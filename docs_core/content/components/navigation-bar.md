---
title: NavigationBar
description: 가로 바 / 세로 레일 / 사이드바 세 가지 모드를 지원하는 통합 네비게이션 컨테이너 컴포넌트
category: navigation
platforms: [flutter, web]
related: [navigation-bar-item, navigation-menu, tabs]
tags: [navigation-bar, navigation-rail, sidebar, navigation]
template: v2
source: navigation/navigation_bar
---

# NavigationBar

`NavigationBar`는 주요 섹션 간 이동을 위한 통합 네비게이션 컨테이너입니다. `mode` 한 가지로 가로 바(`bar`)와 세로 레일(`rail`)을 고르고, 목적지는 `CoreNavigationBarItem` 목록 하나로 만듭니다.

> `sidebar` 모드는 0.164 부터 예고(`@Deprecated`)되어 있습니다. 앱의 옆 내비게이션은 헤더 · 검색 · 구역 · 그룹 · 레일을 갖춘 [Sidebar](/components/sidebar)를 쓰세요. 예고 기간 동안 `sidebar` 모드는 지금처럼 그려집니다.

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 가로 바와 레일을 확인하고, 만들어진 코드를 그대로 복사하세요. 목적지를 누르면 선택이 옮겨 갑니다.

<Playground component="navigation-bar" />

<Note>

하단 바의 바탕 `surface`는 웹 문서의 미리보기 바탕과 같아, 바의 경계는 위쪽 선으로만 보입니다. 레일의 바탕 `surfaceContainerLow`도 그 바탕과 비슷해 경계가 옅게 보일 수 있습니다.

</Note>

`NavigationBar`는 선택을 스스로 기억하지 않습니다. 지금 선택된 목적지의 번호를 `selectedIndex`로 넘기고, `onSelected`가 알려 주는 새 번호로 바꿔 다시 그립니다. 번호는 0부터 시작하고 `CoreNavigationBarItem.destination` 항목만 셉니다. 비활성 목적지도 셉니다.

```dart
NavigationBar(
  selectedIndex: index,
  onSelected: (value) => setState(() => index = value),
  items: const [
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.house),
      label: '홈',
    ),
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.search),
      label: '검색',
    ),
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.user),
      label: '프로필',
    ),
  ],
)
```

## 구조

<Anatomy demo="navigation-bar/anatomy">
<AnatomyItem part="container" name="container">

바 전체. 바탕과 안쪽 여백을 갖고, 화면 끝에 붙은 바는 콘텐츠를 향한 한 변에 선을 긋습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=header]" side="top" name="header">

목적지 앞에 두는 내용(앱 로고 등). 선택 사항입니다.

</AnatomyItem>
<AnatomyItem select="[data-coui-nav-index='0'] svg" side="top" name="icon">

목적지의 아이콘(`icon`). 선택 사항입니다.

</AnatomyItem>
<AnatomyItem select="[data-coui-nav-index='0'] [id$=label]" side="right" name="label">

목적지 이름(`label`). 화면에서 숨겨도 접근 가능한 이름으로 남습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=badge]" side="top" name="badge">

개수 같은 표시(`badge`). 바와 레일은 아이콘의 오른쪽 위 모서리에 놓습니다. 오른쪽에서 왼쪽으로 쓰는 언어에서도 오른쪽입니다.

</AnatomyItem>
<AnatomyItem select="[data-coui-nav-index='2']" side="top" name="destination">

목적지 하나. 눌리는 영역이며, 공개 위젯 [`NavigationBarItem`](/components/navigation-bar-item)으로 그립니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=footer]" side="right" name="footer">

목적지 뒤에 두는 내용(계정 · 요금제 카드 등). 선택 사항입니다.

</AnatomyItem>
</Anatomy>

목적지 하나는 공개 위젯 [`NavigationBarItem`](/components/navigation-bar-item)으로 그립니다. 바가 목적지마다 그 위젯을 놓으므로, 바 밖에서(`Drawer` 안의 목록 등) 직접 놓을 때도 같은 `mode`를 주면 바의 목적지와 같은 모양입니다. `mode`를 주지 않으면 `NavigationBarItem`의 기본값인 `sidebar` 밀도의 행으로 그립니다. 목록에는 목적지 말고도 구획 제목(`CoreNavigationBarItem.label`) · 구분선(`divider`) · 빈 간격(`gap`)을 섞을 수 있습니다.

<a id="모드-modes"></a>
<a id="bar"></a>
<a id="rail"></a>

## 형태

`mode`가 목적지를 놓는 방향과 밀도를 정합니다. 기본값은 `bar`입니다.

<VariantRow name="bar" component="navigation-bar" props="mode=bar">

가로 바. 모바일 앱 아래쪽의 주요 섹션 이동에 맞습니다. 목적지가 바의 폭을 같은 몫으로 나눠 갖고, 한 칸은 96에서 더 넓어지지 않습니다.

</VariantRow>
<VariantRow name="rail" component="navigation-bar" props="mode=rail">

세로 레일. 화면 옆의 좁은 내비게이션에 맞습니다. 리퀴드 글래스에서는 아이콘만 세운 떠 있는 캡슐이 됩니다 — [리퀴드 글래스의 바와 레일](#리퀴드-글래스의-바와-레일)을 보세요.

</VariantRow>

<a id="sidebar"></a>

### `sidebar` 모드

<Note>

`CoreNavigationBarMode.sidebar`는 0.164 부터 예고(`@Deprecated`)되었습니다. 새 화면의 옆 내비게이션은 [Sidebar](/components/sidebar)로 만드세요. 예고 기간 동안에는 지금처럼 그려집니다.

</Note>

확장 세로 사이드바 모양입니다. 구획 제목과 구분선으로 계층을 나타냅니다.

<Preview component="navigation-bar" example="sidebar" />

```dart
NavigationBar(
  mode: CoreNavigationBarMode.sidebar,
  selectedIndex: index,
  onSelected: (value) => setState(() => index = value),
  items: const [
    CoreNavigationBarItem.label('메인'),
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.house),
      label: '대시보드',
    ),
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.search),
      label: '탐색',
    ),
    CoreNavigationBarItem.divider(),
    CoreNavigationBarItem.label('계정'),
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.bell),
      label: '알림',
      badge: Badge(
        form: CoreBadgeForm.count,
        tone: CoreBadgeTone.info,
        variant: CoreBadgeVariant.filled,
        size: CoreComponentSize.xs,
        child: Text('3'),
      ),
    ),
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.settings),
      label: '설정',
    ),
  ],
  footer: const Text('무료 플랜 · 좌석 5개 중 3개 사용').labelMedium.onSurfaceVariant,
)
```

<a id="모드별-밀도-density-per-mode"></a>

## 모드별 밀도

하단 바와 사이드바는 같은 컴포넌트의 다른 밀도입니다. 바와 레일은 아이콘 아래에 12px 라벨을 둔 64 높이 칸을, 사이드바는 20px 아이콘과 14px 라벨을 나란히 놓은 40 높이 행을 그립니다. 모드마다 다른 값은 `CoreNavigationBarStyle.defaultsByMode`가 정하고, 모드가 정하지 않은 값은 `CoreNavigationBarStyle`의 `default*` 값(바 · 레일의 값)을 씁니다.

| 항목 | bar | rail | sidebar (예고) |
| --- | --- | --- | --- |
| 바 안쪽 여백 | 세로 8 · 가로 12 (+ 아래 안전 영역) | 8 | 세로 16 · 가로 12 |
| 바탕색 | `surface` | `surfaceContainerLow` | `surfaceContainerLow` |
| 항목 사이 | 0 | 8 | 2 |
| 항목 최소 높이 | 64 (라벨을 숨기면 40) | 64 (라벨을 숨기면 40) | 40 |
| 항목 최대 폭 (`itemMaxWidth`) | 96 | 없음 | 없음 |
| 항목 안쪽 여백 | 세로 6 · 가로 4 | 세로 6 · 가로 4 | 세로 10 · 가로 12 |
| 항목 모서리 | 10 | 10 | 10 |
| 아이콘 | 24 (48×28 상자 안) | 24 (48×28 상자 안) | 20 |
| 아이콘 ↔ 라벨 | 4 | 4 | 10 |
| 라벨 글자 | `labelSmall` | `labelSmall` | `labelLarge` |
| 라벨 표시 (`labelMode`) | `all` | `all` | `all` |
| 선택 표시 (`indicator`) | `color` | `fill` | `fill` |

하단 바의 목적지는 바의 폭을 똑같이 나눠 갖되 96에서 더 넓어지지 않습니다(`itemMaxWidth`). 휴대폰 폭(360에 목적지 넷이면 하나에 84)에서는 몫이 96보다 작아 바를 끝까지 채우고, 태블릿처럼 넓은 바에서는 목적지가 96에서 멈추고 남는 폭이 `alignment`(기본 `center`)에 따라 놓입니다. 레일과 사이드바는 목적지가 자기 열의 폭을 따르므로 상한이 없고, 리퀴드 글래스 캡슐도 상한을 두지 않습니다 — 움직이는 렌즈가 목적지를 줄 전체를 똑같이 나눈 칸으로 재기 때문입니다. 상한을 없애려면 `CoreNavigationBarStyle(itemMaxWidth: double.infinity)`를 줍니다.

바탕색은 레일과 사이드바가 `surfaceContainerLow`이고, 하단 바는 `surface`입니다. 하단 바는 콘텐츠 아래에 붙어 위쪽 선으로 갈리므로, 홈 인디케이터 밑까지 다른 색을 깔지 않습니다. 선은 콘텐츠를 향한 한 변에만 긋습니다 — 하단 바는 위쪽, 레일과 사이드바는 끝(LTR에서 오른쪽) 변입니다.

구획 제목은 `labelSmall` 600에 `onSurfaceSubtle`을 씁니다. 구획 제목은 목적지의 항목 여백을 빌리지 않고 자기 여백(`sectionLabelPadding` — 위 18 · 아래 6 · 좌우 10)을 갖습니다. 위 여백이 아래보다 커야 구획이 갈립니다.

## 상태

선택은 `fill`과 `color` 어느 표시에서든 라벨 굵기(700, 나머지는 500)로 알리고, 그 위에 [선택 표시](#선택-표시)가 정한 모양을 더합니다.

<Preview demo="navigation-bar/states" />

| 상태 | 모습 |
| --- | --- |
| 기본 | 아이콘 · 라벨 `onSurfaceSubtle` |
| 선택 | 아이콘 · 라벨 `primary`, 라벨 700. `fill`은 타일 전체에 `surfaceContainerHigh`를 칠합니다 |
| hover | `fill`은 `onSurface` 상태 레이어 3%를 덮습니다. `color`는 레이어 없이 아이콘 · 라벨을 `onSurface`로 진하게 합니다 |
| 포커스 · 눌림 | `onSurface` 상태 레이어 8%. 키보드 포커스에는 포커스 링이 함께 나타납니다 |
| 비활성 | 아이콘 · 라벨 `disabledContent`. 라벨 글자는 `labelTextStyle`이 아니라 `disabledLabelTextStyle`에서 오므로, 평소 라벨에 준 글자 스타일은 비활성 라벨에 닿지 않습니다 |
| 선택 + 비활성 | `fill`은 타일 `disabledContainer`, `color`는 면 없음. 라벨은 `disabledContent` 700, 선택 점은 `disabledContent`입니다. 보조 기술에는 선택을 알리지 않습니다. 렌즈가 움직이는 리퀴드 글래스에서는 다릅니다([알려진 제약](#알려진-제약)) |

선택된 목적지도 hover · 포커스 · 눌림에서는 자기 표시 위에 같은 상태 레이어를 받습니다. 렌즈가 움직이는 리퀴드 글래스의 바와 레일은 다릅니다. Web은 어느 목적지에도 hover · 포커스 · 눌림 색을 덮지 않고, 키보드 포커스에는 포커스 링만 남습니다. Flutter는 선택된 목적지에 덮지 않고, 누르고 있거나 렌즈가 옮겨 가는 동안에는 다른 목적지에도 덮지 않습니다. 선택된 비활성 목적지의 면 · 글자 · 점은 `disabledSelectedBackgroundColor` · `disabledSelectedLabelTextStyle` · `disabledSelectionMarkStyle`로 바꿉니다.

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

### 선택과 입력

- 목적지를 누르면 그 목적지의 번호로 `onSelected(index)`를 부릅니다. 번호는 목적지만 셉니다.
- 포커스한 목적지는 `Enter` · `Space`로 누릅니다.
- 라벨을 숨긴 목적지에 포인터를 올리면 이름이 툴팁으로 뜹니다. 가로 바에서는 목적지 위에, 세로로 세운 레일에서는 옆에 뜹니다 — 위에 뜨면 바로 위 목적지를 가리기 때문입니다. 레일의 툴팁은 오른쪽으로 열리고, 자리가 없으면(레일이 화면 오른쪽 끝에 선 경우) 왼쪽으로 열립니다.

<a id="애니메이션"></a>

### 전환 시간

- 목적지의 타일 바탕과 선택 점은 `duration`(기본 150ms) 동안 ease-in-out으로 바뀝니다. 리퀴드 글래스의 바와 레일에서 `duration`을 주지 않으면, Flutter는 렌즈의 움직임과는 별개인 스프링이 가라앉는 시간(약 0.95초) 동안 바꿉니다.
- 라벨 · 아이콘 색은 `duration`을 따르지 않습니다. Flutter는 바로 바뀝니다. Web은 앱의 테마 전환 설정(`CoUIWeb`의 `enableThemeAnimation`, 기본 켜짐)에 따라 150ms 동안 바뀌고, 이 설정을 끄면 바로 바뀝니다.
- 동작 줄이기 설정에서는 바로 바뀝니다.

<a id="선택-표시-selection-indicator"></a>

## 선택 표시

선택된 목적지를 어떻게 알릴지는 `indicator`(`CoreNavigationSelectionIndicator`)가 정합니다. 주지 않으면 모드의 기본값(`CoreNavigationBarMode.defaultIndicator`)을 쓰고, 리퀴드 글래스의 캡슐(바 · 레일)은 `color`를 씁니다 — 면은 렌즈가 그리므로 타일을 따로 칠하지 않습니다. 표시에 딸린 값은 `CoreNavigationBarStyle.defaultsByIndicator`에 있고, 직접 준 스타일 값과 테마 값이 그보다 앞섭니다.

<VariantRow name="color" component="navigation-bar" props="indicator=color">

면 없이 색과 굵기로만 알립니다. 바의 기본값입니다.

</VariantRow>
<VariantRow name="fill" component="navigation-bar" props="indicator=fill">

선택된 목적지의 타일 전체를 칠합니다. 레일과 사이드바의 기본값입니다.

</VariantRow>

| 항목 | `fill` (레일 · 사이드바) | `color` (바) |
| --- | --- | --- |
| 선택된 목적지 (라벨 위치와 상관없이) | 타일 전체 `surfaceContainerHigh` (모서리 10), 아이콘 · 라벨 `primary` (라벨 700) | 면 없음, 아이콘 · 라벨 `primary` (라벨 700) |
| 선택 + 비활성 | 타일 `disabledContainer`, 아이콘 · 라벨 `disabledContent` (라벨 700) | 면 없음, 아이콘 · 라벨 `disabledContent` (라벨 700) |
| hover | `onSurface` 상태 레이어 3% | 레이어 없이 아이콘과 라벨이 `onSurface`로 진해짐 |
| 포커스 | `onSurface` 상태 레이어 8% + 포커스 링 | `onSurface` 상태 레이어 8% + 포커스 링 |
| 선택된 목적지의 상태 | 선택 표시 위에 같은 상태 레이어 | 선택 표시 위에 같은 상태 레이어 |
| 쉬는 아이콘 · 라벨 | `onSurfaceSubtle` | `onSurfaceSubtle` |

쉬는 목적지는 `onSurfaceSubtle`로 한 단 연하게 두어 선택된 목적지가 한눈에 읽히게 합니다(쉬는 Tabs와 같은 연함). 바탕에 따라 이 색의 대비가 4.5 : 1 아래로 내려가는 자리가 있습니다 — [색 대비](#색-대비)를 보세요.

`fill`의 선택 표시는 hover 상태 레이어와 같은 크기 · 모서리의 네모입니다. 누를 수 있는 영역과 선택 표시가 같은 모양이라 위치를 읽기 쉽습니다. `color`는 면 없이 색과 굵기로만 선택을 알립니다 — 폰 하단 바는 목적지 폭이 넓어 면이 무거운 막대로 읽히고, 이 바에는 hover 때 덮는 색이 없어 면 없이도 선택이 갈립니다. `fill`의 면은 연한 회색이라 색 있는 브랜드에서도 튀지 않고, 선택은 `primary` 글자 · 아이콘과 굵기(700)가 함께 알립니다 — 면만으로는 hover 색과 잘 갈리지 않기 때문입니다. 면은 `selectedBackgroundColor`, 비활성 면은 `disabledSelectedBackgroundColor`가 정합니다. `selectedIconAnchorColor` · `selectedIconAnchorIconStyle` · `disabledSelectedIconAnchorColor` · `iconAnchorRadius`는 0.184 부터 예고된 필드이고, 어떤 목적지도 읽지 않습니다.

바와 레일처럼 라벨을 아이콘 위아래에 쌓은 목적지는 선택 여부와 상관없이 아이콘을 자기 상자(`iconAnchorPadding` 가로 12 · 세로 2) 안에 둡니다. 그래서 선택이 옮겨 가도 목적지 폭이 그대로입니다. 이 상자는 칠하지 않습니다 — 선택 표시는 타일 전체가 받습니다.

라벨을 숨긴 쌓인 목적지는 64×40을 칠합니다(`iconOnlyItemMinWidth` · `iconOnlyItemMinHeight`). 포인터를 받는 영역은 그와 따로 가로 · 세로 최소 48입니다(`touchTargetSize`) — Flutter는 `TouchTarget`이, Web은 `coui-touch-target`의 `::after`가 눌리는 영역만 넓히고 배치와 그림은 그대로 둡니다. 바가 목적지 몫으로 주는 폭이 64보다 좁으면 두 플랫폼 모두 그 몫을 따릅니다. `itemMinHeight`를 직접 주거나 리퀴드 글래스의 바 · 레일처럼 48이 정해지면, 라벨을 숨긴 목적지도 그 높이를 씁니다. 하단 바의 기본은 라벨을 모두 보이는 것(`all`)이라 목적지는 64, 바는 세로 8 + 64 + 8(안전 영역 별도)입니다. `labelMode`를 `none`으로 직접 준 하단 바만 세로 8 + 40 + 8이 됩니다 — 라벨을 숨긴 40은 접힌 레일이나 좁은 자리를 위한 높이입니다.

```dart
NavigationBar(
  mode: CoreNavigationBarMode.rail,
  header: const AppLogo(),
  items: const [
    CoreNavigationBarItem.destination(icon: Icon(LucideIcons.house), label: '홈'),
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.inbox),
      label: '받은편지함',
      showDot: true,
    ),
  ],
)
```

<a id="배지와-아래-칸-badge-footer"></a>

## 배지와 아래 칸

<Preview demo="navigation-bar/badge-footer" />

`CoreNavigationBarItem.destination(badge:)`는 개수를 보여 주는 `Badge`를 받습니다. 바와 레일에서는 아이콘의 오른쪽 위 모서리에, 사이드바와 아이콘이 없는 목적지에서는 행의 끝(라벨 뒤)에 놓입니다. 배지의 글자는 목적지 이름 뒤에 함께 읽힙니다(`편지함 3`).

`showDot`은 개수 없이 새 소식이 있다는 점을 아이콘의 오른쪽 위 모서리에 그립니다. `badge`가 있으면 `badge`만 그리고, 아이콘이 없는 목적지에는 점을 그리지 않습니다. 배지와 점은 오른쪽에서 왼쪽으로 쓰는 언어에서도 오른쪽에 남습니다.

`header`는 목적지 앞, `footer`는 목적지 뒤에 놓는 내용입니다. 둘 다 바의 바탕 · 선 · 안쪽 여백 안에 들어가고 목적지가 스크롤돼도 제자리에 있으므로, 둘레에 바를 다시 그리지 않아도 됩니다. 부모가 바의 길이를 정해 주면(높이를 지정하거나 칸을 늘리면) `footer`가 아래 끝(가로 바에서는 끝 쪽)에 붙고, 목적지가 바보다 크면 목적지만 스크롤됩니다. 길이를 정해 주지 않으면 세로 레일은 목적지와 `header` · `footer`를 합친 만큼만 차지합니다. 가로 바는 부모가 폭을 제한하면 그 폭을 채웁니다.

아래 코드는 미리보기의 레일과 같습니다. 미리보기는 높이를 352로 정한 칸에 놓았습니다. `alignment`를 `start`로 주면 Web에서도 목적지가 위에 모입니다.

```dart
NavigationBar(
  mode: CoreNavigationBarMode.rail,
  alignment: CoreNavigationAlignment.start,
  selectedIndex: index,
  onSelected: (value) => setState(() => index = value),
  header: const Icon(LucideIcons.atom),
  items: const [
    CoreNavigationBarItem.destination(icon: Icon(LucideIcons.house), label: '홈'),
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.inbox),
      label: '편지함',
      badge: Badge(
        form: CoreBadgeForm.count,
        tone: CoreBadgeTone.info,
        variant: CoreBadgeVariant.filled,
        size: CoreComponentSize.xs,
        child: Text('3'),
      ),
    ),
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.bell),
      label: '알림',
      showDot: true,
    ),
  ],
  footer: const Text('내 계정').labelSmall.onSurfaceVariant,
)
```

<a id="글자-탭과-선택-점-text-tabs-selection-mark"></a>

## 글자 탭과 선택 점

아이콘 없이 라벨만 둔 탭은 `icon`을 비우고 `labelMode`를 `all`로 둡니다. 선택은 라벨의 색과 굵기로 알리고, `selectionMark`를 `dot`으로 주면 선택된 탭의 라벨 위에 작은 점이 하나 더 붙습니다.

<Preview demo="navigation-bar/text-tabs" />

```dart
NavigationBar(
  selectedIndex: index,
  onSelected: (value) => setState(() => index = value),
  labelMode: CoreNavigationLabelMode.all,
  selectionMark: CoreNavigationSelectionMark.dot,
  items: const [
    CoreNavigationBarItem.destination(label: '홈'),
    CoreNavigationBarItem.destination(label: '지도'),
    CoreNavigationBarItem.destination(label: '채팅'),
    CoreNavigationBarItem.destination(label: '내 정보'),
  ],
)
```

- **모든 탭이 점의 자리를 가집니다.** 점은 선택된 탭에만 보이지만 나머지 탭도 같은 높이를 비워 두므로, 선택이 바뀌어도 라벨이 들썩이지 않고 한 줄로 맞습니다.
- **점은 `Badge`의 dot입니다.** 지름 4, 내용과의 간격 6입니다. 색은 `color` 표시(바의 기본)에서는 `primary`이고, 리퀴드 글래스가 아닌 `fill` 표시에서는 `onSurface`입니다. 이 `fill`에서는 선택 라벨이 `primary`라 점과 라벨의 색이 다릅니다. 리퀴드 글래스의 바와 레일은 `indicator`와 상관없이 `primary`입니다. 색 · 크기는 `selectionMarkStyle`, 간격은 `selectionMarkGapStyle`로 바꿉니다. 점은 라벨 색을 따라가지 않으므로, 선택 라벨 색을 바꾸면 점 색도 함께 바꾸세요.
- **라벨을 아이콘 옆에 두는 행에는 점이 없습니다.** 사이드바처럼 라벨이 아이콘 옆에 놓이면(`labelPosition`이 `start` · `end`) 점을 얹을 위쪽이 없습니다.

<a id="리퀴드-글래스의-바와-레일-liquid-glass"></a>

## 리퀴드 글래스의 바와 레일

표면 스타일이 리퀴드 글래스이면 — 앱 전체의 표면 스타일이든, `navigationBarStyle.surfaceStyle`로 이 바에만 준 것이든 — 바와 레일은 화면 가장자리에 붙은 판이 아니라 **떠 있는 캡슐**로 그려지고, 선택은 캡슐 안을 움직이는 렌즈가 알립니다. 사이드바는 재질만 받고 붙은 모양 그대로입니다.

<Preview demo="navigation-bar/glass" />

| 항목 | 글래스 바 | 글래스 레일 |
| --- | --- | --- |
| 모양 | 가로 캡슐 | 세로 캡슐 |
| 캡슐 둘레 여백 (`barMargin`) | 8 | 8 |
| 캡슐 안쪽 여백 | 4 | 4 |
| 목적지 | 최소 높이 48, 폭은 고르게 나눔 | 40 × 48 (라벨을 숨긴 기본) |
| 목적지 사이 | 0 | 4 |
| 아이콘 상자 | 48 × 28 | 32 × 28 |
| 라벨 표시 (`labelMode`) | `all` | `none` |
| 선택 표시 (`indicator`) | `color` — 면은 렌즈가 그림 | `color` — 면은 렌즈가 그림 |
| 콘텐츠 쪽 선 | 없음 | 없음 |

이 값은 `CoreNavigationBarStyle.glassBarStyle` · `glassRailStyle`에 있습니다. 직접 준 스타일 값 · 테마 값 · `labelMode` · `indicator`가 이 값보다 앞섭니다. 글래스 바에서 라벨을 보이는 목적지는 아이콘과 라벨만큼 커집니다.

렌즈의 움직임은 다음과 같습니다.

- 선택이 옮겨 가면 렌즈가 바에서는 옆으로, 레일에서는 위아래로 미끄러집니다. 누르고 있는 동안에는 렌즈가 조금 부풉니다. 동작 줄이기에서는 미끄러지지 않고 바로 옮겨 갑니다.
- 렌즈가 떠 있는 동안 — 누르고 있거나 아직 가는 중일 때 — 캡슐 전체가 렌즈 · 목적지와 함께 3% 커집니다(`CoreGlassNavigationMotion.barSwell`). 커지는 기준점은 렌즈의 반대편으로 기울어 있어(`barSwellOrigin`) 렌즈가 있는 쪽이 가장 많이 밀려 나가고, 놓으면 한 번 살짝 작아졌다가 제 크기로 돌아옵니다. 그리는 크기만 바뀌므로 바가 차지하는 자리와 주변 배치는 그대로이고, 손가락의 위치도 커지기 전 바를 기준으로 읽습니다. 동작 줄이기에서는 커지지 않습니다.

### 글래스 레일 — 세로 탭 바

글래스 레일은 아이콘만 세운 폭 48의 캡슐입니다. 목적지가 네 개면 48 × 212이고, 하나 늘 때마다 52씩 길어집니다. 탭 바를 화면 옆으로 옮겨 세로로 세우는 기기의 탭 바와 같은 모양입니다. 세로로 세운 바에서는 글자를 눕히지 않으므로 라벨을 그리지 않습니다 — 라벨은 목적지의 이름으로 남으니 `label`은 그대로 채우세요.

```dart
NavigationBar(
  mode: CoreNavigationBarMode.rail,
  selectedIndex: index,
  onSelected: (value) => setState(() => index = value),
  items: const [
    CoreNavigationBarItem.destination(icon: Icon(LucideIcons.house), label: '홈'),
    CoreNavigationBarItem.destination(icon: Icon(LucideIcons.search), label: '검색'),
    CoreNavigationBarItem.destination(icon: Icon(LucideIcons.bell), label: '알림'),
    CoreNavigationBarItem.destination(icon: Icon(LucideIcons.user), label: '프로필'),
  ],
)
```

목적지를 누르면 렌즈가 그 자리로 미끄러집니다. 캡슐을 누른 채 위아래로 끌면 렌즈가 손가락을 따라가고, 놓은 자리의 목적지가 한 번 선택됩니다(`onSelected`를 준 경우). 옆으로 끄는 동작은 페이지의 것으로 남습니다. 오른쪽에서 왼쪽으로 쓰는 언어에서도 순서는 위에서 아래입니다.

렌즈는 아래 조건이 모두 참일 때 움직입니다. 하나라도 어긋나면 캡슐과 재질은 그대로 두고, 선택된 목적지가 렌즈와 같은 색의 면을 스스로 칠합니다.

| 조건 | 바 | 레일 |
| --- | --- | --- |
| 항목이 전부 목적지입니다 (`divider` · `label` · `gap` 없음) | 필요 | 필요 |
| `header` · `footer`가 없습니다 | 필요 | 필요 |
| 목적지의 크기가 모두 같습니다 | 폭을 똑같이 나누므로 보통 충족합니다 | 필요. `labelMode`가 `selected`면 선택된 목적지만 길어져 걸립니다 |
| 목적지가 스크롤 없이 다 보입니다 | 필요 | 필요 |

**캡슐을 어디에 놓을지는 앱이 정합니다.** 레일은 자기 `SafeArea`를 두지 않고 캡슐 둘레의 여백 8만 갖습니다. 화면 한쪽을 세로 컨트롤 자리로 비워 두는 기기에서 Flutter는 그 자리의 폭을 `MediaQuery.viewPaddingOf(context)`의 왼쪽이나 오른쪽 값으로 알려 주므로, 앱의 화면 틀이 그 값을 읽어 레일을 그 안에 놓습니다. 그 자리는 위쪽 여백이 없고 **한쪽에만** 여백이 있는 모양으로 옵니다 — 보통의 휴대폰도 가로로 눕히면 양쪽에 같은 여백이 생기므로, 한쪽 값만 보면 그 화면에서도 레일이 나옵니다. 그 자리는 글 쓰는 방향이 바뀌어도 화면의 같은 쪽에 남으니 `start` · `end`가 아니라 `left` · `right`로 맞춥니다. `AppBar`를 `headers`에 둔 `Scaffold`에서 `adaptiveAppBarActions`를 켜면 `Scaffold`가 본문에 내려 주는 좌우 여백이 0이 되므로, 이 값은 `Scaffold` 밖에서 읽습니다.

아래는 Flutter 코드입니다.

```dart
// 화면 오른쪽에 세로 컨트롤 자리가 있을 때 — 그 안쪽 아래에 레일을 놓습니다.
// 위쪽 여백이 없고 오른쪽에만 여백이 있을 때가 그 자리입니다.
final inset = MediaQuery.viewPaddingOf(context);
final strip = inset.top == 0 && inset.left == 0 ? inset.right : 0.0;

Stacks(
  children: [
    Position.fill(child: content),
    if (strip > 0)
      Position(
        right: 0,
        bottom: 0,
        width: strip,
        child: Align(
          alignment: Alignment.bottomLeft,
          child: NavigationBar(mode: CoreNavigationBarMode.rail, items: items),
        ),
      ),
  ],
)
```

캡슐과 그 자리 가장자리 사이의 거리는 기기마다 다릅니다. 레일의 여백 8보다 더 띄워야 하면 레일을 `Padding`으로 감싸거나 `navigationBarStyle.barMargin`을 줍니다.

같은 자리에 앱 바의 아이콘 동작(뒤로 · 공유)을 함께 세우려면 세로 [ToolbarGroup](/components/toolbar-group)을 씁니다 — 글래스에서 둘 다 폭 48의 캡슐입니다. 바와 나누는 방법은 [AppBar의 조합 예제](/components/app-bar#옆-컨트롤-자리로-동작-나누기)에 있습니다.

<a id="스크롤할-때-줄어드는-바-compact-on-scroll"></a>

## 스크롤할 때 줄어드는 바

본문을 읽어 내려가는 동안 하단 바가 한발 물러나게 하려면 `compact`를 `onScroll`로 줍니다. 본문을 아래로 스크롤하면 바가 라벨을 접어 아이콘만 남기고 아래쪽 가운데를 기준으로 작아집니다. 위로 되돌리거나 본문이 맨 위에 닿으면 라벨과 함께 제 크기로 돌아옵니다.

아래는 같은 글래스 바를 `never`와 `always`로 그린 정지 장면입니다. 스크롤을 따라 줄었다가 돌아오는 움직임은 이 장면에서는 보이지 않습니다.

<Preview demo="navigation-bar/compact" />

```dart
Scaffold(
  floatingFooter: true,
  footers: [
    NavigationBar(
      selectedIndex: index,
      onSelected: (value) => setState(() => index = value),
      compact: CoreNavigationCompact.onScroll,
      navigationBarStyle: const CoreNavigationBarStyle(
        surfaceStyle: CoreSurfaceStyleId.liquidGlass,
      ),
      items: const [
        CoreNavigationBarItem.destination(icon: Icon(LucideIcons.house), label: '홈'),
        CoreNavigationBarItem.destination(icon: Icon(LucideIcons.search), label: '검색'),
      ],
    ),
  ],
  child: feed,
)
```

- **줄어드는 것은 떠 있는 바입니다.** 리퀴드 글래스에서 캡슐로 떠 있는 바는 0.84배로 줄어듭니다(`CoreNavigationBarStyle.glassCompactScale`). 화면 끝에 붙은 바는 줄지 않습니다 — 그 바는 배치에서 자리를 차지하고 끝에 닿아 있어서, 작게 그리면 끝에서 떨어지고 자리를 줄이면 스크롤하던 본문의 크기가 바뀝니다. 직접 띄운 바는 `navigationBarStyle.compactScale`에 배율을 주면 같은 방식으로 줄어듭니다. 레일은 기본 배율이 없고, 배율을 주면 가운데를 기준으로 줄어듭니다.
- **라벨이 접히고 아이콘만 남습니다.** 줄어드는 바는 목적지의 라벨을 접습니다 — 라벨의 높이, 아이콘과의 간격, 불투명도가 함께 0으로 갑니다. 접힌 라벨은 여전히 목적지의 이름이라 스크린 리더는 그대로 읽습니다. 라벨을 숨긴 바(`labelMode`가 `none`)와 달리 접힌 동안에는 툴팁이 뜨지 않습니다 — 스크롤을 되돌리면 라벨이 돌아옵니다. 배율이 1인 바(화면 끝에 붙은 바)는 라벨도 접지 않습니다.
- **바가 낮아지고, 그 바를 작게 그립니다.** 라벨이 접힌 만큼 바의 높이가 줄어듭니다 — 목적지의 최소 높이까지이고, 리퀴드 글래스 바는 48입니다. 그 바를 배율만큼 작게 그립니다. 폭은 배치에서 그대로이고 그리는 크기만 줄어서, 바의 양옆 여백이 그만큼 넓어집니다. Flutter에서 `Scaffold`의 `floatingFooter`처럼 본문 위에 겹쳐 놓은 바는 본문을 다시 배치하지 않습니다. Web의 떠 있는 footer는 스크롤 영역의 끝에 붙어 있어 스크롤 길이가 바가 낮아진 만큼 줄어듭니다([플랫폼 차이](#플랫폼-차이)). 본문 아래 칸에 따로 둔 바는 낮아진 만큼 본문에 자리를 내줍니다. 줄어든 바도 보이는 자리에서 그대로 누르고 끌 수 있습니다.
- **12px를 움직여야 바뀝니다.** 같은 방향으로 12px를 스크롤해야 바가 줄거나 돌아오고, 방향을 바꾸면 처음부터 다시 셉니다. 손가락이 조금 흔들리는 정도로는 바가 깜빡이지 않습니다. 본문이 끝을 넘어 튕기는 움직임은 세지 않습니다. 이 판정은 `CoreNavigationScrollCompaction` 한 곳에 있고 두 플랫폼이 같이 읽습니다.
- **세는 스크롤은 보이는 본문의 바깥쪽 세로 스크롤입니다.** 본문 안에 겹친 세로 목록 · 입력 칸, 숨겨진 탭, 가로 스크롤, 바 자신의 스크롤은 세지 않습니다. 이들의 내용 길이가 바뀌거나 스크롤이 맨 위로 돌아와도 바는 그대로입니다. 가로로 넘기는 면 안의 세로 목록은 본문으로 셉니다. 다른 목적지를 고르면 바가 제 크기로 돌아옵니다 — 바뀐 본문은 바를 온전히 보인 채로 시작합니다.
- **직접 정하려면 `always`와 `never`를 바꿔 줍니다.** 스크롤 말고 다른 기준으로 바를 줄이려는 앱은 `compact`를 `always`와 `never` 사이에서 바꿉니다. 바는 그 사이를 같은 움직임으로 오갑니다.
- **바뀌는 시간.** 바가 줄거나 돌아올 때 300ms(`compactDuration`) 동안 `CoreEasing.move` 곡선으로 크기가 바뀌고, 라벨도 같은 시간 · 같은 곡선으로 접히고 펴집니다. 동작 줄이기에서는 바로 바뀝니다. 줄어든 바의 렌즈를 누르면 캡슐이 커지는 움직임이 줄어든 크기 위에 더해집니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

선택된 곳을 표시하며 주요 섹션 사이를 옮길 때 씁니다. 모바일 앱 아래쪽의 주요 3~5개 섹션은 `bar`, 데스크톱 · 태블릿 옆의 좁은 내비게이션은 `rail`이 맞습니다.

### 다른 컴포넌트가 더 맞는 경우

| 상황 | 쓰는 것 |
| --- | --- |
| 라벨이 강조된 넓은 옆 내비게이션(헤더 · 검색 · 구역 · 그룹) | [Sidebar](/components/sidebar) |
| 위쪽 트리거가 링크 · 동작 · 큰 드롭다운 패널을 여는 내비게이션 | [NavigationMenu](/components/navigation-menu) |
| 같은 화면 안에서 보기를 바꾸는 탭 | [Tabs](/components/tabs) |
| 화면 제목 · 뒤로 가기 · 동작을 담는 헤더 | [AppBar](/components/app-bar) |
| 페이지 끝의 법적 정보 · 링크 묶음 | [Footer](/blocks/footer) |

<a id="do"></a>
<a id="dont"></a>

### 라벨

<Cards columns="2">
<Card demo="navigation-bar/do-short" tone="do" eyebrow="이렇게 하세요">

라벨은 한두 단어로 짧게 씁니다.

</Card>
<Card demo="navigation-bar/dont-long" tone="dont" eyebrow="이렇게 하지 마세요">

긴 라벨은 잘리거나 바를 가로로 스크롤하게 만들어 목적지를 훑어보기 어렵습니다.

</Card>
</Cards>

### 모드의 라벨 기본값을 그대로 씁니다

`labelMode` · `labelPosition`을 생략하면 모드의 기본값(`bar` → `all` · `bottom`, `rail` → `all` · `bottom`, `sidebar` → `all` · `end`)을 씁니다. 리퀴드 글래스의 레일만 `none`입니다. 라벨 표시 방식을 매번 지정할 필요가 없습니다.

```dart
NavigationBar(
  mode: CoreNavigationBarMode.rail,
  selectedIndex: index,
  onSelected: (value) => setState(() => index = value),
  items: destinations,
)
```

### 번호는 목록의 순서가 아닙니다

`selectedIndex` · `onSelected`의 번호는 목적지만 셉니다. `label` · `divider` · `gap`은 건너뛰므로, `items` 목록의 위치를 그대로 넘기면 어긋납니다.

```dart
NavigationBar(
  items: const [
    CoreNavigationBarItem.label('메인'), // 세지 않음
    CoreNavigationBarItem.destination(label: '홈'), // 0
    CoreNavigationBarItem.divider(), // 세지 않음
    CoreNavigationBarItem.destination(label: '설정'), // 1
  ],
  selectedIndex: 1, // '설정'이 선택됩니다. '홈'을 고르려면 0
)
```

### 라벨을 숨겨도 `label`은 채웁니다

목적지의 이름은 `label`(과 배지의 글자)에서만 나옵니다. 화면에 라벨을 보이고 싶지 않으면 `label`을 비우지 말고 `labelMode`를 `none`으로 두세요.

## 배치

<Cards columns="2">
<Card demo="navigation-bar/placement-bottom" title="화면 아래의 바">

모바일에서는 가로 바를 화면 아래 끝에 붙입니다.

</Card>
<Card demo="navigation-bar/placement-rail" title="화면 옆의 레일">

넓은 화면에서는 레일을 글 방향의 시작 쪽에 세우고 본문을 그 옆에 둡니다.

</Card>
</Cards>

`Scaffold`에서는 하단 바를 `footers`에 둡니다. 본문 위에 겹쳐 띄우려면 `floatingFooter`를 켭니다([스크롤할 때 줄어드는 바](#스크롤할-때-줄어드는-바)의 예).

<a id="아래-안전-영역-bottom-safe-area"></a>

### 아래 안전 영역

화면 아래에 붙은 바는 기기의 아래 안전 영역(홈 인디케이터)을 스스로 받습니다. 바의 아래 여백 8에 기기의 인셋이 더해져서, 바탕은 인디케이터 밑까지 칠해지고 목적지는 그 위에 앉습니다. 인셋은 기기마다 다르므로 스타일 값이 아닙니다.

- **Flutter** — `MediaQuery.paddingOf(context).bottom`을 더합니다. `viewPadding`이 아니라 `padding`인 이유는 둘입니다. 키보드가 인디케이터를 덮으면 `padding`은 0이 되고, 바깥 `SafeArea`가 이미 쓴 인셋도 0으로 읽힙니다.
- **Web** — `padding-bottom`에 `env(safe-area-inset-bottom)`을 더해(`calc(8px + env(safe-area-inset-bottom))` 같은 형태) 냅니다. 인셋이 없는 곳(데스크톱, `viewport-fit=cover`를 쓰지 않은 페이지)에서 `env()`는 0입니다.

바가 인셋을 받으므로 바깥에서 같은 인셋을 다시 주지 마세요.

- **Flutter** — 바를 `SafeArea`로 다시 감싸지 마세요. 감싸면 바탕이 인디케이터 위에서 끊기고, 그 아래로 페이지 바탕이 보입니다. 바깥 `SafeArea`가 이미 인셋을 썼다면 바는 0을 읽으므로 두 번 더해지지는 않습니다.
- **Web** — 감싸는 요소에 `env(safe-area-inset-bottom)` 여백을 또 주지 마세요. 바깥에서 써도 `env()` 값은 줄지 않으므로 인셋이 두 번 더해집니다.

떠 있는 바(`barMargin`을 준 바, 글래스 바)는 인셋을 안쪽 여백에 넣지 않습니다. Flutter의 글래스 바는 자기 `SafeArea` 안에 놓이고, `barMargin`으로 띄운 바의 아래 공간은 앱이 정합니다. 두 플랫폼이 붙은 바를 판단하는 기준은 [플랫폼 차이](#플랫폼-차이)를 보세요.

### 남는 폭과 넘치는 목적지

- **가로 바** — 목적지가 폭 안에 들어가면 같은 몫으로 나눕니다. 상한(96) 때문에 남는 폭은 `alignment`(`start` · `center` · `end` · `spaceBetween` · `spaceAround` · `spaceEvenly`)가 나눕니다. 폭에 다 들어가지 않으면 바가 가로로 스크롤합니다.
- **레일** — 목적지가 높이를 넘으면 세로로 스크롤합니다. `alignment`는 두 플랫폼이 다르게 적용합니다([알려진 제약](#알려진-제약)).

Web에서 목적지가 넘칠 수 있는 바와 레일에는 `alignment`를 `start`로 주세요. `center`(기본)와 `end`에서는 넘친 목적지의 앞부분이 스크롤로 닿지 않습니다([알려진 제약](#알려진-제약)).

## 테마와 스타일

`mode` · `labelMode` · `indicator` · `selectionMark` · `compact` 같은 동작과 배치는 위젯 속성으로 넘기고, 색 · 여백 · 모서리처럼 보이는 값은 `navigationBarStyle`로 덮어씁니다.

<Split>

<Code language="dart" title="바 하나만 바꾸기">
NavigationBar(
  selectedIndex: index,
  onSelected: (value) => setState(() => index = value),
  navigationBarStyle: const CoreNavigationBarStyle(
    itemMaxWidth: double.infinity,
  ),
  items: destinations,
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기 (coreComponentTheme)">
CoreComponentTheme(
  navigationBar: CoreNavigationBarTheme(
    style: CoreNavigationBarStyle(
      itemSpacing: CoreSpace.space4,
    ),
  ),
)
</Code>

</Split>

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `NavigationBar` 인스턴스에 스타일을 빠르게 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `navigationBarStyle`과 같게 동작하지만, 이미 만든 위젯 위에서 바로 이어 쓸 수 있습니다. `.surfaceContainer`처럼 Core 토큰 이름과 같은 이름의 짧은 getter도 있습니다. `withStyle`을 한 번 더 줄인 것이고, 이름이 곧 값이라(`.surfaceContainer`는 `CoreColors.surfaceContainer`) 어느 컴포넌트에서 써도 뜻이 같습니다. 아래 예처럼 `withStyle` 뒤에 이어 붙일 수도 있습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class NavigationBarChainExample extends StatefulWidget {
  const NavigationBarChainExample({super.key});

  @override
  State<NavigationBarChainExample> createState() => _NavigationBarChainExampleState();
}

class _NavigationBarChainExampleState extends State<NavigationBarChainExample> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
          mode: CoreNavigationBarMode.bar,
          selectedIndex: _selectedIndex,
          onSelected: (index) => setState(() => _selectedIndex = index),
          labelMode: CoreNavigationLabelMode.all,
          items: const [
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.house),
              label: '홈',
            ),
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.search),
              label: '검색',
            ),
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.bell),
              label: '알림',
            ),
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.user),
              label: '프로필',
            ),
          ],
        )
        .withStyle(
          const CoreNavigationBarStyle(
            itemSpacing: CoreSpace.space12,
            itemPadding: CoreEdgeInsets.all(CoreSpace.space12),
            itemRadius: CoreBorderRadius.all(CoreRadius.radius16),
          ),
        )
        .surfaceContainer;
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class NavigationBarChainExample extends StatefulComponent {
  const NavigationBarChainExample({super.key});

  @override
  State<NavigationBarChainExample> createState() => _NavigationBarChainExampleState();
}

class _NavigationBarChainExampleState extends State<NavigationBarChainExample> {
  int _selectedIndex = 0;

  @override
  Component build(BuildContext context) {
    return NavigationBar(
          mode: CoreNavigationBarMode.bar,
          selectedIndex: _selectedIndex,
          onSelected: (index) => setState(() => _selectedIndex = index),
          labelMode: CoreNavigationLabelMode.all,
          items: const [
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.house),
              label: '홈',
            ),
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.search),
              label: '검색',
            ),
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.bell),
              label: '알림',
            ),
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.user),
              label: '프로필',
            ),
          ],
        )
        .withStyle(
          const CoreNavigationBarStyle(
            itemSpacing: CoreSpace.space12,
            itemPadding: CoreEdgeInsets.all(CoreSpace.space12),
            itemRadius: CoreBorderRadius.all(CoreRadius.radius16),
          ),
        )
        .surfaceContainer;
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

### 값이 정해지는 순서

필드마다 뒤로 갈수록 우선합니다.

```text
CoreNavigationBarStyle.defaultX                // 기본값. 바탕색은 defaultsByVariant[variant]
  → CoreNavigationBarStyle.defaultsByMode[mode]           // 모드별 밀도
  → CoreNavigationBarStyle.defaultsByIndicator[indicator] // 선택 표시
  → CoreNavigationBarStyle.glassStyleFor(mode)            // 리퀴드 글래스의 바 · 레일
  → CoreNavigationBarTheme.style                          // 프로젝트 공통
  → CoreNavigationBarTheme.variantStyles[variant]         // 프로젝트 variant 별
  → widget.navigationBarStyle                             // 인스턴스별
```

<a id="접근성-accessibility"></a>

## 접근성

### 역할

| 대상 | Flutter | Web |
| --- | --- | --- |
| 루트 | `Semantics(container: true, label: …)` — 랜드마크 역할 없음 | `<nav>` 요소 + `aria-label` |
| 목적지 | 목적지 하나가 노드 하나입니다. `Clickable`이 버튼 · 활성 여부 · 선택을 알리고, 목적지가 이름(`label`)을 더해 배지의 글자까지 한 노드로 합칩니다(`MergeSemantics`) | `role="button"`. 누를 수 있으면 `tabindex="0"`, 비활성이거나 `onSelected`가 없으면 `aria-disabled="true"`. `aria-labelledby`(라벨 → 배지), 선택되고 활성이면 `aria-current="page"` |
| 구획 제목 · 구분선 · 빈 간격 | 역할 없음 (`Text` · `Divider` · `Gap` 그대로) | 역할 없음 (`<div>` · `Divider` · `Gap` 그대로) |

선택을 알리는 방식은 플랫폼마다 다릅니다 — Flutter는 `selected` 시맨틱, Web은 `aria-current="page"`입니다. 둘 다 "지금 여기"를 전하지만 스크린 리더가 읽는 문구는 같지 않습니다.

루트의 이름은 두 플랫폼 모두 로케일의 `navigationLabel`(한국어 "탐색", 영어 "Navigation")입니다. Web의 `aria-label`은 넘겨 준 `attributes`를 합친 **뒤에** 쓰므로 바꿀 수 없습니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` / `Shift + Tab` | 목적지 하나씩 앞뒤로 이동합니다(목적지마다 tab stop) |
| `Enter` | 포커스한 목적지를 누릅니다 |
| `Space` | 포커스한 목적지를 누릅니다 |
| `Arrow` (↑↓←→) | 컴포넌트는 처리하지 않습니다. 네이티브 Flutter에서는 프레임워크 기본값이 방향 포커스 이동으로 해석하고, Flutter Web은 스크롤로 처리합니다. Web(Jaspr)에서는 브라우저의 기본 스크롤이 일어납니다 |
| `Home` / `End` | 없음 |

`Enter` · `Space`는 `Clickable`이 처리합니다. Web도 두 키 모두 누를 때 실행합니다. `Space`는 누르고 있는 동안 눌린 모양을 유지하고 뗄 때 풉니다. Web은 이벤트 대상이 목적지 자신일 때만 반응해 안쪽 컨트롤의 활성화를 가로채지 않습니다.

### 스크린 리더

- 이름은 `label`에서 나오고, 배지가 있으면 그 글자가 뒤에 붙습니다(Flutter `알림\n3`, Web `알림 3`). 화면의 라벨 글자는 이름과 겹쳐 두 번 읽히지 않습니다. `labelMode`가 `none` · `selected`라서 라벨이 화면에 없어도 이름은 남습니다 — Flutter는 `Semantics(label:)`, Web은 시각적으로 숨긴 라벨 요소를 `aria-labelledby`로 가리킵니다.
- 비활성 목적지는 비활성으로 알립니다. 선택된 비활성 목적지는 선택(`selected` · `aria-current`)을 알리지 않습니다.
- 선택 점은 장식입니다(Flutter `ExcludeSemantics`, Web `aria-hidden="true"`). 선택은 목적지의 선택 상태로 이미 알립니다.
- 라벨이 화면에 없는 목적지에는 `Tooltip`이 붙습니다. 툴팁 문구가 라벨과 같으면(기본) 이름이므로 힌트로 다시 읽지 않습니다. 라벨과 다른 `tooltip`은 Flutter에서는 힌트로 읽힙니다.
- 선택 번호가 바뀌어도 그 변화를 따로 알리는 영역은 없습니다. 목적지를 직접 누르면 포커스가 거기 있어 새 상태가 읽히지만, 코드가 `selectedIndex`를 바꾸면 조용히 바뀝니다.

### 포커스 관리

- 오버레이가 아니므로 나타나거나 사라질 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. `Tab`은 마지막 목적지를 지나 바깥으로 나갑니다.
- 목적지마다 tab stop이 하나씩 있습니다. 목적지가 N개면 바를 지나는 데 `Tab`을 N번 누릅니다. 구획 제목 · 구분선 · 빈 간격과 비활성 목적지는 포커스를 받지 않습니다.
- 목적지가 넘치면 바는 가로로, 레일은 세로로 스크롤합니다. 화면 밖 목적지로 포커스가 가면 스크롤 영역이 그 목적지를 보이는 자리로 가져옵니다. Web에서 `alignment`가 `center`(기본)나 `end`이면 앞쪽으로 넘친 부분은 스크롤로 닿지 않습니다([알려진 제약](#알려진-제약)).
- 포커스 링은 `Clickable`이 그립니다 — Flutter는 `FocusOutline`, Web은 `:focus-visible` 링입니다.

### 알려진 제약

- **`label`이 없는 목적지는 이름이 없습니다.** `label`은 선택 파라미터이고, 이름은 그 값(과 배지의 글자)에서만 만듭니다. 아이콘만 둔 목적지를 `label` 없이 만들면 스크린 리더는 버튼이라고만 읽습니다. `label`은 채우고 `labelMode`를 `none`으로 두세요.
- **알림 점(`showDot`)은 보조 기술에 알리지 않습니다.** 새 소식이 있다는 사실을 말해야 하면 개수 배지를 쓰거나 `label`에 담으세요.
- **화살표 키로 옮기지 않습니다.** 목적지 수만큼 tab stop이 생깁니다. Web 루트의 `onKeyDown`으로는 어느 목적지가 포커스인지 알 수 없어, 앱에서 화살표 이동을 대신 만들기도 어렵습니다.
- **툴팁은 포인터를 올릴 때 뜹니다.** 키보드로는 두 플랫폼 모두 뜨지 않습니다. 터치로는 Flutter에서 뜨지 않고, Web에서는 브라우저가 터치를 마우스 이벤트로 바꿔 보내는지에 따라 다릅니다.
- **Web은 툴팁과 목적지를 연결하지 않습니다.** 라벨과 다른 `tooltip` 문구는 Web 스크린 리더에 전해지지 않고, 이름(`label` + 배지)만 읽힙니다.
- **`onSelected`를 주지 않으면 플랫폼마다 다릅니다.** Flutter의 목적지는 여전히 누를 수 있는 것으로 보이고 눌러도 아무 일이 없습니다. Web의 목적지는 색이 켜진 목적지 그대로이지만 커서가 금지 모양이고, `aria-disabled="true"`이며 포커스를 받지 않습니다. hover 때 덮는 색은 `fill` 표시(레일 · 사이드바의 기본)에서만 나타납니다.
- **배지와 알림 점은 오른쪽에서 왼쪽으로 쓰는 언어에서도 뒤집히지 않습니다.** 두 플랫폼 모두 아이콘의 오른쪽 위에 놓습니다.
- **Web에서는 넘친 목적지의 앞부분이 스크롤로 닿지 않을 수 있습니다.** `alignment`가 `center`(기본)나 `end`이면, 폭(레일은 높이)에 다 들어가지 않는 목적지 줄이 앞쪽(가로 바는 시작 쪽, 레일은 위쪽)으로도 넘칩니다. 그 부분은 스크롤해도 보이지 않습니다. `alignment`를 `start`로 주세요. Flutter는 영향이 없습니다.
- **레일의 `alignment`는 Flutter에서 효과가 없습니다.** Flutter의 레일은 목적지를 늘 위에 모읍니다. 높이가 늘어난 Web 레일은 `alignment`를 따르므로, 기본값 `center`면 목적지가 가운데에 모입니다. 두 플랫폼에서 위에 모으려면 `alignment`를 `start`로 줍니다.
- **리퀴드 글래스에서는 선택 아이콘이 `selectedIconStyle`을 따르지 않는 경우가 있습니다.** Flutter는 늘 따르지 않습니다 — `iconStyle`에 색을 주면 그 색을, 주지 않으면 선택 라벨의 색을 씁니다. Web은 `iconStyle`에 색을 주지 않은 경우에 선택 라벨의 색을 씁니다. 그래서 글래스 사이드바의 선택 아이콘은 Flutter에서 `primary`, Web에서 `onSurface`입니다.
- **렌즈가 움직이는 리퀴드 글래스에서는 선택 + 비활성 목적지의 표시가 거의 남지 않습니다.** Flutter는 선택 표시를 그리지 않고, Web은 라벨 굵기(그리고 `selectionMark`가 `dot`이면 흐린 점)를 남깁니다.
- **렌즈가 움직이는 Web의 리퀴드 글래스는 키보드 포커스에도 상태 색을 덮지 않습니다.** 포커스 위치는 포커스 링만 알려 줍니다.
- **Web에서 바탕이나 상태 레이어 색을 토큰이 아닌 색으로 주면 상태 레이어를 그리지 않습니다.** Flutter는 그 색에도 그립니다. hover · 포커스 표시가 필요하면 토큰 색을 쓰세요.
- **글래스 바와 레일에 `header` · `footer`를 주면 움직이는 렌즈가 꺼집니다.** 레일은 목적지 크기가 서로 다르거나 스크롤할 때도 같습니다 — [리퀴드 글래스의 바와 레일](#리퀴드-글래스의-바와-레일)의 조건을 보세요.
- **레일은 기기의 세로 컨트롤 자리를 스스로 찾지 않습니다.** 그 자리가 있는지, 어느 쪽인지, 가장자리에서 얼마나 띄울지는 앱이 `MediaQuery`의 값을 읽어 정합니다. 같은 자리에 두는 아이콘 동작은 세로 [ToolbarGroup](/components/toolbar-group)으로 앱이 세우고, 좁은 화면에서 탭 바를 접는 동작은 이 컴포넌트가 하지 않습니다.
- **Flutter 루트에는 내비게이션 랜드마크가 없습니다.** Web은 `<nav>`로 랜드마크를 만들지만 Flutter 루트는 이름만 있어, 랜드마크 목록으로 건너뛸 수 없습니다.

#### 색 대비

쉬는 목적지의 `onSurfaceSubtle` 글자와 아이콘은 4.5 : 1 아래인 자리가 있습니다. 킷의 대비 검사에는 디자이너가 받아들인 예외로 적혀 있습니다.

- CoUI 라이트의 레일 바탕에서는 쉬는 상태가 4.45 : 1입니다. 하단 바의 바탕에서 쉬는 상태는 4.5 : 1을 넘습니다.
- hover · 포커스 · 눌림 색 위에서는 3.8 ~ 4.4 : 1까지 내려갑니다(CoUI 라이트 · 다크). 검사 목록에 오른 자리는 라이트의 바와 레일의 hover · 포커스 · 눌림, 다크 레일의 포커스 · 눌림입니다. 하단 바의 `color` 표시는 hover 때 레이어를 덮지 않고 글자를 진하게 합니다.
- CoUI 팔레트와 `CoreBrand.fromColor` 브랜드에서는 선택된 목적지가 모든 상태에서 4.5 : 1을 넘고, 비활성을 뺀 모든 조합이 3 : 1 위에 있습니다. 고대비 모드는 4.5 : 1을 넘습니다.
- 생성 팔레트를 표준 매핑(`CoreSemanticMappingSet.standard`)으로 읽는 브랜드는 선택 라벨도 4.5 : 1 아래로 내려가는 자리가 있습니다. 라이트에서 면을 칠하는 `fill` 표시(레일 · 사이드바)는 쉬는 상태 3.26 : 1, hover 3.08 : 1, 포커스 · 눌림 2.81 : 1입니다. 라이트의 면 없는 바(`color` 표시)는 포커스 · 눌림에서 3.95 : 1입니다. 다크의 `fill` 표시는 포커스 · 눌림에서 4.35 : 1입니다. 이 자리도 디자이너가 받아들인 예외입니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

두 플랫폼은 같은 생성자 속성을 받습니다. Web은 HTML 속성을 위한 `id` · `classes` · `css` · `attributes`와 DOM 이벤트(`eventHandlers` · `onClick` · `onKeyDown` 등)를 더 받습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 루트 | 이름만 있는 `Semantics` 노드 | `<nav>` |
| 목적지 줄 | 가로 바는 폭에 들어가면 같은 몫으로 나누고, 넘치면 가로 `SingleChildScrollView`. 레일은 세로 `SingleChildScrollView` | flex 상자. 넘치면 `overflow-x-auto` · `overflow-y-auto`. `alignment`가 `center` · `end`면 앞쪽으로 넘친 부분은 스크롤로 닿지 않음 |
| 라벨 넘침 (`overflow`) | `TextOverflow` | CSS `text-overflow` |
| 레일의 `alignment` | 적용하지 않음(목적지가 위에 모임) | 적용 |
| `onSelected`가 `null` | 누를 수 있는 모습과 동작 | 색은 켜진 그대로지만 커서가 금지 모양이고 `aria-disabled`, 포커스를 받지 않음. hover 때 덮는 색은 `fill` 표시에서만 |
| 배지 (바 · 레일) | `Indicator`(겹침 배치) | `Indicator`(절대 위치 오버레이) |
| `header` · `footer` 배치 | 높이가 고정된 세로 바는 목적지가 남는 자리를 모두 쓰고, 위아래가 열린 바는 제 크기까지만 씁니다 | 부모가 높이를 정하면 목적지 상자가 늘어나고, 아니면 내용만큼 |
| 목적지 이름 | 노드 하나에 이름 + 배지 글자(줄바꿈으로 이음) | `aria-labelledby`(공백으로 이음) |
| 붙은 바를 판단하는 기준 (안전 영역 · 콘텐츠 쪽 선) | 정해진 `barMargin`이 0이면 붙은 바 | `barMargin`을 주지 않았으면 붙은 바 — 0을 직접 주면 안전 영역과 선이 빠집니다 |
| 아래 안전 영역 (붙은 하단 바) | 아래 여백에 `MediaQuery.paddingOf(context).bottom`을 더함 | `padding-bottom`에 `env(safe-area-inset-bottom)`을 더함 |
| 글래스 바의 아래 안전 영역 | `SafeArea(top: false)`로 감쌈 | 인셋을 받지 않음 |
| 글래스 선택 렌즈 | 첫 프레임부터 위젯이 그림 | 브라우저에서 깨어난 뒤 목적지를 재서 그림. 서버가 낸 첫 화면에서는 선택된 목적지가 같은 색의 면을 칠함 |
| 글래스 바에 `itemMaxWidth` 상한을 직접 준 경우 | 상한 때문에 목적지가 줄 끝에 닿지 않으면 렌즈 대신 선택된 목적지가 면을 칠함 | 그려진 목적지를 직접 재므로 렌즈가 따라감 |
| 글래스 바 · 레일의 타일 바탕 · 선택 점 전환 시간 (기본) | 렌즈와 별개인 스프링이 가라앉는 시간(약 0.95초) | 150ms |
| 라벨 · 아이콘 색 전환 | 바로 바뀜 | 앱의 테마 전환 설정(`enableThemeAnimation`)이 켜져 있으면 150ms, 끄면 바로 |
| 렌즈가 움직이는 글래스의 상태 색 | 선택된 목적지에는 덮지 않고, 누르고 있거나 렌즈가 옮겨 가는 동안에는 다른 목적지에도 덮지 않음 | 어느 목적지에도 덮지 않음(포커스 링은 남음) |
| `hoverBackgroundColor` (토큰 색) | hover · 포커스 · 눌림에 칠함 | hover에만 칠함 |
| 상태 레이어 | 어떤 색에도 그림 | 바탕과 레이어 색이 토큰일 때만 그림 |
| 선택 점 전환 | `AnimatedOpacity` (`duration` · `CoreEasing.move`) | 감싼 요소의 `opacity` CSS 전환 |
| `compact`가 `onScroll`일 때 듣는 스크롤 | 바 위쪽의 가장 가까운 `ScrollNotificationObserver` — `Scaffold`가 본문 둘레에 하나를 둡니다. `Scaffold` 없이 짠 화면은 바와 본문을 함께 감싸는 자리에 직접 둡니다. 없으면 바는 줄지 않습니다 | 바가 속한 `Scaffold` 안의 스크롤과, 그 `Scaffold`가 놓인 스크롤 영역(페이지 포함)의 스크롤. Web의 `Scaffold`는 내용만큼 자라고 스크롤은 그것을 담은 쪽이 합니다. 더 바깥의 스크롤 영역은 세지 않습니다 |
| 줄어드는 바가 시작하는 때 | 첫 프레임부터 | `onScroll`은 브라우저에서 깨어난 뒤(서버가 낸 첫 화면은 제 크기). `always`는 서버에서부터 줄어 있음 |
| 줄어드는 바와 본문의 스크롤 길이 | `Scaffold`의 떠 있는 footer는 본문 위에 겹쳐 있어, 라벨이 접혀도 스크롤 길이가 그대로 | `Scaffold`의 떠 있는 footer는 스크롤 영역의 끝에 붙어 있어(sticky), 라벨이 접히면 스크롤 길이가 바가 낮아진 만큼 줄고, 끝까지 스크롤한 자리에서도 바는 줄어든 채 |
| 줄어드는 바와 테마 전환 | 바의 색도 함께 전환 | 줄어들 수 있는 바(`compact`가 `never`가 아니고 배율이 1이 아닌 바)는 `transition`을 크기에 쓰므로, 바 바탕색은 전환 없이 바로 바뀜 |

<a id="props-parameters"></a>

## API

`W`는 위젯 슬롯의 타입으로, Flutter에서는 `Widget`, 웹에서는 `Component`입니다.

### NavigationBar 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `items` | `List<CoreNavigationBarItem<W>>` | 필수 | 목적지 · 구획 제목 · 구분선 · 빈 간격 목록 |
| `selectedIndex` | `int?` | `null` | 선택된 목적지의 번호(목적지만 셈). `null`이면 선택 없음 |
| `onSelected` | `CoreValueChanged<int>?` | `null` | 목적지를 누르면 그 번호로 불림 |
| `mode` | `CoreNavigationBarMode` | `bar` | `bar` · `rail` · `sidebar`(0.164 부터 예고) |
| `variant` | `CoreNavigationBarVariant` | `standard` | 지금은 `standard` 하나 |
| `labelMode` | `CoreNavigationLabelMode?` | 모드의 값 | `all` · `selected` · `none` |
| `labelPosition` | `CoreNavigationLabelPosition?` | 모드의 값 | 아이콘에 대한 라벨 위치 `bottom` · `top` · `start` · `end` |
| `alignment` | `CoreNavigationAlignment` | `center` | 주축에서 남는 자리를 나누는 방식 |
| `overflow` | `CoreNavigationOverflow` | `ellipsis` | 라벨이 넘칠 때 `clip` · `ellipsis` · `none` |
| `selectionMark` | `CoreNavigationSelectionMark` | `none` | `dot`이면 라벨을 위아래로 쌓은 목적지(바 · 레일)의 내용 위에 선택 점 |
| `indicator` | `CoreNavigationSelectionIndicator?` | 모드의 값 | `fill` · `color`. 바는 `color`, 레일 · 사이드바는 `fill`, 리퀴드 글래스의 바 · 레일은 `color` |
| `compact` | `CoreNavigationCompact` | `never` | `never` · `onScroll` · `always` |
| `header` | `W?` | `null` | 목적지 앞에 두는 내용. 바의 바탕 · 선 · 여백 안에 들어가고 스크롤하지 않음 |
| `footer` | `W?` | `null` | 목적지 뒤에 두는 내용. 바의 바탕 · 선 · 여백 안에 들어가고 스크롤하지 않음 |
| `navigationBarStyle` | `CoreNavigationBarStyle?` | `null` | 보이는 값 덮어쓰기 |

### CoreNavigationBarItem

| 팩토리 | 설명 |
| --- | --- |
| `CoreNavigationBarItem.destination({icon, label, badge, tooltip, enabled, showDot})` | 선택할 수 있는 목적지. `enabled`는 `true`, `showDot`은 `false`가 기본값 |
| `CoreNavigationBarItem.label(String)` | 선택할 수 없는 구획 제목 |
| `CoreNavigationBarItem.divider()` | 구분선 |
| `CoreNavigationBarItem.gap(double)` | 빈 간격. `const`가 아닙니다 |
| `CoreNavigationBarItem.gapStyled(CoreGapStyle)` | `CoreGapStyle`로 정하는 빈 간격 |

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `kind` | `CoreNavigationItemKind` | `item` · `label` · `divider` · `gap` |
| `icon` | `W?` | 목적지의 아이콘 |
| `label` | `String?` | 목적지 이름이나 구획 제목. 목적지의 접근 가능한 이름 |
| `badge` | `W?` | 개수 같은 표시 |
| `tooltip` | `String?` | 라벨이 화면에 없을 때의 툴팁 문구. 없으면 `label` |
| `enabled` | `bool` | `false`면 누를 수 없는 목적지 |
| `showDot` | `bool` | 아이콘의 알림 점. `badge`가 있으면 그리지 않음 |
| `gapStyle` | `CoreGapStyle?` | 빈 간격의 크기 · 모양 |

<a id="스타일-시스템-style-system"></a>

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreNavigationBarStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `surfaceStyle` | `CoreSurfaceStyleId?` | Surface style (material) override for the navigation bar. `null` inherits the theme's surface style; `defaultStyle` removes the glass. |
| `backgroundColor` | `CoreColor?` | Background colour of the navigation container surface. |
| `padding` | `CoreEdgeInsets?` | Outer padding of the navigation container. |
| `barRadius` | `CoreBorderRadius?` | The bar's own corners. `null` leaves the bar square, which is what a bar docked to an edge wants (a liquid-glass bar or rail takes its capsule from [glassStyleFor]). |
| `barMargin` | `CoreEdgeInsets?` | Space outside the bar. |
| `barBorderColor` | `CoreColor?` | Colour of the bar's content-facing hairline. |
| `barBorderWidth` | `double?` | Thickness of the bar's content-facing hairline (logical px). |
| `itemSpacing` | `double?` | Gap between adjacent navigation items (logical px). |
| `itemPadding` | `CoreEdgeInsets?` | Inner padding of a navigation item. |
| `itemRadius` | `CoreBorderRadius?` | Corner radius of a navigation item. |
| `itemMinHeight` | `double?` | Minimum height of a navigation item (logical px). |
| `itemMaxWidth` | `double?` | Maximum width of a navigation item (logical px). |
| `iconOnlyItemMinHeight` | `double?` | Minimum painted height of a stacked destination that hides its label (logical px). Defaults to [defaultIconOnlyItemMinHeight]; a stated [itemMinHeight] reaches these destinations too when this is `null`. |
| `iconOnlyItemMinWidth` | `double?` | Minimum painted width of a stacked destination that hides its label (logical px). Defaults to [defaultIconOnlyItemMinWidth]. |
| `touchTargetSize` | `double?` | Smallest region, on either axis, that accepts a pointer around a stacked destination (logical px) — hit testing only, nothing painted moves. Defaults to [defaultTouchTargetSize]. |
| `labelSpacing` | `double?` | Native flex `spacing` between an item's icon and its label — passed directly to `Row.spacing` / `Column.spacing` (Flutter) and the inner flex `gap` (Web). Not wrapped in `Gap` (logical px). |
| `iconStyle` | `CoreIconStyle?` | Navigation item icon style override. `size` defers to [defaultIconStyle]. |
| `disabledIconStyle` | `CoreIconStyle?` | Icon style for a disabled destination, laid over the [iconStyle] in effect. Defaults to [defaultDisabledIconStyle]. |
| `badgeIndicatorStyle` | `CoreIndicatorStyle?` | Style for the `Indicator` that places a destination's `badge` over its icon in the bar and the rail. Laid over [defaultBadgeIndicatorStyle] and passed to the `Indicator` as is; it fills in the rest. |
| `selectedBackgroundColor` | `CoreColor?` | Background colour of the selected item — the whole tile, stacked or a row. |
| `selectedLabelTextStyle` | `CoreTextStyle?` | Label text style override for a selected item. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `selectedForegroundColor` field removed). Defaults to [defaultSelectedLabelTextStyle]. |
| `hoverBackgroundColor` | `CoreColor?` | Background colour applied to an item on hover. Defaults to [defaultHoverBackgroundColor] — transparent, i.e. no swap. Set it to paint a fill on hover INSTEAD of [stateLayer]; the two do not stack. |
| `stateLayer` | `CoreStateLayer?` | Ramp laid over the bar while a destination is hovered, focused or pressed. Defaults to [defaultStateLayer]. |
| `stateLayerColor` | `CoreColor?` | Ink [stateLayer] lays over the bar. Defaults to [defaultStateLayerColor]. |
| `labelTextStyle` | `CoreTextStyle?` | Label text style override for an unselected item. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `foregroundColor` field removed). Defaults to [defaultLabelTextStyle]. |
| `disabledLabelTextStyle` | `CoreTextStyle?` | Label text style override for a disabled item. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `disabledForegroundColor` field removed). Defaults to [defaultDisabledLabelTextStyle]. |
| `disabledSelectedLabelTextStyle` | `CoreTextStyle?` | Label text style override for a destination that is selected AND disabled, layered over [disabledLabelTextStyle]. Defaults to [defaultDisabledSelectedLabelTextStyle]. |
| `sectionLabelTextStyle` | `CoreTextStyle?` | Text style override for a non-selectable section header. The semibold weight and `onSurfaceSubtle` colour live in the [defaultSectionLabelTextStyle] overlay; this slot tweaks them per instance. Defaults to [defaultSectionLabelTextStyle]. |
| `sectionLabelPadding` | `CoreEdgeInsets?` | Inset around a non-selectable section header. Defaults to [defaultSectionLabelPadding]. |
| `dividerColor` | `CoreColor?` | Colour of a navigation divider line. |
| `dividerThickness` | `double?` | Thickness of a navigation divider line (logical px). |
| `duration` | `Duration?` | Colour-transition duration for item hover / selection. |
| `clickableStyle` | `CoreClickableStyle?` | Style for each destination's `Clickable` — press scale, focus ring, cursor, keyboard activation. Laid over [defaultClickableStyle] and passed to the `Clickable` as is; it fills in the rest. |
| `selectionMarkStyle` | `CoreBadgeStyle?` | Style for the selection-mark dot. Laid over [defaultSelectionMarkStyle] and passed as is to the `Badge(form:.dot)` that draws it. Read only while the bar's `selectionMark` is `dot`. |
| `selectionMarkGapStyle` | `CoreGapStyle?` | Space between the selection-mark dot and the content under it. Laid over [defaultSelectionMarkGapStyle] and passed as is to `Gap`. |
| `disabledSelectionMarkStyle` | `CoreBadgeStyle?` | Badge style laid over the selection-mark dot of a selected, disabled destination — on top of the [selectionMarkStyle] in effect and [defaultDisabledSelectionMarkStyle]. |
| `selectedIconStyle` | `CoreIconStyle?` | Icon style for the selected destination, laid over the [iconStyle] in effect (size from there, colour from here). Defaults to [defaultSelectedIconStyle], with the indicator's own colour ([defaultsByIndicator]) between the two. |
| `hoverForegroundColor` | `CoreColor?` | Foreground (label and icon) colour of a hovered, unselected destination. Defaults to [defaultHoverForegroundColor] — the transparent sentinel, which leaves the resting foreground in place; the `color` indicator states `onSurface` in [defaultsByIndicator]. |
| `selectedIconAnchorColor` | `CoreColor?` | **Deprecated (since 0.184)** — No pill is drawn — the selected destination paints its whole tile. Use selectedBackgroundColor. No longer read: no destination draws a pill — a selected destination paints its whole tile in [selectedBackgroundColor]. |
| `selectedIconAnchorIconStyle` | `CoreIconStyle?` | **Deprecated (since 0.184)** — No pill is drawn — the selected destination paints its whole tile. Use selectedIconStyle. No longer read: the selected glyph takes [selectedIconStyle]. |
| `disabledSelectedBackgroundColor` | `CoreColor?` | Face of a destination that is selected AND disabled — the whole tile. Defaults to [defaultDisabledSelectedBackgroundColor], with the indicator's own ([defaultsByIndicator]) between the two. |
| `disabledSelectedIconAnchorColor` | `CoreColor?` | **Deprecated (since 0.184)** — No pill is drawn — the selected destination paints its whole tile. Use disabledSelectedBackgroundColor. No longer read: a selected and disabled destination dims its whole tile to [disabledSelectedBackgroundColor]. |
| `iconAnchorPadding` | `CoreEdgeInsets?` | Inset of the box around a stacked destination's icon. Defaults to [defaultIconAnchorPadding]. |
| `iconAnchorRadius` | `CoreBorderRadius?` | **Deprecated (since 0.184)** — No pill is drawn — the selected face takes the tile's itemRadius. No longer read: the selected face takes the tile's [itemRadius]. |
| `notificationDotStyle` | `CoreBadgeStyle?` | Style for a destination's notification dot (`showDot`). Laid over [defaultNotificationDotStyle] and passed as is to the `Badge(form:.dot)` that draws it. |
| `notificationDotIndicatorStyle` | `CoreIndicatorStyle?` | Style for the `Indicator` that places the notification dot over the icon's top-end corner. Laid over [defaultNotificationDotIndicatorStyle] and passed to the `Indicator` as is. |
| `compactScale` | `double?` | Size the bar is drawn at while it is compact, as a factor of its resting size. `null` uses [defaultCompactScale] — `1`, so a docked bar does not change — and the floating glass bar states [glassCompactScale]. |
| `compactDuration` | `Duration?` | Time the bar takes to reach or leave its compact size. `null` uses [defaultCompactDuration]. |

### `CoreNavigationBarStyle` 변형별 기본값 (`CoreNavigationBarVariantStyle`)

| 필드 | `standard` |
|------|------|
| `backgroundColor` | surfaceContainerLow |

<!-- STYLE_TABLE:END -->

<Note>

생성된 표와 지금 동작이 다른 점: 하단 바의 바탕은 `bar` 모드의 값 `surface`입니다(표의 `standard` 바탕 `surfaceContainerLow`는 레일 · 사이드바에 쓰입니다). 리퀴드 글래스에서는 선택 아이콘이 `selectedIconStyle`을 따르지 않는 경우가 있습니다([알려진 제약](#알려진-제약)). 표에서 알림 점을 아이콘의 끝 위 모서리에 놓는다고 적은 것과 달리, 오른쪽에서 왼쪽으로 쓰는 언어에서도 점은 오른쪽 위에 놓입니다. `hoverBackgroundColor`와 상태 레이어는 플랫폼마다 적용 범위가 다릅니다([플랫폼 차이](#플랫폼-차이)).

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="navigation-bar/related-item" title="NavigationBarItem">

바가 목적지마다 그리는 항목입니다. 바 밖에서 목록을 직접 만들 때 씁니다. [NavigationBarItem 문서](/components/navigation-bar-item)

</Card>
<Card title="Sidebar">

헤더 · 검색 · 구역 · 그룹 · 레일을 갖춘 옆 내비게이션입니다. [Sidebar 문서](/components/sidebar)

</Card>
<Card component="tabs" props="variant=underline" title="Tabs">

같은 화면 안에서 보기를 바꿉니다. [Tabs 문서](/components/tabs)

</Card>
<Card title="NavigationMenu">

드롭다운 패널이 있는 가로 메가 메뉴입니다. [NavigationMenu 문서](/components/navigation-menu)

</Card>
</Cards>
