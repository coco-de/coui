#!/usr/bin/env bash
#
# G9 — `CoreSize` primitive-ladder pin (CoUI_Size_Token_Specification §1).
#
# `CoreSize` is the independent 24-token dimension ladder (4–128px,
# banded intervals: optical 2px / control 4px / structure 8px / display
# 16px). It is NOT a `CoreSpace` subset — the two are separate
# namespaces that deliberately never reference each other, and value
# overlap between them (24, 32, …) is by design (they share the
# 4px-multiple principle, not values). What must NOT happen silently:
#
#   - a value appearing in `CoreSize` that the spec ladder does not
#     contain ("Primitive 에 없는 값을 임의로 사용하는 것은 금지" — new
#     values go through the spec first), or
#   - a spec value quietly disappearing (its Figma `size/<n>` variable
#     and every alias into it would dangle).
#
# So this guard pins the *set* of `CoreSize` values to the baseline
# file — additions and removals both fail until the spec (and the
# baseline, with rationale) move together. The old duplication-ratchet
# premise this guard used to carry (#3736 F1 — "CoreSize duplicates
# CoreSpace, keep the debt from growing pending removal") is superseded
# by the spec: the ladder is intentional, not debt.
#
# C1 population floor: the extraction must clear a floor so a broken
# grep pattern (renamed field prefix, moved file) cannot look like a
# perfect match by producing zero of everything.
#
# Usage:
#   ./scripts/guards/tokens/check_space_size_duplication.sh              # 정상 실행
#   ./scripts/guards/tokens/check_space_size_duplication.sh --self-test  # 검증
set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

SIZE_FILE="packages/coui_core/lib/src/size/size.dart"
BASELINE="scripts/guards/tokens/space_size_duplication_baseline.txt"
FLOOR=20 # C1 — the ladder has 24 entries; 20 catches a collapsed extract
         # while leaving headroom for a spec-approved shrink.

fail3() {
  echo "❌ $1"
  echo "   왜: $2"
  echo "   무엇을: $3"
}

extract_values() {
  # $1 = source file, $2 = token name prefix
  grep -oE "static const ${2}[0-9]+ = [0-9.]+" "$1" | grep -oE '[0-9.]+$' | sort -n -u
}

run_check() {
  if [ ! -f "$SIZE_FILE" ] || [ ! -f "$BASELINE" ]; then
    fail3 "입력 파일 누락" "가드가 비교할 소스/baseline 이 없다" "경로 확인($SIZE_FILE / $BASELINE)"
    return 1
  fi

  local size_values size_count baseline_values
  size_values=$(extract_values "$SIZE_FILE" "size")
  size_count=$(printf '%s\n' "$size_values" | grep -c . || true)

  if [ "$size_count" -lt "$FLOOR" ]; then
    fail3 \
      "추출된 토큰 수가 하한 미달 — CoreSize ${size_count}개 (하한 ${FLOOR})" \
      "grep 패턴이 더 이상 매칭하지 않을 가능성 — 이 상태에서는 비교도 텅 비어 '정합' 으로 조용히 오판된다" \
      "$SIZE_FILE 의 필드 선언 패턴이 static const sizeN = N.N 형태에서 바뀌었는지 확인"
    return 1
  fi

  baseline_values=$(grep -vE '^\s*#|^\s*$' "$BASELINE" | sort -n -u)

  local extra missing
  extra=$(comm -23 <(printf '%s\n' "$size_values") <(printf '%s\n' "$baseline_values"))
  missing=$(comm -13 <(printf '%s\n' "$size_values") <(printf '%s\n' "$baseline_values"))

  if [ -n "$extra" ]; then
    fail3 \
      "CoreSize 에 스펙 사다리 밖의 값이 생김: $(printf '%s' "$extra" | tr '\n' ' ')" \
      "Primitive 에 없는 값의 임의 사용은 금지 — 새 값은 스펙(CoUI_Size_Token_Specification §1)에 먼저 추가한 뒤 baseline 과 함께 움직인다" \
      "스펙 문서를 갱신하고 $BASELINE 에 근거를 남기며 값을 추가하라 (또는 CoreSize 에서 그 값을 제거)"
    return 1
  fi
  if [ -n "$missing" ]; then
    fail3 \
      "스펙 사다리의 값이 CoreSize 에서 사라짐: $(printf '%s' "$missing" | tr '\n' ' ')" \
      "그 값을 가리키던 Figma size/<n> 변수와 모든 alias 가 끊긴다" \
      "값을 복원하거나, 스펙 변경이면 $BASELINE 도 같은 커밋에서 갱신하라"
    return 1
  fi

  echo "✅ CoreSize 가 스펙 24토큰 사다리와 정확히 일치(${size_count}개)."
  return 0
}

self_test() {
  local rc=0
  local backup
  backup=$(mktemp)
  cp "$SIZE_FILE" "$backup"

  echo "── self-test 1/2: 사다리 밖 값 주입(size999) → red 확인"
  perl -0777 -pi -e 's/\}\s*\z/  static const size999 = 999.0;\n}\n/' "$SIZE_FILE"

  if run_check >/dev/null 2>&1; then
    echo "   ❌ self-test 실패 — 사다리 밖 값 주입 후에도 green"
    rc=1
  else
    echo "   ✅ red 확인"
  fi

  cp "$backup" "$SIZE_FILE"

  echo "── self-test 2/2: 되돌림 → green 확인"
  if run_check >/dev/null 2>&1; then
    echo "   ✅ green 확인"
  else
    echo "   ❌ self-test 실패 — 되돌린 뒤에도 red (false positive)"
    rc=1
  fi

  rm -f "$backup"

  if [ "$rc" -eq 0 ]; then
    echo "✅ G9 self-test 통과(주입→red · 되돌림→green)."
  else
    echo "❌ G9 self-test 실패 — 위 단계 참고."
  fi
  return "$rc"
}

if [ "${1:-}" = "--self-test" ]; then
  self_test
  exit $?
fi

run_check
exit $?
