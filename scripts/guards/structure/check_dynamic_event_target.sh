#!/usr/bin/env bash
#
# `coui_lints` 의 `avoid_dynamic_event_target` 룰(#4942)이 지키려는 것 —
# `web-specifics.md` 가 적는 dart2js minification 함정: release(dart2js
# minified) 빌드는 dynamic getter call(`event.target` 류)을 mangled name 으로
# 컴파일하고, 컴파일 그래프가 바뀌면 그 매핑이 desync 해 런타임에 throw 한다.
# `debug serve` 는 정상 동작해 이 함정이 안 보인다 — release 에서만 죽는다.
#
# 그 룰은 INFO severity 라 `dart analyze . --fatal-warnings` 를 통과하고,
# 실측(2026-09-17)으로는 이 SDK 의 CLI `dart analyze` 에 coui_lints 진단이
# severity 와 무관하게 **아예 뜨지 않는다**(9 룰 전부 0건). 그래서 이 가드가
# 그 함정을 막는 유일한 그물이다.
#
# 룰이 잡는 것은 정확히 둘(OR) — ① 파라미터 이름이 정확히 `event` 이고 타입이
# 명시적으로 `dynamic`인 것(`{dynamic event}` 포함, 타입 생략은 대상 아님),
# ② `(expr as dynamic)` 뒤 `.property` **읽기**(null-aware/캐스케이드 포함,
# 호출은 MethodInvocation 이라 룰 자체도 못 봄).
#
# WHAT THIS DOES NOT COVER:
#   · 여러 줄로 쪼개진 형태(`dynamic\n  event,` 나 긴 체인이 dart format 에
#     의해 줄바꿈된 `.property`)는 줄 단위 grep 이 원리적으로 못 본다.
#   · 토큰 사이에 낀 block/line 주석(`dynamic /* … */ event`)은 매칭이 깨진다.
#   · 캐스트를 변수에 담아 나중에 읽는 형태(`final d = event as dynamic;
#     d.target;`)는 AST 룰 자신도 못 본다(parent 가 VariableDeclaration).
#   · analyzer 의 `exclude:` 글롭(생성물 · `*_test.dart` · 플랫폼 빌드 산출물)
#     을 그대로 따른다 — 그 파일들은 룰도 안 본다.

set -euo pipefail

_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/ratchet.sh
. "$_GUARD_DIR/../lib/ratchet.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$REPO_ROOT"

BASELINE_FILE="packages/coui_lints/lib/src/rules/avoid_dynamic_event_target_rule.dart"
BASELINE_COUNT=$(ratchet_int "$_GUARD_DIR/dynamic_event_target_baseline.txt") || exit 1

# analyzer 의 analysis_options.yaml exclude: 를 따른다 — 생성물 / 테스트 /
# 플랫폼 빌드 산출물은 룰도 안 보므로 이 가드도 안 본다.
hits="$(grep -rnE '\bdynamic[[:space:]]+event\b|as[[:space:]]+dynamic\)[[:space:]]*\??\.{1,2}[A-Za-z_]' \
  --include='*.dart' \
  --exclude='*.freezed.dart' --exclude='*.config.dart' --exclude='*.module.dart' \
  --exclude='*.mock.dart' --exclude='*.gr.dart' --exclude='*.gm.dart' --exclude='*.g.dart' \
  --exclude='*_test.dart' \
  --exclude-dir=build --exclude-dir=android --exclude-dir=ios --exclude-dir=web \
  --exclude-dir=windows --exclude-dir=macos --exclude-dir=linux \
  packages app tool docs_core docs_site docs 2>/dev/null \
  | grep -v '^packages/coui_mcp/' \
  | grep -v '^packages/coui_flutter/docs/' \
  | grep -vE '^[^:]+:[0-9]+:[[:space:]]*//' || true)"

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
  echo "    'dynamic event' 파라미터 또는 '(x as dynamic).프로퍼티' 캐스트다."
  echo "    release dart2js 빌드에서 mangled name desync 로 런타임 throw 할 수"
  echo "    있다 — packages/coui_web/lib/src/base/ui_events.dart 의"
  echo "    EventHandlers helper 로 target 캐스트를 격리해라."
  echo
  violations=$((violations + 1))
done <<< "$hits"

if (( baseline_seen > BASELINE_COUNT )); then
  echo "✗ ${BASELINE_FILE}"
  echo "    baseline 은 ${BASELINE_COUNT}건인데 ${baseline_seen}건 발견됐다."
  violations=$((violations + 1))
fi

if (( violations > 0 )); then
  echo "✗ avoid_dynamic_event_target: net-new 위반 ${violations}건."
  exit 1
fi

echo "✅ avoid_dynamic_event_target: net-new 0 (baseline ${BASELINE_COUNT}건 유지)."
