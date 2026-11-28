---
title: CategoryBreakdown
description: 합계가 카테고리별로 어떻게 나뉘는지 가로 막대나 도넛과 범례로 보여 주는 분포 컴포넌트입니다.
category: display
platforms: [flutter, web]
related: [trend-chart, progress, stat]
tags: [breakdown, distribution, chart, donut, dashboard, display]
template: v2
source: display/category_breakdown
---

# CategoryBreakdown

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

한 시점의 합계가 카테고리별로 어떻게 나뉘는지 보여 줍니다. 속성을 바꿔 보며 확인하고, 만들어진 코드를 그대로 복사하세요. 필수 값은 `items` 하나이고, 기본 variant는 `bar` 입니다. Flutter와 Web 코드가 같습니다.

<Playground component="category-breakdown" />

- `donut` 을 고르면 `center` 에 합계를 넣은 코드가 됩니다. 컴포넌트는 합계 글을 만들지 않으므로 직접 넘깁니다.
- "valueLabel 빼기" 를 켜면 막대 · 범례의 값이 컴포넌트의 [기본 숫자 표기](#값-표기)로 바뀝니다. `center` 의 합계 글은 직접 넘긴 것이라 그대로입니다.
- "색 목록 바꾸기" 는 `categoryBreakdownStyle` 의 `seriesColors` 를 바꿉니다.

## 구조

variant마다 부분이 다릅니다. 값과 비율은 두 variant 모두 라벨과 같은 줄에 놓이고, 폭이 모자라면 라벨 아래로 내려갑니다.

### 막대의 부분

<Anatomy demo="category-breakdown/anatomy">
<AnatomyItem part="container" name="Container">

항목을 `items` 순서대로 위에서 아래로 쌓는 목록입니다. 행 사이 간격은 `rowSpacing` 입니다.

</AnatomyItem>
<AnatomyItem part="label" name="label">

항목의 `label` 입니다. 글자 스타일은 `labelStyle` 입니다.

</AnatomyItem>
<AnatomyItem select="[role=listitem] > div > span + span > span:first-child" side="top" name="value">

항목의 `valueLabel` 입니다. 없으면 `value` 를 숫자로 적습니다. 글자 스타일은 `valueStyle` 입니다.

</AnatomyItem>
<AnatomyItem select="[role=listitem] > div > span + span > span + span" side="right" name="percent">

합계에서 차지하는 정수 퍼센트입니다. 컴포넌트가 계산합니다. 글자 스타일은 `percentStyle` 입니다.

</AnatomyItem>
<AnatomyItem select="[role=listitem] + [role=listitem] > div + div" side="right" name="track">

막대의 바탕입니다. 두께는 `barHeight`, 색은 `trackColor`, 모서리는 `barBorderRadius` 입니다.

</AnatomyItem>
<AnatomyItem select="[role=listitem] + [role=listitem] > div + div > div" side="left" name="fill">

항목의 몫만큼 트랙을 채웁니다. 읽기 시작 쪽에서 자랍니다.

</AnatomyItem>
</Anatomy>

### 도넛의 부분

<Anatomy demo="category-breakdown/anatomy-donut">
<AnatomyItem part="container" name="Container">

도넛과 범례를 함께 담습니다. 둘 사이 간격은 `legendSpacing` 입니다.

</AnatomyItem>
<AnatomyItem select="svg" side="top" name="ring">

항목마다 몫만큼의 호를 12시 방향부터 그립니다. 지름은 `donutSize`, 두께는 `donutThickness`, 호 사이 간격은 `donutSegmentSpacing` 입니다. 막대의 트랙 같은 바탕 링은 없습니다.

</AnatomyItem>
<AnatomyItem select="svg + div > span" side="top" name="center">

`center` 슬롯입니다. 도넛 가운데에 놓이고, 직접 스타일을 주지 않은 글에는 `valueStyle` 이 적용됩니다.

</AnatomyItem>
<AnatomyItem select="[role=listitem] > span[aria-hidden]" side="top" name="swatch">

호와 같은 색의 견본입니다. 크기는 `swatchSize`, 모서리는 `swatchBorderRadius` 입니다.

</AnatomyItem>
<AnatomyItem select="[role=list]" side="right" name="legend">

항목마다 견본 · 라벨 · 값 · 비율을 적는 범례입니다. 행 사이 간격은 `rowSpacing` 입니다.

</AnatomyItem>
</Anatomy>

<a id="변형-variants"></a>

## Variant

`variant` 는 `CoreCategoryBreakdownVariant` 의 `bar`(기본) · `donut` 중 하나입니다. 컴포넌트가 폭을 보고 variant를 바꾸지는 않으므로, 화면에 맞는 것을 직접 고릅니다.

### bar

<VariantRow name="bar" component="category-breakdown" props="variant=bar;count=3">

항목마다 라벨 · 값 · 비율을 한 줄에 적고, 그 아래에 합계 대비 가로 막대를 그립니다. 라벨이 막대 바로 위에 있어 색과 범례를 번갈아 볼 필요가 없고, 폭이 좁거나 글자가 크거나 라벨이 길면 [줄을 바꿔](#줄바꿈) 담습니다. 기본값입니다.

</VariantRow>

### donut

<VariantRow name="donut" component="category-breakdown" props="variant=donut;count=3">

링 하나에 항목마다 호를 그리고 범례를 둡니다. 호는 12시 방향에서 시계 방향으로 놓입니다. 범례는 폭이 넉넉하면 도넛 옆에, 좁으면 아래에 놓입니다([범례 위치](#범례-위치)). `center` 슬롯은 이 variant에서만 그립니다.

</VariantRow>

## 항목과 비율

### 항목 데이터

항목 하나는 `CoreCategoryBreakdownItem` 입니다. `items` 에 적은 순서대로 그리며, 값의 크기로 다시 정렬하지 않습니다. `label` 과 `valueLabel` 은 넘긴 글을 그대로 적으므로 언어와 단위에 맞춰 만들어 넘깁니다.

```dart
CategoryBreakdown(
  semanticLabel: '문의 유형별 분포',
  items: const [
    CoreCategoryBreakdownItem(label: '결제 문의', value: 128, valueLabel: '128건'),
    CoreCategoryBreakdownItem(label: '배송 문의', value: 61, valueLabel: '61건'),
    // valueLabel 이 없으면 12 로 적습니다. color 는 이 항목에만 적용됩니다.
    CoreCategoryBreakdownItem(label: '기타', value: 12, color: CoreColor.token(CoreColors.outline)),
  ],
)
```

### 비율

비율은 모든 항목의 합계에서 그 항목이 차지하는 몫입니다. 음수는 0으로 셉니다. 막대의 길이와 호의 길이는 반올림하지 않은 몫을 쓰고, 글로 적는 퍼센트만 정수로 맞춥니다.

정수 퍼센트는 **최대 잔여 반올림**을 씁니다. 먼저 모두 내림하고, 100에서 모자란 만큼을 버린 소수점 아래 값이 큰 항목부터 1씩 더합니다. 계산된 값이 똑같으면 앞 항목이 먼저이고, 몫이 0인 항목에는 더하지 않습니다. 그래서 합계가 0보다 크면 적힌 퍼센트의 합은 100이고, 값이 같은 세 항목은 34 · 33 · 33입니다.

<Preview demo="category-breakdown/rounding" />

- 값이 같은 항목끼리는 앞 항목이 먼저입니다. 값이 서로 다르면 버린 부분이 수학적으로 같아도 부동소수점 오차 때문에 앞 항목이 먼저가 아닐 수 있습니다. 예를 들어 값 `1` · `4` · `1` 은 17 · 66 · 17로 적힙니다.
- 아주 작은 몫은 `0%` 로 적힐 수 있습니다. 막대는 실제 몫만큼 그립니다.
- `donut` 에서는 몫이 있는 항목이 둘 이상이면 호마다 `donutSegmentSpacing` 만큼의 간격을 뺍니다. 몫이 그 간격 이하인 항목은 호가 그려지지 않고 범례에만 남습니다. 기본 크기에서는 약 0.47% 이하입니다.
- 두 플랫폼이 `CoreCategoryBreakdownGeometry` 의 같은 계산을 써서 같은 숫자를 보입니다. 둘레의 글에도 같은 퍼센트가 필요하면 `CoreCategoryBreakdownGeometry.compute(values).percents` 를 씁니다.

### 값 표기

`valueLabel` 이 있으면 그대로 적습니다. 없으면 `value` 를 천 단위 구분 없이 라틴 숫자로 적습니다. 정수는 소수점 없이(`128`), 나머지는 소수 둘째 자리까지 반올림하고 끝의 0을 뗍니다(`2.5`, `1.234` → `1.23`). 음수는 비율에서만 0으로 세고, 값 글은 넘긴 음수 그대로입니다.

`value` 에는 유한한 수를 넘기세요. `double.infinity` 가 들어가면 그리는 도중 오류가 나고, `double.nan` 이 섞이면 모든 비율이 0%가 됩니다.

<a id="동작-스펙-behavior"></a>

## 상태

누르기 · 호버 · 선택 · 비활성 상태가 없는 표시 전용 컴포넌트입니다. 화면이 달라지는 것은 데이터에 따라서입니다.

<Preview demo="category-breakdown/states" />

### 상태 전환

| 상황 | 그리는 것 |
| --- | --- |
| 항목 없음 | `empty` 슬롯만 그립니다. `empty` 를 주지 않으면 아무것도 보이지 않습니다. |
| 합계 0 | 위와 같습니다. 모든 값이 0 이하인 경우입니다. |
| 일부 값이 0 이하 | 행은 남고 `0%` 입니다. `bar` 는 채움이 없는 막대를, `donut` 은 호 없이 범례 행만 그립니다. |
| 몫이 하나뿐 | 그 항목이 `100%` 입니다. `donut` 은 틈 없는 링이 됩니다. |

`empty` 를 그릴 때는 그 위젯만 놓입니다. `semanticLabel` 은 붙지 않고, Web의 `id` · `classes` · `css` · `attributes` 도 적용되지 않습니다.

```dart
CategoryBreakdown(
  semanticLabel: '문의 유형별 분포',
  items: items,
  empty: Text('이번 달에는 문의가 없어요').bodyMedium.onSurfaceVariant,
)
```

로딩 상태를 받는 속성은 없습니다. 데이터를 기다리는 동안에는 이 컴포넌트 대신 같은 자리에 [Skeleton](/components/skeleton)을 그리세요. 그동안 빈 목록을 넘기면 로딩이 아니라 `empty` 가 보입니다.

### 애니메이션

컴포넌트에 전환 애니메이션이 없습니다. 값 · variant · 스타일이 바뀌면 새 모습으로 바로 그립니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 문의 유형 · 지출 항목 · 유입 경로 · 등급처럼 합계를 이루는 카테고리의 몫을 보여 줄 때
- 대시보드나 통계 화면에서 구성비를 한눈에 비교할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우 | 대신 쓸 컴포넌트 |
| --- | --- |
| 시간에 따른 변화 | [TrendChart](/components/trend-chart) |
| 작업 하나의 진행률 | [Progress](/components/progress) |
| 비율 없이 숫자 하나 | [Stat](/components/stat) |

<a id="do"></a>
<a id="dont"></a>

### 권장과 금지

<Cards columns="2">
<Card demo="category-breakdown/do-bar" tone="do" eyebrow="이렇게 하세요">

좁은 화면이거나 라벨이 길면 기본 `bar` 를 씁니다. 라벨 · 값 · 비율이 한 행에 있어 색을 구별하지 않아도 어느 항목인지 읽을 수 있고, 폭이 모자라면 줄이 바뀝니다.

</Card>
<Card demo="category-breakdown/dont-mixed" tone="dont" eyebrow="이렇게 하지 마세요">

합계를 이루지 않는 값을 섞지 않습니다. 건수 사이에 평균 응답 시간을 넣어도 모두 더해 나누므로, 화면의 비율이 아무 뜻도 없게 됩니다.

</Card>
<Card demo="category-breakdown/do-grouped" tone="do" eyebrow="이렇게 하세요">

몫이 작은 항목은 앱에서 합쳐 `기타` 한 항목으로 넘깁니다. 컴포넌트는 항목을 합치거나 개수를 줄이지 않습니다.

</Card>
<Card demo="category-breakdown/dont-many" tone="dont" eyebrow="이렇게 하지 마세요">

색을 정하지 않고 일곱 항목 이상을 넣지 않습니다. 기본 색은 여섯 가지라 일곱째 항목이 첫째와 같은 색이 됩니다.

</Card>
<Card demo="category-breakdown/do-short-center" tone="do" eyebrow="이렇게 하세요">

`center` 에는 합계처럼 짧은 값을 넣습니다. 기본 크기에서 가운데 구멍의 지름은 112입니다.

</Card>
<Card demo="category-breakdown/dont-long-center" tone="dont" eyebrow="이렇게 하지 마세요">

긴 글을 넣지 않습니다. 컴포넌트는 가운데 내용을 구멍 크기에 맞춰 줄이거나 자르지 않아, 글이 링과 겹칩니다.

</Card>
</Cards>

## 배치

### 폭

두 variant 모두 부모의 폭을 채우고, 항목 수만큼 아래로 길어집니다. 안에 스크롤은 없습니다.

Flutter에서는 부모가 폭의 상한을 정해 줘야 합니다. `Row` 처럼 자식의 폭을 제한하지 않는 부모에 바로 놓으면 레이아웃 오류가 납니다. `Expanded` 로 감싸거나 `SizedBox` 의 `width` 로 폭을 정하세요. 또 `bar` 에 몫이 0인 항목이 있으면 `IntrinsicWidth` 처럼 내용의 폭을 먼저 묻는 위젯으로 감싸지 마세요. 채움이 없는 막대 때문에 폭을 계산하지 못합니다.

```dart
// Flutter
Row(
  children: [
    Expanded(
      child: CategoryBreakdown(semanticLabel: '문의 유형별 분포', items: items),
    ),
  ],
)
```

도넛은 폭이 지름보다 좁아져도 줄어들지 않습니다. 아주 좁은 자리에는 `bar` 를 쓰거나 `donutSize` 를 줄이세요.

### 줄바꿈

라벨과 값 · 비율이 한 줄에 들어가면 양 끝에 놓고, 들어가지 않으면 값 · 비율이 라벨 아래로 내려갑니다. 긴 라벨은 말줄임 없이 여러 줄이 됩니다. 라벨 · 값 · 비율에는 줄 수 제한이 없어, 글자를 크게 키워도 같은 방식으로 줄이 바뀝니다. `donut` 의 범례 행도 같습니다.

<Preview demo="category-breakdown/placement-wrap" />

### 범례 위치

`donut` 은 받은 폭이 `donutSize × 2 + legendSpacing` 보다 좁으면 범례를 도넛 아래에 전체 폭으로 놓습니다. 그 이상이면 도넛 옆에 놓고 둘을 세로 가운데로 맞춥니다. 기본값에서 경계는 336이고, 두 플랫폼의 기준이 같습니다. 아래 두 상자 가운데 넓은 것도 화면이 좁아 경계에 못 미치면 범례가 아래로 갑니다.

<Preview demo="category-breakdown/placement-legend" />

### 오른쪽에서 왼쪽으로 읽는 화면

막대는 오른쪽에서 자라고, 도넛의 호는 좌우가 뒤집혀 반시계 방향으로 놓입니다. 범례가 옆에 놓이는 폭에서는 도넛이 오른쪽, 범례가 왼쪽입니다. `center` 의 내용은 뒤집지 않습니다. Web에서는 상위 요소의 `dir="rtl"` 을 따릅니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

무엇을 그릴지는 위젯 파라미터(`variant` · `items` · `center` · `empty` · `semanticLabel`)로 넘기고, 색 · 크기 · 간격 · 글자 같은 겉모습은 `categoryBreakdownStyle`(`CoreCategoryBreakdownStyle`)로 바꿉니다. 항목 하나의 색만은 `CoreCategoryBreakdownItem` 의 `color` 로도 정할 수 있습니다.

### 값이 정해지는 순서

```text
CoreCategoryBreakdownStyle.default*                  // 디자인 시스템 기본값
  → CoreCategoryBreakdownTheme.style                 // 프로젝트 공통
  → CoreCategoryBreakdownTheme.variantStyles[variant] // variant별
  → categoryBreakdownStyle                           // 인스턴스별
```

- 뒤의 것이 앞의 것을 필드마다 덮습니다. 주지 않은 필드는 앞의 값이 남습니다.
- `labelStyle` · `valueStyle` · `percentStyle` 은 글자 스타일 안의 값끼리 합칩니다. 색만 주면 글자 역할은 기본값이 남습니다.
- `seriesColors` 는 목록 전체를 바꿉니다. 앞 단계의 목록과 한 칸씩 합치지 않습니다.
- 테마는 `CoreComponentTheme.categoryBreakdown` 에 둡니다.

### 카테고리 색

항목의 색은 순번으로 정해집니다. 첫 항목은 `seriesColors` 의 첫 색을 쓰고, 항목이 색보다 많으면 처음부터 다시 씁니다. 항목에 `color` 를 주면 그 색이 이깁니다. 그 항목도 순번 하나를 차지하므로 뒤 항목의 색은 달라지지 않습니다. `seriesColors` 에 빈 목록을 주면 `color` 가 없는 항목은 모두 `primary` 입니다.

기본 목록은 `primary` → `secondary` → `success` → `warning` → `info` → `error` 입니다.

- CoUI 기본 팔레트의 `primary` 와 `secondary` 는 둘 다 중립색이라, 기본 목록에서는 첫째와 둘째 항목의 색이 서로 아주 비슷합니다. 색으로 둘을 가려야 하면 `seriesColors` 나 항목의 `color` 를 정하세요.
- `success` · `warning` · `error` 는 상태를 말할 때도 쓰는 색입니다. 카테고리가 성공 · 경고 · 오류로 읽힐 수 있으면 색을 직접 정하세요.

### 기본값

두 variant가 함께 쓰는 값입니다.

| 필드 | 기본값 |
| --- | --- |
| `seriesColors` | 위의 여섯 색 |
| `rowSpacing` | 12 |
| `rowContentSpacing` | 6 |
| `labelSpacing` | 8 |
| `labelStyle` | `bodyMedium` · `onSurface` |
| `valueStyle` | `labelLarge` · `onSurface` |
| `percentStyle` | `labelMedium` · `onSurfaceVariant` |

`bar` 에만 적용하는 값입니다.

| 필드 | 기본값 |
| --- | --- |
| `trackColor` | `surfaceContainerHigh` |
| `barHeight` | 8 |
| `barBorderRadius` | `radius9999` |

`donut` 에만 적용하는 값입니다.

| 필드 | 기본값 |
| --- | --- |
| `donutSize` | 160 |
| `donutThickness` | 24 |
| `donutSegmentSpacing` | 2 |
| `legendSpacing` | 16 |
| `swatchSize` | 10 |
| `swatchBorderRadius` | `CoreRadiusRole.part`(4) |

앱의 밀도를 `compact` 나 `spacious` 로 바꾸면 `rowSpacing` · `rowContentSpacing` · `labelSpacing` · `legendSpacing` 이 함께 움직입니다. 기본값처럼 `CoreSpace` 단계인 값 가운데 4보다 큰 것은 4px 격자에서 한 칸씩 좁아지거나 넓어지고, 4 이하는 그대로입니다. 막대 두께, 도넛의 지름 · 두께 · 호 사이 간격, 견본 크기는 밀도에 따라 바뀌지 않습니다.

### 사용 예

<Preview demo="category-breakdown/styled" />

<Split>

<Code language="dart" title="분포 하나만 바꾸기">
CategoryBreakdown(
  semanticLabel: '문의 유형별 분포',
  items: items,
  categoryBreakdownStyle: CoreCategoryBreakdownStyle(
    barHeight: CoreSpace.space12,
    barBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    percentStyle: CoreTextStyle(color: CoreColor.token(CoreColors.onSurface)),
    seriesColors: [
      CoreColor.token(CoreColors.info),
      CoreColor.token(CoreColors.success),
      CoreColor.token(CoreColors.warning),
      CoreColor.token(CoreColors.outline),
    ],
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    categoryBreakdown: CoreCategoryBreakdownTheme(
      style: CoreCategoryBreakdownStyle(rowSpacing: CoreSpace.space16),
      variantStyles: {
        CoreCategoryBreakdownVariant.donut: CoreCategoryBreakdownStyle(
          donutThickness: CoreSpace.space16,
        ),
      },
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다. 앱 전체 예제의 `style` 은 모든 분포에, `variantStyles` 는 해당 variant에만 적용됩니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `CategoryBreakdown` 에 `withStyle` 을 이어 `categoryBreakdownStyle` 을 덧붙일 수 있습니다. 먼저 준 `categoryBreakdownStyle` 위에 합치며, 같은 필드는 `withStyle` 에 넘긴 값이 이깁니다. 아래 예는 막대 두께를 12로, 행 간격을 16으로 바꿉니다.

<Preview component="category-breakdown" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class CategoryBreakdownChainExample extends StatelessWidget {
  const CategoryBreakdownChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return CategoryBreakdown(
      semanticLabel: '문의 유형별 분포',
      items: const [
        CoreCategoryBreakdownItem(label: '결제 문의', value: 128, valueLabel: '128건'),
        CoreCategoryBreakdownItem(label: '배송 문의', value: 61, valueLabel: '61건'),
        CoreCategoryBreakdownItem(label: '계정 · 로그인', value: 33, valueLabel: '33건'),
        CoreCategoryBreakdownItem(label: '기타', value: 12, valueLabel: '12건'),
      ],
    ).withStyle(
      const CoreCategoryBreakdownStyle(
        barHeight: CoreSpace.space12,
        rowSpacing: CoreSpace.space16,
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class CategoryBreakdownChainExample extends StatelessComponent {
  const CategoryBreakdownChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return CategoryBreakdown(
      semanticLabel: '문의 유형별 분포',
      items: const [
        CoreCategoryBreakdownItem(label: '결제 문의', value: 128, valueLabel: '128건'),
        CoreCategoryBreakdownItem(label: '배송 문의', value: 61, valueLabel: '61건'),
        CoreCategoryBreakdownItem(label: '계정 · 로그인', value: 33, valueLabel: '33건'),
        CoreCategoryBreakdownItem(label: '기타', value: 12, valueLabel: '12건'),
      ],
    ).withStyle(
      const CoreCategoryBreakdownStyle(
        barHeight: CoreSpace.space12,
        rowSpacing: CoreSpace.space16,
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

항목마다 라벨 · 값 · 비율을 한 문장으로 묶은 이름을 접근성 트리에 넘깁니다. 분포 전체의 이름은 `semanticLabel` 로 줍니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 전체를 `Semantics(container: true, explicitChildNodes: true)` 로 감싸고 `semanticLabel` 을 이름으로 줍니다. 항목마다 `Semantics(label: ...)` 노드를 둡니다. 목록 · 목록 항목 역할은 붙이지 않습니다. |
| Web `bar` | 루트가 `role="list"`, 행이 `role="listitem"` 입니다. 루트의 `aria-label` 이 `semanticLabel` 입니다. |
| Web `donut` | 루트가 `role="group"` 이고 `aria-label` 이 `semanticLabel` 입니다. 그 안의 범례가 `role="list"`, 범례 행이 `role="listitem"` 입니다. 범례 목록에는 따로 이름이 없습니다. |

`semanticLabel` 을 주지 않으면 분포 전체에는 이름이 없습니다. 컴포넌트가 기본 이름을 만들지 않습니다.

Web에서는 `attributes` 의 `role` 이 적용되지 않습니다. `aria-label` 은 `semanticLabel` 을 주면 그 값이 쓰이고, 주지 않으면 `attributes` 의 값이 남습니다.

### 키보드

없음. 컴포넌트가 처리하는 키가 없습니다. `center` 나 `empty` 에 버튼 같은 컨트롤을 넣으면 그 컨트롤의 키 동작을 따릅니다.

### 스크린 리더

- 항목의 이름은 라벨 · 값 · 비율을 쉼표로 이은 것입니다. 예: `결제 문의, 128건, 55%`. 값은 화면에 적는 값과 같습니다.
- 행 안의 글 · 막대 · 견본과 도넛의 링은 같은 내용이 두 번 전해지지 않게 숨깁니다. Flutter는 `ExcludeSemantics`, Web은 `aria-hidden="true"` 를 씁니다.
- `donut` 의 `center` 는 숨기지 않으므로 항목 이름과 별개의 내용으로 남습니다. 무엇의 합계인지는 `semanticLabel` 이나 둘레의 제목에도 적어 두세요.
- 라이브 영역이 없어, 값이 바뀌어도 컴포넌트가 따로 알리지 않습니다.
- Web은 행 안의 보이는 글을 숨기므로 항목의 내용이 행의 `aria-label` 에만 있습니다. 실제로 어떻게 읽히는지는 지원할 브라우저와 스크린 리더에서 확인하세요.

### 포커스 관리

컴포넌트가 만드는 요소는 포커스를 받지 않아 Tab 순서에 들어가지 않습니다. 나타나거나 `empty` 로 바뀔 때 포커스를 옮기지 않고, 가두지도 않습니다.

### 알려진 제약

| 범위 | 내용 |
| --- | --- |
| 공통 | 항목을 누르거나 고르거나 강조하는 동작이 없습니다. |
| 공통 | `donut` 의 호에는 글자가 없어 호와 범례 행을 색과 놓인 순서로 짝지어야 합니다. 색을 가려 보기 어려운 사용자도 항목을 바로 알아야 하면 `bar` 를 씁니다. |
| 공통 | 기본 색 목록의 첫 두 색은 CoUI 기본 팔레트에서 서로 아주 비슷합니다([카테고리 색](#카테고리-색)). |
| 공통 | 기본 색은 여섯 가지라 일곱째 항목부터 색이 반복됩니다. |
| 공통 | 항목 이름의 구분 기호(`, `)와 퍼센트 표기(라틴 숫자와 `%`)를 바꾸는 속성이 없습니다. |

> 감속 모션 · 고대비 · 강제 색상 · 최소 터치 타겟처럼 전 컴포넌트에 공통으로 걸리는 축은 [전역 접근성 축](/accessibility)에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

클래스 이름 `CategoryBreakdown` 과 `variant` · `items` · `center` · `empty` · `semanticLabel` · `categoryBreakdownStyle` 은 두 플랫폼이 같습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 슬롯 타입 | `Widget?` | `Component?` |
| 막대 | `DecoratedBox` + `FractionallySizedBox` | 트랙 `<div>` 안에 퍼센트 폭의 `<div>` |
| 도넛 | `CustomPaint` 의 호 | 인라인 `<svg>` 의 `<circle>` 점선 호 |
| 범례 배치 | 전용 렌더 객체가 폭을 비교합니다. | `flex-wrap` 과 범례의 기준 폭(지름) |
| 줄바꿈 | `OverflowBar` | `flex-wrap` + `justify-between` |
| 방향 반전 | 막대는 `AlignmentDirectional`, 도넛은 호를 반대 방향으로 그립니다. | 막대는 블록 흐름, 도넛은 `rtl:-scale-x-100` |
| 폭 한계 없음 | 레이아웃 오류가 납니다. | 루트가 부모 폭의 100%를 씁니다. |
| 크기 배율 | 막대 · 간격 · 모서리 · 도넛 · 견본에 `theme.scaling` 을 곱합니다. 글자 확대 설정(`textScaler`)으로는 도넛이 커지지 않습니다. | 막대 두께 · 간격 · 도넛 · 견본이 `rem` 기준이라 브라우저의 기본 글자 크기를 따라 커집니다. |
| 밀도와 간격 | `CoreSpace` 단계가 아닌 간격 값도 `compact` · `spacious` 에서 4px 격자의 이웃 값으로 옮깁니다(13은 12 · 16). | 단계가 아닌 간격 값은 밀도를 바꿔도 적은 값 그대로입니다. |
| `center` 글 색 | `.titleMedium` 같은 글자 역할을 준 글은 `valueStyle` 의 색을 받지 않고 `onSurface` 에서 시작합니다. | 색을 따로 주지 않으면 글자 역할을 줘도 `valueStyle` 의 색을 이어받습니다. |
| 목록 역할 | 없음 | `list` · `listitem` (`donut` 의 루트는 `group`) |
| 중복 숨김 | `ExcludeSemantics` | `aria-hidden` |
| 빈 상태 기본값 | `SizedBox.shrink()` | 빈 fragment |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` |

<a id="props-parameters"></a>

## API

두 플랫폼이 같은 속성을 씁니다. 표의 `W` 는 Flutter의 `Widget`, Web의 Jaspr `Component` 입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `items` | `List<CoreCategoryBreakdownItem>` | 필수 | 카테고리 목록. 적은 순서대로 그립니다. |
| `variant` | `CoreCategoryBreakdownVariant` | `bar` | 가로 막대(`bar`) 또는 도넛(`donut`) |
| `center` | `W?` | `null` | 도넛 가운데에 놓는 내용(보통 합계). `bar` 에서는 그리지 않습니다. |
| `empty` | `W?` | `null` | 항목이 없거나 합계가 0일 때 대신 그리는 내용 |
| `semanticLabel` | `String?` | `null` | 분포 전체의 접근 가능한 이름 |
| `categoryBreakdownStyle` | `CoreCategoryBreakdownStyle?` | `null` | 이 인스턴스의 겉모습(색 · 크기 · 간격 · 글자) |

### CoreCategoryBreakdownItem

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String` | 필수 | 카테고리 이름 |
| `value` | `double` | 필수 | 카테고리 값. 비율을 계산할 때 음수는 0으로 셉니다. |
| `valueLabel` | `String?` | `null` | 화면에 적을 값. 없으면 `value` 를 라틴 숫자로 적습니다. |
| `color` | `CoreColor?` | `null` | 이 카테고리의 색. 없으면 `seriesColors` 에서 순번의 색을 씁니다. |

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `attributes` | `Map<String, String>?` | `null` | 루트의 HTML 속성. `role` 은 컴포넌트의 값이 쓰입니다. |
| `classes` | `String?` | `null` | 루트에 덧붙이는 CSS 클래스 |
| `css` | `Styles?` | `null` | 루트의 인라인 스타일. 컴포넌트의 인라인 스타일 뒤에 합칩니다. |
| `id` | `String?` | `null` | 루트의 id |
| `tag` | `String` | `'div'` | 값을 받지만 지금은 쓰이지 않습니다. 루트는 항상 `<div>` 입니다. |

Web 생성자에는 클릭 같은 이벤트 핸들러를 받는 인자가 없습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreCategoryBreakdownStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `seriesColors` | `List<CoreColor>?` | Colours assigned to categories in order, cycling when there are more categories than colours. An item's own `color` wins. |
| `trackColor` | `CoreColor?` | Colour of the empty part of each bar. |
| `barHeight` | `double?` | Height of each bar (logical px). |
| `barBorderRadius` | `CoreBorderRadius?` | Corner radius of the bar track and its fill. |
| `rowSpacing` | `double?` | Vertical space between category rows (logical px). |
| `rowContentSpacing` | `double?` | Vertical space between a row's text line and its bar (logical px). |
| `labelSpacing` | `double?` | Horizontal space between a row's swatch, label, value and share (logical px). |
| `labelStyle` | `CoreTextStyle?` | Typography of each category label. |
| `valueStyle` | `CoreTextStyle?` | Typography of each category value. |
| `percentStyle` | `CoreTextStyle?` | Typography of each category share. |
| `donutSize` | `double?` | Diameter of the donut (logical px). |
| `donutThickness` | `double?` | Ring thickness of the donut (logical px). |
| `donutSegmentSpacing` | `double?` | Empty space between adjacent donut arcs, measured along the ring (logical px). |
| `legendSpacing` | `double?` | Space between the donut and its legend — beside it, or below it once the legend wraps (logical px). |
| `swatchSize` | `double?` | Side of the colour swatch in each donut legend row (logical px). |
| `swatchBorderRadius` | `CoreBorderRadius?` | Corner radius of the legend swatch. |

<!-- STYLE_TABLE:END -->

<Note>

표의 설명에 더해, `rowContentSpacing` 은 값 · 비율이 라벨 아래로 내려갔을 때의 세로 간격이기도 합니다(`donut` 의 범례 포함). `valueStyle` 은 `donut` 의 `center` 에 놓는 글의 기본 글자 스타일이기도 합니다. `center` 의 글에 직접 준 스타일은 그보다 우선합니다. `.titleMedium` 같은 글자 역할을 준 글에 `valueStyle` 의 색이 남는지는 플랫폼마다 다르므로([플랫폼 차이](#플랫폼-차이)), 두 플랫폼의 색을 맞추려면 `center` 의 글에 색을 직접 주세요.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="category-breakdown/related-trend-chart" title="TrendChart">

값이 시간에 따라 어떻게 변했는지 보여 줍니다.

</Card>
<Card demo="category-breakdown/related-progress" title="Progress">

작업 하나가 얼마나 진행됐는지 보여 줍니다.

</Card>
<Card demo="category-breakdown/related-stat" title="Stat">

비율 없이 지표 하나를 크게 보여 줍니다.

</Card>
</Cards>
