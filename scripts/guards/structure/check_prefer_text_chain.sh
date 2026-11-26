#!/usr/bin/env bash
#
# `coui_lints` 의 `prefer_text_chain` 룰(#4942)은 INFO severity 라
# `dart analyze . --fatal-warnings` 를 통과한다 — 그리고 실측(2026-09-17)으로는
# 이 SDK 의 CLI `dart analyze` 에 `coui_lints` 진단이 severity 와 무관하게
# **아예 뜨지 않는다**(9 룰 전부 0건). 그래서 이 가드가 그 룰이 지키려던
# "raw `Component.text(...)` 대신 CoUI `Text` chain" 을 세는 유일한 그물이다.
#
# 룰이 잡는 것은 정확히: jaspr `Component` 의 생성자 `Component.text(...)`
# (tear-off 아님) 호출이며, 다음 두 경로만 면제한다.
#   ① `packages/coui_web/lib/src/components/{text,display/{code_diff,code_snippet,
#      mockup_code,kbd},control/command,form/{text_area,text_field}}/` 안 —
#      chain API 자신의 base 구현이거나 typography 상속이 무의미한 raw 경계.
#   ② 조상에 `Component.element(tag: 'style'|'script', ...)` 가 있는 payload —
#      `<style>`/`<script>` 의 raw 텍스트는 chain 이 의미가 없다.
#
# WHAT THIS DOES NOT COVER (grep 은 룰의 AST 근사일 뿐):
#   · 조상 체인을 못 본다 — ②의 style/script 면제를 grep 이 되짚지 못해,
#     그 유일한 실사례(overlay_host.dart)를 baseline 파일로 격리해 둔다.
#     새로 생기는 style/script payload 는 그 파일 안이 아니면 위반으로 샌다 —
#     발견되면 그 파일도 baseline 에 추가하거나(정말 그 형태면) 이 가드 자체를
#     조상 인식으로 고친다.
#   · 생성자 tear-off `Component.text`(괄호 없음)는 `ConstructorReference` 라
#     룰도 이 가드도 못 본다.
#   · `typedef C = Component;` 뒤 `C.text(...)` 처럼 타입 별칭을 경유하면
#     lexeme 이 'Component' 가 아니라 둘 다 놓친다.
#   · 변수/헬퍼에 담아 나중에 호출하는 간접 경유는 어떤 정적 검사도 못 본다.

set -euo pipefail

_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/ratchet.sh
. "$_GUARD_DIR/../lib/ratchet.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$REPO_ROOT"

TARGET_DIR="packages/coui_web/lib"
BASELINE_FILE="packages/coui_web/lib/src/overlay/overlay_host.dart"
BASELINE_COUNT=$(ratchet_int "$_GUARD_DIR/prefer_text_chain_baseline.txt") || exit 1

# 룰의 boundary 예외(4번 조건) — chain API 자신의 base 구현이거나 typography
# 상속이 무의미한 raw 경계. 여기 안의 Component.text 는 애초에 위반이 아니다.
BOUNDARY_RE='/components/(text/|display/(code_diff|code_snippet|mockup_code|kbd)/|control/command/|form/(text_area|text_field)/)'

hits="$(grep -rnE '(^|[^A-Za-z0-9_$])Component\.text\(' "$TARGET_DIR" --include='*.dart' 2>/dev/null \
  | grep -vE '^[^:]+:[0-9]+:[[:space:]]*//' \
  | grep -vE "$BOUNDARY_RE" || true)"

violations=0
baseline_seen=0

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  file="${line%%:*}"

  if [[ "$file" == "$BASELINE_FILE" ]]; then
    baseline_seen=$((baseline_seen + 1))
    continue
  fi

  echo "✗ ${line}"
  echo "    raw 'Component.text(...)' 대신 CoUI Text chain 을 쓴다 —"
  echo "    const Text('...').bodyMedium.onSurface 같은 형태."
  echo "    <style>/<script> payload 라면 조상에 Component.element(tag: 'style'|'script')"
  echo "    가 있는지 확인 — 그렇다면 이 가드가 조상을 못 봐서 오탐이다,"
  echo "    prefer_text_chain_baseline.txt 에 이 파일을 등록해라."
  echo
  violations=$((violations + 1))
done <<< "$hits"

if (( baseline_seen > BASELINE_COUNT )); then
  echo "✗ ${BASELINE_FILE}"
  echo "    baseline 은 ${BASELINE_COUNT}건인데 ${baseline_seen}건 발견됐다."
  echo "    baseline 은 이미 있던 것만 담는다 — 새 Component.text(...) 호출의"
  echo "    은신처가 아니다."
  violations=$((violations + 1))
fi

if (( violations > 0 )); then
  echo "✗ prefer_text_chain: net-new 위반 ${violations}건."
  exit 1
fi

echo "✅ prefer_text_chain: net-new 0 (baseline ${BASELINE_COUNT}건 유지)."
