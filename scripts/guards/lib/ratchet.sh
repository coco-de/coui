# ratchet 기준값을 파일에서 읽는다 — 실패하면 **반드시 큰 소리로** 실패한다.
#
# 왜 공용 함수인가: 이 저장소의 가드 대부분은 `set -uo pipefail` 을 쓰되 `-e`
# 는 쓰지 않는다. 그 조합에서 값 읽기가 실패해 빈 문자열이 되면
#
#     [ "$count" -gt "$BASELINE" ]
#
# 가 rc 2 로 떨어지고, `if` 는 그것을 **거짓으로** 읽는다. 그래서 가드는
# 위반을 바닥에 흘린 채 통과 줄을 출력하고 exit 0 한다 — 그리고 그 상태에서는
# **baseline 파일을 지우는 것이 게이트를 끄는 방법**이 된다. 인라인 상수보다
# 나쁜 상태이므로, 추출은 이 검증과 반드시 같이 온다.
#
# 사용법 (호출자가 `|| exit 1` 을 붙이는 것이 계약이다 — `set -e` 에 기대지
# 않는다, 대부분의 가드가 그것을 켜지 않으므로):
#
#     BASELINE=$(ratchet_int "$RATCHET_FILE") || exit 1
#
# 파일 형식: `#` 주석과 빈 줄을 제외한 **첫 줄이 정수 하나**. 그 위의 주석이
# 그 숫자가 왜 그 값인지를 적는 자리다 — 값과 사유가 같은 리뷰에 놓이도록.

ratchet_int() {
  local file="$1"
  local raw

  if [ ! -f "$file" ]; then
    printf '❌ ratchet 기준값 파일이 없다: %s\n' "$file" >&2
    printf '   없는 파일을 0 으로 읽으면 "파일을 지우는 것" 이 게이트를 끄는 길이 된다.\n' >&2
    return 1
  fi

  raw=$(grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$file" | head -1 | tr -d '[:space:]')

  if ! printf '%s' "$raw" | grep -qE '^[0-9]+$'; then
    printf '❌ ratchet 기준값이 정수가 아니다: %s (읽은 값: %s)\n' "$file" "${raw:-<빈 값>}" >&2
    printf '   주석/빈 줄을 제외한 첫 줄이 정수 하나여야 한다.\n' >&2
    return 1
  fi

  printf '%s' "$raw"
}

# 자기 자신을 실패시켜 본다 — 실패시켜 보지 않은 가드는 가드가 아니다.
ratchet_self_test() {
  local tmp rc fails=0
  tmp=$(mktemp -d)

  _expect_fail() {
    local label="$1" file="$2"
    if ratchet_int "$file" >/dev/null 2>&1; then
      printf '  ❌ %s: 통과해버렸다 (실패해야 한다)\n' "$label"; fails=$((fails + 1))
    else
      printf '  ✅ %s: 올바르게 실패\n' "$label"
    fi
  }

  _expect_fail "없는 파일"        "$tmp/nope.txt"
  : > "$tmp/empty.txt";               _expect_fail "빈 파일"    "$tmp/empty.txt"
  printf '# only a comment\n' > "$tmp/c.txt";  _expect_fail "주석뿐"   "$tmp/c.txt"
  printf 'twenty\n' > "$tmp/w.txt";   _expect_fail "숫자 아님"  "$tmp/w.txt"
  printf -- '-3\n' > "$tmp/neg.txt";  _expect_fail "음수"       "$tmp/neg.txt"

  printf '# why this number\n\n27\n' > "$tmp/ok.txt"
  rc=$(ratchet_int "$tmp/ok.txt") || rc="<실패>"
  if [ "$rc" = "27" ]; then printf '  ✅ 정상 파일: 27\n'
  else printf '  ❌ 정상 파일: %s (27 이어야)\n' "$rc"; fails=$((fails + 1)); fi

  rm -rf "$tmp"
  [ "$fails" -eq 0 ]
}

if [ "${1:-}" = "--self-test" ]; then
  echo "ratchet_int self-test"
  ratchet_self_test && { echo "✅ ratchet reader 정상"; exit 0; } || { echo "❌ ratchet reader 결함"; exit 1; }
fi
