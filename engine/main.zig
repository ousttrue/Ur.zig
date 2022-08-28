const builtin = @import("builtin");
const Ur = @import("./Ur.zig");
pub const gl = @import("./gl.zig");

// init OpenGL by glad
const GLADloadproc = ?fn ([*c]const u8) callconv(.C) ?*anyopaque;
pub extern fn gladLoadGLLoader(GLADloadproc) c_int;
pub export fn loadproc(ptr: *const anyopaque) void {
    if (builtin.target.cpu.arch != .wasm32) {
        _ = gladLoadGLLoader(@ptrCast(GLADloadproc, ptr));
    }
}

var ur: ?Ur = null;
pub export fn render(width: c_int, height: c_int) void {
    if (ur == null) {
        ur = Ur.init();
    }
    if (ur) |r| {
        r.render(width, height);
    }
}
