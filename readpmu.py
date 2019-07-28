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

if dev.devtype == 2:
  weekdays = ("Monday", "Tuesday", "Wednesday", "Thursday",
              "Friday", "Saturday", "Sunday")
  rtc = struct.unpack("7B", dev.i2crecv(0, 0xe6, 0x59, 7))
  print("RTC: %s, %2X.%2X.%2X %2X:%2X:%2X"
      % (weekdays[rtc[3]], rtc[4], rtc[5], rtc[6], rtc[2], rtc[1], rtc[0]))

  dev.i2csend(0, 0xe6, 0x54, struct.pack("B", 0x05))
  data = 0
  while (data & 0x80) == 0:
    data = struct.unpack("B", dev.i2crecv(0, 0xe6, 0x57, 1))[0]
  voltage = (struct.unpack("B", dev.i2crecv(0, 0xe6, 0x55, 1))[0] << 2) | (data & 3)
  print("Battery voltage: %.3fV" % (voltage * 6. / 1024))

  dev.i2csend(0, 0xe6, 0x54, struct.pack("B", 0x25))
  data = 0
  while (data & 0x80) == 0:
    data = struct.unpack("B", dev.i2crecv(0, 0xe6, 0x57, 1))[0]
  current = (struct.unpack("B", dev.i2crecv(0, 0xe6, 0x55, 1))[0] << 2) | (data & 3)
  print("Current: %dmA" % current)

  print("Auto-up-down enable: %X" % (struct.unpack("B",dev.i2crecv(0, 0xe6, 0x1b, 1))[0] & 0xf))
  print("Auto-up-down output voltage: %.3fV" % (struct.unpack("B",dev.i2crecv(0, 0xe6, 0x1a, 1))[0] * 0.025 + 0.625))
  print("Step-down 1 enable: %X" % (struct.unpack("B",dev.i2crecv(0, 0xe6, 0x1f, 1))[0] & 0xf))
  print("Step-down 1 output voltage: %.3fV" % (struct.unpack("B",dev.i2crecv(0, 0xe6, 0x1e, 1))[0] * 0.025 + 0.625))
  print("Step-down 2 enable: %X" % (struct.unpack("B",dev.i2crecv(0, 0xe6, 0x23, 1))[0] & 0xf))
  print("Step-down 2 output voltage: %.3fV" % (struct.unpack("B",dev.i2crecv(0, 0xe6, 0x22, 1))[0] * 0.025 + 0.625))
  print("Memory LDO enable: %X" % (struct.unpack("B",dev.i2crecv(0, 0xe6, 0x27, 1))[0] & 0xf))
  print("Memory LDO output voltage: %.3fV" % ((struct.unpack("B",dev.i2crecv(0, 0xe6, 0x26, 1))[0] & 0x1F) * 0.1 + 0.9))
  print("LDO 1 enable: %X" % (struct.unpack("B",dev.i2crecv(0, 0xe6, 0x2e, 1))[0] & 0xf))
  print("LDO 1 output voltage: %.3fV" % ((struct.unpack("B",dev.i2crecv(0, 0xe6, 0x2d, 1))[0] & 0x1F) * 0.1 + 0.9))
  print("LDO 2 enable: %X" % (struct.unpack("B",dev.i2crecv(0, 0xe6, 0x30, 1))[0] & 0xf))
  print("LDO 2 output voltage: %.3fV" % ((struct.unpack("B",dev.i2crecv(0, 0xe6, 0x2f, 1))[0] & 0x1F) * 0.1 + 0.9))
  print("LDO 3 enable: %X" % (struct.unpack("B",dev.i2crecv(0, 0xe6, 0x32, 1))[0] & 0xf))
  print("LDO 3 output voltage: %.3fV" % ((struct.unpack("B",dev.i2crecv(0, 0xe6, 0x31, 1))[0] & 0x1F) * 0.1 + 0.9))
  print("LDO 4 enable: %X" % (struct.unpack("B",dev.i2crecv(0, 0xe6, 0x34, 1))[0] & 0xf))
  print("LDO 4 output voltage: %.3fV" % ((struct.unpack("B",dev.i2crecv(0, 0xe6, 0x33, 1))[0] & 0x1F) * 0.1 + 0.9))
  print("LDO 5 enable: %X" % (struct.unpack("B",dev.i2crecv(0, 0xe6, 0x36, 1))[0] & 0xf))
  print("LDO 5 output voltage: %.3fV" % ((struct.unpack("B",dev.i2crecv(0, 0xe6, 0x35, 1))[0] & 0x1F) * 0.1 + 0.9))
  print("LDO 6 enable: %X" % (struct.unpack("B",dev.i2crecv(0, 0xe6, 0x38, 1))[0] & 0xf))
  print("LDO 6 output voltage: %.3fV" % ((struct.unpack("B",dev.i2crecv(0, 0xe6, 0x37, 1))[0] & 0x1F) * 0.1 + 0.9))
  print("HCLDO enable: %X" % (struct.unpack("B",dev.i2crecv(0, 0xe6, 0x3A, 1))[0] & 0xf))
  print("HCLDO output voltage: %.3fV" % ((struct.unpack("B",dev.i2crecv(0, 0xe6, 0x39, 1))[0] & 0x1F) * 0.1 + 0.9))

else:
  print("Unsupported device: " + dev.devtype2name(dev.devtype))
