# Makefile
# Created by Matheus Leme Da Silva

PROJ     ?= $(CURDIR)/../..
NAME     ?= Gummy
VERSION  ?= dev
BUILDDIR := $(CURDIR)/build
BINDIR   := $(BUILDDIR)/bin
SOURCEDIR:= $(CURDIR)/src

DEFINES := -DNAME=\"$(NAME)\" -DVERSION=\"$(VERSION)\"

TARGET_BIN  ?= $(BINDIR)/stage2.bin
DEP         := $(BUILDDIR)/dep/stage2.d
SOURCE      := $(SOURCEDIR)/main.asm
INCLUDES    := $(wildcard $(CURDIR)/$(SOURCEDIR)/*.asm)


.PHONY: all clean check dirs

all: check $(TARGET_BIN)

check:
	command -v nasm >/dev/null 2>&1 || { echo "ERROR: nasm not found. Install nasm and try again."; exit 1; }

$(TARGET_BIN): $(INCLUDES) | dirs
	nasm -f bin -I$(SOURCEDIR) $(DEFINES) $(SOURCE) -o $(TARGET_BIN) -MD $(DEP)

dirs:
	mkdir -p $(dir $(TARGET_BIN)) $(dir $(DEP))

clean:
	rm -f $(TARGET_BIN) $(DEP)

-include $(DEP)
