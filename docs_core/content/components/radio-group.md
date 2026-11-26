---
title: RadioGroup
description: 펼쳐 둔 여러 선택지 중 하나만 고르게 하는 라디오 버튼 묶음입니다.
category: form
platforms: [flutter, web]
related: [checkbox, select, switch-field]
tags: [interactive, form-control, selection]
template: v2
source: form/radio_group
---

# RadioGroup

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

variant · 방향 · 크기를 바꿔 보며 라디오 묶음을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="radio-group" />

선택지는 `options`(값과 라벨의 목록)로 주는 것이 가장 짧습니다. 설명이 붙은 선택지나 직접 짠 배치가 필요하면 `child` 안에 `Radio` 를 넣습니다 — 그 `Radio` 는 묶음의 선택값 · 콜백 · 활성 여부 · variant · 크기 · `radioGroupStyle` 을 물려받습니다.

<a id="구조-anatomy"></a>

## 구조

라디오 묶음은 그룹과, 선택지마다 인디케이터 · 라벨 · 설명으로 이루어집니다.

<Anatomy demo="radio-group/anatomy">
<AnatomyItem part="container" name="Group">

선택지를 묶는 그룹. 이 안에서 하나만 고를 수 있습니다.

</AnatomyItem>
<AnatomyItem select="[role=radio]" side="left" name="indicator">

동그란 인디케이터. 고르면 링이 두꺼워지고 가운데가 비어 있습니다.

</AnatomyItem>
<AnatomyItem select=".flex-col > span:first-child" side="top" name="label">

선택지의 라벨.

</AnatomyItem>
<AnatomyItem select=".flex-col > span:last-child" side="right" name="description">

라벨 아래의 보조 문장. `child` 안의 `Radio(description:)` 로 줍니다.

</AnatomyItem>
</Anatomy>

선택은 점이 아니라 **링**이 나타냅니다 — 고른 링은 쉴 때보다 두껍고 가운데는 비어 있습니다. `Radio` 의 `prefix` 는 인디케이터 앞에 놓이는 위젯 슬롯이고, `suffix` 는 플랫폼마다 자리가 다릅니다 — Flutter 는 라벨을 대신하고, Jaspr Web 은 라벨 옆에 함께 그립니다.

<a id="변형-variants"></a>

## Variant

설명을 보고 고르는 선택지는 card 로, 그 밖에는 기본(defaultVariant)을 씁니다.

<VariantRow name="defaultVariant" component="radio-group" props="variant=defaultVariant;orientation=horizontal">

인디케이터와 라벨만 있는 한 줄 선택지입니다. 폼 안의 짧은 선택에 씁니다.

</VariantRow>

<VariantRow name="card" demo="radio-group/card">

선택지마다 인디케이터 · 제목 · 설명을 테두리 있는 타일 하나에 담습니다. 요금제나 배송 속도처럼 설명을 보고 고르는 선택에 씁니다.

</VariantRow>

<a id="카드-선택-타일"></a>

### card 타일

- 타일 전체가 누르는 영역입니다. hover · 눌림 표시는 타일 면 전체를 덮고, 포커스 링도 타일의 모서리를 따라 타일을 두릅니다.
- 선택은 인디케이터의 링이 나타내고, 타일은 면과 테두리로 한 번 더 알립니다 — 고르지 않은 타일은 `surface` 면에 `outlineVariant` 테두리 1, 고른 타일은 `primaryContainer` 면에 `primary` 테두리 2 입니다.
- 고른 타일의 굵어진 테두리는 안쪽으로 그려져, 골라도 내용의 자리와 타일 크기가 그대로입니다.
- 비활성 타일은 면과 테두리 두께를 그대로 두고, 테두리를 `disabledOutline` 으로, 글자를 비활성 색으로 바꿉니다.
- `options` 에는 설명을 넣을 자리가 없습니다. 설명이 붙은 타일은 `child` 에 `Radio(description:)` 을 넣어 만듭니다.

```dart
RadioGroup<String>(
  value: plan,
  onChanged: setPlan,
  variant: CoreRadioGroupVariant.card,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: CoreSpace.space8,
    children: const [
      Radio(value: 'basic', label: 'Basic', description: '개인 프로젝트용'),
      Radio(value: 'pro', label: 'Pro', description: '팀 협업과 우선 지원'),
    ],
  ),
)
```

Jaspr Web 에서는 `child` 에 `div([...], classes: 'flex flex-col gap-${CoreSpace.scale.space8}')` 처럼 Component 를 넘깁니다. `child` 로 타일을 넣으면 타일이 그룹 폭으로 늘어날지는 그 배치(위 예의 `stretch`)가 정합니다.

## 크기

인디케이터 12부터 24까지 6단계입니다. 링 두께, 인디케이터와 라벨 사이 간격, 선택지 사이 간격, 글자 크기가 함께 바뀝니다.

<SizeSpec component="radio-group" props="options=1" />

<Note>

쉬는 링의 두께는 모든 크기에서 1 로, Checkbox 의 꺼진 박스와 같은 선입니다. 고른 링의 두께는 크기마다 다르고, 링 안의 구멍은 인디케이터에서 고른 링 두께의 두 배를 뺀 만큼입니다. card 는 이 행 위에 타일 행을 덮습니다 — xs · sm · md 는 촘촘한 타일, lg 는 넉넉한 타일, xl · xl2 는 제목이 큰 타일이고, 인디케이터는 모든 크기에서 같은 크기입니다.

</Note>

<a id="동작-스펙-behavior"></a>
<a id="상태-전환"></a>
<a id="크기-사다리-defaultsbysize"></a>

## 상태

선택지마다 선택 여부와 `enabled` 가 모양을 정합니다.

<Preview demo="radio-group/states" />

| 항목 | 동작 |
| --- | --- |
| 고를 때 | 누른 선택지의 값으로 `onChanged` 를 부릅니다. 이미 고른 선택지를 다시 눌러도 해제되지 않습니다. |
| 선택 | 링이 `primary` 로 두꺼워지고 가운데는 비어 있습니다. 링 안은 쉴 때와 같은 채움(기본 투명)입니다. |
| Hover · 눌림 | 인디케이터 바깥으로 각 변 4만큼 나간 원에 `onSurface` 를 8% 로 깔고, 누르는 동안 16% 로 진하게 합니다. card 는 타일 면 전체에 깝니다. |
| Focus | 키보드 포커스가 닿으면 그 선택지가 곧바로 선택되고, 인디케이터 둘레에 링을 그립니다(card 는 타일 둘레). |
| 비활성 | 링 안 `disabledContainer`, 라벨 · 설명 `disabledContent`. 고르지 않은 링은 `disabledOutline` 의 쉬는 두께, 고른 링은 `disabledContent` 의 고른 두께라 비활성에서도 선택이 구분됩니다. |
| 전환 시간 | 링의 색 · 두께와 hover 표시가 100ms 동안 바뀝니다. 동작 줄이기를 켜면 바로 바뀝니다. |
| 활성 여부 | 그룹의 `enabled` 를 지정하지 않으면 `onChanged` 가 있을 때 활성입니다. 선택지는 자기 `enabled` 와 그룹의 활성이 모두 참일 때 활성입니다. |
| 정렬 | 선택지에 `description` 이 있으면 인디케이터를 라벨 첫 줄 위쪽에 맞춥니다. |

<a id="선택을-누가-들고-있는가-value-vs-initialvalue"></a>

### 선택을 누가 들고 있는가

| 방식 | 넘기는 것 | 선택을 들고 있는 곳 |
| --- | --- | --- |
| 호출자가 들고 있기 | `value` 와 `onChanged` | 호출자. `onChanged` 로 받은 값을 `value` 로 다시 넘겨야 화면이 바뀝니다. |
| 그룹이 들고 있기 | `initialValue` | 그룹 자신. 여기서 시작해 스스로 움직이고, `onChanged` 는 바뀐 값을 알리는 데만 씁니다. |

두 방식은 함께 쓰지 않습니다. `initialValue` 를 주면 그룹은 `value` 를 읽지 않습니다.

<Note>

그룹이 선택을 들고 있게 하면서 `onChanged` 를 생략하려면 `enabled: true` 를 함께 줍니다 — 활성 여부를 `onChanged` 유무로 정하기 때문입니다. `initialValue: null` 로는 이 방식이 켜지지 않아, 아무것도 고르지 않은 채 시작하는 그룹은 호출자가 선택을 들고 있어야 합니다.

</Note>

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 선택지가 많아 펼쳐 두면 화면을 너무 차지할 때 | [Select](/components/select) |
| 여러 개를 동시에 고를 때 | [Checkbox](/components/checkbox) |
| 켜고 끄는 두 값만 있을 때 | [SwitchField](/components/switch-field) |
| 선택지를 칩 모양으로 보여 줄 때 | [ChipGroup](/components/chip-group) |
| 고른 값에 따라 아래 화면을 바꿀 때 | [Tabs](/components/tabs) |

### 선택지 수

<Cards columns="2">
<Card component="radio-group" props="value=pro" tone="do" eyebrow="이렇게 하세요">

선택지를 모두 펼쳐 두고 한눈에 비교하게 합니다. 짧은 목록에 맞습니다.

</Card>
<Card demo="radio-group/dont-many" height="340" tone="dont" eyebrow="이렇게 하지 마세요">

선택지가 많으면 화면을 지나치게 차지하고 비교하기 어렵습니다. Select 를 씁니다.

</Card>
</Cards>

### 묶음의 이름

라디오 묶음이 어떤 질문에 답하는지는 묶음의 이름이 알려 줍니다. 화면에는 위에 제목을 두고, 스크린 리더에는 이름을 따로 붙입니다 — Jaspr Web 은 `RadioGroup(attributes: {'aria-label': '요금제'})`, Flutter 는 `Semantics(container: true, label: '요금제')` 로 감쌉니다. `Fieldset` 으로 묶어도 화면에서만 묶일 뿐, 스크린 리더에는 이름이 생기지 않습니다.

## 배치

선택지를 세로로 쌓을지, 가로로 늘어놓을지는 `orientation` 으로 고릅니다.

<Cards columns="2">
<Card component="radio-group" props="orientation=vertical" title="vertical">

기본 배치입니다. 라벨이 길거나 설명이 붙은 선택지에 씁니다.

</Card>
<Card component="radio-group" props="orientation=horizontal" title="horizontal">

라벨이 짧은 선택지(크기 · 단위)를 한 줄에 놓습니다. 폭이 모자라면 다음 줄로 넘어갑니다.

</Card>
</Cards>

## 그룹 밖에서 쓰기

선택지를 화면 곳곳에 따로 놓아야 할 때(목록 행 안의 라디오, 흩어진 카드형 선택지)는 `Radio` 를 그룹 없이 쓰고 선택값과 콜백을 직접 넘깁니다. 같은 `groupValue` 를 나누는 라디오들이 한 묶음처럼 움직입니다.

```dart
Radio<String>(
  value: 'pickup',
  groupValue: method,
  groupVariant: CoreRadioGroupVariant.card,
  label: '직접 받기',
  onChanged: setMethod,
)
```

그룹 밖의 라디오에는 화살표 이동이 없습니다. 그래서 선택 여부와 상관없이 라디오마다 `Tab` 으로 멈춥니다 — 고른 것만 남기면 고르지 않은 라디오에 키보드로 닿을 길이 없기 때문입니다. 그룹 밖에서는 `groupVariant` · `groupSize` 가 variant 와 크기를 정합니다(그룹 안에서는 읽지 않습니다).

<a id="스타일-시스템-style-system"></a>
<a id="스타일-시스템-radiogroupstyle"></a>

## 테마와 스타일

variant · 크기 · 방향은 위젯 속성으로 고르고, 인디케이터의 색과 두께, 간격, hover 표시, 글자, card 타일처럼 보이는 값은 `radioGroupStyle`(`CoreRadioGroupStyle`) 하나로 덮어씁니다.

<Split>

<Code language="dart" title="묶음 하나만 바꾸기">
RadioGroup(
  value: plan,
  onChanged: setPlan,
  options: plans,
  radioGroupStyle: CoreRadioGroupStyle(
    indicatorActiveColor: CoreColor.token(CoreColors.tertiary),
    itemSpacing: CoreSpace.space16,
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    radioGroup: CoreRadioGroupTheme(
      variantStyles: {
        CoreRadioGroupVariant.card: CoreRadioGroupStyle(
          tileSelectedBackgroundColor: CoreColor.token(CoreColors.surface),
        ),
      },
    ),
  ),
)
</Code>

</Split>

<Note>

인디케이터 색 필드가 실제로 바꾸는 것: `indicatorBorderColor` 는 고르지 않은 링의 색, `indicatorActiveColor` 는 고른 링의 색(점을 다시 켰을 때는 점의 색도), `indicatorBackgroundColor` 는 링 안의 채움(고른 · 고르지 않은 링 모두)입니다. 아래 필드 표의 설명보다 이 문장이 정확합니다.

</Note>

<a id="radiogroupstyle-슬롯"></a>

### 빠른 오버라이드 (Chain)

이미 만든 `RadioGroup` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `radioGroupStyle` 인자와 같게 동작합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class RadioGroupChainExample extends StatefulWidget {
  const RadioGroupChainExample({super.key});

  @override
  State<RadioGroupChainExample> createState() => _RadioGroupChainExampleState();
}

class _RadioGroupChainExampleState extends State<RadioGroupChainExample> {
  String? _selected = 'option1';

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      value: _selected,
      onChanged: (v) => setState(() => _selected = v),
      options: const [
        (value: 'option1', label: '옵션 1'),
        (value: 'option2', label: '옵션 2'),
        (value: 'option3', label: '옵션 3'),
      ],
    ).withStyle(
      const CoreRadioGroupStyle(
        indicatorActiveColor: CoreColor.token(CoreColors.tertiary),
        indicatorBorderColor: CoreColor.token(CoreColors.tertiary),
        indicatorBorderWidth: CoreStrokeWidth.stroke3,
        selectedIndicatorBorderWidth: CoreStrokeWidth.stroke6,
        indicatorSize: CoreSize.size24,
        itemSpacing: CoreSpace.space16,
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class RadioGroupChainExample extends StatefulComponent {
  const RadioGroupChainExample({super.key});

  @override
  State<RadioGroupChainExample> createState() => _RadioGroupChainExampleState();
}

class _RadioGroupChainExampleState extends State<RadioGroupChainExample> {
  String? _selected = 'option1';

  @override
  Component build(BuildContext context) {
    return RadioGroup(
      value: _selected,
      onChanged: (v) => setState(() => _selected = v),
      options: const [
        (value: 'option1', label: '옵션 1'),
        (value: 'option2', label: '옵션 2'),
        (value: 'option3', label: '옵션 3'),
      ],
    ).withStyle(
      const CoreRadioGroupStyle(
        indicatorActiveColor: CoreColor.token(CoreColors.tertiary),
        indicatorBorderColor: CoreColor.token(CoreColors.tertiary),
        indicatorBorderWidth: CoreStrokeWidth.stroke3,
        selectedIndicatorBorderWidth: CoreStrokeWidth.stroke6,
        indicatorSize: CoreSize.size24,
        itemSpacing: CoreSpace.space16,
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
기본값 (sizeDefaultsFor(variant, size) · defaultsByVariant[variant] · default*)
  → CoreComponentTheme.radioGroup.style                    // 앱 전체
  → CoreComponentTheme.radioGroup.variantStyles[variant]   // 앱 전체, variant 별
  → radioGroupStyle                                        // 인스턴스
```

뒤로 갈수록 우선합니다. 맨 아래의 크기 층은 `CoreRadioGroupStyle.sizeDefaultsFor(variant, size)` 한 곳이 정합니다 — 기본 variant 는 `defaultsBySize[size]`, card 는 그 위에 `cardDefaultsBySize[size]` 를 덮은 행입니다. 라벨과 설명 글자는 기본값 위에 크기 행이, 그 위에 테마와 인스턴스 값이 얹힙니다.

<a id="선택-카드-패딩을-별도로-지정하기"></a>

### 고른 card 의 안쪽 여백

고른 타일은 테두리가 두꺼워져도 높이와 내용의 자리를 지킵니다. 시안이 고른 상태에서 다른 안쪽 여백이나 바깥 크기를 요구할 때만 `tileSelectedPadding` 을 줍니다. 주면 그 값이 그대로 쓰여, 테두리 두께 차이만큼 고른 타일의 바깥 크기가 달라질 수 있습니다. 두 플랫폼이 같은 값을 쓰고 비활성 · 선택에도 같은 배치가 적용됩니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreRadioGroupStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `indicatorBackgroundColor` | `CoreColor?` | Indicator background fill colour override (idle / unselected). |
| `indicatorActiveColor` | `CoreColor?` | Indicator background fill colour when selected. |
| `indicatorBorderColor` | `CoreColor?` | Indicator border stroke colour override. |
| `indicatorBorderWidth` | `double?` | Indicator border stroke width override (logical px, pre-scaling) for the **resting** ring — unselected, and disabled-unselected. The selected ring (disabled or not) reads [selectedIndicatorBorderWidth], so restating only this field changes the resting ring and leaves the selected one on its size row. |
| `selectedIndicatorBorderWidth` | `double?` | Selected ring stroke width override (logical px, pre-scaling). The selection is carried by this ring — thicker than the resting one, with the hole left open — not by a dot. A disabled selected ring keeps this width (in the disabled-content colour). `null` defers to the size-keyed [defaultsBySize] entry, and a size whose entry states none draws the selected ring at the resting [indicatorBorderWidth]. |
| `indicatorSize` | `double?` | Indicator size (width = height) override (logical px). |
| `indicatorBorderRadius` | `CoreBorderRadius?` | Selection ring corner radius override. Falls back to [defaultIndicatorBorderRadius] (a full circle) when null. |
| `innerDotSize` | `double?` | Inner dot size override (logical px) — applied when the item is selected. Falls back to [defaultsBySize] when null, which states `0`: no dot is drawn by default, because the selected ring carries the selection ([selectedIndicatorBorderWidth]). |
| `indicatorLabelGapStyle` | `CoreGapStyle?` | Style of the `Gap` between the indicator and the item's label / prefix / suffix slot, in pre-scaling units (the `Gap` applies scaling itself). `null` defers to the size-keyed [defaultsBySize] entry. |
| `itemSpacing` | `double?` | Spacing between sibling radio items (logical px, pre-scaling) — `Wrap.spacing` / `Wrap.runSpacing` in a horizontal group, `Column.spacing` in a vertical one. Falls back to the size-keyed [defaultsBySize] entry when null. |
| `colorTransitionDuration` | `Duration?` | Indicator border / background colour transition duration override. Falls back to [defaultColorTransitionDuration] when null. |
| `dotTransitionDuration` | `Duration?` | Inner dot scale transition duration override. Falls back to [defaultDotTransitionDuration] when null. |
| `indicatorDotStyle` | `CoreIconStyle?` | Inner dot style (size / colour) when the item is selected. The dot is drawn as an icon, so this is a `CoreIconStyle`. `null` defers to [defaultIndicatorDotStyle]; whatever size or colour that leaves unset comes from [defaultsBySize] and the active fill colour. |
| `labelStyle` | `CoreTextStyle?` | Item label text style override. Text colour + typography role are both carried inside this slot; the per-size `fontSize` step comes from [defaultsBySize] underneath it. |
| `descriptionStyle` | `CoreTextStyle?` | Description text style override — the supporting line under the label. Merges over the size row's role (`defaultsBySize`) and [defaultDescriptionStyle]'s foreground, so a caller that states only a weight keeps both. Disabled reads the variant's disabled foreground. |
| `labelDescriptionGapStyle` | `CoreGapStyle?` | Style of the vertical gap between the label and the description below it. `null` defers to the size layer (the card rows set one), then to [defaultLabelDescriptionGapStyle]. |
| `stateLayer` | `CoreStateLayer?` | Ramp laid around the indicator while the row is hovered or pressed. Defaults to [defaultStateLayer]; the `focus` weight is not painted (see the default's doc). |
| `stateLayerColor` | `CoreColor?` | Ink of the halo. Defaults to [defaultStateLayerColor]. |
| `stateLayerSpread` | `double?` | How far the halo reaches past the indicator on each side (logical px, pre-scaling). Defaults to [defaultStateLayerSpread]. |
| `tilePadding` | `CoreEdgeInsets?` | Inset between the tile's border and its content (logical px, pre-scaling). `null` defers to [cardDefaultsBySize]. Read only by the `card` variant. |
| `tileSelectedPadding` | `CoreEdgeInsets?` | Padding inside the selected card's border, before scaling. `null` uses [tilePadding] minus the extra selected stroke, so the content stays where it sits at rest and the card keeps its outer size. Ignored by the plain variant. |
| `tileBorderRadius` | `CoreBorderRadius?` | Tile corner. `null` defers to [cardDefaultsBySize]. The focus ring around a focused tile follows this corner. Read only by the `card` variant. |
| `tileBorderWidth` | `double?` | Stroke width of an unselected tile (logical px, pre-scaling). `null` defers to [defaultTileBorderWidth]. It is also the width the tile's content is inset by in both states unless [tileSelectedPadding] is set. Read only by the `card` variant. |
| `tileSelectedBorderWidth` | `double?` | Stroke width of the selected tile (logical px, pre-scaling), disabled or not. `null` defers to [defaultTileSelectedBorderWidth]. The extra over [tileBorderWidth] is drawn inward and moves neither the content nor the tile's box unless [tileSelectedPadding] is set (see the default's doc). Read only by the `card` variant. |
| `tileBackgroundColor` | `CoreColor?` | Face of an unselected tile, disabled or not. `null` defers to [defaultTileBackgroundColor]. |
| `tileSelectedBackgroundColor` | `CoreColor?` | Face of the selected tile, disabled or not. `null` defers to [defaultTileSelectedBackgroundColor]. |
| `tileBorderColor` | `CoreColor?` | Border of an unselected tile. `null` defers to [defaultTileBorderColor]. A disabled tile reads the variant's `disabledBorderColor` instead, selected or not. |
| `tileSelectedBorderColor` | `CoreColor?` | Border of the selected tile. `null` defers to [defaultTileSelectedBorderColor]. A disabled selected tile reads the variant's `disabledBorderColor` instead. |

### `CoreRadioGroupStyle` 변형별 기본값 (`CoreRadioGroupVariantStyle`)

| 필드 | `defaultVariant` | `card` |
|------|------|------|
| `activeColor` | primary | primary |
| `borderColor` | outline | outline |
| `uncheckedBackground` | transparent | transparent |
| `disabledActiveColor` | disabledContent | disabledContent |
| `disabledBorderColor` | disabledOutline | disabledOutline |
| `disabledBackgroundColor` | disabledContainer | disabledContainer |
| `disabledForegroundColor` | disabledContent | disabledContent |

<!-- STYLE_TABLE:END -->

<a id="접근성-accessibility"></a>

## 접근성

Flutter 는 선택지마다 상호 배타 묶음의 체크 상태를, Jaspr Web 은 `role="radiogroup"` 과 `role="radio"` 를 알립니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 선택지마다 `Semantics(checked:, inMutuallyExclusiveGroup: true)` 로 선택 여부와 상호 배타 묶음을 알립니다. 그룹은 이름 없는 경계 하나만 만들고 그룹 역할은 알리지 않습니다. `initialValue` · `controller` 를 쓰면 그 경계도 없습니다. |
| Jaspr Web | 그룹에 `role="radiogroup"`(비활성이면 `aria-disabled="true"`), 선택지의 동그란 인디케이터에 `role="radio"` · `aria-checked` · `tabindex` 가 붙고, 비활성 선택지에는 `aria-disabled="true"` 가 더해집니다. 포커스를 받는 것은 인디케이터입니다. |

폼 이름(`name`)을 주면 Jaspr Web 은 선택지마다 폼 제출용 숨은 `<input type="radio">` 를 그립니다. 이 입력은 `aria-hidden="true"` · `tabindex="-1"` 이라 스크린 리더에도 Tab 순서에도 나타나지 않습니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` | 그룹의 고른 선택지 하나에서만 멈춥니다. 아무것도 고르지 않았으면 첫 선택지(`Shift` · `Tab` 이면 마지막)에 놓이고, 그 선택지가 곧바로 선택됩니다. |
| `↓` · `→` | 다음 선택지로 포커스를 옮기고 그 선택지를 고릅니다. 끝에서는 처음으로 돌아갑니다. |
| `↑` · `←` | 이전 선택지로 포커스를 옮기고 그 선택지를 고릅니다. 처음에서는 끝으로 돌아갑니다. |
| `Space` · `Enter` | 포커스된 선택지를 고릅니다. |

키보드 포커스가 선택지에 닿으면 그 선택지가 곧바로 선택됩니다(포커스를 따라 선택). 네 화살표는 `orientation` 과 상관없이 같게 동작합니다. `Home` · `End` · `Escape` 는 처리하지 않습니다. 비활성 선택지는 `Tab` 이 건너뜁니다.

### 스크린 리더

| 플랫폼 | 읽히는 것 |
| --- | --- |
| Flutter | 선택지 안의 글자 — `label`(또는 `suffix`), `description`, `prefix` · `suffix` 의 글자 — 가 그 선택지의 이름으로 합쳐져 읽힙니다. 선택 여부와 비활성도 알립니다. |
| Jaspr Web | 선택지마다 라디오 역할과 선택 여부를 읽지만, `label` 이 그 선택지의 **이름이 되지 않습니다**(알려진 제약). 설명도 선택지에 연결되지 않습니다. |

묶음의 이름은 Jaspr Web 에서 `attributes` 로 넣지 않는 한 두 플랫폼 모두 비어 있습니다(사용 가이드의 "묶음의 이름"). 선택이 바뀐 사실을 따로 알리는 라이브 리전은 없습니다.

### 포커스 관리

마운트될 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. `Tab` 은 그룹 밖으로 그대로 나가고, 화살표만 그룹 안에서 돕니다. 포커스 링은 키보드로 포커스한 선택지가 선택돼 있을 때만 나타납니다 — 일반 선택지는 인디케이터 둘레의 원형 링, card 는 타일 모서리를 따른 링입니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | `label` 을 준 선택지는 그 라벨이 `role="radio"` 의 이름이 되지 않습니다. 라벨 · 설명 · 폼 이름 · 슬롯이 있거나 card 면 `Radio(attributes: {'aria-label': ...})` 도 인디케이터가 아니라 바깥 `<label>` 에 실려, 보이는 라벨을 둔 채 이름을 붙일 방법이 없습니다. |
| Flutter | 그룹에 이름을 붙이는 속성이 없고, 그룹 역할도 알리지 않습니다. 호출자가 `Semantics(container: true, label:)` 로 감싸야 합니다. |
| Flutter | 화살표가 비활성 선택지를 건너뛰지 않습니다. 다음 선택지가 비활성이면 포커스가 그 자리에 멈추고, 반대 방향으로 돌아야 닿습니다. Jaspr Web 은 건너뜁니다. |
| 공통 | 고른 선택지가 비활성이거나 `value` 가 어느 선택지와도 맞지 않으면 그룹에 `Tab` 으로 들어갈 수 없습니다. |
| 공통 | 선택이 포커스를 따라가지 않는 경우(호출자가 `onChanged` 를 반영하지 않을 때) 포커스된 선택지에 아무 표시도 없습니다. |
| Jaspr Web | `child` · `suffix` 안에 입력창을 넣으면 그 입력창의 화살표 키도 라디오 이동으로 가져갑니다. |
| Flutter | 비활성 선택지에 반투명이 한 번 더 걸려, Jaspr Web 보다 옅게(대비가 낮게) 그려집니다. |
| Flutter | `initialValue` · `controller` 로 쓰면 고른 값이 폼에 전달되지 않습니다. |
| 공통 | 라벨 없는 라디오를 나란히 놓을 때 인디케이터 크기와 이웃 인디케이터까지의 간격을 더한 값이 24 보다 작으면, 이웃 선택지의 누르는 영역이 겹칩니다 — 누르는 영역이 인디케이터 가운데에서 24 로 넓어지기 때문입니다. `xs`(12) 는 12, `sm`(14) 은 10, `md`(16) 는 8 이상 띄우세요. 라벨 없는 라디오는 `child` 나 그룹 밖에서 직접 늘어놓으므로 이 간격은 그 배치가 정합니다. |
| Flutter | 그룹의 `name` · `focusNode` · `statesController` 는 받지만 아직 아무 일도 하지 않습니다. 포커스는 선택지마다 `Radio(focusNode:)` 로 다룹니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>
<a id="레거시-vs-통일-비교-migration-notes"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 값 타입 | `RadioGroup<T>` · `Radio<T>` — 어떤 타입이든 | `String` 만 |
| 그룹 역할 | 이름 없는 경계만 | `role="radiogroup"` |
| 선택지 이름 | 선택지 안의 글자가 이름이 됩니다 | 이름이 없습니다 |
| 그룹 이름을 붙이는 법 | 호출자가 `Semantics` 로 감쌉니다 | `attributes` 의 `aria-label` |
| `suffix` | 라벨을 대신합니다 | 라벨 옆에 함께 그립니다 |
| 화살표와 비활성 선택지 | 비활성 앞에서 멈춥니다 | 비활성을 건너뜁니다 |
| 마우스로 눌렀을 때 포커스 | 옮기지 않습니다 | 인디케이터(둘레의 누르는 영역 포함)를 누를 때만 인디케이터로 옮깁니다 — 링과 자동 선택은 없습니다. 라벨 글자나 card 타일 면을 누르면 인디케이터로 옮겨지지 않습니다 |
| 폼 값 | `FormValueSupplier`. `name` 은 쓰지 않습니다 | `FormValueSupplier` 와, 폼 이름이 있으면 숨은 `<input type="radio">` |
| 이미 고른 선택지를 다시 누를 때 | `value` 로 쓰면 `onChanged` 를 부르지 않습니다 | 같은 값으로 다시 부릅니다 |
| 비활성 모양 | 비활성 색 위에 반투명이 더 걸립니다 | 비활성 색만 |
| 고른 card 의 굵은 테두리 | 실제 테두리를 그리고 차이만큼 여백을 줄입니다 | 테두리는 쉬는 두께로 두고 차이를 안쪽 그림자로 칠합니다 |
| 포커스 · 상태 제어 | `Radio.focusNode`, 그룹의 `controller` | 브라우저 포커스와 CSS 상태 |

<a id="props-parameters"></a>
<a id="radio-아이템-파라미터"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. 값 타입 `T` 는 Jaspr Web 에서 `String` 입니다.

### RadioGroup — 값과 선택지

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `T?` | `null` | 고른 값. 호출자가 선택을 들고 있을 때 씁니다. |
| `initialValue` | `T?` | `null` | 처음 고른 값. 주면 그룹이 선택을 들고 있고 `value` 는 읽지 않습니다. |
| `onChanged` | `ValueChanged<T?>?` | `null` | 고른 값을 받습니다. |
| `options` | `List<({T value, String label})>?` | `null` | 선택지 목록. `child` 와 둘 중 하나는 줘야 합니다. |
| `child` | `Widget?` | `null` | 직접 짠 배치. 안에 `Radio` 를 넣습니다. `options` 보다 우선합니다. |

### RadioGroup — 상태와 형태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `enabled` | `bool?` | `null` | 지정하지 않으면 `onChanged` 유무로 정합니다. |
| `variant` | `CoreRadioGroupVariant` | `defaultVariant` | defaultVariant, card |
| `size` | `CoreComponentSize` | `md` | 인디케이터 · 간격 · 글자 크기 |
| `orientation` | `CoreRadioGroupOrientation` | `vertical` | vertical, horizontal |
| `radioGroupStyle` | `CoreRadioGroupStyle?` | `null` | 보이는 값 덮어쓰기 |
| `name` | `String?` | `null` | 폼 제출 이름 (Web 만 숨은 입력으로 씁니다) |

### Radio — 선택지 하나

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `T` | 필수 | 이 선택지의 값 |
| `label` | `String?` | `null` | 라벨 |
| `labelMaxLines` | `int?` | `null` | 라벨의 최대 줄 수. 지정하지 않으면 제한하지 않습니다. |
| `labelOverflow` | `CoreTextOverflow?` | `null` | 최대 줄 수를 넘긴 라벨의 처리 |
| `description` | `String?` | `null` | 라벨 아래 보조 문장 |
| `prefix` | `Widget?` | `null` | 인디케이터 앞 슬롯 |
| `suffix` | `Widget?` | `null` | Flutter 는 라벨 자리, Web 은 라벨 옆 |
| `enabled` | `bool` | `true` | 이 선택지의 활성 여부. 그룹이 비활성이면 함께 비활성입니다. |
| `groupValue` | `T?` | `null` | 그룹 밖에서 쓸 때의 선택값. 그룹 안에서 비우면 그룹의 값 |
| `onChanged` | `ValueChanged<T?>?` | `null` | 그룹 밖에서 쓸 때의 콜백. 그룹 안에서 비우면 그룹의 콜백 |
| `groupVariant` | `CoreRadioGroupVariant` | `defaultVariant` | 그룹 밖에서 쓸 때의 variant |
| `groupSize` | `CoreComponentSize` | `md` | 그룹 밖에서 쓸 때의 크기 |

### 플랫폼 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `controller` | `RadioGroupController<T?>?` | `null` | Flutter 전용. 선택을 바깥에서 다룰 때 |
| `focusNode` | `FocusNode?` | `null` | Flutter 전용. `Radio` 에 주면 그 선택지의 포커스를 다룹니다(그룹의 것은 쓰이지 않습니다). |
| `statesController` | `WidgetStatesController?` | `null` | Flutter 전용. 그룹에 있지만 쓰이지 않습니다. |
| `attributes` | `Map<String, String>?` | `null` | Web 전용. `RadioGroup` 에 주면 그룹에(그룹 이름 `aria-label` 등), `Radio` 에 주면 그 선택지에 붙습니다 — 라벨 · 설명 · 폼 이름 · 슬롯이 있거나 card 면 인디케이터가 아니라 바깥 `<label>` 에 붙습니다. |
| `name` | `String?` | `null` | Web 전용 `Radio`. 이 선택지의 숨은 입력에 쓰는 폼 이름. 비우면 그룹의 `name` 을 씁니다. |
| `group` | `ResolvedRadioGroup?` | `null` | Web 전용 `Radio`. 미리 계산한 묶음의 스타일을 넘깁니다. |

<a id="관련-컴포넌트-related-components"></a>
<a id="조합-예제"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card component="checkbox" props="checked=true" label="알림 받기" title="Checkbox">

여러 항목을 동시에 고를 때 씁니다.

</Card>
<Card component="select" props="placeholder=선택하세요" title="Select">

선택지가 많을 때 펼침 목록에서 하나를 고릅니다.

</Card>
<Card demo="radio-group/related-switch-field" title="SwitchField">

켜고 끄는 두 값만 있는 설정에 씁니다.

</Card>
</Cards>
