#!/usr/bin/env bash
set -euo pipefail

echo "Cleaning and building CsoundVST3 for macOS..."
strict_codesign=false
cmake_args=()
while (($#))
do
    case "$1" in
        --strict-codesign)
            strict_codesign=true
            shift
            ;;
        *)
            cmake_args+=("$1")
            shift
            ;;
    esac
done

source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${source_dir}/.." && pwd)"
build_dir="${repo_root}/build-macos"
install_dir="${repo_root}/dist"
entitlements="${source_dir}/Resources/macos/AllowIncompatibleCsoundDependencies.entitlements"

if [[ "${strict_codesign}" != true && -f "${entitlements}" ]]
then
    export CSOUND_VST3_MACOS_ENTITLEMENTS="${entitlements}"
    echo "CSOUND_VST3_MACOS_ENTITLEMENTS=${entitlements} (local dist signing; use with Homebrew-linked system Csound)."
    echo "GitHub Actions omits this for strict release signing; pass --strict-codesign here to match CI."
else
    unset CSOUND_VST3_MACOS_ENTITLEMENTS 2>/dev/null || true
    if [[ "${strict_codesign}" == true ]]
    then
        echo "Strict codesign: CSOUND_VST3_MACOS_ENTITLEMENTS unset."
    fi
fi

rm -rf "${build_dir}" "${install_dir}"
cmake -S "${source_dir}" -B "${build_dir}" -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=10.15 \
    -DCMAKE_OSX_ARCHITECTURES="${CMAKE_OSX_ARCHITECTURES:-arm64}" \
    -DCMAKE_INSTALL_PREFIX="${install_dir}" \
    -DCMAKE_PREFIX_PATH="/Library;/Library/Frameworks;/opt/homebrew;/usr/local" \
    -DCMAKE_FRAMEWORK_PATH="/Library/Frameworks;$HOME/Library/Frameworks" \
    -DCSOUND_AC_ENABLE_CODESIGN=ON \
    -DCSOUND_AC_ENABLE_NOTARIZATION=OFF \
    ${cmake_args[@]+"${cmake_args[@]}"}
cmake --build "${build_dir}" --parallel --target archive_dist
cmake --build "${build_dir}" --target notarize_dist

cache_bool_on()
{
    local variable_name="${1:?}"
    local cache_file="${build_dir}/CMakeCache.txt"
    local raw value

    [[ -f "${cache_file}" ]] || return 1
    raw="$(grep -E "^${variable_name}:" "${cache_file}" | head -1)" || return 1
    value="${raw##*=}"
    case "${value}" in
        ON|YES|TRUE|1)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

if cache_bool_on CSOUND_AC_ENABLE_CODESIGN && cache_bool_on CSOUND_AC_ENABLE_NOTARIZATION
then
    cmake --build "${build_dir}" --parallel --target verify_macos_dist
fi

find "${install_dir}" -print
cmake -E echo "Archive: ${build_dir}/csound-vst3-2.0.0-darwin.zip"
echo "Completed clean build of CsoundVST3 for macOS. Built artifacts are in dist/."
echo "Signed with ad hoc identity unless APPLE_CODESIGN_IDENTITY is set (Developer ID for distribution)."
echo "Run standalone (use open, not execute): open \"${install_dir}/Applications/CsoundVST3.app\""
