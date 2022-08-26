const std = @import("std");

const c_pkg = std.build.Pkg{
    .name = "c",
    .source = .{ .path = "c.zig" },
};

const GLFW_BASE = "_external/glfw";

var allocator: std.mem.Allocator = undefined;
var mode: std.builtin.Mode = undefined;

fn buildCmake(step: *std.build.Step) !void {
    _ = step;

    // var envmap = std.process.EnvMap.init(allocator);
    // defer envmap.deinit();
    // try envmap.put("CC", "zig cc");
    // try envmap.put("CXX", "zig c++");

    // configure
    {
        const build_type = if (mode == .Debug) "-DCMAKE_BUILD_TYPE=Debug" else "-DCMAKE_BUILD_TYPE=Release";
        const result = try std.ChildProcess.exec(.{
            .allocator = allocator,
            .argv = &.{
                "cmake",
                "-S",
                "_external/glfw",
                "-B",
                "build",
                build_type,
                "-DBUILD_SHARED_LIBS=1",
            },
            .max_output_bytes = 1024 * 1024 * 50,
            // .env_map = &envmap,
        });
        // static build cause following errors
        // LLD Link... lld-link: error: could not open 'libuuid.a': No such file or directory
        // lld-link: error: could not open 'libMSVCRTD.a': No such file or directory
        // lld-link: error: could not open 'libOLDNAMES.a': No such file or directory
        defer allocator.free(result.stdout);
        defer allocator.free(result.stderr);
    }

    // build
    {
        const config = if (mode == .Debug) "Debug" else "Release";
        const result = try std.ChildProcess.exec(.{
            .allocator = allocator,
            .argv = &.{
                "cmake",
                "--build",
                "build",
                "--config",
                config,
            },
            .max_output_bytes = 1024 * 1024 * 50,
            // .env_map = &envmap,
        });
        defer allocator.free(result.stdout);
        defer allocator.free(result.stderr);
    }
}

pub fn build(b: *std.build.Builder) void {
    allocator = std.heap.page_allocator;

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    mode = b.standardReleaseOptions();

    const cmake_step = b.step("cmake", "build glfw");
    cmake_step.makeFn = buildCmake;

    const exe = b.addExecutable("Ur.zig", "src/main.zig");
    exe.step.dependOn(cmake_step);
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackage(c_pkg);
    // glfw
    exe.addIncludePath(GLFW_BASE ++ "/include");
    exe.linkLibC();
    exe.linkLibCpp();
    const lib_path = if (mode == .Debug) "build/src/Debug" else "build/src/Release";
    exe.addLibraryPath(lib_path);
    exe.linkSystemLibrary("glfw3dll");
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
