#!/bin/bash

set -x

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

# The compiler flags interfere with th build and we need to overide them :-/
if [[ $(uname) == Darwin ]]; then
  unset CPPFLAGS
  export CPPFLAGS="-Wl,-rpath,$PREFIX/lib -I${PREFIX}/include"

  unset LDFLAGS
  export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib -headerpad_max_install_names"
fi

autoreconf -vfi

# The --enable-silent-rules is needed because Travis CI dies on the long output from this build.
./configure --prefix=${PREFIX}\
            --host=$HOST \
            --enable-linux-lfs \
            --enable-silent-rules \
            --enable-shared \
            --with-ssl \
            --with-zlib \
            --with-jpeg \
            --disable-netcdf \
            --disable-fortran \
            --disable-static

make

# ncgen segfaults on macOS
if [[ $(uname) != Darwin ]]; then
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
# The following tests seems to fail on ppc64le when runing on azure with emulation
# Testing reading of netCDF file using the SDxxx interface (tnetcdf.c)
# *** Routine netCDF Read Test 1. SDstart failed on file test1.nc FAILED at line 176 ***
# *** Routine SDstart FAILED at line 83 ***
if [[ "${target_platform}" != "linux-ppc64le" ]]; then
make check
fi
fi
fi

make install


# Remove man pages.
rm -rf ${PREFIX}/share

# Avoid clashing names with netcdf.
mv ${PREFIX}/bin/ncdump ${PREFIX}/bin/h4_ncdump
mv ${PREFIX}/bin/ncgen ${PREFIX}/bin/h4_ncgen

# People usually Google these.
rm -rf ${PREFIX}/examples
