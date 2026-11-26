#!/usr/bin/env bash
#
# Gate: the Flutter and Web localization interfaces expose the same members.
#
# `cross-platform/localization.md` requires that if one platform reads a
# string from localizations, its twin reads the equivalent — otherwise the
# same component is translated on one platform and hardcoded on the other.
#
# That divergence is unusually quiet: the hardcoded side still renders
# perfectly, it just renders in English forever, so neither a render test nor
# a screenshot catches it. The only reliable signal is that the member exists
# on one interface and not the other, which is exactly what this compares.
#
# Locale classes extend the interfaces directly (never the Default*), so a
# member missing from a *locale* is already a compile error. This guard
# covers the other half — a member missing from the opposite *platform*.
#
# Usage: ./scripts/guards/structure/check_localization_parity.sh
set -uo pipefail

# ratchet 기준값은 파일에 산다 — 이 스크립트 안의 상수가 아니다.
# 상수였을 때는 한 글자(`=0` → `=1`)가 위반 한 칸을 열었고, 그 한 글자가
# 통과 여부를 결정하는 **바로 그 PR 안에** 있었다. 파일이면 CODEOWNERS 의
# `/scripts/guards/**/*baseline*` 과 check_codeowners_ratchet_coverage.sh 가
# 그 diff 를 본다. 읽기 실패는 fail-closed 다 (lib/ratchet.sh 참조).
_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/ratchet.sh
. "$_GUARD_DIR/../lib/ratchet.sh"


FLUTTER_IFACE='packages/coui_flutter/lib/src/components/locale/coui_localizations.dart'
WEB_IFACE='packages/coui_web/lib/src/components/locale/coui_localizations/coui_localizations.dart'

for f in "$FLUTTER_IFACE" "$WEB_IFACE"; do
  if [ ! -f "$f" ]; then
    echo "❌ Localization interface not found: $f"
    echo "   (Did it move? Update this guard's paths — a missing file must"
    echo "    not read as parity.)"
    exit 1
  fi
done

# Abstract members only: `String get x;` / `String x(...);` declarations that
# end in a semicolon, not the `=> '...'` implementations further down.
members() {
  grep -oE '^\s+String (get )?[a-zA-Z]+(\([^)]*\))?;' "$1" \
    | grep -oE '(get )?[a-zA-Z]+(\([^)]*\))?;' \
    | sed -E 's/^get //; s/\(.*//; s/;//' \
    | sort -u
}

flutter_only=$(comm -23 <(members "$FLUTTER_IFACE") <(members "$WEB_IFACE"))
web_only=$(comm -13 <(members "$FLUTTER_IFACE") <(members "$WEB_IFACE"))
count=$(members "$FLUTTER_IFACE" | wc -l | tr -d ' ')

status=0

if [ -n "$flutter_only" ]; then
  echo "❌ Present on Flutter but missing from Web:"
  echo "$flutter_only" | sed 's/^/     /'
  status=1
fi

if [ -n "$web_only" ]; then
  echo "❌ Present on Web but missing from Flutter:"
  echo "$web_only" | sed 's/^/     /'
  status=1
fi

if [ "$status" -ne 0 ]; then
  echo "   Add the member to both interfaces. A string localised on one"
  echo "   platform and hardcoded on the other still renders fine — in"
  echo "   English, forever — so nothing else catches this."
  exit "$status"
fi

# A guard that finds nothing because it parsed nothing is worse than none.
if [ "$count" -lt 50 ]; then
  echo "❌ Only $count members parsed — the extraction is probably broken"
  echo "   rather than the interfaces being tiny. Check the grep above."
  exit 1
fi

# ── Consumption parity ─────────────────────────────────────────
#
# The header above promises that "if one platform reads a string from
# localizations, its twin reads the equivalent" — and the check above
# compares interface members only. Both interfaces can agree perfectly
# while a component reads five of those members on one platform and a
# literal on the other — the interface says all five exist, but says
# nothing about which platform actually calls them.
#
# That divergence renders correctly. It renders correctly in English,
# forever, and only a locale switch shows it — so nothing else catches
# it either.
#
# Two things make the count below wider than "does this component read
# the locale at all":
#
#   Counted per MEMBER, not per component. A component that reads four
#   of five members on both platforms and drops the fifth on one is a
#   real gap — counting it as "1 divergent component" the way a coarser
#   pass would hides four-fifths of what is actually missing.
#
#   Every file in the component directory, not just `{name}/{name}.dart`.
#   A barrier label or a close button routinely lives in a sibling file
#   (`drawer_backdrop.dart`, `toast_overlay.dart`) — a check that only
#   opens the entry file never sees it, and a hardcoded barrier label is
#   exactly the kind of string that sits there.
#
# Both a direct call (`CoUILocalizations.of(context).x`) and a call
# through a locally aliased variable (`final l10n = ...of(context); ...
# l10n.x`) count as a read — the alias is how most of this codebase
# actually reads the interface, and a check that only matched the
# direct form would miss most real usage, not just the sibling-file kind.
#
# Ratcheted rather than failed: closing this in one pass is a sweep, and
# a guard that is red on arrival gets disabled. What must not happen is
# a new one.
#
CONSUMPTION_BASELINE=$(ratchet_int "$_GUARD_DIR/localization_consumption_baseline.txt") || exit 1

readonly alias_re='l10n|locale|localization|localizations'

# Members a file reads: the direct-call form, plus anything reached
# through a locally aliased variable of that file's own declaring.
#
# Matched against the file with its newlines folded away, not line by
# line. `dart format` breaks a call that overruns the page width as
#
#   CoUILocalizations.of(
#     context,
#   ).carouselPreviousSlide
#
# and a line-oriented grep sees three lines none of which is a read. The
# member then counts as "the other platform only" while both platforms
# read it — eight of the twenty-one parked entries were exactly that, and
# the same blindness HID three real gaps (a member unseen on both sides
# agrees with itself). Which side a formatter happens to wrap is not a
# fact about localization.
members_in_file() {
  local f="$1" class_re="$2" flat
  flat=$(tr '\n' ' ' < "$f")
  {
    printf '%s\n' "$flat" \
      | grep -oE "${class_re}\.of\([^)]*\)[[:space:]]*\.[a-zA-Z]+" \
      | sed -E 's/.*\.//'
    printf '%s\n' "$flat" \
      | grep -oE "(final|var) (${alias_re})[[:space:]]*=[[:space:]]*${class_re}\.of\([^)]*\)[[:space:]]*;" \
      | sed -E 's/^(final|var) //; s/[[:space:]]*=.*//' \
      | while read -r alias; do
          printf '%s\n' "$flat" \
            | grep -oE "\b${alias}[[:space:]]*\.[a-zA-Z]+" | sed -E 's/.*\.//'
        done
  } | sort -u | grep -v '^$'
}

# Genuine component directories only — an entry file `{name}/{name}.dart`
# at least two levels below `components/` (`{category}/{name}/{name}.dart`).
# A one-level match, such as the `form` category's own `form.dart`
# (unrelated form-infrastructure, not the `Form` component, which lives
# at `form/form/form.dart`), is category-level plumbing that happens to
# share its folder's name — matching it here would fold that folder's
# other loose files into a "form" component directory that was never
# really theirs.
component_dir_of() {
  local root="$1"
  find "$root" -mindepth 3 -type f -name '*.dart' \
    | while read -r f; do
        [ "$(basename "$f" .dart)" = "$(basename "$(dirname "$f")")" ] \
          && dirname "$f"
      done
}

web_dirs=$(component_dir_of packages/coui_web/lib/src/components)

# Portable pairing, not an associative array: bash on macOS ships 3.2,
# which has none, and this repo's guards run wherever that is true too.
web_dir_for() {
  local name="$1"
  printf '%s\n' "$web_dirs" | while read -r d; do
    [ "$(basename "$d")" = "$name" ] && printf '%s\n' "$d" && break
  done
}

divergent_report=''
divergent_total=0
while read -r fdir; do
  name="$(basename "$fdir")"
  wdir=$(web_dir_for "$name")
  [ -n "$wdir" ] || continue

  f_members=$(find "$fdir" -maxdepth 1 -name '*.dart' | while read -r f; do
    members_in_file "$f" 'CoUILocalizations'
  done | sort -u | grep -v '^$' || true)
  w_members=$(find "$wdir" -maxdepth 1 -name '*.dart' | while read -r f; do
    members_in_file "$f" 'CouiLocalizations'
  done | sort -u | grep -v '^$' || true)
  [ -z "$f_members" ] && [ -z "$w_members" ] && continue

  f_only=$(comm -23 <(printf '%s\n' "$f_members" | grep -v '^$' || true) \
                     <(printf '%s\n' "$w_members" | grep -v '^$' || true))
  w_only=$(comm -13 <(printf '%s\n' "$f_members" | grep -v '^$' || true) \
                     <(printf '%s\n' "$w_members" | grep -v '^$' || true))
  f_count=$(printf '%s\n' "$f_only" | grep -c . || true)
  w_count=$(printf '%s\n' "$w_only" | grep -c . || true)
  diverge=$((f_count + w_count))

  if [ "$diverge" -gt 0 ]; then
    entry="  $name:"
    [ "$f_count" -gt 0 ] && entry="$entry
    flutter-only  $(printf '%s\n' "$f_only" | tr '\n' ' ')"
    [ "$w_count" -gt 0 ] && entry="$entry
    web-only      $(printf '%s\n' "$w_only" | tr '\n' ' ')"
    divergent_report="$divergent_report$entry
"
    divergent_total=$((divergent_total + diverge))
  fi
done < <(component_dir_of packages/coui_flutter/lib/src/components)

echo "Members read on one platform only: $divergent_total" \
     "(baseline $CONSUMPTION_BASELINE)"

if [ "$divergent_total" -gt "$CONSUMPTION_BASELINE" ]; then
  printf '%s' "$divergent_report"
  echo "❌ A component reads a localized string on one platform and a"
  echo "   literal on the other. It renders fine — in English — so only"
  echo "   a locale switch shows it."
  exit 1
fi

if [ "$divergent_total" -lt "$CONSUMPTION_BASELINE" ]; then
  echo "   ✅ below baseline — lower the value in"
  echo "      scripts/guards/structure/localization_consumption_baseline.txt to $divergent_total"
  echo "      and update the itemized list in that same file."
else
  echo "   ✅ at baseline (no net-new)."
fi

echo "✅ Localization interfaces agree ($count members on both platforms)."
