---
title: DropdownMenu
description: 트리거 클릭 시 하단에 액션 목록을 표시하는 드롭다운 메뉴 컴포넌트
category: menu
platforms: [flutter, web]
related: [menu, context-menu, popup]
tags: [dropdown, menu, overlay, actions]
template: v2
source: menu/dropdown_menu
---

# DropdownMenu

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 항목을 확인하고, 만들어진 코드를 그대로 복사하세요. 그림 아래의 **메뉴 열기** 버튼은 같은 항목의 메뉴를 실제로 엽니다.

<Playground component="dropdown-menu" />

DropdownMenu 는 `trigger` 위젯과, 그것을 누르면 아래에 뜨는 패널로 이루어집니다. 패널은 [Menu](/components/menu) 하나이고, 그 안의 누를 수 있는 행은 [MenuItem](/components/menu-item) 입니다. 행은 `items` 에 `CoreMenuItem` 으로 넣습니다. 크기를 고르는 속성이 없어, 행은 `Menu` 의 기본 크기인 sm(높이 32)으로 그려집니다.

<Note>

무대의 열린 패널은 페이지 안에 그린 그림입니다. 실제 DropdownMenu 의 패널은 열리면 화면 위의 오버레이에 올라가므로 제자리에 둘 수 없습니다. 그림은 DropdownMenu 가 패널에 그리는 `Menu` 를 같은 항목으로 그리고, 그 위에 트리거 버튼을 기본 간격 4로 놓은 것입니다. 그래서 `Menu` · `MenuItem` · `Popup` 의 테마와 서페이스 스타일은 그림에도 닿지만, `CoreComponentTheme.dropdownMenu` 로 바꾼 값은 보이지 않고 열고 닫는 움직임도 없습니다. 그림 속 버튼은 눌러도 열리지 않습니다. 실제 DropdownMenu 는 플레이그라운드의 그림 아래에만 있고, 거기서 checkbox · radio 를 바꾸면 그림도 함께 바뀝니다. Flutter 팬에서 연 메뉴는 그 팬 안에 열립니다.

</Note>

## 구조

<Anatomy demo="dropdown-menu/anatomy">
<AnatomyItem select="[data-docs-part=trigger]" side="left" name="trigger">

`trigger` 로 넘긴 위젯입니다. DropdownMenu 는 모양을 바꾸지 않고, 눌러서 열고 닫는 동작과 접근성 상태를 붙입니다. 마우스를 올리면 클릭 커서가 됩니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=panel]" side="right" name="panel">

`Menu` 의 판입니다. 배경은 `surfaceBright`, 테두리는 1px `outlineVariant`, 모서리는 12, 그림자는 `lg` 단계입니다. 행은 바깥 가장자리에서 6 안쪽에 놓이고 행 사이는 2입니다. 폭은 240에서 280 사이에서 내용에 맞춥니다.

</AnatomyItem>
<AnatomyItem select="[role=presentation]" side="left" name="label">

누를 수 없는 제목(`CoreMenuItem.label`)입니다. `labelSmall` 글자에 `onSurfaceSubtle` 색이고, 위와 좌우 여백은 행과 같으며 아래는 4입니다.

</AnatomyItem>
<AnatomyItem select="[role=menuitem]" side="right" name="item">

행 하나입니다. 최소 높이 32, 안쪽 여백은 가로 8 · 세로 6, 모서리 8, 부분 사이 8입니다. 라벨은 `labelLarge`, 앞 아이콘은 16, 단축키 힌트는 `bodyXs` 글자에 `onSurfaceVariant` 색입니다.

</AnatomyItem>
<AnatomyItem select="[role=separator]" side="left" name="divider">

`CoreMenuItem.divider()` 가 그리는 1px `outlineVariant` 선입니다. 위아래로 4씩 더 비웁니다.

</AnatomyItem>
</Anatomy>

트리거와 패널 사이는 4(`menuOffset`)입니다.

<a id="변형-variants"></a>

## 항목

`items` 의 각 항목은 `CoreMenuItem` 의 생성자가 종류를 정합니다. [Menu](/components/menu) · [ContextMenu](/components/context-menu) · [Menubar](/components/menubar) 도 같은 `CoreMenuItem` 을 받습니다. DropdownMenu 에는 variant 가 없습니다.

| 생성자 | 그리는 것 | 고르면 |
| --- | --- | --- |
| `CoreMenuItem.label` | 누를 수 없는 제목. `leading` · `trailing` 을 붙일 수 있습니다. | — |
| `CoreMenuItem.action` | 행동 행. `submenu` 를 주면 하위 항목이 아래에 펼쳐집니다. | `submenu` 가 없고 `onPressed` 가 있으면 메뉴를 닫고 `onPressed` 를 부릅니다. `submenu` 가 있는 행은 메뉴를 닫지 않고, `onPressed` 가 있으면 부릅니다. |
| `CoreMenuItem.checkbox` | 켜고 끄는 행 | `onChanged` 에 반대 값을 넘기고, 메뉴는 열린 채입니다. |
| `CoreMenuItem.radio` | 여럿 가운데 하나를 고르는 행 | `onChanged` 에 `true` 를 넘기고, 메뉴는 열린 채입니다. |
| `CoreMenuItem.divider` | 구분선 | — |
| `CoreMenuItem.gap` | 넘긴 크기만큼의 빈 칸 | — |

<Preview demo="dropdown-menu/entries" height="hug" />

- 체크 표시는 앱이 넘긴 `checked` · `selected` 를 그대로 그립니다. DropdownMenu 는 값을 들고 있지 않으므로, `onChanged` 에서 상태를 바꾸고 새 `items` 를 넘기면 열려 있는 패널이 따라 바뀝니다.
- 켜진 checkbox 와 고른 radio 행은 `primary` 채움으로 그려집니다. radio 의 표시는 `radioMark` 로 고릅니다 — `dot`(기본) 또는 `check` 입니다.
- checkbox 나 radio 가 하나라도 있으면 모든 누를 수 있는 행이 표시 자리를 비워 두어, 앞 아이콘이 없는 행끼리는 라벨이 같은 위치에서 시작합니다. 앞 아이콘이 있는 행의 라벨은 아이콘만큼 더 들어갑니다.
- `standardAction`(`cut` · `copy` · `paste` · `undo` · `redo` · `share` · `rename` · `delete`)은 앞 아이콘만 정합니다. 글자와 `onPressed` 는 직접 줍니다. `leading` 을 함께 주면 `leading` 이 그려집니다.
- `description` 은 라벨 아래의 옅은 둘째 줄입니다. 둘째 줄이 있는 행은 높아집니다.
- `tone: CoreMenuItemTone.critical` 은 라벨과 아이콘을 `error` 색으로 그립니다.
- `submenu` 가 있는 행은 끝에 꺾쇠가 붙고, 하위 항목은 16 들여서 부모 행 아래에 늘 펼쳐져 있습니다. 접고 펼치는 동작은 없으며, 하위 항목을 골라도 메뉴는 닫히지 않습니다.

<a id="단축키-힌트-비활성-엔트리"></a>

### 단축키 힌트와 비활성 행

`shortcut` 은 라벨 뒤의 끝 쪽에 옅은 글자로 보여 주기만 합니다. 그 키를 눌러도 아무 일도 일어나지 않으므로 단축키는 앱이 따로 등록합니다. `submenu` 가 있는 행은 그 자리에 꺾쇠가 놓여 힌트가 보이지 않습니다. `disabled: true` 인 행은 흐리게 그려지고 골라도 아무 일도 하지 않지만, 키보드로는 닿을 수 있습니다.

<Preview demo="dropdown-menu/shortcut" height="hug" />

```dart
DropdownMenu(
  trigger: Button(
    variant: CoreButtonVariant.outline,
    onPressed: () {},
    child: Text('편집'),
  ),
  items: [
    CoreMenuItem.action('실행 취소', shortcut: 'Ctrl+Z', onPressed: undo),
    CoreMenuItem.action('다시 실행', shortcut: 'Ctrl+Shift+Z', disabled: true, onPressed: redo),
  ],
)
```

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 열고 닫기

- 트리거를 누르면 열리고, 다시 누르면 닫힙니다. 마우스 오른쪽 버튼으로는 열리지 않습니다.
- 열려 있는 동안 뒤 화면의 버튼은 눌리지 않습니다(Flutter 의 예외는 [알려진 제약](#알려진-제약)에 있습니다). 바깥을 누르거나 `Escape` 를 누르면 닫힙니다.
- `submenu` 가 없는 action 을 고르면 메뉴를 닫기 시작한 뒤 `onPressed` 를 부릅니다. `onPressed` 가 없는 action 은 골라도 메뉴가 닫히지 않습니다.
- checkbox · radio 를 고르면 `onChanged` 를 부르고 메뉴는 그대로 둡니다.
- 열려 있는 동안 새 `items` 를 넘기면 열린 패널이 새 항목으로 바뀝니다. 다시 열지 않아도 됩니다. 열린 채 바꾼 `menuOffset` 은 다음에 열 때 반영됩니다.

트리거로 `Button` 을 쓸 때는 `onPressed: () {}` 를 줍니다. 누름은 DropdownMenu 가 따로 받으므로 콜백이 할 일은 없지만, 비워 두면 `Button` 이 비활성으로 그려지고 Jaspr Web 에서는 눌러도 메뉴가 열리지 않을 수 있습니다.

### 코드에서 열고 닫기

`controller` 에 `PopoverController` 를 넘기면 `show()` · `close()` · `toggle()` 로 열고 닫고, `isOpen` 과 `addListener` 로 상태를 읽습니다. [Popover](/components/popover) 와 같은 타입입니다. 직접 만든 컨트롤러는 직접 `dispose()` 합니다.

Flutter 의 포커스 가능한 CoUI `Button` · `Clickable` 트리거는 `Enter` · `Space` 또는 접근성 `tap` 동작으로 메뉴를 엽니다. 원래 누름 콜백도 한 번 실행됩니다. 일반 텍스트 트리거에도 기본 접근성 `tap` 동작을 제공합니다. 기존처럼 `onPressed` 에 `show` 를 명시적으로 연결해도 됩니다. CoUI 의 활성화 경로를 쓰지 않고 별도 semantics 경계를 가진 커스텀 트리거의 동작은 그대로 두므로, 메뉴를 열려면 자체 콜백에 `show` 를 연결합니다. `toggle` 을 연결하면 마우스로 눌렀을 때 상태가 두 번 뒤집혀 열리자마자 닫힐 수 있습니다. Jaspr Web 에는 이 연결을 넣지 않습니다 — 누름이 이미 메뉴를 열고 닫으므로, `show` 를 더하면 열렸다가 바로 닫힐 수 있습니다.

<Code language="dart" title="Flutter — 명시적으로 열기">
// State 의 필드로 두고, dispose() 에서 menuController.dispose() 를 부릅니다.
final menuController = PopoverController();
// build 안에서
DropdownMenu(
  controller: menuController,
  trigger: Button(
    variant: CoreButtonVariant.outline,
    onPressed: menuController.show,
    child: Text('메뉴 열기'),
  ),
  items: items,
)
</Code>

### 애니메이션

패널은 열 때 150ms, 닫을 때 100ms 동안 크기(90%에서 100%)와 불투명도가 바뀌며 나타나고 사라집니다. 운영체제의 동작 줄이기를 켜면 움직임 없이 바로 바뀝니다. 행의 색 전환은 플랫폼마다 다릅니다. Flutter 에서 일반 행의 hover · 눌림 색은 전환 없이 바로 바뀌고, `critical` 행의 강조 채움은 150ms 동안 바뀝니다. Jaspr Web 은 `CoUIWeb` 의 테마 색 전환(`enableThemeAnimation`, 기본값 `true`)이 켜져 있으면 행의 hover · 눌림 색도 150ms 동안 바뀝니다.

## 상태

행의 상태는 아래와 같이 보입니다. hover · 눌림 · 포커스는 장면에 켜 둘 수 없어 표로 설명합니다.

<Preview demo="dropdown-menu/states" height="hug" />

| 상태 | 모양 |
| --- | --- |
| 기본 | 채움이 없습니다. 라벨과 아이콘은 `onSurface` 입니다. |
| hover | 행의 글자색을 8%로 덧씌웁니다. |
| 키보드 포커스 | 8% 덧씌움과 포커스 링 |
| 눌림 | 12% 덧씌움. 행이 97% 크기로 살짝 줄어듭니다. |
| 선택 — `active`, 켜진 checkbox, 고른 radio | `primary` 채움. 라벨 · 아이콘 · 설명 · 단축키는 `onPrimary` 입니다. |
| 비활성 — `disabled` | 라벨 · 아이콘 · 설명 · 단축키가 `disabledContent` 입니다. hover 색이 없고 커서는 금지 모양입니다. Jaspr Web 은 여기에 불투명도 50%가 더해집니다. 선택된 행이 비활성이면 Flutter 는 `primary` 채움 없이 그리고, Jaspr Web 은 `primary` 채움을 남긴 채 글자와 아이콘만 `disabledContent` 로 바꿉니다. |
| 위험 — `tone` 이 `critical` | 라벨과 아이콘은 `error` 입니다. hover · 키보드 포커스 · 눌림은 덧씌움 대신 `errorContainer` 채움이고, 설명과 단축키는 옅은 색 그대로입니다. |

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

버튼 하나에 여러 행동을 모아 두고, 눌렀을 때만 보여 줄 때 씁니다.

- "더보기" 버튼에서 편집 · 공유 · 삭제 같은 행동을 보여 줄 때
- 특정 버튼에서 여는 상황별 행동 목록이 필요할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 폼에 들어갈 값을 고를 때 | [Select](/components/select) |
| 누른 자리에서 우클릭 메뉴를 열 때 | [ContextMenu](/components/context-menu) |
| 가로 막대에 메뉴 여러 개를 나란히 둘 때 | [Menubar](/components/menubar) |
| 메뉴가 화면에 늘 보여야 할 때 | [Menu](/components/menu) |
| 행동 목록이 아닌 입력 · 내용 패널 | [Popover](/components/popover) |
| 검색해서 명령을 고를 때 | [Command](/components/command) |

<a id="do"></a>
<a id="dont"></a>

### 항목 구성

<Cards columns="2">
<Card demo="dropdown-menu/do-group" tone="do" eyebrow="이렇게 하세요">

관련 있는 행동끼리 구분선으로 묶습니다. 묶음이 보이면 원하는 행동을 빨리 찾습니다.

</Card>
<Card demo="dropdown-menu/dont-value-pick" tone="dont" eyebrow="이렇게 하지 마세요">

폼의 값을 고르게 하지 않습니다. 고른 값이 트리거에 저절로 보이지 않고 필드 라벨과 오류 문구도 없습니다. 값은 [Select](/components/select) 로 받습니다.

</Card>
<Card demo="dropdown-menu/do-critical-last" tone="do" eyebrow="이렇게 하세요">

삭제처럼 위험한 행동은 `critical` 로 표시하고, 구분선 뒤 맨 끝에 둡니다.

</Card>
<Card demo="dropdown-menu/dont-critical-middle" tone="dont" eyebrow="이렇게 하지 마세요">

위험한 행동을 다른 행동 사이에 끼우지 않습니다. 쉬는 상태에서는 글자색이 유일한 표시라, 옆 행을 누르려다 잘못 누를 수 있습니다.

</Card>
</Cards>

## 배치

- 패널은 앱의 오버레이에 그려져, 트리거를 감싼 상자의 `overflow` 에 잘리지 않습니다. Jaspr Web 은 `CoUIWeb`(`OverlayHost`) 아래에서 그렇습니다.
- 패널은 트리거 아래에 왼쪽 끝을 맞춰 열립니다(`bottomStart`). 글 방향이 오른쪽에서 왼쪽이어도 왼쪽 끝을 맞춥니다. 여는 방향을 고르는 속성은 없습니다.
- 아래에 자리가 모자라면 위로 뒤집어 엽니다. Jaspr Web 은 위로 열 때 덜 넘치는 경우에만 뒤집습니다. 화면 가장자리에서는 8을 띄웁니다.
- 화면 높이에는 들어가지만 트리거 위와 아래 어느 쪽에도 다 들어가지 않는 메뉴는, Flutter 에서는 화면 안으로 밀려 트리거를 덮을 수 있고 Jaspr Web 에서는 일부가 화면 밖으로 나갈 수 있습니다.
- 오른쪽에 자리가 모자라면 Flutter 는 패널의 오른쪽 끝을 트리거의 오른쪽 끝에 맞추고, Jaspr Web 은 화면 안에 들어올 만큼 패널을 왼쪽으로 밉니다.
- 트리거와 패널 사이는 4이고 `menuOffset` 으로 바꿉니다. 위로 뒤집혀도 같은 간격을 둡니다.
- 패널의 폭은 트리거 폭을 따르지 않고 240에서 280 사이입니다.
- 항목이 화면에 남는 높이보다 길면, 패널이 남는 높이를 모두 차지하고 위쪽 여백에 붙어 열립니다(트리거를 덮을 수 있습니다). 행은 패널 안에서 스크롤되어 마지막 행까지 닿습니다. 남는 높이에 들어가는 메뉴는 높이를 줄이지 않습니다.
- 접히는 기기에서 화면이 둘로 나뉘면, 패널은 트리거가 놓인 쪽 안에 머뭅니다.

<Code language="dart" title="트리거와 패널 사이 넓히기">
DropdownMenu(
  dropdownMenuStyle: CoreDropdownMenuStyle(menuOffset: CoreSpace.space8),
  trigger: trigger,
  items: items,
)
</Code>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

DropdownMenu 의 겉모습은 `dropdownMenuStyle`(`CoreDropdownMenuStyle`) 하나로 덮어씁니다. 필드는 둘입니다 — 안의 `Menu` 에 넘기는 `menuStyle`(`CoreMenuStyle`)과, 트리거와 패널 사이의 `menuOffset` 입니다. 패널 상자는 `menuStyle.popupStyle`(`CorePopupStyle`), 행은 `menuStyle.itemStyle`(`CoreMenuItemStyle`), 구분선은 `menuStyle.dividerStyle`, 제목 글자는 `menuStyle.labelTextStyle` 로 바꿉니다. 트리거의 모양은 트리거 위젯에서 정합니다.

<Split>

<Code language="dart" title="메뉴 하나만 바꾸기">
DropdownMenu(
  trigger: trigger,
  items: items,
  dropdownMenuStyle: CoreDropdownMenuStyle(
    menuStyle: CoreMenuStyle(
      popupStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      ),
      itemStyle: CoreMenuItemStyle(minHeight: CoreControlSize.heightMd),
    ),
  ),
)
</Code>

<Code language="dart" title="앱의 모든 DropdownMenu 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    dropdownMenu: CoreDropdownMenuTheme(
      style: CoreDropdownMenuStyle(
        menuOffset: CoreSpace.space8,
        menuStyle: CoreMenuStyle(
          popupStyle: CorePopupStyle(
            minWidth: CoreLayout.layout280,
            maxWidth: CoreLayout.layout320,
          ),
        ),
      ),
    ),
  ),
)
</Code>

</Split>

### 빠른 오버라이드 (Chain)

이미 만든 `DropdownMenu` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `dropdownMenuStyle` 인자와 같게 동작합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class DropdownMenuChainExample extends StatelessWidget {
  const DropdownMenuChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      trigger: Button(
        variant: CoreButtonVariant.outline,
        onPressed: () {},
        child: const Text('메뉴 열기'),
      ),
      items: [
        CoreMenuItem.action('프로필', onPressed: () {}),
        CoreMenuItem.action('설정', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.action('로그아웃', onPressed: () {}),
      ],
    ).withStyle(
      const CoreDropdownMenuStyle(
        menuOffset: CoreSpace.space16,
        menuStyle: CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space16,
              vertical: CoreSpace.space8,
            ),
          ),
          labelTextStyle: CoreTextStyle.token(
            CoreTextStyles.labelLarge,
            color: CoreColor.token(CoreColors.primary),
          ),
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class DropdownMenuChainExample extends StatelessComponent {
  const DropdownMenuChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return DropdownMenu(
      trigger: Button(
        variant: CoreButtonVariant.outline,
        onPressed: () {},
        child: Text('메뉴 열기'),
      ),
      items: [
        CoreMenuItem.action('프로필', onPressed: () {}),
        CoreMenuItem.action('설정', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.action('로그아웃', onPressed: () {}),
      ],
    ).withStyle(
      const CoreDropdownMenuStyle(
        menuOffset: CoreSpace.space16,
        menuStyle: CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space16,
              vertical: CoreSpace.space8,
            ),
          ),
          labelTextStyle: CoreTextStyle.token(
            CoreTextStyles.labelLarge,
            color: CoreColor.token(CoreColors.primary),
          ),
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

예제의 `labelTextStyle` 은 제목(`CoreMenuItem.label`) 항목의 글자에만 닿습니다. 이 목록에는 제목이 없어 그 값으로는 보이는 변화가 없습니다.

</Note>

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreMenuStyle 의 기본값 (패널 상자와 행의 나머지 값은 CorePopupStyle · CoreMenuItemStyle 의 기본값)
  → CoreComponentTheme.menu.style                      // 모든 Menu
  → CoreComponentTheme.dropdownMenu.style.menuStyle    // 모든 DropdownMenu
  → dropdownMenuStyle.menuStyle                        // 인스턴스
```

뒤로 갈수록 우선합니다. `menuOffset` 은 기본값 4, `CoreComponentTheme.dropdownMenu.style.menuOffset`, `dropdownMenuStyle.menuOffset` 순서입니다.

- `CoreComponentTheme.popup` 과 `CoreComponentTheme.menuItem` 도 함께 적용됩니다. 다만 `Menu` 가 직접 정해 넘기는 값 — 패널의 안쪽 여백 6, 폭 240–280, 행 간격 2, 행 모서리 8 — 은 기본 서페이스 스타일에서 이 두 테마로 바뀌지 않습니다. 이 값은 위 순서의 `menuStyle` 로 바꿉니다.
- 열고 닫는 시간은 `popupStyle` 의 `openAnimationDuration` · `closeAnimationDuration` 으로 바꿉니다. `dropdownMenuStyle`, `CoreComponentTheme.dropdownMenu`, `CoreComponentTheme.popup` 에 준 값은 따르지만, `CoreComponentTheme.menu` 에 준 시간은 DropdownMenu 의 움직임에 닿지 않습니다.
- liquidGlass 서페이스 스타일에서는 Flutter 의 `Menu` 가 패널 모서리 24 · 안쪽 여백 8 · 행 모서리 16을 씁니다. Jaspr Web 의 DropdownMenu 는 문서의 스타일만 바꾸면 이 모양이 바뀌지 않을 수 있습니다. `dropdownMenuStyle.menuStyle.popupStyle` 이나 `CoreComponentTheme.popup` 의 스타일에 `surfaceStyle: CoreSurfaceStyleId.liquidGlass` 를 주면 바뀝니다. `menuStyle` 로 직접 정한 값이 있으면 그 값이 우선합니다.

<a id="접근성-accessibility"></a>

## 접근성

트리거는 열림 상태를 가진 버튼으로, 패널은 메뉴로, 행은 종류에 맞는 메뉴 항목으로 알립니다. 키보드 지원은 두 플랫폼이 크게 다릅니다.

### 역할

| 부분 | Flutter | Jaspr Web |
| --- | --- | --- |
| 트리거 | 트리거 위젯에 버튼 역할과 열림 상태(`expanded`)를 알리는 노드를 둡니다. | 트리거를 감싼 `<div>` 에 `role="button"` · `aria-haspopup="true"` · `aria-expanded` 를 붙입니다. `aria-controls` 는 없습니다. |
| 패널 | 메뉴 역할 | `role="menu"` · `aria-orientation="vertical"` |
| action 행 | 메뉴 항목 역할과 선택 · 활성 상태 | `role="menuitem"`. `active` 행은 `aria-current="true"`, `submenu` 가 있는 행은 `aria-haspopup="menu"` |
| checkbox · radio 행 | `menuItemCheckbox` · `menuItemRadio` 역할과 `checked` | `menuitemcheckbox` · `menuitemradio` 와 `aria-checked`. 켜진 행에는 `aria-current="true"` 도 붙습니다. |
| 비활성 행 | 비활성 상태 | `aria-disabled="true"` |
| 구분선 | 로케일의 "구분선" 이름 | `role="separator"` 와 같은 이름의 `aria-label` |

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| 트리거에서 `Enter` · `Space` | 포커스 가능한 CoUI `Button` · `Clickable` 트리거에서 메뉴를 열고, 기존 `onPressed` 도 한 번 부릅니다. | 트리거가 `Button` 처럼 키보드로 누르면 클릭 이벤트가 생기는 요소이면 엽니다. `Clickable` 로 만든 트리거는 키보드로 열리지 않습니다. `CoUIWeb` 아래에서는 열린 동안 트리거가 `inert` 가 되므로, 닫을 때는 `Escape` 를 누릅니다. |
| `Tab` · `Shift+Tab` | 패널 안의 행 사이를 돕니다. | 메뉴 전체가 `Tab` 한 칸입니다. `submenu` 마다 한 칸이 더 생깁니다. |
| `↓` · `↑` | 메뉴만의 처리는 없습니다. 웹이 아닌 Flutter 앱에서는 Flutter 의 기본 방향키 이동이 동작할 수 있습니다. | 다음 · 이전 행으로 옮기고, 끝에서 반대쪽으로 돕니다. |
| `Home` · `End` | 메뉴만의 처리는 없습니다. | 첫 · 마지막 행 |
| 글자 키 | 메뉴만의 처리는 없습니다. | 그 글자로 시작하는 라벨의 행으로 옮깁니다. 500ms 안에 이어 치면 이어서 찾습니다. |
| 행에서 `Enter` · `Space` | 고릅니다. | 고릅니다. |
| `Escape` | 닫습니다. | 닫습니다. |

Jaspr Web 의 행 이동은 패널 안의 [Menu](/components/menu) 가 맡습니다. 방향키는 포커스가 패널 안에 있을 때 동작합니다. 제목 · 구분선 · 빈 칸은 건너뛰고, 비활성 행에는 닿지만 골라지지 않습니다. `submenu` 안의 행은 위 목록의 방향키에서 빠지며 `Tab` 으로 들어갑니다.

### 스크린 리더

- 트리거의 이름은 `trigger` 위젯에서 옵니다. DropdownMenu 는 이름을 만들지 않으므로, 아이콘만 넣었다면 그 위젯에 이름을 붙입니다.
- 패널에는 접근성 이름이 없습니다. `Menu` 에는 `ariaLabel` 이 있지만 DropdownMenu 로는 줄 수 없습니다.
- 행의 이름은 `label` 에서 옵니다.
- 열려 있는 동안 두 플랫폼 모두 뒤 화면을 보조 기술에서 막습니다. Jaspr Web 은 뒤 화면을 `inert` 로 만듭니다.
- 바깥을 누를 수 없는 스크린 리더 사용자를 위한 닫기 수단이 있습니다. Flutter 는 패널 영역에 로케일의 "닫기" 이름을 가진 닫기 동작을 두어, 스크린 리더의 닫기 제스처를 쓰거나 그 영역을 활성화하면 닫힙니다. Jaspr Web 은 패널 곁에 화면에 보이지 않는 `role="button"` 요소(`aria-label` 은 "닫기" 문구)를 두고, 이 요소를 활성화하면 닫힙니다. 이 요소는 `tabindex="-1"` 이라 `Tab` 순서에 없고, 키보드는 `Escape` 를 씁니다.
- 터치 스크린 리더에는 `Escape` 가 없으므로, 행을 고르지 않고 메뉴를 닫을 때는 이 닫기 수단을 씁니다. 이 "닫기" 는 닫기 동작의 이름이고 메뉴의 이름은 아닙니다.
- 열리고 닫히는 것을 따로 알리는 라이브 리전은 없습니다. 열림 상태는 트리거에만 붙는데, 메뉴가 열려 있는 동안에는 트리거가 보조 기술에서 가려집니다(Jaspr Web 은 `CoUIWeb` 아래에서 그렇습니다).

### 포커스 관리

| 때 | Flutter | Jaspr Web |
| --- | --- | --- |
| 열 때 | 패널 영역이 포커스를 받습니다. 첫 행에 놓지는 않습니다. | 첫 행으로 옮기지 않습니다. 뒤 화면이 `inert` 가 되면서 트리거의 포커스가 풀릴 수 있습니다. |
| 열려 있는 동안 | `Tab` 이 패널 안에서 돕니다. | 뒤 화면에는 닿지 않지만, 패널 안에 가두지는 않습니다. 패널 밖으로 `Tab` 을 누르면 브라우저의 주소창 같은 곳으로 나갔다가 돌아올 수 있습니다. |
| 닫은 뒤 | DropdownMenu 가 따로 옮기지는 않습니다. 패널이 닫히면 Flutter 의 초점 기록에 따라 열기 전에 초점이 있던 곳(키보드로 연 경우 트리거)으로 돌아갈 수 있습니다. | 트리거로 되돌리는 처리가 없습니다. |

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | 키보드로 열려면 포커스 가능한 트리거를 사용합니다. 일반 위젯에 키보드 포커스를 자동으로 추가하지는 않습니다. 방향키 · `Home` · `End` · 글자 키로 행을 옮기는 메뉴만의 처리도 없습니다. |
| Flutter | CoUI 의 활성화 경로를 쓰지 않고 별도 semantics 경계를 가진 커스텀 트리거의 접근성 동작은 메뉴 열기와 연결되지 않습니다. [코드에서 열고 닫기](#코드에서-열고-닫기)처럼 해당 트리거의 콜백에 `controller.show` 를 연결합니다. |
| Flutter | 비활성인 `Button` 을 트리거로 써도 포인터로 누르면 메뉴가 열릴 수 있습니다. DropdownMenu 에는 비활성 속성이 없으므로, 열지 않아야 할 때는 DropdownMenu 없이 버튼만 그립니다. |
| Flutter | 열려 있는 동안 뒤 화면을 끌거나 휠로 굴리면 화면은 움직이고 패널은 제자리에 남을 수 있습니다. |
| Flutter | 뒤 화면의 다른 DropdownMenu · Popover 트리거처럼 포인터를 직접 읽는 요소는 누름에 반응해, 이 메뉴가 닫히면서 그쪽이 열릴 수 있습니다. 마우스를 올리면 뒤 화면에 hover 모양이 보일 수도 있습니다. |
| Jaspr Web | 트리거를 감싼 `<div>` 가 `role="button"` 이라, 안에 `Button` 을 넣으면 버튼 안의 버튼이 됩니다. `aria-expanded` 는 바깥에만 붙어 안쪽 버튼에는 열림 상태가 없습니다. |
| Jaspr Web | 닫아도 포커스를 트리거로 되돌리지 않습니다. |
| Jaspr Web | 비활성 행에 키보드 포커스가 가도 포커스 링과 덧씌움이 보이지 않을 수 있습니다. |
| Jaspr Web | 화면 높이에는 들어가지만 트리거 위와 아래 어느 쪽에도 다 들어가지 않는 메뉴는 일부가 화면 밖에 놓여, 그 행이 보이지 않을 수 있습니다. |
| Jaspr Web | 닫히는 동안(기본 100ms)에는 `controller` 의 `show()` · `toggle()` 로 다시 열리지 않을 수 있습니다. |
| Jaspr Web | 행의 `leading` · `trailing` 에 Tooltip 처럼 스스로 패널을 여는 컴포넌트를 두면, 그 패널이 열릴 때 메뉴가 닫힐 수 있습니다. |
| Jaspr Web | Dialog 안에서 메뉴를 연 채 `Escape` 를 누르면 Dialog 까지 닫힐 수 있습니다. |
| 공통 | `submenu` 안의 항목을 골라도 메뉴가 닫히지 않습니다. 닫으려면 그 항목의 `onPressed` 에서 `controller` 의 `close()` 를 부릅니다. |
| 공통 | `CoreMenuItem.action` 의 `href` 로는 이동하지 않습니다. Jaspr Web 은 행에 `data-href` 속성만 붙입니다. 이동은 `onPressed` 에서 합니다. |
| 공통 | 패널에 접근성 이름을 붙일 수 없습니다. |

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타겟)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

두 플랫폼은 `trigger` · `items` · `dropdownMenuStyle` · `controller` 를 같은 이름으로 받고, 패널 안은 같은 `Menu` 로 그립니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 패널이 그려지는 곳 | 앱의 루트 `Overlay` | `CoUIWeb`(`OverlayHost`)의 메뉴 층. 호스트가 없으면 트리거 옆에 그립니다. |
| 키보드로 열기 | 포커스 가능한 CoUI `Button` · `Clickable` 트리거에서 `Enter` · `Space` 로 엽니다. | 트리거가 `Button` 처럼 키보드로 누르면 클릭 이벤트가 생기는 요소이면 열립니다. |
| 메뉴 안 이동 | `Tab` 으로 행 사이를 옮깁니다. 웹이 아닌 앱에서는 Flutter 의 기본 방향키 이동이 동작할 수 있습니다. | 방향키 · `Home` · `End` · 글자 키. 메뉴 전체가 `Tab` 한 칸입니다. |
| 오른쪽 자리가 모자랄 때 | 패널의 오른쪽 끝을 트리거의 오른쪽 끝에 맞춥니다. | 화면 안에 들어올 만큼 왼쪽으로 밉니다. |
| 위아래 어느 쪽에도 다 들어가지 않을 때 | 화면 안으로 밀어 놓아 트리거를 덮을 수 있습니다. | 일부가 화면 밖으로 나갈 수 있습니다. |
| 열린 채 트리거가 움직일 때 | 패널은 제자리에 남습니다. | 스크롤이나 창 크기 변화에 맞춰 다시 놓습니다. |
| 긴 메뉴의 높이 | 화면 여백 · 시스템 바 · 화면 키보드를 뺀 높이까지 | 화면 위아래 여백 8을 뺀 높이까지 |
| 커지며 열리는 기준점 | 트리거 쪽 모서리 | 패널 가운데 |
| 열린 채 바뀐 값 | 새 `items` 목록을 넘기면 반영합니다. 같은 목록을 두고 `dropdownMenuStyle` 만 바꾸면 다음에 열 때 반영될 수 있습니다. 빈 목록을 넘겨도 닫지 않습니다. `menuOffset` 은 다음에 열 때 반영됩니다. | 다시 그릴 때 반영합니다. `menuOffset` 은 다음에 열 때 반영됩니다. 빈 목록을 넘기면 닫습니다. |
| 비활성 행 | `disabledContent` 색. 키보드 포커스가 가면 포커스 링이 보입니다. | 같은 색에 불투명도 50%가 더해져 더 흐립니다. 키보드 포커스 표시가 보이지 않을 수 있습니다. |
| 선택된 비활성 행 | `primary` 채움 없이 그립니다. | `primary` 채움을 남깁니다. |
| liquidGlass 의 패널 모양 | 모서리 24 · 안쪽 여백 8 · 행 모서리 16 | 문서의 스타일만 바꾸면 기본 모양(모서리 12 · 안쪽 여백 6 · 행 모서리 8)으로 남을 수 있습니다. |
| 행의 hover · 눌림 색 전환 | 일반 행은 바로 바뀌고, `critical` 강조 채움은 150ms 동안 바뀝니다. | `enableThemeAnimation`(기본값 `true`)이 켜져 있으면 150ms 동안 바뀝니다. |
| 스크린 리더의 닫기 | 패널의 닫기 동작 | 패널 곁의 숨긴 `role="button"` 요소 (`Tab` 순서 밖) |
| 위젯 타입 `W` | `Widget` | `Component` |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `onClick` 등. 패널이 아니라 트리거를 감싼 바깥 요소에 붙습니다. |

<a id="props-parameters"></a>

## API

Flutter 와 Jaspr Web 이 같은 속성을 씁니다. `W` 는 Flutter 의 `Widget`, Jaspr Web 의 `Component` 입니다.

### 위젯

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `trigger` | `W` | 필수 | 누르면 메뉴를 열고 닫는 요소 |
| `items` | `List<CoreMenuItem<W>>` | 필수 | 패널의 항목 |
| `dropdownMenuStyle` | `CoreDropdownMenuStyle?` | `null` | 겉모습과 간격 덮어쓰기. `withStyle` 로도 덧붙일 수 있습니다. |
| `controller` | `PopoverController?` | `null` | 코드에서 열고 닫을 때 넘깁니다. 없으면 DropdownMenu 가 스스로 만듭니다. |

<a id="coremenuitem-드롭다운에서-쓰는-종류"></a>

### CoreMenuItem 생성자

`label` 과 `size` 는 이름 없이 첫 자리에 넘깁니다.

| 생성자 | 파라미터 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- | --- |
| `.label` | `label` | `String` | 필수 | 제목 글자 |
| `.label` | `leading` · `trailing` | `W?` | `null` | 제목 앞뒤의 위젯 |
| `.action` | `label` | `String` | 필수 | 행의 글자. Jaspr Web 의 글자 키 이동도 이 값을 씁니다. |
| `.action` | `onPressed` | `void Function()?` | `null` | 비활성이 아닌 행을 고르면 부릅니다. |
| `.action` | `disabled` | `bool` | `false` | 흐리게 그리고 고를 수 없게 합니다. |
| `.action` | `shortcut` | `String?` | `null` | 단축키 힌트 글자 |
| `.action` | `description` | `String?` | `null` | 라벨 아래 둘째 줄 |
| `.action` | `tone` | `CoreMenuItemTone` | `neutral` | `neutral` 또는 `critical` |
| `.action` | `leading` · `trailing` | `W?` | `null` | 행 앞뒤의 위젯 |
| `.action` | `standardAction` | `CoreMenuAction?` | `null` | `leading` 이 없을 때 그릴 정해진 아이콘 |
| `.action` | `active` | `bool` | `false` | 선택된 모양으로 그립니다. |
| `.action` | `submenu` | `List<CoreMenuItem<W>>?` | `null` | 아래에 펼칠 하위 항목 |
| `.action` | `href` | `String?` | `null` | 지금은 이동에 쓰이지 않습니다. |
| `.checkbox` | `label` | `String` | 필수 | 행의 글자 |
| `.checkbox` | `checked` | `bool` | `false` | 켜짐 상태 |
| `.checkbox` | `onChanged` | `void Function(bool)?` | `null` | 고르면 `checked` 의 반대 값을 받습니다. |
| `.checkbox` | `description` · `tone` · `trailing` · `disabled` | action 과 같음 | action 과 같음 | action 과 같습니다. |
| `.radio` | `label` | `String` | 필수 | 행의 글자 |
| `.radio` | `selected` | `bool` | `false` | 고름 상태 |
| `.radio` | `onChanged` | `void Function(bool)?` | `null` | 고르면 `true` 를 받습니다. |
| `.radio` | `radioMark` | `CoreMenuRadioMark` | `dot` | 고른 행의 표시. `dot` 또는 `check` |
| `.radio` | `shortcut` · `description` · `tone` · `trailing` · `disabled` | action 과 같음 | action 과 같음 | action 과 같습니다. |
| `.divider` | — | — | — | 구분선. 받는 값이 없습니다. |
| `.gap` | `size` | `double` | 필수 | 빈 칸의 크기 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreDropdownMenuStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `menuStyle` | `CoreMenuStyle?` | Style of the `Menu` inside — the whole menu's look: the panel box via [CoreMenuStyle.popupStyle], each `MenuItem` row via [CoreMenuStyle.itemStyle], the divider, the heading typography and so on. Passed to the inner `Menu`'s `menuStyle` as is, where it is laid over `CoreMenuTheme.style`; `null` leaves the inner `Menu` at its design-system defaults. |
| `menuOffset` | `double?` | Per-instance gap between the trigger and the menu panel along the placement axis — `null` falls back to [defaultMenuOffset]. A single placement-axis scalar (not a multi-side inset), so it stays a flat `double` field (mirrors `CoreMenubarStyle.menuOffset`). |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="Menu" href="/components/menu" more="Menu 보기">

화면에 놓는 메뉴 패널입니다. DropdownMenu 의 패널이 바로 이 컴포넌트입니다.

</Card>
<Card title="ContextMenu" href="/components/context-menu" more="ContextMenu 보기">

트리거 버튼 대신 우클릭한 자리에서 여는 메뉴입니다.

</Card>
<Card title="Popup" href="/components/popup" more="Popup 보기">

메뉴 패널의 상자입니다. 위치와 열림 상태를 직접 다루는 패널에 씁니다.

</Card>
</Cards>
