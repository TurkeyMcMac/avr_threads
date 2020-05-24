#ifndef AVR_THREADS_H_
#define AVR_THREADS_H_

unsigned char avrt_init(void);

signed char avrt_start(void *arg, void (*func)(void *arg), void *stack);

void avrt_yield(void);

void avrt_exit(void) __attribute__((noreturn));

#endif /* AVR_THREADS_H_ */
