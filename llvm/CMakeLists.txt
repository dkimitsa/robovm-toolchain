cmake_minimum_required(VERSION 2.9)
include(ExternalProject)

project(robovm-llvm)

if(DEFINED OS)
  set(OS_PARAM "-DOS=${OS}")
endif()

if(DEFINED ARCH)
  set(ARCH_PARAM "-DARCH=${ARCH}")
endif()

if(DEFINED MINGW_VARIANT)
  set(MINGW_PARAM "-DMINGW_VARIANT=${MINGW_VARIANT}")
endif()

if(DEFINED INSTALL_DIR)
  set(INSTDIR_PARAM "-DINSTALL_DIR=${INSTALL_DIR}")
endif()

ExternalProject_Add(extllvm
  SVN_REPOSITORY https://github.com/dkimitsa/robovm/branches/linuxwindows/compiler/llvm
  UPDATE_COMMAND ""
  CONFIGURE_COMMAND cmake ${OS_PARAM} ${ARCH_PARAM} ${MINGW_PARAM} ${INSTDIR_PARAM}
  BUILD_IN_SOURCE 1
)

add_custom_target(robovm-llvm)
add_dependencies(robovm-llvm extllvm)
