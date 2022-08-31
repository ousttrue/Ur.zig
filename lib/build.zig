const std = @import("std");

const imgui_pkg = std.build.Pkg{ .name = "imgui", .source = .{ .path = "pkgs/imgui/src/main.zig" } };

const GLAD_BASE = "_external/glad";

var allocator: std.mem.Allocator = undefined;
var mode: std.builtin.Mode = undefined;

const IMGUI_BASE = "_external/imgui";
const IMGUI_SOURCES = [_][]const u8{
    IMGUI_BASE ++ "/imgui.cpp",
    IMGUI_BASE ++ "/imgui_draw.cpp",
    IMGUI_BASE ++ "/imgui_widgets.cpp",
    IMGUI_BASE ++ "/imgui_tables.cpp",
    IMGUI_BASE ++ "/imgui_demo.cpp",
    // IMGUI_BASE ++ "/backends/imgui_impl_glfw.cpp",
    // IMGUI_BASE ++ "/backends/imgui_impl_opengl3.cpp",
    "pkgs/imgui/src/imvec2_byvalue.cpp",
    "pkgs/imgui/src/internal.cpp",
};
const IMGUI_FLAGS = [_][]const u8{
    // "-DIMGUI_DISABLE_DEFAULT_FORMAT_FUNCTIONS",
    // "-DIMGUI_USE_STB_SPRINTF",
};
const STB_BASE = "_external/stb";

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

    const dll = b.addSharedLibrary("Ur", "src/main.zig", .unversioned);
    dll.setTarget(target);
    dll.setBuildMode(mode);
    dll.linkLibC();
    if (target.os_tag == std.Target.Os.Tag.windows) {
        dll.linkSystemLibrary("OpenGL32");
    }
    // imgui
    dll.addPackage(imgui_pkg);
    dll.addIncludePath(IMGUI_BASE);
    dll.addIncludePath(STB_BASE);
    dll.addCSourceFiles(&IMGUI_SOURCES, &IMGUI_FLAGS);
    // dll.addCSourceFile("_external/stb_build.c", &.{});

    if (target.cpu_arch != std.Target.Cpu.Arch.wasm32) {
        dll.linkLibCpp();
        // glad
        dll.addIncludePath(GLAD_BASE ++ "/include");
        dll.addCSourceFile(GLAD_BASE ++ "/src/glad.c", &.{});
        dll.addCSourceFile("src/glad_placeholders.c", &.{});
    }
    dll.install();

    const dll_tests = b.addTest("src/main.zig");
    dll_tests.setTarget(target);
    dll_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&dll_tests.step);
}
