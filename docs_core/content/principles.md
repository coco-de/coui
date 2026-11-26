---
title: 설계 원칙
description: 목표는 같은 코드가 Flutter와 Web에서 같게 보이는 것입니다. 아래 규칙은 이 목표를 위해 포기한 것들의 목록입니다.
design: true
---

# 설계 원칙

## 같은 줄이 양쪽에서 컴파일된다

컴포넌트 호출은 두 플랫폼에서 같고, 다른 것은 import 줄뿐입니다. 레이아웃도 Flutter 기본 위젯 대신 공통 컴포넌트로 씁니다.

| Flutter 습관 | 양쪽 공통 |
|---|---|
| `Container`, `Row`, `Column`, `Padding` | `Frame` |
| `Stack` / `Positioned` | `Stacks` / `Position` |
| `SizedBox` spacer | `Gap` |

> 정렬 같은 타입도 플랫폼과 무관한 Core 타입(CoreAlignment)을 쓰고, 이름은 물리적 좌우가 아니라 텍스트 시작 방향(topStart)을 따릅니다.

Flutter 의 `Alignment` · `StackFit` · `Clip` 은 `coui_web` 에 없습니다. 그 타입을 쓴 파일은 Flutter 에서는 문제없이 돌고, Web 빌드에 넣을 때 비로소 컴파일되지 않습니다.

## 값을 넣을 자리는 세 개다

같은 값을 두 경로로 받지 않도록 자리를 나눕니다. 같은 겉모습을 두 곳에서 정하면 위젯 하나의 xxxStyle이 앱 전체의 값을 이깁니다.

| 무엇을 | 어디에 |
|---|---|
| 무엇인가, 어떻게 동작하나 (variant, enabled, onTap) | 생성자 파라미터 |
| 어떻게 보이나 (색, 여백, 반경, 그림자, duration) | xxxStyle 슬롯 |
| 앱 전체에 한 번 (모든 Card의 반경 등) | CoreComponentTheme |

<DesignNote title="우회하면 조용히 깨집니다">

리터럴 색은 CSS 변수를 거치지 않아 다크 모드에서 틀리고, 리터럴 Duration에는 동작 줄이기 설정이 닿지 않습니다.

</DesignNote>

자동 완성에 보이는 `resolveXxx` · `ResolvedXxx` 는 쓰라고 내놓은 이름이 아닙니다. 두 플랫폼이 일부러 다른 모양으로 만드는 내부 결과물이고, 사용자 API 는 생성자 파라미터와 `CoreXxxStyle` · `CoreComponentTheme` 입니다.

## 이름은 Flutter를 따른다

Flutter 쪽에 이미 이 라이브러리를 쓰는 프로젝트가 있어 이름은 한 방향으로 맞춥니다. Button, Icon, Card처럼 접두사를 붙이지 않습니다.

| 웹 관습 이름 | 실제 이름 |
|---|---|
| `CodeBlock` | `CodeSnippet` |
| `List` | `Listing` |
| `Grid` | `ResponsiveGrid` |

## 텍스트는 chain으로 쓴다

style: 인자는 플랫폼마다 받는 타입이 달라 이식되지 않습니다. chain은 그릴 때 현재 테마를 읽어 다크 모드를 자동으로 따릅니다.

<Code language="dart" title="Flutter · Web">
Text('저장').labelMedium.onPrimary
</Code>

같은 숫자도 두 플랫폼에서 뜻이 다릅니다. `TextStyle(letterSpacing: 0.5)` 는 Flutter 에서 0.5 논리 픽셀, Web 에서 0.5em 입니다. 두 플랫폼의 `Text` 는 같은 클래스가 아니라서 chain 결과를 공유 타입 변수에 담을 수 없고, 슬롯에 바로 넣을 때만 같은 줄이 됩니다. 메서드 목록은 [Text](/components/text) 에 있습니다.

<a id="chrome-을-생성자-파라미터로-받지-않는다"></a>

## 일부러 하지 않는 것

Card에는 padding, color, borderRadius 인자가 없고 모두 cardStyle 하나로 받습니다. Web의 classes와 css는 구조 레이아웃에만 씁니다.

<Cards variant="outlined" columns="2">
  <Card tone="do" eyebrow="권장" title="테마를 따르는 방법">

```dart
Card(
  cardStyle: CoreCardStyle(
    backgroundColor: CoreColor.token(...),
  ),
)
```

- 테마와 다크 모드를 따릅니다.

</Card>
  <Card tone="dont" eyebrow="금지" title="라이트 모드에서만 맞는 방법">

```dart
Card(
  css: Styles(raw: {
    'background-color': '#1e293b',
  }),
)
```

- 인라인 스타일이 항상 이겨 다크 모드에서 틀립니다.

</Card>
</Cards>

겉모습 몇 개만 바꿀 때는 `withStyle` 로 바꿀 필드만 덧붙입니다. 자식을 놓기만 하는 레이아웃 컴포넌트(`Stacks` · `Position`)는 Style 슬롯이 없습니다. 예외는 `Frame` 하나로, Figma 의 Inspect 값을 그대로 옮기려고 낱개 파라미터와 Style 을 함께 받으며 필드마다 우선순위가 다릅니다.

```dart
Badge(child: Text('New')).withStyle(
  CoreBadgeStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius4)),
)
```

Web 컴포넌트는 `id` · `role` · `aria-*` · `attributes` 와 이벤트 핸들러를 HTML 요소로 그대로 넘깁니다. `classes` 로 색을 넣으면 스타일시트의 규칙 순서에 따라 이기기도 하고 지기도 합니다.

## 막혀 있는 것과 규율인 것

규율로만 지키는 항목은 테마를 바꾸거나 반대 플랫폼을 빌드하기 전까지 아무 신호가 없습니다.

<Cards variant="outlined" columns="2">
  <Card title="컴파일러가 막는 것">

- 컴포넌트 이름 충돌
- Web 코드의 raw Alignment

</Card>
  <Card title="규율로 지키는 것">

- Flutter의 raw Stack, Positioned
- classes, css의 리터럴 색
- 컴포넌트 밖의 리터럴 Duration, Color

</Card>
</Cards>
