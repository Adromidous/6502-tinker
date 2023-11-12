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


LCD_RAM = $3fde                                                         ; LCD RAM ranges from $3000 - $301f for two line display
CURSOR_POS = $3fdd                                                      ; Address to store position of cursor

A0 = $00                                                                ; Common use registers
A1 = $01
A2 = $02
A3 = $03

WAIT_COUNTER = $18
WAIT = $3fdb
PROGRAM_START = $0020

    .org $8000

main:
    ; ------------------------------------------------------------------
    ;                           MAIN PROGRAM

    ldx #$ff ; Load 0xff into X register
    txs ; Store into stack

    jsr via_initialization ; Initialize VIA for I/O and clear display

    jsr print_message
    
    lda #$ff ; Delay length
    ldx #$20

main_2:
.delay:
    jsr sleep
    dex
    bne .delay

    ;jmp .menu_generate ; Render all options to run 6502 and check memory
    ;jmp main


.menu_generate:

    lda #0
    sta CURSOR_POS

.start:
    ldx #0
    ldy #0
    lda #%00000001                                                      ; Clear display
    jsr lcd_instruction


.loop:
    lda message, y
    sta LCD_RAM, x
    inx
    iny
    cpx #$20                                                            ; Since each text in message is 16 characters, we only want to print two lines -> Loop through 32 times
    bne .loop


.lcd_cursor:
    lda #">"
    ldy CURSOR_POS
    bne .lower_cursor                                                   ; If CURSOR_POS == 0 -> Set cursor on first line, else set on second line
    sta LCD_RAM
    jmp .render


.lower_cursor
    sta LCD_RAM+$11                                                     ; Store in first or second line depending on CURSOR_POS


.render:

    jsr lcd_render                                                      ; Render LCD_RAM data onto LCD


.input_wait:
    ldx #$04
.user_input:
    lda #$ff                                                           ; Start wait counter
    jsr sleep
    dex
    bne .user_input                                                     

    lda #0
    jsr read_VIA                                                        ; Read data coming from VIA -> PORT A
    beq .input_wait                                                     ; Used AND operator in read_VIA -> If no buttons pressed, go back to .input_wait


.handle_VIA_input:
    cmp #$01                                                            ; Move up button was pressed
    beq .move_up

    cmp #$02                                                            ; Move down button was pressed
    beq .move_down

    cmp #$04                                                           ; Back button was pressed
    beq .enter

    ;cmp #$08                                                           ; Enter button was pressed
    ;beq .back_screen
    ;lda #0                                                              ; Reset A register
    jmp .input_wait


.move_up:
    lda CURSOR_POS                                                      ; Store A register with data at CURSOR_POS
    beq .return                                                         ; Return to user input if cursor is already at the top position
    lda #0                                                              ; Set cursor position to top
    sta CURSOR_POS                                                      ; Store that in CURSOR_POS
    jmp .start                                                          ; Go back to start


.move_down:
    lda CURSOR_POS                                                      ; Store A register with data at CURSOR_POS
    bne .return                                                         ; Return to user input if cursor is already at the bottom position
    lda #%1                                                             ; Set cursor position to bottom
    sta CURSOR_POS                                 
    jmp .start


.enter:
    lda CURSOR_POS                                                       
    bne program                                                         ; Cursor at second position -> Jump to main program
    lda #<PROGRAM_START                                                 ; Load LSB into A register
    ldy #<PROGRAM_START                                                 ; Load MSB into Y register
    jmp scan_ROM                                                        ; Jump to SCAN ROM program


.return
    jmp .input_wait

    ; ------------------------------------------------------------------

    ; ------------------------------------------------------------------
    ;                           ROM PROGRAM

program:
    lda #%00000001                                                      ; Clear display
    jsr lcd_instruction
    ldx #0
.print_program_message1:
    lda program_message1, x
    beq print_program_message2
    jsr print_char
    inx
    jmp .print_program_message1

print_program_message2:
    lda #%11000000                                                      ; Setup 2nd line display
    jsr lcd_instruction
    ldx #0
.print_title_routine
    lda program_message2, x
    beq stop
    jsr print_char
    inx
    jmp .print_title_routine



    ; ------------------------------------------------------------------

stop:
    jmp stop

    ; ------------------------------------------------------------------
    ;                             SCAN ROM

scan_ROM:
    sta A0                                                              ; Store LSB into A0
    sty A1                                                              ; Store MSB into A1 -> To use later on
    
    lda #%00000001                                                      ; Clear display
    jsr lcd_instruction

    lda #$00                                                            
    sta A3                                                              ; A3 used later on to determine if we write in upper or lower half of LCD module
    jsr .rom_contents

    clc                                                                 ; Clear carry bit
    lda A0                                                              
    adc #$04
    sta A0
    bcc .skip
    inc A1

.skip:
    lda #$01                                                            ; Going to load lower row of LCD
    sta A3
    jsr .rom_contents

    jsr lcd_render                                                      ; Render onto LCD

.input_wait:
    ldx #$04
.user_input:
    lda #$ff
    jsr sleep
    dex
    bne .user_input

    lda #0
    jsr read_VIA
    beq .input_wait

.handle_VIA_input:
    cmp #$01                                                            ; Move up button was pressed
    beq .move_up

    cmp #$02                                                            ; Move down button was pressed
    beq .move_down              

    cmp #$08                                                            ; Back button pressed
    beq .back

.back:
    jmp main_2

.move_up:
    sec
    lda A0
    sbc #$08
    sta A0
    lda A1
    sbc #$00
    sta A1
    jmp scan_ROM

.move_down:
    sec
    lda A0
    adc #$00
    sta A0
    lda A1
    adc #$04
    sta A1
    jmp scan_ROM


.rom_contents:
    ldy #3                                                              ; Iterate through 4 times to get the contents of the 4 bytes in ROM

.seek_rom:
    lda (A0),y
    pha                                                                 ; Push A0 - A3 onto stack for now
    dey
    bne .seek_rom                                                       ; If loop not complete, go back to .seek_rom
    lda (A0), y                                                         ; Get the last byte since loop doesn't catch the last byte
    pha

    lda A0
    pha
    lda A1
    pha
    ldy #0

.seek_stack:
    cpy #6                                                              ; Going to display 6 bytes in each row
    beq .end                                                            ; Exit subroutine
    sty A2                                                              ; Save Y register for later since we're going to enter subroutine
    pla                                                                 ; Going to push A back onto stack in .bin_to_hex subroutine but just doing this to get value into A register
    jsr .bin_to_hex                                                     ; Convert binary to hex to display onto LCD module
    ldy A2                                                              ; Restore Y
    pha                                                                 ; Transfer LSN onto stack
    txa
    pha                                                                 ; Transfer MSN onto stack

    tya
    adc ROM_MAP, y                                                      ; For displaying on LCD
    tax                                                                 ; Transfer ROM_MAP to X register for later use
    pla                                                                 ; Pulling MSN
    jsr .store_nibble                                                   ; Store MSN
    inx                                                                 ; Increment ROM_MAP
    pla
    jsr .store_nibble                                                   ; Now storing LSN

    iny                                                                 ; To go back to loop
    jmp .seek_stack

.store_nibble:
    pha                                                                 ; Push MSN back onto stack
    lda A3                                                              ; A3 determines if we're storing in upper line of LCD or lower line of LCD
    beq .store_upper_line                                              
    pla                                                                 ; Pull MSN from stack
    sta LCD_RAM+$10, x                                                  ; This is for storing in lower line -> X register holds the offset from ROM_MAP that we calculated earlier
    jmp .exit_store

.store_upper_line
    pla                                                                 ; Pull MSN from stack
    sta LCD_RAM,x                                                       ; Store in upper line with X register offset calculated from before


.exit_store:
    rts

.end:
    lda #":"
    sta LCD_RAM+$4
    sta LCD_RAM+$15                                                     ; Place colon 16 sections apart
    rts


.bin_to_hex:
    ldy #$ff
    pha                                                                 ; Register A is pushed onto stack but value is still in stack which can be used
    lsr
    lsr
    lsr
    lsr
    jsr .to_hex                                                         ; Convert to HEX
    pla

.to_hex:
    and #%00001111                                                      ; Only want Least Significant Nibble
    ora #"0"                                                            ; Add ascii character for offset
    cmp #"9" + 1                                                        ; Check if decimal
    bcc .output                                                         ; Go to output if digit is a decimal since no carry bit
    adc #6                                                              ; Else add six character offset to get letters A to F

.output:
    iny                                                                 ; If Y == 0 at this line, we have converted MSB. If Y==1 at this line, we have converted LSB
    bne .return
    tax                                                                 ; X holds MSN, A holds LSN

.return:
    rts

    ; ------------------------------------------------------------------

    ; ------------------------------------------------------------------
    ;               VIA PORT AND LCD DISPLAY INITIALIZATION

via_initialization:
    lda #%11110000                                                      ; Set bottom 4 pins to input, rest to output
    sta DDRA                                                            ; Load into Data Direction Register A

    ;lda #%00001000                                                      ; BOOTUP HAS STARTED
    ;sta PORTA

    lda #$ff                                                            ; Set all pins to output
    sta DDRB                                                            ; Load into Data Direction Register B

    lda #%00111000                                                      ; Function set -> 8 bit mode; 2 line display; 5x8 display
    jsr lcd_instruction
    lda #%00001110                                                      ; Display on; Cursor on ; Curson blink off
    jsr lcd_instruction
    lda #%00000110                                                      ; Increment cursor ; Display shift off
    jsr lcd_instruction

    lda #%00000001                                                      ; Clear display
    jsr lcd_instruction

    rts

    ; ------------------------------------------------------------------

    ; ------------------------------------------------------------------
    ;                        PRINT STARTUP MESSAGE

print_message:
    ldx #0
.print_welcome_routine:
    lda welcome_message, x
    beq print_6502_title
    jsr print_char
    inx
    jmp .print_welcome_routine

print_6502_title:
    lda #%11000000                                                      ; Setup 2nd line display
    jsr lcd_instruction
    ldx #0
.print_title_routine
    lda bootloader_title, x
    beq .return
    jsr print_char
    inx
    jmp .print_title_routine

.return:
    rts


    ; ------------------------------------------------------------------

    ; ------------------------------------------------------------------
    ;                           LCD BUSY CHECKER

lcd_busy_check:
    pha                                                                 ; Store register A onto stack
    lda #%00000000
    sta DDRB                                                            ; Set all B pins to input

lcd_busy:
    lda #RW
    sta PORTA

    lda #(RW | E)
    sta PORTA

    lda PORTB                                                           ; Store PORT B into A register
    and #%10000000
    bne lcd_busy

    lda #RW
    sta PORTA

    lda #%11111111
    sta DDRB                                                            ; Set PORT B directions to output
    pla                                                                 ; Place stack value back onto stack
    rts

    ; ------------------------------------------------------------------

    ; ------------------------------------------------------------------
    ;                        SEND LCD INSTRUCTION

lcd_instruction:
    jsr lcd_busy_check
    sta PORTB
    
    lda #0
    sta PORTA
    lda #E                                                              ; Send instruction
    sta PORTA
    lda #0
    sta PORTA
    rts

    ; ------------------------------------------------------------------

    ; ------------------------------------------------------------------
    ;                       RENDER MESSAGE ONTO LCD

lcd_render:
    pha 
    txa
    pha
    tya
    pha

    ldx #0

.char_render:
    lda LCD_RAM,x                                                       ; Start printing from the first position
    cpx #$10                                                            ; Check if the first 16 characters (First message) has been printed to LCD
    beq .set_second_line                                                ; If 16 characters have been printed to LCD
    cpx #$20                                                            ; If 32 characters have been printed to LCD
    beq .exit_render
    jsr print_char                                                      ; Send instruction to LCD
    inx                                                                 ; Increment to go to next address in LCD_RAM
    jmp .char_render                                                    ; Back to beginning
    

.set_second_line
    pha                                                                 ; Don't want to lost data in A register -> Important when jumping back to .char_render
    lda #%11000000                                                      ; Force cursor at second line
    jsr lcd_instruction                                                 ; Send instruction to LCD
    pla                                                                 ; Pull stack data onto A register
    inx                                                                 ; Increment X to go to next address in LCD_RAM
    jmp .char_render

.exit_render:
    pla
    tay
    pla
    tax
    pla
    rts



    ; ------------------------------------------------------------------

    ; ------------------------------------------------------------------
    ;                           READ VIA INPUT

read_VIA:
    lda PORTA                                                           ; Load PORTA button presses into A register
    and #$0f                                                            ; Only want to read bottom 4 bits of PORTA
    rts

    ; ------------------------------------------------------------------

    ; ------------------------------------------------------------------
    ;                         PRINT CHARACTER

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

    ; ------------------------------------------------------------------

    ; ------------------------------------------------------------------
    ;                            MESSAGES


welcome_message: .asciiz "    WELCOME!    "
bootloader_title: .asciiz " TK-TINKER 6502 "

program_message1: .asciiz "  HELLO WORLD!  "
program_message2: .asciiz "(-(-_(-_-)_-)-) "

ROM_MAP:
    .byte $00, $01, $03, $05, $07, $09                                  ; For LCD to know where to place certain bytes for ROM seek function

message:
    .text " SCAN ROM       "
    .text "  RUN           "

    ; ------------------------------------------------------------------

    ; ------------------------------------------------------------------
    ;                            DEBUG FUNCTION

debug:
    pha
    lda #%00010000
    sta PORTA
    lda #0
    sta PORTA
    pla

    rts
    ; ------------------------------------------------------------------


    ; ------------------------------------------------------------------
    ;                            SLEEP FUNCTION

sleep:
    ldy #WAIT_COUNTER
    sty WAIT                                                            ; Store WAIT variable with inital value each time sleep is called

.outerloop:
    tay                                                                 ; Y register now holds initial value of #$ff
.innerloop:
    dey
    bne .innerloop
    dec WAIT                                                            ; Decrement WAIT value until #0
    bne .outerloop                                                      ; Reset Y register to #$ff
    rts


    ; ------------------------------------------------------------------

nmi:
irq:

    .org $fffa
    .word nmi
    .word main
    .word irq