; $ -> Hexadecimal % -> Binary # -> Immediate 

E = %10000000
RW = %01000000
RS = %00100000

PORTA = $6001
PORTB = $6000
DDRB = $6002
DDRA = $6003

IFR = $600d
IER = $600e
PCR = $600c

    .org $8000

reset:
    ldx #$ff
    txs
    cli

    lda #%10010000 ; Setting Interrupt enable register to enable CB1
    sta IER

    lda #$00
    sta PCR

    lda #$ff ; Set all pins to output
    sta DDRB ; All B ports to output

    lda #%11111000 ; Set top 3 pins on Port A to output 
    sta DDRA

    lda #%00011000
    sta PORTA

    lda #%00111000 ; Function set -> 8 bit mode; 2 line display; 5x8 display
    jsr lcd_instruction
    lda #%00001111 ; Display on; Cursor on ; Curson blink on
    jsr lcd_instruction
    lda #%00000110 ; Increment cursor ; Display shift off
    jsr lcd_instruction

    lda #%00000001 ; Clear display
    jsr lcd_instruction

loop:
    lda #%00000010 ; Make cursor go back to home
    jsr lcd_instruction
    ldx #0

print_message1:
    lda message1, x
    beq loop
    jsr print_char
    inx
    jmp print_message1


message1: .asciiz "BOOP"
message2: .asciiz "INTERRUPT"
message3: .asciiz "LOW"

lcd_busy_check:
    pha ; Store register A onto stack
    lda #%00000000
    sta DDRB ; Set all B pins to input

lcd_busy:
    lda #RW
    sta PORTA

    lda #(RW | E)
    sta PORTA

    lda PORTB ; Store PORT B into A register
    and #%10000000
    bne lcd_busy

    lda #RW
    sta PORTA

    lda #%11111111
    sta DDRB ; Set PORT B directions to output
    pla ; Place stack value back onto stack
    rts

lcd_instruction:
    jsr lcd_busy_check
    sta PORTB
    lda #0
    sta PORTA
    lda #E ; Send instruction
    sta PORTA
    lda #0
    sta PORTA
    rts

print_char:
    jsr lcd_busy_check
    sta PORTB
    lda #RS
    sta PORTA
    lda #(RS | E)
    sta PORTA
    lda #RS
    sta PORTA
    rts

nmi:
    rti
irq:
    pha
    txa
    pha

    lda #%11111000
    sta DDRA

    lda PORTA
    ldx PORTA
    ldy PORTA

    and #%00000001
    beq address_0_irq

    txa
    and #%00000010
    beq address_1_irq

    tya
    and #%00000100
    beq address_2_irq

    jmp exit_irq

address_0_irq:
    lda #%00010000
    sta PORTA
    jmp exit_irq

address_1_irq:
    lda #%00001000
    sta PORTA
    jmp exit_irq

address_2_irq:
    lda #%00011000
    sta PORTA
    
exit_irq:
    pla
    tax
    pla
    bit PORTB
    rti ; Return from interrupt

    .org $fffa
    .word nmi
    .word reset
    .word irq