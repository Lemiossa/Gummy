# Changelog

All notable changes to Gummy are documented here. Entries follow the Git tags in chronological order.

## v0.1.0 — 2026-07-27

First version. Functional foundation of the system:

- **Two-stage bootloader** (stage1/stage2) in assembly: boot sector with disk reads via INT 13h, and stage2 with disk driver, its own console, and a complete FAT driver (FAT table reading, directories, `fat_read_file`).
- **Kernel loading**: stage2 detects the FAT type, loads the kernel image and jumps to it.
- **Initial i686 kernel**: reloaded GDT, zeroed BSS, VGA text-mode terminal driver.
- **GNU Make build system**: FAT16 image generated automatically, QEMU target and silent mode.

## v0.2.0 — 2026-08-04

- Kernel: cleaned-up assembly entry (direction flag cleared, BSS zeroed), GDT naming fix and lowercase syntax.
- Kernel: added the IDT with basic exception handlers.

## v0.3.0 — 2026-08-21

- Kernel: parsing of the E820 memory map collected by the bootloader and total memory printout.
- Kernel: PIC remapped to the correct vectors (0x20+).
- Build: kernel compiled with the i686-elf GCC cross-compiler; versioned image names (`NAME`/`VERSION` macros); `source/` renamed to `src/`.

## v0.4.0 — 2026-08-22

- **PMM (Physical Memory Manager)**: physical page allocation based on a bitmap built from the E820 map.
- `types.h`: added `ALIGN_UP`/`ALIGN_DOWN` macros.
- README: cross-compiler build guide.

## v0.5.1 — 2026-08-26

- Added `bitmap_find_free_bit`; PMM now uses free-bit search for page allocation.
- VMM groundwork: initial structures and page directory (`vmm.c`), starting higher-half kernel support.

## v0.5.2 — 2026-08-26

- PMM improvements (more robust bitmap initialization) and VMM progress.

## v0.5.3 — 2026-08-26

- More complete VMM: `vmm_map`/`vmm_unmap`, page mapping with flags.

## v0.5.4 — 2026-08-29

- **Interrupt handling rewrite**: new IDT model with `exception.c`, centralized handlers and I/O fixes (carriage return in error messages).
- `SOURCE` renamed to `SRC` in the Makefiles.

## v0.5.5 — 2026-08-29

- Fixed formatting (`\r`) in `exception_handler` messages.

## v0.5.6 — 2026-08-29

- VMM: unmapped the first MiB of memory (low memory area released).

## v0.5.7 — 2026-08-29

- VMM made more generic (unified signatures and flags).

## v0.5.8 — 2026-08-29

- Type renaming for consistency (`u8`/`u16`/`u32`…) across the kernel.

## v0.6.0 — 2026-08-29

- **Timer (PIT)**: PIT driver and tick counter; page fault handler registered (initially only logged).

## v0.6.1 — 2026-08-29

- Timer fix: send EOI to the PIC on every tick.

## v0.6.2 — 2026-08-29

- Fixed page fault when unmapping the first MiB; VMM reorganized (more helpers, fewer messages).

## v0.6.3 — 2026-08-30

- Removed PMM/VMM debug messages.

## v0.7.0 — 2026-09-01

- VMM: added `vmm_alloc_pages` and `vmm_free_pages` (contiguous virtual page allocation).

## v0.8.0 — 2026-09-14

- VMM: added `vmm_clone()` (address space cloning).

## v0.8.1 — 2026-09-18

- Scheduler groundwork: `timer.c` turned into `sched.c` with counters/scheduling basis.

## v0.9.0 — 2026-09-22

- **Kernel heap** (`heap.c`) with its own allocator.
- Major PMM/VMM revision: e820 cleanup, revised types, adjusted `vmm.h`/`pmm.h`.
- GDB debugging support (Makefile + README).

## v0.9.1 — 2026-09-24

- Removed the PMM initialization message; simplified `kmain`.

## v0.9.2 — 2026-09-25

- Fixed text terminal scrolling.

## v0.10.0 — 2026-09-24

- Heap: block splitting and merge (coalescing) on free. *(tagged later, but historically belongs here)*

## v0.10.1 — 2026-09-25

- Fixed declarations (prototypes) in `pmm.h`/`vmm.h`.

## v0.11.0 — 2026-09-25

- **Serial (COM)**: basic serial write functions and `debug.c` module; `kmain` and terminal adjusted to use serial as debug output.

## v0.11.1 — 2026-09-25

- Added logs across subsystems (e820, exceptions, GDT/IDT, PMM, VMM, heap, PIC, PIT).

## v0.11.2 — 2026-09-26

- More logs in the PMM and VMM.

## v0.12.0 — 2026-09-26

- **Experimental scheduler**: task structures and context switch groundwork started, IDT/timer hooks.

## v0.12.1 — 2026-09-30

- Scheduler temporarily simplified/removed ("returning to simplicity").

## v0.13.0 — 2026-10-01

- Build with detailed compilation messages; new `lib/` directory with `string.c` alongside the kernel.

## v0.13.1 — 2026-10-02

- More logs in `heap.c`.

## v0.14.0 — 2026-10-03

- **Initial multitasking!**
  - TSS (Task State Segment) set up in the GDT with stack switch support.
  - Queue (`queue.h`/`queue.c` in `lib/`) for task states.
  - Scheduler rewritten with ready queues; tasks with their own context.

---

Note: there are no commits after `v0.14.0`, so no `Unreleased` section was needed. `v0.9.2` was tagged out of order (after `v0.11.0`), but in the Git history it sits between `v0.9.1` and `v0.10.0` — this changelog follows the history order.
