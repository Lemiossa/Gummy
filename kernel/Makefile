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
SRCDIR      := src
ARCHDIR     := $(SRCDIR)/arch/$(ARCH)
GLOBAL_LIB  ?= $(PROJ)/build/lib/global_lib.a
DEBUG       ?= 1

ASM      := nasm
CC       := $(ARCH)-elf-gcc
OBJCOPY  := $(ARCH)-elf-objcopy

LINKER_FILE := $(CURDIR)/$(ARCHDIR)/link.ld
CFLAGS   := -std=c11 -Wall -Wextra \
			-ffreestanding -fno-stack-protector -fno-builtin -nostdlib \
			-nostdinc -fno-omit-frame-pointer -fno-strict-aliasing \
			-fno-pic -fno-pie -fdata-sections -ffunction-sections \
			-mno-sse -mno-sse2 -mno-mmx -mno-3dnow -fmerge-all-constants
ifeq ($(DEBUG), 1)
	CFLAGS += -O0 -g
else
	CFLAGS += -O1
endif
CPPFLAGS := -I$(PROJ)/include -I$(CURDIR)/include \
			-I$(CURDIR)/include/arch/$(ARCH) \
			-DNAME=\"$(NAME)\" -DVERSION=\"$(VERSION)\"
LDFLAGS  := -T $(LINKER_FILE) -static -nostdlib -Wl,--gc-sections
LDLIBS   := -lgcc

# Colors
BLUE   := \033[1;34m
GREEN  := \033[1;32m
YELLOW := \033[1;33m
RESET  := \033[0m

define echo_cmd
	@printf "$(BLUE)%-10s$(RESET) %s\n" "$(1)" "$(2)"
endef

ifeq ($(ARCH),i686)
	ASMFLAGS := -f elf32
	LDFLAGS += -m32
	CFLAGS += -m32
else
	ifeq ($(ARCH),x86_64)
		ASMFLAGS := -f elf64
		LDFLAGS += -m64
		CFLAGS += -m64
	else
		$(error Unsupported architecture)
	endif
endif

SRC  := \
			$(ARCHDIR)/entry.asm \
			$(ARCHDIR)/gdt.asm \
			$(ARCHDIR)/idt.asm \
			$(ARCHDIR)/io.asm \
			$(ARCHDIR)/gdt.c \
			$(ARCHDIR)/idt.c \
			$(ARCHDIR)/exception.c \
			$(ARCHDIR)/e820.c \
			$(ARCHDIR)/pmm.c \
			$(ARCHDIR)/vmm.c \
			$(ARCHDIR)/tss.c \
			$(ARCHDIR)/tss.asm \
			$(SRCDIR)/kmain.c \
			$(SRCDIR)/serial.c \
			$(SRCDIR)/debug.c \
			$(SRCDIR)/heap.c \
			$(SRCDIR)/pit.c \
			$(SRCDIR)/sched.c \
			$(SRCDIR)/pic.c \
			$(SRCDIR)/vga.c \
			$(SRCDIR)/terminal.c

SRC_C      := $(filter %.c,$(SRC))
SRC_ASM    := $(filter %.asm,$(SRC))
OBJS_C     := $(patsubst %.c,$(OBJDIR)/%.c.o,$(SRC_C))
OBJS_ASM   := $(patsubst %.asm,$(OBJDIR)/%.asm.o,$(SRC_ASM))
OBJS       := $(OBJS_ASM) $(OBJS_C)
DEPS       := $(OBJS:.o=.d)
TARGET_ELF ?= $(BINDIR)/kernel.elf
TARGET_BIN ?= $(BINDIR)/kernel.bin

.PHONY: all clean

all: $(TARGET_BIN)

$(OBJDIR)/%.asm.o: %.asm
	@mkdir -p $(dir $@)
	$(call echo_cmd,AS,$<)
	@$(ASM) $(ASMFLAGS) -o $@ $<

$(OBJDIR)/%.c.o: %.c
	@mkdir -p $(dir $@)
	$(call echo_cmd,CC,$<)
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $< -MD

$(TARGET_ELF): $(OBJS) $(LINKER_FILE)
	@mkdir -p $(dir $@)
	$(call echo_cmd,LD,$@)
	@$(CC) $(LDFLAGS) -o $@ $(OBJS) $(GLOBAL_LIB) $(LDLIBS)

$(TARGET_BIN): $(TARGET_ELF)
	@mkdir -p $(dir $@)
	$(call echo_cmd,OBJCOPY,$@)
	@$(OBJCOPY) -O binary $< $@

clean:
	$(call echo_cmd,CLEAN,$(OBJDIR))
	@rm -rf $(OBJDIR)
	@rm -f $(TARGET_ELF)
	@rm -f $(TARGET_BIN)

-include $(DEPS)
