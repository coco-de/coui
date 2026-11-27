#!/usr/bin/env python3
"""작업 공간(git worktree)들이 main 과 얼마나 어긋났는지 한 번에 본다.

왜: 여러 세션이 각자 작업 공간에서 일하면, 어느 세션이 옛 main 위에서 일하는지,
머지가 끝났는데 남은 작업 공간이 무엇인지, 열린 PR 끼리 같은 파일을 만지는지가
화면 어디에도 모이지 않는다. 그 셋은 PR 을 올리거나 머지할 때 충돌로 처음
드러나는데, 그때는 이미 작업이 끝난 뒤다.

사용:
  worktree_sync_status.py            표 + 알림 목록 (읽기만 한다)
  worktree_sync_status.py --report   알림 목록만, 세션에 보낼 문장으로
  worktree_sync_status.py --check    새 알림이 있으면 0, 없으면 1 (Orca precheck 용)
  worktree_sync_status.py --mark     지금 알림 집합을 '보냄' 으로 기록한다

알림은 집합이 바뀔 때만 다시 나간다 — 같은 알림을 15분마다 되풀이하면 아무도 안 읽는다.
뒤처진 커밋 수는 알림의 정체성에 넣지 않는다(커밋 하나마다 새 알림이 되므로).

이 스크립트는 아무것도 고치지 않는다: rebase · 삭제 · 커밋은 그 작업 공간의 세션이 한다.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

BEHIND_THRESHOLD = int(os.environ.get('COUI_SYNC_BEHIND', '20'))
STATE = Path(os.environ.get('XDG_CACHE_HOME', str(Path.home() / '.cache'))) / 'coui-worktree-sync' / 'last-notified.json'
# 릴리스 PR 은 CHANGELOG · pubspec 만 만지고 모든 PR 과 겹쳐 보이므로 겹침 판정에서 뺀다.
RELEASE_TITLE_PREFIX = 'chore: release'


def run(args: list[str], cwd: str | None = None, check: bool = True) -> str:
    r = subprocess.run(args, cwd=cwd, capture_output=True, text=True)
    if check and r.returncode != 0:
        raise RuntimeError(f'{" ".join(args)} → {r.returncode}: {r.stderr.strip()[:300]}')
    return r.stdout


def gh() -> str:
    return shutil.which('gh') or '/opt/homebrew/bin/gh'


def repo_root() -> str:
    here = Path(__file__).resolve().parent
    common = run(['git', 'rev-parse', '--path-format=absolute', '--git-common-dir'], cwd=str(here)).strip()
    # 공용 .git 의 부모가 main 체크아웃이다 — 워크트리 안에서 실행해도 같은 답.
    return str(Path(common).resolve().parent)


def worktrees(root: str) -> list[dict]:
    out, cur = [], {}
    for line in run(['git', 'worktree', 'list', '--porcelain'], cwd=root).splitlines():
        if line.startswith('worktree '):
            if cur:
                out.append(cur)
            cur = {'path': line[len('worktree '):], 'branch': None}
        elif line.startswith('branch '):
            cur['branch'] = line[len('branch refs/heads/'):]
        elif line == 'detached':
            cur['branch'] = None
        elif line.startswith('prunable'):
            cur['prunable'] = True
    if cur:
        out.append(cur)
    return out


def pr_index(root: str) -> dict[str, dict]:
    rows = json.loads(run([gh(), 'pr', 'list', '--state', 'all', '--limit', '300',
                           '--json', 'number,state,headRefName,title'], cwd=root))
    idx: dict[str, dict] = {}
    for r in rows:  # 최신순 — 같은 브랜치면 열린 PR 을 우선한다
        cur = idx.get(r['headRefName'])
        if cur is None or (cur['state'] != 'OPEN' and r['state'] == 'OPEN'):
            idx[r['headRefName']] = r
    return idx


def describe(root: str, wt: dict, prs: dict[str, dict]) -> dict:
    p = wt['path']
    d = dict(wt)
    if not Path(p).is_dir():
        d['missing'] = True
        return d
    count = lambda rng: int(run(['git', 'rev-list', '--count', rng], cwd=p, check=False).strip() or 0)
    d['behind'] = count('HEAD..origin/main')
    d['ahead'] = count('origin/main..HEAD')
    d['dirty'] = sum(1 for l in run(['git', 'status', '--porcelain'], cwd=p, check=False).splitlines() if not l.startswith('??'))
    d['last'] = run(['git', 'log', '-1', '--format=%cd', '--date=format:%m-%d %H:%M'], cwd=p, check=False).strip()
    # 원격 이름이 로컬 브랜치와 다를 수 있다(push 대상만 다른 경우) — 추적 브랜치를 먼저 본다.
    up = run(['git', 'rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}'], cwd=p, check=False).strip()
    names = [n for n in (up.split('/', 1)[1] if up.startswith('origin/') else None, wt.get('branch')) if n]
    d['pr'] = next((prs[n] for n in names if n in prs), None)
    d['role'] = 'main' if Path(p).resolve() == Path(root).resolve() else ('bundle' if p.rstrip('/').endswith(('coui-bundle', 'coui-public-bundle')) else 'work')
    return d


def is_generated(path: str) -> bool:
    # 생성기가 쓰는 파일 — 충돌은 손으로 풀지 않고 다시 생성해서 푼다.
    return path.endswith(('components.json', '_chain_permutations.dart', '.g.dart', '.freezed.dart', 'code.js'))


def overlaps(root: str) -> list[dict]:
    rows = json.loads(run([gh(), 'pr', 'list', '--state', 'open', '--limit', '100',
                           '--json', 'number,title,headRefName,files'], cwd=root))
    rows = [r for r in rows if not r['title'].startswith(RELEASE_TITLE_PREFIX)]
    files = {r['number']: {f['path'] for f in (r.get('files') or [])} for r in rows}
    out = []
    for i, a in enumerate(rows):
        for b in rows[i + 1:]:
            shared = sorted(files[a['number']] & files[b['number']])
            if shared:
                out.append({'a': a, 'b': b, 'shared': shared})
    return out


def alerts(root: str) -> tuple[list[dict], list[dict]]:
    prs = pr_index(root)
    rows = [describe(root, w, prs) for w in worktrees(root)]
    found = []
    for d in rows:
        if d.get('missing'):
            found.append({'key': f'missing:{d["path"]}', 'kind': '기록만 남음',
                          'text': f'{d["path"]} — 폴더가 없다. `git worktree prune` 으로 기록을 지운다.'})
            continue
        if d['role'] != 'work':
            continue
        pr = d['pr']
        label = d.get('branch') or '(detached)'
        if pr and pr['state'] == 'MERGED':
            found.append({'key': f'merged:{d["path"]}', 'kind': '정리 후보',
                          'text': f'{d["path"]} [{label}] — PR #{pr["number"]} 이 머지됐다(미저장 {d["dirty"]}). '
                                  '이어서 쓰지 말고 다음 일은 origin/main 에서 새 브랜치로, 이 작업 공간은 정리.'})
            continue
        live = (pr and pr['state'] == 'OPEN') or (not pr and (d['ahead'] > 0 or d['dirty'] > 0))
        if live and d['behind'] >= BEHIND_THRESHOLD:
            ref = f'PR #{pr["number"]}' if pr else 'PR 없음'
            found.append({'key': f'stale:{d["path"]}', 'kind': '뒤처짐',
                          'text': f'{d["path"]} [{label}, {ref}] — main 보다 {d["behind"]}커밋 뒤처짐(앞섬 {d["ahead"]}, 미저장 {d["dirty"]}). '
                                  '`git fetch && git rebase origin/main` 으로 맞춘다'
                                  + (' — 미저장 변경은 먼저 커밋하거나 따로 둔다.' if d['dirty'] else '.')})
    for o in overlaps(root):
        a, b = o['a'], o['b']
        files = ', '.join(o['shared'][:5]) + (f' 외 {len(o["shared"]) - 5}' if len(o['shared']) > 5 else '')
        found.append({'key': f'overlap:{min(a["number"], b["number"])}-{max(a["number"], b["number"])}', 'kind': '같은 파일',
                      'text': f'PR #{a["number"]} ({a["headRefName"]}) 와 #{b["number"]} ({b["headRefName"]}) 가 같은 파일을 만진다: {files}. '
                              '먼저 머지되는 쪽 뒤에 다른 쪽이 rebase 하고, 같은 일을 하고 있지 않은지 본다'
                              + ('. 생성물은 손으로 합치지 말고 rebase 뒤 다시 생성한다.' if any(is_generated(f) for f in o['shared']) else '.')})
    return found, rows


def load_state() -> list[str]:
    try:
        return json.loads(STATE.read_text())['keys']
    except Exception:
        return []


def table(rows: list[dict]) -> str:
    lines = [f'{"WORKTREE":58} {"BRANCH":40} {"BEHIND":>6} {"AHEAD":>5} {"DIRTY":>5} {"LAST":11} PR']
    home = str(Path.home())
    for d in rows:
        path = d['path'].replace(home, '~')
        if d.get('missing'):
            lines.append(f'{path:58} (폴더 없음)')
            continue
        pr = d['pr']
        prs = f'#{pr["number"]} {pr["state"]}' if pr else '-'
        lines.append(f'{path:58} {(d.get("branch") or "(detached)")[:40]:40} {d["behind"]:>6} {d["ahead"]:>5} {d["dirty"]:>5} {d["last"]:11} {prs}')
    return '\n'.join(lines)


def main() -> int:
    mode = sys.argv[1] if len(sys.argv) > 1 else ''
    root = repo_root()
    run(['git', 'fetch', '--quiet', 'origin'], cwd=root, check=False)
    found, rows = alerts(root)
    keys = sorted(a['key'] for a in found)
    sent = load_state()
    if mode == '--check':
        new = sorted(set(keys) - set(sent))
        print(f'알림 {len(keys)}개, 새 알림 {len(new)}개')
        return 0 if new else 1
    if mode == '--mark':
        STATE.parent.mkdir(parents=True, exist_ok=True)
        STATE.write_text(json.dumps({'keys': keys}, ensure_ascii=False))
        print(f'기록: 알림 {len(keys)}개')
        return 0
    if mode not in ('', '--report'):
        print(__doc__)
        return 2
    if mode == '':
        print(table(rows))
        print()
    if not found:
        print('알림 없음')
        return 0
    print(f'세션 동기화 알림 {len(found)}개 (기준: main 보다 {BEHIND_THRESHOLD}커밋 이상 뒤처짐 · 머지 끝난 작업 공간 · 같은 파일을 만지는 열린 PR)')
    for a in found:
        mark = '' if a['key'] in sent else ' (새)'
        print(f'- [{a["kind"]}]{mark} {a["text"]}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
