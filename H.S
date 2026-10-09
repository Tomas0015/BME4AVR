; == BME4AVR library ==
; humidity compensation function
; written by Tomas Bezanyi 2026

; --------------------------------------------------
; uint32_t BME4AVR_compensate_H_int32(int32_t adc_H)
; --------------------------------------------------

; int32_t BME4AVR_t_fine;
; uint32_t BME4AVR_compensate_H_int32(int32_t adc_H) {
; 	int32_t v_x1_u32r, a, b, d, e;
; 	
; 	v_x1_u32r = BME4AVR_t_fine - ((int32_t) 76800);
; 	
; 	a = (
; 	(adc_H << 14)
; 	- (((int32_t) c.dig_H4) << 20)
; 	- (((int32_t) c.dig_H5) * v_x1_u32r)
; 	+ ((int32_t) 16384)
; 	) >> 15;
; 	
; 	d = ((v_x1_u32r * ((int32_t) c.dig_H3)) >> 11) + ((int32_t) 32768);
; 	e = ((v_x1_u32r * ((int32_t) c.dig_H6)) >> 10);
; 	
; 	v_x1_u32r =
; 	(
; 	  (
; 	    (
; 	      (
; 	        (d * e) >> 10
; 	      )
; 	      + ((int32_t) 2097152)
; 	    )
; 	    * ((int32_t) c.dig_H2) + 8192
; 	  ) >> 14
; 	)
; 	* a;
; 	
; 	b = v_x1_u32r >> 15;
; 	b = b * b;
; 	b >>= 7;
; 	v_x1_u32r = v_x1_u32r - ((b * ((int32_t) c.dig_H1)) >> 4);
; 			
; 	v_x1_u32r = (v_x1_u32r < 0 ? 0 : v_x1_u32r);
; 	v_x1_u32r = (v_x1_u32r > 419430400 ? 419430400 : v_x1_u32r);
; 	return (uint32_t) (v_x1_u32r >> 12);
; }

; adc_H	 32bit signed
; t_fine 32bit signed
; dig_H1 8bit  unsigned
; dig_H2 16bit signed
; dig_H3 8bit  unsigned
; dig_H4 16bit signed
; dig_H5 16bit signed
; dig_H6 8bit  signed

.equ off_dig_H1, 24
.equ off_dig_H2, 25
.equ off_dig_H3, 27
.equ off_dig_H4, 28
.equ off_dig_H5, 30
.equ off_dig_H6, 32

.text
.global	BME4AVR_compensate_H_int32
.type	BME4AVR_compensate_H_int32, @function
	
BME4AVR_compensate_H_int32:
	; preserve r14:r17
	push r14
	push r15
	push r16
	push r17
	
	; load t_fine to r18:r21
	ldi r30, lo8(BME4AVR_t_fine)
	ldi r31, hi8(BME4AVR_t_fine)
	ld r18, Z+
	ld r19, Z+
	ld r20, Z+
	ld r21, Z+
	
	; load comp struct base addr into Z
	ldi r30, lo8(c)
	ldi r31, hi8(c)
	
	; v_x1_u32r = t_fine - 76800(0x00012c00)
	subi r19, 0x2c
	sbci r20, 0x01
	sbci r21, 0x00
	
	; a = adc_H << 14
	ldi r26, 14
	rcall Shift32_left
	
	; a = a + 16384 (a - -16384(0xffffc000))
	subi r23, 0xc0
	sbci r24, 0xff
	sbci r25, 0xff
	
	; a -> r14:r17
	movw r14, r22
	movw r16, r24
	
	; a = a - (c.dig_H4 << 20)
	ldd r22, Z + off_dig_H4
	ldd r23, Z + off_dig_H4 + 1
	ldi r26, 4
	rcall Shift32_left
	sub r16, r22
	sbc r17, r23
	
	; a = a - (c.dig_H5 * v_x1_u32r)
	ldd r26, Z + off_dig_H5
	ldd r27, Z + off_dig_H5 + 1
	rcall __mulshisi3 ; c.dig_H5 in r26:r27, v_x1_u32r in r18:r21, result in r22:r25
	sub r14, r22
	sbc r15, r23
	sbc r16, r24
	sbc r17, r25
	
	; a = a >> 15
	movw r22, r14
	movw r24, r16
	ldi r26, 15
	rcall Shift32_right
	
	; a -> r14:r17
	movw r14, r22
	movw r16, r24
	
	; d = v_x1_u32r * c.dig_H3
	ldd r26, Z + off_dig_H3
	ldi r27, 0
	rcall __muluhisi3 ; c.dig_H3 in r26:r27, v_x1_u32r in r18:r21, result in r22:r25
	
	; d = d >> 11
	ldi r26, 11
	rcall Shift32_right
	
	; d = d + 32768 (- -32768) (0xffff8000)
	subi r23, 0x80
	sbci r24, 0xff
	sbci r25, 0xff
	
	; store d
	push r22
	push r23
	push r24
	push r25
	
	; load c.dig_H6 to r26, extend to int16
	ldd r26, Z + off_dig_H6
	sbrc r26, 7
	ldi r27, 0xff
	
	; e = v_x1_u32r * c.dig_H6
	rcall __mulshisi3 ; c.dig_H6 in r26:r27, v_x1_u32r in r18:r21, result in r22:r25
	
	; e = e >> 10
	ldi r26, 10
	rcall Shift32_right
	
	; v_x1_u32r = d * e
	pop r21
	pop r20
	pop r19
	pop r18
	rcall __mulsi3 ; d in r18:r21, e in r22:r25, result in r22:r25
	
	; v_x1_u32r = v_x1_u32r >> 10
	ldi r26, 10
	rcall Shift32_right
	
	; v_x1_u32r = v_x1_u32r + 2097152 (- -2097152) (0xffe00000)
	subi r24, 0xe0
	sbci r25, 0xff
	
	; v_x1_u32r = v_x1_u32r * c.dig_H2
	movw r18, r22
	movw r20, r24
	ldd r26, Z + off_dig_H2
	ldd r27, Z + off_dig_H2 + 1
	rcall __mulshisi3 ; c.dig_H2 in r26:r27, v_x1_u32r in r18:r21, result in r22:r25
	
	; v_x1_u32r = v_x1_u32r + 8192 (- -8192) (0xffffe000)
	subi r23, 0xe0
	sbci r24, 0xff
	sbci r25, 0xff
	
	; v_x1_u32r = v_x1_u32r >> 14
	ldi r26, 14
	rcall Shift32_right
	
	; v_x1_u32r = v_x1_u32r * a
	movw r18, r14
	movw r20, r16
	rcall __mulsi3 ; a in r18:r21, v_x1_u32r in r22:r25, result in r22:r25
	
	; v_x1_u32r -> r14:r17
	movw r14, r22
	movw r16, r24
	
	; b = v_x1_u32r >> 15
	ldi r26, 15
	rcall Shift32_right
	
	; b = b * b
	movw r18, r22
	movw r20, r24
	rcall __mulsi3 ; b in r18:r21 and r22:r25, result in r22:r25
	
	; b = b >> 7
	ldi r26, 7
	rcall Shift32_right
	
	; b = b * c.dig_H1
	movw r18, r22
	movw r20, r24
	ldd r26, Z + off_dig_H1
	ldi r27, 0
	rcall __muluhisi3 ; c.dig_H1 in r26:r27, b in r18:r21, result in r22:r25
	
	; b = b >> 4
	ldi r26, 4
	rcall Shift32_right
	
	; v_x1_u32r = v_x1_u32r - b
	sub r14, r22
	sbc r15, r23
	sbc r16, r24
	sbc r17, r25
	
	; v_x1_u32r -> r22:r25
	movw r22, r14
	movw r24, r16
	
	; restore r14:r17
	pop r17
	pop r16
	pop r15
	pop r14
	
	; not checking if hum < 0% or > 100%
	
	; return v_x1_u32r >> 12
	ldi r26, 12
	rjmp Shift32_right
