#!/usr/bin/env bash
#
# Gate: caller/widget chrome must not be injected through `classes` / `css`.
#
# Web passthrough has three surfaces (api.md):
#   - identity / semantic (id, role, aria, attributes) — passthrough OK
#   - behaviour (events)                                — passthrough OK
#   - STYLE (classes, css)                              — Core Style only
#
# `classes` / `css` are a Web-only surface with no Flutter counterpart, so
# letting a caller (or a widget) push *chrome* (bg / shadow / radius /
# border-colour / opacity / colour-text) through them is a second source of
# truth that Flutter can't mirror — chrome must flow through `CoreXxxStyle`
# slots + the resolver. Structural *layout* (flex / grid / gap / items-…)
# through `classes` is fine: it's the library parent→child layout the
# Flutter tree mirrors with widgets.
#
# So: a widget file must never carry a hardcoded **chrome** class literal —
# chrome comes from `resolved.<slot>` only. This gate catches the
# reintroduction of such literals. Same spirit as `check_design_tokens.sh`.
#
# Ratchet baseline: fails on NET-NEW violations.
#
# Usage: ./scripts/guards/structure/check_chrome_passthrough.sh
set -euo pipefail

# ratchet 기준값은 파일에 산다 — 이 스크립트 안의 상수가 아니다.
# 상수였을 때는 한 글자(`=0` → `=1`)가 위반 한 칸을 열었고, 그 한 글자가
# 통과 여부를 결정하는 **바로 그 PR 안에** 있었다. 파일이면 CODEOWNERS 의
# `/scripts/guards/**/*baseline*` 과 check_codeowners_ratchet_coverage.sh 가
# 그 diff 를 본다. 읽기 실패는 fail-closed 다 (lib/ratchet.sh 참조).
_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/ratchet.sh
. "$_GUARD_DIR/../lib/ratchet.sh"


DIR="packages/coui_web/lib/src/components"
BASELINE=$(ratchet_int "$_GUARD_DIR/chrome_passthrough_baseline.txt") || exit 1
status=0

# Chrome-prefix class literals (a string literal, no `$` interpolation) in a
# widget file. Colour-bearing `border-`/`text-` only (border-0 / text-sm are
# width / size = layout-ish, not chrome). Comment lines are excluded.
CHROME='(bg-[a-z]|shadow(-[a-z]+)?|rounded(-[a-z0-9]+)?|opacity-[0-9]|'
CHROME+='border-(primary|secondary|surface|outline|on-|muted|error|success|warning|info)|'
CHROME+='text-(primary|secondary|surface|outline|on-|muted|error|success|warning|info))'

# Scope: widget files only. `*_style.dart` is the resolver — that is exactly
# where chrome is *supposed* to be composed, so it is excluded.
#
# ⚠️ This used to glob `co_*.dart`. The `co_` prefix was dropped repo-wide and
# the glob was never updated, so the gate matched **zero files** and reported
# `0 (baseline 0) ✅` on every run — green while guarding nothing. Injecting a
# regression did not fail it. If you narrow this scope again, re-run the
# self-test below and confirm it still fails on an injected violation.
#
# The trailing `grep -v` drops CSS *property keys* in inline-style maps
# (`'text-shadow': …`) — a property name is not a Tailwind class, and the
# `shadow` alternative above matches inside it.
matches=$(grep -rnE "'[^'\$]*\b${CHROME}[a-z0-9/-]*[^']*'" \
  "$DIR" --include='*.dart' 2>/dev/null \
  | grep -v '_style\.dart:' \
  | grep -vE ':\s*(//|///|\*)' \
  | grep -vE "'[a-z-]+'\s*:" || true)

count=$(printf '%s' "$matches" | grep -c . || true)

echo "[1] chrome class literals in web widget files : $count  (baseline $BASELINE)"
if [ "$count" -gt "$BASELINE" ]; then
  echo "    ❌ NET-NEW chrome injected through a widget class literal."
  echo "       Chrome flows through CoreXxxStyle slots + resolver; a widget"
  echo "       reads chrome from resolved.<slot>.className only. Layout"
  echo "       (flex / grid / gap / items-…) via classes is fine. Offending:"
  printf '%s\n' "$matches" | sed 's/^/         /'
  status=1
elif [ "$count" -lt "$BASELINE" ]; then
  echo "    ✅ below baseline — lower the value in"
  echo "       scripts/guards/structure/chrome_passthrough_baseline.txt to $count."
else
  echo "    ✅ at baseline (no net-new)."
fi

if [ "$status" -eq 0 ]; then
  echo "✔ chrome-passthrough gate passed."
fi
exit $status
