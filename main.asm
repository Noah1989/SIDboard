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
.equ    TIMER1_SETUPA = 1 << COM1B0 | 1 << COM1B1 | \
                        1 << WGM10 | 1 << WGM11 
.equ    TIMER1_SETUPB = 1 << WGM12 | 1 << WGM13 | \
                        1 << CS10
                       
        ; generated clock: 14.7456 MHz / 15 = 0.983 MHz
        ; original C64 clock frequency (PAL): 0.985 MHz
.equ    SID_CYCLE_LENGTH = 15
                        
.def    zero = r0   ; always zero
.def    temp = r16  ; temporary register, preserved by interrupts
.def    addr = r17  ; SID address, used by write interrupt
.def    data = r18  ; SID data, used by write interrupt

.cseg

.include "interrupts.asm"

.org 0x38
RESET:
    clr     temp                        ; set up zero register
    mov     zero, temp    

    ldi     temp, high(RAMEND)          ; initialize stack
    out     SPH, temp
    ldi     temp, low(RAMEND)
    out     SPL, temp
    
    sei                                 ; enable interrupts
    
    out     ADDR_PORT, zero             ; init ports to zero
    out     DATA_PORT, zero
    out     CTRL_PORT, zero    

    ldi     temp, 0xFF                  ; set ports as outputs
    out     ADDR_DDR, temp
    out     DATA_DDR, temp
    out     CTRL_DDR, temp

    ldi     temp, TIMER1_SETUPA         ; set up SID clock timer
    out     TCCR1A, temp
    ldi     temp, TIMER1_SETUPB
    out     TCCR1B, temp                
    ldi     temp, SID_CYCLE_LENGTH - 1
    out     OCR1AH, zero
    out     OCR1AL, temp    
    ldi     temp, SID_CYCLE_LENGTH / 2 
    out     OCR1BH, zero
    out     OCR1BL, temp
       
    sbi     CTRL_PORT, RES              ; enable SID (reset to high)
    
main:

    ldi     addr, 0x18  ; volume
    ldi     data, 0x0F
    rcall   sidws
    
    ldi     addr, 0x01  ; frequency
    ldi     data, 0x20

    rcall   sidws    
    ldi     addr, 0x05  ; attack / decay
    ldi     data, 0xDA
    rcall   sidws  
    ldi     addr, 0x06  ; sustain / release
    ldi     data, 0x08
    rcall   sidws
        
    ldi     addr, 0x04  ; waveform / gate
    ldi     data, 0x81
    rcall   sidws 

loop:
    rjmp    loop

sidws:
    ; synchronous sid write
    ; enables TIM1_OVF to write to the SID
    ; and waits for it to finish
    ldi     temp, 1 << TOV1     ; TOV1 = TOIE1
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
	

	
