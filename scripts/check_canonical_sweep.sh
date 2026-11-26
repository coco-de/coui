#!/usr/bin/env bash
# check_canonical_sweep.sh — 컴포넌트 단위 canonical sweep 의 구조 게이트.
#
# Usage: ./scripts/check_canonical_sweep.sh <component> [<component> ...]
#   e.g.  ./scripts/check_canonical_sweep.sh badge
#         ./scripts/check_canonical_sweep.sh chip avatar
#
# Exit 0 = 모든 체크 PASS. Exit 1 = 하나 이상 위반 (파일:라인 + 메시지 출력).
#
# ─────────────────────────────────────────────────────────────────────────
# WHY (badge 파일럿 동기):
#   badge 통일화에서 위임 agent 가 `dart analyze` + 테스트를 통과시키고도
#   **구조적으로 틀린** 결과를 냈다 (Theme 에 variant/size 평면 필드 잔존,
#   resolver 가 variantStyles 를 안 엮음, Web 에 scheme.resolve no-op, 평면
#   chrome typography 하드코딩). analyze/test 는 이런 "컴파일은 되지만 1:1:1:1:1:1
#   / Style-contract 위반" 을 못 잡는다. 이 게이트는 그 빈틈을 grep 으로 막는다.
#
# 기존 게이트와의 관계 (중복 아닌 보완):
#   - verify_contracts.sh    : ==/hashCode/copyWith/merge 필드 완전성, mergedStyle,
#                              build-time merge chain, CoreColor literal 등 (프로젝트 전역).
#   - check_web_resolver.sh  : Web resolver RULE A~F (전역 Web sweep backlog).
#   - check_design_tokens.sh : 하드코딩 토큰 리터럴 (Duration/arbitrary class/inline px).
#   - check_canonical_sweep.sh (this): **컴포넌트 1개를 받아** Core+Flutter+Web 을 가로질러
#                              Theme 구조 / variantStyles 배선 / 타이포·색 하드코딩 /
#                              Resolved 네이밍을 한 번에 본다. 통일화 직후
#                              "이 컴포넌트 canonical 인가?" 단일 판정용.
#
# 검사 항목 (룰 출처):
#   [1] Theme 구조 — Core{X}Theme 은 {style, variantStyles} 슬롯만.
#       variant / size / chrome 평면 필드(final CoreColor? color 등) 잔존 = 위반.
#       (.claude/rules/core/style-contract.md "CoreXxxTheme — style + variantStyles 슬롯만")
#   [2] resolver variantStyles 배선 — variant enum 있는 컴포넌트면 Flutter+Web
#       {x}_style.dart 의 resolveStyleChain(...) 안에 variantStyles?[variant] 존재.
#       (.claude/rules/resolver/resolver-pattern.md merge chain 우선순위)
#   [3] 하드코딩 금지 — platform {x}_style.dart 가 theme.typography. /
#       theme.coreTypography.resolve / cs.(onSurface|surface|primary|outline) 직접참조,
#       또는 Web 에서 scheme.resolve( (no-op) = 위반.
#       (.claude/rules/web/web-specifics.md "Web EMIT — scheme.resolve 는 no-op → 금지";
#        .claude/rules/core/layer-mapping.md "모든 디자인 값은 Core Style 단일 출처")
#   [4] Resolved 네이밍 — ResolvedCo{X} 필드에 override[A-Z] prefix 또는
#       Hungarian (xColorToken / xCoreColor / xColorResolved) = 위반.
#       (.claude/rules/code-style/naming.md "resolved 필드 override* 금지 / no-Hungarian")
#   [5] manual typography role class — Web {x}_style.dart 가 typography role
#       class 를 손으로 조립(`text-${...token!.name}` / `.token!.name` 보간) = 위반.
#       canonical 경로는 `emitTypography(value, fallbackDefault)` 단일 진입점이
#       role class + overlay inline 을 함께 emit 한다. 손조립은 그 경로를 우회
#       (role+overlay 케이스에서 overlay inline 을 따로 박게 됨). 주석 제외.
#       (.claude/rules/core/layer-mapping.md "모든 디자인 값은 Core Style 단일 출처";
#        .claude/rules/web/web-specifics.md EMIT 패밀리 단일 진입점)
#   [6] scoped dart analyze + check_design_tokens (있으면) 묶어 실행.
#
# variant enum 없는 컴포넌트(chip/avatar 등)는 항목 [2] skip.
#
# NOTE — check_web_resolver.sh RULE A 와의 의도적 차이:
#   RULE A 는 Web color path 로 `scheme.resolve(x).toValue()` 를 요구하지만,
#   그건 더 오래된 컨벤션이다. canonical baseline (badge) 과 web-specifics.md L240
#   ("Web EMIT — scheme.resolve 는 no-op → 금지") 은 Web 에서 scheme.resolve 제거를
#   요구한다. 이 게이트는 후자(최신 canonical)를 따른다.

set -uo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <component> [<component> ...]" >&2
  echo "  e.g. $0 badge" >&2
  exit 2
fi

CORE_CONTRACTS="packages/coui_core/lib/src/component/contracts"
FLU_COMPONENTS="packages/coui_flutter/lib/src/components"
WEB_COMPONENTS="packages/coui_web/lib/src/components"

# Common-token color tokens that platform style files must reach via
# CoreXxxStyle.defaultYyy, never `cs.<token>` directly.
CS_DIRECT='(cs|colorScheme|scheme).(onSurface|surface|surfaceDim|surfaceBright|surfaceVariant|surfaceTint|surfaceContainer|surfaceContainerLowest|surfaceContainerLow|surfaceContainerHigh|surfaceContainerHighest|onSurfaceVariant|primary|onPrimary|primaryContainer|onPrimaryContainer|inversePrimary|secondary|onSecondary|secondaryContainer|onSecondaryContainer|tertiary|onTertiary|tertiaryContainer|onTertiaryContainer|error|onError|errorContainer|onErrorContainer|outline|outlineVariant|shadow|scrim|inverseSurface|onInverseSurface|background|onBackground)\b'

TOTAL_ERRORS=0

# ── helper: emit a violation line ──
fail() { # <msg>
  echo "    ✗ $1"
}

# Resolve the contract dir holding <component>'s Core contract files.
#
# Most components live in their own dir (`contracts/<comp>/`). Sub-components
# of a family (e.g. `mockup_code` under `contracts/mockup/`, sharing the
# `<comp>_` filename prefix) have no dir of their own — fall back to the dir
# that actually CONTAINS `<comp>_style.dart`. The Theme / variant lookups and
# check [1] already key on the `<comp>_` filename prefix, so a family dir
# resolves the right per-component files; check [6]'s scoped analyze widens
# to the family dir, which must be clean regardless.
core_dir_of() { # <component>
  local d="$CORE_CONTRACTS/$1"
  if [ -d "$d" ]; then
    echo "$d"
    return
  fi
  local style
  style="$(find "$CORE_CONTRACTS" -name "${1}_style.dart" 2>/dev/null | head -1)"
  [ -n "$style" ] && dirname "$style"
}

# Find platform style file under coui_{flutter,web} components for <component>.
platform_style_of() { # <component> <flutter|web>
  local comp="$1" plat="$2" base
  case "$plat" in
    flutter) base="$FLU_COMPONENTS" ;;
    web)     base="$WEB_COMPONENTS" ;;
    *)       return ;;
  esac
  find "$base" -path "*/${comp}/${comp}_style.dart" 2>/dev/null | head -1
}

# Find platform widget file(s) (co_<component>.dart) under coui_{flutter,web}.
# A component may have several co_*.dart (e.g. co_xxx.dart + co_xxx_item.dart).
platform_widget_of() { # <component> <flutter|web>
  local comp="$1" plat="$2" base
  case "$plat" in
    flutter) base="$FLU_COMPONENTS" ;;
    web)     base="$WEB_COMPONENTS" ;;
    *)       return ;;
  esac
  find "$base" -path "*/${comp}/co_*.dart" ! -path '*dart_tool*' 2>/dev/null \
    | xargs grep -L '@Deprecated' 2>/dev/null
}

# ── per-component check ──
check_component() {
  local comp="$1"
  local comp_errors=0
  echo "=== canonical sweep: $comp ==="

  local core_dir
  core_dir="$(core_dir_of "$comp")"
  if [ -z "$core_dir" ]; then
    fail "core contract dir not found: $CORE_CONTRACTS/$comp"
    TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    return
  fi

  local flu_style web_style
  flu_style="$(platform_style_of "$comp" flutter)"
  web_style="$(platform_style_of "$comp" web)"

  # Does this component have a variant enum file? (drives check 2)
  local variant_file variant_enum=""
  variant_file="$(find "$core_dir" -name "${comp}_variant.dart" 2>/dev/null | head -1)"
  if [ -n "$variant_file" ]; then
    variant_enum="$(grep -oE 'enum Core[A-Za-z]+Variant' "$variant_file" 2>/dev/null | head -1 | sed 's/^enum //')"
  fi

  # ─────────────────────────────────────────────────────────────────────
  # [1] Theme 구조 — {style, variantStyles} 슬롯만.
  # ─────────────────────────────────────────────────────────────────────
  echo "  [1] Theme structure ({style, variantStyles} only)"
  local theme_file
  theme_file="$(find "$core_dir" -name "${comp}_theme.dart" 2>/dev/null | head -1)"
  if [ -z "$theme_file" ]; then
    echo "      (no ${comp}_theme.dart — skip)"
  else
    # Extract every `final` instance field name in the Core*Theme class;
    # anything other than `style` / `variantStyles` is a chrome/semantic
    # flat-field violation.
    local bad_fields
    bad_fields="$(perl -0777 -ne '
      while (/^class (Core[A-Za-z]+Theme)\b[^{]*\{(.*?)^\}/sgm) {
        my $body = $2;
        for my $line (split /\n/, $body) {
          next if $line =~ /^\s*static\s/;
          # capture: "  final <Type> <name>;"  and the source line number is
          # reconstructed by the caller via grep -n below.
          if ($line =~ /^\s*final\s+[^;]+?\s+([a-z_][a-zA-Z0-9_]*)\s*;/) {
            my $f = $1;
            next if $f eq "style" or $f eq "variantStyles";
            print "$f\n";
          }
        }
      }
    ' "$theme_file")"
    if [ -n "$bad_fields" ]; then
      while IFS= read -r f; do
        [ -z "$f" ] && continue
        local ln
        ln="$(grep -nE "final[^;]+\b${f}\s*;" "$theme_file" | head -1 | cut -d: -f1)"
        fail "$theme_file:${ln:-?}  Theme carries flat field '$f' — chrome/semantic must move into Style slot ({style, variantStyles} only)"
        comp_errors=$((comp_errors + 1))
      done <<< "$bad_fields"
    else
      echo "      PASS"
    fi
  fi

  # ─────────────────────────────────────────────────────────────────────
  # [2] resolver variantStyles 배선 (variant 있는 컴포넌트만).
  # ─────────────────────────────────────────────────────────────────────
  echo "  [2] resolver variantStyles wiring"
  if [ -z "$variant_enum" ]; then
    echo "      (no variant enum — skip)"
  else
    local plat f
    for plat in flutter web; do
      [ "$plat" = flutter ] && f="$flu_style" || f="$web_style"
      if [ -z "$f" ]; then
        echo "      ($plat: no ${comp}_style.dart — skip)"
        continue
      fi
      if ! grep -qE 'resolveStyleChain\(' "$f"; then
        fail "$f  ($plat) has no resolveStyleChain(...) — cannot wire variantStyles"
        comp_errors=$((comp_errors + 1))
      elif ! grep -qE 'variantStyles\?\[' "$f"; then
        fail "$f  ($plat) resolveStyleChain missing variantStyles?[variant] — variant override silently dropped"
        comp_errors=$((comp_errors + 1))
      else
        echo "      $plat: PASS"
      fi
    done
  fi

  # ─────────────────────────────────────────────────────────────────────
  # [3] 하드코딩 금지 (platform {x}_style.dart).
  # ─────────────────────────────────────────────────────────────────────
  echo "  [3] no hardcoded typography/color in platform style"
  local plat f hit
  local check3_violations="$comp_errors"
  for plat in flutter web; do
    [ "$plat" = flutter ] && f="$flu_style" || f="$web_style"
    [ -z "$f" ] && continue
    # Strip // line comments before matching so doc/explanatory comments
    # that mention these patterns don't false-positive.
    # (a) direct typography role ref
    hit="$(grep -nE 'theme\.typography\.|theme\.coreTypography\.resolve' "$f" 2>/dev/null \
            | grep -vE ':[[:space:]]*//|^[^:]*:[0-9]+:[[:space:]]*///' )"
    if [ -n "$hit" ]; then
      while IFS= read -r l; do
        [ -z "$l" ] && continue
        fail "$f:$(cut -d: -f1 <<<"$l")  ($plat) direct typography role — route through CoreXxxStyle.defaultXxx (CoreTextStyle slot)"
        comp_errors=$((comp_errors + 1))
      done <<< "$hit"
    fi
    # (b) direct color scheme token ref
    hit="$(grep -nE "$CS_DIRECT" "$f" 2>/dev/null \
            | grep -vE ':[[:space:]]*//|^[^:]*:[0-9]+:[[:space:]]*///' )"
    if [ -n "$hit" ]; then
      while IFS= read -r l; do
        [ -z "$l" ] && continue
        fail "$f:$(cut -d: -f1 <<<"$l")  ($plat) direct cs.<token> — route through CoreXxxStyle.defaultXxx"
        comp_errors=$((comp_errors + 1))
      done <<< "$hit"
    fi
    # (c) Web scheme.resolve( — no-op (CSS resolves tokens at runtime)
    if [ "$plat" = web ]; then
      hit="$(grep -nE '[Ss]cheme\.resolve\(' "$f" 2>/dev/null \
              | grep -vE ':[[:space:]]*//|^[^:]*:[0-9]+:[[:space:]]*///' )"
      if [ -n "$hit" ]; then
        while IFS= read -r l; do
          [ -z "$l" ] && continue
          fail "$f:$(cut -d: -f1 <<<"$l")  (web) scheme.resolve(...) is a no-op — emit .toValue() (token → var(--coui-X))"
          comp_errors=$((comp_errors + 1))
        done <<< "$hit"
      fi
    fi
  done
  if [ -z "$flu_style" ] && [ -z "$web_style" ]; then
    echo "      (no platform style files — skip)"
  elif [ "$comp_errors" -eq "$check3_violations" ]; then
    echo "      PASS"
  fi

  # ─────────────────────────────────────────────────────────────────────
  # [4] Resolved 네이밍 — override* prefix / Hungarian suffix.
  # ─────────────────────────────────────────────────────────────────────
  echo "  [4] Resolved field naming (no override*/Hungarian)"
  local plat f naming_hit
  local naming_found=0
  for plat in flutter web; do
    [ "$plat" = flutter ] && f="$flu_style" || f="$web_style"
    [ -z "$f" ] && continue
    # override[A-Z] prefix field, or Hungarian Type-encoding suffix on a field.
    naming_hit="$(grep -nE '^\s*final\s+[^;]*\s+(override[A-Z][a-zA-Z0-9]*|[a-z][a-zA-Z0-9]*(ColorToken|CoreColor|ColorResolved))\s*;' "$f" 2>/dev/null)"
    if [ -n "$naming_hit" ]; then
      while IFS= read -r l; do
        [ -z "$l" ] && continue
        fail "$f:$(cut -d: -f1 <<<"$l")  ($plat) Resolved field uses override*/Hungarian naming — final value carries no unresolved-state prefix/type suffix"
        comp_errors=$((comp_errors + 1))
        naming_found=1
      done <<< "$naming_hit"
    fi
  done
  [ "$naming_found" -eq 0 ] && echo "      PASS"

  # ─────────────────────────────────────────────────────────────────────
  # [5] manual typography role class construction (Web {x}_style.dart).
  #     `emitTypography` is the single canonical path for typography — it
  #     emits a `text-{role}` class AND any explicit scalar overlay inline.
  #     Hand-rolling the role class (`text-${...token!.name}` or any
  #     `.token!.name` interpolation) bypasses it, so a role+overlay
  #     component ends up pinning the role on a class and emitting the
  #     overlay inline by hand (the exact anti-pattern that motivated the
  #     emitTypography role+overlay enhancement). Comment lines are excluded.
  # ─────────────────────────────────────────────────────────────────────
  echo "  [5] no manual typography role class (use emitTypography)"
  if [ -z "$web_style" ]; then
    echo "      (no web ${comp}_style.dart — skip)"
  else
    # Match `.token!.name` interpolation (the manual role-class construction
    # signal), then drop pure comment lines (`//`, `///`, ` * `) so the
    # explanatory prose referencing the pattern doesn't false-positive.
    local role_hit
    role_hit="$(grep -nE '\.token!\.name' "$web_style" 2>/dev/null \
                  | grep -vE '^[0-9]+:[[:space:]]*(//|\*)' )"
    if [ -n "$role_hit" ]; then
      while IFS= read -r l; do
        [ -z "$l" ] && continue
        fail "$web_style:$(cut -d: -f1 <<<"$l")  (web) manual typography role class (\`.token!.name\` interpolation) — route through emitTypography(value, fallbackDefault) so role class + overlay inline emit together"
        comp_errors=$((comp_errors + 1))
      done <<< "$role_hit"
    else
      echo "      PASS"
    fi
  fi

  # ─────────────────────────────────────────────────────────────────────
  # [7] chaining position — no synthesis inside the resolver's
  #     `return ResolvedCo...(...)` block.
  #
  #     The return literal must be a bare mapping: each argument is one of
  #       field: localVar          (paint-ready local — incl. * scaling done in the local)
  #       field: merged.xxxStyle   (nested Style slot raw-forward)
  #     `* scaling` is Stage2 EMIT (produces the paint-ready scaled value),
  #     so — like color `.resolve().toValue()` and typo `.toValue(theme:)` —
  #     it lives in a LOCAL var, never in the return (uniform: nullable +
  #     non-nullable dimensional both scale in the local).
  #     Any `??` / `.merge(` / ternary `?:` / `.toValue(` / `.resolve(` /
  #     emitColor( / emitTypography( / multi-field domain constructor
  #     (`CoreBorderRadius.only(` / `CoreBorderRadius.all(` /
  #     `CoreEdgeInsets.` / `const CoreIconStyle(` …) appearing in the
  #     return block means synthesis leaked into the literal — it belongs
  #     in a local var. (.claude/rules/resolver/resolver-pattern.md +
  #     resolver/scaling-and-gap.md Anti-Pattern B: "return literal = bare
  #     매핑; ??/.merge()/emit 합성은 local var".)
  #
  #     perl scans every `return ResolvedCo...(` … matching `);` block in
  #     both platform style files, strips `//` line comments, and flags any
  #     forbidden synthesis token in the argument-value side.
  # ─────────────────────────────────────────────────────────────────────
  echo "  [7] no synthesis in return ResolvedCo*(...) block"
  local plat f chain_found=0
  for plat in flutter web; do
    [ "$plat" = flutter ] && f="$flu_style" || f="$web_style"
    [ -z "$f" ] && continue
    local chain_hit
    chain_hit="$(perl -0777 -ne '
      # Walk each `return ResolvedCo<Name>(` … `\n  );` block.
      while (/^([ \t]*)return\s+ResolvedCo[A-Za-z0-9_]*\s*\(\s*\n(.*?)^\1\);/sgm) {
        my $indent = $1;
        my $body   = $2;
        # Reconstruct 1-based source line of the `return` for reporting.
        my $pre    = substr($_, 0, pos($_) - length($&));
        my $start  = ($pre =~ tr/\n//) + 1;
        my @lines  = split /\n/, $body;
        my $ln     = $start;  # body starts on the line after `return`
        for my $line (@lines) {
          $ln++;
          # Strip trailing // line comment (keep code before it).
          (my $code = $line) =~ s{//.*$}{};
          next if $code =~ /^\s*$/;
          # Scan EVERY code line in the return literal (not only `field:`
          # lines) so synthesis split onto a continuation line — e.g.
          #   borderWidth:
          #       (merged.borderWidth ?? default) * scaling,
          # is caught. A canonical return literal only ever contains
          # `field:` and bare identifiers (no `* scaling` — that is Stage2
          # EMIT and lives in the local), so none of the forbidden tokens
          # below appear on any line.
          if ($code =~ /\?\?/                      # ?? fallback
              || $code =~ /\.merge\(/              # composite merge
              || $code =~ /\s\?\s.*:\s/            # ternary  a ? b : c
              || $code =~ /\.toValue\(/            # core→flutter/css conversion
              || $code =~ /\.resolve\(/            # scheme.resolve
              || $code =~ /\bemit(Color|Typography)\(/  # web emit family
              || $code =~ /\*\s*scaling/                 # * scaling is Stage2 EMIT → local var
              || $code =~ /\bCore[A-Za-z]+\.(only|all|symmetric|fromLTRB|token)\(/ # multi-field ctor
              || $code =~ /\bconst\s+Core[A-Za-z]+(Style)?\(/ ) {  # inline const default
            print "$ln:$line\n";
          }
        }
      }
    ' "$f")"
    if [ -n "$chain_hit" ]; then
      while IFS= read -r l; do
        [ -z "$l" ] && continue
        fail "$f:$(cut -d: -f1 <<<"$l")  ($plat) synthesis in return block — move to a local var; return must be bare (field: localVar | merged.xxxStyle), * scaling included:$(cut -d: -f2- <<<"$l")"
        comp_errors=$((comp_errors + 1))
        chain_found=1
      done <<< "$chain_hit"
    fi
  done
  [ "$chain_found" -eq 0 ] && echo "      PASS"

  # ─────────────────────────────────────────────────────────────────────
  # [8] Flutter typography unconverted — the Flutter {x}_style.dart must
  #     materialise the label role through the single-primitive
  #     `default.merge(override).toValue(theme:, color:)` path. The legacy
  #     `applyCoreTextStyle(resolveTypographyRole(theme, default), …)`
  #     assembly is non-canonical (badge reference uses `.toValue(theme:)`).
  #     Comment lines excluded.
  #     (.claude/rules/widget/render-only.md typography state · core
  #      _to_flutter `CoreTextStyle.toValue({color:, theme:})`.)
  # ─────────────────────────────────────────────────────────────────────
  echo "  [8] Flutter typography via .toValue(theme:) (no applyCoreTextStyle/resolveTypographyRole)"
  if [ -z "$flu_style" ]; then
    echo "      (no flutter ${comp}_style.dart — skip)"
  else
    local typo_hit
    typo_hit="$(grep -nE 'applyCoreTextStyle\(|resolveTypographyRole\(' "$flu_style" 2>/dev/null \
                  | grep -vE ':[[:space:]]*//|^[^:]*:[0-9]+:[[:space:]]*///' )"
    if [ -n "$typo_hit" ]; then
      while IFS= read -r l; do
        [ -z "$l" ] && continue
        fail "$flu_style:$(cut -d: -f1 <<<"$l")  (flutter) non-canonical typography assembly — use CoreXxxStyle.defaultLabelStyle.merge(merged.labelStyle).toValue(theme:, color:)"
        comp_errors=$((comp_errors + 1))
      done <<< "$typo_hit"
    else
      echo "      PASS"
    fi
  fi

  # ─────────────────────────────────────────────────────────────────────
  # [9] widget render-only — co_<component>.dart must consume resolved.X only
  #     (1:1:1:1:1:1 use-site cols 4/6). Forbidden in the widget body:
  #       theme.typography. / .coreTypography.  (typography role hardcode)
  #       (context.)theme.coreComponentTheme.   (component-theme access — resolver's job)
  #       var merged = const CoreXxxStyle / merged.merge(  (merge chain in the widget)
  #     All of these belong in {component}_style.dart (resolveCoXxx); the widget
  #     reads resolved.X. (.claude/rules/widget/render-only.md a/b/c.)
  #     NOT flagged: `?? CoreXxxStyle.defaultX` — a contract getter exposing an
  #     effective value (`Type get x => _x ?? CoreXxxStyle.defaultX`) still
  #     references the Core single source (value-preserving, not a theme
  #     divergence), so it is an accepted use-site pattern.
  # ─────────────────────────────────────────────────────────────────────
  echo "  [9] widget render-only (co_*.dart reads resolved.X only)"
  local wf wfiles plat9 widget_hit found9=0
  for plat9 in flutter web; do
    wfiles="$(platform_widget_of "$comp" "$plat9")"
    [ -z "$wfiles" ] && continue
    while IFS= read -r wf; do
      [ -z "$wf" ] && continue
      widget_hit="$(grep -nE 'theme\.typography\.|\.coreTypography\.|\.coreComponentTheme\b|var merged = const Core[A-Za-z]+Style|merged = merged\.merge\(|resolved\.[a-zA-Z_]+\.toValue\(' "$wf" 2>/dev/null \
                      | grep -vE ':[[:space:]]*//|^[^:]*:[0-9]+:[[:space:]]*///' )"
      if [ -n "$widget_hit" ]; then
        while IFS= read -r l; do
          [ -z "$l" ] && continue
          fail "$wf:$(cut -d: -f1 <<<"$l")  ($plat9) widget not render-only — move to resolveCoXxx; widget reads resolved.X:$(cut -d: -f2- <<<"$l")"
          comp_errors=$((comp_errors + 1))
          found9=1
        done <<< "$widget_hit"
      fi
    done <<< "$wfiles"
  done
  [ "$found9" -eq 0 ] && echo "      PASS"

  # ─────────────────────────────────────────────────────────────────────
  # [10] 구현 대칭 — Web co_*.dart 의 `get X => null;` contract stub 은
  #      capability 가 상대 플랫폼 framework-native 인 Flutter 런타임 인프라
  #      타입에만 허용. Web 이 JS/CSS/HTML 로 구현 가능한 behaviour capability
  #      (inputFormatters/onTapOutside/showCursor …) 를 `=> null` 로 stub 하면
  #      WEB-MISSING (미구현). framework-native 화이트리스트 외 `=> null` 플래그.
  #      (.claude/rules/cross-platform/api.md — capability 대칭/메커니즘 비대칭.)
  # ─────────────────────────────────────────────────────────────────────
  echo "  [10] Web => null getter (framework-native capability only)"
  local nfound=0 wf10 wfiles10
  # framework-native 화이트리스트 (capability 가 Web 브라우저/DOM/native 제공)
  local NULLOK='controller|focusNode|statesController|scrollController|scrollPhysics|magnifierConfiguration|contextMenuBuilder|spellCheckConfiguration|selectionControls|selectionHeightStyle|selectionWidthStyle|maxLengthEnforcement|undoController|keyboardAppearance|dragStartBehavior|restorationId|contentInsertionConfiguration|clipBehavior|mouseCursor|style'
  wfiles10="$(platform_widget_of "$comp" web)"
  if [ -n "$wfiles10" ]; then
    while IFS= read -r wf10; do
      [ -z "$wf10" ] && continue
      local nh
      nh="$(grep -nE 'get [a-zA-Z]+ => null;' "$wf10" 2>/dev/null \
            | grep -vE ':[[:space:]]*//' \
            | grep -vE "get ($NULLOK) => null;")"
      if [ -n "$nh" ]; then
        while IFS= read -r l; do
          [ -z "$l" ] && continue
          fail "$wf10:$(cut -d: -f1 <<<"$l")  (web) => null getter — capability 가 Web-implementable 면 구현(WEB-MISSING); framework-native 만 null 허용:$(cut -d: -f2- <<<"$l")"
          comp_errors=$((comp_errors + 1)); nfound=1
        done <<< "$nh"
      fi
    done <<< "$wfiles10"
  fi
  [ "$nfound" -eq 0 ] && echo "      PASS"

  # ─────────────────────────────────────────────────────────────────────
  # [6] scoped dart analyze + design-token guard (bundled).
  # ─────────────────────────────────────────────────────────────────────
  echo "  [6] scoped dart analyze + design-token guard"
  local analyze_targets=()
  [ -d "$core_dir" ] && analyze_targets+=("$core_dir")
  [ -n "$flu_style" ] && analyze_targets+=("$(dirname "$flu_style")")
  [ -n "$web_style" ] && analyze_targets+=("$(dirname "$web_style")")
  if [ "${#analyze_targets[@]}" -gt 0 ] && command -v dart >/dev/null 2>&1; then
    if dart analyze "${analyze_targets[@]}" 2>&1 | grep -qE 'error -|warning -'; then
      fail "dart analyze reported error/warning in: ${analyze_targets[*]}"
      dart analyze "${analyze_targets[@]}" 2>&1 | grep -E 'error -|warning -' | sed 's/^/        /' | head -10
      comp_errors=$((comp_errors + 1))
    else
      echo "      dart analyze: PASS"
    fi
  else
    echo "      (dart not available or no targets — skip analyze)"
  fi
  if [ -x scripts/guards/tokens/check_design_tokens.sh ]; then
    # Phase 1,2,6 are the active sweep phases (Duration/arbitrary class/inline px).
    if ! scripts/guards/tokens/check_design_tokens.sh --phase 6 >/tmp/cds_$$.log 2>&1; then
      # Only count violations that touch THIS component's files.
      local dt_hits
      dt_hits="$(grep -E "/${comp}/" /tmp/cds_$$.log 2>/dev/null || true)"
      if [ -n "$dt_hits" ]; then
        fail "check_design_tokens.sh violations in $comp:"
        printf '%s\n' "$dt_hits" | sed 's/^/        /' | head -10
        comp_errors=$((comp_errors + 1))
      else
        echo "      design-token guard: PASS (no $comp violations)"
      fi
    else
      echo "      design-token guard: PASS"
    fi
    rm -f /tmp/cds_$$.log
  fi

  echo ""
  if [ "$comp_errors" -eq 0 ]; then
    echo "  ✅ $comp: canonical (all structural checks PASS)"
  else
    echo "  ❌ $comp: $comp_errors structural violation(s)"
  fi
  echo ""
  TOTAL_ERRORS=$((TOTAL_ERRORS + comp_errors))
}

for comp in "$@"; do
  check_component "$comp"
done

if [ "$TOTAL_ERRORS" -eq 0 ]; then
  echo "=== ✅ All components canonical ==="
  exit 0
else
  echo "=== ❌ $TOTAL_ERRORS total structural violation(s) ==="
  exit 1
fi
