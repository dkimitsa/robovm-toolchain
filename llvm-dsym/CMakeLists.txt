cmake_minimum_required(VERSION 2.8)
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

  SET(TENTATIVE_WIN32_FLAGS "-DWIN32=true" "-DCROSS_TOOLCHAIN_FLAGS_NATIVE=-DCMAKE_TOOLCHAIN_FILE=${CMAKE_SOURCE_DIR}/host_linux.cmake")
endif()

project(robovm-llvm-dsym)

message (STATUS "OS=${OS}")
message (STATUS "ARCH=${ARCH}")

set(EXTPREFIX "${CMAKE_BINARY_DIR}/ext")

ExternalProject_Add(extllvm
  URL http://releases.llvm.org/5.0.0/llvm-5.0.0.src.tar.xz
  PATCH_COMMAND bash -c "${CMAKE_SOURCE_DIR}/patches/apply-patches"
  CONFIGURE_COMMAND cmake -DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME} ${TENTATIVE_WIN32_FLAGS}
                          -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} -DCMAKE_RC_COMPILER=${CMAKE_RC_COMPILER}
                          -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} "-DCMAKE_INSTALL_PREFIX=${EXTPREFIX}"
                          "-DLLVM_TARGETS_TO_BUILD=ARM$<SEMICOLON>X86$<SEMICOLON>AArch64"
                          -DLLVM_ENABLE_LIBCXX=YES
                          -DLLVM_ENABLE_TERMINFO=OFF
                           ../extllvm/
  INSTALL_COMMAND ""
  BUILD_COMMAND bash -c "make install/strip"
)

add_custom_target(robovm-llvm-dsym)
add_dependencies(robovm-llvm-dsym extllvm)

if (DEFINED INSTALL_DIR)
  # replace template with values
  string(REPLACE "_OS_" "${OS}" INSTALL_DIR ${INSTALL_DIR})
  string(REPLACE "_ARCH_" "${ARCH}" INSTALL_DIR ${INSTALL_DIR})
  message (STATUS "Custom install dir=${INSTALL_DIR}")

  add_custom_command(TARGET robovm-llvm-dsym POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy
                            ${EXTPREFIX}/bin/llvm-dsymutil${EXE_SUFFIX}
                            ${INSTALL_DIR})
endif(DEFINED INSTALL_DIR)

