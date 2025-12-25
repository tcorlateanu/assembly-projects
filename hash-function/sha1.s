#.global sha1_chunk


# in %rdi, first parameter, address of h0

# in %rsi, second parameter, address of the first element in the array
# so, %rsi points to the start of an array, that will hold the 80 words

sha1_chunk:

	# prologue
	pushq %rbp
	movq %rsp, %rbp


	# using callee saved registers for calculating the next word
	pushq %r12    # here we will have w[i-3]
	pushq %r13    # here we will have w[i-8]
	pushq %r14    # here we will have w[i-14]
	pushq %r15	  # here we will have w[i-16]
	pushq %rbx    # here will be the index of the word we are going to calculate

	movq $16, %rbx  # since the first 16 32-bit words are filled, we need to obtain the words starting at index 16 through 79, so we will
	                # have 80 32-bit words in total

# we start the loop, extending the initial 16 words into the full array
next_word_loop:
# we have an array, 32-bit words, so 4 byte words each element
# the base address: first element, stored in %rsi
# the formula we use: base address + index * value(this one is 4(bytes) 
# we need to access the previous words, we will have an offset -12, -32, -56, -64
	movl -12(%rsi, %rbx, 4), %r12d # w[i-3], offest 3*4 
	movl -32(%rsi, %rbx, 4), %r13d # w[i-8], offest 8*4 
	movl -56(%rsi, %rbx, 4), %r14d # w[i-14], offest 14*4 
	movl -64(%rsi, %rbx, 4), %r15d # w[i-16], offest 64*4

	# we calculate the next word
	# formula: leftrotate(w[i-3] XOR w[i-8] XOR w[i-14] XOR w[i-16], 1)
	# we use movl, or xorl because we work with 32-bits, same with the name of the registers, we only use the least significant 32 bits
	movl %r12d, %eax
	xorl %r13d, %eax
	xorl %r14d, %eax
	xorl %r15d, %eax
	roll $1, %eax      #  MsB become LsB example: 010 -> 100

	# we store w[i]
	movl %eax, (%rsi, %rbx, 4) # starting at %rsi, then we add 4*%rbx(=index)

	incq %rbx # %rbx++ we calculate the next word
	cmpq $80, %rbx # check if we have all the words
	jl next_word_loop # if lower, then we calculate the next word

# we calculate the h0, h1, h2, h3, h4
# in %rdi we have the address of h0, h1, h2, h3, h4, are next, we will use the same registers
# the offset is 4, we want the next value, as opposed to calculating the words, where we needed the previous value
    
	movl (%rdi), %r12d      # here we have the initial value of h0 (a)
	movl 4(%rdi), %r13d     # here we have the initial value of h1 (b)
	movl 8(%rdi), %r14d     # here we have the initial value of h2 (c)
	movl 12(%rdi), %r15d    # here we have the initial value of h3 (d)
	movl 16(%rdi), %ebx     # here we have the initial value of h4 (e)

	movq $0, %rcx          # with %rcx we will check if we went through all the words
	movq $0, %r11
	movq $0, %r10
	movq $0, %r9

hash_loop:

    cmpq $80, %rcx
    je end_loop

# formula : temp = leftrotate(a, 5) + f + e + k + w[i]    e = d   d = c  c = leftrotate(b, 30)   b = a   a = temp
# formula f: 0 - 19 (b and c) or (not b and d)   20 - 39 b XOR c XOR d     40 - 59 (b and c) or (b and d) or (c and d)    60 - 79 b XOR c XOR d
# formula k: 0 - 19 k = 0x5A827999     20 - 39 k = 0x6ED9EBA1      40 - 59  k = 0x8F1BBCDC    60 - 79 k = 0xCA62C1D6
# f -> %r11  k -> %r10

	cmpq $20, %rcx
	jl range1

	cmpq $40, %rcx
	jl range2

	cmpq $60, %rcx
	jl range3

	cmpq $80, %rcx
	jl range4

range1:
    # f = (b and c) or (not b and d)
    movl %r13d, %r11d       # r11d = b
    andl %r14d, %r11d       # r11d = b and c
    movl %r13d, %r9d        # r9d = b
    notl %r9d               # r9d = not b
    andl %r15d, %r9d        # r9d = not b and d
    orl %r9d, %r11d         # r11d = (b and c) or (not b and d)
    movl $0x5A827999, %r10d # k = 0x5A827999
    jmp next_abcde

range2:
    # f = b ^ c ^ d
    movl %r13d, %r11d       # r11d = b
    xorl %r14d, %r11d       # r11d = b XOR c
    xorl %r15d, %r11d       # r11d = b XOR c XOR d
    movl $0x6ED9EBA1, %r10d # k = 0x6ED9EBA1
    jmp next_abcde

range3:
    # f = (b and c) or (b and d) or (c and d)
    movl %r13d, %r11d       # r11d = b
    andl %r14d, %r11d       # r11d = b and c
    movl %r13d, %r9d        # r9d = b
    andl %r15d, %r9d        # r9d = b and d
    orl %r9d, %r11d         # r11d = (b and c) or (b and d)
    movl %r14d, %r9d        # r9d = c
    andl %r15d, %r9d        # r9d = c and d
    orl %r9d, %r11d         # r11d = (b and c) or (b and d) or (c and d)
    movl $0x8F1BBCDC, %r10d # k = 0x8F1BBCDC
    jmp next_abcde

range4:
    # f = b XOR c XOR d
    movl %r13d, %r11d       # r11d = b
    xorl %r14d, %r11d       # r11d = b XOR c
    xorl %r15d, %r11d       # r11d = b XOR c XOR d
    movl $0xCA62C1D6, %r10d # k = 0xCA62C1D6
    jmp next_abcde

next_abcde:
# temp = leftrotate(a,5) + f + e + k + w[i]
# for each step out of the 80, we updated our variables, such that the state of the hash will keep track of the combined digits so far

    # leftrotate(a,5):
    movl %r12d, %r9d               # r9d = a
    roll $5, %r9d                  # r9d = leftrotate(a, 5)

    addl %r11d, %r9d               # r9d += f
    addl %ebx, %r9d                # r9d += e   (e stored in rbx)
    addl %r10d, %r9d               # r9d += k

    movl (%rsi, %rcx, 4), %eax     # load w[i]
    addl %eax, %r9d                # r9d += w[i]

    # e = d
    movl %r15d, %ebx

    # d = c
    movl %r14d, %r15d

    # c = leftrotate(b,30)
    movl %r13d, %r14d
    roll $30, %r14d

    # b = a
    movl %r12d, %r13d

    # a = temp (r9d)
    movl %r9d, %r12d

    inc %rcx
    jmp hash_loop

end_loop:
 
	# h0 += a  -> %r12
    movl (%rdi), %eax    # in %eax i will have the initial value
    addl %r12d, %eax     # we add the updated a to the initial value
    movl %eax, (%rdi)    # we store it back in its position 
    
    # h1 += b  -> %r13
    movl 4(%rdi), %eax
    addl %r13d, %eax
    movl %eax, 4(%rdi)
    
    # h2 += c  -> %r14
    movl 8(%rdi), %eax
    addl %r14d, %eax
    movl %eax, 8(%rdi)
    
    # h3 += d -> %r15
    movl 12(%rdi), %eax
    addl %r15d, %eax
    movl %eax, 12(%rdi)
    
    # h4 += e -> %rbx
    movl 16(%rdi), %eax
    addl %ebx, %eax
    movl %eax, 16(%rdi)





	# epilogue
	#restoring the registers, the opposite order
	popq %rbx
	popq %r15
	popq %r14
	popq %r13
	popq %r12

	movq %rbp, %rsp
	popq %rbp
	ret
