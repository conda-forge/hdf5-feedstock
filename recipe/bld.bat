mkdir build
cd build

:: Set environment variables.
set HDF5_EXT_ZLIB=zlib.lib

set "CXXFLAGS=%CXXFLAGS% -LTCG"

:: Configure step.
cmake -G "Ninja" ^
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
      -D SZIP_LIBRARY:FILEPATH=%LIBRARY_PREFIX%\lib\libsz.lib ^
      -D SZIP_INCLUDE_DIR:PATH=%LIBRARY_PREFIX%\include ^
      -D HDF5_ENABLE_THREADSAFE:BOOL=ON ^
      -D HDF5_ENABLE_ROS3_VFD:BOOL=ON ^
      -D ALLOW_UNSUPPORTED:BOOL=ON ^
      %SRC_DIR%
if errorlevel 1 exit 1

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
:: We move the shared executables to a name withtout the -shared prefix to ensure
:: the yare found by programs that expect them in the standard location
:: https://github.com/conda-forge/hdf5-feedstock/pull/188
echo Moving %LIBRARY_PREFIX%\bin\h5repart-shared.exe %LIBRARY_PREFIX%\bin\h5repart.exe
move %LIBRARY_PREFIX%\bin\h5repart-shared.exe %LIBRARY_PREFIX%\bin\h5repart.exe
if errorlevel 1 exit 1

echo Moving %LIBRARY_PREFIX%\bin\h5debug-shared.exe %LIBRARY_PREFIX%\bin\h5debug.exe
move %LIBRARY_PREFIX%\bin\h5debug-shared.exe %LIBRARY_PREFIX%\bin\h5debug.exe
if errorlevel 1 exit 1

echo Moving %LIBRARY_PREFIX%\bin\h5jam-shared.exe %LIBRARY_PREFIX%\bin\h5jam.exe
move %LIBRARY_PREFIX%\bin\h5jam-shared.exe %LIBRARY_PREFIX%\bin\h5jam.exe
if errorlevel 1 exit 1

echo Moving %LIBRARY_PREFIX%\bin\h5unjam-shared.exe %LIBRARY_PREFIX%\bin\h5unjam.exe
move %LIBRARY_PREFIX%\bin\h5unjam-shared.exe %LIBRARY_PREFIX%\bin\h5unjam.exe
if errorlevel 1 exit 1

echo Moving %LIBRARY_PREFIX%\bin\h5clear-shared.exe %LIBRARY_PREFIX%\bin\h5clear.exe
move %LIBRARY_PREFIX%\bin\h5clear-shared.exe %LIBRARY_PREFIX%\bin\h5clear.exe
if errorlevel 1 exit 1

echo Moving %LIBRARY_PREFIX%\bin\h52gif-shared.exe %LIBRARY_PREFIX%\bin\h52gif.exe
move %LIBRARY_PREFIX%\bin\h52gif-shared.exe %LIBRARY_PREFIX%\bin\h52gif.exe
if errorlevel 1 exit 1

echo Moving %LIBRARY_PREFIX%\bin\h5mkgrp-shared.exe %LIBRARY_PREFIX%\bin\h5mkgrp.exe
move %LIBRARY_PREFIX%\bin\h5mkgrp-shared.exe %LIBRARY_PREFIX%\bin\h5mkgrp.exe
if errorlevel 1 exit 1

echo Moving %LIBRARY_PREFIX%\bin\h5format_convert-shared.exe %LIBRARY_PREFIX%\bin\h5format_convert.exe
move %LIBRARY_PREFIX%\bin\h5format_convert-shared.exe %LIBRARY_PREFIX%\bin\h5format_convert.exe
if errorlevel 1 exit 1

echo Moving %LIBRARY_PREFIX%\bin\gif2h5-shared.exe %LIBRARY_PREFIX%\bin\gif2h5.exe
move %LIBRARY_PREFIX%\bin\gif2h5-shared.exe %LIBRARY_PREFIX%\bin\gif2h5.exe
if errorlevel 1 exit 1

echo Moving %LIBRARY_PREFIX%\bin\h5copy-shared.exe %LIBRARY_PREFIX%\bin\h5copy.exe
move %LIBRARY_PREFIX%\bin\h5copy-shared.exe %LIBRARY_PREFIX%\bin\h5copy.exe
if errorlevel 1 exit 1

echo Moving %LIBRARY_PREFIX%\bin\h5stat-shared.exe %LIBRARY_PREFIX%\bin\h5stat.exe
move %LIBRARY_PREFIX%\bin\h5stat-shared.exe %LIBRARY_PREFIX%\bin\h5stat.exe
if errorlevel 1 exit 1

echo Moving %LIBRARY_PREFIX%\bin\h5import-shared.exe %LIBRARY_PREFIX%\bin\h5import.exe
move %LIBRARY_PREFIX%\bin\h5import-shared.exe %LIBRARY_PREFIX%\bin\h5import.exe
if errorlevel 1 exit 1

echo Moving %LIBRARY_PREFIX%\bin\h5watch-shared.exe %LIBRARY_PREFIX%\bin\h5watch.exe
move %LIBRARY_PREFIX%\bin\h5watch-shared.exe %LIBRARY_PREFIX%\bin\h5watch.exe
if errorlevel 1 exit 1

echo Moving %LIBRARY_PREFIX%\bin\h5diff-shared.exe %LIBRARY_PREFIX%\bin\h5diff.exe
move %LIBRARY_PREFIX%\bin\h5diff-shared.exe %LIBRARY_PREFIX%\bin\h5diff.exe
if errorlevel 1 exit 1

echo Moving %LIBRARY_PREFIX%\bin\h5repack-shared.exe %LIBRARY_PREFIX%\bin\h5repack.exe
move %LIBRARY_PREFIX%\bin\h5repack-shared.exe %LIBRARY_PREFIX%\bin\h5repack.exe
if errorlevel 1 exit 1

echo Moving %LIBRARY_PREFIX%\bin\h5ls-shared.exe %LIBRARY_PREFIX%\bin\h5ls.exe
move %LIBRARY_PREFIX%\bin\h5ls-shared.exe %LIBRARY_PREFIX%\bin\h5ls.exe
if errorlevel 1 exit 1

echo Moving %LIBRARY_PREFIX%\bin\h5dump-shared.exe %LIBRARY_PREFIX%\bin\h5dump.exe
move %LIBRARY_PREFIX%\bin\h5dump-shared.exe %LIBRARY_PREFIX%\bin\h5dump.exe
if errorlevel 1 exit 1
