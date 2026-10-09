// == BME4AVR library ==
// global variables
// written by Tomas Bezanyi 2026

#include "BME4AVR.h"

volatile BME4AVR_comp_t c;
volatile int32_t BME4AVR_t_fine; // BME4AVR_t_fine carries fine temperature as global value, set by BME4AVR_compensate_T_int32
