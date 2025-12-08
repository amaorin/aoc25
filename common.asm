section .text

write_string: ; u64 write_string(u8* buf, u64 cap, u8* str, u64 len)

	; to_write = (len > cap ? cap : len)
	mov rax, rcx
	cmp rax, rsi
	cmovg rax, rsi

	xor r8, r8
	write_string_loop:
		cmp r8, rax
		jge write_string_loop_end

		movzx r9, BYTE [rdx + r8]
		mov BYTE [rdi + r8], r9b

		inc r8
		jmp write_string_loop
	write_string_loop_end:

	ret

print_string: ; void print_string(u8* str, u64 len)
	mov rax, 1
	mov rdx, rsi
	mov rsi, rdi
	mov rdi, 1
	syscall

	ret

write_s64: ; u64 write_s64(u8* buf, u64 cap, s64 n)
	sub rsp, 20

	mov rax, rdx ; n
	xor r8, r8   ; required_len

	mov rcx, 1
	test rax, rax
	jns write_s64_positive
		mov rcx, -1
		inc r8
		neg rax
	write_s64_positive:

	xor r9, r9 ; i
	mov r10, 10
	write_s64_loop:
		
		xor rdx, rdx
		idiv r10

		add rdx, '0'
		mov BYTE [rsp + r9], dl

		inc r8
		inc r9

		test rax, rax
		jnz write_s64_loop

	cmp r8, rsi
	jle write_s64_write_number
		mov rax, rsi
		write_s64_write_error_text:
			mov BYTE [rdi + rsi], 'X'
			dec rsi
			jnz write_s64_write_error_text

	write_s64_write_number:
		mov rax, r8
		xor r10, r10
		test rcx, rcx
		jns write_s64_result_positive
			mov BYTE [rdi + r10], '-'
			inc r10
		write_s64_result_positive:

		write_s64_write_number_loop:
			dec r9
			test r9, r9
			js write_s64_write_number_loop_end

			movzx r8, BYTE [rsp + r9]
			mov BYTE [rdi + r10], r8b
			inc r10
			jmp write_s64_write_number_loop
		write_s64_write_number_loop_end:

	write_s64_write_number_end:

	add rsp, 20
	ret

print_s64: ; void print_s64(s64 n)
	sub rsp, 20

	mov rdx, rdi
	mov rdi, rsp
	mov rsi, 20
	call write_s64

	mov rdi, rsp
	mov rsi, rax
	call print_string

	add rsp, 20
	ret

print_results: ; void print_results(s64 part1_result, s64 part2_result)
	push r12
	push r13
	push r14
	push r15
	sub rsp, print_results_buffer_cap

	mov r12, rsp                      ; cursor
	mov r13, print_results_buffer_cap ; cap
	mov r14, rdi                      ; part1_results
	mov r15, rsi                      ; part2_results

	; write_string(STRING("Part 1 result: "))
	mov rdi, r12                              ; buf <- cursor
	mov rsi, r13                              ; cap <- cap
	mov rdx, print_results_results_1_text     ; str
	mov rcx, print_results_results_1_text_len ; len
	call write_string ; (buf, cap, str, len)
	add r12, rax
	sub r13, rax

	; write_s64(part1_result)
	mov rdi, r12 ; buf <- cursor
	mov rsi, r13 ; cap <- cap
	mov rdx, r14 ; n <- part1_results
	call write_s64 ; (buf, cap, n)
	add r12, rax
	sub r13, rax

	; write_string(STRING("\nPart 2 result: "))
	mov rdi, r12                              ; buf <- cursor
	mov rsi, r13                              ; cap <- cap
	mov rdx, print_results_results_2_text     ; str
	mov rcx, print_results_results_2_text_len ; len
	call write_string ; (buf, cap, str, len)
	add r12, rax
	sub r13, rax

	; write_s64(part2_result)
	mov rdi, r12 ; buf <- cursor
	mov rsi, r13 ; cap <- cap
	mov rdx, r15 ; n <- part2_results
	call write_s64 ; (buf, cap, n)
	add r12, rax
	sub r13, rax

	cmp r13, 0
	jle print_results_write_newline_end
	mov BYTE [r12], 0x0A
	add r12, 1
	sub r13, 1
	print_results_write_newline_end:

	mov rdi, rsp
	mov rsi, r12
	sub rsi, rsp
	call print_string

	add rsp, print_results_buffer_cap
	pop r12
	pop r13
	pop r14
	pop r15
	ret

section .data
print_results_results_1_text db "Part 1 results: "
print_results_results_1_text_len equ $ - print_results_results_1_text
print_results_results_2_text db 0x0A, "Part 2 results: "
print_results_results_2_text_len equ $ - print_results_results_2_text
print_results_buffer_cap equ (5*16)
%if print_results_buffer_cap < print_results_results_1_text_len + 1 + 19 + print_results_results_2_text_len + 1 + 19
%error "print_results_buffer_cap is too small"
%endif
