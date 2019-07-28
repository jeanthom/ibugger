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
	swi	0x6
	swi	0x6
	swi	0x6
	swi	0x6
	swi	0x6
	swi	0x6
	ldr	pc, =irqhandler
	subs	pc, lr, #4

	ldr	r0, =__bss_start__
	ldr	r1, =__bss_end__
	mov	r2, #0
1:	cmp	r0, r1
	strle	r2, [r0], #4
	ble	1b

	bl	main

	swi	0x7
