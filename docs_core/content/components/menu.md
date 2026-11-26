---
title: Menu
description: 정적 메뉴 패널 컴포넌트
category: menu
platforms: [flutter, web]
related: [context-menu, dropdown-menu, menubar, popover]
tags: [navigation, action, interactive]
template: v2
source: menu/menu
---

# Menu

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 메뉴를 확인하고, 만들어진 코드를 그대로 복사하세요. 무대의 메뉴는 실제 `Menu` 입니다. `체크 · 라디오` 를 켜면 줄을 눌러 값을 바꿔 볼 수 있습니다.

<Playground component="menu" />

`Menu` 는 항목 목록을 테두리 있는 패널 하나에 담아, 문서 흐름 안의 놓인 자리에 그립니다. 항목은 `CoreMenuItem` 의 이름 있는 생성자로 만듭니다.

```dart
Menu(
  ariaLabel: '주 메뉴',
  items: [
    const CoreMenuItem.label('탐색'),
    CoreMenuItem.action('홈', onPressed: goHome, active: true),
    CoreMenuItem.action('프로필', onPressed: openProfile),
    const CoreMenuItem.divider(),
    CoreMenuItem.checkbox('격자 보기', checked: showGrid, onChanged: setShowGrid),
    const CoreMenuItem.action('설정', disabled: true),
  ],
)
```

- **열고 닫지 않습니다.** 트리거로 여는 메뉴는 [DropdownMenu](/components/dropdown-menu), 우클릭 메뉴는 [ContextMenu](/components/context-menu), 여러 메뉴를 가진 가로 바는 [Menubar](/components/menubar) 가 이 `Menu` 를 패널로 띄웁니다. 직접 만든 오버레이에 넣을 때는 `onActivate` 에 닫기를 연결합니다.
- **고른 값을 기억하지 않습니다.** checkbox · radio 는 `onChanged` 가 알려 주는 값으로 `checked` · `selected` 를 다시 넘겨야 화면이 바뀝니다.
- **콜백이 없는 줄은 저절로 비활성이 되지 않습니다.** `onPressed` · `onChanged` 를 주지 않아도 `disabled: true` 가 아니면 보통 줄처럼 그리고, 눌러도 아무 일이 일어나지 않습니다.
- **`href` 로는 이동하지 않습니다.** Jaspr Web 은 줄에 `data-href` 속성만 남기고, Flutter 는 이 값을 읽지 않습니다. 이동은 `onPressed` 에서 합니다.

## 구조

메뉴는 패널 상자와, 그 안에 위에서 아래로 놓이는 헤딩 · 줄 · 구분선으로 이루어집니다.

<Anatomy demo="menu/anatomy">
<AnatomyItem part="container" name="Panel">

항목을 담는 상자. [Popup](/components/popup) 의 겉모습으로 그립니다. 기본은 채움 `surfaceBright`, 테두리 `outlineVariant` 1, 모서리 12, 안쪽 여백 6, 줄 사이 2, 그림자 `CoreShadow.lg` 이고, 폭은 내용에 따라 240 에서 280 사이입니다.

</AnatomyItem>
<AnatomyItem select="[role=presentation]" side="left" name="label">

`CoreMenuItem.label` 로 만드는 헤딩. 누를 수 없고 `labelSmall`(12 Medium) 글자를 `onSurfaceSubtle` 색으로 그립니다.

</AnatomyItem>
<AnatomyItem select="[role=menuitem]" side="left" name="MenuItem">

누를 수 있는 줄. action · checkbox · radio 는 모두 [MenuItem](/components/menu-item) 한 줄로 그립니다.

</AnatomyItem>
<AnatomyItem select="[role=menuitem] > .co-menu-item-ink" side="right" name="shortcut">

줄 끝의 단축키 글자. 표시만 하며, 그 키를 눌렀을 때의 동작은 만들지 않습니다.

</AnatomyItem>
<AnatomyItem select="[role=separator]" side="right" name="divider">

항목 묶음을 나누는 [Divider](/components/divider).

</AnatomyItem>
<AnatomyItem select="[role=menuitemcheckbox] .co-menu-item-wash + div" side="left" name="mark">

checkbox · radio 의 표시가 놓이는 칸(16). 목록에 checkbox 나 radio 가 하나라도 있으면 누를 수 있는 모든 줄이 이 칸을 비워 두어 라벨 시작 위치가 맞습니다.

</AnatomyItem>
</Anatomy>

<a id="변형-variants"></a>

## 항목

항목은 `CoreMenuItem` 의 생성자로 종류를 고릅니다. `leading` · `trailing` 에 넘기는 타입은 Flutter 의 `Widget`, Jaspr Web 의 `Component` 입니다.

| 생성자 | 그리는 것 | 누를 수 있나 |
| --- | --- | --- |
| `CoreMenuItem.label` | 묶음의 헤딩 | 아니요 |
| `CoreMenuItem.action` | 동작을 실행하는 줄. `submenu` 를 주면 아래에 하위 목록이 펼쳐집니다. | 예 |
| `CoreMenuItem.checkbox` | 켜고 끄는 줄 | 예 |
| `CoreMenuItem.radio` | 여러 선택지 중 하나인 줄 | 예 |
| `CoreMenuItem.divider` | 구분선 | 아니요 |
| `CoreMenuItem.gap` | 정한 크기의 빈 간격 | 아니요 |

<a id="체크-라디오-항목"></a>

### 체크박스와 라디오

<Preview demo="menu/selection" />

```dart
Menu(
  items: [
    CoreMenuItem.checkbox('자동 저장', checked: autoSave, onChanged: setAutoSave),
    CoreMenuItem.radio('좁게', selected: density == 'narrow', onChanged: (_) => setDensity('narrow')),
    CoreMenuItem.radio('넓게', selected: density == 'wide', onChanged: (_) => setDensity('wide')),
  ],
)
```

| 항목 | checkbox | radio |
| --- | --- | --- |
| 누르면 | `onChanged(!checked)` | `onChanged(true)`. 고른 줄을 다시 눌러도 `true` 이므로 꺼지지 않습니다. |
| 켜진 줄 | 체크 표시와 `primary` 채움 | 점 표시(`CoreMenuRadioMark.dot`, 기본)와 `primary` 채움 |
| 메뉴 닫기 | `onActivate` 를 부르지 않습니다. | `onActivate` 를 부르지 않습니다. |

radio 의 `radioMark` 에 `CoreMenuRadioMark.check` 를 주면 고른 줄에 점 대신 체크를 그립니다. 한 설정의 선택지를 고르는 메뉴에 씁니다. 그림만 바뀌고 줄은 그대로 radio 입니다. 한 묶음에서 한 줄만 `selected: true` 가 되게 하는 것은 호출자의 일입니다.

<a id="위젯-슬롯-leading-trailing-은-위젯-그대로"></a>

### 설명 · 단축키 · 아이콘

<Preview demo="menu/description" />

| 값 | 받는 생성자 | 동작 |
| --- | --- | --- |
| `description` | action · checkbox · radio | 라벨 아래의 둘째 줄. 이 값이 있는 줄은 크기의 최소 높이보다 커집니다. |
| `shortcut` | action · radio | 줄 끝의 단축키 글자. 키를 등록하지 않습니다. `submenu` 가 있는 줄에서는 그리지 않습니다. |
| `leading` | action · label | 라벨 앞의 위젯. 누를 수 있는 줄에서는 그 안의 `Icon` 크기를 크기 단계가, 색을 줄의 글자색이 정합니다. |
| `standardAction` | action | 표준 명령의 기본 아이콘. `leading` 이 있으면 `leading` 을 그립니다. |
| `trailing` | label · action · checkbox · radio | 단축키와 셰브런 뒤의 위젯. 줄이 크기를 정해 주지 않습니다. |

`leading` · `trailing` 은 위젯을 그대로 받으므로 아이콘 · 인디케이터 · `Text` 체인을 넣을 수 있습니다. 무엇을 놓을지는 이 두 값이 정하고, `menuStyle` 의 `itemStyle` 은 놓인 모양만 바꿉니다.

```dart
CoreMenuItem.action(
  '동기화',
  leading: const Icon(LucideIcons.refreshCw),
  trailing: Text('베타').labelSmall,
  onPressed: sync,
)
```

`standardAction` 은 자주 쓰는 명령에 같은 아이콘을 붙입니다. 라벨 글자는 직접 씁니다.

<Preview demo="menu/standard-actions" />

| 값 | Lucide 아이콘 |
| --- | --- |
| `CoreMenuAction.cut` | `scissors` |
| `CoreMenuAction.copy` | `copy` |
| `CoreMenuAction.paste` | `clipboardPaste` |
| `CoreMenuAction.undo` | `undo2` |
| `CoreMenuAction.redo` | `redo2` |
| `CoreMenuAction.share` | `share` |
| `CoreMenuAction.rename` | `pencil` |
| `CoreMenuAction.delete` | `trash2` |

### 위험한 동작

<Preview demo="menu/critical" />

`tone: CoreMenuItemTone.critical` 인 줄은 라벨과 아이콘을 `error` 색으로 그립니다. hover · 키보드 포커스 · pressed 에서는 줄을 `errorContainer` 색으로 채웁니다. 이때 글자색은 바뀌지 않아 라벨은 `error`, 설명과 단축키는 `onSurfaceVariant` 그대로입니다. 쉬는 상태의 단서가 색 하나이므로 위험한 항목은 묶음의 마지막, 보통 구분선 뒤에 둡니다. `tone` 은 action · checkbox · radio 가 받으며, 켜진 줄은 `tone` 과 상관없이 선택 색으로 그립니다.

<a id="서브메뉴-인라인-중첩"></a>

### 서브메뉴

<Preview demo="menu/submenu" />

```dart
Menu(
  items: [
    CoreMenuItem.action('열기', onPressed: openFile),
    CoreMenuItem.action(
      '내보내기',
      submenu: [
        CoreMenuItem.action('PDF', onPressed: exportPdf),
        CoreMenuItem.action('CSV', onPressed: exportCsv),
      ],
    ),
  ],
)
```

| 항목 | 동작 |
| --- | --- |
| 펼침 | 하위 목록은 부모 줄 아래에 16 만큼 들여써 **늘 펼쳐 둡니다.** 접는 상태가 없고, 옆에 뜨는 패널도 아닙니다. |
| 부모 줄 | 끝에 오른쪽 셰브런을 그리고 `shortcut` 은 그리지 않습니다. 누르면 그 줄의 `onPressed` 만 불리고 `onActivate` 는 불리지 않습니다. |
| 하위 목록 | 상자 없는 `Menu` 입니다. `size` 는 부모 값을 쓰고, 부모가 가로여도 세로로 그립니다. 접근 가능한 이름은 없습니다. |
| 겉모습 | `submenuStyle` 이 정합니다. 부모 `menuStyle` 에 적은 `itemStyle` 같은 값은 하위 목록으로 이어지지 않습니다. 앱 전체의 `CoreMenuTheme` 은 하위 목록에도 닿습니다. |
| 하위 항목 | 골라도 `onActivate` 가 불리지 않습니다. 바깥 메뉴를 닫으려면 [알려진 제약](#알려진-제약)을 보세요. |
| 스크롤 | Flutter 는 따로 스크롤하지 않고 부모 목록과 함께 움직입니다. Jaspr Web 에서는 `DropdownMenu` · `ContextMenu` · `Menubar` 패널의 높이가 화면에 맞춰 제한되면 하위 목록도 같은 높이를 상한으로 받아 자기 스크롤 영역을 만듭니다. 그래서 하위 목록이 그 높이보다 길면 따로 스크롤할 수 있습니다. |

### 구분선과 간격

<Preview demo="menu/divider-gap" />

- `CoreMenuItem.divider()` 는 `Divider` 를 그립니다. 기본 색은 `outlineVariant`, 두께는 1 이고, 세로 메뉴에서는 위아래에 4 를 비웁니다. 가로 메뉴에서는 세로선이며 이 여백이 없습니다.
- `CoreMenuItem.gap(size)` 는 [Gap](/components/gap) 으로 빈 자리를 둡니다. 위 목록은 16 입니다. 패널의 줄 사이 간격 2 가 앞뒤에 한 번씩 더 붙습니다.

### 행은 `MenuItem` 이 그립니다

action · checkbox · radio 는 `Menu` 가 직접 그리지 않고 [MenuItem](/components/menu-item) 을 씁니다. 헤딩 · 구분선 · 간격만 `Menu` 가 그립니다. 항목의 값은 다음처럼 `MenuItem` 으로 옮겨집니다.

| `CoreMenuItem` | `MenuItem` |
| --- | --- |
| `label` · `description` · `shortcut` | 같은 이름의 값(`Text` 로 감싸서) |
| `tone` · `trailing` | 같은 이름의 값 |
| `leading`, 없으면 `standardAction` 의 아이콘 | `leading` |
| checkbox 의 `checked`, radio 의 `selected` | `selected`. 켜진 줄은 `mark` 에 체크(checkbox) 또는 `radioMark` 의 아이콘(radio)을 넣습니다. |
| action 의 `active` | `selected`. 표시(`mark`)는 넣지 않습니다. |
| 목록에 checkbox 나 radio 가 있음 | 모든 줄에 `reserveMark: true` |
| `submenu` 가 비어 있지 않음 | `hasSubmenu: true` |
| `disabled: true` | `enabled: false` |
| `Menu` 의 `size` | `size` |
| `menuStyle` 의 `itemStyle`(메뉴의 기본 모서리 위에) | `menuItemStyle` |

<a id="밀도-size"></a>

## 크기

`size` 는 메뉴에서 한 번 정하고, 그 값이 하위 목록을 포함한 모든 줄에 갑니다. 한 메뉴 안에서 줄 높이가 섞이지 않습니다. 기본값은 `CoreMenuItemSize.sm`(32)이며, [DropdownMenu](/components/dropdown-menu) · [ContextMenu](/components/context-menu) · [Menubar](/components/menubar) 가 띄우는 메뉴의 줄도 sm 입니다.

<SizeSpec component="menu" props="sample=size" label="메뉴" />

표의 높이는 줄의 최소 높이입니다. `description` 이 있는 줄은 그보다 커집니다. 헤딩의 좌우와 위쪽 여백은 `menuStyle` · `CoreMenuTheme` 의 `itemStyle` 에 적은 `padding` 을 따르고, 비어 있으면 같은 크기의 기본 줄 여백을 따릅니다. 아래쪽만 4(`labelBottomInset`)입니다. 앱 전체의 `CoreMenuItemTheme` 에 적은 여백과 부품 간격은 줄에만 적용되어, 헤딩과 줄의 시작 위치가 어긋날 수 있습니다.

<Note>

`size` 의 타입은 `CoreMenuItemSize`(sm · md · lg)입니다. `CoreComponentSize` 와는 다른 세 단계입니다. 표준 밀도에서 메뉴 안의 줄 모서리는 모든 크기에서 8 이고, 혼자 놓은 `MenuItem` 은 sm · md 8, lg 12 입니다. sm 의 32 와 lg 의 48 은 밀도(`CoreDensity`)를 따라 움직입니다. `spacious` 에서는 40 · 56 이고, `compact` 에서는 lg 가 40, sm 은 32 그대로입니다. md 의 36 은 움직이지 않습니다. 줄의 여백은 세 크기 모두 밀도를 따릅니다. 패널의 모서리 12 와 안쪽 여백 6, 줄 모서리 8 도 밀도를 따릅니다. `compact` 에서는 패널 모서리 10 · 여백 4 이고 줄 모서리는 8 그대로이며, `spacious` 에서는 패널 모서리 14 · 여백 8 · 줄 모서리 10 입니다.

</Note>

<a id="동작-스펙-behavior"></a>
<a id="hover-focus-pressed"></a>

## 상태

줄의 모양은 `MenuItem` 이 정합니다. 아래 미리보기는 쉬는 상태이며, hover · 포커스 · pressed 는 표로 적습니다.

<Preview demo="menu/states" />

| 상태 | 모양 |
| --- | --- |
| 기본 | 채움이 없습니다. 라벨과 아이콘은 `onSurface`, 설명과 단축키는 `onSurfaceVariant` 입니다. |
| Hover · 키보드 포커스 | 줄의 글자색을 8% 로 얹습니다. 키보드 포커스에는 포커스 링도 그립니다. |
| Pressed | 글자색을 12% 로 얹고 줄이 0.97 배로 줄어듭니다. |
| `active` · `checked` · `selected`(비활성이 아닐 때) | `primary` 채움에 `onPrimary` 글자. hover · 키보드 포커스 · pressed 는 `onPrimary` 를 같은 비율로 얹습니다. 비활성이면서 켜진 줄은 두 플랫폼이 다르게 그립니다([플랫폼 차이](#플랫폼-차이)). |
| `disabled` | 라벨 · 설명 · 단축키와 앞 아이콘을 `disabledContent` 색으로 그리고, hover 에 반응하지 않습니다. 눌러도 아무 일이 일어나지 않습니다. |
| `critical` | `error` 라벨. hover · 키보드 포커스 · pressed 는 `errorContainer` 채움입니다. |

<a id="항목-활성화"></a>

### 줄을 누를 때

| 줄 | 불리는 콜백 |
| --- | --- |
| action(`submenu` 없음) | `onActivate` 다음에 그 줄의 `onPressed`. `onPressed` 가 없는 줄은 둘 다 불리지 않습니다. |
| `submenu` 를 가진 action | 그 줄의 `onPressed` 만 |
| checkbox | `onChanged(!checked)` |
| radio | `onChanged(true)` |
| `disabled` 인 줄 | 없습니다 |

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

동작이나 이동 항목의 목록을 패널로 화면에 바로 놓을 때 씁니다. 앞뒤 아이콘, 체크박스, 라디오가 섞인 목록이나, 계층을 늘 펼쳐 보여 주는 하위 목록이 필요할 때도 맞습니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 트리거를 누르면 떠오르는 메뉴일 때 | [DropdownMenu](/components/dropdown-menu) |
| 우클릭이나 길게 누르기로 여는 메뉴일 때 | [ContextMenu](/components/context-menu) |
| 가로 바에서 여러 메뉴를 오가야 할 때 | [Menubar](/components/menubar) |
| 사이트 이동 링크와 넓은 드롭다운 콘텐츠가 필요할 때 | [NavigationMenu](/components/navigation-menu) |
| 동작 실행이 아니라 폼의 값을 고를 때 | [Select](/components/select) |
| 데이터의 계층을 펼치고 접으며 탐색할 때 | [Tree](/components/tree) |
| 항목의 뜻 없이 떠 있는 패널 상자만 필요할 때 | [Popup](/components/popup) |
| 줄 하나만 직접 배치할 때 | [MenuItem](/components/menu-item) |

<a id="do"></a>
<a id="dont"></a>

### 위험한 항목과 아이콘

<Cards columns="2">
<Card demo="menu/do-critical-last" tone="do" eyebrow="이렇게 하세요">

위험한 항목은 구분선 뒤, 묶음의 마지막에 둡니다.

</Card>
<Card demo="menu/dont-critical-middle" tone="dont" eyebrow="이렇게 하지 마세요">

자주 쓰는 항목 사이에 위험한 항목을 끼우지 않습니다.

</Card>
<Card demo="menu/do-leading-aligned" tone="do" eyebrow="이렇게 하세요">

한 목록의 줄에는 앞 아이콘을 모두 주거나 모두 뺍니다.

</Card>
<Card demo="menu/dont-leading-mixed" tone="dont" eyebrow="이렇게 하지 마세요">

아이콘이 있는 줄과 없는 줄이 섞이면 라벨이 시작하는 위치가 어긋납니다.

</Card>
</Cards>

### 이름과 닫기

<Cards columns="2">
<Card tone="do" eyebrow="이렇게 하세요" title="혼자 놓은 메뉴에 이름 주기">

`ariaLabel` 을 줍니다. 트리거 없이 놓은 메뉴에는 스크린 리더에 목적을 알릴 이름이 저절로 생기지 않습니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요" title="닫기 연결 빠뜨리기">

직접 만든 오버레이에 `Menu` 를 넣고 `onActivate` 를 빠뜨리면, action 을 골라도 패널이 열린 채로 남습니다.

</Card>
</Cards>

```dart
Menu(items: actionItems, onActivate: closePanel)
```

`DropdownMenu` · `ContextMenu` · `Menubar` 는 자기 `Menu` 에 닫기를 이미 연결합니다. [Popover](/components/popover) 는 `content` 를 자기 패널 안에 담으므로, 거기에 `Menu` 를 넣으면 패널 안에 메뉴 패널이 한 번 더 그려집니다. 트리거로 여는 메뉴에는 `DropdownMenu` 를 씁니다.

## 배치

`Menu` 는 화면에서의 위치를 정하지 않고, 놓인 자리에 그립니다.

### 폭

패널의 폭은 내용에 따라 240(`CoreLayout.layout240`)에서 280(`CoreLayout.layout280`) 사이입니다. 다른 범위가 필요하면 `menuStyle` 의 `popupStyle` 에 `minWidth` · `maxWidth` 를 줍니다.

```dart
Menu(
  items: items,
  menuStyle: const CoreMenuStyle(
    popupStyle: CorePopupStyle(
      minWidth: CoreLayout.layout160,
      maxWidth: CoreLayout.layout320,
    ),
  ),
)
```

부모가 폭을 하나로 강제하면 Flutter 는 그 폭을 따르고, Jaspr Web 은 `width: fit-content` 로 위의 범위 안에서 내용 폭을 지킵니다.

### 긴 목록

| 플랫폼 | 동작 |
| --- | --- |
| Flutter | 세로 `Menu` 는 받은 높이가 줄에 모자라면 패널 안에서 줄을 스크롤합니다. 높이를 정하는 것은 부모입니다. 제한이 없는 자리에서는 줄을 모두 펼치고, 가로 `Menu` 는 스크롤하지 않습니다. |
| Jaspr Web | 직접 놓은 `Menu` 는 스스로 스크롤하지 않습니다. 감싼 상자에서 스크롤하면 패널 상자 전체가 함께 움직입니다. |

`DropdownMenu` · `ContextMenu` · `Menubar` 가 띄우는 패널은 두 플랫폼 모두 화면에 남은 높이 안에 맞추고 줄을 스크롤합니다. Jaspr Web 에서는 패널 상자에 `max-height` 를 걸고 상자 안의 목록만 `overflow-y: auto` 로 스크롤하므로, 테두리 · 모서리 · 그림자는 제자리에 있습니다.

### 가로 메뉴

<Preview demo="menu/horizontal" />

```dart
Menu(
  vertical: false,
  items: [
    CoreMenuItem.action('홈', onPressed: goHome, active: true),
    CoreMenuItem.action('문서', onPressed: openDocs),
  ],
)
```

| 항목 | 동작 |
| --- | --- |
| 폭 범위 | 240 ~ 280 범위를 풉니다. 안쪽 여백 6 과 줄 사이 2 는 그대로입니다. |
| 폭 | Flutter 는 패널과 줄이 내용만큼입니다. Jaspr Web 의 패널은 블록 부모 안에서 부모 폭을 채우고 줄들이 그 폭을 나눠 가집니다. 그래서 위 Jaspr Web 미리보기는 폭을 정한 블록 상자에 놓았습니다. 부모가 내용에 맞춰 폭을 정하면 라벨이 꺾입니다([알려진 제약](#알려진-제약)). |
| 역할 | menu 가 아니라 menubar 로 알립니다. |
| 하위 목록 | 가로 메뉴에는 `submenu` 를 넣지 않습니다. 이유는 [알려진 제약](#알려진-제약)에 있습니다. |

눌러서 하위 메뉴를 여는 가로 바가 필요하면 [Menubar](/components/menubar) 를 씁니다.

<a id="스타일-시스템-style-system"></a>
<a id="시맨틱-vs-스타일"></a>
<a id="파라미터와-스타일"></a>

## 테마와 스타일

항목 · 방향 · 크기 · 이름 · 닫기는 위젯 속성(`items` · `vertical` · `size` · `ariaLabel` · `onActivate`)으로 정하고, 색 · 간격 · 모서리 같은 겉모습은 `menuStyle`(`CoreMenuStyle`) 하나로 덮어씁니다.

| 부분 | 필드 | 기본값 |
| --- | --- | --- |
| 패널 상자 | `popupStyle` | 폭 240 ~ 280, 안쪽 여백 6, 줄 사이 2. 채움 · 테두리 · 모서리(12) · 그림자는 `Popup` 의 기본값입니다. |
| 누를 수 있는 줄 | `itemStyle` | 모서리 8. 나머지는 `MenuItem` 의 크기 · tone 기본값입니다. |
| 헤딩 글자 | `labelTextStyle` | `labelSmall`, `onSurfaceSubtle` |
| 헤딩 아래 여백 | `labelBottomInset` | 4 |
| 구분선 | `dividerStyle` | `outlineVariant`, 두께 1 |
| 구분선 위아래 여백 | `dividerInset` | 4 (세로 메뉴) |
| 헤딩의 앞 칸 폭 | `leadingColumnWidth` | 16 |
| 하위 목록 | `submenuStyle` · `submenuIndent` | 상자 없는 패널 · 16 |

<Note>

리퀴드글라스(`liquidGlass`) 서페이스 스타일에서는 패널 모서리 24 · 줄 모서리 16 이 기본이 되고, 세로 메뉴의 패널 안쪽 여백은 8 이 됩니다. 가로 메뉴의 안쪽 여백은 이 스타일에서도 6 입니다. `menuStyle` 이나 `CoreMenuTheme` 에 적은 값이 이보다 우선합니다. 이 스타일에서는 앱 전체의 `CorePopupTheme` 에 적은 값이 패널의 모서리 · 여백뿐 아니라 메뉴의 폭 · 줄 간격 기본값보다도 우선합니다. 다만 가로 메뉴의 안쪽 여백과 폭 범위에는 가로 메뉴의 기본값이 우선합니다.

</Note>

<a id="사용-예"></a>

<Split>

<Code language="dart" title="메뉴 하나만 바꾸기">
Menu(
  items: items,
  menuStyle: const CoreMenuStyle(
    popupStyle: CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
    itemStyle: CoreMenuItemStyle(
      selectedBackgroundColor: CoreColor.token(CoreColors.secondary),
      selectedForegroundColor: CoreColor.token(CoreColors.onSecondary),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    menu: CoreMenuTheme(
      style: CoreMenuStyle(
        itemStyle: CoreMenuItemStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
        ),
      ),
    ),
  ),
)
</Code>

</Split>

### 빠른 오버라이드 (Chain)

이미 만든 `Menu` 에는 `withStyle` 로 스타일을 덧붙입니다. 생성자의 `menuStyle` 인자와 같게 동작하고, 겹치는 필드는 뒤에 붙인 값이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class MenuChainExample extends StatelessWidget {
  const MenuChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Menu(
      ariaLabel: '주 메뉴',
      items: [
        const CoreMenuItem.label('탐색'),
        CoreMenuItem.action('홈', onPressed: () {}, active: true),
        CoreMenuItem.action('프로필', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.checkbox('격자 보기', onChanged: (_) {}, checked: true),
        CoreMenuItem.action('설정', disabled: true),
      ],
    ).withStyle(
      const CoreMenuStyle(
        itemStyle: CoreMenuItemStyle(
          padding: CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space20,
            vertical: CoreSpace.space12,
          ),
          contentGapStyle: CoreGapStyle(size: CoreSpace.space12),
          markIconStyle: CoreIconStyle(
            color: CoreColor.token(CoreColors.tertiary),
          ),
        ),
        dividerStyle: CoreDividerStyle(
          color: CoreColor.token(CoreColors.primary),
          thickness: CoreStrokeWidth.stroke2,
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class MenuChainExample extends StatelessComponent {
  const MenuChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Menu(
      ariaLabel: '주 메뉴',
      items: [
        const CoreMenuItem.label('탐색'),
        CoreMenuItem.action('홈', onPressed: () {}, active: true),
        CoreMenuItem.action('프로필', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.checkbox('격자 보기', onChanged: (_) {}, checked: true),
        CoreMenuItem.action('설정', disabled: true),
      ],
    ).withStyle(
      const CoreMenuStyle(
        itemStyle: CoreMenuItemStyle(
          padding: CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space20,
            vertical: CoreSpace.space12,
          ),
          contentGapStyle: CoreGapStyle(size: CoreSpace.space12),
          markIconStyle: CoreIconStyle(
            color: CoreColor.token(CoreColors.tertiary),
          ),
        ),
        dividerStyle: CoreDividerStyle(
          color: CoreColor.token(CoreColors.primary),
          thickness: CoreStrokeWidth.stroke2,
        ),
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

뒤로 갈수록 우선합니다.

```text
헤딩 · 하위 목록
  CoreMenuStyle 의 기본값
    → CoreComponentTheme.menu.style                // 앱 전체
    → menuStyle                                    // 인스턴스

구분선
  CoreDividerStyle 의 기본값
    → CoreComponentTheme.divider.style             // 앱 전체의 Divider
    → CoreMenuStyle.defaultDividerStyle            // 메뉴 구분선의 색
    → CoreComponentTheme.menu.style.dividerStyle
    → menuStyle.dividerStyle

패널 상자
  CorePopupStyle 의 기본값
    → CoreComponentTheme.popup.style               // 앱 전체의 Popup
    → CoreMenuStyle.defaultPopupStyle              // 메뉴의 폭 · 여백 · 줄 간격
    → 리퀴드글라스의 패널 모서리 24 · 여백 8             // 리퀴드글라스일 때
    → CoreComponentTheme.popup.style 한 번 더         // 리퀴드글라스일 때
    → CoreMenuStyle.defaultHorizontalPopupStyle    // 가로 메뉴일 때: 여백 6 · 폭 범위 없음
    → CoreComponentTheme.menu.style.popupStyle
    → menuStyle.popupStyle

누를 수 있는 줄
  CoreMenuItemStyle 의 size · tone 기본값
    → CoreComponentTheme.menuItem.style            // 앱 전체의 MenuItem
    → CoreMenuStyle.defaultItemStyle               // 메뉴 안 줄의 모서리 8
    → 리퀴드글라스의 줄 모서리 16                       // 리퀴드글라스일 때
    → CoreComponentTheme.menu.style.itemStyle
    → menuStyle.itemStyle
```

`Menu` 는 자기 기본값을 `Popup` 과 `MenuItem` 의 앱 전체 테마 뒤에 놓습니다. 그래서 리퀴드글라스가 아닐 때는 `CorePopupTheme` 으로 메뉴의 폭 · 안쪽 여백 · 줄 간격을 바꿀 수 없습니다. 메뉴 안 줄의 모서리는 어떤 서페이스 스타일에서도 `CoreMenuItemTheme` 으로 바꿀 수 없습니다. 이 값들은 `CoreMenuTheme` 이나 `menuStyle` 에 적습니다. 리퀴드글라스에서 `CorePopupTheme` 이 닿는 범위는 위의 참고를 보세요.

<a id="접근성-accessibility"></a>

## 접근성

`Menu` 는 항목 목록을 그리고 역할을 알립니다. 열고 닫기, 열 때의 포커스, `Escape` 는 `Menu` 를 띄우는 컴포넌트의 일이라, 아래에서 둘을 나눠 적습니다.

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은 [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

### 역할

| 대상 | Flutter | Jaspr Web |
| --- | --- | --- |
| 패널 | menu(가로는 menuBar) 역할의 시맨틱 노드. 이름은 `ariaLabel` 입니다. | `role="menu"`(가로는 `menubar`)와 `aria-orientation`. `ariaLabel` 이 있으면 `aria-label` 이 붙습니다. |
| action 줄 | menuItem. 활성 여부와, `active` 를 선택됨으로 알립니다. | `role="menuitem"`. `active` 줄에 `aria-current="true"`. |
| `submenu` 를 가진 줄 | menuItem. 펼침 상태는 알리지 않습니다. | `aria-haspopup="menu"` 가 더 붙습니다. |
| checkbox 줄 | menuItemCheckbox 와 체크 상태 | `role="menuitemcheckbox"` 와 `aria-checked` |
| radio 줄 | menuItemRadio 와 체크 상태. 하나만 켜지는 묶음으로 알립니다. | `role="menuitemradio"` 와 `aria-checked` |
| `disabled` 줄 | 비활성으로 알립니다. | `aria-disabled="true"` |
| 헤딩 | 보통 글자 | `role="presentation"` 상자 안의 글자 |
| 구분선 | 로케일의 "구분선" 이름을 가진 시맨틱 노드 | `role="separator"` 와 로케일의 "구분선" `aria-label` |

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` · `Shift` · `Tab` | 비활성 줄까지 줄마다 멈춥니다. | 목록 하나가 한 번 멈춥니다. 하위 목록은 자기 자리를 하나 더 가집니다. |
| `Enter` · `Space` | 포커스한 줄을 누릅니다. 비활성 줄에서는 아무 일도 하지 않습니다. | 포커스한 줄을 누릅니다. 비활성 줄에서는 줄이 동작하지 않으며, `Space` 가 페이지를 스크롤할 수 있습니다. |
| `ArrowUp` · `ArrowDown` (세로) | 메뉴가 직접 처리하지 않습니다. 네이티브 앱에서는 기본 단축키가 방향대로 포커스를 옮기고, Flutter Web 에서는 스크롤에 씁니다. | 이전 · 다음 줄. 끝에서는 반대쪽 끝으로 돌아갑니다. |
| `ArrowLeft` · `ArrowRight` (가로) | 위와 같습니다. | 이전 · 다음 줄. 끝에서는 반대쪽 끝으로 돌아갑니다. |
| `Home` · `End` | 메뉴 동작이 없습니다. | 첫 줄 · 마지막 줄 |
| 글자 | 메뉴 동작이 없습니다. | 라벨이 그 글자로 시작하는 줄로 옮깁니다. 0.5초 안에 이어 치면 이어진 글자로 찾습니다. |

Jaspr Web 에서 `Tab` 이 처음 멈추는 곳은 첫 번째 누를 수 있는 줄입니다. 멈추는 줄은 화살표 · `Home` · `End` · 글자 입력으로만 옮겨 가고, 줄을 누르는 것만으로는 옮겨 가지 않습니다. 비활성 줄도 건너뛰지 않으며, 헤딩 · 구분선 · 간격은 순서에 들지 않습니다.

#### 메뉴를 띄운 컴포넌트의 `Escape`

`Menu` 자신은 `Escape` 를 처리하지 않습니다.

| 컴포넌트 | Flutter | Jaspr Web |
| --- | --- | --- |
| `DropdownMenu` · `ContextMenu` | 닫힙니다. | 닫힙니다. |
| `Menubar` | `Escape` 동작이 없습니다. | 닫히고, 포커스가 그 메뉴를 연 트리거로 돌아갑니다. |

### 스크린 리더

- 메뉴의 접근 가능한 이름은 `ariaLabel` 로 줍니다. Jaspr Web 에서는 `attributes` 의 `aria-label` 도 읽히고, 둘 다 있으면 `ariaLabel` 이 이깁니다.
- 줄의 이름은 줄 안의 글자에서 옵니다. Jaspr Web 에서는 라벨 · 설명 · 단축키 글자가 함께 이름이 됩니다.
- 헤딩은 아래 줄들의 묶음 이름으로 연결되지 않습니다.
- `Menu` 는 항목 수와 "몇 번째" 인지를 알리는 속성을 따로 붙이지 않습니다.
- checkbox · radio 의 값이 바뀐 것을 따로 알리는 라이브 리전은 없습니다. 바뀐 체크 상태가 줄의 상태로 전달됩니다.
- 메뉴가 열리고 닫힌 것을 알리는 라이브 리전도 없습니다. `DropdownMenu` · `Menubar` 는 트리거의 펼침 상태로 알립니다.

### 포커스 관리

- `Menu` 는 화면에 놓일 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다.
- 키보드로 포커스한 줄은 줄의 모서리를 따라 포커스 링을 그립니다. 예외는 Jaspr Web 의 비활성 줄입니다.
- Flutter 의 `DropdownMenu` · `ContextMenu` 는 열 때 포커스를 첫 줄이 아니라 패널로 옮기고, `Tab` 을 패널 안에 두며, 배경을 스크린 리더에서 가립니다. `Menubar` 의 패널은 그렇게 열리지 않습니다.
- Jaspr Web 의 `DropdownMenu` · `ContextMenu` 는 앱의 오버레이 호스트에 열리면 뒤 페이지를 `inert` 로 만들어 `Tab` 과 스크린 리더가 닿지 않게 합니다. 열 때 포커스를 패널이나 첫 줄로 옮기지는 않습니다.
- Jaspr Web 의 `Menubar` 는 `Escape` 나 패널 안의 `Tab` 으로 닫으면 포커스를 그 메뉴를 연 트리거로 옮깁니다. 그 밖의 경우에는 두 플랫폼의 `DropdownMenu` · `ContextMenu` · `Menubar` 가 닫은 뒤 포커스를 트리거로 직접 옮기지 않습니다. 닫은 뒤 포커스가 어디로 가는지는 보장되지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 하위 목록의 action 을 골라도 바깥 메뉴의 `onActivate` 가 불리지 않습니다. 그래서 `DropdownMenu` · `ContextMenu` 에 `submenu` 를 넣으면 하위 항목을 골라도 메뉴가 닫히지 않습니다. 하위 항목의 `onPressed` 에서 `controller` 의 `close()` 를 부릅니다. |
| 공통 | 하위 목록은 늘 펼쳐져 있는데도 부모 줄은 셰브런을 그립니다. Jaspr Web 은 부모 줄에 `aria-haspopup="menu"` 를 붙이고 `aria-expanded` 는 붙이지 않아, 눌러야 열리는 메뉴처럼 읽힐 수 있습니다. |
| 공통 | 하위 목록의 상자는 안쪽 여백이 0 이고 넘치는 것을 잘라, 하위 줄의 포커스 링이 잘려 보일 수 있습니다. |
| 공통 | 누를 수 있는 줄은 `leading` 이 없으면 아이콘 자리를 비워 두지 않습니다. 아이콘이 있는 줄과 없는 줄(`leading` 을 받지 않는 checkbox · radio 포함)이 섞이면 라벨 시작 위치가 어긋납니다. |
| 공통 | checkbox 와 radio 가 없는 메뉴에서 헤딩의 앞 칸은 `leadingColumnWidth`(16)로 고정입니다. 앞 아이콘이 18 · 24 인 md · lg 에서는 헤딩 글자가 줄의 라벨보다 2 · 8 만큼 앞에서 시작합니다. |
| 공통 | `onPressed` · `onChanged` 가 없는 줄은 `disabled: true` 를 주기 전에는 비활성으로 보이지 않고 비활성으로 알려지지도 않습니다. |
| 공통 | 헤딩의 여백과 부품 간격은 앱 전체의 `CoreMenuItemTheme` 을 읽지 않습니다. 이 테마로 줄의 `padding` · `contentGapStyle` 을 바꾸면 헤딩과 줄이 어긋날 수 있습니다. |
| Flutter | 줄마다 `Tab` 정지점이 생기고, 화살표 · `Home` · `End` · 글자로 메뉴 안을 옮겨 다니는 메뉴 동작이 없습니다. |
| Flutter | 가로 `Menu` 에 `submenu` 를 가진 줄을 넣으면 레이아웃 오류가 날 수 있습니다. |
| Flutter | 가로 `Menu` 의 구분선은 부모의 높이가 정해지지 않으면 길이가 0 이 되어 보이지 않고, 정해져 있으면 그 높이까지 늘어 메뉴가 커질 수 있습니다. |
| Jaspr Web | 비활성 줄에는 포커스 링을 그리지 않습니다. 화살표로 비활성 줄에 가면 포커스가 어디에 있는지 보이지 않습니다. |
| Jaspr Web | 켜진 checkbox · radio 줄에도 `aria-checked` 와 함께 `aria-current="true"` 가 붙습니다. |
| Jaspr Web | 하위 목록과 부모 목록 사이를 화살표로 오갈 수 없습니다. `Tab` 이나 `Shift` · `Tab` 으로 옮겨 갑니다. |
| Jaspr Web | `items` 가 줄어 `Tab` 이 멈추던 순서의 줄이 없어지면, `Tab` 으로 메뉴에 들어갈 수 없게 될 수 있습니다. |
| Jaspr Web | 가로 `Menu` 를 내용에 맞춰 폭이 정해지는 상자(가운데 정렬 flex 등)에 놓으면 줄이 좁아져 한글 라벨이 글자 단위로 꺾입니다. 블록 상자에 폭을 정해 놓습니다. |
| Jaspr Web | 오른쪽에서 왼쪽으로 쓰는 언어에서도 가로 메뉴의 `ArrowRight` 는 다음 줄(화면에서는 왼쪽)로 옮깁니다. |
| Jaspr Web | 높이에 맞춰 목록을 스크롤하는 패널에서는 줄의 포커스 링 좌우가 잘려 보일 수 있습니다. |
| Jaspr Web | 높이에 맞춰 목록을 스크롤하는 패널 안에서는 하위 목록도 자기 스크롤 영역을 만들어 스크롤이 겹칠 수 있습니다. 스크롤바가 자리를 차지하는 환경에서는 하위 줄이 그만큼 좁아질 수 있습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

같은 이름의 속성과 `CoreMenuItem` 을 쓰고, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 패널 | menu · menuBar 시맨틱 안의 `Popup` | `Popup` 의 겉모습을 입힌 `<div role="menu">` 또는 `<div role="menubar">` |
| 키보드 이동 | 줄마다 `Tab`. 메뉴 전용 키가 없습니다. | 목록마다 `Tab` 한 번, 화살표 · `Home` · `End` · 글자 |
| 비활성 줄 | `disabledContent` 색. 포커스 링을 그립니다. | `disabledContent` 색에 불투명도 50% 가 더해지고, 포커스 링이 없습니다. |
| 비활성이면서 켜진 줄(`active` · `checked` · `selected`) | 채움 없이 `disabledContent` 색 | `primary` 채움이 남고, 그 위에 `disabledContent` 글자와 불투명도 50% |
| `description` 이 있는 줄 | 표시 · 아이콘 · 글자를 위로 맞춥니다. | 표시 · 아이콘 · 단축키를 줄의 세로 가운데에 둡니다. |
| `trailing` 의 색 | 선택 · 비활성 같은 줄의 글자색을 따르지 않습니다. | 색을 직접 정하지 않은 아이콘과 글자는 줄의 글자색을 따릅니다. |
| 가로 메뉴의 폭 | 패널과 줄이 내용만큼 | 블록 부모 안에서는 패널이 부모 폭을 채우고, 줄들이 그 폭을 나눠 가질 수 있습니다. |
| 부모가 폭을 강제할 때 | 그 폭 | 폭 범위 안의 내용 폭 |
| 직접 놓은 긴 목록 | 받은 높이 안에서 스크롤 | 스스로 스크롤하지 않습니다. |
| `labelTextStyle` 에 다른 타이포 역할 | 반영합니다. | 반영하지 않습니다. `fontSize` · `fontWeight` · `color` 처럼 직접 적은 값은 반영합니다. |
| `itemStyle` 의 `padding` 이 좌우 또는 위아래가 다를 때 | 네 변을 그대로 씁니다. | 왼쪽 값을 양옆에, 위쪽 값을 위아래에 씁니다. |
| `href` | 읽지 않습니다. | 줄에 `data-href` 속성을 붙입니다. |
| 크기 배율 | 테마의 크기 배율(`scaling`)을 곱합니다. | CSS 변수나 `rem` 으로 그립니다. |
| HTML 속성 · DOM 이벤트 | 없습니다. | `id` · `classes` · `css` · `attributes` · DOM 이벤트가 패널 `<div>` 에 붙습니다. |

<a id="props-parameters"></a>

## API

Flutter 와 Jaspr Web 이 같은 속성을 씁니다. `W` 는 Flutter 의 `Widget`, Jaspr Web 의 `Component` 입니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `items` | `List<CoreMenuItem<W>>` | 필수 | 패널에 놓을 항목. 순서대로 그립니다. |
| `vertical` | `bool` | `true` | `false` 면 항목을 가로로 놓습니다. |
| `size` | `CoreMenuItemSize` | `CoreMenuItemSize.sm` | 모든 줄의 크기 |
| `ariaLabel` | `String?` | `null` | 메뉴의 접근 가능한 이름 |
| `menuStyle` | `CoreMenuStyle?` | `null` | 이 메뉴의 겉모습 덮어쓰기 |
| `onActivate` | `void Function()?` | `null` | `submenu` 없는 action 을 누를 때 그 줄의 `onPressed` 보다 먼저 불립니다. 메뉴를 띄운 쪽의 닫기를 연결합니다. 하위 목록에는 전달되지 않습니다. |

두 플랫폼 모두 `key` 를 받습니다. Jaspr Web 은 패널 `<div>` 에 붙는 `id` · `classes` · `css` · `attributes` · `eventHandlers` 와 `onClick` · `onChange` · `onInput` · `onKeyDown` · `onKeyUp` · `onMouseEnter` · `onMouseLeave` 도 받습니다. `role` 과 `aria-orientation` 은 메뉴가 정하므로 `attributes` 로 바꿀 수 없습니다.

### `CoreMenuItem` 팩토리

| 팩토리 | 설명 |
| --- | --- |
| `CoreMenuItem.label(String label, {leading, trailing})` | 누를 수 없는 헤딩 |
| `CoreMenuItem.action(String label, {description, tone, leading, standardAction, trailing, shortcut, onPressed, href, submenu, active, disabled})` | 동작을 실행하는 줄 |
| `CoreMenuItem.checkbox(String label, {description, tone, trailing, onChanged, checked, disabled})` | 켜고 끄는 줄 |
| `CoreMenuItem.radio(String label, {description, tone, trailing, shortcut, onChanged, selected, radioMark, disabled})` | 여러 선택지 중 하나인 줄 |
| `CoreMenuItem.divider()` | 구분선 |
| `CoreMenuItem.gap(double size)` | 정한 크기의 빈 간격 |

### `CoreMenuItem` 필드

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String` | 필수(divider · gap 은 `''`) | 줄이나 헤딩의 글자 |
| `description` | `String?` | `null` | 라벨 아래의 둘째 줄 |
| `tone` | `CoreMenuItemTone` | `CoreMenuItemTone.neutral` | `critical` 은 위험한 동작 |
| `leading` | `W?` | `null` | 라벨 앞의 위젯 |
| `standardAction` | `CoreMenuAction?` | `null` | `leading` 이 없을 때의 표준 명령 아이콘 |
| `trailing` | `W?` | `null` | 단축키 · 셰브런 뒤의 위젯 |
| `shortcut` | `String?` | `null` | 단축키 글자 |
| `submenu` | `List<CoreMenuItem<W>>?` | `null` | 줄 아래에 펼쳐 두는 하위 항목 |
| `CoreMenuItem.onPressed` | `void Function()?` | `null` | action 을 누를 때 |
| `CoreMenuItem.onChanged` | `void Function(bool)?` | `null` | checkbox · radio 를 누를 때의 다음 값 |
| `href` | `String?` | `null` | 이동 주소 정보. 메뉴가 이동시키지는 않습니다. |
| `active` | `bool` | `false` | action 을 선택된 모양으로 그립니다. |
| `checked` | `bool` | `false` | checkbox 의 값 |
| `selected` | `bool` | `false` | radio 의 선택 여부 |
| `radioMark` | `CoreMenuRadioMark` | `CoreMenuRadioMark.dot` | 고른 radio 의 그림. `dot` 또는 `check` |
| `disabled` | `bool` | `false` | 누를 수 없는 줄 |
| `gapSize` | `double` | `0` | `gap` 의 크기. `CoreMenuItem.gap(size)` 로 정합니다. |
| `kind` | `CoreMenuItemKind` | 팩토리가 정함 | `label` · `action` · `checkbox` · `radio` · `divider` · `gap` |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreMenuStyle patch)` | `menuStyle` 에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다. |
| `copyWith({items, vertical, size, ariaLabel, menuStyle, onActivate, key})` | 바꾼 값으로 사본을 만듭니다. Jaspr Web 은 HTML 속성과 DOM 이벤트도 받습니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.menu` | `CoreMenuTheme?` | 앱 전체의 메뉴 모양. `style`(`CoreMenuStyle?`) 하나를 가집니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreMenuStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `popupStyle` | `CorePopupStyle?` | Style of the `Popup` the menu panel is drawn in — its background, border, corners, padding, shadow, minimum width and the spacing between rows. Passed to `Popup(popupStyle: …)` as is. Only the fields where a menu differs are set in [defaultPopupStyle]; the rest come from [CorePopupStyle]'s own defaults. The per-instance value is laid on top. |
| `submenuStyle` | `CoreMenuStyle?` | Style of an inline submenu. The submenu is itself a `Menu` (an indented child), so this slot takes a full [CoreMenuStyle], passed to the child's `menuStyle` as is. Defaults to [defaultSubmenuStyle] — a flush panel with no box — so inline submenus read as an indented group; override it to give submenus their own box and row look. The per-instance value is laid on top of the default. |
| `itemStyle` | `CoreMenuItemStyle?` | Look of every interactive row — the `MenuItem` the menu draws. `null` → [defaultItemStyle]. Each row gets [effectiveItemStyle] as is and fills the rest from its own size and tone ladders. Size and tone themselves are not here — the menu passes `size` as a prop and each entry carries its own tone. |
| `labelTextStyle` | `CoreTextStyle?` | Text style of non-interactive label / header entries (`CoreMenuItemKind.label`), laid over [defaultLabelTextStyle] (`labelSmall` role + its default colour) and applied to the entry's `Text` / `<span>`. Carries the heading weight and colour, so both platforms take the heading typography from this one slot. |
| `dividerStyle` | `CoreDividerStyle?` | Style of the divider entry, laid over [defaultDividerStyle] and passed to `Divider(dividerStyle: …)` as is; the `Divider` works out the colour and thickness. |
| `labelBottomInset` | `double?` | Space left below a label / heading entry (logical px). The heading's top and sides follow the row padding (from [itemStyle], else the size ladder) so its text lines up with the rows; only the bottom is its own. `null` → [defaultLabelBottomInset]. |
| `dividerInset` | `double?` | Space kept on each side of a divider entry across the menu's cross axis (logical px) — above and below the rule in a column menu, either side of it in a bar. `null` → [defaultDividerInset]. |
| `leadingColumnWidth` | `double?` | Leading-icon column width (logical px). |
| `submenuIndent` | `double?` | Per-level submenu indentation (logical px). |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 설명과 지금 동작이 다른 곳이 있습니다. `itemStyle` 을 비웠을 때 줄은 메뉴의 기본 모서리(8)를 받고, 리퀴드글라스에서는 16 입니다. `dividerInset` 은 세로 메뉴의 구분선 위아래에만 적용되며, 가로 메뉴의 구분선 양옆에는 여백이 생기지 않습니다. `leadingColumnWidth` 는 헤딩의 앞 칸에만 쓰이고, 누를 수 있는 줄의 아이콘 자리는 정하지 않습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="menu/related-menu-item" title="MenuItem">

메뉴의 줄 하나입니다. 줄의 모양과 상태를 정합니다. [MenuItem 문서](/components/menu-item)

</Card>
<Card demo="menu/related-dropdown-menu" title="DropdownMenu">

트리거를 누르면 메뉴를 띄웁니다. [DropdownMenu 문서](/components/dropdown-menu)

</Card>
<Card demo="menu/related-context-menu" title="ContextMenu">

우클릭이나 길게 누르기로 메뉴를 띄웁니다. [ContextMenu 문서](/components/context-menu)

</Card>
<Card demo="menu/related-menubar" title="Menubar">

여러 메뉴를 가진 가로 메뉴바입니다. [Menubar 문서](/components/menubar)

</Card>
<Card demo="menu/related-popover" title="Popover">

원하는 내용을 트리거 옆 패널에 띄웁니다. [Popover 문서](/components/popover)

</Card>
</Cards>
