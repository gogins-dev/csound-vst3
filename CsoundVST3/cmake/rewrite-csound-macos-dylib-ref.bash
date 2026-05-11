#!/usr/bin/env bash
# Rewrite the CsoundLib64 load command to @rpath so the plugin finds a system-installed framework
# (/Library/Frameworks is already on the rpath list from CMake).
set -euo pipefail
bin="${1:?Mach-O path required}"
new="@rpath/CsoundLib64.framework/Versions/Current/CsoundLib64"
old="$(otool -L "${bin}" | awk '/CsoundLib64\.framework.*\/CsoundLib64 \(compatibility/ { print $1; exit }')"
if [[ -z "${old}" || "${old}" == "${new}" ]]
then
    exit 0
fi
exec install_name_tool -change "${old}" "${new}" "${bin}"
