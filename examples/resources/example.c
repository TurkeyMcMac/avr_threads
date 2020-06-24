#include <avr/interrupt.h>
#include <example_common.h>
#include <stddef.h>
#include <util/setbaud.h>
#include <util/delay.h>

#define N_CHILD_THREADS (AVRT_MAX_THREADS - 1)

static void verify(_Bool v)
{
	// If the condition being verified is false, turn on PB3 and stop the
	// program:
	if (!v) {
		cli();
		PORTB |= _BV(PB3);
		for (;;)
			;
	}
}

// The thread sets the pointed boolean to true and finishes:
static TASK void set_true(void *arg)
{
	_Bool *dest = arg;
	*dest = 1;
	avrt_exit();
}

int main(void)
{
	static _Bool dones[N_CHILD_THREADS];
	static char stacks[N_CHILD_THREADS][AVRT_MIN_STACK_SIZE + 16];
	ports_init();
	avrt_init();
	for (unsigned char i = 0; i < N_CHILD_THREADS; ++i) {
		// There will be resources available for the first
		// AVRT_MAX_THREADS threads (this main thread is the first one):
		verify(avrt_start(&dones[i], set_true,
			stacks[i] + sizeof(stacks[i]) - 1) > 0);
	}
	// -1 is returned with too many threads:
	verify(avrt_start(NULL, NULL, NULL) < 0);
	thread_timer_init();
	sei();
	// Let the other threads run first:
	avrt_yield();
	for (;;) {
		for (unsigned char i = 0; i < N_CHILD_THREADS; ++i) {
			_Bool done;
			cli();
			done = dones[i];
			sei();
			if (done) {
				// Thread IDs are reused when threads exit:
				verify(avrt_start(&dones[i], set_true,
					stacks[i] + sizeof(stacks[i]) - 1) > 0);
				cli();
				PORTB |= _BV(PB4);
				avrt_exit();
			}
		}
	}
}
