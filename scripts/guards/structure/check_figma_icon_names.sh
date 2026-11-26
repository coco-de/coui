#!/usr/bin/env bash
#
# A-4 / G13 (#3996) — Figma 빌더의 아이콘 이름과 데이터가 맞물려 있는지.
#
# 네 가지를 본다. 넷 다 **net-new 0** 이 아니라 성질이 달라서 따로 적는다.
#
#   (1) `makeIcon('name')` 의 모든 이름이 `src/data/icons.json` 에 있는가
#       — net-new 0. 없는 이름은 `makeIcon` 이 throw 하고, 그 엔트리는 실패로
#         기록된 뒤 실행은 계속된다 — **롤백되지 않는다**. per-entry undo 는
#         의도적으로 제거돼 있어(`generate.ts` 의 `No triggerUndo() here.`),
#         throw 한 빌더가 그리다 만 노드가 캔버스에 그대로 남는다. 없는 것보다
#         나쁘다: 완성된 컴포넌트처럼 보인다. 로그를 열지 않으면 알 수 없다.
#         `size/*` dangling 변수가 101 중 33 개를 조용히 지웠던 것과 같은
#         실패 경로다(G12).
#
#   (2) `icons.json` 이 `gen-icons.ts` 의 `ICON_NAMES` 와 일치하는가
#       — net-new 0. 생성물이 stale 하면 (1) 이 통과하면서도 런타임에 없는
#         이름이 생긴다. 재생성해서 비교하는 것이 유일한 판정이다
#         (`check_figma_export_fresh.sh` 가 components.json 에 하는 것과 같다).
#
#   (4) `icon-keys.json` 이 `ICON_NAMES` 와 맞물려 있는가 — net-new 0.
#       상세는 아래 (4) 블록 주석.
#
#   (3) 아이콘 자리에 남은 **텍스트 글리프** 개수 — ratchet.
#       빌더가 `makeLabel('✕', …)` 로 문자를 세워두면 (a) 폰트 의존이 생기고
#       (b) 코드가 그리는 마크가 아니며 (c) 문자라서 아이콘으로 교체할 수
#       없다. 0 이 목표지만 지금 남은 것들은 **콘텐츠 텍스트**(`'•••'` 노치,
#       `'Search…'` 플레이스홀더, 목록 데모의 음표)와 근거 없는 자리 하나라서
#       한 번에 0 이 되지 않는다 — 내려가는 것만 허용한다.
#
# 왜 (3) 이 별도 가드가 아니라 여기 붙는가: 이름 검사와 같은 파일을 훑고,
# 둘이 갈리면 "글리프를 아이콘으로 바꿨다" 는 주장을 어느 쪽도 단독으로
# 검증하지 못한다 — 이름만 맞으면 안 쓰는 아이콘이 등록돼 있어도 통과하고,
# 개수만 줄면 없는 이름을 써도 통과한다.
#
# 2026-08-07: 아이콘 *이름 선택* 은 이 가드가 보지 않는다. 여기서 보는 것은
# "그 이름이 카탈로그에 있는가" 이고, **그 이름이 위젯이 그리는 아이콘인가** 는
# 별개 질문이다. 실제로 세 컴포넌트가 어긋나 있었다 — DraggablePanel 은 위젯이
# `menu` 인데 `grip-vertical`, Label 은 `mail` 인데 `info`, RefreshTrigger 는
# `arrowDown` 인데 `chevron-down`. 전부 이 가드 green 상태에서.
#
# 그 질문은 G14(합성 파리티)와 같은 계열이다 — "빌더가 그리는 것이 위젯이 그리는
# 것인가". 아이콘 축까지 G14 로 옮기는 것이 맞고, 지금은 여기 적어 다음 사람이
# 이 가드의 green 을 "아이콘이 맞다" 로 읽지 않게 한다.
#
# 2026-08-06: 텍스트 글리프 7 → 5. 남은 5건은 전부 콘텐츠 텍스트다 — mockup
# 노치의 `'•••'`, 플레이스홀더 `'Search…'`, 목록 데모의 음표, mockup 코드 줄.
# 아이콘 슬롯이 아니라 그 자리에 있는 게 정말 문자다.
#
# Usage: check_figma_icon_names.sh [--update | --report]

set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

readonly PLUGIN="tools/figma-token-sync"
readonly BUILDERS="$PLUGIN/src/components"
readonly ICONS="$PLUGIN/src/data/icons.json"
readonly GEN="$PLUGIN/scripts/gen-icons.ts"
readonly BASELINE="scripts/guards/structure/figma_text_glyph_baseline.txt"

if [ ! -f "$ICONS" ]; then
  echo "❌ $ICONS 없음 — (cd $PLUGIN && npm run gen:icons)"
  exit 1
fi

mode="${1:-check}"

# ── (2) 생성물 freshness ─────────────────────────────────────────────────────
# 재생성은 파일을 덮으므로 사본을 먼저 떠서 비교하고 되돌린다 — 가드가 사람의
# 작업물을 바꿔놓고 통과하면 그건 검사가 아니다.
tools_ready=0
if command -v npm >/dev/null 2>&1 && [ -d "$PLUGIN/node_modules" ]; then
  tools_ready=1
fi

fresh_state=skipped
if [ "$tools_ready" = 1 ]; then
  fresh_state=ok
  before=$(cat "$ICONS")
  if (cd "$PLUGIN" && npm run --silent gen:icons >/dev/null 2>&1); then
    if [ "$before" != "$(cat "$ICONS")" ]; then
      fresh_state=stale
      printf '%s' "$before" > "$ICONS"
    fi
  fi
fi

# ── (4) 키 맵이 어휘와 맞물려 있는가 ────────────────────────────────────────
# `makeIcon` 은 이제 path data 를 그리지 않고 라이브러리 글리프를 swap 한다.
# 그 글리프에 닿으려면 published component key 가 필요하고, 키는 Figma 파일
# 안에만 존재해서 이 레포에서 생성할 수 없다 — `gen:icon-keys` 가 생성기가
# 아니라 검사기인 이유다(그 파일 헤더에 수확 방법이 적혀 있다).
#
# net-new 0. 이름이 어휘에 있는데 키가 없으면 그 아이콘을 그리는 컴포넌트가
# 런타임에 이름을 대며 실패하고, 반대로 남는 키는 프리루드에서 쓸데없는
# import 를 한 번 더 한다.
keys_state=skipped
if [ "$tools_ready" = 1 ]; then
  keys_state=ok
  if ! keys_out=$(cd "$PLUGIN" && npm run --silent gen:icon-keys 2>&1); then
    keys_state=drift
    echo "❌ icon-keys.json 이 ICON_NAMES 와 어긋난다:"
    echo "$keys_out" | sed 's/^/   /'
  fi
fi

if [ "$tools_ready" != 1 ]; then
  echo "ℹ️  npm / node_modules 없음 — (2) freshness · (4) icon-keys 동기 건너뜀."
fi

env G13_BUILDERS="$BUILDERS" G13_ICONS="$ICONS" G13_GEN="$GEN" \
  G13_BASELINE="$BASELINE" G13_MODE="$mode" G13_FRESH="$fresh_state" \
  G13_KEYS="$keys_state" python3 - <<'PY'
import json, os, re, sys, glob, collections

builders = os.environ['G13_BUILDERS']
mode = os.environ['G13_MODE']
fresh_state = os.environ['G13_FRESH']
keys_state = os.environ['G13_KEYS']
baseline_path = os.environ['G13_BASELINE']

icons = json.load(open(os.environ['G13_ICONS'], encoding='utf-8'))

# ── (1) every makeIcon name exists ──────────────────────────────────────────
# Two different scans, because the two questions they answer have different
# safe directions when the scan is incomplete.
#
#   `called`  — names passed to `makeIcon` as a literal, plus the values of the
#               `_kXxxIcon` dispatch maps. Used to find names that don't exist.
#               Deliberately strict: a false hit here would fail a build over a
#               string that never reaches an icon.
#
#   `present` — any single-quoted string anywhere in the builders that equals an
#               `icons.json` key. Used only to answer "is this icon dead". Names
#               reach `makeIcon` through wrappers (`treeRow(lk, 'file', …)`,
#               `navCell(lk, 'arrow-left', …)`, `triggerField(…, 'calendar', …)`)
#               and through array/object literals (`{ icon: 'house' }`), so the
#               strict scan called ten live icons unused on its first run — and
#               acting on that report would have deleted names the build needs.
#               Over-counting is the safe direction for this question.
#
# Names that reach `makeIcon` only through indirection cannot be validated
# statically at all. The registry-runtime harness is what covers them: it drives
# all 101 builders, so a bad name from any path throws there. This guard checks
# what a literal scan can see; the harness checks the rest.
used = collections.Counter()
where = collections.defaultdict(list)
present = set()
name_re = re.compile(r"makeIcon\(\s*'([a-z0-9-]+)'")
# Values of the `_kXxxIcon` dispatch maps — same identity, reached indirectly.
map_re = re.compile(r"^const _k\w*Icon\b[^=]*=\s*\{(.*?)\};", re.S | re.M)
val_re = re.compile(r":\s*'([a-z0-9-]+)'")
any_re = re.compile(r"'([a-z0-9-]+)'")

GLYPHS = set('✕⌕▾▴▸◂✓✗•⬚⋯▦☰⬆★☆♪♫♬◷⌂♥●○ℹ⚠')
glyph_sites = []

for f in sorted(glob.glob(f'{builders}/*.ts')):
    src = open(f, encoding='utf-8').read()
    short = f.split('/')[-1]
    for m in name_re.finditer(src):
        used[m.group(1)] += 1
        where[m.group(1)].append(short)
    for m in map_re.finditer(src):
        for v in val_re.finditer(m.group(1)):
            used[v.group(1)] += 1
            where[v.group(1)].append(short)
    for m in any_re.finditer(src):
        if m.group(1) in icons:
            present.add(m.group(1))
    # ── (3) text glyphs left in an icon slot ──
    for i, line in enumerate(src.split('\n'), 1):
        s = line.lstrip()
        if s.startswith('//') or s.startswith('*') or s.startswith('/*'):
            continue
        for ch in line:
            if ch in GLYPHS:
                glyph_sites.append(f'{short}:{i}  {s[:74]}')
                break

unknown = sorted(n for n in used if n not in icons)
unused = sorted(n for n in icons if n not in present)
n_glyph = len(glyph_sites)

if mode == '--report':
    print(f'makeIcon 이름 {len(used)}종 / {sum(used.values())}회 · icons.json {len(icons)}개')
    print(f'없는 이름 {len(unknown)} · 안 쓰는 아이콘 {len(unused)} · 남은 텍스트 글리프 {n_glyph}')
    if unknown:
        print('\n없는 이름:')
        for n in unknown:
            print(f'   {n:20} {", ".join(sorted(set(where[n])))}')
    if unused:
        print(f'\n안 쓰는 아이콘: {", ".join(unused)}')
    if glyph_sites:
        print('\n남은 텍스트 글리프:')
        for s in glyph_sites:
            print('  ', s)
    sys.exit(0)

if mode == '--update':
    with open(baseline_path, 'w', encoding='utf-8') as fh:
        fh.write(f'{n_glyph}\n')
    print(f'baseline 갱신: {n_glyph}')
    sys.exit(0)

fail = False

if fresh_state == 'stale':
    print('❌ icons.json 이 stale — ICON_NAMES 와 다르다.')
    print(f'   (cd tools/figma-token-sync && npm run gen:icons) 후 커밋해라.')
    print()
    fail = True

if unknown:
    print(f'❌ icons.json 에 없는 아이콘 이름 {len(unknown)}개를 빌더가 쓴다.')
    print()
    for n in unknown:
        print(f'   {n:20} {", ".join(sorted(set(where[n])))}')
    print()
    print('   makeIcon 이 throw 하고, 롤백되지 않는다 — 그 엔트리가 실패로')
    print('   보고되고 그리다 만 컴포넌트가 완성처럼 보이는 채 캔버스에 남는다.')
    print(f'   {os.environ["G13_GEN"]} 의 ICON_NAMES 에 추가하고 gen:icons 를 돌려라.')
    print()
    fail = True

# 안 쓰는 아이콘은 실패가 아니다 — 번들에 몇 KB 가 남을 뿐이고, 곧 쓸 이름을
# 미리 등록하는 것은 정당하다. 다만 조용히 쌓이면 "등록됐으니 쓰이는 중" 으로
# 읽히므로 세어서 보여준다.
if unused:
    print(f'ℹ️  등록됐지만 아직 안 쓰는 아이콘 {len(unused)}개: {", ".join(unused)}')

try:
    expected = int(open(baseline_path, encoding='utf-8').read().strip())
except (OSError, ValueError):
    print(f'❌ baseline 값을 못 읽음: {baseline_path}')
    sys.exit(1)

if n_glyph > expected:
    print(f'❌ 아이콘 자리의 텍스트 글리프가 늘었다: {n_glyph}건 (baseline {expected}).')
    print()
    for s in glyph_sites:
        print('  ', s)
    print()
    print('   문자 대신 makeIcon 을 써라 — 어느 Lucide 이름인지는 그 컴포넌트의')
    print('   위젯 소스가 이미 답한다(`LucideIcons.<name>`). 콘텐츠 텍스트라면')
    print('   그 자리가 아이콘 슬롯이 아니라는 뜻이므로 baseline 을 갱신해라.')
    sys.exit(1)

if fail:
    sys.exit(1)

if keys_state == 'drift':
    sys.exit(1)

# 검사한 것만 말한다 — skip 된 블록을 성공 줄이 통과로 바꿔 읽으면,
# 그 green 을 보고 넘어간 사람에게 거짓을 판 것이 된다.
fresh_note = '생성물 fresh' if fresh_state == 'ok' else '생성물 freshness 미검사'
keys_note = ('icon-keys.json 동기' if keys_state == 'ok'
             else 'icon-keys.json 동기 미검사')
print(
    f'✅ G13 아이콘 이름 {len(used)}종 전부 icons.json 에 존재 · '
    f'텍스트 글리프 {n_glyph}건 (baseline {expected} 이하) · {fresh_note} · '
    f'{keys_note}.'
)
PY
