# vim: set ft=python:

def rename_builder(env, target, source):
    env.Command(target[0], source[0], Copy('$TARGET', '$SOURCE'))
    return None

env = Environment()
env.Append(BUILDERS = {'Rename': rename_builder})

sources={ 'xhexs.x'  : 'compiler_8_bit.x',
          'xhexb.x'  : 'compiler_32_bit.x',
          'xhexsa.x' : 'assembly_compiler_8_bit.x',
          'xhexba.x' : 'assembly_compiler_32_bix.x',
          'xhexb.bin': 'compiler_32_bit.bin',
          'hexsimb.c': 'simulator_32_bit.c',
          'hexsim.c' : 'simulator_8_bit.c',
        }

def rename_files():
    for file_pair in sources.iteritems():
        rename_file(file_pair)

def rename_file(file_pair):
    old_source = file_pair[0]
    new_source = file_pair[1]

    env.Rename(new_source, old_source)

def compile_simulators():
    rename_files()
    env.Program('32_bit_sim', 'simulator_32_bit.c')
    env.Program('8_bit_sim', 'simulator_8_bit.c')

def compile_all():
    compile_simulators()

def main():
    compile_all()

main()
