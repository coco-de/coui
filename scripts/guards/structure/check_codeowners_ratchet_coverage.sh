#!/usr/bin/env bash
# ratchet 산출물이 전부 CODEOWNERS 에 걸리는지 센다.
#
# 왜 이 가드가 있나 — ratchet 은 "새 위반 net-new 0" 만 강제하고, baseline
# 자체를 늘리는 완화는 **그 완화를 담은 PR 이 스스로 통과시킨다**. 그래서
# `process/workflow.md` 가 완화를 오너에게 알리라고 한다. 그런데 그
# 요구는 글롭 두 개(`/scripts/guards/**/*baseline*`, `*allowlist*`)로만
# 표현돼 있었고, 다른 트리에 사는 ratchet 은 조용히 빠져나갔다 — 실제로
# 셋이 빠져 있었다.
#
# 문서에 적힌 대조는 강제가 아니다. 세는 것이 없으면 새로 추가된 ratchet 이
# 등록됐는지 아무도 모르고, 그 누락은 "아직 안 한 일" 과 구별되지 않는
# 형태로 쌓인다. 그래서 이 가드가 그 수를 CI 에서 센다.
#
# 후보는 **경로 전체**에서 키워드를 찾는다. basename 만 보면 키워드가
# 디렉터리에 있는 ratchet 을 통째로 놓친다 — `.lint-allowlist/` 가 정확히
# 그 모양이고, 실제로 첫 판이 그것을 놓친 채 "미등록 0" 을 보고했다.
# 세는 것이 틀리면 가드는 구멍을 닫았다고 증언만 하고 아무것도 막지 않는다.
#
# 이 가드가 보지 않는 것: 가드 스크립트 **안에** 인라인으로 박힌 ratchet
# 카운트(`BASELINE=0` 류). 그건 파일이 아니라 값이라 여기서 셀 수 없다.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

CODEOWNERS=".github/CODEOWNERS"
[ -f "$CODEOWNERS" ] || { echo "❌ $CODEOWNERS 없음"; exit 1; }

python3 - "$CODEOWNERS" <<'PY'
import re, subprocess, sys, fnmatch

codeowners = sys.argv[1]

# ── CODEOWNERS 줄 수집 (오너 없는 줄도 **버리지 않는다**) ──
#
# 오너 없는 줄은 빈 줄이 아니라 "이 경로는 오너를 두지 않는다" 는 선언이고,
# 뒤에 오면 앞의 소유를 해제한다. 그런 줄을 수집 단계에서 버리면 해제가
# 보이지 않는 채로 '덮임' 이 남는다 — 아래 covered() 가 그 방향으로 틀리는
# 것을 이 파일이 가장 경계한다.
rules = []  # [(pattern, has_owner)]
for line in open(codeowners, encoding="utf-8"):
    line = line.split("#", 1)[0].strip()
    if not line:
        continue
    parts = line.split()
    rules.append((parts[0], any(p.startswith("@") for p in parts[1:])))

def matches(pattern: str, path: str) -> bool:
    """이 파일이 실제로 쓰는 CODEOWNERS 글롭 형태만 판정한다.

    모르는 형태는 '안 맞음' 으로 답한다(fail-closed). fnmatch 로 대충
    맞춰보고 싶은 유혹이 있지만, fnmatch 의 `*` 는 `/` 를 건너뛰고
    CODEOWNERS 의 글롭은 건너뛰지 않는다 — 더 관대하게 맞으면 덮이지 않은
    파일을 덮였다고 답하게 되고, 그건 이 가드가 존재하는 이유와 정반대다.
    모르면 '안 맞음' 으로 세어 사람이 더 명시적인 패턴을 쓰게 만든다.
    """
    p = pattern[1:] if pattern.startswith("/") else pattern
    if p.endswith("/"):                          # 디렉터리 전체
        return path.startswith(p)
    if "**" in p:                                # /a/**/*baseline*
        head, tail = p.split("**", 1)
        tail = tail.lstrip("/")
        # fnmatchcase — 평범한 fnmatch 는 os.path.normcase 를 적용해서
        # Windows 러너에서만 대소문자를 무시한다. 그건 GitHub 보다 관대해지는
        # 쪽이고, 위 문단이 피하려는 방향 그대로다. 지금 CI 는 리눅스라 두
        # 함수가 같게 동작하지만, 같게 **동작하는 것**과 같게 **정의된 것**은
        # 다르다.
        return path.startswith(head) and fnmatch.fnmatchcase(
            path.rsplit("/", 1)[-1], tail
        )
    if not any(c in p for c in "*?["):
        # 와일드카드가 없는 형태는 정확히 그 경로 하나를 뜻한다.
        return path == p
    return False                                 # 그 밖의 형태(예: `/tool/*baseline*`)

def covered(path: str) -> bool:
    """마지막으로 매칭된 줄이 오너를 갖는가.

    GitHub 의 규칙은 last-match-wins 다 — 문서가 그렇게 못박는다("Order is
    important; the last matching pattern takes the most precedence"). 처음
    매칭에서 멈추면 뒤따르는 더 좁은 줄이 소유를 **해제**해도 이 가드는
    계속 '덮임' 이라 답한다. 그 상태는 CI 초록 + GitHub 리뷰 불요구이고,
    이 가드가 존재하는 이유와 정확히 반대다.
    """
    for pattern, has_owner in reversed(rules):
        if matches(pattern, path):
            return has_owner
    return False

# ── 후보: ratchet **데이터** 파일 ──
# 소스코드(.dart/.ts)는 로직이지 baseline 이 아니고, .github/workflows 는
# 워크플로 정의이지 ratchet 산출물이 아니다.
KEYWORDS = ("baseline", "allowlist", "waiver")
DATA_EXT = (".txt", ".json", ".yaml", ".yml")

tracked = subprocess.run(
    ["git", "ls-files"], capture_output=True, text=True, check=True
).stdout.splitlines()

candidates = []
for path in tracked:
    lowered = path.lower()
    base = lowered.rsplit("/", 1)[-1]
    # 키워드는 경로 어디에 있어도 센다 — basename 만 보면
    # `.lint-allowlist/gap-spacing-naming.txt` 류가 빠져나간다.
    if not any(k in lowered for k in KEYWORDS):
        continue
    if not base.endswith(DATA_EXT):
        continue
    if path.startswith(".github/workflows/"):
        continue
    if "node_modules/" in path:
        continue
    candidates.append(path)

uncovered = [p for p in sorted(candidates) if not covered(p)]

print(f"ratchet 산출물 후보 {len(candidates)}개 · CODEOWNERS 미등록 {len(uncovered)}개")
if uncovered:
    print()
    print(f"❌ {len(uncovered)}개가 CODEOWNERS 패턴에 걸리지 않는다:")
    # 목록을 통째로 쏟으면 CI 로그가 그것만으로 채워진다. 앞 20개로 충분히
    # 어느 트리가 문제인지 보이고, 전체 수는 위 줄이 이미 말한다.
    for p in uncovered[:20]:
        print(f"     {p}")
    if len(uncovered) > 20:
        print(f"     … 외 {len(uncovered) - 20}개")
    print()
    print("   이 파일들의 완화(항목 추가)는 그 완화를 담은 PR 안에서 리뷰")
    print("   없이 통과한다. .github/CODEOWNERS 에 패턴을 추가하라.")
    sys.exit(1)

print("✅ 모든 ratchet 산출물이 CODEOWNERS 에 등록돼 있다.")
PY
