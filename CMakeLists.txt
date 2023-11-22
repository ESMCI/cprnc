cmake_minimum_required (VERSION 3.14)
project (cprnc Fortran C)
include (CheckFunctionExists)
include (ExternalProject)

#===== Local modules =====
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

#==============================================================================
#  DEFINE THE TARGET
#==============================================================================

set (CPRNC_Fortran_SRCS cprnc.F90  filestruct.F90  prec.F90  utils.F90)

set (CPRNC_GenF90_SRCS compare_vars_mod.F90)


set (CPRNC_Fortran_MODS ${CMAKE_CURRENT_BINARY_DIR}/compare_vars_mod.mod
                        ${CMAKE_CURRENT_BINARY_DIR}/filestruct.mod
                        ${CMAKE_CURRENT_BINARY_DIR}/prec.mod)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

add_executable (cprnc ${CPRNC_Fortran_SRCS} ${CPRNC_GenF90_SRCS})
# Always use -fPIC
set_property(TARGET cprnc PROPERTY POSITION_INDEPENDENT_CODE ON)

# Compiler-specific compile options
if ("${CMAKE_Fortran_COMPILER_ID}" STREQUAL "GNU")
  target_compile_options (cprnc
    PRIVATE -ffree-line-length-none)
endif()

if (CMAKE_BUILD_TYPE STREQUAL "DEBUG")
     set (CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -g")
endif()

#==============================================================================
#  DEFINE THE INSTALL
#==============================================================================

# Executable
install (TARGETS cprnc DESTINATION bin)

#==============================================================================
#  DEFINE THE DEPENDENCIES
#==============================================================================

#===== genf90 =====
if (DEFINED GENF90_PATH)
  add_custom_target(genf90
    DEPENDS ${GENF90_PATH}/genf90.pl)
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
add_dependencies (cprnc genf90)

file(COPY  ${CMAKE_CURRENT_SOURCE_DIR}/run_tests
     DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink ${CMAKE_CURRENT_SOURCE_DIR}/test_inputs ${CMAKE_CURRENT_BINARY_DIR}/test_inputs)
enable_testing()
add_test(NAME run_tests COMMAND run_tests -outdir tmp)

#===== Fortran Source Generation with GenF90 =====
foreach (SRC_FILE IN LISTS CPRNC_GenF90_SRCS)
  add_custom_command (OUTPUT ${SRC_FILE}
    COMMAND ${GENF90_PATH}/genf90.pl
    ${CMAKE_CURRENT_SOURCE_DIR}/${SRC_FILE}.in > ${SRC_FILE}
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${SRC_FILE}.in genf90)
endforeach ()

#===== NetCDF-Fortran =====
INCLUDE(FindNetCDF Fortran)
if (NetCDF_Fortran_FOUND)
  target_include_directories (cprnc
    PUBLIC ${NetCDF_Fortran_INCLUDE_DIRS})
  target_link_libraries (cprnc
    PUBLIC ${NetCDF_Fortran_LIBRARIES})
endif ()


#===== Check for necessities =====
if (NOT NetCDF_Fortran_FOUND)
  message (FATAL_ERROR "Must have NetCDF Fortran libraries")
endif ()


