# Makefile
# Created by Matheus Leme Da Silva

BUILDDIR := $(CURDIR)/build
BINDIR := $(BUILDDIR)/bin

STAGE1_ASM := $(CURDIR)/stage1/main.asm
STAGE1_BIN := $(BINDIR)/stage1.bin

TARGET ?= $(BINDIR)/bootloader.bin
NASM ?= nasm

.PHONY: all
all: $(TARGET)

.PHONY: clean
clean:
	rm -f $(STAGE1_BIN)

$(TARGET): $(STAGE1_BIN)
	mkdir -p $(dir $@)
	cat $^ > $@

$(STAGE1_BIN): $(STAGE1_ASM)
	mkdir -p $(dir $@)
	$(NASM) -f bin $< -o $@


