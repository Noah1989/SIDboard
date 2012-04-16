; Timer 1 setup (written to TCCR1A:TCCR1B): 
; fast PWM, TOP = OCR1A
; set OC1B pin on Compare Match, clear at TOP,
; internal clock, no prescaling
.equ    TIMER1_SETUPA = (1 << COM1B0) | (1 << COM1B1) | \
                        (1 << WGM10) | (1 << WGM11) 
.equ    TIMER1_SETUPB = (1 << WGM12) | (1 << WGM13) | \
                        (1 << CS10)

; generated clock: 14.7456 MHz / 15 = 0.983 MHz
; original C64 clock frequency (PAL): 0.985 MHz
.equ    SID_CYCLE_LENGTH = 15

sid_init:
    ldi     temp, TIMER1_SETUPA         ; set up SID clock timer
    out     TCCR1A, temp
    ldi     temp, TIMER1_SETUPB
    out     TCCR1B, temp                
    ldi     temp, SID_CYCLE_LENGTH - 1  ; set TOP
    out     OCR1AH, zero
    out     OCR1AL, temp    
    ldi     temp, SID_CYCLE_LENGTH / 2  ; set compare value
    out     OCR1BH, zero
    out     OCR1BL, temp

    ldi     temp, 0xff
    out     ADDR_PORT, temp
       
    sbi     CTRL_PORT, RES              ; enable SID (reset to high)

    
sid_write:
    ; synchronous sid write, should not be called when interrupts could occur
    ; waits for the next SID cycle and writes to the SID
    ldi     tmpi, 1 << TOV1     
    out     TIFR, tmpi          ; clear flag    
sid_write_wait:
    in      tmpi, TIFR          ; wait until flag is set
    sbrs    tmpi, TOV1          
    rjmp    sid_write_wait          
    out     ADDR_PORT, addr     ; write values	
    out     DATA_PORT, data    
    ret
	
.macro sidwsi
    ldi     addr, @0
    ldi     data, @1
    rcall   sid_write 
.endm
