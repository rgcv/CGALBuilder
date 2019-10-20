# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

const name = "CGAL"
const version = v"4.14.1"

# Collection of sources required to build CGAL
const sources = [
    "https://github.com/CGAL/cgal.git" => "f19ad523e473030c83a6457b9748387980fdc121",
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/benlorenz/boostBuilder/releases/download/v1.69.0/build_boost.v1.69.0.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/GMP-v6.1.2-1/build_GMP.v6.1.2.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/MPFR-v4.0.2-1/build_MPFR.v4.0.2.jl",
]

# Bash recipe for building across all platforms
const script = raw"""
## pre-build setup
# exit on error
set -eu
# HACK: cmake v3.11 can't properly find Boost beyond 1.67.. here, we install a
# version of cmake that recognizes Boost at least up to v1.69 (3.13.0)
apk del cmake
apk add cmake --repository http://dl-cdn.alpinelinux.org/alpine/v3.9/main

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
