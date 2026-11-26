---
title: Popup
description: 메뉴 · 드롭다운 · 팝오버처럼 화면 위에 뜨는 콘텐츠를 담는 패널 상자입니다. 겉모습만 그리고, 위치와 열고 닫기는 이것을 띄우는 쪽이 맡습니다.
category: overlay
platforms: [flutter, web]
related: [popover, dropdown-menu, menu, tooltip]
tags: [popup, floating, panel, surface]
template: v2
source: infra/popup
---

# Popup

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

안쪽 여백과 방향을 바꿔 보며 패널을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="popup" />

`Popup`은 배경 · 테두리 · 둥근 모서리 · 그림자를 가진 상자 안에 `children`을 한 방향으로 놓습니다. 다른 층에 띄우지 않고 놓은 자리에 그대로 그리므로, 위 무대의 패널은 실제 `Popup`입니다.

- 위치 계산, 바깥 클릭이나 `Escape`로 닫기, 열고 닫는 애니메이션은 없습니다. 트리거에 붙여 띄우려면 [Popover](/components/popover)를 씁니다.
- 보일지는 `open` 하나가 정합니다. 기본값은 `true`입니다.

## 구조

<Anatomy demo="popup/anatomy">
<AnatomyItem part="container" name="Container">

패널. 배경은 `surfaceBright`, 테두리는 1px `outlineVariant`, 모서리는 12(패널 역할), 그림자는 `lg` 단계입니다. 안에 담는 글의 색은 `onSurface`이고, 최소 폭은 128입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=item]" side="left" name="children">

`children`에 넣은 항목. `direction`을 따라 간격 없이(`spacing` 0) 놓입니다. 이 그림의 항목은 `Menu`가 자기 행에 주는 모서리를 쓴 `MenuItem`이고, 안쪽 여백은 목록 값 6입니다.

</AnatomyItem>
</Anatomy>

- 패널은 둥근 모서리 밖으로 나가는 내용을 잘라 냅니다.
- 다크 모드의 기본 팔레트에서는 `surfaceBright`와 `surfaceContainer`가 같은 색입니다. `surfaceContainer` 바탕 위의 패널은 테두리와 그림자로 구분됩니다.

<a id="안쪽-여백-프리셋"></a>

## 안쪽 여백

<Preview demo="popup/padding" />

패널의 안쪽 여백은 `popupStyle`의 `padding` 필드 하나입니다. 담는 내용에 따라 고를 값 두 가지가 Core에 이름 붙은 상수로 있습니다.

| 상수 | 값 | 맞는 내용 |
| --- | --- | --- |
| `CorePopupStyle.defaultContentPadding` | 16 | 폼 · 카드 · 달력처럼 모양이 정해지지 않은 내용. 기본값(`CorePopupStyle.defaultPadding`)도 16입니다. |
| `CorePopupStyle.defaultListPadding` | 6 | 메뉴 · 선택 목록처럼 행을 담는 패널 |

- `Popup`은 자기가 목록을 담는지 알 수 없어 기본값이 16입니다. `Menu` · `Select` · `Autocomplete`처럼 목록을 담는 컴포넌트는 목록 값을 직접 넘깁니다.
- 안쪽 여백은 테두리를 포함한 패널 바깥 가장자리에서 잽니다. 두 플랫폼 모두 내용이 가장자리에서 그 값만큼 들어옵니다.
- 행의 모서리는 행을 담는 컴포넌트가 정합니다. `Select`의 옵션은 6입니다. 패널 모서리 12에서 여백 6을 뺀 값이라 두 모서리의 중심이 같습니다. `Menu`의 행은 8입니다.
- 밀도를 바꾸면(`CoUIApp(density:)` · `CoUIWeb(density:)`) 값이 함께 움직입니다.

| 값 | compact | standard | spacious |
| --- | --- | --- | --- |
| 내용 여백 | 12 | 16 | 20 |
| 목록 여백 | 4 | 6 | 8 |
| 모서리 | 10 | 12 | 14 |

최소 폭 128은 밀도에 따라 움직이지 않습니다.

<Split>

<Code language="dart" title="목록을 담는 패널">
Popup(
  popupStyle: CorePopupStyle(
    padding: CorePopupStyle.defaultListPadding,
  ),
  children: [
    MenuItem(
      label: Text('프로필'),
      menuItemStyle: CoreMenuStyle.defaultItemStyle,
      onPressed: openProfile,
    ),
  ],
)
</Code>

<Code language="dart" title="내용을 담는 패널">
Popup(
  children: [
    Text('알림을 받을까요?').titleSmall,
    const Gap.space4(),
    Text('새 댓글이 달리면 알려 드려요.').bodySmall.onSurfaceVariant,
  ],
)
</Code>

</Split>

## 방향

<Preview demo="popup/direction" />

`direction`은 자식을 놓는 방향을 `CoreAxis` 값으로 정합니다. 자식 사이의 간격은 `popupStyle`의 `spacing`이 정하며 기본값은 0입니다.

| 값 | 놓는 방식 |
| --- | --- |
| `CoreAxis.vertical` (기본) | 위에서 아래로 놓습니다. 자식은 패널 안쪽 폭만큼 늘어납니다. |
| `CoreAxis.horizontal` | 한 줄로 글 방향을 따라 놓습니다. 높이가 다른 자식의 세로 자리는 플랫폼마다 다릅니다([플랫폼 차이](#플랫폼-차이)). |

<Note>

`MenuItem`은 `horizontal` 패널에 바로 넣지 않습니다. Flutter에서는 행이 가로 폭을 정할 수 없어 레이아웃 오류가 납니다. 가로 메뉴는 `Menu(vertical: false)`로 만듭니다.

</Note>

<a id="동작-스펙-behavior"></a>

## 상태

| `open` | 화면 |
| --- | --- |
| `true` (기본) | 패널을 그립니다. |
| `false` | 아무것도 그리지 않습니다. Flutter는 크기가 0인 빈 상자를 두고, 웹은 요소를 남기지 않습니다. |

- `Popup`은 `open`을 스스로 바꾸지 않습니다. 닫기를 알리는 콜백도 없습니다.
- `open`을 바꿀 때 애니메이션은 없습니다.
- `popupStyle`의 `openAnimationDuration` · `closeAnimationDuration`은 `Popup` 혼자서는 쓰지 않습니다. 패널을 띄우는 `DropdownMenu` · `ContextMenu` · `Menubar` · `NavigationMenu`와 `RichEditor`의 선택 툴바가 읽습니다. `Popover`는 `popoverStyle`의 같은 이름 필드를 씁니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

위치와 열고 닫기를 이미 맡은 곳에서 패널 상자만 필요할 때 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 트리거에 붙여 띄우고 바깥을 누르면 닫혀야 할 때 | [Popover](/components/popover) |
| 버튼을 눌러 여는 액션 목록 | [DropdownMenu](/components/dropdown-menu) |
| 제자리에 놓는 메뉴 목록(항목 · 구분선 · 선택 표시) | [Menu](/components/menu) |
| 화면 흐름 안에 놓는 내용 카드 | [Card](/components/card) |
| 요소를 가리키면 뜨는 짧은 도움말 | [Tooltip](/components/tooltip) |
| 응답을 받아야 하는 모달 | [Dialog](/components/dialog) |

<a id="do"></a>

### 안쪽 여백과 겹치는 패널

<Cards columns="2">
<Card demo="popup/do-list-padding" tone="do" eyebrow="이렇게 하세요">

목록을 담는 패널에는 `CorePopupStyle.defaultListPadding`(6)을 줍니다. 행이 패널 가장자리를 따라 놓입니다.

</Card>
<Card demo="popup/dont-list-padding" tone="dont" eyebrow="이렇게 하지 마세요">

행 목록에 기본값 16을 그대로 두면 행의 안쪽 여백에 패널 여백이 더해져 목록이 헐겁게 보입니다.

</Card>
<Card demo="popup/do-menu" tone="do" eyebrow="이렇게 하세요" height="240">

메뉴 목록은 `Menu` 하나로 그립니다. `Menu`는 자기 패널을 함께 그립니다.

</Card>
<Card demo="popup/dont-double-panel" tone="dont" eyebrow="이렇게 하지 마세요" height="240">

`Menu`를 `Popup`으로 한 번 더 감싸면 테두리 · 배경 · 그림자가 두 겹이 됩니다. `Popover`도 패널(`Popup`)을 스스로 그리므로 `content`에 `Popup`을 다시 넣지 않습니다.

</Card>
</Cards>

<a id="dont"></a>

### 크기를 잴 수 있는 자식

Flutter의 `Popup`은 폭을 내용에 맞추려고 자식의 폭을 미리 잽니다. `LayoutBuilder`나 `ListView` · `CustomScrollView`처럼 폭을 미리 잴 수 없는 위젯을 그대로 넣으면 디버그 빌드에서 레이아웃 오류가 납니다. 크기를 정한 `SizedBox`로 감쌉니다.

<Split>

<Code language="dart" title="이렇게 하세요">
Popup(
  children: [
    SizedBox(
      width: 240,
      height: 200,
      child: ListView(children: rows),
    ),
  ],
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 폭을 잴 수 없어 Flutter 디버그 빌드에서 오류가 납니다.
Popup(
  children: [
    ListView(children: rows),
  ],
)
</Code>

</Split>

`Popup`은 내용을 스스로 스크롤하지 않습니다. 긴 목록은 위처럼 크기를 정한 스크롤 영역에 담거나 `Menu`를 씁니다. Flutter의 세로 `Menu`는 자리가 모자라면 행을 스크롤합니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

겉모습은 `popupStyle`(`CorePopupStyle`) 하나로 바꿉니다. 두 플랫폼이 같은 코드를 씁니다.

<Split>

<Code language="dart" title="패널 하나만 바꾸기">
Popup(
  popupStyle: CorePopupStyle(
    backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
  ),
  children: [Text('항목')],
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    popup: CorePopupTheme(
      style: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      ),
    ),
  ),
)
</Code>

</Split>

<Note>

`CorePopupStyle`에는 안쪽 여백 · 모서리 · 테두리 · 색 · 그림자 · 폭 · 간격 · 재질 · 여닫는 시간의 필드가 있습니다. 전체 목록은 API에서 확인하세요.

</Note>

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CorePopupStyle 기본값        // 디자인 시스템
  → CorePopupTheme.style      // 앱 전체
  → popupStyle                // 패널 하나
```

뒤로 갈수록 우선하고, 필드마다 따로 합쳐집니다.

### Popup 위에 만든 컴포넌트

메뉴나 팝오버 같은 컴포넌트는 `Popup`과 같은 패널을 그리면서, 다르게 할 필드만 `popupStyle` 자리에 넘깁니다. 그래서 리퀴드 글라스 스타일의 `Menu`(아래)를 빼면 `CorePopupTheme`의 값은 그 컴포넌트가 직접 정하지 않은 필드에만 닿습니다. 예를 들어 앱 테마에서 모서리를 바꾸면 모서리를 따로 정하지 않는 `Menu`는 따라오고, 12를 직접 정하는 `Select`는 그대로입니다. 자주 쓰는 컴포넌트가 리퀴드 글라스가 아닌 스타일에서 직접 정하는 값은 다음과 같습니다.

| 컴포넌트 | 직접 정하는 값 |
| --- | --- |
| 세로 `Menu` (`DropdownMenu` · `ContextMenu` 포함) | 안쪽 여백 6, 폭 240~280, 항목 사이 2 |
| `Menubar`의 드롭다운 | 테두리 없음, 안쪽 여백 6, 폭 160~280, 항목 사이 2 |
| `Popover` | 안쪽 여백 16, 최소 폭 0 |
| `Select` | 안쪽 여백 6, 모서리 12, 항목 사이 2, 최소 폭 0(패널 폭은 기본으로 트리거 폭) |
| `NavigationMenu`의 패널 | 안쪽 여백 16, 모서리 12, 테두리 두께 · 색, 배경, 그림자, 최소 폭 256 |
| `HoverCard` | 최소 폭 0, 최대 폭 256 |

그 밖에 `ColorPicker`의 인라인 패널(모서리 14, 그림자 없음), `ToolbarGroup`(알약 모양, 안쪽 여백 4), `Fab`의 동작 메뉴, `RichEditor`의 선택 툴바도 자기 값을 씁니다.

리퀴드 글라스 스타일에서는 두 가지가 다릅니다.

- 세로 `Menu`(`DropdownMenu` · `ContextMenu` 포함)는 안쪽 여백 8 · 모서리 24를 씁니다. 이때는 앱의 `CorePopupTheme` 값이 `Menu`가 직접 정하는 값(위 표의 폭 · 항목 사이 간격 포함)보다 우선합니다. `Menubar`의 드롭다운도 모서리가 24가 되고, `Menubar`가 정하는 테두리 없음 · 안쪽 여백 6 · 최소 폭 160은 그대로입니다.
- `ToolbarGroup`은 안쪽 여백과 테두리가 0이 됩니다.

### 서페이스 스타일

서페이스 스타일을 켜면 `Popup`은 화면 위에 뜨는 표면의 재질(반투명 배경 · 뒤 흐림 · 가장자리 빛처럼 그 스타일이 정한 것)을 받습니다. 패널 하나만 다른 재질로 그리려면 `popupStyle`의 `surfaceStyle`을 줍니다. 배경이 투명한 패널은 두 플랫폼이 다르게 그립니다([플랫폼 차이](#플랫폼-차이)).

### 빠른 오버라이드 (Chain)

이미 만든 `Popup`에 `withStyle`을 이어 스타일을 덧붙입니다. 생성자의 `popupStyle`에 주는 것과 같고, 겹치는 필드는 뒤에 붙인 값이 이깁니다. `.radius16`처럼 Core 토큰 상수와 이름이 같은 getter도 있습니다. 모서리 getter는 `borderRadius`만, 색 getter는 `backgroundColor`만 바꿉니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class PopupChainExample extends StatelessWidget {
  const PopupChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Popup(
          children: [
            Padding(
              padding: const CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space8,
                vertical: CoreSpace.space4,
              ).toValue(geometry: Theme.of(context).geometry),
              child: Text('프로필').bodyMedium,
            ),
            Padding(
              padding: const CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space8,
                vertical: CoreSpace.space4,
              ).toValue(geometry: Theme.of(context).geometry),
              child: Text('설정').bodyMedium,
            ),
            Padding(
              padding: const CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space8,
                vertical: CoreSpace.space4,
              ).toValue(geometry: Theme.of(context).geometry),
              child: Text('로그아웃').bodyMedium,
            ),
          ],
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Popup(
          children: [
            Padding(
              padding: const CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space8,
                vertical: CoreSpace.space4,
              ).toValue(geometry: Theme.of(context).geometry),
              child: Text('프로필').bodyMedium,
            ),
            Padding(
              padding: const CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space8,
                vertical: CoreSpace.space4,
              ).toValue(geometry: Theme.of(context).geometry),
              child: Text('설정').bodyMedium,
            ),
            Padding(
              padding: const CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space8,
                vertical: CoreSpace.space4,
              ).toValue(geometry: Theme.of(context).geometry),
              child: Text('로그아웃').bodyMedium,
            ),
          ],
        ).withStyle(
          const CorePopupStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
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
class PopupChainExample extends StatelessComponent {
  const PopupChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Popup(
          children: [
            div(
              [Text('프로필').bodyMedium],
              classes: 'px-${CoreSpace.scale.space8} py-${CoreSpace.scale.space4}',
            ),
            div(
              [Text('설정').bodyMedium],
              classes: 'px-${CoreSpace.scale.space8} py-${CoreSpace.scale.space4}',
            ),
            div(
              [Text('로그아웃').bodyMedium],
              classes: 'px-${CoreSpace.scale.space8} py-${CoreSpace.scale.space4}',
            ),
          ],
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Popup(
          children: [
            div(
              [Text('프로필').bodyMedium],
              classes: 'px-${CoreSpace.scale.space8} py-${CoreSpace.scale.space4}',
            ),
            div(
              [Text('설정').bodyMedium],
              classes: 'px-${CoreSpace.scale.space8} py-${CoreSpace.scale.space4}',
            ),
            div(
              [Text('로그아웃').bodyMedium],
              classes: 'px-${CoreSpace.scale.space8} py-${CoreSpace.scale.space4}',
            ),
          ],
        ).withStyle(
          const CorePopupStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
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

<Note>

색 getter는 배경만 바꾸고 글자색(`contentColor`, 기본 `onSurface`)은 그대로 둡니다. CoUI 기본 팔레트의 `primary`와 `tertiary`는 `onSurface`와 명암이 거의 같아, 위 예제의 두 패널은 글자를 읽기 어렵습니다. 진한 배경에는 `contentColor`도 짝이 되는 색(`primary`라면 `onPrimary`)으로 함께 바꾸세요.

</Note>

<a id="접근성-accessibility"></a>

## 접근성

`Popup`은 패널의 겉모습을 그립니다. 웹에서는 루트에 메뉴 역할을 붙이고, 키보드와 포커스는 다루지 않습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 없습니다. 패널을 `Semantics(container: true)` 노드 하나로 묶습니다. |
| Jaspr Web | 루트에 `role="menu"`를 붙입니다. `attributes`에 `role`을 주면 그 값을 씁니다. |

웹에서 `Popup` 위젯으로 패널을 그리는 킷 컴포넌트 가운데 `RichEditor`의 선택 툴바는 역할을 `toolbar`로, `ToolbarGroup`은 `group`으로, `ContextMenu`의 미리보기는 `presentation`으로 바꿉니다. `Fab`의 동작 메뉴와 `ColorPicker`의 인라인 패널은 `menu` 그대로입니다. `Menu`나 `Popover`처럼 패널의 겉모습만 자기 요소에 그리는 컴포넌트는 역할을 각자 정합니다.

### 키보드

`Popup`은 처리하는 키가 없습니다. 안에 넣은 컨트롤의 키가 그대로 동작하고, `Tab`은 안에 놓인 컨트롤 사이를 옮깁니다.

### 스크린 리더

- `Popup`은 이름을 붙이지 않습니다. 이름이 필요하면 웹은 `attributes`의 `aria-label`로 주고, Flutter는 `Semantics(container: true, label: ...)`로 감쌉니다.
- 패널이 나타나거나 사라진 것을 따로 알리지 않습니다. live region이 없습니다.
- 패널이 열렸는지를 알리는 일은 띄우는 컴포넌트가 맡습니다. 예를 들어 `Popover`와 `DropdownMenu`는 트리거에 펼침 상태를 알립니다.
- 웹의 접근성 트리에는 기본으로 메뉴 역할의 요소로 들어가고, 안에 넣은 내용이 그 아래에 놓입니다.

### 포커스 관리

`Popup`은 포커스를 옮기지도, 안에 가두지도, 돌려주지도 않습니다. `open`을 바꿔도 같습니다. 열 때 포커스를 어디로 옮기고 닫을 때 어디로 돌려줄지는 패널을 띄우는 컴포넌트가 정합니다. 각 컴포넌트의 문서를 확인하세요.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | 메뉴가 아닌 내용을 담아도 `role="menu"`가 붙습니다. 메뉴 역할은 방향 키로 옮겨 다니는 동작을 기대하게 하는데 `Popup`은 키를 처리하지 않습니다. 메뉴가 아니면 `attributes: {'role': 'group'}`처럼 바꾸세요. |
| Jaspr Web | `ColorPicker`의 인라인 패널은 이 역할을 바꾸지 않아, 스크린 리더가 메뉴로 알릴 수 있습니다. |
| Flutter | 패널의 역할을 알리지 않습니다. |
| 공통 | 패널은 둥근 모서리 밖을 잘라 냅니다. 포커스 링은 컨트롤 바깥 4까지 그리므로, 1px 테두리를 그리는 패널에서는 안쪽 여백이 웹은 5(테두리 1 + 링 4), Flutter는 4보다 작으면 가장자리에 붙은 컨트롤의 링이 잘릴 수 있습니다. 밀도 `compact`의 목록 여백 4는 웹에서 링이 1만큼 잘릴 수 있습니다. |

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타깃)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

위젯 파라미터의 이름과 기본값은 같고, 웹의 자식 타입은 `Component`입니다. 그리는 결과는 아래 자리에서 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `maxWidth`를 비운 패널의 폭 | 내용 폭입니다(최소 128). | 블록 부모나 자식을 늘이는 세로 flex 안에서는 부모 폭을 채웁니다. 가로 flex 안이나 `items-start` 부모 안에서는 내용 폭입니다. 어디서나 내용 폭으로 두려면 `maxWidth`를 정하거나 `classes: 'w-fit'`을 줍니다. |
| 부모가 폭을 강제할 때 (`stretch` 정렬 등) | 그 폭이 됩니다. `minWidth` · `maxWidth`보다 부모가 우선합니다. | `maxWidth`를 정한 패널은 늘어나지 않고 내용 폭을 범위 안에서 씁니다. |
| `horizontal`의 세로 정렬 | 자식을 세로 가운데에 둡니다. | 자식을 가장 높은 자식의 높이만큼 늘입니다. 높이를 정하지 않은 글은 위에 붙습니다. |
| `contentColor` | 글자에만 닿습니다. 아이콘은 주변 `IconTheme`의 색을 씁니다. | 색을 따로 주지 않은 아이콘도 글자색을 따라갑니다. |
| 배경이 투명한 패널과 서페이스 스타일 | 뒤 흐림 · 채도 · 유리의 가장자리 빛 · 굴절을 그리지 않습니다. 그림자와 클레이모피즘의 안쪽 빛은 남으므로, 없애려면 `boxShadow: []`도 함께 줍니다. 유리가 아닌 스타일에서는 남은 그림자가 투명한 패널 안으로도 비칠 수 있습니다. 리퀴드 글라스처럼 가장자리를 재질이 그리는 스타일에서는 테두리 색도 투명해져 테두리가 보이지 않을 수 있습니다. | 표면 클래스가 남아 있어, 뒤를 흐리는 스타일에서는 투명한 패널 뒤가 흐려질 수 있습니다. |
| 앱의 크기 배율 | 안쪽 여백 · 테두리 · 최소 · 최대 폭 · 자식 간격에 곱합니다. 모서리에는 곱하지 않습니다. | 배율을 곱하는 단계가 없습니다. 길이는 `rem`과 CSS 변수로 그립니다. |
| 역할 | 없음 (`Semantics(container: true)`) | `role="menu"` (`attributes`로 바꿈) |
| 웹 전용 파라미터 | — | `id` · `classes` · `css` · `attributes` · `eventHandlers` (패널 루트에 붙음) |
| 렌더링 | `DecoratedBox` + `ClipRRect` | `<div>` + Tailwind 클래스와 인라인 CSS, `overflow: hidden` |

<a id="props-parameters"></a>

## API

### 위젯 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `children` | `List<Widget>` | 필수 | 패널 안에 `direction`을 따라 놓는 내용. 웹은 `List<Component>` |
| `open` | `bool` | `true` | `false`면 아무것도 그리지 않습니다. |
| `direction` | `CoreAxis` | `CoreAxis.vertical` | 자식을 놓는 방향 |
| `popupStyle` | `CorePopupStyle?` | `null` | 이 패널의 겉모습을 바꾸는 값 |

웹의 생성자는 `id` · `classes` · `css` · `attributes` · `eventHandlers`도 받아 패널 루트에 붙입니다. `classes`와 `css`는 레이아웃에 쓰고, 겉모습은 `popupStyle`로 바꿉니다.

### 그 밖의 멤버

- `withStyle(CorePopupStyle patch)`는 `popupStyle`에 `patch`를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch`가 이깁니다.
- `copyWith(...)`는 바꾼 값으로 사본을 만듭니다.
- 모서리 getter: `radius0` · `radius2` · `radius4` · `radius6` · `radius8` · `radius10` · `radius12` · `radius14` · `radius16` · `radius20` · `radius24` · `radius28` · `radius32` · `radius36` · `radius40` · `radius48` · `radius56` · `radius64` · `radius9999`
- 배경색 getter: `primary` · `secondary` · `tertiary` · `surface` · `surfaceContainer` · `error` · `success` · `warning` · `info` · `outline` · `transparent`

### 테마 — `CorePopupTheme`

`CoreComponentTheme(popup: ...)`으로 앱에 둡니다. `Popup`에는 variant가 없어 variant별 값은 없습니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CorePopupStyle?` | `null` | 모든 `Popup`에, 그리고 `Popup` 위에 만든 컴포넌트가 직접 정하지 않은 필드에 깔리는 값. 리퀴드 글라스의 `Menu`는 예외입니다([Popup 위에 만든 컴포넌트](#popup-위에-만든-컴포넌트)). |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CorePopupStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `surfaceStyle` | `CoreSurfaceStyleId?` | Material override for this surface; `null` inherits the surrounding material. |
| `padding` | `CoreEdgeInsets?` | Internal padding of the popup panel. |
| `borderRadius` | `CoreBorderRadius?` | Corner radius of the popup panel. |
| `borderWidth` | `double?` | Border width of the popup panel (logical px). |
| `backgroundColor` | `CoreColor?` | Background colour of the popup panel. |
| `borderColor` | `CoreColor?` | Border colour of the popup panel. |
| `boxShadow` | `List<CoreShadowLayer>?` | Elevation shadow of the popup panel. |
| `shadowBaseColor` | `CoreColor?` | Base colour the [boxShadow] layers tint against. |
| `minWidth` | `double?` | Minimum width of the popup panel (logical px). |
| `maxWidth` | `double?` | Maximum panel width (logical px). `null` → [defaultMaxWidth] (unbounded). Content-driven between [minWidth] and this. |
| `spacing` | `double?` | Uniform spacing (logical px) between adjacent children laid out along the panel's axis. Flows into `Column` / `Row.spacing` (Flutter) and the flex `gap` (Web). `null` → [defaultSpacing] (0, flush). |
| `contentColor` | `CoreColor?` | Text colour the panel content inherits. The panel wraps its content in a `DefaultTextStyle` with this colour, keeping the surrounding typography role and changing only the colour. |
| `openAnimationDuration` | `Duration?` | Open (enter) animation duration of the popup panel. `null` → [defaultOpenAnimationDuration]. |
| `closeAnimationDuration` | `Duration?` | Close (exit) animation duration of the popup panel. `null` → [defaultCloseAnimationDuration]. |

<!-- STYLE_TABLE:END -->

<Note>

표의 설명과 함께 알아 둘 동작입니다.

- `openAnimationDuration`과 `closeAnimationDuration`은 `Popup` 혼자서는 쓰지 않습니다. 읽는 컴포넌트는 상태에 있습니다.
- `maxWidth`를 비우면 상한이 없습니다. 이때 웹 패널은 블록 부모의 폭을 채울 수 있습니다([플랫폼 차이](#플랫폼-차이)).
- `contentColor`는 Flutter에서는 글자에만, 웹에서는 색을 따로 주지 않은 아이콘에도 닿습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="Popover" href="/components/popover" more="Popover 보기">

트리거에 붙는 위치 계산과 닫기를 갖춘 패널입니다.

</Card>
<Card title="DropdownMenu" href="/components/dropdown-menu" more="DropdownMenu 보기">

버튼을 눌러 여는 액션 목록입니다.

</Card>
<Card title="Menu" href="/components/menu" more="Menu 보기">

항목 · 구분선 · 선택 표시를 갖춘 메뉴 목록입니다.

</Card>
</Cards>
