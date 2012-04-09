sidws:
    ; synchronous sid write
    ; enables TIM1_OVF to write to the SID
    ; and waits for it to finish
    ldi     temp, 1 << TOV1     ; TOV1 == TOIE1
    out     TIFR, temp          ; clear flag
    out     TIMSK, temp         ; enable interrupt
sidws_wait:
    in      temp, TIMSK
    sbrc    temp, TOIE1
    rjmp    sidws_wait
    ret

TIM1_OVF:
    ; this interrupt does preserve SREG by just not touching it.
    ; be careful!
    out     ADDR_PORT, addr     ; write values	
    out     DATA_PORT, data
	out     TIMSK, zero         ; disable interrupt
	reti
	
.macro sidwsi
    ldi     addr, @0
    ldi     data, @1
    rcall   sidws 
.endm
