# Stop on first error
set -e

# Test C compiler
echo "Testing h5cc"
h5cc -show
h5cc h5_cmprss.c -o h5_cmprss
./h5_cmprss

# Test C++ compiler
echo "Testing h5c++"
h5c++ -show
h5c++ h5tutr_cmprss.cpp -o h5tutr_cmprss
./h5tutr_cmprss

# Test Fortran compiler. For this we need to set DYLD_FALLBACK_LIBRARY_PATH to
# make sure libgfortran gets picked up. Ideally this shouldn't be needed, but
# this is how the gfortran compiler works in conda - see:
#
#   https://github.com/ContinuumIO/anaconda-issues/issues/739
#
# for more details.

export DYLD_FALLBACK_LIBRARY_PATH=${CONDA_PREFIX}/lib

echo "Testing h5fc"
h5fc -show
h5fc h5_cmprss.f90 -o h5_cmprss
./h5_cmprss
