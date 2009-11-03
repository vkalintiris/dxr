#!/bin/sh

# Safely (i.e., no install) gets/builds all tools needed to run dxr.js script in ./tools
#
# Depends on:
#   * Mozilla Build Environment for Linux (https://developer.mozilla.org/en/Linux_Build_Prerequisites)
#   * Mercurial
#   * autoconf-2.13
#   * mpfr-devel
#
# On Fedora you can do:
#
#  su -c "yum groupinstall 'Development Tools' 'Development Libraries' 'GNOME Software Development'"
#  su -c "yum install mercurial autoconf213" 
#  su -c "yum install mpfr-devel"

mkdir tools
cd tools
TOOLSDIR=${PWD}

# Grab and build new mozilla-central
hg clone http://hg.mozilla.org/mozilla-central/ ./mozilla-central
cd mozilla-central

# jshydra currently needs SpiderMonkey at rev ea128fc02710, see: 
# http://hg.mozilla.org/users/Pidgeot18_gmail.com/jshydra/file/17651ca38478/configure#l3
hg update -r ea128fc02710

# Setup a basic mozconfig file
echo '. $topsrcdir/browser/config/mozconfig' > .mozconfig
echo 'mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/objdir' >> .mozconfig
echo 'mk_add_options MOZ_MAKE_FLAGS="-j4"' >> .mozconfig

# Build
make -f client.mk
cd ..

if [ "$?" -ne 0 ]; then echo "ERROR - mozilla-central build failed, aborting."; exit 1; fi

# Build jshydra, which will also get mozilla-central
hg clone http://hg.mozilla.org/users/Pidgeot18_gmail.com/jshydra/ ./jshydra
cd ./jshydra
./configure --moz-src=${TOOLSDIR}/mozilla-central --moz-obj=${TOOLSDIR}/mozilla-central/objdir
make

if [ "$?" -ne 0 ]; then echo "ERROR - jshydra build failed, aborting."; exit 1; fi

# Clean-up after jshydra build
cd ./mozilla
hg st -un | xargs rm -f

# Update mozilla-central to tip again for SpiderMonkey/dehydra build
cd ${TOOLSDIR}/mozilla-central
hg update tip
cd ${TOOLSDIR}

# Build SpiderMonkey
cp -R ./mozilla-central/js/ ./js
cd ./js/src
autoconf-2.13
mkdir build-release
cd build-release
../configure --prefix=../../../SpiderMonkey
make
if [ "$?" -ne 0 ]; then echo "ERROR - SpiderMonkey build failed, aborting."; exit 1; fi
make install

# Make custom gcc with plugin support
cd ../../..
mkdir gcc-dehydra
cd gcc-dehydra
wget ftp://ftp.nluug.nl/mirror/languages/gcc/releases/gcc-4.3.0/gcc-4.3.0.tar.bz2
tar jxvf gcc-4.3.0.tar.bz2
cd gcc-4.3.0/ 
hg init .
hg clone http://hg.mozilla.org/users/tglek_mozilla.com/gcc-moz-plugin-mq .hg/patches
(for file in `cat .hg/patches/series`; do cat .hg/patches/$file; done) |patch -p1 
cd ..
mkdir gcc-build 
cd gcc-build
# For 32-bit OS, use this:
# ../gcc-4.3.0/configure --without-libstdcxx --enable-checking --disable-bootstrap CFLAGS="-g3 -O0" --enable-languages=c,c++ --enable-__cxa_atexit --prefix=$PWD/../installed 
../gcc-4.3.0/configure --without-libstdcxx --enable-languages=c,c++ --disable-multilib --prefix=$PWD/../installed
make
if [ "$?" -ne 0 ]; then echo "ERROR - GCC with plugin support build failed, aborting."; exit 1; fi
make install

# Build Dehydra
cd ..
#http://hg.mozilla.org/users/tglek_mozilla.com/dehydra-gcc/
hg clone http://hg.mozilla.org/rewriting-and-analysis/dehydra/
export CXX=${TOOLSDIR}/gcc-dehydra/installed/bin/g++
cd dehydra
./configure --js-libs=../../SpiderMonkey/lib/ --js-headers=../../SpiderMonkey/include/js
make
if [ "$?" -ne 0 ]; then echo "ERROR - Dehydra build failed, aborting."; exit 1; fi

# Build glimpse + glimpseindex
cd ${TOOLSDIR}
wget http://webglimpse.net/trial/glimpse-latest.tar.gz
tar xzf glimpse-latest.tar.gz
rm glimpse-latest.tar.gz
cd glimpse-*
./configure
make
if [ "$?" -ne 0 ]; then echo "ERROR - Glimpse build failed, aborting."; exit 1; fi

echo
echo "DXR Tools Built Successfully:"
echo "  GCC with plugin support  ${TOOLSDIR}/gcc-dehydra/installed/bin/g++"
echo "  Dehydra GCC plugin       ${TOOLSDIR}/gcc-dehydra/dehydra/gcc_dehydra.so"
echo "  jshydra                  ${TOOLSDIR}/jshydra/jshydra"
echo "  glimpse                  ${PWD}/bin/glimpse"
echo "  glimpseindex             ${PWD}/bin/glimpseindex"
