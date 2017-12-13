cmake_minimum_required(VERSION 2.9)
include(ExternalProject)

# Parameters to be specified from command line
# OS name
# INSTALL_DIR if required to override

if(NOT DEFINED OS)
  message(FATAL_ERROR "Please specify an os (macosx, linux, windows), e.g. -DOS=linux")
elseif(OS STREQUAL "linux")
  set(LINUX YES)
  set(DLIB_SUFFIX ".so")
elseif(OS STREQUAL "macosx")
  set(MACOSX YES)
  set(DLIB_SUFFIX ".dylib")
elseif(OS STREQUAL "windows")
  set(WINDOWS YES)
  set(DLIB_SUFFIX ".dll")
  set(EXE_SUFFIX ".exe")
else()
    message(FATAL_ERROR "Not supported OS ${OS}" )
endif()

if(NOT DEFINED ARCH)
  set(ARCH "x86_64")
  set(X86_64 YES)
elseif (ARCH STREQUAL "x86")
  set(X86 YES)
elseif (ARCH STREQUAL "x86_64")
  set(X86_64 YES)
else()
    message(FATAL_ERROR "Not supported ARCH ${ARCH}")
endif()

set(EXTPREFIX "${CMAKE_BINARY_DIR}/ext")

if (WINDOWS)
  if(NOT DEFINED MINGW_VARIANT)
    message(FATAL_ERROR "Please setup MINGW_VARIANT, e.g. -DMINGW_VARIANT=x86_64-w64-mingw32 variable")
  endif()

  # the name of the target operating system
  SET(CMAKE_SYSTEM_NAME Windows)

  # which compilers to use for C and C++
  SET(CMAKE_C_COMPILER ${MINGW_VARIANT}-gcc)
  SET(CMAKE_CXX_COMPILER ${MINGW_VARIANT}-g++)
  SET(CMAKE_RC_COMPILER ${MINGW_VARIANT}-windres)

  SET(TENTATIVE_WIN32_ROOTS "-DCMAKE_FIND_ROOT_PATH=/usr/${MINGW_VARIANT}")
  SET(TENTATIVE_WIN32_FIND_ROOT_PATH_MODE_PROGRAM "-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER")
  SET(TENTATIVE_WIN32_FIND_ROOT_PATH_MODE_LIBRARY "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY")
  SET(TENTATIVE_WIN32_FIND_ROOT_PATH_MODE_INCLUDE "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY")
endif()

project(robovm-xib2nib)

message (STATUS "OS=${OS}")
message (STATUS "ARCH=${ARCH}")

ExternalProject_Add(extxib2nib
  SVN_REPOSITORY https://github.com/dkimitsa/WinObjC/branches/xib2nib/tools/vsimporter/xib2nib
  UPDATE_COMMAND ""
  CONFIGURE_COMMAND cmake -DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}
                          "${TENTATIVE_WIN32_ROOTS}"
                          "${TENTATIVE_WIN32_FIND_ROOT_PATH_MODE_PROGRAM}"
                          "${TENTATIVE_WIN32_FIND_ROOT_PATH_MODE_LIBRARY}"
                          "${TENTATIVE_WIN32_FIND_ROOT_PATH_MODE_INCLUDE}"
                          -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
                          -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
                          -DCMAKE_RC_COMPILER=${CMAKE_RC_COMPILER}
                          -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                          "-DCMAKE_INSTALL_PREFIX=${EXTPREFIX}"
                           ../extxib2nib/
)

add_custom_target(robovm-xib2nib)
add_dependencies(robovm-xib2nib extxib2nib)


if (DEFINED INSTALL_DIR)
  # replace template with values
  string(REPLACE "_OS_" "${OS}" INSTALL_DIR ${INSTALL_DIR})
  string(REPLACE "_ARCH_" "${ARCH}" INSTALL_DIR ${INSTALL_DIR})
  message (STATUS "Custom install dir=${INSTALL_DIR}")

  add_custom_command(TARGET robovm-xib2nib POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy
                            ${EXTPREFIX}/bin/xib2nib${EXE_SUFFIX}
                            ${INSTALL_DIR})
endif(DEFINED INSTALL_DIR)
