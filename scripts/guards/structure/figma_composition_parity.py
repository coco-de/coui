"""Counts children a widget composes that its Figma builder never draws.

The criterion this measures is not "does it look close enough" — it is that the
Figma component's structure IS the widget's structure. If `ColorPicker` composes
a `Popover` holding a `TextField` and four `Button`s, the generated component
has to contain those, not a swatch row that resembles the trigger. A designer
who opens the component and finds no popover has been told something false about
the library, and a future Figma→code direction reads structure, so a structure
that was never there cannot be read back.

Nothing else in the pipeline asks this question. The literal ratchet counts
hardcoded values; the field-coverage guard counts whether a Style field reached
`components.json`; the runtime harness catches exceptions. All three are green
for a builder that draws a convincing picture of a component it never composed.

WHAT COUNTS AS SATISFIED

A child is satisfied when the builder expresses it *somehow*, not only via
`instanceOf`:

  Icon          `makeIcon(...)` — it creates an Icon instance internally
  Gap           auto-layout `itemSpacing` / a `gap:` chrome option
  Stacks        manual placement (`layoutMode = 'NONE'` plus `.x`/`.y`)
  FocusOutline  a drawn ring (`setBorder` / focus-ring chrome)

Counting only `instanceOf` inflated the number from 172 to 247, and a guard that
overstates gets argued with instead of acted on. These are deliberately
generous: a false SATISFIED here is a missed finding, which is the direction
that keeps the number honest rather than alarming.

WHAT IS EXCLUDED, AND WHY THAT IS NOT THE SAME AS SATISFIED

`Clickable` is not counted at all. It owns no fill and no border — its whole
visible contribution is a focus ring and a disabled opacity, and the parent
reads both out of its own `clickableStyle` field and paints them itself. A
Figma instance also cannot wrap its parent, so there is no arrangement in which
a builder composes it. `display.ts`'s `buildCard` states this in a comment and
draws the two effects as variant axes, which is the correct answer.

This used to be a satisfaction rule ("any mention"), and that was wrong in a way
that hid 29 edges: comments were part of the text being matched, so a paragraph
of prose mentioning `Clickable` credited whichever function it happened to sit
after — and the transitive fold spread that credit to every caller. The count
read 20 while the honest figure was 53. An exclusion says the same thing about
`Clickable` without letting prose decide any other component's score.

WHAT IT CANNOT SEE

Whether the child is composed in the right *place*, or how many. A builder that
instantiates one Button where the widget composes four scores as satisfied. This
counts presence, not shape — the ceiling of what a static scan can claim.

Usage: python3 scripts/guards/structure/figma_composition_parity.py [--report]
"""

import collections
import glob
import json
import os
import re
import subprocess
import sys

PLUGIN = 'tools/figma-token-sync/src/components'
# Children no builder can compose — see "WHAT IS EXCLUDED" above.
EXCLUDED = frozenset({'Clickable'})
FLUTTER = 'packages/coui_flutter/lib/src/components'
NAMES_SCRIPT = 'scripts/guards/structure/figma_registry_names.py'


def registry_names() -> set[str]:
    out = subprocess.run(
        ['python3', NAMES_SCRIPT], capture_output=True, text=True, check=True
    ).stdout
    return set(out.split())


def slug_of(name: str) -> str:
    return re.sub(r'(?<!^)(?=[A-Z])', '_', name).lower()


def _strip_comments(src: str) -> str:
    """Comments out, newlines kept so function spans stay put.

    A span here runs from one top-level `function` to the next, comments
    included, and several of these checks match a bare substring. So a
    paragraph of prose that happens to sit between two functions was credited
    to the earlier one — `slotNodes` was scored as composing `Clickable` and
    `Stacks` because the doc comment for the section BELOW it mentioned them,
    and the transitive fold then handed that credit to every builder calling
    `slotNodes`. Badge came out satisfied while `badge.dart` really does
    `return Clickable(...)`.

    Two costs, and the second is the reason this is not merely a wrong number:
    the masked edge was invisible, and the credit depended on where a paragraph
    happened to land — so any refactor that moved a function or a comment
    flipped the count for reasons unrelated to composition.
    """
    src = re.sub(r'/\*.*?\*/', lambda m: '\n' * m.group(0).count('\n'), src, flags=re.S)
    return re.sub(r'(?<!:)//[^\n]*', '', src)


def _direct(body: str) -> set[str]:
    """Children a single function body expresses."""
    found = {m.group(1) for m in re.finditer(r"instanceOf\(\s*page,\s*'(\w+)'", body)}
    if 'makeIcon(' in body:
        found.add('Icon')
    # A `Divider` composed through the one helper allowed to instance it.
    #
    # Spanning the box a rule separates takes two writes (the instance stretches,
    # and the line inside it stretches), either one alone leaves the rule short,
    # and short reads as a design choice rather than a bug — so
    # `check_divider_hosting.sh` makes `hostedDivider` the only door and the
    # half-applied state unrepresentable. That moved the `instanceOf` text out of
    # five builder bodies, and this gate credits composition by text: it reported
    # all five as newly un-composed while the canvas gained a correctly spanning
    # rule in four of them.
    #
    # Crediting the helper CALL, not the `needs` declaration, for the reason the
    # note below gives for `setSlotIcon`: `needs` is a build-order claim a builder
    # can make while drawing nothing.
    if 'hostedDivider(' in body:
        found.add('Divider')
    # `popupInstance` in popup-composition.ts creates a real Popup instance,
    # selecting the member for the parent's stated padding. The local-helper
    # fold cannot follow that import, just as with hostedDivider / setSlotIcon.
    # Credit the call, never a comment, import or `needs: ['Popup']` declaration.
    if re.search(r'\bpopupInstance\s*\(', body):
        found.add('Popup')
    # An icon expressed by SWAPPING a composed component's slot to it, rather
    # than by instantiating one directly. `Select` draws the selected row's check
    # exactly where the widget puts it — inside the row `Button`'s own `trailing:`
    # — so the canvas has the icon and the builder body has no `Icon(` text.
    #
    # This is the shape the docstring above credits to `needs`, and reading
    # `needs` would be the wrong fix: it is a BUILD-ORDER declaration, so a
    # builder could declare it and draw nothing, and every entry declares it for
    # whatever it instantiates. Crediting the swap CALL keeps the claim tied to
    # something the builder actually does.
    if 'setSlotIcon(' in body:
        found.add('Icon')
    # `gapSpacer(` is a Gap drawn as its own node instead of as the parent's
    # `itemSpacing`. `EmptyState` has to: the widget interleaves THREE different
    # gaps down one column (16 / 8 / 24) and a Figma frame has one `itemSpacing`,
    # so spending one value in all three places had two of the three wrong on
    # every member. Interleaving real spacers is the faithful shape, and it must
    # not read as having stopped composing `Gap`.
    if (
        'itemSpacing' in body
        or re.search(r'\bgap:', body)
        or 'gapSpacer(' in body
        # `applyFormRowChrome(` sets `itemSpacing` inside helpers.ts, and the
        # transitive fold below only follows helpers in the SAME file — so three
        # form builders (Checkbox / Toggle / RadioGroup) read as having stopped
        # composing `Gap` the moment their row chrome moved into that helper.
        # Exactly the failure the `pinAbsolute(` note below describes: the
        # composition did not change, only where it is spelled.
        or 'applyFormRowChrome(' in body
    ):
        found.add('Gap')
    # `pinAbsolute(` is absolute positioning expressed through the shared helper
    # rather than in place. The transitive fold below only follows helpers in the
    # SAME file, so a child that moves into `helpers.ts` disappears from this
    # scan — which is what happened when four builders stopped writing
    # `.x =`/`constraints` themselves and called one helper instead. The
    # composition did not change; only where it is spelled did.
    # These imported helpers still position real nodes; moving their bodies
    # below the registry modules must preserve the same composition credit.
    if re.search(r"layoutMode = 'NONE'|\.x =|absolute|\b(?:pinAbsolute|overlayGlyph|iconSlot)\s*\(", body):
        found.add('Stacks')
    # `setBorder(` used to count here, and it was a FALSE credit: that helper
    # draws whatever border its caller asks for, and in the two field builders it
    # was drawing the field's own boundary — not a focus ring. The credit only
    # surfaced when a rewire replaced those two calls with `borderData`, and two
    # real edges appeared that had been masked since the pattern was written.
    #
    # What counts now is a ring: the shared drawer, a `focusRing(` call, or a real
    # `FocusOutline` instance. A generous credit is deliberate here (the docstring
    # says a false SATISFIED is the safer direction) but generous is not the same
    # as wrong — `setBorder(` says nothing about focus.
    # Any call whose NAME says focus ring / focus outline, case-insensitively,
    # plus a real `FocusOutline` instance.
    #
    # Named by pattern rather than by enumerating spellings, because enumerating
    # them is what kept breaking. This list has been repaired twice for the same
    # reason — `focusRing` matched only while the drawer lived in the same file,
    # then `addFocusRing(` had to be added when it moved to `helpers.ts` and
    # `Badge` lost a credit having changed nothing — and it broke a third time on
    # `addSegmentFocusRing(`, a per-segment drawer whose capital F the lowercase
    # substring misses. Each time, the builder drew the ring it always drew and the
    # gate reported a missing composition.
    #
    # Generous by design (the docstring says a false SATISFIED is the safer
    # direction) and no more generous than before: this credits a call that draws a
    # focus ring, which is exactly what the enumerated names were reaching for.
    # Comments are stripped upstream, so prose about focus rings earns nothing.
    if (
        re.search(r'\b\w*[Ff]ocus(?:Ring|Outline)\w*\s*\(', body)
        # The bare substring stays. Written as an ADDITION to it rather than a
        # replacement: dropping it tightened the gate, and tightening it is a
        # different decision from making it robust. `Subfocus` lost its credit that
        # way — its ring is a hand-drawn stroke and its only `focusRing` text is the
        # field read `SUBFOCUS.fields.focusRingRadius`, so the pattern above does
        # not match it. That component IS a real gap (the widget wraps its child in
        # `FocusOutline`; the builder strokes a border), and it is one this gate had
        # never reported — surfacing it belongs to a change that can also fix it,
        # not to one repairing a spelling.
        or 'focusRing' in body
        or "instanceOf(page, 'FocusOutline')" in body
        or "'FocusOutline'" in body
    ):
        found.add('FocusOutline')
    return found


def satisfied_by_builder() -> dict[str, set[str]]:
    """Children each builder expresses, following local helpers.

    Attribution has to be transitive. A builder often delegates a repeated row
    to a file-local helper — `appendMenuRow(page, c, …)` is where Menu's Button
    instance actually lives — and crediting only the text inside `buildMenu`
    scored that child as absent while the canvas has it. The same transitive
    walk was needed to attach `needs: ['Icon']` correctly, and for the same
    reason: the call site and the declaration are in different functions.
    """
    out: dict[str, set[str]] = collections.defaultdict(set)
    for path in sorted(glob.glob(f'{PLUGIN}/*.ts')):
        with open(path, encoding='utf-8') as source:
            src = _strip_comments(source.read())
        # `async` is optional: an async builder is still a builder, and matching
        # only the bare keyword silently merged `async function buildButton`
        # into the previous function's body — Button lost every credit at once.
        starts = [(m.group(1), m.start(), m.end()) for m in re.finditer(r'\n(?:async )?function (\w+)\s*\(', src)]
        bodies: dict[str, str] = {}
        for i, (fn, _s, e) in enumerate(starts):
            stop = starts[i + 1][1] if i + 1 < len(starts) else len(src)
            bodies[fn] = src[e:stop]
        direct = {fn: _direct(b) for fn, b in bodies.items()}
        # Fold each helper's children into every function that calls it, until
        # nothing new appears (helpers call helpers).
        changed = True
        while changed:
            changed = False
            for fn, body in bodies.items():
                for other, kids in direct.items():
                    if other == fn or not kids:
                        continue
                    if re.search(r'\b' + re.escape(other) + r'\s*\(', body) and not kids <= direct[fn]:
                        direct[fn] |= kids
                        changed = True
        for fn, kids in direct.items():
            if fn.startswith('build'):
                out[fn[len('build'):]] |= kids
    return out


def composed_by_widget(name: str, names: set[str]) -> set[str]:
    text = ''
    for d in glob.glob(f'{FLUTTER}/*/{slug_of(name)}'):
        for f in glob.glob(f'{d}/*.dart'):
            text += open(f, encoding='utf-8').read()
    if not text:
        return set()
    # Doc comments describe usage rather than composition, and `///` starts
    # with `//`, so one strip covers both.
    text = re.sub(r'//[^\n]*', '', text)
    # A prefixed call is another library's class, not this registry's
    # component: `definition_list.dart` builds its `columns` layout on
    # Flutter's own `widgets.Table(` — imported under a prefix precisely
    # because the barrel hides that name so `Table` can be CoUI's data table.
    # Reading the bare name credited the data table as a composed child.
    # Named constructors are lower-case, so `Button.primary(` never matched
    # here and nothing real is lost.
    return {
        m.group(1)
        for m in re.finditer(r'(?<!\.)\b([A-Z][A-Za-z]+)\(', text)
        if m.group(1) in names and m.group(1) != name and m.group(1) not in EXCLUDED
    }


def main() -> int:
    names = registry_names()
    sat = satisfied_by_builder()
    missing: dict[str, list[str]] = {}
    for name in sorted(names):
        gap = sorted(composed_by_widget(name, names) - sat.get(name, set()))
        if gap:
            missing[name] = gap
    total = sum(len(v) for v in missing.values())

    if '--report' in sys.argv:
        by_child = collections.Counter(c for v in missing.values() for c in v)
        print(f'미합성 간선 {total} · 영향 컴포넌트 {len(missing)}\n')
        print('자식별:')
        for child, n in by_child.most_common():
            print(f'  {child:20} {n:3}')
        print('\n컴포넌트별:')
        for name, kids in sorted(missing.items(), key=lambda kv: -len(kv[1])):
            print(f'  {name:22} {", ".join(kids)}')
        return 0

    # baseline 은 없다. 조건은 "미합성 간선은 전부 이름이 적혀 있어야 한다" 이고,
    # 통과하는 길은 합성이거나 이름과 사유다 — G16 과 같은 모양이며 같은 이유다:
    # 숫자로 통과할 수 있으면 그 숫자가 무엇인지 아무도 말하지 않아도 된다.
    allow_path = 'scripts/guards/structure/figma_composition_allowlist.json'
    allow: dict[str, dict[str, str]] = {}
    if os.path.exists(allow_path):
        with open(allow_path, encoding='utf-8') as fh:
            allow = json.load(fh).get('edges') or {}

    concluded = {
        'wrapper',
        'sibling-file',
        'drawn',
        'composed-in-child',
        'unreachable-default',
        'gesture',
    }
    pending_kinds = {'needs-compose'}

    faults: list[str] = []
    for key, entry in sorted(allow.items()):
        cat = (entry or {}).get('category')
        why = ((entry or {}).get('why') or '').strip()
        if cat not in concluded | pending_kinds:
            faults.append(f'{key}: category {cat!r} 이 알려진 것이 아니다')
        if len(why) < 20:
            faults.append(f'{key}: why 가 비었거나 너무 짧다')
    live = {f'{name}.{kid}' for name, kids in missing.items() for kid in kids}
    for key in sorted(allow):
        if key not in live:
            faults.append(f'{key}: 이미 합성되었거나 존재하지 않는 간선이다 — 지워라')
    if faults:
        print(f'❌ allowlist 자체가 규율을 깼다 ({len(faults)}건):')
        for f in faults:
            print(f'   {f}')
        print(f'   파일: {allow_path}')
        return 1

    unnamed = {k: [c for c in v if f'{k}.{c}' not in allow] for k, v in missing.items()}
    unnamed = {k: v for k, v in unnamed.items() if v}
    if unnamed:
        n = sum(len(v) for v in unnamed.values())
        print(f'❌ 이름이 적히지 않은 미합성 간선 {n}개.')
        print()
        for name, kids in sorted(unnamed.items(), key=lambda kv: -len(kv[1])):
            print(f'   {name:22} {", ".join(kids)}')
        print()
        print('   빌더가 그 자식을 닮은 것을 직접 그리는 대신')
        print("   `instanceOf(page, '<Child>')` 로 합성하고 REGISTRY 엔트리에")
        print("   `needs: ['<Child>']` 를 붙여라. 합성할 수 없다면 그 이유를")
        print(f'   {os.path.basename(allow_path)} 에 category 와 why 로 적어라 —')
        print('   이 게이트에 숫자는 없다.')
        return 1

    pending = sorted(k for k in allow if allow[k].get('category') in pending_kinds)
    print(
        f'✅ G14 미합성 간선 전수 열거됨 '
        f'(결론 {len(allow) - len(pending)}개 · 남은 일 {len(pending)}개). baseline 없음.'
    )
    for key in pending:
        print(f'   ○ {key} — {allow[key].get("why", "")}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
