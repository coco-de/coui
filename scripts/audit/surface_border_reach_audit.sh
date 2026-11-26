#!/usr/bin/env bash
#
# Walks every documented component under a surface style and reports the
# two ways that style's *border floor* fails to arrive on Web.
#
# The floor can only raise a width that is already being drawn — a zero
# stays zero, deliberately, because several variants express "no border"
# by collapsing the width and a preset that raised those would draw
# borders on components that removed them on purpose. That rule is right
# and it has a consequence nobody had measured: a component that draws
# no border at all is a component the floor can never reach. Under a
# style whose whole identity is that everything is outlined, those
# components render as if the style were off.
#
#   F. no box anywhere in the preview — nothing in the component's
#      rendered example carries a boundary at the style's floor, and
#      nothing wears the style's hard cast either. The preset is
#      invisible on this component.
#
#   G. a boundary painted below the floor — a drawn border or outline
#      thinner than the floor. The constraint lifts every width that
#      passes through it, so a survivor is a width that reached paint by
#      some route the constraint does not sit on.
#
# Unit tests cannot see either. They assert that `stroke()` lifts what it
# is given, and in (F) it is never given anything while in (G) the Dart
# side is correct and the width arrives from somewhere else.
#
# WHAT THIS DOES NOT COVER: Flutter. This measures the browser. Flutter's
# half of the same question needs widget tests that read rendered
# geometry — see test/components/ for the cast's equivalents.
#
# Usage:
#   scripts/audit/surface_border_reach_audit.sh [<style-id>] [<base-url>]
#
# Defaults to neoBrutalism against http://localhost:8080 — the docs
# server must already be running (`cd docs_site && jaspr serve`).
#
# A targeted run: `COUI_SLUGS="tooltip toggle" scripts/audit/...`.
# Prove the detector fires before believing a clean run:
# `COUI_SELFTEST=1 scripts/audit/...`.
#
# Exits non-zero when any component reports an anomaly.

set -euo pipefail

STYLE="${1:-neoBrutalism}"
BASE="${2:-http://localhost:8080}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CATALOG="$REPO_ROOT/docs_core/lib/shared/component_catalog.dart"

if [[ ! -f "$CATALOG" ]]; then
  echo "component catalog not found at $CATALOG" >&2
  exit 1
fi

if ! curl -sf -o /dev/null --max-time 5 "$BASE/"; then
  echo "docs server not reachable at $BASE — start it with:" >&2
  echo "  cd docs_site && jaspr serve --port 8080" >&2
  exit 1
fi

# Slugs come from the catalog rather than a list kept here: a second
# list is a list that goes stale, and the components this misses are
# exactly the new ones nobody has looked at yet.
# A targeted run: `COUI_SLUGS="button alert" scripts/audit/...`. Useful
# when checking one fix, and the only way to sanity-check the probe
# itself against a page whose answer you already know.
if [[ -n "${COUI_SLUGS:-}" ]]; then
  read -r -a SLUGS <<< "$COUI_SLUGS"
else
# `mapfile` is bash 4; macOS ships 3.2, so read the list the portable way.
SLUGS=()
while IFS= read -r slug; do
  SLUGS+=("$slug")
done < <(grep -oE "slug: '[a-z0-9-]+'" "$CATALOG" | sed "s/slug: '//;s/'//" | sort -u)
fi

if [[ ${#SLUGS[@]} -eq 0 ]]; then
  echo "no slugs parsed from $CATALOG" >&2
  exit 1
fi

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if [[ ! -x "$CHROME" ]]; then
  echo "Google Chrome not found at $CHROME" >&2
  exit 1
fi

PROFILE="$(mktemp -d -t coui-audit.XXXXXX)"
CHROME_PID=""
cleanup() {
  local rc=$?
  if [[ -n "$CHROME_PID" ]]; then
    # The browser this run launched, by PID.
    kill "$CHROME_PID" 2>/dev/null || true
    for _ in $(seq 1 25); do
      kill -0 "$CHROME_PID" 2>/dev/null || break
      sleep 0.2
    done
    if kill -0 "$CHROME_PID" 2>/dev/null; then
      kill -9 "$CHROME_PID" 2>/dev/null || true
    fi
  fi
  # A renderer can outlive the browser process. Whatever still carries this
  # run's private profile path is this run's — the path is unique to the
  # run, so unlike a port or flag pattern it cannot reach another browser.
  pkill -f -- "--user-data-dir=$PROFILE" 2>/dev/null || true
  # Chrome's Cache_Data can still be written while it shuts down — retry
  # the recursive remove instead of failing on the macOS "directory not
  # empty" race.
  for _ in 1 2 3 4 5; do
    rm -rf "$PROFILE" 2>/dev/null && break
    sleep 0.2
  done
  exit $rc
}
trap cleanup EXIT

# Port 0 lets the OS pick a free port, so a second run — or anything else
# holding a fixed debugging port — can neither be measured by mistake nor
# be killed by this run's cleanup.
"$CHROME" \
  --remote-debugging-port=0 \
  --user-data-dir="$PROFILE" \
  --no-first-run --no-default-browser-check \
  --headless=new --disable-gpu \
  "about:blank" >/dev/null 2>&1 &
CHROME_PID=$!

# `DevToolsActivePort` is written into the profile only this Chrome owns
# (line 1 = port, line 2 = browser path), so the port it names is this
# Chrome's own.
PORT=""
for _ in $(seq 1 40); do
  if [[ -s "$PROFILE/DevToolsActivePort" && -n "$(sed -n 2p "$PROFILE/DevToolsActivePort")" ]]; then
    PORT="$(sed -n 1p "$PROFILE/DevToolsActivePort")"
    break
  fi
  if ! kill -0 "$CHROME_PID" 2>/dev/null; then
    echo "Chrome exited before opening a debugging port" >&2
    exit 1
  fi
  sleep 0.25
done
if [[ -z "$PORT" ]]; then
  echo "Timed out waiting for Chrome's debugging port" >&2
  exit 1
fi

WS_CACHE="$HOME/.cache/coui-cdp"
mkdir -p "$WS_CACHE"
if [[ ! -d "$WS_CACHE/node_modules/ws" ]]; then
  (cd "$WS_CACHE" && npm init -y >/dev/null 2>&1 && npm install ws --silent >/dev/null 2>&1)
fi

# The floor is the preset's own, read from the recipe rather than passed
# in: a number typed here would be a second statement of it, and the day
# the recipe changes this audit would keep checking the old one.
RECIPE="$REPO_ROOT/packages/coui_core/lib/src/surface/surface_recipe.dart"
STROKE_FLOOR="$(
  awk -v style="CoreSurfaceStyleId.$STYLE:" '
    index($0, style) { inblock = 1 }
    inblock && /CoreSurfaceStyleId\.[a-zA-Z]+: CoreSurfaceRecipe/ && !index($0, style) { inblock = 0 }
    inblock && /strokeFloor: CoreStrokeWidth\.stroke/ {
      match($0, /stroke([0-9]+)/, m); print m[1]; exit
    }
  ' "$RECIPE" 2>/dev/null || true
)"
if [[ -z "$STROKE_FLOOR" ]]; then
  # gawk's match() with a third argument is not in BSD awk; fall back to
  # a plain grep over the same block.
  STROKE_FLOOR="$(
    sed -n "/CoreSurfaceStyleId.$STYLE: CoreSurfaceRecipe/,/^    CoreSurfaceStyleId\.[a-zA-Z]*: CoreSurfaceRecipe/p" "$RECIPE" \
      | grep -oE 'strokeFloor: CoreStrokeWidth\.stroke[0-9]+' | head -1 \
      | grep -oE '[0-9]+$'
  )"
fi
if [[ -z "$STROKE_FLOOR" ]]; then
  echo "$STYLE states no strokeFloor — this audit has nothing to check." >&2
  echo "(That is an answer, not a failure: a style with no floor cannot" >&2
  echo " fail to reach one.)" >&2
  exit 0
fi

export COUI_STROKE_FLOOR="$STROKE_FLOOR"

export COUI_PORT="$PORT"
export COUI_BASE="$BASE"
export COUI_STYLE="$STYLE"
export COUI_SLUGS="${SLUGS[*]}"
export COUI_WS_CACHE="$WS_CACHE"

cd "$WS_CACHE"
node "$REPO_ROOT/scripts/audit/surface_border_reach_audit.mjs"
