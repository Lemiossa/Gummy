# Gummy

Um sistema operacional hobby simples para a arquitetura x86.

## Requisitos

- NASM
- QEMU (opcional, para testes)
- dosfstools
- mtools
- GCC 15.2.0 (compilador cruzado) para a arquitetura especificada (com libgcc e binutils 2.45)
- GDB 17.2 (opcional, para depuração)

## Compilação

```bash
make
```

Isso produz `build/images/Gummy-<version>.img`, em que a versão vem da variável
`VERSION` no `Makefile` da raiz. Tanto o kernel quanto o bootloader recebem as
macros `NAME` e `VERSION` em tempo de compilação.

## Execução

```bash
make qemu
```

Para o QEMU sem interface gráfica:

```bash
make qemu-ng
```

## Limpeza

```bash
make clean
```

## Suporte a editores

O `compile_commands.json` contém as flags exatas usadas para compilar cada
unidade de tradução do kernel, da biblioteca e dos dois estágios do bootloader.
Ele é mantido manualmente na raiz do repositório, para que editores como o
`clangd` resolvam os includes, as macros `NAME`/`VERSION` e a arquitetura
alvo sem nenhuma ferramenta extra.

Os caminhos são absolutos, então o arquivo só corresponde à máquina em que foi
escrito (por isso ele está no git-ignore). Quando o projeto é movido, ou quando
um novo arquivo-fonte é adicionado a uma das listas `SRC` dos Makefiles, a
entrada também precisa ser atualizada manualmente.

## Compilador cruzado

Dependências para compilar o compilador cruzado:
- make
- bison
- flex
- gmp
- mpc
- mpfr
- texinfo
- isl (opcional)

Para mais informações, consulte o [Guia de Instalação do GCC](https://gcc.gnu.org/install/).

Você pode compilar o compilador cruzado usando os seguintes comandos:

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

### gdb
```bash
cd ~/cross
wget https://ftp.gnu.org/gnu/gdb/gdb-17.2.tar.gz
tar -xvf gdb-17.2.tar.gz
cd gdb-17.2
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

## Licença

MIT
