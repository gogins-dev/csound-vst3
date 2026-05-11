#!/usr/bin/env bash
set -euo pipefail

archive="${1:?archive path is required}"
enabled="${2:-OFF}"

if [[ "${enabled}" != "ON" ]]
then
    echo "Notarization is disabled."
    exit 0
fi

if [[ ! -f "${archive}" ]]
then
    echo "Archive does not exist: ${archive}"
    exit 1
fi

notary_key_id="${APPLE_NOTARY_KEY_ID:-${APPLE_API_KEY_ID:-}}"
notary_issuer_id="${APPLE_NOTARY_ISSUER_ID:-${APPLE_API_ISSUER_ID:-}}"
notary_key="${APPLE_NOTARY_KEY:-${APPLE_API_KEY_P8_BASE64:-}}"

if [[ -z "${notary_key}" ]]
then
    echo "APPLE_NOTARY_KEY or APPLE_API_KEY_P8_BASE64 is not set."
    exit 1
fi

if [[ -z "${notary_key_id}" ]]
then
    echo "APPLE_NOTARY_KEY_ID or APPLE_API_KEY_ID is not set."
    exit 1
fi

if [[ -z "${notary_issuer_id}" ]]
then
    echo "APPLE_NOTARY_ISSUER_ID or APPLE_API_ISSUER_ID is not set."
    exit 1
fi

key_file="$(mktemp -t "AuthKey_${notary_key_id}.XXXXXX.p8")"

cleanup()
{
    rm -f "${key_file}"
}

trap cleanup EXIT

if [[ -f "${notary_key}" ]]
then
    cp "${notary_key}" "${key_file}"
else
    if ! printf "%s" "${notary_key}" | /usr/bin/base64 --decode > "${key_file}"
    then
        echo "Failed to decode APPLE_NOTARY_KEY or APPLE_API_KEY_P8_BASE64 as base64."
        exit 1
    fi
fi

echo "Submitting ${archive} for notarization."

xcrun notarytool submit "${archive}" \
    --key "${key_file}" \
    --key-id "${notary_key_id}" \
    --issuer "${notary_issuer_id}" \
    --wait

echo "Stapling notarization ticket onto ${archive}"
xcrun stapler staple "${archive}"