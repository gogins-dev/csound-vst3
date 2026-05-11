#!/bin/bash
# Re-sign a .app / .vst3 / .component after link (entitlements for Homebrew-linked Csound deps).
# Always ad hoc ("-") so incremental builds do not require a Developer ID keychain.
set -eu
bundle="${1:?bundle path}"
entitlements="${2:?entitlements path}"
deep_flag="${3:-}"
if [[ "${deep_flag}" == "--deep" ]]
then
    exec /usr/bin/codesign --force --sign - --deep --entitlements "${entitlements}" "${bundle}"
fi
exec /usr/bin/codesign --force --sign - --entitlements "${entitlements}" "${bundle}"
