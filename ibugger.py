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


def usage():
  print ""
  print "Please provide a command and (if needed) parameters as command line arguments"
  print ""
  print "Available commands:"
  print ""
  print "  restart"
  print "    Restarts the iBugger core or loader, whichever is running"
  print ""
  print "  reset"
  print "    Resets the device"
  print ""
  print "  startup"
  print "    Loads the iBugger core and executes it."
  print "    If you don't load the core, you will only have very limited functionality."
  print ""
  print "  upload <address> <file>"
  print "    Uploads the specified file to the specified memory address on the device."
  print ""
  print "  download <address> <size> <file>"
  print "    Downloads <size> bytes of data from the specified address on the device,"
  print "    and stores it in the specified file."
  print ""
  print "  execute <address> <stack>"
  print "    Executes code at the specified address in the device's memory."
  print "    The stack pointer will be set to <stack> before jumping to <address>."
  print "    iBugger will probably lose control of the device,"
  print "    if the code isn't explicitly written for it."
  print ""
  print "  run <file>"
  print "    Loads the specified file to 0x08000000 (SDRAM) and executes it with an"
  print "    entrypoint of 0x08000020, loading the core first, if neccessary."
  print "    This is what you usually want to do."
  print ""
  print "  dumpstate"
  print "    Dumps the debugging target state"
  print ""
  print "  backlighton"
  print "    Power on the backlight"
  print ""
  print "  backlightoff"
  print "    Power off the backlight"
  print ""
  print "  console"
  print "    Display messages sent by a program executed on the iPod"
  print ""
  print "All numbers are hexadecimal!"
  exit(2)


def parsecommand(dev, argv):
  if len(argv) < 2: usage()

  elif argv[1] == "restart":
    if len(argv) != 2: usage()
    dev.restart()
  
  elif argv[1] == "reset":
    if len(argv) != 2: usage()
    dev.reset()
  
  elif argv[1] == "startup":
    if len(argv) != 2: usage()
    if dev.type == 1: dev.startup()
    else: print "Core already running"

  elif argv[1] == "upload":
    if len(argv) != 4: usage()
    dev.upload(int(argv[2], 16), argv[3])

  elif argv[1] == "download":
    if len(argv) != 5: usage()
    dev.download(int(argv[2], 16), int(argv[3], 16), argv[4])

  elif argv[1] == "execute":
    if len(argv) != 4: usage()
    dev.execute(int(argv[2], 16), int(argv[3], 16))

  elif argv[1] == "run":
    if len(argv) != 3: usage()
    dev.run(argv[2])

  elif argv[1] == "backlighton":
    if len(argv) != 2: usage()
    dev.backlighton(32, 1)

  elif argv[1] == "backlightoff":
    if len(argv) != 2: usage()
    dev.backlightoff(32)

  elif argv[1] == "dumpstate":
    if len(argv) != 2: usage()
    dev.dumpstate(-1)

  elif argv[1] == "console":
    try:
      while True:
        block = dev.consoleread(512);
        sys.stdout.write(block);
        sys.stdout.flush();
        time.sleep(0.0002 * (512 - len(block)))
    except KeyboardInterrupt:
      pass

  else: usage()


dev = libibugger.ibugger()
parsecommand(dev, sys.argv)
