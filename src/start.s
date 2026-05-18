.section .text.boot
.global _start

_start:
    csrr t0, mhartid
    bnez    t0, park
    la      sp, stack_top

# zero-initialise bss
    la      t0, __bss_start
    la      t1, __bss_end
bss_zero_loop:
    bgeu    t0, t1, bss_zero_done
    sd      zero, 0(t0)
    addi    t0, t0, 8
    j       bss_zero_loop

bss_zero_done:
    call kmain

park:
 wfi
 j park
