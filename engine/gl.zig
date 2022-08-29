// Types
pub const GLboolean = u8;
pub const GLuint = c_uint;
pub const GLenum = c_uint;
pub const GLbitfield = c_uint;
pub const GLint = c_int;
pub const GLsizei = c_int;
pub const GLsizeiptr = c_longlong;
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

pub const GL_COMPILE_STATUS = 0x8B81;
pub const GL_TEXTURE_BINDING_2D = 0x8069;
pub const GL_ARRAY_BUFFER_BINDING = 0x8894;
pub const GL_VERTEX_ARRAY_BINDING = 0x85B5;
pub const GL_INFO_LOG_LENGTH = 0x8B84;
pub const GL_LINK_STATUS = 0x8B82;
pub const GL_LINEAR = 0x2601;
pub const GL_UNPACK_ROW_LENGTH = 0x0CF2;

// [wasm] inject WebGL when instanciate by importObject
// [desktop] inject OpenGL when link with glad_placeholders.c
pub extern fn viewport(x: GLint, y: GLint, width: GLsizei, height: GLsizei) void;
pub extern fn clearColor(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat) void;
pub extern fn clear(mask: GLbitfield) void;
pub extern fn genBuffers(n: GLsizei, buffers: *GLuint) void;
pub extern fn bindBuffer(target: GLenum, buffer: GLuint) void;
pub extern fn bufferData(target: GLenum, size: GLsizeiptr, data: *const anyopaque, usage: GLenum) void;
pub extern fn createShader(shaderType: GLenum) c_uint;
pub extern fn deleteShader(shader: GLuint) void;
pub extern fn shaderSource(shader: GLuint, count: GLuint, string: *const [*:0]const u8) void;
pub extern fn compileShader(shader: GLuint) void;
pub extern fn getShaderiv(shader: GLuint, pname: GLenum, params: *GLint) void;
pub extern fn getShaderInfoLog(shader: GLuint, maxLength: GLsizei, length: ?*GLsizei, infoLog: *u8) void;
pub extern fn createProgram() GLuint;
pub extern fn attachShader(program: GLuint, shader: GLuint) void;
pub extern fn detachShader(program: GLuint, shader: GLuint) void;
pub extern fn linkProgram(program: GLuint) void;
pub extern fn getProgramiv(program: GLuint, pname: GLenum, params: *GLint) void;
pub extern fn getProgramInfoLog(program: GLuint, maxLength: GLsizei, length: ?*GLsizei, infoLog: *u8) void;
pub extern fn getUniformLocation(program: GLuint, name: [*:0]const u8) GLuint;
pub extern fn getAttribLocation(program: GLuint, name: [*:0]const u8) GLuint;
pub extern fn enableVertexAttribArray(index: GLuint) void;
pub extern fn vertexAttribPointer(index: GLuint, size: GLint, type: GLenum, normalized: GLboolean, stride: GLsizei, offset: GLsizeiptr) void;
pub extern fn useProgram(program: GLuint) void;
pub extern fn uniformMatrix4fv(location: GLint, count: GLsizei, transpose: GLboolean, value: *const GLfloat) void;
pub extern fn drawArrays(mode: GLenum, first: GLint, count: GLsizei) void;
pub extern fn getIntegerv(pname: GLenum, data: *GLint) void;
pub extern fn bindTexture(target: GLenum, texture: GLuint) void;
pub extern fn bindVertexArray(array: GLuint) void;
pub extern fn genTextures(n: GLsizei, textures: *GLuint) void;
pub extern fn texParameteri(target: GLenum, pname: GLenum, param: GLint) void;
pub extern fn pixelStorei(pname: GLenum, param: GLint) void;
