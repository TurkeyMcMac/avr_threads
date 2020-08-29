#include <avr/interrupt.h>
#include <example_common.h>
#include <util/delay.h>

/* The default queue size means no one has to spin rather than blocking. */
#ifndef MUTEX_QUEUE_SIZE
#	define MUTEX_QUEUE_SIZE AVRT_MAX_THREADS
#endif

/* More queue items than AVRT_MAX_THREADS is pointless. */
#if MUTEX_QUEUE_SIZE > AVRT_MAX_THREADS
#	undef MUTEX_QUEUE_SIZE
#	define MUTEX_QUEUE_SIZE AVRT_MAX_THREADS
#endif

#if MUTEX_QUEUE_SIZE < 1
#	error MUTEX_QUEUE_SIZE < 1
#endif

/* A mutex has a queue of thread IDs. If a thread is holding the lock, its ID is
 * at position 0. Higher positions are later in the queue. When the queue is
 * full, other threads waiting for access have to spin until a spot opens (which
 * makes their waiting times unfair.) n_filled is the number of queue spots
 * currently filled. */
struct mutex {
	unsigned char n_filled;
	signed char queue[MUTEX_QUEUE_SIZE];
};

#define MUTEX_INITIALIZER { .n_filled = 0 }

void mutex_lock(struct mutex *mtx)
{
retry:
	cli();
	if (mtx->n_filled == 0) {
		// The mutex is uncontested.
		mtx->queue[0] = avrt_self;
		mtx->n_filled = 1;
		sei();
	} else if (mtx->n_filled >= MUTEX_QUEUE_SIZE) {
		// The thread must spin until there's an opening.
		// If there is room in the queue for every possible thread, then
		// no thread that does not own the mutex can be running here:
		if (MUTEX_QUEUE_SIZE >= AVRT_MAX_THREADS)
			__builtin_unreachable();
		avrt_yield();
		goto retry;
	} else {
		// The thread should enqueue and block.
		mtx->queue[mtx->n_filled++] = avrt_self;
		avrt_block();
		// Interrupts are reenabled by avrt_block().
	}
}

void mutex_unlock(struct mutex *mtx)
{
	cli();
	--mtx->n_filled;
	if (mtx->n_filled > 0) {
		for (unsigned char i = 0; i < mtx->n_filled; ++i) {
			mtx->queue[i] = mtx->queue[i + 1];
		}
		avrt_unblock(mtx->queue[0]);
	}
	sei();
}

static struct mutex port_mutex = MUTEX_INITIALIZER;

static TASK void do_blink_loop(void *arg)
{
	unsigned char mask = *(unsigned char *)arg;
	for (;;) {
		mutex_lock(&port_mutex);
		PORTB ^= mask;
		_delay_ms(1000);
		PORTB ^= mask;
		mutex_unlock(&port_mutex);
		_delay_ms(200);
	}
}

int main(void)
{
	static char stack1[AVRT_MIN_STACK_SIZE + 16];
	static char stack2[AVRT_MIN_STACK_SIZE + 16];
	static char stack3[AVRT_MIN_STACK_SIZE + 16];
	unsigned char mask1 = _BV(PB5);
	unsigned char mask2 = _BV(PB4);
	unsigned char mask3 = _BV(PB3);
	unsigned char mask_all = mask1 | mask2 | mask3;
	avrt_init();
	avrt_start(&mask1, do_blink_loop, stack1 + sizeof(stack1) - 1);
	avrt_start(&mask2, do_blink_loop, stack2 + sizeof(stack2) - 1);
	avrt_start(&mask3, do_blink_loop, stack3 + sizeof(stack3) - 1);
	ports_init();
	thread_timer_init();
	sei();
	do_blink_loop(&mask_all);
}
