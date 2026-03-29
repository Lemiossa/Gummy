# Makefile
# Created by Matheus Leme Da Silva

BUILDDIR := $(CURDIR)/build
BINDIR := $(BUILDDIR)/bin
IMAGESDIR := $(BUILDDIR)/images

IMAGE := $(IMAGESDIR)/Bitix.img
BOOTLOADER := $(BINDIR)/bootloader.bin

.PHONY: all
all: $(IMAGE)

.PHONY: clean
clean:
	$(MAKE) -C bootloader clean TARGET=$(BOOTLOADER)

.PHONY: qemu
qemu: $(IMAGE)
	qemu-system-i386 -drive file=$(IMAGE),format=raw,if=ide,media=disk \
		-machine pc

.PHONY: bootloader
bootloader:
	$(MAKE) -C bootloader TARGET=$(BOOTLOADER)

$(IMAGE): bootloader
	mkdir -p $(dir $@)
	dd if=/dev/zero of=$(IMAGE) bs=1 count=0 seek=1440K
	dd if=$(BOOTLOADER) of=$(IMAGE) conv=notrunc 
