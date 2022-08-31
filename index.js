class Logger {
    constructor() {
        this.buffer = [];
    }

    logger(severity, ptr, len) {
        this.push(severity, memToString(ptr, len));
    }

    push(severity, last) {
        this.buffer.push(last);
        if (last.length > 0 && last[last.length - 1] == '\n') {
            const message = this.buffer.join('');
            this.buffer = [];
            switch (severity) {
                case 0:
                    console.error(message);
                    break;

                case 1:
                    console.warn(message);
                    break;

                case 2:
                    console.info(message);
                    break;

                default:
                    console.debug(message);
                    break;
            }
        }
    }
}
const g_logger = new Logger();

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

/**
 * @type WebGL2RenderingContext
 */
const gl = canvas.getContext('webgl2', webglOptions);
if (gl === null) {
    throw "WebGL を初期化できません。ブラウザーまたはマシンが対応していない可能性があります。";
}

const glVertexArrays = [];
// 0origin
const glUniformLocations = [];
// 1origin
const glPrograms = [];
const glShaders = [];
const glBuffers = [];
const glTextures = [];

const getMemory = () => new DataView(instance.exports.memory.buffer);

const memGet = (ptr, len) => new Uint8Array(getMemory().buffer, ptr, len);

const memToString = (ptr, len) => {
    let array = null;
    if (len) {
        array = memGet(ptr, len);
    }
    else {
        // zero terminated
        let i = 0;
        const buffer = new Uint8Array(getMemory().buffer, ptr);
        for (; i < buffer.length; ++i) {
            if (buffer[i] == 0) {
                break;
            }
        }
        array = new Uint8Array(getMemory().buffer, ptr, i);
    }
    const decoder = new TextDecoder()
    const text = decoder.decode(array)
    return text;
}

const memAllocString = (src) => {
    const buffer = (new TextEncoder).encode(src);
    const dstPtr = instance.exports.getGlobalAddress();
    const dst = new Uint8Array(getMemory().buffer, dstPtr, buffer.length);
    for (let i = 0; i < buffer.length; ++i) {
        dst[i] = buffer[i];
    }
    return dstPtr;
}

const memSetString = (dstPtr, maxLength, length, src) => {
    const buffer = (new TextEncoder).encode(src);
    const dst = new Uint8Array(getMemory().buffer, dstPtr, buffer.length);
    for (let i = 0; i < buffer.length && i < maxLength; ++i) {
        dst[i] = buffer[i];
    }
    const write_length = Math.min(buffer.len, maxLength);
    if (length) {
        getMemory().setUint32(length, write_length);
    }
    return write_length;
}

var importObject = {
    // https://github.com/ziglang/zig/blob/master/lib/std/os/wasi.zig
    wasi_snapshot_preview1: {
        args_get: (argv, argv_buf) => 0,
        args_sizes_get: (argc, argv_buf_size) => 0,
        // https://github.com/ziglang/zig/blob/9038528187932babc86558ec343511c635446a28/lib/std/os.zig#L994
        // const ciovs = [_]iovec_const{iovec_const{
        //     .iov_base = bytes.ptr,
        //     .iov_len = bytes.len,
        // }};
        fd_write: (fd, iovs, iovsLen, nwritten) => {
            // console.log(`*** call fd_write: fd=${fd}, iovs=${iovs}, iovsLen=${iovsLen}, nwritten=${nwritten}`)
            let totalSize = 0;
            // WASM is 32bit
            for (let i = 0; i < iovsLen; ++i, iovs += 8) {
                const size = getMemory().getUint32(iovs + 4, true);
                if (size) {
                    const msg = memToString(getMemory().getUint32(iovs, true), size).trim();
                    if (msg) {
                        console.log(msg)
                    }
                    totalSize += size;
                }
            }
            getMemory().setUint32(nwritten, totalSize, true)
            return 0
        },
        proc_exit: () => { },
        fd_prestat_get: () => { },
        fd_prestat_dir_name: () => { },
        fd_close: (fd) => 0,
        fd_fdstat_get: (fd, buf) => 0,
        fd_fdstat_set_flags: (fd, flags) => 0,
        fd_read: (fd, iovs, iovs_len, nread) => 0,
        fd_seek: (fd, offset, whence, newoffset) => 0,
        path_open: (dirfd, dirflags, path, path_len, oflags, fs_rights_base, fs_rights_inheriting, fs_flags, fd) => 0,
        environ_sizes_get: () => { },
        environ_get: () => { }
    },
    // https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext
    env: {
        console_logger: (level, ptr, len) => g_logger.logger(level, ptr, len),
        qsort: (base, num, size, compare) => { },
        //
        __stack_chk_fail: () => { throw ""; },
        memset: (buf, ch, n) => {
            const buffer = memGet(buf, n);
            for (let i = 0; i < buffer.length; ++i) {
                buffer[i] = ch;
            }
        },
        strlen: () => { throw ""; },
        memcpy: (dest, src, n) => {
            const d = memGet(dest, n);
            const s = memGet(src, n);
            for (let i = 0; i < n; ++i) {
                d[i] = s[i];
            }
        },
        __assert_fail: () => { throw ""; },
        strncpy: () => { throw ""; },
        memchr: () => { throw ""; },
        memmove: () => { throw ""; },
        vsnprintf: (s, n, format, arg) => {
            const fmt = memToString(format);
            return memSetString(s, n, null, "ProggyClean.ttf, 15px");
        },
        fopen: () => { throw ""; },
        fclose: () => { throw ""; },
        ftell: () => { throw ""; },
        fseek: () => { throw ""; },
        fread: () => { throw ""; },
        fwrite: () => { throw ""; },
        qsort: () => { },
        strcmp: () => { throw ""; },
        sscanf: () => { throw ""; },
        memcmp: () => { throw ""; },
        fflush: () => { throw ""; },
        strstr: () => { throw ""; },
        strncmp: () => { throw ""; },
        printf: () => { throw ""; },
        malloc: (size) => instance.exports.my_malloc(size),
        free: (ptr) => instance.exports.my_free(ptr),
        acosf: () => { throw ""; },
        //
        getString: (name) => {
            const param = gl.getParameter(name);
            if (typeof (param) == "string") {
                return memAllocString(param);
            }
            else {
                return memAllocString("no getString");
            }
        },
        isEnabled: (cap) => gl.isEnabled(cap),
        viewport: (x, y, width, height) => gl.viewport(x, y, width, height),
        scissor: (x, y, width, height) => gl.scissor(x, y, width, height),
        clear: (x) => gl.clear(x),
        clearColor: (r, g, b, a) => gl.clearColor(r, g, b, a),
        genBuffers: (num, dataPtr) => {
            for (let n = 0; n < num; n++, dataPtr += 4) {
                glBuffers.push(gl.createBuffer());
                getMemory().setUint32(dataPtr, glBuffers.length, true);
            }
        },
        bindBuffer: (type, bufferId) => {
            if (bufferId > 0) {
                gl.bindBuffer(type, glBuffers[bufferId - 1]);
            }
            else {
                gl.bindBuffer(type, null);
            }
        },
        bufferData: (type, count, dataPtr, drawType) => {
            const data = new Uint8Array(getMemory().buffer, Number(dataPtr), Number(count));
            gl.bufferData(type, data, drawType);
        },
        bufferSubData: (target, offset, size, dataPtr) => {
            const data = new Uint8Array(getMemory().buffer, Number(dataPtr), Number(size));
            gl.bufferSubData(target, offset, data);
        },
        createShader: (shaderType) => {
            glShaders.push(gl.createShader(shaderType));
            return glShaders.length;
        },
        deleteShader: (shader) => {
            if (shader > 0) {
                gl.deleteShader(glShaders[shader - 1]);
            }
        },
        shaderSource: (shader, count, srcs) => {
            if (shader <= 0) {
                return;
            }
            let list = [];
            for (let i = 0; i < count; ++i, srcs += 4) {
                const p = getMemory().getUint32(srcs, true);
                const item = memToString(p);
                list.push(item);
            }
            gl.shaderSource(glShaders[shader - 1], list.join(""));
        },
        compileShader: (shader) => {
            if (shader <= 0) {
                return;
            }
            gl.compileShader(glShaders[shader - 1]);
        },
        getShaderiv: (shader, pname, params) => {
            if (shader <= 0) {
                return;
            }
            const param = gl.getShaderParameter(glShaders[shader - 1], pname);
            if (pname == gl.COMPILE_STATUS) {
                if (param) {
                    // gl.GL_TRUE
                    getMemory().setUint32(params, 1, true);
                }
                else {
                    // gl.GL_TRUE
                    getMemory().setUint32(params, 0, true);
                }
            }
            else if (Number.isInteger(param)) {
                getMemory().setUint32(params, param, true);
            }
            else {
                console.warn(`getShaderParameter ${pname}: ${param}`);
            }
        },
        getShaderInfoLog: (shader, maxLength, length, infoLog) => {
            if (shader <= 0) {
                return;
            }
            const message = gl.getShaderInfoLog(glShaders[shader - 1]);
            if (typeof (message) == "string") {
                memSetString(infoLog, maxLength, length, message);
            }
            else {
                getMemory().setUint32(length, 0);
            }
        },
        createProgram: () => {
            glPrograms.push(gl.createProgram());
            return glPrograms.length;
        },
        attachShader: (program, shader) => {
            if (program <= 0) {
                return;
            }
            if (shader <= 0) {
                return;
            }
            gl.attachShader(glPrograms[program - 1], glShaders[shader - 1]);
        },
        detachShader: (program, shader) => {
            if (program <= 0) {
                return;
            }
            if (shader <= 0) {
                return;
            }
            gl.detachShader(glPrograms[program - 1], glShaders[shader - 1]);
        },
        linkProgram: (program) => {
            if (program <= 0) {
                return;
            }
            gl.linkProgram(glPrograms[program - 1]);
        },
        getProgramiv: (program, pname, params) => {
            if (program <= 0) {
                return;
            }
            const param = gl.getProgramParameter(glPrograms[program - 1], pname);
            if (pname == gl.LINK_STATUS) {
                if (param) {
                    // gl.GL_TRUE
                    getMemory().setUint32(params, 1, true);
                }
                else {
                    // gl.GL_TRUE
                    getMemory().setUint32(params, 0, true);
                }
            }
            else if (Number.isInteger(param)) {
                getMemory().setUint32(params, param);
            }
            else {
                console.warn(`getProgramParameter ${pname}: ${param}`);
            }
        },
        getProgramInfoLog: (program, maxLength, length, infoLog) => {
            if (program <= 0) {
                return;
            }
            const message = gl.getProgramInfoLog(glPrograms[program - 1]);
            if (typeof (message) == "string") {
                memSetString(infoLog, maxLength, length, message);
            }
            else {
                getMemory().setUint32(length, 0);
            }
        },
        getUniformLocation: (program, name) => {
            if (program <= 0) {
                return;
            }
            glUniformLocations.push(gl.getUniformLocation(glPrograms[program - 1], memToString(name)));
            return glUniformLocations.length - 1;
        },
        getAttribLocation: (program, name) => {
            if (program <= 0) {
                return;
            }
            return gl.getAttribLocation(glPrograms[program - 1], memToString(name));
        },
        enableVertexAttribArray: (index) => gl.enableVertexAttribArray(index),
        vertexAttribPointer: (index, size, type, normalized, stride, offset) => {
            gl.vertexAttribPointer(index, size, type, normalized, stride, Number(offset));
        },
        useProgram: (program) => {
            if (program <= 0) {
                return;
            }
            gl.useProgram(glPrograms[program - 1]);
        },
        uniformMatrix4fv: (location, count, transpose, value) => {
            const values = new Float32Array(getMemory().buffer, value, 16 * count);
            gl.uniformMatrix4fv(glUniformLocations[location], count, values, transpose);
        },
        uniform1i: (location, v0) => gl.uniform1i(location, v0),
        drawArrays: (mode, first, count) => gl.drawArrays(mode, first, count),
        drawElements: (mode, count, type, offset) => gl.drawElements(mode, count, type, offset),
        getIntegerv: (pname, data) => {
            const param = gl.getParameter(pname);
            if (Number.isInteger(param)) {
                getMemory().setUint32(data, param);
            }
            else {
                getMemory().setUint32(data, -1);
            }
        },
        bindTexture: (target, texture) => {
            if (texture <= 0) {
                gl.bindTexture(target, null);
            }
            else {
                gl.bindTexture(target, glTextures[texture - 1]);
            }
        },
        texImage2D: (target, level, internalFormat, width, height, border, format, type, data) => {
            let pixels = null;
            switch (format) {
                case gl.RGBA:
                    pixels = memGet(data, width * height * 4);
                    break;
                default:
                    logger.error(`unknown ${format}`);
                    break;
            }
            gl.texImage2D(target, level, internalFormat, width, height, border, format, type, pixels);
        },
        activeTexture: (texture) => gl.activeTexture(texture),
        genTextures: (n, textures) => {
            let ptr = textures;
            for (let i = 0; i < n; ++i, ptr += 4) {
                glTextures.push(gl.createTexture());
                getMemory().setUint32(ptr, glTextures.length);
            }
        },
        texParameteri: (target, pname, param) => gl.texParameteri(target, pname, param),
        pixelStorei: (pname, param) => gl.pixelStorei(pname, param),
        genVertexArrays: (n, arrays) => {
            let ptr = arrays;
            for (let i = 0; i < n; ++i, ptr += 4) {
                glVertexArrays.push(gl.createVertexArray());
                getMemory().setUint32(ptr, glVertexArrays.length);
            }
        },
        deleteVertexArrays: (n, array) => {
            let ptr = array;
            for (let i = 0; i < n; ++i) {
                const index = memGetUint32(ptr);
                gl.deleteVertexArray(index);
            }
        },
        bindVertexArray: (array) => {
            if (array > 0) {
                gl.bindVertexArray(glVertexArrays[array-1]);
            }
            else {
                gl.bindVertexArray(null);

            }
        },
        enable: (cap) => gl.enable(cap),
        disable: (cap) => gl.disable(cap),
        blendEquation: (mode) => gl.blendEquation(mode),
        blendFuncSeparate: (srcRGB, dstRGB, srcAlpha, dstAlpha) => gl.blendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha),
        blendEquationSeparate: (modeRGB, modeAlpha) => gl.blendEquationSeparate(modeRGB, modeAlpha),
    },
};

// get
const response = await fetch('zig-out/lib/Ur.wasm')
// byte array
const buffer = await response.arrayBuffer();
// compile
const compiled = await WebAssembly.compile(buffer);
// instanciate env に webgl などを埋め込む
const instance = await WebAssembly.instantiate(compiled, importObject);
console.log(instance);

// call
instance.exports.init();
function step(timestamp) {
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    canvas.width = w;
    canvas.height = h;
    instance.exports.render(w, h);
    // window.requestAnimationFrame(step);
}

window.requestAnimationFrame(step);
