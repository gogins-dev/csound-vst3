#!/usr/bin/env bash
set -euo pipefail

echo "Cleaning and building CsoundVST3 for Windows..."
config="${1:-Release}"
shift || true
cmake_args=()
if [[ $# -gt 0 ]]; then
    cmake_args=("$@")
fi

source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${source_dir}/.." && pwd)"
build_dir="${repo_root}/build-windows"
install_dir="${repo_root}/dist"

rm -rf "${build_dir}" "${install_dir}"
cmake -S "${source_dir}" -B "${build_dir}" -G Ninja \
    -DCMAKE_BUILD_TYPE="${config}" \
    -DCMAKE_INSTALL_PREFIX="${install_dir}" \
    ${cmake_args[@]+"${cmake_args[@]}"}
cmake --build "${build_dir}" --config "${config}" --parallel --target archive_dist
find "${install_dir}" -print
cmake -E echo "Archive: ${build_dir}/csound-vst3-2.0.0-windows.zip"
echo "Completed clean build of CsoundVST3 for Windows. Built artifacts are in dist/."
