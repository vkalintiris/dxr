#!/usr/bin/env bash

set -exu

~/repos/tmp/swift-cref/clang+llvm-3.8.0-x86_64-apple-darwin/bin/clang \
  -isysroot /Applications/Xcode-11.2.1.11B500.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
  -Xclang -load -Xclang /Users/vkal/repos/tmp/swift-cref/dxr/dxr/plugins/clang/libclang-index-plugin.dylib \
  -Xclang -add-plugin -Xclang dxr-index \
  -Xclang -plugin-arg-dxr-index -Xclang . \
  main.c
