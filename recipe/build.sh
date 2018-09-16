#!/bin/bash

if [ "$(uname)" == "Darwin" ]; then
    export CXX="${CXX} -stdlib=libc++"
    export LDFLAGS="${LDFLAGS} -Wl,-rpath,$PREFIX/lib"
fi

export LIBRARY_PATH="${PREFIX}/lib"

cmake \
      -D CMAKE_BUILD_TYPE:STRING=RELEASE \
      -D CMAKE_PREFIX_PATH:PATH=$LIBRARY_PREFIX \
      -D CMAKE_INSTALL_PREFIX:PATH=$LIBRARY_PREFIX \
      -D HDF5_BUILD_CPP_LIB:BOOL=ON \
      -D CMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON \
      -D BUILD_SHARED_LIBS:BOOL=ON \
      -D HDF5_BUILD_HL_LIB:BOOL=ON \
      -D HDF5_BUILD_TOOLS:BOOL=ON \
      -D HDF5_ENABLE_Z_LIB_SUPPORT:BOOL=ON \
      -D HDF5_ENABLE_THREADSAFE:BOOL=ON \
      -D ALLOW_UNSUPPORTED:BOOL=ON \
      $SRC_DIR

make -j "${CPU_COUNT}"
make check
make install

rm -rf $PREFIX/share/hdf5_examples

# We can remove this when we start using the new conda-build.
find $PREFIX -name '*.la' -delete
