# Makefile
# Created by Matheus Leme Da Silva

NASM ?= nasm

.PHONY: all
all: stage1.bin

.PHONY: clean
clean:
	rm -f stage1.bin 

.PHONY: qemu
qemu: stage1.bin
	qemu-system-i386 -drive file=stage1.bin,format=raw,if=ide,media=disk \
		-machine pc

stage1.bin: stage1.asm
	$(NASM) -f bin $< -o $@


