#!/usr/bin/env python
#
#
#    Copyright 2010 TheSeven
#
#
#    This file is part of TheSeven's iPod tools.
#
#    TheSeven's iBugger is free software: you can redistribute it and/or
#    modify it under the terms of the GNU General Public License as
#    published by the Free Software Foundation, either version 2 of the
#    License, or (at your option) any later version.
#
#    TheSeven's iBugger is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#    See the GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with TheSeven's iPod tools.  If not, see <http://www.gnu.org/licenses/>.
#
#


import sys
import time
import libibugger

if len(sys.argv) < 2:
  print "Syntax: runflasher.py <infile> [reboot]"
  exit(2)

dev = libibugger.ibugger(2)
if dev.type == 1: dev.startup()

dev.getstate(2)

dev.upload(0x08000000, sys.argv[1])
dev.execute(0x08000000, 0x0a000000)

sys.stdout.write("Waiting for flashing operation to complete...")
sys.stdout.flush()
while 0 < dev.getstate(-1)[8] < 0x80000000:
  sys.stdout.write(".")
  sys.stdout.flush()
  time.sleep(1)
print(" done")

dev.getstate(2)

if len(sys.argv) > 2: dev.reset()
