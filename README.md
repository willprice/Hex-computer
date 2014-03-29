# README
`*.x` files are source files in the X language
`*.hex` are the compiled files for the machine

* `xhexs.x`   - source code for 8 bit compiler
* `xhexsa.x`  - source code for 8 bit assembly-compiler
* `xhexb.x`   - source code for 32 bit compiler (boot-strapping)
* `xhexba.x`  - source code for 32 bit assembly-compiler (boot-strapping)
* `xhexb.bin` - a 32 bit compiler in binary
* `hexsimb.c` - simulator (32 bit) (boot-strapping)
* `hexsims.c` - simulator (8 bit)

The simulators...

* Run the program in `a.bin`
* Take input from `stdin`
* Output to `sim2`
* The 32 bit sim produces a *binary* file
* The 8 bit sim produces a *hex* file
