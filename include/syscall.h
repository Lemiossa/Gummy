#ifndef SYSCALL_H
#define SYSCALL_H
#include <types.h>

enum {
	SYS_EXIT = 0,
	SYS_GETPID = 1,
};

// Syscall de exit
void sys_exit(int status) {
	__asm__ volatile("int $0x80" : : "a"(0), "b"((uint32_t)status));
}

// Syscall de getpid
uint32_t sys_getpid(void) {
	uint32_t pid = 0;
	__asm__ volatile("int $0x80" : "=b"(pid) : "a"(1));
	return pid;
}

#endif // SYSCALL_H
