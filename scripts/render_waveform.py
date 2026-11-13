#!/usr/bin/env python3
"""Render the dependency-program VCD with a TeX drawing."""
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
source = root / 'build/04_dependencies.vcd'
scopes, signals, changes = [], {}, {}
time = 0
for line in source.read_text().splitlines():
    words = line.split()
    if not words:
        continue
    if words[0] == '$scope':
        scopes.append(words[2])
    elif words[0] == '$upscope':
        scopes.pop()
    elif words[0] == '$var':
        signals['.'.join(scopes + [words[4]])] = words[3]
    elif line.startswith('#'):
        time = int(line[1:])
    elif line[0] in '01xz':
        changes.setdefault(line[1:], []).append((time, line[0]))
    elif line[0] == 'b':
        value, code = words
        changes.setdefault(code, []).append((time, value[1:]))

def value(name, t):
    entries = changes[signals['tb_pipeline_top.' + name]]
    val = 'x'
    for when, bits in entries:
        if when > t:
            break
        val = bits
    return val

rows = [('PC', 'pc'), ('IF', 'if_instr'), ('ID', 'dut.id_instr'),
        ('EX', 'dut.ex_instr'), ('MEM', 'dut.mem_instr'), ('WB', 'dut.wb_instr')]
text = [r'\documentclass{article}',
        r'\usepackage[paperwidth=18cm,paperheight=8.2cm,margin=0.2cm]{geometry}',
        r'\usepackage{tikz}\pagestyle{empty}',
        r'\pdfinfo{/Author (RISC-V CPU) /Creator () /Producer ()}',
        r'\begin{document}\noindent\begin{tikzpicture}[x=1.25cm,y=0.85cm]',
        r'\node[anchor=east] at (1,7.7) {clk};']
# Samples are one picosecond after each edge, in the VCD timescale.
start, count = 25001, 12
for c in range(count):
    x = c + 1.1
    t = start + c * 10000
    text.append(r'\draw (%.2f,7.4) -- (%.2f,7.9) -- (%.2f,7.9) -- (%.2f,7.4) -- (%.2f,7.4);' % (x,x,x+.5,x+.5,x+1))
    text.append(r'\node[font=\scriptsize] at (%.2f,8.3) {%d};' % (x+.5,t//1000))
    assert value('clk',t) == '1'
for r, (label, signal) in enumerate(rows):
    y = 6.5-r
    text.append(r'\node[anchor=east] at (1,%.2f) {%s};' % (y,label))
    for c in range(count):
        bits = value(signal,start+c*10000)
        word = 'unknown' if 'x' in bits or 'z' in bits else f'{int(bits,2):08x}'
        x=c+1.1
        text.append(r'\draw (%.2f,%.2f) rectangle (%.2f,%.2f);' % (x,y-.32,x+1,y+.32))
        text.append(r'\node[font=\tiny\ttfamily] at (%.2f,%.2f) {%s};' % (x+.5,y,word))
text += [r'\node[font=\small] at (7,-0.15) {Time in ns; bus values in hexadecimal, sampled after rising edges};',
         r'\end{tikzpicture}\end{document}']
tex = root / 'build/waveform.tex'
tex.write_text('\n'.join(text)+'\n')
subprocess.run(['pdflatex','-interaction=batchmode','-halt-on-error','-output-directory=build',str(tex)],cwd=root,check=True)
out = root / 'docs/waveforms/dependencies'
out.parent.mkdir(parents=True, exist_ok=True)
subprocess.run(['pdftoppm','-png','-singlefile','-scale-to','2400',str(root/'build/waveform.pdf'),str(out)],check=True)
out.with_suffix('.pdf').write_bytes((root/'build/waveform.pdf').read_bytes())
