#!/bin/bash
set -ex

if [[ "$CONDA_BUILD_CROSS_COMPILATION" == 1 && $target_platform == "osx-arm64" ]]; then
  # using default values for conversion tests:
  # H5_LDOUBLE_TO_LONG_SPECIAL=FALSE
  # H5_LONG_TO_LDOUBLE_SPECIAL=FALSE
  # H5_LDOUBLE_TO_LLONG_ACCURATE=TRUE
  # H5_LLONG_TO_LDOUBLE_CORRECT=TRUE
  # H5_DISABLE_SOME_LDOUBLE_CONV=TRUE

  # using fortran types defaults except for float types
  # MR6108 sets them in cache so pass them directly via cmake args
  CMAKE_FORTRAN_ARGS="-DPAC_FC_ALL_REAL_KINDS={4,8} -DPAC_FC_ALL_REAL_KINDS_SIZEOF={4,8} -DPAC_FORTRAN_NUM_REAL_KINDS=2"
  CMAKE_FORTRAN_ARGS="${CMAKE_FORTRAN_ARGS} -DPAC_FC_MAX_REAL_PRECISION=15 -DPAC_C_MAX_REAL_PRECISION=17"
  # here are the default integer settings:
  # PAC_FC_ALL_INTEGER_KINDS={1,2,4,8,16}, PAC_FORTRAN_NUM_INTEGER_KINDS=5

  # must be the same when generating sources though native builds
  CMAKE_ARGS="${CMAKE_ARGS} ${CMAKE_FORTRAN_ARGS}"
fi

if [[ "$CONDA_BUILD_CROSS_COMPILATION" == 1 && "${CROSSCOMPILING_EMULATOR:-}" == "" ]]; then
  # here we cannot run target binaries
  CMAKE_ARGS="${CMAKE_ARGS} -DBUILD_TESTING=OFF"

  # native build to generate binaries for source generation
  CC=$CC_FOR_BUILD CXX=$CXX_FOR_BUILD FC=$FC_FOR_BUILD \
  CFLAGS= CXXFLAGS= FFLAGS= CPPFLAGS= LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX} \
  OMPI_CC= OMPI_CXX= OMPI_FC= \
  cmake ${CMAKE_FORTRAN_ARGS} -LAH -G "Ninja" \
    -DHDF5_BUILD_FORTRAN=ON \
    -DCMAKE_PREFIX_PATH=$BUILD_PREFIX \
    -B build_native .
  cmake --build build_native --target H5match_types H5_buildiface H5HL_buildiface

  # copy generated sources into a "pregen" dir
  mkdir -p /tmp/pregen
  cp -v ./build_native/fortran/H5fortran_types.F90 /tmp/pregen
  cp -v ./build_native/fortran/H5_gen.F90 /tmp/pregen
  cp -v ./build_native/fortran/H5f90i_gen.h /tmp/pregen
  cp -v ./build_native/hl/fortran/H5LTff_gen.F90 /tmp/pregen
  cp -v ./build_native/hl/fortran/H5TBff_gen.F90 /tmp/pregen
  CMAKE_ARGS="${CMAKE_ARGS} -DHDF5_USE_PREGEN=ON -DHDF5_USE_PREGEN_DIR=/tmp/pregen"
fi

if [[ "$target_platform" == linux-* ]]; then
    # Direct Virtual File System (O_DIRECT) is only valid for linux
    CMAKE_ARGS="${CMAKE_ARGS} -DHDF5_ENABLE_DIRECT_VFD=ON"
fi

if [[ ! -z "$mpi" && "$mpi" != "nompi" ]]; then
  CMAKE_ARGS="${CMAKE_ARGS} -DHDF5_ENABLE_PARALLEL=ON -DMPIEXEC_MAX_NUMPROCS=${CPU_COUNT}"

  export CC=$PREFIX/bin/mpicc
  export CXX=$PREFIX/bin/mpic++
  export FC=$PREFIX/bin/mpifort

  if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
    export CC_FOR_BUILD=$BUILD_PREFIX/bin/mpicc
    export CXX_FOR_BUILD=$BUILD_PREFIX/bin/mpic++
    export FC_FOR_BUILD=$BUILD_PREFIX/bin/mpifort
    if [[ "$mpi" == "openmpi" ]]; then
      # openmpi compilers are binaries, so always need to use build prefix
      # linking is governed by environment variables
      # openmpi env enables cross-compile by default in conda-build
      export CC=$CC_FOR_BUILD
      export CXX=$CXX_FOR_BUILD
      export FC=$FC_FOR_BUILD
    fi
  else
    export CC_FOR_BUILD=$PREFIX/bin/mpicc
    export CXX_FOR_BUILD=$PREFIX/bin/mpic++
    export FC_FOR_BUILD=$PREFIX/bin/mpifort
  fi
fi

cmake ${CMAKE_ARGS} -LAH -G "Ninja" \
  -DHDF5_ENABLE_ZLIB_SUPPORT=ON \
  -DHDF5_ENABLE_SZIP_SUPPORT=ON \
  -DHDF5_BUILD_CPP_LIB=ON \
  -DHDF5_BUILD_HL_LIB=ON \
  -DHDF5_BUILD_FORTRAN=ON \
  -DHDF5_BUILD_EXAMPLES=OFF \
  -DHDF5_H5CC_C_COMPILER=`basename ${CC}` \
  -DHDF5_H5CC_CXX_COMPILER=`basename ${CXX}` \
  -DHDF5_H5CC_Fortran_COMPILER=`basename ${FC}` \
  -DH5_DEFAULT_PLUGINDIR="${PREFIX}/lib/hdf5/plugin" \
  -DHDF5_ENABLE_THREADSAFE=ON \
  -DHDF5_ALLOW_UNSUPPORTED=ON \
  -DHDF5_ENABLE_USING_MEMCHECKER=ON \
  -DHDF5_ENABLE_ROS3_VFD=ON \
  -DHDF5_ENABLE_NONSTANDARD_FEATURES=OFF \
  -DBUILD_STATIC_LIBS=OFF \
  -B build .
cmake --build build --target install --parallel ${CPU_COUNT}

# Remove Libs.private from hdf5.pc
# See https://github.com/conda-forge/hdf5-feedstock/issues/238
sed -i.bak '/^Libs\.private/d' ${PREFIX}/lib/pkgconfig/hdf5.pc
rm -f ${PREFIX}/lib/pkgconfig/hdf5.pc.bak

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR:-}" != "" ]]; then
  ctest --verbose --test-dir build --output-on-failure --schedule-random -j${CPU_COUNT} --timeout 1000 || cat build/Testing/Temporary/LastTestsFailed.log
fi
