#include <avr/io.h>

#define AVRT_MAX_THREADS 4
#define AVRT_INTERRUPT TIMER0_OVF_vect

/*
Thread structure:
1	flags
1	SREG
2	instruction pointer
2	stack pointer
32	r0-r31
*/

#define THREAD_SIZE 38

#define USED_FLAG 0x80

.text

.global avrt_init
.type avrt_init, @function
.global avrt_start
.type avrt_start, @function
.global avrt_exit
.type avrt_exit, @function
.global avrt_yield
.type avrt_yield, @function
.global AVRT_INTERRUPT
.type AVRT_INTERRUPT, @function

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
	ldi r24, USED_FLAG
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
	ldi r26, USED_FLAG
	st Z, r26
	std Z+1, __zero_reg__
	std Z+2, r22
	std Z+3, r23
	std Z+4, r20
	std Z+5, r21
	std Z+30, r24
	std Z+31, r25
	mov r24, r27
	out __SREG__, __tmp_reg__
	ret
.Lnone:
	ldi r24, -1
	out __SREG__, __tmp_reg__
	ret
.size avrt_start, . - avrt_start

avrt_exit:
	cli
	ldi ZL, lo8(thread_buf)
	ldi ZH, hi8(thread_buf)
	lds r17, current_thread
	ldi r18, THREAD_SIZE
	mul r17, r18
	add ZL, r0
	adc ZH, r1
	clr __zero_reg__
	st Z, __zero_reg__
avrt_yield:
	cli
AVRT_INTERRUPT:
	; Save Y, Z, and some temporary registers:
	push YL
	push YH
	push ZL
	push ZH
	push r17
	push r18
	; Save SREG in tmp:
	in r17, __SREG__
	sts tmp, r17
	; r17 is the current thread ID:
	lds r17, current_thread
	; r18 is the thread iterator:
	clr r18
	; Y is the pointer to the current thread:
	ldi YL, lo8(thread_buf)
	ldi YH, hi8(thread_buf)
0:	cp r18, r17
	; Break when the iterator equals the current:
	breq 1f
	inc r18
	adiw YL, THREAD_SIZE
	rjmp 0b
1:	movw ZL, YL
	; Y and Z now point to the current thread.
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
	; Loop until a running thread is found:
	breq 0b
	; Set the current thread ID to the newfound thread:
	sts current_thread, r18
	; Save the current thread:
	; Save SREG (interrupt enable bit is ignored due to reti):
	lds r17, tmp
	std Y+1, r17
	; Restore temporary registers:
	pop r18
	pop r17
	; Save r0-r27:
	std Y+6, r0
	std Y+7, r1
	std Y+8, r2
	std Y+9, r3
	std Y+10, r4
	std Y+11, r5
	std Y+12, r6
	std Y+13, r7
	std Y+14, r8
	std Y+15, r9
	std Y+16, r10
	std Y+17, r11
	std Y+18, r12
	std Y+19, r13
	std Y+20, r14
	std Y+21, r15
	std Y+22, r16
	std Y+23, r17
	std Y+24, r18
	std Y+25, r19
	std Y+26, r20
	std Y+27, r21
	std Y+28, r22
	std Y+29, r23
	std Y+30, r24
	std Y+31, r25
	std Y+32, r26
	std Y+33, r27
	; Save Z (r30-r31):
	pop __tmp_reg__
	std Y+37, __tmp_reg__
	pop __tmp_reg__
	std Y+36, __tmp_reg__
	; Save Y (r28-r29):
	pop __tmp_reg__
	std Y+35, __tmp_reg__
	pop __tmp_reg__
	std Y+34, __tmp_reg__
	; Save instruction pointer:
	pop __tmp_reg__
	std Y+3, __tmp_reg__
	pop __tmp_reg__
	std Y+2, __tmp_reg__
	; Save stack pointer:
	in __tmp_reg__, __SP_L__
	std Y+4, __tmp_reg__
	in __tmp_reg__, __SP_H__
	std Y+5, __tmp_reg__
	; Switch to new thread:
	; Restore SREG:
	ldd __tmp_reg__, Z+1
	out __SREG__, __tmp_reg__
	; Restore stack pointer:
	ldd __tmp_reg__, Z+4
	out __SP_L__, __tmp_reg__
	ldd __tmp_reg__, Z+5
	out __SP_H__, __tmp_reg__
	; Push instruction pointer to return to:
	ldd __tmp_reg__, Z+2
	push __tmp_reg__
	ldd __tmp_reg__, Z+3
	push __tmp_reg__
	; Push Z to restore at the end:
	ldd __tmp_reg__, Z+36
	push __tmp_reg__
	ldd __tmp_reg__, Z+37
	push __tmp_reg__
	; Restore registers r0-r29:
	ldd r0, Z+6
	ldd r1, Z+7
	ldd r2, Z+8
	ldd r3, Z+9
	ldd r4, Z+10
	ldd r5, Z+11
	ldd r6, Z+12
	ldd r7, Z+13
	ldd r8, Z+14
	ldd r9, Z+15
	ldd r10, Z+16
	ldd r11, Z+17
	ldd r12, Z+18
	ldd r13, Z+19
	ldd r14, Z+20
	ldd r15, Z+21
	ldd r16, Z+22
	ldd r17, Z+23
	ldd r18, Z+24
	ldd r19, Z+25
	ldd r20, Z+26
	ldd r21, Z+27
	ldd r22, Z+28
	ldd r23, Z+29
	ldd r24, Z+30
	ldd r25, Z+31
	ldd r26, Z+32
	ldd r27, Z+33
	ldd r28, Z+34
	ldd r29, Z+35
	; Restore Z:
	pop ZH
	pop ZL
	; Restore the instruction pointer:
	reti
.size AVRT_INTERRUPT, . - AVRT_INTERRUPT
.size avrt_yield, . - avrt_yield
.size avrt_exit, . - avrt_exit

.data

.type thread_buf, @object
.type current_thread, @object
.type tmp, @object

thread_buf:
.space AVRT_MAX_THREADS * THREAD_SIZE
.size thread_buf, . - thread_buf

current_thread:
.byte 0
.size current_thread, 1

tmp:
.byte 0
.size tmp, 1
