#!/usr/bin/env bash
#
# A-1 / G11 (#3996) — Figma 빌더의 **축 붕괴** ratchet.
#
# 무엇을 재는가: 빌더가 `defaultsBySize` / `defaultsByVariant` dispatch 테이블을
# **순회하지 않고 키 하나를 소스에 글자로 박아** 쓴 자리의 개수.
#
#     const md = BUTTON.sizes.defaultsBySize['md'];   ← 5개 중 하나만 씀
#     const variants = Object.entries(BUTTON.variants.defaultsByVariant);  ← 전수
#
# 왜 이것이 별도 가드인가: G7 은 빌더에 남은 **리터럴**(하드코딩 색·치수)을
# 세고, G10 은 Dart 필드가 **JSON 에 도달**했는지 센다. 둘 다 이 상태를 못 본다 —
# 데이터는 JSON 에 5개 다 실려 있고(G10 통과), 빌더는 리터럴 대신 JSON 을
# 읽으므로(G7 통과) 두 가드가 모두 green 인데 **캔버스에는 사이즈가 하나뿐**이다.
# Figma 는 컴포넌트 **이름 문자열**(`Variant=primary, Size=md`)을 읽어 우측
# 패널의 드롭다운을 만드는데, 이름에 `Size=` 가 한 번도 등장하지 않으면 그 축이
# 존재한다는 것조차 알 수 없다. 디자이너에게는 "노브가 없다" 로 나타난다.
#
# 참조 구현이 레포 안에 이미 있다 — Badge / ValidationBadge 는 두 축을 모두
# `Object.entries(...)` 로 순회하며 `Variant=${vn}, Size=${sn}` 조합 셋을 만든다.
# 전환은 그 패턴을 복제하는 일이다.
#
# ⚠️ 전환 시 함정: `mountSet` 의 정체성 보존은 variant 이름 문자열로 기존
# 컴포넌트를 찾는다. 축을 추가하면 `Variant=primary` → `Variant=primary, Size=md`
# 로 이름이 바뀌어 기존 컴포넌트를 못 찾고 새로 만든다 → 디자이너가 그 컴포넌트로
# 만든 인스턴스가 전부 끊긴다. `src/renames.ts` 에 structural migration 을 같이
# 등록해야 하고, `src/variant-safety.ts` 의 `npm run selftest` 가 그것을 검증한다.
#
# ratchet 을 버리고 표의 행 수를 본다 — 개수는 이 가드가 재려던 것을 잴 수 없었다.
#
# 이 가드는 남은 자리들이 "키가 하나뿐인 무해한 부분집합" 이라고 적어두고, 세는
# 이유를 "누군가 두 번째 variant 를 Core 에 추가하는 순간 조용히 결손되므로
# ratchet 이 그 순간을 잡아야 한다" 고 썼다. **개수는 그 순간을 잡지 못한다** —
# Core 에 두 번째 variant 가 생겨도 하드코딩된 자리의 수는 그대로이고, 가드는
# green 을 유지한다. 정확히 잡겠다고 선언한 상태에 대해 구조적으로 눈이 없었다.
#
# 그래서 세지 않고, 각 자리가 **읽는 표의 행 수**를 본다:
#
#   행이 1개  →  접힌 것이 없다. 통과.
#   행이 2개+ →  캔버스에 그 축이 없다. 위반 — 그 자리를 순회로 바꾸거나,
#                자기 표가 아니라 **합성하는 자식의 행**이면 사유를 적는다.
#
# 이 형태에는 baseline 이 없다. 두 번째 variant 가 생기는 순간이 곧 red 이고,
# 통과하는 길은 숫자가 아니라 순회 또는 이름과 사유다.
#
# 자식의 행을 읽는 것은 위반이 아니다: 위젯 코드가 그 자식을 그 크기로 쓴다고
# 말하면(`Button(size: .sm)`) 그 행을 읽는 것이 그 진술을 옮기는 일이다.
# `figma_axis_collapse_allowlist.json` 이 그 자리이고, 각 항목은 why 를 가진다.
#
# 주석 라인 제외: `display.ts` 가 다른 빌더의 관례를 설명하며 이 패턴을 주석에
# 인용한다. 주석 언급은 하드코딩이 아니므로 세지 않는다 — 세면 그 주석을 고칠
# 때마다 카운트가 이유 없이 움직인다.
#
# ratchet: 내려가는 것만 허용.
#
# C1 population floor: 패턴이 매칭을 멈추면(헬퍼 rename · 파일 이동) 0 에 가까워져
# "축 붕괴가 다 사라졌다" 로 조용히 오판된다. 총합이 FLOOR 미만이면 grep 붕괴로
# 간주해 fail 한다 — 전환이 정상 진행돼 실제로 0 에 도달하면 그때 FLOOR 를 함께
# 내린다(그 편집이 곧 "전환 완료" 선언이다).
#
# Usage: check_figma_axis_collapse.sh [--report | --self-test]

set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

readonly ALLOWLIST="scripts/guards/structure/figma_axis_collapse_allowlist.json"
readonly BUILDERS="tools/figma-token-sync/src/components"
readonly DATA="tools/figma-token-sync/src/data/components.json"
readonly FLOOR=1

if [ ! -d "$BUILDERS" ]; then
  echo "❌ $BUILDERS 없음 — 경로가 바뀌었는지 확인해라."
  exit 1
fi

# 하드코딩 dispatch 접근을 뽑는다. 주석(`//` · `*` · `/*` 로 시작하는 라인) 제외.
#
# 양쪽 따옴표를 다 받는다. 레포는 작은따옴표를 쓰지만, 한 빌더 파일이
# 큰따옴표로 재포맷되자 그 파일의 하드코딩 3건이 **패턴에서 사라져** 카운트가
# 조용히 내려갔다 — 전환이 진행된 것처럼 보였고, baseline 을 그 숫자로 갱신하면
# 그 3건은 영구히 감사에서 빠진다. FLOOR 도 이걸 못 잡는다(총 붕괴만 본다).
# 스타일이 카운트를 바꾸면 ratchet 이 재는 것은 위반 수가 아니라 포맷이다.
hits() {
  # bracket 과 dot 두 표기 모두. dot 만 세지 않던 동안 6건이 보이지 않았고, 그
  # 구멍은 발견되는 대신 이용될 수 있었다 — 실제로 한 에이전트가 "bracket 으로
  # 쓰면 이 래칫이 4→5 로 올라 CI 가 빨강이 되니 dot 을 쓴다" 고 판단해 그렇게
  # 썼고(그 사실을 스스로 신고했다), 그 판단은 가드가 준 신호대로 옳았다.
  # 표기 차이로 세는 대상이 갈리면 가드는 규칙이 아니라 우회 안내가 된다.
  grep -rnE "defaults(BySize|ByVariant)(\[['\"][^'\"]+['\"]\]|\.[a-z][A-Za-z0-9]*)" "$BUILDERS"/*.ts 2>/dev/null |
    grep -vE ':[0-9]+:[[:space:]]*(//|\*|/\*)' || true
}

count() { hits | grep -c . || true; }

run_check() {
  local n
  n=$(count)

  if [ "$n" -lt "$FLOOR" ]; then
    echo "❌ A-1 grep 붕괴 의심 — 축 하드코딩 ${n}건 (FLOOR ${FLOOR} 미만)."
    echo "   전환이 실제로 끝났다면 이 스크립트의 FLOOR 도 같이 내려라."
    return 1
  fi

  # 각 자리가 읽는 표의 행 수를 components.json 에서 조회한다. 세는 것이 아니라
  # 판정하는 것이므로 baseline 이 없다.
  hits | A1_ALLOWLIST="$ALLOWLIST" A1_DATA="$DATA" \
    python3 scripts/guards/structure/figma_axis_collapse_judge.py
  return $?
}

self_test() {
  local rc=0 target backup
  target="$BUILDERS/display.ts"
  backup=$(mktemp)
  cp "$target" "$backup"

  echo "── self-test 1/2: 축 하드코딩 1건 주입 → red 확인"
  # 실제 빌더 코드 스타일(단순 대입 한 줄)로 주입한다 — 주석 안에 넣으면 이
  # 가드가 의도적으로 제외하므로 self-test 가 조용히 통과한다.
  perl -0pi -e "s/(\nfunction buildProgress)/\nconst a1SelfTestRegression = PROGRESS.sizes.defaultsBySize['md'];\n\$1/" "$target"

  if run_check >/tmp/a1_selftest_out.txt 2>&1; then
    echo "   ❌ self-test 실패 — 주입 후에도 green"
    cat /tmp/a1_selftest_out.txt
    rc=1
  else
    echo "   ✅ red 확인 (여러 행 표에서 키 하나 → fail)"
  fi

  cp "$backup" "$target"

  echo "── self-test 2/2: 되돌림 → green 확인"
  if run_check >/tmp/a1_selftest_out.txt 2>&1; then
    echo "   ✅ green 확인"
  else
    echo "   ❌ self-test 실패 — 되돌린 뒤에도 red (false positive)"
    cat /tmp/a1_selftest_out.txt
    rc=1
  fi

  rm -f "$backup" /tmp/a1_selftest_out.txt

  if [ "$rc" -eq 0 ]; then
    echo "✅ A-1 self-test 통과(주입→red · 되돌림→green)."
  else
    echo "❌ A-1 self-test 실패 — 위 단계 참고."
  fi
  return "$rc"
}

case "${1:-}" in
  --self-test)
    self_test
    exit $?
    ;;
  --report)
    echo "축 하드코딩 $(count)건:"
    hits | sed "s|$BUILDERS/||"
    exit 0
    ;;
  --update)
    # 갱신할 baseline 이 없다. 이 가드는 세지 않고 판정하므로, 숫자를 올려
    # 통과시키는 경로 자체가 사라졌다 — 여러 행 표에서 키 하나를 뽑은 자리는
    # 순회로 바꾸거나 allowlist 에 사유를 적는 것만이 답이다.
    echo "이 가드에는 baseline 이 없다 — --update 할 것이 없다."
    echo "여러 행 표를 접은 자리는 순회로 바꾸거나 $ALLOWLIST 에 why 와 함께 적어라."
    exit 1
    ;;
  *)
    run_check
    exit $?
    ;;
esac
