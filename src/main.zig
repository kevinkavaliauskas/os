const UART_ADDR: *volatile u64 = @ptrFromInt(0x10000000);

fn putc(ch: u8) void {
    UART_ADDR.* = ch;
}

fn print(word: []const u8) void {
    for (word) |ch| {
        putc(ch);
    }
}

export fn kmain() callconv(.c) noreturn {
    print("Hello, Kevin!");
    while (true) asm volatile ("wfi");
}
