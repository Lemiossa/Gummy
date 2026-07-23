/*
 * kmain.c
 * Created by Matheus Leme Da Silva
 */

typedef unsigned char uint8_t;
typedef char int8_t;
typedef unsigned short uint16_t;
typedef short int16_t;
typedef unsigned int uint32_t;
typedef int int32_t;

#define TERMINAL_WIDTH 80
#define TERMINAL_HEIGHT 25

uint16_t cursor_x, cursor_y;
uint8_t current_color = 0x07;
volatile uint16_t *vga = (uint16_t *)0xB8000;

void memset(void *p, uint8_t v, uint32_t n)
{
    if (!p || n == 0)
        return;

    uint8_t *ptr = (uint8_t *)p;
    for (uint32_t i = 0; i < n; i++)
    {
        ptr[i] = v;
    }
}

// Draws a cell in the specified position
void terminal_draw_cell(uint8_t c, uint8_t color, uint16_t x, uint16_t y)
{
    uint16_t pos = y * TERMINAL_WIDTH + x;
    vga[pos] = (color << 8) | c;
}

// Peeks achar in the specified position
uint16_t terminal_peek_cell(uint16_t x, uint16_t y)
{
    uint16_t pos = y * TERMINAL_WIDTH + x;
    return vga[pos];
}

// Scrolls up one line in the terminal
void terminal_scroll_up(void)
{
    for (uint16_t y = 1; y < TERMINAL_HEIGHT; y++)
    {
        for (uint16_t x = 0; x < TERMINAL_WIDTH; x++)
        {
            uint16_t cell = terminal_peek_cell(x, y);
            uint8_t ch = cell & 0xFF;
            uint8_t color = (cell >> 8) & 0xFF;
            terminal_draw_cell(ch, color, x, y - 1);
        }
    }

    for (uint16_t x = 0; x < TERMINAL_WIDTH; x++)
        terminal_draw_cell(' ', current_color, x, TERMINAL_HEIGHT - 1);
}

// Prints a char in the terminal and updates cursor position.
void terminal_putchar(char c)
{
    if (c == '\n')
        cursor_y++;
    else if (c == '\r')
        cursor_x = 0;
    else
        terminal_draw_cell(c, current_color, cursor_x++, cursor_y);
    
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

    for (uint16_t y = 0; y < TERMINAL_HEIGHT; y++)
        for (uint16_t x = 0; x < TERMINAL_WIDTH; x++)
            terminal_draw_cell(' ', 0x07, x, y);
}

void kmain()
{
    terminal_init();
    terminal_print_string("Hello World");
    while (1);
}
