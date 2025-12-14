section .text

strlen: ; u64 strlen(u8* str)
	xor rax, rax
	
	test rdi, rdi
	jz strlen_end

	strlen_loop:
		cmp BYTE [rdi + rax], 0
		je strlen_end
		inc rax
		jmp strlen_loop
	
	strlen_end:
	ret

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

section .text

read_input: ; void read_input(u8* rsp, u8** input, u64* input_len)
	push r12
	push r13
	push r14

	sub rsp, 0x10
	mov QWORD [rsp + 0], rsi
	mov QWORD [rsp + 8], rdx

	mov r12, rdi

	mov r13d, DWORD [r12]
	cmp r13, 2
	je read_input_correct_num_args
		mov rdi, read_input_invalid_num_args_prefix
		mov rsi, read_input_invalid_num_args_prefix_len
		call print_string

		mov r13, QWORD [r12 + 8]
		mov rdi, r13
		call strlen

		mov rdi, r13
		mov rsi, rax
		call print_string

		mov rdi, read_input_invalid_num_args_suffix
		mov rsi, read_input_invalid_num_args_suffix_len
		call print_string

		mov rax, 60 ; sys_exit
		mov rdi, 1  ; error code
		syscall
	read_input_correct_num_args:

	mov r12, QWORD [r12 + 16]

	mov rax, 2   ; sys_open
	mov rdi, r12 ; path
	mov rsi, 0   ; 1 O_RDONLY
	mov rdx, 0   ; no flags
	syscall

	test rax, rax
	jns read_input_opened_file
		mov rdi, read_input_failed_to_open_file_prefix
		mov rsi, read_input_failed_to_open_file_prefix_len
		call print_string

		mov rdi, r12
		call strlen

		mov rdi, r12
		mov rsi, rax
		call print_string

		mov rdi, read_input_failed_to_open_file_suffix
		mov rsi, read_input_failed_to_open_file_suffix_len
		call print_string

		mov rax, 60 ; sys_exit
		mov rdi, 1  ; error code
		syscall
	read_input_opened_file:

	mov r12, rax

	sub rsp, 0x100
	mov rax, 5   ; sys_fstat
	mov rdi, r12 ; fd
	mov rsi, rsp ; sglkdhjfglkj
	syscall
	mov r13, QWORD [rsp + 48]
	add rsp, 0x100

	mov r8, r13
	add r8, 4095
	and r8, -4096
	mov rax, 9  ; sys_mmap
	mov rdi, 0
	mov rsi, r8 ; size
	mov rdx, 3  ; PROT_READ | PROT_WRITE
	mov r10, 0x22  ; MAP_ANONYMOUS | MAP_PRIVATE
	mov r8, -1
	mov r9, 0
	syscall

	cmp rax, -1
	jne read_input_map_succeeded
		 ; TODO error message

		mov rax, 60 ; sys_exit
		mov rdi, 1  ; error code
		syscall
	read_input_map_succeeded:

	mov r14, rax

	mov rax, 0   ; sys_read
	mov rdi, r12 ; fd
	mov rsi, r14 ; buf
	mov rdx, r13 ; len
	syscall

	cmp rax, -1
	jne read_input_read_succeeded
		 ; TODO error message

		mov rax, 60 ; sys_exit
		mov rdi, 1  ; error code
		syscall
	read_input_read_succeeded:

	mov r8, QWORD [rsp + 0]
	mov r9, QWORD [rsp + 8]

	mov QWORD [r8], r14
	mov QWORD [r9], r13

	mov rax, 3   ; sys_close
	mov rdi, r12 ; fd
	syscall

	add rsp, 0x10
	pop r12
	pop r13
	pop r14
	ret

section .data
read_input_invalid_num_args_prefix db "Invalid number of arguments. Expected: "
read_input_invalid_num_args_prefix_len equ $ - read_input_invalid_num_args_prefix
read_input_invalid_num_args_suffix db " [input file]", 0x0A
read_input_invalid_num_args_suffix_len equ $ - read_input_invalid_num_args_suffix
read_input_failed_to_open_file_prefix db "Failed to open file '"
read_input_failed_to_open_file_prefix_len equ $ - read_input_failed_to_open_file_prefix
read_input_failed_to_open_file_suffix db "'", 0x0A
read_input_failed_to_open_file_suffix_len equ $ - read_input_failed_to_open_file_suffix

section .text

eat_whitespace: ; u64 eat_whitespace(u8* input, u64 len)
	xor rax, rax

	eat_whitespace_loop:
		cmp rax, rsi
		jge eat_whitespace_loop_end
		movzx r8, BYTE [rdi + rax]

		dec r8
		cmp r8, 0x20
		jae eat_whitespace_loop_end

		inc rax
		jmp eat_whitespace_loop
	eat_whitespace_loop_end:

	ret

eat_s64: ; struct { u64 advancement; s64 num } eat_s64(u8* input, u64 len)
	xor rax, rax
	xor rdx, rdx

	eat_s64_loop:
		cmp rax, rsi
		jge eat_s64_loop_end

		movzx r8, BYTE [rdi + rax]

		sub r8, '0'
		cmp r8, 10
		jae eat_s64_loop_end

		imul rdx, rdx, 10
		add rdx, r8

		inc rax
		jmp eat_s64_loop
	eat_s64_loop_end:

	ret
