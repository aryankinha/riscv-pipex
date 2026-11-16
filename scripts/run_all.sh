#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
for tool in iverilog vvp python3; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing test tool: $tool. Install Icarus Verilog and Python 3; see README.md." >&2
    exit 127
  fi
done
rm -rf build
mkdir build
rtl=$(find rtl -name '*.v' | sort)
for test in alu regfile control; do
  iverilog -g2001 -Wall -s "tb_$test" -o "build/$test.vvp" $rtl "tb/tb_$test.v"
  vvp "build/$test.vvp"
done
iverilog -g2001 -Wall -s tb_pipeline_top -DPROGRAM_FILE='"programs/01_arithmetic.hex"' -DEXPECTED_FILE='"programs/01_arithmetic.expected"' -DLAST_PC=32 -DEXPECTED_RETIRED=9 -o build/pipeline.vvp $rtl tb/tb_pipeline_top.v
vvp build/pipeline.vvp
mv build/pipeline.vcd build/01_arithmetic.vcd
mv build/pipeline.csv build/01_arithmetic.csv
iverilog -g2001 -Wall -s tb_pipeline_top -DPROGRAM_FILE='"programs/02_load_store.hex"' -DEXPECTED_FILE='"programs/02_load_store.expected"' -DLAST_PC=36 -DEXPECTED_RETIRED=10 -o build/pipeline.vvp $rtl tb/tb_pipeline_top.v
vvp build/pipeline.vvp
mv build/pipeline.vcd build/02_load_store.vcd
mv build/pipeline.csv build/02_load_store.csv
iverilog -g2001 -Wall -s tb_pipeline_top -DPROGRAM_FILE='"programs/03_branches.hex"' -DEXPECTED_FILE='"programs/03_branches.expected"' -DLAST_PC=88 -DEXPECTED_RETIRED=29 -o build/pipeline.vvp $rtl tb/tb_pipeline_top.v
vvp build/pipeline.vvp
mv build/pipeline.vcd build/03_branches.vcd
mv build/pipeline.csv build/03_branches.csv
iverilog -g2001 -Wall -s tb_pipeline_top -DPROGRAM_FILE='"programs/04_dependencies.hex"' -DEXPECTED_FILE='"programs/04_dependencies.expected"' -DLAST_PC=64 -DEXPECTED_RETIRED=17 -o build/pipeline.vvp $rtl tb/tb_pipeline_top.v
vvp build/pipeline.vvp
mv build/pipeline.vcd build/04_dependencies.vcd
mv build/pipeline.csv build/04_dependencies.csv
python3 scripts/check_programs.py
