const std = @import("std");

const TIME_INTERRUPT_INTERVAL = 10_000_000;
const UART_ADDR: *volatile u8 = @ptrFromInt(0x10000000);

fn putc(ch: u8) void {
    UART_ADDR.* = ch;
}

fn print(word: []const u8) void {
    for (word) |ch| {
        putc(ch);
    }
}

fn csrRead(comptime csr: []const u8) usize {
    return asm volatile ("csrr %[ret], " ++ csr
        : [ret] "=r" (-> usize),
    );
}

// this is done outside of the main function purposely so that it lands in .bss
// it shouldn't live on the stack, it should outlive the function scope
// set up reserved memory space for the registers to be saved into during trap handling
// 32 for 32 registers, each register is 64bit. aligned to 16
var trap_frame: [32]u64 align(16) = undefined;

fn trap_handler() align(4) callconv(.naked) void {
    // --------------------------------------------------------------------------------------------
    // this block has to be in assembly in order to save the registers
    // there is no guarantee that the zig compiler will respect our registers, and might clober them
    asm volatile ("csrrw t0, mscratch, t0"); // swap t0 and mscratch (mscratch holds a memory address)
    inline for (1..32) |i| { // inline needed for compile time to outout raw asm
        if (i == 5) continue; // x5 is t0 which is holding our temporary mscratch value, so it gets handled later
        asm volatile (std.fmt.comptimePrint("sd x{d}, {d}(t0)", .{ i, i * 8 })); // save the value of each register into the address held in mscratch + an offset
    }
    asm volatile ("csrr t1, mscratch"); // read mscratch (which contains the value of t0) into t1
    asm volatile ("sd t1, 40(t0)"); // write to trap address (held in t0) + offset into the corresponding memory

    // save the address of the first space (which holds enough for 32 registers) to mscratch CSR
    asm volatile ("csrw mscratch, %[addr]"
        :
        : [addr] "r" (&trap_frame),
    );
    // -----------------------------------------------------------------------------------------------

    // read the mcause register to identify what the reason for the trap was
    // create a packed struct. is_interrupt signifies if its an exception or an interrupt
    const Mcause = packed struct(u64) {
        code: u63,
        is_interrupt: u1,
    };
    const mcause: Mcause = @bitCast(csrRead("mcause"));

    if (mcause.is_interrupt == 1) {
        print("interrupt detected");
        switch (mcause.code) {
            5 => {
                print("unexpected S-mode timer interrupt");
            },
            7 => { // timer interrupt codes
                asm volatile ("sd mtimecmp, t0");
                asm volatile ("addi t0, t0, [%interrupt]"
                    : [interrupt] "r" (TIME_INTERRUPT_INTERVAL),
                );
            },
        }
    } else {
        print("exception detected");
    }
}

export fn kmain() callconv(.c) noreturn {
    // save the address of the first space (which holds enough for 32 registers) to mscratch CSR
    asm volatile ("csrw mscratch, %[addr]"
        :
        : [addr] "r" (&trap_frame),
    );
    // set mtvec CSR to the address of the trap handler.
    // when the cpu traps, it will jump to our trap handler address automatically
    asm volatile ("csrw mtvec, %[addr]"
        :
        : [addr] "r" (&trap_handler),
    );

    print("Hello, Kevin!");

    while (true) asm volatile ("wfi");
}
