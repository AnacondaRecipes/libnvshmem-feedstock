#!/usr/bin/env bash
set -ex

echo "CUDA compiler version: $cuda_compiler_version"

cd nvshmem4py/

$PYTHON -m pip install --no-deps --no-build-isolation -vvv .
