#!/usr/bin/env python2

import os
import pprint
import subprocess
import sys


LLVM_CONFIG = os.path.join(os.environ['LLVM_BINDIR'], 'llvm-config')
os.chdir(os.path.dirname(__file__))


SOURCES = ['dxr-index.cpp', 'sha1.cpp']
OBJECTS = [os.path.splitext(src)[0] + '.o' for src in SOURCES]


def get_ldflags():
    output = subprocess.check_output([LLVM_CONFIG, '--ldflags'], env=os.environ)
    return output.split()


def get_cxxflags():
    output = subprocess.check_output([LLVM_CONFIG, '--cxxflags'], env=os.environ)
    cxxflags = output.split()

    idx = cxxflags.index('-isysroot')
    del cxxflags[idx+1]
    del cxxflags[idx]

    cxxflags.append('-Wno-strict-aliasing')
    cxxflags.append('-Wno-deprecated-declarations')

    return cxxflags


def compile_sources():
    for src, obj in zip(SOURCES, OBJECTS):
        if os.path.isfile(obj):
            continue

        cmd = ['xcrun', 'clang++'] + get_cxxflags() + [ '-c', src, '-o', obj]
        subprocess.check_call(cmd)


def link_objects():
    if os.path.isfile('libclang-index-plugin.dylib'):
        return

    cmd = ['xcrun', 'clang++', '-v'] + get_ldflags()
    cmd.extend(['-Xlinker', '-undefined', '-Xlinker', 'dynamic_lookup'])
    cmd.extend([ '-dynamiclib', '-o', 'libclang-index-plugin.dylib'])
    cmd.extend(OBJECTS)

    subprocess.check_call(cmd)


compile_sources()
link_objects()
