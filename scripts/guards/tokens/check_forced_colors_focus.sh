#!/usr/bin/env bash
#
# Gate: focus stays visible — and only focus stays visible — when the
# platform forces its own palette (Windows High Contrast and friends).
#
# Background. This repo loads Tailwind from the v3 Play CDN, pinned to an
# exact release (`https://cdn.tailwindcss.com/3.x.y` in
# docs_core/lib/site_head.dart). In v3,
# `outline-none` does NOT remove the outline — it compiles to
# `outline: 2px solid transparent; outline-offset: 2px`, on purpose, so a
# forced-colours pass has something to paint.
#
# That makes the class right on a focus state and wrong at rest:
#   - at rest, the forcing pass overrides `transparent`, so every element
#     reserving an outline wears a permanent ring and focus can no longer be
#     picked out — worse than losing the ring, because nothing looks special;
#   - meanwhile component rings are drawn with `box-shadow`, which forced
#     colours does not touch at all, so those can vanish outright.
#
# The correction lives in one `@media (forced-colors: active)` block at the
# app root rather than at the ~15 `outline-none` emit sites, because several
# of those are unconditional for their own good reasons (flipping
# `outline-style` on focus makes the theme cross-fade flash a text-coloured
# border). Confining it to the media query leaves normal rendering identical.
#
# This guard checks that block still exists and is still reachable — and
# that the Tailwind URL still names an exact v3 release. The unversioned URL
# follows whatever the CDN serves that day, so a release that changed what
# `outline-none` compiles to would void this whole fix with nothing in the
# repo moving; only a pinned version turns that change into a reviewed edit.
#
# Usage: ./scripts/guards/tokens/check_forced_colors_focus.sh
set -uo pipefail

ROOT='packages/coui_web/lib/src/coui_web.dart'
HEAD='docs_core/lib/site_head.dart'

status=0

if [ ! -f "$ROOT" ]; then
  echo "❌ App root not found: $ROOT (update this guard's path)."
  exit 1
fi

# 1. The media query exists, with both halves. One without the other is a
#    silent half-fix: rest-only loses the ring, focus-only keeps the
#    permanent ring on everything.
if ! grep -q '@media (forced-colors:active)' "$ROOT"; then
  echo "❌ No '@media (forced-colors:active)' block in $ROOT."
  status=1
fi
if ! grep -q ':not(:focus-visible){outline-style:none;}' "$ROOT"; then
  echo "❌ Missing the at-rest rule — every element that reserves a"
  echo "   transparent outline will show a permanent ring in forced colours."
  status=1
fi
if ! grep -q ':focus-visible{outline:2px solid' "$ROOT"; then
  echo "❌ Missing the focused rule — component rings ride box-shadow, which"
  echo "   forced colours does not paint, so focus would vanish."
  status=1
fi

# 2. The block is scoped to `.coui-root`, and EVERY app-root branch carries
#    that class. A branch without it (e.g. the no-background variant) skips
#    the whole correction with no other symptom.
root_divs=$(grep -cE "classes: '[^']*w-full[^']*\\\$defaultClasses'" "$ROOT" || true)
marked=$(grep -cE "classes: 'coui-root [^']*\\\$defaultClasses'" "$ROOT" || true)
if [ "$root_divs" != "$marked" ]; then
  echo "❌ $marked of $root_divs app-root branches carry '.coui-root'."
  echo "   An unmarked branch silently opts out of the forced-colours fix."
  status=1
fi

# 3. Tailwind is still the v3 CDN, pinned to an exact release. On v4
#    `outline-none` means `outline-style: none`, which inverts the reasoning
#    above — the fix would need revisiting rather than merely still being
#    present. The version segment is part of the check: an unpinned URL is
#    one CDN-side release away from the same inversion.
if [ -f "$HEAD" ]; then
  tw_urls=$(grep -oE "cdn\.tailwindcss\.com[^'\"]*" "$HEAD" || true)
  tw_unpinned=$(printf '%s\n' "$tw_urls" |
    grep -vE '^cdn\.tailwindcss\.com/3\.[0-9]+\.[0-9]+$' |
    sed '/^$/d' || true)
  if [ -z "$tw_urls" ]; then
    echo "❌ Tailwind source changed in $HEAD."
    echo "   This guard assumes the v3 Play CDN, where 'outline-none' reserves"
    echo "   a transparent outline. Re-derive the fix before updating this."
    status=1
  elif [ -n "$tw_unpinned" ]; then
    echo "❌ Tailwind CDN URL in $HEAD is not pinned to an exact v3 release:"
    printf '%s\n' "$tw_unpinned" | sed 's/^/     /'
    echo "   Use https://cdn.tailwindcss.com/3.<minor>.<patch> — the unversioned"
    echo "   URL can change what 'outline-none' compiles to without a commit."
    status=1
  fi
fi

if [ "$status" -eq 0 ]; then
  echo "✅ Forced-colours focus correction present and reachable."
fi

exit "$status"
