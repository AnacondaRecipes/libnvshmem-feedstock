
#!/bin/bash

set -ex

#GPU Arch - anything recent should do but change accordingly if build breaks
SM=89

[[ ${target_platform} == "linux-64" ]] && targetsDir="targets/x86_64-linux"
# https://docs.nvidia.com/cuda/cuda-compiler-driver-nvcc/index.html?highlight=tegra#cross-compilation
[[ ${target_platform} == "linux-aarch64" ]] && targetsDir="targets/sbsa-linux"

if [ -z "${targetsDir+x}" ]; then
    echo "target_platform: ${target_platform} is unknown! targetsDir must be defined!" >&2
    exit 1
fi

# E.g. $CONDA_PREFIX/libexec/gcc/x86_64-conda-linux-gnu/13.3.0/cc1plus
find $CONDA_PREFIX -name cc1plus

GCC_DIR=$(dirname $(find $CONDA_PREFIX -name cc1plus))

export PATH=${GCC_DIR}:$PATH
export LD_LIBRARY_PATH=${GCC_DIR}:$LD_LIBRARY_PATH

# No need for use-linker-plugin optimization, causes compile failure, don't use it for the test
export CXXFLAGS="${CXXFLAGS} -fno-use-linker-plugin"

echo CC =  $CC
echo CXX =  $CXX

# Why NVCC_APPEND_FLAGS?
#
#  NVCC resolves conflicting flags by using the last value. We use NVCC_APPEND_FLAGS
#  to ensure our flags come after those set in the package configuration.
#
#  Reference: https://github.com/AnacondaRecipes/nccl-feedstock/blob/nccl-2.25/recipe/build.sh
#
#  Added flags:
#
#    -std=c++17: GCC 14's libstdc++ headers use C++17 inline variables and built-in traits
#      that NVCC's EDG frontend cannot parse unless host compilation is also C++17.
#      Since package build configuration / tooling almost always have a hardcoded '-std=c++11',
#      addition of this flag produces a harmless warning:
#      "nvcc warning : incompatible redefinition for option 'std', the last value of this option was used"
#
NVCC_MAJOR=$(nvcc --version | grep -oP 'release \K[0-9]+')
echo "NVCC_MAJOR=${NVCC_MAJOR}"
if [[ "${NVCC_MAJOR}" == "12" ]]; then
  export NVCC_APPEND_FLAGS="${NVCC_APPEND_FLAGS} -std=c++17"
fi

cmake -S $PREFIX/share/src/examples \
  -DCMAKE_LIBRARY_PATH=${GCC_DIR} \
  -DCMAKE_C_COMPILER=$CC \
  -DCMAKE_CUDA_COMPILER=$PREFIX/bin/nvcc \
  -DCMAKE_CXX_COMPILER=$CXX \
  -DCMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH;$PREFIX/${targetsDir}/lib/cmake" \
  -DCUDAToolkit_INCLUDE_DIRECTORIES="$PREFIX/include;$PREFIX/${targetsDir}/include" \
  -DNVSHMEM_MPI_SUPPORT=0 \
  -DNVSHMEM_PREFIX=$PREFIX \
  -DCUDA_HOME=$PREFIX \
  -DCMAKE_CUDA_ARCHITECTURES="${SM}"

cmake --build . -j"$(nproc)"
