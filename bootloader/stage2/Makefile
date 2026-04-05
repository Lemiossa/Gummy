# Makefile
# Created by Matheus Leme Da Silva

BUILDDIR := $(CURDIR)/build
BINDIR := $(BUILDDIR)/bin

TARGET ?= $(BINDIR)/stage2.bin
ASM ?= nasm
ECHO ?= echo
RM ?= rm -f
MKDIR ?= mkdir -p

DEP := $(BUILDDIR)/dep

.PHONY: all
all: $(CURDIR)/source/main.asm
	@$(MKDIR) $(dir $(TARGET)) $(dir $(DEP))
	@$(ECHO)  "  ASM           $(TARGET)"
	@$(ASM)   -f bin -I $(CURDIR)/source $< -o $(TARGET) -MD -MF $(DEP)

.PHONY: clean
clean:
	@$(ECHO) "  RM            $(TARGET) $(DEP)"
	@$(RM) $(TARGET)  $(DEP)

-include $(DEP)
