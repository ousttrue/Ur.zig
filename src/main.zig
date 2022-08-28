const std = @import("std");
const c = @import("c");
const engine = @import("engine_extern.zig");

pub fn main() anyerror!void {

    // Initialize the library
    std.debug.assert(c.glfwInit() == 1);
    defer c.glfwTerminate();

    // Create a windowed mode window and its OpenGL context
    const window = c.glfwCreateWindow(640, 480, "Hello World", null, null);
    std.debug.assert(window != null);
    defer c.glfwDestroyWindow(window);

    // Make the window's context current
    c.glfwMakeContextCurrent(window);
    c.glfwSwapInterval(1);

    engine.loadproc(c.glfwGetProcAddress);

    // Loop until the user closes the window
    while (c.glfwWindowShouldClose(window) == 0) {
        var width: c_int = undefined;
        var height: c_int = undefined;
        c.glfwGetFramebufferSize(window, &width, &height);
        // ratio = width / (float) height;

        // Render here
        engine.render(width, height);

        // Swap front and back buffers
        c.glfwSwapBuffers(window);
        // Poll for and process events
        c.glfwPollEvents();
    }
}
