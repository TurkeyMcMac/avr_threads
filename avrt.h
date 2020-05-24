#ifndef AVR_THREADS_H_
#define AVR_THREADS_H_

#define AVRT_MIN_STACK_SIZE 35

extern const unsigned char avrt_self;

unsigned char avrt_init(void);

signed char avrt_start(void *arg, void (*func)(void *arg), void *stack);

void avrt_block(void);

_Bool avrt_unblock(unsigned char thread);

void avrt_yield(void);

void avrt_exit(void) __attribute__((noreturn));

#endif /* AVR_THREADS_H_ */
