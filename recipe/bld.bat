@echo on
setlocal EnableDelayedExpansion

mkdir build
cd build

:: Set environment variables.
set HDF5_EXT_ZLIB=zlib.lib
echo "FC=%FC%"
:: Needed by IFX
set "LIB=%BUILD_PREFIX%\Library\lib;%LIB%"
set "INCLUDE=%BUILD_PREFIX%\opt\compiler\include\intel64;%INCLUDE%"
set "CMAKE_ARGS=!CMAKE_ARGS! -D HDF5_BUILD_FORTRAN:BOOL=ON"

set "CXXFLAGS=%CXXFLAGS% -LTCG"
if "%mpi%"=="impi" (
  :: cmake generates syntax errors if there are backslashes in paths
  set _LIBRARY=%LIBRARY_PREFIX:\=/%
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_C_ADDITIONAL_INCLUDE_DIRS:PATH=!_LIBRARY!/include"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_CXX_ADDITIONAL_INCLUDE_DIRS:PATH=!_LIBRARY!/include"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_FC_ADDITIONAL_INCLUDE_DIRS:PATH=!_LIBRARY!/include"
  :: --- Only Fortran MPI variables added below ---
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_Fortran_COMPILER:PATH=!_LIBRARY!/bin/mpiifx.bat"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_Fortran_INCLUDE_PATH:PATH=%BUILD_PREFIX%\opt\compiler\include"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_Fortran_MODULE_DIR:PATH=%BUILD_PREFIX%\opt\compiler\include\intel64"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_Fortran_WORKS:BOOL=ON"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_Fortran_LIB_NAMES=IMPI"
  :: --- End Fortran MPI additions ---
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_C_LIB_NAMES=IMPI"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_CXX_LIB_NAMES=IMPI"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_IMPI_LIBRARY:PATH=!_LIBRARY!/lib/impi.lib"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_ASSUME_NO_BUILTIN_MPI=ON"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_SKIP_COMPILER_WRAPPER=ON"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_SKIP_GUESSING=ON"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D HDF5_ENABLE_PARALLEL:BOOL=ON"
)

echo "CMAKE_ARGS=!CMAKE_ARGS!"

:: Configure step.
cmake -G "Ninja" ^
      !CMAKE_ARGS! ^
      -D CMAKE_BUILD_TYPE:STRING=RELEASE ^
      -D CMAKE_PREFIX_PATH:PATH=%LIBRARY_PREFIX% ^
      -D CMAKE_INSTALL_PREFIX:PATH=%LIBRARY_PREFIX% ^
      -D HDF5_BUILD_CPP_LIB:BOOL=ON ^
      -D CMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON ^
      -D BUILD_SHARED_LIBS:BOOL=ON ^
      -D BUILD_STATIC_LIBS:BOOL=OFF ^
      -D ONLY_SHARED_LIBS:BOOL=ON ^
      -D HDF5_BUILD_HL_LIB:BOOL=ON ^
      -D HDF5_BUILD_TOOLS:BOOL=ON ^
      -D HDF5_BUILD_HL_GIF_TOOLS:BOOL=ON ^
      -D HDF5_ENABLE_Z_LIB_SUPPORT:BOOL=ON ^
      -D HDF5_ENABLE_THREADSAFE:BOOL=ON ^
      -D HDF5_ENABLE_ROS3_VFD:BOOL=ON ^
      -D HDF5_ENABLE_SZIP_SUPPORT=ON ^
      -D ALLOW_UNSUPPORTED:BOOL=ON ^
      %SRC_DIR%
if errorlevel 1 (
  dir CMakeFiles
  type CMakeFiles/CMakeOutput.log
  type CMakeFiles/CMakeError.log
  type CMakeFiles/CMakeConfigureLog.yaml
  exit 1
)

:: Build C libraries and tools.
ninja
if errorlevel 1 exit 1

:: Install step.
ninja install
if errorlevel 1 exit 1

:: Remove extraneous COPYING file that gets installed automatically
:: https://github.com/conda-forge/hdf5-feedstock/issues/87
del /f %PREFIX%\Library\COPYING
if errorlevel 1 exit 1
del /f %PREFIX%\Library\RELEASE.txt
if errorlevel 1 exit 1

:: Remove Libs.private from h5.pc
:: See https://github.com/conda-forge/hdf5-feedstock/issues/238
findstr /V "Libs.private"  %LIBRARY_PREFIX%\\lib\\pkgconfig\\hdf5.pc > hdf5.pc.new
if errorlevel 1 exit 1
move /y hdf5.pc.new %LIBRARY_PREFIX%\\lib\\pkgconfig\\hdf5.pc
if errorlevel 1 exit 1
