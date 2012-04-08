.org 0x00 
    rjmp RESET       ; Reset Handler
    
.org 0x02 
    reti; jmp EXT_INT0    ; IRQ0 Handler
    
.org 0x04 
    reti; jmp EXT_INT1    ; IRQ1 Handler
    
.org 0x06 
    reti; jmp EXT_INT2    ; IRQ2 Handler
    
.org 0x08 
    reti; jmp PCINT0      ; PCINT0 Handler
    
.org 0x0A 
    reti; jmp PCINT1      ; PCINT1 Handler
    
.org 0x0C 
    reti; jmp TIM3_CAPT   ; Timer3 Capture Handler
    
.org 0x0E 
    reti; jmp TIM3_COMPA  ; Timer3 CompareA Handler
    
.org 0x10 
    reti; jmp TIM3_COMPB  ; Timer3 CompareB Handler
    
.org 0x12 
    reti; jmp TIM3_OVF    ; Timer3 Overflow Handler
    
.org 0x14 
    reti; jmp TIM2_COMP   ; Timer2 Compare Handler
    
.org 0x16 
    reti; jmp TIM2_OVF    ; Timer2 Overflow Handler
    
.org 0x18 
    reti; jmp TIM1_CAPT   ; Timer1 Capture Handler
    
.org 0x1A 
    reti; jmp TIM1_COMPA  ; Timer1 CompareA Handler
    
.org 0x1C 
    reti; jmp TIM1_COMPB  ; Timer1 CompareB Handler
    
.org 0x1E 
    reti; jmp TIM1_OVF    ; Timer1 Overflow Handler
    
.org 0x20 
    reti; jmp TIM0_COMP   ; Timer0 Compare Handler
    
.org 0x22 
    reti; jmp TIM0_OVF    ; Timer0 Overflow Handler
    
.org 0x24 
    reti; jmp SPI_STC     ; SPI Transfer Complete Handler
    
.org 0x26 
    reti; jmp USART0_RXC  ; USART0 RX Complete Handler
    
.org 0x28 
    reti; jmp USART1_RXC  ; USART1 RX Complete Handler
    
.org 0x2A 
    reti; jmp USART0_UDRE ; UDR0 Empty Handler
    
.org 0x2C 
    reti; jmp USART1_UDRE ; UDR1 Empty Handler
    
.org 0x2E 
    reti; jmp USART0_TXC  ; USART0 TX Complete Handler
    
.org 0x30 
    reti; jmp USART1_TXC  ; USART1 TX Complete Handler
    
.org 0x32 
    reti; jmp EE_RDY      ; EEPROM Ready Handler
    
.org 0x34 
    reti; jmp ANA_COMP    ; Analog Comparator Handler
    
.org 0x36 
    reti; jmp SPM_RDY     ; Store Program Memory Ready Handler

