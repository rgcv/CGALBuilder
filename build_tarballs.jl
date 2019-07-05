# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

const name = "CGAL"
const version = v"4.14"

# Collection of sources required to build CGAL
const sources = [
    "https://github.com/CGAL/cgal.git" => "bf86a541522982ea042f0787ad75476556858496",
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/benlorenz/boostBuilder/releases/download/v1.69.0/build_boost.v1.69.0.jl",
    "https://github.com/JuliaMath/GMPBuilder/releases/download/v6.1.2-2/build_GMP.v6.1.2.jl",
    "https://github.com/JuliaMath/MPFRBuilder/releases/download/v4.0.1-3/build_MPFR.v4.0.1.jl",
]

# Bash recipe for building across all platforms
const script = raw"""#!/bin/bash
mkdir -p "$WORKSPACE/srcdir/build" && cd "$WORKSPACE/srcdir/build"

declare -A ARGS
## cmake specific
ARGS+=([CMAKE_BUILD_TYPE]=Release)
ARGS+=([CMAKE_INSTALL_PREFIX]="$prefix")
ARGS+=([CMAKE_TOOLCHAIN_FILE]="/opt/$target/$target.toolchain")
ARGS+=([CMAKE_CXX_STANDARD]=11)
## cgal specific
ARGS+=([WITH_CGAL_Core]=ON)
ARGS+=([WITH_CGAL_ImageIO]=OFF)
ARGS+=([WITH_CGAL_Qt5]=OFF)
# try_run doesn't like cross-compilation: these are required
ARGS+=([CGAL_test_cpp_version_RUN_RES]=0)
ARGS+=([CGAL_test_cpp_version_RUN_RES__TRYRUN_OUTPUT]="201103")

# CGAL_Core's CMakeLists includes the latter path.. dirty hack
ln -sf "$prefix/include" "/opt/$target/$target/sys-root/usr/local/include"

for arg in "${!ARGS[@]}"; do
  echo "-D$arg=${ARGS[$arg]}"
done | xargs cmake ../cgal

cmake --build . --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = []
const _oss = (Linux, MacOS, Windows)
const _archs = (:x86_64, :i686)
for os in _oss
    for arch in _archs
        os == MacOS && arch !== :x86_64 && continue
        push!(platforms, os(arch))
    end
end

# The products that we will ensure are always built
const _lib  = Symbol(:lib, name)
const _libs = (:Core,)
products(prefix) = [
    LibraryProduct(prefix, "$_lib", _lib),
    map(lib -> LibraryProduct(prefix, "$(_lib)_$lib", lib), _libs)...
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
