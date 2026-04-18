# Makefile
# Created by Matheus Leme Da Silva
MAKEFLAGS += -s --no-print-directory

BUILDDIR := ../../build
BINDIR  := $(BUILDDIR)/bin

TARGET ?= $(BINDIR)/stage2.bin
ASM    ?= nasm
ECHO   ?= echo
RM     ?= rm -f
MKDIR  ?= mkdir -p

DEP := $(BUILDDIR)/dep/stage2.d

.PHONY: all
all: source/main.asm
	$(MKDIR) $(dir $(TARGET)) $(dir $(DEP))
	$(ECHO) "  ASM         $(TARGET)"
	$(ASM) -f bin -Isource source/main.asm -o $(TARGET) -MD $(DEP)

.PHONY: clean
clean:
	$(ECHO) "  RM          $(TARGET) $(DEP)"
	$(RM)   $(TARGET) $(DEP)

-include $(DEP)
