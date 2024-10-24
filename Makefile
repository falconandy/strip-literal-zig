build-wasm-release:
	zig build -Dtarget=wasm32-freestanding -Doptimize=ReleaseSmall -p . --prefix-exe-dir docs && du -sh -B1 --apparent-size ./docs/strip-literal.wasm

build-wasm-debug:
	zig build -Dtarget=wasm32-freestanding -p . --prefix-exe-dir docs && du -sh -B1 --apparent-size ./docs/strip-literal.wasm
