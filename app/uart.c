/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */

#include <stdint.h>
#include "uart.h"

#define UART_TXDATA (*(volatile uint8_t *)(uintptr_t)0x40000010u)
#define UART_STATUS (*(volatile uint32_t *)(uintptr_t)0x40000014u)
#define UART_STATUS_TX_FULL 1u

void uart_putc(char c) {
    while (UART_STATUS & UART_STATUS_TX_FULL) {
    }
    UART_TXDATA = (uint8_t)c;
}
