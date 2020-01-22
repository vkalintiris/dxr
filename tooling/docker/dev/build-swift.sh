#!/usr/bin/env bash

set -ex

SOURCE_FOLDER="$HOME/dxr/projects/swift-source"
OBJECT_FOLDER="$HOME/dxr/projects/build/swift-source"

mkdir -p "$SOURCE_FOLDER" "$OBJECT_FOLDER"

pushd "$SOURCE_FOLDER"

git clone https://github.com/apple/swift.git

# 2nd run will create llvm-project's symlinks
"$SOURCE_FOLDER/swift/utils/update-checkout" --clone --tag swift-5.1.2-RELEASE
"$SOURCE_FOLDER/swift/utils/update-checkout" --clone --tag swift-5.1.2-RELEASE

env SWIFT_BUILD_ROOT="$OBJECT_FOLDER" \
  "$SOURCE_FOLDER/swift/utils/build-script" \
    --extra-cmake-options="-DCMAKE_C_FLAGS=\"$DXR_CLANG_FLAGS\"" \
    --extra-cmake-options="-DCMAKE_CXX_FLAGS=\"$DXR_CLANG_FLAGS\"" \
    --extra-cmake-options="-DLLVM_PARALLEL_LINK_JOBS=2"

popd
