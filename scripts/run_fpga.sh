#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
for tool in yosys nextpnr-ice40 python3; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing FPGA tool: $tool. See README.md." >&2
    exit 127
  fi
done
mkdir -p build/fpga
rtl=$(find rtl -name '*.v' | sort | tr '\n' ' ')
yosys -V
nextpnr-ice40 --version
for top in single_cycle_top pipeline_top; do
  out="build/fpga/$top"
  if ! yosys -Q -T -l "$out.synth.log" -p "
    read_verilog $rtl
    chparam -set HEX_FILE \"programs/benchmarks/branch_loop.hex\" $top
    synth_ice40 -top $top -json $out.netlist.json
    check -assert
  " > "$out.synth.stdout" 2>&1; then
    tail -30 "$out.synth.stdout" >&2
    exit 1
  fi
  rm "$out.synth.stdout"
  if ! nextpnr-ice40 --hx8k --package ct256 --freq 12 --seed 1 \
       --pcf-allow-unconstrained --json "$out.netlist.json" \
       --report "$out.route.json" > "$out.route.log" 2>&1; then
    tail -30 "$out.route.log" >&2
    exit 1
  fi
done
python3 - <<'PY'
import csv
import json
from pathlib import Path

out = Path('build/fpga')
with (out / 'summary.csv').open('w', newline='') as stream:
    writer = csv.writer(stream)
    writer.writerow(['core', 'logic_cells', 'ram_blocks', 'io_pins', 'clock_mhz'])
    for core in ('single_cycle_top', 'pipeline_top'):
        report = json.loads((out / f'{core}.route.json').read_text())
        usage = report['utilization']
        clock = min(report['fmax'].values(), key=lambda entry: entry['achieved'])
        result = [core, usage['ICESTORM_LC']['used'], usage['ICESTORM_RAM']['used'],
                  usage['SB_IO']['used'], f"{clock['achieved']:.2f}"]
        writer.writerow(result)
        print(', '.join(map(str, result)))
PY
