/*
 * Copyright © 2017, Robert Gollagher.
 * SPDX-License-Identifier: GPL-3.0+
 * 
 * Program:    fvma.js
 * Author :    Robert Gollagher   robert.gollagher@freeputer.net
 * Created:    20170611
 * Updated:    20170615-0733+
 * Version:    pre-alpha-0.0.0.5 for FVM 2.0
 *
 *                     This Edition of the Assembler:
 *                                JavaScript
 *                           for HTML 5 browsers
 * 
 *                                ( ) [ ] { }
 *
 * ===========================================================================
 * 
 * WARNING: This is pre-alpha software and as such may well be incomplete,
 * unstable and unreliable. It is considered to be suitable only for
 * experimentation and nothing more.
 * 
 * ===========================================================================
 *
 */

/*
Design notes:

  - assembler is intended to be minimum required for bootstrapping higher languages later
  - assembler design is intended for extemely minimal memory use (few kB) and extreme simplicity
  - reason for this is to achieve extreme hardware freedom (e.g. develop on a microcontroller)
  - remove anything not reasonably essential (YAGNI)
  - there is a reasonable argument for going smaller, perhaps PRG should be 64 kB and then compose multiple instances?

Thus:

  - all symbols except opcode are in effect an encoded word (and might add simple namespacing later)
  - preprocessor could be added later for more human-readable convenience but not essential

Next:

  - implement forward references and think more about labels in general (keeping it to a mimimum)
  - consider eliminating all other definitions except labels and just using \foo approach instead!
  - but take into account possible slot management
  - are forward decls worthwhile?
  - possibly nop strategy

*/

// Module modFVMA will provide a Freeputer Assembler implementation.
var modFVMA = (function () { 'use strict'; // TODO consider adding slot management

  const DEF = '#def';
  const HERE = '.';
  const COMSTART = '(';
  const COMEND = ')';
  const COMWORD= '/';
  const OPCODES = {
    nop: 0x00,
    lit: 0x01,
    jmp: 0x03,
    hal: 0xff
  };

  class FVMA {
    constructor(fnMsg) {
      this.fnMsg = fnMsg;
      this.prgElems = new PrgElems();
      this.inComment = false;
      this.dict = OPCODES;
      this.expectDecl = false;
      this.expectDef = false;
      this.Decl = "";
    };

    asm(str) { // FIXME no enforcement yet
      this.fnMsg('Parsing...');
      var lines = str.split(/\n/);
      try {
        for (var i = 0; i < lines.length; i++) {
          this.parseLine(lines[i], i+1);
        }
        this.fnMsg(this.prgElems);
        this.fnMsg('Melding...');
        this.prgElems.meld();
        this.fnMsg(this.prgElems);
        this.fnMsg('Dictionary...');
        this.fnMsg(JSON.stringify(this.dict));
        return this.prgElems.toBuf();
      } catch (e) {
        this.fnMsg(e);
      }
    };

    parseLine(line, lineNum) {
      // Tokens are separated by any whitespace. Tokens contain no whitespace.
      var tokens = line.split(/\s+/).filter(x => x.match(/\S+/));
      tokens.forEach(token => this.parseToken(token,lineNum), this);
    }

    use(x) {
      if (this.expectDef) {
        if (x === HERE) {
          this.dict[this.decl] = this.prgElems.cursor / 2;
        } else {
          this.dict[this.decl] = x;
        }
        this.decl = "";
        this.expectDef = false;
      } else {
        this.prgElems.addElem(x);
      }
    }

    parseToken(token, lineNum) {
      if (false) {
      } else if (this.inCmt(token)) {
      } else if (this.parseComment(token, lineNum)) {
      } else if (this.parseComword(token, lineNum)) {
      } else if (this.expectingDecl(token, lineNum)) {
      } else if (this.parseForw(token)) {
      } else if (this.parseBackw(token)) {
      } else if (this.parseDef(token)) {
      } else if (this.parseRef(token)) {
      } else if (this.parseHere(token)) {
      } else if (this.parseHex2(token)) {
      } else if (this.parseHex6(token)) {
      } else {
        throw lineNum + ":Unknown symbol:" + token;
      }
    };

    expectingDecl(token, lineNum) {
      if (this.expectDecl) {
        if (this.dict[token]) {
          throw lineNum + ":Already defined:" + token;
        } else {
          this.decl = token;
          this.expectDecl = false;
          this.expectDef = true;
        }
        return true;
      }
      return false;
    }

    inCmt(token, lineNum) {
        if (this.inComment) {
          if (token == COMEND){
            this.inComment = false;
          }
          return true;
        } else {
          if (token == COMEND){
            throw lineNum + ":Not permitted here:" + token;
          }
          return false;
        }     
    }

    parseComment(token, lineNum) {
      if (token === COMSTART){
        this.inComment = true;
        return true;
      } else {
        return false;
      }      
    }

    parseComword(token, lineNum) {
      if (token.startsWith(COMWORD)) {
        return true;
      } else {
        return false;
      }
    }

    parseDef(token) {
      if (token === DEF){
        this.expectDecl = true;
        return true;
      } else {
        return false;
      }      
    }

    parseRef(token) {
      if (this.dict[token] >= 0){
        this.use(this.dict[token]);
        return true;
      } else {
        return false;
      }      
    }

    parseHere(token, lineNum) {
      if (token === HERE){
        if (this.expectDef) {
          this.use(token);
        } else {
          throw lineNum + ":Not permitted here:" + token;
        }
        return true;
      } else {
        return false;
      }      
    }

    parseHex2(token) {
      if (token.length == 4 && token.match(/0x[0-9a-f]{2}/)){
        var n = parseInt(token,16);
        this.use(n);
        return true;
      } else {
        return false;
      }      
    }

    parseHex6(token) {
      if (token.length == 8 && token.match(/0x[0-9a-f]{6}/)){
        var n = parseInt(token,16);
        this.use(n);
        return true;
      } else {
        return false;
      }      
    }

    parseForw(token) { // TODO check overflow or out of bounds and endless loop
      if (token.length == 8 && token.match(/0f[0-9a-f]{6}/)){
        var asHex = token.replace('0f','0x');
        var n = parseInt(token,16);
        var m = this.prgElems.cursor/2 + n;
        this.use(m);
        return true;
      } else {
        return false;
      }      
    }

    parseBackw(token) { // TODO check overflow or out of bounds and endless loop
      if (token.length == 8 && token.match(/0r[0-9a-f]{6}/)){
        var asHex = token.replace('0r','0x');
        var n = parseInt(token,16);
        var m = this.prgElems.cursor/2 - n -1;
        this.use(m);
        return true;
      } else {
        return false;
      }      
    }

  };

  class PrgElems {
    constructor() {
      this.cursor = 0;
      this.elems = [];
    };

    addElem(n) {
      this.cursor = this.elems.push(n);
    }

    topElem() {
      return this.elems[-1];
    }

    meld() {
      var melded = [];
      for (var i = 0; i < this.elems.length-1; i=i+2) {
        melded.push(this.elems[i] + (this.elems[i+1] << 8));
      }
      this.elems = melded;
    }

    toBuf() {
      return new Uint32Array(this.elems).buffer;
    }

    toString() {
      var str = ":";
      this.elems.forEach(x => str = str + modFmt.hex8(x) + ":");
      return str;
    }

  };

  return {
    makeFVMA: function(fnMsg) {
      return new FVMA(fnMsg);
    }
  };

})(); // modFVMA

