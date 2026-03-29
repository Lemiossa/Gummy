# Makefile
# Created by Matheus Leme Da Silva

BUILDDIR := $(CURDIR)/build
BINDIR := $(BUILDDIR)/bin

STAGE1_BIN := $(BINDIR)/stage1.bin
STAGE2_BIN := $(BINDIR)/stage2.bin

TARGET ?= $(BINDIR)/bootloader.bin
NASM ?= nasm

.PHONY: all
all: stage1 stage2 $(TARGET)

.PHONY: clean
clean:
	$(MAKE) -C stage1 clean TARGET=$(STAGE1_BIN)
	$(MAKE) -C stage2 clean TARGET=$(STAGE2_BIN)
	rm -f $(TARGET)

.PHONY: stage1
stage1:
	$(MAKE) -C stage1 TARGET=$(STAGE1_BIN)

.PHONY: stage2
stage2:
	$(MAKE) -C stage2 TARGET=$(STAGE2_BIN)

$(TARGET): $(STAGE1_BIN) $(STAGE2_BIN)
	mkdir -p $(dir $@)
	cat $^ > $@

