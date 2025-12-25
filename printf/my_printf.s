# we will use "write syscall", instead of printf: write syscall is the way
# user programs ask the Linux kernel (manages resources and acts as the bridge between software and hardware) 
# to output bytes to the terminal screen, directly asking the kernel to print our string without any intermediary libraries.
write_syscall:
    movq  %rsi, %rdx            # length of the string that needs to be printed
    movq  %rdi, %rsi            # in %rdi we have the start address of the string, it needs to be moved into %rsi
    movq  $1, %rdi              # where to write: we do movq $1, because we want to print the output to the terminal screen
    movq  $1, %rax              # syscall number for write: 1
    syscall
    ret

# this will help us output a null-terminated string to the terminal screen.
print_string:

    # push callee-saved register
    pushq  %rbx

    movq  %rdi, %rbx        # so, in %rbx we will have the first address of the string
    movq  %rdi, %rax        # copy 

length:
    movb  (%rax), %cl       # we use movb, so we can load the last 8 bits = 1 byte in %rcx
    cmpb  $0, %cl           # compare with zero to see if we reached the null-terminator
    je    length_done       # if so, we are done
    incq   %rax             # move to the next byte
    jmp   length            # continue the loop

length_done:
    subq  %rbx, %rax        # rax = length = current pointer(%rax) - start pointer(%rbx)

    movq  %rbx, %rdi        # rdi = pointer to string (first argument to write_syscall)
    movq  %rax, %rsi        # rsi = length of string (second argument)

    call  write_syscall     # call your syscall subroutine to print string

    # pop callee-saved register
    popq  %rbx 
    ret

my_printf:

    # prologue
    pushq  %rbp
    movq   %rsp, %rbp

    # saving argument registers to the stack for easier access
    # argument = what needs to be printed when encountering %d, %s, %u or %%
    pushq  %rdi  # format string
    pushq  %rsi  # argument 0
    pushq  %rdx  # argument 1
    pushq  %rcx  # argument 2
    pushq  %r8   # argument 3
    pushq  %r9   # argument 4

    movq   $0, %rcx        # argument index = 0
    movq   %rdi, %rsi      # %rsi becomes the pointer to the format string

parse:
    movzbq  (%rsi), %rax    # we load one byte at %rsi into %rax such that, the last 8 bits are the byte from %rsi, and the rest are 0
    cmpb  $0, %al           # we check if we went through all the characters
    je  end_parse           # if we reached the null terminator, end

    cmpb  $'%', %al       
    jne  print_char       # if we do NOT encounter %, then we just print the character
    # handle the cases
    incq  %rsi            # move pointer to specifier char, meaning the next char (d, u, s, %) 
    movzbq  (%rsi), %rax

    cmpb  $'d', %al
    je  handle_d

    cmpb  $'u', %al
    je  handle_u

    cmpb  $'s', %al
    je  handle_s

    cmpb  $'%', %al
    je  handle_percent

    # if we reached this line, then we have an unknown specifier, such as %r, %y
    # in this case, we print % and then the specifier
    # print '%'
    movb $'%', %al
    call print_one_char

    # print the unknown specifier character at %rsi
    movb (%rsi), %al
    call print_one_char

    incq %rsi                # advance format string pointer
    jmp parse

print_one_char:
    subq $24, %rsp         # allocate stack space, we do this, so the value at which %rsp originally pointed won't be overwritten
                           # plus stack alignment 
    movb %al, (%rsp)       # store char
    movb $0, 1(%rsp)       # null-terminator
    movq %rsp, %rdi        # in %rdi we will have the string we need to print: char + null-terminator, for print_string
    pushq %rsi
    pushq %rcx

    call print_string      # print the single-char string
    popq %rcx
    popq %rsi
    addq $24, %rsp         # deallocate
    ret

print_char:
    movb  (%rsi), %al     # load character at current pointer
    call  print_one_char  # print the character
    incq  %rsi            # advance pointer
    jmp  parse

# %rcx = argument index

handle_argument:
    cmpq $0, %rcx
    je arg_0

    cmpq $1, %rcx
    je arg_1

    cmpq $2, %rcx
    je arg_2

    cmpq $3, %rcx
    je arg_3

    cmpq $4, %rcx
    je arg_4

    # beyond 5, get from the stack: 7th argument onwards ( first argument %rdi = format, the next 5 are saved in registers, that is why we say
    # from 7th argument onwards)
    # calculate offset: 16 + 8 * (%rcx - 5)
    movq %rcx, %rax
    subq $5, %rax                    # (rcx - 5)
    imulq $8, %rax, %rax             # *8
    addq $16, %rax                   # offset from %rbp, because in (%rbp) we have previous %rbp, at 8(%rbp) the ret address, then the arguments
    movq (%rbp,%rax), %rax           # we do memory at address %rbp plus %rax into %rax
    jmp use_arg

arg_0: 
    movq -16(%rbp), %rax
    jmp use_arg    

arg_1:
    movq -24(%rbp), %rax
    jmp use_arg

arg_2:
    movq -32(%rbp), %rax
    jmp use_arg

arg_3: 
    movq -40(%rbp), %rax
    jmp use_arg

arg_4: 
    movq -48(%rbp), %rax
    jmp use_arg

use_arg:
    ret


# signed integer in decimal
handle_d:
    subq $64, %rsp              # allocate space on stack
    movq %rsp, %rdx             # where the value will be -> %rdx
    pushq %rsi
    pushq %rcx

    call handle_argument        # get argument in %rax (unsigned int)

    movq %rax, %rsi             # move value to %rsi (for conversion function)
    call signed_int_to_str      # convert signed int to string, returned pointer in %rax

    movq %rax, %rdi             # string pointer in %rdi
    call print_string           # print string

    popq %rcx
    popq %rsi
    addq $64, %rsp              # deallocate the space
    incq %rcx                   # argument index++
    incq %rsi                   # advance format string pointer
    jmp parse

# unsigned integer in decimal
handle_u:
    subq $32, %rsp              # allocate space on stack
    movq %rsp, %rdx             # where the value will be -> %rdx
    pushq %rsi
    pushq %rcx

    call handle_argument        # get argument in rax (unsigned int)

    movq %rax, %rsi             # move value to rsi (for conversion function)
    call unsigned_int_to_str    # convert unsigned int to string; returned pointer in rax

    movq %rax, %rdi             # string pointer in rdi
    call print_string           # print string

    popq %rcx
    popq %rsi
    addq $32, %rsp              # deallocate the space
    incq %rcx                   # argument index++
    incq %rsi                   # advance format string pointer
    jmp parse


# null-terminator string
handle_s:
    call handle_argument    # fetch argument into %rax (pointer to string)
                            # %rax points to a null-terminated string
    pushq %rsi
    pushq %rcx

    movq %rax, %rdi         # String pointer first argument to print_string
    call print_string       # Print the string

    popq %rcx
    popq %rsi

    incq %rcx
    incq %rsi
    jmp parse

# print only once %
handle_percent:
    movb $'%', %al
    pushq %rsi
    pushq %rcx
    call print_one_char     # print single '%'
    popq %rcx
    popq %rsi
    incq %rsi
    jmp parse

# this routine writes the decimal number as ASCII characters into memory and returns the pointer to that string, ready for printing
unsigned_int_to_str:
    movq %rdx, %rax           # save start address of the memory block for return
    movq %rdx, %rcx           # %rcx points to end of memory block
    addq $31, %rcx            # move %rcx to the last byte reserved
    movb $0, (%rcx)           # write null terminator at last byte
                              # we saved 32 bits, each bit will be a digit
    decq %rcx                 # move one byte backward for digit writing

    cmpq $0, %rsi             # check if the number is zero
    jne convert_loop          # if not zero, proceed to conversion

    # handle zero as a special case:
    movb $'0', (%rcx)         # write character '0' at current position
    movq %rcx, %rax           # return pointer to string start
    ret                       # done

convert_loop:
    movq %rsi, %rax           # move number into %rax for division
    movq $0, %rdx             # clear %rdx for division

    movq $10, %r10            # divisor 10

div_loop:
    divq %r10                 # divide rdx:rax by 10, quotient in rax, remainder in rdx
    addb $'0', %dl            # convert remainder to ASCII digit
    movb %dl, (%rcx)          # store digit at current memory position
    decq %rcx                 # move backwards one byte

    movq %rax, %rsi           # update number to quotient

    cmpq $0, %rsi             # check if quotient is zero
    jne div_loop              # continue if number not zero

    incq %rcx                 # adjust pointer to first digit

    movq %rcx, %rax           # return pointer in %rax to start of string
    ret

# input:  %rsi = signed 64-bit value
#         %rdx = start address of writable space (32 bytes)
# output: %rax = address of first char of null-terminated decimal text

signed_int_to_str:
    movq %rdx, %rax            # remember original start (used if '-' written)
    movl $0, %r8d              # r8d = 0 => no sign

    cmpq $0, %rsi
    jge  positive

    negq %rsi                  # make positive
    //movb $'-', (%rdx)          # write '-' 
    //incq %rdx                  # digits will follow the sign
    movl $1, %r8d              # mark had_sign = 1

positive:
    movq %rdx, %rcx            # rcx = write cursor (we build right-to-left)
    addq $31, %rcx            
    movb $0,  (%rcx)
    decq %rcx

    # zero special-case
    cmpq $0, %rsi
    jne  .digits
    movb $'0', (%rcx)
    movq %rcx, %rax
    ret

.digits:
    movq $10, %r10

.div_loop:
    movq %rsi, %rax             # dividend in rax
    movq $0,   %rdx             # high half for unsigned div
    divq %r10                   # rdx:rax / 10 -> q=rax, r=rdx(remainder)
    addb $'0', %dl
    movb %dl,  (%rcx)
    decq %rcx
    movq %rax, %rsi
    cmpq $0,   %rsi
    jne  .div_loop

    incq  %rcx                 # %rcx now points at first digit
    cmpq $0, %r8               # was negative?
    jz no_sign                 # if not, return first-digit pointer

    decq  %rcx                 # make room for '-'
    movb  $'-', (%rcx)         # write sign byte
    movq  %rcx, %rax           # return pointer to '-', into %rax
    ret

no_sign:
    movq  %rcx, %rax           # return pointer to first digit
    ret

end_parse:
    # cleanup and return
    popq  %r9
    popq  %r8
    popq  %rcx
    popq  %rdx
    popq  %rsi
    popq  %rdi
    leave
    ret

    .global main
main:
    # Prologue
    pushq   %rbp
    movq    %rsp, %rbp

    subq    $8, %rsp                                

    # Set up my_printf(format, arg1, arg2)
    leaq    msg(%rip), %rdi                         # 1st arg: format string in RDI 
    leaq    name(%rip), %rsi                        # 2nd arg: %s pointer in RSI 
    movl    $42, %edx                               # 3rd arg: %u value in edx
    call    my_printf                               # caller ensures 16B alignment before call 

    addq    $8, %rsp                          

    movq  $60, %rax                                 # sys_exit number
    movq  $0, %rdi                          
    syscall                                        

    # epilogue
    leave
    ret

    .section .data
msg:
    .asciz "My name is %s. I think I'll get a %u for my exam. What does %r do? And %%?"
name:
    .asciz "Teo"

    .section .text

