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

# Nested frameworks (e.g. dist/.../CsoundVST3.vst3/Contents/Frameworks/CsoundLib64.framework)
# must be signed before enclosing .app / .vst3 / .component bundles or codesign errors:
# "bundle format unrecognized, invalid, or unsuitable"
echo "Signing .framework bundles (deepest paths first)"
while IFS= read -r fw_path
do
    [[ -z "${fw_path}" ]] && continue
    echo "Signing framework ${fw_path}"
    codesign --force "${bundle_extra[@]}" --sign "${identity}" "${fw_path}"
done < <(
    find "${dist_dir}" -type d -name "*.framework" -print |
        awk '{ print length($0) "\t" $0 }' |
        sort -rn |
        cut -f2-
)

echo "Signing Mach-O files outside app/vst3/component bundles"
while IFS= read -r file_path
do
    [[ -z "${file_path}" ]] && continue
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

echo "Signing app/vst3/component bundles"
while IFS= read -r bundle_path
do
    [[ -z "${bundle_path}" ]] && continue
    case "${bundle_path}" in
        *.app|*.vst3|*.component)
            echo "Signing bundle ${bundle_path}"
            codesign --force --deep "${bundle_extra[@]}" --sign "${identity}" "${bundle_path}"
            ;;
    esac
done < <(
    find "${dist_dir}" -type d \( -name "*.app" -o -name "*.vst3" -o -name "*.component" \) -print
)
