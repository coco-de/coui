#!/usr/bin/env bash
# check_flutter_resolver.sh — Epic #1603 / #2210 Flutter resolver 통일 게이트.
#
# `check_web_resolver.sh` 의 Flutter 거울상. 양쪽 RULE 라벨이 같은 원칙을
# 가리키도록 정렬 (A color-path / B single-entry / C paint-ready / D chaining
# / E coverage). Flutter resolver(`packages/coui_flutter/lib/src/components/**/
# *_style.dart`)가 Web 에서 확립한 규율의 Flutter 버전을 지키는지 검출.
#
# RULE A — C7 color-path (최우선, #1601 dark-mode regression class):
#   CoreColor → Flutter Color 는 반드시 `scheme.resolve(x).toValue()` 로만.
#   (A1) forward Flutter `Color(<core>.value)` / dot-shorthand `.new(<core>.value)` /
#        `Color(<core>.toARGB32())` 직접 생성 금지 — resolver(*_style.dart) +
#        widget(co_*.dart) 모든 컴포넌트 `*.dart` 대상. (`Color(c.value)` 는
#        토큰의 light 값을 동결해 dark-mode 에서 깨진다.) 역방향
#        `CoreColor(<flutterColor>.toARGB32())` 브리지(이미 resolved 한 Flutter
#        Color 를 자식 CoreColor API 로 전달)는 negative-prefix 로 제외.
#   (A2) color receiver 의 `.toValue()` standalone (같은 식에 `resolve(` 없음) 금지
#        — `merged.xColor!.toValue()`, `cs.surface.toValue()`, `.scaleAlpha(..).toValue()`.
#        (`*_style.dart` resolver 한정 — widget 은 scheme.X.toValue() 정당 사용 다수.)
#   허용: `scheme.resolve(token).toValue()` (resolve 포함), 자식 슬롯에 CoreColor
#        그대로 forward (`.toValue()` 자체 없음).
#
# RULE B — C1 single-entry:
#   *_style.dart 의 top-level public `resolve[A-Z]*` 함수는 `resolve<Comp>` 하나만.
#   per-slot/per-state public resolver(resolveChipBg, resolveSliderTrackColor 등) +
#   public `merge*CoreTextStyle`/`apply*TextStyle` helper 는 file-private(`_`) 여야.
#   (한 파일에 colocated Co widget 이 여럿이면 resolve* 가 둘 이상일 수 있음 — 그건 허용.)
#
# RULE C — C9 paint-ready:
#   Resolved* 의 raw `double` *Radius/*BorderRadius 필드 금지 (Flutter BorderRadius 여야).
#   Resolved 가 `CoreXxxTheme` / 전체 `CoreXxxStyle`(슬롯 아닌 holder) 저장 금지.
#   예외: 필드 선언 라인에 `// guard-non-rect-radius: <이유>` 트레일링 주석이 있으면
#   skip — 사각형 4-corner 개념이 아닌 단일 scalar(예: 원호 반경)일 때만 쓴다.
#   "애니메이션 lerp 편의상 scalar 로 뭉갰다" 류는 해당 없음(그건 진짜 결함, 예외 아님) —
#   BorderRadius 승격이 가능한데 안 한 케이스는 마커를 달지 말고 고친다(#3260 이 그 예).
#
# RULE D — chaining (Web RULE D 미러, Epic #2210):
#   Flutter resolver(`*_style.dart`) 가 `CoreXxxStyle.defaultYyy` 를 emit
#   (Color/EdgeInsets/BorderRadius 등으로 toValue/scheme.resolve/scaleAlpha
#   체인에 흘러가는) 하면서, 그 `Yyy` 에 대응하는 override 필드 `yyy` 가
#   contract `CoreXxxStyle` 에 존재(`this.yyy`)하는데 resolver 파일에 `merged.yyy`
#   참조가 **전혀 없는** 케이스를 잡는다 (1:1:1:1 ③칸 누락 의 Flutter 측 미러).
#   예외: override 가 nested-slot sub-field(`merged.iconStyle?.color`) 나
#   base-then-merge(`CoreIconStyle(color: default).merge(merged.slot)`) 로
#   들어와 리터럴 `merged.yyy` 매칭이 안 되지만 실제로는 동작하는 경우 —
#   파일 아무 곳에 `// guard-nested-override: <field>` 를 달면 skip.
#   반드시 그 override 가 실제로 도달하는지 확인 후에만 달 것(#3259 사례 참조).
#
# RULE E — coverage (Web RULE E 미러, Epic #2210):
#   contract `CoreXxxStyle` override 필드 yyy 가 Flutter resolver `*_style.dart`
#   에 `merged.yyy` (또는 어떤 객체.yyy) 로 전혀 반영되지 않은 케이스 — 삭제됐거나
#   처음부터 누락. Web 반영 여부도 함께 라벨링 (양쪽 미러 비교).
#   예외: contract 생성자에서 `@Deprecated(...)` 가 붙은 필드는 skip한다 —
#   `process/deprecation.md` 의 표준 폐기 경로로 "더 이상 적용되지 않음"이
#   이미 그 필드 자신의 주석으로 선언돼 있으므로, 미반영이 결함이 아니라
#   의도다(FormattedInput DDR-06/07 — 단일 input 전환으로 세그먼트별
#   폭/간격/구분자 색 개념 자체가 없어짐). Deprecation 은 플랫폼별로 시차를
#   두고 반영될 수 있으므로(Flutter 선행 → Web 후속) 이 skip 은 Web 반영
#   여부와 무관하게 적용된다.
#
# 사용: ./scripts/check_flutter_resolver.sh [dir-or-file]   (기본: 전체)
# exit 1 if any violation.

set -uo pipefail
TARGET="${1:-packages/coui_flutter/lib/src/components}"

# Strict mode (Epic #2210 사용자 결정): 모든 위반 = ERROR.
# 마이그 진행 중에는 CI fail 상태로 admin merge, 모든 sweep 완료 시 자동 PASS.

v=0
report=""

# 대상 파일 목록 (*_style.dart, 주석/문서 라인 제외는 각 룰에서)
# Portable (bash 3.2 / macOS) replacement for `mapfile`.
FILES=()
while IFS= read -r _line; do FILES+=("$_line"); done < <(find "$TARGET" -name '*_style.dart' 2>/dev/null | sort)

# ── RULE A1: forward Color(<core>.value)/.new(<core>.value)/Color(<core>.toARGB32())
#    직접 생성 — 모든 컴포넌트 *.dart (resolver + widget).
#    negative-prefix `(^|[^A-Za-z0-9_])` 로 역방향 `CoreColor(<x>.toARGB32())`
#    브리지와 `Foo.new(...)` 명시 생성자 호출을 제외한다.
while IFS= read -r h; do
  [ -z "$h" ] && continue
  report+="A1 ${h#packages/coui_flutter/lib/src/components/}  [forward Color(core.value) 직접생성 → scheme.resolve(x).toValue()]"$'\n'
  v=$((v+1))
done < <(grep -rnE "(^|[^A-Za-z0-9_])Color\([A-Za-z0-9_.!]+\.value\)|(^|[^A-Za-z0-9_])Color\([^)]*\.toARGB32\(\)\)|(^|[^A-Za-z0-9_])\.new\([A-Za-z0-9_.!]+\.value\)" "$TARGET" --include='*.dart' 2>/dev/null \
          | grep -vE ":[[:space:]]*//|^[^:]*:[0-9]+:[[:space:]]*///" )

# ── RULE A2: color receiver .toValue() standalone (resolve 없음) ──────
# color receiver: 토큰이 [Cc]olor 로 끝나거나 scaleAlpha(...) 체인.
while IFS= read -r h; do
  [ -z "$h" ] && continue
  # 같은 라인에 resolve( 있으면 정당 (scheme.resolve(x).toValue())
  grep -qE "resolve\(" <<<"$h" && continue
  report+="A2 ${h#packages/coui_flutter/lib/src/components/}  [color.toValue() standalone → scheme.resolve(x).toValue()]"$'\n'
  v=$((v+1))
done < <(grep -rnE "[Cc]olor[!?]?\.toValue\(\)|scaleAlpha\([^)]*\)\.toValue\(\)" "$TARGET" --include='*_style.dart' 2>/dev/null \
          | grep -vE ":[[:space:]]*//|^[^:]*:[0-9]+:[[:space:]]*///" )

# ── RULE B: public text-style helper ────────────────────────────────
# de-prefix 이후 canonical resolver 는 resolveXxx 단일 형태라, 단일 진입점
# resolveXxx 와 보조 resolveXxxItem 을 이름만으로 가려낼 접두 marker 가
# 사라졌다 (둘 다 같은 `resolve*` 형태). 따라서 "여분 public resolver" 판별은
# 폐기하고, 여기서는 per-slot/state text helper 가 public 인 것만 잡는다.
for f in "${FILES[@]+"${FILES[@]}"}"; do
  [ -z "$f" ] && continue
  # public mergeXxxCoreTextStyle / applyXxxTextStyle (top-level, _ 아님)
  pubhelper=$(grep -cE "^[A-Za-z_][A-Za-z0-9_<>, ?]*\b(merge[A-Z][A-Za-z0-9]*CoreTextStyle|apply[A-Z][A-Za-z0-9]*TextStyle)\(" "$f" 2>/dev/null || true)
  if [ "$pubhelper" -gt 0 ]; then
    report+="B  ${f#packages/coui_flutter/lib/src/components/}  [public textHelper ${pubhelper} → per-slot/state helper 는 file-private(_)]"$'\n'
    v=$((v+1))
  fi
done

# ── RULE C: Resolved 의 raw double *Radius / Core holder 필드 ─────────
while IFS= read -r h; do
  [ -z "$h" ] && continue
  report+="C  ${h#packages/coui_flutter/lib/src/components/}  [raw double *Radius / Core holder 필드 → BorderRadius / nested slot]"$'\n'
  v=$((v+1))
done < <(grep -rnE "final double [a-zA-Z0-9]*([Rr]adius|BorderRadius);|final Core[A-Za-z]+Theme [a-z]|final WidgetStateProperty<.*>\? [a-z]*[Rr]adius" "$TARGET" --include='*_style.dart' 2>/dev/null \
          | grep -vE ":[[:space:]]*//|^[^:]*:[0-9]+:[[:space:]]*///" \
          | grep -v 'guard-non-rect-radius' )

# ── RULE D: chaining (1:1:1:1 ③칸 누락 — Web chaining 미러) ──────────
CONTRACTS="packages/coui_core/lib/src/component/contracts"

# A default that depends on an input is a function named `default<Field>For`
# (`CoreChipStyle.defaultCustomSelectedForegroundColorFor(seed)` — the label
# a seed fill wears). It is the default of `<field>`, not of a field named
# `<field>For`, so the trailing `For` comes off before the override lookup;
# the resolver still has to chain `merged.<field>` in front of it.
field_of_flutter() { perl -pe 's/^default//; s/For$//; s/^(.)/lc($1)/e' <<<"$1"; }

while IFS= read -r hit; do
  [ -z "$hit" ] && continue
  file="${hit%%:*}"
  while IFS= read -r ident; do
    [ -z "$ident" ] && continue
    klass="$(sed 's/\.default.*//' <<<"$ident")"
    deflt="$(sed 's/.*\.//' <<<"$ident")"
    field="$(field_of_flutter "$deflt")"
    # `merged.` 는 merge chain 을 가진 resolver 의 표기다. Style 슬롯이 없는
    # 컴포넌트(위젯이 값을 직접 받는 쪽)는 체인을 만들 것이 없어 theme 의 Style 을
    # 바로 읽는다 — `coreTheme?.style?.${field}`. 룰 D 가 묻는 것은 "override 가
    # 반영되나" 이고 그 형태도 반영이므로, 표기 하나만 보면 통과해야 할 코드를
    # 잡는다. 실제로 그랬다: 값 하나를 `default<Field>` 짝으로 rename 한 것만으로
    # 동작이 1바이트도 안 바뀐 resolver 가 red 가 됐다.
    if grep -qE "merged\.${field}\b" "$file" \
      || grep -qE "style\?\.${field}\b" "$file" \
      || grep -qE "guard-nested-override:[[:space:]]*${field}\b" "$file"; then
      continue
    fi
    # The disabled search glyph takes an explicitly supplied nested icon
    # color before the disabled default, just as in the Web resolver.
    if [ "$klass" = CoreItemPickerStyle ] && [ "$field" = disabledSearchIconColor ] \
      && grep -vE '^[[:space:]]*//' "$file" | grep -qE 'merged\.searchIconStyle\?\.color[[:space:]]*!=[[:space:]]*null'; then
      continue
    fi
    cfile="$(grep -rlE "class[[:space:]]+${klass}\b" "$CONTRACTS" 2>/dev/null | head -1)"
    has_field="없음→contract 필드 승격 필요"
    [ -n "$cfile" ] && grep -qE "this\.${field}\b" "$cfile" && has_field="존재하나 merged.${field} 미참조"
    report+="D  ${file#packages/coui_flutter/lib/src/components/}  ${klass}.${deflt}  (override '${field}' ${has_field})"$'\n'
    v=$((v+1))
  done < <(grep -oE "Core[A-Za-z]+Style\.default[A-Za-z]+" <<<"$hit")
done < <(grep -rnE "Core[A-Za-z]+Style\.default[A-Za-z]+\b" "$TARGET" 2>/dev/null \
          | grep -E '_style\.dart:' \
          | grep -vE '\.defaults[A-Z]' \
          | grep -vE 'static const|^[^:]*:[0-9]+:[[:space:]]*//')

# ── RULE E: coverage (contract override 필드가 Flutter resolver 에 미반영) ──
WEB_BASE="packages/coui_web/lib/src/components"
while IFS= read -r fstyle; do
  klass="$(grep -oE "const (Core[A-Za-z]+Style)\(\)" "$fstyle" 2>/dev/null | head -1 | grep -oE "Core[A-Za-z]+Style")"
  [ -z "$klass" ] && continue
  cfile="$(grep -rlE "class[[:space:]]+${klass}\b" "$CONTRACTS" 2>/dev/null | head -1)"
  [ -z "$cfile" ] && continue
  comp="$(basename "$(dirname "$fstyle")")"
  wstyle="$(find "$WEB_BASE" -path "*/$comp/${comp}_style.dart" 2>/dev/null | head -1)"
  # Deprecated 생성자 파라미터 이름 집합 — `@Deprecated(...)` 뒤 가장
  # 가까운 `this.<field>` 를 잡는다(문자열 인자 안 괄호도 안전 —
  # non-greedy `.*?` 가 `this.` 앞에서만 멈춘다).
  deprecated_fields="$(perl -0777 -ne '
    while (/\@Deprecated\(.*?\)\s*\n\s*this\.([a-zA-Z0-9_]+)/gs) {
      print "$1\n";
    }
  ' "$cfile" 2>/dev/null)"
  while IFS= read -r field; do
    [ -z "$field" ] && continue
    case "$field" in on[A-Z]*|child|children|key|controller|focusNode) continue;; esac
    grep -qxF "$field" <<<"$deprecated_fields" && continue
    grep -qE "[a-zA-Z0-9]\.${field}\b" "$fstyle" && continue
    wlbl="(Web도 미반영)"
    if [ -n "$wstyle" ] && grep -qE "\.${field}\b|merged\.${field}\b|style\.${field}\b" "$wstyle" 2>/dev/null; then
      wlbl="★복구대상(Web 반영O)"
    fi
    report+="E  $comp  '$field'  $wlbl"$'\n'
    v=$((v+1))
  done < <(grep -oE "this\.[a-z][A-Za-z0-9]*" "$cfile" | sed 's/this\.//' | sort -u)
done < <(find "$TARGET" -name '*_style.dart' | sort)

if [ "$v" -eq 0 ]; then
  echo "✅ flutter resolver: 통일 위반 없음 in $TARGET"
  exit 0
fi

# Ratchet (#6038): the violations standing when this gate first ran to
# completion are listed beside this script — promoting a default to a
# Style field and wiring a contract field are API work each, not a sweep.
# Net-new lines fail; a listed line that is gone fails too, so the list
# only shrinks. Only the whole-tree run compares — a narrowed TARGET
# reports as before.
BASELINE="$(dirname "$0")/flutter_resolver_baseline.txt"
if [ "$TARGET" = "packages/coui_flutter/lib/src/components" ] && [ -f "$BASELINE" ]; then
  current=$(printf '%s' "$report" | sed '/^$/d' | sort -u)
  known=$(grep -vE '^\s*(#|$)' "$BASELINE" | sort -u)
  added=$(comm -23 <(printf '%s\n' "$current") <(printf '%s\n' "$known"))
  gone=$(comm -13 <(printf '%s\n' "$current") <(printf '%s\n' "$known"))
  if [ -z "$added" ] && [ -z "$gone" ]; then
    echo "✅ flutter resolver: $v 개 위반 — 전부 baseline ($(printf '%s\n' "$known" | grep -c .)), net-new 없음."
    exit 0
  fi
  if [ -n "$added" ]; then
    echo "❌ flutter resolver: baseline 에 없는 새 위반:"
    printf '%s\n' "$added" | sed 's/^/   /'
  fi
  if [ -n "$gone" ]; then
    echo "❌ flutter resolver: 고쳐진 항목이 baseline 에 남아 있다 — 지워라:"
    printf '%s\n' "$gone" | sed 's/^/   /'
  fi
  echo "   baseline: $BASELINE"
  exit 1
fi
echo "❌ flutter resolver: $v 개 위반 (RULE A color-path / B single-entry / C paint-ready / D chaining / E coverage):"
echo ""
printf '%s' "$report" | head -40
[ "$v" -gt 40 ] && echo "    ... ($((v - 40)) more)"
echo ""
echo "정정: CoreColor→Color = scheme.resolve(x).toValue() / per-slot resolver·textHelper file-private /"
echo "      Resolved = paint-ready / defaultY emit 은 merged.y 통해 / contract override 필드는 모두 반영."
exit 1
