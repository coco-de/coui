#!/usr/bin/env bash
# A component that mounts over the viewport needs a preview pane that is one.
#
# Most entries in `kDocsWideComponents` are there because content *wraps* in
# a half-width gallery pane — annoying, legible, recoverable. An overlay
# fails differently: it does not wrap, it is handed a wrong-sized world. The
# scrim covers a quarter of a row instead of a screen, the centring centres
# against that quarter, and the panel's max-width resolves against it.
#
# What that looked like when it was found: a modal opened in a gallery pane
# ~250px wide, its title broken across two lines, and its confirm button
# painted outside the pane it had just been centred in. Nine overlays were
# unregistered at that point — every one of them, because nobody had opened
# one in a gallery.
#
# So the rule is derived, not listed: any Web component that mounts an
# overlay portal must be registered wide. A list of today's overlays would
# go stale on the next one added, which is exactly how this got missed.
#
# The registered set may legitimately be a *superset*. A component that
# composes `Popover` rather than mounting a portal itself (select,
# autocomplete) has the same problem on the Flutter side, where the panel
# renders inside the embed's canvas and the canvas is the pane. This guard
# does not require those, and does not object to them.
#
# What it cannot see: whether the pane that results is tall enough, or
# whether the overlay actually fits once it has the width. Both are
# measured, not grepped.
set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

readonly WEB_COMPONENTS='packages/coui_web/lib/src/components'
readonly LAYOUT='docs_core/lib/shared/preview_layout.dart'
readonly CATALOG='docs_core/lib/shared/component_catalog.dart'

fail=0
checked=0

while IFS= read -r file; do
  # The component's own entry file, not a style or helper beside it.
  dir="$(dirname "$file")"
  [ "$(basename "$file" .dart)" = "$(basename "$dir")" ] || continue

  slug="$(basename "$dir" | tr '_' '-')"
  # Only components the docs actually publish a page for — an unpublished
  # component has no preview to be narrow.
  grep -q "slug: '$slug'" "$CATALOG" || continue

  checked=$((checked + 1))
  if ! grep -q "^  '$slug'," "$LAYOUT"; then
    echo "❌ $slug mounts an overlay portal and is not registered wide."
    echo "   Its gallery pane is its viewport, so a half-width pane gives"
    echo "   the panel a screen that is not one — add it to"
    echo "   kDocsWideComponents in $LAYOUT."
    fail=1
  fi
done < <(grep -rl 'OverlayPortal' "$WEB_COMPONENTS" --include='*.dart')

# The derivation is only a rule while it derives something. A rename of the
# portal type would empty this loop and leave the guard reporting a clean
# bill of health for a check it never ran — which is the same shape of
# silence that let the overlays go unregistered.
if [ "$checked" -eq 0 ]; then
  echo "❌ no published component matched 'OverlayPortal' — this guard is inert."
  echo "   The portal type or the component-file convention was renamed."
  exit 1
fi

if [ "$fail" -eq 0 ]; then
  echo "✅ overlay preview width — $checked published overlay(s) registered"
fi

exit "$fail"
