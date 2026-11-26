#!/bin/bash
# Contract verification script for CoUI unified API.
# Ensures coui_core, coui_flutter, and coui_web maintain API consistency.
#
# Usage: ./scripts/verify_contracts.sh
#
# Checks 5-8 guard the Resolver/Resolved Style Contract (Epic #1579,
# docs/tech-spec-resolver-style-contract.md):
#   [5/8] re-introduction of mergedStyle (cleaned up by S5)
#   [6/8] re-introduction of build-time merge chains (S4/S6)
#   [7/8] re-introduction of String typography / raw radius in size_tokens (S7)
#   [8/8] field-completeness in == / hashCode / copyWith / merge bodies
#         (CoreXxxStyle hand-written boilerplate — Issue #1592)
#
# Checks 9-13 guard the PoC #1601 token-resolution + interface learnings:
#   [9/13]  Flutter widget resolver bare `.toValue()` on chrome colour
#           (token → kDefaultLightCoreColorArgb light fallback — dark mode
#           ignored). Required: scheme.resolve(...).
#   [10/13] CoreColor(0x00000000) literal in contracts — use
#           CoreColor.transparent shared sentinel.
#   [11/13] Platform style file directly references a common-token class
#           (CoreSpace / CoreFontSize / CoreFocusRing / CoreDuration /
#           CoreBorderWidth / CoreRadius) — must go through
#           CoreXxxStyle.defaultYyy instead.
#   [12/13] Web Resolved* must `implements WebResolvedChrome` (single
#           root entry point) and avoid bare `String? xxxClassName` /
#           `Styles? xxxInlineStyles` flat field pairs (group into
#           `WebElementChrome xxx`).
#   [13/13] Core ↔ Core enum mapping must live as `enum.toY()` source-side
#           method, not file-local `_mapXxx()` / `extension on CoreXxx`
#           inside platform _style.dart.
#   [14/14] Web `_style.dart` must not name local CSS-rendered chrome
#           variables with the `Css` / `Rem` / `Token` suffix
#           (`borderRadiusCss`, `borderRadiusRem`, `paddingCss`, ...).
#           Variables should match the source field name so the resolved
#           chrome reflects `merged.borderRadius` / `merged.padding`
#           directly (Epic #1599 / #2201).
#
# Migration mode (#1601 PoC): checks 9, 11, 12, 13 fail only for the
# PoC trio (button / alert / card). All other components emit a WARN
# line listing the violation so the next sweep PR sees the inventory.
# As each component migrates, add it to the COMPONENTS_ENFORCED list.
# Check 10 (CoreColor literal in contracts) is project-wide ERROR.
# Check 14 (chrome variable naming) is project-wide ERROR.

set -e

echo "=== CoUI Contract Verification ==="
echo ""

ERRORS=0

# 1. Verify coui_core compiles cleanly
echo "[1/8] Analyzing coui_core..."
if dart analyze packages/coui_core 2>&1 | grep -q "error -"; then
  echo "  FAIL: coui_core has analysis errors"
  dart analyze packages/coui_core 2>&1 | grep "error -"
  ERRORS=$((ERRORS + 1))
else
  echo "  PASS: coui_core clean"
fi

# 2. Verify coui_flutter compiles cleanly
echo "[2/8] Analyzing coui_flutter..."
if dart analyze packages/coui_flutter 2>&1 | grep -q "error -"; then
  echo "  FAIL: coui_flutter has analysis errors"
  dart analyze packages/coui_flutter 2>&1 | grep "error -"
  ERRORS=$((ERRORS + 1))
else
  echo "  PASS: coui_flutter clean"
fi

# 3. Verify coui_web compiles cleanly
echo "[3/8] Analyzing coui_web..."
if dart analyze packages/coui_web 2>&1 | grep -q "error -"; then
  echo "  FAIL: coui_web has analysis errors"
  dart analyze packages/coui_web 2>&1 | grep "error -"
  ERRORS=$((ERRORS + 1))
else
  echo "  PASS: coui_web clean"
fi

# 4. Verify no 'isDisabled' usage remains in contracts
echo "[4/8] Checking deprecated parameter usage..."
if grep -r "isDisabled\|isReadOnly" packages/coui_core/lib/src/component/contracts/ 2>/dev/null; then
  echo "  FAIL: Found deprecated parameter names in contracts"
  ERRORS=$((ERRORS + 1))
else
  echo "  PASS: No deprecated parameter names in contracts"
fi

# 5. ResolvedXxx must not carry a merged CoreXxxStyle bundle (Epic #1579 S5).
#    The resolver finishes merge + fallback + conversion; ResolvedXxx holds
#    plain values only. A `mergedStyle` field means the widget re-runs the
#    fallback chain — RFC §3.2 deviation.
echo "[5/8] Checking ResolvedXxx has no mergedStyle field..."
if grep -rnE 'final Core[A-Za-z]+Style\??\s+mergedStyle\b' \
    packages/coui_flutter/lib packages/coui_web/lib \
    --include='*.dart' 2>/dev/null; then
  echo "  FAIL: ResolvedXxx carries a mergedStyle field — fold it into"
  echo "        plain resolved fields (see docs/tech-spec-resolver-style-contract.md §3.2)"
  ERRORS=$((ERRORS + 1))
else
  echo "  PASS: No ResolvedXxx.mergedStyle field"
fi

# 6. Widget build must not run the merge chain.
#    (Globbed `co_*.dart` until the `co_` prefix was dropped repo-wide — it
#     matched zero files and passed vacuously.)
#    The merge chain (resolveStyleChain / var merged = const CoreXxxStyle())
#    belongs in {component}_style.dart's resolveXxx — RFC §3.1, verify 7-6(m).
echo "[6/8] Checking widget files do not run the merge chain..."
if grep -rnE 'resolveStyleChain|var merged = const Core' \
    --include='*.dart' --exclude='*_style.dart' \
    packages/coui_flutter/lib packages/coui_web/lib 2>/dev/null; then
  echo "  FAIL: a widget file runs a merge chain — move it into resolveXxx"
  echo "        ({component}_style.dart; RFC §3.1, verify 7-6 m)"
  ERRORS=$((ERRORS + 1))
else
  echo "  PASS: No merge chain in widget build"
fi

# 7. size_tokens must not use Web-vocabulary typography strings or raw-double
#    radius (Epic #1579 S7). Typography role → CoreXxxTypographyRole enum;
#    border radius → CoreBorderRadius.
echo "[7/8] Checking size_tokens use domain types (no String typography / raw radius)..."
if grep -rnE 'String (textStyle|fontWeight)|static const double (borderRadius|radius)\b' \
    packages/coui_core/lib/src/component/contracts \
    --include='*_size_tokens.dart' 2>/dev/null; then
  echo "  FAIL: size_tokens uses a String typography key or raw-double radius"
  echo "        — use a CoreXxxTypographyRole enum / CoreBorderRadius"
  ERRORS=$((ERRORS + 1))
else
  echo "  PASS: size_tokens use domain types"
fi

# 8. Hand-written equality / hashCode / copyWith / merge boilerplate on
#    CoreXxxStyle (issue #1592) — every `final` instance field declared on
#    a Style class must appear in the bodies of all four hand-rolled
#    methods. CoUI deliberately does not depend on Equatable / freezed,
#    so this grep guard substitutes for the codegen safety net.
echo "[8/8] Checking CoreXxxStyle field completeness (==/hashCode/copyWith/merge)..."
# Disable set -e for this check — perl's non-zero exit drives the conditional.
set +e
MISSING_REPORT=$(perl -e '
use strict;
use warnings;
use File::Find;

my @style_files;
find(sub {
  push @style_files, $File::Find::name if /_style\.dart$/;
}, "packages/coui_core/lib/src/component/contracts");

my $problems = 0;
my $report = "";

for my $file (sort @style_files) {
  open my $fh, "<", $file or next;
  my $src = do { local $/; <$fh> };
  close $fh;

  # Each CoreXxxStyle class block (greedy up to a matching `^}` at column 0)
  while ($src =~ /^class (Core[A-Za-z]+Style)(?:\s+(?:implements|extends)[^{]*)?\s*\{(.*?)^\}/sgm) {
    my ($cls, $body) = ($1, $2);
    # Only MAIN Style (has its own merge() method)
    next unless $body =~ /\b\Q$cls\E\s+merge\s*\(/;

    # Collect final instance fields (skip static const)
    my @fields;
    for my $line (split /\n/, $body) {
      next if $line =~ /^\s*static\s/;
      if ($line =~ /^\s*final\s+[^;]+?\s+([a-z_][a-zA-Z0-9_]*)\s*;/) {
        push @fields, $1;
      }
    }
    next unless @fields;

    # Extract bodies of ==, hashCode, copyWith, merge
    my %bodies;
    if ($body =~ /(bool\s+operator\s+==.*?)(?=\@override|\n\s*static|\n\s*Core[A-Z]|\Z)/s) {
      $bodies{eq} = $1;
    }
    if ($body =~ /(int\s+get\s+hashCode.*?)(?=\@override|\n\s*static|\n\s*Core[A-Z]|\Z)/s) {
      $bodies{hash} = $1;
    }
    if ($body =~ /(\Q$cls\E\s+copyWith\s*\(.*?\}\s*\n)/s) {
      $bodies{copy} = $1;
    }
    if ($body =~ /(\Q$cls\E\s+merge\s*\(.*?\}\s*\n)/s) {
      $bodies{merge} = $1;
    }

    for my $fld (@fields) {
      my @missing;
      for my $key (qw(eq hash copy merge)) {
        if (defined $bodies{$key} && $bodies{$key} !~ /\b\Q$fld\E\b/) {
          push @missing, $key;
        }
      }
      if (@missing) {
        $report .= "  $cls.$fld missing in: @missing\n";
        $problems++;
      }
    }
  }
}

if ($problems > 0) {
  print "FAIL\n$report";
  exit 1;
}
exit 0;
')
PERL_EXIT=$?
set -e
if [ "$PERL_EXIT" -ne 0 ]; then
  echo "  FAIL: CoreXxxStyle field completeness violations:"
  echo "$MISSING_REPORT" | tail -n +2
  echo "        — add the missing field to all four methods"
  echo "        (CoUI does not use Equatable / freezed, so completeness is hand-enforced)"
  ERRORS=$((ERRORS + 1))
else
  echo "  PASS: All CoreXxxStyle fields appear in ==, hashCode, copyWith, merge"
fi

# Components fully migrated to the PoC #1601 patterns. Checks 9, 12, 13
# are enforced as errors for these; everything else emits WARN only.
COMPONENTS_ENFORCED=(button alert card)
# Components migrated past the common-token-leak sweep (Phase 21+).
# Check 11 enforces these as errors (their platform style files must
# route every chrome value through CoreXxxStyle.defaultYyy).
# Superset of COMPONENTS_ENFORCED — anything fully migrated also passes
# Phase 11 by construction.
COMPONENTS_ENFORCED_COMMON_TOKEN=(
  button
  alert
  card
  item_picker
  datalist
  autocomplete
  formatted_input
  form
  select
  object_input
  time_picker
  toggle
  input_otp
  checkbox
  slider
  phone_input
  carousel
  stat
  calendar
  mockup_browser
  badge
  code_snippet
  mockup_device
  empty_state
  description_card
  chip
  diff
  aspect_ratio_box
  dot_indicator
  window_panel
  stepper
  accordion
  window
  tree
  hidden
  gap
  focus_outline
  swiper
  tooltip
  toast
  popover
  filter
  dialog
  drawer
  command
  fab
  tabs
  menubar
  menu
  theme_controller
  navigation_menu
  icon
  dropdown_menu
)
# Common-token classes whose static members must NOT be referenced from
# platform style files (they go through CoreXxxStyle.defaultYyy).
COMMON_TOKEN_CLASSES='CoreSpace|CoreFontSize|CoreFocusRing|CoreDuration|CoreStrokeWidth|CoreRadius'

# Helper: is a file under any enforced component path?
is_enforced() {
  local path="$1"
  for comp in "${COMPONENTS_ENFORCED[@]}"; do
    case "$path" in
      */components/*/${comp}/*) return 0 ;;
    esac
  done
  return 1
}

# Helper: is a file under any common-token-enforced component path?
#
# Phase 28 closing — common token leak sweep 가 모든 컴포넌트 카테고리
# (form / display / layout / overlay / menu / control / navigation /
# icon / text) 에서 완료되었으므로 components/ 디렉토리 전체를 ENFORCED
# 처리. 이후 신규 컴포넌트도 자동으로 enforced — 회귀 방지.
#
# COMPONENTS_ENFORCED_COMMON_TOKEN 배열은 historical inventory 로 유지
# (어떤 컴포넌트가 어느 Phase 에서 마이그됐는지 추적).
is_enforced_common_token() {
  local path="$1"
  case "$path" in
    */components/*) return 0 ;;
  esac
  return 1
}

# 9. Flutter widget resolver — chrome colour fields must go through
#    scheme.resolve(...). Bare `.toValue()` on a CoreColor field
#    falls back to kDefaultLightCoreColorArgb when the colour is a token
#    (Bug 3 in PoC #1601). Pattern matches: `(bg|border|fg|icon|shadow)
#    Color: merged.X?.toValue()` style; `scheme.resolve(X).toValue()`
#    chains are allowed.
echo "[9/13] Checking Flutter widget resolvers route CoreColor through scheme.resolve..."
set +e
TOK_HITS=$(grep -rnE '(backgroundColor|borderColor|foregroundColor|iconColor|shadowColor)\s*:\s*merged\.[a-zA-Z_]+\??\.toValue\(\)' \
    packages/coui_flutter/lib/src/components --include='*_style.dart' 2>/dev/null)
set -e
TOK_ENFORCE=""
TOK_WARN=""
if [ -n "$TOK_HITS" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    path="${line%%:*}"
    if is_enforced "$path"; then
      TOK_ENFORCE="$TOK_ENFORCE$line\n"
    else
      TOK_WARN="$TOK_WARN$line\n"
    fi
  done <<< "$TOK_HITS"
fi
if [ -n "$TOK_ENFORCE" ]; then
  echo "  FAIL: Enforced components still use bare merged.X.toValue() on chrome colours:"
  printf "%b" "$TOK_ENFORCE" | sed 's/^/    /'
  echo "        — replace with scheme.resolve(merged.X ?? chrome.X)."
  ERRORS=$((ERRORS + 1))
elif [ -n "$TOK_WARN" ]; then
  TOK_WARN_COUNT=$(printf "%b" "$TOK_WARN" | grep -c .)
  echo "  WARN: $TOK_WARN_COUNT non-enforced violation(s) — migration backlog:"
  printf "%b" "$TOK_WARN" | sed 's/^/    /' | head -20
  [ "$TOK_WARN_COUNT" -gt 20 ] && echo "    ... ($((TOK_WARN_COUNT - 20)) more)"
  echo "  PASS: All enforced components route through scheme.resolve"
else
  echo "  PASS: All Flutter widget resolvers route through scheme.resolve"
fi

# 10. CoreColor(0x00000000) raw literal in contracts. Use the shared
#     CoreColor.transparent sentinel instead so the meaning ("no fill")
#     is explicit and the toValue() alpha-preservation path is exercised.
echo "[10/13] Checking CoreColor transparent literals use shared sentinel..."
set +e
TRANS_HITS=$(grep -rnE 'CoreColor\(\s*0x0+\s*\)' \
    packages/coui_core/lib/src/component/contracts 2>/dev/null)
set -e
if [ -n "$TRANS_HITS" ]; then
  echo "  FAIL: Raw CoreColor(0x00000000) literals in contracts:"
  echo "$TRANS_HITS" | sed 's/^/    /'
  echo "        — use CoreColor.transparent (shared sentinel)."
  ERRORS=$((ERRORS + 1))
else
  echo "  PASS: No raw transparent CoreColor literals in contracts"
fi

# 11. Platform style files (packages/coui_{flutter,web}/.../{component}_style.dart)
#     must not reference common-token classes directly. Every chrome value
#     goes through CoreXxxStyle.defaultYyy so the contract owns the
#     single source of truth (1:1:1:1 mapping principle, #1601 PoC).
#     Doc-comment prose that merely *mentions* a token class (e.g.
#     `// ... CoreDuration.ms200 ... so behaviour is unchanged.`) is not
#     a code reference — strip anything from a `//` line-comment marker
#     onward before re-testing the match so prose false-positives don't
#     hard-fail real code.
echo "[11/13] Checking platform style files do not reference common-token classes directly..."
set +e
CT_HITS=$(grep -rnE "\b(${COMMON_TOKEN_CLASSES})\.[a-z]" \
    packages/coui_flutter/lib/src/components \
    packages/coui_web/lib/src/components \
    --include='*_style.dart' 2>/dev/null \
    | perl -ne '
        if (/^([^:]+:\d+):(.*)$/) {
          my ($prefix, $rest) = ($1, $2);
          (my $code_only = $rest) =~ s{//.*$}{};
          print "$prefix:$rest\n" if $code_only =~ /\b('"${COMMON_TOKEN_CLASSES}"')\.[a-z]/;
        }
      ')
set -e
CT_ENFORCE=""
CT_WARN=""
if [ -n "$CT_HITS" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    path="${line%%:*}"
    if is_enforced_common_token "$path"; then
      CT_ENFORCE="$CT_ENFORCE$line\n"
    else
      CT_WARN="$CT_WARN$line\n"
    fi
  done <<< "$CT_HITS"
fi
if [ -n "$CT_ENFORCE" ]; then
  echo "  FAIL: Enforced components reference common-token classes directly:"
  printf "%b" "$CT_ENFORCE" | sed 's/^/    /'
  echo "        — add CoreXxxStyle.defaultYyy in the contract and reference that instead."
  ERRORS=$((ERRORS + 1))
elif [ -n "$CT_WARN" ]; then
  CT_WARN_COUNT=$(printf "%b" "$CT_WARN" | grep -c .)
  echo "  WARN: $CT_WARN_COUNT non-enforced violation(s) — migration backlog:"
  printf "%b" "$CT_WARN" | sed 's/^/    /' | head -20
  [ "$CT_WARN_COUNT" -gt 20 ] && echo "    ... ($((CT_WARN_COUNT - 20)) more)"
  echo "  PASS: All enforced components reference common tokens via CoreXxxStyle.defaultYyy"
else
  echo "  PASS: No common-token class references in platform style files"
fi

# 12. Web Resolved* must implement WebResolvedChrome + use WebElementChrome
#     for chrome slots (no flat `String? xxxClassName` / `Styles? xxxInlineStyles`
#     pairs). #1601 PoC interface — single root entry point + slot grouping.
echo "[12/13] Checking Web Resolved* uses WebResolvedChrome + WebElementChrome..."
set +e
# (a) Resolved* missing implements WebResolvedChrome.
# Category-C/D/E Resolved classes (Resolved*Rules = scoped <style> CSS text,
# Resolved*Runtime = client-side JS config, Resolved*Timing = behaviour
# timings) intentionally do NOT implement WebResolvedChrome — they carry no
# DOM chrome (a raw `String css` / config record), per web/web-specifics.md's
# "5 종 Resolved 카테고리". Only category-A/B chrome Resolved classes must.
MISSING_IFACE=$(grep -rnE 'class Resolved[A-Z][a-zA-Z]+\b' \
    packages/coui_web/lib/src/components --include='*_style.dart' 2>/dev/null \
    | grep -v 'implements WebResolvedChrome' \
    | grep -vE 'class Resolved[A-Z][a-zA-Z]+(Rules|Runtime|Timing)\b')
# (b) Flat className / inlineStyles fields
FLAT_CHROME=$(grep -rnE '^\s+final (String\??\s+[a-z][a-zA-Z]*ClassName\b|Styles\??\s+[a-z][a-zA-Z]*InlineStyles\b)' \
    packages/coui_web/lib/src/components --include='*_style.dart' 2>/dev/null)
set -e
IFACE_ENFORCE=""
IFACE_WARN=""
FLAT_ENFORCE=""
FLAT_WARN=""
if [ -n "$MISSING_IFACE" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    path="${line%%:*}"
    if is_enforced "$path"; then
      IFACE_ENFORCE="$IFACE_ENFORCE$line\n"
    else
      IFACE_WARN="$IFACE_WARN$line\n"
    fi
  done <<< "$MISSING_IFACE"
fi
if [ -n "$FLAT_CHROME" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    path="${line%%:*}"
    if is_enforced "$path"; then
      FLAT_ENFORCE="$FLAT_ENFORCE$line\n"
    else
      FLAT_WARN="$FLAT_WARN$line\n"
    fi
  done <<< "$FLAT_CHROME"
fi
COMBINED_ENFORCE="${IFACE_ENFORCE}${FLAT_ENFORCE}"
COMBINED_WARN="${IFACE_WARN}${FLAT_WARN}"
if [ -n "$COMBINED_ENFORCE" ]; then
  echo "  FAIL: Enforced components missing WebResolvedChrome / using flat chrome fields:"
  printf "%b" "$COMBINED_ENFORCE" | sed 's/^/    /'
  echo "        — add 'implements WebResolvedChrome' + group className/inlineStyles into WebElementChrome."
  ERRORS=$((ERRORS + 1))
elif [ -n "$COMBINED_WARN" ]; then
  WARN_COUNT=$(printf "%b" "$COMBINED_WARN" | grep -c .)
  echo "  WARN: $WARN_COUNT non-enforced violation(s) — migration backlog:"
  printf "%b" "$COMBINED_WARN" | sed 's/^/    /' | head -20
  [ "$WARN_COUNT" -gt 20 ] && echo "    ... ($((WARN_COUNT - 20)) more)"
  echo "  PASS: All enforced components use WebResolvedChrome + WebElementChrome"
else
  echo "  PASS: All Web Resolved* implement WebResolvedChrome with WebElementChrome slots"
fi

# 13. Core ↔ Core enum mapping must live as source-side `toXxx()` method,
#     not file-local `_mapXxx()` function or `extension on CoreXxx` inside
#     platform _style.dart. Platform vocabulary (Tailwind / Flutter native)
#     mapping lives in platform adapter files as extension getters — that
#     is OK and not caught here.
echo "[13/13] Checking enum mappings are source-side (no _mapXxx() / file-local extension)..."
set +e
# (a) _mapXxx free function — file-local enum→enum mapping
MAP_FN=$(grep -rnE '^[A-Z][a-zA-Z<>?,\s]+\s+_map[A-Z][a-zA-Z]+\s*\(' \
    packages/coui_flutter/lib/src/components \
    packages/coui_web/lib/src/components \
    --include='*_style.dart' 2>/dev/null)
# (b) file-local extension on CoreXxx
EXT_LOCAL=$(grep -rnE '^extension\s+on\s+Core[A-Z]' \
    packages/coui_flutter/lib/src/components \
    packages/coui_web/lib/src/components \
    --include='*_style.dart' 2>/dev/null)
set -e
ENUM_ENFORCE=""
ENUM_WARN=""
ENUM_HITS="${MAP_FN}${MAP_FN:+\n}${EXT_LOCAL}"
if [ -n "$MAP_FN" ] || [ -n "$EXT_LOCAL" ]; then
  for hits in "$MAP_FN" "$EXT_LOCAL"; do
    [ -z "$hits" ] && continue
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      path="${line%%:*}"
      if is_enforced "$path"; then
        ENUM_ENFORCE="$ENUM_ENFORCE$line\n"
      else
        ENUM_WARN="$ENUM_WARN$line\n"
      fi
    done <<< "$hits"
  done
fi
if [ -n "$ENUM_ENFORCE" ]; then
  echo "  FAIL: Enforced components have file-local enum mapping helpers:"
  printf "%b" "$ENUM_ENFORCE" | sed 's/^/    /'
  echo "        — move the mapping to a method on the source CoreXxx enum (X.toY())."
  ERRORS=$((ERRORS + 1))
elif [ -n "$ENUM_WARN" ]; then
  WARN_COUNT=$(printf "%b" "$ENUM_WARN" | grep -c .)
  echo "  WARN: $WARN_COUNT non-enforced violation(s) — migration backlog:"
  printf "%b" "$ENUM_WARN" | sed 's/^/    /' | head -20
  [ "$WARN_COUNT" -gt 20 ] && echo "    ... ($((WARN_COUNT - 20)) more)"
  echo "  PASS: All enforced components route enum mapping through source-side methods"
else
  echo "  PASS: No file-local enum mapping helpers in platform style files"
fi

# 14. Verify Web _style.dart local variables don't carry render-format
#     suffixes (`Css` / `Rem` / `Token`) for chrome that already has a
#     source field name (Epic #1599 / #2201 / #2202 / #2210).
#       borderRadius / padding (domain-typed source):
#         Css / Rem / Token  → ERROR (single representation, just use `borderRadius`)
#       gap (logical-px double source):
#         Css / Token        → ERROR (ambiguous / source-of-truth confusion)
#         Rem                → ALLOWED (double original + rem string co-exist;
#                              see RFC §9.1)
#       margin: Style 필드로 도입 자체가 금지 (RFC §9.1 비범위) — `margin`
#         변수 등장 시나리오 자체가 없음. 자식 간 spacing 은 `gap: double?`
#         평면 필드 + Flutter `Row(spacing:)` / Web flex `gap` 으로 emit
#         (RFC §10.1 — Gap 자식 삽입 표준은 #2210 step3 revert 시 폐기).
#     The variable should match the source field so the resolved chrome
#     reflects `merged.X` directly. Project-wide ERROR — no migration list.
echo "[14/14] Checking Web chrome variable naming suffixes..."
set +e
NAMING_HITS=$(grep -rnE '\b((borderRadius|padding)(Css|Rem|Token)|gap(Css|Token))\b' \
  packages/coui_web/lib --include='*_style.dart' 2>/dev/null)
set -e
if [ -n "$NAMING_HITS" ]; then
  HIT_COUNT=$(printf '%s\n' "$NAMING_HITS" | grep -c .)
  echo "  FAIL: $HIT_COUNT chrome variable(s) carry render-format suffix:"
  printf '%s\n' "$NAMING_HITS" | sed 's/^/    /' | head -20
  [ "$HIT_COUNT" -gt 20 ] && echo "    ... ($((HIT_COUNT - 20)) more)"
  echo "        — rename to match the source field (e.g. \`borderRadiusCss\` → \`borderRadius\`)."
  ERRORS=$((ERRORS + 1))
else
  echo "  PASS: No render-format suffix on chrome variables"
fi

echo ""
if [ $ERRORS -eq 0 ]; then
  echo "=== All checks passed ==="
  exit 0
else
  echo "=== $ERRORS check(s) failed ==="
  exit 1
fi
