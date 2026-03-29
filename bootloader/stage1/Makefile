# Makefile
# Created by Matheus Leme Da Silva

BUILDDIR := $(CURDIR)/build
BINDIR := $(BUILDDIR)/bin

TARGET ?= $(BINDIR)/stage1.bin
NASM ?= nasm

.PHONY: all
all: $(TARGET)

.PHONY: clean
clean:
	rm -f $(TARGET)

$(TARGET): $(CURDIR)/source/main.asm
	mkdir -p $(dir $@)
	$(NASM) -f bin $< -o $@

