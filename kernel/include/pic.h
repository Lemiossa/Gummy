#ifndef PIC_H
#define PIC_H
#include <types.h>

#define PIC_VECTOR_START 0x20

void pic_remap(void);
void pic_send_eoi(uint8_t irq);
void pic_irq_set_mask(uint8_t irq);
void pic_irq_clear_mask(uint8_t irq);

#endif // PIC_H
