#!/usr/bin/env bash
# viewport meta — 앱 진입 HTML 마다 정확히 하나, 그리고 확대를 막지 않는다.
#
# WCAG 1.4.4 (Resize Text, AA) 는 사용자가 텍스트를 200% 까지 키울 수 있어야
# 한다고 요구한다. `user-scalable=no` 나 `maximum-scale=1` 은 브라우저의 핀치
# 줌을 통째로 꺼서 그 요구를 페이지 단위로 무효화한다. 상류 Flutter Web 도
# 같은 이유로 자기 `flt` viewport 를 WCAG 에 맞췄다.
#
# 왜 "정확히 하나" 를 세는가: 실제로 난 결함은 잘못된 meta 하나가 아니라
# **유효한 meta 둘** 이었다 — 위쪽은 옳았고 아래쪽이 확대를 막았으며, 문서
# 순서상 아래쪽이 이긴다. 둘 다 개별로는 정상이라 "user-scalable=no 만 잡는"
# 검사는 첫 줄만 보고 통과할 수 있다. 개수를 세야 두 번째가 보인다.
#
# 대상은 앱 진입점 `**/web/index.html` 이다. 벤더 미리보기 페이지(icons/)와
# 코드젠 산물 백업(`*.original`), 빌드 출력은 대상이 아니다.
#
# Fail-closed: 대상을 하나도 못 찾으면 그것도 실패다 — 검사할 게 없어 초록인
# 가드는 가드가 아니다.
set -u
cd "$(git rev-parse --show-toplevel)"

files=$(git ls-files '*/web/index.html' | grep -vE '/(build|\.dart_tool|node_modules)/|icons/' || true)
if [ -z "$files" ]; then
  echo "❌ viewport: no app entry index.html found under */web/ — nothing to check is a failure."
  exit 1
fi

fail=0; n=0
while IFS= read -r f; do
  n=$((n+1))
  count=$(grep -ciE '<meta[^>]*name="viewport"' "$f" || true)
  if [ "$count" -ne 1 ]; then
    echo "❌ $f — viewport meta $count 개 (정확히 1 이어야 한다)"
    grep -niE '<meta[^>]*name="viewport"' "$f" | sed 's/^/     /'
    fail=1; continue
  fi
  if grep -iE '<meta[^>]*name="viewport"' "$f" | grep -qiE 'user-scalable\s*=\s*(no|0)|maximum-scale\s*=\s*1(\.0*)?\b'; then
    echo "❌ $f — viewport 가 확대를 막는다 (user-scalable=no / maximum-scale=1): WCAG 1.4.4"
    grep -niE '<meta[^>]*name="viewport"' "$f" | sed 's/^/     /'
    fail=1
  fi
done <<< "$files"

[ "$fail" -eq 0 ] && echo "✅ viewport: $n 개 진입 HTML 전부 meta 정확히 1개, 확대 허용." 
exit $fail
