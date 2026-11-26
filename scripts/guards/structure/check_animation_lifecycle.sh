#!/usr/bin/env bash
#
# Every `CurvedAnimation` a component builds has an owner that disposes it.
#
# A `CurvedAnimation` registers a status listener on its parent. One that is
# never disposed pins itself to the controller or route animation it was
# built on — for as long as that parent lives, and on a route that is the
# whole app session. `CurveTween` (an `Animatable`) has no such listener and
# nothing to dispose, which is why it is the answer wherever the curve has no
# reverse direction.
#
# Two shapes kept producing the leak, and a "does this file dispose
# something" check misses both:
#
#   1. Rebuilt outside `initState` — in `didChangeDependencies`, in `build`,
#      in a helper called from either — without disposing the one it
#      replaces. Every theme change or rebuild strands one more. A component
#      shipped this way for months: its `dispose()` released the controller,
#      so the file looked tidy.
#   2. Built in a top-level function. A free function has no state, so the
#      curve it builds has no owner that could ever release it. A dialog's
#      transition builder did this on every frame of every open.
#
# What this checks, per construction in `packages/coui_flutter/lib`:
#   * not inside a top-level function                            (shape 2)
#   * stored — `target = CurvedAnimation(` or `target ??= …`; a curve passed
#     straight into an argument or `return`ed has no field to dispose it
#   * the file disposes that target (`target.dispose()` / `target?.dispose()`)
#   * a plain `=` outside `initState` disposes the target earlier in the
#     same method — a reassignment that does not is shape 1
#
# What it does not see: whether the parent outlives the owner, or a leak
# that goes through an alias. The leak-tracked widget test
# (`test/components/animation_lifecycle_leak_test.dart`) measures actual
# allocations; the two do not replace each other.
#
# Ratchet, not a bar. Existing sites are counted; net-new ones are not
# allowed. Lower the baseline when you fix one — never raise it.
set -uo pipefail

_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/ratchet.sh
. "$_GUARD_DIR/../lib/ratchet.sh"

cd "$(dirname "$0")/../../.." || exit 1

BASELINE=$(ratchet_int "$_GUARD_DIR/animation_lifecycle_baseline.txt") || exit 1
ROOT="${COUI_ANIMATION_LIFECYCLE_ROOT:-packages/coui_flutter/lib}"

python3 - "$BASELINE" "$ROOT" <<'PY'
import os, re, sys

BASELINE = int(sys.argv[1])
ROOT = sys.argv[2]

CONSTRUCT = re.compile(r'\bCurvedAnimation\s*\(')
TYPE_DECL = re.compile(r'\b(class|mixin|extension|enum)\b')


def without_comments(text):
    """Blanks comments and string contents, keeping every byte position."""
    out = list(text)
    at, size = 0, len(text)
    while at < size:
        if text.startswith('//', at):
            end = text.find('\n', at)
            end = size if end < 0 else end
            for k in range(at, end):
                out[k] = ' '
            at = end
        elif text.startswith('/*', at):
            end = text.find('*/', at + 2)
            end = size if end < 0 else end + 2
            for k in range(at, end):
                if out[k] != '\n':
                    out[k] = ' '
            at = end
        elif text[at] in '"\'':
            quote, at = text[at], at + 1
            while at < size and text[at] != quote:
                if text[at] != '\n':
                    out[at] = ' '
                at += 2 if text[at] == '\\' else 1
            at += 1
        else:
            at += 1
    return ''.join(out)


def blocks(source):
    """Every `{…}` block as (open, close, header) — header is the text
    between the previous `;`/`{`/`}` and the brace, i.e. what declares it."""
    found, stack = [], []
    for at, ch in enumerate(source):
        if ch == '{':
            stack.append(at)
        elif ch == '}' and stack:
            start = stack.pop()
            head_from = max(source.rfind(';', 0, start),
                            source.rfind('{', 0, start),
                            source.rfind('}', 0, start)) + 1
            found.append((start, at, source[head_from:start]))
    return found


def enclosing(all_blocks, pos):
    """Blocks containing pos, outermost first."""
    return sorted((b for b in all_blocks if b[0] < pos < b[1]),
                  key=lambda b: b[0])


def method_of(chain):
    """Innermost block that is a function body: header ends in `)`
    (optionally `async`) and is not a control statement."""
    for start, end, head in reversed(chain):
        h = head.strip()
        h = re.sub(r'\s+(async|sync)\*?$', '', h)
        if not h.endswith(')'):
            continue
        name = re.search(r'([A-Za-z_]\w*)\s*(<[^()]*>)?\s*\(', h)
        if not name or name.group(1) in ('if', 'for', 'while', 'switch',
                                         'catch', 'on'):
            continue
        return start, end, name.group(1)
    return None


offenders = []
scanned_files = 0
constructions = 0
for dirpath, _, files in os.walk(ROOT):
    for name in sorted(files):
        if not name.endswith('.dart'):
            continue
        path = os.path.join(dirpath, name)
        source = without_comments(open(path).read())
        scanned_files += 1
        all_blocks = blocks(source)
        for match in CONSTRUCT.finditer(source):
            constructions += 1
            pos = match.start()
            line = source[:pos].count('\n') + 1
            where = f'{path}:{line}'
            chain = enclosing(all_blocks, pos)
            in_type = any(TYPE_DECL.search(head) for _, _, head in chain)
            if not in_type:
                offenders.append(f'{where}  built in a top-level function — '
                                 'no owner can dispose it')
                continue

            before = source[:pos].rstrip()
            target = re.search(r'([A-Za-z_]\w*)\s*(\?\?=|=)$', before)
            if not target or before.endswith('=='):
                offenders.append(f'{where}  not stored — passed or returned '
                                 'straight away, nothing holds it to dispose')
                continue
            ident, op = target.group(1), target.group(2)

            disposes = re.compile(r'\b' + re.escape(ident) +
                                  r'\s*[?!]?\s*\.\s*dispose\s*\(\s*\)')
            if not disposes.search(source):
                offenders.append(f'{where}  `{ident}` is never disposed')
                continue

            method = method_of(chain)
            if method is None or op == '??=':
                continue  # field initializer, or created once
            m_start, _, m_name = method
            if m_name == 'initState':
                continue
            if not disposes.search(source, m_start, pos):
                offenders.append(f'{where}  `{ident}` reassigned in '
                                 f'`{m_name}` without disposing the one it '
                                 'replaces')

if scanned_files == 0 or constructions == 0:
    print(f'FAIL: scanned {scanned_files} files, {constructions} '
          'CurvedAnimation constructions under ' + ROOT)
    print('      Zero is not a clean result here — the kit builds these in')
    print('      several places, so zero means the scan stopped seeing them.')
    sys.exit(1)

count = len(offenders)
print(f'unowned CurvedAnimation constructions: {count} (baseline {BASELINE}; '
      f'{constructions} scanned in {scanned_files} files)')
for entry in sorted(offenders):
    print(f'  {entry}')

if count > BASELINE:
    print()
    print('FAIL: a CurvedAnimation with no owner to dispose it. If the curve')
    print('      has no reverse direction, drive a CurveTween instead —')
    print('      `parent.drive(Tween(...).chain(CurveTween(curve: ...)))` —')
    print('      which has nothing to dispose. Otherwise store it on the State')
    print('      or route and dispose it there (and before replacing it).')
    sys.exit(1)

if count < BASELINE:
    print()
    print(f'NOTE: down to {count} — lower animation_lifecycle_baseline.txt to '
          f'{count}.')

sys.exit(0)
PY
