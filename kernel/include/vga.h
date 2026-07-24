#ifndef VGA_H
#define VGA_H

#include <types.h>

typedef struct 
{
    uint8_t ch;
    uint8_t attr;
} __attribute__((packed)) VgaCell;

// Draws a cell in the specified position
// **FOR TEXT MODE**
void vga_draw_cell(VgaCell cell, uint16_t x, uint16_t y);
// Peeks a cell in the specified position
// **FOR TEXT MODE**
VgaCell vga_peek_cell(uint16_t x, uint16_t y);
// Updates de VGA cursor position
// **FOR TEXT MODE**
void vga_update_cursor(uint16_t x, uint16_t y);

#endif // VGA_H
