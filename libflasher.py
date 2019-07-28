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


def genflasher(addr, data):
  size = len(data)
  paddedsize = (size + 1) & 0xFFFFFFFE

  file = open(sys.path[0] + "/flasher/flasher.bin", "rb")
  code = file.read()
  file.close()

  offset = code.find("ADDR")
  code = code[:offset] + struct.pack("<I", addr) + code[offset + 4:]

  offset = code.find("SIZE")
  code = code[:offset] + struct.pack("<I", paddedsize) + code[offset + 4:]

  return code + data


def genflasherfile(addr, infile, outfile):
  file = open(infile, "rb")
  data = file.read()
  file.close()

  file = open(outfile, "wb")
  file.write(genflasher(addr, data))
  file.close()
