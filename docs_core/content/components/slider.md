---
title: Slider
description: 범위 안에서 값 하나를 끌어서 고르는 슬라이더입니다. 볼륨 · 밝기처럼 상대적인 위치가 중요한 값에 씁니다.
category: form
platforms: [flutter, web]
related: [range, number-input, progress]
tags: [form-control, range, interactive]
template: v2
source: form/slider
---

# Slider

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

값과 슬롯을 바꿔 보며 슬라이더를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="slider" />

슬라이더는 `min` 과 `max` 사이의 값 하나를 고릅니다. 값을 스스로 바꾸지 않으므로, `onChanged` 로 받은 값을 호출자가 `value` 로 다시 넘겨야 놓은 뒤에도 썸이 그 자리에 남습니다. `onChanged` 를 주지 않으면 값을 보여 주기만 합니다.

## 구조

슬라이더는 트랙, 지금 값까지 채운 부분, 끌어 움직이는 썸, 그리고 선택 사항인 앞 · 뒤 슬롯으로 이루어집니다. 포커스와 키는 Jaspr Web 에서는 슬롯까지 감싼 바깥 상자가, Flutter 에서는 슬롯을 뺀 트랙 부분이 받습니다.

<Anatomy demo="slider/anatomy">
<AnatomyItem part="container" name="Container">

한 줄 전체. 앞 슬롯 · 트랙 · 뒤 슬롯을 가로로 놓습니다.

</AnatomyItem>
<AnatomyItem part="leading" side="top" name="leading">

트랙 앞의 위젯 슬롯. 눌러도 값이 바뀌지 않습니다.

</AnatomyItem>
<AnatomyItem select="[data-coui-slider-track] > div:first-child" side="top" name="track">

값의 범위 전체를 나타내는 막대. 아무 곳이나 누르면 썸이 그 자리로 옵니다.

</AnatomyItem>
<AnatomyItem select="[data-coui-slider-track] > div:first-child > div" side="top" name="fill">

`min` 부터 지금 값까지 채운 부분. 썸의 가운데까지 `activeColor` 로 칠합니다.

</AnatomyItem>
<AnatomyItem select="[data-coui-slider-track] > div:last-child > div" side="top" name="thumb">

끌어 움직이는 손잡이. 가장자리가 트랙 끝에서 멈추므로 `min` · `max` 에서도 트랙 밖으로 나가지 않습니다. 키보드 포커스 링이 이 둘레에 그려집니다.

</AnatomyItem>
<AnatomyItem part="trailing" side="top" name="trailing">

트랙 뒤의 위젯 슬롯. 지금 값이나 단위를 보여 주는 데도 씁니다.

</AnatomyItem>
</Anatomy>

### 기본 치수

| 항목 | 기본값 | 토큰 |
| --- | --- | --- |
| 트랙 높이 | 4 | `CoreSpace.space4` |
| 썸 크기 | 16 | `CoreSpace.space16` |
| 썸 테두리 | 1 | `CoreStrokeWidth.stroke1` |
| 모서리 | 알약(완전히 둥긂) | `CoreRadius.radius9999` |
| 위아래 여백 | 8 | `CoreSpace.space8` |
| 썸 그림자 | 가장 작은 단계 | `CoreShadow.xs` |
| 트랙과 슬롯 사이 | 12 | `CoreSpace.space12` |

기본 밀도에서 슬라이더 한 줄의 높이는 썸 크기에 위아래 여백을 더한 32 입니다. 위아래 여백과 트랙 · 슬롯 사이 간격은 밀도를 따라 움직이고, 트랙 · 썸 크기는 움직이지 않습니다. Slider 에는 크기(`size`) 축이 없습니다 — 트랙과 썸의 크기는 `sliderStyle` 의 `trackHeight` · `thumbSize` 로 바꿉니다.

<a id="변형-variants"></a>
<a id="값-제어"></a>

## 값과 단계

기본 범위는 0 ~ 100 입니다. `value` · `min` · `max` · `step` 은 모두 사용자가 고르는 값의 단위이고, 트랙 길이(화면의 픽셀)와는 상관이 없습니다.

```dart
Slider(
  value: volume,
  onChanged: (value) => setState(() => volume = value),
)
```

- 값은 호출자가 가집니다. 슬라이더는 `value` 를 그리고, 바뀐 값은 `onChanged` 로 알리기만 합니다.
- `value` 가 `min` · `max` 밖이면 썸은 가까운 끝에 그려집니다.
- 슬라이더는 값 하나만 고릅니다. 손잡이가 둘인 구간 선택은 [Range](/components/range) 를 씁니다.

<a id="divisions-step-스냅"></a>
<a id="단계-지정"></a>
<a id="step-지정"></a>

### 단계에 맞추기

고를 수 있는 값이 정해져 있으면 `divisions` 나 `step` 을 줘 포인터로 고른 값을 그 단계에 맞춥니다.

```dart
// 16 ~ 30 도를 1 도씩
Slider(value: temperature, min: 16, max: 30, divisions: 14, onChanged: setTemperature)

// 0 ~ 500,000 원을 10,000 원씩
Slider(value: price, max: 500000, step: 10000, onChanged: setPrice)
```

| 항목 | 동작 |
| --- | --- |
| `divisions` | `min` ~ `max` 를 같은 간격의 칸으로 나누고, 포인터로 고른 값을 가장 가까운 칸에 맞춥니다. |
| `step` | 포인터로 고른 값을 `step` 의 배수에 맞춥니다. 배수는 0 부터 셉니다 — `min` 이 `step` 의 배수가 아니면 `min` 다음 칸이 `min + step` 이 아닙니다(`min: 16, step: 3` 이면 16, 18, 21, …). |
| 둘 다 줄 때 | `divisions` 칸에 맞춘 뒤 다시 `step` 의 배수에 맞춥니다. |
| 둘 다 없을 때 | 맞추지 않습니다. 포인터 자리 그대로의 값입니다. |
| 키 한 번의 크기 | `step` → `(max - min) / divisions` → 범위의 1% 순으로 정합니다. `PageUp` · `PageDown` 은 그 10배입니다. |
| 키로 옮길 때 | 지금 `value` 에 한 번만큼 더하고 `min` · `max` 로 자를 뿐, 칸에 다시 맞추지 않습니다. `value` 가 칸 위에 있지 않으면 키로 옮긴 값도 칸 사이에 놓입니다. |

<Note>

칸 눈금이나 눈금 글자는 그리지 않습니다. `divisions` 를 주어도 트랙은 그대로이므로, 지금 값을 슬롯에 함께 보여 줍니다(사용 가이드 참고).

</Note>

<a id="드래그-인터랙션"></a>

### 누르고 끌기

- 트랙 아무 곳이나 누르면 썸이 그 자리로 오고, 이어서 끌 수 있습니다. 포인터는 썸의 가운데로 읽힙니다 — 썸의 가장자리가 트랙 끝에서 멈추므로, 트랙 양 끝에서 썸 반 폭 안쪽은 `min` · `max` 입니다.
- 끄는 동안에는 슬라이더가 포인터 자리에 썸을 먼저 그립니다. 놓으면 `value` 자리로 돌아가므로, 호출자가 받은 값을 `value` 로 넘겨야 그 자리에 남습니다.
- 끌기를 시작하면 그때의 `value` 로 `onChangeStart` 를, 끝나면 마지막 값으로 `onChangeEnd` 를 부릅니다. 브라우저나 OS 가 끌기를 중간에 거둬도 `onChangeEnd` 를 부릅니다. 누르기만 하고 끌지 않을 때는 플랫폼마다 다릅니다(플랫폼 차이 참고).
- Jaspr Web 은 누르는 순간 `onChangeStart` 를 불러 늘 누르기 전의 값을 넘깁니다. Flutter 는 누른 채 잠깐(100ms) 멈췄다가 끌면 누른 자리의 값으로 `onChanged` 가 먼저 불리므로, 호출자가 그 값을 `value` 로 넘긴 뒤라면 `onChangeStart` 가 받는 값은 누른 자리의 값입니다.
- 끄는 도중 슬라이더가 비활성이 되거나 `onChanged` 가 사라지면 끌기가 끝나고, 이때는 `onChangeEnd` 를 부르지 않습니다. Jaspr Web 은 끄는 도중 `min` · `max` 가 바뀌어도 그렇습니다.
- 앞 · 뒤 슬롯을 누르면 값이 바뀌지 않습니다.

<a id="동작-스펙-behavior"></a>
<a id="포커스-링"></a>

## 상태

슬라이더에는 variant 가 없습니다. `enabled` 와 `onChanged` 가 모양과 입력을 정합니다.

<Preview demo="slider/states" />

| 항목 | 동작 |
| --- | --- |
| 쉴 때 | 트랙 `surfaceContainerHigh`, 채움 `primary`, 썸 `surfaceBright` 에 테두리 `outlineVariant`(1)와 그림자 `CoreShadow.xs`. |
| Hover · 눌림 | 색은 바뀌지 않고 커서만 손 모양이 됩니다. |
| 끄는 동안 | 썸과 채움이 포인터를 따라갑니다(누르고 끌기 참고). |
| Focus | 키보드로 포커스했을 때만 **썸** 둘레에 `primary` 링을 그립니다 — 썸에서 2만큼 비운 뒤 2 두께의 알약 모양 링이고, 150ms 동안 나타납니다. 포인터로 잡으면 포커스는 받지만 링은 숨기고, 그 뒤 키를 누르면 링이 나타납니다. |
| 비활성 (`enabled: false`) | 트랙 `surfaceContainer`, 채움 `outlineVariant`, 썸 `disabledContainer` 에 테두리 `disabledOutline`. 투명도를 곱하지 않고 전용 색을 씁니다. 포커스 · 포인터 · 키를 받지 않습니다. |
| 보여 주기만 할 때 (`onChanged: null`) | 쉴 때의 색 그대로이고, 포커스 · 포인터 · 키를 받지 않습니다. |
| 값이 바뀔 때 | 썸과 채움이 바로 옮겨집니다. 전환 애니메이션은 없습니다. |
| 누르는 영역 | Flutter 는 썸 높이(16)의 줄을 위아래로 넓혀 24 높이까지 받습니다. Jaspr Web 은 썸 높이의 트랙 상자 안에서만 받습니다(알려진 제약 참고). |

<Note>

`surfaceContainer` 는 비활성 트랙과 같은 색입니다. 그 색으로 채운 면(네이티브 문서 앱의 무대가 그렇습니다) 위에 비활성 슬라이더를 두면 트랙이 묻혀 채움과 썸만 보입니다.

</Note>

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

볼륨 · 밝기처럼 정확한 숫자보다 상대적인 위치가 중요한 값 하나를 조절할 때 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 최솟값과 최댓값을 함께 고를 때 | [Range](/components/range) |
| 정확한 숫자를 입력해야 할 때 | [NumberInput](/components/number-input) · [TextField](/components/text-field) |
| 셋 이상의 값이 얽힌 입력 | 값마다 따로 둔 [NumberInput](/components/number-input) |
| 조작 없이 진행 정도만 보여 줄 때 | [Progress](/components/progress) |
| 별 모양 점수를 매길 때 | [StarRating](/components/star-rating) |
| 정해진 선택지 중 하나를 고를 때 | [Select](/components/select) · [RadioGroup](/components/radio-group) |

<a id="do"></a>
<a id="dont"></a>

### 이름과 지금 값

<Cards columns="2">
<Card demo="slider/value-label" tone="do" eyebrow="이렇게 하세요">

무엇을 조절하는지 이름을 붙이고, 지금 값을 뒤 슬롯에 보입니다. 눈금이 그려지지 않아도 어느 값인지 바로 읽힙니다.

</Card>
<Card component="slider" props="value=60" tone="dont" eyebrow="이렇게 하지 마세요">

이름도 값도 없으면 무엇을 얼마나 조절하는지 알 수 없습니다. 슬라이더는 스스로 이름을 붙이지 않아, 화면의 글자가 유일한 단서입니다.

</Card>
<Card demo="slider/with-number-input" tone="do" eyebrow="이렇게 하세요">

정확한 값도 필요하면 숫자 입력을 함께 둡니다. 슬라이더로 대략 맞추고 숫자로 고칩니다.

</Card>
<Card component="slider" props="value=350000;max=1000000" tone="dont" eyebrow="이렇게 하지 마세요">

범위가 넓은데 정확한 값을 슬라이더만으로 고르게 하지 않습니다. 트랙의 한 픽셀이 수천 단위를 건너뜁니다.

</Card>
</Cards>

### 구간 고르기

<Cards columns="2">
<Card demo="slider/two-sliders" tone="dont" eyebrow="이렇게 하지 마세요">

구간을 슬라이더 두 개로 만들지 않습니다. 두 슬라이더는 서로를 모르므로 최솟값이 최댓값보다 커질 수 있습니다.

</Card>
<Card demo="slider/related-range" tone="do" eyebrow="대신 이렇게 하세요">

최솟값과 최댓값은 Range 하나로 고릅니다. 한 손잡이가 다른 손잡이를 넘지 않습니다.

</Card>
</Cards>

## 배치

### 폭

슬라이더는 받은 가로 폭을 채웁니다. Flutter 에서 가로 폭이 정해지지 않은 자리(`Row` 의 자식)에 바로 두면 그릴 폭이 없으므로 `Expanded` 나 `SizedBox` 로 폭을 줍니다. Jaspr Web 은 부모 폭의 100% 를 씁니다.

```dart
Row(
  spacing: CoreSpace.space12,
  children: [
    Expanded(
      child: Slider(value: temperature, min: 16, max: 30, divisions: 14, onChanged: setTemperature),
    ),
    NumberInput(value: temperature, min: 16, max: 30, onChanged: setTemperature),
  ],
)
```

### 앞 · 뒤 슬롯

`leading` 은 트랙 앞, `trailing` 은 트랙 뒤에 위젯을 그립니다 — 줄이기 · 늘리기 아이콘이나 범위 끝의 글자, 지금 값 같은 것입니다.

<Preview demo="slider/slots" />

```dart
Slider(
  value: volume,
  onChanged: setVolume,
  leading: Icon(LucideIcons.minus),
  trailing: Icon(LucideIcons.plus),
)
```

- 슬롯이 `null` 이면 아무것도 그리지 않고 간격도 없습니다 — 슬롯 없는 슬라이더의 배치는 그대로입니다.
- 트랙과 슬롯 사이는 `sliderStyle.slotGapStyle`(기본 12)입니다. 슬롯은 줄의 가운데에 맞춥니다.
- 포인터는 트랙 위에서만 값으로 바뀝니다. 슬롯을 눌러도 값이 바뀌지 않습니다.
- 슬롯의 글자는 `Text(...)` 체인으로 스타일을 줍니다. Flutter 는 슬라이더 전체를 `tickLabelStyle`(기본 `labelLarge`)로 감싸 스타일 없는 글자가 그 역할을 따르고, Jaspr Web 은 `tickLabelStyle` 을 줄 때만 그 값을 바깥 상자에 실어 슬롯 글자에 물려줍니다.
- 썸(16)보다 큰 슬롯을 두면 Jaspr Web 의 줄이 더 높아집니다. Web 은 위아래 여백 8 을 슬롯까지 감싼 바깥 상자에 두고, Flutter 는 트랙 쪽에만 둡니다 — 기본 밀도에서 24 아이콘을 두면 Flutter 는 32, Web 은 40 입니다.

<a id="스타일-시스템-style-system"></a>
<a id="스타일-시스템-sliderstyle"></a>
<a id="sliderstyle-슬롯"></a>

## 테마와 스타일

Slider 에는 variant 와 크기 축이 없습니다. 트랙 · 채움 · 썸의 색과 크기, 모서리, 포커스 링, 슬롯 간격처럼 보이는 값은 `sliderStyle`(`CoreSliderStyle`) 하나로 덮어씁니다.

<Split>

<Code language="dart" title="슬라이더 하나만 바꾸기">
Slider(
  value: volume,
  onChanged: setVolume,
  sliderStyle: CoreSliderStyle(
    activeColor: CoreColor.token(CoreColors.tertiary),
    trackHeight: CoreSpace.space6,
    thumbSize: CoreSpace.space20,
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    slider: CoreSliderTheme(
      style: CoreSliderStyle(
        activeColor: CoreColor.token(CoreColors.tertiary),
      ),
    ),
  ),
)
</Code>

</Split>

<Note>

- `thumbBorderColor` 를 비운 채 `activeColor` 를 주면 썸 테두리도 그 색이 됩니다(둘 다 비우면 `outlineVariant`). 기본 테두리를 지키려면 `thumbBorderColor` 를 함께 줍니다.
- 비활성일 때는 `disabledTrackColor` · `disabledActiveColor` · `disabledThumbColor` · `disabledThumbBorderColor` 만 읽습니다. 활성 색을 바꿔도 비활성 모양은 그대로입니다.
- `borderRadius` 하나가 트랙 · 채움 · 썸의 모서리를 함께 정합니다. 각지게 하면 썸도 네모가 됩니다.
- 포커스 링의 모서리는 `borderRadius` 를 따르지 않고 기본 알약 모양 그대로입니다. 썸을 각지게 할 때는 `focusOutlineStyle` 의 `borderRadius` 도 함께 줍니다.

</Note>

### 빠른 오버라이드 (Chain)

이미 만든 `Slider` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `sliderStyle` 인자와 같게 동작합니다. `.radius4` 처럼 Core 토큰 상수와 같은 이름의 getter 는 `borderRadius` 를 그 값으로 바꾸는 짧은 형태입니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class SliderChainExample extends StatefulWidget {
  const SliderChainExample({super.key});

  @override
  State<SliderChainExample> createState() => _SliderChainExampleState();
}

class _SliderChainExampleState extends State<SliderChainExample> {
  double _value = 50;

  @override
  Widget build(BuildContext context) {
    return Slider(
          value: _value,
          min: 0,
          max: 100,
          onChanged: (v) => setState(() => _value = v),
        )
        .withStyle(
          const CoreSliderStyle(
            trackHeight: CoreSpace.space12,
            thumbSize: CoreSpace.space24,
            activeColor: CoreColor.token(CoreColors.tertiary),
          ),
        )
        .radius16;
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class SliderChainExample extends StatefulComponent {
  const SliderChainExample({super.key});

  @override
  State<SliderChainExample> createState() => _SliderChainExampleState();
}

class _SliderChainExampleState extends State<SliderChainExample> {
  double _value = 50;

  @override
  Component build(BuildContext context) {
    return Slider(
          value: _value,
          min: 0,
          max: 100,
          onChanged: (v) => setState(() => _value = v),
        )
        .withStyle(
          const CoreSliderStyle(
            trackHeight: CoreSpace.space12,
            thumbSize: CoreSpace.space24,
            activeColor: CoreColor.token(CoreColors.tertiary),
          ),
        )
        .radius16;
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
기본값 (default*)
  → CoreComponentTheme.slider.style   // 앱 전체
  → sliderStyle                       // 인스턴스
```

뒤로 갈수록 우선합니다. `slotGapStyle` 과 `focusOutlineStyle` 은 기본값 위에 필드별로 합쳐져 간격(`Gap`)과 포커스 링(`FocusOutline`)에 그대로 넘어가고, 비운 필드는 그 부품의 기본값을 씁니다. `tickLabelStyle` 도 필드별로 합쳐지며, Flutter 는 그 아래에 기본값 `labelLarge` 를 깔고 Jaspr Web 은 깔지 않습니다.

<a id="접근성-accessibility"></a>

## 접근성

Flutter 는 `Semantics(slider: true, value:)` 로, Jaspr Web 은 `role="slider"` 와 `aria-valuenow` 같은 속성으로 슬라이더와 지금 값을 알립니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | `Semantics(slider: true, value: '<현재 값>')` 로 슬라이더임과 지금 값을 알립니다. 이름 · 최소 · 최댓값 · 비활성 표시는 싣지 않습니다. |
| Jaspr Web | 바깥 `<div>` 에 `role="slider"` 와 `aria-valuemin` · `aria-valuemax` · `aria-valuenow` 를 직접 붙입니다(네이티브 `<input type="range">` 가 아닙니다). `enabled: false` 면 `aria-disabled="true"` 가 붙고, `enabled: true` 이면서 `onChanged` 가 있을 때만 `tabindex="0"` 이 붙습니다. |

슬라이더는 이름을 붙이지 않습니다 — `aria-label` 도 `Semantics(label:)` 도 설정하지 않습니다.

### 키보드

`enabled: true` 이면서 `onChanged` 가 있을 때만 포커스를 받고 아래 키가 동작합니다. 수정 키 없이 누를 때 두 플랫폼이 같은 키를 처리합니다. Flutter 는 `Shift` · `Ctrl` · `Alt` · `Meta` 를 함께 누르면 처리하지 않고, Jaspr Web 은 함께 눌러도 같은 동작을 하며 그 키의 기본 동작을 막습니다.

| 키 | 동작 |
| --- | --- |
| `→` · `↑` | 한 번만큼 올립니다. |
| `←` · `↓` | 한 번만큼 내립니다. |
| `PageUp` · `PageDown` | 10번만큼 올리거나 내립니다. |
| `Home` · `End` | `min` · `max` 로 갑니다. |
| `Tab` | 다음 요소로 포커스를 옮깁니다. |
| `Shift+Tab` | 이전 요소로 포커스를 옮깁니다. |

한 번의 크기는 `step` → `(max - min) / divisions` → 범위의 1% 순으로 정해집니다(값과 단계 참고). Flutter 는 `FocusableActionDetector` 의 단축키로, Jaspr Web 은 바깥 상자의 `keydown` 으로 처리합니다. Web 은 처리한 키마다 기본 동작을 막아 페이지가 스크롤되지 않습니다.

### 스크린 리더

- **이름**: 없습니다(위 참고). 리더는 역할과 값만 읽습니다.
- **값**: Flutter 는 `Semantics(value:)` 에, Jaspr Web 은 `aria-valuenow` 에 `value` 를 `toString()` 한 글자를 그대로 넣습니다 — Dart VM(Flutter 네이티브 · 서버 렌더)에서는 `50.0`, JavaScript 로 컴파일된 웹 빌드에서는 `50` 입니다. `aria-valuetext` 가 없어 "50%" 처럼 단위를 붙인 표현으로 바꿀 수 없습니다.
- **알림**: 라이브 리전이 아닙니다. 포커스가 없는 동안 `value` 가 바뀌면 알리지 않습니다.

### 포커스 관리

오버레이가 아니므로 열림 · 닫힘이 없고, 마운트될 때 포커스를 옮기지 않으며 가두지도 않습니다. `Tab` 으로 들어오고 `Tab` 으로 나갑니다.

포인터로 트랙을 누르면 Flutter 는 슬라이더에 포커스를 가져오되 링은 숨깁니다 — 끌어서 대략 맞춘 뒤 화살표로 다듬는 흐름이 `Tab` 없이 이어집니다. Jaspr Web 은 누를 때 링만 끄고, 포커스는 `tabindex="0"` 요소를 누를 때의 브라우저 동작에 맡깁니다.

포커스 링은 두 플랫폼 모두 `FocusOutline` 이 썸 둘레에 그리고, 키보드로 포커스했을 때만 나타납니다 — Flutter 는 포커스가 키보드로 들어왔는지 포인터로 들어왔는지를 기억해 키보드일 때만 링을 그리고, Jaspr Web 은 브라우저의 `:focus-visible` 이 맞는지를 읽습니다. 링은 `sliderStyle` 의 `focusOutlineStyle`(`CoreFocusOutlineStyle`)로 바꿉니다 — 색 · 두께뿐 아니라 `align` · `borderRadius` · `offsetColor` · `duration` 도 같은 자리에서 정하고, 비운 필드는 `FocusOutline` 의 기본값을 따릅니다.

```dart
Slider(
  value: volume,
  onChanged: setVolume,
  sliderStyle: const CoreSliderStyle(
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderColor: CoreColor.token(CoreColors.error),
    ),
  ),
)
```

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 슬라이더에 이름을 붙이는 속성이 없습니다. 리더는 무엇을 조절하는지 없이 "슬라이더, 50" 처럼 읽습니다. Flutter 는 호출부에서 `Semantics(label:)` 로 감싸는 우회가 있습니다. |
| Jaspr Web | 호출자가 속성을 넘길 자리가 없습니다. 생성자가 `key` 와 `id` 만 더 받아 `attributes` · `classes` · `css` · 이벤트를 받지 않고, `copyWith` 는 `attributes` · `classes` · `css` 를 인자로 받지만 버립니다. 그래서 `aria-label` · `aria-labelledby` · `aria-describedby` 를 밖에서 실을 수 없습니다. |
| Flutter | 스크린 리더의 올리기 · 내리기 동작이 없습니다. `Semantics` 에 `onIncrease` · `onDecrease` 가 없어 VoiceOver 의 조정 제스처(위아래 쓸기)로 값을 바꾸지 못합니다. 가로 끌기에 딸린 스크롤 동작은 남아 있어 스크린 리더가 그것으로 `onChanged` 를 부를 수 있지만, 트랙 가운데를 누르고 끈 것처럼 합성되어 지금 값에서 한 칸 옮긴 값이 되지 않습니다(하드웨어 키보드는 위 표대로 동작합니다). |
| Flutter | `enabled: false` 를 알리지 않습니다. 비활성 슬라이더가 활성처럼 읽힙니다(포커스는 두 플랫폼 모두 받지 않습니다). |
| Flutter | 오른쪽에서 왼쪽으로 쓰는 언어에서도 트랙은 왼쪽부터 채워지고 `→` 가 값을 올립니다. 앞 · 뒤 슬롯만 글 방향을 따라 자리를 바꾸므로 `leading` 이 큰 값 쪽에 놓입니다. |
| Jaspr Web | 오른쪽에서 왼쪽으로 쓰는 언어에서는 채움과 썸이 서로 다른 끝에서 시작합니다. 썸은 `left` 로 놓여 왼쪽에서 움직이지만, 채움은 시작할 쪽을 정하지 않아(`left` · `right` 를 쓰지 않습니다) 글 방향을 따라 트랙 오른쪽 끝에 붙습니다. 포인터와 `→` 는 왼쪽 기준으로 값을 올리고, 앞 · 뒤 슬롯은 글 방향을 따라 자리를 바꿉니다. |
| Jaspr Web | 트랙 위아래 여백을 눌러도 값이 바뀌지 않습니다. 포인터는 썸 높이(16)의 트랙 상자 안에서만 받습니다 — Flutter 는 24 높이까지 받습니다. |
| Jaspr Web | 포인터를 값으로 바꿀 때 썸 크기를 px 로 빼지만, 썸은 rem 으로 그립니다. 브라우저 글자 크기를 16px 가 아닌 값으로 바꾸면 끄는 동안 썸 가운데가 포인터에서 조금 어긋납니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>
<a id="플랫폼별-구현"></a>

## 플랫폼 차이

두 플랫폼 모두 네이티브 슬라이더를 쓰지 않고 트랙 · 채움 · 썸을 직접 그리며, 포인터와 키보드로 값을 바꿉니다. 아래는 플랫폼마다 다른 것입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 그리는 방법 | `Container` 와 `Stacks` | 트랙 · 채움 · 썸을 그리는 `<div>` 와, 그것을 담는 썸 높이의 상자 · 포커스 링 상자. `<input type="range">` 가 아닙니다 |
| 포인터 | `GestureDetector`(누르기와 가로 끌기) | `pointerdown` 뒤 문서 전체에 끌기 리스너. 주 포인터의 주 버튼만 받습니다 |
| 누르기만 하고 끌지 않을 때 | `onChanged` 만 부릅니다 | `onChangeStart` · `onChanged` · `onChangeEnd` 를 모두 부릅니다 |
| 누르는 동안의 썸(끌지 않을 때) | `value` 가 바뀌어야 움직입니다 | 누르는 동안 그 자리에 그리고, 놓으면 `value` 자리로 돌아갑니다 |
| 누르는 영역 | 썸 높이의 줄을 위아래 24 높이까지 | 썸 높이의 트랙 상자 안만 |
| 커서 | 움직일 수 있으면 손 모양, 아니면 금지 표시(누르는 영역과 같은 24 높이의 줄 전체) | 트랙 막대와 썸 위에서 손 모양, 비활성이면 금지 표시. `onChanged` 가 없어도 손 모양입니다 |
| 슬라이더임을 알리는 방법 | `Semantics(slider: true, value:)` — 이름 · 범위 · 비활성은 싣지 않습니다 | `role="slider"` 와 `aria-valuemin` · `aria-valuemax` · `aria-valuenow`, 비활성이면 `aria-disabled` |
| 키보드 | `FocusableActionDetector` 의 단축키 | `tabindex="0"` 과 `keydown` |
| 수정 키와 함께 누를 때 | 처리하지 않습니다 | 같은 동작을 하고 기본 동작을 막습니다 |
| 끌기 시작의 `onChangeStart` 값 | 그때의 `value` — 누른 채 잠깐 멈췄다 끌면 누른 자리의 값일 수 있습니다 | 누르기 전의 값 |
| 슬롯 배치 | `Row` 안에서 트랙이 `Expanded` | 바깥 상자가 flex 행이고 트랙은 `min-w-0` |
| 위아래 여백 8 이 놓이는 곳 | 트랙 쪽에만 | 슬롯까지 감싼 바깥 상자 — 썸보다 큰 슬롯이면 줄이 더 높습니다 |
| 슬롯 글자의 기본 스타일 | `labelLarge`(`tickLabelStyle` 의 기본값) | 주변 글자를 따릅니다. `tickLabelStyle` 을 줄 때만 실립니다 |
| 크기의 단위 | 앱의 배율(`scaling`)을 곱합니다 | rem 으로 내보내 브라우저 글자 크기를 따릅니다 |
| 더 받는 파라미터 | 없음 | `id`(바깥 `<div>` 에 붙습니다) |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 파라미터를 씁니다. Web 의 슬롯 타입은 `Component?` 이고 콜백 타입은 `CoreValueChanged<double>?` 입니다. Web 은 여기에 `id` 를 더 받습니다.

### 값과 동작

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `double` | `0.0` | 지금 값. 끄는 동안이 아니면 이 값을 그립니다. |
| `min` | `double` | `0.0` | 가장 작은 값 |
| `max` | `double` | `100.0` | 가장 큰 값 |
| `step` | `double?` | `null` | 포인터로 고른 값을 이 배수에 맞춥니다(0 기준). 키 한 번의 크기도 됩니다. |
| `divisions` | `int?` | `null` | `min` ~ `max` 를 이만큼의 칸으로 나눠 맞춥니다. 눈금은 그리지 않습니다. |
| `enabled` | `bool` | `true` | `false` 면 비활성 색이고 입력을 받지 않습니다. |
| `onChanged` | `ValueChanged<double>?` | `null` | 바뀐 값을 받습니다. 값은 호출자가 반영합니다. `null` 이면 보여 주기만 합니다. |
| `onChangeStart` | `ValueChanged<double>?` | `null` | 끌기를 시작할 때 그때의 `value` 를 받습니다(Web 은 누를 때마다, 누르고 끌기 참고). |
| `onChangeEnd` | `ValueChanged<double>?` | `null` | 끌기가 끝날 때 마지막 값을 받습니다(Web 은 누를 때마다). |

### 내용과 스타일

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `leading` | `Widget?` | `null` | 트랙 앞의 슬롯. 트랙과 `slotGapStyle` 만큼 떨어집니다. |
| `trailing` | `Widget?` | `null` | 트랙 뒤의 슬롯 |
| `sliderStyle` | `CoreSliderStyle?` | `null` | 트랙 · 채움 · 썸의 겉모습과 슬롯 간격, 포커스 링을 바꾸는 값 묶음 |

### 테마 — `CoreSliderTheme`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CoreSliderStyle?` | `null` | 앱의 모든 슬라이더에 깔리는 값. Slider 에는 variant 가 없어 variant 별 값은 없습니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreSliderStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `trackColor` | `CoreColor?` | Inactive track fill colour. |
| `activeColor` | `CoreColor?` | Active (filled) track fill colour. |
| `trackHeight` | `double?` | Track height override (logical px). |
| `disabledTrackColor` | `CoreColor?` | Inactive track fill colour when the slider is disabled. |
| `disabledActiveColor` | `CoreColor?` | Active (filled) track colour when disabled. |
| `disabledThumbColor` | `CoreColor?` | Thumb background fill colour when disabled. |
| `disabledThumbBorderColor` | `CoreColor?` | Thumb border stroke colour when disabled. |
| `containerPadding` | `CoreEdgeInsets?` | Padding inside the slider container — provides hit-area room above / below the track (symmetric vertical padding by default). |
| `borderRadius` | `CoreBorderRadius?` | Corner radius override for the track / fill / thumb. `null` → [defaultBorderRadius] (full pill). |
| `thumbColor` | `CoreColor?` | Thumb background fill colour. |
| `thumbBorderColor` | `CoreColor?` | Thumb border stroke colour. |
| `thumbSize` | `double?` | Thumb size (width = height) override (logical px). |
| `thumbBorderWidth` | `double?` | Thumb border stroke width override (logical px). |
| `thumbShadow` | `List<CoreShadowLayer>?` | Thumb drop-shadow override. `null` defers to [defaultThumbShadow]. |
| `slotGapStyle` | `CoreGapStyle?` | Gap between the track and each of the leading / trailing slots. `null` defers to [defaultSlotGapStyle]. |
| `tickLabelStyle` | `CoreTextStyle?` | Tick label text style override (when divisions / discrete labels are rendered). |
| `focusOutlineStyle` | `CoreFocusOutlineStyle?` | Keyboard focus ring, passed to the `FocusOutline` inside the slider. `null` uses [defaultFocusOutlineStyle], and any field left `null` in it takes `FocusOutline`'s own default. |

<!-- STYLE_TABLE:END -->

<Note>

- `tickLabelStyle` 은 눈금 글자가 아니라 슬롯 글자에 물려주는 스타일입니다. 슬라이더는 눈금 글자를 그리지 않습니다.
- `containerPadding` 의 위아래 여백이 그대로 누르는 영역이 되지는 않습니다. Flutter 는 썸 줄을 24 높이까지만 넓혀 받으므로 기본값에서는 여백 8 가운데 썸 쪽 4 만 들어가고, Jaspr Web 은 여백을 눌러도 값이 바뀌지 않습니다(썸 높이의 트랙 상자 안만 받습니다).

</Note>

<a id="관련-컴포넌트-related-components"></a>
<a id="조합-예제"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="slider/related-range" title="Range">

최솟값과 최댓값을 함께 고르는 구간 슬라이더입니다.

</Card>
<Card demo="slider/related-number-input" title="NumberInput">

정확한 숫자를 입력하거나 한 칸씩 올리고 내립니다.

</Card>
<Card demo="slider/related-progress" title="Progress">

조작 없이 진행 정도만 보여 줍니다. Slider 는 입력, Progress 는 출력입니다.

</Card>
</Cards>
