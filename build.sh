#!/bin/bash
set -e

SELF=$(basename $0)
BASE=$(cd $(dirname $0); pwd -P)
SUPORTED_TARGETS=("macosx-x86_64" "linux-x86_64" "linux-x86" "windows-x86_64" "windows-x86")
DEFAULT_TARGETS=("linux-x86_64" "linux-x86" "windows-x86_64" "windows-x86")
SUPORTED_TOOLS=("llvm" "libmd" "ld64" "llvm-dsym" "xcbuild" "file" "xib2nib" "deps")


function usage {
  cat <<EOF
Usage: $SELF [options] [target1] [target2] ...
Supported targets: "${SUPORTED_TARGETS[*]}"
Supported tools: "${SUPORTED_TOOLS[*]}"
Options:
  --help                  Displays this information and exits.
  [target]                target to build
  [tool]                  tool to build
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
TOOLS=()

for arg in "$@"
do
  case $arg in
    '--help')
      usage 0
      ;;
    *)
      if arrayContainsElement "$arg" "${SUPORTED_TARGETS[@]}"; then
        TARGETS+=("$arg")
      elif arrayContainsElement "$arg" "${SUPORTED_TOOLS[@]}"; then
        TOOLS+=("$arg")
      else
        echo "Unrecognized option or syntax error in option '$arg'"
        usage 1
      fi
      ;;
  esac
done

if [ ${#TARGETS[@]} -eq 0 ]; then
  TARGETS=(${DEFAULT_TARGETS[*]})
fi
if [ ${#TOOLS[@]} -eq 0 ]; then
  TOOLS=(${SUPORTED_TOOLS[*]})
fi

# the template for subscripts to properly make destination install directory
# as defined in SUPORTED_TARGETS
INSTALL_DIR="${BASE}/bin/_OS_-_ARCH_/"
# pre-create bin directories
for T in ${TARGETS[@]}; do
    mkdir -p "${BASE}/bin/${T}"
done

echo "--------------"
echo "Building tools ${TOOLS[*]} for ${TARGETS[*]}"
echo "--------------"

# building tools one by one
if arrayContainsElement "llvm" "${TOOLS[@]}"; then
   echo "Building LLVM for ${TARGETS[*]}"
   llvm/build.sh --clean --postclean "--install=${INSTALL_DIR}" ${TARGETS[*]}
fi

if arrayContainsElement "libmd" "${TOOLS[@]}"; then
   echo "Building libmobiledev for ${TARGETS[*]}"
   libmd/build.sh --clean --postclean "--install=${INSTALL_DIR}" ${TARGETS[*]}
fi

if arrayContainsElement "ld64" "${TOOLS[@]}"; then
   echo "Building cctools/ld64 for ${TARGETS[*]}"
   ld64/build.sh --clean --postclean "--install=${INSTALL_DIR}" ${TARGETS[*]}
fi

if arrayContainsElement "llvm-dsym" "${TOOLS[@]}"; then
   echo "Building llvm-dsym for ${TARGETS[*]}"
   llvm-dsym/build.sh --clean --postclean "--install=${INSTALL_DIR}" ${TARGETS[*]}
fi

if arrayContainsElement "xcbuild" "${TOOLS[@]}"; then
   echo "Building xcbuild for ${TARGETS[*]}"
   xcbuild/build.sh --clean --postclean "--install=${INSTALL_DIR}" ${TARGETS[*]}
fi

if arrayContainsElement "file" "${TOOLS[@]}"; then
   echo "Building unix file for ${TARGETS[*]}"
   file/build.sh --clean --postclean "--install=${INSTALL_DIR}" ${TARGETS[*]}
fi

if arrayContainsElement "xib2nib" "${TOOLS[@]}"; then
   echo "Building xib2nib file for ${TARGETS[*]}"
   xib2nib/build.sh --clean --postclean "--install=${INSTALL_DIR}" ${TARGETS[*]}
fi

if arrayContainsElement "deps" "${TOOLS[@]}"; then
   if arrayContainsElement "windows-x86_64" "${TARGETS[@]}"; then
     echo "Copy dependencies windows-x86_64..."
     cp -f /usr/x86_64-w64-mingw32/bin/libwinpthread-1.dll "${BASE}/bin/windows-x86_64/"
     cp -f /usr/x86_64-w64-mingw32/bin/libgcc_s_seh-1.dll "${BASE}/bin/windows-x86_64/"
     cp -f /usr/x86_64-w64-mingw32/bin/libstdc++-6.dll "${BASE}/bin/windows-x86_64/"
   fi
   if arrayContainsElement "windows-x86" "${TARGETS[@]}"; then
     echo "Copy dependencies windows-x86..."
     cp -f /usr/i686-w64-mingw32/bin/libwinpthread-1.dll "${BASE}/bin/windows-x86/"
     cp -f /usr/i686-w64-mingw32/bin/libgcc_s_sjlj-1.dll "${BASE}/bin/windows-x86/"
     cp -f /usr/i686-w64-mingw32/bin/libstdc++-6.dll "${BASE}/bin/windows-x86/"
   fi
fi
