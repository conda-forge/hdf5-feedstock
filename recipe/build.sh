
#!/bin/bash

export LIBRARY_PATH="${PREFIX}/lib"

if [[ ! -z "$mpi" && "$mpi" != "nompi" ]]; then
  export CONFIGURE_ARGS="--enable-parallel ${CONFIGURE_ARGS}"
  export CC=mpicc
  export CXX=mpic++
  export FC=mpifort
  if [[ $(uname) == "Linux" ]]; then
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

./configure --prefix="${PREFIX}" \
            ${CONFIGURE_ARGS} \
            --with-pic \
            --host="${HOST}" \
            --build="${BUILD}" \
            --enable-linux-lfs \
            --with-zlib="${PREFIX}" \
            --with-pthread=yes  \
            --enable-cxx \
            --enable-fortran \
            --enable-fortran2003 \
            --with-default-plugindir="${PREFIX}/lib/hdf5/plugin" \
            --enable-threadsafe \
            --enable-build-mode=production \
            --enable-unsupported \
            --enable-using-memchecker \
            --enable-clear-file-buffers \
            --with-ssl \
            --enable-static=yes \

# allow oversubscribing with openmpi in make check
export OMPI_MCA_rmaps_base_oversubscribe=yes

# using || to quiet logs unless there is an issue
{
    make -j "${CPU_COUNT}" ${VERBOSE_AT} >& make_logs.txt
} || {
    tail -n 5000 make_logs.txt
    exit 1
}

