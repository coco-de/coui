#!/usr/bin/env bash
#
# 설정은 preflight 를 끈다고 선언하는데, 실행 중인 사이트에는 preflight 가 있다.
#
# `theme_config.dart` 는 `corePlugins:{preflight:false}` 를 쓴다. 그런데 Play CDN
# 은 `<script src>` 로 로드되는 즉시 기본 설정(preflight 켜짐)으로 초기화하고 그
# 다음 줄의 `tailwind.config = {...}` 가 설정을 덮으므로, 처음 주입된 preflight
# `<style>` 은 그대로 남는다. CSSOM 으로 확인하면 `*, ::after, ::before
# { border-style: solid }` 가 살아 있다.
#
# 그래서 Tailwind v3 의 `border` / `border-2` 유틸리티가 **그려진다**. 그 유틸은
# `border-width` 만 쓰고 `border-style` 은 preflight 가 놓기 때문이다. preflight
# 가 없으면 `border-style: none` → used `border-width: 0` → 테두리가 조용히
# 사라진다. 없어지는 것은 테두리뿐이고 아무것도 던지지 않는다.
#
# 이 우연이 사라지는 경로는 전부 실재한다 — 빌드타임 Tailwind 전환(그때는
# `preflight:false` 가 실제로 먹는다) · 설정 주입 순서 변경 · CDN 버전 업.
# `tool/parity/vendor/tailwind/` 가 3.4.17 을 vendoring 하고 있으므로 첫 번째는
# 가상의 얘기가 아니다.
#
# 어느 쪽으로 정할지는 **보류**다 — 빌드타임 전환 로드맵이 정해져야 A(의도적으로
# 켠다)와 B(정말로 끈다)가 갈린다. 그때까지 이 가드는 그 불일치가 **조용히 더
# 벌어지는 것만** 막는다: preflight 에 기대는 파일 수를 세어 net-new 0.
# 로드맵이 정해지면 이 baseline 이 곧 B 의 작업 목록이다.
#
# 세는 것: Web 컴포넌트 resolver(`*_style.dart`) 중
#   (a) Tailwind **border-width 유틸리티 클래스**를 emit 하면서
#   (b) 같은 파일 어디에도 `border-style` 을 선언하지 않는 것.
# (b) 를 가진 파일은 preflight 가 사라져도 자기 테두리를 그린다 — 이미 방어했다.
#
# 이 가드가 보지 못하는 것: 그 클래스가 실제로 화면에 테두리를 그리는지, 그리고
# `border-style` 선언이 그 클래스를 쓰는 **바로 그 요소**에 붙는지. 둘 다 렌더를
# 봐야 알 수 있고, 이 가드는 소스만 본다. 파일 단위가 과소도 과대도 아닌 이유는
# 하나뿐이다 — 한 resolver 가 그리는 요소들은 같이 살고 같이 죽는다.
#
# 스캐너는 `--self-test` 로 자기를 실패시켜 볼 수 있다. 실패시켜 보지 않은
# 검출기는 검출기가 아니다 — 이 가드의 첫 판은 perl 이 정규식 컴파일에 실패해
# 한 파일도 못 읽은 채 "✅ 0개" 를 출력했다(그 상태에서는 숫자를 내리라고까지
# 권했다). 그래서 스캔 결과가 통째로 비면 fail-closed 한다.

set -uo pipefail

_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# `.` 는 호출자의 위치 인자를 그대로 물려준다 — 인자 없이 source 하면 이
# 스크립트의 `--self-test` 가 ratchet.sh 의 `--self-test` 로도 읽혀 엉뚱한
# 하네스가 돈다(실측). 그래서 매칭되지 않는 인자를 명시적으로 준다.
# shellcheck source=../lib/ratchet.sh
. "$_GUARD_DIR/../lib/ratchet.sh" --load-only

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$REPO_ROOT"

SCAN_ROOT="packages/coui_web/lib/src/components"
CONFIG_FILE="packages/coui_web/lib/src/base/theme_config.dart"

# 따옴표 문자열만 본다. 그중 **맵 키**(뒤에 `]` 나 `:` 가 오는 것)는 먼저
# 지운다 — `raw['border']` 는 CSS shorthand 라 style 을 스스로 담고,
# `'border-radius':` 는 애초에 width 가 아니다. 이 제외가 없으면 둘 다 위반으로
# 잡힌다(실측: 그 상태의 첫 판은 31 이 아니라 77 을 셌다).
read -r -d '' SCANNER <<'PERL' || true
while (<>) {
  next if /^\s*\/\//;
  s/'[^']*'\s*(\]|:)/ /g;
  # 구분자는 `!` 다 — `m{...}` 를 쓰면 perl 이 문자 클래스 안의 `}` 를
  # 구분자 끝으로 세어 정규식이 조용히 잘린다(실측: 컴파일 에러로 터졌다).
  while (m!(?:^|[ '])(border(?:-[trblxy])?(?:-(?:stroke[1-9][0-9]*|[1-9][0-9]*))?)(?=[ '])!g) {
    print "$1\n";
  }
  while (m!(border(?:-[trblxy])?-\$\{[^}]*[Ss]troke[^}]*\})!g) { print "$1\n" }
}
PERL

scan() { perl -e "$SCANNER" "$1" | sort -u; }

self_test() {
  local tmp fails=0 out
  tmp=$(mktemp -d)

  _case() { # label file-content expected-tokens(space separated, empty = none)
    local label="$1" content="$2" want="$3" got
    printf '%s\n' "$content" > "$tmp/case.dart"
    got="$(scan "$tmp/case.dart" | tr '\n' ' ')"
    got="${got% }"
    if [ "$got" = "$want" ]; then
      printf '  ✅ %s\n' "$label"
    else
      printf '  ❌ %s: got [%s], want [%s]\n' "$label" "$got" "$want"
      fails=$((fails + 1))
    fi
  }

  _case "bare border class"        "classes: 'flex border rounded-radius8',"      "border"
  _case "sided border class"       "classes: 'border-b border-t',"                "border-b border-t"
  _case "numeric width"            "classes: 'border-2',"                         "border-2"
  _case "interpolated stroke"      'classes: '"'"'border-${w.tailwindStroke}'"'"',' 'border-${w.tailwindStroke}'
  _case "inline shorthand key"     "raw['border'] = '1px solid red';"             ""
  _case "css property keys"        "raw = {'border-radius': x, 'border-width': y, 'border-color': z};" ""
  _case "colour utility only"      "classes: 'border-outline',"                   ""
  _case "zero width"               "classes: 'border-0',"                         ""
  _case "comment line"             "// classes: 'border rounded'"                 ""

  rm -rf "$tmp"
  [ "$fails" -eq 0 ]
}

if [ "${1:-}" = "--self-test" ]; then
  echo "tailwind preflight scanner self-test"
  self_test && { echo "✅ 스캐너 정상"; exit 0; } || { echo "❌ 스캐너 결함"; exit 1; }
fi

BASELINE=$(ratchet_int "$_GUARD_DIR/tailwind_preflight_drift_baseline.txt") || exit 1

# 전제 확인 — 설정이 아직 preflight 를 끈다고 선언하는가.
#
# 선언이 사라졌다는 것은 이 이슈가 A 로 결정됐다는 뜻이고, 그러면 세는 일 자체가
# 무의미해진다. 그 상태에서 조용히 계속 세면 이 가드는 아무 뜻도 없는 숫자를
# 지키는 게이트가 된다 — 그래서 여기서 멈추고 사람을 부른다.
if ! grep -q 'corePlugins:{preflight:false}' "$CONFIG_FILE" 2>/dev/null; then
  echo "✗ ${CONFIG_FILE}"
  echo "    'corePlugins:{preflight:false}' 선언이 없다."
  echo "    이 가드는 '설정은 끈다는데 런타임엔 켜져 있다' 는 불일치를 세는"
  echo "    것이므로, 그 선언이 사라졌으면 세는 대상이 정의되지 않는다."
  echo "    preflight 를 의도적으로 켠 것이면 이 가드를 은퇴시켜라."
  exit 1
fi

relies=0
emitters=0
listed=()

while IFS= read -r f; do
  [ -z "$f" ] && continue
  hits="$(scan "$f" | tr '\n' ' ')"
  [ -z "${hits// /}" ] && continue
  emitters=$((emitters + 1))
  # 이미 방어한 파일 — preflight 가 없어도 자기 테두리를 그린다.
  # here-string 으로 받는다 — `pipefail` 아래에서 `... | grep -q` 는 매치 시
  # EPIPE 로 종료 상태가 뒤집힌다(check_guard_sigpipe.sh 가 그걸 센다).
  code="$(grep -vE '^[[:space:]]*//' "$f")"
  if grep -q "'border-style'" <<<"$code"; then
    continue
  fi
  relies=$((relies + 1))
  listed+=("${f#"$SCAN_ROOT"/}  [${hits% }]")
done < <(find "$SCAN_ROOT" -name '*_style.dart' | sort)

# fail-closed — 한 파일도 못 읽었으면 그건 "위반 0" 이 아니라 스캐너 고장이다.
if (( emitters == 0 )); then
  echo "✗ border 유틸을 emit 하는 파일을 하나도 못 찾았다 — 스캐너가 고장났다."
  echo "    $0 --self-test 로 확인해라."
  exit 1
fi

# 로드맵이 정해지면 이 목록이 곧 B(정말로 끈다)의 작업 목록이다.
if [ "${1:-}" = "--list" ]; then
  echo "preflight 에 기대는 Web resolver ${relies}개 (border emit ${emitters}개 중):"
  for l in "${listed[@]}"; do echo "  $l"; done
  exit 0
fi

if (( relies > BASELINE )); then
  echo "✗ preflight 에 기대는 Web resolver 가 늘었다: ${relies} (baseline ${BASELINE})"
  echo
  for l in "${listed[@]}"; do echo "    $l"; done
  echo
  echo "    Tailwind border-width 유틸은 'border-style' 을 놓지 않는다 —"
  echo "    그건 preflight 가 놓고, 이 레포의 설정은 preflight 를 끈다고"
  echo "    선언한다. 새로 추가하는 자리는 같은 요소의 inline CSS 에"
  echo "    'border-style': 'solid' 를 함께 emit 해라."
  exit 1
fi

if (( relies < BASELINE )); then
  echo "✅ preflight 의존 ${relies}개 / border emit ${emitters}개 (baseline ${BASELINE}) — 줄었다. baseline 을 ${relies} 로 내려라."
  exit 0
fi

echo "✅ preflight 의존 ${relies}개 / border emit ${emitters}개 — baseline(${BASELINE}) 그대로, net-new 0."
