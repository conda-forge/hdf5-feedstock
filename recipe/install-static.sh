#!/bin/bash

mkdir -p ${PREFIX}/lib


cp c++/src/.libs/libhdf5_cpp.a ${PREFIX}/lib
cp fortran/src/.libs/libhdf5_fortran.a ${PREFIX}/lib
cp hl/c++/src/.libs/libhdf5_hl_cpp.a ${PREFIX}/lib
cp hl/fortran/src/.libs/libhdf5hl_fortran.a ${PREFIX}/lib
cp hl/src/.libs/libhdf5_hl.a ${PREFIX}/lib
cp src/.libs/libhdf5.a ${PREFIX}/lib
