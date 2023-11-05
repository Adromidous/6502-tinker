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


LCD_RAM = $3000                                                         ; LCD RAM ranges from $3000 - $301f for two line display
CURSOR_POS = $3020                                                      ; Address to store position of cursor

WAIT_COUNTER = $10
WAIT = $2023

    .org $8000

main:
    ; ------------------------------------------------------------------
    ;                           MAIN PROGRAM

    ldx #$ff ; Load 0xff into X register
    txs ; Store into stack

    jsr via_initialization ; Initialize VIA for I/O and clear display

    jsr print_message
    
    lda #$ff ; Delay length
    ldx #$18

.delay:
    jsr sleep
    dex
    bne .delay

    jsr MENU_GENERATE ; Render all options to run 6502 and check memory
    jmp main


MENU_GENERATE:
    lda #0
    sta CURSOR_POS


.start:
    ldx #0
    ldy #0


.loop:
    lda message, Y
    sta LCD_RAM, X

    inx
    iny
    cpx #$20                                                            ; Since each text in message is 16 characters, we only want to print two lines -> Loop through 32 times
    bne .loop


.lcd_cursor:
    lda #">"
    ldy CURSOR_POS
    jmp .change_cursor                                                  ; If CURSOR_POS == 0 -> Set cursor on first line, else set on second line
.cursor_setup
    sta LCD_RAM,X                                                       ; Store in first or second line depending on CURSOR_POS
    jmp .render                                                         ; Render onto LCD


.render:
    jsr lcd_render                                                      ; Render LCD_RAM data onto LCD


.input_wait:
    ldx #$04
.user_input:
    lda #$ff                                                            ; Start wait counter
    jsr sleep
    dex
    bne .user_input                                                     

    lda #0
    jsr read_VIA                                                        ; Read data coming from VIA -> PORT A
    beq .input_wait                                                     ; Used AND operator in read_VIA -> If no buttons pressed, go back to .user_input


.handle_VIA_input:
    cmp #$01                                                            ; Move up button was pressed
    beq .move_up

    cmp #$02                                                            ; Move down button was pressed
    beq .move_down

    ;cmp #$04                                                            ; Back button was pressed
    ;beq .back_screen

    ;cmp #$08                                                            ; Enter button was pressed
    ;beq .enter
    ;lda #0                                                              ; Reset A register
    ;jmp .input_wait


.move_up:
    lda CURSOR_POS                                                      ; Store A register with data at CURSOR_POS
    beq .return                                                         ; Return to user input if cursor is already at the top position
    lda #0                                                              ; Set cursor position to top
    sta CURSOR_POS                                                      ; Store that in CURSOR_POS
    jmp .start                                                          ; Go back to start


.move_down:
    lda CURSOR_POS                                                      ; Store A register with data at CURSOR_POS
    bne .return                                                         ; Return to user input if cursor is already at the bottom position
    lda #1                                                              ; Set cursor position to bottom
    sta CURSOR_POS                                 
    jmp .start

.return
    jmp .input_wait

.change_cursor:
    beq .set_cursor_first_line                                          ; Check if the CURSOR_POS has the value #0 stored
    ldx #$10                                                            ; Load #16 into X register for second line
    jmp .cursor_setup                                                   ; Go back to cursor_setup
.set_cursor_first_line:                                                 ; Setup first line cursor
    ldx #0                                                              ; Set #0 offset in X register
    jmp .cursor_setup                                                   ; Jump back to cursor setup

    ; ------------------------------------------------------------------

    ; ------------------------------------------------------------------
    ;               VIA PORT AND LCD DISPLAY INITIALIZATION

via_initialization:
    lda #%11111000                                                      ; Set bottom 3 pins to input, rest to output
    sta DDRA                                                            ; Load into Data Direction Register A

    lda #%00011000                                                      ; BOOTUP HAS STARTED
    sta PORTA

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
    lda #%1000000                                                       ; Force cursor at first line
    jsr lcd_instruction                                                 ; Send instruction to LCD

    ldx #0

.char_render:
    lda LCD_RAM, X                                                      ; Start printing from the first position
    cpx #$10                                                            ; Check if the first 16 characters (First message) has been printed to LCD
    beq .set_second_line                                                ; If 16 characters have been printed to LCD
    cpx #$20                                                            ; If 32 characters have been printed to LCD
    beq .exit_render
    jsr lcd_instruction                                                 ; Send instruction to LCD
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

message:
    .text " SCAN ROM       "
    .text " RUN            "

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