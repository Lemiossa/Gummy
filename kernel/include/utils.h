#ifndef UTILS_H
#define UTILS_H

#define BYTE_TO_HEX(byte, dest) do { \
    (dest)[0] = "0123456789ABCDEF"[((byte) >> 4) & 0x0F]; \
    (dest)[1] = "0123456789ABCDEF"[(byte) & 0x0F]; \
    (dest)[2] = '\0'; \
} while(0)

#endif // UTILS_H
