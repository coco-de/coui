---
title: Chip
description: 태그, 필터, 선택 상태를 표시하는 칩 컴포넌트
category: display
platforms: [flutter, web]
related: [chip-input, chip-group, badge, button]
tags: [interactive, tag, filter, selection]
---

# Chip

태그, 필터 옵션, 선택 상태 등을 표시하는 칩 컴포넌트입니다. 삭제 버튼, 아바타, 선택 상태를 지원합니다.

## Live Preview

<LivePreview component="chip" variants="selected,variant,shape,removable,disabled,cast-motion,prefix" />

## 사용 시기 (When to Use)

**이 컴포넌트를 사용하세요:**
- 카테고리, 태그, 키워드를 시각적으로 표현할 때
- 필터 옵션을 선택/해제할 수 있는 토글 가능한 레이블이 필요할 때
- 선택된 항목 목록을 삭제 가능한 태그로 표시할 때 (예: 이메일 수신자 목록)
- 다중 선택 UI에서 선택된 항목을 표시할 때

**대신 다른 컴포넌트를 사용하세요:**
- **[Badge](/components/badge)**: 선택·제거 상태 없이 상태 문자열이나 개수·점을 표시할 때 (`onPressed` 로 단일 클릭은 가능)
- **[Button](/components/button)**: 선택·제거할 태그 대신 단일 액션을 실행하는 컨트롤일 때
- **[ChipInput](/components/chip-input)**: 텍스트를 직접 입력하여 칩을 생성하는 입력 필드가 필요할 때

## 기본 사용법 (Basic Usage)

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
// 기본 칩
Chip(
  label: 'Flutter',
)

// 삭제 가능한 칩
Chip(
  label: 'Dart',
  onRemove: handleDeleteDart,
)

// leading 위젯 포함 칩
Chip(
  label: '홍길동',
  leading: Avatar(
    imageUrl: 'https://example.com/avatar.jpg',
    size: CoreComponentSize.xs,
  ),
  onRemove: handleDeleteUser,
)

// 선택 가능한 칩
Chip(
  label: '디자인',
  chipColor: CoreChipColor.primary,
  selected: isDesignSelected,
  onTap: handleSelectDesign,
)

// 필터 칩 — 키 글자 + 지금 값
Chip(
  variant: CoreChipVariant.filled,
  prefixLabel: '필터',
  label: '전체',
  trailing: const Icon(LucideIcons.chevronDown),
  selected: isFilterApplied,
  onTap: handleOpenFilter,
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
// 기본 칩
Chip(label: 'Flutter')

// 삭제 가능한 칩
Chip(
  label: 'Dart',
  onRemove: handleDeleteDart,
)

// leading 포함 칩
Chip(
  label: '홍길동',
  leading: Avatar(
    initials: 'C',
    size: CoreComponentSize.xs,
  ),
  onRemove: handleDeleteUser,
)

// 선택 가능한 칩
Chip(
  label: '디자인',
  chipColor: CoreChipColor.primary,
  selected: isDesignSelected,
  onTap: handleSelectDesign,
)

// 필터 칩 — 키 글자 + 지금 값
Chip(
  variant: CoreChipVariant.filled,
  prefixLabel: '필터',
  label: '전체',
  trailing: Icon(LucideIcons.chevronDown),
  selected: isFilterApplied,
  onTap: handleOpenFilter,
)
```

  </TabItem>
</Tabs>

**필터 칩**은 "무엇을 거르는가"와 "지금 값"을 한 칩에 함께 보입니다. 키 글자는
`prefixLabel` 로 넘기세요 — `child` 에 `Row` 를 넣어 같은 모양을 만들면 크기
사다리와 상태별 키 색이 닿지 않습니다.

## Props / Parameters

`W` 는 Flutter의 `Widget`, Web의 Jaspr `Component` 입니다. `W?` 는 선택 슬롯입니다.

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `prefixLabel` | `String?` | `null` | 라벨 앞에 붙는 키 글자 — 필터 칩이 무엇을 거르는지("필터", "상태"). 크기마다 라벨보다 한 단 작은 역할(`labelXs` · `labelSmall` · `labelMedium`, 굵기 500)로 그리고, 꺼진 칩에서는 키 전용 색으로 — high 칩에서는 라벨보다 옅고, low 칩에서는 라벨과 같은 색이라 크기 · 굵기로만 갈립니다 — 켜지거나 비활성이면 라벨과 같은 색입니다. 한 줄을 지키며 줄어들지 않습니다 — 좁아지면 라벨이 말줄임됩니다. `null` 이면 그리지 않습니다 |
| `label` | `String?` | `null` | 칩에 표시할 텍스트 |
| `labelMaxLines` | `int?` | `null` | 라벨이 넘칠 때까지 허용하는 줄 수. `null` 은 기존처럼 한 줄로 자릅니다 |
| `labelOverflow` | `CoreTextOverflow?` | `null` | `labelMaxLines` 에 도달한 라벨의 넘침 처리 (`clip` / `fade` / `ellipsis` / `visible`). `null` 은 기존처럼 말줄임표(`ellipsis`)입니다 |
| `child` | `W?` | `null` | 커스텀 내용 (label 대체) |
| `chipColor` | `CoreChipColor` | `.defaultColor` (`neutral`) | 켜졌을 때 칩이 입는 색 — `neutral`(반전 채움) · `primary`(브랜드 색) · `custom`(`seedColor`). 꺼진 칩은 이 값과 무관하게 무채입니다 |
| `variant` | `CoreChipVariant` | `.defaultVariant` (`outlined`) | 꺼진 칩의 모양 — `outlined`(투명 채움 + 옅은 테두리) · `filled`(회색 채움, 테두리 없음). 켜진 칩과 비활성 칩에는 관여하지 않습니다. `filled` 는 `emphasis: high` 와만 씁니다(디버그 빌드는 `filled` + `low` 를 경고합니다) |
| `emphasis` | `CoreChipEmphasis` | `high` | 켜진 칩의 강조 — `low` 연한 채움 / `high` 진한 채움. 꺼진 칩에서는 색이 아니라 라벨 진하기만 바꿉니다(`low` `onSurfaceVariant` · `high` `onSurface`) |
| `size` | `CoreChipSize` | `md` | 칩 크기 — `sm` · `md` · `lg` (28 / 32 / 40). 24 는 Badge 의 자리이고 48·56 은 Button 의 자리라 그 두 쪽 사다리는 이 컴포넌트가 갖지 않는다 |
| `shape` | `CoreChipShape` | `.defaultShape` (`rounded`) | 칩의 윤곽 — `rounded`(크기 행의 모서리 6 · 8 · 10) · `pill`(모든 크기에서 양 끝이 반원). `chipStyle` 에 `borderRadius` 를 적으면 두 모양 모두 그 값을 따릅니다 |
| `selected` | `bool` | `false` | 선택 상태 여부 |
| `enabled` | `bool` | `true` | 활성화 여부 |
| `onTap` | `VoidCallback?` | `null` | 탭 핸들러 |
| `onRemove` | `VoidCallback?` | `null` | 삭제 버튼 클릭 핸들러. null이면 삭제 버튼 미표시 |
| `leading` | `W?` | `null` | 레이블 앞 위젯 |
| `trailing` | `W?` | `null` | 레이블 뒤 위젯 |
| `seedColor` | `CoreColor?` | `null` | 커스텀 시드 색상 |
| `maxLength` | `int?` | `null` | 레이블 최대 글자 수 |
| `chipStyle` | `CoreChipStyle?` | `null` | 인스턴스 스타일 (Style 시스템 참조) |

<a id="테두리-없는-마케팅-크롬"></a>

## 테두리 없는 마케팅용 모양

기본 칩은 크기 행의 반경(`sm` 6 · `md` 8 · `lg` 10)과 1px 테두리를 그립니다. 알약이 필요하면 반경을 적지 말고 `shape: CoreChipShape.pill` 을 씁니다(→ [둥근 모서리와 알약](#둥근-모서리와-알약-shape)). 초점 링은 어느 쪽이든 칩의 반경을 따릅니다. Web 은 반경·선 굵기를 **inline** 으로 내보내므로, 제품 CSS 가 같은 속성을 이기려면 `!important` 가 필요합니다. 스타일 슬롯이 그 inline 을 직접 씁니다.

```dart
Chip(
  label: '디자인',
  chipStyle: const CoreChipStyle(
    borderWidth: CoreStrokeWidth.stroke0,
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
  ),
)
```

`borderWidth: 0` 은 선 굵기 토큰 `stroke0` 입니다. 채움 토큰은 `bg-*` 클래스 하나로 나가서 색·모양 기본 채움과 겹치지 않습니다. 테두리 없는 회색 칩이 필요한 것이라면 이 스타일을 직접 쓰기 전에 `variant: CoreChipVariant.filled` 를 먼저 봅니다.

## 스타일 시스템 (Style System)

Chip 의 겉모습(색 · 크기 · 간격)과 안쪽 부품의 스타일은 전부 `CoreChipStyle` 하나로 바꿉니다. 종류를 고르는 값 (`chipColor` / `variant` / `emphasis` / `size` / `shape` / `selected` / `enabled`) 과 내용 · 동작 필드는 위젯 파라미터로 직접 넘깁니다.

<a id="시맨틱-vs-스타일"></a>

### 파라미터와 스타일

- **종류 · 내용 · 동작**: 위젯 파라미터로 직접 (`chipColor`, `variant`, `emphasis`, `size`, `shape`, `selected`, `enabled`, `onTap`, `onRemove`, `prefixLabel`, `label`, `leading`, `trailing`, `seedColor`, `maxLength`)
- **겉모습 (색 · 크기 · 간격, 안쪽 부품의 스타일)**: `CoreChipStyle` 한 곳으로 (아래 필드 표 참고)
- **close 버튼 변형 교체**: asChild — 직접 `Button(variant: ghost, ...)` 위젯 주입은 권장 X. `closeButtonStyle` 로 겉모습만 조정하면 됩니다. 내부적으로 `Button(variant: .ghost, size: .sm)` 가 사용됩니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
design system default for chip (size row → shape row)
  → CoreChipTheme.style                    // 프로젝트 공통
  → CoreChipTheme.colorStyles[chipColor]   // 색별 (neutral · primary · custom)
  → CoreChipTheme.variantStyles[variant]   // 모양별 (outlined · filled)
  → parent component slot override
  → widget.chipStyle                       // 인스턴스별
```

맨 앞의 기본값은 크기 행(`CoreChipStyle.defaultsBySize[size]`) 위에 모양 행(`CoreChipStyle.defaultsByShape[shape]`)을 얹은 것입니다. 그 뒤의 테마와 `chipStyle` 이 적은 값이 둘 다를 이깁니다.

`CoreChipTheme.variantStyles` 의 키는 꺼진 칩의 모양(`CoreChipVariant`)이고, 색(`CoreChipColor`)별 오버라이드는 `colorStyles` 입니다. 색별 기본값 표는 `CoreChipStyle.defaultsByColor` 이며, 꺼진 칩의 열(`unselectedBg` · `unselectedFg` · `unselectedPrefixFg` · `borderColor` · `lowUnselectedFg`)은 모든 색에서 같습니다 — 꺼진 칩은 색을 말하지 않기 때문입니다.

안쪽 부품의 스타일 (`labelStyle` / `prefixLabelStyle` / `leadingIconStyle` / `trailingIconStyle` / `closeIconStyle` / `closeButtonStyle` / `clickableStyle`) 은 그 부품 자신의 기본값 · 테마와 같은 순서로 한 번 더 합쳐집니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreChipStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Panel background fill colour override — wins across every state. `null` defers to the state-keyed [defaultsByColor] base; see the note above for why there is no `default*`. |
| `foregroundColor` | `CoreColor?` | Foreground (label) colour override — wins across every state, and is also the fallback the label / key / leading / trailing / close slots inherit when they carry no colour of their own. `null` defers to the state-keyed [defaultsByColor] base; see the note above. |
| `borderColor` | `CoreColor?` | Border stroke colour. |
| `borderWidth` | `double?` | Border stroke width (logical px). |
| `borderRadius` | `CoreBorderRadius?` | Border radius. `null` defers to the shape's corner ([defaultsByShape] — the full corner for `CoreChipShape.pill`), and for `CoreChipShape.rounded` to the size row's, `CoreChipStyle.defaultsBySize[size]!.borderRadius` — 6 · 8 · 10, the chip's height × 0.25 on a `CoreRadius` rung. A value here wins over both shapes. It is also the corner the focus ring follows. |
| `padding` | `CoreEdgeInsets?` | Padding. |
| `minHeight` | `double?` | Minimum chip height (logical px). Per-size default from [defaultsBySize] — the spec's height ladder, stated as a floor so the chip matches the control tier beside it rather than its own label. |
| `contentAlignment` | `CoreMainAxisAlignment?` | Where the content row (leading · key · label · trailing · close) sits along the chip's main axis when the chip is drawn wider than its content — a caller's fixed or stretched width. A chip that hugs its content has no free space, so the value changes nothing there. `null` defers to [defaultContentAlignment]. |
| `iconLabelGapStyle` | `CoreGapStyle?` | Gap between the parts of the content row — leading, key, label, trailing and close button. `null` uses the size row's gap, `CoreChipStyle.defaultsBySize[size]!.iconLabelGapStyle!`. |
| `closeIconStyle` | `CoreIconStyle?` | Style of the X icon inside the `onRemove` close button, passed to `Icon(iconStyle: …)` as is. Separate from [leadingIconStyle] / [trailingIconStyle], which style the leading / trailing content slots. |
| `transitionDuration` | `Duration?` | Transition duration for hover / focus / state colour changes. When null falls back to [defaultTransitionDuration]. |
| `castHideDuration` | `Duration?` | The engage-squash pair's shared clock — how long the shadow takes to hide and the chip takes to travel into the space it vacated. `null` defers to [defaultCastHideDuration]. Reduced-motion collapses this to zero on both platforms — state (the hide, the travel) is unaffected. |
| `labelStyle` | `CoreTextStyle?` | Label text style override. |
| `prefixLabelStyle` | `CoreTextStyle?` | Text style of the key drawn in front of the label (the widget's `prefixLabel`). `null` uses the size row's role, `CoreChipStyle.defaultsBySize[size]!.prefixLabelStyle`, over [defaultPrefixLabelStyle]. A colour set here wins over the key colour for the chip's current state and over [foregroundColor], the way a [labelStyle] colour does for the label. |
| `leadingIconStyle` | `CoreIconStyle?` | Leading icon style override. |
| `trailingIconStyle` | `CoreIconStyle?` | Trailing icon style override (does **not** affect the close button — [closeButtonStyle] does). |
| `closeButtonStyle` | `CoreButtonStyle?` | Style for the close (`onRemove`) button — its padding, corners and colours. Each close button is a `Button(variant: ghost)` inside; the X icon in it takes [closeIconStyle]. |
| `clickableStyle` | `CoreClickableStyle?` | Style for the `Clickable` around a tappable chip (`onTap != null`) — press scale, durations, focus ring, disabled opacity. Laid over [defaultClickableStyle] and passed to the `Clickable` as is; the `Clickable` fills in the rest. |
| `customDisabledBackgroundColor` | `CoreColor?` | Disabled custom-seed chip background override. `null` → [defaultCustomDisabledBackgroundColor]. |
| `customDisabledUnselectedBackgroundColor` | `CoreColor?` | Background of a **disabled, unselected** custom-seed chip — the surface behind a hairline, the row that keeps a never-selected chip from reading as a selected one. `null` → [defaultCustomDisabledUnselectedBackgroundColor]. |
| `customDisabledForegroundColor` | `CoreColor?` | Disabled custom-seed chip foreground override. `null` → [defaultCustomDisabledForegroundColor]. |
| `customDisabledBorderColor` | `CoreColor?` | Disabled custom-seed chip border override. `null` → [defaultCustomDisabledBorderColor]. |
| `customSelectedForegroundColor` | `CoreColor?` | Selected-state custom-seed chip label colour override. `null` → the seed's own on-colour, per [defaultCustomSelectedForegroundColorFor]. |
| `lowUnselectedForegroundColor` | `CoreColor?` | Label colour override for an unselected chip at [CoreChipEmphasis.low]; `null` → [CoreChipColorStyle.lowUnselectedFg] from [defaultsByColor] — the neutral row for [CoreChipColor.custom]. |
| `lowUnselectedBorderColor` | `CoreColor?` | Border colour override for an unselected chip at [CoreChipEmphasis.low]; falls back to [defaultLowUnselectedBorderColor]. |
| `filledUnselectedBackgroundColor` | `CoreColor?` | Fill override for an unselected, enabled chip at [CoreChipVariant.filled]; `null` → [defaultFilledUnselectedBackgroundColor]. The border follows it. |
| `disabledSelectedBorderColor` | `CoreColor?` | Border colour override for a **selected disabled** chip (any colour, custom seed included); falls back to [defaultDisabledSelectedBorderColor] — none. |
| `customLowSelectedBackgroundColor` | `CoreColor?` | Fill override for a selected custom-seed chip at [CoreChipEmphasis.low] — the tint a raw seed cannot derive on its own; falls back to [defaultCustomLowSelectedBackgroundColor]. |
| `customLowSelectedForegroundColor` | `CoreColor?` | Label override for a selected custom-seed chip at [CoreChipEmphasis.low]; falls back to [defaultCustomLowSelectedForegroundColor]. |
| `stateLayer` | `CoreStateLayer?` | Ramp laid over the chip's own fill while hovered, focused or pressed. Defaults to [defaultStateLayer]. |
| `castMotion` | `CoreCastMotion?` | What this chip's cast does when the chip is engaged. |

### `CoreChipStyle` 색별 기본값 (`CoreChipColorStyle`)

| 필드 | `neutral` | `primary` |
|------|------|------|
| `lowUnselectedFg` | onSurfaceVariant | onSurfaceVariant |
| `disabledSelectedBg` | disabledContainer | disabledContainer |
| `selectedBg` | inverseSurface | primary |
| `selectedFg` | inverseOnSurface | onPrimary |
| `lowSelectedBg` | surfaceContainerHighest | primaryContainer |
| `lowSelectedFg` | onSurface | onPrimaryContainer |
| `unselectedBg` | transparent | transparent |
| `unselectedFg` | onSurface | onSurface |
| `unselectedPrefixFg` | onSurfaceVariant | onSurfaceVariant |
| `borderColor` | outlineVariant | outlineVariant |
| `disabledBg` | surface | surface |
| `disabledFg` | disabledContent | disabledContent |
| `disabledBorderColor` | disabledOutline | disabledOutline |

<!-- STYLE_TABLE:END -->

### 사용 예 (Flutter)

```dart
Chip(
  label: '선택됨',
  chipColor: CoreChipColor.primary,
  selected: true,
  onRemove: handleRemove,
  chipStyle: CoreChipStyle(
    padding: CoreEdgeInsets.symmetric(
      horizontal: CoreSpace.space12,
      vertical: CoreSpace.space6,
    ),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
    closeButtonStyle: CoreButtonStyle(
      padding: CoreEdgeInsets.all(CoreSpace.space4),
    ),
  ),
)
```

### 사용 예 (Web)

```dart
Chip(
  label: '선택됨',
  chipColor: CoreChipColor.primary,
  selected: true,
  onRemove: handleRemove,
  chipStyle: CoreChipStyle(
    padding: CoreEdgeInsets.symmetric(
      horizontal: CoreSpace.space12,
      vertical: CoreSpace.space6,
    ),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
  ),
)
```

### 빠른 오버라이드 (Chain)

이미 만든 `Chip` 인스턴스에 스타일을 빠르게 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 style 슬롯 인자와 동일하게 동작하지만, 이미 구성된 위젯 위에서 바로 이어 쓸 수 있습니다. `.radius8`처럼 Core 토큰 상수 이름과 똑같은 이름의 getter도 있습니다 — `withStyle`을 한 번 더 줄인 sugar로, 이름이 곧 값이라(radius8 == `CoreRadius.radius8`) 어느 컴포넌트에서 써도 뜻이 갈리지 않습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ChipChainExample extends StatefulWidget {
  const ChipChainExample({super.key});

  @override
  State<ChipChainExample> createState() => _ChipChainExampleState();
}

class _ChipChainExampleState extends State<ChipChainExample> {
  bool _comboSelected = false;
  bool _fullSelected = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Chip(
          label: '디자인',
          selected: _comboSelected,
          onTap: () => setState(() => _comboSelected = !_comboSelected),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Chip(
          label: '직접 지정',
          selected: _fullSelected,
          onTap: () => setState(() => _fullSelected = !_fullSelected),
        ).withStyle(
          const CoreChipStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiaryContainer),
            foregroundColor: CoreColor.token(CoreColors.onTertiaryContainer),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space12,
              vertical: CoreSpace.space4,
            ),
          ),
        ),
      ],
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class ChipChainExample extends StatefulComponent {
  const ChipChainExample({super.key});

  @override
  State<ChipChainExample> createState() => _ChipChainExampleState();
}

class _ChipChainExampleState extends State<ChipChainExample> {
  bool _comboSelected = false;
  bool _fullSelected = false;

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Chip(
          label: '디자인',
          selected: _comboSelected,
          onTap: () => setState(() => _comboSelected = !_comboSelected),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Chip(
          label: '직접 지정',
          selected: _fullSelected,
          onTap: () => setState(() => _fullSelected = !_fullSelected),
        ).withStyle(
          const CoreChipStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiaryContainer),
            foregroundColor: CoreColor.token(CoreColors.onTertiaryContainer),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space12,
              vertical: CoreSpace.space4,
            ),
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

## 변형 (Variants)

네 손잡이가 각자 한 가지만 정합니다.

| 손잡이 | 정하는 것 | 값 |
|---|---|---|
| `variant` | 꺼진 칩의 **모양** | `outlined`(기본) · `filled` |
| `shape` | 칩의 **윤곽** | `rounded`(기본) · `pill` |
| `emphasis` | 켜진 칩의 **강조** | `high`(기본, 진한 채움) · `low`(연한 채움) |
| `chipColor` | 켜진 칩의 **색** | `neutral`(기본) · `primary` · `custom` |

### 꺼진 칩의 모양 (`variant`)

| `variant` | 꺼진 칩 | 어울리는 곳 |
|---|---|---|
| `outlined` (기본) | 투명 채움, 옅은 테두리(`outlineVariant`) | 선택·필터 묶음. 어느 바탕 위에서도 |
| `filled` | 회색 채움(`surfaceContainerHigh`), 테두리 없음(채움과 같은 색) | 추천·바로 실행 칩, 흰 화면에 가볍게 까는 필터 줄 |

`variant` 는 켜진 칩에 관여하지 않습니다 — 켜진 칩은 `variant` 값과 무관하게 같은 그림입니다. 비활성 칩도 `variant` 와 무관하게 전용 disabled 토큰(꺼짐 `surface` + `disabledOutline`, 켜짐 `disabledContainer`)으로 그립니다.

```dart
Chip(
  label: '추천',
  variant: CoreChipVariant.filled,
  selected: isSelected,
  onTap: handleSelect,
)
```

<Callout type="warning">

**`filled` 는 진한 선택(`emphasis: high`)과만 씁니다.**

`filled` 인 꺼진 칩과 `low` 로 켜진 칩은 밝기 대비가 neutral 1.06, primary 1.09 (Light 기준)뿐이라 옅은 남색과 회색의 색상 차이로만 구분됩니다. 색만으로 상태를 나르면 색약 사용자와 강제 색 모드에서 구분이 사라집니다(WCAG 1.4.1). 색과 무관하게 `filled` + `low` 는 디버그 빌드에서 경고를 냅니다(릴리스 빌드에는 없습니다). 렌더 자체는 되지만 쓰지 않는 조합입니다.

</Callout>

회색 바탕(`surface-container` 이상) 위에서는 `filled` 칩이 바탕에 묻힙니다. 그 자리는 `outlined` 를 씁니다.

### 둥근 모서리와 알약 (`shape`)

`shape` 는 칩의 윤곽만 정합니다. 색 · 크기 · 상태와는 상관없습니다.

| `shape` | 모서리 | 어울리는 곳 |
|---|---|---|
| `rounded` (기본) | 크기 행의 모서리 — `sm` 6 · `md` 8 · `lg` 10 (칩 높이 × 0.25) | 태그 · 선택 묶음. 지금까지의 모든 칩 |
| `pill` | 모든 크기에서 양 끝이 반원 — 높이 28 · 32 · 40 이면 반경 14 · 16 · 20 | 필터 · 정렬 · 통화처럼 한 줄로 늘어선 칩 |

`pill` 은 새 반경 값이 아니라 "끝까지 둥글게" 라는 모양입니다. 칩의 높이가 크기마다 달라서 숫자 하나로는 세 크기의 반원을 모두 그릴 수 없기 때문입니다. 두 플랫폼은 가장 큰 모서리를 칩 높이의 절반으로 줄여 그리므로, 칩이 바닥 높이보다 커져도 알약을 지킵니다. 삭제 버튼은 크기 행의 모서리를 그대로 씁니다.

`chipStyle` 이나 테마(`CoreChipTheme.style`)에 `borderRadius` 를 적으면 그 값이 두 모양 모두를 이깁니다. 반경을 직접 적을 때는 `shape` 가 아무것도 바꾸지 않습니다.

```dart
Chip(
  label: 'USD',
  shape: CoreChipShape.pill,
  selected: isUsdSelected,
  onTap: handleSelectUsd,
)
```

### 선택과 강조 (`selected` · `emphasis`)

칩의 켜진 모양은 `chipColor` · `emphasis` 가, 꺼진 모양은 `variant` 가 정합니다. 기본값은 `neutral` · `high` · `outlined` 이므로 인자 없이 쓴 `Chip(selected: …)` 은 이렇게 그려집니다.

| 상태 | 모양 |
|---|---|
| 꺼짐 | 옅은 테두리(`outlineVariant`), 라벨 `onSurface` |
| 켜짐 | `inverseSurface` 채움과 테두리, 라벨 `inverseOnSurface` |

`selected` 와 `emphasis` 가 고르는 네 행은 다음과 같습니다(`outlined` 기준).

| selected | emphasis | 채움 | 테두리 | 라벨 |
|---|---|---|---|---|
| 꺼짐 | `low` | 없음 | `outlineVariant` | `onSurfaceVariant` |
| 꺼짐 | `high` | 없음 | `outlineVariant` | `onSurface` |
| 켜짐 | `low` | `{color}Container` | — | `on{color}Container` |
| 켜짐 | `high` | `{color}` | — | `on{color}` |

꺼진 칩은 어느 `chipColor` 든 같은 그림입니다 — 색은 켜질 때 처음 나옵니다. `emphasis` 가 꺼진 칩에서 바꾸는 것은 라벨 진하기뿐입니다. `primary` 로 같은 모양을 내려면 `chipColor` 만 바꿉니다.

```dart
Chip(
  label: '디자인',
  chipColor: CoreChipColor.primary,
  selected: isDesignSelected,
  onTap: handleSelectDesign,
)
```

라벨은 크기마다 `labelSmall` · `labelMedium` · `labelLarge`(12 / 13 / 14) 역할이고, 굵기도 그 역할의 500 그대로입니다 — 옆의 `Button` 라벨과 같은 굵기입니다. `ChipInput` 배지는 자기 400 을 명시합니다(→ [타이포그래피](/guides/typography)).

### 필터 칩의 키 글자 (`prefixLabel`)

필터 칩은 "무엇을 거르는가"(키)와 "지금 값"(라벨)을 한 칩에 보입니다. 키는 라벨 앞에 붙고, 라벨보다 한 단 작은 역할을 그 역할의 굵기 500 그대로 씁니다 — 값이 읽으러 온 글자이고 키는 그것을 이름 짓는 쪽이라, 키가 작은 쪽입니다.

| 크기 | 키 글자 | 라벨(값) |
|---|---|---|
| `sm` | `labelXs` 11 / 500 | `labelSmall` 12 / 600 |
| `md` | `labelSmall` 12 / 500 | `labelMedium` 13 / 600 |
| `lg` | `labelMedium` 13 / 500 | `labelLarge` 14 / 600 |

| 상태 | 키 글자 | 라벨(값) |
|---|---|---|
| 꺼짐 · `high` | `onSurfaceVariant` (`unselectedPrefixFg`) | `onSurface` |
| 꺼짐 · `low` | `onSurfaceVariant` | `onSurfaceVariant` — 같은 색이라 크기·굵기로만 갈립니다 |
| 켜짐 | 라벨과 같은 색 | 색별 표의 `selectedFg`(`high`) · `lowSelectedFg`(`low`) |
| 비활성 | 라벨과 같은 색 | `disabledContent` |

키는 한 줄을 지키며 줄어들지 않습니다 — 칩이 좁아지면 라벨이 말줄임됩니다. 키의 역할과 색은 `chipStyle` 의 `prefixLabelStyle` 로 덮습니다. 거기 적은 색은 라벨의 `labelStyle` 색처럼 모든 상태에서 이기고, `foregroundColor` 를 적으면 라벨과 함께 키도 그 색이 됩니다.

```dart
Chip(
  variant: CoreChipVariant.filled,
  prefixLabel: '상태',
  label: isFiltered ? '진행 중' : '전체',
  trailing: const Icon(LucideIcons.chevronDown),
  selected: isFiltered,
  onTap: handleOpenStatusFilter,
)
```

### 색 (`chipColor`)

#### Neutral (기본)
켜지면 반전 채움(`inverseSurface`)이 되는 중립 칩입니다.

```dart
Chip(label: '중립', chipColor: CoreChipColor.neutral)
```

#### Primary
켜지면 브랜드 색으로 채워지는 칩입니다.

```dart
Chip(label: '기본', chipColor: CoreChipColor.primary)
```

색 변형은 이 둘에 `custom` 을 더한 셋입니다. 성공·경고처럼 의미를 나르는 색은 [Badge](/components/badge) 가 맡습니다.

<Callout type="info">

`Chip(...).secondary` · `.tertiary` 같은 체인 getter 는 인스턴스 하나의 **배경색 토큰**(`CoreColors.secondary` / `tertiary`)을 고르는 것이고, `CoreChipColor` 의 값이 아닙니다. `chipColor` 에 넘길 수 있는 값은 `neutral` · `primary` · `custom` 입니다.

</Callout>

#### Custom (seedColor)
`seedColor` 로 임의 색을 파생시킵니다. `chipColor` 를 `custom` 으로 두고 씨드 색을 넘깁니다.

```dart
Chip(
  label: '직접 지정',
  chipColor: CoreChipColor.custom,
  seedColor: CoreColor.token(CoreColors.tertiary),
)
```

선택된 칩(`emphasis: high`)의 글자색은 씨드 채움의 on-색을 따릅니다. 씨드가 on-색과 짝을 이루는 토큰이면 그 on-토큰을 쓰고(`tertiary` → `onTertiary`, `success` → `onSuccess`), 원시 색이면 흰색과 검은색 중 그 색 위에서 대비가 더 큰 쪽을 씁니다. 다른 글자색이 필요하면 `chipStyle: CoreChipStyle(customSelectedForegroundColor: …)` 로 지정합니다.

씨드 색은 켜진 칩에만 입혀집니다. 꺼진 칩은 `neutral` 과 같은 무채(글자 `on-surface` · `on-surface-variant`, 테두리 `outline-variant`)로 그려집니다. 임의 색은 바탕 위에서 대비를 보장할 수 없기 때문입니다.

## 칩 그룹

여러 칩을 필터 그룹으로 묶어 사용할 수 있습니다.

```dart
Wrap(
  spacing: CoreSpace.space8,
  children: [
    Chip(label: 'Flutter', onRemove: () => handleDelete('flutter')),
    Chip(label: 'Dart', onRemove: () => handleDelete('dart')),
    Chip(label: 'UI', onRemove: () => handleDelete('ui')),
  ],
)
```

## 동작 스펙 (Behavior)

### 인터랙션

- **클릭/탭 (선택형)**: `onTap` 콜백 실행. `selected` 상태 갱신은 부모에서 처리
- **삭제 버튼 클릭**: `onRemove` 콜백 실행. 칩 제거는 부모에서 처리
- **호버**: 배경색 미세 변화로 상호작용 가능 상태 표시
- **포커스**: 합성된 `Clickable` 의 포커스 링 표시

### 상태 전환

- `default` → `hover` → `pressed` → `default`
- `selected` 상태 렌더는 `selected` 파라미터가 결정 (컴포넌트가 자체 토글하지 않음)
- `enabled: false`: 클릭 불가, 전용 disabled 토큰(`disabledBg` / `disabledFg` / `disabledBorderColor`)으로 렌더. `variant` 와 `chipColor` 는 비활성 칩에 관여하지 않습니다
- 제거 버튼은 `onRemove != null && enabled` 일 때만 표시됩니다. 제거 동작은 `onTap` 선택과 별개이며, 칩을 실제 목록에서 지우는 것은 부모입니다.

### 애니메이션

- 선택/호버 색 전환: `chipStyle.transitionDuration` (기본 `CoreDuration.instant` = 100ms)
- 삭제 시 (부모 목록에서): `AnimatedSize` 또는 `AnimatedOpacity` 사용 권장

### 캐스트 모션 (`castMotion`)

`chipStyle.castMotion: CoreCastMotion?` 은 칩이 *engage* 될 때 그림자(캐스트)가 언제 · 어느 쪽으로 바뀌는지를 정합니다. 세 값입니다:

| 값 | rest | engage | 참조 이름 |
|---|---|---|---|
| `defaultMotion` (기본) | 캐스트가 있음 | 캐스트가 **사라지고**, 칩이 그 자리로 이동 | `default` |
| `reverse` | 캐스트가 없음 | 캐스트가 **생기고**, 칩이 반대 방향으로 이동 | `reverse` |
| `noShadow` | 캐스트 없음 | 변화 없음 (그림자도 이동도) | `noShadow` |

`defaultMotion` 과 `reverse` 는 그림자 유무와 이동 방향이 하나의 짝으로 묶여 있습니다 — 숨김과 이동을 다른 시계에 태우면 한 번의 누름이 두 개의 사건으로 보입니다. 탭 핸들러가 없는(`onTap == null`, 예: `ChipInput` 안의 표시 전용 칩) 칩은 애초에 engage 할 수단이 없으므로, `reverse` 를 고르면 캐스트가 rest 그대로 계속 숨어 있습니다 — engage 없이 자라날 수 없기 때문입니다.

#### engage — hover 인가 press 인가

Button 과 동일하게, "engage" 는 하나의 입력이 아닙니다. **포인터가 있는 기기에서는 hover, 없는 기기에서는 press** 가 engage 를 켭니다.

| 기기 | engage 트리거 |
|---|---|
| 포인터 있음 (마우스 · 트랙패드) | hover |
| 포인터 없음 (터치 전용) | press |

이 축이 참조하는 디자인은 웹 전용 라이브러리라 `:hover` 만 말합니다. 그대로 옮기면 터치 기기에서 깨집니다 — 터치의 `:hover` 는 브라우저가 탭을 흉내 내어 켜고 다음 탭까지 꺼지지 않으므로, 칩이 탭 이후 계속 눌린 모양으로 굳어 있게 됩니다. 그래서 데스크톱은 hover, 터치는 press 로 갈립니다 — Web 은 `@media (hover: hover)`, Flutter 는 hover 이벤트가 데스크톱에만 도달하는 성질을 그대로 씁니다.

#### Button 과 다른 점 — 채움 게이트가 없습니다

Button 은 배경도 테두리도 그리지 않는 variant(`ghost`/`link`/`text`/`plain`)에서 캐스트를 걸러내는 채움 게이트를 갖고, 호출자가 명시한 `boxShadow` 가 이 축을 이깁니다. Chip 에는 둘 다 없습니다 — `CoreChipStyle` 에 `boxShadow` 슬롯 자체가 없고(칩은 자기 그림자를 직접 조합하는 용도가 아님), 모든 칩이 기본으로 1px 테두리(`borderWidth` 기본값 `stroke1`)를 그리므로(`filled` 의 테두리는 채움과 같은 색이라 보이지 않을 뿐 같은 1px 입니다) "던질 박스가 없는" 상태가 되지 않습니다. 그래서 `castMotion` 은 활성 스타일이 캐스트를 publish 하기만 하면 배경 채움 여부와 무관하게 항상 적용됩니다 — `chipStyle.borderWidth` 를 `0` 으로 직접 낮추고 배경도 투명으로 둔 경우는 예외이며, 그 조합에서는 박스 없이 그림자만 뜬 모양이 될 수 있습니다.

#### 눈에 보이려면 스타일이 캐스트를 publish 해야 합니다

`castMotion` 은 *언제* 캐스트가 바뀌는지만 말합니다. 캐스트 자체(오프셋 · 색 · 두께)는 [서페이스 스타일](/guides/surface-styles) 이 진술합니다. 오늘은 **Neo-brutalism** 프리셋만 이 값을 publish 합니다 — 나머지(Default · Liquid Glass · Neumorphism · Claymorphism) 아래에서는 `castMotion` 을 무엇으로 바꾸든 화면이 그대로입니다. 위 라이브 프리뷰가 아무 변화도 안 보인다면 결함이 아니라 활성 프리셋이 이 축을 publish 하지 않는다는 뜻입니다 — 프리셋 스위처로 Neo-brutalism 을 켜면 세 값의 차이가 드러납니다.

## 사용 가이드라인 (Usage Guidelines)

### ✅ Do

<Callout type="tip">

**필터 그룹에서 선택형 칩 사용**

```dart
Wrap(
  spacing: CoreSpace.space8,
  children: categories.map((cat) => Chip(
    label: cat.name,
    chipColor: CoreChipColor.primary,
    selected: selectedCategories.contains(cat.id),
    onTap: () => handleToggleCategory(cat.id),
  )).toList(),
)
```

선택형 칩은 필터 옵션을 토글하는 데 직관적인 UI를 제공합니다.

</Callout>

---

### ✅ Do

<Callout type="tip">

**흰 화면에 가볍게 까는 필터 줄은 `filled` + `high`**

```dart
Chip(
  label: '추천',
  variant: CoreChipVariant.filled,
  selected: isSelected,
  onTap: handleSelect,
)
```

회색 채움 칩은 테두리 없이도 칩으로 읽히고, 켜지면 진한 채움으로 바뀌어 상태가 분명합니다. 회색 바탕(`surface-container` 이상) 위에서는 `outlined` 를 쓰세요.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**`filled` 칩을 연한 선택(`low`)과 함께 쓰지 마세요.**

```dart
// ❌ 꺼진 회색 채움과 켜진 연한 채움이 색상으로만 갈린다
Chip(
  label: '추천',
  variant: CoreChipVariant.filled,
  emphasis: CoreChipEmphasis.low,
  selected: isSelected,
)
```

두 상태의 밝기 차이가 거의 없어 색약 사용자와 강제 색 모드에서 구분되지 않습니다. 연한 선택이 필요하면 `variant` 를 `outlined` 로 두세요.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**칩에 긴 텍스트 사용 금지**

```dart
// ❌ 너무 긴 레이블
Chip(
  label: '사용자가 최근에 방문한 카테고리 항목', // 너무 길다
)
```

칩은 짧고 간결한 레이블에 최적화되어 있습니다. 긴 텍스트는 레이아웃을 깨뜨리고 가독성을 저해합니다. 2~3단어 이내로 제한하세요.

</Callout>

### ✅ Do

<Callout type="tip">

**삭제 가능한 칩 목록에 애니메이션 적용**

```dart
AnimatedList(
  initialItemCount: tags.length,
  itemBuilder: (context, index, animation) => SizeTransition(
    sizeFactor: animation,
    child: Chip(
      label: tags[index],
      onRemove: () => handleRemoveTag(index),
    ),
  ),
)
```

칩 삭제 시 자연스러운 애니메이션은 사용자에게 변화를 시각적으로 전달합니다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**비활성화된 칩에 삭제 버튼 표시 금지**

```dart
// ❌ enabled: false 이지만 onRemove 가 있음
Chip(
  label: '읽기 전용 태그',
  enabled: false,
  onRemove: handleDelete, // disabled 상태에서는 의미 없음
)
```

비활성화된 칩에 삭제 버튼이 있으면 사용자가 혼란스러워합니다. `enabled: false` 일 때는 `onRemove` 를 null 로 설정하세요.

</Callout>

### ✅ Do

<Callout type="tip">

**Chip의 label은 간결하게 작성하세요.**

```dart
// ✅ 짧고 명확한 레이블
Chip(label: '모바일', onTap: handleMobileSelected)
Chip(label: 'UX', onTap: handleUxSelected)
Chip(label: 'Flutter', onTap: handleFlutterSelected)
```

Chip은 키워드나 태그처럼 짧은 텍스트를 표시하는 용도입니다. 간결한 레이블이 스캔과 선택을 쉽게 만듭니다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**Chip에 긴 문장을 넣지 마세요.**

```dart
// ❌ 너무 긴 Chip 레이블
Chip(
  label: '사용자가 직접 등록한 관심 카테고리',  // 너무 길다
  onTap: handleCategorySelected,
)
```

긴 텍스트는 Chip의 시각적 일관성을 깨고 레이아웃을 혼란스럽게 만듭니다. Badge나 Tag 컴포넌트를 고려하세요.

</Callout>

## 접근성 (Accessibility)

### 역할

- **Flutter** — `onTap` 이 있을 때만 `Clickable` 이 `Semantics(button: true,
  enabled: …)` 를 답니다. 표시 전용 칩(`onTap == null`, 예: `ChipInput` 안)에는
  `Semantics` 가 없습니다. `selected` 는 어느 경로로도 시맨틱에 실리지 않습니다.
- **Web** — `onTap` 이 있으면 `Clickable` 루트가 `role="button"` 과
  `tabindex="0"` 을, 비활성이면 `aria-disabled="true"` 를 냅니다. 표시 전용 칩은
  role 없는 `<div>` 이고 비활성일 때만 `aria-disabled` 가 붙습니다.
  `aria-selected` / `aria-pressed` 는 어느 쪽도 없습니다.
- 제거 버튼은 양 플랫폼 모두 `Button`(ghost) 이며, 로케일과 `label` 에서 온 이름을 갖습니다.

### 키보드

| 키 | Flutter | Web |
|---|---|---|
| `Tab` | 칩(탭 가능할 때)과 제거 버튼이 각각 tab stop | 동일 |
| `Enter` / `Space` (칩) | `onTap` 실행 | `onTap` 실행 |
| `Enter` / `Space` (제거 버튼) | `onRemove` 실행 | `onRemove` 실행 |
| `Delete` / `Backspace` 로 제거 | **없음** | **없음** |

칩에 포커스한 채 지우는 경로가 없어, 제거하려면 `Tab` 으로 제거 버튼까지
이동해야 합니다.

### 스크린 리더

이름은 `label`(또는 `child`)에서 나오고, `prefixLabel` 이 있으면 그 앞에 그려진
순서대로 읽힙니다("필터 전체"). `maxLength` 로 잘린 칩은 잘린 문자열과
`...` 이 그대로 읽히고, 원본을 읽히는 경로는 없습니다.

- **삭제 버튼 이름**: 아이콘만 있는 버튼이라 자기 텍스트가 없으므로, 양 플랫폼 모두 칩의 이름(`prefixLabel` 이 있으면 키 글자, 그다음 `label`)을 넣은 이름을 붙입니다 — Flutter 는 `Semantics(label:)`, Web 은 `aria-label`. 값은 렌더 시점에 활성 로케일에서 읽습니다(`chipRemoveLabel` — 영어 `Remove {label}`, 한국어 `{label} 제거`). 이름이 없으면 삭제 가능한 칩이 여럿일 때 스크린 리더가 똑같은 이름 없는 버튼을 줄줄이 읽어, 무엇을 지우려는지 알 수 없습니다.

**선택 상태는 통보되지 않습니다.** 선택형 칩도 일반 버튼으로 읽혀 켜짐과 꺼짐을
구분할 수 없습니다.

비활성은 탭 가능한 칩에서만 전달됩니다 — Web `aria-disabled="true"`, Flutter
`Semantics(enabled: false)`. 표시 전용 비활성 칩은 Web 에만 `aria-disabled` 가
남고 Flutter 에는 아무 신호가 없습니다.

칩이 제거된 사실을 알리는 live region 은 양쪽 다 없습니다.

### 포커스 관리

- **진입 / 트랩** — 없음. 포커스는 칩 밖으로 그대로 빠져나갑니다.
- 칩을 제거하면 그 버튼이 사라지므로 **포커스를 잃습니다** — 다음 칩이나
  컨테이너로 옮겨주는 코드가 양 플랫폼 모두 없습니다.
- **포커스 표시** — 닫기 버튼의 링은 링과 버튼 사이 2px 간격을 `surface` 밴드로
  칠합니다(`CoreChipStyle.defaultCloseButtonStyle`). 닫기 버튼은 칩 채움 위에 놓여
  링이 칩 색과 맞닿기 때문입니다. `ChipInput` 의 칩도 같은 기본값을 받습니다.

### 알려진 제약

- **삭제 버튼 이름은 `label` 에서 옵니다.** `child` 만 쓴 칩은 삭제 문구에 항목
  이름이 들어가지 않습니다. 삭제 가능한 칩에는 `label` 도 채우세요.
- 칩은 작은 사이즈에서 24 (`CoreTouchTarget.minimum`) 아래로 그려지므로,
  `TouchTarget`(Flutter) / `coui-touch-target`(Web)이 **그리는 크기는 그대로 둔 채**
  닿는 범위만 그 하한까지 넓힙니다.
- 삭제 버튼은 칩이 **탭 가능하지 않을 때만**(`onTap` 없음 — `ChipInput` 이 그리는
  칩 전부) 자기 하한을 갖습니다. 탭 가능한 칩은 칩 전체가 이미 하한을 들고 있어서,
  그 안에 하한을 하나 더 두면 삭제 영역이 라벨 위로 넓어져 칩을 누르려던 탭이
  칩을 지웁니다. 삭제 버튼의 확장은 **안쪽(라벨 쪽)**을 향합니다.
- **`filled` + `low` 는 상태가 색상으로만 갈립니다.** 꺼진 회색 채움과 켜진 연한 채움의 밝기 대비가 neutral 1.06 · primary 1.09 (Light) 라 색을 구분하지 못하면 두 상태가 같아 보입니다(WCAG 1.4.1). 디버그 빌드는 이 조합을 경고합니다.
- **OS 색 강제 모드에서 선택 칩과 비선택 칩이 같아 보입니다.** 두 상태의 차이가
  채움·전경·보더 색이 함께 갈리지만 축이 **색뿐**이라(`selectedBg`/`selectedFg`/보더 ↔ 투명 채움 + `unselectedFg`) 시맨틱 색이 시스템
  색으로 접히면 구분할 축이 남지 않습니다. 비활성은 투명도가 아니라 전용
  disabled 토큰으로 그려 이 모드에서도 살아남습니다.
- **선택 상태의 시맨틱은 자동으로 붙지 않습니다.** Web 은 `attributes` 를
  루트에 통과시킬 수 있으므로 호출부가 상태를 함께 실을 수 있고, Flutter 는
  호출부에서 `Semantics(selected:)` 로 보완해야 합니다.

## 크로스 플랫폼 차이점 (Platform Differences)

| 항목 | Flutter | Web |
|------|---------|-----|
| 그룹 레이아웃 | `Wrap` 위젯 | `flexbox` 자동 처리 |
| 색 전환 | `AnimatedContainer` (`transitionDuration`) | CSS `transition` (동일 토큰) |
| `pill` 의 반원 끝 | 가장 큰 모서리(`radius9999`)를 그리는 순간 높이의 절반으로 줄임 | 같은 모서리를 inline 으로 내고, 브라우저가 겹치는 모서리를 높이의 절반으로 줄임 |
| `filled` + `low` 경고 | `FlutterError.reportError` (디버그 빌드) | `console.warn` (디버그 빌드, 서버 렌더에는 출력 없음) |

## 관련 컴포넌트 (Related Components)

- **[ChipInput](/components/chip-input)**: 텍스트 입력으로 칩을 동적으로 추가하는 입력 필드
- **[Badge](/components/badge)**: 상호작용 없이 상태나 숫자만 표시할 때 사용
- **[Button](/components/button)**: 클릭 시 명확한 단일 액션이 실행되어야 할 때

### 조합 예제

```dart
// Chip + ChipInput 조합으로 태그 입력 UI 구현
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Wrap(
      spacing: CoreSpace.space8,
      runSpacing: CoreSpace.space4,
      children: selectedTags.map((tag) => Chip(
        label: tag,
        onRemove: () => handleRemoveTag(tag),
      )).toList(),
    ),
    Gap(gapStyle: CoreGapStyle(size: CoreSpace.space8)),
    ChipInput(
      placeholder: '태그 추가...',
      onSubmitted: handleAddTag,
    ),
  ],
)
```
