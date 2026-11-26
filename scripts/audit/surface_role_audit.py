#!/usr/bin/env python3
"""Which material role each surface receives, and where that answer comes from.

`surface_eligibility_triage.sh` answers *whether* a component is a surface.
This answers *which kind* — `functional` (floats over content) or `content`
(a face in the content layer) — and, when the component does not say so in
its own code, which composed primitive said it for it.

Three columns, deliberately separate:

  declared   the one word the component states about itself
             (`/// surface:functional` / `/// surface:content`)
  direct     a `CoreSurfaceRole.<x>` reached from that component's own code
             — its marker call, its `surfaceFor(...)`, or a role handed to
             the primitive it composes
  inherited  the role of the surface primitives it composes, resolved
             transitively (`select` -> `popover` -> `popup`)

The split is the point. Answering "which role" by reading the wiring alone
makes a surface that has not been wired yet indistinguishable from one that
does not float, and the gap this audit exists to show becomes empty by
construction — the same argument `core/theme-axis-composition.md` makes for
keeping the `surface:behind` declaration separable from `SurfaceBlur`.

It also answers a question that costs reviewers time: `select`,
`date_picker`, `color_picker` and `autocomplete` never name a role. They
open a `Popover`, which borrows `resolvePopup(...)`, and the role rides in
from there. A grep for the marker reports four holes that are not there.

Usage:
  scripts/audit/surface_role_audit.py            # human table
  scripts/audit/surface_role_audit.py --tsv      # platform/component/…
  scripts/audit/surface_role_audit.py --gap      # declared but unwired

Always exits 0 — this reports. The invariant is held by
`scripts/guards/structure/check_surface_role.sh`.
"""

from __future__ import annotations

import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# The primitives a component can inherit a surface from, mapped to the
# directory that owns each. Read as code references, so a doc comment
# saying `HoverCard(` is not a composition.
#
# `Popover` is here even though it draws no panel: on both platforms it
# borrows `resolvePopup(...)` output rather than mounting a `Popup`, so a
# component that composes a popover reaches the popup's role through it.
# That indirection is exactly the one the issue warns reviewers about.
PRIMITIVES = {
    "OutlinedContainer": "infra/outlined_container",
    "Popup": "infra/popup",
    "Card": "layout/card",
    "Dialog": "overlay/dialog",
    "Popover": "overlay/popover",
    "WindowPanel": "layout/window_panel",
}
# Resolver-level borrowing: Web components call these instead of mounting
# the component, and the marker rides out in the returned className.
RESOLVER_PRIMITIVES = {
    "resolveOutlinedContainer": "infra/outlined_container",
    "resolvePopup": "infra/popup",
    "resolveCard": "layout/card",
    "resolvePopover": "overlay/popover",
}

DECLARED_RE = re.compile(r"///\s*surface:(functional|content)\b")
# `defaultRole` counts as `content` — a primitive that takes the role as a
# parameter still *states* one, and the state it states when nobody
# overrides it is what its own declaration has to match. Reading only the
# two member names would make a surface look undeclared the moment it
# grew the parameter, which is backwards.
ROLE_RE = re.compile(
    r"(?:CoreSurfaceRole\.|"
    # Dot shorthand, which is what the lint asks for and therefore what
    # this code actually looks like. Matched only where the receiving
    # parameter names the role, so a bare `.content` belonging to some
    # other enum is not read as a surface declaration.
    r"(?:\brole\s*[:=]\s*|webSurfaceMarkerFor\(|surfaceFor\(\s*)\."
    r")(functional|content|defaultRole)\b"
)
# Any line whose first non-space is `//` — a `///` doc line and a plain
# `//` note both talk *about* code rather than being it, and a note
# reading "like the Flutter `OutlinedContainer`" is not a composition.
DOC_RE = re.compile(r"^\s*//")


def component_dirs(platform: str) -> list[str]:
    """Leaf directories holding a `.dart` file — found, not listed."""
    base = os.path.join(ROOT, f"packages/coui_{platform}/lib/src/components")
    found = set()
    for dirpath, _dirnames, filenames in os.walk(base):
        if dirpath == base:
            continue
        if any(f.endswith(".dart") for f in filenames):
            found.add(os.path.relpath(dirpath, base))
    return sorted(found)


def read_dir(platform: str, rel: str) -> tuple[str, str]:
    """Returns (all text, code-only text) for the `.dart` files in `rel`."""
    base = os.path.join(ROOT, f"packages/coui_{platform}/lib/src/components", rel)
    whole: list[str] = []
    code: list[str] = []
    for name in sorted(os.listdir(base)):
        if not name.endswith(".dart"):
            continue
        path = os.path.join(base, name)
        if not os.path.isfile(path):
            continue
        with open(path, encoding="utf-8") as handle:
            for line in handle:
                whole.append(line)
                if not DOC_RE.match(line):
                    code.append(line)
    return "".join(whole), "".join(code)


def camel(rel: str) -> str:
    leaf = rel.rsplit("/", 1)[-1]
    return "".join(part[:1].upper() + part[1:] for part in leaf.split("_"))


def scan(platform: str) -> dict[str, dict]:
    """One record per component directory."""
    out: dict[str, dict] = {}
    for rel in component_dirs(platform):
        whole, code = read_dir(platform, rel)
        own = camel(rel)

        declared = sorted(set(DECLARED_RE.findall(whole)))
        direct = sorted(
            {"content" if r == "defaultRole" else r
             for r in ROLE_RE.findall(code)}
        )

        composes: set[str] = set()
        for name, target in PRIMITIVES.items():
            if name == own or target == rel:
                continue
            if re.search(rf"(^|[^A-Za-z0-9_]){name}\(", code):
                composes.add(target)
        for name, target in RESOLVER_PRIMITIVES.items():
            if target == rel:
                continue
            if re.search(rf"(^|[^A-Za-z0-9_]){name}\(", code):
                composes.add(target)

        out[rel] = {
            "declared": declared,
            "direct": direct,
            "composes": sorted(composes),
        }
    return out


def resolve(records: dict[str, dict]) -> None:
    """Fill `inherited` / `via` by walking composition transitively."""

    def walk(rel: str, seen: frozenset[str]) -> tuple[list[str], list[str]]:
        record = records.get(rel)
        if record is None or rel in seen:
            return [], []
        if record["direct"]:
            return record["direct"], [rel]
        roles: set[str] = set()
        path: list[str] = []
        for target in record["composes"]:
            sub_roles, sub_path = walk(target, seen | {rel})
            if sub_roles:
                roles.update(sub_roles)
                path.append(" -> ".join([target, *sub_path[1:]]))
        return sorted(roles), path

    for rel, record in records.items():
        roles: set[str] = set()
        path: list[str] = []
        for target in record["composes"]:
            sub_roles, sub_path = walk(target, frozenset({rel}))
            if sub_roles:
                roles.update(sub_roles)
                path.append(" -> ".join([target, *sub_path[1:]]))
        record["inherited"] = sorted(roles)
        record["via"] = sorted(set(path))
        record["effective"] = record["direct"] or record["inherited"]


def rows() -> list[tuple[str, str, str, str, str, str]]:
    result = []
    for platform in ("flutter", "web"):
        records = scan(platform)
        resolve(records)
        for rel in sorted(records):
            record = records[rel]
            if not (record["declared"] or record["effective"]):
                continue
            result.append(
                (
                    platform,
                    rel,
                    "+".join(record["declared"]) or "-",
                    "+".join(record["direct"]) or "-",
                    "+".join(record["inherited"]) or "-",
                    ", ".join(record["via"]) or "-",
                )
            )
    return result


def main() -> int:
    mode = sys.argv[1] if len(sys.argv) > 1 else "report"
    data = rows()

    if mode == "--tsv":
        # The stable read for tooling: platform, component, declared,
        # direct, inherited, via. The human table's columns move.
        for row in data:
            print("\t".join(row))
        return 0

    if mode == "--gap":
        print("Declared a role, nothing wired yet — what the material has")
        print("still to reach:")
        for platform, rel, declared, direct, inherited, _via in data:
            if declared != "-" and direct == "-" and inherited == "-":
                print(f"  {platform:<8} {rel:<34} declared {declared}")
        return 0

    print(f"{'platform':<8} {'component':<34} {'decl':<11} {'direct':<11} "
          f"{'inherited':<11} via")
    for row in data:
        print(f"{row[0]:<8} {row[1]:<34} {row[2]:<11} {row[3]:<11} "
              f"{row[4]:<11} {row[5]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
