#!/usr/bin/env bash
# `package:flutter/material.dart` 를 import/export 하는 라이브러리 코드를 센다.
#
# CoUI 는 Material 의 대체다(`code-style/naming.md` consumer 규칙). 라이브러리
# 안에 Material import 가 하나 늘 때마다 그 파일은 Material 의 테마·위젯·
# 라우트에 다시 기대게 되고, 그 의존은 렌더가 멀쩡한 채로 쌓인다. 그래서
# 지금 남아 있는 것은 사유와 함께 적어 두고, 새로 생기는 것만 막는다.
#
# ── 왜 린트 옆에 bash 가드가 따로 있나 (중복이 아니다 — 지우지 말 것) ──────
#
# `analysis_options.yaml` 에 `avoid_framework_import` 가 켜져 있지만, 그것은
# 이 질문에 답하지 않는다. 이유가 둘이고, 둘 다 독립적으로 충분하다.
#
#   1. CI 에서 아무것도 막지 않는다.
#      값이 `true` 라 심각도가 INFO 이고, CI 는 `dart analyze --fatal-warnings`
#      다 — INFO 는 실패가 되지 않는다(같은 파일의 plugins 블록 주석이 그렇게
#      적는다). 그걸 잡는 곳은 로컬 훅(`--fatal-infos`)뿐이라 훅을 건너뛰면
#      통과한다. 게다가 analyzer 플러그인은 SDK 범프에서 로드에 조용히
#      실패할 수 있고, 그러면 룰이 통째로 사라진 채 분석은 초록이다 — ci.yaml
#      의 static-guards 잡이 다른 coui_lints 룰 셋을 셸 grep 으로 옮긴 이유가
#      정확히 이것이다(이 SDK 의 CLI analyze 에서 coui_lints 진단이 뜨지 않는
#      것이 실측됐다).
#
#   2. 켜져 있어도 다른 것을 검사한다.
#      그 룰은 **같은 파일이 CoUI 배럴도 import 할 때만**, 그리고 **prefix 도
#      `show` 도 없는** framework import 에만 발화한다. 목적이 "bare CoUI 이름이
#      framework 동명과 모호해지는 것" 을 막는 것이기 때문이다. `as m` 이나
#      `show X` 로 좁힌 import 는 일부러 면제한다 — 그리고 지금 남은 Material
#      import 는 **전부 그 면제 형태**다. 즉 그 룰이 완벽히 동작해도 이 목록은
#      0 건으로 보인다. "Material 이 늘었는가" 는 그 룰의 질문이 아니다.
#
# ── 범위 ────────────────────────────────────────────────────────────────
#
#   packages/coui_flutter/lib — ratchet. 아래 baseline 에 적힌 것만 허용.
#   packages/coui_core/lib    — 하드 0. baseline 항목으로도 허용하지 않는다.
#
# coui_core 는 pubspec 에 flutter 의존이 없으므로 `package:flutter/*` import 는
# 지금도 **컴파일러가 이미 막는다**. 그 범위를 여기 남기는 것은 회귀 그물이다:
# 누군가 편의로 flutter 의존을 추가하는 순간 컴파일러의 보장은 사라지고,
# 그때 platform-neutral 패키지에 Material 이 들어오는 것을 이 줄이 막는다.
#
# ── baseline 형식 ───────────────────────────────────────────────────────
#
#   <kind> | <파일 경로> | <정규화된 directive 전문> | <사유>
#
#   kind = allow — 의도적 공개 재노출(배럴의 show 제한 export). 부채가 아니다.
#   kind = debt  — 줄여야 할 import.
#
# 항목은 **줄 번호가 아니라 directive 내용**으로 맞춘다. 파일 위쪽에 줄이
# 하나 늘 때마다 baseline 이 흔들리면 사람들은 --update 를 습관으로 돌리고,
# 그 습관이 새 import 를 같이 쓸어 담는다. 같은 이유로 directive 는 `show`
# 목록까지 전부 비교한다 — 배럴 export 의 show 목록에 Material 타입을 하나
# 더하는 것은 새 공개 표면이고, 그것도 여기서 멈춰야 한다.
#
# 사유 칸이 비었거나 `REASON-MISSING` 이면 실패한다. --update 는 기존 항목의
# kind·사유를 보존하고, 새 항목에는 그 표시를 넣어 사람이 적게 만든다.
#
# baseline 에 있는데 코드에서 사라진 항목도 실패한다 — 목록이 실제로 줄어야
# ratchet 이다. 사라진 채 남은 항목은 같은 import 를 다시 들여올 자리가 된다.
#
# ── self-check ──────────────────────────────────────────────────────────
#
# 스캔이 (baseline 에 있는 것을 포함해) 0 건을 찾으면 레포가 깨끗해진 것이
# 아니라 **추출이 고장난 것**으로 보고 실패한다. 알려진 항목이 있는 상태에서
# 0 건은 "경로가 옮겨졌다 / 정규식이 깨졌다" 의 신호다.
# `check_localization_parity.sh` 가 파싱한 멤버 수가 비정상적으로 적으면
# 실패하는 것과 같은 이유다 — 아무것도 파싱하지 못해서 아무것도 찾지 못한
# 가드는 없는 가드보다 나쁘다. (정말로 전부 걷어낸 날에는 이 검사를 그
# 사실에 맞게 고치면 된다 — 그 편집이 그 사실의 기록이 된다.)
#
# Usage: check_material_import.sh [--update]

set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

BASELINE="scripts/guards/structure/material_import_baseline.txt"
RATCHET_DIR="packages/coui_flutter/lib"
HARD_ZERO_DIR="packages/coui_core/lib"

for d in "$RATCHET_DIR" "$HARD_ZERO_DIR"; do
  [ -d "$d" ] || { echo "❌ 스캔 대상 디렉터리가 없다: $d (옮겨졌다면 이 가드의 경로를 고칠 것)"; exit 1; }
done

# 파일 하나에서 Material import/export directive 를 전문으로 뽑는다.
# directive 는 여러 줄에 걸칠 수 있으므로(`show` 목록 줄바꿈) 파일을 통째로
# 읽고 `;` 까지 잡는다. 줄 머리에서 시작하는 것만 — 주석 안의 언급은 제외.
extract() {
  perl -0777 -ne '
    my $file = $ARGV;
    while (/^[ \t]*((?:import|export)[ \t]+[\x27"]package:flutter\/material\.dart[\x27"][^;]*;)/mg) {
      my $d = $1;
      $d =~ s/\s+/ /g;
      $d =~ s/ ;$/;/;
      print "$file | $d\n";
    }
  ' "$@"
}

scan() {
  find "$1" -name '*.dart' -type f | sort | while IFS= read -r f; do extract "$f"; done
}

hard_zero=$(scan "$HARD_ZERO_DIR")
found=$(scan "$RATCHET_DIR" | sort -u)

status=0

if [ -n "$hard_zero" ]; then
  echo "❌ coui_core 에 Material import 가 있다 (baseline 으로도 허용되지 않는다):"
  printf '%s\n' "$hard_zero" | sed 's/^/     /'
  echo "   coui_core 는 platform-neutral 이다. Flutter 타입이 필요하면 그 변환은"
  echo "   coui_flutter adapter 에 산다 (code-style/conversion-helpers.md)."
  status=1
fi

if [ ! -f "$BASELINE" ]; then
  echo "❌ baseline 파일이 없다: $BASELINE"
  echo "   없는 파일을 빈 목록으로 읽으면 파일을 지우는 것이 게이트를 끄는 길이 된다."
  exit 1
fi

# baseline 항목: kind | path | directive | reason
entries=$(grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$BASELINE" || true)

# path | directive 키만 뽑는다.
keys_of() { awk -F ' \\| ' 'NF>=3 { print $2 " | " $3 }'; }

known=$(printf '%s\n' "$entries" | sed '/^$/d' | keys_of | sort -u)

if [ "${1:-}" = "--update" ]; then
  if [ -n "$hard_zero" ]; then
    echo "❌ coui_core 항목은 baseline 에 넣을 수 없다 — 먼저 걷어낼 것."
    exit 1
  fi
  # 추출이 고장난 상태에서 --update 를 돌리면 baseline 이 통째로 비고, 그
  # 순간부터 가드는 아무것도 세지 않는다 — 아래 self-check 와 같은 이유로 막는다.
  if [ -z "$found" ]; then
    echo "❌ Material directive 를 0 건 찾았다 — 추출이 고장난 채로 baseline 을 덮어쓰지 않는다."
    exit 1
  fi
  header=$(awk '/^[[:space:]]*#|^[[:space:]]*$/ { print; next } { exit }' "$BASELINE")
  {
    printf '%s\n' "$header"
    printf '%s\n' "$found" | sed '/^$/d' | while IFS= read -r key; do
      prev=$(printf '%s\n' "$entries" | awk -F ' \\| ' -v k="$key" 'NF>=4 && ($2 " | " $3) == k { print; exit }')
      if [ -n "$prev" ]; then
        printf '%s\n' "$prev"
      else
        printf 'debt | %s | REASON-MISSING\n' "$key"
      fi
    done
  } > "$BASELINE"
  echo "baseline updated ($(printf '%s' "$found" | grep -c . || true) entries)"
  added=$(grep -c 'REASON-MISSING' "$BASELINE" || true)
  [ "$added" -gt 0 ] && echo "   새 항목 $added 건에 사유를 적을 것 — 적기 전까지 가드는 실패한다."
  exit 0
fi

# 형식 · 사유 검사
bad=$(printf '%s\n' "$entries" | sed '/^$/d' | awk -F ' \\| ' '
  NF != 4 { print "형식 오류: " $0; next }
  $1 != "allow" && $1 != "debt" { print "kind 가 allow/debt 가 아니다: " $0; next }
  $4 ~ /^[[:space:]]*$/ || $4 ~ /REASON-MISSING/ { print "사유 없음: " $2 " | " $3 }
')
bad_core=$(printf '%s\n' "$known" | grep "^${HARD_ZERO_DIR}/" || true)
if [ -n "$bad" ] || [ -n "$bad_core" ]; then
  echo "❌ baseline 항목이 올바르지 않다 ($BASELINE):"
  printf '%s\n' "$bad" "$bad_core" | sed '/^$/d; s/^/     /'
  echo "   형식은 'kind | path | directive | reason', coui_core 항목은 허용되지 않는다."
  status=1
fi

netnew=$(comm -23 <(printf '%s\n' "$found" | sed '/^$/d') <(printf '%s\n' "$known" | sed '/^$/d'))
stale=$(comm -13 <(printf '%s\n' "$found" | sed '/^$/d') <(printf '%s\n' "$known" | sed '/^$/d'))

if [ -n "$netnew" ]; then
  echo "❌ 새 Material import/export (baseline 에 없음):"
  printf '%s\n' "$netnew" | sed 's/^/     /'
  echo "   CoUI 배럴이 Material 을 대체한다 — 필요한 것이 배럴에 있는지 먼저 본다."
  echo "   framework 전용 심볼이 정말 필요하면 baseline 에 사유와 함께 올리되,"
  echo "   그 편집은 CODEOWNERS 리뷰 요청을 부른다(의도된 신호다)."
  echo "   export 의 show 목록을 바꿔도 여기 걸린다 — 새 공개 표면이기 때문이다."
  status=1
fi

if [ -n "$stale" ]; then
  echo "❌ baseline 에 있지만 코드에서 사라진 항목 — 줄어든 것을 기록할 것:"
  printf '%s\n' "$stale" | sed 's/^/     /'
  echo "   bash scripts/guards/structure/check_material_import.sh --update"
  status=1
fi

# self-check — 아무것도 찾지 못한 가드는 추출이 고장난 것이다.
total=$(printf '%s\n' "$found" | grep -c . || true)
if [ "$total" -eq 0 ]; then
  echo "❌ $RATCHET_DIR 에서 Material directive 를 0 건 찾았다 — 레포가 깨끗해진 것이"
  echo "   아니라 추출이 고장났을 가능성이 크다(경로 이동 · 정규식 파손)."
  echo "   정말로 전부 걷어냈다면 이 self-check 를 그 사실에 맞게 고칠 것."
  status=1
fi

[ "$status" -ne 0 ] && exit "$status"

allow=$(printf '%s\n' "$entries" | grep -c '^allow ' || true)
debt=$(printf '%s\n' "$entries" | grep -c '^debt ' || true)
echo "PASS: 새 Material import 없음 (allow $allow · debt $debt, coui_core 0)"
exit 0
