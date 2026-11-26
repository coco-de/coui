#!/usr/bin/env bash
# CODEOWNERS 의 오너가 실제로 **해석되는지** GitHub 자신에게 묻는다.
#
# 왜 이 가드가 있나 — `check_codeowners_ratchet_coverage.sh` 는 ratchet 산출물이
# CODEOWNERS 에 등록됐는지를 세지만, 등록된 오너가 GitHub 에서 실제로 사람으로
# 풀리는지는 보지 않는다. 그 판정은 `p.startswith("@")` 하나이므로 오타난 핸들도,
# write 권한을 잃은 사용자도, secret 팀도 전부 통과한다. 셋 다 GitHub 에서는
# 오너 0명으로 해석되어 리뷰 요청이 아무에게도 가지 않는데, 가드는 초록을 보고한다.
#
# 이건 가정이 아니다. `.github/CODEOWNERS` 헤더가 이 저장소가 그 함정에 이미 한
# 번 당했다고 적어 두었다 — secret 팀을 오너로 두어 파일 전체가 "있으나 마나 한
# 상태" 였던 적이 있다. 헤더는 처방까지 적었다: `codeowners/errors` 를 되읽어
# 확인하라고. **그 되읽기가 어디에도 배선돼 있지 않았다.** 문서에 적힌 대조는
# 강제가 아니다.
#
# GitHub 자신의 파서를 쓰므로 오너 해석과 패턴 문법을 함께 검증한다 — 위 가드의
# 손으로 쓴 matcher 가 모델링할 수 없는 형태까지 같이 덮인다.
#
# ## 통과가 헛되지 않게 하는 장치
#
# `codeowners/errors` 는 **ref 에 있는 파일**을 검증한다. 그래서 아직 푸시되지
# 않은 편집에 대해 `errors: []` 가 돌아올 수 있고, 그건 "이 편집이 유효하다" 가
# 아니라 "다른 파일이 유효하다" 는 뜻이다. 실제로 그 헛통과가 한 번 나왔다.
# 그래서 이 가드는 **응답이 검증한 파일이 지금 이 작업 트리의 파일과 같은지**
# 해시로 대조한 뒤에만 통과시킨다.
#
# ## 도구가 없을 때
#
# 도구 부재는 안전 위반이 아니다(레포의 Degradation Contract). 로컬에서 gh 가
# 없거나 인증이 없거나 ref 가 아직 원격에 없으면 경고 후 건너뛴다. 다만 **CI
# 에서는 하드 실패** — 거기서 조용히 건너뛰면 이 가드는 존재만 하고 아무것도
# 세지 않는 상태가 되고, 그건 이 파일이 고치려는 실패와 같은 모양이다.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

readonly CODEOWNERS=".github/CODEOWNERS"
[ -f "$CODEOWNERS" ] || { echo "❌ $CODEOWNERS 없음"; exit 1; }

# CI 여부. GitHub Actions 는 CI=true 를 항상 설정한다.
in_ci() { [ "${CI:-}" = "true" ]; }

# 건너뛸 때의 종료 코드 — CI 면 실패, 아니면 통과.
skip_or_fail() {
  local reason="$1"
  if in_ci; then
    echo "❌ CI 에서 오너 해석을 확인하지 못했다: $reason"
    echo "   CI 에서 이 확인을 건너뛰면 가드가 존재만 하고 아무것도 세지 않는다."
    exit 1
  fi
  echo "⚠️  건너뜀 — $reason"
  echo "   (로컬 한정. CI 에서는 같은 조건이 하드 실패다.)"
  exit 0
}

# GitHub API 한 번. 두 전송 수단을 순서대로 시도하고, **결과로** 판정한다.
#
# `gh auth status` 를 능력 판정에 쓰지 않는다. 그 명령은 설정된 호스트 중 하나만
# 낡아도 실패하는데, 그때도 토큰으로 API 는 정상 호출된다 — 실제로 이 저장소의
# self-hosted 러너가 정확히 그 상태였고, `GH_TOKEN` 이 넘어가 있는데도 이 가드가
# "gh 미인증" 으로 CI 를 빨갛게 만들었다. 대리 질문에 답하지 말고 하려던 일을
# 직접 해 보고 그 결과로 판정한다 — 이 파일이 헛통과를 막는 방식과 같은 규칙이다.
api() {
  local path="$1" out
  if command -v gh >/dev/null 2>&1 && out=$(gh api "$path" 2>/dev/null); then
    printf '%s' "$out"
    return 0
  fi
  local token="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
  if [ -n "$token" ] && out=$(curl -sSf \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com$path" 2>/dev/null); then
    printf '%s' "$out"
    return 0
  fi
  return 1
}

REPO="${GITHUB_REPOSITORY:-}"
if [ -z "$REPO" ]; then
  REPO=$(git remote get-url origin 2>/dev/null \
    | sed -E 's#^.*github\.com[:/]##; s#\.git$##') \
    || skip_or_fail "리포지토리를 판정하지 못함"
fi
[ -n "$REPO" ] || skip_or_fail "리포지토리를 판정하지 못함"

# 브랜치 이름이 아니라 **작업 트리의 HEAD SHA** 를 쓴다.
#
# 이름은 그 사이 다른 커밋을 가리킬 수 있어 아래 해시 대조가 무엇을 비교했는지
# 모호해진다. `GITHUB_SHA` 를 쓰지 않는 이유는 다른 쪽이다 — checkout 설정에
# 따라 그 값이 지금 체크아웃된 트리와 다른 커밋일 수 있고(merge ref vs head),
# 그러면 해시가 어긋나 이 가드가 자기 설정 문제로 빨개진다. HEAD 는 정의상
# 지금 비교하려는 그 트리다.
REF=$(git rev-parse HEAD)

# ── 1. GitHub 이 그 ref 에서 본 CODEOWNERS 를 가져와 지금 파일과 대조 ──
contents_json=$(api "/repos/$REPO/contents/$CODEOWNERS?ref=$REF") \
  || skip_or_fail "$REF 에서 $CODEOWNERS 를 읽지 못함 (커밋이 아직 원격에 없거나 API 에 닿지 못함)"
remote_b64=$(printf '%s' "$contents_json" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("content",""))' 2>/dev/null)
[ -n "$remote_b64" ] || skip_or_fail "$REF 의 $CODEOWNERS 응답을 해석하지 못함"

remote_sha=$(printf '%s' "$remote_b64" | base64 -d | shasum -a 256 | awk '{print $1}')
local_sha=$(shasum -a 256 "$CODEOWNERS" | awk '{print $1}')

if [ "$remote_sha" != "$local_sha" ]; then
  # 통과시키지 않는다 — 응답이 이 편집을 검증한 것이 아니기 때문이다.
  skip_or_fail "$REF 의 $CODEOWNERS 가 작업 트리와 다르다 (검증 대상이 이 편집이 아님)"
fi

# ── 2. 오너 해석 ──
errors_json=$(api "/repos/$REPO/codeowners/errors?ref=$REF") \
  || skip_or_fail "codeowners/errors 조회 실패"

count=$(printf '%s' "$errors_json" | python3 -c 'import json,sys; print(len(json.load(sys.stdin).get("errors", [])))' 2>/dev/null)
if [ -z "$count" ]; then
  skip_or_fail "codeowners/errors 응답을 해석하지 못함"
fi

if [ "$count" != "0" ]; then
  echo "❌ CODEOWNERS 오너/문법 오류 ${count}건 — GitHub 이 이 줄들의 오너를 해석하지 못한다:"
  # f-string 안에 중첩 따옴표를 쓰지 않는다 — 이 블록은 오류가 있을 때만 도는
  # 자리라, 문법이 깨져 있어도 평소에는 아무도 모른다. 실제로 첫 판이 그랬고
  # 일부러 실패시켜 보다가 드러났다.
  printf '%s' "$errors_json" | python3 -c '
import json, sys
for e in json.load(sys.stdin).get("errors", []):
    line = e.get("line", "?")
    msg = e.get("message", "")
    src = e.get("source", "").strip()
    print(f"     {line}행: {msg}  |  {src}")
'
  echo
  echo "   오너가 해석되지 않는 줄은 리뷰를 요구하지 않는다 — 등록은 돼 있는데"
  echo "   강제되는 것이 없는 상태다. 오타난 핸들이거나, write 권한이 없거나,"
  echo "   팀이 secret 이라 GitHub 이 볼 수 없는 경우다."
  exit 1
fi

echo "✅ CODEOWNERS 오너가 전부 해석된다 (GitHub 파서, ref ${REF:0:7}, 파일 해시 일치)."
