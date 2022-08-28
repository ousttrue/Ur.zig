const canvas = document.querySelector("#gl");
const webglOptions = {
    alpha: true, //Boolean that indicates if the canvas contains an alpha buffer.
    antialias: true,  //Boolean that indicates whether or not to perform anti-aliasing.
    depth: 32,  //Boolean that indicates that the drawing buffer has a depth buffer of at least 16 bits.
    failIfMajorPerformanceCaveat: false,  //Boolean that indicates if a context will be created if the system performance is low.
    powerPreference: "default", //A hint to the user agent indicating what configuration of GPU is suitable for the WebGL context. Possible values are:
    premultipliedAlpha: true,  //Boolean that indicates that the page compositor will assume the drawing buffer contains colors with pre-multiplied alpha.
    preserveDrawingBuffer: true,  //If the value is true the buffers will not be cleared and will preserve their values until cleared or overwritten by the author.
    stencil: true, //Boolean that indicates that the drawing buffer has a stencil buffer of at least 8 bits.
};

const gl = canvas.getContext('webgl2', webglOptions);
if (gl === null) {
    throw "WebGL を初期化できません。ブラウザーまたはマシンが対応していない可能性があります。";
}

const glShaders = [];
const glPrograms = [];
const glVertexArrays = [];
const glBuffers = [];
const glTextures = [];
const glUniformLocations = [];

const glCreateBuffer = () => {
    glBuffers.push(gl.createBuffer());
    return glBuffers.length - 1;
}

const readCharStr = (buffer, ptr, len) => {
    const array = new Uint8Array(buffer, ptr, len)
    const decoder = new TextDecoder()
    return decoder.decode(array)
}

var importObject = {
    imports: {
        imported_func: function (arg) {
            console.log(arg);
        }
    },
    env: {
        viewport: (x, y, width, height) => gl.viewport(x, y, width, height),
        clear: (x) => gl.clear(x),
        clearColor: (r, g, b, a) => gl.clearColor(r, g, b, a),
        genBuffers: (num, dataPtr) => {
            const buffers = new Uint32Array(memory.buffer, dataPtr, num);
            for (let n = 0; n < num; n++) {
                const b = glCreateBuffer();
                buffers[n] = b;
            }
        },
        bindBuffer: (type, bufferId) => gl.bindBuffer(type, glBuffers[bufferId]),
        bufferData: (type, count, dataPtr, drawType) => {
            const floats = new Uint8Array(memory.buffer, Number(dataPtr), Number(count));
            gl.bufferData(type, floats, drawType);
        },
        createShader: (shaderType) => {
            glShaders.push(gl.createShader(shaderType));
            return glShaders.length - 1;
        },
        shaderSource: (shader, string, length) => {
            const text = readCharStr(memory.buffer, string, length);
            gl.shaderSource(glShaders[shader], text);
        },
        compileShader: (shader) => {
            gl.compileShader(glShaders[shader]);
            const success = gl.getShaderParameter(glShaders[shader], gl.COMPILE_STATUS);
            if (!success) {
                console.error(gl.getShaderInfoLog(glShaders[shader]));
            }
        },
        createProgram: () => {
            glPrograms.push(gl.createProgram());
            return glPrograms.length - 1;
        },
        attachShader: (program, shader) => gl.attachShader(glPrograms[program], glShaders[shader]),
        linkProgram: (program) => {
            gl.linkProgram(glPrograms[program]);
            const success = gl.getProgramParameter(glPrograms[program], gl.LINK_STATUS);
            if (!success) {
                console.error(gl.getProgramInfoLog(glPrograms[program]));
            }
        },
        getUniformLocation: (program, name, length) => {
            const text = readCharStr(memory.buffer, name, length);
            glUniformLocations.push(gl.getUniformLocation(glPrograms[program], text));
            return glUniformLocations.length - 1;
        },
        getAttribLocation: (program, name, length) => {
            const text = readCharStr(memory.buffer, name, length);
            return gl.getAttribLocation(glPrograms[program], text);
        },
        enableVertexAttribArray: (index) => gl.enableVertexAttribArray(index),
        vertexAttribPointer: (index, size, type, normalized, stride, offset) => {
            gl.vertexAttribPointer(index, size, type, normalized, stride, Number(offset));
        },
        useProgram: (program) => gl.useProgram(glPrograms[program]),
        uniformMatrix4fv: (location, count, transpose, value) => {
            const values = new Float32Array(memory.buffer, value, 16 * count);
            gl.uniformMatrix4fv(glUniformLocations[location], count, values, transpose);
        },
        drawArrays: (mode, first, count) => gl.drawArrays(mode, first, count),
    },
};

// get
const response = await fetch('zig-out/lib/Ur.zig.wasm')
// byte array
const buffer = await response.arrayBuffer();
// compile
const compiled = await WebAssembly.compile(buffer);
// instanciate env に webgl などを埋め込む
const instance = await WebAssembly.instantiate(compiled, importObject);
console.log(instance);
const memory = instance.exports.memory;

// call
function step(timestamp) {
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    canvas.width = w;
    canvas.height = h;
    instance.exports.render(w, h);
    window.requestAnimationFrame(step);
}

window.requestAnimationFrame(step);
