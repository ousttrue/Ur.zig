const std = @import("std");

// https://devlog.hexops.com/2022/packed-structs-in-zig/
pub const Flags = packed struct {
    left_down: bool = false,
    right_down: bool = false,
    middle_down: bool = false,
    is_active: bool = false,
    is_hover: bool = false,

    _padding: u11 = undefined,

    comptime {
        std.debug.assert(@sizeOf(@This()) == @sizeOf(u16));
        std.debug.assert(@bitSizeOf(@This()) == @bitSizeOf(u16));
    }
};

pub const FrameInput = extern struct {
    const Self = @This();

    width: c_int = 1,
    height: c_int = 1,
    cursor_x: f32 = 0,
    cursor_y: f32 = 0,
    wheel: c_int = 0,
    flags: Flags = .{},
};
