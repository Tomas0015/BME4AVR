; == BME4AVR library ==
; bit-shift macros
; written by Tomas Bezanyi 2026

.text
.global	Shift32_right
.global	Shift32_right_1
.global	Shift32_left
.global	Shift32_left_1

; shifts r22-r25 right by 1, clob r26
Shift32_right_1:
	ldi r26, 1
	
; shifts r22-r25 right by r26
Shift32_right:
	asr r25
	ror r24
	ror r23
	ror r22
	dec r26
	brne Shift32_right
	ret
	
; shifts r22-r25 left by 1, clob r26
Shift32_left_1:
	ldi r26, 1

; shifts r22-r25 left by r26
Shift32_left:
	add r22, r22
	adc r23, r23
	adc r24, r24
	adc r25, r25
	dec r26
	brne Shift32_left
	ret
	