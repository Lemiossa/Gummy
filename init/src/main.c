/*
 * main.c
 * Criado por Matheus Leme da Silva
 * */
#include <syscall.h>
#include <types.h>

void proc(void)
{
	while (1)
	{
		sys_sleep(1000);
	}
	sys_exit(0);
}

int main(void) {
	sys_nprocess(proc, 512);
	return 42;
}
