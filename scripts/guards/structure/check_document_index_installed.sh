#!/usr/bin/env bash
#
# 컴포넌트를 이름으로 찾는 명령은 **문서 인덱스를 설치**해야 한다. **net-new 0**
# (ratchet 아님).
#
# 무엇을 막는가: 아무것도 검사하지 않고 성공처럼 끝나는 명령.
#
# 컴포넌트당 페이지(#4023) 아래에서 자식은 절대 호출자의 페이지에 없다 — `Button`
# 은 `❖ Button` 에, 그것이 인스턴스하는 `Icon` 은 `❖ Icon` 에 있다. `helpers` 의
# 조회(`findComponentByName` 계열)는 **문서 인덱스가 설치돼 있을 때만** 문서 전체를
# 본다. 설치되지 않으면 인수로 받은 페이지만 훑고 — 정확히 아무것도 못 찾는다.
#
# 실제로 그렇게 됐다. `generate` 는 인덱스를 설치했고, 읽기 전용 명령 둘은 자기
# 페이지-지역 조회를 그대로 갖고 있었다. 그 결과:
#
#   · 충실도 검증 — `No "🧩 Components" page. Nothing was checked, which is not
#     the same as nothing being wrong.` 문장 자체는 정직했다. 그리고 쓸모없었다:
#     값이 맞는지 판정하는 검사가 **한 번도 돌 수 없었다**.
#   · 테마 프리뷰 — `Run "Generate Components" first.` 로 거부. 모든 컴포넌트가
#     이미 빌드된 문서에서.
#
# 둘 다 실패로 보이지 않는다. 하나는 성공적으로 0 을 보고하고, 하나는 사용자에게
# 이미 한 일을 하라고 시킨다. 그래서 이 형태는 로그를 읽어도 안 보인다.
#
# 두 번째 형태: **빌더를 구동하는 파일**. 빌더는 자기 안에서 자식 조회를 부르므로,
# 구동하는 쪽이 인덱스 상태를 통제해야 한다 — 설치하거나 **명시적으로 비우거나**.
# `verify.ts` 가 그 경우였다: 빈 scratch 페이지에 prerequisite 를 민팅하고 그것이
# 자식으로 해소되는 것에 주장 전체가 걸려 있는데, 앞선 명령이 남긴 인덱스가 있으면
# 자식이 문서의 다른 노드로 해소된다. 그러면 정체성 비교와 PNG diff 가 리셋 스윕이
# 만들지 않는 트리를 재는 셈이고, 둘 다 조용히 통과하거나 조용히 실패한다.
#
# 이 가드가 보는 것: 명령 모듈이 자식 조회를 쓰면서 인덱스를 설치하지 않는 상태.
# 못 보는 것: 인덱스를 설치하고도 그 결과를 안 쓰는 경우 — 그건 fidelity 하네스가
# 본다(컴포넌트당 페이지 double 을 쓰므로 페이지-지역 조회를 넣으면 읽는 컴포넌트가
# 143 → 1 로 떨어져 주입 검사가 red 가 된다). 정적 검사와 하네스는 서로를
# 대신하지 못한다.
#
# Usage: check_document_index_installed.sh

set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

readonly TOOL="tools/figma-token-sync"
readonly ENTRY="$TOOL/code.ts"

if [ ! -f "$ENTRY" ]; then
  echo "❌ $ENTRY 없음 — 경로가 바뀌었으면 이 가드도 따라가야 한다."
  exit 1
fi

# 명령 모듈 = 플러그인 진입점이 import 하는 `./src/*` 모듈. 목록을 손으로 들지
# 않는다 — 새 명령이 추가되면 그것도 자동으로 대상이 된다.
modules=$(grep -oE "from '\./src/[a-z-]+'" "$ENTRY" | sed -e "s|from '\./|$TOOL/|" -e "s|'|.ts|" | sort -u)

count=$(echo "$modules" | grep -c . || true)
if [ "$count" -lt 4 ]; then
  echo "❌ 진입점이 import 하는 명령 모듈이 ${count}개뿐이다 — import 형태가 바뀌었고,"
  echo "   볼 것이 없는 가드는 아무것도 비교하지 않고 통과한다."
  exit 1
fi

# 자식 조회 헬퍼. 이 중 하나라도 호출하면 그 모듈은 문서 전체를 봐야 한다.
readonly LOOKUPS='findComponentByName|instanceOf|bestVariantName|iconMainId|mainComponentIdOf'

# 주석을 지운 뒤 CALL 형태로 본다 — 사유를 적은 주석이 그 사유를 검사하는 가드를
# 무력화하는 일이 이 레포에서 이미 한 번 있었다(check_build_order_shared.sh).
#
# 파이프가 아니라 herestring 으로 먹인다. `echo "$code" | grep -q` 는 `grep -q` 가
# 첫 매치에서 즉시 끝나 남은 입력을 쓰던 `echo` 를 SIGPIPE 로 죽이고, 위에 켜 둔
# `pipefail` 이 그 죽음을 파이프라인 상태로 올려 **매치를 실패로 뒤집는다**.
#
# 이 가드에서 그 뒤집힘은 빨갛게 나지 않는다 — 아래 게이트가 `|| continue` 라서
# "이 모듈은 자식 조회를 안 쓴다" 로 읽히고 검사 자체가 건너뛰어진다. 즉 침묵하는
# 초록이다. 매치 뒤 남은 바이트가 커널이 준 파이프 버퍼(맥 기본 16KB)보다 커야
# 일어나는데, 이 가드가 훑는 모듈 중 13 개가 그 조건에 해당한다(잔여 최대 50KB).
missing=""
checked=0
for f in $modules; do
  [ -f "$f" ] || continue
  code=$(sed -e 's://.*::' -e '/^[[:space:]]*\*/d' "$f")
  grep -qE "\b($LOOKUPS)\s*\(" <<<"$code" || continue
  checked=$((checked + 1))
  # 인덱스를 직접 설치하거나(`indexDocumentComponents` → `installNodeIndex`),
  # 자기가 전 페이지를 순회하며 인덱스를 세워 넘기는 형태 둘 다 인정한다.
  if ! grep -qE 'indexDocumentComponents\s*\(|installNodeIndex\s*\(' <<<"$code"; then
    missing="$missing $f"
  fi
done

if [ "$checked" -eq 0 ]; then
  echo "❌ 자식 조회를 쓰는 명령 모듈이 0개 — 헬퍼 이름이 바뀌었다."
  echo "   LOOKUPS 목록을 현재 이름으로 갱신해라. 이 가드는 지금 아무것도 보지 않는다."
  exit 1
fi

# 빌더 구동 파일 — 인자 이름이 아니라 호출 형태로 본다(check_tint_flush.py 가 인자
# 이름에 키잉해 자기 주 대상을 놓친 적이 있다).
drivers=$(grep -rlE '\b\w+\.build\(\s*[A-Za-z_]' "$TOOL/src" --include='*.ts' 2>/dev/null | sort -u)
for f in $drivers; do
  code=$(sed -e 's://.*::' -e '/^[[:space:]]*\*/d' "$f")
  checked=$((checked + 1))
  if ! grep -qE 'indexDocumentComponents\s*\(|installNodeIndex\s*\(|clearNodeIndex\s*\(' <<<"$code"; then
    missing="$missing $f(driver)"
  fi
done

if [ -n "$missing" ]; then
  echo "❌ 자식 조회를 쓰면서 문서 인덱스를 설치하지 않는 명령 모듈:"
  for m in $missing; do echo "   ✗ $m"; done
  echo
  echo "   installNodeIndex(await indexDocumentComponents()) 를 명령 시작에서 불러라."
  echo "   빌더를 구동하는 파일이라면 clearNodeIndex() 로 명시적으로 비우는 것도 답이다 —"
  echo "   빈 페이지에 자식을 민팅해 쓰는 경우가 그렇다. 통제하지 않는 것만 위반이다."
  echo "   컴포넌트당 페이지에서 자식은 호출자의 페이지에 없다 — 인덱스 없이는 조회가"
  echo "   인수로 받은 페이지만 훑고 아무것도 못 찾는다. 그 상태의 명령은 실패하지"
  echo "   않는다: 0 을 검사하고 성공을 보고한다."
  exit 1
fi

echo "✅ 자식 조회를 쓰는 명령 모듈 ${checked}개 전부 문서 인덱스 설치 (하드 0)."
