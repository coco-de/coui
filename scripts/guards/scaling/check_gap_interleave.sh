#!/usr/bin/env bash
# check_gap_interleave.sh — Guard 8: for-loop + Gap interleave 차단
#
# 안티 패턴: widget 안에서 N children 사이 균등 분포 spacing 을 위해
# `for (i = 0; ...) { if (i > 0) Gap(...) }` interleave 또는
# `children.add(Gap(...))` 균등 누적 패턴 사용.
#
# CLAUDE.md PART 1 룰: 균등 분포는 native API 사용:
#   - Row(spacing:) / Column(spacing:) / Wrap(spacing:) / GridView(mainAxisSpacing:)
#   - Web: flex/grid container 의 CSS `gap`
# Gap 위젯은 1-off spacer (명명된 두 sibling 사이) 전용.
#
# 차단 패턴:
#   1. `if (i > 0) ... Gap` — index 기반 interleave
#   2. `if (index > 0) ... Gap`
#   3. `stars.add(Gap(...))` / `cells.add(Gap(...))` / `children.add(Gap(...))`
#      inside `for` loop body
#
# Scan paths:
#   - packages/coui_flutter/lib/src/components/**/co_*.dart  (active widgets)
#
# Exception:
#   - @Deprecated 마커 파일 (legacy widgets — exempted automatically)
#   - *_style.dart resolver files (정통: resolver 가 nested CoreGapStyle 생성)
#
# Exit code: 0 if clean, 1 on any violation.

set -u

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

readonly SCAN_ROOT="${REPO_ROOT}/packages/coui_flutter/lib/src/components"

if [ ! -d "${SCAN_ROOT}" ]; then
  echo "error: scan root not found: ${SCAN_ROOT}" >&2
  exit 2
fi

violations=0
violation_lines=""

# Find all co_*.dart files and inspect for interleave patterns.
while IFS= read -r -d '' file; do
  # Skip @Deprecated legacy files
  if grep -q "@Deprecated" "$file" 2>/dev/null; then
    continue
  fi
  # Skip allow-listed files (user-supplied spacer item patterns, etc.)
  case "$file" in
    */navigation_bar/co_navigation_bar.dart)
      # NavigationItem.gap variant — explicit user-supplied 1-off spacer, not interleave
      continue
      ;;
  esac

  # Detect "for (...) { ... if (i > 0) ... Gap }" or "for (...) { ... cells.add(Gap }" patterns.
  # Strategy: line-by-line scan keeping track of for-loop body depth, flag Gap
  # inside a for that is preceded by an `if (i > 0)` or similar index check, or
  # `<list>.add(Gap(` inside a for-loop body.
  awk -v file="$file" '
    BEGIN {
      depth_for = 0
      i_seen = 0
    }
    # Track for-loop entry (simple heuristic)
    /^[[:space:]]*for[[:space:]]*\(/ {
      depth_for++
      i_seen = 1   # variable named `i`, `index` likely
      for_start_line = NR
      next
    }
    # `if (i > 0)` or `if (index > 0)` inside a for-loop = interleave gate
    depth_for > 0 && /if[[:space:]]*\([[:space:]]*(i|index)[[:space:]]*>[[:space:]]*0[[:space:]]*\)/ {
      gate_seen = 1
      gate_line = NR
      next
    }
    # Interleaved Gap detection cases (inside for-loop body):
    #   case A: gate_seen → next Gap line is interleave
    #   case B: `xxxList.add(Gap(...))` inside for
    depth_for > 0 && /Gap[[:space:]]*\(/ {
      if (gate_seen && (NR - gate_line) <= 3) {
        printf "%s:%d: for-loop+Gap interleave (N-sibling 균등 분포) — use Row/Column/Wrap.spacing native API instead\n", file, NR
        gate_seen = 0
      } else if (/\.add[[:space:]]*\(Gap/) {
        printf "%s:%d: list.add(Gap(...)) inside for-loop — N-sibling interleave anti-pattern\n", file, NR
      }
    }
    # Simple brace tracking to know when for-loop body closes (heuristic)
    /\}/ {
      if (depth_for > 0) {
        # very loose — assume one closing brace per loop
        # (not 100% accurate but flags the common patterns)
        if (NR - for_start_line > 20) {
          depth_for--
          gate_seen = 0
        }
      }
    }
  ' "$file"
# ⚠️ 예전에는 `co_*.dart` 를 글롭했다. `co_` 접두가 레포 전역에서 제거된 뒤 글롭이
#    따라오지 않아 이 가드는 **0개 파일**을 훑으며 매번 "위반 없음" 을 보고했다.
#    `*_style.dart`(resolver)는 제외 — interleave 는 위젯 build 의 문제다.
done < <(find "${SCAN_ROOT}" -type f -name '*.dart' ! -name '*_style.dart' -print0) > /tmp/interleave_violations.$$ 2>&1

# Ratchet baseline — 이 가드가 `co_*.dart`(= 0개 파일)를 글롭하던 동안 쌓인 잔여.
#
#   navigation_bar.dart:331  `case .gap: children.add(Gap(gapStyle: item.gapStyle))`
#
# 이 한 건은 **interleave 가 아니라 호출자가 선언한 gap 항목**이다 — 형제 사이마다
# 자동으로 끼우는 패턴(`if (i > 0) Gap(...)`)이 아니라, 소비자가 아이템 목록에
# `.gap` 종류를 직접 넣은 것을 그리는 자리다. 가드는 for-loop 안의 `add(Gap(...))`
# 형태만 보므로 둘을 구분하지 못한다.
#
# 그래서 0 이 아니라 1 로 둔다. 이 값은 **내려가기만 한다.**
BASELINE="${GAP_INTERLEAVE_BASELINE:-1}"

if [ -s /tmp/interleave_violations.$$ ]; then
  violations=$(wc -l < /tmp/interleave_violations.$$ | tr -d ' ')
  if [ "$violations" -le "$BASELINE" ]; then
    echo "✅ for-loop Gap interleave (Guard 8): $violations 건 (baseline $BASELINE) — net-new 없음"
    [ "$violations" -lt "$BASELINE" ] && echo "   ↓ baseline 을 $violations 로 내려라."
    rm -f /tmp/interleave_violations.$$
    exit 0
  fi
  echo "[$SCRIPT_NAME] for-loop + Gap interleave anti-pattern detected." >&2
  echo "  N-sibling 균등 분포 spacing 은 native API 로 처리:" >&2
  echo "    Flutter: Row(spacing:) / Column(spacing:) / Wrap(spacing:) / GridView(mainAxisSpacing:)" >&2
  echo "    Web    : flex/grid container 의 CSS gap" >&2
  echo "  Gap 위젯은 명명된 두 sibling 사이 1-off spacer 전용." >&2
  echo "" >&2
  cat /tmp/interleave_violations.$$ >&2
  echo "" >&2
  echo "[$SCRIPT_NAME] FAIL — $violations violation(s) > baseline $BASELINE." >&2
  rm -f /tmp/interleave_violations.$$
  exit 1
fi

rm -f /tmp/interleave_violations.$$
echo "✅ for-loop Gap interleave (Guard 8): 위반 없음 in ${SCAN_ROOT#${REPO_ROOT}/}"
exit 0
