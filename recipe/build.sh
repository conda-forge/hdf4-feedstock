#!/bin/bash

set -ex

# The Fortran code uses implicit casting, which newer gfortran versions don't allow
export FFLAGS="${FFLAGS} -fallow-argument-mismatch"

# Link to settings in repository
ln -s config/cmake/scripts/CTestScript.cmake CTestScript.cmake
ln -s config/cmake/scripts/HDF4config.cmake HDF4config.cmake

mkdir build
cd build
cmake ${CMAKE_ARGS} -G "Unix Makefiles" \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_PREFIX_PATH="${PREFIX}" \
      -DCMAKE_BUILD_TYPE="Release" \
      -DBUILD_SHARED_LIBS="ON" \
      -DHDF4_NO_PACKAGES="ON" \
      -DHDF4_BUILD_EXAMPLES="OFF" \
      -DHDF4_BUILD_FORTRAN="ON" \
      -DHDF4_ENABLE_NETCDF="OFF" \
      -DHDF4_ENABLE_JPEG_LIB_SUPPORT="ON" \
      -DHDF4_ENABLE_Z_LIB_SUPPORT="ON" \
      -Wno-dev ..

make -j "${CPU_COUNT}"
make test
make install

# Link to old library name
cd ${PREFIX}/lib
ln -s libhdf.a libdf.a
ln -s libhdf.so libdf.so
ln -s libhdf.so.4 libdf.so.0
