
#include "stdio.h"

#define true     1
#define false    0

#define i_ldam   0x0
#define i_ldbm   0x1
#define i_stam   0x2

#define i_ldac   0x3
#define i_ldbc   0x4
#define i_ldap   0x5

#define i_ldai   0x6 
#define i_ldbi   0x7 
#define i_stai   0x8

#define i_br     0x9
#define i_brz    0xA 
#define i_brn    0xB

#define i_brb    0xC

#define i_add    0xD
#define i_sub    0xE

#define i_pfix   0xF

FILE *codefile;

unsigned char mem[256];
unsigned char *pmem = (unsigned char *) mem;

unsigned char pc;

unsigned char areg;
unsigned char breg;
unsigned char oreg;

unsigned char inst;

unsigned int running;

main() 
{
  printf("\n");
	
  load();
	
  running = true;	
	
  oreg = 0; 
  pc = 0;
	
  while (running) 

  { inst = pmem[pc]; 

    pc = pc + 1;	

    oreg = oreg | (inst & 0xf);	
	
    switch ((inst >> 4) & 0xf)
    {
	  case i_ldam: areg = mem[oreg]; oreg = 0; break;
	  case i_ldbm: breg = mem[oreg]; oreg = 0; break;
	  case i_stam: mem[oreg] = areg; oreg = 0; break;	  
		  
	  case i_ldac: areg = oreg; oreg = 0; break;
	  case i_ldbc: breg = oreg; oreg = 0; break;
	  case i_ldap: areg = pc + oreg; oreg = 0; break;
		  
	  case i_ldai: areg = mem[areg + oreg]; oreg = 0; break;
	  case i_ldbi: breg = mem[breg + oreg]; oreg = 0; break;
	  case i_stai: mem[breg + oreg] = areg; oreg = 0; break;	  
		  
	  case i_br:   stop(); pc = pc + oreg; oreg = 0; break;
	  case i_brz:  if (areg == 0) pc = pc + oreg; oreg = 0; break;
	  case i_brn:  if (areg > 127) pc = pc + oreg; oreg = 0; break;	  

	  case i_brb:  pc = breg; oreg = 0; break; 
		  
	  case i_add:  areg = areg + breg; oreg = 0; break; 
	  case i_sub:  areg = areg - breg; oreg = 0; break;	  
		  
	  case i_pfix: oreg = oreg << 4; break;
	};
  	
  }
	
}	
		  		  		  
load()
{ int n;
  int i;
  codefile = fopen("a.bin", "rb");
  n = getbyte();
  i = 0;	
  while (n != EOF)
  { pmem[i] = n;
	n = getbyte();
	i = i + 1;
  };
}

getbyte()
{ int high;
  high = gethex();
  if (high == EOF)
	return EOF;
  else
    return (high << 4) | gethex();
}

gethex() 
{ int h;
  h = fgetc(codefile);
  while ((h == ' ') || (h == '\n')) 
	h = fgetc(codefile);
  if (h == EOF)
	return EOF;
  else	  
  if ((h >= 'A') && (h <= 'F'))  
	return (h - 'A') + 10;
  else 
	return h - '0';
}

stop() 
{ if (oreg == 0xFE)
  { printf("\nareg = %d\n", areg);
    running = false; 
  }	  
}



