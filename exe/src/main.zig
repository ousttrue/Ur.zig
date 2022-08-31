const std = @import("std");
const c = @import("c");
const engine = @import("./engine_extern.zig");

var input: engine.FrameInput = undefined;

fn mouse_button_callback(window: ?*c.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
    _ = window;
    _ = mods;
    switch (button) {
        c.GLFW_MOUSE_BUTTON_LEFT => {
            input.flags.left_down = action == c.GLFW_PRESS;
        },
        c.GLFW_MOUSE_BUTTON_RIGHT => {
            input.flags.right_down = action == c.GLFW_PRESS;
        },
        c.GLFW_MOUSE_BUTTON_MIDDLE => {
            input.flags.middle_down = action == c.GLFW_PRESS;
        },
        else => {},
    }
}

fn scroll_callback(window: ?*c.GLFWwindow, xoffset: f64, yoffset: f64) callconv(.C) void {
    _ = window;
    _ = xoffset;
    input.wheel = @floatToInt(c_int, yoffset);
}

pub fn main() anyerror!void {

    // Initialize the library
    std.debug.assert(c.glfwInit() == 1);
    defer c.glfwTerminate();

    // Create a windowed mode window and its OpenGL context
    const window = c.glfwCreateWindow(1024, 768, "Ur.zig", null, null);
    std.debug.assert(window != null);
    defer c.glfwDestroyWindow(window);

    _ = c.glfwSetMouseButtonCallback(window, mouse_button_callback);
    _ = c.glfwSetScrollCallback(window, scroll_callback);

    // Make the window's context current
    c.glfwMakeContextCurrent(window);
    c.glfwSwapInterval(1);

    engine.loadproc(c.glfwGetProcAddress);

    // Loop until the user closes the window
    while (c.glfwWindowShouldClose(window) == 0) {
        // Poll for and process events
        c.glfwPollEvents();

        c.glfwGetFramebufferSize(window, &input.width, &input.height);
        var xpos: f64 = undefined;
        var ypos: f64 = undefined;
        c.glfwGetCursorPos(window, &xpos, &ypos);
        input.cursor_x = @floatCast(f32, xpos);
        input.cursor_y = @floatCast(f32, ypos);

        // Render here
        engine.render(&input);

        // clear
        input.wheel = 0;

        // Swap front and back buffers
        c.glfwSwapBuffers(window);
    }
}
