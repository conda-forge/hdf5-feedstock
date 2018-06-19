#!/bin/bash

if [ "$(uname)" == "Darwin" ]; then
    export CXX="${CXX} -stdlib=libc++"
    export LDFLAGS="${LDFLAGS} -Wl,-rpath,$PREFIX/lib"
fi

export LIBRARY_PATH="${PREFIX}/lib"

if [[ ! -z "$mpi" && "$mpi" != "nompi" ]]; then
  export CONFIGURE_ARGS="--enable-parallel ${CONFIGURE_ARGS}"
  export CC=mpicc
  export CXX=mpic++
  export FC=mpifort
fi

./configure --prefix="${PREFIX}" \
            ${CONFIGURE_ARGS} \
            --with-pic \
            --enable-linux-lfs \
            --with-zlib="${PREFIX}" \
            --with-pthread=yes  \
            --enable-cxx \
            --enable-fortran \
            --enable-fortran2003 \
            --with-default-plugindir="${PREFIX}/lib/hdf5/plugin" \
            --enable-threadsafe \
            --enable-shared \
            --enable-build-mode=production \
            --enable-unsupported \
            --with-ssl

# allow oversubscribing with openmpi in make check
export OMPI_MCA_rmaps_base_oversubscribe=yes

make -j "${CPU_COUNT}"
make check
make install

rm -rf $PREFIX/share/hdf5_examples
