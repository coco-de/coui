---
title: Indicator
description: 다른 요소의 모서리나 가장자리에 배지 · 상태 점 같은 작은 항목 하나를 겹쳐 놓습니다.
category: display
platforms: [flutter, web]
related: [badge, avatar, status, dot-indicator]
tags: [overlay, badge, corner, status]
template: v2
source: display/indicator
---

# Indicator

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

위치 · 간격 · 둘레 두께를 바꿔 보며 Indicator 를 확인하고, 만들어진 코드를 복사하세요. `Indicator` 는 `child` 를 감싸고 그 위에 `item` 하나를 겹쳐 놓습니다. 위치를 주지 않으면 오른쪽 위(`end` · `top`)입니다.

<Playground component="indicator" />

`item 내용` 과 `child 내용` 은 두 슬롯에 무엇을 넣을지 고르는 문서용 선택지입니다. 코드의 `openInbox` 는 앱에서 정하는 함수입니다. 플레이그라운드의 위치는 모서리 네 자리이고, `center` · `middle` 은 [위치](#위치) 섹션에서 다룹니다.

## 구조

Indicator 에는 본체인 `child` 와 그 위에 겹치는 `item`, 두 슬롯이 있습니다. 둘 다 반드시 넘깁니다.

<Anatomy demo="indicator/anatomy">
<AnatomyItem part="container" name="Indicator">

`child` 를 감싸는 바깥 상자입니다. `item` 의 위치는 이 상자의 가장자리를 기준으로 잽니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=child]" side="top" name="child">

본체입니다. 아바타 · 버튼 · 아이콘 · 카드처럼 어떤 위젯(Web 은 컴포넌트)이든 넣습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=item]" side="right" name="item">

겹쳐 놓는 항목 하나입니다. 배지나 상태 점을 넣습니다. 기본으로 바깥에 둘레가 그려집니다.

</AnatomyItem>
</Anatomy>

기준은 `child` 의 모양이 아니라 사각형 상자입니다. 원형 아바타에서는 상자 모서리가 원 바깥에 있어, `item` 의 일부가 원 밖에 놓입니다. 원 안쪽으로 더 겹치게 하려면 `offset` 에 양수를 줍니다.

<a id="동작-스펙-behavior"></a>

## 둘레

`item` 바깥에는 둘레가 그려집니다. 기본은 두께 2, 색 `surface`, 알약 모양이며, `item` 이 `child` 에서 오려 낸 것처럼 보이게 합니다.

<Preview demo="indicator/ring" />

- 모서리 네 자리에서 `offset` 이 0이면 `item` 의 모서리가 Indicator 상자의 모서리와 만나고, 둘레는 그 바깥으로 튀어나옵니다. `end` · `top` 이면 `item` 의 오른쪽 위 모서리가 상자의 오른쪽 위 모서리입니다. 이 네 자리에서는 둘레를 두껍게 하거나 없애도 `item` 이 움직이지 않습니다.
- `ringWidth: CoreStrokeWidth.stroke0` 이면 둘레를 그리지 않습니다.
- 기본 색이 `surface` 이므로, 다른 색 바탕 위에 놓을 때는 `ringColor` 를 그 바탕색으로 맞춥니다.
- 둘레의 모서리는 `ringBorderRadius` 로 정합니다. 기본은 `CoreRadius.radius9999`(알약)입니다. 낱말을 담은 `label` 형태의 Badge 처럼 모서리가 덜 둥근 `item` 에는 그 모양에 가까운 값을 줍니다.

```dart
// Flutter · Web 같은 코드
Indicator(
  indicatorStyle: CoreIndicatorStyle(
    ringColor: CoreColor.token(CoreColors.surfaceContainer),
    ringBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
  ),
  item: Badge(size: CoreComponentSize.xs, child: Text('신규')),
  child: Avatar(initials: 'KS', size: CoreComponentSize.xl),
)
```

두 플랫폼은 둘레를 칠하는 방법이 다릅니다. `item` 에 비어 있는 부분이 있거나 `ringBorderRadius` 에 알약보다 작은 값을 주면 결과가 달라지므로 [플랫폼 차이](#플랫폼-차이)를 확인하세요.

<a id="변형-variants"></a>

## 위치

`horizontalPosition`(`start` · `center` · `end`)과 `verticalPosition`(`top` · `middle` · `bottom`)을 조합합니다. 아래 그림은 모서리 네 자리입니다.

<Preview demo="indicator/positions" />

<a id="위치-조합-position-matrix"></a>

| 세로 \ 가로 | `start` | `center` | `end` |
| --- | --- | --- | --- |
| `top` | 왼쪽 위 | 위쪽 가운데 | 오른쪽 위 (기본) |
| `middle` | 왼쪽 가운데 | 정중앙 | 오른쪽 가운데 |
| `bottom` | 왼쪽 아래 | 아래쪽 가운데 | 오른쪽 아래 |

`start` 는 왼쪽, `end` 는 오른쪽입니다. 글을 오른쪽에서 왼쪽으로 읽는 방향에서도 두 플랫폼 모두 좌우가 뒤집히지 않습니다.

<Note>

위 표는 Web 에서 놓이는 자리입니다. **Flutter 는 지금 `center` · `middle` 에서 `item` 을 `child` 의 가운데에 맞추지 못합니다.** 모서리 네 자리는 두 플랫폼이 같습니다.

| 조합 | Flutter 에서 놓이는 자리 |
| --- | --- |
| `center` 와 `top` · `bottom` | 가로 가운데가 아니라 왼쪽 가장자리입니다. 오른쪽에서 왼쪽으로 읽는 방향에서는 오른쪽 가장자리입니다. |
| `start` · `end` 와 `middle` | 세로 가운데가 아니라 위쪽입니다. |
| `center` 와 `middle` | 부모가 폭 · 높이의 한도를 정한 방향으로는 Indicator 상자가 그 한도까지 늘어나고, `item` 은 늘어난 길이의 가운데에 놓입니다. 한도가 없는 방향(스크롤하는 방향 등)에서는 시작 쪽에 놓입니다. `child` 는 상자의 위쪽 시작 모서리(왼쪽에서 읽는 방향이면 왼쪽 위)에 남습니다. |

`center` 와 `middle` 을 함께 쓸 때는 Indicator 를 `child` 와 같은 크기의 `SizedBox` 로 감싸면 `item` 이 `child` 가운데에 놓입니다. 한쪽 방향만 가운데인 조합은 감싸도 위 표의 자리 그대로입니다.

</Note>

<a id="default"></a>

### 오른쪽 위 — 개수 배지

위치를 주지 않은 기본 자리입니다. 읽지 않은 개수처럼 `child` 에 딸린 수를 얹습니다.

```dart
// Flutter · Web 같은 코드
Indicator(
  item: Badge(
    tone: CoreBadgeTone.destructive,
    variant: CoreBadgeVariant.filled,
    form: CoreBadgeForm.count,
    size: CoreComponentSize.xs,
    child: Text('99+'),
  ),
  child: Avatar(initials: 'C'),
)
```

<a id="bottom-start"></a>

### 왼쪽 아래

두 위치를 함께 바꿉니다. 첫 예제는 짧은 라벨을, 둘째 예제는 `offset` 4 만큼 안쪽으로 당긴 상태 점을 놓습니다.

```dart
// Flutter · Web 같은 코드
Indicator(
  horizontalPosition: CoreIndicatorHorizontalPosition.start,
  verticalPosition: CoreIndicatorVerticalPosition.bottom,
  item: Badge(size: CoreComponentSize.xs, child: Text('신규')),
  child: Avatar(initials: 'C', size: CoreComponentSize.xl),
)

Indicator(
  horizontalPosition: CoreIndicatorHorizontalPosition.start,
  verticalPosition: CoreIndicatorVerticalPosition.bottom,
  indicatorStyle: CoreIndicatorStyle(offset: CoreSpace.space4),
  item: Status(),
  child: Icon(LucideIcons.bell),
)
```

### 가장자리에서의 거리

`offset` 은 고른 가장자리에서 **`item` 의 가장자리**까지의 거리입니다. 둘레의 바깥선이 아닙니다. 기본은 0이고, 양수는 `child` 안쪽으로, 음수는 바깥쪽으로 옮깁니다. 가운데로 맞추는 방향(`center` · `middle`)에는 쓰이지 않습니다.

<Preview demo="indicator/offset" />

Flutter 는 이 값에 테마의 `scaling` 을 곱한 논리 픽셀을 쓰고, Web 은 16으로 나눈 `rem` 을 씁니다(`offset: 4` 는 `0.25rem`).

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

다음처럼 다른 요소에 **딸린 정보 하나**를 그 모서리에 붙일 때 씁니다.

- 버튼이나 아이콘의 모서리에 읽지 않은 개수 · 알림 점을 얹을 때
- 아바타 모서리에 읽지 않은 개수를 얹을 때
- 카드나 이미지 모서리에 "신규" 같은 짧은 라벨을 얹을 때

| 상황 | 대신 쓸 것 |
| --- | --- |
| 상태나 개수를 글줄 · 목록 행에 나란히 보일 때 | [Badge](/components/badge) |
| 아바타에 접속 상태 점을 붙일 때 | [Avatar](/components/avatar)의 `badge` 슬롯과 `AvatarBadge`. 원형 아바타에서는 점의 중심이 원의 테두리 위에 놓입니다. |
| 하단 바 같은 내비게이션 항목의 아이콘에 배지나 알림 점을 붙일 때 | `NavigationBarItem` 의 `badge` · `showDot` |
| 여러 쪽 가운데 지금 위치를 점 여러 개로 보일 때 | [DotIndicator](/components/dot-indicator) |

<a id="do"></a>
<a id="dont"></a>

<Cards columns="2">
<Card demo="indicator/do-count" tone="do" eyebrow="이렇게 하세요" title="짧은 항목 하나">

숫자나 점처럼 작은 항목 하나를 얹어 `child` 를 알아볼 수 있게 둡니다.

</Card>
<Card demo="indicator/dont-long" tone="dont" eyebrow="이렇게 하지 마세요" title="긴 문장 얹기">

긴 글은 `child` 를 가리거나 밖으로 뻗습니다. 문장은 `child` 옆이나 아래에 둡니다.

</Card>
<Card demo="indicator/do-dots" tone="do" eyebrow="이렇게 하세요" title="점 목록은 DotIndicator">

전체 개수와 지금 위치를 `length` 와 `index` 로 넘깁니다.

</Card>
<Card demo="indicator/dont-list" tone="dont" eyebrow="이렇게 하지 마세요" title="Indicator 로 점 늘어놓기">

Indicator 는 `child` 하나에 `item` 하나를 놓습니다. 점을 늘어놓으려고 빈 `child` 를 반복해서 감싸지 않습니다.

</Card>
</Cards>

### item 에 뜻 담기

Indicator 는 자리만 정하고 뜻을 더하지 않습니다. 무엇을 알리는지는 `item` 과 `child` 가 담아야 합니다. 숫자나 점만으로 뜻이 전해지지 않으면 [스크린 리더](#스크린-리더)의 예제처럼 이름을 붙입니다.

## 배치

### 크기와 넘침

`item` 과 둘레는 겹쳐 그려질 뿐 Indicator 의 크기에 들어가지 않습니다. Flutter 에서 `center` 와 `middle` 을 함께 쓰는 경우는 예외입니다([위치](#위치)). 상자 밖으로 나간 부분은 옆 요소와 겹칠 수 있습니다. Indicator 는 이 부분을 자르지 않지만, 바깥의 부모가 넘친 부분을 자르면 함께 잘립니다.

### 부모가 상자를 늘릴 때

세로 배치에서 자식을 가로로 늘리는 경우처럼 부모가 Indicator 상자를 늘리면, `item` 은 `child` 가 아니라 늘어난 상자의 가장자리를 따라갑니다. Flutter 는 이때도 `child` 에게 늘어난 크기를 강제하지 않아 `item` 과 `child` 가 떨어질 수 있습니다. 아래처럼 Indicator 가 `child` 만큼만 차지하게 합니다.

<Tabs groupId="platform">
<TabItem label="Flutter" value="flutter">

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Align(
      alignment: Alignment.centerLeft,
      child: Indicator(
        item: Status(),
        child: Avatar(initials: 'KS'),
      ),
    ),
  ],
)
```

</TabItem>
<TabItem label="Web" value="web">

```dart
// 세로 flex 부모 안에서 가로로 늘어나지 않게 합니다.
Indicator(
  css: Styles(raw: {'align-self': 'flex-start'}),
  item: Status(),
  child: Avatar(initials: 'KS'),
)
```

</TabItem>
</Tabs>

### Web 의 작은 인라인 child

Web 의 바깥 `<div>` 는 `inline-block` 입니다. `child` 가 작은 아이콘처럼 글자와 같은 줄에 놓이는 요소이면, 브라우저의 줄 높이 때문에 이 상자가 `child` 보다 커져 `item` 이 `child` 모서리에서 떨어질 수 있습니다. 그럴 때는 `css` 로 바깥 `<div>` 를 `inline-flex` 로 바꿉니다.

```dart
// Web
Indicator(
  css: Styles(raw: {'display': 'inline-flex'}),
  item: Status(),
  child: Icon(LucideIcons.bell),
)
```

### 누를 수 있는 요소와 함께

- `item` 은 `child` 위에 그려집니다. 배지나 점이 덮은 자리를 누르면 그 누름은 `child` 의 `onPressed` 에 닿지 않습니다. Flutter 는 기본 둘레의 안쪽도 덮은 자리에 들어갑니다.
- Flutter 는 Indicator 상자 밖으로 나간 부분에서 누름을 받지 않습니다. `item` 을 누를 수 있게 만들었다면 음수 `offset` 이나 `child` 보다 큰 `item` 은 피합니다.

### item 이 child 보다 넓을 때

모서리에 놓은 `item` 에 Flutter 는 폭의 한도를 주지 않습니다. 긴 글은 고정된 가장자리의 반대쪽으로 `child` 밖까지 뻗습니다. Web 은 `item` 을 담는 상자의 폭을 브라우저가 정하며, 모서리에서는 `child` 폭에서 `offset` 을 뺀 만큼, 가로 가운데(`center`)에서는 `child` 폭의 절반이 기준입니다. 그래서 줄 바꿈이 되는 `item`(`label` 형태의 Badge 등)은 이 폭보다 길면 여러 줄이 될 수 있습니다. 얹는 글은 짧게 유지합니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

거리와 둘레는 `indicatorStyle`(`CoreIndicatorStyle`) 하나로 바꿉니다. 위치는 스타일에 없으며 생성자의 `horizontalPosition` · `verticalPosition` 으로 정합니다. 필드의 타입은 [API](#api)의 표에 있습니다.

| 필드 | 기본값 |
| --- | --- |
| `offset` | `CoreIndicatorStyle.defaultOffset` — 0 |
| `ringWidth` | `CoreIndicatorStyle.defaultRingWidth` — `CoreStrokeWidth.stroke2` (2) |
| `ringColor` | `CoreIndicatorStyle.defaultRingColor` — `surface` 색 토큰 |
| `ringBorderRadius` | `CoreIndicatorStyle.defaultRingBorderRadius` — `CoreRadius.radius9999` |

### 값이 정해지는 순서

```text
CoreIndicatorStyle 의 기본값
  → CoreComponentTheme.indicator.style   // 앱 전체 (CoreIndicatorTheme)
  → indicatorStyle                       // 인스턴스
```

필드마다 따로 합치고, 아래에 적힌 단계가 위의 값을 이깁니다. 한 필드만 적으면 나머지는 앞 단계의 값을 그대로 씁니다.

- Flutter 는 `offset` · `ringWidth` · `ringBorderRadius` 에 테마의 `scaling` 을 곱하고, 색 토큰은 지금 테마의 색으로 바꿉니다.
- Web 은 `offset` 을 `rem` 으로 바꾸고, 색 · 모서리 토큰은 `--coui-*` CSS 변수로 읽습니다. `ringWidth` 는 0.5 · 1 · 1.5 · 2 · 3 · 4 · 5 · 6 · 8 이면 `--coui-stroke-width-*` 변수를, 그 밖의 양수면 `px` 를 씁니다. 0 이면 둘레에 관한 CSS 를 넣지 않습니다.

### 사용 예

<Split>

<Code language="dart" title="Indicator 하나만 바꾸기">
Indicator(
  indicatorStyle: CoreIndicatorStyle(
    offset: CoreSpace.space2,
    ringWidth: CoreStrokeWidth.stroke1,
  ),
  item: Status(color: CoreStatusColor.success),
  child: Avatar(initials: 'KS'),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    indicator: CoreIndicatorTheme(
      style: CoreIndicatorStyle(ringWidth: CoreStrokeWidth.stroke1),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다. 앱 전체 값은 `NavigationBarItem` 이 아이콘에 `badge` 나 알림 점을 얹을 때 쓰는 Indicator 에도 닿습니다. 다만 그 자리의 `offset` 은 `CoreNavigationBarStyle` 의 `badgeIndicatorStyle` · `notificationDotIndicatorStyle` 이 정하므로 `CoreIndicatorTheme` 의 `offset` 보다 우선합니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

`withStyle` 은 넘긴 `CoreIndicatorStyle` 을 지금의 `indicatorStyle` 에 합친 새 Indicator 를 돌려줍니다. 겹치는 필드는 나중에 이은 값이 이기고, 적지 않은 필드는 남습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class IndicatorChainExample extends StatelessWidget {
  const IndicatorChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Indicator(
      item: const Status(
        color: CoreStatusColor.success,
        size: CoreStatusSize.lg,
      ),
      child: const Avatar(initials: 'C'),
    ).withStyle(
      const CoreIndicatorStyle(offset: CoreSpace.space8),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class IndicatorChainExample extends StatelessComponent {
  const IndicatorChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Indicator(
      item: Status(
        color: CoreStatusColor.success,
        size: CoreStatusSize.lg,
      ),
      child: Avatar(initials: 'C'),
    ).withStyle(
      const CoreIndicatorStyle(offset: CoreSpace.space8),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="접근성-accessibility"></a>

## 접근성

Indicator 는 놓는 자리만 정합니다. 화면을 읽는 도구에 전할 내용은 `child` 와 `item` 이 가집니다.

### 역할

Indicator 는 역할을 더하지 않습니다.

| 플랫폼 | 동작 |
| --- | --- |
| Flutter | `Semantics` 를 붙이지 않습니다. `child` 와 `item` 을 겹쳐 배치하고 둘레를 그릴 뿐입니다. |
| Jaspr Web | 바깥 `<div>` 와 `item` 을 담는 `<div>` 에 스스로 `role` 이나 `aria-*` 를 붙이지 않습니다. `attributes` 로 준 값은 바깥 `<div>` 에 붙습니다. |

### 키보드

Indicator 가 처리하는 키는 없습니다. `onPressed` 같은 콜백이 없고, 스스로 포커스를 받는 자리를 만들지 않습니다. `child` 나 `item` 이 누를 수 있는 컴포넌트면 그 컴포넌트의 키보드 동작을 따릅니다.

Web 의 `eventHandlers` 는 바깥 `<div>` 에 달리며, 안의 `child` · `item` 에서 올라온 이벤트를 받습니다. Web 에서 둘 다 `tabindex` 를 따로 바꾸지 않은 포커스 대상이면 `Tab` 은 문서 순서대로 `child` 다음 `item` 으로 갑니다.

### 스크린 리더

Indicator 에서 나오는 이름은 없습니다. `child` 와 `item` 을 하나의 이름으로 묶는 설정이나, `item` 이 `child` 에 딸린 알림이라는 관계를 더하지 않습니다.

- **순서.** Web 의 문서 순서는 `child` 다음 `item` 입니다. 화면에서는 `item` 이 위에 겹쳐 보여도 문서에서는 뒤에 옵니다. Flutter 의 Indicator 는 읽는 순서를 정하는 값(`sortKey`)을 따로 두지 않습니다.
- **변화.** Indicator 에는 라이브 영역이 없습니다. `item` 의 변화를 알릴지는 `item` 컴포넌트나 화면이 맡습니다. 예를 들어 `Status` 는 Flutter 에서 `semanticLabel` 을 줄 때 라이브 영역이 되고, Web 에서는 `role="status"` 를 가집니다.

#### 숫자만 있는 item 에 이름 붙이기

`3` 이라는 글만으로는 무엇이 세 개인지 알 수 없습니다. `item` 에 뜻을 담은 이름을 붙입니다.

<Tabs groupId="platform">
<TabItem label="Flutter" value="flutter">

```dart
Indicator(
  item: Semantics(
    label: '읽지 않은 알림 3개',
    excludeSemantics: true,
    child: Badge(
      tone: CoreBadgeTone.destructive,
      variant: CoreBadgeVariant.filled,
      form: CoreBadgeForm.count,
      size: CoreComponentSize.xs,
      child: Text('3'),
    ),
  ),
  child: Button(onPressed: openInbox, child: Text('받은 편지함')),
)
```

</TabItem>
<TabItem label="Web" value="web">

```dart
Indicator(
  item: Badge(
    tone: CoreBadgeTone.destructive,
    variant: CoreBadgeVariant.filled,
    form: CoreBadgeForm.count,
    size: CoreComponentSize.xs,
    attributes: {'role': 'img', 'aria-label': '읽지 않은 알림 3개'},
    child: Text('3'),
  ),
  child: Button(onPressed: openInbox, child: Text('받은 편지함')),
)
```

</TabItem>
</Tabs>

#### 장식인 item 숨기기

뜻을 `child` 나 주변 글이 이미 전한다면 `item` 을 접근성 트리에서 뺍니다. Flutter 는 `item` 을 `ExcludeSemantics` 로 감싸고, Web 은 `item` 의 `attributes` 에 `aria-hidden: 'true'` 를 줍니다. `semanticLabel` 이 없는 Flutter 의 `Status` 는 점 자체의 시맨틱을 만들지 않으므로, 보이는 `label` 도 없다면 감쌀 필요가 없습니다.

### 포커스 관리

Indicator 는 포커스를 옮기거나 가두지 않고, 자신은 `Tab` 정지점이 아닙니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | `item` 과 `child` 의 관계를 보조 기술에 알리지 않습니다. 필요한 뜻은 `item` 이나 `child` 의 이름에 직접 담습니다. |
| 공통 | `item` 이 바뀌어도 Indicator 는 알리지 않습니다. |
| 공통 | 배지나 점이 덮은 자리는 `child` 의 누름을 받지 않습니다. 작은 `child` 에 큰 `item` 을 얹으면 `child` 를 누를 수 있는 자리가 줄어듭니다. |
| Flutter | 상자 밖으로 나간 `item` 의 부분은 누를 수 없습니다. |
| Jaspr Web | 둘레는 `box-shadow` 라서 색 강제 모드(`forced-colors`)에서는 그려지지 않습니다. `item` 과 `child` 의 구분을 둘레에만 맡기지 않습니다. |

동작 줄이기 · 고대비 · 최소 터치 타깃처럼 여러 컴포넌트에 걸친 기준은 [접근성](/accessibility) 페이지에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`child` · `item` · `horizontalPosition` · `verticalPosition` · `indicatorStyle` 과 `copyWith` · `withStyle` 은 두 플랫폼이 같은 이름을 씁니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 슬롯 타입 | `Widget` | `Component` |
| 구성 | 넘친 부분을 자르지 않는 `Stacks` 에 `child` 를 두고, `item` 은 `Position` 으로 놓습니다. | `relative inline-block` 인 `<div>` 에 `child` 와, `item` 을 담은 `absolute` `<div>` 를 둡니다. |
| `center` · `middle` | 가운데에 맞지 않습니다([위치](#위치)). | `50%` 지점에 놓고 `translate` 로 당겨 가운데에 맞춥니다. |
| `offset` 단위 | 논리 픽셀 × 테마 `scaling` | `offset / 16` 의 `rem`. 루트 글자 크기를 따라 커지고 작아집니다. |
| 둘레를 칠하는 방법 | `ringColor` 로 칠한 면 위에 `item` 을 `ringWidth` 만큼 안쪽에 놓습니다. 둘레 안쪽 전체가 칠해져, `item` 의 빈 부분에는 `ringColor` 가 보입니다. | `item` 을 담은 상자 바깥에 `box-shadow` 로 띠를 두릅니다. 안쪽은 칠하지 않아, `item` 의 빈 부분에는 뒤의 내용이 보입니다. |
| `ringBorderRadius` 가 닿는 선 | 둘레의 바깥선 | 둘레의 안쪽선(`item` 을 담은 상자). 알약보다 작은 양수를 주면 바깥선은 이 값보다 더 둥글게 그려집니다. |
| 겹치는 순서 | `child` 다음에 `item` 을 그립니다. | `item` 을 담은 상자의 `z-index` 는 1001(`CoreZIndex.z0 + 1`)입니다. 같은 쌓임 맥락에서 이보다 낮은 `z-index` 의 요소(직접 만든 고정 헤더 등)와 겹치면 위에 그려집니다. |
| `item` 의 폭 | 모서리 자리에서는 한도가 없습니다. | 모서리 자리에서는 `child` 폭에서 `offset` 을 뺀 만큼을 기준으로 브라우저가 정합니다. |
| 상자 밖의 누름 | 받지 않습니다. | 밖에 그려진 `item` 도 누를 수 있습니다. |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` 가 바깥 `<div>` 에 적용됩니다. |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. 표의 `W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `W` | 필수 | 감싸는 본체 |
| `item` | `W` | 필수 | `child` 위에 겹쳐 놓는 항목 |
| `horizontalPosition` | `CoreIndicatorHorizontalPosition` | `end` | 가로 자리 — `start` · `center` · `end` |
| `verticalPosition` | `CoreIndicatorVerticalPosition` | `top` | 세로 자리 — `top` · `middle` · `bottom` |
| `indicatorStyle` | `CoreIndicatorStyle?` | `null` | 거리(`offset`)와 둘레의 두께 · 색 · 모서리 덮어쓰기 |

`copyWith` 는 넘긴 값만 바꾼 새 Indicator 를, `withStyle` 은 스타일을 합친 새 Indicator 를 돌려줍니다.

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 바깥 `<div>` 의 id |
| `classes` | `String?` | `null` | 바깥 `<div>` 에 더하는 클래스 |
| `css` | `Styles?` | `null` | 바깥 `<div>` 의 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 바깥 `<div>` 의 HTML 속성 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 바깥 `<div>` 의 이벤트 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreIndicatorStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `offset` | `double?` | Pixel offset override from the chosen edge / corner. Measured from the item's own edge (not the ring's). |
| `ringWidth` | `double?` | Thickness override of the ring around the item (logical px). `0` draws no ring. |
| `ringColor` | `CoreColor?` | Colour override of the ring around the item. |
| `ringBorderRadius` | `CoreBorderRadius?` | Corner radius override of the ring. `null` → [defaultRingBorderRadius]. |

<!-- STYLE_TABLE:END -->

<Note>

인스턴스에서 `ringBorderRadius` 를 비우면 먼저 `CoreIndicatorTheme` 의 값을 쓰고, 그 값도 없을 때 `defaultRingBorderRadius` 를 씁니다. 다른 세 필드도 같은 순서입니다([값이 정해지는 순서](#값이-정해지는-순서)).

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="indicator/related-badge" title="Badge">

상태 · 개수 · 분류를 보이는 작은 라벨입니다. `item` 에 넣어 모서리에 얹습니다.

</Card>
<Card demo="indicator/related-avatar" title="Avatar">

프로필 아바타입니다. 접속 상태 점은 자체 `badge` 슬롯에 넣습니다.

</Card>
<Card demo="indicator/related-status" title="Status">

상태를 색 점으로 보입니다. `item` 으로 얹거나 글과 나란히 씁니다.

</Card>
<Card demo="indicator/related-dot-indicator" title="DotIndicator">

여러 쪽 가운데 지금 위치를 점으로 보입니다.

</Card>
</Cards>
