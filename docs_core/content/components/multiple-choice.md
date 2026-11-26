---
title: MultipleChoice
description: 여러 옵션 중 하나를 선택하는 단일 선택 그룹 컴포넌트
category: form
platforms: [flutter, web]
related: [radio-group, select, chip-group]
tags: [interactive, form-control, single-select]
template: v2
source: form/multiple_choice
---

# MultipleChoice

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

선택값 · 해제 허용 · 옵션 수 · 활성 여부를 바꿔 보며 확인하고, 만들어진 코드를 그대로 복사하세요. 미리보기의 옵션을 누르면 선택이 옮겨 갑니다. 코드의 `value` 는 컨트롤에서 고른 값이라, 미리보기를 눌러 바꾼 선택은 코드에 나타나지 않습니다.

<Playground component="multiple-choice" />

MultipleChoice 는 옵션 여럿을 펼쳐 두고 하나를 고르게 하는 그룹이고, 옵션 하나가 [Chip](/components/chip) 하나입니다. 선택값은 스스로 바꾸지 않습니다. 옵션을 누르면 `onChanged` 로 그 값을 알리고, 호출자가 그 값을 `value` 로 다시 넘겨야 선택이 옮겨 갑니다. 옵션은 값을 고를 뿐이라, 누르면 다른 화면으로 이동하는 속성은 없습니다.

```dart
MultipleChoice<String>(
  options: const [
    (value: 'sm', label: '작음'),
    (value: 'md', label: '보통'),
    (value: 'lg', label: '큼'),
  ],
  value: size,
  onChanged: (next) => setState(() => size = next),
)
```

Flutter 와 Jaspr Web 이 같은 코드를 씁니다. 옵션은 `(value:, label:)` 레코드의 목록이고, 값의 타입 `T` 는 어떤 타입이든 됩니다. 옵션의 `value` 는 서로 다르게 둡니다 — 그룹의 `value` 와 `==` 로 같은 옵션은 모두 고른 모양이 됩니다.

## 구조

그룹은 옵션을 늘어놓는 틀 하나와, 옵션마다의 칩으로 이루어집니다.

<Anatomy demo="multiple-choice/anatomy">
<AnatomyItem part="container" name="Container">

옵션을 가로로 놓고, 폭이 모자라면 다음 줄로 넘기는 틀. 옵션 사이와 줄 사이를 8씩 띄웁니다. 틀 자체에는 채움 · 테두리 · 안쪽 여백이 없습니다.

</AnatomyItem>
<AnatomyItem select="[role=radio]" side="top" name="option">

고르지 않은 옵션. 채움 없이 1 두께의 `outlineVariant` 테두리와 `onSurfaceVariant` 라벨로 그립니다.

</AnatomyItem>
<AnatomyItem select="[aria-checked=true]" side="top" name="selected">

고른 옵션. `primaryContainer` 채움, 채움과 같은 색의 테두리, `onPrimaryContainer` 라벨입니다. 체크 표시나 아이콘은 붙지 않습니다.

</AnatomyItem>
<AnatomyItem select="[role=radio] ~ [role=radio] ~ [role=radio] span" side="right" name="label">

옵션의 라벨. `label` 문자열을 한 줄로 그립니다.

</AnatomyItem>
</Anatomy>

그룹은 옵션의 상자를 직접 그리지 않습니다. 옵션은 선택 여부에 따라 아래 값의 칩으로 그려집니다. 컴포넌트가 칩에 정해 주는 것은 `chipColor` · `emphasis` · `selected` 이고, `variant` 는 두 경우 모두 칩의 기본값(`outlined`)입니다.

| 옵션 | `chipColor` | `variant` | `emphasis` | `selected` |
| --- | --- | --- | --- | --- |
| 고르지 않음 | `neutral` | `outlined` | `low` | `false` |
| 고름 | `primary` | `outlined` | `low` | `true` |

칩의 크기는 `md`(높이 32 · 좌우 여백 12 · 모서리 8 · 라벨 `labelMedium`), 모양은 `rounded` 입니다. 그룹에는 크기나 모양을 고르는 속성이 없고, 다른 값이 필요하면 [`chipStyle`](/components/multiple-choice#테마와-스타일) 로 바꿉니다.

<a id="동작-스펙-behavior"></a>

## 상태

선택 여부와 `enabled` 가 모양을 정합니다. 미리보기는 옵션이 하나뿐인 그룹을 상태마다 하나씩 놓은 것입니다.

<Preview demo="multiple-choice/states" />

| 항목 | 동작 |
| --- | --- |
| 고를 때 | 고르지 않은 옵션을 누르면 그 값으로 `onChanged` 를 부릅니다. 고를 수 있는 값은 한 번에 하나입니다. |
| 고른 옵션을 다시 누를 때 | 기본은 콜백을 부르지 않습니다. `allowUnselect: true` 면 `onChanged(null)` 을 부릅니다. |
| 선택 | 고른 옵션만 `primaryContainer` 로 채워지고, 라벨이 `onPrimaryContainer` 가 됩니다. |
| Hover · 눌림 | 칩의 글자색을 채움 위에 hover 3% · 눌림 12% 로 겹칩니다. 누르는 동안 칩이 0.97배로 줄어듭니다. |
| Focus | 키보드로 포커스하면 글자색을 8% 로 겹치고, 그 칩의 모서리를 따라 포커스 링을 그립니다. |
| 비활성 | `enabled: false` 는 모든 옵션을 막습니다. 고르지 않은 옵션은 `surface` 채움에 `disabledOutline` 테두리, 고른 옵션은 `disabledContainer` 채움에 테두리 없음, 라벨은 `disabledContent` 입니다. 누를 수 없고 hover · 눌림 · 포커스 표시가 없습니다. |
| `onChanged` 가 없을 때 | `enabled` 의 기본값은 `onChanged` 유무와 상관없이 `true` 입니다. 그래서 비활성 모양이 아니고 hover 와 포커스에도 반응하지만, 눌러도 아무 일도 일어나지 않습니다. |
| 전환 시간 | 선택이 바뀌면 칩의 채움과 테두리가 100ms 동안 바뀝니다. Jaspr Web 은 라벨 색도 함께 바뀝니다. 동작 줄이기를 켜면 바로 바뀝니다. |

<Note>

CoUI 기본 색에서 `primaryContainer` 는 중립색입니다. 라이트 모드에서 `surfaceContainer` 로 채운 면 위에 놓으면, 바탕(neutral 100)과 고른 칩의 채움(neutral 200)이 모두 옅은 회색이라 두 색의 차이가 작습니다.

</Note>

### 선택 해제

`allowUnselect` 를 켜면 고른 옵션을 다시 누르거나 `Enter` · `Space` 를 눌러 선택을 비울 수 있습니다. 해제도 `onChanged` 로 알리며 값은 `null` 입니다. 기본값은 꺼짐입니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

크기나 옵션처럼 적은 수의 후보 중 하나를 버튼 모양으로 고르게 할 때, 라디오 버튼보다 눈에 띄는 선택 화면이 필요할 때 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 라디오 버튼의 화살표 키 이동이나 폼에 값을 전달하는 기능이 필요할 때 | [RadioGroup](/components/radio-group) |
| 후보를 펼쳐 두지 않고 드롭다운에서 하나를 고를 때 | [Select](/components/select) |
| 칩으로 여러 개를 동시에 고를 때 | [ChipGroup](/components/chip-group) |
| 두세 칸을 한 트랙에 묶어 보기 방식을 바꿀 때 | [ToggleGroup](/components/toggle-group) |

### 후보 수

<Cards columns="2">
<Card component="multiple-choice" props="value=md" tone="do" eyebrow="이렇게 하세요">

후보가 적고 라벨이 짧아 한눈에 비교할 수 있을 때 씁니다.

</Card>
<Card demo="multiple-choice/dont-many" height="340" tone="dont" eyebrow="이렇게 하지 마세요">

후보가 많으면 여러 줄로 쌓여 비교하기 어렵습니다. Select 를 씁니다.

</Card>
</Cards>

<a id="do"></a>

### 해제는 의미가 있을 때만

"필터 없음"처럼 아무것도 고르지 않은 상태가 유효할 때만 `allowUnselect` 를 켭니다. 켜지 않으면 고른 옵션을 다시 눌러도 선택이 그대로입니다.

```dart
MultipleChoice<String>(
  options: const [
    (value: 'all', label: '전체'),
    (value: 'active', label: '진행 중'),
  ],
  value: filter,
  allowUnselect: true,
  onChanged: (next) => setState(() => filter = next),
)
```

<a id="dont"></a>

### 특정 옵션만 막기

`enabled` 는 그룹 전체를 켜고 끕니다. 옵션 레코드에는 옵션 하나를 막는 필드가 없습니다. 아래처럼 써도 `'md'` 하나가 막히지 않습니다 — `'md'` 를 고르기 전에는 모든 옵션이 눌리고, `'md'` 를 고르는 순간 그룹 전체가 꺼져 다른 옵션으로 바꿀 수 없게 됩니다.

```dart
// 이렇게 하지 마세요 — 고른 값에 따라 그룹 전체가 꺼집니다.
MultipleChoice<String>(
  options: const [
    (value: 'sm', label: '작음'),
    (value: 'md', label: '보통 (품절)'),
  ],
  value: size,
  enabled: size != 'md',
  onChanged: (next) => setState(() => size = next),
)
```

막아야 할 옵션은 `options` 에서 뺍니다. 보여 주면서 막아야 하면 옵션마다 활성 여부를 정할 수 있는 컴포넌트를 씁니다 — [RadioGroup](/components/radio-group) 은 `child` 안의 `Radio(enabled: false)`, [ChipGroup](/components/chip-group) 은 `chipBuilder` 가 그리는 `Chip(enabled: false)` 입니다.

## 배치

옵션은 가로로 놓이고, 폭이 모자라면 다음 줄로 넘어갑니다.

<Preview demo="multiple-choice/wrap" />

| 항목 | 동작 |
| --- | --- |
| 방향 | 가로 배치 하나입니다. 방향을 고르는 속성은 없습니다. |
| 간격 | 옵션 사이와 줄 사이가 같은 `optionSpacing`(기본 8)입니다. |
| 폭 | 부모가 폭을 강제하지 않으면 옵션의 내용만큼 차지하고, 부모 폭을 넘으면 줄을 바꿉니다. Flutter 에서 `Row` 처럼 폭을 제한하지 않는 부모에 바로 넣으면 줄을 바꾸지 않고 한 줄로 늘어섭니다. `Expanded` 나 `SizedBox` 로 폭을 정해 줍니다. |
| 옵션 크기 | 높이는 32 이상이고, 폭은 라벨과 좌우 여백이 정합니다. |
| 밀도 | 옵션 사이 간격이 `compact` 에서 4, `spacious` 에서 12 가 됩니다. 칩의 좌우 여백과 모서리도 밀도를 따르고, 높이 32 는 그대로입니다. |

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

`multipleChoiceStyle`(`CoreMultipleChoiceStyle`)로 옵션 사이 간격(`optionSpacing`)과 옵션 칩의 모양(`chipStyle`)을 바꿉니다. `transitionDuration` 과 `clickableStyle` 은 칩의 전환 시간과 누름 · 포커스 표현으로 전달됩니다. `chipStyle` 에서 같은 값을 정하면 `chipStyle` 이 이깁니다.

<Split>

<Code language="dart" title="그룹 하나만 바꾸기">
MultipleChoice<String>(
  options: sizes,
  value: size,
  onChanged: setSize,
  multipleChoiceStyle: CoreMultipleChoiceStyle(
    optionSpacing: CoreSpace.space12,
    chipStyle: CoreChipStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    multipleChoice: CoreMultipleChoiceTheme(
      style: CoreMultipleChoiceStyle(optionSpacing: CoreSpace.space12),
    ),
  ),
)
</Code>

</Split>

`chipStyle` 로 자주 바꾸는 값은 아래와 같습니다.

| 바꾸려는 것 | `CoreChipStyle` 필드 | 닿는 옵션 |
| --- | --- | --- |
| 모서리 | `borderRadius` | 모든 옵션. 포커스 링도 이 모서리를 따릅니다. |
| 높이 하한 | `minHeight` | 모든 옵션 |
| 안쪽 여백 | `padding` | 모든 옵션 |
| 라벨 글자 | `labelStyle` | 모든 옵션 |
| 고르지 않은 옵션의 라벨 색 | `lowUnselectedForegroundColor` | 활성 상태의 고르지 않은 옵션 |
| 고르지 않은 옵션의 테두리 색 | `lowUnselectedBorderColor` | 활성 상태의 고르지 않은 옵션 |

<Note>

`chipStyle` 은 고른 옵션과 고르지 않은 옵션에 같은 값으로 전달됩니다. `backgroundColor` · `borderColor` · `foregroundColor` 나 `labelStyle` 안의 색을 주면 비활성까지 모든 상태를 덮어, 어느 옵션을 골랐는지 구분이 약해지거나 사라집니다. 누를 수 있는 상태에서 고른 옵션의 색만 바꾸는 `chipStyle` 필드는 없습니다(비활성일 때 고른 옵션의 테두리 색만 바꾸는 `disabledSelectedBorderColor` 는 있습니다). 앱 테마의 `CoreChipTheme.colorStyles[CoreChipColor.primary]` 는 고른 옵션에 닿지만, 같은 테마 아래의 모든 primary 칩과 그 모든 상태가 함께 바뀝니다.

</Note>

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `MultipleChoice` 에는 `withStyle` 로 스타일을 덧붙입니다. 생성자의 `multipleChoiceStyle` 인자와 같게 동작하고, 겹치는 필드는 뒤에 붙인 값이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class MultipleChoiceChainExample extends StatefulWidget {
  const MultipleChoiceChainExample({super.key});

  @override
  State<MultipleChoiceChainExample> createState() => _MultipleChoiceChainExampleState();
}

class _MultipleChoiceChainExampleState extends State<MultipleChoiceChainExample> {
  String? _value = 'md';

  @override
  Widget build(BuildContext context) {
    return MultipleChoice<String>(
      options: const [
        (value: 'sm', label: '작음'),
        (value: 'md', label: '보통'),
        (value: 'lg', label: '큼'),
      ],
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    ).withStyle(
      const CoreMultipleChoiceStyle(
        optionSpacing: CoreSpace.space12,
        chipStyle: CoreChipStyle(
          padding: CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space20,
            vertical: CoreSpace.space12,
          ),
          borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class MultipleChoiceChainExample extends StatefulComponent {
  const MultipleChoiceChainExample({super.key});

  @override
  State<MultipleChoiceChainExample> createState() => _MultipleChoiceChainExampleState();
}

class _MultipleChoiceChainExampleState extends State<MultipleChoiceChainExample> {
  String? _value = 'md';

  @override
  Component build(BuildContext context) {
    return MultipleChoice<String>(
      options: const [
        (value: 'sm', label: '작음'),
        (value: 'md', label: '보통'),
        (value: 'lg', label: '큼'),
      ],
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    ).withStyle(
      const CoreMultipleChoiceStyle(
        optionSpacing: CoreSpace.space12,
        chipStyle: CoreChipStyle(
          padding: CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space20,
            vertical: CoreSpace.space12,
          ),
          borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        ),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

### 값이 정해지는 순서

```text
그룹
  CoreMultipleChoiceStyle.defaultOptionSpacing (8)
  → CoreComponentTheme.multipleChoice.style      // 앱 전체
  → multipleChoiceStyle                          // 인스턴스

옵션 칩
  Chip 의 md · rounded 기본값
  → CoreComponentTheme.chip.style
  → CoreComponentTheme.chip.colorStyles[primary 또는 neutral]
  → CoreComponentTheme.chip.variantStyles[outlined]
  → MultipleChoice 가 칩에 넘기는 값
       CoreMultipleChoiceStyle.defaultChipStyle  // 높이 32
       → transitionDuration · clickableStyle · 이전 낱개 필드
       → chipStyle
       // 뒤의 두 줄은 multipleChoice 테마 위에 multipleChoiceStyle 을 합친 값입니다
```

뒤로 갈수록 우선합니다. MultipleChoice 는 높이 32 를 칩에 직접 넘기므로, `CoreChipTheme.style.minHeight` 는 이 옵션들의 높이를 바꾸지 않습니다. 옵션 높이는 `multipleChoiceStyle` 의 `chipStyle.minHeight` 로 바꿉니다.

<a id="이전-필드-deprecated"></a>

### 이전 필드

옵션 상자를 직접 꾸미던 아래 필드는 deprecated(since 0.173)입니다. 값은 옵션 칩에 계속 전달되고, 같은 값을 `chipStyle` 도 정하면 `chipStyle` 이 이깁니다. 새 코드는 `chipStyle` 을 씁니다. 선택이나 활성 여부에 따라 값이 갈리던 필드는 `chipStyle` 로 옮기면 그 구분이 사라지는 것이 많으므로, 옮기기 전에 아래 표를 확인합니다.

| 이전 필드 | 이전 필드가 닿는 옵션 | `chipStyle` 의 대체 |
| --- | --- | --- |
| `optionPadding` | 모두 | `padding` |
| `optionBorderRadius` | 모두 | `borderRadius` |
| `optionBorderWidth` | 모두 | `borderWidth` |
| `selectedBackgroundColor` | 고른 옵션(비활성 포함) | 같은 범위의 필드가 없습니다. `backgroundColor` 는 모든 옵션에 닿습니다. |
| `unselectedBackgroundColor` | 고르지 않은 옵션(비활성 포함) | 같은 범위의 필드가 없습니다. `backgroundColor` 는 모든 옵션에 닿습니다. |
| `selectedBorderColor` | 고른 옵션(비활성 포함) | 비활성 상태는 `disabledSelectedBorderColor`. 활성 상태까지 같은 범위인 필드는 없습니다. `borderColor` 는 모든 옵션에 닿습니다. |
| `unselectedBorderColor` | 고르지 않은 옵션(비활성 포함) | 활성 상태는 `lowUnselectedBorderColor`. 비활성까지 같은 범위인 필드는 없습니다. |
| `selectedTextStyle` | 활성 상태의 고른 옵션 | 같은 범위의 필드가 없습니다. `labelStyle` 은 모든 옵션에 닿습니다. |
| `unselectedTextStyle` | 활성 상태의 고르지 않은 옵션 | 색만 바꿀 때는 `lowUnselectedForegroundColor`. 글자 전체를 바꾸는 같은 범위의 필드는 없습니다. |
| `disabledTextStyle` | 비활성 그룹의 모든 옵션 | 같은 범위의 필드가 없습니다. |

<a id="접근성-accessibility"></a>

## 접근성

Flutter 는 옵션마다 선택 상태를 알리고, Jaspr Web 은 `role="radiogroup"` 안의 `role="radio"` 로 알립니다.

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은 [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

### 역할

| 플랫폼 | 그룹 | 옵션 |
| --- | --- | --- |
| Flutter | `Wrap` 하나뿐이고 그룹 시맨틱을 만들지 않습니다. | 옵션마다 `Semantics(selected:, inMutuallyExclusiveGroup: true)` 로 칩을 감쌉니다. 활성 옵션은 칩이 버튼이라는 것과 활성 상태도 알립니다. 비활성 옵션에는 버튼 · 비활성 정보가 없습니다. |
| Jaspr Web | 루트 `<div>` 에 `role="radiogroup"` 이 붙습니다. | 칩에 `role="radio"` 와 `aria-checked` 가 붙고, 활성 옵션은 `tabindex="0"` 을 가집니다. 비활성 옵션은 `aria-disabled="true"` 를 가진, 포커스를 받지 않는 `<div>` 입니다. |

Jaspr Web 에서 `attributes` 는 컴포넌트가 붙이는 속성보다 우선합니다. 그룹 루트에 `aria-label` 이나 `aria-labelledby` 를 붙일 수 있고, `role` 을 주면 `radiogroup` 대신 그 값이 붙습니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift` · `Tab` | 활성 옵션을 하나씩 옮겨 다닙니다. 비활성 그룹은 건너뜁니다. |
| `Enter` · `Space` | 포커스된 옵션을 고릅니다. `allowUnselect` 가 켜져 있고 이미 고른 옵션이면 해제합니다. |
| 화살표 | 컴포넌트가 처리하지 않아 선택이 바뀌지 않습니다. Flutter 네이티브 앱에서는 Flutter 의 기본 단축키가 포커스만 옮기고, Flutter Web 의 기본 단축키는 화살표를 스크롤에 씁니다. Jaspr Web 은 화살표로 포커스를 옮기지 않습니다. |
| `Home` · `End` | 처리하지 않습니다. |

### 스크린 리더

- 각 옵션의 이름은 옵션의 `label` 문자열입니다 — 칩 안의 글자로 읽힙니다.
- 선택 상태는 Flutter 에서는 선택됨(selected)으로, Jaspr Web 에서는 `aria-checked` 로 알립니다.
- 비활성 상태는 Jaspr Web 만 `aria-disabled="true"` 로 알립니다. Flutter 의 비활성 옵션은 글자와 선택 상태만 남고, 비활성이라는 것을 알리지 않습니다.
- 그룹에는 이름이 없습니다. 컴포넌트에 그룹 라벨 속성이 없어서, 필요하면 Jaspr Web 은 `attributes: {'aria-label': '크기'}` 를 주고 Flutter 는 `Semantics(container: true, label: '크기', child: ...)` 로 감쌉니다.
- 선택이 바뀐 사실을 따로 알리는 라이브 리전은 없습니다.

### 포커스 관리

그룹은 마운트될 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. 한 옵션만 `Tab` 정지점으로 두는 방식(roving tabindex)이 아니라 활성 옵션 하나하나가 정지점이라, 옵션이 N 개면 그룹을 지나가는 데 `Tab` 을 N 번 눌러야 합니다. 포커스 링은 키보드로 포커스한 칩이 자기 모서리를 따라 그립니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | `radiogroup` · `radio` 역할에서 기대하는 화살표 이동과 하나뿐인 `Tab` 정지점이 없습니다. 스크린 리더는 라디오 그룹이라고 안내하지만 옵션 사이는 `Tab` 으로만 옮겨 갑니다. 이 이동을 켜는 속성은 없습니다. |
| Flutter | 비활성 옵션이 비활성이라고 알려지지 않습니다. 비활성 칩은 누를 수 없는 표시용 칩으로 그려져 버튼 · 활성 정보를 내지 않습니다. |
| Flutter | 라디오 그룹 구조가 없습니다. 옵션은 선택됨과 상호 배타 묶음 정보를 알리지만 그룹 노드가 없어 "3개 중 1번" 같은 위치 안내가 없습니다. 호출자가 `Semantics(container: true, label:)` 로 감싸면 그룹 이름은 붙일 수 있습니다. |
| Jaspr Web | 그룹을 비활성으로 두어도 `radiogroup` 루트에는 `aria-disabled` 가 붙지 않고, 옵션에만 붙습니다. |
| 공통 | `enabled: true`(기본)이고 `onChanged` 가 없으면 옵션이 누를 수 있는 것처럼 보이고 포커스도 받지만 아무 일도 하지 않습니다. |
| 공통 | 옵션 하나만 비활성으로 둘 수 없습니다. |
| 공통 | 고른 옵션은 채움 · 테두리 · 글자 색으로만 구분합니다. Jaspr Web 의 OS 색 강제 모드에서는 이 색들이 시스템 색으로 바뀌어 고른 옵션과 고르지 않은 옵션이 같아 보일 수 있습니다([Chip](/components/chip) 참고). |
| 공통 | 고른 값을 폼에 전달하거나 폼 검증에 참여하는 기능이 없습니다. 폼 값이 필요하면 호출자가 직접 넘기거나 [RadioGroup](/components/radio-group) 을 씁니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 클래스명 | `MultipleChoice<T>` | `MultipleChoice<T>` |
| 루트 | `Wrap`(`spacing` · `runSpacing` 이 `optionSpacing`) | `<div role="radiogroup">`(`inline-flex` · `flex-wrap` · 최대 폭 100%, 간격은 `gap`) |
| 옵션의 의미 | 선택 상태(selected). 활성 옵션은 버튼으로도 알립니다 | `role="radio"` · `aria-checked` |
| 비활성 알림 | 없음 | `aria-disabled="true"` |
| 화살표 키 | 네이티브 앱에서는 기본 단축키가 포커스만 옮기고, Flutter Web 에서는 스크롤에 씁니다 | 포커스를 옮기지 않습니다 |
| 간격의 크기 배율 | 테마의 크기 배율(`scaling`)을 곱합니다 | CSS 변수나 `rem` 으로 그려 브라우저의 글자 크기를 따릅니다 |
| 단계 밖 간격(예: 13)과 밀도 | 밀도에 따라 다음 칸으로 옮겨집니다 | 적은 값 그대로 그려, 밀도가 닿지 않습니다 |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` 가 루트 `<div>` 에 붙습니다 |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. `T` 는 옵션 값의 타입입니다.

### 값과 선택지

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `options` | `List<({T value, String label})>` | 필수 | 선택지 목록. 목록 순서대로 놓습니다. 타입 이름은 `CoreMultipleChoiceOption<T>` 입니다. |
| `value` | `T?` | `null` | 지금 고른 값. `==` 로 같은 값을 가진 옵션을 고른 모양으로 그립니다. `null` 이면 선택이 없습니다. |
| `onChanged` | `ValueChanged<T?>?` | `null` | 다른 옵션을 누르면 그 값을, `allowUnselect` 로 해제하면 `null` 을 받습니다. |

### 활성과 해제

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `enabled` | `bool` | `true` | 그룹 전체의 활성 여부. `onChanged` 유무로 정하지 않습니다. |
| `allowUnselect` | `bool` | `false` | 고른 옵션을 다시 눌러 선택을 비울 수 있는지 |

### 겉모습

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `multipleChoiceStyle` | `CoreMultipleChoiceStyle?` | `null` | 옵션 사이 간격과 옵션 칩의 모양(`chipStyle`)을 덮어씁니다. |

두 플랫폼 모두 `key` 를 받습니다.

### 플랫폼 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | Web 전용. 그룹 루트의 HTML `id` |
| `classes` | `String?` | `null` | Web 전용. 그룹 루트에 덧붙이는 CSS 클래스 |
| `css` | `Styles?` | `null` | Web 전용. 그룹 루트의 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | Web 전용. 그룹 루트의 HTML 속성. `aria-label` 로 그룹 이름을 붙입니다. |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | Web 전용. 그룹 루트의 DOM 이벤트 |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreMultipleChoiceStyle patch)` | `multipleChoiceStyle` 에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다. |
| `copyWith({options, value, onChanged, enabled, ...})` | 바꾼 값으로 사본을 만듭니다. `null` 을 넘기면 기존 값이 남으므로, 이 방법으로는 `value` 를 비울 수 없습니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.multipleChoice` | `CoreMultipleChoiceTheme?` | 앱 전체의 그룹 모양. `style`(`CoreMultipleChoiceStyle?`) 하나를 가집니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreMultipleChoiceStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `optionSpacing` | `double?` | Gap between consecutive options (logical px) — `Wrap.spacing` on Flutter, the root row `gap` on Web. Defaults to [defaultOptionSpacing]. |
| `optionPadding` | `CoreEdgeInsets?` | **Deprecated (since 0.173)** — Use chipStyle.padding — the option is a composed Chip now; the value still reaches the chip until removed. Option padding override. |
| `optionBorderRadius` | `CoreBorderRadius?` | **Deprecated (since 0.173)** — Use chipStyle.borderRadius — the option is a composed Chip now; the value still reaches the chip until removed. Option corner radius override. |
| `optionBorderWidth` | `double?` | **Deprecated (since 0.173)** — Use chipStyle.borderWidth — the option is a composed Chip now; the value still reaches the chip until removed. Option border width override (logical px). |
| `selectedBackgroundColor` | `CoreColor?` | **Deprecated (since 0.173)** — Use chipStyle.backgroundColor on a selected Chip — the option is a composed Chip now; the value still reaches the chip until removed. Selected option background colour override. |
| `selectedTextStyle` | `CoreTextStyle?` | **Deprecated (since 0.173)** — Use chipStyle.labelStyle — the option is a composed Chip now; the value still reaches the chip until removed. Selected option text style override. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `selectedTextColor` field removed). Defaults to [defaultSelectedTextStyle]. |
| `selectedBorderColor` | `CoreColor?` | **Deprecated (since 0.173)** — Use chipStyle.borderColor — the option is a composed Chip now; the value still reaches the chip until removed. Selected option border colour override. |
| `unselectedBackgroundColor` | `CoreColor?` | **Deprecated (since 0.173)** — Use chipStyle.backgroundColor — the option is a composed Chip now; the value still reaches the chip until removed. Unselected option background colour override. |
| `unselectedTextStyle` | `CoreTextStyle?` | **Deprecated (since 0.173)** — Use chipStyle.labelStyle — the option is a composed Chip now; the value still reaches the chip until removed. Unselected option text style override. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `unselectedTextColor` field removed). Defaults to [defaultUnselectedTextStyle]. |
| `unselectedBorderColor` | `CoreColor?` | **Deprecated (since 0.173)** — Use chipStyle.borderColor — the option is a composed Chip now; the value still reaches the chip until removed. Unselected option border colour override. |
| `disabledTextStyle` | `CoreTextStyle?` | **Deprecated (since 0.173)** — Use chipStyle.labelStyle — the option is a composed Chip now; the value still reaches the chip until removed. Disabled option text style override. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `disabledTextColor` field removed). Defaults to [defaultDisabledTextStyle]. |
| `transitionDuration` | `Duration?` | Transition duration override for selection colour changes. Folded into the composed `Chip`'s `transitionDuration` by [chipStyleFor]. |
| `clickableStyle` | `CoreClickableStyle?` | Style for each option's `Clickable` — press scale, durations, focus ring, disabled opacity. [chipStyleFor] puts it into the option `Chip`'s own `clickableStyle`; the `Chip` fills in the rest. |
| `chipStyle` | `CoreChipStyle?` | Style for each option's `Chip`. Laid over [defaultChipStyle] (and the deprecated flat option fields, see [chipStyleFor]) and passed as is to `Chip(chipStyle:)`; the `Chip` fills in the rest. |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 설명 가운데 지금 동작과 다른 것이 세 가지 있습니다. 첫째, 선택이나 활성 여부에 따라 갈리는 이전 필드의 설명이 대신 쓰라고 하는 `chipStyle.backgroundColor` · `chipStyle.borderColor` · `chipStyle.labelStyle` 은 모든 옵션에 같은 값을 씁니다(위 [이전 필드](/components/multiple-choice#이전-필드) 표). 둘째, `clickableStyle` 설명의 비활성 불투명도는 MultipleChoice 에 닿지 않습니다 — 비활성 옵션은 누르는 영역 없이 그려져 `clickableStyle` 을 읽지 않습니다. 셋째, `selectedTextStyle` · `unselectedTextStyle` · `disabledTextStyle` 설명 끝의 `Defaults to …` 문장은 맞지 않습니다. 거기 적힌 기본값은 읽지 않으며, 이 필드를 주지 않으면 라벨은 칩의 `labelMedium` 글자와 상태별 색으로 그려집니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card component="radio-group" props="value=pro;orientation=horizontal" title="RadioGroup">

라디오 버튼으로 하나를 고릅니다. 화살표 키로 옮겨 다닙니다.

</Card>
<Card component="select" props="placeholder=크기 선택" title="Select">

선택지를 드롭다운에 접어 두고 하나를 고릅니다.

</Card>
<Card demo="multiple-choice/related-chip-group" title="ChipGroup">

칩으로 여러 개를 고릅니다.

</Card>
</Cards>
