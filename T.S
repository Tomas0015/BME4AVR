; == BME4AVR library ==
; temperature compensation function
; written by Tomas Bezanyi 2026

; --------------------------------------------------
; int32_t BME4AVR_compensate_T_int32(int32_t adc_T)
; --------------------------------------------------

; int32_t BME4AVR_t_fine;
; int32_t BME4AVR_compensate_T_int32(int32_t adc_T) {
; 	int32_t var1, var2;
; 	
; 	adc_T >>= 3;
; 
; 	int32_t a = adc_T - ((int32_t) c.dig_T1 << 1);
; 	var1 = (a * ((int32_t) c.dig_T2)) >> 11;
; 
; 	a >>= 1;
; 	var2 = (((a * a) >> 12) * ((int32_t) c.dig_T3)) >> 14;
; 
; 	BME4AVR_t_fine = var1 + var2;
; 	return (BME4AVR_t_fine * 5 + 128) >> 8;
; }

; adc_T	 32bit signed
; dig_T1 16bit unsigned
; dig_T2 16bit signed
; dig_T3 16bit signed
; t_fine 32bit signed

; dig_T1, dig_T2 and dig_T3 must be stored in this sequence

.text
.global	BME4AVR_compensate_T_int32
.type	BME4AVR_compensate_T_int32, @function
	
BME4AVR_compensate_T_int32:
	; adc_T in r22:r25
	
	; a = adc_T >> 3
	ldi r26, 3
	rcall Shift32_right
	
	; a = a - c.dig_T1 * 2
	ldi r30, lo8(c)
	ldi r31, hi8(c)
	ld r26, Z+
	ld r27, Z+
	ldi r18, 2
dig_T1_sub:
	sub     r22, r26
	sbc     r23, r27
	sbc     r24, r1
	sbc     r25, r1
	dec     r18
	brne    dig_T1_sub
	
	; a = a * c.dig_T2
	rcall Load_and_multiply
	
	; var1 = a >> 11
	ldi r26, 11
	rcall Shift32_right
	
	; store var1
	push r22
	push r23
	push r24
	push r25
	
	; restore a after mul
	movw r22, r18
	movw r24, r20
	
	; a = a >> 1
	rcall Shift32_right_1
	
	; a = a * a
	movw r18, r22
	movw r20, r24
	rcall __mulsi3 ; a in r18:r21 and r22:r25, result in r22:r25
	
	; a = a >> 12
	ldi r26, 12
	rcall Shift32_right
	
	; a = a * c.dig_T3
	rcall Load_and_multiply
	
	; var2 = a >> 14
	ldi r26, 14
	rcall Shift32_right
	
	; t_fine = var1 + var2
	pop r21
	pop r20
	pop r19
	pop r18
	add r22, r18
	adc r23, r19
	adc r24, r20
	adc r25, r21
	
	; store t_fine
	ldi r30, lo8(BME4AVR_t_fine)
	ldi r31, hi8(BME4AVR_t_fine)
	st Z+, r22
	st Z+, r23
	st Z+, r24
	st Z+, r25
	
	; T = t_fine * 5 + 128 (... - -128 (0xffffff80))
	ldi r26, 5
	ldi r27, 0
	movw r18, r22
	movw r20, r24
	rcall __muluhisi3 ; 5 in r26:r27, t_fine in r18:r21, result in r22:r25
	subi r22, 0x80
	sbci r23, 0xff
	sbci r24, 0xff
	sbci r25, 0xff
	
	; T = T >> 8
	ldi r26, 8
	rjmp Shift32_right
	; end of function

; loads int16 from (Z), multiplies with r22:r25, result in r22:r25
; clob: r18:r19 = org r22:r25, r26:r27 = (Z)
Load_and_multiply:
	ld r26, Z+
	ld r27, Z+
	movw r18, r22
	movw r20, r24
	rcall __mulshisi3 ; c.dig_Tx in r26:r27, a in r18:r21, result in r22:r25
	ret
	