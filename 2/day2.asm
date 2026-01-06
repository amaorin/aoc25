BITS 64

%include "../common.asm"

global _start

section .text
_start:
	mov rdi, rsp
	mov rsi, input
	mov rdx, input_len
	call read_input
	
	sub rsp, 0x40
	mov r12, QWORD [input]
	mov QWORD [rsp + 0x00], r12

	mov r13, QWORD [input_len]
	mov QWORD [rsp + 0x08], r13

	mov QWORD [rsp + 0x40], 0
	mov QWORD [rsp + 0x48], 0

	loop:
		mov r12, QWORD [rsp + 0x00]
		mov r13, QWORD [rsp + 0x08]

		mov rdi, r12
		mov rsi, r13
		call eat_whitespace
		add rdi, rax
		sub rsi, rax

		cmp rsi, 0
		jle loop_end

		mov rdi, r12
		mov rsi, r13
		call eat_s64
		add r12, rax
		sub r13, rax
		mov r14, rdx

		; assume a -
		inc r12
		dec r13

		mov rdi, r12
		mov rsi, r13
		call eat_s64
		add r12, rax
		sub r13, rax
		mov r15, rdx

		; assume a , or eof
		inc r12
		dec r13

		mov QWORD [rsp + 0x00], r12
		mov QWORD [rsp + 0x08], r13
		mov QWORD [rsp + 0x10], r14
		mov QWORD [rsp + 0x18], r15

		mov r12, QWORD [rsp + 0x10]
		mov rdi, r12
		call ilog10
		mov r13, rax
		shr r13, 1
		inc r13

		mov rdi, r13
		call ipow10
		mov r8, rax

		xor rdx, rdx
		mov rax, r12
		idiv r8

		mov r14, rax
		mov r15, rdx
		
		mov r9, r14
		lea r10, [r9 + 1]
		cmp r15, r14
		cmovg r9, r10

		lea rdi, [r13 - 1]
		call ipow10
		lea r11, [rax]
		cmp r14, rax
		cmovl r9, r11

		mov QWORD [rsp + 0x20], r9

		mov r12, QWORD [rsp + 0x18]
		mov rdi, r12
		call ilog10
		mov r13, rax
		shr r13, 1
		inc r13

		mov rdi, r13
		call ipow10
		mov r8, rax

		xor rdx, rdx
		mov rax, r12
		idiv r8

		mov r14, rax
		mov r15, rdx
		
		mov r9, r14
		lea r10, [r9 - 1]
		cmp r15, r14
		cmovl r9, r10

		lea rdi, [r13 - 1]
		call ipow10
		lea r11, [rax - 1]
		cmp r14, rax
		cmovl r9, r11

		mov QWORD [rsp + 0x28], r9

		mov r12, QWORD [rsp + 0x20]
		mov r13, QWORD [rsp + 0x28]

		mov r14, r13
		sub r14, r12

		mov r15, r14
		inc r14
		imul r15, r14
		shr r15, 1

		imul r14, r12

		add r14, r15

		mov rdi, r12
		call ilog10
		lea rdi, [rax + 1]
		call ipow10

		mov r15, r14
		imul r15, rax
		add r14, r15

		mov r8, QWORD [rsp + 0x40]
		add r8, r14
		mov QWORD [rsp + 0x40], r8

		jmp loop
	loop_end:

	mov rdi, QWORD [rsp + 0x40]
	mov rsi, QWORD [rsp + 0x48]
	call print_results

	add rsp, 0x40

	mov rax, 60 ; sys_exit
	mov rdi, 1  ; error code
	syscall

section .data
nl db 0x0A

section .bss
input resb 8
input_len resb 8
