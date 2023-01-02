 list p=pic10f202

 #include p10f202.inc

 __config _WDTE_OFF & _MCLRE_OFF & _CP_OFF

;this code multiplexes 4 leds using a 74hc595 shift register

CLK equ GP0
DAT equ GP1
OE equ GP2

;variables
ca equ 0x08
cb equ 0x09
cc equ 0x0a
out equ 0x0b;value to put into shift register

 org 0x000

 movlw b'11000111';option register bits
 option

;setup io
 movlw 0x00
 movwf GPIO
 TRIS GPIO

 movlw 0x0d
 movwf out

 movlw 0x0d
 movwf cc

 goto main_loop

delay_1ms
ca equ 0x08
 movlw 0xfa
 movwf ca
delay_1ms_loop
 nop;padding to make it 4 inst cycles
 decfsz ca,F
 goto delay_1ms_loop 
 retlw 0x00

delay_5ms
 movlw 0x05
 movwf cb
delay_5ms_loop
 call delay_1ms
 decfsz cb,F
 goto delay_5ms_loop
 retlw 0x00

clock
 bsf GPIO,CLK
 bcf GPIO,CLK
 retlw 0x00

clear
 bcf GPIO,DAT
 call clock
 call clock
 call clock
 call clock
 call clock;update storage reg
 retlw 0x00

shift0
 bsf GPIO,DAT
 call clock
 bcf GPIO,DAT
 call clock;update storage reg
 retlw 0x00
shift1
 bsf GPIO,DAT
 call clock
 bcf GPIO,DAT
 call clock
 call clock;update storage reg
 retlw 0x00
shift2
 bsf GPIO,DAT
 call clock
 bcf GPIO,DAT
 call clock
 call clock
 call clock;update storage reg
 retlw 0x00
shift3
 bsf GPIO,DAT
 call clock
 bcf GPIO,DAT
 call clock
 call clock
 call clock
 call clock;update storage reg
 retlw 0x00

main_loop
 call clear

 call shift0
 btfsc out,0x03
 bcf GPIO,OE
 call delay_5ms
 call delay_5ms
 bsf GPIO,OE
 call clear
 
 call shift1
 btfsc out,0x02
 bcf GPIO,OE
 call delay_5ms
 call delay_5ms
 bsf GPIO,OE
 call clear

 call shift2
 btfsc out,0x01
 bcf GPIO,OE
 call delay_5ms
 call delay_5ms
 bsf GPIO,OE
 call clear

 call shift3
 btfsc out,0x00
 bcf GPIO,OE
 call delay_5ms
 call delay_5ms
 bsf GPIO,OE
 
 decfsz cc,F
 goto main_loop
 
 movlw 0x0d
 movwf cc

 incf out,F

 goto main_loop

 end