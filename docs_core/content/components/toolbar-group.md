---
title: ToolbarGroup
description: 관련 툴바 동작이 하나의 재질 표면을 공유하는 그룹
category: menu
platforms: [flutter, web]
related: [button, menubar, dropdown-menu]
tags: [toolbar, glass, actions]
template: v2
source: layout/toolbar_group
---

# ToolbarGroup

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

방향과 재질을 바꿔 보며 그룹을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="toolbar-group" />

`ToolbarGroup`은 서로 관련된 컨트롤을 알약 모양 패널(`Popup`) 하나에 묶고, 그 묶음에 `ariaLabel`로 이름을 붙입니다.

- 그룹은 명령을 실행하거나 선택 상태를 만들지 않습니다. 누름 콜백 · 비활성 상태 · 포커스는 안에 넣은 컨트롤이 각자 맡습니다.
- 아이콘만 넣은 버튼에는 버튼마다 이름을 줍니다. Flutter는 `Semantics(label:)`로, 웹은 `Button(attributes: {'aria-label': ...})`로 주기 때문에 두 플랫폼의 코드가 다릅니다.
- 웹의 그룹은 블록 부모 안에서 부모 폭을 채웁니다. 내용 폭으로 두려면 가로 flex 부모나 `items-center` · `items-start` 부모 안에 둡니다([플랫폼 차이](#플랫폼-차이)).

<Note>

그룹은 놓은 자리에 그대로 그려지므로 무대의 그룹은 실제 `ToolbarGroup`입니다. `Liquid Glass`를 켜면 `popupStyle`의 `surfaceStyle`로 이 그룹만 리퀴드 글라스로 그립니다. 무대 바탕이 한 색이라 유리 뒤에서 흐려질 내용이 없어, 유리가 옅게 보일 수 있습니다.

</Note>

## 구조

<Anatomy demo="toolbar-group/anatomy">
<AnatomyItem part="container" name="Container">

그룹의 패널이며 `Popup`으로 그립니다. 리퀴드 글라스가 아닐 때의 기본값은 모서리 9999(알약), 안쪽 여백 4, 1px `outlineVariant` 테두리, `surfaceBright` 배경, `lg` 단계 그림자입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=control]" side="top" name="children">

`children`에 넣은 컨트롤입니다. `direction`을 따라 간격 없이(`spacing` 0) 놓입니다. 그림의 컨트롤은 `ghost` · `square` 버튼입니다.

</AnatomyItem>
</Anatomy>

- `ariaLabel`은 화면에 보이지 않습니다.
- 패널은 둥근 모서리 밖으로 나가는 내용을 잘라 냅니다. 포커스 링에 미치는 영향은 [알려진 제약](#알려진-제약)을 보세요.

<a id="세로-그룹-vertical"></a>

## 방향

<Preview demo="toolbar-group/direction" height="240" />

`direction`은 컨트롤을 놓는 방향을 `CoreAxis` 값으로 정합니다.

| 값 | 놓는 방식 | 어울리는 곳 |
| --- | --- | --- |
| `CoreAxis.horizontal` (기본) | 글 방향을 따라 한 줄로 | 바의 동작 묶음, 본문 위의 도구 줄 |
| `CoreAxis.vertical` | 위에서 아래로 | 바의 줄이 아니라 콘텐츠 옆. 화면 한쪽의 세로 컨트롤 자리, 지도 · 캔버스의 도구 모음 |

세로로 세운 자리에서는 글자를 눕히지 않으므로 아이콘 버튼을 넣고, 버튼마다 이름을 줍니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
ToolbarGroup(
  ariaLabel: '페이지 동작',
  direction: CoreAxis.vertical,
  children: [
    Semantics(
      label: '뒤로',
      child: Button(
        variant: CoreButtonVariant.ghost,
        shape: CoreButtonShape.square,
        onPressed: goBack,
        child: Icon(LucideIcons.chevronLeft),
      ),
    ),
    Semantics(
      label: '공유',
      child: Button(
        variant: CoreButtonVariant.ghost,
        shape: CoreButtonShape.square,
        onPressed: share,
        child: Icon(LucideIcons.share),
      ),
    ),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
ToolbarGroup(
  ariaLabel: '페이지 동작',
  direction: CoreAxis.vertical,
  children: [
    Button(
      variant: CoreButtonVariant.ghost,
      shape: CoreButtonShape.square,
      onPressed: goBack,
      attributes: {'aria-label': '뒤로'},
      child: Icon(LucideIcons.chevronLeft),
    ),
    Button(
      variant: CoreButtonVariant.ghost,
      shape: CoreButtonShape.square,
      onPressed: share,
      attributes: {'aria-label': '공유'},
      child: Icon(LucideIcons.share),
    ),
  ],
)
```

  </TabItem>
</Tabs>

## 서페이스 스타일에 따른 모양

<Preview demo="toolbar-group/surface" height="240" />

그룹의 모양은 리퀴드 글라스인지에 따라 둘 중 하나입니다. 아래 값은 그룹이 정하는 기본값입니다. 모서리 · 안쪽 여백 · 테두리 · 그림자는 `popupStyle`로, 버튼의 높이 · 최소 폭 · 누를 때 · 아이콘 크기는 버튼 스타일로 덮어쓸 수 있습니다. 유리 모양의 컨트롤 자리(44 · 48)는 바꿀 수 없어서, 버튼을 더 작게 지정해도 자리는 그대로입니다.

아래 표의 테두리와 그림자는 서페이스 스타일에 따라 다르게 그려질 수 있습니다. 예를 들어 neo-brutalism에서는 불투명 그룹의 테두리가 4로 두꺼워지고, 그림자는 흐림 없이 오른쪽 아래로 밀린 진한 그림자가 됩니다.

| 항목 | 그 밖의 서페이스 스타일 | 리퀴드 글라스 |
| --- | --- | --- |
| 모서리 | 9999 | 9999 |
| 안쪽 여백 | 4 | 0 |
| 테두리 | 1px `outlineVariant` | 0 |
| 그림자 | `lg` 단계 | `sm` 단계 |
| 컨트롤 자리 | 컨트롤의 크기 그대로 | 가로 그룹은 44 × 44 이상, 세로 그룹은 48 × 48 이상. 컨트롤은 자리 가운데에 놓입니다. |
| 버튼의 높이 · 최소 폭 | 버튼의 `size`를 따릅니다. | 자리 크기(44 · 48)가 최소 높이 · 최소 폭입니다. 아이콘 버튼(`square` · `circle`)은 이 크기로 그립니다. 글자 버튼은 `size`의 위아래 여백과 글자 줄을 더한 높이가 자리보다 크면 그만큼 높아집니다. 표준 밀도에서는 가로 그룹의 `xl` · `xl2`와 세로 그룹의 `xl2`가 그렇습니다. |
| 누를 때 | 버튼의 기본 동작 | 버튼이 줄어들지 않습니다(`pressedScale` 1). |
| 아이콘 크기 | 버튼의 크기를 따릅니다. | 가로 그룹은 버튼의 크기를 따르고, 세로 그룹은 24입니다. |

- 세로 유리 그룹의 폭 48은 리퀴드 글라스 [NavigationBar](/components/navigation-bar) 레일의 폭과 같고, 아이콘 24도 레일의 아이콘과 같습니다. 한 자리에 함께 선 두 캡슐이 한 벌로 보이게 하기 위해서입니다. Jaspr Web에서는 내용 폭이 되는 부모 안에 두어야 이 폭이 됩니다([플랫폼 차이](#플랫폼-차이)).
- 앱의 `CoreButtonTheme`이나 버튼의 `buttonStyle`에 적은 높이 · 아이콘 크기는 그룹의 유리 기본값보다 우선합니다. 다만 세로 유리 그룹의 `square` · `circle` 버튼은 아이콘 크기를 `iconShapeIconStyle`에 적어야 바뀝니다. `leadingIconStyle` · `trailingIconStyle`에 적은 크기는 그룹의 24에 밀립니다.
- 유리 자리(44 · 48)는 앱의 밀도를 바꿔도 움직이지 않습니다. 다만 글자 버튼의 위아래 여백은 밀도를 따르므로, `spacious`에서는 가로 유리 그룹의 `lg` 글자 버튼도 44보다 높아집니다. 불투명 그룹의 버튼은 밀도를 따라 높이가 바뀝니다.
- 유리 그룹을 지정해도 버튼의 `variant`는 바뀌지 않습니다. 공유하는 표면 위에는 `ghost` 버튼을 놓습니다.

어느 모양을 쓸지는 아래 순서로 정합니다.

1. `popupStyle`의 `surfaceStyle`을 주면 그 값만 봅니다. `CoreSurfaceStyleId.liquidGlass`면 유리 모양이고, 다른 값이면 불투명 모양입니다.
2. 비우면 주변 서페이스 스타일이 리퀴드 글라스인지를 따릅니다.

앱 테마의 `CorePopupTheme`에 둔 `surfaceStyle`은 모양(크기 · 여백)을 정하는 이 판단에 쓰지 않습니다. 하지만 `popupStyle`에 `surfaceStyle`이 없으면 패널의 재질은 그 값을 따르므로, 모양과 재질이 어긋날 수 있습니다. Jaspr Web의 유리 모양 그룹은 패널의 재질을 리퀴드 글라스로 직접 정해 이 값의 영향을 받지 않습니다.

<Split>

<Code language="dart" title="이 그룹만 리퀴드 글라스">
ToolbarGroup(
  ariaLabel: '편집 도구',
  popupStyle: CorePopupStyle(
    surfaceStyle: CoreSurfaceStyleId.liquidGlass,
  ),
  children: actions,
)
</Code>

<Code language="dart" title="유리 앱에서 이 그룹만 불투명">
ToolbarGroup(
  ariaLabel: '편집 도구',
  popupStyle: CorePopupStyle(
    surfaceStyle: CoreSurfaceStyleId.defaultStyle,
  ),
  children: actions,
)
</Code>

</Split>

`popupStyle`의 `surfaceStyle`은 이 그룹의 재질을 정하고, 리퀴드 글라스인지에 따라 위 표의 모양도 함께 바꿉니다. 색 팔레트와 글꼴은 그대로입니다.

<Note>

투명도 줄이기가 켜지면(Flutter는 `CoUIApp(reduceTransparency: true)`, 웹은 `prefers-reduced-transparency`) 유리 그룹의 배경이 불투명해지고 뒤 흐림이 사라집니다. 크기와 여백은 유리 모양 그대로입니다.

Flutter에서 고대비를 켜면 `popupStyle`로 유리를 준 그룹은 굴절을 그리지 않습니다. 반투명한 채움과 뒤 흐림은 남으므로, 불투명하게 보여야 하면 투명도 줄이기를 씁니다.

</Note>

<a id="동작-스펙-behavior"></a>

## 상태

<Preview demo="toolbar-group/disabled" />

그룹에는 비활성 · 선택 같은 상태가 없습니다. 상태는 안의 컨트롤마다 따로 가집니다. 위 그룹은 두 번째 버튼만 끈 모습입니다.

| `children` | 화면 |
| --- | --- |
| 그릴 컨트롤이 하나 이상 | 패널과 접근성 그룹을 그립니다. |
| 빈 목록 | 패널도 접근성 그룹도 그리지 않습니다. |
| 세로 그룹에 `horizontalOnly` 동작만 | 빈 목록과 같습니다. |

- 숨길 동작은 `children`에서 뺍니다.
- 그릴 것이 없으면 Flutter는 크기가 0인 빈 상자를 두고, 웹은 요소를 남기지 않습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

확대 · 축소, 실행 취소 · 다시 실행처럼 함께 쓰는 동작을 묶을 때 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 앱의 주요 섹션 사이를 옮겨 다닐 때 | [NavigationBar](/components/navigation-bar) |
| 파일 · 편집처럼 계층이 있는 명령 줄 | [Menubar](/components/menubar) |
| 명령이 많아 접어 두어야 할 때 | [DropdownMenu](/components/dropdown-menu) |
| 여러 칸 가운데 하나를 골라 켜 둘 때 | [ToggleGroup](/components/toggle-group) |
| 요소끼리 테두리를 맞대고 붙일 때 | [Join](/components/join) |

<Cards columns="2">
<Card demo="toolbar-group/do-split" tone="do" eyebrow="이렇게 하세요" title="기능마다 그룹 하나">

관련 기능마다 그룹을 따로 만들고 그룹 사이에 여백을 둡니다.

</Card>
<Card demo="toolbar-group/dont-merged" tone="dont" eyebrow="이렇게 하지 마세요" title="한 그룹에 모두">

관련 없는 동작을 한 캡슐에 넣으면 어디까지가 한 묶음인지 알기 어렵습니다.

</Card>
<Card demo="toolbar-group/do-ghost" tone="do" eyebrow="이렇게 하세요" title="ghost 버튼">

공유하는 표면 위에는 `ghost` 버튼을 놓고, 글자나 아이콘 가운데 한 가지로 맞춥니다.

</Card>
<Card demo="toolbar-group/dont-filled" tone="dont" eyebrow="이렇게 하지 마세요" title="채운 버튼">

`primary`처럼 배경을 칠하는 버튼은 버튼마다 자기 면을 그려 한 표면으로 읽히기 어렵습니다.

</Card>
</Cards>

컨트롤이 들어갈 폭(세로 그룹은 높이)은 그룹을 놓는 화면에서 확보합니다. 그룹은 줄바꿈이나 넘침 메뉴를 만들지 않고, 스크롤하지도 않습니다.

## 배치

### 바의 동작을 그대로 넘기기

<Preview demo="toolbar-group/bar-actions" height="240" />

[AppBar](/components/app-bar)의 `leading` · `trailing` 목록은 세로 그룹에 그대로 넘길 수 있습니다. 세로 그룹은 그 가운데 세로 줄에 설 수 있는 동작만 그립니다.

- `BarAction(axisBehavior: CoreBarActionAxisBehavior.horizontalOnly)`로 표시한 동작(글자 버튼 같은 것)은 세로 그룹이 그리지 않습니다. 표시하지 않은 항목은 글자 버튼이어도 모두 세로 줄에 섭니다.
- 목록에 든 `ToolbarGroup`은 캡슐을 따로 그리지 않고, 그 안의 컨트롤을 세로 그룹이 받습니다. 이때 안쪽 그룹의 `ariaLabel` · `popupStyle` · `direction`은 쓰지 않습니다.
- `BarAction`은 목록의 항목 자체여야 하고, 안쪽 `ToolbarGroup`은 목록의 항목이거나 `BarAction`이 바로 감싼 것이어야 합니다. `Semantics` 같은 다른 위젯으로 한 번 더 감싸면 읽지 못해, 표시한 동작도 세로 줄에 서고 안쪽 그룹은 자기 캡슐을 따로 그립니다.
- 가로 그룹은 받은 것을 모두 그대로 그립니다. 안쪽 그룹도 자기 캡슐을 그립니다.

```dart
final actions = [
  shareButton,
  BarAction(
    axisBehavior: CoreBarActionAxisBehavior.horizontalOnly,
    child: editButton,
  ),
];

ToolbarGroup(
  ariaLabel: '페이지 동작',
  direction: CoreAxis.vertical,
  children: actions,
)
```

바와 세로 그룹에 목록 하나를 나눠 그리는 방법은 [AppBar의 조합 예제](/components/app-bar#옆-컨트롤-자리로-동작-나누기)에 있습니다. `Scaffold`의 `adaptiveAppBarActions`를 켜면, 화면 옆에 컨트롤 자리가 있고 높이가 충분할 때 `Scaffold`가 첫 `AppBar`의 옮길 수 있는 동작을 세로 그룹으로 직접 세웁니다. `leading`과 `trailing`은 따로 묶으므로 옮길 동작이 있는 목록마다 그룹이 하나씩(많으면 두 개) 생기고, 두 그룹의 이름은 모두 로케일의 내비게이션 문구(한국어는 "탐색")입니다.

### AppBar와 함께 두기

- 세로 그룹은 `AppBar`의 `leading` · `trailing`에 넣지 않습니다. 컨트롤이 여럿이면 바의 한 줄보다 길어져 넘칩니다.
- 리퀴드 글라스의 `AppBar`는 `leading` · `trailing`에서 이어지는, 묶지 않은 동작을 캡슐 하나로 묶어 그립니다. 직접 넣은 `ToolbarGroup`은 그대로 두고 그 둘레에 캡슐을 더하지 않습니다. 따로 보일 묶음은 `ToolbarGroup`으로 만듭니다.
- 리퀴드 글라스의 `AppBar`는 바 전체에는 유리를 칠하지 않고 동작 캡슐에만 유리를 씁니다. 그래서 그룹의 유리 아래에 바의 유리가 겹치지 않습니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

`ToolbarGroup`에는 전용 Style 클래스나 컴포넌트 테마가 없습니다. 패널의 겉모습은 `popupStyle`(`CorePopupStyle`)로 바꿉니다. `popupStyle`에 적은 필드는 그룹의 기본 모양 위에 덮어씁니다.

<Split>

<Code language="dart" title="그룹 하나만 바꾸기">
ToolbarGroup(
  ariaLabel: '편집 도구',
  popupStyle: CorePopupStyle(
    padding: CoreEdgeInsets.all(CoreSpace.space8),
    spacing: CoreSpace.space4,
  ),
  children: actions,
)
</Code>

<Code language="dart" title="앱의 Popup 테마 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    popup: CorePopupTheme(
      style: CorePopupStyle(
        borderColor: CoreColor.token(CoreColors.outline),
      ),
    ),
  ),
)
</Code>

</Split>

`CorePopupTheme`은 그룹만이 아니라 `Popup`으로 그리는 다른 패널에도 닿습니다.

### 값이 정해지는 순서

```text
CorePopupStyle 기본값                            // Popup 의 기본값
  → CorePopupTheme.style                         // 앱 전체의 Popup
  → CoreToolbarGroupContract.defaultPopupStyle   // 그룹 모양 (리퀴드 글라스면 glassPopupStyle)
  → popupStyle                                   // 그룹 하나
```

뒤로 갈수록 우선하고, 필드마다 따로 합쳐집니다.

- 그룹 모양이 정하는 필드는 `CorePopupTheme`의 값보다 우선합니다. 모서리 · 안쪽 여백 · 최소 폭 · 최대 폭 · 간격이 그렇고, 리퀴드 글라스에서는 테두리 두께와 그림자도 그렇습니다. 웹의 유리 그룹은 `surfaceStyle`도 직접 정합니다.
- 배경색 · 테두리 색 · 글자색과 불투명 모양의 테두리 두께 · 그림자는 `CorePopupTheme`을 따릅니다.
- 유리 그룹의 버튼 기본값(자리 크기, 누를 때 줄어들지 않음, 세로 그룹의 아이콘 24)은 앱의 `CoreButtonTheme`보다 아래에 깔립니다. 그다음에 버튼의 `buttonStyle`이 적용됩니다. 다만 세로 유리 그룹의 `square` · `circle` 버튼 아이콘은 예외라, `iconShapeIconStyle`에 적어야 바뀝니다.

<a id="접근성-accessibility"></a>

## 접근성

그룹은 이름 있는 묶음 하나를 만들고, 동작과 상태는 안의 컨트롤이 알립니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | `ariaLabel`을 이름으로 가진 `Semantics` 컨테이너 노드입니다. 따로 그룹 역할 값을 주지는 않습니다. |
| Jaspr Web | 패널에 `role="group"`과 `aria-label`을 붙입니다. `Popup`의 기본 역할인 `menu`는 쓰지 않습니다. |

각 버튼은 자기 역할과 비활성 상태를 알립니다. 그릴 컨트롤이 없는 그룹은 접근성 트리에도 나타나지 않습니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` / `Shift` + `Tab` | 다음 · 이전 컨트롤로 옮깁니다. 컨트롤마다 `Tab` 순서가 하나씩 있습니다. |
| `Enter` / `Space` | 포커스한 버튼을 누릅니다. |

- 그룹이 따로 처리하는 키는 없고, 그룹만의 방향 키 이동도 없습니다. 방향 키가 포커스를 옮길지는 앱의 기본 단축키가 정합니다. 웹이 아닌 Flutter 앱의 기본값에서는 방향 키로 그 방향의 컨트롤에 포커스를 옮길 수 있고, Flutter Web의 기본값은 방향 키를 스크롤에 씁니다. Jaspr Web의 그룹은 방향 키를 처리하지 않습니다.
- 세로 그룹의 `Tab` 순서는 위에서 아래입니다.
- 꺼진 버튼은 `Tab` 순서에서 빠집니다.

### 스크린 리더

- 그룹의 이름은 번역해 넘긴 `ariaLabel`입니다. 빈 문자열은 디버그 빌드의 assert에 걸립니다.
- 그룹의 이름은 아이콘 버튼의 이름을 대신하지 않습니다. 아이콘 버튼마다 이름을 줍니다.
- 세로 그룹이 목록에 든 `ToolbarGroup`의 컨트롤을 받으면 그 그룹의 이름은 읽히지 않습니다. 받은 컨트롤은 세로 그룹의 이름 아래에 놓입니다.
- live region은 없습니다. 그룹이 나타나거나 사라진 것을 따로 알리지 않습니다.

### 포커스 관리

그룹은 포커스를 옮기지도, 가두지도, 돌려주지도 않습니다. 순서는 `children`의 순서를 따르고, 포커스 링은 안의 버튼이 그립니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | ARIA toolbar 패턴(`role="toolbar"`, 방향 키 이동, `Tab` 순서 하나)을 구현하지 않습니다. 명령이 많으면 `DropdownMenu`로 나눕니다. |
| 공통 | 패널이 둥근 모서리 밖을 잘라 냅니다. 유리 그룹은 안쪽 여백이 0이라 버튼이 패널 가장자리까지 차서, 버튼 바깥에 그리는 포커스 링이 패널 가장자리를 따라 잘립니다. 웹의 가로 그룹에서 버튼 높이가 모두 자리 크기이면, 첫 버튼의 링은 위 · 아래 · 바깥쪽이 모두 잘려 안쪽 세로 선만 남습니다(Chrome에서 확인). 컨트롤이 하나뿐인 그룹에서는 링이 거의 보이지 않을 수 있습니다. 리퀴드 글라스의 `AppBar`가 스스로 묶는 캡슐도 같습니다. |
| 공통 | 불투명 그룹(안쪽 여백 4)도 알약의 둥근 양 끝에서는 첫 버튼과 마지막 버튼의 포커스 링이 잘릴 수 있습니다(웹의 첫 버튼은 Chrome에서 확인). 웹은 1px 테두리가 이 여백에 들어 있어 곧은 가장자리에서도 링이 1만큼 잘릴 수 있습니다. neo-brutalism에서는 4로 두꺼워진 테두리가 웹의 안쪽 여백을 모두 차지해, 곧은 가장자리의 링도 가려질 수 있습니다. |
| Jaspr Web | 유리 그룹은 색 강제 모드에서 경계가 보이지 않을 수 있습니다. 테두리 두께가 0이고, 리퀴드 글라스 스타일이 이 모드에서 표면에 더하는 1px 테두리가 이 그룹에는 닿지 않습니다. |
| Jaspr Web | 리퀴드 글라스의 `AppBar`가 스스로 묶는 동작 캡슐에는 이름 없는 `role="group"`이 붙습니다. 이름이 필요한 묶음은 `ariaLabel`을 가진 `ToolbarGroup`으로 직접 만듭니다. |

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타깃)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

생성자 파라미터의 이름과 기본값은 같습니다. 그리는 결과는 아래 자리에서 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `children` 타입 | `List<Widget>` | `List<Component>` |
| 아이콘 버튼의 이름 | 버튼을 `Semantics(label:)`로 감쌉니다. | `Button(attributes: {'aria-label': ...})` |
| 그룹의 폭 | 내용 폭입니다. 부모가 폭을 강제하면(`stretch` 정렬 등) 그 폭이 됩니다. | 블록 부모나 자식을 늘이는 세로 flex 안에서는 부모 폭을 채웁니다. 가로 flex 안이나 `items-center` · `items-start` 부모 안에서는 내용 폭입니다. |
| 불투명 가로 그룹의 세로 정렬 | 높이가 다른 자식을 세로 가운데에 둡니다. | 높이가 정해진 버튼은 위에 맞추고, 높이를 정하지 않은 글은 패널 높이만큼 늘어나 위에 붙어 보입니다. 유리 그룹은 두 플랫폼 모두 자리 가운데에 둡니다. |
| 폭이 모자랄 때 | 줄을 바꾸지 않고 넘칩니다. 디버그 빌드에는 넘침 표시가 나타납니다. | 버튼이 줄어들며 글자 라벨이 여러 줄로 꺾일 수 있습니다. 한글은 글자 단위로 꺾일 수 있습니다. |
| 폭을 미리 잴 수 없는 자식 | 패널이 자식의 폭을 먼저 잽니다. `LayoutBuilder`나 `ListView`처럼 폭을 미리 잴 수 없는 위젯을 직접 넣으면 레이아웃 오류가 납니다. | 해당 없습니다. |
| 리퀴드 글라스인지 읽는 곳 | `popupStyle`의 `surfaceStyle`, 비우면 주변 `Theme` | `popupStyle`의 `surfaceStyle`, 비우면 `SurfaceStyleScope`, 그것도 없으면 문서의 `data-coui-style` 속성입니다. 서버에서만 렌더한 그룹은 문서 속성을 읽지 못해, 재질은 CSS로 입혀져도 크기 · 여백은 불투명 모양입니다. |
| `popupStyle`로 유리를 준 그룹의 안쪽 | 그룹 아래 전체가 리퀴드 글라스 테마를 읽어, 채움이 있는 버튼이나 안쪽 `ToolbarGroup`도 유리로 그려질 수 있습니다. | 그룹 패널만 유리입니다. 안의 버튼에는 유리 모양의 버튼 기본값이 적용되지만, 안의 버튼과 안쪽 `ToolbarGroup`의 재질은 주변 서페이스 스타일을 따릅니다. |
| 다른 유리 표면 안의 유리 그룹 | 뒤 흐림을 한 번 더 그리지 않습니다. | 자기 뒤 흐림을 따로 그립니다. |
| 유리 효과 | 렌더러에 따라 흐림 · 굴절의 모습이 다를 수 있습니다. | 브라우저의 `backdrop-filter` 지원에 따라 모습이 다를 수 있습니다. |
| HTML 속성 | — | `ToolbarGroup`에는 `id` · `classes` · `css` · `attributes` 파라미터가 없습니다. 위치와 폭은 부모에서 정합니다. |

<a id="props-parameters"></a>

## API

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `ariaLabel` | `String` | 필수 | 그룹의 접근 가능한 이름. 번역한 문자열을 넘깁니다. 빈 문자열은 디버그 빌드의 assert에 걸립니다. |
| `children` | `List<Widget>` | 필수 | 서로 관련된 컨트롤. 웹은 `List<Component>`. 세로 그룹은 `horizontalOnly`로 표시한 동작을 빼고 그립니다. |
| `direction` | `CoreAxis` | `CoreAxis.horizontal` | 컨트롤을 놓는 방향 |
| `popupStyle` | `CorePopupStyle?` | `null` | 그룹 패널의 겉모습. 그룹의 기본 모양 위에 덮어씁니다. `surfaceStyle`은 유리 모양을 쓸지도 정합니다. |

`CorePopupStyle`의 필드는 [Popup의 API](/components/popup#api)에 있습니다.

### 함께 쓰는 `BarAction`

`BarAction`은 바의 동작 하나를 감싸, 그 동작이 설 수 있는 방향을 적습니다. `AppBar`와 세로 `ToolbarGroup`이 이 표시를 읽고, 그 밖의 자리에서는 `child`만 그립니다.

- 생성자는 `BarAction(axisBehavior:, child:)`이고 두 값 모두 필수입니다.
- `axisBehavior`는 `CoreBarActionAxisBehavior.automatic`(표시하지 않은 동작과 같음)이나 `CoreBarActionAxisBehavior.horizontalOnly`(바의 줄에만 남음)입니다.

### `CoreToolbarGroupContract` 상수

| 이름 | 값 | 설명 |
| --- | --- | --- |
| `CoreToolbarGroupContract.defaultDirection` | `CoreAxis.horizontal` | `direction`의 기본값 |
| `CoreToolbarGroupContract.defaultPopupStyle` | 모서리 9999, 안쪽 여백 4, 최소 폭 0, 최대 폭 제한 없음, 간격 0 | 불투명 모양의 패널 |
| `CoreToolbarGroupContract.glassPopupStyle` | 위 값에서 안쪽 여백 0, 테두리 0, 그림자 `CoreShadow.sm` | 리퀴드 글라스 모양의 패널 |
| `CoreToolbarGroupContract.glassActionMinSize` | 44 | 가로 유리 그룹의 자리 |
| `CoreToolbarGroupContract.glassVerticalActionMinSize` | 48 | 세로 유리 그룹의 자리 |
| `CoreToolbarGroupContract.glassVerticalIconSize` | 24 | 세로 유리 그룹의 아이콘 크기 |

방향에 맞는 값은 `CoreToolbarGroupContract.glassActionMinSizeFor(direction)`(자리 크기, 가로 44 · 세로 48)와 `CoreToolbarGroupContract.glassIconStyleFor(direction)`(아이콘 스타일, 가로는 `null` · 세로는 크기 24)가 돌려줍니다.

## 관련 컴포넌트

<Cards columns="3">
<Card title="Button" href="/components/button" more="Button 보기">

그룹 안에서 실행하는 동작입니다.

</Card>
<Card title="Menubar" href="/components/menubar" more="Menubar 보기">

계층이 있는 명령 줄입니다.

</Card>
<Card title="DropdownMenu" href="/components/dropdown-menu" more="DropdownMenu 보기">

접어 두는 추가 명령 목록입니다.

</Card>
</Cards>
