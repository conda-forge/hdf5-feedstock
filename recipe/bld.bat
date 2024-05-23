@echo on
setlocal EnableDelayedExpansion

mkdir build
cd build

:: Set environment variables.
set HDF5_EXT_ZLIB=zlib.lib

set "CXXFLAGS=%CXXFLAGS% -LTCG"
if "%mpi%"=="impi" (
  set "CMAKE_ARGS=!CMAKE_ARGS! -D MPI_C_LIBRARIES=impi"
  :: set "CMAKE_ARGS=!CMAKE_ARGS! -D CMAKE_C_COMPILER=%LIBRARY_PREFIX%\bin\mpicc.bat"
  :: set "CMAKE_ARGS=!CMAKE_ARGS! -D CMAKE_CXX_COMPILER=%LIBRARY_PREFIX%\bin\mpicxx.bat"
  set "CMAKE_ARGS=!CMAKE_ARGS! -D HDF5_ENABLE_PARALLEL:BOOL=ON"
)

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
  type CMakeFiles/CMakeOutput.log
  type CMakeFiles/CMakeError.log
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


:: The CMake Build process adds a -shared at the end of every exe when you don't
:: build the static libraries.
:: We copy the shared executables to a name without the -shared suffix to ensure
:: they are found by programs that expect them in the standard location
:: We cannot move the files since the generated CMake files from HDF5 still
:: expect them to exists with the -shared suffix
:: https://github.com/conda-forge/hdf5-feedstock/pull/188
for %%path in (%LIBRARY_PREFIX%\bin\*-shared.exe) do (
  set "shared_exe=%%path"
  set "new_exe=!shared:-shared.exe:.exe!
  copy !shared_exe! !new_exe!
  if errorlevel 1 exit 1
)
