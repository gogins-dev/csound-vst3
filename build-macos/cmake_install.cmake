# Install script for directory: /Users/michaelgogins/csound-vst3/CsoundVST3

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/Users/michaelgogins/csound-vst3/dist")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "RelWithDebInfo")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set path to fallback-tool for dependency-resolution.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/usr/bin/objdump")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/michaelgogins/csound-vst3/build-macos/JUCE/cmake_install.cmake")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/michaelgogins/csound-vst3/build-macos/CsoundVST3_artefacts/RelWithDebInfo/libCsoundVST3_SharedCode.a")
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libCsoundVST3_SharedCode.a" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libCsoundVST3_SharedCode.a")
    execute_process(COMMAND "/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libCsoundVST3_SharedCode.a")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/Library/Audio/Plug-Ins/VST3" TYPE DIRECTORY FILES "/Users/michaelgogins/csound-vst3/build-macos/CsoundVST3_artefacts/RelWithDebInfo/VST3/CsoundVST3.vst3" USE_SOURCE_PERMISSIONS)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/Library/Audio/Plug-Ins/Components" TYPE DIRECTORY FILES "/Users/michaelgogins/csound-vst3/build-macos/CsoundVST3_artefacts/RelWithDebInfo/AU/CsoundVST3.component" USE_SOURCE_PERMISSIONS)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "CsoundVST3_Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/Applications" TYPE DIRECTORY FILES "/Users/michaelgogins/csound-vst3/build-macos/CsoundVST3_artefacts/RelWithDebInfo/Standalone/CsoundVST3.app" USE_SOURCE_PERMISSIONS)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "CsoundVST3_Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/Applications/CsoundVST3.app/Contents/Frameworks" TYPE DIRECTORY FILES "/Users/michaelgogins/Library/Frameworks/CsoundLib64.framework" USE_SOURCE_PERMISSIONS)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "CsoundVST3_Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/Library/Audio/Plug-Ins/VST3/CsoundVST3.vst3/Contents/Frameworks" TYPE DIRECTORY FILES "/Users/michaelgogins/Library/Frameworks/CsoundLib64.framework" USE_SOURCE_PERMISSIONS)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "CsoundVST3_Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/Library/Audio/Plug-Ins/Components/CsoundVST3.component/Contents/Frameworks" TYPE DIRECTORY FILES "/Users/michaelgogins/Library/Frameworks/CsoundLib64.framework" USE_SOURCE_PERMISSIONS)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "CsoundVST3_Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/." TYPE FILE OPTIONAL FILES "/Users/michaelgogins/csound-vst3/CsoundVST3/../README.md")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "CsoundVST3_Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/." TYPE DIRECTORY FILES "/Users/michaelgogins/csound-vst3/CsoundVST3/Resources")
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/Users/michaelgogins/csound-vst3/build-macos/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
if(CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_COMPONENT MATCHES "^[a-zA-Z0-9_.+-]+$")
    set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
  else()
    string(MD5 CMAKE_INST_COMP_HASH "${CMAKE_INSTALL_COMPONENT}")
    set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INST_COMP_HASH}.txt")
    unset(CMAKE_INST_COMP_HASH)
  endif()
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/Users/michaelgogins/csound-vst3/build-macos/${CMAKE_INSTALL_MANIFEST}"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
