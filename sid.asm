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
    
    in      temp, TIMSK                 ; enable interrupt
    sbr     temp, 1 << OCIE1A
    out     TIMSK, temp
    ret

 
TIM1_COMPA:
    ; RISING EDGE -------------------------------
    ;interrupt response time: 4 4  
    ; rjmp from vector table: 2 6
    in      stashA, SREG    ; 1 7
    ; FALLING EDGE ------------------------------
    mov     stashB, r24     ; 1 1
    mov     stashC, r25     ; 1 2       
        
    ldi     YH, 0x01        ; 1 3
    ld      r25, Y          ; 2 5
    ldi     YH, 0x02        ; 1 6
    ld      r24, Y          ; 2 8    
    ; RISING EDGE -------------------------------            
    ldi     YH, 0x03        ; 1 1
    ld      addr, Y         ; 2 3        
    ldi     YH, 0x04        ; 1 4
    ld      data, Y         ; 2 6    
    sbiw    r24, 1          ; 1 7
    ; FALLING EDGE ------------------------------        
    ;second cycle from sbiw ; 1 1    
    out     ADDR_PORT, addr ; 1 2
    out     DATA_PORT, data ; 1 3
    ; remaining cycles until RISING EDGE: 5
    out     OCR1AH, r25
    out     OCR1AL, r24  
    
    inc     YL             
    cpi     YL, BUFSIZE 
    brlo    TIM1_COMPA_end
    clr     YL        
TIM1_COMPA_end:       
    mov     r25, stashC
    mov     r24, stashB
    out     SREG, stashA
    reti
