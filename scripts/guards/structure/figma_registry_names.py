"""Prints the component names the Figma plugin's REGISTRY actually contains.

Split out of `check_figma_registry_parity.sh` rather than inlined as a heredoc:
bash 3.2 (macOS's system bash, and what this repo targets) scans the body of a
`$( ... )` command substitution for the closing paren *before* honouring a
quoted heredoc, and it tracks quote balance while doing so. A regex containing
`['"]` — unbalanced from bash's point of view — makes it run off the end of the
file and report a syntax error hundreds of lines later, pointing at innocent
code. A separate file has no quoting hazard at all.

Two things are extracted here, and both had to stop being line-based:

  · WHICH FILES COUNT — only builder files whose export array ends up inside the
    REGISTRY expression. A `RegistryEntry` in a file nothing imports is not
    covered: `generate.ts` iterates REGISTRY, so such a builder never runs and
    never reaches the canvas. Grepping every file under `src/components/`
    counted four unwired files' 41 entries as covered while the plugin built
    none of them.

  · WHICH NAMES — a REGISTRY entry is an object literal, written on one line or
    on five. A line-based pattern sees only the first shape, and when ten
    builder files gained `needs:` and their longer entries wrapped, the guard
    reported a registered component as having no builder.

BUILDER FIXTURES — a third kind of entry, and why it is not in the names list:
a set the plugin draws for its own use (`.Slot`, the empty-slot stand-in), with
no CoUI component behind it. Every guard that reads the default names output
asks a question about components — is there a `*_style.dart` for it, does it
compose what the widget composes, are its slots swappable, are its fields read —
and a fixture has no answer to any of them. So fixtures are left out of that
list and held by their own rule (`--fixture-faults`): a name starting with `.`
declares `fixture`, a `fixture` sits on a `.` name, carries a description, and
names a selftest that exists. That last check is the fixture's comparison — the
record fidelity would otherwise compare it against does not exist.

Usage: python3 scripts/guards/structure/figma_registry_names.py [--files]
       (default prints names; `--files` prints the covered file paths;
        `--unresolved-slugs` prints entries whose data slug names nothing;
        `--fragment-scope-drift` prints fragments whose builder reads a parent
        field their `dataFields` does not declare;
        `--fixtures` prints the builder fixtures' names;
        `--fixture-faults` prints builder fixtures that break their rule)
"""

# Annotations are strings until asked for — `str | None` is 3.10 syntax and the
# CI runner is a self-hosted Mac whose `python3` is Apple's 3.9. Evaluated at
# import, that union raised on the runner and took the two guards that shell
# out to this file down with it.
from __future__ import annotations

import json
import os
import re
import sys

PLUGIN = 'tools/figma-token-sync'
REGISTRY = f'{PLUGIN}/src/registry.ts'
COMPONENTS = f'{PLUGIN}/src/data/components.json'
SELFTESTS = f'{PLUGIN}/scripts'

# `section` and `name` inside one object literal. Anything but a brace may sit
# between them, which covers newlines, `build:`, and a trailing `needs:`.
ENTRY = re.compile(
    r"""section:\s*['"][^'"]+['"]\s*,[^{}]*?name:\s*['"]([^'"]+)['"]""",
    re.S,
)

IMPORT = re.compile(
    r"""import\s*\{([^}]*)\}\s*from\s*['"]\./components/([\w-]+)['"]""",
    re.S,
)


def registry_expression(src: str) -> str:
    """The text of the REGISTRY initializer, found by paren depth.

    A non-greedy match up to the first `;` looked equivalent and was not: a
    prose comment inside the `concat(...)` call ("…curated order; build order
    is decided by…") ended the capture early, so the four arrays after that
    semicolon fell out of the expression and this guard declared 41 registered
    components — and `Icon` — uncovered. Depth counting cannot be fooled by
    punctuation in a comment.
    """
    start = src.index('export const REGISTRY')
    eq = src.index('=', start)
    depth = 0
    for i in range(eq, len(src)):
        ch = src[i]
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
            if depth == 0:
                return src[eq + 1:i]
        elif ch == ';' and depth == 0:
            return src[eq + 1:i]
    return src[eq + 1:]


def covered_files() -> list[str]:
    src = open(REGISTRY, encoding='utf-8').read()
    # The REGISTRY expression's own text — so an array that is imported but
    # never concatenated (an easy half-wiring) is not counted either. Comments
    # are stripped first: a comment naming an array must not make it count.
    expr = registry_expression(src)
    expr = re.sub(r'//[^\n]*', '', expr)
    expr = re.sub(r'/\*.*?\*/', '', expr, flags=re.S)
    used = set(re.findall(r'\b([A-Z][A-Z0-9_]+)\b', expr))
    out = []
    for m in IMPORT.finditer(src):
        names = {n.strip() for n in m.group(1).replace('\n', ' ').split(',') if n.strip()}
        if not (names & used):
            continue
        path = f'{PLUGIN}/src/components/{m.group(2)}.ts'
        if os.path.exists(path):
            out.append(path)
    return sorted(out)


def slug_of_name(name: str) -> str:
    """The plugin's own fallback — `entry.dataSlug ?? slugOfName(entry.name)`."""
    return re.sub(r'(?!^)([A-Z])', r'_\1', name).lower()


def balanced(src: str, open_at: int, pair: str = '{}') -> int:
    """Index of the bracket closing the one at `open_at`."""
    depth = 0
    for j in range(open_at, len(src)):
        if src[j] == pair[0]:
            depth += 1
        elif src[j] == pair[1]:
            depth -= 1
            if depth == 0:
                return j
    return len(src) - 1


def entry_objects(files: list[str]) -> list[dict]:
    """Every REGISTRY entry as `{name, slug, fields, build, path, src}`.

    Brace-balanced rather than regex-shaped: an entry may carry a nested
    `sizing: { … }` between its `name:` and its `dataSlug:`, and a pattern that
    forbids braces between the two reads such an entry as having no slug — the
    exact false negative the slug mode exists to catch.
    """
    out: list[dict] = []
    for path in files:
        src = open(path, encoding='utf-8').read()
        for arr in re.finditer(r':\s*RegistryEntry\[\]\s*=\s*\[', src):
            i = arr.end() - 1
            body = src[i + 1:balanced(src, i, '[]')]
            k = 0
            while k < len(body):
                if body[k] != '{':
                    k += 1
                    continue
                m = balanced(body, k)
                obj = body[k:m + 1]
                nm = re.search(r"""name:\s*['"]([^'"]+)['"]""", obj)
                bd = re.search(r'build:\s*([A-Za-z0-9_]+)', obj)
                if nm and bd:
                    ds = re.search(r"""dataSlug:\s*['"]([^'"]+)['"]""", obj)
                    df = re.search(r'dataFields:\s*\[([^\]]*)\]', obj)
                    fx = re.search(r'\bfixture:\s*\{', obj)
                    fixture = None
                    if fx:
                        body_fx = obj[fx.end() - 1:balanced(obj, fx.end() - 1) + 1]
                        cb = re.search(r"""checkedBy:\s*['"]([^'"]+)['"]""", body_fx)
                        desc = ''.join(
                            re.findall(
                                r"""['"]([^'"]*)['"]""",
                                (re.search(r'description:(.*?)(?:,\s*checkedBy:|$)', body_fx, re.S) or [None, ''])[1],
                            )
                        )
                        dfm = re.search(r'dataFrom:\s*\[([^\]]*)\]', body_fx)
                        fixture = {
                            'checked_by': cb.group(1) if cb else None,
                            'description': desc,
                            'has_data': bool(ds or df),
                            'data_from': re.findall(r"""['"]([^'"]+)['"]""", dfm.group(1)) if dfm else [],
                        }
                    out.append({
                        'name': nm.group(1),
                        'slug': ds.group(1) if ds else slug_of_name(nm.group(1)),
                        'fields': re.findall(r"""['"]([^'"]+)['"]""", df.group(1)) if df else None,
                        'build': bd.group(1),
                        'path': path,
                        'src': src,
                        'fixture': fixture,
                    })
                k = m + 1
    return out


def fixture_faults(files: list[str]) -> list[tuple[str, str]]:
    """Builder fixtures that break their rule — see the module docstring."""
    selftests = ''
    if os.path.isdir(SELFTESTS):
        for f in sorted(os.listdir(SELFTESTS)):
            if f.startswith('selftest-'):
                selftests += open(os.path.join(SELFTESTS, f), encoding='utf-8').read()
    faults: list[tuple[str, str]] = []
    for e in entry_objects(files):
        fx = e['fixture']
        dotted = e['name'].startswith('.')
        if dotted and fx is None:
            faults.append((e['name'], 'a `.` name is a builder fixture — declare `fixture: { description, checkedBy }`'))
            continue
        if fx is None:
            continue
        if not dotted:
            faults.append((e['name'], '`fixture` on a published name — a fixture is named with a leading `.`'))
        if len(fx['description'].strip()) < 20:
            faults.append((e['name'], '`fixture.description` is empty or too short — it is what the set says in the panel'))
        if fx['has_data']:
            faults.append((e['name'], 'a fixture has no record — drop `dataSlug` / `dataFields`'))
        # A typo here hashes as `null` forever: the set would never notice the
        # record it draws from move.
        known = set(json.load(open(COMPONENTS, encoding='utf-8'))['components']) if os.path.isfile(COMPONENTS) else set()
        for slug in fx['data_from']:
            if slug not in known:
                faults.append((e['name'], f'`fixture.dataFrom` names "{slug}", which is not a record in components.json'))
        if not fx['checked_by']:
            faults.append((e['name'], '`fixture.checkedBy` is missing — name the selftest that asserts what it draws'))
        elif fx['checked_by'] not in selftests:
            faults.append((e['name'], f"`fixture.checkedBy` names \"{fx['checked_by']}\", which no selftest under {SELFTESTS} mentions"))
    return faults


def builder_body(src: str, fn: str) -> str | None:
    m = re.search(rf'function\s+{fn}\s*\(', src) or re.search(rf'const\s+{fn}\s*=', src)
    if not m:
        return None
    i = src.find('{', m.end())
    return None if i < 0 else src[i:balanced(src, i) + 1]


def fragment_scope_drift(files: list[str], components: dict) -> list[tuple[str, str]]:
    """Fragments whose builder reads a parent field outside its `dataFields`.

    Reads are collected through the aliases the builder binds to the parent's
    data — `const f = COMMAND.fields` (hop 0) and `const sz = sizeRows.get(…)`
    where `sizeRows` was itself bound from the parent (hop 1) — and kept only
    when the name is a field the parent actually states. A read outside the
    declared scope is a value `scopeToFragment` strips before the checks run,
    so the builder paints it and nothing compares it.
    """
    drift: list[tuple[str, str]] = []
    for e in entry_objects(files):
        if e['fields'] is None:
            continue
        parent = components.get(e['slug'])
        if parent is None:
            continue  # `--unresolved-slugs` owns that finding
        keys = set(parent.get('fields', {}))
        for bucket in ('sizes', 'variants'):
            for rows in (parent.get(bucket) or {}).values():
                for rec in (rows or {}).values():
                    keys |= set(rec or {})
        prefixes = [f[:-1] for f in e['fields'] if f.endswith('*')]
        declared = {f for f in e['fields'] if not f.endswith('*')}
        declared |= {k for k in keys if any(k.startswith(p) for p in prefixes)}
        body = builder_body(e['src'], e['build'])
        if body is None:
            drift.append((e['name'], f"builder `{e['build']}` not found — cannot verify dataFields"))
            continue
        aliases = set(re.findall(r'const\s+(\w+)\s*=\s*[A-Z][A-Z0-9_]*\.(?:fields|sizes|variants)\b', body))
        aliases |= set(re.findall(r'const\s+(\w+)\s*=\s*new Map\(Object\.entries\([A-Z][A-Z0-9_]*\.', body))
        hop1 = set()
        for a in list(aliases):
            hop1 |= set(re.findall(rf'const\s+(\w+)\s*=\s*{a}\.get\(', body))
            hop1 |= set(re.findall(rf'const\s+(\w+)\s*=\s*{a}\[', body))
        reads: set[str] = set()
        for a in aliases | hop1:
            reads |= set(re.findall(rf'\b{a}\.([A-Za-z0-9]+)', body))
        undeclared = sorted((reads & keys) - declared)
        if undeclared:
            drift.append((e['name'], 'reads but does not declare: ' + ', '.join(undeclared)))
    return drift


def main() -> int:
    files = covered_files()
    if not files:
        print(
            'FAIL: no builder file resolves into the REGISTRY expression — '
            "registry.ts's shape changed, fix this extractor before trusting "
            'any result.',
            file=sys.stderr,
        )
        return 1
    if '--unresolved-slugs' in sys.argv or '--fragment-scope-drift' in sys.argv:

        components = json.load(open(COMPONENTS, encoding='utf-8'))['components']
        if len(components) < 100:
            print(
                f'FAIL: components.json yielded only {len(components)} component '
                'keys — the export shape changed; fix this extractor before '
                'trusting any result.',
                file=sys.stderr,
            )
            return 1
        if '--unresolved-slugs' in sys.argv:
            for e in sorted(entry_objects(files), key=lambda e: e['name']):
                # A fixture has no record by definition — `--fixture-faults`
                # holds it instead.
                if e['fixture'] is not None:
                    continue
                if e['slug'] not in components:
                    print(f"{e['name']}\t{e['slug']}\t{e['path']}")
        else:
            for name, why in fragment_scope_drift(files, components):
                print(f'{name}\t{why}')
        return 0
    if '--files' in sys.argv:
        for f in files:
            print(f)
        return 0
    if '--fixtures' in sys.argv:
        for e in sorted(entry_objects(files), key=lambda e: e['name']):
            if e['fixture'] is not None:
                print(e['name'])
        return 0
    if '--fixture-faults' in sys.argv:
        for name, why in fixture_faults(files):
            print(f'{name}\t{why}')
        return 0
    names = set()
    for path in files:
        with open(path, encoding='utf-8') as fh:
            for m in ENTRY.finditer(fh.read()):
                names.add(m.group(1))
    # Builder fixtures are not components — see the module docstring.
    names -= {e['name'] for e in entry_objects(files) if e['fixture'] is not None}
    for n in sorted(names):
        print(n)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
