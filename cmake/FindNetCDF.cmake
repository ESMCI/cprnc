# First try to locate nf-config.
find_program(NetCDF_Fortran_CONFIG_EXECUTABLE
    NAMES nf-config
    HINTS ENV NetCDF_ROOT ENV NetCDF_Fortran_ROOT
    PATH_SUFFIXES bin Bin
    DOC "NetCDF config program. Used to detect NetCDF Fortran include directory and linker flags." )
mark_as_advanced(NetCDF_Fortran_CONFIG_EXECUTABLE)
find_program(NetCDF_C_CONFIG_EXECUTABLE
    NAMES nc-config
    HINTS ENV NetCDF_ROOT ENV NetCDF_C_ROOT
    PATH_SUFFIXES bin Bin
    DOC "NetCDF config program. Used to detect NetCDF C include directory and linker flags." )
mark_as_advanced(NetCDF_C_CONFIG_EXECUTABLE)


if(NetCDF_Fortran_CONFIG_EXECUTABLE)
    # Found nf-config - use it to retrieve include directory and linking flags.
    # Note that if the process fails (as e.g. on Windows), the output variables
    # will remain empty
  execute_process(COMMAND ${NetCDF_Fortran_CONFIG_EXECUTABLE} --includedir
                    OUTPUT_VARIABLE DEFAULT_Fortran_INCLUDE_DIR
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(COMMAND ${NetCDF_Fortran_CONFIG_EXECUTABLE} --flibs
                    OUTPUT_VARIABLE flibs
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
  if (flibs)
    set(NetCDF_Fortran_LIBRARIES ${flibs} CACHE STRING "NetCDF libraries (or linking flags)")
    set(AUTODETECTED_NetCDF_Fortran_LIBRARIES ON)
  endif()

  execute_process(COMMAND ${NetCDF_Fortran_CONFIG_EXECUTABLE} --prefix
                    OUTPUT_VARIABLE root
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
  if (root)
    set(NetCDF_Fortran_ROOT ${root} CACHE STRING "NetCDF Fortran Root")
    set(AUTODETECTED_NetCDF_Fortran_ROOT ON)
  endif()

endif()

if(NetCDF_C_CONFIG_EXECUTABLE)
    # Found nc-config - use it to retrieve include directory and linking flags.
    # Note that if the process fails (as e.g. on Windows), the output variables
    # will remain empty
  execute_process(COMMAND ${NetCDF_C_CONFIG_EXECUTABLE} --includedir
                    OUTPUT_VARIABLE DEFAULT_C_INCLUDE_DIR
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(COMMAND ${NetCDF_C_CONFIG_EXECUTABLE} --libs
                    OUTPUT_VARIABLE clibs
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
  if (clibs)
    set(NetCDF_C_LIBRARIES ${libs} CACHE STRING "NetCDF libraries (or linking flags)")
    set(AUTODETECTED_NetCDF_C ON)
  endif()

endif()

# Determine default name of NetCDf library
# If nf-config succeeded, its result takes priority as it has already been
# used to set NetCDF_LIBRARIES
if(DEFINED ENV{NetCDFLIBNAME})
  set(DEFAULT_LIBRARY_NAME "$ENV{NETCDFLIBNAME}")
else()
  set(DEFAULT_LIBRARY_NAME netcdff)
endif()

find_path(NetCDF_Fortran_INCLUDE_DIRS netcdf.mod
  HINTS "${DEFAULT_Fortran_INCLUDE_DIR}" "$ENV{NetCDF_Fortran_INCLUDE_DIRS}" "$ENV{CONDA_PREFIX}/Library/include"
  DOC "NetCDF Fortran include directories")

find_library(NetCDF_Fortran_LIBRARY NAMES ${DEFAULT_LIBRARY_NAME}
            HINTS "${DEFAULT_LIBRARY_DIR}" "$ENV{NetCDF_Fortran_LIBRARY}" "$ENV{CONDA_PREFIX}/Library/lib"
            DOC "NetCDF libraries (or linking flags)")

find_path(NetCDF_C_INCLUDE_DIRS netcdf.h
  HINTS "${DEFAULT_C_INCLUDE_DIR}" "$ENV{NetCDF_C_INCLUDE_DIRS}" "$ENV{CONDA_PREFIX}/Library/include"
  DOC "NetCDF C include directories")

find_library(NetCDF_C_LIBRARY NAMES ${DEFAULT_LIBRARY_NAME}
            HINTS "${DEFAULT_LIBRARY_DIR}" "$ENV{NetCDF_C_LIBRARY}" "$ENV{CONDA_PREFIX}/Library/lib"
            DOC "NetCDF C libraries (or linking flags)")

if(AUTODETECTED_NetCDF)
  mark_as_advanced(NetCDF_Fortran_INCLUDE_DIRS NetCDF_Fortran_LIBRARIES)
  mark_as_advanced(NetCDF_C_INCLUDE_DIRS NetCDF_C_LIBRARIES)
  mark_as_advanced(NetCDF_Fortran_ROOT)
endif()

# Process default arguments (QUIET, REQUIRED)
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args (NetCDF DEFAULT_MSG NetCDF_Fortran_LIBRARIES NetCDF_Fortran_INCLUDE_DIRS)
find_package_handle_standard_args (NetCDF DEFAULT_MSG NetCDF_C_LIBRARIES NetCDF_C_INCLUDE_DIRS)

add_library(netcdf INTERFACE IMPORTED GLOBAL)
set_property(TARGET netcdf APPEND PROPERTY INTERFACE_INCLUDE_DIRECTORIES "${NetCDF_C_INCLUDE_DIRS} ${NetCDF_Fortran_INCLUDE_DIRS}")
set_property(TARGET netcdf APPEND PROPERTY INTERFACE_LINK_LIBRARIES "${NetCDF_Fortran_LIBRARIES} ${NetCDF_C_LIBRARIES}")
