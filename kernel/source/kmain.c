/*
 * kmain.c
 * Created by Matheus Leme Da Silva
 */

void kmain()
{
    unsigned char *p = (unsigned char *)0xb8000;
    *p = 'X';
    *(p+1) = 0x0F;
    while (1);
}
