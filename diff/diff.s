.section .data
f1:     .asciz "< " 
f2:     .asciz "> " 
f3:     .asciz "---\n" 
f4:     .byte '\n'  
f5:     .byte 'c' 

.text
.global  write

# print unsigned integer: %rdi = value -> prints decimal to stdout using write(1,start address,length)
.global  print_uint
print_uint:
    # prologue
    pushq   %rbp
    movq    %rsp, %rbp

    subq    $48, %rsp                # we push the stack pointer so we can build our number in ASCII
    leaq    -32(%rbp), %rsi          # in %rsi we will have the base address
    movq    %rsi, %rcx               # %rcx will now point to the same address
    addq    $32, %rcx                # we add 32 , now we start building from right to left
    movq    %rdi, %rax               # rax = value
    movq    $0,  %rdx                # printed_any = 0

division_loop:
    cmpq    $0, %rax                 # did we reach the end?
    jnz     do_division              # if not, we start doing the divisiongcc -no-pie -O2 -g diff.s -o mydiff && ./mydiff -i -B
    cmpq    $0, %rdx                 # is %rdx 0? then original input = 0
    jnz     division_done            # if not,  we are done
    subq    $1, %rcx                 # we decrease the value of %rcx 
    movb    $'0', (%rcx)             # we convert our number ( 0 )into ASCII
    movq    $1, %rdx                 # we have something                
    jmp     division_done

do_division:
    movq    $0, %rdx               # make sure %rdx is 0, here will be the remainder
    movq    $10, %r8               # we will divide by 10
    divq    %r8                    # rax = quo, rdx = rem 
                                   # so from 1234 in %rax we will have 123 and in %rdx we will have 4
    subq    $1, %rcx               # %rcx -- , so we will go to the next addres(right to left)
    movq    %rdx, %r9              # remainder -> %r9
    addq    $'0', %r9              # we convert to ASCII
    movb    %r9b, (%rcx)           # we put it in its place so at first _ _ _ 4 
                                   # then _ _ 3 4 and so on
    movq    $1, %rdx               # at least one digit written, even in %rax is now zero      
    jmp     division_loop

division_done:
    # write(1, rcx, len=end-rcx)
    movq    $1, %rdi       # must appear here 
    movq    %rcx, %rsi     # start address
# we added 32 so         x -> _ _ ... _ _, then we compute our number _ _ _..._ _ 1 2 3 4
# here was the base at first  .                                       rcx is here .

    leaq    -32(%rbp), %r9 # recomputes the base address: base address = %rbp − 32 lets say x
    movq    %r9, %r8       # copy that into %r8   %r8 = x
    addq    $32, %r8       # we add 32  %r8 = x + 32
    movq    %r8, %rax      # %rax = x + 32
    subq    %rcx, %rax     # %rax = x + 32 - (where %rcx points) which will result into the length
    movq    %rax, %rdx     # into %rdx
    call    write          # we print dirrectly on the terminal, no printf needed

    addq    $48, %rsp
    leave
    ret

.global  diff
diff:
    # prologue
    pushq   %rbp
    movq    %rsp, %rbp

    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    subq    $8, %rsp                 # ensure 16B alignment before any call 

    # args: rdi=text1, rsi=text2, rdx=i_flag, rcx=B_flag
    movq    %rdx, %r12               # i_flag (0/1)
    movq    %rcx, %r13               # B_flag (0/1)
    movq    %rdi, %r14               # left base
    movq    %rsi, %r15               # right base
    movq    $0,  %rbx                # line_no = 0 

# loop header
next_line:
    # stop when both reach end
    movzbq  (%r14), %rax
    movzbq  (%r15), %rcx
    cmpq    $0, %rax
    jnz     more_left
    cmpq    $0, %rcx
    jnz     more_left
    jmp     done

more_left:
    # scan left line -> len1 in %r10
    movq    %r14, %rdi   # %rdi start address
find_eol1:
    movzbq  (%rdi), %rax   # move the current byte into %rax 
    cmpb    $'\n', %al     # search for the character 'newline'
    je      found_eol1     # if equals, check next
    cmpb    $0, %al        # serach for null temrinator
    je      found_eol1
    addq    $1, %rdi
    jmp     find_eol1
found_eol1:
    movq    %rdi, %rax     # in %rax final address, where either 'newline' or 'null terminator' is
    subq    %r14, %rax     # we do final-start = length1 of the first line
    movq    %rax, %r10     # len1 in %r10

    # scan right line -> len2 in %r11
    movq    %r15, %rdi
find_eol2:
    movzbq  (%rdi), %rax
    cmpb    $'\n', %al
    je      found_eol2
    cmpb    $0, %al
    je      found_eol2
    addq    $1, %rdi
    jmp     find_eol2
found_eol2:
    movq    %rdi, %rax
    subq    %r15, %rax
    movq    %rax, %r11               # len2

    cmpq    $0, %r13                # we check if B is on
    jz      no_fast_path
# if left empty (len1==0) and right not empty -> skip left line only
cmpq    $0, %r10   # left is 0
jne      no_fast_path
check_r:
cmpq    $0, %r11   # right is not zero, the advance left
jne     adv_l 

cmpq    $0, %r11   # right is 0
jne      no_fast_path
check_l:
cmpq    $0, %r10   # left is not zero, the advance right
jne     adv_r
# advance left only
adv_l:
movzbq  (%r14,%r10,1), %rax
leaq    0(%r14,%r10,1), %r14
cmpq    $'\n', %rax
jne     next_line
addq    $1, %r14
jmp     next_line
adv_r:
movzbq  (%r15,%r11,1), %rax
leaq    0(%r15,%r11,1), %r15
cmpq    $'\n', %rax
jne     next_line
addq    $1, %r15
jmp     next_line

no_fast_path:

# blank-only flags: left -> %rdx, right -> %r9 (1=blank-only, 0=not)
    movq    $1, %rdx               # we start by assuming the line is blank only (space, tab)
    movq    $0, %rcx               # index
blank_left_loop:  
    cmpq    %r10, %rcx             # check if we went through all the characters
    jge     blank_left_done        # if so, done
    movzbq  (%r14,%rcx,1), %r8     # base + index*value, start %r14, %rcx = index (which byte), 1 = value(one byte only)
    cmpq    $0x20, %r8             # check if it is sapce space
    je      bl_l_next
    cmpq    $0x09, %r8             # tab
    je      bl_l_next
    movq    $0, %rdx               # we reach this line, then not blank so $0 in %rdx
    jmp     blank_left_done
bl_l_next:
    addq    $1, %rcx
    jmp     blank_left_loop
blank_left_done:
# the exact same thing for the other line, we store the value in %r9
    movq    $1, %r9
    movq    $0, %rcx
blank_right_loop:
    cmpq    %r11, %rcx
    jge     blank_right_done
    movzbq  (%r15,%rcx,1), %r8
    cmpq    $0x20, %r8
    je      bl_r_next
    cmpq    $0x09, %r8
    je      bl_r_next
    movq    $0, %r9
    jmp     blank_right_done
bl_r_next:
    addq    $1, %rcx
    jmp     blank_right_loop
blank_right_done:

# -B gate: if enabled and both blank-only -> skip reporting
# why? " " and "/t/t" will be the same, no need to compare byte by byte, no importance what value i has

    cmpq    $0, %r13                 # B_flag ?
    jz      B_off
    cmpq    $0, %rdx                 # blank1 ?
    jz      B_off
    cmpq    $0, %r9                  # blank2 ?
    jz      B_off
    jmp     advance_both    # we reach this line, then both blank and B is on
# B off meaning that " " and "/t/t" will be different
B_off:
check_i:
    cmpq    $0, %r12                 # i_flag ? is it 0?
    jz      compare_exact            # compare exact: "hello" and "Hello" are different
    jmp     compare_fold             # compare fold:  "hello" and "Hello" are the same 

# exact compare (i=0) -> %rax=1 if different, 0 if equal (here we will have our final result)
# B is off, we compare character with character B = 0 i = 0
compare_exact:
    movq    $0, %rax             # we assume they are equal at first
    cmpq    %r10, %r11           # check their length, if it is not equal then from the starts there is a difference
    jne     mark_diff            # jump to mark_diff
    movq    $0, %rcx             # %rcx = index, we start our comparison
ce_loop:
    cmpq    %r10, %rcx           # check if we reached the end, if so, comparison done
    jge     cmp_done
    movzbq  (%r14,%rcx,1), %r8   # we move the current byte into %r8
    movzbq  (%r15,%rcx,1), %r9   # we move the current byte into %r9
    cmpq    %r8, %r9             # we compare them
    jne     mark_diff            # not equal, there is a differnce 
    addq    $1, %rcx             # go to the next one
    jmp     ce_loop
    jmp     cmp_done             # we reached this line, then we are done, otherwise we would have been 
                                 # still in the loop, or in mark_diff
                                 # the lines are equal!!!

# case-insensitive compare (i=1)
compare_fold:
    movq    $0, %rax            # same things here, checking the lenghts
    cmpq    %r10, %r11
    jne     mark_diff
    movq    $0, %rcx
# ASCII code: A = 65  Z = 90 a = 97 z = 122
cf_loop:
    cmpq    %r10, %rcx         # check if we reached the end
    jge     cmp_done           # if so, we are done
    movzbq  (%r14,%rcx,1), %r8       # a
    movzbq  (%r15,%rcx,1), %r9       # b

    movq    %r8, %rsi         # we copy the current byte into %rsi
    cmpq    $'A', %rsi        # is the value of the current byte lower than 'A' ?
                              # it is not an upperCase letter than
    jb      skip_a            # we go this skip_a
    cmpq    $'Z', %rsi        # is it greater(above) 'Z', not an upperCase letter
    ja      skip_a
    orq     $0x20, %r8        # if we are here, we have an upperCase letter, we convert it into 
                              # a lower case one 
skip_a:
    movq    %r9, %rsi         # in %r9 we had our current byte, which is not an uppercase letter here
    cmpq    $'A', %rsi        # is it below 'A' ? not a letter, we do the comparison normally
    jb      skip_b        
    cmpq    $'Z', %rsi       
    ja      skip_b            # is it greater(above) 'Z', not an upperCase letter
    orq     $0x20, %r9
skip_b:
    # here we will have the upperCase letters converted into lowerCase letters
    cmpq    %r8, %r9     # are they different?      
    jne     mark_diff    # difference
    addq    $1, %rcx     # incraese index, go to the next character
    jmp     cf_loop      # repeat the loop

mark_diff:
    movq    $1, %rax     # we have a difference !!!
# we reach this line if we went through all the characters
cmp_done:
    # print hunk if different
    cmpq    $0, %rax    # if we have no difference, we jump, we do NOT print 
    jz      after_print

    # line_no = line_no + 1
    addq    $1, %rbx   
    subq    $16, %rsp
    movq    %r10, 0(%rsp)         # save len1
    movq    %r11, 8(%rsp)         # save len2 

# f1:.asciz "< " , f2: .asciz "> ", f3: .asciz "---\n", f4: .byte '\n', f5: .byte 'c' 
    # Header: L c L \n
    # we reach this line, we have a differnce, we print 
    movq    %rbx, %rdi               # print_uint(line_no) = line number 
    call    print_uint               # we print
    leaq    f5(%rip), %rsi           # write(1,"c",1)
    movq    $1, %rdx                 # length = 1
    movq    $1, %rdi                 # convention
    call    write
    movq    %rbx, %rdi                # print_uint(line_no)
    call    print_uint
    leaq    f4(%rip), %rsi           # write(1,"\n",1)
    movq    $1, %rdx
    movq    $1, %rdi
    call    write

    # "< " + left slice + "\n"
    leaq    f1(%rip), %rsi       # write(1,"< ",2)
    movq    $2, %rdx             # length 
    movq    $1, %rdi
    call    write
    movq    %r14, %rsi            # write(1,left,len1) , start address is %rsi
    movq    0(%rsp), %rdx         # len1 (restored)
    movq    $1,  %rdi
    call    write
    leaq    f4(%rip), %rsi       # write(1,"\n",1)
    movq    $1, %rdx
    movq    $1, %rdi
    call    write

    # "---\n"
    leaq    f3(%rip), %rsi      # write(1,"---\n",4)
    movq    $4, %rdx            # length
    movq    $1, %rdi
    call    write

    # "> " + right slice + "\n"
    leaq    f2(%rip), %rsi       # write(1,"> ",2)
    movq    $2, %rdx
    movq    $1, %rdi
    call    write
    movq    %r15, %rsi            # right start
    movq    8(%rsp), %rdx         # len2 (restored)
    movq    $1,  %rdi
    call    write
    leaq    f4(%rip), %rsi       # write(1,"\n",1)
    movq    $1, %rdx
    movq    $1, %rdi
    call    write

    movq 0(%rsp), %r10
    movq 8(%rsp), %r11
    addq    $16, %rsp             # drop saved lengths
    jmp after_print

after_print:
    # if equal, still bump line_no for header parity
    cmpq    $0, %rax    # is %rax 0
    jnz     keep_lno    # if not, then we do not add 1 to %rbx, because we already added 1 when they were not 
                        # equal. After printing, the code "falls through", we do not want to increment that much
    addq    $1, %rbx
keep_lno:

advance_both:
    # advance left past '\n' if present
    movzbq  (%r14,%r10,1), %rax    # from base we go to the next addres, if base = x , length = 10
                                   # next addres x + 10 * 1 = x + 10
    leaq    0(%r14,%r10,1), %r14   # that address into %r14
    cmpq    $'\n', %rax            # is it newline?
    jne     adv_right              
    addq    $1, %r14               # we add one, so we go to the next address    

adv_right:
    movzbq  (%r15,%r11,1), %rax
    leaq    0(%r15,%r11,1), %r15
    cmpq    $'\n', %rax
    jne     next_line
    addq    $1, %r15
    jmp     next_line

done:
    addq    $8, %rsp                 
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    movq    %rbp, %rsp
    popq    %rbp
    ret

.global  main
main:
    pushq   %rbp
    movq    %rsp, %rbp

    # on entry: %rdi = argc, %rsi = argv (convention, this is the way it is)
    # example: Command: wsl file1.txt file2.txt
    # values inside main: argc = 5, argv = "./mydiff", "-i", "-B" "file1.txt file2.txt" + null-terminator
    # at argv[argv]
    # so, argc = counter, argv = array of pointers: name of the program + arguments
    # each argv[i] is an 8-byte pointer to a string


    movq    $0, %rdx                 # i_instr = 0
    movq    $0, %rcx                 # B_instr = 0

    movq    $1, %r8
argv_loop:
    cmpq    %rdi, %r8
    jge     argv_done
    movq    (%rsi,%r8,8), %rax

    cmpb    $'-', (%rax)
    jne     next_argv

    movzbq  1(%rax), %r9
    cmpb    $'i', %r9b
    jne     check_B
    cmpb    $0, 2(%rax)
    jne     next_argv
    movq    $1, %rdx                 # set i_instr = 1
    jmp     next_argv

check_B:
    cmpb    $'B', %r9b
    jne     next_argv
    cmpb    $0, 2(%rax)
    jne     next_argv
    movq    $1, %rcx                 # set B_instr = 1

next_argv:
    addq    $1, %r8
    jmp     argv_loop

argv_done:
    leaq    txt1(%rip), %rdi
    leaq    txt2(%rip), %rsi

    subq    $8, %rsp              
    call    diff
    addq    $8, %rsp

    leave
    ret

.section .data
txt1:
    .asciz "HelLo world\n I am Teo" 
txt2:
    .asciz "Hello world\n I am Daria" 

#txt1: "A\nB\nC.\n"
#txt2: "A\nB\nC.\n"

#txt1: "A\nThis is test1.\nZ\n"
#txt2: "A\nThis is test2.\nZ\n"

#txt1: "A\nalpha\nbeta\nomega\n"
#txt2: "A\nAlpha\nBETa!\nomega\n"

#txt1: "MiXeD CaSe Line\n"
#txt2: "mixed case line\n"

#txt1: "A\n \nB\n"
#txt2: "A\n\t\t\nB\n"

#txt1: "line1\nline2\n"
#txt2: "line1\n\nline2\n"

#txt1: " \t\tana\nana"
#txt2: "ana\nana"
