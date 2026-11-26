#!/usr/bin/env bash
# check_design_tokens.sh
#
# Guards against re-introduction of design-token bypasses tracked by
# Epic #1096 (design-token parity). Runs in phases that are activated
# incrementally as each sub-story (#1097~#1101) lands.
#
# Usage:
#   ./scripts/check_design_tokens.sh [--phase N] [--verbose] [--help]
#
#   --phase N   Run phases 1..N (default: 2). Valid: 1, 2, 3, 4, 5, 6, 7.
#   --verbose   Print passing phases too.
#   --help      Show this help.
#
# Phases:
#   1. Flutter Duration(milliseconds|seconds) literals  (#1097, active)
#   2. Web fixed-value arbitrary (`rounded-[4px]`, ...)  (#1098, active)
#   3. Web color arbitrary (`bg-[#...]`, `bg-[rgba(..)]`) (#1099, pending)
#   4. Web dynamic arbitrary (`<prefix>-[${...}]`)        (#1101, pending)
#   5. Flutter radius/border literals                     (follow-up, pending)
#   6. Web inline CSS `'${value}px'` literals              (#1148, active)
#   7. Web inline CSS border-width `rem` (must stay px-fixed) (#3276, active)
#
# Exit code: 0 if clean, 1 if any violation found.
#
# NOTE: CI runs phases 1–7 — `--phase 6` covers 1–6 cumulatively and
# `--phase 7` runs separately (see .github/workflows/ci.yaml).

set -u

# ---------------------------------------------------------------------------
# Regex test block (reference — not executed).
# Verified manually against:
#   "Duration(milliseconds: 300)"        → matches Phase 1
#   "Duration(seconds: 2)"               → matches Phase 1
#   "const _kFoo = Duration(seconds: 2)" → matches Phase 1 but allowlisted
#   "rounded-[4px]"                      → matches Phase 2
#   "text-[10px]"                        → matches Phase 2
#   "max-h-[300px]"                      → matches Phase 2
#   "bg-[#ff0000]"                       → matches Phase 3
#   "bg-[rgba(0,0,0,0.5)]"               → matches Phase 3
#   "border-[rgb(1,2,3)]"                → matches Phase 3
#   "rounded-[\${kRadius}]"              → matches Phase 4
#   "px-[\${size}]"                      → matches Phase 4
#   "BorderRadius.circular(8)"           → matches Phase 5
#   "Border.all(width: 2)"               → matches Phase 5
#   "'${gap.toInt()}px'"                 → matches Phase 6
#   "'${value / 16}rem'"                 → allowed (rem escape hatch)
#   "'border-width': '${w / 16}rem'"     → matches Phase 7 (border stays px)
#   "'border-width': strokeWidthCss(w)"  → allowed (px-fixed converter)
# ---------------------------------------------------------------------------

readonly EPIC_URL="https://github.com/coco-de/coui/issues/1096"
readonly SCRIPT_NAME="$(basename "$0")"

PHASE=2
VERBOSE=0

print_help() {
  sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --phase)
        shift
        PHASE="${1:-}"
        ;;
      --phase=*)
        PHASE="${1#--phase=}"
        ;;
      --verbose)
        VERBOSE=1
        ;;
      --help|-h)
        print_help
        exit 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        echo "Run '$SCRIPT_NAME --help' for usage." >&2
        exit 2
        ;;
    esac
    shift
  done

  case "$PHASE" in
    1|2|3|4|5|6|7) ;;
    *)
      echo "Invalid --phase value: $PHASE (expected 1..7)" >&2
      exit 2
      ;;
  esac
}

# Prefer ripgrep when available.
have_rg() { command -v rg >/dev/null 2>&1; }

# search_pattern <pattern> <scope_dir> <exclude_globs_space_separated>
# Prints matches in "file:line:content" format. Returns 0 even when no matches.
search_pattern() {
  local pattern="$1"
  local scope="$2"
  local excludes="$3"

  if [ ! -d "$scope" ]; then
    return 0
  fi

  if have_rg; then
    local args=(--no-heading --line-number --color never -e "$pattern" "$scope")
    for ex in $excludes; do
      args+=(--glob "!${ex}")
    done
    rg "${args[@]}" 2>/dev/null || true
  else
    # grep -E fallback. Exclude dirs via --exclude-dir.
    local grep_args=(-R -n -E "$pattern" "$scope")
    for ex in $excludes; do
      # Reduce a glob like "packages/.../base/**" to its basename path for
      # --exclude-dir; grep only handles directory names, not full paths.
      local dirname
      dirname="$(basename "${ex%%/\*\*}")"
      grep_args+=(--exclude-dir="$dirname")
    done
    grep "${grep_args[@]}" 2>/dev/null || true
  fi
}

VIOLATIONS=0

report_violation() {
  local file="$1" line="$2" matched="$3" phase="$4" desc="$5" suggestion="$6"
  printf '\xE2\x9D\x8C %s:%s\n' "$file" "$line"
  printf '   Found: %s\n' "$matched"
  printf '   Rule: Phase %s (%s)\n' "$phase" "$desc"
  printf '   Use instead: %s\n' "$suggestion"
  printf '   Epic: %s\n\n' "$EPIC_URL"
  VIOLATIONS=$((VIOLATIONS + 1))
}

# is_allowed_phase1 <file> <line_number> <line_text>
# Allowlist for Phase 1: lines starting (ignoring leading whitespace) with
# "const _k" — component-local constants are acceptable. Also skip doc-comment
# lines (/// ...) which are examples, not real code.
is_allowed_phase1() {
  local line_text="$1"
  # Trim leading whitespace.
  local stripped="${line_text#"${line_text%%[![:space:]]*}"}"
  case "$stripped" in
    'const _k'*) return 0 ;;
    '///'*)      return 0 ;;
    '//'*)       return 0 ;;
  esac
  return 1
}

# is_allowed_phase2 <line_text>
# Phase 3 activation will allow bg-[var(--coui-...)] / border-[var(--coui-...)].
# Those patterns don't overlap with Phase 2 regexes so no allowlist needed yet.
is_allowed_phase2() {
  return 1
}

run_phase1() {
  local scope="packages/coui_flutter/lib/src/components"
  local excludes="packages/coui_flutter/lib/src/constants/** packages/coui_flutter/lib/src/theme/** packages/coui_core/lib/src/**"
  local pattern='Duration\((milliseconds|seconds):\s*[0-9]'
  local desc="Flutter Duration literal"
  local suggestion="AnimationConstants.{xs|short|normal|medium} / CoreDuration"

  local matches
  matches=$(search_pattern "$pattern" "$scope" "$excludes")
  [ -z "$matches" ] && { [ "$VERBOSE" = "1" ] && echo "Phase 1: clean"; return; }

  local local_violations=0
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    local file line content
    file="${hit%%:*}"
    local rest="${hit#*:}"
    line="${rest%%:*}"
    content="${rest#*:}"
    if is_allowed_phase1 "$content"; then
      continue
    fi
    report_violation "$file" "$line" "$(printf '%s' "$content" | sed 's/^[[:space:]]*//')" 1 "$desc" "$suggestion"
    local_violations=$((local_violations + 1))
  done <<EOF
$matches
EOF
  if [ "$local_violations" = "0" ] && [ "$VERBOSE" = "1" ]; then
    echo "Phase 1: clean"
  fi
}

run_phase2() {
  local scope="packages/coui_web/lib/src/components"
  local excludes="packages/coui_web/lib/src/base/** packages/coui_web/lib/src/adapter/** packages/coui_web/lib/src/util/**"
  local desc="Web fixed-value arbitrary class"
  local suggestion="CoreRadius/CoreSpace/CoreSize preset (rounded-sm, h-10, min-w-40, ...)"

  # Combined pattern for ripgrep/grep; split per-prefix for clarity.
  local pattern='(rounded|text|max-h|min-w|min-h|w|h)-\[[0-9]+px\]'

  local matches
  matches=$(search_pattern "$pattern" "$scope" "$excludes")
  [ -z "$matches" ] && { [ "$VERBOSE" = "1" ] && echo "Phase 2: clean"; return; }

  local local_violations=0
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    local file line content
    file="${hit%%:*}"
    local rest="${hit#*:}"
    line="${rest%%:*}"
    content="${rest#*:}"
    if is_allowed_phase2 "$content"; then
      continue
    fi
    report_violation "$file" "$line" "$(printf '%s' "$content" | sed 's/^[[:space:]]*//')" 2 "$desc" "$suggestion"
    local_violations=$((local_violations + 1))
  done <<EOF
$matches
EOF
  if [ "$local_violations" = "0" ] && [ "$VERBOSE" = "1" ]; then
    echo "Phase 2: clean"
  fi
}

run_phase3() {
  local scope="packages/coui_web/lib/src/components"
  local excludes="packages/coui_web/lib/src/base/** packages/coui_web/lib/src/adapter/** packages/coui_web/lib/src/util/**"
  local desc="Web color arbitrary"
  local suggestion="CSS variable bg-[var(--coui-xxx)] / CoreColorToken class"

  local patterns=(
    'bg-\[#[0-9a-fA-F]+\]'
    'bg-\[rgba?\('
    'border-\[#[0-9a-fA-F]+\]'
    'border-\[rgba?\('
  )

  local matches=""
  local p
  for p in "${patterns[@]}"; do
    local chunk
    chunk=$(search_pattern "$p" "$scope" "$excludes")
    [ -n "$chunk" ] && matches="${matches}${chunk}
"
  done

  if [ -z "$(printf '%s' "$matches" | tr -d '[:space:]')" ]; then
    [ "$VERBOSE" = "1" ] && echo "Phase 3: clean"
    return
  fi

  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    local file line content
    file="${hit%%:*}"
    local rest="${hit#*:}"
    line="${rest%%:*}"
    content="${rest#*:}"
    report_violation "$file" "$line" "$(printf '%s' "$content" | sed 's/^[[:space:]]*//')" 3 "$desc" "$suggestion"
  done <<EOF
$matches
EOF
}

run_phase4() {
  local scope="packages/coui_web/lib/src/components"
  local excludes="packages/coui_web/lib/src/base/** packages/coui_web/lib/src/adapter/** packages/coui_web/lib/src/util/**"
  local desc="Web dynamic arbitrary (string interpolation)"
  local suggestion="preset class + inline Styles for dynamic values, or CSS variable"

  # Matches `<word>-[${...}]` — e.g. rounded-[\${kRadius}], px-[\${size}].
  local pattern='[a-zA-Z]+-\[\$\{'

  local matches
  matches=$(search_pattern "$pattern" "$scope" "$excludes")
  [ -z "$matches" ] && { [ "$VERBOSE" = "1" ] && echo "Phase 4: clean"; return; }

  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    local file line content
    file="${hit%%:*}"
    local rest="${hit#*:}"
    line="${rest%%:*}"
    content="${rest#*:}"
    report_violation "$file" "$line" "$(printf '%s' "$content" | sed 's/^[[:space:]]*//')" 4 "$desc" "$suggestion"
  done <<EOF
$matches
EOF
}

run_phase5() {
  local scope="packages/coui_flutter/lib/src/components"
  local excludes="packages/coui_flutter/lib/src/constants/** packages/coui_flutter/lib/src/theme/** packages/coui_core/lib/src/**"
  local desc="Flutter radius/border literal"
  local suggestion="CoreRadius.scale.xxx / CoreBorderWidth.xxx"

  local patterns=(
    'BorderRadius\.circular\(\s*[0-9]'
    'Border\.all\(\s*width:\s*[0-9]'
  )

  local matches=""
  local p
  for p in "${patterns[@]}"; do
    local chunk
    chunk=$(search_pattern "$p" "$scope" "$excludes")
    [ -n "$chunk" ] && matches="${matches}${chunk}
"
  done

  if [ -z "$(printf '%s' "$matches" | tr -d '[:space:]')" ]; then
    [ "$VERBOSE" = "1" ] && echo "Phase 5: clean"
    return
  fi

  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    local file line content
    file="${hit%%:*}"
    local rest="${hit#*:}"
    line="${rest%%:*}"
    content="${rest#*:}"
    # Skip doc-comment lines.
    local stripped="${content#"${content%%[![:space:]]*}"}"
    case "$stripped" in
      '///'*|'//'*) continue ;;
    esac
    report_violation "$file" "$line" "$(printf '%s' "$content" | sed 's/^[[:space:]]*//')" 5 "$desc" "$suggestion"
  done <<EOF
$matches
EOF
}

run_phase6() {
  local scope="packages/coui_web/lib/src/components"
  local excludes="packages/coui_web/lib/src/base/** packages/coui_web/lib/src/adapter/** packages/coui_web/lib/src/util/**"
  local desc="Web inline CSS 'px' literal (accessibility scale bypass)"
  local suggestion="'\${value / kRemDivisor}rem' (accessibility-scale aware) or 'var(--coui-<category>-<token>)'"

  # Matches inline CSS strings like '${value}px' that bypass rem/CSS-variable
  # accessibility scaling. The rem-escape-hatch ('${x / 16}rem') is allowed.
  local pattern="'\\\$\\{[^}]+\\}px'"

  local matches
  matches=$(search_pattern "$pattern" "$scope" "$excludes")
  [ -z "$matches" ] && { [ "$VERBOSE" = "1" ] && echo "Phase 6: clean"; return; }

  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    local file line content
    file="${hit%%:*}"
    local rest="${hit#*:}"
    line="${rest%%:*}"
    content="${rest#*:}"
    # Skip doc-comment lines.
    local stripped="${content#"${content%%[![:space:]]*}"}"
    case "$stripped" in
      '///'*|'//'*) continue ;;
    esac
    # Escape-hatch marker: `// design-token: <reason>` on the same line.
    # Used for runtime viewport-relative computed values (drag positions,
    # window bounds) where `px` is the intentional, accessibility-neutral
    # unit because the value already scales with viewport, not with
    # `root font-size`.
    case "$content" in
      *'// design-token:'*) continue ;;
    esac
    report_violation "$file" "$line" "$(printf '%s' "$content" | sed 's/^[[:space:]]*//')" 6 "$desc" "$suggestion"
  done <<EOF
$matches
EOF
}

run_phase7() {
  local scope="packages/coui_web/lib/src/components"
  local excludes="packages/coui_web/lib/src/base/** packages/coui_web/lib/src/adapter/** packages/coui_web/lib/src/util/**"
  local desc="Web inline CSS border-width 'rem' (border must stay px-fixed)"
  local suggestion="strokeWidthCss(<width>) — px-fixed via '--coui-stroke-width-N'; a border is a physical hairline and must not thicken with the browser's root font-size (the axis 'rem' responds to)"

  # A stroke width emitted as `rem` grows when the user enlarges the
  # browser's root font-size — the exact opposite of the px-fixed policy
  # (Flutter's textScaling axis never reaches borderWidth either). The
  # inline value must be `strokeWidthCss(...)` (→ `var(--coui-stroke-width-N)`
  # or a literal `px`), never `${x / kRemDivisor}rem`.
  #
  # Primary: a `border[-side]-width` inline key with a `rem` value on the
  # same line — the dominant shape (`'border-width': '${w / kRemDivisor}rem'`,
  # `raw['border-left-width'] = '${w / kRemDivisor}rem'`).
  local pattern="border(-(top|right|bottom|left))?-width'[^;,]*rem"
  # Secondary: a rem-valued border-width intermediate variable
  # (`final barBorderWidthRem = '${w / kRemDivisor}rem'`) that a keyed
  # match cannot see — caught by the `*BorderWidth*Rem =` + rem shape.
  local varPattern="[Bb]order[A-Za-z]*[Ww]idth[A-Za-z]*Rem[[:space:]]*=[^;]*rem"

  local matches
  matches=$(
    { search_pattern "$pattern" "$scope" "$excludes"
      search_pattern "$varPattern" "$scope" "$excludes"
    } | sort -u
  )
  [ -z "$matches" ] && { [ "$VERBOSE" = "1" ] && echo "Phase 7: clean"; return; }

  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    local file line content
    file="${hit%%:*}"
    local rest="${hit#*:}"
    line="${rest%%:*}"
    content="${rest#*:}"
    # Skip doc-comment lines.
    local stripped="${content#"${content%%[![:space:]]*}"}"
    case "$stripped" in
      '///'*|'//'*) continue ;;
    esac
    report_violation "$file" "$line" "$(printf '%s' "$content" | sed 's/^[[:space:]]*//')" 7 "$desc" "$suggestion"
  done <<EOF
$matches
EOF
}

main() {
  parse_args "$@"

  echo "=== CoUI design-token guard (phase 1..${PHASE}) ==="
  if have_rg; then
    echo "engine: ripgrep"
  else
    echo "engine: grep -E (ripgrep not found — install 'rg' for faster runs)"
  fi
  echo

  [ "$PHASE" -ge 1 ] && run_phase1
  [ "$PHASE" -ge 2 ] && run_phase2
  [ "$PHASE" -ge 3 ] && run_phase3
  [ "$PHASE" -ge 4 ] && run_phase4
  [ "$PHASE" -ge 5 ] && run_phase5
  [ "$PHASE" -ge 6 ] && run_phase6
  [ "$PHASE" -ge 7 ] && run_phase7

  if [ "$VIOLATIONS" -eq 0 ]; then
    printf '\xE2\x9C\x85 No violations found across phase 1..%s.\n' "$PHASE"
    exit 0
  fi
  printf '\xE2\x9D\x8C %s violation(s) detected. See %s for token migration guidance.\n' "$VIOLATIONS" "$EPIC_URL"
  exit 1
}

main "$@"
