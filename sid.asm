; Timer 3 setup (written to TCCR3A:TCCR3B): 
; fast PWM, TOP = OCR3A
; set OC3B pin on Compare Match, clear at TOP,
; internal clock, no prescaling
.equ    TIMER3_SETUPA = (1 << COM3B0) | (1 << COM3B1) | \
                        (1 << WGM30) | (1 << WGM31) 
.equ    TIMER3_SETUPB = (1 << WGM32) | (1 << WGM33) | \
                        (1 << CS30)

; generated clock: 14.7456 MHz / 15 = 0.983 MHz
; original C64 clock frequency (PAL): 0.985 MHz
.equ    SID_CYCLE_LENGTH = 15

; number of SID cycles to wait between interrupts
.equ    WAIT_SID_CYCLES = 16

; Timer 1 setup (written to TCCR1A:TCCR1B): 
; fast PWM, TOP = OCR1A
; do nothing with OC1B pin,
; external clock source on T1 pin, clock on rising edge
.equ    TIMER1_SETUPA = (1 << WGM10) | (1 << WGM11) 
.equ    TIMER1_SETUPB = (1 << WGM12) | (1 << WGM13) | \
                        (1 << CS10) |(1 << CS11) | (1 << CS12)

sid_init:
    ldi     temp, TIMER3_SETUPA         ; set up SID clock timer
    sts     TCCR3A, temp
    ldi     temp, TIMER3_SETUPB
    sts     TCCR3B, temp                
    ldi     temp, SID_CYCLE_LENGTH - 1  ; set TOP
    sts     OCR3AH, zero
    sts     OCR3AL, temp    
    ldi     temp, SID_CYCLE_LENGTH / 2  ; set compare value
    sts     OCR3BH, zero
    sts     OCR3BL, temp

    sbi     DDRB, PB4                   ; clock line as output

    ldi     temp, 0xff
    out     ADDR_PORT, temp
       
    sbi     CTRL_PORT, RES              ; enable SID (reset to high)    

    ldi     temp, TIMER1_SETUPA        ; set up timer
    out     TCCR1A, temp
    ldi     temp, TIMER1_SETUPB        ; set up timer
    out     TCCR1B, temp
    ldi     temp, WAIT_SID_CYCLES - 1
    sts     OCR1AH, zero
    out     OCR1AL, temp
    
    in      temp, TIMSK                 ; enable interrupt
    sbr     temp, 1 << OCIE1A
    out     TIMSK, temp
    ret

.def    delayH = r25        ; be careful. these registers are also
.def    delayL = r24        ; used by the command processing loop
 
TIM1_COMPA:
    out     ADDR_PORT, addr     ; write values	
    out     DATA_PORT, data    

    in      stashA, SREG    ; save SREG
    mov     stashB, r24     ; stash contents of r24/r25
    mov     stashC, r25
    
    ; CAUTION! do not trash temp or call functions that do so.
        
    ldi     YH, 0x01        ; load current delay from buffer
    ld      delayH, Y
    ldi     YH, 0x02
    ld      delayL, Y
    
    sbiw    delayL, WAIT_SID_CYCLES
    brlo    perform_write
    st      Y, delayL
    ldi     YH, 0x01
    st      Y, delayH
    rjmp    end
    
perform_write:    
    
    ; TODO: busy-wait the exact number of remaining SID cycles
    
    ldi     YH, 0x03        ; load current address from buffer
    ld      addr, Y
    ldi     YH, 0x04        ; load current data from buffer
    ld      data, Y
    
sid_write:
    ;ldi     tmpi, 1 << TOV3    
    ;sts     ETIFR, tmpi          ; clear flag    
sid_write_wait:
    ;lds      tmpi, ETIFR          ; wait until flag is set
    ;sbrs    tmpi, TOV3          
    ;rjmp    sid_write_wait          
    	
    
    inc     YL              ; advance to next buffer position
    cpi     YL, BUFSIZE     
    brlo    end
    clr     YL              ; wrap around at buffer end 
        
end:    
    mov     r25, stashC     ; restore contents of r24/r25
    mov     r24, stashB
    out     SREG, stashA    ; restore SREG
    reti
