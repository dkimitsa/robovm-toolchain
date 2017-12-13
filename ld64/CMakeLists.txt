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

  # for libtapi target
  if (ARCH STREQUAL "x86")
    set(TENTATIVE_LIBTAPI_TARGET "TARGET=MINGW32")
  else()
    set(TENTATIVE_LIBTAPI_TARGET "TARGET=MINGW64")
  endif()

  # for ld
  set(TENTATIVE_CROSS_COMPILE_HOST "--host=${MINGW_VARIANT}")
elseif(LINUX)
  if (ARCH STREQUAL "x86")
    set(TENTATIVE_LIBTAPI_TARGET "TARGET=Linux32")
    set(TENTATIVE_CROSS_COMPILE_HOST "--build=i686-linux-gnu \"CFLAGS=-m32\" \"CXXFLAGS=-m32\" \"OBJCFLAGS=-m32\" \"LDFLAGS=-m32\"")
  endif()
endif()

project(robovm-ld64)

message (STATUS "OS=${OS}")
message (STATUS "ARCH=${ARCH}")

set(EXTPREFIX "${CMAKE_BINARY_DIR}/ext")

# allow to override repository for quiker checkouts on local builds
if(DEFINED ENV{ROBOVM_TAPI_GIT_PATH})
	set(TAPI_GIT_PATH "$ENV{ROBOVM_TAPI_GIT_PATH}")
	message (STATUS "Using custom tapi.git @ ${TAPI_GIT_PATH}")
else()
	set(TAPI_GIT_PATH  https://github.com/tpoechtrager/apple-libtapi.git)
endif()
ExternalProject_Add(exttapi
  GIT_REPOSITORY ${TAPI_GIT_PATH}
  GIT_TAG 1.30.0
  UPDATE_COMMAND ""
  CONFIGURE_COMMAND ""
  PATCH_COMMAND bash -c "${CMAKE_SOURCE_DIR}/patches-tapi/apply-patches"
  BUILD_COMMAND bash -c "INSTALLPREFIX=${EXTPREFIX} ${TENTATIVE_LIBTAPI_TARGET} ./build.sh"
  INSTALL_COMMAND bash -c "./install.sh"
  BUILD_IN_SOURCE 1
)


# allow to override repository for quiker checkouts on local builds
if(DEFINED ENV{ROBOVM_CCTOOLS_GIT_PATH})
	set(CCTOOLS_GIT_PATH "$ENV{ROBOVM_CCTOOLS_GIT_PATH}")
	message (STATUS "Using custom cctools.git @ ${CCTOOLS_GIT_PATH}")
else()
	set(CCTOOLS_GIT_PATH  https://github.com/dkimitsa/cctools-port.git)
endif()
ExternalProject_Add(extcctools
  DEPENDS exttapi
  GIT_REPOSITORY ${CCTOOLS_GIT_PATH}
  GIT_TAG mingw
  UPDATE_COMMAND ""
  PATCH_COMMAND bash -c "${CMAKE_SOURCE_DIR}/patches-cctool/apply-patches"
  CONFIGURE_COMMAND bash -c "cd cctools && ./configure --prefix=${EXTPREFIX} --with-libtapi=${EXTPREFIX} ${TENTATIVE_CROSS_COMPILE_HOST} --target=i386-apple-darwin11 --target=x86_64-apple-darwin11 --target=arm-apple-darwin11 "
  BUILD_COMMAND bash -c "cd cctools &&  make"
  INSTALL_COMMAND bash -c "cd cctools &&  make install"
  BUILD_IN_SOURCE 1
)

add_custom_target(robovm-ld64)
add_dependencies(robovm-ld64 extcctools)

if (DEFINED INSTALL_DIR)
  # replace template with values
  string(REPLACE "_OS_" "${OS}" INSTALL_DIR ${INSTALL_DIR})
  string(REPLACE "_ARCH_" "${ARCH}" INSTALL_DIR ${INSTALL_DIR})
  message (STATUS "Custom install dir=${INSTALL_DIR}")

if (WINDOWS)
  add_custom_command(TARGET robovm-ld64 POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy
                            ${EXTPREFIX}/bin/tapi${DLIB_SUFFIX}
                            ${INSTALL_DIR})
else(WINDOWS)
  add_custom_command(TARGET robovm-ld64 POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy
                            ${EXTPREFIX}/lib/libtapi${DLIB_SUFFIX}
                            ${INSTALL_DIR})
endif()
  add_custom_command(TARGET robovm-ld64 POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy
                            ${EXTPREFIX}/bin/arm-apple-darwin11-ld${EXE_SUFFIX}
                            ${INSTALL_DIR})
  add_custom_command(TARGET robovm-ld64 POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy
                            ${EXTPREFIX}/bin/arm-apple-darwin11-nm${EXE_SUFFIX}
                            ${INSTALL_DIR})
  add_custom_command(TARGET robovm-ld64 POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy
                            ${EXTPREFIX}/bin/arm-apple-darwin11-lipo${EXE_SUFFIX}
                            ${INSTALL_DIR})
  add_custom_command(TARGET robovm-ld64 POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy
                            ${EXTPREFIX}/bin/arm-apple-darwin11-strip${EXE_SUFFIX}
                            ${INSTALL_DIR})
  add_custom_command(TARGET robovm-ld64 POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy
                            ${EXTPREFIX}/bin/arm-apple-darwin11-otool${EXE_SUFFIX}
                            ${INSTALL_DIR})
  add_custom_command(TARGET robovm-ld64 POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy
                            ${EXTPREFIX}/bin/arm-apple-darwin11-codesign_allocate${EXE_SUFFIX}
                            ${INSTALL_DIR})
endif(DEFINED INSTALL_DIR)
