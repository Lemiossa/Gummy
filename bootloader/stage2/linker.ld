ENTRY(_start)
__start_addr__ = 0x8000;

SECTIONS
{
	. = __start_addr__;
	.text : {
		*(.entry)
		*(.text*)
	}

	.data : {
		*(.data*)
	}

	.bss : {
		*(.bss*)
	}

	__end_addr__ = .;
}
