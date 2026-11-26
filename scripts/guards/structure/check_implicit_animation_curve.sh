#!/usr/bin/env bash
#
# Every implicit animation in a component states its curve.
#
# Flutter's implicitly-animated widgets default to `Curves.linear`. Their
# Web twins do not — the kit's CSS transitions are emitted with
# `CoreEasing.move`, which is ease-in-out. Same duration, different shape:
# the two panes start and finish together and disagree in between, and
# side by side that reads as one of them being broken.
#
# It is invisible on either platform alone, which is why it lasted: 52 of
# 76 implicit animations in the kit ran linear, and nothing failed.
#
# Ratchet, not a bar. Existing sites are counted; net-new ones are not
# allowed. Lower the baseline when you fix one — never raise it.
set -uo pipefail

# ratchet 기준값은 파일에 산다 — 이 스크립트 안의 상수가 아니다.
# 상수였을 때는 한 글자(`=0` → `=1`)가 위반 한 칸을 열었고, 그 한 글자가
# 통과 여부를 결정하는 **바로 그 PR 안에** 있었다. 파일이면 CODEOWNERS 의
# `/scripts/guards/**/*baseline*` 과 check_codeowners_ratchet_coverage.sh 가
# 그 diff 를 본다. 읽기 실패는 fail-closed 다 (lib/ratchet.sh 참조).
_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/ratchet.sh
. "$_GUARD_DIR/../lib/ratchet.sh"


cd "$(dirname "$0")/../../.." || exit 1

BASELINE=$(ratchet_int "$_GUARD_DIR/implicit_animation_curve_baseline.txt") || exit 1

python3 - "$BASELINE" <<'PY'
import os, re, sys

BASELINE = int(sys.argv[1])
ROOT = 'packages/coui_flutter/lib/src'

# The implicitly-animated widgets whose curve parameter defaults to linear.
# Not a closed list of everything Flutter ships — a closed list would be a
# second thing to keep in step. These are the ones this kit uses; a new one
# arrives with its own review.
WIDGETS = (
    'AnimatedContainer', 'AnimatedOpacity', 'AnimatedPadding',
    'AnimatedAlign', 'AnimatedPositioned', 'AnimatedPositionedDirectional',
    'AnimatedDefaultTextStyle', 'AnimatedScale', 'AnimatedRotation',
    'AnimatedSlide', 'AnimatedPhysicalModel', 'AnimatedFractionallySizedBox',
)
CALL = re.compile(r'\b(' + '|'.join(WIDGETS) + r')\s*\(')

def without_comments(text):
    """Blanks comments, keeping every byte position and line break.

    These files document their widget trees as ASCII diagrams inside doc
    comments, and those diagrams name the very widgets scanned for here.
    A first version counted them — 28 hits, over half of them prose — so
    editing a comment could fail this guard and fixing real code could
    leave it red.
    """
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
            # Step over string literals so an apostrophe in prose cannot
            # swallow the rest of the file.
            quote, at = text[at], at + 1
            while at < size and text[at] != quote:
                at += 2 if text[at] == '\\' else 1
            at += 1
        else:
            at += 1

    return ''.join(out)


offenders = []
for dirpath, _, files in os.walk(ROOT):
    for name in files:
        if not name.endswith('.dart'):
            continue
        path = os.path.join(dirpath, name)
        source = without_comments(open(path).read())
        for match in CALL.finditer(source):
            start = match.end()
            depth, at = 1, start
            while at < len(source) and depth:
                if source[at] == '(':
                    depth += 1
                elif source[at] == ')':
                    depth -= 1
                at += 1
            body = source[start:at]
            # Only this call's own arguments — a nested widget's `curve:`
            # says nothing about this one.
            #
            # Collapsed until nothing is left to collapse. One pass removes
            # the innermost level only, so a `curve:` two levels down
            # survived into what this then read as the outer call's own
            # arguments. Measured: deleting the surface's outer curve left
            # this guard reporting zero, because the inner animated box
            # still had one. A guard that cannot fail is not a guard.
            own = body
            while True:
                collapsed = re.sub(r'\([^()]*\)', '', own)
                if collapsed == own:
                    break
                own = collapsed
            if 'curve:' in own:
                continue
            line = source[:match.start()].count('\n') + 1
            offenders.append(f'{path}:{line}  {match.group(1)}')

count = len(offenders)
print(f'implicit animations with no stated curve: {count} (baseline {BASELINE})')
for entry in sorted(offenders):
    print(f'  {entry}')

if count > BASELINE:
    print()
    print('FAIL: a new implicit animation runs on Curves.linear while its')
    print('      Web twin eases. State the curve — `CoreEasing.move.toValue()`')
    print('      for chrome moving between states, which is what the Web side')
    print('      already names for the same element.')
    sys.exit(1)

if count < BASELINE:
    print()
    print(f'NOTE: down to {count} — lower BASELINE in this guard to {count}.')

sys.exit(0)
PY
