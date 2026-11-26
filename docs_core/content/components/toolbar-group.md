---
title: ToolbarGroup
description: 관련 툴바 동작이 하나의 재질 표면을 공유하는 그룹
category: menu
platforms: [flutter, web]
related: [button, menubar, dropdown-menu]
tags: [toolbar, glass, actions]
---

# ToolbarGroup

관련된 버튼을 하나의 둥근 표면에 묶습니다. 버튼은 가로로 늘어서고, `direction`
으로 세로로 세울 수 있습니다. `popupStyle.surfaceStyle`로 그룹에만 Liquid Glass를
지정할 수 있습니다.

## Live Preview

<LivePreview component="toolbar-group" variants="default,vertical" />

## 사용 시기 (When to Use)

확대·축소, 실행 취소·다시 실행처럼 함께 사용하는 동작을 묶을 때 사용합니다.
화면 이동은 NavigationBar, 계층적인 명령 목록은 Menubar나 DropdownMenu를 사용합니다.

## 기본 사용법 (Basic Usage)

Flutter와 Web의 생성자 이름과 스타일 슬롯이 같습니다.

```dart
ToolbarGroup(
  ariaLabel: '편집 기록',
  popupStyle: const CorePopupStyle(surfaceStyle: .liquidGlass),
  children: [
    Button(variant: .ghost, onPressed: undo, child: const Text('실행 취소')),
    Button(variant: .ghost, onPressed: redo, child: const Text('다시 실행')),
  ],
)
```

### 세로 그룹 (Vertical)

`direction: CoreAxis.vertical` 은 버튼을 위에서 아래로 세웁니다. 바 안이 아니라
콘텐츠 옆에 서는 컨트롤 — 화면 한쪽의 세로 컨트롤 자리, 지도나 캔버스의 도구
모음 — 에 씁니다. 세로로 세운 자리에서는 글자를 눕히지 않으므로 아이콘 버튼을
넣고, 버튼마다 이름을 줍니다.

```dart
ToolbarGroup(
  ariaLabel: '페이지 동작',
  direction: CoreAxis.vertical,
  children: [
    Semantics(
      label: '뒤로',
      child: Button(
        variant: .ghost,
        shape: .square,
        onPressed: goBack,
        child: const Icon(LucideIcons.chevronLeft),
      ),
    ),
    Semantics(
      label: '공유',
      child: Button(
        variant: .ghost,
        shape: .square,
        onPressed: share,
        child: const Icon(LucideIcons.share),
      ),
    ),
  ],
)
```

Web 은 `Semantics` 대신 `Button(attributes: {'aria-label': '뒤로'})` 로 이름을 줍니다.

Liquid Glass 에서 세로 그룹은 폭 48 의 캡슐이고 버튼 하나가 48 × 48 을 차지합니다.
가로 그룹의 자리는 44 입니다. 세로 그룹이 48 인 것은 같은 자리에 함께 서는
[NavigationBar](/components/navigation-bar) 의 글래스 레일과 폭을 맞추기 위해서입니다.
아이콘도 레일과 같은 24 로 그립니다 — 한 자리에 선 두 캡슐의 아이콘 굵기가 같아야
하기 때문입니다. 버튼에 직접 준 아이콘 크기는 이 값보다 먼저입니다.
불투명한 그룹은 방향과 상관없이 안쪽 여백 4 에 버튼 자기 크기를 그대로 두고,
아이콘도 버튼 자기 크기입니다.

세로 그룹을 `AppBar` 의 `leading` · `trailing` 에 넣지 마세요. 바의 한 줄보다
길어서 넘칩니다.

#### 바의 동작을 그대로 넘기기

`AppBar` 의 `leading` · `trailing` 목록을 세로 그룹에 그대로 넘길 수 있습니다.
세로 그룹은 그 가운데 세로 줄에 설 수 있는 동작만 그립니다.

- `BarAction` 으로 `horizontalOnly` 라고 표시한 동작(글자 버튼)은 그리지 않습니다.
- 목록에 든 `ToolbarGroup` 은 캡슐을 따로 그리지 않고, 그 안의 동작을 세로 그룹이
  자기 것으로 받습니다. 세로 그룹은 캡슐 하나입니다.

가로 그룹은 받은 것을 모두 그대로 그립니다. 바 쪽에서 나머지 동작만 남기는 방법은
[AppBar 의 조합 예제](/components/app-bar#옆-컨트롤-자리로-동작-나누기) 를 보세요.

## Props / Parameters

| 속성 | 타입 | 기본값 | 설명 |
|---|---|---|---|
| `ariaLabel` | `String` | 필수 | 비어 있지 않은, 번역된 그룹 이름 |
| `children` | Flutter `List<Widget>`, Web `List<Component>` | 필수 | 서로 관련된 컨트롤. 세로 그룹은 `horizontalOnly` 로 표시한 `BarAction` 을 빼고 그립니다 |
| `direction` | `CoreAxis` | `horizontal` | 버튼이 늘어서는 방향. `vertical` 은 위에서 아래로 세웁니다 |
| `popupStyle` | `CorePopupStyle?` | `null` | 공유 패널의 재질·여백·모서리 등 |

## 스타일 시스템 (Style System)

`CoreToolbarGroupContract.defaultPopupStyle`은 캡슐 모서리, 4px 안쪽 여백,
자식 간격 0을 기본으로 제공합니다. Liquid Glass 에서는 안쪽 여백 없이 버튼이
자리를 가득 채웁니다 — 가로 그룹은 44, 세로 그룹은 48 입니다
(`CoreToolbarGroupContract.glassActionMinSizeFor`). 세로 그룹의 버튼은 아이콘을 24 로
그립니다(`CoreToolbarGroupContract.glassVerticalIconSize`). 버튼에 직접 준 크기는 이
값들보다 먼저입니다. `popupStyle`에 지정한 값으로 덮어쓴 뒤
합성된 Popup의 테마와 재질 해석 경로를 따릅니다. 재질 축의 `null`은 상속이고,
`defaultStyle`은 명시적 불투명 재질입니다. 팔레트와 글꼴은 그대로 유지됩니다.

투명도 줄이기·고대비 설정이 로컬 유리 재질보다 우선합니다. 그룹에 유리를
지정해도 자식 버튼의 variant는 바뀌지 않으므로 공유 표면에는 ghost 버튼을 사용합니다.

## 동작 스펙 (Behavior)

버튼의 콜백, 활성 상태, 포커스는 각 자식이 소유합니다. 그룹 자체는 명령을
실행하거나 선택 상태를 만들지 않습니다. 숨길 동작은 children에서 제외하며,
그릴 동작이 하나도 없으면(목록이 비었거나, 세로 그룹에 `horizontalOnly` 동작만
있으면) 패널과 접근성 그룹을 모두 그리지 않습니다.

## 사용 가이드라인 (Usage Guidelines)

관련 기능마다 별도 그룹을 만들고 그룹 사이에 여백을 둡니다. 그룹 내부의
버튼 표현은 텍스트 또는 아이콘으로 일관되게 유지합니다. 아이콘만 사용하는
버튼에는 각각 접근 가능한 이름을 제공해야 합니다.

자식이 들어갈 폭(세로 그룹은 높이)은 호출자가 확보합니다. 그룹은 자동 줄바꿈이나
overflow 메뉴를 만들지 않고, 스크롤하지도 않습니다. AppBar 안에 별도 유리 그룹을 넣으면 AppBar의 채움을
투명하게 지정해 배경 필터가 겹치지 않도록 구성할 수 있습니다.

## 접근성 (Accessibility)

### 역할

Flutter는 `CoUISemantics`의 group 역할과 `ariaLabel`을 사용하고, Web은
`role="group"`과 `aria-label`을 제공합니다. 각 버튼은 자신의 역할과 활성 상태를
노출합니다. 빈 그룹은 접근성 트리에도 나타나지 않습니다.

### 키보드

Tab으로 자식 컨트롤을 탐색하며 Enter/Space 활성화는 버튼이 담당합니다.
그룹 전용 방향키 탐색은 없습니다. 세로 그룹의 Tab 순서는 위에서 아래입니다.

### 스크린 리더

그룹의 이름은 호출자가 번역해 제공한 `ariaLabel`에서 옵니다. 각 버튼은 텍스트나
별도로 지정한 접근 가능한 이름을 사용합니다. 그룹 자체에 live region은 없습니다.
세로 그룹이 목록에 든 `ToolbarGroup` 의 동작을 받으면 그 그룹의 이름은 읽히지
않습니다 — 받은 동작은 세로 그룹의 이름 아래에 놓입니다.

### 포커스 관리

진입·이탈 순서는 자식 버튼의 일반 Tab 순서를 따릅니다. 포커스 트랩이나 자동
포커스 복귀를 만들지 않습니다. 포커스 링은 자식 버튼이 그립니다.

### 알려진 제약

이 그룹은 ARIA toolbar의 roving 포커스 패턴을 구현하지 않습니다. 자식 버튼마다
Tab stop을 가지며, 많은 명령은 DropdownMenu로 나누어 구성합니다. 그룹의 이름은
아이콘 버튼 각각의 이름을 대신하지 않습니다.

## 크로스 플랫폼 차이점 (Platform Differences)

Flutter는 Widget, Web은 Component 목록을 받습니다. API와 빈 그룹 처리,
방향, 캡슐 기하 및 재질 우선순위는 같습니다. 아이콘 버튼의 이름은 Flutter 가
`Semantics(label:)` 로, Web 이 `Button(attributes: {'aria-label': ...})` 로 줍니다. 유리 렌더링은 Flutter의 Impeller
지원 여부와 Web 브라우저의 backdrop-filter 지원에 따라 달라집니다.

## 관련 컴포넌트

- [Button](/components/button): 그룹 안에서 실행하는 동작
- [Menubar](/components/menubar): 계층적인 메뉴
- [DropdownMenu](/components/dropdown-menu): 추가 명령 목록
