;; console.asm
;; Created by Matheus Leme Da Silva
%IFNDEF _CONSOLE_ASM_
%DEFINE _CONSOLE_ASM_

;; Prints a string ending with zero on the screen
;; DS:SI: pointer to string
print_string:
	PUSH AX
	PUSH SI
	MOV AH, 0x0E
.loop:
	LODSB ;; AL = DS:SI++
	TEST AL, AL
	JZ .end
	INT 0x10
	JMP .loop
.end:
	POP SI
	POP AX
	RET

%ENDIF ;; _CONSOLE_ASM_

