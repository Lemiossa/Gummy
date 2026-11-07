# Makefile
# Criado por Matheus Leme da Silva

ARCH        ?= i686
NAME        ?= Gummy
VERSION     ?= dev
PROJ        ?= $(CURDIR)/..
BUILDDIR    := $(CURDIR)/build
INITRDMAKER := $(CURDIR)/make-initrd
TARGET      ?= $(BUILDDIR)/initrd

INITRD_ROOT := $(BUILDDIR)/root
INIT        := $(INITRD_ROOT)/init.sys

# Cores
BLUE   := \033[1;34m
GREEN  := \033[1;32m
YELLOW := \033[1;33m
RESET  := \033[0m

define echo_cmd
	@printf "$(BLUE)%-10s$(RESET) %s\n" "$(1)" "$(2)"
endef

.PHONY: all clean FORCE
all: $(TARGET)

$(TARGET): $(INIT) FORCE
	@mkdir -p $(dir $@)
	@chmod +x $(INITRDMAKER)
	$(call echo_cmd,MK-INITRD,$@)
	@$(INITRDMAKER) $(INITRD_ROOT) $@

clean:
	$(call echo_cmd,CLEAN,$(TARGET) $(INITRD_ROOT))
	@rm -rf $(TARGET) $(INITRD_ROOT)

$(INITRD_ROOT): FORCE
	@mkdir -p $@

$(INIT): $(INITRD_ROOT) 
	@$(MAKE) -C $(CURDIR)/init TARGET_BIN=$@

init: $(INIT)

FORCE:
