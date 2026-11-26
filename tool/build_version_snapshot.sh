#!/usr/bin/env bash
# build_version_snapshot.sh — builds a full docs_site snapshot at a git tag
# and archives it under docs_site/build/jaspr/versions/{tag}/ in the
# CURRENT checkout, then records the version in
# docs_core/content/_data/versions.json.
#
# WHY: CoUI ships from git tags, not pub.dev (publish_to: none), so a
# consumer pinned to an older `ref:` has no pub.dev version dropdown to
# find matching docs for (#3564/#3587). Each snapshot is a real, separate
# `jaspr build` run against that tag's own docs_core/coui_flutter/coui_web
# source — not a filtered view of today's docs — so it reflects the API
# surface that actually existed at that release.
#
# Usage:
#   ./tool/build_version_snapshot.sh {tag}
#   ./tool/build_version_snapshot.sh coui_flutter-v0.128.1
#
# Run from the repository root, on a clean working tree (the script does
# not touch your current checkout's git state — it builds the tag in a
# separate `git worktree` and only ever *adds* files under
# docs_site/build/jaspr/versions/{tag}/ plus the manifest entry).
#
# This intentionally does not attempt to backfill CoUI's full tag history
# (500+ tags as of writing) — building every historical release would
# make each deploy prohibitively slow, and most of those tags predate a
# toolchain (Flutter/jaspr_cli version) old enough that a modern build may
# not even reproduce them faithfully. The archive grows forward from
# whichever tags a maintainer chooses to snapshot (typically: notable
# releases going forward), same as most versioned-docs tools' "start
# tracking from here" convention.
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 {tag}" >&2
  exit 64
fi
tag="$1"

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if ! git rev-parse "refs/tags/${tag}" >/dev/null 2>&1; then
  echo "error: tag '${tag}' does not exist in this checkout (try 'git fetch --tags')." >&2
  exit 1
fi

date="$(git log -1 --format=%cs "refs/tags/${tag}")"
# `label` drops a leading "{component}-v" (e.g. coui_flutter-v0.128.1 ->
# 0.128.1) for the switcher's display text — falls back to the full tag
# for tags that don't follow that shape (pre-`include-component-in-tag`
# tags like `v0.98.17`).
label="$(printf '%s' "$tag" | sed -E 's/^[a-z_]+-v//')"
if [ "$label" = "$tag" ]; then
  label="$(printf '%s' "$tag" | sed -E 's/^v//')"
fi

worktree_dir="$(mktemp -d)/coui-snapshot-${tag//\//_}"
echo "→ checking out ${tag} into ${worktree_dir}"
git worktree add --detach "$worktree_dir" "refs/tags/${tag}" >/dev/null
cleanup() {
  echo "→ removing worktree ${worktree_dir}"
  git worktree remove --force "$worktree_dir" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Same recipe as .github/workflows/deploy.yaml's build-docs job — kept in
# lockstep deliberately (not re-derived) so a snapshot build behaves
# exactly like a normal deploy build, just at an older ref.
(
  cd "$worktree_dir/docs_site"
  echo "→ dart pub get"
  dart pub get
  echo "→ flutter pub get"
  flutter pub get
  echo "→ jaspr build"
  jaspr build
  if [ -d build/flutter ]; then
    cp -n build/flutter/main.dart.js build/jaspr/main.dart.js 2>/dev/null || true
    cp -n build/flutter/flutter.js build/jaspr/flutter.js 2>/dev/null || true
  fi
)

built_output="$worktree_dir/docs_site/build/jaspr"
if [ ! -f "$built_output/index.html" ]; then
  echo "error: ${built_output}/index.html missing — build did not produce a usable site." >&2
  exit 1
fi

dest="docs_site/build/jaspr/versions/${tag}"
echo "→ copying build output to ${dest}"
mkdir -p "$dest"
cp -R "$built_output/." "$dest/"

echo "→ recording ${tag} (${label}, ${date}) in docs_core/content/_data/versions.json"
(cd docs_core && dart run bin/record_version_snapshot.dart "$tag" "$label" "$date")

echo "✓ snapshot ready at ${dest}"
echo "  Commit docs_core/content/_data/versions.json and re-run the docs-site"
echo "  build so VersionSwitcher picks up the new entry, then include"
echo "  ${dest} in the deploy artifact under versions/${tag}/."
