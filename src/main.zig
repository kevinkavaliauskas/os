const std = @import("std");

const UART_ADDR: *volatile u64 = @ptrFromInt(0x10000000);

fn putc(ch: u8) void {
    UART_ADDR.* = ch;
}

fn print(word: []const u8) void {
    for (word) |ch| {
        putc(ch);
    }
}

fn trap_handler() callconv(.naked) void {
    asm volatile ("csrrw t0, mscratch, t0");
    inline for (1..32) |i| {
        if (i == 5) continue; // x5 is t0 which is holding our temporary mscratch value, so it gets handled later
        asm volatile (std.fmt.comptimePrint("sd x{d}, {d}(t0)", .{ i, i * 8 })); // save the value of each register into the address held in mscratch + an offset
    }
}

export fn kmain() callconv(.c) noreturn {
    print("Hello, Kevin!");

    while (true) asm volatile ("wfi");
}
