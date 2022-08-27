var importObject = {
    imports: {
        imported_func: function (arg) {
            console.log(arg);
        }
    },
    env: {
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
// call
const value = instance.exports.add(1, 2);
console.log(value);
