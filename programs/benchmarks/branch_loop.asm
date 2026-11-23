.text
    addi x1, x0, 4
    addi x2, x0, 0
loop:
    add  x2, x2, x1
    addi x1, x1, -1
    bne  x1, x0, loop
    sw   x2, 0(x0)
    lw   x3, 0(x0)
    beq  x3, x2, done
    addi x4, x0, 99
    sw   x4, 4(x0)
done:
    sub  x5, x3, x1
