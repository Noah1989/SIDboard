.nolist
.include "m162def.inc"

.list

.equ    ADDR_PORT = PORTA
.equ    ADDR_DDR = DDRA

.equ    DATA_PORT = PORTC
.equ    DATA_DDR = DDRC

.equ    CTRL_PORT = PORTE
.equ    CTRL_DDR = DDRE
.equ    RES = PE0   ; reset
.equ    RWC = PE1   ; read/write control

        ; Timer 1 setup (written to TCCR1A:TCCR1B): 
        ; fast PWM, TOP = OCR1A
        ; set OC1B pin on Compare Match, clear at TOP,
        ; internal clock, no prescaling
.equ    TIMER1_SETUPA = (1 << COM1B0) | (1 << COM1B1) | \
                        (1 << WGM10) | (1 << WGM11) 
.equ    TIMER1_SETUPB = (1 << WGM12) | (1 << WGM13) | \
                        (1 << CS10)
                       
.equ    CPU_CLOCK = 14745600               

        ; generated clock: 14.7456 MHz / 15 = 0.983 MHz
        ; original C64 clock frequency (PAL): 0.985 MHz
.equ    SID_CYCLE_LENGTH = 15

.equ    BUFSIZE = 240   ; be careful to leave enough space for the stack!
                        
.def    zero = r0  ; always zero
.def    temp = r16  ; temporary register, preserved by interrupts,
                    ; used as argument and/or return value for subroutines
                    
.def    addr = r17  ; SID address, used by write interrupt
.def    data = r18  ; SID data, used by write interrupt

.def    command = r19   ; currently processed command
.def    datlenH = r25   ; length of received data
.def    datlenL = r24   ;

.cseg

.include "interrupts.asm"
.include "usart.asm"
.include "sid.asm"
.include "chime.asm"

RESET:
    clr     temp                ; set up zero register
    mov     zero, temp    
    
    out     ADDR_PORT, zero     ; init ports to zero
    out     DATA_PORT, zero
    out     CTRL_PORT, zero    

    ldi     temp, 0xFF          ; set ports as outputs
    out     ADDR_DDR, temp
    out     DATA_DDR, temp
    out     CTRL_DDR, temp
       
    ldi     temp, high(RAMEND)  ; initialize stack
    out     SPH, temp
    ldi     temp, low(RAMEND)
    out     SPL, temp    

    clr     XL                  ; clear buffer write pointer
    clr     YL                  ; clear buffer read pointer

    sei                         ; enable interrupts

    rcall   usart_init          ; initialize USART
    rcall   sid_init            ; initialize SID       
    rcall   chime               ; power-on chime
    
loop:
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
    
    rjmp    loop

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
    mov     data, temp
    ldi     addr, 0x18      ; volume register
    rcall   sid_write
    
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
    ; TODO: destroy queued data on all SIDs, and cease audio production
    ldi     temp, 0x00      ; OK
    rcall   usart_transmit
    ret
    
command_try_write:
    ; try to queue a number of write-to-sid events
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
    brne    command_try_write
    
    ldi     temp, 0x00      ; OK
    rcall   usart_transmit
    ret
	
