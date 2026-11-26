#!/usr/bin/env python3
"""G16 — components.json 이 실어 보낸 값 중 아무 빌더도 읽지 않는 필드 ratchet.

왜 G7 로 부족한가
-----------------

G7(빌더 리터럴)은 스스로를 "이 프로젝트의 성공 판정" 이라 부르며 이 상태를
잡겠다고 선언한다 — "exporter 가 JSON 을 1,290 필드로 채워도 **빌더가 여전히
10개만 그 JSON 을 읽으면** 나머지는 하드코딩된 값을 그대로 그린다".

그런데 G7 이 세는 것은 **리터럴**이다. 빌더가 그 자리에 하드코딩된 값을 그릴 때만
보인다. 빌더가 그 자리에 **아무것도 안 그리면** 리터럴이 없으므로 G7 에는
아무것도 보이지 않는다 — Core 가 값을 정하고 exporter 가 실어 보냈는데 캔버스에
그 값이 존재하지 않는 상태가, 그 상태를 잡겠다는 게이트를 그대로 통과한다.

실측 176개가 그 상태였다(전체 fields 의 14%). `window` 24개, `text_area` 8개,
`phone_input` 7개 — `barrierColor`(Figma 에 모달 배리어가 없다), `closeAnimation
ScaleMax`(정적 캔버스에 애니메이션이 없다) 처럼 표현 자체가 불가능한 것도 있고,
`dropdownItemPadding`·`errorTextStyle` 처럼 그릴 수 있는데 안 그린 것도 있다. 둘을
구분하는 것이 이 수를 내리는 작업이고, 이 게이트는 그 수가 조용히 늘지 않게 한다.

판정 방법과 그 오차 방향
------------------------

필드 이름이 `tools/figma-token-sync/src/**/*.ts` 에 **식별자로 한 번도 나오지
않으면** 아무 빌더도 그 값을 읽을 수 없다. 이것은 반증 불가능한 방향의 판정이다.

더 엄격한 판정(`.field` 멤버 접근만 인정)은 332개를 보고하지만, 구조 분해나 계산된
키로 읽는 경우를 놓쳐 **읽고 있는 필드를 안 읽는다고 말할 수 있다**. 게이트가
늑대 소리를 내면 읽히지 않고, 읽히지 않는 게이트는 없는 게이트다. 그래서 하한을
쓴다 — 176 은 "최소 이만큼은 확실히 안 읽힌다" 이고, 실제 수는 더 크다.

이름이 짧고 흔한 필드(`color`, `size`, `half`, `fit` — 29개)는 무관한 곳에서
우연히 매칭돼 "읽힌다" 로 오판될 수 있다. 그 오판은 이 수를 **과소** 보고하는
방향이므로 게이트를 느슨하게 만들 뿐 거짓 red 를 내지 않는다.

ratchet 을 버리고 전수 열거로 — baseline 이 없다
-----------------------------------------------

이 게이트는 "176 이하" 로 시작했다. 그 모양이 틀렸다는 지적이 정확했다: baseline
은 *이미 있는 위반을 영구히 허용*한다는 선언이고, 그건 무결이 아니라 **허용된
부채**다. 176 이 23 이 되어도 23 은 여전히 "23 개는 캔버스에 도달하지 않아도
된다" 는 뜻이고, 게이트를 통과하는 길이 **숫자**로 남아 있는 한 아무도 그 23 개가
무엇인지 말하지 않아도 된다.

그래서 숫자를 없앴다. 조건은 하나다 — **미판독 필드는 전부 이름이 적혀 있어야
한다**. 통과하는 길이 숫자가 아니라 이름과 사유라서, 새 필드가 배선 없이 들어오면
그 필드의 이름을 적어야 하고, 이름을 적는 행위는 리뷰에 보인다(CODEOWNERS).
줄어드는 것은 세는 수가 아니라 그 파일의 길이다.

`figma_unread_fields_allowlist.json` 이 그 목록이고, 각 항목은 category 와 why 를
가진다. category 는 네 가지이고, 앞의 셋은 **결론**(배선할 것이 없다)이며 마지막
하나만 **남은 일**이다:

결론 — 배선할 것이 없다:
  motion               정적 캔버스에 자세가 없다. 값이 전환의 시작·길이·곡선을 말한다.
  gesture              진행 중인 포인터 제스처 동안에만 존재한다. 머무는
                       상태(hover)는 자세를 갖지만 끌고 있는 중은 머물지 않는다.
  no-op                값 자체가 "아무 일도 하지 않는다" 다.
  composition          자식 인스턴스가 이미 그린다(자식 default 에 reach 금지).
  unreachable-default  위젯의 기본 구성이 그 분기에 들어가지 않는다.

남은 일 — 캔버스보다 앞에 할 일이 있다:
  code-gap             양쪽 위젯 어디서도 소비되지 않는다. 위젯이 먼저 그려야 한다.
  needs-component      그 값을 읽는 위젯이 있는데 REGISTRY 항목이 없다.

둘을 섞어 하나의 수로 세면 그게 다시 baseline 이다 — 그래서 게이트는 분리해
출력하고, 남은 일 항목은 매번 이름과 함께 찍는다.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[3]
DATA = ROOT / 'tools/figma-token-sync/src/data/components.json'
SRC = ROOT / 'tools/figma-token-sync/src'
ALLOWLIST = pathlib.Path(__file__).with_name('figma_unread_fields_allowlist.json')
ROW_BASELINE = pathlib.Path(__file__).with_name(
    'figma_unread_row_keys_baseline.txt'
)

# 적을 수 있는 사유의 종류. 여기 없는 category 는 거부한다 — 자유 서술 필드로
# 두면 "TODO" 가 category 가 된다. 앞의 셋은 결론이고 needs-pose 만 남은 일이다.
CONCLUDED = {
    'gesture',
    'no-op',
    'composition',
    'unreachable-default',
    'platform-absent',
    'no-pixels',
    'motion-endpoint',
}
PENDING = {'needs-pose', 'needs-component', 'code-gap', 'needs-export'}
CATEGORIES = CONCLUDED | PENDING

# population floor — 패턴이나 경로가 깨져 0 에 가까워지면 "다 읽힌다" 로 조용히
# 오판된다. G7 이 같은 이유로 FLOOR 를 두고 있고, 같은 근거로 여기도 둔다.
FLOOR = 800
ROW_KEY_FLOOR = 150
_DIM_LEAVES = frozenset({'v', 'ref', 'via', 'choice'})


# 주석을 지운 소스. 이 가드가 세는 것은 "빌더가 그 값을 읽는가" 이고, 주석에 이름이
# 적혀 있는 것은 읽는 것이 아니다.
#
# 실제로 그 구멍으로 한 필드가 통과했다: ResizableTable 을 만들며 그 docstring 에
# `resizerDragColor` 를 (왜 그리지 않는지 설명하려고) 적었더니, 그 순간 그 필드가
# "읽힌다" 로 판정돼 allowlist 에서 지우라는 요구가 나왔다. 사유를 적는 행위가
# 사유를 무효화하는 모양이었다.
def sources() -> dict[str, str]:
    out: dict[str, str] = {}
    for path in sorted(SRC.rglob('*.ts')):
        text = path.read_text(encoding='utf-8')
        # Line comments first. A `/*` inside `// …` is not a block comment —
        # stripping blocks first ate real code after `// … icon-size/*` (#4475).
        # `(?<!:)` so a URL inside a template string (`http://www.w3.org/…`)
        # is not read as the start of a comment.
        text = re.sub(r'(?<!:)//[^\n]*', ' ', text)
        text = re.sub(r'/\*.*?\*/', ' ', text, flags=re.DOTALL)
        out[path.name] = text
    return out


# 읽힘 판정은 **그 컴포넌트의 접근 경로**로 한다 — 이름만으로는 안 된다.
#
# 처음엔 필드 이름을 빌더 소스 전체에서 찾았고, 그것이 이름을 공유하는 모든
# 컴포넌트를 한꺼번에 credit 했다. `focusOutlineStyle` 은 열 몇 컴포넌트가 가진
# 이름이라, 한 곳이 읽으면 나머지 전부가 "읽힌다" 로 판정됐다. 실측 187 필드가 그
# 상태였다 — 게이트가 0 이라고 말하는 동안.
#
# 그중 하나가 `button.focusOutlineStyle` 이었고, 그 필드는 ring 의 정렬·두께·색을
# 전부 진술하는데 Button 에는 Focus 축도 ring 노드도 없다. "값이 우연히 맞는" 것도
# 아니고 아무것도 그리지 않는데 게이트가 초록이었다.
#
# 경로는 두 형태다 — 직접 `BUTTON.fields.x` 와, 훨씬 흔한 파일 지역 별칭
# (`const f = BUTTON.fields;` 뒤의 `f.x`). 별칭은 파일 단위로만 유효하므로 파일을
# 합치지 않고 파일별로 본다: 합치면 A 파일의 `f` 가 B 파일의 `f.x` 를 credit 한다.
# 값 자체가 모션이라고 말하는 필드 — 손으로 적지 않고 데이터에서 판정한다.
#
# 판정: 값이 `Primitives/duration/*` 를 참조하거나 `via` 가 `CoreDuration` /
# `CoreEasing` 를 거치거나, 값이 `CoreEasing` 별칭 choice 다.
#
# 게이트는 이 수를 따로 출력한다 — 결론과 섞어 하나로 세면 그게 baseline 이다.
#
# `CoreEasing` 의 멤버 이름은 손으로 적지 않고 그 정의 파일에서 읽는다. 다섯 개
# (`standard`/`decelerate`/`accelerate`/`spring`/`linear`) 를 박아 두었더니 두
# 필드가 미판독으로 올라왔는데, 값이 `{choice: 'move'}` 였다 — 리더는 별칭을
# **종단 이름**으로 해소하고 `standard` 는 `move` 를 가리킨다(`easing_scale.dart`:
# `static const CoreCubicBezier standard = move;`). 그래서 시맨틱 별칭 다섯 개는
# 데이터에 거의 나타나지 않는다.
#
# 이름 목록을 손으로 드는 것이 이 레포에서 반복 실패하는 모양이다(합성 게이트의
# focus-ring 철자 목록이 같은 이유로 세 번 고쳐졌다). 곡선 이름이 무엇이든
# cubic-bezier 는 모션이므로, 판정은 "그 파일이 정의한 이름인가" 로 한다.
def _easing_names() -> set[str]:
    path = ROOT / 'packages/coui_core/lib/src/motion/easing_scale.dart'
    if not path.exists():
        # 경로가 바뀌면 조용히 통과시키지 않는다 — 빈 집합은 모든 curve 필드를
        # 미판독으로 올리므로 red 가 되고, red 는 읽힌다.
        return set()
    src = path.read_text(encoding='utf-8')
    return set(re.findall(r'static const CoreCubicBezier (\w+)\s*=', src))


MOTION_EASINGS = _easing_names()


def is_motion_value(value: object) -> bool:
    if not isinstance(value, dict):
        return False
    keys = set(value)
    if keys == {'choice'}:
        return str(value.get('choice')) in MOTION_EASINGS
    if not keys <= {'v', 'ref', 'via'}:
        return False
    ref = str(value.get('ref') or '')
    via = str(value.get('via') or '')
    return (
        'Primitives/duration' in ref
        or 'CoreDuration' in via
        or 'CoreEasing' in via
    )


def allowed() -> dict[str, dict[str, str]]:
    if not ALLOWLIST.exists():
        return {}
    doc = json.loads(ALLOWLIST.read_text(encoding='utf-8'))
    return doc.get('fields') or {}


BUCKETS = ('fields', 'constants', 'variants', 'sizes')


def screaming(slug: str) -> str:
    return slug.upper()


# 스코프는 파일이 아니라 **함수**다.
#
# 한 빌더 파일에는 `const f = BANNER.fields;` 와 `const f = CHIP.fields;` 가 나란히
# 있다 — 함수마다 하나씩, 전부 `f` 라는 이름으로. 별칭을 파일 단위로 모으면 `f.x` 가
# 그 파일의 모든 컴포넌트를 한꺼번에 credit 하고, 그건 이 게이트가 방금 고친
# "이름만으로 credit" 의 한 단계 아래 같은 결함이다.
#
# 함수 경계는 중괄호 깊이로 찾는다. 정규식으로 본문을 잡으려 하면 중첩 함수에서
# 끊긴다.
#
# `async` 는 있어도 된다. 비동기 빌더도 자기 스코프인데, 맨 `function` 만 보면 그
# 본문이 함수 밖(모듈 레벨)으로 새고 거기 적힌 `const f = KBD.fields;` 가 파일 전체의
# `f` 별칭이 된다 — 같은 파일의 다른 빌더가 `f.xxx` 로 읽는 값이 전부 엉뚱한
# 컴포넌트에 credit 되고, 정작 그 빌더의 필드는 "아무도 읽지 않는다" 로 나온다.
# (`figma_composition_parity.py` 가 같은 이유로 `async` 를 이미 받는다.)
def _function_bodies(text: str) -> list[str]:
    out: list[str] = []
    for m in re.finditer(r'^(?:export )?(?:async )?function\s+\w+', text, re.M):
        i = text.find('{', m.end())
        if i < 0:
            continue
        depth = 0
        for j in range(i, len(text)):
            if text[j] == '{':
                depth += 1
            elif text[j] == '}':
                depth -= 1
                if depth == 0:
                    out.append(text[i : j + 1])
                    break
    return out


# 함수 밖(모듈 레벨)의 접근도 읽힘이다 — `const kX = BUTTON.fields.y;` 같은 상수.
# 함수 본문을 다 빼고 남은 것이 그 표면이다.
def _module_level(text: str) -> str:
    rest = text
    for body in _function_bodies(text):
        rest = rest.replace(body, ' ', 1)
    return rest


_ALIAS_RE = re.compile(
    r'const (\w+)\s*=\s*([A-Z][A-Z0-9_]*)\.(?:' + '|'.join(BUCKETS) + r')\b'
)

# A dispatch ROW alias — `const [name, variant] of Object.entries(X.variants.…)`,
# `const sz = X.sizes.defaultsBySize[zn]`, `const v = variants[i][1]`.
#
# A flat field and its per-row twin are the same design decision stated twice, and
# the resolver reads the ROW: `CoreEmptyStateStyle.defaultIconTitleGapStyle` is 16
# and the `normal` row is 16 while `compact` is 12, so a builder that read the flat
# field would paint 16 on both and disagree with each platform. Six flat fields were
# in that state — read through the row, unread through themselves — and requiring
# the flat path would have asked builders to switch to the wrong source to make a
# counter go down.
#
# The row's own bucket is what ties the credit to this component: the alias has to
# come from `<OWNER>.variants…` / `<OWNER>.sizes…`, not from any table.
#
# Two hops, because that is how the builders spell it — the table is bound first
# (`const sizes = Object.entries(CHIP.sizes.defaultsBySize);`) and destructured
# after (`for (const [zn, sz] of sizes)`). A one-hop pattern matched neither line.
_TABLE_RE = re.compile(
    r'(?:const|let)\s+(\w+)\s*=[^;\n]*?([A-Z][A-Z0-9_]*)\.(?:variants|sizes)\b'
)
_DESTRUCTURE_RE = re.compile(
    r'for\s*\(\s*(?:const|let)\s*\[[^\]]*?,\s*(\w+)\s*\]\s*of\s+(\w+)'
)
# `const sz = SIZES[zn]` / `const row = table[key]` — the indexed form.
_INDEXED_RE = re.compile(r'(?:const|let)\s+(\w+)\s*=\s*(\w+)\s*\[')
# `const variant = variantData.get(combo['Variant'])` — the row pulled out of a
# `Map`. The dispatch tables are wrapped in one (`new Map(Object.entries(X.variants
# .defaultsByVariant))`) and the row comes back through `.get`, so neither the
# destructured nor the indexed hop reaches it.
#
# Nine fields were reported unread on this alone — `Menubar`'s bar colours,
# `EmptyState`'s three gaps, `Toggle`'s padding and gap, `Button`'s gap,
# `Checkbox`'s gap — each of them read on the line the report pointed at. A false
# unread costs more than a missed one here: the answer it asks for is a written
# exemption, so it invites a paragraph explaining why a field that IS wired is not.
_MAP_GET_RE = re.compile(r'(?:const|let)\s+(\w+)\s*=\s*(\w+)\s*\.get\(')
# `const s = sizeRowFor(sizeData, combo['Size'], …)` — the same row, picked by the
# builders' copy of `resolveSizeRow` so a size the table does not state draws the
# row the app falls back to. The table is the first argument; the call is a `.get`
# with the fallback attached, and reading it as anything less would report every
# key of the Button / TextField / TextArea / Badge rows unread.
_ROW_CALL_RE = re.compile(r'(?:const|let)\s+(\w+)\s*=\s*sizeRowFor\(\s*(\w+)')


def _aliases(text: str) -> dict[str, str]:
    out = {m.group(1): m.group(2) for m in _ALIAS_RE.finditer(text)}
    # Hop 1 — the table variable and the component it came from.
    tables = {m.group(1): m.group(2) for m in _TABLE_RE.finditer(text)}
    # Hop 2 — the row name destructured out of it, or indexed from it.
    for pattern in (_DESTRUCTURE_RE, _INDEXED_RE, _MAP_GET_RE, _ROW_CALL_RE):
        for m in pattern.finditer(text):
            owner = tables.get(m.group(2))
            if owner:
                out.setdefault(m.group(1), owner)
    return out


def scopes(src: dict[str, str]) -> list[tuple[str, dict[str, str]]]:
    """(스코프 텍스트, 그 안의 별칭 → 컴포넌트) 목록."""
    out: list[tuple[str, dict[str, str]]] = []
    for text in src.values():
        for body in _function_bodies(text):
            out.append((body, _aliases(body)))
        module = _module_level(text)
        out.append((module, _aliases(module)))
    return out


def reads_field(scoped, slug: str, field: str, files=None) -> bool:
    owner = screaming(slug)
    direct = re.compile(
        r'\b' + re.escape(owner) + r'\.(?:' + '|'.join(BUCKETS) + r')\.'
        + re.escape(field) + r'\b'
    )
    member = re.compile(r'\.' + re.escape(field) + r'\b')
    # A COMPUTED read — `STAT.fields[trend.color]`, where the key comes from a
    # table whose members are string literals. `Stat` draws all three trend colours
    # that way (its `ChangeType` axis IS those three) and a path-only matcher read
    # every one of them as unread.
    #
    # Checked per FILE rather than per scope, unlike everything else here, because
    # the two halves live in different scopes by construction: the literal table is
    # module-level (`_kStatChanges`) and the indexing sits inside the builder
    # function. A key table and its consumer are in one file — that is what makes
    # the wider scope safe here and nowhere else.
    #
    # Both halves are still required: the owner's bucket must be indexed AND this
    # field's name must appear as a literal, so the credit stays tied to the field
    # rather than covering the whole bucket.
    computed = re.compile(
        r'\b' + re.escape(owner) + r'\.(?:' + '|'.join(BUCKETS) + r')\['
    )
    quoted = re.compile(r"['\"]" + re.escape(field) + r"['\"]")
    for text in (files or {}).values():
        if computed.search(text) and quoted.search(text):
            return True
    for text, aliases in scoped:
        if direct.search(text):
            return True
        for alias, comp in aliases.items():
            if comp != owner:
                continue
            if re.search(r'\b' + re.escape(alias) + member.pattern, text):
                return True
    return False


def unread() -> tuple[int, dict[str, list[str]], list[str], list[str]]:
    doc = json.loads(DATA.read_text(encoding='utf-8'))
    src = sources()
    allow = allowed()
    out: dict[str, list[str]] = {}
    excused: list[str] = []
    motion: list[str] = []
    total = 0
    scoped = scopes(src)
    for slug, comp in sorted(doc['components'].items()):
        fields = comp.get('fields') or {}
        for field in sorted(fields):
            total += 1
            if reads_field(scoped, slug, field, src):
                continue
            if is_motion_value(fields[field]):
                motion.append(f'{slug}.{field}')
                continue
            if f'{slug}.{field}' in allow:
                excused.append(f'{slug}.{field}')
                continue
            out.setdefault(slug, []).append(field)
    return total, out, excused, motion


def _row_dicts(comp: dict) -> list[dict]:
    out: list[dict] = []
    for row in (comp.get('variants') or {}).get('defaultsByVariant', {}).values():
        if isinstance(row, dict):
            out.append(row)
    for row in (comp.get('sizes') or {}).get('defaultsBySize', {}).values():
        if isinstance(row, dict):
            out.append(row)
    return out


def unread_rows() -> tuple[int, list[str]]:
    """Row-table keys not already in `fields` (#4566).

    `hoverTextDecoration` lives on Button variant rows, not `fields`, so the
    fields walk never saw it. Union keys by name per component: read on any
    row counts as read. Motion-valued keys are skipped the same way as fields.
    """
    doc = json.loads(DATA.read_text(encoding='utf-8'))
    src = sources()
    scoped = scopes(src)
    unread: list[str] = []
    total = 0
    for slug, comp in sorted(doc['components'].items()):
        fields = set(comp.get('fields') or {})
        collected: dict[str, list] = {}
        for row in _row_dicts(comp):
            if set(row) <= _DIM_LEAVES:
                continue
            for key, value in row.items():
                if key in _DIM_LEAVES or key in fields:
                    continue
                collected.setdefault(key, []).append(value)
        for field, values in sorted(collected.items()):
            total += 1
            if values and all(is_motion_value(v) for v in values):
                continue
            if reads_field(scoped, slug, field, src):
                continue
            unread.append(f'{slug}.{field}')
    return total, unread


def _read_row_baseline() -> list[str]:
    if not ROW_BASELINE.exists():
        return []
    return [
        line
        for line in ROW_BASELINE.read_text(encoding='utf-8').splitlines()
        if line and not line.startswith('#')
    ]


def _write_row_baseline(keys: list[str]) -> None:
    ROW_BASELINE.write_text('\n'.join(keys) + ('\n' if keys else ''), encoding='utf-8')


# allowlist 자신의 규율: 모든 항목에 알려진 category 와 비어 있지 않은 why 가
# 있어야 하고, 실제로 unread 인 필드만 적혀 있어야 한다. 마지막 조건이 없으면
# 배선을 끝낸 항목이 남아 수를 영구히 부풀린다.
def allowlist_faults(excused: list[str]) -> list[str]:
    faults: list[str] = []
    allow = allowed()
    for key, entry in sorted(allow.items()):
        cat = (entry or {}).get('category')
        why = ((entry or {}).get('why') or '').strip()
        if cat not in CATEGORIES:
            faults.append(f'{key}: category {cat!r} 은 {sorted(CATEGORIES)} 중에 없다')
        if len(why) < 20:
            faults.append(f'{key}: why 가 비었거나 너무 짧다 — 왜 배선할 수 없는지 적어라')
        if key not in excused:
            faults.append(f'{key}: 이미 읽히거나 존재하지 않는 필드다 — allowlist 에서 지워라')
    return faults


def main(argv: list[str]) -> int:
    mode = argv[1] if len(argv) > 1 else 'check'
    total, groups, excused, motion = unread()
    row_total, row_unread = unread_rows()
    count = sum(len(v) for v in groups.values())
    faults = allowlist_faults(excused)

    if mode == 'update':
        _write_row_baseline(row_unread)
        print(f'Wrote row-key baseline ({len(row_unread)}) → {ROW_BASELINE.name}')
        return 0

    if total < FLOOR:
        print(f'❌ fields 총계가 {total} 로 FLOOR({FLOOR}) 미만 — 데이터/경로가 깨졌다.')
        print('   무엇을: components.json 경로와 스키마(`components.*.fields`) 확인.')
        return 1

    if row_total < ROW_KEY_FLOOR:
        print(
            f'❌ row keys 총계가 {row_total} 로 FLOOR({ROW_KEY_FLOOR}) 미만 — '
            'variants/sizes 추출이 깨졌다.'
        )
        return 1

    row_baseline = _read_row_baseline()
    row_new = [k for k in row_unread if k not in row_baseline]
    if row_new:
        print(f'❌ 행 키 미판독 net-new {len(row_new)}개 (#4566):')
        for key in row_new:
            print(f'   {key}')
        print('   빌더가 그 키를 읽게 하라. 지금은 못 읽는 부채면')
        print(f'   python3 {pathlib.Path(__file__).name} --update 로 baseline 에 올려라.')
        return 1

    if mode == 'report':
        print(f'components.json fields 총 {total} · 아무 빌더도 읽지 않음 {count} · '
              f'사유 기록됨 {len(excused)} · 값이 모션 {len(motion)}\n')
        for slug, fields in sorted(groups.items(), key=lambda kv: -len(kv[1])):
            print(f'── {slug}  ({len(fields)})')
            for f in fields:
                print(f'   {f}')
        allow = allowed()
        by_cat: dict[str, list[str]] = {}
        for key in excused:
            by_cat.setdefault(allow[key].get('category', '?'), []).append(key)
        for cat, keys in sorted(by_cat.items()):
            print(f'\n── 사유: {cat}  ({len(keys)})')
            for key in sorted(keys):
                print(f'   {key} — {allow[key].get("why", "")}')
        print()

    if faults:
        print(f'❌ allowlist 자체가 규율을 깼다 ({len(faults)}건):')
        for f in faults:
            print(f'   {f}')
        print(f'   파일: {ALLOWLIST}')
        return 1

    if count > 0:
        print(f'❌ 이름이 적히지 않은 미판독 필드 {count}개.')
        print('   왜: Core 가 값을 정하고 exporter 가 실어 보냈는데 캔버스에 그 값이')
        print('       없다. G7 은 이 상태를 볼 수 없다 — 세는 것이 리터럴이라,')
        print('       빌더가 그 자리에 아무것도 안 그리면 리터럴도 없다.')
        print('   무엇을: 빌더가 그 필드를 읽게 하라. 읽을 것이 없다면 그 이유를')
        print(f'       {ALLOWLIST.name} 에 category 와 why 로 적어라 — 이 게이트에')
        print('       숫자는 없고, 통과하는 길은 이름과 사유뿐이다.')
        for slug, fields in sorted(groups.items(), key=lambda kv: -len(kv[1])):
            print(f'   ── {slug}: {", ".join(fields)}')
        return 1

    allow = allowed()
    pending = sorted(k for k in excused if allow[k].get('category') in PENDING)
    concluded = len(excused) - len(pending)
    row_gone = [k for k in row_baseline if k not in row_unread]
    print(
        f'✅ G16 fields {total} — 미판독 전수 열거됨 '
        f'(값이 모션 {len(motion)}개 · 사유 기록 {concluded}개 · '
        f'남은 일 {len(pending)}개). baseline 없음.'
    )
    print(
        f'✅ G16 row keys {row_total} — 미판독 {len(row_unread)} '
        f'(baseline {len(row_baseline)}, no net-new).'
    )
    if row_gone:
        print(
            f'   ℹ {len(row_gone)} baseline 행 키가 이제 읽힌다 — '
            f'--update 로 baseline 을 줄여라.'
        )
    # 남은 일은 매번 이름과 함께 찍는다. 하나의 수로 접으면 그게 다시 baseline 이다.
    for key in pending:
        print(f'   ○ {key} — {allow[key].get("why", "")}')
    return 0


if __name__ == '__main__':
    argv = [a.lstrip('-') if a.startswith('--') else a for a in sys.argv]
    sys.exit(main(argv))
