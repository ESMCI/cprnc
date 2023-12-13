cmake_minimum_required (VERSION 3.14)
project (cprnc Fortran C)
include (CheckFunctionExists)
include (ExternalProject)

#===== Local modules =====
list (APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

#==============================================================================
#  DEFINE THE TARGET
#==============================================================================

set (CPRNC_Fortran_SRCS cprnc.F90  filestruct.F90  prec.F90  utils.F90)

set (CPRNC_GenF90_SRCS compare_vars_mod.F90)


set (CPRNC_Fortran_MODS ${CMAKE_CURRENT_BINARY_DIR}/compare_vars_mod.mod
                        ${CMAKE_CURRENT_BINARY_DIR}/filestruct.mod
                        ${CMAKE_CURRENT_BINARY_DIR}/prec.mod)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_MACOSX_RPATH 1)

# Compiler-specific compile options
if ("${CMAKE_Fortran_COMPILER_ID}" STREQUAL "GNU")
  set (CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -ffree-line-length-none")
endif()

if (CMAKE_BUILD_TYPE STREQUAL "DEBUG")
  set (CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -O0 -g")
endif()

#==============================================================================
#  DEFINE THE DEPENDENCIES
#==============================================================================

#===== genf90 =====
if (DEFINED GENF90_PATH)
  # If GENF90_PATH is defined, the target may also already be defined
  if (NOT TARGET genf90)
    add_custom_target(genf90
      DEPENDS ${GENF90_PATH}/genf90.pl)
  endif()
else ()
  ExternalProject_Add (genf90
    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/genf90
    GIT_REPOSITORY https://github.com/PARALLELIO/genf90
    GIT_TAG genf90_200608
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND "")
  ExternalProject_Get_Property (genf90 SOURCE_DIR)
  set (GENF90_PATH ${SOURCE_DIR})
  unset (SOURCE_DIR)
endif ()


file(COPY  ${CMAKE_CURRENT_SOURCE_DIR}/run_tests
     DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink ${CMAKE_CURRENT_SOURCE_DIR}/test_inputs ${CMAKE_CURRENT_BINARY_DIR}/test_inputs)

#===== Fortran Source Generation with GenF90 =====
foreach (SRC_FILE IN LISTS CPRNC_GenF90_SRCS)
  add_custom_command (OUTPUT ${SRC_FILE}
    COMMAND ${GENF90_PATH}/genf90.pl
    ${CMAKE_CURRENT_SOURCE_DIR}/${SRC_FILE}.in > ${SRC_FILE}
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${SRC_FILE}.in genf90)
endforeach ()

#===== NetCDF-Fortran =====
INCLUDE(FindNetCDF)
find_library(netcdf_fortran_lib netcdff HINTS ${NetCDF_Fortran_ROOT})
#message (STATUS "netcdf_fortran_lib == ${netcdf_fortran_lib}")
get_filename_component(netcdf_fortran_lib_location ${netcdf_fortran_lib} DIRECTORY)
#message (STATUS "netcdf_fortran_lib_location == ${netcdf_fortran_lib_location}")

find_library(netcdf_c_lib netcdf HINTS ${NetCDF_C_LIBRARY})
#message (STATUS "netcdf_c_lib == ${netcdf_c_lib}")
get_filename_component(netcdf_c_lib_location ${netcdf_c_lib} DIRECTORY)
#message (STATUS "netcdf_c_lib_location == ${netcdf_c_lib_location}")

list(APPEND CMAKE_BUILD_RPATH ${netcdf_fortran_lib_location} ${netcdf_c_lib_location})
#message("CMAKE_BUILD_RPATH is ${CMAKE_BUILD_RPATH}")
add_executable (cprnc ${CPRNC_Fortran_SRCS} ${CPRNC_GenF90_SRCS})
#message("Setting include dir ${NetCDF_Fortran_INCLUDE_DIRS}")
target_include_directories(cprnc PUBLIC ${CMAKE_CURRENT_SOURCE_DIR} ${NetCDF_Fortran_INCLUDE_DIRS})

add_dependencies (cprnc genf90)

# Always use -fPIC
set_property(TARGET cprnc PROPERTY POSITION_INDEPENDENT_CODE ON)
target_link_libraries (cprnc
    PUBLIC ${NetCDF_Fortran_LIBRARIES} ${NetCDF_C_LIBRARIES} ${NetCDF_LIBRARIES})


enable_testing()
add_test(NAME run_tests COMMAND run_tests -outdir tmp)

#==============================================================================
#  DEFINE THE INSTALL
#==============================================================================

# Executable
install (TARGETS cprnc DESTINATION bin)
