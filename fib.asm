; Trabalho Avaliativo Linguagens de Montagens
; Calcula o n-ésimo número de fibonacci e guarda em arquivo
; Paulo Roberto Scalon
;
; nasm -f elf64 fib.asm ; ld fib.o -o fib.x

%define maxChars 3

section .data
	strOla : db "Atencao, digite no maximo DOIS digitos!", 10, "Entre com o n-esimo termo de fibonacci: "
	strOlaL: equ $ - strOla

	strErr : db "Foi encontrado um erro, encerrando!...", 10
	strErrL : equ $ - strErr

    strFile : db "fib(00).bin", 0
    strFileL : equ $ - strFile

section .bss
	entrada : resb 3		; 3 bytes para entrada do fib(n) (2 digitos + /n)
	resultado : resq 1	
	strFibFile: resb 2
	fileHandle : resd 1

section .text
	global _start

_start:
	mov rax, 1 ; WRITE
  	mov rdi, 1
	lea rsi, [strOla]
	mov edx, strOlaL
	syscall

	mov rax, 0 ; READ
  	mov rdi, 1
	lea rsi, [entrada]
	mov edx, maxChars
	syscall

	xor ecx, ecx ; limpa ecx para receber a soma da entrada do teclado (linha..)

	cmp eax, 1
	je err
	cmp eax, 2
	je converte1
	cmp byte [entrada + eax - 1], 10 ; se for digitado mais que 2 digitos, limpa buffer do teclado!
	jne limpaBuffer
	jmp converte2
	
limpaBuffer:
    mov rax, 0  ; READ
    mov rdi, 1
    lea rsi, [entrada]
    mov edx, 1
    syscall
    
    cmp byte [entrada], 10
    jne limpaBuffer
	jmp err

converte1: ; caso for digitado apenas 1 digito
	mov cl, [entrada]

	mov [strFibFile+1], cl	; aproveita bloco para preparar o nome do arquivo
	mov byte [strFibFile], 0x30 ; adiciona '0' em ASCII na posicao da dezena

	AND cl, 0x0F ; remove a parte alta do numero, símbolo em número
	jmp convertido

converte2:
	mov bl, [entrada] ; bl está com a dezena
	mov cl, [entrada+1] ; cl está com a unidade

	mov [strFibFile+1], cl ; aproveita bloco para preparar o nome do arquivo
	mov byte [strFibFile], bl

	AND bl, 0x0F
	AND cl, 0x0F
	xor eax, eax
	mov eax, 10  ; multiplicador para dezena
	mul bl
	add ecx, eax ; soma dezena com a unidade

	cmp ecx, 93 ; fib(>=93) estoura a representação de 64 bits 
	jge err
	
convertido:
	cmp ecx, 1 ; se numero digitado for menor que 1, move o numero para a resposta
	mov [resultado], rcx 
	jle posFib

	mov r15, rcx ; indice do "for"
	mov r13, 1 ; base do cálculo

fib:
	; r14 = f(x), r13 = f(x-1) e r12 = f(x-2)
	mov r14, r13
    add r14, r12
    
    mov r12, r13
    mov r13, r14
    
    dec r15
    cmp r15, 1
    jne fib

	mov [resultado], r14

posFib:
	mov ax, [strFibFile] 
	mov [strFile+4], ax	;copia numero (ASCII) da entrada para o nome do aquivo a ser gerado

	mov rax, 2 ; abre arquivo
    lea rdi, [strFile]
    mov esi, 101o ; 100(create) + 1(o_write)
    mov edx, 644o
    syscall
	mov [fileHandle], eax

	mov rax, 1	; write arquivo
	mov edi, [fileHandle]
	lea rsi, [resultado]
	mov edx, 8
	syscall

	mov rax, 3	; fechar arquivo
    mov edi, [fileHandle]
    syscall

	jmp fim
err:
	mov rax, 1 ;WRITE
  	mov rdi, 1
	lea rsi, [strErr]
	mov edx, strErrL
	syscall

fim:
	mov rax, 60
	mov rdi, 0
	syscall
