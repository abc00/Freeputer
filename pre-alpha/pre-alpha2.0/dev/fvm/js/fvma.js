/*
 * Copyright © 2017, Robert Gollagher.
 * SPDX-License-Identifier: GPL-3.0+
 * 
 * Program:    fvma.js
 * Author :    Robert Gollagher   robert.gollagher@freeputer.net
 * Created:    20170611
 * Updated:    20170611-1431+
 * Version:    pre-alpha-0.0.0.3 for FVM 2.0
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

// Module modFVMA will provide a Freeputer Assembler implementation.
var modFVMA = (function () { 'use strict';

  const DEF = '#def';
  const HERE = '.';
  const COMMENT = '//';

  class FVMA {
    constructor(fnMsg) {
      this.fnMsg = fnMsg;
      this.prgElems = new PrgElems();
      this.cmtLineNum = 0;
      this.inComment = false;
      this.dict = {};
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
      } else if (this.inCmt(lineNum)) {
      } else if (this.parseComment(token, lineNum)) {
      } else if (this.excectingDecl(token)) {
      } else if (this.parseDef(token)) {
      } else if (this.parseRef(token)) {
      } else if (this.parseHere(token)) {
      } else if (this.parseHex2(token)) {
      } else if (this.parseHex6(token)) {
      } else {
        throw lineNum + ":Unknown symbol:" + token;
      }
    };

    excectingDecl(token) {
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

    inCmt(lineNum) {
      if (lineNum == this.cmtLineNum){
        return true;
      } else {
        this.cmtLineNum = false;
        return false;
      }      
    }

    parseComment(token, lineNum) {
      if (token === COMMENT){
        this.cmtLineNum = lineNum;
        this.inComment = true;
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

    parseHere(token) {
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

  };

  class PrgElems {
    constructor() {
      this.cursor = 0;
      this.elems = [];
    };

    addElem(n) {
      this.cursor = this.elems.push(n);
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
