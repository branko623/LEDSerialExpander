#!/usr/bin/python3
from setuptools import setup,find_packages
from setuptools.extension import Extension
from distutils.command.sdist import sdist as _sdist


try:
    from Cython.Distutils import build_ext
    use_cython = True
except ImportError:
    use_cython = False

cmdclass = {}
if use_cython:
    extensions = [
        Extension("LEDSerialExpander", ["src/LEDSerialExpander.pyx"])
    ]
    cmdclass['build_ext'] = build_ext
else:
    extensions = [
        Extension("LEDSerialExpander", ["src/LEDSerialExpander.c"])
    ]
 
class sdist(_sdist):
    def run(self):
        # Make sure the compiled Cython files in the distribution are up-to-date
        from Cython.Build import cythonize
        cythonize(extensions)
        _sdist.run(self)
            
cmdclass['sdist'] = sdist

with open("requirements.txt") as fp:
    install_requires = fp.read().strip().split("\n")

setup(
    name = "LEDSerialExpander",
    url="https://github.com/branko623/LEDSerialExpander",
    author = "Branko Mirkovic",
    author_email = "branko623@gmail.com",
    description = "Expander Board Python Driver",
    packages = find_packages(),
    ext_modules=extensions,
    cmdclass = cmdclass,
    install_requires=install_requires
)
