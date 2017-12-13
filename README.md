# RoboVM ToolChain

This repo contains builds scripts used to compile/crosscompile toolchain utilities used to enable RoboVM compilation on Windows/Linux
RoboVM branch for Windows/Linux is [here](https://github.com/dkimitsa/robovm/tree/linuxwindows)

## Build
To build there is build.sh script that will build all tools for all platrforms available.
See options (run ./build --helps) to limit/customize build
After binaries are built they can be packed into archives with ./seal.sh

## Host system
Toolchain was successfuly compiled in ArchLinux 2017.11.01
Tools were used: GCC 7.2.0, mingw 7.2.0

## License
Scripts itself are GPL2 but binaries that are produced are covered by corresponding Project's license
