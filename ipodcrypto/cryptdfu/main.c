//
//
//    Copyright 2009 TheSeven
//
//
//    This file is part of TheSeven's iBugger.
//
//    TheSeven's iBugger is free software: you can redistribute it and/or
//    modify it under the terms of the GNU General Public License as
//    published by the Free Software Foundation, either version 2 of the
//    License, or (at your option) any later version.
//
//    TheSeven's iBugger is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//    See the GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License along
//    with TheSeven's iBugger.  If not, see <http://www.gnu.org/licenses/>.
//
//

#include <stdint.h>

#define PWRCONEXT  *((volatile uint32_t*)(0x3C500040))
#define ICONSRCPND *((volatile uint32_t*)(0x39C00000))
#define ICONINTPND *((volatile uint32_t*)(0x39C00010))
#define AESCONTROL *((volatile uint32_t*)(0x39800000))
#define AESGO      *((volatile uint32_t*)(0x39800004))
#define AESUNKREG0 *((volatile uint32_t*)(0x39800008))
#define AESSTATUS  *((volatile uint32_t*)(0x3980000C))
#define AESUNKREG1 *((volatile uint32_t*)(0x39800010))
#define AESKEYLEN  *((volatile uint32_t*)(0x39800014))
#define AESOUTSIZE *((volatile uint32_t*)(0x39800018))
#define AESOUTADDR *((volatile uint32_t*)(0x39800020))
#define AESINSIZE  *((volatile uint32_t*)(0x39800024))
#define AESINADDR  *((volatile uint32_t*)(0x39800028))
#define AESAUXSIZE *((volatile uint32_t*)(0x3980002C))
#define AESAUXADDR *((volatile uint32_t*)(0x39800030))
#define AESSIZE3   *((volatile uint32_t*)(0x39800034))
#define AESTYPE    *((volatile uint32_t*)(0x3980006C))
#define HASHCTRL   *((volatile uint32_t*)(0x3C600000))
#define HASHRESULT  ((volatile uint32_t*)(0x3C600020))
#define HASHDATAIN  ((volatile uint32_t*)(0x3C600040))

void clean_dcache() __attribute__((naked, noinline));
void clean_dcache()
{
    asm volatile(
        "MOV R0, #0                \n\t"
        "clean_dcache_loop:        \n\t"
        "MCR p15, 0, R0,c7,c10,2   \n\t"
        "ADD R1, R0, #0x10         \n\t"
        "MCR p15, 0, R1,c7,c10,2   \n\t"
        "ADD R1, R1, #0x10         \n\t"
        "MCR p15, 0, R1,c7,c10,2   \n\t"
        "ADD R1, R1, #0x10         \n\t"
        "MCR p15, 0, R1,c7,c10,2   \n\t"
        "ADDS R0, R0, #0x04000000  \n\t"
        "BNE clean_dcache_loop     \n\t"
        "MCR p15, 0, R5,c7,c10,4   \n\t"
        "MOV PC, LR                \n\t"
    );
}

void invalidate_dcache() __attribute__((naked, noinline));
void invalidate_dcache()
{
    asm volatile(
        "MOV R0, #0                \n\t"
        "invalidate_dcache_loop:   \n\t"
        "MCR p15, 0, R0,c7,c14,2   \n\t"
        "ADD R1, R0, #0x10         \n\t"
        "MCR p15, 0, R1,c7,c14,2   \n\t"
        "ADD R1, R1, #0x10         \n\t"
        "MCR p15, 0, R1,c7,c14,2   \n\t"
        "ADD R1, R1, #0x10         \n\t"
        "MCR p15, 0, R1,c7,c14,2   \n\t"
        "ADDS R0, R0, #0x04000000  \n\t"
        "BNE invalidate_dcache_loop\n\t"
        "MCR p15, 0, R5,c7,c10,4   \n\t"
        "MOV PC, LR                \n\t"
    );
}

void encrypt(uint32_t* data, uint32_t size)
{
    uint32_t ptr, i;
    uint32_t go = 1;
    PWRCONEXT &= ~0x400;
    AESTYPE = 1;
    AESUNKREG0 = 1;
    AESUNKREG0 = 0;
    AESCONTROL = 1;
    AESKEYLEN = 9;
    AESOUTSIZE = size << 2;
    AESAUXSIZE = 0x10;
    AESINSIZE = 0x10;
    AESSIZE3 = 0x10;
    for (ptr = 0; ptr < size; ptr += 4)
    {
        AESOUTADDR = (uint32_t)data + (ptr << 2);
        AESINADDR = (uint32_t)data + (ptr << 2);
        AESAUXADDR = (uint32_t)data + (ptr << 2);
        if (ptr != 0) for (i = 0; i < 4; i++) data[ptr + i] ^= data[ptr + i - 4];
        clean_dcache();
        AESSTATUS = 6;
        AESGO = go;
        go = 3;
        while ((AESSTATUS & 6) == 0);
        invalidate_dcache();
    }
    AESCONTROL = 0;
    PWRCONEXT |= 0x400;
}

/* Don't need this, just for reference
void decrypt(uint32_t* data, uint32_t size)
{
    uint32_t ptr, i;
    uint32_t go = 1;
    AESTYPE = 1;
    AESUNKREG0 = 1;
    AESUNKREG0 = 0;
    AESCONTROL = 1;
    AESKEYLEN = 8;
    AESOUTSIZE = size << 2;
    AESAUXSIZE = 0x10;
    AESINSIZE = 0x10;
    AESSIZE3 = 0x10;
    for (ptr = size - 4; ; ptr -= 4)
    {
        AESOUTADDR = (uint32_t)data + (ptr << 2);
        AESINADDR = (uint32_t)data + (ptr << 2);
        AESAUXADDR = (uint32_t)data + (ptr << 2);
        clean_dcache();
        AESSTATUS = 6;
        AESGO = go;
        go = 3;
        while ((AESSTATUS & 6) == 0);
        invalidate_dcache();
        if (ptr == 0) break;
        for (i = 0; i < 4; i++) data[ptr + i] ^= data[ptr + i - 4];
    }
    AESCONTROL = 0;
}
*/

void hash(uint32_t* data, uint32_t size, uint32_t* result)
{
    uint32_t ptr, i;
    uint32_t ctrl = 2;
    PWRCONEXT &= ~0x4;
    for (ptr = 0; ptr < size; ptr += 0x10)
    {
      for (i = 0; i < 0x10; i++) HASHDATAIN[i] = data[ptr + i];
      HASHCTRL = ctrl;
      ctrl = 0xA;
      while ((HASHCTRL & 1) != 0);
    }
    for (i = 0; i < 5; i ++) result[i] = HASHRESULT[i];
    PWRCONEXT |= 0x4;
}

void main(void)
{
    #define image ((volatile uint32_t*)(0x08010000))
    #define size *((volatile uint32_t*)(0x08000024))
    uint32_t i;
    for (i = 0; i < 0x200; i++) image[i] = 0;
    image[0] = 0x31303738;
    image[1] = 0x00302e31;
    image[2] = 0x800;
    image[3] = size;
    hash(&image[0x200], size >> 2, &image[4]);
    hash(image, 0x10, &image[0x10]);
    encrypt(image, (size >> 2) + 0x200);
}

void irqhandler(void) __attribute__((interrupt("IRQ")));
void irqhandler(void)
{
    uint32_t sources;
    sources = ICONSRCPND;

    ICONSRCPND = sources;
    ICONINTPND = sources;
}
