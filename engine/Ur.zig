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
const Self = @This();

program: gl.GLuint = undefined,
mvp_location: gl.GLuint = undefined,
vpos_location: gl.GLuint = undefined,
vcol_location: gl.GLuint = undefined,

pub fn init() Self {
    var self = Self{};

    var vertex_buffer: gl.GLuint = undefined;
    gl.genBuffers(1, &vertex_buffer);
    gl.bindBuffer(gl.GL_ARRAY_BUFFER, vertex_buffer);
    gl.bufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices[0][0], gl.GL_STATIC_DRAW);

    // const vertex_shader = gl.glCreateShader(gl.GL_VERTEX_SHADER);
    // gl.glShaderSource(vertex_shader, 1, &vertex_shader_text, null);
    // gl.glCompileShader(vertex_shader);

    // const fragment_shader = gl.glCreateShader(gl.GL_FRAGMENT_SHADER);
    // gl.glShaderSource(fragment_shader, 1, &fragment_shader_text, null);
    // gl.glCompileShader(fragment_shader);

    // self.program = gl.glCreateProgram();
    // gl.glAttachShader(self.program, vertex_shader);
    // gl.glAttachShader(self.program, fragment_shader);
    // gl.glLinkProgram(self.program);

    // self.mvp_location = @intCast(gl.GLuint, gl.glGetUniformLocation(self.program, "MVP"));
    // self.vpos_location = @intCast(gl.GLuint, gl.glGetAttribLocation(self.program, "vPos"));
    // self.vcol_location = @intCast(gl.GLuint, gl.glGetAttribLocation(self.program, "vCol"));

    // gl.glEnableVertexAttribArray(self.vpos_location);
    // gl.glVertexAttribPointer(self.vpos_location, 2, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), null);
    // gl.glEnableVertexAttribArray(self.vcol_location);
    // gl.glVertexAttribPointer(self.vcol_location, 3, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), @intToPtr(*anyopaque, @sizeOf(f32) * 2));

    return self;
}

pub fn render(self: Self, width: i32, height: i32) void {
    _ = self;
    gl.viewport(0, 0, width, height);
    gl.clearColor(0.2, 0.5, 0.2, 1);
    gl.clear(gl.GL_COLOR_BUFFER_BIT);

    // var mvp = [_]f32{
    //     1, 0, 0, 0, //
    //     0, 1, 0, 0, //
    //     0, 0, 1, 0, //
    //     0, 0, 0, 1, //
    // };

    // gl.glUseProgram(self.program);
    // gl.glUniformMatrix4fv(@intCast(c_int, self.mvp_location), 1, gl.GL_FALSE, &mvp);
    // gl.glDrawArrays(gl.GL_TRIANGLES, 0, 3);
}
