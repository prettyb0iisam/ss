.intel_syntax noprefix
.global _start

.data
response: .ascii        "HTTP/1.0 200 OK\r\n\r\n"
response_len = . - response

active:	.ascii	"Server in ascolto sulla porta 8080...\n"
active_len= . - active

fail:	.ascii	"HTTP/1.0 404 Not Found\r\n\r\n"
fail_len = . - fail

CR:	.ascii	"\r"
CR_len = . - CR

CRLF:	.ascii	"\n\r\n"
CRLF_len = . - CRLF


GET: .ascii	"G"
GET_len = . - GET

space: .ascii	" "

content:        .skip   250000

.text
_start:

#SOCKET
mov rax, 41
mov rdi, 2
mov rsi, 1
mov rdx, 0
syscall
mov r8, rax

#BIND
mov rax, 49
mov rdi, r8
push rbp
mov rbp, rsp
sub rsp, 16
mov si, 2
mov [rsp], si
mov si, 0x901f
mov [rsp+2], si
mov esi, 0
mov [rsp+4], esi
mov [rsp+8], rsi
mov rsi, rsp
mov rdx, 16
syscall

#LISTEN
mov rax, 50
mov rdi, r8
mov rsi, 5
syscall

#WRITE
mov rax, 1
mov rdi, 1
lea rsi, active
mov rdx, active_len
syscall

loop:
#ACCEPT
mov rax, 43
mov rdi, r8
mov rsi, 0
mov rdx, 0
syscall
mov r9, rax

#FORK
mov rax, 57
syscall

#PARENT OR CHILD?
cmp rax, 0
je CHILD
jmp PARENT

PARENT:
#CLOSE
mov rax, 3
mov rdi, r9
syscall
jmp loop

CHILD:
#CLOSE
mov rax, 3
mov rdi, r8
syscall

#READ
mov rax, 0
mov rdi, r9
lea rsi, content
mov rdx, 1024
syscall
mov r13, rax

#POST o GET?
lea rax, GET
lea rbx, content
mov al, [rax]
mov bl, [rbx]
cmp al, bl
je GET_REQUEST
jmp POST_REQUEST


POST_REQUEST:
#parsing
#OPEN
lea rax, space
mov al, [rax]
lea rbx, content
trova_inizio:
mov cl, [rbx]
cmp al, cl
je parsa
inc rbx
jmp trova_inizio

parsa:
inc rbx
push rbx
trova_fine:
mov cl, [rbx]
cmp al, cl
je trovato
inc rbx
jmp trova_fine

trovato:
mov rcx, 0
mov [rbx], cl
mov rax, 2
pop rdi
mov r14, rdi
mov rsi, 65
mov rdx, 511
syscall
mov r10, rax

#200 or 404?
test rax, rax
js not_found

#WRITE
xor rsi, rsi
lea rbx, content
parsa_cr:
lea rax, CR
mov al, [rax]
mov cl, [rbx]
cmp al, cl
je possibile_inizio
inc rbx
inc rsi
jmp parsa_cr

possibile_inizio:
inc rbx
inc rsi
continua:
lea rax, CRLF
mov dl, [rax]
mov cl, [rbx]
cmp cl, dl
jne parsa_cr
inc rbx
inc rax
inc rsi
mov cl, [rbx]
mov dl, [rax]
cmp cl, dl
jne parsa_cr
inc rbx
inc rax
inc rsi
mov cl, [rbx]
mov dl, [rax]
cmp dl, cl
jne parsa_cr
inc rbx
sub r13, rsi
mov rdx, r13
mov rsi, rbx
mov rdi, r10
mov rax, 1
syscall

#CLOSE
mov rax, 3
mov rdi, r10
syscall

#WRITE
mov rax, 1
mov rdi, r9
lea rsi, response
mov rdx, response_len
syscall
jmp done








GET_REQUEST:
#parsing
#OPEN
lea rax, space
mov al, [rax]
lea rbx, content
trova_inizioo:
mov cl, [rbx]
cmp al, cl
je parsaa
inc rbx
jmp trova_inizioo

parsaa:
inc rbx
push rbx
trova_finee:
mov cl, [rbx]
cmp al, cl
je trovatoo
inc rbx
jmp trova_finee

trovatoo:
mov rcx, 0
mov [rbx], cl
mov rax, 2
pop rdi
mov r14, rdi
mov rsi, 0
mov rdx, 0
syscall 
mov r10, rax

#200 or 404?
test rax, rax
js not_found

#READ
mov rax, 0
mov rsi, rdi
mov rdi, r10
mov rdx, 250000
syscall
dec rax
mov r12, rax

#CLOSE
mov rax, 3
mov rdi, r10
syscall

#WRITE
mov rax, 1
mov rdi, r9
lea rsi, response
mov rdx, response_len
syscall

#WRITE
mov rax, 1
mov rdi, r9
mov rsi, r14
mov rdx, r12
syscall
jmp done

not_found:
#WRITE
mov rax, 1
mov rdi, r9
lea rsi, fail
mov rdx, fail_len
syscall

done:
#CLOSE
mov rax, 3
mov rdi, r9
syscall

#EXIT
mov rax, 60
mov rdi, 0
syscall
