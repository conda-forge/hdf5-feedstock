#!/bin/bash

mkdir -p ${PREFIX}/lib
cp \
  {libhdf5hl_fortran,libhdf5_hl_fortran,libhdf5_hl_cpp,libhdf5_hl,libhdf5_fortran,libhdf5_cpp,libhdf5}.a \
  ${PREFIX}/lib/