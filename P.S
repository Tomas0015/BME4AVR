; == BME4AVR library ==
; pressure compensation function
; written by Tomas Bezanyi 2026

; --------------------------------------------------
; uint32_t BME4AVR_compensate_P_int32(int32_t adc_P)
; --------------------------------------------------

; int32_t BME4AVR_t_fine;
; uint32_t BME4AVR_compensate_P_int32(int32_t adc_P) {
; 	int32_t var1, var2, var3, var4, a, b, e, f;
; 	uint32_t p, d, g;
; 
; 	var1 = (BME4AVR_t_fine >> 1) - (int32_t) 64000;
; 	a = var1 >> 2;
; 	b = (a * a) >> 11;
; 
; 	var2 = b * ((int32_t) c.dig_P6);
; 	e = (((int32_t) c.dig_P5 * 2) * var1);
; 	var2 = var2 + e;
; 	var2 = (var2 >> 2) + (((int32_t) c.dig_P4) << 16);
; 	var2 >>= 12;
; 
; 	var1 = ((((int32_t) c.dig_P2) * var1) >> 1);
; 	f = (c.dig_P3 * (b >> 2)) >> 3;
; 	var1 = var1 + f;
; 	var1 >>= 18;
; 	var1 = (((32768 + var1))*((int32_t) c.dig_P1)) >> 15;
; 	
; 	if (var1 == 0) {
; 		return 0; // avoid exception caused by division by zero
; 	}
; 	
; 	p = ((uint32_t) (((int32_t) 1048576) - adc_P) - var2) * 3125;
; 	if (p < 0x80000000) {
; 		p = (p << 1) / ((uint32_t) var1);
; 	} else {
; 		p = (p / (uint32_t) var1) * 2;
; 	}
; 	
; 	g = p >> 2;
; 	d = g >> 1;
; 	d = (d * d) >> 13;
; 	
; 	var3 = (((int32_t) c.dig_P9) * d) >> 12;
; 	var4 = (((int32_t) g) * ((int32_t) c.dig_P8)) >> 13;
; 	
; 	return ((int32_t) p + ((var3 + var4 + c.dig_P7) >> 4));
; }

; adc_P	 32bit signed
; t_fine 32bit signed
; dig_P1 16bit unsigned
; dig_P2 16bit signed
; dig_P3 16bit signed
; dig_P4 16bit signed
; dig_P5 16bit signed
; dig_P6 16bit signed
; dig_P7 16bit signed
; dig_P8 16bit signed
; dig_P9 16bit signed

.equ off_dig_P1, 6
.equ off_dig_P2, 8
.equ off_dig_P3, 10
.equ off_dig_P4, 12
.equ off_dig_P5, 14
.equ off_dig_P6, 16
.equ off_dig_P7, 18
.equ off_dig_P8, 20
.equ off_dig_P9, 22

.text
.global	BME4AVR_compensate_P_int32
.type	BME4AVR_compensate_P_int32, @function
	
BME4AVR_compensate_P_int32:
	; preserve r10:r17
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15
	push r16
	push r17
	
	; adc_P in r22:r25, store for later use
	push r22
	push r23
	push r24
	push r25
	
	; load t_fine to r22:r25
	ldi r30, lo8(BME4AVR_t_fine)
	ldi r31, hi8(BME4AVR_t_fine)
	ld r22, Z+
	ld r23, Z+
	ld r24, Z+
	ld r25, Z+
	
	; t_fine = t_fine >> 1
	rcall Shift32_right_1
	
	; var1 = t_fine - 64000 (0xfa00)
	subi r23, 0xfa
	sbc r24, r1
	sbc r25, r1
	
	; var1 -> r14:r17
	movw r14, r22
	movw r16, r24
	
	; a = var1 >> 2
	ldi r26, 2
	rcall Shift32_right
	
	; b = a * a
	movw r18, r22
	movw r20, r24
	rcall __mulsi3 ; a in r18:r21 and r22:r25, result in r22:r25
	
	; b = b >> 11
	ldi r26, 11
	rcall Shift32_right
	
	; b -> r18:r21
	movw r18, r22
	movw r20, r24
	
	; b = b >> 2
	ldi r26, 2
	rcall Shift32_right
	
	; b -> r10:r13
	movw r10, r22
	movw r12, r24
	
	; load comp struct base addr into Z
	ldi r30, lo8(c)
	ldi r31, hi8(c)
	
	; var2 = (nonshifted)b * c.dig_P6
	ldd r26, Z + off_dig_P6
	ldd r27, Z + off_dig_P6 + 1
	rcall __mulshisi3 ; c.dig_P6 in r26:r27, b in r18:r21, result in r22:r25
	
	; var1 -> r18:r21, var2 -> r14:r17
	movw r18, r14
	movw r20, r16
	movw r14, r22
	movw r16, r24
	
	; e = c.dig_P5 * var1 * 2
	ldd r26, Z + off_dig_P5
	ldd r27, Z + off_dig_P5 + 1
	rcall __mulshisi3 ; c.dig_P5 in r26:r27, var1 in r18:r21, result in r22:r25
	rcall Shift32_left_1
	
	; var2 = var2 + e
	add r22, r14
	adc r23, r15
	adc r24, r16
	adc r25, r17
	
	; var2 = var2 >> 2
	ldi r26, 2
	rcall Shift32_right
	
	; var2 = var2 + c.dig_P4 << 16
	ldd r26, Z + off_dig_P4
	ldd r27, Z + off_dig_P4 + 1
	add r24, r26
	adc r25, r27
	
	; var2 = var2 >> 12
	ldi r26, 12
	rcall Shift32_right
	
	; var2 -> r14:r17
	movw r14, r22
	movw r16, r24
	
	; var1 = c.dig_P2 * var1
	ldd r26, Z + off_dig_P2
	ldd r27, Z + off_dig_P2 + 1
	rcall __mulshisi3 ; c.dig_P2 in r26:r27, var1 in r18:r21, result in r22:r25
	
	; var1 = var1 >> 1
	rcall Shift32_right_1
	
	; b -> r18:r21, var1 -> r10:r13
	movw r18, r10
	movw r20, r12
	movw r10, r22
	movw r12, r24
	
	; f = b * c.dig_P3
	ldd r26, Z + off_dig_P3
	ldd r27, Z + off_dig_P3 + 1
	rcall __mulshisi3 ; c.dig_P3 in r26:r27, b in r18:r21, result in r22:r25
	
	; f = f >> 3
	ldi r26, 3
	rcall Shift32_right
	
	; var1 = var1 + f
	add r22, r10
	adc r23, r11
	adc r24, r12
	adc r25, r13
	
	; var1 = var1 >> 18
	ldi r26, 18
	rcall Shift32_right
	
	; var1 = var1 + 32768 (0x8000)
	ldi r26, 0x80
	add r23, r26
	adc r24, r1
	adc r25, r1
	
	; var1 = var1 * c.dig_P1
	movw r18, r22
	movw r20, r24
	ldd r26, Z + off_dig_P1
	ldd r27, Z + off_dig_P1 + 1
	rcall __muluhisi3 ; c.dig_P1 in r26:r27, var1 in r18:r21, result in r22:r25
	
	; var1 = var1 >> 15
	ldi r26, 15
	rcall Shift32_right
	
	; var1 -> r10:r13
	movw r10, r22
	movw r12, r24
	
	; not checking if var1 == 0, may divide by zero
	
	; restore adc_P
	pop r25
	pop r24
	pop r23
	pop r22
	
	; p = 1048576(0x00100000) - adc_P
	ldi r18, 0x00
	ldi r19, 0x00
	ldi r20, 0x10
	ldi r21, 0x00
	sub r18, r22
	sbc r19, r23
	sbc r20, r24
	sbc r21, r25
	
	; p = p - var2
	sub r18, r14
	sbc r19, r15
	sbc r20, r16
	sbc r21, r17
	
	; p = p * 3125(0x0c35)
	ldi r26, 0x35
	ldi r27, 0x0c
	rcall __muluhisi3 ; 3125 in r26:r27, p in r18:r21, result in r22:r25
	
	; keep p MSB for later
	mov r17, r25
	
	; if p MSb cleared, double p
	sbrs r17, 7
	rcall Shift32_left_1
	
	; p = p / var1
	movw r18, r10
	movw r20, r12
	rcall __udivmodsi4 ; p in r22:r25, var1 in r18:r21, result in r18:r21
	movw r22, r18
	movw r24, r20
	
	; double p (if not already)
	sbrc r17, 7
	rcall Shift32_left_1

	; p -> r10:r13
	movw r10, r22
	movw r12, r24
	
	; g = p >> 2
	ldi r26, 2
	rcall Shift32_right
	
	; g -> r14:r17
	movw r14, r22
	movw r16, r24
	
	; d = g >> 1
	rcall Shift32_right_1
	
	; d = d * d
	movw r18, r22
	movw r20, r24
	rcall __mulsi3 ; d in r18:r21 and r22:r25, result in r22:r25
	
	; d = d >> 13
	ldi r26, 13
	rcall Shift32_right
	
	; restore comp struct base addr after div
	ldi r30, lo8(c)
	ldi r31, hi8(c)
	
	; var3 = d * c.dig_P9
	movw r18, r22
	movw r20, r24
	ldd r26, Z + off_dig_P9
	ldd r27, Z + off_dig_P9 + 1
	rcall __mulshisi3 ; c.dig_P9 in r26:r27, d in r18:r21, result in r22:r25
	
	; var3 = var3 >> 12
	ldi r26, 12
	rcall Shift32_right
	
	; g -> r18:r21, var3 -> r14:r17
	movw r18, r14
	movw r20, r16
	movw r14, r22
	movw r16, r24
	
	; var4 = g * c.dig_P8
	ldd r26, Z + off_dig_P8
	ldd r27, Z + off_dig_P8 + 1
	rcall __mulshisi3 ; c.dig_P8 in r26:r27, g in r18:r21, result in r22:r25
	
	; var4 = var4 >> 13
	ldi r26, 13
	rcall Shift32_right
	
	; var4 = var4 + var3
	add r22, r14
	adc r23, r15
	adc r24, r16
	adc r25, r17
	
	; var4 = var4 + c.dig_P7
	ldd r26, Z + off_dig_P7
	ldd r27, Z + off_dig_P7 + 1
	add r22, r26
	adc r23, r27
	adc r24, r1
	adc r25, r1
	
	; var4 = var4 >> 4
	ldi r26, 4
	rcall Shift32_right
	
	; return p + var4
	add r22, r10
	adc r23, r11
	adc r24, r12
	adc r25, r13
	
	; restore r10:r17
	pop r17
	pop r16
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	
	ret
