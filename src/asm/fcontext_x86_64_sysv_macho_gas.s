/*
            Copyright Oliver Kowalke 2009.
   Distributed under the Boost Software License, Version 1.0.
      (See accompanying file LICENSE_1_0.txt or copy at
            http://www.boost.org/LICENSE_1_0.txt)
*/

/****************************************************************************************
 *                                                                                      *
 *  ----------------------------------------------------------------------------------  *
 *  |    0    |    1    |    2    |    3    |    4     |    5    |    6    |    7    |  *
 *  ----------------------------------------------------------------------------------  *
 *  |   0x0   |   0x4   |   0x8   |   0xc   |   0x10   |   0x14  |   0x18  |   0x1c  |  *
 *  ----------------------------------------------------------------------------------  *
 *  |        RBX        |        R12        |         R13        |        R14        |  *
 *  ----------------------------------------------------------------------------------  *
 *  ----------------------------------------------------------------------------------  *
 *  |    8    |    9    |   10    |   11    |    12    |    13   |    14   |    15   |  *
 *  ----------------------------------------------------------------------------------  *
 *  |   0x20  |   0x24  |   0x28  |  0x2c   |   0x30   |   0x34  |   0x38  |   0x3c  |  *
 *  ----------------------------------------------------------------------------------  *
 *  |        R15        |        RBP        |         RSP        |        RIP        |  *
 *  ----------------------------------------------------------------------------------  *
 *  ----------------------------------------------------------------------------------  *
 *  |    16   |    17   |                                                            |  *
 *  ----------------------------------------------------------------------------------  *
 *  |   0x40  |   0x44  |                                                            |  *
 *  ----------------------------------------------------------------------------------  *
 *  |        RDI        |                                                            |  *
 *  ----------------------------------------------------------------------------------  *
 *  ----------------------------------------------------------------------------------  *
 *  |   18    |   19    |                                                            |  *
 *  ----------------------------------------------------------------------------------  *
 *  |  0x48   |  0x4c   |                                                            |  *
 *  ----------------------------------------------------------------------------------  *
 *  | fc_mxcsr|fc_x87_cw|                                                            |  *
 *  ----------------------------------------------------------------------------------  *
 *  ----------------------------------------------------------------------------------  *
 *  |   20    |    21   |    22    |   23    |    24   |    25   |                   |  *
 *  ----------------------------------------------------------------------------------  *
 *  |  0x50   |   0x54  |   0x58   |  0x5c   |   0x60  |   0x64  |                   |  *
 *  ----------------------------------------------------------------------------------  *
 *  |       sbase       |        slimit      |      fc_link      |                   |  *
 *  ----------------------------------------------------------------------------------  *
 *                                                                                      *
 * **************************************************************************************/

.text
.globl _boost_fcontext_jump
//.type _boost_fcontext_jump,@function
.align 8
_boost_fcontext_jump:
    movq     %rbx,       (%rdi)         /* save RBX */
    movq     %r12,       0x8(%rdi)      /* save R12 */
    movq     %r13,       0x10(%rdi)     /* save R13 */
    movq     %r14,       0x18(%rdi)     /* save R14 */
    movq     %r15,       0x20(%rdi)     /* save R15 */
    movq     %rbp,       0x28(%rdi)     /* save RBP */

    stmxcsr  0x48(%rdi)                 /* save SSE2 control and status word */
    fnstcw   0x4c(%rdi)                 /* save x87 control word */

    leaq     0x8(%rsp),  %rcx           /* exclude the return address and save as stack pointer */
    movq     %rcx,       0x30(%rdi)     /* save as stack pointer */
    movq     (%rsp),     %rcx           /* save return address */
    movq     %rcx,       0x38(%rdi)     /* save return address as RIP */


    movq     (%rsi),      %rbx      /* restore RBX */
    movq     0x8(%rsi),   %r12      /* restore R12 */
    movq     0x10(%rsi),  %r13      /* restore R13 */
    movq     0x18(%rsi),  %r14      /* restore R14 */
    movq     0x20(%rsi),  %r15      /* restore R15 */
    movq     0x28(%rsi),  %rbp      /* restore RBP */

    ldmxcsr  0x48(%rsi)             /* restore SSE2 control and status word */
    fldcw    0x4c(%rsi)             /* restore x87 control word */

    movq     0x30(%rsi),  %rsp      /* restore RSP */
    movq     0x38(%rsi),  %rcx      /* fetch the address to return to */
    movq     0x40(%rsi),  %rdi      /* restore RDI */

    xorq     %rax,        %rax      /* set RAX to zero */
    jmp      *%rcx                  /* indirect jump to context */

.text
.globl _boost_fcontext_make
//.type _boost_fcontext_make,@function
.align 8
_boost_fcontext_make:
    movq   %rdi,                 (%rdi)     /* save the address of current context */
    movq   %rsi,                 0x38(%rdi) /* save the address of the function supposed to run */
    movq   %rdx,                 0x40(%rdi) /* save the the void pointer */
    movq   0x50(%rdi),           %rdx       /* load the stack base */
    leaq   -0x8(%rdx),           %rdx       /* reserve space for the last frame on stack, (RSP + 8) % 16 == 0 */
    movq   %rdx,                 0x30(%rdi) /* save the address */
    movq   0x60(%rdi),           %rcx       /* load the address of the next context */
    movq   %rcx,                 0x8(%rdi)  /* save the address of next context */
    stmxcsr  0x48(%rdi)                     /* save SSE2 control and status word */
    fnstcw   0x4c(%rdi)                     /* save x87 control word */
    leaq   link_fcontext(%rip),  %rcx       /* helper code executed after fn() returns */
    movq   %rcx,                 (%rdx)
    xorq   %rax,                 %rax       /* set RAX to zero */
    ret

link_fcontext:
    movq   %r12,               %rsi			/* restore next context */
    testq  %rsi,               %rsi         /* test if a next context was given */
    je     1f                               /* jump to finish */

    movq   %rbx,               %rdi         /* restore current context */
    call   _boost_fcontext_jump             /* install next context */

1:
    xorq    %rdi,              %rdi         /* exit code is zero */
    call   _exit                            /* exit application */