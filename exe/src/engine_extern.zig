const std = @import("std");
pub const FrameInput = @import("./frame_input.zig").FrameInput;

pub extern fn loadproc(ptr: *const anyopaque) void;
pub extern fn render(input: *const FrameInput) void;
