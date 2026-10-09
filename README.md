# BME4AVR Library
Compensation functions for the BME280 sensor, space-optimized for AVR microcontrollers. Hand-compiled into assembly, based on [Bosch's int32 functions](https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bme280-ds002.pdf#page=25).

## BME4AVR vs Bosch comparison
Bosch functions were compiled with avr-gcc 7.3.0 using `-Os`.

Size (in bytes):
|                         | BME4AVR | Bosch |
|-------------------------|--------:|------:|
| Temperature function    |     124 |   244 |
| Pressure function       |     360 |   658 |
| Humidity function       |     218 |   422 |
| bit-shift macros        |      32 |     0 |
| mul and div subroutines |     154 |   154 |
| total                   |     888 |  1478 |

Execution time (in us, on 16MHz Arduino UNO):
|                         | BME4AVR | Bosch |
|-------------------------|--------:|------:|
| Temperature function    |   43,28 | 40,28 |
| Pressure function       |   142,4 | 144,6 |
| Humidity function       |   91,24 | 96,49 |

## Known (possible) issues
- The official Bosch pressure function checks whether a divisor is zero; my code does not.
- Unlinke the official Bosch implementation, the humidity function does not clamp the resulting value and might return humidity above 100 %.
- The library relies on the `__mulsi3` subroutine not overwriting the register pair r30:r31; might break in the future. (tested working with avr-gcc 7.3.0 and 14.2.0)

## Compatibility
The library is compatible with AVRe+, AVRxm and AVRxt cores. A table of devices and cores can be found [here](https://ww1.microchip.com/downloads/en/devicedoc/AVR-Instruction-Set-Manual-DS40002198A.pdf#_OPENTOPIC_TOC_PROCESSING_d138e70024).

## Usage example
```
#include <stdint.h>
#include "BME4AVR.h"

extern BME4AVR_comp_t c;

int main(){
	
	// set compensation parameters
	c.dig_T1 = 1;
	c.dig_T2 = 2;
	c.dig_T3 = 3;
	/*
	...
	*/
	c.dig_H6 = 4;
	
	// calculate temperature, set BME4AVR_t_fine global variable
	int32_t temperature = BME4AVR_compensate_T_int32(123);
	
	// calculate pressure and humidity
	uint32_t pressure = BME4AVR_compensate_P_int32(456);
	uint32_t humidity = BME4AVR_compensate_H_int32(789);
	
	return 0;
}
```