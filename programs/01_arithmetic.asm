# Leave two NOPs between a register write and its dependent read.
# ID can read the WB value at the same rising edge through write-through.
.text
    addi x1, x0, 17
    addi x2, x0, -5
    addi x0, x0, 0
    addi x0, x0, 0
    add x3, x1, x2
    sub x4, x1, x2
    addi x0, x0, 99
    addi x5, x0, -2048
    addi x6, x0, 2047
