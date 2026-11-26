#!/usr/bin/env bash
#
# Which components get the surface material, decided by a rule rather
# than by a list.
#
# `core/theme-axis-composition.md` forbids the axis from carrying a
# component list: a list goes quietly stale as components are added, and
# the omission shows up on screen as "this one didn't change". So this
# script does not hold one. It applies two questions to every component
# directory it finds and reports which class each landed in.
#
#   Q1  Does it draw its own fill?
#       No fill, nothing to make translucent — and a blur behind an
#       opaque fill is invisible anyway. The material is the pair.
#
#   Q2  Can something pass behind it?
#       Nothing passing behind, nothing for the blur to sample. A panel
#       that sits inside its parent's box has only that parent behind it.
#
# Both true -> ELIGIBLE. Either false -> OUT, and the report says which
# question it fell on, because the two failures are fixed differently.
#
# A third class sits before both: a component that composes a
# surface-drawing component (`OutlinedContainer` / `Popup` / `Card` /
# `Dialog` / `Popover`) already receives the material through it.
# Marking it again stacks a second backdrop pass over the first — the
# regression #4231 measured. That class is INHERITS, and it is reported
# rather than silently dropped, because "it already works" and "it is
# not a surface" are different facts about a component.
#
# A component that composes the primitive on one platform and has to
# redraw the same box on the other (a `<span>` root that cannot wrap a
# `<div>`, a native `<button>`) is the same surface on both. The redrawn
# box is the primitive's box, so it is answered as the primitive is —
# ELIGIBLE, with the reason saying so — rather than by asking Q1/Q2 of a
# file that spells its fill and its mount differently from the twin it
# mirrors. `core/theme-axis-composition.md` states the same thing from
# the drawing side: a box redrawn instead of composed receives everything
# the composition would have given it.
#
# WHY Q2 IS PART INFERRED AND PART DECLARED
#
# A floating panel says so in its own source: it mounts through an
# overlay layer, a route, or a fixed/sticky position. That is greppable.
#
# A docked bar does not. `dock` and `navigation_bar` are stacked over
# content by the shell that hosts them, so nothing in their own files
# records that content passes underneath. Inferring it would mean
# guessing from category names, and #4218 already measured what name
# matching is worth on this axis: four sheen fields passed a guard by
# colliding with unrelated fields of the same name.
#
# So a docked surface declares it, once, in its own source:
#
#     /// surface:behind — the shell stacks this bar over scrolling body
#
# The declaration is deliberately separable from the wiring. If "is it a
# surface" were answered by "does it wrap SurfaceBlur", the gap this
# script exists to find would be empty by construction.
#
# Usage:
#   scripts/audit/surface_eligibility_triage.sh            # full report
#   scripts/audit/surface_eligibility_triage.sh --gap      # unwired only
#   scripts/audit/surface_eligibility_triage.sh --markdown # triage doc
#   scripts/audit/surface_eligibility_triage.sh --tsv      # for tooling
#
# Always exits 0 — this reports, it does not judge. The invariant that
# holds today is enforced by check_surface_eligibility.sh.

set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1

MODE="${1:-report}"

# Components that draw a panel other components sit inside. Composing one
# of these is how a component inherits the material. `Popover` is not
# among them: it anchors a panel, it does not draw one — `Popup` does.
SURFACE_DRAWERS='(^|[^A-Za-z0-9_])(OutlinedContainer|Popup|Card|Dialog)\('

# Mounted detached from normal flow — content genuinely passes behind.
BEHIND_INFERRED="OverlayPortal|CoreOverlayLayer|PopoverOverlayHandler|OverlayPositioner|showDialog|PopupRoute|ModalRoute|'position': *'(fixed|sticky)'"

# The docked half, declared because it cannot be inferred (see above).
BEHIND_DECLARED='surface:behind'

# Q1. Both platforms name the fill the same way in the resolver — Flutter
# settles it into a `Color`, Web hands it to `emitColor(.., .background)`
# — so the question is whether the component owns a background colour at
# all, not how it spells the emit.
# `backgroundColor` is the common spelling; a scrim names its fill
# `fillColor`. The question is whether a fill is owned, not how it is
# spelled.
FILL="[Bb]ackgroundColor|[Ff]illColor"

# `-exec … {} +` with no matching files never runs the command, and then
# `find` succeeds — which would read as a match. Directories reaching
# here always hold a `.dart`, but the shape is a trap either way.
has() {
  find "$1" -maxdepth 1 -name '*.dart' -exec cat {} + 2>/dev/null |
    grep -E "$2" >/dev/null
}

# Composition is read from code only. A doc comment showing `HoverCard(`
# is not this component composing a `Card` — and without the word
# boundary above it would not even be a different name. A line comment is
# no different: a Web resolver that says it mirrors the Flutter twin's
# `OutlinedContainer(height:)` composes nothing.
has_code() {
  find "$1" -maxdepth 1 -name '*.dart' -exec cat {} + 2>/dev/null |
    grep -v '^[[:space:]]*//' | grep -E "$2" >/dev/null
}

# Already receiving the material today.
wired_flutter() {
  has "$1" 'theme\.surfaceBlur|theme\.surfaceSaturation|resolveSurfaceSheen\(' &&
    has "$1" 'SurfaceBlur\(' &&
    has "$1" 'surfaceOpacity'
}
# The helper, not the bare constant: a surface marks itself through
# `webSurfaceMarkerFor(role)`, which is where the constant lives. Matching
# the constant alone found only the helper's own file and read every Web
# surface as unwired — so the invariant below held on one platform only.
#
# The fill is published inline (`surfaceFillVar`) or, for a fill only a
# pseudo-state paints, as classes (`surfaceFillClasses`) — one contract.
wired_web() {
  has "$1" 'kWebSurfaceMarker|webSurfaceMarkerFor\(' &&
    has "$1" 'surfaceFillVar\(|surfaceFillClasses\('
}

# The surface-drawing components a directory could compose — every one but
# itself: `outlined_container` naming `OutlinedContainer(` is its own
# constructor, not an inheritance.
drawers_for() { # <dir> -> extended regex, or empty
  local own drawers
  own="$(basename "$1" | awk -F_ '{s="";for(i=1;i<=NF;i++)s=s toupper(substr($i,1,1)) substr($i,2);print s}')"
  drawers="$(printf '%s' "$SURFACE_DRAWERS" |
    sed -E 's/^\(\^\|\[\^A-Za-z0-9_\]\)\(//; s/\)\\\($//' |
    tr '|' '\n' | grep -vxF "$own" | paste -sd'|' -)"
  [ -n "$drawers" ] && printf '(^|[^A-Za-z0-9_])(%s)\\(' "$drawers"
}

composes_drawer() { # <dir>
  local drawers
  drawers="$(drawers_for "$1")"
  [ -n "$drawers" ] && [ -d "$1" ] && has_code "$1" "$drawers"
}

classify() { # <dir> <platform> -> "CLASS<TAB>reason"
  local dir="$1" platform="$2" fill behind twin twin_platform

  if composes_drawer "$dir"; then
    echo -e "INHERITS\tcomposes a surface-drawing component"
    return
  fi

  # The same component on the other platform, by the mirrored path.
  if [ "$platform" = flutter ]; then twin_platform=web; else twin_platform=flutter; fi
  twin="packages/coui_$twin_platform/lib/src/components/${dir#packages/coui_$platform/lib/src/components/}"
  if composes_drawer "$twin"; then
    echo -e "ELIGIBLE\tredraws the surface its $twin_platform twin composes"
    return
  fi

  if ! has "$dir" "$FILL"; then
    echo -e "OUT\tQ1 — draws no fill of its own"
    return
  fi

  if has "$dir" "$BEHIND_INFERRED"; then
    behind='overlay-mounted or detached from flow'
  elif has "$dir" "$BEHIND_DECLARED"; then
    behind='declared: docked over content it does not own'
  else
    echo -e "UNDECIDED\tQ2 — passes Q1, no behind-signal and no declaration"
    return
  fi

  echo -e "ELIGIBLE\t$behind"
}

# Component directories are the leaves that hold a widget file. Found,
# not listed.
dirs_for() {
  find "packages/coui_$1/lib/src/components" -name '*.dart' 2>/dev/null |
    xargs -n1 dirname | sort -u |
    grep -v "^packages/coui_$1/lib/src/components$"
}

emit_platform() { # <platform>
  local platform="$1" dir class reason wired
  while read -r dir; do
    IFS=$'\t' read -r class reason < <(classify "$dir" "$platform")
    if [ "$platform" = flutter ]; then
      wired_flutter "$dir" && wired=wired || wired=unwired
    else
      wired_web "$dir" && wired=wired || wired=unwired
    fi
    printf '%s\t%s\t%s\t%s\t%s\n' \
      "$platform" "${dir#packages/coui_$platform/lib/src/components/}" \
      "$class" "$wired" "$reason"
  done < <(dirs_for "$platform")
}

ROWS="$(emit_platform flutter; emit_platform web)"

count() { printf '%s\n' "$ROWS" | awk -F'\t' "$1" | grep -c . || true; }

case "$MODE" in
  --gap)
    echo "Eligible but not wired — the scope S3/S4 inherits:"
    printf '%s\n' "$ROWS" |
      awk -F'\t' '$3=="ELIGIBLE" && $4=="unwired" {printf "  %-8s %-34s %s\n", $1, $2, $5}'
    ;;
  --tsv)
    # The stable read for other tools: platform, component, class,
    # wiring, reason. `--markdown` is for people and its columns move;
    # anything that depends on the columns reads this instead.
    printf '%s\n' "$ROWS"
    ;;
  --markdown)
    # Every row, including the ones that fell out at Q1: "which question
    # did it fall on" is the whole point of the record, and a table that
    # drops the fallers answers it for nobody.
    printf '%s\n' "$ROWS" |
      sort -t"$(printf '\t')" -k3,3 -k1,1 -k2,2 |
      awk -F'\t' 'BEGIN{print "| 부류 | 플랫폼 | 컴포넌트 | 현재 배선 | 어느 질문에서 |"; print "|---|---|---|---|---|"}
                  {printf "| %s | %s | `%s` | %s | %s |\n", $3, $1, $2, $4, $5}'
    ;;
  *)
    echo "Rule applied to $(printf '%s\n' "$ROWS" | grep -c .) component directories."
    echo
    printf '  %-10s %s\n' ELIGIBLE "$(count '$3=="ELIGIBLE"')"
    printf '  %-10s %s\n' INHERITS "$(count '$3=="INHERITS"')"
    printf '  %-10s %s\n' OUT      "$(count '$3=="OUT"')"
    echo
    echo "Wired today: flutter $(count '$1=="flutter" && $4=="wired"'), web $(count '$1=="web" && $4=="wired"')"
    echo
    echo "Eligible but not wired (S3/S4 scope):"
    printf '%s\n' "$ROWS" |
      awk -F'\t' '$3=="ELIGIBLE" && $4=="unwired" {printf "  %-8s %-34s %s\n", $1, $2, $5}'
    echo
    echo "Wired but the rule says otherwise (must be empty):"
    printf '%s\n' "$ROWS" |
      awk -F'\t' '$3!="ELIGIBLE" && $4=="wired" {printf "  %-8s %-34s %s / %s\n", $1, $2, $3, $5}'
    ;;
esac
