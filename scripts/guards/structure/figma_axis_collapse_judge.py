#!/usr/bin/env python3
"""A-1 판정: 하드코딩된 dispatch 자리가 읽는 표의 행 수를 본다.

stdin 으로 `check_figma_axis_collapse.sh` 의 grep 히트를 받는다. 별도 파일인
이유는 셸의 heredoc 이 파이프 stdin 을 덮어쓰기 때문이다 — 처음 인라인으로 두었을
때 파이프가 사라져 히트 0건을 받고 "전부 안전" 을 출력했다. 판정 로직이 아무것도
보지 않으면서 green 을 내는 것이 이 레포가 반복해서 사는 실패라, 이 파일의 존재
자체가 그 실패의 자리다.
"""

import json
import os
import re
import sys

data = json.load(open(os.environ['A1_DATA']))['components']
allow_path = os.environ['A1_ALLOWLIST']
allow = {}
if os.path.exists(allow_path):
    allow = (json.load(open(allow_path)).get('sites') or {})

# `NAMESPACE.sizes.defaultsBySize.md` / `COMPONENTS.button.variants.defaultsByVariant['primary']`
pat = re.compile(
    r"(?P<ns>[A-Za-z_][A-Za-z0-9_.]*)\.(?P<bucket>sizes|variants)"
    r"\.(?P<table>defaultsBySize|defaultsByVariant)"
    r"(?:\[['\"](?P<k1>[^'\"]+)['\"]\]|\.(?P<k2>[a-z][A-Za-z0-9]*))"
)

# NAMESPACE → slug. `COMPONENTS.<slug>` is explicit; a file-local alias
# (`const BUTTON = COMPONENTS.button`) is resolved by snake-casing the name.
def slug_of(ns: str) -> str:
    tail = ns.split('.')
    if len(tail) >= 2 and tail[-2] == 'COMPONENTS':
        return tail[-1]
    name = tail[-1]
    if name.startswith('COMPONENTS.'):
        return name.split('.')[-1]
    # 파일 로컬 별칭은 이미 SCREAMING_SNAKE (`DESCRIPTION_CARD`) 이므로 소문자화만
    # 하면 slug 다. camelCase 를 가정해 언더스코어를 넣으면 글자마다 끼워
    # `d_e_s_c...` 가 되어 아무 컴포넌트에도 맞지 않는다 — 그 오류가 "해석 못함"
    # 으로 크게 드러난 것이, 조용히 통과하는 것보다 나은 실패다.
    return name.lower()

bad, ok, excused, noaxis = [], 0, 0, 0
unknown = []
for line in sys.stdin:
    line = line.rstrip('\n')
    loc = ':'.join(line.split(':')[:2])
    m = pat.search(line)
    if not m:
        unknown.append(loc)
        continue
    slug = slug_of(m.group('ns'))
    comp = data.get(slug)
    if comp is None:
        unknown.append(f'{loc} (slug {slug!r} not in components.json)')
        continue
    table = ((comp.get(m.group('bucket')) or {}).get(m.group('table')) or {})
    rows = len(table)
    # 키는 `<파일>:<slug>.<table>` — 줄 번호를 넣지 않는다. 처음엔 넣었고, 같은
    # 파일의 무관한 편집이 줄을 밀자 5 개 항목이 한꺼번에 매칭을 잃었다. allowlist
    # 항목이 편집으로 조용히 무효가 되면 그 게이트는 편집마다 거짓 red 를 내고,
    # 거짓 red 는 읽히지 않는다.
    site = f"{loc.split(':')[0]}:{slug}.{m.group('table')}"
    if rows <= 1:
        ok += 1
        continue
    if site in allow:
        excused += 1
        continue
    # Two data-checked exemptions, both meaning "there is no axis on the canvas for
    # these rows to become", so reading one is not collapsing anything.
    #
    # Checked here rather than written into the allowlist because the allowlist can
    # only hold an assertion — it admits one category, a parent reading a composed
    # CHILD's row, which nothing but prose can establish. These two are checkable,
    # so they are checked, and they stop being true by themselves if the data
    # changes.
    #
    # (1) NO ENUM anywhere. `axes` records every enum a component has, promoted as
    #     an axis or filed under `other`. When neither names one, the table's keys
    #     are not an axis in the making: `text_area.defaultsByVariant` is keyed by a
    #     bare `'false'`/`'true'`, and `tabs.defaultsBySize`'s six rows answer to no
    #     size enum the schema knows.
    #
    # There is no phantom exemption, and the attempt to add one is why this note
    # exists. `chip.defaultsByVariant` had four colour rows with one key hardcoded,
    # and the other three were listed as phantoms — so "the remaining rows are
    # deleted on sight, enumerating them would mint what another table removes" read
    # as a reason to excuse it. This gate had caught the collapse correctly and that
    # exemption switched it off.
    #
    # The premise was false. Every comparable component draws its unpromoted enum as
    # an axis — `Status` draws `CoreStatusColor` as `Variant`, and `Dock` / `Fab` /
    # `Progress` / `ValidationBadge` / `DescriptionCard` each draw their own. The
    # destination existed; Chip was the one component that had not built it, and the
    # phantoms were a record of that gap rather than a reason for it. A
    # `Chip(chipColor: CoreChipColor.primary)` that both platforms accept had nothing
    # on the canvas, and a user found it by looking.
    #
    # An enum sitting in `axes.other` is NOT an exemption on its own. That is a real
    # axis the schema under-promotes (the reader only lifts `size` when the getter
    # returns `CoreComponentSize`), and excusing it would excuse `progress`, whose
    # `CoreProgressSize` is exactly that — which is the site this guard's own
    # self-test injects into. The first version of this branch excused it and the
    # self-test went green on an injected regression: an exemption wide enough to
    # swallow the proof that the gate works.
    axes = comp.get('axes') or {}
    axis_key = 'variant' if m.group('table') == 'defaultsByVariant' else 'size'
    others = {o.get('enum') for o in (axes.get('other') or [])}
    suffixes = ('Size',) if axis_key == 'size' else ('Variant', 'Color')
    has_enum = bool(axes.get(axis_key)) or any(
        str(e).endswith(suffixes) for e in others
    )
    if not has_enum:
        noaxis += 1
        continue
    bad.append((loc, site, rows, m.group('k1') or m.group('k2')))

if unknown:
    print(f'❌ 이 가드가 해석하지 못한 자리 {len(unknown)}건 — 패턴이나 별칭 해소가 낡았다:')
    for u in unknown:
        print(f'   {u}')
    sys.exit(1)

if bad:
    print(f'❌ 캔버스에 없는 축 {len(bad)}건 — 표에 행이 여럿인데 키 하나를 글자로 박았다:')
    for loc, site, rows, key in bad:
        print(f"   {loc}  {site} 는 {rows}행인데 '{key}' 하나만 쓴다")
        print(f'      allowlist 키: {site}')
    print()
    print('   Object.entries(...) 로 순회하고 컴포넌트 이름에 그 축을 실어라 —')
    print('   Badge / ValidationBadge 참조. 이름이 바뀌면 src/renames.ts 에')
    print('   migration 을 같이 등록해야 한다(variant-safety self-test 가 검증).')
    print('   합성하는 자식의 행을 읽는 자리라면 allowlist 에 why 와 함께 적어라.')
    sys.exit(1)

print(
    f'✅ A-1 축 하드코딩 자리 {ok + excused + noaxis}건 전부 안전 — '
    f'행이 하나뿐 {ok}건 · 자식의 행 {excused}건 · 축 없음 {noaxis}건'
    f'(그 표의 키에 해당하는 enum 이 `axes` 에 아예 없다). baseline 없음.'
)
