"""Counts chrome fields that have no `default*` — the rule's own orphan field.

`core/layer-mapping.md` states the requirement and even ships the grep that
finds it:

    # field 는 있는데 default 없음 — orphan field

and the line above it says an exemption needs an audited justification
("면제 정당성 audit 필수 (절대 임의 면제 금지)"). What it does not have is a
gate. The snippet is written per-component with `{component}` as a literal
placeholder, so it was never something CI could run, and nothing else looks at
this pairing — `verify_contracts.sh` has eight stages and the closest one
([8/8]) checks a field against `==`/`hashCode`/`copyWith`/`merge`, not against
its default.

So the fields accumulated. The Figma exporter is what surfaced them: a nullable
field with no default has nothing to emit, so it never reaches the canvas, and
the coverage guard reports it as `no-default`. That was 161 fields — but read
from the wrong end. They are not "values Core has not decided yet"; they are
the state this repo's own rule already calls a violation.

WHAT COUNTS

A nullable instance field on a MAIN `CoreXxxStyle` needs one of:

  · `static const|final default<Field>` in the same class, or
  · an entry under that name inside any `…DefaultsBy…` map literal — the tree
    has eight (`defaultsByVariant`, `defaultsBySize`, `ByType`, `ByTone`,
    `ByStatus`, `ByState`, `ByColor`, and the private
    `_dimensionalDefaultsBySize`). A per-axis table IS the default for a field
    whose value varies along that axis,
  · or a same-named field on the class's `CoreXxxVariantStyle` sibling — the
    table's value type carries the per-variant half of the same field.

WHAT IS NOT COUNTED, AND WHY

`CoreXxxVariantStyle` / `CoreXxxSizeStyle` classes are skipped entirely. Their
fields are the values a table holds, not slots a caller overrides, so a
`default*` for them would be a default for a default.

Behaviour fields are not distinguished. `style-contract.md` says behaviour does
not belong on a Style class at all, so a `bool`/`int` field here is a different
violation and this guard would be the wrong place to name it.

WHAT THIS CANNOT SEE

Whether a default that exists is the RIGHT value, and whether a field that
legitimately has none carries the audited justification the rule demands. An
exemption today looks exactly like an oversight — which is most of why 161 of
them are indistinguishable from each other. Fixing that means writing the
justification down, and this guard's number going down either way is the point:
a decided exemption and a supplied default are both decisions, and silence is
neither.

Usage: python3 scripts/guards/structure/figma_orphan_fields.py [--report|--update]
"""

import collections
import glob
import re
import sys

CONTRACTS = 'packages/coui_core/lib/src/component/contracts'
RESOLVERS = [
    'packages/coui_flutter/lib/src/components/*/*/*_style.dart',
    'packages/coui_web/lib/src/components/*/*/*_style.dart',
]
BASELINE = 'scripts/guards/structure/figma_orphan_fields_baseline.txt'

# `final CoreColor? backgroundColor;` — nullable instance fields only. A
# non-nullable field is not an override slot (the caller cannot omit it), so the
# `default*` requirement does not apply to it.
FIELD = re.compile(r'^\s+final\s+([A-Za-z0-9_<>, ]+\?)\s+([a-z]\w*)\s*;', re.M)

# Class bodies, by brace depth — a regex cannot find the end of one, and
# splitting on `\nclass ` breaks on the nested-class files this tree has.
CLASS_HEAD = re.compile(r'\n(?:@\w+\s+)*(?:abstract\s+)?(?:final\s+|base\s+|sealed\s+)*class\s+(\w+)')


def strip_comments(src: str) -> str:
    """Comments out, newlines kept so line numbers stay usable in reports."""
    src = re.sub(r'/\*.*?\*/', lambda m: '\n' * m.group(0).count('\n'), src, flags=re.S)
    return re.sub(r'(?<!:)//[^\n]*', '', src)


def class_bodies(src: str) -> dict[str, str]:
    """`{className: body}` by brace matching from each declaration."""
    out: dict[str, str] = {}
    for match in CLASS_HEAD.finditer(src):
        start = src.find('{', match.end())
        if start < 0:
            continue
        depth = 0
        for i in range(start, len(src)):
            if src[i] == '{':
                depth += 1
            elif src[i] == '}':
                depth -= 1
                if depth == 0:
                    out[match.group(1)] = src[start:i]
                    break
    return out


def table_literals(body: str) -> str:
    """The text INSIDE `defaultsByVariant` / `defaultsBySize` map literals.

    Scoped by brace matching rather than searched over the file, because the
    file is full of `field: other.field ?? field,` lines — `merge` and
    `copyWith` bodies mention every field by name with a colon after it. The
    first draft of this check searched the whole source and credited
    `CoreButtonStyle.maxWidth` as having a default on the strength of

        maxWidth: other.maxWidth ?? maxWidth,

    in `merge`. There is no `defaultMaxWidth` anywhere in that file. The count
    read 101 and was an UNDERCOUNT — the direction that matters, because a
    guard that credits a violation reports the codebase as cleaner than it is
    and nobody goes looking.
    """
    out: list[str] = []
    # Any `…[Dd]efaultsBy…` map, not the two names first guessed. The tree
    # has eight: `defaultsByVariant`, `defaultsBySize`, and one each of
    # `ByType`/`ByTone`/`ByStatus`/`ByState`/`ByColor`, plus the private
    # `_dimensionalDefaultsBySize` that `description_card` merges from. Naming
    # the two common ones scored the other six as absent, and description_card
    # alone accounted for twelve fields whose values are right there.
    for match in re.finditer(r'_?\w*[Dd]efaultsBy\w*\s*=\s*\{', body):
        depth = 0
        start = body.index('{', match.start())
        for i in range(start, len(body)):
            if body[i] == '{':
                depth += 1
            elif body[i] == '}':
                depth -= 1
                if depth == 0:
                    out.append(body[start:i])
                    break
    return '\n'.join(out)


def resolver_sources() -> dict[str, str]:
    """`{componentSlug: concatenated resolver source}` for both platforms."""
    out: dict[str, str] = collections.defaultdict(str)
    for pattern in RESOLVERS:
        for path in sorted(glob.glob(pattern)):
            slug = path.rsplit('/', 1)[1][: -len('_style.dart')]
            out[slug] += strip_comments(open(path, encoding='utf-8').read())
    return out


def slug_of(class_name: str) -> str:
    """`CoreDescriptionCardStyle` → `description_card`."""
    bare = class_name[len('Core') : -len('Style')]
    return re.sub(r'(?<!^)(?=[A-Z])', '_', bare).lower()


# `merged.<field> ?? <fallback>` — the resolver's own answer to "what is this
# field's baseline". Every resolver in the tree names that local `merged`
# (1021 occurrences, no other spelling), so this reads the real thing rather
# than a convention hoped for.
def baseline_kind(src: str, field: str) -> str:
    """Where this field's baseline lives, per the resolver. '' when nowhere."""
    match = re.search(rf'merged\.{re.escape(field)}\s*\?\?\s*([^;,\n]+)', src)
    if not match:
        return ''
    value = match.group(1).strip().rstrip(')')
    if re.search(r'Core\w+Style\.default', value):
        return 'core'
    # `vs.textColor` / `variantStyle.focusBorderColor` — the per-axis table IS
    # the baseline; the flat field and the table field simply carry different
    # names for it. `banner.foregroundColor` ↔ `CoreBannerVariantStyle.textColor`
    # is the shape, and the Figma builder reads the table, so nothing is broken
    # anywhere — only a name-matching guard could call it a violation.
    if re.match(r'^(vs|variantStyle|sizeStyle|sz|chrome)\.', value):
        return 'table'
    # `theme.surfaceBlur` — the theme axis owns it. Freezing this into a
    # `static const` would take the value OUT of the axis's reach, which
    # `core/theme-axis-composition.md` forbids: the axis's seat is token
    # resolution, and a Style-level constant is downstream of it.
    if re.match(r'^(context\.theme|theme)\.', value):
        return 'theme'
    # `material?.blurRadius` — the theme axis again, one hop further. A
    # role-aware resolver asks `theme.surfaceFor(role)` for the material its
    # component's role gets and reads the terms off that, so the baseline
    # still lives on the axis; only the spelling moved. Freezing it into a
    # `static const` would take it out of the axis's reach exactly as the
    # branch above describes.
    #
    # Matched by the local's name, like the `vs`/`variantStyle` branch above
    # and for the same reason: the classifier sees one expression, not the
    # assignment that produced it. The convention is that a resolver naming
    # this local calls it `material`.
    if re.match(r'^material\??\.', value):
        return 'theme'
    # `merged.errorBorderColor ?? merged.borderColor` — a PRECEDENCE CHAIN, not
    # a missing default. `ResolvedTextField.errorBorderColor` documents the
    # intent: it stays null when the override is unset so the per-state
    # decoration falls through to the variant table's `borderColor`. A
    # `static const` here would stop it being null and kill that path — the fix
    # would be the defect.
    #
    # This is the "면제 정당성" the rule asks for, and it is already written
    # down where it belongs (on the resolved field). Counting it would demand a
    # default that the code explains why it must not have.
    if re.match(r'^merged\.', value):
        return 'chain'
    return 'literal'


# An exemption written on the field. The rule asks for "면제 정당성" and this is
# where it lands — a doc comment saying this field deliberately has no default
# and naming what a default would break.
#
# Recognised so that WRITING the justification moves the count. It did not
# before: `strip_comments` runs first, so 84 exemptions were structurally
# invisible and the number stayed at 119 after the decisions were made. A
# decision that does not move the number reads as work not done, and the next
# reader audits all 119 again.
#
# The gaming risk — write the words, skip the thinking — is real and is handled
# the way this repo handles every other approval: the words appear in a diff a
# reviewer reads. A silent field appears nowhere.
EXEMPTION = re.compile(
    r'(no `?default\*?`?'
    r'|absence is the design'
    r'|deliberately'
    r'|by design'
    r'|not have (?:a|its own) default'
    # `@hostDerived` (coui_core) — the value is injected by the host at render
    # time, so no constant CAN hold it. The annotation is the statement; a doc
    # sentence saying the same thing is welcome but not required.
    r'|@hostDerived\b)',
    re.I,
)


def field_doc(raw: str, field: str) -> str:
    """The `///` block immediately above a field declaration, from RAW source.

    Annotation lines (`@hostDerived`, `@Deprecated(...)`) between the doc and
    the `final` are part of the returned text: they do not break the doc's
    adjacency, and an annotation is itself a statement this guard may read.
    Without this, one annotation line hid a field's exemption sentence and the
    guard counted a deliberate absence as a gap.
    """
    match = re.search(
        rf'((?:^[ \t]*(?://|@)[^\n]*\n)*)^[ \t]*final\s[^;]*\b{re.escape(field)}\s*;',
        raw,
        re.M,
    )
    return match.group(1) if match else ''


# Value types of this class's `…DefaultsBy…` maps — `Map<K, CoreDrawerStyle>`
# yields `CoreDrawerStyle`.
#
# A table whose VALUE TYPE is the field's own type is that field's baseline, and
# no `field:` key appears anywhere: the whole map value IS the value. So the
# key-matching check above cannot see it. `CoreSwiperStyle.drawerStyle` is the
# shape — both resolvers read
# `CoreSwiperStyle.defaultsByVariant[variant]!.merge(merged.drawerStyle)` — and
# it was counted as having no baseline at all.
def table_value_types(body: str) -> set[str]:
    return {
        m.group(1)
        for m in re.finditer(
            r'Map<[^>]*?,\s*([A-Z]\w+)>\s*\n?\s*_?\w*[Dd]efaultsBy\w*\s*=', body
        )
    }


def orphans() -> tuple[dict[str, list[str]], dict[str, list[str]], dict[str, list[str]]]:
    """Two maps: fields with no baseline at all, and fields whose baseline is
    a literal sitting in a resolver instead of in Core.

    Split because the fixes are different. The first needs someone to DECIDE a
    value — and deciding 104 of them changes what both platforms render, which
    is not a sweep. The second needs the value MOVED, which is mechanical and
    changes nothing visually.

    Collapsing them into one number said "160 violations" when 23 of those were
    resolvers correctly reading a per-axis table or a theme axis under another
    name. A count that includes non-violations sends the next person to do work
    that does not exist.
    """
    found: dict[str, list[str]] = {}
    exempted: dict[str, list[str]] = {}
    resolver_literal: dict[str, list[str]] = {}
    resolvers = resolver_sources()
    for path in sorted(glob.glob(f'{CONTRACTS}/*/*_style.dart')):
        raw = open(path, encoding='utf-8').read()
        src = strip_comments(raw)
        bodies = class_bodies(src)
        for name, body in bodies.items():
            # Only MAIN Style classes own override slots. `VariantStyle` /
            # `SizeStyle` / `ModeStyle` bodies are the values a table holds.
            if not name.startswith('Core') or not name.endswith('Style'):
                continue
            if re.search(r'(Variant|Size|Mode)Style$', name):
                continue
            # The table's value type, when this class has one — its fields are
            # the per-variant half of the same names.
            sibling = '\n'.join(
                b
                for n, b in bodies.items()
                if n.startswith(name[:-len('Style')]) and re.search(r'(Variant|Size|Mode)Style$', n)
            )
            resolver = resolvers.get(slug_of(name), '')
            table_types = table_value_types(body)
            gap: list[str] = []
            noted: list[str] = []
            lifted: list[str] = []
            for _type, field in FIELD.findall(body):
                if _type.rstrip('?').strip() in table_types:
                    continue
                cap = field[0].upper() + field[1:]
                if re.search(rf'static\s+(?:const|final)[^;=]*\bdefault{cap}\b\s*=', body):
                    continue
                # The table's value type declaring the same name — that class
                # is where the per-variant half of this field lives.
                #
                # Matched as a DECLARATION, not as `field:`. The sibling's own
                # `merge`/`copyWith` bodies name every field with a colon after
                # it, so the loose form credited the same way the table check
                # did before it was scoped.
                if re.search(rf'^\s+final\s[^;]*\b{re.escape(field)}\s*;', sibling, re.M):
                    continue
                if re.search(rf'\b{re.escape(field)}\s*:', table_literals(body)):
                    continue
                kind = baseline_kind(resolver, field)
                if kind in ('core', 'table', 'theme', 'chain'):
                    continue
                # The written exemption is checked BEFORE the literal
                # classification, not after. It is an answer to the question this
                # guard asks — "where does this field's baseline live" — and the
                # answer "nowhere, deliberately, and here is what a default would
                # break" does not become a different answer because the resolver
                # spells absence as `?? const []` instead of leaving it null.
                #
                # Checked after, it demanded the value be lifted into Core for two
                # fields whose docs argue that a Core default is the defect:
                # `CoreButtonStyle.boxShadow` (a non-null default puts an
                # elevation under every button in the kit and takes from `Fab` the
                # one thing that distinguishes it) and
                # `CoreProgressStyle.backgroundColor` (a fixed default stops the
                # track deriving from a recoloured arc and makes the sibling
                # `backgroundAlpha`, whose whole contract is "applied when
                # backgroundColor is not set", unreachable). Lifting either would
                # be doing the damage the doc predicts, on this guard's advice.
                # Read the doc from THIS class's declaration onward. Two classes
                # in one file can declare the same field name (a main Style and
                # the per-axis cell it reads); searching the whole file returns
                # the first one, so a cell's written exemption was read off the
                # main Style's field and never counted.
                own = re.search(rf'\bclass\s+{re.escape(name)}\b', raw)
                scoped = raw[own.start():] if own else raw
                if EXEMPTION.search(field_doc(scoped, field)):
                    noted.append(field)
                    continue
                if kind == 'literal':
                    lifted.append(field)
                    continue
                gap.append(field)
            if gap:
                found[name] = gap
            if noted:
                exempted[name] = noted
            if lifted:
                resolver_literal[name] = lifted
    return found, exempted, resolver_literal


def main() -> int:
    silent, exempted, lifted = orphans()
    total = sum(len(v) for v in silent.values())
    note_total = sum(len(v) for v in exempted.values())
    lift_total = sum(len(v) for v in lifted.values())

    if '--report' in sys.argv:
        print(
            f'미결 (default·면제기록 없음, 또는 아무도 안 읽음) {total} · '
            f'클래스 {len(silent)}\n'
            f'면제 기록됨 {note_total} · 클래스 {len(exempted)}\n'
            f'baseline 이 resolver 리터럴 {lift_total} · 클래스 {len(lifted)}\n'
        )
        print('① resolver 리터럴 — Core 로 올리면 끝:')
        for name, fields in sorted(lifted.items(), key=lambda kv: -len(kv[1])):
            print(f'  {name:34} {", ".join(fields)}')
        print()
        print('② 미결 — default 를 주거나, 면제 근거를 적거나, (아무도 안 읽으면)')
        print('   배선하거나 지워야 한다. 근거가 적혀 있어도 "아무도 안 읽는다" 는')
        print('   면제가 아니라 미결이라 여기 남는다:')
        for name, fields in sorted(silent.items(), key=lambda kv: -len(kv[1])):
            print(f'  {name:34} {", ".join(fields)}')
        return 0

    if '--update' in sys.argv:
        open(BASELINE, 'w', encoding='utf-8').write(f'{total} {lift_total}\n')
        print(f'baseline 갱신: 미결 {total} · resolver 리터럴 {lift_total} '
              f'(면제 기록 {note_total} 은 ratchet 대상 아님)')
        return 0

    try:
        line = next(
            l for l in open(BASELINE, encoding='utf-8')
            if l.strip() and not l.startswith('#')
        ).split()
        expected, expected_lift = int(line[0]), int(line[1])
    except (OSError, StopIteration, ValueError, IndexError):
        print(f'❌ baseline 값을 못 읽음: {BASELINE}')
        return 1

    failed = False
    if total > expected:
        failed = True
        print(f'❌ 미결 필드가 늘었다: {total} (baseline {expected}).')
        for name, fields in sorted(silent.items(), key=lambda kv: -len(kv[1]))[:8]:
            print(f'   {name:34} {", ".join(fields[:6])}')
        print()
        print('   `core/layer-mapping.md`: field 는 있는데 default 없음 = orphan field.')
        print('   `static const default<Field>` 를 두거나, default 가 렌더를 바꾸는')
        print('   자리라면 그 필드 doc 에 무엇이 깨지는지 적어라 — 적으면 이 수에서')
        print('   빠지고 "면제 기록됨" 으로 옮겨간다. 아무것도 안 적힌 상태만 센다.')
    if lift_total > expected_lift:
        failed = True
        print(
            f'❌ resolver 가 리터럴로 fallback 하는 필드가 늘었다: '
            f'{lift_total} (baseline {expected_lift}).'
        )
        for name, fields in sorted(lifted.items(), key=lambda kv: -len(kv[1]))[:8]:
            print(f'   {name:34} {", ".join(fields[:6])}')
        print()
        print('   값이 platform resolver 에 살면 두 플랫폼이 각자 갖게 되고 한쪽만')
        print('   바뀌면 조용히 갈라진다 — `CoreXxxStyle.default<Field>` 로 올려라.')
    if failed:
        return 1

    print(
        f'✅ 미결 {total}개 (≤{expected}) · resolver 리터럴 {lift_total}개 '
        f'(≤{expected_lift}) · 면제 기록됨 {note_total}개.'
    )
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
