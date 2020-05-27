#ifndef AVR_THREADS_H_
#define AVR_THREADS_H_

/* GENERAL NOTES
 *
 * Context Switch Interrupts
 * You will have to set up a timer to cause periodic context switch interrupts.
 * When compiling, define AVRT_INTERRUPT to be the symbol to use for the
 * interrupt, e.g. TIMER0_OVF_vect. Because interrupts are used, use cli and sei
 * around sections that need to be atomic.
 *
 * Thread Numbering
 * Only a fixed number of threads is supported. When compiling, define
 * AVRT_MAX_THREADS to a positive number, the maximum number of threads at a
 * time. AVRT_MAX_THREADS must be less than 129. A thread ID is a number between
 * 0 and AVRT_MAX_THREADS - 1, inclusive.
 *
 * Interrupt Safety
 * Unless otherwise noted, these symbols cannot be called/accessed from within
 * interrupts.
 */

#ifndef __ASSEMBLER__

/* Initialize the thread system. The return value is the ID of a newly created
 * thread running the current code. This should be called before the first
 * context switch. */
unsigned char avrt_init(void);

/* The ID of the current thread. This cannot be accessed before avrt_init()
 * is called. It is constant because each thread sees a different constant
 * value. */
extern const unsigned char avrt_self;

/* Start another thread. This can be called before or after the first context
 * switch. The argument arg is passed to the function func, which is where the
 * thread starts. Specifically, r24-r25 are preserved in the new thread. The
 * stack is the last argument. Make sure the pointer is to the end of the stack,
 * since stacks grow down. The stack should be at least (probably more than)
 * AVRT_MIN_STACK_SIZE. There is no stack bounds checking. The return value is a
 * thread ID for the new thread or -1 if resources are exhausted. */
signed char avrt_start(void *arg, void (*func)(void *arg), void *stack);

/* Block the thread until another thread calls avrt_unblock() with the ID of
 * this thread. This will enable interrupts after it is done. */
void avrt_block(void);

/* Unblock the existent thread with the given ID. 1 is returned unless the
 * thread was not blocked to begin with. This can be called from interrupts. Due
 * to limitations in the code, a thread must be running to receive an interrupt.
 * If all threads are blocked, interrupts are blocked. To work around this, keep
 * a thread running calling avrt_yield() in a loop. */
_Bool avrt_unblock(unsigned char thread);

/* Force a context switch to another thread. This will enable interrupts if they
 * are disabled. Otherwise, calling it does not clobber any state whatsoever. */
void avrt_yield(void);
#define avrt_yield() ({ __asm__("call avrt_yield" :::); (void)0; })

/* Exit this thread. When all threads exit, the program stops. */
void avrt_exit(void) __attribute__((noreturn));

#endif /* !defined(__ASSEMBLER__) */

/* The minimum size of a thread's stack, assuming the code it runs does not
 * itself use the stack at all. */
#define AVRT_MIN_STACK_SIZE 35

#endif /* AVR_THREADS_H_ */
