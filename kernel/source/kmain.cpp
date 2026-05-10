/*
 * kmain.cpp
 * Created by Matheus Leme Da Silva
 */ 



extern "C" void kmain()
{
    unsigned char *p = (unsigned char *)0xb8000;
    *p = 'X';
    *(p+1) = 0x0F;
    while (1);
}
