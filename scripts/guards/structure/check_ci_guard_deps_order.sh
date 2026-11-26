#!/usr/bin/env bash
# CI 스텝 순서 — 도구를 필요로 하는 가드가 그 도구 설치보다 먼저 돌지 않는가.
#
# 왜 이 가드가 있나. `check_figma_icon_names.sh` 의 freshness 블록과 icon-keys
# 동기 블록은 `tools/figma-token-sync/node_modules` 가 있어야 돌아간다. 그런데
# 그 가드는 잡 전체의 유일한 `npm ci` 보다 148줄 먼저 있었고, checkout 이
# untracked 를 지우므로 그 디렉터리는 존재한 적이 없다. 두 블록은 CI 에서
# **한 번도 돈 적이 없는데** 성공 줄은 둘 다 통과했다고 말했다.
#
# 이 실패 방식이 특히 나쁜 이유는 red 가 아니라 green 으로 나타난다는 것이다.
# 아무도 로그를 읽지 않고, 읽어도 "건너뜀" 한 줄은 통과처럼 보인다. 그래서
# 사람이 순서를 기억하는 것에 기대지 않고 여기서 강제한다 — 스텝을 재배치하는
# 다음 사람이 이 짝을 모른 채로 되돌릴 수 있기 때문이다.
#
# 판정은 "같은 잡 안에서 설치 스텝이 소비 스텝보다 앞서는가" 하나다. 잡이
# 다르면 node_modules 가 공유되지 않으므로 그것도 위반이다.
set -uo pipefail

readonly WORKFLOW=".github/workflows/ci.yaml"

if [ ! -f "$WORKFLOW" ]; then
  echo "❌ $WORKFLOW 없음"
  exit 1
fi

# pyyaml 없이 판정한다 — CI 파이썬에 서드파티가 깔려 있다는 보장이 없고,
# 여기서 필요한 것은 스텝 경계와 순서뿐이라 들여쓰기 스캔으로 충분하다.
env CI_WORKFLOW="$WORKFLOW" python3 - <<'PY'
import io, os, re, sys

path = os.environ['CI_WORKFLOW']
lines = io.open(path, encoding='utf-8').read().split('\n')

# (설치 토큰, 소비 토큰, 사람이 읽을 이름) — 짝이 늘면 여기 추가한다.
PAIRS = [
    ('npm ci', 'check_figma_icon_names.sh', 'figma 플러그인 node_modules'),
]

job = None
step = -1            # 잡 안에서의 스텝 순번
# where[(job, token)] = (첫 스텝 순번, 줄번호)
where = {}

for n, line in enumerate(lines, 1):
    if re.match(r'^  [A-Za-z0-9_-]+:\s*$', line):
        job, step = line.strip().rstrip(':'), -1
        continue
    if re.match(r'^      - ', line):
        step += 1
    if job is None or step < 0:
        continue
    # 주석은 세지 않는다. 이 잡의 주석 본문에 `npm ci` 가 이미 등장하므로,
    # 주석을 세면 실제 설치 스텝이 뒤로 밀려도 가드가 통과한다 — 가드가
    # 검사하려던 바로 그 실패를 가드 자신이 재현하는 꼴이다.
    body = line.split('#', 1)[0] if line.lstrip().startswith('#') else line
    if not body.strip():
        continue
    line = body
    for install, consume, _ in PAIRS:
        for tok in (install, consume):
            if tok in line and (job, tok) not in where:
                where[(job, tok)] = (step, n)

fail = 0
for install, consume, label in PAIRS:
    jobs_with_consumer = sorted({j for (j, t) in where if t == consume})
    if not jobs_with_consumer:
        print(f'❌ {consume} 를 부르는 스텝이 {path} 에 없다 — 가드가 배선에서 빠졌다.')
        fail = 1
        continue
    for j in jobs_with_consumer:
        c_step, c_line = where[(j, consume)]
        got = where.get((j, install))
        if got is None:
            print(f'❌ [{j}] {consume} (스텝 {c_step}, {path}:{c_line}) 가 도는데')
            print(f'   같은 잡에 `{install}` 이 없다 — {label} 가 설치되지 않는다.')
            print(f'   그 가드의 도구 의존 블록은 조용히 건너뛴다.')
            fail = 1
            continue
        i_step, i_line = got
        if i_step >= c_step:
            print(f'❌ [{j}] `{install}` 이 소비자보다 뒤에 있다 — {label}')
            print(f'   설치: 스텝 {i_step} ({path}:{i_line})')
            print(f'   소비: 스텝 {c_step} ({path}:{c_line})  ← {consume}')
            print()
            print('   checkout 이 untracked 를 지우므로 이 순서면 node_modules 가')
            print('   없고, 그 가드의 도구 의존 블록은 검사 없이 건너뛴다.')
            print('   설치 스텝을 소비 스텝 위로 올려라.')
            fail = 1
        else:
            print(f'   ○ [{j}] {label}: 설치 스텝 {i_step} < 소비 스텝 {c_step} ✓')

if fail:
    sys.exit(1)

print(f'✅ CI 도구 의존 스텝 순서 {len(PAIRS)}쌍 전부 설치가 소비보다 앞선다.')
PY
