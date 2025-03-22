#!/bin/bash
set -e

mkdir -p build
cd build

if [[ ! -z "$mpi" && "$mpi" != "nompi" ]]; then
  HDF5_ENABLE_PARALLEL=ON
else
  HDF5_ENABLE_PARALLEL=OFF
fi

if [[ "$target_platform" == linux-* ]]; then
  HDF5_ENABLE_DIRECT_VFD=ON
else
  HDF5_ENABLE_DIRECT_VFD=OFF
fi

# We don't have emulation in osx...
if [[ "$CONDA_BUILD_CROSS_COMPILATION" == 1 && $target_platform == "osx-arm64" ]]; then
  export H5_SIZEOF_LONG_DOUBLE=8
  export H5_LDOUBLE_TO_LONG_SPECIAL=NO
  export H5_LONG_TO_LDOUBLE_SPECIAL=NO
  export H5_LDOUBLE_TO_LLONG_ACCURATE=YES
  export H5_LLONG_TO_LDOUBLE_CORRECT=YES
  export H5_DISABLE_SOME_LDOUBLE_CONV=NO
  export H5_SYSTEM_SCOPE_THREADS=YES
  export H5_PAC_FC_MAX_REAL_PRECISION=15
  export H5_PAC_C_MAX_REAL_PRECISION=17
  export H5_PAC_FC_ALL_INTEGER_KINDS="{1,2,4,8,16}"
  export H5_PAC_FC_ALL_REAL_KINDS="{4,8}"
  export H5_H5CONFIG_F_NUM_IKIND="INTEGER, PARAMETER :: num_ikinds = 5"
  export H5_H5CONFIG_F_NUM_RKIND="INTEGER, PARAMETER :: num_rkinds = 2"
  export H5_H5CONFIG_F_IKIND="INTEGER, DIMENSION(1:num_ikinds) :: ikind = (/1,2,4,8,16/)"
  export H5_H5CONFIG_F_RKIND="INTEGER, DIMENSION(1:num_rkinds) :: rkind = (/4,8/)"
  export H5_PAC_FORTRAN_NATIVE_INTEGER_SIZEOF="                    4"
  export H5_PAC_FORTRAN_NATIVE_INTEGER_KIND="           4"
  export H5_PAC_FORTRAN_NATIVE_REAL_SIZEOF="                    4"
  export H5_PAC_FORTRAN_NATIVE_REAL_KIND="           4"
  export H5_PAC_FORTRAN_NATIVE_DOUBLE_SIZEOF="                    8"
  export H5_PAC_FORTRAN_NATIVE_DOUBLE_KIND="           8"
  export H5_PAC_FORTRAN_NUM_INTEGER_KINDS="5"
  export H5_PAC_FC_ALL_REAL_KINDS_SIZEOF="{4,8}"
  export H5_PAC_FC_ALL_INTEGER_KINDS_SIZEOF="{1,2,4,8,16}"
fi

# Configure step
cmake $CMAKE_ARGS \
      -D CMAKE_BUILD_TYPE:STRING=RELEASE \
      -D CMAKE_PREFIX_PATH:PATH=${PREFIX} \
      -D CMAKE_INSTALL_PREFIX:PATH=${PREFIX} \
      -D HDF5_BUILD_CPP_LIB:BOOL=ON \
      -D CMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON \
      -D BUILD_SHARED_LIBS:BOOL=ON \
      -D BUILD_STATIC_LIBS:BOOL=OFF \
      -D ONLY_SHARED_LIBS:BOOL=ON \
      -D HDF5_BUILD_HL_LIB:BOOL=ON \
      -D HDF5_BUILD_TOOLS:BOOL=ON \
      -D HDF5_BUILD_HL_GIF_TOOLS:BOOL=ON \
      -D HDF5_ENABLE_Z_LIB_SUPPORT:BOOL=ON \
      -D HDF5_ENABLE_THREADSAFE:BOOL=ON \
      -D HDF5_ENABLE_ROS3_VFD:BOOL=ON \
      -D HDF5_ENABLE_SZIP_SUPPORT:BOOL=ON \
      -D ALLOW_UNSUPPORTED:BOOL=ON \
      -D HDF5_TEST_EXAMPLES:BOOL=OFF \
      -D HDF5_ENABLE_PARALLEL:BOOL=${HDF5_ENABLE_PARALLEL} \
      -D HDF5_ENABLE_DIRECT_VFD:BOOL=${HDF5_ENABLE_DIRECT_VFD} \
      -D HDF5_BUILD_FORTRAN:BOOL=ON \
      ..

make -j${CPU_COUNT}
make install

if [[ ${mpi} == "mpich" || (${mpi} == "openmpi" && "$(uname)" == "Darwin") ]]; then
  # ph5diff hangs on darwin with openmpi, skip the test
  # ph5diff also crashes on mpich 4.1
  echo <<EOF > tools/test/h5diff/testph5diff.sh
#!/bin/sh
exit 0
EOF
fi

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1"  ]]; then
    if [[ ${mpi} == "mvapich" ]]; then
        # Setting environment variables to allow oversubscription
        export MV2_ENABLE_AFFINITY=0
        # Run tests excluding specific ones using ctest
        ctest -E "(t_bigio|t_pmulti_dset|t_filters_parallel|t_cache_image)"
    else
        # Run parallel tests on native platforms
        # https://github.com/h5py/h5py/issues/817
        # https://forum.hdfgroup.org/t/hdf5-1-10-long-double-conversions-tests-failed-in-ppc64le/4077
        # make check RUNPARALLEL="mpiexec -n 2"
        # echo how do i run make check in parallel???
        make test
    fi
elif [[ "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
    # make check
    make test
fi
