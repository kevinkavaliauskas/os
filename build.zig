const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .riscv64,
        .os_tag = .freestanding,
        .abi = .none,
    });

    const kernel_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = .ReleaseSafe,
    });

    const kernel = b.addExecutable(.{
        .name = "kernel.elf",
        .root_module = kernel_mod,
    });
    kernel_mod.addAssemblyFile(b.path("src/start.s"));
    kernel.setLinkerScript(b.path("linker.ld"));
    kernel.entry = .disabled;
    b.installArtifact(kernel);

    const run = b.addSystemCommand(&.{
        "qemu-system-riscv64",
        "-machine",
        "virt",
        "-bios",
        "none",
        "-nographic",
        "-kernel",
    });
    run.addArtifactArg(kernel);
    b.step("run", "Run in QEMU").dependOn(&run.step);
}
