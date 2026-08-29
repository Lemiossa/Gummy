# Makefile
# Created by Matheus Leme Da Silva

NAME     := Gummy
VERSION  := 0.6.2
ARCH     := i686

PROJ     := $(CURDIR)
BUILDDIR := $(PROJ)/build
BINDIR   := $(BUILDDIR)/bin
IMGDIR   := $(BUILDDIR)/images
IMGROOT  := $(BUILDDIR)/imgroot

IMAGE      := $(IMGDIR)/$(NAME)-$(VERSION).img
BOOTLOADER := $(BINDIR)/bootloader.bin
KERNEL     := $(BINDIR)/kernel.bin
PATH       := /sbin:/usr/sbin:$(PATH)

define check_tool
	command -v $(1) >/dev/null 2>&1 || { echo "ERROR: $(1) not found. Install it and try again."; exit 1; }
endef

QEMUFLAGS := \
	-drive file=$(IMAGE),format=raw,if=ide,media=disk \
	-machine pc -vga std -display gtk

export PROJ
export NAME
export VERSION
export ARCH

.PHONY: all bootloader clean qemu qemu-ng

all: $(IMAGE)

$(BOOTLOADER): FORCE
	$(MAKE) -C bootloader TARGET_BIN=$(BOOTLOADER)

FORCE:

bootloader: $(BOOTLOADER)

$(KERNEL): FORCE
	$(MAKE) -C kernel TARGET_BIN=$(KERNEL)

kernel: $(KERNEL)

$(IMAGE): $(BOOTLOADER) $(KERNEL)
	$(call check_tool,mkfs.fat)
	$(call check_tool,mcopy)
	$(call check_tool,dd)
	mkdir -p $(dir $@)
	mkdir -p $(IMGROOT)
	cp $(KERNEL) $(IMGROOT)/kernel.sys
	dd if=/dev/zero of=$(IMAGE) bs=1K count=1440 status=none
	mkfs.fat --mbr=y -F 12 -n GUMMY -R 64 $(IMAGE)
	mcopy -i $(IMAGE) -s $(IMGROOT)/* ::
	dd if=$(BOOTLOADER) of=$(IMAGE) bs=1 count=3 conv=notrunc status=none
	dd if=$(BOOTLOADER) of=$(IMAGE) bs=1 skip=62 seek=62 count=386 conv=notrunc status=none
	dd if=$(BOOTLOADER) of=$(IMAGE) bs=1 skip=512 seek=512 conv=notrunc status=none

clean:
	$(MAKE) -C bootloader clean TARGET_BIN=$(BOOTLOADER)
	$(MAKE) -C kernel     clean TARGET_BIN=$(KERNEL)
	rm -rf $(BUILDDIR)

qemu: $(IMAGE)
	$(call check_tool,qemu-system-i386)
	qemu-system-i386 $(QEMUFLAGS) -serial stdio

qemu-ng: $(IMAGE)
	$(call check_tool,qemu-system-i386)
	qemu-system-i386 $(QEMUFLAGS) -nographic
