#!/bin/bash

if [ "$(uname)" == "Darwin" ]; then
    export CXX="${CXX} -stdlib=libc++"
    export LDFLAGS="${LDFLAGS} -Wl,-rpath,$PREFIX/lib"
fi

export LIBRARY_PATH="${PREFIX}/lib"

mkdir -p build
cd build

cmake -G"$CMAKE_GENERATOR" \
      -DCMAKE_BUILD_TYPE:STRING=RELEASE \
      -DCMAKE_PREFIX_PATH:PATH=$PREFIX \
      -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX \
      -DHDF5_BUILD_CPP_LIB:BOOL=ON \
      -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON \
      -DBUILD_SHARED_LIBS:BOOL=ON \
      -DHDF5_BUILD_HL_LIB:BOOL=ON \
      -DHDF5_BUILD_TOOLS:BOOL=ON \
      -DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=ON \
      -DHDF5_ENABLE_THREADSAFE:BOOL=ON \
      -DALLOW_UNSUPPORTED:BOOL=ON \
      -DHDF_BUILD_FORTRAN:BOOL=ON \
      -DHDF_ENABLE_PARALLEL:BOOL=ON \
      $SRC_DIR

make -j "${CPU_COUNT}"
make install

rm -rf $PREFIX/share/hdf5_examples

# We can remove this when we start using the new conda-build.
find $PREFIX -name '*.la' -delete
