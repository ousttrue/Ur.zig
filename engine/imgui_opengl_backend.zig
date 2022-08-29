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
        // (Bilinear sampling is required by default. Set 'io.Fonts.Flags |= ImFontAtlasFlags_NoBakedLines' or 'style.AntiAliasedLinesUseTex = false' to allow point/nearest sampling)
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
        // c.sscanf(&self.GlslVersionString[0], "#version %d", &glsl_version);
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

    fn render(self: *Data, draw_data: *const imgui.ImDrawData) void {
        // Avoid rendering when minimized, scale coordinates for retina displays (screen coordinates != framebuffer coordinates)
        const fb_width = @floatToInt(i32, draw_data.DisplaySize.x * draw_data.FramebufferScale.x);
        const fb_height = @floatToInt(i32, draw_data.DisplaySize.y * draw_data.FramebufferScale.y);
        if (fb_width <= 0 or fb_height <= 0)
            return;

        // Backup GL state
        var last_active_texture: gl.GLint = undefined;
        gl.getIntegerv(gl.GL_ACTIVE_TEXTURE, &last_active_texture);
        gl.activeTexture(gl.GL_TEXTURE0);
        var last_program: gl.GLint = undefined;
        gl.getIntegerv(gl.GL_CURRENT_PROGRAM, &last_program);
        var last_texture: gl.GLint = undefined;
        gl.getIntegerv(gl.GL_TEXTURE_BINDING_2D, &last_texture);
        // #ifdef IMGUI_IMPL_OPENGL_MAY_HAVE_BIND_SAMPLER
        //     GLuint last_sampler; if (self.GlVersion >= 330) { glGetIntegerv(GL_SAMPLER_BINDING, (GLint*)&last_sampler); } else { last_sampler = 0; }
        // #endif
        var last_array_buffer: gl.GLint = undefined;
        gl.getIntegerv(gl.GL_ARRAY_BUFFER_BINDING, &last_array_buffer);
        // #ifndef IMGUI_IMPL_OPENGL_USE_VERTEX_ARRAY
        //     // This is part of VAO on OpenGL 3.0+ and OpenGL ES 3.0+.
        //     GLint last_element_array_buffer; glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &last_element_array_buffer);
        //     ImGui_ImplOpenGL3_VtxAttribState last_vtx_attrib_state_pos; last_vtx_attrib_state_pos.GetState(self.AttribLocationVtxPos);
        //     ImGui_ImplOpenGL3_VtxAttribState last_vtx_attrib_state_uv; last_vtx_attrib_state_uv.GetState(self.AttribLocationVtxUV);
        //     ImGui_ImplOpenGL3_VtxAttribState last_vtx_attrib_state_color; last_vtx_attrib_state_color.GetState(self.AttribLocationVtxColor);
        // #endif
        var last_vertex_array_object: gl.GLint = undefined;
        gl.getIntegerv(gl.GL_VERTEX_ARRAY_BINDING, &last_vertex_array_object);
        // #ifdef IMGUI_IMPL_HAS_POLYGON_MODE
        //     GLint last_polygon_mode[2]; glGetIntegerv(GL_POLYGON_MODE, last_polygon_mode);
        // #endif
        //     GLint last_viewport[4]; glGetIntegerv(GL_VIEWPORT, last_viewport);
        //     GLint last_scissor_box[4]; glGetIntegerv(GL_SCISSOR_BOX, last_scissor_box);
        //     GLenum last_blend_src_rgb; glGetIntegerv(GL_BLEND_SRC_RGB, (GLint*)&last_blend_src_rgb);
        //     GLenum last_blend_dst_rgb; glGetIntegerv(GL_BLEND_DST_RGB, (GLint*)&last_blend_dst_rgb);
        //     GLenum last_blend_src_alpha; glGetIntegerv(GL_BLEND_SRC_ALPHA, (GLint*)&last_blend_src_alpha);
        //     GLenum last_blend_dst_alpha; glGetIntegerv(GL_BLEND_DST_ALPHA, (GLint*)&last_blend_dst_alpha);
        //     GLenum last_blend_equation_rgb; glGetIntegerv(GL_BLEND_EQUATION_RGB, (GLint*)&last_blend_equation_rgb);
        //     GLenum last_blend_equation_alpha; glGetIntegerv(GL_BLEND_EQUATION_ALPHA, (GLint*)&last_blend_equation_alpha);
        //     GLboolean last_enable_blend = glIsEnabled(GL_BLEND);
        //     GLboolean last_enable_cull_face = glIsEnabled(GL_CULL_FACE);
        //     GLboolean last_enable_depth_test = glIsEnabled(GL_DEPTH_TEST);
        //     GLboolean last_enable_stencil_test = glIsEnabled(GL_STENCIL_TEST);
        //     GLboolean last_enable_scissor_test = glIsEnabled(GL_SCISSOR_TEST);
        // #ifdef IMGUI_IMPL_OPENGL_MAY_HAVE_PRIMITIVE_RESTART
        //     GLboolean last_enable_primitive_restart = (self.GlVersion >= 310) ? glIsEnabled(GL_PRIMITIVE_RESTART) : GL_FALSE;
        // #endif

        // Setup desired GL state
        // Recreate the VAO every time (this is to easily allow multiple GL contexts to be rendered to. VAO are not shared among GL contexts)
        // The renderer would actually work without any VAO bound, but then our VertexAttrib calls would overwrite the default one currently bound.
        var vertex_array_object: gl.GLuint = 0;
        gl.genVertexArrays(1, &vertex_array_object);
        self.setupRenderState(draw_data, fb_width, fb_height, vertex_array_object);

        // Will project scissor/clipping rectangles into framebuffer space
        const clip_off = draw_data.DisplayPos; // (0,0) unless using multi-viewports
        const clip_scale = draw_data.FramebufferScale; // (1,1) unless using retina display which are often (2,2)

        // Render command lists
        for (@ptrCast([*]*imgui.ImDrawList, draw_data.CmdLists.?)[0..@intCast(usize, draw_data.CmdListsCount)]) |cmd_list| {

            // Upload vertex/index buffers
            // - On Intel windows drivers we got reports that regular glBufferData() led to accumulating leaks when using multi-viewports, so we started using orphaning + glBufferSubData(). (See https://github.com/ocornut/imgui/issues/4468)
            // - On NVIDIA drivers we got reports that using orphaning + glBufferSubData() led to glitches when using multi-viewports.
            // - OpenGL drivers are in a very sorry state in 2022, for now we are switching code path based on vendors.
            const vtx_buffer_size = cmd_list.VtxBuffer.Size * @sizeOf(imgui.ImDrawVert);
            const idx_buffer_size = cmd_list.IdxBuffer.Size * @sizeOf(u16);
            if (self.UseBufferSubData) {
                if (self.VertexBufferSize < vtx_buffer_size) {
                    self.VertexBufferSize = vtx_buffer_size;
                    gl.bufferData(gl.GL_ARRAY_BUFFER, self.VertexBufferSize, null, gl.GL_STREAM_DRAW);
                }
                if (self.IndexBufferSize < idx_buffer_size) {
                    self.IndexBufferSize = idx_buffer_size;
                    gl.bufferData(gl.GL_ELEMENT_ARRAY_BUFFER, self.IndexBufferSize, null, gl.GL_STREAM_DRAW);
                }
                gl.bufferSubData(gl.GL_ARRAY_BUFFER, 0, vtx_buffer_size, cmd_list.VtxBuffer.Data);
                gl.bufferSubData(gl.GL_ELEMENT_ARRAY_BUFFER, 0, idx_buffer_size, cmd_list.IdxBuffer.Data);
            } else {
                gl.bufferData(gl.GL_ARRAY_BUFFER, vtx_buffer_size, cmd_list.VtxBuffer.Data, gl.GL_STREAM_DRAW);
                gl.bufferData(gl.GL_ELEMENT_ARRAY_BUFFER, idx_buffer_size, cmd_list.IdxBuffer.Data, gl.GL_STREAM_DRAW);
            }

            const p = @ptrCast([*]const imgui.ImDrawCmd, @alignCast(@alignOf(imgui.ImDrawCmd), cmd_list.CmdBuffer.Data));
            for (p[0..@intCast(usize, cmd_list.CmdBuffer.Size)]) |*pcmd| {
                //             const ImDrawCmd* pcmd = &cmd_list.CmdBuffer[cmd_i];
                if (pcmd.UserCallback != null) {
                    // User callback, registered via ImDrawList::AddCallback()
                    // (ImDrawCallback_ResetRenderState is a special callback value used by the user to request the renderer to reset render state.)
                    // if (pcmd.UserCallback == imgui.ImDrawCallback_ResetRenderState) {
                    self.setupRenderState(draw_data, fb_width, fb_height, vertex_array_object);
                    // } else {
                    //     pcmd.UserCallback(cmd_list, pcmd);
                    // }
                } else {
                    // Project scissor/clipping rectangles into framebuffer space
                    const clip_min = imgui.ImVec2{ .x = (pcmd.ClipRect.x - clip_off.x) * clip_scale.x, .y = (pcmd.ClipRect.y - clip_off.y) * clip_scale.y };
                    const clip_max = imgui.ImVec2{ .x = (pcmd.ClipRect.z - clip_off.x) * clip_scale.x, .y = (pcmd.ClipRect.w - clip_off.y) * clip_scale.y };
                    if (clip_max.x <= clip_min.x or clip_max.y <= clip_min.y)
                        continue;

                    // Apply scissor/clipping rectangle (Y is inverted in OpenGL)
                    gl.scissor(
                        @floatToInt(c_int, clip_min.x),
                        @floatToInt(c_int, (@intToFloat(f32, fb_height) - clip_max.y)),
                        @floatToInt(c_int, (clip_max.x - clip_min.x)),
                        @floatToInt(c_int, (clip_max.y - clip_min.y)),
                    );

                    // Bind texture, Draw
                    gl.bindTexture(gl.GL_TEXTURE_2D, @intCast(u32, @ptrToInt(pcmd.TextureId)));
                    // #ifdef IMGUI_IMPL_OPENGL_MAY_HAVE_VTX_OFFSET
                    //                 if (self.GlVersion >= 320)
                    //                     glDrawElementsBaseVertex(GL_TRIANGLES, (GLsizei)pcmd.ElemCount, sizeof(ImDrawIdx) == 2 ? GL_UNSIGNED_SHORT : GL_UNSIGNED_INT, (void*)(intptr_t)(pcmd.IdxOffset * sizeof(ImDrawIdx)), (GLint)pcmd.VtxOffset);
                    //                 else
                    // #endif
                    gl.drawElements(
                        gl.GL_TRIANGLES,
                        @intCast(c_int, pcmd.ElemCount),
                        gl.GL_UNSIGNED_SHORT,
                        pcmd.IdxOffset * 2,
                    );
                }
            }
        }

        // Destroy the temporary VAO
        gl.deleteVertexArrays(1, &vertex_array_object);

        // Restore modified GL state
        gl.useProgram(@intCast(u32, last_program));
        gl.bindTexture(gl.GL_TEXTURE_2D, @intCast(u32, last_texture));
        // #ifdef IMGUI_IMPL_OPENGL_MAY_HAVE_BIND_SAMPLER
        //     if (self.GlVersion >= 330)
        //         glBindSampler(0, last_sampler);
        // #endif
        gl.activeTexture(@intCast(u32, last_active_texture));
        gl.bindVertexArray(@intCast(u32, last_vertex_array_object));
        gl.bindBuffer(gl.GL_ARRAY_BUFFER, @intCast(u32, last_array_buffer));
        //     glBlendEquationSeparate(last_blend_equation_rgb, last_blend_equation_alpha);
        //     glBlendFuncSeparate(last_blend_src_rgb, last_blend_dst_rgb, last_blend_src_alpha, last_blend_dst_alpha);
        //     if (last_enable_blend) glEnable(GL_BLEND); else glDisable(GL_BLEND);
        //     if (last_enable_cull_face) glEnable(GL_CULL_FACE); else glDisable(GL_CULL_FACE);
        //     if (last_enable_depth_test) glEnable(GL_DEPTH_TEST); else glDisable(GL_DEPTH_TEST);
        //     if (last_enable_stencil_test) glEnable(GL_STENCIL_TEST); else glDisable(GL_STENCIL_TEST);
        //     if (last_enable_scissor_test) glEnable(GL_SCISSOR_TEST); else glDisable(GL_SCISSOR_TEST);
        // #ifdef IMGUI_IMPL_OPENGL_MAY_HAVE_PRIMITIVE_RESTART
        //     if (self.GlVersion >= 310) { if (last_enable_primitive_restart) glEnable(GL_PRIMITIVE_RESTART); else glDisable(GL_PRIMITIVE_RESTART); }
        // #endif

        // #ifdef IMGUI_IMPL_HAS_POLYGON_MODE
        //     glPolygonMode(GL_FRONT_AND_BACK, (GLenum)last_polygon_mode[0]);
        // #endif
        //     glViewport(last_viewport[0], last_viewport[1], (GLsizei)last_viewport[2], (GLsizei)last_viewport[3]);
        //     glScissor(last_scissor_box[0], last_scissor_box[1], (GLsizei)last_scissor_box[2], (GLsizei)last_scissor_box[3]);
        //     (void)bd; // Not all compilation paths use this

    }

    fn setupRenderState(self: Data, draw_data: *const imgui.ImDrawData, fb_width: i32, fb_height: i32, vertex_array_object: gl.GLuint) void {
        // Setup render state: alpha-blending enabled, no face culling, no depth testing, scissor enabled, polygon fill
        gl.enable(gl.GL_BLEND);
        gl.blendEquation(gl.GL_FUNC_ADD);
        gl.blendFuncSeparate(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA, gl.GL_ONE, gl.GL_ONE_MINUS_SRC_ALPHA);
        gl.disable(gl.GL_CULL_FACE);
        gl.disable(gl.GL_DEPTH_TEST);
        gl.disable(gl.GL_STENCIL_TEST);
        gl.enable(gl.GL_SCISSOR_TEST);
        // if (self.GlVersion >= 310)
        //     gl.disable(gl.GL_PRIMITIVE_RESTART);
        // gl.PolygonMode(gl.GL_FRONT_AND_BACK, gl.GL_FILL);

        // Setup viewport, orthographic projection matrix
        // Our visible imgui space lies from draw_data.DisplayPos (top left) to draw_data.DisplayPos+data_data.DisplaySize (bottom right). DisplayPos is (0,0) for single viewport apps.
        gl.viewport(0, 0, fb_width, fb_height);
        const L = draw_data.DisplayPos.x;
        const R = draw_data.DisplayPos.x + draw_data.DisplaySize.x;
        const T = draw_data.DisplayPos.y;
        const B = draw_data.DisplayPos.y + draw_data.DisplaySize.y;
        const ortho_projection = [4][4]f32{
            .{ 2.0 / (R - L), 0.0, 0.0, 0.0 },
            .{ 0.0, 2.0 / (T - B), 0.0, 0.0 },
            .{ 0.0, 0.0, -1.0, 0.0 },
            .{ (R + L) / (L - R), (T + B) / (B - T), 0.0, 1.0 },
        };
        gl.useProgram(self.ShaderHandle);
        gl.uniform1i(self.AttribLocationTex, 0);
        gl.uniformMatrix4fv(self.AttribLocationProjMtx, 1, gl.GL_FALSE, &ortho_projection[0][0]);

        // #ifdef IMGUI_IMPL_OPENGL_MAY_HAVE_BIND_SAMPLER
        //     if (self.GlVersion >= 330)
        //         glBindSampler(0, 0); // We use combined texture/sampler state. Applications using GL 3.3 may set that otherwise.
        // #endif

        gl.bindVertexArray(vertex_array_object);

        // Bind vertex/index buffers and setup attributes for ImDrawVert
        gl.bindBuffer(gl.GL_ARRAY_BUFFER, self.VboHandle);
        gl.bindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, self.ElementsHandle);
        gl.enableVertexAttribArray(self.AttribLocationVtxPos);
        gl.enableVertexAttribArray(self.AttribLocationVtxUV);
        gl.enableVertexAttribArray(self.AttribLocationVtxColor);
        gl.vertexAttribPointer(self.AttribLocationVtxPos, 2, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(imgui.ImDrawVert), @offsetOf(imgui.ImDrawVert, "pos"));
        gl.vertexAttribPointer(self.AttribLocationVtxUV, 2, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(imgui.ImDrawVert), @offsetOf(imgui.ImDrawVert, "uv"));
        gl.vertexAttribPointer(self.AttribLocationVtxColor, 4, gl.GL_UNSIGNED_BYTE, gl.GL_TRUE, @sizeOf(imgui.ImDrawVert), @offsetOf(imgui.ImDrawVert, "col"));
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
    var bd = Data.get() orelse {
        @panic("Did you call ImGui_ImplOpenGL3_Init()?");
    };

    bd.render(draw_data);
}
