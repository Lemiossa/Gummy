OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386)
ENTRY(_start)

SECTIONS
{
	. = 0xC0010000;
	__kernel_start = .;

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
