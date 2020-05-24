#include <avr/io.h>

#define AVRT_MAX_THREADS 4
#define AVRT_INTERRUPT TIMER0_OVF_vect

/*
Thread structure:
1	flags
2	stack pointer

Saved stack state (in order of push):
2	instruction pointer
32	r0-r31
1	SREG

The stack pointer in the thread structure points to the top of the stack state.
*/

#define THREAD_SIZE 3

#define THREAD_STACK_SAVE_SIZE 35

#if THREAD_SAVE_STACK_SIZE > AVRT_MIN_STACK_SIZE
#	error THREAD_SAVE_STACK_SIZE > AVRT_MIN_STACK_SIZE
#endif

/* Don't change these flag values! */
#define RUNNING_FLAG 0x80
#define BLOCKED_FLAG 0x40

.text

.global avrt_init
.type avrt_init, @function
.global avrt_start
.type avrt_start, @function
.global avrt_block
.type avrt_block, @function
.global avrt_exit
.type avrt_exit, @function
.global avrt_yield
.type avrt_yield, @function
.global AVRT_INTERRUPT
.type AVRT_INTERRUPT, @function
.global avrt_unblock
.type avrt_unblock, @function
.global avrt_self
.type avrt_self, @object

__tmp_reg__ = 0
__zero_reg__ = 1
__SP_L__ = 0x3D
__SP_H__ = 0x3E
__SREG__ = 0x3F

avrt_init:
	in __tmp_reg__, __SREG__
	cli
	; Make sure all threads but 0 have clear flags (IDK why this is needed):
	ldi r27, 1
	ldi ZL, lo8(thread_buf + THREAD_SIZE)
	ldi ZH, hi8(thread_buf + THREAD_SIZE)
0:	cpi r27, AVRT_MAX_THREADS
	brge 1f
	st Z, __zero_reg__
	inc r27
	adiw ZL, THREAD_SIZE
	rjmp 0b
1:	; Mark thread 0 as used:
	ldi r24, RUNNING_FLAG
	sts thread_buf, r24
	ldi r24, 0
	out __SREG__, __tmp_reg__
	ret
.size avrt_init, . - avrt_init

avrt_start:
	in __tmp_reg__, __SREG__
	cli
	clr r27
	ldi ZL, lo8(thread_buf)
	ldi ZH, hi8(thread_buf)
0:	cpi r27, AVRT_MAX_THREADS
	brge .Lnone
	ld r26, Z
	tst r26
	breq .Lfound
	inc r27
	adiw ZL, THREAD_SIZE
	rjmp 0b
.Lfound:
	ldi r26, RUNNING_FLAG
	st Z, r26
	; Offset the stack (simulate pushing a bunch) and store it:
	subi r20, THREAD_STACK_SAVE_SIZE
	sbc r21, __zero_reg__
	std Z+1, r20
	std Z+2, r21
	movw ZL, r20
	; Set the initial SREG:
	std Z+1, __zero_reg__
	; Initialize the argument (r24-r25) of the thread function:
	std Z+8, r25
	std Z+9, r24
	; Initialize the instruction pointer to the thread function:
	std Z+34, r23
	std Z+35, r22
	mov r24, r27
	out __SREG__, __tmp_reg__
	ret
.Lnone:
	ldi r24, -1
	out __SREG__, __tmp_reg__
	ret
.size avrt_start, . - avrt_start

avrt_block:
	; The flags will be set to BLOCKED_FLAG:
	ldi r24, BLOCKED_FLAG
set_flags_and_yield:
	cli
	ldi ZL, lo8(thread_buf)
	ldi ZH, hi8(thread_buf)
	lds r18, avrt_self
	ldi r19, THREAD_SIZE
	mul r18, r19
	add ZL, r0
	adc ZH, r1
	clr __zero_reg__
	st Z, r24
avrt_yield:
	cli
AVRT_INTERRUPT:
	; The instruction pointer has been saved by the hardware.
	; Save registers and SREG on the stack too:
	push r0
	push r1
	push r2
	push r3
	push r4
	push r5
	push r6
	push r7
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15
	push r16
	push r17
	push r18
	push r19
	push r20
	push r21
	push r22
	push r23
	push r24
	push r25
	push r26
	push r27
	push r28
	push r29
	push r30
	push r31
	in __tmp_reg__, __SREG__
	push __tmp_reg__
	; Point Z to the current thread and set r18 to its ID:
	ldi ZL, lo8(thread_buf)
	ldi ZH, hi8(thread_buf)
	lds r18, avrt_self
	ldi r19, THREAD_SIZE
	mul r18, r19
	add ZL, r0
	adc ZH, r1
	; Save the current thread stack pointer:
	in __tmp_reg__, __SP_L__
	std Z+1, __tmp_reg__
	in __tmp_reg__, __SP_H__
	std Z+2, __tmp_reg__
	; This loop now finds the next thread to switch to:
0:	adiw ZL, THREAD_SIZE
	inc r18
	cpi r18, AVRT_MAX_THREADS
	brlt 1f
	; Wrap back to the start:
	clr r18
	ldi ZL, lo8(thread_buf)
	ldi ZH, hi8(thread_buf)
1:	ld r17, Z
	tst r17
	; Loop until a running thread is found (brpl = RUNNING_FLAG not set):
	brpl 0b
	; Set the current thread ID to the newfound thread:
	sts avrt_self, r18
	; Restore the context of the new thread:
	; Restore the stack pointer:
	ldd __tmp_reg__, Z+1
	out __SP_L__, __tmp_reg__
	ldd __tmp_reg__, Z+2
	out __SP_H__, __tmp_reg__
	; Restore the SREG:
	pop __tmp_reg__
	out __SREG__, __tmp_reg__
	; Restore the registers:
	pop r31
	pop r30
	pop r29
	pop r28
	pop r27
	pop r26
	pop r25
	pop r24
	pop r23
	pop r22
	pop r21
	pop r20
	pop r19
	pop r18
	pop r17
	pop r16
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop r7
	pop r6
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	; Restore the instruction pointer and enable interrupts:
	reti
.size AVRT_INTERRUPT, . - AVRT_INTERRUPT
.size avrt_yield, . - avrt_yield
.size set_flags_and_yield, . - set_flags_and_yield
.size avrt_block, . - avrt_block

avrt_exit:
	; The flags will be set to zero:
	clr r24
	rjmp set_flags_and_yield
.size avrt_exit, . - avrt_exit

avrt_unblock:
	in r26, __SREG__
	cli
	ldi ZL, lo8(thread_buf)
	ldi ZH, hi8(thread_buf)
	ldi r25, THREAD_SIZE
	mul r24, r25
	add ZL, r0
	adc ZH, r1
	clr r24
	ld r27, Z
	cpi r27, BLOCKED_FLAG
	brne 0f
	ldi r27, RUNNING_FLAG
	st Z, r27
	ldi r24, 1
0:	clr __zero_reg__
	out __SREG__, r26
	ret
.size avrt_unblock, . - avrt_unblock

.data

.type thread_buf, @object

thread_buf:
.space AVRT_MAX_THREADS * THREAD_SIZE
.size thread_buf, . - thread_buf

avrt_self:
.byte 0
.size avrt_self, 1
