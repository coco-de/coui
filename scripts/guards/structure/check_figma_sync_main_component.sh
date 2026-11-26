#!/usr/bin/env bash
#
# 플러그인 소스는 인스턴스의 `mainComponent` 를 **동기로 읽지 않는다**. net-new 0
# (ratchet 아님 — 오늘 0 이다).
#
# 무엇을 막는가: 셀프테스트는 전부 통과하고 실제 Figma 에서만 그 엔트리가 죽는 것.
#
# 플러그인 manifest 는 `documentAccess: "dynamic-page"` 다. 그 모드에서
# `InstanceNode.mainComponent` 는 쓰기만 되고, 읽으면 Figma 가
# `in get_mainComponent: Cannot call with documentAccess: dynamic-page. Use
# node.getMainComponentAsync instead.` 로 던진다. 셀프테스트의 Figma 대역은 그
# getter 를 평범한 필드로 두므로 읽기가 그대로 성공한다 — 대역을 바꾸면 하네스
# 자신의 수백 곳 읽기가 같이 깨진다.
#
# 실제로 그렇게 나갔다. Banner 빌더가 바인드 뒤 패스에서 `button.mainComponent?.name`
# 으로 붙은 variant 를 읽었고, 셀프테스트가 초록인 채 머지된 뒤 Generate 에서 Banner
# 엔트리가 통째로 실패했다(`✗ ❖ Banner`).
#
# 이 가드가 보는 것: `src/` · `code.ts` 의 주석을 뺀 코드에서 `.mainComponent` 를
# 읽는 자리. 대입(`x.mainComponent = …`)과 속성 참조 키
# (`componentPropertyReferences` 의 `mainComponent`, `refs.mainComponent`)는 읽기가
# 아니라 뺀다. 못 보는 것: 구조 분해(`const { mainComponent } = node`)나 문자열
# 키 접근 — 그런 형태가 나오면 이 가드를 넓힌다.
#
# Usage: check_figma_sync_main_component.sh

set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

readonly TOOL="tools/figma-token-sync"
if [ ! -d "$TOOL/src" ]; then
  echo "❌ $TOOL/src 없음 — 경로가 바뀌었으면 이 가드도 따라가야 한다."
  exit 1
fi

files=$(find "$TOOL/src" -name '*.ts' -not -path '*/data/*'; echo "$TOOL/code.ts")
checked=0
hits=""
for f in $files; do
  [ -f "$f" ] || continue
  checked=$((checked + 1))
  # 주석 줄과 줄 끝 주석을 지운 뒤 본다 — 사유를 적은 주석이 걸리지 않게.
  found=$(sed -e 's://.*$::' -e 's:^[[:space:]]*\*.*$::' "$f" \
    | grep -nE '\.mainComponent\b' \
    | grep -vE '\.mainComponent[[:space:]]*=[^=]' \
    | grep -vE '(refs|References|componentPropertyReferences)[?]?\.mainComponent' || true)
  if [ -n "$found" ]; then
    hits+=$(echo "$found" | sed "s|^|  $f:|")$'\n'
  fi
done

if [ "$checked" -lt 20 ]; then
  echo "❌ 훑은 파일이 ${checked}개뿐이다 — 볼 것이 없는 가드는 아무것도 비교하지 않고 통과한다."
  exit 1
fi

if [ -n "$hits" ]; then
  echo "❌ 동기 mainComponent 읽기 — dynamic-page 에서 Figma 가 던진다:"
  printf '%s' "$hits"
  echo "   getMainComponentAsync 를 쓰거나, 붙일 main 을 속성 정의의 기본값과 세트에서 읽어라."
  exit 1
fi
echo "✅ 동기 mainComponent 읽기 없음 (${checked}개 파일)"
