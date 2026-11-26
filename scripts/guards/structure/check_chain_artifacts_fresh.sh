#!/usr/bin/env bash
#
# chain 생성물 신선도 — 실측표(chain_axis_table)·tier1 name-set·T1 순열
# 렌더러(×2 플랫폼)·chain registry(×2)가 `*StyleChain` extension 표면 및
# T1 base 예제와 어긋나지 않았는지 본다. 생성기는 결정적이므로 커밋본이
# 재생성 결과와 다르면 소스 변경(getter 표면 또는 base 예제)이 생성물에
# 반영되지 않은 것 — 랜덤 토글이 "첫 클릭에 콘텐츠가 점프하는" 반쪽
# 동작으로 늦게 드러난다.
#
# baseline 없음 — 신선도는 이진값이라 ratchet 대상이 아니다.
#
# 방법: 생성기의 --check 모드가 재생성 결과를 파일에 쓰지 않고 메모리에서
# byte-compare 한다 — tracked 파일을 건드리지 않으므로 로컬 실행에
# 부작용이 없다(freshness 가드의 미커밋 변경 보호가 여기선 불필요).
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

dart tool/generate_chain_artifacts.dart --check >/dev/null 2>&1 || {
  echo "❌ chain 생성물이 소스와 어긋남(stale)"
  echo "   왜: *StyleChain 표면 또는 T1 base 예제가 바뀌었는데 생성물(실측표·tier1 set·순열 렌더러·registry)이 재생성되지 않았다"
  echo "   무엇을: dart tool/generate_chain_artifacts.dart --write 를 실행하고 diff 를 리뷰해 재생성 커밋을 올려라"
  dart tool/generate_chain_artifacts.dart --check 2>&1 | grep -E "drift|missing" || true
  exit 1
}
echo "✅ chain 생성물 fresh (실측표·tier1 set·렌더러·registry·md 스니펫 주입)"
