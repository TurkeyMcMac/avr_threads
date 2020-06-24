#ifndef EXAMPLE_COMMON_H_
#define EXAMPLE_COMMON_H_

/* This file contains useful common code for the examples. */

#include <avrt.h>
#include <avr/io.h>

/* Initialize PB3, PB4, and PB5 for misc. use. */
static void ports_init(void)
{
	DDRB |= _BV(PB3) | _BV(PB4) | _BV(PB5);
}

/* Initialize TIMER0 (assumed to be 8-but) as the thread timer with a reasonable
 * interval, without enabling interrupts. */
static void thread_timer_init(void)
{
	TCCR0B = _BV(CS02);
	TIMSK0 = _BV(TOIE0);
}

/* Signifies that a function is a thread task, so it does not need to preserve
 * registers and will not return (instead calling avrt_exit.) */
#define TASK __attribute__((OS_task, noreturn))

#endif /* EXAMPLE_COMMON_H_ */
