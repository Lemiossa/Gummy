# Documentação do Sedge

Documentação técnica completa do sistema operacional **Sedge** (v0.26.2, i686). Os documentos descrevem o estado atual do código — inclusive partes incompletas e bugs conhecidos — e usam português, com nomes de funções/variáveis mantidos em inglês conforme a convenção do projeto.

## Índice

### Comece aqui

1. [Visão geral](visao-geral.md) — arquitetura, mapa de memória, componentes e fluxo de boot
2. [Kernel: estrutura e inicialização](kernel.md) — sequência exata de `kmain()`
3. [Estado atual e pendências](estado-atual.md) — o que funciona, o que falta, bugs e histórico

### Boot e build

- [Bootloader](bootloader.md) — stage1/stage2, FAT12, E820, transição para 32 bits
- [Build, execução e depuração](build.md) — Makefiles, imagem FAT12, QEMU/GDB
- [Initrd](initrd.md) — formato da imagem e programa `init`

### Kernel e arquitetura

- [Camada i686](arquitetura-i686.md) — entry, linker script, GDT, TSS, IDT e exceções
- [Interrupções, PIC e PIT](interrupcoes.md) — IRQs, timer e tratadores
- [Memória: PMM, VMM e heap](memoria.md) — bitmap, paginação, first-fit
- [Escalonador, processos e threads](escalonador.md) — round-robin, CR3, pilhas, reaper
- [Syscalls](syscalls.md) — `int 0x80`, convenção de registradores

### Serviços e suporte

- [IPC](ipc.md) — mailboxes, ring buffer, bloqueio
- [VFS](vfs.md) — volumes, handles, callbacks e RAMFS em andamento
- [Biblioteca comum e tipos](biblioteca.md) — bitmap, queue, string, `vsnprintf`
- [Saída de texto e depuração](saida-e-debug.md) — `printk`, VGA e serial
- [Glossário](glossario.md) — termos e conceitos

## Convenções dos documentos

- Caminhos relativos apontam para a raiz do repositório (por exemplo, [`kernel/src/kmain.c`](../kernel/src/kmain.c)).
- Endereços são hexadecimais; quando há alias, a forma física e a virtual são apresentadas lado a lado (ex.: `0x10000` ↔ `0xC0010000`).
- Blocos `c`/`asm` reproduzem assinaturas e estruturas **exatamente como estão no código**.
- Diagramas usam Mermaid e podem ser renderizados no GitHub ou em editores compatíveis.
- "`🚧`" indica código inacabado; "`⚠️`" indica código funcional com limitações relevantes.
- A versão de referência é a do `Makefile` raiz; o histórico detalhado está em [`CHANGELOG.md`](../CHANGELOG.md).

## Mapa rápido de um subsistema para o documento

| O que procurar | Onde estar |
|---|---|
| "Por onde começa o boot?" | [visão geral](visao-geral.md), [bootloader](bootloader.md), [kernel](kernel.md) |
| "Como a memória é organizada?" | [memoria.md](memoria.md), [visão geral](visao-geral.md#mapa-de-memória) |
| "Como uma syscall chega ao kernel?" | [syscalls.md](syscalls.md), [arquitetura-i686.md](arquitetura-i686.md#idt-e-tratadores) |
| "Como uma thread é escalonada?" | [escalonador.md](escalonador.md), [interrupcoes.md](interrupcoes.md) |
| "Como os processos conversam?" | [ipc.md](ipc.md) |
| "Como compilo e executo?" | [build.md](build.md), [`README.md`](../README.md) |
| "O que ainda não funciona?" | [estado-atual.md](estado-atual.md) |

## Índice de arquivos-fonte

| Arquivos | Documento principal |
|---|---|
| `Makefile`, `kernel/Makefile`, `lib/Makefile`, `bootloader/Makefile`, `initrd/Makefile`, `initrd/init/Makefile` | [build.md](build.md) |
| `bootloader/stage1/src/{main,console,disk}.asm`, `bootloader/stage2/src/{main,console,disk,e820,fat,32bit,config}.asm` | [bootloader.md](bootloader.md) |
| `include/types.h`, `include/{bitmap,queue,ring_buffer,spinlock,string,vsnprintf,initrd}.h`, `lib/src/*.c` | [biblioteca.md](biblioteca.md) |
| `include/initrd.h`, `initrd/make-initrd`, `initrd/init/src/**` | [initrd.md](initrd.md) |
| `include/arch/i686/syscall.h`, `kernel/src/arch/i686/syscall.c` | [syscalls.md](syscalls.md) |
| `kernel/src/kmain.c`, `kernel/src/vfs.c`, `kernel/include/vfs.h` | [kernel.md](kernel.md), [vfs.md](vfs.md) |
| `kernel/src/arch/i686/{entry.asm,link.ld,e820.*,gdt.*,idt.*,exception.*,io.*,tss.*}` | [arquitetura-i686.md](arquitetura-i686.md) |
| `kernel/src/arch/i686/{pmm.*,vmm.*}`, `kernel/include/arch/i686/{pmm,vmm,e820}.h`, `kernel/src/heap.c` | [memoria.md](memoria.md) |
| `kernel/src/{pic,pit}.c`, `kernel/include/{pic,pit}.h` | [interrupcoes.md](interrupcoes.md) |
| `kernel/src/{debug,serial,terminal,vga}.c`, `kernel/include/{debug,serial,terminal,vga,utils}.h` | [saida-e-debug.md](saida-e-debug.md) |
| `kernel/src/ipc.c`, `kernel/include/ipc.h` | [ipc.md](ipc.md) |
| `kernel/src/sched/*.c`, `kernel/include/sched/*.h` | [escalonador.md](escalonador.md) |

## Documentos de referência do repositório

- [`README.md`](../README.md) — visão introdutória e instruções de compilação
- [`CHANGELOG.md`](../CHANGELOG.md) — todas as versões, da v0.26.2 à v0.1.0
- [`TODO.md`](../TODO.md) — pendências
- [`IDEAS.md`](../IDEAS.md) — ideias de evolução
- [`LICENSE`](../LICENSE) — MIT
