#!/usr/bin/env bash
#
# Gate: every key a `tailwind*` vocabulary getter (core_to_css.dart) can
# emit for a scale category must be registered in theme_config.dart's
# matching Tailwind config list for that category.
#
# Why this exists: `tailwindRadius` enumerates all 19 `CoreRadius` values,
# but `theme_config.dart`'s `borderRadius` config only registered 9 of
# them. The 10 missing values produced className strings that compiled
# (the vocab getter didn't throw) but had no matching CSS rule — Tailwind
# silently dropped classes like `rounded-radius10` (#3774). A vocab getter
# and its config registration are two hand-maintained lists that must stay
# in lockstep; nothing in the type system enforces that. This guard makes
# the set difference an explicit, checked invariant instead of a silent
# drop discovered by screenshot diffing.
#
# Method: for each category, extract the RHS `Core{X}.scale.{key}`
# references inside the vocab getter's switch body (core_to_css.dart) —
# that's everything the getter can produce — and diff it against the
# `Core{X}.scale.{key}` references inside the matching config variable in
# theme_config.dart. Any vocab key absent from the config set is a class
# string with no CSS rule behind it.
#
# Scope: switch-based vocab getters only (tailwindRadius / tailwindStroke /
# tailwindDuration). tailwindSpace / tailwindSize are a formula
# ('space${toInt()}'), not a switch — every CoreSpace/CoreSize member maps
# by construction, so there is no hand-maintained list to drift.
#
# Usage: ./scripts/guards/tokens/check_tailwind_config_completeness.sh
set -uo pipefail

CSS_FILE="packages/coui_web/lib/src/util/core_to_css.dart"
CONFIG_FILE="packages/coui_web/lib/src/base/theme_config.dart"
status=0

# extract_switch_keys <getter_name> <file>
# Prints unique `Core*.scale.*` RHS references inside `String get
# {getter_name} => switch (this) { ... };`.
extract_switch_keys() {
  local getter="$1" file="$2"
  # Anchor on the switch-statement form specifically (`=> switch (this) {`)
  # so a one-line alias getter of the same name elsewhere in the file
  # (e.g. `CoreBorderRadius.tailwindRadius => topLeft.tailwindRadius;`)
  # never opens a grab that only a *later, unrelated* switch's `};` closes.
  awk -v g="String get ${getter} => switch (this) {" '
    index($0, g) { grabbing = 1 }
    grabbing { print }
    grabbing && /^  };$/ { grabbing = 0 }
  ' "$file" | grep -oE 'Core[A-Za-z]+\.scale\.[A-Za-z0-9]+' | sort -u
}

# extract_config_keys <var_name> <file>
# Prints unique `Core*.scale.*` references inside a
# `static final/const ... _varName = ... ;` declaration (single- or
# multi-line, terminated by a line ending in `;`).
extract_config_keys() {
  local var="$1" file="$2"
  awk -v v="${var} =" '
    $0 ~ v { grabbing = 1 }
    grabbing { print }
    grabbing && /;[[:space:]]*$/ { grabbing = 0 }
  ' "$file" | grep -oE 'Core[A-Za-z]+\.scale\.[A-Za-z0-9]+' | sort -u
}

check_category() {
  local label="$1" getter="$2" config_var="$3"
  local vocab config missing

  vocab=$(extract_switch_keys "$getter" "$CSS_FILE")
  config=$(extract_config_keys "$config_var" "$CONFIG_FILE")

  if [ -z "$vocab" ]; then
    echo "⚠️  ${label}: vocab extraction found 0 keys (getter renamed? guard needs updating) — $CSS_FILE:get $getter"
    status=1
    return
  fi

  missing=$(comm -23 <(echo "$vocab") <(echo "$config"))
  if [ -n "$missing" ]; then
    echo "❌ ${label}: tailwind${getter#tailwind} emits classes with no theme_config registration:"
    echo "$missing" | sed 's/^/     /'
    echo "   → add the missing keys to ${config_var} in $CONFIG_FILE"
    status=1
  else
    echo "✅ ${label}: $(echo "$vocab" | wc -l | tr -d ' ') vocab keys, all registered in theme_config."
  fi
}

check_category "radius"   "tailwindRadius"   "_borderRadiusConfig"
check_category "stroke"   "tailwindStroke"   "_borderWidthConfig"
check_category "duration" "tailwindDuration" "_durationScaleKeys"

exit $status
