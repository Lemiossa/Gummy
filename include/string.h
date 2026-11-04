#ifndef STRING_H
#define STRING_H
#include <types.h>

// Copia n bytes de src para dst
void memcpy(void *dst, const void *src, size_t n);
// Preenche n bytes com o valor c em dst
void memset(void *dst, int c, size_t n);
// Compara n bytes de duas regiões da memória
// Retorna a diferença
int memcmp(const void *s1, const void *s2, size_t n);
// Transforma um número em sua representação ascii com uma base desejada
// Por segurança, o buffer de saída deve ter 66 bytes de tamanho. 64 de números,
// 65 pra um possível sinal e 66 para caso tudo seja usado e ele precise de um
// null terminator ou seja:
//   out: deve ter 66 bytes
//   base: deve ser de 2 a 16
//   num: deve ser absoluto
//   signal: deve indicar se tem '-' ou não
//   upper: se !0, caracteres serão em maiúsculo
//   zero_pad: zeros acrescentados no
// Retorna o número de caracteres escritos
int itoa(char *out, uint64_t base, uint64_t num, int signal, int upper,
		 uint32_t zero_pad);
// Retorna o tamanho de uma string
size_t strlen(const char *str);
// Compara as duas strings até o fim da primeira
// Retorna a diferença
int strcmp(const char *s1, const char *s2);
// Compara n bytes de duas strings
// Retorna a diferença
int strncmp(const char *s1, const char *s2, size_t n);

#endif // STRING_H
