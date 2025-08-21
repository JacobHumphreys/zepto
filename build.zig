const std = @import("std");
const build_zig_zon = @embedFile("build.zig.zon");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const root_unit_tests_mod = b.createModule(.{
        .root_source_file = b.path("src/root_unit_tests.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{
                .name = "lib",
                .module = lib_mod,
            },
        },
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{
                .name = "lib",
                .module = lib_mod,
            },
        },
    });

    root_unit_tests_mod.addImport("lib", lib_mod);

    const exe = b.addExecutable(.{
        .name = "zepto",
        .root_module = exe_mod,
    });

    exe.linkLibC();

    var build_options = std.Build.Step.Options.create(b);
    build_options.addOption([]const u8, "contents", build_zig_zon);
    exe.root_module.addOptions("build_zig_zon", build_options);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const root_unit_tests = b.addTest(.{
        .root_module = root_unit_tests_mod,
    });

    const run_root_unit_tests = b.addRunArtifact(root_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_root_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
