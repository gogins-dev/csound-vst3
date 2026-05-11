#!/usr/bin/env bash
set -euo pipefail

zip_file="${1:?usage: $0 path/to/archive.zip}"

if [[ ! -f "${zip_file}" ]]
then
    echo "ERROR: ZIP file does not exist: ${zip_file}"
    exit 1
fi

if [[ "$(uname -s)" != "Darwin" ]]
then
    echo "ERROR: This script must run on macOS."
    exit 1
fi

work_dir="$(mktemp -d -t verify-macos-zip.XXXXXX)"

cleanup()
{
    rm -rf "${work_dir}"
}

trap cleanup EXIT

failures=0

fail()
{
    echo "FAIL: $*"
    failures=$((failures + 1))
}

pass()
{
    echo "PASS: $*"
}

warn()
{
    echo "WARN: $*"
}

section()
{
    echo
    echo "==== $* ===="
}

relative_path()
{
    case "$1" in
        "${work_dir}"/*)
            printf "%s\n" "${1#${work_dir}/}"
            ;;
        *)
            printf "%s\n" "$1"
            ;;
    esac
}

section "ZIP"
echo "ZIP: ${zip_file}"

if unzip -tq "${zip_file}" >/dev/null
then
    pass "ZIP integrity"
else
    fail "ZIP integrity"
fi

if unzip -q "${zip_file}" -d "${work_dir}"
then
    pass "ZIP extraction"
else
    fail "ZIP extraction"
fi

section "Mach-O discovery"

macho_list="${work_dir}/macho-files.txt"
bundle_list="${work_dir}/bundles.txt"
codesign_output="${work_dir}/codesign.out"
codesign_bundle_output="${work_dir}/codesign-bundle.out"
spctl_output="${work_dir}/spctl.out"
stapler_output="${work_dir}/stapler.out"

: > "${macho_list}"
: > "${bundle_list}"

find "${work_dir}" -type f -print0 |
while IFS= read -r -d '' file_path
do
    if file "${file_path}" | grep -q "Mach-O"
    then
        printf "%s\n" "${file_path}" >> "${macho_list}"
    fi
done

find "${work_dir}" -type d \( \
    -name "*.app" -o \
    -name "*.vst3" -o \
    -name "*.component" \
\) -print | sort > "${bundle_list}"

macho_count="$(wc -l < "${macho_list}" | tr -d '[:space:]')"
bundle_count="$(wc -l < "${bundle_list}" | tr -d '[:space:]')"

echo "Found ${macho_count} Mach-O file(s)."
echo "Found ${bundle_count} app/plugin bundle(s)."

if [[ "${bundle_count}" -eq 0 ]]
then
    echo
    echo "NOTE: No app/plugin bundles were found."
    echo "NOTE: This archive contains only loose Mach-O files."
    echo "NOTE: ZIP notarization cannot be verified locally by stapler or spctl."
    echo "NOTE: Treat notarization as successful only if notarytool submit returned 'status: Accepted'."
fi

section "Code signature checks"

while IFS= read -r artifact
do
    [[ -z "${artifact}" ]] && continue

    artifact_relative="$(relative_path "${artifact}")"

    echo
    echo "Checking Mach-O: ${artifact_relative}"

    if codesign --verify --strict --verbose=4 "${artifact}" >"${codesign_output}" 2>&1
    then
        pass "codesign: ${artifact_relative}"
    else
        cat "${codesign_output}"
        fail "codesign: ${artifact_relative}"
    fi

    echo "-- linked libraries"
    if ! otool -L "${artifact}"
    then
        fail "otool -L: ${artifact_relative}"
    fi

    echo "-- rpaths"
    if ! otool -l "${artifact}" | awk '
        $1 == "cmd" && $2 == "LC_RPATH" { in_rpath = 1 }
        in_rpath && $1 == "path" { print; in_rpath = 0 }
    '
    then
        fail "otool LC_RPATH: ${artifact_relative}"
    fi
done < "${macho_list}"

section "Bundle checks"

while IFS= read -r bundle
do
    [[ -z "${bundle}" ]] && continue

    bundle_relative="$(relative_path "${bundle}")"

    echo
    echo "Checking bundle: ${bundle_relative}"

    if codesign --verify --deep --strict --verbose=4 "${bundle}" >"${codesign_bundle_output}" 2>&1
    then
        pass "bundle codesign: ${bundle_relative}"
    else
        cat "${codesign_bundle_output}"
        fail "bundle codesign: ${bundle_relative}"
    fi

    if spctl --assess --type execute --verbose=4 "${bundle}" >"${spctl_output}" 2>&1
    then
        cat "${spctl_output}"
        if grep -q "source=Notarized Developer ID" "${spctl_output}"
        then
            pass "Gatekeeper notarized acceptance: ${bundle_relative}"
        else
            pass "spctl accepted, but source was not 'Notarized Developer ID': ${bundle_relative}"
        fi
    else
        cat "${spctl_output}"
        fail "spctl/Gatekeeper assessment: ${bundle_relative}"
    fi

    if xcrun stapler validate "${bundle}" >"${stapler_output}" 2>&1
    then
        cat "${stapler_output}"
        pass "stapled notarization ticket: ${bundle_relative}"
    else
        cat "${stapler_output}"
        warn "no stapled notarization ticket or stapler validation failed: ${bundle_relative}"
    fi
done < "${bundle_list}"

section "Summary"

if [[ "${failures}" -eq 0 ]]
then
    echo "All minimum checks passed."
    exit 0
else
    echo "${failures} check(s) failed."
    exit 1
fi
