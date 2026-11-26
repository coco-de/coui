#!/usr/bin/env bash
# check_web_resolver.sh — Epic #1603 / #2210 Web resolver 통일 게이트 (단일 파일).
#
# `check_flutter_resolver.sh` 의 Web 거울상. 양쪽 RULE 라벨이 같은 원칙을
# 가리키도록 정렬:
#   RULE A — (제거됨) 구 color-path. canonical 전환으로 폐기:
#            Web EMIT 은 theme-free — token 색은 `var(--coui-X)` CSS 변수로
#            브라우저가 런타임 해석하므로 `value.toValue()` standalone 이
#            정공법이고, Web `scheme.resolve` 는 identity no-op 이라 금지다
#            (resolver-pattern.md "Web EMIT"). 옛 RULE A 는 정확히 반대를
#            요구해 canonical 코드를 전부 오탐했다.
#   RULE B — single-entry
#   RULE C — paint-ready
#   RULE D — chaining (1:1:1:1 ③칸)
#   RULE E — coverage (override 필드 반영)
#   RULE F — single-inline-signature (Web 전용, Flutter 는 paint model 차이로 무의미)
#
# RULE B — single-entry (Flutter B 미러):
#   `*_style.dart` 의 top-level public `resolve[A-Z]*` 함수는
#   `resolve<Comp>` 하나만. per-slot/state public resolver +
#   public `merge*CoreTextStyle`/`apply*TextStyle` helper 는 file-private(`_`)
#   여야. (한 파일에 colocated Co widget 이 여럿이면 resolve* 둘 이상 허용.)
#
# RULE C — paint-ready (옵션 B 필드 카테고리, RFC §10):
#   `ResolvedXxx` final 필드는 다음 3 카테고리만 허용:
#     (1) chrome 슬롯       — WebElementChrome[?] / List<WebElementChrome[?]>
#     (2) nested Style 슬롯  — Core[A-Za-z]+Style[?] (자식 forward)
#     (3) sub-Resolved 슬롯  — Resolved[A-Za-z]+[?] (per-item chrome)
#   그 외 위반:
#     - scalar (`String` / `double` / `int` / `bool` / `Color` / `Duration`)
#       → paint-ready 값은 chrome 슬롯의 inlineStyles 안.
#     - paint-ready Flutter 타입 (`BorderRadius` / `EdgeInsets`)
#       → Flutter 전용. Web 은 inline CSS 문자열.
#     - 도메인 타입 단독 노출 (`CoreBorderRadius` / `CoreEdgeInsets`)
#       → chrome 슬롯 안 .toValue() 또는 nested Style 슬롯 안.
#
# RULE D — chaining (1:1:1:1 ③칸 누락):
#   Web resolver(`*_style.dart`) 가 `CoreXxxStyle.defaultYyy` 를 chrome emit
#   (.tailwindColor/.toValue/.tailwindSpace/.tailwindRadius/.tailwindSize/...) 으로
#   소비하면서, 대응 override 필드 `yyy` 가 contract 에 존재(`this.yyy`)하는데
#   resolver 파일에 `merged.yyy` 참조가 전혀 없음 → 1:1:1:1 ③칸 누락.
#   추가 차단: reach-in / legacy — corner/edge `.topLeft/.top` reach-in,
#             `.tailwindRadius` legacy uniform-corner extractor.
#
# RULE E — coverage:
#   contract `CoreXxxStyle` 의 override 필드 yyy 가 Web resolver 에 `merged.yyy`
#   (또는 어떤 객체.yyy) 로 전혀 반영되지 않음 → 삭제/누락. Flutter 반영 여부
#   라벨링.
#   예외: contract 생성자에서 `@Deprecated(...)` 가 붙은 필드는 skip한다 —
#   Flutter RULE E 미러 (`check_flutter_resolver.sh`) 와 동일 근거·동일
#   추출 로직. `process/deprecation.md` 표준 폐기 경로로 이미 "더 이상
#   적용되지 않음"이 선언된 필드라 미반영이 결함이 아니다. 플랫폼별 시차
#   반영(한쪽 선행)을 감안해 상대 플랫폼 반영 여부와 무관하게 적용된다.
#
# RULE F — single-inline-signature (Web 전용, paint model 차이로 Flutter 무의미):
#   chrome (radius/padding/gap/size) 는 무조건 `(merged.X ?? default).toValue()`
#   또는 `'${... / kRemDivisor}rem'` inline. Tailwind class 금지 (rounded-*,
#   p-*, py-*, px-*, .tailwindRadius, .tailwindClasses), class-drop 분기 `? ''`
#   금지. 색/typography 만 토큰 class 허용 (default class + override inline,
#   card 모범).
#
# Strict mode (Epic #2210): 모든 위반 = ERROR. 마이그 진행 중에는 CI fail 상태로
# admin merge, 모든 sweep 완료 시 자동 PASS. Backlog 가시화 + 점진 압박.
#
# 사용: ./scripts/check_web_resolver.sh [dir-or-file]   (기본: 전체)
# exit 1 if any violation.

set -uo pipefail
TARGET="${1:-packages/coui_web/lib/src/components}"
CONTRACTS="packages/coui_core/lib/src/component/contracts"
FLU_BASE="packages/coui_flutter/lib/src/components"

v=0
report=""

# Portable (bash 3.2 / macOS) replacement for `mapfile` — read NUL-free lines.
FILES=()
while IFS= read -r _line; do FILES+=("$_line"); done < <(find "$TARGET" -name '*_style.dart' 2>/dev/null | sort)

# A default that depends on an input is a function named `default<Field>For`
# (`CoreChipStyle.defaultCustomSelectedForegroundColorFor(seed)` — the label
# a seed fill wears). It is the default of `<field>`, not of a field named
# `<field>For`, so the trailing `For` comes off before the override lookup;
# the resolver still has to chain `merged.<field>` in front of it.
field_of_web() { perl -pe 's/^default//; s/For$//; s/^(.)/lc($1)/e' <<<"$1"; }

# ── RULE A: 제거됨 (canonical Web EMIT = theme-free value.toValue();
#    Web scheme.resolve 는 no-op 이라 금지 — 헤더 참조) ────────────────

# ── RULE B: public text-style helper ────────────────────────────────
# de-prefix 이후 canonical resolver 는 resolveXxx 단일 형태라, 단일 진입점/
# 보조 resolver 를 이름만으로 가려낼 접두 marker 가 사라졌다 → "여분 public
# resolver" 판별은 폐기하고 public text helper 만 잡는다.
for f in "${FILES[@]+"${FILES[@]}"}"; do
  [ -z "$f" ] && continue
  pubhelper=$(grep -cE "^[A-Za-z_][A-Za-z0-9_<>, ?]*\b(merge[A-Z][A-Za-z0-9]*CoreTextStyle|apply[A-Z][A-Za-z0-9]*TextStyle)\(" "$f" 2>/dev/null || true)
  if [ "$pubhelper" -gt 0 ]; then
    report+="B  ${f#packages/coui_web/lib/src/components/}  [public textHelper ${pubhelper}]"$'\n'
    v=$((v+1))
  fi
done

# ── RULE C: Resolved* final 필드 옵션 B 카테고리 ──────────────────
for f in "${FILES[@]+"${FILES[@]}"}"; do
  [ -z "$f" ] && continue
  hits=$(perl -e '
    use strict; use warnings;
    my $file = $ARGV[0];
    open my $fh, "<", $file or exit 0;
    my $src = do { local $/; <$fh> };
    close $fh;
    while ($src =~ /^class (Resolved[A-Za-z]+)(\s+(?:implements|extends)[^{]*)?\s*\{(.*?)^\}/sgm) {
      my ($cls, $impl, $body) = ($1, $2 // "", $3);
      # Category checks below run more regexes. Save this source offset before
      # those matches replace the Perl capture offsets.
      my $body_start_line = 1 + (substr($src, 0, $-[3]) =~ tr/\n//);
      # web-specifics.md 5종 Resolved 카테고리 C/D/E — Rules(Scoped CSS)/
      # Runtime(client runtime config)/Timing(behavior timing) suffix 는
      # WebResolvedChrome 를 implements 하지 않는 non-chrome holder 로,
      # scalar config 필드(String css / Duration / double / int)를 명시 허용한다.
      next if $cls =~ /(Rules|Runtime|Timing)$/ && $impl !~ /WebResolvedChrome/;
      # 순수 query/value bundle — DOM chrome 을 전혀 안 그리는 Resolved
      # (예: ResolvedBreakpoint — Breakpoint 는 아무것도 렌더 안 함): WebResolvedChrome
      # 를 implements 하지도, WebElementChrome 필드를 하나도 갖지도 않는다.
      # Resolved-layer 비대칭이 정당하므로(core/layer-mapping.md) scalar/enum
      # query 필드를 허용한다.
      next if $impl !~ /WebResolvedChrome/ && $body !~ /\bWebElementChrome\b/;
      my $line_in_body = 0;
      for my $line (split /\n/, $body) {
        $line_in_body++;
        next if $line =~ m{^\s*///};
        next if $line =~ m{^\s*//};
        next if $line =~ m{^\s*static\s};
        if ($line =~ m{^\s*final\s+([A-Za-z_][A-Za-z0-9_<>?, ]*?)\s+([a-z_][a-zA-Z0-9_]*)\s*;}) {
          my ($type, $name) = ($1, $2);
          $type =~ s/\s+/ /g;
          $type =~ s/^\s+|\s+$//g;
          next if $type =~ /^WebElementChrome\??$/;
          next if $type =~ /^List<WebElementChrome\??>$/;
          next if $type =~ /^Core[A-Za-z]+Style\??$/;
          next if $type =~ /^List<Core[A-Za-z]+Style\??>$/;
          next if $type =~ /^Resolved[A-Za-z]+\??$/;
          next if $type =~ /^List<Resolved[A-Za-z]+\??>$/;
          my $abs_line = $body_start_line + $line_in_body - 1;
          print "$file:$abs_line  $cls.$name [$type]\n";
        }
      }
    }
  ' "$f")
  [ -z "$hits" ] && continue
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    report+="C  ${hit#packages/coui_web/lib/src/components/}"$'\n'
    v=$((v+1))
  done <<< "$hits"
done

# ── RULE D: 1:1:1:1 chaining ────────────────────────────────────────
while IFS= read -r hit; do
  [ -z "$hit" ] && continue
  file="${hit%%:*}"
  lineno="$(sed 's/^[^:]*:\([0-9]*\):.*/\1/' <<<"$hit")"
  while IFS= read -r ident; do
    [ -z "$ident" ] && continue
    klass="$(sed 's/\.default.*//' <<<"$ident")"
    deflt="$(sed 's/.*\.//' <<<"$ident")"
    field="$(field_of_web "$deflt")"
    # Flutter 가드(check_flutter_resolver.sh:130) 미러 — override 가 nested-slot
    # sub-field(`merged.iconStyle?.color`) / base-then-merge
    # (`CoreIconStyle(color: default).merge(merged.slot)`) / resolver-arg
    # (semantic prop `field ?? default`) 로 들어와 리터럴 `merged.field` 매칭은
    # 안 되지만 실제로 도달하는 경우, 파일에 `// guard-nested-override: <field>`
    # 를 달면 skip (달기 전 override 도달 실확인 필수 — Flutter 룰과 동일).
    # Style 슬롯이 없는 컴포넌트는 merge chain 이 없고 theme 의 Style 을 바로
    # 읽는다 — Flutter 쪽 룰 D 와 같은 이유로 그 표기도 반영으로 센다.
    if grep -qE "merged\.${field}\b" "$file" \
      || grep -qE "style\?\.${field}\b" "$file" \
      || grep -qE "guard-nested-override:[[:space:]]*${field}\b" "$file"; then
      continue
    fi
    # The disabled search glyph is a nested Icon slot: an explicitly supplied
    # searchIconStyle.color takes precedence over the disabled default. Check
    # the actual condition rather than accepting the default alone.
    if [ "$klass" = CoreItemPickerStyle ] && [ "$field" = disabledSearchIconColor ] \
      && grep -vE '^[[:space:]]*//' "$file" | grep -qE 'merged\.searchIconStyle\?\.color[[:space:]]*!=[[:space:]]*null'; then
      continue
    fi
    has_field="없음→contract 필드 승격 필요"
    cfile="$(grep -rlE "class[[:space:]]+${klass}\b" "$CONTRACTS" 2>/dev/null | head -1)"
    [ -n "$cfile" ] && grep -qE "this\.${field}\b" "$cfile" && has_field="존재하나 merged.${field} 미참조"
    report+="D  ${file#packages/coui_web/lib/src/components/}:${lineno}  ${klass}.${deflt}  (override '${field}' ${has_field})"$'\n'
    v=$((v+1))
  done < <(grep -oE "Core[A-Za-z]+Style\.default[A-Za-z]+" <<<"$hit")
done < <(grep -rnE "Core[A-Za-z]+Style\.default[A-Za-z]+\b" "$TARGET" 2>/dev/null \
          | grep -E '_style\.dart:' \
          | grep -vE '\.defaults[A-Z]' \
          | grep -vE 'static const|^[^:]*:[0-9]+:[[:space:]]*//')

# RULE D 보조: reach-in / legacy — single-corner/edge EMIT 만 잡는다.
# web-specifics.md 문서화된 검출(`.borderRadius.tailwindRadius` /
# `.xxxPadding.(top|left).tailwindSpace`)에 맞춰, corner/edge 뒤에 emit
# (`.tailwind*`/`.toValue`/`.toInlineCss`)이 바로 붙은 single-corner/edge 추출만
# 위반이다. override 반영된 merged 값의 corner 를 raw double 로 읽어(예:
# `mergedRadius.topLeft` → `CoreBorderRadius.only(...)` 재구성 · Runtime px 설정 ·
# SVG rect uniform radius) 완전한 4-side 를 처리하는 건 정당하다(오탐 아님).
while IFS= read -r rhit; do
  [ -z "$rhit" ] && continue
  report+="D  ${rhit#packages/coui_web/lib/src/components/}  (reach-in/legacy — single-corner/edge emit → core_to_css 4-side 어댑터로)"$'\n'
  v=$((v+1))
done < <(grep -rnE "\.(topLeft|topRight|bottomLeft|bottomRight)\.(tailwind[A-Za-z]+|toValue|toInlineCss)|[A-Za-z]*(Padding|Margin|Inset|Insets)\.(top|left|right|bottom)\.tailwind[A-Za-z]+|[Bb]orderRadius\.tailwindRadius\b" "$TARGET" 2>/dev/null \
          | grep -E '_style\.dart:' \
          | grep -vE 'static const|^[^:]*:[0-9]+:[[:space:]]*//' \
          | sed 's/\(:[0-9]*\):.*/\1/' | sort -u)

# ── RULE E: coverage (contract override 미반영) ──────────────────────
while IFS= read -r wstyle; do
  comp="$(basename "$(dirname "$wstyle")")"
  # A resolver may construct a child style before its own merge chain.
  # Prefer the component's own named contract when that type occurs in the
  # resolver and exists in Core; retain the old fallback for aliases.
  own_klass="Core$(perl -pe 's/(?:^|_)([a-z])/uc($1)/ge' <<<"$comp")Style"
  own_file=""
  if grep -qE "\b${own_klass}\b" "$wstyle"; then
    own_file="$(grep -rlE "class[[:space:]]+${own_klass}\b" "$CONTRACTS" 2>/dev/null | head -1)"
  fi
  if [ -n "$own_file" ]; then
    klass="$own_klass"
    cfile="$own_file"
  else
    klass="$(grep -oE "const (Core[A-Za-z]+Style)\(\)" "$wstyle" 2>/dev/null | head -1 | grep -oE "Core[A-Za-z]+Style")"
    [ -z "$klass" ] && continue
    cfile="$(grep -rlE "class[[:space:]]+${klass}\b" "$CONTRACTS" 2>/dev/null | head -1)"
    [ -z "$cfile" ] && continue
  fi
  fstyle="$(find "$FLU_BASE" -path "*/$comp/${comp}_style.dart" 2>/dev/null | head -1)"
  # Deprecated 생성자 파라미터 이름 집합 — Flutter RULE E 미러와 동일 추출.
  deprecated_fields="$(perl -0777 -ne '
    while (/\@Deprecated\(.*?\)\s*\n\s*this\.([a-zA-Z0-9_]+)/gs) {
      print "$1\n";
    }
  ' "$cfile" 2>/dev/null)"
  while IFS= read -r field; do
    [ -z "$field" ] && continue
    case "$field" in on[A-Z]*|child|children|key|controller|focusNode) continue;; esac
    grep -qxF "$field" <<<"$deprecated_fields" && continue
    grep -qE "[a-zA-Z0-9]\.${field}\b" "$wstyle" && continue
    flu="(Flutter도 미반영)"
    if [ -n "$fstyle" ] && grep -qE "\.${field}\b|merged\.${field}\b|style\.${field}\b" "$fstyle" 2>/dev/null; then
      flu="★복구대상(Flutter 반영O)"
    fi
    report+="E  $comp  '$field'  $flu"$'\n'
    v=$((v+1))
    # MAIN `CoreXxxStyle` 의 생성자 파라미터만. 파일 전체를 긁으면 같은 파일에 사는
    # 헬퍼 클래스의 `required` 필드까지 override 슬롯으로 센다 — per-state 색 삼중항의
    # `foregroundColor` 가 그렇게 잡혀서, resolver 가 그 색을 label typography 로
    # 반영하고 있고 주석에 그렇게 적혀 있는데도 "미반영" 으로 보고됐다. 룰 문구가
    # 말하는 대상은 MAIN 클래스의 override 필드이고, 범위가 그 문구를 따라가야 한다.
  done < <(G_KLASS="$klass" perl -0777 -ne '
    my $k = $ENV{G_KLASS};
    if (/^\s*class\s+\Q$k\E\b.*?\n\}/ms) {
      my $body = $&;
      while ($body =~ /this\.([a-z][A-Za-z0-9]*)/g) { print "$1\n"; }
    }
  ' "$cfile" 2>/dev/null | sort -u)
done < <(find "$TARGET" -name '*_style.dart' | sort)

# ── RULE F: 단일 inline 시그니처 (Web 전용) ──────────────────────────
PSEUDO='(hover|focus|focus-visible|focus-within|active|disabled|placeholder|aria-[a-z]+|group-[a-z]+|peer-[a-z]+|data-\[)'
while IFS= read -r h; do
  [ -z "$h" ] && continue
  report+="F  ${h#packages/coui_web/lib/src/components/}  [radius/padding→class] (merged.X ?? default).toValue() inline 으로"$'\n'
  v=$((v+1))
done < <(grep -rnE "'(rounded-|p-|py-|px-)|\.tailwindRadius\b|\.tailwindClasses\(" "$TARGET" --include='*_style.dart' 2>/dev/null \
          | grep -vE "${PSEUDO}:" \
          | grep -vE "static const|^[^:]*:[0-9]+:[[:space:]]*//" \
          | sed 's/\(:[0-9]*\):.*/\1/' | sort -u)
class_drop_hits=$(python3 "$(dirname "$0")/web_class_drop.py" "${FILES[@]+"${FILES[@]}"}") || {
  echo '❌ web resolver: RULE F source scan failed; no pass result.' >&2
  exit 1
}
while IFS= read -r h; do
  [ -z "$h" ] && continue
  report+="F  ${h#packages/coui_web/lib/src/components/}  [class-drop ? ''] inline 으로"$'\n'
  v=$((v+1))
done <<< "$class_drop_hits"

# ── 보고 ──
if [ "$v" -eq 0 ]; then
  echo "✅ web resolver: 통일 위반 없음 in $TARGET"
  exit 0
fi
# Ratchet (#6038): the violations standing when this gate first ran to
# completion are listed beside this script, line numbers dropped so a
# shifted line is not a new violation. Promoting a default to a Style
# field and wiring a contract field are API work each, not a sweep. Net-new
# lines fail; a listed line that is gone fails too, so the list only
# shrinks. Only the whole-tree run compares.
BASELINE="$(dirname "$0")/web_resolver_baseline.txt"
if [ "$TARGET" = "packages/coui_web/lib/src/components" ] && [ -f "$BASELINE" ]; then
  current=$(printf '%s' "$report" | sed '/^$/d' | sed -E 's/\.dart:[0-9]+  /.dart  /' | sort -u)
  known=$(grep -vE '^\s*(#|$)' "$BASELINE" | sort -u)
  added=$(comm -23 <(printf '%s\n' "$current") <(printf '%s\n' "$known"))
  gone=$(comm -13 <(printf '%s\n' "$current") <(printf '%s\n' "$known"))
  if [ -z "$added" ] && [ -z "$gone" ]; then
    echo "✅ web resolver: $v 개 위반 — 전부 baseline ($(printf '%s\n' "$known" | grep -c .)), net-new 없음."
    exit 0
  fi
  if [ -n "$added" ]; then
    echo "❌ web resolver: baseline 에 없는 새 위반:"
    printf '%s\n' "$added" | sed 's/^/   /'
  fi
  if [ -n "$gone" ]; then
    echo "❌ web resolver: 고쳐진 항목이 baseline 에 남아 있다 — 지워라:"
    printf '%s\n' "$gone" | sed 's/^/   /'
  fi
  echo "   baseline: $BASELINE"
  exit 1
fi
echo "❌ web resolver: $v 개 위반 (RULE B single-entry / C paint-ready / D chaining / E coverage / F single-inline-signature):"
echo ""
printf '%s' "$report" | head -40
[ "$v" -gt 40 ] && echo "    ... ($((v - 40)) more)"
echo ""
echo "정정: B per-slot resolver·textHelper file-private /"
echo "      C chrome+nested-Style+sub-Resolved 만 / D merged.<field> 통해 체인 / E contract override 모두 반영 /"
echo "      F chrome 은 inline .toValue()/rem."
exit 1
