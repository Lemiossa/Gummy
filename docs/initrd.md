# Initrd — disco de inicialização em memória

> **Arquivos:** [`initrd/make-initrd`](../initrd/make-initrd), [`initrd/Makefile`](../initrd/Makefile), [`initrd/init/`](../initrd/init/), [`include/initrd.h`](../include/initrd.h), [`lib/src/initrd.c`](../lib/src/initrd.c), leitura em [`kernel/src/kmain.c`](../kernel/src/kmain.c).

## Visão geral

O initrd é uma imagem simples contendo o programa `init.sys` (e futuros arquivos). O bootloader a carrega em `0x50000` (físico); o kernel a lê pelo alias higher-half `0xC0050000`, encontra a entrada `/init.sys`, copia seus bytes para `0x400000` no espaço de usuário e cria o PID 1. O `init` termina imediatamente com `SYS_EXIT(42)`.

```mermaid
flowchart LR
    A[init/src/main.c + entry.asm] -->|i686-elf-gcc / objcopy| B[init.bin]
    B -->|initrd/Makefile → build/root/init.sys| C[make-initrd Python]
    C -->|header + entradas + dados| D[build/initrd]
    D -->|mcopy para a imagem FAT| E["/INITRD no disco"]
    E -->|stage2 → 0x00050000| F[0xC0050000 no kernel]
    F -->|initrd_find_entry /init.sys| G[PID 1 em 0x400000]
```

## Formato da imagem

Todos os inteiros são little-endian e as estruturas são `packed`.

### Header (16 bytes)

```c
typedef struct {
    uint32_t magic;        /* INITRD_MAGIC = 0x47554D4D → bytes 'M','M','U','G' */
    uint32_t version;      /* 1 */
    uint32_t entry_count;
    uint32_t data_offset;  /* 16 + Σ(20 + tamanho do nome) */
} __attribute__((packed)) initrd_header_t;
```

### Entrada (20 bytes + nome NUL-terminated)

```c
typedef struct {
    uint32_t type;         /* 1 = diretório, 2 = arquivo */
    uint32_t permissions;  /* bits de permissão do stat */
    uint32_t name_size;    /* inclui o NUL */
    uint32_t offset;       /* offset absoluto dentro da imagem */
    uint32_t size;         /* bytes de dados */
} __attribute__((packed)) initrd_entry_t;
```

```text
┌──────────────────┬──────────────────────────┬────────────────────┐
│ header (16 B)    │ entradas (20 B + nome) × N │ dados dos arquivos │
└──────────────────┴──────────────────────────┴────────────────────┘
                    data_offset ────────────────▶
```

O gerador [`make-initrd`](../initrd/make-initrd) usa `struct.pack("<IIII", ...)` e `struct.pack("<IIIII", ...)`, um placeholder de 4 bytes para `data_offset`, calcula os offsets acumulados e reescreve o header.

## API do parser

```c
void                 initrd_create(initrd_t *out, const void *data);
int                  initrd_check(const initrd_t *initrd);          /* !0 = inválido */
const initrd_entry_t *initrd_get_entry(const initrd_t *initrd, size_t n);
const initrd_entry_t *initrd_find_entry(const initrd_t *initrd, const char *path);
size_t               initrd_get_len(const initrd_entry_t *entry);
const void *         initrd_get_data(const initrd_t *initrd, const initrd_entry_t *entry);
```

- `initrd_create()` monta `entries = base + 16` e `data = base + header->data_offset`.
- `initrd_get_entry()` avança `sizeof(initrd_entry_t) + name_size` por entrada.
- `initrd_find_entry()` compara `name_size == strlen(path) + 1` e usa `memcmp` — o nome inclui a barra inicial (`/init.sys`).
- `initrd_get_data()` retorna `base + entry->offset` (o campo `initrd.data` calculado em `initrd_create` não é usado nessa função).
- `initrd_check()` valida apenas ponteiros e o magic.

## O programa `init`

`initrd/init/src/main.c` contém apenas:

```c
int main(void) { return 42; }
```

O startup em `arch/i686/entry.asm` faz:

```asm
_start:
    call main
    mov ebx, eax       ; código de saída = 42
    mov eax, 0         ; SYS_EXIT
    int 0x80
    jmp $              ; inalcançável
```

O binário é linkado em `0x400000` (`init/src/arch/i686/link.ld`), com `ENTRY(_start)` e seções `.text`, `.rodata`, `.data`, `.bss`. O kernel fornece `ESP = 0xBFFFF000` no frame sintético da thread ([escalonador.md](escalonador.md#criação-de-threads-e-pilhas)). O `.bss` **não é zerado** pelo startup. Não há impressão de texto nem outras syscalls além de `SYS_EXIT`.

## Uso no kernel

Em `kmain`, após `syscall_init()` e com interrupções habilitadas:

```c
const char *initpath = "/init.sys";
uintptr_t initrd_loc = 0xC0050000;

initrd_t initrd;
initrd_create(&initrd, (void *)initrd_loc);
if (initrd_check(&initrd)) goto halt;

const initrd_entry_t *init = initrd_find_entry(&initrd, initpath);
if (!init) { printk("Falha ao carregar init!\r\n"); ... goto halt; }

size_t len = initrd_get_len(init);
const void *data = initrd_get_data(&initrd, init);
sys_nprocess(data, len);      /* cria PID 1 em 0x400000 */
for (;;) halt_cpu();
```

## Limitações

1. `initrd_check()` não valida `entry_count`, `name_size`, `offset`, `size` nem `version` — uma imagem corrompida causa leituras fora dos limites.
2. `initrd_find_entry()` reescaneia a tabela desde o início a cada chamada (O(n²)).
3. `name_size` é comparado de forma estrita; nomes sem a barra inicial não são encontrados.
4. `.bss` do `init` não é zerada, portanto globais com valor zero pueden conter lixo.
5. `jmp $` após a syscall de exit é código morto; se o exit falhar, o init entra em loop ocupando a CPU.
6. O initrd não é exposto pelo [VFS](vfs.md): o kernel o lê diretamente via `initrd_*`.

## Ver também

- [Build e execução](build.md) — como a imagem é gerada e onde `/INITRD` é gravada
- [Bootloader](bootloader.md) — carregamento do initrd pelo stage2
- [Syscalls](syscalls.md) — `sys_nprocess` e `sys_exit`
