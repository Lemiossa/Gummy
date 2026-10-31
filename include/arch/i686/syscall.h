#ifndef SYSCALL_H
#define SYSCALL_H
#include <types.h>

enum {
	SYS_EXIT = 0,
	SYS_GETPID,
	SYS_GETPPID,
	SYS_NPROCESS,
	SYS_NTHREAD,
	SYS_SLEEP,
};

#ifdef KERNEL
void syscall_init(void);
#endif

#define SYSCALL_INLINE static inline __attribute__((always_inline))

// Syscall de exit
SYSCALL_INLINE void sys_exit(int status) {
	__asm__ volatile("int $0x80" : : "a"(SYS_EXIT), "b"((uint32_t)status));
}

// Syscall de getpid
SYSCALL_INLINE uint32_t sys_getpid(void) {
	uint32_t pid = 0;
	__asm__ volatile("int $0x80" : "=a"(pid) : "a"(SYS_GETPID));
	return pid;
}

// Syscall de getppid
SYSCALL_INLINE uint32_t sys_getppid(void) {
	uint32_t ppid = 0;
	__asm__ volatile("int $0x80" : "=a"(ppid) : "a"(SYS_GETPPID));
	return ppid;
}

// Syscall de sleep(ms)
SYSCALL_INLINE void sys_sleep(uint32_t ms) {
	__asm__ volatile("int $0x80" : : "a"(SYS_SLEEP), "b"(ms));
}

// Syscall de nthread
SYSCALL_INLINE int sys_nthread(void (*entry)(void)) {
	int eax = 0;
	__asm__ volatile("int $0x80"
					 : "=a"(eax)
					 : "a"(SYS_NTHREAD), "b"((uintptr_t)entry));
	return eax;
}

// Syscall de nprocess
SYSCALL_INLINE uint32_t sys_nprocess(const void *entry, uint32_t n) {
	uint32_t pid = 0;
	__asm__ volatile("int $0x80"
					 : "=a"(pid)
					 : "a"(SYS_NPROCESS), "b"((uint32_t)entry),
					   "c"((uint32_t)n));
	return pid;
}

// Cede a CPU
SYSCALL_INLINE void sys_yield(void) {
	__asm__ volatile("int $0x81" : : );
}


#endif // SYSCALL_H
