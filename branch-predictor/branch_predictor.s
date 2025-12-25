.global predict_branch
.global actual_branch
.global init

.section .bss
.align 8
history_table: .space 2048         # 2048 byte counters, values 0..3 [web:5][web:1]

.section .text

# init: fill table with weakly taken (=2) to reduce cold-start mispredicts on loops
init:
    pushq   %rbp
    movq    %rsp, %rbp

    leaq    history_table(%rip), %rdi  # base ptr [web:12]
    movl    $2048, %ecx                # count [web:12]
    movl    $2, %eax                   # fill value: 2 = weakly taken [web:5][web:1]
.init_loop:
    movb    %al, (%rdi)                # store byte [web:12]
    incq    %rdi
    loop    .init_loop                 # uses ecx as counter [web:12]

    movq    %rbp, %rsp
    popq    %rbp
    ret

# Helper macro (conceptually) for index: idx = ((pc ^ (pc>>11)) & 0x7FF)
# This cheap fold reduces some aliasing vs. plain low-11 bits, still 0..2047 [web:32].
# Implement inline in each function to keep things simple.

predict_branch:
    pushq   %rbp
    movq    %rsp, %rbp

    # rdi = branch address (PC) [web:19]
    movq    %rdi, %rax                 # rax = pc [web:19]
    movq    %rdi, %r9                  # r9  = pc copy [web:19]
    shrq    $11, %r9                   # r9 = pc >> 11 [web:32]
    xorq    %r9, %rax                  # rax = pc ^ (pc>>11) [web:32]
    andq    $0x7FF, %rax               # rax = index 0..2047 [web:5]

    leaq    history_table(%rip), %r10  # base [web:12]
    movzbl  (%r10,%rax,1), %r11d       # load counter (0..3) into 32-bit reg [web:5]

    # Predict taken if counter >= 2 (states 2,3) [web:4][web:5]
    xorl    %eax, %eax                 # default: 0 (not taken) [web:5]
    cmpl    $2, %r11d                  # if ctr >= 2 ... [web:4]
    jl      .pb_done                   # ... stay 0 [web:4]
    movl    $1, %eax                   # else 1 (taken) [web:4]
.pb_done:
    movq    %rbp, %rsp
    popq    %rbp
    ret

actual_branch:
    pushq   %rbp
    movq    %rsp, %rbp

    # rdi = branch address, rsi = actual outcome (0/1) [web:19]
    movq    %rdi, %rax                 # rax = pc [web:19]
    movq    %rdi, %r9                  # r9  = pc copy [web:19]
    shrq    $11, %r9                   # r9 = pc >> 11 [web:32]
    xorq    %r9, %rax                  # rax = pc ^ (pc>>11) [web:32]
    andq    $0x7FF, %rax               # rax = index 0..2047 [web:5]

    leaq    history_table(%rip), %r10  # base [web:12]
    movzbl  (%r10,%rax,1), %r11d       # r11d = counter [web:5]

    # if taken (rsi==1): ctr = min(ctr+1, 3), else ctr = max(ctr-1, 0) [web:4][web:5]
    cmpq    $1, %rsi                   # taken? [web:19]
    jne     .ab_not_taken              # no -> decrement path [web:5]

    cmpl    $3, %r11d                  # taken: saturate at 3 [web:4]
    jae     .ab_store
    incl    %r11d
    jmp     .ab_store

.ab_not_taken:
    testl   %r11d, %r11d               # zero? [web:5]
    je      .ab_store
    decl    %r11d

.ab_store:
    movb    %r11b, (%r10,%rax,1)       # store updated byte [web:5]

    movq    %rbp, %rsp
    popq    %rbp
    ret
