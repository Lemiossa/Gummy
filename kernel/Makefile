# Makefile
# Created by Matheus Leme Da Silva

PROJ     ?= $(CURDIR)/..
BUILDDIR := $(PROJ)/build
BINDIR   := $(BUILDDIR)/bin
OBJDIR   := $(BUILDDIR)/obj
DEPDIR   := $(BUILDDIR)/dep

ASM      := nasm
CC       := clang
LD       := ld.lld
OBJCOPY  := llvm-objcopy

CCFLAGS := -target i686-pn-none-elf -m32 -std=c99 -O2 -Wall -Wextra -ffreestanding -fno-stack-protector -fno-builtin -nostdlib
ASMFLAGS := -f elf32
LDFLAGS  := -T kernel.ld -nostdlib

SOURCES  := entry.asm kmain.c

OBJS     := $(addprefix $(OBJDIR)/, $(addsuffix .o, $(basename $(SOURCES))))
TARGET_ELF := $(BINDIR)/kernel.elf
TARGET_BIN := $(BINDIR)/kernel.bin

rel = $(subst $(PROJ)/,,$(1))

.PHONY: all clean

all: $(TARGET_BIN)

$(OBJDIR)/%.o: source/%.asm
	mkdir -p $(dir $@)
	$(ASM) $(ASMFLAGS) -o $@ $<

$(OBJDIR)/%.o: source/%.c
	mkdir -p $(dir $@)
	$(CC) $(CCFLAGS) -c -o $@ $<

$(TARGET_ELF): $(OBJS) kernel.ld
	mkdir -p $(dir $@)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

$(TARGET_BIN): $(TARGET_ELF)
	mkdir -p $(dir $@)
	$(OBJCOPY) -O binary $< $@

clean:
	rm -rf $(OBJDIR)
	rm -f $(TARGET_ELF)
	rm -f $(TARGET_BIN)
