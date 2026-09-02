#!/bin/sh
# Cross-compile msgpack-c for every platform OpenModelica looks in, stage them
# under MessagePack/Resources/Library/<platform>/, and zip a release that the
# OpenModelica package manager can install binaries and all.
#
#   tools/build-release.sh                       # everything the host can build
#   tools/build-release.sh --targets=linux64,wasm32-wasip1
#   tools/build-release.sh --upload --tag=v0.2.0 # also attach it to the release
#
# Every run starts by deleting dist/ and rebuilding. Beside the zip it writes a
# .buildinfo naming the commit, the platforms and the zip's checksum, which is
# what lets release.sh publish a zip built on another machine without rebuilding
# it. A target whose toolchain is missing is
# skipped, and --upload (or --require-complete) then refuses, because replacing
# the release asset with a partial zip takes those platforms away from everyone.
# --allow-missing overrides.
#
# No binary is written into the source tree: the zip is `git archive` of HEAD
# plus the libraries, staged in dist/.
#
# Toolchains, each skipped with a note when it is not installed:
#   linux64        cc
#   linux32        zig cc -target x86-linux-gnu
#   win64 / win32  clang-cl against the Windows headers cargo-xwin downloads
#                  (msgpackc.lib, what an --target=msvc build links), plus a
#                  MinGW-ABI libmsgpackc.a from zig, which is what OMDev's
#                  default gcc resolves `-lmsgpackc` to
#   darwin64       zig cc -target {x86_64,aarch64}-macos, the two lipo'd into one
#                  universal archive, so Intel and Apple Silicon are both covered
#   wasm32-wasip1  the toolchain file OpenModelica installs
# zig is used as `zig` or as the `ziglang` Python package; the xwin cache is
# ~/.cache/cargo-xwin/xwin unless XWIN_CACHE says otherwise (`cargo xwin` or
# `xwin splat` puts it there; --arch x86 is needed for a 32-bit build).

set -eu

LIB=MessagePack
ALL_TARGETS="linux64 linux32 win64 win32 darwin64 wasm32-wasip1"

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD=${BUILD_DIR:-$ROOT/build-binaries}
DIST=${DIST_DIR:-$ROOT/dist}
CMAKE_PROJECT=$ROOT/$LIB/Resources/BuildProjects/CMake
MACOS_SDK=${MACOS_SDK:-}
XWIN_CACHE=${XWIN_CACHE:-$HOME/.cache/cargo-xwin/xwin}
OMHOME=${OPENMODELICAHOME:-}
WASI_SYSROOT=${WASI_SYSROOT:-}

targets=$ALL_TARGETS
upload=no
allow_missing=no
require_complete=no
tag=
built=
missing=

for arg do
  case $arg in
    --targets=*) targets=$(echo "${arg#--targets=}" | tr ',' ' ') ;;
    --upload) upload=yes ;;
    --allow-missing) allow_missing=yes ;;
    --require-complete) require_complete=yes ;;
    --tag=*) tag=${arg#--tag=} ;;
    --macos-sdk=*) MACOS_SDK=${arg#--macos-sdk=} ;;
    --xwin-cache=*) XWIN_CACHE=${arg#--xwin-cache=} ;;
    --omc-home=*) OMHOME=${arg#--omc-home=} ;;
    --wasi-sysroot=*) WASI_SYSROOT=${arg#--wasi-sysroot=} ;;
    -h|--help) sed -n '2,29p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "$0: unknown argument $arg" >&2; exit 2 ;;
  esac
done

version=$(sed -n 's/.*annotation(version="\([^"]*\)".*/\1/p' "$ROOT/$LIB/package.mo" | head -1)
[ -n "$version" ] || { echo "$0: cannot read the version from $LIB/package.mo" >&2; exit 1; }
[ -n "$tag" ] || tag=v$version

note() { echo "== $*"; }
skip() { echo "-- skipping $1: $2"; missing="$missing $1"; }

# ---------------------------------------------------------------- zig wrappers
# CMAKE_C_COMPILER is one word, and zig may only be there as a Python module.
zig=
zig_ready=no
setup_zig() {
  [ "$zig_ready" = no ] || return 0
  if command -v zig >/dev/null 2>&1; then
    zig=zig
  elif python3 -m ziglang version >/dev/null 2>&1; then
    zig="python3 -m ziglang"
  else
    return 1
  fi
  mkdir -p "$BUILD/bin"
  for tool in cc ar ranlib; do
    printf '#!/bin/sh\nexec %s %s "$@"\n' "$zig" "$tool" > "$BUILD/bin/zig-$tool"
    chmod +x "$BUILD/bin/zig-$tool"
  done
  zig_ready=yes
}

# write_toolchain <file> <system> <compiler> <ar> <ranlib> <flags>
write_toolchain() {
  cat > "$1" <<EOF
set(CMAKE_SYSTEM_NAME $2)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_C_COMPILER "$3")
set(CMAKE_AR "$4" CACHE FILEPATH "")
set(CMAKE_RANLIB "$5" CACHE FILEPATH "")
set(CMAKE_C_FLAGS_INIT "$6")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
EOF
}

# build <target> <toolchain-file> [extra cmake args...]
# sh has no local variables, so every helper uses its own prefix.
build() {
  _bt=$1; _btc=$2; shift 2
  _bd=$BUILD/$_bt
  rm -rf "$_bd"
  mkdir -p "$_bd"
  ( cd "$_bd" && cmake -DCMAKE_BUILD_TYPE=Release \
      "-DCMAKE_TOOLCHAIN_FILE=$_btc" \
      "-DCMAKE_INSTALL_PREFIX=$DIST/$LIB/Resources/Library/$_bt" \
      -DCMAKE_INSTALL_LIBDIR=. "$@" "$CMAKE_PROJECT" >build.log 2>&1 \
    && cmake --build . >>build.log 2>&1 \
    && cmake --build . --target install >>build.log 2>&1 ) \
    || { echo "-- $_bt FAILED, see $_bd/build.log" >&2; tail -20 "$_bd/build.log" >&2; return 1; }
  case $_bt in
    *-msvc|*-mingw|darwin64-*) ;;
    *) note "$_bt: $(ls "$DIST/$LIB/Resources/Library/$_bt")"; built="$built $_bt" ;;
  esac
}

build_zig() {  # <target> <system> <zig target> [extra flags]
  _zg=$1; _zsys=$2; _zt=$3; _zextra=${4:-}
  setup_zig || { skip "$_zg" "no zig (install it, or pip install ziglang)"; return 0; }
  write_toolchain "$BUILD/$_zg.cmake" "$_zsys" "$BUILD/bin/zig-cc" \
    "$BUILD/bin/zig-ar" "$BUILD/bin/zig-ranlib" "-target $_zt -O2 $_zextra"
  build "$_zg" "$BUILD/$_zg.cmake"
}

build_linux64() {
  command -v cc >/dev/null 2>&1 || { skip linux64 "no cc"; return 0; }
  write_toolchain "$BUILD/linux64.cmake" Linux cc ar ranlib "-O2"
  build linux64 "$BUILD/linux64.cmake"
}

# Windows gets both ABIs, because omc can use either: `--target=msvc` links
# `msgpackc.lib`, while OMDev's default gcc resolves `-lmsgpackc` to
# `libmsgpackc.a`. The MSVC half is clang-cl against the CRT and SDK headers
# cargo-xwin downloads — no MinGW install and no Wine; the MinGW half is zig,
# which carries the mingw-w64 headers and import libraries.
build_windows() {  # <target> <xwin arch> <clang target> <zig target>
  _wt=$1
  build_windows_msvc "$1" "$2" "$3"
  build_windows_mingw "$1" "$4"
  [ -d "$DIST/$LIB/Resources/Library/$_wt" ] || skip "$_wt" "neither ABI could be built"
}

# Moves what one ABI produced into the platform directory the other shares.
take_windows_lib() {  # <target> <suffix> <file>
  mkdir -p "$DIST/$LIB/Resources/Library/$1"
  mv "$DIST/$LIB/Resources/Library/$1-$2/$3" "$DIST/$LIB/Resources/Library/$1/$3"
  rm -rf "$DIST/$LIB/Resources/Library/$1-$2"
  note "$1: $3 ($2)"
  case " $built " in *" $1 "*) ;; *) built="$built $1" ;; esac
}

build_windows_msvc() {
  _mt=$1; _march=$2; _mtriple=$3
  command -v clang-cl >/dev/null 2>&1 || { skip "$_mt (msvc)" "no clang-cl"; return 0; }
  _mlib=$(command -v llvm-lib || ls /usr/bin/llvm-lib-* 2>/dev/null | sort -V | tail -1 || true)
  [ -n "$_mlib" ] || { skip "$_mt (msvc)" "no llvm-lib"; return 0; }
  [ -d "$XWIN_CACHE/crt/lib/$_march" ] || {
    skip "$_mt (msvc)" "no $_march libraries in $XWIN_CACHE (xwin --arch $_march splat)"
    return 0
  }
  _minc="/imsvc $XWIN_CACHE/crt/include /imsvc $XWIN_CACHE/sdk/include/ucrt"
  _minc="$_minc /imsvc $XWIN_CACHE/sdk/include/um /imsvc $XWIN_CACHE/sdk/include/shared"
  write_toolchain "$BUILD/$_mt-msvc.cmake" Windows clang-cl "$_mlib" : \
    "--target=$_mtriple $_minc -O2"
  build "$_mt-msvc" "$BUILD/$_mt-msvc.cmake" || return 1
  take_windows_lib "$_mt" msvc msgpackc.lib
}

build_windows_mingw() {
  _gt=$1; _gzt=$2
  setup_zig || { skip "$_gt (mingw)" "no zig (install it, or pip install ziglang)"; return 0; }
  write_toolchain "$BUILD/$_gt-mingw.cmake" Windows "$BUILD/bin/zig-cc" \
    "$BUILD/bin/zig-ar" "$BUILD/bin/zig-ranlib" "-target $_gzt -O2"
  build "$_gt-mingw" "$BUILD/$_gt-mingw.cmake" || return 1
  take_windows_lib "$_gt" mingw libmsgpackc.a
}

build_darwin64() {
  setup_zig || { skip darwin64 "no zig (install it, or pip install ziglang)"; return 0; }
  _dsdk=
  if [ -n "$MACOS_SDK" ]; then
    _dsdk="--sysroot $MACOS_SDK -iframework $MACOS_SDK/System/Library/Frameworks"
  fi
  _lipo=$(command -v llvm-lipo || ls /usr/bin/llvm-lipo-* 2>/dev/null | sort -V | tail -1 || true)
  for _darch in x86_64 aarch64; do
    write_toolchain "$BUILD/darwin64-$_darch.cmake" Darwin "$BUILD/bin/zig-cc" \
      "$BUILD/bin/zig-ar" "$BUILD/bin/zig-ranlib" "-target $_darch-macos -O2 $_dsdk"
    build "darwin64-$_darch" "$BUILD/darwin64-$_darch.cmake" || return 1
  done
  mkdir -p "$DIST/$LIB/Resources/Library/darwin64"
  if [ -n "$_lipo" ]; then
    "$_lipo" -create -output "$DIST/$LIB/Resources/Library/darwin64/libmsgpackc.a" \
      "$DIST/$LIB/Resources/Library/darwin64-x86_64/libmsgpackc.a" \
      "$DIST/$LIB/Resources/Library/darwin64-aarch64/libmsgpackc.a"
    note "darwin64: universal libmsgpackc.a ($("$_lipo" -archs "$DIST/$LIB/Resources/Library/darwin64/libmsgpackc.a"))"
    built="$built darwin64"
  else
    cp "$DIST/$LIB/Resources/Library/darwin64-x86_64/libmsgpackc.a" \
       "$DIST/$LIB/Resources/Library/darwin64/libmsgpackc.a"
    echo "-- darwin64: no llvm-lipo, shipping x86_64 only" >&2
    missing="$missing darwin64-arm64"
  fi
  rm -rf "$DIST/$LIB/Resources/Library/darwin64-x86_64" \
         "$DIST/$LIB/Resources/Library/darwin64-aarch64"
}

build_wasm() {
  _wtc=
  if [ -z "$OMHOME" ] && command -v omc >/dev/null 2>&1; then
    OMHOME=$(dirname "$(dirname "$(command -v omc)")")
  fi
  [ -n "$OMHOME" ] && _wtc=$OMHOME/share/omc/cmake/wasm32-wasip1.cmake
  if [ -z "$_wtc" ] || [ ! -f "$_wtc" ]; then
    skip wasm32-wasip1 "no OpenModelica wasm toolchain file (set OPENMODELICAHOME or --omc-home)"
    return 0
  fi
  _wargs=""
  [ -n "$WASI_SYSROOT" ] && _wargs="-DOMC_WASI_SYSROOT=$WASI_SYSROOT"
  # A wasm target loads a module; the others link an archive.
  build wasm32-wasip1 "$_wtc" -DBUILD_SHARED_LIBS=ON $_wargs
}

# ------------------------------------------------------------------- staging
rm -rf "$DIST"
mkdir -p "$DIST" "$BUILD"
commit=$(cd "$ROOT" && git rev-parse HEAD)
note "staging $LIB $version from HEAD ($(echo "$commit" | cut -c1-8))"
( cd "$ROOT" && git archive --format=tar HEAD "$LIB" ) | ( cd "$DIST" && tar x )

for t in $targets; do
  case $t in
    linux64)       build_linux64 ;;
    linux32)       build_zig linux32 Linux x86-linux-gnu ;;
    win64)         build_windows win64 x86_64 x86_64-pc-windows-msvc x86_64-windows-gnu ;;
    win32)         build_windows win32 x86 i686-pc-windows-msvc x86-windows-gnu ;;
    darwin64)      build_darwin64 ;;
    wasm32-wasip1) build_wasm ;;
    *) echo "$0: unknown target $t (have: $ALL_TARGETS)" >&2; exit 2 ;;
  esac
done

zipfile=$DIST/$LIB-$version.zip
rm -f "$zipfile"
( cd "$DIST" && zip -qr "$zipfile" "$LIB" )
note "wrote $zipfile"
unzip -l "$zipfile" | grep -E "Resources/Library/.*/" || true

built=$(echo $built)
note "built:  ${built:- (nothing)}"

# A target the host cannot build and a target that was never asked for leave the
# same hole in the zip, so completeness is judged against every platform.
if [ "$upload" = yes ] || [ "$require_complete" = yes ]; then
  missing=
  for t in $ALL_TARGETS; do
    case " $built " in *" $t "*) ;; *) missing="$missing $t" ;; esac
  done
fi
[ -z "$missing" ] || note "MISSING:$missing"

# What the zip is, for a release run that did not build it: the commit it came
# from, the platforms in it, and a checksum tying the two together.
complete=yes
for t in $ALL_TARGETS; do
  case " $built " in *" $t "*) ;; *) complete=no ;; esac
done
cat > "$zipfile.buildinfo" <<EOF
library=$LIB
version=$version
commit=$commit
targets=$built
complete=$complete
sha256=$(sha256sum "$zipfile" | cut -d' ' -f1)
built=$(date -u +%Y-%m-%dT%H:%M:%SZ)
builder=$(uname -sm), $(hostname)
EOF
note "wrote $zipfile.buildinfo"

if { [ "$upload" = yes ] || [ "$require_complete" = yes ]; } &&
   [ -n "$missing" ] && [ "$allow_missing" = no ]; then
  cat >&2 <<EOF

$0: this zip is missing:$missing

The release asset is what the package manager installs instead of the source
tree, so publishing an incomplete one takes those platforms away from everyone.
Either build the missing ones here, or build the zip on a host that can and
upload it by hand:

    gh release upload $tag <the complete zip> --clobber

Pass --allow-missing if you really do mean to publish a partial release.
EOF
  exit 1
fi

if [ "$upload" = yes ]; then
  command -v gh >/dev/null 2>&1 || { echo "$0: --upload needs the gh CLI" >&2; exit 1; }
  note "attaching $(basename "$zipfile") to release $tag"
  gh release view "$tag" >/dev/null 2>&1 || gh release create "$tag" --title "$tag" --notes "$LIB $version"
  gh release upload "$tag" "$zipfile" --clobber
fi
