# README
## Notes
`*.x` files are source files in the X language

`*.hex` are the compiled files for the machine

## Files
* `xhexs.x`   - source code for 8 bit compiler
* `xhexsa.x`  - source code for 8 bit assembly-compiler
* `xhexb.x`   - source code for 32 bit compiler (boot-strapping)
* `xhexba.x`  - source code for 32 bit assembly-compiler (boot-strapping)
* `xhexb.bin` - a 32 bit compiler binary (to be run on the 32 bit simulator)
* `hexsimb.c` - simulator (32 bit) (boot-strapping)
* `hexsims.c` - simulator (8 bit)

## The simulators...

* Run the program in `a.bin`
* Take input from `stdin`
* Output to `sim2`
* The 32 bit sim produces a *binary* file
* The 8 bit sim produces a *hex* file

## Instructions on use
(From David's email)

As I said in the lecture, I've used a 32-bit version of the instruction set
to execute the compilers - and to bootstrap them.

You should be able to compile the C simulator for the 32-bit processor
using (eg):

gcc hexsimb.c

The simulator uses a binary in a.bin, so you need to copy this from xhexb.bin:

cp xhexb.bin a.bin

Then you can run the simulator in order to execute the compiler in a.bin. If you
supply the compiler source, this will generate a new binary version of the
compiler:

a.out <xhexb.x

The binary will be written to a file - sim2.

You can copy sim2 to a.bin:

cp sim2 a.bin

and repeat

a.out <xhexb.x

This should produce exactly the same output in sim2 as before.

I've also attached xhexba.x - this is similar to xhexb.x, but outputs assembler which
you can read.

You can now compile the compiler for the 8-bit machine - xhexs.x - using the
xhexb compiler:

a.out <xhexs.x

cp sim2 a.bin

Now you can write and compile programs to hex files that modulesim can
load - so that you can run them on the processor assembled from
modules. I've attached a simple program - fact3.x - that computes factorial 5.

a.out <fact3.x

will produce a hex file in sim2.

You can also execute this using the C simulator of the 8-bit processor:

gcc hexsims.c

cp sim2 a.bin

a.out

Finally, I've attached a hex file for fact3.x. It should be identical to the one
you have produced in a.bin. If for some reason you can't get the compilers
to run this will enable you to run the fact3 program on the processor
assembled from modules.

