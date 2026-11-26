#!/usr/bin/env bash
# check_gap_spacing_naming.sh
#
# CI guard: enforce name <-> type consistency for gap/spacing slots on
# CoreXxxStyle / ResolvedXxx classes under packages/coui_core contracts.
#
# Naming contract (1:1:1:1 — see feedback_one_to_one_field_mapping):
#   * `xxxGapStyle`  -> MUST be `CoreGapStyle?`   (nested Style slot — composed Gap)
#   * `xxxSpacing`   -> MUST be `double?`         (raw logical-pixel scalar)
#   * `xxxGap` (not GapStyle / not Spacing) -> AMBIGUOUS — author must rename
#     to either `xxxGapStyle` (nested Style slot) or `xxxSpacing` (raw double).
#
# Allowlist:
#   * iconSpacing — pre-existing label / button convention, type double? (already
#     conforms to the Spacing rule; explicitly whitelisted in case of future
#     type drift in adjacent style files).
#   * rowSpacing, lineSpacing — TextStyle row/line spacing (CSS-ish unit on
#     Text contracts); both legitimately `double?` so they already conform,
#     but listed here so reviewers know they were considered.
#   * File-level overrides may be added to
#     `.lint-allowlist/gap-spacing-naming.txt` (one repo-relative path per
#     line, `#` for comments). The file is referenced only — this script
#     does NOT create it.
#
# Usage:
#   ./scripts/check_gap_spacing_naming.sh
#
# Exit:
#   0  no violations
#   1  one or more violations (printed as `file:line: <message>`)
#   2  bad invocation / repo layout problem
#
# Strict mode.

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve repo root + scan target.
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

SCAN_ROOT="${REPO_ROOT}/packages/coui_core/lib/src/component/contracts"
ALLOWLIST_FILE="${REPO_ROOT}/.lint-allowlist/gap-spacing-naming.txt"

if [ ! -d "${SCAN_ROOT}" ]; then
  echo "error: scan root not found: ${SCAN_ROOT}" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Load file-level allowlist (repo-relative paths). Missing file = empty list.
# ---------------------------------------------------------------------------
# Use a tmpfile so awk can ingest it without quoting headaches.
ALLOWLIST_TMP="$(mktemp -t gapspc.allowlist.XXXXXX)"
trap 'rm -f "${ALLOWLIST_TMP}"' EXIT

if [ -f "${ALLOWLIST_FILE}" ]; then
  # Strip blank lines and `#` comments; normalize whitespace.
  grep -Ev '^\s*(#|$)' "${ALLOWLIST_FILE}" \
    | awk '{ gsub(/^[ \t]+|[ \t]+$/, "", $0); if (length($0) > 0) print $0 }' \
    > "${ALLOWLIST_TMP}" || true
fi

# Field-name allowlist for `xxxSpacing` that may legitimately not be `double?`
# in edge cases (kept narrow). Today every entry is `double?` already, so
# the list is empty — but is wired in so future TextStyle-shaped fields
# can be added without rewriting the script.
#
# Format: one field name per line.
FIELD_NAME_ALLOWLIST=$(cat <<'EOF'
EOF
)

# ---------------------------------------------------------------------------
# Collect candidate files.
# ---------------------------------------------------------------------------
# Portable (bash 3.2 / macOS) replacement for `mapfile`.
DART_FILES=()
while IFS= read -r _line; do DART_FILES+=("$_line"); done < <(find "${SCAN_ROOT}" -type f -name '*.dart' | sort)

if [ "${#DART_FILES[@]}" -eq 0 ]; then
  echo "error: no .dart files under ${SCAN_ROOT}" >&2
  exit 2
fi

VIOLATIONS=0

# ---------------------------------------------------------------------------
# Filter step — drop files that are allowlisted (repo-relative match).
# ---------------------------------------------------------------------------
filtered_files=()
for f in "${DART_FILES[@]+"${DART_FILES[@]}"}"; do
  rel="${f#${REPO_ROOT}/}"
  if [ -s "${ALLOWLIST_TMP}" ] && grep -Fxq "${rel}" "${ALLOWLIST_TMP}"; then
    continue
  fi
  filtered_files+=("$f")
done

# ---------------------------------------------------------------------------
# Scan. For each `final <Type> <name>;` declaration:
#   - capture Type and field name
#   - apply rules below
#
# We deliberately only match `final` field declarations (the canonical
# CoreXxxStyle / ResolvedXxx slot shape). Constructor params and
# copyWith named args are out of scope — the field declaration is the
# single source of truth.
# ---------------------------------------------------------------------------
report() {
  # $1 file (absolute)  $2 line  $3 message
  local rel="${1#${REPO_ROOT}/}"
  echo "${rel}:${2}: ${3}"
  VIOLATIONS=$((VIOLATIONS + 1))
}

for f in "${filtered_files[@]+"${filtered_files[@]}"}"; do
  # grep -nE prints `<lineno>:<content>`; we then parse with awk.
  # Match `  final <type> <name>;` allowing leading whitespace + nullable types.
  # Examples that match:
  #   final double? sectionSpacing;
  #   final CoreGapStyle? headerBodyGapStyle;
  #   final double? panelGap;
  # Examples we skip (no `final` keyword): constructor params, copyWith args.
  while IFS= read -r hit; do
    # hit format: "<lineno>:<content>"
    lineno="${hit%%:*}"
    content="${hit#*:}"

    # awk extracts type token and identifier token from the `final ...;` line.
    parsed=$(printf '%s\n' "${content}" \
      | awk '{
          # Strip leading whitespace.
          sub(/^[ \t]+/, "", $0);
          # Require leading `final ` keyword.
          if ($1 != "final") { exit 0 }
          # $2 = type, $3 = identifier (drop trailing `;`).
          type = $2;
          name = $3;
          sub(/;.*$/, "", name);
          # Ignore if name is empty (multi-line decl — out of scope).
          if (length(name) == 0) exit 0;
          print type "\t" name;
        }')

    [ -z "${parsed}" ] && continue

    field_type="${parsed%%$'\t'*}"
    field_name="${parsed#*$'\t'}"

    # Field-name allowlist short-circuit (e.g. legacy TextStyle row/line spacing).
    if [ -n "${FIELD_NAME_ALLOWLIST}" ] \
       && grep -Fxq "${field_name}" <<<"${FIELD_NAME_ALLOWLIST}"; then
      continue
    fi

    case "${field_name}" in
      # -----------------------------------------------------------------
      # Rule A: *GapStyle MUST be CoreGapStyle?
      # -----------------------------------------------------------------
      *GapStyle)
        if [ "${field_type}" != "CoreGapStyle?" ]; then
          report "$f" "${lineno}" \
            "field '${field_name}' suffix 'GapStyle' requires type 'CoreGapStyle?', found '${field_type}' (CoreXxxStyle gap slot rule)"
        fi
        ;;

      # -----------------------------------------------------------------
      # Rule B: *Spacing MUST be double?
      # iconSpacing is whitelisted (it already is double?, but kept
      # explicit for future-proofing). rowSpacing / lineSpacing on
      # TextStyle-shaped contracts likewise stay double?.
      # -----------------------------------------------------------------
      *Spacing)
        case "${field_name}" in
          iconSpacing|rowSpacing|lineSpacing)
            # Allowlisted by name — still enforce double? to prevent drift.
            if [ "${field_type}" != "double?" ]; then
              report "$f" "${lineno}" \
                "allowlisted spacing field '${field_name}' must remain type 'double?', found '${field_type}'"
            fi
            ;;
          *)
            if [ "${field_type}" != "double?" ]; then
              report "$f" "${lineno}" \
                "field '${field_name}' suffix 'Spacing' requires type 'double?', found '${field_type}' (raw scalar slot rule)"
            fi
            ;;
        esac
        ;;

      # -----------------------------------------------------------------
      # Rule C: bare *Gap (not *GapStyle, not *Spacing) is AMBIGUOUS.
      # Author must rename to either xxxGapStyle (nested Style slot)
      # or xxxSpacing (raw double).
      # -----------------------------------------------------------------
      *Gap)
        report "$f" "${lineno}" \
          "field '${field_name}' has ambiguous 'Gap' suffix — rename to '${field_name}Style' (CoreGapStyle? slot) or '${field_name%Gap}Spacing' (double? raw scalar)"
        ;;
    esac

  done < <(grep -nE '^\s*final\s+[A-Za-z0-9_<>,\? ]+\s+[A-Za-z_][A-Za-z0-9_]*\s*;' "$f" || true)
done

# ---------------------------------------------------------------------------
# Summary + exit.
# ---------------------------------------------------------------------------
if [ "${VIOLATIONS}" -gt 0 ]; then
  echo "" >&2
  echo "check_gap_spacing_naming: ${VIOLATIONS} violation(s) found." >&2
  echo "See CLAUDE.md '1:1:1:1 Field Mapping' rule + feedback_one_to_one_field_mapping." >&2
  exit 1
fi

exit 0
