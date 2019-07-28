all:
	make -C flasher
	make -C ibugger
	make -C ipodcrypto
	make -C ucl CC=gcc

clean:
	make -C flasher clean
	make -C ibugger clean
	make -C ipodcrypto clean
	make -C ucl clean
	rm -f *.pyc
