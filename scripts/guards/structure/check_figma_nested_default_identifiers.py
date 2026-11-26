#!/usr/bin/env python3
"""Nested-Style default identifiers — does `components.json` carry what Core states?

A nested-Style default is a `static const CoreChildStyle defaultSlot =
CoreChildStyle(field: value, …)` on a Style class. When `value` is a bare
identifier (`backgroundColor: defaultBackgroundColor`) the value lives in the
SAME class as the constructor call, one member over. The exporter used to emit
that argument in the CHILD class's scope instead — so the identifier resolved
against `CoreChildStyle.defaultBackgroundColor` (a different value) or against
nothing, and in both cases the child's own default reached the canvas.

`CardImage`'s frame was drawn with a `surface` fill and an `outline-variant`
border while both platforms paint it transparent. The parity baseline agreed
with the code the whole time; the canvas was the only thing wrong, and nothing
compared the canvas's input to the code's. G1 asks whether the JSON is fresh,
G10 whether a field reached it — this is the first gate that asks whether the
value that reached it is the value Core states.

WHAT THIS COMPARES

For every nested-Style default constructor argument that is an identifier —
bare (`defaultX`, same class) or qualified (`CoreOtherStyle.defaultX`) — and
whose declared type routes as a LEAF (colour / dim / insets / radius / text /
gap / icon / duration / shadow / enum), two exports of the same Core value must
agree:

  · `components[slug].fields|constants[slot][arg]`   — the nested emission
  · `components[owner].fields|constants[identKey]`   — the identifier's own
                                                       top-level export

Both come from the same exporter, so equality proves the nested argument
resolved to the same value the identifier stands for. `via` (the alias chain,
provenance only) is stripped before comparing: the nested path may record one
more hop (`defaultX -> CoreSpace.space16`) than the top-level one, and that is
not a difference in value.

A PRIVATE static (`_chevronIconSize`) has no top-level export to compare
against — the exporter skips private members at the top level — so for those
only presence is asserted: the nested leaf must carry a value. A dropped
private reference is the same silence as a dropped public one.

An identifier whose declared type is itself a `Core…Style` (other than the
three leaf-routed ones) is a nested-Style REFERENCE — `popupStyle:
defaultSubmenuPopupStyle` — which the exporter follows through
`resolveCallInScope` and which was never part of this fault. Those are
counted and skipped.

WHAT THIS CANNOT SEE

An identifier the exporter dropped along with its whole slot, and an identifier
whose own top-level export is missing. Both are reported as `unverifiable` and
FAIL the guard: a comparison that silently skips is how the fault lived this
long. Neither state exists in the tree today.

Three more, written down because a gate whose reach is not stated gets read as
covering everything it sits next to — the failure this repo keeps paying for.

1. ALIAS-FORM nested defaults. `NESTED_DEFAULT` requires a CONSTRUCTOR CALL on
   the right-hand side, so a default that IS an identifier — no arguments to
   compare — never enters the population:

     static const CorePopupStyle defaultPopupStyle =
         CoreMenuStyle.defaultPopupStyle;          // fab_style.dart
     static const CoreTextFieldStyle defaultSearchFieldStyle =
         chromelessFieldStyle;                     // phone_input_style.dart

   Both resolve correctly today — `fab.popupStyle` and `menu.popupStyle` export
   the same value once `via` is stripped, and `phone_input.searchFieldStyle`
   carries its 27 fields. That is a measurement, not a guarantee: this guard is
   not what would catch it if either stopped.

2. PRIVATE statics, by value. A private identifier has no top-level export to
   compare against (the exporter skips private members there), so the nested
   emission records `ref: null` and only its PRESENCE is asserted —
   `phone_input.chevronIconStyle.size` is `{v: 12.0, ref: null, via:
   "_chevronIconSize"}`. A private reference that resolved to the WRONG value
   would still carry a value and still pass.

3. Whether a slot that emitted nothing SHOULD have emitted something. This
   compares values that reached the JSON against each other; a nested-Style
   argument the reader could not follow is refused at the source instead
   (`schema_v2.dart#_emitNestedStyle`), which is the other half of the same
   question and lives there because only the reader knows it looked.

No ratchet baseline. The exporter resolves these in the writing class's scope,
so the correct count is zero and a new drift is a new bug.

Usage:
  python3 scripts/guards/structure/check_figma_nested_default_identifiers.py [--report]

Exit 1 on any drift or any unverifiable site. `--report` prints every site,
including the ones that agree.
"""

from __future__ import annotations

import glob
import json
import re
import sys

CONTRACTS = 'packages/coui_core/lib/src/component/contracts'
COMPONENTS_JSON = 'tools/figma-token-sync/src/data/components.json'

# Annotations (one level of parens inside the argument list is enough for a
# `@Deprecated('… (since 0.1).')` message) are captured so a retired class —
# which the exporter does not ship — can be skipped rather than reported as
# an unexported component.
CLASS_HEAD = re.compile(
    r'\n((?:@\w+(?:\((?:[^()]|\([^()]*\))*\))?\s+)*)'
    r'(?:abstract\s+)?(?:final\s+|base\s+|sealed\s+)*class\s+(\w+)'
)
IMPLEMENTS_CORE_STYLE = re.compile(r'\bimplements\b[^{]*\bCoreStyle\s*<')
NESTED_STYLE_TYPE = re.compile(r'^Core[A-Z][A-Za-z0-9]*Style$')
# `static const CoreChildStyle defaultSlot =` (or `static final`), followed by
# an optional `const` and the child's constructor call — plain or named
# (`CoreTextStyle.token(...)`). The call's argument text is cut by paren
# matching below, not by this regex.
NESTED_DEFAULT = re.compile(
    r'static\s+(?:const|final)\s+(Core[A-Z][A-Za-z0-9]*Style)\s+(\w+)\s*=\s*'
    r'(?:const\s+)?(Core[A-Z][A-Za-z0-9]*Style)(?:\.\w+)?\s*\('
)
STATIC_DECL = re.compile(
    r'static\s+(?:const|final)\s+([A-Za-z_][\w<>, ?]*?)\s+(\w+)\s*='
)
BARE_IDENT = re.compile(r'^[a-z_]\w*$')
QUALIFIED_IDENT = re.compile(r'^(Core[A-Z][A-Za-z0-9]*)\.(\w+)$')

# Mirrors `schema_v2.dart#fieldKindOf` — the leaf-routed Style types. Every
# other `Core…Style` is a nested slot.
LEAF_STYLE_TYPES = {'CoreTextStyle', 'CoreGapStyle', 'CoreIconStyle'}


def strip_comments(src: str) -> str:
    src = re.sub(r'/\*.*?\*/', lambda m: '\n' * m.group(0).count('\n'), src, flags=re.S)
    return re.sub(r'(?<!:)//[^\n]*', '', src)


def class_bodies(src: str) -> dict:
    """`{className: (annotations, headerText, body)}` by brace matching."""
    out = {}
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
                    out[match.group(2)] = (
                        match.group(1),
                        src[match.end():start],
                        src[start:i],
                    )
                    break
    return out


def balanced(text: str, open_at: int) -> int:
    """Index of the `)` matching the `(` at `open_at`, or -1."""
    depth = 0
    for i in range(open_at, len(text)):
        c = text[i]
        if c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
            if depth == 0:
                return i
    return -1


def split_args(text: str) -> list:
    """Top-level `name: value` pairs of a constructor's argument text."""
    out = []
    depth = 0
    current = []
    for c in text:
        if c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
        if c == ',' and depth == 0:
            out.append(''.join(current))
            current = []
        else:
            current.append(c)
    if ''.join(current).strip():
        out.append(''.join(current))
    pairs = []
    for raw in out:
        raw = raw.strip()
        m = re.match(r'^(\w+)\s*:\s*(.+)$', raw, re.S)
        if m:
            pairs.append((m.group(1), m.group(2).strip()))
    return pairs


def json_key_for(member: str) -> str:
    """`schema_v2.dart#_constantJsonKey` / `emit.dart#jsonKeyFor`."""
    if not member.startswith('default'):
        return member
    rest = member[len('default'):]
    if not rest or rest[0].upper() != rest[0]:
        return member
    return rest[0].lower() + rest[1:]


def slug_of(class_name: str) -> str:
    bare = class_name
    if bare.startswith('Core'):
        bare = bare[4:]
    if bare.endswith('Style'):
        bare = bare[:-5]
    return re.sub(r'(?<!^)(?=[A-Z])', '_', bare).lower()


def static_decl(body: str, name: str):
    """`(declaredType, matchStart)` of `static const|final <T> <name> =`."""
    for m in STATIC_DECL.finditer(body):
        if m.group(2) == name:
            return m.group(1).strip(), m.start()
    return None


_STRING_LITERAL = re.compile(r"'(?:\\.|[^'\\\n])*'|\"(?:\\.|[^\"\\\n])*\"")


def is_deprecated_at(body: str, decl_start: int) -> bool:
    """Whether the declaration starting at `decl_start` carries `@Deprecated`.

    The statement boundary is found with string literals blanked out: a
    deprecation message that says "set X instead; this default …" holds a
    `;`, and taking it for the end of the previous statement cut the
    annotation off and read a retired default as a live one.
    """
    head = body[:decl_start]
    code = _STRING_LITERAL.sub(lambda m: ' ' * len(m.group(0)), head)
    boundary = max(code.rfind(';'), code.rfind('{'), code.rfind('}'))
    return '@Deprecated' in head[boundary + 1:]


def strip_via(value):
    if isinstance(value, dict):
        return {k: strip_via(v) for k, v in value.items() if k != 'via'}
    if isinstance(value, list):
        return [strip_via(v) for v in value]
    return value


def compact(value) -> str:
    """One-line human rendering of a leaf, for the report."""
    if value is None:
        return '∅'
    if isinstance(value, dict):
        if 'argb' in value:
            ref = value.get('ref')
            base = ref if ref else '#%08x' % (value.get('argb') or 0)
            op = value.get('opacity', 1.0)
            return base if op in (1, 1.0) else '%s @%s' % (base, op)
        if 'v' in value and 'ref' in value:
            v = value['v']
            return '%s' % (int(v) if float(v).is_integer() else v)
        if set(value) >= {'l', 't', 'r', 'b'}:
            return 'l%s t%s r%s b%s' % tuple(compact(value[k]) for k in ('l', 't', 'r', 'b'))
        if set(value) >= {'start', 't', 'end', 'b'}:
            return 's%s t%s e%s b%s' % tuple(compact(value[k]) for k in ('start', 't', 'end', 'b'))
        if set(value) >= {'topLeft', 'topRight', 'bottomLeft', 'bottomRight'}:
            corners = [compact(value[k]) for k in ('topLeft', 'topRight', 'bottomLeft', 'bottomRight')]
            return corners[0] if len(set(corners)) == 1 else '/'.join(corners)
        if 'choice' in value:
            return '.%s' % value['choice']
        return json.dumps(strip_via(value), sort_keys=True)
    return json.dumps(value)


def exported(component: dict, key: str):
    """`fields[key]` else `constants[key]` else None."""
    fields = component.get('fields') or {}
    if key in fields:
        return fields[key]
    constants = component.get('constants') or {}
    if key in constants:
        return constants[key]
    return None


def main(argv) -> int:
    report = '--report' in argv
    with open(COMPONENTS_JSON, encoding='utf-8') as f:
        components = json.load(f)['components']

    drift = []
    unverifiable = []
    agree = []
    nested_refs = []

    for path in sorted(glob.glob('%s/**/*_style.dart' % CONTRACTS, recursive=True)):
        src = strip_comments(open(path, encoding='utf-8').read())
        bodies = class_bodies('\n' + src)
        for cls, (annotations, header, body) in bodies.items():
            if not IMPLEMENTS_CORE_STYLE.search(header):
                continue
            if '@Deprecated' in annotations:
                # A retired component is not shipped; nothing of it is on the
                # canvas to be wrong.
                continue
            slug = slug_of(cls)
            component = components.get(slug)
            for m in NESTED_DEFAULT.finditer(body):
                slot_type, member, ctor = m.group(1), m.group(2), m.group(3)
                if member.startswith('_'):
                    continue
                if slot_type != ctor:
                    continue
                close = balanced(body, m.end() - 1)
                if close < 0:
                    continue
                args = split_args(body[m.end():close])
                slot_key = json_key_for(member)
                for arg, value in args:
                    ident = None
                    owner_cls = cls
                    owner_body = body
                    if BARE_IDENT.match(value) and value not in ('true', 'false', 'null'):
                        ident = value
                    else:
                        q = QUALIFIED_IDENT.match(value)
                        if q and q.group(1) in bodies:
                            owner_cls = q.group(1)
                            owner_body = bodies[owner_cls][2]
                            ident = q.group(2)
                        elif q and q.group(1).endswith('Style'):
                            # A class from another file — resolved through the
                            # global registry by the exporter; verified below
                            # only through that class's own export.
                            owner_cls = q.group(1)
                            owner_body = None
                            ident = q.group(2)
                    if ident is None:
                        continue

                    site = '%s.%s.%s' % (slug, slot_key, arg)
                    origin = '%s.%s' % (owner_cls, ident)

                    decl = static_decl(owner_body, ident) if owner_body is not None else None
                    if owner_body is not None and decl is None:
                        # Not a static of that class (an inherited or top-level
                        # name) — the exporter cannot follow it either.
                        unverifiable.append((site, origin, 'identifier is not a static member of %s' % owner_cls))
                        continue
                    decl_type = decl[0] if decl else None
                    if decl_type and NESTED_STYLE_TYPE.match(decl_type) and decl_type not in LEAF_STYLE_TYPES:
                        nested_refs.append((site, origin, decl_type))
                        continue
                    if decl and is_deprecated_at(owner_body, decl[1]):
                        # A retired default is not exported at all — nothing
                        # to compare and nothing on the canvas.
                        continue

                    if component is None:
                        unverifiable.append((site, origin, '%s is not an exported component' % slug))
                        continue
                    slot = exported(component, slot_key)
                    if not isinstance(slot, dict):
                        unverifiable.append((site, origin, 'slot %s.%s not exported' % (slug, slot_key)))
                        continue
                    canvas = slot.get(json_key_for(arg))

                    if ident.startswith('_'):
                        if canvas is None:
                            drift.append((site, origin, compact(canvas), '(private static — value present in Core)'))
                        else:
                            agree.append((site, origin, '%s  (private — presence only)' % compact(canvas)))
                        continue

                    owner_component = components.get(slug_of(owner_cls))
                    if owner_component is None:
                        unverifiable.append((site, origin, '%s is not an exported component' % owner_cls))
                        continue
                    core = exported(owner_component, json_key_for(ident))
                    if core is None:
                        unverifiable.append((site, origin, '%s has no top-level export' % origin))
                        continue

                    if strip_via(canvas) == strip_via(core):
                        agree.append((site, origin, compact(core)))
                    else:
                        drift.append((site, origin, compact(canvas), compact(core)))

    if report:
        print('── nested-Style default identifier sites ──')
        for site, origin, value in agree:
            print('   ok     %-52s ← %-48s %s' % (site, origin, value))
        for site, origin, decl in nested_refs:
            print('   nested %-52s ← %-48s (%s reference — resolved by resolveCallInScope)' % (site, origin, decl))
        print()

    for site, origin, canvas, core in drift:
        print('❌ DRIFT  %s ← %s' % (site, origin))
        print('   canvas carries : %s' % canvas)
        print('   Core states    : %s' % core)
    for site, origin, why in unverifiable:
        print('❌ UNVERIFIABLE  %s ← %s — %s' % (site, origin, why))

    print(
        'nested-Style default identifiers: %d leaf agree · %d drift · %d unverifiable · %d nested-Style refs (skipped)'
        % (len(agree), len(drift), len(unverifiable), len(nested_refs))
    )
    if drift or unverifiable:
        print('   왜: components.json 이 실은 값이 Core 가 진술한 값과 다르면 캔버스가 어느 플랫폼도 칠하지 않는 chrome 을 그린다.')
        print('   무엇을: `dart run packages/coui_core/bin/export_figma_components.dart` 로 재생성하고, 그래도 갈리면 exporter 의 nested overlay 가 부모 스코프로 식별자를 푸는지(schema_v2.dart `_emitNestedStyle` · emit.dart `resolveCallInScope`) 본다.')
        return 1
    print('✅ every nested-Style default identifier reaches the canvas as the value Core states.')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
