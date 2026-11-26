---
title: TabPane
description: 박스형 탭 + 통합 콘텐츠 패널
category: navigation
platforms: [flutter, web]
related: [tabs, accordion]
tags: [interactive, panel, switching]
template: v2
source: navigation/tabs
---

# TabPane

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

variant 와 탭 속성을 바꿔 보며 탭 카드와 편집기 탭 줄을 확인하고, 만들어진 코드를 그대로 복사하세요. 미리보기의 탭은 눌러서 고르고, 닫기 버튼과 끌기도 켜면 동작합니다.

<Playground component="tab-pane" />

`TabPane` 은 선택과 탭 목록을 스스로 바꾸지 않습니다. 탭을 누르면 `onChanged` 로 그 탭의 자리(0부터)를 알리고, 호출자가 그 값을 `selectedIndex` 로 다시 넘겨야 화면이 바뀝니다. 탭 닫기와 순서 바꾸기도 콜백을 받아 `tabs` 를 직접 고칩니다. 탭은 [Tabs](/components/tabs) 와 같은 `CoreTabItem` 이며, 기본 variant(`boxed`)는 선택한 탭의 `content` 를 아래 패널에 그립니다. `editorStrip` 은 패널 없이 탭 줄만 그립니다.

```dart
TabPane(
  tabs: [
    CoreTabItem(label: '계정', content: accountPanel),
    CoreTabItem(label: '비밀번호', content: passwordPanel),
  ],
  selectedIndex: index,
  onChanged: (i) => setState(() => index = i),
)
```

## 구조

`boxed` 는 테두리 있는 카드 하나 안에 탭 바와 콘텐츠 패널을 담습니다. 탭 하나는 라벨과, 선택 사항인 앞 아이콘 · 배지 · 뒤 슬롯(`trailing`) · 닫기 버튼으로 이루어집니다. 뒤 슬롯은 아래 그림에 번호가 없으며, '배지 · 슬롯 · 닫기 버튼' 절에서 다룹니다.

<Anatomy demo="tab-pane/anatomy">
<AnatomyItem part="container" name="Container">

탭 바와 패널을 함께 담는 카드입니다. `outlineVariant` 1px 테두리, 모서리 12, `surface` 채움입니다.

</AnatomyItem>
<AnatomyItem select="[role=tablist]" side="right" name="bar">

높이 44의 탭 바입니다. 좌우에 `barPadding` 16을 두고, 아래에 카드 테두리와 같은 색의 선을 긋습니다. 탭이 폭보다 많으면 가로로 스크롤합니다.

</AnatomyItem>
<AnatomyItem part="leading" side="top" name="leading">

라벨 앞의 아이콘(`CoreTabItem.leading`)입니다. 크기를 적지 않은 `Icon` 은 16으로 그립니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="label">

탭의 글자(`CoreTabItem.label`)입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=badge]" side="top" name="badge">

라벨 뒤의 배지(`CoreTabItem.badge`)입니다.

</AnatomyItem>
<AnatomyItem select="[role=tablist] button" side="top" name="onClose">

`onClose` 를 준 탭에 붙는 닫기 버튼입니다.

</AnatomyItem>
<AnatomyItem select="[role=tablist] span[aria-hidden=true]" side="right" name="indicator">

선택한 탭을 표시하는 2px 막대입니다. `boxed` 는 탭 아래쪽, `editorStrip` 은 탭 위쪽 가장자리에 그립니다.

</AnatomyItem>
<AnatomyItem select="[role=tabpanel]" side="right" name="content">

선택한 탭의 `content` 를 그리는 패널입니다. 패널은 여백과 글자 스타일을 정하지 않습니다.

</AnatomyItem>
</Anatomy>

## Variant

`variant`(`CoreTabPaneVariant`)는 `boxed`(기본)와 `editorStrip` 두 가지입니다. 인스턴스마다 고르며, 테마로는 바꾸지 않습니다.

<VariantRow name="boxed" demo="tab-pane/variant-boxed">

기본 모양입니다. 카드 하나 안에 탭 바와 선택한 탭의 `content` 를 그리는 패널을 담습니다. 선택한 탭은 아래쪽 가장자리의 `primary` 표시줄로 구분하고, 탭에는 면도 외곽선도 없습니다.

</VariantRow>

<VariantRow name="editorStrip" demo="tab-pane/variant-editor-strip">

IDE 에디터의 탭 줄입니다. 패널과 카드 없이 높이 36의 탭 줄만 그리고, `CoreTabItem.content` 는 읽지 않습니다. 선택한 탭은 `surface` 면과 위쪽 가장자리의 표시줄로 구분합니다.

</VariantRow>

<Note>

`surfaceContainer` 에 가까운 배경 위에서는 `editorStrip` 의 띠(`surfaceContainerLow`)가 옅게 보입니다. 라이트 모드에서 두 색의 차이가 작기 때문입니다.

</Note>

### 값 비교

| 항목 | `boxed` | `editorStrip` |
| --- | --- | --- |
| 탭 바 높이 | 44 | 36 |
| 탭 바 좌우 여백(`barPadding`) | 16 | 없음 |
| 탭 안쪽 여백(`tabPadding`) | 좌우 2 | 시작 12 · 끝 8 |
| 탭 사이 | 간격 20 | 간격 0, 탭의 끝 쪽에 `outlineVariant` 1px 선 |
| 라벨 글자 역할 | `labelLarge` | `codeSm` |
| 탭 줄 띠 | 없음 | `surfaceContainerLow` |
| 카드 | `outlineVariant` 1px 테두리 · 모서리 12 · `surface` | 없음(모서리 0) |
| 바 아래 선 | 있음 | 있음. 선택한 탭의 면이 덮습니다 |
| 선택 표시줄 | 아래쪽 2px `primary`, 위 두 모서리 2 | 위쪽 2px `primary` |
| 선택한 탭의 면 | 없음 | `surface` |
| 닫기 버튼 상자 | `Button` ghost `sm`(높이 32, 너비는 글리프 + 좌우 여백) | 20 × 20, 모서리 4, 패딩 0 |
| 닫기 글리프 | 버튼 색을 따름 | 12, `onSurfaceSubtle` 고정 |
| 키보드 포커스 링 | 탭을 고르는 영역 바깥. 위아래가 잘릴 수 있음([알려진 제약](#알려진-제약)) | 탭을 고르는 영역 안쪽 |
| `content` | 패널에 그림 | 읽지 않음 |

'탭을 고르는 영역'은 `leading` · 라벨 · `badge` 를 감싼 영역입니다. Flutter 에서 `trailing` 과 닫기 버튼이 없는 탭만 이 영역이 탭 상자 전체입니다.

두 variant 모두 그림자를 쓰지 않습니다. 탭 바 높이(44 · 36)는 앱 밀도에서 움직이지 않습니다. 간격 값(`tabPadding` · `barPadding` · `tabSpacing`)은 밀도를 따르며, 4 이하는 그대로라 `boxed` 의 `tabPadding` 2는 변하지 않습니다.

<a id="ide-에디터-크롬-editorstrip"></a>

## IDE 에디터의 탭 줄 (`editorStrip`)

코드 에디터처럼 **탭 줄만** 필요하고 본문은 직접 배치할 때 씁니다. 파일 탭 줄은 `Button` 을 나열하거나 `content` 를 비운 `boxed` 로 흉내 내지 말고 이 variant 로 만듭니다.

<Preview demo="tab-pane/editor-strip" />

위 장면에서 탭 줄 아래의 본문은 `TabPane` 이 아니라 장면이 따로 그린 것입니다.

```dart
TabPane(
  variant: CoreTabPaneVariant.editorStrip,
  tabs: [
    CoreTabItem(
      label: 'main.dart',
      leading: Icon(LucideIcons.file),
      onClose: () => closeTab(0),
    ),
    CoreTabItem(label: 'pubspec.yaml', onClose: () => closeTab(1)),
  ],
  selectedIndex: index,
  onChanged: (i) => setState(() => index = i),
)
```

- 콘텐츠 패널을 그리지 않으므로 에디터 본문은 직접 둡니다.
- `.editorStrip` 체인(`TabPane(...).editorStrip`)은 `variant` 만 바꿉니다. 겉모습 값은 variant 기본값(`CoreTabPaneStyle.defaultsByVariant`)이 채웁니다.
- 반대로 `boxed` 에 `tabPaneStyle: CoreTabPaneStyle.editorStrip` 만 넘기면 콘텐츠 패널과 카드 테두리가 남습니다.
- 키보드 포커스 링은 탭을 고르는 영역 안쪽에 그립니다(Flutter 에서 `trailing` 과 닫기 버튼이 없는 탭은 탭 상자 안쪽). 탭 줄은 가로로 스크롤하는 상자라, 바깥에 그리면 위아래가 잘릴 수 있습니다.
- `boxed` 의 `content` 를 비워 탭 줄로 쓰면 빈 카드가 남습니다.

### Button 합성 스트립에서 이전

파일 버튼을 나열해 만든 탭 줄에는 선택 표시줄과 바 아래 선이 없고, Web 에서는 탭 역할과 탭 키보드 이동도 없습니다. `editorStrip` 으로 바꿉니다.

```dart
// 파일 버튼을 나열한 줄 — 선택 표시줄과 바 아래 선이 없습니다.
Row(
  children: [
    for (var i = 0; i < files.length; i++)
      Button(variant: CoreButtonVariant.ghost, onPressed: () => select(i), child: Text(files[i])),
  ],
)

// content 를 비운 boxed — 빈 카드가 남습니다.
TabPane(
  tabs: [CoreTabItem(label: 'main.dart')],
  selectedIndex: 0,
  onChanged: select,
)

// 이렇게 바꿉니다.
TabPane(
  variant: CoreTabPaneVariant.editorStrip,
  tabs: [for (final file in files) CoreTabItem(label: file)],
  selectedIndex: index,
  onChanged: select,
)
```

## 배지 · 슬롯 · 닫기 버튼

탭 하나(`CoreTabItem`)에는 앞에서부터 `leading` · 라벨 · `badge` · `trailing` · 닫기 버튼이 놓입니다. 사이 간격은 `labelBadgeGapStyle`(6)이고, 비운 자리는 간격도 차지하지 않습니다.

### 배지

<Preview demo="tab-pane/badge" />

```dart
CoreTabItem(
  label: '받은편지함',
  badge: Badge(
    variant: CoreBadgeVariant.filled,
    form: CoreBadgeForm.count,
    size: CoreComponentSize.xs,
    child: Text('3'),
  ),
  content: inboxPanel,
)
```

`badge` 는 자기 색을 그대로 칠합니다.

### 앞뒤 슬롯

<Preview demo="tab-pane/slots" />

```dart
CoreTabItem(
  label: 'pubspec.lock',
  leading: Icon(LucideIcons.file),
  trailing: Icon(LucideIcons.lock),
  onClose: closeLockFile,
)
```

- `leading` 과 `badge` 는 탭을 고르는 영역 안에 있습니다.
- `trailing` 과 닫기 버튼은 그 영역 밖이라, 눌러도 `onChanged` 를 부르지 않습니다.
- 슬롯의 `Icon` 은 크기를 직접 적지 않으면 16(`slotIconStyle`)입니다.
- [Tabs](/components/tabs) 는 `leading` · `trailing` · `content` 를 그리지 않고, `badge` 와 `onClose` 만 씁니다.

<a id="닫기-와-hit-test"></a>

### 닫기 버튼과 누르는 영역

`onClose` 를 주면 탭 끝에 ghost `Button` 과 `LucideIcons.x` 로 만든 닫기 버튼을 붙입니다.

- 닫기 버튼을 누르면 `onClose` 만 부릅니다. 목록에서 탭을 지우고 `selectedIndex` 를 맞추는 일은 직접 합니다.
- 닫기 버튼은 탭이 비활성이거나 `onChanged` 가 없어도 눌립니다.
- 다른 모양의 닫기를 `trailing` 에 넣어도 똑같이 탭을 고르는 영역 밖에 놓입니다.
- 상자와 글리프는 `closeButtonStyle` · `closeIconStyle` 로 바꿉니다. `editorStrip` 의 글리프 색(`onSurfaceSubtle`)은 hover 에서도 바뀌지 않고 비활성 탭에서도 흐려지지 않습니다. `boxed` 의 글리프는 색을 따로 정하지 않아 버튼 색을 따릅니다.
- `tabPadding` 은 `leading` 부터 닫기 버튼까지 탭 전체를 감쌉니다. 그래서 닫기 버튼은 `tabPadding` 의 끝 여백만큼 탭 끝에서 떨어집니다(`boxed` 2, `editorStrip` 8). 앞뒤 슬롯과 배지가 없는 `editorStrip` 탭은 시작 12 + 라벨 + 6 + 20 + 끝 8 입니다. Flutter · Web · Figma 가 같은 상자를 감쌉니다.
- 닫기 버튼의 접근성 이름은 화면을 그리는 시점 로케일의 닫기 문구(한국어는 '닫기')입니다.

<a id="동작-스펙-behavior"></a>

## 상태

<Preview demo="tab-pane/states" />

| 상태 | 동작 |
| --- | --- |
| 선택함 | 라벨 색 `onSurface` 와 선택 표시줄. `editorStrip` 은 `surface` 면도 칠합니다. |
| 선택 안 함 | 라벨 색 `onSurfaceVariant`. 선택해도 라벨 굵기는 바뀌지 않습니다. |
| Hover | 탭에는 hover 모양이 없습니다. 닫기 버튼만 ghost 버튼의 hover 를 보입니다. |
| 눌림 | 탭을 고르는 영역이 0.97배로 줄어듭니다. |
| Focus | 키보드로 포커스하면 탭을 고르는 영역에 `focusRing` 색의 굵기 2 링을 그립니다. `boxed` 는 영역에서 2 떨어진 바깥, `editorStrip` 은 영역 가장자리 안쪽입니다. `boxed` 의 바깥 링은 위아래가 잘릴 수 있고, Web 의 비활성 탭에는 링이 없습니다([알려진 제약](#알려진-제약)). |
| 비활성 | `CoreTabItem.enabled: false` 이거나 `onChanged` 가 없으면 눌러도 고르지 않습니다. 커서는 금지 모양이고 탭을 고르는 영역이 50% 로 흐려집니다(`clickableStyle.disabledOpacity`). [Tabs](/components/tabs) 와 달리 비활성 전용 색은 쓰지 않으며, 닫기 버튼과 `trailing` 은 흐려지지 않습니다. |
| 선택 + 비활성 | 선택 표시줄이 남습니다. `trailing` 과 닫기 버튼이 없는 탭은 Flutter 가 표시줄까지 탭 전체를, Web 이 라벨 영역만 흐립니다. |
| 전환 | 선택 표시줄과 패널은 전환 애니메이션 없이 바뀝니다. |

### 탭 전환

- 탭을 누르면 `onChanged` 를 그 탭의 자리로 부릅니다. 화면은 새 `selectedIndex` 를 넘길 때 바뀝니다.
- 닫기 버튼은 `onClose` 만 부릅니다.
- `selectedIndex` 가 범위를 벗어나면 선택한 탭이 없고 패널이 비어 있습니다. Flutter 는 패널에 아무 위젯도 놓지 않고, Web 은 빈 `tabpanel` 을 둡니다.
- 트리에는 선택한 탭의 `content` 만 있습니다. 탭을 바꿔도 남겨야 하는 입력값 같은 상태는 바깥에서 보관하고, 모양이 같은 패널끼리 상태를 이어받지 않게 서로 다른 `key` 를 줍니다.
- 패널은 여백과 글자 스타일을 정하지 않아 `content` 위젯이 그대로 놓입니다. `contentTextStyle` 은 탭 라벨에만 닿습니다. 설명 한 줄을 넣을 때는 `space20` 여백 안에 `Text(...).bodyMedium.onSurfaceVariant` 를 둡니다. Figma 세트의 예시 콘텐츠도 같은 모양입니다.
- `boxed` 카드는 패널 내용을 카드 모서리에 맞춰 자르지 않습니다. 모서리까지 칠하는 내용에는 여백을 두거나 그 내용의 모서리를 둥글게 합니다.

## 드래그 정렬

`reorderable: true` 와 `onReorder` 가 둘 다 있어야 탭을 끌 수 있습니다. `onReorder` 는 새 순서의 `CoreTabItem` 목록을 넘기며, `tabs` 와 `selectedIndex` 는 직접 고칩니다.

```dart
TabPane(
  tabs: tabs,
  selectedIndex: index,
  onChanged: (i) => setState(() => index = i),
  reorderable: true,
  onReorder: (next) => setState(() {
    final current = tabs[index];
    tabs = next;
    index = next.indexOf(current);
  }),
)
```

- 끌고 있는 탭은 `dragOpacity`(0.5)로 흐려집니다.
- 끌던 탭은 놓은 자리의 탭 **바로 앞**에 들어갑니다. 그래서 오른쪽 이웃 탭 위에 놓으면 순서가 바뀌지 않고(`onReorder` 는 같은 순서의 목록으로 불립니다), 맨 끝으로는 옮길 수 없습니다.
- 포인터로만 동작합니다. Flutter 는 `Draggable` / `DragTarget`, Web 은 HTML5 drag and drop 을 씁니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 언제 쓰나

- 탭과 그 탭의 콘텐츠를 카드 하나로 함께 보여 줄 때(`boxed`)
- IDE · 코드 에디터처럼 탭 줄만 필요하고 본문은 직접 배치할 때(`editorStrip`)
- 탭마다 닫기 버튼이나 앞뒤 슬롯이 필요하거나, 끌어서 순서를 바꿔야 할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 탭 바만 필요할 때(pill · underline, `sm`~`lg` 크기, 균등 폭, 밀어서 넘기기). IDE 파일 탭에는 `TabPane` 의 `editorStrip` 을 씁니다 | [Tabs](/components/tabs) |
| 모든 섹션을 한 페이지에서 펼치고 접을 때 | [Accordion](/components/accordion) |
| 라벨 없이 보이는 화면만 바꿀 때 | [Switcher](/components/switcher) |
| 앱의 주요 화면을 오갈 때 | [NavigationBar](/components/navigation-bar) |

### 내용과 variant

<a id="do"></a>
<a id="dont"></a>

<Cards columns="2">
<Card demo="tab-pane/do-content" tone="do" eyebrow="이렇게 하세요">

`boxed` 에서는 탭마다 `content` 를 채웁니다.

</Card>
<Card demo="tab-pane/dont-empty-content" tone="dont" eyebrow="이렇게 하지 마세요">

`content` 없이 `boxed` 를 탭 줄로 쓰지 않습니다. 빈 카드가 남습니다.

</Card>
<Card demo="tab-pane/do-editor-strip" tone="do" eyebrow="이렇게 하세요">

탭 줄만 필요하면 `editorStrip` 을 씁니다.

</Card>
<Card demo="tab-pane/dont-button-strip" tone="dont" eyebrow="이렇게 하지 마세요">

`Button` 을 나열해 탭 줄을 만들지 않습니다. 선택 표시줄과 바 아래 선이 없습니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

`reorderable: true` 만 켜고 `onReorder` 를 빼지 않습니다. 둘 다 있어야 끌 수 있습니다.

</Card>
</Cards>

## 배치

`TabPane` 은 부모의 폭을 채웁니다. Flutter 에서는 폭이 정해진 부모가 필요합니다. 탭 바가 안에서 `Expanded` 를 쓰므로, `Row` 의 바로 아래 자식처럼 폭이 무한한 자리에 두면 레이아웃 오류가 납니다. 그런 자리에서는 `Expanded` 나 폭을 정한 상자로 감쌉니다. Web 은 `w-full` 입니다.

<Cards columns="2">
<Card demo="tab-pane/placement-actions" title="탭 바 뒤의 버튼">

`TabPane` 의 `trailing` 에 새 파일 버튼을 두었습니다. Flutter 는 바의 끝에, Web 은 마지막 탭 뒤에 놓습니다.

</Card>
<Card demo="tab-pane/placement-scroll" title="탭이 넘칠 때">

탭이 폭보다 많으면 탭 바가 가로로 스크롤합니다. Flutter 는 넘치는 쪽 가장자리를 흐리게 하고, Web 에는 흐림 표시가 없습니다.

</Card>
</Cards>

### 바 앞뒤 위젯

`TabPane` 의 `leading` · `trailing` 은 탭 바 앞뒤에 놓는 위젯이며, 탭마다의 `leading` · `trailing` 과는 다른 자리입니다.

- Flutter 는 둘을 스크롤 밖, 바의 양끝에 고정합니다. Web 은 첫 탭 앞과 마지막 탭 뒤에 두며, 탭과 함께 스크롤합니다.
- Flutter 는 이 위젯을 바 높이만큼 늘립니다. Web 은 높이를 정하지 않은 위젯만 늘리고, `Button` 처럼 높이가 정해진 위젯은 바 위쪽에 붙습니다.
- 가운데에 놓으려면 아래처럼 두 플랫폼 모두 감싸서 맞춥니다. 아이콘만 있는 버튼에는 접근성 이름을 줍니다.

<Split>

<Code language="dart" title="Flutter">
TabPane(
  variant: CoreTabPaneVariant.editorStrip,
  tabs: fileTabs,
  selectedIndex: index,
  onChanged: select,
  trailing: [
    Center(
      child: Semantics(
        button: true,
        label: '새 파일',
        child: Button(
          variant: CoreButtonVariant.ghost,
          size: CoreComponentSize.sm,
          shape: CoreButtonShape.square,
          onPressed: addFile,
          child: Icon(LucideIcons.plus),
        ),
      ),
    ),
  ],
)
</Code>

<Code language="dart" title="Jaspr Web">
TabPane(
  variant: CoreTabPaneVariant.editorStrip,
  tabs: fileTabs,
  selectedIndex: index,
  onChanged: select,
  trailing: [
    div(
      [
        Button(
          variant: CoreButtonVariant.ghost,
          size: CoreComponentSize.sm,
          shape: CoreButtonShape.square,
          attributes: {'aria-label': '새 파일'},
          onPressed: addFile,
          child: Icon(LucideIcons.plus),
        ),
      ],
      classes: 'flex items-center',
    ),
  ],
)
</Code>

</Split>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

`variant` 는 위젯 속성으로 고르고, 색 · 크기 · 간격 · 모서리처럼 보이는 값은 `tabPaneStyle`(`CoreTabPaneStyle`) 하나로 덮어씁니다. `tabs` · `selectedIndex` · `onChanged` · `reorderable` 같은 내용과 동작은 위젯 속성으로 넘깁니다.

<Split>

<Code language="dart" title="하나만 바꾸기">
TabPane(
  tabs: tabs,
  selectedIndex: index,
  onChanged: select,
  tabPaneStyle: const CoreTabPaneStyle(
    barHeight: CoreSize.size40,
    tabSpacing: CoreSpace.space16,
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    tabPane: CoreTabPaneTheme(
      style: CoreTabPaneStyle(
        indicatorColor: CoreColor.token(CoreColors.success),
      ),
      variantStyles: {
        CoreTabPaneVariant.editorStrip: CoreTabPaneStyle(
          barHeight: CoreSize.size40,
        ),
      },
    ),
  ),
)
</Code>

</Split>

<Note>

`CoreComponentTheme.tabPane` 은 `Tabs` 의 테마(`CoreTabsTheme`)와 따로입니다. 테마의 `style` 은 두 variant 의 기본값을 모두 덮으므로, 한 variant 만 바꾸려면 `variantStyles` 를 씁니다. 서페이스 스타일의 재질은 `boxed` 카드에만 닿습니다. `editorStrip` 에는 카드가 없습니다.

</Note>

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `TabPane` 에는 `withStyle` 체인으로 스타일을 덧붙입니다. 생성자의 `tabPaneStyle` 인자와 같게 동작하고, 겹치는 필드는 나중에 덧붙인 값이 이깁니다. Core 토큰 상수와 이름이 같은 getter 도 있습니다. `radius0`~`radius64` 와 `radius9999` 는 `borderRadius` 를 바꾸며, 카드가 없는 `editorStrip` 에서는 보이는 변화가 없습니다. 색 getter(`primary` · `secondary` · `tertiary` · `surface` · `surfaceContainer` · `error` · `success` · `warning` · `info` · `outline` · `transparent`)는 `backgroundColor`(`boxed` 는 카드 채움, `editorStrip` 은 선택한 탭의 면)를 바꿉니다. `.editorStrip` 은 `variant` 만 바꿉니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class TabPaneChainExample extends StatefulWidget {
  const TabPaneChainExample({super.key});

  @override
  State<TabPaneChainExample> createState() => _TabPaneChainExampleState();
}

class _TabPaneChainExampleState extends State<TabPaneChainExample> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        TabPane(
          tabs: [
            CoreTabItem(
              label: '계정',
              content: Padding(
                padding: const CoreEdgeInsets.all(CoreSpace.space20).toValue(geometry: Theme.of(context).geometry),
                child: Text(
                  '계정 설정을 관리해요.',
                ).bodyMedium.onSurfaceVariant,
              ),
            ),
            CoreTabItem(
              label: '비밀번호',
              content: Padding(
                padding: const CoreEdgeInsets.all(CoreSpace.space20).toValue(geometry: Theme.of(context).geometry),
                child: Text('여기에서 비밀번호를 바꿔요.').bodyMedium.onSurfaceVariant,
              ),
            ),
          ],
          selectedIndex: _index,
          onChanged: (i) => setState(() => _index = i),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderWidth)까지 한 번에.
        TabPane(
          tabs: [
            CoreTabItem(
              label: '계정',
              content: Padding(
                padding: const CoreEdgeInsets.all(CoreSpace.space20).toValue(geometry: Theme.of(context).geometry),
                child: Text(
                  '계정 설정을 관리해요.',
                ).bodyMedium.onSurfaceVariant,
              ),
            ),
            CoreTabItem(
              label: '비밀번호',
              content: Padding(
                padding: const CoreEdgeInsets.all(CoreSpace.space20).toValue(geometry: Theme.of(context).geometry),
                child: Text('여기에서 비밀번호를 바꿔요.').bodyMedium.onSurfaceVariant,
              ),
            ),
          ],
          selectedIndex: _index,
          onChanged: (i) => setState(() => _index = i),
        ).withStyle(
          const CoreTabPaneStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
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
class TabPaneChainExample extends StatefulComponent {
  const TabPaneChainExample({super.key});

  @override
  State<TabPaneChainExample> createState() => _TabPaneChainExampleState();
}

class _TabPaneChainExampleState extends State<TabPaneChainExample> {
  int _index = 0;

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        TabPane(
          tabs: [
            CoreTabItem(
              label: '계정',
              content: div(
                [Text('계정 설정을 관리해요.').bodyMedium.onSurfaceVariant],
                classes: 'p-${CoreSpace.scale.space20}',
              ),
            ),
            CoreTabItem(
              label: '비밀번호',
              content: div(
                [Text('여기에서 비밀번호를 바꿔요.').bodyMedium.onSurfaceVariant],
                classes: 'p-${CoreSpace.scale.space20}',
              ),
            ),
          ],
          selectedIndex: _index,
          onChanged: (index) => setState(() => _index = index),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderWidth)까지 한 번에.
        TabPane(
          tabs: [
            CoreTabItem(
              label: '계정',
              content: div(
                [Text('계정 설정을 관리해요.').bodyMedium.onSurfaceVariant],
                classes: 'p-${CoreSpace.scale.space20}',
              ),
            ),
            CoreTabItem(
              label: '비밀번호',
              content: div(
                [Text('여기에서 비밀번호를 바꿔요.').bodyMedium.onSurfaceVariant],
                classes: 'p-${CoreSpace.scale.space20}',
              ),
            ),
          ],
          selectedIndex: _index,
          onChanged: (index) => setState(() => _index = index),
        ).withStyle(
          const CoreTabPaneStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
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

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreTabPaneStyle.defaultX / defaultsByVariant   // 디자인 시스템 기본값
  → CoreTabPaneTheme.style                      // 프로젝트 공통
  → CoreTabPaneTheme.variantStyles[variant]     // 프로젝트 variant 별
  → widget.tabPaneStyle                         // 인스턴스별
```

뒤에 오는 값이 이깁니다. `contentTextStyle` · `clickableStyle` · `labelBadgeGapStyle` · `closeButtonStyle` · `closeIconStyle` · `slotIconStyle` 은 적은 필드만 덮고, 나머지 필드는 아래 값을 그대로 둡니다.

### `CoreTabPaneStyle` 필드

| 필드 | `boxed` 기본값 | `editorStrip` 기본값 | 하는 일 |
| --- | --- | --- | --- |
| `backgroundColor` | `surface` | `surface` | `boxed` 는 카드 채움, `editorStrip` 은 선택한 탭의 면. `boxed` 의 선택한 탭은 `tabBorderColor` 를 정했을 때만 이 색의 면을 갖습니다 |
| `stripBackgroundColor` | 없음 | `surfaceContainerLow` | 탭 줄 전체의 띠 |
| `borderColor` | `outlineVariant` | `outlineVariant` | `boxed` 는 카드 테두리와 바 아래 선, `editorStrip` 은 탭 줄 아래 선. `transparent` 면 그리지 않습니다 |
| `borderWidth` | 1 | 1 | 그 선의 두께 |
| `borderRadius` | 12 | 쓰지 않음(카드 없음) | 카드 모서리 |
| `barHeight` | 44 | 36 | 탭 바 높이 |
| `barPadding` | 좌우 16 | 없음 | 탭 바 안쪽 여백. 카드 모서리에서 계산하지 않습니다 |
| `tabPadding` | 좌우 2 | 시작 12 · 끝 8 | 탭 하나 전체(앞뒤 슬롯과 닫기 버튼 포함)의 안쪽 여백 |
| `tabSpacing` | 20 | 0 | 탭마다 뒤에 두는 간격. 마지막 탭 뒤에도 둡니다 |
| `tabSeparatorColor` | 없음 | `outlineVariant` | 탭 끝 쪽의 세로 선 |
| `tabSeparatorWidth` | 1 | 1 | 세로 선 두께 |
| `tabBorderColor` | `transparent` | `transparent` | 색을 정하면 `boxed` 의 선택한 탭에 면과 세 변 외곽선을 그립니다. `editorStrip` 에는 외곽선을 그리지 않습니다 |
| `indicatorColor` | `primary` | `primary` | 선택 표시줄 색. `transparent` 면 그리지 않습니다 |
| `indicatorWidth` | 2 | 2 | 표시줄 두께 |
| `indicatorBorderRadius` | 위 두 모서리 2 | 0 | 표시줄 모서리 |
| `activeContentColor` | `onSurface` | `onSurface` | 선택한 탭의 라벨 색 |
| `inactiveContentColor` | `onSurfaceVariant` | `onSurfaceVariant` | 선택하지 않은 탭의 라벨 색 |
| `contentTextStyle` | `labelLarge` | `codeSm` | 탭 라벨 글자. 패널에는 닿지 않습니다 |
| `labelBadgeGapStyle` | 6 | 6 | 탭 안에서 라벨 · 슬롯 · 배지 · 닫기 버튼 사이의 간격 |
| `slotIconStyle` | 크기 16 | 크기 16 | `leading` · `trailing` 아이콘의 크기. 크기만 읽으며, 크기를 직접 적은 아이콘은 그 크기를 지킵니다 |
| `closeButtonStyle` | ghost `sm` 그대로(높이 32, 너비는 글리프 + 좌우 여백) | 20 × 20 · 모서리 4 · 패딩 0 | 닫기 버튼의 상자 |
| `closeIconStyle` | 정하지 않음(버튼 색을 따름) | 12 · `onSurfaceSubtle` | 닫기 글리프 |
| `clickableStyle` | 기본 | 포커스 링을 안쪽에 | 탭을 고르는 영역의 포커스 링 · 눌림 · 비활성 흐림 |
| `dragOpacity` | 0.5 | 0.5 | 끌고 있는 탭의 불투명도 |

`boxed` 의 선택 표시줄은 탭 폭 전체에 걸쳐 바 아래 선 위에 얹힙니다. `editorStrip` 의 표시줄은 탭 위쪽 가장자리 안쪽에 칠하며, 레이아웃 높이를 쓰지 않아 선택한 탭과 아닌 탭의 라벨 높이 위치가 같습니다. `editorStrip` 의 바 아래 선은 탭 줄 높이 안쪽 맨 아래에 그려, 선택한 탭의 면이 그 선을 덮습니다.

<a id="접근성-accessibility"></a>

## 접근성

### 역할

- **Flutter**: 탭마다 `Semantics(button: true, selected: …, enabled: …)` 를 붙이고, 탭을 고르는 `Clickable` 도 버튼 정보를 냅니다. 탭 목록과 패널의 역할은 없습니다. 닫기 버튼은 `Semantics(button: true, label: …)` 로 이름을 갖습니다.
- **Web**: 탭 바에 `role="tablist"`, 탭마다 `role="tab"` 과 `aria-selected` 를 붙입니다. `role="tab"` 은 `Clickable` 의 기본 버튼 역할을 대신합니다. `boxed` 의 패널에는 `role="tabpanel"` 이 붙고, `editorStrip` 은 패널이 없습니다.
- 루트 요소에는 역할이 없습니다. 필요하면 `attributes` 로 루트에 직접 줄 수 있습니다. 다만 `attributes` 는 탭 목록(`tablist`)에는 닿지 않아, 목록 이름은 붙일 수 없습니다.
- 두 플랫폼 모두 탭과 패널을 `aria-controls` · `aria-labelledby` · `id` 로 잇지 않습니다.

Web 의 `boxed` 는 대략 이런 모양입니다.

```html
<div>
  <div role="tablist">
    <span><span>
      <div role="tab" aria-selected="true" tabindex="0">계정</div>
    </span></span>
    <span><span>
      <div role="tab" aria-selected="false" tabindex="-1">비밀번호</div>
    </span></span>
  </div>
  <div role="tabpanel">…</div>
</div>
```

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` | 활성 탭마다 정지점이 하나씩 있습니다. 닫기 버튼 · `trailing` · 바 앞뒤의 컨트롤은 따로 정지합니다 | 탭 줄에 정지점이 하나입니다(선택한 탭, `selectedIndex` 가 범위를 벗어나면 첫 탭). 닫기 버튼 · `trailing` · 바 앞뒤의 컨트롤은 따로 정지합니다 |
| `←` `→` | 탭 전용 이동이 없습니다. 앱의 기본 단축키가 동작합니다(데스크톱 · 모바일은 방향에 따라 포커스를 옮기고, Flutter web 은 스크롤합니다) | 이전 · 다음 탭으로 포커스를 옮기며, 양끝에서 순환합니다 |
| `Home` `End` | 없음 | 첫 탭 · 마지막 탭으로 포커스를 옮깁니다 |
| `Enter` `Space` | 포커스한 탭을 고릅니다 | 포커스한 탭을 고릅니다 |

Web 의 화살표는 포커스만 옮기고 선택은 `Enter` · `Space` 로 합니다(수동 활성화). 비활성 탭에도 화살표로 갈 수 있지만 고를 수는 없고, `Tab` 정지점은 선택한 탭에 남습니다. 비활성 탭이 포커스를 받아도 링은 보이지 않습니다([알려진 제약](#알려진-제약)). Flutter 의 비활성 탭은 `Tab` 으로 가지 않습니다.

Web 의 키보드 동작은 야간 CI 가 실제 브라우저에서 확인합니다(`tool/parity/keyboard_probe.dart`, `parity-nightly.yml`). 이 확인은 결과를 보고만 하며 실패해도 CI 를 막지 않습니다.

### 스크린 리더

- 탭 이름은 라벨이며, `badge` 나 `leading` 에 글자가 있으면 함께 읽습니다.
- 선택 상태는 Flutter 의 `Semantics(selected:)`, Web 의 `aria-selected` 로 알립니다.
- 비활성 탭은 Flutter 의 `enabled: false`, Web 의 `aria-disabled="true"` 로 알립니다.
- 닫기 버튼의 이름은 로케일의 닫기 문구뿐입니다. [Tabs](/components/tabs) 의 닫기 버튼도 같습니다.
- 탭을 바꿔 패널 내용이 바뀌는 것은 알리지 않습니다. 두 플랫폼 모두 live region 이 없습니다.

### 포커스 관리

- 오버레이가 아니라서 처음 그릴 때 포커스를 가져가지 않고, 포커스를 가두지도 않습니다. `Tab` 은 탭 바를 지나 다음 요소로 나갑니다.
- 탭을 골라도 포커스는 그 탭에 남고 패널로 옮겨 가지 않습니다. Flutter 의 예외는 알려진 제약에 있습니다.
- 포커스 링은 키보드로 포커스했을 때만 그립니다.

### 알려진 제약

- **Flutter 에는 탭 목록과 패널 구조가 없습니다.** 각 탭은 선택할 수 있는 버튼으로만 읽힙니다. 바깥을 `Semantics` 로 감싸 이름을 붙일 수는 있지만, 탭과 패널의 관계는 만들 수 없습니다.
- **Flutter 는 탭마다 `Tab` 정지점이 생기고, 탭 전용 화살표 이동(순환 · `Home` · `End`)이 없습니다.** 화살표는 앱의 기본 단축키를 따릅니다. 탭이 많으면 `Tab` 을 누르는 횟수도 늘어납니다.
- **Flutter 는 선택이 바뀐 탭(새로 고른 탭과 이전에 고른 탭)의 안쪽을 다시 만듭니다.** 선택 표시줄이 생기고 사라지면서 일어나며, 그 탭의 `leading` · `badge` · `trailing` 위젯은 상태를 처음부터 다시 시작합니다. 닫기 버튼이나 `trailing` 이 있는 탭은 탭을 고르는 `Clickable` 까지 새로 만들어져, 키보드로 고르면 포커스가 탭에서 빠집니다.
- **`boxed` 의 포커스 링은 위아래가 잘릴 수 있습니다.** 탭 바는 가로로 스크롤하는 상자이고, 탭이 바 높이를 채웁니다. Web 에서는 링의 위 · 아래 변이 잘려 좌우만 보입니다. Flutter 는 탭이 줄 폭을 넘쳐 스크롤할 때 같은 일이 생깁니다.
- **Web 은 비활성 탭이 포커스를 받아도 포커스 링을 그리지 않습니다.** 화살표로 옮겨 갔을 때와, 선택한 탭이 비활성이라 그 탭이 `Tab` 정지점일 때가 그렇습니다. 어디에 포커스가 있는지 보이지 않습니다. 색 강제 모드에서만 앱 루트의 규칙이 링을 따로 켭니다.
- **Web 은 바의 `leading` · `trailing` 과 닫기 버튼이 `tablist` 안에 있습니다.** 그 컨트롤에서 화살표 · `Home` · `End` 를 누르면 선택한 탭을 기준으로 탭 포커스가 옮겨 가고 기본 동작이 막힙니다. 그래서 바에 둔 입력란에서는 이 키로 커서를 옮길 수 없습니다.
- **Web 은 탭 목록에 이름을 붙일 수 없습니다.** `attributes` 는 루트 요소에 붙습니다.
- **Web 은 오른쪽에서 왼쪽으로 쓰는 화면에서도 `→` 가 다음 순서의 탭으로 갑니다.** 화면에서는 왼쪽에 있는 탭입니다.
- **탭과 패널이 프로그램적으로 이어지지 않습니다.** `aria-controls` · `aria-labelledby` 가 없고, 두 요소의 속성은 컴포넌트 안에서 만들어 직접 채울 수 없습니다.
- **순서 바꾸기는 포인터로만 할 수 있습니다.** 키보드로 `onReorder` 를 일으킬 방법이 없어 WCAG 2.1.1 을 충족하지 못합니다. 순서를 바꾸는 일이 꼭 필요하면 키보드로 할 수 있는 다른 조작을 함께 둡니다.
- **끌던 탭은 놓은 탭 바로 앞에 들어가므로 맨 끝으로 옮길 수 없습니다.**
- **닫기 버튼 이름은 어느 탭의 것인지 말하지 않습니다.** 모두 같은 닫기 문구입니다.
- **Web 은 색 강제 모드에서 바 아래 선이 사라집니다.** 자세한 내용은 아래 플랫폼 차이에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

Flutter 와 Jaspr Web 은 같은 이름의 속성을 같은 뜻으로 씁니다(`variant` 와 `CoreTabItem.onClose` 포함). 그리는 방식과 아래 항목은 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 접근성 역할 | 탭마다 선택할 수 있는 버튼 | `tablist` · `tab` · `tabpanel` |
| 키보드 | 활성 탭마다 `Tab` 정지점. 탭 전용 화살표 이동(순환 · `Home` · `End`) 없이 앱의 기본 단축키를 따름 | 정지점 하나, 화살표 · `Home` · `End` |
| 비활성 탭의 포커스 | 받지 않음 | 화살표로 받을 수 있음. 선택한 탭이 비활성이면 `Tab` 으로도 받음. 링은 없음 |
| `boxed` 포커스 링 | 바깥. 탭이 넘쳐 스크롤할 때 위아래가 잘림 | 바깥. 위아래가 잘려 좌우만 보임 |
| `trailing` · 닫기 버튼이 없는 탭의 누르는 영역 | `tabPadding` 을 포함한 탭 전체 | `leading` · 라벨 · `badge` 영역(좌우 여백 제외) |
| 같은 탭의 비활성 흐림 · 눌림 축소 | 선택 표시줄까지 탭 전체 | 누르는 영역만 |
| 넘침 표시 | 넘치는 쪽 가장자리를 흐리게 함 | 없음 |
| 바의 `leading` · `trailing` | 스크롤 밖, 바 양끝에 고정 | 탭 줄 안(첫 탭 앞 · 마지막 탭 뒤), 탭과 함께 스크롤 |
| 바의 `leading` · `trailing` 높이 | 바 높이만큼 늘어남 | 높이를 정하지 않은 위젯만 늘어남 |
| 순서 바꾸기 | `Draggable` / `DragTarget` | HTML5 drag and drop |
| 선택 표시줄 | `Stacks` 와 `Position` 으로 얹음 | 절대 배치한 `<span aria-hidden>` |
| 바 아래 선 | `Border` | 안쪽 `box-shadow` |
| 폭 | 폭이 정해진 부모가 필요 | `w-full` |
| Web 전용 속성 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` · `onClick` · `onInput` · `onChange` · `onKeyDown` · `onKeyUp` · `onMouseEnter` · `onMouseLeave`. 루트 요소에 붙으며, `onChange` 는 루트의 DOM 이벤트라 탭 변경에는 `onChanged` 를 씁니다 |

### 선택 표시줄과 색 강제 모드

선택 표시줄은 두 플랫폼 모두 레이아웃 높이를 쓰지 않고 칠하기만 하며, 모서리는 같은 `indicatorBorderRadius` 를 읽습니다.

브라우저의 색 강제 모드(`forced-colors: active`)는 배경색을 시스템 색으로 바꿉니다. 그러면 배경만으로 그린 표시줄은 보이지 않고, 선택한 탭의 면도 `Canvas` 색이 됩니다. 그래서 Web 은 선택한 탭에 두께로 정해지는 클래스(`co-tab-pane-indicator-<두께>`)를 달고, `@media (forced-colors:active)` 규칙이 높이 0 인 의사 요소에 실제 `border-top` 을 그립니다. `editorStrip` 은 위쪽, `boxed` 는 아래쪽 가장자리이며, 두 variant 모두 시스템 색 `Highlight` 를 씁니다. 의사 요소는 절대 배치라 라벨 위치가 바뀌지 않습니다. 일반 모드에서는 그리는 모양이 같습니다. 표시줄이 없으면(`indicatorColor: transparent` 또는 두께 0) 클래스와 `<style>` 도 없습니다.

남는 차이는 바 아래 선입니다. Web 의 선은 `box-shadow` 라 색 강제 모드에서 두 variant 모두 사라지고, Flutter 의 `Border` 는 남습니다. `boxed` 카드의 테두리는 실제 테두리라 Web 에서도 남습니다.

<a id="남은-갭-figma"></a>

### Figma 세트

[CoUI 라이브러리 파일](https://www.figma.com/design/9FgsLhiWz0aLsVqcoI6nYJ/CoUI---Cocode-Design-System-v1.0)의 `TabPane` 은 `Variant=boxed | editorStrip` 축 하나를 가진 컴포넌트 세트입니다. 겉모습 · 테마 · 다크 축은 따로 없고, 다크 모습은 캔버스의 CoUI 변수 모드가 정합니다.

- `editorStrip` 멤버에는 콘텐츠 패널과 카드가 없습니다. 높이 36의 탭 줄에 띠와 `outlineVariant` 선을 그리고, 모서리는 0 입니다.
- `boxed` 멤버는 루트가 카드(테두리 · 콘텐츠 재질 면 · 모서리 12)입니다. 높이 44의 바 안에 좌우 16을 두고, 탭이 바 높이를 채우며, 바 아래 선과 선택한 탭 폭의 표시줄(위 두 모서리 2)을 그립니다. 항목을 겹치거나 순서를 뒤집어 그리지 않습니다.
- 탭 하나는 `TabPaneTab` 세트(`Variant` × `Selected`)입니다. `Label`, `Show leading` · `Leading`, `Show trailing` · `Trailing`, `Show count`(Badge 인스턴스) 속성이 있고, `Show close` 는 `editorStrip` 멤버에만 있습니다.
- `TabPane` 은 안의 탭 인스턴스를 노출합니다. 자기 속성은 `Content` 와 `Show disabled tab` 입니다. `Show disabled tab` 은 기본이 꺼짐이며, 켜면 50%로 흐린 세 번째 예시 탭이 나타납니다.
- 닫기는 `Button` 인스턴스가 아니라 같은 크기의 상자로 그려 hover 면이 없습니다. 끌고 있는 상태는 없습니다.

코드를 머지해도 게시한 라이브러리는 바뀌지 않습니다. CoUI 파일에서 Generate 를 하고 라이브러리를 게시한 다음, 라이브러리를 쓰는 파일에서 업데이트하고 인스턴스의 `Variant` 를 고릅니다. Generate 는 같은 이름의 단일 컴포넌트가 남아 있으면 한 번 지우고 세트를 만듭니다.

<a id="props-parameters"></a>

## API

`W` 는 위젯 타입(Flutter 의 `Widget`, Web 의 `Component`)입니다. `selectedIndex` 는 0부터 셉니다.

### TabPane 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `tabs` | `List<CoreTabItem<W>>` | 필수 | 탭 목록 |
| `selectedIndex` | `int` | 필수 | 선택한 탭의 자리. 범위를 벗어나면 선택한 탭이 없습니다 |
| `variant` | `CoreTabPaneVariant` | `boxed` | `boxed` 는 탭 카드, `editorStrip` 은 탭 줄. 테마로 바꾸지 않습니다 |
| `onChanged` | `CoreValueChanged<int>?` | `null` | 탭을 누르면 그 자리로 부릅니다. 없으면 모든 탭이 비활성입니다 |
| `reorderable` | `bool` | `false` | `onReorder` 와 함께 켜면 끌어서 순서를 바꿉니다 |
| `onReorder` | `void Function(List<CoreTabItem<W>>)?` | `null` | 새 순서의 탭 목록을 받습니다 |
| `leading` | `List<W>` | `[]` | 탭 바 앞의 위젯. 탭의 `leading` 과 다른 자리입니다 |
| `trailing` | `List<W>` | `[]` | 탭 바 뒤의 위젯. 탭의 `trailing` 과 다른 자리입니다 |
| `tabPaneStyle` | `CoreTabPaneStyle?` | `null` | 인스턴스 스타일 |

`copyWith` 와 `withStyle` 체인이 있습니다. Jaspr Web 에는 플랫폼 차이 표의 Web 전용 속성이 더 있습니다.

### CoreTabItem 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String` | 필수 | 탭 글자. 접근성 이름의 바탕입니다 |
| `enabled` | `bool` | `true` | `false` 면 고를 수 없습니다 |
| `content` | `W?` | `null` | `boxed` 인 `TabPane` 의 패널에 그립니다. `Tabs` 와 `editorStrip` 은 읽지 않습니다 |
| `leading` | `W?` | `null` | 라벨 앞, 탭을 고르는 영역 안. `TabPane` 만 그립니다 |
| `badge` | `W?` | `null` | 라벨 뒤, 탭을 고르는 영역 안 |
| `trailing` | `W?` | `null` | `badge` 뒤, 탭을 고르는 영역 밖. `TabPane` 만 그립니다 |
| `onClose` | `CoreVoidCallback?` | `null` | 주면 닫기 버튼을 그립니다 |

### 테마

`CoreComponentTheme.tabPane`(`CoreTabPaneTheme?`)은 두 variant 에 공통인 `style` 과 variant 별 `variantStyles` 를 받습니다.

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="tab-pane/related-tabs" title="Tabs" href="/components/tabs" more="Tabs 보기">

콘텐츠 패널 없이 탭 바만 필요할 때 씁니다(pill · underline).

</Card>
<Card demo="tab-pane/related-accordion" title="Accordion" href="/components/accordion" more="Accordion 보기">

여러 섹션을 한 페이지에서 펼치고 접을 때 씁니다.

</Card>
</Cards>
