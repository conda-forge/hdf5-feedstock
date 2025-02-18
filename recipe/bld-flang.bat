@echo on
setlocal EnableDelayedExpansion

mkdir build
cd build

REM set clanglibdir=%CONDA_PREFIX:\=/%/lib/clang/19/lib/windows
REM copy "%clanglibdir%\clang_rt.builtins-x86_64.lib" "%LIBRARY_LIB%\clang_rt.builtins.lib"

:: Set environment variables.
set HDF5_EXT_ZLIB=zlib.lib

:: temporarily vendor flang compiler activation
set "FC=flang-new"
set "CC=clang-cl"
set "CXX=clang-cl"

:: need to read clang version for path to compiler-rt
FOR /F "tokens=* USEBACKQ" %%F IN (`clang.exe -dumpversion`) DO (
    SET "CLANG_VER=%%F"
)

set "CFLAGS=-w"
set "FFLAGS=-D_CRT_SECURE_NO_WARNINGS -D_MT -D_DLL --target=x86_64-pc-windows-msvc"
set "LDFLAGS=--target=x86_64-pc-windows-msvc -fms-runtime-lib=dll -fuse-ld=lld"
set "LDFLAGS=%LDFLAGS% -Wl,-defaultlib:%BUILD_PREFIX%/Library/lib/clang/!CLANG_VER:~0,2!/lib/windows/clang_rt.builtins-x86_64.lib"


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

:: Configure step.
cmake -G "Ninja" ^
      !CMAKE_ARGS! ^
      -D CMAKE_BUILD_TYPE:STRING=RELEASE ^
      -D CMAKE_PREFIX_PATH:PATH=%LIBRARY_PREFIX% ^
      -D CMAKE_INSTALL_PREFIX:PATH=%LIBRARY_PREFIX% ^
      -D CMAKE_Fortran_COMPILER:STRING=%FC% ^
      -D HDF5_BUILD_CPP_LIB:BOOL=ON ^
      -D CMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON ^
      -D BUILD_SHARED_LIBS:BOOL=ON ^
      -D BUILD_STATIC_LIBS:BOOL=OFF ^
      -D ONLY_SHARED_LIBS:BOOL=ON ^
      -D HDF5_BUILD_HL_LIB:BOOL=ON ^
      -D HDF5_BUILD_TOOLS:BOOL=ON ^
      -D HDF5_BUILD_FORTRAN:BOOL=ON ^
      -D HDF5_BUILD_HL_GIF_TOOLS:BOOL=ON ^
      -D HDF5_ENABLE_Z_LIB_SUPPORT:BOOL=ON ^
      -D HDF5_ENABLE_THREADSAFE:BOOL=ON ^
      -D HDF5_ENABLE_ROS3_VFD:BOOL=ON ^
      -D HDF5_ENABLE_SZIP_SUPPORT=ON ^
      -D ALLOW_UNSUPPORTED:BOOL=ON ^
      %SRC_DIR%

if errorlevel 1 (
  dir CMakeFiles
  type CMakeFiles\CMakeOutput.log
  type CMakeFiles\CMakeError.log
  type CMakeFiles\CMakeConfigureLog.yaml
  exit /b 1
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
