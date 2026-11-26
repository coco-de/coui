# 러너 도구가 **실제로 실행되는지** 묻는다 — "도구가 죽었다" 와 "위반을 찾았다"
# 를 서로 다른 신호로 가른다.
#
# ## 왜
#
# macOS 의 `/usr/bin/python3` · `/usr/bin/git` 은 Xcode 셸 심(shim)이다. Xcode
# 라이선스에 동의하지 않은 머신에서는 심이 실행 대신
#
#     You have not agreed to the Xcode license agreements. …
#
# 을 내고 non-zero 로 끝난다. 그래서 `command -v python3` 는 성공하는데 실행은
# 실패한다 — 존재 확인으로는 이 상태를 볼 수 없고, **한 번 돌려 봐야** 보인다.
#
# 그 상태에서 가드는 위반을 하나도 찾지 못했는데 스텝이 `exit 1` 로 끝났고, 그
# 빨강은 "가드가 위반을 찾았다" 와 구별되지 않았다. 실제로 토큰 가드 스텝이 개별
# 가드 전부 ✅ 를 찍고도 빨갰고, 그 PR 은 자기 변경을 의심하며 재실행을 거듭했다
# — 같은 러너가 다시 잡혀 매번 같은 결과였다. 막힌 사람에게 필요한 것은 "네
# 변경이 아니라 러너다" 라는 한 줄이다.
#
# 도구 부재는 안전 위반이 아니다. 그래서 위반(1)과 다른 종료 코드를 쓴다:
#
#     0  실행된다
#     3  실행되지 않는다 — 가드 위반이 아니다
#
# ## 사용법
#
# 가드에서 (실행 불가면 CI 에서는 이유를 적고 exit 3, 로컬에서는 경고 후 exit 0 —
# CI 에서 조용히 건너뛰면 그 가드는 존재만 하고 아무것도 세지 않는다):
#
#     . "$_GUARD_DIR/../lib/require_tool.sh"
#     require_tool python3 -c 'print(1)'
#
# 판정만 필요하면 (종료하지 않고 0/3 을 돌려준다):
#
#     probe_tool git --version || bad=1
#
# 첫 인자는 도구 이름이자 실행할 명령이다 — 이름과 실제로 돌린 명령이 어긋날
# 자리를 두지 않는다.
#
# 자기 시험: `bash scripts/guards/lib/require_tool.sh --self-test`

# 실행 불가를 뜻하는 종료 코드. 위반(1)·사용법 오류(2)와 겹치지 않는다.
REQUIRE_TOOL_UNAVAILABLE=3

_require_tool_in_ci() { [ "${CI:-}" = "true" ]; }

# 한 줄 진단 — Actions 에서는 주석(annotation)으로, 그 밖에서는 평문으로.
_require_tool_say() {
  local level="$1" msg="$2"
  if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
    printf '::%s title=러너 도구 불가 — 가드 위반 아님::%s\n' "$level" "$msg"
  else
    printf '%s\n' "$msg"
  fi
}

# probe_tool <cmd> [args…] — 명령을 한 번 실행해 보고 0(된다) / 3(안 된다).
# 실패하면 원인을 분류해 stderr 가 아니라 stdout 에 적는다(CI 로그 순서 보존).
probe_tool() {
  local tool="$1" out rc runner reason
  runner="${RUNNER_NAME:-$(hostname 2>/dev/null || echo unknown)}"

  if ! command -v "$tool" >/dev/null 2>&1; then
    reason="'$tool' 을 PATH 에서 찾지 못했다"
  else
    # `set -e` 아래에서도 이 함수가 먼저 죽지 않도록 if 안에서 받는다.
    if out=$("$@" 2>&1); then
      return 0
    else
      rc=$?
    fi
    if grep -qiE 'xcode license|xcodebuild -license' <<<"$out"; then
      reason="'$tool' 이 Xcode 라이선스 미동의로 실행되지 않는다 (rc=$rc) — 러너에서 'sudo xcodebuild -license accept'"
    else
      reason="'$tool' 실행 실패 (rc=$rc): $(head -1 <<<"$out")"
    fi
  fi

  _require_tool_say error "러너 '$runner': $reason. 가드 위반이 아니라 러너 상태다 — 코드를 의심하기 전에 러너를 고친다."
  return "$REQUIRE_TOOL_UNAVAILABLE"
}

# require_tool <cmd> [args…] — 실행되면 그대로 진행, 안 되면 이 스크립트를 끝낸다.
require_tool() {
  probe_tool "$@" && return 0
  if _require_tool_in_ci; then
    exit "$REQUIRE_TOOL_UNAVAILABLE"
  fi
  echo "⚠️  건너뜀 — 위 도구 없이는 이 가드가 셀 수 없다 (로컬 한정. CI 에서는 같은 조건이 exit $REQUIRE_TOOL_UNAVAILABLE 이다)."
  exit 0
}

# 자기 자신을 실패시켜 본다 — 실패시켜 보지 않은 가드는 가드가 아니다.
_require_tool_self_test() {
  local tmp fails=0 out rc
  tmp=$(mktemp -d)

  # Xcode 심 흉내 — 존재는 하지만 실행하면 라이선스 문구를 내고 69 로 끝난다.
  mkdir -p "$tmp/xcode" "$tmp/broken" "$tmp/ok"
  cat > "$tmp/xcode/fakepy" <<'SH'
#!/bin/sh
echo "You have not agreed to the Xcode license agreements. Please run 'sudo xcodebuild -license' from within a Terminal window to review and agree to the Xcode and Apple SDKs license." >&2
exit 69
SH
  printf '#!/bin/sh\necho "dyld: library not loaded" >&2\nexit 5\n' > "$tmp/broken/fakepy"
  printf '#!/bin/sh\necho 1\n' > "$tmp/ok/fakepy"
  chmod +x "$tmp"/*/fakepy

  # $1 라벨 · $2 PATH 앞에 둘 디렉터리 · $3 CI 값 · $4 기대 rc · $5 출력에 있어야 할 문구
  _expect() {
    local label="$1" dir="$2" ci="$3" want_rc="$4" want_text="$5"
    out=$(PATH="$dir:$PATH" CI="$ci" GITHUB_ACTIONS="" bash -c \
      '. "$1"; require_tool fakepy -c "print(1)"; echo "진행함"' _ "$_REQUIRE_TOOL_SELF" 2>&1)
    rc=$?
    # 도구가 안 되는 경우는 가드 본문으로 **넘어가지 않아야** 한다 — 로컬에서
    # rc 0 으로 끝나더라도 그것은 건너뜀이지 진행이 아니다.
    local leaked=0
    if [ "$want_text" != "진행함" ] && grep -qF "진행함" <<<"$out"; then leaked=1; fi
    if [ "$rc" -eq "$want_rc" ] && [ "$leaked" -eq 0 ] && grep -qF -- "$want_text" <<<"$out"; then
      printf '  ✅ %s: rc=%s\n' "$label" "$rc"
    else
      printf '  ❌ %s: rc=%s (기대 %s), 출력:\n' "$label" "$rc" "$want_rc"
      printf '%s\n' "$out" | sed 's/^/       /'
      fails=$((fails + 1))
    fi
  }

  _expect "Xcode 심 · CI"       "$tmp/xcode"  true  3 "Xcode 라이선스 미동의"
  _expect "Xcode 심 · 로컬"     "$tmp/xcode"  ""    0 "건너뜀"
  _expect "그 밖의 실행 실패"   "$tmp/broken" true  3 "dyld: library not loaded"
  _expect "PATH 에 없음"        "$tmp/none"   true  3 "PATH 에서 찾지 못했다"
  _expect "정상 도구는 진행"    "$tmp/ok"     true  0 "진행함"

  # 실행 불가의 종료 코드가 위반(1)과 같으면 이 헬퍼가 있을 이유가 없다.
  if [ "$REQUIRE_TOOL_UNAVAILABLE" -eq 1 ]; then
    printf '  ❌ 실행 불가 종료 코드가 위반(1)과 같다\n'; fails=$((fails + 1))
  fi

  rm -rf "$tmp"
  [ "$fails" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  _REQUIRE_TOOL_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
  if [ "${1:-}" = "--self-test" ]; then
    echo "require_tool self-test"
    if _require_tool_self_test; then echo "✅ require_tool 정상"; exit 0; fi
    echo "❌ require_tool 결함"; exit 1
  fi
  echo "사용법: source 해서 require_tool / probe_tool 을 쓴다, 또는 --self-test" >&2
  exit 2
fi
