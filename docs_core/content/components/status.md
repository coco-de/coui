---
title: Status
description: 사람 · 기기의 접속 상태나 시스템의 지금 상태를 작은 점으로 보여 줍니다. 색만 고르거나, 색과 모양을 함께 정하는 접속 상태를 고릅니다.
category: display
platforms: [flutter, web]
related: [avatar, badge, validation-badge]
tags: [status, indicator, user-presence]
template: v2
source: display/status
---

# Status

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

`Status` 는 지금의 상태 하나를 작은 점으로 보여 줍니다. 접속 상태는 `variant`(`online` · `busy` · `away` · `offline`)로 고르고, 그 밖의 상태는 `color` 로 점의 색을 고릅니다. 속성을 바꿔 보며 확인하고, 만들어진 코드를 복사하세요.

`variant` 를 `null` 로 두면 `color` 가 적용됩니다. `variant` 가 있으면 `color` 는 쓰지 않습니다. `보이는 글자` 를 끄면 코드에는 같은 낱말이 `semanticLabel` 로 들어갑니다. Web 에서는 보이는 글자를 켠 채로 맥동을 켜도 점이 깜빡이지 않습니다([플랫폼 차이](#플랫폼-차이)).

<Playground component="status" />

```dart
// 접속 상태 — 색과 모양을 함께 정합니다
Status(variant: CoreStatusVariant.online, label: Text('온라인'))

// 색 점 — 보이는 글자 없이 놓을 때는 이름을 줍니다
Status(
  color: CoreStatusColor.success,
  size: CoreStatusSize.lg,
  semanticLabel: '정상 운영 중',
)
```

Flutter와 Web 코드가 같습니다. `color` 의 기본값은 `neutral`, `size` 의 기본값은 `md`(지름 10)입니다. 아무 값도 주지 않으면 보이는 글자와 접근 가능한 이름이 모두 없는 점이 됩니다.

## 구조

기본 모양은 점 하나입니다. `variant: CoreStatusVariant.busy` 는 점 위에 막대를 더하고, `label` 을 주면 점과 글자를 한 줄에 담는 상자가 생깁니다. 아래 그림은 부분이 잘 보이도록 `statusStyle` 로 점 · 막대 · 간격을 키운 것입니다.

<Anatomy demo="status/anatomy">
<AnatomyItem part="container" name="Container">

`label` 을 줄 때만 생기는 한 줄 상자입니다. 점과 글자를 세로 가운데에 맞추고 `labelSpacing` 만큼 띄웁니다. `label` 이 없으면 점만 그립니다.

</AnatomyItem>
<AnatomyItem select="span:first-child" side="top" name="dot">

지름이 `size` 인 점입니다. 채우거나, 안쪽으로 선을 두른 고리로 그립니다.

</AnatomyItem>
<AnatomyItem select="span > span > span" side="right" name="bar">

`busy` 에만 있는 가로 막대입니다. 길이는 `barLength`, 두께는 `barWidth`, 색은 `barColor`(기본 `onError`)입니다.

</AnatomyItem>
<AnatomyItem part="label" name="label">

점 옆에 보이는 글자 슬롯입니다. 선택 사항입니다. 크기마다 정해진 본문 글자 역할과 `onSurface` 색을 쓰고, `offline` 만 `onSurfaceVariant` 를 씁니다.

</AnatomyItem>
</Anatomy>

## Variant

`variant`(`CoreStatusVariant`)는 접속 상태 넷 중 하나를 고릅니다. 색과 모양이 함께 정해집니다. 기본값은 `null` 이고, 그때는 `color` 로 칠한 채운 점입니다.

<VariantRow name="online" component="status" props="variant=online;size=xl;showLabel=true" label="온라인">

연락할 수 있는 상태입니다. `success` 색의 채운 점입니다.

</VariantRow>

<VariantRow name="busy" component="status" props="variant=busy;size=xl;showLabel=true" label="방해 금지">

연락할 수 있지만 방해받고 싶지 않은 상태입니다. `error` 색의 채운 점 위에 가로 막대를 그립니다.

</VariantRow>

<VariantRow name="away" component="status" props="variant=away;size=xl;showLabel=true" label="자리 비움">

잠시 자리를 비운 상태입니다. `warning` 색의 고리입니다.

</VariantRow>

<VariantRow name="offline" component="status" props="variant=offline;size=xl;showLabel=true" label="오프라인">

연락할 수 없는 상태입니다. `outline` 색의 고리이고, 보이는 글자도 `onSurfaceVariant` 로 옅어집니다.

</VariantRow>

- 채운 점(`online` · `busy`)과 고리(`away` · `offline`)는 바깥 지름이 같습니다. 고리의 선은 점 안쪽으로 두께 2 로 그립니다.
- `busy` 막대는 두께가 2 이고, 길이는 크기를 따릅니다. 끝은 두께의 절반으로 둥급니다.
- `away` 와 `offline` 은 모양이 같고 색으로만 갈립니다. 둘을 함께 쓰는 화면에는 상태를 말하는 글을 곁에 둡니다.

```dart
Status(variant: CoreStatusVariant.online, label: Text('온라인'))
Status(variant: CoreStatusVariant.busy, label: Text('방해 금지'))
Status(variant: CoreStatusVariant.away, label: Text('자리 비움'))
Status(variant: CoreStatusVariant.offline, label: Text('오프라인'))
```

## 색으로 고르는 점

서버 운영 상태처럼 접속 상태가 아닌 것은 `variant` 를 두지 않고 `color`(`CoreStatusColor`)로 고릅니다. 여덟 값은 색 토큰만 다르고 모양은 같은 채운 원입니다. 아래 점 옆의 글은 `color` 값의 이름입니다.

<Preview demo="status/colors" />

| `color` 값 | 점의 색 토큰 |
| --- | --- |
| `neutral` (기본) | `onSurfaceVariant` |
| `primary` | `primary` |
| `secondary` | `secondary` |
| `tertiary` | `tertiary` |
| `info` | `info` |
| `success` | `success` |
| `warning` | `warning` |
| `error` | `error` |

## 크기

`size`(`CoreStatusSize`)는 지름 6부터 14까지 다섯 단계입니다. 점 지름과 함께 `busy` 막대 길이, 보이는 글자의 글자 역할, 점과 글자 사이 간격이 바뀝니다.

<SizeSpec component="status" props="variant=busy;showLabel=true" label="방해 금지" />

- 기본값은 `md`(10)입니다.
- 고리의 선 두께(2)와 `busy` 막대 두께(2)는 모든 크기에서 같습니다. 그래서 `xs` 고리의 가운데 빈 곳은 지름이 2 입니다.
- 보이는 글자의 역할은 `xs` 부터 차례로 `bodyXs` · `bodySmall` · `bodyMedium` · `bodyLarge` · `bodyLarge` 입니다.
- 단계에 없는 지름은 `statusStyle` 의 `size` 로 줍니다. 이때 `busy` 막대 길이, 보이는 글자의 글자 역할, 점과 글자 사이 간격은 `size` 단계의 값이 그대로 남습니다.

<a id="동작-스펙-behavior"></a>

## 상태

`Status` 는 표시 전용입니다. `onPressed` 가 없고, hover · pressed · focus · disabled 모양이 없습니다. 움직임은 `animated` 맥동 하나입니다.

<Preview demo="status/animated" />

| 항목 | 동작 |
| --- | --- |
| `animated: false` (기본) | 멈춘 점입니다. |
| `animated: true` | 점의 불투명도가 1 과 0.4 사이를 계속 오갑니다. 고리와 `busy` 막대도 점과 함께 바뀝니다. 한 번 오가는 시간은 플랫폼마다 다릅니다. |
| `animated` 와 `label` | Flutter 는 점만 맥동하고 글자는 그대로입니다. Web 은 `label` 이 있으면 점도 맥동하지 않습니다. |
| 동작 줄이기 | 설정을 켜면 맥동하지 않습니다. |

`animated` 는 보이는 움직임만 더합니다. 연결 상태를 재거나 주기적으로 데이터를 요청하지 않습니다. 상태나 이름이 바뀌면 앱이 새 파라미터를 넘겨야 합니다.

```dart
Status(
  variant: CoreStatusVariant.online,
  animated: true,
  semanticLabel: '실시간 연결 중',
)
```

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 사람이나 기기의 접속 상태(online · busy · away · offline)를 보여 줄 때 — `variant`
- 서버나 서비스의 지금 운영 상태를 보여 줄 때 — `color` 와 `label`
- 채팅, 사용자 목록, 서버 모니터링 화면에서 아바타나 목록 행에 작은 상태 점을 붙일 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 항목의 처리 상태나 분류를 바탕이 있는 라벨로 적을 때 (검토 중 · 승인됨) | [Badge](/components/badge) (`tone` + `showDot`) |
| 읽지 않은 수나 알림 개수를 보여 줄 때 | [Badge](/components/badge) (`form: CoreBadgeForm.count`) |
| 검증 규칙의 pending · valid · invalid 상태를 보여 줄 때 | [ValidationBadge](/components/validation-badge) |
| 여러 시점의 상태 이력을 보여 줄 때 | [Tracker](/components/tracker) |

### Badge 의 점과 가르는 기준

`Badge(form: CoreBadgeForm.dot)` 도 점 하나를 그립니다. 점이 사람이나 기기의 접속 상태를 말하면 `Status` 를, 톤 색으로 "여기에 무언가 있다" 만 알리면 Badge 의 점을 씁니다.

| 질문 | `Status` | `Badge` 의 `dot` 형태 |
| --- | --- | --- |
| 무엇을 고르나 | 접속 상태(`variant`) 또는 색 여덟 가지(`color`) | 톤(`tone`) |
| 색 말고 모양도 다른가 | `busy` 는 막대, `away` · `offline` 은 고리 | 아니요. 원 하나입니다. |
| 점 옆의 글 | `label` 슬롯 | 그리지 않습니다. |
| 접근 가능한 이름 | `semanticLabel` | 전용 파라미터가 없습니다. |
| 맥동 | `animated` | 없습니다. |

<a id="do"></a>
<a id="dont"></a>

### 상태를 전달하는 법

<Cards columns="2">
<Card demo="status/do-state-text" tone="do" eyebrow="이렇게 하세요">

점 옆에 상태를 말하는 글을 둡니다. 색을 가려 보기 어려운 사람도 상태를 읽을 수 있습니다.

</Card>
<Card demo="status/dont-color-only" tone="dont" eyebrow="이렇게 하지 마세요">

색만 다른 점을 글 없이 늘어놓으면 어떤 상태인지 색에만 기대게 됩니다.

</Card>
<Card demo="status/do-count" tone="do" eyebrow="이렇게 하세요">

알림 개수는 `Badge` 의 `count` 형태로 보여 줍니다.

</Card>
<Card demo="status/dont-count" tone="dont" eyebrow="이렇게 하지 마세요">

읽지 않은 알림의 수를 알려야 하는 자리에 `Status` 점을 두지 않습니다. 점은 개수를 말하지 못합니다.

</Card>
</Cards>

점만 놓을 때는 무엇의 어떤 상태인지 `semanticLabel` 로 알려 줍니다. 옆에 상태를 말하는 글이 이미 있을 때만 생략합니다.

```dart
Status(color: CoreStatusColor.success, semanticLabel: '결제 서버 정상')
```

## 배치

### 아바타에 붙이기

[Avatar](/components/avatar) 의 `badge` 슬롯에 `Status` 를 넣으면 아바타의 배지 자리에 놓입니다.

<Preview demo="status/with-avatar" />

```dart
Avatar(
  initials: 'AB',
  size: CoreComponentSize.lg,
  badge: Status(
    variant: CoreStatusVariant.online,
    size: CoreStatusSize.lg,
    semanticLabel: '온라인',
  ),
)
```

- 점 크기는 `Status` 의 `size` 가 정합니다. 아바타 크기를 따라 바뀌지 않습니다.
- 점 둘레에 바탕색 띠를 따로 그리지 않습니다. `away` · `offline` 고리는 가운데가 비어 있어 뒤의 그림이 비칩니다.
- 다른 요소의 모서리에 얹으려면 [Indicator](/components/indicator) 에 넣습니다.

### 목록에 놓기

`label` 을 주면 점과 글자가 한 줄로 놓입니다. 둘은 세로 가운데에 맞고, 간격은 크기 표의 값입니다.

<Preview demo="status/service-list" />

```dart
Status(color: CoreStatusColor.success, label: Text('API 서버 · 정상'))
Status(color: CoreStatusColor.warning, label: Text('배치 작업 · 지연'))
Status(color: CoreStatusColor.error, label: Text('결제 모듈 · 장애'))
```

### 좁은 너비와 늘어나는 부모

- Flutter 는 부모보다 긴 `label` 을 줄바꿈하지 않아 글자가 넘칩니다. Web 은 부모 너비에 맞춰 줄바꿈합니다. 긴 설명은 `label` 에 넣지 말고, `label` 없는 점과 글을 직접 `Row` 에 놓고 글을 `Expanded` 로 감쌉니다(Web 은 flex 상자를 씁니다).
- Flutter 에서 `label` 없는 점은 부모가 크기를 강제하면 늘어납니다. 예를 들어 `crossAxisAlignment: CrossAxisAlignment.stretch` 인 `Column` 안에서는 `Align` 으로 감쌉니다. Web 의 점은 지정한 너비와 높이를 가집니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

상태를 고르는 값과 내용 · 동작은 위젯 파라미터로 넘기고, 크기 · 색 · 모서리 같은 겉모습은 `statusStyle`(`CoreStatusStyle`) 하나로 덮어씁니다.

### 파라미터와 스타일

- **위젯 파라미터** — `color`, `variant`, `size`, `label`, `semanticLabel`, `animated`
- **점** — `statusStyle` 의 `size`, `color`, `borderRadius`
- **고리** — `ringWidth`. `away` · `offline` 에만 쓰입니다.
- **막대** — `barLength`, `barWidth`, `barColor`, `barBorderRadius`. `busy` 에만 쓰입니다.
- **보이는 글자** — `labelStyle`, `labelSpacing`. `label` 이 있을 때만 쓰입니다.

채움 · 고리 · 막대 가운데 어떤 모양을 그릴지는 `variant` 가 정합니다. `statusStyle` 로는 바꿀 수 없습니다.

### 값이 정해지는 순서

뒤에 있을수록 우선합니다.

```text
defaultsBySize[size] + defaultsByColor[color]   // 디자인 시스템 기본값
                                                // variant 가 있으면 색은 defaultsByVariant[variant]
  → CoreStatusTheme.style                       // 앱 전체
  → statusStyle                                 // 인스턴스별
```

- 고리 · 막대 · 모서리의 기본값은 `CoreStatusStyle` 의 `defaultRingWidth`, `defaultBarWidth`, `defaultBarColor`, `defaultBarBorderRadius`, `defaultBorderRadius` 입니다. 막대 길이는 `defaultsBySize` 에 있습니다.
- `labelStyle` 은 필드 단위로 합쳐집니다. 크기의 글자 역할 위에 `offline` 의 글자색, 테마, 인스턴스 순서로 얹히므로 색만 바꿔도 크기의 글자 역할은 남습니다.
- 테마의 `style` 에 `size` 를 두면 점의 지름이 크기 단계와 관계없이 그 값이 됩니다. `color` 를 두면 점의 색이 `color` · `variant` 와 관계없이 그 값이 됩니다. 인스턴스의 `statusStyle` 이 같은 필드를 주면 그 값이 우선합니다. 모양은 `variant` 를 그대로 따릅니다.

### 사용 예

<Split>

<Code language="dart" title="점 하나만 바꾸기">
Status(
  variant: CoreStatusVariant.busy,
  size: CoreStatusSize.xl,
  semanticLabel: '방해 금지',
  statusStyle: CoreStatusStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    barColor: CoreColor.token(CoreColors.surface),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    status: CoreStatusTheme(
      style: CoreStatusStyle(
        ringWidth: CoreStrokeWidth.stroke3,
        labelStyle: CoreTextStyle(
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다. 앱 전체 예제는 모든 고리의 선을 3 으로, 모든 보이는 글자를 `onSurfaceVariant` 색으로 바꿉니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

`withStyle` 은 지금의 `statusStyle` 위에 넘긴 값을 합친 새 `Status` 를 돌려줍니다. 같은 필드는 뒤에 적은 값이 이깁니다. `radius0` 부터 `radius9999` 까지의 getter 는 `borderRadius` 를 같은 이름의 `CoreRadius` 값으로 바꾸는 짧은 형태입니다. 아래 예제는 점의 지름과 색을 덮은 뒤 모서리를 `radius16` 으로 정합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class StatusChainExample extends StatefulWidget {
  const StatusChainExample({super.key});

  @override
  State<StatusChainExample> createState() => _StatusChainExampleState();
}

class _StatusChainExampleState extends State<StatusChainExample> {
  @override
  Widget build(BuildContext context) {
    return const Status(
          color: CoreStatusColor.primary,
          size: CoreStatusSize.lg,
        )
        .withStyle(
          const CoreStatusStyle(
            size: CoreSize.size24,
            color: CoreColor.token(CoreColors.tertiary),
          ),
        )
        .radius16;
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class StatusChainExample extends StatefulComponent {
  const StatusChainExample({super.key});

  @override
  State<StatusChainExample> createState() => _StatusChainExampleState();
}

class _StatusChainExampleState extends State<StatusChainExample> {
  @override
  Component build(BuildContext context) {
    return Status(
          color: CoreStatusColor.primary,
          size: CoreStatusSize.lg,
        )
        .withStyle(
          const CoreStatusStyle(
            size: CoreSize.size24,
            color: CoreColor.token(CoreColors.tertiary),
          ),
        )
        .radius16;
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="접근성-accessibility"></a>

## 접근성

`Status` 의 접근 가능한 이름은 `semanticLabel` 로 줍니다. 보이는 `label` 과는 따로 받는 값입니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 역할을 지정하지 않습니다. `semanticLabel` 이 있으면 점을 `Semantics(label: …, liveRegion: true)` 로 감쌉니다. 없으면 점에는 시맨틱이 붙지 않습니다. |
| Jaspr Web | `semanticLabel` 이 없어도 루트 `<span>` 에 늘 `role="status"` 가 붙습니다. `semanticLabel` 이 있으면 `aria-label` 도 붙습니다. `label` 이 있으면 루트는 점과 글자를 감싼 바깥 `<span>` 입니다. `attributes` 에 같은 이름을 주면 그 값이 우선합니다. |

### 키보드

없음. 표시 전용이라 두 플랫폼 모두 점이 포커스를 받지 않고 키를 처리하지 않습니다. `onPressed` 가 없고, Web 생성자는 이벤트 파라미터를 받지 않습니다. 누르는 동작이 필요하면 누를 수 있는 컴포넌트 안에 놓습니다.

### 스크린 리더

- 점의 이름은 `semanticLabel` 에서만 옵니다. 생략해도 `status` 같은 기본 낱말을 넣지 않습니다. Web 은 `aria-label` 을 붙이지 않고, Flutter 는 점에 대해 아무것도 읽지 않습니다.
- `label` 의 글자는 두 플랫폼 모두 접근성 정보에 들어갑니다.
- `label` 과 `semanticLabel` 을 함께 주면 두 문자열이 모두 접근성 정보에 들어갑니다. 같은 말을 넣으면 두 번 읽힐 수 있습니다.

상태가 바뀔 때의 알림은 구성에 따라 다릅니다.

| 구성 | Flutter | Jaspr Web |
| --- | --- | --- |
| `semanticLabel` 있음 | 점이 live region 입니다. | `aria-label` 을 가진 `role="status"` 영역입니다. |
| `label` 만 있음 | live region 이 아닙니다. | 글자가 `role="status"` 영역 안에 있습니다. |
| 둘 다 없음 | 알릴 것이 없습니다. | 읽을 내용이 없는 `role="status"` 영역입니다. |

`role="status"` 는 정중한(polite) live region 입니다. 실제로 언제 무엇을 읽는지는 운영체제, 브라우저, 스크린 리더에 따라 다릅니다. 특히 Web 에서 글자는 그대로 두고 `aria-label` 만 바꾸는 경우는 다시 읽지 않을 수 있습니다. 꼭 알려야 하는 변화는 쓰는 환경에서 확인합니다.

### 포커스 관리

없음. 오버레이가 아니고 포커스를 받지 않아, 포커스를 옮기거나 가두거나 되돌리지 않습니다.

### 알려진 제약

- `color` 로 고른 점은 색만 다르고 모양이 같습니다.
- `away` 와 `offline` 은 모양이 같은 고리라 색으로만 갈립니다. 점 옆의 글이나 `semanticLabel` 로 상태를 함께 알립니다. `semanticLabel` 은 화면에 보이지 않습니다.
- Flutter 에는 live region 을 따로 켜고 끄는 파라미터가 없습니다. `semanticLabel` 이 있는지에 따라 정해집니다.
- Web 에서 `label` 과 `animated: true` 를 함께 주면 점이 맥동하지 않습니다.
- Web 에는 색 강제 모드(forced-colors)를 위한 `Status` 전용 스타일이 없습니다. 이 모드에서는 브라우저가 색을 바꾸므로 색 차이가 전달되지 않으며, 채워서 그린 점과 막대는 바탕에 묻힐 수 있습니다.
- Web 에서 선을 굵게 만드는 서페이스 스타일을 쓰면 고리도 굵어집니다. `CoreSurfaceStyleId.neoBrutalism` 은 선의 최소 두께가 4 라서, 브라우저 기본 글자 크기에서는 지름 8 이하(`xs` · `sm`)의 고리에 가운데 빈 곳이 남지 않습니다.
- Flutter 는 부모보다 긴 `label` 을 줄바꿈하지 않습니다.

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은
> [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`color` · `variant` · `size` · `label` · `semanticLabel` · `animated` · `statusStyle` 은 두 플랫폼에서 이름과 기본값이 같습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 클래스 이름 | `Status` | `Status` |
| `label` 타입 | `Widget?` | `Component?` |
| 그리는 방법 | `Container` 와 `BoxDecoration`. 고리는 테두리이고 막대는 안쪽의 작은 상자입니다. | `<span>` 에 인라인 너비 · 높이 · 모서리. 고리는 테두리이고 막대는 안쪽 `<span>` 입니다. 토큰 색은 클래스로, 직접 적은 색 값은 인라인 스타일로 붙습니다. |
| 접근성 | `semanticLabel` 이 있을 때만 live region 인 `Semantics` | `role="status"` 는 늘, `aria-label` 은 `semanticLabel` 이 있을 때 |
| 맥동 한 주기 | 2000ms. 불투명도 0.4 와 1 사이를 한 방향에 1000ms씩 일정한 속도로 오갑니다. | 1000ms. 불투명도가 1 → 0.4 → 1 로 `ease-in-out` 곡선을 따라 바뀝니다. |
| 맥동과 `label` | 점만 맥동합니다. | 맥동하지 않습니다. |
| 동작 줄이기 | `MediaQuery.disableAnimations` 또는 `AccessibilityFeatures.reduceMotion` | `@media (prefers-reduced-motion: reduce)` |
| 크기 배율 | 지름 · 고리 두께 · 막대 크기 · 점과 글자 간격에 `theme.scaling` 을 곱합니다. | 지름 · 막대 크기 · 점과 글자 간격은 `rem` 단위라 브라우저의 루트 글자 크기를 따릅니다. |
| 선을 굵게 만드는 서페이스 스타일 | 고리는 `ringWidth` 에 `theme.scaling` 만 곱한 두께입니다. | 고리 두께가 `--coui-stroke-width-*` 변수를 따라 굵어집니다. |
| 긴 `label` | 줄바꿈하지 않고 넘칩니다. | 줄바꿈합니다. |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` 는 루트 `<span>` 에 붙습니다. `label` 이 있으면 바깥 상자, 없으면 점입니다. |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. 표의 `W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다.

### 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `color` | `CoreStatusColor` | `neutral` | 점의 색 — neutral, primary, secondary, tertiary, info, success, warning, error. `variant` 를 주면 쓰지 않습니다. |
| `variant` | `CoreStatusVariant?` | `null` | 접속 상태 — online, busy, away, offline. 색과 모양을 함께 정합니다. |
| `size` | `CoreStatusSize` | `md` | 크기 단계 — xs(6), sm(8), md(10), lg(12), xl(14) |
| `label` | `W?` | `null` | 점 옆에 보이는 글자 |
| `semanticLabel` | `String?` | `null` | 상태를 설명하는 접근성 라벨. 화면에 보이지 않습니다. |
| `animated` | `bool` | `false` | 점의 맥동 |
| `statusStyle` | `CoreStatusStyle?` | `null` | 이 인스턴스의 겉모습 덮어쓰기 |
| `key` | `Key?` | `null` | 위젯 · 컴포넌트의 키 |

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트 `<span>` 의 id |
| `classes` | `String?` | `null` | 루트에 더하는 클래스 |
| `css` | `Styles?` | `null` | 루트에 더하는 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 루트의 HTML 속성. `role` · `aria-label` 을 주면 컴포넌트 값보다 우선합니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreStatusStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `size` | `double?` | Status dot size (logical px). When set, it replaces the size [defaultsBySize] gives the dot's size variant. |
| `color` | `CoreColor?` | Status dot colour. When set, it replaces the colour [defaultsByColor] gives the dot's colour variant. |
| `borderRadius` | `CoreBorderRadius?` | Status dot border radius override. When non-null, overrides [defaultBorderRadius] (the full pill / circle radius). |
| `ringWidth` | `double?` | Stroke of a ring state. `null` → [defaultRingWidth]. |
| `barLength` | `double?` | Length of the bar across a `busy` dot — the bar's width as the eye reads it, running across the dot (the designer's "막대 폭"); [barWidth] is its thickness. `null` → the size row's value in [defaultsBySize]: 4 · 4 · 6 · 8 · 8 from xs to xl. |
| `barWidth` | `double?` | Thickness of the bar across a `busy` dot. `null` → [defaultBarWidth]. |
| `barColor` | `CoreColor?` | Colour of the bar across a `busy` dot. `null` → [defaultBarColor]. |
| `barBorderRadius` | `CoreBorderRadius?` | Corners of the bar across a `busy` dot. `null` → [defaultBarBorderRadius] (round ends — half the bar's thickness). |
| `labelStyle` | `CoreTextStyle?` | Text style of the visible label. `null` → the size row's role in [defaultsBySize] (xs 12 · sm 13 · md 14 · lg, xl 15 — the body roles) in `on-surface`, merged with the state's own label colour in [defaultsByVariant] (`offline` reads `on-surface-variant`). |
| `labelSpacing` | `double?` | Space between the dot and the visible label. `null` → the size row's value in [defaultsBySize]. |

### `CoreStatusStyle` 변형별 기본값 (`CoreStatusStyle`)

| 필드 | `online` | `busy` | `away` | `offline` |
|------|------|------|------|------|
| `color` | success | error | warning | outline |
| `labelStyle` | — | — | — | CoreTextStyle(color: CoreColor.token(CoreColors.onSurfaceVari… |

<!-- STYLE_TABLE:END -->

<Note>

`statusStyle` 의 `color` 는 `color` 파라미터의 색뿐 아니라 `variant` 가 정하는 색도 바꿉니다. 모양은 `variant` 를 그대로 따릅니다. Flutter 는 `size` · `ringWidth` · `barLength` · `barWidth` · `labelSpacing` 의 값에 `theme.scaling` 을 곱해 그립니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="status/related-avatar" title="Avatar">

사용자 프로필 이미지입니다. `badge` 슬롯에 `Status` 를 넣어 접속 상태를 붙입니다. 자세한 내용은 [Avatar](/components/avatar) 를 보세요.

</Card>
<Card demo="status/related-badge" title="Badge">

상태 · 개수 · 분류를 짧게 적는 라벨입니다. 자세한 내용은 [Badge](/components/badge) 를 보세요.

</Card>
<Card demo="status/related-validation-badge" title="ValidationBadge">

입력값 검증 결과를 아이콘과 글로 보여 줍니다. 자세한 내용은 [ValidationBadge](/components/validation-badge) 를 보세요.

</Card>
<Card demo="status/related-tracker" title="Tracker">

여러 시점의 상태를 칸으로 이어 보여 줍니다. 자세한 내용은 [Tracker](/components/tracker) 를 보세요.

</Card>
</Cards>
