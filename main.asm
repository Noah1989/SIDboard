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
                      
.equ    CPU_CLOCK = 14745600            

.equ    BUFSIZE = 250   ; be careful to leave enough space for the stack!
                        
.def    zero = r0   ; always zero

.def    stashA = r1 ; used by interrupts to stash data
.def    stashB = r2 ;
.def    stashC = r3 ;

.def    temp = r16  ; temporary register, preserved by interrupts,
                    ; used as argument and/or return value for subroutines
                    
.def    tmpi = r20  ; temporary register, not preserved by interrupts
.def    backup = r21 ; backup register for original buffer write position
                    
.def    addr = r17  ; SID address, nothing else
.def    data = r18  ; SID data, nothing else

.def    command = r19   ; currently processed command
.def    datlenH = r25   ; length of received data
.def    datlenL = r24   ; preserved by interrupts

.cseg

.include "interrupts.asm"
.include "usart.asm"
.include "sid.asm"
.include "commands.asm"

RESET:
    clr     temp                ; set up zero register
    mov     zero, temp    
    
    out     ADDR_PORT, zero     ; init ports to zero
    out     DATA_PORT, zero
    out     CTRL_PORT, zero    

    ldi     temp, 0xFF          ; set ports as outputs
    out     ADDR_DDR, temp
    out     DATA_DDR, temp

    ldi     temp, (1 << RES) | (1 << RWC)
    out     CTRL_DDR, temp
       
    ldi     temp, high(RAMEND)  ; initialize stack
    out     SPH, temp
    ldi     temp, low(RAMEND)
    out     SPL, temp    

    clr     XL                  ; clear buffer write pointer
    clr     YL                  ; clear buffer read pointer

    rcall   usart_init          ; initialize USART
    rcall   sid_init            ; initialize SID
    
    sei
    
    rjmp    command_loop        ; start processing commands
