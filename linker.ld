ENTRY(_start)

SECTIONS {
    . = 0x80000000;

    .text : {
        *(.text.boot);
        *(.text*);
    }
    .rodata : {
        *(.rodata*);
    }
    .data : {
        *(.data*);
    }
    .bss : {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(8);
        __bss_end = .;
    }

    . = ALIGN(16);
    . += 0x4000;
    stack_top = .;
}
