#!/bin/bash
set -euo pipefail

echo "Installing for developer to ~...."
cmake --install build --config Release --prefix ~