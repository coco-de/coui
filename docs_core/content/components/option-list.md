---
title: OptionList
description: OptionItem 줄을 세로로 쌓아 선택지 한 목록으로 보여 주는 묶음입니다. 바텀시트나 패널 안에 정렬 · 필터 선택지를 모아 놓을 때 씁니다.
category: form
platforms: [flutter, web]
related: [option-item, menu, select]
tags: [form, option, selection, list]
template: v2
source: form/option_list
---

# OptionList

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

간격과 선택 방식을 바꿔 보며 목록을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="option-list" />

OptionList 는 [OptionItem](/components/option-item) 같은 줄을 위에서 아래로 쌓고, 줄마다 목록의 폭을 채웁니다. 어느 줄을 골랐는지는 목록이 기억하지 않습니다. 줄을 누르면 그 줄의 `onPressed` 만 불리므로, 호출자가 새 `selected` 값을 줄에 다시 넘겨야 화면이 바뀝니다. 그래서 무대의 줄은 눌러도 선택이 바뀌지 않습니다.

<a id="구조-anatomy"></a>

## 구조

목록은 줄을 담는 틀 하나와, 그 안에 위에서 아래로 놓이는 줄로 이루어집니다.

<Anatomy demo="option-list/anatomy">
<AnatomyItem part="container" name="Container">

줄을 세로로 쌓는 틀. 줄 사이를 `spacing`(기본 8)만큼 띄우고 줄마다 목록의 폭을 채웁니다. 틀 자체에는 채움 · 테두리 · 안쪽 여백이 없습니다.

</AnatomyItem>
<AnatomyItem select="[role=button]" side="right" name="row">

선택지 한 줄. `children` 에 넣은 순서대로 놓입니다. 보통 [OptionItem](/components/option-item) 이고, 테두리 · 채움 · 라벨 · 선택 표시처럼 줄 안의 모양은 줄이 정합니다.

</AnatomyItem>
</Anatomy>

`children` 은 위젯(Jaspr Web 은 Component) 목록이라 다른 것도 담을 수 있습니다. 목록은 받은 것을 순서대로 쌓기만 하고, 선택 표시나 누르는 동작을 더하지 않습니다.

Figma: [CoUI 라이브러리 파일](https://www.figma.com/design/9FgsLhiWz0aLsVqcoI6nYJ/CoUI---Cocode-Design-System-v1.0)의 `OptionList` 페이지

## 선택 방식

선택 방식은 목록이 아니라 줄마다 `selection` 과 `selected` 로 정합니다.

<Preview demo="option-list/selection" />

| 선택 방식 | 줄에 넘기는 것 | 선택 표시 |
| --- | --- | --- |
| single (기본) | `selected` | 고른 줄 끝에만 체크 표시 |
| multiple | `selection: CoreOptionItemSelection.multiple` 과 `selected` | 모든 줄 끝에 체크박스 |

목록은 한 줄만 고르도록 막지 않습니다. 하나만 고르는 목록이면 호출자가 한 줄에만 `selected: true` 를 줍니다.

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

여러 줄을 고르는 목록은 모든 줄에 `selection: CoreOptionItemSelection.multiple` 을 주고, 누를 때마다 고른 값에 넣거나 뺍니다.

```dart
OptionList(
  children: [
    for (final tag in tags)
      OptionItem(
        selection: CoreOptionItemSelection.multiple,
        label: Text(tag.name),
        selected: chosen.contains(tag),
        onPressed: () => toggle(tag),
      ),
  ],
)
```

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>
<a id="상태-전환"></a>
<a id="애니메이션"></a>

## 상태

목록에는 자기 상태가 없습니다. 눌림 · 포커스 · 선택 · 비활성은 모두 줄의 것입니다. 아래 미리보기의 가운데 줄은 `enabled: false` 입니다.

<Preview demo="option-list/disabled" />

| 항목 | 동작 |
| --- | --- |
| 누를 때 | 누른 줄의 `onPressed` 만 불립니다. 선택을 알려 주는 콜백이 목록에는 없습니다. |
| 선택 | 줄의 `selected` 가 정합니다. 값을 바꾸는 쪽은 호출자입니다. |
| 비활성 | 목록에는 `enabled` 가 없습니다. 막을 줄마다 `enabled: false` 를 줍니다. 줄의 `enabled` 를 지정하지 않으면 `onPressed` 가 없는 줄이 비활성입니다. 키보드에서 두 플랫폼이 다른 점은 [키보드](#키보드)에 있습니다. |
| 전환 애니메이션 | 목록에는 없습니다. |

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

바텀시트나 패널 안에서 `OptionItem` 여러 줄을 한 목록으로 놓을 때 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 누르면 동작을 실행하는 줄의 목록일 때 | [Menu](/components/menu) |
| 목록을 트리거의 드롭다운 안에 접어 둘 때 | [Select](/components/select) |
| 고른 값을 폼에 전달하거나, 화살표 키로 옮겨 가며 하나를 고르게 할 때 | [RadioGroup](/components/radio-group) |

<a id="do"></a>
<a id="dont"></a>

### 선택 방식과 간격

<Cards columns="2">
<Card demo="option-list/do-same-selection" tone="do" eyebrow="이렇게 하세요">

한 목록의 줄은 같은 `selection` 으로 맞춥니다.

</Card>
<Card demo="option-list/dont-mixed-selection" tone="dont" eyebrow="이렇게 하지 마세요">

한 목록에 체크 표시와 체크박스가 섞이면 고르는 방식이 줄마다 달라 보입니다.

</Card>
<Card component="option-list" props="spacing=4" tone="do" eyebrow="이렇게 하세요">

줄 사이를 좁히거나 넓힐 때는 `optionListStyle` 의 `spacing` 을 바꿉니다. 위 목록은 4 입니다.

</Card>
<Card demo="option-list/dont-divider" tone="dont" eyebrow="이렇게 하지 마세요">

줄 사이에 `Divider` 를 직접 끼우지 않습니다. 줄마다 테두리가 있어 선이 하나 더 생기고, 선의 위아래에 `spacing` 이 한 번씩 붙어 목록이 벌어집니다.

</Card>
</Cards>

## 배치

| 항목 | 동작 |
| --- | --- |
| 폭 | 부모가 준 폭을 채우고, 줄마다 목록의 폭을 채웁니다. |
| 높이 | 줄의 높이와 줄 사이 `spacing` 의 합입니다. |
| 순서 | `children` 순서대로 위에서 아래로 놓습니다. |
| 스크롤 | 스스로 스크롤하지 않고 모든 줄을 한 번에 만듭니다. 줄이 많으면 스크롤 영역 안에 둡니다. [BottomSheet](/components/bottom-sheet) 의 `content` 에 넣으면, 시트가 최대 높이를 넘는 내용을 내용 영역 안에서 스크롤합니다. |
| Flutter 의 `Row` 안 | `Row` 처럼 자식의 가로 길이를 정해 주지 않는 부모에 바로 넣으면 레이아웃 오류가 납니다. `Expanded` 나 `SizedBox` 로 폭을 정해 줍니다. |

<a id="스타일-시스템-style-system"></a>
<a id="optionliststyle"></a>

## 테마와 스타일

목록에서 바꿀 수 있는 겉모습은 줄 사이 간격 하나이고, `optionListStyle`(`CoreOptionListStyle`)로 덮어씁니다. 무엇을 담을지는 `children` 으로 정합니다. 줄의 모양은 각 줄의 `optionItemStyle` 이나 앱 전체의 `CoreComponentTheme.optionItem` 으로 바꿉니다.

| 부분 | 필드 | 기본값 |
| --- | --- | --- |
| 줄 사이 간격 | `spacing` | 8 (테두리를 가진 줄과 줄 사이) |

기본값 8 은 간격 단계의 값이라 밀도(`CoreDensity`)를 따릅니다. `compact` 에서는 4, `spacious` 에서는 12 가 됩니다.

<a id="사용-예"></a>

<Split>

<Code language="dart" title="목록 하나만 바꾸기">
OptionList(
  optionListStyle: CoreOptionListStyle(spacing: CoreSpace.space4),
  children: rows,
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    optionList: CoreOptionListTheme(
      style: CoreOptionListStyle(spacing: CoreSpace.space4),
    ),
  ),
)
</Code>

</Split>

### 빠른 오버라이드 (Chain)

이미 만든 `OptionList` 에는 `withStyle` 로 스타일을 덧붙입니다. 생성자의 `optionListStyle` 인자와 같게 동작하고, 겹치는 필드는 뒤에 붙인 값이 이깁니다.

```dart
OptionList(children: items).withStyle(
  const CoreOptionListStyle(spacing: CoreSpace.space4),
)
```

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
기본값 (CoreOptionListStyle.defaultSpacing)
  → CoreComponentTheme.optionList.style     // 앱 전체
  → optionListStyle                         // 인스턴스
```

뒤로 갈수록 우선합니다.

<a id="접근성-accessibility"></a>

## 접근성

목록은 줄을 한 덩어리로 감싸기만 합니다. 줄마다의 역할 · 선택 · 비활성 알림과 키 처리는 줄이 맡습니다. 아래에서 줄에 관한 내용은 줄이 `OptionItem` 일 때의 동작입니다.

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은 [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

### 역할

| 플랫폼 | 목록 | 줄 (`OptionItem`) |
| --- | --- | --- |
| Flutter | `CoUISemantics(role: .group, container: true)` 로 목록을 시맨틱 경계 하나로 감쌉니다. "그룹" 이라는 역할은 알리지 않습니다. | 버튼입니다. 고른 줄인지(selected)와 활성인지도 알립니다. |
| Jaspr Web | 루트 `<div>` 에 `role="group"` 을 붙입니다. | `role="button"` 입니다. 고른 줄에는 `aria-current="true"`, 비활성 줄에는 `aria-disabled="true"` 가 붙습니다. |

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` · `Shift` · `Tab` | 줄을 화면 순서대로 옮겨 다닙니다. 비활성 줄에도 멈춥니다. | 활성 줄만 화면 순서대로 옮겨 다닙니다. 비활성 줄은 건너뜁니다. |
| `Enter` · `Space` | 포커스된 줄의 `onPressed` 를 부릅니다. 비활성 줄에서는 아무 일도 하지 않습니다. | 포커스된 줄의 `onPressed` 를 부릅니다. |

목록 자체는 포커스를 받지 않습니다. 목록과 `OptionItem` 은 화살표 · `Home` · `End` 키를 직접 처리하지 않으므로, 하나만 고르는 목록도 라디오처럼 화살표로 선택이 바뀌지 않습니다. Flutter 네이티브 앱에서는 Flutter 의 기본 단축키가 위 · 아래 화살표로 줄 사이의 포커스만 옮깁니다. Flutter Web 의 기본 단축키는 화살표를 스크롤에 쓰고 Jaspr Web 은 화살표를 처리하지 않아, 두 곳에서는 화살표로 포커스가 옮겨 가지 않습니다.

### 스크린 리더

- 목록에는 접근 가능한 이름이 없습니다. 줄의 라벨이 곧 내용이고, 줄은 `children` 순서대로 읽힙니다.
- 목록은 줄이 몇 개인지, 지금 몇 번째 줄인지 알리는 정보를 붙이지 않습니다.
- 고른 줄은 Flutter 에서는 선택됨(selected)으로, Jaspr Web 에서는 `aria-current="true"` 로 알립니다. multiple 의 체크박스는 두 플랫폼 모두 보조 기술에서 숨깁니다.
- 선택이 바뀐 사실을 따로 알리는 라이브 리전은 없습니다.

### 포커스 관리

목록은 마운트될 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. 포커스 링은 키보드로 포커스한 줄이 자기 모서리를 따라 그립니다. Flutter 는 비활성 줄에 포커스가 가면 그 줄에도 링을 그립니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 목록에 이름을 붙이는 전용 속성이 없습니다. 이름이 필요하면 Jaspr Web 은 `attributes: {'aria-label': '정렬 기준'}` 을 주고, Flutter 는 `Semantics(container: true, label: '정렬 기준', child: ...)` 로 목록을 감쌉니다. |
| 공통 | 선택지 목록 역할(`listbox` · `radiogroup`)이 없고, 화살표로 선택을 바꾸는 동작이 없습니다. 하나만 고르는 목록도 줄마다 `Tab` 으로 멈추는 버튼들입니다. |
| 공통 | 목록과 `OptionItem` 에는 고른 값을 폼에 넘기는 기능이 없습니다. 그런데 multiple 줄 안의 체크박스는 감싼 `FormField` 가 있으면 자기 체크 여부(`true` · `false`)를 그 필드에 보고합니다. 여러 줄이 한 `FormField` 안에 있으면 마지막으로 보고한 체크박스의 값이 필드 값이 됩니다. multiple 목록은 `FormField` 안에 두지 말고, 고른 값은 호출자가 따로 폼에 넘깁니다. |
| Flutter | 비활성 줄이 `Tab` 순서에 남고, 포커스 링도 그려집니다. `Enter` · `Space` 를 눌러도 아무 일이 일어나지 않습니다. Jaspr Web 은 비활성 줄을 건너뜁니다. |
| Jaspr Web | 고르지 않은 줄에는 선택 상태가 붙지 않고, multiple 의 체크박스는 `inert` 라 보조 기술에 닿지 않습니다. 고르지 않은 줄이 고를 수 있는 선택지라는 것을 상태로는 알리지 않습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 클래스명 | `OptionList` | `OptionList` |
| 루트 | `CoUISemantics` 안의 `Column`(가로 `stretch`, 높이는 줄만큼) | `<div role="group">`(세로 flex, 줄 사이는 `gap`) |
| 목록의 역할 | 시맨틱 경계만 둡니다 | `role="group"` |
| 비활성 줄과 `Tab` | 멈춥니다 | 건너뜁니다 |
| 위 · 아래 화살표 | 네이티브 앱에서는 기본 단축키가 포커스만 옮기고, Flutter Web 에서는 스크롤에 씁니다 | 포커스를 옮기지 않습니다 |
| 고른 줄 알림 | 선택됨(selected) | `aria-current="true"` |
| 가로 길이를 정해 주지 않는 부모 | 레이아웃 오류가 납니다 | 오류 없이 부모 폭의 100%(`w-full`)를 폭으로 잡습니다 |
| 간격의 크기 배율 | 테마의 크기 배율(`scaling`)을 곱합니다 | CSS 변수나 `rem` 으로 그려 브라우저의 글자 크기를 따릅니다 |
| 단계 밖 간격(예: 13)과 밀도 | 밀도에 따라 다음 칸으로 옮겨집니다 | 적은 값 그대로 그려, 밀도가 닿지 않습니다 |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` 가 루트 `<div>` 에 붙습니다 |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. `W` 는 Flutter 의 `Widget`, Jaspr Web 의 `Component` 입니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `children` | `List<W>` | 필수 | 위에서 아래로 쌓을 줄. 보통 `OptionItem` |
| `optionListStyle` | `CoreOptionListStyle?` | `null` | 줄 사이 간격 덮어쓰기. 비우면 테마의 값을, 그다음 8 을 씁니다. |

두 플랫폼 모두 `key` 를 받습니다. Jaspr Web 은 루트 `<div>` 에 붙는 `id` · `classes` · `css` · `attributes` · `eventHandlers` 도 받습니다. `attributes` 에 `role` 을 주면 `role="group"` 대신 그 값이 붙습니다.

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreOptionListStyle patch)` | `optionListStyle` 에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다. |
| `copyWith({children, optionListStyle, key})` | 바꾼 값으로 사본을 만듭니다. Jaspr Web 은 `id` · `classes` · `css` · `attributes` · `eventHandlers` 도 받습니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.optionList` | `CoreOptionListTheme?` | 앱 전체의 목록 모양. `style`(`CoreOptionListStyle?`) 하나를 가집니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreOptionListStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `spacing` | `double?` | Space between two rows (logical px, pre-scaling). `null` → [defaultSpacing]. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="option-list/related-option-item" title="OptionItem">

목록의 줄 하나입니다. 선택 표시 · 눌림 · 비활성은 줄이 정합니다.

</Card>
<Card demo="option-list/related-menu" title="Menu">

누르면 동작을 실행하는 줄의 목록입니다.

</Card>
<Card component="select" props="placeholder=정렬 기준" title="Select">

목록을 드롭다운 안에 접어 두고 하나를 고릅니다.

</Card>
</Cards>
