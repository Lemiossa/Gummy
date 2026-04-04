# Makefile
# Created by Matheus Leme Da Silva

BUILDDIR := $(CURDIR)/build
BINDIR := $(BUILDDIR)/bin
DEPDIR := $(BUILDDIR)/dep

TARGET ?= $(BINDIR)/stage2.bin
NASM ?= nasm
ECHO ?= echo
RM ?= rm -f
MKDIR ?= mkdir -p

.PHONY: all
all: $(TARGET)

.PHONY: clean
clean:
	@$(ECHO) "  RM            $(TARGET) $(DEPDIR)/main.d"
	@$(RM) $(TARGET) $(DEPDIR)/main.d

$(TARGET): $(CURDIR)/source/main.asm
	@$(MKDIR) $(dir $@) $(DEPDIR)
	@$(ECHO) "  NASM          $@"
	@$(NASM) -f bin -I $(CURDIR)/source $< -o $@ -MD -MF $(DEPDIR)/main.d

-include $(DEPDIR)/main.d
