#!/usr/bin/env bash
#
# G1 (0번 가드) — 플러그인 번들에 들어가는 생성 데이터의 신선도:
#   - `components.json`  ← `export_figma_components.dart`
#   - `brands.json`      ← `export_figma_tokens.dart` (코드 브랜드의 값 표 — 소비 파일의
#                          브랜드 확장 컬렉션을 채우는 값이라 토큰을 붙여넣지 않는 파일에서도
#                          플러그인이 들고 있어야 한다)
#   - `content-colors.json` ← `export_figma_tokens.dart` (글리프가 슬롯에서 받는 색 —
#                          `Semantic/ Content` · `Semantic/ Content Status` 의 모드 목록.
#                          Generate 가 토큰을 모드로 바꾸는 어휘이고 하네스가 컬렉션을 시드하는
#                          출처라, 컬렉션을 만드는 목록과 같은 실행에서 나온다)
# exporter 는 결정적인데(2회 실행 md5 동일) 커밋본이 소스와 어긋나 31일간 아무도
# 몰랐다(#3732). 재생성을 강제하는 CI 가 없었기 때문이다. 이 가드가 그 CI 다.
#
# baseline 없음 — 신선도는 이진값이라 ratchet 대상이 아니다(항목 목록으로
# "일부만 허용"할 축이 없다: 커밋본이 재생성 결과와 같거나(fresh) 다르거나
# (stale) 둘 중 하나).
#
# 방법(대상마다 같다): exporter 를 실제로 재실행해 tracked JSON 을 그 결과로 덮어쓰고
# `git diff --exit-code` 로 커밋본과의 편차를 본다. diff 가 있으면 커밋본이
# 소스보다 stale 하다는 뜻 — 재생성 커밋이 필요하다.
#
# C1 모집단 하한: 추출이 붕괴해(빈 컴포넌트 맵 등) 재생성 결과가 텅 비면,
# 커밋본도 우연히 비슷하게 작을 경우 diff 가 작아 보이거나 0 이 되어
# "신선함"으로 조용히 통과할 위험이 있다. 그래서 diff 결과와 무관하게
# 재생성된 파일 자체의 바이트 크기를 하한과 비교해 별도로 unblock한다.
# ⚠️ 이 값은 이슈 초안의 20000 이 아니다 — 실측 현재 크기가 17805 바이트
# (10 컴포넌트, #3732 재생성 기준)라 20000 은 항상 red 가 되는 깨진 가드를
# 만든다. 10000 은 현재 건강한 크기의 절반 수준으로, 진짜 붕괴(빈 JSON 근처,
# 수백 바이트)는 여유 있게 잡으면서 오늘의 fresh 상태는 통과시킨다. 커버리지
# 확장(10→145, Epic E) 이후 파일이 커지면 이 상수도 같이 올린다.
#
# 미커밋 변경 보호: 로컬에서 이 가드를 돌리면 exporter 가 tracked 파일을
# 덮어쓴다. 실행 전 대상 파일이 이미 modified 상태면 그 변경을 덮지 않고
# 보고만 한다(.claude/rules/process/workflow.md — destructive 명령은 명시
# 허락만). 시작이 clean 이었다면 검사 후 원래 커밋 상태로 되돌려 로컬 실행이
# 부작용을 남기지 않는다.
#
# CI 배선: `dart analyze` 뒤에 두지 않는다 — GitHub Actions 는 실패한 스텝
# 이후를 skip 하므로, 무관한 analyzer warning 하나가 이 가드를 조용히
# 건너뛰게 만든다. 이 스크립트를 부르는 CI 스텝은 `if: always()` 를 쓴다.
#
# Usage:
#   ./scripts/guards/structure/check_figma_export_fresh.sh              # 정상 실행
#   ./scripts/guards/structure/check_figma_export_fresh.sh --self-test  # C4 4단 검증
set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

TARGET="tools/figma-token-sync/src/data/components.json"
EXPORTER="packages/coui_core/bin/export_figma_components.dart"
FLOOR_BYTES=10000

fail3() {
  # C5 — 무엇이 틀렸나 / 왜 위험한가 / 무엇을 하라.
  echo "❌ $1"
  echo "   왜: $2"
  echo "   무엇을: $3"
}

run_check() {
  local floor_test="${1:-0}"

  if [ ! -f "$TARGET" ]; then
    fail3 "$TARGET 이 없음" "가드가 검사할 대상 파일 자체가 없다" "경로 확인(파일이 이동했다면 이 가드도 갱신)"
    return 1
  fi

  local pre_dirty=0
  if ! git diff --quiet -- "$TARGET" || ! git diff --cached --quiet -- "$TARGET"; then
    pre_dirty=1
  fi

  if [ "$pre_dirty" -eq 1 ]; then
    echo "⚠️  $TARGET 에 이미 커밋되지 않은 변경이 있음 — 덮어쓰지 않고 신선도 검사를 건너뜀."
    echo "   (destructive 명령은 명시 허락만 — 진행 중인 로컬 작업을 보호)"
    return 0
  fi

  if [ "$floor_test" = "1" ]; then
    # self-test 전용: 실제 exporter 를 부르지 않고 "붕괴한 추출"을 흉내낸다
    # (빈 컴포넌트 맵) — 진짜 toolchain 을 망가뜨리지 않고 C1 하한이
    # 실제로 fire 하는지 검증하기 위함.
    printf '{"components":{}}' >"$TARGET"
  elif ! dart run "$EXPORTER" >/tmp/figma_export_fresh.log 2>&1; then
    fail3 "exporter 실행 실패" "신선도를 판정할 수 없다" "dart run $EXPORTER 를 직접 실행해 에러 확인"
    cat /tmp/figma_export_fresh.log
    git checkout -- "$TARGET"
    return 1
  fi

  local size
  size=$(wc -c <"$TARGET" | tr -d ' ')

  if [ "$size" -lt "$FLOOR_BYTES" ]; then
    fail3 \
      "재생성된 $TARGET 이 ${size} 바이트 — 하한 ${FLOOR_BYTES} 바이트 미달" \
      "추출이 붕괴했을 가능성(빈 컴포넌트 맵 등) — 이 상태에서 diff 0 이 나오면 '신선함'으로 조용히 오판된다" \
      "dart run $EXPORTER 를 직접 실행해 컴포넌트 카운트를 확인하라"
    git checkout -- "$TARGET" 2>/dev/null || true
    return 1
  fi

  if git diff --quiet -- "$TARGET"; then
    echo "✅ $TARGET 이 소스와 일치 — fresh."
    return 0
  fi

  fail3 \
    "$TARGET 이 소스와 어긋남(stale)" \
    "exporter 는 결정적인데 커밋본이 다르면, 최근 coui_core 변경이 Figma 산출물에 반영되지 않은 것 — 디자이너가 사실과 다른 값을 본다" \
    "dart run $EXPORTER 를 실행하고 diff 를 리뷰해 재생성 커밋을 올려라"
  git diff --stat -- "$TARGET"
  # 다음 실행이 다시 clean 상태에서 시작하도록 원복(로컬 실행 부작용 방지).
  # CI 는 매번 새 checkout 이라 이 라인이 없어도 무해하지만, 로컬 반복
  # 실행 시 "한 번 stale 을 봤으니 계속 stale" 로 착각하지 않게 한다.
  git checkout -- "$TARGET"
  return 1
}

self_test() {
  local rc=0
  local start_sha
  start_sha=$(git rev-parse HEAD)

  # run_check 의 "미커밋 변경 보호"는 사용자 WIP 을 지키기 위한 것이고,
  # 그 판정은 실행 *시작* 시점의 git diff 로 이루어진다. "재생성 없이
  # 커밋된 stale 값"을 흉내내려면 주입한 값이 그 시작 시점에 이미
  # committed(=git diff clean) 상태여야 한다 — 그래서 uncommitted 로
  # 남기지 않고 임시 커밋한 뒤 self-test 끝에서 원래 SHA 로 되돌린다.
  echo "── self-test 1/3: 회귀 주입(재생성 없이 커밋) → red 확인"
  python3 - "$TARGET" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
data["components"]["button"]["variants"]["outline"]["borderColor"]["color"] = "___G1_SELF_TEST_REGRESSION___"
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
  git add "$TARGET"
  # `--` 로 pathspec 을 제한하지 않는다 — 이미 add 로 이 파일만 staged 라
  # 불필요하고, 로컬 git-attribution 래퍼가 `-m` 트레일러를 인자 끝에
  # 덧붙이는 방식이라 `--` 뒤에 오면 그 트레일러까지 pathspec 으로 오인된다.
  git commit -q -m "chore(self-test): G1 회귀 주입 — 리셋 예정"
  if run_check; then
    echo "   ❌ self-test 실패 — 회귀 주입 후에도 green (diff 판정이 동작하지 않음)"
    rc=1
  else
    echo "   ✅ red 확인"
  fi

  echo "── self-test 2/3: 되돌림 → green 확인"
  git reset --hard -q "$start_sha"
  if run_check; then
    echo "   ✅ green 확인"
  else
    echo "   ❌ self-test 실패 — 되돌린 뒤에도 red (false positive)"
    rc=1
  fi

  echo "── self-test 3/3: C1 모집단 하한 — 추출 붕괴(빈 컴포넌트 맵) 시뮬레이션 → red 확인"
  if run_check 1; then
    echo "   ❌ self-test 실패 — 붕괴 시뮬레이션이 green (C1 하한이 동작하지 않음)"
    rc=1
  else
    echo "   ✅ C1 하한이 fire 함"
  fi

  # 안전망 — 세 단계 모두 자체 정리하지만, 어느 하나가 중간에 실패해도
  # self-test 가 저장소를 시작 SHA 로 확실히 되돌린다.
  git reset --hard -q "$start_sha"

  if [ "$rc" -eq 0 ]; then
    echo "✅ G1 self-test 전부 통과(주입→red · 되돌림→green · C1 하한→red)."
  else
    echo "❌ G1 self-test 실패 — 위 단계 참고."
  fi
  return "$rc"
}

if [ "${1:-}" = "--self-test" ]; then
  # 회귀 주입 · 되돌림은 `components.json` 의 경로로 돈다 — `brands.json` 은 같은 `run_check` 를
  # 다른 대상으로 부르는 것뿐이라 판정 코드는 같다.
  self_test
  exit $?
fi

rc=0
run_check || rc=1

# 두 번째 대상 — 코드 브랜드의 값 표. `run_check` 는 전역 TARGET / EXPORTER / FLOOR_BYTES 를
# 읽으므로 바꿔서 한 번 더 부른다. 하한 20000 은 오늘 크기(약 120KB)의 한참 아래라 표가
# 텅 비는 붕괴만 잡는다.
TARGET="tools/figma-token-sync/src/data/brands.json"
EXPORTER="packages/coui_core/bin/export_figma_tokens.dart"
FLOOR_BYTES=20000
run_check || rc=1

# 세 번째 대상 — 글리프 색 어휘. 하한 400 은 오늘 크기(약 1KB)의 절반 아래라, 모드 목록이
# 비는 붕괴만 잡는다.
TARGET="tools/figma-token-sync/src/data/content-colors.json"
FLOOR_BYTES=400
run_check || rc=1
exit "$rc"
