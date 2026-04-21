cmake_minimum_required(VERSION 3.15)

project(CsoundVST3 VERSION 2.0.0)
set(CSOUND_SIGN_IDENTITY "Apple Development: Michael Gogins (JC94KD4B5T)" CACHE STRING "Code signing identity for macOS")

# Require C++20
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Set JUCE root
set(JUCE_ROOT "${CMAKE_SOURCE_DIR}/include/JUCE")
add_subdirectory(${JUCE_ROOT})

# ------------------------------------------------------------------------------
# Find Csound
# ------------------------------------------------------------------------------

if(APPLE)
    include("$ENV{HOME}/cmake/FindCsoundHomeFirst.cmake")

    if(NOT CSOUND_FOUND)
        message(FATAL_ERROR "Csound was not found on macOS.")
    endif()

    message(STATUS "CSOUND_EXECUTABLE:   ${CSOUND_EXECUTABLE}")
    message(STATUS "CSOUND_LIBRARY:      ${CSOUND_LIBRARY}")
    message(STATUS "CSOUND_INCLUDE_DIRS: ${CSOUND_INCLUDE_DIRS}")
    message(STATUS "CSOUND_FRAMEWORK_DIR:${CSOUND_FRAMEWORK_DIR}")
    message(STATUS "CSOUND_VERSION:      ${CSOUND_VERSION}")

else()
    # Allow the user to specify a custom root path for Csound
    set(CSOUND_ROOT "" CACHE PATH "Root directory of the Csound installation")

    if(WIN32)
        set(CSOUND_POSSIBLE_PATHS
            "${CSOUND_ROOT}"
            "C:/Program Files/Csound6_x64"
            "C:/Program Files (x86)/Csound6_x86"
        )
    elseif(UNIX)
        set(CSOUND_POSSIBLE_PATHS
            "${CSOUND_ROOT}"
            "/usr"
            "/usr/local"
            "/opt"
        )
    endif()

    find_path(CSOUND_INCLUDE_DIR
        NAMES csound.hpp csound.h
        PATH_SUFFIXES include/csound include
        PATHS ${CSOUND_POSSIBLE_PATHS}
        NO_DEFAULT_PATH
    )

    find_library(CSOUND_LIBRARY
        NAMES csound64 CsoundLib64 csound
        PATH_SUFFIXES lib
        PATHS ${CSOUND_POSSIBLE_PATHS}
        NO_DEFAULT_PATH
    )

    if(NOT CSOUND_INCLUDE_DIR OR NOT CSOUND_LIBRARY)
        message(FATAL_ERROR "Csound library or headers not found. Set CSOUND_ROOT or install Csound.")
    endif()

    set(CSOUND_INCLUDE_DIRS "${CSOUND_INCLUDE_DIR}")
    set(CSOUND_LIBRARIES "${CSOUND_LIBRARY}")
endif()

# ------------------------------------------------------------------------------
# Plugin
# ------------------------------------------------------------------------------

juce_add_plugin(CsoundVST3
    COMPANY_NAME "Irreducible Productions"
    COMPANY_WEBSITE "https://michaelgogins.tumblr.com"
    COMPANY_EMAIL "michael.gogins@gmail.com"

    IS_SYNTH TRUE
    IS_MIDI_EFFECT TRUE
    NEEDS_MIDI_INPUT TRUE

    FORMATS AU VST3 Standalone

    VST3_CATEGORIES "Fx;Instrument"
    BUNDLE_ID "com.irreducibleproductions.csoundvst3"

    PLUGIN_MANUFACTURER_CODE IrPr
    PLUGIN_CODE Csv3
    PRODUCT_NAME "CsoundVST3"
    COPY_PLUGIN_AFTER_BUILD TRUE
)

juce_add_binary_data(CsoundBinaryData
    SOURCES
        Resources/angel_concert.png
        Resources/angel_concert.icns
)

target_sources(CsoundVST3 PRIVATE
    Source/PluginProcessor.cpp
    Source/PluginEditor.cpp
    Source/CsoundTokeniser.cpp
)

target_include_directories(CsoundVST3 PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/Source
    ${CSOUND_INCLUDE_DIRS}
    /usr/include/harfbuzz/
    /usr/include/glib-2.0/glib
)

target_link_libraries(CsoundVST3 PRIVATE
    CsoundBinaryData
    juce::juce_audio_basics
    juce::juce_audio_devices
    juce::juce_audio_formats
    juce::juce_audio_plugin_client
    juce::juce_audio_processors
    juce::juce_audio_utils
    juce::juce_core
    juce::juce_data_structures
    juce::juce_events
    juce::juce_graphics
    juce::juce_gui_basics
    juce::juce_gui_extra
    curl
)

target_compile_definitions(CsoundVST3 PRIVATE
    JUCE_STRICT_REFCOUNTEDPOINTER=1
    JUCE_VST3_CAN_REPLACE_VST2=0
)

set(resources
    Resources/angel_concert.png
    Resources/angel_concert.icns
    Resources/README.md
)

# ------------------------------------------------------------------------------
# macOS-specific bundle properties and Csound linkage
# ------------------------------------------------------------------------------

if(APPLE)
    set(CSOUNDVST3_TARGETS
        CsoundVST3
        CsoundVST3_Standalone
        CsoundVST3_VST3
        CsoundVST3_AU
    )

    set(BASE_BUNDLE_ID "com.irreducibleproductions.csoundvst3")

    set(BUNDLE_IDENTIFIER "${BASE_BUNDLE_ID}.vst3")
    configure_file(${CMAKE_SOURCE_DIR}/Resources/Info.plist.in ${CMAKE_BINARY_DIR}/VST3_Info.plist @ONLY)

    set(BUNDLE_IDENTIFIER "${BASE_BUNDLE_ID}.au")
    configure_file(${CMAKE_SOURCE_DIR}/Resources/Info.plist.in ${CMAKE_BINARY_DIR}/AU_Info.plist @ONLY)

    set(BUNDLE_IDENTIFIER "${BASE_BUNDLE_ID}.standalone")
    configure_file(${CMAKE_SOURCE_DIR}/Resources/Info.plist.in ${CMAKE_BINARY_DIR}/Standalone_Info.plist @ONLY)

    set_target_properties(CsoundVST3_VST3 PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_BINARY_DIR}/VST3_Info.plist
    )
    set_target_properties(CsoundVST3_AU PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_BINARY_DIR}/AU_Info.plist
    )
    set_target_properties(CsoundVST3_Standalone PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_BINARY_DIR}/Standalone_Info.plist
    )

    set(ICNS_FILE Resources/angel_concert.icns)
    set_source_files_properties(${ICNS_FILE} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")

    if(CSOUND_FRAMEWORK_DIR)
        get_filename_component(CSOUND_FRAMEWORK_PARENT "${CSOUND_FRAMEWORK_DIR}" DIRECTORY)
    else()
        get_filename_component(CSOUND_FRAMEWORK_PARENT "${CSOUND_LIBRARY}" DIRECTORY)
    endif()

    foreach(target IN LISTS CSOUNDVST3_TARGETS)
        if(TARGET ${target})
            target_include_directories(${target} PRIVATE ${CSOUND_INCLUDE_DIRS})
            target_link_libraries(${target} PRIVATE "${CSOUND_LIBRARIES}")
            target_link_options(${target} PRIVATE
                "-F${CSOUND_FRAMEWORK_PARENT}"
                "-Wl,-rpath,${CSOUND_FRAMEWORK_PARENT}"
            )
            target_sources(${target} PRIVATE ${ICNS_FILE})
            set_target_properties(${target} PROPERTIES
                MACOSX_BUNDLE TRUE
                MACOSX_BUNDLE_ICON_FILE angel_concert.icns
            )
        endif()
    endforeach()

elseif(WIN32)
    set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
    if(CSOUND_INCLUDE_DIR)
        target_include_directories(CsoundVST3 PRIVATE ${CSOUND_INCLUDE_DIR})
    endif()
    if(CSOUND_LIBRARY)
        target_link_libraries(CsoundVST3 PRIVATE ${CSOUND_LIBRARY})
    endif()

elseif(UNIX)
    include_directories("/usr/include/csound" "/opt/homebrew/include/csound")
    link_directories("/usr/lib" "/opt/homebrew/lib")
    target_link_libraries(CsoundVST3 PRIVATE ${CSOUND_LIBRARY})
endif()

# ------------------------------------------------------------------------------
# Install
# ------------------------------------------------------------------------------

if(APPLE)
    install(TARGETS CsoundVST3_VST3
        LIBRARY DESTINATION Library/Audio/Plug-Ins/VST3
    )

    install(TARGETS CsoundVST3_AU
        LIBRARY DESTINATION Library/Audio/Plug-Ins/Components
    )

    install(TARGETS CsoundVST3_Standalone
        BUNDLE DESTINATION Applications
    )

    install(CODE "
        message(STATUS \"Signing VST3 bundle...\")
        execute_process(COMMAND codesign --deep --force --options runtime
            --sign \"${CSOUND_SIGN_IDENTITY}\"
            \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/Library/Audio/Plug-Ins/VST3/CsoundVST3.vst3\")

        message(STATUS \"Signing AU component...\")
        execute_process(COMMAND codesign --deep --force --options runtime
            --sign \"${CSOUND_SIGN_IDENTITY}\"
            \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/Library/Audio/Plug-Ins/Components/CsoundVST3.component\")

        message(STATUS \"Signing Standalone app...\")
        execute_process(COMMAND codesign --deep --force --options runtime
            --sign \"${CSOUND_SIGN_IDENTITY}\"
            \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/Applications/CsoundVST3.app\")
    ")
elseif(WIN32 OR UNIX)
    install(TARGETS CsoundVST3
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
    )
endif()