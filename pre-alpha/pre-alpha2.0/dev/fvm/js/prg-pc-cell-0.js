var prgSrc = `
/*
  Copyright 2017, Robert Gollagher.
  SPDX-License-Identifier: GPL-3.0+

  Program:    prg.js (also known as 'prg.c')
  Author :    Robert Gollagher   robert.gollagher@freeputer.net
  Created:    20170911
  Updated:    20180410+
  ------------------
  FREE: 
  LAST SYMBOL: g6
  ------------------

  NOTES:

  - Radical experiment has partially begun: generic stacks (see far below).

  - This is written in an assembly language which aims to be C-compatible.
  - This is a demonstration program for FVM2 pre-alpha (see 'fvm2.js').
  - The assembler is very simplistic (see 'fvma.js') and uses little memory.
  - m0.x0 is the only forward reference the assembler allows
  - x symbols are exported from a module (e.g. x0 in m1 is m1.x0)
  - u symbols are local to a module (u0..uff)
  - s symbols are local to a unit (s0..sff)
  - Units begin with u{ and end with }u
  - Modules begin with m{ and end with }m
  - Modules are named by mod(m1)
  - The C-preprocessor would replace u{ with { __label__ s0, s1 ...
  - TODO Enforce use of u{ keyword prior to any locals
  - See 'fvma.js' for further caveats

*/

m{ mod(m1) /*forward*/ jump(m0.x0) }m

m{ mod(m2) /*incs*/

  // ( n1 -- n2 ) doIncs
  // Increment n1 times to give the number of increments n2.
  // This is only to test that the VM is working correctly. 
  u{ x1: cpush lit(0x0) s0: inc rpt(s0) ret }u

  // ( -- 0x100000 ) doManyIncs
  // Do 1,048,576 increments to test VM performance.
  // Temporarily disable tracing while doing so.
  // See browser console for timer output.
  u{ x2: lit(0x100000) troff call(x1) /*doIncs*/ tron ret }u

}m

m{ mod(m3) /*io*/

  // ( n -- ) send
  // Output n to stdout or fail if not possible.
  u{ s0: fail x1: out(s0) ret }u

  // ( -- ) sendA
  // Output 'A' to stdout
  u{ x2: lit(0x41) call(x1) /*send*/ ret }u

  // ( n -- ) nInOut
  // Output to stdout no more than n characters from stdin.
  u{ s0: fail u1: cpush s1: in(s0) call(x1) /*send*/ rpt(s1) ret }u

  // ( -- ) max9InOut
  // Output to stdout no more than 9 characters from stdin.
  u{ x3: lit(0x9) call(u1) /*nInOut*/ ret }u

}m

// Testing remapping of module names -----------------------------------------
m{ mod(m4) /*foo*/

  // ( -- ) banana
  u{ x1: nop ret }u

  // ( -- ) nopHalt
  u{ x2: nop halt }u

}m

m{ mod(m5) /*bar*/

  // ( -- ) peach
  u{ x1: call(m4.x1) /*foo.banana*/ ret }u

}m
// ---------------------------------------------------------------------------

m{ mod(m0) /*run*/

  u{
    x0:

      sp(0x100) // Radical experiment
      lit(0x12345678)

/*

The following result in the same flow control. A simple jump:

      jump(m4.x2)

Or jumping by copying the destination address into cell 0 (i.e. the PC):

      lit(0x0)
      lit(m4.x2)
      put

*/

      lit(0x0)
      lit(m4.x2)
      put


      halt

      // TODO NEXT: add another instruction rp(0x200), to declare
      // the location of the return stack. Thereafter the sp() and rp()
      // instructions can be used to generically use multiple
      // stacks programmatically within the VM without
      // requiring the VM implementation itself to
      // provide any fixed number of stacks.


      lit(0x3) call(m2.x1) /*incs.doIncs*/    // Do 3 increments
      lit(0x41) add call(m3.x1) /*io.send*/   // Output 'D' by addition
      call(m5.x1) /*bar.peach*/
      halt
  }u

}m

`;
