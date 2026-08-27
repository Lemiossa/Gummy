# Makefile
# Created by Matheus Leme Da Silva

PROJ     ?= $(CURDIR)/../..
NAME     ?= Gummy
VERSION  ?= dev
BUILDDIR := $(CURDIR)/build
BINDIR   := $(BUILDDIR)/bin
SRCDIR:= $(CURDIR)/src

DEFINES := -DNAME=\"$(NAME)\" -DVERSION=\"$(VERSION)\"

TARGET_BIN  ?= $(BINDIR)/stage1.bin
DEP         := $(BUILDDIR)/dep/stage1.d
SRC      := $(SRCDIR)/main.asm
INCLUDES    := $(wildcard $(CURDIR)/$(SRCDIR)/*.asm)

.PHONY: all clean check dirs

all: check $(TARGET_BIN)

check:
	command -v nasm >/dev/null 2>&1 || { echo "ERROR: nasm not found. Install nasm and try again."; exit 1; }

$(TARGET_BIN): $(INCLUDES) | dirs
	nasm -f bin -I$(SRCDIR) $(DEFINES) $(SRC) -o $(TARGET_BIN) -MD $(DEP)

dirs:
	mkdir -p $(dir $(TARGET_BIN)) $(dir $(DEP))

clean:
	rm -f $(TARGET_BIN) $(DEP)

-include $(DEP)
