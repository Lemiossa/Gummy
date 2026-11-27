# Camada de arquitetura i686

> **Arquivos:** [`kernel/src/arch/i686/`](../kernel/src/arch/i686/) (entry, GDT, IDT, TSS, exceções, E820, PMM, VMM, syscalls), [`kernel/include/arch/i686/`](../kernel/include/arch/i686/) e [`include/arch/i686/syscall.h`](../include/arch/i686/syscall.h).

## Entrada do kernel e linker script

### `entry.asm`

```asm
bits 32
section .text
global _start
extern kmain
extern __bss_start, __bss_end

_start:
    cli                       ; desliga interrupções
    mov esp, stack_top        ; pilha estática de 4096 bytes
    cld                       ; DF=0 para rep stosb
    xor al, al
    mov edi, __bss_start
    mov ecx, __bss_end
    sub ecx, edi
    rep stosb                 ; zera toda a BSS
    call kmain
.hang:
    cli
    hlt
    jmp .hang
```

O kernel entra **já com paginação ativa**: o bootloader configurou CR3 e `CR0.PG` antes do salto para `0xC0010000`. Não há configuração de paging em `entry.asm` e nenhum parâmetro de boot é lido.

### `link.ld`

```ld
OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386)
ENTRY(_start)

SECTIONS
{
    . = 0xC0010000;
    __kernel_start = .;
    .text   ALIGN(4096) : { *(.text*) }
    .rodata ALIGN(4096) : { *(.rodata*) }
    .data   ALIGN(4096) : { *(.data*) }
    __bss_start = .;
    .bss    ALIGN(4096) : { *(COMMON) *(.bss*) }
    __bss_end = .;
    __kernel_end = .;
}
```

| Símbolo | Endereço |
|---|---|
| `__kernel_start` / `_start` | `0xC0010000` (físico `0x10000`) |
| `__bss_start` | fim de `.data` |
| `__bss_end` / `__kernel_end` | fim de `.bss` (usado pelo PMM para o bitmap) |

Com `-fdata-sections -ffunction-sections` e `-Wl,--gc-sections`, símbolos não referenciados são descartados no ELF final.

## GDT

`gdt_init()` preenche 8 entradas e chama `gdt_flush(&gdtr)` (assembly: `lgdt`, salto far para `0x08`, recarga de `ds/es/fs/gs/ss` com `0x10`). O tamanho registrado é `8*8 - 1 = 63`.

| Índice | Seletor | Uso | Access | Flags | DPL |
|---:|---:|---|---:|---:|---:|
| 0 | `0x00` | nula | `0x00` | `0` | 0 |
| 1 | `0x08` | código kernel (KCODE32) | `0x9A` | `0xC` (G=1, D/B=1) | 0 |
| 2 | `0x10` | dados kernel (KDATA32) | `0x92` | `0xC` | 0 |
| 3 | `0x18` | código usuário (UCODE32) | `0xFA` | `0xC` | **3** |
| 4 | `0x20` | dados usuário (UDATA32) | `0xF2` | `0xC` | **3** |
| 5 | `0x28` | TSS (instalada por `tss_init()`) | `0x89` | `0` | 0 |
| 6–7 | `0x30`, `0x38` | reservadas/zero | — | — | — |

Com `G=1` e limite `0xFFFFF`, os segmentos de código/dados cobrem 4 GiB. Os seletores efetivos de usuário incluem RPL 3: **`0x1B`** (código) e **`0x23`** (dados).

```c
void gdt_set_entry(uint16_t index, uint32_t base, uint32_t limit,
                   uint8_t access, uint8_t flags);
void gdt_init(void);
extern void gdt_flush(gdtr_t *);
```

> O nome real da função é `gdt_set_entry` (não `gdt_set`). O bootloader usa uma GDT própria de apenas 3 entradas, substituída por esta no boot do kernel.

## TSS

```c
struct tss_entry { /* 104 bytes = 0x68 */
    uint32_t prev_tss, esp0, ss0, esp1, ss1, esp2, ss2, cr3;
    uint32_t eip, eflags, eax, ecx, edx, ebx, esp, ebp, esi, edi;
    uint32_t es, cs, ss, ds, fs, gs, ldt;
    uint16_t trap, iomap_base;
} __attribute__((packed));

void tss_init(void);
extern void tss_flush(uintptr_t sel);       /* ltr */
void tss_set_sp0(uintptr_t sp0, uintptr_t ss0);
```

`tss_init()` zera a estrutura, define `ss0 = 0x10`, `iomap_base = 0x68`, instala o descritor na entrada 5 da GDT (`base = &tss`, limite `0x67`, access `0x89`) e chama `tss_flush(0x28)`. A cada troca de contexto, `switch_context()` atualiza `esp0` com `new->stack0 + 4096` e `ss0 = 0x10`: é daí que a CPU retira `SS:ESP` ao entrar em ring 0 por interrupção ou syscall.

## IDT e tratadores

### Estruturas

```c
typedef struct { uint16_t size; uint32_t offset; } __attribute__((packed)) idtr_t;

typedef struct {
    uint16_t offset_low;
    uint16_t selector;
    uint8_t reserved;
    uint8_t attributes;
    uint16_t offset_high;
} __attribute__((packed)) idt_entry_t;      /* 8 bytes */

typedef struct {
    uint32_t gs, fs, es, ds;                    /* 4 */
    uint32_t esi, edi, ebp, edx, ecx, ebx, eax; /* 7 */
    uint32_t int_num, error_code;               /* 2 */
    uint32_t eip, cs, eflags, esp, ss;          /* 5 */
} __attribute__((packed)) interrupt_context_t;  /* 72 bytes */

typedef void (*interrupt_handler_t)(interrupt_context_t *ctx);
```

`idtr.size = 256*8 - 1 = 2047`, seletor `0x08`, atributo padrão `0x8E` (interrupt gate, DPL 0). Vetores 3 e 4 usam `0x8F` (trap gate).

```c
void idt_init(void);
void idt_set_handler(uint16_t index, interrupt_handler_t handler);
void idt_set_dpl(uint16_t index, uint8_t dpl);
void interrupt_handler(interrupt_context_t *ctx);
extern void load_idt(idtr_t *);                /* lidt */
extern void restore_context(uintptr_t esp0);   /* usado pelo scheduler */
```

> O nome real da rotina de carregamento é `load_idt` (não `idt_flush`). `idt_set_dpl(0x80, 3)` transforma o atributo de `0x8E` em `0xEE`.

### Stubs em assembly

- 256 stubs gerados por macros: `isr_stub_no_error N` empilha `0` (error code falso) e `N`; `isr_stub_error N` empilha somente `N` porque a CPU já empilhou o código. Vetores com código da CPU: **8, 10, 11, 12, 13, 14, 17**.
- `isr_common` empilha `eax, ebx, ecx, edx, ebp, edi, esi`, depois `ds, es, fs, gs`, recarrega os segmentos com `0x10`, empilha `esp` (o `ctx`) e chama `interrupt_handler`.
- `_restore_context` desempilha os segmentos e registradores, descarta `error_code` + `int_num` (`add esp, 8`) e executa `iret`. É reaproveitado por `restore_context()` na troca de contexto.

### Handlers registrados

| Vetor | Número | Handler | Origem | DPL |
|---|---:|---|---|---:|
| 0–31 | `0x00–0x1F` | `exception_handler` | `exception_init()` | 0 |
| IRQ0 | `0x20` (32) | `timer_handler` | `sched_init()` | 0 |
| syscall | `0x80` (128) | `syscall_handler` | `syscall_init()` | 3 |
| yield | `0x81` (129) | `schedule` | `sched_init()` | 3 |

Os outros 220 vetores têm handler nulo; os stubs apenas descartam o quadro e fazem `iret`.

```mermaid
flowchart TD
    int[INT n / IRQ / exceção] --> cpu[CPU empilha SS:ESP, EFLAGS, CS:EIP\n(se mudança de CPL)]
    cpu --> stub[isr_stub_N empilha error_code + int_num]
    stub --> common[isr_common empilha GS..EAX\nsegmentos = 0x10]
    common --> dispatch[interrupt_handler ctx]
    dispatch --> h0[exception_handler 0..31]
    dispatch --> h32[timer_handler 32]
    dispatch --> h80[syscall_handler 0x80]
    dispatch --> h81[schedule 0x81]
    h0 --> restore[_restore_context: pop + iret]
    h32 --> restore
    h80 --> restore
    h81 --> switch[switch_context → restore_context]
```

## Exceções

```c
void exception_init(void);  /* registra exception_handler nos vetores 0..31 */
```

`exception_handler(ctx)`:

1. Detecta a origem com `from_user = (ctx->cs & 3) == 3`.
2. Imprime o nome da exceção, `INT: n`, `EIP: 0x%08X` e, para page fault (14), `CR2: 0x%08X` via `read_cr2()`.
3. Chama `debug_dump_code((uintptr_t)ctx->eip, 16)` — 16 bytes em hexadecimal após `Bytes em 0x...:`.
4. **Usuário:** `sched_destroy_current_process()` marca o processo como `PROCESS_DYING` e cede a CPU; o reaper o destrói depois.
5. **Kernel:** imprime `Sistema parado!\r\n` e entra em `for (;;) { disable_interrupts(); halt_cpu(); }`.

Nomes de 0 a 31: Division Error, Debug, Non-Maskable Interrupt, Breakpoint, Overflow, BOUND Range Exceeded, Invalid Opcode, Device Not Available, Double Fault, Coprocessor Segment Overrun, Invalid TSS, Segment Not Present, Stack-Segment Fault, General Protection Fault, Page Fault, Reserved, x87 Floating-Point Exception, Alignment Check, Machine Check, SIMD Floating-Point Exception, Virtualization Exception, Control Protection Exception, Reserved (22–27), Hypervisor Injection Exception, VMM Communication Exception, Security Exception, Reserved (31).

> Não há dump de registradores gerais nem de stack, apesar de `interrupt_context_t` conter todos eles. Page fault não faz demand paging nem COW: apenas destrói o processo de usuário ou para o kernel.

## E820

```c
#define E820_ADDRESS 0xC0000500

typedef struct {
    uint64_t base, length;
    uint32_t type, acpi_extended;
} __attribute__((packed)) e820_entry_t;   /* 24 bytes */

void E820_init(void);
extern uint16_t E820_entry_count;
extern e820_entry_t *E820_entries;
```

O bootloader grava o contador em `0x500` e as entradas a partir de `0x502` via `INT 15h, AX=0xE820`. O kernel lê os mesmos bytes pelo alias `0xC0000500`. `E820_init()` apenas imprime as entradas; o PMM as usa para construir o bitmap ([memoria.md](memoria.md)). A variável `total_memory` é declarada, mas nunca atribuída nem usada.

## Diferenças em relação a nomes comuns

| Nome esperado | Nome no código |
|---|---|
| `gdt_set` | `gdt_set_entry` |
| `idt_flush` | `load_idt` |
| `vmm_copy` | inexistente (há `vmm_clone`) |
| `syscall.h` em `kernel/include/arch/i686/` | está em `include/arch/i686/syscall.h` |

## Ver também

- [Interrupções e timer](interrupcoes.md)
- [Memória: PMM/VMM](memoria.md)
- [Troca de contexto no escalonador](escalonador.md#troca-de-contexto)
- [Syscalls](syscalls.md)
- [Bootloader: transição para 32 bits](bootloader.md#transição-para-modo-protegido-e-paginação)
