
#include "stdio.h"

#define true     1
#define false    0


FILE *codefile;

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
	
while (running) 

{ 
  inst = pmem[pc]; 
	
	printf("pc = %d; op = %d; opd = %d; areg = %d; breg = %d\n", pc, (inst>>4) & 0xF, inst & 0xF, areg, breg);	

  pc = pc + 1;	

  oreg = oreg | (inst & 0xf);	
	
  switch ((inst >> 4) & 0xf)
  {
	case i_ldam:   areg = mem[oreg]; oreg = 0; break;
	case i_ldbm:   breg = mem[oreg]; oreg = 0; break;
	case i_stam:   mem[oreg] = areg; oreg = 0; break;	  
		  
	case i_ldac:   areg = oreg; oreg = 0; break;
	case i_ldbc:   breg = oreg; oreg = 0; break;
	case i_ldap:   areg = pc + oreg; oreg = 0; break;
		  
	case i_ldai:   areg = mem[areg + oreg]; oreg = 0; break;
	case i_ldbi:   breg = mem[breg + oreg]; oreg = 0; break;
	case i_stai:   mem[breg + oreg] = areg; oreg = 0; break;	  
		  
	case i_br:     stop(); pc = pc + oreg; oreg = 0; break;
	case i_brz:    if (areg == 0) pc = pc + oreg; oreg = 0; break;
	case i_brn:    if (areg > 127) pc = pc + oreg; oreg = 0; break;	  

	case i_brb:    pc = breg; oreg = 0; break; 
		  
	case i_add:    areg = areg + breg; oreg = 0; break; 
	case i_sub:    areg = areg - breg; oreg = 0; break;	  
		  
	case i_pfix:   oreg = oreg << 4; break;
		
  };
	
}
	
}	
		  		  		  
load()
{ int low;
  int length;	
  int n;
  codefile = fopen("a.bin", "rb");
  low = inbin();	
  length = ((inbin() << 16) | low) << 2;
  for (n = 0; n < length; n++)
    pmem[n] = fgetc(codefile);
  pc = 0;
};

inbin(d) 
{ int lowbits;
  int highbits;
  lowbits = fgetc(codefile);
  highbits = fgetc(codefile);
  return (highbits << 8) | lowbits;
};

stop() 
{ if (oreg == 0xFE)
  { printf("\nareg = %d\n", areg);
    running = false; 
  }	  
}



