# Makefile
# Criado por Matheus Leme Da Silva

MAKEFLAGS += -s --no-print-directory

PROJ     ?= $(CURDIR)/..
BUILDDIR := $(PROJ)/build
BINDIR   := $(BUILDDIR)/bin
OBJDIR   := $(BUILDDIR)/obj
DEPDIR   := $(BUILDDIR)/dep

CXX      := i686-elf-g++
CXXFLAGS := -std=c++11 -O2 -Wall -Wextra -ffreestanding -fno-rtti -fno-exceptions -fno-stack-protector -fno-builtin -nostdlib

ASM      := nasm
ASMFLAGS := -f elf32

LD       := i686-elf-ld
LDFLAGS  := -T kernel.ld -nostdlib

OBJCOPY  := i686-elf-objcopy

SOURCES  := entry.asm kmain.cpp

OBJS     := $(addprefix $(OBJDIR)/, $(addsuffix .o, $(basename $(SOURCES))))
TARGET_ELF := $(BINDIR)/kernel.elf
TARGET_BIN := $(BINDIR)/kernel.bin

rel = $(subst $(PROJ)/,,$(1))

.PHONY: all clean

all: $(TARGET_BIN)

$(OBJDIR)/%.o: source/%.asm
	@mkdir -p $(dir $@)
	@echo "  NASM      $(call rel,$@)"
	@$(ASM) $(ASMFLAGS) -o $@ $<

$(OBJDIR)/%.o: source/%.cpp
	@mkdir -p $(dir $@)
	@echo "  CXX       $(call rel,$@)"
	@$(CXX) $(CXXFLAGS) -c -o $@ $<

$(TARGET_ELF): $(OBJS) kernel.ld
	@mkdir -p $(dir $@)
	@echo "  LD        $(call rel,$@)"
	@$(LD) $(LDFLAGS) -o $@ $(OBJS)

$(TARGET_BIN): $(TARGET_ELF)
	@mkdir -p $(dir $@)
	@echo "  OBJCOPY   $(call rel,$@)"
	@$(OBJCOPY) -O binary $< $@

clean:
	@echo "  RM        $(call rel,$(OBJDIR))"
	@rm -rf $(OBJDIR)
	@echo "  RM        $(call rel,$(TARGET_ELF))"
	@rm -f $(TARGET_ELF)
	@echo "  RM        $(call rel,$(TARGET_BIN))"
	@rm -f $(TARGET_BIN)
