#include <avr/interrupt.h>
#include <example_common.h>
#include <stddef.h>

/* The list of alarms for each thread. The value is a number of milliseconds, or
 * -1 if the thread is not blocked waiting. */
static int times[AVRT_MAX_THREADS];
/* The stack for the timer dummy thread, increased for TIMER2_COMPA_vect. */
static char timer_stack[AVRT_DUMMY_STACK_SIZE + 5];

/* This interrupt fires every millisecond. */
ISR(TIMER2_COMPA_vect)
{
	for (unsigned char i = 0; i < AVRT_MAX_THREADS; ++i) {
		if (times[i] >= 0) {
			// Unblock waiting threads when their alarms go off:
			if (times[i] == 0) avrt_unblock(i);
			--times[i];
		}
	}
}

static signed char sleep_timer_init(void)
{
	for (unsigned char i = 0; i < AVRT_MAX_THREADS; ++i) {
		times[i] = -1;
	}
	// I think this timing is about a millisecond:
	OCR2A = 248;
	TCCR2A = _BV(WGM21);
	TCCR2B = _BV(CS22);
	TIMSK2 = _BV(OCIE2A);
	char *stack_end = timer_stack + sizeof(timer_stack) - 1;
	// At least one thread must be running to make interrupt unblock work:
	if (avrt_start(NULL, avrt_dummy_thread, stack_end) < 0) return -1;
	return 0;
}

static void timer_sleep(int millis)
{
	// Disable interrupts to make this atomic:
	cli();
	// Set alarm:
	times[avrt_self] = millis;
	avrt_block();
	// Interrupts reenabled by avrt_block().
}

static TASK void pb3_after_1s(void *arg)
{
	(void)arg;
	timer_sleep(1000);
	PORTB |= _BV(PB3);
	avrt_exit();
}

static TASK void pb4_after_2s(void *arg)
{
	(void)arg;
	timer_sleep(2000);
	PORTB |= _BV(PB4);
	avrt_exit();
}

static TASK void pb5_after_3s(void *arg)
{
	(void)arg;
	timer_sleep(3000);
	PORTB |= _BV(PB5);
	avrt_exit();
}

int main(void)
{
	static char stack1[AVRT_MIN_STACK_SIZE + 16];
	static char stack2[AVRT_MIN_STACK_SIZE + 16];
	avrt_init();
	avrt_start(NULL, pb3_after_1s, stack1 + sizeof(stack1) - 1);
	avrt_start(NULL, pb4_after_2s, stack2 + sizeof(stack2) - 1);
	ports_init();
	sleep_timer_init();
	thread_timer_init();
	sei();
	pb5_after_3s(NULL);
}
