#ifndef CAP_H
#define CAP_H
#include <types.h>

typedef enum {
	CAP_MEMORY = 0,
	CAP_IOPORT,
} cap_type_t;

#define P_DELEGATE (1 << 0)
#define P_REVOKE (1 << 1)

typedef struct cap {
	cap_type_t type;
	uint32_t permissions;

	union {
		struct {
			uintptr_t start;
			uintptr_t end;
		} memory;

		struct {
			uint16_t start;
			uint16_t end;
		} ioport;
	} data;
} cap_t;

#endif // CAP_H
