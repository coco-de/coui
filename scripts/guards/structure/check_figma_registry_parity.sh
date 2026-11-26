#!/usr/bin/env bash
#
# Gate: the Figma plugin's REGISTRY names a component that either doesn't
# exist in coui_core, or exists under a different name.
#
# Mint-by-name (#3737) makes this a live-identity bug, not a cosmetic one —
# the plugin finds a persistent Figma component by NAME and reuses it in
# place. A REGISTRY entry with a name coui_core doesn't have is either a
# phantom (the class was renamed/removed in code and nobody told the
# plugin) or a typo, and either way the plugin will happily keep minting a
# component nothing in the design system actually maps to.
#
# Three findings, three different rules — because they carry different risk:
#
#   phantom / mismatch — REGISTRY name has no matching coui_core class
#     (excluding the D1 allowlist below). net-new 0 — a fresh mismatch means
#     something drifted right now and should be fixed before merge, not
#     ratcheted for later.
#   uncovered — coui_core has the class, REGISTRY doesn't have the entry
#     (i.e. not yet built into the plugin). Ratchet — this is normal and
#     large today (~44 of 145); it only needs to not grow silently.
#
# Canonical population: `*_style.dart` under coui_core's contracts/ (one per
# component's Style class — architecture doc's own recommendation, "판독기가
# 실제로 여는 것"). NOT the component directory name and NOT a naive
# "capitalize every letter after a boundary" conversion — an earlier
# investigation transformed `InputOTP` into `input_o_t_p` by splitting on
# every capital letter, which then couldn't find `input_otp` at all. The
# rule here is simpler and doesn't have that failure mode: split the slug on
# `_` only, capitalize each segment, join — `input_otp` → `InputOtp`, which
# is also coui_flutter's actual class name (Effective Dart treats acronyms
# as ordinary words). A NAME_EXCEPTIONS map exists for the day a slug's real
# class name doesn't match that rule; it is empty today because none does.
#
# C1 (population floor): if either extraction collapses to a handful of
# entries, every comparison below would pass by having nothing to compare —
# silently. Both extractions assert a floor before anything else runs.
#
# D2 allowlist: a component whose chrome lives in a SIBLING's Style class, so
# there is no `*_style.dart` of its own to match. Kept separate from D1 because
# D1 is a one-reason list and folding a second reason into it would make the
# reason it documents false for one of its members.
#
# Builder fixtures: a set the plugin draws for its own use with no CoUI
# component behind it — `.Slot`, the empty-slot stand-in a swap default points
# at. Neither D1 nor D2 describes it: those are components whose NAME or STYLE
# lives elsewhere, and a fixture has no contract at all, so an allowlist entry
# would claim a sibling owns chrome nobody states. It is held by shape instead
# of by list — a name starting with `.` (Figma's "do not publish") declares
# `fixture: { description, checkedBy }`, the field sits on no other name, and
# `checkedBy` names the selftest that asserts what the builder draws: the
# comparison a contract would otherwise get from the fidelity sweep. The rule
# lives in figma_registry_names.py `--fixture-faults`; fixtures are left out of
# its names list, because every guard reading that list asks a component
# question a fixture has no answer to.
#
# D1 allowlist: components a now-rejected "Tag" taxonomy proposal wanted to
# rename, but the rename was never adopted (#3742) — Badge/Chip/ChipGroup/
# ChipInput/Indicator/AvatarBadge/Status keep their current names. Listed
# explicitly so a future stricter matcher doesn't relitigate a decision
# that's already been made.
#
# Usage: check_figma_registry_parity.sh [--update]

set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

readonly BASELINE="scripts/guards/structure/figma_registry_uncovered_baseline.txt"
readonly PLUGIN_DIR="tools/figma-token-sync/src/components"
readonly CONTRACTS_DIR="packages/coui_core/lib/src/component/contracts"

# D1 — intentionally excluded from the phantom/mismatch check (see header).
# Plain space list, not an associative array: bash 3.2 (macOS system /bin/bash
# — still the default on this platform) has no `declare -A`, and this script
# should run the same under that and under a modern bash in CI.
readonly D1_ALLOWLIST="Badge Chip ChipGroup ChipInput Indicator AvatarBadge Status"
# Why each one, all the same reason: a now-rejected "Tag" taxonomy proposal
# (v1.0 Chip ↔ v2.1 Tag) wanted to rename this family; the rename was never
# adopted (#3742), so these keep their current names. Listed explicitly so a
# future stricter matcher doesn't relitigate a decision that's already made.

# D2 — a REGISTRY name with no Style class of its own because a sibling owns its
# chrome. Not a phantom: the widget exists on both platforms and its builder
# reads real fields — from the sibling's Style.
#
#   ResizableTable — `resizable_table.dart` on both platforms, with its own
#   contract (`CoreResizableTableContract<W>`), but its three chrome fields
#   (`resizerThickness` / `resizerHoverColor` / `resizerDragColor`) are declared
#   on `CoreTableStyle`, and `buildResizableTable` reads them from there. An empty
#   `CoreResizableTableStyle` would satisfy this matcher while leaving the fields
#   where they are — a class that exists to be found, which is worse than the
#   exemption. This entry retires the day those three fields move to a Style of
#   their own; until then the pairing is stated here rather than discovered.
#
#   NavigationBarItem — `NavigationBarItem` on both platforms, with its own
#   contract (`CoreNavigationBarItemContract<W>`) — the destination
#   `NavigationBar` composes, and the designer's own Figma component that
#   `buildNavigationBar` composes as an INSTANCE per destination. It has no
#   Style of its own: its chrome slot is the bar's `CoreNavigationBarStyle`
#   (padding / radius / min-height / per-state colour), which both resolvers
#   read at the item's mode density (`buildNavigationBarItem` declares
#   `dataSlug: 'navigation_bar'` for the same reason). A Style class here
#   would exist only to be found, same as ResizableTable above.
#
#   DisclosureGroup — `DisclosureGroup` on both platforms, with its own contract
#   (`CoreDisclosureGroupContract<W>`), but its single chrome value
#   (`itemSpacing`) is declared on `CoreDisclosureStyle` and both resolvers read
#   it from there — the group holds no state and restyles nothing, so spacing
#   between siblings is the only thing it has to say. `buildDisclosureGroup`
#   declares `dataSlug: 'disclosure'` for that reason. An empty
#   `CoreDisclosureGroupStyle` would satisfy this matcher while leaving the
#   field where it belongs, which is the "class that exists to be found" the two
#   entries above already reject.
#
#   TabItem — the designer's own per-tab Figma component (`Variant` ×
#   `Selected` × `Focus` × `Disabled`), composed by `buildTabs` as six
#   INSTANCES per bar. It has no Dart widget and no Style of its own —
#   `CoreTabItem<W>` is a data value (`label` / `enabled` / `content`), not a
#   widget with a resolver — its chrome (`tabPadding`, the active indicator's
#   colour / radius / thickness, the active and inactive content colours,
#   `clickableStyle`) is entirely `CoreTabsStyle`'s, and the per-tab resolver is
#   `resolveTabsTab` on the bar's own Web resolver (`buildTabItem` declares
#   `dataSlug: 'tabs'` for the same reason). A Style class here would exist only
#   to be found, same as NavigationBarItem above.
#
#   CommandItem — the palette row, drawn as its own set so its per-row states
#   (`Active` × `State` × `Lines`) can be axes, and composed by `buildCommand`
#   as four INSTANCES per palette. It has no Dart widget and no Style of its
#   own — `CoreCommandItem<W>` is a data value (`value` / `label` / `overline`
#   / `shortcut` / `enabled`), and every pixel it paints is an `item*` field of
#   `CoreCommandStyle` resolved by `resolveCommand`. Same shape as TabItem
#   above; the fidelity selftest compares it through `Command`
#   (`kFragmentsComparedThroughParent`).
#
#   ThemeSwatch — the designer's own per-theme Figma component (`Size` ×
#   `State` × `Selected`, 24 members), composed by `buildThemeController` as
#   four INSTANCES per row. It has no public Dart widget and no Style of its
#   own — `_ThemeSwatch` is a private `StatefulWidget` inside
#   `theme_controller.dart` that reads the controller's own `resolved` bundle —
#   so every value it draws (`buttonSize` / `buttonRadius` / the border pairs /
#   `previewSize` / `pressedPreviewShrink` / `labelStyle` /
#   `labelGapStyle` / the three `disabled*` tokens) is `CoreThemeControllerStyle`'s
#   (`buildThemeSwatch` declares `dataSlug: 'theme_controller'` for the same
#   reason). A Style class here would exist only to be found, same as
#   NavigationBarItem above.
#
#   TableHeaderCell · TableCell — the table's header and body cells, drawn as
#   their own sets so a designer edits a cell's text or swaps a component into
#   it on an instance, and composed by `buildTable` / `buildResizableTable` as
#   one INSTANCE per cell. They have no Dart widget and no Style of their own —
#   `CoreTableCellData<W>` is a data value (`child` / `columnSpan` / `rowSpan`),
#   and every pixel a cell paints (`headerPadding` / `cellPadding`, the two text
#   styles, the two foregrounds) is `CoreTableStyle`'s, resolved by
#   `resolveTable` (both builders declare `dataSlug: 'table'`). Same shape as
#   TabItem above.
#
#   TreeItem · TabPaneTab — one node row of `Tree` and one tab of `TabPane`,
#   drawn as their own sets so a designer assembles a file tree or an editor
#   strip out of instances (the v2 kit's FileTreeItem · CodeTab), and composed
#   by `buildTree` / `buildTabPane` as one INSTANCE per row / tab. They have no
#   Dart widget and no Style of their own — `CoreTreeNode` and `CoreTabItem<W>`
#   are data values, and every pixel a row or a tab paints is
#   `CoreTreeStyle`'s / `CoreTabPaneStyle`'s, resolved by `resolveTree` /
#   `resolveTabPane` (the builders declare `dataSlug: 'tree'` / `'tab_pane'`).
#   Same shape as TabItem and TableCell above.
#
#   RichEditorSelectionToolbar — the toolbar `RichEditor` floats over selected
#   text, drawn as its own component because the designer drew it as one. It
#   is a part of the editor with no contract and no Style of its own: its
#   panel is `CoreRichEditorStyle.selectionToolbarPanelStyle` (forwarded to
#   the composed `Popup`) and its buttons are drawn from the same `toolbar*` /
#   `blockType*` slots the toolbar in the editor's box reads, resolved by
#   `resolveRichEditor` (the builder declares `dataSlug: 'rich_editor'`). A
#   Style class here would restate the editor's toolbar slots a second time.
readonly D2_ALLOWLIST="ResizableTable NavigationBarItem DisclosureGroup TabItem CommandItem ThemeSwatch TableHeaderCell TableCell TreeItem TabPaneTab RichEditorSelectionToolbar"

is_d2_exempt() {
  case " $D2_ALLOWLIST " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

is_d1_exempt() {
  case " $D1_ALLOWLIST " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

# ─── C1: extraction floors ───────────────────────────────────────────────────

# Both quote styles are accepted. The repo writes single quotes, but a single
# reformatted file is enough to make its entries invisible here — and the C1
# floor below can't catch that, because it only fires on *total* collapse. When
# one of eight builder files flipped to double quotes, exactly 7 of ~101 names
# dropped out and the guard reported them as newly-uncovered components: a
# false positive naming real, covered components, produced by a cosmetic edit.
# A guard whose failure text is wrong about *which* thing is broken sends the
# reader to the wrong file, so match what TypeScript accepts, not one style.
# Population comes from a python helper, not from grep. Both extractions it
# performs had to stop being line-based, and the reasons are in its docstring —
# figma_registry_names.py. Keeping it in a file rather than a heredoc also
# avoids bash 3.2's `$( )` quote-scanning bug, which turned a regex containing
# `['"]` into a syntax error reported 100 lines away from its cause.
figma_names=$(python3 scripts/guards/structure/figma_registry_names.py) || exit 1
figma_count=$(printf '%s\n' "$figma_names" | grep -c . || true)
if [ "$figma_count" -lt 80 ]; then
  echo "FAIL: Figma REGISTRY extraction collapsed ($figma_count names, expected ~100+)."
  echo "      grep pattern in this script no longer matches — fix before trusting any result below."
  exit 1
fi

# Slugs come from the *class* name, not the file name.
#
# A `*_style.dart` file does not always declare a component's Style: four of
# them declare `enum`s (`core_chip_selected_style.dart`,
# `core_chip_unselected_style.dart`, `core_frame_border_style.dart`,
# `core_outlined_container_border_style.dart`). Deriving from file names turned
# those into the component names `CoreChipSelected`, `CoreChipUnselected`,
# `CoreFrameBorder`, `CoreOutlinedContainerBorder` and reported them as
# components missing a Figma builder — four entries in the uncovered baseline
# that no builder could ever satisfy, because there is nothing to build.
#
# This is the same defect the field-coverage guard had (it derived a component
# slug from the file name and mis-attributed fields belonging to a second Style
# class in the same file). The fix is the same: ask the class.
#
# `implements CoreStyle` is the MAIN-Style marker (`core/style-contract.md`'s
# "Style 클래스 3 종"), so an auxiliary `CoreXxxVariantStyle` in the same file
# is not mistaken for a component either.
#
# A MAIN Style whose declaration carries `@Deprecated(...)` is not a coverage
# target. The class still compiles through its deprecation window
# (`process/deprecation.md`), but the design system draws its replacement now
# and the exporter no longer ships it — so a REGISTRY entry for it would mint a
# component the canvas is meant to retire. Counting it as "uncovered" would
# ask for exactly that builder back. The annotation's message may itself hold
# a call (`MockupBrowser(addressBar: null)`), so the match allows one level of
# nested parentheses.
#
# Extracted with python3, not `grep -oE`, because the declaration wraps:
#
#     class CoreOutlinedContainerStyle
#         implements CoreStyle<CoreOutlinedContainerStyle> {
#
# `grep` matches within one line, so a wrapped `implements` is invisible to it —
# a line-based version of this extraction found 134 of 143 and dropped nine real
# components (among them AspectRatioBox · MediaQueryVisibility ·
# OutlinedContainer · ResponsiveContainer · ResponsiveGrid ·
# ResponsiveRowColumn · ScrollViewInterceptor · ScrollableClient) out of the
# population. The C1 floor did not catch it: 134 clears a floor of 100. A floor
# only catches total collapse, and *partial* loss is the failure mode that
# actually happens here — so the floor is raised to just under the real count
# as well, and it is the count, not the file list, that has to be kept current.
style_slugs=$(
  python3 - <<'EXTRACT'
import re, glob
names = set()
for path in glob.glob(
    'packages/coui_core/lib/src/component/contracts/**/*.dart', recursive=True
):
    src = open(path, encoding='utf-8').read()
    retired = set(
        re.findall(
            r'@Deprecated\((?:[^()]|\([^()]*\))*\)\s*(?:@\w+(?:\([^()]*\))?\s*)*'
            r'class\s+(Core[A-Za-z0-9]+)Style\b',
            src,
            re.S,
        )
    )
    for m in re.finditer(
        r'class\s+(Core[A-Za-z0-9]+)Style\b[^{;]*?implements\s+CoreStyle', src, re.S
    ):
        if m.group(1) in retired:
            continue
        bare = m.group(1)[len('Core'):]
        slug = re.sub(r'(?<!^)(?=[A-Z])', '_', bare).lower()
        names.add(slug)
for n in sorted(names):
    print(n)
EXTRACT
)
slug_count=$(printf '%s\n' "$style_slugs" | grep -c . || true)
if [ "$slug_count" -lt 140 ]; then
  echo "FAIL: coui_core MAIN-Style class extraction collapsed ($slug_count slugs, expected 143+)."
  echo "      contracts/ layout changed, or this script is looking in the wrong place."
  exit 1
fi

# slug (snake_case) → PascalCase, segment-by-segment (never letter-by-letter).
to_pascal() {
  local slug="$1" out="" seg
  IFS='_' read -ra parts <<<"$slug"
  for seg in "${parts[@]}"; do
    out+="$(printf '%s' "${seg:0:1}" | tr '[:lower:]' '[:upper:]')${seg:1}"
  done
  printf '%s' "$out"
}

# Reserved for the day a real class name doesn't follow the segment rule —
# `case` rather than an associative array for the same bash-3.2 reason as
# D1_ALLOWLIST above. Empty today: see header for why InputOtp does NOT need
# an entry here (segment-capitalize already produces it correctly).
name_exception() {
  case "$1" in
    *) return 1 ;;
  esac
}

code_names=""
for slug in $style_slugs; do
  if exc=$(name_exception "$slug"); then
    code_names+="$exc"$'\n'
  else
    code_names+="$(to_pascal "$slug")"$'\n'
  fi
done
code_names=$(printf '%s' "$code_names" | LC_ALL=C sort -u)

# ─── phantom / mismatch — net-new 0 ──────────────────────────────────────────

mismatch=$(LC_ALL=C comm -23 <(printf '%s\n' "$figma_names") <(printf '%s\n' "$code_names"))
mismatch_real=""
for name in $mismatch; do
  is_d1_exempt "$name" && continue
  is_d2_exempt "$name" && continue
  mismatch_real+="$name"$'\n'
done
mismatch_real=$(printf '%s' "$mismatch_real" | sed '/^$/d')

if [ -n "$mismatch_real" ]; then
  echo "FAIL: Figma REGISTRY name(s) with no matching coui_core *_style.dart class:"
  printf '%s\n' "$mismatch_real" | sed 's/^/    /'
  echo "    — either the class was renamed/removed in code (rename it in the plugin"
  echo "      too, via src/renames.ts SET_RENAMES so identity survives — see #3742),"
  echo "      or it's a genuine phantom (retire it via src/renames.ts RETIRED — #3744),"
  echo "      or a sibling owns its Style and it belongs in D2_ALLOWLIST with a reason,
      or it's D1-exempt and belongs in this script's D1_ALLOWLIST with a reason."
  exit 1
fi

# ─── uncovered — ratchet ─────────────────────────────────────────────────────

uncovered=$(LC_ALL=C comm -13 <(printf '%s\n' "$figma_names") <(printf '%s\n' "$code_names"))

if [ "${1:-}" = "--update" ]; then
  {
    echo "# coui_core components with no Figma REGISTRY entry yet."
    echo "# Ratchet: net-new entries fail CI; this list may only shrink."
    printf '%s\n' "$uncovered"
  } | sed '/^$/d' > "$BASELINE"
  echo "baseline updated ($(printf '%s' "$uncovered" | grep -c . || true) uncovered entries)"
  exit 0
fi

known=$(grep -vE '^#|^$' "$BASELINE" 2>/dev/null | LC_ALL=C sort -u)
netnew=$(LC_ALL=C comm -23 <(printf '%s\n' "$uncovered" | sed '/^$/d') <(printf '%s\n' "$known" | sed '/^$/d'))

if [ -n "$netnew" ]; then
  echo "FAIL: newly-uncovered coui_core component(s) — not in the Figma REGISTRY, and not in the known baseline:"
  printf '%s\n' "$netnew" | sed 's/^/    /'
  echo "    — either add it to tools/figma-token-sync (a builder + REGISTRY entry),"
  echo "      or run this script with --update if leaving it uncovered for now is intentional."
  exit 1
fi

# ─── data slug resolves · fragment scope covers its reads — net-new 0 ─────────
#
# Every entry resolves to a slug — `entry.dataSlug ?? slugOfName(entry.name)` —
# and three consumers read it: the fidelity report compares the drawn set
# against that slug's stated fields, the content hash feeds it so an entry
# redraws when its data changes, and the run places the page by the section
# that slug declares. A slug naming nothing fails none of them loudly: fidelity
# says "no entry in components.json" and moves on, the hash folds `null` and
# stays stable, the page falls back to the entry's own section. The set keeps
# being drawn, and nothing verifies it.
#
# A fragment (D2: a sibling owns its Style) additionally declares `dataFields`
# — the parent fields it reads. `scopeToFragment` strips everything else before
# the checks run, so a field the builder reads through `f.` or a size-row alias
# but the list does not name is a value painted and never compared. Both are
# provable today and one line to fix, so neither is a ratchet.
unresolved=$(python3 "$(dirname "$0")/figma_registry_names.py" --unresolved-slugs) || exit 1
scope_drift=$(python3 "$(dirname "$0")/figma_registry_names.py" --fragment-scope-drift) || exit 1
fixture_faults=$(python3 "$(dirname "$0")/figma_registry_names.py" --fixture-faults) || exit 1

if [ -n "$unresolved" ]; then
  echo "FAIL: REGISTRY entr(y|ies) whose data slug names nothing in components.json:"
  printf '%s\n' "$unresolved" | sed 's/^/    /'
  echo "    — the fidelity report cannot judge these sets, and their content hash"
  echo "      folds null. If a sibling owns the chrome, declare that sibling and the"
  echo "      fields read from it: \`dataSlug: '<sibling>', dataFields: [...]\`."
  echo "    — if instead the component should own its Style, add the"
  echo "      \`*_style.dart\` contract and re-export components.json."
  exit 1
fi

if [ -n "$scope_drift" ]; then
  echo "FAIL: fragment(s) whose builder reads a parent field outside its dataFields:"
  printf '%s\n' "$scope_drift" | sed 's/^/    /'
  echo "    — add the field (or its prefix) to that entry's \`dataFields\`; a read the"
  echo "      list does not cover is stripped before the fidelity checks see it."
  exit 1
fi

# ─── builder fixtures — net-new 0 ─────────────────────────────────────────────
if [ -n "$fixture_faults" ]; then
  echo "FAIL: builder fixture(s) breaking their rule:"
  printf '%s\n' "$fixture_faults" | sed 's/^/    /'
  echo "    — a name starting with \`.\` is a builder fixture: declare"
  echo "      \`fixture: { description, checkedBy }\` after \`name:\`, keep \`dataSlug\`"
  echo "      off it, and name a selftest that asserts what it draws. A published"
  echo "      name is a component, not a fixture — drop \`fixture\` or add the \`.\`."
  exit 1
fi
fixture_count=$(python3 "$(dirname "$0")/figma_registry_names.py" --fixtures | grep -c . || true)

d1_count=$(printf '%s\n' $D1_ALLOWLIST | grep -c . || true)
d2_count=$(printf '%s\n' $D2_ALLOWLIST | grep -c . || true)
echo "PASS: 0 phantom/mismatch, $(printf '%s' "$known" | grep -c . || echo 0) known-uncovered (ratchet), D1-exempt: $d1_count, D2-exempt: $d2_count, builder fixtures: $fixture_count"
exit 0
