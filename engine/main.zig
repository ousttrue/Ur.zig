const std = @import("std");
const builtin = @import("builtin");
const Ur = @import("./Ur.zig");
const logger = std.log.scoped(.main);
pub const gl = @import("./gl.zig");

var global_string: [1024]u8 = undefined;

pub export fn getGlobalAddress() *u8 {
    return &global_string[0];
}

// init OpenGL by glad
const GLADloadproc = ?fn ([*c]const u8) callconv(.C) ?*anyopaque;
pub extern fn gladLoadGLLoader(GLADloadproc) c_int;
pub export fn loadproc(ptr: *const anyopaque) void {
    if (builtin.target.cpu.arch != .wasm32) {
        _ = gladLoadGLLoader(@ptrCast(GLADloadproc, ptr));
    }
}

// wasi
pub export fn main(_: c_int, _: **u8) c_int {
    return 0;
}

var ur: ?Ur = null;
pub export fn render(width: c_int, height: c_int) void {
    _ = width;
    _ = height;
    if (ur == null) {
        ur = Ur.init(std.heap.page_allocator) catch {
            @panic("fail to init");
        };
    }
    if (ur) |*r| {
        r.render(width, height);
    }
}
