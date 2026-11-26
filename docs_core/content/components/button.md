---
title: Button
description: 사용자가 저장, 제출, 삭제처럼 하나의 행동을 실행하도록 돕는 기본 컨트롤입니다. 하나의 Button에 variant와 size를 지정해 모든 버튼을 만듭니다.
category: control
platforms: [flutter, web]
related: [fab, toggle, menu]
tags: [interactive, action, form-control]
template: v2
source: control/button
---

# Button

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 버튼을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="button" />

<a id="구조-anatomy"></a>

## 구조

버튼은 컨테이너 하나와 세 개의 슬롯으로 이루어집니다.

<Anatomy demo="button/anatomy">
<AnatomyItem part="container" name="Container">

배경, 테두리, 모서리. 모서리는 높이의 0.25배입니다.

</AnatomyItem>
<AnatomyItem part="leading" name="leading">

라벨 앞 아이콘 슬롯. 선택 사항입니다.

</AnatomyItem>
<AnatomyItem part="label" name="child">

버튼 라벨. 필수이며 접근 가능한 이름이 됩니다.

</AnatomyItem>
<AnatomyItem part="trailing" name="trailing">

라벨 뒤 아이콘 슬롯. 선택 사항입니다.

</AnatomyItem>
</Anatomy>

<a id="변형-variants"></a>

## Variant

행동의 중요도에 따라 7가지 중 하나를 고릅니다. 한 영역에는 primary를 하나만 둡니다.

<VariantRow name="primary" component="button" props="variant=primary" label="저장하기">

화면에서 가장 중요한 행동 하나에 씁니다. 저장, 제출, 다음 단계처럼 흐름을 앞으로 보내는 행동입니다.

</VariantRow>

<VariantRow name="secondary" component="button" props="variant=secondary" label="임시 저장">

primary를 보조하는 두 번째 행동에 씁니다.

</VariantRow>

<VariantRow name="tonal" component="button" props="variant=tonal" label="미리 보기">

secondary보다 조금 더 눈에 띄어야 하는 보조 행동에 씁니다.

</VariantRow>

<VariantRow name="outline" component="button" props="variant=outline" label="취소">

취소, 뒤로 가기처럼 중립적인 행동에 씁니다. 카드형 버튼도 outline에 radius16을 지정해 만듭니다.

</VariantRow>

<VariantRow name="ghost" component="button" props="variant=ghost" label="편집">

툴바나 표의 행처럼 반복해서 나오는 가벼운 행동에 씁니다.

</VariantRow>

<VariantRow name="plain" component="button" props="variant=plain" label="자세히 보기">

닫기(✕)나 복사처럼 조용한 보조 행동에 씁니다. 채움 없이 흐린 글자로 두었다가 hover에서 진해집니다. 글자만 있는 이동 링크는 Link를 씁니다.

</VariantRow>

<VariantRow name="destructive" component="button" props="variant=destructive;leading=trash-2" label="삭제">

삭제처럼 되돌리기 어려운 행동에 씁니다. 라벨에 결과를 분명히 적어 주세요.

</VariantRow>

<Note>

menu, menubar, fixed는 Menu 컴포넌트 안에서만 쓰는 내부용 variant라 이 페이지에서는 다루지 않습니다.

</Note>

## 크기

높이 24부터 64까지 6단계입니다. 여백, 아이콘, 글자 크기가 높이에 맞춰 함께 바뀝니다.

<SizeSpec component="button" label="버튼" />

<Note>

기본값은 md(40)입니다. 모바일 화면의 주요 행동에는 lg(48) 이상을 권장합니다.

</Note>

## 형태

아이콘만 있는 버튼은 square나 circle로 만들고, 반드시 접근 가능한 이름을 지정합니다.

<Cards columns="3">
<Card component="button" props="shape=rectangle" label="저장하기" title="rectangle">

기본 모양입니다. 라벨이 있는 모든 버튼에 씁니다.

</Card>
<Card component="button" props="shape=square;variant=outline;icon=plus" title="square">

아이콘만 있는 버튼입니다. 툴바나 입력창 옆에 씁니다.

</Card>
<Card component="button" props="shape=circle;icon=plus" title="circle">

아이콘만 있는 둥근 버튼입니다. 떠 있는 영역에 씁니다.

</Card>
</Cards>

<a id="동작-스펙-behavior"></a>

## 상태

모든 variant는 같은 다섯 가지 상태를 가집니다.

<Preview demo="button/states" />

| 항목 | 동작 |
| --- | --- |
| 전환 시간 | 150ms |
| 누를 때 크기 | 0.95배로 줄어듭니다. buttonStyle의 pressedScale로 바꿀 수 있습니다. |
| 채워진 variant | primary와 destructive는 hover와 press에서 컨테이너 색을 바꿉니다. |
| 밝은 variant | secondary, tonal, outline, ghost는 반투명 상태 레이어를 덮습니다. |
| 포커스 | 채우기는 그대로 두고 링만 더합니다. |
| 반응 기준 | 마우스가 있으면 hover에, 터치만 있는 기기에서는 press에 반응합니다. |

<a id="링크-버튼-href"></a>

## 링크 버튼

다른 페이지로 이동하는 버튼은 onPressed 대신 href를 지정합니다.

<Preview component="button" props="variant=outline;trailing=external-link;href=https://cocode.im;external" label="홈페이지 열기" />

```dart
Button(
  variant: CoreButtonVariant.outline,
  href: 'https://cocode.im',
  external: true,
  child: Text('홈페이지 열기'),
)
```

| 설정 | 웹에서 렌더링되는 결과 |
| --- | --- |
| `href` | 실제 `<a href>`로 렌더링합니다. 검색 엔진이 링크를 따라갈 수 있습니다. |
| `external: true` | `target="_blank"`와 `rel="noopener noreferrer"`를 함께 붙입니다. |
| `enabled: false` | 비활성 `<button>`으로 렌더링하고 URL을 노출하지 않습니다. |

<Note>

Flutter에서는 링크 정보만 시맨틱으로 전달하고, 실제 이동은 onPressed에서 처리합니다.

</Note>

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 켜고 끄는 값을 바꿀 때 | [Toggle](/components/toggle) |
| 글자만 있는 이동 링크 | [Link](/components/link) |
| 화면의 대표 행동을 떠 있게 둘 때 | [FAB](/components/fab) |
| 여러 행동을 하나로 묶을 때 | [Menu](/components/menu) |

### 라벨과 강조

<Cards columns="2">
<Card demo="button/do-one-primary" tone="do" eyebrow="이렇게 하세요">

한 영역에는 primary를 하나만 둡니다.

</Card>
<Card demo="button/dont-two-primary" tone="dont" eyebrow="이렇게 하지 마세요">

primary가 둘이면 무엇이 중요한지 알 수 없습니다.

</Card>
<Card demo="button/do-clear-label" tone="do" eyebrow="이렇게 하세요">

되돌릴 수 없는 행동은 라벨에 결과를 적습니다.

</Card>
<Card demo="button/dont-vague-label" tone="dont" eyebrow="이렇게 하지 마세요">

'확인'만으로는 무엇이 일어나는지 알 수 없습니다.

</Card>
<Card demo="button/do-ghost-repeat" tone="do" eyebrow="이렇게 하세요">

반복되는 가벼운 행동은 ghost로 무게를 줄입니다.

</Card>
<Card demo="button/dont-heavy-repeat" tone="dont" eyebrow="이렇게 하지 마세요">

반복되는 행동을 모두 채우면 화면이 무거워집니다.

</Card>
</Cards>

## 배치

버튼 여러 개를 함께 둘 때의 순서와 정렬입니다.

<Cards columns="2">
<Card demo="button/placement-dialog" height="340" title="다이얼로그">

주요 행동은 오른쪽 끝에, 보조 행동은 그 왼쪽에 둡니다.

</Card>
<Card demo="button/placement-mobile" height="340" title="모바일 하단">

화면 하단에 고정한 버튼은 expanded로 가로를 채웁니다.

</Card>
</Cards>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

variant, size, shape는 위젯 속성으로 고르고, 색이나 여백처럼 보이는 값은 buttonStyle로 덮어씁니다.

<Preview demo="button/theme-order" />

<Split>

<Code language="dart" title="버튼 하나만 바꾸기">
Button(
  variant: CoreButtonVariant.outline,
  buttonStyle: CoreButtonStyle(
    borderRadius: CoreBorderRadius.all(
      CoreRadius.radius16,
    ),
    pressedScale: 1.0,
  ),
  child: Text('카드형 버튼'),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    button: CoreButtonTheme(
      style: CoreButtonStyle(
        pressedScale: 1.0,
      ),
    ),
  ),
)
</Code>

</Split>

<Note>

CoreButtonStyle에는 색, 테두리, 여백, 크기 제한, 애니메이션 등 35개 필드가 있습니다. 전체 목록은 API에서 확인하세요.

</Note>

<a id="접근성-accessibility"></a>

## 접근성

Flutter는 `Semantics(button: true)`로, 웹은 네이티브 `<button>` 또는 `<a href>`로 버튼임을 알립니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | `Semantics(button: true)`. `href`가 있으면 링크 정보가 같은 노드에 함께 붙습니다. |
| Jaspr Web | 네이티브 `<button>`. `href`가 있고 활성이면 `<a href>`입니다. |

### 키보드

| 키 | 동작 |
| --- | --- |
| `Enter` · `Space` | 버튼을 실행합니다. |
| `Tab` | 다음 요소로 포커스를 옮깁니다. |
| `Shift` · `Tab` | 이전 요소로 포커스를 옮깁니다. |

<Note>

비활성 버튼은 포커스 순서에서 빠집니다.

</Note>

### 스크린 리더

접근 가능한 이름은 `child`의 내용에서 옵니다. 아이콘만 넣은 버튼은 이름이 비므로 웹에서는 `aria-label`로 이름을 지정합니다.

<Preview demo="button/a11y-icon-name" />

활성 · 비활성은 두 플랫폼 모두 알립니다. 누른 결과는 버튼이 알리지 않으니, 무엇이 바뀌었는지는 화면이 알려야 합니다.

### 포커스 관리

마운트될 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. 포커스 링은 키보드로 포커스했을 때만 나타납니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | 선택 상태를 스크린 리더에 알리지 않습니다. |
| Flutter | 아이콘 버튼의 이름을 지정하는 슬롯이 아직 없습니다. |
| Jaspr Web | `disableFocusOutline`이 동작하지 않습니다. |
| 공통 | 모션 줄이기 설정의 처리 방식이 플랫폼마다 다릅니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 시맨틱 | `Semantics(button: true)` | 네이티브 `<button>` |
| 링크 | Semantics로 링크 정보 전달, 이동은 onPressed에서 처리 | 실제 `<a href>`로 렌더링 |
| 포커스 링 끄기 | `disableFocusOutline` 지원 | 지원하지 않음 |
| 아이콘 버튼 이름 | 지정 슬롯 없음 | `aria-label` |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다.

### 내용과 형태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `Widget` | 필수 | 버튼 라벨. 접근 가능한 이름이 됩니다. |
| `variant` | `CoreButtonVariant` | `primary` | 시각적 강조 수준 |
| `size` | `CoreComponentSize` | `md` | 높이, 여백, 아이콘 크기 |
| `shape` | `CoreButtonShape` | `rectangle` | rectangle, square, circle |
| `leading` | `Widget?` | `null` | 라벨 앞 아이콘 |
| `trailing` | `Widget?` | `null` | 라벨 뒤 아이콘 |
| `buttonStyle` | `CoreButtonStyle?` | `null` | 보이는 값 덮어쓰기 |
| `role` | `CoreSurfaceRole` | `defaultRole` | 버튼이 놓인 맥락의 역할 |

### 상태와 레이아웃

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `enabled` | `bool?` | `null` | 지정하지 않으면 콜백이나 href 유무로 정합니다. |
| `href` | `String?` | `null` | 지정하면 웹에서 링크로 렌더링합니다. |
| `external` | `bool` | `false` | 새 탭에서 엽니다. |
| `expanded` | `bool` | `false` | 가로를 꽉 채웁니다. |
| `alignment` | `AlignmentGeometry?` | `null` | 내용 정렬 |
| `marginAlignment` | `AlignmentGeometry?` | `null` | 여백 기준 정렬 |
| `disableTransition` | `bool` | `false` | 상태 전환 애니메이션 끄기 |
| `disableHoverEffect` | `bool` | `false` | hover 효과 끄기 |
| `disableFocusOutline` | `bool` | `false` | 포커스 링 끄기 (Flutter 전용) |

### 콜백

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `onPressed` | `VoidCallback?` | `null` | 눌렀을 때 |
| `onHover` | `ValueChanged<bool>?` | `null` | hover 상태가 바뀔 때 |
| `onFocus` | `ValueChanged<bool>?` | `null` | 포커스 상태가 바뀔 때 |
| `onTapDown` 외 14개 | `GestureCallback?` | `null` | 탭, 길게 누르기, 보조 탭 등 세부 제스처 |

### 고급

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `enableFeedback` | `bool?` | `null` | 터치 피드백. null이면 켜짐 |
| `focusNode` | `FocusNode?` | `null` | 포커스를 직접 제어할 때 |
| `statesController` | `WidgetStatesController?` | `null` | 상태를 직접 제어할 때 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreButtonStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Background fill colour override. |
| `foregroundColor` | `CoreColor?` | Foreground (label / icon) colour override. A colour set in [leadingIconStyle] / [trailingIconStyle] wins over it for that icon. |
| `borderColor` | `CoreColor?` | Border stroke colour override. |
| `hoverBackgroundColor` | `CoreColor?` | Hover background fill colour override. `null` → the variant's `hoverBackgroundColor`. Mirrors [backgroundColor] for the hovered state so the hover colour can be set per button, not only per variant. |
| `hoverForegroundColor` | `CoreColor?` | Hover foreground (label / icon) colour override. `null` → the variant's `hoverForegroundColor` (else idle foreground). |
| `hoverBorderColor` | `CoreColor?` | Hover border stroke colour override. `null` → the variant's `hoverBorderColor` (else idle border colour). |
| `borderWidth` | `double?` | Border stroke width override (logical px, pre-scaling). |
| `borderRadius` | `CoreBorderRadius?` | Border radius override for the rectangle and square shapes. `null` → the variant's own [CoreButtonVariantStyle.radius], else the size row's corner (the control height × 0.25) — [borderRadiusForSize]. |
| `boxShadow` | `List<CoreShadowLayer>?` | Drop-shadow / elevation override. `null` → no shadow (buttons are flat by default); a non-null layer list paints an elevation behind the surface — used by composing components such as `Fab` that need a floating elevation on an otherwise plain button surface. |
| `castMotion` | `CoreCastMotion?` | What this button's cast does when the button is engaged. |
| `dashedBorder` | `bool?` | Whether to render a dashed border instead of a solid one. |
| `dashedBorderColor` | `CoreColor?` | Dashed border stroke colour override. Falls back to [borderColor] when null. |
| `dashLength` | `double?` | Dash segment length when [dashedBorder] is true (logical px). `null` → [defaultDashLength]. |
| `dashSpacing` | `double?` | Gap between dash segments (logical px). `null` → [defaultDashSpacing]. |
| `height` | `double?` | Fixed height override (logical px). |
| `width` | `double?` | Fixed width override (logical px). |
| `minWidth` | `double?` | Minimum width constraint (logical px). |
| `maxWidth` | `double?` | Maximum width constraint (logical px). |
| `padding` | `CoreEdgeInsets?` | Padding override. |
| `iconLabelGapStyle` | `CoreGapStyle?` | Gap between the leading / trailing icon and the label, passed to the `Gap` between them as is. `null` takes the size's gap from [defaultsBySize], then falls back to [defaultIconLabelGapStyle]. |
| `circleBorderRadius` | `CoreBorderRadius?` | Border radius override for `CoreButtonShape.circle`. `null` defers to [defaultCircleBorderRadius] (pill). The shape itself is set on the widget; this field only changes the corners drawn for the circle shape. |
| `iconShapePadding` | `CoreEdgeInsets?` | Padding override for `CoreButtonShape.square` / `CoreButtonShape.circle`. `null` defers to [defaultIconShapePadding] (zero — tight icon container). The shape itself is set on the widget; this field only changes the padding used for the square / circle shapes. |
| `animationDuration` | `Duration?` | How long the button's look (colours, border, corners, padding) takes to change between states (hover / focus / pressed). `null` defers to [defaultAnimationDuration]. |
| `castHideDuration` | `Duration?` | The engage-squash pair's shared clock — how long the shadow takes to hide and the control takes to travel into the space it vacated. `null` defers to [defaultCastHideDuration]. Reduced-motion collapses this to zero on both platforms (`core/design-tokens.md`'s transition tier) — state (the hide, the travel) is unaffected. |
| `pressedScale` | `double?` | Scale the button shrinks to while pressed. `null` defers to [defaultPressedScale]; `1.0` turns the shrink off. Rides the [castHideDuration] clock on both platforms, so the press reads as one gesture with the engage pair. The rest render never wears it. |
| `disableHoverEffect` | `bool?` | Whether the hover visual effect is suppressed. `null` defers to [defaultDisableHoverEffect]. |
| `stateLayer` | `CoreStateLayer?` | State-layer ramp laid over the resting fill on hover and pressed — the resting label colour at the ramp's weights. `null` defers to the variant's own ramp ([CoreButtonVariantStyle.stateLayer]), which the filled variants leave unset because they swap the container instead. |
| `focusOutlineStyle` | `CoreFocusOutlineStyle?` | Focus ring override ([CoreFocusOutlineStyle]) — ring colour, width, offset and the colour of the band in the offset. `null` (or any field left unset in it) defers to [defaultFocusOutlineStyle]. |
| `labelStyle` | `CoreTextStyle?` | Label text style override (a `CoreTextStyle`), so any of font size, weight or colour can be changed without touching the rest of the button's look. |
| `leadingIconStyle` | `CoreIconStyle?` | Leading icon style override (a `CoreIconStyle`) — set its size, its colour, or both. |
| `trailingIconStyle` | `CoreIconStyle?` | Trailing icon style override (a `CoreIconStyle`). |
| `iconShapeIconStyle` | `CoreIconStyle?` | The glyph of a `CoreButtonShape.square` / `CoreButtonShape.circle` button — one with no label to sit beside, a step larger than the [leadingIconStyle] of the same size. Read in place of the size row's [leadingIconStyle] when the shape is not `rectangle`; what the instance states here outranks a slot statement ([iconSizeFor] holds the order). |

### `CoreButtonStyle` 변형별 기본값 (`CoreButtonVariantStyle`)

| 필드 | `primary` | `secondary` | `tonal` | `destructive` | `outline` | `ghost` | `plain` | `menu` | `menubar` | `fixed` |
|------|------|------|------|------|------|------|------|------|------|------|
| `backgroundColor` | primary | secondaryContainer | primaryContainer | errorContainer | surface | surfaceContainer (opacity 0) | transparent | surfaceContainerHighest (opacity 0, fallback: surfaceContainerHigh) | surfaceContainerHighest (opacity 0, fallback: surfaceContainerHigh) | transparent |
| `foregroundColor` | onPrimary | onSecondaryContainer | onPrimaryContainer | onErrorContainer | onSurface | onSurface | onSurfaceVariant | onSurface | onSurface | onSurface |
| `hoverBackgroundColor` | primaryHover | secondaryContainer | primaryContainer | error | surface | surfaceContainer (opacity 0) | transparent | surfaceContainerHighest (fallback: surfaceContainerHigh) | surfaceContainerHighest (fallback: surfaceContainerHigh) | transparent |
| `pressedBackgroundColor` | primaryPressed | — | — | errorPressed | — | — | — | — | — | — |
| `disabledBackgroundColor` | disabledContainer | disabledContainer | disabledContainer | disabledContainer | outline (opacity 0) | surfaceContainer (opacity 0) | transparent | transparent | transparent | transparent |
| `disabledForegroundColor` | disabledContent | disabledContent | disabledContent | disabledContent | disabledContent | disabledContent | disabledContent | disabledContent | disabledContent | disabledContent |
| `stateLayer` | — | subtle | subtle | — | subtle | subtle | — | — | — | — |
| `hoverForegroundColor` | — | — | — | onError | — | — | onSurface | onSurface | onSurface | — |
| `pressedForegroundColor` | — | — | — | onError | — | — | — | — | — | — |
| `borderColor` | — | — | — | — | outlineVariant | — | — | — | — | — |
| `hoverBorderColor` | — | — | — | — | outlineVariant | — | — | — | — | — |
| `disabledBorderColor` | — | — | — | — | disabledOutline | — | — | — | — | — |
| `borderWidth` | — | — | — | — | stroke1 | — | — | — | — | — |
| `paddingInline` | — | — | — | — | — | — | space0 | — | — | — |
| `iconColor` | — | — | — | — | — | — | — | onSurface | onSurface | — |
| `hoverIconColor` | — | — | — | — | — | — | — | onSurface | onSurface | — |
| `selectedBackgroundColor` | — | — | — | — | — | — | — | primary | surfaceContainerHigh | — |
| `selectedForegroundColor` | — | — | — | — | — | — | — | onPrimary | — | — |
| `focusedBackgroundColor` | — | — | — | — | — | — | — | surfaceContainerHighest (fallback: surfaceContainerHigh) | surfaceContainerHighest (fallback: surfaceContainerHigh) | — |
| `useSelectedState` | — | — | — | — | — | — | — | true | true | — |
| `useFocusedAsHover` | — | — | — | — | — | — | — | true | true | — |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="button/related-fab" title="FAB">

화면의 대표 행동을 떠 있는 버튼으로 둡니다.

</Card>
<Card demo="button/related-toggle" title="Toggle">

켜짐과 꺼짐처럼 상태가 있는 선택에 씁니다.

</Card>
<Card demo="button/related-menu" title="Menu">

여러 행동을 하나의 버튼 아래로 묶습니다.

</Card>
</Cards>
