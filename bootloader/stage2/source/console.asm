;; console.asm
;; Created by Matheus Leme Da Silva
%ifndef _CONSOLE_ASM_
%define _CONSOLE_ASM_

%define DEFAULT_FG_COLOR    0x07        ;; Default: white on black
%define DEFAULT_BG_COLOR    0x00        ;; Default: black background
%define DEFAULT_ATTR        0x07        ;; Default: white on black

%define TITLE_FG_COLOR      0x0A        ;; Green for titles
%define TITLE_BG_COLOR      0x00        ;; Black background

%define ERROR_FG_COLOR      0x04        ;; Red for errors
%define ERROR_BG_COLOR      0x00        ;; Black background

%define SUCCESS_FG_COLOR    0x0A        ;; Green for success
%define SUCCESS_BG_COLOR    0x00        ;; Black background

%define T80x50                          ;; Uncomment for 80x50 mode

;; Foreground: 0x0-0xF, Background: 0x00-0xF0
;; Attribute = (bg << 4) | fg
;; 0 = black, 1 = blue, 2 = green, 3 = cyan, 4 = red, 5 = magenta
;; 6 = brown, 7 = gray, 8 = darkgray, 9 = lightblue, A = lightgreen, B = lightcyan
;; C = lightred, D = lightmagenta, E = yellow, F = white

;; Initializes console
section .text
console_init:
;; Set text mode 80x25 (3) or 80x50 (83)
	mov ax, 3
	int 0x10

	mov word [console_width], 79
	mov word [console_height], 24

;; Set 80x50 mode if configured
	%ifdef T80x50
	mov ax, 0x1112
	int 0x10
	mov word [console_height], 49
	%endif ;; T80x50

;; Initialize cursor position
	mov word [current_cursor_x], 0
	mov word [current_cursor_y], 0

;; Initialize screen boundaries
	mov word [top_corner_x], 0
	mov word [top_corner_y], 0
	mov word [bottom_corner_x], 79
	%ifdef T80x50
	mov word [bottom_corner_y], 49
	%else
	mov word [bottom_corner_y], 24
	%endif ;; T80x50

;; Set default color
	mov byte [current_attributes], DEFAULT_ATTR

	ret

;; Clears the screen with current background color
section .text
console_clear:
	push ax
	push cx
	push dx

	mov ah, 0x06
	mov al, 0
	mov bh, byte [current_attributes]
	mov ch, byte [top_corner_y]
	mov cl, byte [top_corner_x]
	mov dh, byte [bottom_corner_y]
	mov dl, byte [bottom_corner_x]
	int 0x10

	pop dx
	pop cx
	pop ax
	ret

;; Moves cursor to specific position
;; DH: row, DL: col
section .text
set_cursor_position:
	push ax
	push bx

	mov ah, 0x02
	xor bx, bx
	int 0x10

	pop bx
	pop ax
	ret

;; Gets current cursor position
;; Returns: DH: row, DL: col
section .text
get_cursor_position:
	push ax
	push bx

	mov ah, 0x03
	xor bx, bx
	int 0x10

	pop bx
	pop ax
	ret

;; Sets foreground color
;; AL: foreground color (0x0-0xF)
section .text
set_foreground_color:
	push ax
	and al, 0x0F
	mov byte [current_fg_color], al
	call update_attributes
	pop ax
	ret

;; Sets background color
;; AL: background color (0x0-0xF)
section .text
set_background_color:
	push ax
	and al, 0x0F
	shl al, 4
	mov byte [current_bg_color], al
	call update_attributes
	pop ax
	ret

;; Resets color to default
section .text
reset_color:
	push ax

	mov byte [current_fg_color], DEFAULT_FG_COLOR
	mov byte [current_bg_color], DEFAULT_BG_COLOR
	call update_attributes

	pop ax
	ret

;; Updates current_attributes from fg/bg colors
section .text
update_attributes:
	push ax

	mov al, byte [current_bg_color]
	or al, byte [current_fg_color]
	mov byte [current_attributes], al

	pop ax
	ret

;; Puts a character in VGA mode
;; AL: character
;; AH: attributes
;; DH: row
;; DL: col
section .text
put_char:
	push dx
	push di
	push es

	mov byte [.row], dh
	mov byte [.col], dl

;; offset = (row * 80 + col) * 2
	mov di, 0xB800
	mov es, di
	mov di, word [.row]
	mov dx, di

	shl di, 6                ;; row * 64
	shl dx, 4               ;; row * 16
	add di, dx              ;; row * 80
	add di, word [.col]     ;; row * 80 + col
	shl di, 1               ;; * 2 for character/attribute

	mov byte [es:di], al
	mov byte [es:di+1], ah

	pop es
	pop di
	pop dx
	ret
section .data
.row: dw 0
.col: dw 0

;; Scrolls the screen one line
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

;; Prints a character on the screen with current attributes and cursor position
;; AL: character
section .text
print_char:
	push ax
	push bx
	push dx

;; DEBUG: Print on serial if DEBUG is defined
%ifdef DEBUG
	push dx
	xor dx, dx
	mov ah, 0x01
	int 0x14
	pop dx
%endif ;; DEBUG

;; Handle carriage return
	cmp al, 0x0D
	je .carriage_return

;; Handle line feed
	cmp al, 0x0A
	je .line_feed

;; Draw character at current cursor position
	mov dl, byte [current_cursor_x]
	mov dh, byte [current_cursor_y]
	mov ah, byte [current_attributes]
	call put_char

	inc word [current_cursor_x]

;; Check if need to move to next line
	mov ax, word [bottom_corner_x]
	cmp word [current_cursor_x], ax
	jbe .no_inc_y
.line_feed:
	inc word [current_cursor_y]
.carriage_return:
	mov ax, word [top_corner_x]
	mov word [current_cursor_x], ax
.no_inc_y:
;; Check if need to scroll
	mov ax, word [bottom_corner_y]
	cmp word [current_cursor_y], ax
	jbe .no_scroll
	call scroll
.no_scroll:
;; Update hardware cursor
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
	lodsb  ;; AL = DS:SI++
	test al, al
	jz .end
	call print_char
	jmp .loop
.end:
	pop si
	pop ax
	ret

;; Prints a string in title color (green)
;; DS:SI: pointer to string
section .text
print_title:
	push ax
	push si

	mov al, byte [current_fg_color]
	push ax
	mov al, TITLE_FG_COLOR
	call set_foreground_color
	pop ax

	call print_string

	call reset_color

	pop si
	pop ax
	ret

;; Prints a string in error color (red)
;; DS:SI: pointer to string
section .text
print_error:
	push ax
	push si

	mov al, byte [current_fg_color]
	push ax
	mov al, ERROR_FG_COLOR
	call set_foreground_color
	pop ax

	call print_string

	call reset_color

	pop si
	pop ax
	ret

;; Prints a string in success color (green)
;; DS:SI: pointer to string
section .text
print_success:
	push ax
	push si

	mov al, byte [current_fg_color]
	push ax
	mov al, SUCCESS_FG_COLOR
	call set_foreground_color
	pop ax

	call print_string

	call reset_color

	pop si
	pop ax
	ret

;; Macro for printing inline strings
%macro print 1+
section .data
%%string: db %1, 0
section .text
	push si
	mov si, %%string
	call print_string
	pop si
%endmacro

;; Macro for printing title-styled strings
%macro print_title 1+
section .data
%%string: db %1, 0
section .text
	push si
	mov si, %%string
	call print_title
	pop si
%endmacro

;; Macro for printing error-styled strings
%macro print_error 1+
section .data
%%string: db %1, 0
section .text
	push si
	mov si, %%string
	call print_error
	pop si
%endmacro

;; Macro for printing success-styled strings
%macro print_success 1+
section .data
%%string: db %1, 0
section .text
	push si
	mov si, %%string
	call print_success
	pop si
%endmacro

;; Macro for new line
%macro newline 0
section .text
	push ax
	mov al, 0x0A
	call print_char
	pop ax
%endmacro

;; Converts a nibble to hex character
;; AL: nibble (0x0-0xF)
;; Returns: AL: hex character
section .text
nibble_to_hex:
	push cx
	mov cl, al
	and cl, 0x0F
	cmp cl, 9
	jbe .digit
	sub cl, 10
	add cl, 'A'
	jmp .end
.digit:
	add cl, '0'
.end:
	mov al, cl
	pop cx
	ret

;; Prints a 4-bit value in hex
;; AL: nibble
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

;; Prints an 8-bit value in hex
;; 1: r8
%macro print_hex_byte 1
section .text
	push ax
	mov al, %1
	shr al, 4
	call print_nibble
	pop ax
	push ax
	mov al, %1
	call print_nibble
	pop ax
%endmacro

;; Prints a 16-bit value in hex
;; 1: r16
%macro print_hex_word 1
section .text
	push bx
	mov bx, %1
	print_hex_byte bh
	print_hex_byte bl
	pop bx
%endmacro

;; Prints a 32-bit value in hex
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
current_cursor_x:	resw 1
current_cursor_y:	resw 1
top_corner_y:	resw 1
top_corner_x:	resw 1
bottom_corner_y:	resw 1
bottom_corner_x:	resw 1
console_width:	resw 1
console_height:	resw 1
current_attributes: resb 1
current_fg_color:	resb 1
current_bg_color:	resb 1

%endif ;; _CONSOLE_ASM_
