# FindCsoundHomeFirst.cmake
#
# Home-first Csound discovery.
#
# Search order on macOS (framework / headers):
#   1. $HOME/Library/Frameworks   (optional local build)
#   2. $HOME
#   3. /Library/Frameworks        (standard installer)
#   4. /Applications/Csound       (standard installer)
#   5. /usr/local
#   6. /opt/homebrew
#
# Executable search on macOS prefers a CLI in $HOME/bin, /usr/local/bin, or
# /opt/homebrew/bin, then falls back to /Applications/Csound/csound from the
# installer. That installer frontend is a valid CSOUND_EXECUTABLE, but must
# not be invoked as `csound --version` during configure (it can hang forever
# when CMake captures stdin/stdout). Version comes from the framework
# version.h instead.
#
# Search order on Windows:
#   1. CSOUND_ROOT_HINT (if set)
#   2. %USERPROFILE% or %HOME%
#   3. C:/Program Files/Csound
#   4. C:/Program Files (x86)/Csound
#
# Search order on Linux and other Unix:
#   1. CSOUND_ROOT_HINT (if set)
#   2. $HOME
#   3. /usr/local
#   4. /opt/homebrew
#   5. /usr
#
# Sets:
#   CSOUND_FOUND
#   CSOUND_EXECUTABLE
#   CSOUND_LIBRARY
#   CSOUND_LIBRARIES
#   CSOUND_INCLUDE_DIR
#   CSOUND_INCLUDE_DIRS
#   CSOUND_FRAMEWORK_DIR
#   CSOUND_VERSION
#   CSOUND_VERSION_MAJOR
#   CSOUND_VERSION_MINOR
#
# Optional inputs:
#   CSOUND_ROOT_HINT
#   FIND_CSOUND_HOME_FIRST_REQUIRED

include_guard(GLOBAL)

if(NOT DEFINED FIND_CSOUND_HOME_FIRST_REQUIRED)
    set(FIND_CSOUND_HOME_FIRST_REQUIRED ON)
endif()

set(_csound_home "$ENV{HOME}")
if(WIN32 AND (NOT _csound_home OR _csound_home STREQUAL ""))
    if(DEFINED ENV{USERPROFILE} AND NOT "$ENV{USERPROFILE}" STREQUAL "")
        set(_csound_home "$ENV{USERPROFILE}")
    endif()
endif()

set(_csound_search_roots)
if(DEFINED CSOUND_ROOT_HINT AND NOT CSOUND_ROOT_HINT STREQUAL "")
    list(APPEND _csound_search_roots "${CSOUND_ROOT_HINT}")
endif()

if(APPLE)
    list(APPEND _csound_search_roots
        "${_csound_home}/Library/Frameworks"
        "${_csound_home}"
        "/Library/Frameworks"
        "/Applications/Csound"
        "/usr/local"
        "/opt/homebrew"
    )
elseif(WIN32)
    list(APPEND _csound_search_roots
        "${_csound_home}"
        "C:/Program Files/Csound"
        "C:/Program Files (x86)/Csound"
    )
else()
    list(APPEND _csound_search_roots
        "${_csound_home}"
        "/usr/local"
        "/opt/homebrew"
        "/usr"
    )
endif()

list(REMOVE_DUPLICATES _csound_search_roots)

# Help ordinary CMake searches prefer home first.
if(APPLE)
    list(PREPEND CMAKE_FRAMEWORK_PATH
        "${_csound_home}/Library/Frameworks"
        "/Library/Frameworks"
        "/Applications/Csound"
    )
endif()

if(WIN32)
    list(PREPEND CMAKE_PREFIX_PATH "${_csound_home}")
else()
    list(PREPEND CMAKE_PREFIX_PATH
        "${_csound_home}"
        "/usr/local"
        "/opt/homebrew"
    )
endif()

# ------------------------------------------------------------------------------
# Executable
# ------------------------------------------------------------------------------
# Do not pass $HOME or /Applications/Csound as a generic PATHS root with
# PATH_SUFFIXES bin: CMake also searches the root itself, so it can pick
# /Applications/Csound/csound before /usr/local/bin/csound.

set(_csound_exe_paths)
if(DEFINED CSOUND_ROOT_HINT AND NOT CSOUND_ROOT_HINT STREQUAL "")
    list(APPEND _csound_exe_paths
        "${CSOUND_ROOT_HINT}/bin"
        "${CSOUND_ROOT_HINT}"
    )
endif()
if(APPLE)
    list(APPEND _csound_exe_paths
        "${_csound_home}/bin"
        "/usr/local/bin"
        "/opt/homebrew/bin"
        "/Applications/Csound"
    )
elseif(WIN32)
    list(APPEND _csound_exe_paths
        "${_csound_home}/bin"
        "C:/Program Files/Csound/bin"
        "C:/Program Files (x86)/Csound/bin"
    )
else()
    list(APPEND _csound_exe_paths
        "${_csound_home}/bin"
        "/usr/local/bin"
        "/opt/homebrew/bin"
        "/usr/bin"
    )
endif()
list(REMOVE_DUPLICATES _csound_exe_paths)

find_program(CSOUND_EXECUTABLE
    NAMES csound csound64
    PATHS ${_csound_exe_paths}
    NO_DEFAULT_PATH
)

if(NOT CSOUND_EXECUTABLE)
    find_program(CSOUND_EXECUTABLE NAMES csound csound64)
endif()

# ------------------------------------------------------------------------------
# Library / framework / include directories
# ------------------------------------------------------------------------------

unset(CSOUND_LIBRARY CACHE)
unset(CSOUND_INCLUDE_DIR CACHE)
unset(CSOUND_FRAMEWORK_DIR CACHE)

if(APPLE)
    foreach(_root IN LISTS _csound_search_roots)
        if(EXISTS "${_root}/CsoundLib64.framework/CsoundLib64")
            set(CSOUND_LIBRARY "${_root}/CsoundLib64.framework/CsoundLib64")
            set(CSOUND_INCLUDE_DIR "${_root}/CsoundLib64.framework/Headers")
            set(CSOUND_FRAMEWORK_DIR "${_root}/CsoundLib64.framework")
            break()
        endif()

        if(EXISTS "${_root}/CsoundLib64.framework/Versions/Current/CsoundLib64")
            set(CSOUND_LIBRARY "${_root}/CsoundLib64.framework/Versions/Current/CsoundLib64")
            set(CSOUND_INCLUDE_DIR "${_root}/CsoundLib64.framework/Headers")
            set(CSOUND_FRAMEWORK_DIR "${_root}/CsoundLib64.framework")
            break()
        endif()

        if(EXISTS "${_root}/CsoundLib64.framework/Versions/7.0/CsoundLib64")
            set(CSOUND_LIBRARY "${_root}/CsoundLib64.framework/Versions/7.0/CsoundLib64")
            set(CSOUND_INCLUDE_DIR "${_root}/CsoundLib64.framework/Headers")
            set(CSOUND_FRAMEWORK_DIR "${_root}/CsoundLib64.framework")
            break()
        endif()

        if(EXISTS "${_root}/CsoundLib64.framework/Versions/6.0/CsoundLib64")
            set(CSOUND_LIBRARY "${_root}/CsoundLib64.framework/Versions/6.0/CsoundLib64")
            set(CSOUND_INCLUDE_DIR "${_root}/CsoundLib64.framework/Headers")
            set(CSOUND_FRAMEWORK_DIR "${_root}/CsoundLib64.framework")
            break()
        endif()
    endforeach()
endif()

if(NOT CSOUND_LIBRARY)
    set(_csound_library_names CsoundLib64 csound64 csound64-6.0)
    if(WIN32)
        list(APPEND _csound_library_names csound csound64.lib)
    endif()
    find_library(CSOUND_LIBRARY
        NAMES ${_csound_library_names}
        PATHS ${_csound_search_roots}
        PATH_SUFFIXES lib lib64
        NO_DEFAULT_PATH
    )
endif()

if(NOT CSOUND_INCLUDE_DIR)
    find_path(CSOUND_INCLUDE_DIR
        NAMES csound.h csound/csound.h
        PATHS ${_csound_search_roots}
        PATH_SUFFIXES include include/csound
        NO_DEFAULT_PATH
    )
endif()

if(NOT CSOUND_LIBRARY)
    set(_csound_library_names_fallback CsoundLib64 csound64 csound64-6.0)
    if(WIN32)
        list(APPEND _csound_library_names_fallback csound)
    endif()
    find_library(CSOUND_LIBRARY NAMES ${_csound_library_names_fallback})
endif()

if(NOT CSOUND_INCLUDE_DIR)
    find_path(CSOUND_INCLUDE_DIR NAMES csound.h csound/csound.h)
endif()

set(CSOUND_LIBRARIES "${CSOUND_LIBRARY}")
set(CSOUND_INCLUDE_DIRS "${CSOUND_INCLUDE_DIR}")

# ------------------------------------------------------------------------------
# Version (for -DCSOUND_VERSION_MAJOR=... compile definitions)
# ------------------------------------------------------------------------------

if(NOT CSOUND_VERSION_MAJOR)
    get_property(_csound_cached_major_set CACHE CSOUND_VERSION_MAJOR PROPERTY VALUE SET)
    if(_csound_cached_major_set)
        get_property(CSOUND_VERSION_MAJOR CACHE CSOUND_VERSION_MAJOR PROPERTY VALUE)
        get_property(_csound_cached_minor_set CACHE CSOUND_VERSION_MINOR PROPERTY VALUE SET)
        if(_csound_cached_minor_set)
            get_property(CSOUND_VERSION_MINOR CACHE CSOUND_VERSION_MINOR PROPERTY VALUE)
        endif()
        if(CSOUND_VERSION_MAJOR)
            set(CSOUND_VERSION "${CSOUND_VERSION_MAJOR}.${CSOUND_VERSION_MINOR}")
        endif()
    endif()
endif()

if(CSOUND_LIBRARY AND NOT CSOUND_VERSION_MAJOR)
    if(CSOUND_LIBRARY MATCHES "/Versions/([0-9]+)\\.([0-9]+)/")
        set(CSOUND_VERSION_MAJOR "${CMAKE_MATCH_1}")
        set(CSOUND_VERSION_MINOR "${CMAKE_MATCH_2}")
        set(CSOUND_VERSION "${CMAKE_MATCH_1}.${CMAKE_MATCH_2}")
    endif()
endif()

if(CSOUND_INCLUDE_DIR AND NOT CSOUND_VERSION_MAJOR)
    set(_csound_version_h "")
    foreach(_csound_version_candidate IN ITEMS
        "${CSOUND_INCLUDE_DIR}/version.h"
        "${CSOUND_INCLUDE_DIR}/csound/version.h"
    )
        if(EXISTS "${_csound_version_candidate}")
            set(_csound_version_h "${_csound_version_candidate}")
            break()
        endif()
    endforeach()

    if(_csound_version_h)
        file(READ "${_csound_version_h}" _csound_version_h_text)
        string(REGEX MATCH "#define[ \t]+CS_VERSION[ \t]+\\(([0-9]+)\\)" _cs_ver_match "${_csound_version_h_text}")
        if(_cs_ver_match)
            set(CSOUND_VERSION_MAJOR "${CMAKE_MATCH_1}")
        endif()
        string(REGEX MATCH "#define[ \t]+CS_SUBVER[ \t]+\\(([0-9]+)\\)" _cs_sub_match "${_csound_version_h_text}")
        if(_cs_sub_match)
            set(CSOUND_VERSION_MINOR "${CMAKE_MATCH_1}")
        endif()
        if(CSOUND_VERSION_MAJOR)
            set(CSOUND_VERSION "${CSOUND_VERSION_MAJOR}.${CSOUND_VERSION_MINOR}")
        endif()
    endif()
endif()

# Last resort only, and never the macOS installer frontend: that binary can
# hang forever on --version when CMake pipes stdin/stdout.
if(CSOUND_EXECUTABLE AND NOT CSOUND_VERSION_MAJOR
        AND NOT CSOUND_EXECUTABLE MATCHES "/Applications/Csound/")
    if(WIN32)
        set(_csound_devnull "NUL")
    else()
        set(_csound_devnull "/dev/null")
    endif()
    execute_process(
        COMMAND "${CSOUND_EXECUTABLE}" --version
        INPUT_FILE "${_csound_devnull}"
        OUTPUT_VARIABLE _csound_version_stdout
        ERROR_VARIABLE _csound_version_stderr
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_STRIP_TRAILING_WHITESPACE
        TIMEOUT 8
        RESULT_VARIABLE _csound_version_result
    )

    set(_csound_version_text "${_csound_version_stdout}\n${_csound_version_stderr}")

    string(REGEX MATCH "Csound version[ ]+([0-9]+)\\.([0-9]+)" _csound_version_match "${_csound_version_text}")

    if(_csound_version_match)
        set(CSOUND_VERSION "${CMAKE_MATCH_1}.${CMAKE_MATCH_2}")
        set(CSOUND_VERSION_MAJOR "${CMAKE_MATCH_1}")
        set(CSOUND_VERSION_MINOR "${CMAKE_MATCH_2}")
    endif()
endif()

if(CSOUND_VERSION_MAJOR AND NOT CSOUND_VERSION)
    if(NOT DEFINED CSOUND_VERSION_MINOR OR CSOUND_VERSION_MINOR STREQUAL "")
        set(CSOUND_VERSION_MINOR "0")
    endif()
    set(CSOUND_VERSION "${CSOUND_VERSION_MAJOR}.${CSOUND_VERSION_MINOR}")
endif()

# ------------------------------------------------------------------------------
# Result
# ------------------------------------------------------------------------------

if(CSOUND_LIBRARY AND CSOUND_INCLUDE_DIR)
    set(CSOUND_FOUND TRUE)
else()
    set(CSOUND_FOUND FALSE)
endif()

# Cache for visibility in CMakeCache.txt
set(CSOUND_FOUND "${CSOUND_FOUND}" CACHE BOOL "Whether Csound was found" FORCE)
set(CSOUND_EXECUTABLE "${CSOUND_EXECUTABLE}" CACHE FILEPATH "Csound executable" FORCE)
set(CSOUND_LIBRARY "${CSOUND_LIBRARY}" CACHE FILEPATH "Csound library/framework binary" FORCE)
set(CSOUND_LIBRARIES "${CSOUND_LIBRARIES}" CACHE STRING "Csound libraries" FORCE)
set(CSOUND_INCLUDE_DIR "${CSOUND_INCLUDE_DIR}" CACHE PATH "Csound include directory" FORCE)
set(CSOUND_INCLUDE_DIRS "${CSOUND_INCLUDE_DIRS}" CACHE STRING "Csound include directories" FORCE)
set(CSOUND_FRAMEWORK_DIR "${CSOUND_FRAMEWORK_DIR}" CACHE PATH "Csound framework directory" FORCE)
if(CSOUND_VERSION)
    set(CSOUND_VERSION "${CSOUND_VERSION}" CACHE STRING "Csound version" FORCE)
endif()
if(CSOUND_VERSION_MAJOR)
    set(CSOUND_VERSION_MAJOR "${CSOUND_VERSION_MAJOR}" CACHE STRING "Csound major version" FORCE)
endif()
if(CSOUND_VERSION_MINOR)
    set(CSOUND_VERSION_MINOR "${CSOUND_VERSION_MINOR}" CACHE STRING "Csound minor version" FORCE)
endif()

message(STATUS "==== Csound home-first detection ====")
message(STATUS "CSOUND_FOUND:         ${CSOUND_FOUND}")
message(STATUS "CSOUND_EXECUTABLE:    ${CSOUND_EXECUTABLE}")
message(STATUS "CSOUND_LIBRARY:       ${CSOUND_LIBRARY}")
message(STATUS "CSOUND_INCLUDE_DIRS:  ${CSOUND_INCLUDE_DIRS}")
message(STATUS "CSOUND_FRAMEWORK_DIR: ${CSOUND_FRAMEWORK_DIR}")
message(STATUS "CSOUND_VERSION:       ${CSOUND_VERSION}")
message(STATUS "CSOUND_VERSION_MAJOR: ${CSOUND_VERSION_MAJOR}")
message(STATUS "CSOUND_VERSION_MINOR: ${CSOUND_VERSION_MINOR}")
message(STATUS "=====================================")

if(FIND_CSOUND_HOME_FIRST_REQUIRED AND NOT CSOUND_FOUND)
    message(FATAL_ERROR "Csound was not found.")
endif()