#!/usr/bin/env bash
#
# Gate: install instructions have to work.
#
# Every package in this repo sets `publish_to: none`, so a README that says
#
#     dependencies:
#       coui_flutter: ^0.2.4
#
# cannot resolve — the package is not on pub.dev, and the version is a number
# nobody has updated since. That is the first thing a new consumer runs, and it
# fails before they see a single component.
#
# It went wrong quietly and in three different ways at once: the root README
# said `^0.2.4`, the Korean README said `^0.1.0`, and `packages/coui_web`'s own
# README said `^0.0.4` — while the actual versions were 0.128.1 / 0.127.17.
# Three hand-maintained copies of one fact, none of them right.
#
# What this checks, for each package that is NOT published:
#
#   1. No README offers it as a pub-hosted dependency (`name: ^x.y.z`).
#   2. No README links a pub.dev badge or page for it — a dead badge reads as
#      "this is on pub.dev" before anyone reads the prose underneath.
#
# What this does not check: whether the git URL is reachable. That needs the
# network, and a guard that needs the network is a guard that flakes.

set -euo pipefail

cd "$(dirname "$0")/../../.."

failures=""

# Packages that declare `publish_to: none` — offering these from pub is wrong.
unpublished=()
for pubspec in packages/*/pubspec.yaml; do
  grep -q '^publish_to:[[:space:]]*none' "$pubspec" || continue
  unpublished+=("$(basename "$(dirname "$pubspec")")")
done

if [ ${#unpublished[@]} -eq 0 ]; then
  echo "✔ readme-install gate: no unpublished packages to check."
  exit 0
fi

readmes=$(git ls-files '*README*.md' 2>/dev/null || find . -name 'README*.md' -not -path './.git/*')

for name in "${unpublished[@]}"; do
  # 1. pub-hosted dependency line: `  coui_web: ^0.0.4` / `coui_web: "^0.0.4"`
  hits=$(printf '%s\n' "$readmes" | while IFS= read -r f; do
    [ -f "$f" ] || continue
    grep -nE "^[[:space:]]*${name}:[[:space:]]*[\"']?\^?[0-9]" "$f" \
      | sed "s|^|$f:|" || true
  done)
  if [ -n "$hits" ]; then
    failures+="  $name is \`publish_to: none\` but offered as a pub dependency:"$'\n'
    failures+="$(printf '%s\n' "$hits" | sed 's/^/    /')"$'\n'
  fi

  # 2. pub.dev badge / page link for the same package
  links=$(printf '%s\n' "$readmes" | while IFS= read -r f; do
    [ -f "$f" ] || continue
    grep -nE "img\.shields\.io/pub/[a-z]+/${name}\b|pub\.dev/packages/${name}\b" "$f" \
      | sed "s|^|$f:|" || true
  done)
  if [ -n "$links" ]; then
    failures+="  $name is \`publish_to: none\` but linked as a pub.dev package:"$'\n'
    failures+="$(printf '%s\n' "$links" | sed 's/^/    /')"$'\n'
  fi
done

if [ -n "$failures" ]; then
  echo "✗ readme-install gate failed."
  echo
  printf '%s' "$failures"
  echo
  echo "  Unpublished packages must be offered from git:"
  echo
  echo "      dependencies:"
  echo "        <name>:"
  echo "          git:"
  echo "            url: https://github.com/coco-de/coui.git"
  echo "            path: packages/<name>"
  echo
  echo "  If a package is meant to be published, drop its \`publish_to: none\`"
  echo "  first — then this gate stops applying to it."
  exit 1
fi

echo "✔ readme-install gate passed (${#unpublished[@]} unpublished package(s) checked)."
