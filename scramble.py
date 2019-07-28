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
import struct

if len(sys.argv) != 5:
  print "Syntax: scramble.py <modelname> <modelid> <infile> <outfile>"
  exit(2)

file = open(sys.argv[3], "rb")
data = file.read()
file.close()

checksum = int(sys.argv[2])
for i in range(len(data)):
  checksum = (checksum  + struct.unpack("B", data[i])[0]) & 0xffffffff

file = open(sys.argv[4], "wb")
file.write(struct.pack(">I", checksum) + sys.argv[1] + data)
file.close()
