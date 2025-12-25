# helper methods


# we will use "write syscall", instead of printf: write syscall is the way
# user programs ask the Linux kernel (manages resources and acts as the bridge between software and hardware) 
# to output bytes to the terminal screen, directly asking the kernel to print our string without any intermediary libraries.
write_syscall:
    movq  %rsi, %rdx            # length of the string that needs to be printed
    movq  %rdi, %rsi            # in %rdi we have the start address of the string, it needs to be moved into %rsi
    movq  $1, %rdi              # where to write: fd=1 (stdout)
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
    movb  (%rax), %cl       # load 1 byte
    cmpb  $0, %cl           # reached null terminator?
    je    length_done
    incq  %rax
    jmp   length

length_done:
    subq  %rbx, %rax        # rax = length = current - start

    movq  %rbx, %rdi        # rdi = pointer to string
    movq  %rax, %rsi        # rsi = length

    call  write_syscall

    # pop callee-saved register
    popq  %rbx 
    ret

# this routine writes the decimal number as ASCII characters into memory and returns the pointer to that string, ready for printing
unsigned_int_to_str:
    movq %rdx, %rax           # save start address of the memory block for return
    movq %rdx, %rcx           # %rcx points to end of memory block
    addq $31, %rcx            # move %rcx to the last byte reserved
    movb $0, (%rcx)           # write null terminator at last byte
    decq %rcx                 # move one byte backward for digit writing

    cmpq $0, %rsi             # check if the number is zero
    jne convert_loop          # if not zero, proceed to conversion

    # handle zero as a special case:
    movb $'0', (%rcx)         # write character '0'
    movq %rcx, %rax           # return pointer
    ret

convert_loop:
    movq %rsi, %rax           # dividend in rax
    movq $0, %rdx             # high half = 0
    movq $10, %r10            # divisor 10

div_loop:
    divq %r10                 # rdx:rax / 10 -> q=rax, r=rdx
    addb $'0', %dl            # remainder to ASCII
    movb %dl, (%rcx)          # store digit
    decq %rcx

    movq %rax, %rsi           # update number to quotient
    cmpq $0, %rsi
    jne  div_loop

    incq %rcx                 # adjust pointer to first digit
    movq %rcx, %rax           # return pointer
    ret

# input:  %rsi = signed 64-bit value
#         %rdx = start address of writable space (32 bytes)
# output: %rax = address of first char of null-terminated decimal text
signed_int_to_str:
    movq %rdx, %rax           # remember original start
    movl $0, %r8d             # r8d = 0 => no sign

    cmpq $0, %rsi
    jge  positive

    negq %rsi                 # make positive
    movl $1, %r8d             # had_sign = 1

positive:
    movq %rdx, %rcx
    addq $31, %rcx
    movb $0, (%rcx)
    decq %rcx

    cmpq $0, %rsi
    jne  .digits
    movb $'0', (%rcx)
    movq %rcx, %rax
    ret

.digits:
    movq $10, %r10

.div_loop:
    movq %rsi, %rax
    movq $0, %rdx
    divq %r10                 # rdx:rax / 10
    addb $'0', %dl
    movb %dl, (%rcx)
    decq %rcx
    movq %rax, %rsi
    cmpq $0, %rsi
    jne  .div_loop

    incq %rcx                 # first digit
    cmpq $0, %r8
    jz   no_sign

    decq %rcx
    movb $'-', (%rcx)
    movq %rcx, %rax
    ret

no_sign:
    movq %rcx, %rax
    ret

# %rdi = pointer (to any position in the input line)
# returns %rax = pointer to first non-space/non-tab (or 0 terminator)
skip_spaces:
    movq %rdi, %rax
skip_loop:
    movzbq (%rax), %rcx
    cmpb $0, %cl
    je   done
    cmpb $' ', %cl
    je   next
    cmpb $'\t', %cl
    jne  done
next:
    incq %rax
    jmp  skip_loop
done:
    ret

# %rdi = pointer at first non-space
# this routine will return:
#   %rax = start of word
#   %rdx = length of word
#   %rsi = pointer just after the word
read_word:
    movq %rdi, %rax           # start
    movq %rdi, %rsi
    movq $0, %rdx             # length
.rw_loop:
    movzbq (%rsi), %rcx
    cmpb $0,  %cl
    je   .rw_done
    cmpb $' ', %cl
    je   .rw_done
    cmpb $'\n', %cl
    je   .rw_done
    cmpb $'\r', %cl
    je   .rw_done
    cmpb $'\t', %cl
    je   .rw_done
    incq %rsi
    incq %rdx
    jmp  .rw_loop
.rw_done:
    ret

# %rdi = pointer to word start
# %rsi = length of word
# %rdx = pointer to null-terminated literal ("help", "quit", etc.)
# returns: %eax = 1 if equal, 0 otherwise
cmp_cmd:
    movq $0, %rax
    movq $0, %rcx
.cc_loop:
    cmpq %rsi, %rcx
    je   .check_literal_end
    movzbq (%rdi,%rcx,1), %r8
    movzbq (%rdx,%rcx,1), %r9
    cmpb %r8b, %r9b
    jne  .done
    incq %rcx
    jmp  .cc_loop
.check_literal_end:
    movzbq (%rdx,%rcx,1), %r8
    cmpb $0, %r8b
    jne  .done
    movq $1, %rax
.done:
    ret

# atoi_signed:
#  input:  %rdi = pointer to word (optional leading '-')
#          %rsi = length of word
#  output: %rax = signed 64-bit value
atoi_signed:
    cmpq $0, %rsi
    je   .as_zero       

    movzbq (%rdi), %rcx 
    cmpb $'-', %cl
    je   .as_negative

    # if positive, just use the normal unsigned converter
    call atoi_unsigned
    ret

.as_negative:
    incq %rdi           # skip the '-' char
    decq %rsi           # length is 1 shorter
    
    pushq $-1           # remember we need to negate later
    call atoi_unsigned  # convert the digits 
    popq %rdx           
    
    imulq %rdx, %rax    # Result * -1
    ret

.as_zero:
    movq $0, %rax
    ret
    

# atoi_unsigned:
#  input:  %rdi = pointer to word (digits only, no sign)
#          %rsi = length of word
#  output: %rax = unsigned 64-bit value
atoi_unsigned:
    movq $0, %rax           # value
    movq $0, %rcx           # i

.u_loop:
    cmpq %rsi, %rcx
    je   .u_done

    movzbq (%rdi,%rcx,1), %rdx

    cmpb  $'0', %dl
    jb    .u_done
    cmpb  $'9', %dl
    ja    .u_done

    subb  $'0', %dl         # digit

    imulq $10, %rax
    addq  %rdx, %rax

    incq  %rcx
    jmp   .u_loop

.u_done:
    ret

# used for uninitialized globals
.section .bss
input_buf:
    .skip 256               # buffer for user input line
num_buf:
    .skip 64                # for unsigned_int_to_str

# read-only data section, for the string literals (null terminated strings)
.section .rodata
prompt:
    .asciz "shell> "
cmd_help:
    .asciz "help"
cmd_quit:
    .asciz "quit"
cmd_add:
    .asciz "add"
msg_unknown:
    .asciz "unknown command\n"
msg_help:
    .asciz "available: help, quit, add, mul\n"
newline:
    .asciz "\n"
cmd_mul:
    .asciz "mul"
msg_overflow:
    .asciz "error: result too big\n" 
cmd_div:
    .asciz "div"
msg_div_zero:
    .asciz "error: division by zero\n"       

.global _start
.section .text

_start:
    pushq %rbx              # save caller-saved copy for whole shell
.loop:
    # print prompt
    leaq prompt(%rip), %rdi
    call print_string

    # read a line: read(0, input_buf, 255)
    movq $0, %rdi
    leaq input_buf(%rip), %rsi
    movq $255, %rdx
    movq $0, %rax
    syscall

    cmpq $0, %rax
    jle  .exit

    # null-terminate
    leaq input_buf(%rip), %rdi
    movq %rax, %rcx
    movb $0, (%rdi,%rcx,1)

    # skip leading spaces/tabs
    leaq input_buf(%rip), %rdi
    call skip_spaces

    movq %rax, %rdi
    cmpb $0, (%rdi)
    je   .loop

    # read first word
    call read_word           # rax=start, rdx=len, rsi=after_word
    movq %rsi, %rbx         # rbx = after command
    movq %rax, %rdi          # word start
    movq %rdx, %rsi          # word length

    # help?
    leaq cmd_help(%rip), %rdx
    call cmp_cmd
    cmpq $1, %rax
    je   .do_help

    # quit?
    leaq cmd_quit(%rip), %rdx
    call cmp_cmd
    cmpq $1, %rax
    je   .do_quit

    # add?
    leaq cmd_add(%rip), %rdx
    call cmp_cmd
    cmpq $1, %rax
    je   .do_add

    # mul?
    leaq cmd_mul(%rip), %rdx
    call cmp_cmd
    cmpq $1, %rax
    je   .do_mul

     # div?
    leaq cmd_div(%rip), %rdx
    call cmp_cmd
    cmpq $1, %rax
    je   .do_div


    # unknown
    leaq msg_unknown(%rip), %rdi
    call print_string
    jmp  .loop

.do_help:
    leaq msg_help(%rip), %rdi
    call print_string
    jmp  .loop

.do_quit:
    jmp  .exit
.do_add:
    # 1. parse first number
    movq %rbx, %rdi         # %rbx points to text after "add"
    call skip_spaces        # skip whitespace to find 1st arg
    
    movq %rax, %rdi         # checking if we hit end of line (no args)
    cmpb $0, (%rdi)
    je   .add_error         # if empty, skip 

    call read_word          # returns: %rax = start, %rdx = len, %rsi = next
    movq %rsi, %rbx         # %rbx to point after this word
    
    # convert 1st string to int (handles signs)
    movq %rax, %rdi         # word start
    movq %rdx, %rsi         # word length
    call atoi_signed        # returns value in %rax  <--- CHANGED
    pushq %rax              # 1st number on stack

    # 2. parse seconf number
    movq %rbx, %rdi         # start from where we left off
    call skip_spaces
    
    movq %rax, %rdi         # check if 2nd arg exists
    cmpb $0, (%rdi)
    je   .add_error_pop     # if missing, clean stack and exit

    call read_word          # returns: %rax = start, %rdx = len
    
    # convert 2nd string to int (handles signs)
    movq %rax, %rdi
    movq %rdx, %rsi
    call atoi_signed        # returns value in %rax
    
    # 3. perform addition
    popq %rcx               # RESTORE 1st number into %rcx
    addq %rcx, %rax         # %rax = 2nd_val + 1st_val

    # 4. print result
    movq %rax, %rsi          # value to convert
    leaq num_buf(%rip), %rdx # buffer (defined in .bss)
    call signed_int_to_str   # returns ptr to string in %rax 

    movq %rax, %rdi         # string to print
    call print_string
    
    leaq newline(%rip), %rdi # print newline
    call print_string

    jmp .loop               # return to shell prompt

.add_error_pop:
    popq %rax               # clean up stack (remove saved 1st number)
.add_error:
    jmp .loop

.do_mul:
    # 1. Parse first number
    movq %rbx, %rdi         # %rbx points to text after "mul"
    call skip_spaces        # skip whitespace to find 1st arg
    
    movq %rax, %rdi         # check if we hit end of line (no args)
    cmpb $0, (%rdi)
    je   .mul_error         # if empty, skip

    call read_word          # returns: %rax = start, %rdx = len, %rsi = next
    movq %rsi, %rbx         # update %rbx to point after this word
    
    # convert 1st string to int
    movq %rax, %rdi         # word start
    movq %rdx, %rsi         # word length
    call atoi_signed        # returns value in %rax
    pushq %rax              # save 1st number on stack

    # 2. Parse second number
    movq %rbx, %rdi         # start from where we left off
    call skip_spaces
    
    movq %rax, %rdi         # check if 2nd arg exists
    cmpb $0, (%rdi)
    je   .mul_error_pop     # if missing, clean stack and exit

    call read_word          # returns: %rax = start, %rdx = len
    
    # convert 2nd string to int
    movq %rax, %rdi
    movq %rdx, %rsi
    call atoi_signed        # 2nd number is now in %rax

    # 3. Perform Multiplication
    popq %rcx               # restore 1st number into %rcx
    imulq %rcx, %rax        # %rax = %rax * %rcx (signed multiplication)

    # 4. Check for Overflow
    jo   .mul_overflow      # Jump if Overflow Flag (OF) is set

    # 5. Print Result 
    movq %rax, %rsi         # value to convert
    leaq num_buf(%rip), %rdx
    call signed_int_to_str  # returns ptr to string in %rax

    movq %rax, %rdi         # string to print
    call print_string
    
    leaq newline(%rip), %rdi
    call print_string

    jmp .loop               # return to shell prompt

.mul_overflow:
    leaq msg_overflow(%rip), %rdi
    call print_string
    jmp .loop

.mul_error_pop:
    popq %rax               # clean up stack (remove saved 1st number)
.mul_error:
    jmp .loop

.do_div:
    # 1. parse first number, dividend
    movq %rbx, %rdi         # %rbx points to text after "div"
    call skip_spaces        
    
    movq %rax, %rdi         # check if we hit end of line
    cmpb $0, (%rdi)
    je   .div_error         

    call read_word          
    movq %rsi, %rbx         # update %rbx position
    
    # convert 1st string to int
    movq %rax, %rdi         
    movq %rdx, %rsi         
    call atoi_signed        # returns value in %rax
    pushq %rax              # save divident on stack

    # 2. parse second number, divisor
    movq %rbx, %rdi         
    call skip_spaces
    
    movq %rax, %rdi         
    cmpb $0, (%rdi)
    je   .div_error_pop     

    call read_word          
    
    # convert 2nd string to int
    movq %rax, %rdi
    movq %rdx, %rsi
    call atoi_signed        # divisor is now in %rax

    # 3. check for zero
    cmpq $0, %rax           # check if divisor is 0
    je   .div_by_zero       # if 0, jump to error handler

    # 4. prepare registers
    movq %rax, %r10         # Move divisor to %r10 (so we can use %rax)
    popq %rax               # Restore dividend to %rax

    # 5. division
    # idivq divides the 128-bit value in %rdx:%rax by the operand.
    # the sign of %rax into %rdx must be extended
    cqo                     # sign-extend %rax -> %rdx:%rax
    
    idivq %r10              # Divide %rdx:%rax by %r10
                            # Result is stored in %rax
                            # Remainder is stored in %rdx 

    # 6. print result
    movq %rax, %rsi         # value to convert
    leaq num_buf(%rip), %rdx
    call signed_int_to_str  

    movq %rax, %rdi         
    call print_string
    
    leaq newline(%rip), %rdi
    call print_string

    jmp .loop               

.div_by_zero:
    popq %rax               # clean stack (remove saved dividend)
    leaq msg_div_zero(%rip), %rdi
    call print_string
    jmp .loop

.div_error_pop:
    popq %rax               # clean stack
.div_error:
    jmp .loop


.exit:
    popq %rbx               # restore before exiting
    movq $60, %rax
    movq $0,  %rdi
    syscall
