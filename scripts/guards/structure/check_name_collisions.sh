#!/usr/bin/env bash
#
# Gate: coui's bare (de-prefixed) public names must not collide with the
# framework names the package barrel re-exports.
#
# De-prefix (Epic #2496) removed the `Co` prefix that made every CoUI type
# immune to framework name clashes. Each barrel now re-exports the framework
# (`package:flutter/widgets.dart` etc / `package:jaspr/dom.dart` + `jaspr.dart`)
# with a curated `hide` list so the CoUI type wins the bare name. If CoUI adds
# a component whose bare name also exists in the framework — or a framework
# upgrade introduces a new colliding name — and the barrel does NOT hide it,
# the barrel's export scope has two declarations for that name and the analyzer
# raises `ambiguous_export` ON THE BARREL. This guard is the named gate that
# replaces the prefix's immunity (spirit of verify_contracts.sh /
# check_design_tokens.sh — "누락을 코드로 막는다", not discipline).
#
# Method (precise + version-correct — uses the real resolver against the
# resolved SDK / pub-cache, so framework upgrades are caught automatically):
#   `dart analyze` each package barrel and fail on any `ambiguous_export`.
#   The fix is always to add the framework name to that barrel's `hide`
#   clause (as Icon/Banner are for flutter, Gap/Position for web).
#
# Usage: ./scripts/check_name_collisions.sh
set -uo pipefail

status=0

check_barrel() {
  local label="$1" barrel="$2"

  if [ ! -f "$barrel" ]; then
    echo "❌ $label: barrel not found at $barrel"
    status=1
    return
  fi

  local out amb
  out=$(dart analyze "$barrel" 2>&1 || true)
  amb=$(echo "$out" | grep -E '\- ambiguous_export$|is defined in the libraries' || true)

  if [ -n "$amb" ]; then
    echo "❌ $label: bare-name collision with a framework export (ambiguous_export)."
    echo "   Add the offending name to the barrel's framework \`hide\` clause"
    echo "   (e.g. Icon/Banner for flutter, Gap/Position for web):"
    echo "$amb" | sed 's/^/     /'
    status=1
  else
    echo "✅ $label: no un-hidden framework name collisions."
  fi
}

echo "── CoUI bare-name ∩ framework collision guard ──"
check_barrel coui_flutter packages/coui_flutter/lib/coui_flutter.dart
check_barrel coui_web packages/coui_web/lib/coui_web.dart

exit "$status"
