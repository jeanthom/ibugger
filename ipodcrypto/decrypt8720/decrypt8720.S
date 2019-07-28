@
@
@    Copyright 2010 TheSeven
@
@
@    This file is part of TheSeven's iPod tools.
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
@    with TheSeven's iPod tools.  If not, see <http://www.gnu.org/licenses/>.
@
@

.global _start
_start:

swi 6
swi 6
swi 6
swi 6
swi 6
swi 6
swi 6
swi 6

mov r0, #0x08000000
orr r0, r0, #0x10000
ldr r1, [r0,#0x14]
add r0, r0, #0x600
mov r2, #0xe
mov r3, #1
bl doaes

swi 7

doaes:
	stmfd	sp!, {r4, lr}
	mov	r12, #0x38000000
	orr	r12, r12, #0xc00000
	add	r4, r12, #0x3900000
	ldr	lr, [r4, #0x48]
	bic	lr, lr, #0x80
	str	lr, [r4, #0x48]
	mov	lr, #0
	mov	r4, #1
	str	lr, [r12,#0x74]
	str	lr, [r12,#0x78]
	str	lr, [r12,#0x7c]
	str	lr, [r12,#0x80]
	str	r4, [r12,#0x08]
	str	lr, [r12,#0x08]
	str	r4, [r12]
	str	lr, [r12,#0x10]
	str	r3, [r12,#0x6c]
	ldr	r3, [r12,#0x6c]
	mvn	r3, r3
	str	r3, [r12,#0x88]
	str	lr, [r12,#0x8c]
	str	r2, [r12,#0x14]
	str	r1, [r12,#0x18]
	str	r0, [r12,#0x20]
	str	r1, [r12,#0x24]
	str	r0, [r12,#0x28]
	str	r1, [r12,#0x2c]
	str	r0, [r12,#0x30]
	str	r1, [r12,#0x34]
	str	r4, [r12,#0x04]
doaes_wait:
	ldr	r0, [r12,#0x0c]
	tst	r0, #0xf
	beq	doaes_wait
	str	lr, [r12,#0x4c]
	str	lr, [r12,#0x50]
	str	lr, [r12,#0x54]
	str	lr, [r12,#0x58]
	str	lr, [r12,#0x5c]
	str	lr, [r12,#0x60]
	str	lr, [r12,#0x64]
	str	lr, [r12,#0x68]
	str	lr, [r12,#0x74]
	str	lr, [r12,#0x78]
	str	lr, [r12,#0x7c]
	str	lr, [r12,#0x80]
	add	r4, r12, #0x3900000
	ldr	lr, [r4, #0x48]
	orr	lr, lr, #0x80
	str	lr, [r4, #0x48]
	ldmfd	sp!, {r4, pc}
