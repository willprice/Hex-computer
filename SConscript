# vim: set ft=python:
sources={ 'xhexs.x'  : 'compiler_8_bit.x',
          'xhexb.x'  : 'compiler_32_bit.x',
          'xhexsa.x' : 'assembly_compiler_8_bit.x',
          'xhexba.x' : 'assembly_compiler_32_bix.x',
          'xhexb.bin': 'compiler_32_bit.bin',
          'hexsimb.c': 'simulator_32_bit.c',
          'hexsim.c': 'simulator_8_bit.c',
        }


def rename_files():
    for file_pair in sources.iteritems():
        source = file_pair[0]
        if file_exists(source):
            rename_file(file_pair)

def file_exists(file):
    return File(file).exists()

def rename_file(file_pair):
    old_source = file_pair[0]
    new_source = file_pair[1]

    Execute(Move(new_source, old_source))

def compile_simulators():
    rename_files()
    Program('32_bit_sim', 'simulator_32_bit.c')
    Program('8_bit_sim', 'simulator_8_bit.c')

def compile_all():
    compile_simulators()

compile_all()
