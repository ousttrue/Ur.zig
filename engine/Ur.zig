const std = @import("std");
const gl = @import("./gl.zig");
const Vertex = std.meta.Tuple(&.{ f32, f32, f32, f32, f32 });
const vertices = [3]Vertex{
    .{ -0.6, -0.4, 1.0, 0.0, 0.0 },
    .{ 0.6, -0.4, 0.0, 1.0, 0.0 },
    .{ 0.0, 0.6, 0.0, 0.0, 1.0 },
};

const vertex_shader_text: [*:0]const u8 = @embedFile("./shader.vs");
const fragment_shader_text: [*:0]const u8 = @embedFile("./shader.fs");
var GL: gl.GL = undefined;
const Self = @This();

program: gl.GLuint = undefined,
mvp_location: gl.GLuint = undefined,
vpos_location: gl.GLuint = undefined,
vcol_location: gl.GLuint = undefined,

pub fn init(_GL: gl.GL) Self {
    GL = _GL;
    var self = Self{};

    // var vertex_buffer: gl.GLuint = undefined;
    // GL.glGenBuffers(1, &vertex_buffer);
    // GL.glBindBuffer(gl.GL_ARRAY_BUFFER, vertex_buffer);
    // GL.glBufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices[0][0], gl.GL_STATIC_DRAW);

    // const vertex_shader = GL.glCreateShader(gl.GL_VERTEX_SHADER);
    // GL.glShaderSource(vertex_shader, 1, &vertex_shader_text, null);
    // GL.glCompileShader(vertex_shader);

    // const fragment_shader = GL.glCreateShader(gl.GL_FRAGMENT_SHADER);
    // GL.glShaderSource(fragment_shader, 1, &fragment_shader_text, null);
    // GL.glCompileShader(fragment_shader);

    // self.program = GL.glCreateProgram();
    // GL.glAttachShader(self.program, vertex_shader);
    // GL.glAttachShader(self.program, fragment_shader);
    // GL.glLinkProgram(self.program);

    // self.mvp_location = @intCast(gl.GLuint, GL.glGetUniformLocation(self.program, "MVP"));
    // self.vpos_location = @intCast(gl.GLuint, GL.glGetAttribLocation(self.program, "vPos"));
    // self.vcol_location = @intCast(gl.GLuint, GL.glGetAttribLocation(self.program, "vCol"));

    // GL.glEnableVertexAttribArray(self.vpos_location);
    // GL.glVertexAttribPointer(self.vpos_location, 2, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), null);
    // GL.glEnableVertexAttribArray(self.vcol_location);
    // GL.glVertexAttribPointer(self.vcol_location, 3, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), @intToPtr(*anyopaque, @sizeOf(f32) * 2));

    return self;
}

pub fn render(self: Self, width: i32, height: i32) void {
    _ = self;
    GL.glViewport(0, 0, width, height);
    GL.glClear(gl.GL_COLOR_BUFFER_BIT);

    // var mvp = [_]f32{
    //     1, 0, 0, 0, //
    //     0, 1, 0, 0, //
    //     0, 0, 1, 0, //
    //     0, 0, 0, 1, //
    // };

    // GL.glUseProgram(self.program);
    // GL.glUniformMatrix4fv(@intCast(c_int, self.mvp_location), 1, gl.GL_FALSE, &mvp);
    // GL.glDrawArrays(gl.GL_TRIANGLES, 0, 3);
}
