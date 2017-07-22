/*
                      TINY VIRTUAL MACHINE (TVM)

Copyright © 2017, Robert Gollagher.
SPDX-License-Identifier: GPL-3.0+

Program:    srm
Author :    Robert Gollagher   robert.gollagher@freeputer.net
Created:    20170721
Updated:    20170721+
Version:    pre-alpha-0.0.0.1 for FVM 2.0

Notes: This is an experiment along the lines of srm.s but even simpler.
It attemps to be about two orders of magnitude simpler than FVM 2.0.
The initial version of tvm.s is identical to srm.s.
It will be progressively cut down and simplified.


                              This Edition:
                           32-bit i386 native
                          x86 Assembly Language
                           using GNU Assembler

                               ( ) [ ] { }

This experimental version uses macros and is compiled to native x86.
Therefore this can easily be ported to other architectures such as ARM.
Once experimentation is complete an interpreted VM will also be implemented.
Note: it perhaps makes sense to make this a Harvard architecture.

==============================================================================
                            BUILDING FOR i386
==============================================================================

For debugging build with:

  as -g --gstabs -o fvm.o fvm.s --32
  gcc -o fvm fvm.o -m32

For release build with:

  as -o fvm.o fvm.s --32
  gcc -o fvm fvm.o -m32

Alternative if no imports:

  as -o fvm.o fvm.s --32
  ld -o fvm fvm.o -m elf_i386

==============================================================================
 WARNING: This is pre-alpha software and as such may well be incomplete,
 unstable and unreliable. It is considered to be suitable only for
 experimentation and nothing more.
============================================================================*/
# ============================================================================
#                                IMPORTS
# ============================================================================
.extern printf
.extern putchar

# ============================================================================
#                                SYMBOLS
# ============================================================================
.equ SUCCESS, 0
.equ FAILURE, 1
.equ MM_BYTES, 0x1000000
.equ WORD_SIZE, 4
.equ vA, %ebx
.equ vX, %edx
.equ vL, %edi
.equ rA, %eax
.equ rC, %ecx

# ============================================================================
.section .data #                CONSTANTS
# ============================================================================
version: .asciz "SRM 0.0.0.0\n"
exit: .asciz "SRM exit code: "
illegal: .asciz "SRM illegal opcode with metadata: "
format_hex8: .asciz "%08x"
newline: .asciz "\n"
space: .asciz " "

# ============================================================================
#                             INSTRUCTION SET
# ============================================================================
/*



*/
# ----------------------------------------------------------------------------
#                   I/O INSTRUCTIONS just for fun for now
# ----------------------------------------------------------------------------
.macro OUTCHAR reg
  pushl \reg
  call putchar
  addl $4, %esp
.endm

.macro INCHAR
  call getchar
.endm


# ----------------------------------------------------------------------------
#                             MOVE INSTRUCTIONS
# ----------------------------------------------------------------------------
.macro lit metadata
  movl $\metadata, vA
.endm

.macro litx metadata
  movl $\metadata, vA
  movl $0x00800000, rC
  andl vA, rC
  jz 1f
    orl $0xff000000, vA
  1:
.endm

.macro litm metadata
  movl $\metadata, rA
  shll $8, rA
  andl $0x00ffffff, vA
  orl rA, vA
.endm
# ----------------------------------------------------------------------------
.macro from metadata
  movl $\metadata, rA
  movl memory(,rA,1), vA
.endm

.macro fromx metadata
  movl $\metadata, rA
  movl memory(,rA,1), vA
.endm

.macro from_ptr metadata
  movl $\metadata, rA
  movl memory(,rA,1), rA
  movl memory(,rA,1), vA
.endm

.macro from_ptr_pp metadata
  movl $\metadata, rC
  movl memory(,rC,1), rA
  addl $4, memory(,rC,1)
  movl memory(,rA,1), vA
.endm

.macro from_ptr_mm metadata
  movl $\metadata, rA
  movl memory(,rA,1), rC
  subl $4, rC
  movl rC, memory(,rA,1)
  movl memory(,rC,1), vA
.endm
# ----------------------------------------------------------------------------
.macro by metadata
  movl $\metadata, vX
.endm

.macro byx metadata
  movl $\metadata, vX
  movl $0x00800000, rC
  andl vX, rC
  jz 1f
    orl $0xff000000, vX
  1:
.endm

.macro bym metadata
  movl $\metadata, rA
  shll $8, rA
  andl $0x00ffffff, vX
  orl rA, vX
.endm

.macro by_at metadata
  movl $\metadata, rA
  movl memory(,rA,1), vX
.endm

.macro by_ptr metadata
  movl $\metadata, rA
  movl memory(,rA,1), rA
  movl memory(,rA,1), vX
.endm

.macro by_ptr_pp metadata
  movl $\metadata, rC
  movl memory(,rC,1), rA
  addl $4, memory(,rC,1)
  movl memory(,rA,1), vX
.endm

.macro by_ptr_mm metadata
  movl $\metadata, rA
  movl memory(,rA,1), rC
  subl $4, rC
  movl rC, memory(,rA,1)
  movl memory(,rC,1), vX
.endm
# ----------------------------------------------------------------------------
.macro to metadata
  movl $\metadata, rA
  movl vA, memory(,rA,1)
.endm

.macro to_ptr metadata
  movl $\metadata, rA
  movl memory(,rA,1), rA
  movl vA, memory(,rA,1)
.endm

.macro to_ptr_pp metadata
  movl $\metadata, rC
  movl memory(,rC,1), rA
  movl vA, memory(,rA,1)
  addl $4, memory(,rC,1)
.endm

.macro to_ptr_mm metadata
  movl $\metadata, rA
  movl memory(,rA,1), rC
  subl $4, rC
  movl rC, memory(,rA,1)
  movl vA, memory(,rC,1)
.endm
# ----------------------------------------------------------------------------
#                           ARITHMETIC INSTRUCTIONS
# ----------------------------------------------------------------------------
.macro add by metadata
  \by \metadata
  addl vX, vA
.endm
# ----------------------------------------------------------------------------
.macro sub by metadata
  \by \metadata
  subl vX, vA
.endm

# ----------------------------------------------------------------------------
.macro multi by metadata # FIXME broken
  \by \metadata
  mull vX, vA     # TODO consider limiting to 15-bit mul so cannot overflow
.endm
# ----------------------------------------------------------------------------
.macro div by metadata
  \by \metadata
  pushl vX        # untested
  movl vA, %eax
  movl vX, %ebx
  test %ebx, %ebx
  je 1f           # TODO consider what to do on /-1
  cdq             # MUST widen %eax here to %edx:eax or (neg) div wrong
  idivl %ebx      # %edx:eax is the implied dividend
  jmp 2f
  1: # Division by zero shall yield 0
    movl $0, vA
  2:
  movl %eax, vA
  popl vX
.endm
# ----------------------------------------------------------------------------
#                               BITWISE INSTRUCTIONS
# ----------------------------------------------------------------------------
.macro or by metadata
  \by \metadata
  orl vX, vA
.endm
# ----------------------------------------------------------------------------
.macro and by metadata
  \by \metadata
  andl vX, vA
.endm
# ----------------------------------------------------------------------------
.macro xor by metadata
  \by \metadata
  xorl vX, vA
.endm
# ----------------------------------------------------------------------------
.macro shl by metadata
  \by \metadata
  movl vX, rA
  movl rA, %ecx
  shll %cl, vA
.endm
# ----------------------------------------------------------------------------
.macro shr by metadata
  \by \metadata
  movl vX, rA
  movl rA, %ecx
  shrl %cl, vA
.endm
# ----------------------------------------------------------------------------
#                   JUMP INSTRUCTIONS maybe decleq
# ----------------------------------------------------------------------------
.macro jumprel baseAddr
  # A bit dicey
  leal \baseAddr(,vA,WORD_SIZE), %eax
  jmp *(%eax)
.endm

.macro jumpx by metadata
  \by \metadata
  jmp vX
.endm

.macro jump label
  leal \label, rA
  jmp rA
.endm

# This provides a nice bit-30 overflow-detection solution
.macro jmpo label
  leal \label, rA
  andl vA, $0x80000000
  jz positive
    andl vA, $0x40000000
    jnz ok
      jmp rA
  positive:
    andl vA, $0x40000000
    jz ok
      jmp rA \label
  ok:
.endm

.macro jmpz label
  leal \label, rA
  xorl $0, vA
  jnz 1f
    jmp rA
  1:
.endm

.macro jmpnz label
  leal \label, rA
  xorl $0, vA
  jz 1f
    jmp rA
  1:
.endm

.macro jmplz label
  leal \label, rA
  cmp $0, vA
  jge 1f
    jmp rA
  1:
.endm

.macro jmpgz label
  leal \label, rA
  cmp $0, vA
  jle 1f
    jmp rA
  1:
.endm

.macro jmplez label
  leal \label, rA
  cmp $0, vA
  jg 1f
    jmp rA
  1:
.endm

.macro jmpgez label
  leal \label, rA
  cmp $0, vA
  jl 1f
    jmp rA
  1:
.endm
# ----------------------------------------------------------------------------
#                            OTHER INSTRUCTIONS
# ----------------------------------------------------------------------------
.macro swap
  movl vA, rC
  movl vX, vA
  movl rC, vX
.endm

.macro nop
.endm

.macro halt by metadata
  \by \metadata
  movl vX, %eax
  jmp vm_success
.endm

# ============================================================================
.section .bss #                  VARIABLES
# ============================================================================
# For the meta-machine
memory: .lcomm mm, MM_BYTES

# ============================================================================
.section .text #             EXIT POINTS for the VM
# ============================================================================
vm_failure:

  movl $FAILURE, rA
  ret

vm_success:

  movl $SUCCESS, rA
  ret

# ============================================================================
# ============================================================================
# ========================= EXAMPLE PROGRAM ==================================
# ============================================================================
# ============================================================================
#                 EXAMPLE VARIABLES for an example program
# ============================================================================
.equ v_memory, 0
.equ rsp, v_memory + 16
.equ linkr, rsp + WORD_SIZE
.equ v_vA, linkr + WORD_SIZE
.equ v_vX, v_vA + WORD_SIZE
.equ v_pc, v_vX + WORD_SIZE
.equ instr, v_pc + WORD_SIZE

# ============================================================================
#   EXAMPLE MACROS for an example program (not part of the instruction set!)
# ============================================================================
.macro CALLING label
  lit 1f
  to_ptr_pp rsp
  jump \label
  1:
.endm

.macro RETURN
  jumpx by_ptr_mm rsp
.endm

.macro BRANCH label
  lit 1f
  to linkr
  jump \label
  1:
.endm

.macro MERGE
  jumpx by_at linkr
.endm

# ============================================================================
#                     ENTRY POINT for an example program
# ============================================================================
.global main
  main:
    halt by 0

# ============================================================================

