"""Counts composition slots a designer cannot put anything into.

A CoUI contract slot typed `W` / `W?` accepts ANY widget — `Chip(leading: …)`
takes an icon, an avatar, or a whole custom row, and the widget just wraps
whatever arrives in an `IconTheme` and lays it out. The Figma equivalent of
"any widget goes here" is an INSTANCE_SWAP component property: the designer
picks a component from the panel and it takes that slot.

Without one, the builder's demo content IS the component. Whatever glyph the
builder happened to draw becomes the only thing that slot can ever hold, and a
designer reads it as the component's icon rather than as a placeholder. That is
a stronger claim than the contract makes, and it is the one direction where
being wrong is invisible: the canvas looks finished.

WHAT COUNTS

Every non-repeated slot (`W`, `W?`) needs a property a designer can act on.
`List<W>` is excluded — Figma has no repeated-slot property, and a designer adds
or removes children directly.

INSTANCE_SWAP is the full answer: any component goes in, which is what `W?`
means. A TEXT property is the partial one — the words are editable, the widget
is not.

The ratchet counts only slots with NEITHER. Text-rendering slots keep their TEXT
property and are reported separately, because swapping them would need a `Text`
component in the REGISTRY and the owner decided against adding one: Figma's
native typography mechanism is the shared Text Style, and wrapping every label
in an instance to gain a swap the design system does not need trades a real cost
for a theoretical one. Counting those 21 as defects would have this guard demand
a decision that was already made against — the same way its first draft counted
`makeIcon`-satisfied children as absent and inflated 172 to 247.

Matching is by name with case and separators folded away: the contract's
`leading` and the panel's `Leading` are the same slot, and so are
`primaryAction` and the panel's `Primary action` (two-word Figma props are
spaced, like `Show leading`). A property whose name matches no slot is not
counted as covering one — it may be a real affordance, but it is not this
slot's.

WHAT IT CANNOT SEE

A checked `exposeSlot` declaration also counts: it verifies the named child
property and its type at build time, then exposes that bound instance. The
registry runtime harness checks the exposed native swap property.

Whether the default the property points at is a sensible placeholder, and
whether the node the property is bound to is the one that actually renders the
slot. A property bound to the wrong node shows in the panel and changes nothing
— `check_figma_composition_parity`'s sibling problem, and the reason the audit
step for these builders checks binding, not declaration.

Usage: python3 scripts/guards/structure/figma_slot_swappability.py [--report|--update]
"""

import collections
import glob
import json
import re
import subprocess
import sys

PLUGIN = 'tools/figma-token-sync/src/components'
COMPONENTS = 'tools/figma-token-sync/src/data/components.json'
NAMES_SCRIPT = 'scripts/guards/structure/figma_registry_names.py'
BASELINE = 'scripts/guards/structure/figma_slot_swap_baseline.txt'


def registry_names() -> set[str]:
    out = subprocess.run(
        ['python3', NAMES_SCRIPT], capture_output=True, text=True, check=True
    ).stdout
    return set(out.split())


def slug_of(name: str) -> str:
    return re.sub(r'(?<!^)(?=[A-Z])', '_', name).lower()


def prop_key(name: str) -> str:
    """Fold a slot or Figma property name to its comparable core.

    Figma property names are designer-facing and spell two-word names with
    a space (`Primary action`, `Show leading`), while the Core slot is
    camel-cased (`primaryAction`). Case and separators carry no meaning on
    either side, so both fold to bare lower-case alphanumerics before the
    comparison — otherwise a swap declared under the canvas spelling reads
    as undeclared.
    """
    return re.sub(r'[^a-z0-9]', '', name.lower())


def declared_props(kind: str) -> dict[str, set[str]]:
    """Property names of one kind each builder declares, folded by [prop_key]."""
    out: dict[str, set[str]] = collections.defaultdict(set)
    for path in sorted(glob.glob(f'{PLUGIN}/*.ts')):
        src = open(path, encoding='utf-8').read()
        # `async` is optional: an async builder is still a builder, and matching
        # only the bare keyword silently dropped `async function buildButton`
        # from the scan — its three swap props read as undeclared.
        starts = [(m.group(1), m.start(), m.end()) for m in re.finditer(r'\n(?:async )?function (\w+)\s*\(', src)]
        bodies: dict[str, str] = {}
        for i, (fn, _s, e) in enumerate(starts):
            stop = starts[i + 1][1] if i + 1 < len(starts) else len(src)
            bodies[fn] = src[e:stop]
        direct = {
            fn: {
                prop_key(m.group(1))
                for m in re.finditer(
                    r"(?:defineProp|exposeSlot)\([^,]+,\s*'([^']+)'\s*,\s*'" + kind + r"'", body
                )
            }
            for fn, body in bodies.items()
        }
        # Same transitive fold the composition guard needs: a builder often
        # declares a row's swap inside a file-local helper.
        changed = True
        while changed:
            changed = False
            for fn, body in bodies.items():
                for other, props in direct.items():
                    if other == fn or not props:
                        continue
                    if re.search(r'\b' + re.escape(other) + r'\s*\(', body) and not props <= direct[fn]:
                        direct[fn] |= props
                        changed = True
        for fn, props in direct.items():
            if fn.startswith('build'):
                out[fn[len('build'):]] |= props
    return out


def main() -> int:
    names = registry_names()
    doc = json.load(open(COMPONENTS, encoding='utf-8'))['components']
    swaps = declared_props('INSTANCE_SWAP')
    texts = declared_props('TEXT')

    missing: dict[str, list[str]] = {}
    text_only: dict[str, list[str]] = {}
    total_slots = 0
    for name in sorted(names):
        comp = doc.get(slug_of(name))
        if not comp:
            continue
        swappable = swaps.get(name, set())
        editable = texts.get(name, set())
        gap = []
        partial = []
        for slot, meta in sorted(comp['slots'].items()):
            if meta.get('repeated'):
                continue
            total_slots += 1
            key = prop_key(slot)
            if key in swappable:
                continue
            if key in editable:
                partial.append(slot)
            else:
                gap.append(slot)
        if gap:
            missing[name] = gap
        if partial:
            text_only[name] = partial
    total = sum(len(v) for v in missing.values())
    partial_total = sum(len(v) for v in text_only.values())

    if '--report' in sys.argv:
        print(
            f'단일 합성 슬롯 {total_slots} · property 없음 {total} '
            f'(영향 {len(missing)}) · TEXT 만 {partial_total}\n'
        )
        for name, slots in sorted(missing.items(), key=lambda kv: -len(kv[1])):
            print(f'  {name:22} {", ".join(slots)}')
        print('\nTEXT property 만 있는 슬롯 (Text 컴포넌트 미도입 결정에 따른 상한):')
        for name, slots in sorted(text_only.items()):
            print(f'  {name:22} {", ".join(slots)}')
        return 0

    if '--update' in sys.argv:
        open(BASELINE, 'w', encoding='utf-8').write(f'{total}\n')
        print(f'baseline 갱신: {total}')
        return 0

    try:
        expected = int(
            next(
                l for l in open(BASELINE, encoding='utf-8')
                if l.strip() and not l.startswith('#')
            ).strip()
        )
    except (OSError, StopIteration, ValueError):
        print(f'❌ baseline 값을 못 읽음: {BASELINE}')
        return 1

    if total > expected:
        print(f'❌ property 가 하나도 없는 슬롯이 늘었다: {total} (baseline {expected}).')
        print()
        for name, slots in sorted(missing.items(), key=lambda kv: -len(kv[1]))[:12]:
            print(f'   {name:22} {", ".join(slots)}')
        print()
        print('   `W`/`W?` 슬롯은 임의 위젯을 받는다. Figma 등가물은 INSTANCE_SWAP')
        print("   property 다 — `defineProp(owner, '<Slot>', 'INSTANCE_SWAP', <defaultId>)`")
        print('   + 그 슬롯을 그리는 인스턴스에 `bindSwapProp`.')
        return 1

    print(
        f'✅ G15 property 없는 슬롯 {total}개 / 단일 슬롯 {total_slots} '
        f'(baseline {expected} 이하) · TEXT 만 {partial_total}.'
    )
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
