# iBugger

**This version of iBugger contains USB communication fixes. In the latest iBugger version published by TheSeven, USB BULK transactions were out of spec and caused libusb bugs.**

## HowTo

Software requirements:

 * Python 2 
 * pyusb (`pip install pyusb`)

Copy `ibugger/nano2g/loader/loader.htm` to the `Notes` folder of your iPod, then eject it. You should be greeted a few moments later with the Mandelbrot Set on your iPod Nano LCD. If that's not the case, try rebooting the iPod Nano by holding `MENU` and `SELECT` until the Apple logo appears.

You can then try to load *iBugger Core* by doing `python ibugger.py startup`. The iPod Nano should re-enumerate as "iBugger Core". You may now use the `ipodcrypt.py` utility to crypt/decrypt firmware files.
