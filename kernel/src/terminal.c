/*
 * terminal.c
 * Criado por Matheus Leme da Silva
 * */
#include <types.h>
#include <vga.h>
#include <terminal.h>
#include <utils.h>

uint16_t cursor_x, cursor_y;
uint8_t current_color = 0x07;
static int initialized = 0;

// Rola uma linha para cima no terminal
void terminal_scroll_up(void)
{
    for (uint16_t y = 1; y < TERMINAL_HEIGHT; y++)
    {
        for (uint16_t x = 0; x < TERMINAL_WIDTH; x++)
        {
            vga_cell_t cell = vga_peek_cell(x, y);
            vga_draw_cell(cell, x, y - 1);
        }
    }

    vga_cell_t space_cell = {' ', current_color};
    for (uint16_t x = 0; x < TERMINAL_WIDTH; x++)
        vga_draw_cell(space_cell, x, TERMINAL_HEIGHT - 1);
}

// Imprime um caractere no terminal e atualiza a posicao do cursor.
void terminal_putchar(char c)
{
    if (c == '\n')
        cursor_y++;
    else if (c == '\r')
        cursor_x = 0;
    else
    {
        vga_cell_t cell = {c, current_color};
        vga_draw_cell(cell, cursor_x++, cursor_y);
    }
    
    if (cursor_x >= TERMINAL_WIDTH)
    {
        cursor_x = 0;
        cursor_y++;
    }

    if (cursor_y >= TERMINAL_HEIGHT)
    {
        terminal_scroll_up();
        cursor_x = 0;
        cursor_y--;
    }

    vga_update_cursor(cursor_x, cursor_y);
}

// Imprime uma string no terminal
void terminal_print_string(const char *s)
{
    if (!initialized)
        return;

    while (*s)
        terminal_putchar(*s++);
}

// Inicializa o sistema de terminal
void terminal_init(void)
{
    cursor_x = 0;
    cursor_y = 0;

    vga_cell_t space_cell = {' ', current_color};
    for (uint16_t y = 0; y < TERMINAL_HEIGHT; y++)
        for (uint16_t x = 0; x < TERMINAL_WIDTH; x++)
            vga_draw_cell(space_cell, x, y);

    vga_update_cursor(cursor_x, cursor_y);
    initialized = 1;
}

// Imprime um byte em hexadecimal
void terminal_print_hex8(uint8_t b)
{
    char str[3];
    BYTE_TO_HEX(b, str);
    terminal_print_string(str);
}

// Imprime uma word em hexadecimal
void terminal_print_hex16(uint16_t w)
{
    terminal_print_hex8((w >> 8) & 0xFF);
    terminal_print_hex8(w & 0xFF);
}

// Imprime uma dword em hexadecimal
void terminal_print_hex32(uint32_t dw)
{
    terminal_print_hex16((dw >> 16) & 0xFFFF);
    terminal_print_hex16(dw & 0xFFFF);
}

// Imprime uma qword em hexadecimal
void terminal_print_hex64(uint64_t qw)
{
    terminal_print_hex32((qw >> 32) & 0xFFFFFFFF);
    terminal_print_hex32(qw & 0xFFFFFFFF);
}
