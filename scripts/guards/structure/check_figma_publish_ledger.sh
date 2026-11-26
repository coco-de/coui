#!/usr/bin/env bash
# Figma 플러그인 게시 원장이 읽을 수 있는 상태이고, 그것을 쓰고 읽는 두 워크플로가
# 살아 있는지 본다 (#4633).
#
# 왜 이 가드가 있나 — 게시 원장(`tools/figma-token-sync/PUBLISHED.json`)은 "지금
# Community 에 올라간 것이 어느 커밋인가" 의 유일한 기록이다. 그런데 그것을
# 판정하는 잡은 main 푸시에서만 돌고, 기록하는 워크플로는 사람이 dispatch 할
# 때만 돈다 — 둘 다 PR 에서는 실행되지 않는다. 그래서 원장을 손으로 깨뜨리거나
# 워크플로 한쪽의 배선을 지우는 PR 은 초록으로 머지되고, 그 결과(추적 이슈가 안
# 열림 · 기록 dispatch 가 실패)는 다음 게시 때에야 드러난다. 이 가드는 그 셋을
# PR 에서 본다:
#
#   1. 원장이 세 상태 중 하나로 읽힌다 — 미기록(전부 null) 또는 완전한 기록.
#      반쯤 쓴 원장은 실패다(판정 잡이 그걸 어떻게 읽을지 정의되지 않는다).
#   2. 판정 잡과 기록 워크플로가 같은 스크립트(`publish-fingerprint.mjs`)를
#      부른다 — 한쪽이 다른 지문을 재면 영원히 drift 다.
#   3. 원장이 CODEOWNERS 에 걸려 있다 — 손으로 고친 편집이 오너에게 보이도록.
#
# 보지 않는 것: 지문 자체가 맞는지(번들을 굽지 않는다 — 그건 main 푸시의 판정
# 잡이 한다), 그리고 실제로 게시가 됐는지(리포는 그걸 알 수 없다).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

fail=0
plugin="tools/figma-token-sync"
script="$plugin/scripts/publish-fingerprint.mjs"
record=".github/workflows/figma-plugin-publish-record.yaml"
package=".github/workflows/figma-plugin-package.yaml"

# 원장의 문법은 `publish-fingerprint.mjs` 하나가 소유한다(`parseLedger`) — 판정
# 잡과 기록 워크플로가 부르는 그 함수로 읽는다. 이 잡은 SDK 없는 셀프호스티드
# 러너라 node 가 PATH 에 없을 수 있다(플러그인을 안 건드린 PR 은 Setup Node 를
# 건너뛴다). 그때는 건너뛰지 않고 python 으로 **모양만** 본다 — 전부 null 이거나
# 전부 비지 않은 문자열 — 그리고 그렇게 했다고 말한다.
if command -v node >/dev/null 2>&1; then
  if ! out="$(cd "$plugin" && node scripts/publish-fingerprint.mjs validate 2>&1)"; then
    echo "❌ 게시 원장을 읽을 수 없다 — $out"
    fail=1
  else
    state="$(printf '%s' "$out" | sed -n 's/.*"state":"\([a-z]*\)".*/\1/p')"
  fi
else
  echo "ℹ️  node 없음 — 원장은 python 으로 모양만 본다(전체 문법은 판정 잡이 main 에서 본다)."
  if ! state="$(python3 - "$plugin/PUBLISHED.json" <<'PY'
import json, sys
fields = ["publishFingerprint", "sharedSourceHash", "commitSha", "figmaVersionLabel", "publishedAt", "publishedBy"]
v = json.load(open(sys.argv[1], encoding="utf-8"))
if not isinstance(v, dict) or any(f not in v for f in fields):
    sys.exit("원장에 필드가 빠졌다")
vals = [v[f] for f in fields]
if all(x is None for x in vals):
    print("unrecorded")
elif all(isinstance(x, str) and x for x in vals):
    print("recorded")
else:
    sys.exit("반쯤 쓴 원장이다")
PY
)"; then
    echo "❌ 게시 원장을 읽을 수 없다"
    fail=1
  fi
fi

[ -f "$script" ] || { echo "❌ $script 없음"; fail=1; }

if [ ! -f "$record" ]; then
  echo "❌ $record 없음 — 게시를 기록할 경로가 없다"
  fail=1
else
  grep -q 'workflow_dispatch:' "$record" || { echo "❌ $record 가 dispatch 워크플로가 아니다"; fail=1; }
  grep -q 'publish-fingerprint.mjs record' "$record" || { echo "❌ $record 가 publish-fingerprint.mjs record 로 원장을 쓰지 않는다"; fail=1; }
fi

if ! grep -q 'publish-fingerprint.mjs check' "$package"; then
  echo "❌ $package 에 drift 판정(publish-fingerprint.mjs check)이 없다"
  fail=1
fi

if ! grep -qE '^/tools/figma-token-sync/PUBLISHED\.json[[:space:]]+@' .github/CODEOWNERS; then
  echo "❌ .github/CODEOWNERS 에 /tools/figma-token-sync/PUBLISHED.json 이 없다"
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "✅ 게시 원장 읽힘(${state:-?}) · 기록 워크플로 · drift 판정 · CODEOWNERS 배선 확인."
