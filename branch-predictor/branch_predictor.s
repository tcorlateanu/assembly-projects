.global predict_branch
.global actual_branch
.global init

.section .bss
# we will use the .bss  because it reserves space for global/static variables 
# that don’t have an explicit initial value, we only need the memory for the variables 
.align 8
# ensures the next symbol (table) starts at an address that’s a multiple of 8 bytes
table: .space 2048   # 2048 byte counters, 2048 unique branches per run, so we allocate one byte per branch
# table = label (a named address) marking where our reserved storage begins
# we will use table as the base of our branch history table (BHT)
# so we can index into it with table + index: we take the base address where the array begins (that’s table),
# add an offset (index) to reach the element we want, and then load/store that byte.
# 0 strongly not taken
# 1 not taken
# 2 taken
# 3 strongly taken
# each branch has a state number 0/1/2/3
# predict rule: 0–1 -> predict not-taken, 2–3 -> predict taken.
# update rule: move one step toward the real outcome, but don’t go past 3
# initialization chooses the very first predictions before any learning
# if we start at 1 (not-taken), our FIRST guess for a new branch is "taken"
# if that branch turns out to be taken, the counter moves 1 -> 2 and NEXT time we will predict taken
# if we start at 2 (taken), our FIRST guess for a new branch is "taken"
# if it turns out to be not-taken, the counter moves 2 -> 1 and NEXT time we will predict not-taken
# so the difference is the initial bias: 1 favors "not taken" on first sight, while 2 favors "taken" on first sight
.section .text
# why we choose 1: many forward if/else checks are often not-taken at first, for example: if(something rare), then... 
# starting at 1 guesses these as not-taken right away, avoiding an early mistake on such branches
# init: fill table with not taken (=1) 
init:
    # prologue
    pushq   %rbp
    movq    %rsp, %rbp

    leaq    table(%rip), %rdi          # base address into %rdi
    movl    $2048, %ecx                # counter, we use 32 bits because it is enough to store
	                                   # no need to use the whole register
    movl    $1, %eax                   # fill value: 2 = weakly taken 
loop:
    movb    %al, (%rdi)                # store byte
    incq    %rdi
	decl    %ecx
    cmpl $0, %ecx
	jnz loop                           # uses %ecx as counter 
    
	# epilogue 
    movq    %rbp, %rsp
    popq    %rbp
    ret

# Helper macro (conceptually) for index: idx = ((pc ^ (pc>>11)) & 0x7FF)
# This cheap fold reduces some aliasing vs. plain low-11 bits, still 0..2047 [web:32].
# Implement inline in each function to keep things simple.

predict_branch:
    # prologue 
    pushq   %rbp
    movq    %rsp, %rbp

    # rdi = branch address
	# we will copy the pc into two registers so one copy can be shifted without losing the original.
	# pc: a 64-bit address uniquely identifying a branch site
    movq    %rdi, %rax                 # %rax = program counter, where this address "lives"
    movq    %rdi, %r9                  # %r9  = pc copy 

	# the next 3 instructions are a tiny hash to reduce collisions
    shrq    $11, %r9                   # %r9 = pc >> 11 
    xorq    %r9, %rax                  # %rax = pc ^ (pc>>11), we mix the bits 
    # why? a cheap way to combine patterns so addresses that share low bits but differ above map to a different index
    andq    $0x7FF, %rax               # %rax = index 0..2047 
	                                   # %rax keeps the lowest 11 bits of %rax and zeroes all higher bits

    leaq    table(%rip), %r10          # base 
    movzbl  (%r10,%rax,1), %r11d       # load counter (0..3) into 32-bit register
	                                   # our value 
	# (base, index, scale) means memory at base + index*scale
	# why 1? each table entry is exactly 1 byte (a single counter)

    # predict taken if counter >= 2 (states 2,3) 
    xorl    %eax, %eax                 # default: 0 (not taken) xorl <=> %eax = 0
    cmpl    $2, %r11d                  # if ctr >= 2 
    jl      done                       # stays 0 
    movl    $1, %eax                   # else 1 (taken)
 done:
    movq    %rbp, %rsp
    popq    %rbp
    ret
# to update the correct entry, actual_branch must compute the exact same index the predictor
# used to make the prediction, that is why it repeats the same fold-and-mask steps on the same PC
actual_branch:
    # prologue
    pushq   %rbp
    movq    %rsp, %rbp

    # rdi = branch address, rsi = actual outcome (0/1)
    movq    %rdi, %rax                 # %rax = pc 
    movq    %rdi, %r9                  # %r9  = pc copy 

    shrq    $11, %r9                   # r9 = pc >> 11 
    xorq    %r9, %rax                  # rax = pc ^ (pc>>11) 
    andq    $0x7FF, %rax               # rax = index 0..2047


    leaq    table(%rip), %r10          # base
    movzbl  (%r10,%rax,1), %r11d       # r11d = counter 

    # if taken (rsi==1): ctr = min(ctr+1, 3), else ctr = max(ctr-1, 0) 
	#"saturating" means the counter moves one step toward the observed outcome but clamps at the ends:
    # if outcome is taken: increment by 1, but not above 3 -> state = min(state + 1, 3).
	# if outcome is not taken: decrement by 1, but not below 0 -> state = max(state − 1, 0).
	# ctr = counter, 0/1/2/3
    cmpq    $1, %rsi                   # taken? 
    jne     ab_not_taken               # no -> decrement path 

    cmpl    $3, %r11d                  # taken: saturate at 3 
    jae     ab_store
    incl    %r11d
    jmp     ab_store

ab_not_taken:
    testl   %r11d, %r11d               # do we have zero in %r11d? 
    je      ab_store
    decl    %r11d                      # else, --

ab_store:
    movb    %r11b, (%r10,%rax,1)       # store updated byte

    movq    %rbp, %rsp
    popq    %rbp
    ret

# predict_branch is "read-only + decide now" to keep execution flowing.

# actual_branch is "learn and write back" so future calls to predict_branch for the same PC use updated history.
