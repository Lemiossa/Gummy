#ifndef TYPES_H
#define TYPES_H

typedef unsigned char uint8_t;
typedef char int8_t;
typedef unsigned short uint16_t;
typedef short int16_t;
typedef unsigned int uint32_t;
typedef int int32_t;
typedef unsigned long long uint64_t;
typedef long long int64_t;

typedef int32_t pid_t;

#define UINT8_MAX 0xFF
#define UINT16_MAX 0xFFFF
#define UINT32_MAX 0xFFFFFFFF
#define UINT64_MAX 0xFFFFFFFFFFFFFFFF

#define INT8_MAX 127
#define INT16_MAX 32767
#define INT32_MAX 2147483647
#define INT64_MAX 9223372036854775807LL

#define INT8_MIN (-128)
#define INT16_MIN (-32768)
#define INT32_MIN (-2147483647 - 1)
#define INT64_MIN (-9223372036854775807LL - 1)

#if defined(__x86_64__) || defined(__aarch64__)
typedef uint64_t uintptr_t;
typedef int64_t intptr_t;
typedef int64_t flags_t;

typedef uint64_t size_t;
typedef int64_t ssize_t;
#define SIZE_MAX UINT64_MAX
#define SSIZE_MAX INT64_MAX
#elif defined(__i386__) || defined(__arm__)
typedef uint32_t uintptr_t;
typedef int32_t intptr_t;
typedef uint32_t flags_t;

typedef uint32_t size_t;
typedef int32_t ssize_t;
#define SIZE_MAX UINT32_MAX
#define SSIZE_MAX INT32_MAX
#else
#error "Arquitetura nao suportada"
#endif

#define NULL ((void *)0)

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

#define OFFSETOF(type, member) ((size_t)&((type *)0)->member)

#define CONTAINER_OF(ptr, type, member)                                        \
	((type *)((char *)(ptr) - OFFSETOF(type, member)))

#define ALIGN_UP(x, a) (((x) + ((a) - 1)) & ~((a) - 1))
#define ALIGN_DOWN(x, a) ((x) & ~((a) - 1))

typedef __builtin_va_list va_list;
#define va_start(ap, last) __builtin_va_start(ap, last)
#define va_end(ap) __builtin_va_end(ap)
#define va_arg(ap, type) __builtin_va_arg(ap, type)
#define va_copy(d, s) __builtin_va_copy(d, s)

#endif // TYPES_H
