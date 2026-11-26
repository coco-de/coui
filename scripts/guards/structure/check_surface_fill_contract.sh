#!/usr/bin/env bash
# A surface that carries the marker but never publishes its fill loses
# its background under a material preset.
#
# The preset rule restates the fill as `rgb(var(--coui-surface-rgb) /
# calc(var(--coui-surface-alpha, 1) * N%))`. It has to: a card fills with
# `surface`, a popover with `popover`, and a rule cannot know which. So the
# component publishes the triplet (and the token's own alpha beside it) and
# the preset composes the colour.
#
# Carry the marker without publishing and the rule still matches — it
# resolves to an invalid colour and the background disappears rather than
# turning translucent. Publish without the marker and the preset simply
# never reaches the surface, which is the quieter half of the same bug.
#
# Tests cover the two components that draw their own panel. This covers
# the rest of the file set, including whatever is added next: the pairing
# is a contract, not a per-component decision.
#
# A second, narrower pairing (#3463): a marked surface that states a
# shadow stack of its own must reference claymorphism's rim variable
# beside it. "States a shadow of its own" is the qualifier — not marker
# alone, and not "draws any box-shadow". A rim decorates a surface that
# casts; it does not raise a flat one (`core/theme-axis-composition.md`;
# the Flutter twin keys `resolveSurfaceRim` on the authored stack). A
# `box-shadow` that is only the style's contributed cast, a border drawn
# as an inset layer or a focus band is not a cast the surface authored,
# and asking those to carry the rim is what lit flat surfaces under
# claymorphism on Web alone.
#
# And its converse, held at zero: the rim never rides alone, and never
# beside the contributed cast (or its ghost) as the only other layer —
# the two shapes that over-reach took.
set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

WEB_LIB='packages/coui_web/lib/src'
# The helper, not the bare constant. Since the role axis a surface marks
# itself through `webSurfaceMarkerFor(role)`, which takes the role as a
# required argument — so a surface cannot mark itself without choosing one.
# Matching the constant instead would find only the comment that mentions
# it, and this guard would go green by finding nothing to check.
MARKER='webSurfaceMarkerFor'
# Inline (`surfaceFillVar`) or, for a fill only a pseudo-state paints, the
# class form (`surfaceFillClasses`) — the same publication either way.
PUBLISH='surfaceFillVar\(|surfaceFillClasses\('
RIM='kSurfaceRimVar'
# A shadow stack the component states itself: emitted through the shared
# `emitShadow`, or carried as `CoreShadowLayer`s it converts. Not the
# `box-shadow` property alone — that is also how a surface takes the
# style's contributed cast, a border's inset layer or a focus band, none
# of which it authored, so none of which a rim decorates.
SHADOW='emitShadow\(|CoreShadowLayer|[Ss]hadowLayers'
# The rim written as the whole value, or beside nothing but the style's
# contributed cast (or its zero-alpha ghost). Code lines only.
RIM_OVERREACH="(:|[?]|=>)[[:space:]]*$RIM[[:space:]]*([,;)]|$)|kControlShadow(Ghost)?Var[^;]*$RIM"
# `kSurfaceRimVar`'s own doc: "the rim... belongs on things filled with
# [the page] surface — panels — and not on controls, whose fill is the
# opposite token." Button (#4360) is marked and casts a real shadow, but
# that shadow is the *control* counterpart the same doc names —
# `kControlShadowVar`/`kControlShadowGhostVar` — not a page-surface
# panel elevation. `OutlinedContainer` also references the control
# counterpart (as its `.none`-elevation fallback) and stays eligible
# below: its callers are the panels the rim is for, so this is a named
# exemption for the control itself, not a rule keyed on that reference.
RIM_EXEMPT="$WEB_LIB/components/control/button"
# `ToggleGroup` marks its track, which states no shadow; the stack in the
# directory is the *chosen face's* (`CoreShadow.xs`), an unmarked element that
# lerps through alpha 0 on every change. A rim decorates a surface that casts,
# and the marked surface here does not (the Flutter twin keys the rim on the
# surface's authored stack too), so the heuristic's directory-level match is
# a false positive.
RIM_EXEMPT_TOGGLE_GROUP="$WEB_LIB/components/control/toggle_group"

# The style file that draws a surface and the widget file that carries
# the class can be different files in the same component directory, so
# compare by directory rather than by file.
dirs_with() {
  grep -rlE "$1" "$WEB_LIB/components" --include='*.dart' 2>/dev/null |
    xargs -n1 dirname 2>/dev/null | sort -u
}

marked=$(dirs_with "$MARKER")
publishing=$(dirs_with "$PUBLISH")
shadow_bearing=$(dirs_with "$SHADOW")
rim_reading=$(dirs_with "$RIM")

missing_publish=$(comm -23 <(printf '%s\n' $marked) <(printf '%s\n' $publishing))
missing_marker=$(comm -13 <(printf '%s\n' $marked) <(printf '%s\n' $publishing))

# Eligible for the rim check = marked AND has a shadow mechanism. Not
# "marked" alone — that is exactly the false positive this guard would
# raise against the four surfaces named above if it used the same set
# the fill check does.
rim_eligible=$(comm -12 <(printf '%s\n' $marked) <(printf '%s\n' $shadow_bearing) |
  grep -vx "$RIM_EXEMPT" | grep -vx "$RIM_EXEMPT_TOGGLE_GROUP")
missing_rim=$(comm -23 <(printf '%s\n' $rim_eligible) <(printf '%s\n' $rim_reading))

status=0

if [ -n "$missing_publish" ]; then
  echo "❌ Carries the surface marker but never publishes its fill —"
  echo "   under a material preset the background resolves to an invalid"
  echo "   colour and disappears:"
  for d in $missing_publish; do echo "     ${d#$WEB_LIB/components/}"; done
  echo "   Add \`raw.addAll(surfaceFillVar(<the background token>))\`."
  status=1
fi

if [ -n "$missing_marker" ]; then
  echo "❌ Publishes a fill but carries no surface marker — the preset"
  echo "   never reaches this surface:"
  for d in $missing_marker; do echo "     ${d#$WEB_LIB/components/}"; done
  echo "   Add \`...$MARKER(role)\` to the surface element's class list."
  status=1
fi

if [ -n "$missing_rim" ]; then
  echo "❌ Marked as a surface and states a shadow of its own, but never"
  echo "   references $RIM — claymorphism's rim (its one defining"
  echo "   material statement) never reaches this surface's shadow:"
  for d in $missing_rim; do echo "     ${d#$WEB_LIB/components/}"; done
  echo "   Append \`, $RIM\` beside the authored stack in \`box-shadow\`."
  status=1
fi

# Comment lines are prose about the rule, not the rule.
overreach=$(grep -rnE "$RIM_OVERREACH" "$WEB_LIB" --include='*.dart' 2>/dev/null |
  grep -vE '^[^:]+:[0-9]+:[[:space:]]*//' || true)
if [ -n "$overreach" ]; then
  echo "❌ Names the rim where nothing this surface authored casts — alone,"
  echo "   or beside only the style's contributed cast. A rim decorates a"
  echo "   surface that casts its own shadow; it does not raise a flat one,"
  echo "   and the Flutter twin draws none there:"
  printf '%s\n' "$overreach" | sed "s#^$WEB_LIB/#     #"
  echo "   Write $RIM only beside a stack the component states."
  status=1
fi

if [ "$status" -eq 0 ]; then
  count=$(printf '%s\n' $marked | grep -c . || true)
  rim_count=$(printf '%s\n' $rim_eligible | grep -c . || true)
  echo "✔ $count surface(s) both marked and publishing their fill,"
  echo "  $rim_count of the $MARKER set also stating a shadow of their own,"
  echo "  all reading the rim beside it, and no rim where nothing authored"
  echo "  casts. Some surfaces read the rim without carrying the"
  echo "  marker — that is a narrower question than this guard checks,"
  echo "  and it is not a gap."
fi

exit "$status"
