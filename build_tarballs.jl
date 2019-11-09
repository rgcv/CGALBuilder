# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

const name = "CGAL"
const version = v"4.14.2"

# Collection of sources required to build CGAL
const sources = [
    "https://github.com/CGAL/cgal.git" => "f8c1f6eb1bb2df3dc29916890cecc90b4246a9b1",
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/benlorenz/boostBuilder/releases/download/v1.71.0-1/build_boost.v1.71.0.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/GMP-v6.1.2-1/build_GMP.v6.1.2.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/MPFR-v4.0.2-1/build_MPFR.v4.0.2.jl",
]

# Bash recipe for building across all platforms
const script = raw"""
## pre-build setup
# exit on error
set -eu

# check c++ standard reported by the compiler
# CGAL uses CMake's try_run to check if it needs to link with Boost.Thread
# depending on the c++ standard supported by the compiler. From c++11 onwards,
# CGAL doesn't require Boost.Thread
__need_boost_thread=1
__cplusplus=$($CXX -x c++ -dM -E - </dev/null | grep __cplusplus | grep -o '[0-9]*')
[ $__cplusplus -ge 201103 ] && __need_boost_thread=0


## configure build
mkdir -p "$WORKSPACE/srcdir/build" && cd "$WORKSPACE/srcdir/build"

CMAKE_FLAGS=(
  ## cmake specific
  -DCMAKE_TOOLCHAIN_FILE="/opt/$target/$target.toolchain"
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_INSTALL_PREFIX="$prefix"
  -DCMAKE_FIND_ROOT_PATH="$prefix"
  ## cgal specific
  -DWITH_CGAL_Core=ON
  -DWITH_CGAL_ImageIO=OFF
  -DWITH_CGAL_Qt5=OFF
  # try_run doesn't like cross-compilation: this is required
  -DCGAL_test_cpp_version_RUN_RES=$__need_boost_thread
  -DCGAL_test_cpp_version_RUN_RES__TRYRUN_OUTPUT=$__cplusplus
)

cmake ${CMAKE_FLAGS[@]} ../cgal*/

## and away we go..
cmake --build . --config Release --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
const platforms = expand_gcc_versions(supported_platforms())

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libCGAL", :libCGAL),
    LibraryProduct(prefix, "libCGAL_Core", :libCGAL_Core),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
