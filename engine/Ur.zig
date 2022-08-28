const std = @import("std");
const gl = @import("./gl.zig");
const Vertex = std.meta.Tuple(&.{ f32, f32, f32, f32, f32 });
const vertices = [3]Vertex{
    .{ -0.6, -0.4, 1.0, 0.0, 0.0 },
    .{ 0.6, -0.4, 0.0, 1.0, 0.0 },
    .{ 0.0, 0.6, 0.0, 0.0, 1.0 },
};

const vertex_shader_text = @embedFile("./shader.vs");
const fragment_shader_text = @embedFile("./shader.fs");
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
    gl.bufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.GL_STATIC_DRAW);

    const vertex_shader = gl.createShader(gl.GL_VERTEX_SHADER);
    gl.shaderSource(vertex_shader, &vertex_shader_text[0], vertex_shader_text.len);
    gl.compileShader(vertex_shader);

    const fragment_shader = gl.createShader(gl.GL_FRAGMENT_SHADER);
    gl.shaderSource(fragment_shader, &fragment_shader_text[0], fragment_shader_text.len);
    gl.compileShader(fragment_shader);

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
