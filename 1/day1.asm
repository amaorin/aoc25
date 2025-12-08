BITS 64
global _start

%include "../common.asm"

section .text
_start:
	
	mov rdi, 0
	mov rsi, -42
	call print_results

	mov rax, 60 ; sys_exit
	mov rdi, 0  ; error code
	syscall

section .data
