#!/usr/bin/env bash
set -ex

echo "CUDA compiler version: $cuda_compiler_version"

# Disable the GCC linker plugin on the cross-compiled linux-aarch64 build: the
# cross-compiler's liblto_plugin.so cannot be loaded by the linker
# (ld: .../liblto_plugin.so: cannot open shared object file). LTO is not used
# here, so dropping the plugin is a no-op on the produced binary. linux-64 links
# fine, so leave it untouched. Same workaround as compile_perf_test.sh.
if [[ "${target_platform}" == "linux-aarch64" ]]; then
  export CFLAGS="${CFLAGS} -fno-use-linker-plugin"
  export CXXFLAGS="${CXXFLAGS} -fno-use-linker-plugin"
  export LDFLAGS="${LDFLAGS} -fno-use-linker-plugin"
fi

cd nvshmem4py/

$PYTHON -m pip install --no-deps --no-build-isolation -vvv .
