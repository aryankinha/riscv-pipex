.text
    addi x1, x0, 4
    addi x2, x0, 12
    sw   x2, 0(x1)
    lw   x3, 0(x1)
    addi x4, x3, 1
    sw   x4, 4(x1)
    lw   x5, 4(x1)
    sw   x5, 8(x1)
    lw   x6, 0(x1)
    addi x7, x0, 6   # The immediate's low bits match x6, but ADDI has no rs2.
    lw   x0, 4(x1)
    add  x8, x0, x7
    lw   x9, 0(x1)
    add  x10, x0, x9
