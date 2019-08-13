make install

if [[ ${mpi} == "openmpi" && "$(uname)" == "Darwin" ]]; then
  # ph5diff hangs on darwin with openmpi, skip the test
  echo <<EOF > tools/test/h5diff/testph5diff.sh
#!/bin/sh
exit 0
EOF
fi
if [[ ! ${HOST} =~ .*powerpc64le.* ]]; then
  # https://github.com/h5py/h5py/issues/817
  # https://forum.hdfgroup.org/t/hdf5-1-10-long-double-conversions-tests-failed-in-ppc64le/4077
  make check RUNPARALLEL="${RECIPE_DIR}/mpiexec.sh -n 2"
fi

rm -rf $PREFIX/share/hdf5_examples

# remove the static libraries
rm -f libs/{libhdf5hl_fortran,libhdf5_hl_fortran,libhdf5_hl_cpp,libhdf5_hl,libhdf5_fortran,libhdf5_cpp,libhdf5}.a
