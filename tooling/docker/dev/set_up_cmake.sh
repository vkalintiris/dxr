#!/bin/sh -e
# Do the Ubuntu-specific setup necessary to run DXR on any Ubuntu box for any
# purpose. This is reusable for prod, as we don't do anything specific to
# development or CI.

curl -L -o /opt/cmake.tar.gz \
  'https://github.com/Kitware/CMake/releases/download/v3.16.3/cmake-3.16.3-Linux-x86_64.tar.gz'

cd /opt/
tar xf cmake.tar.gz && rm cmake.tar.gz
mv cmake-* cmake
