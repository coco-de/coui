---
title: Tracker
description: 날짜 · 빌드처럼 순서가 있는 구간의 상태를 색 막대 한 줄로 보여 줍니다. 구간마다 상태 네 가지 중 하나와 툴팁 글을 줍니다.
category: display
platforms: [flutter, web]
related: [progress, stat]
tags: [tracker, uptime, streak, segments, display]
template: v2
source: display/tracker
---

# Tracker

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

`Tracker` 는 `segments` 목록을 적은 순서대로 한 줄의 색 구간으로 그립니다. 모든 구간의 폭은 같고, 색은 구간의 `status` 가 정합니다. 업타임 이력, 습관 추적, 연속 기록처럼 여러 시점의 상태를 이어 볼 때 씁니다.

속성을 바꿔 보며 확인하고, 만들어진 코드를 복사하세요. 구간에 마우스를 올리면 그 구간의 툴팁이 아래에 열립니다.

<Playground component="tracker" />

`segments` 컨트롤은 구간 수를 바꿉니다. `itemHeight` · `itemSpacing` · `한 가지 색` 은 `trackerStyle` 의 값이고, `한 가지 색` 은 `segmentColor` 에 `primary` 토큰을 줍니다. `각진 끝` 은 `rounded: false` 입니다.

## 구조

Tracker 는 가로 한 줄과 그 안의 구간으로 이루어집니다. 구간마다 [Tooltip](/components/tooltip) 이 하나씩 감싸고 있으며, 말풍선은 마우스를 올렸을 때만 나타납니다. 아래 그림은 부분이 잘 보이도록 `trackerStyle` 로 높이 · 간격 · 모서리를 키운 것입니다.

<Anatomy demo="tracker/anatomy">
<AnatomyItem part="container" name="Container">

부모의 폭을 쓰는 가로 한 줄입니다. 구간 사이를 `itemSpacing` 만큼 띄웁니다. 자체 배경과 테두리는 없습니다.

</AnatomyItem>
<AnatomyItem select="[aria-label] > div > div > [aria-label]" name="segment">

`CoreTrackerSegment` 하나입니다. 폭은 모두 같고, 높이는 `itemHeight`, 색은 `status` 가 정합니다. `rounded` 가 `true` 면 첫 구간의 왼쪽과 마지막 구간의 오른쪽 모서리만 둥급니다.

</AnatomyItem>
</Anatomy>

<a id="coretrackerstatus-색상"></a>

## 구간 상태

구간의 상태는 `CoreTrackerStatus` 네 값 가운데 하나입니다. 어떤 값이 어느 상태인지는 앱이 정해서 넘깁니다. Tracker 는 수치를 받아 상태를 계산하지 않습니다.

<Preview demo="tracker/statuses" />

| 상태 | 색 토큰 | 보이는 모습 |
| --- | --- | --- |
| `fine` | `success`, 불투명도 40% | 옅은 성공 색. 정상 구간을 옅게 두어 경고 · 오류 구간이 눈에 띄게 합니다. |
| `warning` | `warning` | 경고 색 |
| `critical` | `error` | 오류 색 |
| `unknown` | `outlineVariant` | 옅은 선 색. 값을 모르거나 기록이 없는 구간에 씁니다. |

- 색의 실제 값은 앱의 색 구성표를 따릅니다.
- 상태 하나의 색만 바꾸는 필드는 없습니다. `trackerStyle.segmentColor` 는 상태와 관계없이 모든 구간을 한 색으로 칠합니다.
- 색 구성표의 `success` · `warning` · `error` · `outlineVariant` 를 바꾸면 구간 색도 바뀝니다. 같은 토큰을 쓰는 다른 컴포넌트도 함께 바뀝니다.
- 네 상태는 모양이 같고 색(`fine` 은 불투명도까지)으로만 구분됩니다.

## 크기

Tracker 에는 `size` 단계가 없습니다. 폭은 부모를 따르고, 높이 · 간격 · 끝 모서리는 `trackerStyle` 로 바꿉니다. 아래 값은 논리 px 입니다.

| 항목 | `CoreTrackerStyle` 필드 | 기본값 |
| --- | --- | --- |
| 구간 높이 | `itemHeight` | 32 |
| 구간 사이 간격 | `itemSpacing` | 4 |
| 바깥 양 끝의 모서리 | `endRadius` | 2 |
| 구간 폭 | 필드 없음 | 간격을 뺀 폭을 구간 수로 똑같이 나눕니다. |

<Preview demo="tracker/heights" />

```dart
Tracker(
  segments: segments,
  trackerStyle: CoreTrackerStyle(itemHeight: CoreSpace.space16),
)
```

- 앱의 밀도(`CoUIApp(density:)` · `CoUIWeb(density:)`)는 4 이하의 간격을 바꾸지 않습니다. 그래서 기본 간격 4 는 모든 밀도에서 같습니다. 4보다 큰 `itemSpacing` 은 밀도에 따라 달라질 수 있습니다.
- 끝 모서리도 기본값 2 는 모든 밀도에서 같습니다. 6 ~ 16 사이의 `endRadius` 는 밀도에 따라 달라질 수 있습니다.
- 활성 서페이스 스타일은 끝 모서리를 더 둥글거나 각지게 바꿀 수 있습니다.

## 형태

`rounded`(기본 `true`)는 줄 전체의 바깥 양 끝을 둥글게 할지 정합니다. 안쪽 모서리는 늘 각져 있습니다. 구간이 하나면 그 구간의 양 끝이 모두 둥급니다. `false` 면 `endRadius` 를 주어도 모서리를 둥글리지 않습니다.

<Preview demo="tracker/shape" />

```dart
// 끝 모서리를 키우기
Tracker(
  segments: segments,
  trackerStyle: CoreTrackerStyle(endRadius: CoreRadius.radius12),
)

// 모두 각지게
Tracker(segments: segments, rounded: false)
```

<a id="동작-스펙-behavior"></a>

## 상태

Tracker 는 표시 전용입니다. 자체 타이머, 선택 상태, 클릭 콜백이 없습니다. 데이터가 바뀌면 앱이 새 `segments` 목록을 넘깁니다. 구간에 반응하는 동작은 툴팁 하나입니다.

| 상황 | 동작 |
| --- | --- |
| 구간에 마우스를 올림 | 150ms 동안 머물면 툴팁이 구간 아래에 열립니다. 아래에 자리가 없으면 반대쪽으로 옮겨 열 수 있습니다. |
| 마우스가 구간을 벗어남 | 150ms 뒤에 닫히기 시작합니다. |
| hover 중인 구간의 색 · 크기 | 바뀌지 않습니다. |
| 클릭 · 탭 | 처리하지 않습니다. |
| 키보드 | 처리하지 않습니다. 구간은 포커스를 받지 않습니다. |
| `tooltip` 생략 | 상태 값의 영어 이름(`fine` · `warning` · `critical` · `unknown`)이 툴팁에 보입니다. |
| `tooltip: ''` | 툴팁이 꺼지지 않고 글이 없는 말풍선이 열립니다. |
| 빈 `segments` | 구간을 하나도 그리지 않습니다. |

- Flutter 에서 동작 줄이기를 켜면 150ms 를 기다리지 않고 바로 열고 닫기 시작합니다. Web 은 같은 시간을 기다립니다.
- 툴팁의 위치와 여닫는 시간을 바꾸는 파라미터는 없습니다. 구간 하나의 툴팁만 끄는 방법도 없습니다.
- Jaspr Web 의 툴팁은 컴포넌트가 브라우저에서 동작할 때만 열립니다(클라이언트 앱 또는 `@client` 컴포넌트 안). 서버에서만 그린 HTML 에는 말풍선이 없고, 툴팁 글은 구간의 `aria-label` 에만 있습니다. 이 페이지에서는 플레이그라운드에서 확인합니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 서비스의 업타임 · 다운타임 이력을 색 막대로 보여 줄 때
- 습관 추적, 스트릭, 연속 기록을 보여 줄 때
- 빌드나 배포처럼 순서가 있는 실행 결과를 상태별로 이어 보여 줄 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 지금의 상태 하나를 점으로 보여 줄 때 | [Status](/components/status) |
| 작업이 얼마나 끝났는지 비율로 보여 줄 때 | [Progress](/components/progress) |
| 시간순 사건에 제목과 설명을 붙일 때 | [Timeline](/components/timeline) |
| 가동률 같은 숫자 하나를 강조할 때 | [Stat](/components/stat) |

구간을 눌러 상세 화면을 열어야 한다면 Tracker 만으로는 할 수 없습니다. 구간에는 누르는 동작이 없습니다.

<a id="do"></a>

### 구간마다 뜻이 있는 `tooltip` 주기

`tooltip` 에는 언제의 구간인지와 상태를 함께 적습니다. 생략하면 번역되지 않은 상태 이름만 남고, 날짜만 적으면 툴팁과 구간의 이름에서 상태가 빠집니다. 주어진 `tooltip` 뒤에 상태 이름을 덧붙이지 않기 때문입니다.

```dart
CoreTrackerSegment(
  status: CoreTrackerStatus.critical,
  tooltip: '3월 4일 · 다운타임 발생',
)
```

<a id="dont"></a>

### 요약과 색

<Cards columns="2">
<Card demo="tracker/do-summary" tone="do" eyebrow="이렇게 하세요">

제목과 요약 문장을 곁에 둡니다. 색을 가려 보기 어렵거나 툴팁을 열 수 없는 사람도 상태를 읽을 수 있습니다.

</Card>
<Card demo="tracker/dont-bare" tone="dont" eyebrow="이렇게 하지 마세요">

요약 없이 Tracker 만 두지 않습니다. 상태는 색으로 구분되고, 툴팁은 키보드로 열 수 없습니다.

</Card>
<Card demo="tracker/do-status-color" tone="do" eyebrow="이렇게 하세요">

상태가 섞인 목록은 상태마다 정해진 색을 그대로 둡니다.

</Card>
<Card demo="tracker/dont-one-color" tone="dont" eyebrow="이렇게 하지 마세요">

상태가 섞인 목록에 `segmentColor` 를 주지 않습니다. 모든 구간이 같은 색이 되어 눈으로는 상태를 가릴 수 없습니다.

</Card>
</Cards>

## 배치

### 폭

Tracker 는 부모의 폭을 채우고 구간에 똑같이 나눠 줍니다. 부모의 폭이 정해져 있어야 합니다.

- **Flutter** — 가로 폭에 제한이 없는 곳(`Row` 의 직계 자식, 가로 스크롤 안)에 바로 두면 레이아웃 에러가 납니다. `Expanded` 나 폭을 정한 `SizedBox` 로 감쌉니다.
- **Jaspr Web** — 폭이 내용에 맞춰 정해지는 상자(예: 가로 flex 안의 폭 없는 `div`)에는 구간에 나눠 줄 폭이 없어 구간이 보이지 않을 수 있습니다. 그 상자에 폭을 주거나 `flex-1` 을 줍니다.

제목 옆에 한 줄로 놓을 때는 이렇게 씁니다.

<Split>

<Code language="dart" title="Flutter">
Row(
  children: [
    Text('API 서버'),
    Gap.space12(),
    Expanded(child: Tracker(segments: segments)),
  ],
)
</Code>

<Code language="dart" title="Jaspr Web">
div(classes: 'flex items-center', [
  Text('API 서버'),
  Gap.space12(),
  div(classes: 'flex-1', [Tracker(segments: segments)]),
])
</Code>

</Split>

### 구간이 많을 때

구간은 줄바꿈하거나 가로로 스크롤하지 않고, 구간 수를 자동으로 줄이지도 않습니다. 간격은 줄어들지 않으므로 구간 하나의 폭은 `(전체 폭 − itemSpacing × (구간 수 − 1)) ÷ 구간 수` 입니다. 아래는 폭 320, 기본 간격 4, 배율 1 일 때의 계산값입니다.

| 구간 수 | 간격이 차지하는 폭 | 구간 하나의 폭 |
| --- | --- | --- |
| 14 | 52 | 약 19.1 |
| 30 | 116 | 6.8 |
| 60 | 236 | 1.4 |
| 90 | 356 | 남는 폭이 없습니다. |

간격의 합이 전체 폭 이상이면 모든 구간의 폭이 0 이 되어 막대가 하나도 보이지 않습니다. 폭 320 에서 기본 간격이면 81칸부터입니다. 간격의 합이 전체 폭보다 크면 줄이 부모 밖으로 넘칩니다. Flutter 는 디버그 모드에서 넘침 에러를 알리고, Web 은 간격이 줄 밖으로 밀려 나가 페이지에 가로 스크롤이 생길 수 있습니다.

<Preview demo="tracker/dense" />

```dart
Tracker(
  segments: segments, // 60칸
  trackerStyle: CoreTrackerStyle(itemSpacing: CoreSpace.space2),
)
```

- 간격을 줄입니다. 폭 320 에서 90칸은 간격이 2 면 한 칸이 약 1.6, 0 이면 약 3.6 입니다. 간격이 0 이면 색이 같은 이웃 구간은 하나로 이어져 보입니다.
- 구간을 묶습니다. 예를 들어 하루 단위 90칸 대신 주 단위 구간을 넘기고, 각 주의 상태와 `tooltip` 은 앱이 정합니다.
- 좁은 화면에서는 최근 구간만 넘깁니다. Tracker 가 화면 폭에 맞춰 목록을 고르지는 않습니다.
- 구간이 가늘수록 마우스를 올려 툴팁을 열기 어렵습니다.

## 테마와 스타일

### 파라미터와 스타일

- **위젯 파라미터** — `segments`, `rounded`, `trackerStyle`
- **크기** — `trackerStyle` 의 `itemHeight`, `itemSpacing`, `endRadius`
- **색** — `trackerStyle` 의 `segmentColor`. 모든 구간에 적용됩니다.
- **툴팁의 겉모습** — Tracker 에는 전용 파라미터가 없습니다. 앱 전체의 `CoreTooltipTheme` 이 Tracker 의 툴팁에도 적용되며, 다른 Tooltip 도 함께 바뀝니다.

### 값이 정해지는 순서

뒤에 있을수록 우선하고, 필드마다 따로 합쳐집니다.

```text
CoreTrackerStyle 의 기본값 + defaultsByStatus[status]   // 디자인 시스템 기본값
  → CoreTrackerTheme.style                              // 앱 전체
  → trackerStyle                                        // 인스턴스별
```

테마의 `style` 에 `segmentColor` 를 두면 모든 Tracker 의 모든 구간이 그 색이 됩니다. 인스턴스에서 `segmentColor` 를 `null` 로 두면 테마 값을 그대로 물려받으므로, 상태별 색으로 되돌릴 수 없습니다.

### 사용 예

<Split>

<Code language="dart" title="인스턴스 하나 바꾸기">
Tracker(
  segments: segments,
  trackerStyle: CoreTrackerStyle(
    itemHeight: CoreSpace.space24,
    itemSpacing: CoreSpace.space2,
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    tracker: CoreTrackerTheme(
      style: CoreTrackerStyle(
        itemHeight: CoreSpace.space24,
        itemSpacing: CoreSpace.space2,
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

`withStyle` 은 이미 만든 `Tracker` 의 `trackerStyle` 위에 넘긴 값을 합친 새 `Tracker` 를 돌려줍니다. 생성자의 `trackerStyle` 과 같은 방식으로 적용되고, 같은 필드는 뒤에 적은 값이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class TrackerChainExample extends StatefulWidget {
  const TrackerChainExample({super.key});

  @override
  State<TrackerChainExample> createState() => _TrackerChainExampleState();
}

class _TrackerChainExampleState extends State<TrackerChainExample> {
  @override
  Widget build(BuildContext context) {
    return Tracker(
      segments: [
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.warning),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.critical),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.unknown),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.warning),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
      ],
    ).withStyle(
      const CoreTrackerStyle(
        itemHeight: CoreSpace.space48,
        itemSpacing: CoreSpace.space4,
        endRadius: CoreRadius.radius8,
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class TrackerChainExample extends StatefulComponent {
  const TrackerChainExample({super.key});

  @override
  State<TrackerChainExample> createState() => _TrackerChainExampleState();
}

class _TrackerChainExampleState extends State<TrackerChainExample> {
  @override
  Component build(BuildContext context) {
    return Tracker(
      segments: [
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.warning),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.critical),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.unknown),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.warning),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
      ],
    ).withStyle(
      const CoreTrackerStyle(
        itemHeight: CoreSpace.space48,
        itemSpacing: CoreSpace.space4,
        endRadius: CoreRadius.radius8,
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

Tracker 는 줄 전체와 구간마다 정보를 하나씩 붙입니다. 줄의 이름은 앱의 언어를 따르는 한 낱말(영어 `Tracker`, 한국어 `트래커`)이고, 구간의 글은 `tooltip` 입니다. `tooltip` 이 없으면 상태 값의 영어 이름을 씁니다.

### 역할

| 플랫폼 | 줄 전체 | 구간 |
| --- | --- | --- |
| Flutter | 줄 전체를 `Semantics(container: true, label: …)` 로 감쌉니다. 역할은 지정하지 않습니다. | 구간마다 시맨틱 노드가 따로 있고, 글은 노드의 `tooltip` 속성에 들어갑니다. `label` 과 역할은 없습니다. |
| Jaspr Web | 루트 `<div>` 에 `aria-label` 이 붙습니다. `role` 은 없습니다. | 색을 칠한 `<div>` 에 `aria-label` 이 붙습니다. `role` 은 없습니다. |

Web 에서 `attributes` 로 직접 넣은 것을 빼면, `role` 을 가진 요소는 hover 중에 나타나는 말풍선(`role="tooltip"`) 하나뿐입니다. 말풍선과 구간은 `aria-describedby` 로 연결되지 않습니다.

### 키보드

없음. 표시 전용이라 포커스를 받는 요소가 없고 키를 처리하지 않습니다.

### 스크린 리더

- 줄의 이름은 무엇의 이력인지, 몇 칸이 어떤 상태인지 말하지 않습니다. 요약 문장을 만들어 주는 기능은 없습니다.
- Flutter 의 구간 글은 `label` 이 아닌 `tooltip` 속성이라, 읽는 방식은 플랫폼과 보조 기술에 따라 다를 수 있습니다.
- Web 의 `aria-label` 은 `role` 이 없는 `<div>` 에 붙어 있습니다. ARIA 는 이런 요소에 이름을 붙이는 것을 허용하지 않으므로 스크린 리더가 무시할 수 있습니다. 구간 안에는 글자가 없어, 무시되면 구간에서 읽을 내용이 없습니다.

#### 요약을 함께 주기

상태 정보를 꼭 전해야 한다면 "최근 14일 중 중단 1일" 같은 요약을 화면의 글로 함께 둡니다. 화면의 글은 두 플랫폼에서 스크린 리더, 키보드, 터치 사용자 모두에게 닿는 방법입니다.

```dart
Text('최근 14일: 정상 10일 · 느림 2일 · 중단 1일 · 기록 없음 1일').bodySmall.onSurfaceVariant
```

요약을 줄 전체의 이름으로도 주려면 Tracker 를 바깥에서 감싸고, 감싼 쪽의 이름이 안쪽 정보를 대신하게 합니다. Web 의 `attributes` 에 `aria-label` 을 넘기면 Tracker 가 자기 이름으로 덮어쓰므로, 줄의 이름은 `attributes` 의 `aria-label` 로 바꿀 수 없습니다. 감싼 상자도 [폭](#폭) 규칙을 따릅니다.

<Split>

<Code language="dart" title="Flutter">
Semantics(
  container: true,
  label: '최근 14일 중 중단 1일, 느림 2일',
  child: ExcludeSemantics(
    child: Tracker(segments: segments),
  ),
)
</Code>

<Code language="dart" title="Jaspr Web">
div(
  attributes: {
    'role': 'img',
    'aria-label': '최근 14일 중 중단 1일, 느림 2일',
  },
  [Tracker(segments: segments)],
)
</Code>

</Split>

#### 색 구분

네 상태는 같은 모양의 막대이고 색(`fine` 은 불투명도까지)으로만 구분됩니다. 구간에 무늬, 아이콘, 글자를 넣는 옵션은 없습니다.

### 포커스 관리

없음. 구간은 포커스를 받지 않고, 툴팁이 열려도 포커스를 옮기거나 가두지 않습니다.

### 알려진 제약

- 구간의 툴팁은 키보드로 열 수 없습니다.
- 터치용 동작(탭 · 길게 누르기)이 없습니다. Flutter 는 마우스와 스타일러스의 hover 만 들으므로 손가락 터치로는 툴팁이 열리지 않습니다. Web 은 `mouseenter` · `mouseleave` 를 듣습니다. 모바일 브라우저가 탭할 때 마우스 이벤트를 흉내 내어 툴팁이 열릴 수는 있지만 정해진 동작이 아닙니다.
- 열린 툴팁은 `Escape` 로 닫을 수 없습니다. 포인터를 말풍선으로 옮기면 구간을 벗어난 것으로 보고 닫습니다.
- 줄 전체를 대신하는 텍스트 요약과 `img` · `list` · `meter` 같은 역할이 없습니다.
- Web 의 줄 이름과 구간 이름은 `role` 이 없는 요소에 붙어 있어 스크린 리더가 무시할 수 있습니다.
- Web 에서는 `attributes` 의 `aria-label` 이 적용되지 않습니다.
- `tooltip` 이 없는 구간의 글은 번역되지 않는 상태 값의 영어 이름입니다.
- 상태는 색으로만 구분됩니다.
- Web 에는 색 강제 모드(forced-colors)를 위한 `Tracker` 전용 스타일이 없습니다. 구간은 배경색으로만 그리므로, Chrome 의 강제 색 모드 에뮬레이션에서는 구간이 모두 보이지 않았습니다.
- 구간이 많아 간격의 합이 전체 폭 이상이면 막대가 보이지 않습니다([구간이 많을 때](#구간이-많을-때)).
- 오른쪽에서 왼쪽으로 쓰는 방향(RTL)에서는 첫 구간이 오른쪽에 놓이지만, 둥근 모서리는 첫 구간의 왼쪽과 마지막 구간의 오른쪽에 그대로 적용됩니다. 그래서 줄의 바깥 끝 대신 첫 구간과 마지막 구간의 안쪽 모서리가 둥글어집니다.
- Web 에서는 `segmentColor` 에 토큰이 아닌 색을 주면 그리는 중에 에러가 납니다.

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은
> [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`segments` · `rounded` · `trackerStyle` 은 두 플랫폼에서 이름과 기본값이 같습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 클래스 이름 | `Tracker` | `Tracker` |
| 그리는 방법 | `Row` + `Expanded` + `Container` | flex `<div>` + `flex-1` 칸 |
| 상태 → 색 | `defaultsByStatus` 의 토큰을 테마 색으로 바꿔 칠합니다. | 같은 토큰을 `bg-{토큰}` 클래스로 붙입니다(`fine` 은 `bg-success/40`). |
| 직접 만든 `segmentColor` | `CoreColor(0xFF…)` · `CoreColor.fromHex` 같은 값도 칠합니다. | `CoreColor.token` 만 됩니다. 토큰이 아닌 색은 에러가 납니다. |
| 끝 모서리 | `BorderRadius.horizontal` | 첫 구간과 마지막 구간의 인라인 `border-radius` |
| 크기 배율 | 높이 · 간격 · 끝 모서리에 `theme.scaling` 을 곱합니다. | 높이와 간격은 `rem` 단위라 브라우저의 루트 글자 크기를 따릅니다. |
| 툴팁 | `Tooltip` 위젯. 마우스 · 스타일러스 hover 로 열립니다. | `Tooltip` 컴포넌트. `mouseenter` 로 열리며 브라우저에서 동작해야 합니다. |
| 폭이 정해지지 않은 부모 | 가로 폭에 제한이 없으면 레이아웃 에러가 납니다. | 폭이 내용에 맞춰지는 상자에서는 구간이 보이지 않을 수 있습니다. |
| 간격이 폭보다 클 때 | 디버그 모드에서 넘침 에러를 알립니다. | 간격이 줄 밖으로 넘칩니다. |
| 동작 줄이기 | 툴팁의 150ms 대기 두 번(열기 전 · 닫기 전)이 없어집니다. | 150ms 대기가 그대로입니다. |
| 접근성 정보 | 줄은 `label`, 구간은 `tooltip` 시맨틱 속성 | 줄과 구간 모두 `role` 없는 `aria-label` |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` 는 루트 `<div>` 에 붙습니다. |

<a id="props-parameters"></a>

## API

`Tracker` 의 공통 속성은 두 플랫폼이 같습니다.

### 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `segments` | `List<CoreTrackerSegment>` | 필수 | 구간 목록. 적은 순서대로 그립니다. |
| `rounded` | `bool` | `true` | 줄의 바깥 양 끝을 둥글게 합니다. |
| `trackerStyle` | `CoreTrackerStyle?` | `null` | 이 인스턴스의 겉모습(색 · 크기 · 간격)을 바꾸는 값 묶음 |
| `key` | `Key?` | `null` | 위젯 · 컴포넌트의 키 |

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트 `<div>` 의 id |
| `classes` | `String?` | `null` | 루트에 더하는 클래스 |
| `css` | `Styles?` | `null` | 루트에 더하는 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 루트의 HTML 속성. `aria-label` 은 Tracker 의 이름으로 덮어씁니다. |
| `tag` | `String` | `'div'` | 값을 받지만 루트는 늘 `<div>` 입니다. |

### CoreTrackerSegment

구간 하나의 데이터입니다.

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `status` | `CoreTrackerStatus` | 필수 | 상태 — fine, warning, critical, unknown. 색을 정합니다. |
| `tooltip` | `String?` | `null` | hover 때 보이는 글이자 구간의 접근성 정보. `null` 이면 상태 값의 이름을 씁니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreTrackerStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `itemHeight` | `double?` | Height of each tracker segment (logical px). |
| `itemSpacing` | `double?` | Horizontal spacing (logical px, pre-scaling) between adjacent tracker segments. Falls back to [defaultItemSpacing] when null. |
| `endRadius` | `double?` | Border-radius applied to the outer ends of the segment row when `widget.rounded == true` (logical px). |
| `segmentColor` | `CoreColor?` | Optional global override applied to every segment, regardless of the segment's [CoreTrackerStatus]. When `null` (the default) each segment uses its status colour from [defaultsByStatus]. |

<!-- STYLE_TABLE:END -->

<Note>

값을 주지 않으면 `itemHeight` 는 32, `itemSpacing` 은 4, `endRadius` 는 2 입니다. Flutter 는 세 값에 `theme.scaling` 을 곱해 그립니다. `segmentColor` 는 Jaspr Web 에서 `CoreColor.token` 으로 만든 색만 쓸 수 있습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="tracker/related-status" title="Status">

지금의 상태 하나를 작은 점으로 보여 줍니다. 자세한 내용은 [Status](/components/status) 를 보세요.

</Card>
<Card demo="tracker/related-progress" title="Progress">

작업이 얼마나 끝났는지 막대로 보여 줍니다. 자세한 내용은 [Progress](/components/progress) 를 보세요.

</Card>
<Card demo="tracker/related-timeline" title="Timeline">

시간순 사건을 제목과 시각으로 보여 줍니다. 자세한 내용은 [Timeline](/components/timeline) 을 보세요.

</Card>
<Card demo="tracker/related-stat" title="Stat">

지표의 이름과 숫자를 크게 보여 줍니다. 자세한 내용은 [Stat](/components/stat) 을 보세요.

</Card>
</Cards>
