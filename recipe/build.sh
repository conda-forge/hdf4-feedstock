#!/bin/bash

set -ex

# Build with CMake rather than autotools.  HDF4's autotools build refuses to
# build the Fortran interface and shared libraries at the same time
# (configure.ac: "Cannot build shared fortran libraries"), so the previous
# --enable-shared build had to pass --disable-fortran.  The CMake build has no
# such restriction, so we get shared C libraries AND the Fortran interface in a
# single build.  See conda-forge/hdf4-feedstock#39.

# HDF4 4.2.15's Fortran stubs pass mismatched argument types (e.g. CHARACTER(*)
# vs INTEGER(4)) to the same routine, which gfortran >= 10 rejects by default.
# conda-forge ships a modern gfortran, so allow the legacy mismatch.  See
# conda-forge/hdf4-feedstock#39.
export FFLAGS="${FFLAGS:-} -fallow-argument-mismatch"
export FCFLAGS="${FCFLAGS:-} -fallow-argument-mismatch"

# The ncgen/ncdump/hdiff tools are K&R-era C (undeclared yyerror/getopt/write,
# implicit int), which GCC 14+ and clang 16+ reject; the libraries are clean.
export CFLAGS="${CFLAGS:-} -Wno-error=implicit-function-declaration -Wno-error=implicit-int"

mkdir build
cd build

# HDF4_ENABLE_NETCDF=OFF keeps HDF4's bundled netCDF-2 API out of the package so
# it cannot clash with the real netcdf-c (same reason the autotools build passed
# --disable-netcdf).  With it off the mfhdf header installs as hdf4_netcdf.h.
cmake ${CMAKE_ARGS} \
    -G Ninja \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX="${PREFIX}" \
    -D CMAKE_INSTALL_LIBDIR=lib \
    -D CMAKE_PREFIX_PATH="${PREFIX}" \
    -D BUILD_SHARED_LIBS=ON \
    -D BUILD_STATIC_LIBS=ON \
    -D HDF4_BUILD_FORTRAN=ON \
    -D HDF4_BUILD_JAVA=OFF \
    -D HDF4_ENABLE_NETCDF=OFF \
    -D HDF4_BUILD_XDR_LIB=OFF \
    -D HDF4_BUILD_HL_LIB=ON \
    -D HDF4_BUILD_TOOLS=ON \
    -D HDF4_BUILD_UTILS=ON \
    -D HDF4_BUILD_EXAMPLES=OFF \
    -D HDF4_ENABLE_Z_LIB_SUPPORT=ON \
    -D HDF4_ENABLE_JPEG_LIB_SUPPORT=ON \
    -D HDF4_ENABLE_SZIP_SUPPORT=OFF \
    -D BUILD_TESTING=OFF \
    ..

cmake --build . -j "${CPU_COUNT}"
cmake --install .

# The autotools build also shipped free-form .f90 copies of the Fortran include
# files (hdf.f90, dffunc.f90, mffunc.f90), generated from the fixed-form .inc;
# the CMake build installs only the .inc.  Free-form consumers include e.g.
# "hdf.f90", so regenerate them with HDF4's own conversion (hdf/src/Makefile.am:
# .inc.f90 rule): turn fixed-form C-comments and column-6 continuations into
# free-form.
pushd "${PREFIX}/include"
for base in hdf dffunc mffunc; do
    if [[ -f "${base}.inc" && ! -f "${base}.f90" ]]; then
        sed -e 's/^[cC]/!/' -e 's/^     [^ ]/     \&/' "${base}.inc" > "${base}.f90"
    fi
done
popd

# Avoid clashing binary names with the netcdf package (the autotools recipe did
# the same rename).  Only present if the tools were built.
for tool in ncdump ncgen; do
    if [[ -f "${PREFIX}/bin/${tool}" ]]; then
        mv "${PREFIX}/bin/${tool}" "${PREFIX}/bin/h4_${tool}"
    fi
done

# Strip docs/man/examples we do not ship.
rm -rf "${PREFIX}/share/man" "${PREFIX}/share/hdf4_examples" "${PREFIX}/examples" || true
