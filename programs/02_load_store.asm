# Leave two NOPs between a register write and its dependent read.
# ID can read the WB value at the same rising edge through write-through.
.text
    addi x1, x0, 40
    addi x2, x0, -19
    addi x0, x0, 0
    addi x0, x0, 0
    sw x2, 0(x1)
    lw x3, 0(x1)
    addi x0, x0, 0
    addi x0, x0, 0
    sw x3, 4(x0)
    lw x4, 4(x0)
