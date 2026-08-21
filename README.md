# Gummy

A simple hobby operating system for x86 architecture.

## Building

```bash
make
```

This produces `build/images/Gummy-<version>.img`, where the version comes
from the `VERSION` variable in the root `Makefile`. Both the kernel and the
bootloader receive the `NAME` and `VERSION` macros at compile time.

## Running

```bash
make qemu
```

For QEMU without GUI:

```bash
make qemu-ng
```

## Cleaning

```bash
make clean
```

## Requirements

- NASM
- QEMU
- dosfstools
- mtools
- GCC 15.2.0 cross-compiler for the specified architecture(with libgcc and binutils 2.45)

## License

MIT
