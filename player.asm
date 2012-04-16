; number of SID cycles to wait between interrupts
.equ WAIT_SID_CYCLES = 16

; Timer 0 setup (written to TCCR0): 
; CTC mode, TOP = OCR0
; no output to pin,
; internal clock, no prescaling
.equ    TIMER0_SETUP = (1 << WGM01) || (1 << CS00)

player_init:
    ldi     temp, TIMER0_SETUP  ; set up timer
    out     TCCR0, temp
    ldi     temp, WAIT_SID_CYCLES * SID_CYCLE_LENGTH - 1
    out     OCR0, temp
    
    in      temp, TIMSK     ; enable interrupt
    sbr     temp, 1 << OCIE0
    out     TIMSK, temp
    ret

.def    delayH = r25        ; be careful. these registers are also
.def    delayL = r24        ; used by the command processing loop
 
TIM0_COMP:
    in      stashA, SREG    ; save SREG
    mov     stashB, r24     ; stash contents of r24/r25
    mov     stashC, r25
    
    ; CAUTION! do not trash temp or call functions that do so.
        
    ldi     YH, 0x01        ; load current delay from buffer
    ld      delayH, Y
    ldi     YH, 0x02
    ld      delayL, Y
    
    sbiw    delayL, WAIT_SID_CYCLES
    brlo    TIM0_COMP_perform_write
    st      Y, delayL
    ldi     YH, 0x01
    st      Y, delayH
    rjmp    TIM0_COMP_end
    
TIM0_COMP_perform_write:    
    
    ; TODO: busy-wait the exact number of remaining SID cycles
    
    ldi     YH, 0x03        ; load current address from buffer
    ld      addr, Y
    ldi     YH, 0x04        ; load current data from buffer
    ld      data, Y
    
    ; TODO: inline    
    rcall   sid_write       ; write to SID
    
    inc     YL              ; advance to next buffer position
    cpi     YL, BUFSIZE     
    brlo    TIM0_COMP_end
    clr     YL              ; wrap around at buffer end 
        
TIM0_COMP_end:    
    mov     r25, stashC     ; restore contents of r24/r25
    mov     r24, stashB
    out     SREG, stashA    ; restore SREG
    reti
