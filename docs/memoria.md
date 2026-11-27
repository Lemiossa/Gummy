# Memória: PMM, VMM e heap

> **Arquivos:** [`kernel/include/arch/i686/pmm.h`](../kernel/include/arch/i686/pmm.h), [`kernel/src/arch/i686/pmm.c`](../kernel/src/arch/i686/pmm.c), [`kernel/include/arch/i686/vmm.h`](../kernel/include/arch/i686/vmm.h), [`kernel/src/arch/i686/vmm.c`](../kernel/src/arch/i686/vmm.c), [`kernel/include/heap.h`](../kernel/include/heap.h), [`kernel/src/heap.c`](../kernel/src/heap.c), [`include/bitmap.h`](../include/bitmap.h).

## Visão geral

```mermaid
flowchart LR
    E820["Mapa E820 @ 0xC0000500"] --> PMM["PMM<br/>bitmap 1 bit/página"]
    PMM -->|pmm_alloc_page| VMM["VMM<br/>PDE/PTE + CR3"]
    VMM -->|vmm_alloc_pages_region| HEAP["Heap 0xE0000000<br/>first-fit + split/coalesce"]
    VMM -->|vmm_clone| PROC["Processos: CR3 próprio<br/>páginas de usuário"]
    HEAP --> PROC
```

- Offset *higher-half*: **`0xC0000000`**; kernel em `0xC0010000` ↔ físico `0x10000`.
- Páginas de 4 KiB, dois níveis (1024 PDEs × 1024 PTEs), **diretório recursivo** em `0xFFC00000`.
- O bootloader deixa `PD[0]` (identidade do primeiro MiB) e `PD[768]` (alias higher-half) apontando para a mesma page table; `vmm_init()` zera `PD[0]` e preserva o alias.

## Gerenciador de memória física (PMM)

```c
#define PAGE_SIZE 4096

uintptr_t pmm_alloc_page(void);
void      pmm_free_page(uintptr_t page);
void      pmm_init(void);
```

Variáveis internas: `bitmap`, `bitmap_bits`, `bitmap_bytes`, `phys_top`, `usable_mem`. O bitmap fica **logo após o fim do kernel**: `BITMAP_LOCATION = (uint32_t)&__kernel_end` ([arquitetura-i686.md](arquitetura-i686.md#entrada-do-kernel-e-linker-script)). Um bit representa uma página física: 1 = ocupada, 0 = livre.

### `pmm_init()`

1. Itera as entradas E820, ignorando `base >= 0xFFFFFFFF`, limitando `end = MIN(base+length, 0xFFFFFFFF)`, acumulando `phys_top` e `usable_mem` das entradas com `type == 1`.
2. `bitmap_bits = phys_top / 4096`; `bitmap_bytes = ALIGN_UP(bitmap_bits, 8) / 8` (no máximo `0x20000` bytes = 128 KiB).
3. `memset(bitmap, 0xFF, bitmap_bytes)` — começa tudo ocupado.
4. Para cada entrada `type == 1`, libera os bits de `ALIGN_UP(base, 4096)/4096` até `ALIGN_DOWN(end, 4096)/4096`.
5. Reserva o kernel e o próprio bitmap: converte `&__kernel_start` e `&__kernel_end + bitmap_bytes` para físico subtraindo `0xC0000000` e marca as páginas correspondentes.
6. Reserva as **16 primeiras páginas** (`0x00000–0x0FFFF`), onde ficam a tabela E820 e os buffers do bootloader.
7. Imprime `Memoria utilizavel: 0x%08X\r\n`.

### Alocação e liberação

`pmm_alloc_page()` usa `bitmap_find_free_bit()` e devolve `page * PAGE_SIZE`. O valor **0 é sentinela de falha**, então a página física 0 nunca é retornada (na prática já está reservada). `pmm_free_page(page)` limpa o bit `page / PAGE_SIZE`, sem validar limites ou alinhamento.

## Gerenciador de memória virtual (VMM)

```c
extern uintptr_t kernel_cr3;

int   vmm_map(uintptr_t virt, uintptr_t phys, uint32_t flags);
int   vmm_unmap(uintptr_t virt);
void *vmm_alloc_pages_region(uint32_t n, uint32_t flags,
                             uintptr_t region_start, uintptr_t region_end);
void *vmm_alloc_pages(uint32_t n, uint32_t flags);
int   vmm_free_pages(uint32_t n, void *virt);
uintptr_t vmm_clone(void);
void  vmm_destroy(uintptr_t cr3);
void  vmm_init(void);

/* variantes que operam em outro CR3 */
int   vmm_map_in(uintptr_t cr3, uintptr_t virt, uintptr_t phys, uint32_t flags);
int   vmm_unmap_in(uintptr_t cr3, uintptr_t virt);
void *vmm_alloc_pages_region_in(uintptr_t cr3, uint32_t n, uint32_t flags,
                                uintptr_t region_start, uintptr_t region_end);
void *vmm_alloc_pages_in(uintptr_t cr3, uint32_t n, uint32_t flags);
int   vmm_free_pages_in(uintptr_t cr3, uint32_t n, void *virt);
```

### Layout e acesso às tabelas

```c
pde_index = virt >> 22;
pte_index = (virt >> 12) & 0x3FF;
get_pde(virt) = &((uint32_t *)0xFFFFF000)[virt >> 22];
get_pt(virt)  = (uint32_t *)(0xFFC00000 + pde_index * 0x1000);
get_pte(virt) = &get_pt(virt)[pte_index];
```

| Macro de flag | Bit | Valor |
|---|---:|---:|
| `VMM_FLAGS_PRESENT` | 0 | `0x001` |
| `VMM_FLAGS_RW` | 1 | `0x002` |
| `VMM_FLAGS_USER` | 2 | `0x004` |
| `VMM_FLAGS_PWT` | 3 | `0x008` |
| `VMM_FLAGS_PCD` | 4 | `0x010` |
| `VMM_FLAGS_ACCESSED` | 5 | `0x020` |
| `VMM_FLAGS_RESERVED` | 6 | `0x040` |
| `VMM_FLAGS_PAGE_SIZE` | 7 | `0x080` |
| `VMM_FLAGS_GLOBAL` | 8 | `0x100` |

### Comportamento das funções

- **`vmm_map()`**: se a PDE não existe, aloca uma page table com `pmm_alloc_page()`, zera suas 1024 entradas e grava a PDE com as flags; grava a PTE e executa `invlpg(virt)`.
- **`vmm_unmap()`**: zera a PTE e invalida a TLB; se a page table ficar vazia e `virt < 0xC0000000`, libera a PT e zera a PDE (tabelas higher-half nunca são liberadas).
- **`vmm_alloc_pages_region()`**: alinha a região e procura `n` PTEs livres consecutivas; aloca com `pmm_alloc_page()` e mapeia com `vmm_map()`, desfazendo o trabalho em caso de falha. `vmm_alloc_pages()` usa `[0x1000, 0xFFC00000)`.
- **`vmm_free_pages()`**: exige que todas as PTEs estejam presentes; libera cada página física e invalida a TLB.
- **Variantes `*_in()`**: desligam interrupções, trocam CR3 pelo argumento, executam a operação e restauram CR3 e EFLAGS. São usadas para montar espaços de usuário antes de escaloná-los.
- **`vmm_clone()`**: aloca 1 página para o novo diretório, zera as 1024 entradas, copia apenas as PDEs **768..1023** (metade kernel) e reescreve a entrada 1023 com o próprio CR3 físico (recursividade). Retorna o **endereço físico** do diretório; o espaço de usuário nasce vazio (sem COW).
- **`vmm_destroy(cr3)`**: ignora `cr3 == 0` ou igual ao CR3 atual; percorre PDEs 0..767, libera páginas e page tables de usuário e zera as entradas. A página do diretório é liberada pelo chamador (`sched_destroy_process()` → `pmm_free_page(proc->cr3)`).
- **`vmm_init()`**: captura `kernel_cr3 = read_cr3()`, zera `PD[0]` e invalida a TLB de `0x0` a `0xFFFFF` (remove a identidade do primeiro MiB).

> Não existe `vmm_copy()` no código (apenas uma menção no `CHANGELOG.md`). Não há demand paging, copy-on-write nem handler de page fault no VMM: o vetor 14 é tratado em `exception.c`, que destrói o processo de usuário ou para o kernel.

### Mapa de endereços virtuais

| Região | Intervalo | Uso |
|---|---|---|
| Usuário — imagem | `0x400000`…`0x1000000` | código do `init` (máx. 16 MiB) |
| Usuário — pilhas | `0xBFF78000`…`0xBFFFF000` | 8 slots de 64 KiB + guard page |
| Kernel — código | `0xC0010000`…`__kernel_end` | ELF do kernel |
| E820 | `0xC0000500` | mapa de memória |
| Initrd | `0xC0050000` | imagem lida por `initrd_*` |
| VGA | `0xC00B8000` | console 80×25 |
| Heap | `0xE0000000`… | 24 páginas iniciais, expansão até `0xFFC00000` |
| Recursivo | `0xFFC00000`…`0xFFFFFFFF` | page tables e diretório de páginas |

## Heap do kernel

```c
#define HEAP_VIRTUAL_ADDRESS     0xE0000000
#define HEAP_INITIAL_PAGES       24
#define HEAP_SPLIT_BLOCK_MIN_SIZE 32

void  heap_init(void);
void *heap_alloc(size_t size);
void  heap_free(void *ptr);
void  heap_print(void);

/* internas, não declaradas no header */
void *heap_expand(size_t n);
void  heap_merge_free_blocks(heap_block_t *b);
void  heap_split_block(heap_block_t *b, size_t size);
```

### Estrutura de bloco

```c
typedef struct heap_block {
    size_t size;                 /* tamanho do payload, sem o cabeçalho */
    uint8_t used;                /* 1 = alocado, 0 = livre */
    struct heap_block *prev, *next;
} heap_block_t;
```

Em i386 o cabeçalho tem 16 bytes. A lista é duplamente ligada e ordenada por endereço; o ponteiro devolvido é `b + sizeof(heap_block_t)`. **Não há campo `magic`**, portanto double-free e ponteiros inválidos não são detectados.

### Algoritmo

1. `heap_init()` pede 24 páginas em `[0xE0000000, 0xE0018000)` com `vmm_alloc_pages_region()` e cria um bloco livre de `98312` bytes.
2. `heap_alloc(size)` arredonda para `ALIGN_UP(size, sizeof(uintptr_t))` (4 bytes em i386) e escolhe o **primeiro** bloco livre com espaço suficiente (*first-fit*).
3. `heap_split_block()` divide o bloco se sobrarem pelo menos 32 bytes de payload; caso contrário o bloco inteiro é alocado.
4. Se não há bloco adequado, `heap_expand()` aloca páginas adicionais no fim da região e as anexa à lista (sem dividir: um bloco inteiro vira usado).
5. `heap_free()` marca o bloco como livre e chama `heap_merge_free_blocks()`, que mescla com `prev` e/ou `next` quando também estão livres. **A coalescência só acontece no free**.

`heap_print()` imprime `blocos=%u usado=%u b livre=%u b\r\n`, mas não é chamada em nenhum lugar do kernel.

## Limitações conhecidas

1. `pmm_alloc_page()` usa 0 como falha; `pmm_free_page()` não valida o argumento.
2. `bitmap_find_free_bit()` retorna 0 tanto para "bit 0 livre" quanto para "nenhum livre"; `set/test/clear` não checam limites ([biblioteca.md](biblioteca.md)).
3. `vmm_map()`/`vmm_unmap()` não validam alinhamento de `virt`/`phys`.
4. `vmm_clone()` não copia páginas de usuário nem implementa COW; `vmm_destroy()` não libera o diretório (feito pelo chamador).
5. Heap sem canário: double-free e ponteiro interior corrompem a lista.
6. `heap_expand()` marca blocos inteiros como usados (fragmentação interna); alinhamento de apenas 4 bytes em i386.
7. `heap_print()` usa contadores `uint32_t` para somar `size_t`.
8. `switch_context()` recarrega CR3 mesmo entre threads do mesmo processo, invalidando a TLB sem necessidade.

## Ver também

- [Bootloader: paginação inicial](bootloader.md#transição-para-modo-protegido-e-paginação)
- [Escalonador: CR3 e pilhas](escalonador.md)
- [Biblioteca comum: bitmap](biblioteca.md#bitmap-bitmaph-header-only)
- [Estado atual e pendências](estado-atual.md)
