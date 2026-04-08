;; console.asm
;; Created by Matheus Leme Da Silva
%ifndef _CONSOLE_ASM_
%define _CONSOLE_ASM_
%define T80x50

;; Initializes console
section .text
console_init:
	;; Set text mode
	mov ax, 3
	int 0x10

	mov word [console_width], 79
	mov word [console_height], 24

%ifdef T80x50
	;; Set font 8x8
	mov ax, 0x1112
	int 0x10
	mov word [console_height], 49
%endif ;; T80x50
	
	mov word [current_cursor_x], 1
	mov word [current_cursor_y], 1

	mov word [top_corner_x], 1
	mov word [top_corner_y], 1
	mov word [bottom_corner_x], 78
%ifdef T80x50
	mov word [bottom_corner_y], 48
%else
	mov word [bottom_corner_y], 23
%endif ;; T80x50
	mov byte [current_attributes], 0x1F

	call redraw_interface

	ret

;; Redraw the interface
section .text
redraw_interface:
	push bx
	mov bh, byte [current_attributes]
	call clear
	pop bx
	
	push ax
	push dx
	push cx

	;; Draw borders
	mov al, 0xC9 ;; ╔
	mov ah, byte [current_attributes]
	mov dl, 0
	mov dh, 0
	call put_char
	
	;; Draw top line
	mov cx, word [console_width]
	dec cx
	mov al, 0xCD ;; ═
	mov dl, 1
	mov dh, 0
.line1_loop:
	call put_char
	inc dl
	loop .line1_loop

	mov al, 0xBB ;; ╗
	mov dl, byte [console_width]
	mov dh, 0
	call put_char

	;; Print ║ in col 0 and MAX_WIDTH in lines 1-(MAX_HEIGHT-1)
	mov cx, word [console_height]
	dec cx
	mov al, 0xBA ;; ║
	mov dh, 1
.rows_loop:
	;; col 0
	mov dl, 0
	call put_char

	;; col 79
	mov dl, byte [console_width]
	call put_char

	inc dh
	loop .rows_loop

	mov al, 0xC8 ;; ╚
	mov dl, 0
	mov dh, byte [console_height]
	call put_char
	
	;; Draw bottom line 
	mov cx, 78
	mov al, 0xCD ;; ═
	mov dl, 1
	mov dh, byte [console_height]
.line2_loop:
	call put_char
	inc dl
	loop .line2_loop

	mov al, 0xBC ;; ╝
	mov dl, byte [console_width]
	mov dh, byte [console_height]
	call put_char

	push bp
	;; Title
	mov ah, 0x13
	mov bh, 0
	mov bl, byte [current_attributes]
	mov cx, (.title_end - .title)
	mov dh, 0
	mov dl, 2
	mov bp, .title
	int 0x10
	
	;; Build
	mov ah, 0x13
	mov bh, 0
	mov bl, byte [current_attributes]
	mov cx, (.build_date_end - .build_date)
	mov dh, 0
	mov dl, byte [console_width]
	sub dl, 2
	sub dl, (.build_date_end - .build_date)
	mov bp, .build_date
	int 0x10

	pop bp
	
	pop cx
	pop dx
	pop ax
	ret
.title: db " Bitix "
.title_end:
.build_date: db " Build ", __DATE__, " ", __TIME__, " "
.build_date_end:

;; Clears the screen
;; BH = attr
section .text
clear:
	push ax
	push cx
	push dx
	mov ah, 0x06
	mov al, 0
	mov ch, byte [top_corner_y]
	mov cl, byte [top_corner_x]
	mov dh, byte [bottom_corner_y]
	mov dl, byte [bottom_corner_x]
	int 0x10
	pop dx
	pop cx
	pop ax
	ret

;; Put a character in VGA mode
;; AL: char
;; AH: attributes
;; DH: row
;; DL: col
section .text
put_char:
	push ax
	push dx
	push di
	push es
	
	mov byte [.row], dh
	mov byte [.col], dl

	;; offset = (line * 80 + col) * 2
	;; char = offset
	;; attr = offset + 1
	mov di, 0xB800
	mov es, di
	mov di, word [.row]
	mov dx, di

	shl di, 6 ;; * 64
	;; DI = line * 64
	
	shl dx, 4 ;; * 16
	;; DX = line * 16

	add di, dx
	;; DI = line * 80

	add di, word [.col]
	;; DI = line * 80 + col

	shl di, 1 ;; * 2
	;; DI = (line * 80 + col) * 2

	mov byte [es:di], al
	mov byte [es:di+1], ah

	pop es
	pop di
	pop dx
	pop ax
	ret
section .data
.row: dw 0
.col: dw 0

;; Scrolls the screen
section .text
scroll:
	push ax
	push bx
	push cx
	push dx

	mov ah, 0x06
	mov al, 1
	mov bh, byte [current_attributes]
	mov ch, byte [top_corner_y]
	mov cl, byte [top_corner_x]
	mov dh, byte [bottom_corner_y]
	mov dl, byte [bottom_corner_x]
	int 0x10
	dec word [current_cursor_y]
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret

;; Prints a character on the screen
section .text
print_char:
	push ax
	push bx
	push dx
	
	;; DEBUG: Print on serial
	%ifdef DEBUG
	push dx
	xor dx, dx
	mov ah, 0x01
	int 0x14
	pop dx
	%endif ;; DEBUG

	cmp al, 0x0D
	je .carriage_return

	cmp al, 0x0A
	je .inc_y
	
	;; Draw char
	mov dl, byte [current_cursor_x]
	mov dh, byte [current_cursor_y]
	mov ah, byte [current_attributes]
	call put_char

	inc word [current_cursor_x]
	
	;; Verify if need jump to next line
	mov ax, word [bottom_corner_x]
	cmp word [current_cursor_x], ax
	jbe .no_inc_y
.inc_y:
	;; y++
	inc word [current_cursor_y]
.carriage_return:
	;; x = top_corner_x
	mov ax, word [top_corner_x]
	mov word [current_cursor_x], ax
.no_inc_y:
	;; Verify if need to scroll
	mov ax, word [bottom_corner_y]
	cmp word [current_cursor_y], ax
	jbe .no_scroll
	call scroll
.no_scroll:

	mov ah, 0x02
	mov bh, 0
	mov dh, byte [current_cursor_y]
	mov dl, byte [current_cursor_x]
	int 0x10

	pop dx
	pop bx
	pop ax
	ret

;; Prints a string ending with zero on the screen
;; DS:SI: pointer to string
section .text
print_string:
	push ax
	push si
.loop:
	lodsb ;; al = ds:si++
	test al, al
	jz .end
	call print_char
	jmp .loop
.end:
	pop si
	pop ax
	ret

%macro print 1+
section .data
%%string: db %1, 0
section .text
	push si
	mov si, %%string
	call print_string
	pop si
%endmacro

%macro newline 0
section .text
	push ax
	mov al, 0x0A
	call print_char
	pop ax
%endmacro

;; Prints a HEX 4-bit value in AL
section .text
print_nibble:
	push ax
	and al, 0x0F

	cmp al, 9
	jbe .digit
	sub al, 10
	add al, 'A'
	jmp .end
.digit:
	add al, '0'
.end:
	call print_char
	pop ax
	ret

;; Prints a HEX 8-bit value
;; 1: r8
%macro print_hex_byte 1
section .text
	push ax
	mov al, %1

	push ax
	;; Nibble 1
	shr al, 4
	call print_nibble
	pop ax

	;; Nibble 0
	call print_nibble

	pop ax
%endmacro

;; Prints a HEX 16-bit value
;; 1: r16
%macro print_hex_word 1
section .text
	push bx
	mov bx, %1
	print_hex_byte bh
	print_hex_byte bl
	pop bx
%endmacro

;; Prints a HEX 32-bit value
;; 1: high r16
;; 2: low r16
%macro print_hex_dword 2
section .text
	push cx
	mov cx, %1
	print_hex_word cx
	mov cx, %2
	print_hex_word cx
	pop cx
%endmacro

section .bss
current_cursor_x:   resw 1
current_cursor_y:   resw 1
top_corner_y:       resw 1
top_corner_x:       resw 1
bottom_corner_y:    resw 1
bottom_corner_x:    resw 1
console_width:      resw 1
console_height:     resw 1
current_attributes: resb 1

%endif ;; _CONSOLE_ASM_
