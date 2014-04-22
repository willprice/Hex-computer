# vim: set ft=python:
# SCons does not run things linearly, all SCons commands set up a
# dependency chain which once fully formed is then executed from leaf
# nodes to the top of the tree. I have tried to make this explicit
# through the naming of the functions.
Import('env')

compiler_32_bit = File("compiler_32_bit.bin")
cross_compiler =  File('8_bit_compiler_for_32_bit_machine.bin')
sim_src_32 = "simulator_32_bit.c"
sim_src_8 =  "simulator_8_bit.c"

simulators = {
    '8_bit'  : File('8_bit_sim'),
    '32_bit' : File('32_bit_sim'),
}

sources={
    'xhexs.x'  : 'compiler_8_bit.x',
    'xhexb.x'  : 'compiler_32_bit.x',
    'xhexsa.x' : 'assembly_compiler_8_bit.x',
    'xhexba.x' : 'assembly_compiler_32_bix.x',
    'xhexb.bin':  compiler_32_bit,
    'hexsimb.c':  sim_src_32,
    'hexsims.c' :  sim_src_8,
}

def rename_files():
    for source, target in sources.iteritems():
        target = File(target)
        source = File(source)
        env.Command(target, source, action=Copy(target, source))

def compile_simulators():
    env.Program(simulators['32_bit'], sim_src_32)
    env.Program(simulators['8_bit'], sim_src_8)

def compile_compilers():
    env.Compile32Bit(cross_compiler, 'compiler_8_bit.x')

def generate_compiler_builder(compiler_file, simulator_file):
    return Builder(action = ['cp ' + compiler_file.path + ' a.bin',
                             simulator_file.abspath + ' < $SOURCE',
                             'mv sim2 $TARGET',
                             'rm a.bin'])

Depends(simulators['32_bit'], compiler_32_bit)
compile_32_bit = generate_compiler_builder(compiler_32_bit, simulators['32_bit'])
compile_32_bit_for_8_bit = generate_compiler_builder(cross_compiler, simulators['32_bit'])

# No 8 bit host, 8 bit target compiler is provided as the compiler source code
# depends on 32 bit features. You can only use the cross compiler to generate 8
# bit hex binaries (or more accurately hex files!)
env.Append(BUILDERS = {'Compile32Bit': compile_32_bit,
                       'CrossCompile': compile_32_bit_for_8_bit})

def compile_my_source_code():
    env.CrossCompile('factorial.hex', 'fact3.x')

rename_files()
compile_simulators()
compile_compilers()

compile_my_source_code()
