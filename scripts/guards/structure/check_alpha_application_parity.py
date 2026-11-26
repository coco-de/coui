#!/usr/bin/env python3
"""An alpha field must be applied the same way on both platforms.

`CoreXxxStyle` states alphas as bare doubles (`surfaceOpacity`,
`descriptionAlpha`, `disabledAlpha`, …), and a bare double says nothing about
WHAT it dims. Two readings are available at the paint site and they are not the
same picture:

  colour  — the alpha rides one colour (`bgColor.withValues(alpha: a)`,
            `fg.scaleAlpha(a)`, Tailwind's `text-{token}/{pct}`). That colour
            goes translucent; everything else on the node keeps its own.
  node    — the alpha rides the element (`Opacity(opacity: a)`,
            `raw['opacity'] = a`). The node and every descendant fade together.

Whenever the node holds exactly one painted thing the two are indistinguishable,
which is why this drifted silently: five fields were read as a colour on Flutter
and as a node on Web, and each looked right in isolation. `Dialog.surfaceOpacity`
is the one that shows: Flutter made the panel translucent and left the title,
body and buttons opaque, while Web faded the panel *and its contents*, so a
translucent-surface preset produced a readable dialog on one platform and a
washed-out one on the other. `EmptyState.iconColorAlpha` was worse — Web dropped
it entirely when a colour was stated and dimmed the node when one was not, two
wrongs that cancelled into something that read as deliberate.

So: for every alpha field, classify each platform's application and require
agreement. Undetermined is not a pass — a field this script cannot classify is
listed with a reason, the same way the other baseline-free gates list what they
cannot judge. There is no baseline: adding a line to the allowlist is a change a
reviewer sees, not a number that quietly goes up.

The classifier follows one alias hop, because that is how resolvers are written:
`final iconAlpha = merged.iconColorAlpha ?? default;` then
`iconColorBase.withValues(alpha: iconAlpha)`. Without the hop nine of the
twenty-six fields read as unused, and a gate that cannot see the paint site would
have passed the exact divergence it exists to catch.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[3]
CONTRACTS = ROOT / "packages/coui_core/lib/src/component/contracts"
PLATFORMS = {
    "flutter": ROOT / "packages/coui_flutter/lib/src/components",
    "web": ROOT / "packages/coui_web/lib/src/components",
}
ALLOWLIST = pathlib.Path(__file__).with_name("alpha_application_allowlist.json")

ALPHA_FIELD = re.compile(r"^\s+final double\?? (\w*(?:[Aa]lpha|[Oo]pacity))\s*;", re.M)

# Classification is VALUE-scoped: the alpha has to sit in the value position of
# the idiom, with only same-expression text between them (no comma, semicolon or
# brace crossed).
#
# Two coarser versions failed in opposite directions and both were wrong in the
# accusing direction. Adjacency missed every ternary —
# `AnimatedOpacity(opacity: inside ? resolved.fadeOpacity : 1)` puts the
# condition in between — and read those as "no paint site found". Whole-statement
# matching then over-reached: a `Styles(raw: {…})` map is one statement, so
# `Drawer`'s barrier read as node-dimmed because the same map carries
# `'opacity': '$openProgress'` for the open/close animation, a different value
# entirely. Scoping to the value position keeps the ternary and drops the
# neighbour.
NAME = "NAME"
COLOR_PATTERNS = (
    r"(?:withOpacity|scaleAlpha)\(\s*[^,;)]*\bNAME\b",
    r"withValues\(\s*alpha:\s*[^,;)]*\bNAME\b",
    r"\balpha:\s*[^,;)]*\bNAME\b",
    r"\bNAME\b\s*\*\s*kPercentScale",
)
NODE_PATTERNS = (
    r"(?<![\w.])(?:Animated)?Opacity\(\s*opacity:\s*[^,;)]*\bNAME\b",
    r"raw\['opacity'\]\s*=\s*[^;]*\bNAME\b",
    r"'opacity'\s*:\s*[^,}]*\bNAME\b",
    r"\.opacity\s*=\s*[^;]*\bNAME\b",
)


def _matches(patterns: tuple[str, ...], alias: str, body: str) -> bool:
    esc = re.escape(alias)
    return any(
        re.search(p.replace(NAME, esc), body, re.S) is not None for p in patterns
    )


def strip_comments(src: str) -> str:
    """Blanks comment bodies so a doc comment describing an idiom is not one."""
    out = []
    for line in src.split("\n"):
        stripped = line.lstrip()
        out.append("" if stripped.startswith("//") else line)
    return "\n".join(out)


def aliases_of(field: str, src: str) -> set[str]:
    """Locals that carry `field` — one hop, which is how resolvers are written.

    Only a *forwarding* initializer counts. Accepting any declaration that
    merely mentions the field captured container variables — a `final raw = {…}`
    map literal that happens to hold the alpha somewhere makes `raw` an alias,
    and then every `raw['opacity'] = …` in the file reads as this field being
    applied to a node. That produced seven confident reports of double-dimming
    where none existed, in components that were already correct: a gate wrong in
    the accusing direction is worse than one that stays quiet, because the fix it
    demands is to undo working code.
    """
    names = {field}
    for m in re.finditer(
        r"final\s+(?:double\??\s+)?(\w+)\s*=([^;]*)",
        src,
    ):
        init = m.group(2)
        if not re.search(r"\b" + re.escape(field) + r"\b", init):
            continue
        # A forward, not a container: no collection literal, and short enough to
        # be one expression rather than a bundle being assembled.
        if "{" in init or "[" in init or len(init) > 160:
            continue
        names.add(m.group(1))
    # `ResolvedXxx(field: local)` then `resolved.field` in the widget — the
    # Resolved member keeps the field's name, so `field` already covers it.
    return names


def classify(field: str, sources: list[str]) -> set[str]:
    found: set[str] = set()
    for src in sources:
        body = strip_comments(src)
        for alias in aliases_of(field, body):
            if _matches(COLOR_PATTERNS, alias, body):
                found.add("colour")
            if _matches(NODE_PATTERNS, alias, body):
                found.add("node")
    return found


def style_scopes(style: pathlib.Path) -> tuple[str, ...]:
    """Platform directories a contract style file's alphas are applied in.

    A contract directory is named after the component only when it holds one
    style. One that holds several variants' styles (`mockup/` holds
    `mockup_device_style.dart`) is matched by the platform directory of the
    variant that file belongs to (`mockup_device/`), and the file stem names
    it. Searching the contract directory name alone found no paint site for
    those fields and listed them as undetermined, which is a statement about
    the script and not about the code.
    """
    stem = style.name[: -len("_style.dart")]
    return tuple(dict.fromkeys((style.parent.name, stem)))


def component_sources(
    scopes: tuple[str, ...], platform_root: pathlib.Path
) -> list[str]:
    seen: set[pathlib.Path] = set()
    out = []
    for scope in scopes:
        for d in platform_root.rglob(scope):
            if not d.is_dir() or d in seen:
                continue
            seen.add(d)
            for f in d.glob("*.dart"):
                out.append(f.read_text())
    return out


def main() -> int:
    allow = json.loads(ALLOWLIST.read_text()) if ALLOWLIST.exists() else {"fields": {}}
    entries: dict[str, dict] = allow.get("fields", {})

    fields: list[tuple[str, str]] = []
    scopes_of: dict[str, tuple[str, ...]] = {}
    for style in sorted(CONTRACTS.rglob("*_style.dart")):
        component = style.parent.name
        for m in ALPHA_FIELD.finditer(style.read_text()):
            fields.append((component, m.group(1)))
            scopes_of[f"{component}.{m.group(1)}"] = style_scopes(style)

    if len(fields) < 15:
        print(
            f"FAIL: only {len(fields)} alpha field(s) found — the extraction "
            "broke, and a gate with nothing to compare passes by comparing "
            "nothing."
        )
        return 1

    disagree: list[str] = []
    undetermined: list[str] = []
    agreed = 0
    for component, field in fields:
        key = f"{component}.{field}"
        kinds = {
            plat: classify(field, component_sources(scopes_of[key], root))
            for plat, root in PLATFORMS.items()
        }
        f_, w_ = kinds["flutter"], kinds["web"]
        # A divergence needs BOTH sides read and reading differently. One side
        # blank is this script failing to find a paint site, not evidence that
        # the platform has none — `card.surfaceOpacity` reaches its alpha inside
        # the `OutlinedContainer` it forwards to, a file this component's own
        # directory does not contain. Calling that a divergence would make the
        # gate loudest exactly where it understands least, and the fix would be
        # to weaken the check. So it goes to `undetermined`, which still has to
        # be named and explained — the gate says what it cannot judge instead of
        # guessing.
        if not f_ or not w_:
            undetermined.append(key)
            continue
        # Both readings on ONE platform is a defect on its own, and an
        # intersection test alone passes it: adding `raw['opacity']` on top of a
        # colour that already carries the alpha leaves colour ∩ colour non-empty
        # while the pixel is dimmed twice (0.8 × 0.8 = 0.64 where the code says
        # 0.8). The first version of this gate was proven green against exactly
        # that injection, which is the reason the check is written as "one
        # reading per platform, and the same one" rather than "they overlap".
        if len(f_) > 1 or len(w_) > 1:
            if key in entries:
                agreed += 1
                continue
            disagree.append(
                f"{key} — 한 플랫폼이 두 방식을 동시에 쓴다 (이중 dimming): "
                f"flutter: {'/'.join(sorted(f_))} · web: {'/'.join(sorted(w_))}"
            )
            continue
        if f_ == w_:
            agreed += 1
            continue
        if key in entries:
            agreed += 1
            continue
        disagree.append(
            f"{key} — flutter: {'/'.join(sorted(f_))} · web: {'/'.join(sorted(w_))}"
        )

    unlisted = [k for k in undetermined if k not in entries]
    stale = [k for k in entries if k not in {f"{c}.{f}" for c, f in fields}]

    if disagree:
        print("❌ 같은 alpha 필드를 두 플랫폼이 다르게 적용한다:")
        for d in disagree:
            print(f"   ✗ {d}")
        print()
        print("   색의 alpha 와 노드 opacity 는 다른 그림이다 — 노드에 걸면 그 안의")
        print("   모든 것이 같이 흐려진다. 필드 이름이 무엇을 흐리게 하는지 말하고")
        print("   있고, 모호하면 Flutter 가 기준이다(principles/flutter-first.md).")
        print("   Tailwind 는 class 안에 alpha 를 담으므로(`text-{token}/{pct}`)")
        print("   색으로 옮겨도 토큰 바인딩을 잃지 않는다.")
        return 1

    if unlisted:
        print("❌ 적용 지점을 판정할 수 없는 alpha 필드가 열거되지 않았다:")
        for k in sorted(unlisted):
            print(f"   ✗ {k}")
        print()
        print(f"   {ALLOWLIST.name} 에 사유와 함께 적어라 — 판정 불가를 그냥")
        print("   통과시키면 이 게이트는 자기가 못 보는 것을 봤다고 말하게 된다.")
        return 1

    if stale:
        print("❌ allowlist 에 이제 존재하지 않는 필드가 남아 있다:")
        for k in sorted(stale):
            print(f"   ✗ {k}")
        return 1

    print(
        f"✅ alpha 필드 {len(fields)}개 — 적용 방식 일치 {agreed}개 · "
        f"판정 불가 {len(undetermined)}개(사유 기록). baseline 없음."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
