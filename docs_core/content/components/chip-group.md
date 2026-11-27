---
title: ChipGroup
description: 칩 여러 개를 늘어놓고 그중 하나 또는 여러 개를 고르게 하는 묶음입니다. 줄바꿈 · 가로 스크롤 배치와 선택 개수 제한을 고를 수 있고, 칩의 모양은 직접 정합니다.
category: display
platforms: [flutter, web]
related: [chip, chip-input, radio-group]
tags: [selection, filter, group, multi-select]
template: v2
source: display/chip_group
---

# ChipGroup

<a id="live-preview"></a>

## 플레이그라운드

배치와 선택 규칙을 바꿔 보며 칩을 눌러 보고, 만들어진 코드를 복사하세요. 아무 값도 주지 않은 `ChipGroup` 은 여러 개를 고르는(`multi`) 줄바꿈(`wrap`) 묶음입니다.

<Playground component="chip-group" />

<Note>

컨트롤을 바꾸면 미리보기의 선택은 그 설정의 처음 값으로 돌아갑니다. 미리보기는 폭 280 상자 안에 놓았고, 코드에는 그 상자가 없습니다. `saveTopics` 는 고른 집합(`Set<String>`)을 받는 여러분의 함수 자리입니다. `selectionHint` 의 글은 컴포넌트가 만들지 않으며 직접 넘깁니다.

</Note>

## 구조

`ChipGroup` 은 선택한 항목을 기억하고 선택 규칙을 지키면서 칩을 늘어놓습니다. 배경과 테두리는 그리지 않습니다. 칩도 직접 만들지 않고, `chipBuilder` 가 돌려준 것을 그대로 놓습니다.

<Anatomy demo="chip-group/anatomy">
<AnatomyItem part="container" side="top" name="Container">

헤더와 칩 영역을 위아래로 놓습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=title]" side="left" name="title">

묶음의 제목 슬롯. 선택 사항입니다. 기본 모양은 15 SemiBold, `onSurface` 입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=hint]" side="right" name="selectionHint">

제목 아래의 안내 슬롯. 선택 사항입니다. 기본 모양은 12, `onSurfaceVariant` 입니다.

</AnatomyItem>
<AnatomyItem select="div:has(> [role=button])" side="right" name="칩 영역">

`layout` 에 따라 줄바꿈하거나 한 줄로 가로 스크롤합니다.

</AnatomyItem>
<AnatomyItem select="[role=button]" side="left" name="chip">

`chipBuilder` 가 항목마다 돌려주는 것입니다. 이 그림에서는 `Chip` 입니다.

</AnatomyItem>
</Anatomy>

- **헤더** — `title` 과 `selectionHint` 중 하나라도 있으면 생깁니다. 제목 아래에 안내를 두고 시작 쪽에 맞추며, 둘 다 있을 때만 그 사이를 2 띄웁니다.
- **헤더와 칩 사이** — 헤더가 있으면 8 을 띄웁니다. 둘 다 없으면 헤더와 이 간격 모두 그리지 않습니다.
- **글 모양** — 두 슬롯의 기본 글 모양은 스타일을 따로 주지 않은 `Text` 에 적용됩니다. `Text` 에 직접 준 글 모양이 있으면 그 값이 우선합니다.

<a id="예제"></a>

## 칩 만들기

`items` 와 `chipBuilder` 는 필수입니다. 묶음을 그릴 때 `chipBuilder` 가 항목마다 불리며, 항목과 함께 상태 셋을 받습니다. 돌려준 위젯(Web 은 컴포넌트)이 그대로 칩이 되므로 `Chip` 의 색 · 크기 · 아이콘은 여기에서 정합니다.

| 받는 값 | 타입 | 연결하지 않으면 |
| --- | --- | --- |
| `selected` | `bool` | 골라도 칩이 선택된 모양으로 바뀌지 않습니다. |
| `enabled` | `bool` | 개수 제한에 닿아도 칩이 비활성으로 보이지 않습니다. 제한은 그룹이 지키므로 더 골라지지는 않습니다. |
| `onTap` | `void Function()` | 눌러도 선택이 바뀌지 않습니다. `Chip` 은 `onTap` 이 없으면 표시 전용이 되어 버튼 역할과 Tab 정지점도 없습니다. |

```dart
ChipGroup<String>(
  items: const ['디자인', '프런트엔드', '백엔드'],
  onChanged: (next) => print(next),
  chipBuilder: (item, {required selected, required enabled, required onTap}) => Chip(
    label: item,
    selected: selected,
    enabled: enabled,
    chipColor: CoreChipColor.primary,
    onTap: onTap,
  ),
)
```

Flutter와 Web 코드가 같습니다. 여러 곳에서 같은 칩을 쓰려면 `ChipGroupItemBuilder<String>` 타입의 함수로 빼 둡니다. 이 타입 이름도 두 플랫폼에 있습니다. 아래 예제의 `buildChip` 이 이 함수입니다.

```dart
final ChipGroupItemBuilder<String> buildChip =
    (item, {required selected, required enabled, required onTap}) => Chip(
          label: item,
          selected: selected,
          enabled: enabled,
          chipColor: CoreChipColor.primary,
          onTap: onTap,
        );
```

### 항목 타입

항목은 문자열이 아니어도 됩니다. 선택은 `Set<T>` 로 기억하므로 같은 항목인지는 `==` 와 `hashCode` 로 가립니다.

- 서로 같다고 비교되는 항목이 `items` 에 두 번 있으면 선택 상태를 함께 씁니다.
- 화면을 다시 그릴 때마다 항목 객체를 새로 만든다면 `==` 와 `hashCode` 를 정의해야 선택이 새 객체에도 이어집니다.

```dart
enum Topic { design, frontend, backend }

ChipGroup<Topic>(
  items: Topic.values,
  chipBuilder: (topic, {required selected, required enabled, required onTap}) => Chip(
    label: switch (topic) {
      Topic.design => '디자인',
      Topic.frontend => '프런트엔드',
      Topic.backend => '백엔드',
    },
    selected: selected,
    enabled: enabled,
    onTap: onTap,
  ),
)
```

## 레이아웃

`layout` 으로 칩을 놓는 방식을 고릅니다. 주지 않으면 `wrap` 입니다.

<VariantRow name="wrap" component="chip-group" props="layout=wrap">

부모 너비를 넘으면 다음 줄로 넘깁니다. 칩 사이는 `itemSpacing`, 줄 사이는 `rowSpacing` 이고 기본값은 둘 다 8 입니다.

</VariantRow>

<VariantRow name="scroll" component="chip-group" props="layout=scroll">

한 줄에 놓고 넘치는 만큼 가로로 스크롤합니다. 칩 사이는 `itemSpacing` 입니다.

</VariantRow>

### 가장자리 흐림

`scroll` 배치는 [FadeScroll](/components/fade-scroll) 로 그리며 스크롤바를 보이지 않습니다. 가장자리 흐림은 칩 위에 색을 덮는 것이 아니라 칩 자체를 가장자리에서 서서히 지우는 마스크입니다.

- 시작 쪽 흐림은 스크롤해서 앞의 내용이 가려졌을 때 생깁니다.
- 끝 쪽 흐림은 끝까지 스크롤하면 사라집니다.
- 칩이 모두 들어가면 흐림이 없습니다.
- `showFade: false` 는 흐림만 끕니다. 가로 스크롤은 그대로입니다.
- 흐림의 폭은 `fadeWidth` 이고 기본값은 32 입니다.

`showFade` 와 `fadeWidth` · `fadeColor` 는 `wrap` 배치에서는 쓰지 않습니다.

<Preview demo="chip-group/scroll-fade" />

```dart
ChipGroup<String>(
  items: const ['디자인', '프런트엔드', '백엔드', '모바일', '데이터', 'DevOps'],
  layout: CoreChipGroupLayout.scroll,
  showFade: false,
  chipBuilder: buildChip,
)
```

<a id="동작-스펙-behavior"></a>

## 상태

선택은 `ChipGroup` 이 직접 갖고 있습니다. 칩을 누르면 선택 규칙을 적용해 다음 선택을 정하고, 칩마다 `selected` 와 `enabled` 를 다시 계산해 `chipBuilder` 에 넘깁니다. hover · 눌림 · 포커스 모양은 `chipBuilder` 가 돌려준 칩이 그립니다.

### 선택 모드

`selectionMode` 를 주지 않으면 `multi` 입니다.

| `selectionMode` | 고르지 않은 칩을 누르면 | 고른 칩을 누르면 |
| --- | --- | --- |
| `multi` | 선택에 더합니다. | 선택에서 뺍니다. |
| `single` | 이전 선택을 지우고 그 항목 하나를 고릅니다. | 선택을 해제합니다. |

선택이 모드에 맞지 않아도 그룹이 잘라내지 않습니다. `single` 에 두 항목을 처음 값으로 주거나, `multi` 에서 여러 개를 고른 뒤 `single` 로 바꾸면 칩을 누르기 전까지 여러 항목이 선택된 채입니다. 그때 고르지 않은 칩을 누르면 그 하나만 남습니다.

### 선택 해제 막기

- **`allowDeselect: false`** — `single` 에서만 효과가 있습니다. 고른 칩을 다시 눌러도 선택이 남습니다. 다른 칩을 눌러 바꾸는 것은 됩니다.
- **`minSelection`** — 고른 개수가 이 값 이하이면 고른 칩을 눌러도 빠지지 않습니다. 모자란 개수를 저절로 채우지는 않으므로 처음 선택은 이 값보다 적을 수 있습니다. `single` 에서 다른 칩으로 바꾸는 것은 해제가 아니므로 막지 않습니다.

두 규칙으로 막힌 칩은 비활성이 되지 않고 `enabled` 가 `true` 로 남습니다.

<Note>

`minSelection` 때문에 해제가 막힌 탭에서도 `onChanged` 는 내용이 같은 집합으로 불립니다. 값이 실제로 바뀔 때만 해야 하는 일(저장 · 요청)은 이전 값과 비교한 뒤 실행하세요. `allowDeselect: false` 만으로 막힌 탭은 `onChanged` 를 부르지 않습니다.

</Note>

```dart
// 하나를 고르면 해제할 수 없고, 다른 항목으로만 바꿉니다.
ChipGroup<String>(
  items: const ['최신순', '인기순', '가격순'],
  initialValue: const {'최신순'},
  selectionMode: CoreChipGroupSelectionMode.single,
  allowDeselect: false,
  chipBuilder: buildChip,
)
```

### 선택 개수 제한

`maxSelection` 은 고를 수 있는 항목 수입니다. 그 수에 닿으면 고르지 않은 칩을 눌러도 선택이 바뀌지 않고 `onChanged` 도 불리지 않습니다. 이미 고른 칩은 해제할 수 있습니다(`minSelection` 은 그대로 적용됩니다). `maxSelectionBehavior` 는 그동안 나머지 칩의 `enabled` 를 정합니다.

| `maxSelectionBehavior` | 고르지 않은 칩의 `enabled` | 눌렀을 때 |
| --- | --- | --- |
| `disableRest` (기본) | `false` — 연결한 칩은 비활성으로 보입니다. | 선택이 바뀌지 않습니다. |
| `silentIgnore` | `true` — 평소 모양입니다. | 선택이 바뀌지 않습니다. |

<Preview demo="chip-group/max-selection" />

- 처음 선택이 제한보다 많아도 잘라내지 않습니다.
- `items` 에서 빠진 항목도 선택 집합에는 남아 `maxSelection` 과 `minSelection` 의 개수에 들어갑니다.
- `single` 에서는 `maxSelection` 을 주지 마세요. `maxSelection: 1` 이면 하나를 고른 뒤 다른 칩으로 바로 바꿀 수 없어 먼저 해제해야 합니다. `allowDeselect: false` 까지 주면 사용자는 선택을 바꿀 수 없습니다.

### 선택 값 바꾸기

`initialValue` 는 묶음이 처음 만들어질 때의 선택입니다. 주지 않으면 빈 선택입니다. 그 뒤에는 부모가 다시 그릴 때 **직전에 넘긴 것과 다른 객체**인 `initialValue` 를 넘기면 선택이 그 값으로 바뀝니다. `null` 이나 직전과 같은 객체는 새 값으로 보지 않습니다. 그래서 값을 바꿀 때는 넘긴 집합을 고치지 말고 새 집합을 만들어 넘깁니다.

`onChanged` 는 칩을 누른 결과로 정해진 다음 선택을 받습니다. `initialValue` 로 선택을 바꿀 때는 불리지 않습니다. 부모가 값을 저장하지 않아도 그룹의 선택은 이미 바뀌어 있으며, `onChanged` 를 주지 않아도 선택은 동작합니다. 받은 집합은 그룹이 쓰는 객체 그대로이므로 직접 고치지 말고, 고쳐야 하면 복사해서 씁니다.

부모가 값을 함께 갖는 방법은 받은 집합을 저장해 다시 `initialValue` 로 넘기는 것입니다.

```dart
// State 클래스 안
Set<String> _topics = const {'디자인'};

// build 안
ChipGroup<String>(
  items: const ['디자인', '프런트엔드', '백엔드'],
  initialValue: _topics,
  onChanged: (next) => setState(() => _topics = next),
  chipBuilder: buildChip,
)

// 선택 비우기 — 새로 만든 빈 집합을 넘깁니다.
setState(() => _topics = <String>{});
```

`build` 안에서 만든 집합 리터럴을 바로 넘기면 부모가 다시 그릴 때마다 새 객체가 되어 사용자의 선택이 그 값으로 되돌아갑니다. 처음 한 번만 정할 값이면 `const` 로 쓰거나 `State` 에 보관합니다.

```dart
// 부모가 다시 그려질 때마다 {'디자인'} 으로 되돌아갑니다.
initialValue: {'디자인'},

// 늘 같은 객체라 처음 값으로만 쓰입니다.
initialValue: const {'디자인'},
```

반대로 `const` 집합은 늘 같은 객체이므로, 직전에도 같은 `const` 집합을 넘겼다면 다시 넘겨도 선택이 바뀌지 않습니다.

### 묶음 전체 비활성

묶음 전체를 끄는 파라미터는 없습니다. 칩에 넘기는 `enabled` 에 조건을 함께 겁니다.

```dart
ChipGroup<String>(
  items: topics,
  chipBuilder: (item, {required selected, required enabled, required onTap}) => Chip(
    label: item,
    selected: selected,
    enabled: enabled && !isSaving,
    onTap: onTap,
  ),
)
```

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 태그나 카테고리에서 하나 또는 여러 개를 고를 때
- 필터 조건을 칩으로 펼쳐 둘 때
- 선택지를 가로로 스크롤하는 한 줄로 보여 줄 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 켜고 끄는 설정 하나 | [Toggle](/components/toggle) · [SwitchField](/components/switch-field) |
| 라디오 버튼 모양으로 하나만 고를 때 | [RadioGroup](/components/radio-group) |
| 펼침 목록에서 하나를 고를 때 | [Select](/components/select) |
| 사용자가 글을 입력해 칩을 새로 만들 때 | [ChipInput](/components/chip-input) |
| 선택 규칙 없이 칩 하나를 둘 때 | [Chip](/components/chip) |

<a id="do"></a>
<a id="dont"></a>

### 칩 상태 연결과 제한 안내

<Cards columns="2">
<Card demo="chip-group/do-forward" tone="do" eyebrow="이렇게 하세요">

`selected` · `enabled` · `onTap` 을 모두 칩에 넘깁니다. 개수 제한에 닿으면 나머지 칩이 비활성으로 보입니다.

</Card>
<Card demo="chip-group/dont-forward" tone="dont" eyebrow="이렇게 하지 마세요">

`enabled` 를 빠뜨리면 더 고를 수 없는 칩이 누를 수 있는 것처럼 보입니다.

</Card>
<Card demo="chip-group/do-hint" tone="do" eyebrow="이렇게 하세요">

`maxSelection` 을 쓰면 `selectionHint` 로 제한을 글로 알립니다.

</Card>
<Card demo="chip-group/dont-hint" tone="dont" eyebrow="이렇게 하지 마세요">

안내 없이 두면 칩이 비활성이 된 이유를 알 수 없습니다. 그룹은 이유를 따로 알려 주지 않습니다.

</Card>
</Cards>

```dart
ChipGroup<String>(
  items: topics,
  maxSelection: 3,
  title: Text('관심 분야'),
  selectionHint: Text('최대 3개까지 고를 수 있어요'),
  chipBuilder: buildChip,
)
```

## 배치

묶음의 너비는 부모가 정합니다. `wrap` 은 그 너비에서 줄을 바꾸고 `scroll` 은 그 너비 안에서 스크롤하므로, 두 배치 모두 너비 제한이 있는 자리에 둡니다.

- **Flutter** — `Row` 에 바로 넣으면 너비 제한이 없어 `wrap` 은 줄을 바꾸지 않고 `scroll` 은 스크롤하지 않습니다. 칩이 넘치면 `Row` 가 넘칩니다. `Expanded` 로 감싸 남은 너비를 넘깁니다.
- **Web** — 루트는 `inline-flex` 라 일반 블록 부모 안에서는 내용만큼의 너비를 쓰고, `max-width: 100%` 와 `min-width: 0` 으로 부모를 넘지 않습니다.

<Code language="dart" title="Flutter — Row 안의 가로 스크롤">
Row(
  children: [
    Text('필터'),
    Gap.space12(),
    Expanded(
      child: ChipGroup<String>(
        items: topics,
        layout: CoreChipGroupLayout.scroll,
        chipBuilder: buildChip,
      ),
    ),
  ],
)
</Code>

## 테마와 스타일

간격 · 가장자리 흐림 · 헤더의 글 모양은 `chipGroupStyle`(`CoreChipGroupStyle`) 하나로 바꿉니다. 칩의 색 · 크기 · 모양은 여기에 없습니다. `chipBuilder` 가 돌려주는 [Chip](/components/chip) 의 파라미터와 `chipStyle`, 앱 전체라면 `CoreComponentTheme.chip` 으로 바꿉니다.

| 필드 | 바꾸는 것 | 기본값 |
| --- | --- | --- |
| `itemSpacing` | 칩 사이 가로 간격 | 8 |
| `rowSpacing` | `wrap` 의 줄 사이 간격 | 8 |
| `titleHintGapStyle` | 제목과 안내 사이 | 2 |
| `titleGapStyle` | 헤더와 칩 사이 | 8 |
| `titleTextStyle` | 제목 글 모양 | `labelXl`(15) · SemiBold · `onSurface` |
| `selectionHintTextStyle` | 안내 글 모양 | `bodyXs`(12) · `onSurfaceVariant` |
| `fadeWidth` | `scroll` 의 흐림 폭 | 32 |
| `fadeColor` | `scroll` 의 흐림 마스크 색 (아래 API 의 설명 참고) | 플랫폼 차이 섹션 참고 |

### 값이 정해지는 순서

아래로 갈수록 우선합니다.

```text
CoreChipGroupStyle.default*     // 디자인 시스템 기본값
  → CoreChipGroupTheme.style    // 프로젝트 공통 (CoreComponentTheme.chipGroup)
  → chipGroupStyle              // 인스턴스별
```

- 지정한 필드만 덮고 나머지는 앞 단계의 값이 남습니다. 간격 · 글 모양 필드는 그 안의 값도 하나씩 합칩니다. 예를 들어 `titleTextStyle` 에서 글 역할만 바꾸면 SemiBold 굵기는 남습니다.
- `showFade: false` 는 스타일의 `fadeWidth` 와 상관없이 흐림을 끕니다.

<Note>

`CoreChipGroupTheme` 에는 `layout` 과 `selectionMode` 필드도 있지만, 지금은 두 플랫폼 모두 읽지 않습니다. 테마에 지정해도 달라지지 않으므로 두 값은 `ChipGroup` 에 직접 넘깁니다.

</Note>

### 사용 예

<Preview demo="chip-group/styled" />

<Split>

<Code language="dart" title="묶음 하나만 바꾸기">
ChipGroup<String>(
  items: topics,
  title: Text('관심 분야'),
  chipGroupStyle: CoreChipGroupStyle(
    itemSpacing: CoreSpace.space12,
    rowSpacing: CoreSpace.space12,
    titleGapStyle: CoreGapStyle(size: CoreSpace.space12),
    titleTextStyle: CoreTextStyle.token(
      CoreTextStyles.labelLarge,
      color: CoreColor.token(CoreColors.onSurfaceVariant),
    ),
  ),
  chipBuilder: buildChip,
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    chipGroup: CoreChipGroupTheme(
      style: CoreChipGroupStyle(
        itemSpacing: CoreSpace.space12,
        rowSpacing: CoreSpace.space12,
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `ChipGroup` 에 `withStyle` 을 이어 `chipGroupStyle` 을 덧붙일 수 있습니다. 원래 묶음은 그대로 두고 스타일을 합친 새 묶음을 돌려줍니다. 같은 필드는 나중에 덧붙인 값이 이기고, 지정하지 않은 필드는 앞의 값이 남습니다. 아래 예제는 간격과 제목 글 모양을 바꿉니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ChipGroupChainExample extends StatefulWidget {
  const ChipGroupChainExample({super.key});

  @override
  State<ChipGroupChainExample> createState() => _ChipGroupChainExampleState();
}

class _ChipGroupChainExampleState extends State<ChipGroupChainExample> {
  Set<String> _selected = const {'Flutter'};

  @override
  Widget build(BuildContext context) {
    return ChipGroup<String>(
      items: const ['Flutter', 'React', 'Swift', 'Kotlin'],
      initialValue: _selected,
      selectionMode: CoreChipGroupSelectionMode.multi,
      onChanged: (next) => setState(() => _selected = next),
      chipBuilder: (item, {required selected, required enabled, required onTap}) => Chip(
        label: item,
        selected: selected,
        enabled: enabled,
        chipColor: CoreChipColor.primary,
        onTap: onTap,
      ),
    ).withStyle(
      const CoreChipGroupStyle(
        itemSpacing: CoreSpace.space12,
        rowSpacing: CoreSpace.space12,
        titleGapStyle: CoreGapStyle(size: CoreSpace.space8),
        titleTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelLarge,
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class ChipGroupChainExample extends StatefulComponent {
  const ChipGroupChainExample({super.key});

  @override
  State<ChipGroupChainExample> createState() => _ChipGroupChainExampleState();
}

class _ChipGroupChainExampleState extends State<ChipGroupChainExample> {
  Set<String> _selected = const {'Flutter'};

  @override
  Component build(BuildContext context) {
    return ChipGroup<String>(
      items: const ['Flutter', 'React', 'Swift', 'Kotlin'],
      initialValue: _selected,
      selectionMode: CoreChipGroupSelectionMode.multi,
      onChanged: (next) => setState(() => _selected = next),
      chipBuilder: (item, {required selected, required enabled, required onTap}) => Chip(
        label: item,
        selected: selected,
        enabled: enabled,
        chipColor: CoreChipColor.primary,
        onTap: onTap,
      ),
    ).withStyle(
      const CoreChipGroupStyle(
        itemSpacing: CoreSpace.space12,
        rowSpacing: CoreSpace.space12,
        titleGapStyle: CoreGapStyle(size: CoreSpace.space8),
        titleTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelLarge,
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="접근성-accessibility"></a>

## 접근성

`ChipGroup` 은 선택 규칙과 배치를 맡고, 역할 · 이름 · 선택 상태는 붙이지 않습니다. 누르고 포커스를 받는 대상은 `chipBuilder` 가 돌려준 칩입니다. 아래 칩에 관한 설명은 `Chip` 을 돌려줄 때의 것입니다.

### 역할

| 대상 | Flutter | Web |
| --- | --- | --- |
| 묶음 | `ChipGroup` 이 직접 붙이는 `Semantics` 가 없습니다. | role 없는 `<div>` |
| `title` · `selectionHint` | 넘긴 위젯 그대로입니다. | 넘긴 컴포넌트를 감싼 role 없는 `<div>` |
| 누를 수 있는 칩 (`onTap`) | `Semantics(button: true, enabled: …)` | `role="button"` |
| 표시 전용 칩 (`onTap` 없음) | 버튼 시맨틱이 없습니다. | role 없는 `<div>` |

묶음에는 `group` · `listbox` · `radiogroup` 역할과 `aria-multiselectable` 이 모두 없고, `title` 은 묶음의 접근 가능한 이름이 되지 않습니다. 이름이 필요하면 직접 붙입니다. Flutter 는 바깥을 `Semantics` 로 감싸고, Web 은 `attributes` 로 루트에 역할과 이름을 줍니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Semantics(
  container: true,
  explicitChildNodes: true,
  label: '관심 분야',
  child: ChipGroup<String>(
    items: topics,
    chipBuilder: buildChip,
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
ChipGroup<String>(
  items: topics,
  attributes: const {'role': 'group', 'aria-label': '관심 분야'},
  chipBuilder: buildChip,
)
```

  </TabItem>
</Tabs>

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift+Tab` | 누를 수 있는 칩마다 정지점이 하나씩 있습니다. 비활성 칩은 건너뜁니다(Flutter 는 기본 탐색 방식일 때). |
| `Enter` · `Space` | 포커스한 칩의 `onTap` 을 실행합니다. 눌렀을 때와 같은 선택 규칙이 적용됩니다. |
| 방향키 | `ChipGroup` 은 방향키를 처리하지 않습니다. 네이티브 Flutter 앱에서는 `shortcuts` 를 바꾸지 않았다면 프레임워크의 기본 단축키가 그 방향의 컨트롤로 포커스를 옮깁니다. |

`Enter` · `Space` 동작은 묶음이 아니라 `Chip` 의 것입니다. 누를 수 없는 위젯을 돌려주면 그룹이 대신 키 동작을 더하지 않습니다. Web 의 `onKeyDown` · `onKeyUp` 은 루트 `<div>` 에 연결되므로, 칩에서 올라오는 키 이벤트를 여기에서 받을 수 있습니다.

### 스크린 리더

- **제목과 안내** — `title` 과 `selectionHint` 는 칩과 프로그램으로 연결되지 않은 별개의 내용입니다.
- **선택 상태** — 그룹은 `selected` 를 `chipBuilder` 에 넘기기만 합니다. `Chip` 은 이 값으로 모양만 바꾸고, `aria-pressed` · `aria-selected` 나 Flutter 의 `selected` 시맨틱을 붙이지 않습니다.
- **비활성** — `disableRest` 로 막힌 칩에 `enabled` 를 넘기면 Web 은 `aria-disabled="true"`, Flutter 는 `Semantics(enabled: false)` 로 알립니다. 막힌 이유는 전달하지 않습니다.
- **안내되지 않는 것** — 선택 모드, 고른 개수, `minSelection` · `maxSelection` 규칙은 그룹이 알리지 않습니다. 선택 변화를 알리는 라이브 영역도 없습니다.

#### 선택 상태 알리기

선택 상태는 `chipBuilder` 에서 직접 실어 주세요.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
ChipGroup<String>(
  items: topics,
  chipBuilder: (item, {required selected, required enabled, required onTap}) => Semantics(
    selected: selected,
    child: Chip(
      label: item,
      selected: selected,
      enabled: enabled,
      onTap: onTap,
    ),
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
ChipGroup<String>(
  items: topics,
  chipBuilder: (item, {required selected, required enabled, required onTap}) => Chip(
    label: item,
    selected: selected,
    enabled: enabled,
    onTap: onTap,
    attributes: {'aria-pressed': '$selected'},
  ),
)
```

  </TabItem>
</Tabs>

이름 붙이기와 선택 상태 모두, 대상 기기의 보조 기술에서 어떻게 읽히는지 확인하세요.

### 포커스 관리

- 묶음은 화면에 나타날 때나 선택이 바뀔 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다.
- 묶음은 자신의 `FocusNode` 나 `tabindex` 를 만들지 않습니다. 포커스 범위나 탐색 묶음도 만들지 않고, 칩 하나만 Tab 정지점으로 두는 방식(roving `tabindex`)도 쓰지 않습니다.
- `chipBuilder` 에서 `enabled` 를 넘기면, `disableRest` 로 제한에 닿았을 때 고르지 않은 칩이 비활성이 되어 Tab 순서에서 빠집니다. `silentIgnore` 는 칩의 활성 상태를 바꾸지 않습니다.
- 포커스 링은 칩이 그립니다. `scroll` 배치에서는 이 링의 일부가 잘릴 수 있습니다(알려진 제약).

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 그룹 역할과 접근 가능한 이름이 없습니다. 위의 방법으로 직접 붙입니다. |
| 공통 | `Chip` 은 선택 상태를 보조 기술에 전달하지 않습니다. |
| 공통 | 칩의 역할 · 키보드 · 포커스는 `chipBuilder` 가 돌려준 것에 달려 있습니다. 접근할 수 없는 것을 돌려줘도 그룹이 보완하지 않습니다. |
| 공통 | 제한이나 해제 규칙 때문에 선택이 바뀌지 않아도 그룹은 따로 알리지 않습니다. 비활성이 아닌 칩은 평소처럼 누름에 반응합니다. |
| 공통 | 묶음만의 방향키 이동이 없고 칩들을 Tab 정지점 하나로 묶지도 않습니다. 활성 칩이 많으면 그만큼 Tab 정지점이 늘어납니다. |
| 공통 | `scroll` 배치는 스크롤바를 보이지 않으며, 스크롤 버튼이나 스크롤 키를 따로 더하지 않습니다. |
| 공통 | `scroll` 배치는 칩 줄을 스크롤 영역에서 잘라냅니다. `Chip` 의 포커스 링은 칩 바깥에 그려지므로 위아래가 잘리고, 영역의 양 끝에 닿은 칩은 그쪽 옆도 잘립니다. Web 은 `scroll` 배치면 늘 그렇고, Flutter 는 칩이 영역을 넘칠 때 그렇습니다. 링이 온전히 보여야 하면 `wrap` 배치를 씁니다. |
| Flutter | `scroll` 배치의 줄은 마우스 드래그로 움직이지 않습니다. 끌기는 터치 · 스타일러스 · 트랙패드를 받습니다. |

`ChipGroup` 에는 자체 애니메이션이 없습니다. 칩의 전환은 [Chip](/components/chip) 을 참고하세요. 모든 컴포넌트에 공통인 접근성 기준은 [전역 접근성 축](/accessibility) 에 정리되어 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`ChipGroup` 의 파라미터 이름 · 기본값 · 선택 규칙은 두 플랫폼이 같습니다. 다른 점은 아래와 같습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 슬롯 · 칩 타입 | `Widget` | `Component` |
| 루트 | 헤더가 있으면 `Column`, 없으면 칩 영역이 곧 루트입니다. | 헤더가 없어도 `inline-flex` 세로 `<div>` 가 감쌉니다. |
| `wrap` 배치 | `Wrap` 의 `spacing` · `runSpacing` | flex-wrap `<div>` 의 `column-gap` · `row-gap` |
| `scroll` 배치 | `FadeScroll` 안의 `Row` | `FadeScroll` 안의 가로 flex `<div>` |
| `itemSpacing` · `rowSpacing` | 테마의 밀도 설정으로 값을 옮긴 뒤 `theme.scaling` 을 곱합니다. | 간격 단계에 있는 값은 `--coui-space-*` 변수로 써서 밀도 설정과 변수 덮어쓰기를 따릅니다. 단계에 없는 값은 지정한 크기 그대로 `rem` 으로 씁니다. |
| 흐림을 그리는 방법 | `ShaderMask` | CSS `mask-image` |
| `fadeColor` 를 주지 않았을 때의 마스크 색 | `surface` | `FadeScroll` 의 `gradient` — `CoreComponentTheme.fadeScroll` 에 지정한 값이 있으면 그 값, 없으면 `onSurface` → 투명 |
| `fadeWidth` 의 배율 | `theme.scaling` 이 두 번 곱해집니다. `1` 이면 차이가 없습니다. | 지정한 값을 CSS px 로 씁니다. |
| 스크롤 위치를 재기 전 | 첫 프레임에는 흐림이 없습니다. | 서버에서 그린 화면처럼 위치를 재기 전에는 끝 쪽 흐림을 먼저 그립니다. |
| `scroll` 의 항목 제약 | 줄의 높이를 `IntrinsicHeight` 로 정합니다. `LayoutBuilder` 는 이 계산을 지원하지 않으므로 항목에 쓰지 않습니다. | 해당 없음 |
| HTML 속성과 DOM 이벤트 | 없음 | 루트 `<div>` 에 붙습니다(API 의 웹 전용 표). |

<a id="props-parameters"></a>

## API

`항목과 선택` · `배치와 모양` 의 속성은 Flutter와 Jaspr Web이 같습니다. Web 에만 있는 속성은 `웹 전용` 에 따로 적었습니다. `T` 는 항목의 타입, `W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다.

### 항목과 선택

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `items` | `List<T>` | 필수 | 칩으로 그릴 항목. 목록 순서대로 놓습니다. |
| `chipBuilder` | `ChipGroupItemBuilder<T>` | 필수 | 항목마다 칩을 만듭니다. `selected` · `enabled` · `onTap` 을 받습니다. `CoreChipGroupItemBuilder<T, W>` 의 플랫폼별 이름입니다. |
| `selectionMode` | `CoreChipGroupSelectionMode?` | `null` (`multi`) | `multi` · `single` |
| `initialValue` | `Set<T>?` | `null` (빈 선택) | 처음 선택. 직전과 다른 객체를 다시 넘기면 선택을 바꿉니다. |
| `onChanged` | `void Function(Set<T>)?` | `null` | 칩을 누른 결과로 정해진 선택을 받습니다. |
| `allowDeselect` | `bool` | `true` | `single` 에서 고른 칩을 다시 눌러 해제할 수 있는지 |
| `minSelection` | `int?` | `null` | 고른 개수가 이 값 이하이면 해제를 막습니다. |
| `maxSelection` | `int?` | `null` | 고를 수 있는 항목 수. `null` 이면 개수 제한이 없습니다. |
| `maxSelectionBehavior` | `CoreChipGroupMaxBehavior?` | `null` (`disableRest`) | 제한에 닿았을 때 `disableRest` · `silentIgnore` |

### 배치와 모양

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `layout` | `CoreChipGroupLayout?` | `null` (`wrap`) | `wrap` · `scroll` |
| `showFade` | `bool` | `true` | `scroll` 의 가장자리 흐림 |
| `title` | `W?` | `null` | 칩 위의 제목 |
| `selectionHint` | `W?` | `null` | 제목 아래의 안내. 제목 없이도 쓸 수 있습니다. |
| `chipGroupStyle` | `CoreChipGroupStyle?` | `null` | 간격 · 흐림 · 헤더 글 모양 덮어쓰기 |

`copyWith` 는 일부 값만 바꾼 새 묶음을 돌려주며, `null` 을 넘긴 값은 기존 값이 남습니다. `withStyle` 은 `chipGroupStyle` 에 값을 덧붙입니다.

### 웹 전용

모두 묶음의 루트 `<div>` 에 닿습니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `attributes` | `Map<String, String>?` | `null` | HTML 속성 — `role`, `aria-label`, `data-*`, 테스트 id |
| `id` · `classes` · `css` | `String?` · `String?` · `Styles?` | `null` | 루트의 id 와 배치용 클래스 · 스타일 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 이름으로 거는 DOM 이벤트 |
| `onClick` · `onMouseEnter` · `onMouseLeave` | `UiMouseEventHandler?` | `null` | 마우스 이벤트. 칩의 클릭도 루트까지 올라옵니다. |
| `onKeyDown` · `onKeyUp` | `UiKeyboardEventHandler?` | `null` | 키 이벤트. 칩에서 올라온 것도 받습니다. |
| `onInput` · `onChange` | `UiInputEventHandler?` | `null` | 지금은 여기에 넘긴 함수가 불리지 않습니다. 선택 변경은 `onChanged` 로, 다른 DOM 이벤트는 `eventHandlers` 로 받습니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreChipGroupStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `fadeWidth` | `double?` | Edge fade width in scroll layout (logical px, pre-scaling). |
| `fadeColor` | `CoreColor?` | Edge fade colour override (scroll layout). |
| `itemSpacing` | `double?` | Horizontal gap between sibling chips (logical px, pre-scaling), forwarded to `Wrap.spacing` / `Row.spacing` (Flutter) and `column-gap` (Web). Native paint-API scalar — not a `Gap`. |
| `rowSpacing` | `double?` | Vertical gap between rows in wrap layout (logical px, pre-scaling), forwarded to `Wrap.runSpacing` (Flutter) / `row-gap` (Web). |
| `titleHintGapStyle` | `CoreGapStyle?` | Gap between the title line and the selection-hint line in the header, passed to `Gap(gapStyle: …)`. Drawn only when both are present. |
| `titleGapStyle` | `CoreGapStyle?` | Gap between the header (title and hint) and the chips, passed to `Gap(gapStyle: …)`. |
| `titleTextStyle` | `CoreTextStyle?` | Title text style override (color + fontWeight + size + …). |
| `selectionHintTextStyle` | `CoreTextStyle?` | Selection-hint text style override. |

<!-- STYLE_TABLE:END -->

<Note>

위 표와 지금 동작이 다르거나 덧붙일 점입니다.

- **`fadeColor`** — 흐림에 색을 입히지 않습니다. 흐림은 마스크라 색의 불투명도만 쓰이고 색상은 보이지 않습니다. 반투명한 색을 주면 흐림 바깥의 칩까지 옅어질 수 있으니, 흐림의 모양은 `fadeWidth` 와 `showFade` 로 조절합니다.
- **`fadeWidth`** — Flutter 에서는 `theme.scaling` 이 두 번 곱해집니다.

</Note>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="chip-group/related-chip" title="Chip">

`chipBuilder` 에서 돌려주는 칩입니다. 색 · 크기 · 아이콘 · 지우기 버튼을 정합니다.

</Card>
<Card demo="chip-group/related-chip-input" title="ChipInput">

정해진 항목을 고르는 대신 글을 입력해 칩을 더하는 입력입니다.

</Card>
<Card demo="chip-group/related-radio-group" title="RadioGroup">

라디오 버튼 모양으로 하나만 고르게 하는 묶음입니다.

</Card>
</Cards>
