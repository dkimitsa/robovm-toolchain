#!/bin/bash

SELF=$(basename $0)
BASE=$(cd $(dirname $0); pwd -P)
SUPORTED_TARGETS=("macosx-x86_64" "linux-x86_64" "linux-x86" "windows-x86_64" "windows-x86")
# targets that already has file implementation
OMIT_TARGETS=("macosx-x86_64" "linux-x86_64" "linux-x86")
CLEAN=0
POSTCLEAN=0
WORKERS=1
SUFFIX=unix-file
CMAKE_INSTALL_DIR=

function usage {
  cat <<EOF
Usage: $SELF [options] [target1] [target2] ...
Supported targets: "${SUPORTED_TARGETS[*]}"
Options:
  --clean                 Cleans the build dir before starting the build.
  --help                  Displays this information and exits.
  --postclean             Cleans the build dir after performing the build
  --install=/<OS>/<ARCH>  Sets custom intstall path, <OS> and <ARCH> will be replaced with proper values
  [target]                target to build
EOF
  exit $1
}

function arrayContainsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

TARGETS=()
SKIPPED_TARGETS=()

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
      if arrayContainsElement "$arg" "${SUPORTED_TARGETS[@]}"; then
        if arrayContainsElement "$arg" "${OMIT_TARGETS[@]}"; then
           echo "Skipping $arg"
           SKIPPED_TARGETS+=("$arg")
        else
           TARGETS+=("$arg")
        fi
      else
        echo "Unrecognized option or syntax error in option '$arg'"
        usage 1
      fi
      ;;
  esac
done

if [ ${#TARGETS[@]} -eq 0 ]; then
  if [ ${#SKIPPED_TARGETS[@]} -ne 0 ]; then
    exit 0
  fi
  echo "No target specified !"
  usage 1
fi

mkdir -p "$BASE/target.${SUFFIX}/build"

for T in ${TARGETS[@]}; do
  OS=${T%%-*}
  ARCH=${T#*-}
  BUILD_TYPE=Release
  MAKE=make
  case "$T" in
   "windows-x86_64")
    CMAKE_PARAMS="-DMINGW_VARIANT=x86_64-w64-mingw32"
    ;;
   "windows-x86")
    CMAKE_PARAMS="-DMINGW_VARIANT=i686-w64-mingw32"
    ;;
  esac

  echo "Building target $T with params: $CMAKE_PARAMS $CMAKE_INSTALL_DIR"
  # clean before build
  if [ "$CLEAN" = '1' ]; then
    rm -rf "$BASE/target.${SUFFIX}/build/$T"
  fi
  mkdir -p "$BASE/target.${SUFFIX}/build/$T"
  if [ -z "$CMAKE_INSTALL_DIR" ]; then
    # there is no override in install location, so just
    rm -rf "$BASE/binaries/$OS/$ARCH"
  fi
  bash -c "cd '$BASE/target.${SUFFIX}/build/$T'; cmake -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DOS=$OS -DARCH=$ARCH $CMAKE_PARAMS $CMAKE_INSTALL_DIR '$BASE'; $MAKE robovm-unix-file"
  R=$?
  if [[ $R != 0 ]]; then
    echo "$T build failed"
    exit $R
  fi
  # clean after build
  if [ "$POSTCLEAN" = '1' ]; then
    rm -rf "$BASE/target.${SUFFIX}/build/$T"
  fi
done

