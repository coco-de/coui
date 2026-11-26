---
title: NavigationMenu
description: 호버 또는 클릭으로 콘텐츠 패널이 펼쳐지는 가로 메가-메뉴 컴포넌트
category: menu
platforms: [flutter, web]
related: [menu, menubar, navigation-bar]
tags: [navigation-menu, mega-menu, dropdown, menu]
template: v2
source: menu/navigation_menu
---

# NavigationMenu

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 열린 메뉴의 모양을 확인하고, 그림 아래의 실제 `NavigationMenu`에서 항목에 포인터를 올리거나 눌러 패널을 열어 보세요. 마우스로는 올리는 순간 열리므로, 이어서 누르면 닫힙니다. 만들어진 코드는 두 플랫폼에서 그대로 쓸 수 있습니다.

<Playground component="navigation-menu" />

`NavigationMenu`는 `CoreNavigationMenuItem` 목록을 받아 라벨을 가로 바에 늘어놓습니다. `content`가 있는 항목은 포인터를 올리거나 누르면 바 아래에 패널이 열리고, 링크 항목과 동작 항목은 패널 없이 이동하거나 콜백을 부릅니다. 항목의 라벨은 문자열이고, 패널 안에는 원하는 위젯을 넣습니다.

```dart
NavigationMenu(
  items: [
    CoreNavigationMenuItem(
      label: '제품',
      content: Text('제품 카탈로그를 둘러보세요.').bodyMedium,
    ),
    CoreNavigationMenuItem(
      label: '요금제',
      href: '/pricing',
      onTap: openPricing,
    ),
    CoreNavigationMenuItem(label: '로그인', onTap: signIn),
  ],
)
```

<Note>

무대의 위쪽은 첫 항목이 열린 모습의 그림입니다. 열린 패널은 화면 위의 층에 그려져 페이지 안 제자리에 둘 수 없습니다. 그래서 그림의 항목은 `NavigationMenu`와 같은 `menubar` 버튼과 같은 값으로, 패널은 같은 `Popup` 모양으로 그렸습니다. 앱 테마의 색 · 글자 · 밀도, `CoreNavigationMenuTheme`, 서페이스 스타일의 재질은 이 그림에도 닿지만, 화면 가장자리에서의 뒤집기 · 밀기, 열고 닫는 전환, 항목 사이를 옮길 때의 움직임은 없고 그림 속 항목은 눌러도 아무 일이 없습니다. 그 아래의 바는 실제 `NavigationMenu`입니다. 이 사이트에서 눌러서 패널을 열 수 있는 곳은 플레이그라운드이고, 다른 미리보기는 눌러도 열리지 않습니다.

</Note>

## 구조

`NavigationMenu`는 항목을 늘어놓은 바 하나와, 그 아래에 뜨는 패널 하나로 이루어집니다. 패널은 한 번에 하나만 열립니다.

<Anatomy demo="navigation-menu/anatomy">
<AnatomyItem select="[data-docs-part=bar]" side="top" name="bar">

항목을 가로로 늘어놓은 바입니다. 항목 사이는 2(`triggerSpacing`)이고, 바 자체에는 배경과 테두리가 없습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=trigger]" side="left" name="trigger">

항목 하나의 버튼입니다. `Button`의 `menubar` variant를 쓰고, 기본 밀도에서 높이 40, 모서리 8입니다. 라벨은 `labelLarge` · Medium · `onSurface`입니다. 패널을 여는 항목의 안쪽 여백은 위아래 8, 글이 시작하는 쪽 12, 끝나는 쪽 8이고, 패널이 없는 항목은 양옆 12입니다. 그림의 항목은 열린 상태라 `surfaceContainer`로 채워져 있습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=chevron]" side="top" name="chevron">

`content`가 있는 항목에 붙는 아래 화살표입니다. 크기 16, 색 `onSurfaceVariant`이고 라벨과 4 떨어집니다. 열리면 180° 돕니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=panel]" side="left" name="panel">

패널의 상자(`Popup`)입니다. 배경은 `surfaceBright`, 테두리는 1px `outlineVariant`, 모서리는 12, 안쪽 여백은 16, 최소 폭은 256, 그림자는 `lg` 단계, 글자색은 `onSurface`입니다. 열린 항목의 왼쪽 가장자리에 맞춰 4(`menuOffset`) 아래에 놓입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=content]" side="right" name="content">

항목의 `content`에 넣은 위젯입니다. 패널은 글자색을 정할 뿐이라, 글자의 크기와 굵기는 `.bodyMedium` 같은 글자 역할로 직접 정합니다.

</AnatomyItem>
</Anatomy>

## 항목 종류

항목의 종류는 `CoreNavigationMenuItem`의 어느 필드를 채우느냐로 정해집니다. 아래 바는 왼쪽부터 패널 항목, 링크 항목, 동작 항목입니다.

<Preview demo="navigation-menu/kinds" />

| 종류 | 채우는 필드 | 화살표 | 눌렀을 때 |
| --- | --- | --- | --- |
| 패널 항목 | `content` | 있음 | 패널을 열거나 닫고, `onTap`이 있으면 함께 부릅니다. Flutter는 패널이 열려 있을 때 누르면 `onTap` 없이 닫기만 합니다. |
| 링크 항목 | `href` | 없음 | Web은 그 주소로 이동합니다. Flutter는 `onTap`을 부르지만, 패널이 열려 있으면 패널만 닫힙니다. |
| 동작 항목 | `onTap` | 없음 | 열려 있던 패널을 닫고 `onTap`을 부릅니다. Flutter는 패널이 열려 있으면 패널만 닫히고, 한 번 더 눌러야 `onTap`이 불립니다. |

- **링크 항목** — Web은 `<a href>`로 그려 브라우저가 이동하고, `onTap`은 부르지 않습니다. Flutter는 `href`로 이동하지 않고 접근성에 링크라고 알리기만 하므로, 이동은 `onTap`에서 합니다. 두 플랫폼이 같은 곳으로 가게 하려면 `href`와 `onTap`을 함께 줍니다.
- **한 항목에는 한 종류** — `content`와 `href`를 함께 주면 두 플랫폼이 다르게 동작합니다. Flutter는 화살표가 있는 패널 항목으로 그리고, 누르면 패널을 여닫으며 `onTap`을 부릅니다(패널이 열려 있으면 닫기만 합니다). 접근성에는 링크라고도 알립니다. Web은 화살표 없는 링크로 그립니다. 마우스를 올리면 패널이 열리지만, 누르면 주소로 이동하고 `onTap`은 부르지 않습니다.
- **항목이 갖지 않는 것** — 항목에는 아이콘, 비활성 상태, 지금 있는 페이지 표시를 위한 필드가 없습니다.

```dart
// 이렇게 쓰지 않습니다 — Web은 링크로, Flutter는 패널 항목으로 동작합니다.
CoreNavigationMenuItem(
  label: '문서',
  href: '/docs',
  content: Text('문서 미리 보기'),
)
```

<a id="동작-스펙-behavior"></a>

## 상태

<a id="인터랙션"></a>

### 열고 닫기

| 조작 | 동작 |
| --- | --- |
| 패널 항목에 마우스 올리기 | 바로 열립니다. 여는 지연 시간은 없습니다. |
| 패널 항목 누르기 | 열려 있으면 닫고, 닫혀 있으면 엽니다. 마우스는 올리는 순간 이미 열리므로, 이어서 누르면 닫힙니다. |
| 다른 패널 항목에 올리기 | 패널이 닫히지 않고 그 항목 아래로 옮겨 갑니다. |
| 다른 패널 항목 누르기 | 마우스는 올리는 순간 이미 옮겨 갔으므로, 이어서 누르면 닫힙니다. 터치로 눌러도 닫힐 수 있습니다. Web에서 키보드로 누르면 그 항목 아래로 옮겨 갑니다. |
| 링크 · 동작 항목에 올리기 | 열려 있던 패널은 그대로입니다. |
| 포인터가 항목이나 패널을 벗어남 | 200ms(`closeDelay`) 뒤에 닫힙니다. 그 사이에 항목(방금 벗어난 항목 포함)이나 패널에 다시 들어오면 닫지 않습니다. |
| 바깥 누르기 | 닫힙니다. |
| `Escape` | 닫힙니다. |

Flutter는 패널이 열린 동안 바를 포함한 화면 위에 투명한 배경막을 깝니다. 마우스를 올리는 것은 아래 항목에 닿아 패널이 옮겨 가지만, 누르면 배경막이 그 누름을 받아 패널만 닫힙니다. 이때 누른 항목의 `onTap`은 불리지 않고, 다른 패널도 열리지 않습니다.

바와 패널은 4 떨어져 있어, 포인터가 건너가는 동안 잠깐 메뉴를 벗어납니다. `closeDelay`는 그 사이에 패널이 닫히지 않게 하는 여유 시간입니다.

패널 안의 링크나 버튼을 눌러도 메뉴는 저절로 닫히지 않습니다. Flutter에서는 패널 안 위젯의 `context`로 `closeOverlay(context)`를 불러 닫을 수 있습니다.

터치 화면의 Web 브라우저는 누를 때 마우스를 올린 이벤트도 함께 보낼 수 있어, 패널이 열리자마자 닫힐 수 있습니다.

### 트리거 모양

| 상태 | 모양 |
| --- | --- |
| 기본 | 채움이 없습니다. |
| 마우스 올림 | `surfaceContainer`로 채웁니다. |
| 열림 | 같은 `surfaceContainer` 채움을 유지합니다(포인터가 패널로 옮겨 가도). 화살표가 180° 돕니다. |
| 포커스 | Flutter는 포커스 링 없이 `surfaceContainer`로 채웁니다. Web의 버튼 항목은 포커스를 받으면 같은 채움을 그리고(브라우저에 따라 마우스로 눌렀을 때도 남을 수 있습니다), 키보드 포커스에는 링도 그립니다. 링크 항목은 브라우저의 기본 포커스 표시를 씁니다. |

`menubar` variant에는 선택 상태의 채움(`surfaceContainerHigh`)이 따로 있지만, `NavigationMenu`는 열린 항목을 선택 상태로 만들지 않아 이 채움을 쓰지 않습니다. 열린 항목은 올림 채움과 같은 `surfaceContainer`를 유지하고, 이 값은 `openTriggerButtonStyle`이 정합니다.

### 상태 전환

- 닫힘 → 열림: 패널 항목에 마우스를 올리거나 누릅니다. `activeIndex`로도 열 수 있습니다.
- 열림 → 다른 항목: 다른 패널 항목에 마우스를 올리거나, Web에서 키보드로 누르거나, `activeIndex`를 바꿉니다. 패널은 닫혔다 다시 열리지 않고 자리를 옮깁니다.
- 열림 → 닫힘: 바깥 누르기, `Escape`, 열린 항목 다시 누르기, 링크 · 동작 항목 누르기, 포인터가 벗어난 뒤 `closeDelay`가 지남. Flutter는 열려 있을 때 바의 어느 항목을 눌러도 닫힙니다. Web의 링크 항목은 누르면 브라우저가 이동할 뿐, 열린 패널을 닫는 처리는 따로 없습니다.

### 애니메이션

- **열고 닫기** — 패널은 0.9배에서 1배로 커지며 나타나고(150ms), 닫을 때는 반대로 줄며 사라집니다(100ms). 시간은 `panelStyle`의 `openAnimationDuration` · `closeAnimationDuration`으로 바꿉니다. 다만 Flutter는 닫을 때 패널의 내용이 먼저 비워져, 닫히는 전환이 보이지 않고 패널이 바로 사라질 수 있습니다.
- **항목 사이 이동** — `panelSwitchDuration`(기본 300ms, `CoreEasing.move`) 동안 패널이 이전 자리에서 새 자리로 미끄러집니다. 내용은 옮겨 가는 방향 쪽에서 들어오고, 이전 내용은 반대쪽으로 나가며 겹쳐 바뀝니다.
- **화살표** — `duration`(기본 150ms) 동안 180° 돕니다. 항목의 채움 색은 `Button`의 전환 시간(기본 150ms)을 따릅니다.
- **동작 줄이기** — 여닫기 · 이동 · 화살표 전환은 바로 끝납니다. 다만 Web 링크 항목의 색 전환은 줄지 않을 수 있습니다. `closeDelay`는 모션이 아니라 포인터가 건너갈 여유 시간이라 그대로입니다.

### 열림 직접 정하기

`activeIndex`를 생략하면 `NavigationMenu`가 열림을 스스로 관리하고, 사용자 조작으로 열린 항목이 바뀔 때마다 `onActiveIndexChanged`를 새 인덱스로 부릅니다. 닫힐 때는 `null`입니다. 숫자를 주면 그 항목의 패널을 열고, 사용자가 닫거나 다른 항목으로 옮기려 하면 `onActiveIndexChanged`로 알립니다. 목록을 벗어난 숫자나 패널이 없는 항목의 숫자면 패널이 없습니다.

`activeIndex: null`은 "닫기"가 아니라 "스스로 관리하기"라는 뜻입니다. 그래서 `onActiveIndexChanged`로 받은 값을 그대로 `activeIndex`에 돌려주는 방식은 지금 제대로 닫히지 않습니다. Flutter에서는 사용자가 연 메뉴가 바깥을 눌러 `null`을 돌려줘도 열린 채 남고, 한 번 더 눌러야 닫힙니다. 이때 디버그에서는 `Multiple widgets used the same GlobalKey` 오류도 납니다. Web에서는 패널은 보이지 않는데 항목만 열린 모양으로 남을 수 있습니다. 또 Web은 처음부터 `activeIndex`를 주면 패널이 나타나지 않을 수 있습니다. 패널의 자리를 값이 바뀔 때에만 잡기 때문입니다.

열림이 바뀐 것을 알기만 하면 된다면 `activeIndex` 없이 `onActiveIndexChanged`만 씁니다.

```dart
// 열림은 NavigationMenu 가 관리하고, 앱은 바뀐 것만 받습니다.
NavigationMenu(
  items: items,
  onActiveIndexChanged: trackOpenMenu,
)
```

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

사이트 머리글처럼, 분류마다 설명 · 링크 · 카드를 담은 패널을 여는 가로 내비게이션에 씁니다.

### 언제 쓰나

- 사이트 전역 내비게이션에서 분류별로 풍부한 패널이 필요할 때
- 마케팅 사이트의 머리글처럼 제품 · 솔루션을 메가 메뉴로 정리할 때
- 위쪽 항목에 패널 · 링크 · 동작이 섞일 때
- 마우스를 올려 내용을 미리 보여 주면서, 눌러서도 열 수 있어야 할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 파일 · 편집처럼 앱 명령을 담는 데스크톱식 메뉴 바 | [Menubar](/components/menubar) |
| 버튼 하나에서 여는 명령 목록 | [DropdownMenu](/components/dropdown-menu) |
| 늘 펼쳐 두는 항목 목록 | [Menu](/components/menu) |
| 지금 있는 화면을 표시하며 주요 화면을 오가는 바 · 레일 | [NavigationBar](/components/navigation-bar) |
| 구역과 그룹으로 나눈 앱의 옆 내비게이션 | [Sidebar](/components/sidebar) |
| 같은 자리에서 보기를 바꾸는 탭 | [Tabs](/components/tabs) |
| 트리거 하나에 붙는 패널 | [Popover](/components/popover) |

<a id="do"></a>
<a id="dont"></a>

### 항목과 패널

<Cards columns="2">
<Card demo="navigation-menu/do-short" tone="do" eyebrow="이렇게 하세요">

항목 이름은 짧게 쓰고, 바가 놓일 폭에 모든 항목이 들어가게 합니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요" title="좁은 칸에 두기">

바는 항목을 줄이거나 줄을 바꾸거나 스크롤하지 않습니다. 좁으면 [밖으로 넘칩니다](#바가-놓일-폭).

</Card>
<Card tone="do" eyebrow="이렇게 하세요" title="링크는 href와 onTap을 함께">

`href`는 Web의 이동에, `onTap`은 Flutter의 이동에 씁니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요" title="content와 href를 한 항목에">

Flutter는 패널 항목이 되고 Web은 링크가 되어, 같은 코드가 다르게 동작합니다.

</Card>
<Card tone="do" eyebrow="이렇게 하세요" title="패널 밖에도 가는 길 두기">

중요한 목적지는 링크 항목이나 별도 페이지에서도 닿게 합니다. Web에서는 키보드나 터치로 패널 안에 닿기 어려울 수 있습니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요" title="패널에서 입력 · 확인 받기">

마우스 포인터가 벗어나면 패널이 닫힙니다. 폼이나 확인은 [Dialog](/components/dialog)에 둡니다.

</Card>
</Cards>

## 배치

패널은 열린 항목의 아래에, 왼쪽 가장자리를 맞춰 놓입니다. 바와의 간격은 `menuOffset`(기본 4)입니다. 아래 그림은 두 번째 항목이 열린 모습입니다.

<Preview demo="navigation-menu/placement" />

- 오른쪽에서 왼쪽으로 읽는 언어에서도 패널은 항목의 왼쪽 가장자리에 맞춥니다.
- 패널이 화면 가장자리(8 안쪽)를 넘으면 위로 뒤집거나 화면 안으로 옮깁니다. 오른쪽이 넘칠 때 Web은 패널을 왼쪽으로 밀고, Flutter는 패널의 오른쪽 가장자리를 항목의 오른쪽에 맞추는 쪽으로 뒤집을 수 있습니다.
- 다른 패널 항목으로 옮기면 패널도 그 항목 아래로 옮겨 갑니다.
- `CoUIApp` · `CoUIWeb` 아래에서 패널은 화면 위의 층에 그려져, 부모의 `overflow`나 클리핑에 잘리지 않습니다.
- Web은 스크롤이나 창 크기가 바뀌면 패널을 다시 놓습니다. Flutter 패널은 열 때 잰 자리에 놓여, 페이지를 스크롤해도 따라 움직이지 않을 수 있습니다.

### 패널의 크기

- 폭은 내용에 맞추고, 256보다 좁아지지 않습니다. 상한은 없으니 필요하면 `panelStyle`의 `maxWidth`로 정합니다.
- 패널은 긴 내용을 스스로 스크롤하지 않습니다. 화면보다 긴 내용은 넘치거나 잘릴 수 있습니다.
- Flutter 패널은 내용의 폭을 먼저 묻습니다. `LayoutBuilder`처럼 폭을 답하지 못하는 위젯은 `SizedBox(width:)`로 폭을 정해 넣습니다. 패널은 내용의 높이를 정해 주지 않으므로, 세로로 스크롤하는 `ListView`는 `SizedBox(width:, height:)`로 폭과 높이를 함께 정합니다.

### 바가 놓일 폭

바의 폭은 항목이 차지하는 폭의 합입니다. 이보다 좁은 컨테이너에 두면 두 플랫폼이 다르게 깨집니다. Flutter는 디버그 빌드에서 `RenderFlex overflowed` 경고와 넘침 줄무늬를 그리고, Web은 아무 신호 없이 밖으로 넘칩니다. 바를 스크롤하거나 자르지 않고 이 차이를 일부러 남겨 두었으므로, 모든 항목이 들어가는 폭은 호출하는 쪽에서 보장합니다.

```dart
// Flutter — 이렇게 두면 넘칩니다. 항목 라벨을 다 담지 못하는 폭입니다.
SizedBox(
  width: 120,
  child: NavigationMenu(items: items),
)
```

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

<a id="시맨틱-vs-스타일"></a>

### 파라미터와 스타일

항목의 내용 · 종류와 열림은 위젯 파라미터(`items`, `variant`, `activeIndex`, `onActiveIndexChanged`)로, 색 · 크기 · 간격 같은 겉모습은 `navigationMenuStyle`(`CoreNavigationMenuStyle`) 하나로 바꿉니다. 패널의 겉모습은 `panelStyle`(`CorePopupStyle`)에 `Popup`의 스타일 그대로 적습니다. 두 플랫폼이 같은 코드를 씁니다.

<a id="사용-예-flutter-web-동일"></a>

<Split>

<Code language="dart" title="NavigationMenu 하나만 바꾸기">
NavigationMenu(
  items: items,
  navigationMenuStyle: CoreNavigationMenuStyle(
    triggerButtonStyle: CoreButtonStyle(
      hoverBackgroundColor: CoreColor.token(
        CoreColors.secondaryContainer,
      ),
    ),
    openTriggerButtonStyle: CoreButtonStyle(
      backgroundColor: CoreColor.token(
        CoreColors.secondaryContainer,
      ),
    ),
    panelStyle: CorePopupStyle(
      borderRadius: CoreBorderRadius.all(
        CoreRadiusRole.surface,
      ),
      maxWidth: CoreLayout.layout400,
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    navigationMenu: CoreNavigationMenuTheme(
      style: CoreNavigationMenuStyle(
        triggerSpacing: CoreSpace.space8,
        panelStyle: CorePopupStyle(
          padding: CoreEdgeInsets.all(CoreSpace.space20),
        ),
      ),
    ),
  ),
)
</Code>

</Split>

### 항목의 겉모습 바꾸기

패널 · 동작 항목은 `Button`이라 버튼 스타일 필드로 바꿉니다. Web의 링크 항목은 버튼이 아니라 `<a>`라서, 따로 정해진 필드를 읽습니다.

| 바꿀 것 | 버튼으로 그리는 항목 (Flutter 전부, Web의 패널 · 동작 항목) | Web 링크 항목 |
| --- | --- | --- |
| 안쪽 여백 | `triggerButtonStyle`의 `padding`. 패널 항목만 바꾸려면 `contentTriggerButtonStyle` | `triggerPadding` |
| 모서리 | `triggerButtonStyle`의 `borderRadius` | `triggerBorderRadius` |
| 올림 · 열림 채움 | `triggerButtonStyle`의 `hoverBackgroundColor`와 `openTriggerButtonStyle`의 `backgroundColor` | `triggerHoverColor` |
| 라벨 글자 | Flutter는 `triggerTextStyle`, Web은 `triggerButtonStyle`의 `labelStyle` | `triggerTextStyle` |
| 라벨과 화살표 간격 | `triggerButtonStyle`의 `iconLabelGapStyle` | 화살표가 없습니다. |
| 화살표 | `chevronIconStyle` | 화살표가 없습니다. |
| 항목 사이 간격 | `triggerSpacing` | `triggerSpacing` |

- `triggerPadding` · `triggerBorderRadius` · `triggerHoverColor`는 Flutter에서는 어떤 항목에도 적용되지 않습니다.
- `chevronIconStyle`은 기본값에 덧붙이지 않고 통째로 대신합니다. 크기만 적으면 색이 `onSurfaceVariant`가 아니라 항목의 글자색이 됩니다.
- 라벨 글자를 두 플랫폼에서 같게 바꾸려면 `triggerTextStyle`과 `triggerButtonStyle`의 `labelStyle`에 같은 값을 줍니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreNavigationMenuStyle.defaultX · defaultsByVariant   // 디자인 시스템 기본값
  → CoreNavigationMenuTheme.style                      // 앱의 모든 NavigationMenu
  → CoreNavigationMenuTheme.variantStyles[variant]     // variant별
  → navigationMenuStyle                                // NavigationMenu 하나
```

뒤로 갈수록 우선하고, 필드마다 따로 합쳐집니다. 항목의 버튼에는 `CoreButtonTheme`도 적용되지만, `NavigationMenu`가 넘기는 여백 · 모서리 · 올림 채움 · 화살표 간격이 그 위에 옵니다.

패널은 `Popup`의 값 위에 쌓입니다.

```text
CorePopupStyle 기본값                          // Popup 의 디자인 시스템 값
  → CorePopupTheme.style                       // 앱의 모든 Popup
  → NavigationMenu 의 패널 기본값과 색           // 여백 · 모서리 · 테두리 · 그림자 · 최소 폭 · 색
  → CoreNavigationMenuTheme 의 panelStyle
  → navigationMenuStyle 의 panelStyle
```

`NavigationMenu`의 패널 기본값이 `CorePopupTheme`보다 뒤에 있으므로, 그 기본값이 정하는 여백 · 모서리 · 색 등은 `CorePopupTheme`으로 바뀌지 않습니다. 앱 전체에서 바꾸려면 `CoreNavigationMenuTheme`에 적습니다.

### 빠른 오버라이드 (Chain)

이미 만든 `NavigationMenu`에 스타일을 덧붙일 때는 `withStyle`을 이어 씁니다. 생성자의 `navigationMenuStyle`에 주는 것과 같고, 여러 번 이으면 뒤의 값이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class NavigationMenuChainExample extends StatelessWidget {
  const NavigationMenuChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationMenu(
      items: [
        CoreNavigationMenuItem(
          label: '제품',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Theme.of(context).geometry.space(CoreSpace.space8),
            children: [
              Text('웹 앱').titleSmall.medium,
              Text('최신 웹 경험을 만들어요').bodySmall.onSurfaceVariant,
              Text('모바일 앱').titleSmall.medium,
              Text('iOS와 Android 네이티브 앱').bodySmall.onSurfaceVariant,
            ],
          ),
        ),
        CoreNavigationMenuItem(
          label: '솔루션',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Theme.of(context).geometry.space(CoreSpace.space8),
            children: [
              Text('스타트업용').titleSmall.medium,
              Text('처음부터 출시까지 함께해요').bodySmall.onSurfaceVariant,
              Text('기업용').titleSmall.medium,
              Text('보안과 규정 준수를 기본으로 갖췄어요').bodySmall.onSurfaceVariant,
            ],
          ),
        ),
        CoreNavigationMenuItem(label: '요금제', onTap: () {}),
        CoreNavigationMenuItem(label: '소개', onTap: () {}),
      ],
    ).withStyle(
      const CoreNavigationMenuStyle(
        triggerPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space20,
          vertical: CoreSpace.space12,
        ),
        triggerBorderRadius: CoreBorderRadius.all(CoreRadius.radius24),
        triggerHoverColor: CoreColor.token(CoreColors.secondaryContainer),
        triggerSpacing: CoreSpace.space12,
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class NavigationMenuChainExample extends StatelessComponent {
  const NavigationMenuChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return NavigationMenu(
      items: [
        CoreNavigationMenuItem(
          label: '제품',
          content: div(
            [
              Text('웹 앱').titleSmall.medium,
              Text('최신 웹 경험을 만들어요').bodySmall.onSurfaceVariant,
              Text('모바일 앱').titleSmall.medium,
              Text('iOS와 Android 네이티브 앱').bodySmall.onSurfaceVariant,
            ],
            styles: const Styles(
              display: Display.flex,
              flexDirection: FlexDirection.column,
              gap: jaspr_dom.Gap.all(Unit.pixels(CoreSpace.space8)),
            ),
          ),
        ),
        CoreNavigationMenuItem(
          label: '솔루션',
          content: div(
            [
              Text('스타트업용').titleSmall.medium,
              Text('처음부터 출시까지 함께해요').bodySmall.onSurfaceVariant,
              Text('기업용').titleSmall.medium,
              Text('보안과 규정 준수를 기본으로 갖췄어요').bodySmall.onSurfaceVariant,
            ],
            styles: const Styles(
              display: Display.flex,
              flexDirection: FlexDirection.column,
              gap: jaspr_dom.Gap.all(Unit.pixels(CoreSpace.space8)),
            ),
          ),
        ),
        CoreNavigationMenuItem(label: '요금제', onTap: () {}),
        CoreNavigationMenuItem(label: '소개', onTap: () {}),
      ],
    ).withStyle(
      const CoreNavigationMenuStyle(
        triggerPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space20,
          vertical: CoreSpace.space12,
        ),
        triggerBorderRadius: CoreBorderRadius.all(CoreRadius.radius24),
        triggerHoverColor: CoreColor.token(CoreColors.secondaryContainer),
        triggerSpacing: CoreSpace.space12,
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<Note>

이 예제가 적는 값 가운데 지금 화면에 반영되는 것은 `triggerSpacing`입니다. `triggerPadding` · `triggerBorderRadius` · `triggerHoverColor`는 Flutter에서는 어디에도 적용되지 않고 Web에서는 링크 항목에만 닿는데, 이 예제에는 링크 항목이 없습니다. 버튼으로 그리는 항목의 여백 · 모서리 · 채움은 [항목의 겉모습 바꾸기](#항목의-겉모습-바꾸기)의 필드로 바꿉니다.

</Note>

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreNavigationMenuStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `triggerPadding` | `CoreEdgeInsets?` | Padding applied to each top-level trigger. |
| `triggerBorderRadius` | `CoreBorderRadius?` | Corner radius of a top-level trigger. |
| `triggerHoverColor` | `CoreColor?` | Hover / active background colour of a trigger. |
| `triggerButtonStyle` | `CoreButtonStyle?` | Style for the top-level trigger `Button(variant: menubar)` — the one place that sets the trigger button's padding, corners, label → chevron gap and hover fill. Laid over [defaultTriggerButtonStyle] (used alone when `null`) and passed to the `Button` as is. |
| `contentTriggerButtonStyle` | `CoreButtonStyle?` | What a trigger that owns a dropdown (and so shows a chevron) changes on top of [triggerButtonStyle]. Merged over [defaultContentTriggerButtonStyle]; `null` keeps that default. |
| `openTriggerButtonStyle` | `CoreButtonStyle?` | What a trigger changes on top of its content-trigger style while its dropdown is open. Merged over [defaultOpenTriggerButtonStyle]; `null` keeps that default. |
| `triggerSpacing` | `double?` | Spacing between adjacent top-level triggers in the bar (logical px, pre-scaling). Flows directly into `Row.spacing` (Flutter) / inline CSS `gap` (Web) — both native paint-API forms that consume raw doubles, so the slot stays scalar (`double?`). The label → chevron gap is not this value: it is [triggerButtonStyle]'s `iconLabelGapStyle`. Falls back to [defaultTriggerSpacing] when null. |
| `triggerTextStyle` | `CoreTextStyle?` | Top-level trigger label text style override. The typography role, weight and colour ([CoreTextStyle.color]) all go in this one style. Overlaid on [defaultTriggerTextStyle] (`labelLarge` role + medium weight + `onSurface` colour) when null. |
| `chevronIconStyle` | `CoreIconStyle?` | Chevron disclosure icon style of a content trigger. Falls back to [defaultChevronIconStyle] when null. |
| `panelStyle` | `CorePopupStyle?` | Look of the dropdown panel, which is a `Popup`. Laid over [defaultPanelStyle] and the variant's colours from [defaultsByVariant], then passed as is to the `Popup`'s `popupStyle`; the `Popup` fills in the rest from [CorePopupStyle]'s own defaults. |
| `menuOffset` | `double?` | Vertical gap between the trigger bar and a dropdown panel (logical px). |
| `duration` | `Duration?` | Open / close colour-transition duration. |
| `closeDelay` | `Duration?` | Grace period between the pointer leaving the menu and the panel closing. Falls back to [defaultCloseDelay] when null. |
| `panelSwitchDuration` | `Duration?` | Duration of the panel's slide when the open menu moves from one trigger to another. Falls back to [defaultPanelSwitchDuration] when null. |

### `CoreNavigationMenuStyle` 변형별 기본값 (`CorePopupStyle`)

| 필드 | `standard` |
|------|------|
| `backgroundColor` | surfaceBright |
| `borderColor` | outlineVariant |

<!-- STYLE_TABLE:END -->

<Note>

표의 설명과 다른 지금 동작입니다.

- `triggerPadding` · `triggerBorderRadius` · `triggerHoverColor`는 Flutter에서는 적용되지 않고, Web에서는 링크 항목에만 적용됩니다.
- `triggerTextStyle`은 Web에서는 링크 항목에만 적용됩니다.
- `duration`은 패널을 여닫는 시간이 아닙니다. 화살표 회전과 Web 링크 항목의 색 전환 시간입니다. 여닫는 시간은 `panelStyle`의 `openAnimationDuration` · `closeAnimationDuration`입니다.
- `closeDelay`는 동작 줄이기를 켜도 줄지 않습니다.
- `chevronIconStyle`은 기본값에 덧붙이지 않고 통째로 대신합니다.

</Note>

<a id="접근성-accessibility"></a>

## 접근성

역할은 WAI-ARIA의 **disclosure navigation** 패턴을 따릅니다. 앱 메뉴가 아니라 사이트 내비게이션이라, `menubar` · `menu` · `menuitem` 역할을 쓰지 않습니다. 패널에는 링크 · 카드 · 글 같은 임의의 내용이 들어가는데, 메뉴라고 알리면 스크린 리더는 화살표로 움직이는 메뉴를 기대하고 안의 링크는 그것을 줄 수 없기 때문입니다. 다만 Flutter는 패널이 열린 동안 포커스를 패널에 두고 뒤 화면을 접근성 트리에서 뺍니다([포커스 관리](#포커스-관리)).

### 역할

| 자리 | Flutter | Jaspr Web |
| --- | --- | --- |
| 바 | navigation 랜드마크. 이름은 로케일의 내비게이션 문구(한국어 "탐색") | `<nav>` 랜드마크와 같은 문구의 `aria-label`. `role`은 따로 적지 않습니다. |
| 패널 항목 | 버튼 + 펼침 상태 | `<button>` + `aria-expanded` |
| 링크 항목 | 버튼 + 링크 표시 | `<a href>` |
| 동작 항목 | 버튼 | `<button>` |
| 패널 | 패널 자체의 역할은 없습니다. 둘레에 로케일의 닫기 문구(한국어 "닫기")를 이름으로 한 닫기 노드가 있습니다. | 이름과 역할이 없습니다. |

- **`<nav>`로 다시 감싸지 않습니다.** Web 컴포넌트는 이미 `<nav>`라서, 바깥에 또 `<nav>`를 두면 같은 내비게이션이 랜드마크 두 겹이 됩니다. 레이아웃용 상자는 `<div>`를 씁니다.
- **Web은 랜드마크 이름을 바꿀 수 있습니다.** `attributes: {'aria-label': '주요'}`처럼 넘긴 값이 기본 문구를 이깁니다. 한 페이지에 내비게이션이 여럿이면(머리글 · 사이드바 · 바닥글) 서로 다른 이름을 줍니다. Flutter에는 이 이름을 바꾸는 파라미터가 없습니다.

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` (패널이 닫혀 있을 때) | 항목마다 한 번씩 포커스가 멈춥니다. | 항목(버튼 · 링크)마다 한 번씩 포커스가 멈춥니다. |
| `Enter` · `Space` (패널 항목) | 패널을 엽니다. 열리면 포커스가 패널로 옮겨 가므로, 닫을 때는 `Escape`를 씁니다. | 패널을 여닫습니다. |
| `Enter` · `Space` (동작 항목) | `onTap`을 부릅니다. | `onTap`을 부릅니다. |
| 링크 항목의 `Enter` · `Space` | `onTap`을 부릅니다. | `Enter`는 이동하고, `Space`로는 이동하지 않습니다. |
| `Tab` (패널이 열려 있을 때) | 포커스가 패널 안에서 돕니다. | 다음 항목으로 갑니다. 패널 내용은 문서 끝에 그려져 있습니다. |
| `Escape` | 패널을 닫습니다. | 포커스가 어디 있든 패널을 닫습니다. |

화살표 · `Home` · `End`로 항목을 옮기는 동작은 따로 두지 않습니다. 키보드로 포커스를 옮기는 것만으로는 패널이 열리지 않습니다.

### 스크린 리더

- 항목의 이름은 `CoreNavigationMenuItem`의 `label`입니다.
- 펼침 상태는 Flutter의 `expanded`, Web의 `aria-expanded`로 알립니다. 열림과 닫힘을 따로 알리는 live region은 없습니다.
- 패널 안의 내용은 `content` 자신의 의미를 그대로 유지합니다. Web의 패널은 이름이 없고, 항목과 패널을 `aria-controls`로 잇지 않습니다.
- 항목 사이를 옮기며 두 내용이 겹쳐 보이는 동안, 나가는 내용은 두 플랫폼 모두 접근성 트리에서 뺍니다.
- Flutter는 패널이 열린 동안 바를 포함한 뒤 화면이 접근성 트리에서 빠집니다. 그래서 열린 동안에는 항목에서 펼쳐진 상태를 확인하지 못할 수 있습니다. 패널은 위 표의 "닫기" 노드가 가진 닫기 동작으로도 닫을 수 있습니다.
- Flutter의 링크 항목은 버튼 위에 링크 표시를 얹으므로 버튼이라고도 알립니다. Web은 링크 하나입니다.

### 포커스 관리

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 열 때 | 포커스를 패널의 포커스 범위로 옮깁니다. 마우스를 올려 열 때도 같습니다. | 포커스를 옮기지 않습니다. |
| 열린 동안 | `Tab`이 패널 안에서 돕니다. | 배경에 `inert`를 걸지 않고 가두지 않습니다. |
| 닫을 때 | 트리거로 되돌리는 처리는 따로 없고, 사라진 포커스 범위 다음의 포커스는 Flutter가 정합니다. | 트리거로 되돌리지 않습니다. 패널 안에 있던 포커스는 잃을 수 있습니다. |
| 포커스 표시 | 링 없이 `surfaceContainer` 채움 | 버튼 항목은 키보드 포커스 링과 채움, 링크 항목은 브라우저 기본 표시 |

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | `onActiveIndexChanged`의 값을 그대로 `activeIndex`에 돌려주면 사용자가 연 메뉴가 제대로 닫히지 않습니다. Flutter는 열린 채 남고, Web은 패널이 숨은 채 항목만 열린 모양으로 남을 수 있습니다([열림 직접 정하기](#열림-직접-정하기)). |
| 공통 | 마우스 포인터가 항목이나 패널을 벗어나면 닫히므로, 키보드로 보던 중에도 마우스가 벗어나면 닫힐 수 있습니다. |
| 공통 | 패널 안의 항목을 눌러도 메뉴가 저절로 닫히지 않습니다. |
| 공통 | 항목에 비활성 상태, 지금 있는 페이지 표시, 아이콘이 없습니다. |
| 공통 | 바가 들어가지 않는 좁은 폭에서는 넘칩니다([바가 놓일 폭](#바가-놓일-폭)). |
| Flutter | 패널이 열려 있으면 바의 항목을 눌러도 패널만 닫혀, 누른 항목의 `onTap`이 불리지 않고 다른 패널도 열리지 않습니다. |
| Flutter | 닫을 때 패널의 내용이 먼저 비워져, 닫히는 전환이 보이지 않을 수 있습니다. |
| Flutter | 마우스를 올려 열어도 포커스를 패널로 가져가므로, 다른 곳에 입력하던 포커스가 옮겨질 수 있습니다. |
| Flutter | 포커스 표시가 옅은 채움뿐이라 눈에 덜 띌 수 있습니다. |
| Flutter | `href`로는 이동하지 않습니다. 이동은 `onTap`에서 합니다. |
| Flutter | 랜드마크 이름을 바꿀 수 없어, 내비게이션이 여럿인 화면에서 구별하기 어려울 수 있습니다. |
| Flutter | 열린 패널은 페이지를 스크롤해도 따라 움직이지 않을 수 있습니다. |
| Web | 패널이 문서 끝의 층에 그려져, 트리거에서 `Tab`으로 바로 패널 안에 들어가지 못할 수 있습니다. |
| Web | `content`와 `href`를 함께 준 항목은 키보드로 패널을 열 수 없습니다. |
| Web | 터치 화면에서는 패널이 열리자마자 닫힐 수 있습니다. |
| Web | 처음부터 `activeIndex`를 주면 패널이 나타나지 않을 수 있습니다. |
| Web | 다른 패널(툴팁 · Popover · 메뉴 류)이 열리면, 열려 있던 패널의 위치 추적이 멈출 수 있습니다. |
| Web | 링크 항목은 `onTap`을 부르지 않고, 높이를 따로 정하지 않아 다른 항목(40)보다 낮을 수 있습니다. |
| Web | 링크 항목의 색 전환은 동작 줄이기를 켜도 줄지 않을 수 있습니다. |
| Web | 다른 패널 항목으로 옮기는 전환 동안에는 이전 내용이 새 내용 위에 겹쳐 있어, 그 사이에 누르면 이전 내용이 눌릴 수 있습니다. |

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 등)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

파라미터 이름과 기본값은 같고, 그리는 방법과 이벤트는 각 플랫폼의 방식을 따릅니다. Web의 위젯 타입은 `Widget` 대신 `Component`입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 링크 항목 | 다른 항목과 같은 `menubar` 버튼 | `<a href>`. `Button`이 아닙니다. |
| `href` | 링크 표시만 하고 이동하지 않습니다. | 브라우저가 이동합니다. |
| 링크 항목의 `onTap` | 부릅니다. 패널이 열려 있으면 불리지 않습니다. | 부르지 않습니다. |
| `content`와 `href`를 함께 | 화살표가 있는 패널 항목 + 링크 표시 | 화살표 없는 링크. 마우스를 올리면 패널이 열립니다. |
| 링크 항목의 높이 | 다른 항목과 같습니다. | 글자 줄과 위아래 여백만큼이라 기본값에서 36입니다. |
| `triggerPadding` · `triggerBorderRadius` · `triggerHoverColor` | 적용되지 않습니다. | 링크 항목에만 적용됩니다. |
| `triggerTextStyle` | 모든 항목 | 링크 항목에만 적용됩니다. |
| 패널이 그려지는 곳 | 앱의 루트 오버레이 | `CoUIWeb` · `OverlayHost`의 메뉴 층에 올리고 브라우저의 top layer로 올립니다. 호스트가 없으면 바 안에 이어 그립니다. |
| 열린 동안 뒤 화면 | 투명한 배경막을 깔고 접근성 트리에서 뺍니다. 첫 누름은 패널을 닫는 데 쓰여, 아래의 버튼은 눌리지 않습니다. | 막지 않습니다. 바깥을 누르면 닫히고, 누른 요소도 그 누름을 받습니다. |
| 열린 동안 바의 항목 누르기 | 패널만 닫힙니다. | 누른 항목이 동작합니다. 패널 항목은 옮겨 가거나 닫히고, 동작 항목은 패널을 닫고 `onTap`을 부르며, 링크 항목은 이동합니다. |
| 열 때의 포커스 | 패널로 옮깁니다. | 옮기지 않습니다. |
| 위치 다시 잡기 | 열 때와 다른 항목으로 옮길 때. 스크롤은 따라가지 않을 수 있습니다. | 스크롤 · 창 크기가 바뀔 때도 |
| 오른쪽이 넘칠 때 | 패널의 오른쪽을 항목의 오른쪽에 맞추는 쪽으로 뒤집을 수 있습니다. | 패널을 왼쪽으로 밉니다. |
| 닫히는 전환 | 내용이 먼저 비워져 보이지 않을 수 있습니다. | 줄면서 흐려집니다. |
| 처음부터 `activeIndex` | 그 패널을 엽니다. | 패널이 나타나지 않을 수 있습니다. |
| 추가 속성 | 없습니다. | `id` · `classes` · `css` · `attributes`와 이벤트 처리기를 받아 `<nav>`에 붙입니다. |

여는 전환은 두 플랫폼 모두 0.9배에서 1배로 커지며 나타나지만, 기준점과 곡선이 다릅니다. Flutter는 항목에 붙는 모서리(기본은 패널의 왼쪽 위)를 기준으로 일정한 속도로 커지고, Web은 패널 가운데를 기준으로 `CoreEasing.enter`를 따라 커집니다. Web은 닫을 때 `CoreEasing.exit`를 씁니다. 항목 사이를 옮길 때의 이동은 두 플랫폼 모두 `panelSwitchDuration`과 `CoreEasing.move`를 씁니다.

<a id="props-parameters"></a>

## API

두 플랫폼이 같은 파라미터를 씁니다. `W`는 위젯 타입으로 Flutter에서는 `Widget`, Web에서는 `Component`입니다. Web의 추가 속성은 [플랫폼 차이](#플랫폼-차이)를 보세요.

### 위젯 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `items` | `List<CoreNavigationMenuItem<W>>` | 필수 | 바에 늘어놓는 항목 |
| `activeIndex` | `int?` | `null` | 숫자를 주면 그 항목을 엽니다. `null`이면 스스로 관리합니다([열림 직접 정하기](#열림-직접-정하기)). |
| `onActiveIndexChanged` | `void Function(int?)?` | `null` | 사용자 조작으로 열린 항목이 바뀌거나 바꾸려 할 때 새 인덱스로 부릅니다. 닫을 때는 `null`입니다. |
| `variant` | `CoreNavigationMenuVariant` | `standard` | 지금은 `standard` 하나입니다. |
| `navigationMenuStyle` | `CoreNavigationMenuStyle?` | `null` | 겉모습 · 간격 · 전환 시간 덮어쓰기 |

두 플랫폼 모두 `withStyle(CoreNavigationMenuStyle patch)`로 `navigationMenuStyle`에 값을 덧붙인 복사본을 만듭니다.

`navigationMenuStyle`의 필드는 [테마와 스타일](#테마와-스타일) 끝의 필드 표에 있습니다.

### `CoreNavigationMenuItem`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String` | 필수 | 항목의 라벨. 접근 가능한 이름이 됩니다. |
| `content` | `W?` | `null` | 패널에 그릴 위젯. 있으면 패널 항목입니다. |
| `href` | `String?` | `null` | 링크 주소. Web에서 이동합니다. |
| `onTap` | `CoreVoidCallback?` | `null` | 눌렀을 때 부릅니다. Web의 링크 항목은 부르지 않습니다. Flutter는 패널이 열린 동안 바를 누르면 부르지 않습니다. |

### 테마 — `CoreNavigationMenuTheme`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CoreNavigationMenuStyle?` | `null` | 앱의 모든 `NavigationMenu`에 깔리는 값 |
| `variantStyles` | `Map<CoreNavigationMenuVariant, CoreNavigationMenuStyle>?` | `null` | variant별 값 |

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="Menubar" href="/components/menubar" more="Menubar 보기">

데스크톱 앱처럼 명령을 담는 메뉴 바입니다.

</Card>
<Card title="NavigationBar" href="/components/navigation-bar" more="NavigationBar 보기">

앱의 주요 화면을 오가는 바 · 레일입니다. 옆 내비게이션에는 Sidebar를 씁니다.

</Card>
<Card title="DropdownMenu" href="/components/dropdown-menu" more="DropdownMenu 보기">

버튼에서 여는 명령 목록입니다.

</Card>
<Card title="Menu" href="/components/menu" more="Menu 보기">

화면에 늘 펼쳐 두는 항목 목록입니다.

</Card>
<Card title="Tabs" href="/components/tabs" more="Tabs 보기">

같은 자리에서 보기를 바꾸는 탭 바입니다.

</Card>
<Card title="Popup" href="/components/popup" more="Popup 보기">

패널의 상자입니다. 위치와 열림을 직접 관리하는 패널에 씁니다.

</Card>
</Cards>
