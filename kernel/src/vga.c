/*
 * vga.c
 * Criado por Matheus Leme da Silva
 * Recursos:
 * https://wiki.osdev.org/Text_Mode_Cursor
 * */
#include <io.h>
#include <types.h>
#include <vga.h>

#define VGA_TEXT_MODE_WIDTH 80
#define VGA_TEXT_MODE_HEIGHT 25
#define VGA_LOC 0xC00B8000

volatile vga_cell_t *vga = (vga_cell_t *)VGA_LOC;

// Desenha uma celula na posicao especificada
// **PARA O MODO TEXTO**
void vga_draw_cell(vga_cell_t cell, uint16_t x, uint16_t y) {
	uint16_t pos = y * VGA_TEXT_MODE_WIDTH + x;
	vga[pos] = cell;
}

// Le uma celula na posicao especificada
// **PARA O MODO TEXTO**
vga_cell_t vga_peek_cell(uint16_t x, uint16_t y) {
	uint16_t pos = y * VGA_TEXT_MODE_WIDTH + x;
	return vga[pos];
}

// Atualiza a posicao do cursor da VGA
// **PARA O MODO TEXTO**
void vga_update_cursor(uint16_t x, uint16_t y) {
	uint16_t pos = y * VGA_TEXT_MODE_WIDTH + x;
	outb(0x3D4, 0x0F);
	outb(0x3D5, (uint8_t)(pos & 0xFF));
	outb(0x3D4, 0x0E);
	outb(0x3D5, (uint8_t)((pos >> 8) & 0xFF));
}
