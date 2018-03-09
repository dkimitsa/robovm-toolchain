cmake_minimum_required(VERSION 2.9)
include(ExternalProject)


project(robovm-xcode)

if (DEFINED INSTALL_DIR)
  message (STATUS "Custom install dir=${INSTALL_DIR}")
else(DEFINED INSTALL_DIR)
  set(INSTALL_DIR "${CMAKE_BINARY_DIR}/ext")
endif()

ExternalProject_Add(extiossdk
  URL https://github.com/dkimitsa/robovm-sdk-builder/releases/download/ios11.2.6/sdk-ios11.2.6.zip
  UPDATE_COMMAND mkdir -p "${INSTALL_DIR}"
  CONFIGURE_COMMAND echo unzip <DOWNLOADED_FILE>
  BUILD_COMMAND unzip <DOWNLOADED_FILE>
  INSTALL_COMMAND cp -f -R Xcode.app/. "${INSTALL_DIR}/"
  BUILD_IN_SOURCE 1
  DOWNLOAD_NO_EXTRACT 1
)

ExternalProject_Add(extswiftlibs
  DEPENDS extiossdk
  URL https://swift.org/builds/swift-4.0.3-release/xcode/swift-4.0.3-RELEASE/swift-4.0.3-RELEASE-osx.pkg
  UPDATE_COMMAND ""
  CONFIGURE_COMMAND ""
  BUILD_COMMAND echo "Unpacking pkg..."
        COMMAND ${CMAKE_SOURCE_DIR}/tools/unpkg.sh <DOWNLOADED_FILE>
        COMMAND echo "Applying version..."
	COMMAND javac ${CMAKE_SOURCE_DIR}/tools/ForceVersion.java
	COMMAND java -cp "${CMAKE_SOURCE_DIR}/tools" ForceVersion "usr/lib/swift/iphoneos/*.dylib" 4.0.3 1.0.0
  INSTALL_COMMAND echo "Copying to install location..."
          COMMAND mkdir -p "${INSTALL_DIR}/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphoneos/"
          COMMAND bash -c "cp usr/lib/swift/iphoneos/*.dylib ${INSTALL_DIR}/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphoneos/"
  BUILD_IN_SOURCE 1
  DOWNLOAD_NO_EXTRACT 1
)


add_custom_target(robovm-xcode)
add_dependencies(robovm-xcode extswiftlibs)


