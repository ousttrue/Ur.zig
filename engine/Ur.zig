const std = @import("std");
const builtin = @import("builtin");
const gl = @import("./gl.zig");
const logger = std.log.scoped(.Ur);

fn getShaderType(shader_type: gl.GLenum) []const u8 {
    return switch (shader_type) {
        gl.GL_VERTEX_SHADER => "vs",
        gl.GL_FRAGMENT_SHADER => "fs",
        else => {
            unreachable;
        },
    };
}

fn compileShader(shader_type: gl.GLenum, src: []const u8) !c_uint {
    const shader = gl.createShader(shader_type);
    errdefer gl.deleteShader(shader);
    gl.shaderSource(shader, &src[0], @intCast(c_uint, src.len));
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

const vertex_shader_text = @embedFile("./shader.vs");
const prefix = if (builtin.target.cpu.arch == .wasm32) "precision mediump float;\n" else "";
const fragment_shader_text = prefix ++ @embedFile("./shader.fs");
const Self = @This();

program: gl.GLuint = undefined,
mvp_location: gl.GLuint = undefined,
vpos_location: gl.GLuint = undefined,
vcol_location: gl.GLuint = undefined,

// wasi
pub export fn main(_: c_int, _: **u8) c_int {
    return 0;
}

pub fn init() Self {
    var self = Self{};

    logger.debug("", .{});

    var vertex_buffer: gl.GLuint = undefined;
    gl.genBuffers(1, &vertex_buffer);
    gl.bindBuffer(gl.GL_ARRAY_BUFFER, vertex_buffer);
    gl.bufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.GL_STATIC_DRAW);

    const vertex_shader = compileShader(gl.GL_VERTEX_SHADER, vertex_shader_text) catch {
        unreachable;
    };
    const fragment_shader = compileShader(gl.GL_FRAGMENT_SHADER, fragment_shader_text) catch {
        unreachable;
    };

    self.program = gl.createProgram();
    gl.attachShader(self.program, vertex_shader);
    gl.attachShader(self.program, fragment_shader);
    gl.linkProgram(self.program);

    self.mvp_location = @intCast(gl.GLuint, gl.getUniformLocation(self.program, "MVP", 3));
    self.vpos_location = @intCast(gl.GLuint, gl.getAttribLocation(self.program, "vPos", 4));
    self.vcol_location = @intCast(gl.GLuint, gl.getAttribLocation(self.program, "vCol", 4));

    gl.enableVertexAttribArray(self.vpos_location);
    gl.vertexAttribPointer(self.vpos_location, 2, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), 0);
    gl.enableVertexAttribArray(self.vcol_location);
    gl.vertexAttribPointer(self.vcol_location, 3, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), @sizeOf(f32) * 2);

    return self;
}

pub fn render(self: Self, width: i32, height: i32) void {
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
}
