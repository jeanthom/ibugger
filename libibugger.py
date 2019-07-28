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
import math
import struct
import time
import usb


class ibugger:
  def __init__(self, generation = 0, type = 0):
    busses = usb.busses()
 
    for bus in busses:
      devices = bus.devices
      for dev in devices:
        if dev.idVendor == 0xffff and dev.idProduct == 0x8642:
          handle = dev.open()
          handle.setConfiguration(1)
          handle.claimInterface(0)
          handle.bulkWrite(4, struct.pack("<IIII", 1, 0, 0, 0))
          data = self.__getbulk(handle, 0x83, 0x10)
          i = struct.unpack("<BBBBIHHI", data)
          if generation in [0, i[4]] and type in [0, i[3] + 1]:
            self.handle = handle
            self.major, self.minor, self.rev, self.type, self.devtype, self.maxout, self.maxin = i[:7]
            self.type = self.type + 1
            print("Connected to iBugger %s v%d.%d.%d on %s, USB version %s" \
                  % (self.type2name(self.type), self.major, self.minor, self.rev, \
                     self.devtype2name(self.devtype), dev.deviceVersion))
            if self.devtype == 2:
              self.maxout = 512
              self.maxin = 512
            return
          handle.releaseInterface()

    raise Exception("Could not find specified device (generation = %d, type = %d)" % (generation, type))


  @staticmethod
  def __myprint(data):
    sys.stdout.write(data)
    sys.stdout.flush()


  @staticmethod
  def __getbulk(handle, endpoint, size):
    data = handle.bulkRead(endpoint, size, 1000)
    return struct.pack("%dB" % len(data), *data)


  @staticmethod
  def __checkstatus(data):
    errorcode = struct.unpack("<I", data[:4])[0]
    if errorcode == 1:
      # everything went fine
      return
    elif errorcode == 2:
      print("\nError: Device doesn't support this function!")
      raise Exception("iBugger device doesn't support this function!")
    else:
      print("\nUnknown error %d" % errorcode)
      raise Exception("Unknown iBugger error %d" % errorcode)


  def __readstatus(self):
    return self.__getbulk(self.handle, 0x83, 0x10)


  @staticmethod
  def state2name(state):
    if state == 0: return "RUNNING"
    elif state == 1: return "BREAKPOINT"
    elif state == 2: return "STARTUP"
    elif state == 3: return "EXCEPTION_RESET"
    elif state == 4: return "EXCEPTION_DATA"
    elif state == 5: return "EXCEPTION_PREFETCH"
    elif state == 6: return "EXCEPTION_UNDEFINED_INSTR"
    elif state == 7: return "EXCEPTION_UNDEFINED_VECTOR"
    elif state == 8: return "FINISHED"
    else: return "UNKNOWN (%8x)" % state


  @staticmethod
  def type2name(type):
    if type == 1: return "Loader"
    elif type == 2: return "Core"
    else: return "UNKNOWN (%8x)" % type


  @staticmethod
  def devtype2name(devtype):
    if devtype == 2: return "iPod Nano 2G"
    elif devtype == 3: return "iPod Nano 3G"
    elif devtype == 4: return "iPod Nano 4G"
    elif devtype == 0x10: return "iPod Classic"
    else: return "UNKNOWN (%8x)" % devtype


  def write(self, offset, data, *range):
    if offset & 3 == 0:
      opcode = 6
      divisor = 4
    else:
      opcode = 7
      divisor = 1

    boffset = 0
    size = len(data)
    if len(range) > 0:
      boffset = range[0]
    if len(range) > 1:
      size = range[1]

    maxblk = self.maxout - 0x10

    while True:
      blocklen = size
      if blocklen == 0: break
      if blocklen > maxblk: blocklen = maxblk
      if blocklen & 3 != 0:
        opcode = 7
        divisor = 1
      self.handle.bulkWrite(4, struct.pack("<IIII", opcode, offset, int(blocklen / divisor), 0) \
                             + data[boffset:boffset+blocklen])
      self.__checkstatus(self.__readstatus())
      offset += blocklen
      boffset += blocklen
      size -= blocklen


  def read(self, offset, size):
    if offset & 3 == 0:
      opcode = 4
      divisor = 4
    else:
      opcode = 5
      divisor = 1

    maxblk = self.maxin - 0x10

    data = ""

    while True:
      blocklen = size
      if blocklen == 0: break
      if blocklen > maxblk: blocklen = maxblk
      if blocklen & 3 != 0:
        opcode = 5
        divisor = 1
      self.handle.bulkWrite(4, struct.pack("<IIII", opcode, offset, int(blocklen / divisor), 0))
      block = self.__getbulk(self.handle, 0x83, 0x10 + blocklen)
      self.__checkstatus(block)
      offset += blocklen
      data += block[0x10:]
      size -= blocklen

    return data


  def i2crecv(self, bus, slave, addr, size):
    self.handle.bulkWrite(4, struct.pack("<IBBBBII", 0xc, bus, slave, addr, size, 0, 0))
    data = self.__getbulk(self.handle, 0x83, 0x10 + size)
    self.__checkstatus(data)
    return data[16:]


  def i2csend(self, bus, slave, addr, data):
    self.handle.bulkWrite(4, struct.pack("<IBBBBII", 0xd, bus, slave, addr, len(data), 0, 0) + data)
    self.__checkstatus(self.__readstatus())


  def getstate(self, newstate):
    self.handle.bulkWrite(4, struct.pack("<IiII", 0xa, newstate, 0, 0))
    data = self.__getbulk(self.handle, 0x83, 0x5c)
    self.__checkstatus(data)
    return struct.unpack("<IIIIIIIIIIIIIIIIIII", data[16:])


  def putstate(self, newstate):
    self.handle.bulkWrite(4, struct.pack("<IIIIIIIIIIIIIIIIIIIIIII", 0xb, 0, 0, 0, *newstate))
    self.__checkstatus(self.__readstatus())


  def backlighton(self, fade, brightness):
    self.__myprint("Turning on backlight...")
    if self.devtype == 2:
      self.i2csend(0, 0xe6, 0x2b, struct.pack("<B", fade))
      self.i2csend(0, 0xe6, 0x28, struct.pack("<B", int(brightness * 46)))
      self.i2csend(0, 0xe6, 0x29, struct.pack("<B", 1))
      self.__myprint(" done\n")
    elif self.devtype == 4:
      self.i2csend(0, 0xe6, 0x30, struct.pack("<B", int(brightness * 250)))
      self.i2csend(0, 0xe6, 0x31, struct.pack("<B", 3))
      self.__myprint(" done\n")
    else: self.__myprint(" unsupported (%s)\n" % self.devtype2name(self.devtype))


  def backlightoff(self, fade):
    self.__myprint("Turning off backlight...")
    if self.devtype == 2:
      self.i2csend(0, 0xe6, 0x2b, struct.pack("<B", fade))
      self.i2csend(0, 0xe6, 0x29, struct.pack("<B", 0))
      self.__myprint(" done\n")
    elif self.devtype == 4:
      self.i2csend(0, 0xe6, 0x31, struct.pack("<B", 2))
      self.__myprint(" done\n")
    else: self.__myprint(" unsupported (%s)\n" % self.devtype2name(self.devtype))


  def restart(self):
    self.__myprint("Restarting iBugger %s..." % self.type2name(self.type))
    self.handle.bulkWrite(4, struct.pack("<IIII", 2, 0, 0, 0))
    self.__myprint(" done\n")


  def reset(self):
    self.__myprint("Resetting device...")
    self.handle.bulkWrite(4, struct.pack("<IIII", 3, 0, 0, 0))
    self.__myprint(" done\n")


  def execute(self, addr, stack):
    self.__myprint("Passing control to code at 0x%8x..." % addr)
    self.handle.bulkWrite(4, struct.pack("<IIII", 8, addr, stack, 0))
    self.__myprint(" done\n")


  def updatelcd(self, addr, startx, endx, starty, endy, color, data):
    self.__myprint("Updating LCD...")
    if addr == 0x40000000:
      self.handle.bulkWrite(4, struct.pack("<IIHHHHH", 9, addr, startx, endx, starty, endy, color))
    else:
      self.handle.bulkWrite(4, struct.pack("<IIHHHH", 9, addr, startx, endx, starty, endy) + data)
    self.__checkstatus(self.__readstatus())
    self.__myprint(" done\n")


  def consoleread(self, maxbytes):
    if maxbytes > self.maxin - 0x10:
      maxbytes = self.maxin - 0x10
    self.handle.bulkWrite(4, struct.pack("<IIII", 0xe, maxbytes, 0, 0))
    data = self.__getbulk(self.handle, 0x83, maxbytes + 0x10)
    self.__checkstatus(data)
    return data[0x10 : 0x10 + struct.unpack("<IIII", data[:0x10])[1]]


  def consolewrite(self, data):
    self.handle.bulkWrite(4, struct.pack("<IIII", 0xf, len(data), 0, 0) + data)
    status = self.__readstatus()
    self.__checkstatus(status)
    return struct.unpack("<I", status[4:8])[0]


  def upload(self, offset, file):
    self.__myprint("Uploading %s to 0x%8x..." % (file, offset))
    f = open(file, "rb")

    while True:
      data = f.read(65536)
      if data == "": break
      self.write(offset, data)
      offset += len(data)
      self.__myprint(".")

    self.__myprint(" done\n")


  def download(self, offset, size, file):
    self.__myprint("Downloading 0x%x bytes from 0x%8x to %s..." % (size, offset, file))
    f = open(file, "wb")

    while True:
      blocklen = size
      if blocklen == 0: break
      if blocklen > 65536: blocklen = 65536
      f.write(self.read(offset, blocklen))
      offset += blocklen
      size -= blocklen
      self.__myprint(".")

    self.__myprint(" done\n")


  def startup(self):
    self.upload(0x22000020, sys.path[0] + "/ibugger/logo-%d.bin" % self.devtype)
    if self.devtype == 2:
      self.updatelcd(0x22000020, 0, 175, 0, 131, 0, "")
    elif self.devtype == 4:
      self.updatelcd(0x22000020, 0, 239, 0, 319, 0, "")
    self.backlighton(32, 1)
    self.upload(0x22000000, sys.path[0] + "/ibugger/core-%d.bin" % self.devtype)
    self.execute(0x22000020, 0x0a000000)
    time.sleep(2)
    dev = ibugger(self.devtype, 2)
    self.handle = dev.handle
    self.type = 2


  def run(self, file):
    if self.type == 1:
      self.startup()
    self.backlighton(32, 1)
    self.getstate(2)
    self.upload(0x08000000, file)
    self.execute(0x08000020, 0x0a000000)


  def dumpstate(self, newstate):
    self.__myprint("Getting target state...")
    state = self.getstate(newstate)
    self.__myprint(" done\n")
    print "  R0: %8x     R4: %8x     R8: %8x    R12: %8x" % (state[0], state[4], state[8], state[12])
    print "  R1: %8x     R5: %8x     R9: %8x     SP: %8x" % (state[1], state[5], state[9], state[13])
    print "  R2: %8x     R6: %8x    R10: %8x     LR: %8x" % (state[2], state[6], state[10], state[14])
    print "  R3: %8x     R7: %8x    R11: %8x     PC: %8x" % (state[3], state[7], state[11], state[15])
    print "CPSR: %8x     ABORTSP: %8x     STATE: %s" % (state[16], state[17], self.state2name(state[18]))
