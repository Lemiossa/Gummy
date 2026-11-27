# Estado atual, pendências e histórico

> Este documento consolida o que **funciona**, o que está **incompleto** e os **problemas conhecidos** do código em `master` (v0.27.0). A referência oficial de versões é o [`CHANGELOG.md`](../CHANGELOG.md).

## Matriz de status

| Subsistema | Status | Observação |
|---|---|---|
| Bootloader 2 estágios + FAT12 | ✅ funcional | carrega kernel e initrd; sem subdiretórios |
| E820 + PMM | ✅ funcional | bitmap de páginas físicas |
| VMM | ✅ funcional | higher-half, recursivo, clone de CR3; sem COW/demand paging |
| Heap | ✅ funcional | first-fit, split e coalescência no free |
| GDT/IDT/TSS/exceções | ✅ funcional | user DPL 3, dump de 16 bytes em EIP |
| PIC/PIT/timer | ⚠️ parcial | só IRQ0; sem teclado |
| Escalonador | ⚠️ parcial | round-robin; limpeza de zombies e processos incompleta |
| Syscalls | ⚠️ parcial | 8 de 10 despachadas; sem validação de usuário |
| IPC | ⚠️ parcial | mailbox funcional; sem travamento e sem filtro de tipo |
| Initrd + `init` | ✅ funcional | `/init.sys` → PID 1, `SYS_EXIT(42)` |
| VFS | 🚧 em construção | camada de despacho com validação de callbacks e API de `stat`/`unmount`; nenhum FS montado |
| RAMFS | 🚧 esqueleto | em `kmain.c`, nunca inicializado |
| Saída VGA/serial | ✅ funcional | mensagens duplicadas, cor fixa |

## Pendências explícitas

[`TODO.md`](../TODO.md):

- [ ] `copy_from_user` e `copy_to_user`
- [ ] `is_in_user_range`
- [x] VFS básico (camada de despacho; sem filesystem funcional)
- [x] Colocar `handle_type_t type` em `stat_t`
- [ ] Fazer `vfs_check_fs()` não rejeitar filesystems sem todas as operações

> O item do `vfs_check_fs()` segue marcado como pendente em [`TODO.md`](../TODO.md), embora a validação já tenha sido flexibilizada para aceitar `fs_t` com callbacks parciais.

[`IDEAS.md`](../IDEAS.md) registra uma ideia para **spawn de processos**: uma thread do kernel criaria processos em uma lista. Hoje o spawn é feito por `sys_nprocess()` a partir do `kmain` (e, futuramente, por qualquer processo de usuário).

## Problemas conhecidos por subsistema

### Bootloader e build

| Problema | local |
|---|---|
| Stage1 lê exatamente 62 setores; crescimento do stage2 corrompe a FAT | `bootloader/stage1/src/main.asm` |
| `fat_find_in_root_dir()` retorna `CF=0` em erro (`stc` seguido de `clc`) | `bootloader/stage2/src/fat.asm` |
| `fat_read_file()` lê clusters completos e ignora `file_size` no último | idem |
| Bug de borda em FAT16 quando a entrada cruza o fim do setor | idem |
| A20 apenas pela porta `0x92`, sem fallback | `32bit.asm` |
| `INCLUDES` quebrado nos Makefiles de stage1/stage2 | `bootloader/*/Makefile` |
| `$(INIT)` indefinido no Makefile raiz; `DEPDIR` não usado | `Makefile` |
| `compile_commands.json` documentado, mas ausente e ignorado | `README.md`, `.gitignore` |
| README desatualizado (nome da imagem e "FAT16") | `README.md`, `CHANGELOG.md` |

### Memória

| Problema | local |
|---|---|
| `pmm_alloc_page()` usa `0` como falha; `pmm_free_page()` não valida argumento | `pmm.c` |
| `bitmap_find_free_bit()` ambíguo (0 = livre ou "nenhum"); sem checagem de limites | `bitmap.h` |
| `vmm_clone()` não copia páginas de usuário; sem COW | `vmm.c` |
| `vmm_destroy()` não libera a página do diretório (feita pelo chamador) | `vmm.c`, `process.c` |
| Heap sem `magic`: double-free e ponteiro interior não detectados | `heap.c` |
| `heap_expand()` não divide o bloco novo (fragmentação interna) | `heap.c` |
| Alinhamento do heap de apenas 4 bytes em i386 | `heap.c` |

### Interrupções, escalonador e syscalls

| Problema | local |
|---|---|
| IRQ1 (teclado) mascarada e sem handler; demais IRQs sem uso | `pic.c`, `sched.c` |
| `pit_set_frequency()` desmascara IRQ0 duas vezes; divisor truncado | `pit.c` |
| `ms_per_tick == 0` para frequências > 1000 Hz | `sched.c` |
| `zombie_queue` nunca é drenada; `exit_code` nunca lido | `thread.c`, `sched.c` |
| Processos com threads que só chamam `SYS_EXIT` não viram `PROCESS_DYING` → vazamento de CR3 | `thread.c`, `sched.c` |
| Slots com falha na criação ficam `THREAD_RUNNING` em vez de `THREAD_FREE` | `thread.c` |
| `schedule()` pode deixar a thread atual fora das filas; sem fallback idle | `sched.c` |
| `tss.esp0` aponta para o topo da pilha: interrupções aninhadas sobrescrevem o frame | `sched.c` |
| `write_cr3()` incondicional em cada troca | `sched.c` |
| `queue_remove(NULL)` desreferencia antes do teste | `lib/src/queue.c` |
| `sys_map`/`sys_unmap` não despachados (`default: ret = -1`) | `syscall.c` |
| Sem validação de ponteiros de usuário | `syscall.c`, `TODO.md` |

### IPC, VFS e RAMFS

| Problema | local |
|---|---|
| Ring buffer e fila `waiters` sem spinlock/`cli` | `ipc.c` |
| Race após o wake: mensagem pode ter sido consumida por outra thread | `ipc.c` |
| `ipc_receive()` descarta `type` e trunca silenciosamente mensagens grandes | `ipc.c` |
| Apenas um waiter acordado por mensagem | `ipc.c` |
| `vfs_create()` valida `ops->write` em vez de `ops->create` | `vfs.c` |
| `vfs_unmount()` não trunca o nome no `':'` e não libera o slot do volume | `vfs.c` |
| `vfs_open()` não verifica `h` antes de `h->vol = vol` | `vfs.c` |
| Sem syscalls de VFS; `vfs_stat()`/`vfs_unmount()` só são chamáveis pelo kernel | `vfs.h`, `vfs.c` |
| Nenhum FS registrado/montado; RAMFS inalcançável e incompleto | `kmain.c` |
| `ramfs_init()` não atribui `fs->ops = ops`; `ramfs_open()` não retorna | `kmain.c` |

### Initrd e biblioteca

| Problema | local |
|---|---|
| `initrd_check()` valida só ponteiros e magic; offsets/tamanhos não conferidos | `lib/src/initrd.c` |
| `initrd_find_entry()` O(n²) e exige `name_size` exato | `lib/src/initrd.c` |
| `.bss` do `init` não é zerada no startup | `initrd/init/src/arch/i686/entry.asm` |
| `strncpy()` não garante NUL quando `strlen(src) >= n` | `lib/src/string.c` |
| `vsnprintf()` ignora precisão e várias flags; `printk` trunca em 255 bytes | `vsnprintf.c`, `debug.c` |
| `debug_log_string()` declarada, nunca implementada | `debug.h` |
| Terminal/VGA sem checagem de limites e cor fixa `0x07` | `vga.c`, `terminal.c` |

## Histórico de versões (resumo)

O [`CHANGELOG.md`](../CHANGELOG.md) registra todas as versões de `v0.1.0` (27/07/2026) a `v0.27.0` (27/11/2026). Marcos principais:

| Versão | Data | Marco |
|---|---|---|
| v0.1.0 | 27/07/2026 | bootloader 2 estágios, FAT, kernel i686 inicial |
| v0.3.0 | 21/08/2026 | E820, PIC remapeado, compilador cruzado |
| v0.4.0 | 22/08/2026 | PMM com bitmap |
| v0.8.0–v0.9.0 | set/2026 | VMM `vmm_clone`, heap, PIT |
| v0.14.0 | 03/10/2026 | multitarefa inicial com TSS e filas |
| v0.15.2 | 25/10/2026 | serial/debug, IDT, page fault, escalonador reescrito |
| v0.17.0 | 27/10/2026 | `int 0x80`, espaço de usuário, programa `init` |
| v0.18.0–v0.19.0 | 31/10/2026 | estados de thread, sleep, syscalls, IPC mailbox |
| v0.20.0–v0.21.0 | nov/2026 | checagem 386+, exceções em usuário, `-O2` |
| v0.22.0–v0.23.3 | nov/2026 | `printk`, spinlocks, initrd, reestruturação do escalonador |
| v0.24.0–v0.27.0 | nov/2026 | VFS: registro, mount, handles, validação de callbacks, `stat`/`unmount` e RAMFS em andamento |

## Convenções para contribuição

- Código e documentação em **português** desde 22/10/2026; nomes de funções e variáveis permanecem em inglês.
- Estilo K&R (chaves na mesma linha), indentação com tabs, includes ordenados alfabeticamente (v0.16.0).
- Ao adicionar um arquivo-fonte a uma lista `SRC`, atualizar também o `compile_commands.json` manual ([build.md](build.md#suporte-a-editores)).
- Ao alterar o comportamento do kernel, atualizar o `CHANGELOG.md` e esta documentação.
- Alterações em componentes críticos devem registrar a justificativa técnica exigida por [`RULES.md`](../RULES.md); exemplo em [vfs.md](vfs.md#justificativa-das-alterações-no-vfs).

## Ver também

- [Visão geral](visao-geral.md)
- [Documentação individual de cada subsistema](README.md)
- [`TODO.md`](../TODO.md) · [`IDEAS.md`](../IDEAS.md) · [`CHANGELOG.md`](../CHANGELOG.md)
