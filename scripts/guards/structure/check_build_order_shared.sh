#!/usr/bin/env bash
#
# 빌더를 구동하는 모든 것이 **같은 순서 함수**를 써야 한다 — `topoSortRegistry`.
# **net-new 0** (ratchet 아님).
#
# 무엇을 막는가: 하네스는 초록인데 실제 실행에서 절반이 죽는 상태.
#
# 컴포넌트의 절반 이상(106/144)이 `needs: ['Icon']` 같은 자식 의존성을 갖는다.
# `topoSortRegistry` 가 자식을 먼저 놓고, 그 순서가 아니면 부모가 없는 자식을
# 찾다 죽는다 — `makeIcon('info'): the Icon component is not on the page yet`.
#
# 실제로 그렇게 됐다. 하네스는 `topoSortRegistry(REGISTRY)` 로 구동했고,
# `generate.ts` 는 섹션→이름 byte-order 로 정렬했다. 둘은 **다른 순서**였고
# 검사받는 쪽만 옳았다. 그래서 하네스 144/144 초록 · 실제 실행 34개가 needs 로
# 실패 — 그리고 그 실패들의 per-entry undo 가 직전 Import 를 되돌려 문서의
# 변수가 전부 사라졌다. 로그에는 143 줄의 서로 다른 변수 id 만 남았다.
#
# 이 가드가 요구하는 것: 빌더를 구동하는 파일은 `topoSortRegistry` 를 호출하고,
# 그 결과를 구동 순서로 쓴다. 하네스가 프로덕션을 대표하지 못하면 하네스의 초록은
# 프로덕션에 대해 아무 말도 하지 않는다.
#
# 이 가드가 못 보는 것: 결과를 받아 **다시 정렬**하는 경우. 그건 `generate.ts` 가
# 런타임에 자기 순서를 `needs` 로 검증해 로그 첫 줄에 보고한다 — 정적 검사와
# 런타임 검증은 서로를 대신하지 못한다.
#
# Usage: check_build_order_shared.sh

set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

readonly TOOL="tools/figma-token-sync"

if [ ! -d "$TOOL" ]; then
  echo "❌ $TOOL 이 없다 — 경로가 바뀌었으면 이 가드도 따라가야 한다."
  exit 1
fi

# 코드만 남긴다 — 주석과 문자열 리터럴의 **내용**을 지운다 (문자열은 빈 `""` 로 남는다).
#
# 이 가드는 텍스트로 코드를 판정한다. 그래서 코드가 아닌 텍스트가 코드로 읽히는 길을
# 모두 막아야 하고, 그 길은 둘이었다 — 둘 다 실제로 열려 있었다.
#   · `topoSortRegistry` 판정: 처음엔 파일에 그 이름이 있는지만 봤고, 그 가드는 회귀
#     주입에 **통과했다** — 정렬을 이름 순으로 되돌리고 import 를 지웠는데도, 왜 이렇게
#     해야 하는지 설명하는 주석에 이름이 남아 있었기 때문이다. 사유를 적는 행위가 그
#     사유를 검사하는 가드를 무력화한 셈이다.
#   · 구동 파일 판정: 하네스가 generate.ts 의 소스를 **문자열로** 검사하는 줄
#     (`generate.indexOf('node = await e.build(targetPage, lk)')`) 이 구동 호출로 읽혀,
#     빌더를 구동하지 않는 파일이 구동 파일로 잡혔다. 원문을 그대로 grep 하는 판정이라
#     주석 속의 같은 텍스트도 똑같이 걸린다.
# 두 판정이 이 한 함수가 정의하는 "코드" 만 본다. 한쪽만 고치면 다른 쪽에 같은 구멍이
# 남는다.
#
# 한 번의 스캔이 문자열·주석 중 먼저 시작하는 것부터 소비한다 — 문자열 안의 `//` 와
# 주석 안의 따옴표가 서로를 오인하지 않는다.
#
# 못 보는 것: 정규식 리터럴 안의 따옴표나 `//` (그 줄의 나머지를 먹는다), 템플릿
# 리터럴의 `${ … }` 안의 코드 (템플릿 전체를 문자열로 본다). 구동 호출이 그런 자리에
# 있어 구동 파일이 사라지면 아래 개수 점검이 막는다.
strip_to_code() {
  perl -0777 -pe '
    s{
        ( "(?:\\.|[^"\\\n])*"
        | \x27(?:\\.|[^\x27\\\n])*\x27
        | `(?:\\.|[^`\\])*` )
      | //[^\n]*
      | /\*.*?\*/
    }{ defined $1 ? q("") : q() }gsex
  ' "$1"
}

# 한 파일을 판정한다 — 출력은 한 줄: `driver=yes|no topo=yes|no|-`.
#   driver : 빌더를 구동하는가 (REGISTRY 의 build 슬롯을 호출하는가)
#   topo   : 구동한다면 `topoSortRegistry(` 를 **호출**하는가
#
# 파이프가 아니라 herestring 으로 먹인다. `echo "$code" | grep -q` 는 이 가드에서
# **매치했는데 실패로 읽히는** 상태를 만든다: `grep -q` 는 첫 매치에서 즉시 끝나고,
# 그때 남은 입력을 쓰던 `echo` 가 SIGPIPE 로 죽는다. 파일 위쪽에 켜 둔 `pipefail` 이
# 그 죽음을 파이프라인의 종료 상태로 올려, grep 이 찾았다는 사실을 덮는다. `!` 가 그걸
# 뒤집으면 준수하는 파일이 위반으로 보고된다.
#
# 이건 조건이 맞을 때만 나타난다 — 매치 뒤에 남은 바이트가 커널이 준 파이프 버퍼보다
# 커야 `echo` 가 블록한다. 드라이버 하나가 주석 제거 후 60KB 이고 매치가 그 절반
# 지점에 있어, 같은 커밋이 러너에서 한 번 통과하고 한 번 실패했다. herestring 은
# 파이프가 아니라 임시 파일이라 SIGPIPE 자체가 없다.
classify() {
  local code
  code=$(strip_to_code "$1")
  if ! grep -qE '\b\w+\.build\(\s*(page|targetPage)' <<<"$code"; then
    echo "driver=no topo=-"
  elif grep -qE 'topoSortRegistry\s*\(' <<<"$code"; then
    echo "driver=yes topo=yes"
  else
    echo "driver=yes topo=no"
  fi
}

# 자기 시험 — 매 실행마다, 스캔 앞에서 돈다. 판정이 조용히 틀어지면(구동 파일을 못
# 찾거나, 문자열·주석 속 호출을 구동으로 읽거나, 주석 속 이름을 호출로 읽으면) 가드는
# 깨끗한 트리와 똑같이 보고하거나 멀쩡한 파일을 위반으로 보고한다. 그래서 알려진
# 모양으로 먼저 증명한다: 파일마다 기대 판정이 fixtures/build_order.expected.txt 에 있다.
selftest() {
  local dir="scripts/guards/structure/fixtures" name got expected
  got=$(for name in \
    build_order_compliant \
    build_order_driver_without_topo \
    build_order_real_call_after_comment_apostrophe \
    build_order_real_call_after_url_string \
    build_order_text_only; do
    printf '%s %s\n' "$name" "$(classify "$dir/$name.ts.txt")"
  done)
  expected=$(cat "$dir/build_order.expected.txt")
  if [ "$got" != "$expected" ]; then
    echo "❌ build-order self-test: 판정이 알려진 모양을 잘못 읽었다."
    echo "--- expected ($dir/build_order.expected.txt)"
    printf '%s\n' "$expected"
    echo "--- got"
    printf '%s\n' "$got"
    exit 1
  fi
}

selftest

# 빌더를 구동하는 파일 = REGISTRY 의 build 슬롯을 호출하는 파일. 원문에 `.build(` 가 있는
# 파일만 후보로 잡는다 — 주석·문자열을 지우면 후보는 줄기만 하므로 후보를 넓게 잡아도
# 놓치는 것이 없고, 판정은 classify 가 코드만 보고 한다.
# (`check_tint_flush.py` 는 자기 기준을 따로 쓴다 — 원문을 그대로 보고 인자 이름을
# 가리지 않는다. 두 가드의 구동 파일 집합은 같지 않을 수 있다.)
drivers=""
missing=""
for f in $(grep -rlE '\.build\(' "$TOOL/src" "$TOOL/scripts" --include='*.ts' 2>/dev/null | sort -u); do
  case "$(classify "$f")" in
    "driver=yes topo=yes") drivers="$drivers$f"$'\n' ;;
    "driver=yes topo=no")  drivers="$drivers$f"$'\n'; missing="$missing $f" ;;
  esac
done

count=$(grep -c . <<<"$drivers" || true)
if [ "$count" -lt 2 ]; then
  echo "❌ 빌더를 구동하는 파일이 ${count}개뿐이다 — '.build(page' 형태가 바뀌었고,"
  echo "   볼 것이 없는 가드는 아무것도 비교하지 않고 통과한다."
  exit 1
fi

if [ -n "$missing" ]; then
  echo "❌ topoSortRegistry 를 쓰지 않고 빌더를 구동하는 파일:"
  for m in $missing; do echo "   ✗ $m"; done
  echo
  echo "   topoSortRegistry(REGISTRY) 의 순서로 구동해라. 컴포넌트 절반 이상이"
  echo "   needs 로 자식을 요구하고, 다른 순서로 돌리면 부모가 자식보다 먼저 와서"
  echo "   'the Icon component is not on the page yet' 로 죽는다. 하네스와 프로덕션이"
  echo "   다른 순서를 쓰면 하네스의 초록은 프로덕션에 대해 아무 말도 하지 않는다."
  exit 1
fi

# 런타임 검증이 살아 있는지 — 정적으로 잡을 수 없는 "결과를 다시 정렬" 을 보는 쪽.
if ! grep -q 'build order violates' "$TOOL/src/generate.ts"; then
  echo "❌ generate.ts 가 자기 빌드 순서를 needs 로 검증하지 않는다."
  echo "   topoSortRegistry 를 부르고도 그 결과를 다시 정렬하면 이 가드는 통과하고"
  echo "   순서는 깨진다 — 런타임 검증이 그 구멍을 본다."
  exit 1
fi

echo "✅ 빌더 구동 파일 ${count}개 전부 topoSortRegistry 사용 · generate 런타임 순서 검증 보유 (하드 0)."
