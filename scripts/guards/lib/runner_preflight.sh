#!/usr/bin/env bash
# 러너가 가드를 돌릴 수 있는 상태인지 먼저 묻는다 — 가드보다 앞에서, 한 번.
#
# ## 왜
#
# 정적 가드 잡의 뒤 스텝들은 python3 와 git 을 그냥 부른다. 러너에서 그 도구가
# 죽어 있으면(macOS 의 /usr/bin/python3 · /usr/bin/git 은 Xcode 심이라 라이선스
# 미동의만으로 실행이 실패한다) 스텝마다 따로 빨개지고, 그 빨강은 전부 "가드가
# 위반을 찾았다" 처럼 읽힌다. 실제로 개별 가드가 전부 ✅ 를 찍고도 스텝이
# `exit 1` 로 끝났고, 다음 스텝은 `git fetch` 에서 `exit 69` 로 죽었다 — 막힌
# PR 은 자기 변경을 의심하며 재실행했고, 같은 러너가 다시 잡혀 같은 결과였다.
#
# 이 스크립트가 맨 앞에서 실패하면 뒤 스텝은 건너뛰어지고, 잡의 유일한 빨강이
# "러너 X 의 도구 Y 가 원인 Z 로 안 된다 — 가드 위반 아님" 한 줄이 된다.
#
# 체크아웃은 git 이 안 될 때 실패하지 않고 REST API 아카이브로 내려앉는다. 그러면
# 작업 디렉터리에 git 저장소가 없어 커밋을 읽는 가드가 범위를 정할 수 없다 —
# 그래서 git 바이너리뿐 아니라 저장소가 있는지도 따로 본다.
#
# 종료 코드: 0 준비됨 / 3 러너 도구 불가 (가드 위반의 1 과 다르다).
#
# 사용법: bash scripts/guards/lib/runner_preflight.sh
#         bash scripts/guards/lib/runner_preflight.sh --self-test

set -uo pipefail

_PREFLIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=require_tool.sh
. "$_PREFLIGHT_DIR/require_tool.sh"

preflight() {
  local bad=0 runner
  runner="${RUNNER_NAME:-$(hostname 2>/dev/null || echo unknown)}"

  # 가드가 부르는 그대로(PATH 의 python3) 돌려 본다 — 절대 경로를 따로 재면
  # 가드가 실제로 쓰는 쪽과 다른 바이너리를 볼 수 있다.
  probe_tool python3 -c 'print(1)' || bad=1

  if probe_tool git --version; then
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
      _require_tool_say error "러너 '$runner': 작업 디렉터리 '$(pwd)' 가 git 저장소가 아니다 — 체크아웃이 git 대신 REST 아카이브로 내려앉았을 수 있다. 가드 위반이 아니라 러너 상태다."
      bad=1
    fi
  else
    bad=1
  fi

  if [ "$bad" -ne 0 ]; then
    echo "❌ 러너 도구 불가 — 뒤의 가드 스텝은 돌지 않는다. 이 빨강은 PR 의 변경과 무관하다."
    return "$REQUIRE_TOOL_UNAVAILABLE"
  fi
  echo "✅ 러너 준비됨 — python3 · git · 저장소 확인 ($runner)"
}

_preflight_self_test() {
  local tmp fails=0 out rc repo
  tmp=$(mktemp -d)
  repo="$(cd "$_PREFLIGHT_DIR/../../.." && pwd)"

  mkdir -p "$tmp/xcode" "$tmp/notrepo"
  for t in python3 git; do
    cat > "$tmp/xcode/$t" <<'SH'
#!/bin/sh
echo "You have not agreed to the Xcode license agreements. Please run 'sudo xcodebuild -license' from within a Terminal window to review and agree to the Xcode and Apple SDKs license." >&2
exit 69
SH
    chmod +x "$tmp/xcode/$t"
  done

  # $1 라벨 · $2 작업 디렉터리 · $3 PATH 앞에 둘 디렉터리(없으면 빈 값) · $4 기대 rc · $5 있어야 할 문구
  _expect() {
    local label="$1" dir="$2" pre="$3" want_rc="$4" want_text="$5" path="$PATH"
    [ -n "$pre" ] && path="$pre:$PATH"
    out=$(cd "$dir" && PATH="$path" GITHUB_ACTIONS="" bash "$_PREFLIGHT_DIR/runner_preflight.sh" 2>&1)
    rc=$?
    if [ "$rc" -eq "$want_rc" ] && grep -qF -- "$want_text" <<<"$out"; then
      printf '  ✅ %s: rc=%s\n' "$label" "$rc"
    else
      printf '  ❌ %s: rc=%s (기대 %s), 출력:\n' "$label" "$rc" "$want_rc"
      printf '%s\n' "$out" | sed 's/^/       /'
      fails=$((fails + 1))
    fi
  }

  _expect "Xcode 심 python3·git" "$repo"         "$tmp/xcode" 3 "Xcode 라이선스 미동의"
  _expect "git 저장소 없음"     "$tmp/notrepo"   ""           3 "git 저장소가 아니다"
  _expect "정상 러너"            "$repo"         ""           0 "러너 준비됨"

  rm -rf "$tmp"
  [ "$fails" -eq 0 ]
}

if [ "${1:-}" = "--self-test" ]; then
  echo "runner_preflight self-test"
  if _preflight_self_test; then echo "✅ runner_preflight 정상"; exit 0; fi
  echo "❌ runner_preflight 결함"; exit 1
fi

preflight
