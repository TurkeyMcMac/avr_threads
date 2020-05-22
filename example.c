#include "avrt.h"
#include <avr/interrupt.h>
#include <avr/io.h>
#include <stdio.h>
#include <stdlib.h>

struct spinlock {
	volatile uint8_t state;
};

#define SPINLOCK_INIT {0}

static void spin_lock(struct spinlock *lock)
{
	for (;;) {
		cli();
		if (lock->state == 0) {
			lock->state = 1;
			sei();
			return;
		}
		sei();
		avrt_yield();
	}
}

static void spin_unlock(struct spinlock *lock)
{
	lock->state = 0;
}

static void print_series(char var_name, struct spinlock *lock)
{
	for (int i = 0; i < 100; ++i) {
		int var = i * i;
		char var_buf[16];
		itoa(var, var_buf, 10);
		spin_lock(lock);
		putchar(var_name);
		fputs("^2 = ", stdout);
		puts(var_buf);
		spin_unlock(lock);
	}
}

struct arg {
	char var_name;
	struct spinlock *lock;
};

static void child(void *arg_void)
{
	struct arg *arg = arg_void;
	char var_name = arg->var_name;
	struct spinlock *lock = arg->lock;
	print_series(var_name, lock);
	avrt_exit();
}

#define F_CPU 16000000UL
#define BAUD 9600
#include <util/setbaud.h>

static int uart_put(char c, FILE *f)
{
	(void)f;
	loop_until_bit_is_set(UCSR0A, UDRE0);
	UDR0 = c;
	return 0;
}

static void init_stdout(void)
{
	UBRR0H = UBRRH_VALUE;
	UBRR0L = UBRRL_VALUE;
#if USE_2X
	UCSR0A |= _BV(U2X0);
#endif
	UCSR0C = _BV(UCSZ01) | _BV(UCSZ00);
	UCSR0B = _BV(TXEN0);
	fdevopen(uart_put, NULL);
}

static void init_timer(void)
{
	//TCCR0B |= _BV(CS01) | _BV(CS00);
	TIMSK0 |= _BV(TOIE0);
	sei();
}

int main(void)
{
	static char stack1[256];
	static char stack2[256];
	struct spinlock lock = SPINLOCK_INIT;
	struct arg arg1 = { 'j', &lock };
	struct arg arg2 = { 'k', &lock };
	init_stdout();
	init_timer();
	avrt_start(&arg1, child, stack1 + sizeof(stack1) - 1);
	avrt_start(&arg2, child, stack2 + sizeof(stack2) - 1);
	print_series('i', &lock);
	avrt_exit();
	puts("Main thread done.");
}
