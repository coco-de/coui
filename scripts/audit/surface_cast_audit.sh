#!/usr/bin/env bash
#
# Walks every documented component under a surface style and reports the
# two ways an injected cast goes wrong on Web.
#
# Both were found by looking at a rendered page after seven all-green
# PRs, which is the reason this exists as a script rather than a habit:
#
#   A. a cast with no box — a shadow thrown by a surface that has no
#      fill and no border. It detaches and reads as a dark smear beside
#      the content rather than as depth. (Transparent button variants;
#      a menubar told not to draw its bar.)
#
#   B. a marker with no cast — an element carrying the opt-in class
#      whose computed shadow is nothing, because an inline `box-shadow`
#      on the same element out-ranks the class. (An avatar's ring chain.)
#
# And the material's three, which go wrong the same ways:
#
#   C. a marker with no material — carries `.coui-surface` but computes
#      to no `backdrop-filter`. Wiring missing, or an inline rule on the
#      same element out-ranked the preset.
#
#   D. a material with no marker — blurs without opting in, which means
#      the blur came from somewhere other than the preset. A second
#      source for the thing the preset is supposed to own.
#
#   E. a material inside a material — a backdrop pass nested in another.
#      Cheap to make by accident and visible when it happens: the inner
#      pass samples a surface that has already been blurred. This is the
#      browser-side shape of a regression already measured in Flutter,
#      where handing a fill-less nested panel a material stacked one
#      pass inside another.
#
# The material checks are gated on the active style actually injecting
# one. `neoBrutalism` states no blur, so a run against it exercises A/B
# and says so rather than reporting C/D/E as clean.
#
# Unit tests cannot see either. They assert the cast is present, and in
# (A) present is exactly what is wrong, while in (B) the Dart side is
# correct and the loss happens in the cascade.
#
# WHAT THIS DOES NOT COVER: Flutter. Two of the five defects this was
# built from were Flutter-side (a variant branch that dropped the cast,
# a sibling widget that never read it). Those need widget tests that
# iterate variants — see test/components/cast_branch_coverage_test.dart.
# A green run here is not a statement about Flutter.
#
# The material extension inherits that boundary exactly. Flutter's side
# of the same contract is held by
# `scripts/guards/structure/check_flutter_surface_contract.sh` (the
# three-part structural contract) and
# `test/components/surface_material_pair_test.dart` (resolver re-read
# plus widget-tree search, per component). Green here says nothing about
# either.
#
# Usage:
#   scripts/audit/surface_cast_audit.sh [<style-id>] [<base-url>]
#
# Defaults to neoBrutalism against http://localhost:8080 — the docs
# server must already be running (`cd docs_site && jaspr serve`).
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

export COUI_PORT="$PORT"
export COUI_BASE="$BASE"
export COUI_STYLE="$STYLE"
export COUI_SLUGS="${SLUGS[*]}"
export COUI_WS_CACHE="$WS_CACHE"

cd "$WS_CACHE"
node "$REPO_ROOT/scripts/audit/surface_cast_audit.mjs"
