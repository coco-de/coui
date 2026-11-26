#!/usr/bin/env bash
#
# Gate: the OKLab / sRGB colour-space transformation math has exactly one
# home — `coui_core`'s `color/color_conversion.dart` (`CoreColorConversion`).
#
# `coui_flutter` and `coui_web` bridge through `CoreColorConversion`
# (Color ↔ Core, string parsing); they must NOT re-declare the OKLab matrix
# coefficients or the sRGB gamma constants. A second copy silently diverges
# (one matrix tweak fixes one platform's colours, not the other) — exactly
# the duplication S1.2 removed. This guard keeps it removed (spirit of
# verify_contracts.sh / check_design_tokens.sh — "누락을 코드로 막는다").
#
# Method: grep the distinctive colour-space constants (the multi-digit
# OKLab↔linear-sRGB matrix coefficients + sRGB gamma thresholds — values
# that do not occur coincidentally) across the platform packages. Any hit
# outside `coui_core` is a re-declaration.
#
# Usage: ./scripts/check_color_space_single_source.sh
set -uo pipefail

# Distinctive OKLab↔sRGB constants (matrix coefficients + sRGB gamma).
PATTERN='0\.3963377774|0\.2158037573|0\.1055613458|0\.0638541728|0\.0894841775|1\.2914855480|4\.0767416621|3\.3077115913|0\.2309699292|1\.2684380046|2\.6097574011|0\.3413193965|0\.0041960863|0\.7034186147|1\.7076147010|0\.0031308|0\.04045'

status=0

# 1. No colour-space math outside coui_core.
hits=$(grep -rnE "$PATTERN" \
  packages/coui_flutter/lib packages/coui_web/lib \
  --include='*.dart' 2>/dev/null || true)

if [ -n "$hits" ]; then
  echo "❌ Colour-space math constant re-declared outside coui_core:"
  echo "$hits" | sed 's/^/     /'
  echo "   OKLab/sRGB transforms live only in"
  echo "   coui_core/lib/src/color/color_conversion.dart — bridge through"
  echo "   CoreColorConversion instead (do not copy the matrix)."
  status=1
else
  echo "✅ Colour-space math is single-source (no copies in flutter/web)."
fi

# 2. The single source actually exists (guard is meaningful).
if ! grep -qE "$PATTERN" packages/coui_core/lib/src/color/color_conversion.dart 2>/dev/null; then
  echo "❌ Expected the OKLab/sRGB constants in"
  echo "   coui_core/lib/src/color/color_conversion.dart — not found."
  echo "   (Did the file move? Update this guard's source path.)"
  status=1
fi

exit "$status"
