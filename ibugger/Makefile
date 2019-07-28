all:
	make -C nano2g/core
	make -C nano2g/loader
	make -C nano3g/core
	make -C nano3g/loader
	make -C nano4g/core
	make -C nano4g/loader
	make -C classic/core
	make -C classic/loader
	cp nano2g/core/core.bin core-2.bin
	cp nano4g/core/core.bin core-3.bin
	cp nano4g/core/core.bin core-4.bin
	cp classic/core/core.bin core-16.bin

clean:
	make -C nano2g/core clean
	make -C nano2g/loader clean
	make -C nano3g/core clean
	make -C nano3g/loader clean
	make -C nano4g/core clean
	make -C nano4g/loader clean
	make -C classic/core clean
	make -C classic/loader clean
	rm -f core-2.bin
	rm -f core-3.bin
	rm -f core-4.bin
	rm -f core-16.bin
