# Makefile
# Criado por Matheus Leme Da Silva

MAKEFLAGS += -s --no-print-directory

PROJ     ?= $(CURDIR)/../..
BUILDDIR := $(PROJ)/build
BINDIR   := $(BUILDDIR)/bin

TARGET  ?= $(BINDIR)/stage1.bin
DEP      := $(BUILDDIR)/dep/stage1.d
SOURCE   := source/main.asm
INCLUDES := $(wildcard $(CURDIR)/source/*.asm)

rel = $(subst $(PROJ)/,,$(1))

.PHONY: all clean check dirs

all: check $(TARGET)

check:
	@command -v nasm >/dev/null 2>&1 || { echo "ERROR: nasm not found. Install with: sudo apt install nasm"; exit 1; }

$(TARGET): $(INCLUDES) | dirs
	@echo "  ASM       $(call rel,$(TARGET))"
	@nasm -f bin -Isource $(SOURCE) -o $(TARGET) -MD $(DEP)

dirs:
	@mkdir -p $(dir $(TARGET)) $(dir $(DEP))

clean:
	@echo "  RM        $(call rel,$(TARGET))"
	@rm -f $(TARGET) $(DEP)

-include $(DEP)
