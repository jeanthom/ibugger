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
import libipodcrypto


def usage():
  print ""
  print "Please provide a command and (if needed) parameters as command line arguments"
  print ""
  print "Available commands:"
  print "  cryptdfu <infile> <outfile>"
  print "  cryptfirmware <infile> <outfile>"
  print "  cryptnor <infile> <outfile>"
  print "  decryptdfu <infile> <outfile>"
  print "  decryptfirmware <infile> <outfile>"
  print "  decryptnor <infile> <outfile>"
  print "  decrypt8720 <infile> <outfile>"
  exit(2)


def parsecommand(argv):
  if len(argv) != 4: usage()

  elif argv[1] == "cryptdfu":
    libipodcrypto.cryptdfufile(argv[2], argv[3])

  elif argv[1] == "cryptfirmware":
    libipodcrypto.cryptfirmwarefile(argv[2], argv[3])

  elif argv[1] == "cryptnor":
    libipodcrypto.cryptnorfile(argv[2], argv[3])

  elif argv[1] == "decryptdfu":
    libipodcrypto.decryptdfufile(argv[2], argv[3])

  elif argv[1] == "decryptfirmware":
    libipodcrypto.decryptfirmwarefile(argv[2], argv[3])

  elif argv[1] == "decryptnor":
    libipodcrypto.decryptnorfile(argv[2], argv[3])

  elif argv[1] == "decrypt8720":
    libipodcrypto.decrypt8720file(argv[2], argv[3])

  else: usage()


parsecommand(sys.argv)
