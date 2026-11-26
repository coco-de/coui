#!/usr/bin/env bash
#
# `coui_lints` 의 `avoid_override_prefixed_resolved_field` 룰(#4942)이
# 지키려는 것 — `code-style/naming.md`: "resolved 필드는 이미 fallback 적용된
# 최종 값이라, `override*` 접두는 '아직 해결 안 됐을 수도' 라는 미해결 상태를
# 이름에 남긴다." (text_field/select/button/popover 재발 방지.)
#
# 그 룰은 INFO severity 라 `dart analyze . --fatal-warnings` 를 통과하고,
# 실측(2026-09-17)으로는 이 SDK 의 CLI `dart analyze` 에 coui_lints 진단이
# severity 와 무관하게 **아예 뜨지 않는다**(9 룰 전부 0건). 그래서 이 가드가
# 유일한 그물이다.
#
# 룰이 잡는 것은 정확히: `Resolved[A-Z]...` 로 시작하는 클래스의 **필드
# 선언**(`FieldDeclaration` — getter 는 `MethodDeclaration` 이라 제외, static
# 필드는 포함)이 `override[A-Z]...` 이름을 가질 때. 초기화식 유무와 무관하게
# AST 는 잡지만, 이 가드는 초기화식 없는 `Type name;` 형태만 본다(아래 참조).
#
# WHAT THIS DOES NOT COVER:
#   · **클래스 스코프를 모른다** — `Resolved*` 가 아닌 클래스의 `override*`
#     필드도 이 가드는 잡는다(룰보다 엄격). 오늘 그런 필드가 0개라 baseline
#     에 영향 없지만, 새로 생기면 이 가드가 먼저 걸린다 — 그건 오탐이 아니라
#     `code-style/naming.md` 가 이미 금지하는 이름이므로 고치는 게 맞다.
#   · **초기화식이 붙은 필드**(`final int overrideX = 3;`)는 못 본다 — `=`
#     를 거르는 것이 resolver 지역 변수(`final overrideColor = merged.x;`)와
#     클래스 필드(`required this.x` 로 생성자 초기화, `Type name;` 모양)를
#     가르는 유일한 신호이기 때문이다. 이 트레이드오프로 놓치는 것은
#     `Resolved*` 필드 중 초기화식 있는 형태(오늘 실측 67개, 전체 2758개
#     중 약 2.4%) — 대부분 `Type name;` 모양이라 커버리지는 높다.
#   · **타입과 이름이 다른 줄로 접힌 선언**은 줄 단위 grep 이 못 본다
#     (포매터가 긴 이름을 줄바꿈할 때).
#   · **한 줄에 여러 변수**(`final Color? overrideA, overrideB;`)는 AST 가
#     진단 2건인데 이 가드는 위반 줄 1개로 센다 — 줄은 드러나므로 놓치지는
#     않지만 건수가 갈린다.
#   · analyzer 의 `exclude:` 글롭(생성물 · `*_test.dart`)을 따른다.

set -euo pipefail

_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/ratchet.sh
. "$_GUARD_DIR/../lib/ratchet.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$REPO_ROOT"

BASELINE_COUNT=$(ratchet_int "$_GUARD_DIR/override_prefixed_resolved_field_baseline.txt") || exit 1

# `Type name;` 또는 `Type name,` 모양만 — `=` 로 끝나는 초기화식이 붙은 줄은
# 구조적으로 제외된다(resolver 지역 변수 `final x = expr;` 과 구별하는 신호).
hits="$(grep -rnE '^[[:space:]]*[A-Za-z_][A-Za-z0-9_<>?,.[:space:]]*[[:space:]]override[A-Z][A-Za-z0-9_]*[[:space:]]*[;,]$' \
  app docs_core docs_site packages tool --include='*.dart' 2>/dev/null \
  | grep -vE '\.(g|freezed|config|module|mock|gr|gm)\.dart:' \
  | grep -vE '(^|/)[^/]*_test\.dart:' || true)"

violations=0

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  echo "✗ ${line}"
  echo "    Resolved* 필드가 'override' 접두를 가지면 안 된다 — resolved 필드는"
  echo "    이미 fallback 이 적용된 최종 값이다. 접두 없는 이름으로 바꿔라"
  echo "    (code-style/naming.md 참조)."
  echo
  violations=$((violations + 1))
done <<< "$hits"

if (( violations > BASELINE_COUNT )); then
  echo "✗ avoid_override_prefixed_resolved_field: net-new 위반 $((violations - BASELINE_COUNT))건."
  exit 1
fi

echo "✅ avoid_override_prefixed_resolved_field: net-new 0 (baseline ${BASELINE_COUNT}건 유지)."
