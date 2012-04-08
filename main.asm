.nolist
.include "m162def.inc"

.list

.equ    ADDR_PORT = PORTA
.equ    ADDR_DDR = DDRA

.equ    DATA_PORT = PORTB
.equ    DATA_DDR = DDRB

.equ    CTRL_PORT = PORTC
.equ    CTRL_DDR = PORTC
.equ    CLK = PC4   ; SID clock, generated using OC3B (Timer 3 output)
.equ    RES = PB1   ; reset
.equ    RWC = PB0   ; read/write control

        ; Timer 3 setup (written to TCCRA:TCCRB): 
        ; fast PWM, TOP = OCR3A
        ; set OC3B pin on Compare Match, clear at TOP,
        ; internal clock, no prescaling
.equ    TIMER3_SETUP = 0x10 << COM3B0 | 0x10 << COM3B1 | \
                       0x10 << WGM30 | 0x10 << WGM31 | \
                       0x01 << WGM32 | 0x01 << WGM33 | \
                       0x01 << CS30
                       
        ; generated clock: 14.7456 MHz / 15 = 0.983 MHz
        ; original C64 clock frequency (PAL): 0.985 MHz
.equ    SID_CYCLE_LENGTH = 15 
                        
.def    zero = r0    ; always zero
.def    temp = r16   ; temporary register, preserved by interrupts

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
    
    out     ADDR_PORT, zero             ; init ports to zero
    out     DATA_PORT, zero
    out     CTRL_PORT, zero
    
    ldi     temp, 0xFF                  ; set ports as outputs
    out     ADDR_DDR, temp
    out     DATA_DDR, temp
    out     CTRL_DDR, temp
    
    ldi     temp, high(TIMER3_SETUP)    ; set up SID clock timer
    sts     TCCR3A, temp
    ldi     temp, low(TIMER3_SETUP)
    sts     TCCR3B, temp                
    ldi     temp, SID_CYCLE_LENGTH - 1
    sts     OCR3AH, zero
    sts     OCR3AL, temp    
    ldi     temp, SID_CYCLE_LENGTH / 2
    sts     OCR3BH, zero
    sts     OCR3BL, temp
        
    sbi     CTRL_PORT, RES              ; enable SID (reset to high)
    

