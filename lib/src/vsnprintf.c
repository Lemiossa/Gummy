/*
 * vsnprintf.c
 * Criado por Matheus Leme da Silva
 */
#include <string.h>
#include <types.h>
#include <vsnprintf.h>

typedef enum { SIZE_NORMAL, SIZE_H, SIZE_HH, SIZE_L, SIZE_LL } format_size_t;

struct string_formatter {
	char *out;
	size_t index;
	size_t limit;
};

static void put_char(struct string_formatter *f, char c) {
	if (!f)
		return;

	if (f->out && f->limit > 0 && f->index < f->limit - 1)
		f->out[f->index] = c;

	f->index++;
}

static void put_string(struct string_formatter *f, const char *str, size_t n) {
	if (!f || !str)
		return;

	for (size_t i = 0; i < n; i++)
		put_char(f, str[i]);
}

static void put_number(struct string_formatter *f, uint64_t base, uint64_t num,
					   int signal, int upper, uint32_t zero_pad) {
	char buffer[66];

	int len = itoa(buffer, base, num, signal, upper, zero_pad);

	if (len > 0)
		put_string(f, buffer, (size_t)len);
}

int vsnprintf(char *s, size_t n, const char *format, va_list arg) {
	if (!format || (!s && n != 0))
		return -1;

	struct string_formatter f = {.out = s, .index = 0, .limit = n};

	while (*format) {
		if (*format != '%') {
			put_char(&f, *format++);
			continue;
		}

		format++;

		if (!*format)
			break;

		// Flags
		int zero_flag = 0;

		if (*format == '0') {
			zero_flag = 1;
			format++;
		}

		// Largura
		uint32_t width = 0;

		while (*format >= '0' && *format <= '9') {
			uint32_t digit = (uint32_t)(*format - '0');

			if (width <= (UINT32_MAX - digit) / 10)
				width = width * 10 + digit;
			else
				width = UINT32_MAX;

			format++;
		}

		// Modificador de tamanho
		format_size_t size = SIZE_NORMAL;

		if (*format == 'h') {
			size = SIZE_H;
			format++;

			if (*format == 'h') {
				size = SIZE_HH;
				format++;
			}
		} else if (*format == 'l') {
			size = SIZE_L;
			format++;

			if (*format == 'l') {
				size = SIZE_LL;
				format++;
			}
		}

		if (!*format)
			break;

		uint64_t base = 10;
		uint64_t num = 0;

		int signal = 0;
		int upper = 0;
		int is_number = 0;
		int prefix = 0;

		switch (*format) {
		case '%':
			put_char(&f, '%');
			break;

		case 'c': {
			char c = (char)va_arg(arg, int);
			put_char(&f, c);
			break;
		}

		case 's': {
			const char *str = va_arg(arg, const char *);

			if (!str)
				str = "(null)";

			while (*str)
				put_char(&f, *str++);

			break;
		}

		case 'p': {
			void *ptr = va_arg(arg, void *);

			num = (uint64_t)(uintptr_t)ptr;
			base = 16;
			prefix = 1;
			upper = 0;
			is_number = 1;

			break;
		}

		case 'd':
		case 'i': {
			int64_t value;

			switch (size) {
			case SIZE_HH:
				value = (signed char)va_arg(arg, int);
				break;

			case SIZE_H:
				value = (short)va_arg(arg, int);
				break;

			case SIZE_L:
				value = va_arg(arg, long);
				break;

			case SIZE_LL:
				value = va_arg(arg, long long);
				break;

			default:
				value = va_arg(arg, int);
				break;
			}

			if (value < 0) {
				signal = 1;
				num = (uint64_t)(-(value + 1)) + 1;
			} else {
				num = (uint64_t)value;
			}

			is_number = 1;
			break;
		}

		case 'u':
		case 'x':
		case 'X':
		case 'o': {
			switch (size) {
			case SIZE_HH:
				num = (unsigned char)va_arg(arg, int);
				break;

			case SIZE_H:
				num = (unsigned short)va_arg(arg, int);
				break;

			case SIZE_L:
				num = va_arg(arg, unsigned long);
				break;

			case SIZE_LL:
				num = va_arg(arg, unsigned long long);
				break;

			default:
				num = va_arg(arg, unsigned int);
				break;
			}

			if (*format == 'x' || *format == 'X')
				base = 16;
			else if (*format == 'o')
				base = 8;

			upper = (*format == 'X');
			is_number = 1;

			break;
		}

		default:
			put_char(&f, '%');
			put_char(&f, *format);
			break;
		}

		if (is_number) {
			uint32_t digit_width = 0;

			if (zero_flag && width > 0) {
				uint32_t extra = (signal ? 1 : 0) + (prefix ? 2 : 0);

				if (width > extra)
					digit_width = width - extra;
			}

			if (prefix) {
				put_char(&f, '0');
				put_char(&f, 'x');
			}

			put_number(&f, base, num, signal, upper, digit_width);
		}

		format++;
	}

	if (s && n > 0)
		s[f.index < n ? f.index : n - 1] = '\0';

	return (int)f.index;
}
