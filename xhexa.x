
val put            = 1;
val get            = 2;
||
val instream       = 0;
val messagestream  = 0;
val binstream      = 2 << 8;
||
val EOF           = 255;
||
| tree node field selectors |
val t_op          = 0;
val t_op1         = 1;
val t_op2         = 2;
val t_op3         = 3;
||
| symbols |
val s_null        = 0;
val s_name        = 1;
val s_number      = 2;
val s_lbracket    = 3; 
val s_rbracket    = 4;
val s_lparen      = 6;
val s_rparen      = 7;
||
val s_fncall      = 8;
val s_pcall       = 9;
val s_if          = 10;
val s_then        = 11;
val s_else        = 12;
val s_while       = 13;
val s_do          = 14;
val s_ass         = 15;
val s_skip        = 16;
val s_begin       = 17;
val s_end         = 18;
val s_semicolon   = 19;
val s_comma       = 20;
val s_var         = 21;
val s_array       = 22;
val s_body        = 23;
val s_proc        = 24;
val s_func        = 25;
val s_is          = 26;
val s_stop        = 27;
||
val s_not         = 32;
val s_neg         = 34;
val s_val         = 35;
val s_string      = 36;
||
val s_true        = 42;
val s_false       = 43;
val s_return      = 44;
||
val s_endfile     = 60;
||
val s_diadic      = 64;
||
val s_plus        = s_diadic + 0;
val s_minus       = s_diadic + 1;
val s_or          = s_diadic + 5;
val s_and         = s_diadic + 6;
||
val s_eq          = s_diadic + 10;
val s_ne          = s_diadic + 11;
val s_ls          = s_diadic + 12;
val s_le          = s_diadic + 13;
val s_gr          = s_diadic + 14;
val s_ge          = s_diadic + 15;
||
val s_sub         = s_diadic + 16;
||
| up instruction codes |
val i_ldam        = #0;
val i_ldbm        = #1;
val i_stam        = #2;

val i_ldac        = #3;
val i_ldbc        = #4;
val i_ldap        = #5;

val i_ldai        = #6; 
val i_ldbi        = #7;
val i_stai        = #8;

val i_br          = #9;
val i_brz         = #A; 
val i_brn         = #B;

val i_bra         = #C;

val i_add         = #D;
val i_sub         = #E;

val i_pfix        = #F;
val i_nfix        = #F;
||
val r_areg        = 0;
val r_breg        = 1;
||
val bytesperword  = 4;
||
| lexical analyser |
val linemax = 200;
val nametablesize = 128;
array nametable[nametablesize];
val nil = 0;
val hashmask = 127;
||

var outstream;
||
val treemax = 20000;
array tree[treemax];
var treep;

var namenode;
var nullnode;
var zeronode;
var numval;

var symbol;
||
array wordv[100];
var wordp;
var wordsize;
||
array charv[100];
var charp;
var ch;
||
array linev[linemax];
var linep;
var linelength;
var linecount;
||
| name scoping stack |
array names_d[500];
array names_v[500];

var namep;
var nameb;

val pflag = #1000;
||

var arrayspace;
var arraycount;

var codesize;

var procdef;
var proclabel;
var infunc;
||
var stackp;
var stk_max;
| constants, strings and labels |
array consts[500];
var constp;
||
array strings[1000];
var stringp;
||
val labval_size  = 1000;
array labval[labval_size];
var labelcount; 
||
val cb_size      = 15000;
||
| code buffer flags |
val cbf_inst     = 1;

val cbf_lab      = 2;
val cbf_fwdref   = 3; 
val cbf_bwdref   = 4;

val cbf_stack    = 5;

val cbf_const    = 6;
val cbf_string   = 7;
val cbf_entry    = 8;
val cbf_pexit    = 9;
val cbf_fnexit   = 10;

val cbf_var      = 11;

||
| code buffer variables |
array codebuffer[cb_size];
var cb_bufferp;
var cb_loadbase;
var cb_entryinstp;
var cb_blockstart;
var cb_loadpoint;
var cb_conststart;
var cb_stringstart;

var entrylab;

||
val maxaddr      = 0;

proc main() is
  var t;
{ 
  selectoutput(messagestream);  

  t := formtree();

  prints("tree size: "); printn(treep); newline(); 
  
  translate(t);

  prints("program size: "); printn(codesize); newline();
  
  prints("size: "); printn(codesize + (arrayspace << 2)); newline()

}

proc selectoutput(val c) is outstream := c

proc putval(val c) is put(c, outstream)

proc newline() is putval('\n')

func times(val n, val m) is
  var i;
  var j;
  var r;
{ i := n;
  j := m;
  r := 0;
  while j ~= 0 do
  { r := r + (i and ((j and 1) ~= 0));
    j := j >> 1;
    i := i << 1
  };
  return r
}

func div(val n, val m) is
  var i;
  var j;
  var b;
  var r;
{ i := m;
  j := n >> 1;
  b := 1;
  r := 0;
  while i <= j do
  { i := i << 1;
    b := b << 1
  };
  j := n;
  while b > 0 do
  { if j >= i
    then
    { r := r or b;
      j := j - i
    }
    else
      skip;
    i := i >> 1;
    b := b >> 1
  };
  return r
}

func rem(val n, val m) is
  return (n - times(div(n, m), m))
  
func packstring(array s, array v) is 
  var n;
  var si;
  var vi;
  var w;
  var b;
{ n := s[0];
  si := 0;
  vi := 0;
  b := 0;
  w := 0;
  while si <= n do
  { w :=  w or (s[si] << (b<<3));
    b := b + 1;
    if (b = bytesperword) 
    then
    { v[vi] := w;
      vi := vi + 1;
      w := 0;
      b := 0  
    }
    else skip;
    si := si + 1
  };  
  if (b = 0)
  then
    vi := vi - 1
  else
    v[vi] := w; 
  return vi
}
  
proc unpackstring(array s, array v) is
  var si;
  var vi;
  var b;
  var w;
  var n;
{ si := 0;
  vi := 0;
  b := 0;
  w := s[0];
  n := w and 255;
  while vi <= n do
  { v[vi] := w and 255;
    w := w >> 8;
    vi := vi + 1;
    b := b + 1;
    if b = bytesperword 
    then 
    { b := 0;
      si := si + 1; 
      w := s[si]
    }
    else skip  
  }
}

proc prints(array s) is
  var n;
  var p;
  var w;
  var l;
  var b;
{ n := 1;
  p := 0;
  w := s[p];
  l := w and 255;
  w := w >> 8;   
  b := 1;
  while (n <= l) do 
  { putval(w and 255);
    w := w >> 8; 
    n := n + 1;
    b := b + 1;
    if (b = bytesperword)
    then
    { b := 0;
      p := p + 1;
      w := s[p]
    }
    else skip
  }  
}

proc printn(val n) is
{ if n < 0 
  then
  { putval('-');
    printn(-n)
  }
  else
  { if n > 9 
    then 
      printn(div(n, 10)) 
    else skip;
    putval(rem(n, 10) + '0')
  }
}

proc printhex(val n) is
  var d;
{ if (n and (~ 15)) = 0 then skip else printhex(n >> 4);
  d := n and 15;
  if d < 10 
  then putval(d + '0')
  else putval((d - 10) + 'a')
}

func formtree() is
  var i;
  var t;
  
{ linep := 0;
  wordp := 0;
  charp := 0;

  treep := 1;

  i := 0;
  while i < nametablesize do
  { nametable[i] := nil;
    i := i + 1    
  };

  declsyswords();

  nullnode := cons1(s_null);

  zeronode := cons2(s_number, 0);

  linecount := 0;
  
  rdline();
  rch();
   
  nextsymbol();
 
  if (symbol = s_var) or (symbol = s_val) or (symbol = s_array)
  then 
    t := rgdecls()
  else
    t := nullnode;
  
  return cons3(s_body, t, rprocdecls())
}  
 
proc cmperror(array s) is 
{ prints("error near line ");
  printn(linecount); prints(": ");
  prints(s);
  newline() 
}

| tree node constructors |

func newvec(val n) is 
  var t;
{ t := treep
; treep := treep + n
; if treep > treemax then cmperror("out of space") else skip
; return t
}

func cons1(val op) is
  var t;
{ t := newvec(1)
; tree[t] := op
; return t
}

func cons2(val op, val t1) is
  var t;
{ t := newvec(2);
  tree[t] := op;
  tree[t+1] := t1;
  return t
}

func cons3(val op, val t1, val t2) is
  var t;
{ t := newvec(3);
  tree[t] := op;
  tree[t+1] := t1;
  tree[t+2] := t2;
  return t
}

func cons4(val op, val t1, val t2, val t3) is
  var t;
{ t := newvec(4);
  tree[t] := op;
  tree[t+1] := t1;
  tree[t+2] := t2;
  tree[t+3] := t3;
  return t
}

| name table lookup |

func lookupword() is
  var a;
  var hashval;
  var i;
  var stype;
  var found;
  var searching;
{ a := wordv[0];
  hashval := ((a+(a>>3))+(wordv[wordsize]<<2)) and hashmask;
  namenode := nametable[hashval];
  found := false;
  searching := true;
  while searching do
  { if namenode = nil
    then 
    { found := false;
      searching := false
    }
    else
    { i := 0;
      while (i <= wordsize) and (tree[(namenode+i)+2] = wordv[i]) do
        i := i + 1;
      if i <= wordsize
      then 
        namenode := tree[namenode + 1]
      else 
      { stype := tree[namenode];
        found := true;
        searching := false
      }
    }   
  };
  if found
  then
    skip
  else
  { namenode := newvec(wordsize+3);
    tree[namenode] := s_name;
    tree[namenode+1] := nametable[hashval];
    i := 0;
    while i <= wordsize do 
    { tree[(namenode+i)+2] := wordv[i];
      i := i + 1
    };
    nametable[hashval] := namenode;
    stype := s_name   
  };
  return stype
}


proc declare(array s, val item) is
{ unpackstring(s, charv);
  wordsize := packstring(charv, wordv);
  lookupword();
  tree[namenode] := item
}

proc declsyswords() is
{ declare("and", s_and);
  declare("array", s_array);
  declare("do", s_do);
  declare("else", s_else);
  declare("false", s_false);
  declare("func", s_func);
  declare("if", s_if);
  declare("is", s_is);
  declare("or", s_or);
  declare("proc", s_proc);
  declare("return", s_return);
  declare("skip", s_skip);
  declare("stop", s_stop);
  declare("then", s_then);
  declare("true", s_true);
  declare("val", s_val);
  declare("var", s_var);
  declare("while", s_while)
 }  

func getchar() is 
  return get(instream)

proc rdline() is
{ linelength := 1;
  linep := 1;
  linecount := linecount + 1;
  ch := getchar();
  linev[linelength] := ch;
  while (ch ~= '\n') and (ch ~= EOF) and (linelength < linemax) do
  { ch := getchar();
    linelength := linelength + 1;
    linev[linelength] := ch
  }  
}

proc rch() is
{ if (linep > linelength) then rdline() else skip; 
  ch := linev[linep];
  linep := linep + 1
}

proc rdtag() is
{ charp := 0;
  while ((ch>='A') and (ch<='Z')) or ((ch>='a') and (ch<='z')) or ((ch>='0') and (ch<='9')) or (ch = '_') do 
  { charp := charp + 1;
    charv[charp] := ch;
    rch()
  };
  charv[0] := charp;
  wordsize := packstring(charv, wordv)
}

proc readnumber(val base) is
  var d; 
{ d := value(ch);
  numval := 0;
  if (d >= base) then
    cmperror("error in number")
  else
    while (d < base) do
    { numval := times(numval, base) + d;
      rch();
      d := value(ch)
    }
}

func value(val c) is
  if (c >= '0') and (c <= '9')
  then
    return c - '0' 
  else
  if (c >= 'A') and (c <= 'Z')
  then
    return (c + 10) - 'A'
  else
    return 500

func readcharco() is
  var v;
{ if (ch = '\\')
  then
  { rch();
    if (ch = '\\')
    then 
     v := '\\'
    else
    if (ch = '\'')
    then
      v := '\''
    else
    if (ch = '\"')
    then
      v := '\"' 
    else
    if (ch = 'n')
    then
      v := '\n'
    else 
    if (ch = 'r')
    then 
      v := '\r'
    else
      cmperror("error in character constant")
  }
  else
    v := ch;
  rch();
  return v
}

proc readstring() is
  var charc;
{ charp := 0;
  while (ch ~= '\"') do
  { if (charp = 255)
    then cmperror("error in string constant")
    else skip;
    charc := readcharco();
    charp := charp + 1;
    charv[charp] := charc
  };
  charv[0] := charp;
  wordsize := packstring(charv, wordv)
}

| lexical analyser main procedure | 

proc nextsymbol() is
{ while (ch = '\n') or (ch = '\r') or (ch = ' ') do
     rch();   
  if (ch = '|') 
  then
  { rch();
    while (ch ~= '|') do
      rch(); 
    rch();
    nextsymbol()
  }
  else
  if ((ch >= 'A') and (ch <= 'Z')) or ((ch >= 'a') and (ch <= 'z')) 
  then
  { rdtag();
    symbol := lookupword()
  }
  else
  if (ch >= '0') and (ch <= '9')
  then
  { symbol := s_number;
    readnumber(10)
  }
  else
  if (ch = '#')
  then
  { rch();
    symbol := s_number;
    readnumber(16)
  }
  else 
  if (ch = '[')
  then 
  { rch();
    symbol := s_lbracket
  }  
  else 
  if (ch = ']')
  then
  { rch();
    symbol := s_rbracket
  }  
  else 
  if (ch = '(')
  then
  { rch();
    symbol := s_lparen
  }  
  else 
  if (ch = ')')
  then 
  { rch();
    symbol := s_rparen
  }  
  else 
  if (ch = '{')
  then
  { rch();
    symbol := s_begin
  }  
  else 
  if (ch = '}')
  then
  { rch();
    symbol := s_end
  }  
  else 
  if (ch = ';')
  then
  { rch();
    symbol := s_semicolon
  }  
  else 
  if (ch = ',')
  then
  { rch();
    symbol := s_comma
  }  
  else 
  if (ch = '+')
  then
  { rch();
    symbol := s_plus
  }  
  else 
  if (ch = '-')
  then
  { rch();
    symbol := s_minus
  }  
  else 
  if (ch = '=')
  then
  { rch();
    symbol := s_eq
  }  
  else
  if (ch = '<')
  then
  { rch();
    if (ch = '=')
    then
    { rch();
      symbol := s_le
    }
    else
      symbol := s_ls
  }  
  else
  if (ch = '>')
  then
  { rch();
    if (ch = '=')
    then
    { rch();
      symbol := s_ge
    }
    else
      symbol := s_gr
  }  
  else 
  if (ch = '~')
  then
  { rch();
    if (ch = '=')
    then
    { rch();
      symbol := s_ne
    }
    else
      symbol := s_not
  }  
  else
  if (ch = ':')
  then
  { rch();
    if (ch = '=')
    then
    { rch();
      symbol := s_ass
    }
    else
      cmperror("\'=\' expected")
  }  
  else
  if (ch = '\'')
  then
  { rch();
    numval := readcharco();
    if (ch = '\'')
    then
      rch()
    else
      cmperror("error in character constant");      
    symbol := s_number
  }
  else
  if (ch = '\"')
  then
  { rch();
    readstring();
    if (ch = '\"')
    then
      rch()
    else
      cmperror("error in string constant");      
    symbol := s_string
  }   
  else
  if (ch = EOF)
  then
    symbol := s_endfile
  else
    cmperror("illegal character")
}

| syntax analyser |

proc checkfor(val s, array m) is
  if symbol = s
  then
    nextsymbol()
  else
    cmperror(m) 

func rname() is
  var a;
{ if symbol = s_name
  then
  {  a := namenode;
     nextsymbol()
  }
  else 
    cmperror("name expected");
  return a
}
  
func relement() is 
  var a;
  var b;
  var i;
{ if (symbol = s_name)
  then
  { a := rname();
    if (symbol = s_lbracket)
    then
    { nextsymbol(); 
      b := rexpression(); 
      checkfor(s_rbracket, "\']\' expected"); 
      a := cons3(s_sub, a, b)
    }
    else
    if (symbol = s_lparen)
    then
    { nextsymbol();
      if (symbol = s_rparen)
      then
        b := nullnode 
      else
        b := rexplist();
      checkfor(s_rparen, "\')\' expected");
      a := cons3(s_fncall, a, b)
    }
    else 
      skip
  }
  else 
  if (symbol = s_number)
  then
  {  a := cons2(s_number, numval);
     nextsymbol()
  }
  else
  if ((symbol = s_true) or (symbol = s_false))
  then
  { a := namenode;
    nextsymbol()
  }  
  else
  if (symbol = s_string) 
  then
  { a := newvec(wordsize + 2); 
    tree[a + t_op] := s_string;
    i := 0;
    while i <= wordsize do
    { tree[a + i + 1] := wordv[i];
      i := i + 1
    };
    nextsymbol()
  }
  else  
  if (symbol = s_lparen)
  then
  {  nextsymbol();
     a := rexpression();
     checkfor(s_rparen, "\')\' expected") 
  } 
  else
    cmperror("error in expression"); 
  return a
}

func rexpression() is
  var a;
  var b;
  var s;
{ if (symbol = s_minus)
  then
  {  nextsymbol();
     b := relement();
     return cons2(s_neg, b)
  }
  else
  if (symbol = s_not)
  then
  {  nextsymbol();
     b := relement();
     return cons2(s_not, b)
  }  
  else
  { a := relement();
    if ((symbol and s_diadic) ~= 0) 
    then
    { s := symbol;
      nextsymbol();
      return cons3(s, a, rright(s))
    }
    else   
      return a
  }
}

func rright(val s) is
  var b;
{ b := relement(); 
  if (associative(s) and (symbol = s))
  then
  { nextsymbol();
    return cons3(s, b, rright(s))
  }
  else 
    return b
}
    

func associative(val s) is 
  return (s = s_and) or (s = s_or) or (s = s_plus) 

  
func rexplist() is
  var a;
{ a := rexpression();
  if (symbol = s_comma)
  then
  { nextsymbol();
    return cons3(s_comma, a, rexplist())
  }
  else 
    return a
}
      
func rstatement() is
  var a;
  var b;
  var c;
{ if (symbol = s_skip)
  then
  { nextsymbol(); 
    return cons1(s_skip)
  }
  else  
  if (symbol = s_stop)
  then
  { nextsymbol();
    return cons1(s_stop)
  }
  else
  if (symbol = s_return)
  then
  { nextsymbol();
    return cons2(s_return, rexpression())
  }
  else
  if (symbol = s_if)
  then
  { nextsymbol();
    a := rexpression();
    checkfor(s_then, "\'then\' expected");
    b := rstatement();
    checkfor(s_else, "\'else\' expected");
    c := rstatement();
    return cons4(s_if, a, b, c)
  }
  else
  if (symbol = s_while)
  then
  { nextsymbol();
    a := rexpression();
    checkfor(s_do, "\'do\' expected");
    b := rstatement();
    return cons3(s_while, a, b)
  }
  else 
  if (symbol = s_begin)
  then
  { nextsymbol();
    a := rstatements();    
    checkfor(s_end, "\'}\' expected");
    return a
  }
  else
  if symbol = s_name
  then
  { a := relement();
    if (tree[a + t_op] = s_fncall)
    then
    { tree[a + t_op] := s_pcall;
      return a
    }
    else 
    { checkfor(s_ass, "\':=\' expected");
      return cons3(s_ass, a, rexpression())
    }
  }
  else
  { cmperror("error in command");    
    return cons1(s_stop)
  }
}      

func rstatements() is
  var a; 
{ a := rstatement();
  if symbol = s_semicolon
  then
  { nextsymbol();
    return cons3(s_semicolon, a, rstatements())
  }
  else 
    return a
}

func rprocdecls() is 
  var a;
{ a := rprocdecl();
  if (symbol = s_proc) or (symbol = s_func)
  then
    return cons3(s_semicolon, a, rprocdecls())
  else
    return a
}

func rprocdecl() is
  var s;
  var a;
  var b;
  var c;
{ s := symbol;
  nextsymbol();
  a := rname();
  checkfor(s_lparen, "\'(\' expected"); 
  if symbol = s_rparen
  then
    b := nullnode
  else
    b := rformals();
  checkfor(s_rparen, "\')\' expected");
  checkfor(s_is, "\'is\' expected");
  if (symbol = s_var) or (symbol = s_val) 
  then 
    c := rldecls()
  else
    c := nullnode;
  c := cons3(s_body, c, rstatement()); 
  return cons4(s, a, b, c)
}

func rformals() is 
  var s;
  var a;
  var b;
{ if (symbol = s_val) or (symbol = s_array) or (symbol = s_proc)
  then
  { s := symbol;
    nextsymbol();
    if (symbol = s_name)
    then
      a := cons2(s, rname())
    else
      cmperror("name expected") 
  }
  else
    skip;
  if (symbol = s_comma)
  then
  { nextsymbol();
    b := rformals();
    return cons3(s_comma, a, b)
  }
  else
    return a
}

func rgdecls() is
  var a;
{ a := rdecl();
  if (symbol = s_val) or (symbol = s_var) or (symbol = s_array)
  then
    return cons3(s_semicolon, a, rgdecls())
  else
    return a
}

func rldecls() is
  var a;
{ a := rdecl();
  if (symbol = s_val) or (symbol = s_var)
  then
    return cons3(s_semicolon, a, rldecls())
  else
    return a
}

func rdecl() is
  var a;
  var b;
{ if (symbol = s_var)
  then
  { nextsymbol(); 
    a := cons2(s_var, rname())
  }
  else
  if (symbol = s_array)
  then
  { nextsymbol();
    a := rname();
    checkfor(s_lbracket, "\'[\' expected");
    b := rexpression();
    checkfor(s_rbracket, "\']\' expected");
    a := cons3(s_array, a, b) 
  }
  else
  if (symbol = s_val) 
  then
  { nextsymbol();
    a := rname();
    checkfor(s_eq, "\'=\' expected");
    b := rexpression();
    a := cons3(s_val, a, b)
  }
  else
    skip;
  checkfor(s_semicolon, "\';\' expected");
  return a
}
  

proc namemessage(array s, val x) is
  var n;
  var p;
  var w;
  var l;
  var b;
{ prints(s);
  if tree[x + t_op] = s_name
  then
  { n := 1;
    p := 2;
    w := tree[x + p];
    l := w and 255;
    w := w >> 8;   
    b := 1;
    while (n <= l) do 
    { putval(w and 255);
      w := w >> 8; 
      n := n + 1;
      b := b + 1;
      if (b = bytesperword)
      then
      { b := 0;
        p := p + 1;
        w := tree[x + p]
      }
      else skip
    }  
  }
  else skip;
  newline()
}

proc generror(array s) is
{ prints(s); newline();
  namemessage("in function ", tree[procdef + t_op1])
}

| translator |

proc declprocs(val x) is
{ if (tree[x + t_op] = s_semicolon)
  then
  { declprocs(tree[x + t_op1]);
    declprocs(tree[x + t_op2])
  }
  else
    addname(x, getlabel())
}

proc declformals(val x) is
  var op;
{ op := tree[x + t_op];
  if op = s_null
  then
    skip
  else
  if op = s_comma
  then
  { declformals(tree[x + t_op1]);
    declformals(tree[x + t_op2])
  }
  else
  { if op = s_val
    then
      tree[x + t_op] := s_var
    else
      skip;
    addname(x, stackp + pflag);
    stackp := stackp + 1
  }
}

proc declglobals(val x) is
  var op;
{ op := tree[x + t_op];
  if (op = s_semicolon)
  then
  { declglobals(tree[x + t_op1]);
    declglobals(tree[x + t_op2])
  }
  else
  if (op = s_var)
  then
  { addname(x, stackp);
    stackp := stackp + 1
  }
  else
  if (op = s_val) 
  then
  { tree[x + t_op2] := optimiseexpr(tree[x + t_op2]);
    if isval(tree[x + t_op2]) 
    then
      addname(x, getval(tree[x + t_op2]))
    else
      generror("constant expression expected")
  }
  else
  if (op = s_array)
  then
  { tree[x + t_op2] := optimiseexpr(tree[x + t_op2]);
    if isval(tree[x + t_op2]) 
    then
    { arrayspace := arrayspace + getval(tree[x + t_op2]);
      addname(x, stackp);
      stackp := stackp + 1
    }
    else
      generror("constant expression expected")
  }
  else
    skip
}

proc tglobals() is
  var g;
  var arraybase;
  var name;
{ g := 0;
  arraybase := maxaddr - arrayspace;
  genconst(arraybase - 2);
  while g < namep do
  { name := names_d[g];
    if tree[name + t_op] = s_array
    then
    { gen(cbf_var, 0, arraybase);
      arraybase := arraybase + getval(tree[name + t_op2])
    }
    else
      gen(cbf_var, 0, 0);
    g := g + 1
  }
}

proc decllocals(val x) is
  var op;
{ op := tree[x + t_op];
  if op = s_null
  then
    skip
  else
  if (op = s_semicolon)
  then
  { decllocals(tree[x + t_op1]);
    decllocals(tree[x + t_op2])
  }
  else
  if (op = s_var)
  then
  { addname(x, stackp);
    stackp := stackp + 1
  }
  else
  if (op = s_val) 
  then
  { tree[x + t_op2] := optimiseexpr(tree[x + t_op2]);
    if isval(tree[x + t_op2]) 
    then
      addname(x, getval(tree[x + t_op2]))
    else
      generror("constant expression expected")
  }
  else
    skip
}

proc addname(val x, val v) is 
{ names_d[namep] := x;
  names_v[namep] := v;
  namep := namep + 1
}


func findname(val x) is
  var n;
  var found;
{ found := false;
  n := namep - 1;
  while ((found = false) and (n >= 0)) do
  { if tree[names_d[n] + t_op1] = x
    then
      found := true
    else
      n := n - 1
  };
  if found 
  then
    skip
  else
  { namemessage("name not declared ", x);
    namemessage("in function", tree[procdef + t_op1])
  };
  return n
}

func islocal(val n) is
  return n >= nameb

proc optimise(val x) is
  var op;
{ op := tree[x + t_op];
  if (op = s_skip) or (op = s_stop)
  then
    skip
  else
  if (op = s_return)
  then
    tree[x + t_op1] := optimiseexpr(tree[x + t_op1])
  else
  if (op = s_if)
  then
  { tree[x + t_op1] := optimiseexpr(tree[x + t_op1]);
    optimise(tree[x + t_op2]);
    optimise(tree[x + t_op3])
  }
  else
  if (op = s_while)
  then
  { tree[x + t_op1] := optimiseexpr(tree[x + t_op1]);
    optimise(tree[x + t_op2])
  }  
  else
  if (op = s_ass)
  then
  { tree[x + t_op2] := optimiseexpr(tree[x + t_op2]);
    tree[x + t_op1] := optimiseexpr(tree[x + t_op1])
  }
  else
  if (op = s_pcall)
  then
  { tree[x + t_op2] := optimiseexpr(tree[x + t_op2]);
    tree[x + t_op1] := optimiseexpr(tree[x + t_op1])
  }   
  else
  if (op = s_semicolon)
  then
  { optimise(tree[x + t_op1]);
    optimise(tree[x + t_op2])
  }
  else skip
}

func optimiseexpr(val x) is
  var op;
  var name;
  var r;
  var temp;
  var left;
  var right;
  var leftop;
  var rightop;
{ r := x;
  op := tree[x + t_op];
  if (op = s_name)
  then
  { name := findname(x);
    if tree[names_d[name] + t_op] = s_val
    then 
      r := tree[names_d[name] + t_op2]
    else skip
  }
  else
  if (monadic(op))
  then
  { tree[x + t_op1] := optimiseexpr(tree[x + t_op1]);
    if (isval(tree[x + t_op1]))
    then
    { tree[x + t_op1] := evalmonadic(x);
      tree[x + t_op] := s_number
    }
    else
    if op = s_neg
    then
      r := cons3(s_minus, zeronode, tree[x + t_op1])
    else
      skip
  }
  else
  if (op = s_fncall)
  then
  { tree[x + t_op2] := optimiseexpr(tree[x + t_op2]);
    tree[x + t_op1] := optimiseexpr(tree[x + t_op1])
  }   
  else
  if (diadic(op))
  then
  { tree[x + t_op2] := optimiseexpr(tree[x + t_op2]);
    tree[x + t_op1] := optimiseexpr(tree[x + t_op1]);
    left := tree[x + t_op1];
    right := tree[x + t_op2];
    leftop := tree[left + t_op];
    rightop := tree[right + t_op];
    if (op = s_sub)
    then
      skip
    else
    if (isval(left) and isval(right))
    then
    { tree[x + t_op1] := evaldiadic(x);
      tree[x + t_op] := s_number
    }
    else
    if (op = s_eq)
    then
    { if (leftop = s_not) and (rightop = s_not)
      then
      { tree[x + t_op1] := tree[left + t_op1];
        tree[x + t_op2] := tree[right + t_op1]
      }    
      else skip 
    }   
    else
    if (op = s_ne)
    then
    { tree[x + t_op] := s_eq;
      r := cons2(s_not, x);
      if (leftop = s_not) and (rightop = s_not)
      then 
      { tree[x + t_op1] := tree[left + t_op1];
        tree[x + t_op2] := tree[right + t_op1]
      }     
      else skip
    } 
    else
    if (op = s_ge)
    then
    { tree[x + t_op] := s_ls;
      r := cons2(s_not, x)
    } 
    else
    if (op = s_gr)
    then
    { temp := tree[x + t_op1];
      tree[x + t_op1] := tree[x + t_op2];
      tree[x + t_op2] := temp;
      tree[x + t_op] := s_ls
    }
    else
    if (op = s_le)
    then
    { temp := tree[x + t_op1];
      tree[x + t_op1] := tree[x + t_op2];
      tree[x + t_op2] := temp;
      tree[x + t_op] := s_ls;
      r := cons2(s_not, x)
    }
    else
    if ((op = s_or) or (op = s_and))
    then
    { if (leftop = s_not) and (rightop = s_not) 
      then
      { r := cons2(s_not, x);
        if (tree[x + t_op] = s_and)
        then
          tree[x + t_op] := s_or
        else 
          tree[x + t_op] := s_and;
        tree[x + t_op1] := tree[left + t_op1];
        tree[x + t_op2] := tree[right + t_op1]
      }
      else
        skip
    }
    else     
    if ((op = s_plus) or (op = s_or)) and (iszero(tree[x + t_op1]) or iszero(tree[x + t_op2]))
    then
    { if (iszero(tree[x + t_op1]))
      then
        r := tree[x + t_op2]
      else
      if (iszero(tree[x + t_op2]))
      then
        r := tree[x + t_op1]
      else skip
    }
    else
    if (op = s_minus) and iszero(tree[x + t_op2])
    then
      r := tree[x + t_op1]
    else skip    
  }
  else  
  if (op = s_comma)
  then
  { tree[x + t_op2] := optimiseexpr(tree[x + t_op2]);
    tree[x + t_op1] := optimiseexpr(tree[x + t_op1])
  }
  else skip;
  return r
}

func isval(val x) is
  var op;
{ op := tree[x + t_op];
  return (op = s_true) or (op = s_false) or (op = s_number)
}

func getval(val x) is
  var op;
{ op := tree[x + t_op];
  if (op = s_true)
  then
    return 1
  else
  if (op = s_false)
  then
    return 0
  else
  if (op = s_number)
  then
    return tree[x + t_op1]
  else
    return 0
}  

func evalmonadic(val x) is
  var op;
  var opd;
{ op := tree[x + t_op];
  opd := getval(tree[x + t_op1]);
  if (op = s_neg) 
  then
    return - opd
  else
  if (op = s_not)
  then
    return ~ opd
  else
  { generror("compiler error");
    return 0
  }
}

func evaldiadic(val x) is
  var op;
  var left;
  var right;
{ op := tree[x + t_op];
  left := getval(tree[x + t_op1]);
  right := getval(tree[x + t_op2]);
  if (op = s_plus)
  then
      return left + right
  else
  if (op = s_minus)
  then
      return left - right
  else
  if (op = s_eq)
  then
      return left = right
  else
  if (op = s_ne)
  then
      return left ~= right
  else
  if (op = s_ls)
  then
      return left < right
  else
  if (op = s_gr)
  then
      return left > right
  else
  if (op = s_le)
  then
      return left <= right
  else
  if (op = s_ge)
  then
      return left >= right
  else
  if (op = s_or)
  then
      return left or right
  else
  if (op = s_and)
  then
      return left and right
  else
  { cmperror("optimise error");
    return 0
  }
}

proc translate(val t) is
  var s;
  var dlab;
  var mainlab;
  var link;
  
{ namep := 0;
  nameb := 0;

  labelcount := 1;
  initlabels();

  initbuffer();

  arrayspace := 0;
  stk_init(3);

  declglobals(tree[t + t_op1]);
 
  tglobals(tree[t + t_op1]);
  declprocs(tree[t + t_op2]);
  nameb := namep;
  entrylab := getlabel(); 
  mainlab := getlabel();
  link := getlabel();
  setlab(entrylab);
  genref(i_ldap, link);
  genref(i_br, mainlab);
  setlab(link);
  geni(i_ldam, 2);
  geni(i_ldai, 1);
  geni(i_br, -2);
  setlab(mainlab);  

  genprocs(tree[t + t_op2]); 

  flushbuffer()
}

proc genprocs(val x) is
  var body;
  var savetreep;
  var pn;
{ if (tree[x + t_op] = s_semicolon)
  then
  { genprocs(tree[x + t_op1]);
    genprocs(tree[x + t_op2])
  }
  else
  { savetreep := treep;
    namep := nameb;
    pn := findname(tree[x + t_op1]); 
    proclabel := names_v[pn];
    procdef := names_d[pn];
    infunc := tree[procdef + t_op] = s_func;
    body := tree[x + t_op3]; 
    if infunc 
    then 
      stk_init(2)
    else
      stk_init(1);
    declformals(tree[x + t_op2]);
    setlab(proclabel);
    genentry();
    if infunc 
    then 
      stk_init(2)
    else
      stk_init(1);
    decllocals(tree[body + t_op1]);
    setstack();
   
    optimise(tree[body + t_op2]);   
    genstatement(tree[body + t_op2], true, 0, true); 

    genexit();   
    treep := savetreep
  }
}

func funtail(val tail) is
  return infunc and tail

proc genstatement(val x, val seq, val clab, val tail) is
  var op;
  var op1;
  var lab;
  var thenpart;
  var elsepart;
  var elselab;
{ op := tree[x + t_op];
  if (op = s_semicolon)
  then
  { genstatement(tree[x + t_op1], true, 0, false);
    genstatement(tree[x + t_op2], seq, clab, tail)
  }
  else
  if (op = s_if) and (clab = 0)
  then
  { lab := getlabel();
    genstatement(x, true, lab, tail);
    setlab(lab)
  }
  else
  if op = s_if
  then
  { thenpart := tree[x + t_op2];
    elsepart := tree[x + t_op3];
    if (~ funtail(tail)) and ((tree[thenpart + t_op] = s_skip) or (tree[elsepart + t_op] = s_skip))
    then
    { gencondjump(tree[x + t_op1], (tree[thenpart + t_op] = s_skip), clab); 
      if (tree[thenpart + t_op] = s_skip)
      then
        genstatement(elsepart, seq, clab, tail)
      else
        genstatement(thenpart, seq, clab, tail)
    }   
    else
    { elselab := getlabel();
      gencondjump(tree[x + t_op1], false, elselab);       
      genstatement(thenpart, false, clab, tail);
      setlab(elselab);
      genstatement(elsepart, seq, clab, tail)
    }
  }
  else
  if funtail(tail)
  then
    if op = s_return
    then
    { op1 := tree[x + t_op1];
      if tree[op1 + t_op] = s_fncall
      then
      { tcall(op1, seq, clab, tail);
        geni(i_ldam, 2);
        geni(i_ldai, 1)
      }       
      else
      { texp(tree[x + t_op1]);
        genbr(seq, clab) 
      }
    }
    else
      generror("\"return\" expected")
  else
  if (op = s_while) and (clab = 0)
  then
  { lab := getlabel();
    genstatement(x, false, lab, false);
    setlab(lab)
  }
  else
  if (op = s_while)
  then
  { lab := getlabel();
    setlab(lab);
    gencondjump(tree[x + t_op1], false, clab);
    genstatement(tree[x + t_op2], false, lab, false)
  }
  else
  if (op = s_pcall)
  then
    tcall(x, seq, clab, tail)
  else
  if (op = s_stop)
  then
    geni(i_br, -2)
  else
  { if (op = s_skip) 
    then
      skip
    else
    if (op = s_ass) 
    then
      genassign(tree[x + t_op1], tree[x + t_op2])
    else
    if op = s_return 
    then 
      generror("misplaced \"return\"")
    else 
      skip;
    genbr(seq, clab)
  }
}

proc tbool(val x, val cond) is
  var op;
  var lab;
{ op := tree[x + t_op];
  if (op = s_not) 
  then
    tbool(tree[x + t_op1], ~cond)
  else
  if (op = s_and) or (op = s_or)
  then
  { lab := getlabel();
    gencondjump(x, true, lab);
    geni(i_ldac, 0);
    geni(i_br, 1);
    geni(i_ldac, 0);
    setlab(lab)
  }
  else
  if op = s_eq
  then
  { if iszero(tree[x + t_op1]) 
    then
      texp(tree[x + t_op2])
    else
    if iszero(tree[x + t_op2])
    then
      texp(tree[x + t_op1])
    else
      texp2(s_minus, tree[x + t_op1], tree[x + t_op2]);
    if cond
    then
    { geni(i_brz, 1);
      geni(i_ldac, 1)
    }
    else
    { geni(i_brz, 2);
      geni(i_ldac, 0);
      geni(i_br, 1);
      geni(i_ldac, 1)
    }
  }
  else
  if op = s_ls
  then
  { if iszero(tree[x + t_op2]) 
    then
      texp(tree[x + t_op1])
    else
      texp2(s_minus, tree[x + t_op1], tree[x + t_op2]);
    geni(i_brn, 2);
    geni(i_ldac, cond and 1);
    geni(i_br, 1);
    geni(i_ldac, (~cond) and 1)
  }
  else
    skip 
}

 
proc gencondjump(val x, val cond, val target) is
  var op;
  var lab;
{ op := tree[x + t_op];
  if (op = s_not) 
  then
    gencondjump(tree[x + t_op1], ~cond, target)
  else
  if (op = s_and) or (op = s_or)
  then
    if ((op = s_and) and cond) or ((op = s_or) and (~cond)) 
    then 
    { lab := getlabel();
      gencondjump(tree[x + t_op1], ~cond, lab);
      gencondjump(tree[x + t_op2], ~cond, lab);
      genref(i_br, target);
      setlab(lab)
    }
    else
    { gencondjump(tree[x + t_op1], ~cond, target);
      gencondjump(tree[x + t_op2], ~cond, target)     
    }
  else
  if op = s_eq
  then
  { if iszero(tree[x + t_op1]) 
    then
      texp(tree[x + t_op2])
    else
    if iszero(tree[x + t_op2])
    then
      texp(tree[x + t_op1])
    else
      texp2(s_minus, tree[x + t_op1], tree[x + t_op2]);
    genjump(i_brz, cond, target)
  }
  else
  if op = s_ls
  then
  { if iszero(tree[x + t_op2]) 
    then
      texp(tree[x + t_op1])
    else
      texp2(s_minus, tree[x + t_op1], tree[x + t_op2]);
    genjump(i_brn, cond, target)
  }
  else
  { texp(x);
    genjump(i_brz, cond, target)
  }  
}

proc genjump(val inst, val cond, val target) is
  var lab;
{ if cond
  then
    genref(inst, target)
  else
  { lab := getlabel();
    genref(inst, lab);
    genref(i_br, target);
    setlab(lab)
  }
}
  
proc tcall(val x, val seq, val clab, val tail) is
  var sp;
  var entry;
  var def;
{ sp := stackp;
  entry := findname(tree[x + t_op1]);
  def := names_d[entry];
  checkps(tree[def + t_op2], tree[x + t_op2]); 
  if tree[def + t_op] = s_func
  then 
    loadaps(tree[x + t_op2], 2)
  else
    loadaps(tree[x + t_op2], 1);
  gencall(names_v[entry], seq, clab);
  stackp := sp
}


proc loadaps(val aplist, val n) is
  var x;
{ x := aplist;
  if tree[x + t_op] = s_comma 
  then
  { loadaps(tree[x + t_op2], n + 1);
    loadap(tree[x + t_op1], n)
  }
  else
    loadap(x, n)
}

proc loadap(val x, val n) is
  var op; 
  var vn;
  var aptype;
{ op := tree[x + t_op];
  if op = s_null 
  then
    skip
  else
  { if op = s_name
    then
    { vn := findname(x);
      aptype := tree[names_d[vn] + t_op];
      if aptype = s_val
      then
        loadconst(r_areg, names_v[vn])
      else 
        loadvar(r_areg, vn)
    }
    else      
      texp(x);
    geni(i_ldbm, 2);
    geni(i_stai, n);
    stackp := stackp + 1;
    setstack()  
  } 
}
  
proc checkps(val alist, val flist) is
  var ax;
  var fx;
{ while tree[fx + t_op] = s_comma do
    if tree[ax + t_op] = s_comma
    then 
    { checkp(tree[ax + t_op1], tree[fx + t_op1]);
      fx := tree[fx + t_op2];
      ax := tree[ax + t_op2]
    }
    else
      cmperror("parameter mismatch");
  checkp(ax, fx)
}

proc checkp(val a, val f) is
  if tree[f + t_op] = s_null
  then
    skip
  else
  if tree[f + t_op] = s_val
  then
    skip 
  else
  if tree[f + t_op] = s_array  
  then
    skip
  else
  if tree[f + t_op] = s_proc
  then
    skip
  else
    skip
 
func iszero(val x) is
  return isval(x) and (getval(x) = 0)

func immop(val x) is
  var value;
{ value := getval(x);
  return isval(x) and (value > (-65536)) and (value < 65536)
}

func needsareg(val x) is
  var op;
{ op := tree[x + t_op];
  return ~ (isval(x) or (op = s_string) or (op = s_name))
}
  
    
func regsfor(val x) is 
  var op;
  var rleft;
  var rright;
{ op := tree[x + t_op];
  if op = s_fncall
  then
    return 10
  else
  if monadic(op)
  then
    return regsfor(tree[x + t_op1])
  else
  if diadic(op)
  then
  { rleft := regsfor(tree[x + t_op1]);  
    rright := regsfor(tree[x + t_op2]);
    if rleft = rright 
    then
      return 1 + rleft
    else
    if rleft > rright
    then
      return rleft
    else 
      return rright
  }
  else
    return 1
}    

proc loadbase(val reg, val base) is
  var name;
  var def;
{ if isval(base)
  then
    loadconst(reg, getval(base))
  else
  { name := findname(base);
    def := names_d[name];
    if tree[def + t_op] = s_array
    then 
      loadvar(reg, name)
    else
      namemessage("array expected", tree[def + t_op1])
  }
}

proc genassign(val left, val right) is
  var sp;
  var leftop;
  var name;
  var base;
  var offset;
  var value;
{ leftop := tree[left + t_op];
  if leftop = s_name
  then
  { name := findname(left);
    texp(right);
    storevar(name)
  }
  else
  { base := tree[left + t_op1];
    offset := tree[left + t_op2];
    if isval(offset)
    then
    { value := getval(offset);
      texp(right);
      loadbase(r_breg, base);
      geni(i_stai, value)
    }
    else  
    { sp := stackp;
      texp(offset);
      loadbase(r_breg, base);
      geni(i_add, 0);
      stackp := stackp + 1;
      setstack();
      geni(i_ldbm, 2);
      gensref(i_stai, sp);
      texp(right);
      geni(i_ldbm, 2);
      gensref(i_ldbi, sp);
      geni(i_stai, 0);
      stackp := sp
    }
  }
}
  
proc texp(val x) is
  var op;
  var left;
  var right;
  var offs;
  var value;
  var def;
  var sp;
{ op := tree[x + t_op];
  if isval(x)
  then
  { value := getval(x);
    loadconst(r_areg, value)
  }
  else   
  if op = s_string
  then
    genstring(x)
  else
  if (op = s_name)  
  then 
  { left := findname(x);
    def := names_d[left]; 
    if tree[def + t_op] = s_val
    then
      loadconst(r_areg, names_v[left])
    else
    if tree[def + t_op] = s_var
    then
      loadvar(r_areg, left)
    else
      skip
  } 
  else
  if (op = s_not) or (op = s_and) or (op = s_or) or (op = s_eq) or (op = s_ls)  
  then
    tbool(tree[x + t_op1], true)
  else
  if (op = s_sub)
  then
  { left := tree[x + t_op1];
    def := names_d[left];
    if isval(tree[x + t_op2])
    then
    { loadbase(r_areg, left);
      value := getval(tree[x + t_op2]);
      geni(i_ldai, value)
    }
    else
    { texp(tree[x + t_op2]);
      loadbase(r_breg, left);
      geni(i_add, 0);
      geni(i_ldai, 0)
    }
  }
  else
  if op = s_fncall
  then
  { tcall(x, true, 0, false);
    geni(i_ldam, 2);
    geni(i_ldai, 1)
  }
  else
    texp2(op, tree[x + t_op1], tree[x + t_op2])
}
 
proc texp2(val op, val op1, val op2) is
  var left;
  var right;  
  var sp;
{ left := op1;
  right := op2;
  if (op = s_plus) and (regsfor(left) < regsfor(right))
  then
  { left := op2;
    right := op1
  }
  else
    skip;
  if needsareg(right)
  then
  { sp := stackp;
    texp(right);
    stackp := stackp + 1;
    setstack();
    geni(i_ldbm, 2);        
    gensref(i_stai, sp);
    texp(left);
    geni(i_ldbm, 2);
    gensref(i_ldbi, sp);
    stackp := sp
  }
  else
  { texp(left);
    tbexp(right)
  };
  if (op = s_plus)
  then
    geni(i_add, 0)
  else
  if (op = s_minus) 
  then
    geni(i_sub, 0) 
  else
    skip
}

proc tbexp(val x) is
  var op;
  var left;
  var value;
  var def;
{ op := tree[x + t_op];
  if isval(x)
  then
  { value := getval(x);
    loadconst(r_breg, value)
  }
  else   
  if op = s_string
  then
    genstring(x)
  else
  if (op = s_name)  
  then 
  { left := findname(x);
    def := names_d[left]; 
    if tree[def + t_op] = s_val
    then
      loadconst(r_breg, names_v[left])
    else
    if tree[def + t_op] = s_var
    then
      loadvar(r_breg, left)
    else
      skip
  } 
  else
    skip
}


proc stk_init(val n) is 
{ stackp := n;
  stk_max := n
}
  
proc setstack() is
  if stk_max < stackp
  then 
    stk_max := stackp
  else
    skip

proc loadconst(val reg, val value) is
  if (value > (-65536)) and (value < 65536)
  then
  if reg = r_areg
  then
    geni(i_ldac, value)
  else
    geni(i_ldbc, value)
  else
    gen(cbf_const, reg, genconst(value))
 
proc loadvar(val reg, val vn) is
  var offs;
{ offs := names_v[vn];
  if islocal(vn) 
  then 
    if reg = r_areg
    then
    { geni(i_ldam, 2);
      gensref(i_ldai, offs) 
    }
    else
    { geni(i_ldbm, 2);
      gensref(i_ldbi, offs)
    }
  else
    if reg = r_areg
    then
      geni(i_ldam, offs)
    else
      geni(i_ldbm, offs)
}
 
proc storevar(val vn) is
  var offs;
{ offs := names_v[vn];
  if islocal(vn) 
  then
  { geni(i_ldbm, 2); 
    gensref(i_stai, offs)
  } 
  else
    geni(i_stam, offs)
}
 
func monadic(val op) is
  return (op = s_not) or (op = s_neg)

func diadic(val op) is 
  return ((op and s_diadic) ~= 0)

proc geni(val i, val opd) is
  gen(cbf_inst, i, opd)

proc genref(val inst, val lab) is
  if labval[lab] = 0
  then
    gen(cbf_fwdref, inst, lab)
  else
    gen(cbf_bwdref, inst, lab)

proc gensref(val i, val offs) is
  gen(cbf_stack, i, offs)

proc genbr(val seq, val lab) is
  if seq 
  then
    skip
  else
    genref(i_br, lab)

proc gencall(val p, val seq, val clab) is
  var link;
{ link := getlabel();
  genref(i_ldap, link);
  genref(i_br, p);
  setlab(link);
  genbr(seq, clab)
}

proc genconst(val n) is
  var i;
  var cp;
  var found;
{ found := false;
  i := 0;
  while ((i < constp) and (found = false)) do
    if (consts[i] = n) 
    then
    { found := true;
      cp := i
    }
    else
      i := i + 1;
  if found 
  then
    skip
  else
  { consts[constp] := n;
    cp := constp;
    constp := constp + 1 
  }
}


proc genstring(val x) is
  var i;
  var sp;
{ sp := stringp;
  i := 0;
  while i <= ((tree[x + 1] and 255) >> 2) do
  { strings[stringp] := tree[x + i + 1];
    stringp := stringp + 1;
    i := i + 1
  };
  gen(cbf_string, 0, sp)
}
     
proc gen(val t, val h, val l) is
{ cb_loadpoint := cb_loadpoint + 1; 
  codebuffer[cb_bufferp] := (t << 28) or (h << 24) or (l and #FFFFFF);
  cb_bufferp := cb_bufferp + 1;
  if (cb_bufferp = cb_size)
  then
    generror("code buffer overflow")
  else skip
}
  
proc initlabels() is
  var l;
{ l := 0;
  while l < labval_size do
  { labval[l] := 0;
    l := l + 1
  }
}

func getlabel() is
{ if labelcount < labval_size
  then
    labelcount := labelcount + 1
  else
    generror("too many labels");
  return labelcount
}

proc setlab(val l) is
{ labval[l] := cb_loadpoint;
  gen(cbf_lab, 0, l)
}

proc genentry() is
{ cb_entryinstp := cb_bufferp;
  gen(cbf_entry, 0, 0)
}  
   
proc genexit() is
{ cb_setlow(cb_entryinstp, stk_max);
  if tree[procdef+ t_op] = s_proc
  then
    gen(cbf_pexit, 0, 0)
  else
    gen(cbf_fnexit, 0, 0)
}

proc initbuffer() is
{ cb_loadpoint := 0;
  constp := 0;
  stringp := 0;
  cb_bufferp := 0
}

proc cb_setflag(val p, val f) is
  codebuffer[p] := (codebuffer[p] and #FFFFFFF) or (f << 28)

func cb_flag(val p) is
  return (codebuffer[p] >> 28)

proc cb_sethigh(val p, val f) is
  codebuffer[p] := (codebuffer[p] and #F0FFFFFF) or (f << 24)

func cb_high(val p) is
  return (codebuffer[p] >> 24) and #F

proc cb_setlow(val p, val f) is
  codebuffer[p] := (codebuffer[p] and #FF000000) or (f and #FFFFFF)

func cb_low(val p) is
  var l;
{ l := codebuffer[p] and #FFFFFF;
  if (l >> 23) = 0
  then
    return l
  else
    return l or #FF000000
} 

func instlength(val opd) is
  var v;
  var n;
{ if (opd >= 0) and (opd < 16)
  then
    n := 1
  else
  { n := 8;
    if opd < 0 
    then
    { v := opd and #FFFFFF00;
      while (v >> 28) = #F do
      { v := v << 4;
        n := n - 1
      }
    }
    else
    { v := opd;
      while (v >> 28) = 0 do
      { v := v << 4;
        n := n - 1
      }
    }
  };
  return n
}

func cb_laboffset(val p) is
  return labval[cb_low(p)] - (cb_loadpoint + cb_reflength(p))

func cb_reflength(val p) is
  var ilen;
  var labaddr;
{ ilen := 1;
  labaddr := labval[cb_low(p)];
  while ilen < instlength(labaddr - (cb_loadpoint + ilen)) do
    ilen := ilen + 1;
  return ilen
}

func cb_stackoffset(val p, val stksize) is
  var offs;
{ offs := cb_low(p);
  if (offs and pflag) = 0
    then 
      return (stksize - offs) + 1
    else 
      return stksize + (offs - pflag)
}

proc expand() is
  var bufferp;
  var offset;
  var stksize;
  var flag;
{ bufferp := 0; 
  while bufferp < cb_bufferp do
  { flag := cb_flag(bufferp);
    if flag = cbf_entry 
    then
    { stksize := cb_low(bufferp);
      cb_loadpoint := cb_loadpoint + instlength(- stksize) + 4
    }
    else
    if flag = cbf_pexit
    then
      cb_loadpoint := cb_loadpoint + instlength(stksize) + 5
    else
    if flag = cbf_fnexit
    then
      cb_loadpoint := cb_loadpoint + instlength(stksize) + 6
    else
    if flag = cbf_inst
    then
      cb_loadpoint := cb_loadpoint + instlength(cb_low(bufferp))
    else
    if flag = cbf_stack
    then
    { offset := cb_stackoffset(bufferp, stksize); 
      cb_loadpoint := cb_loadpoint + instlength(offset)
    }
    else 
    if flag = cbf_lab
    then
      labval[cb_low(bufferp)] := cb_loadpoint
    else
    if flag = cbf_bwdref
    then
      cb_loadpoint := cb_loadpoint + cb_reflength(bufferp)
    else
    if flag = cbf_fwdref
    then
    { offset := cb_laboffset(bufferp);
      if offset > 0
      then
        cb_loadpoint := cb_loadpoint + cb_reflength(bufferp)
      else
        cb_loadpoint := cb_loadpoint + 1
    }
    else
    if flag = cbf_const
    then
    { offset := cb_low(bufferp) + 2;
      cb_loadpoint := cb_loadpoint + instlength(offset)
    }
    else
    if flag = cbf_string
    then
    { offset := cb_low(bufferp) + constp;
      cb_loadpoint := cb_loadpoint + instlength(offset)
    }
    else
    if flag = cbf_var
    then
      cb_loadpoint := cb_loadpoint + 1
    else
      cmperror("code buffer error");       
    bufferp := bufferp + 1
  }
}

proc flushbuffer() is
  var bufferp;
  var last;
  var offset;
  var stksize;
  var flag;
{ cb_loadpoint := 0;
  last := 0; 
  expand();
  while cb_loadpoint ~= last do
  { last := cb_loadpoint;
    cb_loadpoint := 0;
    expand()
  };
  codesize := cb_loadpoint + ((constp + stringp) << 2);
  outhdr();
  outconsts();
  outstrings();
  bufferp := 0; 
  cb_loadpoint := 0;
  while bufferp < cb_bufferp do
  { flag := cb_flag(bufferp);
    if flag = cbf_entry 
    then
    { stksize := cb_low(bufferp);
      outinst(i_ldbm, 2);
      outinst(i_stai, 0);
      outinst(i_ldac, (-stksize)); 
      outinst(i_add, 0);
      outinst(i_stam, 2);
      cb_loadpoint := cb_loadpoint + instlength(- stksize) + 4
    }
    else
    if flag = cbf_pexit 
    then
    { outinst(i_ldbm, 2);
      outinst(i_ldac, stksize); 
      outinst(i_add, 0);
      outinst(i_stam, 2);
      outinst(i_ldai, 0);
      outinst(i_bra, 0); 
      cb_loadpoint := cb_loadpoint + instlength(stksize) + 5  
    }
    else
    if flag = cbf_fnexit 
    then
    { outinst(i_ldbm, 2);
      outinst(i_stai, stksize + 1);
      outinst(i_ldac, stksize); 
      outinst(i_add, 0);
      outinst(i_stam, 2);
      outinst(i_ldai, 0);
      outinst(i_bra, 0); 
      cb_loadpoint := cb_loadpoint + instlength(stksize) + 6  
    }
    else
    if flag = cbf_inst
    then
    { outinst(cb_high(bufferp), cb_low(bufferp));
      cb_loadpoint := cb_loadpoint + instlength(cb_low(bufferp))
    }
    else
    if flag = cbf_stack
    then
    { offset := cb_stackoffset(bufferp, stksize); 
      outinst(cb_high(bufferp), offset);
      cb_loadpoint := cb_loadpoint + instlength(offset)
    }
    else 
    if flag = cbf_lab
    then 
      outlab('L', cb_low(bufferp))
    else
    if (flag = cbf_bwdref) or (flag = cbf_fwdref)
    then
    { offset := cb_laboffset(bufferp);
      outref(cb_high(bufferp), cb_low(bufferp));
      cb_loadpoint := cb_loadpoint + cb_reflength(bufferp)
    }
    else
    if flag = cbf_const
    then
    { offset := cb_low(bufferp);
      outcref(cb_high(bufferp), offset);
      cb_loadpoint := cb_loadpoint + instlength(offset)
    }
    else
    if flag = cbf_string
    then
    { offset := cb_low(bufferp) + constp; 
      outsref(offset);
      cb_loadpoint := cb_loadpoint + instlength(offset)
    }
    else 
    if flag = cbf_var
    then
    { outvar(cb_low(bufferp));
      cb_loadpoint := cb_loadpoint + 1
    }
    else
      skip;
    bufferp := bufferp + 1
  }
}

proc outinst(val inst, val opd) is
  { prints("  ");
    if inst = i_ldam
    then
      prints("LDAM    ")
    else
    if inst = i_ldbm
    then
      prints("LDBM    ")
    else
    if inst = i_stam
    then
      prints("STAM    ")
    else
    if inst = i_ldac
    then
      prints("LDAC    ")
    else 
    if inst = i_ldbc
    then
      prints("LDBC    ")
    else
    if inst = i_ldap
    then
      prints("LDAP    ")
    else
    if inst = i_ldai
    then
      prints("LDAI    ")
    else
    if inst = i_ldbi
    then
      prints("LDBI    ") 
    else
    if inst = i_stai
    then
      prints("STAI    ")
      else
    if inst = i_br
    then
      prints("BR      ")
    else
    if inst = i_brz
    then
      prints("BRZ     ")
    else
    if inst = i_brn
    then
      prints("BRN     ")
    else
    if inst = i_bra
    then
      prints("BRA     ")
    else
    if inst = i_add
    then
      prints("ADD     ")
    else
    if inst = i_sub
    then
      prints("SUB     ")
    else
      skip;
    if inst < i_bra
    then
      printn(opd)
    else
      skip;
    newline()
  }
  
proc outlab(val t, val lab) is
{ prlab(t, lab);
  newline()
}

proc outref(val inst, val lab) is
{ prints("  ");
  if inst = i_br
  then
    prints("BR      ")
  else
  if inst = i_brz
  then 
    prints("BRZ     ")
  else
  if inst = i_brn
  then 
    prints("BRN     ")
  else
    prints("LDAP    ");
  prlab('L', lab);
  newline()
}

proc prlab(val t, val n) is
{ putval(t);
  printn(n)
}

proc outcref(val reg, val c) is
  if reg = r_areg
  then 
  { prints("  LDAM    ");
    prlab('C', c);
    newline()
  } 
  else
  { prints("  LDBM    ");
    prlab('C', c);
    newline()
  }

proc outsref(val c) is
{ prints("  LDAC    ");
  prlab('S', c);
  newline()
}

proc outconsts() is
  var count;
{ count := 0; 
  while (count < constp) do 
  { outlab('C', count);
    prints("  DATA    ");
    printn(consts[count]);
    newline();
    count := count + 1
  }
}

proc outvar(val d) is
{ prints("  DATA    ");
  printn(d);
  newline()
}

proc outstrings() is
  var count;
  var len;
{ count := 0;
  while (count < stringp) do 
  { outlab('S', constp + count);
    len := ((strings[count] and 255) >> 2) + 1;
    while len > 0 do
    { prints("  DATA    ");
      printn(strings[count]); 
      newline();
      count := count + 1;
      len := len - 1
    }
  }
}

proc outhdr() is
  outref(i_br, entrylab)







