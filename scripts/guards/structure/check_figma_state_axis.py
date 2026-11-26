#!/usr/bin/env python3
"""Figma 빌더의 `State` 축 계약 가드 (R1 · R3) — 정적 소스 검사. ratchet.

무엇을 막는가
-------------
상호작용 상태를 `State` 한 축으로 둔다는 규칙(R1: 이름 `enabled · hover · focus · pressed ·
disabled` 와 그 순서)과, `State` 에 `focus` 가 있으면 `Show focus ring` 불린이 **정의되고
결선돼야** 한다는 규칙(R3). 규칙의 구현은 `src/state-axis.ts` 한 곳이다 — 빌더는 값 목록을
`stateAxis([...])` 로, 불린을 `defineShowFocusRing` / `bindShowFocusRing` 으로 만든다.

왜 정적 가드가 따로 있는가: 헬퍼는 **그것을 거친 목록**만 검증한다. 거치지 않은 목록은 조용하다 —
순서가 다른 세트는 멤버 이름이 그럴듯해 보이고, `State=focus` 만 있고 불린이 없는 세트는 오류 없이
그려진다(링을 겹쳐 켤 수 없을 뿐이다). 그래서 이 가드는 빌더 소스에서 세 가지를 센다:

  list-not-via-helper            `k…States` 목록이 `stateAxis(...)` 를 거치지 않았다
                                 (R1 이름 · 순서 위반이면 메시지에 이유가 붙는다)
  list-invalid                   `stateAxis(...)` 를 거쳤지만 R1 이름 · 순서가 아니다 — 런타임에도
                                 던지지만 소스 모양에서 먼저 잡는다
  axis-without-list              `State` 축(`axis: 'State'` · `State=${…}`)을 쓰는 함수가 어떤
                                 `k…States` 목록도 · `stateAxis(...)` 도 참조하지 않는다
  focus-without-show-focus-ring  `focus` 가 든 목록을 참조하는 함수가 `defineShowFocusRing(` 과
                                 `bindShowFocusRing(` 을 **둘 다** 부르지 않는다(정의만 하고 결선하지
                                 않은 불린은 게시에서 세트를 빼는 미연결 속성이다)

기존 위반은 `figma_state_axis_baseline.txt` 에 키로 적혀 있고 **net-new 0** 이다. baseline 에 있는데
더는 위반이 아닌 키는 실패한다 — 고친 사람이 그 줄을 지우는 것이 ratchet 이 내려가는 방식이다.
각 줄은 이유를 가진다(`#` 주석). 무엇이 아직 R1 밖인지는 그 세트를 옮기는 작업(변형 개명표와 함께)의
몫이고 이 가드는 새로 늘지 않게만 한다.

보지 못하는 것
--------------
· 값이 계약 데이터에서 오는 `State` 축(`axisSpecsOf` — Dart enum 의 멤버)은 소스에 목록이 없다.
  그 세트들은 `selftest-registry-runtime` 의 *state axis drill* 이 **만들어진 세트**에서 같은 두
  질문을 한다(같은 baseline 파일의 `set::` 줄).
· 불린이 정의되고 결선된 **노드가 실제로 있는지**는 소스 모양으로 알 수 없다 — 같은 drill 이 본다.

Usage: check_figma_state_axis.py [--report | --self-test]
"""
from __future__ import annotations

import os
import re
import sys
from typing import Dict, List, Optional, Set, Tuple

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
BUILDERS = os.path.join(ROOT, "tools", "figma-token-sync", "src", "components")
BASELINE = os.path.join(ROOT, "scripts", "guards", "structure", "figma_state_axis_baseline.txt")

# R1 — `src/state-axis.ts` 의 `kStateOrder` 와 같아야 한다. 아래 floor 와 함께 selftest 가
# 두 목록이 같은지 단언한다(selftest-state-axis).
R1_ORDER = ["enabled", "hover", "focus", "pressed", "disabled"]

# 모집단 하한 — 패턴이 매칭을 멈추면(헬퍼 rename · 파일 이동) 위반이 0 에 가까워져 "다 고쳐졌다" 로
# 조용히 오판된다. 헬퍼를 거친 목록 수가 이 아래이면 grep 붕괴로 보고 실패한다.
FLOOR_HELPER_LISTS = 12
FLOOR_SHOW_FOCUS_DEFINERS = 8


# ── 소스를 코드만 남기고 훑는다 ─────────────────────────────────────────────────────────────────


def sanitize(src: str) -> str:
    """주석과 문자열 **내용**을 공백으로 바꾼다 — 길이 · 줄바꿈 · 오프셋은 그대로.

    중괄호 맞추기와 "주석 안의 매칭 걸러내기" 용이다. 따옴표 자체는 남긴다.
    """
    out = list(src)
    i = 0
    n = len(src)
    # 템플릿 리터럴 안의 `${ … }` 는 코드다 — 깊이를 스택으로 센다.
    template_stack: List[int] = []
    brace_depth = 0
    while i < n:
        c = src[i]
        nxt = src[i + 1] if i + 1 < n else ""
        if c == "/" and nxt == "/":
            while i < n and src[i] != "\n":
                out[i] = " "
                i += 1
            continue
        if c == "/" and nxt == "*":
            while i < n and not (src[i] == "*" and i + 1 < n and src[i + 1] == "/"):
                if src[i] != "\n":
                    out[i] = " "
                i += 1
            for j in (i, i + 1):
                if j < n:
                    out[j] = " "
            i += 2
            continue
        if c in ("'", '"'):
            quote = c
            i += 1
            while i < n and src[i] != quote:
                if src[i] == "\\":
                    out[i] = " "
                    i += 1
                if i < n and src[i] != "\n":
                    out[i] = " "
                i += 1
            i += 1
            continue
        if c == "`":
            i += 1
            while i < n and src[i] != "`":
                if src[i] == "\\":
                    out[i] = " "
                    i += 1
                    if i < n:
                        out[i] = " "
                    i += 1
                    continue
                if src[i] == "$" and i + 1 < n and src[i + 1] == "{":
                    template_stack.append(brace_depth)
                    brace_depth += 1
                    i += 2
                    # `${ … }` 안은 코드 — 닫는 `}` 까지 일반 스캔으로 돌아간다.
                    depth = 1
                    while i < n and depth > 0:
                        ch = src[i]
                        if ch == "{":
                            depth += 1
                        elif ch == "}":
                            depth -= 1
                            if depth == 0:
                                break
                        i += 1
                    i += 1
                    brace_depth -= 1
                    template_stack.pop()
                    continue
                if src[i] != "\n":
                    out[i] = " "
                i += 1
            i += 1
            continue
        i += 1
    return "".join(out)


FUNC_RE = re.compile(r"^(?:export\s+)?(?:async\s+)?function\s+(\w+)\s*(?:<[^>]*>)?\s*\(", re.M)


def function_spans(code: str) -> List[Tuple[str, int, int]]:
    """최상위 함수 선언의 (이름, 시작, 끝) — 중괄호는 sanitize 된 코드에서 맞춘다."""
    spans: List[Tuple[str, int, int]] = []
    for m in FUNC_RE.finditer(code):
        i = m.end()
        # 매개변수 괄호를 닫고, 그 뒤 첫 `{` 가 본문이다.
        depth = 1
        while i < len(code) and depth > 0:
            if code[i] == "(":
                depth += 1
            elif code[i] == ")":
                depth -= 1
            i += 1
        while i < len(code) and code[i] != "{":
            i += 1
        start = i
        depth = 0
        while i < len(code):
            if code[i] == "{":
                depth += 1
            elif code[i] == "}":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        spans.append((m.group(1), m.start(), i + 1))
    return spans


# ── 목록 · 사용 ────────────────────────────────────────────────────────────────────────────────


LIST_DEF_RE = re.compile(
    r"^const\s+(k\w*States)\s*=\s*(stateAxis\(\s*)?\[(.*?)\]\s*(?:as const\s*)?(\))?\s*;",
    re.M | re.S,
)
INLINE_HELPER_RE = re.compile(r"\bstateAxis(?:Spec)?\(\s*\[(.*?)\]\s*\)", re.S)
STATE_USE_RE = re.compile(r"axis:\s*'State'|`State=\$\{|'State='")
STR_RE = re.compile(r"'([^']*)'")


def r1_problem(values: List[str]) -> Optional[str]:
    """R1 이름 · 순서 · 중복 위반이면 이유, 아니면 None."""
    seen: Set[str] = set()
    at = -1
    for v in values:
        if v not in R1_ORDER:
            return "'%s' 는 R1 이름이 아니다" % v
        if v in seen:
            return "'%s' 가 두 번 든다" % v
        seen.add(v)
        idx = R1_ORDER.index(v)
        if idx < at:
            return "[%s] 는 R1 순서가 아니다" % ", ".join(values)
        at = idx
    return None


class Finding:
    def __init__(self, key: str, why: str) -> None:
        self.key = key
        self.why = why


def analyze(fname: str, src: str) -> Tuple[List[Finding], Dict[str, int]]:
    code = sanitize(src)
    findings: List[Finding] = []
    stats = {"helper_lists": 0, "show_focus_definers": 0}

    # 1. 이름 붙은 목록.
    lists: Dict[str, Tuple[List[str], bool]] = {}  # name → (values, via helper)
    for m in LIST_DEF_RE.finditer(src):
        if code[m.start()] != src[m.start()]:
            continue  # 주석 안
        name = m.group(1)
        values = STR_RE.findall(m.group(3))
        via_helper = m.group(2) is not None
        lists[name] = (values, via_helper)
        problem = r1_problem(values)
        if via_helper:
            stats["helper_lists"] += 1
            if problem:
                findings.append(Finding("%s::%s::list-invalid" % (fname, name), problem))
        else:
            why = "stateAxis(...) 를 거치지 않았다"
            if problem:
                why += " — 그리고 " + problem
            findings.append(Finding("%s::%s::list-not-via-helper" % (fname, name), why))

    # 2. 함수 단위.
    for fn, start, end in function_spans(code):
        body_src = src[start:end]
        body_code = code[start:end]
        uses_state = bool(STATE_USE_RE.search(body_src)) and any(
            body_code[m.start()] == body_src[m.start()] for m in STATE_USE_RE.finditer(body_src)
        )
        referenced = [n for n in lists if re.search(r"\b%s\b" % re.escape(n), body_code)]
        inline = [
            STR_RE.findall(m.group(1))
            for m in INLINE_HELPER_RE.finditer(body_src)
            if body_code[m.start()] == body_src[m.start()]
        ]
        for values in inline:
            problem = r1_problem(values)
            if problem:
                findings.append(Finding("%s::%s::list-invalid" % (fname, fn), problem))
        if uses_state and not referenced and not inline:
            findings.append(
                Finding(
                    "%s::%s::axis-without-list" % (fname, fn),
                    "State 축을 쓰는데 k…States 목록도 stateAxis(...) 도 참조하지 않는다",
                )
            )
        has_focus = any("focus" in lists[n][0] for n in referenced) or any("focus" in v for v in inline)
        defines = bool(re.search(r"\bdefineShowFocusRing\(", body_code))
        binds = bool(re.search(r"\bbindShowFocusRing\(", body_code))
        if defines:
            stats["show_focus_definers"] += 1
        if has_focus and not (defines and binds):
            missing = []
            if not defines:
                missing.append("defineShowFocusRing(")
            if not binds:
                missing.append("bindShowFocusRing(")
            findings.append(
                Finding(
                    "%s::%s::focus-without-show-focus-ring" % (fname, fn),
                    "State 에 focus 가 있는데 %s 를 부르지 않는다" % " · ".join(missing),
                )
            )
    return findings, stats


# ── baseline ──────────────────────────────────────────────────────────────────────────────────


def read_baseline() -> Dict[str, str]:
    """`키  # 이유` — 정적 키(`file::name::kind`)만. `set::` 줄은 selftest 의 몫이다."""
    out: Dict[str, str] = {}
    if not os.path.exists(BASELINE):
        return out
    with open(BASELINE, encoding="utf-8") as fh:
        for raw in fh:
            line = raw.strip()
            if not line or line.startswith("#") or line.startswith("set::"):
                continue
            key, _, why = line.partition("#")
            out[key.strip()] = why.strip()
    return out


def run(report: bool) -> int:
    if not os.path.isdir(BUILDERS):
        print("❌ %s 없음 — 경로가 바뀌었으면 이 가드도 따라가야 한다." % os.path.relpath(BUILDERS, ROOT))
        return 1
    all_findings: List[Finding] = []
    helper_lists = 0
    definers = 0
    for fname in sorted(os.listdir(BUILDERS)):
        if not fname.endswith(".ts"):
            continue
        with open(os.path.join(BUILDERS, fname), encoding="utf-8") as fh:
            src = fh.read()
        found, stats = analyze(fname, src)
        all_findings.extend(found)
        helper_lists += stats["helper_lists"]
        definers += stats["show_focus_definers"]

    floor_failed = helper_lists < FLOOR_HELPER_LISTS or definers < FLOOR_SHOW_FOCUS_DEFINERS
    if floor_failed:
        print(
            "❌ 모집단이 하한 아래다 — stateAxis 목록 %d (하한 %d) · defineShowFocusRing 호출 함수 %d (하한 %d)."
            % (helper_lists, FLOOR_HELPER_LISTS, definers, FLOOR_SHOW_FOCUS_DEFINERS)
        )
        print("   패턴이 매칭을 멈춘 것이다(헬퍼 rename · 파일 이동) — '위반 0' 을 믿지 말고 이 가드를 따라가라.")
        print("   세트를 정말 지웠거나 목록을 헬퍼 밖으로 꺼낸 것이라면 아래 위반도 함께 본다 — 하한을 내리는 편집이 곧 그 선언이다.")

    baseline = read_baseline()
    found_by_key = {f.key: f for f in all_findings}

    if report:
        print("stateAxis 목록 %d · defineShowFocusRing 호출 함수 %d · 위반 %d" % (helper_lists, definers, len(found_by_key)))
        for key in sorted(found_by_key):
            tag = "baseline" if key in baseline else "NEW"
            print("  [%s] %s — %s" % (tag, key, found_by_key[key].why))
        return 0

    new = sorted(k for k in found_by_key if k not in baseline)
    stale = sorted(k for k in baseline if k not in found_by_key)
    if new:
        print("❌ State 축 계약 위반 net-new %d건:" % len(new))
        for k in new:
            print("   ✗ %s — %s" % (k, found_by_key[k].why))
        print()
        print("   값 목록은 `stateAxis([...])` (R1 이름 · 순서), 포커스가 든 세트는 `defineShowFocusRing(set)` 과")
        print("   `bindShowFocusRing(ring, id)` 를 부른다 — `tools/figma-token-sync/src/state-axis.ts`.")
        print("   기존 세트를 옮기는 일이라면 변형 개명표와 함께 하고, 그 전까지의 예외는 baseline 에 이유와 함께 적는다.")
    if stale:
        print("❌ baseline 에 있지만 더는 위반이 아닌 키 %d건 — 줄을 지워라(ratchet 은 내려가기만 한다):" % len(stale))
        for k in stale:
            print("   ✗ %s" % k)
    if new or stale or floor_failed:
        return 1
    print(
        "✅ State 축 계약 — stateAxis 목록 %d · defineShowFocusRing 호출 함수 %d · 위반은 baseline %d건 그대로 (net-new 0)."
        % (helper_lists, definers, len(baseline))
    )
    return 0


# ── self-test: 이 가드가 실패할 수 있다는 증거 ───────────────────────────────────────────────────


def self_test() -> int:
    failures = 0

    def check(label: str, ok: bool) -> None:
        nonlocal failures
        print("  %s  %s" % ("ok " if ok else "FAIL", label))
        if not ok:
            failures += 1

    def keys(src: str) -> Set[str]:
        return {f.key for f in analyze("x.ts", src)[0]}

    good = (
        "const kAStates = stateAxis(['enabled', 'hover', 'focus', 'disabled']);\n"
        "function buildA(page) {\n"
        "  const combos = [{ axis: 'State', values: [...kAStates] }];\n"
        "  const id = defineShowFocusRing(set);\n"
        "  bindShowFocusRing(ring, id);\n"
        "}\n"
    )
    check("conforming builder → no findings", keys(good) == set())

    check(
        "out-of-order list through the helper → list-invalid",
        "x.ts::kAStates::list-invalid"
        in keys(good.replace("['enabled', 'hover', 'focus', 'disabled']", "['enabled', 'focus', 'hover', 'disabled']")),
    )
    raw = good.replace(
        "stateAxis(['enabled', 'hover', 'focus', 'disabled'])",
        "['enabled', 'hover', 'focus', 'disabled'] as const",
    )
    check(
        "raw list (not through the helper) → list-not-via-helper",
        "x.ts::kAStates::list-not-via-helper" in keys(raw),
    )
    check(
        "non-R1 name (default) → flagged",
        "x.ts::kAStates::list-invalid" in keys(good.replace("'enabled'", "'default'")),
    )
    check(
        "value state in State (selected) → flagged",
        "x.ts::kAStates::list-invalid" in keys(good.replace("'disabled'", "'selected'")),
    )
    check(
        "focus without defineShowFocusRing → focus-without-show-focus-ring",
        "x.ts::buildA::focus-without-show-focus-ring" in keys(good.replace("defineShowFocusRing(set)", "null")),
    )
    check(
        "defined but never bound → still flagged (an unbound property drops the set from publishing)",
        "x.ts::buildA::focus-without-show-focus-ring" in keys(good.replace("bindShowFocusRing(ring, id);", "")),
    )
    check(
        "no focus in the list → no Show focus ring required",
        keys(good.replace("'focus', ", "").replace("  const id = defineShowFocusRing(set);\n  bindShowFocusRing(ring, id);\n", "")) == set(),
    )
    check(
        "State composed by hand with no list → axis-without-list",
        "x.ts::buildB::axis-without-list" in keys("function buildB(page) {\n  const n = `State=${s}`;\n}\n"),
    )
    check(
        "a comment that mentions the pattern is not a use",
        keys("function buildC(page) {\n  // axis: 'State', values: [] — see the other builder\n}\n") == set(),
    )
    check(
        "a 'focus' inside a comment does not make the function a focus function",
        keys(good.replace("'focus', ", "").replace("  const id = defineShowFocusRing(set);\n  bindShowFocusRing(ring, id);\n", "").replace("function buildA(page) {", "function buildA(page) {\n  // focus ring lives elsewhere\n")) == set(),
    )
    check("R1 order matches state-axis.ts", R1_ORDER == _r1_from_source())

    if failures:
        print("\n%d self-test(s) failed." % failures)
        return 1
    print("\nAll self-tests passed.")
    return 0


def _r1_from_source() -> List[str]:
    path = os.path.join(ROOT, "tools", "figma-token-sync", "src", "state-axis.ts")
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    m = re.search(r"export const kStateOrder = \[(.*?)\] as const;", text, re.S)
    return STR_RE.findall(m.group(1)) if m else []


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        sys.exit(self_test())
    sys.exit(run("--report" in sys.argv))
