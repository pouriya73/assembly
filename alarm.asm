Alarm

cseg	segment para public 'code'
org	100h
alarm	proc far

; Memory-resident program to intercept the timer interrupt and display the
; system time in the upper right-hand corner of the display.
; This program is run as 'ALARM hh:mm x', where hh:mm is the alarm time and
; x is '-' to turn the display off. Any other value of x or no value will
; turn the clock on

intaddr equ 1ch*4		; interrupt address
segaddr equ 62h*4		; segment address of first copy
mfactor equ 17478		; minute conversion factor * 16
whozat	equ 1234h		; signature
color	equ 14h 		; color attribute

	assume cs:cseg,ds:cseg,ss:nothing,es:nothing
	jmp p150		; start-up code

jumpval dd 0			; address of prior interrupt
signature dw whozat		; program signature
state	db 0			; '-' = off, all else = on
wait	dw 18			; wait time - 1 second or 18 ticks
hour	dw 0			; hour of the day
atime	dw 0ffffh		; minutes past midnite for alarm
acount	dw 0			; alarm beep counter - number of seconds (5)
atone	db 5			; alarm tone - may be from 1 to 255 - the
				; higher the number, the lower the frequency
aleng	dw 8080h		; alarm length (loop count) may be from 1-FFFF

dhours	dw 0			; display hours
	db ':'
dmins	dw 0			; display minutes
	db ':'
dsecs	dw 0			; display seconds
	db '-'
ampm	db 0			; 'A' or 'P' for am or pm
	db 'm'

tstack	db 16 dup('stack   ')   ; temporary stack
estack	db 0			; end of stack
holdsp	dw 0			; original sp
holdss	dw 0			; original ss

p000:				; interrupt code
	push ax 		; save registers
	push ds
	pushf

	push cs
	pop ds			; make ds=cs
	mov ax,wait		; check wait time
	dec ax			; zero?
	jz p010 		; yes - 1 second has elapsed
	mov wait,ax		; not this time
	jmp p080		; return

p010:	cli			; disable interrupts
	mov ax,ss		; save stack
	mov holdss,ax
	mov holdsp,sp
	mov ax,ds
	mov ss,ax		; point to internal stack
	mov sp,offset estack
	sti			; allow interrupts

	push bx 		; save other registers
	push cx
	push dx
	push es
	push si
	push di
	push bp

	mov ax,18		; reset wait time
	mov wait,ax

	mov al,state		; are we disabled?
	cmp al,'-'
	jnz p015		; no
	jmp p070

p015:	mov ah,0		; read time
	int 1ah 		; get time of day
	mov ax,dx		; low part
	mov dx,cx		; high part
	mov cl,4
	shl dx,cl		; multiply by 16
	mov bx,ax
	mov cl,12
	shr bx,cl		; isolate top 4 bits of ax
	add dx,bx		; now in upper
	mov cl,4
	shl ax,cl		; multiply by 16
	mov bx,mfactor		; compute minutes
	div bx			; minutes in ax, remainder in dx
	cmp ax,atime		; time to sound the alarm?
	jnz p020		; no
	call p100		; yes - beep the speaker twice
	push ax
	mov ax,acount		; get beep count
	dec ax			; down by 1
	mov acount,ax		; save beep count
	cmp ax,0		; is it zero?
	jnz p018		; no - keep alarm on
	mov ax,0ffffh		; turn off alarm
	mov atime,ax
p018:	pop ax

p020:	mov dsecs,dx		; save remainder
	mov bx,60		; compute hours
	xor dx,dx		; zero it
	div bx			; hours in ax, minutes in dx
	mov dmins,dx		; save minutes

	cmp ax,0		; midnight?
	jnz p030		; no
	mov ax,12		; yes
	jmp p040a		; set am

p030:	cmp ax,12		; before noon?
	jb p040a		; yes - set am
	jz p040p		; noon - set pm
	sub ax,12		; convert the rest
p040p:	mov bl,'p'
	jmp p040x

p040a:	mov bl,'a'

p040x:	mov ampm,bl
	aam			; fix up hour
	cmp ax,hour		; top of the hour?
	jz p060 		; no

	mov hour,ax
	call p120		; beep the speaker once

p060:	add ax,3030h		; convert hours to ascii
	xchg ah,al
	mov dhours,ax

	mov ax,dmins		; get minutes
	aam
	add ax,3030h		; convert to ascii
	xchg ah,al
	mov dmins,ax

	mov ax,dsecs		; get seconds (remainder)
	xor dx,dx
	mov bx,60
	mul bx
	mov bx,mfactor
	div bx			; seconds in ax
	aam
	add ax,3030h
	xchg ah,al
	mov dsecs,ax

	xor ax,ax		; check monitor type
	mov es,ax
	mov ax,es:[410h]	; get config byte
	and al,30h		; isolate monitor type
	cmp al,30h		; color?
	mov ax,0b000h		; assume mono
	jz p061 		; its mono

	mov ax,0b800h		; color screen address

p061:	mov dx,es:[463h]	; point to 6845 base port
	add dx,6		; point to status port

	mov es,ax		; point to monitor
	mov bh,color		; color in bh
	mov si,offset dhours	; point to time
	mov di,138		; row 1, col 69
	cld
	mov cx,11		; loop count

p062:	mov bl,[si]		; get next character

p063:	in al,dx		; get crt status
	test al,1		; is it low?
	jnz p063		; no - wait
	cli			; no interrupts

p064:	in al,dx		; get crt status
	test al,1		; is it high?
	jz p064 		; no - wait

	mov ax,bx		; move color & character
	stosw			; move color & character again
	sti			; interrupts back on
	inc si			; point to next character
	loop p062		; done?

p070:	pop bp			; restore registers
	pop di
	pop si
	pop es
	pop dx
	pop cx
	pop bx
	cli			; no interrupts
	mov ax,holdss
	mov ss,ax
	mov sp,holdsp
	sti			; allow interrupts

p080:	popf
	pop ds
	pop ax
	jmp cs:[jumpval]

p100	proc near		; beep the speaker twice
	call p120
	push cx
	mov cx,20000
p105:	loop p105		; wait around
	pop cx
	call p120
	push cx
	mov cx,20000
p106:	loop p106		; wait around
	pop cx
	call p120
	ret
p100	endp

p120	proc near		; beep the speaker once
	push ax
	push cx
	mov al,182
	out 43h,al		; setup for sound
	mov al,0
	out 42h,al		; low part
	mov al,atone		; get alarm tone
	out 42h,al		; high part
	in al,61h
	push ax 		; save port value
	or al,3
	out 61h,al		; turn speaker on
	mov cx,aleng		; get loop count
p125:	loop p125		; wait around
	pop ax			; restore original port value
	out 61h,al		; turn speaker off
	pop cx
	pop ax
	ret
p120	endp

p150:				; start of transient code
	mov dx,offset copyr
	call p220		; print copyright
	mov ax,0
	mov es,ax		; segment 0
	mov di,segaddr+2	; this program's prior location
	mov ax,es:[di]		; get prior code segment
	mov es,ax		; point to prior program segment
	mov di,offset signature
	mov cx,es:[di]		; is it this program?
	cmp cx,whozat
	jnz p160		; no - install it
	call p200		; set state & alarm
	int 20h 		; terminate

p160:	mov di,segaddr+2	; point to int 62h
	mov ax,0
	mov es,ax		; segment 0
	mov ax,ds		; get current ds
	mov es:[di],ax		; set int 62h
	mov si,offset jumpval
	mov di,intaddr		; point to timer interrupt
	mov bx,es:[di]		; get timer ip
	mov ax,es:[di+2]	; and cs
	mov [si],bx		; save prior ip
	mov [si+2],ax		; and cs
	mov bx,offset p000
	mov ax,ds
	cli			; clear interrupts
	mov es:[di],bx		; set new timer interrupt
	mov es:[di+2],ax
	sti			; set interrupts
	push ds
	pop es
	call p200		; set state & alarm
	mov dx,offset p150	; last byte of resident portion
	inc dx
	int 27h 		; terminate

p200	proc near		; set state & alarm
	mov si,80h		; point to command line
	mov ax,0
	mov di,0ffffh		; init hours
	mov bh,0
	mov ch,0
	mov dh,0		; : counter
	mov es:[state],bh	; turn clock on
	mov cl,[si]		; get length
	jcxz p210		; it's zero

p203:	inc si			; point to next char
	mov bl,[si]		; get it
	cmp bl,'-'              ; is it a minus?
	jnz p204		; no
	mov es:[state],bl	; turn clock off
	push dx
	mov dx,offset msg3	; print msg
	call p220
	pop dx
	jmp p206

p204:	cmp dh,2		; seen 2nd colon?
	jz p206 		; yes - ignore seconds
	cmp bl,':'              ; colon?
	jnz p205		; no
	inc dh
	cmp dh,2		; second colon?
	jz p206 		; yes - ignore seconds
	push cx
	push dx
	mov cx,60
	mul cx			; multiply current ax by 60
	pop dx
	pop cx
	mov di,ax		; save hours
	mov ax,0
	jmp p206
p205:	cmp bl,'0'
	jb p206 		; too low
	cmp bl,'9'
	ja p206 		; too high - can be a problem
	sub bl,'0'              ; convert it to binary
	push cx
	push dx
	mov cx,10
	mul cx			; multiply current value by 10
	add ax,bx		; and add latest digit
	pop dx
	pop cx
p206:	loop p203		; done yet?
	cmp di,0ffffh		; any time to set?
	jz p210 		; no
	add ax,di		; add hours
	cmp ax,24*60
	jb p209 		; ok
	mov dx,offset msg1	; print error message
	call p220
	jmp p210

p209:	mov es:[atime],ax	; save minutes past midnight
	mov ax,5
	mov es:[acount],ax	; set alarm count
	mov dx,offset msg2	; print set msg
	call p220
p210:	ret
p200	endp

p220	proc near		; print message
	push ax
	mov ah,9
	int 21h
	pop ax
	ret
p220	endp

copyr	db 'Alarm - Clock',10,13,'$'
msg1	db 'Invalid time - must be from 00:00 to 23:59',10,13,'$'
msg2	db 'Resetting alarm time',10,13,'$'
msg3	db 'Turning clock display off',10,13,'$'

alarm	endp
cseg	ends
end	alarm
