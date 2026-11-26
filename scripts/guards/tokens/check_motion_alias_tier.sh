#!/usr/bin/env bash
#
# Gate: component code reaches motion timing through the semantic alias tier
# — `CoreDuration.instant|fast|normal|moderate|slow` for duration,
# `CoreEasing.move|enter|exit|feedback` for easing — never
# through the raw constant that alias is pinned to.
#
# Why: the raw scale says how long / which curve, the alias says why — and
# more practically, a global motion override (reduced-motion, or a future
# systemic easing override) needs ONE vocabulary to act on. If half the
# components say `ms150` and half say `fast`, the override reaches only half
# of them, and the half it misses is invisible until someone with vestibular
# sensitivity hits it. Keeping the aliasable raw tokens out of component code
# makes that reachable set complete by construction rather than by review.
#
# Only the five aliased duration values / four aliased curves are gated.
# `ms0`/`ms50`/`ms250`/`ms350`/`ms400`/`ms450` have no duration alias (no use
# case claimed them), the display tier (`ms1000`+, `indeterminate`) describes
# how long content stays on screen rather than how fast it moves (a motion
# override must not touch those), and the other 30 raw curves (`easeInSine`,
# `easeOutCubic`, `fastOutSlowIn`, …) have no easing alias — all stay raw by
# design.
#
# Exempt by construction:
#   - coui_core/lib/src/motion/          — the tier definitions themselves
#   - coui_web/.../util/core_to_css.dart — the raw→Tailwind/CSS mapping
#     table, which must enumerate raw tokens to translate them (duration +
#     easing alike)
#   - coui_web/.../base/theme_config.dart — same reason, for the Tailwind
#     `transitionTimingFunction` config + `--easing-*` CSS variables, which
#     must enumerate all 34 raw curves (easing only — this file has no raw
#     duration token literal to exempt)
#
# Usage: ./scripts/guards/tokens/check_motion_alias_tier.sh
set -uo pipefail

# The five raw duration tokens that have a semantic alias.
ALIASED_DURATION='CoreDuration\.(ms100|ms150|ms200|ms300|ms500)\b'

# The four raw curves that have a semantic alias. Longest alternative first
# per this repo's `find -regex` / non-GNU-grep convention — `\b` already
# protects `easeOut`/`easeIn` from matching `easeOutBack`/`easeInOut`/etc on
# POSIX-longest-match `grep -E`, but ordering costs nothing and guards any
# leftmost-first engine too.
ALIASED_EASING='CoreEasing\.(easeInOut|easeOutBack|easeOut|easeIn)\b'

status=0

# 1. No aliased raw duration token in shipped library code outside the
#    exemptions.
hits=$(grep -rnE "$ALIASED_DURATION" \
  packages/coui_core/lib packages/coui_flutter/lib packages/coui_web/lib \
  --include='*.dart' 2>/dev/null \
  | grep -v '/lib/src/motion/' \
  | grep -v 'util/core_to_css\.dart' \
  || true)

if [ -n "$hits" ]; then
  echo "❌ Raw duration token used where a semantic alias exists:"
  echo "$hits" | sed 's/^/     /'
  echo "   Use the alias tier so a global motion override reaches this:"
  echo "     ms100 → CoreDuration.instant    ms150 → CoreDuration.fast"
  echo "     ms200 → CoreDuration.normal     ms300 → CoreDuration.moderate"
  echo "     ms500 → CoreDuration.slow"
  status=1
else
  echo "✅ Motion timing goes through the duration alias tier (no aliased raw tokens)."
fi

# 1b. No aliased raw curve in shipped library code outside the exemptions.
#     (#3466/#3467 — this half didn't exist until this gate: the duration
#     check above existed but nothing gated easing consumption, so raw
#     `easeInOut`/`easeOut`/`easeIn`/`easeOutBack` accumulated in ~40 sites
#     across both platforms while only 2 used the alias.)
easing_hits=$(grep -rnE "$ALIASED_EASING" \
  packages/coui_core/lib packages/coui_flutter/lib packages/coui_web/lib \
  --include='*.dart' 2>/dev/null \
  | grep -v '/lib/src/motion/' \
  | grep -v 'util/core_to_css\.dart' \
  | grep -v 'base/theme_config\.dart' \
  || true)

if [ -n "$easing_hits" ]; then
  echo "❌ Raw easing curve used where a semantic alias exists:"
  echo "$easing_hits" | sed 's/^/     /'
  echo "   Use the alias tier so a future systemic easing override reaches this:"
  echo "     easeInOut → CoreEasing.move     easeOut → CoreEasing.enter"
  echo "     easeIn → CoreEasing.exit        easeOutBack → CoreEasing.feedback"
  status=1
else
  echo "✅ Motion timing goes through the easing alias tier (no aliased raw curves)."
fi

# 2. The alias tier actually exists. Without this the guard passes trivially
#    if the tier is ever removed or renamed — a green check for a vocabulary
#    that is no longer there.
DURATION_SRC='packages/coui_core/lib/src/motion/duration_token.dart'
missing=''
for alias in instant fast normal moderate slow; do
  if ! grep -qE "static const int ${alias} = ms[0-9]+;" "$DURATION_SRC" 2>/dev/null; then
    missing="${missing} ${alias}"
  fi
done

if [ -n "$missing" ]; then
  echo "❌ Duration alias tier missing or renamed in ${DURATION_SRC}:"
  echo "    ${missing}"
  echo "   This guard gates against that tier — update both together."
  status=1
fi

EASING_SRC='packages/coui_core/lib/src/motion/easing_scale.dart'
missing_easing=''
for alias in move enter exit feedback; do
  if ! grep -qE "static const CoreCubicBezier ${alias} = ease" "$EASING_SRC" 2>/dev/null; then
    missing_easing="${missing_easing} ${alias}"
  fi
done

if [ -n "$missing_easing" ]; then
  echo "❌ Easing alias tier missing or renamed in ${EASING_SRC}:"
  echo "    ${missing_easing}"
  status=1
fi

exit "$status"
