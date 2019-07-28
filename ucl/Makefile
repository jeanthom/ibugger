#             __________               __   ___.
#   Open      \______   \ ____   ____ |  | _\_ |__   _______  ___
#   Source     |       _//  _ \_/ ___\|  |/ /| __ \ /  _ \  \/  /
#   Jukebox    |    |   (  <_> )  \___|    < | \_\ (  <_> > <  <
#   Firmware   |____|_  /\____/ \___  >__|_ \|___  /\____/__/\_ \
#                     \/            \/     \/    \/            \/
# $Id: Makefile 8878 2006-03-01 23:40:55Z amiconn $
#
CFLAGS = -O2 -Iinclude

TARGET = ../uclpack
TARGET2 = ../ucl2e10singleblk
TARGET3 = ../ucl2e10singleblkunpack

ALL: $(TARGET) $(TARGET2) $(TARGET3)

$(TARGET): uclpack.o src/libucl.a
	$(CC) uclpack.o src/libucl.a -o $(TARGET)

$(TARGET2): ucl2e10singleblk.o src/libucl.a
	$(CC) ucl2e10singleblk.o src/libucl.a -o $(TARGET2)

$(TARGET3): ucl2e10singleblkunpack.o src/libucl.a
	$(CC) ucl2e10singleblkunpack.o src/libucl.a -o $(TARGET3)

uclpack.o: uclpack.c

ucl2e10singleblk.o: ucl2e10singleblk.c

ucl2e10singleblkunpack.o: ucl2e10singleblkunpack.c

src/libucl.a:
	$(MAKE) -C src

clean:
	rm -f $(TARGET) uclpack.o ucl2e10singleblk.o ucl2e10singleblkunpack.o
	$(MAKE) -C src clean