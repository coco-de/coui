#!/usr/bin/env bash
# check_widget_scaling.sh — Anti-Pattern C: widget-side scaling 검출 가드.
#
# 원칙 (Epic #1603 C11/C13, #1601 paint-ready):
#   {Component} widget(co_*.dart)은 render-only 여야 한다. `theme.scaling` 곱셈은
#   resolver(*_style.dart)의 책임 — Resolved* 가 paint-ready (scaling-pre-applied)
#   값을 들고 나오면 widget 은 `resolved.x` 만 읽고 곱셈 없이 위젯에 박는다.
#   widget 안에 `* scaling`, `* theme.scaling`, `* Theme.of(context).scaling`
#   가 보이면 resolver bypass — Anti-Pattern C.
#
# 정정 방향:
#   1) `*_style.dart` resolver 에서 `merged.<field> ?? defaultY` 직후 `* scaling`
#      을 한 번에 적용해 Resolved 의 paint-ready 필드로 emit.
#   2) widget(co_*.dart) 은 `resolved.<field>` 만 읽고 별도 `* scaling` 금지.
#
# 스캔: packages/coui_flutter/lib/src/components/**/co_*.dart
#   - `*_style.dart` 는 scope 밖 (resolver 가 scaling 곱하는 건 정답).
#   - 비-접두 legacy 위젯(button.dart, color_picker.dart, select.dart 등)은
#     {Component} 미통일 컴포넌트이므로 이 가드 범위 외 (별도 통일화 Epic
#     완료 후 자동으로 co_*.dart 로 승격되며 가드 적용).
#
# 예외 (스킵 처리):
#   - `//` 한줄 주석 / `///` 문서 주석 (라인 시작이 주석)
#   - 라인 안에 `*scaling` 패턴이 string literal('...' / "...") 내부에 위치
#     하면 grep 결과에서 후처리 제외 (간단한 동일라인 따옴표 검사로).
#
# 출력: file:line: widget-side scaling — resolver should pre-apply scaling
#       for paint-ready output
# Exit 1 if any violation.

set -uo pipefail
TARGET="${1:-packages/coui_flutter/lib/src/components}"

# Ratchet baseline — 이 가드가 `co_*.dart` 를 글롭하던 동안(= 0개 파일) 위젯 쪽
# `* scaling` 이 세 자리에 쌓였다. 가드를 되살리면서 그것을 즉시 red 로 만들면 이
# PR 이 무관한 리팩터를 떠안게 되므로, **명시적 baseline** 으로 고정하고 별도
# 이슈로 0 까지 내린다. 이 값은 **내려가기만 한다.**
#
#   color_picker_internal.dart:452,489  `_kPreviewLabelOffset * theme.scaling`
#   form_field.dart:371                 `EdgeInsets.all(CoreSpace.space16) * theme.scaling`
BASELINE="${WIDGET_SCALING_BASELINE:-3}"

v=0
report=""

# 대상: 위젯 파일 (`*_style.dart` = resolver 는 제외 — 거기가 `* scaling` 의 제자리다).
#
# ⚠️ 예전에는 `co_*.dart` 를 글롭했다. `co_` 접두는 레포 전역에서 제거됐는데 글롭이
#    따라오지 않아 이 가드는 **0개 파일**을 훑으며 매번 "위반 없음" 을 보고했다 —
#    초록인데 아무것도 지키지 않는 상태였다. 범위를 다시 좁힐 일이 있으면 회귀를
#    주입해 실제로 실패하는지 확인하고 바꿔라.
#
# Portable (bash 3.2 / macOS) replacement for `mapfile`.
FILES=()
while IFS= read -r _line; do FILES+=("$_line"); done < <(find "$TARGET" -name '*.dart' ! -name '*_style.dart' 2>/dev/null | sort)

for f in "${FILES[@]+"${FILES[@]}"}"; do
  [ -z "$f" ] && continue

  # 패턴:
  #   `* scaling`              — local scaling 변수에 곱
  #   `* theme.scaling`        — theme receiver 직접 곱
  #   `* Theme.of(context).scaling` — Theme.of 인라인 곱
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue

    line_no="${hit%%:*}"
    rest="${hit#*:}"
    code="$rest"

    # 주석 라인 제외 (라인 시작이 // 또는 ///)
    if grep -qE "^[[:space:]]*///|^[[:space:]]*//" <<<"$code"; then
      continue
    fi

    # string literal 안인지 거친 판정:
    #   * scaling 매치 위치 기준 좌측에 홀수 개의 ' 또는 " 가 있으면 string 내부로 간주.
    # bash 만으로 정확히 보긴 어렵지만, 단순 휴리스틱으로 동일 라인의 첫 match 가
    # quote pair 안에 통째로 들어있는 케이스를 잡는다.
    prefix="${code%%\* scaling*}"
    if [ "$prefix" != "$code" ]; then
      q1=$(printf '%s' "$prefix" | tr -cd "'" | wc -c | tr -d ' ')
      q2=$(printf '%s' "$prefix" | tr -cd '"' | wc -c | tr -d ' ')
      if [ $((q1 % 2)) -ne 0 ] || [ $((q2 % 2)) -ne 0 ]; then
        continue
      fi
    fi

    rel="${f#packages/coui_flutter/lib/src/components/}"
    report+="${rel}:${line_no}: widget-side scaling — resolver should pre-apply scaling for paint-ready output"$'\n'
    v=$((v+1))
  done < <(grep -nE "\* scaling\b|\* theme\.scaling\b|\* Theme\.of\(context\)\.scaling\b" "$f" 2>/dev/null)
done

if [ "$v" -le "$BASELINE" ]; then
  if [ "$v" -eq 0 ]; then
    echo "✅ widget scaling: Anti-Pattern C 위반 없음 in $TARGET"
  else
    echo "✅ widget scaling: $v 개 (baseline $BASELINE) — net-new 없음 in $TARGET"
    [ "$v" -lt "$BASELINE" ] && echo "   ↓ baseline 을 $v 로 내려라."
  fi
  exit 0
fi

echo "❌ widget scaling: $v 개 위반 > baseline $BASELINE (Anti-Pattern C — widget 안에서 * scaling 곱셈):"
echo ""
printf '%s' "$report" | head -60
[ "$v" -gt 60 ] && echo "    ... ($((v - 60)) more)"
echo ""
echo "정정: resolver(*_style.dart)에서 'merged.<field> ?? defaultY' 후 한 번에 * scaling 적용 →"
echo "      Resolved.<field> 로 paint-ready emit, widget 은 resolved.<field> 만 읽기."
exit 1
