#!/usr/bin/env bash
#
# G10 (#3996) — Dart 필드 ↔ `components.json` 커버리지 판정.
#
# 왜 이 가드가 필요한가: `tools/figma-token-sync/README.md` 의 OQ-2 표는
# "어느 필드가 왜 Figma 에 못 갔는가" 를 106 행으로 적어 놓았지만, 그 사유가
# 사람 손으로 쓰였다. 표본 14 건을 Dart 소스와 대조했을 때 **11 건에서 사유가
# 틀렸다** — "no field on CoreXxxStyle" 이라 적힌 자리에 그 필드가 실재했다
# (`card.headerTextStyle` · `table.headerTextStyle` · `accordion.backgroundColor`
# · `dialog.panelBackgroundColor` · `text_field.backgroundColor` …). 그 표를
# 근거로 "Core 에 필드 추가" 작업을 잡으면 이미 있는 필드를 또 만든다.
#
# 그래서 이 가드는 **사유를 기계로 판정**한다. G1~G9 와 역할이 다르다:
#   G1  JSON 이 소스와 같은지          (신선도)
#   G3  리더가 필드를 emit 했는지       (센서스 — 리더 관점)
#   G7  빌더에 리터럴이 남았는지        (실현 관점)
#   G10 **Dart 필드가 JSON 에 도달했는지** (도달 관점) ← 이 가드
#
# G3 과 겹치지 않는다: G3 은 리더가 *발견한* 멤버를 세고, G10 은 Dart 선언에서
# 출발해 *JSON 에 없는 것* 을 센다. 리더가 애초에 못 본 필드는 G3 의 시야에
# 들어오지 않으므로 G3 은 0 을 보고하면서 G10 은 420 을 보고할 수 있다.
#
# 방법: `contracts/*/*_style.dart` 의 각 `CoreXxxStyle` 클래스에서 nullable
# 인스턴스 필드(`final T? name;`)를 뽑아, 그 이름이 `components.json` 의 해당
# 컴포넌트 서브트리 어디에든 (fields / variants.* / sizes.* 전부) 키로
# 등장하는지 본다.
#
# 두 가지를 정확히 해야 오판하지 않는다 — 둘 다 실제로 오판을 낸 자리다:
#
#   1. **서브트리 전체를 본다.** variant·size 별 default 는 `fields` 가 아니라
#      그 아래로 들어가므로 `fields` 만 보면 도달한 필드를 누락으로 센다
#      (첫 측정이 그 오류로 569 를 냈다).
#   2. **슬러그는 클래스명에서 나온다 — 파일명이 아니다.** 리더는 클래스명으로
#      컴포넌트를 식별한다(`style-contract.md` 규약 #4). 한 파일에 MAIN Style
#      이 둘인 4 건(chat_bubble · radial_progress · scroll_view_interceptor ·
#      selectable_text)에서 파일명으로 귀속시키면 도달한 필드를 엉뚱한
#      컴포넌트에서 찾아 누락으로 센다 (그 오류가 427 을 냈고, 클래스명 기준
#      으로 고쳐 420 이 됐다).
#
# 누락은 5 원인으로 분류한다 — 고칠 곳이 서로 다르기 때문이다:
#   static-final  `static final … .copyWith/.merge` default. 미해소 AST 가
#                 표현식을 평가하지 못해 리더가 못 읽는다. 고칠 곳은 리더이고,
#                 **코드가 아니다** — `core/style-contract.md` 가 그 패턴을
#                 ✅ Good 예시로 명시한다.
#   nested-slot   자식 `CoreXxxStyle?` 슬롯. raw-forward partial 이라 자식
#                 default 와 merge 해야 값이 완성된다. 고칠 곳은 리더.
#   no-default    필드는 있는데 짝이 되는 `default*` 가 없다. 고칠 곳은 Core.
#   empty-value   default 가 있으나 값이 `null` 이거나 dispatch 가 `{}`.
#                 고칠 곳은 Core.
#   unknown       위 어디에도 안 걸림 — 사람이 봐야 한다.
#
# ratchet: 누락 총합이 baseline 을 넘으면 fail. 내려가는 건 언제나 OK.
# 분류별 카운트는 리포트로만 낸다(분류 규칙이 바뀌면 총합만 고정돼야 하므로).
#
# C1 population floor: 추출이 붕괴하면(경로 이동·패턴 변경) 필드 수가 0 에
# 가까워지고 "누락 0" 으로 조용히 통과한다. Dart 필드 총수가 FLOOR 미만이면
# 추출 붕괴로 간주해 fail 한다.
#
# Usage: check_figma_field_coverage.sh [--update | --report | --self-test]

set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

readonly BASELINE="scripts/guards/structure/figma_field_coverage_baseline.txt"
# 별도 파일: "누락"(아무 통에도 없음)과 "리더가 못 읽음"(라우팅 실패)은 다른
# 실패이고 고치는 방법도 다르다 — 앞은 값을 정하거나 부재를 기록하는 일이고,
# 뒤는 리더에 AST 지원을 넣는 일이다. 한 수로 합치면 한쪽이 줄면서 다른 쪽이
# 늘어도 통과한다.
readonly UNTOK_BASELINE="scripts/guards/structure/figma_untokenized_baseline.txt"
readonly CONTRACTS="packages/coui_core/lib/src/component/contracts"
readonly JSON="tools/figma-token-sync/src/data/components.json"
readonly FLOOR=1000

if [ ! -f "$JSON" ]; then
  echo "❌ $JSON 없음 — exporter 를 먼저 돌려라 (melos run export:figma-components)."
  exit 1
fi

# ─── 측정 ────────────────────────────────────────────────────────────────────
# stdout: "<total_fields> <total_missing>" + 원인별 카운트 + (--report 시 상세)
measure() {
  # readonly 변수는 명령 앞 할당으로 재지정할 수 없으므로 별도 이름으로 넘긴다.
  env G10_MODE="${1:-count}" G10_CONTRACTS="$CONTRACTS" G10_JSON="$JSON" python3 - <<'PY'
import json, os, re, sys, glob, collections

mode = os.environ['G10_MODE']
comp = json.load(open(os.environ['G10_JSON'], encoding='utf-8'))['components']

def keys_of(node, acc):
    if isinstance(node, dict):
        for k, v in node.items():
            acc.add(k)
            keys_of(v, acc)
    elif isinstance(node, list):
        for v in node:
            keys_of(v, acc)
    return acc

INST = re.compile(r'^\s*final\s+([A-Za-z0-9_<>?]+)\s+([a-z][A-Za-z0-9_]*)\s*;', re.M)
SFINAL = re.compile(r'static\s+final\s+[A-Za-z0-9_<>]+\s+(default[A-Za-z0-9_]*)\s*=')
SCONST = re.compile(r'static\s+const\s+[A-Za-z0-9_<>,\s]+\s+(default[A-Za-z0-9_]*)\s*=')

def field_of(default_name):
    f = default_name[len('default'):]
    return f[0].lower() + f[1:] if f else ''

CLASS = re.compile(
    r'^(?:(?:final|abstract|sealed|base|interface|mixin)\s+)*'
    r'class\s+([A-Za-z0-9_]+)',
    re.M,
)
STYLE_CLASS = re.compile(r'^Core([A-Za-z0-9]+)Style$')


def slug_of(class_name):
    """`CoreRadialProgressStyle` → `radial_progress`.

    슬러그는 **클래스명**에서 나온다 — 파일명이 아니다. `style-contract.md`
    규약 #4 대로 리더가 클래스명으로 컴포넌트를 식별하기 때문이다. 파일명으로
    잡으면 한 파일에 두 MAIN Style 이 있는 4 건(chat_bubble ·
    radial_progress · scroll_view_interceptor · selectable_text)에서 필드를
    엉뚱한 컴포넌트에 귀속시켜 "도달했는데 누락" 으로 오판한다.
    """
    m = STYLE_CLASS.match(class_name)
    if not m:
        return None
    return re.sub(r'(?<!^)(?=[A-Z])', '_', m.group(1)).lower()


def class_regions(src):
    """(class_name, body_source) — 최상위 class 선언 사이를 잘라 본문으로 본다.

    brace 매칭 없이 선언 위치만으로 자른다: 이 레포의 contract 클래스는 전부
    컬럼 0 에서 시작하므로 다음 선언까지가 그 클래스의 본문이다. AST 를 쓰지
    않는 이유는 이 가드가 SDK 없는 static-guards job 에 살아야 하기 때문이다.
    """
    marks = list(CLASS.finditer(src))
    for i, m in enumerate(marks):
        end = marks[i + 1].start() if i + 1 < len(marks) else len(src)
        yield m.group(1), src[m.start():end]


total = missing = 0
causes = collections.Counter()
rows = []
absent_declared = 0
host_derived_count = 0
deprecated_count = 0
untokenized_count = 0

for path in sorted(glob.glob(f"{os.environ['G10_CONTRACTS']}/*/*_style.dart")):
    src_all = open(path, encoding='utf-8').read()
    for class_name, src in class_regions(src_all):
        slug = slug_of(class_name)
        if slug is None or slug not in comp:
            continue
        fields = {n: t for t, n in INST.findall(src) if t.endswith('?')}
        sfinal = {field_of(d) for d in SFINAL.findall(src)}
        sconst = {field_of(d) for d in SCONST.findall(src)}
        # `absent` 를 뺀 서브트리에서만 "값이 도달했다" 를 센다.
        #
        # 리더가 값 없는 필드를 `absent: {field: kind}` 로 싣기 시작했고,
        # `keys_of` 는 서브트리 전체를 훑으므로 그 키까지 도달로 세면 이 가드가
        # 131개를 값 없이 초록으로 넘긴다. 그건 부재 선언을 **가드를 통과하는
        # 수단**으로 만드는 것이고, 이 축이 재려던 것과 정반대다.
        #
        # 그래서 두 수를 따로 낸다. 값 도달은 값 도달이고, 부재 선언은
        # "Core 가 값을 두지 않기로 했다" 는 별개의 진술이며 — 그 진술이 참인지는
        # 이 가드가 아니라 캔버스 되읽기(fidelity 의 absence 검증)가 판정한다.
        declared_absent = set((comp[slug] or {}).get('absent') or {})
        # 리더가 `@Deprecated` default 의 값을 싣지 않는다 — 위젯이 적용하지 않는
        # chrome 을 캔버스가 칠하면 값이 없는 것보다 나쁘다(Core 에서 온 것처럼
        # 보인다). 값도 아니고 의도된 부재도 아니라 셋째 칸으로 센다.
        retired = set((comp[slug] or {}).get('deprecated') or [])
        # 값이 호스트에서 렌더 시점에 오는 필드(`@hostDerived`). 값도 부재
        # 선언도 아니다 — 어떤 상수도 맞지 않아서 비어 있고, 캔버스는 데모
        # 호스트의 값을 보여줄 뿐이라 되읽기도 단언할 것이 없다. 넷째 칸.
        host_derived = set((comp[slug] or {}).get('hostDerived') or [])
        # 리더가 시도했다 실패한 필드. 값도 아니고 부재 결정도 아니고 폐기도
        # 아니다 — 리더 버그다. 이제까지 exporter 의 stderr 안내문 한 줄로만
        # 존재해서 세는 게이트가 없었고, 이번 세션 중 13 → 21 로 늘었는데
        # 아무도 몰랐다. 총계만 있으면 회귀 보고가 "22개(전 21)" 로 쓸모없으므로
        # JSON 이 필드 이름을 싣고 여기서 이름으로 센다.
        unroutable = {
            u['field'].split('.')[-1]
            for u in ((comp[slug] or {}).get('untokenized') or [])
        }
        valued = {
            k: v for k, v in (comp[slug] or {}).items()
            if k not in ('absent', 'deprecated', 'hostDerived')
        }
        present = keys_of(valued, set())

        total += len(fields)
        for name, typ in sorted(fields.items()):
            if name in present:
                continue
            if name in retired:
                deprecated_count += 1
                continue
            if name in unroutable:
                untokenized_count += 1
                continue
            if name in declared_absent:
                absent_declared += 1
                continue
            if name in host_derived:
                host_derived_count += 1
                continue
            missing += 1
            bare = typ.rstrip('?')
            # 순서가 중요하다: default 가 아예 없는 필드는 타입이 무엇이든
            # 내보낼 값이 없으므로 `no-default` 다. 타입을 먼저 보면 default 없는
            # nested 슬롯이 `nested-slot` 으로 분류돼 "리더를 고치면 된다" 로
            # 읽히는데, 실제로 필요한 건 Core 에 default 를 넣는 것이다.
            if name not in sconst and name not in sfinal:
                cause = 'no-default'
            elif name in sfinal:
                cause = 'static-final'
            elif re.fullmatch(r'Core[A-Z][A-Za-z0-9]*Style', bare):
                cause = 'nested-slot'
            else:
                cause = 'empty-value'
            causes[cause] += 1
            rows.append((slug, name, bare, cause))

if mode == 'report':
    valued_reach = (
        total - missing - absent_declared - host_derived_count
        - deprecated_count - untokenized_count
    )
    print(f'Dart nullable 인스턴스 필드 : {total}')
    print(f'값이 도달                : {valued_reach}  ({valued_reach/max(total,1)*100:.0f}%)')
    print(f'부재로 선언              : {absent_declared}  (Core 가 값을 두지 않기로 한 필드)')
    print(f'호스트 파생              : {host_derived_count}  (값이 호스트에서 온다 — @hostDerived)')
    print(f'폐기됨                   : {deprecated_count}  (default 가 @Deprecated — 더 이상 적용 안 됨)')
    print(f'리더가 못 읽음           : {untokenized_count}  (값이 있는데 라우팅 실패 — 리더 버그)')
    print(f'누락                     : {missing}')
    print()
    print('원인별:')
    for c in ('static-final', 'nested-slot', 'no-default', 'empty-value', 'unknown'):
        if causes[c]:
            print(f'  {c:14} {causes[c]:4}')
    print()
    per = collections.Counter(r[0] for r in rows)
    print('누락 상위 20 컴포넌트:')
    for slug, n in per.most_common(20):
        cs = collections.Counter(r[3] for r in rows if r[0] == slug)
        detail = ' '.join(f'{k}:{v}' for k, v in cs.most_common())
        print(f'  {slug:24} {n:3}   {detail}')
    print()
    print('전체 목록 (slug · field · type · cause):')
    for slug, name, typ, cause in rows:
        print(f'  {slug:24} {name:34} {typ:26} {cause}')
else:
    parts = ' '.join(f'{c}={causes[c]}' for c in sorted(causes))
    print(f'{total} {missing} absent-declared={absent_declared} host-derived={host_derived_count} '
          f'deprecated={deprecated_count} untokenized={untokenized_count} {parts}')
PY
}

run_check() {
  local out total miss rest expected
  out=$(measure count) || return 1
  total=$(echo "$out" | awk '{print $1}')
  miss=$(echo "$out" | awk '{print $2}')
  rest=$(echo "$out" | cut -d' ' -f3-)

  if [ "$total" -lt "$FLOOR" ]; then
    echo "❌ G10 추출 붕괴 의심 — Dart nullable 필드 ${total}개 (FLOOR ${FLOOR} 미만)."
    echo "   경로/패턴이 바뀌었는지 확인: $CONTRACTS/*/*_style.dart"
    return 1
  fi

  expected=$(grep -vE '^\s*(#|$)' "$BASELINE" | tail -1 | tr -d '[:space:]')
  if [ -z "$expected" ]; then
    echo "❌ baseline 값을 못 읽음: $BASELINE"
    return 1
  fi

  if [ "$miss" -gt "$expected" ]; then
    echo "❌ Dart 필드가 components.json 에 도달하지 못한 수가 늘었다: ${miss} (baseline ${expected})."
    echo "   원인별: $rest"
    echo
    echo "   Dart 에 필드를 추가했다면 exporter 가 그것을 실어내는지 확인해라 —"
    echo "   선언만 늘고 JSON 이 안 따라오면 그 필드는 캔버스에 존재하지 않는다."
    echo "   상세: bash $0 --report"
    return 1
  fi

  # 값 도달과 부재 선언을 한 수로 합치지 않는다. 합치면 "Core 가 값을 두지
  # 않기로 했다" 가 "값이 파이프라인을 통과했다" 로 읽히고, 이 가드는 값을 하나도
  # 더 싣지 않고도 초록이 될 수 있다.
  declared=$(printf '%s' "$rest" | grep -oE 'absent-declared=[0-9]+' | cut -d= -f2)
  declared=${declared:-0}
  retired=$(printf '%s' "$rest" | grep -oE 'deprecated=[0-9]+' | cut -d= -f2)
  retired=${retired:-0}
  retired_untok=$(printf '%s' "$rest" | grep -oE 'untokenized=[0-9]+' | cut -d= -f2)
  retired_untok=${retired_untok:-0}
  untok_expected=$(grep -vE '^\s*(#|$)' "$UNTOK_BASELINE" 2>/dev/null | tail -1 | tr -d '[:space:]')
  if [ -z "$untok_expected" ]; then
    echo "❌ untokenized baseline 값을 못 읽음: $UNTOK_BASELINE"
    exit 1
  fi
  if [ "$retired_untok" -gt "$untok_expected" ]; then
    echo "❌ 리더가 라우팅에 실패한 필드가 늘었다: ${retired_untok} (baseline ${untok_expected})."
    echo "   값은 Core 에 있는데 리더가 못 읽는다 — 그 필드는 캔버스에 도달하지 않는다."
    echo "   상세: bash $0 --report"
    exit 1
  fi
  echo "✅ G10 Dart 필드 ${total} · 값 도달 $((total - miss - declared - retired - retired_untok)) · 부재 선언 ${declared} · 폐기 ${retired} · 리더실패 ${retired_untok} · 누락 ${miss}개 (baseline ${expected} 이하) · ${rest}"
  return 0
}

self_test() {
  local rc=0 target backup
  target="$CONTRACTS/card/card_style.dart"
  backup=$(mktemp)
  cp "$target" "$backup"

  echo "── self-test 1/2: JSON 에 없는 nullable 필드 주입 → red 확인"
  # 실제 코드 스타일(선언 한 줄)로 주입한다 — 주석/문자열 안에 넣으면 추출
  # 패턴이 안 잡아 self-test 가 조용히 통과한다.
  perl -0pi -e 's/(\n  final CoreTextStyle\? bodyTextStyle;)/\n  final CoreColor? g10SelfTestRegression;$1/' "$target"

  if run_check >/tmp/g10_selftest_out.txt 2>&1; then
    echo "   ❌ self-test 실패 — 필드 주입 후에도 green"
    cat /tmp/g10_selftest_out.txt
    rc=1
  else
    echo "   ✅ red 확인 (baseline 초과로 fail)"
  fi

  cp "$backup" "$target"

  echo "── self-test 2/2: 되돌림 → green 확인"
  if run_check >/tmp/g10_selftest_out.txt 2>&1; then
    echo "   ✅ green 확인"
  else
    echo "   ❌ self-test 실패 — 되돌린 뒤에도 red (false positive)"
    cat /tmp/g10_selftest_out.txt
    rc=1
  fi

  rm -f "$backup" /tmp/g10_selftest_out.txt

  if [ "$rc" -eq 0 ]; then
    echo "✅ G10 self-test 통과(주입→red · 되돌림→green)."
  else
    echo "❌ G10 self-test 실패 — 위 단계 참고."
  fi
  return "$rc"
}

case "${1:-}" in
  --self-test)
    self_test
    exit $?
    ;;
  --report)
    measure report
    exit 0
    ;;
  --update)
    out=$(measure count)
    miss=$(echo "$out" | awk '{print $2}')
    total=$(echo "$out" | awk '{print $1}')
    rest=$(echo "$out" | cut -d' ' -f3-)
    {
      grep -E '^\s*#' "$BASELINE"
      echo "#"
      echo "# $(date -u +%Y-%m-%d) (--update): Dart nullable 필드 ${total} 중 누락 ${miss}. ${rest}"
      echo "$miss"
    } >"$BASELINE.tmp"
    mv "$BASELINE.tmp" "$BASELINE"
    echo "baseline 갱신: $miss"
    exit 0
    ;;
  *)
    run_check
    exit $?
    ;;
esac
