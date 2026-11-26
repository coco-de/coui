#!/usr/bin/env python3
"""A component that states a chromeless child style must apply it on the canvas.

Some components put a `TextField` inside their own bordered box. The box owns the
single visible boundary, and the widgets say so by forwarding a chromeless
`CoreTextFieldStyle` into the field — transparent fill and border, zero border
width, zero padding, transparent focus ring.

A composed Figma INSTANCE does not know that. It arrives with `TextField`'s own
border and fill, so the canvas draws a field inside a field: a second rounded
outline sitting inside the first, with a gap between them. Three components were
in that state (`PhoneInput`, `ChipInput`, `Command`), and the report that surfaced
it put the canvas next to the app for one of them — the difference is obvious side
by side and looks like a deliberate inset on its own.

Two things had to be true for it to persist that long, and this guard closes both:

1.  The value was not exported. `chromelessFieldStyle` is a public `static const`
    with no matching instance field — the number field's chrome is deliberately
    NOT caller-overridable — and the reader dropped every such const on the
    reasoning that it is outside the override surface. True, and beside the point:
    it is still a value the widget paints. 95 constants across 48 components were
    dropped that way, so a builder that wanted one had no choice but to restate it
    by hand, which the literal guard then (correctly) refuses.

2.  Nothing asked whether the builder applied it. So: for every component whose
    `constants` carry a chromeless style, the builder must pass it to
    `suppressFieldChrome`. Checked by name so the value and its application stay
    tied — a builder could otherwise call the helper with some other component's
    const and read as compliant.

Net-new 0, no baseline. The population is what `components.json` says it is, so
the guard grows by itself when a fourth component states one.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[3]
DATA = ROOT / "tools/figma-token-sync/src/data/components.json"
BUILDERS = ROOT / "tools/figma-token-sync/src/components"
PHONE_STYLE = ROOT / "packages/coui_core/lib/src/component/contracts/phone_input/phone_input_style.dart"
# G16 의 기록 — 캔버스가 어떤 필드를 왜 그리지 않는지 이름과 사유로 적힌 곳.
UNREAD_ALLOWLIST = pathlib.Path(__file__).with_name(
    "figma_unread_fields_allowlist.json"
)
# 그중 "그 값이 앉을 정지 자세가 캔버스에 없다" 는 결론만. 자세가 없으면 합성된
# 인스턴스도 없고, 인스턴스가 없으면 벗겨 낼 크롬도 없다.
#
# `composition` 은 빠진다 — 자식 인스턴스가 **이미 그린다** 는 뜻이라 그 인스턴스의
# 크롬은 여전히 벗겨야 한다. `no-op` · `no-pixels` 도 빠진다 — 자세가 없다는
# 진술이 아니다. 남은 일(needs-pose 류)은 자세가 아직 오는 중이라 당연히 빠진다.
NO_CANVAS_INSTANCE = {
    "gesture",
    "motion-endpoint",
    "unreachable-default",
    "platform-absent",
}
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


def is_transparent(leaf: object) -> bool:
    """A colour leaf that paints nothing — no token, alpha byte 0."""
    if not isinstance(leaf, dict):
        return False
    if leaf.get("ref") is not None:
        return False
    return (leaf.get("argb") or 0) == 0


def is_zero_dim(leaf: object) -> bool:
    return isinstance(leaf, dict) and leaf.get("v") == 0


def is_chromeless_value(value: object) -> bool:
    """A nested style that states a boundary and states it as absent.

    Requires BOTH colour surfaces transparent AND a zero border width, so a slot
    that merely omits a fill is not read as a suppression instruction.
    """
    if not isinstance(value, dict):
        return False
    needed = ("backgroundColor", "borderColor", "borderWidth")
    if not all(k in value for k in needed):
        return False
    return (
        is_transparent(value["backgroundColor"])
        and is_transparent(value["borderColor"])
        and is_zero_dim(value["borderWidth"])
    )


def screaming(slug: str) -> str:
    """`phone_input` → `PHONE_INPUT`, the constant a builder binds it to."""
    return slug.upper()


def phone_alias_forwarded(doc: dict, source: str, core: str) -> list[str]:
    """Verify PhoneInput's number field instance and its Core default alias.

    Only the number field is chromeless: the outer container owns its
    chrome, and the field is `chromelessFieldStyle` with the dial code's
    type role laid on top. The dropdown's search field is the item picker's
    bare search row (`CoreItemPickerStyle.defaultSearchFieldStyle`), a
    composed `TextField` that paints its own chrome — it is not checked here.
    Equal chromeless values alone cannot prove that the composed field paints
    them, so the named number field has to apply it; comments cannot count
    as code.
    """
    errors: list[str] = []
    source = re.sub(r"/\*.*?\*/|//[^\n]*", "", source, flags=re.S)
    core = re.sub(r"/\*.*?\*/|//[^\n]*", "", core, flags=re.S)
    match = re.search(
        r"\bfunction\s+buildPhoneInput\s*\([^)]*\).*?(?=^function\s|\Z)",
        source,
        flags=re.S | re.M,
    )
    body = match.group(0) if match else ""
    flat = re.sub(r"\s+", " ", body)
    if not re.search(
        r"\bdefaultNumberFieldStyle\s*=\s*chromelessFieldStyle\s*(;|\.merge\()",
        core,
    ):
        errors.append("PhoneInput defaultNumberFieldStyle alias missing")

    phone = doc.get("phone_input", {})
    original = (phone.get("constants") or {}).get("chromelessFieldStyle")
    keys = ("backgroundColor", "borderColor", "borderWidth", "padding")
    for name in ("numberFieldStyle",):
        value = (phone.get("fields") or {}).get(name)
        if not is_chromeless_value(original) or not is_chromeless_value(value):
            errors.append(f"PhoneInput {name} is not chromeless")
        elif any(original.get(k) != value.get(k) for k in keys):
            errors.append(f"PhoneInput {name} differs from its default alias")

    patterns = {
        "field bucket": r"\bconst\s+f\s*=\s*PHONE_INPUT\.fields\s*;",
        "number instance": r"\bfield\.name\s*=\s*['\"]number field['\"]\s*;",
        "number application": r"\bsuppressFieldChrome\(\s*field\s*,\s*lk\s*,\s*f\.numberFieldStyle\s*\)",
    }
    errors.extend(f"PhoneInput {name} missing" for name, pat in patterns.items()
                  if not re.search(pat, flat))
    return errors


def main() -> int:
    if not DATA.exists():
        print(f"FAIL: {DATA} 가 없다 — export 를 먼저 돌려야 한다.")
        return 1

    # C1 — the helper must exist and must clear both surfaces. A repo where
    # `suppressFieldChrome` was reduced to clearing fills would pass every call
    # site while leaving the inner border, which is the visible half.
    if not _shared_sources():
        print("FAIL: tools/figma-token-sync/src 에 .ts 가 없다.")
        return 1
    helpers = _shared_sources()
    body_at = helpers.find("export function suppressFieldChrome(")
    if body_at < 0:
        print("FAIL: suppressFieldChrome 이 없다 — 이 가드가 요구하는 경로 자체가 없다.")
        return 1
    body = helpers[body_at : body_at + 3000]
    missing = [
        what
        for what, token in (("fills 제거", ".fills = []"), ("strokes 제거", ".strokes = []"))
        if token not in body
    ]
    if missing:
        print(f"FAIL: suppressFieldChrome 이 {' / '.join(missing)} 를 하지 않는다.")
        print("      안쪽 테두리가 남으면 '필드 안의 필드' 는 그대로 보인다 —")
        print("      눈에 보이는 쪽이 그쪽이다.")
        return 1

    doc = json.loads(DATA.read_text())["components"]
    sources = {f.name: f.read_text() for f in sorted(BUILDERS.rglob("*.ts"))}
    if len(sources) < 5:
        print(f"FAIL: 빌더 파일 {len(sources)}개 — 경로 추출이 깨졌다.")
        return 1
    joined = "\n".join(sources.values())

    # A chromeless forward is one whose stated chrome is ALL transparent / zero —
    # judged from the value, not only from a `chromeless*` name.
    #
    # Name-matching alone found three (`PhoneInput`, `ChipInput`, `Command`) and
    # missed `ObjectInput`, whose slot is called `fieldInputStyle` and states
    # exactly the same thing: transparent fill, transparent border, zero width,
    # zero padding. Its canvas had three bordered boxes inside one row. A guard
    # keyed on a naming convention only sees the components that followed it.
    # Collected through NESTED paths too, not just the top level of each bucket.
    #
    # `menu.fields.submenuStyle.popupStyle` is the merged panel a builder actually
    # applies, and it lives one level down. Reading only the top level found the raw
    # partial (`constants.submenuPopupStyle`) and not the merged value it becomes,
    # so the pair could never be recognised as one statement and the gate demanded
    # the partial be painted — a value no resolver produces.
    stated: list[tuple[str, str]] = []

    def collect(slug: str, prefix: str, node: object, depth: int) -> None:
        if not isinstance(node, dict) or depth > 3:
            return
        for name, value in sorted(node.items()):
            path = f"{prefix}.{name}"
            if is_chromeless_value(value) or (
                "chromeless" in name.lower() and prefix == "constants"
            ):
                stated.append((slug, path))
                continue
            collect(slug, path, value, depth + 1)

    for slug, comp in sorted(doc.items()):
        for bucket in ("constants", "fields"):
            collect(slug, bucket, comp.get(bucket) or {}, 1)

    if not stated:
        print(
            "FAIL: chromeless 상수를 가진 컴포넌트가 0개다 — constants 버킷이 비었거나"
            " 이름 규약이 바뀌었고, 어느 쪽이든 이 가드는 아무것도 비교하지 않는다."
        )
        return 1

    # Two ways count, because two exist and both are correct.
    #
    # `suppressFieldChrome(field, lk, <path>)` is the shared one. The other is the
    # explicit pair — `fillData(row, …backgroundColor)` + `borderData(row,
    # …borderColor, …borderWidth)` on the field row — which three builders were
    # already using, with a comment saying why they go through the emitters rather
    # than assigning `[]`: a designer who gives the forward a colour should get it
    # instead of an override that erases it.
    #
    # Crediting only the helper made this guard demand a rewrite of working code,
    # which is the accusing direction. It asks whether the forward REACHES the
    # canvas, not which function carried it.
    #
    # Matched by the value's own path either way, so the value and its application
    # stay tied — a builder cannot pass some other component's style and pass.
    flat = re.sub(r"\s+", " ", joined)
    applied: list[tuple[str, str]] = []
    pending: list[tuple[str, str]] = []
    for slug, name in stated:
        owner = screaming(slug)
        bucket, field = name.split(".", 1)
        # The path can be spelled three ways and all three are the same read:
        # fully (`PHONE_INPUT.fields.searchFieldStyle`), through a bucket alias
        # (`const f = PHONE_INPUT.fields;` then `f.searchFieldStyle`), or held in a
        # local (`const segment = f.segmentInputStyle;`). The builders use all
        # three, so matching only the first read them as unapplied.
        spellings = [re.escape(f"{owner}.{name}")]
        for m in re.finditer(
            r"const (\w+) = " + re.escape(f"{owner}.{bucket}") + r"\b", flat
        ):
            spellings.append(re.escape(f"{m.group(1)}.{field}"))
        path = "(?:" + "|".join(spellings) + ")"
        via_helper = re.search(r"suppressFieldChrome\([^;]*" + path, flat)
        held = None
        for spelling in spellings:
            alias = re.search(r"const (\w+) = " + spelling + r"\b", flat)
            if alias:
                held = alias.group(1)
                break
        def wrote(fn: str) -> bool:
            if re.search(fn + r"\([^;]*" + path + r"\b", flat):
                return True
            return held is not None and re.search(
                fn + r"\([^;]*\b" + re.escape(held) + r"\.", flat
            ) is not None
        via_pair = wrote("fillData") and wrote("borderData")
        if via_helper or via_pair:
            applied.append((slug, name))
        else:
            pending.append((slug, name))

    phone_constant = ("phone_input", "constants.chromelessFieldStyle")
    if phone_constant in stated:
        errors = phone_alias_forwarded(
            doc, sources.get("form-fields.ts", ""), PHONE_STYLE.read_text()
        )
        if errors:
            for error in errors:
                print(f"❌ {error}")
            return 1
        else:
            if phone_constant in pending:
                pending.remove(phone_constant)
            if phone_constant not in applied:
                applied.append(phone_constant)

    # A partial and the merged value built from it are ONE statement, and applying
    # either satisfies both.
    #
    # `CoreMenuStyle.submenuPopupStyle` is the box-less partial; the exporter's
    # nested overlay merges it over the parent's own panel defaults and publishes
    # the result at `submenuStyle.popupStyle`, which is the value the child menu's
    # resolver actually computes (they differ in exactly one field — the partial
    # says nothing about `spacing`, the merged value keeps the menu's 2). The
    # builder reads the merged path, correctly; demanding the raw partial too would
    # be demanding it paint a value no resolver produces.
    #
    # Judged on the chrome keys this gate is about, not on whole-value equality —
    # the two differ precisely in a key that is not chrome.
    chrome_keys = ("backgroundColor", "borderColor", "borderWidth", "padding")

    def chrome_of(slug: str, name: str) -> str:
        bucket, field = name.split(".", 1)
        node = (doc[slug].get(bucket) or {})
        for part in field.split("."):
            node = (node or {}).get(part) or {}
        return json.dumps({k: node.get(k) for k in chrome_keys}, sort_keys=True)

    # Only a NESTED applied path can stand in for an unapplied `constants` partial.
    #
    # Value equality alone was too loose and let a real gap through: `PhoneInput`
    # states the same chromeless chrome twice — `constants.chromelessFieldStyle` for
    # the number field and `fields.searchFieldStyle` for the dropdown's — and those
    # are two different instances needing two applications. Crediting one from the
    # other passed a repo where the search field's `borderData` had been deleted.
    #
    # The distinction is structural. A top-level slot (`fields.searchFieldStyle`) IS
    # a composed child's own forward, and it needs its own write. A nested one
    # (`fields.submenuStyle.popupStyle`) is a slot inside a slot — which is what a
    # merged partial becomes — and applying it is applying the partial.
    applied_chrome = {
        (slug, chrome_of(slug, name))
        for slug, name in applied
        if name.count(".") >= 2
    }
    unapplied = [
        (slug, name)
        for slug, name in pending
        if (slug, chrome_of(slug, name)) not in applied_chrome
    ]

    # A slot the canvas never draws has no instance to strip.
    #
    # The gate exists because a composed INSTANCE arrives with its own chrome. A
    # slot painted only away from every resting pose — a lens mounted for the
    # length of a transition — has no instance on the canvas at all, so there is
    # nothing to suppress and nothing to apply. That judgement is not made here:
    # it is read off G16's allowlist, where the field is named with the reason
    # the canvas draws no pose for it (and a reviewer sees it there). Judged on
    # the top-level field, because nothing inside an undrawn slot is drawn.
    unread_record = {}
    if UNREAD_ALLOWLIST.exists():
        unread_record = (
            json.loads(UNREAD_ALLOWLIST.read_text(encoding="utf-8")).get("fields")
            or {}
        )

    def drawn_nowhere(slug: str, name: str) -> bool:
        bucket, _, rest = name.partition(".")
        if bucket != "fields":
            return False
        entry = unread_record.get(f"{slug}.{rest.split('.')[0]}") or {}
        return entry.get("category") in NO_CANVAS_INSTANCE

    exempt = [f"{slug}.{name}" for slug, name in unapplied if drawn_nowhere(slug, name)]
    unapplied = [
        f"{slug}.{name}" for slug, name in unapplied if not drawn_nowhere(slug, name)
    ]

    if unapplied:
        print(f"❌ chromeless 를 진술하고 캔버스에 적용하지 않는 컴포넌트 {len(unapplied)}건:")
        for u in unapplied:
            print(f"   ✗ {u}")
        print()
        print("   빌더에서 그 필드 인스턴스에")
        print("   suppressFieldChrome(field, lk, <COMP>.<path>) 를 호출하거나,")
        print("   그 필드 row 에 fillData + borderData 로 같은 값을 쓴다 —")
        print("   합성된 TextField 는 자기 테두리와 채움을 들고 오므로, 밖의 상자가")
        print("   경계를 소유한다는 위젯의 진술이 캔버스에서는 '필드 안의 필드' 가 된다.")
        return 1

    print(
        f"✅ chromeless 합성 {len(stated) - len(exempt)}건 전부 캔버스에 적용됨 (하드 0) · "
        "suppressFieldChrome 이 fill·stroke 둘 다 제거."
    )
    for e in exempt:
        print(f"   ○ {e} — 캔버스에 인스턴스 없음 (G16 allowlist 의 결론)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
