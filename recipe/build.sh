#!/bin/bash
set -ex

mkdir -p build
cd build

# These tests are very problematic for MPI based builds
# They are not run on non-mpi
HDF5_DISABLE_TESTS_REGEX="MPI_TEST_testphdf5"
HDF5_DISABLE_TESTS_REGEX="${HDF5_DISABLE_TESTS_REGEX}|H5SHELL-test_flush_refresh"
# HDF5_DISABLE_TESTS_REGEX="${HDF5_DISABLE_TESTS_REGEX}|MPI_TEST_FORT_parallel_test"
# HDF5_DISABLE_TESTS_REGEX="${HDF5_DISABLE_TESTS_REGEX}|MPI_TEST_FORT_subfiling_test"
# HDF5_DISABLE_TESTS_REGEX="${HDF5_DISABLE_TESTS_REGEX}|MPI_TEST_FORT_async_test"

if [[ ! -z "$mpi" && "$mpi" != "nompi" ]]; then
  HDF5_ENABLE_PARALLEL=ON

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
else
  HDF5_ENABLE_PARALLEL=OFF
fi

if [[ "$target_platform" == linux-* ]]; then
  HDF5_ENABLE_DIRECT_VFD=ON
else
  HDF5_ENABLE_DIRECT_VFD=OFF
fi

if [[ "${target_platform}" = "linux-ppc64le" ]]; then
  # The test dt_arith seems to fail on pcc64le (at least when run with emulation)
  # https://github.com/HDFGroup/hdf5/blob/104bd625aba5c1507cd686dc18268e935fc68dd9/release_docs/HISTORY-1_14_0-2_0_0.txt#L1822
  HDF5_WANT_DCONV_EXCEPTION=OFF
else
  HDF5_WANT_DCONV_EXCEPTION=ON
fi

THESE_ARGS="${THESE_ARGS} -G Ninja"
THESE_ARGS="${THESE_ARGS} -D CMAKE_BUILD_TYPE:STRING=RELEASE"
THESE_ARGS="${THESE_ARGS} -D CMAKE_PREFIX_PATH:PATH=${PREFIX}"
THESE_ARGS="${THESE_ARGS} -D CMAKE_INSTALL_PREFIX:PATH=${PREFIX}"
THESE_ARGS="${THESE_ARGS} -D HDF5_BUILD_CPP_LIB:BOOL=ON"
THESE_ARGS="${THESE_ARGS} -D CMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON"
THESE_ARGS="${THESE_ARGS} -D BUILD_SHARED_LIBS:BOOL=ON"
THESE_ARGS="${THESE_ARGS} -D BUILD_STATIC_LIBS:BOOL=OFF"
THESE_ARGS="${THESE_ARGS} -D ONLY_SHARED_LIBS:BOOL=ON"
THESE_ARGS="${THESE_ARGS} -D HDF5_BUILD_HL_LIB:BOOL=ON"
THESE_ARGS="${THESE_ARGS} -D HDF5_BUILD_TOOLS:BOOL=ON"
THESE_ARGS="${THESE_ARGS} -D HDF5_ENABLE_ZLIB_SUPPORT:BOOL=ON"
THESE_ARGS="${THESE_ARGS} -D HDF5_ENABLE_THREADSAFE:BOOL=ON"
THESE_ARGS="${THESE_ARGS} -D HDF5_ENABLE_ROS3_VFD:BOOL=ON"
THESE_ARGS="${THESE_ARGS} -D HDF5_ENABLE_SZIP_SUPPORT:BOOL=ON"
THESE_ARGS="${THESE_ARGS} -D HDF5_ALLOW_UNSUPPORTED:BOOL=ON"
THESE_ARGS="${THESE_ARGS} -D HDF5_TEST_EXAMPLES:BOOL=OFF"
THESE_ARGS="${THESE_ARGS} -D HDF5_ENABLE_PARALLEL:BOOL=${HDF5_ENABLE_PARALLEL}"
THESE_ARGS="${THESE_ARGS} -D HDF5_ENABLE_DIRECT_VFD:BOOL=${HDF5_ENABLE_DIRECT_VFD}"
THESE_ARGS="${THESE_ARGS} -D HDF5_BUILD_FORTRAN:BOOL=ON"
THESE_ARGS="${THESE_ARGS} -D HDF5_H5CC_C_COMPILER:PATH=${PREFIX}/bin/$(basename ${CC})"
THESE_ARGS="${THESE_ARGS} -D HDF5_H5CC_CXX_COMPILER:PATH=${PREFIX}/bin/$(basename ${CXX})"
THESE_ARGS="${THESE_ARGS} -D HDF5_H5CC_Fortran_COMPILER:PATH=${PREFIX}/bin/$(basename ${FC})"
THESE_ARGS="${THESE_ARGS} -D HDF5_WANT_DCONV_EXCEPTION:BOOL=${HDF5_WANT_DCONV_EXCEPTION}"


# We don't have emulation in osx...
if [[ "$CONDA_BUILD_CROSS_COMPILATION" == 1 && $target_platform == "osx-arm64" ]]; then
  # Used an educated guess from our autotools history
  export HDF5_FORTRAN_VALID_INT_KINDS="1,2,4,8,16"
  export HDF5_FORTRAN_VALID_REAL_KINDS="4,8"
  export HDF5_FORTRAN_MAX_REAL_PRECISION="15"

  # I just guess the valud logical kinds here
  export HDF5_FORTRAN_VALID_LOGICAL_KINDS="1,2,4,8"
  export HDF5_FORTRAN_MPI_LOGICAL_KIND="4"

  # Used an educated guess from our autotools history
  export HDF5_FORTRAN_INTEGER_KINDS_SIZEOF="1,2,4,8,16"
  export HDF5_FORTRAN_REAL_KINDS_SIZEOF="4,8"
  export HDF5_FORTRAN_NATIVE_INTEGER_SIZEOF="4"
  export HDF5_FORTRAN_NATIVE_INTEGER_KIND="4"
  export HDF5_FORTRAN_NATIVE_REAL_SIZEOF="4"
  export HDF5_FORTRAN_NATIVE_REAL_KIND="4"
  export HDF5_FORTRAN_NATIVE_DOUBLE_SIZEOF="8"
  export HDF5_FORTRAN_NATIVE_DOUBLE_KIND="8"

  export H5MATCH_TYPES_COMPILER=${CC_FOR_BUILD}

  # Compile once, to generate the needed H5Match_types binary
  # This doesn't work---- hmaarrfk
  # CC=${CC_FOR_BUILD} CXX=${CXX_FOR_BUILD} FC=${FC_FOR_BUILD} cmake ${THESE_ARGS} ..
  # cmake --build . --target H5match_types
  # cp bin/H5match_types ${BUILD_PREFIX}/bin/.
  # export H5MATCH_TYPES_BIN="${BUILD_PREFIX}/bin/H5match_types"
  # rm -rf *
fi

cmake ${CMAKE_ARGS} ${THESE_ARGS} \
    -D HDF5_DISABLE_TESTS_REGEX="${HDF5_DISABLE_TESTS_REGEX}" \
    -D H5EX_BUILD_TESTING=OFF \
    ..

ninja -j${CPU_COUNT}

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR:-}" != "" ]]; then
    cmake --build . --target test
fi

ninja install

# Remove Libs.private from hdf5.pc
# See https://github.com/conda-forge/hdf5-feedstock/issues/238
sed -i.bak '/^Libs\.private/d' ${PREFIX}/lib/pkgconfig/hdf5.pc
rm -f ${PREFIX}/lib/pkgconfig/hdf5.pc.bak
