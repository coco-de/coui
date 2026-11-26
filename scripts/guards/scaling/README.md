# Four-Principle Guards

CoUI 의 Style/Resolver 4원칙 + Gap/Spacing 네이밍 규칙을 강제하는 6개 CI 스크립트.
CLAUDE.md "Gap / Spacing 네이밍 + scaling 위치 규칙" 섹션에서 정의된 anti-pattern A/C/E/F + naming + inline-construct 를 차단한다.

| # | Guard | Anti-Pattern | Scan path |
|---|---|---|---|
| 1 | `check_gap_spacing_naming.sh` | 네이밍 ↔ 타입 불일치 | `coui_core/lib/src/component/contracts/**` |
| 2 | `check_gap_inline_construct.sh` | inline `Gap(gapStyle: CoreGapStyle(...))` in widget | Flutter + Web widgets |
| 3 | `check_nested_style_scaling.sh` | A: nested Style 슬롯에 `* scaling` | Flutter `*_style.dart` |
| 4 | `check_widget_scaling.sh` | C: widget 안 `* scaling` | Flutter `co_*.dart` |
| 5 | `check_scaling_naming.sh` | E: 변수명 / 직접 사용 | Flutter `*_style.dart` |
| 6 | `check_dimensional_scaling.sh` | F: dimensional resolver scaling 누락 | Flutter `*_style.dart` |

`check_scaled_locals.sh` (구 Anti-Pattern B: "`final scaled* = .. * scaling` 을
return 위치로 inline") 는 제거됐다 — `.claude/rules/resolver/resolver-pattern.md`
"RETURN literal = bare 매핑 ONLY" 로 컨벤션이 반대 방향으로 확정된 이후
(scaling 은 Stage2 EMIT 이라 **local var** 에서 끝내고 return 은 bare 매핑만),
이 가드는 정확히 그 확정된 컨벤션을 위반으로 오탐했다. 실측 검증: 이미
컨벤션을 올바르게 따르는 `menubar_style.dart` 의 `final barPadding = (...)
.toValue() * scaling;` 조차 `dart format` 이 두 줄로 감싸 가드의 단일-라인
정규식을 우연히 피해갔을 뿐 — 걸렸다면 그것도 오탐됐을 것. `check_size_tokens_pairs.sh`
와 같은 종류의 rot (컨벤션 변경 후 미갱신 가드).

## Local run

```bash
for f in scripts/guards/scaling/check_*.sh; do
  echo "=== $f ===";
  bash "$f" || true;
done
```

## CI workflow

`.github/workflows/ci.yaml`'s "Scaling guards" step runs every `scripts/guards/scaling/check_*.sh` script on PR to `main`.

## Allowlist rationale per guard

### 1. check_gap_spacing_naming.sh

Three false-positive vectors and how the allowlist handles each:

1. TextStyle-shaped row/line spacing on text contracts (e.g. skeleton_style.dart `lineSpacing`, future text contracts `rowSpacing`) — semantically a CSS-ish vertical rhythm unit, not a "gap between siblings". These are already declared as `double?`, so they already satisfy Rule B. They are also matched by field-NAME allowlist (`iconSpacing|rowSpacing|lineSpacing`) which still enforces `double?` to prevent silent drift to e.g. `CoreGapStyle?` — i.e. the allowlist tightens rather than loosens, so renaming-style drift is still caught.

2. Pre-existing `iconSpacing` convention (label_style.dart, button-family) — historic naming where "spacing between icon and label" is a raw double. Kept allowlisted by name so a future contributor cannot quietly retype it to `CoreGapStyle?` (which would imply the nested Gap slot pattern) without a rename. If `iconSpacing` is ever upgraded to the nested Style slot, the migration must rename to `iconGapStyle`, surfacing the change in review.

3. File-level escape hatch via `.lint-allowlist/gap-spacing-naming.txt` (repo-relative paths, `#` comments). The script references the file but does NOT create it — keeping the allowlist surface visible and auditable. Three contract files are listed today (empty_state · text_area · validation_badge), suppressing 4 real violations — point `ALLOWLIST_FILE` at an empty file and the guard goes red. It is a live escape hatch, not a dormant hook, so it is owned in `.github/CODEOWNERS`: adding a path here is a relaxation and needs the same review as any other ratchet.

The ambiguous `*Gap` suffix (Rule C) is deliberately NOT allowlistable by name, because the entire point is to force a rename decision. Current violations the script will flag on first CI run include: footer_style.dart `sectionTitleGap`, tooltip_style.dart `panelGap`, form_field_style.dart `requiredIndicatorGap`, date_picker_style.dart `labelBottomGap`, chip_input_style.dart `chipGap`, chip_group_style.dart `itemGap`/`rowGap`/`titleGap`, chat_style.dart `avatarGap`, empty_state_style.dart `iconBottomGap`/`titleDescriptionGap`/`descriptionActionGap` (both nullable Style slot AND Resolved non-nullable copies), text_area_style.dart `labelGap`/`descriptionGap`/`rowGap`. These are real ambiguity bugs the guard is meant to surface — they should be renamed in a sweep PR before flipping the workflow to required, or temporarily file-allowlisted with a tracking issue.

### 2. check_gap_inline_construct.sh

The only legitimate caller of `CoreGapStyle(size: ...)` literals is the resolver layer — i.e. files matching `*_style.dart`. These files own the chrome decision and emit a `ResolvedXxx` whose nested `gapStyle` slot is forwarded into widgets. So the allowlist is: any source path ending in `_style.dart` is exempt. Survey of the current tree shows 8 such files (4 in coui_flutter components, 4 in coui_web components) that legitimately literalize `CoreGapStyle(size: ...)` — e.g. `form_style.dart`, `card_style.dart`, `card_image_style.dart`, `chip_group_style.dart`, `description_card_style.dart`, `color_picker_style.dart`. These are not anti-pattern usages; they ARE the Style layer the rule is trying to centralize on. Everything else (widget files `co_*.dart` or any other component .dart) is treated as a violation. The other class of "false positive" worth calling out — `Gap.space4()` / `const Gap.space16()` named constructors — does not require an allowlist entry because the regex `Gap\(gapStyle:[[:space:]]*CoreGapStyle\(` does not match the named-constructor form (no `gapStyle:` argument at the call site). They are inherently outside the rule's scope, which matches the user's "token-folded constants are fine" exception exactly. The scan is also bounded to `packages/coui_{flutter,web}/lib/src/components/**`, so test files, example files, docs, and core token defaults outside the components tree cannot trip the guard even though they may legitimately reference `CoreGapStyle` in their own contexts.

### 3. check_nested_style_scaling.sh

스캔 범위가 `*_style.dart` (resolver 파일) 로 제한되고, 시작 패턴을 `<name>Style = ...` (좌변 변수명이 정확히 `Style` 로 끝남) 으로 좁혀 false positive 를 차단한다. ① `final iconSize = ... * scaling` 같은 컴포넌트-자체 scalar 는 변수명이 `Style` 로 끝나지 않아 잡히지 않는다. ② `return ResolvedXxx( ... size: ... * scaling )` 형식의 resolver 자기 출력 필드(예: avatar_style.dart:155)는 시작 패턴 (`<x>Style =` 또는 `= Core[A-Z]\w*Style(`) 양쪽 모두에 매치되지 않아 자연히 제외된다 — `ResolvedXxx` 는 `Style` 로 끝나는 식별자가 아니고, 시작 좌변도 `return` 이라 식별자가 아니다. ③ `final leadingIconStyle = CoreIconStyle(size: iconSize, ...)` (button_style.dart:216) 처럼 size 인자가 raw 변수 `iconSize` 일 뿐 `* scaling` 곱이 없으면 size-line 정규식이 매치되지 않아 통과한다. ④ awk 가 `//` 주석을 스트립한 뒤 검사하므로 주석 안 예시 코드 (`// CoreIconStyle(size: x * scaling)` 같은 설명) 도 잡지 않는다. ⑤ 괄호 깊이 추적으로 블록 종료를 정확히 감지해, 블록 밖에 있는 무관한 `size: ... * scaling` (예: 상위 Resolved 생성자) 를 nested-Style block 위반으로 오인하지 않는다. Allowlist 자체는 두지 않고 시작 패턴으로 정밀 게이팅한다 — 패턴 자체가 의미적으로 좁아서 별도 면제 목록이 필요한 경계 케이스가 발견되지 않는다 (위반 5건 모두 정확 식별, button/avatar/alert/toast/checkbox/text_field/text_area 등 정상 케이스 모두 통과).

### 4. check_widget_scaling.sh

False-positive 분류와 처리:

1) `// * scaling` / `/// ... * scaling` 주석:
   - co_input_otp.dart:329 "Effective sizing (resolver already applies scaling)" 같은 설명 주석,
     co_form_field.dart:61 "/// [CoreSpace.space8] * scaling." 같은 doc 주석이 다수 존재.
   - 라인 시작이 `//` 또는 `///` 인 경우 스킵 (정규식 `^[[:space:]]*///|^[[:space:]]*//`).

2) string literal 내부 `* scaling`:
   - 토큰 설명·로깅 메시지 등에서 `'... * scaling'` 형태로 나올 수 있음.
   - match 좌측의 따옴표(`'`/`"`) 개수가 홀수이면 string 내부로 간주하고 스킵 (간이 휴리스틱).

3) 비-접두 legacy 위젯 파일 (button.dart, color_picker.dart, select.dart,
   form_field.dart, menu.dart, dropdown_menu.dart 등):
   - find 글롭이 `co_*.dart` 만 잡으므로 자동으로 제외됨 — 별도 allowlist 불필요.
   - 이 파일들은 {Component} 통일 전 잔존 위젯이며 통일화(Epic #1659/#1696 sweep)
     완료 시 `co_*.dart` 로 승격되며 그때 가드 범위로 진입.

4) `*_style.dart` resolver:
   - 글롭에서 자동 제외 (co_*.dart 만 매치). resolver 가 `* scaling` 을 곱하는
     것은 정답 경로이므로 의도적으로 보호.

5) 변수명·식별자 안 `scaling` (예: `_scalingFactor`, `noScaling`):
   - 패턴이 `\* scaling\b` / `\* theme\.scaling\b` / `\* Theme\.of\(context\)\.scaling\b`
     세 형태만 잡고 word boundary `\b` 로 종료시키므로 다른 식별자에는 매치 안 됨.

현재 코드베이스 실측: co_input_otp.dart (2건), co_date_picker.dart (6건),
co_formatted_input.dart (2건), co_object_input.dart (2건), co_item_picker.dart
(2건), co_radio_group.dart 등 다수 — Anti-Pattern C 실 위반이 광범위하게 잔존
하므로 가드는 실제 marker 로 동작 (false positive 가 아닌 진짜 회귀 검출).
초기 도입은 resolver-signature-check.yml 의 strict mode 와 동일한 정책:
fail 상태로 admin merge 허용 + sweep 완료 시 자동 PASS.

### 5. check_scaling_naming.sh

The guard relies on a single-pass per-file sanitizer (awk) that strips the three commentary contexts found in this repo before any matching, which removes the only realistic false-positive sources: (a) `///` and `//` line/doc comments that quote `theme.scaling` as prose (e.g. `/// widget multiplies by theme.scaling`) — these are stripped to EOL so the token does not feed the V1/V2 matchers nor the 2+ occurrence counter, (b) single-line `/* … */` block comments — also stripped, (c) single-quoted string literal bodies — blanked so a debug log like `'scaling=${theme.scaling}'` cannot trip the guard. After sanitization the regex is intentionally conservative: V1 fires only on the literal shape `final <name> = theme.scaling` (so it never confuses a getter `theme.scaling` access for a binding), and V2 fires only when the same file has 2+ sanitized references AND a non-extraction line uses the token (the E1 exception is encoded as the `>= 2` threshold — exactly one inline use stays clean). Validated against the full real tree (`find packages/coui_flutter/lib/src/components -name '*_style.dart'` finds 30+ files with `theme.scaling`, all extracted as `final scaling = theme.scaling`, and the guard exits 0). Validated against six synthetic fixtures — V1 (`final s = …`, `final scalingFactor = …`) and V2 (two inline `* theme.scaling`) all fire on the right line numbers; single-use inline, properly-named extraction, and comment-only references all stay green. No allowlist file is needed because the comment/string sanitizer subsumes every observed exception class.

### 6. check_dimensional_scaling.sh

두 종류 false positive 가 예상되며 다음과 같이 다룬다.

(1) 파일 단위 화이트리스트 (EXEMPT_FILES): paint-only 또는 ratio-only 렌더러로 scaling 적용이 의미 없거나 부모 위젯이 대신 적용하는 컴포넌트. 사용자 지시대로 7 개 파일을 통째 제외: clickable_style.dart (borderRadius 만, 부모 chrome 이 scaling 적용), hover_style.dart (scale/opacity factor 전용), scrollview_style.dart (dragSpeed/maxScrollSpeed 는 속도값 — scaling 무관), aspect_ratio_box_style.dart (ratio 만), media_query_style.dart (breakpoint width 는 viewport 비교 절대값 — scaling 적용 시 오작동), gap_style.dart (Gap 자체는 paint-only; 부모 Xxx resolver 가 size 에 scaling 곱해서 전달), icon_style.dart (Icon 별도 가드 — size 가 사용자 의도 픽셀이거나 부모가 곱해 전달).

(2) 필드명 단위 제외 (EXEMPT_FIELD_RE): 같은 double 타입이지만 의미가 차원이 아닌 비율/요인/투명도/속도/브레이크포인트 필드. ratio / factor / opacity / velocity / breakpoint / clickable / scale 토큰이 식별자에 포함되면 dimensional 카운트에서 빼고, 남은 dimensional 이 0 이면 PASS. 이렇게 하면 (예) hover-가-아닌 컴포넌트가 우연히 `final double fadeOpacity` 하나만 가져도 오탐하지 않고, 동시에 진짜 dimensional 필드 (padding/borderRadius/size 등) 가 함께 있으면 검사가 정상 발동한다.

이 두 단계 화이트리스트는 본문에 직접 박혀있어 변경 이력을 git blame 으로 추적 가능하며, 새 paint-only 컴포넌트가 추가될 때만 EXEMPT_FILES 한 줄을 갱신하면 된다 (기존 Epic #1097/#1148 가드들과 같은 운영 방식).
