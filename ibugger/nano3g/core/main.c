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

extern char* usb_sendbuf;
extern char* usb_recvbuf;
extern unsigned int* target_regs;
extern int target_state;

#define STATE_RUNNING 0
#define STATE_BREAKPOINT 1
#define STATE_STARTUP 2
#define STATE_EXCEPTION_RESET 3
#define STATE_EXCEPTION_DATA 4
#define STATE_EXCEPTION_PREFETCH 5
#define STATE_EXCEPTION_UNDEFINED_INSTR 6
#define STATE_EXCEPTION_UNDEFINED_VECTOR 7
#define STATE_FINISHED 8

int handlerequest()
{
  return 0;
}
