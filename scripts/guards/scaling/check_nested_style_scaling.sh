#!/usr/bin/env bash
# check_nested_style_scaling.sh — Anti-Pattern A guard (#1659/#2210 mirror).
#
# 검출 대상 — Flutter resolver(`*_style.dart`)가 **자식 컴포넌트의 nested
# `CoreXxxStyle` 슬롯**을 만들면서 부모의 `theme.scaling` 을 baking 해 넣는
# 안티패턴.
#
#   nested Style slot 은 자식 resolver(`resolveIcon`/`resolveGap` 등)가
#   다시 받아 자기 `theme.scaling` 으로 처리하는 단위다. 부모가 미리 곱해
#   넘기면 자식이 한 번 더 곱해 **이중 스케일**되거나, "raw forward" 표준이
#   깨져 자식 컴포넌트별로 paint 정합성이 흐트러진다. 부모는 **raw 값** 만
#   슬롯에 실어 보내고, 스케일링은 자식에게 위임해야 한다.
#
# 잡는 두 가지 형태:
#
#   (A) copyWith 변이형
#       `final <name>Style = <merged>.copyWith( ... size: ... * scaling ... );`
#       — 좌변 변수명이 `Style` 로 끝나고, copyWith body 안에서 `size:` 가
#         `* scaling` 을 곱한다.
#
#   (B) 생성자형
#       `final <name>Style = CoreXxxStyle( ... size: ... * scaling ... );`
#       — 좌변 변수명이 `Style` 로 끝나고, `Core[A-Z]\w*Style(` 생성자의
#         `size:` 가 `* scaling` 을 곱한다.
#
# 허용(`Resolved*` 출력은 paint-ready 가 본분):
#
#   - `return ResolvedXxx( ... size: ... * scaling )` — Resolver 자기
#     출력 필드는 paint-ready 가 정상.
#   - 슬롯이 아닌 컴포넌트-자체 scalar(예: `final iconSize = ... * scaling`)
#     — `Style` 접미 변수가 아니라서 잡지 않는다.
#
# 위반 시 메시지: 자식 resolver 가 self-scale 하도록 부모는 raw 값을
# slot 에 forward 하라.
#
# 사용: ./scripts/check_nested_style_scaling.sh [dir-or-file]
#   기본 스캔 경로: packages/coui_flutter/lib/src/components
# exit 1 if any violation.

set -uo pipefail

TARGET="${1:-packages/coui_flutter/lib/src/components}"

if [[ ! -e "$TARGET" ]]; then
  echo "check_nested_style_scaling: target not found: $TARGET" >&2
  exit 2
fi

# 스캔 대상 — *_style.dart (resolver 파일) 만.
# Portable (bash 3.2 / macOS) replacement for `mapfile`.
FILES=()
while IFS= read -r _line; do FILES+=("$_line"); done < <(find "$TARGET" -type f -name '*_style.dart' | sort)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "check_nested_style_scaling: no *_style.dart files under $TARGET" >&2
  exit 0
fi

TMP_REPORT="$(mktemp -t nested_style_scaling.XXXXXX)"
trap 'rm -f "$TMP_REPORT"' EXIT

# awk 상태 머신:
#   - 한 줄씩 읽으면서 "Style 접미 변수 할당 시작" 을 감지하면 블록 모드 진입.
#   - 블록 종료(닫는 ");") 전까지 `size:` 라인을 모아 `* scaling` 검사.
#   - 시작 패턴 두 종류:
#       (A) ... <name>Style = <expr>.copyWith(
#       (B) ... <name>Style = Core[A-Z]\w*Style(
#   - 한 줄에서 시작·종료가 모두 일어나는 경우(드물지만 가능) 동일 라인 검사.
for f in "${FILES[@]+"${FILES[@]}"}"; do
  awk -v FNAME="$f" '
    function strip_comment(s,   i) {
      i = index(s, "//")
      if (i > 0) s = substr(s, 1, i - 1)
      return s
    }

    BEGIN {
      in_block = 0
      depth = 0
      kind = ""
    }

    {
      line = $0
      lineno = NR
      code = strip_comment(line)

      if (in_block == 0) {
        # 시작 감지 — 좌변이 `Style` 로 끝나는 변수에 copyWith / Core*Style(
        # 가 호출되는 첫 줄.
        if (match(code, /[a-zA-Z_][a-zA-Z0-9_]*Style[[:space:]]*=[[:space:]]*[^;]*\.copyWith[[:space:]]*\(/)) {
          in_block = 1
          kind = "copyWith"
        } else if (match(code, /[a-zA-Z_][a-zA-Z0-9_]*Style[[:space:]]*=[[:space:]]*Core[A-Z][A-Za-z0-9_]*Style[[:space:]]*\(/)) {
          in_block = 1
          kind = "ctor"
        }

        if (in_block == 1) {
          depth = 0
          # 현재 줄에서 괄호 깊이 계산
          tmp = code
          gsub(/[^()]/, "", tmp)
          for (i = 1; i <= length(tmp); i++) {
            c = substr(tmp, i, 1)
            if (c == "(") depth++
            else if (c == ")") depth--
          }

          # 같은 줄에서 size: ... * scaling 위반 즉시 검사
          if (code ~ /size[[:space:]]*:/ && code ~ /\*[[:space:]]*scaling/) {
            printf "%s:%d: nested Style slot scaling — child resolver should self-scale (use raw forward) [%s]\n", FNAME, lineno, kind
          }

          if (depth <= 0) {
            in_block = 0
          }
          next
        }
      } else {
        # 블록 내부 — 괄호 깊이 갱신 후 `size:` 줄 검사.
        tmp = code
        gsub(/[^()]/, "", tmp)
        for (i = 1; i <= length(tmp); i++) {
          c = substr(tmp, i, 1)
          if (c == "(") depth++
          else if (c == ")") depth--
        }

        if (code ~ /size[[:space:]]*:/ && code ~ /\*[[:space:]]*scaling/) {
          printf "%s:%d: nested Style slot scaling — child resolver should self-scale (use raw forward) [%s]\n", FNAME, lineno, kind
        }

        if (depth <= 0) {
          in_block = 0
        }
      }
    }
  ' "$f" >> "$TMP_REPORT"
done

if [[ -s "$TMP_REPORT" ]]; then
  cat "$TMP_REPORT"
  COUNT=$(wc -l < "$TMP_REPORT" | tr -d ' ')
  echo ""
  echo "check_nested_style_scaling: ${COUNT} violation(s) found." >&2
  echo "Fix: nested CoreXxxStyle slot 은 raw 값(스케일 미적용)으로 forward 하라." >&2
  echo "     child resolver(resolveIcon/resolveGap 등) 가 자체 theme.scaling 으로 처리한다." >&2
  exit 1
fi

echo "check_nested_style_scaling: PASS (0 violations)."
exit 0
