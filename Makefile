flags = -mmcu=atmega328p -O3
programmer = arduino
partno = m328p
port = /dev/ttyUSB0

example.hex: example.elf
	avr-objcopy -O ihex example.elf $@
	chmod -x example.hex

example.elf: example.c libavrt.a avrt.h
	avr-gcc $(flags) -o $@ example.c libavrt.a

libavrt.a: avrt.o
	avr-ar crsu $@ avrt.o

avrt.o: avrt.S avrt.h
	avr-gcc $(flags) -c -o $@ avrt.S

.PHONY: upload
upload: example.hex
	avrdude -c$(programmer) -p$(partno) -P$(port) -Uflash:w:example.hex:i

.PHONY: clean
clean:
	rm -f example.elf libavrt.a avrt.o
