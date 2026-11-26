#!/usr/bin/env bash
#
# Inline spacing in coui_web reaches the `--coui-space-*` variables.
#
# Every inline declaration whose property is spacing — `padding`,
# `padding-*`, `margin`, `margin-*`, `gap`, `row-gap`, `column-gap`,
# logical `*-inline-*` / `*-block-*` longhands included — takes its value
# from `spaceCss(px)` or from a helper that routes through it
# (`CoreEdgeInsets.toValue()`, `toLogicalDeclarations`, `emitSpacing`). It
# never builds the length itself: `_rem(…)`, `'${x / kRemDivisor}rem'`,
# `'${x / 16}rem'`, a literal `'4px'` / `'1rem'` / `'0'`, or a hand-built
# `'var(--coui-space-${x.toInt()})'`.
#
# ## Why
#
# On Web a theme axis can only re-map a value that is emitted through a CSS
# variable (`core/theme-axis-composition.md`, "Web 은 CSS 변수로만 재지정한다").
# A Tailwind spacing class already reads one (`p-space16` →
# `var(--coui-space-16)`); an inline declaration written as a literal `rem`
# renders the same length today and is the one place a re-mapped variable —
# a designer override, a density axis — silently does not reach. Nothing
# throws and nothing looks wrong until someone turns the axis on, and then
# only that component keeps its old spacing.
#
# `spaceCss` keeps a step a variable and emits anything else (an off-scale
# override, a negative offset) as the same literal as before, so routing
# through it changes no rendered value. The hand-built variable is banned
# because `toInt()` truncation names a variable that does not exist for an
# off-scale value, and the browser drops the declaration.
#
# ## What this counts
#
# The scanner (`spacing_var_routing.py`) lexes the Dart, so it sees values
# held in locals, built by same-file helpers (`String rem(double px) => …`),
# spread over adjacent string literals, and keys that are computed — a
# ternary of two properties, a local or a function returning one, or a
# parameter a call site feeds one (`{cssProperty: …}` inside a helper called
# with `cssProperty: 'gap'`). It also checks that `CoreEdgeInsetsToCss` itself
# routes through `spaceCss`, because every `.toValue()` call above is trusted
# on that basis, and it fails rather than passes when it finds fewer
# declarations than a floor (a scanner gone blind reads as "no violations").
#
# One opt-out is allowed and counted: `pinnedLengthCss`, for a value that
# rides a spacing property without being spacing (a cap taken from a size, a
# device's safe area, a centring pull-back, margins that cancel a footprint).
# Pinned values never name a spacing variable, so a re-map leaves them where
# they are; the count is a ratchet in `spacing_pinned_length_baseline.txt`,
# so a new one is a declared decision rather than a quiet way around the rule.
#
# ## What this does not count
#
# - The routed converters of other families are trusted as values:
#   `radiusCss`, `strokeWidthCss`, `pictureStrokeCss` (an inset that clears a
#   corner is a radius, a band drawn with `padding` is a stroke).
# - Whether a value sent through `spaceCss` is spacing in meaning. A size or
#   a derived offset that happens to equal a step becomes that step's
#   variable — value-identical, but it will follow a re-map. Choosing
#   `pinnedLengthCss` for it is review's call, not this scan's.
# - Couplings to properties outside this rule: a spacing value that also
#   feeds a Dart-side `transform`, `width` or `height` follows a re-map in
#   the spacing declaration and not in the other one.
# - Spacing written into CSS text (a scoped `<style>` rule string) or
#   through jaspr's typed `Styles(padding: …)` API — the scan reads map
#   entries and index assignments only.
# - A member that returns a literal, other than the ones the scanner names
#   (`CoreBorderRadius.uniformRem`): `x.member` is trusted, the same way
#   `insets.toValue()` is.
# - The unit argument of complete `round(nearest, 1lh, 1px)` is a logical
#   line-metric quantum (Flutter LineMetrics.height), not authored spacing.
#   Only that 1px argument is distinguished; other literals in the same
#   expression, other inputs/quanta, and incomplete functions still fail.
#
# Usage: ./scripts/guards/tokens/check_spacing_var_routing.sh
#        ./scripts/guards/tokens/check_spacing_var_routing.sh --self-test

set -uo pipefail

# lib/ratchet.sh 는 source 될 때 `$1 == --self-test` 를 자기 self-test 로
# 가로채 exit 한다. 이 가드의 플래그를 먼저 집고 positional 을 비운 뒤 source.
SELF_TEST=0
[ "${1:-}" = "--self-test" ] && SELF_TEST=1
set --

_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ratchet 기준값은 파일에 산다 — 읽기 실패는 fail-closed 다 (lib/ratchet.sh).
# shellcheck source=../lib/ratchet.sh
. "$_GUARD_DIR/../lib/ratchet.sh"

# 스캐너가 python3 이다. macOS 의 /usr/bin/python3 은 Xcode 심이라, 라이선스에
# 동의하지 않은 러너에서는 존재는 하는데 실행이 실패한다 — 그때 이 가드가
# `exit 1` 로 끝나면 "위반을 찾았다" 와 구별되지 않는다.
# shellcheck source=../lib/require_tool.sh
. "$_GUARD_DIR/../lib/require_tool.sh"
require_tool python3 -c 'print(1)'

cd "$_GUARD_DIR/../../.." || exit 1

if [ "$SELF_TEST" -eq 1 ]; then
  python3 "$_GUARD_DIR/spacing_var_routing.py" --self-test
  exit $?
fi

BASELINE=$(ratchet_int "$_GUARD_DIR/spacing_pinned_length_baseline.txt") || exit 1

echo "=== 인라인 간격은 --coui-space-* 변수로 (spaceCss) ==="
python3 "$_GUARD_DIR/spacing_var_routing.py" packages/coui_web/lib \
  --pinned-baseline="$BASELINE"
rc=$?
if [ "$rc" -eq 1 ]; then
  echo "   왜: 리터럴 rem 은 오늘 같은 길이를 그리지만, 변수를 다시 가리키는 규칙"
  echo "       (디자이너 override · 밀도 축)이 그 선언에만 닿지 않는다."
  echo "   무엇을: 값을 spaceCss(px) 로 — 단계는 var(--coui-space-N), 그 밖의 값은"
  echo "       예전과 같은 리터럴이 된다. 인셋은 CoreEdgeInsets.toValue()."
fi
exit "$rc"
