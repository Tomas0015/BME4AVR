// == BME4AVR library ==
// main header file
// written by Tomas Bezanyi 2026

#ifndef BME4AVR_H
#define	BME4AVR_H

#include <stdint.h>

typedef struct {
	uint16_t dig_T1;
	int16_t dig_T2;
	int16_t dig_T3;
	uint16_t dig_P1;
	int16_t dig_P2;
	int16_t dig_P3;
	int16_t dig_P4;
	int16_t dig_P5;
	int16_t dig_P6;
	int16_t dig_P7;
	int16_t dig_P8;
	int16_t dig_P9;
	uint8_t dig_H1;
	int16_t dig_H2;
	uint8_t dig_H3;
	int16_t dig_H4;
	int16_t dig_H5;
	int8_t dig_H6;
} BME4AVR_comp_t;


#ifdef	__cplusplus
#define _exc extern "C"
#else
#define _exc 
#endif

// Returns temperature in DegC, resolution is 0.01 DegC. Output value of "5123" equals 51.23 DegC.
_exc int32_t BME4AVR_compensate_T_int32(int32_t adc_T);

// Returns pressure in Pa as unsigned 32 bit integer. Output value of "96386" equals 96386 Pa = 963.86 hPa
_exc uint32_t BME4AVR_compensate_P_int32(int32_t adc_P);

// Returns humidity in %RH as unsigned 32 bit integer in Q22.10 format (22 integer and 10 fractional bits).
// Output value of "47445" represents 47445/1024 = 46.333 %RH
_exc uint32_t BME4AVR_compensate_H_int32(int32_t adc_H);

#endif	/* BME4AVR_H */
