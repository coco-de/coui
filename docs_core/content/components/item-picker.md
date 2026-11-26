---
title: ItemPicker
description: 검색 가능한 단일 선택 아이템 리스트/그리드 피커
category: form
platforms: [flutter, web]
related: [select, autocomplete]
tags: [interactive, form-control, picker]
template: v2
source: form/item_picker
---

# ItemPicker

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

레이아웃 · 격자의 열 수 · 제목 · 검색 입력 · 비활성을 바꿔 보며 ItemPicker 를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="item-picker" />

ItemPicker 는 검색 입력 아래에 글자 항목을 목록이나 격자로 늘어놓고 하나를 고르게 합니다. 트리거를 눌러 여는 방식이 아니라 화면 흐름 안에 그대로 놓입니다. 고른 값은 호출자가 가집니다. 항목을 누르면 그 글자를 `onChanged` 로 넘기기만 하므로, 호출자가 `selectedValue` 를 새 값으로 다시 넘겨야 체크 표시가 옮겨 갑니다. 플레이그라운드의 미리보기는 누른 항목을 기억해 다시 넘깁니다.

```dart
ItemPicker(
  items: const ['김코드', '이코드', '박코드'],
  selectedValue: assignee,
  title: '담당자',
  onChanged: (value) => setState(() => assignee = value),
)
```

## 구조

둥근 패널 안에 검색 입력, 그 아래를 닫는 선, 항목 목록이 위에서 아래로 놓입니다. `title` 은 패널의 머리글이 아니라 목록 맨 위의 구역 라벨입니다.

<Anatomy demo="item-picker/anatomy">
<AnatomyItem part="container" name="Panel">

선택지를 담는 패널. 채움 `surfaceBright`, 테두리 `outlineVariant`, 모서리 12, 그림자 `lg` 입니다. 활성일 때 포인터를 올리면 테두리가 `outline` 으로 한 단 진해집니다.

</AnatomyItem>
<AnatomyItem select="input" side="right" name="search">

목록을 거르는 검색 입력. 테두리 없는(`plain`) [TextField](/components/text-field)의 앞자리에 16 크기 검색 아이콘이 놓이고, 그 아래를 [Divider](/components/divider) 가 닫습니다. `showSearch: false` 면 선까지 함께 사라집니다.

</AnatomyItem>
<AnatomyItem select="[role=presentation]" side="left" name="title">

`title` 로 주는 구역 라벨. `labelSmall` · `onSurfaceSubtle` 글자이고, 목록의 첫 줄이라 항목과 함께 스크롤합니다.

</AnatomyItem>
<AnatomyItem select="[role=option]" side="right" name="option">

항목 한 줄(격자에서는 한 칸). 글자 하나만 담고, 눌러서 고릅니다.

</AnatomyItem>
<AnatomyItem select="[aria-selected=true] svg" side="left" name="check">

고른 항목의 글자 앞에 붙는 `primary` 체크. 고른 항목에는 채움이 없고 이 표시만 붙습니다.

</AnatomyItem>
</Anatomy>

`standard` 밀도의 `list` 레이아웃에서 구역 라벨과 고르지 않은 항목의 글자는 패널 테두리 안쪽에서 14 떨어진 곳에서 시작합니다. 검색 아이콘은 검색 입력의 투명한 1px 테두리가 더해져 15 에서 시작합니다. `compact` · `spacious` 에서는 라벨 · 항목 글자가 8 · 20, 검색 아이콘이 13 · 17 이라 시작 위치가 더 벌어집니다. 고른 항목은 글자가 시작하던 자리에 체크가 오고, 글자는 체크 16 과 간격 8 만큼(24, `compact` · `spacious` 는 20 · 28) 뒤로 밀립니다. 체크 자리를 미리 비워 두지 않으므로, 다른 항목을 고르면 두 항목의 글자가 함께 움직입니다.

## 레이아웃

`layout` 은 `CoreItemPickerLayout` 의 두 값 중 하나이고, 기본은 `list` 입니다.

<Preview demo="item-picker/layouts" />

| 값 | 놓는 방식 |
| --- | --- |
| `list` (기본) | 위에서 아래로 한 줄에 하나씩. 줄 사이를 띄우지 않고, 줄마다 패널 폭을 채웁니다. |
| `grid` | `gridColumns`(기본 4)개의 같은 폭 열. 칸의 가로 · 세로 간격은 8(`optionSpacing`)입니다. 구역 라벨은 모든 열에 걸쳐 놓입니다. |

- `gridColumns` 는 열 **개수**이고 `layout` 이 `grid` 일 때만 씁니다. 1 이상을 줍니다. Jaspr Web 은 12 열까지만 열을 만듭니다.
- 격자 칸의 모양은 두 플랫폼이 다릅니다. Flutter 의 칸은 정사각형이고, 글자는 칸 앞쪽의 세로 가운데에 놓입니다. Jaspr Web 의 칸은 내용 높이이고, 같은 행의 칸은 가장 높은 칸에 맞춰 늘어납니다.
- 격자 칸은 좁습니다. 글자는 칸 폭에서 좌우 안쪽 여백 8 씩을 뺀 자리에 놓이고, 고른 칸은 체크 때문에 24 가 더 줄어듭니다. 넘치면 줄이 바뀌고, Flutter 에서는 칸 높이를 넘은 줄이 잘립니다. 격자에는 짧은 이름을 씁니다.
- 항목은 글자(`String`)뿐입니다. 격자로 놓아도 색 견본 · 아이콘 · 이미지를 담을 수는 없습니다.

```dart
ItemPicker(
  items: templates,
  layout: CoreItemPickerLayout.grid,
  gridColumns: 3,
  title: '템플릿',
  onChanged: pick,
)
```

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 검색

검색 입력은 기본으로 보입니다(`showSearch: true`). 입력한 글자를 포함하는 항목만 남깁니다. 대소문자를 가리지 않고, 앞뒤 공백도 검색어에 들어갑니다.

- 검색은 목록을 거를 뿐 값을 만들지 않습니다. 입력한 글자는 `onChanged` 로 나오지 않습니다.
- 검색은 고른 값을 바꾸지 않습니다. 고른 항목이 거른 결과에서 빠져도 `selectedValue` 는 그대로이고, 검색어를 지우면 체크가 다시 보입니다.
- 검색어는 ItemPicker 안에만 있습니다. 읽거나 정하는 속성과 알려 주는 콜백이 없고, 항목을 고르거나 `items` 가 바뀌어도 남습니다.
- 검색 입력의 안내 글자는 `searchPlaceholder` 이고, 주지 않으면 로케일 문구(한국어 "검색")입니다.
- 남는 항목이 없으면 `emptyText` 를, 주지 않으면 로케일 문구(한국어 "항목이 없어요.")를 보여 줍니다. 이때는 `title` 도 그리지 않습니다.

## 상태

<Preview demo="item-picker/states" />

| 상태 | 모양과 동작 |
| --- | --- |
| 쉴 때 | 패널 테두리 `outlineVariant`, 항목 글자 `bodyMedium` · `onSurface` |
| 패널 Hover | 포인터가 패널(구역 라벨 · 검색 입력 · 항목 위 포함)에 올라가면 테두리가 `outline` 이 됩니다. 비활성에는 없습니다. 패널 자체에는 포커스 · 오류 상태가 없고, 검색 입력은 자기 [TextField](/components/text-field) 상태를 따릅니다. |
| 항목 Hover | 고르지 않은 항목에만 `surfaceContainerHigh` 채움이 깔립니다. 고른 항목은 올려도 채움이 생기지 않습니다. |
| 키보드 포커스 | 포커스한 항목과 검색 입력에 포커스 링을 그립니다. 포커스만으로는 채움이 생기지 않습니다. Flutter 의 검색 입력 링은 아래쪽 선만 보이고, 비활성인 Jaspr Web 의 항목에는 링이 없습니다(접근성의 알려진 제약). |
| 누름 | 항목은 누를 때 크기가 줄지 않습니다. |
| 선택 | 글자 앞에 16 크기의 `primary` 체크를 그립니다. 채움은 없습니다. 이미 고른 항목을 다시 눌러도 `onChanged` 가 불립니다. |
| 항목 없음 | 목록 자리에 빈 상태 문구를 보여 줍니다. 검색 입력은 그대로 있습니다. |
| 비활성 | `enabled: false`. 검색 입력이 비활성이 되고, 검색 아이콘 · 항목 글자 · 체크 · 구역 라벨 · 빈 상태 문구가 `disabledContent` 가 됩니다. 항목에는 그 위에 50% 불투명도가 한 번 더 걸립니다. 항목을 눌러도 `onChanged` 가 불리지 않습니다. |

`enabled` 의 기본값은 `true` 이고 `onChanged` 가 있는지와 상관없습니다. `onChanged` 를 주지 않으면 활성 모양 그대로이지만 눌러도 아무것도 바뀌지 않습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

미리 정해진 글자 목록에서 검색하며 하나를 고르고, 그 목록을 화면에 펼쳐 둘 때 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 목록을 접어 두고 트리거를 눌러 하나를 고를 때 | [Select](/components/select) |
| 목록에 없는 글자도 값이 될 수 있을 때 | [Autocomplete](/components/autocomplete) |
| 줄마다 아이콘 · 설명이 있거나 여럿을 고를 때 | [OptionList](/components/option-list) 와 [OptionItem](/components/option-item) |
| 선택지가 몇 개뿐이고 고른 값을 폼에 전달해야 할 때 | [RadioGroup](/components/radio-group) |
| 값을 고르는 것이 아니라 실행할 동작을 검색할 때 | [Command](/components/command) |

ItemPicker 는 `items` 에 있는 글자만 고를 수 있고, 하나만 고릅니다. 새 태그처럼 목록에 없는 값을 받아야 하는 곳에는 쓰지 않습니다.

```dart
// 목록에 없는 새 태그는 넣을 방법이 없다 — Autocomplete 를 쓴다
ItemPicker(items: existingTags, onChanged: addTag)
```

<a id="do"></a>
<a id="dont"></a>

### 검색 입력과 항목 글자

<Cards columns="2">
<Card demo="item-picker/do-short-list" tone="do" eyebrow="이렇게 하세요">

항목이 몇 개뿐이면 `showSearch: false` 로 검색 입력을 끕니다. 목록만 남아 간결합니다.

</Card>
<Card demo="item-picker/dont-search-short" tone="dont" eyebrow="이렇게 하지 마세요">

항목 세 개에 검색 입력을 두지 않습니다. 거를 것이 없는 칸이 자리를 차지합니다.

</Card>
<Card demo="item-picker/do-distinct" tone="do" eyebrow="이렇게 하세요">

항목마다 다른 글자를 씁니다. 같은 이름은 구분되는 말을 덧붙입니다.

</Card>
<Card demo="item-picker/dont-duplicate" tone="dont" eyebrow="이렇게 하지 마세요">

같은 글자를 두 번 넣지 않습니다. 고른 값이 글자라서 같은 글자의 항목이 모두 고른 것으로 보이고, `onChanged` 로도 어느 것을 눌렀는지 알 수 없습니다.

</Card>
</Cards>

```dart
ItemPicker(
  items: const ['소', '중', '대'],
  showSearch: false,
  selectedValue: selectedSize,
  onChanged: (value) => setState(() => selectedSize = value),
)
```

## 배치

| 항목 | 동작 |
| --- | --- |
| 폭 | 부모가 준 폭을 채웁니다. Flutter 에서는 `Row` 처럼 가로 길이를 정해 주지 않는 부모에 바로 넣으면 레이아웃 오류가 납니다. `Expanded` 나 `SizedBox` 로 폭을 정해 줍니다. |
| 높이 | 검색 입력(기본 40), 그 아래 선, 목록을 더한 높이입니다. 목록(구역 라벨 · 항목 · 안쪽 여백)은 최대 256 이고, 넘으면 목록만 스크롤합니다. 검색 입력은 스크롤하지 않습니다. |
| 위치 | 떠 있는 판처럼 그림자를 갖지만 화면 흐름 안에 놓입니다. 다른 내용 위에 띄우거나 열고 닫는 방식은 없습니다. |
| 밀도 | 검색 입력 높이는 `compact` · `standard` · `spacious` 에서 32 · 40 · 48 입니다. 안쪽 여백 · 간격 · 모서리도 밀도를 따릅니다. 목록의 최대 높이 256 은 그대로입니다. 직접 준 `searchHeight` 도 밀도에 따라 바뀌지 않습니다. |

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

놓는 방식은 `layout` · `gridColumns` 로 고르고, 보이는 값은 `itemPickerStyle`(`CoreItemPickerStyle`) 하나로 덮어씁니다. 앱 전체의 기본값은 `CoreComponentTheme.itemPicker` 에 둡니다. 크기 단계와 variant 는 없습니다.

| 부분 | 필드 | 기본값 |
| --- | --- | --- |
| 패널 채움 | `backgroundColor` | `surfaceBright` |
| 패널 테두리 | `borderColor` · `borderWidth` | `outlineVariant` · 1 |
| Hover 테두리 | `hoverBorderColor` | `outline` |
| 패널 모서리 · 그림자 | `borderRadius` · `elevation` | 12 · `strong`(`lg`) |
| 목록의 최대 높이 | `maxHeight` | 256 |
| 검색 입력 높이 | `searchHeight` | 40 |
| 검색 입력 | `searchFieldStyle` | 안쪽 여백 좌우 14 · 위아래 8 |
| 검색 아이콘 | `searchIconStyle` | 16 · `onSurfaceSubtle` |
| 검색 아래 선 | `searchDividerStyle` | `Divider` 의 기본값(1 · `outlineVariant`) |
| 목록의 안쪽 여백 | `itemsPadding` | 6 |
| 구역 라벨 | `titleTextStyle` · `titlePadding` | `labelSmall` · `onSurfaceSubtle`, 위 6 · 아래 4 · 좌우 8(높이 27) |
| 항목의 여백 · 모서리 | `optionPadding` · `optionBorderRadius` | 8 · 8 |
| 항목 글자 | `optionTextStyle` | `bodyMedium` · `onSurface` |
| 고른 항목 | `selectedColor` · `selectedTextStyle` | 투명 · `bodyMedium` · `onSurface` |
| 올린 항목 | `optionHoverColor` · `optionHoverTextStyle` | `surfaceContainerHigh` · `onSurface` |
| 체크 | `checkColor` · `checkIconSize` | `primary` · 16 |
| 간격 | `optionSpacing` | 8 (격자의 칸 간격, 체크와 글자 사이) |
| 빈 상태 | `emptyTextStyle` · `emptyPadding` | `bodySmall` · `onSurfaceVariant` · 24 |
| 비활성 글자 | `disabledForegroundColor` | `disabledContent` |
| 항목의 누름 | `clickableStyle` | 누를 때 줄지 않음(`pressedScale: 1`) |

<Split>

<Code language="dart" title="ItemPicker 하나만 바꾸기">
ItemPicker(
  items: templates,
  selectedValue: template,
  onChanged: setTemplate,
  itemPickerStyle: CoreItemPickerStyle(
    maxHeight: CoreLayout.layout320,
    elevation: CoreOutlinedContainerElevation.none,
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    itemPicker: CoreItemPickerTheme(
      style: CoreItemPickerStyle(maxHeight: CoreSpace.space192),
    ),
  ),
)
</Code>

</Split>

### 안쪽 부품의 스타일

검색 입력 · 검색 아이콘 · 아래 선 · 항목의 누름은 각 부품의 Style 을 그대로 받습니다. 순서대로 `searchFieldStyle`(`CoreTextFieldStyle`), `searchIconStyle`(`CoreIconStyle`), `searchDividerStyle`(`CoreDividerStyle`), `clickableStyle`(`CoreClickableStyle`)입니다. ItemPicker 가 넘기는 검색 입력의 안쪽 여백(좌우 14 · 위아래 8)과 누를 때 줄지 않는 `pressedScale: 1` 은 앱 전체의 `CoreComponentTheme.textField` · `clickable` 보다 우선하므로, 이 둘은 `CoreComponentTheme.itemPicker` 나 `itemPickerStyle` 에서 바꿉니다. 검색 입력의 높이는 `searchHeight` 로만 정합니다. `searchFieldStyle.height` 를 적어도 그 값은 쓰지 않습니다. 이때 줄 높이는 `searchHeight` 이고, 주지 않았으면 밀도와 상관없이 40 입니다. `searchFieldStyle.minHeight` 를 그 줄 높이보다 크게 적거나 `maxHeight` 를 작게 적으면 Jaspr Web 의 검색 줄 높이만 바뀌고 Flutter 는 그대로이므로, 두 값은 적지 않습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `ItemPicker` 에는 `withStyle` 로 스타일을 덧붙입니다. 생성자의 `itemPickerStyle` 인자와 같게 동작하고, 겹치는 필드는 뒤에 붙인 값이 이깁니다. `.radius16` 처럼 Core 토큰 이름과 똑같은 getter 도 있습니다. 모서리 getter 는 `borderRadius` 를, 색 getter(`.primary` 류)는 패널의 `backgroundColor` 를 바꿉니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ItemPickerChainExample extends StatefulWidget {
  const ItemPickerChainExample({super.key});

  @override
  State<ItemPickerChainExample> createState() => _ItemPickerChainExampleState();
}

class _ItemPickerChainExampleState extends State<ItemPickerChainExample> {
  String _selected = '김코드';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        ItemPicker(
          items: const ['김코드', '이코드', '박코드', '최코드', '정코드'],
          selectedValue: _selected,
          title: '담당자',
          onChanged: (value) => setState(() => _selected = value),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        ItemPicker(
          items: const ['김코드', '이코드', '박코드', '최코드', '정코드'],
          selectedValue: _selected,
          title: '직접 지정',
          onChanged: (value) => setState(() => _selected = value),
        ).withStyle(
          const CoreItemPickerStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
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
class ItemPickerChainExample extends StatefulComponent {
  const ItemPickerChainExample({super.key});

  @override
  State<ItemPickerChainExample> createState() => _ItemPickerChainExampleState();
}

class _ItemPickerChainExampleState extends State<ItemPickerChainExample> {
  String _selected = '김코드';

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        ItemPicker(
          items: const ['김코드', '이코드', '박코드', '최코드', '정코드'],
          selectedValue: _selected,
          title: '담당자',
          onChanged: (value) => setState(() => _selected = value),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        ItemPicker(
          items: const ['김코드', '이코드', '박코드', '최코드', '정코드'],
          selectedValue: _selected,
          title: '직접 지정',
          onChanged: (value) => setState(() => _selected = value),
        ).withStyle(
          const CoreItemPickerStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
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

<Note>

색 getter 는 패널 바탕만 바꿉니다. 위 예의 첫 번째처럼 `.primary` 를 붙이면 항목 글자는 `onSurface` 그대로이고 `primary` 체크는 같은 색 바탕에 묻힙니다. 진한 바탕을 쓸 때는 글자 색(`optionTextStyle` · `selectedTextStyle` · `titleTextStyle`)과 `checkColor` 를 함께 바꿉니다.

</Note>

### 값이 정해지는 순서

```text
기본값 (CoreItemPickerStyle.default*)
  → CoreComponentTheme.itemPicker.style   // 앱 전체
  → itemPickerStyle                       // 인스턴스
```

뒤로 갈수록 우선합니다. 글자 스타일과 안쪽 부품의 스타일은 필드 단위로 합칩니다.

<a id="접근성-accessibility"></a>

## 접근성

Jaspr Web 은 목록을 `listbox`, 항목을 `option` 으로 알립니다. Flutter 에는 이 역할이 없어 항목을 버튼과 선택 상태로 알립니다.

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은 [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | `listbox` · `option` 역할은 없습니다. 항목마다 버튼이고, 고른 여부(`selected`)와 활성 여부를 함께 알립니다. 패널과 구역 라벨에는 따로 역할이 없습니다. |
| Jaspr Web | 항목을 직접 담는 요소가 `role="listbox"` 입니다. `list` 레이아웃이면 `aria-orientation="vertical"`, 비활성이면 `aria-disabled="true"` 가 붙습니다. 항목은 `role="option"` 과 `aria-selected` 를 갖고, 비활성 항목에는 `aria-disabled="true"` 가 붙습니다. 목록 안의 구역 라벨은 `role="presentation"` 이라, `listbox` 의 자식 중 `option` 이 아닌 것은 이것뿐입니다. 검색 입력(`type="search"`)은 `listbox` 밖에 있습니다. |

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` · `Shift` · `Tab` | 검색 입력에서 시작해 항목마다 한 번씩 멈춥니다. | 검색 입력 다음에 목록 전체가 한 번 멈춥니다. 멈추는 항목은 마지막으로 포커스한 항목이고, 없으면 고른 항목, 그것도 없으면 첫 항목입니다. |
| `Enter` · `Space` | 포커스한 항목을 고릅니다. | 포커스한 항목을 고릅니다. |
| `↑` · `↓` | 네이티브 앱에서는 Flutter 의 기본 단축키가 그 방향으로 포커스를 옮깁니다. Flutter Web 에서는 스크롤합니다. | `list` 는 이전 · 다음 항목, `grid` 는 한 행 위 · 아래로 옮깁니다. 끝에서는 멈춥니다. |
| `←` · `→` | `↑` · `↓` 와 같은 기본 단축키를 따릅니다. | `grid` 에서 이전 · 다음 항목으로 옮깁니다(행 끝에서는 다음 행으로 이어집니다). `list` 에서는 처리하지 않습니다. |
| `Home` · `End` | 처리하지 않습니다. | 첫 항목 · 마지막 항목으로 옮깁니다. 격자에서도 전체의 처음과 끝입니다. |
| 글자 키 | 처리하지 않습니다. | 그 글자로 시작하는 다음 항목으로 옮깁니다. |

- Jaspr Web 은 WAI-ARIA listbox 패턴을 따릅니다. 화살표 · `Home` · `End` · 글자 키는 포커스만 옮기고, 고르기는 `Enter` · `Space` 로 합니다.
- Jaspr Web 의 글자 키는 500ms 안에 이어 친 글자를 하나의 앞부분으로 보고, 같은 글자를 반복해 누르면 그 글자로 시작하는 항목을 돌아가며 옮깁니다. 대소문자를 가리지 않습니다. 글자 그대로의 앞부분을 비교하므로 자모 하나(`ㄱ`)는 음절(`김`)과 맞지 않습니다.
- 검색 입력에 포커스가 있으면 화살표 키로 목록에 들어갈 수 없습니다. 목록에는 `Tab` 으로 들어갑니다. 검색 입력에서 `Enter` 를 눌러도 항목을 고르지 않습니다.
- Flutter 네이티브 앱의 화살표 이동은 ItemPicker 가 아니라 프레임워크의 방향 포커스 이동입니다. 그래서 ItemPicker 밖의 요소로도 넘어가고, 선택은 따라가지 않습니다.

### 스크린 리더

- 항목의 이름은 항목 글자입니다.
- **Jaspr Web** — `title` 이 있으면 그것이 `listbox` 의 이름이 됩니다. `attributes: {'aria-label': ...}` 를 주면 그 이름이 우선합니다. `role` · `aria-*` 속성은 바깥 틀이 아니라 `listbox` 에 붙습니다. 다만 `role` 과 컴포넌트가 정하는 `aria-orientation` · `aria-disabled` 는 컴포넌트의 값이 우선합니다. 검색 입력에는 라벨이 없어, 이름은 안내 글자(`placeholder`)에서만 옵니다.
- **Flutter** — 목록이나 검색 입력에 이름을 주는 속성이 없고, 검색 입력에는 글자를 입력했든 아니든 접근 가능한 이름이 없습니다. 안내 글자는 입력의 라벨이 아니라 입력 위에 겹쳐 그리는 별도의 글자이고, 입력을 시작하면 숨습니다. `title` 은 일반 글자로 읽힙니다. 전체를 `Semantics(container: true, label: '담당자', child: ...)` 로 감싸면 검색 입력까지 포함한 ItemPicker 전체에 이름이 붙습니다.
- 두 플랫폼 모두 검색 결과가 바뀌거나 비었다는 것을 따로 알리지 않습니다(라이브 리전이 없습니다).

### 포커스 관리

- 마운트될 때 포커스를 옮기지 않습니다.
- 포커스를 가두지 않습니다. `Tab` 은 순서대로 ItemPicker 를 지나갑니다.
- Jaspr Web 에서 화살표 · `Home` · `End` · 글자 키로 포커스를 옮기면 `Tab` 이 멈추는 항목도 함께 옮겨 갑니다. 선택은 포커스를 따라가지 않습니다.
- 포커스 링은 키보드로 포커스한 항목과 검색 입력에 나타납니다. Flutter 의 검색 입력 링은 패널에 잘려 아래쪽 선만 보이고, 비활성인 Jaspr Web 의 ItemPicker 에서는 포커스한 항목에 링이 없습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | `Form` · `FormField` 에 고른 값을 보고하지 않습니다. 검색 입력도 감싼 `FormField` 에 값을 보고하지 않습니다. 제출할 값은 `onChanged` 로 받아 직접 가집니다. |
| 공통 | 감싼 `Fieldset` · `FormField` 의 비활성 설정은 검색 입력만 읽고 항목은 읽지 않습니다. `Fieldset(enabled: false)` 안에서는 흐려 보여도 항목을 고를 수 있고, `FormField(enabled: false)` 안에서는 포인터는 막히지만 키보드로 고를 수 있습니다. 항목까지 막으려면 ItemPicker 에 `enabled: false` 를 줍니다. `FormField` 의 오류도 검색 입력만 읽어, 검색 입력에만 오류 테두리가 생깁니다. |
| 공통 | 비활성 항목은 `disabledContent` 색 위에 50% 불투명도가 한 번 더 걸려, 같은 비활성 색의 구역 라벨보다 옅습니다. `clickableStyle: CoreClickableStyle(disabledOpacity: 1)` 로 불투명도를 없앨 수 있습니다. |
| 공통 | 검색어를 알려 주는 콜백이 없고 안의 거르기를 끌 수 없습니다. 그래서 이 검색 입력의 글자로 서버를 검색할 수 없고, 밖에서 `items` 를 바꿔도 남아 있는 검색어로 다시 거릅니다. 검색어를 입력한 뒤 `showSearch: false` 로 바꾸면 남은 검색어가 목록을 계속 거르는데, 지울 입력이 없습니다. 다시 `true` 로 바꿔도 검색 입력은 빈칸인데 목록은 이전 검색어로 걸러진 채이고, 새로 글자를 입력해야 바뀝니다. |
| 공통 | 같은 글자의 항목이 둘이면 둘 다 고른 것으로 표시됩니다. Flutter 는 고르지 않은 같은 글자 항목 하나에 포인터를 올리면 그 글자의 항목 모두에 hover 채움이 깔립니다. Jaspr Web 은 두 번째 이후의 같은 글자 항목에서도 화살표 · 글자 키의 현재 위치를 첫 번째 항목 자리로 계산해, 화살표로는 그 아래 항목까지 가지 못할 수 있습니다. |
| Flutter | 패널이 안쪽 내용을 잘라 내서, 맨 위에서 폭을 꽉 채우는 검색 입력의 키보드 포커스 링은 위 · 좌우가 보이지 않고 아래쪽 선만 보입니다. |
| Flutter | 항목마다 `Tab` 이 멈추므로, 항목이 많으면 `Tab` 만으로 목록을 지나가야 합니다. |
| Flutter | `grid` 의 칸이 정사각형이라, 칸 높이를 넘는 글자는 잘립니다. |
| Flutter | `grid` 는 자기 위 · 아래 여백을 정하지 않아, 주변 `MediaQuery` 에 안전 영역 여백(`padding`)이 남아 있으면 격자 위 · 아래에 그만큼의 빈 자리가 생깁니다. `SafeArea` 안처럼 이미 빠진 곳에서는 생기지 않습니다. |
| Jaspr Web | 비활성이어도 항목 하나에 `Tab` 이 멈추고 화살표로 옮겨 다니는데, 포커스 링이 보이지 않아 지금 어느 항목인지 알 수 없습니다. |
| Jaspr Web | 남는 항목이 없으면 `listbox` 요소가 없어, `attributes` 로 준 `role` · `aria-*` 속성이 어디에도 붙지 않습니다. |
| Jaspr Web | `gridColumns` 가 12 를 넘으면 열 클래스가 만들어지지 않아 여러 열로 놓이지 않습니다. |
| Jaspr Web | 검색 입력이 `type="search"` 라 브라우저에 따라 지우기 버튼을 그리거나 `Escape` 로 입력한 글자를 지웁니다. 컴포넌트가 만든 동작이 아니라 브라우저의 기본 동작이며 Flutter 에는 없습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API 는 같지만, 아래 항목은 두 플랫폼이 다르게 그리거나 다르게 동작합니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 클래스명 | `ItemPicker` | `ItemPicker` |
| 검색 입력 | `TextField`(`plain`) | `TextField`(`plain`, `type: .search`) |
| 검색 입력의 키보드 포커스 링 | 패널에 잘려 아래쪽 선만 보입니다 | 네 변이 패널 위로 보입니다 |
| `searchFieldStyle` 의 `minHeight` · `maxHeight` | 검색 줄 높이를 바꾸지 않습니다 | 줄 높이보다 큰 `minHeight`, 작은 `maxHeight` 가 줄 높이를 바꿉니다 |
| 체크 표시 | `Icon(LucideIcons.check)` | `Icon(LucideIcons.check)` |
| 목록의 역할 | 없음. 항목은 버튼과 `selected` 상태 | `listbox` · `option` · `aria-selected` |
| 항목 이동 | 항목마다 `Tab`, 네이티브 앱은 방향 포커스 이동 | `Tab` 한 번 뒤 화살표 · `Home` · `End` · 글자 키. 화살표는 끝에서 반대쪽으로 넘어가지 않습니다 |
| 비활성에서 키보드 | 항목이 포커스를 받지 않습니다 | `Tab` 이 항목 하나에 멈추고 화살표로 옮겨 다닙니다. 고를 수는 없고, 포커스 링도 그리지 않습니다 |
| 패널 Hover 테두리 | `MouseRegion` 으로 포인터를 알아챕니다 | CSS `:hover` 로 그립니다 |
| 격자 칸 | 정사각형 | 내용 높이 |
| 격자의 열 개수 | 1 이상 | 1 ~ 12 |
| 격자의 구역 라벨과 첫 행 | 라벨의 아래 여백만큼 떨어집니다 | 칸 간격 8 이 더해집니다 |
| 빈 상태 문구 | 시작 쪽에 맞춥니다 | 가운데에 맞춥니다 |
| `optionHoverTextStyle` | 값 전체를 올린 항목 글자에 씁니다. 이때 `optionTextStyle` 은 쓰지 않습니다 | `color` 만 씁니다. 나머지 모양은 쉬는 글자(`optionTextStyle`) 그대로입니다. `optionTextStyle` 에 토큰이 아닌 색을 주면 올려도 글자 색이 바뀌지 않습니다 |
| 크기 배율 | 테마의 크기 배율(`scaling`)을 곱합니다 | CSS 변수와 `rem` 으로 그려 브라우저의 글자 크기를 따릅니다 |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` 와 `onClick` 같은 이벤트. `role` · `aria-*` 는 `listbox` 에, 나머지는 바깥 틀에 붙습니다 |

<a id="props-parameters"></a>

## API

Flutter 와 Jaspr Web 이 같은 속성을 씁니다.

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `items` | `List<String>` | `const []` | 고를 수 있는 항목. 서로 다른 글자를 줍니다. |
| `selectedValue` | `String?` | `null` | 고른 항목. 호출자가 정하고 바꿉니다. `items` 에 없는 값이면 체크가 보이지 않습니다. |
| `title` | `String?` | `null` | 목록 맨 위의 구역 라벨. 남는 항목이 없으면 그리지 않습니다. |
| `searchPlaceholder` | `String?` | `null` | 검색 입력의 안내 글자. 주지 않으면 로케일 문구를 씁니다. |
| `emptyText` | `String?` | `null` | 남는 항목이 없을 때의 문구. 주지 않으면 로케일 문구를 씁니다. |

### 상태와 형태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `layout` | `CoreItemPickerLayout` | `list` | `list` 또는 `grid` |
| `gridColumns` | `int` | `4` | 격자의 열 개수. `grid` 일 때만 씁니다. |
| `showSearch` | `bool` | `true` | 검색 입력과 그 아래 선을 보여 줄지 |
| `enabled` | `bool` | `true` | false 면 비활성. `onChanged` 유무와 상관없습니다. |
| `itemPickerStyle` | `CoreItemPickerStyle?` | `null` | 보이는 값 덮어쓰기 |

### 콜백

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `onChanged` | `void Function(String value)?` | `null` | 누른 항목의 글자를 받습니다. 선택을 바꾸려면 받은 값을 `selectedValue` 로 다시 넘깁니다. |

콜백 타입은 Flutter 에서는 `ValueChanged<String>?`, Jaspr Web 에서는 `CoreValueChanged<String>?` 로 쓰고 모양이 같습니다. 두 플랫폼 모두 `key` 를 받습니다. Jaspr Web 은 `id` · `classes` · `css` · `attributes` · `eventHandlers` 와 `onClick` · `onKeyDown` 같은 이벤트도 받습니다.

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreItemPickerStyle patch)` | `itemPickerStyle` 에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다. |
| 모서리 · 색 getter (`radius0` ~ `radius9999`, `primary` ~ `transparent`) | `withStyle` 을 줄인 형태. 모서리는 `borderRadius`, 색은 `backgroundColor` 를 바꿉니다. |
| `copyWith({items, selectedValue, layout, itemPickerStyle, …})` | 바꾼 값으로 사본을 만듭니다. `null` 을 넘기면 지금 값이 남습니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.itemPicker` | `CoreItemPickerTheme?` | 앱 전체의 모양. `style`(`CoreItemPickerStyle?`) 하나를 가집니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreItemPickerStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Picker container background colour override. |
| `borderColor` | `CoreColor?` | Picker container border colour override. |
| `hoverBorderColor` | `CoreColor?` | Picker container border colour override while the pointer is over the picker. `null` → [defaultHoverBorderColor]. Never applied while the picker is disabled. |
| `borderRadius` | `CoreBorderRadius?` | Picker container border radius override. |
| `borderWidth` | `double?` | Picker container border width override (logical px). |
| `elevation` | `CoreOutlinedContainerElevation?` | Picker container shadow rung override. `null` → [defaultElevation]. |
| `maxHeight` | `double?` | Picker items scroll-area maximum height override (logical px). |
| `selectedColor` | `CoreColor?` | Selected option background colour override. |
| `optionTextStyle` | `CoreTextStyle?` | Option label text style override applied in the resting (neither selected nor hovered) state. Layers onto the [defaultOptionTextStyle] token role; the resting colour is carried via [CoreTextStyle.color] inside this slot. |
| `selectedTextStyle` | `CoreTextStyle?` | Selected option text style override. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `selectedTextColor` field removed). |
| `optionHoverColor` | `CoreColor?` | Option hover background colour override. |
| `optionHoverTextStyle` | `CoreTextStyle?` | Option text style override applied when the option is hovered. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `optionHoverTextColor` field removed). |
| `titleTextStyle` | `CoreTextStyle?` | Picker section label (title row) text style override. Layers onto the [defaultTitleTextStyle] token role; a weight or colour override rides [CoreTextStyle.fontWeight] / [CoreTextStyle.color] inside this slot. |
| `emptyTextStyle` | `CoreTextStyle?` | Empty-state text style override. Layers onto the [defaultEmptyTextStyle] token role; the placeholder's colour is carried via [CoreTextStyle.color] inside this slot. |
| `titlePadding` | `CoreEdgeInsets?` | Picker section label (title row) padding override. |
| `itemsPadding` | `CoreEdgeInsets?` | Picker items scroll-area padding override. |
| `optionPadding` | `CoreEdgeInsets?` | Option row padding override. |
| `optionSpacing` | `double?` | Inter-option spacing (logical px). Drives the grid layout `mainAxisSpacing` / `crossAxisSpacing` (Flutter `GridView.count`) / `gap` inline CSS (Web grid container) and the per-option row icon ↔ label gap. `null` defers to [defaultOptionSpacing]. |
| `optionBorderRadius` | `CoreBorderRadius?` | Option row corner radius override. |
| `emptyPadding` | `CoreEdgeInsets?` | Empty-state padding override. |
| `clickableStyle` | `CoreClickableStyle?` | Style for each option's `Clickable` — press scale, durations, focus ring, disabled opacity. Laid over [defaultClickableStyle] and passed to the `Clickable` as is, which fills in the rest. |
| `checkIconSize` | `double?` | Selected-option check-glyph icon size (logical/CSS px). `null` → [defaultCheckIconSize]. |
| `checkColor` | `CoreColor?` | Selected-option check glyph colour override. `null` → [defaultCheckColor]. |
| `disabledForegroundColor` | `CoreColor?` | Foreground colour while the picker is disabled — the option text, the selected-option check, the title and the empty-state line. `null` → [defaultDisabledForegroundColor]. |
| `searchHeight` | `double?` | Search `<input>` row height (logical/CSS px). `null` → [defaultSearchHeight]. |
| `searchFieldStyle` | `CoreTextFieldStyle?` | Look of the search `TextField`. Laid over [defaultSearchFieldStyle] and passed as is to `TextField(textFieldStyle: …)` on both platforms. The row height stays [searchHeight]. |
| `searchIconStyle` | `CoreIconStyle?` | Look of the search glyph in front of the search field. Laid over [defaultSearchIconStyle] and passed to the `Icon` as is. A disabled picker swaps the colour to [defaultDisabledSearchIconColor] unless this states one. |
| `searchDividerStyle` | `CoreDividerStyle?` | Look of the `Divider` that closes the search row. Laid over [defaultSearchDividerStyle] and passed as is to `Divider(dividerStyle: …)`. |

<!-- STYLE_TABLE:END -->

<Note>

- `optionSpacing` 은 `list` 에서는 줄 사이를 띄우지 않고 체크와 글자 사이에만 씁니다.
- 고른 항목의 글자는 `optionTextStyle` 을 읽지 않고, Flutter 의 올린 항목 글자도 읽지 않습니다. 글자 크기나 서체를 바꾸려면 `optionTextStyle` · `selectedTextStyle` · `optionHoverTextStyle` 을 함께 줍니다.
- Jaspr Web 은 `optionHoverTextStyle` 에서 `color` 만 씁니다. `optionTextStyle` 의 색이 토큰이 아니면 이 색도 적용되지 않습니다.
- `disabledForegroundColor` 를 쓰는 비활성 항목에는 50% 불투명도(`clickableStyle` 의 `disabledOpacity`)가 함께 걸립니다.
- `searchFieldStyle` 설명의 "줄 높이는 `searchHeight`" 는 `height` 에만 맞습니다. 줄 높이보다 큰 `minHeight` 나 작은 `maxHeight` 를 적으면 Jaspr Web 의 검색 줄 높이는 바뀌고 Flutter 는 그대로입니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card component="select" props="placeholder=지역 선택" title="Select">

목록을 드롭다운에 접어 두고 하나를 고릅니다.

</Card>
<Card component="autocomplete" props="placeholder=지역 검색" title="Autocomplete">

추천을 보여 주되, 목록에 없는 글자도 입력할 수 있습니다.

</Card>
<Card component="option-list" props="selection=multiple" title="OptionList">

설명 · 아이콘을 담은 OptionItem 줄을 쌓습니다. 여럿도 고릅니다.

</Card>
</Cards>
