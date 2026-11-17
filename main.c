/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "st7789.h"
#include "perf.h"
#include "util.h"
#include "uart.h"

void RandomChar() {
    // Define MMIO pointers for performance counters based on your memory map
    volatile uint32_t *ctrl_reg   = (volatile uint32_t *) 0x40000000;
    
    int count = 0;
    
    // START COUNTERS: write 1 to control register
    *ctrl_reg = 1;
    
    // Run for a fixed number of steps so the benchmark can complete
    while (count < 1000) {
        uint32_t status = *(volatile uint32_t *)0x40000014;
        count++;
        char c = 'A' + rand() % 26;
        uart_putc(c);   
        pg_lcd_draw_char(rand() % 240, rand() % 240, c, rand() & 0x7, 1);
        pg_lcd_set_pos(0, 14);
        pg_lcd_prints("Status :");
        pg_lcd_printd(status);
    }

    // STOP COUNTERS: write 2 to control register
    *ctrl_reg = 2;
}

int main () {
    pg_lcd_reset();
    RandomChar();
    return 0;
}
