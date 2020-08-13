#!/usr/bin/python3
from distutils.core import setup
from distutils.extension import Extension
from distutils.command.sdist import sdist as _sdist

try:
    from Cython.Distutils import build_ext
except ImportError:
    use_cython = False
else:
    use_cython = True

cmds = {}
if use_cython:
    
    extensions = [
        Extension("LEDSerialExpanderBoard.DisplayLED", ["src/LEDSerialExpanderBoard.pyx"])
    ]
    cmds.update({'build_ext': build_ext})
else:
    extensions = [
        Extension("LEDSerialExpanderBoard.DisplayLED", ["src/LEDSerialExpanderBoard.c"])
    ]
 
class sdist(_sdist):
    def run(self):
        # Make sure the compiled Cython files in the distribution are up-to-date
        from Cython.Build import cythonize
        cythonize(extensions)
        _sdist.run(self)
cmds['sdist'] = sdist

with open("requirements.txt") as fp:
    install_requires = fp.read().strip().split("\n")

setup(
    name = "LEDSerialExpanderBoard",
    ext_modules=extensions,
    cmdclass = cmds,
    install_requires=install_requires
)
