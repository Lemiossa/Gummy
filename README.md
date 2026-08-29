# Gummy

A simple hobby operating system for x86 architecture.

## Requirements

- NASM
- QEMU(optional, for tests)
- dosfstools
- mtools
- GCC 15.2.0 cross-compiler for the specified architecture(with libgcc and binutils 2.45)

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
## cross-compiler

Dependencies for building the cross-compiler:
- make
- bison
- flex
- gmp
- mpc
- mpfr
- texinfo
- isl (optional)

For more information, please refer to the [GCC Installation Guide](https://gcc.gnu.org/install/).

You can build the cross-compiler using the following commands:

### binutils
```bash
mkdir -p ~/cross
cd ~/cross
wget https://ftp.gnu.org/gnu/binutils/binutils-2.45.tar.gz
tar -xvf binutils-2.45.tar.gz
cd binutils-2.45
mkdir build
cd build
../configure --target=i686-elf \
  --prefix="/usr/local" \
  --with-sysroot \
  --disable-nls \
  --disable-werror \
  --enable-default-execstack=no
make -j$(nproc)
sudo make install
```

### gcc
```bash
cd ~/cross
wget https://ftp.gnu.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.gz
tar -xvf gcc-15.2.0.tar.gz
cd gcc-15.2.0
mkdir build
cd build
../configure \
  --target=i686-elf \
  --prefix="/usr/local" \
  --disable-nls \
  --enable-languages=c \
  --without-headers \
  --enable-initfini-array
make -j$(nproc) all-gcc
sudo make install-gcc
make -j$(nproc) all-target-libgcc
sudo make install-target-libgcc
```

## License

MIT
