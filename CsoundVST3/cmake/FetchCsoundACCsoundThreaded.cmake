# Invoked as: cmake -DURL=... -DDST=... -P FetchCsoundACCsoundThreaded.cmake
# Downloads gogins-dev/csound-ac CsoundAC/csound_threaded.hpp to DST. Never calls message(FATAL_ERROR).

if(NOT DEFINED URL OR NOT DEFINED DST)
    message(WARNING "FetchCsoundACCsoundThreaded.cmake: URL or DST not set; skipping download.")
    return()
endif()

get_filename_component(_dst_dir "${DST}" DIRECTORY)
file(MAKE_DIRECTORY "${_dst_dir}")

set(_tmp "${DST}.download.tmp")
file(DOWNLOAD "${URL}" "${_tmp}" STATUS _st SHOW_PROGRESS)
list(GET _st 0 _code)
if(_code EQUAL 0)
    file(RENAME "${_tmp}" "${DST}")
    message(STATUS "Updated csound-ac CsoundAC/csound_threaded.hpp -> ${DST}")
else()
    list(GET _st 1 _msg)
    message(WARNING "Could not download csound-ac csound_threaded.hpp (${_msg}). Using existing file if present: ${DST}")
    if(EXISTS "${_tmp}")
        file(REMOVE "${_tmp}")
    endif()
endif()
