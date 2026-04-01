# Makefile
# Created by Matheus Leme Da Silva

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
	$(MAKE) -C bootloader clean TARGET=$(BOOTLOADER)

QEMU := qemu-system-i386
QEMUFLAGS := \
			 -drive file=$(IMAGE),format=raw,if=ide,media=disk \
			 -audiodev alsa,id=audio0 \
			 -machine pc,pcspk-audiodev=audio0

.PHONY: qemu
qemu: $(IMAGE)
	$(QEMU) $(QEMUFLAGS)

.PHONY: qemu-ng
qemu-ng: $(IMAGE)
	$(QEMU) $(QEMUFLAGS) -nographic

.PHONY: bootloader
bootloader:
	$(MAKE) -C bootloader TARGET=$(BOOTLOADER)

$(IMAGE): bootloader
	mkdir -p $(dir $@) $(IMAGEROOT)
	echo "Hello world" > $(IMAGEROOT)/text.txt
	dd if=/dev/zero of=$(IMAGE) bs=1K count=1440 
	mkfs.fat -F 12 -n "BITIX" -R 64 $(IMAGE)
	mcopy -i $(IMAGE) -s $(IMAGEROOT)/* "::/"
	dd if=$(BOOTLOADER) of=$(IMAGE) bs=1 count=3 conv=notrunc 
	dd if=$(BOOTLOADER) of=$(IMAGE) bs=1 skip=62 seek=62 count=386 conv=notrunc 
	dd if=$(BOOTLOADER) of=$(IMAGE) bs=1 skip=512 seek=512 conv=notrunc 
