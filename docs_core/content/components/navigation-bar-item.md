---
title: NavigationBarItem
description: NavigationBar 의 목적지 하나를 바 밖에서도 직접 놓는 항목입니다. 아이콘 · 이름 · 배지와 지금 있는 곳 표시를 가집니다.
category: navigation
platforms: [flutter, web]
related: [navigation-bar, sidebar, drawer, badge]
tags: [navigation, sidebar, drawer, item]
template: v2
source: navigation/navigation_bar_item
---

# NavigationBarItem

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

모양과 상태를 바꿔 보며 목적지 하나를 확인하고, 만들어진 코드를 그대로 복사하세요. 미리보기의 둥근 판은 문서가 그린 것으로, 항목이 hover · 포커스 · 눌림 색을 섞는 바탕색입니다.

<Playground component="navigation-bar-item" />

`NavigationBarItem` 은 아이콘 · 이름 · 개수 배지와 지금 있는 곳인지를 알리는 표시를 가진 목적지 하나입니다. [NavigationBar](/components/navigation-bar) 가 목적지마다 쓰는 바로 그 위젯이라, 바 밖에 직접 놓아도 같은 모양과 동작을 가집니다. 항목은 선택을 스스로 기억하지 않습니다. `selected` 를 그리고 누르면 `onPressed` 를 부를 뿐이므로, 지금 있는 곳은 항목을 놓는 화면이 정합니다.

```dart
NavigationBarItem(
  icon: const Icon(LucideIcons.inbox),
  label: '받은편지함',
  badge: const Badge(
    form: CoreBadgeForm.count,
    tone: CoreBadgeTone.info,
    variant: CoreBadgeVariant.filled,
    size: CoreComponentSize.xs,
    child: Text('3'),
  ),
  selected: page == 0,
  onPressed: () => setState(() => page = 0),
)
```

<Note label="사이드바 줄은 제거 예고">

`mode` 를 적지 않으면 사이드바 줄로 그립니다. 그 값 `CoreNavigationBarMode.sidebar` 는 0.164 부터 제거가 예고돼 있고, 대신 [Sidebar](/components/sidebar) 를 쓰도록 안내합니다. 새로 만드는 옆 내비게이션은 `Sidebar` 와 그 행 `SidebarItem` 으로 만드세요. 제거되기 전까지 사이드바 줄은 지금처럼 그려지며, 이 값을 코드에 직접 적으면 분석기가 deprecation 경고를 냅니다.

</Note>

<a id="구조-anatomy"></a>

## 구조

사이드바 줄은 아이콘과 이름이 앞(글이 시작하는 쪽)에, 배지가 줄 끝에 놓입니다. 바 · 레일 모양(`mode: bar` · `rail`)은 이름을 아이콘 아래에 쌓고, 배지를 아이콘의 끝 쪽 위 모서리에 겁니다.

<Anatomy demo="navigation-bar-item/anatomy">
<AnatomyItem select="[role=button]" side="left" name="Container">

선택 · hover · 포커스 · 눌림 색을 칠하는 칸입니다. 모서리는 `itemRadius`(기본 10), 높이는 내용과 `itemMinHeight` 가 정합니다.

</AnatomyItem>
<AnatomyItem part="leading" side="top" name="icon">

목적지의 그림입니다. 없으면 이름만 그립니다. 아이콘에 크기와 색을 직접 주지 않으면 항목이 크기(사이드바 20, 바 · 레일 24)와 상태에 맞는 색을 내려 줍니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="label">

목적지의 이름이자 접근성 이름입니다. 한 줄로만 그립니다. `labelMode` 로 숨겨도 이름과 말풍선으로 남습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=badge]" side="right" name="badge">

개수 같은 표시를 위젯으로 받습니다. 스크린 리더는 이름 뒤에 이어 읽습니다.

</AnatomyItem>
</Anatomy>

Figma: [`❖ NavigationBarItem`](https://www.figma.com/design/9FgsLhiWz0aLsVqcoI6nYJ/CoUI---Cocode-Design-System-v1.0)

### Figma 속성 대응

Figma 세트의 축과 속성이 코드의 어느 값인지입니다. 이름이 다른 곳은 그대로 적어 둡니다. Figma 쪽 이름은 디자이너가 정한 이름이라 코드가 바꾸지 않습니다.

| Figma | 코드 | 비고 |
| --- | --- | --- |
| `Label` (텍스트) | `label` | |
| `Icon` (인스턴스 교체) | `icon` | |
| `Show icon` | `icon` 이 있는가 | 끄면 이름만 있는 목적지 |
| `Show count` | `badge` | 개수를 끄고 켜는 속성. 코드는 배지 위젯을 받습니다 |
| `Show mark` | `selectionMark: dot` | 이름이 아이콘 아래 · 위로 쌓일 때만 그립니다 |
| `Selected` | `selected` | |
| `State=disabled` | `enabled: false` | |
| `State=hover` · `focus` | — | 포인터와 키보드가 만드는 상태라 속성이 아닙니다 |
| `Show focus ring` | — | 다른 모양 위에 포커스 링을 겹쳐 보는 캔버스 속성입니다 |
| `Label=end` · `bottom` | `labelPosition` | `end` 는 사이드바 줄(`mode: sidebar`), `bottom` 은 바 · 레일 |
| `Label=none` | `labelMode: none` | 이름은 숨겨도 접근성 이름으로 남습니다 |
| `Indicator=fill` · `color` | `indicator` | `fill` 은 칸 전체를 채우는 선택 면, `color` 는 면 없이 색만. `color` 는 `Label=bottom` 에만 있습니다 |
| `Show dot` | `showDot` | 개수 없이 새 소식을 알리는 점. 코드는 `badge` 가 있으면 배지만 그립니다 |

## 모드

`mode` 는 목적지를 그리는 모양을 고릅니다. 값에 따라 이름의 자리, 선택 표시, 크기의 기본값이 함께 바뀌며, `NavigationBar` 가 목적지를 그릴 때와 같은 값입니다.

<Cards columns="3">
<Card component="navigation-bar-item" props="selected=true" label="받은편지함" title="sidebar (기본, 제거 예고)">

아이콘 옆에 이름이 놓이는 줄입니다.

</Card>
<Card component="navigation-bar-item" props="mode=rail;selected=true" label="받은편지함" title="rail">

이름을 아이콘 아래에 쌓고, 선택한 칸 전체를 채웁니다.

</Card>
<Card component="navigation-bar-item" props="mode=bar;selected=true" label="받은편지함" title="bar">

이름을 아이콘 아래에 쌓고, 선택은 색과 굵기로만 알립니다.

</Card>
</Cards>

| 기본값 | `sidebar` | `rail` | `bar` |
| --- | --- | --- | --- |
| 이름 자리 | 아이콘 뒤(`end`) | 아이콘 아래(`bottom`) | 아이콘 아래(`bottom`) |
| 선택 표시 | `fill` | `fill` | `color` |
| 최소 높이 | 40 | 64 (이름을 숨기면 40) | 64 (이름을 숨기면 40) |
| 아이콘 크기 | 20 | 24 | 24 |
| 이름 글자 | `labelLarge` (14) | `labelSmall` (12) | `labelSmall` (12) |
| 안쪽 여백 (위아래 · 좌우) | 10 · 12 | 6 · 4 | 6 · 4 |
| 아이콘과 이름 사이 | 10 | 4 | 4 |
| 상태 색을 섞는 바탕 | `surfaceContainerLow` | `surfaceContainerLow` | `surface` |
| 배지 자리 | 줄 끝 | 아이콘 모서리 | 아이콘 모서리 |
| 말풍선 방향 | 옆(오른쪽) | 옆(오른쪽) | 위 |

이름을 아이콘 위 · 아래에 쌓는 바 · 레일 목적지가 이름을 숨기면, 최소 높이 40 과 함께 최소 폭 64 를 지킵니다(`iconOnlyItemMinHeight` · `iconOnlyItemMinWidth`). 칸이 64 보다 좁으면 칸 폭까지 줄어듭니다. `itemMinHeight` 만 직접 주면 이름을 숨긴 목적지도 그 높이를 따릅니다. 리퀴드 글라스에서는 최소 높이가 48 이고, `rail` 의 최소 폭은 40 입니다.

## 선택 표시

`indicator` 는 지금 있는 곳을 알리는 방법을 고릅니다. 두 방법 모두 고른 항목의 이름을 `primary` 색 Bold 로, 아이콘을 `primary` 색으로 바꿉니다. 적지 않으면 `bar` 는 `color`, `rail` 과 `sidebar` 는 `fill` 입니다.

<Cards columns="3">
<Card component="navigation-bar-item" props="mode=rail;indicator=fill;selected=true" label="받은편지함" title="fill">

칸 전체를 `surfaceContainerHigh` 로 채웁니다. hover 색이 켜지는 상자와 같은 모양입니다.

</Card>
<Card component="navigation-bar-item" props="mode=rail;indicator=color;selected=true" label="받은편지함" title="color">

면 없이 색과 굵기만 씁니다. 고르지 않은 항목에 마우스를 올리면 면 대신 이름과 아이콘이 `onSurface` 로 진해집니다.

</Card>
<Card component="navigation-bar-item" props="mode=bar;selectionMark=dot;selected=true" label="받은편지함" title="selectionMark: dot">

내용 위에 작은 점을 더합니다. 고르지 않은 항목도 점 자리를 비워 두어 이름 높이가 맞습니다.

</Card>
</Cards>

- `selectionMark: CoreNavigationSelectionMark.dot` 은 이름이 아이콘 아래나 위에 쌓일 때만 점을 그립니다. 한 줄 배치(`end` · `start`)에는 그리지 않습니다.
- 점은 지름 4 이고 아래 내용과 6 떨어집니다. 색은 `color` 에서 `primary`, `fill` 에서 `onSurface` 입니다. 선택이 바뀌면 `duration`(기본 150ms) 동안 나타나거나 사라집니다.

## 배지와 알림 점

`badge` 는 위젯 슬롯이라 배지의 색과 모양은 넘기는 `Badge` 가 정합니다. 아래 그림과 위 코드의 개수 배지는 `form: CoreBadgeForm.count` · `tone: CoreBadgeTone.info` · `variant: CoreBadgeVariant.filled` · `size: CoreComponentSize.xs` 입니다.

<Cards columns="3">
<Card component="navigation-bar-item" props="badge=3" label="받은편지함" title="줄 끝 배지">

사이드바 줄은 배지를 줄 끝에 둡니다. 이름이 길면 이름이 폭을 내주고 줄어듭니다.

</Card>
<Card component="navigation-bar-item" props="mode=rail;badge=3" label="받은편지함" title="아이콘 모서리 배지">

바 · 레일은 배지를 아이콘의 끝 쪽 위 모서리에 겁니다. 아이콘이 없는 항목은 배지를 이름 뒤 줄 끝에 둡니다.

</Card>
<Card component="navigation-bar-item" props="mode=rail;showDot=true" label="받은편지함" title="showDot">

개수 없이 새 소식만 알리는 `error` 색 점(지름 8)입니다.

</Card>
</Cards>

- 배지의 자리는 `labelPosition` 이 아니라 `mode` 가 정합니다. 레일 항목의 이름을 옆에 놓아도 배지는 아이콘 모서리에 남습니다.
- `showDot` 은 `badge` 가 있으면 그리지 않고(배지가 이깁니다), 아이콘이 없으면 걸 곳이 없어 그리지 않습니다.

## 이름 표시

이름은 `labelMode`(보이는 때), `labelPosition`(자리), `overflow`(긴 이름)가 정합니다.

### 보이는 때

| `labelMode` | 이름 |
| --- | --- |
| `all` | 늘 보입니다. 세 모드의 기본값입니다 |
| `selected` | 선택한 동안만 보입니다. 비활성 항목도 `selected: true` 면 보입니다 |
| `none` | 숨깁니다. 접근성 이름과 말풍선으로는 남습니다 |

리퀴드 글라스 서페이스 스타일에서 `rail` 모양의 항목은 기본값이 `none` 입니다. `labelMode` 를 적으면 적은 값을 따릅니다.

### 이름 자리

`bottom` · `top` 은 이름을 아이콘 아래 · 위에 쌓고, `end` · `start` 는 아이콘 뒤 · 앞에 한 줄로 놓습니다. 적지 않으면 `sidebar` 는 `end`, 바와 레일은 `bottom` 입니다.

<Preview demo="navigation-bar-item/label-positions" />

### 긴 이름

이름은 늘 한 줄입니다. 아래 그림의 윗줄은 기본값 `ellipsis`(말줄임표), 아랫줄은 `clip` 입니다. `clip` 과 `none` 은 두 플랫폼에서 다르게 보입니다.

| `overflow` | Flutter | Jaspr Web |
| --- | --- | --- |
| `clip` | 줄을 바꿀 수 있는 자리까지의 첫 줄만 보입니다. | 이름 자리의 끝에서 자릅니다. 글자 중간에서 잘릴 수 있습니다. |
| `none` | 자르는 처리는 하지 않지만, `clip` 처럼 첫 줄만 그리고 나머지 글자는 보이지 않습니다. | 이름이 칸 밖으로 넘칠 수 있습니다. |

<Preview demo="navigation-bar-item/long-label" />

### 말풍선

이름이 보이지 않을 때 마우스를 올리면 말풍선이 뜹니다. 글은 `tooltip`, 없으면 `label` 입니다. 이름이 보이는 동안에는 `tooltip` 을 쓰지 않습니다. `rail` · `sidebar` 는 옆(오른쪽, 자리가 없으면 반대쪽)에, `bar` 는 위에 뜹니다.

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 상태

<Preview demo="navigation-bar-item/states" />

그림의 왼쪽은 사이드바 줄(`fill`), 오른쪽은 바 목적지(`color`)입니다. hover · 포커스 · 눌림은 포인터나 키보드로 만드는 상태라 플레이그라운드에서 확인합니다. 아래 표의 "바탕색에 섞은 색"은 [`navigationBarStyle`](#navigationbarstyle) 절의 바탕색에 `onSurface` 를 그 비율만큼 섞은 색입니다.

| 상태 | 칸 | 이름 · 아이콘 |
| --- | --- | --- |
| 기본 | 칠하지 않음 | `onSurfaceSubtle`, 이름 Medium |
| hover · 포커스 · 눌림 (`fill`) | 바탕색에 3% · 8% · 8% 섞은 색 | 기본과 같음 |
| hover · 포커스 · 눌림 (`color`) | hover 는 바탕색 그대로(0%), 포커스 · 눌림은 8% 섞은 색 | hover 는 `onSurface` |
| 선택 (`fill`) | `surfaceContainerHigh`. hover · 포커스 · 눌림은 이 색에 3% · 8% · 8% 를 더 섞습니다 | `primary`, 이름 Bold |
| 선택 (`color`) | 칠하지 않음. 포커스 · 눌림은 바탕색에 8% 섞은 색 | `primary`, 이름 Bold |
| 비활성 | 칠하지 않음 | `disabledContent`. 따로 흐려지지 않습니다 |
| 선택 · 비활성 (`fill`) | `disabledContainer` | `disabledContent`, 이름 Bold |
| 선택 · 비활성 (`color`) | 칠하지 않음 | `disabledContent`, 이름 Bold |

### 활성과 누르기

- `enabled` 를 적지 않으면 `onPressed` 가 있을 때만 활성입니다(`enabled ?? onPressed != null`). 클릭, 탭, 그리고 포커스를 가진 상태의 `Enter` · `Space` 가 `onPressed` 를 부릅니다.
- 누르는 동안 항목이 97% 크기로 살짝 작아집니다. 활성 항목의 커서는 손 모양, 비활성 항목은 금지 모양입니다.
- 비활성 항목은 눌리지 않고 hover 색도 받지 않습니다. 선택돼 있으면 지금 있는 곳을 흐린 선택 표시로 남기지만, 보조 기술에는 선택으로 알리지 않습니다.
- `enabled: true` 를 주고 `onPressed` 를 비우면 활성 모양으로 그리지만 눌리지 않고, 보조 기술에는 비활성으로 알립니다. 커서는 금지 모양입니다. 이때도 Jaspr Web 은 마우스를 올리거나 누를 때의 상태 색을 칠하고, Flutter 는 칠하지 않습니다. 활성 항목에는 `onPressed` 를 함께 주세요.
- 이름을 아이콘 위 · 아래에 쌓은 목적지는 칠한 크기와 상관없이 가로 · 세로 최소 48(`touchTargetSize`)에서 탭을 받습니다. 누르는 영역만 넓어지고 배치는 그대로입니다. 한 줄 배치는 칠한 상자가 누르는 영역입니다.

### 상태 전환

칸의 색과 선택 점은 `duration`(기본 150ms) 동안 바뀝니다. 동작 줄이기 설정에서는 바로 바뀝니다. Flutter 의 리퀴드 글라스 알약은 `duration` 을 적지 않으면 스프링이 멎는 시간을 씁니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 언제 쓰나

- `NavigationBar` 에 맞지 않는 배치로 바 · 레일 목적지를 직접 조립할 때. 앱만의 레일이나 화면 한쪽의 목적지 몇 개가 그렇습니다.
- `Drawer` 안의 사이드바나 설정 화면의 목록처럼, 지금 보는 곳을 표시하는 줄을 이 항목으로 둘 때. 항목을 손으로 그리지 않고 이 위젯을 놓습니다. 다만 `mode` 기본값인 사이드바 줄은 제거가 예고돼 있으니 새 옆 내비게이션은 `Sidebar` 를 먼저 고릅니다.
- 앱이 목록의 구조를 직접 짜면서 목적지의 상태 · 선택 표시 · 접근성은 바와 똑같이 받고 싶을 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 목적지 목록을 데이터로 넘겨 바 · 레일을 통째로 그릴 때(구획 이름 · 구분선 · 아래 칸 · 리퀴드 글라스의 움직이는 선택 렌즈까지) | [NavigationBar](/components/navigation-bar) |
| 신원 · 검색 · 구획 · 접는 묶음 · 계정이 있는 옆 내비게이션 | [Sidebar](/components/sidebar) |
| 메뉴 패널 안의 동작 한 줄. 장소가 아니라 명령일 때 | [MenuItem](/components/menu-item) |
| 같은 화면 안에서 보여 줄 보기만 바꿀 때 | [Tabs](/components/tabs) |

<a id="do"></a>
<a id="dont"></a>

### 선택과 이름

<Cards columns="2">
<Card demo="navigation-bar-item/do-one-selected" tone="do" eyebrow="이렇게 하세요">

지금 있는 곳 하나만 선택합니다. 화면의 상태 하나에서 모든 항목의 `selected` 를 계산하세요.

</Card>
<Card demo="navigation-bar-item/dont-two-selected" tone="dont" eyebrow="이렇게 하지 마세요">

두 곳을 함께 선택해 보이면 지금 어디에 있는지 알 수 없습니다.

</Card>
</Cards>

<Cards columns="2">
<Card tone="do" eyebrow="이렇게 하세요" title="아이콘만 보여도 이름은 채웁니다">

```dart
NavigationBarItem(
  icon: const Icon(LucideIcons.settings),
  label: '설정',
  labelMode:
      CoreNavigationLabelMode.none,
  onPressed: openSettings,
)
```

숨긴 이름이 스크린 리더가 읽는 이름이자 말풍선 글이 됩니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요" title="줄을 손으로 그리지 않습니다">

```dart
// 면 · 상태 · 이름 · 배지를
// 직접 조립한 줄
Clickable(
  onPressed: openInbox,
  child: handMadeInboxRow,
)
```

손으로 그린 줄은 바의 스타일 · 상태 색 · 선택 표시 · 접근성 이름을 받지 못하고, 바가 바뀔 때 따라오지 않습니다.

</Card>
</Cards>

## 배치

### 목록으로 쌓기

줄은 받은 폭을 채우고, 높이는 내용과 최소 높이만큼입니다. 남는 높이를 채우지 않습니다. 여러 줄은 `Column`(Jaspr Web 은 세로 flex `div`)으로 쌓습니다. `NavigationBar` 가 사이드바 줄 사이에 두는 간격은 `CoreSpace.space2` 입니다.

<Preview demo="navigation-bar-item/column" />

### 직접 조립한 레일

`mode: CoreNavigationBarMode.rail` 을 주면 레일 목적지가 됩니다. `NavigationBar` 의 레일은 목적지 사이를 `CoreSpace.space8` 만큼 띄웁니다. 레일의 바탕색(`surfaceContainerLow`) 위에 놓아야 hover 색이 바탕과 어울립니다.

<Preview demo="navigation-bar-item/rail-column" />

<a id="조합-예제"></a>

### 서랍 안의 목록

`Drawer` 의 내용에 항목을 쌓고, 줄을 고르면 화면을 바꾼 뒤 서랍을 닫습니다.

<Preview component="navigation-bar-item" example="drawer" />

<Note>

문서 사이트의 이 미리보기는 서버가 그린 화면이라 버튼을 눌러도 서랍이 열리지 않습니다. 아래 코드를 앱에 옮기면 서랍이 열립니다.

</Note>

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
openDrawer<void>(
  context: context,
  side: CoreDrawerSide.left,
  builder: (drawerContext) => Drawer(
    title: '워크스페이스',
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CoreSpace.space2,
      children: [
        NavigationBarItem(
          icon: const Icon(LucideIcons.house),
          label: '홈',
          selected: page == 0,
          onPressed: () {
            openPage(0);
            closeDrawer<void>(drawerContext);
          },
        ),
      ],
    ),
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
openDrawer<void>(
  context: context,
  side: CoreDrawerSide.left,
  builder: (close) => Drawer(
    title: '워크스페이스',
    content: div(
      [
        NavigationBarItem(
          icon: const Icon(LucideIcons.house),
          label: '홈',
          selected: page == 0,
          onPressed: () {
            openPage(0);
            close();
          },
        ),
      ],
      classes: 'flex flex-col gap-${CoreSpace.scale.space2}',
    ),
  ),
)
```

  </TabItem>
</Tabs>

### 폭이 정해지지 않은 자리

Flutter 에서 `Row` 처럼 폭이 열린 자리에 놓으면 항목은 내용 폭이 되고, 줄 끝 배지는 이름 바로 뒤에 붙습니다. Jaspr Web 의 폭 규칙은 [플랫폼 차이](#플랫폼-차이) 를 보세요.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

항목에는 자기 스타일 클래스가 없습니다. 겉모습은 바의 `CoreNavigationBarStyle` 하나가 정하고, 항목은 그 가운데 항목에 관한 필드를 `mode` 의 기본값 위에 읽습니다. 무엇을 보여 줄지(`icon` · `label` · `badge` · `selected` · `enabled`)와 어떤 모양을 고를지(`mode` · `indicator` · `labelMode` 등)는 위젯 파라미터로 줍니다.

<Split>

<Code language="dart" title="항목 하나만 바꾸기">
NavigationBarItem(
  icon: Icon(LucideIcons.inbox),
  label: '받은편지함',
  selected: true,
  onPressed: openInbox,
  navigationBarStyle: CoreNavigationBarStyle(
    selectedBackgroundColor: CoreColor.token(
      CoreColors.primaryContainer,
    ),
    itemRadius: CoreBorderRadius.all(
      CoreRadiusRole.panel,
    ),
    // 포커스 링의 모서리도 맞춥니다.
    clickableStyle: CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(
        CoreRadiusRole.panel,
      ),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    navigationBar: CoreNavigationBarTheme(
      style: CoreNavigationBarStyle(
        itemRadius: CoreBorderRadius.all(
          CoreRadiusRole.panel,
        ),
        clickableStyle: CoreClickableStyle(
          borderRadius:
              CoreBorderRadius.all(
            CoreRadiusRole.panel,
          ),
        ),
      ),
    ),
  ),
)
</Code>

</Split>

앱 전체 값은 `NavigationBar` 와 단독 항목에 함께 닿습니다. 바의 테마를 바꾼 앱은 직접 놓은 항목도 같이 바뀝니다.

### `navigationBarStyle`

항목이 읽는 필드는 아래와 같습니다. 필드의 타입과 전체 목록은 [NavigationBar](/components/navigation-bar) 문서에 있습니다.

| 묶음 | 필드 |
| --- | --- |
| 칸 | `itemPadding` · `itemRadius` · `itemMinHeight` · `iconOnlyItemMinHeight` · `iconOnlyItemMinWidth` · `touchTargetSize` |
| 이름 | `labelTextStyle` · `selectedLabelTextStyle` · `disabledLabelTextStyle` · `disabledSelectedLabelTextStyle` · `labelSpacing` |
| 아이콘 | `iconStyle` · `selectedIconStyle` · `disabledIconStyle` · `iconAnchorPadding` |
| 선택 · 상태 색 | `selectedBackgroundColor` · `disabledSelectedBackgroundColor` · `backgroundColor`(상태 색을 섞는 바탕) · `stateLayer` · `stateLayerColor` · `hoverBackgroundColor` · `hoverForegroundColor` |
| 선택 점 | `selectionMarkStyle` · `selectionMarkGapStyle` · `disabledSelectionMarkStyle` |
| 배지 · 알림 점 | `badgeIndicatorStyle` · `notificationDotStyle` · `notificationDotIndicatorStyle` |
| 그 밖 | `clickableStyle`(누름 · 포커스 링 · 커서) · `duration` · `surfaceStyle` |

- 바의 틀에 관한 필드(`padding` · `barRadius` · `barMargin` · `barBorderColor` · `barBorderWidth` · `itemSpacing` · `sectionLabelTextStyle` · `sectionLabelPadding` · `dividerColor` · `dividerThickness` · `compactScale` · `compactDuration`)는 항목 하나에는 보이는 변화를 만들지 않습니다.
- 단독 항목에서 `itemMaxWidth` 는 Jaspr Web 의 `bar` 모양만 읽습니다.
- `selectedIconAnchorColor` · `selectedIconAnchorIconStyle` · `disabledSelectedIconAnchorColor` · `iconAnchorRadius` 는 0.184 부터 deprecated 이고 아무것도 바꾸지 않습니다. 선택한 칸과 아이콘의 색은 `selectedBackgroundColor` · `selectedIconStyle` · `disabledSelectedBackgroundColor` 로, 칸의 모서리는 `itemRadius` 로 바꾸세요.
- 포커스 링의 모서리는 `clickableStyle.borderRadius`(기본 10)를 따릅니다. `itemRadius` 를 바꾸면 이 값도 함께 바꾸세요.

<Note label="상태 색의 바탕">

hover · 포커스 · 눌림 색은 놓인 배경 위에 반투명하게 덮는 색이 아닙니다. `backgroundColor`(적지 않으면 모드의 바탕색, 바는 `surface`, 레일 · 사이드바는 `surfaceContainerLow`)에 `stateLayerColor` 를 섞어 만든 색입니다. 다른 바탕 위에 놓으면 hover 칸이 배경과 다른 색으로 보일 수 있으니 `backgroundColor` 를 그 바탕의 테마 토큰 색으로 맞추세요. Jaspr Web 은 토큰이 아닌 색을 주면 상태 색을 칠하지 않습니다.

</Note>

<Note label="리퀴드 글라스">

리퀴드 글라스 서페이스 스타일에서는 `bar` · `rail` 모양의 단독 항목도 알약 모양(최소 높이 48)과 옅게 어두워지는 선택 면, `color` 선택 표시를 기본으로 받고, `rail` 은 이름을 숨깁니다. 직접 준 값은 이 값보다 우선합니다. 선택을 따라 움직이는 렌즈는 `NavigationBar` 에만 있고, 사이드바 줄의 모양은 바뀌지 않습니다.

</Note>

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 항목에는 `withStyle` 을 이어 씁니다. `navigationBarStyle` 에 합쳐지고, 여러 번 이으면 같은 필드는 뒤의 값이 이깁니다. 아래 예제는 `itemRadius` 만 바꾸므로, 포커스 링까지 맞추려면 위 예제처럼 `clickableStyle` 의 `borderRadius` 도 함께 주세요.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class NavigationBarItemChainExample extends StatelessWidget {
  const NavigationBarItemChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: CoreLayout.layout240),
      child:
          NavigationBarItem(
            icon: const Icon(LucideIcons.inbox),
            label: '받은편지함',
            selected: true,
            onPressed: () {},
          ).withStyle(
            const CoreNavigationBarStyle(
              selectedBackgroundColor: CoreColor.token(CoreColors.primaryContainer),
              itemRadius: CoreBorderRadius.all(CoreRadiusRole.panel),
            ),
          ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class NavigationBarItemChainExample extends StatelessComponent {
  const NavigationBarItemChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        NavigationBarItem(
          icon: const Icon(LucideIcons.inbox),
          label: '받은편지함',
          selected: true,
          onPressed: () {},
        ).withStyle(
          const CoreNavigationBarStyle(
            selectedBackgroundColor: CoreColor.token(
              CoreColors.primaryContainer,
            ),
            itemRadius: CoreBorderRadius.all(CoreRadiusRole.panel),
          ),
        ),
      ],
      classes: 'w-full max-w-${CoreLayout.scale.layout240}',
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
CoreNavigationBarStyle 의 기본값               // 디자인 시스템 (바 · 레일의 값)
  → defaultsByVariant[variant]                 // 바탕색
  → defaultsByMode[mode]                       // 모드의 크기 · 여백 · 글자 · 바탕
  → defaultsByIndicator[indicator]             // 선택 표시
  → 리퀴드 글라스의 알약 값                    // 그 스타일의 바 · 레일만
  → CoreNavigationBarTheme.style               // 앱 전체
  → CoreNavigationBarTheme.variantStyles[variant]
  → navigationBarStyle                         // 항목 하나
```

뒤로 갈수록 우선합니다. `variant` 의 값은 지금 `standard` 하나입니다.

<a id="접근성-accessibility"></a>

## 접근성

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 버튼 하나로 알립니다. `Clickable` 이 버튼 · 활성 · 선택 상태를 알리고, 항목이 이름(`label`)을 더하며 배지의 글을 같은 노드에 합칩니다(`MergeSemantics`). |
| Jaspr Web | `role="button"` 입니다. 활성이면 `tabindex="0"`, 비활성이면 `aria-disabled="true"` 입니다. 이름은 `aria-labelledby`(이름 요소, 배지 요소 순서)로 붙고, 선택하면 `aria-current="page"` 가 붙습니다. |

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` | 활성 항목마다 한 번씩 멈춥니다. | 활성 항목마다 한 번씩 멈춥니다. |
| `Enter` · `Space` | `onPressed` 를 부릅니다. | `onPressed` 를 부릅니다. |

### 스크린 리더

- **이름**: `label` 다음에 배지의 글을 읽습니다. Flutter 는 줄바꿈(`받은편지함\n3`), Jaspr Web 은 공백(`받은편지함 3`)으로 이어집니다. 화면의 이름 글자를 따로 한 번 더 읽지 않고, `labelMode` 로 숨겨도 이름은 같습니다.
- **지금 있는 곳**: Flutter 는 선택 상태, Jaspr Web 은 `aria-current="page"` 로 알립니다.
- **비활성**: Flutter 는 비활성 상태, Jaspr Web 은 `aria-disabled="true"` 로 알립니다. 비활성 항목은 선택돼 있어도 선택을 알리지 않습니다.
- **선택 점과 알림 점**: 장식으로 숨깁니다.
- **이름과 다른 `tooltip`**: 이름을 숨긴 항목에 `label` 과 다른 글을 주면 Flutter 는 도움말로도 알리고, Jaspr Web 은 말풍선을 눈에만 보입니다.
- 선택이 바뀌는 것을 따로 알리는 live region 은 없습니다.

### 포커스 관리

- 항목은 놓일 때 포커스를 옮기지 않고 가두지도 않습니다.
- 비활성 항목은 `Tab` 으로 닿지 않습니다.
- 포커스 링은 `Clickable` 이 그립니다(Flutter `FocusOutline`, Jaspr Web `:focus-visible`). 키보드로 포커스한 동안에는 8% 상태 색도 함께 깔립니다.

### 알려진 제약

- **항목은 화살표 키를 처리하지 않습니다.** 목록 단위의 화살표 이동이 없고, 활성 항목마다 `Tab` 이 멈춥니다. 웹이 아닌 Flutter 앱에서는 앱이 단축키를 바꾸지 않으면 Flutter 기본 단축키가 화살표를 방향에 따른 포커스 이동에 씁니다. Flutter 웹과 Jaspr Web 에서는 이 이동이 없으므로 `Tab` 으로 옮깁니다. 목록 안에서만 도는 화살표 이동이 필요하면 항목을 놓는 쪽이 만들어야 합니다.
- **`label` 이 없으면 버튼에 이름이 없습니다.** 배지가 있으면 배지 글만 이름이 됩니다. `tooltip` 만 줘도 이름이 되지 않습니다. Jaspr Web 은 말풍선을 버튼과 잇지 않고, Flutter 는 말풍선 글을 버튼이 아닌 바깥 노드에 둡니다. 아이콘만 보이게 하려면 `label` 을 채우고 `labelMode: CoreNavigationLabelMode.none` 을 주세요.
- **말풍선은 마우스를 올렸을 때를 위한 것입니다.** 키보드 포커스로는 뜨지 않고, 터치를 위한 동작도 따로 없습니다. Flutter 는 터치로 뜨지 않습니다. Jaspr Web 은 마우스 이벤트만 듣기 때문에, 모바일 브라우저가 탭을 마우스 이벤트로 바꿔 보내면 뜰 수 있습니다.
- **알림 점(`showDot`)은 보조 기술에 전해지지 않습니다.** 새 소식을 읽어 주어야 하면 개수 `badge` 를 쓰세요.
- **주소(href)를 받지 않습니다.** Jaspr Web 에서도 링크가 아니라 버튼이라, 새 탭으로 열기 같은 링크 동작이 없습니다.
- **대비**: 고르지 않은 이름과 아이콘(`onSurfaceSubtle`)은 일부 조합에서 글자 대비 기준 4.5 : 1 에 못 미칩니다. CoUI Light 는 레일 · 사이드바 바탕(`surfaceContainerLow`)에서는 쉬는 상태(4.45 : 1)부터 못 미치고, 바 바탕(`surface`)에서도 포커스 · 눌림 색을 깔면 못 미칩니다. CoUI Dark 는 레일 · 사이드바 바탕에서 포커스 · 눌림 색을 깔면 못 미칩니다. 이 색의 조합은 모두 3 : 1 이상이고, 고대비에서는 4.5 : 1 을 지킵니다. 디자이너가 받아들인 예외로 대비 검사에 올라 있습니다.

> 동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 영역처럼 모든 컴포넌트에 걸친 내용은 [접근성](/accessibility) 페이지가 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

두 생성자의 파라미터 이름 · 순서 · 기본값은 같고, Jaspr Web 은 HTML 용 파라미터를 더 받습니다. 그리는 방식과 몇 가지 동작은 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 슬롯 타입 | `Widget` | `Component` |
| Web 전용 파라미터 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` 를 버튼 역할을 하는 바깥 요소에 붙입니다. `id` 는 이름 · 배지 요소 id 의 앞부분이 됩니다. |
| 선택 알림 | 선택 상태 | `aria-current="page"` |
| 이름과 배지 | 한 노드에서 줄바꿈으로 이음 | `aria-labelledby` 로 공백을 두고 이음 |
| 이름과 다른 `tooltip` | 보조 기술에도 알림 | 눈에 보이는 말풍선만 |
| 상태 색 | 위젯이 상태별 색을 고름 | 범위를 좁힌 `<style>` 규칙(`:hover` · `:focus-visible` · `:active`). 단독 항목은 자기 규칙을 두고, 바 안에서는 바가 한 번 씁니다. |
| `hoverBackgroundColor` | 고르지 않은 항목의 hover · 포커스 · 눌림에 이 색을 칠하고, 고른 항목의 상태 색은 없앱니다. | 고르지 않은 항목의 hover 에만 칠합니다. 테마 토큰 색을 주면 고른 항목을 포함해 상태 색이 모두 없어집니다. |
| 토큰이 아닌 `backgroundColor` · `stateLayerColor` (고른 항목은 `selectedBackgroundColor` 도) | 그 색으로 상태 색을 만듭니다. | 상태 색을 칠하지 않습니다. |
| `color` 표시에서 마우스를 올린 채 누르거나 포커스 | 이름은 기본 색으로 돌아가고 아이콘은 `onSurface` 로 남음 | 이름과 아이콘 모두 `onSurface` |
| `enabled: true` 인데 `onPressed` 가 없음 | 마우스를 올리거나 눌러도 상태 색 없음 | 마우스를 올리거나 누르면 상태 색을 칠함 |
| 긴 이름의 `overflow: clip` | 줄을 바꿀 수 있는 자리까지의 첫 줄만 보임 | 이름 자리의 끝에서 자름 |
| 긴 이름의 `overflow: none` | 첫 줄만 그리고 나머지는 보이지 않음 | 칸 밖으로 넘칠 수 있음 |
| 터치 브라우저에서의 말풍선 | 터치로 뜨지 않음 | 브라우저가 탭을 마우스 이벤트로 바꾸면 뜰 수 있음 |
| `bar` 모양 단독 항목의 폭 | 부모가 준 폭을 채움. `Row` 처럼 폭이 열린 자리에서는 내용 폭 | 블록 안에서는 내용 폭, flex 안에서는 늘어남. 최대 `itemMaxWidth`(기본 96) |
| `rail` · `sidebar` 모양의 폭 | 부모가 준 폭을 채움. `Row` 처럼 폭이 열린 자리에서는 내용 폭 | 부모 폭(`w-full`) |

<a id="props-parameters"></a>

## API

`W` 는 위젯 슬롯의 타입입니다. Flutter 는 `Widget`, Jaspr Web 은 `Component` 입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `icon` | `W?` | `null` | 이름 앞의 아이콘. 없으면 이름만 그립니다. |
| `label` | `String?` | `null` | 목적지 이름. 숨겨도 접근성 이름과 말풍선 글로 남습니다. |
| `badge` | `W?` | `null` | 개수 같은 표시. `sidebar` 는 줄 끝, 바 · 레일은 아이콘 모서리(아이콘이 없으면 줄 끝)에 놓습니다. |
| `tooltip` | `String?` | `null` | 이름이 보이지 않을 때 마우스를 올리면 뜨는 글. 없으면 `label` 입니다. |
| `selected` | `bool` | `false` | 지금 있는 곳인지. 비활성이면 흐린 선택 표시만 남깁니다. |
| `enabled` | `bool?` | `null` | 활성 여부. `null` 이면 `onPressed` 가 있을 때만 활성입니다. |
| `onPressed` | `void Function()?` | `null` | 클릭 · 탭, 포커스한 상태의 `Enter` · `Space` 에 부릅니다. |
| `mode` | `CoreNavigationBarMode` | `CoreNavigationBarItemContract.defaultMode` (`sidebar`) | `bar` · `rail` · `sidebar`(제거 예고). 이름 자리 · 선택 표시 · 크기의 기본값을 함께 고릅니다. |
| `variant` | `CoreNavigationBarVariant` | `standard` | 바의 겉모습 종류. 값은 하나입니다. |
| `labelMode` | `CoreNavigationLabelMode?` | `null` | `all` · `selected` · `none`. `null` 이면 `all` 이고, 리퀴드 글라스의 `rail` 만 `none` 입니다. |
| `labelPosition` | `CoreNavigationLabelPosition?` | `null` | `bottom` · `top` · `end` · `start`. `null` 이면 `sidebar` 는 `end`, 나머지는 `bottom` 입니다. |
| `overflow` | `CoreNavigationOverflow` | `ellipsis` | 남은 폭보다 긴 이름의 처리. `clip` · `ellipsis` · `none` |
| `selectionMark` | `CoreNavigationSelectionMark` | `none` | `dot` 이면 선택을 알리는 점을 더합니다. 이름을 쌓을 때만 그립니다. |
| `indicator` | `CoreNavigationSelectionIndicator?` | `null` | `fill` · `color`. `null` 이면 `bar` 는 `color`, 나머지는 `fill` 입니다(리퀴드 글라스의 바 · 레일은 `color`). |
| `showDot` | `bool` | `false` | 아이콘 모서리의 알림 점. `badge` 가 있거나 아이콘이 없으면 그리지 않습니다. |
| `navigationBarStyle` | `CoreNavigationBarStyle?` | `null` | 바의 스타일. 항목에 관한 필드를 읽습니다. |

Jaspr Web 은 `id` · `classes` · `css` · `attributes` · `eventHandlers` 도 받습니다. 두 플랫폼 모두 `copyWith` 와 `withStyle(CoreNavigationBarStyle patch)` 로 일부를 바꾼 복사본을 만듭니다.

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="NavigationBar" href="/components/navigation-bar" more="NavigationBar 보기">

목적지 목록을 받아 바 · 레일을 통째로 그립니다. 목적지마다 이 위젯을 씁니다.

</Card>
<Card title="Sidebar" href="/components/sidebar" more="Sidebar 보기">

신원 · 검색 · 구획 · 접는 묶음을 갖춘 옆 내비게이션입니다.

</Card>
<Card title="Drawer" href="/components/drawer" more="Drawer 보기">

화면 가장자리에서 여는 패널입니다. 목적지 목록을 담을 수 있습니다.

</Card>
</Cards>

`badge` 에 넣는 개수 표시는 [Badge](/components/badge) 문서를 보세요.
