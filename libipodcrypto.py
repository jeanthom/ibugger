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
import time
import libibugger


def runcrypter(device, data, image, offset, resultoffset):
  size = len(data)
  paddedsize = (size + 0x3F) & 0xFFFFFFC0
  if paddedsize > 0x1FE0000:
    raise Exception("This file is too big. Only files up to 31MB are supported.")

  dev = libibugger.ibugger(device)
  if dev.type == 1: dev.startup()

  file = open(sys.path[0] + "/ipodcrypto/" + image + "/" + image + ".bin", "rb")
  code = file.read()
  file.close()

  pos = code.find("SIZE")
  if pos != -1:
    code = code[:pos] + struct.pack("<I", paddedsize) + code[pos + 4:]

  dev.getstate(2)

  sys.stdout.write("Uploading data...")
  dev.write(0x08000000, code)
  dev.write(0x08010000 + offset, data)
  dev.write(0x08010000 + offset + size, struct.pack("B", 0) * (paddedsize - size))
  print(" done")
  dev.execute(0x08000020, 0x08010000)

  sys.stdout.write("Waiting for crypto operation to complete...")
  sys.stdout.flush()
  while dev.getstate(-1)[18] == 0:
    sys.stdout.write(".")
    sys.stdout.flush()
    time.sleep(1)
  print(" done")

  sys.stdout.write("Downloading result...")
  result = dev.read(0x08010000 + resultoffset, paddedsize + offset - resultoffset)
  print(" done")

  return result


def runcrypterfile(device, infile, outfile, image, offset, resultoffset):
  file = open(infile, "rb")
  data = file.read()
  file.close()
  result = runcrypter(device, data, image, offset, resultoffset)
  file = open(outfile, "wb")
  file.write(result)
  file.close()


def cryptdfu(data):
  return runcrypter(2, data, "cryptdfu", 0x800, 0)


def cryptfirmware(data):
  return runcrypter(2, data, "cryptfirmware", 0x800, 0)


def cryptnor(data):
  return runcrypter(2, data, "cryptnor", 0x200, 0)


def decryptdfu(data):
  return runcrypter(2, data, "decryptdfu", 0, 0)


def decryptfirmware(data):
  return runcrypter(2, data, "decryptfirmware", 0, 0)


def decryptnor(data):
  return runcrypter(2, data, "decryptnor", 0, 0)


def decrypt8720(data):
  return runcrypter(4, data, "decrypt8720", 0x600, 0)


def cryptdfufile(infile, outfile):
  return runcrypterfile(2, infile, outfile, "cryptdfu", 0x800, 0)


def cryptfirmwarefile(infile, outfile):
  return runcrypterfile(2, infile, outfile, "cryptfirmware", 0x800, 0)


def cryptnorfile(infile, outfile):
  return runcrypterfile(2, infile, outfile, "cryptnor", 0x200, 0)


def decryptdfufile(infile, outfile):
  return runcrypterfile(2, infile, outfile, "decryptdfu", 0, 0)


def decryptfirmwarefile(infile, outfile):
  return runcrypterfile(2, infile, outfile, "decryptfirmware", 0, 0)


def decryptnorfile(infile, outfile):
  return runcrypterfile(2, infile, outfile, "decryptnor", 0, 0)


def decrypt8720file(infile, outfile):
  return runcrypterfile(4, infile, outfile, "decrypt8720", 0, 0x600)
