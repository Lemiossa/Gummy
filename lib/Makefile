# Makefile
# Created by Matheus Leme Da Silva

ARCH        ?= i686
NAME        ?= Gummy
VERSION     ?= dev
PROJ        ?= $(CURDIR)/..
BUILDDIR    := $(CURDIR)/build
LIBDIR      := $(BUILDDIR)/lib
OBJDIR      := $(BUILDDIR)/obj
DEPDIR      := $(BUILDDIR)/dep
SRCDIR      := src
ARCHDIR     := $(SRCDIR)/arch/$(ARCH)
DEBUG       ?= 1

ASM      := nasm
CC       := $(ARCH)-elf-gcc
AR       := $(ARCH)-elf-ar
OBJCOPY  := $(ARCH)-elf-objcopy

LINKER_FILE := $(CURDIR)/$(ARCHDIR)/link.ld
CFLAGS   := -std=c11 -Wall -Wextra \
			-ffreestanding -fno-stack-protector -fno-builtin -nostdlib \
			-nostdinc -fno-omit-frame-pointer -fno-strict-aliasing \
			-fno-pic -fno-pie -fdata-sections -ffunction-sections \
			-mno-sse -mno-sse2 -mno-mmx -mno-3dnow -fmerge-all-constants
ifeq ($(DEBUG),1)
	CFLAGS += -O0 -g
else
	CFLAGS += -O1
endif
CPPFLAGS := -I$(PROJ)/include \
			-DNAME=\"$(NAME)\" -DVERSION=\"$(VERSION)\"
LDFLAGS  := -T $(LINKER_FILE) -static -nostdlib -Wl,--gc-sections
LDLIBS   := -lgcc
ARFLAGS  := rcs

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

SRC := \
		$(SRCDIR)/string.c \
		$(SRCDIR)/queue.c

SRC_C      := $(filter %.c,$(SRC))
SRC_ASM    := $(filter %.asm,$(SRC))
OBJS_C     := $(patsubst %.c,$(OBJDIR)/%.c.o,$(SRC_C))
OBJS_ASM   := $(patsubst %.asm,$(OBJDIR)/%.asm.o,$(SRC_ASM))
OBJS       := $(OBJS_ASM) $(OBJS_C)
DEPS       := $(OBJS:.o=.d)
TARGET     ?= $(LIBDIR)/global_lib.a

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJS)
	@mkdir -p $(dir $@)
	$(call echo_cmd,AR,$@)
	@$(AR) $(ARFLAGS) $@ $^

$(OBJDIR)/%.asm.o: %.asm
	@mkdir -p $(dir $@)
	$(call echo_cmd,AS,$<)
	@$(ASM) $(ASMFLAGS) -o $@ $<

$(OBJDIR)/%.c.o: %.c
	@mkdir -p $(dir $@)
	$(call echo_cmd,CC,$<)
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $< -MD

clean:
	$(call echo_cmd,CLEAN,$(OBJDIR))
	@rm -rf $(OBJDIR)
	@rm -f $(TARGET)

-include $(DEPS)

