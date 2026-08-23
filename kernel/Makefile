# Makefile
# Created by Matheus Leme Da Silva

ARCH        ?= i686
NAME        ?= Gummy
VERSION     ?= dev
PROJ        ?= $(CURDIR)/..
BUILDDIR    := $(CURDIR)/build
BINDIR      := $(BUILDDIR)/bin
OBJDIR      := $(BUILDDIR)/obj
DEPDIR      := $(BUILDDIR)/dep
SOURCEDIR   := $(CURDIR)/src
ARCHDIR     := $(SOURCEDIR)/arch/$(ARCH)

ASM      := nasm
CC       := i686-elf-gcc
LD       := i686-elf-ld
OBJCOPY  := i686-elf-objcopy

LINKER_FILE := $(ARCHDIR)/link.ld
CFLAGS   := -m32 -std=c99 -O2 -g -Wall -Wextra \
			-ffreestanding -fno-stack-protector -fno-builtin -nostdlib \
			-nostdinc -fno-omit-frame-pointer -fno-strict-aliasing \
			-fno-pic -fno-pie -fdata-sections -ffunction-sections
CPPFLAGS := -I$(PROJ)/include -I$(CURDIR)/include \
			-I$(CURDIR)/include/arch/$(ARCH) \
			-DNAME=\"$(NAME)\" -DVERSION=\"$(VERSION)\"
ASMFLAGS := -f elf32
LDFLAGS  := -T $(LINKER_FILE) -static -nostdlib --gc-sections
LDLIBS   :=

SOURCE  := \
			$(ARCHDIR)/entry.asm \
			$(ARCHDIR)/gdt.asm \
			$(ARCHDIR)/idt.asm \
			$(ARCHDIR)/io.asm \
			$(SOURCEDIR)/kmain.c \
			$(SOURCEDIR)/pic.c \
			$(ARCHDIR)/gdt.c \
			$(ARCHDIR)/idt.c \
			$(ARCHDIR)/e820.c \
			$(ARCHDIR)/pmm.c \
			$(SOURCEDIR)/vga.c \
			$(SOURCEDIR)/terminal.c

SOURCE_C   := $(filter %.c,$(SOURCE))
SOURCE_ASM := $(filter %.asm,$(SOURCE))
OBJS_C     := $(patsubst %.c,$(OBJDIR)/%.c.o,$(SOURCE_C))
OBJS_ASM   := $(patsubst %.asm,$(OBJDIR)/%.asm.o,$(SOURCE_ASM))
OBJS       := $(OBJS_ASM) $(OBJS_C)
TARGET_ELF := $(BINDIR)/kernel.elf
TARGET_BIN ?= $(BINDIR)/kernel.bin

.PHONY: all clean

all: $(TARGET_BIN)

$(OBJDIR)/%.asm.o: %.asm
	mkdir -p $(dir $@)
	$(ASM) $(ASMFLAGS) -o $@ $<

$(OBJDIR)/%.c.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $< 

$(TARGET_ELF): $(OBJS) $(LINKER_FILE)
	mkdir -p $(dir $@)
	$(LD) $(LDFLAGS) -o $@ $(OBJS) $(LDLIBS)

$(TARGET_BIN): $(TARGET_ELF)
	mkdir -p $(dir $@)
	$(OBJCOPY) -O binary $< $@

clean:
	rm -rf $(OBJDIR)
	rm -f $(TARGET_ELF)
	rm -f $(TARGET_BIN)
