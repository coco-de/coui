#!/usr/bin/env bash
#
# Gate: WCAG contrast for the semantic colour pairs the design system
# actually renders — light, dark, both high-contrast variants, and the
# deltas each colour-changing preset contributes on top; all of it under
# CoUI's own colour source (`CouiColorPresets.source`, what every CoUI seat
# draws) and again under the standard mapping brands inherit, each
# namespaced in the baseline by its own prefix.
#
# The other token guards keep hardcoded values out; none of them look at
# contrast. A palette tweak or a semantic-mapping change can therefore drop a
# pair below `1.4.3 Contrast (Minimum)` with a green build — the screen still
# looks plausible to whoever made the change, and only fails the people who
# cannot read low-contrast text.
#
# The audit itself needs the Dart SDK (it builds the real schemes rather than
# re-parsing colour literals out of source, so it measures what actually
# renders). This wrapper exists so the check sits with the other token guards
# instead of being an isolated `dart run` line in CI.
#
# Ratchet: today's violations are frozen in tool/contrast_baseline.txt.
# Net-new fails; the baseline may only shrink.
#
# Usage: ./scripts/guards/tokens/check_contrast.sh
set -uo pipefail

if ! command -v dart >/dev/null 2>&1; then
  echo "⚠️  dart not found — skipping contrast guard."
  echo "   (This check measures resolved colour schemes, so it needs the SDK."
  echo "    It runs in the SDK-backed CI job; a local skip is not a pass.)"
  exit 0
fi

# The audit lives inside coui_core because it imports that package's schemes
# rather than re-parsing colour literals out of source.
cd "$(dirname "$0")/../../../packages/coui_core" || exit 1
exec dart run tool/check_contrast.dart --ci
