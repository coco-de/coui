---
title: Timeline
description: 시각 · 제목 · 설명으로 된 사건을 넘긴 순서대로 위에서 아래로 늘어놓고, 점과 세로 연결선으로 잇습니다.
category: display
platforms: [flutter, web]
related: [steps, stepper]
tags: [timeline, history, events, display]
template: v2
source: display/timeline
---

# Timeline

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

`Timeline` 은 이벤트나 활동 내역을 시간 흐름에 따라 보여 줍니다. 사건 하나는 `CoreTimelineItem`(`title` · `description` · `timestamp`)이고, 그 목록을 `items` 로 넘깁니다. 값을 바꿔 보며 확인하고, 만들어진 코드를 복사하세요.

`시각` 을 꺼도 시각 칸의 자리는 남습니다. `항목 수` 를 1로 두면 연결선 없이 점 하나만 남습니다.

<Playground component="timeline" />

```dart
Timeline(
  items: [
    CoreTimelineItem(
      title: '주문 접수',
      timestamp: '오전 10:00',
      description: '주문을 접수했어요.',
    ),
    CoreTimelineItem(
      title: '처리 중',
      timestamp: '오전 11:30',
    ),
    CoreTimelineItem(
      title: '발송 완료',
      timestamp: '오후 2:00',
    ),
  ],
)
```

Flutter와 Web 코드가 같습니다. 방향을 고르는 속성은 없고, 항목은 늘 위에서 아래로 쌓입니다.

## 구조

항목 하나가 한 줄입니다. 왼쪽에서 오른쪽으로 읽을 때 줄은 시각 칸, 점 칸, 내용 칸의 순서로 나뉩니다. 부분을 바꿔 끼우는 위젯 슬롯은 없고, 글은 모두 `CoreTimelineItem` 의 문자열에서 옵니다.

<Anatomy demo="timeline/anatomy">
<AnatomyItem part="container" name="Container">

항목 줄을 `rowSpacing` 간격으로 위에서 아래로 쌓는 상자입니다. 스스로 칠하는 배경과 테두리는 없습니다.

</AnatomyItem>
<AnatomyItem part="label" name="timestamp">

시각 칸의 글입니다. 칸의 폭은 고정이고(기본 120), 글 상자는 칸의 오른쪽에 붙습니다. `bodySmall` 역할과 `onSurfaceVariant` 색입니다.

</AnatomyItem>
<AnatomyItem select="div + div + div > div:first-child" side="top" name="dot">

사건 하나를 표시하는 점입니다. 기본은 지름 10의 `primary` 원입니다.

</AnatomyItem>
<AnatomyItem select="div + div + div > div + div" side="left" name="connector">

다음 항목의 점을 향해 내려가는 선입니다. 기본은 두께 2의 `outlineVariant` 색이고, 마지막 항목에는 없습니다.

</AnatomyItem>
<AnatomyItem select="div + div + div + div + div > div:first-child" side="top" name="title">

사건의 제목입니다. `labelLarge` 역할과 `onSurface` 색입니다.

</AnatomyItem>
<AnatomyItem select="div + div + div + div + div > div + div" side="right" name="description">

선택 사항인 설명입니다. 제목에서 2 아래에 놓이고, `bodySmall` 역할과 `onSurfaceVariant` 색입니다.

</AnatomyItem>
</Anatomy>

<a id="동작-스펙-behavior"></a>

## 연결선과 정렬

사건을 세로로 나열하고, 점(dot)과 세로 연결선으로 시간 흐름을 나타냅니다. 마지막 항목에는 연결선이 없습니다. 설명이 길어 줄이 높아지면 그 줄의 연결선도 함께 길어집니다.

<Preview demo="timeline/connector" />

### 가로 배치

한 줄은 `시각 칸 → 간격 → 점 칸 → 간격 → 내용 칸` 순서입니다. 아래의 길이는 기본값이고, 밀도가 표준이며 배율이 1일 때의 값입니다.

- 시각 칸은 `timeColumnWidth`(120) 폭으로 고정입니다. 글 길이에 맞춰 늘거나 줄지 않아, 모든 줄의 점 칸이 같은 자리에서 시작합니다.
- 두 간격은 `columnGapStyle`(16) 하나로 함께 정합니다.
- 점 칸의 폭은 점 지름(10)이고, 연결선은 점의 가운데를 지납니다.
- 내용 칸은 남은 폭을 모두 씁니다. 줄의 시작에서 162 떨어진 곳에서 시작합니다.

`connectorThickness` 는 `dotSize` 이하로 둡니다. 선이 점보다 두꺼우면 선이 있는 줄만 점 칸이 넓어져, 선이 없는 마지막 줄과 점 · 글의 가로 자리가 어긋납니다.

### 세로 배치

- 시각과 제목은 줄의 위에서 시작합니다.
- 점은 줄 위에서 `dotTopMargin`(5)만큼 내려와, 점의 가운데가 제목 첫 줄의 가운데에 놓입니다.
- 연결선은 자기 점에서 `connectorSpacing`(4) 아래에서 시작해, 다음 점에서 4 위에서 끝납니다. 두 끝이 점을 기준으로 하므로 길이는 줄 높이와 `rowSpacing`(16)을 따라갑니다. 남는 길이가 없으면 선이 보이지 않습니다.

### 점 크기를 바꿀 때

`dotTopMargin` 은 `dotSize` 를 따라 바뀌지 않습니다. 기본값 5는 `(제목 한 줄의 높이 − 점 지름) / 2` 를 정수로 맞춘 값입니다. 점 지름이나 제목 글자 스타일을 바꾸면 `dotTopMargin` 도 함께 바꿉니다. 기본 제목 글자에서 지름 16이면 2가 맞습니다.

<Cards columns="2">
<Card demo="timeline/do-dot-align" tone="do" eyebrow="이렇게 하세요">

`dotSize: CoreSpace.space16` 과 `dotTopMargin: CoreSpace.space2` 를 함께 줍니다.

</Card>
<Card demo="timeline/dont-dot-align" tone="dont" eyebrow="이렇게 하지 마세요">

점만 16으로 키우면 점의 가운데가 제목 첫 줄의 가운데보다 아래로 내려갑니다.

</Card>
</Cards>

Flutter 에서는 `dotTopMargin` 에 음수를 줄 수 없습니다. 음수를 주면 디버그 빌드에서 `Container` 의 assert 에 걸립니다.

## 상태

`Timeline` 은 표시 전용입니다. 항목마다 따로 두는 상태 값이 없습니다. `CoreTimelineItem` 은 문자열 셋만 가지므로 완료 · 진행 · 실패 같은 구분, 항목별 색과 아이콘을 줄 수 없습니다. 눌렀을 때 부르는 콜백도 없어 hover · pressed · 선택 · 비활성 모양이 없고, 불러오는 중 모양도 없습니다.

그리는 모양은 비운 값, 항목 수, 항목의 자리에 따라 달라집니다.

<Preview demo="timeline/states" />

| 상황 | 그리는 것 |
| --- | --- |
| `description` 이 `null` | 설명과 그 위 간격을 그리지 않습니다. 빈 문자열은 설명이 있는 것으로 치므로, 설명이 없으면 `null` 로 둡니다. |
| `timestamp` 가 `null` | 글 없이 시각 칸(기본 120)과 그 뒤 간격이 그대로 남습니다. 점의 가로 자리는 바뀌지 않습니다. |
| 마지막 항목 | 점 아래에 연결선이 없습니다. |
| 항목이 하나 | 점이 하나이고 연결선이 없습니다. |
| 빈 목록 | 점 · 선 · 글을 그리지 않습니다. 빈 상태를 알리는 글은 앱이 대신 보여 줍니다. |

`timelineStyle` 의 값은 모든 항목에 똑같이 적용됩니다. `dotColor` 를 바꾸면 모든 점의 색이 함께 바뀝니다.

모든 항목에 시각이 없는 목록은 `timeColumnWidth: 0` 으로 시각 칸의 폭을 없앨 수 있습니다. 이때도 점 앞의 간격 하나(기본 16)는 남습니다. 시각을 주는 항목이 하나라도 있으면 폭을 0으로 두지 않습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 활동 이력이나 변경 로그를 시간 순서로 나열할 때
- 사건마다 제목, 시각, 자세한 설명이 필요할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 정해진 단계의 완료 · 진행 · 대기 · 실패를 보여 줄 때 | [Steps](/components/steps) |
| 단계를 가로로 늘어놓을 때 | [Steps](/components/steps) 의 `vertical: false` |
| 단계를 눌러 이동하는 다단계 폼을 만들 때 | [Stepper](/components/stepper) |
| 설명 없이 여러 구간의 상태를 이어 보여 줄 때 | [Tracker](/components/tracker) |

### 순서는 앱이 정합니다

`Timeline` 은 `items` 를 넘긴 순서대로 위에서 아래로 그립니다. `timestamp` 문자열을 날짜로 해석하지 않고, 정렬하지 않습니다. 최신 항목을 위에 두려면 앱이 정렬해서 넘깁니다. 날짜와 시각의 표기 형식도 앱이 문자열로 만들어 넘깁니다.

<a id="do"></a>
<a id="dont"></a>

### 항목을 쓰는 법

<Cards columns="2">
<Card demo="timeline/do-optional" tone="do" eyebrow="이렇게 하세요">

덧붙일 설명이 없는 사건은 `description` 을 생략합니다. 그 항목은 제목과 시각만 그리고, 빈 글 자리가 생기지 않습니다.

</Card>
<Card demo="timeline/do-state-text" tone="do" eyebrow="이렇게 하세요">

항목의 상태는 제목과 설명의 글로 말합니다.

</Card>
<Card demo="timeline/dont-state-color" tone="dont" eyebrow="이렇게 하지 마세요">

`dotColor` 로 한 항목의 실패를 나타내려 하지 않습니다. 모든 점이 같은 색이 되어 어느 항목인지 알 수 없습니다.

</Card>
<Card demo="timeline/do-count" tone="do" eyebrow="이렇게 하세요">

항목 수가 중요하면 바깥에 수를 말하는 제목을 두거나 앱에서 요약 라벨을 함께 제공합니다.

</Card>
<Card demo="timeline/dont-count" tone="dont" eyebrow="이렇게 하지 마세요">

항목 수가 중요한 화면에 `Timeline` 만 놓지 않습니다. 목록 시맨틱이 없어 스크린 리더가 항목 수와 몇 번째인지를 알려 주지 못합니다.

</Card>
</Cards>

```dart
// 설명은 생략할 수 있습니다
CoreTimelineItem(title: '처리 중', timestamp: '오전 11:30')
```

"총 5단계 중 3번째" 를 알려야 하는 화면에서 `Timeline(items: orderStatusSteps)` 만으로는 그 정보가 보조 기술에 전달되지 않습니다. 바깥에서 알려 주는 방법은 [스크린 리더](#스크린-리더)를 보세요.

## 배치

### 폭

| 플랫폼 | 폭이 정해지는 방식 |
| --- | --- |
| Flutter | 항목이 있으면 받은 폭을 채웁니다. 항목마다 폭 전체를 쓰는 `Row` 이기 때문입니다. `Row` 안이나 가로 스크롤처럼 폭이 정해지지 않은 자리에서는 레이아웃 오류가 나므로 `Expanded` 나 `SizedBox` 로 폭을 줍니다. |
| Jaspr Web | 블록 부모에서는 폭을 채웁니다. 가로 flex 부모나 가운데 정렬한 세로 flex 부모에서는 내용에 맞춰 폭이 정해집니다. `Timeline` 에 준 `classes` · `css` 는 적용되지 않으므로, 폭을 정할 때는 `div` 로 감쌉니다. |

<Split>

<Code language="dart" title="Flutter — Row 안에서">
Row(
  children: [
    Expanded(child: Timeline(items: historyItems)),
  ],
)
</Code>

<Code language="dart" title="Web — flex 부모 안에서">
div(
  [
    div([Timeline(items: historyItems)], classes: 'w-full'),
  ],
  classes: 'flex',
)
</Code>

</Split>

### 좁은 너비

<Preview demo="timeline/narrow" />

시각 칸, 두 간격, 점 칸은 줄어들지 않습니다. 기본값에서는 `120 + 16 + 10 + 16 = 162` 가 늘 필요하고, 이보다 좁은 자리에서는 두 플랫폼 모두 내용이 밖으로 넘칩니다. 내용 칸이 너무 좁아지는 화면에서는 `timeColumnWidth` 를 줄입니다. 위 장면은 폭 240에 시각 칸 72를 둔 것입니다. `Timeline` 이 화면 폭에 따라 배치를 스스로 바꾸지는 않습니다.

### 긴 글

<Preview demo="timeline/long-text" />

- 제목과 설명은 내용 칸 안에서 줄을 바꿉니다.
- 시각은 시각 칸 안에서 줄을 바꿉니다. 줄이 바뀐 시각의 정렬은 플랫폼마다 다릅니다([플랫폼 차이](#플랫폼-차이)).
- 줄이 높아지면 연결선도 함께 길어집니다.
- 줄 수를 제한하거나 말줄임하는 설정은 없습니다. 줄여야 하는 글은 앱이 줄여서 넘깁니다.
- 칸보다 긴, 띄어쓰기 없는 낱말은 낱말 안에서 줄이 바뀝니다. Web 에서는 `CoUIWeb` 앱 루트가 물려주는 줄 바꿈 설정을 따르므로, 앱 루트 아래에 둘 때의 동작입니다.

### 높이와 스크롤

| 플랫폼 | 높이가 정해지는 방식 |
| --- | --- |
| Flutter | 부모가 높이를 제한하면(`Center`, 높이를 준 `SizedBox`, `Expanded`) 그 높이를 다 차지하고 항목은 위부터 놓입니다. 내용 높이로 두려면 `Column(mainAxisSize: MainAxisSize.min)` 이나 세로 스크롤 안에 둡니다. |
| Jaspr Web | 블록 부모에서는 내용 높이입니다. 높이를 늘려 맞추는 flex · grid 부모에서는 부모의 배치를 따릅니다. |

`Timeline` 은 스스로 스크롤하지 않고, 모든 항목을 한 번에 만듭니다. 긴 이력은 스크롤 영역(Flutter 의 `SingleChildScrollView`, Web 의 `overflow-y` 를 둔 상자)에 넣습니다. 항목이 아주 많으면 앱이 나눠서 넘깁니다.

### 오른쪽에서 왼쪽으로 읽는 언어

읽는 방향이 오른쪽에서 왼쪽이면 줄의 순서가 뒤집혀 시각 칸이 오른쪽에 놓입니다. 시각 칸 안의 정렬 기준은 읽는 방향과 관계없이 오른쪽이라, 한 줄짜리 시각은 점 쪽이 아니라 바깥쪽에 붙습니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

항목 데이터는 위젯 파라미터 `items` 로 넘깁니다. 겉모습(색 · 크기 · 간격)과 글자 스타일은 `timelineStyle`(`CoreTimelineStyle`) 하나로 바꿉니다. 시각 칸의 폭도 겉모습에 속하므로 `timeColumnWidth` 로 정합니다.

<a id="시맨틱-vs-스타일"></a>

### 파라미터와 스타일

- **데이터** — 위젯 파라미터 `items`
- **점** — `timelineStyle` 의 `dotColor`, `dotSize`, `dotCornerRadius`, `dotBorderColor`, `dotBorderWidth`, `dotTopMargin`
- **연결선** — `connectorColor`, `connectorThickness`, `connectorSpacing`
- **폭과 간격** — `timeColumnWidth`, `columnGapStyle`, `rowSpacing`, `titlePadding`, `contentTopGapStyle`
- **글자** — `timestampTextStyle`, `titleTextStyle`, `descriptionTextStyle`

점의 모서리는 `dotCornerRadius` 로 정합니다. 기본값 `9999` 는 원이고, `0` 은 사각형이며, 점 지름의 절반보다 작은 값은 모서리가 둥근 사각형입니다. 점의 테두리는 `dotBorderColor` 와 `dotBorderWidth` 를 둘 다 줄 때만 그립니다. 하나만 주면 테두리가 없습니다.

`titlePadding` 은 제목에만 적용됩니다. 시작 쪽 여백을 주면 제목만 들여지고 설명은 제자리에 남습니다. 기본값은 여백 없음입니다.

디자인 시스템 기본값은 `CoreTimelineStyle` 의 `default` 로 시작하는 상수(`CoreTimelineStyle.defaultDotSize` 등)에 있고, Flutter와 Web이 같은 상수를 읽습니다.

### 밀도

앱의 밀도(`CoUIApp(density:)` · `CoUIWeb(density:)`)는 항목 줄 사이와 칸 사이의 간격을 바꿉니다. 기본값 16인 두 간격은 `compact` 에서 12, `spacious` 에서 20이 됩니다. 시각 칸의 폭, 점 지름, 점의 위 여백은 밀도를 따르지 않습니다. 따라서 [좁은 너비](#좁은-너비)에서 필요한 최소 폭도 밀도에 따라 달라집니다.

### 서페이스 스타일

선 두께에 하한이 있는 `neoBrutalism` 서페이스 스타일에서는 두 플랫폼 모두 기본 연결선(두께 2)이 4 두께로 그려집니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

뒤에 있을수록 우선합니다.

```text
CoreTimelineStyle 의 디자인 시스템 기본값
  → CoreComponentTheme.timeline.style    // 앱 전체 (CoreTimelineTheme)
  → timelineStyle                        // 인스턴스별
```

글자 스타일(`timestampTextStyle` · `titleTextStyle` · `descriptionTextStyle`)과 간격(`columnGapStyle` · `contentTopGapStyle`)은 그 안의 필드끼리 같은 순서로 합쳐집니다. 예를 들어 `titleTextStyle` 에 색만 주면 기본 글자 역할은 남습니다.

### 사용 예

<Preview demo="timeline/styled" />

<Split>

<Code language="dart" title="Timeline 하나만 바꾸기">
Timeline(
  items: historyItems,
  timelineStyle: CoreTimelineStyle(
    dotColor: CoreColor.token(CoreColors.success),
    dotSize: CoreSpace.space16,
    dotTopMargin: CoreSpace.space2,
    connectorThickness: CoreStrokeWidth.stroke1,
    rowSpacing: CoreSpace.space24,
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    timeline: CoreTimelineTheme(
      style: CoreTimelineStyle(
        timeColumnWidth: CoreSpace.space96,
        rowSpacing: CoreSpace.space24,
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

`withStyle` 은 지금의 `timelineStyle` 위에 넘긴 값을 합친 새 `Timeline` 을 돌려줍니다. 생성자의 `timelineStyle` 과 같게 동작하고, 같은 필드는 뒤에 이은 값이 이깁니다. 모서리나 색을 한 낱말로 바꾸는 getter 는 `Timeline` 에 없습니다.

아래 예제는 점 지름을 16으로 키우고 `dotTopMargin` 은 기본값으로 둡니다. 점을 제목 첫 줄의 가운데에 맞추려면 `dotTopMargin: CoreSpace.space2` 를 함께 줍니다([점 크기를 바꿀 때](#점-크기를-바꿀-때)).

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class TimelineChainExample extends StatelessWidget {
  const TimelineChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Timeline(
      items: [
        CoreTimelineItem(title: '주문 접수', timestamp: '오전 10:00'),
        CoreTimelineItem(title: '처리 중', timestamp: '오전 11:30'),
        CoreTimelineItem(title: '발송 완료', timestamp: '오후 2:00'),
      ],
    ).withStyle(
      const CoreTimelineStyle(
        dotColor: CoreColor.token(CoreColors.success),
        dotSize: CoreSpace.space16,
        dotCornerRadius: CoreRadius.radius4,
        connectorColor: CoreColor.token(CoreColors.outlineVariant),
        connectorThickness: CoreStrokeWidth.stroke4,
        titlePadding: CoreEdgeInsets.directional(start: CoreSpace.space16),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class TimelineChainExample extends StatelessComponent {
  const TimelineChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Timeline(
      items: [
        CoreTimelineItem(title: '주문 접수', timestamp: '오전 10:00'),
        CoreTimelineItem(title: '처리 중', timestamp: '오전 11:30'),
        CoreTimelineItem(title: '발송 완료', timestamp: '오후 2:00'),
      ],
    ).withStyle(
      const CoreTimelineStyle(
        dotColor: CoreColor.token(CoreColors.success),
        dotSize: CoreSpace.space16,
        dotCornerRadius: CoreRadius.radius4,
        connectorColor: CoreColor.token(CoreColors.outlineVariant),
        connectorThickness: CoreStrokeWidth.stroke4,
        titlePadding: CoreEdgeInsets.directional(start: CoreSpace.space16),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="접근성-accessibility"></a>

## 접근성

`Timeline` 은 표시 전용이고, 두 플랫폼 모두 스스로 붙이는 접근성 역할과 이름이 없습니다. 보조 기술에는 안의 글이 전달됩니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 없습니다. 위젯이 `Semantics` 를 붙이지 않습니다. |
| Jaspr Web | 없습니다. 루트, 항목 줄, 칸, 점, 연결선은 `<div>` 이고 글은 그 안의 `<span>` 입니다. 컴포넌트가 붙이는 `role` · `aria-*` 는 없고, `attributes` 로 준 속성은 루트에 붙습니다. |

#### 목록 시맨틱

두 플랫폼 모두 목록과 목록 항목을 알리지 않습니다. Web 은 `attributes` 로 루트에 `role="list"` 를 줄 수 있지만, 항목 줄은 컴포넌트 안에서 만드는 `<div>` 라 `role="listitem"` 을 붙일 방법이 없습니다. 항목 없는 목록이 되므로 루트에만 `role="list"` 를 주지 않습니다. Flutter 도 항목 하나에 시맨틱을 더할 파라미터가 없습니다.

단계마다 완료 · 진행 · 대기 · 실패 상태가 있는 진행 목록이라면 [Steps](/components/steps) 의 `variant: CoreStepsVariant.list` 를 씁니다. 이 형태는 두 플랫폼 모두 목록과 목록 항목 역할을 붙입니다. 다만 항목의 설명은 그리지 않습니다.

### 키보드

없음. `CoreTimelineItem` 에 콜백이 없어 항목을 조작할 수 없고, 포커스를 받는 자식이 없어 Tab 으로 멈추는 곳이 생기지 않습니다. Web 생성자는 이벤트 처리 파라미터를 받지 않습니다.

### 스크린 리더

- **내용 순서** — 위젯 트리와 DOM 에는 `items` 순서대로, 항목마다 시각 → 제목 → 설명이 놓입니다. `null` 인 값은 읽을 글이 없습니다.
- **점과 연결선** — 글과 이름이 없는 장식이라 읽을 내용이 없습니다.
- **이름** — `Timeline` 전체에는 접근 가능한 이름이 없습니다.
- **변화 알림** — 라이브 영역이 없어, 항목이 추가되거나 바뀌어도 알리지 않습니다.

목록 전체에 이름과 항목 수를 알려야 하면 바깥에서 붙입니다. 화면에 보이는 제목으로 적으면 모든 사용자가 같은 정보를 얻습니다. 보조 기술에만 묶음 이름을 주려면 아래처럼 씁니다. 묶음 이름을 실제로 읽는 방식은 보조 기술마다 다를 수 있고, 이 방법으로는 항목마다 몇 번째인지를 알리지 못합니다.

<Split>

<Code language="dart" title="Flutter">
Semantics(
  container: true,
  explicitChildNodes: true,
  label: '주문 이력, 3건',
  child: Timeline(items: historyItems),
)
</Code>

<Code language="dart" title="Jaspr Web">
Timeline(
  items: historyItems,
  attributes: {
    'role': 'group',
    'aria-label': '주문 이력, 3건',
  },
)
</Code>

</Split>

### 포커스 관리

없음. 오버레이가 아니고 포커스를 받지 않아, 포커스를 옮기거나 가두거나 되돌리지 않습니다.

### 알려진 제약

- 목록 시맨틱이 없어, 스크린 리더에 "N개 중 M번째" 가 전달되지 않습니다.
- 시간의 흐름은 화면 배치와 내용 순서로만 드러납니다. 시각 글은 전달되지만 이전 · 다음 관계는 따로 알리지 않습니다.
- `CoreTimelineItem` 의 `title` · `description` · `timestamp` 는 모두 `String` 이라 항목에 위젯을 넣을 수 없습니다. 항목 하나를 `Semantics` 로 감싸거나 그 자리에 `Skeleton` 을 넣을 방법이 없습니다. 불러오는 동안에는 `Timeline` 대신 `Skeleton` 으로 만든 화면을 직접 그립니다.
- 항목의 상태를 나타내는 값이 없어 모든 점의 모양과 색이 같습니다. 상태는 글로 적어야 합니다.
- Web 에는 색 강제 모드(forced-colors)를 위한 `Timeline` 전용 스타일이 없습니다. 기본 점과 연결선은 배경색으로만 그리므로, Chrome 의 강제 색 모드 에뮬레이션에서는 점과 연결선이 보이지 않고 글만 남았습니다.
- Flutter 에서 시스템 글자 크기를 키우면 글자는 커지지만 시각 칸의 폭과 점의 위 여백은 그대로입니다. 시각이 더 일찍 줄을 바꾸고, 점이 제목 첫 줄의 가운데보다 위에 놓입니다. 이 두 길이는 글자 크기 설정이 아니라 `theme.scaling` 을 따릅니다.

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은
> [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`items` 와 `timelineStyle` 은 두 플랫폼에서 이름이 같습니다. 두 플랫폼 모두 목록 시맨틱, 방향 속성, 항목별 상태가 없습니다. 그리는 방식과 일부 값의 적용은 다음처럼 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 그리는 방법 | `Column(spacing:)` 에 항목마다 `IntrinsicHeight` + `Row` 를 쌓고, 연결선은 `CustomPaint` 로 그립니다. | `<div>` 에 CSS flex 와 `gap` 을 씁니다. 연결선은 늘어나는 `<div>` 입니다. |
| 시각 칸 폭 | `timeColumnWidth` 를 logical px 로 씁니다. | `timeColumnWidth` 를 `rem` 으로 바꿔 씁니다. |
| 폭 | 받은 폭을 채웁니다. 폭이 정해진 자리가 필요합니다. | 블록 부모에서는 폭을 채우고, 가로 flex 나 가운데 정렬한 세로 flex 부모에서는 내용에 맞춥니다. |
| 높이 | 부모가 높이를 제한하면 그 높이를 다 차지합니다. | 블록 부모에서는 내용 높이입니다. |
| 줄이 바뀐 시각 | 글 상자가 칸 폭을 쓰고, 그 안의 줄은 읽기 시작하는 쪽에 맞춥니다(왼쪽에서 오른쪽으로 읽을 때는 왼쪽). | 모든 줄을 오른쪽에 맞춥니다. |
| 크기를 키우는 기준 | `theme.scaling` 이 시각 칸 폭, 점 지름, 점의 위 여백, 제목 여백, 간격, 연결선 두께에 반영됩니다. `dotBorderWidth` 에는 곱하지 않습니다. | 시각 칸 폭, 간격, 점의 지름 · 위 여백 · 테두리는 `rem` 이라 브라우저의 루트 글자 크기를 따릅니다. 연결선 두께는 px 라 따르지 않습니다. |
| 테두리를 두른 점 | 테두리를 `dotSize` 안쪽에 그립니다. | 점에 `box-sizing` 을 정하지 않습니다. 앱에 `box-sizing: border-box` 규칙이 없으면 테두리가 바깥에 더해져, 점의 지름이 `dotSize + 2 × dotBorderWidth` 가 됩니다. |
| 점의 모서리와 서페이스 스타일 · 밀도 | 서페이스 스타일과 밀도는 `dotCornerRadius` 를 바꾸지 않습니다. | `CoreRadius` 단계와 같은 값은 `--coui-radius-*` 변수를 읽어, 서페이스 스타일이나 밀도에 따라 달라질 수 있습니다. 기본 제공 서페이스 스타일과 밀도는 `0` 과 `9999` 를 바꾸지 않습니다. |
| `contentTopGapStyle` | `Gap` 에 그대로 넘깁니다. | `size` 만 읽습니다. |
| HTML 속성 | 없습니다. | `id` 와 `attributes` 는 루트 `<div>` 에 붙습니다. `classes` · `css` · `tag` 는 생성자가 받지만 루트에 적용되지 않습니다. |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 `items` 와 `timelineStyle` 을 같은 이름으로 씁니다.

### `Timeline` 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `items` | `List<CoreTimelineItem>` | 필수 | 타임라인 항목 목록. 넘긴 순서대로 그립니다. |
| `timelineStyle` | `CoreTimelineStyle?` | `null` | 이 인스턴스의 겉모습. 필드는 아래 표에 있습니다. |
| `key` | `Key?` | `null` | 위젯 · 컴포넌트의 키 |

### `CoreTimelineItem` 필드

두 플랫폼이 같은 클래스를 쓰고, `const` 로 만들 수 있습니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `title` | `String` | 필수 | 제목 |
| `description` | `String?` | `null` | 제목 아래의 설명 |
| `timestamp` | `String?` | `null` | 시각 칸에 적는 글. 날짜로 해석하지 않습니다. |

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트 `<div>` 의 id |
| `attributes` | `Map<String, String>?` | `null` | 루트의 HTML 속성 — `role`, `aria-label`, `data-*` |
| `classes` | `String?` | `null` | 생성자가 받지만 루트에 적용되지 않습니다. |
| `css` | `Styles?` | `null` | 생성자가 받지만 루트에 적용되지 않습니다. |
| `tag` | `String` | `'div'` | 생성자가 받지만 루트는 늘 `<div>` 입니다. |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreTimelineStyle patch)` | `timelineStyle` 에 `patch` 를 합친 새 `Timeline` 을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다. |
| `copyWith({items, timelineStyle, key})` | 바꾼 값으로 사본을 만듭니다. Web 은 `id` · `attributes` · `classes` · `css` · `tag` 도 받습니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.timeline` | `CoreTimelineTheme?` | 앱 전체의 Timeline 테마. `style`(`CoreTimelineStyle?`) 하나를 가집니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreTimelineStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `dotColor` | `CoreColor?` | Dot indicator fill colour. |
| `dotSize` | `double?` | Dot indicator diameter (logical px). |
| `dotCornerRadius` | `double?` | Dot indicator corner radius (logical px). `9999` = circle. |
| `dotBorderColor` | `CoreColor?` | Dot indicator border stroke colour. Paired with [dotBorderWidth] — the ring is drawn only when BOTH are set; see the note above. |
| `dotBorderWidth` | `double?` | Dot indicator border stroke width (logical px). Paired with [dotBorderColor]; see the note above. |
| `dotTopMargin` | `double?` | Dot indicator top margin (logical px) — lines the dot up with the first line of the title. See [defaultDotTopMargin] for how the default is derived. |
| `connectorColor` | `CoreColor?` | Connector line colour. |
| `connectorThickness` | `double?` | Connector line thickness (logical px). |
| `connectorSpacing` | `double?` | Spacing between the connector line and the dot at each of its ends (logical px) — the line starts this far below its own dot and stops this far above the next item's dot, so a larger value makes the line shorter. See [defaultConnectorSpacing]. |
| `rowSpacing` | `double?` | Vertical spacing between adjacent timeline rows / blocks (logical px). Stays a flat double — the rows wrapper consumes this scalar via native `Column.spacing` (Flutter) / inline `gap` rem (Web) per N-sibling uniform distribution pattern. |
| `columnGapStyle` | `CoreGapStyle?` | Horizontal gap between the timestamp, dot and content columns. |
| `timeColumnWidth` | `double?` | Width of the timestamp column (logical px). |
| `titlePadding` | `CoreEdgeInsets?` | Padding of the item title. Falls back to [defaultTitlePadding]. |
| `contentTopGapStyle` | `CoreGapStyle?` | Vertical gap between the title and the description. |
| `timestampTextStyle` | `CoreTextStyle?` | Timestamp text style override. `null` defers to [defaultTimestampTextStyle]. |
| `titleTextStyle` | `CoreTextStyle?` | Item title text style override. `null` defers to [defaultTitleTextStyle]. |
| `descriptionTextStyle` | `CoreTextStyle?` | Item description text style override. `null` defers to [defaultDescriptionTextStyle]. |

<!-- STYLE_TABLE:END -->

<Note>

표의 `dotBorderColor` · `dotBorderWidth` 설명이 가리키는 안내는 이것입니다. 두 값을 모두 줄 때만 점의 테두리를 그리고, 두 값에는 기본값이 없습니다. `contentTopGapStyle` 은 Web 에서 `size` 만 읽습니다. `dotCornerRadius` 는 `9999` 가 아니어도 점을 원으로 만들 만큼 크면 원이 됩니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="timeline/related-steps" title="Steps">

단계별 진행 상황을 상태와 함께 보여 줍니다. 자세한 내용은 [Steps](/components/steps) 를 보세요.

</Card>
<Card demo="timeline/related-stepper" title="Stepper">

단계를 눌러 이동하는 다단계 폼에 씁니다. 자세한 내용은 [Stepper](/components/stepper) 를 보세요.

</Card>
<Card demo="timeline/related-tracker" title="Tracker">

여러 구간의 상태를 칸으로 이어 보여 줍니다. 자세한 내용은 [Tracker](/components/tracker) 를 보세요.

</Card>
</Cards>
