# Makefile
# Created by Matheus Leme Da Silva
PROJ     ?= $(CURDIR)/..
BUILDDIR := $(PROJ)/build
BINDIR   := $(BUILDDIR)/bin

STAGE1_BIN := $(BINDIR)/stage1.bin
STAGE2_BIN := $(BINDIR)/stage2.bin
TARGET     := $(BINDIR)/bootloader.bin

rel = $(subst $(PROJ)/,,$(1))

export PROJ

.PHONY: all clean stage1 stage2

all: $(TARGET)

$(TARGET): $(STAGE1_BIN) $(STAGE2_BIN)
	mkdir -p $(dir $@)
	cat $(STAGE1_BIN) $(STAGE2_BIN) > $@

$(STAGE1_BIN): FORCE
	$(MAKE) -C stage1 TARGET=$@

FORCE:

$(STAGE2_BIN): FORCE
	$(MAKE) -C stage2 TARGET=$@

clean:
	$(MAKE) -C stage1 clean
	$(MAKE) -C stage2 clean
	rm -f $(TARGET)

stage1: $(STAGE1_BIN)

stage2: $(STAGE2_BIN)
