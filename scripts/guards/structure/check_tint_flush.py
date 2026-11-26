#!/usr/bin/env python3
"""Anything that drives a builder must flush the tint layers it created.

A sub-1 token tint cannot live on the paint — a bound colour supplies its own
alpha and overwrites the paint's — so it lives on its own layer, and that layer
has to be the size of the box it tints. The size is not knowable while the builder
runs: a container is painted before its content exists (`applyChrome` runs while
the frame is still just its padding), so the number measured then is one the frame
has already outgrown.

`flushTintLayers()` gives every tint the size its host settled at, and it has to be
called once per entry, after `build` returns. Four files drive builders: the plugin's
`generate.ts` and `verify.ts`, and the two harnesses.

The failure a forgotten call produces is the one this guard is for: every tint drawn
short of its box's right and bottom edges by about its padding. That reads as a
gradient, or as a deliberate inset, and it shipped exactly once — the run that
prompted "투명도를 어떻게 했길래 이렇게 깨지는거야".

Net-new 0, no baseline: a driver either calls it or it does not.
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[3]
TOOL = ROOT / "tools/figma-token-sync"

# A call through the REGISTRY's build slot, which is what makes a file a driver.
#
# The argument's NAME is not part of the pattern. It was — `\b\w+\.build\(\s*page`
# — and that keyed the whole guard on a local variable's spelling: `generate.ts`
# passes `targetPage` and `verify.ts` passes `scratch`, so the two files this guard
# exists for were both invisible while it reported green over the two harnesses.
# `verify.ts` did not call `flushTintLayers` at all, which is exactly the defect
# this is written to prevent.
DRIVES = re.compile(r"\b\w+\.build\(\s*[A-Za-z_]")


def main() -> int:
    if not TOOL.exists():
        print(f"FAIL: {TOOL} 가 없다 — 경로가 바뀌었으면 이 가드도 따라가야 한다.")
        return 1

    files = sorted(
        [*(TOOL / "src").rglob("*.ts"), *(TOOL / "scripts").rglob("*.ts")]
    )
    if len(files) < 10:
        print(f"FAIL: 파일 {len(files)}개 — 경로 추출이 깨졌다.")
        return 1

    drivers: list[pathlib.Path] = []
    missing: list[str] = []
    for f in files:
        src = f.read_text()
        flat = re.sub(r"\s+", " ", src)
        if not DRIVES.search(flat):
            continue
        drivers.append(f)
        if "flushTintLayers(" not in src:
            missing.append(str(f.relative_to(ROOT)))

    # Four is the real count, so a regex that stops matching is caught rather than
    # reported as a clean run over a shrinking set.
    if len(drivers) < 4:
        print(
            f"FAIL: 빌더를 구동하는 파일이 {len(drivers)}개뿐이다 (4개여야 한다) — `.build(` 형태가 "
            "바뀌었고, 볼 것이 없는 가드는 아무것도 비교하지 않고 통과한다."
        )
        return 1

    if missing:
        print(f"❌ tint flush 를 부르지 않는 빌더 구동 파일 {len(missing)}건:")
        for m in missing:
            print(f"   ✗ {m}")
        print()
        print("   `build` 가 반환한 직후 `flushTintLayers()` 를 부른다 — tint 레이어는")
        print("   host 가 정착한 크기를 그때 받는다. 부르지 않으면 모든 tint 가 자기 상자의")
        print("   오른쪽·아래를 패딩만큼 못 채운 채 그려지고, 그건 그라데이션이나 의도된")
        print("   inset 처럼 보인다.")
        return 1

    print(
        f"✅ 빌더 구동 파일 {len(drivers)}개 전부 flushTintLayers 를 호출 (하드 0)."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
