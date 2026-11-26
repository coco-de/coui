#!/usr/bin/env bash
#
# Ratchet: disabled state is a colour, not a multiplier.
#
# `core/design-tokens.md` states it — "disabled 는 전용 disabled 색상
# 토큰(label 텍스트 포함)으로 표현, `Opacity`/`opacity-50` 은 disabled
# 전용 토큰이 없을 때만" — and a sweep moved 58 sites onto dedicated
# tokens. Nothing stopped the next one from arriving, so this does.
#
# ## Why a multiplier is the wrong tool
#
# An opacity multiply makes the resulting contrast depend on whatever is
# behind it. The same `opacity-50` passes over a light surface and fails
# WCAG 1.4.3 over a dark one, and the code cannot tell you which — the
# background is not in the expression. A dedicated token decides the
# value once, against a known pair, and holds.
#
# It also reads differently to the contrast guard: a token is a colour it
# can audit, a multiplier is an operation it cannot follow.
#
# ## What this counts
#
# Only the disabled path. A multiplier elsewhere — a fade transition, a
# scrim, a skeleton shimmer — is a legitimate use of opacity and is not
# the subject here.
#
# `opacity100` is *not* a violation and is deliberately excluded: it
# turns the generic fade off for a component that paints its own
# disabled tokens, which is the pattern this guard wants.

set -euo pipefail

# ratchet 기준값은 파일에 산다 — 이 스크립트 안의 상수가 아니다.
# 상수였을 때는 한 글자(`=0` → `=1`)가 위반 한 칸을 열었고, 그 한 글자가
# 통과 여부를 결정하는 **바로 그 PR 안에** 있었다. 파일이면 CODEOWNERS 의
# `/scripts/guards/**/*baseline*` 과 check_codeowners_ratchet_coverage.sh 가
# 그 diff 를 본다. 읽기 실패는 fail-closed 다 (lib/ratchet.sh 참조).
_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/ratchet.sh
. "$_GUARD_DIR/../lib/ratchet.sh"


cd "$(dirname "$0")/../../.."

# Web — a disabled utility class carrying a sub-100 opacity. Code lines
# only: several of these appear in doc comments describing the classes a
# component emits, and a comment dims nothing.
# 7 → 6: `CodeSnippet`'s line numbers stopped being dimmed by an `opacity-40`
# class and started carrying the 40 % in the COLOUR, which is where Core states it
# (`lineNumberAlpha`). The class went with the multiplier.
WEB_BASELINE=$(ratchet_int "$_GUARD_DIR/disabled_tokens_web_baseline.txt") || exit 1
web_count=$(
  grep -rnE '^[^/]*(disabled:opacity-|opacity-(1[0-9]|[2-9][0-9])\b)' \
    packages/coui_web/lib/src --include='*.dart' |
    grep -vc 'opacity-100' || true
)

# Flutter — an `Opacity` widget fed by the resolved disabled multiplier.
FLUTTER_BASELINE=$(ratchet_int "$_GUARD_DIR/disabled_tokens_flutter_baseline.txt") || exit 1
flutter_count=$(
  grep -rnc 'opacity: resolved\.disabledOpacity' \
    packages/coui_flutter/lib/src/components --include='*.dart' |
    awk -F: '{sum += $2} END {print sum + 0}'
)

fail=0

report() {
  local label="$1" count="$2" baseline="$3"
  echo "[$label] disabled expressed as a multiplier: $count (baseline $baseline)"
  if [ "$count" -gt "$baseline" ]; then
    echo "    ❌ net-new. Give the state a dedicated disabled colour token."
    echo "       A multiplier's contrast depends on the background, so the"
    echo "       same value passes on one surface and fails on another."
    fail=1
  elif [ "$count" -lt "$baseline" ]; then
    echo "    ✅ below baseline — lower the value in"
    echo "       scripts/guards/tokens/disabled_tokens_${label}_baseline.txt to $count."
    fail=1
  else
    echo "    ✅ no net-new."
  fi
}

report web "$web_count" "$WEB_BASELINE"
report flutter "$flutter_count" "$FLUTTER_BASELINE"

exit $fail
