#!/usr/bin/env bash
#
# Gate: a spacing value reaches the size factor only through the theme
# density.
#
# The density moves spacing one rung on the spacing scale, and Flutter has
# exactly one place to do that: where a resolver turns an authored value
# into a paint-ready one. Insets have a conversion that takes the theme's
# geometry, and the `pass_theme_geometry` lint (coui_lints) holds every call
# to it. A spacing *double* has no conversion — `merged.x ?? default` goes
# straight into `* scaling` — so nothing at compile time can require it to
# pass through `theme.geometry.space(...)`. Leaving it out renders correctly
# under the standard density and ignores every other one: the component
# keeps its gaps while the padding around it tightens.
#
# The check reads the resolvers' syntax trees
# (`packages/coui_lints/tool/density_spacing_reach.dart`) rather than
# matching text: a regular expression over these files once matched
# nothing — its pattern expected the operands on one line, the code had
# them across two — and passed every file it was meant to catch. The tool
# fails, rather than passes, when it reads no resolver or no `* scaling`
# product: a check pointed at the wrong place is not evidence of
# compliance.
#
# Ratchet: values named like spacing that are not the layout's spacing —
# geometry a component replicates or plots — are counted in the baseline
# beside this script, each with its reason. Net-new ones fail.
#
# Usage: check_density_spacing_reach.sh
set -uo pipefail

_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/ratchet.sh
. "$_GUARD_DIR/../lib/ratchet.sh"
# shellcheck source=../lib/require_tool.sh
. "$_GUARD_DIR/../lib/require_tool.sh"

cd "$_GUARD_DIR/../../.." || exit 1

require_tool dart --version

BASELINE=$(ratchet_int "$_GUARD_DIR/density_spacing_reach_baseline.txt") || exit 1
ROOT="$PWD/packages/coui_flutter/lib/src/components"

cd packages/coui_lints || exit 1
dart run tool/density_spacing_reach.dart --root "$ROOT" --baseline "$BASELINE"
