---
title: Menubar
description: 데스크탑 앱 스타일의 상단 가로 메뉴 바 컴포넌트
category: menu
platforms: [flutter, web]
related: [menu, dropdown-menu, context-menu, navigation-menu]
tags: [menubar, desktop, navigation, menu]
template: v2
source: menu/menubar
---

# Menubar

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

`Menubar`는 상위 메뉴 이름을 가로로 늘어놓고, 누른 메뉴의 항목을 패널로 보여 줍니다. 메뉴와 항목은 위젯이 아니라 데이터(`CoreMenubarMenu` · `CoreMenubarEntry`)로 넘기고, 두 플랫폼이 같은 코드를 씁니다. 속성을 바꿔 보고 만들어진 코드를 복사하세요.

<Playground component="menubar" />

<Note>

무대의 열린 메뉴는 그림입니다. 실제 `Menubar`의 패널은 누를 때 페이지 위에 뜨기 때문에, 연 채로 그 자리에 둘 수 없습니다. 플레이그라운드의 그림 아래에 있는 막대가 같은 속성의 실제 `Menubar`이니 눌러서 열어 보세요. 웹 팬에서는 페이지 위에, Flutter 팬에서는 그 팬 안에 패널이 뜹니다. 그림의 막대와 패널은 테마와 서페이스 스타일을 따라가지만, Flutter 그림의 막대는 유리 스타일의 흐림과 가장자리 빛을 그리지 않습니다. 그림의 패널은 막대 아래로 `menuOffset`의 기본값(4)만큼 띄워 그리며, 실제 패널의 세로 자리는 플랫폼마다 다릅니다([플랫폼 차이](#플랫폼-차이)). 이 페이지의 다른 미리보기에 있는 열린 패널도 같은 그림입니다. 플레이그라운드 밖의 막대(형태 · 사용 가이드 카드)는 이 사이트에서 눌러도 열리지 않습니다.

</Note>

## 구조

메뉴 막대는 막대와 상위 메뉴 트리거로 이루어집니다. 메뉴를 열면 그 트리거 아래에 항목을 담은 패널이 뜹니다.

<Anatomy demo="menubar/anatomy">
<AnatomyItem select="[data-docs-part=bar]" side="right" name="Bar">

막대. 채움은 `surfaceBright`, 테두리는 1px `outlineSubtle`, 모서리는 8(컨트롤 역할), 안쪽 여백은 테두리를 포함해 4입니다. 표준 밀도에서 높이는 48입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=open-trigger]" side="left" name="Open trigger">

메뉴가 열린 트리거. `surfaceContainerHigh` 채움과 Medium 굵기의 라벨로 어느 메뉴가 열렸는지 알립니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=trigger]" side="top" name="Trigger">

닫힌 트리거. `Button`의 `menubar` 모양으로, 높이 40, 좌우 12 · 위아래 4 여백, 모서리 8이고 글자는 `labelLarge` · `onSurface`(Regular)입니다. 트리거 사이에는 간격이 없습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=panel]" side="left" name="Panel">

패널. `Menu`가 그리는 상자로, 안쪽 여백 6, 테두리 없음, 모서리 12, `surfaceBright` 채움, `lg` 단계 그림자이고 폭은 160에서 280 사이입니다.

</AnatomyItem>
<AnatomyItem select="[role=menuitem]" side="right" name="Entry">

항목 한 줄. 최소 높이 32, 좌우 8 · 위아래 6 여백, 모서리 8이고 이름은 `labelLarge`입니다. 끝의 단축키 힌트는 `bodyXs` · `onSurfaceVariant`이며, 줄 사이는 2입니다.

</AnatomyItem>
<AnatomyItem select="[role=separator]" side="right" name="Divider">

구분선. 1px `outlineVariant` 선이고 위아래로 4를 띄웁니다.

</AnatomyItem>
</Anatomy>

상위 메뉴의 이름은 필수 `String` 하나입니다. 트리거에는 아이콘이나 다른 위젯을 넣을 수 없습니다.

<a id="변형-variants"></a>

## 항목

상위 메뉴 하나는 이름(`label`)과 항목(`entries`)을 가진 `CoreMenubarMenu`입니다. 항목은 두 종류입니다.

| 만드는 법 | 그리는 것 |
| --- | --- |
| `CoreMenubarEntry.action` | 눌러서 실행하는 항목. 이름과 함께 단축키 힌트 · 표준 아이콘 · 비활성을 정할 수 있습니다. |
| `CoreMenubarEntry.divider` | 항목 묶음 사이의 구분선 |

<Preview demo="menubar/entries" />

체크박스, 라디오, 서브메뉴, 묶음 제목, 설명 줄, 위험한 행동의 색, 앞뒤에 넣는 위젯은 없습니다. 이런 항목이 필요하면 [DropdownMenu](/components/dropdown-menu)를 씁니다.

- 항목을 고르면 메뉴를 먼저 닫고 `onSelect`를 부릅니다.
- `onSelect`가 없는 항목은 활성처럼 보이지만, 눌러도 아무 일도 일어나지 않고 메뉴도 닫히지 않습니다. 지금 실행할 수 없는 항목은 `enabled: false`로 둡니다.
- `entries`가 비어 있는 메뉴를 열면 빈 패널이 뜹니다.
- 상위 메뉴 자체를 비활성으로 만드는 속성은 없습니다.

```dart
CoreMenubarMenu(
  label: '편집',
  entries: [
    CoreMenubarEntry.action(
      label: '실행 취소',
      shortcut: 'Ctrl+Z',
      standardAction: CoreMenuAction.undo,
      onSelect: undo,
    ),
    CoreMenubarEntry.action(
      label: '다시 실행',
      shortcut: 'Ctrl+Shift+Z',
      standardAction: CoreMenuAction.redo,
      enabled: false,
      onSelect: redo,
    ),
    CoreMenubarEntry.divider(),
    CoreMenubarEntry.action(
      label: '잘라내기',
      shortcut: 'Ctrl+X',
      standardAction: CoreMenuAction.cut,
      onSelect: cutSelection,
    ),
    CoreMenubarEntry.action(
      label: '복사',
      shortcut: 'Ctrl+C',
      standardAction: CoreMenuAction.copy,
      onSelect: copySelection,
    ),
    CoreMenubarEntry.action(
      label: '붙여넣기',
      shortcut: 'Ctrl+V',
      standardAction: CoreMenuAction.paste,
      onSelect: pasteClipboard,
    ),
  ],
)
```

<a id="단축키-포함"></a>

### 단축키 힌트

`shortcut`은 항목 끝에 보이는 글자일 뿐입니다. 그 키를 눌러도 `onSelect`가 불리지 않으므로, 실제 단축키는 앱이 따로 연결하고 힌트에는 연결한 키를 그대로 적습니다.

`standardAction`은 잘라내기 · 복사 · 붙여넣기 · 실행 취소 같은 표준 명령(`CoreMenuAction`)의 아이콘을 항목 앞에 그립니다. 아이콘만 더하고, 이름이나 동작은 바꾸지 않습니다. 한 패널에 아이콘이 있는 항목과 없는 항목이 섞이면 이름이 시작하는 자리가 어긋납니다. 항목에 아이콘을 줄 방법은 `standardAction`뿐이므로, 한 메뉴의 모든 항목이 표준 명령일 때만 아이콘을 씁니다.

<a id="비활성-엔트리"></a>

### 비활성 항목

`enabled: false`인 항목은 흐리게 보이고, 눌러도 `onSelect`를 부르지 않으며 메뉴는 열린 채입니다. 목록에서 빠지지는 않아서 패널 안에서는 키보드 정지점으로 남고 비활성이라고 알립니다. Flutter에서 키보드로 패널까지 가는 길은 [알려진 제약](#알려진-제약)을 보세요. 지금 쓸 수 없는 명령을 숨기지 않고 비활성으로 두면 다른 항목의 자리가 바뀌지 않습니다.

## Variant

`variant`는 `CoreMenubarVariant.standard` 하나이며 기본값입니다. 막대의 채움(`surfaceBright`)과 테두리 색(`outlineSubtle`)을 정합니다. 앱 테마의 `CoreMenubarTheme.variantStyles`에 variant별 값을 둘 수 있습니다. 웹은 그중 일부를 패널 위치를 정할 때 읽지 않습니다([플랫폼 차이](#플랫폼-차이)).

## 형태

막대를 상자로 그릴지는 `border`가 정합니다.

<Cards columns="2">
<Card demo="menubar/bordered" title="border: true (기본)" height="140">

막대를 채움 · 테두리 · 둥근 모서리가 있는 상자로 그립니다. 그림자를 더하는 서페이스 스타일에서는 상자에 그림자도 생깁니다.

</Card>
<Card demo="menubar/borderless" title="border: false" height="140">

상자와 그 그림자를 그리지 않고 안쪽 여백 4는 남깁니다. 이미 상자가 있는 도구 영역 안에 둘 때 씁니다. 막대의 채움 · 테두리 · 모서리 필드는 보이지 않습니다.

</Card>
</Cards>

## 상태

<Preview demo="menubar/states" height="140" />

두 번째 트리거(편집)가 열린 모양입니다. 호버와 포커스는 켜 둘 수 없어 표로 설명합니다.

| 트리거 상태 | 모양 |
| --- | --- |
| 쉼 | 채움 없음, Regular 라벨 |
| 호버 | `surfaceContainerHighest` 채움 |
| 포커스 | 호버와 같은 채움. 웹은 키보드 포커스에 포커스 링도 그립니다. |
| 열림 | `surfaceContainerHigh` 채움(호버보다 한 단계 약한 면), Medium 라벨 |

상위 메뉴에는 비활성 상태가 없습니다. 비활성은 패널 안의 항목에만 있습니다.

<a id="동작-스펙-behavior"></a>

## 열고 닫기

### 인터랙션

| 사용자 동작 | 결과 |
| --- | --- |
| 닫힌 트리거 누르기 | 그 메뉴를 엽니다. |
| 열린 트리거 다시 누르기 | 닫습니다. |
| 메뉴가 열린 동안 다른 트리거에 마우스 올리기 | 누르지 않아도 그 메뉴로 바꿉니다. 그 자리에서 누르면 이미 열린 트리거를 누른 것이어서 닫힙니다. |
| 메뉴가 열린 동안 터치로 다른 트리거 누르기 | 그 메뉴로 바꿉니다. |
| 모두 닫힌 상태에서 마우스 올리기 | 아무 일도 없습니다. |
| 항목 고르기(`onSelect`가 있는 항목) | 메뉴를 닫고 `onSelect`를 부릅니다. |
| 막대와 패널 바깥 누르기 | 닫습니다. 누름은 그 아래의 요소에도 그대로 전달됩니다. |
| `Escape` | 웹은 닫고 트리거로 포커스를 돌립니다. Flutter에서는 닫히지 않을 수 있습니다. |

데스크톱 앱의 메뉴 막대처럼, 처음 한 번 누른 뒤로는 포인터를 따라 메뉴가 바뀝니다. 닫힌 상태의 호버로는 열지 않습니다. 막대를 지나가기만 해도 메뉴가 튀어나오기 때문입니다. 마우스를 올리기만 해도 여는 [NavigationMenu](/components/navigation-menu)와 일부러 다르게 두었습니다. 호버가 메뉴를 닫지도 않습니다. 패널로 내려가려면 포인터가 트리거를 벗어나야 하기 때문입니다. 마우스를 올려 바꾸기는 마우스에서만 동작합니다. 웹은 호버를 지원하는 포인터(`hover: hover`)일 때만 바꾸어, 터치의 누름이 메뉴를 바꾼 뒤 바로 닫는 일을 막습니다.

<a id="상태-전환"></a>

### 열림 상태 다루기

열린 메뉴는 0부터 세는 인덱스로 나타냅니다. 보통은 아무것도 주지 않습니다. `Menubar`가 열림을 스스로 기억합니다.

- 열림 · 닫힘 · 전환을 알아야 하면 `onActiveIndexChanged`만 줍니다. 새 인덱스를 받고, 닫히면 `null`을 받습니다.
- `activeIndex`에 값을 주면 그 메뉴가 열립니다. 처음부터 값을 주면 열린 채로 시작합니다. 값이 있는 동안 사용자의 닫기 · 전환은 `onActiveIndexChanged`로 알려 줄 뿐이고, 부모가 값을 바꿔야 반영됩니다.
- `activeIndex: null`은 "닫힘"이 아니라 "`Menubar`가 기억하는 값을 쓰기"입니다. 그래서 받은 값을 그대로 `activeIndex`에 돌려주면 닫기가 한 번에 되지 않을 수 있습니다([알려진 제약](#알려진-제약)).

```dart
Menubar(
  menus: menus,
  onActiveIndexChanged: (index) => logOpenMenu(index),
)
```

열린 동안 `menus`를 새 목록으로 바꾸면 열린 패널도 새 항목을 그립니다. 열린 인덱스가 새 목록의 범위를 벗어나면 패널이 닫힙니다. `activeIndex`를 주지 않았다면 이렇게 닫힌 것은 `onActiveIndexChanged`로 알리지 않습니다. `activeIndex`를 주었다면 부모가 가진 값은 저절로 바뀌지 않으므로, `null`이나 새 목록 안의 인덱스로 함께 바꿉니다. 이때 Flutter는 `onActiveIndexChanged(null)`을 부를 수 있고, 웹은 부르지 않습니다. Flutter에서 같은 `menus` 목록 객체를 그대로 두고 `menubarStyle`만 바꾸면, 열려 있는 패널에는 다음에 열 때 반영될 수 있습니다. `menuOffset`은 두 플랫폼 모두 다음에 열거나 다른 메뉴로 바꿀 때 반영됩니다.

### 애니메이션

- **트리거 채움**: 150ms(`CoreDuration.fast`) 동안 색이 바뀝니다. `menubarStyle`의 `triggerButtonStyle.animationDuration`으로 바꿉니다.
- **패널**: 0.9배에서 커지며 나타나고, 여는 데 150ms · 닫는 데 100ms가 걸립니다. `menubarStyle`의 `menuPanelStyle.openAnimationDuration` · `closeAnimationDuration`으로 바꿉니다.
- 다른 메뉴로 바꾸면 이전 패널을 닫고 새 트리거 아래에 새 패널을 엽니다.
- 동작 줄이기를 켜면 전환 없이 바로 바뀝니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

- 편집기나 업무 도구처럼 파일 · 편집 · 보기 같은 명령 묶음을 화면 위쪽의 같은 자리에 늘 두는 데스크톱 화면에 씁니다.
- 명령은 의미에 따라 상위 메뉴로 나누고, 한 메뉴 안에서는 구분선으로 묶습니다.
- 한 메뉴의 항목이 10개 안팎을 넘으면 메뉴를 나누거나 줄입니다. 화면에 남는 높이보다 긴 메뉴도 패널 안에서 스크롤해 마지막 항목까지 닿지만, 원하는 항목을 찾기 어려워집니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 사이트의 상위 링크와 링크 묶음 패널 | [NavigationMenu](/components/navigation-menu) |
| 버튼 하나에 딸린 명령 목록 | [DropdownMenu](/components/dropdown-menu) |
| 오른쪽 클릭이나 길게 누르기로 여는 명령 | [ContextMenu](/components/context-menu) |
| 화면에 늘 보이는 목록 | [Menu](/components/menu) |
| 같은 화면의 내용 하나를 바꾸기 | [Tabs](/components/tabs) |
| 휴대폰의 주요 화면 이동 | [NavigationBar](/components/navigation-bar) |
| 이름을 검색해 명령 실행하기 | [Command](/components/command) |

<a id="do"></a>
<a id="dont"></a>

### 묶기와 쓰임

<Cards columns="2">
<Card demo="menubar/do-group" tone="do" eyebrow="이렇게 하세요">

관련된 명령을 구분선으로 묶으면 원하는 명령을 빨리 찾습니다.

</Card>
<Card demo="menubar/dont-flat" tone="dont" eyebrow="이렇게 하지 마세요">

성격이 다른 명령을 구분 없이 늘어놓으면 목록을 처음부터 읽어야 합니다.

</Card>
<Card demo="menubar/do-shortcut" tone="do" eyebrow="이렇게 하세요">

자주 쓰는 명령에는 앱이 실제로 연결한 단축키를 힌트로 보여 줍니다. 메뉴를 쓰면서 단축키를 익히게 됩니다.

</Card>
<Card demo="menubar/dont-mobile-nav" tone="dont" eyebrow="이렇게 하지 마세요">

휴대폰의 주요 화면 이동에 쓰지 않습니다. 데스크톱에 맞춘 막대이므로 NavigationBar나 Drawer를 씁니다.

</Card>
</Cards>

## 배치

- `Menubar`는 화면에서의 자리를 스스로 정하지 않습니다. 앱 위쪽처럼 여러 화면에서 같은 자리를 지키는 가로 영역에 놓습니다.
- 패널은 앱의 오버레이에 그려져, 막대를 감싼 상자의 `overflow`에 잘리지 않습니다. 웹은 `CoUIWeb`(`OverlayHost`) 아래에서 그렇습니다.
- 패널은 누른 트리거 아래에, 트리거의 왼쪽 끝에 맞춰 열립니다(`bottomStart`). 글 방향이 오른쪽에서 왼쪽이어도 왼쪽 끝을 맞춥니다.
- 아래에 자리가 모자라면 위로 뒤집어 엽니다. 웹은 위로 열 때 덜 넘치는 경우에만 뒤집습니다. 화면 가장자리에서는 8을 띄웁니다.
- 화면에 남는 높이에는 들어가지만 트리거 위와 아래 어느 쪽에도 다 들어가지 않는 메뉴는, Flutter에서는 화면 안으로 밀려 막대를 덮을 수 있고 웹에서는 일부가 화면 밖으로 나갈 수 있습니다.
- 오른쪽에 자리가 모자라면 Flutter는 패널의 오른쪽 끝을 트리거의 오른쪽 끝에 맞추고, 웹은 화면 안에 들어올 만큼 패널을 왼쪽으로 밉니다.
- 항목이 화면에 남는 높이보다 길면, 패널이 남는 높이를 모두 차지하고 위쪽 여백에 붙어 열립니다(막대를 덮을 수 있습니다). 항목은 패널 안에서 스크롤됩니다.
- 접히는 화면이 접힘으로 나뉘어 있으면 패널은 트리거가 놓인 조각 안에 열립니다.

### 좁은 컨테이너

막대는 모든 트리거가 들어가는 폭이 필요합니다. `Menubar`는 트리거를 가로로 스크롤하거나 여러 줄로 나눠 놓지 않습니다. 더 좁으면 Flutter는 `Row`가 넘친다는 경고를 그리고, 웹은 알림 없이 트리거가 좁아져 라벨이 꺾이거나 레이아웃이 어긋날 수 있습니다. 두 플랫폼의 이 차이는 의도적으로 남겨 둔 것이므로, 폭은 쓰는 쪽에서 보장합니다.

<a id="스타일-시스템-style-system"></a>
<a id="시맨틱-vs-스타일"></a>
<a id="파라미터와-스타일"></a>

## 테마와 스타일

무엇을 보여 줄지와 동작(`menus` · `border` · `variant` · 열림 상태)은 위젯 파라미터로 줍니다. 막대 · 트리거 · 패널 상자 · 라벨 글자의 겉모습은 `menubarStyle`(`CoreMenubarStyle`) 하나로 바꿉니다.

패널 안 항목 줄과 구분선의 모양은 `Menu`가 그리므로 `menubarStyle`로는 바꿀 수 없습니다. 앱 테마의 `CoreMenuTheme`(줄은 `style.itemStyle`, 구분선은 `style.dividerStyle`)으로 바꾸며, 줄은 `CoreMenuItemTheme`으로도 바꿀 수 있습니다. 이 값들은 앱의 다른 메뉴에도 함께 적용됩니다. 다만 줄의 모서리는 `Menu`가 줄마다 정해 넘기므로 `CoreMenuItemTheme`으로는 바뀌지 않습니다. 모서리는 `CoreMenuTheme`의 `style.itemStyle`에 `borderRadius`를 적어 바꿉니다. 패널 상자의 안쪽 여백 · 테두리 두께 · 최소 폭은 `menubarStyle` 쪽 값(기본값 포함)이 앱의 메뉴 테마보다 우선합니다.

<a id="사용-예-flutter-web-동일"></a>

<Split>

<Code language="dart" title="막대 하나만 바꾸기">
Menubar(
  menus: menus,
  menubarStyle: CoreMenubarStyle(
    barBackgroundColor: CoreColor.token(
      CoreColors.surfaceContainer,
    ),
    triggerButtonStyle: CoreButtonStyle(
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space16,
        vertical: CoreSpace.space4,
      ),
    ),
    menuPanelStyle: CorePopupStyle(
      minWidth: CoreLayout.layout240,
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기 (Flutter)">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    menubar: CoreMenubarTheme(
      style: CoreMenubarStyle(
        menuOffset: CoreSpace.space8,
      ),
    ),
  ),
)
</Code>

</Split>

- 라벨 색은 `labelTextStyle`의 `color`로 바꿉니다. 웹에서는 `CoreColor.token`으로 적은 색이 마우스를 올린 동안 `onSurface`로 돌아가고, 쉬는 상태에서도 적용되지 않을 수 있습니다. 토큰이 아닌 색 값(`CoreColor(0xFF…)`)은 적용됩니다.
- 열린 트리거의 라벨 굵기(기본 Medium)는 `openTriggerButtonStyle`의 `labelStyle`이 정합니다. `labelTextStyle`의 굵기만 바꾸면 열린 트리거는 Medium으로 남습니다.
- 열린 트리거의 채움은 `Button`의 `menubar` 모양이 선택 상태에 그리는 채움(`surfaceContainerHigh`)입니다. `openTriggerButtonStyle`이나 `triggerButtonStyle`의 `backgroundColor`를 `CoreColor.token`으로 적으면, Flutter는 열린 트리거에도 그 색을 칠하지만 웹은 선택 채움이 남을 수 있습니다.
- `labelTextStyle`과 `triggerButtonStyle.labelStyle`을 함께 쓰면 두 플랫폼의 결과가 다를 수 있습니다([플랫폼 차이](#플랫폼-차이)). 라벨 글자는 `labelTextStyle` 한쪽에 적습니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreMenubarStyle 기본값                          // 디자인 시스템
  → CoreMenubarTheme.style                        // 앱 전체
  → CoreMenubarTheme.variantStyles[variant]       // variant별
  → menubarStyle                                  // 막대 하나
```

뒤로 갈수록 우선합니다. 필드마다 따로 합쳐지므로 앞에서 정한 다른 필드는 그대로 남습니다.

### 빠른 오버라이드 (Chain)

이미 만든 `Menubar` 인스턴스에 스타일을 빠르게 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 style 슬롯 인자와 동일하게 동작하지만, 이미 구성된 위젯 위에서 바로 이어 쓸 수 있습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class MenubarChainExample extends StatelessWidget {
  const MenubarChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Menubar(
      menus: const [
        CoreMenubarMenu(
          label: '파일',
          entries: [
            CoreMenubarEntry.action(label: '새로 만들기', shortcut: 'Ctrl+N'),
            CoreMenubarEntry.action(label: '열기', shortcut: 'Ctrl+O'),
            CoreMenubarEntry.divider(),
            CoreMenubarEntry.action(label: '종료'),
          ],
        ),
        CoreMenubarMenu(
          label: '편집',
          entries: [
            CoreMenubarEntry.action(label: '잘라내기', shortcut: 'Ctrl+X'),
            CoreMenubarEntry.action(label: '복사', shortcut: 'Ctrl+C'),
            CoreMenubarEntry.action(label: '붙여넣기', shortcut: 'Ctrl+V'),
          ],
        ),
        CoreMenubarMenu(
          label: '보기',
          entries: [
            CoreMenubarEntry.action(label: '확대'),
            CoreMenubarEntry.action(label: '축소'),
            CoreMenubarEntry.divider(),
            CoreMenubarEntry.action(label: '전체 화면'),
          ],
        ),
      ],
    ).withStyle(
      const CoreMenubarStyle(
        barPadding: CoreEdgeInsets.all(CoreSpace.space8),
        barBorderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        barBorderWidth: CoreStrokeWidth.stroke2,
        barBackgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
        barBorderColor: CoreColor.token(CoreColors.primary),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class MenubarChainExample extends StatelessComponent {
  const MenubarChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Menubar(
      menus: const [
        CoreMenubarMenu(
          label: '파일',
          entries: [
            CoreMenubarEntry.action(label: '새로 만들기', shortcut: 'Ctrl+N'),
            CoreMenubarEntry.action(label: '열기', shortcut: 'Ctrl+O'),
            CoreMenubarEntry.divider(),
            CoreMenubarEntry.action(label: '종료'),
          ],
        ),
        CoreMenubarMenu(
          label: '편집',
          entries: [
            CoreMenubarEntry.action(label: '잘라내기', shortcut: 'Ctrl+X'),
            CoreMenubarEntry.action(label: '복사', shortcut: 'Ctrl+C'),
            CoreMenubarEntry.action(label: '붙여넣기', shortcut: 'Ctrl+V'),
          ],
        ),
        CoreMenubarMenu(
          label: '보기',
          entries: [
            CoreMenubarEntry.action(label: '확대'),
            CoreMenubarEntry.action(label: '축소'),
            CoreMenubarEntry.divider(),
            CoreMenubarEntry.action(label: '전체 화면'),
          ],
        ),
      ],
    ).withStyle(
      const CoreMenubarStyle(
        barPadding: CoreEdgeInsets.all(CoreSpace.space8),
        barBorderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        barBorderWidth: CoreStrokeWidth.stroke2,
        barBackgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
        barBorderColor: CoreColor.token(CoreColors.primary),
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

웹은 메뉴 막대 방식의 ARIA 역할과 화살표 키 이동을 갖춥니다. Flutter는 버튼과 메뉴 역할을 쓰며, 막대 전용 키보드 처리는 없습니다.

### 역할

| 요소 | Flutter | Jaspr Web |
| --- | --- | --- |
| 막대 | 이름이 있는 묶음(`Semantics(container: true)`). `menuBar` 역할은 없습니다. | `role="menubar"` · `aria-orientation="horizontal"` |
| 트리거 | 펼침 상태(`expanded`)를 알리는 버튼 | `<button role="menuitem" aria-haspopup="true" aria-expanded>`. 열려 있으면 `aria-selected="true"`도 붙습니다. |
| 패널 | `menu` 역할 | `role="menu"` · `aria-orientation="vertical"` |
| 항목 | `menuItem` 역할 | `role="menuitem"`. 비활성 항목은 `aria-disabled="true"`입니다. |
| 구분선 | 로케일 문구(한국어 "구분선")를 이름으로 가집니다. Flutter에는 구분선 역할이 없습니다. | `role="separator"` · 같은 문구의 `aria-label` |

웹 막대의 `role` · `aria-orientation` · `aria-label`은 `attributes`보다 뒤에 쓰여 바꿀 수 없습니다.

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` | 트리거와 패널의 항목이 각각 정지점입니다. 다만 열어도 포커스가 패널로 가지 않아, 트리거에서 `Tab`으로 패널의 항목까지 가지 못할 수 있습니다([알려진 제약](#알려진-제약)). | 막대 전체가 Tab 정지점 하나입니다. 패널 안에서는 패널을 닫고 트리거로 돌아옵니다. |
| `←` · `→` | 막대 전용 처리가 없습니다. 네이티브에서는 Flutter의 방향 포커스 이동이 동작하고, Flutter Web에서는 스크롤로 갑니다. | 막대: 이전 · 다음 트리거(끝에서 반대쪽으로). 메뉴가 열려 있으면 메뉴도 따라 바뀝니다. 패널: 옆 메뉴를 열고 첫 항목으로 |
| `Home` · `End` | 처리하지 않습니다. | 막대: 첫 · 마지막 트리거. 패널: 첫 · 마지막 항목 |
| `↓` · `↑` | `←` · `→`와 같습니다. | 트리거: 메뉴를 열고 첫 · 마지막 항목으로(열려 있으면 그 항목으로 들어갑니다). 패널: 항목 사이 이동(끝에서 반대쪽으로) |
| 글자 | 처리하지 않습니다. | 패널에서 그 글자로 시작하는 항목으로 옮깁니다. |
| `Enter` · `Space` | 포커스된 트리거를 열고 닫고, 항목을 실행합니다. | 같습니다. 트리거에서 눌러 열면 포커스는 트리거에 남습니다. |
| `Escape` | 처리하지 않습니다. | 닫고 트리거로 포커스를 돌립니다. |

웹의 패널은 오버레이 층에 올라가 문서 순서에서 막대와 떨어져 있습니다. 그래서 패널 안의 `Tab`은 다음 요소로 흘려보내지 않고 패널을 닫은 뒤 트리거로 돌립니다.

### 스크린 리더

- 막대의 이름은 로케일 문구입니다(한국어 "메뉴 막대", 영어 "Menubar"). 두 플랫폼이 같은 문구를 쓰며, 바꾸는 파라미터는 없습니다.
- 트리거와 항목의 이름은 `CoreMenubarMenu.label` · `CoreMenubarEntry.label`입니다. 단축키 힌트는 항목 이름과 함께 읽힐 수 있습니다.
- 메뉴가 열리고 닫히는 것은 따로 알리지 않습니다. 트리거의 펼침 상태(`expanded` · `aria-expanded`)로만 드러납니다.
- 패널에는 이름이 없습니다. 모달이 아니어서 뒤의 화면을 가리지 않고, 모달 패널에 붙는 닫기 접근성 동작도 없습니다.

### 포커스 관리

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 열 때 | 포커스를 옮기지 않습니다. | 누르기 · `Enter` · `Space`로 열면 포커스가 트리거에 남고, `↓` · `↑`로 열면 첫 · 마지막 항목으로 옮깁니다. |
| 닫을 때 | 포커스를 되돌리는 처리가 없습니다. | `Escape`와 패널 안의 `Tab`은 트리거로 돌립니다. 항목을 고른 뒤에는 돌리지 않습니다. |
| 가두기 | 가두지 않습니다. | 가두지 않습니다. |
| 막대의 Tab 정지점 | 트리거마다 하나 | 하나. 처음에는 첫 트리거입니다. 막대의 `←` · `→` · `Home` · `End` · `↓` · `↑`로 옮겨 가고, `Escape`나 패널의 `Tab`으로 닫거나 패널에서 `←` · `→`로 옆 메뉴를 열면 그 트리거로 옮겨 갑니다. 마우스로 누르기만 해서는 옮기지 않습니다. |
| 포커스 표시 | 트리거는 포커스 링을 그리지 않고 호버와 같은 채움만 보입니다. | `Button`의 포커스 링 |

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 사용자가 처음 연 뒤 `onActiveIndexChanged`로 받은 값을 `activeIndex`에 그대로 돌려주면, 닫기(트리거 다시 누르기 · 항목 고르기 · 바깥 누르기 · 웹의 `Escape`)가 한 번에 되지 않거나 부모가 `null`로 바꿔도 열려 있을 수 있습니다. Flutter에서는 바깥을 누르면 패널이 닫혔다가 다시 열릴 수 있습니다. `null`이 "닫힘"이 아니기 때문입니다. 열림을 지켜보기만 할 때는 `activeIndex`를 주지 마세요. |
| 공통 | `onSelect`가 없는 항목은 활성처럼 보이지만 눌러도 아무 일이 없고 메뉴가 닫히지 않습니다. |
| 공통 | `standardAction` 아이콘이 있는 항목과 없는 항목을 섞으면 이름이 시작하는 자리가 어긋납니다. |
| 공통 | 막대와 패널의 이름을 바꾸는 파라미터가 없습니다. |
| Flutter | `Escape`로 닫히지 않을 수 있습니다. 패널을 여는 방식에 `Escape`를 받는 처리가 없습니다. 바깥을 누르거나 트리거를 다시 눌러 닫습니다. |
| Flutter | 트리거가 포커스 링을 그리지 않고 포커스가 호버와 같은 모양이라, 키보드 포커스의 위치를 알기 어렵습니다. |
| Flutter | 화살표 키로 막대와 패널을 오가는 메뉴 방식의 이동이 없습니다. 열어도 포커스가 패널로 가지 않아, 트리거에서 `Tab`을 눌러도 패널의 항목에 닿지 않을 수 있습니다. |
| Jaspr Web | 항목을 고른 뒤 포커스가 트리거로 돌아오지 않아, 페이지의 어느 요소에도 남지 않을 수 있습니다. |
| Jaspr Web | 트리거에서 `Tab`으로 막대를 벗어나면 메뉴가 열린 채 남을 수 있습니다. |
| Jaspr Web | 패널이 `aria-controls`로 트리거와 이어지지 않고, 막대 밖의 오버레이 층에 놓여 막대의 하위 요소가 되지 않습니다. |
| Jaspr Web | 열린 트리거에 붙는 `aria-selected`는 `menuitem` 역할이 지원하는 속성이 아니라, 접근성 검사 도구가 경고할 수 있습니다. |
| Jaspr Web | `activeIndex`에 음수를 주면 그리는 중에 오류가 날 수 있습니다. 닫힘을 `-1`로 나타내지 마세요. |
| Jaspr Web | 메뉴가 열린 동안 툴팁처럼 위치를 계산하는 다른 패널이 열리면, 메뉴 패널이 스크롤을 따라가지 않을 수 있습니다. |
| Jaspr Web | 비활성 항목에 키보드 포커스가 가도 포커스 링이 보이지 않아, 어느 항목에 있는지 알기 어려울 수 있습니다. |
| Jaspr Web | 화면에 남는 높이에는 들어가지만 트리거 위와 아래 어느 쪽에도 다 들어가지 않는 메뉴는 일부가 화면 밖에 놓여, 그 항목이 보이지 않을 수 있습니다. |
| Jaspr Web | `Dialog` 안에서 메뉴를 연 채 `Escape`를 누르면 `Dialog`까지 닫힐 수 있습니다. |

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타깃)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

파라미터 이름과 기본값은 같습니다. 아래는 렌더링과 동작이 다른 곳입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 막대 폭 | 트리거 폭만큼. 부모가 폭을 정하면 늘어납니다. | 블록 요소 안에서는 부모의 폭을 채웁니다. |
| 좁은 컨테이너 | `Row`가 넘친다는 경고를 그립니다. | 알림 없이 트리거가 좁아져 라벨이 꺾이거나 레이아웃이 어긋날 수 있습니다. |
| 패널의 세로 자리(기본값) | `menuOffset`을 트리거 버튼 아래에서 재어, 패널이 막대의 아래 가장자리에 맞닿을 수 있습니다. | 막대의 아래 여백과 테두리를 더해 재어, 막대 아래로 약 5px(`border: false`면 약 4px) 떨어질 수 있습니다. |
| `variantStyles`의 위치 값 | `menuOffset`을 읽습니다. | 패널 위치를 계산할 때 `variantStyles`의 `menuOffset` · `barPadding` · `barBorderWidth`를 읽지 않습니다. |
| 오른쪽 자리가 모자랄 때 | 패널의 오른쪽 끝을 트리거의 오른쪽 끝에 맞춥니다. | 화면 안에 들어올 만큼 왼쪽으로 밉니다. |
| 위아래 어느 쪽에도 다 들어가지 않을 때 | 화면 안으로 밀어 놓아 막대를 덮을 수 있습니다. | 일부가 화면 밖으로 나갈 수 있습니다. |
| 열린 채 스크롤 | 패널이 연 자리에 남아 트리거를 따라가지 않을 수 있습니다. | 트리거를 따라 다시 자리를 잡습니다. |
| 라벨 글자를 두 곳에 줄 때 | 단계(앱 테마 → variant → `menubarStyle`)가 뒤인 값이 이깁니다. | 어느 단계든 `triggerButtonStyle.labelStyle`이 `labelTextStyle`을 이깁니다. |
| 라벨 색을 토큰으로 적을 때 | 모든 상태에 적용합니다. | 마우스를 올리면 `onSurface`로 돌아가고, 쉬는 상태에서도 적용되지 않을 수 있습니다. |
| 열린 트리거의 배경색을 토큰으로 적을 때 | 적은 색을 칠합니다. | 선택 채움(`surfaceContainerHigh`)이 남을 수 있습니다. |
| 비활성 항목 | `disabledContent` 색. 키보드 포커스가 가면 포커스 링이 보입니다. | 같은 색에 불투명도 50%가 더해져 더 흐리고, 포커스 링이 없습니다. |
| 키보드 | 막대 전용 키 처리가 없습니다. | 화살표 · `Home` · `End`와 글자 입력으로 옮겨 다닙니다. |
| `Escape` | 닫히지 않을 수 있습니다. | 닫고 트리거로 포커스를 돌립니다. |
| 마우스를 올려 바꾸기 | 터치는 호버를 알리지 않습니다. | `hover: hover`인 환경에서만 바꿉니다. |
| 패널을 올리는 곳 | 앱의 `Overlay` | 오버레이 호스트의 메뉴 층(top layer). 호스트가 없으면 막대가 있는 자리에 그립니다. |
| 긴 메뉴 | 패널의 높이를 남는 자리로 제한하고 안에서 스크롤합니다. 시스템 바와 화면 키보드가 가린 자리도 뺍니다. | 상자의 `max-height`를 남는 자리로 두고 안의 목록을 스크롤합니다. |
| 추가 파라미터 | — | `id` · `classes` · `css` · `attributes`와 이벤트 처리기 |

<a id="props-parameters"></a>

## API

`Menubar`는 두 플랫폼이 같은 파라미터를 씁니다.

### 위젯 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `menus` | `List<CoreMenubarMenu>` | 필수 | 막대에 늘어놓는 상위 메뉴 |
| `border` | `bool` | `true` | 막대를 채움 · 테두리가 있는 상자로 그릴지 |
| `activeIndex` | `int?` | `null` | 열 메뉴의 인덱스(0부터). `null`이면 `Menubar`가 열림을 기억합니다. |
| `onActiveIndexChanged` | `void Function(int?)?` | `null` | 열림 · 전환 · 닫힘을 알립니다. 닫히면 `null`입니다. |
| `variant` | `CoreMenubarVariant` | `CoreMenubarVariant.standard` | 막대의 색 |
| `menubarStyle` | `CoreMenubarStyle?` | `null` | 막대 · 트리거 · 패널 상자 · 라벨의 겉모습 덮어쓰기 |

웹은 여기에 `id` · `classes` · `css` · `attributes`와 이벤트 처리기를 더 받고, 모두 막대 요소에 붙습니다. 두 플랫폼 모두 `withStyle(CoreMenubarStyle patch)`로 `menubarStyle`에 값을 덧붙인 복사본을 만듭니다.

### CoreMenubarMenu

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String` | 필수 | 막대에 보이는 메뉴 이름 |
| `entries` | `List<CoreMenubarEntry>` | `const []` | 메뉴를 열면 보이는 항목 |

### CoreMenubarEntry

`CoreMenubarEntry.action`의 파라미터입니다. `CoreMenubarEntry.divider()`는 파라미터가 없습니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String` | 필수 | 항목 이름 |
| `shortcut` | `String?` | `null` | 이름 뒤에 보이는 단축키 힌트. 키를 연결하지는 않습니다. |
| `standardAction` | `CoreMenuAction?` | `null` | 이 표준 명령의 아이콘을 앞에 그립니다. |
| `enabled` | `bool` | `true` | `false`면 흐리게 보이고 `onSelect`를 부르지 않습니다. |
| `onSelect` | `CoreVoidCallback?` | `null` | 항목을 고르면 메뉴를 닫은 뒤 부릅니다. 없으면 눌러도 메뉴가 닫히지 않습니다. |

### 테마 — `CoreMenubarTheme`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CoreMenubarStyle?` | `null` | 앱의 모든 메뉴 막대에 깔리는 값 |
| `variantStyles` | `Map<CoreMenubarVariant, CoreMenubarStyle>?` | `null` | variant별로 덧입히는 값 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreMenubarStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `surfaceStyle` | `CoreSurfaceStyleId?` | Material override for this surface; `null` inherits the surrounding material. |
| `barPadding` | `CoreEdgeInsets?` | Internal padding of the horizontal bar container. |
| `barBorderRadius` | `CoreBorderRadius?` | Corner radius of the horizontal bar container. |
| `barBorderWidth` | `double?` | Border width of the horizontal bar container (logical px). |
| `barBackgroundColor` | `CoreColor?` | Background colour of the horizontal bar. |
| `barBorderColor` | `CoreColor?` | Border colour of the horizontal bar. |
| `triggerButtonStyle` | `CoreButtonStyle?` | Style of each top-level trigger `Button(variant: menubar)` — the one place to set the trigger's padding and highlight radius. Laid over [defaultTriggerButtonStyle] and passed to the `Button` as is. `null` falls back to [defaultTriggerButtonStyle]. |
| `openTriggerButtonStyle` | `CoreButtonStyle?` | What the trigger whose menu is open changes on top of its resting style — its label weight by default. Merged over [defaultOpenTriggerButtonStyle]; `null` keeps that default. |
| `menuPanelStyle` | `CorePopupStyle?` | Look of the dropdown menu's panel box. The dropdown is a `Popup` drawn by the panel `Menu`, so this style, laid over [defaultMenuPanelStyle], is passed as is to that `Menu`'s panel slot. The per-instance value is laid on top. |
| `menuOffset` | `double?` | Vertical gap between the bar and a dropdown panel (logical px). |
| `labelTextStyle` | `CoreTextStyle?` | Per-instance override for the top-level trigger label typography — overlaid on the `labelLarge` role / [defaultLabelTextStyle]. Text colour is carried via [CoreTextStyle.color] inside this slot. |

### `CoreMenubarStyle` 변형별 기본값 (`CoreMenubarVariantStyle`)

| 필드 | `standard` |
|------|------|
| `barBackgroundColor` | surfaceBright |
| `barBorderColor` | outlineSubtle |

<!-- STYLE_TABLE:END -->

<Note>

`barBorderRadius` · `barBorderWidth` · `barBackgroundColor` · `barBorderColor`는 `border: true`일 때만 보입니다. `menuOffset`은 막대와 패널 사이의 간격이라고 적혀 있지만, 지금은 두 플랫폼이 재는 기준이 달라 같은 값이라도 보이는 간격이 다를 수 있습니다([플랫폼 차이](#플랫폼-차이)). 표는 라벨 색을 `labelTextStyle`의 `color`에 담는다고 적지만, 웹에서는 `CoreColor.token`으로 적은 색이 마우스를 올린 동안 `onSurface`로 돌아가고 쉬는 상태에서도 적용되지 않을 수 있습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card title="Menu" href="/components/menu" more="Menu 보기">

화면에 놓는 메뉴 패널입니다. Menubar의 패널이 이 컴포넌트입니다.

</Card>
<Card title="DropdownMenu" href="/components/dropdown-menu" more="DropdownMenu 보기">

버튼 하나에 붙여 여는 메뉴입니다. 체크박스 · 라디오 · 서브메뉴 항목을 쓸 수 있습니다.

</Card>
<Card title="ContextMenu" href="/components/context-menu" more="ContextMenu 보기">

오른쪽 클릭이나 길게 누른 자리에서 여는 메뉴입니다.

</Card>
<Card title="NavigationMenu" href="/components/navigation-menu" more="NavigationMenu 보기">

사이트의 상위 링크와 링크 묶음 패널을 보여 줍니다.

</Card>
</Cards>
