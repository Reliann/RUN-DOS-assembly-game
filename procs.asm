CODESEG
Csize equ  01bh			;this is a constant, the charecter's size all charecters are a squares
x equ [word ptr bp+4] 	
y equ [word ptr bp+6]  
border_w equ 8			;the size of the left,right,and down border
border_top equ 26		;the size of the top border
pointC equ 5			;the size of the point (point is a square)
TrColor equ 120			;the color of the user's tracer
BackColor equ 0 		;backround color 
OmnColor equ 5			;omnics color 
Pcolor equ 22			;point color
; this procedure will draw charecter the size of Csize x Csize
; push the y first then the x of the wanted charecter
; in [color] put the wanted color 
PROC Charecter 
	
	push bp
	mov bp, sp

	push ax				;save all of the used registers
	push bx 
	push cx 
	push dx
	
	mov cx,Csize		;repeat on lines Csize times 
	DrawPixleColumn:
		push cx			;so we can restore the repeat times of the lines 
		mov cx,Csize	;repeat on columns Csize times
		
		DrawPixelLine: 
			mov bh,0h
			push cx		; so we can restore cx, after drawing pixel. we need to keep this value for the loop
			mov cx,x ;SET X
			mov dx,y ;SET Y
			mov al,[color] ;SET COLOR
			mov ah,0ch
			int 10h ;draw the wanted pixel
			pop cx		;restore repeat times after using the interupt 
			inc x		;to get next pixle next loop run
		loop DrawPixelLine
		inc y			; to start a new line of pixels
		sub x,Csize 	;X NOW POINTS ON CHARACTER START
		pop cx			;restore the repeat times of the lines 
	loop DrawPixleColumn
	
	sub y,Csize 		; Y NOW POINTS ON CHARACTER START
	
	pop dx				;get back all of the used registers
	pop cx
	pop bx
	pop ax
	pop bp

ret 4
ENDP Charecter


; ClearScreen Clears the screen from all graphics
PROC ClearScreen

	push ax 	; save the only used register
	
	
	 mov al,13 	; loads graphic mode
	 mov ah,0
	 int 10h
	
	
	
	pop ax		; restore the only used register 
ret
ENDP ClearScreen

;EscPressed see if player pressed ESC, if Esc pressed it's game over 
PROC EscPressed
	 push ax 	;save the only used register
	
	
	 in al, 64h 	; Read keyboard status port
	 cmp al, 10b 	; Data in buffer ?
	 je continueG	; Wait until data available
	 in al, 60h 		; Get keyboard data
	 cmp al, 1h 		; Is it the ESC key ?
	 jne continueG
	 
	 ;game over does not return back to the code, (it exits it therfore there is no need to ret or pop )
	call GameOver 	;display game over sound and screen 

	 continueG:		;ESC was not pressed so the game continues
		pop ax		;restore the only used register 
		ret 
		
ENDP EscPressed
;draws the user's tracer in this frame's mouse location.
PROC DrawTracer 
	push ax		;save those used registers
	push cx
	push dx
	
	push [cruser_Y]		;drawing procedure gets x and y from the stack
	push [cruser_X]		
	mov [color],BackColor 		; backround color
	call Charecter 				; "delete" the tracer in last frame by coloring in black (backround color)
	
	mov ax,3h		;get cruser location x==>cx y===>dx 
	int 33h
	shr cx,1		;dvide to fit screen
	
		mov [cruser_X],cx	;player is in this location 
		mov [cruser_Y],dx
		
		cmp [cruser_X],320-Csize-border_w	;check right border 
		jnge check_down						;no problem check next border
		mov [cruser_X],320-Csize-border_w	;problem, dont let it be drawn on the right border 
	
	check_down:
		cmp [cruser_Y],200-Csize-border_w	;check down border 
		jnge check_up						;no problem check next border
		mov [cruser_Y],200-Csize-border_w	;problem, don't let it be drawn on the down border
	
	check_up:
		cmp [cruser_Y],border_top			;check top border 
		jnle check_left						;no problem check next border 
		mov [cruser_Y],border_top			;problem, don't let it be drawn on the top border
	
	check_left:
		cmp [cruser_X],border_w				;check left border 
		jnle draws_tracer					;no problem, draw the playe's tracer
		mov [cruser_X],border_w				;problem, don't let it be drawn on the left border 
	
	draws_tracer :							;draw the playe's tracer
		push [cruser_Y]		;procedure gets x and y values from stack
		push [cruser_X]
		mov [color],TrColor ;tracer's color
		call Charecter
	
	 DoNothing: 
		pop dx	;restore used regisers
		pop cx 		 
		pop ax
		ret
ENDP DrawTracer

; check if GTime (game time) is 0, if it is then calls victory
; see if 5 second pass and the speed of the omnics should be increased to make the game abit harder with time.
; runs once per frame of the main therefor: every 1/18 second
Proc GameTime 
 push ax		; save the only used register

		
		
		dec [SecPass] 			; dec from the 18 fps counter 
		cmp [SecPass], 0		; see if 18 fps pass and time needs to be decreased 
		jne BackToPlay			; 1 second did not pass, go back to the frame's loop
		mov [SecPass],18 		; if 1 second pass reset secpass to 18
		dec [GTime] 			; sec pass, dec game time
		;need to print time on screen here
		cmp [GTime],0			; see if Gtime = 0 and it's a victory for the player 
		JE Victory				
		mov AL,[Gtime]			; it's not a victory but check if it's time to inrease omnic speed 
		cmp AL,[MoveTime]		; if 5 sec pass (from gtime) inc speed
		jg BackToPlay			; game time is greater then the time to change speed- go back to frame's loop
		SUB [MoveTime],5		; if we inc speed, we remove from the time to change speed another 5 seconds 
		inc [speed]
		
		
BackToPlay:	

	pop ax		; restore the only used register
 
ret 
Endp GameTime

;victory - dislpay score, and victory msg, play vicrory sound and leave on next key pressed 
PROC Victory

	
	in al, 61h 		;activate speaker
	or al, 00000011b
	out 61h, al
	
	mov al, 0B6h 	;get acsess
	out 43h, al
	
	;to play frequency
	mov al, 81
	out 42h, al 	; Sending lower byte
	mov al, 26
	out 42h, al 	; Sending upper byte
	
	;play the sound for one second
	mov [update],18		;use the update valueble because it wont be using it to check frames anymore (saving an extra byte here :P)
	mov ah,2ch			;get time
	int 21h
	now_wait:
	
		mov [fps_waiter],dl ; use fps_waiter beacuse it won't be using it anymore (saving another extra byte xD)
		
		mov ah,2ch			;get time
		int 21h
		
		cmp [fps_waiter],dl 
		je now_wait			;one 1/18 second pass?
		
		dec [update]		
		cmp [update],0		;one sec pass?
		jne now_wait		;if not keep waiting for it to pass
	
	;one second pass:
	in al, 61h ;deactivate speaker
	and al, 11111100b
	out 61h, al
	
	call ClearScreen	;so we can print the victory masseges 
	
	; disply a messege for victory 
	mov dx, offset VicM ;"victory"
	mov ah,09h
	int 21h
	
	mov dx, offset Msg2 ;"press any key.."
	;mov ah,09h
	int 21h
	
	mov dx, offset scoreMsg ;"your score:"
	;mov ah,09h
	int 21h
	
	
	call PrintScore ;print score
	
	mov ah,0h ;wait for any key...
	int 16h
	
	;exit game
	mov ah, 0 ; Return to text mode
	mov al, 2
	int 10h
	
	mov ax, 4c00h ;exit
	int 21h


	;sadly this procedure does not return (ret), it exits the game :D
ENDP  Victory

;prints the currect score on the screen 
proc PrintScore
	push ax
	push dx

	 cmp [score], 10d ;Check if the number of points is equal or bigger than 10
	jb print_ondig
  ; if score >= 10
      mov ax, [score]
	  mov dl,10
    div dl
  
       push ax ;store ax before interupt
    add al, 48; print tens
    mov dl, al
    mov ah, 2
    int 21h
	
    pop ax;restore ax
    add ah, 48
    mov dl, ah; print digits
    mov ah, 2
    int 21h
	jmp skip_print
	
	print_ondig:
	 mov dl,[byte ptr score]	;move score to dl for interupt 
	 add dl,48		;get ascii
	 mov ah, 02h
	 int 21h
	
	skip_print:
	
	pop dx
	pop ax
ret
endp PrintScore



; when the game is over either from a loss or exit (ESC pressed)
; play game over sound and display score and game over messeges
PROC GameOver 

	; "game over" sound
	in al, 61h ;activate speaker
	or al, 00000011b
	out 61h, al
	
	mov al, 0B6h ;get acsess
	out 43h, al
	
	mov al, 98h
	out 42h, al ; Sending lower byte
	mov al, 0Ah
	out 42h, al ; Sending upper byte

	; wait a second
	mov [update],18		;use the update valueble because it wont be using it to check frames anymore (saving an extra byte here :P)
	mov ah,2ch			;get the time
	int 21h	
	now_wait_Gover:
	
		mov [fps_waiter],dl ;use fps_waiter beacuse it won't be using it anymore in the frame's loop (game over exits game so saving another extra byte)
		
		mov ah,2ch			; get the time
		int 21h
		
		cmp [fps_waiter],dl 	;one 1/18 second pass?
		je now_wait_Gover		;no= wait 
		
		dec [update]			
		cmp [update],0			;second pass?
		jne now_wait_Gover		;if not= wait
	
	;one second pass
	in al, 61h ;deactivate speaker
	and al, 11111100b
	out 61h, al
	
	call ClearScreen ; clears the screen
	; disply messeges for game over 
	mov dx, offset Msg1		;"GAMEOVER"
	mov ah,09h
	int 21h
	
	;Disply messege for "press any key.."
	mov dx, offset Msg2
	;mov ah,09h
	int 21h
	
	mov dx, offset scoreMsg ;"your score:"
	;mov ah,09h
	int 21h
	
	call PrintScore
	
	mov ah,0h ;wait for any key...
	int 16h
	
	;exit game
	mov ah, 0 ; Return to text mode
	mov al, 2
	int 10h
	
	mov ax, 4c00h ;exit
	int 21h

;sadly this procedure does not return (ret), it exits the game :D
ENDP GameOver

;UpdateGraphic  checks if 1/18 second have passed and its time to set update to 0 for a new frame
proc UpdateGraphic 

 push ax
 push cx
 push dx

		mov  ah, 2ch 	;get time
		int  21h
		cmp [fps_waiter],dl		; one 1/18 sec passed?
		je DoneChecking			; had not changed, go back to game's loop
		mov [update],0			; changed, 1 frame passed, update=0
		
DoneChecking:	
	 mov [fps_waiter],dl ; SAVE LAST HUNDRETH SEC VALUE in fps_waiter for next procedure run
	 pop dx 
	 pop cx
	 pop ax

ret
endp UpdateGraphic

; generates a persudo random number in range 0-6 (include) ;change xor_memory before calling for maximume officancy (add/sub)
;to genrate omnic time use shr [rnd],1 after calling, for direction keep rnd the same
proc RnG 
	
	push ax 	; save used registers
	push bx 
	push cx
	push dx
	
	mov ah, 2Ch	;get time
	int 21h
	mov al, dl

	mov bx, [cs:xor_memory]	
	xor ax, [bx]	;xor with something from cs
	and ax, 6d		; AX CAN BE ONLY: 0,2,4,6
	mov [rnd], ax	; mov the "random" number to rnd

	pop dx		;restore used regisers
	pop cx
	pop bx
	pop ax
ret
endp RnG

;this procedure is responsible for random movement for the omnics "the enemies"
;basically puts random directions in the omnics's direction array, and random times in movement time array
;when movement time reaches zero the onic changes its direction to a random diraction
proc Comnics
push bx 	; save used registers
push cx
push dx
push si

	
	dec [SecPass2] 		; 1/18 seconds pass (procedure is called every frame)
	cmp [SecPass2], 0	; have 1 second pass?
	jne OutOfIt			;if not there is nothing to change.
	mov [SecPass2],18 	;if 1 second pass reset 1 secpass

	mov cx,4			;repeat 4 times
	
	DirChange:
		
		
		push cx 		 			; to get si (now omnic pointer)value for word long
			mov si,8 
			shl cx,1
			sub si,cx
		pop cx
		
		 dec [OmnicMoveT+si] 		;sec pass, decrease the time that the omnic needs to move in this direction
		 cmp [OmnicMoveT+si],0		;omnic time counter reached zero?
		 jle Set_Omnic				;if reached zero set a new random movement time and a random direction
		 loop DirChange				;if not there is nothing to do, move to the next omnic 
		jmp OutOfIt 				;if that is last omnic leave
		
		 Set_Omnic:
		 sub [xor_memory],31
		 call RnG 				;change omnic direction to random
		 mov bx,[rnd]
		 mov [OmnicDir+si],bx
		
		 add [xor_memory],207
		 call RnG 				;renew omnic moving time- 1 SEC,2 SEC,3 SEC (OR 0= MOVE UNTIL TOUCH BORDER. (but has the posibulity to change next comnic run)
		 shr [rnd],1			;to get time in range 0-3
		 mov bx,[rnd]
		 mov [OmnicMoveT+si],bx
		 
	loop DirChange		;move to next omnic
	
	OutOfIt:
 pop si
 pop dx		;restore saved registers
 pop cx
 pop bx
 
ret
endp Comnics

; CheckPass, see if the game is over by omnic being drawn on tracer's location. (player lost)
; if on tracer's location there is any OmnColor pixle 
PROC CheckPass 
	
	push ax
	push bx 
	push cx 
	push dx
	
	mov cx,Csize 		;repeat on lines Csize times 
	CheckPixleColumn:
		push cx			;save line repeat time
		mov cx,Csize 	;repeat on Column Csize times 
		
		CheckPixelLine:
			mov bh,0h
			push cx				;so we can restore cx, after drawing pixel. we need to keep this value for the loop
			mov cx,[cruser_X]
			mov dx,[cruser_Y]
			mov ah,0Dh
			int 10h 			;Read the wanted pixel
			pop cx 				;restore repeat times after using the interupt 
			cmp al,OmnColor		; if this pixle is colord purple (omnic on tracer) jump to lost
			je lost 
			inc [cruser_X]		; to check the next pixle next loop run
		loop CheckPixelLine
		inc [cruser_Y]			;to check a new line next run
		sub [cruser_X],Csize ;X NOW POINTS ON CHARACTER START
		pop cx			;restore the repeat times of the lines 
	loop CheckPixleColumn
	
	sub [cruser_Y],Csize 	; Y NOW POINTS ON CHARACTER START
	jmp passed				;the game isn't over, player did'nt "touch" an omnic continue playing the game
	
	lost: 
	pop cx 			;left in the middle of the loop but we still need to pop :D
	call GameOver	; player lost 
	
	Passed:
	pop dx			;restore all of the used registers
	pop cx
	pop bx
	pop ax


ret 
ENDP CheckPass

;sets the x and y of the omnics this frame by thier directions and calls to draw all omnics in the frame
PROC DrawOmnic 
push cx		;saved used registers
push si
push bx


mov si,[speed]
mov cx,4 ;repeat times
DrawNext:

		push cx 		 ; to get bx value for word long
			mov bx,8 
			shl cx,1
			sub bx,cx
		pop cx
		
		mov [color],BackColor 
		push [ Omnic_Y+bx]
		push [ Omnic_X+bx]
		call Charecter ;draws a 01bhx01bh squer on the screen, in the posion. to 'delete omnic'
		
		
	 cmp [OmnicDir+bx],0
	 je up
	 cmp [OmnicDir+bx],2
	 je down
	 cmp [OmnicDir+bx],4
	 je left
	 cmp [OmnicDir+bx],6
	 je right
	 

	 up:	;if direction points up change the y 
		
		sub [Omnic_Y+bx],si
		cmp [Omnic_Y+bx],border_top		; omnic touched up border? up = 28
		jnl continue_up 		; if not continue going up 
		add [Omnic_Y+bx],si		; dont let onmnic_y  get above the border
		mov [OmnicDir+bx], 2	; change dir to 2 (go down the opposite direction)
		
		continue_up:
		loop DrawNext 
		jmp NoNeedTOD
		
		
	 down:	;if direction points down change the y 
		add [Omnic_Y+bx],si	
		cmp [Omnic_Y+bx],200-Csize-border_w	; omnic touched down border? Borer =8
		jng continue_up 			;if not continue going down 
		sub [Omnic_Y+bx],si			;dont let onmnic_y  get under the border
		mov [OmnicDir+bx], 0		; change dir to 0 (go up the opposite direction)
		
		continue_down :
		loop DrawNext 
		jmp NoNeedTOD
		
	   
	 Loop_shortcut :	; proc is too long so here is a jump shortcut 
		loop DrawNext 
		jmp NoNeedTOD
	 left:	;if direction points left change the x
		
		sub [Omnic_X+bx],si
		cmp [Omnic_X+bx],border_w		;omnic touched left border?
		jnl continue_left		;if not continue left 
		add [Omnic_X+bx],si		; dont let omnic _x get left to the border
		mov [OmnicDir+bx],6		;change dir to 6 (go right the opposite direction)

		continue_left:
		jmp Loop_shortcut ;use shortcut to loop
		
		
		
	 right:	;if direction points right change the x 
	 	add [Omnic_X+bx],si
		cmp [Omnic_X+bx],320-Csize-border_w		;omnic touched right border?
		jng continue_right				;if not continue right
		sub [Omnic_X+bx],si				; dont let omnic _x get right to the border
		mov [OmnicDir+bx],4				;change dir to 4 (go left the opposite direction)
		
		continue_right:
		jmp Loop_shortcut ;use shortcut to loop
	
	NoNeedTOD:
	call OmnicDrawn; draw all omnics in frame
	pop bx
	pop si
	pop cx

ret 
endp DrawOmnic

;draw omnics in thier x and y 
proc OmnicDrawn

push bx ;Save used registers 
PUSH CX


	mov [color],OmnColor 
	mov cx,4
	drawem:
		push cx 		 ; to get bx value for word long
			mov bx,8 
			shl cx,1
			sub bx,cx
		pop cx
		
		push [ Omnic_Y+bx]
		push [ Omnic_X+bx]
		call Charecter ;draws a 01bhx01bh squer on the screen, in the posion.
	loop drawem
	
pop cx ;restore used registers
POP bx

ret 
endp OmnicDrawn
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;- extra graphics !!!!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

proc OpenFile

    ; Open file

    mov ah, 3Dh
    xor al, al
    mov dx, [file_offset]
    int 21h

    jc openerror
    mov [filehandle], ax
    ret

    openerror:
    mov dx, offset ErrorMsg
    mov ah, 9h
    int 21h
	
	mov ah,0h 			;wait for any key...
	int 16h
	
	;;exit game
	mov ah, 0 ; Return to text mode
	mov al, 2
	int 10h
	
	mov ax, 4c00h ;exit
	int 21h
	
    ret
endp OpenFile
proc ReadHeader

    ; Read BMP file header, 54 bytes

    mov ah,3fh
    mov bx, [filehandle]
    mov cx,54
    mov dx,offset Header
    int 21h
    ret
    endp ReadHeader
    proc ReadPalette

    ; Read BMP file color palette, 256 colors * 4 bytes (400h)

    mov ah,3fh
    mov cx,400h
    mov dx,offset Palette
    int 21h
    ret
endp ReadPalette
proc CopyPal

    ; Copy the colors palette to the video memory
    ; The number of the first color should be sent to port 3C8h
    ; The palette is sent to port 3C9h

    mov si,offset Palette
    mov cx,256
    mov dx,3C8h
    mov al,0

    ; Copy starting color to port 3C8h

    out dx,al

    ; Copy palette itself to port 3C9h

    inc dx
    PalLoop:

    ; Note: Colors in a BMP file are saved as BGR values rather than RGB.

    mov al,[si+2] ; Get red value.
    shr al,2 ; Max. is 255, but video palette maximal

    ; value is 63. Therefore dividing by 4.

    out dx,al ; Send it.
    mov al,[si+1] ; Get green value.
    shr al,2
    out dx,al ; Send it.
    mov al,[si] ; Get blue value.
    shr al,2
    out dx,al ; Send it.
    add si,4 ; Point to next color.

    ; (There is a null chr. after every color.)

    loop PalLoop
    ret
endp CopyPal

proc CopyBitmap

    ; BMP graphics are saved upside-down.
    ; Read the graphic line by line (200 lines in VGA format),
    ; displaying the lines from bottom to top.

    mov ax, 0A000h
    mov es, ax
    mov cx,200
    PrintBMPLoop:
    push cx

    ; di = cx*320, point to the correct screen line

    mov di,cx
    shl cx,6
    shl di,8
    add di,cx

    ; Read one line

    mov ah,3fh
    mov cx,320
    mov dx,offset ScrLine
    int 21h

    ; Copy one line into video memory

    cld 

    ; Clear direction flag, for movsb

    mov cx,320
    mov si,offset ScrLine
    rep movsb 

    ; Copy line to the screen
    ;rep movsb is same as the following code:
    ;mov es:di, ds:si
    ;inc si
    ;inc di
    ;dec cx
    ;loop until cx=0

    pop cx
    loop PrintBMPLoop
    ret
endp CopyBitmap


;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;
;points!!!

;generates a persudo random number and puts it's value in point_X, the value is never on the border.
; change xor_memory before calling for maximume officancy (add/sub)
proc RnGpointX 
	
	push ax ;save used registers
	push bx 
	push cx
	push dx
	
	mov ah, 2Ch		; Get clock time
	int 21h
	mov al, dl
	
	mov bx, [cs:xor_memory]
	xor ax, [bx]
	and ax, 320-pointC-border_w*2	; AX RANGE never at border 
	mov [point_X], ax
	add [point_X],border_w ;NEVER BE LESS THAN border_w
	

	pop dx 		;restore used registers
	pop cx
	pop bx
	pop ax
ret
endp RnGpointX

; generates a persudo random number and puts it's value in point_X, the value is never on the border.
; change xor_memory before calling for maximume officancy (add/sub)
proc RnGpointY 
	
	push ax 	;save used registers
	push bx 
	push cx
	push dx
	
	mov ah, 2Ch		; Get time
	int 21h
	mov al, dl
	

	mov bx, [cs:xor_memory]
	xor ax, [bx]
	and ax, 200-pointC-border_w-border_top	; AX RANGE never at border 
	mov [point_Y], ax
	add [point_Y],border_top ;NEVER BE LESS THAN border_w
	

	pop dx	;restore used registers
	pop cx
	pop bx
	pop ax
ret
endp RnGpointY


;draws the point on point_x point_Y , by the color in [color]
PROC DrawPoint  
	

	push ax		;store used registers
	push bx 
	push cx 
	push dx
	
	
	mov cx,PointC 
	DrawPointColumn:
		push cx				; store repeat times of the lines 
		mov cx,PointC 
		
		DrawPointLine: 
			mov bh,0h
			push cx			; store so value isn't lost by the interupt
			mov cx,[point_X] ;SET X
			mov dx,[point_Y] ;SET Y
			mov al,[color] ;SET COLOR
			mov ah,0ch
			int 10h ;draw the wanted pixel
			pop cx			;restore the value that needed to be changed for the interupt 
			inc [point_X]	;to draw next pixle in line next loop run 
		loop DrawPointLine
		inc [point_Y]		; to start new line next loop run
		sub [point_X],PointC  ;X NOW POINTS ON CHARACTER START
		pop cx				;restore the repeat times of the lines 
	loop DrawPointColumn
	
	sub [point_Y],PointC  ; Y NOW POINTS ON CHARACTER START
	
	pop dx		; restore used registers
	pop cx
	pop bx
	pop ax

ret 
ENDP DrawPoint

;checks if the point was taken by a user or omnic. if user -score up and delete. if omnic -delete. wan't touched - does nothing
;deletes point and counts a second befor drawing a new point
;checks the point_x and point_y from rngpointx and rngpointy so it wont be spawning on the user's tracer
;if it would be spawning on players tracer count another half second before generating new x and y --cheacking again-- and drawing a new point
PROC PointTaken 
	
	push ax		;store used registers
	push bx 
	push cx 
	push dx
	
	cmp [point_exist],0 ; check if the point exists 0= exists
	jne new_point
	
	mov bx,[point_X]	;save those values in stack before running loop so we can delete point properly
	mov x,bx			
	mov bx,[point_Y]
	mov y,bx
	
	mov cx,PointC 
	CheckPointColumn:
		push cx
		mov cx,PointC 
		
		CheckPointLine: 
			mov bh,0h
			push cx				;store cx before calling interupt
			mov cx,[point_X]
			mov dx,[point_Y]
			mov ah,0Dh
			int 10h 		  	;Read the wanted pixel
			pop cx				;restore cx 
			cmp al,Pcolor 		; if this pixle is omnic or tracer 
			jne point_up 		;if so see who "ate" the point
			inc [point_X]	  	;next pixle in line
		loop CheckPointLine
		inc [point_Y]
		sub [point_X],PointC 	;X NOW POINTS ON CHARACTER START
		pop cx	
	loop CheckPointColumn
	
	sub [point_Y],PointC  	; Y NOW POINTS ON CHARACTER START
	
	jmp Point_still			; after checking nothing touched point so it stays still.
	
	point_up:
	pop cx 					; left in a loop but we still need to pop :D
	cmp al,TrColor 			;was it player or omnic?
	jne deleteP 			;not point up :(
	inc [score]				; add to player's score :D
	mov [point_sound],0	 	;point_sound=0 play point sound :D
	mov [P_sound_time],0	;set time for playing sound 
	
	deleteP:
	
	mov bx,x			; return old x and y because we left in the middle of the loop and they only go back to the original at the end of it
	mov [point_X],bx	; we want to delete from original
	mov bx,y
	mov [point_Y],bx
	
	mov [color],BackColor
	call DrawPoint
	mov [point_exist],1 		;point was deleted=does not exist=1
	mov [update_count],0 		;wait a second after point was deleted befor drawing a new one
	
	new_point:
	cmp [update_count],18 		;have  second passed?
	jne Point_still
	
	
	; new point x and y
	mov [color],Pcolor				;point color
	add [xor_memory],22
	call RnGpointX 					;Puts a random x value in point X
	sub [xor_memory],99
	call RnGpointY 					;Puts a random y value in point y
	
	;so point won't spawn on user: sorry but user ain't getting any free points!!! :D
	mov bx,[cruser_X] 	
	sub bx , pointC					; if not -pointC then it would spawn on user (the rest of the point).
	cmp [point_X],bx
	jNge draw_the_point 			;no problem draw the point 
	add bx ,Csize
	cmp [point_X],bx
	jle check_y				 		;in user x range, check the y
	jmp draw_the_point				; not in user x range, draw the point 
	
	check_y:
	;so point won't spawn on user:
	mov bx ,[cruser_Y]	
	sub bx , pointC			; if not -pointC then it would spawn on user (the rest of the point).
	cmp [point_Y],bx
	jnge draw_the_point
	add bx ,Csize
	cmp [point_Y],bx
	jnle draw_the_point		;it's not going to spawn on charecter, draw

	;gonna spawn on charecter
	mov [update_count],9 	;wait another half second if point will spawn on user 
	jmp Point_still 
	
	draw_the_point:
	call DrawPoint
	mov [point_exist],0 	;point was drawn, the point exists
	
	
	Point_still:
	pop dx			;restore used registers
	pop cx
	pop bx
	pop ax

ret 
ENDP PointTaken

;play point sound for half second :D
proc PointSound
push ax			;store used register


cmp [point_sound],0		;was point taken by user and needs to play sound?
jne back_to_frame		; not taken= not play
cmp [P_sound_time],6	;if it was taken [P_sound_time] was set to zero and increased in each frame
je no_sound				;if it reached third second stop playing

cmp [P_sound_time],0
jg	back_to_frame ;already activated speaker
;play sound:

	in al, 61h ;activate speaker
	or al, 00000011b
	out 61h, al
	
	mov al, 0B6h ;get acsess
	out 43h, al
	
	mov al, 48
	out 42h, al ; Sending lower byte
	mov al, 30
	out 42h, al ; Sending upper byte

	jmp back_to_frame
	
no_sound: 
	mov [point_sound],1 ;no need to play sound anymore
	in al, 61h ;deactivate speaker
	and al, 11111100b
	out 61h, al

back_to_frame:
pop ax			;restore used register
ret
endp