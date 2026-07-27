# Makefile
# Created by Matheus Leme Da Silva

PROJ     ?= $(CURDIR)/..
BUILDDIR := $(CURDIR)/build
BINDIR   := $(BUILDDIR)/bin

STAGE1_BIN := $(BINDIR)/stage1.bin
STAGE2_BIN := $(BINDIR)/stage2.bin
TARGET_BIN := $(BINDIR)/bootloader.bin

export PROJ

.PHONY: all clean stage1 stage2

all: $(TARGET_BIN)

$(TARGET_BIN): $(STAGE1_BIN) $(STAGE2_BIN)
	mkdir -p $(dir $@)
	cat $(STAGE1_BIN) $(STAGE2_BIN) > $@

$(STAGE1_BIN): FORCE
	$(MAKE) -C stage1 TARGET_BIN=$@

FORCE:

$(STAGE2_BIN): FORCE
	$(MAKE) -C stage2 TARGET_BIN=$@

clean:
	$(MAKE) -C stage1 clean TARGET_BIN=$(STAGE1_BIN)
	$(MAKE) -C stage2 clean TARGET_BIN=$(STAGE2_BIN)
	rm -f $(TARGET_BIN)

stage1: $(STAGE1_BIN)

stage2: $(STAGE2_BIN)
