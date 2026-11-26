#!/usr/bin/env bash
#
# Gate: no unsourced z-index literal in coui_web — every Tailwind `z-N`
# class and every raw `'z-index': 'N'` inline declaration must be
# interpolated from a `CoreZIndex` reference, never a bare digit typed
# directly into the string.
#
# Why this exists (#3775): `--z-*` CSS variables and the Tailwind `zIndex`
# config were 0 for years, so every component that needed stacking order
# invented its own raw number. draggable_panel / scaffold / dropdown_menu /
# menubar / popover / drawer / tooltip / hover_card / dialog / context_menu /
# navigation_menu all landed on `z-40` or `z-50` independently — several
# semantically different layers (backdrop vs. modal vs. popover vs.
# tooltip) collapsed onto the *same* numeric level purely by coincidence,
# so "which overlay wins when two meet" depended on DOM mount order, not
# design intent. A `CoreZIndex`-sourced reference can't silently collide
# this way, because every semantic layer has its own named rung
# (`z0`..`z100`) and the source text itself records which one a component
# claims — this guard keeps a bare digit from creeping back in.
#
# What this guard does NOT flag (by design, not by omission):
#   - `CoreZIndex.z0 + N` local-offset arithmetic (sortable / table /
#     hero_section / indicator / calendar) — sourced from the token, just
#     not a registered `zIndex` scale step, so it emits inline CSS rather
#     than a Tailwind class. The digit in the source is never a bare
#     literal; it's always `z0 + <small offset>`.
#   - window.dart's `_kAlwaysOnTopZ` / `_kNormalWindowZ` / `_kSnapGhostZ` /
#     `_kSnapBarZ` / `_kDraggingWindowZ` — documented (window.dart:56-62)
#     as living inside their own CSS `isolation: isolate` stacking
#     context, so they never compete with `CoreZIndex`'s page-level ladder
#     and forcing them onto it would collide with `CoreZIndex.z100`
#     (1100) at the `_kAlwaysOnTopZ + 900`-equivalent range. Named,
#     documented constants — not bare inline digits.
#   - prose in `//`/`///` comments describing the *rendered* value (e.g.
#     "`z-50`" in a DOM-shape doc comment) — these are accurate
#     descriptions of what the token resolves to, not a second source of
#     truth a browser reads.
#
# Method: grep two patterns across `packages/coui_web/lib`, both restricted
# to non-comment lines (a line whose only content, after leading
# whitespace, is `//`/`///` prose is excluded — this is a description of
# a rendered value, not code the browser executes):
#   1. A Tailwind class literal `z-<digits>` NOT preceded by `${` (i.e.
#      not part of a `z-${CoreZIndex.scale.zN}` interpolation).
#   2. A raw `'z-index': '<digits>` (or `"z-index": "<digits>`) inline
#      declaration where the value starts with a bare digit rather than
#      `$`.
#
# Usage:
#   ./scripts/guards/tokens/check_z_index_unsourced.sh
set -uo pipefail

LIB_DIR="packages/coui_web/lib"
status=0

strip_comment_only_lines() {
  # A line is comment-only if, after leading whitespace, it starts with
  # `//` (covers both `///` doc comments and plain `//` comments).
  perl -ne 'print unless /^[^:]+:\d+:\s*\/\//'
}

echo "── Tailwind z-<digit> class literals (unsourced) ──"
class_hits=$(
  grep -rnE "'z-[0-9]+'|\"z-[0-9]+\"|\bz-[0-9]+\b" "$LIB_DIR" --include='*.dart' \
    | grep -vE '\bz-\$\{|--z-[0-9]' \
    | strip_comment_only_lines
)
if [ -n "$class_hits" ]; then
  echo "❌ Unsourced z-<digit> Tailwind class literal(s):"
  echo "$class_hits" | sed 's/^/     /'
  echo "   → interpolate from CoreZIndex.scale.zN (page-level rung) or"
  echo "     CoreZIndex.z0 + N via inline 'z-index' (local, off-scale)"
  status=1
else
  echo "✅ 0 unsourced z-<digit> Tailwind class literals."
fi

echo "── raw 'z-index': '<digit>' inline literals (unsourced) ──"
inline_hits=$(
  grep -rnE "'z-index':\s*'[0-9]|\"z-index\":\s*\"[0-9]" "$LIB_DIR" --include='*.dart' \
    | strip_comment_only_lines
)
if [ -n "$inline_hits" ]; then
  echo "❌ Unsourced raw 'z-index' literal(s):"
  echo "$inline_hits" | sed 's/^/     /'
  echo "   → interpolate from CoreZIndex (e.g. '\${CoreZIndex.z0 + N}')"
  status=1
else
  echo "✅ 0 unsourced raw 'z-index' literals."
fi

exit $status
