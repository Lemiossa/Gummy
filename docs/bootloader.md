# Bootloader

> **Arquivos:** [`bootloader/stage1/src/`](../bootloader/stage1/src/), [`bootloader/stage2/src/`](../bootloader/stage2/src/) e os Makefiles de [`bootloader/`](../bootloader/).

## Visão geral

O bootloader é montado pela concatenação de dois binários NASM `-f bin`:

```make
cat stage1.bin stage2.bin > bootloader.bin
```

O resultado é injetado em uma imagem FAT12 de 1,44 MiB preservando a BPB gerada por `mkfs.fat`. Não há Multiboot nem ABI de parâmetros: kernel, initrd e mapa E820 são encontrados por **endereços físicos fixos**.

```mermaid
flowchart TD
    bios[BIOS carrega setor 0 @ 0x7C00] --> s1[Stage 1: 62 setores via INT 13h CHS\n→ 0x7E00]
    s1 --> s2[Stage 2 @ 0x7E00\ncheca CPU, EDD, FAT]
    s2 --> fat[FAT12: lê KERNEL.SYS @ 0x10000\ne INITRD @ 0x50000]
    fat --> e820[INT 15h E820 @ 0x500]
    e820 --> pm[A20, GDT, CR0.PE, paginação\nPD[0], PD[768], PD[1023]]
    pm --> k[jmp 0xC0010000]
```

## Stage 1

**Arquivos:** `main.asm`, `console.asm`, `disk.asm`. Tamanho: exatamente 512 bytes.

```asm
bits 16
org 0x7c00
start_addr:   equ 0x7e00
start_sector: equ 1
sector_count: equ 62
```

### Layout do setor

| Offset | Conteúdo |
|---:|---|
| `0x0000–0x0002` | `jmp short main` + `nop` |
| `0x0003–0x003D` | 59 bytes zero (reserva de BPB) |
| `0x003E` (62) | início do código (`main`) |
| `0x01B8` (440) | `dd __TIME__` do NASM |
| `0x01FE` (510) | assinatura `0xAA55` |

O `mkfs.fat` gera a BPB nos bytes 3–61 e o `Makefile` preserva esses bytes ao injetar o bootloader. O setor de boot original da FAT não é usado.

### Fluxo

1. `cli`, `DS=ES=SS=0`, `SP=0x7C00`, `sti`; salva `DL` (drive da BIOS).
2. `INT 13h, AH=08h` para geometria: setores por trilha (`CL & 0x3F`) e cabeças (`DH + 1`).
3. Destino `ES:BX = 0x07E0:0x0000` → físico `0x7E00`.
4. Origem LBA 1, contador 62 setores.
5. Loop: lê um setor, imprime `.` via `INT 10h, AH=0x0E`, avança `BX += 512` e `LBA += 1`.
6. Ao terminar (62 × 512 = 31.744 bytes = `0x7C00`, físico `0x7E00..0xF9FF`), salta com `RETF` para `0x07E0:0x0000`.

| Função | Arquivo | Finalidade |
|---|---|---|
| `print_string` | `console.asm` | string NUL via `INT 10h, AH=0x0E` |
| `read_sector` | `disk.asm` | LBA→CHS e leitura via `INT 13h, AH=02h` |
| `int13_failed` | `disk.asm` | mensagem `Falha no Int13!` e parada |
| `halt` | `main.asm` | `Sistema parado. Reinicie.` + `cli; hlt` |

## Stage 2

**Arquivos:** `main.asm`, `console.asm`, `disk.asm`, `e820.asm`, `fat.asm`, `config.asm`, `32bit.asm`.

```asm
org 0x7e00
bits 16
%define INITRD_LOC 0x50000
%define KERNEL_LOC 0x10000
```

### Fluxo de `main`

1. `cli`, segmentos 0, `SP=0x7C00`, `sti`.
2. `check_286` / `check_386`: garante CPU 386+; caso contrário imprime `Erro: a CPU precisa ser 386+` e para.
3. `disk_init`: exige extensões INT 13h (EDD) via `AH=41h`, `BX=0x55AA`.
4. Imprime `<NAME> bootloader v<VERSION>` (macros passadas pelo Makefile).
5. `fat_init`: lê a BPB e detecta FAT12/FAT16.
6. `read_file` para `KERNEL  SYS` → `0x10000`.
7. `read_file` para `INITRD     ` → `0x50000`.
8. `e820_init`: monta o mapa de memória em `0x500`.
9. `jmp _to32bit`.

### Detecção da CPU

- **`check_286`**: empilha flags, tenta zerar os bits 12–15 com `popf`, lê de volta; se não zeram, é 8086/186.
- **`check_386`**: tenta ligar os bits 12–14; só 386+ permite isso em modo real. Em 286, cai em `halt` (correção registrada na v0.20.1).

### Módulos e funções

| Módulo | Símbolos | Finalidade |
|---|---|---|
| `console.asm` | `console_print_string`, `console_print_nibble`, `console_print_byte` | saída via BIOS teletype (os dois últimos não são usados) |
| `disk.asm` | `disk_init`, `disk_read_sector`, `DAP` | EDD, DAP de 16 bytes, `INT 13h AH=42h` com até 3 tentativas |
| `fat.asm` | `fat_init`, `fat12_next_cluster`, `fat16_next_cluster`, `fat_next_cluster`, `fat_read_root_dir`, `fat_find_in_root_dir`, `fat_cluster_to_lba`, `fat_cluster_is_eof`, `fat_read_file` | driver FAT |
| `e820.asm` | `e820_init` | `INT 15h, AX=0xE820`, `EDX='SMAP'`, 24 bytes por entrada |
| `32bit.asm` | `_to32bit`, `_32bit_entry`, `pd`, `pt` | A20, GDT, modo protegido, paginação |
| `config.asm` | `gdt_entry`, `gdt`, `gdtr`, `KERNEL_LOAD_ADDRESS` | GDT de 3 entradas e constantes |
| `main.asm` | `read_file`, `fat_error`, `mem_error`, `halt`, `zero_entry` | orquestração e mensagens |

## Driver FAT

### BPB e geometria da imagem padrão

`fat_init()` lê o LBA 0 em `0x0500:0000`, copia 36 bytes da BPB e calcula:

| Grandeza | Fórmula | Valor típico (1,44 MiB) |
|---|---|---:|
| Bytes por setor | BPB | 512 |
| Setores por FAT | BPB | 9 |
| Setores do root dir | `((entradas*32)+511)/512` | 14 (224 entradas) |
| Primeiro setor de dados | `reservados + 2*FAT + root` | `64 + 18 + 14 = 96` |
| Primeiro setor do root | `dados - root` | 82 |
| Setores de dados | `total - (reservados + 2*FAT + root)` | `2880 - 96 = 2784` |
| Tipo | `< 4085` → FAT12, `< 65525` → FAT16 | FAT12 |

A imagem é FAT12 (`mkfs.fat -F 12 -n SEDGE -R 64`), com 64 setores reservados: LBA 0 para o stage1, LBA 1–62 para o stage2 e LBA 63 livre.

### Cadeia de clusters e busca

- **FAT12:** `fat_offset = cluster + cluster/2`; lê 2 setores consecutivos para cobrir entradas que cruzam fronteira; clusters ímpares usam `>> 4`, pares usam `& 0x0FFF`.
- **FAT16:** `fat_offset = cluster*2`; lê apenas 1 setor (há bug de borda quando a palavra cruza o fim do setor).
- **Cluster → LBA:** `(cluster - 2) * sectors_per_cluster + first_data_sector`.
- **EOF:** FAT12 `>= 0x0FF8`, FAT16 `>= 0xFFF8`.
- **Root dir:** `fat_find_in_root_dir()` percorre as 224 entradas de 32 bytes, pula entradas `0xE5` (apagadas), para em `0x00` e compara os 11 bytes do nome 8.3. Apenas `KERNEL  SYS` e `INITRD     ` são procurados — **sem subdiretórios**.
- **`fat_read_file()`:** rejeita tamanho zero, exige `cluster >= 2` e `destino + file_size < 0x90000`; percorre a cadeia lendo clusters completos.

## Transição para modo protegido e paginação

Implementada em `32bit.asm`:

1. `cli`.
2. **A20** via porta `0x92` (`in al,0x92; or al,2; out 0x92,al`), sem fallback pelo controlador de teclado.
3. **GDT** da `config.asm`: 3 entradas (nula, código `0x08` com `0x9A`, dados `0x10` com `0x92`), base 0, limite `0xFFFFF`, flags `0b1100`, `gdtr.limit = 23`; `lgdt`.
4. `CR0 |= PE`, salto far para `0x08:_32bit_entry`, segmentos `0x10`, `ESP=0x7C00`.
5. **Tabelas de paginação** dentro da própria imagem stage2 (`align 4096`):
   - `pt[i] = (i*0x1000) | 3` para `i = 0..255` → físico `0x00000000..0x000FFFFF`;
   - `PD[0] = pt | 3` (identidade);
   - `PD[768] = pt | 3` (alias higher-half `0xC0000000..0xC003FFFFF`);
   - `PD[1023] = pd | 3` (diretório recursivo em `0xFFC00000`);
   - `CR3 = pd`.
6. `CR0 |= PG`, `jmp 0xC0010000` (`= 0xC0000000 + 0x10000`).

O kernel depois substitui a GDT, zera `PD[0]` (removendo a identidade do primeiro MiB) e mantém o alias higher-half. Veja [arquitetura-i686.md](arquitetura-i686.md) e [memoria.md](memoria.md).

## Interface com o kernel

| Endereço físico | Endereço virtual no kernel | Conteúdo |
|---|---|---|
| `0x10000` | `0xC0010000` | kernel binário |
| `0x50000` | `0xC0050000` | initrd |
| `0x500` | `0xC0000500` | contador E820 |
| `0x502` | `0xC0000502` | 24 bytes por entrada E820 |

**Nenhum parâmetro é passado por registrador.** `kmain()` é `void kmain(void)`; `entry.asm` ignora registradores. `DL` (drive) é usado somente pelo bootloader. Os endereços `/init.sys` e `0xC0050000` são constantes no kernel.

## Mapa de memória e limites

| Endereço | Uso | Limite |
|---|---|---|
| `0x0500` | buffer FAT temporário / E820 | — |
| `0x7C00` | setor de boot e pilha | cresce para baixo |
| `0x7E00` | stage2 | 62 setores (`0x7C00` bytes) |
| `0x10000` | kernel | `< 0x80000` (512 KiB) |
| `0x50000` | initrd | `< 0x40000` (256 KiB) |
| `0x90000` | limite superior de carregamento | `fat_read_file` rejeita `destino+tamanho >= 0x90000` |

## Limitações conhecidas

1. O stage1 lê **exatamente** 62 setores: se `stage2.bin` ultrapassar 31.744 bytes, passará a ler a FAT.
2. `fat_find_in_root_dir()` faz `stc` e depois cai em `.end: clc`, retornando `CF=0` mesmo em erro.
3. `fat_read_file()` lê clusters inteiros e ignora `file_size` no último cluster; pode carregar lixo após o EOF.
4. Arquivos vazios são erro; o limite usa `file_size`, não o tamanho arredondado para cluster.
5. FAT16 tem bug de borda em `fat16_next_cluster()` (palavra que cruza setor) — não afeta a imagem FAT12 atual.
6. A20 usa apenas a porta `0x92`, sem verificação ou fallback.
7. `console_print_nibble/byte` chamam `INT 14h, AH=01h` e não são usadas; `config_invalid_size_message` e `KERNEL_LOAD_ADDRESS` são resquícios.
8. Não há configuração lida pelo bootloader apesar do nome `config.asm` — ele contém apenas a GDT e constantes.

## Ver também

- [Build: como o bootloader é montado e injetado](build.md#montagem-da-imagem-fat12)
- [Kernel: entrada e linker script](arquitetura-i686.md#entrada-do-kernel-e-linker-script)
- [Initrd: formato da imagem](initrd.md)
- [Estado atual](estado-atual.md)
