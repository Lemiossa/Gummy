/*
 * vga.c
 * Created by Matheus Leme da Silva
 * Recourses:
 * https://wiki.osdev.org/Text_Mode_Cursor
 * */
#include <types.h>
#include <vga.h>
#include <io.h>

#define VGA_TEXT_MODE_WIDTH 80
#define VGA_TEXT_MODE_HEIGHT 25
#define VGA_LOC 0xC00B8000

volatile VgaCell *vga = (VgaCell *)VGA_LOC;

// Draws a cell in the specified position
// **FOR TEXT MODE**
void vga_draw_cell(VgaCell cell, uint16_t x, uint16_t y)
{
    uint16_t pos = y * VGA_TEXT_MODE_WIDTH + x;
    vga[pos] = cell;
}

// Peeks a cell in the specified position
// **FOR TEXT MODE**
VgaCell vga_peek_cell(uint16_t x, uint16_t y)
{
    uint16_t pos = y * VGA_TEXT_MODE_WIDTH + x;
    return vga[pos];
}

// Updates de VGA cursor position
// **FOR TEXT MODE**
void vga_update_cursor(uint16_t x, uint16_t y)
{
    uint16_t pos = y * VGA_TEXT_MODE_WIDTH + x;
    outb(0x3D4, 0x0F);
    outb(0x3D5, (uint8_t) (pos & 0xFF));
    outb(0x3D4, 0x0E);
    outb(0x3D5, (uint8_t) ((pos >> 8) & 0xFF));
}

