# Makefile
# Created by Matheus Leme Da Silva

BUILDDIR := $(CURDIR)/build
BINDIR := $(BUILDDIR)/bin
OBJDIR := $(BUILDDIR)/obj
DEPDIR := $(BUILDDIR)/dep

TARGET ?= $(BINDIR)/stage2.bin
TARGET_ELF ?= $(basename $(TARGET)).elf

LINKER_FILE := $(CURDIR)/linker.ld

CC ?= gcc
NASM ?= nasm

CFLAGS := \
		  -std=c99 -Os \
		  -Wall -Wextra \
		  -fdata-sections -ffunction-sections \
		  -mno-mmx -mno-sse -mno-sse2 \
		  -fno-PIC -fno-pie

LDFLAGS := \
		   -static \
		   -nostdlib \
		   -Wl,-T$(LINKER_FILE) -Wl,-melf_i386

SOURCE := \
		 entry.asm 

SOURCE := $(addprefix $(CURDIR)/source/,$(SOURCE))
SOURCE_C := $(filter %.c,$(SOURCE))
SOURCE_ASM := $(filter %.asm,$(SOURCE))

OBJ := $(patsubst $(CURDIR)/source/%.c,$(OBJDIR)/c/%.o,$(SOURCE_C)) \
	   $(patsubst $(CURDIR)/source/%.asm,$(OBJDIR)/asm/%.o,$(SOURCE_ASM))

DEP := $(patsubst $(CURDIR)/source/%.c,$(DEPDIR)/c/%.d,$(SOURCE_C)) \
	   $(patsubst $(CURDIR)/source/%.asm,$(DEPDIR)/asm/%.d,$(SOURCE_ASM))

.PHONY: all
all: $(TARGET)

.PHONY: clean
clean:
	rm -f $(TARGET) $(OBJ) $(DEP)

$(TARGET_ELF): $(OBJ)
	mkdir -p $(dir $@)
	$(CC) $(LDFLAGS) -o $@ $^

$(TARGET): $(TARGET_ELF)
	mkdir -p $(dir $@)
	objcopy -O binary $< $@

$(OBJDIR)/c/%.o: $(CURDIR)/source/%.c
	mkdir -p $(dir $@) $(dir $(DEPDIR)/$*)
	$(CC) $(CFLAGS) -c $< -o $@ -MMD -MF $(DEPDIR)/$*.d

$(OBJDIR)/asm/%.o: $(CURDIR)/source/%.asm
	mkdir -p $(dir $@) $(dir $(DEPDIR)/$*)
	$(NASM) -f elf32 $< -o $@ -MD -MF $(DEPDIR)/$*.d

-include $(DEP)
