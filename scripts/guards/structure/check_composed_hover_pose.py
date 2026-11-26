#!/usr/bin/env python3
"""A composed child is drawn at REST — the parent owns the pointer.

A `Button` that a component composes (a menu row, a select option, a dialog's
action, a toast's ✕) is not a button a designer hovers. It is a part of the
parent, and the pointer is over the PARENT: what changes under it is the parent's
statement about its own row, which is why `Menu` / `Select` / `Tree` / `Table` all
carry a hover colour of their own and hand the child none.

So the child's hovered row must not be the one on the canvas. Picking it would put
two hover fills on one surface — the parent's row tint and the child's own — and a
designer inspecting the instance would find a pointer state that the app never
reaches through it.

Scope: variant selection for a composed instance. This gate reads the axes a
builder ASKS for (`bestVariantName(page, 'X', { … Hover: … })` and the literal
maps beside those calls) and requires every one that names a `Hover`-like axis to
name the resting value. It does not stop a designer from flipping the axis in
Figma — that is the set's property and cannot be per-instance — so what it holds
is the shipped page.

Not just `Button`: any composed instance whose set has a hover axis reads the same
way, and the rule is about composition, not about which component.

Net-new 0, no baseline. Every site already asks for the resting row, so the
population is at zero and a number here would only be somewhere for the next
hovered pick to sit.
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[3]
BUILDERS = ROOT / "tools/figma-token-sync/src/components"

# A hovered pose asked for by axis, in every spelling the builders use.
#
# TWO shapes, because a state axis is not always a boolean. `Hover: 'true'` is
# the boolean-pose form; `State: 'hover'` is the enum form, which arrived when
# `Button` folded its five poses onto one axis. Reading only the first was not a
# smaller net — it was a net with nothing in it: the seven Button call sites this
# guard was written around all moved to the enum spelling at once, and the guard
# kept printing green because four unrelated `Hover:` mentions elsewhere were
# enough to clear its fail-closed.
#
# Whitespace-collapsed first so a multi-line object literal is caught too (the
# shape that hid six `Divider` sites from an earlier single-line grep).
HOVERED = re.compile(
    r"\bHover(?:ed)?:\s*(?:'true'|\"true\"|`true`|true\b)"
    r"|\bState:\s*(?:'hover'|\"hover\"|`hover`)"
)

# The variant NAME string form — `Hover=true` / `State=hover` inside a name a
# builder composes. A set's own builder writes these to enumerate its members, so
# this is only a violation when it is an instance SELECTION; those go through
# `bestVariantName` or `instanceOf`, and both take the name as an argument rather
# than pushing it.
SELECTED_NAME = re.compile(
    r"(?:bestVariantName|instanceOf|restingVariantName)\([^;]{0,400}?"
    r"(?:Hover(?:ed)?=true|State=hover)"
)

# What the fail-closed counts: any STATE AXIS named at a call site, whatever
# value it carries. Not "any hover" — zero hovered selections is the state this
# guard exists to produce, so counting only those would make success look like
# breakage. Counting the axis instead answers the question the fail-closed is
# really asking: can this guard still see where poses are chosen?
STATE_AXIS_NAMED = re.compile(r"\b(?:Hover(?:ed)?|State):")


def main() -> int:
    files = sorted(BUILDERS.rglob("*.ts"))
    if len(files) < 5:
        print(f"FAIL: 빌더 파일 {len(files)}개 — 경로 추출이 깨졌다.")
        return 1

    # The gate has to see the axis at all, or it is checking nothing: every
    # composed-instance call site that names a state axis is counted, and a run
    # that finds none means the spelling changed.
    axis_named = 0
    hits: list[str] = []
    for f in files:
        src = f.read_text()
        flat = re.sub(r"\s+", " ", src)
        axis_named += len(STATE_AXIS_NAMED.findall(flat))
        for m in re.finditer(r"(?:bestVariantName|instanceOf|restingVariantName)\(", src):
            window = re.sub(r"\s+", " ", src[m.start() : m.start() + 400])
            # Trim at the call's own closing paren so the next statement's axes
            # are not read as this call's.
            depth = 0
            end = len(window)
            for i, ch in enumerate(window):
                if ch == "(":
                    depth += 1
                elif ch == ")":
                    depth -= 1
                    if depth == 0:
                        end = i
                        break
            call = window[:end]
            if HOVERED.search(call) or SELECTED_NAME.search(call):
                line = src.count("\n", 0, m.start()) + 1
                hits.append(f"{f.relative_to(ROOT)}:{line}")

    if axis_named == 0:
        print(
            "FAIL: Hover 축을 지정하는 인스턴스 호출이 0건이다 — 축 이름이 바뀌었고, "
            "볼 것이 없는 가드는 아무것도 비교하지 않고 통과한다."
        )
        return 1

    if hits:
        print(f"❌ 합성된 자식을 hover 자세로 고른 자리 {len(hits)}건:")
        for h in hits:
            print(f"   ✗ {h}")
        print()
        print("   합성된 자식은 쉬는 자세로 그린다 — 포인터는 부모 위에 있고, 그 아래에서")
        print("   바뀌는 것은 부모가 자기 행에 대해 하는 진술이다(Menu/Select/Tree/Table 이")
        print("   각자 hover 색을 갖고 자식에게는 주지 않는 이유). 자식의 hover 를 고르면")
        print("   한 표면에 hover 채움이 둘이 되고, 인스턴스를 들여다본 디자이너는 앱이")
        print("   그 경로로는 도달하지 않는 포인터 상태를 보게 된다.")
        return 1

    print(
        f"✅ 합성 자식의 hover 자세 선택 0건 (하드 0) · Hover 축을 지정한 호출 "
        f"{axis_named}건 · 빌더 {len(files)}개."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
