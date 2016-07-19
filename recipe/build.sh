#!/bin/bash

# FIXME: This is a hack to make sure the environment is activated.
# The reason this is required is due to the conda-build issue
# mentioned below.
#
# https://github.com/conda/conda-build/issues/910
#
source activate "${CONDA_DEFAULT_ENV}"

if [ "$(uname)" == "Darwin" ]
then
    export CXX="${CXX} -stdlib=libc++"
fi

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
