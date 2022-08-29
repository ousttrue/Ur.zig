const std = @import("std");
const builtin = @import("builtin");
const imgui = @import("imgui");
const gl = @import("./gl.zig");
const logger = std.log.scoped(.imgui_opengl_backend);

// OpenGL Data
const Data = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    // Extracted at runtime using GL_MAJOR_VERSION, GL_MINOR_VERSION queries (e.g. 320 for GL 3.2)
    GlVersion: gl.GLuint = 0,
    // Specified by user or detected based on compile time GL settings.
    GlslVersionString: [:0]const u8,
    FontTexture: gl.GLuint = 0,
    ShaderHandle: gl.GLuint = 0,
    // Uniforms location
    AttribLocationTex: gl.GLint = 0,
    AttribLocationProjMtx: gl.GLint = 0,
    // Vertex attributes location
    AttribLocationVtxPos: gl.GLuint = 0,
    AttribLocationVtxUV: gl.GLuint = 0,
    AttribLocationVtxColor: gl.GLuint = 0,
    VboHandle: c_uint = 0,
    ElementsHandle: c_uint = 0,
    VertexBufferSize: gl.GLsizeiptr = 0,
    IndexBufferSize: gl.GLsizeiptr = 0,
    HasClipOrigin: bool = false,
    UseBufferSubData: bool = false,

    fn new(allocator: std.mem.Allocator, GlslVersionString: [:0]const u8) !*Self {
        var self = try allocator.create(Self);
        self.* = Self{
            .allocator = allocator,
            .GlslVersionString = GlslVersionString,
        };
        return self;
    }

    fn delete(self: *Self) void {
        // ImGui_ImplOpenGL3_ShutdownPlatformInterface();
        // ImGui_ImplOpenGL3_DestroyDeviceObjects();
        self.allocator.destroy(self);
    }

    // Backend data stored in io.BackendRendererUserData to allow support for multiple Dear ImGui contexts
    // It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
    fn get() ?*Self {
        if (imgui.GetCurrentContext()) |_| {
            return @ptrCast(?*Self, @alignCast(@alignOf(Self), imgui.GetIO().BackendRendererUserData));
        }
        return null;
    }

    // If you get an error please report on github. You may try different GL context version or GLSL version. See GL<>GLSL version table at the top of this file.
    fn checkShader(self: Self, handle: gl.GLuint, desc: []const u8) !void {
        var status: gl.GLint = 0;
        gl.getShaderiv(handle, gl.GL_COMPILE_STATUS, &status);
        if (status == gl.GL_TRUE) {
            return;
        }
        var log_length: gl.GLint = 0;
        gl.getShaderiv(handle, gl.GL_INFO_LOG_LENGTH, &log_length);
        if (status == gl.GL_FALSE) {
            logger.err("ERROR: ImGui_ImplOpenGL3_CreateDeviceObjects: failed to compile {s}! With GLSL: {s}", .{ desc, self.GlslVersionString });
        }
        if (log_length > 1) {
            var buf = try self.allocator.allocSentinel(u8, @intCast(usize, log_length), 0);
            defer self.allocator.free(buf);
            gl.getShaderInfoLog(handle, log_length, null, &buf[0]);
            logger.err("{s}", .{buf});
        }
        return error.compileError;
    }

    // If you get an error please report on GitHub. You may try different GL context version or GLSL version.
    fn checkProgram(self: Self, handle: gl.GLuint, desc: []const u8) !void {
        var status: gl.GLint = 0;
        gl.getProgramiv(handle, gl.GL_LINK_STATUS, &status);
        if (status == gl.GL_TRUE) {
            return;
        }
        var log_length: gl.GLint = 0;
        gl.getProgramiv(handle, gl.GL_INFO_LOG_LENGTH, &log_length);
        if (status == gl.GL_FALSE) {
            logger.err("ERROR: ImGui_ImplOpenGL3_CreateDeviceObjects: failed to link {s}! With GLSL {s}", .{ desc, self.GlslVersionString });
        }
        if (log_length > 1) {
            var buf = try self.allocator.allocSentinel(u8, @intCast(usize, log_length), 0);
            defer self.allocator.free(buf);
            gl.getProgramInfoLog(handle, log_length, null, &buf[0]);
            logger.err("{s}", .{buf});
        }
        return error.programError;
    }

    fn createFontsTexture(self: *Self) bool {
        _ = self;
        var io = imgui.GetIO();

        // Build texture atlas
        var pixels: ?*u8 = undefined;
        var width: c_int = undefined;
        var height: c_int = undefined;
        io.Fonts.?.GetTexDataAsRGBA32(&pixels, &width, &height, .{}); // Load as RGBA 32-bit (75% of the memory is wasted, but default font is so small) because it is more likely to be compatible with user's existing shaders. If your ImTextureId represent a higher-level concept than just a GL texture id, consider calling GetTexDataAsAlpha8() instead to save on GPU memory.

        // Upload texture to graphics system
        // (Bilinear sampling is required by default. Set 'io.Fonts->Flags |= ImFontAtlasFlags_NoBakedLines' or 'style.AntiAliasedLinesUseTex = false' to allow point/nearest sampling)
        var last_texture: gl.GLint = undefined;
        gl.getIntegerv(gl.GL_TEXTURE_BINDING_2D, &last_texture);
        gl.genTextures(1, &self.FontTexture);
        gl.bindTexture(gl.GL_TEXTURE_2D, self.FontTexture);
        gl.texParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR);
        gl.texParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR);
        if (builtin.target.cpu.arch != .wasm32) {
            // #ifdef GL_UNPACK_ROW_LENGTH // Not on WebGL/ES
            gl.pixelStorei(gl.GL_UNPACK_ROW_LENGTH, 0);
        } else {
            gl.texImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, width, height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, pixels);
        }

        // Store our identifier
        // io.Fonts.?.SetTexID(@intToPtr(*anyopaque, self.FontTexture));
        io.Fonts.?.TexID = @intToPtr(*anyopaque, self.FontTexture);

        // Restore state
        gl.bindTexture(gl.GL_TEXTURE_2D, @intCast(c_uint, last_texture));

        return true;
    }

    fn createDeviceObjects(self: *Self) !void {
        // Backup GL state
        var last_texture: gl.GLint = undefined;
        gl.getIntegerv(gl.GL_TEXTURE_BINDING_2D, &last_texture);
        var last_array_buffer: gl.GLint = undefined;
        gl.getIntegerv(gl.GL_ARRAY_BUFFER_BINDING, &last_array_buffer);

        var last_vertex_array: gl.GLint = undefined;
        gl.getIntegerv(gl.GL_VERTEX_ARRAY_BINDING, &last_vertex_array);

        // Parse GLSL version string
        var glsl_version: c_int = 130;
        // c.sscanf(&bd.GlslVersionString[0], "#version %d", &glsl_version);
        const vertex_shader_glsl_120: [:0]const u8 = @embedFile("./imgui_120.vs");
        const vertex_shader_glsl_130: [:0]const u8 = @embedFile("./imgui_130.vs");
        const vertex_shader_glsl_300_es: [:0]const u8 = @embedFile("./imgui_300.vs");
        const vertex_shader_glsl_410_core: [:0]const u8 = @embedFile("./imgui_410.vs");
        const fragment_shader_glsl_120: [:0]const u8 = @embedFile("./imgui_120.fs");
        const fragment_shader_glsl_130: [:0]const u8 = @embedFile("./imgui_130.fs");
        const fragment_shader_glsl_300_es: [:0]const u8 = @embedFile("./imgui_300.fs");
        const fragment_shader_glsl_410_core: [:0]const u8 = @embedFile("./imgui_410.fs");

        // Select shaders matching our GLSL versions
        var vertex_shader: [:0]const u8 = "";
        var fragment_shader: [:0]const u8 = "";
        if (glsl_version < 130) {
            vertex_shader = vertex_shader_glsl_120;
            fragment_shader = fragment_shader_glsl_120;
        } else if (glsl_version >= 410) {
            vertex_shader = vertex_shader_glsl_410_core;
            fragment_shader = fragment_shader_glsl_410_core;
        } else if (glsl_version == 300) {
            vertex_shader = vertex_shader_glsl_300_es;
            fragment_shader = fragment_shader_glsl_300_es;
        } else {
            vertex_shader = vertex_shader_glsl_130;
            fragment_shader = fragment_shader_glsl_130;
        }

        // Create shaders
        const vertex_shader_with_version = [_][*:0]const u8{ self.GlslVersionString, "\n", vertex_shader };
        const vert_handle = gl.createShader(gl.GL_VERTEX_SHADER);
        gl.shaderSource(vert_handle, @intCast(u32, vertex_shader_with_version.len), &vertex_shader_with_version[0]);
        gl.compileShader(vert_handle);
        try self.checkShader(vert_handle, "vertex shader");

        const fragment_shader_with_version = [_][*:0]const u8{ self.GlslVersionString, "\n", fragment_shader };
        const frag_handle = gl.createShader(gl.GL_FRAGMENT_SHADER);
        gl.shaderSource(frag_handle, @intCast(u32, fragment_shader_with_version.len), &fragment_shader_with_version[0]);
        gl.compileShader(frag_handle);
        try self.checkShader(frag_handle, "fragment shader");

        // Link
        self.ShaderHandle = gl.createProgram();
        gl.attachShader(self.ShaderHandle, vert_handle);
        gl.attachShader(self.ShaderHandle, frag_handle);
        gl.linkProgram(self.ShaderHandle);
        try self.checkProgram(self.ShaderHandle, "shader program");

        gl.detachShader(self.ShaderHandle, vert_handle);
        gl.detachShader(self.ShaderHandle, frag_handle);
        gl.deleteShader(vert_handle);
        gl.deleteShader(frag_handle);

        self.AttribLocationTex = @intCast(c_int, gl.getUniformLocation(self.ShaderHandle, "Texture"));
        self.AttribLocationProjMtx = @intCast(c_int, gl.getUniformLocation(self.ShaderHandle, "ProjMtx"));
        self.AttribLocationVtxPos = gl.getAttribLocation(self.ShaderHandle, "Position");
        self.AttribLocationVtxUV = gl.getAttribLocation(self.ShaderHandle, "UV");
        self.AttribLocationVtxColor = gl.getAttribLocation(self.ShaderHandle, "Color");

        // Create buffers
        gl.genBuffers(1, &self.VboHandle);
        gl.genBuffers(1, &self.ElementsHandle);

        _ = self.createFontsTexture();

        // Restore modified GL state
        gl.bindTexture(gl.GL_TEXTURE_2D, @intCast(c_uint, last_texture));
        gl.bindBuffer(gl.GL_ARRAY_BUFFER, @intCast(c_uint, last_array_buffer));

        gl.bindVertexArray(@intCast(c_uint, last_vertex_array));
    }
};

pub fn init(allocator: std.mem.Allocator, glsl_version: [:0]const u8) !void {
    _ = glsl_version;

    var io = imgui.GetIO();
    if (io.BackendRendererUserData != null) {
        @panic("Already initialized a renderer backend!");
    }

    const bd = try Data.new(allocator, glsl_version);
    io.BackendRendererUserData = bd;
    io.BackendRendererName = "imgui_impl_Ur.zig";
}

pub fn deinit() void {
    var bd = Data.get() orelse {
        @panic("No renderer backend to shutdown, or already shutdown?");
    };
    bd.delete();

    var io = imgui.GetIO();
    io.BackendRendererName = null;
    io.BackendRendererUserData = null;
}

pub fn newFrame() !void {
    var bd = Data.get() orelse {
        @panic("Did you call ImGui_ImplOpenGL3_Init()?");
    };
    if (bd.ShaderHandle == 0) {
        try bd.createDeviceObjects();
    }
}

pub fn renderDrawData(draw_data: *const imgui.ImDrawData) void {
    _ = draw_data;
}
