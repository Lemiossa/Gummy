OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386)
ENTRY(_start)

SECTIONS
{
	__kernel_start = .;
	. = 0x10000;

	.text : {
		*(.text*)
	}

	.rodata : {
		*(.rodata*)
	}

	.data : {
		*(.data*)
	}

	__bss_start = .;
	.bss : {
		*(COMMON)
		*(.bss*)
	}
	__bss_end = .;
	__kernel_end = .;
}
