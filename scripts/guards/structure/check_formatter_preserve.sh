#!/usr/bin/env bash
#
# `dart format` 의 설정은 옵션 파일에서 오고, 그 값이 이 리포 밖에서 바뀔 수
# 있으면 포맷은 의존성 범프 하나로 통째로 갈린다.
#
# 실제 형태: `very_good_analysis` 는 10.x 까지 `trailing_commas: preserve`
# 였고 11.0.0 에서 `automate` 로 뒤집었다. 그 기본값을 상속만 하고 있던
# 옵션 파일은 VGA 를 올리는 순간 `dart format` 이 trailing comma 를 지우며
# 줄을 접기 시작한다 — 코드 변경 0 인 PR 에서 수천 파일이 재포맷되고,
# 리뷰는 그 안에서 실제 변경을 못 본다.
#
# 그래서 불변식은 "preserve 인가" 가 아니라 **"그 값이 이 리포 안에서
# 읽히는가"** 다. `package:` include 뒤에 숨은 값은 이 가드가 못 보고,
# 못 보는 값은 다음에 누가 뒤집어도 아무 신호를 내지 않는다.
#
# 이 가드가 보지 못하는 것: 파일이 실제로 그 설정대로 포맷돼 있는지.
# 그건 CI 의 `dart format --set-exit-if-changed` 가 본다. 둘은 서로를
# 대신하지 못한다 — 설정이 옳아도 파일이 드리프트할 수 있고, 파일이
# 깨끗해도 설정이 다음 범프에 뒤집힐 수 있다.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$REPO_ROOT"

python3 - <<'PY'
import os
import re
import sys

SKIP_DIRS = {'.git', '.dart_tool', 'build', 'node_modules', '.fvm'}

def option_files():
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        if 'analysis_options.yaml' in files:
            yield os.path.normpath(os.path.join(root, 'analysis_options.yaml'))

def includes_of(text):
    """`include:` as a scalar or as a list, in declaration order."""
    m = re.search(r'^include:[ \t]*(.*)$', text, re.M)
    if not m:
        return []
    inline = m.group(1).strip()
    if inline:
        return [inline]
    out = []
    start = text.index(m.group(0)) + len(m.group(0))
    for line in text[start:].splitlines():
        if not line.strip():
            continue
        entry = re.match(r'^[ \t]+-[ \t]*(\S+)[ \t]*$', line)
        if not entry:
            break
        out.append(entry.group(1))
    return out

def own_trailing_commas(text):
    block = re.search(r'^formatter:[ \t]*$((?:\n[ \t]+.*|\n[ \t]*)*)', text, re.M)
    if not block:
        return None
    v = re.search(r'^[ \t]+trailing_commas:[ \t]*(\S+)', block.group(1), re.M)
    return v.group(1) if v else None

def resolve(path, seen):
    """(value, origin) — or (None, reason) when it leaves the repo."""
    if path in seen:
        return None, 'include cycle'
    seen = seen | {path}
    try:
        text = open(path, encoding='utf-8').read()
    except OSError as exc:
        return None, 'unreadable (%s)' % exc
    own = own_trailing_commas(text)
    if own is not None:
        return own, path
    # Later includes win, so walk them from the back.
    for inc in reversed(includes_of(text)):
        if inc.startswith('package:'):
            return None, '`%s` — value lives outside the repo' % inc
        target = os.path.normpath(os.path.join(os.path.dirname(path), inc))
        value, origin = resolve(target, seen)
        if value is not None or 'outside the repo' in (origin or ''):
            return value, origin
    return None, 'no `formatter: trailing_commas:` anywhere in the include chain'

violations = 0
checked = 0
for path in sorted(option_files()):
    checked += 1
    value, origin = resolve(path, frozenset())
    if value == 'preserve':
        continue
    violations += 1
    print('✗ %s' % path)
    if value is None:
        print('    trailing_commas is not readable from this repo: %s' % origin)
        print('    Declare `formatter: { trailing_commas: preserve }` in this file,')
        print('    or include (relatively) one that does.')
    else:
        print('    trailing_commas resolves to `%s` (from %s), expected `preserve`.' % (value, origin))
    print()

if violations:
    print('formatter config: %d option file(s) do not resolve trailing_commas'
          ' to `preserve` inside this repo.' % violations)
    sys.exit(1)

print('✅ formatter config: %d option file(s) resolve trailing_commas to'
      ' `preserve` from an in-repo declaration.' % checked)
PY
