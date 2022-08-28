const std = @import("std");
const logger = std.log.scoped(.gl);

// Types
pub const GLuint = c_uint;
pub const GLenum = c_uint;
pub const GLint = c_int;
pub const GLfloat = f32;

// Identifier constants pulled from WebGLRenderingContext
pub const GL_VERTEX_SHADER: c_uint = 35633;
pub const GL_FRAGMENT_SHADER: c_uint = 35632;
pub const GL_ARRAY_BUFFER: c_uint = 34962;
pub const GL_TRIANGLES: c_uint = 4;
pub const GL_TRIANGLE_STRIP = 5;
pub const GL_STATIC_DRAW: c_uint = 35044;
pub const GL_FLOAT: c_uint = 5126;
pub const GL_DEPTH_TEST: c_uint = 2929;
pub const GL_LEQUAL: c_uint = 515;
pub const GL_COLOR_BUFFER_BIT: c_uint = 16384;
pub const GL_DEPTH_BUFFER_BIT: c_uint = 256;
pub const GL_STENCIL_BUFFER_BIT = 1024;
pub const GL_TEXTURE_2D: c_uint = 3553;
pub const GL_RGBA: c_uint = 6408;
pub const GL_UNSIGNED_BYTE: c_uint = 5121;
pub const GL_TEXTURE_MAG_FILTER: c_uint = 10240;
pub const GL_TEXTURE_MIN_FILTER: c_uint = 10241;
pub const GL_NEAREST: c_uint = 9728;
pub const GL_TEXTURE0: c_uint = 33984;
pub const GL_BLEND: c_uint = 3042;
pub const GL_SRC_ALPHA: c_uint = 770;
pub const GL_ONE_MINUS_SRC_ALPHA: c_uint = 771;
pub const GL_ONE: c_uint = 1;
pub const GL_NO_ERROR = 0;
pub const GL_FALSE = 0;
pub const GL_TRUE = 1;
pub const GL_UNPACK_ALIGNMENT = 3317;

pub const GL_TEXTURE_WRAP_S = 10242;
pub const GL_CLAMP_TO_EDGE = 33071;
pub const GL_TEXTURE_WRAP_T = 10243;
pub const GL_PACK_ALIGNMENT = 3333;

pub const GL = struct {
    const Self = @This();

    glViewport: fn (_: c_int, _: c_int, _: c_int, _: c_int) callconv(.Inline) void = undefined,
    // glClearColor: fn (_: f32, _: f32, _: f32, _: f32) callconv(.Inline) void = undefined,
    // glEnable: fn (_: c_uint) callconv(.Inline) void = undefined,
    // glDepthFunc: fn (_: c_uint) callconv(.Inline) void = undefined,
    // glBlendFunc: fn (_: c_uint, _: c_uint) callconv(.Inline) void = undefined,
    glClear: fn (_: c_uint) callconv(.Inline) void = undefined,
    // glGetAttribLocation: fn (_: c_uint, _: [*:0]const u8) callconv(.Inline) c_int = undefined,
    // glGetUniformLocation: fn (_: c_uint, _: [*:0]const u8) callconv(.Inline) c_int = undefined,
    // glUniform4f: fn (_: c_int, _: f32, _: f32, _: f32, _: f32) callconv(.Inline) void = undefined,
    // glUniform1i: fn (_: c_int, _: c_int) callconv(.Inline) void = undefined,
    // glUniform1f: fn (_: c_int, _: f32) callconv(.Inline) void = undefined,
    // glUniformMatrix4fv: fn (_: c_int, _: c_int, _: u8, _: [*]const f32) callconv(.Inline) void = undefined,
    // glCreateVertexArray: fn () callconv(.Inline) c_uint = undefined,
    // glGenVertexArrays: fn (_: c_int, [*c]c_uint) callconv(.Inline) void = undefined,
    // glDeleteVertexArrays: fn (_: c_int, [*c]c_uint) callconv(.Inline) void = undefined,
    // glBindVertexArray: fn (_: c_uint) callconv(.Inline) void = undefined,
    // glCreateBuffer: fn () callconv(.Inline) c_uint = undefined,
    // glGenBuffers: fn (_: c_int, _: [*c]c_uint) callconv(.Inline) void = undefined,
    // glDeleteBuffers: fn (_: c_int, _: [*c]c_uint) callconv(.Inline) void = undefined,
    // glDeleteBuffer: fn (_: c_uint) callconv(.Inline) void = undefined,
    // glBindBuffer: fn (_: c_uint, _: c_uint) callconv(.Inline) void = undefined,
    // glBufferData: fn (_: c_uint, _: c_uint, _: [*c]const f32, _: c_uint) callconv(.Inline) void = undefined,
    // glPixelStorei: fn (_: c_uint, _: c_int) callconv(.Inline) void = undefined,
    // glAttachShader: fn (_: c_uint, _: c_uint) callconv(.Inline) void = undefined,
    // glDetachShader: fn (_: c_uint, _: c_uint) callconv(.Inline) void = undefined,
    // glDeleteShader: fn (_: c_uint) callconv(.Inline) void = undefined,
    // glUseProgram: fn (_: c_uint) callconv(.Inline) void = undefined,
    // glDeleteProgram: fn (_: c_uint) callconv(.Inline) void = undefined,
    // glEnableVertexAttribArray: fn (_: c_uint) callconv(.Inline) void = undefined,
    // glVertexAttribPointer: fn (_: c_uint, _: c_uint, _: c_uint, _: c_uint, _: c_uint, _: ?*const anyopaque) callconv(.Inline) void = undefined,
    // glDrawArrays: fn (_: c_uint, _: c_uint, _: c_uint) callconv(.Inline) void = undefined,
    // glCreateTexture: fn () callconv(.Inline) c_uint = undefined,
    // glGenTextures: fn (_: c_int, _: [*c]c_uint) callconv(.Inline) void = undefined,
    // glDeleteTextures: fn (_: c_int, _: [*c]const c_uint) callconv(.Inline) void = undefined,
    // glDeleteTexture: fn (_: c_uint) callconv(.Inline) void = undefined,
    // glBindTexture: fn (_: c_uint, _: c_uint) callconv(.Inline) void = undefined,
    // glTexImage2D: fn (_: c_uint, _: c_uint, _: c_uint, _: c_int, _: c_int, _: c_uint, _: c_uint, _: c_uint, _: [*]const u8, _: c_uint) callconv(.Inline) void = undefined,
    // glTexParameteri: fn (_: c_uint, _: c_uint, _: c_uint) callconv(.Inline) void = undefined,
    // glActiveTexture: fn (_: c_uint) callconv(.Inline) void = undefined,
    // glGetError: fn () callconv(.Inline) c_int = undefined,
    // glCreateShader: fn (shaderType: c_uint) callconv(.Inline) c_uint = undefined,
    // glShaderSource: fn (shader: c_uint, count: c_uint, string: *const [*]const u8, length: [*c]const c_int) callconv(.Inline) void = undefined,
    // glCompileShader: fn (shader: c_uint) callconv(.Inline) void = undefined,
    // glCreateProgram: fn () callconv(.Inline) c_uint = undefined,
    // glLinkProgram: fn (program: c_uint) callconv(.Inline) void = undefined,

    pub fn from(t: anytype) Self {
        var self = Self{};

        inline for (@typeInfo(Self).Struct.fields) |field| {
            if (@hasDecl(t, field.name)) {
                logger.debug("field: {s}", .{field.name});
                @field(self, field.name) = (&@field(t, field.name)).*;
            } else {
                logger.warn("no field: {s}", .{field.name});
            }
        }

        return self;
    }
};
