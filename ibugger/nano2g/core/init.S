@
@
@    Copyright 2009-2010 TheSeven
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
	b	handle_reset
	b	handle_undefined_instr
	b	handle_swi
	b	handle_prefetch_abort
	b	handle_data_abort
	b	handle_undefined_vector
	b	handle_irq
	ldr	pc, val_0800001c
        b	init

handle_swi:
	str	r12, [sp,#-4]
	mrs	r12, cpsr
	bic	r12, r12, #0xc0
	msr	cpsr_c, r12
	ldr	r12, [lr,#-4]
	bic	r12, r12, #0xff000000
	cmp	r12, #(swilist_end-swilist_start)/4+1
	addcc	pc, pc, r12,lsl#2
	movs	pc, lr
swilist_start:
	b	debug_printf
	b	debug_sendbytes
	b	debug_sendchar
	b	debug_getline
	b	debug_getbytes
	b	debug_getchar
	b	debug_break
	b	debug_end
	b	aes128_decrypt
	b	aes128_encrypt
	b	aes128_decrypt_cbc
	b	aes128_encrypt_cbc
	b	waitforint
	b	reset
	b	snprintf
swilist_end:

debug_end:
	ldr	r12, val_target_regs
	stmia	r12!, {r0-r11}
	mov	r6, #8
	B	debug_break_common

debug_break:
	ldr	r12, val_target_regs
	stmia	r12!, {r0-r11}
	mov	r6, #1
debug_break_common:
	ldr	r0, [sp,#-4]
	mov	r1, sp
	mov	r2, lr
	mov	r3, lr
	mrs	r4, cpsr
	stmia	r12!, {r0-r6}
	b	debuggeridle

handle_undefined_instr:
	str	r12, [sp,#-4]
	mov	r12, #6
	b	exception

handle_prefetch_abort:
	str	r12, [sp,#-4]
	mov	r12, #5
	b	exception

handle_data_abort:
	str	r12, [sp,#-4]
	mrs	r12, cpsr
	and	r12, r12, #0x1f
	cmp	r12, #0x13
	beq	handle_swi
	sub	lr, lr, #4
	mov	r12, #4
	b	exception

handle_undefined_vector:
	str	r12, [sp,#-4]
	mov	r12, #7
	b	exception

handle_reset:
	str	r12, [sp,#-4]
	mov	r12, #3

exception:
	str	r11, [sp,#-8]
	ldr	r11, val_target_regs
	stmia	r11!, {r0-r10}
	ldr	r0, [sp,#-8]
	ldr	r1, [sp,#-4]
	mrs	r4, cpsr
	mrs	r5, spsr
	msr	cpsr_c, r5
	mov	r2, sp
	mov	r3, lr
	msr	cpsr_c, r4
	sub	r4, lr, #4
	mov	r6, sp
	stmia	r11!, {r0-r6,r12}
	ldr	lr, val_debuggeridle
	movs	pc, lr


val_300C30C0:
	.word	0x300C30C0

val_08000018:
	.word	0x08000018

val_0800001c:
	.word	0x0800001c

val_target_regs:
	.word	target_regs

val_stack_top:
	.word	stack_top

val_supervisor_stack:
	.word	supervisor_stack

val_exception_stack:
	.word	exception_stack

val_debuggeridle:
	.word	debuggeridle

val_debug_end:
	.word	debug_end

val___clear_start__:
	.word	__clear_start__

val___clear_end__:
	.word	__clear_end__

val_debug_sendbuf:
	.word	debug_sendbuf

val_debug_sendbuf_readptr:
	.word	debug_sendbuf_readptr

val_debug_sendbuf_writeptr:
	.word	debug_sendbuf_writeptr

val_debug_recvbuf:
	.word	debug_recvbuf

val_debug_recvbuf_readptr:
	.word	debug_recvbuf_readptr

val_debug_recvbuf_writeptr:
	.word	debug_recvbuf_writeptr

val_debug_printf_lr:
	.word	debug_printf_lr

val_debug_snprintf_buf:
	.word	debug_snprintf_buf


debug_printf:
	stmfd	sp!, {r2,r3}
	ldr	r3, val_debug_printf_lr
	str	lr, [r3]
	mov	r3, r1
	mov	r2, r0
	mov	r1, #0x100
	ldr	r0, val_debug_snprintf_buf
	bl	snprintf
	ldr	r3, val_debug_printf_lr
	ldr	lr, [r3]
	add	sp, sp, #8
	cmp	r0, #0x100
	movcs	r0, #0xff
	mov	r1, r0
	ldr	r0, val_debug_snprintf_buf
@ fallthrough


debug_sendbytes:
	stmfd	sp!, {lr}
	ldr	r12, val_debug_sendbuf_writeptr
	ldr	r3, [r12]
sendbytes_nextbyte:
	ldr	lr, val_debug_sendbuf
	add	lr, lr, r3
	ldrb	r2, [r0], #1
	strb	r2, [lr]
	add	r3, r3, #1
	mov	lr, #0x8000
	bic	r3, r3, lr
	ldr	lr, val_debug_sendbuf_readptr
sendbytes_waitfree:
	ldr	r2, [lr]
	subs	r2, r2, r3
	mcreq	p15, 0, r2,c7,c8,2
	beq	sendbytes_waitfree
	str	r3, [r12]
	subs	r1, r1, #1
	bne	sendbytes_nextbyte
	ldmfd	sp!, {lr}
	movs	pc, lr


debug_sendchar:
	ldr	r12, val_debug_sendbuf_writeptr
	ldr	r3, [r12]
	ldr	r1, val_debug_sendbuf
	add	r1, r1, r3
	strb	r0, [r1]
	add	r3, r3, #1
	mov	r1, #0x8000
	bic	r3, r3, r1
	ldr	r1, val_debug_sendbuf_readptr
sendchar_waitfree:
	ldr	r2, [r1]
	subs	r2, r2, r3
	mcreq	p15, 0, r2,c7,c8,2
	beq	sendchar_waitfree
	str	r3, [r12]
	movs	pc, lr


debug_getline:
	stmfd	sp!, {r4-r5,lr}
	mov	r4, r0
	mov	r5, r1
getline_nextchar:
	cmp	r5, #0
	subnes	r5, r5, #1
	beq	getline_done
	bl	debug_getchar
	strb	r0, [r4], #1
	cmp	r0, #0x0a
	bne	getline_nextchar
getline_done:
	mov	r0, #0
	strb	r0, [r4]
	ldmfd	sp!, {r4-r5,lr}
	movs	pc, lr


debug_getbytes:
	stmfd	sp!, {lr}
	ldr	r12, val_debug_recvbuf_readptr
	ldr	r3, [r12]
recvbytes_waitdata:
	ldr	lr, val_debug_recvbuf_writeptr
	ldr	r2, [lr]
	subs	r2, r2, r3
	mcreq	p15, 0, r2,c7,c8,2
	beq	recvbytes_waitdata
	ldr	lr, val_debug_recvbuf
	add	lr, lr, r3
	ldrb	r2, [lr]
	strb	r2, [r0], #1
	add	r3, r3, #1
	mov	lr, #0x400
	bic	r3, r3, lr
	str	r3, [r12]
	subs	r1, r1, #1
	bne	recvbytes_waitdata
	ldmfd	sp!, {lr}
	movs	pc, lr


debug_getchar:
	ldr	r12, val_debug_recvbuf_readptr
	ldr	r1, val_debug_recvbuf_writeptr
	ldr	r3, [r12]
recvchar_waitdata:
	ldr	r2, [r1]
	subs	r2, r2, r3
	mcreq	p15, 0, r2,c7,c8,2
	beq	recvchar_waitdata
	ldr	r1, val_debug_recvbuf
	add	r1, r1, r3
	ldrb	r0, [r1]
	add	r3, r3, #1
	mov	r1, #0x400
	bic	r3, r3, r1
	str	r3, [r12]
	movs	pc, lr


aes128_decrypt:
aes128_encrypt:
aes128_decrypt_cbc:
aes128_encrypt_cbc:


debuggeridle:
	sub	lr, pc, #4
@ fallthrough

waitforint:
	mov	r0, #0
	mcr	p15, 0, r0,c7,c0,4
	movs	pc, lr

sleep10ms:
	mov	R0, #0x01000000
@ fallthrough

sleeploop:
	SUBS	R0, R0, #1
	BNE	sleeploop
	MOV	PC, LR

init:
MSR CPSR_c, #0xD3          @ Supervisor mode, no IRQs, no FIQs
MRC p15, 0, R0,c1,c0
BIC R0, R0, #5
MCR p15, 0, R0,c1,c0       @ Disable the Protection Unit and DCache
MOV R11, #1
MOV R12, #0
MCR p15, 0, R12,c7,c5      @ Flush ICache
ADR LR, cacheflush_done

flushcache:
  MOV R5, #0
  flushcache_loop:
    MCR p15, 0, R5,c7,c14,2
    ADD R6, R5, #0x10
    MCR p15, 0, R6,c7,c14,2
    ADD R6, R6, #0x10
    MCR p15, 0, R6,c7,c14,2
    ADD R6, R6, #0x10
    MCR p15, 0, R6,c7,c14,2
    ADDS R5, R5, #0x04000000
  BNE flushcache_loop
  MCR p15, 0, R5,c7,c10,4
MOV PC, LR

cacheflush_done:
MOV R0, #0x3F
MCR p15, 0, R0,c6,c0,1     @ CS0: 4GB at offset 0 - everything
MCR p15, 0, R0,c6,c0,0     @ DS0: 4GB at offset 0 - everything
MOV R0, #0x31
MCR p15, 0, R0,c6,c1,1     @ CS1: SRAM/SDRAM mirror
MCR p15, 0, R0,c6,c1,0     @ DS1: SRAM/SDRAM mirror
ADD R0, R0, #0x08000000
MCR p15, 0, R0,c6,c2,1     @ CS2: SDRAM
MCR p15, 0, R0,c6,c2,0     @ DS2: SDRAM
MOV R0, #0x23
ADD R0, R0, #0x22000000
MCR p15, 0, R0,c6,c3,1     @ CS3: SRAM
MCR p15, 0, R0,c6,c3,0     @ DS3: SRAM
MOV R0, #0x27
ADD R0, R0, #0x24000000
MCR p15, 0, R0,c6,c4,1     @ CS4: NOR flash
MCR p15, 0, R0,c6,c4,0     @ DS4: NOR flash
MCR p15, 0, R12,c6,c5,1    @ CS5: unused
MCR p15, 0, R12,c6,c5,0    @ DS5: unused
MCR p15, 0, R12,c6,c6,1    @ CS6: unused
MCR p15, 0, R12,c6,c6,0    @ DS6: unused
MCR p15, 0, R12,c6,c7,1    @ CS7: unused
MCR p15, 0, R12,c6,c7,0    @ DS7: unused
MOV R0, #0x0E
MCR p15, 0, R0,c2,c0, 1    @ CS1-3: cacheable
MCR p15, 0, R0,c2,c0, 0    @ DS1-3: cacheable
MCR p15, 0, R0,c3,c0, 0    @ DS1-3: write cacheable
MOV R0, #0x300
ADD R0, R0, #0xFF
MCR p15, 0, R0,c5,c0, 1    @ CS0-4: full access
MCR p15, 0, R0,c5,c0, 0    @ DS0-4: full access
MRC p15, 0, R0,c1,c0
ORR R0, R0, #5
ORR R0, R0, #0x1000
MCR p15, 0, R0,c1,c0       @ Re-enable the Protection Unit and DCache

MOV R8, #0x38800000
MOV R9, #0x3C400000
ADD R1, R9, #0x00100000    @ Enable USB clocks
LDR R0, [R1,#0x28]
BIC R0, R0, #0x4000
STR R0, [R1,#0x28]
LDR R0, [R1,#0x40]
BIC R0, R0, #0x800
STR R0, [R1,#0x40]
ADD R1, R1, #0x00A00000    @ Enable charging
LDR R0, [R1,#0xB4]
ORR R0, R0, #1
STR R0, [R1,#0xB4]

	SUB	R1, R8, #0x00600000
	LDR	R2, [R1]
	ORR	R2, R2, #1
	BIC	R2, R2, #0x10000
	STR	R2, [R1]

	ldr	r0, val___clear_start__
	ldr	r1, val___clear_end__
	mov	r2, #0
1:	cmp	r0, r1
	strle	r2, [r0], #4
	ble	1b

	mov	r0, #2
	ldr	r1, val_target_regs
	str	r0, [r1,#0x48]

LDR R0, [R8,#0xE00]        @ PHY clock enable
BIC R0, R0, #3
STR R0, [R8,#0xE00]

LDR R3, [R8,#0x804]
ORR R0, R3, #2
STR R0, [R8,#0x804]        @ USB2 Gadget: Soft disconnect

BL sleep10ms
STR R12, [R9]              @ USB2 PHY: Power on
MOV R0, #6
STR R11, [R9,#0x1C]        @ USB2 PHY: Undocumented
MOV R0, #0xE00
ORR R0, R0, #0x3F
STR R0, [R9,#0x44]         @ USB2 PHY: Undocumented
LDR R0, [R9,#0x04]
BIC R0, R0, #3
STR R0, [R9,#0x04]         @ USB2 PHY: Clock is 48MHz
LDR R0, [R9,#0x08]
ORR R1, R0, #1
STR R1, [R9,#0x08]         @ USB2 PHY: Assert Software Reset
BL sleep10ms
STR R0, [R9,#0x08]         @ USB2 PHY: Deassert Software Reset
BL sleep10ms

STR R11, [R8,#0x10]        @ USB2 Gadget: Assert Core Software Reset
waitcorereset:
LDR R0, [R8,#0x10]         @ USB2 Gadget: Wait for Core to reset
TST R0, #1
BNE waitcorereset
TST R0, #0x80000000        @ USB2 Gadget: Wait for AHB IDLE
BEQ waitcorereset

MOV R0, #0xB6
STR R0, [R8,#0x24]         @ USB2 Gadget: RX FIFO size: 728 bytes
ORR R0, R0, #0x840000
STR R0, [R8,#0x28]         @ USB2 Gadget: Non-periodic TX FIFO size: 528 bytes
MOV R0, #0x27
STR R0, [R8,#0x08]         @ USB2 Gadget: DMA Enable, Burst Length: 4
MOV R0, #0x1400
ADD R0, R0, #8
STR R0, [R8,#0x0C]         @ USB2 Gadget: PHY IF is 16bit, Turnaround 5 (???)
STR R3, [R8,#0x804]
	MOV	R2, #0xC1000
	STR	R2, [R8,#0x18]         @ USB2 Gadget: Interrupt Mask
	ADD	R3, R8, #0x01400000
	STR	R12, [R3,#0x04]        @ All interrupts are IRQs
	MOV	R2, #0x00010000
	STR	R2, [R3,#0x08]         @ Mask all internal interrupts besides USB
	STR	R12, [R3,#0x38]        @ Mask all ???????? interrupts
	STR	R12, [R3,#0x20]        @ Mask all external interrupts
	SUB	R2, R12, #1
	STR	R2, [R3]               @ Ack all internal interrupts
	STR	R2, [R3,#0x10]         @ Ack the arbiter output
	STR	R2, [R3,#0x1c]         @ Ack all external interrupts
	LDR	SP, val_supervisor_stack
	MOV	R3, #0xD7
	MSR	CPSR_c, R3             @ Abort mode, IRQs disabled, FIQs disabled
	LDR	SP, val_exception_stack
	MOV	R3, #0xDB
	MSR	CPSR_c, R3             @ Undefined Instruction mode, IRQs disabled, FIQs disabled
	LDR	SP, val_exception_stack
	MOV	R3, #0x13
	MSR	CPSR_c, R3             @ Supervisor mode, IRQs enabled, FIQs enabled
	LDR	R2, val_300C30C0
	B	debuggeridle


handle_irq:
	stmfd	sp, {r11,r12}
	mov	r12, #0x39C00000
	ldr	r11, [r12,#0x08]
	ldr	r12, [r12]
	tst	r12, #0x00010000
	bne	catchint
	ands	r12, r12, r11
	beq	catchint
	ldr	r12, val_target_regs
	ldr	r12, [r12,#0x48]
	cmp	r12, #0
	ldreq	r11, [sp,#-8]
	ldreq	r12, [sp,#-4]
	ldreq	pc, val_08000018
catchint:
	ldr	r11, val_target_regs
	ldr	r12, [r11,#0x48]
	cmp	r12, #0
	bne	nosave
	stmia	r11!, {r0-r10}
	mov	r10, #0x39C00000
	ldr	r9, [r10,#0x08]
	ldr	r10, [r10]
	and	r10, r10, r9
	bics	r10, r10, #0x00010000
	ldr	r0, [sp,#-8]
	ldr	r1, [sp,#-4]
	movne	r2, sp
	movne	r3, lr
	ldrne	r4, val_08000018
	mrsne	r5, cpsr
	bne	save
	mrs	r6, cpsr
	mrs	r5, spsr
	orr	r7, r5, #0xc0
	msr	cpsr_c, r7
	mov	r2, sp
	mov	r3, lr
	msr	cpsr_c, r6
	sub	r4, lr, #4
save:
	stmia	r11!, {r0-r5}
nosave:
	ldr	sp, val_stack_top

	MOV	R8, #0x38800000
	MOV	R11, #1
	MOV	R12, #0

	mov	r0, #0x39C00000
	ldr	r1, [r0]
	tst	r1, #0x00010000
	beq	nousbint

  LDR R3, [R8,#0x14]         @ Global USB interrupts
  TST R3, #0x00001000        @ BUS reset
  BEQ noreset
    MOV R2, #0x500
    STR R2, [R8,#0x804]
    MOV R2, #4
    STR R2, [R8,#0x800]        @ USB2 Gadget: Device Address 0, STALL on non-zero length status stage
    MOV R2, #0x8000
    STR R2, [R8,#0x900]        @ USB2 Gadget: Endpoint 0 IN Control: ACTIVE
    STR R2, [R8,#0xB00]        @ USB2 Gadget: Endpoint 0 OUT Control: ACTIVE
    SUB R5, R12, #1
    STR R5, [R8,#0x908]        @ USB2 Gadget: Endpoint 0 IN Interrupt: ALL
    STR R5, [R8,#0xB08]        @ USB2 Gadget: Endpoint 0 OUT Interrupt: ALL
    LDR R2, val_20080040
    STR R2, [R8,#0xB10]        @ USB2 Gadget: Endpoint 0 OUT Transfer Size: 64 Bytes, 1 Packet, 1 Setup Packet
    LDR R2, val_usb_ctrl_recvbuf
    STR R2, [R8,#0xB14]        @ USB2 Gadget: Endpoint 0 OUT DMA Address
    LDR R2, [R8,#0xB00]
    ORR R2, R2, #0x84000000
    STR R2, [R8,#0xB00]        @ USB2 Gadget: Endpoint 0 OUT Control: ENABLE CLEARNAK
    LDR R2, val_00088210
    STR R2, [R8,#0x960]        @ USB2 Gadget: Endpoint 3 IN Control: ACTIVE BULK, 528 byte packets
    STR R2, [R8,#0xB80]        @ USB2 Gadget: Endpoint 4 OUT Control: ACTIVE BULK, 528 byte packets
    STR R5, [R8,#0x968]        @ USB2 Gadget: Endpoint 3 IN Interrupt: ALL
    STR R5, [R8,#0xB88]        @ USB2 Gadget: Endpoint 4 OUT Interrupt: ALL
    LDR R2, val_00080210
    STR R2, [R8,#0xB90]        @ USB2 Gadget: Endpoint 4 OUT Transfer Size: 528 Bytes, 1 Packet
    LDR R2, val_usb_recvbuf
    STR R2, [R8,#0xB94]        @ USB2 Gadget: Endpoint 4 OUT DMA Address
    LDR R2, [R8,#0xB80]
    ORR R2, R2, #0x94000000
    STR R2, [R8,#0xB80]        @ USB2 Gadget: Endpoint 4 OUT Control: ENABLE CLEARNAK DATA0
    MOV R2, #0x0D
    STR R2, [R8,#0x810]        @ USB2 Gadget: IN Endpoint Interrupt Mask
    STR R2, [R8,#0x814]        @ USB2 Gadget: OUT Endpoint Interrupt Mask
    STR R5, [R8,#0x81C]        @ USB2 Gadget: Enable interrupts on all endpoints
  noreset:
  TST R3, #0x00040000        @ IN endpoint event
  BEQ noinevent
    LDR R4, [R8,#0x908]        @ Just ACK them all...
    STR R4, [R8,#0x908]
    LDR R4, [R8,#0x968]
    STR R4, [R8,#0x968]
  noinevent:
  TST R3, #0x00080000        @ OUT endpoint event
  BEQ nooutevent
    LDR R4, [R8,#0xB08]
    MOVS R4, R4                @ Event on OUT EP0
    BEQ noep0out
      TST R4, #8                 @ SETUP phase done
      BEQ controldone
        LDR R5, val_usb_ctrl_recvbuf
        LDRB R6, [R5,#0x01]        @ Get request type
        CMP R6, #0
          BEQ GET_STATUS
        CMP R6, #1
          BEQ CLEAR_FEATURE
        CMP R6, #3
          BEQ SET_FEATURE
        CMP R6, #5
          BEQ SET_ADDRESS
        CMP R6, #6
          BEQ GET_DESCRIPTOR
        CMP R6, #8
          BEQ GET_CONFIGURATION
        CMP R6, #9
          BEQ SET_CONFIGURATION
        ctrlstall:
        LDR R1, [R8,#0x900]
        ORR R1, R1, #0x00200000
        STR R1, [R8,#0x900]        @ Stall IN EP0
        LDR R1, [R8,#0xB00]
        ORR R1, R1, #0x00200000
        STR R1, [R8,#0xB00]        @ Stall OUT EP0
      controldone:
      BL flushcache
      LDR R1, val_20080040
      STR R1, [R8,#0xB10]        @ OUT EP0: 64 Bytes, 1 Packet, 1 Setup Packet
      LDR R1, val_usb_ctrl_recvbuf
      STR R1, [R8,#0xB14]        @ OUT EP0: DMA address
      LDR R1, [R8,#0xB00]
      ORR R1, R1, #0x84000000
      STR R1, [R8,#0xB00]        @ OUT EP0: Enable ClearNAK
    noep0out:
    STR R4, [R8,#0xB08]        @ ACK it, whatever it was...
    LDR R4, [R8,#0xB88]
    MOVS R4, R4                @ Event on OUT EP4
    BEQ noep1out
      TST R4, #1                 @ XFER complete
      BEQ datadone
      xfercomplete:
        LDR R0, val_usb_recvbuf
        LDR R1, [R0]
        LDR R2, [R0,#0x04]
        CMP R1, #0                 @ PING
          BEQ sendsuccess
        CMP R1, #1                 @ GET INFO
          BEQ sendinfo
        CMP R1, #2                 @ RESTART, no feedback
          BEQ init
        CMP R1, #3                 @ RESET, no feedback
          BEQ reset  
        CMP R1, #4                 @ FASTREAD
        BNE nofastread
	  BL flushcache
          LDR R1, [R0,#0x08]
          MOV R6, R1,LSL#2
          LDR R0, val_usb_sendbuf
          ADD R0, R0, #0x10
          fastcopydata:
            LDR R5, [R2], #4
            STR R5, [R0], #4
            SUBS R1, R1, #1
          BNE fastcopydata
          B readdone
        nofastread:
        CMP R1, #5                 @ READ
        BNE noread
	  BL flushcache
          LDR R1, [R0,#0x08]
          MOV R6, R1
          LDR R0, val_usb_sendbuf
          ADD R0, R0, #0x10
          copydata:
            LDRB R5, [R2], #1
            STRB R5, [R0], #1
            SUBS R1, R1, #1
          BNE copydata
        readdone:
          ADD R1, R6, #0x10
          B sendsuccesscustomsize
        noread:
        CMP R1, #6                 @ FASTWRITE
        BNE nofastwrite
          LDR R1, [R0,#0x08]
          ADD R0, R0, #0x10
          fastcopydata2:
            LDR R5, [R0], #4
            STR R5, [R2], #4
            SUBS R1, R1, #1
          BNE fastcopydata2
	  BL flushcache
          B sendsuccess
        nofastwrite:
        CMP R1, #7                 @ WRITE
        BNE nowrite
          LDR R1, [R0,#0x08]
          ADD R0, R0, #0x10
          copydata2:
            LDRB R5, [R0], #1
            STRB R5, [R2], #1
            SUBS R1, R1, #1
          BNE copydata2
	  BL flushcache
          B sendsuccess
        nowrite:
        CMP R1, #9                 @ UPDATE_LCD
        BNE noupdatelcd
          CMP R2, #0x40000000
          LDRGE R2, val_usb_recvbuf
          ADDGE R2, R2, #0x10
          ORREQ R2, R2, #0x40000000
          LDR R5, [R0,#0x08]
          LDR R9, [R0,#0x0c]
          BL displaylcd
          B sendsuccess
        noupdatelcd:
        CMP R1, #8                 @ EXECUTE, no feedback
        BNE noexecute
          LDR R5, [R0,#0x08]
          LDR R6, val_debug_end
          MOV R7, R2
          MOV R9, #0x13
          LDR R10, val_target_regs
          ADD R10, R10, #0x34
          STMIA R10, {R5-R7,R9,R11,R12}
          MCREQ p15, 0, R12,c7,c5    @ Flush ICache
          B datadone
        noexecute:
        CMP R1, #0x0A              @ GET_TARGET_STATUS
        BNE nogettargetstatus
          LDR R6, val_target_regs
          MOV R1, #0x13
          LDR R0, val_usb_sendbuf
          ADD R0, R0, #0x10
          copytargetstatus:
            LDR R5, [R6], #4
            STR R5, [R0], #4
            SUBS R1, R1, #1
          BNE copytargetstatus
          ADDS R5, R2, #1
          STRNE R2, [R6,#-0x04]
          MOV R1, #0x5C
          B sendsuccesscustomsize
        nogettargetstatus:
        CMP R1, #0x0B              @ PUT_TARGET_STATUS
        BNE noputtargetstatus
          LDR R6, val_target_regs
          MOV R1, #0x13
          ADD R0, R0, #0x10
          copytargetstatus2:
            LDR R5, [R0], #4
            STR R5, [R6], #4
            SUBS R1, R1, #1
          BNE copytargetstatus2
          B sendsuccess
        noputtargetstatus:
        CMP R1, #0x0C              @ I2C_READ
        BNE noi2cread
          MOV R10, #0x3C000000
          ADD R10, R10, #0x00900000
          STR R12, [R10,#0x08]
          LDRB R2, [R0,#0x05]
          STR R2, [R10,#0x0C]
          MOV R6, #0xF0
          STR R6, [R10,#0x04]
          MOV R6, #0xF3
          STR R6, [R10]
          BL i2cwait
          LDRB R5, [R0,#0x06]
          STR R5, [R10,#0x0C]
          STR R6, [R10]
          BL i2cwait
          ORR R2, R2, #1
          STR R2, [R10,#0x0C]
          MOV R5, #0xB0
          STR R5, [R10,#0x04]
          STR R6, [R10]
          BL i2cwait
          LDRB R9, [R0,#0x07]
          LDR R7, val_usb_sendbuf
          ADD R7, R7, #0x10
          i2creadbyte:
            SUBS R9, R9, #1
            MOVEQ R6, #0x73
            STR R6, [R10]
            BL i2cwait
            LDR R5, [R10,#0x0C]
            STRB R5, [R7], #1
            CMP R9, #0
          BNE i2creadbyte
          MOV R6, #0x90
          STR R6, [R10,#0x04]
          MOV R6, #0xF3
          STR R6, [R10]
          i2cwait5:
            LDR R5, [R10,#0x04]
            TST R5, #0x20
          BNE i2cwait5
          LDRB R1, [R0,#0x07]
          ADD R1, R1, #0x10
          B sendsuccesscustomsize
        noi2cread:
        CMP R1, #0x0D              @ I2C_WRITE
        BNE noi2cwrite
          MOV R10, #0x3C000000
          ADD R10, R10, #0x00900000
          STR R12, [R10,#0x08]
          LDRB R2, [R0,#0x05]
          STR R2, [R10,#0x0C]
          MOV R6, #0xF0
          STR R6, [R10,#0x04]
          MOV R6, #0xF3
          STR R6, [R10]
          BL i2cwait
          LDRB R5, [R0,#0x06]
          STR R5, [R10,#0x0C]
          STR R6, [R10]
          BL i2cwait
          LDRB R9, [R0,#0x07]
          ADD R7, R0, #0x10
          i2cwritebyte:
            LDRB R5, [R7], #1
            STR R5, [R10,#0x0C]
            STR R6, [R10]
            BL i2cwait
            SUBS R9, R9, #1
          BNE i2cwritebyte
          MOV R5, #0xD0
          STR R5, [R10,#0x04]
          STR R6, [R10]
          i2cwait9:
            LDR R5, [R10,#0x04]
            TST R5, #0x20
          BNE i2cwait9
          B sendsuccess
        noi2cwrite:
        CMP R1, #0x0E              @ CONSOLE_READ
        BNE noconsoleread
          LDR R0, val_debug_sendbuf
          LDR R1, val_usb_sendbuf
          ADD R1, R1, #0x10
          LDR R5, val_debug_sendbuf_writeptr
          LDR R5, [R5]
          LDR R7, val_debug_sendbuf_readptr
          LDR R6, [R7]
          consolereadnextbyte:
            CMP R5, R6
            BEQ consolereaddone
            ADD R9, R0, R6
            ADD R6, R6, #1
            BIC R6, R6, #0x8000
            STR R6, [R7]
            LDRB R9, [R9]
            STRB R9, [R1], #1
            SUBS R2, R2, #1
          BNE consolereadnextbyte
          consolereaddone:
          ADR LR, datadone
          LDR R2, val_usb_sendbuf
          SUB R1, R1, R2
          SUB R0, R1, #0x10
          STR R11, [R2]
          STR R0, [R2,#0x04]
          STR R12, [R2,#0x08]
          STR R12, [R2,#0x0c]
          B datasend
        noconsoleread:
        CMP R1, #0x0F              @ CONSOLE_WRITE
        BNE sendunknownfunc
          ADD R1, R0, #0x10
          LDR R0, val_debug_recvbuf
          LDR R5, val_debug_recvbuf_readptr
          LDR R5, [R5]
          SUB R5, R5, #1
          LDR R7, val_000003ff
          AND R5, R5, R7
          LDR R7, val_debug_recvbuf_writeptr
          LDR R6, [R7]
          consolewritenextbyte:
            CMP R5, R6
            BEQ consolewritedone
            ADD R9, R0, R6
            ADD R6, R6, #1
            BIC R6, R6, #0x400
            STR R6, [R7]
            LDRB R10, [R1], #1
            STRB R10, [R9]
            SUBS R2, R2, #1
          BNE consolewritenextbyte
          consolewritedone:
          ADR LR, datadone
          LDR R2, val_usb_sendbuf
          LDR R0, val_usb_recvbuf
          SUB R1, R1, R0
          SUB R0, R1, #0x10
          STR R11, [R2]
          STR R0, [R2,#0x04]
          STR R12, [R2,#0x08]
          STR R12, [R2,#0x0c]
          MOV R1, #0x10
          B datasend
        sendsuccess:
          MOV R1, #0x10
          @ fallthrough
        sendsuccesscustomsize:
          LDR R2, val_usb_sendbuf
          STMIA R2, {R11, R12}
          @ fallthrough
        sendlast2zero:
	  ADR LR, datadone
          STR R12, [R2,#0x08]
          STR R12, [R2,#0x0C]
          @ fallthrough
        datasend:
          BL flushcache
          LDR R0, val_00088210
          STR R0, [R8,#0x960]        @ EP3 IN: ACTIVE BULK, 528 byte packets
          ORR R1, R1, #0x20000000    @ 1 Packet at a time
          ORR R1, R1, #0x00080000    @ 1 Packet
          STR R1, [R8,#0x970]        @ EP3 IN: 1 Packet, 1 Packet at a time, Size as in R1
          STR R2, [R8,#0x974]        @ EP3 IN: DMA address
          LDR R1, [R8,#0x960]
          ORR R1, R1, #0x84000000
          STR R1, [R8,#0x960]        @ EP3 IN: Enable ClearNAK
      datadone:
      BL flushcache
      LDR R1, val_00080210
      STR R1, [R8,#0xB90]        @ OUT EP4: 528 Bytes, 1 Packet
      LDR R1, val_usb_recvbuf
      STR R1, [R8,#0xB94]        @ Out EP4: DMA address
      LDR R1, [R8,#0xB80]
      ORR R1, R1, #0x84000000
      STR R1, [R8,#0xB80]        @ Out EP4: Enable ClearNAK
    noep1out:
    STR R4, [R8,#0xB88]        @ ACK it, whatever it was...
  nooutevent:
  STR R3, [R8,#0x14]         @ ACK it, whatever it was...

nousbint:
	mov	r11, #0x39C00000
	mov	r0, #0x00010000
	str	r0, [r11]
	str	r0, [r11,#0x10]
	ldr	r12, val_target_regs
	ldr	r0, [r12,#0x48]
	cmp	r0, #0
	ldrne	lr, val_debuggeridle
	movnes	pc, lr
	ldr	r0, [r12,#0x40]
	msr	spsr_all, r0
	mrs r1, cpsr
	orr r0, r0, #0xc0
	msr cpsr_c, r0
	ldr sp, [r12,#0x34]
	ldr lr, [r12,#0x38]
	msr cpsr_c, r1
	ldr lr, [r12,#0x3C]
	ldmia	r12, {r0-r12}
	movs pc, lr

reset:
  MSR CPSR_c, #0xD3          @ Supervisor mode, no IRQs, no FIQs
  MOV R5, #0x110000
  ADD R5, R5, #0xFF
  ADD R6, R5, #0xA00
  MOV R10, #0x3C800000
  STR R6, [R10]    
  MOV R6, #0xFF0
  STR R6, [R10,#4]
  STR R5, [R10]
@ fallthrough

hang:
B hang

sendinfo:
  LDR R2, val_usb_sendbuf
  LDR R0, val_version
  MOV R1, #2
  LDR R5, [R8,#808]
  TST R5, #2
  MOVEQ R5, #0x210
  MOVNE R5, #0x40
  ORR R5, R5, R5,LSL#16
  STMIA R2, {R0,R1,R5,R12}
  MOV R1, #0x10
B datasend

sendunknownfunc:
  BL handlerequest
  ADR LR, datadone
  CMN R0, #1
  MOVEQ PC, LR
  MOVS R1, R0
  LDR R2, val_usb_sendbuf
  BNE datasend
  MOV R1, #2
  STMIA R2, {R1, R12}
  MOV R1, #0x10
B sendlast2zero

GET_DESCRIPTOR:
  LDRB R7, [R5,#3]           @ Descriptor type
  CMP R7, #1
    ADREQ R0, devicedescriptor
    BEQ senddescriptor
  CMP R7, #2
    ADREQ R0, configurationdescriptor
    MOVEQ R1, #0x20
    BEQ senddescriptorcustomsize
  CMP R7, #3
  BNE ctrlstall
  LDRB R7, [R5,#2]           @ String descriptor index
  CMP R7, #0
    ADREQ R0, langstringdescriptor
    BEQ senddescriptor
  CMP R7, #1
  CMPNE R7, #2
    ADREQ R0, devnamestringdescriptor
  BNE ctrlstall
@ fallthrough

senddescriptor:
  LDRB R1, [R0]              @ Descriptor length
@ fallthrough

senddescriptorcustomsize:
  LDRH R5, [R5,#0x06]        @ Requested length
  CMP R5, R1
  MOVLO R1, R5
  LDR R2, val_usb_ctrl_sendbuf
  ADD R6, R1, R2
  copydescriptor:
    LDR R5, [R0], #4
    STR R5, [R2], #4
    CMP R2, R6
  BCC copydescriptor
B ctrlsend

GET_STATUS:
  LDRB R1, [R5]
  CMP R1, #0x80
  LDR R0, val_usb_ctrl_sendbuf
  STREQ R11, [R0]
  STRNE R12, [R0]
  MOV R1, #0x00000002
B ctrlsend

CLEAR_FEATURE:
  LDRB R2, [R5]
  CMP R2, #2
  LDREQ R2, [R5,#2]
  BICEQ R2, R2, #0x00800000
  CMPEQ R2, #0x00010000
@ fallthrough

SET_CONFIGURATION:
  LDREQ R2, [R8,#0x960]
  ORREQ R2, R2, #0x10000000
  STREQ R2, [R8,#0x960]      @ EP3 IN: Set DATA0 PID
  LDREQ R2, [R8,#0xB80]
  ORREQ R2, R2, #0x10000000
  STREQ R2, [R8,#0xB80]      @ EP4 OUT: Set DATA0 PID
B SET_FEATURE              @ zero-length ACK

SET_ADDRESS:
  LDRH R2, [R5,#0x02]        @ new address
  LDR R1, [R8,#0x800]
  BIC R1, R1, #0x000007F0
  ORR R1, R1, R2,LSL#4
  STR R1, [R8,#0x800]        @ set new address
@ fallthrough

SET_FEATURE:
  MOV R1, #0                 @ zero-length ACK
B ctrlsend

GET_CONFIGURATION:
  MOV R1, #0x00000001
  STR R1, [R0]
@ fallthrough

ctrlsend:
  BL flushcache
  LDR R0, val_usb_ctrl_sendbuf @ Buffer to be sent
  MOV R2, #0x00009800
  STR R2, [R8,#0x900]        @ EP0 IN: ACTIVE
  ORR R1, R1, #0x00080000    @ 1 Packet
  STR R1, [R8,#0x910]        @ EP0 IN: 1 Packet, Size as in R1
  STR R0, [R8,#0x914]        @ EP0 IN: DMA address
  LDR R1, [R8,#0x900]
  ORR R1, R1, #0x84000000
  STR R1, [R8,#0x900]        @ EP0 IN: Enable ClearNAK
B controldone

i2cwait:
  LDR R5, [R10]
  TST R5, #0x10
BEQ i2cwait
MOV PC, LR

sendlcd2c:
  STRH R12, [R1,#0x04]
waitlcd2c:
  LDRH R12, [R1, #0x1C]
  ANDS R12, R12, #0x10
  BNE waitlcd2c
sendlcdc:
  STRH R0, [R1,#0x04]
  B waitlcd
sendlcd2d:
  STRH R12, [R1,#0x40]
waitlcd2d:
  LDRH R12, [R1, #0x1C]
  ANDS R12, R12, #0x10
  BNE waitlcd2d
sendlcdd:
  AND R0, R0, #0xFF
  STRH R0, [R1,#0x40]
waitlcd:
  LDRH R0, [R1, #0x1C]
  ANDS R0, R0, #0x10
  BNE waitlcd
MOV PC, LR

displaylcd:
  MOV R7, LR
  MOV R1, #0x3C000000
  ADD R1, R1, #0x00F00000
  LDR R0, [R1,#0xD0]
  BIC R0, R0, #0x0F
  STR R0, [R1,#0xD0]
  LDR R0, [R1,#0xE0]
  BIC R0, R0, #0xF0
  STR R0, [R1,#0xE0]
  LDR R0, [R1,#0xD4]
  AND R0, R0, #1
  LDR R10, [R1,#0xE4]
  AND R10, R10, #2
  ORR R10, R0, R10
  SUB R1, R1, #0x04900000
  CMP R10, #2                @ Type 2 LCD
  BNE othertypes
    MOV R0, #0x50
    BL sendlcd2c
    MOV R0, R5
    BL sendlcd2d
    MOV R0, #0x51
    BL sendlcd2c
    MOV R0, R5,LSR#16
    BL sendlcd2d
    MOV R0, #0x52
    BL sendlcd2c
    MOV R0, R9
    BL sendlcd2d
    MOV R0, #0x53
    BL sendlcd2c
    MOV R0, R9,LSR#16
    BL sendlcd2d
    MOV R0, #0x20
    BL sendlcd2c
    MOV R0, R5
    BL sendlcd2d
    MOV R0, #0x21
    BL sendlcd2c
    MOV R0, R9
    BL sendlcd2d
    MOV R0, #0x22
    BL sendlcd2c
    B blit
  othertypes:                @ Other LCD types
    MOV R0, #0x2A
    BL sendlcdc
    BL sendlcdd
    MOV R0, R5
    BL sendlcdd
    BL sendlcdd
    MOV R0, R5,LSR#16
    BL sendlcdd
    MOV R0, #0x2B
    BL sendlcdc
    BL sendlcdd
    MOV R0, R9
    BL sendlcdd
    BL sendlcdd
    MOV R0, R9,LSR#16
    BL sendlcdd
    MOV R0, #0x2C
    BL sendlcdc
  blit:
  MOV R0, R5,LSR#16
  MOV R12, R5,LSL#16
  SUB R0, R0, R12,LSR#16
  ADD R0, R0, #1
  MOV R5, R9,LSR#16
  MOV R12, R9,LSL#16
  SUB R5, R5, R12,LSR#16
  ADD R5, R5, #1
  MUL R12, R0, R5
  loop:
    LDRB R9, [R2]
    LDRB R0, [R2, #1]
    TST R2, #0x40000000
    ADDEQ R2, R2, #2
    BL sendlcdd
    MOV R0, R9
    BL sendlcdd
    SUBS R12, R12, #1
  BNE loop
MOV PC, R7

val_00080210:
.word 0x00080210

val_00088210:
.word 0x00088210

val_20080040:
.word 0x20080040

val_000003ff:
.word 0x000003ff

val_usb_ctrl_sendbuf:
.word usb_ctrl_sendbuf

val_usb_ctrl_recvbuf:
.word usb_ctrl_recvbuf

val_usb_sendbuf:
.word usb_sendbuf

val_usb_recvbuf:
.word usb_recvbuf

devicedescriptor:
.word 0x02000112
.word 0x40FFFFFF
.word 0x8642FFFF
.word 0x02010001
.word 0x00010100

configurationdescriptor:
.word 0x00200209
.word 0xC0000101
.word 0x00040932
.word 0xFFFF0200
.word 0x050700FF
.word 0x02100204
.word 0x83050701
.word 0x01021002

langstringdescriptor:
.word 0x04090304

devnamestringdescriptor:
.word 0x00550320
.word 0x0069006E
.word 0x00690066
.word 0x00640065
.word 0x00690020
.word 0x00750042
.word 0x00670067
.word 0x00720065

val_version:
.word 0x1010100

