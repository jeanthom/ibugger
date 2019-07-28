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


import struct
import libibugger


dev = libibugger.ibugger()

gpio = dev.read(0x3CF00000, 0x100)

for i in range(0x10):
  mask = struct.unpack("<I", gpio[(i << 4):(i << 4) + 4])[0]
  data = struct.unpack("<I", gpio[(i << 4) + 4:(i << 4) + 8])[0]
  print("GPIO%2d MASK = %8X" % (i, mask))
  print("GPIO%2d DATA = %s\n" % (i, "".join([str((data >> y) & 1) for y in range(7, -1, -1)])))

