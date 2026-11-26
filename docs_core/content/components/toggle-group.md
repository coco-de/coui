---
title: ToggleGroup
description: 옵션 여럿을 한 트랙에 묶어 하나만 고르게 하고, 고른 칸을 위로 띄우는 묶음 토글입니다. 두세 개의 옵션을 그 자리에서 바로 바꿀 때 씁니다.
category: form
platforms: [flutter, web]
related: [filter, tabs, radio-group]
tags: [form-control, segmented, selection, toggle]
template: v2
source: control/toggle_group
---

# ToggleGroup

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

크기 · 방향 · 칸 모양을 바꿔 보며 묶음 토글을 확인하고, 만들어진 코드를 그대로 복사하세요. 미리보기의 칸을 누르면 선택이 옮겨 갑니다.

<Playground component="toggle-group" />

`ToggleGroup` 은 선택값을 스스로 바꾸지 않습니다. 칸을 누르면 `onChanged` 로 그 칸의 값을 알리고, 호출자가 그 값을 `value` 로 다시 넘겨야 선택이 옮겨 갑니다. 이미 고른 칸을 다시 눌러도 같은 값으로 `onChanged` 를 부릅니다. 목록 필터([Filter](/components/filter))의 칸, 시간 선택기([TimePicker](/components/time-picker))의 오전 / 오후, 색 선택기([ColorPicker](/components/color-picker))의 모드 탭이 모두 이 컴포넌트를 안에 그려 같은 모양을 씁니다.

```dart
ToggleGroup<String>(
  value: period,
  onChanged: (next) => setState(() => period = next),
  items: const [
    CoreToggleGroupItem(value: 'am', label: '오전'),
    CoreToggleGroupItem(value: 'pm', label: '오후'),
  ],
)
```

Flutter 와 Jaspr Web 이 같은 코드를 씁니다. 칸은 `items` 에 `CoreToggleGroupItem` 으로 줍니다. 칸의 `value` 는 서로 다르게 둡니다 — 묶음의 `value` 와 `==` 로 같은 칸이 고른 칸이 되므로, 값이 같은 칸이 둘이면 둘 다 고른 모양이 됩니다.

<a id="구조-anatomy"></a>

## 구조

묶음 토글은 트랙과 그 위에 놓인 칸으로 이루어집니다. 칸 하나는 아이콘과 라벨을 가지고, 마지막 칸 뒤에는 트랙 안에 위젯을 덧붙이는 `trailing` 자리가 있습니다.

<Anatomy demo="toggle-group/anatomy">
<AnatomyItem part="container" name="track">

칸을 담는 바탕입니다. 고른 칸이 아닌 곳은 트랙의 채움(`surfaceContainer`)이 그대로 보입니다.

</AnatomyItem>
<AnatomyItem part="leading" side="top" name="icon">

라벨 앞의 아이콘(`CoreToggleGroupItem.icon`)입니다. 선택 사항입니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="label">

칸의 글자(`CoreToggleGroupItem.label`)입니다. `showLabel: false` 면 그리지 않고 접근성 이름으로만 남습니다.

</AnatomyItem>
<AnatomyItem select="[aria-checked=true]" side="top" name="segment">

값 하나를 고르는 칸입니다. 고른 칸만 `surfaceRaised` 면과 그림자를 가집니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=trailing]" side="right" name="trailing">

마지막 칸 뒤, 트랙 안에 덧붙인 위젯입니다. 칸이 아니라서 선택에 참여하지 않습니다.

</AnatomyItem>
</Anatomy>

<Note>

`surfaceContainer` 로 채운 면(네이티브 문서 앱의 무대가 그렇습니다) 위에서는 트랙의 기본 채움(`surfaceContainer`)이 바탕에 묻혀 트랙의 경계가 보이지 않고, 고른 칸의 면만 구분됩니다. CoUI 라이트의 비활성 트랙(`disabledContainer`)도 같은 색입니다. `surface` 바탕인 웹 문서의 미리보기에서는 트랙이 보입니다.

</Note>

<a id="레이아웃"></a>

## 크기

`md`(기본)와 `sm` 두 단계가 있습니다. 표준 밀도에서 `md` 트랙(4 + 32 + 4)은 40 이라 같은 줄의 `md` TextField · Button 과 높이가 맞고, `sm` 트랙(3 + 26 + 3)은 32 라 `sm` 컨트롤과 높이가 맞습니다. 판 안에 놓는 묶음(TimePicker 의 오전 / 오후, ColorPicker 의 모드 탭)은 `sm` 을 씁니다.

<SizeSpec component="toggle-group" props="options=2" />

<Note>

두 크기가 다르게 정하는 값은 트랙 안쪽 여백, 트랙 모서리, 칸 높이, 칸 좌우 여백, 라벨 글자 역할(`md` 는 `labelLarge`, `sm` 은 `labelMedium`)입니다. 칸 모서리 6, 라벨의 좌우 여백 8, 아이콘 16, 칸 사이 간격 2 는 두 크기가 같습니다. `md` 의 칸 모서리 6 은 트랙 모서리 10 에서 안쪽 여백 4 를 뺀 값이라 트랙과 칸의 모서리가 같은 중심을 씁니다. `xs` · `lg` · `xl` · `xl2` 는 크기 행이 없어 `md` 로 그립니다.

</Note>

- 칸 높이는 크기 단계가 정한 값(`itemHeight`)으로 고정이고, 칸 안의 내용은 가로 · 세로 모두 가운데입니다.
- 칸은 높이보다 좁아지지 않습니다(최소 폭 = 칸 높이). 내용 크기인 가로 묶음에서 아이콘만 있는 칸은 `md` 32 × 32, `sm` 26 × 26 정사각형이 되고, 높이보다 넓은 라벨 칸은 제 폭 그대로입니다.
- 라벨 칸의 폭은 고른 칸의 굵은 글자까지 담도록 잡습니다. 그래서 선택이 옮겨 가도 묶음의 폭이 변하지 않습니다.
- 앱 밀도(`compact` · `spacious`)는 칸 높이, 트랙 안쪽 여백(4 · 3), 칸 사이 간격 2 를 바꾸지 않습니다. 라벨 좌우 여백 8 은 `compact` 에서 4, `spacious` 에서 12 가 됩니다. 모서리는 `spacious` 에서 트랙과 칸이 모두 한 단 커지고, `compact` 에서는 `md` 트랙 모서리만 10 에서 8 로 줄어듭니다.
- 옆에 놓는 TextField · Button 의 행 높이는 밀도를 따라 움직입니다. `compact` 에서는 `md` 컨트롤이, `spacious` 에서는 `md` · `sm` 컨트롤이 묶음 토글과 높이가 달라집니다.

<a id="변형-variants"></a>

## 형태

칸은 라벨만, 아이콘과 라벨, 아이콘만의 세 모양입니다. 칸마다 `icon` 과 `showLabel` 로 정합니다.

<Cards columns="3">
<Card component="toggle-group" props="options=2" title="라벨">

`label` 만 줍니다. 기본 모양입니다.

</Card>
<Card component="toggle-group" props="options=2;icon=true" title="아이콘 + 라벨">

`icon` 을 라벨 앞에 그립니다.

</Card>
<Card component="toggle-group" props="options=2;showLabel=false" title="아이콘만">

`showLabel: false` 로 라벨을 그리지 않습니다. 라벨은 접근성 이름으로 남습니다.

</Card>
</Cards>

### 아이콘 칸

```dart
ToggleGroup<String>(
  value: view,
  onChanged: setView,
  items: const [
    CoreToggleGroupItem(value: 'grid', label: '격자', icon: Icon(LucideIcons.layoutGrid)),
    CoreToggleGroupItem(value: 'list', label: '목록', icon: Icon(LucideIcons.list), showLabel: false),
  ],
)
```

아이콘의 색과 크기는 상태마다 `iconStyle`(고르지 않은 칸), `selectedIconStyle`(고른 칸), `disabledIconStyle`(비활성)이 정합니다. 기본 크기는 16 입니다. `showLabel: false` 를 주면서 `icon` 을 비우면 빈 칸이 되므로, 라벨을 숨길 때는 아이콘을 함께 줍니다. 긴 라벨을 자르거나 말줄임하는 처리는 없습니다.

<a id="동작-스펙-behavior"></a>
<a id="시각"></a>

## 상태

묶음 토글에는 variant 가 없습니다. 어느 칸을 골랐는지와 `enabled` 가 모양을 정합니다.

<Preview demo="toggle-group/states" />

| 항목 | 동작 |
| --- | --- |
| 트랙 | `surfaceContainer` 채움입니다. |
| 고른 칸 | `surfaceRaised` 면과 가장 작은 그림자 단계(`CoreShadow.xs`)를 가집니다. 라벨 · 아이콘은 `onSurface`, 라벨 굵기는 600 입니다. |
| 고르지 않은 칸 | 채움이 없어 트랙이 보입니다. 라벨 · 아이콘은 `onSurfaceVariant` 입니다. |
| 선택 없음 | `value` 가 `null` 이거나 어느 칸의 값과도 같지 않으면 아무 칸도 고른 모양이 아닙니다. |
| 고를 때 | 누른 칸의 값으로 `onChanged` 를 부릅니다. 선택은 호출자가 새 `value` 를 넘길 때 옮겨 갑니다. |
| Hover | 마우스를 올린 칸 위에 `onSurface` 3% 를 칸 모양 그대로 덮습니다. 고른 칸도 면 위에 같은 표시를 받고, 면 색과 그림자는 그대로입니다. 색은 `stateLayerColor`, 세기는 `stateLayer` 의 `hover`(기본 3%)로 바꿉니다. |
| 눌림 | 누르는 칸이 0.97배로 줄어듭니다(100ms). `toggleGroupStyle.clickableStyle` 로 바꿀 수 있습니다. |
| Focus | 키보드로 포커스한 칸 둘레에 링을 그립니다. |
| 전환 시간 | 고른 면의 채움과 그림자가 150ms 동안 바뀝니다. 동작 줄이기를 켜면 바로 바뀝니다. |
| 활성 여부 | `enabled` 를 지정하지 않으면 `onChanged` 가 있을 때 활성입니다. 지정하면 그 값이 우선합니다. |

### 비활성

`onChanged` 가 `null` 이고 `enabled` 를 지정하지 않았거나 `enabled: false` 면, 입력을 받지 않고 납작한 비활성 모양이 됩니다.

- 트랙은 `disabledContainer` 입니다.
- 고른 칸은 `surfaceContainerHigh` 로 가라앉고 그림자가 없습니다.
- 라벨과 아이콘은 고른 칸 · 고르지 않은 칸 모두 `disabledContent` 입니다. 고른 칸의 라벨 굵기는 유지됩니다.
- 칸에는 hover 표시와 눌림 표시가 없고, 칸은 `Tab` 순서에서 빠집니다. 칸 위의 커서는 금지 모양입니다.
- `trailing` 의 위젯은 묶음의 비활성을 따르지 않습니다. 거기 둔 버튼은 그대로 눌리고 `Tab` 도 멈추므로, 함께 막으려면 그 버튼을 따로 끕니다. [Filter](/components/filter) 는 비활성일 때 초기화 버튼을 스스로 끕니다.

칸 하나만 비활성으로 두는 속성은 없습니다. 고를 수 없는 값은 `items` 에서 뺍니다.

<Note>

`enabled: true` 를 주고 `onChanged` 를 `null` 로 두면 색은 활성 모양인데 눌러도 아무 일이 일어나지 않습니다. 커서 · 포커스 · 보조 기술에 전하는 상태는 플랫폼마다 다릅니다(→ 알려진 제약). 읽기 전용으로 보여 줄 때는 `enabled: false` 를 줍니다.

</Note>

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

두세 개(많아도 네 개)의 옵션 중 하나를 그 자리에서 바로 바꿀 때 씁니다. 오전 / 오후, 보기 방식, 모드 탭처럼 옵션이 늘 화면에 모두 보여야 하는 자리에 맞습니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 초기화 버튼이 붙은 목록 필터 | [Filter](/components/filter) |
| 선택에 따라 콘텐츠 패널이 바뀔 때 | [Tabs](/components/tabs) |
| 폼에 값을 싣는 라디오 입력이 필요할 때 (`ToggleGroup` 은 폼 값을 싣지 않습니다) | [RadioGroup](/components/radio-group) |
| 여러 개를 함께 고를 때 | [ChipGroup](/components/chip-group) · [Checkbox](/components/checkbox) |
| 옵션이 다섯 개 이상이거나 라벨이 길 때 | [Select](/components/select) |

### 선택지

<a id="do"></a>
<a id="dont"></a>

<Cards columns="2">
<Card component="toggle-group" props="options=2" tone="do" eyebrow="이렇게 하세요">

이름이 짧은 옵션 2~4개에 씁니다.

</Card>
<Card demo="toggle-group/dont-many" tone="dont" eyebrow="이렇게 하지 마세요">

옵션이 다섯 개 이상이거나 라벨이 길면 쓰지 않습니다. 칸은 한 줄(세로면 한 열)로만 놓이고, 넘쳐도 다음 줄로 넘기거나 스크롤하지 않습니다.

</Card>
<Card component="toggle-group" props="options=3;value=grid" tone="do" eyebrow="이렇게 하세요">

처음부터 하나를 고른 상태로 시작합니다.

</Card>
<Card demo="toggle-group/dont-empty" tone="dont" eyebrow="이렇게 하지 마세요">

`value` 가 `null` 이면 아무 칸도 강조되지 않아, 지금 무엇이 적용 중인지 알 수 없습니다.

</Card>
<Card demo="toggle-group/do-select" tone="do" eyebrow="대신 이렇게 하세요">

옵션이 많아 한 줄에 다 놓기 어려우면 Select 를 씁니다.

</Card>
<Card component="tabs" props="variant=pill;size=sm" tone="do" eyebrow="대신 이렇게 하세요">

콘텐츠 패널을 바꾸는 탭에는 Tabs 를 씁니다. 묶음 토글을 탭으로 쓰지 않습니다.

</Card>
</Cards>

### 묶음의 이름

`ToggleGroup` 에는 묶음의 이름을 정하는 속성이 없습니다. 곁에 보이는 제목을 두고, 스크린 리더에도 묶음의 이름이 필요하면 감싸서 붙입니다.

<Split>

<Code language="dart" title="Flutter">
Semantics(
  container: true,
  label: '보기 방식',
  child: ToggleGroup<String>(
    value: view,
    onChanged: setView,
    items: viewItems,
  ),
)
</Code>

<Code language="dart" title="Jaspr Web">
div(
  attributes: {'role': 'group', 'aria-label': '보기 방식'},
  [
    ToggleGroup<String>(
      value: view,
      onChanged: setView,
      items: viewItems,
    ),
  ],
)
</Code>

</Split>

Jaspr Web 에서 이 이름은 바깥 묶음의 이름이고, 트랙의 `radiogroup` 자신의 이름은 아닙니다(→ 알려진 제약).

<a id="세로"></a>

## 배치

놓는 방향은 `direction`, 폭은 `fillWidth` 로 정합니다.

<Cards columns="2">
<Card component="toggle-group" props="direction=horizontal" title="horizontal">

기본 배치입니다. 칸을 가로 한 줄로 놓고, 트랙은 칸 내용만큼만 차지합니다.

</Card>
<Card component="toggle-group" props="direction=vertical;options=2" title="vertical">

칸을 위에서 아래로 놓습니다.

</Card>
<Card component="toggle-group" props="fillWidth=true" title="fillWidth">

트랙이 부모 폭을 채우고, 가로 묶음의 칸은 그 폭을 똑같이 나눕니다.

</Card>
<Card demo="toggle-group/trailing" title="trailing">

마지막 칸 뒤에 초기화 버튼을 덧붙였습니다.

</Card>
</Cards>

### 방향

`direction: CoreAxis.vertical` 이면 칸이 위에서 아래로 놓입니다(오전 위, 오후 아래).

- 칸은 가장 넓은 칸의 폭(`fillWidth` 면 부모 폭)으로 늘어나고, 내용은 가운데입니다. Flutter 는 `Column` 의 `stretch`, Jaspr Web 은 `flex-col` 과 `items-stretch` 로 맞춥니다.
- 칸 사이 간격 2 와 트랙 안쪽 여백은 가로와 같습니다. 고른 면과 그림자는 칸마다 칠해져 방향과 상관없이 고른 칸을 따라갑니다.
- 칸이 둘인 트랙의 높이는 `sm` 이 3 + 26 + 2 + 26 + 3 = 60, `md` 가 4 + 32 + 2 + 32 + 4 = 74 입니다. 60 은 TimePicker 의 시 · 분 칸 높이와 같아, TimePicker 는 오전 / 오후를 세로 `sm` 으로 시 · 분 칸 옆에 위를 맞춰 놓아 판 폭을 좁게 둡니다.

### 가로 채우기

`fillWidth: true` 면 트랙이 부모가 주는 폭을 채우고, 가로 묶음의 칸은 그 폭을 똑같이 나눕니다(세 칸이면 3등분). 칸 안의 내용은 가운데이고 칸 사이 간격과 트랙 안쪽 여백은 그대로입니다. ColorPicker 의 모드 탭은 아래의 폭을 채운 영역과 가장자리를 맞추려고 이 설정을 씁니다. 부모의 폭이 정해져 있어야 합니다 — Flutter 에서 `Row` 의 바로 아래 자식처럼 가로가 무한한 자리에 두면 레이아웃 오류가 납니다.

### 끝에 덧붙이기

`trailing` 은 트랙 안, 마지막 칸 뒤에 놓는 호출자의 위젯입니다. 칸이 아니라서 선택에 참여하지 않고, 칸 사이 간격 2 는 마지막 칸과 이 위젯 사이에도 들어갑니다. [Filter](/components/filter) 는 여기에 구분선과 초기화 버튼을 둡니다. 안에 아이콘만 있는 버튼을 두면 접근성 이름을 함께 줍니다. Jaspr Web 에서 이 버튼에 포커스가 있을 때의 화살표 · `Home` · `End` 동작은 알려진 제약을 확인하세요.

### 떠 있는 판 위에 놓을 때

팝오버처럼 `surfaceBright` 로 칠한 판 위에서는, 다크 모드의 `surfaceContainer` 트랙이 판과 같은 색이 됩니다. 그래서 TimePicker 의 오전 / 오후와 ColorPicker 의 모드 탭은 트랙 색을 한 단계 위(`surfaceContainerHigh`)로 넘깁니다. 직접 판 위에 놓을 때도 같게 합니다.

비활성 트랙은 `backgroundColor` 가 아니라 `disabledBackgroundColor` 를 읽습니다. 다크 모드에서는 그 기본값 `disabledContainer` 도 판과 같은 색입니다. 판 위의 비활성 묶음에서도 트랙이 보여야 하면 `disabledBackgroundColor` 도 함께 정합니다. 고른 비활성 칸의 면(`disabledSelectedColor`, 기본 `surfaceContainerHigh`)과는 다른 색을 고릅니다.

```dart
ToggleGroup<String>(
  value: view,
  onChanged: setView,
  size: CoreComponentSize.sm,
  items: viewItems,
  toggleGroupStyle: CoreToggleGroupStyle(
    backgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
  ),
)
```

### Figma 세트

Figma 라이브러리의 `ToggleGroup` 세트는 `size` 를 `Size=md | sm`, `fillWidth` 를 `Width=Hug | Fill`, `direction` 을 `Orientation=Horizontal | Vertical` 축으로 나타냅니다. `Vertical` 은 `Size=sm` · `Width=Hug` 조합만 있습니다. TimePicker 의 오전 / 오후와 ColorPicker 의 모드 탭처럼 판 안에 놓는 인스턴스는 `Size=sm` 입니다. `Width=Fill` 인스턴스가 부모 폭을 채우게 하려면 인스턴스의 가로 크기를 FILL 로 둡니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

크기 · 방향 · 폭은 위젯 속성으로 고르고, 트랙과 칸의 색 · 모서리 · 여백 · 글자처럼 보이는 값은 `toggleGroupStyle`(`CoreToggleGroupStyle`) 하나로 덮어씁니다. variant 가 없어 테마에도 `style` 하나만 있습니다.

<a id="테마로-덮어쓰기"></a>

<Split>

<Code language="dart" title="묶음 하나만 바꾸기">
ToggleGroup<String>(
  value: view,
  onChanged: setView,
  items: viewItems,
  toggleGroupStyle: CoreToggleGroupStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    itemBorderRadius: CoreBorderRadius.all(CoreRadius.radius12),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    toggleGroup: CoreToggleGroupTheme(
      style: CoreToggleGroupStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainerHighest),
      ),
    ),
  ),
)
</Code>

</Split>

<Note>

앱 전체 값은 Filter · TimePicker · ColorPicker 안의 묶음 토글에도 닿습니다. 다만 TimePicker 의 오전 / 오후와 ColorPicker 의 모드 탭은 트랙 색을 자기 값으로 넘기므로, 두 곳의 트랙 색은 각각 `amPmToggleStyle` · `modeTabsStyle` 로 바꿉니다. 비활성 묶음은 트랙 · 고른 면 · 글자 · 아이콘에 `disabledBackgroundColor` · `disabledSelectedColor` · `disabledLabelTextStyle` · `disabledIconStyle` 을 읽습니다. 평소의 색(`backgroundColor` · `selectedColor`) · 라벨 스타일(`labelTextStyle` · `selectedLabelTextStyle`) · 아이콘 스타일(`iconStyle` · `selectedIconStyle`)과 `selectedShadow` · `stateLayerColor` · `stateLayer` 는 읽지 않습니다. 고른 칸의 라벨 굵기를 정하는 `selectedFontWeight` 는 비활성에서도 씁니다.

</Note>

### 빠른 오버라이드 (Chain)

이미 만든 `ToggleGroup` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `toggleGroupStyle` 인자와 같게 동작하고, 겹치는 필드는 나중에 덧붙인 값이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ToggleGroupChainExample extends StatefulWidget {
  const ToggleGroupChainExample({super.key});

  @override
  State<ToggleGroupChainExample> createState() => _ToggleGroupChainExampleState();
}

class _ToggleGroupChainExampleState extends State<ToggleGroupChainExample> {
  String? _selected = 'am';

  void handleChanged(String value) {
    setState(() => _selected = value);
  }

  @override
  Widget build(BuildContext context) {
    // withStyle full-control — 트랙 모서리와 선택 면 그림자를 한 번에.
    return ToggleGroup<String>(
      value: _selected,
      onChanged: handleChanged,
      items: const [
        CoreToggleGroupItem(value: 'am', label: '오전'),
        CoreToggleGroupItem(value: 'pm', label: '오후'),
      ],
    ).withStyle(
      const CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        itemBorderRadius: CoreBorderRadius.all(CoreRadius.radius12),
        selectedShadow: CoreShadow.none,
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class ToggleGroupChainExample extends StatefulComponent {
  const ToggleGroupChainExample({super.key});

  @override
  State<ToggleGroupChainExample> createState() => _ToggleGroupChainExampleState();
}

class _ToggleGroupChainExampleState extends State<ToggleGroupChainExample> {
  String? _selected = 'am';

  void handleChanged(String value) {
    setState(() => _selected = value);
  }

  @override
  Component build(BuildContext context) {
    // withStyle full-control — 트랙 모서리와 선택 면 그림자를 한 번에.
    return ToggleGroup<String>(
      value: _selected,
      onChanged: handleChanged,
      items: const [
        CoreToggleGroupItem(value: 'am', label: '오전'),
        CoreToggleGroupItem(value: 'pm', label: '오후'),
      ],
    ).withStyle(
      const CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        itemBorderRadius: CoreBorderRadius.all(CoreRadius.radius12),
        selectedShadow: CoreShadow.none,
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
기본값 (CoreToggleGroupStyle 의 default*)
  → CoreToggleGroupStyle.defaultsBySize[size]   // 크기 행 (sm · md)
  → CoreComponentTheme.toggleGroup.style         // 앱 전체
  → toggleGroupStyle                             // 인스턴스
```

뒤로 갈수록 우선합니다. 라벨 글자는 상태마다의 기본 색 위에 크기 행의 글자 역할이, 그 위에 테마와 인스턴스 값이 얹힙니다. 고른 칸의 라벨 굵기는 `selectedFontWeight`(기본 600)가 정하고, 활성 묶음에서는 `selectedLabelTextStyle` 에 적은 굵기가 그보다 우선합니다. 비활성 묶음의 고른 칸은 `disabledLabelTextStyle` 에 굵기를 적어도 `selectedFontWeight` 를 씁니다.

<a id="접근성-accessibility"></a>

## 접근성

Flutter 는 칸마다 `Semantics(checked:, inMutuallyExclusiveGroup:)` 로, Jaspr Web 은 `role="radio"` 와 `aria-checked` 로 어느 칸을 골랐는지 알립니다. 이 컴포넌트가 직접 다루지 않는 대비 · 모션 같은 전역 축은 [전역 접근성 축](/accessibility) 한 곳에서 관리합니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 칸마다 `Semantics(checked:, inMutuallyExclusiveGroup: true, enabled:, label:)` 로 알립니다. 칸을 감싼 `Clickable` 의 버튼 역할은 끕니다. 트랙에는 묶음 역할이 없습니다. |
| Jaspr Web | 트랙에 `role="radiogroup"`, 칸에 `role="radio"` · `aria-checked` · `aria-label` 이 붙습니다. 비활성이면 트랙과 칸에 `aria-disabled="true"` 가 붙습니다. `trailing` 은 `radiogroup` 안에 놓입니다. 라벨 칸의 폭을 잡는 두 번째 글자는 `aria-hidden="true"` 입니다. |

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` · `Shift` + `Tab` | 칸마다 멈춥니다. | 칸 가운데 한 곳에서만 멈춥니다 — 고른 칸, 고른 칸이 없으면 첫 칸입니다. |
| `Enter` · `Space` | 포커스한 칸을 고릅니다. | 포커스한 칸을 고릅니다. |
| `→` · `↓` | 처리하지 않습니다. | 다음 칸으로 포커스를 옮기고 고릅니다. 끝에서는 처음으로 돌아갑니다. |
| `←` · `↑` | 처리하지 않습니다. | 이전 칸으로 포커스를 옮기고 고릅니다. 처음에서는 끝으로 돌아갑니다. |
| `Home` · `End` | 처리하지 않습니다. | 첫 칸 · 마지막 칸으로 포커스를 옮기고 고릅니다. |

Jaspr Web 은 WAI-ARIA radio group 방식(Tab 정지점 하나, 화살표 이동)을 따르고, 네 화살표는 `direction` 과 상관없이 같게 동작합니다. Flutter 의 `ToggleGroup` 은 화살표를 처리하지 않아 선택이 바뀌지 않습니다. 화살표로 포커스가 옮겨 갈지는 Flutter 의 기본 단축키가 정합니다 — 데스크톱 · 모바일 기본값은 그 방향으로 포커스를 옮기고, Flutter 웹 기본값은 화살표를 스크롤에 씁니다. 비활성 묶음은 두 플랫폼 모두 칸에 `Tab` 정지점이 없고 칸의 키를 처리하지 않습니다. `trailing` 에 둔 버튼은 칸이 아니라서 `Tab` 이 따로 멈추고, 묶음이 비활성이어도 버튼을 따로 끄지 않으면 그대로입니다.

### 스크린 리더

- 칸의 이름은 `CoreToggleGroupItem.label` 에서 옵니다. `showLabel: false` 인 아이콘 칸도 이 이름을 가집니다.
- 칸의 선택 여부와 비활성을 알립니다. 선택이 바뀐 것을 따로 알리는 라이브 리전은 없습니다.
- 묶음 자체의 이름은 없습니다. 곁에 보이는 제목을 두고, 필요하면 감싸서 이름을 붙입니다(→ 사용 가이드의 "묶음의 이름").

### 포커스 관리

마운트될 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. 포커스 링은 칸을 감싼 `Clickable` 의 링이며 칸마다 그리고, 키보드로 포커스했을 때 보입니다. Jaspr Web 은 화살표가 포커스와 선택을 함께 옮깁니다. `Tab` 이 멈추는 칸은 `value` 를 따르므로, 호출자가 `onChanged` 를 반영하지 않으면 화살표로 포커스는 옮겨 가도 `Tab` 의 자리는 이전 선택에 남습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | 칸마다 `Tab` 정지점이 있고 화살표가 선택을 바꾸지 않습니다. radio group 의 키 동작은 Jaspr Web 에만 있습니다. |
| 공통 | 칸 하나만 비활성으로 둘 수 없습니다. |
| Flutter | 묶음의 이름도 라디오 묶음 역할도 알리지 않습니다. 이름이 필요하면 `Semantics(container: true, label:)` 로 감쌉니다. |
| Jaspr Web | `radiogroup` 에 이름을 붙일 방법이 없습니다. 생성자가 `aria-label` 같은 속성을 받지 않아, 감싼 요소에 붙인 이름은 바깥 묶음의 이름이 됩니다. |
| Jaspr Web | `copyWith` 가 `attributes` · `classes` · `css` 를 받지만 반영하지 않습니다. |
| Jaspr Web | `trailing` 안의 버튼에 포커스가 있을 때 화살표를 누르면 고른 칸(없으면 첫 칸)의 이전 · 다음 칸으로, `Home` · `End` 를 누르면 첫 칸 · 마지막 칸으로 포커스와 선택이 옮겨 갑니다. Filter 의 초기화 버튼도 `trailing` 에 있습니다. |
| 공통 | `enabled: true` 인데 `onChanged` 가 `null` 이면 색은 활성 모양이지만 눌러도 아무 일이 없습니다. Flutter 의 칸은 커서가 금지 모양이고, 포커스와 hover · 눌림 표시가 없으며, 보조 기술에 비활성으로 전합니다. Jaspr Web 의 칸은 커서가 손 모양이고, `Tab` 이 멈추고 hover · 눌림 표시가 남으며, `aria-disabled` 도 붙지 않습니다. |
| 공통 | 포커스 링의 모서리는 칸의 모서리 6 이 아니라 `Clickable` 의 기본값 4 에서 정해집니다. `itemBorderRadius` 를 바꿔도 링은 따라가지 않으니, 맞추려면 `toggleGroupStyle` 의 `clickableStyle` 에 `borderRadius` 를 함께 줍니다. |
| Flutter | 트랙이 자기 모서리 밖을 잘라 냅니다. 포커스 링은 칸 바깥 4 까지 그려지므로, 표준 밀도의 치수로 계산하면 `sm`(트랙 안쪽 여백 3)은 트랙 가장자리 쪽 링의 바깥 1 이 잘리고, `md`(여백 4)는 트랙 모서리에 닿는 링의 모서리가 1 미만으로 잘립니다. Jaspr Web 의 트랙은 자르지 않습니다. |
| Flutter | `CoUIApp(scaling:)` 을 1 이 아닌 값으로 두면 트랙 안쪽 여백에는 배율이 두 번 곱해집니다. |
| 공통 | 아이콘과 라벨이 함께 있는 칸은 아이콘 앞에 칸 좌우 여백(`md` 2, `sm` 0)만 두고, 라벨 뒤에는 라벨 여백 8 까지 더해(`md` 10, `sm` 8) 좌우가 다릅니다. 트랙이 내용 크기인 `sm` 묶음에서는 아이콘이 칸 가장자리에 닿습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`items` · `value` · `onChanged` · `enabled` · `size` · `direction` · `fillWidth` · `trailing` · `toggleGroupStyle` 은 두 플랫폼이 같은 API 입니다. 렌더링은 각 플랫폼의 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 트랙 | 안에 그리는 `OutlinedContainer` | `<div role="radiogroup">`. 서페이스 스타일의 재질이 닿는 면으로 표시합니다. |
| 선택 알림 | `Semantics(checked:, inMutuallyExclusiveGroup:)` | `role="radio"` · `aria-checked` |
| 키보드 | 칸마다 `Tab`, `Enter` · `Space` | 칸에 `Tab` 정지점 하나, 화살표 · `Home` · `End` 로 옮기며 선택 |
| Hover 표시 | `Clickable.onHover` 를 받아 칸의 `foregroundDecoration` 으로 그리고, 150ms 동안 나타납니다. | CSS `:hover` 로 칸의 면 위에 덧칠합니다. 바로 나타납니다. |
| 고른 면의 그림자 | `BoxShadow` (`CoreShadow.xs`) | `box-shadow: var(--shadow-xs)` |
| 선택이 바뀔 때의 전환 | `AnimatedContainer` — 면 채움과 그림자 | CSS `transition` — 면 채움, 그림자, 라벨 글자색 |
| 라벨 글자색 | 바로 바뀝니다. | 150ms 동안 바뀝니다. |
| 선택해도 폭 유지 | 보이지 않는 600 굵기 글자가 폭만 차지합니다. | `aria-hidden` 인 두 번째 라벨이 폭만 차지합니다. |
| 트랙 밖 그리기 | 트랙 모서리 밖을 잘라 냅니다. | 자르지 않습니다. |
| 웹 전용 속성 | — | `id` (트랙 요소) |

<a id="props-parameters"></a>

## API

Flutter 와 Jaspr Web 이 같은 속성 이름을 씁니다. `T` 는 선택 값의 타입이고, 위젯 자리 `W` 는 Flutter 에서 `Widget`, Jaspr Web 에서 `Component` 입니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `items` | `List<CoreToggleGroupItem<T, W>>` | 필수 | 칸 목록. 1개 이상이어야 합니다(assert). |
| `value` | `T?` | 필수 | 고른 값. `null` 이면 아무 칸도 고르지 않습니다. |
| `onChanged` | `void Function(T)?` | 필수 | 누른 칸의 값을 받습니다. `null` 이고 `enabled` 를 지정하지 않으면 비활성입니다. |
| `enabled` | `bool?` | `null` | `null` 이면 `onChanged != null`. 지정하면 그 값이 우선합니다. |
| `size` | `CoreComponentSize` | `md` | `sm` · `md`. 다른 값은 `md` 로 그립니다. |
| `direction` | `CoreAxis` | `horizontal` | 칸을 놓는 축. `horizontal` · `vertical` |
| `fillWidth` | `bool` | `false` | 트랙이 부모 폭을 채우고, 가로 묶음에서는 칸이 폭을 똑같이 나눕니다. |
| `trailing` | `W?` | `null` | 트랙 안, 마지막 칸 뒤의 위젯. 선택에 참여하지 않습니다. |
| `toggleGroupStyle` | `CoreToggleGroupStyle?` | `null` | 보이는 값 덮어쓰기 |
| `id` | `String?` | `null` | Web 전용. 트랙 요소의 id |

`withStyle(patch)` 는 `toggleGroupStyle` 에 `patch` 를 합친 사본을 돌려줍니다.

### CoreToggleGroupItem

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `T` | 필수 | 이 칸의 값. 칸마다 다르게 둡니다. |
| `label` | `String` | 필수 | 칸의 글자이자 접근성 이름(`aria-label` / `Semantics(label:)`) |
| `icon` | `W?` | `null` | 라벨 앞의 아이콘 |
| `showLabel` | `bool` | `true` | 라벨을 그릴지 여부. `false` 이고 `icon` 이 있으면 아이콘만 있는 칸입니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.toggleGroup` | `CoreToggleGroupTheme?` | `style: CoreToggleGroupStyle?` 하나를 가집니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreToggleGroupStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Fill of the track. |
| `selectedColor` | `CoreColor?` | Fill of the chosen segment. |
| `disabledBackgroundColor` | `CoreColor?` | Fill of the track of a disabled group. |
| `disabledSelectedColor` | `CoreColor?` | Fill of the chosen segment of a disabled group. |
| `selectedShadow` | `List<CoreShadowLayer>?` | Shadow under the chosen segment. An empty list paints none. |
| `borderRadius` | `CoreBorderRadius?` | Track corner radius. |
| `itemBorderRadius` | `CoreBorderRadius?` | Per-segment corner radius. |
| `padding` | `CoreEdgeInsets?` | Inset between the track edge and the segments. |
| `itemPadding` | `CoreEdgeInsets?` | Padding inside each segment — its uniform inset around `[icon][label box]`. |
| `labelPadding` | `CoreEdgeInsets?` | Inset of the label box inside a segment (painted only when the item shows its label). |
| `itemHeight` | `double?` | Fixed segment height (logical px); content centres vertically. |
| `itemSpacing` | `double?` | Spacing between segments (logical px). |
| `selectedFontWeight` | `int?` | Font weight of the chosen segment's label (CSS font-weight integer). |
| `transitionDuration` | `Duration?` | Chosen-state colour transition duration. |
| `stateLayerColor` | `CoreColor?` | Colour of the state layer laid over a hovered segment. |
| `stateLayer` | `CoreStateLayer?` | Weights of the segment state layer (only `hover` is read). |
| `labelTextStyle` | `CoreTextStyle?` | Label text style of unchosen segments. |
| `selectedLabelTextStyle` | `CoreTextStyle?` | Label text style of the chosen segment. |
| `disabledLabelTextStyle` | `CoreTextStyle?` | Label text style of a disabled group, chosen and unchosen alike. |
| `iconStyle` | `CoreIconStyle?` | Icon style of an unchosen segment's caller-supplied icon. |
| `selectedIconStyle` | `CoreIconStyle?` | Icon style of the chosen segment's caller-supplied icon. |
| `disabledIconStyle` | `CoreIconStyle?` | Icon style of a disabled group's icons, chosen and unchosen alike. |
| `clickableStyle` | `CoreClickableStyle?` | Style for each segment's `Clickable` — press scale, durations, focus ring. Laid over [defaultClickableStyle] and passed to the `Clickable` as is. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="toggle-group/related-filter" title="Filter">

같은 칸에 구분선과 초기화 버튼이 붙은 목록 필터입니다.

</Card>
<Card component="tabs" props="variant=underline;size=sm" title="Tabs">

선택에 따라 아래 콘텐츠를 바꿀 때 씁니다.

</Card>
<Card component="radio-group" props="options=2;orientation=horizontal" title="RadioGroup">

폼 안의 라디오 선택에 씁니다.

</Card>
</Cards>
