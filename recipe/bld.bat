@echo on
setlocal EnableDelayedExpansion

mkdir build
cd build

:: Set environment variables.
set HDF5_EXT_ZLIB=zlib.lib


set "CXXFLAGS=%CXXFLAGS% -LTCG"
if "%mpi%"=="impi" (
  :: cmake generates syntax errors if there are backslashes in paths
  set _LIBRARY=%LIBRARY_PREFIX:\=/%
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_C_ADDITIONAL_INCLUDE_DIRS:PATH=!_LIBRARY!/include"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_CXX_ADDITIONAL_INCLUDE_DIRS:PATH=!_LIBRARY!/include"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_C_LIB_NAMES=IMPI"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_CXX_LIB_NAMES=IMPI"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_IMPI_LIBRARY:PATH=!_LIBRARY!/lib/impi.lib"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_ASSUME_NO_BUILTIN_MPI=ON"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_SKIP_COMPILER_WRAPPER=ON"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_SKIP_GUESSING=ON"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D HDF5_ENABLE_PARALLEL:BOOL=ON"
)

echo "CMAKE_ARGS=!CMAKE_ARGS!"
:: gif tools have an unresolved CVE https://github.com/HDFGroup/hdf5/pull/2313
set "HDF5_BUILD_HL_LIB=OFF"
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
      -D HDF5_BUILD_HL_GIF_TOOLS:BOOL=%HDF5_BUILD_HL_LIB% ^
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
