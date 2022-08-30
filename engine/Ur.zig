const std = @import("std");
const builtin = @import("builtin");
const imgui = @import("imgui");
const imgui_opengl_backend = @import("./imgui_opengl_backend.zig");
const gl = @import("./gl.zig");
const glsl_version = if (builtin.target.cpu.arch == .wasm32) 300 else 130;
const logger = std.log.scoped(.Ur);

fn getShaderType(shader_type: gl.GLenum) []const u8 {
    return switch (shader_type) {
        gl.GL_VERTEX_SHADER => "vs",
        gl.GL_FRAGMENT_SHADER => "fs",
        else => "unknown",
    };
}

fn compileShader(shader_type: gl.GLenum, src: []const [*:0]const u8) !c_uint {
    const shader = gl.createShader(shader_type);
    errdefer gl.deleteShader(shader);
    gl.shaderSource(shader, @intCast(u32, src.len), &src[0]);
    gl.compileShader(shader);
    var compiled: gl.GLint = undefined;
    gl.getShaderiv(shader, gl.GL_COMPILE_STATUS, &compiled);
    if (compiled != gl.GL_TRUE) {
        var log_length: gl.GLsizei = undefined;
        var message: [1024]u8 = undefined;
        gl.getShaderInfoLog(shader, message.len, &log_length, &message[0]);
        logger.err("{s}: {s}", .{ getShaderType(shader_type), message[0..@intCast(usize, log_length)] });
        return error.compileError;
    }
    return shader;
}

const Vertex = std.meta.Tuple(&.{ f32, f32, f32, f32, f32 });
const vertices = [3]Vertex{
    .{ -0.6, -0.4, 1.0, 0.0, 0.0 },
    .{ 0.6, -0.4, 0.0, 1.0, 0.0 },
    .{ 0.0, 0.6, 0.0, 0.0, 1.0 },
};

const vertex_shader_text: [*:0]const u8 = @embedFile("./shader.vs");
const prefix = if (builtin.target.cpu.arch == .wasm32) "precision mediump float;\n" else "";
const fragment_shader_text: [*:0]const u8 = prefix ++ @embedFile("./shader.fs");
const Self = @This();

program: gl.GLuint = undefined,
mvp_location: gl.GLuint = undefined,
vpos_location: gl.GLuint = undefined,
vcol_location: gl.GLuint = undefined,
show_demo_window: bool = true,

pub fn init(allocator: std.mem.Allocator) !Self {
    var self = Self{};

    logger.info("OpenGL Version:  {s}", .{std.mem.span(gl.getString(gl.GL_VERSION))});
    logger.info("OpenGL Vendor:   {s}", .{std.mem.span(gl.getString(gl.GL_VENDOR))});
    logger.info("OpenGL Renderer: {s}", .{std.mem.span(gl.getString(gl.GL_RENDERER))});

    var vertex_buffer: gl.GLuint = undefined;
    gl.genBuffers(1, &vertex_buffer);
    gl.bindBuffer(gl.GL_ARRAY_BUFFER, vertex_buffer);
    gl.bufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.GL_STATIC_DRAW);

    const vertex_shader = try compileShader(gl.GL_VERTEX_SHADER, &.{vertex_shader_text});
    const fragment_shader = try compileShader(gl.GL_FRAGMENT_SHADER, &.{fragment_shader_text});

    self.program = gl.createProgram();
    gl.attachShader(self.program, vertex_shader);
    gl.attachShader(self.program, fragment_shader);
    gl.linkProgram(self.program);

    self.mvp_location = @intCast(gl.GLuint, gl.getUniformLocation(self.program, "MVP"));
    self.vpos_location = @intCast(gl.GLuint, gl.getAttribLocation(self.program, "vPos"));
    self.vcol_location = @intCast(gl.GLuint, gl.getAttribLocation(self.program, "vCol"));

    gl.enableVertexAttribArray(self.vpos_location);
    gl.vertexAttribPointer(self.vpos_location, 2, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), 0);
    gl.enableVertexAttribArray(self.vcol_location);
    gl.vertexAttribPointer(self.vcol_location, 3, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), @sizeOf(f32) * 2);

    _ = imgui.CreateContext(.{});
    var io = imgui.GetIO();
    _ = io;
    // _ = io.Fonts.?.AddFontDefault(.{});

    try imgui_opengl_backend.init(allocator, glsl_version);

    return self;
}

pub fn deinit(self: *Self) void {
    _ = self;
    imgui_opengl_backend.deinit();
    imgui.DestroyContext();
}

pub fn render(self: *Self, width: i32, height: i32) void {
    _ = self;
    _ = width;
    _ = height;

    {
        // update input
        var io = imgui.GetIO();
        io.DisplaySize = .{ .x = @intToFloat(f32, width), .y = @intToFloat(f32, height) };

        imgui_opengl_backend.newFrame() catch |err| {
            logger.err("{}", .{err});
        };
        imgui.NewFrame();

        // 1. Show the big demo window (Most of the sample code is in imgui.ShowDemoWindow()! You can browse its code to learn more about Dear ImGui!).
        // if (self.show_demo_window)
        //     imgui.ShowDemoWindow(.{ .p_open = &self.show_demo_window });

        // Rendering
        imgui.Render();
    }

    gl.viewport(0, 0, width, height);
    gl.clearColor(0.2, 0.5, 0.2, 1);
    gl.clear(gl.GL_COLOR_BUFFER_BIT);

    var mvp = [_]f32{
        1, 0, 0, 0, //
        0, 1, 0, 0, //
        0, 0, 1, 0, //
        0, 0, 0, 1, //
    };

    gl.useProgram(self.program);
    gl.uniformMatrix4fv(@intCast(c_int, self.mvp_location), 1, gl.GL_FALSE, &mvp[0]);
    gl.drawArrays(gl.GL_TRIANGLES, 0, 3);

    if (imgui.GetDrawData()) |data| {
        imgui_opengl_backend.renderDrawData(data) catch |err| {
            logger.err("{}", .{err});
        };
    }
}
