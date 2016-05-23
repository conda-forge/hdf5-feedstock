#!/bin/bash

./configure --prefix="${PREFIX}" \
            --enable-linux-lfs \
            --with-zlib="${PREFIX}" \
            --with-pthread=yes  \
            --enable-cxx \
            --enable-fortran \
            --with-default-plugindir="${PREFIX}/lib/hdf5/plugin"

# --enable-fortran2003

make
make check
make install

rm -rf $PREFIX/share/hdf5_examples
