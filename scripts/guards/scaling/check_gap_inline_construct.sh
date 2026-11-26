#!/usr/bin/env bash
# check_gap_inline_construct.sh
#
# Guards against the Gap inline-construct anti-pattern:
#
#     Gap(gapStyle: CoreGapStyle(size: ...))
#
# The widget call site should never wrap a flat numeric value in
# `CoreGapStyle(...)`. The chrome decision (which size / which token) belongs
# in the component's resolver (`*_style.dart`), and the widget should either:
#
#   - forward a resolved nested Style slot (`Gap(gapStyle: resolved.foo)`), or
#   - use a token-folded named constructor (`const Gap.space16()`,
#     `Gap.space4()`, etc.).
#
# Inline-constructing `CoreGapStyle` at the call site bypasses the nested-Style
# slot contract from feedback "1:1:1:1 Field Mapping" and "Default in Style,
# Not Theme": the chrome value escapes the Style layer and lives directly in
# the widget tree, so consumers can no longer override it through the standard
# `style:` slot.
#
# Allowed callers:
#   - `*_style.dart` files (resolver files). These ARE the chrome layer and
#     are the one place a raw `CoreGapStyle(size: ...)` literal is legitimate.
#
# Disallowed callers:
#   - Widget files (`co_*.dart`, plus any other `.dart` outside `*_style.dart`)
#     under the scanned component trees.
#
# Exception: `Gap.spaceN(...)` named constructors (e.g. `const Gap.space4()`)
# are token-folded constants — they do NOT match the inline-construct pattern
# (no `gapStyle:` argument), so they are inherently outside the regex below
# and require no special-casing.
#
# Scan paths:
#   - packages/coui_flutter/lib/src/components/**/*.dart
#   - packages/coui_web/lib/src/components/**/*.dart
#
# Exit code: 0 if clean, 1 on any violation.
#
# Usage:
#   ./scripts/check_gap_inline_construct.sh [--verbose]
#
#   --verbose   Print scan summary even when clean.

set -u

readonly SCRIPT_NAME="$(basename "$0")"
readonly REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

VERBOSE=0

print_help() {
  sed -n '2,46p' "$0" | sed 's/^# \{0,1\}//'
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --verbose) VERBOSE=1 ;;
      --help|-h) print_help; exit 0 ;;
      *)
        echo "Unknown argument: $1" >&2
        echo "Run '$SCRIPT_NAME --help' for usage." >&2
        exit 2
        ;;
    esac
    shift
  done
}

# Pattern: literal `Gap(gapStyle: CoreGapStyle(`
# - Matches multi-line callers because we grep linewise but only the opening
#   line carries this token sequence; the closing `)` is irrelevant.
# - Does NOT match `Gap.spaceN(...)` (no `gapStyle:` argument).
# - Does NOT match `Gap(gapStyle: someResolvedSlot)` — only when the value
#   is being inline-constructed via `CoreGapStyle(`.
readonly PATTERN='Gap\(gapStyle:[[:space:]]*CoreGapStyle\('

# Scan roots — only component directories are subject to the rule.
SCAN_ROOTS=(
  "$REPO_ROOT/packages/coui_flutter/lib/src/components"
  "$REPO_ROOT/packages/coui_web/lib/src/components"
)

choose_grep() {
  if command -v rg >/dev/null 2>&1; then
    echo "rg"
  else
    echo "grep"
  fi
}

scan() {
  local engine
  engine="$(choose_grep)"
  local raw_hits=""

  for root in "${SCAN_ROOTS[@]}"; do
    if [ ! -d "$root" ]; then
      continue
    fi
    local hits=""
    if [ "$engine" = "rg" ]; then
      hits="$(rg --no-heading --line-number --color=never \
              --glob '*.dart' \
              "$PATTERN" "$root" 2>/dev/null || true)"
    else
      hits="$(grep -rn --include='*.dart' -E "$PATTERN" "$root" 2>/dev/null || true)"
    fi
    if [ -n "$hits" ]; then
      raw_hits="${raw_hits}${hits}
"
    fi
  done

  # Strip out hits in allowed callers:
  #  (a) resolver files: *_style.dart (the chrome layer — legitimate)
  #  (b) the gap() factory helpers in util.dart — the construction primitive
  #      home; a CoreGapStyle literal must live somewhere, this is it
  #  (c) data-driven CoreMenuItem.gap construction (`size: item.gapSize`) —
  #      the size is per-item caller data, not a call-site chrome bypass
  #  (d) @Deprecated legacy widget files
  # Format of each hit line: "<path>:<lineno>:<content>"
  local violations
  violations="$(printf '%s' "$raw_hits" \
    | awk -F: 'NF >= 3 {
        path = $1;
        # Allow if filename ends in _style.dart
        if (path ~ /_style\.dart$/) next;
        # Allow the gap() construction primitive (util.dart)
        if (path ~ /\/util\.dart$/) next;
        # Allow data-driven menu-item gap construction
        if ($0 ~ /item\.gapSize/) next;
        # Allow if file contains @Deprecated marker (legacy widget)
        cmd = "grep -l @Deprecated \"" path "\" 2>/dev/null";
        cmd | getline marker;
        close(cmd);
        if (marker != "") next;
        print $0;
      }')"

  if [ -z "$violations" ]; then
    if [ "$VERBOSE" -eq 1 ]; then
      echo "[$SCRIPT_NAME] OK — no Gap inline-construct violations under scanned roots."
    fi
    return 0
  fi

  echo "[$SCRIPT_NAME] Gap inline-construct anti-pattern detected." >&2
  echo "  Move the CoreGapStyle(...) literal into the component's *_style.dart resolver" >&2
  echo "  and forward it through the widget's nested gapStyle slot, or use a token-folded" >&2
  echo "  named constructor (e.g. const Gap.space16())." >&2
  echo "" >&2

  # Emit one violation per line in the requested format:
  #   <path>:<lineno>: Gap inline-construct in widget file (must move to resolver / use nested gapStyle slot)
  printf '%s\n' "$violations" \
    | awk -F: 'NF >= 3 {
        printf "%s:%s: Gap inline-construct in widget file (must move to resolver / use nested gapStyle slot)\n", $1, $2;
      }' >&2

  local count
  count="$(printf '%s\n' "$violations" | grep -c . || true)"
  echo "" >&2
  echo "[$SCRIPT_NAME] FAIL — $count violation(s)." >&2
  return 1
}

main() {
  parse_args "$@"
  scan
}

main "$@"
