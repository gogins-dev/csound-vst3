cmake_minimum_required(VERSION 3.21)

project(CsoundVST3
    VERSION 2.0.0
    DESCRIPTION "Csound in a VST3/AU/Standalone plugin."
    LANGUAGES C CXX
)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Build type" FORCE)
endif()

option(CSOUND_AC_ENABLE_CODESIGN "Sign Mach-O artifacts in dist when credentials are available." OFF)
option(CSOUND_AC_ENABLE_NOTARIZATION "Notarize the macOS distribution archive when credentials are available." OFF)
# Default OFF: release assumes a binary-compatible Csound 7 is already installed (e.g. CsoundLib64.framework
# under /Library/Frameworks or ~/Library/Frameworks). Set ON only for a self-contained bundle that ships Csound.
option(CSOUND_VST3_EMBED_CSOUND_FRAMEWORK
    "macOS: copy CsoundLib64.framework into each built .app/.vst3/.component (Contents/Frameworks)."
    OFF
)
# Ad-hoc re-sign after link with disable-library-validation so system CsoundLib64 can pull Homebrew dylibs.
# Turn OFF for strict signing experiments; distribution with official Csound typically does not need this.
option(CSOUND_VST3_MACOS_POSTBUILD_ADHOC_SIGN
    "macOS: after each bundle link, ad-hoc codesign with AllowIncompatibleCsoundDependencies.entitlements."
    ON
)

set(CSOUND_VST3_SOURCE_DIR
    "${CMAKE_CURRENT_LIST_DIR}"
    CACHE PATH "CsoundVST3 source directory."
)

set(CSOUND_VST3_REPOSITORY_ROOT
    "${CMAKE_CURRENT_LIST_DIR}/.."
    CACHE PATH "Repository root."
)

set(CSOUND_VST3_DIST_DIR
    "${CSOUND_VST3_REPOSITORY_ROOT}/dist"
    CACHE PATH "Distribution staging and local install directory."
)

string(TOLOWER "${CMAKE_SYSTEM_NAME}" CSOUND_VST3_SYSTEM_NAME_LOWER)

set(CSOUND_VST3_ARCHIVE_NAME
    "csound-vst3-${PROJECT_VERSION}-${CSOUND_VST3_SYSTEM_NAME_LOWER}.zip"
    CACHE STRING "Distribution archive filename."
)

set(CSOUND_VST3_ARCHIVE
    "${CMAKE_BINARY_DIR}/${CSOUND_VST3_ARCHIVE_NAME}"
    CACHE FILEPATH "Full path to the distribution archive."
)

message(STATUS "CMAKE_SYSTEM_NAME: ${CMAKE_SYSTEM_NAME}")
message(STATUS "CSOUND_VST3_SOURCE_DIR: ${CSOUND_VST3_SOURCE_DIR}")
message(STATUS "CSOUND_VST3_REPOSITORY_ROOT: ${CSOUND_VST3_REPOSITORY_ROOT}")
message(STATUS "CSOUND_VST3_DIST_DIR: ${CSOUND_VST3_DIST_DIR}")
message(STATUS "CSOUND_VST3_ARCHIVE: ${CSOUND_VST3_ARCHIVE}")
message(STATUS "CSOUND_AC_ENABLE_CODESIGN: ${CSOUND_AC_ENABLE_CODESIGN}")
message(STATUS "CSOUND_AC_ENABLE_NOTARIZATION: ${CSOUND_AC_ENABLE_NOTARIZATION}")
message(STATUS "CSOUND_VST3_EMBED_CSOUND_FRAMEWORK: ${CSOUND_VST3_EMBED_CSOUND_FRAMEWORK}")
message(STATUS "CSOUND_VST3_MACOS_POSTBUILD_ADHOC_SIGN: ${CSOUND_VST3_MACOS_POSTBUILD_ADHOC_SIGN}")

message(STATUS "Refreshing FindCsoundHomeFirst.cmake from csound-ac (csound_threaded.hpp is fetched at build time)...")

file(MAKE_DIRECTORY "${CSOUND_VST3_SOURCE_DIR}/cmake")

set(csound_ac_refresh_dir "${CMAKE_BINARY_DIR}/csound-ac-refresh")
file(MAKE_DIRECTORY "${csound_ac_refresh_dir}")
file(MAKE_DIRECTORY "${CSOUND_VST3_SOURCE_DIR}/cmake")

file(DOWNLOAD
    "https://raw.githubusercontent.com/gogins-dev/csound-ac/refs/heads/master/cmake/FindCsoundHomeFirst.cmake"
    "${csound_ac_refresh_dir}/FindCsoundHomeFirst.cmake"
    STATUS find_csound_download_status
    SHOW_PROGRESS
)

list(GET find_csound_download_status 0 find_csound_download_code)

if(find_csound_download_code EQUAL 0)
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${csound_ac_refresh_dir}/FindCsoundHomeFirst.cmake"
            "${CSOUND_VST3_SOURCE_DIR}/cmake/FindCsoundHomeFirst.cmake"
    )
else()
    list(GET find_csound_download_status 1 find_csound_download_message)
    message(WARNING
        "Failed to refresh FindCsoundHomeFirst.cmake from csound-ac head: "
        "${find_csound_download_message}. Using local copy."
    )
endif()

include("${CSOUND_VST3_SOURCE_DIR}/cmake/FindCsoundHomeFirst.cmake")

if(NOT CSOUND_FOUND)
    message(FATAL_ERROR "Csound was not found.")
endif()

# CsoundAC's downloaded csound_threaded.hpp uses #include "csound.hpp". Many Linux prefixes put
# csound.hpp in include/csound/ while FindCsoundHomeFirst sets CSOUND_INCLUDE_DIR to .../include.
if(CSOUND_INCLUDE_DIR AND EXISTS "${CSOUND_INCLUDE_DIR}/csound/csound.hpp")
    list(APPEND CSOUND_INCLUDE_DIRS "${CSOUND_INCLUDE_DIR}/csound")
endif()

message(STATUS "Using Csound executable:    ${CSOUND_EXECUTABLE}")
message(STATUS "Using Csound library:       ${CSOUND_LIBRARY}")
message(STATUS "Using Csound include dirs:  ${CSOUND_INCLUDE_DIRS}")
message(STATUS "Using Csound framework dir: ${CSOUND_FRAMEWORK_DIR}")
message(STATUS "Using Csound version:       ${CSOUND_VERSION}")

set(JUCE_ROOT
    "${CSOUND_VST3_REPOSITORY_ROOT}/include/JUCE"
    CACHE PATH "JUCE source directory."
)

if(NOT EXISTS "${JUCE_ROOT}/CMakeLists.txt")
    message(STATUS "JUCE was not found at ${JUCE_ROOT}. Downloading JUCE...")

    file(MAKE_DIRECTORY "${CSOUND_VST3_REPOSITORY_ROOT}/include")

    execute_process(
        COMMAND git clone --depth 1 --branch 8.0.8
            https://github.com/juce-framework/JUCE.git
            "${JUCE_ROOT}"
        RESULT_VARIABLE juce_clone_result
    )

    if(NOT juce_clone_result EQUAL 0)
        message(FATAL_ERROR
            "Failed to download JUCE into ${JUCE_ROOT}. "
            "Install git or clone JUCE there manually.")
    endif()
endif()

if(NOT TARGET juce::juce_core)
    add_subdirectory("${JUCE_ROOT}" "${CMAKE_BINARY_DIR}/JUCE")
endif()

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
    COPY_PLUGIN_AFTER_BUILD FALSE
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
    "${CSOUND_VST3_SOURCE_DIR}/Source"
    ${CSOUND_INCLUDE_DIRS}
)

# Every build: pull CsoundAC/csound_threaded.hpp (not Csound SDK). Source/ is listed before CSOUND_INCLUDE_DIRS
# so this file wins over any installed csound_threaded.hpp. Download failure is WARNING only (see script).
set(CSOUND_AC_CSOUND_THREADED_URL
    "https://raw.githubusercontent.com/gogins-dev/csound-ac/refs/heads/master/CsoundAC/csound_threaded.hpp"
)
set(CSOUND_AC_CSOUND_THREADED_DST "${CSOUND_VST3_SOURCE_DIR}/Source/csound_threaded.hpp")
add_custom_target(csound_ac_fetch_csound_threaded
    COMMAND "${CMAKE_COMMAND}"
        -DURL="${CSOUND_AC_CSOUND_THREADED_URL}"
        -DDST="${CSOUND_AC_CSOUND_THREADED_DST}"
        -P "${CSOUND_VST3_SOURCE_DIR}/cmake/FetchCsoundACCsoundThreaded.cmake"
    COMMENT "Download csound-ac CsoundAC/csound_threaded.hpp"
    VERBATIM
)
foreach(_csound_ac_fetch_t IN ITEMS CsoundVST3 CsoundVST3_VST3 CsoundVST3_AU CsoundVST3_Standalone)
    if(TARGET ${_csound_ac_fetch_t})
        add_dependencies(${_csound_ac_fetch_t} csound_ac_fetch_csound_threaded)
    endif()
endforeach()

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
    ${CSOUND_LIBRARIES}
)

find_package(CURL QUIET)
if(CURL_FOUND)
    target_link_libraries(CsoundVST3 PRIVATE CURL::libcurl)
else()
    target_link_libraries(CsoundVST3 PRIVATE curl)
endif()

target_compile_definitions(CsoundVST3 PRIVATE
    JUCE_STRICT_REFCOUNTEDPOINTER=1
    JUCE_VST3_CAN_REPLACE_VST2=0
    USE_DOUBLE
    CSOUND_VERSION_MAJOR=${CSOUND_VERSION_MAJOR}
    CSOUND_VERSION_MINOR=${CSOUND_VERSION_MINOR}
    CSOUND_AC_CSOUND_VERSION_MAJOR=${CSOUND_VERSION_MAJOR}
    CSOUND_AC_CSOUND_VERSION_MINOR=${CSOUND_VERSION_MINOR}
)

# juce_gui_extra pulls GTK/WebKit when JUCE_WEB_BROWSER=1; this project does not use WebBrowserComponent.
# Disabling avoids missing gtk/gtk.h on Linux CI where JUCE does not attach pkg-config flags to this target.
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_compile_definitions(CsoundVST3 PRIVATE JUCE_WEB_BROWSER=0)
endif()

if(APPLE)
    set(CSOUNDVST3_TARGETS
        CsoundVST3
        CsoundVST3_Standalone
        CsoundVST3_VST3
        CsoundVST3_AU
    )

    set(BASE_BUNDLE_ID "com.irreducibleproductions.csoundvst3")
    # Info.plist.in uses @EXECUTABLE_NAME@ / @PRODUCT_NAME@ (otherwise CFBundleExecutable is empty and the app won't launch).
    set(PRODUCT_NAME "CsoundVST3")
    set(EXECUTABLE_NAME "CsoundVST3")

    set(BUNDLE_IDENTIFIER "${BASE_BUNDLE_ID}.vst3")
    set(CFBundle_PACKAGE_TYPE "BNDL")
    configure_file("${CSOUND_VST3_SOURCE_DIR}/Resources/Info.plist.in" "${CMAKE_BINARY_DIR}/VST3_Info.plist" @ONLY)

    set(BUNDLE_IDENTIFIER "${BASE_BUNDLE_ID}.au")
    set(CFBundle_PACKAGE_TYPE "BNDL")
    configure_file("${CSOUND_VST3_SOURCE_DIR}/Resources/Info.plist.in" "${CMAKE_BINARY_DIR}/AU_Info.plist" @ONLY)

    set(BUNDLE_IDENTIFIER "${BASE_BUNDLE_ID}.standalone")
    set(CFBundle_PACKAGE_TYPE "APPL")
    configure_file("${CSOUND_VST3_SOURCE_DIR}/Resources/Info.plist.in" "${CMAKE_BINARY_DIR}/Standalone_Info.plist" @ONLY)

    if(TARGET CsoundVST3_VST3)
        set_target_properties(CsoundVST3_VST3 PROPERTIES
            MACOSX_BUNDLE_INFO_PLIST "${CMAKE_BINARY_DIR}/VST3_Info.plist"
        )
    endif()

    if(TARGET CsoundVST3_AU)
        set_target_properties(CsoundVST3_AU PROPERTIES
            MACOSX_BUNDLE_INFO_PLIST "${CMAKE_BINARY_DIR}/AU_Info.plist"
        )
    endif()

    if(TARGET CsoundVST3_Standalone)
        set_target_properties(CsoundVST3_Standalone PROPERTIES
            MACOSX_BUNDLE_INFO_PLIST "${CMAKE_BINARY_DIR}/Standalone_Info.plist"
        )
    endif()

    set(ICNS_FILE "${CSOUND_VST3_SOURCE_DIR}/Resources/angel_concert.icns")
    set_source_files_properties("${ICNS_FILE}" PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")

    foreach(target IN LISTS CSOUNDVST3_TARGETS)
        if(TARGET ${target})
            target_sources(${target} PRIVATE "${ICNS_FILE}")
            target_link_libraries(${target} PRIVATE ${CSOUND_LIBRARIES})
            target_link_options(${target} PRIVATE
                "-Wl,-rpath,@loader_path"
                "-Wl,-rpath,@loader_path/../Frameworks"
                "-Wl,-rpath,@loader_path/../lib"
                "-Wl,-rpath,/Library/Frameworks"
                "-Wl,-rpath,/usr/local/lib"
            )
            if(CSOUND_FRAMEWORK_DIR)
                get_filename_component(csound_framework_parent "${CSOUND_FRAMEWORK_DIR}" DIRECTORY)
                target_link_options(${target} PRIVATE "-F${csound_framework_parent}")
                # Only bake the build machine's framework path into rpath when embedding; otherwise rely on
                # /Library/Frameworks plus a POST_BUILD rewrite of the Csound dylib reference to @rpath.
                if(CSOUND_VST3_EMBED_CSOUND_FRAMEWORK)
                    target_link_options(${target} PRIVATE "-Wl,-rpath,${csound_framework_parent}")
                endif()
            endif()
            set_target_properties(${target} PROPERTIES
                MACOSX_BUNDLE TRUE
                MACOSX_BUNDLE_ICON_FILE angel_concert.icns
                BUILD_WITH_INSTALL_RPATH ON
                INSTALL_RPATH "@loader_path;@loader_path/../Frameworks;@loader_path/../lib;/Library/Frameworks;/usr/local/lib"
            )
        endif()
    endforeach()

    # Optional: ship Csound inside each bundle. When OFF (default), plugins load the host's Csound 7 via
    # rpath (/Library/Frameworks, etc.) and the dylib path recorded at link time.
    if(CSOUND_VST3_EMBED_CSOUND_FRAMEWORK AND CSOUND_FRAMEWORK_DIR)
        get_filename_component(_csound_fw_bundle_name "${CSOUND_FRAMEWORK_DIR}" NAME)
        message(STATUS "Embedding ${CSOUND_FRAMEWORK_DIR} into bundles (POST_BUILD → Contents/Frameworks/${_csound_fw_bundle_name}).")
        foreach(_csound_embed_tgt IN ITEMS CsoundVST3_Standalone CsoundVST3_VST3 CsoundVST3_AU)
            if(TARGET ${_csound_embed_tgt})
                add_custom_command(TARGET ${_csound_embed_tgt} POST_BUILD
                    COMMAND "${CMAKE_COMMAND}" -E rm -rf
                        "$<TARGET_BUNDLE_CONTENT_DIR:${_csound_embed_tgt}>/Frameworks"
                    COMMAND "${CMAKE_COMMAND}" -E make_directory
                        "$<TARGET_BUNDLE_CONTENT_DIR:${_csound_embed_tgt}>/Frameworks"
                    COMMAND /usr/bin/ditto
                        "${CSOUND_FRAMEWORK_DIR}"
                        "$<TARGET_BUNDLE_CONTENT_DIR:${_csound_embed_tgt}>/Frameworks/${_csound_fw_bundle_name}"
                    COMMENT "Embedding ${_csound_fw_bundle_name} into ${_csound_embed_tgt} (ditto preserves framework symlinks)"
                    VERBATIM
                )
            endif()
        endforeach()
    elseif(CSOUND_FRAMEWORK_DIR)
        message(STATUS "Not embedding Csound framework (CSOUND_VST3_EMBED_CSOUND_FRAMEWORK=OFF); require compatible Csound 7 on the system.")
    endif()

    # Ship-time: load Csound from /Library/Frameworks (or other paths already on INSTALL_RPATH), not the
    # absolute path where this project was linked (e.g. CI's /tmp/csound-install/...).
    if(NOT CSOUND_VST3_EMBED_CSOUND_FRAMEWORK)
        foreach(_rewrite_t IN ITEMS CsoundVST3_VST3 CsoundVST3_AU CsoundVST3_Standalone)
            if(TARGET ${_rewrite_t})
                add_custom_command(TARGET ${_rewrite_t} POST_BUILD
                    COMMAND /bin/bash
                        "${CSOUND_VST3_SOURCE_DIR}/cmake/rewrite-csound-macos-dylib-ref.bash"
                        "$<TARGET_FILE:${_rewrite_t}>"
                    COMMENT "Rewrite CsoundLib64 dependency to @rpath for system-installed Csound 7"
                    VERBATIM
                )
            endif()
        endforeach()
    endif()

    set(_csound_entitlements "${CSOUND_VST3_SOURCE_DIR}/Resources/macos/AllowIncompatibleCsoundDependencies.entitlements")
    if(CSOUND_VST3_MACOS_POSTBUILD_ADHOC_SIGN AND EXISTS "${_csound_entitlements}")
        if(TARGET CsoundVST3_Standalone)
            add_custom_command(TARGET CsoundVST3_Standalone POST_BUILD
                COMMAND /bin/bash
                    "${CSOUND_VST3_SOURCE_DIR}/cmake/postbuild-sign-macos-bundle.bash"
                    "$<TARGET_BUNDLE_DIR:CsoundVST3_Standalone>"
                    "${_csound_entitlements}"
                    --deep
                COMMENT "Post-link codesign Standalone (entitlements for Homebrew-linked system Csound)"
                VERBATIM
            )
        endif()
        foreach(_adhoc_t IN ITEMS CsoundVST3_VST3 CsoundVST3_AU)
            if(TARGET ${_adhoc_t})
                add_custom_command(TARGET ${_adhoc_t} POST_BUILD
                    COMMAND /bin/bash
                        "${CSOUND_VST3_SOURCE_DIR}/cmake/postbuild-sign-macos-bundle.bash"
                        "$<TARGET_BUNDLE_DIR:${_adhoc_t}>"
                        "${_csound_entitlements}"
                        NONE
                    COMMENT "Post-link codesign ${_adhoc_t} (entitlements for Homebrew-linked system Csound)"
                    VERBATIM
                )
            endif()
        endforeach()
    endif()
elseif(WIN32)
    set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
elseif(UNIX)
    target_link_libraries(CsoundVST3 PRIVATE ${CSOUND_LIBRARY})
endif()

# Do not install CsoundVST3's BUNDLE to Applications — that collides with CsoundVST3_Standalone's
# CsoundVST3.app and yields an app bundle with an empty Contents/MacOS ("executable is missing").
install(TARGETS CsoundVST3
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    COMPONENT CsoundVST3_Runtime
)

if(APPLE)
    if(TARGET CsoundVST3_VST3)
        install(TARGETS CsoundVST3_VST3
            LIBRARY DESTINATION "Library/Audio/Plug-Ins/VST3"
            BUNDLE DESTINATION "Library/Audio/Plug-Ins/VST3"
            COMPONENT CsoundVST3_Runtime
        )
    endif()

    if(TARGET CsoundVST3_AU)
        install(TARGETS CsoundVST3_AU
            LIBRARY DESTINATION "Library/Audio/Plug-Ins/Components"
            BUNDLE DESTINATION "Library/Audio/Plug-Ins/Components"
            COMPONENT CsoundVST3_Runtime
        )
    endif()

    if(TARGET CsoundVST3_Standalone)
        install(TARGETS CsoundVST3_Standalone
            BUNDLE DESTINATION Applications
            COMPONENT CsoundVST3_Runtime
        )
    endif()
endif()

install(FILES
    "${CSOUND_VST3_REPOSITORY_ROOT}/README.md"
    DESTINATION .
    OPTIONAL
    COMPONENT CsoundVST3_Runtime
)

install(DIRECTORY
    "${CSOUND_VST3_SOURCE_DIR}/Resources"
    DESTINATION .
    COMPONENT CsoundVST3_Runtime
)

add_custom_target(clean_dist
    COMMAND "${CMAKE_COMMAND}" -E rm -rf "${CSOUND_VST3_DIST_DIR}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${CSOUND_VST3_DIST_DIR}"
    COMMENT "Creating clean dist directory"
)

# macOS only: install copies .app/.vst3/.component from the build tree; they must be built first.
# Depending only on CsoundVST3 can leave CsoundVST3_Standalone unbuilt and yield an empty Contents/MacOS/.
set(CSOUND_VST3_STAGE_DIST_DEPS clean_dist CsoundVST3)
if(APPLE)
    foreach(_stage_bundle_t IN ITEMS CsoundVST3_Standalone CsoundVST3_VST3 CsoundVST3_AU)
        if(TARGET ${_stage_bundle_t})
            list(APPEND CSOUND_VST3_STAGE_DIST_DEPS ${_stage_bundle_t})
        endif()
    endforeach()
endif()
add_custom_target(stage_dist
    DEPENDS ${CSOUND_VST3_STAGE_DIST_DEPS}
    COMMAND "${CMAKE_COMMAND}" --install "${CMAKE_BINARY_DIR}" --prefix "${CSOUND_VST3_DIST_DIR}" --component CsoundVST3_Runtime --config "$<CONFIG>"
    COMMENT "Installing runtime artifacts into dist"
)

if(APPLE)
    add_custom_target(sign_dist
        DEPENDS stage_dist
        COMMAND /bin/bash
            "${CSOUND_VST3_SOURCE_DIR}/cmake/sign-macos-dist.bash"
            "${CSOUND_VST3_DIST_DIR}"
            "$<IF:$<BOOL:${CSOUND_AC_ENABLE_CODESIGN}>,ON,OFF>"
        VERBATIM
        COMMENT "Signing macOS Mach-O artifacts in dist when enabled"
    )

    add_custom_target(archive_dist
        DEPENDS sign_dist
        COMMAND "${CMAKE_COMMAND}" -E tar cfv "${CSOUND_VST3_ARCHIVE}" --format=zip -- dist
        WORKING_DIRECTORY "${CSOUND_VST3_REPOSITORY_ROOT}"
        COMMENT "Creating macOS dist archive"
    )

    add_custom_target(notarize_dist
        DEPENDS archive_dist
        COMMAND /bin/bash
            "${CSOUND_VST3_SOURCE_DIR}/cmake/notarize-macos-dist.bash"
            "${CSOUND_VST3_ARCHIVE}"
            "$<IF:$<AND:$<BOOL:${CSOUND_AC_ENABLE_CODESIGN}>,$<BOOL:${CSOUND_AC_ENABLE_NOTARIZATION}>>,ON,OFF>"
        VERBATIM
        COMMENT "Notarizing macOS dist archive when enabled"
    )

    if(CSOUND_AC_ENABLE_CODESIGN AND CSOUND_AC_ENABLE_NOTARIZATION)
        add_custom_target(verify_macos_dist
            DEPENDS notarize_dist
            COMMAND /bin/bash
                "${CSOUND_VST3_SOURCE_DIR}/codesign-check.bash"
                "${CSOUND_VST3_ARCHIVE}"
            VERBATIM
            COMMENT "Verifying macOS distribution archive (codesign / Gatekeeper)"
        )
    endif()

else()
    add_custom_target(sign_dist
        DEPENDS stage_dist
        COMMAND "${CMAKE_COMMAND}" -E echo "No platform signing step configured for ${CMAKE_SYSTEM_NAME}."
    )

    add_custom_target(archive_dist
        DEPENDS sign_dist
        COMMAND "${CMAKE_COMMAND}" -E tar cfv "${CSOUND_VST3_ARCHIVE}" --format=zip -- dist
        WORKING_DIRECTORY "${CSOUND_VST3_REPOSITORY_ROOT}"
        COMMENT "Creating dist archive"
    )
endif()
