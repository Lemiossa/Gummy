OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386)
ENTRY(_start)

SECTIONS
{
	. = 0xC0010000;
	__kernel_start = .;

	.text ALIGN(4096) : {
		*(.text*)
	}

	.rodata ALIGN(4096) : {
		*(.rodata*)
	}

	.data ALIGN(4096) : {
		*(.data*)
	}

	__bss_start = .;
	.bss ALIGN(4096) : {
		*(COMMON)
		*(.bss*)
	}
	__bss_end = .;
	__kernel_end = .;
}
