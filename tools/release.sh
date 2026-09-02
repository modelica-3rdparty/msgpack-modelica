#!/bin/sh
# Release MessagePack in one command: build every platform's binaries, push the
# branch, tag it, and attach the zip to a GitHub release.
#
#   tools/release.sh --dry-run     # do everything except push/tag/upload
#   tools/release.sh               # asks before it touches the remote
#   tools/release.sh --yes         # for CI
#   tools/release.sh --no-build    # publish a zip somebody else built
#
# The version comes from MessagePack/package.mo; the tag is v<version> unless
# --tag says otherwise. Options not listed here are passed to build-release.sh
# (--omc-home=, --macos-sdk=, --xwin-cache=, --wasi-sysroot=, --allow-missing).
#
# The binaries need a row of cross-toolchains, which the person cutting the
# release need not have: one machine runs build-release.sh, and the zip and its
# .buildinfo are handed to another, which publishes them with --no-build. An
# existing zip is reused automatically when its .buildinfo says it was built
# from this very commit and carries every platform; --rebuild forces the build
# anyway, --no-build forbids it.
#
# Nothing reaches the remote until the binaries are there, because a release
# whose asset is missing platforms is worse than no release: the package manager
# installs the asset instead of the source tree.

set -eu

LIB=MessagePack
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

remote=origin
branch=
tag=
assume_yes=no
dry_run=no
build=auto
build_args=

for arg do
  case $arg in
    --remote=*) remote=${arg#--remote=} ;;
    --branch=*) branch=${arg#--branch=} ;;
    --tag=*) tag=${arg#--tag=} ;;
    -y|--yes) assume_yes=yes ;;
    -n|--dry-run) dry_run=yes ;;
    --no-build) build=never ;;
    --rebuild) build=always ;;
    -h|--help) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --*) build_args="$build_args $arg" ;;
    *) echo "$0: unknown argument $arg" >&2; exit 2 ;;
  esac
done

die() { echo "$0: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

# --------------------------------------------------------------- sanity checks
step "checking the working tree"
git rev-parse --git-dir >/dev/null 2>&1 || die "not a git repository"
git diff --quiet && git diff --cached --quiet ||
  die "the working tree has uncommitted changes; the zip is built from HEAD, so commit or stash first"

[ -n "$branch" ] || branch=$(git rev-parse --abbrev-ref HEAD)
[ "$branch" != HEAD ] || die "detached HEAD; pass --branch"

version=$(sed -n 's/.*annotation(version="\([^"]*\)".*/\1/p' "$LIB/package.mo" | head -1)
[ -n "$version" ] || die "cannot read the version from $LIB/package.mo"
[ -n "$tag" ] || tag=v$version
[ "$tag" = "v$version" ] ||
  die "tag $tag does not match version $version in $LIB/package.mo; change one of them"

git rev-parse -q --verify "refs/tags/$tag" >/dev/null &&
  die "tag $tag already exists locally; delete it or bump the version"
git ls-remote --exit-code --tags "$remote" "$tag" >/dev/null 2>&1 &&
  die "tag $tag already exists on $remote; bump the version"

command -v gh >/dev/null 2>&1 || die "the gh CLI is needed to create the release"
gh auth status >/dev/null 2>&1 || die "gh is not logged in (gh auth login)"

echo "  $LIB $version, tag $tag, $branch -> $remote, $(git rev-parse --short HEAD)"

# ----------------------------------------------------------------------- build
zipfile=$ROOT/dist/$LIB-$version.zip
info=$zipfile.buildinfo
head_sha=$(git rev-parse HEAD)

# Why the zip on disk cannot be published as it is; empty when it can.
stale_reason() {
  [ -f "$zipfile" ] || { echo "no $zipfile"; return; }
  [ -f "$info" ] || { echo "no $(basename "$info") beside it"; return; }
  _got=$(sed -n 's/^commit=//p' "$info")
  [ "$_got" = "$head_sha" ] ||
    { echo "built from ${_got:-?}, HEAD is $head_sha"; return; }
  [ "$(sed -n 's/^version=//p' "$info")" = "$version" ] ||
    { echo "built for version $(sed -n 's/^version=//p' "$info")"; return; }
  [ "$(sed -n 's/^complete=//p' "$info")" = yes ] ||
    { echo "missing platforms (has: $(sed -n 's/^targets=//p' "$info"))"; return; }
  [ "$(sha256sum "$zipfile" | cut -d' ' -f1)" = "$(sed -n 's/^sha256=//p' "$info")" ] ||
    { echo "the zip does not match its recorded checksum"; return; }
}

stale=$(stale_reason)
case $build in
  never)
    [ -z "$stale" ] || die "--no-build, but the zip cannot be published: $stale"
    step "using the prebuilt zip"
    ;;
  auto)
    if [ -z "$stale" ]; then
      step "using the prebuilt zip"
    else
      step "building the binaries ($stale)"
      build=always
    fi
    ;;
  always) step "rebuilding the binaries" ;;
esac

if [ "$build" = always ]; then
  # --require-complete: a zip missing a platform must not become a release,
  # whether the toolchain was absent or the target simply was not asked for.
  # shellcheck disable=SC2086
  "$ROOT/tools/build-release.sh" --require-complete $build_args
  [ -f "$zipfile" ] || die "$zipfile was not produced"
  stale=$(stale_reason)
  [ -z "$stale" ] || die "the build did not produce a publishable zip: $stale"
fi
echo "  $(basename "$zipfile"), $(sed -n 's/^targets=/platforms: /p' "$info")"
echo "  built $(sed -n 's/^built=//p' "$info") on $(sed -n 's/^builder=//p' "$info")"

# ------------------------------------------------------------------- confirm
step "ready to publish"
cat <<EOF
  git push $remote $branch
  git tag -a $tag && git push $remote $tag
  gh release create $tag  (if it does not exist)
  gh release upload $tag $(basename "$zipfile") --clobber
EOF

if [ "$dry_run" = yes ]; then
  echo; echo "-- dry run, stopping here. The zip is at $zipfile"
  exit 0
fi
if [ "$assume_yes" = no ]; then
  [ -t 0 ] || die "not a terminal; pass --yes to publish non-interactively"
  printf "\nPublish? [y/N] "
  read -r reply
  case $reply in y|Y|yes|YES) ;; *) die "aborted" ;; esac
fi

# ----------------------------------------------------------------------- push
step "pushing $branch to $remote"
git push "$remote" "$branch"

step "tagging $tag"
git tag -a "$tag" -m "$LIB $version"
git push "$remote" "$tag"

step "publishing the release"
gh release view "$tag" >/dev/null 2>&1 ||
  gh release create "$tag" --title "$LIB $version" --generate-notes
gh release upload "$tag" "$zipfile" --clobber

url=$(gh release view "$tag" --json url -q .url 2>/dev/null || echo "")
step "done${url:+ — $url}"
cat <<EOF

Register the asset with the OpenModelica package manager so it installs the
binaries instead of the source tree — in OMPackageManager/repos.json, under
"MessagePack":

  "zipfiles": {
    "$version": "https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/download/$tag/$LIB-$version.zip"
  }
EOF
