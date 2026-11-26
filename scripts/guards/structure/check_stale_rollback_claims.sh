#!/usr/bin/env bash
# 제거된 per-entry undo 를 "지금도 일어나는 일" 로 단정하는 문장 — hard 0.
#
# 사실: 플러그인은 예전에 엔트리마다 build 를 `figma.triggerUndo()` 트랜잭션으로
# 감쌌고, 그 설계는 제거됐다(`src/generate.ts` 의 "No `triggerUndo()` here.").
# 빌더가 throw 해도 되돌리지 않는다 — 그 엔트리가 실패로 보고되고, 그리다 만
# 컴포넌트가 완성처럼 보이는 채 캔버스에 남는다(다음에 그 이름이 mint 될 때
# `resetNode` 로 비워진다). 부재보다 나쁘다: 없는 것은 눈에 띄고 완성처럼
# 보이는 것은 아니다. 이 거짓은 실제로 뒤이은 작업의 초기 진단을 틀리게 했다.
#
# ── 왜 ratchet 이 아니라 hard 0 인가 (실측으로 갈아엎은 설계) ──
#
# 처음에는 어휘 총량 ratchet 이었다. 실측해 보니 못 쓸 물건이었다:
#   · `roll(s|ed) … back` 20 건이 **전부 부정문** — 즉 이 스윕이 만든 교정문이다.
#     총량을 세면 "올바르게 설명하는 문장" 을 추가할 때마다 가드가 막는다.
#     옳은 일에 마찰을 거는 게이트는 사람이 우회하게 되어 있다.
#   · `off the page` · `vanish` 의 비부정 매치는 전부 **무관한 뜻**이었다
#     ("read off the page", "the words vanished into the block").
#   · 한국어는 부정이 후치라 `롤백하지 않는다` 가 긍정으로 잡혔다.
#
# 그래서 어휘가 아니라 **단정의 형태**만 본다. 거짓 진술에만 나타나고 교정문에는
# 나타나지 않는 형태여야 하며, 부정(전치·후치 둘 다)이 붙으면 제외한다.
#
# ── 이 가드가 잡지 못하는 것 (알고 남긴다) ──
#
# 같은 거짓을 새로운 표현으로 쓰면 못 잡는다. 텍스트 가드의 한계이고, 여기서
# 총량 ratchet 으로 넓히면 위에 적은 이유로 더 나빠진다. 실제 방어선은 코퍼스
# 자체가 옳게 고쳐졌다는 것이고, 이 가드는 **가장 문자 그대로의 재도입**을 막는다.
# 넓히고 싶으면 어휘가 아니라 단정 형태를 추가해라.
#
# 줄바꿈 해제가 필요한 이유: 주석은 80칸에서 접히므로 구절이 줄을 걸친다.
# 실제로 "took ColorPicker and TimePicker off / the page" 가 줄 단위 스캔을
# 통과했다. 자기 자신은 스캔에서 제외한다 — 이 파일에 그 형태가 다 들어 있다.
set -uo pipefail

env RB_MODE="${1:-check}" python3 - <<'PY'
import io, os, re, sys

# 거짓 단정의 형태. 각 항목은 (이름, 정규식).
# 교정문("nothing rolls the entry back", "롤백되지 않는다")에는 나타나면 안 된다.
# 기계형 — 롤백이 무언가를 한다고 직접 말하므로 자기 문맥을 갖는다.
MECHANISM = [
    ('rollback-rolls-it-back',
     r'roll(?:s|ed)\s+(?:the\s+)?(?:whole\s+)?\w*\s*(?:entry|component|host)?\s*back'),
    ('per-entry-does-something',
     r'per-entry\s+(?:undo|rollback|transaction)\s+(?:rolls|turns|takes|swallow)'),
    ('ko-rollback-then',               r'롤백(?:한|하고|된|되고)'),
]

# 결과형 — "컴포넌트가 페이지에 없다". 이 말 자체는 롤백과 무관한 자리에서도
# 쓰인다(실측: "the vertical layout simply is not on the page" 는 variant
# orientation 얘기였다). 그래서 같은 블록에 throw/rollback 문맥이 있을 때만
# 센다. 거짓 진술은 항상 "빌더가 throw 하면 → X" 논증 안에 산다.
CONSEQUENCE = [
    ('component-never-appears',        r'(?:silently\s+)?never\s+appears'),
    ('component-simply-not-on-page',   r'simply\s+(?:is\s+)?not\s+on\s+the\s+page'),
    ('component-taken-off-page',       r'tak(?:es|en|ing)\s+(?:the\s+)?\w*\s*(?:component|entry|host)?\s*off\s+the\s+(?:page|canvas)'),
    ('ko-silently-absent',             r'조용히\s*안\s*생긴다'),
]

CONTEXT = re.compile(r'throw|rollback|roll(?:s|ed)?\s+back|per-entry|#?\b3738\b|롤백|트랜잭션', re.I)

ASSERTIONS = MECHANISM + CONSEQUENCE
CONSEQUENCE_NAMES = {n for n, _ in CONSEQUENCE}

# 부정. 영어는 전치, 한국어는 후치라 양쪽을 본다.
NEG_BEFORE = re.compile(r'(?:nothing|not|never|no longer|isn\'t|doesn\'t)\W+\w*\W*$', re.I)
NEG_AFTER  = re.compile(r'^\s*\w{0,6}(?:지\s*않|되지\s*않|하지\s*않)')

ROOTS = [('tools/figma-token-sync', ('.ts', '.md')), ('scripts/guards', ('.sh', '.py'))]
SELF = {'scripts/guards/structure/check_stale_rollback_claims.sh'}
COMMENT = re.compile(r'^\s*(?://+|#+|\*|///)\s?')


def blocks(path):
    """주석 마커를 떼고 연속 주석 줄을 이어붙인다 — 줄을 걸친 구절을 보기 위해."""
    buf, start = [], None
    for n, raw in enumerate(io.open(path, encoding='utf-8', errors='replace'), 1):
        line = raw.rstrip('\n')
        m = COMMENT.match(line)
        if m:
            if start is None:
                start = n
            buf.append(line[m.end():])
            continue
        if buf:
            yield start, ' '.join(buf)
            buf, start = [], None
        yield n, line
    if buf:
        yield start, ' '.join(buf)


hits = []
for root, exts in ROOTS:
    for dp, dn, fns in os.walk(root):
        dn[:] = [d for d in dn if d not in ('node_modules', '.git')]
        for fn in sorted(fns):
            if not fn.endswith(exts):
                continue
            p = os.path.join(dp, fn)
            if p in SELF:
                continue
            for ln, text in blocks(p):
                for name, pat in ASSERTIONS:
                    for m in re.finditer(pat, text, re.I):
                        before = text[max(0, m.start() - 40):m.start()]
                        after = text[m.end():m.end() + 12]
                        if NEG_BEFORE.search(before) or NEG_AFTER.match(after):
                            continue
                        # 결과형은 롤백 문맥 안에서만 거짓이다.
                        if name in CONSEQUENCE_NAMES and not CONTEXT.search(text):
                            continue
                        hits.append((p, ln, name,
                                     text[max(0, m.start() - 55):m.end() + 45].strip()))

if os.environ.get('RB_MODE') == '--list':
    for p, ln, name, t in hits:
        print(f'{p}:{ln}  [{name}]  …{t}…')
    sys.exit(0)

if hits:
    print(f'❌ 제거된 per-entry 롤백을 현재 동작으로 단정하는 문장 {len(hits)}건:')
    print()
    for p, ln, name, t in hits:
        print(f'   {p}:{ln}  [{name}]')
        print(f'      …{t}…')
    print()
    print('   per-entry undo 는 제거됐다 — src/generate.ts 의 "No `triggerUndo()` here."')
    print('   빌더가 throw 해도 되돌리지 않는다. 그 엔트리가 실패로 보고되고 그리다 만')
    print('   컴포넌트가 완성처럼 보이는 채 캔버스에 남는다 — 결과는 "페이지에 없다" 가')
    print('   아니라 "완성처럼 보이는 반제품이 있다" 다. 부재보다 나쁘다.')
    sys.exit(1)

print('✅ 제거된 per-entry 롤백을 현재 동작으로 단정하는 문장 0건 (하드 0).')
PY
