#!/usr/bin/env bash
#
# Gate: the pointer-target floor exists on both platforms and reaches
# every control that draws below it.
#
# WCAG 2.2 `2.5.8` asks for a 24×24 pointer target. The kit's smaller
# sizes draw well under that — a checkbox is 12, 14 or 16 before scaling
# — and the fix is deliberately invisible: it extends where a pointer is
# accepted and changes nothing that is painted. That is what makes it
# easy to delete. Nothing looks different afterwards.
#
# Two things are checked, and they fail differently:
#
#   The mechanism — a Flutter widget that expands hit testing and a Web
#   rule that expands the pointer area. Either one going missing takes
#   every control with it at once.
#
#   The reach — a component style that states an interactive size below
#   the floor has to be a component that opts in, on *both* platforms
#   independently. This is the part that rots: a new control ships at
#   `size12`, nobody notices, and the floor
#   silently does not apply to it.
#
# The reach check is a heuristic and says so. It reads size tables, not
# rendered geometry, so it cannot see a control that falls short because
# of its padding — a chip's height comes from its content. Rendered
# geometry is what the tests measure; this catches the case that arrives
# without a test.

set -euo pipefail

cd "$(dirname "$0")/../../.."

readonly token='packages/coui_core/lib/src/size/touch_target.dart'
readonly flutter_widget='packages/coui_flutter/lib/src/components/infra/touch_target/touch_target.dart'
readonly web_rule='packages/coui_web/lib/src/base/theme_config.dart'
readonly web_marker='packages/coui_web/lib/src/util/web_constants.dart'

failures=""

# ── The mechanism ────────────────────────────────────────────────
[ -f "$token" ] || failures="${failures}the shared floor is gone: $token
"
[ -f "$flutter_widget" ] ||
  failures="${failures}Flutter has no way to expand a target: $flutter_widget
"

# Both halves of the Web rule. The element needs `position:relative` for
# the overlay to resolve against it, and that half fails silently: the
# overlay lands against some ancestor and the target moves elsewhere.
grep -q 'kWebTouchTargetMarker' "$web_marker" ||
  failures="${failures}the Web marker class is gone: $web_marker
"
grep -q 'position:relative' "$web_rule" ||
  failures="${failures}the Web rule no longer positions the marked element
"
grep -q 'max(100%' "$web_rule" ||
  failures="${failures}the Web rule no longer states a floor — a fixed size
would shrink targets that are already large enough
"

# ── The reach ────────────────────────────────────────────────────
#
# Interactive size fields — the ones that decide how large a control is
# to a pointer. Icon sizes are excluded on purpose: an icon sits inside a
# button that carries its own size, so a 12px glyph says nothing about
# the target around it.
readonly floor=24
readonly fields='boxSize|indicatorSize|thumbSize|dotSize|handleSize|knobSize'
# One TitleCase name per field above — the `default*` constant a field
# falls back to when a caller doesn't override it. Kept as a literal
# list rather than derived from $fields: bash has no built-in
# capitalize-first-letter, and deriving it would trade a readable
# one-line mapping for a harder-to-audit transform.
readonly default_fields='defaultBoxSize|defaultIndicatorSize|defaultThumbSize|defaultDotSize|defaultHandleSize|defaultKnobSize'
# Both token namespaces a component can route a size through — direct
# `CoreSize.sizeN` and `CoreSpace.spaceN` are both design-token scales
# and either can back an interactive size field.
readonly small_size='Core(Size|Space)\.(size|space)([0-9]|1[0-9]|2[0-3])\b'

# A button a component composes and sizes below the floor. The field
# names above never see it: a close / save / window-control affordance
# is a `Button` whose size arrives as the `height` / `width` of a
# nested `CoreButtonStyle`, and `height` alone is too common a word to
# grep for. So this reads the `CoreButtonStyle(...)` literals
# themselves. Missing it is how three sub-24 buttons shipped with no
# floor on either platform (#3969).
#
# The floor belongs to the component that *renders* the button — the
# nearest `CoreXxxStyle(...)` the literal sits inside. A remove button
# a container hands its chips (`chipStyle: CoreChipStyle(closeButtonStyle:
# …)`) is drawn by `Chip`, so `Chip` is the one that has to opt in.
# A literal at the top of a style file is rendered by that file's own
# component.
button_owners() {
  python3 - "$floor" <<'PY'
import glob
import re
import sys

floor = int(sys.argv[1])
root = 'packages/coui_core/lib/src/component/contracts/'
token = re.compile(r'Core(?:Size|Space)\.(?:size|space)(\d+)\b')
enclosing = re.compile(r'Core(\w+)Style\s*$')


def snake(name):
    return re.sub(r'(?<!^)(?=[A-Z])', '_', name).lower()


def owner_of(text, start, fallback):
    depth = 0
    i = start - 1
    while i >= 0:
        c = text[i]
        if c == ')':
            depth += 1
        elif c == '(':
            if depth == 0:
                m = enclosing.search(text[:i])
                if m and m.group(1) != 'Button':
                    return snake(m.group(1))
            else:
                depth -= 1
        i -= 1
    return fallback


for path in sorted(glob.glob(root + '**/*_style.dart', recursive=True)):
    text = open(path).read()
    component = path[len(root):].split('/')[0]
    for m in re.finditer(r'\bCoreButtonStyle\(', text):
        i, depth = m.end(), 1
        args = []
        while depth and i < len(text):
            c = text[i]
            if c in '([{':
                depth += 1
            elif c in ')]}':
                depth -= 1
            if depth == 1:
                args.append(c)
            i += 1
        top_level = ''.join(args)
        small = False
        for field in ('height', 'width'):
            f = re.search(r'\b' + field + r':\s*([\w.]+)', top_level)
            if f:
                t = token.fullmatch(f.group(1))
                if t and int(t.group(1)) < floor:
                    small = True
        if small:
            print(owner_of(text, m.start(), component))
PY
}

# A size field stated inside a nested `CoreXxxStyle(...)` literal belongs to
# the component that literal styles — the one that draws that size. A dot a
# navigation bar hands its composed `Badge` (`selectionMarkStyle:
# CoreBadgeStyle(dotSize: …)`) is drawn by `Badge`, which states its own
# floor where it is interactive; reading it as the bar's own target would
# demand a floor around a mark no pointer is meant to reach. A size at the
# style's own level stays the file's component.
#
# Buttons are the exception and are read by `button_owners` above: a
# `Button` does not apply the floor itself, so a small button belongs to the
# component that renders it.
size_owners() {
  python3 - "$floor" "$fields" <<'PY'
import glob
import re
import sys

floor = int(sys.argv[1])
fields = sys.argv[2]
root = 'packages/coui_core/lib/src/component/contracts/'
literal = re.compile(
    r'\b(?:' + fields + r'):\s*Core(?:Size|Space)\.(?:size|space)(\d+)\b'
)
enclosing = re.compile(r'Core(\w+)Style\s*$')


def snake(name):
    return re.sub(r'(?<!^)(?=[A-Z])', '_', name).lower()


def owner_of(text, start, fallback):
    depth = 0
    i = start - 1
    while i >= 0:
        c = text[i]
        if c == ')':
            depth += 1
        elif c == '(':
            if depth == 0:
                m = enclosing.search(text[:i])
                if m:
                    return snake(m.group(1))
            else:
                depth -= 1
        i -= 1
    return fallback


for path in sorted(glob.glob(root + '**/*_style.dart', recursive=True)):
    text = open(path).read()
    component = path[len(root):].split('/')[0]
    for m in literal.finditer(text):
        if int(m.group(1)) < floor:
            print(owner_of(text, m.start(), component))
PY
}

small=$(
  {
    {
      # Direct form: the field states its own size inline — attributed to
      # the component whose style literal states it (`size_owners`).
      size_owners
      # One hop through a named constant: the field falls back to a
      # `static const double default*` that states the size instead. This
      # is the shape `dot_indicator`/`slider` actually used, and the
      # direct-form regex above cannot see through the extra assignment —
      # it never matched `defaultDotSize = CoreSpace.space12` at all.
      grep -rnE "static const double ($default_fields) *= *$small_size" \
        packages/coui_core/lib/src/component/contracts --include='*_style.dart' |
        sed 's|packages/coui_core/lib/src/component/contracts/||' |
        cut -d/ -f1
    }
    button_owners
  } | sort -u
)

# Field name alone cannot tell a clickable dot from a decorative one —
# `timeline`'s dot shares the `dotSize` vocabulary with
# `dot_indicator`'s, and only one of those two is a target a pointer
# needs to reach. This is the same widening the a11y-parity
# guard went through: a bare size match isn't proof of a pointer
# surface, so the reach check also asks whether the component states any
# interactive handler at all before demanding a floor for it.
readonly interactive_signal='onTap|onPressed|onChanged|\bClickable\(|\bGestureDetector\('

# Components whose floor waits on a decision, each with the issue that
# decides it. Not an exemption by name alone: an entry with no issue fails,
# and an entry for a component that no longer needs a floor fails too, so
# the list cannot outlive its reason.
#
#   tabs — the close × sits inside a tab that is itself always a pointer
#   target, so a floor on the button would widen it over the label and a
#   tap beside the × would close instead of select (the reason a tappable
#   `Chip` carries no close-button floor). Size or hit area is a design
#   call (#6069).
readonly floor_pending="tabs:#6069"
pending_seen=""

for component in $small; do
  if ! grep -rqE "$interactive_signal" \
    "packages/coui_flutter/lib/src/components" \
    "packages/coui_web/lib/src/components" \
    --include="${component}*.dart"; then
    continue
  fi
  # Each platform opts in on its own — checked separately, not as "the
  # marker appears somewhere across both directories". A combined check
  # passes the moment either platform opts in, so a component that wired
  # up the Web marker but never wrapped the Flutter widget in
  # `TouchTarget` (or the reverse) reads as fully covered when one whole
  # platform has no floor at all. Caught by a regression-injection pass
  # that reverted only the Flutter side of a fix and watched this guard
  # stay green.
  flutter_opted_in=0
  grep -rqE 'TouchTarget' "packages/coui_flutter/lib/src/components" \
    --include="${component}*.dart" && flutter_opted_in=1
  web_opted_in=0
  grep -rqE 'kWebTouchTargetMarker' "packages/coui_web/lib/src/components" \
    --include="${component}*.dart" && web_opted_in=1

  if [ "$flutter_opted_in" = 0 ] || [ "$web_opted_in" = 0 ]; then
    pending_issue=""
    for entry in $floor_pending; do
      [ "${entry%%:*}" = "$component" ] && pending_issue="${entry#*:}"
    done
    if [ -n "$pending_issue" ]; then
      pending_seen="$pending_seen $component"
      continue
    fi
    missing_platforms=""
    [ "$flutter_opted_in" = 0 ] && missing_platforms="Flutter"
    [ "$web_opted_in" = 0 ] &&
      missing_platforms="${missing_platforms:+$missing_platforms + }Web"
    failures="${failures}${component} draws an interactive size under ${floor}
and opts into no pointer-target floor on: ${missing_platforms}
"
  fi
done

for entry in $floor_pending; do
  name="${entry%%:*}"
  issue="${entry#*:}"
  if [ "$issue" = "$entry" ] || ! grep -qE '^#[0-9]+$' <<<"$issue"; then
    failures="${failures}floor_pending entry '${entry}' names no issue
"
  elif ! grep -qw "$name" <<<"$pending_seen"; then
    failures="${failures}floor_pending entry '${entry}' no longer needs a floor — remove it
"
  fi
done

# ── The number, in prose ─────────────────────────────────────────
#
# Docs restate the floor, and the templates they are copied from state
# platform recommendations — 48 (Material), 44 (iOS HIG) — which this
# kit deliberately minimises to the WCAG 2.2 floor of 24. A wrong number
# here is worse than none: it reads as the requirement, and a component
# built to it is over-padded while one built to the real floor looks
# non-conforming.
#
# Matched by NUMBER, not by a fixed spelling list. An earlier version of
# this check only knew the digits "48" — the exact number one template
# had used — so when a *different* template's number (44) showed up on
# three other pages, the check had nothing to compare it against and
# reported green with the wrong floor on the page. Reading the number
# out of the text and comparing it to the real floor closes that gap for
# every platform recommendation, not just the one this check happened to
# have seen before.
#
# Matched by SECTION, not by line. Real cases sit under a `### 터치
# 타겟` heading and state the number on the next line — so a line-level
# keyword filter sees a bare "44dp" and lets it through. A check that
# only sees the spelling nobody uses is worse than none.
prose=$(
  for f in $(find docs_core/content -name '*.md' 2>/dev/null); do
    awk -v file="$f" -v floor="$floor" '
      /^#{2,}/ { heading = tolower($0) }
      {
        line = tolower($0)
        if (!match($0, /[0-9]+(dp|×[0-9]+|x[0-9]+)/)) next
        token = substr($0, RSTART, RLENGTH)
        num = token
        sub(/[^0-9].*/, "", num)
        if (num + 0 == floor + 0) next
        if (line ~ /터치|touch|target/ || heading ~ /터치|touch|target/) {
          print file ":" NR ":" $0
        }
      }
    ' "$f"
  done || true
)
if [ -n "$prose" ]; then
  failures="${failures}docs state a platform recommendation (48 Material, 44 iOS HIG, …)
as the minimum pointer target; the floor is ${floor} (CoreTouchTarget.minimum).
Platform guidance asks for more, and a component may draw larger — but the
line below which one is wrong is ${floor}:
$prose
"
fi

if [ -n "$failures" ]; then
  echo "A control can be smaller than a pointer can reliably hit."
  echo
  printf '%s' "$failures"
  echo
  echo "Extend where the pointer is accepted, not what is drawn:"
  echo "  Flutter — wrap the interactive root in TouchTarget."
  echo "  Web — add kWebTouchTargetMarker to the interactive element."
  exit 1
fi

echo "PASS: the pointer-target floor exists on both platforms and every"
echo "      sub-${floor} interactive size opts into it."
