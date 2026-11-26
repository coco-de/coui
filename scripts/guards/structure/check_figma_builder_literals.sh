#!/usr/bin/env bash
#
# G7 (#3756) — Figma 빌더 색·치수 리터럴 카운트 ratchet. **이 프로젝트의
# 성공 판정.**
#
# 왜 이 가드가 유일한가: G1~G6·G8·G9 는 전부 "JSON 에 필드가 있는가" 만
# 잰다 — G1 은 JSON 이 소스와 같은지, G2 는 레지스트리 이름이 맞는지, G3 은
# 필드 센서스, G6 은 tsc 타입, G8/G9 는 토큰 값 중복. exporter 가 145 Style
# 을 전수 순회해 JSON 이 1,290 필드로 차도, **빌더가 여전히 10개만 그 JSON
# 을 읽으면** 나머지 91개는 하드코딩된 값을 그대로 그린다 — 디자이너가
# Figma 에서 보는 픽셀은 거의 안 바뀐다. 위 아홉 가드 중 어느 것도 이 상태를
# 볼 수 없다(G3 은 "JSON 에 키가 있는가" 만 세지, "빌더가 그 키를 읽는가"
# 는 안 본다). 이 가드가 그 유일한 그물이다.
#
# 방법: PRD FR-007 AC-2 가 이미 요구하던 것 — tools/figma-token-sync/src/
# components/**.ts 의 색 리터럴(`lk.sem('name')` / `fillSem(..., 'name')` /
# `setBorder(..., 'name')` / `ChromeOpts.bg|border: 'name'`) + 치수 리터럴
# (#3753 이 number|Dim 로 넓힌 13개 헬퍼 — bindSize/bindRadiusN/
# indicatorBox/applyFormRowChrome/lockWidth/layoutSet/wrapSet 의 직접 인자,
# 그리고 panel/applyChrome(ChromeOpts)·makeLabel/glyphOpts(LabelOpts) 의
# size/radius/gap/pl/pr/pt/pb/strokeN/bgOp/borderOp 필드 — 에 박힌 숫자
# 리터럴) 총 개수를 baseline 과 비교한다. 빌더가 data.ts 로 전환되면 그
# 리터럴이 사라지고 카운트가 내려간다 — baseline 은 그 방향으로만 움직인다.
#
# bindPad 는 함수-스코프 패턴(두 번째 대체군)으로 잡는다 — project/3720의
# Epic F(#3726)가 `bindPad(node, lk, {pl,pr,pt,pb})` 를 PadData 유니온
# (`{l,r,t,b}` 물리 / `{start,t,end,b}` 논리)으로 재설계해 키 이름 자체가
# 바뀌었다. 키-이름 기반(`pl|pr|pt|pb`) 패턴에 `l|r|t|b`/`start|end` 를
# 더하면 파일 전역의 무관한 `t:`/`b:` 같은 흔한 짧은 키까지 오탐하므로,
# 대신 `bindSize`/`bindRadiusN` 과 같은 방식으로 "그 호출의 괄호 안에 숫자가
# 있는가" 만 본다 — 오탐 없이 새 키 이름을 그대로 커버한다.
#
# C1 population floor: 패턴이 더 이상 매칭하지 않으면(파일 이동·구조 변경·
# 헬퍼 rename) 카운트가 0 에 가까워져 "리터럴이 다 사라졌다"로 조용히
# 오판된다. 총합이 FLOOR 미만이면 grep 붕괴로 간주해 fail — 그 하한이 왜 1 인지는
# `FLOOR=` 선언 옆에 적는다(200 이었고, 진짜 진전에 red 를 냈다).
#
# allowlist ratchet — "skip 을 늘리는 것 자체가 막혀야 한다": 리터럴을 남길
# 정당한 사유(builder-original — 코어에 대응 default 없음, #3755 OQ-2)가
# 있으면 allowlist 에 파일명 + 사유를 적어 그 파일을 카운트에서 제외할 수
# 있다. 단 allowlist "항목 수" 자체도 ratchet 대상이다 — 안 그러면 "리터럴을
# allowlist 로 옮기기" 로 카운트를 낮추는 우회가 가능해진다.
#
# Usage:
#   ./scripts/guards/structure/check_figma_builder_literals.sh              # 정상 실행
#   ./scripts/guards/structure/check_figma_builder_literals.sh --self-test  # C4 4단 검증
set -uo pipefail

# ratchet 기준값은 파일에 산다 — 이 스크립트 안의 상수가 아니다.
# 상수였을 때는 한 글자(`=0` → `=1`)가 위반 한 칸을 열었고, 그 한 글자가
# 통과 여부를 결정하는 **바로 그 PR 안에** 있었다. 파일이면 CODEOWNERS 의
# `/scripts/guards/**/*baseline*` 과 check_codeowners_ratchet_coverage.sh 가
# 그 diff 를 본다. 읽기 실패는 fail-closed 다 (lib/ratchet.sh 참조).
_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/ratchet.sh
. "$_GUARD_DIR/../lib/ratchet.sh"

cd "$(dirname "$0")/../../.." || exit 1

TARGET_DIR="tools/figma-token-sync/src/components"
BASELINE_FILE="scripts/guards/structure/figma_builder_literals_baseline.txt"
ALLOWLIST_FILE="scripts/guards/structure/figma_builder_literals_allowlist.txt"
# C1 — 패턴이 살아 있는지의 하한. 1 이고, 그 이유는 이 게이트가 한 번 그것 때문에
# 진짜 진전에 red 를 낸 뒤에 적는다.
#
# 200 이었다. 근거는 "실측 총합 ~1131 이므로 정상적인 전환으로는 한참 못 미친다"
# 였고 그것이 참인 동안에는 좋은 하한이었다. 미설명이 0 이 되고 발판이 197 로
# 줄자 population 이 하한을 밑돌아, **리터럴을 없앤 것이 grep 붕괴로 보고됐다.**
#
# 이 스크립트의 self-test 주석이 이미 그 규칙을 적어뒀다 — "검사를 개선이
# 무력화한다면 그건 검사의 결함이다". 총합의 크기는 패턴의 생존을 묻는 잘못된
# 질문이고, 옳은 질문("패턴이 여전히 매칭하는가")은 self-test 가 이미 답한다:
# 리터럴 하나를 주입해 red 를 확인하고 되돌려 green 을 확인한다. population ≥ 1
# 은 그 위의 최소한이다 — 0 이면 아무것도 매칭하지 않았다는 뜻이고, 그때만
# "다 사라졌다" 라는 오판이 가능하다.
FLOOR=1
# 프리뷰 발판으로 표시된 리터럴 수 — 상한이 아니라 **보고**다.
#
# 이 수에는 baseline 이 있었고(0 → 160 → 203), 그 근거는 옳았다: "마커를 붙이는
# 것만으로 미설명 카운트를 내릴 수 있으면 그것이 우회다. 양쪽을 같이 잠가야
# '설명을 쓰는 행위' 가 비용을 갖는다."
#
# 미설명이 **하드 0** 이 되면서 그 우회가 닫혔다 — 0 은 더 내릴 수 없으므로, 마커를
# 붙여 낮출 카운트가 남아 있지 않다. 리터럴을 하나 추가하는 유일한 길은 그 줄에
# 사유를 쓰는 것이고, 사유는 리터럴 옆에 있어 diff 에서 읽힌다. 그것이 G16 과 G14 가
# 도달한 것과 같은 계약이다 — 통과하는 길은 배선이거나 이름과 사유다.
#
# 그래서 숫자를 없앴다. 남은 것은 매 실행마다 찍히는 수와, 사유 없는 마커를 거부하는
# 패턴 검사다(MARKER 는 `g7-preview-only:` 뒤에 공백이 아닌 문자를 요구한다 —
# 형식적 사유는 그 자리에서 걸린다).
#
# 이 수를 상한으로 되돌리고 싶어지는 순간이 있을 것이다: 발판이 쌓이는 것을 막고
# 싶을 때. 그건 진짜 걱정이지만 숫자는 그것을 재는 나쁜 도구다 — 정당한 새 프리뷰마다
# 올려야 하고, 올리는 것이 곧 통과이므로 결국 형식이 된다. 발판이 너무 많다는 판단은
# 그 사유들을 읽어서 하는 것이고, 사유는 코드에 있다.
ALLOWLIST_BASELINE=$(ratchet_int "$_GUARD_DIR/figma_builder_literals_allowlist_baseline.txt") || exit 1

COLOR_PATTERN="\\.sem\\([^)]*'[a-z][a-z0-9-]*'|fillSem\\([^)]*'[a-z][a-z0-9-]*'|setBorder\\([^)]*'[a-z][a-z0-9-]*'|\\bbg:[[:space:]]*'[a-z][a-z0-9-]*'|\\bborder:[[:space:]]*'[a-z][a-z0-9-]*'"
DIM_PATTERN="\\b(size|radius|gap|pl|pr|pt|pb|strokeN|bgOp|borderOp):[[:space:]]*[0-9]+(\\.[0-9]+)?\\b|\\b(bindSize|bindRadiusN|indicatorBox|applyFormRowChrome|lockWidth|layoutSet|wrapSet|bindPad)\\([^)]*[0-9]"

fail3() {
  # C5 — 무엇이 틀렸나 / 왜 위험한가 / 무엇을 하라.
  echo "❌ $1"
  echo "   왜: $2"
  echo "   무엇을: $3"
}

# 줄 단위 마커. `// g7-preview-only: <사유>` 가 그 줄이나 바로 윗줄에 있으면 그
# 리터럴은 "프리뷰 발판" 으로 따로 센다.
#
# 왜 줄 단위인가: 기존 allowlist 는 파일 단위라 242건에는 쓸 수 없다 —
# display-media.ts 를 빼면 그 안의 진짜 위반 84건까지 같이 숨는다. 그리고 왜
# 나눠야 하는가: 292 라는 한 수는 **고칠 수 있는 것과 영구히 남을 발판을 구별하지
# 못한다**. 구별하지 않으면 이 수의 진척과 잡음이 같아 보이고, 그게 "래칫이 기존
# 문제를 합법화한다" 는 비판이 실제로 맞는 지점이다.
#
# 사유를 요구하는 이유는 orphan 필드 면제와 같다: 사유를 쓰는 행위가 카운트를
# 움직이므로, 대량으로 마커를 붙이려면 대량으로 근거를 써야 한다.
readonly MARKER='g7-preview-only:[[:space:]]*[^[:space:]]'

# stdout: "<unmarked> <marked>"
count_file_literals() {
  local f="$1"
  local unmarked=0 marked=0
  while IFS=: read -r n rest; do
    [ -z "$n" ] && continue
    local hits
    hits=$(printf '%s\n' "$rest" | grep -oE "$COLOR_PATTERN|$DIM_PATTERN" | wc -l | tr -d ' ')
    [ "$hits" -eq 0 ] && continue
    # 그 줄 또는 바로 윗줄에 사유가 붙은 마커가 있나. 윗줄까지 보는 이유는 여러
    # 줄로 쪼개진 호출에서 리터럴이 인자 줄에 있고 주석은 그 위에 오기 때문이다.
    local here above
    here=$(printf '%s\n' "$rest" | grep -cE "$MARKER" || true)
    above=0
    if [ "$n" -gt 1 ]; then
      above=$(sed -n "$((n - 1))p" "$f" | grep -cE "$MARKER" || true)
    fi
    if [ "$here" -gt 0 ] || [ "$above" -gt 0 ]; then
      marked=$((marked + hits))
    else
      unmarked=$((unmarked + hits))
    fi
  done < <(grep -nE "$COLOR_PATTERN|$DIM_PATTERN" "$f" 2>/dev/null)
  echo "$unmarked $marked"
}

allowlisted_basenames() {
  [ -f "$ALLOWLIST_FILE" ] || return 0
  grep -vE '^\s*#|^\s*$' "$ALLOWLIST_FILE" | awk -F'|' '{ gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1 }'
}

allowlist_entry_count() {
  [ -f "$ALLOWLIST_FILE" ] || { echo 0; return; }
  grep -vE '^\s*#|^\s*$' "$ALLOWLIST_FILE" | grep -c . || true
}

run_check() {
  if [ ! -d "$TARGET_DIR" ]; then
    fail3 "$TARGET_DIR 가 없음" "가드가 셀 대상 디렉터리 자체가 없다" "경로 확인(빌더 파일이 이동했다면 이 가드도 갱신)"
    return 1
  fi
  if [ ! -f "$BASELINE_FILE" ]; then
    fail3 "$BASELINE_FILE 가 없음" "ratchet 기준값이 없어 비교 불가" "baseline 파일 생성(초기값은 현재 총합)"
    return 1
  fi

  local allowlist
  allowlist=$(allowlisted_basenames)

  local total=0
  local marked_total=0
  local report=""
  local file_count=0
  while IFS= read -r f; do
    file_count=$((file_count + 1))
    local base
    base=$(basename "$f")
    if [ -n "$allowlist" ] && grep -qxF "$base" <<<"$allowlist"; then
      report="${report}   (allowlisted) ${f}\n"
      continue
    fi
    local n m
    read -r n m < <(count_file_literals "$f")
    total=$((total + n))
    marked_total=$((marked_total + m))
    report="${report}   ${f}: ${n}$([ "$m" -gt 0 ] && printf ' (+%s 프리뷰 발판)' "$m")\n"
  done < <(find "$TARGET_DIR" -name '*.ts' | sort)

  if [ "$file_count" -eq 0 ]; then
    fail3 "$TARGET_DIR 안에 *.ts 파일이 0개" "population 자체가 비어 diff 가 공허하게 통과한다" "TARGET_DIR/find 패턴이 실제 빌더 파일을 찾는지 확인"
    return 1
  fi

  # FLOOR 은 population 이 붕괴했는지 묻는다 — 그 population 은 미설명 + 발판이다.
  # 카운트를 둘로 쪼갤 때 이 비교를 미설명만 보게 남겨뒀더니, 104줄에 사유를 적어
  # 발판으로 옮긴 순간 "패턴이 더 이상 매칭하지 않는다" 로 오판했다. 실제로는 패턴이
  # 260건을 그대로 잡고 있었다 — 설명을 쓴 것이 붕괴로 읽힌 것이다.
  population=$((total + marked_total))
  if [ "$population" -lt "$FLOOR" ]; then
    fail3 "리터럴 population 이 하한 미달 — ${population}개 (미설명 ${total} + 발판 ${marked_total}, 하한 ${FLOOR})" "grep 패턴이 더 이상 매칭하지 않을 가능성 — 이 상태에서는 '리터럴이 다 사라졌다'로 조용히 오판된다" "헬퍼 함수명(bindSize/bindRadiusN/…)이나 ChromeOpts/LabelOpts 필드명이 바뀌었는지, 빌더 파일이 이동했는지 확인"
    return 1
  fi

  local baseline
  # `G7_BASELINE_OVERRIDE` 는 self-test 전용이다 — 아래 self_test 의 doc 참조.
  # CI 나 개발자 실행에서는 설정되지 않으며, 설정해서 게이트를 통과시키는 것은
  # baseline 파일을 직접 올리는 것과 같고 그쪽은 CODEOWNERS 리뷰를 거친다.
  baseline=${G7_BASELINE_OVERRIDE:-$(grep -vE '^\s*#|^\s*$' "$BASELINE_FILE" | head -1 | tr -d ' ')}
  # 0 이 아닌 값을 거부한다 — 이 축은 ratchet 을 졸업했다.
  #
  # 파일은 남는다: 304 → 0 까지의 로그가 그 안에 있고, 그 역사가 왜 이 게이트를
  # 믿을 수 있는지의 근거다. 남지 않는 것은 그 값을 올리는 길이다. 올릴 수 있는
  # 동안에는 "미설명 리터럴을 하나 더 두는" 것이 숫자 한 줄이었고, 지금은 그 줄에
  # 사유를 쓰는 것이 유일한 길이다.
  if [ -z "${G7_BASELINE_OVERRIDE:-}" ] && [ "$baseline" != "0" ]; then
    fail3 \
      "$BASELINE_FILE 의 값이 0 이 아니다: '$baseline'" \
      "미설명 리터럴은 하드 0 이다 — baseline 을 올려 통과하는 길은 닫혔고, 리터럴을 하나 더 두려면 그 줄에 사유를 써야 한다" \
      "값을 0 으로 되돌리고, 남기려는 리터럴에는 \`// g7-preview-only: <사유>\` 를 붙여라"
    return 1
  fi
  if ! [[ "$baseline" =~ ^[0-9]+$ ]]; then
    fail3 "$BASELINE_FILE 의 첫 non-comment 줄이 숫자가 아님: '$baseline'" "ratchet 비교 기준을 파싱할 수 없다" "baseline 파일 형식 확인(주석/빈 줄 제외 첫 줄 = 정수)"
    return 1
  fi

  local allowlist_count
  allowlist_count=$(allowlist_entry_count)

  local fail=0
  if [ "$total" -gt "$baseline" ]; then
    fail3 \
      "빌더 리터럴 총합이 baseline(${baseline}) 을 초과: ${total}개 (+$((total - baseline)))" \
      "하드코딩 색·치수 리터럴이 늘었다 — 91개 미전환 빌더가 줄어드는 방향이어야 할 카운트가 반대로 갔다는 뜻" \
      "새로 추가한 리터럴을 data.ts 경유(#3754/#3755 패턴, 기존 10개 데이터 기반 빌더 참조)로 바꾸거나, 정말 builder-original 이면(#3755 OQ-2) allowlist 에 사유와 함께 등재하고 baseline 을 갱신"
    fail=1
  fi
  if [ "$allowlist_count" -gt "$ALLOWLIST_BASELINE" ]; then
    fail3 \
      "allowlist 항목 수가 baseline(${ALLOWLIST_BASELINE}) 을 초과: ${allowlist_count}개" \
      "'리터럴을 allowlist 로 옮기기' 로 카운트 ratchet 을 우회할 수 있다 — allowlist 항목 수도 ratchet 대상인 이유" \
      "scripts/guards/structure/figma_builder_literals_allowlist_baseline.txt 의 값을 같은 diff 에서 올리고(오너 리뷰 대상), 각 신규 항목에 판정 사유를 남겨라"
    fail=1
  fi

  if [ "$fail" -ne 0 ]; then
    echo "── 파일별 리터럴 카운트 ──"
    printf '%b' "$report"
    return 1
  fi

  echo "✅ 빌더 리터럴 미설명 ${total}개 (하드 0) · 프리뷰 발판 ${marked_total}개 (사유 필수, 상한 없음) · allowlist ${allowlist_count}개 (baseline ${ALLOWLIST_BASELINE} 이하)."
  return 0
}

# `--report` — 총계가 아니라 목록.
#
# 이 가드는 스스로를 "이 프로젝트의 성공 판정" 이라 부르는데, 오래 세기만 했다:
# `--report` 가 총계 한 줄을 다시 찍었을 뿐이다. 그 상태로는 래칫이 잡은 위반을
# **고칠 수 없다** — 304 라는 수는 304개가 어디 있는지 말하지 않고, 그중 몇이
# 고칠 수 있는지도 말하지 않는다. 래칫이 문제를 합법화한다는 비판이 정확히
# 겨누는 지점이 이것이고, 반례가 아니라 목록이 답이다.
#
# 같은 교훈이 하루 안에 두 번 났다: exporter 의 라우팅 실패도 총계만 있었고,
# 필드 이름을 싣자마자 총계가 감추고 있던 키 버그가 나왔다.
report_literals() {
  local allowlist
  allowlist=$(allowlisted_basenames)
  local shown=0
  while IFS= read -r f; do
    local base
    base=$(basename "$f")
    if [ -n "$allowlist" ] && grep -qxF "$base" <<<"$allowlist"; then
      continue
    fi
    local hits
    hits=$(grep -nE "$COLOR_PATTERN|$DIM_PATTERN" "$f" 2>/dev/null || true)
    [ -z "$hits" ] && continue
    echo "── ${f}"
    # 한 줄에 리터럴이 여럿일 수 있어 카운트와 줄 수는 다르다 — 카운트는
    # run_check 가 매칭 수로 세고, 여기서는 사람이 갈 자리를 보여준다.
    printf '%s\n' "$hits" | sed 's/^/   /'
    shown=$((shown + 1))
  done < <(find "$TARGET_DIR" -name '*.ts' | sort)
  [ "$shown" -eq 0 ] && echo "(리터럴 없음)"
  return 0
}

self_test() {
  local rc=0
  local target="tools/figma-token-sync/src/components/navigation.ts"
  local backup
  backup=$(mktemp)
  cp "$target" "$backup"

  # baseline 과 현재 총합 사이에 여유가 있으면 리터럴 하나를 주입해도 여전히
  # 통과한다 — 즉 **누군가 숫자를 개선한 순간 이 self-test 가 증명력을 잃는다.**
  # 실제로 그렇게 됐다: 리터럴이 304 에서 290 으로 내려가자 주입-후-red 단계가
  # green 을 보고 실패했고, 가드가 고장난 게 아니라 self-test 가 여유를 못 다루는
  # 것이었다. 검사를 개선이 무력화한다면 그건 검사의 결함이다.
  #
  # 그래서 비교 기준을 현재 총합으로 못박고 주입한다 — 여유와 무관하게 항상
  # "하나 늘면 red" 를 검사한다.
  local current
  current=$(G7_BASELINE_OVERRIDE=999999 run_check 2>/dev/null | grep -oE '미설명 [0-9]+' | grep -oE '[0-9]+')
  if [ -z "$current" ]; then
    echo "   ❌ self-test 준비 실패 — 현재 총합을 읽지 못했다"
    rm -f "$backup"
    return 1
  fi
  export G7_BASELINE_OVERRIDE="$current"

  echo "── self-test 1/2: 새 색 리터럴 주입(전환된 빌더에 fillSem(node, lk, '...') 추가) → red 확인 (기준 ${current})"
  perl -0777 -pi -e "s/(export const NAVIGATION_BUILDERS)/fillSem(dummyNode, lk, 'destructive');\n\n\$1/" "$target"
  # 위 injection 은 grep 신호만 필요하므로 실제 호출 유효성(figma/lk 스코프)은
  # 무관 — run_check 는 정적 텍스트만 본다. tsc 타입체크는 이 self-test 의
  # 대상이 아니다(G6 이 별도로 본다). 인자에 중첩 괄호(예: figma.createFrame())
  # 를 넣지 않는다 — COLOR_PATTERN 의 `fillSem\([^)]*'...'` 는 첫 `)` 에서
  # 멈추므로, 중첩 괄호가 있으면 실제 코드에서도 못 잡는 패턴 한계를 이
  # self-test 가 잘못 가리게 된다(처음 이 self-test 를 `figma.createFrame()`
  # 로 작성했을 때 정확히 이 이유로 조용히 통과해, self-test 자체가 self-test
  # 를 통과 못 했다 — 그래서 실제 빌더 코드 스타일(단순 변수 인자)로 교정).

  if run_check >/tmp/g7_selftest_out.txt 2>&1; then
    echo "   ❌ self-test 실패 — 리터럴 주입 후에도 green"
    cat /tmp/g7_selftest_out.txt
    rc=1
  else
    echo "   ✅ red 확인 (baseline 초과로 fail)"
  fi

  cp "$backup" "$target"

  echo "── self-test 2/2: 되돌림 → green 확인"
  if run_check >/tmp/g7_selftest_out.txt 2>&1; then
    echo "   ✅ green 확인"
  else
    echo "   ❌ self-test 실패 — 되돌린 뒤에도 red (false positive)"
    cat /tmp/g7_selftest_out.txt
    rc=1
  fi

  rm -f "$backup" /tmp/g7_selftest_out.txt
  unset G7_BASELINE_OVERRIDE

  if [ "$rc" -eq 0 ]; then
    echo "✅ G7 self-test 통과(주입→red · 되돌림→green)."
  else
    echo "❌ G7 self-test 실패 — 위 단계 참고."
  fi
  return "$rc"
}

if [ "${1:-}" = "--self-test" ]; then
  self_test
  exit $?
fi

if [ "${1:-}" = "--report" ]; then
  report_literals
  echo
  run_check
  exit $?
fi

run_check
exit $?
