#!/usr/bin/env bash
#
# Gate: a modal surface keeps the background unreachable, on both platforms.
#
# The capability is one sentence: while a modal surface is open, the
# background is unreachable to assistive technology, unreachable by Tab, and
# Escape closes the surface. Each platform states it with its own primitive,
# and each primitive is one edit away from being deleted by someone who reads
# it as redundant:
#
#   Flutter — the barrier was a bare gesture surface. It swallowed pointers
#   and nothing else, so a screen-reader user could still walk into content
#   the sighted user could not reach. `BlockSemantics` is what makes it
#   modal, and it is what `ModalBarrier` itself uses.
#
#   Web — `inert` on the backdrop is all three properties at once: out of the
#   accessibility tree, out of the tab order, out of hit-testing. Removing it
#   leaves a page that still *looks* blocked because the barrier paints over
#   it.
#
# Both failures are invisible from the side that works: the component renders
# identically, its widget test passes, and the screenshot is unchanged.
#
# Usage: ./scripts/guards/structure/check_modal_containment.sh
set -uo pipefail

FLUTTER_BARRIER='packages/coui_flutter/lib/src/components/overlay/popover/popover_overlay.dart'
WEB_HOST='packages/coui_web/lib/src/overlay/overlay_host.dart'
WEB_CONTROLLER='packages/coui_web/lib/src/overlay/overlay_controller.dart'

for f in "$FLUTTER_BARRIER" "$WEB_HOST" "$WEB_CONTROLLER"; do
  if [ ! -f "$f" ]; then
    echo "❌ Not found: $f (update this guard's paths)."
    exit 1
  fi
done

fail=0

# --- Flutter: the modal barrier blocks semantics --------------------------
# Code lines only, and in one grep. The comment above the wrapper explains
# what `BlockSemantics` is for, so a plain word match stays green after the
# call itself is deleted — this check was written that way first and passed
# the injection it existed to catch. (A `grep | grep -q` pipeline is also
# wrong here: `-q` exits on the first match, the upstream grep takes SIGPIPE,
# and `pipefail` turns that into a failure on a clean tree.)
if ! grep -qE '^[^/]*BlockSemantics\(' "$FLUTTER_BARRIER"; then
  echo "❌ $FLUTTER_BARRIER: the modal barrier does not block semantics."
  echo "   Without BlockSemantics the barrier stops pointers only, and the"
  echo "   background stays in the accessibility tree."
  fail=1
fi

# The barrier has to be *wrapped* in it, not merely import it — check the
# helper that both barrier branches go through still exists and is used by
# both. One branch left unwrapped is the half-fix that reads as done.
wrapped=$(grep -cE '^[^/]*BlockSemantics\(' "$FLUTTER_BARRIER")
# One per barrier branch. A branch left unwrapped is the half-fix that
# reads as done.
if [ "$wrapped" -lt 2 ]; then
  echo "❌ $FLUTTER_BARRIER: only $wrapped barrier branch(es) wrapped."
  echo "   Both the consume-taps and the pass-through barrier need it —"
  echo "   they are the same surface with different pointer behaviour."
  fail=1
fi

# --- Flutter: Escape reaches a dismissible modal ---------------------------
# Either spelling — the lints require the dot shorthand inside
# `SingleActivator`, but a qualified key is equally a binding.
if ! grep -qE 'SingleActivator\((LogicalKeyboardKey)?\.escape\)' \
  "$FLUTTER_BARRIER"; then
  echo "❌ $FLUTTER_BARRIER: no Escape binding on the modal surface."
  fail=1
fi

# --- Web: the backdrop can go inert ---------------------------------------
if ! grep -q "'inert'" "$WEB_HOST"; then
  echo "❌ $WEB_HOST: the backdrop never emits \`inert\`."
  echo "   \`inert\` is the whole of Web modal containment — a11y tree, tab"
  echo "   order and hit-testing in one attribute."
  fail=1
fi

# `aria-hidden` on a subtree that still holds focusable content is an ARIA
# violation and is worse than nothing. It is the tempting wrong answer here
# precisely because it looks like the same thing.
if grep -q "'aria-hidden'" "$WEB_HOST"; then
  echo "❌ $WEB_HOST: the backdrop uses \`aria-hidden\`."
  echo "   On focusable content that is an ARIA violation; \`inert\` covers"
  echo "   it correctly."
  fail=1
fi

# --- Web: modality is tracked as a set, not a count ------------------------
# A counter double-decremented by a repeated unmount leaves the page inert
# for the rest of the session, with nothing on screen to explain why.
if ! grep -q '_modalTokens' "$WEB_CONTROLLER"; then
  echo "❌ $WEB_CONTROLLER: no modal-entry tracking."
  fail=1
elif grep -qE 'int _modal(Count|Depth)' "$WEB_CONTROLLER"; then
  echo "❌ $WEB_CONTROLLER: modality is tracked as a counter."
  echo "   Overlays stack and unmount can repeat; a set is idempotent."
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo "❌ Modal containment check failed."
  exit 1
fi

echo "✅ Modal containment holds on both platforms."
