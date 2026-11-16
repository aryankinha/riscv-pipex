# 5-Stage Pipelined RISC-V Processor

Verilog-2001 Phase I project for Modern Computer Architecture at Newton School of Technology, Rishihood University.

## 1. Install on Mac

Install [Homebrew](https://docs.brew.sh/Installation) first if `brew` is missing. Then run:

```sh
brew install git python icarus-verilog surfer
```

## 2. Get the project and run tests

```sh
git clone https://github.com/aryankinha/riscv-pipex.git
cd riscv-pipex
command -v iverilog
command -v vvp
python3 --version
./scripts/run_all.sh
```

If you downloaded a ZIP, extract it and open Terminal inside its folder instead of cloning. If the script reports permission denied, run `chmod +x scripts/run_all.sh` and retry. Missing tools must be installed in step 1; `chmod` does not install them.

Expected: 59 RTL unit cases and 19 program runs pass, along with eight reference-model cases and four encoding checks. The final line is `PASS reference comparisons=19`. A failing check returns a nonzero exit status. Each run replaces `build/` and writes VCD waveforms and CSV traces there.

## 3. View the pipeline

After the tests finish, run:

```sh
surfer -c docs/waveforms/pipeline.sucl build/04_dependencies.vcd
```

The command file selects the clock, PC, five instruction stages and valid bits, then fits the timeline. It works with Surfer 0.7.0; use lowercase `-c`, not `-C`. Keep the viewer running while inspecting it. INFO messages in Terminal are normal.

Follow a non-NOP instruction through IF, ID, EX, MEM and WB, one clock at a time. Different instructions occupy the stages simultaneously. `00000013` is NOP; a valid bit of zero marks a bubble.

For branch flushing:

```sh
surfer -c docs/waveforms/branches.sucl build/03_branches.vcd
```

Watch `taken`, the redirected PC, and the cleared ID/EX valid bits. Zoom into a few cycles so the values are readable. On Mac, use Shift+Command+4 for a screenshot or Shift+Command+5 for screen recording.

## Processor scope

ADD, SUB, ADDI, LW, SW, BEQ and BNE; NOP is ADDI x0,x0,0. Each memory holds 64 words. Reset is synchronous and active high; PC starts at zero and x0 reads zero.

Separate dependent instructions with two NOPs or two independent instructions. There is no hardware data-hazard handling yet. Taken branches resolve in EX and flush two younger slots. The instruction reference model and edge-case tests are described in the report.

## Report and figures

- [IEEE report](docs/report/report.pdf), with [LaTeX source](docs/report/report.tex).
- [Block diagram](docs/diagrams/block.png) and [waveform figure](docs/waveforms/dependencies.png).
- `rtl/`: processor modules; `tb/`: tests; `programs/`: assembly, hex and expected states.

Reading these files needs only a PDF/image viewer. To rebuild them, install a TeX distribution and Poppler first. If you do not already have TeX:

```sh
brew install --cask mactex-no-gui
brew install poppler
```

Open a new terminal after installing MacTeX. Existing TinyTeX users can install a missing IEEE class with `tlmgr install ieeetran` instead of installing MacTeX. Check `kpsewhich IEEEtran.cls` and `kpsewhich tikz.sty` before rendering.

From the repository root, rebuild the waveform with:

```sh
python3 scripts/render_waveform.py
```

Rebuild the report with:

```sh
cd docs/report
pdflatex -interaction=nonstopmode -halt-on-error report.tex
pdflatex -interaction=nonstopmode -halt-on-error report.tex
cd ../..
```

## CI

[Phase I tests](https://github.com/aryankinha/riscv-pipex/actions/workflows/test.yml) install dependencies and run the full suite from a fresh checkout on every push and pull request. Open the test step for PASS output or the first failure. You can also select Run workflow in Actions.

## Video

[Video](https://drive.google.com/drive/folders/1zvoQiCziL2G4nigfQbIoxcu8opQLb8yZ?usp=sharing)

## Team

Team lead: Aryan Kinha.

| Member | Student ID | Email | Assigned role |
| --- | --- | --- | --- |
| Preetish Ubhrani | 2401020050 | preetish.ubhrani2024@nst.rishihood.edu.in | Execute and branch logic |
| Aryan Kinha | 2401020013 | aryan.kinha2024@nst.rishihood.edu.in | Team lead, integration and testing |
| Divyanshu Singh | 2401010161 | divyanshu.singh2024@nst.rishihood.edu.in | Decode and control |
| Jatin Verma | 2401010200 | jatin.verma2024@nst.rishihood.edu.in | Memory and write-back |
| Jatin Kumar Singh | 2401010199 | jatin.singh2024@nst.rishihood.edu.in | Fetch and instruction memory |

## Phase II

Planned: forwarding and stalls, a single-cycle baseline, CPI comparison, benchmarks, synthesis and FPGA evaluation, and final Results and Conclusion sections.
