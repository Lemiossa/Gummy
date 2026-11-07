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
	SYS_SEND,
	SYS_RECEIVE,
	SYS_MAP,
	SYS_UNMAP,
};

#ifdef KERNEL
void syscall_init(void);
#endif

#define IPC_QUEUE_SIZE 16
#define IPC_MSG_MAX 64

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
SYSCALL_INLINE void sys_yield(void) { __asm__ volatile("int $0x81" : :); }

// Syscall de send
SYSCALL_INLINE int sys_send(uint32_t pid, uint32_t type, const void *data,
							size_t size) {
	int ret;

	__asm__ volatile("int $0x80"
					 : "=a"(ret)
					 : "a"(SYS_SEND), "b"(pid), "c"(type), "S"(data), "d"(size)
					 : "memory");

	return ret;
}

// Syscall de receive
SYSCALL_INLINE int sys_receive(uint32_t *sender_pid, void *buffer,
							   size_t size) {
	int ret;

	__asm__ volatile(

		"int $0x80"
		: "=a"(ret)
		: "a"(SYS_RECEIVE), "b"(size), "S"(sender_pid), "D"(buffer)
		: "memory");

	return ret;
}

// Syscall de map
SYSCALL_INLINE int sys_map(uintptr_t phys, uintptr_t virt, uint32_t pages,
						   uint32_t flags) {
	int ret;

	__asm__ volatile("int $0x80"
					 : "=a"(ret)
					 : "a"(SYS_MAP), "S"(phys), "D"(virt), "b"(pages),
					   "d"(flags)
					 : "memory");

	return ret;
}

// Syscall do unmap
SYSCALL_INLINE void sys_unmap(uintptr_t virt, uint32_t pages) {
	__asm__ volatile("int $0x80"
					 :
					 : "a"(SYS_UNMAP), "D"(virt), "b"(pages)
					 : "memory");
}

#endif // SYSCALL_H
