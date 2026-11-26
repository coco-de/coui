#!/usr/bin/env bash
# check_resolver_scaling.sh — Anti-Pattern F (dimensional resolver missing scaling).
#
# Rule:
#   *_style.dart 의 `class Resolved<Comp>` 가 dimensional 필드
#   (double / Size / EdgeInsets / EdgeInsetsGeometry / BorderRadius /
#    BorderRadiusGeometry / CoreEdgeInsets / CoreBorderRadius / Radius) 를
#   하나라도 선언하면, 그 파일의 resolve* 함수가 반드시 `theme.scaling` 을
#   사용 (직접 `* theme.scaling` 또는 `final scaling = theme.scaling;` 캡처)
#   해야 한다. 그렇지 않으면 접근성 텍스트 스케일 / DPI 스케일이 반영되지
#   않은 paint-ready 값이 위젯으로 흘러간다 (Epic #1148 accessibility-parity
#   regression class 의 Flutter 측 미러).
#
# 검출 방식:
#   1) `class Resolved[A-Z]` 라인을 가진 *_style.dart 만 후보.
#   2) 그 파일에 위 dimensional 타입 필드 선언 (`^\s*final <T>[?!]?\s+name;`)
#      이 1개라도 있는지 확인.
#   3) 파일 어딘가에 `theme.scaling` 토큰이 등장하면 PASS (직접/캡처 양쪽 OK).
#
# Exceptions (renderer / paint-only / ratio-only — scaling 적용 불요):
#   • 파일 단위 화이트리스트:
#       clickable_style.dart / hover_style.dart / scrollview_style.dart /
#       aspect_ratio_box_style.dart / media_query_style.dart /
#       gap_style.dart          (Gap = paint-only, 부모가 scaling 적용)
#       icon_style.dart         (Icon 별도 가드에서 처리)
#       breakpoint_style.dart   (judgement-only — observes raw
#                                MediaQuery.sizeOf viewport width to pick a
#                                CoreBreakpoint tier; same category as
#                                media_query_style.dart above. Scaling the
#                                observed width would mis-classify the tier
#                                whenever accessibility text-scale is active)
#       dropdown_menu_style.dart (its only dimensional field, `menuOffset`,
#                                is a placement-axis trigger↔panel gap
#                                intentionally left unscaled to match the
#                                raw Web `OverlayPositioner` offset and
#                                `ResolvedMenubar.menuOffset` — scaling it
#                                would desync the vertical gap from Web,
#                                same regression class documented in
#                                menubar_style.dart)
#       swiper_style.dart       (its only dimensional fields are the
#                                deprecated `dragHandle*` readouts, copied
#                                from the composed Drawer's resolver, which
#                                scales them — scaling them here would scale
#                                twice. Drop this entry with those fields.)
#   • 필드명 단위 제외 (ratio / factor / opacity / velocity / breakpoint /
#     clickable / scale 류): 해당 필드만 dimensional 카운트에서 빼고,
#     남은 dimensional 필드가 0 이면 PASS.
#
# 사용: ./scripts/check_resolver_scaling.sh [dir-or-file]
#   기본 스캔: packages/coui_flutter/lib/src/components
# Exit 1 if any violation.

set -uo pipefail
TARGET="${1:-packages/coui_flutter/lib/src/components}"

# ── 파일 단위 화이트리스트 (basename 매칭) ─────────────────────────────
EXEMPT_FILES=(
  "clickable_style.dart"
  "hover_style.dart"
  "scrollview_style.dart"
  "aspect_ratio_box_style.dart"
  "media_query_style.dart"
  "gap_style.dart"
  "icon_style.dart"
  "breakpoint_style.dart"
  "dropdown_menu_style.dart"
  "swiper_style.dart"
)

is_exempt_file() {
  local base
  base="$(basename "$1")"
  local ex
  for ex in "${EXEMPT_FILES[@]+"${EXEMPT_FILES[@]}"}"; do
    [ "$base" = "$ex" ] && return 0
  done
  return 1
}

# ── 필드명 단위 제외 패턴 (ratio/factor/opacity/velocity/breakpoint/scale) ──
# 정규식: 필드 식별자 어디든 토큰이 박혀 있으면 dimensional 카운트에서 제외.
# `[Ss]cale$` generalises what `pressedScale` / `hoverScale` spelled out
# one at a time: a field NAMED for a scale is a multiplier, not a length,
# and multiplying a multiplier by the density factor is the double-scale
# this guard exists to prevent. Without it `card_image`'s `normalScale`
# read as an unscaled dimension the moment the `theme.scaling` check
# stopped matching doc comments.
EXEMPT_FIELD_RE='[Rr]atio|[Ff]actor|[Oo]pacity|[Vv]elocity|[Bb]reakpoint|[Cc]lickable|[Ss]cale[A-Z]|[Ss]cale$|^scale$|fadeOpacity|disabledOpacity'

# 대상 파일 목록
# Portable (bash 3.2 / macOS) replacement for `mapfile`.
FILES=()
while IFS= read -r _line; do FILES+=("$_line"); done < <(find "$TARGET" -name '*_style.dart' 2>/dev/null | sort)

v=0
report=""

for f in "${FILES[@]+"${FILES[@]}"}"; do
  [ -z "$f" ] && continue

  # Resolved* 클래스가 없으면 스킵 (Anti-Pattern F 적용 대상 아님)
  grep -qE '^class Resolved[A-Z][A-Za-z0-9]*\b' "$f" 2>/dev/null || continue

  # 파일 화이트리스트
  is_exempt_file "$f" && continue

  # dimensional 필드 (선언만; 문서주석/일반주석은 자연스럽게 매치 안 됨)
  # 매치 라인 → 필드명 추출 → 제외 패턴 적용 → 잔여 카운트
  # No `-n`: the loop greps ONE file at a time, so grep prints no
  # filename, and the extraction below used to expect `file:line:` and
  # get `line:`. It therefore matched nothing and passed the whole line
  # through — meaning the field-name exemptions were applied to
  # `  final double hoverScale;` rather than to `hoverScale`, and only
  # the entries that happened to be literal substrings of a declaration
  # line ever fired. Anchored patterns like `^scale$` could not match by
  # construction. Extract the bare identifier instead.
  remaining=$(grep -hE '^[[:space:]]+final (double|Size|EdgeInsets|EdgeInsetsGeometry|BorderRadius|BorderRadiusGeometry|CoreEdgeInsets|CoreBorderRadius|Radius)[?!]?[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*' "$f" 2>/dev/null \
    | sed -E 's/^[[:space:]]*final [A-Za-z]+[?!]?[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*).*/\1/' \
    | grep -vE "$EXEMPT_FIELD_RE" \
    | wc -l | tr -d ' ')

  [ "$remaining" -eq 0 ] && continue

  # theme.scaling 사용 여부 (직접 곱하기든 `final scaling = theme.scaling;` 캡처든 OK)
  # Comments stripped BEFORE the check. A whole-file grep reads prose:
  # `button_style.dart` carried three doc comments explaining where
  # `theme.scaling` gets applied (by `Gap`, by `Clickable`, "pre-scaling
  # units") and applied it nowhere itself — the guard matched the words
  # and passed the file for years while every Button dimension stayed
  # unscaled. A rule that a doc comment can satisfy is a rule about
  # documentation.
  #
  # 파이프가 아니라 herestring 으로 먹인다. `sed "$f" | grep -q` 는 `grep -q` 가
  # 첫 매치에서 즉시 끝나 남은 입력을 쓰던 `sed` 를 SIGPIPE 로 죽이고, 위에 켜 둔
  # `pipefail` 이 그 죽음(141)을 파이프라인 상태로 올려 **매치를 실패로 뒤집는다**.
  # 그러면 결백한 파일이 continue 를 못 타고 위반으로 보고된다.
  #
  # 여기서는 침묵하지 않고 **빨갛게** 난다 — 그래서 더 나쁘다. 같은 커밋에서
  # 20 회 중 5 회 실패했고, 필수 CI 체크라 무관한 PR 이 무작위로 막혔다. 사람이
  # 배우는 것은 "가드를 읽어라" 가 아니라 "다시 돌려라" 다.
  #
  # 왜 항상이 아니라 가끔인가: 매치 뒤 남은 바이트가 커널 파이프 버퍼(맥 기본
  # 16KB)를 넘어야 `sed` 가 아직 쓰고 있다. 실측 — `button_style.dart` 는 주석을
  # 지운 뒤 18,428 바이트이고 매치가 3,197 바이트 지점이라 잔여 15,231 바이트가
  # 그 경계 바로 아래에 앉는다. 스케줄링이 결과를 정한다.
  #
  # 이 함정은 이 저장소에서 이미 한 번 문서화됐다
  # (check_document_index_installed.sh · check_build_order_shared.sh) — 그쪽은
  # 뒤집힘이 `|| continue` 로 흘러 조용한 초록이 됐다.
  _stripped=$(sed -E 's://.*::' "$f" 2>/dev/null)
  if grep -qE 'theme\.scaling' <<<"$_stripped"; then
    continue
  fi

  rel="${f#packages/coui_flutter/lib/src/components/}"
  report+="F  ${rel}  [dimensional resolver missing scaling extraction (add \"final scaling = theme.scaling;\")] dim_remaining=${remaining}"$'\n'
  v=$((v+1))
done

if [ "$v" -eq 0 ]; then
  echo "✅ resolver scaling (Anti-Pattern F): 통일 위반 없음 in $TARGET"
  exit 0
fi

echo "❌ resolver scaling (Anti-Pattern F): $v 개 위반"
echo ""
printf '%s' "$report" | head -60
[ "$v" -gt 60 ] && echo "    ... ($((v - 60)) more)"
echo ""
echo "정정: Resolved* 가 dimensional 필드 (double/Size/EdgeInsets/BorderRadius/"
echo "      Radius/CoreEdgeInsets/CoreBorderRadius) 를 가지면 resolve 함수에"
echo "      \`final scaling = theme.scaling;\` 캡처 또는 \`* theme.scaling\` 직접 적용 필수."
echo "      paint-only/ratio-only renderer (clickable/hover/scrollview/aspect_ratio_box/"
echo "      media_query/gap/icon) 는 exempt — 새 파일 추가 시 EXEMPT_FILES 갱신."
exit 1
