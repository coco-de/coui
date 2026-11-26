#!/usr/bin/env bash
# A web component's shadow reaches the page through a variable, not a literal.
#
# A surface style bends shadow geometry by re-pointing `--shadow-*`. That
# only reaches a component whose shadow resolves through those variables; a
# component that bakes the layers into a literal is opted out of every
# preset, and nothing about the code says so. On screen it reads as "this
# one component didn't change" — which is not a shape anyone recognises as a
# missing indirection, so it survives.
#
# The routing lives in one place (`emitShadow`), which sends a stack on the
# scale to its variable and anything else to a literal. Calling the raw
# converter from a component skips that decision, so the call is what this
# checks for.
#
# The adapter itself and the variable definitions legitimately call the raw
# converter — one of them is where the literal is supposed to be produced,
# the other is what bakes the variables.
#
# Usage: check_shadow_indirection.sh

set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

SCOPE="packages/coui_web/lib/src/components"

hits=$(grep -rn '\.toValue(base:' "$SCOPE" --include='*.dart' 2>/dev/null || true)

echo "[shadow] components calling the raw box-shadow converter"

if [ -n "$hits" ]; then
  echo "    ❌ a baked literal cannot follow a surface style:"
  printf '%s\n' "$hits" | sed 's/^/       /'
  echo "       Route it through emitShadow(layers, base: …) instead."
  exit 1
fi

routed=$(grep -rc 'emitShadow(' "$SCOPE" --include='*.dart' 2>/dev/null |
  awk -F: '{ n += $2 } END { print n + 0 }')

if [ "$routed" -eq 0 ]; then
  echo "    ❌ no component routes a shadow at all — the check is measuring"
  echo "       nothing, which is worse than a violation because it passes."
  exit 1
fi

echo "    ✅ $routed routed, 0 baked."
exit 0
