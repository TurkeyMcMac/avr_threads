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

/* Initialize the thread system and register the current thread of execution.
 * Don't call/access other symbols in this library until you've called this.
 * Call it only once. */
void avrt_init(void);

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

/* Do the same as avrt_block except that interrupts are disabled, not enabled,
 * afterward. If interrupts were already disabled, there is no point at which an
 * interrupt can be delivered. This is not a real function because it can be
 * replicated in assembly just by putting cli directly after the call. */
#define avrt_block_cli() ({ __asm__ volatile ("call avrt_block\ncli" ::: \
	"r0", "r18", "r19", "r20", "r21", "r22", "r23", "r24", "r25", "r26", \
	"r27", "r30", "r31", "memory"); (void)0; })

/* Unblock the existent thread with the given ID. 1 is returned unless the
 * thread was not blocked to begin with. This can be called from interrupts. Due
 * to limitations in the code, a thread must be running to receive an interrupt.
 * If all threads are blocked, interrupts are blocked. To work around this, keep
 * a thread running with avrt_dummy_thread passed to avrt_start. */
_Bool avrt_unblock(unsigned char thread);

/* Force a context switch to another thread. This will enable interrupts if they
 * are disabled. Otherwise, calling it does not clobber any state whatsoever. */
void avrt_yield(void);
#define avrt_yield() /* This communicates that only the SREG is clobbered. */ \
	({ __asm__ volatile ("call avrt_yield" ::: "memory"); (void)0; })

/* Do the same as avrt_yield except that interrupts are disabled, not enabled,
 * afterward. If interrupts were already disabled, there is no point at which an
 * interrupt can be delivered. This is not a real function because it can be
 * replicated in assembly just by putting cli directly after the call. */
#define avrt_yield_cli() \
	({ __asm__ volatile ("call avrt_yield\ncli" ::: "memory"); (void)0; })

/* Exit this thread. When all threads exit, the program stops. */
void avrt_exit(void) __attribute__((noreturn));

/* A function that can be passed to avrt_start. The thread will continuously
 * yield and never exit. This function is special in that it will never need a
 * stack larger than AVRT_DUMMY_STACK_SIZE, providing some space savings over
 * functions without guaranteed stack usage. The thread can be used to receive
 * interrupts with all other threads blocked. */
void avrt_dummy_thread(void *arg);

#endif /* !defined(__ASSEMBLER__) */

/* The minimum size of a thread's stack, assuming the code it runs does not
 * itself use the stack at all. */
#define AVRT_MIN_STACK_SIZE 35

/* The minimum safe stack size for a thread running avrt_dummy_thread. */
#define AVRT_DUMMY_STACK_SIZE (AVRT_MIN_STACK_SIZE + 2)

#endif /* AVR_THREADS_H_ */
