#!/usr/bin/env python3
"""An instance of a multi-variant set names the variant it wants.

`instanceOf(page, 'Button')` with no variant name does not leave the choice open
for a designer — it returns whichever variant sorts FIRST. Across a set with a
dozen variants and five sizes that is a coin flip, and the coin was landing wrong:

  · `Menubar` / `NavigationMenu` composed their File / Edit / View triggers this
    way while both widgets pass `Button(variant: .menubar)`. The canvas drew three
    filled `primary` pills across a bar the app draws flat — reported as
    "File/Edit/View 버튼이 Ghost 버튼으로 되어야 하는거 아닌가", and the answer is
    `menubar`, the variant that exists for exactly this.
  · `RefreshTrigger` composed `const Loading()` unnamed, so `bar` at `lg` was as
    likely as the spinner the widget draws.

The comment defending the omission argued that naming a variant would break the
builder when the child's axis list grew, since `instanceOf` matches the full name
exactly. That concern is real and `bestVariantName` is its answer: it matches on
the axes you name and ignores the rest. So the omission bought nothing and cost a
silent wrong pick.

Scope: only sets with MORE THAN ONE variant or size row. A single-variant set has
nothing to choose, and requiring a name there would be noise.

Net-new 0, no baseline. A number here would be a place for the next coin flip to
sit, and the population is small enough that zero is reachable — it is zero now.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[3]
DATA = ROOT / "tools/figma-token-sync/src/data/components.json"
BUILDERS = ROOT / "tools/figma-token-sync/src/components"

# `instanceOf(page, 'X')` — no third argument. Whitespace-collapsed first, so the
# multi-line spelling is caught too (the shape that hid six `Divider` sites from
# an earlier single-line grep).
UNNAMED = re.compile(r"instanceOf\(\s*page\s*,\s*'(\w+)'\s*\)")


def pascal(slug: str) -> str:
    return "".join(part.capitalize() for part in slug.split("_"))


def main() -> int:
    if not DATA.exists():
        print(f"FAIL: {DATA} 가 없다 — export 를 먼저 돌려야 한다.")
        return 1

    doc = json.loads(DATA.read_text())["components"]
    # Component name → (variant rows, size rows), for the ones with a real choice.
    choosy: dict[str, tuple[int, int]] = {}
    for slug, comp in doc.items():
        variants = len((comp.get("variants") or {}).get("defaultsByVariant") or {})
        sizes = len((comp.get("sizes") or {}).get("defaultsBySize") or {})
        if variants > 1 or sizes > 1:
            choosy[pascal(slug)] = (variants, sizes)

    if len(choosy) < 10:
        print(
            f"FAIL: 선택지가 있는 컴포넌트가 {len(choosy)}개뿐이다 — 추출이 깨졌고, "
            "볼 것이 없는 가드는 아무것도 비교하지 않고 통과한다."
        )
        return 1

    files = sorted(BUILDERS.rglob("*.ts"))
    if len(files) < 5:
        print(f"FAIL: 빌더 파일 {len(files)}개 — 경로 추출이 깨졌다.")
        return 1

    hits: list[str] = []
    for f in files:
        src = f.read_text()
        flat = re.sub(r"\s+", " ", src)
        wanted = {m.group(1) for m in UNNAMED.finditer(flat)} & set(choosy)
        if not wanted:
            continue
        for m in re.finditer(r"instanceOf\(", src):
            window = re.sub(r"\s+", " ", src[m.start() : m.start() + 240])
            hit = UNNAMED.match(window)
            if hit and hit.group(1) in wanted:
                line = src.count("\n", 0, m.start()) + 1
                v, z = choosy[hit.group(1)]
                hits.append(
                    f"{f.relative_to(ROOT)}:{line} — {hit.group(1)} "
                    f"(variant {v} · size {z})"
                )

    if hits:
        print(f"❌ variant 를 지정하지 않은 다중-variant 인스턴스 {len(hits)}건:")
        for h in hits:
            print(f"   ✗ {h}")
        print()
        print("   `bestVariantName(page, '<Child>', { Variant: …, Size: … })` 로")
        print("   위젯이 실제로 넘기는 행을 지정한다. 이름을 빼는 것은 선택을 designer")
        print("   에게 열어두는 게 아니라 **정렬상 첫 variant** 로 고정하는 것이다 —")
        print("   그건 결정이 아니라 사고이고, 캔버스에서는 의도된 디자인처럼 보인다.")
        print("   축이 늘어날 걱정은 bestVariantName 이 해결한다(부분 축 매칭).")
        return 1

    print(
        f"✅ variant 미지정 인스턴스 0건 (하드 0) · 선택지 있는 컴포넌트 "
        f"{len(choosy)}개 · 빌더 {len(files)}개."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
