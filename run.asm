
;rrrrrrrrrr		uuu		uuu		nnnnn    nnn	!!!
;rrr	rrr		uuu		uuu		nnnnnn   nnn	!!!
;rrr	rrr		uuu		uuu		nnn nnn  nnn	!!!
;rrrrrrrrrr		uuu		uuu		nnn	 nnn nnn	!!!
;rrrrrrrrr		uuu		uuu	 	nnn	  nn nnn	!!!
;rrr	rrr		uuu		uuu		nnn	   nnnnn	
;rrr	 rrr	uuuuuuuuuuu		nnn		nnnn	!!!
;rrr	  rrr	uuuuuuuuuuu		nnn		 nnn	!!!

; by: orel levi
; procedures at: proc.asm

IDEAL
MODEL small
STACK 100h
DATASEG

color db 0Eh
speed dw 2 ;changes with difficulty
rnd dW 0
Msg1 db '		GAME OVER			', 10, 13,'$'
Msg2 db '	  press any key to exit	',10,13,'$'
Msg3 db 'choose a difficulty',10,13,'$'
Msg4 db 'E= easy N=normal H=HARD S= FUCK YOU',10,13,'s'
Msg5 db 'please choose a difficulty',10,13,'$'
VicM db '		Victory!!			',10,13,'$'
SecPass db 18
GTime db 30 ; changes with difficulty
MoveTime db 25 ;is reduced over time
SecPass2 db 18; for movement
OmnicDir dw 6,4,2,0 ;currect direction		
Omnic_X DW 55,55,55,55  ;thier positions
Omnic_Y DW 40,80,120,160
OmnicMoveT Dw 3,2,2,1
cruser_X DW 090h
cruser_Y DW 090h
fps_waiter db 0 ; 1hunderdec pass 1 frame
update db 1
xor_memory dw 0

;;;;;;;;;;; for points

point_X dw 0
point_Y dw 0
score dw 0
update_count dw 0
point_exist	db 0
scoreMsg db '		your score:			','$'
P_sound_time db 0
point_sound db 1 	;No need to play point sound at the begining 

;;;;;-for the extra graphics!!

file_offset dw 0
open_screen db 'opening.bmp',0
background db 'ground.bmp',0
filehandle dw ?
Header db 54 dup (0)
Palette db 256*4 dup (0)
ScrLine db 320 dup (0)
ErrorMsg db 'Error', 13, 10,'$'
CODESEG

include "procs.asm"


start:
	mov ax, @data
	mov ds, ax

	mov ax, 13h ; enter Graphic mode
	int 10h
	;;;;;;;;;;;;;;;;;;;
	; loads my beautiful opening screen :D
	mov bx, offset open_screen
	mov [file_offset], bx
	; Process BMP file
    call OpenFile
    call ReadHeader
    call ReadPalette
    call CopyPal
    call CopyBitmap
	
	;;;;;;;;;;;;;;;;;;;
	mov ah,0h 			;wait for any key...
	int 16h
	
	call EscPressed		;was it Esc?
	
	;;;;;;;;;;;;;;;;;;;;;;;;
	; load background :D
	mov bx, offset background
	mov [file_offset], bx
	; Process BMP file
    call OpenFile
    call ReadHeader
    call ReadPalette
    call CopyPal
    call CopyBitmap
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;draw charecters on the screen 	
	call OmnicDrawn			; draw all omnics 
	
	mov [color],Pcolor
	add [xor_memory],4
	call RnGpointX		 	;Puts a random x value in point X
	sub [xor_memory],7
	call RnGpointY 			;Puts a random y value in point X
	call DrawPoint
	
	mov ax,0h
	int 33h 				;reset crusor
	call DrawTracer
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov  ah, 2ch 
	int  21h  
	mov [fps_waiter],dl ; GET TIME FOR FIRST RUN
	;omnics randomness for first run
	
	mov cx,4			;repeat 4 times
	
	first_random:
		
		push cx 		 			; to get si (now omnic pointer)value for word long
			mov si,8 
			shl cx,1
			sub si,cx
		pop cx
		
		 sub [xor_memory],99
		 call RnG 				;change omnic direction to random
		 mov bx,[rnd]
		 mov [OmnicDir+si],bx
		
		 add [xor_memory],342
		 call RnG 				;renew omnic moving time- 1 SEC,2 SEC,3 SEC (OR 0= MOVE UNTIL TOUCH BORDER. (but has the posibulity to change next comnic run)
		 shr [rnd],1			;to get time in range 0-3
		 mov bx,[rnd]
		 mov [OmnicMoveT+si],bx
		 
	loop first_random		;move to next omnic
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	play:
	
		call EscPressed		;if esc pressed exit game
		call UpdateGraphic 	;if 1\18 sec pass update = 0
		
		cmp [update], 0
		jne play
		
		
		; updates graphics per 1\18 sec 
		call GameTime		;if 30 sec pass victory
		call comnics 		;update direction and moving time for omnics 
		call DrawTracer		; draw tracer in mouse's currect posion 
		call DrawOmnic  	;draws omnics, if third sec pass move if not draw in place
		call CheckPass 		; if the user had lost 
		call PointTaken		; was the point drawn at start taken? if so score up! and draw a new one if 1 sec pass
		call PointSound		;if point taken play sound for third second
		
		inc [update_count]	;counting for point drawing
		inc [P_sound_time]	;counting for point sound
		
		mov [update],1		
		
		
	jmp play
	
END start