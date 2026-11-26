#!/usr/bin/env bash
#
# check_componentization.sh — Epic #2302 normalization guard.
#
# One objective measure of how far the component library is from the
# "organic Co-block composition + Flutter↔Web identical structure"
# target. Every dimension below must reach 0; CI gates on the total.
#
# Dimensions:
#   B  hand-rolled clickable        → CoClickable / CoButton
#   C1 CoreColor(x.toARGB32())       → CoreColor token raw-forward (single
#                                      field, NO `Token` suffix, NO dup)
#   C2 native (Vertical)Divider      → CoSeparator / CoDivider
#   A  residual Component.text       → CoUI Text (mono/code excepted)
#   N  resolver-output var named     → rename `final style = resolveCo…`
#      `style` instead of `resolved`   to `final resolved = …`
#
# Usage: scripts/check_componentization.sh [-v]
# @Deprecated legacy excluded (rule 8). POSIX grep (CI-safe).

set -uo pipefail

FL="packages/coui_flutter/lib/src/components"
WB="packages/coui_web/lib/src/components"
INC="--include=co_*.dart"
VERBOSE="${1:-}"
TOTAL=0

no_deprecated() {
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    grep -q '@Deprecated' "$f" 2>/dev/null || echo "$f"
  done
}

report() {
  local label="$1" files="$2" n
  n=$(printf '%s\n' "$files" | grep -c . || true)
  printf '  [%3d] %s\n' "$n" "$label"
  TOTAL=$((TOTAL + n))
  if [ "$VERBOSE" = "-v" ] && [ "$n" -gt 0 ]; then
    printf '%s\n' "$files" | sed 's|^|         |'
  fi
}

echo "=== Componentization normalization scan (Epic #2302) ==="
echo
echo "── B: hand-rolled clickable (→ CoClickable / CoButton) ──"
report "Flutter clickable-cursor hand-roll" \
  "$(grep -rlE 'SystemMouseCursors\.click' $INC "$FL" 2>/dev/null \
     | grep -vE 'co_clickable\.dart|co_button\.dart' | no_deprecated)"
report "Web role=button div hand-roll" \
  "$(grep -rlF "'role': 'button'" $INC "$WB" 2>/dev/null \
     | grep -vE 'co_button\.dart|co_clickable\.dart' | no_deprecated)"

echo
echo "── C: native primitive / anti-pattern ──"
report "C1 CoreColor round-trip .toARGB32()" \
  "$(grep -rlE '\.toARGB32\(\)' $INC "$FL" 2>/dev/null | no_deprecated)"
report "C2 native (Vertical)Divider" \
  "$(grep -rlE 'VerticalDivider\(|(^|[^A-Za-z])Divider\(' $INC "$FL" 2>/dev/null \
     | grep -vE 'co_separator\.dart|co_divider\.dart' | no_deprecated)"

echo
echo "── A: residual Component.text labels (mono/code excepted) ──"
report "Web Component.text() (files)" \
  "$(grep -rlF 'Component.text(' $INC "$WB" 2>/dev/null | no_deprecated)"

echo
echo "── N: resolver-output naming (final style = resolveCo… → resolved) ──"
report "Flutter 'final style = resolveCo'" \
  "$(grep -rlE 'final style = resolveCo' $INC "$FL" 2>/dev/null | no_deprecated)"

echo
echo "──────────────────────────────────────────────"
echo "TOTAL normalization violations: $TOTAL"
if [ "$TOTAL" -gt 0 ]; then exit 1; fi
echo "✅ Fully normalized."
exit 0
