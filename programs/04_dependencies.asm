# Leave two NOPs between a register write and its dependent read.
# ID can read the WB value at the same rising edge through write-through.
.text
    addi x1, x0, 9
    addi x0, x0, 0
    addi x0, x0, 0
    addi x2, x1, 4
    addi x0, x0, 0
    addi x0, x0, 0
    add x3, x2, x1
    addi x0, x0, 0
    addi x0, x0, 0
    sw x3, 0(x0)
    lw x4, 0(x0)
    addi x0, x0, 0
    addi x0, x0, 0
    sub x5, x4, x1
    addi x0, x0, 0
    addi x0, x0, 0
    sw x5, 4(x0)
