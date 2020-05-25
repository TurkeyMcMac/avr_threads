ex = blinkers
flags = -mmcu=atmega328p -O3 -I. \
	-DAVRT_MAX_THREADS=8 -DAVRT_INTERRUPT=TIMER0_OVF_vect \
	-DF_CPU=16000000L -DBAUD=9600 $(CFLAGS)
programmer = arduino
partno = m328p
port = /dev/ttyUSB0

example-dir = examples/$(ex)

$(example-dir)/example.hex: $(example-dir)/example.elf
	avr-objcopy -O ihex $< $@

$(example-dir)/example.elf: $(example-dir)/example.c libavrt.a avrt.h
	avr-gcc $(flags) -o $@ $< libavrt.a

libavrt.a: avrt.o
	avr-ar crsu $@ avrt.o

avrt.o: avrt.S avrt.h
	avr-gcc $(flags) -c -o $@ avrt.S

.PHONY: upload
upload: $(example-dir)/example.hex
	avrdude -c$(programmer) -p$(partno) -P$(port) -Uflash:w:$<:i

.PHONY: clean
clean:
	rm -f examples/*/example.elf examples/*/example.hex libavrt.a avrt.o
