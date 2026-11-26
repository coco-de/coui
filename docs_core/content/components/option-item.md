---
title: OptionItem
description: 바텀시트나 패널의 선택지 목록에 놓는 한 줄입니다. 하나를 고를 때는 체크로, 여럿을 고를 때는 체크박스로 고른 상태를 보여 줍니다.
category: form
platforms: [flutter, web]
related: [option-list, checkbox, menu-item, select]
tags: [form, option, selection, list]
template: v2
source: form/option_item
---

# OptionItem

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

선택 방식과 상태를 바꿔 보며 선택지 한 줄을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="option-item" />

줄은 무엇이 골라졌는지 스스로 들고 있지 않습니다. `selected` 가 그 상태를 말하고, 줄을 누르면 `onPressed` 만 불립니다. 어느 줄이 골라졌는지는 호출자가 정하며, 새 `selected` 를 넘겨야 화면이 바뀝니다.

<a id="구조-anatomy"></a>

## 구조

줄은 테두리를 두른 둥근 카드입니다. 앞에서부터 앞 아이콘, 글(라벨과 설명), 고른 상태의 표시가 놓입니다.

<Anatomy demo="option-item/anatomy">
<AnatomyItem part="container" name="Container">

테두리를 두른 카드이자 누르는 영역입니다. 쉴 때는 바탕이 없고, 고른 줄은 바탕을 채우며 테두리가 `primary` 로 바뀝니다.

</AnatomyItem>
<AnatomyItem part="leading" side="top" name="leading">

라벨 앞의 아이콘 자리입니다. 선택 사항이고, 없으면 자리를 만들지 않습니다. 줄이 아이콘에 크기(20)와 색을 내려 주고, 아이콘에 직접 준 값은 그보다 우선합니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="label">

선택지의 이름입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=description]" side="right" name="description">

라벨 아래의 짧은 한 줄입니다. 선택 사항이고, 없으면 그 줄을 그리지 않습니다.

</AnatomyItem>
<AnatomyItem part="trailing" side="right" name="mark">

고른 상태의 표시입니다. 그림은 `single` 의 고른 줄로, 끝에 체크가 있습니다. `multiple` 은 모든 줄 끝에 Checkbox 를 그립니다.

</AnatomyItem>
</Anatomy>

눌린 동안에는 테두리 안쪽을 채우는 둥근 눌림 면이 바탕 위, 글과 표시 아래에 깔립니다.

Figma: [CoUI 라이브러리 파일](https://www.figma.com/design/9FgsLhiWz0aLsVqcoI6nYJ/CoUI---Cocode-Design-System-v1.0)의 `OptionItem` 페이지

<a id="변형-variants"></a>
<a id="selection-multiple"></a>

## 선택 방식

`selection` 은 고른 상태를 보여 주는 방식입니다. 두 방식은 줄의 크기와 여백이 같고, 끝의 표시와 고른 라벨의 색이 다릅니다.

<Cards columns="2">
<Card component="option-item" props="selection=single;selected=true" label="최신순" title="single (기본)">

하나만 고르는 목록에 씁니다. 고른 줄 끝에만 `primary` 체크를 그리고, 라벨이 `primary` 색이 됩니다. 고르지 않은 줄에는 표시 자리가 없습니다.

</Card>
<Card component="option-item" props="selection=multiple;selected=true" label="무료 배송" title="multiple">

여럿을 고르는 목록에 씁니다. 모든 줄 끝에 `lg` 크기 [Checkbox](/components/checkbox) 를 그립니다. 고른 줄의 라벨은 `onSurface` 색 그대로이고, 고른 상태는 체크박스가 보여 줍니다.

</Card>
</Cards>

고른 줄의 라벨은 두 방식 모두 SemiBold 가 됩니다. 체크박스는 줄의 상태를 그린 것이라 입력을 받지 않습니다 — 누름은 줄이 받고, 비활성 줄의 체크박스는 비활성 모양입니다.

`selection` 은 몇 줄을 고를 수 있는지 강제하지 않습니다. 하나만 고르는 목록이면 호출자가 한 줄만 `selected` 로 둡니다. 한 목록의 줄은 같은 `selection` 으로 맞춥니다.

```dart
OptionItem(
  selection: CoreOptionItemSelection.multiple,
  label: Text('무료 배송'),
  description: Text('3만원 이상 주문'),
  selected: freeShipping,
  onPressed: toggleFreeShipping,
)
```

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>
<a id="상태-전환"></a>
<a id="애니메이션"></a>
<a id="비활성"></a>

## 상태

OptionItem 에는 variant 가 없습니다. `selected` 와 `enabled`, 그리고 `selection` 이 모양을 정합니다.

<Preview demo="option-item/states" />

<Note>

`surfaceContainer` 로 채운 면(네이티브 문서 앱의 무대가 그렇습니다) 위에서는 고른 비활성 줄의 바탕(`surfaceContainer`)이 구분되지 않습니다. `surface` 바탕인 웹 문서의 미리보기에서는 구분됩니다.

</Note>

### 색

| 상태 | 카드 | 라벨 | 끝 표시 (`single` · `multiple`) |
| --- | --- | --- | --- |
| 기본 | 바탕 없음, 테두리 `outlineVariant` 1 | `onSurface` · Medium | 없음 · 빈 Checkbox |
| 고름 | 바탕 `surfaceContainerLow`, 테두리 `primary` 1.5 | SemiBold — `single` 은 `primary`, `multiple` 은 `onSurface` | `primary` 체크 · 선택한 Checkbox |
| 비활성 | 바탕 없음, 테두리 `outlineVariant` 1 | `disabledContent` · Medium | 없음 · 비활성 빈 Checkbox |
| 고름 · 비활성 | 바탕 `surfaceContainer`, 테두리 `outlineVariant` 1 | `disabledContent` · SemiBold | `disabledContent` 체크 · 비활성 선택 Checkbox |

설명은 `onSurfaceVariant` 입니다. 앞 아이콘은 라벨의 평소 색(`onSurface`)이고, 고른 줄에서도 바뀌지 않습니다. 비활성 줄에서는 설명과 앞 아이콘도 `disabledContent` 가 됩니다.

줄은 `label` · `description` 에 넣은 글자에 글자 모양과 색을 내려 줍니다. 그 글자에 색을 직접 주면(`Text('최신순').onSurface` 처럼) 고른 색과 비활성 색이 닿지 않습니다.

앞 아이콘도 같습니다. `Icon` 의 `iconStyle` 에 크기나 색을 직접 주거나 앱의 Icon 테마(`CoreComponentTheme.icon`)에 값이 있으면, 줄이 내려 주는 크기 · 색 대신 그 값이 쓰입니다. 색을 이렇게 정한 아이콘에는 비활성 색도 닿지 않습니다.

<Note>

고른 줄의 1.5 테두리는 화면 배율이 2 미만이면 1 로 그려집니다. 그 화면에서는 고른 줄과 쉬는 줄의 테두리 두께가 같고, 테두리 색 · 바탕 · 표시로 구분됩니다.

</Note>

### 동작

| 항목 | 동작 |
| --- | --- |
| 누를 때 | `onPressed` 를 부릅니다. `selected` 는 저절로 바뀌지 않습니다. |
| 활성 여부 | `enabled` 를 지정하지 않으면 `onPressed` 가 있을 때 활성입니다. `enabled: false` 면 `onPressed` 가 있어도 부르지 않습니다. |
| Hover | 모양은 바뀌지 않고, 커서만 손가락 모양이 됩니다. |
| 눌림 | 누르는 동안 카드 테두리 안쪽에 `surfaceContainerHigh` 면을 깝니다. `stateLayer` 의 눌림 값이 기본 100% 라 불투명합니다. 바탕 위, 글자와 표시 아래라서 고른 줄의 바탕도 덮습니다. 기본 밀도에서 면의 모서리는 12 에서 지금 그리는 테두리 두께를 뺀 값(두께 1 이면 11, 1.5 면 10.5)이라 테두리 안쪽 곡선과 맞습니다. 줄 크기는 줄어들지 않습니다. |
| 키보드로 누를 때 | Flutter 는 같은 눌림 면을 잠깐(기본 100ms, 동작 줄이기에서는 0) 보입니다. Jaspr Web 은 보이지 않습니다(알려진 제약). |
| Focus | 키보드로 포커스했을 때 카드 바깥에 링을 그립니다. 카드에서 2 만큼 비운 뒤 2 두께이고, 모서리는 카드를 따릅니다. |
| 비활성 | 눌림 면이 없고, 커서는 금지 모양이 됩니다. 줄 전체를 흐리게(opacity) 하지 않고 색으로 비활성을 보입니다([색](#색)). |
| 전환 (Flutter) | 눌림 면, 그리고 고른 상태에 따른 카드의 바탕 · 테두리와 라벨은 전환 없이 바로 바뀝니다. |
| 전환 (Jaspr Web) | 활성 줄의 카드 바탕 · 테두리 색은 100ms 동안 바뀝니다. 눌림 면의 색, 라벨 글자색, 비활성 줄의 카드 색은 `CoUIWeb` 의 테마 전환 애니메이션(`enableThemeAnimation`, 기본 켜짐)을 따라 150ms 동안 바뀌고, 이 애니메이션을 끄면 바로 바뀝니다. 동작 줄이기에서는 모두 바로 바뀝니다. |
| `multiple` 의 체크박스 전환 | 두 플랫폼 모두 [Checkbox](/components/checkbox) 의 전환(기본 300ms, 동작 줄이기에서는 바로)을 따릅니다. |

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

바텀시트나 패널 안에서 정렬 기준 · 필터 값처럼 목록에서 하나 또는 여럿을 고를 때 씁니다. 줄마다 짧은 설명이나 앞 아이콘을 함께 보여 줄 수 있습니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 목록을 트리거의 드롭다운 안에 접어 둘 때 | [Select](/components/select) |
| 폼 안에서 라디오 표시로 하나를 고를 때 | [RadioGroup](/components/radio-group) |
| 목록이 아니라 단독 확인 항목일 때 | [Checkbox](/components/checkbox) |
| 선택이 아니라 동작을 실행하는 메뉴 줄일 때 | [MenuItem](/components/menu-item) |

<a id="do"></a>
<a id="dont"></a>

### 선택 상태와 줄 안의 행동

<Cards columns="2">
<Card tone="do" eyebrow="이렇게 하세요" title="고른 상태는 호출자가 듭니다">

```dart
OptionList(
  children: [
    for (final sort in Sort.values)
      OptionItem(
        label: Text(sort.label),
        selected: sort == current,
        onPressed: () => setState(() => current = sort),
      ),
  ],
)
```

줄이 선택을 스스로 들면 목록의 다른 줄과 어긋납니다. 한 줄만 고르는 규칙은 목록을 아는 호출자의 몫입니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요" title="줄 안에 또 다른 행동을 넣지 않습니다">

```dart
// Flutter 코드입니다. Jaspr Web 에는 Row 가 없어 div 로 묶게 됩니다.
// 어느 쪽이든 줄 전체가 누르는 영역이라 안의 버튼과 겹칩니다.
OptionItem(
  label: Row(children: [Text('최신순'), Button(onPressed: showMore, child: Text('더보기'))]),
  onPressed: chooseLatest,
)
```

줄은 누르는 대상 하나입니다. Jaspr Web 에서는 안쪽 버튼을 눌러도 줄의 `onPressed` 가 함께 불립니다. 다른 행동은 목록 밖에 둡니다.

</Card>
</Cards>

## 배치

### 한 줄의 크기

표의 값은 기본 밀도의 값입니다.

| 항목 | 기본값 |
| --- | --- |
| 폭 | 받은 폭을 채웁니다. 글 칸이 남는 폭을 차지하고 긴 글은 줄을 바꿉니다. |
| 높이 | 내용이 정하되 52(`minHeight`)보다 낮아지지 않습니다. |
| 안쪽 여백 | 위아래 12, 좌우 16. 테두리를 포함한 카드 바깥 가장자리에서 잽니다. |
| 앞 아이콘 · 글 · 표시 사이 | 12 |
| 라벨과 설명 사이 | 4 |
| 모서리 | 12 |
| 아이콘 | 앞 아이콘 20, 체크 20 |
| 체크박스 | `lg` (박스 18) |
| 글자 | 라벨 `bodyLarge` · Medium, 설명 `bodySmall` |

- 기본 밀도에서 한 줄짜리 카드는 위아래 여백과 `bodyLarge` 한 줄을 더해도 52 에 못 미쳐 52 로 서고, 내용은 세로 가운데에 놓입니다. `spacious` 에서는 위아래 여백이 16 이 되어 한 줄짜리 카드도 52 보다 커집니다.
- 설명이 없으면 앞 아이콘 · 글 · 표시를 세로 가운데에 맞추고, 설명이 있으면 위쪽에 맞춥니다. 설명이 있는 카드는 라벨 · 설명 · 그 사이 간격에 위아래 여백을 더한 높이가 되어 52 보다 커집니다. 이 높이보다 큰 `minHeight` 를 주면 내용의 세로 위치가 플랫폼마다 다릅니다([플랫폼 차이](#플랫폼-차이)).
- 테두리 두께가 바뀌어도 글은 움직이지 않습니다. 여백을 카드 바깥 가장자리에서 재기 때문입니다.
- 안쪽 여백과 12 간격은 밀도(`CoreDensity`)를 따라 4px 격자에서 한 칸 움직입니다. 카드와 눌림 면의 모서리 12 도 `compact` 에서 10, `spacious` 에서 14 가 됩니다. 최소 높이 52, 라벨과 설명 사이 4, 아이콘과 체크박스 크기는 그대로입니다.
- Flutter 에서는 폭이 정해지지 않은 자리(`Row` 의 직접 자식 등)에 그대로 놓으면 레이아웃 오류가 납니다. `Expanded` 나 `SizedBox` 로 폭을 줍니다.

<a id="조합-예제"></a>

### 목록으로 놓기

[OptionList](/components/option-list) 는 줄을 8 간격으로 세로로 쌓고, 각 줄이 목록의 폭을 채웁니다. 목록도 선택을 들지 않습니다.

<Preview demo="option-item/list" />

```dart
OptionList(
  children: [
    OptionItem(label: Text('최신순'), selected: true, onPressed: chooseLatest),
    OptionItem(label: Text('인기순'), onPressed: choosePopular),
    OptionItem(label: Text('낮은 가격순'), onPressed: chooseCheapest),
  ],
)
```

<a id="스타일-시스템-style-system"></a>
<a id="optionitemstyle"></a>

## 테마와 스타일

선택 방식과 상태는 위젯 속성(`selection` · `selected` · `enabled`)이 정하고, 색 · 크기 · 간격처럼 보이는 값은 `optionItemStyle`(`CoreOptionItemStyle`) 하나로 덮어씁니다.

<a id="사용-예"></a>

<Split>

<Code language="dart" title="줄 하나만 바꾸기">
OptionItem(
  label: Text('최신순'),
  selected: true,
  onPressed: chooseLatest,
  optionItemStyle: CoreOptionItemStyle(
    selectedBorderColor: CoreColor.token(CoreColors.tertiary),
    selectedLabelTextStyle: CoreTextStyle(
      color: CoreColor.token(CoreColors.tertiary),
    ),
    checkIconStyle: CoreIconStyle(
      color: CoreColor.token(CoreColors.tertiary),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    optionItem: CoreOptionItemTheme(
      style: CoreOptionItemStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        pressedBackgroundBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      ),
    ),
  ),
)
</Code>

</Split>

<Note>

카드 모서리(`borderRadius`)를 바꿀 때는 `pressedBackgroundBorderRadius` 도 같은 값으로 바꿉니다. 눌림 면의 모서리는 `borderRadius` 를 따라가지 않습니다. 포커스 링은 `borderRadius` 를 따릅니다.

</Note>

`multiple` 의 체크박스에는 `optionItemStyle` 이 닿지 않습니다. Checkbox 테마(`CoreComponentTheme.checkbox`)가 닿으므로, 앱 전체에 주면 다른 Checkbox 도 함께 바뀝니다.

눌림 면은 `pressedBackgroundColor` 로 색을, `stateLayer` 의 눌림 값(기본 100%)으로 보이는 정도를 바꿉니다. `pressedBackgroundOutset` 은 면을 테두리 안쪽에서 좌우로 더 넓히고, `pressedBackgroundInset` 은 위아래를 그만큼 줄입니다. 둘 다 기본값이 0 이라 면이 테두리 안쪽을 채웁니다. `clickableStyle` 의 기본값은 `pressedScale: 1` 과 `disabledOpacity: 1` 입니다 — 눌러도 줄이 작아지지 않고, 비활성 줄을 흐리게 하지 않습니다. 눌림은 눌림 면이, 비활성은 `disabledContent` 색이 이미 보여 주기 때문입니다.

### 빠른 오버라이드 (Chain)

이미 만든 `OptionItem` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `optionItemStyle` 인자와 같게 동작합니다.

```dart
OptionItem(
  label: const Text('최신순'),
  selected: true,
  onPressed: () {},
).withStyle(
  const CoreOptionItemStyle(spacing: CoreSpace.space8),
)
```

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
기본값 (default* · defaultsBySelection[selection])
  → CoreComponentTheme.optionItem.style   // 앱 전체
  → optionItemStyle                       // 인스턴스
```

뒤로 갈수록 우선합니다. 상태에 따라 색이 얹히는 순서는 다음과 같습니다.

- 고른 줄의 라벨은 `labelTextStyle` 을 얹은 라벨 위에 `selection` 별 기본값(색과 SemiBold)이, 그 위에 `selectedLabelTextStyle` 이 얹힙니다. 그래서 `labelTextStyle` 의 색 · 굵기는 고른 줄에서 덮입니다. 고른 줄의 라벨은 `selectedLabelTextStyle` 로 바꿉니다.
- 앞 아이콘에 줄이 내려 주는 색은 `leadingIconStyle` 의 색이고, 없으면 `labelTextStyle` 을 얹은 평소 라벨 색입니다.
- 비활성 줄에서는 `disabledForegroundColor` 가 라벨 · 설명 · 앞 아이콘 · 체크의 색을 덮습니다. `optionItemStyle` 의 다른 필드로 따로 준 색도 덮입니다. 앞 아이콘의 `iconStyle` 이나 Icon 테마로 준 색은 덮지 않습니다([색](#색)).

<a id="접근성-accessibility"></a>

## 접근성

Flutter 는 줄을 버튼으로 알리면서 고른 여부를 함께 싣고, Jaspr Web 은 `role="button"` 인 줄에 `aria-current` 를 붙여 고른 줄을 알립니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 줄 안의 `Clickable` 이 버튼으로 알리고, 고른 여부(`selected`)와 활성 여부(`enabled`)를 함께 알립니다. `multiple` 의 체크박스는 의미 트리에서 빠집니다(`ExcludeSemantics`) — 고른 상태는 줄이 말합니다. |
| Jaspr Web | 줄은 `<div role="button">` 입니다. 고른 줄에는 `aria-current="true"` 가 붙고, 비활성 줄에는 `aria-disabled="true"` 가 붙으며 `tabindex` 가 빠집니다. `multiple` 의 체크박스를 감싼 요소는 `inert` 라 탭 순서와 보조 기술에서 빠집니다. |

### 키보드

| 키 | 동작 |
| --- | --- |
| `Space` · `Enter` | 활성 줄의 `onPressed` 를 부릅니다. 키를 뗄 때가 아니라 누를 때 부릅니다. 비활성 줄은 부르지 않습니다. |
| `Tab` | 다음 요소로 포커스를 옮깁니다. 줄마다 한 번 멈춥니다. |
| `Shift` · `Tab` | 이전 요소로 포커스를 옮깁니다. |

<Note>

Jaspr Web 의 비활성 줄은 탭 순서에서 빠지지만, Flutter 의 비활성 줄은 순서에 남습니다(알려진 제약). 줄과 OptionList 는 화살표 · `Home` · `End` 를 따로 처리하지 않습니다.

</Note>

### 스크린 리더

- **이름** — 이름만 정하는 속성은 없고, 줄 안의 글자가 읽힙니다. Jaspr Web 의 버튼 이름은 `label` 과 `description` 의 글자를 이어 만들어지며, 바꾸려면 `attributes` 로 `aria-label` 을 줍니다.
- **상태** — Flutter 는 고른 여부와 비활성을 알립니다. Jaspr Web 은 고른 줄을 `aria-current` 로, 비활성을 `aria-disabled` 로 알리고, 고르지 않은 줄에는 상태를 따로 붙이지 않습니다.
- **알림** — 값이 바뀐 사실을 따로 알리는 라이브 리전은 없습니다.

### 포커스 관리

마운트될 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. 포커스 링은 키보드로 포커스했을 때만 카드 바깥에 나타납니다. Jaspr Web 은 활성 줄을 마우스로 누르면 그 줄에 포커스가 가지만 링은 보이지 않습니다. Flutter 는 눌러도 포커스를 옮기지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | 비활성 줄도 `Tab` 으로 닿고 포커스 링이 그려집니다. `Space` · `Enter` 를 눌러도 아무 일도 없습니다. |
| Jaspr Web | 키보드(`Space` · `Enter`)로 누를 때 눌림 면이 나타나지 않습니다. 눌림 면의 CSS 규칙이 `:active` 만 보는데, `<div>` 에는 키보드 입력으로 `:active` 가 켜지지 않습니다. |
| Jaspr Web | `eventHandlers` 에 준 `click` · `mousedown` · `mouseup` · `mouseenter` · `mouseleave` · `focusout` · `keydown` · `keyup` 핸들러는 불리지 않습니다. 같은 이벤트를 줄이 직접 쓰면서 덮기 때문입니다. 누름은 `onPressed` 로 받습니다. |
| Jaspr Web | 줄 안에 버튼이나 링크를 넣으면, 그것을 눌러도 줄의 `onPressed` 가 함께 불립니다. |
| Jaspr Web | 고른 상태를 `aria-current` 로 전합니다. 라디오나 체크박스의 선택 상태가 아니므로, 라디오 · 체크박스 그룹 역할이 필요한 폼에는 [RadioGroup](/components/radio-group) · [Checkbox](/components/checkbox) 를 씁니다. |
| 공통 | 줄은 하나만 고르는 목록인지, 목록의 몇 번째인지를 알리지 않습니다. OptionList 는 이름 없이 줄을 묶기만 합니다(Jaspr Web 은 `role="group"`, Flutter 는 의미 트리의 묶음 하나). |
| 공통 | `Space` · `Enter` 를 누르고 있으면 키가 반복될 때마다 `onPressed` 가 다시 불립니다. |
| 공통 | `multiple` 의 체크박스 모양은 `optionItemStyle` 로 바꿀 수 없습니다. |
| 공통 | 눌림 면의 모서리는 카드의 `borderRadius` 를 따라가지 않습니다(위 "테마와 스타일"). |

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은
> [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

두 플랫폼은 속성의 이름 · 순서 · 기본값이 같고, 렌더링은 각 플랫폼의 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 줄의 구성 | `Clickable` 안의 최소 높이 상자 → 바탕 · 테두리 → `Stacks`(눌림 면 + 여백 안의 `Row`) | `Clickable` 의 `<div>`(바탕 · 테두리) 안에 눌림 면 · 앞 아이콘 · 글 · 표시 |
| 테두리와 여백 | 상자 장식의 테두리라 자리를 차지하지 않습니다 | CSS `border`. 여백에서 테두리 두께를 빼 글의 자리를 맞춥니다 |
| 눌림 면 | 누르는 동안에만 테두리 안쪽에 그립니다 | 늘 있는 `<div>` 를 `:active` 규칙이 칠하면서 `z-index: -1` 로 내립니다. 줄이 자기 쌓임 맥락(`isolate`)을 만들어, 누르는 동안 면은 바탕 위 · 글 아래에 놓입니다 |
| 눌림 감지 | `Clickable.onPressedChange` | CSS `:active` |
| 키보드로 누를 때 | 눌림 면을 잠깐 보입니다 | 눌림 면을 보이지 않습니다 |
| 눌림 면의 전환 | 없습니다 | 테마 전환 애니메이션(기본 켜짐)이 켜져 있으면 150ms |
| 고른 상태가 바뀔 때 | 카드 바탕 · 테두리와 라벨이 바로 바뀝니다 | 활성 줄의 바탕 · 테두리 색은 100ms, 라벨 글자색은 테마 전환 애니메이션이 켜져 있으면 150ms 동안 바뀝니다 |
| 설명이 있는 줄에 내용보다 큰 `minHeight` | 내용 묶음을 세로 가운데에 둡니다 | 내용 묶음을 위쪽에 둡니다 |
| `clickableStyle.borderRadius` | 포커스 링의 모서리만 바꿉니다 | 포커스 링과 카드가 같은 `<div>` 라 카드 모서리도 바꿉니다. `optionItemStyle`(또는 OptionItem 테마)의 `borderRadius` 가 있으면 그 값이 이깁니다 |
| 비활성 줄의 포커스 | `Tab` 으로 닿고 링이 그려집니다 | `Tab` 으로 닿지 않습니다 |
| 마우스로 눌렀을 때 포커스 | 옮기지 않습니다 | 활성 줄로 옮깁니다(링은 없음) |
| 고른 상태 알림 | `Semantics(selected:)` | `aria-current="true"` |
| `multiple` 의 체크박스 | `IgnorePointer` · `ExcludeFocus` · `ExcludeSemantics` 로 감쌉니다 | `inert` · `pointer-events-none` 이 붙은 `<div>` 로 감쌉니다 |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers`(일부 이벤트는 불리지 않습니다 — 알려진 제약) |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. 표의 `Widget` 은 Jaspr Web 에서 `Component` 입니다. Jaspr Web 은 여기에 `id` · `classes` · `css` · `attributes` · `eventHandlers` 를 더 받습니다.

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `Widget` | 필수 | 선택지의 이름 |
| `description` | `Widget?` | `null` | 라벨 아래의 짧은 한 줄. 없으면 그 줄을 그리지 않습니다. |
| `leading` | `Widget?` | `null` | 라벨 앞의 아이콘. 없으면 자리를 만들지 않습니다. |

### 상태와 겉모습

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `selection` | `CoreOptionItemSelection` | `single` | `single` 또는 `multiple` ([선택 방식](#선택-방식)) |
| `selected` | `bool` | `false` | 이 줄이 골라졌는지 |
| `enabled` | `bool?` | `null` | 지정하지 않으면 `onPressed` 가 있을 때 활성입니다. |
| `onPressed` | `void Function()?` | `null` | 활성 줄을 누르면 불립니다. |
| `optionItemStyle` | `CoreOptionItemStyle?` | `null` | 보이는 값 덮어쓰기 |

이미 만든 줄에는 `withStyle` 로 같은 값을 덧붙일 수 있습니다([빠른 오버라이드](#빠른-오버라이드-chain)).

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreOptionItemStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `padding` | `CoreEdgeInsets?` | Inset of the row's content (pre-scaling). `null` → [defaultPadding]. |
| `spacing` | `double?` | Space between the parts of the row — leading, text, mark (logical px, pre-scaling). `null` → [defaultSpacing]. |
| `minHeight` | `double?` | The card's least height (logical px, pre-scaling) — a floor: a row with a description grows past it. `null` → [defaultMinHeight]. |
| `borderRadius` | `CoreBorderRadius?` | Corner of the card. `null` → [defaultBorderRadius]. |
| `borderColor` | `CoreColor?` | Colour of the card's border at rest — and of a chosen row that is disabled. `null` → [defaultBorderColor]. |
| `borderWidth` | `double?` | Width of the card's border at rest (logical px). `null` → [defaultBorderWidth]. |
| `selectedBackgroundColor` | `CoreColor?` | Fill of a chosen row. `null` → [defaultSelectedBackgroundColor]. |
| `selectedBorderColor` | `CoreColor?` | Colour of a chosen row's border. `null` → [defaultSelectedBorderColor]. |
| `selectedBorderWidth` | `double?` | Width of a chosen row's border (logical px). `null` → [defaultSelectedBorderWidth]. |
| `disabledSelectedBackgroundColor` | `CoreColor?` | Fill of a chosen row that is disabled. Its border stays the resting one. `null` → [defaultDisabledSelectedBackgroundColor]. |
| `labelTextStyle` | `CoreTextStyle?` | Text style of the label, merged on top of [defaultLabelTextStyle]. |
| `selectedLabelTextStyle` | `CoreTextStyle?` | What a chosen row's label states over [labelTextStyle] — its colour and weight. A chosen row that is disabled keeps this weight and takes [disabledForegroundColor] for its ink. `null` → the entry of [defaultsBySelection] for the row's selection. |
| `descriptionTextStyle` | `CoreTextStyle?` | Text style of the description, merged on top of [defaultDescriptionTextStyle]. |
| `descriptionGapStyle` | `CoreGapStyle?` | Space between the label and the description. `null` → [defaultDescriptionGapStyle]. |
| `leadingIconStyle` | `CoreIconStyle?` | Size of the leading glyph. `null` → [defaultLeadingIconStyle]. |
| `checkIconStyle` | `CoreIconStyle?` | Size and colour of the check mark of a chosen single-selection row. `null` → [defaultCheckIconStyle]. |
| `disabledForegroundColor` | `CoreColor?` | Colour of the label, description, leading glyph and check mark of a disabled row. `null` → [defaultDisabledForegroundColor]. |
| `pressedBackgroundColor` | `CoreColor?` | The colour of the pressed face — shown at [stateLayer]'s pressed weight. `null` → [defaultPressedBackgroundColor]. |
| `stateLayer` | `CoreStateLayer?` | How strongly the pressed face shows. `null` → [defaultStateLayer]. |
| `pressedBackgroundBorderRadius` | `CoreBorderRadius?` | Corner of the pressed face, measured at the card's outer edge like [borderRadius]. The face is drawn inside the border, so its own corner is this less the border width in effect (the resting or the chosen one) — concentric with the border's inner curve. `null` → [defaultPressedBackgroundBorderRadius]. |
| `pressedBackgroundOutset` | `double?` | How far the pressed face reaches past each side of the inside of the card's border (logical px, pre-scaling). `null` → [defaultPressedBackgroundOutset]. |
| `pressedBackgroundInset` | `double?` | How far the pressed face stops short of the top and bottom of the inside of the card's border (logical px, pre-scaling). `null` → [defaultPressedBackgroundInset]. |
| `clickableStyle` | `CoreClickableStyle?` | Style for the row's `Clickable` — focus ring, press feedback. `null` → [defaultClickableStyle]. Passed to the `Clickable` as is. |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 설명은 소스 주석에서 만들어지며, 두 필드는 설명이 지금 동작을 다 담지 못합니다.

- `leadingIconStyle` — 앞 아이콘의 크기뿐 아니라 색도 정합니다. 색을 주지 않으면 라벨의 평소 색입니다.
- `clickableStyle` — 받은 값만 넘기지 않고, 줄의 기본값(`pressedScale: 1` · `disabledOpacity: 1`)과 카드의 `borderRadius` 위에 합쳐 `Clickable` 에 넘깁니다. 일부 값만 주면 나머지는 줄의 값이 남습니다. 모서리를 줄 때의 플랫폼 차이는 [플랫폼 차이](#플랫폼-차이)에 있습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="option-item/related-option-list" title="OptionList">

줄을 세로로 쌓는 묶음입니다. [OptionList](/components/option-list) 문서에서 목록의 속성을 봅니다.

</Card>
<Card component="checkbox" props="checked=true" label="약관에 동의합니다" title="Checkbox">

`multiple` 줄 끝의 표시이고, 목록이 아닌 단독 확인 항목에도 씁니다.

</Card>
<Card component="select" props="placeholder=정렬 기준" title="Select">

선택지를 드롭다운 안에 접어 두고 하나를 고릅니다.

</Card>
</Cards>

선택이 아니라 동작을 실행하는 메뉴 줄은 [MenuItem](/components/menu-item) 입니다.
