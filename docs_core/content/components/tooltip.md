---
title: Tooltip
description: 툴팁 컴포넌트
category: overlay
platforms: [flutter, web]
related: [popover, hover-card]
tags: [help, floating, hover]
template: v2
source: overlay/tooltip
---

# Tooltip

<a id="live-preview"></a>

## 플레이그라운드

속성을 바꿔 보며 말풍선을 확인하고, 그림 아래의 **올려 보기** 버튼에 포인터를 올려 같은 속성의 `Tooltip`을 열어 보세요. 만들어진 코드는 두 플랫폼에서 그대로 쓸 수 있습니다.

<Playground component="tooltip" />

`Tooltip`은 **포인터를 올려야** 열립니다. 키보드 포커스나 터치로 여는 방법은 따로 없으므로, 꼭 읽어야 하는 안내는 툴팁에만 두지 않습니다. 코드로 여닫는 `open`이나 컨트롤러도 없습니다.

<Note>

무대의 말풍선은 페이지 안에 그린 그림입니다. 열린 말풍선은 오버레이에 떠서 트리거에 붙으므로 문서 안의 그 자리에 둘 수 없습니다. 그림은 `Tooltip`이 쓰는 값(`CoreTooltipStyle` 기본값과 고른 `tooltipStyle`, 테마, 서페이스 스타일)으로 그립니다. 화면 가장자리에서 반대쪽으로 넘기는 것, 대기 시간, 나타나고 사라지는 모습은 **올려 보기**로 여는 실제 `Tooltip`에서만 확인할 수 있습니다. 이때 웹 팬에서는 페이지 화면을, Flutter 팬에서는 그 팬 안을 화면으로 보고 말풍선을 놓습니다. 이 페이지의 다른 말풍선 미리보기도 같은 그림입니다.

</Note>

## 구조

툴팁은 안내를 붙일 트리거(`child`)와, 열려 있는 동안만 오버레이에 그려지는 말풍선으로 이루어집니다.

<Anatomy demo="tooltip/anatomy">
<AnatomyItem select="[data-docs-part=bubble]" side="left" name="bubble">

말풍선. 바탕은 `onSurface`, 모서리는 8, 안쪽 여백은 좌우 10 · 위아래 6입니다. 기본 말풍선에는 테두리와 그림자가 없고, 서페이스 스타일이 컨트롤에 더하는 테두리도 붙지 않습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=label]" side="top" name="message">

안내 글. 글자는 `labelSmall`(12 Medium), 색은 `surface`입니다. 한 줄짜리 기본 말풍선의 높이는 29(6 + 줄 높이 17 + 6)입니다. `tooltipChild`를 주면 이 자리에 그 위젯을 그립니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=tail]" side="right" name="tail">

꼬리. 기본 말풍선에는 없습니다(`tailWidth` · `tailHeight` 0). 이 그림은 12 × 6을 준 것입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=trigger]" side="left" name="child">

트리거. 안내를 붙일 위젯입니다. 말풍선은 트리거에서 8(`placementOffset`) 떨어진 자리에 놓입니다.

</AnatomyItem>
</Anatomy>

### 꼬리

트리거를 가리키는 삼각형이 필요하면 `tailWidth`(말풍선에 닿는 밑변)와 `tailHeight`(트리거 쪽으로 튀어나온 길이)를 함께 줍니다. 어느 하나라도 `0`이면 꼬리를 그리지 않습니다. 꼬리는 말풍선의 바탕색을 그대로 따르고, 말풍선이 반대쪽으로 넘어가면 함께 옮겨 갑니다. 꼬리는 `placementOffset`이 만든 틈으로 튀어나오므로, `tailHeight`가 그보다 길면 트리거를 덮습니다.

<Preview demo="tooltip/tail" />

```dart
Tooltip(
  message: '저장',
  tooltipStyle: CoreTooltipStyle(
    tailWidth: CoreSpace.space12,
    tailHeight: CoreSpace.space6,
  ),
  child: Icon(LucideIcons.save),
)
```

<a id="변형-variants"></a>
<a id="기본-사용법-basic-usage"></a>

## 내용

Tooltip에는 variant가 없습니다. 무엇이 보일지는 `message`와 `tooltipChild`가 정합니다. `tooltipChild`를 주면 `message` 대신 그 위젯을 그립니다. 둘 다 비어 있어도 여백만 있는 빈 말풍선이 열리므로, 보여 줄 안내가 없으면 `Tooltip`으로 감싸지 않습니다.

```dart
Tooltip(
  message: '이 버튼을 누르면 저장됩니다',
  child: Button(
    onPressed: handleSave,
    child: Icon(LucideIcons.save),
  ),
)
```

### 긴 안내문 줄바꿈

기본 말풍선에는 폭 상한이 없습니다. 웹은 한 줄로 길어지고, Flutter는 화면 폭에 닿으면 줄을 바꿉니다. 두 플랫폼이 정한 폭에서 줄을 바꾸게 하려면 `panelMaxWidth`를 줍니다. 폭을 잡으려고 `tooltipChild`를 쓸 필요는 없습니다. `message`에 넣은 줄바꿈 문자(`\n`)는 Flutter에서만 줄을 나눕니다. 웹에서는 `panelMaxWidth`를 주어도 공백 하나로 보입니다.

<Preview demo="tooltip/long" />

```dart
Tooltip(
  message: '배너 이미지는 가로 1200px 이상을 권장합니다. '
      '더 작은 이미지는 확대되어 흐리게 보일 수 있습니다.',
  tooltipStyle: CoreTooltipStyle(panelMaxWidth: CoreSpace.space256),
  child: Icon(LucideIcons.info),
)
```

### 리치 툴팁

`tooltipChild`에는 아이콘이나 두 줄짜리 설명처럼 원하는 위젯(웹은 `Component`)을 넣습니다. 라벨 글자 스타일(`labelSmall` · `surface`)이 기본값으로 이어지고, 안쪽 위젯이 직접 정한 색과 크기가 있으면 그것을 따릅니다. 두 플랫폼에서 똑같이 보이게 하려면 다음을 지킵니다.

- 말풍선 안의 아이콘에는 색을 직접 줍니다(`CoreIconStyle(color: CoreColor.token(CoreColors.surface))`). Flutter에서 색을 주지 않은 `Icon`은 주변 아이콘 색(보통 `onSurface`)으로 그려져 바탕에 묻힐 수 있습니다.
- 글에는 `.semiBold`처럼 굵기나 색만 바꾸는 체인을 씁니다. Flutter에서 `.bodySmall` · `.labelMedium`처럼 글자 역할을 정하는 체인은 색을 `onSurface`에서 시작하므로 바탕에 묻힐 수 있습니다.
- Flutter의 `Row` · `Column`은 `mainAxisSize: MainAxisSize.min`으로 둡니다. 두지 않으면 말풍선이 화면 폭이나 높이만큼 커집니다.

<Preview demo="tooltip/rich" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Tooltip(
  tooltipChild: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        LucideIcons.keyboard,
        iconStyle: CoreIconStyle(
          size: CoreSize.size16,
          color: CoreColor.token(CoreColors.surface),
        ),
      ),
      Gap.space8(),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('실행 취소').semiBold,
          Text('Ctrl + Z'),
        ],
      ),
    ],
  ),
  child: Button(
    variant: CoreButtonVariant.outline,
    onPressed: handleUndo,
    child: Text('실행 취소'),
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
Tooltip(
  tooltipChild: div(
    [
      Icon(
        LucideIcons.keyboard,
        iconStyle: CoreIconStyle(
          size: CoreSize.size16,
          color: CoreColor.token(CoreColors.surface),
        ),
      ),
      Gap.space8(),
      div(
        [Text('실행 취소').semiBold, Text('Ctrl + Z')],
        classes: 'flex flex-col',
      ),
    ],
    classes: 'flex items-center',
  ),
  child: Button(
    variant: CoreButtonVariant.outline,
    onPressed: handleUndo,
    child: Text('실행 취소'),
  ),
)
```

  </TabItem>
</Tabs>

<a id="동작-스펙-behavior"></a>

## 상태

툴팁은 닫힘과 열림 두 상태를 가지며, 상태는 포인터의 움직임이 정합니다.

| 상황 | 동작 |
| --- | --- |
| 포인터를 트리거에 올림 | `waitDuration` 동안 머물면 열립니다. |
| 기다리는 동안 벗어남 | 열리지 않습니다. 툴팁이 붙은 항목들을 빠르게 지나가도 뜨지 않습니다. |
| 열린 뒤 트리거를 벗어남 | `showDuration` 동안 그대로 머문 뒤 사라집니다. `minDuration`을 준 경우는 타이밍 표를 보세요. |
| 머무는 동안 다시 올림 | 닫지 않고 그대로 둡니다. |
| 사라지는 동안 다시 올림 | 웹은 바로 다시 나타나고, Flutter는 `waitDuration`이 지난 뒤 새로 엽니다. |
| 누름 | Flutter는 말풍선 밖을 누르면 닫습니다. 트리거를 누르는 것도 포함이며, 포인터가 트리거를 벗어났다가 다시 올라와야 다시 열립니다. 웹은 누름으로 닫지 않습니다. |
| 열린 동안 값 바꾸기 | Flutter는 열린 말풍선에 반영하지 않고 다음에 열 때 반영합니다. 웹은 `message` · `tooltipChild` · 겉모습을 바로 반영하고, `position` · `placementOffset`은 다음에 열 때 반영합니다. |

### 타이밍

| 파라미터 | 기본값 | 설명 |
| --- | --- | --- |
| `waitDuration` | 150ms (`CoreDuration.fast`) | 열리기 전에 포인터가 트리거에 머물러야 하는 시간 |
| `showDuration` | 150ms (`CoreDuration.fast`) | 포인터가 벗어난 뒤 닫기 시작할 때까지 머무는 시간 |
| `minDuration` | 0ms (하한 없음) | 포인터가 올라온 때부터 잰 최소 시간. 이 시간이 지나기 전에 벗어나면 `showDuration` 대신 남은 시간만큼 머뭅니다. 남은 시간이 `showDuration`보다 짧으면 더 빨리 닫힙니다. |

`waitDuration` · `showDuration`의 기본값은 두 플랫폼이 `CoreTooltipContract`(`defaultWaitDuration` · `defaultShowDuration`)에서 읽습니다. `minDuration`은 비우면 0ms이며, Flutter에서는 `CoreHoverTheme`에 정한 값이 있으면 그 값을 씁니다.

- Flutter에서 `waitDuration: null` · `showDuration: null`을 직접 넘기면 위 표의 값이 아니라 `Hover`의 값(`CoreHoverTheme`에 정한 값, 없으면 대기 500ms · 머무름 200ms)을 씁니다. 웹은 `null`을 넘겨도 위 표의 값입니다.
- Flutter에서 동작 줄이기를 켜면 500ms 이하인 대기 · 머무름 · 최소 시간은 0이 되어, 포인터를 올리면 바로 열리고 벗어나면 바로 닫기 시작합니다. 웹의 타이밍은 이 설정에 따라 바뀌지 않습니다.

### 지연 시간 조절

두 플랫폼이 같은 파라미터를 씁니다. 대부분의 화면에는 기본 150ms가 알맞습니다. 너무 짧으면 지나가기만 해도 뜨고, 너무 길면 사용자가 기다리게 됩니다.

```dart
// 기다리지 않고 바로 열기
Tooltip(
  message: '바로 표시',
  waitDuration: Duration.zero,
  child: target,
)

// 1초 동안 머물러야 열기
Tooltip(
  message: '1초 뒤 표시',
  waitDuration: Duration(milliseconds: CoreDuration.ms1000),
  child: target,
)

// 열린 뒤 금방 벗어나도, 포인터가 올라온 때부터 500ms까지는 보이기
Tooltip(
  message: '잠깐 올려도 읽을 수 있게',
  minDuration: Duration(milliseconds: CoreDuration.slow),
  child: target,
)
```

### 애니메이션

나타나고 사라지는 시간은 고정값이며, 바꾸는 파라미터나 스타일 필드가 없습니다. `waitDuration` · `showDuration` · `minDuration`은 이 움직임의 길이를 바꾸지 않습니다.

- **열기** — 150ms 동안 일정한 속도(`linear`)로 나타나면서 0.9배에서 1배로 커집니다.
- **닫기** — 사라지는 움직임은 약 67ms이고, 말풍선은 100ms 뒤에 내립니다.
- **커지는 기준점** — Flutter는 트리거를 향한 변입니다(반대쪽으로 넘어간 뒤에도 트리거 쪽 변). 웹은 말풍선 가운데입니다.
- **웹의 전환** — 웹은 위 값을 CSS 전환으로 설정합니다. 다만 말풍선을 오버레이에 그리는 방식 때문에 이 움직임이 보이지 않고 바로 나타나거나 사라질 수 있습니다.
- **유리 스타일** — Flutter는 말풍선이 흐림 같은 재질을 진행에 맞춰 줄이며 나타나고 사라집니다. 웹은 말풍선 자체의 불투명도를 바꾸게 되어 있어, 전환이 보이는 동안에는 흐린 판과 선명한 뒤 화면이 겹쳐 보일 수 있습니다.
- **동작 줄이기** — 웹은 이 설정을 켜도 말풍선에 설정한 전환 시간을 줄이지 않습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

툴팁은 트리거를 짧게 덧붙여 설명합니다. 값을 고르거나, 포커스를 붙잡고 응답을 받는 자리가 아닙니다.

- 글자 없는 아이콘 버튼이나 줄여 쓴 UI에 설명을 덧붙일 때
- 키보드 단축키를 알려 줄 때
- 1~2줄의 짧은 글이면 충분할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 이미지 · 버튼처럼 내용이 많은 호버 미리보기 | [HoverCard](/components/hover-card) |
| 누르면 열리고 그 안에서 조작하는 패널 | [Popover](/components/popover) |
| 행동의 결과를 알리는 알림 | [Toast](/components/toast) |
| 응답을 기다려야 하는 확인 | [Dialog](/components/dialog) |
| 꼭 읽어야 하는 안내 | 화면에 늘 보이는 글(입력창의 `description` 등) |

<a id="do"></a>
<a id="dont"></a>

### 하면 좋은 것과 피할 것

<Cards columns="2">
<Card demo="tooltip/do-icon-name" tone="do" eyebrow="이렇게 하세요">

글자 없는 아이콘 버튼에는 무엇을 하는 버튼인지 툴팁으로 알려 줍니다. 접근성 이름은 트리거에도 따로 줍니다.

</Card>
<Card demo="tooltip/dont-repeat" tone="dont" eyebrow="이렇게 하지 마세요">

이미 '저장'이라고 쓴 버튼에 '저장' 툴팁을 또 붙이지 않습니다. 단축키처럼 새 정보가 있을 때만 붙입니다.

</Card>
<Card demo="tooltip/do-short" tone="do" eyebrow="이렇게 하세요" height="240">

짧고 분명하게, 1~2줄 안에 씁니다.

</Card>
<Card demo="tooltip/dont-long" tone="dont" eyebrow="이렇게 하지 마세요" height="240">

긴 설명은 포인터를 트리거에 계속 둔 채 읽어야 하고, 벗어나면 곧 사라집니다. HoverCard나 화면의 글로 옮깁니다.

</Card>
<Card demo="tooltip/do-visible-text" tone="do" eyebrow="이렇게 하세요">

입력 규칙처럼 꼭 알아야 하는 안내는 화면에 늘 보이게 둡니다.

</Card>
<Card demo="tooltip/dont-hidden-rule" tone="dont" eyebrow="이렇게 하지 마세요">

필수 안내를 툴팁에만 두지 않습니다. 키보드나 터치만 쓰는 사용자는 놓칠 수 있습니다.

</Card>
<Card demo="tooltip/dont-interactive" tone="dont" eyebrow="이렇게 하지 마세요">

버튼이나 링크처럼 누를 것을 넣지 않습니다. 포인터가 트리거를 벗어나면 닫히고, 웹에서는 말풍선 안의 것을 누를 수 없습니다.

</Card>
<Card tone="do" eyebrow="이렇게 하세요" title="조작할 것은 Popover에" href="/components/popover" more="Popover 보기">

말풍선 안에서 무엇인가를 눌러야 한다면 누르면 열리는 `Popover`를 씁니다.

</Card>
</Cards>

### 조합 예제

도구 모음의 아이콘 버튼마다 하나씩 감쌉니다. 버튼의 접근성 이름은 따로 줍니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Tooltip(
      message: '실행 취소 (Ctrl+Z)',
      child: Semantics(
        label: '실행 취소',
        child: Button(
          variant: CoreButtonVariant.ghost,
          shape: CoreButtonShape.square,
          onPressed: handleUndo,
          child: Icon(LucideIcons.undo2),
        ),
      ),
    ),
    Tooltip(
      message: '다시 실행 (Ctrl+Y)',
      child: Semantics(
        label: '다시 실행',
        child: Button(
          variant: CoreButtonVariant.ghost,
          shape: CoreButtonShape.square,
          onPressed: handleRedo,
          child: Icon(LucideIcons.redo2),
        ),
      ),
    ),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(
  [
    Tooltip(
      message: '실행 취소 (Ctrl+Z)',
      child: Button(
        variant: CoreButtonVariant.ghost,
        shape: CoreButtonShape.square,
        attributes: {'aria-label': '실행 취소'},
        onPressed: handleUndo,
        child: Icon(LucideIcons.undo2),
      ),
    ),
    Tooltip(
      message: '다시 실행 (Ctrl+Y)',
      child: Button(
        variant: CoreButtonVariant.ghost,
        shape: CoreButtonShape.square,
        attributes: {'aria-label': '다시 실행'},
        onPressed: handleRedo,
        child: Icon(LucideIcons.redo2),
      ),
    ),
  ],
  classes: 'flex items-center',
)
```

  </TabItem>
</Tabs>

## 배치

### 위치

`position`은 말풍선이 놓일 쪽을 `top`(기본) · `bottom` · `left` · `right` 중에서 고릅니다. 말풍선은 그 변의 가운데에 맞춰 놓입니다.

<Cards columns="2">
<Card component="tooltip" props="position=top" title="top (기본)">

트리거 위에 놓입니다.

</Card>
<Card component="tooltip" props="position=bottom" title="bottom">

트리거 아래에 놓입니다.

</Card>
<Card component="tooltip" props="position=left" title="left">

트리거 왼쪽에 놓입니다.

</Card>
<Card component="tooltip" props="position=right" title="right">

트리거 오른쪽에 놓입니다.

</Card>
</Cards>

```dart
Tooltip(
  message: '설정 메뉴',
  position: CoreTooltipPosition.right,
  child: Icon(LucideIcons.settings),
)
```

### 화면 가장자리와 스크롤

- 고른 쪽에 자리가 모자라면 반대쪽으로 넘깁니다. 양쪽 다 모자라면 Flutter는 넘긴 뒤 화면 안으로 밀어 넣어 트리거를 덮을 수 있고, 웹은 덜 넘치는 쪽에 둡니다.
- 옆으로 삐져나가면(`top` · `bottom`은 좌우, `left` · `right`는 위아래) 화면 안으로 밀어 넣습니다. 꼬리는 넘어간 쪽을 따라갑니다.
- 가장자리에서 띄우는 거리는 다릅니다. 기본값에서 말풍선 기준으로 Flutter는 16(여백 8 + `placementOffset` 8), 웹은 8입니다. Flutter는 화면 키보드가 가린 영역도 피합니다.
- 화면이 접힘으로 나뉘어 있으면 말풍선은 트리거의 가운데가 놓인 조각 안에 머뭅니다. 어디까지 되는지는 [레이아웃](/guides/layout)의 "접히는 화면"을 보세요.
- Flutter는 열 때 한 번 자리를 잡습니다. 열린 동안 스크롤로 트리거가 움직여도 말풍선은 따라가지 않습니다. 웹은 스크롤하거나 말풍선 크기가 바뀌면 다시 놓습니다. 창 크기 변화는 따로 듣지 않습니다.

<a id="web-구현"></a>

### 오버레이에 그리기

- **Flutter** — 루트 `Overlay`에 올립니다. 조상의 `ClipRect`나 `Transform`에 잘리지 않고, 테마는 트리거 자리의 것을 가져갑니다.
- **Web** — `CoUIWeb`의 오버레이 호스트 툴팁 층에 그리고 브라우저의 top layer로 올립니다. 조상의 `overflow: hidden`이나 `transform`에 잘리지 않으며, `BrightnessScope` · `TypographyTierScope` 범위도 말풍선에 이어집니다. 오버레이 호스트가 없는 트리에서는 트리거 옆의 DOM에 그리므로 조상의 `transform`에 갇힐 수 있습니다.
- **레이아웃** — Flutter에서는 감싸도 트리거의 레이아웃이 그대로입니다. 웹은 트리거를 바깥 `<div>`와 안쪽 `inline-flex` `<div>`로 감싸므로, 감싼 버튼은 부모 폭을 채우지 않고 자기 폭으로 남습니다. `id` · `classes` · `css` · `attributes`는 바깥 `<div>`에 붙습니다.

<a id="스타일-시스템-tooltipstyle"></a>
<a id="스타일-시스템-style-system"></a>
<a id="tooltipstyle-슬롯"></a>

## 테마와 스타일

말풍선의 겉모습과 꼬리, 폭, 트리거와의 거리, 라벨 글자는 모두 `tooltipStyle`(`CoreTooltipStyle`) 하나로 바꿉니다. 말풍선이 놓일 쪽(`position`)과 타이밍은 위젯 파라미터로 줍니다. 두 플랫폼이 같은 코드를 씁니다.

<Split>

<Code language="dart" title="툴팁 하나만 바꾸기">
Tooltip(
  message: '도움말',
  tooltipStyle: CoreTooltipStyle(
    panelBackgroundColor: CoreColor.token(
      CoreColors.inverseSurface,
    ),
    panelBorderRadius: CoreBorderRadius.all(
      CoreRadius.radius6,
    ),
    panelPadding: CoreEdgeInsets.all(CoreSpace.space8),
    labelStyle: CoreTextStyle.token(
      CoreTextStyles.bodySmall,
      color: CoreColor.token(CoreColors.inverseOnSurface),
    ),
  ),
  child: Icon(LucideIcons.info),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    tooltip: CoreTooltipTheme(
      style: CoreTooltipStyle(
        tailWidth: CoreSpace.space12,
        tailHeight: CoreSpace.space6,
      ),
    ),
  ),
)
</Code>

</Split>

<a id="surface-효과"></a>

### 서페이스 효과

뒤를 흐리는 정도(`surfaceBlur`)와 말풍선 바탕의 불투명도(`surfaceOpacity`)도 `tooltipStyle`로 줍니다. 비우면 켜 둔 서페이스 스타일의 재질을 따릅니다. 불투명도는 바탕에만 적용되고 글자는 흐려지지 않습니다.

기본 서페이스 스타일에서 바탕색이 불투명하면 `surfaceOpacity`는 두 플랫폼에서 같게 보입니다. Flutter는 `surfaceOpacity`로 바탕색의 알파를 바꾸고 웹은 알파에 곱하므로, 반투명한 `panelBackgroundColor`를 주면 결과가 다릅니다. `liquidGlass`처럼 떠 있는 판을 비치게 그리는 서페이스 스타일에서는 웹이 `surfaceOpacity` 대신 스타일이 정한 비침 정도로 바탕을 그릴 수 있습니다. 웹은 `surfaceBlur`의 소수점 아래를 버립니다.

```dart
Tooltip(
  message: '흐림 효과',
  tooltipStyle: CoreTooltipStyle(
    surfaceBlur: 10,
    surfaceOpacity: 0.8,
  ),
  child: target,
)
```

### 빠른 오버라이드 (Chain)

이미 만든 `Tooltip`에 스타일을 덧붙일 때는 `withStyle`을 이어 씁니다. `tooltipStyle`에 주는 것과 같고, 여러 번 이으면 뒤의 값이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class TooltipChainExample extends StatelessWidget {
  const TooltipChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '링크 복사',
      position: CoreTooltipPosition.bottom,
      child: Button(
        variant: CoreButtonVariant.outline,
        onPressed: () {},
        child: const Text('공유'),
      ),
    ).withStyle(
      const CoreTooltipStyle(
        panelBackgroundColor: CoreColor.token(CoreColors.primary),
        panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        panelPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space16,
          vertical: CoreSpace.space8,
        ),
        labelStyle: CoreTextStyle.token(
          CoreTextStyles.bodySmall,
          color: CoreColor.token(CoreColors.onPrimary),
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class TooltipChainExample extends StatelessComponent {
  const TooltipChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Tooltip(
      message: '링크 복사',
      position: CoreTooltipPosition.bottom,
      child: Button(
        variant: CoreButtonVariant.outline,
        onPressed: () {},
        child: Text('공유'),
      ),
    ).withStyle(
      const CoreTooltipStyle(
        panelBackgroundColor: CoreColor.token(CoreColors.primary),
        panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        panelPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space16,
          vertical: CoreSpace.space8,
        ),
        labelStyle: CoreTextStyle.token(
          CoreTextStyles.bodySmall,
          color: CoreColor.token(CoreColors.onPrimary),
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

```text
CoreTooltipStyle 기본값        // 디자인 시스템
  → CoreTooltipTheme.style      // 앱 전체
  → tooltipStyle                // 툴팁 하나
```

뒤로 갈수록 우선합니다. 필드마다 따로 합쳐지고, `labelStyle`도 그 안의 필드끼리 합쳐집니다. 리치 에디터처럼 안에서 툴팁을 쓰는 컴포넌트는 자기 스타일의 `tooltipStyle`을 이 `tooltipStyle` 자리로 넘깁니다. `surfaceBlur` · `surfaceOpacity`를 아무 데서도 정하지 않으면 서페이스 스타일의 값이 쓰입니다.

<a id="접근성-accessibility"></a>

## 접근성

툴팁은 덧붙이는 설명입니다. 트리거의 접근 가능한 이름은 트리거에 따로 주세요.

### 역할

| 플랫폼 | 트리거 | 말풍선 |
| --- | --- | --- |
| Flutter | `Semantics(container: true, tooltip: message)`로 `message`를 트리거의 시맨틱 툴팁 문구로 붙입니다. `tooltipChild`를 주거나 `message`가 비어 있으면 붙이지 않습니다. | 툴팁 역할의 노드는 따로 없습니다. 열려 있는 동안 말풍선의 글자는 보통 글자로 접근성 트리에 놓입니다. |
| Jaspr Web | 역할도 `aria-*`도 붙이지 않습니다. | 열려 있는 동안에만 DOM에 있는 `<div role="tooltip">` |

### 키보드

툴팁이 처리하는 키는 없습니다.

| 키 · 동작 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab`으로 이동 | `Tooltip` 자체는 포커스 대상이 아닙니다. `child`의 포커스는 그대로입니다. | 트리거를 감싼 `<div>`에 `tabindex`가 없습니다. `child`의 포커스는 그대로입니다. |
| 포커스로 열기 | 없음 | 없음 |
| `Escape`로 닫기 | 없음 | 없음 |

`child`가 `Button`처럼 포커스를 받는 위젯이어도 포커스만으로는 열리지 않습니다.

### 스크린 리더

- **Flutter** — `message`는 말풍선을 열지 않아도 트리거의 툴팁 문구로 전해집니다. 읽는 방식은 플랫폼의 보조 기술이 정합니다. `tooltipChild`를 쓰면 이 문구가 없습니다.
- **Web** — 말풍선은 `aria-describedby`로 트리거와 이어지지 않아, 트리거를 읽을 때 함께 읽히지 않습니다. `CoUIWeb`의 오버레이 호스트가 있으면 말풍선은 DOM에서 트리거 옆이 아니라 앱 내용 뒤의 툴팁 층에 놓이므로, 읽는 순서로도 트리거 바로 다음에 오지 않을 수 있습니다.
- 두 플랫폼 모두 말풍선이 열린 것을 따로 알리지 않습니다.

### 포커스 관리

- 열릴 때 포커스를 말풍선으로 옮기지 않습니다.
- 옮기지 않으므로 닫을 때 되돌리는 것도 없습니다.
- 포커스를 가두지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 키보드만 쓰는 사용자는 툴팁을 열 수 없습니다. 꼭 필요한 안내는 화면에 늘 보이게 두거나 트리거의 이름에 담으세요. |
| 공통 | `Escape`로 닫을 수 없습니다. 포인터를 말풍선으로 옮기면 트리거를 벗어난 것으로 보고 닫으므로, WCAG 1.4.13이 호버로 뜨는 내용에 요구하는 '포인터를 올려 둘 수 있어야 한다'를 충족하지 않습니다. |
| 공통 | 툴팁만으로는 트리거의 이름이 되지 않습니다. 아이콘만 있는 트리거에는 이름을 따로 주세요 — Flutter는 `Semantics(label:)`, 웹은 버튼의 `attributes`에 `aria-label`입니다. |
| Flutter | 터치로는 열 수 없습니다. 마우스처럼 올려 둘 수 있는 포인터에서만 열립니다. |
| Flutter | `tooltipChild` 안의 색을 주지 않은 `Icon`과 글자 역할 체인(`.bodySmall` 등) 글은 바탕과 같은 `onSurface`로 그려져 보이지 않을 수 있습니다. 리치 툴팁의 방법을 쓰세요. |
| Flutter | 열린 동안 바꾼 `message` · `tooltipChild` · `tooltipStyle`은 다음에 열 때 반영됩니다. |
| Jaspr Web | 터치를 위한 처리가 없습니다. 모바일 브라우저가 탭할 때 마우스 이벤트를 흉내 내어 열릴 수는 있지만 정해진 동작이 아닙니다. |
| Jaspr Web | `Tooltip`이 열리면 열려 있던 `DropdownMenu` · `ContextMenu`가 닫힐 수 있습니다. `Popover`처럼 열린 다른 앵커 패널은 그대로 있지만 스크롤을 따라 움직이지 않게 될 수 있습니다. |
| Jaspr Web | 말풍선이 덮은 자리의 버튼이나 링크는 말풍선이 떠 있는 동안 눌리지 않을 수 있습니다. |
| Jaspr Web | 말풍선이 전환 없이 바로 나타나거나 사라질 수 있습니다. |
| Jaspr Web | 동작 줄이기를 켜도 말풍선에 설정한 전환 시간은 줄지 않습니다. |
| Jaspr Web | `liquidGlass`처럼 바탕을 비치게 하는 서페이스 스타일에서는 `surfaceOpacity`를 주어도 스타일의 비침 정도로 그려질 수 있습니다. 이 스타일에서 `surfaceBlur`를 주면 스타일의 채도 · 밝기 보정이 빠질 수 있습니다. |

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타깃)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

파라미터 이름은 같고, 아래 동작이 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 슬롯 타입 | `Widget` | `Component` |
| 여는 입력 | `MouseRegion`(마우스 · 올려 둘 수 있는 펜) | `mouseenter` · `mouseleave` |
| 누름 | 말풍선 밖(트리거 포함)을 누르면 닫습니다 | 닫지 않습니다 |
| 말풍선 위의 누름 | 말풍선이 받아 아래 요소에 닿지 않습니다 | 말풍선에는 `pointer-events: none`이 있지만 감싼 상자에는 없어, 아래 요소에 닿지 않을 수 있습니다 |
| 사라지는 동안 다시 올리기 | `waitDuration` 뒤에 새로 엽니다 | 바로 다시 나타납니다 |
| 타이밍에 `null` | `CoreHoverTheme`의 값, 없으면 `Hover` 기본값(대기 500ms · 머무름 200ms · 최소 0ms) | `CoreTooltipContract`의 기본값(대기 · 머무름 150ms · 최소 0ms) |
| 동작 줄이기 | 500ms 이하의 대기 · 머무름 · 최소 시간이 0 | 타이밍과 전환 시간 모두 그대로 |
| 긴 글 | 화면 폭에서 줄바꿈 | 한 줄 |
| `message`의 `\n` | 줄을 나눕니다 | 공백으로 보입니다 |
| `tooltipChild`의 색 | 라벨 글자 스타일은 이어받지만, 색 없는 `Icon`과 글자 역할 체인은 `onSurface` | 말풍선의 글자색을 이어받습니다 |
| 열린 동안 값 바꾸기 | 다음에 열 때 반영 | 내용 · 겉모습은 바로, `position` · `placementOffset`은 다음에 |
| 스크롤 | 따라가지 않습니다 | 다시 놓습니다 |
| 화면 가장자리에서의 거리(기본값) | 16 | 8 |
| 양쪽 다 자리가 모자랄 때 | 반대쪽으로 넘긴 뒤 화면 안으로 밀어 넣어 트리거를 덮을 수 있습니다 | 덜 넘치는 쪽에 둡니다 |
| 커지는 기준점 | 트리거를 향한 변 | 말풍선 가운데(전환이 보이지 않을 수 있습니다) |
| 반투명한 바탕에 `surfaceOpacity` | 바탕색의 알파를 바꿉니다 | 알파에 곱합니다 |
| 유리 스타일의 `surfaceOpacity` | 준 값을 씁니다 | 스타일의 비침 정도로 그릴 수 있습니다 |
| 소수점이 있는 `surfaceBlur` | 그대로 씁니다 | 소수점 아래를 버립니다 |
| 유리 스타일의 전환 | 재질을 줄이며 나타나고 사라집니다 | 말풍선의 불투명도를 바꾸게 되어 있습니다 |
| 오버레이 | 루트 `Overlay` | 오버레이 호스트의 툴팁 층 + top layer |
| 감싼 트리거의 레이아웃 | 그대로 | 바깥 `<div>` + `inline-flex` `<div>` |

<a id="props-parameters"></a>

## API

### 위젯 파라미터

웹의 `Widget` 자리는 `Component`입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `Widget` | 필수 | 안내를 붙일 트리거 |
| `message` | `String` | `''` | 안내 글. Flutter에서는 트리거의 시맨틱 툴팁 문구로도 씁니다. |
| `tooltipChild` | `Widget?` | `null` | `message` 대신 말풍선에 그릴 위젯 |
| `position` | `CoreTooltipPosition` | `CoreTooltipPosition.top` | 말풍선이 놓일 쪽 — `top` · `bottom` · `left` · `right` |
| `waitDuration` | `Duration?` | `CoreTooltipContract.defaultWaitDuration`(150ms) | 열리기 전에 기다리는 시간. `null`은 타이밍을 보세요. |
| `showDuration` | `Duration?` | `CoreTooltipContract.defaultShowDuration`(150ms) | 벗어난 뒤 머무는 시간. `null`은 타이밍을 보세요. |
| `minDuration` | `Duration?` | `null`(0ms) | 포인터가 올라온 때부터의 최소 시간 |
| `tooltipStyle` | `CoreTooltipStyle?` | `null` | 말풍선의 겉모습과 라벨 글자 덮어쓰기 |

웹은 여기에 `id` · `classes` · `css` · `attributes`와 이벤트 처리기를 더 받으며, 모두 트리거를 감싼 바깥 `<div>`에 붙습니다. 말풍선에는 붙지 않습니다. 두 플랫폼 모두 `copyWith`와 `withStyle(CoreTooltipStyle patch)`로 값을 바꾼 복사본을 만듭니다.

### 테마 — `CoreTooltipTheme`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CoreTooltipStyle?` | `null` | 앱의 모든 툴팁에 깔리는 값. Tooltip에는 variant가 없어 variant별 값은 없습니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreTooltipStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `panelBackgroundColor` | `CoreColor?` | Panel background fill colour override. |
| `panelBorderRadius` | `CoreBorderRadius?` | Panel border radius override. |
| `panelMaxWidth` | `double?` | Maximum panel width (logical px) override — the ceiling the bubble grows to before its content wraps onto another line. Setting it makes the bubble wrap on both platforms: Flutter constrains the bubble, Web drops the single-line `white-space: nowrap` it otherwise carries. `null` leaves the panel unconstrained, and has no paired `default*` on purpose — a shared ceiling would silently re-wrap every existing tooltip. |
| `panelPadding` | `CoreEdgeInsets?` | Panel content padding override. |
| `placementOffset` | `double?` | Overlay placement offset (logical px) override — how far the floating panel sits from its trigger anchor along the placement axis (not content padding, not axis spacing). |
| `tailWidth` | `double?` | Tail base width override — the triangle edge flush against the panel side. `0` removes the tail. |
| `tailHeight` | `double?` | Tail protrusion height override — how far the tip extends beyond the panel edge toward the trigger. `0` removes the tail. |
| `surfaceBlur` | `double?` | Backdrop blur sigma applied behind the panel. |
| `surfaceOpacity` | `double?` | Panel surface opacity multiplier (0.0 – 1.0). |
| `labelStyle` | `CoreTextStyle?` | Label text style override (applied when the contract's `message` string is rendered). Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `panelForegroundColor` field removed). |

<!-- STYLE_TABLE:END -->

<Note>

- `panelMaxWidth`를 비워 두면 웹은 한 줄로 두지만, Flutter는 화면 폭에 닿으면 줄을 바꿉니다.
- `surfaceBlur` · `surfaceOpacity`를 비우면 서페이스 스타일의 값을 씁니다. Flutter는 `surfaceOpacity`를 바탕색의 알파에 곱하지 않고 그 알파를 바꿉니다. `liquidGlass`처럼 바탕을 비치게 하는 서페이스 스타일에서는 웹이 `surfaceOpacity` 대신 스타일의 비침 정도로 바탕을 그릴 수 있습니다.
- `labelStyle`은 `message`뿐 아니라 `tooltipChild`의 기본 글자 스타일로도 쓰입니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="HoverCard" href="/components/hover-card" more="HoverCard 보기">

이미지와 버튼까지 담는 호버 미리보기입니다.

</Card>
<Card title="Popover" href="/components/popover" more="Popover 보기">

누르면 열리고 그 안에서 조작하는 앵커 패널입니다.

</Card>
<Card title="Toast" href="/components/toast" more="Toast 보기">

행동의 결과를 알리는 알림입니다.

</Card>
</Cards>
