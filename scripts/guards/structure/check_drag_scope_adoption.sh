#!/usr/bin/env bash
#
# Gate: a shipped Web component hands its own root to the drag scope.
#
# The Flutter `DragScope` builds an inherited marker, which owns no render
# object — wrapping a subtree in a scope there cannot move anything. The
# Web scope has no such thing to build: it needs an element to hang an id
# on, and unless the caller names one it renders a `<div>` of its own. That
# div is a real box, and it lands between the caller's component and its
# own root.
#
# A box in that position is invisible until the layout crossing it says
# something about its parent, and then it is silently wrong:
#
#   - a percentage height (`h-full`) resolves against `auto`, and a root
#     whose children are all absolutely positioned makes `auto` zero — the
#     component renders at zero height with no error anywhere (#3829,
#     DraggablePanel);
#   - a flex `gap` only separates the children its container owns, so rows
#     collected under one wrapper touch while the container still reports
#     the gap that a resolver-level test would read back as correct
#     (#3786, Sortable).
#
# Both were found by looking at the page, months apart, with every test
# green. The mechanism that avoids it already exists — `originElementId`
# adopts an element the caller already renders and the scope then renders
# nothing — and a shipped component always has a root to offer, so there
# is no case where taking the default is the right call.
#
# Scope is the shipped Web library. Application and example code composes
# a scope around markup it wrote itself and can see; the definition file
# names the parameter and shows the plain form in its own doc examples.

set -euo pipefail

cd "$(dirname "$0")/../../.."

# How far past the constructor to look. Both call sites name the parameter
# within two lines; the allowance is for a comment above it.
readonly lookahead=10

offenders=$(
  grep -rl 'DragScope(' packages/coui_web/lib --include='*.dart' |
    grep -v 'infra/drag_scope/drag_scope.dart' |
    while read -r file; do
      awk -v lookahead="$lookahead" '
        { line[FNR] = $0 }
        END {
          for (i = 1; i <= FNR; i++) {
            if (line[i] ~ /^[[:space:]]*\/\//) continue
            if (line[i] !~ /DragScope\(/) continue

            adopted = 0
            for (j = i; j <= i + lookahead && j <= FNR; j++) {
              if (line[j] ~ /originElementId:/) { adopted = 1; break }
            }
            if (!adopted) printf "%s:%d:%s\n", FILENAME, i, line[i]
          }
        }
      ' "$file"
    done || true
)

if [ -n "$offenders" ]; then
  echo "A shipped Web component lets the drag scope render its own box."
  echo
  printf '%s\n' "$offenders"
  echo
  echo "Pass originElementId: <the id already on this component's root>."
  echo "The scope then renders nothing, and the component's own layout"
  echo "reaches its parent unchanged — the shape the Flutter twin has."
  exit 1
fi

echo "✅ every shipped Web drag scope adopts a caller element"
