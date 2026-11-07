#ifndef SCHED_H
#define SCHED_H

#include <idt.h>
#include <ipc.h>
#include <pmm.h>
#include <queue.h>
#include <types.h>

// Inicializa o escalonador com a frequencia informada em Hz
// Retorna !0 se ocorrer um erro
int sched_init(uint16_t frequency);
// Retorna os ticks do escalonador
uint32_t sched_get_ticks(void);
// Retorna o número de milisegundos por tick
uint32_t sched_get_ms_per_tick(void);

#endif // SCHED_H
