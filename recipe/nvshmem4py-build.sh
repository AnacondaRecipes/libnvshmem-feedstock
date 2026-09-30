#!/usr/bin/env bash
set -ex

echo "CUDA compiler version: $cuda_compiler_version"

cd nvshmem4py/

# setuptools_scm cannot infer a version from the source archive (no git); pin
# it so wheel metadata matches the conda package version instead of 0.0.0
export SETUPTOOLS_SCM_PRETEND_VERSION="${PKG_VERSION}"

$PYTHON -m pip install --no-deps --no-build-isolation -vvv .
