# Ur.zig

An engine that shares zig code between OpenGL and WebGL(wasm).

```
  +---------+
  |Ur.zig   |
  +---------+
  ^         ^
  |dll      |wasm
+-------+ +-------+
|Desktop| |Browser|
|GLFW   | |WebGL  |
+-------+ +-------+
```

## wasm build

- <https://github.com/fabioarnold/hello-webgl>

```
$ zig build -Dtarget=wasm32-freestanding
```

## TODO

- [x] Triangle
- [ ] ImGui
- [ ] glTF Scene
- [ ] PBR Material
- [ ] VRM
