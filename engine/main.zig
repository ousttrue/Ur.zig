const std = @import("std");
const builtin = @import("builtin");
const Ur = @import("./Ur.zig");
const logger = std.log.scoped(.main);
pub const gl = @import("./gl.zig");

pub extern fn console_logger(level: c_int, ptr: *const u8, size: c_int) void;

fn extern_write(level: c_int, m: []const u8) error{}!usize {
    if (m.len > 0) {
        console_logger(level, &m[0], @intCast(c_int, m.len));
    }
    return m.len;
}

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    if (builtin.target.cpu.arch == .wasm32) {
        const level = switch (message_level) {
            .err => 0,
            .warn => 1,
            .info => 2,
            .debug => 3,
        };
        const w = std.io.Writer(c_int, error{}, extern_write){
            .context = level,
        };
        w.print(format, args) catch |err| {
            const err_name = @errorName(err);
            extern_write(0, err_name) catch unreachable;
        };
        _ = extern_write(level, "\n") catch unreachable;
    } else {
        std.log.defaultLog(message_level, scope, format, args);
    }
}

var global_string: [1024]u8 = undefined;

pub export fn getGlobalAddress() *u8 {
    return &global_string[0];
}

var gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined;
var allocator: std.mem.Allocator = undefined;
var map: std.AutoHashMap([*]u8, usize) = undefined;

pub export fn init() void {
    logger.info("init", .{});
    gpa = std.heap.GeneralPurposeAllocator(.{}){};
    allocator = gpa.allocator();
    map = std.AutoHashMap([*]u8, usize).init(allocator);
}

pub export fn deinit() void {
    map.deinit();
    std.debug.assert(!gpa.deinit());
}

pub export fn my_malloc(size: u32) *u8 {
    const buffer = allocator.alloc(u8, size) catch {
        @panic("malloc");
    };
    var p = &buffer[0];
    map.put(@ptrCast([*]u8, p), buffer.len) catch {
        @panic("malloc put");
    };
    return p;
}

pub export fn my_free(ptr: [*]u8) void {
    if (map.get(ptr)) |size| {
        const buffer = ptr[0..size];
        allocator.free(buffer);
    } else {
        @panic("free");
    }
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
