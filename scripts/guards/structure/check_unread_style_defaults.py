#!/usr/bin/env python3
"""Counts `default*` constants on Style classes that no code reads.

`core/layer-mapping.md` names six seats a chrome value passes through, and
two of them are the pair this looks at:

  (2) Core default   `CoreXxxStyle.defaultFieldName`
  (3)(5) resolver    `merged.fieldName ?? CoreXxxStyle.defaultFieldName`

`figma_orphan_fields.py` already counts one direction of that pair — a field
with no default. This counts the other: a default nobody reads.

WHY THIS DIRECTION NEEDS ITS OWN GATE

The two failures look nothing alike from the authoring side. A field with no
default has nothing to emit, so the Figma exporter reports it and the value's
absence is visible. A default with no reader is the opposite — it is a
complete, well-formed, documented constant. It has a type, a token reference
and a doc comment describing the render it produces. Everything about it says
"this is what the component paints" except the one thing nobody checks, which
is whether any code paints it.

That is the failure `core/theme-axis-composition.md` describes: not "the value
is a little wrong" but "the value looks decided and is not" — and the harm is
that the next person builds on it. Four of the entries this finds carry doc
comments stating a specific visual effect ("applied as a multiplier on…",
"so the secondary line reads slightly muted") that no platform performs.

WHAT COUNTS AS READ

Production source only — `coui_core`, `coui_flutter`, `coui_web`, `docs_core`.
Tests are excluded on purpose: a constant read only by a test that asserts its
value is still a constant nobody renders, and counting the test would let a
value pin itself alive.

A default is read when either

  · some file names it qualified — `CoreXxxStyle.defaultThing`, or
  · its own declaring file names it bare, off the declaration line — the
    common case where one default is an argument to another
    (`CoreColor.token(…, opacity: defaultRowSelectedOpacity)`).

Qualified-or-own-file rather than bare-anywhere, because two components can
declare the same name (`defaultFocusRingWidth` lives on more than one Style)
and a bare count would let one component's reader vouch for the other's
orphan.

TWO BUCKETS, BECAUSE THE FIX DIFFERS

`components.json` decides which. The exporter walks instance fields, so a
default whose field exists still reaches the Figma canvas even when no
resolver consults it; a default with no field reaches nothing at all.

  exported   The canvas may draw it while both platforms ignore it — so the
             canvas and the app disagree and neither side reports it. G16
             (`check_figma_unread_fields.py`) sees the canvas half of this
             and its allowlist already documents three text_field entries
             with the same root cause, ending "the resolver has to consult
             the default first". This is that sentence, counted.

  inert      No field, no reader, no export. Nothing anywhere is downstream
             of the value.

HOW TO FIX ONE

Read it (wire the resolver's `merged.X ?? CoreXxxStyle.defaultX`), or remove
it. Removal of an exported symbol goes through `process/deprecation.md` — the
entry stays listed until the removal lands, because a deprecated constant is
still a declared constant.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parents[3]
CONTRACTS = REPO / 'packages/coui_core/lib/src/component/contracts'
COMPONENTS_JSON = REPO / 'tools/figma-token-sync/src/data/components.json'
BASELINE = (
    REPO / 'scripts/guards/structure/unread_style_defaults_baseline.txt'
)

SOURCE_ROOTS = [
    'packages/coui_core/lib',
    'packages/coui_flutter/lib',
    'packages/coui_web/lib',
    'docs_core/lib',
]

DECL = re.compile(
    r'static\s+(?:const|final)\s+[\w<>,\s?]+?\s+(default[A-Z]\w*)\s*=',
)
OWNER = re.compile(r'^(?:abstract\s+)?(?:final\s+)?class\s+(Core\w*Style)\b')


def declarations() -> dict[str, tuple[str, str, pathlib.Path]]:
    """`component.defaultName` → (owner class, default name, file)."""
    found: dict[str, tuple[str, str, pathlib.Path]] = {}
    for path in sorted(CONTRACTS.rglob('*_style.dart')):
        component = path.parent.name
        owner = ''
        for line in path.read_text(encoding='utf-8').split('\n'):
            match = OWNER.match(line.strip())
            if match:
                owner = match.group(1)
            decl = DECL.search(line)
            if decl and owner:
                name = decl.group(1)
                found[f'{component}.{name}'] = (owner, name, path)
    return found


def read_names(decls: dict[str, tuple[str, str, pathlib.Path]]) -> set[str]:
    """The `component.defaultName` keys some production file actually reads."""
    qualified: set[str] = set()
    own_file: set[str] = set()

    wanted_qualified = {
        f'{owner}.{name}' for owner, name, _ in decls.values()
    }
    by_qualified: dict[str, set[str]] = {}
    for key, (owner, name, _) in decls.items():
        by_qualified.setdefault(f'{owner}.{name}', set()).add(key)

    word = re.compile(r'\b(Core\w*Style)\.(default[A-Z]\w*)\b')
    # The formatter folds a long chain as `CoreXxxStyle\n    .defaultX\n    .merge(`,
    # which puts the owner and the name on different lines — a read the
    # per-line match cannot see. Stitch `Owner` and `.defaultX` back
    # together first. Stitching can pull a declaration's right-hand side
    # onto its declaration line, so a declaration line is scanned past its
    # `=` rather than skipped: a default built from another default is that
    # other default's reader.
    folded = re.compile(r'(Style)\n\s*\.(default[A-Z])')
    for root in SOURCE_ROOTS:
        for path in (REPO / root).rglob('*.dart'):
            if not path.is_file():
                continue
            text = folded.sub(r'\1.\2', path.read_text(encoding='utf-8'))
            for line in text.split('\n'):
                decl = DECL.search(line)
                scan = line[decl.end():] if decl else line
                for match in word.finditer(scan):
                    hit = f'{match.group(1)}.{match.group(2)}'
                    if hit in wanted_qualified:
                        qualified.update(by_qualified[hit])

    for key, (_, name, path) in decls.items():
        bare = re.compile(r'\b' + name + r'\b')
        for line in path.read_text(encoding='utf-8').split('\n'):
            if DECL.search(line):
                continue
            if bare.search(line) and not line.lstrip().startswith('///'):
                own_file.add(key)
                break

    return qualified | own_file


def exported_fields() -> dict[str, set[str]]:
    """Per component, the field names `components.json` carries."""
    try:
        data = json.loads(COMPONENTS_JSON.read_text(encoding='utf-8'))
    except OSError:
        return {}
    return {
        name: set(entry.get('fields', {}))
        for name, entry in data.get('components', {}).items()
    }


def field_of(default_name: str) -> str:
    """`defaultThingColor` → `thingColor`."""
    rest = default_name[len('default'):]
    return rest[0].lower() + rest[1:] if rest else rest


def unread() -> tuple[dict[str, str], dict[str, tuple[str, str, pathlib.Path]]]:
    decls = declarations()
    read = read_names(decls)
    exported = exported_fields()

    buckets: dict[str, str] = {}
    for key, (_, name, _path) in sorted(decls.items()):
        if key in read:
            continue
        component = key.split('.', 1)[0]
        is_exported = field_of(name) in exported.get(component, set())
        buckets[key] = 'exported' if is_exported else 'inert'
    return buckets, decls


def load_baseline() -> set[str]:
    try:
        lines = BASELINE.read_text(encoding='utf-8').split('\n')
    except OSError:
        return set()
    return {
        line.strip()
        for line in lines
        if line.strip() and not line.startswith('#')
    }


def write_baseline(buckets: dict[str, str]) -> None:
    header = [
        '# `default*` constants on a CoreXxxStyle that no production code',
        '# reads. Net-new entries fail CI; this list may only shrink.',
        '#',
        '# exported — components.json carries the field, so the Figma canvas',
        '#            may draw a value neither platform renders. Fixing it is',
        '#            a resolver change (consult the default), not a builder',
        '#            edit.',
        '# inert    — no instance field, no reader, no export. Nothing is',
        '#            downstream of the value at all.',
        '#',
        '# To clear one: wire it (`merged.X ?? CoreXxxStyle.defaultX`) or',
        '# remove it. Removal of an exported symbol follows',
        '# process/deprecation.md, and the entry stays here until the removal',
        '# lands — a deprecated constant is still a declared one.',
        '',
    ]
    body: list[str] = []
    for kind in ('exported', 'inert'):
        names = sorted(k for k, v in buckets.items() if v == kind)
        if not names:
            continue
        body.append(f'# ── {kind} ({len(names)})')
        body.extend(names)
        body.append('')
    BASELINE.write_text('\n'.join(header + body), encoding='utf-8')


def main() -> int:
    buckets, decls = unread()

    if '--report' in sys.argv:
        print(f'default* 선언 {len(decls)} · 미판독 {len(buckets)}')
        for kind in ('exported', 'inert'):
            names = sorted(k for k, v in buckets.items() if v == kind)
            print(f'\n── {kind} ({len(names)})')
            for name in names:
                print(f'   {name}')
        return 0

    if '--update' in sys.argv:
        write_baseline(buckets)
        print(f'baseline 갱신: 미판독 {len(buckets)}')
        return 0

    baseline = load_baseline()
    current = set(buckets)
    added = sorted(current - baseline)
    removed = sorted(baseline - current)

    if added:
        print(f'❌ 아무도 읽지 않는 default* 가 {len(added)}개 새로 생겼다.')
        print('   왜: 이 상수는 저작 쪽에서 완성으로 보인다 — 타입도 토큰도')
        print('       doc 주석도 갖췄고, 그 주석은 자기가 만드는 렌더를')
        print('       설명한다. 빠진 것은 그 값을 읽는 코드 하나뿐이라,')
        print('       다음 사람이 이 값을 근거로 설계를 얹는다.')
        print('   무엇을: resolver 가 `merged.X ?? CoreXxxStyle.defaultX` 로')
        print('       읽게 하거나, 지워라(공개 심볼이면 deprecation.md).')
        print('       읽을 것이 없다는 판단이면 baseline 에 등록하되, 그')
        print('       등록은 CODEOWNERS 리뷰를 거친다.')
        for name in added:
            print(f'   ── {name} ({buckets[name]})')
        return 1

    if removed:
        print(f'❌ baseline 에 있는데 지금은 없는 항목 {len(removed)}개.')
        print('   고쳤다면 `--update` 로 baseline 을 줄여 커밋하라.')
        for name in removed:
            print(f'   ── {name}')
        return 1

    exported = sum(1 for v in buckets.values() if v == 'exported')
    inert = len(buckets) - exported
    print(
        f'✅ 미판독 default* {len(buckets)} '
        f'(exported {exported} · inert {inert}) — net-new 없음.',
    )
    return 0


if __name__ == '__main__':
    sys.exit(main())
