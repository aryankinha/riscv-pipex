#!/usr/bin/env python3
"""Check retirement traces against the supported instruction semantics."""
import csv
from pathlib import Path
import random
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / 'build'
MASK = (1 << 32) - 1
NOP = 0x00000013


def signed(value, width):
    return value - (1 << width) if value & (1 << (width - 1)) else value


def reference(words):
    regs, memory, events = [0] * 32, [0] * 64, []
    pc = 0
    for _ in range(500):
        if pc % 4 or not 0 <= pc // 4 < len(words):
            raise ValueError(f'reference PC outside program: {pc:08x}')
        ins = words[pc // 4]
        opcode, funct3 = ins & 127, (ins >> 12) & 7
        rd, rs1, rs2 = (ins >> 7) & 31, (ins >> 15) & 31, (ins >> 20) & 31
        next_pc, result = pc + 4, None
        if opcode == 0x33 and funct3 == 0 and ins >> 25 in (0, 32):
            result = regs[rs1] - regs[rs2] if ins >> 25 else regs[rs1] + regs[rs2]
        elif opcode == 0x13 and funct3 == 0:
            result = regs[rs1] + signed(ins >> 20, 12)
        elif opcode in (0x03, 0x23) and funct3 == 2:
            offset = ins >> 20 if opcode == 3 else ((ins >> 25) << 5) | ((ins >> 7) & 31)
            address = (regs[rs1] + signed(offset, 12)) & MASK
            valid = address % 4 == 0 and address < 256
            if opcode == 3:
                result = memory[address // 4] if valid else 0
            elif valid:
                memory[address // 4] = regs[rs2]
        elif opcode == 0x63 and funct3 in (0, 1):
            offset = ((ins >> 31) << 12) | (((ins >> 7) & 1) << 11)
            offset |= (((ins >> 25) & 63) << 5) | (((ins >> 8) & 15) << 1)
            equal = regs[rs1] == regs[rs2]
            taken = equal if funct3 == 0 else not equal
            if taken:
                next_pc = pc + signed(offset, 13)
        else:
            raise ValueError(f'unsupported instruction {ins:08x} at {pc:08x}')
        write = result is not None and rd != 0
        if write:
            regs[rd] = result & MASK
        events.append((pc, ins, int(write), rd if write else 0, regs[rd] if write else 0))
        if pc == 4 * (len(words) - 1):
            return regs + memory, events
        pc = next_pc
    raise ValueError('reference program did not finish')


def immediate(rd, rs1, value, load=False):
    return (((value & 4095) << 20) | (rs1 << 15) | ((2 if load else 0) << 12)
            | (rd << 7) | (3 if load else 0x13))


def arithmetic(rd, rs1, rs2, subtract=False):
    return (int(subtract) << 30) | (rs2 << 20) | (rs1 << 15) | (rd << 7) | 0x33


def store(rs2, rs1, offset):
    bits = offset & 4095
    return (((bits >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (2 << 12)
            | ((bits & 31) << 7) | 0x23)


def branch(rs1, rs2, offset, unequal=False):
    bits = offset & 8191
    return (((bits >> 12) << 31) | (((bits >> 5) & 63) << 25)
            | (rs2 << 20) | (rs1 << 15) | (int(unequal) << 12)
            | (((bits >> 1) & 15) << 8) | (((bits >> 11) & 1) << 7) | 0x63)


def model_checks():
    cases = [
        ([0x00500093, 0xffd00113, 0x002081b3, 0x40208233], {1: 5, 2: 0xfffffffd, 3: 2, 4: 8}),
        ([0xfff00093, 0x00100113, 0x002081b3, 0x40200233], {1: MASK, 3: 0, 4: MASK}),
        ([0x06300013, 0x00002003], {0: 0}),
        ([0xff900093, 0x00102023, 0x00002103], {1: 0xfffffff9, 2: 0xfffffff9, 32: 0xfffffff9}),
        ([0x00000463, 0x06300093, 0x00700113], {1: 0, 2: 7}),
        ([0x00001463, 0x00500093, 0x00700113], {1: 5, 2: 7}),
        ([0x00300093, 0xfff08093, 0xfe009ee3, NOP], {1: 0}),
        ([0x10000093, 0x0000a103, 0x0010a023], {1: 256, 2: 0, 32: 0}),
    ]
    for words, expected in cases:
        state, _ = reference(words)
        for index, want in expected.items():
            if state[index] != want:
                raise ValueError(f'model self-check failed at state index {index}')
    encodings = [immediate(1, 0, 5), arithmetic(4, 1, 2, True), store(1, 0, 0), branch(1, 0, -4, True)]
    if encodings != [0x00500093, 0x40208233, 0x00102023, 0xfe009ee3]:
        raise ValueError('instruction encoding self-check failed')
    print(f'PASS reference self-checks={len(cases)} and encoding checks={len(encodings)}')


def check_trace(path, events):
    with path.open(newline='') as stream:
        rows = list(csv.DictReader(stream))
    retired = [row for row in rows if row['wb_valid'] == '1']
    if len(retired) != len(events):
        raise ValueError(f'{path.name}: retirement count {len(retired)} != {len(events)}')
    for index, (row, expected) in enumerate(zip(retired, events)):
        pc, ins, write, rd, data = expected
        got = (int(row['wb_pc'], 16), int(row['wb_instr'], 16), int(row['wb_write']))
        if got != (pc, ins, write):
            raise ValueError(f'{path.name}: retirement {index}: got {got}, expected {(pc, ins, write)}')
        if write and (int(row['wb_rd']), int(row['wb_data'], 16)) != (rd, data):
            raise ValueError(f'{path.name}: retirement {index}: x{rd} should receive {data:08x}')
    return int(rows[-1]['cycle'])


def fixture_words(path):
    count = 0
    for line in path.with_suffix('.asm').read_text().splitlines():
        line = line.split('#')[0].strip()
        if ':' in line:
            line = line.split(':', 1)[1].strip()
        if line and not line.startswith('.'):
            count += 1
    return [int(word, 16) for word in path.read_text().split()][:count]


def directed_cases():
    memory = []
    operations = [immediate(1, 0, 252), immediate(2, 0, -7), store(2, 1, 0),
                  immediate(3, 1, 0, True), immediate(2, 0, 29), store(2, 1, 0),
                  immediate(3, 1, 0, True), immediate(4, 0, 256), store(2, 4, 0),
                  immediate(5, 4, 0, True), immediate(4, 0, 1), store(2, 4, 0),
                  immediate(6, 4, 0, True), immediate(0, 1, 0, True), arithmetic(7, 3, 2)]
    for word in operations:
        memory.extend([word, NOP, NOP])
    repeated = [immediate(1, 0, 11), immediate(1, 0, 29), NOP, NOP,
                arithmetic(2, 1, 1), NOP, NOP, store(2, 0, 0),
                immediate(3, 0, 0, True), immediate(3, 0, -5), NOP, NOP,
                arithmetic(4, 3, 0, True), NOP, NOP, store(4, 0, 4),
                immediate(0, 0, 99), immediate(0, 0, 0, True),
                arithmetic(5, 0, 0), NOP, NOP, store(5, 0, 8), NOP]
    branches = [immediate(1, 0, 1), NOP, NOP, branch(1, 1, 12),
                immediate(10, 0, 99), store(1, 0, 0), branch(0, 0, 12),
                branch(0, 1, 12, True), immediate(11, 0, 99),
                immediate(2, 0, 0, True), NOP, NOP, branch(2, 0, 12),
                immediate(12, 0, 99), store(1, 0, 4), branch(1, 0, 12),
                branch(1, 0, 12, True), immediate(13, 0, 99),
                store(1, 0, 8), NOP]
    return [('memory_edges', memory, {3: 29, 5: 0, 6: 0, 7: 58, 95: 29}),
            ('repeated_writes', repeated, {0: 0, 1: 29, 2: 58, 3: 0xfffffffb, 4: 0xfffffffb, 32: 58, 33: 0xfffffffb}),
            ('branch_edges', branches, {10: 0, 11: 0, 12: 0, 13: 0, 32: 0, 33: 0, 34: 0})]


def random_case(seed):
    rng = random.Random(seed)
    words = [immediate(1, 0, rng.randint(-64, -1)),
             immediate(2, 0, rng.randint(1, 64))]
    for index in range(18):
        rd, rs1, rs2 = (rng.choice([0, 1, 2, 3, 4, 5, 6, 7, 31]) for _ in range(3))
        kind = rng.randrange(7 if index < 15 else 5)
        if kind == 0:
            word = immediate(rd, rs1, rng.randint(-2048, 2047))
        elif kind in (1, 2):
            word = arithmetic(rd, rs1, rs2, kind == 2)
        elif kind == 3:
            word = immediate(rd, 0, 4 * rng.randrange(64), True)
        elif kind == 4:
            word = store(rs2, 0, 4 * rng.randrange(64))
        else:
            word = branch(rs1, rs2, rng.choice([8, 12]), kind == 6)
        words.append(word)
    return words + [NOP]


def simulate(name, image, expected, words, events, baseline=False, stalls=None):
    if not 5 <= len(words) <= 64:
        raise ValueError(f'{name}: program does not fit instruction memory')
    top = 'single_cycle' if baseline else 'pipeline_top'
    output = 'single_cycle' if baseline else 'pipeline'
    rtl = sorted(str(path.relative_to(ROOT)) for path in (ROOT / 'rtl').rglob('*.v'))
    command = ['iverilog', '-g2001', '-Wall', '-s', f'tb_{top}',
               f'-DPROGRAM_FILE="{image.relative_to(ROOT)}"',
               f'-DEXPECTED_FILE="{expected.relative_to(ROOT)}"',
               f'-DLAST_PC={4 * (len(words) - 1)}', f'-DEXPECTED_RETIRED={len(events)}',
               '-o', f'build/{output}.vvp', *rtl, f'tb/tb_{top}.v']
    if stalls is not None:
        command.insert(5, f'-DEXPECTED_STALLS={stalls}')
    subprocess.run(command, cwd=ROOT, check=True)
    result = subprocess.run(['vvp', f'build/{output}.vvp'], cwd=ROOT, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=True)
    if 'PASS ' + ('single-cycle' if baseline else 'pipeline') not in result.stdout:
        raise ValueError(f'{name}: missing PASS result')
    trace = BUILD / f'{name}.csv'
    (BUILD / f'{output}.csv').replace(trace)
    if not baseline:
        (BUILD / 'pipeline.vcd').replace(BUILD / f'{name}.vcd')
    return check_trace(trace, events)


def simulate_case(name, words, state, events):
    image, expected = BUILD / f'{name}.hex', BUILD / f'{name}.expected'
    image.write_text(''.join(f'{word:08x}\n' for word in words + [NOP] * (64 - len(words))))
    expected.write_text(''.join(f'{word:08x}\n' for word in state))
    return simulate(name, image, expected, words, events)


def benchmark():
    fixtures = {'alu_chain': 0, 'load_use': 3, 'branch_loop': 1}
    fields = ['program', 'retired', 'single_cycles', 'pipeline_cycles',
              'stalls', 'taken', 'single_cpi', 'pipeline_cpi', 'single_ipc', 'pipeline_ipc']
    with (BUILD / 'benchmarks.csv').open('w', newline='') as stream:
        writer = csv.writer(stream)
        writer.writerow(fields)
        for name, stalls in fixtures.items():
            image = ROOT / 'programs' / 'benchmarks' / f'{name}.hex'
            expected = image.with_suffix('.expected')
            words = fixture_words(image)
            state, events = reference(words)
            if state != [int(word, 16) for word in expected.read_text().split()]:
                raise ValueError(f'{name}: expected-state fixture disagrees with reference')
            pipe = simulate(name, image, expected, words, events, stalls=stalls)
            single = simulate(f'{name}_single', image, expected, words, events, baseline=True)
            retired = len(events)
            with (BUILD / f'{name}.csv').open(newline='') as trace:
                taken = sum(row['taken'] == '1' for row in csv.DictReader(trace))
            writer.writerow([name, retired, single, pipe, stalls, taken,
                             f'{single / retired:.3f}', f'{pipe / retired:.3f}',
                             f'{retired / single:.3f}', f'{retired / pipe:.3f}'])
            print(f'PASS benchmark {name} retired={retired} single_cycles={single} '
                  f'pipeline_cycles={pipe} stalls={stalls} taken={taken}')
    return 2 * len(fixtures)


def main():
    model_checks()
    checked = 0
    for path in sorted((ROOT / 'programs').glob('*.hex')):
        state, events = reference(fixture_words(path))
        expected = [int(word, 16) for word in path.with_suffix('.expected').read_text().split()]
        if state != expected:
            raise ValueError(f'{path.stem}: expected-state fixture disagrees with reference')
        cycles = check_trace(BUILD / (path.stem + '.csv'), events)
        print(f'PASS reference {path.stem} cycles={cycles} retired={len(events)}')
        checked += 1
    for name, words, known in directed_cases():
        state, events = reference(words)
        for index, want in known.items():
            if state[index] != want:
                raise ValueError(f'{name}: hand-calculated state mismatch at {index}')
        cycles = simulate_case(name, words, state, events)
        print(f'PASS reference {name} cycles={cycles} retired={len(events)}')
        checked += 1
    for seed in range(12):
        name, words = f'random_{seed:02d}', random_case(seed)
        state, events = reference(words)
        cycles = simulate_case(name, words, state, events)
        print(f'PASS reference {name} cycles={cycles} retired={len(events)}')
        checked += 1
    checked += benchmark()
    print(f'PASS reference comparisons={checked}')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f'FAIL reference check: {error}', file=sys.stderr)
        if isinstance(error, subprocess.CalledProcessError) and error.stdout:
            print(error.stdout, file=sys.stderr)
        sys.exit(1)
