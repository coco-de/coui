#!/usr/bin/env bash
#
# Gate: every value a `tailwind*` adapter (`core_to_css.dart`) can emit as a
# class key has a matching registration in `theme_config.dart` — the
# Tailwind config entry AND the `--coui-*` CSS variable it points at.
#
# Why: a `tailwind*` getter turns a Core token into a class-name key
# (`CoreRadius.radius10` → `'radius10'`). The token guard (Phase 1-7) only
# checks that call sites reference a token instead of a literal, so it is
# green the moment the token is spelled correctly — it has no opinion on
# whether `theme_config.dart` actually defines a CSS rule for that key. When
# it doesn't, the browser silently drops the declaration (unknown class /
# undefined CSS variable) and the component renders as if the token were
# never applied. #3774 found this for `radius`: `tailwindRadius` emits all
# 19 `CoreRadius` steps, `theme_config.dart`'s `borderRadius` config only
# registered 9 — the missing 10 produced valid-looking classes
# (`rounded-radius10`) with no CSS behind them, and every existing guard
# was green because nothing about that gap involves a literal.
#
# This gate is the general form: for every closed-vocabulary `tailwind*`
# adapter, the set of keys it CAN emit must be a SUBSET of the set
# `theme_config.dart` registers. Radius is one instance of the shape, not
# the only one covered — stroke-width, font-weight, and duration go through
# the same switch-statement pattern, and space/size go through a formula
# (`'space${toInt()}'`) sourced from the `CoreSpace`/`CoreSize` token files
# instead of a switch. Each family may have more than one registration
# surface in `theme_config.dart` (a Tailwind config key map, a `:root`
# CSS-variable block, and — radius/stroke only — a `_kXxxVariableSteps` list
# consumed by the surface-style geometry override) and every surface is
# checked independently: a step present in the Tailwind map but missing
# from the CSS-variable block is exactly as broken as the reverse.
#
# What this gate is NOT: it does not check that the registered CSS custom
# property actually resolves to the intended *value* (wrong px amount,
# wrong unit) — only that the key exists at all. Value correctness is a
# design/spec concern; existence is the structural one #3774 is about.
#
# Usage: ./scripts/guards/tokens/check_tailwind_theme_config_parity.sh
set -uo pipefail

CSS_FILE="packages/coui_web/lib/src/util/core_to_css.dart"
CFG_FILE="packages/coui_web/lib/src/base/theme_config.dart"
CORE_SPACE_FILE="packages/coui_core/lib/src/spacing/spacing.dart"
CORE_SIZE_FILE="packages/coui_core/lib/src/size/size.dart"
CORE_LAYOUT_FILE="packages/coui_core/lib/src/size/layout.dart"

for f in "$CSS_FILE" "$CFG_FILE" "$CORE_SPACE_FILE" "$CORE_SIZE_FILE"; do
  if [ ! -f "$f" ]; then
    echo "❌ Expected file not found: $f"
    exit 1
  fi
done

status=0

# Prints a single Dart statement (from the line matching $2 to the next
# line ending in `;`) out of file $1. Every block this gate reads —
# switch-expression getters, `static final`/`static const` string or list
# literals — is exactly one such statement, so this one primitive covers
# all of them without a bespoke end-marker per family.
extract_stmt() {
  awk -v pat="$2" '
    $0 ~ pat { p = 1 }
    p { print }
    p && $0 ~ /;[[:space:]]*$/ { exit }
  ' "$1"
}

# Reports any value present in EMITTED but absent from REGISTERED.
# $1 = family label, $2 = registration-surface label, $3 = emitted values
# (newline-separated), $4 = registered values (newline-separated).
check_coverage() {
  local family="$1" surface="$2" emitted="$3" registered="$4"
  local missing
  missing=$(comm -23 \
    <(printf '%s\n' "$emitted" | sort -u) \
    <(printf '%s\n' "$registered" | sort -u))
  if [ -n "$missing" ]; then
    echo "❌ $family: '$surface' does not register a key tailwind* emits:"
    echo "$missing" | sed 's/^/     /'
    status=1
  else
    echo "✅ $family ↔ $surface: registered set covers the full emitted set."
  fi
}

# ── radius (CoreRadius, 19 steps) ────────────────────────────────────────

radius_emitted=$(extract_stmt "$CSS_FILE" 'String get tailwindRadius' \
  | grep -F '=>' \
  | grep -oE 'CoreRadius\.scale\.radius[0-9]+' \
  | sed -E 's/.*\.radius//')

radius_reg_config=$(extract_stmt "$CFG_FILE" '_borderRadiusConfig =' \
  | grep -oE 'CoreRadius\.scale\.radius[0-9]+' \
  | sed -E 's/.*\.radius//')
check_coverage 'radius' '_borderRadiusConfig (Tailwind key map)' \
  "$radius_emitted" "$radius_reg_config"

radius_reg_cssvar=$(extract_stmt "$CFG_FILE" '_tokenCssVariables =' \
  | sed -n '/Border radius/,/Ring width/p' \
  | grep -oE -- '--coui-radius-[0-9]+:' \
  | sed -E 's/--coui-radius-//; s/://')
check_coverage 'radius' '_tokenCssVariables (:root CSS variables)' \
  "$radius_emitted" "$radius_reg_cssvar"

# The surface-geometry surface used to be a SECOND radius step list in
# theme_config.dart, and the two came apart: it carried all nineteen
# steps while the emitter carried nine, so ten radii were bent here and
# never referenced there — a `.radius48` chip stayed a pill on Web while
# its Flutter twin obeyed the preset. Coverage checking could not catch
# that, because it only asks whether the registered set covers the
# emitted one and the gap ran the other way.
#
# So the two are now one constant, and what is checked is that they stay
# one. A re-introduced local list is the regression, and it is visible
# in the source rather than in a set difference.
if grep -qE '_kRadiusVariableSteps\s*=' "$CFG_FILE"; then
  echo "❌ radius: theme_config.dart declares its own radius step list again."
  echo "   The surface-geometry loop must read the emitter's 'kRadiusSteps'"
  echo "   (core_to_css.dart). Two lists drifted once already: nineteen bent"
  echo "   steps against nine emitted ones, and the ten in between emitted"
  echo "   literals no surface style could move."
  status=1
elif grep -qE 'for \(final step in kRadiusSteps\)' "$CFG_FILE"; then
  echo "✅ radius ↔ surface-style geometry: one shared list (kRadiusSteps)."
else
  echo "❌ radius: the surface-geometry loop no longer reads kRadiusSteps."
  echo "   Whatever it reads now is a second source and can drift from the"
  echo "   emitter — which is the defect this replaced."
  status=1
fi

# ── stroke width (CoreStrokeWidth, 10 steps) ──────────────────────────────
#
# A fractional step is spelled with `_` (`stroke0_5`, `stroke1_5`), so every
# pattern below reads an optional `_<digits>` — without it `1_5` collapses to
# `1`, and a registry missing the step passes green.

stroke_emitted=$(extract_stmt "$CSS_FILE" 'String get tailwindStroke' \
  | grep -F '=>' \
  | grep -oE 'CoreStrokeWidth\.scale\.stroke[0-9]+(_[0-9]+)?' \
  | sed -E 's/.*\.stroke//')

stroke_reg_config=$(extract_stmt "$CFG_FILE" '_borderWidthConfig =' \
  | grep -oE 'CoreStrokeWidth\.scale\.stroke[0-9]+(_[0-9]+)?' \
  | sed -E 's/.*\.stroke//')
check_coverage 'stroke-width' '_borderWidthConfig (Tailwind key map)' \
  "$stroke_emitted" "$stroke_reg_config"

stroke_reg_cssvar=$(extract_stmt "$CFG_FILE" '_tokenCssVariables =' \
  | sed -n '/Border width/,/Border radius/p' \
  | grep -oE -- '--coui-stroke-width-[0-9]+(_[0-9]+)?:' \
  | sed -E 's/--coui-stroke-width-//; s/://')
check_coverage 'stroke-width' '_tokenCssVariables (:root CSS variables)' \
  "$stroke_emitted" "$stroke_reg_cssvar"

stroke_reg_steps=$(extract_stmt "$CFG_FILE" '_kStrokeVariableSteps =' \
  | grep -oE "key: '[0-9]+(_[0-9]+)?'" \
  | grep -oE '[0-9]+(_[0-9]+)?')
check_coverage 'stroke-width' '_kStrokeVariableSteps (surface-style geometry)' \
  "$stroke_emitted" "$stroke_reg_steps"

# ── font weight (CoreFontWeight, 9 steps, word-keyed) ────────────────────

fontweight_emitted=$(extract_stmt "$CSS_FILE" 'String get tailwindFontWeight' \
  | grep -F '=>' \
  | grep -oE 'CoreFontWeight\.scale\.[A-Za-z]+' \
  | sed -E 's/.*\.scale\.//')

fontweight_reg_config=$(extract_stmt "$CFG_FILE" '_fontWeightConfig =' \
  | grep -oE 'CoreFontWeight\.scale\.[A-Za-z]+' \
  | sed -E 's/.*\.scale\.//')
check_coverage 'font-weight' '_fontWeightConfig (Tailwind key map)' \
  "$fontweight_emitted" "$fontweight_reg_config"

fontweight_reg_cssvar=$(extract_stmt "$CFG_FILE" '_tokenCssVariables =' \
  | sed -n '/Font weight/,/Line height/p' \
  | grep -oE -- '--coui-font-weight-[a-z]+:' \
  | sed -E 's/--coui-font-weight-//; s/://')
check_coverage 'font-weight' '_tokenCssVariables (:root CSS variables)' \
  "$fontweight_emitted" "$fontweight_reg_cssvar"

# ── duration (CoreDuration, 17 steps incl. `indeterminate`) ──────────────
#
# Only one registration surface: `_durationScaleKeys` feeds both the
# Tailwind `transitionDuration` map and the `--coui-duration-*` CSS
# variables through the same list comprehension (see theme_config.dart),
# so those two can't drift from each other — only from the switch.

duration_emitted=$(extract_stmt "$CSS_FILE" 'String get tailwindDuration' \
  | grep -F '=>' \
  | grep -oE 'CoreDuration\.scale\.[A-Za-z0-9]+' \
  | sed -E 's/.*\.scale\.//')

duration_reg=$(extract_stmt "$CFG_FILE" '_durationScaleKeys =' \
  | grep -oE 'CoreDuration\.scale\.[A-Za-z0-9]+' \
  | sed -E 's/.*\.scale\.//')
check_coverage 'duration' '_durationScaleKeys' "$duration_emitted" "$duration_reg"

# ── space (CoreSpace, formula-based — sourced from the token file) ───────
#
# `tailwindSpace` is `'space${toInt()}'`, not a switch, so there is no
# closed vocabulary to read out of core_to_css.dart. The token file itself
# (`CoreSpace`'s `static const spaceN` members) is the closed set.

space_emitted=$(grep -oE 'static const space[0-9]+' "$CORE_SPACE_FILE" \
  | grep -oE '[0-9]+')

space_reg_config=$(extract_stmt "$CFG_FILE" '_spacingConfig =' \
  | grep -oE 'CoreSpace\.scale\.space[0-9]+' \
  | sed -E 's/.*\.space//')
check_coverage 'space' '_spacingConfig (Tailwind key map)' \
  "$space_emitted" "$space_reg_config"

space_reg_cssvar=$(extract_stmt "$CFG_FILE" '_tokenCssVariables =' \
  | sed -n '/── Space (rem)/,/── Size (rem)/p' \
  | grep -oE -- '--coui-space-[0-9]+:' \
  | sed -E 's/--coui-space-//; s/://')
check_coverage 'space' '_tokenCssVariables (:root CSS variables)' \
  "$space_emitted" "$space_reg_cssvar"

# ── size (CoreSize, formula-based — sourced from the token file) ─────────

size_emitted=$(grep -oE 'static const size[0-9]+' "$CORE_SIZE_FILE" \
  | grep -oE '[0-9]+')

size_reg_config=$(extract_stmt "$CFG_FILE" '_sizeAxisConfig =' \
  | grep -oE 'CoreSize\.scale\.size[0-9]+' \
  | sed -E 's/.*\.size//')
check_coverage 'size' '_sizeAxisConfig (Tailwind key map)' \
  "$size_emitted" "$size_reg_config"

size_reg_cssvar=$(extract_stmt "$CFG_FILE" '_tokenCssVariables =' \
  | sed -n '/── Size (rem)/,/── Font size/p' \
  | grep -oE -- '--coui-size-[0-9]+:' \
  | sed -E 's/--coui-size-//; s/://')
check_coverage 'size' '_tokenCssVariables (:root CSS variables)' \
  "$size_emitted" "$size_reg_cssvar"

# ── layout (CoreLayout, formula-based — sourced from the token file) ─────
#
# Panel / overlay bounds. Same shape as size: the `static const layoutN`
# members are the closed set, and both the Tailwind axis map and the
# `:root` variables must cover every one of them.

layout_emitted=$(grep -oE 'static const layout[0-9]+' "$CORE_LAYOUT_FILE" \
  | grep -oE '[0-9]+')

layout_reg_config=$(extract_stmt "$CFG_FILE" '_layoutAxisConfig =' \
  | grep -oE 'CoreLayout\.scale\.layout[0-9]+' \
  | sed -E 's/.*\.layout//')
check_coverage 'layout' '_layoutAxisConfig (Tailwind key map)' \
  "$layout_emitted" "$layout_reg_config"

layout_reg_cssvar=$(extract_stmt "$CFG_FILE" '_tokenCssVariables =' \
  | sed -n '/── Layout (rem)/,/── Font size/p' \
  | grep -oE -- '--coui-layout-[0-9]+:' \
  | sed -E 's/--coui-layout-//; s/://')
check_coverage 'layout' '_tokenCssVariables (:root CSS variables)' \
  "$layout_emitted" "$layout_reg_cssvar"

exit $status
