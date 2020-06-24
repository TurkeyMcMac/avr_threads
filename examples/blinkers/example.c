#include <example_common.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <util/setbaud.h>

/* Do some amount of waiting based on the given ID. */
static void wait(unsigned char id)
{
	_delay_ms(60);
	for (unsigned char i = 0; i < 4 + id * 2; ++i) {
		_delay_ms(20);
	}
}

/* Blink a bunch, duration depending on the given (by reference) ID. */
static TASK void do_blinks(void *arg)
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
	avrt_init();
	avrt_start(&id1, do_blinks, stack1 + sizeof(stack1) - 1);
	avrt_start(&id2, do_blinks, stack2 + sizeof(stack2) - 1);
	ports_init();
	thread_timer_init();
	sei();
	do_blinks(&id0);
}
