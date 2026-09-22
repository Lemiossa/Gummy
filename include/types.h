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

typedef uint32_t size_t;
typedef int32_t ssize_t;

#if defined(__x86_64__) || defined(__aarch64__)
    typedef unsigned long long uintptr_t;
    typedef long long intptr_t;
#elif defined(__i386__) || defined(__arm__)
    typedef unsigned int uintptr_t;
    typedef int intptr_t;
#else
    #error "Unsupported architecture"
#endif

#define NULL ((void *)0)

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

#define ALIGN_UP(x, a) (((x) + ((a)-1)) & ~((a)-1))
#define ALIGN_DOWN(x, a) ((x) & ~((a)-1))

#endif // TYPES_H
