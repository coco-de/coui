---
title: MenuItem
description: 메뉴 행 하나 — Menu, DropdownMenu, ContextMenu, Menubar, Select 가 함께 놓는 단위
category: menu
platforms: [flutter, web]
related: [menu, dropdown-menu, context-menu, menubar, select]
tags: [interactive, menu]
template: v2
source: menu/menu_item
---

# MenuItem

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

크기 · 톤 · 자리에 넣는 내용을 바꿔 보며 메뉴 행 하나를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="menu-item" />

행은 쉴 때 바탕이 없어 무대에는 글자와 아이콘만 보입니다. 마우스를 올리거나 `selected` 를 켜면 행의 상자가 보입니다. 행은 선택 상태를 스스로 들고 있지 않습니다. 누르면 `onPressed` 만 불리고, `selected` 는 호출자가 새 값을 넘겨야 바뀝니다. `hasSubmenu` 를 켜면 `shortcut` 을 넘겨도 단축키 대신 화살표를 그립니다.

<a id="해부-anatomy"></a>

## 구조

행은 앞에서부터 아래 순서로 자리를 놓습니다. 자리 사이 간격은 `contentGapStyle` 이 정합니다. 넘기지 않은 자리는 만들지 않고, `reserveMark` 를 켠 `mark` 칸만 비어 있어도 남습니다.

```text
[ mark ] [ leading ] [ label / description ] [ shortcut 또는 화살표 ] [ trailing ]
```

<Anatomy demo="menu-item/anatomy">
<AnatomyItem part="container" name="Container">

행 상자이자 누르는 영역입니다. 높이는 `size` 의 최소 높이에서 시작하고 내용이 크면 늘어납니다. 쉴 때는 바탕이 없습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=mark]" side="top" name="mark">

켜짐을 나타내는 체크나 점의 자리입니다. 선택 사항이고, `reserveMark` 가 `true` 면 `mark` 가 없어도 이 칸의 폭을 남깁니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=leading]" side="top" name="leading">

아이콘이나 표시를 놓는 앞 자리입니다. 선택 사항입니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="label">

행의 이름입니다. 필수이고, 남는 폭을 차지하며 길면 줄을 바꿉니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=description]" side="right" name="description">

`label` 아래의 흐린 두 번째 줄입니다. 선택 사항입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=shortcut]" side="top" name="shortcut">

단축키를 알려 주는 글자입니다. 서브메뉴를 여는 행(`hasSubmenu`)은 이 자리에 오른쪽 화살표(`LucideIcons.chevronRight`)를 그립니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=trailing]" side="right" name="trailing">

단축키나 화살표 뒤의 추가 자리입니다. 선택 사항이고, 행이 아이콘 크기 · 색 설정을 내려 주지 않습니다. Jaspr Web 에서는 행의 글자색을 물려받습니다([슬롯에 넣은 위젯](#슬롯에-넣은-위젯)).

</AnatomyItem>
</Anatomy>

그림은 `lg` 행입니다. 행은 `Clickable` 안에 자리를 놓고 `Gap` 으로 띄웁니다. 글자 자리에는 넘긴 위젯을 그대로 놓고, 서브메뉴 화살표만 `Icon` 으로 직접 그립니다. `Button` 은 쓰지 않습니다. 메뉴 행은 비활성이어도 키보드로 닿아야 하고, 행의 종류에 따라 `menuitem` · `menuitemcheckbox` · `menuitemradio` 처럼 다르게 알려야 해서 버튼과 규칙이 다르기 때문입니다.

<a id="축-axes-밀도와-톤"></a>
<a id="톤-tone"></a>
<a id="변형-variants"></a>
<a id="파괴적-액션-critical"></a>

## Variant

`MenuItem` 의 variant 는 `tone`(`CoreMenuItemTone`)입니다. 크기(`size`)와는 따로 고릅니다.

<VariantRow name="neutral" component="menu-item" props="tone=neutral;leading=copy" label="복사">

일반 동작에 씁니다. 기본값입니다. 쉴 때 라벨과 아이콘은 `onSurface` 입니다.

</VariantRow>

<VariantRow name="critical" component="menu-item" props="tone=critical;leading=trash-2" label="삭제">

삭제처럼 되돌릴 수 없는 동작에 씁니다. 쉴 때 라벨과 아이콘이 `error` 입니다. 마우스를 올리거나 포커스하거나 누르면 바탕을 `errorContainer` 로 채우고, 글자색은 그대로 둡니다.

</VariantRow>

- `tone` 은 라벨 · `mark` · `leading` · 화살표의 색을 바꾸고, `critical` 은 hover · 포커스 · 눌림 바탕도 따로 정합니다. `description` 과 `shortcut` 은 두 톤 모두 `onSurfaceVariant` 입니다.
- `neutral` 은 hover · 포커스 · 눌림에 바탕을 따로 채우지 않고 전경색을 8% · 8% · 12%(`stateLayer`)로 덮습니다. `critical` 은 이 덮기 대신 `errorContainer` 바탕을 씁니다. 에러 색을 투명한 행에 옅게 덮으면 알아보기 어렵기 때문입니다.
- 선택한 행(`selected`)은 두 톤이 같은 `primary` 바탕과 `onPrimary` 글자를 씁니다.
- `critical` 은 색으로 위험을 알립니다. 색이 유일한 단서가 되지 않도록 묶음의 마지막, 구분선 뒤에 놓습니다([위험한 행의 자리](#위험한-행의-자리)). 색을 강제하는 모드에서는 두 톤의 색 차이가 사라질 수 있습니다.

<a id="밀도-size-32-36-48"></a>
<a id="defaultsbysize-defaultsbytone"></a>

## 크기

`size`(`CoreMenuItemSize`)는 `sm`(기본) · `md` · `lg` 세 단입니다. 행의 최소 높이 · 여백 · 자리 간격 · 모서리 · 앞 아이콘 · 글자 역할을 함께 바꿉니다. 조사한 디자인 시스템들이 메뉴 행을 32 아래나 48 위로 그리지 않아 `xs` · `xl` 단은 두지 않았습니다. 표의 값은 기본 밀도의 값입니다.

<SizeSpec component="menu-item" props="leading=copy;shortcut=⌘C" label="복사" />

라벨 글자 역할은 `sm` · `md` 가 `labelLarge`, `lg` 가 `labelXl` 입니다. 설명은 차례로 `bodyXs` · `bodySmall` · `bodyMedium`, 단축키는 `bodyXs` · `bodyXs` · `bodySmall` 입니다.

- `sm`(32)은 촘촘한 데스크톱 메뉴에 맞는 높이이고 기본값입니다. `lg`(48)는 터치 화면에 맞는 높이입니다. `md`(36)는 컨트롤 높이 단계 32 와 40 사이의 높이라, `md` 크기 `Select` 트리거(40)보다 낮습니다.
- 높이는 최소값입니다. 설명이 있거나 글자를 키우면 행이 늘어나고, 내용이 최소 높이보다 낮으면 세로 가운데에 놓입니다.
- `mark` 와 화살표 아이콘은 모든 크기에서 16 입니다. `reserveMark` 로 남기는 칸의 폭도 `mark` 아이콘 크기를 따릅니다.
- 표의 모서리는 행이 혼자 있을 때의 값입니다. 32 와 48 은 행 높이 × 0.25 이고, 36 × 0.25 = 9 는 모서리 단계에 없어 8 입니다. 다른 컴포넌트의 패널 안에서는 그 컴포넌트가 모서리를 정합니다([다른 컴포넌트 안의 행](#다른-컴포넌트-안의-행)).
- 밀도(`CoreDensity`)에 따라 `sm` · `lg` 의 높이가 움직입니다. `spacious` 에서는 40 · 56 이고, `compact` 에서는 `lg` 만 40 이 되고 `sm` 은 32 에 머뭅니다. `md` 36 은 컨트롤 높이 단계가 아니라 그대로입니다. 여백 · 자리 간격 · 모서리도 밀도를 따릅니다. 앞 아이콘 크기와 `label` · `description` 사이 간격 2 는 그대로입니다.
- 테마나 `menuItemStyle` 로 `minHeight` 를 직접 주면 그 높이는 밀도에 따라 바뀌지 않습니다.

<a id="설명-두-줄-lg"></a>

## 설명 줄

`description` 을 넘기면 `label` 아래에 2 간격으로 두 번째 줄을 놓습니다. 모든 크기에서 쓸 수 있고, 행은 최소 높이보다 커집니다.

<Preview demo="menu-item/description" />

설명은 `onSurfaceVariant` 이고, 선택한 행과 비활성 행에서는 라벨과 같은 색이 됩니다. 설명이 있는 행에서 Flutter 는 `mark` · `leading` · 단축키 · `trailing` 을 위(라벨 줄)에 맞추고, Jaspr Web 은 두 줄의 세로 가운데에 맞춥니다.

```dart
MenuItem(
  size: CoreMenuItemSize.lg,
  leading: Icon(LucideIcons.archive),
  label: Text('보관'),
  description: Text('보관 폴더로 옮겨요'),
  onPressed: archiveItem,
)
```

<a id="체크박스-라디오-마크"></a>

## 체크와 라디오 표시

`mark` 는 호출자가 넘기는 위젯입니다. `mark` 와 `selected` 는 서로 따로입니다. `mark` 를 넘겨도 행이 선택 모양이 되지 않고, `selected` 를 켜도 `mark` 가 생기지 않습니다.

<Preview demo="menu-item/marks" />

켜진 행과 꺼진 행이 섞인 묶음에서는 꺼진 행에 `reserveMark: true` 를 줘 라벨의 시작선을 맞춥니다. 그림의 세 번째 행처럼 둘 다 없으면 라벨이 앞으로 당겨집니다.

[Menu](/components/menu) 는 `CoreMenuItem.checkbox` · `CoreMenuItem.radio` 항목에 이 값들을 채웁니다. 켜진 체크박스에는 체크를, 켜진 라디오에는 기본으로 점(`CoreMenuRadioMark.dot`)을 `mark` 로 넣고 `selected` 를 켭니다. 체크 · 라디오 항목이 하나라도 있는 메뉴는 모든 행에 `reserveMark` 를 켭니다. 체크박스 · 라디오 역할과 켜짐 알림도 `Menu` 가 붙입니다. 행에 `mark` 를 넣는 것만으로는 역할이 바뀌지 않습니다. 일반 항목(`CoreMenuItem.action`)에 `active: true` 를 주면 `Menu` 가 그 행의 `selected` 를 켭니다.

```dart
MenuItem(
  mark: Icon(LucideIcons.check),
  label: Text('격자 보기'),
  selected: true,
  onPressed: toggleGrid,
)
```

## 서브메뉴 트리거

`hasSubmenu: true` 면 단축키 자리에 오른쪽 화살표를 그립니다. `shortcut` 을 함께 넘겨도 단축키는 그리지 않습니다.

<Preview component="menu-item" props="hasSubmenu=true;leading=external-link" label="내보내기" />

행은 서브메뉴를 열지 않습니다. 열고 닫는 일은 행을 놓은 쪽이 맡고, 행은 화살표를 그리며 Jaspr Web 에서는 `aria-haspopup="menu"` 를 붙입니다. [Menu](/components/menu) 는 `submenu` 가 있는 항목 아래에 하위 항목을 들여써 늘 펼쳐 놓습니다.

```dart
MenuItem(
  hasSubmenu: true,
  label: Text('내보내기'),
  onPressed: openExportMenu,
)
```

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 상태

행의 모양은 `tone` · `selected` · `enabled` 와 hover · 포커스 · 눌림이 정합니다.

<Preview demo="menu-item/states" />

<Note>

선택한 채 비활성인 행은 두 플랫폼이 바탕을 다르게 그립니다. Jaspr Web 만 `primary` 바탕을 칠합니다([알려진 제약](#알려진-제약)).

</Note>

### 색

| 상태 | 바탕 | 라벨 · 아이콘 · 화살표 | 설명 · 단축키 |
| --- | --- | --- | --- |
| 기본 | 없음 | `onSurface` (`critical` 은 `error`) | `onSurfaceVariant` |
| `neutral` 의 hover · 포커스 · 눌림 | 전경색을 8% · 8% · 12% 로 덮음 | 기본과 같음 | 기본과 같음 |
| `critical` 의 hover · 포커스 · 눌림 | `errorContainer` | `error` | `onSurfaceVariant` |
| 선택 | `primary`. hover · 포커스 · 눌림에는 `onPrimary` 를 8% · 8% · 12% 로 덮음 | `onPrimary` | `onPrimary` |
| 비활성 | 없음 | `disabledContent` | `disabledContent` |
| 선택한 비활성 행 | Flutter 는 없음, Jaspr Web 은 `primary` | `disabledContent` | `disabledContent` |

Jaspr Web 의 비활성 행은 여기에 더해 행 전체를 50% 불투명도로 그립니다.

### 동작

| 항목 | 동작 |
| --- | --- |
| 누를 때 | `onPressed` 를 부릅니다. `selected` 는 저절로 바뀌지 않습니다. |
| 활성 여부 | `enabled` 를 지정하지 않으면 `onPressed` 가 있을 때 활성입니다. `enabled: false` 면 `onPressed` 가 있어도 부르지 않습니다. |
| 커서 | 활성 행은 손가락 모양, 비활성 행은 금지 모양입니다. |
| 눌림 | 눌림 색을 칠하고 행이 0.97 배로 줄어듭니다(`clickableStyle.pressedScale`). |
| 키보드로 누를 때 | Flutter 는 눌림 색과 줄어듦을 잠깐(기본 100ms, 동작 줄이기에서는 0) 보입니다. Jaspr Web 은 줄어듦만 보이고 눌림 색은 보이지 않습니다. |
| 비활성 | hover 와 눌림의 모양이 없습니다. 포커스는 받습니다. |
| 손가락을 떼지 않고 고르기 | [ContextMenu](/components/context-menu) 의 `glideToSelect`(기본 꺼짐)를 켜면, 길게 눌러 메뉴를 연 손가락을 떼지 않고 옮길 때 손가락 아래의 활성 행에 눌림 색을 칠합니다. |

### 포커스 링

키보드로 포커스하면 행 바깥으로 2 를 비우고 두께 2 의 `focusRing` 링을 그립니다. 비운 간격에는 색을 칠하지 않고, 모서리는 행의 모서리를 따릅니다. 비활성 행의 링은 Flutter 만 그립니다([알려진 제약](#알려진-제약)). 링의 모양은 `menuItemStyle` 의 `clickableStyle.focusOutlineStyle` 로 바꿉니다.

## 다른 컴포넌트 안의 행

아래 컴포넌트가 그리는 목록의 행도 `MenuItem` 입니다. 각 컴포넌트가 값 몇 가지를 정해 넘깁니다.

| 놓는 곳 | 크기 | 행 모서리 | 그 밖에 정하는 것 |
| --- | --- | --- | --- |
| [Menu](/components/menu) · [DropdownMenu](/components/dropdown-menu) · [ContextMenu](/components/context-menu) · [Menubar](/components/menubar) | `Menu` 는 자기 `size` 를 모든 행에 넘깁니다. 나머지 셋은 크기 속성이 없어 `sm` 입니다 | 8 (`liquidGlass` 표면 스타일에서는 16) | 체크 · 라디오 항목의 `mark` · `selected` · `reserveMark` |
| [Select](/components/select) | `Select` 의 `size` 와 같은 이름 | 6 (패널 모서리 12 에서 안쪽 여백 6 을 뺀 값) | 고른 옵션의 `selected` 와 체크 `mark`, 모든 행의 `reserveMark` |
| [Fab](/components/fab) 의 액션 | `lg` | 8 | 액션의 아이콘을 `leading` 에 놓습니다 |

행이 크기 단의 모서리를 그대로 쓰면 `lg` 행(12)이 12 인 패널 모서리만큼 둥글어지므로, 행을 놓는 컴포넌트가 크기와 상관없이 값 하나를 정합니다. `Menu` 의 8 은 패널 모서리에서 안쪽 여백을 뺀 값(12 − 6 = 6) 대신 정한 값이며, 패널 모서리 12 를 넘지 않습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

메뉴 목록 전체가 필요하면 [Menu](/components/menu) 를 씁니다. `MenuItem` 은 직접 조립하는 오버레이나 패널에 메뉴 모양의 행이 필요할 때 놓습니다. 행을 여러 개 세로로 놓기만 해서는 방향키 이동이 생기지 않습니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 구분선과 묶음 제목이 있는 메뉴 목록 | [Menu](/components/menu) |
| 버튼을 눌러 여는 메뉴 | [DropdownMenu](/components/dropdown-menu) |
| 우클릭이나 길게 눌러 여는 메뉴 | [ContextMenu](/components/context-menu) |
| 폼에 넣을 값을 하나 고를 때 | [Select](/components/select) |
| 바텀시트나 패널의 선택지 목록 | [OptionItem](/components/option-item) |
| 메뉴가 아닌 목록 | [Listing](/components/listing) |

<a id="dont"></a>

### 위험한 행의 자리

<Cards columns="2">
<Card tone="do" eyebrow="이렇게 하세요" title="묶음 마지막, 구분선 뒤" demo="menu-item/do-critical-last">

되돌릴 수 없는 행을 나머지와 떼어 놓으면, 색을 구분하기 어려울 때도 자리로 알아볼 수 있습니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요" title="묶음 가운데" demo="menu-item/dont-critical-middle">

색이 유일한 단서가 되고, 옆 행을 누르려다 삭제를 누르기 쉽습니다.

</Card>
</Cards>

```dart
Menu(
  items: [
    CoreMenuItem.action('이름 바꾸기', onPressed: rename),
    CoreMenuItem.action('복제', onPressed: duplicate),
    CoreMenuItem.divider(),
    CoreMenuItem.action('삭제', tone: CoreMenuItemTone.critical, onPressed: remove),
  ],
)
```

<a id="do"></a>

### 한 패널에는 한 크기

`Menu` 는 자기 `size` 를 모든 행에 넘깁니다. 직접 조립하는 패널에서도 한 패널의 행은 같은 `size` 로 맞춥니다. 크기를 섞으면 행의 높이와 여백이 들쭉날쭉해집니다.

## 배치

- 행은 받은 폭을 채웁니다. `label` 이 남는 폭을 차지해 길면 줄을 바꾸고, 단축키는 줄지 않습니다.
- Flutter 에서는 폭이 정해지지 않은 자리(`Row` 의 직접 자식 등)에 그대로 놓으면 레이아웃 오류가 납니다. `Expanded` 나 `SizedBox` 로 폭을 줍니다. Flutter 의 가로 방향 `Menu` 는 행마다 폭을 내용에 맞춰 감쌉니다.

<a id="스타일-시스템-style-system"></a>
<a id="스타일-시스템-coremenuitemstyle"></a>
<a id="파라미터와-스타일"></a>
<a id="시맨틱-vs-스타일"></a>

## 테마와 스타일

무엇인지를 정하는 값(`size` · `tone` · `selected` · `enabled` · `hasSubmenu` · `reserveMark`)은 위젯 속성이고, 색 · 크기 · 간격처럼 보이는 값은 `menuItemStyle`(`CoreMenuItemStyle`) 하나로 덮어씁니다.

<a id="사용-예"></a>

<Split>

<Code language="dart" title="행 하나만 바꾸기">
MenuItem(
  label: Text('복사'),
  onPressed: copyItem,
  menuItemStyle: CoreMenuItemStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    foregroundColor: CoreColor.token(CoreColors.secondary),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    menuItem: CoreMenuItemTheme(
      style: CoreMenuItemStyle(
        selectedBackgroundColor: CoreColor.token(CoreColors.secondary),
        selectedForegroundColor: CoreColor.token(CoreColors.onSecondary),
      ),
    ),
  ),
)
</Code>

</Split>

<a id="위젯-슬롯-label-leading-mark-은-위젯-그대로"></a>

### 슬롯에 넣은 위젯

`label` · `description` · `shortcut` · `leading` · `trailing` · `mark` 은 모두 위젯(Jaspr Web 은 `Component`)을 그대로 받습니다.

- `label` · `description` · `shortcut` 에는 행이 글자 모양과 상태 색을 내려 줍니다. 그 글자에 색을 직접 주면(`Text('복사').onSurfaceVariant` 처럼) 선택 · 비활성 색이 닿지 않습니다.
- `leading` · `mark` 의 `Icon` 에는 행이 크기와 색을 내려 줍니다. 아이콘의 `iconStyle` 이나 앱의 Icon 테마(`CoreComponentTheme.icon`)에 값이 있으면 그 값이 먼저입니다.
- `trailing` 에는 크기와 색을 내려 주지 않습니다. 크기를 정하지 않은 `Icon` 은 CoUI 앱에서 20 으로 그립니다. Jaspr Web 의 `trailing` 은 행의 글자색을 물려받아 선택 · 비활성 색을 따라가지만, Flutter 는 따라가지 않습니다. Flutter 에서 선택될 수 있는 행의 `trailing` 은 `selected` 에 맞춰 색을 골라 넘깁니다.

```dart
MenuItem(
  onPressed: sync,
  leading: Icon(LucideIcons.refreshCw),
  label: Text('동기화'),
  trailing: Text('베타').labelSmall.onSurfaceVariant,
)
```

### 빠른 오버라이드 (Chain)

이미 만든 `MenuItem` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `menuItemStyle` 인자와 같게 동작합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class MenuItemChainExample extends StatelessWidget {
  const MenuItemChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreLayout.layout280,
      child:
          MenuItem(
            onPressed: () {},
            label: const Text('복사'),
            shortcut: const Text('⌘C'),
            leading: const Icon(LucideIcons.copy),
          ).withStyle(
            const CoreMenuItemStyle(
              padding: CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space16,
                vertical: CoreSpace.space8,
              ),
              contentGapStyle: CoreGapStyle(size: CoreSpace.space12),
              foregroundColor: CoreColor.token(CoreColors.primary),
            ),
          ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class MenuItemChainExample extends StatelessComponent {
  const MenuItemChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        MenuItem(
          onPressed: () {},
          label: const Text('복사'),
          shortcut: const Text('⌘C'),
          leading: const Icon(LucideIcons.copy),
        ).withStyle(
          const CoreMenuItemStyle(
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space16,
              vertical: CoreSpace.space8,
            ),
            contentGapStyle: CoreGapStyle(size: CoreSpace.space12),
            foregroundColor: CoreColor.token(CoreColors.primary),
          ),
        ),
      ],
      classes: 'w-${CoreLayout.scale.layout280}',
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
기본값 (defaultsBySize[size] · defaultsByTone[tone] · default*)
  → CoreComponentTheme.menuItem.style   // 앱 전체
  → menuItemStyle                       // 인스턴스
```

뒤로 갈수록 우선합니다.

- 최소 높이 · 여백 · 자리 간격 · 모서리 · 앞 아이콘 크기 · 글자 역할의 기본값은 `size` 가 정하고, 전경색과 `critical` 의 hover · 눌림 바탕은 `tone` 이 정합니다.
- 테마와 `menuItemStyle` 의 값은 크기와 톤에 상관없이 덮습니다. `foregroundColor` 를 주면 `critical` 행의 `error` 색도 덮이고, `hoverBackgroundColor` 를 주면 `neutral` 행도 덮기 대신 그 바탕을 칠합니다.
- 선택한 행의 글자와 아이콘은 `selectedForegroundColor`, 비활성 행은 `disabledForegroundColor` 가 정합니다. `labelStyle` 의 색은 쓰지 않습니다. `descriptionStyle` · `shortcutTextStyle` 의 색은 선택하지 않은 활성 행에 쓰입니다.
- `activeForegroundColor` 는 hover · 눌림 바탕이 있는 행(`critical`, 또는 `hoverBackgroundColor` 를 준 행)에서만 쓰입니다. 그런 행은 hover · 포커스 · 눌림 동안 라벨 · 설명 · 단축키 · 아이콘을 이 색으로 그립니다. `hoverBackgroundColor` 를 주지 않은 `neutral` 행에 이 값만 주면 아무것도 바뀌지 않습니다.
- `hoverBackgroundColor` · `pressedBackgroundColor` · `activeForegroundColor` 는 선택한 행과 비활성 행에는 쓰이지 않습니다. 선택한 활성 행은 hover · 포커스 · 눌림에 `selectedBackgroundColor` 바탕 위로 `selectedForegroundColor` 를 `stateLayer` 만큼 덮습니다.
- `Menu` · `Select` · `Fab` 이 놓은 행은 그 컴포넌트가 넘긴 값이 `menuItemStyle` 자리에 들어갑니다. 그래서 앱 전체 `CoreMenuItemTheme` 의 `borderRadius` 는 그 행에 닿지 않습니다. 메뉴 행은 `CoreMenuStyle.itemStyle`, Select 의 행은 `CoreSelectStyle.optionStyle`, Fab 의 행은 `CoreFabStyle.actionItemStyle` 로 바꿉니다.

<a id="접근성-accessibility"></a>

## 접근성

`MenuItem` 은 행 하나의 역할 · 상태 · 활성화를 맡습니다. 행 사이 이동, 메뉴 닫기, 닫은 뒤의 포커스 복귀는 행을 담은 컴포넌트가 맡습니다.

### 역할

| 놓인 곳 | Flutter | Jaspr Web |
| --- | --- | --- |
| 혼자 놓을 때 | 버튼(button). 선택 여부와 활성 여부를 함께 알립니다 | `role="menuitem"` |
| `Menu` 안 | `menuItem`. 체크 · 라디오 항목은 `Menu` 가 `menuItemCheckbox` · `menuItemRadio` 와 켜짐 여부로 알립니다 | `menuitem`. 체크 · 라디오 항목은 `Menu` 가 `menuitemcheckbox` · `menuitemradio` 와 `aria-checked` 를 붙입니다 |
| `Select` 안 | Flutter 에는 option 역할이 없어 선택 여부와 활성 여부만 알립니다 | 바깥의 `<div role="option">` 이 역할과 `aria-selected` 를 맡고, 행은 `role="presentation"` 입니다 |

Jaspr Web 은 선택한 행에 `aria-current="true"`, 비활성 행에 `aria-disabled="true"`, `hasSubmenu` 행에 `aria-haspopup="menu"` 를 붙입니다. `attributes` 로 같은 이름의 값을 주면 그 값이 우선합니다.

Flutter 에서 직접 만든 패널의 행을 메뉴 항목으로 알리려면, 패널에 `menu` 역할을 두고 `MenuRowScope` 로 감쌉니다.

```dart
CoUISemantics(
  role: CoreSemanticRole.menu,
  container: true,
  child: MenuRowScope(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MenuItem(label: Text('복사'), onPressed: copyItem),
      ],
    ),
  ),
)
```

Flutter 에서 패널이 행마다 역할을 직접 감싸 알릴 때는 그 행을 `MenuRowScope(rowRole: null, child: …)` 로 감쌉니다. 그러면 행은 자기 역할을 붙이지 않고, 선택 여부도 감싼 쪽이 알려야 합니다. 비활성 상태는 계속 행이 알립니다. 행에 다른 역할을 주려면 `rowRole` 에 그 값을 넘깁니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Enter` · `Space` | 포커스한 활성 행의 `onPressed` 를 부릅니다. 키를 뗄 때가 아니라 누를 때 부릅니다. |
| `Tab` · `Shift` + `Tab` | 혼자 놓은 행은 하나씩 멈춥니다. Jaspr Web 의 `Menu` 는 목록 하나에서 한 번 멈추고, `submenu` 로 펼친 하위 목록에서는 목록마다 한 번씩 더 멈춥니다. Flutter 의 `Menu` 는 행마다 멈춥니다. |

행 사이 이동은 행을 담은 컴포넌트의 몫입니다. Jaspr Web 의 `Menu` 는 메뉴 방향의 화살표(끝에서 처음으로 이어짐) · `Home` · `End` · 첫 글자 입력으로 행을 옮깁니다. 바깥 목록의 화살표는 하위 목록의 행으로 들어가지 않으므로, 하위 목록에는 `Tab` 으로 들어갑니다. Flutter 의 `Menu` 는 이 키들을 따로 처리하지 않습니다. `Escape` 로 닫는 일은 메뉴를 띄운 컴포넌트가 맡습니다.

#### 비활성 행도 포커스를 받습니다

WAI-ARIA 메뉴 패턴처럼 비활성 행도 키보드 순서에 남습니다. 키보드 사용자가 그 행에 닿아야 비활성이라는 안내를 들을 수 있기 때문입니다. 비활성 행에서 `Enter` · `Space` 를 눌러도 행은 동작하지 않습니다. 다만 Jaspr Web 은 비활성 행에서 `Space` 의 기본 동작을 막지 않아 페이지가 스크롤될 수 있습니다. Jaspr Web 은 `aria-disabled="true"` 를 붙이고, 혼자 놓인 행에는 `tabindex="0"` 을 둡니다. Jaspr Web 의 `Menu` 안에서는 비활성 행도 다른 행처럼 화살표 이동 순서에 들어갑니다.

### 스크린 리더

- **이름** — 이름만 정하는 속성은 없고 행 안의 글자가 읽힙니다. Jaspr Web 의 이름은 `label` · `description` · `shortcut` 과 `trailing` 의 글자를 이어 만들어집니다. 바꾸려면 `attributes` 로 `aria-label` 을 줍니다.
- **상태** — 비활성과 선택을 행이 알립니다. 서브메뉴가 있다는 사실은 Jaspr Web 만 `aria-haspopup` 으로 알리고, Flutter 는 알리지 않습니다.
- **단축키** — `shortcut` 은 화면에 보이는 글자입니다. 행은 그 단축키를 등록하지 않습니다.
- **알림** — 상태가 바뀐 것을 따로 알리는 라이브 리전은 없습니다.

### 포커스 관리

행은 마운트될 때 포커스를 옮기지 않고, 포커스를 가두거나 되돌리지 않습니다. 그 일은 행을 담은 컴포넌트가 맡습니다. 포커스 링은 키보드로 포커스했을 때 보입니다. Jaspr Web 은 활성 행을 마우스로 누르면 그 행에 포커스가 가지만 링은 보이지 않습니다. Flutter 는 눌러도 포커스를 옮기지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | 비활성 행은 포커스를 받아도 링을 그리지 않습니다. 비활성 행에는 상태 덮기도 없어, 키보드 사용자가 지금 위치를 눈으로 찾지 못할 수 있습니다. 색을 강제하는 모드에서는 링이 보입니다. Flutter 는 링을 그립니다. |
| Jaspr Web | 비활성 행에 포커스를 두고 `Space` 를 누르면 페이지가 스크롤될 수 있습니다. |
| Jaspr Web | `Menu` 의 켜진 체크 · 라디오 행에는 `aria-checked="true"` 와 함께 `aria-current="true"` 도 붙어, 보조 기술이 현재 항목이라고 덧붙여 읽을 수 있습니다. |
| Jaspr Web | 비활성 행은 `disabledContent` 색에 더해 행 전체가 50% 불투명도로 그려집니다. Flutter 는 색만 바꿉니다. `menuItemStyle` 에 `clickableStyle: CoreClickableStyle(disabledOpacity: 1)` 을 주면 불투명도를 끌 수 있습니다. |
| Jaspr Web | 선택한 비활성 행에도 `primary` 바탕을 칠해, `disabledContent` 글자가 그 위에 놓입니다. Flutter 는 바탕을 칠하지 않습니다. |
| Jaspr Web | 설명이 있는 행의 `mark` · `leading` · 단축키 · `trailing` 이 위가 아니라 세로 가운데에 놓입니다. |
| Jaspr Web | `menuItemStyle` 의 `padding` 은 `left` 값을 좌우에, `top` 값을 위아래에 씁니다. 마주 보는 두 변을 다르게 줘도 반영되지 않습니다. |
| Jaspr Web | `eventHandlers` 에 준 `click` · `mousedown` · `mouseup` · `mouseenter` · `mouseleave` · `focusout` · `keydown` · `keyup` 핸들러는 불리지 않습니다. 같은 이벤트를 행이 직접 쓰면서 덮기 때문입니다. 누름은 `onPressed` 로 받습니다. |
| Jaspr Web | 혼자 놓은 행도 `role="menuitem"` 입니다. 이 역할은 `menu` 안에서 쓰는 역할이라, 메뉴가 아닌 곳에 놓으면 `attributes: {'role': 'button'}` 처럼 바꿉니다. |
| Jaspr Web | 키보드로 누를 때 눌림 색이 보이지 않습니다. 눌림 색 규칙이 CSS `:active` 만 보는데, `<div>` 에는 키보드 입력으로 `:active` 가 켜지지 않습니다. |
| Flutter | `trailing` 은 선택 · 비활성 색을 따라가지 않습니다. 선택 행에서는 `primary` 바탕 위에 원래 색이 남습니다. |
| 공통 | `leadingIconStyle` · `markIconStyle` 은 `size` 만 반영하고 `color` 는 쓰지 않습니다. |
| 공통 | `Enter` · `Space` 를 누르고 있으면 키가 반복될 때마다 `onPressed` 가 다시 불립니다. |
| 공통 | 아이콘만 넣은 `label` 의 이름은 자동으로 만들지 않습니다. |

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은
> [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

두 플랫폼은 속성의 이름 · 순서 · 기본값이 같고, 렌더링은 각 플랫폼의 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 행의 구성 | `Clickable` 안의 바탕 상자 → `Stacks`(덮기 면 + 여백 안의 `Row`) | `Clickable` 의 `<div>`(바탕) 안에 덮기 `<div>` 와 자리들 |
| 상태 감지 | `Clickable` 의 hover · 포커스 · 눌림 콜백 | CSS `:hover` · `:focus-visible` · `:active` |
| 혼자 놓은 행의 역할 | 버튼(button) | `menuitem` |
| 선택 알림 | `Semantics(selected:)` | `aria-current="true"` |
| 서브메뉴 알림 | 없음 | `aria-haspopup="menu"` |
| 설명이 있는 행의 정렬 | 앞뒤 자리를 위에 맞춤 | 앞뒤 자리를 세로 가운데에 맞춤 |
| `mark` 칸 | 넘긴 위젯의 폭 그대로 | `mark` 아이콘 크기(기본 16) 폭의 칸 |
| `trailing` 의 색 | 상태를 따라가지 않음 | 행의 글자색을 물려받음 |
| 비활성 행 | 색만 바꿈 | 색을 바꾸고 50% 불투명도 |
| 비활성 행의 포커스 링 | 그림 | 그리지 않음 |
| 선택한 비활성 행의 바탕 | 없음 | `primary` |
| 키보드로 누를 때의 눌림 색 | 잠깐 보임 | 보이지 않음 |
| `menuItemStyle.padding` | 네 변을 모두 씀 | `left` · `top` 만 씀 |
| `chevronIconStyle.color` | 쓰지 않음(행의 상태 색) | 적용 |
| `clickableStyle.borderRadius` | 포커스 링의 모서리만 바꿈 | 반영되지 않음(행 모서리를 따름) |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers`(일부 이벤트는 불리지 않음 — [알려진 제약](#알려진-제약)) |

<a id="props-parameters"></a>

## API

Flutter 와 Jaspr Web 이 같은 속성을 씁니다. 표의 `Widget` 은 Jaspr Web 에서 `Component` 입니다. Jaspr Web 은 여기에 `id` · `classes` · `css` · `attributes` · `eventHandlers` 를 더 받습니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `Widget` | 필수 | 행의 이름. 글자 모양과 색은 행이 내려 줍니다 |
| `size` | `CoreMenuItemSize` | `sm` | 행 크기 `sm` · `md` · `lg` |
| `tone` | `CoreMenuItemTone` | `neutral` | `neutral` 은 일반 동작, `critical` 은 되돌릴 수 없는 동작 |
| `description` | `Widget?` | `null` | `label` 아래의 두 번째 줄 |
| `shortcut` | `Widget?` | `null` | 단축키 안내. `hasSubmenu` 면 그리지 않습니다 |
| `leading` | `Widget?` | `null` | 앞 아이콘이나 표시 |
| `trailing` | `Widget?` | `null` | 단축키나 화살표 뒤의 추가 자리 |
| `mark` | `Widget?` | `null` | 체크나 점 같은 켜짐 표시 |
| `reserveMark` | `bool` | `false` | `mark` 가 없어도 `mark` 칸의 폭을 남깁니다 |
| `hasSubmenu` | `bool` | `false` | 단축키 자리에 오른쪽 화살표를 그립니다. Jaspr Web 은 `aria-haspopup` 도 붙입니다 |
| `selected` | `bool` | `false` | 선택한 모양으로 그립니다. 행이 스스로 바꾸지 않습니다 |
| `enabled` | `bool?` | `null` | `null` 이면 `onPressed` 가 있을 때 활성입니다 |
| `onPressed` | `void Function()?` | `null` | 활성 행을 누르면 부릅니다 |
| `menuItemStyle` | `CoreMenuItemStyle?` | `null` | 이 행의 겉모습 덮어쓰기 |

앱 전체 덮어쓰기 `CoreMenuItemTheme` 은 `style` 하나를 받습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreMenuItemStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `minHeight` | `double?` | Minimum row height (logical px). A description line grows past it. `null` → the size ladder. |
| `padding` | `CoreEdgeInsets?` | Content insets. `null` → the size ladder. |
| `contentGapStyle` | `CoreGapStyle?` | Gap between the mark, leading, text, shortcut / chevron and trailing parts. `null` → the size ladder. |
| `labelDescriptionGapStyle` | `CoreGapStyle?` | Gap between the label and its description. `null` → [defaultLabelDescriptionGapStyle]. |
| `borderRadius` | `CoreBorderRadius?` | Corner radius. `null` → the size row's corner (`defaultsBySize[size].borderRadius`, the row height × 0.25). A panel that holds the rows sets their corner here, through its Style for the rows. |
| `leadingIconStyle` | `CoreIconStyle?` | Leading icon style (size; colour follows the foreground). `null` → the size ladder. |
| `markIconStyle` | `CoreIconStyle?` | Style of the mark (the toggle glyph). `null` → [defaultMarkIconStyle]. |
| `chevronIconStyle` | `CoreIconStyle?` | Style of the submenu chevron. `null` → [defaultChevronIconStyle]. |
| `labelStyle` | `CoreTextStyle?` | Label typography (role; colour follows the foreground). `null` → the size ladder. |
| `descriptionStyle` | `CoreTextStyle?` | Description typography and colour. `null` → the size ladder. |
| `shortcutTextStyle` | `CoreTextStyle?` | Shortcut hint typography and colour. `null` → the size ladder. |
| `backgroundColor` | `CoreColor?` | Resting fill. `null` → [defaultBackgroundColor]. |
| `foregroundColor` | `CoreColor?` | Resting label / glyph colour. `null` → the tone table. |
| `selectedBackgroundColor` | `CoreColor?` | Fill while the row is `selected`. `null` → [defaultSelectedBackgroundColor]. |
| `selectedForegroundColor` | `CoreColor?` | Foreground while selected. `null` → [defaultSelectedForegroundColor]. |
| `disabledForegroundColor` | `CoreColor?` | Foreground while disabled. `null` → [defaultDisabledForegroundColor]. |
| `hoverBackgroundColor` | `CoreColor?` | Fill while the row is hovered or keyboard-focused. `null` → the row paints no fill of its own for the state and the foreground is washed over the resting fill at [stateLayer]'s weight instead. |
| `pressedBackgroundColor` | `CoreColor?` | Fill while the row is pressed. `null` → as [hoverBackgroundColor]. It takes effect only together with [hoverBackgroundColor]. |
| `activeForegroundColor` | `CoreColor?` | Foreground while the row is hovered, focused or pressed — the label, the description, the shortcut and the glyphs. `null` → every ink keeps its resting colour (the label and the glyphs the resting foreground, the description and the shortcut their muted colour). Stated with [hoverBackgroundColor] and [pressedBackgroundColor], since the ink has to be chosen for the fill it sits on. |
| `stateLayer` | `CoreStateLayer?` | How strongly the foreground is washed over the row on hover / focus / press. `null` → [defaultStateLayer]. A tone that states an active fill takes no wash. |
| `clickableStyle` | `CoreClickableStyle?` | Style for the row's `Clickable` — focus ring, press feedback. `null` → [defaultClickableStyle]. Passed to the `Clickable` as is. |

<!-- STYLE_TABLE:END -->

<Note>

필드 표는 소스의 설명 첫 문단입니다. 지금 코드의 동작 가운데 표와 다르거나 표에 없는 것은 다음과 같습니다.

- `padding` — Jaspr Web 은 `left` 를 좌우에, `top` 을 위아래에 씁니다. `right` · `bottom` 을 다르게 줘도 반영되지 않습니다.
- `leadingIconStyle` · `markIconStyle` — 두 플랫폼 모두 `size` 만 씁니다. 색은 행의 상태가 정합니다.
- `chevronIconStyle` — `color` 는 Flutter 에서는 행의 상태 색에 덮이고, Jaspr Web 에서는 선택 · 비활성 상태에서도 그 색이 그대로 적용됩니다.
- `activeForegroundColor` — hover · 눌림 바탕이 있는 활성 행에서만 쓰이고, 선택한 행과 비활성 행에는 쓰이지 않습니다.
- `pressedBackgroundColor` — `critical` 행은 hover 바탕을 이미 갖고 있어 이 값만 줘도 반영됩니다. 눌림 바탕의 기본값(`errorContainer`)도 따로 있어, `hoverBackgroundColor` 만 바꾸면 눌림 바탕은 그대로입니다. 둘 다 바꾸려면 두 값을 함께 줍니다.
- `clickableStyle` — Flutter 는 여기에 준 `borderRadius` 로 포커스 링의 모서리만 바꿉니다. Jaspr Web 은 행의 모서리가 이깁니다. `disabledOpacity` 는 Jaspr Web 의 비활성 행에 쓰이고 Flutter 의 행에는 쓰이지 않습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="menu-item/related-menu" title="Menu">

항목 목록을 받아 `MenuItem` 행과 구분선 · 묶음 제목을 그리는 메뉴 패널입니다. [Menu](/components/menu)

</Card>
<Card component="select" props="placeholder=정렬 기준" title="Select">

폼 값을 고르는 드롭다운이며, 목록의 각 옵션이 `MenuItem` 행입니다. [Select](/components/select)

</Card>
<Card component="option-item" props="selected=true" label="최신순" title="OptionItem">

바텀시트나 패널의 선택지 목록에 놓는 줄입니다. [OptionItem](/components/option-item)

</Card>
</Cards>

메뉴를 띄우는 [DropdownMenu](/components/dropdown-menu) · [ContextMenu](/components/context-menu) · [Menubar](/components/menubar) 와, 액션 목록에 이 행을 쓰는 [Fab](/components/fab) 도 함께 보세요.
