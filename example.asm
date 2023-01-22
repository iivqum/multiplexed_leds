 list p=pic10f202

 #include p10f202.inc

 __config _WDTE_OFF & _MCLRE_OFF & _CP_OFF

;this code multiplexes 16 leds using a 74hc595 shift register

CLK equ GP0
DAT equ GP1
OE equ GP2

;count variables
ca equ 0x08
cb equ 0x09
;value to put into shift register,upper 4 bits select column lower 4 select row
out equ 0x0b

led8_1 equ 0x0c;first 8 leds state clockwise order
led8_2 equ 0x0d;last 8 leds state clockwise order

mode equ 0x0e;current blink pattern

prescale equ 0x0f;2^n prescaler for timing, based on multiplexing interval of 20ms
prescale_c equ 0x10;old copy of the prescaler, so we can detect changes in prescale register
				   ;to update the state only on transitions

 org 0x000

;load option register
 movlw 0x00
 option
;setup io
 movwf GPIO
 bsf GPIO,OE;make sure were not outputting garbage from the 595
 TRIS GPIO
;output reg
 clrf out
;output leds
 clrf led8_1
 clrf led8_2
;prescaler
 clrf prescale
 clrf prescale_c
;mode
 movlw 0x01
 movwf mode

 goto mode1_init

delay_1ms
 movlw 0xfa
 movwf ca
 nop;padding to make it 4 inst cycles
 decfsz ca,F
 goto $-2
 retlw 0x00

delay_5ms
 movlw 0x05
 movwf cb
 call delay_1ms
 decfsz cb,F
 goto $-2
 retlw 0x00

clock
 bsf GPIO,CLK
 bcf GPIO,CLK
 retlw 0x00

update;copies out register to the shift register
 bsf GPIO,OE
 btfsc out,0x07
 bsf GPIO,DAT
 call clock
 bcf GPIO,DAT
 btfsc out,0x06
 bsf GPIO,DAT
 call clock
 bcf GPIO,DAT
 btfsc out,0x05
 bsf GPIO,DAT
 call clock
 bcf GPIO,DAT
 btfsc out,0x04
 bsf GPIO,DAT
 call clock
 bcf GPIO,DAT
 btfsc out,0x03
 bsf GPIO,DAT
 call clock
 bcf GPIO,DAT
 btfsc out,0x02
 bsf GPIO,DAT
 call clock
 bcf GPIO,DAT
 btfsc out,0x01
 bsf GPIO,DAT
 call clock
 bcf GPIO,DAT
 btfsc out,0x00
 bsf GPIO,DAT
 call clock
 bcf GPIO,DAT
 call clock;update storage register
 bcf GPIO,OE
 retlw 0x00

mode1_init
 movlw b'11111111'
 movwf led8_1
 movwf led8_2
 goto main_loop
mode2_init
 movlw b'01010101'
 movwf led8_1
 movwf led8_2
 goto main_loop
mode3_init
 movlw b'00011111'
 movwf led8_1
 movlw b'00011111'
 movwf led8_2
 goto main_loop
mode4_init;continue mode 3
 goto mode3_init
mode5_init
 movlw b'11111111'
 movwf led8_1
 movwf led8_2
 goto main_loop

mode1_flash
 comf led8_1,F
 comf led8_2,F
 goto main_loop
mode2_flash
 comf led8_1,F
 comf led8_2,F
 goto main_loop
mode3_flash
 rlf led8_1,F
 rlf led8_2,F
 goto main_loop
mode4_flash
 goto mode3_flash
mode5_flash
 comf led8_1,F
 comf led8_2,F
 goto main_loop

update_pattern
 btfsc mode,0x00
 goto mode1_flash
 btfsc mode,0x01
 goto mode2_flash
 btfsc mode,0x02
 goto mode3_flash
 btfsc mode,0x03
 goto mode4_flash
 btfsc mode,0x04
 goto mode5_flash

update_mode
 bcf STATUS,C;make sure no carry bit is present
 rlf mode,F
 btfsc mode,0x05
 goto done
 clrf prescale
 btfsc mode,0x00
 goto mode1_init
 btfsc mode,0x01
 goto mode2_init
 btfsc mode,0x02
 goto mode3_init
 btfsc mode,0x03
 goto mode4_init
 btfsc mode,0x04
 goto mode5_init

done
 bsf GPIO,OE
 movf GPIO,W
 sleep

main_loop
 ;first row, copy lower bits of led8_1 into out
 movf led8_1,W
 movwf out
 comf out,F
 swapf out,F
 movlw 0xf0
 andwf out,F;
 bsf out,0x00;enable row 0
 call update
 call delay_5ms

 ;second row, copy upper bits of led8_1 into out
 movf led8_1,W
 movwf out
 comf out,F
 movlw 0xf0
 andwf out,F;
 bsf out,0x01;enable row 1
 call update
 call delay_5ms

 ;third row, copy lower bits of led8_2 into out
 movf led8_2,W
 movwf out
 comf out,F
 swapf out,F
 movlw 0xf0
 andwf out,F;
 bsf out,0x02;enable row 2
 call update
 call delay_5ms 

 ;fourth row, copy upper bits of led8_2 into out
 movf led8_2,W
 movwf out
 comf out,F
 movlw 0xf0
 andwf out,F;
 bsf out,0x03;enable row 3
 call update
 call delay_5ms

 movfw prescale
 movwf prescale_c
 incf prescale,F
 movfw prescale
 xorwf prescale_c,F;bits will be 1 if they changed
 andwf prescale_c,F;bits will be 1 if they transitioned to 1
;update pattern every 0.16s (20ms * 8)
 btfsc prescale_c,0x02
 goto update_pattern
;update mode every 2.56s (20ms * 128)
 btfsc prescale_c,0x07
 goto update_mode

 goto main_loop

 end