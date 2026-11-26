---
title: ContextMenu
description: 우클릭 또는 길게 누르기로 표시되는 컨텍스트 메뉴 컴포넌트
category: menu
platforms: [flutter, web]
related: [menu, dropdown-menu, popup]
tags: [context-menu, right-click, long-press, glide, preview, haptics, lift, menu]
template: v2
source: menu/context_menu
---

# ContextMenu

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 열린 메뉴의 모습을 확인하고, 만들어진 코드를 그대로 복사하세요. 그림 아래의 영역은 같은 속성의 실제 ContextMenu 라, 우클릭하거나 터치 화면에서 길게 누르면 열립니다.

<Playground component="context-menu" />

ContextMenu 는 `child` 영역을 감쌉니다. 그 안에서 우클릭하거나 터치 · 펜으로 길게 누르거나 컨텍스트 메뉴 키(또는 `Shift+F10`)를 누르면 `items` 를 담은 패널이 열립니다. 패널은 [Menu](/components/menu) 하나이고 그 안의 누를 수 있는 행은 [MenuItem](/components/menu-item) 입니다. 크기를 고르는 속성이 없어 행은 `Menu` 의 기본 크기인 sm(최소 높이 32)으로 그려집니다. [글라이드](#글라이드로-고르기) · [미리보기](#미리보기) · [햅틱](#선택-햅틱) · [들어 올리기](#들어-올리기)는 모두 꺼진 채로 시작합니다.

<Note>

무대의 열린 패널은 페이지 안에 그린 그림입니다. 실제 ContextMenu 의 패널은 열리면 화면 위의 오버레이에 올라가므로 제자리에 둘 수 없습니다. 그림은 ContextMenu 가 패널에 그리는 `Menu` 를 같은 항목으로 그린 것입니다. 그래서 `Menu` · `MenuItem` · `Popup` 의 테마와 서페이스 스타일은 그림에도 닿지만, `CoreComponentTheme.contextMenu` 로 바꾼 값과 열고 닫는 움직임, 실제 들어 올림은 보이지 않습니다. 그림 속 패널의 자리는 설명을 위한 배치이고, 실제 패널은 누른 지점을 기준으로 열립니다([배치](#배치)). 이 페이지의 다른 미리보기도 그림이라 우클릭해도 열리지 않습니다. 실제 ContextMenu 는 플레이그라운드의 그림 아래 영역뿐입니다.

글라이드와 햅틱은 터치 · 펜에서만 확인할 수 있습니다. **비활성**을 켜면 그림이 사라지고 아래 영역은 메뉴를 열지 않습니다. `CoUIWeb` 은 기본으로 브라우저의 우클릭 메뉴를 막으므로, 이 페이지에서는 이때 우클릭해도 아무 메뉴도 뜨지 않을 수 있습니다. Flutter 팬에서 연 메뉴는 그 팬 안에 열립니다.

</Note>

## 구조

<Anatomy demo="context-menu/anatomy">
<AnatomyItem select="[data-docs-part=child]" side="left" name="child">

메뉴를 여는 영역입니다. ContextMenu 는 이 영역의 모양을 바꾸지 않습니다. 그림의 테두리와 여백은 `child` 로 넣은 `OutlinedContainer` 의 것입니다. Flutter 는 `child` 에 상자를 더하지 않고, Jaspr Web 은 `child` 를 `relative inline-block` 인 `<div>` 로 감쌉니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=panel]" side="left" name="panel">

열린 패널, 곧 `Menu` 의 판입니다. 배경은 `surfaceBright`, 테두리는 1px `outlineVariant`, 모서리는 12, 그림자는 `lg` 단계입니다. 안쪽 여백은 6, 행 사이는 2이고, 폭은 240에서 280 사이에서 내용에 맞춥니다.

</AnatomyItem>
<AnatomyItem select="[role=menuitem]" side="right" name="item">

행 하나입니다. 최소 높이 32, 안쪽 여백은 가로 8 · 세로 6, 모서리 8, 부분 사이 8입니다. 라벨은 `labelLarge`, 앞 아이콘은 16, 단축키 힌트는 `bodyXs` 글자에 `onSurfaceVariant` 색입니다. `tone` 이 `critical` 인 행은 라벨과 아이콘이 `error` 색입니다.

</AnatomyItem>
<AnatomyItem select="[role=separator]" side="right" name="divider">

`CoreMenuItem.divider` 입니다. `outlineVariant` 색의 선이고 위아래로 4를 띄웁니다.

</AnatomyItem>
</Anatomy>

<a id="coremenuitem-컨텍스트-메뉴에서-쓰는-종류"></a>

## 항목

`items` 는 [Menu](/components/menu) · [DropdownMenu](/components/dropdown-menu) · [Menubar](/components/menubar) 와 같은 `CoreMenuItem` 목록입니다. 어떤 생성자를 쓰는지가 항목의 종류를 정합니다. ContextMenu 에는 variant 가 없고, 행의 모양은 [Menu](/components/menu) 에서 확인할 수 있습니다.

| 생성자 | 주로 쓰는 값 | 고르면 |
| --- | --- | --- |
| `CoreMenuItem.action` | 라벨(첫 인자) · `shortcut` · `disabled`(기본 `false`) · `onPressed` · `tone` · `description` · `leading` · `standardAction` · `trailing` · `submenu` | `submenu` 가 없고 `onPressed` 가 있으면 메뉴를 닫기 시작한 뒤 `onPressed` 를 부릅니다. `onPressed` 가 없으면 아무 일도 하지 않고 메뉴는 열린 채입니다. `submenu` 가 있는 행은 메뉴를 닫지 않고, `onPressed` 가 있으면 부릅니다. |
| `CoreMenuItem.checkbox` | `checked` · `onChanged` | `onChanged` 에 반대 값을 넘기고, 메뉴는 열린 채입니다. |
| `CoreMenuItem.radio` | `selected` · `onChanged` · `shortcut` · `radioMark` | `onChanged` 에 `true` 를 넘기고, 메뉴는 열린 채입니다. |
| `CoreMenuItem.label` | 라벨 | 누를 수 없는 제목입니다. |
| `CoreMenuItem.divider` | — | 그룹 사이의 구분선입니다. |
| `CoreMenuItem.gap` | 크기 | 그만큼의 빈 칸입니다. |

- `shortcut` 은 라벨 뒤에 옅은 글자로 보여 주기만 합니다. 그 키를 눌러도 아무 일도 일어나지 않으므로 단축키는 앱이 따로 등록합니다.
- `disabled: true` 인 행은 흐리게 그려지고 골라도 `onPressed` · `onChanged` 를 부르지 않습니다.
- `submenu` 의 항목은 부모 행 아래에 늘 펼쳐져 있습니다. 그 안의 항목을 골라도 컨텍스트 메뉴는 닫히지 않습니다.

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 열고 닫기

| 여는 방법 | 패널이 열리는 자리 | 조건 |
| --- | --- | --- |
| 우클릭 | 누른 지점 | `child` 안에서 누릅니다. |
| 길게 누르기 | 손가락이 처음 닿은 지점 | Flutter 는 모바일 플랫폼(iOS · Android · Fuchsia)에서, Jaspr Web 은 포인터가 터치 · 펜일 때(운영체제와 무관) |
| 컨텍스트 메뉴 키 · `Shift+F10` | Flutter 는 포커스를 가진 요소의 가운데, Jaspr Web 은 브라우저 이벤트의 좌표(좌표가 없으면 그 요소의 가운데) | `child` 안의 요소가 포커스를 가지고 있어야 합니다. |
| `controller.show()` | `child` 의 가운데 | `controller` 를 넘겼을 때 |

`enabled: false` 면 네 가지 모두 메뉴를 열지 않습니다. `submenu` 가 없고 `onPressed` 가 있는 액션을 고르면 메뉴를 **먼저** 닫기 시작한 뒤 그 `onPressed` 를 부릅니다. 화면 가장자리에서 패널의 자리를 옮기는 방식은 [배치](#배치)에 있습니다.

### 길게 누르기

- 500ms(`CoreContextMenuContract.defaultLongPressDuration`) 동안 누르고 있으면 열립니다. 그 전에 떼거나, 누른 채 18(`CoreContextMenuContract.defaultLongPressSlop` — Flutter 는 논리 픽셀, Jaspr Web 은 CSS 픽셀)보다 멀리 움직이면 열리지 않습니다. 꼭 18만큼 움직인 것은 아직 누르는 것으로 봅니다. 한 번 취소된 누르기는 손가락이 돌아와도 취소된 채입니다.
- 두 플랫폼이 같은 시간 · 거리 · 위치(처음 닿은 곳)를 씁니다. 이 시간은 전환이 아니라 누름의 기준이라 동작 줄이기 설정으로 줄지 않습니다. 0이 되면 모든 터치가 길게 누르기가 되기 때문입니다.
- Jaspr Web 에서는 마우스로 오래 눌러도 열리지 않습니다. 누르는 동안 페이지나 스크롤 영역이 스크롤되거나 화면 크기가 바뀌면 취소합니다. 손가락 아래가 더 이상 처음 누른 곳이 아니기 때문입니다.
- Jaspr Web 은 브라우저의 `contextmenu` 이벤트에 맡기지 않고 시간을 직접 잽니다. 길게 누르는 동안 이 이벤트를 보내는 브라우저, 손가락을 뗄 때 보내는 브라우저, 보내지 않는 브라우저가 있어 이벤트에 맡기면 열리는 시점이 달라집니다. 같은 누르기에서 온 `contextmenu` 는 다시 열기로 세지 않습니다. 메뉴를 연 누르기에서 손가락을 떼면 `touchend` 의 기본 동작을 막아, 브라우저가 그 터치로 만드는 `click` 이 페이지에 가지 않게 합니다. Flutter 에서는 길게 누르기가 제스처를 이겨 아래 내용이 탭을 받지 않습니다.

### 키보드로 열기

ContextMenu 는 `Tab` 으로 갈 자리를 새로 만들지 않습니다. 컨텍스트 메뉴 키와 `Shift+F10` 은 `child` 안에서 포커스를 가진 요소에서 눌러야 닿습니다. 그래서 `child` 에 포커스를 받는 요소가 없으면 키보드로 열 수 없습니다. Flutter 는 두 키를 모든 플랫폼에서 직접 받아 그 요소의 가운데에 메뉴를 열고, 키를 누르고 있어도 한 번만 처리합니다. Jaspr Web 은 브라우저가 그 키에 대해 보내는 `contextmenu` 이벤트를 받으므로, 어느 키가 그 이벤트를 만드는지는 브라우저와 운영체제가 정합니다. 이벤트에 좌표가 없으면(`clientX` · `clientY` 가 모두 0) 이벤트가 향한 요소의 가운데에, 좌표가 있으면 그 좌표에 엽니다.

### 코드에서 열고 닫기

`controller` 에 `PopoverController` 를 넘기면 `show()` · `close()` · `toggle()` 로 열고 닫고, `isOpen` 과 `addListener` 로 상태를 읽습니다. [Popover](/components/popover) 와 같은 타입입니다. 직접 만든 컨트롤러는 직접 `dispose()` 합니다. 키보드나 터치로 닿기 어려운 영역이라면, 보이는 버튼에 같은 컨트롤러를 연결합니다.

<Code language="dart" title="보이는 버튼으로도 열기">
// State 의 필드로 두고, dispose() 에서 menuController.dispose() 를 부릅니다.
final menuController = PopoverController();

// build 안에서
ContextMenu(
  controller: menuController,
  items: items,
  child: fileRow,
)

// 같은 화면의 보이는 버튼
Button(
  variant: CoreButtonVariant.outline,
  onPressed: menuController.show,
  child: Text('작업 보기'),
)
</Code>

### 닫기

- 메뉴 바깥을 왼쪽 클릭하거나 탭하거나 `Escape` 를 누르면 닫힙니다. `controller` 의 `close()` 로도 닫습니다. Flutter 에서 열려 있는 영역 밖의 우클릭은 메뉴를 닫지 않고 뒤 화면에 닿을 수 있습니다.
- `submenu` 가 없고 `onPressed` 가 있는 액션을 고르면 닫힙니다. checkbox · radio, `submenu` 행, `onPressed` 가 없는 액션은 메뉴를 닫지 않습니다.
- Flutter 에서는 열려 있는 영역을 다시 우클릭하거나 길게 눌러도 닫힙니다. 컨텍스트 메뉴 키는 포커스가 `child` 로 돌아와 있을 때 다시 누르면 닫습니다.
- Jaspr Web 의 `CoUIWeb` 아래에서는 열려 있는 동안 뒤 화면이 막힙니다. 이때의 우클릭은 바깥을 누른 것으로 처리되어 닫힙니다. 브라우저의 기본 메뉴는 `CoUIWeb` 이 기본으로 막으며, `disableBrowserContextMenu: false` 면 함께 뜰 수 있습니다. 열려 있는 동안의 길게 누르기는 ContextMenu 가 받지 않으므로 바깥을 탭해 닫습니다.
- 스크롤해도 닫히지 않습니다. 패널은 연 자리를 따라 `child` 와 함께 움직입니다.

### 열려 있는 동안 바꾸기

- 새 `items` 목록을 넘기면 열린 패널이 새 항목으로 바뀝니다. 다시 열지 않아도 됩니다. Flutter 는 같은 목록 객체의 내용만 고치면 알아채지 못하므로 새 목록을 넘깁니다.
- 열린 채 `enabled` 를 `false` 로 바꾸거나 `items` 를 비우면 Jaspr Web 은 메뉴를 닫고, Flutter 는 열린 채로 둡니다.

### 애니메이션

패널은 열 때 150ms, 닫을 때 100ms 동안 크기(90%에서 100%)와 불투명도가 바뀌며 나타나고 사라집니다. 이 시간은 `menuStyle.popupStyle` 의 `openAnimationDuration` · `closeAnimationDuration` 으로 바꿉니다. 운영체제의 동작 줄이기를 켜면 움직임 없이 바로 바뀝니다. [들어 올리기](#들어-올리기)를 켠 메뉴는 닫힐 때 패널이 `child` 쪽으로 접힙니다.

행의 색 전환은 플랫폼마다 다릅니다. Flutter 에서 일반 행의 hover · 눌림 색은 전환 없이 바로 바뀌고, `critical` 행의 강조 채움은 150ms 동안 바뀝니다. Jaspr Web 은 `CoUIWeb` 의 테마 색 전환(`enableThemeAnimation`, 기본값 `true`)이 켜져 있으면 행의 hover · 눌림 색도 150ms 동안 바뀝니다.

<a id="글라이드-미리보기-햅틱-opt-in"></a>
<a id="글라이드로-고르기-glidetoselect"></a>

## 글라이드로 고르기

`glideToSelect: true` 면 터치 · 펜으로 길게 눌러 연 메뉴에서 **그 손가락을 떼지 않고 움직여** 행을 고릅니다. 메뉴는 누른 지점에 바로 열려 손가락이 첫 행 모서리 위에 놓이는데, 손이 방금 덮은 작은 표적을 다시 겨누지 않아도 됩니다. 꺼 두면 손가락을 어디서 떼든 메뉴가 열린 채 남아 탭으로 고릅니다.

| 손가락이 | 일어나는 일 |
| --- | --- |
| 메뉴가 열린 지점에서 18(`CoreContextMenuContract.defaultGlideSlop`)을 넘지 않은 채 뗍니다 | 아무 일도 없고 메뉴는 열린 채 남습니다. 읽으려던 사람이 놓은 것이지 고른 것이 아닙니다. |
| 그 거리를 넘어 움직입니다 | 글라이드가 시작되고, 손가락 아래의 **활성** 행이 눌린 모양으로 켜집니다. 시작한 글라이드는 손가락이 처음 자리로 돌아와도 이어집니다. |
| 활성 행 위에서 뗍니다 | 그 행을 탭한 것처럼 실행합니다. 탭과 같이 `submenu` 가 없고 `onPressed` 가 있는 액션 행은 메뉴를 닫고, checkbox · radio 행은 메뉴를 연 채 둡니다. |
| 비활성 행 · 구분선 · 행 사이 · 패널 밖에서 뗍니다 | 아무것도 실행하지 않고 메뉴를 닫습니다. |
| 시스템이 손가락을 가져갑니다 | 아무것도 고르지 않고 메뉴는 열린 채 남습니다. |

- **어느 행인가**: 행 상자는 왼쪽 · 위 변을 포함하고 오른쪽 · 아래 변은 포함하지 않습니다. 상자가 겹치면 먼저 오는 행이 이깁니다. 비활성 행은 건너뛰지 않고 그 행 자체로 쳐서 아무것도 켜지 않습니다. 손가락이 그 행 위에 있는데 뒤의 행이 켜지면 안 되기 때문입니다.
- **언제 시작하나**: 거리는 처음 닿은 곳(메뉴가 열린 지점)에서 재며, 길게 누르기의 허용 거리와 같은 값을 같은 방식(넘어야 함)으로 비교합니다.
- **언제 끝나나**: 손가락을 떼거나 시스템이 가져갈 때, 그리고 메뉴가 닫힐 때(`Escape` · 바깥 누르기 · 항목 선택)입니다. 닫힌 메뉴 위에서 손가락을 떼도 아무것도 실행되지 않습니다.
- **어떤 메뉴에 닿나**: 길게 눌러 연 메뉴에만 있습니다. 우클릭 · 키보드 · `controller` 로 연 메뉴에는 따라갈 손가락이 없어 달라지는 것이 없습니다.
- **긴 메뉴**: 목록이 스크롤되는 메뉴에서도 동작합니다. 손가락이 움직이거나 뗄 때마다 행의 위치를 다시 재므로, 다른 손가락이나 휠로 스크롤한 목록에서도 손가락 아래의 행이 켜집니다. 보이지 않는 부분은 대상이 아닙니다. 글라이드가 목록을 스스로 스크롤하지는 않습니다. 손가락이 멈춘 채 목록만 스크롤되면 켜진 행은 손가락이 다시 움직이거나 뗄 때 바뀌고, 떼는 순간의 판정은 그때의 위치를 씁니다. 보이지 않는 행은 탭이나 키보드로 고릅니다.

어느 행이 켜지고 뗄 때 무엇이 일어나는지는 두 플랫폼이 같은 규칙으로 정합니다.

<Code language="dart" title="글라이드 · 햅틱 · 미리보기 켜기">
ContextMenu(
  glideToSelect: true,
  haptics: true,
  preview: Text('분기 보고서.pdf'),
  items: [
    CoreMenuItem.action('열기', onPressed: openFile),
    CoreMenuItem.action('공유', onPressed: shareFile),
    const CoreMenuItem.divider(),
    CoreMenuItem.action('삭제', onPressed: deleteFile),
  ],
  child: Text('분기 보고서.pdf'),
)
</Code>

<a id="미리보기-preview"></a>

## 미리보기

`preview` 는 메뉴가 열려 있는 동안 메뉴 옆에 떠 있는 위젯입니다. 사진 · 메시지 · 기록처럼 메뉴가 가리키는 대상을, 손가락이나 행에 가리는 원래 자리보다 크게 보여 줍니다. `null` 이면 아무것도 그리지 않습니다.

<Preview demo="context-menu/preview" height="hug" />

- **담는 상자**: [Popup](/components/popup) 하나에 담습니다. 안쪽 여백 16, 모서리 12, 배경 `surfaceBright`, 테두리 1px `outlineVariant`, 그림자 `lg`, 최소 폭 128입니다. 이 상자는 `CoreComponentTheme.popup` 을 따르고 `contextMenuStyle.menuStyle` 은 닿지 않습니다.
- **어디에**: 메뉴가 누른 지점에 열리고 화면 가장자리에서 뒤집거나 밀린 **뒤에** 자리를 받으므로, 미리보기는 메뉴가 실제로 놓인 자리를 기준으로 합니다. 메뉴가 놓이기 전에는 그리지 않습니다.
- **순서**: 위 → 아래 → 끝 → 시작 순서로, 미리보기를 통째로 담는 첫 쪽에 놓습니다. 끝은 왼쪽에서 오른쪽으로 쓰는 글에서는 오른쪽, 반대 방향의 글에서는 왼쪽입니다. 위아래를 먼저 보는 것은 이 기능이 필요한 휴대폰 화면에서 폭 240–280의 메뉴 옆자리가 모자라기 때문입니다.
- **어느 쪽도 담지 못하면**: 남는 자리가 가장 큰 쪽(같으면 앞선 순서)에 놓고 그 자리만큼 줄입니다. 메뉴를 덮거나 화면 밖으로 나가지 않으며, 어느 쪽에도 자리가 없으면 그리지 않습니다.
- **간격과 정렬**: 메뉴와 8(`CoreContextMenuContract.defaultPreviewGap`) 떨어집니다. 위아래에 놓을 때는 시작 변을 메뉴의 시작 변에, 옆에 놓을 때는 윗변을 메뉴의 윗변에 맞춘 뒤 화면 안으로 밀어 넣습니다.
- **조작**: 포인터를 받지 않으므로 미리보기를 누르는 것은 메뉴 바깥을 누르는 것이라 메뉴가 닫힙니다. 글라이드하는 손가락은 미리보기 위를 지나 행에 닿습니다. 메뉴의 열림 · 닫힘과 같은 시간에 나타나고 사라집니다.
- **열려 있는 동안 바꾸기**: 다른 `preview` 를 넘기면 열린 미리보기도 따라갑니다. 열린 채 새로 주거나 없애는 경우는 플랫폼마다 다릅니다([플랫폼 차이](#플랫폼-차이)).
- **Flutter 의 조건**: `Popup` 은 내용의 폭을 재서 상자를 맞춥니다. 그래서 `preview` 에는 크기를 미리 알려 줄 수 있는 위젯을 넣어야 합니다. `LayoutBuilder` 처럼 크기를 알려 주지 못하는 위젯은 오류가 날 수 있습니다.

<a id="선택-햅틱-haptics"></a>

## 선택 햅틱

`haptics: true` 면 글라이드의 강조가 **새 행에 들어설 때**(빈 곳에서든 다른 행에서든)와 손가락을 떼어 **행을 골라 실행할 때** 한 번씩 선택 틱(`CoreHapticCue.selectionTick`)이 옵니다. 행을 벗어나 빈 곳으로 가는 움직임과 한 행 안의 움직임은 조용합니다. 틱은 손가락이 움직이는 동안의 것이라 `glideToSelect` 가 없으면 이 틱은 오지 않고, 탭에는 시스템 자신의 반응이 있습니다.

`liftChild` 를 함께 켜면, 길게 눌러 누르기가 확정되고 메뉴가 열리는 순간에도 한 번 옵니다. 올라온 `child` 와 짝이 되는 확정 신호입니다. 우클릭 · 키보드 · `controller` 로 연 메뉴에는 확정할 누르기가 없어 오지 않습니다. `glideToSelect` 도 `liftChild` 도 없으면 `haptics` 는 아무것도 하지 않습니다.

햅틱은 한 가지 틱뿐이며 세기 눈금 · 패턴 · 전체를 켜고 끄는 스위치는 없습니다. 각 플랫폼이 할 수 있는 만큼으로 재생합니다.

| 플랫폼 | 재생 방법 |
| --- | --- |
| Flutter | `HapticFeedback.selectionClick` — 세기는 시스템이 정합니다. |
| Jaspr Web | `navigator.vibrate(10)` — 길이만 정할 수 있습니다. Safari 에는 이 함수가 없어 아무 일도 없고, 브라우저는 첫 탭이나 키 입력 전의 진동을 거절할 수 있으며, 데스크톱 브라우저는 호출이 성공해도 느껴지지 않습니다. |

<a id="들어-올리기-opt-in"></a>
<a id="들어-올리기-liftchild"></a>

## 들어 올리기

`liftChild: true` 면 메뉴가 열려 있는 동안 `child` 가 페이지에서 들려 올라가, 메뉴가 무엇에 대한 것인지 보입니다. 길게 누를 때는 메뉴가 뜨기 전에 `child` 가 먼저 올라와 누르기가 인식되고 있음을 알립니다. 500ms 를 기다리는 동안 아무것도 보이지 않으면 알 수 없기 때문입니다. 우클릭 · 키보드 · `controller` 로 열면 메뉴와 함께 올라오고, 어떻게 닫든 메뉴가 `child` 쪽으로 접히면서 `child` 가 내려앉습니다.

<Preview demo="context-menu/lift" height="hug" />

<Note>

그림은 완전히 올라온 순간의 크기 · 그림자 · 덮개를 기본값으로 그린 것입니다. 실제 덮개는 화면 전체를 덮지만 그림은 이 상자만 덮습니다. 실제 움직임은 플레이그라운드에서 **들어 올리기**를 켜고 확인하세요.

</Note>

<Code language="dart" title="들어 올리기 켜기">
ContextMenu(
  liftChild: true,
  haptics: true,
  items: [
    CoreMenuItem.action('열기', onPressed: openFile),
    CoreMenuItem.action('공유', onPressed: shareFile),
    const CoreMenuItem.divider(),
    CoreMenuItem.action('삭제', onPressed: deleteFile),
  ],
  child: Text('길게 눌러 보세요'),
)
</Code>

**`child` 는 올라와 있는 동안 두 번 빌드됩니다.** 올라온 것은 같은 위젯(컴포넌트)을 한 번 더 빌드한 두 번째 그림이라, `child` 가 무거우면 그동안 빌드와 그리기에 드는 비용도 두 번 듭니다. 켜기 전에 [들어 올릴 때의 제약](#들어-올릴-때의-제약)을 확인하세요.

### 들어 올림의 모양 바꾸기

올라온 `child` 의 크기, 올라오는 시간, 뒤를 덮는 정도, 그림자, 그림자 상자의 모서리, 접힐 때 줄어드는 크기는 `CoreContextMenuStyle` 의 필드입니다. 메뉴 하나는 `contextMenuStyle` 로, 모든 ContextMenu 는 `CoreContextMenuTheme.style` 로 바꿉니다. 둘이 겹치면 필드마다 메뉴 하나에 준 값이 이기고, 적지 않은 필드는 기본값이 남습니다.

| 필드 | 기본값 | 뜻 |
| --- | --- | --- |
| `liftScale` | 1.04 | 다 올라왔을 때 `child` 의 배율 |
| `liftDuration` | 300ms | 올라오는 시간, 중간에 놓았을 때 내려앉는 시간 |
| `liftDimOpacity` | 0.2 | 뒤를 덮는 `scrim` 색의 불투명도. 모달 스크림(30%)보다 옅습니다. |
| `liftCast` | `CoreShadow.lg` | 다 올라왔을 때의 그림자. 빈 목록이면 그림자 없이 올립니다. |
| `liftRadius` | 16 | 그림자를 드리우는 상자의 모서리. `child` 를 자르지는 않습니다. |
| `retractScale` | 0.3 | 닫힐 때 패널과 미리보기가 줄어드는 크기 |

<Split>

<Code language="dart" title="메뉴 하나의 들어 올림">
ContextMenu(
  liftChild: true,
  contextMenuStyle: const CoreContextMenuStyle(
    liftScale: 1.06,
    liftDimOpacity: 0.3,
    liftCast: CoreShadow.xl,
    liftRadius: CoreBorderRadius.all(CoreRadiusRole.panel),
    retractScale: 0.5,
  ),
  items: items,
  child: child,
)
</Code>

<Code language="dart" title="모든 ContextMenu 의 들어 올림">
CoreComponentTheme(
  contextMenu: CoreContextMenuTheme(
    style: CoreContextMenuStyle(
      liftScale: 1.06,
      retractScale: 0.5,
    ),
  ),
)
</Code>

</Split>

- **시간과 거리는 스타일에 없습니다.** 누르기가 확정되는 500ms(`CoreContextMenuContract.defaultLongPressDuration`), 올라오기 전의 기다림 150ms(`CoreContextMenuContract.defaultLiftDelay`), 허용 거리 18, 누르기 없이 열 때도 올리는지(`CoreContextMenuContract.defaultLiftsWithoutHold`)는 앱이 바꾸는 설정이 없는 값입니다. 두 플랫폼이 같은 시간을 기다려야 같은 손짓이 같은 결과를 냅니다.
- **`liftDuration` 은 길게 누를 때 확정을 넘지 않습니다.** 확정까지 남은 시간(500 − 150 = 350ms)보다 길게 적으면 그 시간으로 줄여 실행합니다. 올림이 확정 전에 끝나야 메뉴가 올림의 끝으로 읽히기 때문입니다. 누르기 없이 열 때는 적은 시간 그대로 올라옵니다.
- **범위 밖의 값은 잘라서 씁니다.** `liftScale` 은 1 이상이며, 숫자가 아니거나 무한이면 1입니다. `liftDimOpacity` 와 `retractScale` 은 0에서 1 사이로 자르고, 숫자가 아닌 값(NaN)이면 각각 덮지 않고, 줄이지 않습니다.

### 올라오고 내려앉는 순서

길게 누른 경우의 시간은 손가락이 닿은 순간부터 잽니다. 아래 숫자는 기본값입니다.

| 시각 | 일어나는 일 |
| --- | --- |
| 0 – 150ms | 아무것도 보이지 않습니다. 탭과 스크롤의 시작은 이 안에 끝나므로 들어 올림을 보지 못합니다. |
| 150 – 450ms | `CoreEasing.enter` 곡선으로 올라옵니다. `child` 가 1.04배로 커지고 그림자를 드리우며 뒤의 페이지가 덮입니다. 크기 · 그림자 · 덮개는 한 진행에 비례합니다. |
| 500ms | 누르기가 확정되어 메뉴가 열립니다. 올림은 확정 전에 끝나 있습니다. |
| 확정 전에 떼기 · 18보다 멀리 움직이기 · 시스템이 가져가기 · 스크롤 | 올라온 곳에서 같은 곡선으로, 올라올 때와 같은 시간에 걸쳐 내려앉습니다. 150ms 안이면 아무것도 보이지 않았으므로 그대로입니다. |
| 확정 뒤에 떼기 | 아무 일도 없습니다. 메뉴가 열려 있는 동안 `child` 는 올라온 채입니다. |

- 우클릭 · 키보드 · `controller` 로 열 때는 기다릴 누르기가 없어, 메뉴를 늦추지 않고 열리는 순간 함께 올라옵니다.
- 확정 전에 놓아 내려앉는 중에 새로 누르거나 새 메뉴가 열리면 이전 움직임은 그 자리에서 끝나고 새 들어 올림이 처음부터 시작합니다.
- 메뉴가 닫히며 내려앉는 중에 새로 누르거나 열면 Flutter 는 같은 방식으로 새로 시작합니다. Jaspr Web 은 닫힘이 끝날 때까지 새 누르기와 열기를 받지 않습니다.
- 올라오기 전에 끝나는 탭 · 스크롤은 시계만 만들고 두 번째 그림은 만들지 않습니다.

### 닫힐 때의 접힘

- `Escape`, 바깥 누르기, 항목 실행, `controller.close()`, 글라이드의 손 떼기 — 닫는 방법은 모두 같은 접힘입니다. 복사본은 그때까지의 값에서 패널의 닫힘 시간(`closeAnimationDuration`, 기본 100ms)에 걸쳐 내려앉고, 패널과 미리보기는 같은 시간에 `CoreEasing.exit` 곡선으로 `retractScale` 배까지 줄며 투명해집니다. `popupStyle` 의 `closeAnimationDuration` 을 바꾸면 둘이 함께 바뀝니다.
- 접히는 점은 원본 상자 위에서 패널의 가운데에 가장 가까운 점입니다. 패널이 `child` 옆에 열렸으면 그쪽 가장자리로 빨려 들어가고, `child` 위에 겹쳐 열렸으면 패널 자신의 가운데를 기준으로 제자리에서 줄어듭니다. 패널과 미리보기는 같은 점과 비율을 써서 하나로 접힙니다. Jaspr Web 은 닫기 시작할 때 원본을 다시 재므로, 열려 있는 동안 스크롤한 페이지에서도 지금 있는 원본으로 접힙니다. Flutter 는 복사본을 처음 띄울 때 잰 원본의 자리를 쓰므로, 열려 있는 동안 스크롤했으면 처음 자리를 기준으로 접히는 점을 정합니다.
- 복사본과 덮개가 사라지고 원본이 다시 보이는 것은 패널이 사라지는 프레임과 같은 프레임입니다.

### 복사본과 원본

- **복사본은 그림입니다.** 원본이 있던 자리와 크기에, 메뉴의 배경막 · 패널 **아래**에 그립니다. 그래서 복사본을 누르면 메뉴 바깥을 누른 것입니다. 포인터와 포커스를 받지 않고 스크린 리더에 읽히지 않습니다.
- **원본은 그대로입니다.** 레이아웃의 자리, 상태, 접근성 트리의 자리를 지키고, 복사본이 올라가 있는 동안에만 투명해집니다. 누르는 손가락은 계속 원본에 있어 길게 누르기도 끊기지 않습니다.
- **복사본에는 상태가 없습니다.** 카운터 같은 상태는 초깃값에서 시작하고, 원본의 호버 · 포커스 · 눌림 · 스크롤 위치 · 입력한 글자를 갖지 않습니다. 원본의 상태는 열고 닫는 동안 그대로입니다.
- **움직이는 동안 `child` 를 다시 빌드하지 않습니다.** 올라오고 내려앉으며 프레임마다 바뀌는 것은 복사본의 크기 · 그림자와 덮개입니다.
- **켜고 끄면** `child` 를 감싸는 요소가 달라져 `child` 아래가 다시 만들어집니다. 올라와 있는 동안 끄면 복사본과 덮개는 곧바로 사라지고, 열려 있던 메뉴는 열린 채 남았다가 닫힐 때 접히지 않고 닫힙니다. 이때 Flutter 에서는 닫히는 움직임 없이 사라질 수 있습니다.

### 들어 올릴 때의 제약

- `child` 안에 `GlobalKey` 가 있으면 두 번째 빌드가 같은 키를 써서 Flutter 가 거부합니다. 바깥에서 만들어 `child` 에 넘긴 `FocusNode` · 컨트롤러처럼 한 곳에만 붙는 것도 같습니다. 키 없이 스스로 만드는 `child` 를 들어 올리세요.
- Jaspr Web 에서는 `child` 안의 `id` 가 문서에 두 번 나타납니다. `<form>` 안의 폼 컨트롤은 제출에 두 번 실릴 수 있습니다. `id` 로 찾는 코드나 폼이 `child` 안에 있다면 켜지 마세요.
- Jaspr Web 은 켜져 있는 동안 `child` 를 블록 `<div>` 하나로 더 감쌉니다. 들어 올릴 때 `child` 를 다시 만들지 않으려는 것인데, 인라인 흐름에 섞이는 `child` 라면 줄이 바뀔 수 있습니다.
- Jaspr Web 의 복사본은 원본을 잰 크기의 상자에 놓입니다. `child` 의 스타일이 `.card > .child` 처럼 조상에 기대면 복사본이 다르게 보일 수 있습니다.
- 복사본의 그림자: Jaspr Web 은 다 올라온 값이 그림자 눈금의 단계(기본 `lg`)일 때만 서페이스 스타일을 따르고, 올라오는 중의 값은 따르지 않습니다. 그림자를 바꾸는 서페이스 스타일에서는 다 올라오는 순간 그림자가 한 번 바뀝니다. Flutter 는 모든 진행에서 서페이스 스타일을 따릅니다. 그림자를 바꾸지 않는 기본 서페이스 스타일에서는 두 플랫폼의 그림자 값이 같습니다.

## 디자이너 판단 값

계산해 낸 값이 아니라 느낌으로 정한 값입니다. `CoreContextMenuStyle` 의 값은 앱이 `contextMenuStyle` 이나 테마로 바꾸고, 접힘의 시간은 패널의 `closeAnimationDuration`(`menuStyle.popupStyle`)으로 바꿉니다. `CoreContextMenuContract` 의 값, 미리보기를 놓는 순서, 올라오고 접히는 곡선, 햅틱은 앱이 바꾸는 설정이 없습니다.

| 값 | 어디에 | 정한 값 | 다르게 하면 |
| --- | --- | --- | --- |
| 글라이드가 시작되는 거리 | `CoreContextMenuContract.defaultGlideSlop` | 18 (길게 누르기의 허용 거리와 같음) | 더 크게(24 · 32) 하면 실수로 시작할 일은 줄지만 첫 행들에 손이 덜 닿습니다. 더 작게 하면 누르는 동안 흐른 손이 뗄 때 행을 고릅니다. |
| 미리보기와 메뉴의 간격 | `CoreContextMenuContract.defaultPreviewGap` | 8 | 12 · 16 이면 둘이 더 떨어져 보이고, 4 면 한 덩어리로 붙습니다. |
| 미리보기를 놓는 순서 | `CoreContextMenuPreview.place` | 위 → 아래 → 끝 → 시작 | 옆을 먼저 하면 넓은 화면에서는 자연스럽지만 휴대폰에서는 폭이 모자라 자주 줄어듭니다. |
| 들어 올린 크기 | `CoreContextMenuStyle.defaultLiftScale` | 1.04 | 1.02 면 올라온 것이 거의 읽히지 않고, 1.08 이상이면 이웃을 덮어 `child` 가 바뀐 것처럼 보입니다. |
| 들어 올림 전의 기다림 | `CoreContextMenuContract.defaultLiftDelay` | 150ms | 줄이면 탭 · 스크롤의 시작에도 `child` 가 깜박이고, 늘리면 누르기가 인식되고 있다는 반응이 늦어집니다. |
| 올라오고 내려앉는 시간 | `CoreContextMenuStyle.defaultLiftDuration` | 300ms, 올라올 때와 내려앉을 때 모두 `CoreEasing.enter` | 짧으면 딱 끊겨 보이고, 길면 확정 안에 끝나지 못해 길게 누른 경우에는 350ms 로 줄어 실행됩니다. 곡선을 `CoreEasing.move` 로 하면 내려앉음이 올라옴을 거울처럼 되짚습니다. |
| 그림자의 세기 | `CoreContextMenuStyle.defaultLiftCast` | `CoreShadow.lg` | `CoreShadow.md` 면 낮게 떠 보이고, `xl` 이면 메뉴 패널의 그림자와 겹쳐 둘이 구분되지 않습니다. |
| 페이지를 덮는 정도 | `CoreContextMenuStyle.defaultLiftDimOpacity` | 20% | 더 짙으면 뒤의 맥락이 사라져 대화상자처럼 읽히고, 옅으면 올라온 `child` 가 뒤와 갈리지 않습니다. |
| 그림자 상자의 모서리 | `CoreContextMenuStyle.defaultLiftRadius` | 16 (`CoreRadiusRole.surface`) | `child` 의 모서리와 다르면 그림자가 `child` 의 모양을 따르지 않습니다. |
| 누르기 없이 열 때도 올리는가 | `CoreContextMenuContract.defaultLiftsWithoutHold` | 예 | 끄면 길게 누를 때만 올라와, 마우스 · 키보드로 여는 데스크톱에서는 들어 올림이 보이지 않습니다. |
| 접힐 때 줄어드는 크기 | `CoreContextMenuStyle.defaultRetractScale` | 0.3 | 0.5 면 접힘이 덜 보이는 대신 사라지기 전에 `child` 를 덮고 있는 시간이 깁니다. |
| 접힘의 시간과 곡선 | 패널의 `closeAnimationDuration`(100ms), `CoreEasing.exit` | 패널 닫힘과 같은 시간 | 따로 두면 복사본이 내려앉는 시각과 패널이 사라지는 시각이 어긋나 한쪽이 홀로 남습니다. |
| 확정의 햅틱 | `CoreHapticCue.selectionTick` | 글라이드의 틱과 같은 것 | 따로 두면 두 틱이 서로 다른 세기로 느껴집니다. |
| 햅틱의 세기 | `CoreHapticCue.selectionTick` | Flutter 는 시스템의 선택 틱, Jaspr Web 은 10ms (실기기에서 잰 값이 아닙니다) | Jaspr Web 의 길이를 늘리면 틱이 진동으로 읽힙니다. 모터마다 낼 수 있는 가장 짧은 길이가 다릅니다. |

## 상태

| 상태 | 모습과 동작 |
| --- | --- |
| 닫힘 | `child` 만 보입니다. ContextMenu 는 따로 표시를 더하지 않습니다. |
| 열림 | 누른 지점을 기준으로 패널이 뜨고, `preview` 가 있으면 옆에 함께 뜹니다. 바깥을 왼쪽 클릭하거나 탭하면 메뉴가 닫히고 뒤 화면의 버튼은 눌리지 않습니다(Flutter 의 예외는 [알려진 제약](#알려진-제약)에 있습니다). |
| 들어 올림 (`liftChild`) | 덮인 페이지 위로 `child` 가 올라옵니다. 길게 누르면 메뉴보다 먼저 올라옵니다. |
| 비활성 (`enabled: false`) | 우클릭 · 길게 누르기 · 키보드 · `controller` 모두 메뉴를 열지 않습니다. `child` 의 모양은 바뀌지 않습니다. |

행의 hover · 눌림 · 포커스 · 선택 · 비활성 모양은 [MenuItem](/components/menu-item) 의 것입니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

화면에 이미 있는 대상(파일, 표의 행, 카드)에 대한 보조 행동을 그 자리에서 보여 줄 때 씁니다.

- 우클릭으로 항목마다의 행동 메뉴를 줄 때
- 파일 · 행 · 카드에 상황별 행동이 필요할 때

컨텍스트 메뉴는 **보조 경로**입니다. 메뉴가 있다는 것은 화면에 보이지 않으므로, 핵심 행동은 보이는 버튼으로도 제공합니다. Jaspr Web 에서 입력창이나 링크가 든 영역을 감싸면 브라우저의 기본 메뉴(붙여넣기 · 새 탭에서 열기 등) 대신 이 메뉴가 열립니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 누른 지점이 아니라 버튼에 붙여 여는 메뉴 | [DropdownMenu](/components/dropdown-menu) |
| 가로 막대에서 여러 메뉴를 오갈 때 | [Menubar](/components/menubar) |
| 메뉴가 화면에 늘 보여야 할 때 | [Menu](/components/menu) |
| 행동 목록이 아닌 입력 · 내용 패널 | [Popover](/components/popover) |
| 폼에 들어갈 값을 고를 때 | [Select](/components/select) |

<a id="do"></a>
<a id="dont"></a>

### 여는 길과 항목 순서

<Cards columns="2">
<Card demo="context-menu/do-visible-path" tone="do" eyebrow="이렇게 하세요">

핵심 행동은 보이는 버튼으로 두고, 컨텍스트 메뉴에는 같은 행동을 빠른 길로 더합니다.

</Card>
<Card demo="context-menu/dont-only-path" tone="dont" eyebrow="이렇게 하지 마세요">

우클릭이 하나뿐인 길이면 메뉴가 있는지 알 수 없고, 포커스 받는 요소가 없는 영역은 키보드로 열 수도 없습니다.

</Card>
<Card demo="context-menu/do-critical-last" tone="do" eyebrow="이렇게 하세요">

관련 행동은 구분선으로 묶고, 위험한 행동은 `critical` 로 표시해 맨 끝에 둡니다.

</Card>
<Card demo="context-menu/dont-critical-middle" tone="dont" eyebrow="이렇게 하지 마세요">

위험한 행동을 다른 행동 사이에 끼우면 옆 행을 누르려다 잘못 누를 수 있습니다.

</Card>
</Cards>

## 배치

- 패널은 왼쪽 위 모서리를 여는 지점([열고 닫기](#열고-닫기)의 표)에 맞춰 열립니다.
- Jaspr Web 은 좌우가 모자라면 화면 안으로 밀고, 아래로 넘치는데 위로 뒤집으면 덜 넘칠 때는 여는 지점 위로 뒤집습니다. 가장자리에서는 8을 띄웁니다. 화면에 남는 높이에 들어가는 메뉴는 위아래로 밀지 않습니다([알려진 제약](#알려진-제약)).
- Flutter 는 뒤집을지 · 밀지를 여는 지점이 아니라 `child` 의 왼쪽 위 모서리를 기준으로 정합니다. 그래서 가장자리 가까이에서 연 패널이 화면 밖으로 나가거나 여는 지점에서 떨어진 곳에 열릴 수 있습니다([알려진 제약](#알려진-제약)).
- 항목이 화면에 남는 높이보다 길면, 패널이 남는 높이를 모두 차지하고 위쪽 여백에 붙어 열립니다(누른 지점을 덮을 수 있습니다). 행은 패널 안에서 스크롤되어 마지막 행까지 닿습니다. 남는 높이에 들어가는 메뉴는 높이를 줄이지 않습니다.
- 열려 있는 동안 페이지가 스크롤되면 패널은 닫히지 않고 연 자리를 따라 움직입니다.
- 패널은 앱의 오버레이에 그려져, `child` 를 감싼 상자의 `overflow` 에 잘리지 않습니다. Jaspr Web 은 `CoUIWeb`(`OverlayHost`) 아래에서 그렇습니다.
- Jaspr Web 의 루트는 `relative inline-block` 인 `<div>` 입니다. 폭을 채워야 하는 `child` 라면 ContextMenu 의 `classes` 로 `w-full` 을 줍니다. `<tr>` 처럼 `<div>` 를 둘 수 없는 자리의 요소는 감쌀 수 없습니다.
- Jaspr Web 은 앵커에 붙는 패널을 한 번에 하나만 엽니다. 이 메뉴를 열면 먼저 열려 있던 Popover · DropdownMenu · Tooltip 같은 패널이 닫힙니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

ContextMenu 의 패널은 안에 든 `Menu` 가 그립니다. 패널과 행의 겉모습은 `contextMenuStyle`(`CoreContextMenuStyle`)의 `menuStyle` 하나로 바꿉니다. 패널 상자는 `menuStyle.popupStyle`(`CorePopupStyle`), 행은 `menuStyle.itemStyle`(`CoreMenuItemStyle`), 구분선은 `menuStyle.dividerStyle`, 제목 글자는 `menuStyle.labelTextStyle` 입니다. 들어 올림의 모양은 같은 `contextMenuStyle` 의 `lift*` · `retractScale` 필드입니다([들어 올림의 모양 바꾸기](#들어-올림의-모양-바꾸기)). `child` 의 모양은 `child` 위젯에서 정합니다. 두 플랫폼이 같은 코드를 씁니다.

<Split>

<Code language="dart" title="메뉴 하나만 바꾸기">
ContextMenu(
  items: items,
  contextMenuStyle: CoreContextMenuStyle(
    menuStyle: CoreMenuStyle(
      popupStyle: CorePopupStyle(
        minWidth: CoreLayout.layout280,
        maxWidth: CoreLayout.layout320,
      ),
    ),
  ),
  child: child,
)
</Code>

<Code language="dart" title="앱의 모든 ContextMenu 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    contextMenu: CoreContextMenuTheme(
      style: CoreContextMenuStyle(
        menuStyle: CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(
            minHeight: CoreControlSize.heightMd,
          ),
        ),
      ),
    ),
  ),
)
</Code>

</Split>

### 빠른 오버라이드 (Chain)

이미 만든 `ContextMenu` 에 스타일을 덧붙일 때는 `withStyle` 을 씁니다. `contextMenuStyle` 인자에 주는 것과 같고, 여러 번 이으면 뒤의 값이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ContextMenuChainExample extends StatelessWidget {
  const ContextMenuChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ContextMenu(
      items: [
        CoreMenuItem.action('복사', onPressed: () {}),
        CoreMenuItem.action('붙여넣기', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.action('삭제', onPressed: () {}),
      ],
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: context.theme.colorScheme.outline.toValue(),
            width: CoreStrokeWidth.stroke1,
          ),
          borderRadius: BorderRadius.circular(CoreRadius.radius8),
        ),
        child: Padding(
          padding: const CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space24,
            vertical: CoreSpace.space16,
          ).toValue(geometry: Theme.of(context).geometry),
          child: Text('여기를 오른쪽 클릭해 보세요').bodyMedium,
        ),
      ),
    ).withStyle(
      const CoreContextMenuStyle(
        menuStyle: CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space12,
            ),
            contentGapStyle: CoreGapStyle(size: CoreSpace.space12),
          ),
          labelTextStyle: CoreTextStyle.token(
            CoreTextStyles.bodyMedium,
            color: CoreColor.token(CoreColors.onSurface),
          ),
          leadingColumnWidth: CoreSize.size24,
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class ContextMenuChainExample extends StatelessComponent {
  const ContextMenuChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return ContextMenu(
      items: [
        CoreMenuItem.action('복사', onPressed: () {}),
        CoreMenuItem.action('붙여넣기', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.action('삭제', onPressed: () {}),
      ],
      child: div(
        [Text('여기를 오른쪽 클릭해 보세요').bodyMedium],
        // `border-outline` matches the Flutter example's explicit
        // `outline` border colour — bare `border` would fall back to the
        // current text colour, rendering a darker box on Web only.
        classes:
            'border border-outline rounded-${CoreRadius.scale.radius8} '
            'px-${CoreSpace.scale.space24} py-${CoreSpace.scale.space16}',
      ),
    ).withStyle(
      const CoreContextMenuStyle(
        menuStyle: CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space12,
            ),
            contentGapStyle: CoreGapStyle(size: CoreSpace.space12),
          ),
          labelTextStyle: CoreTextStyle.token(
            CoreTextStyles.bodyMedium,
            color: CoreColor.token(CoreColors.onSurface),
          ),
          leadingColumnWidth: CoreSize.size24,
        ),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<Note>

예제의 `labelTextStyle` 과 `leadingColumnWidth` 는 제목(`CoreMenuItem.label`) 항목에만 닿습니다. 이 목록에는 제목이 없고 행에는 라벨만 있습니다. `contentGapStyle` 의 간격은 아이콘 · 단축키 같은 부분 사이에만 생기므로, 눈에 보이는 변화는 `itemStyle` 의 여백뿐입니다.

</Note>

<a id="resolve-chain"></a>

### 값이 정해지는 순서

패널과 행의 겉모습은 이 순서로 정해집니다.

```text
CoreMenuStyle 의 기본값 (패널 상자와 행의 나머지 값은 CorePopupStyle · CoreMenuItemStyle 의 기본값)
  → CoreComponentTheme.menu.style                      // 모든 Menu
  → CoreComponentTheme.contextMenu.style.menuStyle     // 모든 ContextMenu
  → contextMenuStyle.menuStyle                         // 인스턴스
```

들어 올림의 필드는 이 순서로 정해집니다.

```text
CoreContextMenuStyle 의 기본값
  → CoreComponentTheme.contextMenu.style               // 모든 ContextMenu
  → contextMenuStyle                                   // 인스턴스 (필드마다)
```

뒤로 갈수록 우선합니다.

- `CoreComponentTheme.popup` 과 `CoreComponentTheme.menuItem` 도 함께 적용됩니다. 다만 `Menu` 가 직접 정해 넘기는 값(패널 안쪽 여백 6, 폭 240–280, 행 간격 2, 행 모서리 8)은 기본 서페이스 스타일에서 이 두 테마로 바뀌지 않습니다. 이 값은 위 순서의 `menuStyle` 로 바꿉니다.
- 열고 닫는 시간은 `contextMenuStyle.menuStyle.popupStyle`, `CoreComponentTheme.contextMenu` 의 `style.menuStyle.popupStyle`, `CoreComponentTheme.popup` 의 `style` 에 적은 값을 따르고, 앞에 적은 것이 우선합니다. `CoreComponentTheme.menu` 에 준 시간은 ContextMenu 의 움직임에 닿지 않습니다.

<a id="접근성-accessibility"></a>

## 접근성

패널은 메뉴로, 행은 종류에 맞는 메뉴 항목으로 알립니다. `child` 영역에는 메뉴가 있다는 안내가 붙지 않습니다.

### 역할

| 부분 | Flutter | Jaspr Web |
| --- | --- | --- |
| `child` 영역 | 역할이 없습니다. 제스처 인식기(`RawGestureDetector`)와 단축키(`Shortcuts`)로 감쌉니다. 인식기는 접근성 트리에 누르기 동작을, 모바일 플랫폼에서는 길게 누르기 동작도 더합니다. | `role` 이나 `aria-*` 를 붙이지 않습니다. `attributes` 로 넘긴 값만 감싼 `<div>` 에 붙습니다. |
| 패널 | 메뉴 역할 | `role="menu"` · `aria-orientation="vertical"` |
| action 행 | 메뉴 항목 역할과 선택 · 활성 상태 | `role="menuitem"`. `active` 행은 `aria-current="true"`, `submenu` 행은 `aria-haspopup="menu"` |
| checkbox · radio 행 | `menuItemCheckbox` · `menuItemRadio` 역할과 `checked` | `menuitemcheckbox` · `menuitemradio` 와 `aria-checked`. 켜진 행에는 `aria-current="true"` 도 붙습니다. |
| 비활성 행 | 비활성 상태 | `aria-disabled="true"` |
| 구분선 | 로케일의 "구분선" 이름 | `role="separator"` 와 같은 이름의 `aria-label` |
| 미리보기 | 일반 내용으로 읽힙니다. | 담는 상자의 역할을 `presentation` 으로 바꿔 메뉴로 알리지 않습니다. |

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| 컨텍스트 메뉴 키 · `Shift+F10` (`child` 안의 포커스에서) | 포커스를 가진 요소의 가운데에 메뉴를 엽니다. | 브라우저가 보내는 `contextmenu` 이벤트로 엽니다. |
| `Tab` · `Shift+Tab` | 열린 패널의 행 사이를 돕니다. | 메뉴 전체가 `Tab` 한 칸입니다. `submenu` 마다 한 칸이 더 생깁니다. |
| `↓` · `↑` | 메뉴만의 처리는 없습니다. 웹이 아닌 Flutter 앱에서는 Flutter 의 기본 방향키 이동이 동작할 수 있습니다. | 다음 · 이전 행으로 옮기고, 끝에서 반대쪽으로 돕니다. |
| `Home` · `End` | 메뉴만의 처리는 없습니다. | 첫 · 마지막 행 |
| 글자 키 | 메뉴만의 처리는 없습니다. | 그 글자로 시작하는 라벨의 행으로 옮깁니다. 500ms 안에 이어 치면 이어서 찾습니다. |
| 행에서 `Enter` · `Space` | 고릅니다. | 고릅니다. |
| `Escape` | 닫습니다. | 닫습니다. |

Jaspr Web 의 행 이동은 패널 안의 [Menu](/components/menu) 가 맡으며, 포커스가 패널 안에 있을 때 동작합니다. 제목 · 구분선 · 빈 칸은 건너뛰고, 비활성 행에는 닿지만 골라지지 않습니다.

### 스크린 리더

- `child` 는 그대로 읽힙니다. "컨텍스트 메뉴를 가진 영역" 이라는 신호는 없습니다.
- Flutter 모바일 플랫폼에서는 스크린 리더의 길게 누르기 동작이 길게 누르기 인식기로 이어져, 메뉴가 영역의 가운데에 열립니다. 데스크톱 플랫폼에는 그 인식기가 붙지 않아 스크린 리더로 메뉴를 여는 동작이 없고, 컨텍스트 메뉴 키가 그 자리를 대신합니다.
- **패널에는 접근 가능한 이름이 없습니다.** `Menu` 의 `ariaLabel` 을 ContextMenu 로는 줄 수 없습니다. 행의 이름은 `CoreMenuItem` 의 라벨입니다.
- 열려 있는 동안 두 플랫폼 모두 뒤 화면을 보조 기술에서 막습니다. Jaspr Web 은 `CoUIWeb` 아래에서 뒤 화면을 `inert` 로 만듭니다.
- 바깥을 누를 수 없는 스크린 리더 사용자를 위한 닫기 수단이 있습니다. Flutter 는 패널 영역에 로케일의 "닫기" 이름을 가진 닫기 동작을 두어, 스크린 리더의 닫기 제스처를 쓰거나 그 영역을 활성화하면 닫힙니다. Jaspr Web 은 패널 곁에 화면에 보이지 않는 `role="button"` 요소(`aria-label` 은 같은 "닫기" 문구)를 두고, 이 요소를 활성화하면 닫힙니다. 이 요소는 `tabindex="-1"` 이라 `Tab` 순서에 없고, 키보드는 `Escape` 를 씁니다. 터치 스크린 리더에는 `Escape` 가 없으므로 이 수단으로 닫습니다. 이 "닫기" 는 닫기 동작의 이름이지 메뉴의 이름이 아닙니다.
- 열리고 닫히는 것을 따로 알리는 라이브 리전은 없고, `aria-expanded` 를 붙일 트리거 요소도 없습니다.
- 들어 올린 복사본은 읽히지 않습니다. 스크린 리더가 읽고 닿는 것은 원본 하나입니다(Flutter 는 `ExcludeSemantics`, Jaspr Web 은 `aria-hidden` 과 `inert`).

### 포커스 관리

| 때 | Flutter | Jaspr Web |
| --- | --- | --- |
| 열 때 | 패널 영역이 포커스를 받습니다. 첫 행에 놓지는 않습니다. | 포커스를 옮기지 않습니다. 뒤 화면이 `inert` 가 되면 `child` 의 포커스가 풀릴 수 있습니다. |
| 열려 있는 동안 | `Tab` 이 패널 안에서 돕니다. | 뒤 화면에는 닿지 않지만 패널 안에 가두지는 않습니다. 패널 밖으로 `Tab` 을 누르면 브라우저의 주소창 같은 곳으로 나갔다가 돌아올 수 있습니다. |
| 닫은 뒤 | ContextMenu 가 따로 옮기지는 않습니다. 패널의 포커스 범위가 사라지면 Flutter 의 포커스 기록에 따라 열기 전에 포커스가 있던 위젯으로 돌아갈 수 있습니다. 키보드로 연 메뉴를 `Escape` 로 닫으면 그 위젯으로 돌아갑니다. | 포커스를 되돌리는 처리가 없습니다. |

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 키보드로 여는 길은 `child` 안에 포커스를 받는 요소가 있을 때만 있습니다. 컴포넌트가 `Tab` 자리를 만들지 않기 때문입니다. 그런 영역의 행동은 보이는 버튼과 [코드에서 열고 닫기](#코드에서-열고-닫기)의 `controller.show()` 로도 제공합니다. |
| 공통 | `child` 영역이 메뉴의 존재를 알리지 않습니다. `aria-haspopup` 이나 대응하는 Flutter 의 표시가 없습니다. |
| 공통 | 패널에 접근성 이름을 붙일 수 없습니다. |
| 공통 | `submenu` 안의 항목을 골라도 메뉴가 닫히지 않습니다. 닫으려면 그 항목의 `onPressed` 에서 `controller` 의 `close()` 를 부릅니다. |
| 공통 | `CoreMenuItem.action` 의 `href` 로는 이동하지 않습니다. 이동은 `onPressed` 에서 합니다. |
| 공통 | `liftChild` 를 켜면 `child` 가 두 번 빌드되고, 한 곳에만 있어야 하는 것(`GlobalKey` · 중복 `id` · 폼 컨트롤)이 든 `child` 에는 쓸 수 없습니다. |
| Flutter | 방향키 · `Home` · `End` · 글자 키로 행을 옮기는 메뉴만의 처리가 없습니다. |
| Flutter | 화면 가장자리에서 패널을 뒤집을지 · 밀지를 여는 지점이 아니라 `child` 의 왼쪽 위 모서리로 정합니다. `child` 가 화면 폭을 채우는 목록 행이나 넓은 영역이거나 화면 가장자리에 붙어 있으면, 패널이 여는 지점에서 떨어진 곳에 열리거나 일부가 화면 밖으로 나갈 수 있습니다. |
| Flutter | 열려 있는 동안에도 마우스를 올리면 뒤 화면에 hover 모양이 보일 수 있고, 뒤 화면의 우클릭 · 길게 누르기나 포인터를 직접 읽는 요소(다른 `DropdownMenu` · `Popover` 트리거 류)는 반응할 수 있습니다. 다른 ContextMenu 영역을 우클릭하면 두 메뉴가 함께 열려 있을 수 있습니다. |
| Flutter | 들어 올린 메뉴가 열린 동안 페이지가 스크롤되면, 닫을 때 접히는 점이 처음 자리를 기준으로 정해져 지금 있는 `child` 와 어긋날 수 있습니다. |
| Flutter | 열린 채 `preview` 를 `null` 로 바꾸면 오류가 날 수 있습니다. 메뉴를 닫은 뒤 없앱니다. |
| Flutter | 열린 채 `enabled` 를 `false` 로 바꿔도 메뉴는 닫히지 않습니다. 닫아야 하면 `controller` 의 `close()` 를 부릅니다. |
| Flutter | `child` 영역이 스크린 리더에 누를 수 있는 것으로 알려질 수 있지만, 그 누르기로는 메뉴가 열리지 않습니다. |
| Jaspr Web | 닫아도 포커스를 되돌리지 않습니다. 키보드 사용자는 닫은 뒤 `Tab` 으로 자리를 다시 찾아야 합니다. |
| Jaspr Web | 화면 높이에는 들어가지만 여는 지점의 위와 아래 어느 쪽에도 다 들어가지 않는 메뉴는 일부가 화면 밖에 놓여, 그 행이 보이지 않을 수 있습니다. |
| Jaspr Web | `CoUIWeb(disableBrowserContextMenu: false)` 인 앱에서는 열려 있는 동안 우클릭하면 메뉴가 닫히며 브라우저의 기본 메뉴가 함께 뜰 수 있습니다. |
| Jaspr Web | ContextMenu 를 다른 ContextMenu 의 `child` 안에 겹쳐 두면 안쪽 대신 바깥 메뉴가 열릴 수 있습니다. |
| Jaspr Web | `preview` 에는 포커스를 막는 처리가 없어, 그 안의 버튼 · 링크에 `Tab` 으로 닿을 수 있습니다. 누를 것이 없는 내용만 넣습니다. |
| Jaspr Web | 행의 `leading` · `trailing` 에 Tooltip 처럼 스스로 패널을 여는 컴포넌트를 두면, 그 패널이 열릴 때 메뉴가 닫힐 수 있습니다. |
| Jaspr Web | Dialog 안에서 메뉴를 연 채 `Escape` 를 누르면 Dialog 까지 닫힐 수 있습니다. |

#### 들어 올림과 접근성 설정

들어 올림은 장식이므로 접근성 설정이 이깁니다.

| 설정 | 처리 |
| --- | --- |
| 동작 줄이기 | 올라옴 · 내려앉음 · 접힘이 바로 바뀝니다. 올라온 모습은 누르기를 알리는 반응이라 그대로 보이고, 150ms 의 기다림은 대기라 그대로입니다. 전환으로 보는 기준은 500ms(`CoreReducedMotion.transitionCeilingMs`) 이하라, 그보다 긴 `liftDuration` 은 이 설정이 건드리지 않습니다. 길게 누른 경우의 올림은 그래도 350ms 로 줄어 실행됩니다. Flutter 는 Android 의 애니메이션 끄기와 iOS 의 동작 줄이기를, Jaspr Web 은 `prefers-reduced-motion` 을 읽습니다. |
| 투명도 줄이기 | 따로 처리하지 않습니다. 복사본은 `child` 자신의 채움이고, 덮개는 뒤의 페이지만 물들이며 투명도 줄이기가 걷어 내는 유리 재질이 아닙니다. |
| 고대비 | 덮개와 그림자는 지금 색 구성의 `scrim` · `shadow` 색이라 고대비에서는 그 구성의 값으로 그립니다. |
| 강제 색 모드(Jaspr Web) | 반투명 채움이 불투명한 시스템 색으로 바뀌어 페이지를 가리므로 덮개를 뺍니다. 그림자는 브라우저가 끄고, 복사본과 메뉴는 그대로입니다. Flutter 에는 강제 색 모드가 없습니다. |

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타깃)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

두 플랫폼은 `child` · `items` · `enabled` · `preview` · `glideToSelect` · `haptics` · `liftChild` · `contextMenuStyle` · `controller` 가 같습니다. 길게 누르기의 시간 · 거리 · 위치, 글라이드의 판정, 미리보기를 놓는 규칙, 들어 올림의 진행은 두 플랫폼이 같은 규칙을 씁니다. 다른 곳은 아래와 같습니다.

### 여는 방법과 닫기

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 우클릭 | `onSecondaryTapDown` | DOM `contextmenu` |
| 길게 누르기 | `LongPressGestureRecognizer` — 모바일 플랫폼(iOS · Android · Fuchsia) | `pointerdown` 뒤 타이머 — 터치 · 펜(운영체제와 무관) |
| 키보드로 열기 | `Shortcuts` + `Actions` | DOM `contextmenu` (좌표가 없으면 대상 요소의 가운데) |
| 비활성일 때의 우클릭 | ContextMenu 는 아무것도 하지 않습니다. `CoUIApp` 은 Flutter 웹에서 브라우저 메뉴를 기본으로 끕니다(`disableBrowserContextMenu`). | ContextMenu 는 아무것도 하지 않습니다. `CoUIWeb` 도 브라우저 메뉴를 기본으로 끕니다(`disableBrowserContextMenu`). `false` 로 두었거나 `CoUIWeb` 이 없으면 브라우저의 기본 메뉴가 뜹니다. |
| 가장자리에서 뒤집고 미는 기준 | `child` 의 왼쪽 위 모서리 | 여는 지점 |
| 열린 동안 다시 우클릭 · 길게 누르기 | 닫힙니다. | 우클릭은 바깥 누르기로 닫히고, 길게 누르기는 받지 않습니다(`CoUIWeb` 아래). |
| 열린 채 `enabled: false` · 빈 `items` | 열린 채입니다. | 닫습니다. |
| 닫히는 동안 다시 열기 | 새로 열 수 있습니다. | 닫힘이 끝날 때까지 무시합니다. |
| 열린 채 `contextMenuStyle` 바꾸기 | 새 `items` 목록이나 `glideToSelect` 변경과 함께일 때 열린 패널에 반영됩니다. | 다음 렌더에 바로 반영됩니다. |
| `child` 감싸기 | 레이아웃 상자를 더하지 않습니다. | `relative inline-block` `<div>` — `id` · `classes` · `css` · `attributes` · 이벤트 처리기가 이 요소에 붙습니다. |
| 패널을 두는 곳 | 앱의 루트 `Overlay` | `CoUIWeb` 의 오버레이 호스트 메뉴 층(브라우저의 top layer) |
| 긴 목록 | 패널의 최대 높이를 레이아웃으로 제한하며, 가장자리 여백 · 시스템 바 · 키보드를 뺍니다. | 패널을 잰 뒤 `max-height` 를 걸고 목록만 스크롤합니다. 가장자리 여백만 뺍니다. 상자의 테두리 · 모서리 · 그림자는 행과 함께 밀려나지 않습니다. |
| 스크린 리더의 닫기 | 모달 패널의 닫기 접근성 동작 | 패널 곁의 숨긴 `role="button"` 요소 |

### 터치 동작과 미리보기

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 글라이드가 있는 곳 | 길게 누르기가 있는 모바일 플랫폼 | 터치 · 펜(운영체제와 무관) |
| 손가락 따라가기 | 길게 누르기가 이긴 뒤에도 오는 그 포인터의 이벤트를 포인터 라우터로 받습니다. | 누르는 순간 건 문서 수준 처리기가 그 포인터의 이벤트를 받아, 손가락이 영역을 벗어나도 따라옵니다. |
| 행의 위치 | 움직일 때마다 각 `MenuItem` 의 상자를 전역 좌표로 재고 패널 상자로 자릅니다. | 움직일 때마다 패널의 행 요소를 `getBoundingClientRect` 로 재고, 메뉴 상자와 행을 스크롤하는 목록 상자로 자릅니다. |
| 켜진 행 | `MenuItem` 이 눌린 모양으로 그립니다. | 행에 `data-coui-glide` 가 붙고 눌림과 같은 규칙으로 그립니다. |
| 행 실행 | 행의 `onPressed` 를 부릅니다. | 행의 `click()` 을 불러, 탭과 같은 길을 탑니다. |
| 페이지 스크롤 | 길게 누르기가 제스처를 이겨 스크롤이 시작되지 않습니다. | 글라이드 중 `touchmove` 의 기본 동작을 막습니다(글라이드를 켠 메뉴만). 이미 브라우저가 스크롤로 가져간 터치는 `pointercancel` 로 글라이드가 끝납니다. |
| 햅틱 | `HapticFeedback.selectionClick` | `navigator.vibrate(10)` |
| 미리보기를 두는 곳 | 루트 `Overlay` 에서 메뉴 위 | 메뉴 패널 곁의 두 번째 요소 — 메뉴와 함께 top layer 에 올라가고 함께 사라집니다. |
| 미리보기를 놓는 영역 | 창에서 가장자리 여백 · 시스템 바 · 키보드를 뺀 곳 | 화면에서 가장자리 여백을 뺀 곳 |
| 미리보기 크기 재기 | 원래 크기로 배치해 보고, 줄여야 하면 그 상자 안에서 다시 배치합니다. | 원점에 잠시 두고 원래 크기를 잰 뒤 되돌리고, 줄여야 하면 `max-width` · `max-height` 와 `overflow: hidden` 으로 가둡니다. |
| 미리보기의 포커스 | 받지 않게 막습니다. | 막는 처리가 없습니다. |
| 열린 채 `preview` 를 새로 주기 | 다음에 열 때부터 보입니다. | 바로 보입니다. |
| 열린 채 `preview` 를 없애기 | 오류가 날 수 있습니다. | 바로 사라집니다. |

### 들어 올림

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 기다림을 아는 법 | 길게 누르기 인식기의 `onLongPressDown` 에서 시작하고, 취소 · 포기 · 스크롤이 가져감 · 포인터의 끝을 알면 내립니다. | 터치를 재는 코드가 기다림의 시작과, 확정 없이 끝남(뗌 · 가져감 · 거리 · 스크롤 · 크기 변경)을 알립니다. |
| 시계 | `Ticker` — 누른 뒤 첫 프레임부터 | `requestAnimationFrame` + `performance.now()` |
| 다 올라와 있는 동안 | 시계를 멈추고 닫을 때 잇습니다. | 같습니다 — 바뀌는 것이 없으면 프레임을 요청하지 않습니다. |
| 원본의 자리 | `LayerLink` 로 원본을 따라가 스크롤해도 겹쳐 있습니다. | 원본을 재서 `position: fixed` 로 두고, 스크롤 · 크기 변경 때 다시 잽니다. |
| 접히는 점의 원본 자리 | 복사본을 처음 띄울 때 잰 자리 | 닫기 시작할 때 다시 잽니다. |
| 복사본의 층 | 루트 `Overlay` 에서 메뉴보다 먼저 넣어 메뉴 아래에 둡니다. | ContextMenu 루트 안에 두고 top layer 에 패널보다 먼저 올립니다. |
| 원본 숨기기 | `Opacity(0)` — 접근성 트리에는 남습니다(`alwaysIncludeSemantics`). | 감싼 `<div>` 의 `opacity: 0` |
| 그림자 | 상자를 오려 낸 그림자라 반투명한 `child` 에 그림자가 비치지 않습니다. | `box-shadow` (상자 바깥만 그립니다) |
| 패널의 접힘 | 패널을 `Transform` + `Opacity` 로 직접 그립니다. | `co-overlay-retract` 키프레임 |
| 서페이스 스타일의 그림자 | 모든 진행에서 따릅니다. | 다 올라온 값이 눈금 단계일 때만 따릅니다. |
| 동작 줄이기 | `resolveMotionDuration` | `CoreReducedMotion` 과 전환 시간 CSS 변수 |
| 강제 색 모드 | 없음 | 덮개를 뺍니다. |

<a id="props-parameters"></a>

## API

`W` 는 Flutter 의 `Widget`, Jaspr Web 의 `Component` 입니다. `items` 의 `CoreMenuItem<W>` 도 같은 타입을 씁니다.

### 위젯 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `W` | 필수 | 메뉴를 여는 영역 |
| `items` | `List<CoreMenuItem<W>>` | 필수 | 패널의 항목. `Menu` · `DropdownMenu` · `Menubar` 와 같은 모델입니다. |
| `enabled` | `bool` | `true` | `false` 면 어떤 방법으로도 열지 않습니다. |
| `preview` | `W?` | `null` | 열려 있는 동안 메뉴 옆에 띄우는 위젯([미리보기](#미리보기)) |
| `glideToSelect` | `bool` | `false` | 길게 눌러 연 손가락을 떼지 않고 움직여 행을 고릅니다([글라이드로 고르기](#글라이드로-고르기)). |
| `haptics` | `bool` | `false` | 글라이드와 들어 올림의 확정에 선택 틱을 줍니다([선택 햅틱](#선택-햅틱)). `glideToSelect` 도 `liftChild` 도 없으면 아무것도 하지 않습니다. |
| `liftChild` | `bool` | `false` | 열려 있는 동안 `child` 를 들어 올리고 닫힐 때 메뉴를 접습니다([들어 올리기](#들어-올리기)). `child` 가 두 번 빌드됩니다. |
| `contextMenuStyle` | `CoreContextMenuStyle?` | `null` | 패널의 겉모습(`menuStyle`)과 들어 올림의 모양(`lift*` · `retractScale`) |
| `controller` | `PopoverController?` | `null` | 코드에서 열고 닫습니다. `show()` 는 `child` 의 가운데에 엽니다. |

Jaspr Web 은 여기에 `id` · `classes` · `css` · `attributes` 와 이벤트 처리기를 더 받아 `child` 를 감싼 요소에 붙입니다. 다만 `contextmenu` 이벤트는 ContextMenu 의 처리기가 대신해, 직접 넘긴 처리기는 불리지 않습니다. 두 플랫폼 모두 `withStyle(CoreContextMenuStyle patch)` 로 `contextMenuStyle` 에 값을 덧붙인 복사본을 만듭니다.

### 테마 — `CoreContextMenuTheme`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CoreContextMenuStyle?` | `null` | 모든 ContextMenu 에 까는 값. `CoreComponentTheme.contextMenu` 에 넣습니다. DropdownMenu 의 테마와는 따로입니다. |

### 시간과 거리 — `CoreContextMenuContract`

앱이 바꾸는 설정이 아닙니다. 두 플랫폼이 같은 값을 읽습니다.

| 상수 | 값 | 뜻 |
| --- | --- | --- |
| `CoreContextMenuContract.defaultLongPressDuration` | 500ms | 길게 누르기가 확정되는 시간 |
| `CoreContextMenuContract.defaultLongPressSlop` | 18 | 누르기가 취소되기 전에 움직일 수 있는 거리 |
| `CoreContextMenuContract.defaultGlideSlop` | 18 | 이 거리를 넘으면 글라이드가 시작됩니다. |
| `CoreContextMenuContract.defaultPreviewGap` | 8 | 미리보기와 메뉴의 간격 |
| `CoreContextMenuContract.defaultLiftDelay` | 150ms | 길게 누를 때 올라오기 전의 기다림 |
| `CoreContextMenuContract.defaultLiftsWithoutHold` | `true` | 누르기 없이 열 때도 올립니다. |

들어 올림의 모양 기본값은 `CoreContextMenuStyle.default*` 에 있습니다. `CoreContextMenuContract` 의 `defaultLiftScale` · `defaultLiftDuration` · `defaultLiftDimOpacity` · `defaultLiftCast` · `defaultLiftRadius` · `defaultRetractScale` 은 사용 중단(deprecated)이므로 `CoreContextMenuStyle` 의 같은 이름 값을 씁니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreContextMenuStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `menuStyle` | `CoreMenuStyle?` | Style for the `Menu` inside — the whole look of the menu: the panel box ([CoreMenuStyle.popupStyle]), each `MenuItem` row ([CoreMenuStyle.itemStyle]), the divider, the heading text and so on. Passed as is to the inner `Menu`'s `menuStyle`, where the `Menu` lays it over `CoreMenuTheme.style`; `null` leaves the inner `Menu` at its design-system defaults. |
| `liftScale` | `double?` | The size the lifted child reaches, as a multiple of its own. `null` defers to [defaultLiftScale]. |
| `liftDuration` | `Duration?` | How long the lift takes to reach its full size, and to come back from where it got to when a press ends early. `null` defers to [defaultLiftDuration]. |
| `liftDimOpacity` | `double?` | How dark the page behind the lifted child gets at full lift, as a share of the `scrim` colour. `null` defers to [defaultLiftDimOpacity]. |
| `liftCast` | `List<CoreShadowLayer>?` | The shadow the lifted child casts at full lift. `null` defers to [defaultLiftCast]; an empty list lifts the child without a cast. |
| `liftRadius` | `CoreBorderRadius?` | The corner radius of the box the lifted child's shadow is cast from. `null` defers to [defaultLiftRadius]. |
| `retractScale` | `double?` | The size the menu panel and the preview shrink to as they fold back into the child, as a multiple of their own. `null` defers to [defaultRetractScale]. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="DropdownMenu" href="/components/dropdown-menu" more="DropdownMenu 보기">

버튼에 붙여 여는 메뉴입니다.

</Card>
<Card title="Menu" href="/components/menu" more="Menu 보기">

패널 안에 그려지는 목록입니다. 화면에 늘 보이는 메뉴로도 씁니다.

</Card>
<Card title="Popup" href="/components/popup" more="Popup 보기">

떠 있는 패널 상자입니다. 메뉴 패널과 미리보기 상자가 이것을 씁니다.

</Card>
</Cards>
