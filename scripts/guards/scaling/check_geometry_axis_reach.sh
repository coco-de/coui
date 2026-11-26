#!/usr/bin/env bash
# Keeps the surface-geometry axis reaching every Flutter resolver.
#
# Radius has a compiler lever: `CoreBorderRadiusToFlutter.toValue` requires
# `geometry`, so a missed call site is a build error. Stroke has none — a
# border width is a bare `double` with no converter to make required — so
# adoption there rests entirely on this guard.
#
# That asymmetry is the reason this exists. Two geometry axes already
# shipped in this repository declared, wired through equality, and read by
# nobody: `radiusScaling` reached 2 of 142 components and `cornerStyle`
# reached none. Both looked complete from the theme side. What was missing
# was anything that failed when a resolver did not read them.
#
# Checked:
#   A. a resolver that scales a border width must route it through the
#      constraint, not multiply it directly
#   B. a resolver must not read corners off a CoreBorderRadius that has not
#      been through the constraint
#
# Usage: check_geometry_axis_reach.sh [--ci]

set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

COMPONENTS='packages/coui_flutter/lib/src/components'
failed=0

# ── A. bare `* scaling` on a stroke-shaped value ─────────────────────
# The constraint applies its floor after scaling, so a site that multiplies
# on its own both escapes the axis and gets the ordering wrong.
# Matched on whitespace-normalised whole files, not per line. Two shapes
# defeat simpler patterns and both occur here:
#   `(merged.borderWidth ?? Default) * scaling`  — the token before `*` is
#       a paren, so an adjacency pattern matches nothing;
#   `... defaultBorderWidth) *\n      scaling;` — the name and the `*
#       scaling` land on different lines, so a line pattern matches nothing.
# The second shipped past an earlier version of this guard and was caught
# only by an end-to-end paint assertion — which is why that test exists
# alongside this one rather than instead of it.
#
# Scope is *line weight*, not every dimension that happens to be called a
# thickness. A scrollbar's thickness and a resizer handle's thickness are
# widget sizes, and size belongs to the scaling axis; flooring them would
# make a surface style silently resize controls. Only strokes that draw a
# line are matched.
a_hits=$(for f in $(find "$COMPONENTS" -name '*_style.dart'); do
  perl -0777 -ne '
    s{//[^\n]*}{}g;
    while (/((?:borderWidth|boxBorderWidth|strokeWidth|dividerThickness|connectorThickness|indicatorThickness|indentLineThickness)[A-Za-z]*[^;]{0,200}?\*\s*scaling)/gs) {
      my $hit = $1;
      next if $hit =~ /geometry\.stroke/;
      $hit =~ s/\s+/ /g;
      print "'"$f"': $hit\n";
    }
  ' "$f"
done || true)

if [ -n "$a_hits" ]; then
  echo "FAIL: border width scaled outside the geometry constraint:"
  echo "$a_hits" | sed 's/^/    /'
  echo "    — use theme.geometry.stroke(px, scaling: scaling) so a surface"
  echo "      style can reach it and the floor lands after scaling."
  failed=1
fi

# ── B. corner read off an unbent CoreBorderRadius ────────────────────
# A resolver that reads `.topLeft` off the merged Core value never passes
# through the converter, so the axis cannot see it.
b_hits=$(grep -rnE '\(merged\.[A-Za-z]*[Rr]adius[A-Za-z]*\s*\?\?[^)]*\)\s*\.(topLeft|topRight|bottomLeft|bottomRight)' \
  $(find "$COMPONENTS" -name '*_style.dart') 2>/dev/null \
  | grep -v 'geometry' || true)

# ── C. shadow stack converted without the constraint ─────────────────
# Flutter's shadow conversion requires `geometry`, so a missed site is a
# build error — but a resolver can still hand-roll a BoxShadow list and
# skip the converter entirely, which the compiler cannot see.
# Scoped per file, not per line: the `BoxShadow(` call and the
# `theme.geometry` that feeds it are never on the same line, so a
# line-scoped pattern would flag every routed site and miss the point.
c_hits=$(for f in $(find "$COMPONENTS" -name '*_style.dart'); do
  grep -q 'BoxShadow(' "$f" || continue
  grep -q 'geometry\.shadow(' "$f" ||
    echo "$f: builds BoxShadow without geometry.shadow()"
done || true)

if [ -n "$c_hits" ]; then
  echo "FAIL: shadow built without going through the geometry constraint:"
  echo "$c_hits" | sed 's/^/    /'
  echo "    — build the stack as CoreShadowLayer and convert with"
  echo "      toValue(base:, geometry: theme.geometry)."
  failed=1
fi

if [ -n "$b_hits" ]; then
  echo "FAIL: corner read from a radius the surface style never saw:"
  echo "$b_hits" | sed 's/^/    /'
  echo "    — bend it first: theme.geometry.borderRadius(core).topLeft"
  failed=1
fi

if [ "$failed" -eq 0 ]; then
  echo "PASS: geometry axis reaches every scaled stroke and corner read"
fi

exit "$failed"
