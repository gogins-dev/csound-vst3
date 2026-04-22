#!/bin/bash
set -euo pipefail

rm -rf build
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release

sudo cmake --install build --config Release --prefix / --component CsoundVST3_Runtime
sudo cmake --install build --config Release --prefix / --component CsoundVST3_Signing