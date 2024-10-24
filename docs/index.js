const WASM_URL = 'strip-literal.wasm';

let wasm;
let initWasm;

if ('instantiateStreaming' in WebAssembly) {
    initWasm = WebAssembly.instantiateStreaming(fetch(WASM_URL)).then(function (obj) {
        wasm = obj.instance;
    })
} else {
    initWasm = fetch(WASM_URL).then(resp =>
        resp.arrayBuffer()
    ).then(bytes =>
        WebAssembly.instantiate(bytes).then(function (obj) {
            wasm = obj.instance;
        })
    )
}

initWasm.then(() => {
    document.getElementById("strip").onclick = stripLiterals;
});

function writeString(source) {
    const encoder = new TextEncoder();
    const data = encoder.encode(source);
    const ptr = wasm.exports.malloc(data.length);
    let wasmMem = wasm.exports.memory.buffer
    let mem = new Int8Array(wasmMem);
    mem.set(data, ptr);
    return [ptr, data.length];
}

function readString(ptr, size) {
    let memory = wasm.exports.memory;
    let bytes = memory.buffer.slice(Number(ptr), Number(ptr + size));
    const decoder = new TextDecoder("utf-8");
    return decoder.decode(bytes);
}

function stripLiterals() {
    const language = +document.getElementById("language").value;
    const commentsMode = +document.getElementById("comments").value;
    const stringsMode = +document.getElementById("strings").value;
    const stripMode = stringsMode*4 + commentsMode;
 
    const [codePtr, codeSize] = writeString(document.getElementById("source").value);
    try {
        const resultSize = wasm.exports.stripLiterals(codePtr, codeSize, language, stripMode);
        const result = readString(codePtr, resultSize);
        document.getElementById("result").value = result;
    } finally {
        wasm.exports.free(codePtr);
    }
}