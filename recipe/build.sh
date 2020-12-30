#!/bin/bash

set -x

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* ./bin

export LIBRARY_PATH="${PREFIX}/lib"

if [[ ! -z "$mpi" && "$mpi" != "nompi" ]]; then
  export CONFIGURE_ARGS="--enable-parallel ${CONFIGURE_ARGS}"

  export CC=mpicc
  export CXX=mpic++
  export FC=mpifort
  export CC_FOR_BUILD=mpicc
  export CXX_FOR_BUILD=mpic++
  export FC_FOR_BUILD=mpifort

  if [[ "$target_platform" == linux-* ]]; then
    # --as-needed appears to cause problems with fortran compiler detection
    # due to missing libquadmath
    # unclear why required libs are stripped but still linked
    export FFLAGS="${FFLAGS:-} -Wl,--no-as-needed -Wl,--disable-new-dtags"
    export LDFLAGS="${LDFLAGS} -Wl,--no-as-needed -Wl,--disable-new-dtags"
  fi
else
  export CC=$(basename ${CC})
  export CXX=$(basename ${CXX})
  export F95=$(basename ${F95})
  export FC=$(basename ${FC})
fi

if [[ "$CONDA_BUILD_CROSS_COMPILATION" == 1 && $target_platform == "osx-arm64" ]]; then
  export ac_cv_sizeof_long_double=8
  export hdf5_cv_ldouble_to_long_special=no
  export hdf5_cv_long_to_ldouble_special=no
  export hdf5_cv_ldouble_to_llong_accurate=yes
  export hdf5_cv_llong_to_ldouble_correct=yes
  export hdf5_cv_disable_some_ldouble_conv=no
  export hdf5_cv_system_scope_threads=yes
  export hdf5_cv_printf_ll="l"
  export PAC_FC_MAX_REAL_PRECISION=15
  export PAC_C_MAX_REAL_PRECISION=17
  export PAC_FC_ALL_INTEGER_KINDS="{1,2,4,8,16}"
  export PAC_FC_ALL_REAL_KINDS="{4,8}"
  export H5CONFIG_F_NUM_RKIND="INTEGER, PARAMETER :: num_rkinds = 2"
  export H5CONFIG_F_NUM_IKIND="INTEGER, PARAMETER :: num_ikinds = 5"
  export H5CONFIG_F_RKIND="INTEGER, DIMENSION(1:num_rkinds) :: rkind = (/4,8/)"
  export H5CONFIG_F_IKIND="INTEGER, DIMENSION(1:num_ikinds) :: ikind = (/1,2,4,8,16/)"
  export PAC_FORTRAN_NATIVE_INTEGER_SIZEOF="                    4"
  export PAC_FORTRAN_NATIVE_INTEGER_KIND="           4"
  export PAC_FORTRAN_NATIVE_REAL_SIZEOF="                    4"
  export PAC_FORTRAN_NATIVE_REAL_KIND="           4"
  export PAC_FORTRAN_NATIVE_DOUBLE_SIZEOF="                    8"
  export PAC_FORTRAN_NATIVE_DOUBLE_KIND="           8"
  export PAC_FORTRAN_NUM_INTEGER_KINDS="5"
  export PAC_FC_ALL_REAL_KINDS_SIZEOF="{4,8}"
  export PAC_FC_ALL_INTEGER_KINDS_SIZEOF="{1,2,4,8,16}"
  export hdf5_disable_tests="--enable-tests=no"
fi

export OPAL_PREFIX=$BUILD_PREFIX

function swap()
{
  cp "$1" tmp && cp "$2" "$1" && cp tmp "$2"
}

function swap_mpi() {
  if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
    if [[ "$mpi" == "openmpi" ]]; then
      if [[ "$OPAL_PREFIX" == "$PREFIX" ]]; then
        export OPAL_PREFIX=$BUILD_PREFIX
      else
        export OPAL_PREFIX=$PREFIX
      fi
    elif [[ "$mpi" == "mpich" ]]; then
      swap $BUILD_PREFIX/bin/mpicc $PREFIX/bin/mpicc
      swap $BUILD_PREFIX/bin/mpic++ $PREFIX/bin/mpic++
      swap $BUILD_PREFIX/bin/mpifort $PREFIX/bin/mpifort
    fi
  fi
}

swap_mpi

./configure --prefix="${PREFIX}" \
            ${CONFIGURE_ARGS} \
            --with-pic \
            --host="${HOST}" \
            --build="${BUILD}" \
            --with-zlib="${PREFIX}" \
            --with-pthread=yes  \
            --enable-cxx \
            --enable-fortran \
            --with-default-plugindir="${PREFIX}/lib/hdf5/plugin" \
            --enable-threadsafe \
            --enable-build-mode=production \
            --enable-unsupported \
            --enable-using-memchecker \
            --enable-static=yes \
            --enable-ros3-vfd \
	    ${hdf5_disable_tests}

# allow oversubscribing with openmpi in make check
export OMPI_MCA_rmaps_base_oversubscribe=yes

if [[ "$CONDA_BUILD_CROSS_COMPILATION" == 1 ]]; then
  (
    swap_mpi
    # Make a native build of the hdetect and H5make_libsettings executables
    mkdir -p native-build/bin
    pushd native-build/bin

    # MACOSX_DEPLOYMENT_TARGET is for the target_platform and not for build_platform
    unset MACOSX_DEPLOYMENT_TARGET

    $CC_FOR_BUILD ../../src/H5detect.c -I ../../src/ -o H5detect
    $CC_FOR_BUILD ../../src/H5make_libsettings.c -I ../../src/ -o H5make_libsettings
    $CC_FOR_BUILD ../../fortran/src/H5match_types.c -I ../../src/ -o H5match_types
    $FC_FOR_BUILD ../../fortran/src/H5_buildiface.F90 -I ../../fortran/src/ -L $BUILD_PREFIX/lib -o H5_buildiface
    $FC_FOR_BUILD ../../hl/fortran/src/H5HL_buildiface.F90 -I ../../hl/fortran/src -I ../../fortran/src -L $BUILD_PREFIX/lib -o H5HL_buildiface
    swap_mpi
    popd
  )
  export PATH=`pwd`/native-build/bin:$PATH
fi

if [[ "$CI" != "travis" ]]; then
  make -j "${CPU_COUNT}" ${VERBOSE_AT}
else
# using || to quiet logs unless there is an issue
{
    # see this https://github.com/travis-ci/travis-ci/issues/4190#issuecomment-353342526
    while sleep 1m; do echo "make is still running..."; done &
    make -j "${CPU_COUNT}" ${VERBOSE_AT} >& make_logs.txt
    # make sure to kill the loop
    kill %1
} || {
    # make sure to kill the loop
    kill %1
    tail -n 5000 make_logs.txt
    exit 1
}
fi
