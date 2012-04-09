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
    ; synchronous sid write
    ; waits for the next SID cycle and writes to the SID
    ldi     temp, 1 << TOV1     
    out     TIFR, temp          ; clear flag    
sid_write_wait:
    in      temp, TIFR          ; wait until flag is set
    sbrs    temp, TOV1          
    rjmp    sid_write_wait          
    out     ADDR_PORT, addr     ; write values	
    out     DATA_PORT, data    
    ret
	
.macro sidwsi
    ldi     addr, @0
    ldi     data, @1
    rcall   sid_write 
.endm
