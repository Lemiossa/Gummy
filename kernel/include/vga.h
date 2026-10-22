#ifndef VGA_H
#define VGA_H

#include <types.h>

typedef struct 
{
    uint8_t ch;
    uint8_t attr;
} __attribute__((packed)) vga_cell_t;

// Desenha uma celula na posicao especificada
// **PARA O MODO TEXTO**
void vga_draw_cell(vga_cell_t cell, uint16_t x, uint16_t y);
// Le uma celula na posicao especificada
// **PARA O MODO TEXTO**
vga_cell_t vga_peek_cell(uint16_t x, uint16_t y);
// Atualiza a posicao do cursor da VGA
// **PARA O MODO TEXTO**
void vga_update_cursor(uint16_t x, uint16_t y);

#endif // VGA_H
