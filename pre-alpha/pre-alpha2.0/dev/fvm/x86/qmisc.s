/*
             QUALITY MINIMAL INSTRUCTION SET COMPUTER (QMISC)


Copyright © 2017, Robert Gollagher.
SPDX-License-Identifier: GPL-3.0+

Program:    qmisc.s
Author :    Robert Gollagher   robert.gollagher@freeputer.net
Created:    20170826
Updated:    20170826+
Version:    pre-alpha-0.0.0.4 for FVM 2.0
=======

                              This Edition:
                          x86 Assembly Language
                           using GNU Assembler
                            for 32-bit Linux

                               ( ) [ ] { }

 See 'qmisc.c'. This an x86 implementation of that earlier proof of concept.

==============================================================================
                            BUILDING FOR i386
==============================================================================

You may need gcc-multilib installed.

When linking with gcc for debugging, build with:

  as -g --gstabs -o qmisc.o qmisc.s --32
  gcc -o qmisc qmisc.o -m32

When linking with gcc for release, build with:

  as -o qmisc.o qmisc.s --32
  gcc -o qmisc qmisc.o -m32

When LINKING_WITH_LD_ON_LINUX without any imports, build with:

  as -o qmisc.o qmisc.s --32
  ld -o qmisc qmisc.o -m elf_i386

Or for convenience, build with:

  ./build.sh

Or for convenience, build and run with:

  ./go.sh

==============================================================================
 WARNING: This is pre-alpha software and as such may well be incomplete,
 unstable and unreliable. It is considered to be suitable only for
 experimentation and nothing more.
============================================================================*/
# ============================================================================
#                                IMPORTS
# ============================================================================
.extern printf
# ============================================================================
#                                SYMBOLS
# ============================================================================
.equiv TRACING_ENABLED, 1           # 0 = true, 1 = false
.equiv LINKING_WITH_LD_ON_LINUX, 1  # 0 = true, 1 = false

.equ WD_BYTES, 4
.equ ONES,          0xffffffff
.equ MSb,           0x80000000  # Bit mask for most significant bit
.equ METADATA_MASK, 0x7fffffff  # 31 bits
.equ BYTE_MASK,     0x000000ff
.equ SHIFT_MASK,    0x0000001f
.equ SUCCESS, 0
.equ FAILURE, 1
.equ ILLEGAL, 2
.equ MAX_DM_WORDS,  0x10000000  # Must be 2^(WD_BITS-4) due to C limitations.
.equ DM_WORDS, MAX_DM_WORDS     # Must be some power of 2 <= MAX_DM_WORDS.
.equ DM_BYTES, DM_WORDS*WD_BYTES
.equ DM_MASK, DM_WORDS-1
# There are only 4 accessible registers:
.equ vA, %eax; # accumulator
.equ vB, %ebx; # operand register
.equ vT, %edx; # temporary register
.equ vR, %esi; # repeat register
.equ vL, %edi; # link register (not accessible)
.equ rSwap, %ecx; # swap register (not accessible) (sometimes reused here)
.equ rShift, %cl; # register used for shift magnitude (not accessible)
# ============================================================================
# ==================== START OF PLATFORM-SPECIFIC CODE =======================
# ============================================================================
.macro do_exit reg_vA
  .ifeq LINKING_WITH_LD_ON_LINUX
    movl \reg_vA, %ebx          # Exit code (status)
    movl $0x1, %eax             # Linux call ID for exit
    int $0x80                   # Linux interrupt for system call
  .else
    movl \reg_vA, %eax         # Exit code (status)
    ret
  .endif
.endm
.macro do_success
  movl $SUCCESS, vA
  do_exit vA
.endm
.macro do_failure
  movl $FAILURE, vA
  do_exit vA
.endm
.macro do_illegal
  movl $ILLEGAL, vA
  do_exit vA
.endm
.macro do_init
  xorl vA, vA
  xorl vB, vB
  xorl vT, vT
  xorl vR, vR
  xorl vL, vL
  xorl rSwap, rSwap
.endm
.macro i_add
  addl vB, vA
.endm
.macro i_sub
  subl vB, vA
.endm
.macro i_or
  orl vB, vA
.endm
.macro i_and
  andl vB, vA
.endm
.macro i_xor
  xorl vB, vA
.endm
.macro i_shl
  movl vB, rSwap
  andl $SHIFT_MASK, rSwap
  shll rShift, vA
.endm
.macro i_shr
  movl vB, rSwap
  andl $SHIFT_MASK, rSwap
  shrl rShift, vA
.endm
.macro i_get
  movl vB, vSwap
  andl DM_MASK, vSwap
  movl data_memory(,vSwap,WD_BYTES), vA
.endm
.macro i_put
  movl vB, vSwap
  andl DM_MASK, vSwap
  movl vA, data_memory(,vSwap,WD_BYTES)
.endm
.macro i_at
  movl vB, vSwap
  andl DM_MASK, vSwap
  movl data_memory(,vSwap,WD_BYTES), vB
.endm
.macro i_inc
  incl vB
.endm
.macro i_dec
  decl vB
.endm
.macro i_imm x
  movl $\x, vB
  andl $METADATA_MASK, vB
.endm
.macro i_flip
  xorl $MSb, vB
.endm
.macro i_swap
  movl vA, rSwap
  movl vB, vA
  movl rSwap, vB
.endm
.macro i_tob
  movl vA, vB
.endm
.macro i_tot
  movl vA, vT
.endm
.macro i_tor
  movl vA, vR
.endm
.macro i_fromb
  movl vB, vA
.endm
.macro i_fromt
  movl vT, vA
.endm
.macro i_fromr
  movl vR, vA
.endm
.macro i_mdm
  movl DM_WORDS, vA
.endm
.macro i_nop
  nop
.endm
.macro i_halt
  andl BYTE_MASK, vA
.endm
.macro i_jmpe label
  cmpl vB, vA
  jne 1f
    jmp \label
  1:
.endm
.macro i_jump label
  jmp \label
.endm
.macro i_rpt label
  decl vR
  cmpl $ONES, vR
  jz 1f
    leal \label, rSwap
    jmp *rSwap
  1:
.endm
.macro i_br label
  leal \label, vL
  jmp *vL
.endm
.macro i_link label
  jmp *vL
.endm
# ============================================================================
# ====================== END OF PLATFORM-SPECIFIC CODE =======================
# ============================================================================
# ============================================================================
.section .data #                CONSTANTS
# ============================================================================
.ifeq TRACING_ENABLED
  pntfmt: .asciz "\nPARENT: vA:%08x vB:%08x vT:%08x vR:%08x "
  format_hex8: .asciz "%08x"
  newline: .asciz "\n"
  space: .asciz " "
.endif
# ============================================================================
#                            INSTRUCTION SET
# ============================================================================
.macro add
  i_add
.endm
.macro sub
  i_sub
.endm
.macro or
  i_or
.endm
.macro and
  i_and
.endm
.macro xor
  i_xor
.endm
.macro shl
  i_shl
.endm
.macro shr
  i_shr
.endm
.macro get
  i_get
.endm
.macro put
  i_put
.endm
.macro at
 i_at
.endm
.macro inc
  i_inc
.endm
.macro dec
  i_dec
.endm
.macro imm x
  i_imm \x
.endm
.macro flip
  i_flip
.endm
.macro swap
  i_swap
.endm
.macro tob
  i_tob
.endm
.macro tor
  i_tor
.endm
.macro tot
  i_tot
.endm
.macro fromb
  i_fromb
.endm
.macro fromt
  i_fromt
.endm
.macro fromr
  i_fromr
.endm
.macro mdm
  i_mdm
.endm
.macro noop
  i_nop
.endm
.macro halt
  i_halt
.endm
.macro jmpe label
  i_jmpe \label
.endm
.macro jump label
  i_jump \label
.endm
.macro rpt label
  i_rpt \label
.endm
.macro br label
  i_br \label
.endm
.macro link
  i_link
.endm
# ============================================================================
.section .bss #                  VARIABLES
# ============================================================================
data_memory: .lcomm dm, DM_BYTES
# ============================================================================
#                                 TRACING
# ============================================================================
.ifeq TRACING_ENABLED
  .macro TRACE_PAR
    SAVE_REGS
    pushl vR
    pushl vT
    pushl vB
    pushl vA
    pushl $pntfmt
    call printf
    addl $20, %esp
    RESTORE_REGS
  .endm

  .macro TRACE_STR strz
    SAVE_REGS
    pushl \strz
    call printf
    addl $4, %esp
    RESTORE_REGS
  .endm

  .macro TRACE_HEX8 rSrc
    SAVE_REGS
    pushl %eax
    pushl \rSrc
    pushl $format_hex8
    call printf
    addl $8, %esp
    popl %eax
    RESTORE_REGS
  .endm

  .macro SAVE_REGS
    pushal
  .endm

  .macro RESTORE_REGS
    popal
  .endm
.endif
# ============================================================================
.section .text #           EXIT POINTS for the VM
# ============================================================================
vm_success:
  do_success
vm_failure:
  do_failure
vm_illegal:
  do_illegal
# =========================== EXAMPLE PROGRAM ================================
# Example: to be a small QMISC FW32 implementation (vm_ = parent, v_ = child)
# ============================================================================

# ============================================================================
#                      ENTRY POINT FOR EXAMPLE PROGRAM
# ============================================================================
.ifeq LINKING_WITH_LD_ON_LINUX
  .global _start
  _start:
.else
  .global main
  main:
.endif

vm_init:
  do_init

# For native parent VM speed comparison (1.4 secs for 0x7fffffff nop repeats):
imm 0x7fffffff
fromb
tor
foo:
.ifeq TRACING_ENABLED
  TRACE_PAR
.endif
  noop
  rpt foo

.ifeq TRACING_ENABLED
  TRACE_PAR
.endif

jmp vm_success
# ============================================================================
