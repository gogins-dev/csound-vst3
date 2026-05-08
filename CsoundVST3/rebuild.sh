#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "$(uname -s)" in
    Darwin)
        "${script_dir}/clean-build-macos.bash" "$@"
        ;;
    Linux)
        "${script_dir}/clean-build-linux.bash" "$@"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        "${script_dir}/clean-build-windows.bash" Release "$@"
        ;;
    *)
        echo "Unsupported platform: $(uname -s)" >&2
        exit 1
        ;;
esac
