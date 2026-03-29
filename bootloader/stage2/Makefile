# Makefile
# Created by Matheus Leme Da Silva

BUILDDIR := $(CURDIR)/build
BINDIR := $(BUILDDIR)/bin
DEPDIR := $(BUILDDIR)/dep

TARGET ?= $(BINDIR)/stage2.bin
NASM ?= nasm

.PHONY: all
all: $(TARGET)

.PHONY: clean
clean:
	rm -f $(TARGET) 

$(TARGET): $(CURDIR)/source/main.asm
	mkdir -p $(dir $@) $(DEPDIR)
	$(NASM) -f bin $< -o $@ -MD -MF $(DEPDIR)/main.d

-include $(DEPDIR)/main.d
