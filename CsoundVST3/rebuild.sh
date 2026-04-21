#!/bin/bash
set -euo pipefail

rm -rf build
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release