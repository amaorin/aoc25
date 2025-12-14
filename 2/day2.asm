BITS 64

%include "../common.asm"

global _start

section .text
_start:
	mov rdi, rsp
	mov rsi, input
	mov rdx, input_len
	call read_input

	mov rdi, QWORD [input]
	mov rsi, QWORD [input_len]
	call print_string

	mov rax, 60 ; sys_exit
	mov rdi, 1  ; error code
	syscall

section .data

section .bss
input resb 8
input_len resb 8
