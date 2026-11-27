# Glossário

Termos usados na documentação e no código do Sedge.

| Termo | Significado |
|---|---|
| **A20** | Linha de endereço 20 do 8086; habilitada via porta `0x92` para acessar memória acima de 1 MiB no modo real |
| **ALIGN_UP / ALIGN_DOWN** | Macros de `types.h` que arredondam um valor para cima/baixo; o alinhamento deve ser potência de 2 |
| **BPB** | *BIOS Parameter Block*, campos da BPB FAT lidos pelo stage2 para calcular FATs, root dir e área de dados |
| **Bootloader de 2 estágios** | stage1 (setor de boot, CHS) carrega o stage2 (EDD, FAT, modo protegido) |
| **Buffer de texto VGA** | 80×25 células de 2 bytes em `0xB8000` (virtual `0xC00B8000`); cada célula tem caractere + atributo |
| **CAP** | Capacidade (`cap.h`); tipo de permissão (memória/porta de E/S) declarada, ainda não usada |
| **CHS / LBA** | Cilindro-Cabeça-Setor (INT 13h AH=02h) / endereçamento linear de setor (INT 13h AH=42h) |
| **Coalescência** | fusão de blocos livres adjacentes no heap (`heap_merge_free_blocks`) |
| **COM1** | Porta serial `0x3F8`, usada a 9600 baud para a saída de depuração |
| **CR0.PE / CR0.PG** | bits de modo protegido e paginação; ativados pelo stage2 antes do kernel |
| **CR2** | registrador que contém o endereço virtual que causou um page fault |
| **CR3** | registrador de diretório de páginas; cada processo possui o seu |
| **DAP** | *Disk Address Packet*, estrutura de 16 bytes para leitura LBA via INT 13h extensões |
| **DPL** | *Descriptor Privilege Level*; bits 5–6 da entrada da IDT/GDT. DPL 3 permite chamadas do anel 3 |
| **E820** | chamada BIOS `INT 15h, AX=0xE820` que devolve o mapa de memória física |
| **EDD** | *Enhanced Disk Drive* extensions (INT 13h AH=41h/42h) exigidas pelo stage2 |
| **EOI** | *End of Interrupt*: byte `0x20` enviado ao PIC para liberar a interrupção |
| **FAT12** | filesystem da imagem de 1,44 MiB: 12 bits por entrada da FAT; 2784 clusters |
| **First-fit** | estratégia do heap que escolhe o primeiro bloco livre com espaço suficiente |
| **Flags** | registrador EFLAGS; `read_flags()`/`write_flags()` salvam/restauram o bit IF ao desligar interrupções |
| **Frame sintético** | `interrupt_context_t` montado na criação da thread para que o `iret` a inicie em `eip` com o CPL desejado |
| **GDTR / IDTR** | registradores que apontam para a GDT/IDT (`lgdt`/`lidt`) |
| **GDT** | *Global Descriptor Table*: segmentos de código/dados kernel (0x08/0x10), usuário (0x1B/0x23) e TSS (0x28) |
| **Guard page** | página de 4 KiB não mapeada entre as pilhas de usuário (passo de `0x11000` = 64 KiB + 4 KiB) |
| **Handler** | função registrada em uma entrada da IDT (`handlers[n]`) |
| **Heap** | região virtual em `0xE0000000` gerenciada por lista dupla de blocos (`heap.c`) |
| **Higher-half** | mapeamento do kernel em `0xC0000000+` com offset fixo em relação ao físico |
| **IDT** | *Interrupt Descriptor Table*: 256 entradas com stubs assembly e gates DPL 0/3 |
| **Initrd** | imagem em `0x50000` com `/init.sys`, lida pelo kernel em `0xC0050000` |
| **IRQ** | *Interrupt Request*: IRQ0 (PIT) mapeada para o vetor 0x20; IRQ1 (teclado) para 0x21 |
| **isr_common / _restore_context** | prólogo/epílogo assembly que monta e desmonta o `interrupt_context_t` |
| **Mailbox** | estrutura por processo com ring buffer de 16 mensagens e fila de threads esperando ([ipc.md](ipc.md)) |
| **PDE / PTE / PT** | entradas do diretório de páginas / da tabela de páginas / própria tabela |
| **PIC** | *Programmable Interrupt Controller*: dois 8259A cascateados, remapeados para 0x20–0x2F |
| **PIT** | *Programmable Interval Timer*: canal 0 a 100 Hz gera o tick do escalonador |
| **PMM / VMM** | gerenciador de memória física (bitmap) / virtual (paginação) |
| **Processo idle** | PID 0, CR3 do kernel, `threads[0]` sem pilha própria; hospeda a thread reaper |
| **Reaper** | thread kernel do PID 0 que acorda a cada 5 s e destrói processos `PROCESS_DYING` |
| **Ring 0 / Ring 3** | níveis de privilégio: kernel / usuário |
| **Ring buffer** | estrutura circular com `head`, `tail` e `count` usada pelo IPC ([biblioteca.md](biblioteca.md)) |
| **Root dir** | diretório raiz da FAT (224 entradas de 32 bytes), onde o stage2 procura `KERNEL.SYS` e `INITRD` |
| **Spinlock** | travamento de curta duração baseado em `__sync_lock_test_and_set` e `pause` |
| **Split block** | divisão de um bloco livre do heap quando sobra espaço suficiente (≥ 32 bytes) |
| **Syscall** | chamada de sistema via `int $0x80`; `EAX` contém o número e o retorno |
| **TSS** | *Task State Segment*: estrutura de 104 bytes na GDT (0x28) com `esp0/ss0` para troca de pilha |
| **wake_tick** | valor de `ticks` em que uma thread dormindo deve ser acordada |
| **Yield** | cedência voluntária da CPU via `int $0x81` → `schedule()` |

## Ver também

- [Índice da documentação](README.md)
- [Visão geral](visao-geral.md)
- [Código-fonte](../kernel/src/)
