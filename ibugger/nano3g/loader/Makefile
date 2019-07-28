all: loader.htm

loader.htm: bin2htm loader.bin
	./bin2htm loader.bin loader.htm

loader.o: loader.asm
	arm-elf-as -o $@ $<

loader.elf: loader.o
	arm-elf-ld -e 0 -Ttext=0 -o $@ $<

loader.bin: loader.elf
	arm-elf-objcopy -O binary $< $@

bin2htm: bin2htm.c
	gcc -o bin2htm bin2htm.c

clean:
	rm -f bin2htm bin2htm.exe loader.o loader.elf loader.bin loader.htm loader.lst *~
