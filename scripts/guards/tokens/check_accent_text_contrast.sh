#!/usr/bin/env bash
#
# Gate: the text chain does not offer any accent fill as a text colour.
#
# `check_contrast.dart` used to audit all seven accents as page text against
# WCAG 1.4.3's 4.5:1. Six cleared it — at 4.63:1 to 7.04:1, which is the
# whole problem: that file's own stated reason for auditing them was that
# the margin is thin enough a palette nudge would cross it. An affordance
# one brand-colour adjustment away from unreadable is not one to keep
# offering, so the fills are retired as text and the audit stops measuring
# them.
#
# Warning went first and for a different reason. It measured 1.82:1, and
# unlike the others that is not a tuning miss but structural: it is the one
# role whose `onWarning` is black rather than white, which is another way of
# saying its fill is light by design, because a warning is yellow. Darkening
# it until it reads as text on a near-white page breaks the black foreground
# it carries — the window where both hold is l ∈ [.305,.315], and a warning
# that dark is no longer yellow.
#
# For all seven the replacement is the same slot: `onXContainer`, which the
# audit does still measure on the page. Dropping the pairs is only honest
# while the affordance is really gone. That is what this guard is for.
# Without it the exclusion in `_pairs()` would be a way to delete seven
# findings rather than fix them, and a re-added getter would fail nothing —
# it would just render text at a ratio nobody re-measured.
#
# Web no longer has these getters, and the check below keeps them out.
# Flutter still carries them as @Deprecated: a deprecated getter still
# compiles, but the analyzer names every call site, and that is the whole
# difference from before, when this rendered silently. Removing a public
# getter follows the same deprecation window on both platforms — Web is
# consumed by tag too (.claude/rules/process/deprecation.md).
set -euo pipefail

cd "$(dirname "$0")/../../.."

readonly web_chain='packages/coui_web/lib/src/components/text/text_extension.dart'
readonly flutter_chain='packages/coui_flutter/lib/src/components/text/text.dart'

# Every accent fill the palette carries. Listed rather than derived: a role
# added to the palette should fail this guard until someone decides whether
# its fill is offered as text, and a derived list would quietly answer yes.
readonly roles=(primary secondary tertiary error success warning info)

# Checked rather than assumed: a moved or renamed chain file would make
# every grep below match nothing, and a guard that passes because it
# looked at no bytes is worse than no guard.
for f in "$web_chain" "$flutter_chain"; do
  if [ ! -f "$f" ]; then
    echo "❌ $f is missing — this guard reads it by path."
    echo "   If the text chain moved, point this guard at the new path."
    exit 1
  fi
done

# The replacement tone, named per role so the failure message tells the
# reader what to write instead rather than making them go look.
replacement_for() {
  case "$1" in
    primary) echo 'onPrimaryContainer' ;;
    secondary) echo 'onSecondaryContainer' ;;
    tertiary) echo 'onTertiaryContainer' ;;
    error) echo 'onErrorContainer' ;;
    success) echo 'onSuccessContainer' ;;
    warning) echo 'onWarningContainer' ;;
    info) echo 'onInfoContainer' ;;
  esac
}

failed=0

for role in "${roles[@]}"; do
  replacement=$(replacement_for "$role")

  # Web: the getter must not exist at all.
  if grep -qE "^\s*Text\s+get\s+${role}\s*=>" "$web_chain"; then
    echo "❌ $web_chain offers the ${role} fill as a text colour again."
    echo
    echo "   Accent fills are not text colours here — they sit close enough"
    echo "   to WCAG 1.4.3's 4.5:1 on the page that a palette adjustment"
    echo "   crosses it. Use \`${replacement}\` instead."
    echo
    failed=1
  fi

  # Flutter: the getter may exist, but only carrying its deprecation.
  if ! grep -qE "^\s*TextModifier\s+get\s+${role}\s*=>" "$flutter_chain"; then
    # Removed outright — stricter than this guard requires, so it passes.
    :
  elif ! ROLE="$role" perl -0777 -ne \
    'my $r = $ENV{ROLE};
     exit(/\@Deprecated\(.*?\)\s*TextModifier\s+get\s+\Q$r\E\s*=>/s ? 0 : 1)' \
    "$flutter_chain"; then
    echo "❌ $flutter_chain has a ${role} text getter that is not deprecated."
    echo
    echo "   The annotation is what makes the remaining call sites visible;"
    echo "   without it this is the original silent defect. Use"
    echo "   \`${replacement}\` instead."
    echo
    failed=1
  fi
done

if [ "$failed" -ne 0 ]; then
  exit 1
fi

echo "✅ No accent fill is offered as a text colour (${#roles[@]} roles)."
