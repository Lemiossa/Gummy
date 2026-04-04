# Makefile
# Created by Matheus Leme Da Silva
MAKEFLAGS += --no-print-directory

BUILDDIR := $(CURDIR)/build
BINDIR := $(BUILDDIR)/bin
IMAGESDIR := $(BUILDDIR)/images

IMAGE := $(IMAGESDIR)/Bitix.img
BOOTLOADER := $(BINDIR)/bootloader.bin

IMAGEROOT := $(BUILDDIR)/imgroot

# For debian
PATH := $(PATH):/sbin:/usr/sbin

.PHONY: all
all: $(IMAGE)

.PHONY: clean
clean:
	@$(MAKE) -C bootloader clean TARGET=$(BOOTLOADER)

QEMU := qemu-system-i386
QEMUFLAGS := \
			 -drive file=$(IMAGE),format=raw,if=ide,media=disk \
			 -audiodev alsa,id=audio0 \
			 -machine pc,pcspk-audiodev=audio0 
.PHONY: qemu
qemu: $(IMAGE)
	@echo "  QEMU          $(IMAGE)"
	@$(QEMU) $(QEMUFLAGS)

.PHONY: qemu-ng
qemu-ng: $(IMAGE)
	@echo "  QEMU-NG       $(IMAGE)"
	@$(QEMU) $(QEMUFLAGS) -nographic

.PHONY: bootloader
bootloader:
	@echo "  BOOTLOADER"
	@$(MAKE) -C bootloader TARGET=$(BOOTLOADER)

$(IMAGE): bootloader
	@mkdir -p $(dir $@) $(IMAGEROOT)/subdir
	@echo "Hello world" > $(IMAGEROOT)/subdir/text.txt
	@echo "  GENIMG        $(IMAGE)"
	@dd if=/dev/zero of=$(IMAGE) bs=1K count=16384 status=none > /dev/null
	@echo "  MKFS.FAT      $(IMAGE)"
	@mkfs.fat --mbr=y -F 16 -n "BITIX" -R 64 $(IMAGE) > /dev/null
	@echo "  MCOPY         $(IMAGE)"
	@mcopy -i $(IMAGE) -s $(IMAGEROOT)/* "::/"
	@echo "  INSTALL BOOTLOADER"
	@dd if=$(BOOTLOADER) of=$(IMAGE) bs=1 count=3 conv=notrunc status=none > /dev/null
	@dd if=$(BOOTLOADER) of=$(IMAGE) bs=1 skip=62 seek=62 count=386 conv=notrunc status=none > /dev/null
	@dd if=$(BOOTLOADER) of=$(IMAGE) bs=1 skip=512 seek=512 conv=notrunc status=none > /dev/null
