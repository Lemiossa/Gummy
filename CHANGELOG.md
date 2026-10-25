# Changelog

Todas as mudanças notáveis do Gummy são documentadas aqui. As entradas seguem as tags do Git em ordem cronológica.

## v0.15.1 — 2026-10-25

- **Fila**: nó da fila agora armazena ponteiro para a fila (`queue_node_t.q`); `queue_remove()` passa a receber apenas o nó e atualiza o contador da fila.

## v0.15.2 — 2026-10-25

- **IDT/Tratamento de interrupções**: novos tratadores e ajustes em `idt.asm`/`idt.h`; adicionado suporte a chamadas de sistema via interrupção (estrutura para `syscall`).
- **I/O**: adicionado `io.h` com funções para ler/escrever portas (in/out) em assembly.
- **VMM**: adicionado mapeamento de heap do kernel, melhorias em mapeamento/unmapeamento e tratamento de page fault mais completo.
- **Heap**: pequenos ajustes.
- **Escalonador**: reescrita significativa do escalonador com tarefas/threads, filas, troca de contexto aprimorada e suporte a syscall; `kmain` atualizado para inicializar multitarefa.

## v0.15.3 — 2026-10-25

- **README**: adicionado aviso sobre tradução assistida por IA e indicação de mudança para português a partir de 22/10/2026.


## v0.1.0 — 2026-07-27

Primeira versão. Base funcional do sistema:

- **Bootloader em dois estágios** (stage1/stage2) em assembly: setor de boot com leituras de disco via INT 13h, e stage2 com driver de disco, console próprio e um driver FAT completo (leitura da tabela FAT, diretórios, `fat_read_file`).
- **Carregamento do kernel**: o stage2 detecta o tipo de FAT, carrega a imagem do kernel e salta para ela.
- **Kernel i686 inicial**: GDT recarregada, BSS zerada, driver de terminal em modo texto VGA.
- **Sistema de build com GNU Make**: imagem FAT16 gerada automaticamente, alvo QEMU e modo silencioso.

## v0.2.0 — 2026-08-04

- Kernel: entrada em assembly organizada (flag de direção limpa, BSS zerada), correção da nomenclatura da GDT e sintaxe em minúsculas.
- Kernel: IDT adicionada com tratadores básicos de exceções.

## v0.3.0 — 2026-08-21

- Kernel: análise do mapa de memória E820 coletado pelo bootloader e impressão da memória total.
- Kernel: PIC remapeado para os vetores corretos (0x20+).
- Build: kernel compilado com o compilador cruzado GCC i686-elf; nomes de imagem versionados (macros `NAME`/`VERSION`); `source/` renomeado para `src/`.

## v0.4.0 — 2026-08-22

- **PMM (Gerenciador de Memória Física)**: alocação de páginas físicas baseada em um bitmap construído a partir do mapa E820.
- `types.h`: adicionadas as macros `ALIGN_UP`/`ALIGN_DOWN`.
- README: guia de compilação do compilador cruzado.

## v0.5.1 — 2026-08-26

- Adicionado `bitmap_find_free_bit`; o PMM agora usa busca por bit livre para a alocação de páginas.
- Base do VMM: estruturas iniciais e diretório de páginas (`vmm.c`), iniciando o suporte a kernel em higher-half.

## v0.5.2 — 2026-08-26

- Melhorias no PMM (inicialização de bitmap mais robusta) e avanços no VMM.

## v0.5.3 — 2026-08-26

- VMM mais completo: `vmm_map`/`vmm_unmap`, mapeamento de páginas com flags.

## v0.5.4 — 2026-08-29

- **Reescrita do tratamento de interrupções**: novo modelo de IDT com `exception.c`, tratadores centralizados e correções de I/O (retorno de carro nas mensagens de erro).
- `SOURCE` renomeado para `SRC` nos Makefiles.

## v0.5.5 — 2026-08-29

- Correção da formatação (`\r`) nas mensagens de `exception_handler`.

## v0.5.6 — 2026-08-29

- VMM: desmapeado o primeiro MiB de memória (área de memória baixa liberada).

## v0.5.7 — 2026-08-29

- VMM tornado mais genérico (assinaturas e flags unificadas).

## v0.5.8 — 2026-08-29

- Renomeação de tipos para consistência (`u8`/`u16`/`u32`…) em todo o kernel.

## v0.6.0 — 2026-08-29

- **Timer (PIT)**: driver do PIT e contador de ticks; tratador de page fault registrado (inicialmente apenas registrado em log).

## v0.6.1 — 2026-08-29

- Correção do timer: enviar EOI ao PIC a cada tick.

## v0.6.2 — 2026-08-29

- Corrigido page fault ao desmapear o primeiro MiB; VMM reorganizado (mais auxiliares, menos mensagens).

## v0.6.3 — 2026-08-30

- Removidas as mensagens de depuração do PMM/VMM.

## v0.7.0 — 2026-09-01

- VMM: adicionados `vmm_alloc_pages` e `vmm_free_pages` (alocação contígua de páginas virtuais).

## v0.8.0 — 2026-09-14

- VMM: adicionado `vmm_clone()` (clonagem de espaço de endereçamento).

## v0.8.1 — 2026-09-18

- Base do escalonador: `timer.c` transformado em `sched.c` com contadores/base de escalonamento.

## v0.9.0 — 2026-09-22

- **Heap do kernel** (`heap.c`) com alocador próprio.
- Revisão importante do PMM/VMM: limpeza do e820, tipos revisados, `vmm.h`/`pmm.h` ajustados.
- Suporte a depuração com GDB (Makefile + README).

## v0.9.1 — 2026-09-24

- Removida a mensagem de inicialização do PMM; `kmain` simplificado.

## v0.9.2 — 2026-09-25

- Corrigida a rolagem do terminal de texto.

## v0.10.0 — 2026-09-24

- Heap: divisão e fusão (coalescência) de blocos na liberação. *(marcado depois, mas historicamente pertence aqui)*

## v0.10.1 — 2026-09-25

- Corrigidas as declarações (protótipos) em `pmm.h`/`vmm.h`.

## v0.11.0 — 2026-09-25

- **Serial (COM)**: funções básicas de escrita serial e módulo `debug.c`; `kmain` e terminal ajustados para usar a serial como saída de depuração.

## v0.11.1 — 2026-09-25

- Adicionados logs em todos os subsistemas (e820, exceções, GDT/IDT, PMM, VMM, heap, PIC, PIT).

## v0.11.2 — 2026-09-26

- Mais logs no PMM e no VMM.

## v0.12.0 — 2026-09-26

- **Escalonador experimental**: estruturas de tarefas e base da troca de contexto iniciadas, ganchos na IDT/timer.

## v0.12.1 — 2026-09-30

- Escalonador simplificado/removido temporariamente ("retornando à simplicidade").

## v0.13.0 — 2026-10-01

- Build com mensagens de compilação detalhadas; novo diretório `lib/` com `string.c` junto ao kernel.

## v0.13.1 — 2026-10-02

- Mais logs em `heap.c`.

## v0.14.0 — 2026-10-03

- **Multitarefa inicial!**
  - TSS (Task State Segment) configurado na GDT com suporte a troca de pilha.
  - Fila (`queue.h`/`queue.c` em `lib/`) para estados de tarefa.
  - Escalonador reescrito com filas de prontos; tarefas com contexto próprio.

## v0.14.1 — 2026-10-12

Alterados alguns nomes em sched.*.

## v0.15.0 — 2026-10-22

- **Troca de contexto consolidada**: o escalonador salva o contexto atual diretamente em `current_thread->sp`, muda para o espaço de endereçamento do processo alvo (`write_cr3`) e atualiza `esp0`/`ss0` da TSS a cada troca (exceto para a thread idle).
- `thread` agora rastreia tanto a base da pilha quanto o ponteiro de pilha (`stack`/`sp` e `stack0`/`sp0`).
- TSS: `tss_flush()` agora recebe o seletor como argumento em vez de fixar `0x28`; adicionado `tss_set_sp0()`.
- Fila: contador interno `size` e novo `queue_size()`.
- API do escalonador: `sched_create_process()` não recebe mais `is_kernel`; `sched_create_thread()` declarada; o processo idle não aloca mais uma pilha de kernel separada.
- Build: `mkfs.fat` não usa mais `--mbr=y`, deixando o setor de boot para o bootloader do próprio projeto.
- README: seção sobre suporte a editores e o `compile_commands.json` mantido manualmente.

---

Nota: `v0.9.2` foi marcado fora de ordem (depois de `v0.11.0`), mas no histórico do Git ele fica entre `v0.9.1` e `v0.10.0` — este changelog segue a ordem do histórico.
