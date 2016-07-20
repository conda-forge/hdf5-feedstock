# Stop on first error
set -e

# Test C compiler
echo "Testing h5cc"
h5cc tests/h5_cmprss.c -o tests/h5_cmprss
./tests/h5_cmprss

# Test C++ compiler
echo "Testing h5c++"
h5c++ tests/h5tutr_cmprss.cpp -o tests/h5tutr_cmprss
./tests/h5tutr_cmprss

# Test Fortran compiler
echo "Testing h5fc"
h5fc tests/h5_cmprss.f90 -o h5_cmprss
./tests/h5_cmprss
