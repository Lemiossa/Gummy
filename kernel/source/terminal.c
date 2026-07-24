/*
 * terminal.c
 * Created by Matheus Leme da Silva
 * */
#include <types.h>
#include <vga.h>
#include <terminal.h>

uint16_t cursor_x, cursor_y;
uint8_t current_color = 0x07;

// Scrolls up one line in the terminal
void terminal_scroll_up(void)
{
    for (uint16_t y = 1; y < TERMINAL_HEIGHT; y++)
    {
        for (uint16_t x = 0; x < TERMINAL_WIDTH; x++)
        {
            VgaCell cell = vga_peek_cell(x, y);
            vga_draw_cell(cell, x, y - 1);
        }
    }

    VgaCell space_cell = {' ', current_color};
    for (uint16_t x = 0; x < TERMINAL_WIDTH; x++)
        vga_draw_cell(space_cell, x, TERMINAL_HEIGHT - 1);
}

// Prints a char in the terminal and updates cursor position.
void terminal_putchar(char c)
{
    if (c == '\n')
        cursor_y++;
    else if (c == '\r')
        cursor_x = 0;
    else
    {
        VgaCell cell = {c, current_color};
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
        cursor_x = TERMINAL_HEIGHT - 1;
        cursor_y--;
    }

    vga_update_cursor(cursor_x, cursor_y);
}

// Prints a string on the terminal
void terminal_print_string(const char *s)
{
    while (*s)
        terminal_putchar(*s++);
}

// Initializes the terminal system
void terminal_init(void)
{
    cursor_x = 0;
    cursor_y = 0;

    VgaCell space_cell = {' ', current_color};
    for (uint16_t y = 0; y < TERMINAL_HEIGHT; y++)
        for (uint16_t x = 0; x < TERMINAL_WIDTH; x++)
            vga_draw_cell(space_cell, x, y);

    vga_update_cursor(cursor_x, cursor_y);
}

