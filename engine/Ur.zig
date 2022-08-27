const std = @import("std");
const c = @import("c");
const Vertex = std.meta.Tuple(&.{ f32, f32, f32, f32, f32 });
const vertices = [3]Vertex{
    .{ -0.6, -0.4, 1.0, 0.0, 0.0 },
    .{ 0.6, -0.4, 0.0, 1.0, 0.0 },
    .{ 0.0, 0.6, 0.0, 0.0, 1.0 },
};

const vertex_shader_text: [*:0]const u8 = @embedFile("./shader.vs");
const fragment_shader_text: [*:0]const u8 = @embedFile("./shader.fs");
const Self = @This();

program: c.GLuint = undefined,
mvp_location: c.GLuint = undefined,
vpos_location: c.GLuint = undefined,
vcol_location: c.GLuint = undefined,

pub fn init() Self {
    var self = Self{};

    var vertex_buffer: c.GLuint = undefined;
    c.glGenBuffers(1, &vertex_buffer);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vertex_buffer);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

    const vertex_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vertex_shader, 1, &vertex_shader_text, null);
    c.glCompileShader(vertex_shader);

    const fragment_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fragment_shader, 1, &fragment_shader_text, null);
    c.glCompileShader(fragment_shader);

    self.program = c.glCreateProgram();
    c.glAttachShader(self.program, vertex_shader);
    c.glAttachShader(self.program, fragment_shader);
    c.glLinkProgram(self.program);

    self.mvp_location = @intCast(c.GLuint, c.glGetUniformLocation(self.program, "MVP"));
    self.vpos_location = @intCast(c.GLuint, c.glGetAttribLocation(self.program, "vPos"));
    self.vcol_location = @intCast(c.GLuint, c.glGetAttribLocation(self.program, "vCol"));

    c.glEnableVertexAttribArray(self.vpos_location);
    c.glVertexAttribPointer(self.vpos_location, 2, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Vertex), null);
    c.glEnableVertexAttribArray(self.vcol_location);
    c.glVertexAttribPointer(self.vcol_location, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Vertex), @intToPtr(*anyopaque, @sizeOf(f32) * 2));

    return self;
}

pub fn render(self: Self, width: i32, height: i32) void {
    c.glViewport(0, 0, width, height);
    c.glClear(c.GL_COLOR_BUFFER_BIT);

    var mvp = [_]f32{
        1, 0, 0, 0, //
        0, 1, 0, 0, //
        0, 0, 1, 0, //
        0, 0, 0, 1, //
    };

    c.glUseProgram(self.program);
    c.glUniformMatrix4fv(@intCast(c_int, self.mvp_location), 1, c.GL_FALSE, &mvp);
    c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}
