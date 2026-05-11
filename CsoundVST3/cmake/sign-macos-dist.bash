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

ent_args=()
if [[ -n "${CSOUND_VST3_MACOS_ENTITLEMENTS:-}" && -f "${CSOUND_VST3_MACOS_ENTITLEMENTS}" ]]
then
    ent_args=(--entitlements "${CSOUND_VST3_MACOS_ENTITLEMENTS}")
    echo "Using CSOUND_VST3_MACOS_ENTITLEMENTS=${CSOUND_VST3_MACOS_ENTITLEMENTS} (Contents/MacOS + outer bundles)."
fi

# 1) Embedded .framework bundles (deepest first). Use --deep so nested libs inside the framework are sealed.
echo "Signing .framework bundles (deepest paths first)"
while IFS= read -r fw_path
do
    [[ -z "${fw_path}" ]] && continue
    echo "Signing framework ${fw_path}"
    codesign --force --deep "${bundle_extra[@]+"${bundle_extra[@]}"}" --sign "${identity}" "${fw_path}"
done < <(
    find "${dist_dir}" -type d -name "*.framework" -print |
        awk '{ print length($0) "\t" $0 }' |
        sort -rn |
        cut -f2-
)

# 2) Main executable inside each plugin/app bundle (excluded from loose Mach-O pass below).
echo "Signing Contents/MacOS binaries"
while IFS= read -r exe_path
do
    [[ -z "${exe_path}" ]] && continue
    case "${exe_path}" in
        *.framework/*)
            continue
            ;;
    esac
    [[ "${exe_path}" == *"/Contents/MacOS/"* ]] || continue
    if file "${exe_path}" | grep -q "Mach-O"
    then
        echo "Signing ${exe_path}"
        codesign --force "${macho_extra[@]+"${macho_extra[@]}"}" "${ent_args[@]+"${ent_args[@]}"}" --sign "${identity}" "${exe_path}"
    fi
done < <(
    find "${dist_dir}" -type f ! -path "*.framework/*" -print
)

# 3) Loose Mach-O outside bundles
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
        codesign --force "${macho_extra[@]+"${macho_extra[@]}"}" --sign "${identity}" "${file_path}"
    fi
done < <(
    find "${dist_dir}" -type f -print
)

# 4) Outer bundles: --deep on .app; .vst3 / .au .component often fail with --deep once frameworks are embedded —
#    use a single seal without --deep for those (internals already signed above).
echo "Signing app/vst3/component bundles"
while IFS= read -r bundle_path
do
    [[ -z "${bundle_path}" ]] && continue
    case "${bundle_path}" in
        *.app)
            echo "Signing bundle ${bundle_path}"
            codesign --force --deep "${bundle_extra[@]+"${bundle_extra[@]}"}" "${ent_args[@]+"${ent_args[@]}"}" --sign "${identity}" "${bundle_path}"
            ;;
        *.vst3|*.component)
            echo "Signing bundle ${bundle_path}"
            codesign --force "${bundle_extra[@]+"${bundle_extra[@]}"}" "${ent_args[@]+"${ent_args[@]}"}" --sign "${identity}" "${bundle_path}"
            ;;
    esac
done < <(
    find "${dist_dir}" -type d \( -name "*.app" -o -name "*.vst3" -o -name "*.component" \) -print
)
