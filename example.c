#include "avrt.h"
#include <avr/interrupt.h>
#include <avr/io.h>
#define F_CPU 16000000UL
#define BAUD 9600
#include <util/delay.h>
#include <util/setbaud.h>

static void init_ports(void)
{
	DDRB = _BV(PB3) | _BV(PB4) | _BV(PB5);
}

static void init_timer(void)
{
	TCCR0B = _BV(CS02);
	TIMSK0 = _BV(TOIE0);
	sei();
}

// noinline tests the stacks of the different threads:
__attribute__((noinline))
void wait(unsigned char id)
{
	_delay_ms(60);
	for (unsigned char i = 0; i < 4 + id * 2; ++i) {
		_delay_ms(20);
	}
}

static void child(void *arg)
{
	unsigned char id = *(unsigned char *)arg;
	unsigned char mask = _BV(id + 3);
	for (unsigned char i = 0; i < (4 + id)*2; ++i) {
		wait(id);
		cli();
		PORTB ^= mask;
		sei();
	}
	avrt_exit();
}

int main(void)
{
	static char stack1[256], stack2[256];
	unsigned char id0 = 0, id1 = 1, id2 = 2;
	signed char t0 = 0, t1 = 1, t2 = 2;
	t0 = avrt_init();
	t1 = avrt_start(&id1, child, stack1 + sizeof(stack1) - 1);
	t2 = avrt_start(&id2, child, stack2 + sizeof(stack2) - 1);
	init_ports();
	if (t0 == t1 || t0 == t2 || t1 == t2 || t1 < 0 || t2 < 0)
		for (PORTB = _BV(PB3) | _BV(PB4) | _BV(PB5);;)
			;
	init_timer();
	child(&id0);
}
