# Makefile
# Created by Matheus Leme Da Silva

PROJ     ?= $(CURDIR)/../..
BUILDDIR := $(CURDIR)/build
BINDIR   := $(BUILDDIR)/bin

TARGET_BIN  ?= $(BINDIR)/stage2.bin
DEP         := $(BUILDDIR)/dep/stage2.d
SOURCE      := source/main.asm
INCLUDES    := $(wildcard $(CURDIR)/source/*.asm)


.PHONY: all clean check dirs

all: check $(TARGET_BIN)

check:
	command -v nasm >/dev/null 2>&1 || { echo "ERROR: nasm not found. Install nasm and try again."; exit 1; }

$(TARGET_BIN): $(INCLUDES) | dirs
	nasm -f bin -Isource $(SOURCE) -o $(TARGET_BIN) -MD $(DEP)

dirs:
	mkdir -p $(dir $(TARGET_BIN)) $(dir $(DEP))

clean:
	rm -f $(TARGET_BIN) $(DEP)

-include $(DEP)
