@
@
@    Copyright 2009 TheSeven
@
@
@    This file is part of TheSeven's iBugger.
@
@    TheSeven's iBugger is free software: you can redistribute it and/or
@    modify it under the terms of the GNU General Public License as
@    published by the Free Software Foundation, either version 2 of the
@    License, or (at your option) any later version.
@
@    TheSeven's iBugger is distributed in the hope that it will be useful,
@    but WITHOUT ANY WARRANTY; without even the implied warranty of
@    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
@    See the GNU General Public License for more details.
@
@    You should have received a copy of the GNU General Public License along
@    with TheSeven's iBugger.  If not, see <http://www.gnu.org/licenses/>.
@
@

.global _start
_start:

@ Prepare regs
ldr r13, =0x2400aaaa    @ R13 = 0x2400aaaa
ldr r12, =0x24005554    @ R12 = 0x24005554
ldr r11, =0xfff         @ R11 = 0xfff (sector mask)
ldr r10, =0xffff        @ R10 = 0xffff (empty sector pattern)
ldr r9, addr            @ R9 = destination address
ldr r8, size            @ R8 = image size
adr r7, data            @ R7 = pointer to start of data
mov r6, #0xaa
mov r5, #0x55

loop:
  tst r9, r11           @ If we're not on a sector boundary, don't erase
  bne skiperase
    mov r0, r7
    mov r1, #0x1000
    cmp r1, r8
    addcs r1, r8, #1
    mov r1, r1,lsr#1
    mov r2, r9
    checksector:
      ldrh r3, [r0], #2
      ldrh r4, [r2], #2
      cmp r3, r4
      bne needswrite
      subs r1, r1, #1
    bne checksector
    add r7, r7, #0x1000
    subs r8, r8, #0x1000
    add r9, r9, #0x1000
    b writedone
    needswrite:
    mov r0, r10
    mov r1, #0x800
    mov r2, r9
    checkempty:
      ldrh r3, [r2], #2
      and r0, r0, r3
      subs r1, r1, #1
    bne checkempty
    cmp r0, r10
    beq skiperase
    mov r2, #0x80
    mov r3, #0x30
    strh r6, [r13]      @ Write 0xaa to 0x2400aaaa (command phase 1)
    strh r5, [r12]      @ Write 0x55 to 0x24005554 (command phase 2)
    strh r2, [r13]      @ Write 0x80 to 0x2400aaaa (erase operation)
    strh r6, [r13]      @ Write 0xaa to 0x2400aaaa (erase verify 1)
    strh r5, [r12]      @ Write 0x55 to 0x24005554 (erase verify 2)
    strh r3, [r9]       @ Write 0x30 to destination address (erase sector)
    waiterase:
      ldrh r0, [r9]
      cmp r0, r10
    bne waiterase
  skiperase:
  ldrh r0, [r7], #2     @ Load data for the current word
  ldrh r1, [r9], #2     @ Load data for the current word
  cmp r0, r1
  beq skipwrite
    mov r2, #0xa0
    strh r6, [r13]      @ Write 0xaa to 0x2400aaaa (command phase 1)
    strh r5, [r12]      @ Write 0x55 to 0x24005554 (command phase 2)
    strh r2, [r13]      @ Write 0xa0 to 0x2400aaaa (program word)
    strh r0, [r9, #-2]  @ Write the data word to the destination address
    waitwrite:
      ldrh r1, [r9, #-2]
      cmp r0, r1
    bne waitwrite
  skipwrite:
  subs r8, r8, #2       @ Check if there is anything left to be done
  writedone:
bhi loop

hang:
b hang

.ltorg

addr:
.ascii "ADDR"           @ Will be replaced by genflasher.py

size:
.ascii "SIZE"           @ Will be replaced by genflasher.py

data:                   @ The data to be flashed will be appended to this file
