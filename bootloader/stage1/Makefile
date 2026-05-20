# Makefile
# Created by Matheus Leme Da Silva

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
	command -v nasm >/dev/null 2>&1 || { echo "ERROR: nasm not found. Install nasm and try again."; exit 1; }

$(TARGET): $(INCLUDES) | dirs
	nasm -f bin -Isource $(SOURCE) -o $(TARGET) -MD $(DEP)

dirs:
	mkdir -p $(dir $(TARGET)) $(dir $(DEP))

clean:
	rm -f $(TARGET) $(DEP)

-include $(DEP)
