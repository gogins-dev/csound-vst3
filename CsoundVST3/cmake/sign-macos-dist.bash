#!/usr/bin/env bash
set -euo pipefail

dist_dir="${1:?dist directory is required}"
enabled="${2:-OFF}"

if [[ "${enabled}" != "ON" ]]
then
    echo "Code signing is disabled."
    exit 0
fi

identity="${APPLE_CODESIGN_IDENTITY:--}"

if [[ "${identity}" == "-" ]]
then
    echo "APPLE_CODESIGN_IDENTITY not set (using ad hoc signing \"-\" for local builds)."
    bundle_extra=()
    macho_extra=()
else
    bundle_extra=(--timestamp --options runtime)
    macho_extra=(--timestamp --options runtime)
fi

if [[ ! -d "${dist_dir}" ]]
then
    echo "dist directory does not exist: ${dist_dir}"
    exit 1
fi

echo "Signing macOS artifacts in ${dist_dir}"

while IFS= read -r bundle_path
do
    case "${bundle_path}" in
        *.app|*.vst3|*.component)
            echo "Signing bundle ${bundle_path}"
            codesign --force --deep "${bundle_extra[@]}" --sign "${identity}" "${bundle_path}"
            ;;
    esac
done < <(
    find "${dist_dir}" -type d \( -name "*.app" -o -name "*.vst3" -o -name "*.component" \) -print
)

while IFS= read -r file_path
do
    case "${file_path}" in
        *.app/*|*.vst3/*|*.component/*)
            continue
            ;;
    esac

    if file "${file_path}" | grep -q "Mach-O"
    then
        echo "Signing Mach-O file ${file_path}"
        codesign --force "${macho_extra[@]}" --sign "${identity}" "${file_path}"
    fi
done < <(
    find "${dist_dir}" -type f -print
)
