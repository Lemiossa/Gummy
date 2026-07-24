#ifndef TERMINAL_H
#define TERMINAL_H

#define TERMINAL_WIDTH 80
#define TERMINAL_HEIGHT 25

// Initializes the terminal system
void terminal_init(void);
// Prints a char in the terminal and updates cursor position.
void terminal_putchar(char c);
// Prints a string on the terminal
void terminal_print_string(const char *s);

#endif // TERMINAL_H
