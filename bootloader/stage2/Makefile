# Makefile
# Created by Matheus Leme Da Silva

PROJ     ?= $(CURDIR)/../..
NAME     ?= Gummy
VERSION  ?= dev
BUILDDIR := $(CURDIR)/build
BINDIR   := $(BUILDDIR)/bin
SRCDIR   := $(CURDIR)/src

DEFINES := -DNAME=\"$(NAME)\" -DVERSION=\"$(VERSION)\"

TARGET_BIN  ?= $(BINDIR)/stage2.bin
DEP         := $(BUILDDIR)/dep/stage2.d
SRC      := $(SRCDIR)/main.asm
INCLUDES    := $(wildcard $(CURDIR)/$(SRCDIR)/*.asm)

# Colors
BLUE   := \033[1;34m
GREEN  := \033[1;32m
YELLOW := \033[1;33m
RESET  := \033[0m

define echo_cmd
	@printf "$(BLUE)%-10s$(RESET) %s\n" "$(1)" "$(2)"
endef

.PHONY: all clean check dirs

all: check $(TARGET_BIN)

check:
	@command -v nasm >/dev/null 2>&1 || { echo "nasm not found"; exit 1; }

$(TARGET_BIN): $(INCLUDES) | dirs
	$(call echo_cmd,AS,$@)
	@nasm -f bin -I$(SRCDIR) $(DEFINES) $(SRC) -o $(TARGET_BIN) -MD $(DEP)

dirs:
	@mkdir -p $(dir $(TARGET_BIN)) $(dir $(DEP))

clean:
	$(call echo_cmd,CLEAN,$(TARGET_BIN))
	@rm -f $(TARGET_BIN) $(DEP)

-include $(DEP)
