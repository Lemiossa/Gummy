/*
 * string.c
 * Criado por Matheus Leme da Silva
 * */
#include <string.h>
#include <types.h>

// Copia n bytes de src para dst
void memcpy(void *dst, const void *src, size_t n) {
	if (!dst || !src)
		return;

	uint8_t *from = (uint8_t *)src;
	uint8_t *to = (uint8_t *)dst;

	for (size_t i = 0; i < n; i++)
		to[i] = from[i];
}

// Preenche n bytes com o valor c em dst
void memset(void *dst, int c, size_t n) {
	if (!dst)
		return;

	uint8_t b = (uint8_t)c;

	uint8_t *p = (uint8_t *)dst;
	for (size_t i = 0; i < n; i++)
		p[i] = b;
}

const char CHARS[] = "0123456789ABCDEF";
const char chars[] = "0123456789abcdef";

// Transforma um número em sua representação ascii com uma base desejada
// Por segurança, o buffer de saída deve ter 66 bytes de tamanho. 64 de números,
// 65 pra um possível sinal e 66 para caso tudo seja usado e ele precise de um
// null terminator ou seja:
//   out: deve ter 66 bytes
//   base: deve ser de 2 a 16
//   num: deve ser absoluto
//   signal: deve indicar se tem '-' ou não
//   upper: se !0, caracteres serão em maiúsculo
int itoa(char *out, uint64_t base, uint64_t num, int signal, int upper,
		 uint32_t zero_pad) {
	if (base < 2 || base > 16)
		return 0;

	const char *chs = upper ? CHARS : chars;

	char buffer[66];
	int index = 0;
	int len = 0;

	if (num == 0) {
		buffer[index++] = '0';
	} else {
		while (num > 0) {
			buffer[index++] = chs[num % base];
			num /= base;
		}
	}

	if (signal)
		buffer[index++] = '-';

	len = index;

	uint32_t padding = zero_pad > (uint32_t)len ? zero_pad - len : 0;

	int pos = 0;

	// Sinal
	if (signal)
		out[pos++] = '-';

	// Padding
	for (uint32_t i = 0; i < padding; i++)
		out[pos++] = '0';

	// Número
	int start = signal ? index - 2 : index - 1;

	for (int i = start; i >= 0; i--)
		out[pos++] = buffer[i];

	out[pos] = '\0';

	return pos;
}
