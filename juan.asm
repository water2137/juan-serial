;
; assemble with: nasm -f bin juan.asm -o juan.img
; run with qemu: qemu-system-x86_64 -fda juan.img
;
[org 0x7c00]

start:
;
; assemble with: nasm -f bin juan.asm -o juan.img
; run with qemu: qemu-system-x86_64 -fda juan.img
;
[org 0x7c00]

start:
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7c00

	call serial_init
	mov ah, 0x00
	mov al, 0x03
	call serial_print_ch

	mov si, welcome_msg
	call serial_print_str

main_loop:
	mov si, prompt
	call serial_print_str

	mov di, user_buffer
read_loop:
	call serial_getch

	cmp al, 0x0d
	mov byte [di], 0
	je execute_code

	cmp al, 0x08
	je handle_backspace

	mov ah, 0x0e
	call serial_print_ch

	stosb
	jmp read_loop

handle_backspace:
	cmp di, user_buffer
	jbe read_loop

	dec di
	mov byte [di], 0

	mov ah, 0x0e
	mov al, 0x08
	call serial_print_ch
	mov al, ' '
	call serial_print_ch
	mov al, 0x08
	call serial_print_ch
	jmp read_loop

execute_code:

	mov si, newline
	call serial_print_str

	mov si, user_buffer
	mov di, code_buffer

parse_loop:
	mov al, [si]
	cmp al, 0
	je done_parsing

	call hex_to_bin
	shl al, 4
	mov bl, al

	inc si
	mov al, [si]
	cmp al, 0
	je done_parsing

	call hex_to_bin
	add bl, al
	mov [di], bl

	inc si
	inc di
	jmp parse_loop

done_parsing:
	; mov si, exec_msg
	; call print_string

	call code_buffer

	jmp main_loop

hex_to_bin:
	cmp al, '9'
	jbe .is_digit
	cmp al, 'F'
		jbe .is_upper
		cmp al, 'f'
		jbe .is_lower
	jmp .done
.is_digit:
	sub al, '0'
		jmp .done
.is_upper:
	sub al, 'A' - 10
	jmp .done
.is_lower:
	sub al, 'a' - 10
.done:
	ret
serial_init:
	mov dx, 0x3FB
	mov al, 0x80
	out dx, al

	mov dx, 0x3F8
	mov al, 0x03
	out dx, al
	
	mov dx, 0x3F9
	mov al, 0x00
	out dx, al

	mov dx, 0x3FB
	mov al, 0x03
	out dx, al
	
	mov dx, 0x3FA
	mov al, 0xC7
	out dx, al

	mov dx, 0x3FC
	mov al, 0x0B
	out dx, al

	ret

serial_print_ch:
	push ax
	mov ah, al
.wait:
	mov dx, 0x3FD
	in al, dx
	test al, 0x20
	jz .wait

	mov al, ah
	mov dx, 0x3F8
	out dx, al
	pop ax
	ret

serial_print_str:
	lodsb
	or al, al
	jz .done
	
	push ax
	call serial_print_ch
	pop ax

	jmp serial_print_str
.done:
	ret
serial_getch:
.wait:
	mov dx, 0x3FD
	in al, dx
	test al, 1
	jz .wait
	
	mov dx, 0x3F8
	in al, dx
	ret

welcome_msg: db 'juan v0.1', 0x0d, 0x0a, 0
prompt: db 0x0d, 0x0a, '> ', 0
newline: db 0x0d, 0x0a, 0
; exec_msg:	db 'juanning', 0x0d, 0x0a, 0

user_buffer: resb 96
code_buffer: resb 96
times 510 - ($ - $$) db 0
dw 0xaa55
