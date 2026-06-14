#!/bin/sh

set -e

NEEDED_COMMANDS="curl tar make"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Verify all commands needed
echo "Verifying dependencies..."
for cmd in $NEEDED_COMMANDS; do
        if ! command -v $cmd >/dev/null 2>&1; then
            echo "The command '$cmd' is missing";
            exit 1
        fi 
        echo "Found '$cmd'"
done

BINUTILS_VERSION="2.46.0"
GCC_VERSION="16.1.0"

BINUTILS_URL="https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.gz"
GCC_URL="https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.gz"

BINUTILS_TAR="$SCRIPT_DIR/src/binutils-$BINUTILS_VERSION.tar.gz"
GCC_TAR="$SCRIPT_DIR/src/gcc-$GCC_VERSION.tar.gz"

BINUTILS_DIR="$SCRIPT_DIR/src/binutils-$BINUTILS_VERSION"
GCC_DIR="$SCRIPT_DIR/src/gcc-$GCC_VERSION"

mkdir -p "$SCRIPT_DIR/src"

if [ ! -f "$BINUTILS_TAR" ]; then
        curl -o "$BINUTILS_TAR" $BINUTILS_URL
fi

if [ ! -d "$BINUTILS_DIR" ]; then
        tar xf "$BINUTILS_TAR" -C "$SCRIPT_DIR/src"
fi

if [ ! -f "$GCC_TAR" ]; then
        curl -o "$GCC_TAR" $GCC_URL
fi

if [ ! -d "$GCC_DIR" ]; then
        tar xf "$GCC_TAR" -C "$SCRIPT_DIR/src"
fi

mkdir -p "$SCRIPT_DIR/build/binutils" "$SCRIPT_DIR/build/gcc"
mkdir -p "$SCRIPT_DIR/install"

PREFIX="$SCRIPT_DIR/install"
TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"


if [ ! -x $SCRIPT_DIR/install/bin/i686-elf-ld ]; then
        cd "$SCRIPT_DIR/build/binutils"
        "$BINUTILS_DIR/configure" --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
        make -j$(nproc)
        make install

        cd "../.."

fi

if [ ! -x $SCRIPT_DIR/install/bin/i686-elf-gcc ]; then
        cd "$SCRIPT_DIR/build/gcc"
        "$GCC_DIR/configure" --target="$TARGET" --prefix="$PREFIX" --disable-nls --enable-languages=c --without-headers
        make all-gcc -j$(nproc)
        make all-target-libgcc -j$(nproc)
        make install-gcc
        make install-target-libgcc
        cd "../.."
fi

export PATH="$PREFIX/bin:$PATH"
