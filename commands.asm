command_loop:
    rcall   usart_receive       ; recieve command
    mov     command, temp
    
    rcall   usart_receive       ; recieve SID number (ignored)
                                ; TODO: use SID number
    
    rcall   usart_receive       ; recieve data length (high byte)
    mov     datlenH, temp
    
    rcall   usart_receive       ; recieve data length (low byte)
    mov     datlenL, temp
    
    
    ldi     ZH, high(command_jump_table)
    ldi     ZL, low(command_jump_table)
    add     ZL, command
    adc     ZH, zero    
    icall  
    
    rjmp    command_loop

command_jump_table:
    rjmp    command_flush               ; 0
    ret ;rjmp    command_try_set_sid_count   ; 1
    rjmp    command_mute                ; 2
    rjmp    command_try_reset           ; 3
    ret ;rjmp    command_try_delay           ; 4
    rjmp    command_try_write           ; 5
    ret ;rjmp    command_try_read            ; 6
    rjmp    command_get_version         ; 7

command_get_version:
    ; returns the version of the SID Network protocol
    ldi     temp, 0x04  ; VERSION
    rcall   usart_transmit
    ldi     temp, 0x01  ; v1
    rcall   usart_transmit
    ret

command_try_reset:    
    ; reset all SIDs, setting volume to provided value.
    cbi     CTRL_PORT, RES  ; RES pin to low (reset SID)
    
    clr     temp            ; wait more than 10 SID clock cycles 
    dec     temp
    brne    PC - 1
    
    sbi     CTRL_PORT, RES  ; enable SID again
    
    rcall   usart_receive   ; receive volume
    mov     data, temp      ; TODO: make this reliable
    ldi     addr, 0x18      ; volume register    
        
    ldi     temp, 0x00      ; OK
    rcall   usart_transmit
    ret
    
command_mute:    
    ; TODO: mute/unmute a voice on specified SID
    rcall   usart_receive   ; receive voice (ignored)
    rcall   usart_receive   ; receive enable (ignored)
    ldi     temp, 0x00      ; OK
    rcall   usart_transmit
    ret
    
command_flush:
    ; destroy queued data on all SIDs, and cease audio production
    ldi     temp, 0xFF    
    clr     XL    
    
command_flush_loop:  
    ldi     XH, 0x01
    st      X, zero         ; delay high byte to zero to avoid long wait queue
    ldi     XH, 0x02
    st      X, temp
    ldi     XH, 0x03
    st      X, temp   
    ldi     XH, 0x04
    st      X, temp
    
    inc     XL              ; advance to next buffer position
    cpi     XL, BUFSIZE    
    brlo    command_flush_loop
    
    ldi     temp, 0x00      ; OK
    rcall   usart_transmit
    ret
    
command_try_write:
    ; try to queue a number of write-to-sid events
    mov     backup, XL
    
command_try_write_loop:    
    cp      XL, YL 
    breq    command_try_write_busy  ; handle buffer overflow

    rcall   usart_receive   ; receive delay (high byte)
    ldi     XH, 0x01        ; and store on 1st page
    st      X, temp                     
    rcall   usart_receive   ; receive delay (low byte)
    ldi     XH, 0x02        ; and store on 2nd page
    st      X, temp
    rcall   usart_receive   ; receive SID address
    ldi     XH, 0x03        ; and store on 3rd page
    st      X, temp   
    rcall   usart_receive   ; receive SID data
    ldi     XH, 0x04        ; and store on 4th page
    st      X, temp
    
    inc     XL              ; advance to next buffer position
    cpi     XL, BUFSIZE     
    brlo    command_try_write_nowrap
    clr     XL              ; wrap around at buffer end
command_try_write_nowrap:    
    sbiw    datlenL, 4      ; loop until no data left
    brne    command_try_write_loop
        
    ldi     temp, 0x00      ; OK
    rcall   usart_transmit
    ret
    
command_try_write_busy:    
    rcall   usart_receive   ; discard data
    sbiw    datlenL, 1
    brne    command_try_write_busy
    mov     XL, backup      ; reset write buffer pointer
    ldi     temp, 0x01      ; BUSY
    rcall   usart_transmit
    ret
