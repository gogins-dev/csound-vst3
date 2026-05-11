# FindCsoundHomeFirst.cmake
#
# Home-first Csound discovery.
#
# Search order on macOS:
#   1. $HOME/Library/Frameworks
#   2. $HOME
#   3. /Library/Frameworks
#   4. /Applications/Csound
#   5. /usr/local
#   6. /opt/homebrew
#
# Search order elsewhere:
#   1. $HOME
#   2. /usr/local
#   3. /opt/homebrew
#   4. /usr
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

list(PREPEND CMAKE_PREFIX_PATH
    "${_csound_home}"
    "/usr/local"
    "/opt/homebrew"
)

# ------------------------------------------------------------------------------
# Executable
# ------------------------------------------------------------------------------

find_program(CSOUND_EXECUTABLE
    NAMES csound csound64
    PATHS ${_csound_search_roots}
    PATH_SUFFIXES bin
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
    find_library(CSOUND_LIBRARY
        NAMES CsoundLib64 csound64 csound64-6.0
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
    find_library(CSOUND_LIBRARY NAMES CsoundLib64 csound64 csound64-6.0)
endif()

if(NOT CSOUND_INCLUDE_DIR)
    find_path(CSOUND_INCLUDE_DIR NAMES csound.h csound/csound.h)
endif()

set(CSOUND_LIBRARIES "${CSOUND_LIBRARY}")
set(CSOUND_INCLUDE_DIRS "${CSOUND_INCLUDE_DIR}")

# ------------------------------------------------------------------------------
# Version
# ------------------------------------------------------------------------------

set(CSOUND_VERSION "")
set(CSOUND_VERSION_MAJOR "")
set(CSOUND_VERSION_MINOR "")

if(CSOUND_EXECUTABLE)
    execute_process(
        COMMAND "${CSOUND_EXECUTABLE}" --version
        OUTPUT_VARIABLE _csound_version_stdout
        ERROR_VARIABLE _csound_version_stderr
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_STRIP_TRAILING_WHITESPACE
    )

    set(_csound_version_text "${_csound_version_stdout}\n${_csound_version_stderr}")

    string(REGEX MATCH "Csound version[ ]+([0-9]+)\\.([0-9]+)" _csound_version_match "${_csound_version_text}")

    if(_csound_version_match)
        set(CSOUND_VERSION "${CMAKE_MATCH_1}.${CMAKE_MATCH_2}")
        set(CSOUND_VERSION_MAJOR "${CMAKE_MATCH_1}")
        set(CSOUND_VERSION_MINOR "${CMAKE_MATCH_2}")
    endif()
endif()

# ------------------------------------------------------------------------------
# Result
# ------------------------------------------------------------------------------

if(CSOUND_LIBRARY AND CSOUND_INCLUDE_DIR AND CSOUND_EXECUTABLE)
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
set(CSOUND_VERSION "${CSOUND_VERSION}" CACHE STRING "Csound version" FORCE)
set(CSOUND_VERSION_MAJOR "${CSOUND_VERSION_MAJOR}" CACHE STRING "Csound major version" FORCE)
set(CSOUND_VERSION_MINOR "${CSOUND_VERSION_MINOR}" CACHE STRING "Csound minor version" FORCE)

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