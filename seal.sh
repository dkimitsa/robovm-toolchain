#!/bin/bash
set -e

SELF=$(basename $0)
BASE=$(cd $(dirname $0); pwd -P)
SUPORTED_TARGETS=("macosxlinux-x86_64" "linux-x86_64" "linux-x86" "windows-x86_64" "windows-x86")
DEFAULT_TARGETS=("linux-x86_64" "linux-x86" "windows-x86_64" "windows-x86")
ZIP_TARGETS=("windows-x86_64" "windows-x86")

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

version=`cat ${BASE}/version`

for T in ${TARGETS[@]}; do
    if [ ! -d "${BASE}/bin/${T}" ]; then
       echo "No bin directory for target ${T}"
       exit 1
    fi

    # remove old manifest
    rm -f "${BASE}/bin/${T}/manifest"
    # get file list

    # add version
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

    #pack
    if arrayContainsElement "$T" "${ZIP_TARGETS[@]}"; then
        cd "${BASE}/bin/"
        zip -r "${BASE}/$T-${version}.zip" "${T}/"
        cd -
    else
        tar -czf "${BASE}/$T-${version}.tar.gz" -C "${BASE}/bin/" "${T}"
    fi

done
