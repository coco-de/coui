#!/usr/bin/env bash
# A surface that reads the active material must route its stroke through it.
#
# The material can say "my own edge treatment is the boundary"
# (`CoreSurfaceToken.drawsOwnEdge`), which makes a component's resting stroke
# a second boundary on the same pixels. Suppressing it is one call —
# `resolveSurfaceStroke` — and the failure mode when a resolver skips it is
# not a crash or a wrong colour. It is two surfaces drawing different glass
# under one preset, which reads as a rendering bug in whichever one you
# happen to look at second.
#
# That has already happened once here. The suppression was written inside
# `resolveOutlinedContainer`, and `Popup` — which resolves its own stroke —
# kept its border, so the panel behind every popover and menu disagreed with
# the card beside it. A test naming today's resolvers would not have caught
# it either, because the resolver that goes stale is the one added next.
#
# So the rule is a pairing, not a list: a resolver that reads the surface
# material AND resolves a border colour must call `resolveSurfaceStroke`.
# Resolvers that draw no stroke are not in scope — they have nothing to
# suppress, and requiring the call would be requiring a no-op.
#
# What this cannot see: whether the suppressed value reaches a pixel, and
# whether the width was decided before the suppression rather than after
# (the 1px-per-side trap). Both are held by tests. A guard and a render
# test do not substitute for each other.
set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

readonly SCOPE='packages/coui_flutter/lib/src/components'
readonly MATERIAL='resolveSurfaceSheen('
readonly SUPPRESS='resolveSurfaceStroke('

fail=0
checked=0

while IFS= read -r file; do
  # Only resolvers that read the material.
  grep -q "$MATERIAL" "$file" || continue
  # Only those that resolve a stroke of their own. `scheme.resolve(...)` on
  # something border-named is what "resolves its own stroke" looks like;
  # a resolver that forwards a style slot onward has nothing to suppress.
  # Whole-file, not line-by-line: `scheme.resolve(...)` is routinely
  # split across lines by the formatter, and a per-line pattern silently
  # skips exactly those. Two surfaces sat outside this guard for that
  # reason alone.
  # Fed by herestring, not a pipe. `tr < file | grep -q` lets `grep -q`
  # exit on its first match and kill the still-writing `tr` with SIGPIPE;
  # `pipefail` raises that death (141) into the pipeline's status and would
  # turn a match into a miss. The miss flows into `|| continue`, so the
  # file would be skipped and this guard would report a green it did not
  # earn.
  #
  # Exposure measured, firing NOT observed: it needs the bytes after the
  # match to exceed the kernel pipe buffer (16KB on macOS), and `button`
  # leaves 23,977 — but 20 runs on an unchanged tree all checked the same
  # 18 files. So this is the trap, pre-empted, rather than a bug caught in
  # the act. Written down because the next file to cross that line will
  # not announce itself.
  #
  # Same trap, same fix as check_document_index_installed.sh and
  # check_build_order_shared.sh. check_dimensional_scaling.sh carried the
  # pipe form too and there it DID fire — a compliant file reported as a
  # violation, 5 runs in 20 on an unchanged commit.
  _flat=$(tr '\n' ' ' < "$file")
  grep -qE 'scheme[[:space:]]*\.[[:space:]]*resolve\([^)]*[Bb]order' <<<"$_flat" || continue

  checked=$((checked + 1))
  if ! grep -q "$SUPPRESS" "$file"; then
    echo "❌ ${file#packages/coui_flutter/lib/src/components/}"
    echo "   reads the surface material and resolves its own stroke, but"
    echo "   never calls $SUPPRESS — under a material that draws its own"
    echo "   edge this surface keeps a border its siblings have dropped."
    fail=1
  fi
done < <(find "$SCOPE" -name '*_style.dart')

# The pairing is only a rule while something matches it. If a rename made
# either probe stop matching, every file would fall out of scope and this
# guard would report a clean bill of health for a check it never ran.
if [ "$checked" -eq 0 ]; then
  echo "❌ no resolver matched both probes — this guard is inert."
  echo "   Either '$MATERIAL' or the border-resolution shape was renamed."
  exit 1
fi

if [ "$fail" -eq 0 ]; then
  echo "✅ surface stroke suppression — $checked resolver(s) paired"
fi

exit "$fail"
