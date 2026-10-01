# Makefile
# Created by Matheus Leme Da Silva

ARCH     := i686
VERSION  := 0.13.0
NAME     := Gummy

PROJ     := $(CURDIR)
BUILDDIR := $(PROJ)/build
BINDIR   := $(BUILDDIR)/bin
LIBDIR   := $(BUILDDIR)/lib
IMGDIR   := $(BUILDDIR)/images
IMGROOT  := $(BUILDDIR)/imgroot
DEBUG    ?= 1

GLOBAL_LIB := $(LIBDIR)/global_lib.a
ifeq ($(DEBUG), 1)
IMAGE      := $(IMGDIR)/$(NAME)_$(ARCH)-$(VERSION)_debug.img
BOOTLOADER := $(BINDIR)/bootloader_debug.bin
KERNEL     := $(BINDIR)/kernel_debug.bin
else
IMAGE      := $(IMGDIR)/$(NAME)_$(ARCH)-$(VERSION).img
BOOTLOADER := $(BINDIR)/bootloader.bin
KERNEL     := $(BINDIR)/kernel.bin
endif
PATH       := /sbin:/usr/sbin:$(PATH)

# Colors
BLUE   := \033[1;34m
GREEN  := \033[1;32m
YELLOW := \033[1;33m
RESET  := \033[0m

define check_tool
	@command -v $(1) >/dev/null 2>&1 || { echo "$(1) not found"; exit 1; }
endef

define echo_cmd
	@printf "$(BLUE)%-10s$(RESET) %s\n" "$(1)" "$(2)"
endef

QEMUFLAGS := \
	-drive file=$(IMAGE),format=raw,if=ide,media=disk \
	-machine pc -vga std -display gtk

export PROJ
export NAME
export VERSION
export ARCH
export DEBUG

.PHONY: all bootloader clean qemu qemu-ng

all: $(IMAGE)

$(BOOTLOADER): FORCE
	@$(MAKE) --no-print-directory -C bootloader TARGET_BIN=$(BOOTLOADER)

FORCE:

bootloader: $(BOOTLOADER)

$(KERNEL): FORCE
	@$(MAKE) --no-print-directory -C kernel TARGET_BIN=$(KERNEL) TARGET_ELF=$(KERNEL).elf GLOBAL_LIB=$(GLOBAL_LIB)

kernel: $(KERNEL)

$(GLOBAL_LIB): FORCE
	@$(MAKE) --no-print-directory -C lib TARGET=$(GLOBAL_LIB)

global_lib:: $(GLOBAL_LIB)

$(IMAGE): $(BOOTLOADER) $(GLOBAL_LIB) $(KERNEL)
	$(call check_tool,mkfs.fat)
	$(call check_tool,mcopy)
	$(call check_tool,dd)
	@mkdir -p $(dir $@)
	@mkdir -p $(IMGROOT)
	$(call echo_cmd,CP,$(KERNEL) -> $(IMGROOT)/kernel.sys)
	@cp $(KERNEL) $(IMGROOT)/kernel.sys
	$(call echo_cmd,DD,$(IMAGE))
	@dd if=/dev/zero of=$(IMAGE) bs=1K count=1440 status=none
	$(call echo_cmd,MKFS,$(IMAGE))
	@mkfs.fat --mbr=y -F 12 -n GUMMY -R 64 $(IMAGE)
	$(call echo_cmd,MCOPY,$(IMGROOT)/* -> $(IMAGE))
	@mcopy -i $(IMAGE) -s $(IMGROOT)/* ::
	$(call echo_cmd,DD,bootloader -> $(IMAGE))
	@dd if=$(BOOTLOADER) of=$(IMAGE) bs=1 count=3 conv=notrunc status=none
	@dd if=$(BOOTLOADER) of=$(IMAGE) bs=1 skip=62 seek=62 count=386 conv=notrunc status=none
	@dd if=$(BOOTLOADER) of=$(IMAGE) bs=1 skip=512 seek=512 conv=notrunc status=none

clean:
	@$(MAKE) --no-print-directory -C bootloader clean TARGET_BIN=$(BOOTLOADER)
	@$(MAKE) --no-print-directory -C kernel     clean TARGET_BIN=$(KERNEL)
	$(call echo_cmd,CLEAN,$(BUILDDIR))
	@rm -rf $(BUILDDIR)

qemu: $(IMAGE)
	$(call check_tool,qemu-system-i386)
	@qemu-system-i386 $(QEMUFLAGS) \
	-chardev stdio,id=serial0,mux=on \
	-serial chardev:serial0 \
	| tee qemu.log

qemu-ng: $(IMAGE)
	$(call check_tool,qemu-system-i386)
	@qemu-system-i386 $(QEMUFLAGS) -nographic

qemu-gdb: $(IMAGE)
	$(call check_tool,qemu-system-i386)
	@qemu-system-i386 $(QEMUFLAGS) -s -S &
	$(call check_tool,$(ARCH)-elf-gdb)
	@$(ARCH)-elf-gdb -ex "target remote localhost:1234" -ex "symbol-file $(KERNEL).elf"
