# Makefile
# Created by Matheus Leme Da Silva
MAKEFLAGS += -s --no-print-directory

BUILDDIR := build
BINDIR  := $(BUILDDIR)/bin
IMGDIR := $(BUILDDIR)/images

IMAGE      := $(IMGDIR)/Bitix.img
BOOTLOADER := $(BINDIR)/bootloader.bin
IMGROOT    := $(BUILDDIR)/imgroot

PATH := $(PATH):/sbin:/usr/sbin

ECHO     ?= echo
RM       ?= rm -rf
MKDIR    ?= mkdir -p
CAT      ?= cat
DD       ?= dd
MKFS_FAT ?= mkfs.fat
MCOPY    ?= mcopy
QEMU     ?= qemu-system-i386

QEMUFLAGS := \
	-drive file=$(IMAGE),format=raw,if=ide,media=disk \
	-machine pc -vga std -display gtk

export ECHO RM MKDIR CAT DD MKFS_FAT MCOPY

.PHONY: all
all: $(IMAGE)

.PHONY: clean
clean:
	$(MAKE) -C bootloader clean
	$(ECHO) "  RM         $(IMAGE)"
	$(RM)   $(IMAGE)

.PHONY: qemu
qemu: $(IMAGE)
	$(ECHO) "  QEMU       $(IMAGE)"
	$(QEMU) $(QEMUFLAGS) -serial stdio

.PHONY: qemu-ng
qemu-ng: $(IMAGE)
	$(ECHO) "  QEMU-NG    $(IMAGE)"
	$(QEMU) $(QEMUFLAGS) -nographic

.PHONY: bootloader
bootloader:
	$(ECHO) "  BOOTLOADER"
	$(MAKE) -C bootloader

$(IMAGE): bootloader
	$(MKDIR) $(IMGDIR) $(IMGROOT)/subdir
	$(ECHO) "Hello world" > $(IMGROOT)/subdir/text.txt
	$(ECHO) "  GENIMG     $(IMAGE)"
	$(DD)   if=/dev/zero of=$(IMAGE) bs=1K count=1440 status=none
	$(ECHO) "  MKFS.FAT   $(IMAGE)"
	$(MKFS_FAT) --mbr=y -F 12 -n BITIX -R 64 $(IMAGE)
	$(ECHO) "  MCOPY      $(IMAGE)"
	$(MCOPY) -i $(IMAGE) -s $(IMGROOT)/* ::
	$(ECHO) "  INSTALL    BOOTLOADER"
	$(DD)   if=$(BOOTLOADER) of=$(IMAGE) bs=1 count=3 conv=notrunc status=none
	$(DD)   if=$(BOOTLOADER) of=$(IMAGE) bs=1 skip=62 seek=62 count=386 conv=notrunc status=none
	$(DD)   if=$(BOOTLOADER) of=$(IMAGE) bs=1 skip=512 seek=512 conv=notrunc status=none
