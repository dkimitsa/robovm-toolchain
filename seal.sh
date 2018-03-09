#!/bin/bash
set -e

SELF=$(basename $0)
BASE=$(cd $(dirname $0); pwd -P)
SUPORTED_TARGETS=("darwinlinux-x86_64" "linux-x86_64" "linux-x86" "windows-x86_64" "windows-x86" "Xcode.app")
DEFAULT_TARGETS=("linux-x86_64" "linux-x86" "windows-x86_64" "windows-x86")
ZIP_TARGETS=("windows-x86_64" "windows-x86" "Xcode.app")

function usage {
  cat <<EOF
Seals binaries to archieve
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

for arg in "$@"
do
  case $arg in
    '--help')
      usage 0
      ;;
    *)
      if arrayContainsElement "$arg" "${SUPORTED_TARGETS[@]}"; then
        TARGETS+=("$arg")
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

version_toolchain=`cat ${BASE}/version.toolchain`
version_xcode=`cat ${BASE}/version.xcode`

for T in ${TARGETS[@]}; do
    if [ $T == "darwinlinux-x86_64" ]; then
        # make a copy from macosx-x86_64
        rm -rf ${BASE}/bin/${T}
        cp -R ${BASE}/bin/macosx-x86_64 ${BASE}/bin/${T}
    fi

    if [ ! -d "${BASE}/bin/${T}" ]; then
       echo "No bin directory for target ${T}"
       exit 1
    fi

    # remove old manifest
    rm -f "${BASE}/bin/${T}/manifest"
    # get file list

    if [ $T == "Xcode.app" ]; then
        # Xcode case -- no need to seal tonns of file there
        # add version
        version=$version_xcode
        echo "@version=$version" > "${BASE}/bin/${T}/manifest"
    else
        # add version
        version=$version_toolchain
        echo "@version=$version" > "${BASE}/bin/${T}/manifest"

        # seal all files
        for f in ${BASE}/bin/${T}/*; do
            name=`basename $f`
            if [[ "$name" == "manifest" ]]; then
               continue
            fi
            if [ -x "$(command -v md5sum)" ]; then
                md5sum=($(md5sum $f))
            else
                md5sum=`md5 -q $f`
            fi
            echo "$name=$md5sum" >> "${BASE}/bin/${T}/manifest"
        done
    fi

    #pack
    if arrayContainsElement "$T" "${ZIP_TARGETS[@]}"; then
        cd "${BASE}/bin/"
        zip -r "${BASE}/$T-${version}.zip" "${T}/"
        cd -
    else
        tar -czf "${BASE}/$T-${version}.tar.gz" -C "${BASE}/bin/" "${T}"
    fi

done
