# Leave two NOPs between a register write and its dependent read.
# ID can read the WB value at the same rising edge through write-through.
.text
    addi x1, x0, 3
    addi x2, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
loop:
    addi x2, x2, 1
    addi x1, x1, -1
    addi x0, x0, 0
    addi x0, x0, 0
    bne x1, x0, loop
    addi x10, x0, 77
    addi x0, x0, 0
    addi x0, x0, 0
    sw x10, 0(x0)
    beq x1, x0, equal
    addi x11, x0, 88
    sw x10, 8(x0)
equal:
    bne x1, x0, bad
    beq x1, x2, bad
    addi x3, x0, 9
    beq x0, x0, done
bad:
    addi x4, x0, 99
    sw x10, 12(x0)
done:
    addi x5, x0, 7
