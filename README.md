# 5-Stage Pipelined RISC-V Processor

A Phase I project for Modern Computer Architecture at Newton School of Technology, Rishihood University. The processor is written in Verilog-2001 and runs a small RV32I subset through fetch, decode, execute, memory and write-back. The repository contains the RTL, tests, assembly programs, simulation figures and report. Programs separate data dependencies in software. EX resolves branches.

## Instructions and timing

The processor supports ADD, SUB, ADDI, LW, SW, BEQ and BNE. NOP is `ADDI x0, x0, 0`. Reads of x0 always return zero.

The PC starts at zero. All state uses one clock and a synchronous active-high reset. Instruction and data memory each hold 64 words. Addresses are byte addresses, so consecutive words are at 0, 4, 8 and so on. The memories support aligned word accesses within their local range. Invalid data reads return zero, and invalid writes have no effect. Unsupported instruction encodings cannot change state or retire. Exception handling is outside this prototype.

Leave two NOPs between a register-writing instruction and its first dependent reader. Two independent instructions can fill those slots instead. This rule applies to load results, store data, address operands and branch operands. Register-file write-through lets ID read a result during its WB cycle. The processor has no EX/MEM forwarding or automatic stalls. A taken branch clears IF/ID and ID/EX, losing two instruction slots. A not-taken branch leaves them intact.

## Files

| Path | Contents |
| --- | --- |
| `rtl/common/` | ALU, register file, immediate decoding and control |
| `rtl/memory/` | Instruction and data storage |
| `rtl/pipeline/` | Stages, pipeline registers and integration |
| `tb/` | Unit tests and self-checking processor test |
| `programs/` | Assembly, word-per-line hex and expected states |
| `scripts/` | Test runner, instruction reference model and VCD figure renderer |
| `docs/report/` | IEEE report [PDF](docs/report/report.pdf), LaTeX source and references |
| `docs/diagrams/` | Block and timing diagrams, with TeX sources |
| `docs/waveforms/` | Dependency-program waveform figures |

## Run the tests

The tests require Python 3, a POSIX shell, Icarus Verilog (`iverilog` and `vvp`) and standard Unix file tools. Python uses only its standard library. They were run with Icarus Verilog 13.0. The checked-in hex files run without an assembler.

From this folder:

```sh
./scripts/run_all.sh
```

The runner removes `build/`, compiles with `-g2001 -Wall` and runs every unit test and program. A failing assertion gives a nonzero exit status. VCD files go into `build/`. The processor test compares every register and data-memory word with its `.expected` file. The first 32 lines hold x0 through x31; the next 64 hold data words 0 through 63. All values are hexadecimal.

An instruction retires when a valid supported entry reaches its WB completion edge. NOPs, stores and branches count. Flushed entries do not. Cycles count rising edges after reset release through the final program instruction's completion. The testbench stops the simulation because the CPU has no halt instruction. Trailing NOPs fill unused instruction storage and fall outside each program's stopping boundary.

The pipeline test checks that valid instructions at distinct addresses occupy all stages at once. It also requires `cycles = retired + 4 + 2 * taken_branches`: four cycles fill the pipeline, and each taken branch loses two slots. This is a functional timing check, not a CPI comparison.

`scripts/check_programs.py` executes the seven supported operations in a separate instruction model. It checks the four saved expected-state files and compares each RTL retirement's PC, instruction word and register write with the model. Eight hand-calculated model cases and four fixed encoding checks run before those comparisons.

The full suite runs 19 programs: the original four, three directed edge cases and twelve repeatable random cases using seeds 0 through 11. The added cases cover repeated register destinations, x0, memory overwrites, the last memory word, invalid data addresses and branch shadows. Random cases combine the existing instructions with two-NOP padding and forward branches. All extra images and expected states stay under `build/`. The suite checks this subset and its timing rules; it does not establish full ISA compliance.

Each run also writes `build/<program>.csv` alongside its VCD. CSV rows sample the pipeline immediately before the active edge. They contain the cycle, stage PCs and valid bits, the WB instruction and register write, and the branch-taken signal. PCs, instruction words and data are hexadecimal; counters, flags and register numbers are decimal. Read a stage PC only when its valid bit is set. `wb_write` excludes writes to x0, and `wb_rd` and `wb_data` matter only when it is set.

To rebuild the waveform after running the tests, install Python 3, pdfLaTeX with TikZ, and Poppler (`pdftoppm`), then run:

```sh
python3 scripts/render_waveform.py
```

To rebuild the report, install the IEEEtran LaTeX class, graphicx, cite, url and Latin Modern fonts, then run from this folder:

```sh
cd docs/report
pdflatex -interaction=nonstopmode -halt-on-error report.tex
pdflatex -interaction=nonstopmode -halt-on-error report.tex
```

The report uses the checked-in figures, so its rebuild does not need the figure renderer.

The reference-model and edge-case approach was compared with [Ario2006/risc-5-processor](https://github.com/Ario2006/risc-5-processor). The checker here was written for this processor's instruction subset and NOP scheduling rule.

## Video

[Video](https://drive.google.com/drive/folders/1zvoQiCziL2G4nigfQbIoxcu8opQLb8yZ?usp=sharing)

## Team

Newton School of Technology, Rishihood University. Team lead: Aryan Kinha.

| Member | Student ID | Email | Assigned role |
| --- | --- | --- | --- |
| Preetish Ubhrani | 2401020050 | preetish.ubhrani2024@nst.rishihood.edu.in | Execute and branch logic |
| Aryan Kinha | 2401020013 | aryan.kinha2024@nst.rishihood.edu.in | Team lead, integration and testing |
| Divyanshu Singh | 2401010161 | divyanshu.singh2024@nst.rishihood.edu.in | Decode and control |
| Jatin Verma | 2401010200 | jatin.verma2024@nst.rishihood.edu.in | Memory and write-back |
| Jatin Kumar Singh | 2401010199 | jatin.singh2024@nst.rishihood.edu.in | Fetch and instruction memory |

The repository history records these module contributions. The table also lists the files each member reviews and the topics they prepare for the viva.

| Owner | Files and tasks | Viva focus |
| --- | --- | --- |
| Preetish | `rtl/common/alu.v`, `rtl/pipeline/ex_stage.v`, `rtl/pipeline/ex_mem_reg.v`, `tb/tb_alu.v`; review branch flushing with Aryan | ALU operations, EX operand selection, branch comparison and target, two-slot flush penalty |
| Aryan | `rtl/pipeline/pipeline_top.v`, `tb/tb_pipeline_top.v`, `scripts/`, `programs/01_arithmetic.*`, `programs/03_branches.*`, `programs/04_dependencies.*`, report and figures | Stage connections, reset, valid bits, instruction overlap, retirement counts and test failures |
| Divyanshu | `rtl/common/regfile.v`, `rtl/common/imm_gen.v`, `rtl/common/control_unit.v`, `rtl/pipeline/id_stage.v`, `rtl/pipeline/id_ex_reg.v`, `tb/tb_regfile.v`, `tb/tb_control.v` | Instruction fields, immediate decoding, control bits, x0 and why two NOPs are needed |
| Jatin Verma | `rtl/memory/data_mem.v`, `rtl/pipeline/mem_stage.v`, `rtl/pipeline/mem_wb_reg.v`, `rtl/pipeline/wb_stage.v`, `programs/02_load_store.*` | Word indexing, read/write enables, store timing and the WB result choice |
| Jatin Kumar Singh | `rtl/pipeline/if_stage.v`, `rtl/memory/instr_mem.v`, `rtl/pipeline/if_id_reg.v` | PC reset and sequential updates, hex loading, IF/ID capture and branch redirection |

Preetish reviews branch behavior with Aryan, who coordinates processor integration and testing. Each member must review their own files and be able to explain the full IF, ID, EX, MEM, WB sequence.

## Phase II

Phase II will add forwarding and stall logic, a single-cycle baseline, CPI comparison and benchmark programs. It will also cover synthesis and FPGA evaluation and add Results and Conclusion sections to the report.
