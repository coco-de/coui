---
title: Range
description: 두 개의 핸들로 값 구간을 선택하는 듀얼 핸들 슬라이더
category: form
platforms: [flutter, web]
related: [slider]
tags: [interactive, form-control, slider]
template: v2
source: form/range
---

# Range

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

두 값과 트랙 앞뒤의 글자를 바꿔 보며 Range 를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="range" />

Range 는 값을 스스로 바꾸지 않습니다. 핸들을 끌면 새 두 값으로 `onChanged(minValue, maxValue)` 를 부르므로, 호출자가 그 값을 `minValue` · `maxValue` 로 다시 넘겨야 핸들이 움직입니다. Range 는 부모가 준 폭을 다 채우므로 폭이 정해진 자리에 둡니다 — Flutter 의 `Row` 안이라면 `Expanded` 로 감쌉니다.

## 구조

Range 는 트랙과 그 위의 두 핸들, 그리고 선택 사항인 앞뒤 슬롯으로 이루어집니다.

<Anatomy demo="range/anatomy">
<AnatomyItem part="container" name="Container">

한 줄 전체. 앞 슬롯 · 트랙 · 뒤 슬롯을 가로로 놓습니다.

</AnatomyItem>
<AnatomyItem select="span" side="top" name="leading">

트랙 앞의 위젯 슬롯. 트랙의 시작 값 같은 글자를 둡니다.

</AnatomyItem>
<AnatomyItem select="span + div + div" side="top" name="track">

회색 줄. 두 핸들 사이는 `primary` 로 채워집니다. 핸들뿐 아니라 트랙을 눌러도 값을 고릅니다.

</AnatomyItem>
<AnatomyItem select="[role=slider]" side="top" name="min thumb">

최솟값 핸들. `minValue` 를 나타내고, 최댓값 핸들을 넘어가지 못합니다.

</AnatomyItem>
<AnatomyItem select="div + div + div > [role=slider]" side="top" name="max thumb">

최댓값 핸들. `maxValue` 를 나타내고, 최솟값 핸들 아래로 내려가지 못합니다.

</AnatomyItem>
<AnatomyItem select="span:last-child" side="top" name="trailing">

트랙 뒤의 위젯 슬롯. 트랙의 끝 값 같은 글자를 둡니다.

</AnatomyItem>
</Anatomy>

`leading` · `trailing` 이 없으면 그쪽의 간격도 그리지 않습니다. 핸들은 가장자리가 트랙 끝에 닿을 때까지만 움직이고(트랙 폭 − 핸들 크기), 채움은 두 핸들의 가운데를 잇습니다.

| 부분 | 기본값 | 바꾸는 필드 |
| --- | --- | --- |
| 트랙 높이 | 4 | `trackHeight` |
| 핸들 크기 (너비 = 높이) | 16 | `thumbSize` |
| 핸들 테두리 두께 | 1 | `thumbBorderWidth` |
| 트랙 · 채움 · 핸들 모서리 | 알약 모양 (`CoreRadius.radius9999`) | `borderRadius` |
| 트랙과 앞뒤 슬롯 사이 | 12 | `minMaxGapStyle` |

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 상태

Range 에는 variant 와 크기 축이 없습니다. `enabled` 가 모양을 정합니다.

<Preview demo="range/states" />

| 항목 | 동작 |
| --- | --- |
| 끌기 · 누르기 | 누른 자리에서 더 가까운 핸들을 골라 그 자리로 옮깁니다. 끄는 동안에는 처음 고른 핸들만 움직이고, 두 핸들에서 거리가 같으면 최솟값 핸들을 고릅니다. |
| 교차 | 두 핸들은 서로를 넘지 못합니다. Range 가 내는 값은 늘 `minValue ≤ maxValue` 입니다. |
| 기본 색 | 채움 `primary`, 트랙 `surfaceContainerHigh`, 핸들 `surfaceBright` 에 `outlineVariant` 테두리입니다. |
| Hover | 색은 바뀌지 않고, 커서만 끌기 모양(grab)이 됩니다. |
| Focus | 키보드로 포커스했을 때만 그 핸들 둘레에 원형 링을 그립니다 — 핸들에서 2만큼 비운 뒤 2 두께의 `primary` 링이고, 150ms 동안 나타납니다. |
| 비활성 | 채움 `outlineVariant`, 트랙 `surfaceContainer`, 핸들 `disabledContainer` 에 `disabledOutline` 테두리입니다. 끌기 · 포커스 · 키 입력을 받지 않고, 커서는 금지 모양이 됩니다. |
| 전환 시간 | 핸들과 채움은 값이 바뀌는 즉시 새 자리에 그려집니다. 움직이는 애니메이션은 없습니다. |
| 활성 여부 | `enabled` 의 기본값은 `true` 입니다. `onChanged` 가 없으면 움직이지 않지만, 그리는 색은 플랫폼마다 다릅니다(→ 알려진 제약). |

<Note>

비활성 트랙의 바탕은 `surfaceContainer` 라, 같은 색으로 채운 면(네이티브 문서 앱의 무대가 그렇습니다) 위에서는 트랙이 보이지 않습니다. `surface` 바탕 위에서는 보입니다.

</Note>

### 값의 단위

끌 때 맞추는 눈금과 화살표 키 한 번에 움직이는 양은 `step` · `divisions` 가 정합니다.

| 주는 값 | 끌 때 | 화살표 키 한 번 |
| --- | --- | --- |
| 없음 | 맞추지 않고 연속으로 움직입니다 | 범위(`max − min`)의 1% |
| `divisions` | 범위를 그 수로 나눈 눈금에 맞춥니다 | 눈금 하나 |
| `step` | 0 부터 센 `step` 의 배수에 맞춥니다(→ 알려진 제약) | `step` |
| 둘 다 | 눈금에 맞춘 뒤 `step` 의 배수로 다시 맞춥니다 | `step` |

`PageUp` · `PageDown` 은 화살표 키의 10배를 움직이고, `Home` · `End` 는 그 핸들이 갈 수 있는 끝으로 갑니다(→ 키보드).

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

최솟값과 최댓값을 함께 고르는 구간 입력 — 가격대 · 필터 구간 같은 — 에 Range 를 씁니다. 두 핸들 사이가 채워져 고른 구간이 한눈에 보입니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 값 하나만 조절할 때 | [Slider](/components/slider) |
| 조절하지 않고 완료 비율만 보여 줄 때 | [Progress](/components/progress) |
| 날짜의 시작과 끝을 고를 때 | [DatePicker](/components/date-picker) 의 `DateRangePicker` |

### 값 보여 주기

<Cards columns="2">
<Card demo="range/with-values" tone="do" eyebrow="이렇게 하세요">

고른 두 값을 글자로 함께 보여 줍니다. Range 는 핸들 위에 값을 그리지 않습니다.

</Card>
<Card component="range" props="minValue=20;maxValue=80" tone="dont" eyebrow="이렇게 하지 마세요">

값을 글자로 보여 주지 않으면 핸들의 위치만으로 지금 구간을 어림해야 합니다.

</Card>
</Cards>

<a id="do"></a>
<a id="dont"></a>

### 단위 정하기

<Cards columns="2">
<Card tone="do" eyebrow="이렇게 하세요" title="단위는 step 하나로 정합니다">

정확한 단위가 필요하면 `step` 을 직접 줍니다. 끌 때는 `step` 의 배수에 맞추고, 화살표 키는 `step` 만큼 움직입니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요" title="step 과 divisions 를 함께 주지 않습니다">

끌 때는 `divisions` 의 눈금에 먼저 맞추고, 화살표 키는 `step` 만큼 움직입니다. 둘을 함께 주면 같은 Range 가 끌기와 키보드에서 다른 단위로 움직일 수 있습니다.

</Card>
</Cards>

```dart
// 0 부터 200 까지, 5 단위로
Range(
  minValue: 25,
  maxValue: 75,
  min: 0,
  max: 200,
  step: 5,
  onChanged: (min, max) => updateRange(min, max),
)
```

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

트랙과 핸들의 색 · 크기 · 모서리, 앞뒤 슬롯과의 간격, 포커스 링처럼 보이는 값은 `rangeStyle`(`CoreRangeStyle`) 하나로 덮어씁니다.

<Split>

<Code language="dart" title="Range 하나만 바꾸기">
Range(
  minValue: minPrice,
  maxValue: maxPrice,
  onChanged: updatePrice,
  rangeStyle: CoreRangeStyle(
    activeTrackColor: CoreColor.token(CoreColors.success),
    thumbBorderColor: CoreColor.token(CoreColors.success),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    range: CoreRangeTheme(
      style: CoreRangeStyle(
        trackHeight: CoreSpace.space8,
        thumbSize: CoreSpace.space24,
      ),
    ),
  ),
)
</Code>

</Split>

<Note>

비활성일 때는 활성 색 네 필드(`activeTrackColor` · `inactiveTrackColor` · `thumbColor` · `thumbBorderColor`) 대신 `disabled` 가 붙은 네 필드(`disabledActiveTrackColor` · `disabledInactiveTrackColor` · `disabledThumbColor` · `disabledThumbBorderColor`)를 씁니다. `borderRadius` 는 트랙 · 채움 · 두 핸들에 함께 쓰여, 핸들의 모서리만 따로 바꿀 수 없습니다. 포커스 링은 핸들의 `borderRadius` 와 무관하게 원으로 그려집니다 — 링의 모서리는 `focusOutlineStyle` 의 `circleBorderRadius` 가 정합니다.

</Note>

### 빠른 오버라이드 (Chain)

이미 만든 `Range` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `rangeStyle` 인자와 같게 동작합니다. `.radius4` 처럼 토큰 이름과 같은 이름의 getter 는 `borderRadius` 를 바꿉니다 — 이름이 곧 값이라(`.radius4` 는 `CoreRadius.radius4`) 어느 컴포넌트에서 써도 뜻이 같습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class RangeChainExample extends StatefulWidget {
  const RangeChainExample({super.key});

  @override
  State<RangeChainExample> createState() => _RangeChainExampleState();
}

class _RangeChainExampleState extends State<RangeChainExample> {
  double _min = 20;
  double _max = 80;

  @override
  Widget build(BuildContext context) {
    return Range(
          minValue: _min,
          maxValue: _max,
          onChanged: (min, max) => setState(() {
            _min = min;
            _max = max;
          }),
        )
        .withStyle(
          const CoreRangeStyle(
            trackHeight: CoreSpace.space12,
            thumbSize: CoreSpace.space24,
            activeTrackColor: CoreColor.token(CoreColors.tertiary),
          ),
        )
        .radius16;
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class RangeChainExample extends StatefulComponent {
  const RangeChainExample({super.key});

  @override
  State<RangeChainExample> createState() => _RangeChainExampleState();
}

class _RangeChainExampleState extends State<RangeChainExample> {
  double _min = 20;
  double _max = 80;

  @override
  Component build(BuildContext context) {
    return Range(
          minValue: _min,
          maxValue: _max,
          onChanged: (min, max) => setState(() {
            _min = min;
            _max = max;
          }),
        )
        .withStyle(
          const CoreRangeStyle(
            trackHeight: CoreSpace.space12,
            thumbSize: CoreSpace.space24,
            activeTrackColor: CoreColor.token(CoreColors.tertiary),
          ),
        )
        .radius16;
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

### 값이 정해지는 순서

```text
기본값 (CoreRangeStyle.default*)
  → CoreComponentTheme.range.style   // 앱 전체
  → rangeStyle                       // 인스턴스
```

뒤로 갈수록 우선합니다. Range 에는 variant 가 없어 앱 전체 값은 `style` 하나입니다. 앞뒤 간격(`minMaxGapStyle`)은 기본 간격 12 위에, 포커스 링(`focusOutlineStyle`)은 Range 의 기본 링(색 `primary`) 위에 얹히고, 링에서 비워 둔 필드는 `FocusOutline` 의 기본값을 따릅니다.

<a id="접근성-accessibility"></a>

## 접근성

두 핸들이 각자 하나의 슬라이더입니다. Flutter 는 핸들마다 `Semantics(slider: true)` 로, Jaspr Web 은 핸들마다 `role="slider"` 로 알립니다. 트랙에는 역할이 없습니다 — Jaspr Web 의 트랙은 시맨틱이 없는 그림이고, Flutter 는 트랙의 누르기 · 끌기 동작을 시맨틱에 남깁니다(→ 알려진 제약).

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 핸들마다 `Semantics(slider: true, label:, value:)` 입니다. 라벨은 로케일의 `rangeMinValueLabel` · `rangeMaxValueLabel`, 값은 그 핸들의 숫자를 글자로 바꾼 것입니다(→ 스크린 리더). 핸들이 갈 수 있는 범위와 비활성은 싣지 않습니다. |
| Jaspr Web | 핸들마다 `role="slider"` · `aria-valuenow` · `aria-valuemin` · `aria-valuemax` · `aria-label` 이 붙습니다. 최솟값 핸들의 `aria-valuemax` 는 최댓값 핸들의 지금 값이고, 최댓값 핸들의 `aria-valuemin` 은 최솟값 핸들의 지금 값입니다. 활성일 때만 `tabindex="0"` 이, `enabled: false` 면 `aria-disabled="true"` 가 붙습니다. |

탭 정지점 하나로는 두 값을 알릴 수 없어(`aria-valuenow` 는 숫자 하나입니다) 핸들을 나눴습니다 — ARIA APG 의 "Slider (Multi-Thumb)" 패턴입니다. 두 핸들을 하나의 범위로 묶는 그룹 역할은 어느 플랫폼에도 없습니다. Jaspr Web 루트에는 호출자가 넘긴 `attributes` 만 붙고, Flutter 에도 두 `Semantics` 를 감싸는 노드가 없습니다. `leading` · `trailing` 의 글자도 핸들의 이름으로 이어지지 않습니다.

### 키보드

활성일 때(`enabled: true` 이고 `onChanged` 가 있을 때) 핸들마다 `Tab` 으로 포커스할 수 있고, 포커스된 핸들에서는 두 플랫폼이 같게 동작합니다.

| 키 | 동작 |
| --- | --- |
| `→` · `↑` | 한 단위 올립니다. |
| `←` · `↓` | 한 단위 내립니다. |
| `PageUp` · `PageDown` | 10 단위 올리고 내립니다. |
| `Home` · `End` | 그 핸들이 갈 수 있는 아래 끝 · 위 끝으로 갑니다. |
| `Tab` · `Shift+Tab` | 다른 핸들이나 바깥 요소로 포커스를 옮깁니다. |

`Home` · `End` 의 끝은 핸들마다 다릅니다. 최솟값 핸들은 `Home` 이면 트랙의 `min`, `End` 면 최댓값 핸들의 지금 값으로 갑니다. 최댓값 핸들은 `Home` 이면 최솟값 핸들의 지금 값, `End` 면 트랙의 `max` 로 갑니다. 한 단위의 크기는 위 [값의 단위](#값의-단위) 표를 따르고, [Slider](/components/slider) 의 화살표 키와 같은 규칙입니다.

### 스크린 리더

- **이름**: 두 핸들 모두 활성 로케일의 `rangeMinValueLabel` · `rangeMaxValueLabel` 에서 옵니다(한국어 "최솟값" · "최댓값"). 두 플랫폼이 같은 키를 읽습니다.
- **값**: 두 플랫폼 모두 그 핸들의 값(`double`)을 Dart 의 기본 문자열로 바꿔 싣습니다. 그래서 정수 값도 모바일 · 데스크톱 Flutter 앱에서는 `20.0` 처럼 소수점이 붙고, Jaspr Web 의 `aria-valuenow` 는 서버가 그린 마크업에서 `20.0`, 브라우저에서 다시 그리면 `20` 이 될 수 있습니다. 가격 · 날짜처럼 단위나 형식을 붙여 읽게 하는 방법이 없습니다.
- **범위**: Jaspr Web 은 그 핸들이 갈 수 있는 범위까지 알리고, Flutter 는 값만 알려 "어디까지 올릴 수 있는지" 가 전달되지 않습니다.
- **통보**: 라이브 리전이 아닙니다. 포커스가 없는 핸들의 값이 바뀌면 알리지 않습니다.

### 포커스 관리

마운트될 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. 한 Range 는 탭 정지점 두 개(핸들마다 하나)를 만들고, 비활성이면 두 핸들 모두 탭 순서에서 빠집니다.

Flutter 는 트랙을 누르거나 끌면 고른 핸들로 포커스를 옮깁니다 — 끌어서 대략 맞춘 뒤 `Tab` 없이 화살표 키로 미세 조정할 수 있습니다. 이때 링은 숨겨 두었다가 화살표 같은 조작 키를 누르면 나타냅니다. Jaspr Web 은 트랙을 눌러도 포커스를 옮기지 않습니다. 핸들 자체를 누르면 브라우저가 그 핸들에 포커스를 주고, 링은 그 핸들에서 키를 누르면 나타납니다 — Flutter 와 달리 조작 키가 아닌 키(`Shift` 같은)를 눌러도 나타납니다.

포커스 링은 두 플랫폼 모두 `FocusOutline` 이 핸들 둘레에 원으로 그리고, 키보드로 포커스했을 때만 150ms 동안 나타납니다(동작 줄이기를 켜면 바로 나타납니다). `rangeStyle.focusOutlineStyle`(`CoreFocusOutlineStyle`)로 색 · 두께뿐 아니라 `align` · `offsetColor` · `duration` 까지 정합니다. 링의 색은 비워 두면 Range 의 기본값 `primary` 이고, 그 밖에 비워 둔 필드는 `FocusOutline` 의 기본값을 따릅니다.

```dart
Range(
  minValue: 20,
  maxValue: 80,
  onChanged: (min, max) => setState(() { /* ... */ }),
  rangeStyle: const CoreRangeStyle(
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderColor: CoreColor.token(CoreColors.error),
    ),
  ),
)
```

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | 핸들이 갈 수 있는 범위를 알리지 않아, 리더가 "이 핸들이 어디까지 갈 수 있는지" 를 읽지 못합니다. `Semantics` 는 Range 안에서 만들어지고 바꿀 자리가 없습니다. |
| Flutter | `enabled: false` 를 시맨틱으로 알리지 않습니다. 포커스는 받지 않습니다. |
| Flutter | 핸들의 `Semantics` 에 값 올리기 · 내리기 동작(`onIncrease` · `onDecrease`)이 없습니다. 하드웨어 키보드의 화살표는 위 표대로 동작합니다. |
| Flutter | 트랙의 `GestureDetector` 를 시맨틱에서 빼지 않아(`excludeFromSemantics` 를 주지 않습니다), `enabled` 가 `true` 이면 누르기와 가로 스크롤 동작이 시맨틱에 실립니다. 리더가 그 누르기를 실행하면 트랙 가운데를 누른 것과 같아, 더 가까운 핸들이 범위의 가운데(눈금이 있으면 가장 가까운 눈금)로 옮겨집니다. |
| Jaspr Web | `onChanged` 를 비우면 활성 색으로 그리고 `aria-disabled` 도 붙이지 않습니다 — Flutter 는 같은 경우 비활성 색으로 그립니다. 두 플랫폼 모두 끌기 · 포커스 · 키 입력은 받지 않습니다. 읽기 전용으로 보여 줄 때는 `enabled: false` 를 함께 줍니다. |
| Jaspr Web | 트랙을 눌러도 포커스가 고른 핸들로 옮겨 가지 않습니다. 끌고 나서 화살표로 맞추려면 핸들을 직접 누르거나 `Tab` 으로 갑니다. |
| Jaspr Web | 트랙과 핸들에 `touch-action` 규칙이 없고, `pointerdown` 의 기본 동작도 막지 않습니다. 터치로 끄는 도중 브라우저가 그 손가락을 스크롤에 쓰면 `pointercancel` 이 와서 끌기가 그 자리에서 끝납니다. |
| 공통 | 핸들 이름을 인스턴스마다 바꿀 수 없습니다. 앱의 `CouiLocalizations` · `CoUILocalizations` 구현에서 `rangeMinValueLabel` · `rangeMaxValueLabel` 문구를 바꾸면 앱 전체에 반영됩니다. |
| 공통 | 두 핸들이 하나의 범위라는 관계가 드러나지 않습니다. Jaspr Web 은 `Range(attributes: {'role': 'group', 'aria-label': '가격대'})` 로 루트에 그룹 역할과 이름을 실을 수 있고, Flutter 는 호출부에서 `Semantics` 로 감쌉니다. |
| 공통 | 값을 숫자 그대로 읽습니다. 단위나 형식을 붙일 방법이 없습니다. |
| 공통 | 두 핸들이 같은 값에서 겹치면 누르기 · 끌기는 늘 최솟값 핸들을 잡습니다. 그래서 겹친 자리보다 오른쪽을 누르거나 끌어도 움직이지 않고, 왼쪽으로만 떼어 낼 수 있습니다. 겹친 자리가 트랙의 시작(`min`)이면 끌어서는 떼어 낼 수 없으니, `Tab` 으로 최댓값 핸들(두 번째 정지점)에 가서 화살표로 올립니다. |
| 공통 | 끌 때 `step` 은 `min` 이 아니라 0 부터 센 배수에 맞춥니다. `min` 이 `step` 의 배수가 아니면 끌어서 고른 값과 화살표 키로 고른 값의 눈금이 어긋납니다. |
| 공통 | 오른쪽에서 왼쪽으로 쓰는 언어에서도 값은 왼쪽에서 오른쪽으로 커지고, `→` 가 값을 올립니다. 이때 `leading` 은 트랙의 오른쪽, `trailing` 은 왼쪽에 놓입니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 핸들의 역할 | `Semantics(slider: true)` · 라벨 · 값 | `role="slider"` · `aria-valuenow` · `aria-valuemin` · `aria-valuemax` · `aria-label` |
| 끌기 | `GestureDetector` 의 누르기 · 가로 끌기 | 트랙의 `pointerdown` 과 문서의 `pointermove` · `pointerup` · `pointercancel`. 트랙이 `touch-action` 을 정하지 않습니다(→ 알려진 제약) |
| 누르는 영역 | 트랙 전체 폭에서 높이 24 | 높이 4 의 트랙과 핸들 둘레 24×24 |
| 트랙을 눌렀을 때 포커스 | 고른 핸들로 옮깁니다 | 옮기지 않습니다(핸들을 직접 누르면 그 핸들로) |
| 누른 뒤 링을 켜는 키 | 조작 키(화살표 · `PageUp` · `PageDown` · `Home` · `End`) | 그 핸들에서 누르는 아무 키 |
| 키보드 | 핸들마다 `FocusableActionDetector` 와 단축키 | 핸들마다 `tabindex="0"` 과 `keydown` |
| `onChanged` 가 없을 때의 색 | 비활성 색 | 활성 색 |
| 치수 | 앱의 배율(`scaling`)을 곱합니다 | 트랙 높이 · 핸들 크기는 rem 으로 내보내 브라우저 글자 크기를 따르고, 핸들 테두리 두께는 px 입니다 |
| 그리는 방법 | `Stacks` 안에 트랙 · 채움 · 핸들을 겹칩니다 | `<div>` 로 그리고, 네이티브 `<input type="range">` 는 쓰지 않습니다 |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. `W` 는 위젯 슬롯의 타입으로, Flutter 에서는 `Widget`, Jaspr Web 에서는 `Component` 입니다. 값과 `step` 은 같은 값의 단위를 쓰고, 트랙의 폭(논리 px)과는 따로입니다.

### 값과 범위

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `minValue` | `double` | `0.0` | 최솟값 핸들의 값 |
| `maxValue` | `double` | `100.0` | 최댓값 핸들의 값 |
| `min` | `double` | `0.0` | 트랙의 시작 값 |
| `max` | `double` | `100.0` | 트랙의 끝 값 |
| `step` | `double?` | `null` | 값의 단위. 끌 때 이 배수에 맞추고, 화살표 키는 이만큼 움직입니다. |
| `divisions` | `int?` | `null` | 트랙을 나누는 눈금 수. 끌 때 이 눈금에 맞춥니다. |
| `onChanged` | `void Function(double, double)?` | `null` | 새 `(minValue, maxValue)` 를 받습니다. 값은 호출자가 반영합니다. |

### 상태와 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `enabled` | `bool` | `true` | `false` 면 끌기 · 포커스 · 키 입력을 받지 않고 비활성 색으로 그립니다. |
| `leading` | `W?` | `null` | 트랙 앞 위젯 슬롯 |
| `trailing` | `W?` | `null` | 트랙 뒤 위젯 슬롯 |
| `rangeStyle` | `CoreRangeStyle?` | `null` | 보이는 값 덮어쓰기 |

### Jaspr Web 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `attributes` | `Map<String, String>?` | `null` | 루트 요소에 그대로 붙는 HTML 속성. 두 핸들을 묶는 그룹 역할과 이름을 실을 때 씁니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreRangeStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `activeTrackColor` | `CoreColor?` | Active (selected, between-thumbs) track fill colour. |
| `inactiveTrackColor` | `CoreColor?` | Inactive (outside-selection) track fill colour. |
| `disabledActiveTrackColor` | `CoreColor?` | Active (selected) track fill colour when disabled. |
| `disabledInactiveTrackColor` | `CoreColor?` | Inactive track fill colour when disabled. |
| `disabledThumbColor` | `CoreColor?` | Thumb background fill colour when disabled. |
| `disabledThumbBorderColor` | `CoreColor?` | Thumb border stroke colour when disabled. |
| `trackHeight` | `double?` | Track height override (logical px). |
| `borderRadius` | `CoreBorderRadius?` | Corner radius override for the track / fill / thumbs. `null` → [defaultBorderRadius] (full pill). |
| `thumbColor` | `CoreColor?` | Thumb background fill colour. |
| `thumbBorderColor` | `CoreColor?` | Thumb border stroke colour. |
| `thumbSize` | `double?` | Thumb size (width = height) override (logical px). |
| `thumbBorderWidth` | `double?` | Thumb border stroke width override (logical px). Defaults to [defaultThumbBorderWidth]. |
| `minMaxGapStyle` | `CoreGapStyle?` | Space between the slider and the `leading` / `trailing` content on either side of it, passed as is to the `Gap` on that side (drawn only when that side is set). Laid over [defaultMinMaxGapStyle]. |
| `focusOutlineStyle` | `CoreFocusOutlineStyle?` | Keyboard focus ring of the focused thumb, passed to its `FocusOutline`. `null` uses [defaultFocusOutlineStyle], and any field left `null` in it takes `FocusOutline`'s own default. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="range/related-slider" title="Slider">

값 하나를 고를 때 씁니다.

</Card>
<Card demo="range/related-progress" title="Progress">

조절하지 않고 진행 비율을 보여 줄 때 씁니다.

</Card>
</Cards>
