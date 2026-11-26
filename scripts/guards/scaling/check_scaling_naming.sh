#!/usr/bin/env bash
# check_scaling_naming.sh — Anti-Pattern E: scaling 추출 변수명 통일 가드.
#
# Flutter resolver(`*_style.dart`) 안에서 `theme.scaling` 을 두 번 이상
# 참조하면서 추출 변수명을 `scaling` 이외(`final s`, `final scale`,
# `final scalingFactor` 등)로 잡거나, 추출 없이 인라인(`width * theme.scaling`)
# 으로 직접 곱하는 경우를 차단한다.
#
# 규칙:
#   V1) `final <name> = theme.scaling` 의 `<name>` 은 반드시 `scaling`.
#       (`final s = theme.scaling;`, `final scale = theme.scaling;`,
#        `final scalingFactor = theme.scaling;` 등 ❌)
#   V2) 한 파일에서 `theme.scaling` 이 2회 이상 등장하면 모든 사용처는
#       추출된 로컬 `scaling` 변수를 통해야 한다. `* theme.scaling` /
#       `theme.scaling *` 같이 인라인 직사용이 한 번이라도 보이면 ❌.
#
# 예외:
#   E1) `theme.scaling` 이 코드(주석/문서주석 제외)에서 정확히 1회만 등장
#       하면 인라인 직사용을 허용한다 (`width * theme.scaling` 1회 OK).
#   E2) 문서 주석(`///`, `//`, `/**`, ` * `) 및 단일 인용 문자열 리터럴
#       안의 `theme.scaling` 토큰은 카운트/매칭에서 제외.
#
# 위반 출력 형식:
#   <file>:<line>: scaling var name violation — use "final scaling = theme.scaling;"
#
# 종료 코드: 위반 1건 이상이면 1, 없으면 0.
#
# Usage:
#   ./scripts/check_scaling_naming.sh [path]
#
# `path` 가 주어지면 그 경로 하위 `*_style.dart` 만 검사. 생략 시 기본값은
# `packages/coui_flutter/lib/src/components`.

set -u

ROOT="${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
SCAN_PATH="${1:-packages/coui_flutter/lib/src/components}"

cd "$ROOT"

if [ ! -d "$SCAN_PATH" ]; then
  echo "error: scan path not found: $SCAN_PATH" >&2
  exit 2
fi

violations=0

# Gather all *_style.dart under SCAN_PATH that mention theme.scaling at
# least once (anywhere — including comments). The per-file scan below
# applies the comment/string exclusions properly.
files=$(find "$SCAN_PATH" -type f -name '*_style.dart' -print0 \
  | xargs -0 grep -l 'theme\.scaling' 2>/dev/null || true)

if [ -z "$files" ]; then
  echo "OK: no *_style.dart references to theme.scaling in $SCAN_PATH"
  exit 0
fi

while IFS= read -r file; do
  [ -n "$file" ] || continue
  [ -f "$file" ] || continue

  # Sanitize: blank out (per-line) `///` doc comments, `//` line
  # comments, single-line `/* … */` block comments, and single-quoted
  # string literal bodies. This drops the `theme.scaling` token from
  # any commentary while preserving the original line numbering.
  sanitized=$(awk '
    {
      line = $0
      # Strip single-line /* ... */ block comments.
      gsub(/\/\*[^*]*\*+([^\/*][^*]*\*+)*\//, "", line)
      # Strip from `///` doc comments to EOL.
      sub(/\/\/\/.*$/, "", line)
      # Strip from `//` line comments to EOL.
      sub(/\/\/.*$/, "", line)
      # Strip single-quoted string literal bodies (keeps the quotes).
      gsub(/'\''[^'\'']*'\''/, "'\'''\''", line)
      print line
    }
  ' "$file")

  # ---- V1: wrong extraction variable name -------------------------------
  v1_lines=$(printf '%s\n' "$sanitized" \
    | grep -nE 'final[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*=[[:space:]]*theme\.scaling' \
    | grep -vE 'final[[:space:]]+scaling[[:space:]]*=[[:space:]]*theme\.scaling' \
    || true)

  if [ -n "$v1_lines" ]; then
    while IFS= read -r hit; do
      [ -z "$hit" ] && continue
      lineno="${hit%%:*}"
      printf '%s:%s: scaling var name violation — use "final scaling = theme.scaling;"\n' \
        "$file" "$lineno"
      violations=$((violations + 1))
    done <<EOF
$v1_lines
EOF
  fi

  # ---- V2: inline `theme.scaling` when file uses it 2+ times -----------
  code_uses=$(printf '%s\n' "$sanitized" | grep -cE 'theme\.scaling' || true)
  code_uses="${code_uses:-0}"

  if [ "$code_uses" -ge 2 ]; then
    v2_lines=$(printf '%s\n' "$sanitized" \
      | grep -nE 'theme\.scaling' \
      | grep -vE 'final[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*=[[:space:]]*theme\.scaling' \
      || true)

    if [ -n "$v2_lines" ]; then
      while IFS= read -r hit; do
        [ -z "$hit" ] && continue
        lineno="${hit%%:*}"
        printf '%s:%s: scaling var name violation — use "final scaling = theme.scaling;"\n' \
          "$file" "$lineno"
        violations=$((violations + 1))
      done <<EOF
$v2_lines
EOF
    fi
  fi
done <<EOF
$files
EOF

if [ "$violations" -gt 0 ]; then
  {
    echo ""
    echo "Found $violations scaling-naming violation(s) in $SCAN_PATH."
    echo "Rule (Anti-Pattern E): extract once as 'final scaling = theme.scaling;'"
    echo "and reuse the local 'scaling' variable. Single-use inline is allowed"
    echo "only when 'theme.scaling' appears exactly once in the file."
  } >&2
  exit 1
fi

echo "OK: no scaling-naming violations in $SCAN_PATH"
exit 0
