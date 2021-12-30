CROSS ?= arm-elf-

AS = $(CROSS)as
LD = $(CROSS)ld
OBJCOPY = $(CROSS)objcopy

all: loader.htm

loader.htm: bin2htm loader.bin
	./bin2htm loader.bin loader.htm

loader.o: loader.asm
	$(AS) -o $@ $<

loader.elf: loader.o
	$(LD) -e 0 -Ttext=0 -o $@ $<

loader.bin: loader.elf
	$(OBJCOPY) -O binary $< $@

bin2htm: bin2htm.c
	gcc -o bin2htm bin2htm.c

clean:
	rm -f bin2htm bin2htm.exe loader.o loader.elf loader.bin loader.htm loader.lst *~
