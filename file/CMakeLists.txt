cmake_minimum_required(VERSION 2.8)
include(ExternalProject)

# Parameters to be specified from command line 
# OS name
# INSTALL_DIR if required to override 

if(NOT DEFINED OS)
  message(FATAL_ERROR "Please specify an os (macosx, linux, windows), e.g. -DOS=linux")
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

if(WINDOWS)
  if(NOT DEFINED MINGW_VARIANT)
    message(FATAL_ERROR "Please setup MINGW_VARIANT, e.g. -DMINGW_VARIANT=x86_64-w64-mingw32 variable")
  endif()
  set(TENTATIVE_CROSS_COMPILE_HOST "--host=${MINGW_VARIANT}")
endif()

project(robovm-unix-file)

message (STATUS "OS=${OS}")
message (STATUS "ARCH=${ARCH}")

set(EXTPREFIX "${CMAKE_BINARY_DIR}/ext")

ExternalProject_Add(pcre2ext
  URL https://ftp.pcre.org/pub/pcre/pcre2-10.30.zip
  CONFIGURE_COMMAND bash -c "./configure ${TENTATIVE_CROSS_COMPILE_HOST} --prefix=${EXTPREFIX} --enable-shared=no"
  BUILD_IN_SOURCE 1
)

ExternalProject_Add(extfile
  URL https://github.com/file/file/archive/FILE5_32.tar.gz
  PATCH_COMMAND bash -c "${CMAKE_SOURCE_DIR}/patches/apply-patches"
  CONFIGURE_COMMAND bash -c "autoreconf --install && ./configure LDFLAGS=\"-static -L${EXTPREFIX}/lib\" CFLAGS=\"-DPCRE2_STATIC -I${EXTPREFIX}/include\" --host=${MINGW_VARIANT} --prefix=${EXTPREFIX}"
  BUILD_IN_SOURCE 1
  DEPENDS pcre2ext
)

add_custom_target(robovm-unix-file)
add_dependencies(robovm-unix-file extfile)

if (DEFINED INSTALL_DIR)
  # replace template with values
  string(REPLACE "_OS_" "${OS}" INSTALL_DIR ${INSTALL_DIR})
  string(REPLACE "_ARCH_" "${ARCH}" INSTALL_DIR ${INSTALL_DIR})
  message (STATUS "Custom install dir=${INSTALL_DIR}")

  add_custom_command(TARGET robovm-unix-file POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy
                            ${EXTPREFIX}/bin/file${EXE_SUFFIX}
                            ${INSTALL_DIR})
  add_custom_command(TARGET robovm-unix-file POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy
                            ${EXTPREFIX}/share/misc/magic.mgc
                            ${INSTALL_DIR})
endif(DEFINED INSTALL_DIR)

