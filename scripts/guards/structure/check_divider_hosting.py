#!/usr/bin/env python3
"""A hosted `Divider` goes through `hostedDivider` — never a bare `instanceOf`.

`Divider`'s root hugs and its line is built at a fixed length (200 unlabelled, 90
per segment), so making a rule span the box it separates takes TWO writes: the
instance stretches, and the line inside it stretches. Either alone leaves a rule
that stops short — and short is not obviously wrong on a canvas, it reads as a
design choice.

That is what happened. Of eight call sites, three stretched the instance and left
the line at its build length, and one did neither; the report that surfaced it
named the components those sites are in ("Separator 가 너비가 덜 차있는
컴포넌트들 많음 — 예: Mockup, Command"). A shared helper for exactly this existed
and three sites called it.

So the rule is not "remember both writes" — it is "there is one way in".
`hostedDivider` is the only place allowed to instance a `Divider`, which makes the
half-applied state unrepresentable rather than discouraged.

Written in Python rather than as a grep because the call is not always on one
line. The first version of this guard was a single-line `grep` and it passed on
its first run while an eighth site sat in `PhoneInput`, spelled across four lines:

    const separator = instanceOf(
      page,
      'Divider',
      bestVariantName(page, 'Divider', { Orientation: 'Vertical', … }),
    );

A guard that sees only one formatting of the thing it forbids is a guard against
that formatting. Matching is done on the source with newlines collapsed, and the
reported line is the one that opens the call.

Net-new 0, no baseline: the population is small and at zero, so a number here
would only be somewhere for the next one to hide.
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[3]
# 공유 헬퍼는 `helpers.ts` 한 파일이 아니다.
#
# 이 상수는 그 파일을 가리켰고, `helpers.ts` 가 관심사별 모듈로 쪼개지자 찾는 함수가
# 사라져 이 가드가 red 가 됐다 — 함수는 그대로 있고 파일만 바뀌었는데. 경로가 아니라
# **소스 전체**를 본다: 다음 이동에도 따라간다.
def _shared_sources() -> str:
    root = ROOT / "tools/figma-token-sync/src"
    if not root.exists():
        return ""
    return "\n".join(
        p.read_text() for p in sorted(root.rglob("*.ts")) if "/data/" not in str(p)
    )
BUILDERS = ROOT / "tools/figma-token-sync/src/components"

# `instanceOf( … 'Divider'` with any whitespace, including newlines, between.
BARE = re.compile(r"instanceOf\(\s*page\s*,\s*'Divider'")


def helper_is_whole() -> str | None:
    """Why the helper itself is insufficient, or None when it does both writes.

    Checked because a repo where `hostedDivider` was reduced to one write would
    pass the call-site check with tidy call sites and the same short rules.
    """
    if not _shared_sources():
        return "tools/figma-token-sync/src 에 .ts 가 없다 — 경로가 바뀌었으면 이 가드도 따라가야 한다"
    src = _shared_sources()
    missing = []
    if "export function hostedDivider(" not in src:
        missing.append("hostedDivider 정의")
    body_start = src.find("export function hostedDivider(")
    body = src[body_start:] if body_start >= 0 else ""
    if "rule.layoutSizingHorizontal = 'FILL'" not in body:
        missing.append("인스턴스 FILL")
    if "line.layoutSizingHorizontal = 'FILL'" not in body:
        missing.append("내부 선 FILL")
    return " / ".join(missing) if missing else None


def main() -> int:
    problem = helper_is_whole()
    if problem:
        print(f"FAIL: hostedDivider 가 두 write 를 다 하지 않는다: {problem}")
        print("      인스턴스만 늘리면 선이 build 길이에 멈추고, 선만 늘리면")
        print("      인스턴스가 hug 다 — 둘 다 필요하고 어느 하나로도 충분하지 않다.")
        return 1

    files = sorted(BUILDERS.rglob("*.ts"))
    if len(files) < 5:
        print(
            f"FAIL: 빌더 파일이 {len(files)}개뿐이다 — 경로 추출이 깨졌고, "
            "볼 것이 없는 가드는 아무것도 비교하지 않고 통과한다."
        )
        return 1

    hits: list[str] = []
    for f in files:
        src = f.read_text()
        flat = re.sub(r"\s+", " ", src)
        if not BARE.search(flat):
            continue
        # Recover the opening line: scan each `instanceOf(` and flatten a short
        # window after it, which is where the component name sits.
        for m in re.finditer(r"instanceOf\(", src):
            window = re.sub(r"\s+", " ", src[m.start() : m.start() + 200])
            if BARE.match(window):
                line = src.count("\n", 0, m.start()) + 1
                hits.append(f"{f.relative_to(ROOT)}:{line}")

    if hits:
        print(f"❌ hostedDivider 를 우회한 Divider 인스턴스 {len(hits)}건:")
        for h in hits:
            print(f"   ✗ {h}")
        print()
        print("   hostedDivider(page, lk, host, { axes, color, vertical }) 를 쓴다 —")
        print("   인스턴스 FILL 과 내부 선 FILL 을 함께 하는 유일한 경로다. 직접")
        print("   instanceOf 로 만들면 둘 중 하나를 빠뜨릴 수 있고, 빠뜨린 상태가")
        print("   캔버스에서는 '짧은 규칙선' 이라는 디자인 선택처럼 보인다.")
        return 1

    print(
        f"✅ Divider 호스팅 우회 0건 (하드 0, 빌더 {len(files)}개) · "
        "hostedDivider 가 두 write 를 보유."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
