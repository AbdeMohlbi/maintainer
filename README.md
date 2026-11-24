# Maintainer

requires zig [0.17.1](https://ziglang.org/documentation/0.17.1/)

inspired by [posix_utilities](https://github.com/AbdeMohlbi/posix_utilities)

### Build command

```zig
zig build-exe src/main.zig --name Maintainer
```

### To build and deploy to other machines

```sh
zig build-exe src/main.zig --name Maintainer
mkdir dist
cp Maintainer dist/
chmod +x dist/Maintainer
ditto -c -k --sequesterRsrc dist Maintainer.zip
```