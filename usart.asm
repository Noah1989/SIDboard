        ; default settings are used: 1 stop bit, no parity
.equ    BAUD_RATE = 115200

usart_init:
    ldi     temp, CPU_CLOCK / (16*BAUD_RATE) - 1    
    out     UBRR0H, zero    ; set baud rate
    out     UBRR0L, temp
    sbi     UCSR0B, TXEN    ; enable transmitter
    sbi     UCSR0B, RXEN    ; enable receiver
    ret
    
usart_receive:
    sbis    UCSR0A, RXC     ; wait for data to be received
    rjmp    usart_receive
    in      temp, UDR       ; read from buffer
    ret
    
usart_transmit:
    sbis    UCSR0A, UDRE    ; wait for empty transmit buffer
    rjmp    usart_transmit
    out     UDR, temp       ; write into buffer
    ret
