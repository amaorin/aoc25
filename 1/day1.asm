BITS 64
global _start

%include "../common.asm"

section .text
_start:
	mov rdi, rsp
	mov rsi, input
	mov rdx, input_len
	call read_input

	mov QWORD [part1_result], 0
	mov QWORD [part2_result], 0

	mov r12, QWORD [input]
	mov r13, QWORD [input_len]
	mov r15, 50
	xor rbx, rbx
	xor rbp, rbp
	loop:
		mov rdi, r12
		mov rsi, r13
		call eat_whitespace
		add r12, rax
		sub r13, rax

		cmp r13, 0
		jle loop_end

		movzx r14, BYTE [r12]
		inc r12
		dec r13

		mov rdi, r12
		mov rsi, r13
		call eat_s64
		add r12, rax
		sub r13, rax

		mov rsi, rdx
		neg rsi
		cmp r14, 'L'
		cmove rdx, rsi

		mov r9, r15
		mov r10, rdx
		lea rax, [r15 + rdx]

		compensate_harder:
		add rax, 100
		test rax, rax
		js compensate_harder

		xor rdx, rdx
		mov r8, 100
		idiv r8
		mov r15, rdx

		lea rax, [rbx + 1]
		cmp r15, 0
		cmove rbx, rax

		xor rdx, rdx
		mov rax, r10
		mov r8, 100
		idiv r8
		lea r8, [r9 + rax]

		lea rax, [r9 - 100]
		neg rax
		cmp r9, 0
		cmove rax, r9
		mov rdx, r10
		neg rdx
		cmp r10, 0
		cmovl r9, rax
		cmovl r10, rdx

		xor rdx, rdx
		lea rax, [r9 + r10]
		mov r8, 100
		idiv r8
		lea r8, [rax - 1]
		cmp rdx, 0
		cmove rax, r8

		add rbp, rax
		
		jmp loop
	loop_end:

	mov QWORD [part1_result], rbx

	add rbp, rbx
	mov QWORD [part2_result], rbp

	mov rdi, QWORD [part1_result]
	mov rsi, QWORD [part2_result]
	call print_results

	mov rax, 60 ; sys_exit
	mov rdi, 0  ; error code
	syscall

section .data
newline db 0x0A

section .bss
input resb 8
input_len resb 8
part1_result resb 8
part2_result resb 8
