---
title: TrendChart
description: 시간에 따른 값 하나를 선이나 막대로 그리고, 기간 칩 · 요약 · 기준선을 함께 놓는 추이 차트입니다.
category: display
platforms: [flutter, web]
related: [stat, tracker, progress]
tags: [trend, chart, time-series, dashboard, display]
template: v2
source: display/trend_chart
---

# TrendChart

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

시간에 따라 변하는 값 하나를 선(`line`) 또는 막대(`bar`)로 그립니다. 그래프 위에는 요약 슬롯과 기간 칩을, 아래에는 점선 기준선의 범례를 놓을 수 있습니다. 데이터와 점의 글은 호출자가 넘깁니다.

<Playground component="trend-chart" />

미리보기에서 기간 칩을 누르면 미리보기가 그 기간의 점을 다시 넘깁니다. 차트는 점을 거르지 않습니다. 코드의 `period` 는 호출자가 들고 있는 상태이고, `setState` 를 쓸 수 있는 `State` 안에 둡니다.

요약, 기간 칩, 기준선을 모두 쓰는 코드는 이렇습니다. 두 플랫폼이 같습니다.

```dart
TrendChart(
  semanticLabel: '월별 구독자 추이',
  summary: const Stat(label: '구독자', value: '12,480명'),
  periods: const ['3개월', '6개월', '12개월'],
  selectedPeriodIndex: period,
  onPeriodChanged: (index) => setState(() => period = index),
  referenceValue: 12000,
  referenceLabel: '목표 12,000명',
  points: [
    CoreTrendPoint(date: DateTime(2026, 8), value: 11200, label: '8월', valueLabel: '11,200명'),
    CoreTrendPoint(date: DateTime(2026, 9), value: 12480, label: '9월', valueLabel: '12,480명'),
  ],
)
```

## 구조

위에서부터 요약 → 기간 칩 → 값 축과 그래프 → 날짜 축 → 기준선 범례 순서로 놓입니다. 넘기지 않은 부분은 빠집니다. `points` 가 비면 값 축 · 그래프 · 날짜 축 · 범례가 함께 빠지고, 그 자리에 `empty` 슬롯이 놓입니다.

<Anatomy demo="trend-chart/anatomy">
<AnatomyItem select="[data-docs-part=summary]" side="right" name="summary">

요약 슬롯입니다. 위젯이면 무엇이든 놓을 수 있고, 보통 `Stat` 을 둡니다. 선택 사항입니다.

</AnatomyItem>
<AnatomyItem select="[role=button]" side="left" name="periods">

`periods` 의 글마다 `Chip` 하나입니다. `periods` 가 비면 줄이 없습니다.

</AnatomyItem>
<AnatomyItem select="div[aria-hidden=true] > div" side="left" name="value axis">

값 축의 눈금 글입니다. `valueFormatter` 로 형식을 바꿉니다.

</AnatomyItem>
<AnatomyItem select="[role=group]" side="right" name="plot">

격자, 기준선, 선 또는 막대를 그리는 영역입니다. 점마다 마우스를 올리는 구간이 하나씩 있습니다.

</AnatomyItem>
<AnatomyItem select="[role=group] + div" side="right" name="date axis">

첫 · 가운데 · 마지막 점의 `label` 입니다.

</AnatomyItem>
<AnatomyItem select="svg + span" side="right" name="legend">

점선 표시와 `referenceLabel` 입니다. `referenceValue` 와 `referenceLabel` 을 모두 줄 때 놓입니다.

</AnatomyItem>
</Anatomy>

<a id="변형-variants"></a>

## Variant

`variant`(`CoreTrendChartVariant`)가 시리즈를 그리는 방법을 고릅니다. 기본값은 `line` 입니다. 두 값 모두 그래프 폭을 점의 수만큼 같은 구간으로 나누고 각 점을 자기 구간의 가운데에 놓으므로, 같은 데이터의 점은 가로 위치가 같습니다.

### line

<VariantRow name="line" component="trend-chart" props="variant=line">

모든 점을 잇는 선을 그리고 마지막 점에만 표식을 둡니다. 값 축은 데이터와 기준선의 범위에 맞춰 잡혀 작은 움직임도 보입니다. 축이 0 에서 시작하지 않을 수 있습니다.

</VariantRow>

### bar

<VariantRow name="bar" component="trend-chart" props="variant=bar">

점마다 막대 하나를 0 기준선에서 그립니다. 막대 길이가 곧 값이므로 값 축은 항상 0 을 포함합니다.

</VariantRow>

## 점 데이터

점 하나는 `CoreTrendPoint` 입니다. `date` 와 `value` 는 꼭 넘기고, `label` 과 `valueLabel` 은 선택 사항입니다.

| 항목 | 동작 |
| --- | --- |
| 순서 | 목록 순서 그대로 같은 간격에 놓습니다. 날짜로 정렬하지 않고, 날짜 사이가 벌어져 있어도 간격은 같습니다. |
| `label` | 날짜 축, 툴팁, 점의 접근 가능한 이름에 씁니다. 비우면 `date` 를 `yyyy-MM-dd` 로 적습니다. |
| `valueLabel` | 툴팁과 점의 접근 가능한 이름에 씁니다. 비우면 `valueFormatter` 가 만든 글을 씁니다. `valueFormatter` 도 없으면 값 축 눈금과 같은 형식이라, 눈금 간격에 필요한 소수 자릿수로 반올림하고 천 단위 구분을 넣지 않습니다. |
| 값의 범위 | 음수와 0 을 넘길 수 있습니다. `value` 와 `referenceValue` 는 유한한 수여야 합니다. `NaN` 이나 무한대를 넘기면 값 축을 계산하다 예외가 납니다. |
| 빈 값 | `value` 는 `null` 이 될 수 없고, 선을 끊는 방법이 없습니다. 점을 빼면 앞뒤 점이 바로 이어지고 남은 점이 다시 같은 간격으로 놓입니다. |
| 시리즈 | 하나입니다. |

<Note>

`valueLabel` 없이 `12.4` 와 `47.8` 을 넘기면 기본 설정의 눈금 간격은 10 이고, 툴팁과 접근 가능한 이름에는 `12` 와 `48` 이 나옵니다. 정확한 값을 보여야 하면 `valueLabel` 을 넘깁니다.

</Note>

`valueFormatter` 는 값 축 눈금과 `valueLabel` 이 없는 점에 함께 쓰입니다. 자릿수는 `round()` 나 `toStringAsFixed()` 로 직접 정합니다.

```dart
TrendChart(
  semanticLabel: '월별 문의 추이',
  valueFormatter: (value) => '${value.round()}건',
  points: [
    CoreTrendPoint(date: DateTime(2026, 8), value: 42, label: '8월'),
    CoreTrendPoint(date: DateTime(2026, 9), value: 58, label: '9월'),
  ],
)
```

<a id="축"></a>

## 값 축과 날짜 축

<Preview demo="trend-chart/axis" />

점이 30개여도 날짜 축에는 라벨이 셋만 놓입니다.

### 값 축의 범위와 눈금

- 범위는 모든 값과 `referenceValue` 를 담습니다. `bar` 는 0 도 담습니다.
- 눈금 간격은 1 · 2 · 5 × 10ⁿ 중에서, 범위를 `axisTickCount` 로 나눈 값 이상인 가장 작은 수입니다. 범위의 양 끝은 그 간격의 배수가 되도록 바깥으로 넓힙니다.
- `axisTickCount`(기본 4)는 목표 구간 수입니다. 기본값에서 실제 구간은 2개에서 5개 사이입니다. 예를 들어 `line` 에 0 과 81 을 넘기면 축은 0 · 50 · 100 의 두 구간입니다. 값이 모두 0 인 `bar` 는 [값이 모두 같을 때](#값이-모두-같을-때)를 보세요.
- 눈금마다 가로 격자선을 하나 그립니다. 세로 격자선은 없고, 0 의 선도 다른 격자선과 같은 모양입니다.
- 눈금 글의 기본 형식은 로케일과 상관없이 라틴 숫자(0–9)를 쓰고, 소수는 간격에 필요한 자릿수만 적으며, 천 단위 구분과 단위를 넣지 않습니다. `-0` 은 `0` 으로 적습니다.
- 눈금 글은 한 줄이고, 가장 긴 글의 폭만큼 값 축이 자리를 차지합니다. 글이 길수록 그래프가 좁아지므로 `valueFormatter` 는 짧은 글을 돌려주게 합니다.

### 음수 값

`bar` 의 양수 막대는 0 기준선에서 위로, 음수 막대는 아래로 자랍니다. 둥근 모서리는 기준선 반대쪽 끝에만 붙습니다. 양수와 음수의 색은 같고, 값이 0 인 점에는 막대가 없습니다.

<Preview demo="trend-chart/negative" />

막대 하나의 폭은 구간 폭에서 `barSpacing`(기본 4)을 뺀 값입니다. 점이 많아 구간 폭이 `barSpacing` 이하가 되면 막대가 보이지 않습니다. 이때는 점을 묶어 수를 줄이거나 `line` 을 씁니다.

### 날짜 축

- 첫 점, 가운데 점, 마지막 점의 라벨만 놓습니다. 점이 둘이면 둘, 하나면 하나입니다.
- 라벨은 그래프의 시작 · 가운데 · 끝에 맞춰 놓이고, 점이 하나면 가운데에 놓입니다. 라벨의 위치는 점의 가로 위치를 따르지 않습니다. 예를 들어 첫 점은 첫 구간의 가운데에 있지만 첫 라벨은 그래프의 시작에 붙습니다.
- 라벨마다 칸이 따로 있어 서로 겹치지 않고, 칸보다 긴 글은 말줄임표로 줄입니다.
- 나머지 날짜는 툴팁과 각 점의 접근 가능한 이름에 있습니다.

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 툴팁과 기간 칩

### 툴팁

점마다 그래프 높이 전체를 차지하는 구간이 있습니다. 그 구간에 마우스를 올리면 `Tooltip` 이 「날짜, 값」을 쉼표로 이어 보여 줍니다. 세로 안내선이나 점 강조는 없고, 점을 누르거나 고르는 콜백도 없습니다. `CoreTrendChartStyle` 에는 툴팁의 모양을 바꾸는 필드가 없습니다. 툴팁의 모양은 앱 테마의 `CoreComponentTheme.tooltip` 을 따릅니다.

### 기간 칩

- `periods` 의 글마다 [Chip](/components/chip) 하나를 놓고, 한 줄에 다 들어가지 않으면 다음 줄로 넘깁니다.
- `selectedPeriodIndex` 번째 칩이 선택된 모양이 됩니다. `null` 이거나 목록 밖의 수면 선택된 칩이 없습니다.
- 칩을 누르면 `onPeriodChanged` 가 그 번호(0부터)로 불립니다. 차트는 선택을 기억하지 않고 점을 거르지도 않습니다. 선택 상태를 바꾸고 새 `points` 를 넘기는 일은 호출자가 합니다.
- `onPeriodChanged` 가 `null` 이면 칩은 보여 주기만 하며 누를 수 없고 포커스를 받지 않습니다.

## 요약과 기준선

<Preview demo="trend-chart/summary" />

- `summary` 는 차트 맨 위에 놓는 슬롯입니다. 차트는 요약의 수치를 계산하지 않습니다.
- `referenceValue` 를 주면 그 높이에 가로 점선을 그립니다. 목표나 예산에 씁니다. 값 축의 범위는 이 값까지 넓어집니다.
- `referenceValue` 와 `referenceLabel` 을 모두 주고 `points` 가 있으면, 그래프 아래에 점선 표시와 `referenceLabel` 로 된 범례가 놓입니다.
- 범례에는 `referenceLabel` 의 글만 나옵니다. 기준선의 수치를 알려야 하면 글 안에 적습니다.
- `referenceLabel` 만 주면 아무것도 늘지 않습니다.

<a id="상태-전환"></a>

## 상태

### 데이터가 없을 때

`points` 가 비면 그래프 자리에 `empty` 슬롯을 놓습니다. `empty` 가 없으면 그 자리에는 아무것도 없습니다. 요약과 기간 칩은 그대로 남아 다른 기간을 고를 수 있습니다.

<Preview demo="trend-chart/empty" />

### 점이 하나일 때

`line` 은 선 없이 표식 하나를, `bar` 는 구간 폭에서 `barSpacing` 을 뺀 넓은 막대 하나를 가로 가운데에 놓습니다.

<Preview demo="trend-chart/single" />

### 값이 모두 같을 때

`line` 에서 모든 값이 같고 `referenceValue` 가 없거나 그 값과 같으면, 값의 크기의 10%(값이 0 이면 1)만큼 위아래로 범위를 만든 뒤 눈금에 맞춰 넓힙니다. 그래서 선이 그래프의 위아래 끝에 붙지 않습니다. 모두 0 이면 기본 설정의 눈금은 `-1.0` 에서 `1.0` 까지입니다. 값과 다른 `referenceValue` 가 있으면 이 여유를 더하지 않고 두 값의 범위로 축을 잡습니다.

<Preview demo="trend-chart/flat" />

`bar` 의 값 축은 0 과 그 값을 함께 담습니다.

<Note>

`bar` 에서 값이 모두 0 이고 `referenceValue` 가 없거나 0 이면 값 축의 범위가 0 이 되어 막대와 기준선의 위치를 계산할 수 없습니다. Flutter 디버그 빌드에서는 그리는 중에 assert 가 실패하고, Web 은 막대 높이가 올바른 CSS 값이 되지 않아 막대가 보이지 않습니다. 이런 데이터는 `points` 를 비워 `empty` 를 보이거나 `line` 으로 그립니다.

</Note>

### 로딩

로딩 상태를 정하는 속성은 없습니다. 데이터를 받는 동안에는 호출자가 같은 자리에 [Skeleton](/components/skeleton) 을 둡니다.

### 애니메이션

그래프에는 전환 애니메이션이 없습니다. 데이터가 바뀌면 바로 다시 그립니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 구독자 · 사용량 · 환율 · 매출처럼 한 지표가 시간에 따라 어떻게 움직였는지 보여 줄 때
- 기간을 바꿔 가며 같은 지표를 다시 볼 때 — `periods`
- 목표나 예산과 견주어 지금 위치를 보여 줄 때 — `referenceValue`

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 추이 없이 지금 값과 변동만 보여 줄 때 | [Stat](/components/stat) |
| 기간별 상태(정상 · 주의 · 장애)를 색 구간으로 보여 줄 때 | [Tracker](/components/tracker) |
| 작업 하나의 완료 비율을 보여 줄 때 | [Progress](/components/progress) |
| 한 시점의 합계가 항목별로 어떻게 나뉘는지 보여 줄 때 | [CategoryBreakdown](/components/category-breakdown) |

여러 시리즈를 견주려면 차트를 시리즈마다 하나씩 나란히 둡니다. 차트마다 값 축을 따로 잡으므로 높이만 보고 크기를 견주지 않게 합니다.

<a id="do"></a>
<a id="dont"></a>

### 날짜와 값의 글

<Cards columns="2">
<Card demo="trend-chart/do-labels" tone="do" eyebrow="이렇게 하세요">

`label` 과 `valueLabel` 을 사용자의 언어와 단위에 맞춰 넘깁니다. 차트는 날짜를 현지 형식으로 바꾸지 않습니다.

</Card>
<Card demo="trend-chart/dont-labels" tone="dont" eyebrow="이렇게 하지 마세요">

`label` 을 비우면 날짜 축에 `2026-06-01` 같은 글이 나오고, 좁은 폭에서는 잘립니다.

</Card>
</Cards>

```dart
CoreTrendPoint(date: DateTime(2026, 9), value: 12480, label: '9월', valueLabel: '12,480명')
```

### 작은 변화는 line 으로

<Cards columns="2">
<Card demo="trend-chart/do-scale" tone="do" eyebrow="이렇게 하세요">

값에 비해 작은 변화를 보여 줄 때는 `line` 을 씁니다. 축이 0 에서 시작하지 않을 수 있으므로 선의 높낮이는 값 축의 눈금과 함께 읽습니다.

</Card>
<Card demo="trend-chart/dont-scale" tone="dont" eyebrow="이렇게 하지 마세요">

`bar` 는 늘 0 에서 자라므로 9,980 과 10,020 의 차이가 거의 보이지 않습니다.

</Card>
</Cards>

### 기준선의 글

<Cards columns="2">
<Card demo="trend-chart/do-reference" tone="do" eyebrow="이렇게 하세요">

`referenceLabel` 에 기준선의 뜻과 수치를 함께 적습니다.

</Card>
<Card demo="trend-chart/dont-reference" tone="dont" eyebrow="이렇게 하지 마세요">

점선만 그리면 무엇의 기준인지 알 수 없고, 보조 기술에는 기준선이 전달되지 않습니다.

</Card>
</Cards>

## 배치

- 차트는 부모의 폭을 채웁니다. Flutter 에서는 폭이 정해진 부모 안에 둡니다. `Row` 안에서는 `Expanded` 나 폭을 정한 상자로 감쌉니다.
- 전체 높이는 놓인 부분과 그 사이 간격을 더한 값입니다. 부모가 더 높아도 그래프는 남는 높이를 채우지 않습니다.
- `plotHeight`(기본 160)는 그래프의 최소 높이입니다. 큰 글자처럼 값 축 라벨에 더 많은 높이가 필요하면 그래프가 그만큼 커집니다. 날짜 축은 이 높이 아래에 따로 놓입니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

겉모습(색 · 크기 · 간격)은 `trendChartStyle` 하나로 바꿉니다. 앱 전체의 기본값은 `CoreComponentTheme.trendChart` 에 둡니다. 시리즈 색 `seriesColor` 하나가 선, 표식, 막대에 함께 쓰입니다.

<Preview demo="trend-chart/styled" />

<Split>

<Code language="dart" title="차트 하나만 바꾸기">
TrendChart(
  points: points,
  trendChartStyle: const CoreTrendChartStyle(
    seriesColor: CoreColor.token(CoreColors.success),
    lineWidth: CoreStrokeWidth.stroke3,
    plotHeight: CoreSpace.space120,
    axisTickCount: 2,
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: const CoreComponentTheme(
    trendChart: CoreTrendChartTheme(
      style: CoreTrendChartStyle(plotHeight: CoreSpace.space120),
      variantStyles: {
        CoreTrendChartVariant.bar: CoreTrendChartStyle(barSpacing: CoreSpace.space8),
      },
    ),
  ),
)
</Code>

</Split>

### 값이 정해지는 순서

뒤로 갈수록 우선합니다. `axisLabelStyle`, `legendLabelStyle`, `periodChipStyle` 은 적은 항목만 덮어쓰고 나머지는 앞의 값을 이어받습니다.

```text
CoreTrendChartStyle.default*                       // 디자인 시스템 기본값
  → CoreTrendChartTheme.style                      // 앱 전체
  → CoreTrendChartTheme.variantStyles[variant]     // variant 별
  → trendChartStyle                                // 차트 하나
```

### 기본값

- 색: 시리즈는 `primary`, 격자선은 `outlineVariant`, 기준선 · 축 글 · 범례 글은 `onSurfaceVariant` 입니다.
- 선: 시리즈 선 2, 격자선과 기준선 1 입니다. 점선은 길이 3, 사이 2 이고 표식의 지름은 8 입니다.
- 크기와 간격: 그래프 최소 높이 160, 막대 사이 4, 구역 사이 12, 축 라벨 간격 8, 기간 칩 사이 8, 범례의 점선 폭 16 과 글까지의 간격 8 입니다.
- 글자: 축 라벨은 `labelSmall`, 범례 글은 `labelMedium` 입니다.

기간 칩의 모양은 `periodChipStyle`(`CoreChipStyle`)로 모든 칩에 넘깁니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

이미 만든 `TrendChart` 에 `withStyle` 로 스타일을 덧붙일 수 있습니다. `trendChartStyle` 에 넘기는 것과 같고, 겹치는 항목은 뒤에 붙인 값이 이깁니다.

<Preview component="trend-chart" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class TrendChartChainExample extends StatefulWidget {
  const TrendChartChainExample({super.key});

  @override
  State<TrendChartChainExample> createState() => _TrendChartChainExampleState();
}

class _TrendChartChainExampleState extends State<TrendChartChainExample> {
  @override
  Widget build(BuildContext context) {
    return TrendChart(
      semanticLabel: '월별 구독자 추이',
      points: [
        CoreTrendPoint(date: DateTime(2026, 4), value: 8200, label: '4월', valueLabel: '8,200명'),
        CoreTrendPoint(date: DateTime(2026, 5), value: 9100, label: '5월', valueLabel: '9,100명'),
        CoreTrendPoint(date: DateTime(2026, 6), value: 8800, label: '6월', valueLabel: '8,800명'),
        CoreTrendPoint(date: DateTime(2026, 7), value: 10400, label: '7월', valueLabel: '10,400명'),
        CoreTrendPoint(date: DateTime(2026, 8), value: 11200, label: '8월', valueLabel: '11,200명'),
        CoreTrendPoint(date: DateTime(2026, 9), value: 12480, label: '9월', valueLabel: '12,480명'),
      ],
    ).withStyle(
      const CoreTrendChartStyle(
        plotHeight: CoreSpace.space120,
        lineWidth: CoreStrokeWidth.stroke3,
        seriesColor: CoreColor.token(CoreColors.secondary),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class TrendChartChainExample extends StatefulComponent {
  const TrendChartChainExample({super.key});

  @override
  State<TrendChartChainExample> createState() => _TrendChartChainExampleState();
}

class _TrendChartChainExampleState extends State<TrendChartChainExample> {
  @override
  Component build(BuildContext context) {
    return TrendChart(
      semanticLabel: '월별 구독자 추이',
      points: [
        CoreTrendPoint(date: DateTime(2026, 4), value: 8200, label: '4월', valueLabel: '8,200명'),
        CoreTrendPoint(date: DateTime(2026, 5), value: 9100, label: '5월', valueLabel: '9,100명'),
        CoreTrendPoint(date: DateTime(2026, 6), value: 8800, label: '6월', valueLabel: '8,800명'),
        CoreTrendPoint(date: DateTime(2026, 7), value: 10400, label: '7월', valueLabel: '10,400명'),
        CoreTrendPoint(date: DateTime(2026, 8), value: 11200, label: '8월', valueLabel: '11,200명'),
        CoreTrendPoint(date: DateTime(2026, 9), value: 12480, label: '9월', valueLabel: '12,480명'),
      ],
    ).withStyle(
      const CoreTrendChartStyle(
        plotHeight: CoreSpace.space120,
        lineWidth: CoreStrokeWidth.stroke3,
        seriesColor: CoreColor.token(CoreColors.secondary),
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

동작 줄이기, 고대비, 색 강제 모드, 최소 터치 타깃처럼 모든 컴포넌트에 공통인 항목은 [전역 접근성 축](/accessibility)에 있습니다.

### 역할

| 부분 | Flutter | Web |
| --- | --- | --- |
| 그래프 영역 | `Semantics(container: true, explicitChildNodes: true)` 노드. 이름은 `semanticLabel` 입니다. | `role="group"`. `aria-label` 은 `semanticLabel` 입니다. |
| 점 | 점마다 이름을 가진 노드 하나. 목록 역할은 없습니다. | `role="list"` 안의 `role="listitem"`. 글 내용 없이 `aria-label` 로 이름을 가집니다. |
| 기간 칩 | `onPeriodChanged` 가 있으면 버튼입니다. | `onPeriodChanged` 가 있으면 `role="button"` 입니다. |

### 키보드

그래프가 처리하는 키는 없습니다. `onPeriodChanged` 가 있으면 기간 칩마다 `Tab` 으로 이동하고 `Enter` 나 `Space` 로 누릅니다. 차트가 칩 사이에 더하는 방향키 이동은 없습니다. `onPeriodChanged` 가 없으면 칩은 `Tab` 순서에 들어가지 않습니다.

### 스크린 리더

- 그래프 영역의 이름은 `semanticLabel` 이고, 그 안에 점이 목록 순서대로 「날짜, 값」 이름으로 놓입니다. 글은 [점 데이터](#점-데이터)의 규칙으로 만듭니다.
- 값 축과 날짜 축은 숨기므로, 그래프의 점 데이터는 이 이름들로 전달합니다. 별도의 데이터 표는 만들지 않습니다.
- 값 축 라벨, 날짜 축 라벨, 격자선, 선, 막대, 표식, 기준선, 범례의 점선은 보조 기술에서 숨깁니다. Flutter 는 `ExcludeSemantics`, Web 은 `aria-hidden` 을 씁니다.
- 범례의 `referenceLabel` 은 글로 남습니다.
- `summary` 와 `empty` 의 내용은 넘긴 위젯이 알리는 대로 전달됩니다.
- 데이터가 바뀌었다고 따로 알리는 라이브 영역은 없습니다.

### 포커스 관리

그래프와 점 구간은 포커스를 받지 않습니다. 포커스를 옮기거나 가두지 않습니다. 포커스를 받는 부분은 누를 수 있는 기간 칩입니다. `summary` 와 `empty` 에 넣은 조작 요소는 자기 동작을 따릅니다.

### 알려진 제약

- 툴팁은 마우스를 올려 엽니다. 키보드 포커스로는 열 수 없습니다. Flutter 는 터치로도 열리지 않고, Web 은 `mouseenter` 와 `mouseleave` 로 여닫습니다. 같은 글은 각 점의 접근 가능한 이름에 있지만 화면에 따로 적히지는 않습니다. 툴팁을 열 수 없으면 화면의 그래프에서 점의 값을 읽을 단서는 선이나 막대의 높이와 값 축 눈금뿐이고, 날짜 글은 날짜 축의 라벨(최대 셋)만 보입니다. 꼭 보여야 하는 값은 `summary` 에 적습니다.
- 선택된 기간 칩은 겉모습으로만 구분됩니다. 선택 상태가 보조 기술에 전달되지 않습니다. 고른 기간을 알려야 하면 `summary` 의 글에 함께 적습니다.
- `referenceLabel` 이 없으면 기준선은 보조 기술에 전달되지 않습니다.
- `semanticLabel` 을 비우면 그래프 영역에 이름이 없습니다.
- `points` 가 비면 그래프 영역이 없으므로 `semanticLabel` 도 쓰이지 않습니다. 무엇의 데이터가 없는지는 `empty` 의 글에 적습니다.
- 시리즈는 하나입니다.
- 점은 시간 간격과 상관없이 목록 순서대로 같은 간격에 놓입니다.
- Web 에는 색 강제 모드(forced-colors)를 위한 `TrendChart` 전용 스타일이 없습니다. Chrome 의 강제 색 모드 에뮬레이션에서는 막대, 격자선, 마지막 점 표식이 보이지 않고 선과 기준선은 남았습니다. 고른 기간 칩도 다른 칩과 같게 보였습니다. 값은 `summary` 같은 글로도 보여 주세요.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

클래스 이름 `TrendChart` 와 속성 이름은 같습니다. 값 축의 범위, 눈금, 점의 위치, 날짜 라벨은 두 플랫폼이 같은 `CoreTrendChartGeometry` 로 계산합니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 그리는 방식 | `CustomPaint` 하나에 격자선 · 기준선 · 선 또는 막대 · 표식을 그립니다. | 격자선 · 막대 · 표식은 `<div>`, 선과 점선은 인라인 `<svg>` 입니다. |
| 위치 | 계산한 비율을 픽셀로 바꿉니다. | 계산한 비율을 퍼센트로 씁니다. |
| 오른쪽→왼쪽 | 그래프를 좌우로 뒤집어 그리고, 점 구간과 날짜 라벨의 `Row` 도 방향을 따릅니다. | 막대와 표식은 `inset-inline-start` 로 놓고, 선은 `rtl:-scale-x-100` 클래스로 뒤집습니다. |
| 점의 접근성 구조 | 그래프 노드 아래의 점 노드. 목록 역할은 없습니다. | `list` 와 `listitem` 역할 |
| 툴팁 | `Tooltip` 위젯. 마우스 포인터가 올라올 때 엽니다. | `Tooltip` 컴포넌트. `mouseenter` 로 엽니다. |
| 폭 | 폭이 정해진 부모가 필요합니다. | 부모의 폭을 채웁니다. |
| 크기 배율 | 선 굵기, 점선, 표식, 모서리, 막대 사이, 그래프 최소 높이, 범례의 점선 폭, 구역 · 라벨 · 칩 · 범례 간격에 테마의 크기 배율을 곱합니다. | 그래프 최소 높이, 표식, 막대 사이, 간격, 범례의 점선 폭은 `rem` 기준입니다. 선 굵기와 점선 길이는 `px` 입니다. |
| 밀도 | `sectionSpacing` · `axisLabelSpacing` · `legendSpacing` · `periodSpacing` 이 앱의 밀도를 따릅니다. `barSpacing` 은 따르지 않습니다. | 같은 네 간격은 값이 `CoreSpace` 단계일 때 밀도를 따릅니다. `barSpacing` 은 따르지 않습니다. |
| 값이 모두 0 인 `bar` | 위 [조건](#값이-모두-같을-때)에서 디버그 빌드의 assert 가 실패합니다. | 막대가 보이지 않습니다. |
| 웹 전용 속성 | — | `id` · `classes` · `css` · `attributes` 를 루트 `<div>` 에 붙입니다. |

<a id="props-parameters"></a>

## API

### 생성자

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `points` | `List<CoreTrendPoint>` | 필수 | 표시할 시계열. 오래된 것부터 넘깁니다. |
| `variant` | `CoreTrendChartVariant` | `line` | 선(`line`) 또는 막대(`bar`) |
| `referenceValue` | `double?` | `null` | 점선 기준선의 값(목표 · 예산) |
| `referenceLabel` | `String?` | `null` | 기준선 범례의 글. `referenceValue` 와 함께 있고 점이 있을 때 범례가 보입니다. |
| `valueFormatter` | `String Function(double value)?` | `null` | 값 축 눈금과 `valueLabel` 이 없는 점의 값을 글로 바꿉니다. 비우면 눈금 간격의 소수 자릿수를 쓰는 숫자입니다. |
| `periods` | `List<String>` | `const []` | 기간 칩의 글. 비면 칩 줄이 없습니다. |
| `selectedPeriodIndex` | `int?` | `null` | 선택된 모양으로 보일 칩의 번호(0부터) |
| `onPeriodChanged` | `void Function(int index)?` | `null` | 칩을 누르면 그 번호로 불립니다. `null` 이면 칩을 누를 수 없습니다. |
| `summary` | `Widget?` (Web `Component?`) | `null` | 차트 위의 요약 슬롯 |
| `empty` | `Widget?` (Web `Component?`) | `null` | `points` 가 비었을 때 그래프 자리에 놓을 내용 |
| `semanticLabel` | `String?` | `null` | 그래프 영역의 접근 가능한 이름 |
| `trendChartStyle` | `CoreTrendChartStyle?` | `null` | 이 차트의 겉모습(색 · 크기 · 간격)을 바꿉니다. |

### CoreTrendPoint

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `date` | `DateTime` | 필수 | 점이 가리키는 시점. 위치를 정하지 않고, `label` 이 없을 때의 글에 쓰입니다. |
| `value` | `double` | 필수 | 측정값. 유한한 수여야 하며 음수를 넘길 수 있습니다. |
| `label` | `String?` | `null` | 형식을 맞춘 날짜 글. 비우면 `yyyy-MM-dd` 입니다. |
| `valueLabel` | `String?` | `null` | 형식을 맞춘 값 글. 툴팁과 점의 접근 가능한 이름에 쓰입니다. |

### 웹 전용

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트 `<div>` 의 `id` |
| `classes` | `String?` | `null` | 루트에 더하는 CSS 클래스 |
| `css` | `Styles?` | `null` | 루트에 더하는 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 루트에 더하는 HTML 속성 |
| `tag` | `String` | `'div'` | 생성자가 받지만 결과에 반영되지 않습니다. 루트는 늘 `<div>` 입니다. |

### 그 밖의 멤버

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `withStyle(CoreTrendChartStyle patch)` | `TrendChart` | — | `trendChartStyle` 에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 항목은 `patch` 가 이깁니다. |

`copyWith` 는 넘긴 값만 바꾼 사본을 만듭니다. `null` 을 넘겨 값을 비울 수는 없습니다. Web 의 `classes` 는 바꾸지 않고 기존 값 뒤에 더합니다.

### 테마

`CoreComponentTheme.trendChart` 에 `CoreTrendChartTheme` 를 둡니다.

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CoreTrendChartStyle?` | `null` | 모든 `TrendChart` 에 적용합니다. |
| `variantStyles` | `Map<CoreTrendChartVariant, CoreTrendChartStyle>?` | `null` | 해당 `variant` 에만 `style` 다음으로 적용합니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreTrendChartStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `seriesColor` | `CoreColor?` | Colour of the line, its end marker and the bars. |
| `gridColor` | `CoreColor?` | Colour of the horizontal grid lines at each axis tick. |
| `referenceColor` | `CoreColor?` | Colour of the dashed reference line and its legend swatch. |
| `lineWidth` | `double?` | Stroke width of the series line (logical px). |
| `gridLineWidth` | `double?` | Stroke width of each grid line (logical px). |
| `referenceLineWidth` | `double?` | Stroke width of the reference line (logical px). |
| `referenceDashLength` | `double?` | Length of one dash of the reference line (logical px). |
| `referenceDashSpacing` | `double?` | Gap between two dashes of the reference line (logical px). |
| `markerSize` | `double?` | Diameter of the marker on the last point of a line (logical px). |
| `markerBorderRadius` | `CoreBorderRadius?` | Corner radius of the last-point marker. |
| `barSpacing` | `double?` | Horizontal space between two adjacent bars (logical px). |
| `barBorderRadius` | `CoreBorderRadius?` | Corner radius of a bar's far end — the end away from the zero baseline. The baseline end stays square. |
| `plotHeight` | `double?` | Minimum height of the plot area (logical px). The plot grows when the axis labels need more room (large text). |
| `sectionSpacing` | `double?` | Vertical space between the summary, the period chips, the plot and the legend (logical px). Flows into `Column.spacing` / CSS `gap`. |
| `axisLabelSpacing` | `double?` | Space between the value axis labels and the plot, and between the plot and the date labels (logical px). |
| `axisTickCount` | `int?` | Target number of value-axis intervals. The axis rounds to a nice step, so the drawn count can differ by one. |
| `axisLabelStyle` | `CoreTextStyle?` | Typography of the value-axis and date-axis labels. |
| `legendLabelStyle` | `CoreTextStyle?` | Typography of the reference-line legend text. |
| `legendSpacing` | `double?` | Space between the legend swatch and its text (logical px). |
| `legendSwatchWidth` | `double?` | Width of the dashed legend swatch (logical px). |
| `periodSpacing` | `double?` | Space between period chips, both along a row and between wrapped rows (logical px). |
| `periodChipStyle` | `CoreChipStyle?` | Style for the period chips, passed to every period `Chip`. |

<!-- STYLE_TABLE:END -->

<Note>

`axisTickCount` 로 정한 목표와 실제 구간 수의 차이는 하나보다 클 수 있습니다. 예를 들어 목표가 4 일 때 `line` 에 0 과 81 을 넘기면 두 구간입니다. `axisLabelSpacing` 은 날짜 라벨끼리의 간격에도 쓰입니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="trend-chart/related-stat" title="Stat" href="/components/stat" more="Stat 보기">

지금 값과 변동을 카드 한 장에 담습니다. `summary` 슬롯에 넣을 수 있습니다.

</Card>
<Card demo="trend-chart/related-tracker" title="Tracker" href="/components/tracker" more="Tracker 보기">

기간별 상태를 색 구간 한 줄로 보여 줍니다.

</Card>
<Card demo="trend-chart/related-progress" title="Progress" href="/components/progress" more="Progress 보기">

작업 하나의 진행 비율을 보여 줍니다.

</Card>
<Card demo="trend-chart/related-chip" title="Chip" href="/components/chip" more="Chip 보기">

기간 칩에 쓰이는 컴포넌트입니다.

</Card>
</Cards>
