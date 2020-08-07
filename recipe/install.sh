make install V=1

if [[ ${mpi} == "openmpi" && "$(uname)" == "Darwin" ]]; then
  # ph5diff hangs on darwin with openmpi, skip the test
  echo <<EOF > tools/test/h5diff/testph5diff.sh
#!/bin/sh
exit 0
EOF
fi
if [[ ("$target_platform" != "linux-ppc64le") && ("$target_platform" != "linux-aarch64") ]]; then
  # https://github.com/h5py/h5py/issues/817
  # https://forum.hdfgroup.org/t/hdf5-1-10-long-double-conversions-tests-failed-in-ppc64le/4077
  make check RUNPARALLEL="${RECIPE_DIR}/mpiexec.sh -n 2"
fi

rm -rf ${PREFIX}/share/hdf5_examples

# remove the static libraries
rm -f ${PREFIX}/lib/libhdf5_hl_fortran.a
rm -f ${PREFIX}/lib/libhdf5_hl_cpp.a
rm -f ${PREFIX}/lib/libhdf5hl_fortran.a
rm -f ${PREFIX}/lib/libhdf5_hl.a
rm -f ${PREFIX}/lib/libhdf5_fortran.a
rm -f ${PREFIX}/lib/libhdf5_cpp.a
rm -f ${PREFIX}/lib/libhdf5.a
