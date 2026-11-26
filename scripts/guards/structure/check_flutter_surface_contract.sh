#!/usr/bin/env bash
#
# Web's surface contract is enforced; Flutter's was kept by hand.
#
#   $ bash scripts/guards/structure/check_surface_fill_contract.sh
#   ✔ 9 surface(s) both marked and publishing their fill …
#
# There was no Flutter equivalent. The components wrapping `SurfaceBlur`
# were wrapping it because a person did that, and removing one turned
# nothing red. This guard is that missing half.
#
# THE CONTRACT IS FOUR PARTS, AND ALL FOUR HAVE TO BE THERE
#
#   1. the resolver reads the material off the theme
#        without it the axis never reaches this component at all
#   2. the widget wraps its panel in `SurfaceBlur`
#        without it the resolver settles values nothing draws
#   3. the fill folds `theme.surfaceOpacity`
#        without it the blur is painted and then covered
#   4. the wrapper is handed `refraction`
#        without it the surface frosts but never bends
#
# The third is the one that goes missing, and it is the one that costs
# the most, because the other two look done: the axis is read, the
# wrapper is there, and the panel renders exactly as opaque as before.
# A blur behind an opaque fill is invisible. The material is the pair.
#
# It was missing in three of the eight when this guard was written.
#
# The fourth conjunct was added later, for the same failure one rung
# further out. `CoreSurfaceRefraction`'s own doc records that nothing in
# the kit passed a refraction to anything, so the shipped glass had every
# term except the one it is named for. That was fixed — in
# `OutlinedContainer` alone. Thirteen other surfaces went on frosting
# without bending, and a context menu is the one a person notices,
# because it opens over the page it is supposed to bend.
#
# The first three conjuncts could not see it: the axis was read, the
# wrapper was there, the fill folded the opacity. The surface was
# complete by every measure the guard had, and flat.
#
# WHY THE TRIGGER IS "READS THE MATERIAL FROM THE THEME"
#
# Not "wraps SurfaceBlur" — that would make conjunct 2 unfalsifiable, and
# a component that dropped the wrapper would leave the set rather than
# fail. Not "mentions surfaceOpacity" either: `Card` forwards the axis
# raw into the `OutlinedContainer` it composes without being a surface
# itself, and a trigger that caught forwarding would flag every composer
# in the kit.
#
# So the trigger is the component asking the theme for the material. That
# is the moment it takes on the contract.
#
# WHY DIRECTORIES, NOT FILES
#
# The resolver and the widget are different files. `popup_style.dart`
# reads the axis and `popup.dart` wraps it — neither file satisfies the
# contract alone and neither is wrong.
#
# A CONDITIONAL WRAPPER IS NOT A GAP
#
# `Popup` wraps only when the panel states a fill, because a fill-less
# panel handed a material stacks a backdrop pass inside the one already
# running and draws a squared band around a group with no box. This guard
# asks whether the three parts are present, never whether they are
# unconditional, so that gate reads as satisfied — which it is.
#
# WHAT THIS DOES NOT CHECK
#
# That the material reaches pixels. A name-matching guard on this axis
# has already been measured passing while the wiring was cut, with only a
# render-value test failing. This one is structural and inherits exactly
# that blindness. It is a net under the contract, not evidence of reach.
set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

LIB='packages/coui_flutter/lib/src/components'

# Asking the theme for the material — the moment the contract attaches.
TRIGGER='theme\.surfaceBlur|theme\.surfaceSaturation|theme\.surfaceSheen|resolveSurfaceSheen\('
WRAP='SurfaceBlur\('
# Either spelling of the same fold. A content-layer resolver reads the flat
# field; a role-aware one asks `theme.surfaceFor(role)` for its material and
# reads the alpha off that. Both are the material's opacity reaching the
# fill, which is the whole of what this conjunct is about.
OPACITY='theme\.surfaceOpacity|material\?\.opacity'
# Handed to the wrapper, not merely settled. A resolver that computes a
# refraction and never passes it on is the exact shape this conjunct
# exists to catch.
BEND='refraction:'

# Conjunct 1 cannot be reported the way the other two are: a component
# that stops reading the material off the theme stops triggering, and a
# guard keyed on the trigger has nothing left to complain about. It
# leaves the set silently, which is the exact failure this epic exists
# to stop.
#
# So the count itself is ratcheted. Removing an axis read now moves this
# number, and moving it down is a failure. Raise the floor in the same
# commit that adds a surface — this file going up is the record that the
# reach grew.
FLOOR_FILE="$(dirname "$0")/flutter_surface_contract_baseline.txt"

# A directory is judged by its own files: recursing would let a parent
# collect every signal its children carry and report a contract nobody
# in it satisfies.
# Two traps live in this one helper.
#
# `-exec … {} +` with no matching files never runs the command, so
# `find` succeeds and the test reads as true — every category directory
# holding no `.dart` of its own would report as satisfying the contract.
# Concatenating instead gives an empty stream and grep says no to that.
#
# And `grep -q` exits on the first match, which SIGPIPEs the `cat`
# feeding it; under `pipefail` that failure becomes the pipeline's, so a
# directory that matched would report as not matching. Dropping `-q`
# makes grep drain its input, which costs nothing at this size.
has() {
  find "$1" -maxdepth 1 -name '*.dart' -exec cat {} + 2>/dev/null |
    grep -E "$2" >/dev/null
}

missing_wrap=''
missing_opacity=''
missing_bend=''
complete=0

while read -r dir; do
  has "$dir" "$TRIGGER" || continue
  short="${dir#$LIB/}"

  ok=1
  has "$dir" "$WRAP"    || { missing_wrap="$missing_wrap $short"; ok=0; }
  has "$dir" "$OPACITY" || { missing_opacity="$missing_opacity $short"; ok=0; }
  has "$dir" "$BEND"    || { missing_bend="$missing_bend $short"; ok=0; }
  [ "$ok" -eq 1 ] && complete=$((complete + 1))
done < <(find "$LIB" -type d | sort)

status=0

if [ -n "$missing_wrap" ]; then
  echo "❌ Reads the material off the theme but never wraps a panel in"
  echo "   \`SurfaceBlur\` — the resolver settles values nothing draws:"
  for d in $missing_wrap; do echo "     $d"; done
  echo "   Wrap the panel: \`SurfaceBlur(surfaceBlur: …, surfaceSheen: …)\`."
  status=1
fi

if [ -n "$missing_opacity" ]; then
  echo "❌ Reads the material off the theme but never folds"
  echo "   \`theme.surfaceOpacity\` into its fill — the blur is painted"
  echo "   and then covered by the opaque panel in front of it:"
  for d in $missing_opacity; do echo "     $d"; done
  echo "   Fold it where the fill is settled:"
  echo "     final opacity = merged.surfaceOpacity ?? theme.surfaceOpacity;"
  echo "     … opacity == null ? fill : fill.scaleAlpha(opacity)"
  status=1
fi

if [ -n "$missing_bend" ]; then
  echo "❌ Draws the material but never hands the wrapper a"
  echo "   \`refraction\` — the surface frosts and never bends, which is a"
  echo "   blurred panel rather than glass:"
  for d in $missing_bend; do echo "     $d"; done
  echo "   Pass the active material's bend where the wrapper is built:"
  echo "     refraction: Theme.of(context).surfaceRefraction"
  status=1
fi

if [ "$status" -eq 0 ]; then
  # Zero is not a clean run — this repo has surfaces, so an empty count
  # means the trigger stopped matching, which is the same shape as a
  # guard renamed out from under its own pattern.
  if [ "$complete" -eq 0 ]; then
    echo "❌ matched 0 surfaces. The repo has some, so the trigger is no"
    echo "   longer finding them — a broken read, not a clean tree."
    exit 1
  fi
  # Fail closed. A missing or unreadable floor used to read as 0, and a
  # floor of 0 is a guard that cannot fail — every surface could leave the
  # set and this would still print a check mark.
  floor=$(tr -d '[:space:]' < "$FLOOR_FILE" 2>/dev/null) || floor=''
  case "$floor" in
    ''|*[!0-9]*)
      echo "❌ ${FLOOR_FILE#./} is missing or is not a single integer."
      echo "   Without a floor this count is not ratcheted at all."
      exit 1 ;;
  esac
  if [ "$complete" -lt "$floor" ]; then
    echo "❌ $complete surface(s) hold the contract, down from $floor."
    echo "   A surface stops being checked the moment it stops reading"
    echo "   the material, so a drop here is the only sign that one left."
    echo "   Restore the axis read, or lower the floor deliberately in"
    echo "   ${FLOOR_FILE#./} and say why."
    exit 1
  fi

  echo "✔ $complete Flutter surface(s) hold all four parts of the"
  echo "  contract: the axis read, the \`SurfaceBlur\` wrapper,"
  echo "  \`theme.surfaceOpacity\` folded into the fill, and the bend"
  echo "  handed to the wrapper (floor $floor)."
fi

exit "$status"
