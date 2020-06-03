ex = blinkers
flags = -mmcu=atmega328p -O3 -Wall -Wextra -I. \
	-DAVRT_MAX_THREADS=8 -DAVRT_INTERRUPT=TIMER0_OVF_vect \
	-DF_CPU=16000000L -DBAUD=9600 $(CFLAGS)
programmer = arduino
partno = m328p
port = /dev/ttyUSB0

example-dir = examples/$(ex)
example-headers = avrt.h example_common.h

$(example-dir)/example.hex: $(example-dir)/example.elf Makefile
	avr-objcopy -O ihex $(example-dir)/example.elf $@

$(example-dir)/example.elf: $(example-dir)/example.o libavrt.a Makefile
	avr-gcc $(flags) -o $@ $(example-dir)/example.o libavrt.a

$(example-dir)/example.o: $(example-dir)/example.c $(example-headers) Makefile
	avr-gcc $(flags) -c -o $@ $(example-dir)/example.c

libavrt.a: avrt.o Makefile
	avr-ar crsu $@ avrt.o

avrt.o: avrt.S avrt.h Makefile
	avr-gcc $(flags) -c -o $@ avrt.S

.PHONY: upload
upload: $(example-dir)/example.hex
	avrdude -c$(programmer) -p$(partno) -P$(port) \
		-Uflash:w:$(example-dir)/example.hex:i

.PHONY: clean
clean:
	rm -f examples/*/example.elf examples/*/example.hex \
		examples/*/example.o libavrt.a avrt.o
