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
 

start:
MSR CPSR_c, #0xD3          @ Supervisor mode, no IRQs, no FIQs

MOV R0, #0x00050000
ORR R0, #0x00000078
MCR p15, 0, R0, c1, c0, 0  @ Get rid of some CPU "features" likely to cause trouble

MOV R8, #0x38400000        @ OTG base
MOV R9, #0x3C400000        @ PHY base
ADD R10, R9, #0x00100000   @ PWRCON base
MOV R11, #1
MOV R12, #0

LDR R0, [R10,#0x48]        @ Open USB clock gates
BIC R0, R0, #4
STR R0, [R10,#0x48]
LDR R0, [R10,#0x4C]
BIC R0, R0, #8
STR R0, [R10,#0x4C]

LDR R0, [R8,#0xE00]        @ PHY clock enable
BIC R0, R0, #3
STR R0, [R8,#0xE00]

LDR R10, [R8,#0x804]
ORR R0, R10, #2
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
MOV R0, #0x26
STR R0, [R8,#0x08]         @ USB2 Gadget: DMA Enable, Burst Length: 8, Mask Interrupts
MOV R0, #0x1400
ADD R0, R0, #8
STR R0, [R8,#0x0C]         @ USB2 Gadget: PHY IF is 16bit, Turnaround 5 (???)

STR R10, [R8,#0x804]        @ USB2 Gadget: Soft reconnect

@ fallthrough

mainloop:
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
    MOV R2, #0x22000000
    ORR R2, R2, #0x2000
    STR R2, [R8,#0xB14]        @ USB2 Gadget: Endpoint 0 OUT DMA Address: 0x22002000
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
    MOV R2, #0x22000000
    ORR R2, R2, #0x4000
    STR R2, [R8,#0xB94]        @ USB2 Gadget: Endpoint 4 OUT DMA Address: 0x22004000
    LDR R2, [R8,#0xB80]
    ORR R2, R2, #0x94000000
    STR R2, [R8,#0xB80]        @ USB2 Gadget: Endpoint 4 OUT Control: ENABLE CLEARNAK DATA0
    STR R5, [R8,#0x810]        @ USB2 Gadget: IN Endpoint Interrupt Mask: ALL
    STR R5, [R8,#0x814]        @ USB2 Gadget: OUT Endpoint Interrupt Mask: ALL
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
        MOV R5, #0x22000000
        ORR R5, R5, #0x2000
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
      LDR R1, val_20080040
      STR R1, [R8,#0xB10]        @ OUT EP0: 64 Bytes, 1 Packet, 1 Setup Packet
      MOV R1, #0x22000000
      ORR R1, R1, #0x2000
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
        MOV R0, #0x22000000
        ORR R0, R0, #0x4000
        LDR R1, [R0]
        LDR R2, [R0,#0x04]
        CMP R1, #0                 @ PING
          BEQ sendsuccess
        CMP R1, #1                 @ GET INFO
          BEQ sendinfo
        CMP R1, #2                 @ RESTART, no feedback
          BEQ start
        CMP R1, #3                 @ RESET, no feedback
          MOVEQ R5, #0x100000
          MOVEQ R6, #0x3C800000
          STREQ R5, [R6]    
        CMP R1, #8                 @ EXECUTE, no feedback
          LDR SP, [R0,#0x08]
          ADREQ LR, start
          MOVEQ PC, R2
        CMP R1, #4                 @ FASTREAD
        BNE nofastread
          LDR R1, [R0,#0x08]
          MOV R6, R1,LSL#2
          MOV R0, #0x22000000
          ORR R0, R0, #0x5000
          ORR R0, R0, #0x10
          fastcopydata:
            LDR R5, [R2], #4
            STR R5, [R0], #4
            SUBS R1, R1, #1
          BNE fastcopydata
          B readdone
        nofastread:
        CMP R1, #5                 @ READ
        BNE noread
          LDR R1, [R0,#0x08]
          MOV R6, R1
          MOV R0, #0x22000000
          ORR R0, R0, #0x5000
          ORR R0, R0, #0x10
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
          B sendsuccess
        nowrite:
        CMP R1, #0x0C              @ I2C_READ
        BNE noi2cread
          LDRB R2, [R0,#0x04]
          CMP R2, #1
          MOV R10, #0x3C000000
          ADDNE R10, R10, #0x00600000
          ADDEQ R10, R10, #0x00900000
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
          MOV R7, #0x22000000
          ORR R7, R7, #0x5000
          ORR R7, R7, #0x10
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
        BNE sendunknownfunc
          LDRB R2, [R0,#0x04]
          CMP R2, #1
          MOV R10, #0x3C000000
          ADDNE R10, R10, #0x00600000
          ADDEQ R10, R10, #0x00900000
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
          @ fallthrough
        sendsuccess:
          MOV R1, #0x10
          @ fallthrough
        sendsuccesscustomsize:
          MOV R2, #0x22000000
          ORR R2, R2, #0x5000
          STMIA R2, {R11, R12}
          @ fallthrough
        sendlast2zero:
          STR R12, [R2,#0x08]
          STR R12, [R2,#0x0C]
          @ fallthrough
        datasend:
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
      LDR R1, val_00080210
      STR R1, [R8,#0xB90]        @ OUT EP4: 528 Bytes, 1 Packet
      MOV R1, #0x22000000
      ORR R1, R1, #0x4000
      STR R1, [R8,#0xB94]        @ Out EP4: DMA address
      LDR R1, [R8,#0xB80]
      ORR R1, R1, #0x84000000
      STR R1, [R8,#0xB80]        @ Out EP4: Enable ClearNAK
    noep1out:
    STR R4, [R8,#0xB88]        @ ACK it, whatever it was...
  nooutevent:
  STR R3, [R8,#0x14]         @ ACK it, whatever it was...
B mainloop

sendunknownfunc:
  MOV R0, #2
  MOV R1, #0x10
  MOV R2, #0x22000000
  ORR R2, R2, #0x5000
  STMIA R2, {R0, R12}
B sendlast2zero

sendinfo:
  MOV R2, #0x22000000
  ORR R2, R2, #0x5000
  LDR R0, val_version
  MOV R1, #0x10
  LDR R5, [R8,#808]
  TST R5, #2
  MOVEQ R5, #0x210
  MOVNE R5, #0x40
  ORR R5, R5, R5,LSL#16
  STMIA R2, {R0,R1,R5,R12}
  MOV R1, #0x10
B datasend

sleep10ms:
  mov R0, #0x00100000
@ fallthrough

sleeploop:
  SUBS R0, R0, #1
  BNE sleeploop
MOV PC, LR

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
  MOV R2, #0x22000000
  ORR R2, R2, #0x3000
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
  MOV R0, #0x22000000
  ORR R0, R0, #0x3000
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
  MOV R0, #0x22000000
  ORR R0, R0, #0x3000
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

val_00080210:
.word 0x00080210

val_00088210:
.word 0x00088210

val_20080040:
.word 0x20080040

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
.word 0x10100

