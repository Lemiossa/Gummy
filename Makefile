# Makefile
# Created by Matheus Leme Da Silva
MAKEFLAGS += -s --no-print-directory

BUILDDIR := $(CURDIR)/build
BINDIR := $(BUILDDIR)/bin
IMAGESDIR := $(BUILDDIR)/images

IMAGE := $(IMAGESDIR)/Bitix.img
BOOTLOADER := $(BINDIR)/bootloader.bin

IMAGEROOT := $(BUILDDIR)/imgroot

# For debian
PATH := $(PATH):/sbin:/usr/sbin

ECHO ?= echo
RM ?= rm -f
MKDIR ?= mkdir -p
CAT ?= cat
DD ?= dd
MKFS_FAT ?= mkfs.fat
MCOPY ?= mcopy
QEMU := qemu-system-i386

export ECHO
export RM
export MKDIR
export CAT
export DD
export MKFS_FAT
export MCOPY

QEMUFLAGS := \
			 -drive file=$(IMAGE),format=raw,if=ide,media=disk \
			 -audiodev alsa,id=audio0 \
			 -machine pc,pcspk-audiodev=audio0 

.PHONY: all
all: $(IMAGE)

.PHONY: clean
clean:
	@$(MAKE) -C bootloader clean TARGET=$(BOOTLOADER)

.PHONY: qemu
qemu: $(IMAGE)
	@$(ECHO) "  QEMU          $(IMAGE)"
	@$(QEMU) $(QEMUFLAGS) -serial stdio

.PHONY: qemu-ng
qemu-ng: $(IMAGE)
	@$(ECHO) "  QEMU-NG       $(IMAGE)"
	@$(QEMU) $(QEMUFLAGS) -nographic

.PHONY: bootloader
bootloader:
	@$(ECHO) "  BOOTLOADER"
	@$(MAKE) -C bootloader TARGET=$(BOOTLOADER)

$(IMAGE): bootloader
	@$(MKDIR)    $(dir $@) $(IMAGEROOT)/subdir
	@$(ECHO)     "Hello world" > $(IMAGEROOT)/subdir/text.txt
	@$(ECHO)     "  GENIMG        $(IMAGE)"
	@$(DD)       if=/dev/zero of=$(IMAGE) bs=1K count=1440 status=none > /dev/null
	@$(ECHO)     "  MKFS.FAT      $(IMAGE)"
	@$(MKFS_FAT) --mbr=y -F 12 -n "BITIX" -R 64 $(IMAGE) > /dev/null
	@$(ECHO)     "  MCOPY         $(IMAGE)"
	@$(MCOPY)    -i $(IMAGE) -s $(IMAGEROOT)/* "::/"
	@$(ECHO)     "  INSTALL BOOTLOADER"
	@$(DD)       if=$(BOOTLOADER) of=$(IMAGE) bs=1 count=3 conv=notrunc status=none > /dev/null
	@$(DD)       if=$(BOOTLOADER) of=$(IMAGE) bs=1 skip=62 seek=62 count=386 conv=notrunc status=none > /dev/null
	@$(DD)       if=$(BOOTLOADER) of=$(IMAGE) bs=1 skip=512 seek=512 conv=notrunc status=none > /dev/null
