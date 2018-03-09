#!/bin/bash

SELF=$(basename $0)
BASE=$(cd $(dirname $0); pwd -P)
CLEAN=0
POSTCLEAN=0
WORKERS=1
SUFFIX=xcode-files
CMAKE_INSTALL_DIR=

function usage {
  cat <<EOF
Usage: $SELF [options] [target1] [target2] ...
Options:
  --clean                 Cleans the build dir before starting the build.
  --help                  Displays this information and exits.
  --postclean             Cleans the build dir after performing the build
  --install=              Sets custom intstall path and _ARCH_ will be replaced with proper values
EOF
  exit $1
}


for arg in "$@"
do
  case $arg in
    '--clean') CLEAN=1 ;;
    '--postclean') POSTCLEAN=1 ;;
    '--install='* )
      CMAKE_INSTALL_DIR="-DINSTALL_DIR=${arg#*=}"
      ;;
    '--help')
      usage 0
      ;;
    *)
      echo "Unrecognized option or syntax error in option '$arg'"
      usage 1
      ;;
  esac
done

mkdir -p "$BASE/target.${SUFFIX}/build"
MAKE=make

echo "Building Xcode files (iOS SDK with swift libraries) with params: $CMAKE_INSTALL_DIR"
# clean before build
if [ "$CLEAN" = '1' ]; then
  rm -rf "$BASE/target.${SUFFIX}/build/"
fi

mkdir -p "$BASE/target.${SUFFIX}/build/"
if [ -z "$CMAKE_INSTALL_DIR" ]; then
  # there is no override in install location, so just
  rm -rf "$BASE/binaries/Xcode.app"
fi

bash -c "cd '$BASE/target.${SUFFIX}/build/'; cmake $CMAKE_INSTALL_DIR '$BASE'; $MAKE robovm-xcode"
R=$?

if [[ $R != 0 ]]; then
  echo "$T build failed"
  exit $R
fi

# clean after build
if [ "$POSTCLEAN" = '1' ]; then
  rm -rf "$BASE/target.${SUFFIX}/build/"
fi

