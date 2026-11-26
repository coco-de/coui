#!/usr/bin/env bash
# Every field on a theme-axis carrier must be read by production code.
#
# An axis carrier is a type whose fields move a whole app at once — the theme
# data, the surface-style recipe, the constraints a style states. A field
# there that nothing reads is not a small omission: from the authoring side
# the axis looks finished (it has a field, it is in `copyWith`, it is inside
# `==`, it serializes, it may even have tests) while setting it changes
# nothing on screen.
#
# That exact failure has shipped repeatedly here. Each instance was found
# later, by accident, when someone needed the axis to actually work:
#
#   * a corner-shape field wired through an adapter interface with three
#     implementations and no caller
#   * a radius multiplier that reached two components out of ~140
#   * a colour transform whose only production consumer was on one platform
#   * a surface-treatment field on the style recipe with no consumer at all
#   * a motion token that round-trips through serialization and stops there
#
# In every case the type-level plumbing was correct, so neither review nor
# the analyzer objected. What was missing was anything that failed when the
# field went unread. The contract guard covers component style fields, but it
# scans the component contracts only — the theme-level carriers, exactly the
# ones an axis lives on, fall outside it. This closes that gap.
#
# What counts as a read
#
#   Outside the declaring file: a property access, `<something>.field`.
#   Passing a value *in* (`Carrier(field: x)`) is authoring, not consuming,
#   so it deliberately does not count — that is the shape every dead field
#   already had.
#
#   Inside the declaring file: any mention that is not value-type
#   boilerplate. A constraint applies its own field in its own transform, so
#   the transform is a real consumer; the constructor, `copyWith`, `==`,
#   `hashCode` and `toJson` are not, and are subtracted by shape.
#
# This proves something reads the value, not that the value reaches a pixel.
# Reaching a pixel is what a rendering test is for. This catches the case
# where nothing reads it at all, which is the one that keeps happening.
#
# Known blind spot: the cross-file check matches on the field name, so a
# carrier field whose name is also a component style slot reads as consumed
# on the strength of the slot's callers. `focusOutlineStyle` is in that
# position today. Narrowing it would mean resolving the receiver's type,
# which is a different tool than grep; the honest move is to say so here
# rather than let the PASS imply more than it checked.
#
# Ratchet: fields unread today are listed in the baseline beside this script.
# Net-new ones fail; the list may only shrink.
#
# Usage: check_axis_field_consumed.sh [--update]

set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

BASELINE="scripts/guards/structure/axis_field_consumed_baseline.txt"

# Carriers whose fields move the whole app. Add one when a new axis gets a
# home; the list is meant to stay short enough to read.
CARRIERS=(
  "packages/coui_core/lib/src/theme/core_theme_data.dart"
  "packages/coui_core/lib/src/surface/surface_recipe.dart"
  "packages/coui_core/lib/src/surface/surface_color_constraint.dart"
  "packages/coui_core/lib/src/surface/surface_geometry_constraint.dart"
  "packages/coui_core/lib/src/surface/surface_typography_constraint.dart"
  "packages/coui_core/lib/src/surface/surface_tuning.dart"
  "packages/coui_core/lib/src/component/contracts/surface/surface_a11y_contract.dart"
  "packages/coui_core/lib/src/surface/surface_token.dart"
  "packages/coui_core/lib/src/surface/surface_edge_sheen.dart"
  "packages/coui_core/lib/src/motion/motion_token.dart"
  # The typography tier's heading sizes. Their names are also the type
  # roles', so the cross-file check passes on any role access — the blind
  # spot above. The read that matters is `sizeOf` in the same file, and what
  # fails when it breaks is the shared tier vectors the seats are tested on.
  "packages/coui_core/lib/src/typography/typography_tier.dart"
  # Not a theme axis, but the same failure shape: an ambient constraint a
  # wrapper publishes to every input below it. A field here that no input
  # reads looks wired from the publishing side and changes nothing.
  "packages/coui_core/lib/src/component/contracts/form/form_field_scope.dart"
  # The quality axis: what an app states about trading the glass for
  # smoothness, the numbers the governor decides by, the ladder of tiers and
  # the record of a change. A field here that no seat reads looks wired from
  # the app's side — it is stated, compared, copied — and moves nothing.
  "packages/coui_core/lib/src/quality/quality_tier.dart"
  "packages/coui_core/lib/src/quality/quality_tuning.dart"
  "packages/coui_core/lib/src/quality/quality_governor.dart"
  "packages/coui_core/lib/src/quality/adaptive_quality.dart"
)

unread=""

for carrier in "${CARRIERS[@]}"; do
  [ -f "$carrier" ] || { echo "FAIL: carrier missing: $carrier"; exit 1; }

  fields=$(grep -oE '^  final [A-Za-z0-9_<>,? ]+ [a-z][A-Za-z0-9]*;' "$carrier" |
    sed -E 's/.* ([a-z][A-Za-z0-9]*);/\1/' | sort -u)

  for field in $fields; do
    # Read from elsewhere: a property access on some object.
    outside=$(grep -rlE "\.${field}\b" packages/*/lib --include='*.dart' 2>/dev/null |
      grep -v "^${carrier}$" | head -1)
    [ -n "$outside" ] && continue

    # Read at home: a mention that is not value-type boilerplate.
    inside=$(FIELD="$field" perl -ne '
      my $f = $ENV{FIELD};
      next unless /\b\Q$f\E\b/;
      next if m{^\s*(///|//)};                       # comment
      next if /^\s*(required\s+)?this\.\Q$f\E\b/;    # constructor initializer
      next if /^\s*(final|const)\s.*\b\Q$f\E;\s*$/;  # the declaration
      next if /^\s*[\w<>,?\s]+\s\Q$f\E,\s*$/;        # copyWith parameter
      next if /\Q$f\E\s*==\s*other\.\Q$f\E/;         # equality
      next if /^\s*\Q$f\E,\s*$/;                     # hashCode entry
      next if /'"'"'\Q$f\E'"'"'\s*:/;                # toJson key
      # Writing the value in is authoring, not consuming — copyWith bodies,
      # the preset instances declared beside the type, any construction.
      # Every field that turned out to be dead already had this shape.
      next if /^\s*\Q$f\E:\s*/;
      # Comparing the value is not applying it. An assert that a fallback
      # was declared, or an `isIdentity` reporting the value is absent, is
      # exactly the guarantee that proved insufficient: it says the value
      # exists, never that anything draws it.
      #
      # The comparison is cut out of the line rather than the line being
      # dropped, because one line often does both — a transform that
      # short-circuits on null and then uses the value in the same
      # expression would otherwise read as dead.
      my $rest = $_;
      $rest =~ s/\Q$f\E\s*[!=<>]=?\s*[\w.!]+//g;
      $rest =~ s/[\w.!]+\s*[!=<>]=?\s*\Q$f\E//g;
      next unless $rest =~ /\b\Q$f\E\b/;
      print; last;
    ' "$carrier")
    [ -n "$inside" ] && continue

    unread="${unread}${carrier##*/}:${field}
"
  done
done

unread=$(printf '%s' "$unread" | sed '/^$/d' | sort -u)

if [ "${1:-}" = "--update" ]; then
  {
    echo "# Axis-carrier fields that no production code reads."
    echo "# Net-new entries fail CI; this list may only shrink."
    printf '%s\n' "$unread"
  } | sed '/^$/d' > "$BASELINE"
  echo "baseline updated ($(printf '%s' "$unread" | grep -c . || true) entries)"
  exit 0
fi

known=$(grep -vE '^#|^$' "$BASELINE" 2>/dev/null | sort -u)
netnew=$(comm -23 <(printf '%s\n' "$unread" | sed '/^$/d') <(printf '%s\n' "$known" | sed '/^$/d'))

if [ -n "$netnew" ]; then
  echo "FAIL: axis-carrier field that nothing reads:"
  printf '%s\n' "$netnew" | sed 's/^/    /'
  echo "    — an axis whose field is unread looks complete and changes"
  echo "      nothing on screen. Wire it where the value is consumed, and"
  echo "      add a test that reads it back through that path."
  exit 1
fi

echo "PASS: every axis-carrier field is read ($(printf '%s' "$known" | grep -c . || echo 0) known unread)"
exit 0
