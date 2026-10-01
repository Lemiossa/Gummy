# Makefile
# Created by Matheus Leme Da Silva

PROJ     ?= $(CURDIR)/..
BUILDDIR := $(CURDIR)/build
BINDIR   := $(BUILDDIR)/bin

STAGE1_BIN := $(BINDIR)/stage1.bin
STAGE2_BIN := $(BINDIR)/stage2.bin
TARGET_BIN := $(BINDIR)/bootloader.bin

export PROJ

# Colors
BLUE   := \033[1;34m
GREEN  := \033[1;32m
YELLOW := \033[1;33m
RESET  := \033[0m

define echo_cmd
	@printf "$(BLUE)%-10s$(RESET) %s\n" "$(1)" "$(2)"
endef

.PHONY: all clean stage1 stage2

all: $(TARGET_BIN)

$(TARGET_BIN): $(STAGE1_BIN) $(STAGE2_BIN)
	@mkdir -p $(dir $@)
	$(call echo_cmd,CAT,$@)
	@cat $(STAGE1_BIN) $(STAGE2_BIN) > $@

$(STAGE1_BIN): FORCE
	@$(MAKE) --no-print-directory -C stage1 TARGET_BIN=$@

FORCE:

$(STAGE2_BIN): FORCE
	@$(MAKE) --no-print-directory -C stage2 TARGET_BIN=$@

clean:
	@$(MAKE) --no-print-directory -C stage1 clean TARGET_BIN=$(STAGE1_BIN)
	@$(MAKE) --no-print-directory -C stage2 clean TARGET_BIN=$(STAGE2_BIN)
	$(call echo_cmd,CLEAN,$(TARGET_BIN))
	@rm -f $(TARGET_BIN)

stage1: $(STAGE1_BIN)

stage2: $(STAGE2_BIN)
