#include <avr/io.h>

#define AVRT_MAX_THREADS 4
#define AVRT_INTERRUPT TIMER0_OVF

/*
Thread structure:
1	flags
1	SREG
2	instruction pointer
2	stack pointer
32	r0-r31
*/

#define THREAD_SIZE 38

#define MASK_MAX_THREADS (AVRT_MAX_THREADS - 1)

#define PASTE(a, b) PASTE1(a, b)
#define PASTE1(a, b) PASTE2(a, b)
#define PASTE2(a, b) a##b
#define INTERRUPT_SYMBOL PASTE(AVRT_INTERRUPT, _vect)

.section .text

.global avrt_start
.type avrt_start, @function
.global avrt_exit
.type avrt_exit, @function
.global avrt_yield
.type avrt_yield, @function
.global INTERRUPT_SYMBOL
.type INTERRUPT_SYMBOL, @function

__tmp_reg__ = 0
__zero_reg__ = 0
__SREG__ = 0x3F
__SP_L__ = 0x3D
__SP_H__ = 0x3F

avrt_start:
	in __tmp_reg__, __SREG__
	cli
	clr r27
	ldi ZL, lo8(thread_buf)
	ldi ZH, hi8(thread_buf)
0:	cpi r27, AVRT_MAX_THREADS
	breq .Lnone
	ld r26, Z
	tst r26
	breq .Lfound
	inc r27
	adiw ZL, THREAD_SIZE
	rjmp 0b
.Lfound:
	ldi r26, 0x80
	st Z, r26
	std Z+1, r26
	std Z+2, r20
	std Z+3, r21
	std Z+4, r16
	std Z+5, r17
	std Z+30, r24
	std Z+31, r25
.Lnone:
	out __SREG__, __tmp_reg__
	ret
.size avrt_start, . - avrt_start

avrt_exit:
	cli
	lds r17, current_thread
	ldi ZL, lo8(thread_buf)
	ldi ZH, hi8(thread_buf)
0:	tst r17
	breq 1f
	dec r17
	adiw ZL, THREAD_SIZE
	rjmp 0b
1:	st Z, __zero_reg__
avrt_yield:
	cli
INTERRUPT_SYMBOL:
	push YL
	push YH
	push ZL
	push ZH
	push r17
	push r18
	in r17, __SREG__
	sts tmp, r17
	lds r17, current_thread
	clr r18
	ldi ZL, lo8(thread_buf)
	ldi ZH, hi8(thread_buf)
0:	cp r18, r17
	breq 1f
	inc r18
	adiw YL, THREAD_SIZE
	rjmp 0b
1:	movw ZL, YL
0:	adiw ZL, THREAD_SIZE
	inc r18
	andi r18, MASK_MAX_THREADS
	brne 1f
	ldi ZL, lo8(thread_buf)
	ldi ZH, hi8(thread_buf)
1:	ld r17, Z
	tst r17
	breq 0b
	sts current_thread, r18
	lds r17, tmp
	std Y+1, r17
	pop r18
	pop r17
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
	pop __tmp_reg__
	std Y+37, __tmp_reg__
	pop __tmp_reg__
	std Y+36, __tmp_reg__
	pop __tmp_reg__
	std Y+35, __tmp_reg__
	pop __tmp_reg__
	std Y+34, __tmp_reg__
	pop r27
	pop r26
	std Y+2, r26
	std Y+3, r27
	in __tmp_reg__, __SP_L__
	std Y+4, __tmp_reg__
	in __tmp_reg__, __SP_H__
	std Y+5, __tmp_reg__
	ldd __tmp_reg__, Z+1
	out __SREG__, __tmp_reg__
	ldd __tmp_reg__, Z+4
	out __SP_L__, __tmp_reg__
	ldd __tmp_reg__, Z+5
	out __SP_H__, __tmp_reg__
	ldd __tmp_reg__, Z+2
	push __tmp_reg__
	ldd __tmp_reg__, Z+3
	push __tmp_reg__
	ldd __tmp_reg__, Z+36
	push __tmp_reg__
	ldd __tmp_reg__, Z+37
	push __tmp_reg__
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
	pop ZH
	pop ZL
	reti
.size INTERRUPT_SYMBOL, . - INTERRUPT_SYMBOL
.size avrt_yield, . - avrt_yield
.size avrt_exit, . - avrt_exit

.section .data

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
