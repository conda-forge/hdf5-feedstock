#!/bin/bash

export EXTRA_CONFIG_FLAGS=""

if [ "$(uname)" == "Linux" ]; then
    export CC="${PREFIX}/bin/mpicc"
    export CXX="${PREFIX}/bin/mpic++"
    export EXTRA_CONFIG_FLAGS="--enable-parallel=yes"
fi

if [ "$(uname)" == "Darwin" ]; then
    export CXX="${CXX} -stdlib=libc++"
    export LDFLAGS="${LDFLAGS} -Wl,-rpath,$PREFIX/lib"
fi

export LIBRARY_PATH="${PREFIX}/lib"

./configure --prefix="${PREFIX}" \
            --enable-linux-lfs \
            --with-zlib="${PREFIX}" \
            --with-pthread=yes  \
            --enable-cxx \
            --enable-fortran \
            --enable-fortran2003 \
            --with-default-plugindir="${PREFIX}/lib/hdf5/plugin" \
            --enable-threadsafe \
            --enable-production \
            --enable-unsupported \
            --with-ssl "${EXTRA_CONFIG_FLAGS}"

#             --disable-static \
make -j "${CPU_COUNT}"
make check
make install

rm -rf $PREFIX/share/hdf5_examples
