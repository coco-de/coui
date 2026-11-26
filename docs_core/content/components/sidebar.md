---
title: Sidebar
description: 사이드바 — 앱의 신원 · 검색 · 메뉴 · 계정을 담는 옆 내비게이션
category: navigation
platforms: [flutter, web]
related: [navigation-bar, navigation-bar-item, tabs]
tags: [navigation, sidebar, rail, menu]
template: v2
source: navigation/sidebar
---

# Sidebar

<a id="live-preview"></a>

## 플레이그라운드

속성을 바꿔 가며 사이드바의 세 형태를 확인하고, 만들어진 코드를 복사하세요. 패널의 메뉴 행(하위 행 포함)이나 레일 위쪽의 목적지를 누르면 선택이 옮겨 갑니다. 도움말 행과 레일 맨 아래의 설정 칸은 눌러도 선택이 옮겨 가지 않습니다.

<Playground component="sidebar" />

`Sidebar`는 영역만 나누고 행을 직접 그리지 않으며, 선택도 기억하지 않습니다. 지금 있는 곳의 부품에 `selected: true`를 주고 `onPressed`에서 값을 바꿔 다시 그립니다. 패널의 위아래 영역은 고정되고 가운데 본문만 스크롤하므로, 높이가 정해진 부모 안에 둡니다.

<Note>

`collapsed`는 레일만 그리므로 검색 · 도움말 · 사용자 · 하위 그룹 · 개수 배지를 켜고 꺼도 그림이 그대로입니다. 폭이 좁은 칸에서 Web 미리보기는 가로로 밀어 보고, Flutter 미리보기는 줄여 그립니다.

</Note>

<a id="기본-사용법-basic-usage"></a>

<Tabs groupId="platform">
<TabItem label="Flutter" value="flutter">

```dart
Sidebar(
  semanticLabel: '주 메뉴',
  header: SidebarHeader(
    leading: const Avatar(initials: 'C'),
    title: const Text('나음 병원'),
    subtitle: const Text('본원 · 관리자'),
    trailing: const Icon(LucideIcons.chevronsUpDown),
    onPressed: () {},
  ),
  search: SidebarSearch(
    placeholder: '검색',
    shortcut: const ['⌘', 'K'],
    onPressed: () {},
  ),
  children: [
    SidebarItem(
      leading: const Icon(LucideIcons.house),
      label: const Text('홈'),
      selected: true,
      onPressed: () {},
    ),
    const SidebarSection(label: Text('업무')),
    SidebarGroup(
      leading: const Icon(LucideIcons.folder),
      label: const Text('프로젝트'),
      children: [
        SidebarItem(
          level: CoreSidebarItemLevel.nested,
          label: const Text('디자인 시스템'),
          onPressed: () {},
        ),
      ],
    ),
  ],
)
```

</TabItem>
<TabItem label="Web" value="web">

```dart
Sidebar(
  semanticLabel: '주 메뉴',
  header: SidebarHeader(
    leading: Avatar(initials: 'C'),
    title: Text('나음 병원'),
    subtitle: Text('본원 · 관리자'),
    trailing: Icon(LucideIcons.chevronsUpDown),
    onPressed: () {},
  ),
  search: SidebarSearch(
    placeholder: '검색',
    shortcut: ['⌘', 'K'],
    onPressed: () {},
  ),
  children: [
    SidebarItem(
      leading: Icon(LucideIcons.house),
      label: Text('홈'),
      selected: true,
      onPressed: () {},
    ),
    SidebarSection(label: Text('업무')),
    SidebarGroup(
      leading: Icon(LucideIcons.folder),
      label: Text('프로젝트'),
      children: [
        SidebarItem(
          level: CoreSidebarItemLevel.nested,
          label: Text('디자인 시스템'),
          onPressed: () {},
        ),
      ],
    ),
  ],
)
```

</TabItem>
</Tabs>

<a id="구조-anatomy"></a>

## 구조

사이드바는 레일과 패널 두 열로 이루어지고, `type`이 어느 열을 그릴지 정합니다. 1번은 전체 틀이고, 나머지 번호의 이름은 `Sidebar`의 생성자 파라미터입니다. 첫 그림은 한 패널(`standard`)입니다.

<Anatomy demo="sidebar/anatomy">
<AnatomyItem part="container" name="Sidebar">

고정 폭의 틀입니다. 면과 끝쪽 경계선만 그립니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=header]" side="right" name="header">

패널 맨 위의 신원 행입니다. 보통 `SidebarHeader`를 넣습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=search]" side="right" name="search">

검색을 여는 버튼입니다. 보통 `SidebarSearch`를 넣습니다.

</AnatomyItem>
<AnatomyItem select="[aria-current=page]" side="right" name="children">

패널 본문의 행입니다. 이 영역만 스크롤합니다. 번호는 지금 있는 곳을 가리킵니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=footer]" side="right" name="footer">

도움말 위의 자리입니다. 사용량 카드나 업그레이드 안내를 넣습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=help]" side="right" name="help">

도움말 행입니다. 보통 `SidebarItem`입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=user]" side="right" name="user">

맨 아래의 로그인한 사람입니다. 보통 `SidebarHeader`입니다.

</AnatomyItem>
</Anatomy>

두 칸(`twoPane`)에는 레일과 패널 제목 줄이 더해집니다.

<Anatomy demo="sidebar/anatomy-two-pane">
<AnatomyItem part="container" name="Sidebar">

레일과 패널을 나란히 놓은 틀입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=rail-header]" side="left" name="railHeader">

레일 목적지 위의 표식(로고 타일)입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=rail-item]" side="left" name="railItems">

레일의 목적지입니다. 보통 `SidebarRailItem`을 넣습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=rail-footer]" side="left" name="railFooter">

레일 맨 아래 자리입니다. 설정이나 사람의 아바타를 넣습니다.

</AnatomyItem>
<AnatomyItem select="h2" side="top" name="panelTitle">

패널의 제목입니다. 두 칸에서는 보통 레일에서 고른 영역의 이름입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=panel-action]" side="right" name="panelAction">

제목 줄 끝의 동작입니다. `panelTitle`이 있을 때만 그립니다.

</AnatomyItem>
</Anatomy>

```text
standard    패널   위     header · panelTitle (+ panelAction) · search
                   본문   children (스크롤)
                   아래   footer · help · user
twoPane     레일          railHeader · railItems (스크롤) · railFooter
            패널          standard 와 같은 세 영역
collapsed   레일          railHeader · railItems (스크롤) · railFooter
```

- `header`와 `panelTitle`은 패널이 있는 두 형태 모두에서 그립니다. 위 영역은 `header` → `panelTitle` → `search` 순서입니다.
- 넣은 것이 없는 위 · 아래 영역은 그리지 않습니다.
- 패널의 위아래 영역은 고정되고 본문만 스크롤합니다. 레일에서는 목적지 목록만 스크롤합니다.
- 페이지와 맞닿는 끝쪽 경계선(`outlineVariant`, 1)은 가장 바깥 열이 그립니다. `collapsed`는 레일이, 나머지는 패널이 그립니다.

영역의 기본 여백은 다음과 같습니다. 괄호 안은 `CoreSidebarStyle` 필드입니다.

| 영역 | `standard` | `twoPane` | 안쪽 간격 |
| --- | --- | --- | --- |
| 패널 위 (`topPadding`) | 좌우 16 · 위 16 · 아래 12 | 좌우 12 · 위 16 · 아래 8 | 12 (`topSpacing`) |
| 본문 (`bodyPadding`) | 좌우 16 · 위 4 · 아래 12 | 좌우 12 · 위 4 · 아래 16 | 2 (`bodySpacing`) |
| 패널 아래 (`bottomPadding`) | 좌우 16 · 위 12 · 아래 16 | 같음 | 8 (`bottomSpacing`) |
| 레일 (`railPadding`) | – | 좌우 12 · 위아래 16 | 8 (`railSpacing`) |

`collapsed`의 레일 여백은 `twoPane`의 레일과 같습니다. 레일은 `railHeader` 뒤에 크기 8의 `Gap`(`railHeaderGapStyle`)을 하나 더 둡니다.

<a id="변형-variants"></a>

## Variant

`type`으로 세 형태 중 하나를 고릅니다. 기본값은 `standard`입니다.

| `type` | 열 | 폭 | 레일 면 | 패널 면 | 그리는 파라미터 |
| --- | --- | --- | --- | --- | --- |
| `standard` | 패널 | 248 | – | `surfaceContainerLow` | 패널 파라미터 |
| `twoPane` | 레일 + 패널 | 64 + 240 | `surfaceContainer` | `surfaceContainerLow` | 레일 · 패널 파라미터 |
| `collapsed` | 레일 | 64 | `surfaceContainerLow` | – | 레일 파라미터 |

레일 파라미터는 `railHeader` · `railItems` · `railFooter`이고, 패널 파라미터는 나머지 영역(`header`부터 `user`까지)입니다. 형태에 없는 열의 파라미터는 넣어도 그리지 않습니다.

<Note>

패널 면(`surfaceContainerLow`)은 흰 바탕(`surface`)과 차이가 작아, 패널의 가장자리가 흐리게 보일 수 있습니다. 웹 문서의 미리보기도 흰 바탕입니다.

</Note>

<a id="type-standard"></a>

### standard

한 패널입니다. 위에 신원과 검색, 가운데에 행, 아래에 도움말과 로그인한 사람을 둡니다.

<Preview demo="sidebar/standard" />

<a id="type-twopane"></a>

### twoPane

64 레일 옆에 240 패널을 놓습니다. 레일은 한 단 깊은 `surfaceContainer`로 칠해 두 열로 읽힙니다. 레일과 패널은 서로 연결되어 있지 않으므로, 레일을 눌렀을 때 패널의 제목과 행을 바꾸는 일은 앱이 합니다.

<Preview demo="sidebar/two-pane" />

<a id="type-collapsed"></a>

### collapsed

레일만 남깁니다. 각 목적지의 이름은 툴팁과 접근성 이름이 말합니다. 접기 버튼은 없습니다. 앱이 `type`을 바꿔 다시 그립니다.

<Preview demo="sidebar/collapsed" />

## 부품

행 · 제목 · 신원 · 검색 · 레일은 아래 부품으로 조합합니다. 각 부품은 자기 스타일을 가집니다.

| 부품 | 역할 |
| --- | --- |
| `SidebarItem` | 메뉴 한 줄 — 아이콘 · 이름 · 점 · 개수 · 뒤 아이콘 |
| `SidebarSection` | 행 묶음 위의 조용한 제목 |
| `SidebarGroup` | 하위 행을 접고 펴는 행 |
| `SidebarHeader` | 워크스페이스 또는 사람의 신원 행 (`plain` · `card`) |
| `SidebarSearch` | 검색을 여는 입력 모양의 버튼, 단축키는 `Kbd` |
| `SidebarRailItem` | 아이콘 레일의 정사각형 목적지 |

`W`는 Flutter에서 `Widget`, Web에서 `Component`입니다. Web의 부품은 `id` · `classes` · `css` · `attributes` · `eventHandlers`도 받습니다(`SidebarGroup`은 `eventHandlers`가 없습니다).

### `SidebarItem`

행은 `leading` → 이름 → `dot` → `count` → `trailing` 순서로 놓이고, 이름은 한 줄로 말줄임합니다. 모서리는 8이고, 쉬는 바탕은 비어 있습니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `W` | 필수 | 목적지 이름 |
| `leading` | `W?` | `null` | 이름 앞 아이콘 (18) |
| `count` | `W?` | `null` | 끝의 개수 — 보통 `Badge` |
| `trailing` | `W?` | `null` | 맨 끝 아이콘 (16) |
| `dot` | `bool` | `false` | 안 읽음 점 (`error`, 6) |
| `level` | `CoreSidebarItemLevel` | `top` | `top`은 높이 36 이상 · `labelLarge`, `nested`는 32 이상 · `labelMedium` |
| `selected` | `bool` | `false` | 지금 있는 곳 |
| `enabled` | `bool?` | `null` | `null`이면 `onPressed`가 있을 때만 켜집니다 |
| `onPressed` | `VoidCallback?` | `null` | 눌렀을 때 |
| `sidebarItemStyle` | `CoreSidebarItemStyle?` | `null` | 인스턴스 스타일 |

<Preview demo="sidebar/rows" />

<a id="나머지-부품"></a>

### `SidebarSection`

행 묶음 위의 제목입니다. 누를 수 없고 포커스를 받지 않습니다. 글자는 `labelSmall` · `onSurfaceSubtle` 한 줄이고, `action` 아이콘은 16입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `W` | 필수 | 묶음 이름 |
| `action` | `W?` | `null` | 제목 끝의 동작 |
| `sidebarSectionStyle` | `CoreSidebarSectionStyle?` | `null` | 인스턴스 스타일 |

### `SidebarGroup`

그룹 행은 `SidebarItem`에 펼침 화살표를 붙인 행입니다(열리면 `chevronDown`, 닫히면 `chevronRight`). 하위 행은 시작 쪽에서 28 들여쓰고, 시작 쪽에서 18 떨어진 곳에 1px `outlineVariant` 트리 선을 긋습니다. 하위 행 사이는 2입니다. 그룹은 하위 행의 `level`을 정해 주지 않으므로 `CoreSidebarItemLevel.nested`를 직접 줍니다. 그룹 행에는 `enabled` · `selected`가 없습니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `W` | 필수 | 그룹 이름 |
| `children` | `List<W>` | 필수 | 하위 행 |
| `leading` | `W?` | `null` | 이름 앞 아이콘 |
| `expanded` | `bool?` | `null` | 값을 주면 앱이 열림을 정합니다 |
| `initiallyExpanded` | `bool` | `true` | `expanded`가 없을 때 처음 상태 |
| `onExpandedChanged` | `ValueChanged<bool>?` | `null` | 행을 누를 때 새 열림 값. `expanded`를 줬는데 이 값이 없으면 열리고 닫히지 않습니다 |
| `sidebarGroupStyle` | `CoreSidebarGroupStyle?` | `null` | 인스턴스 스타일. 그룹 행은 `itemStyle` |

### `SidebarHeader`

위쪽의 워크스페이스나 아래쪽의 사람을 보여 줍니다. 제목은 `labelLarge` · 600, 부제목은 `bodyXs` · `onSurfaceVariant`이고 각각 한 줄입니다. `plain`은 바탕과 테두리가 없고, `card`는 `surface` 바탕에 `outlineSubtle` 1px 테두리를 가집니다. `onPressed`가 없으면 역할도 포커스도 없는 글입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `title` | `W` | 필수 | 이름 |
| `variant` | `CoreSidebarHeaderVariant` | `plain` | `plain` · `card` |
| `leading` | `W?` | `null` | 로고 타일이나 `Avatar` |
| `subtitle` | `W?` | `null` | 둘째 줄 |
| `trailing` | `W?` | `null` | 끝 아이콘 (16) — 보통 전환 화살표 |
| `onPressed` | `VoidCallback?` | `null` | 눌렀을 때 |
| `sidebarHeaderStyle` | `CoreSidebarHeaderStyle?` | `null` | 인스턴스 스타일 |

<Preview demo="sidebar/headers" />

### `SidebarSearch`

입력창처럼 생긴 버튼입니다. 글자를 입력받지 않으며, 누르면 앱이 검색 화면(예: [Command](/components/command))을 엽니다. `surface` 바탕에 `outlineSubtle` 1px 테두리, 높이 36 이상, 검색 아이콘 16이고 안내 글은 `bodySmall`입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `placeholder` | `String` | 필수 | 안내 글이자 접근성 이름 |
| `shortcut` | `List<String>?` | `null` | `Kbd`로 그리는 단축키 |
| `onPressed` | `VoidCallback?` | `null` | 눌렀을 때. `null`이면 눌리지 않습니다 |
| `sidebarSearchStyle` | `CoreSidebarSearchStyle?` | `null` | 인스턴스 스타일. 단축키 모양은 `kbdStyle` |

### `SidebarRailItem`

크기 40의 정사각형 목적지입니다. 다만 Flutter의 `collapsed` 레일에서는 폭이 39로 좁아집니다(알려진 제약에 있습니다). 아이콘은 20이고 모서리는 10입니다. 화면에는 아이콘만 보이며, `label`은 접근성 이름과 옆으로 뜨는 툴팁이 됩니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `icon` | `W` | 필수 | 아이콘 |
| `label` | `String` | 필수 | 목적지 이름 |
| `dot` | `bool` | `false` | 안 읽음 점 (`error`, 6) |
| `selected` | `bool` | `false` | 지금 있는 곳 |
| `enabled` | `bool?` | `null` | `null`이면 `onPressed`가 있을 때만 켜집니다 |
| `onPressed` | `VoidCallback?` | `null` | 눌렀을 때 |
| `sidebarRailItemStyle` | `CoreSidebarRailItemStyle?` | `null` | 인스턴스 스타일 |

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>
<a id="상태-전환"></a>

## 상태

누를 수 있는 부품은 `SidebarItem` · `SidebarRailItem` · `SidebarSearch`, `SidebarGroup`의 그룹 행, 그리고 `onPressed`가 있는 `SidebarHeader`입니다. 그림은 패널 폭을 160으로 줄였습니다.

<Preview demo="sidebar/states" />

아래 표의 색은 `SidebarItem`(그룹 행 포함)과 `SidebarRailItem`의 것입니다. `SidebarHeader`(제목은 `onSurface`, 부제목과 끝 아이콘은 `onSurfaceVariant`)와 `SidebarSearch`(`surface` 바탕에 아이콘과 안내 글은 `onSurfaceSubtle`)는 이 표를 따르지 않고, 선택 상태와 비활성 색이 없습니다. hover · focus · press의 상태 레이어는 누를 수 있는 부품이 모두 같이 씁니다.

| 상태 | 글자와 아이콘 | 바탕 |
| --- | --- | --- |
| 기본 | `onSurfaceSubtle` | 비어 있음 |
| 선택됨 | `onSurface`, 행 이름은 SemiBold | 행은 `surfaceContainer`, 레일 칸은 `surfaceContainerHigh` |
| 비활성 | `disabledContent` | 비어 있음 |
| hover · focus · press | 그대로 | `onSurface` 상태 레이어 3% · 8% · 12% |

- 행 끝의 `trailing` 아이콘은 선택돼도 `onSurfaceSubtle`입니다.
- 비활성 부품은 `selected: true`를 줘도 선택으로 그리지 않습니다. 점과 개수는 비활성에서도 그대로 보입니다.
- `onPressed`가 없는 `SidebarSearch`는 눌리지 않지만 모양은 켜진 것과 같습니다.
- focus 레이어는 키보드로 포커스를 옮겼을 때만 칠합니다. 겹치면 press, focus, hover 순서로 이깁니다.
- `Enter` · `Space`로 누를 때 press 레이어는 Flutter만 칠합니다.
- 누르는 동안 부품은 살짝(0.97) 작아집니다.

<a id="애니메이션"></a>

### 전환 시간

- 선택된 행과 레일 칸의 바탕 전환은 Flutter에서 150ms, Web에서 100ms입니다. 상태 레이어는 바로 나타납니다.
- `SidebarGroup`이 열리고 닫히는 시간은 `CoreDuration.normal`(200ms)입니다. 동작 줄이기에서는 두 플랫폼 모두 0입니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

- 메뉴가 많고 구역 · 하위 그룹이 필요한 관리자 · 업무 화면에 씁니다.
- 글이 시작하는 쪽(왼쪽, 오른쪽에서 왼쪽으로 쓰는 언어에서는 오른쪽)에 늘 머무는 내비게이션에 씁니다. 위치는 앱의 레이아웃이 정합니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 화면 아래 탭 바나 좁은 레일만 필요할 때 | [NavigationBar](/components/navigation-bar). 그 `CoreNavigationBarMode.sidebar`는 지원 중단 예정(`@Deprecated`)이고 대체재가 `Sidebar`입니다. |
| 화면 일부의 보기를 바꿔 볼 때 | [Tabs](/components/tabs) |
| 목적지를 검색해 바로 실행할 때 | [Command](/components/command). `SidebarSearch`는 검색을 여는 버튼일 뿐입니다. |
| 버튼을 눌러 잠깐 여는 메뉴가 필요할 때 | [DropdownMenu](/components/dropdown-menu) |

<a id="do"></a>
<a id="dont"></a>

### 지금 있는 곳과 하위 행

<Cards columns="2">
<Card demo="sidebar/do-one-selected" tone="do" eyebrow="이렇게 하세요">

`selected`는 지금 있는 곳 하나에만 줍니다.

</Card>
<Card demo="sidebar/dont-many-selected" tone="dont" eyebrow="이렇게 하지 마세요">

여러 행을 선택하면 지금 있는 곳을 알 수 없습니다.

</Card>
<Card demo="sidebar/do-sub-level" tone="do" eyebrow="이렇게 하세요">

그룹 안의 행에는 `level: CoreSidebarItemLevel.nested`를 줍니다.

</Card>
<Card demo="sidebar/dont-top-level-rows" tone="dont" eyebrow="이렇게 하지 마세요">

기본 `top`을 그대로 두면 하위 행이 상위 행과 같은 높이 · 글자가 되어 위계가 흐려집니다.

</Card>
</Cards>

- 눌러야 하는 패널 동작은 `panelAction`에 이름이 있는 버튼을 넣습니다. `panelAction`은 자리와 아이콘 크기 · 색만 주고, 누르기나 이름을 만들지 않습니다. `twoPane` 미리보기의 `+`는 모양만인 아이콘입니다.
- 레일 칸의 `label`은 짧고 정확하게 씁니다. 화면에는 아이콘만 보입니다.
- 안 읽음 상태는 점으로만 알리지 말고 개수(`count`)나 이름에도 담습니다. 점은 보조 기술에 전해지지 않습니다.
- 사용량 카드 같은 제품 콘텐츠는 사이드바 부품으로 만들지 않고, `footer`에 `Card` · `Progress`를 조합해 넣습니다.

<a id="조합-예제"></a>

```dart
Sidebar(
  footer: Card(
    child: Progress(value: 0.6),
  ),
  children: rows,
)
```

## 배치

사이드바는 폭이 고정이고 부모의 높이를 채웁니다. 앱의 가로 배치에서 첫 자리에 놓고, 나머지 폭을 화면 내용에 줍니다. 아래 그림은 좁은 칸에 맞춰 패널 폭을 160으로 줄였고, 행이 많아 본문만 스크롤합니다.

<Preview demo="sidebar/placement" />

| 항목 | 규칙 |
| --- | --- |
| 폭 | `standard` 248, `twoPane` 304 (레일 64 + 패널 240), `collapsed` 64 |
| 높이 | 부모의 높이를 채웁니다. 위아래 영역은 고정되고 본문만 스크롤합니다. |
| 높이가 정해지지 않은 부모 | Flutter는 레이아웃 오류가 납니다. Web은 내용만큼 늘어나고 본문이 따로 스크롤하지 않습니다. |
| 경계선 | 끝쪽(글 방향의 끝)에 긋습니다. 오른쪽에서 왼쪽으로 쓰는 언어에서는 왼쪽입니다. |

<a id="스타일-시스템-style-system"></a>
<a id="테마로-덮어쓰기"></a>

## 테마와 스타일

`type`은 위젯 속성으로 고릅니다. 틀의 면 · 경계 · 폭 · 영역 여백은 `sidebarStyle`로, 부품의 모양은 각 부품의 스타일로 덮어씁니다.

사이드바 하나만 바꿀 때는 `sidebarStyle`을 넘깁니다.

```dart
Sidebar(
  sidebarStyle: const CoreSidebarStyle(
    panelWidth: CoreLayout.layout280,
    backgroundColor: CoreColor.token(CoreColors.surface),
  ),
  children: rows,
)
```

앱 전체의 기본값은 `coreComponentTheme`로 바꿉니다. Flutter에서는 아래처럼 `ThemeData.fromCore`에 넘깁니다.

```dart
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    sidebar: CoreSidebarTheme(
      style: CoreSidebarStyle(panelWidth: CoreLayout.layout280),
    ),
    sidebarItem: CoreSidebarItemTheme(
      variantStyles: {
        CoreSidebarItemLevel.nested: CoreSidebarItemStyle(
          minHeight: CoreSize.size28,
        ),
      },
    ),
  ),
)
```

`collapsed`는 패널이 없으므로 `backgroundColor`가 닿지 않습니다. 레일 면은 `railBackgroundColor`로 바꿉니다.

### 부분마다 바꾸는 값

| 바꾸려는 것 | 위젯 파라미터 | 앱 전체 (`CoreComponentTheme`) |
| --- | --- | --- |
| 틀 · 레일 · 영역 여백 | `sidebarStyle` | `sidebar` |
| 메뉴 행 | `sidebarItemStyle` | `sidebarItem` |
| 행 묶음 제목 | `sidebarSectionStyle` | `sidebarSection` |
| 하위 그룹 (들여쓰기 · 트리 선 · 그룹 행) | `sidebarGroupStyle` | `sidebarGroup` (그룹 행에는 `sidebarItem`도 닿습니다) |
| 신원 행 | `sidebarHeaderStyle` | `sidebarHeader` |
| 검색 버튼 | `sidebarSearchStyle` | `sidebarSearch` |
| 레일 칸 | `sidebarRailItemStyle` | `sidebarRailItem` |

### 빠른 덮어쓰기

이미 만든 `Sidebar`에 `withStyle`로 스타일 조각을 덧붙일 수 있습니다. 생성자의 `sidebarStyle`과 같은 자리이고, 나중에 이은 값이 같은 필드에서 이깁니다. 부품에도 각각 `withStyle`이 있습니다. 사이드바와 부품에는 `.surface`처럼 토큰 이름을 딴 짧은 getter는 없습니다.

<Preview component="sidebar" example="chain" />

```dart
Sidebar(children: rows).withStyle(
  const CoreSidebarStyle(
    panelWidth: CoreLayout.layout240,
    backgroundColor: CoreColor.token(CoreColors.surface),
  ),
)
```

<a id="resolve-chain"></a>

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
CoreSidebarStyle.defaultX / defaultsByType[type]     // 디자인 시스템 기본값
  → CoreSidebarTheme.style                           // 앱 전체
  → CoreSidebarTheme.variantStyles[type]             // 형태별
  → widget.sidebarStyle                              // 인스턴스

CoreSidebarItemStyle.defaultX / defaultsByLevel[level]
  → CoreSidebarItemTheme.style
  → CoreSidebarItemTheme.variantStyles[level]
  → widget.sidebarItemStyle
```

<a id="접근성-accessibility"></a>

## 접근성

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은
> [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

### 역할

| 부분 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Sidebar` | `semanticLabel`이 있으면 navigation 랜드마크 | `<nav>`. `semanticLabel`이 있으면 `aria-label` |
| `SidebarItem` · `SidebarRailItem` | 버튼. 지금 있는 곳은 selected | `role="button"`. 지금 있는 곳은 `aria-current="page"`, 비활성은 `aria-disabled="true"` |
| `SidebarGroup` 행 | 버튼이며 expanded 상태를 가집니다 | `role="button"` · `aria-expanded` |
| `SidebarSection` | 제목(header) — `action`까지 한 묶음 | `label`만 `<h2>` |
| `panelTitle` | 제목(header) | `<h2>` |
| `SidebarHeader` | `onPressed`가 있으면 버튼 | `onPressed`가 있으면 `role="button"` |
| `SidebarSearch` | 버튼 | `role="button"` |

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift+Tab` | 누를 수 있는 부품을 차례로 지납니다. 비활성 부품은 건너뜁니다. |
| `↓` · `↑` | 다음 · 이전 부품으로 옮깁니다. 범위는 플랫폼마다 다릅니다(아래). |
| `Enter` · `Space` | 포커스된 부품을 누릅니다. |

- Web은 포커스가 이미 `role="button"` 요소에 있을 때만 움직입니다. 사이드바 안의 켜진 `role="button"` 요소를 문서 순서(레일 먼저)로 지나고 처음과 끝에서 멈춥니다. 네이티브 `<button>`으로 그려지는 `Button`은 `role` 속성이 없어 건너뜁니다. `eventHandlers`의 `keydown`에서 `preventDefault()`하면 옮기지 않습니다.
- Flutter는 `↓` · `↑`를 `NextFocusIntent` · `PreviousFocusIntent`로 바꿔 앱의 포커스 순서를 따라 옮깁니다. 처음과 끝에서 멈추지 않아 사이드바 밖의 컨트롤로 나갈 수 있습니다.

### 스크린 리더

- `semanticLabel`로 내비게이션의 이름을 붙입니다.
- 안 읽음 점은 두 플랫폼 모두 보조 기술에서 숨깁니다.
- `count`는 위젯이라 그 안의 글자가 행 이름에 이어집니다.
- `SidebarRailItem`은 보이는 이름이 없어 `label`이 접근성 이름입니다.
- `SidebarSearch`는 `placeholder`가 접근성 이름입니다. 단축키 그림은 읽지 않으며, Web은 `aria-keyshortcuts`를 붙입니다(값의 한계는 알려진 제약에 있습니다).
- 닫힌 `SidebarGroup`의 하위 행은 Web에서는 DOM에 남지만 `inert`라 키보드와 보조 기술에 닿지 않고, Flutter에서는 트리에서 빠집니다.

### 포커스 관리

포커스 링은 각 부품의 모서리를 따릅니다(`Clickable`). 키보드 포커스에서는 상태 레이어(8%)도 함께 칠합니다. 사이드바는 포커스를 스스로 옮기거나 가두지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 선택되지 않은 행과 묶음 제목(`SidebarSection`)의 `onSurfaceSubtle`은 라이트 테마의 `surfaceContainerLow` 위에서 글자 대비 4.5 : 1에 못 미칩니다. `Tabs`의 선택되지 않은 라벨과 같이 받아들인 예외입니다. 지금 있는 곳은 `onSurface`라 해당하지 않습니다. |
| 공통 | 안 읽음 점은 보조 기술에 전해지지 않습니다. |
| 공통 | `SidebarRailItem`의 툴팁은 포인터를 올릴 때만 뜹니다. 키보드 포커스나 길게 누르기로는 이름이 보이지 않습니다. |
| 공통 | `SidebarRailItem`의 점은 글 방향과 상관없이 오른쪽 위에 놓입니다. |
| 공통 | 닫힌 `SidebarGroup`의 화살표는 글 방향과 상관없이 오른쪽을 가리킵니다. |
| 공통 | `onPressed`가 없는 `SidebarSearch`는 눌리지 않지만 모양이 같습니다. |
| 공통 | `SidebarSearch`의 `shortcut`은 그리기만 합니다. 키를 눌렀을 때 검색을 여는 일은 앱이 연결합니다. |
| 공통 | `panelAction`은 `panelTitle`이 없으면 알림 없이 그려지지 않습니다. |
| 공통 | 닫힌 그룹 안에서 선택된 행이 있어도 그룹 행에는 표시가 없어, 지금 있는 곳이 보이지 않습니다. |
| Jaspr Web | `aria-keyshortcuts` 값은 `shortcut`을 `+`로 이은 글자(`⌘+K`)라서 ARIA의 키 이름(`Meta+K`)이 아닙니다. |
| Flutter | `collapsed`에서는 레일의 끝쪽 경계선이 안쪽 폭을 39로 줄여, 레일 칸이 40 × 40이 아니라 39 × 40이 됩니다. Web은 40 × 40을 그대로 그리고 좌우로 0.5씩 넘칩니다. `twoPane`의 레일에는 선이 없어 두 플랫폼 모두 40 × 40입니다. |
| Flutter | `semanticLabel`이 없으면 navigation 랜드마크가 생기지 않습니다. |
| Flutter | `↓` · `↑`가 사이드바 밖으로 포커스를 옮길 수 있습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

공통 파라미터의 이름과 기본값은 두 플랫폼이 같습니다. 동작과 렌더링은 아래가 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 부모 높이 | 정해진 높이가 필요합니다 | 부모 높이를 채우고, 정해지지 않으면 내용만큼 늘어납니다 |
| 랜드마크 | `semanticLabel`이 있을 때만 navigation | 늘 `<nav>`, 이름은 `semanticLabel` |
| 화살표 이동 | 앱의 포커스 순서. 사이드바 밖으로 나갈 수 있습니다 | 사이드바 안의 `role="button"` 사이, 처음과 끝에서 멈춤 |
| 행 바탕 전환 | 150ms | 100ms |
| 그룹 여닫기 | `AnimatedSize`. 닫을 때 내용은 바로 사라지고 높이만 줄어듭니다. 닫힌 행은 트리에서 빠져 상태가 남지 않습니다 | `grid-template-rows` 전환. 닫힌 행은 DOM에 남고 `inert` |
| 묶음 제목의 범위 | 줄 전체(`action` 포함) | `label`만 `<h2>` |
| 상태 레이어 | 위젯이 hover · focus · press를 감지해 칠합니다. `Enter` · `Space`로 눌러도 press 레이어를 칠합니다 | 범위를 좁힌 `<style>` 규칙의 `:hover` · `:focus-visible` · `:active`가 칠합니다. `Enter` · `Space`로 누를 때는 press 레이어를 칠하지 않습니다(눌리며 작아지는 효과는 있습니다) |
| `collapsed` 레일 칸의 폭 | 39 (끝쪽 경계선만큼 좁아집니다) | 40 |
| 추가 파라미터 | – | `id` · `classes` · `css` · `attributes` · `eventHandlers` (`SidebarGroup`은 `eventHandlers` 없음) |
| 예제의 `Avatar` | `const`로 만들 수 있습니다 | `const` 생성자가 아닙니다 |

<a id="props-parameters"></a>

## API

`W`는 Flutter에서 `Widget`, Web에서 `Component`입니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `type` | `CoreSidebarType` | `standard` | `standard` · `twoPane` · `collapsed` |
| `header` | `W?` | `null` | 패널 맨 위의 신원 행 — 보통 `SidebarHeader` |
| `search` | `W?` | `null` | 검색을 여는 버튼 — 보통 `SidebarSearch` |
| `panelTitle` | `W?` | `null` | 패널 제목. 두 칸에서는 레일에서 고른 영역의 이름 |
| `panelAction` | `W?` | `null` | 제목 줄 끝의 동작. `panelTitle`이 있을 때만 그립니다 |
| `children` | `List<W>` | `[]` | 패널 본문의 행 |
| `footer` | `W?` | `null` | 도움말 위의 내용(사용량 카드 같은 것) |
| `help` | `W?` | `null` | 도움말 행 |
| `user` | `W?` | `null` | 맨 아래의 로그인한 사람 |
| `railHeader` | `W?` | `null` | 레일 맨 위의 표식(로고) |
| `railItems` | `List<W>` | `[]` | 레일의 목적지 — 보통 `SidebarRailItem` |
| `railFooter` | `W?` | `null` | 레일 맨 아래(설정 · 아바타) |
| `semanticLabel` | `String?` | `null` | 내비게이션 랜드마크의 접근성 이름 |
| `sidebarStyle` | `CoreSidebarStyle?` | `null` | 인스턴스 스타일 |

Web의 `Sidebar`는 `id` · `classes` · `css` · `attributes` · `eventHandlers`도 받습니다. 두 플랫폼 모두 `copyWith`와 `withStyle(CoreSidebarStyle patch)`가 있습니다.

### 테마

`CoreComponentTheme.sidebar`(`CoreSidebarTheme`)로 앱 전체를 바꿉니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CoreSidebarStyle?` | `null` | 모든 형태에 적용 |
| `variantStyles` | `Map<CoreSidebarType, CoreSidebarStyle>?` | `null` | 형태별로 적용 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreSidebarStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | The panel's face. `null` defers to [defaultBackgroundColor]. |
| `borderColor` | `CoreColor?` | The line on the edge that meets the page. `null` defers to [defaultBorderColor]. |
| `borderWidth` | `double?` | Width of the edge line (logical px). `null` defers to [defaultBorderWidth]. |
| `panelWidth` | `double?` | Width of the panel (logical px). `null` defers to the type's row in [defaultsByType]. |
| `railWidth` | `double?` | Width of the icon rail (logical px). `null` defers to [defaultRailWidth]. |
| `railBackgroundColor` | `CoreColor?` | The rail's face. `null` defers to the type's row in [defaultsByType]. |
| `railPadding` | `CoreEdgeInsets?` | The rail's insets. `null` defers to [defaultRailPadding]. |
| `railSpacing` | `double?` | Spacing between the rail's items. `null` defers to [defaultRailSpacing]. |
| `railHeaderGapStyle` | `CoreGapStyle?` | Extra room after the rail's header. `null` defers to [defaultRailHeaderGapStyle]. |
| `topPadding` | `CoreEdgeInsets?` | The top region's insets (header, search, panel title). `null` defers to the type's row in [defaultsByType]. |
| `topSpacing` | `double?` | Spacing between the top region's parts. `null` defers to [defaultTopSpacing]. |
| `bodyPadding` | `CoreEdgeInsets?` | The body's insets. `null` defers to the type's row in [defaultsByType]. |
| `bodySpacing` | `double?` | Spacing between the body's rows. `null` defers to [defaultBodySpacing]. |
| `bottomPadding` | `CoreEdgeInsets?` | The bottom region's insets. `null` defers to [defaultBottomPadding]. |
| `bottomSpacing` | `double?` | Spacing between the bottom region's parts. `null` defers to [defaultBottomSpacing]. |
| `panelTitleStyle` | `CoreTextStyle?` | The two-pane panel title's text. `null` defers to [defaultPanelTitleStyle]. |
| `panelTitlePadding` | `CoreEdgeInsets?` | Insets around the panel title row. `null` defers to [defaultPanelTitlePadding]. |
| `panelTitleSpacing` | `double?` | Spacing between the panel title and its action. `null` defers to [defaultPanelTitleSpacing]. |
| `panelActionIconStyle` | `CoreIconStyle?` | The panel title's action glyph. `null` defers to [defaultPanelActionIconStyle]. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="sidebar/related-navigation-bar" title="NavigationBar" href="/components/navigation-bar" more="NavigationBar 보기">

화면 아래 탭 바와 좁은 레일에 씁니다.

</Card>
<Card component="tabs" props="variant=pill" title="Tabs" href="/components/tabs" more="Tabs 보기">

화면 일부의 보기를 바꿉니다.

</Card>
<Card demo="sidebar/related-kbd" title="Kbd" href="/components/kbd" more="Kbd 보기">

`SidebarSearch`의 단축키 표시입니다.

</Card>
<Card title="Command" href="/components/command" more="Command 보기">

검색해서 바로 실행하는 명령 팔레트입니다. `SidebarSearch`를 눌렀을 때 여는 화면으로 씁니다.

</Card>
</Cards>
