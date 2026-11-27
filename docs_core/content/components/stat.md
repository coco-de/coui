---
title: Stat
description: 수치 통계를 레이블, 값, 트렌드와 함께 표시하는 컴포넌트
category: display
platforms: [flutter, web]
related: [number-ticker, progress, card]
tags: [dashboard, statistics, analytics, metrics]
template: v2
source: display/stat
---

# Stat

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

대시보드나 리포트의 주요 수치 하나를 카드 한 장에 담습니다. 레이블, 값과 단위, 변동 줄, 설명 줄 가운데 꼭 넘겨야 하는 것은 `label` 뿐입니다. 속성을 바꿔 보며 카드를 확인하고, 만들어진 코드를 복사하세요. `changeType` 은 변동 줄을 켰을 때만 화면에 나타납니다.

<Playground component="stat" />

`value` · `unit` · `change` · `description` 은 받은 문자열을 그대로 적습니다. 천 단위 구분, 통화 기호, 변동률 계산은 `Stat` 이 하지 않으므로 완성한 글을 넘깁니다.

## 구조

카드 상자 안에 위에서부터 레이블 → 값(+ 단위) → 변동 → 설명 순서로 놓입니다. 레이블 줄과 값 줄은 항상 있고, 넘기지 않은 변동 줄과 설명 줄은 그 위의 간격까지 함께 빠집니다.

<Anatomy demo="stat/anatomy">
<AnatomyItem part="container" name="Container">

카드 상자. 채움, 선, 모서리, 안쪽 여백을 가집니다. 두 플랫폼 모두 `OutlinedContainer` 로 그립니다.

</AnatomyItem>
<AnatomyItem part="label" name="label">

지표 이름. 첫 줄의 앞쪽에 놓입니다.

</AnatomyItem>
<AnatomyItem select="svg" side="right" name="icon">

첫 줄의 끝에 놓는 아이콘 슬롯. 선택 사항입니다.

</AnatomyItem>
<AnatomyItem select="div:first-child + div > div" side="left" name="value">

수치. `value` 가 `null` 이면 이 자리에 `—` 를 그립니다.

</AnatomyItem>
<AnatomyItem select="div:first-child + div > div + span" side="right" name="unit">

값 뒤에, 값과 같은 글자 바닥선에 놓는 단위. 선택 사항입니다.

</AnatomyItem>
<AnatomyItem select="div:first-child + div + div" side="left" name="change">

화살표와 변동 글. `change` 와 `changeType` 을 둘 다 줄 때 그립니다.

</AnatomyItem>
<AnatomyItem select="div:first-child + div + div + div" side="right" name="description">

기간이나 기준을 적는 마지막 줄. 선택 사항입니다.

</AnatomyItem>
</Anatomy>

<a id="카드-변형-outlined-filled"></a>

## Variant

`variant`(`CoreStatVariant`)는 카드의 채움과 선을 고릅니다. 기본값은 `outlined` 입니다.

<VariantRow name="outlined" component="stat" props="variant=outlined;unit=true;change=true" label="월간 주문">

`surface` 면에 `outlineVariant` 색의 1px 선을 두릅니다. 선으로 카드를 구분합니다. 기본값입니다.

</VariantRow>

<VariantRow name="filled" component="stat" props="variant=filled;unit=true;change=true" label="월간 주문">

`surfaceContainerLow` 면에 선이 없습니다. 면의 톤으로 카드를 구분합니다.

</VariantRow>

- 기본 서페이스 스타일에서는 두 variant 모두 그림자가 없습니다.
- `Dialog` · `Popup` · `Drawer` 의 기본 면(`surfaceBright`) 위에서는 `filled` 카드의 면이 그 패널보다 어둡게 놓입니다. 패널 안에서는 기본 `outlined` 가 어울립니다.

## 크기

`Stat` 에 정해진 크기는 `md`(기본)와 `sm` 둘입니다. `sm` 은 대시보드의 좁은 칸에 씁니다. 여백과 줄 간격이 줄고 글자 역할이 모두 작아집니다.

<SizeSpec component="stat" props="unit=true;change=true;description=true" label="월간 주문" />

- 두 크기에 없는 값을 넘기면 디버그 빌드에서는 assert 가 실패합니다. assert 가 꺼진 빌드에서는 `lg` · `xl` · `xl2` 를 `md` 로, `xs` 를 `sm` 으로 그립니다.
- 표의 글자 크기는 화면 폭 1024 이상 기준입니다. 기본 설정에서 `md` 의 값 글자(`headlineLarge`)는 768 이상 1024 미만에서 28, 768 미만에서 24 로 작아집니다. `sm` 의 값 글자(`titleLarge`, 20)는 화면 폭에 따라 바뀌지 않습니다.
- `size` 는 `icon` 의 크기를 바꾸지 않습니다.

<a id="변형-variants"></a>
<a id="상승-트렌드"></a>
<a id="하락-트렌드"></a>
<a id="중립"></a>

## 변동 지표

`changeType`(`CoreStatChangeType`) 하나가 화살표와 색을 함께 정합니다.

| 값 | 화살표 | 기본 색 | 색을 바꾸는 스타일 필드 |
| --- | --- | --- | --- |
| `positive` | `↑` | `onSuccessContainer` | `positiveColor` |
| `negative` | `↓` | `onErrorContainer` | `negativeColor` |
| `neutral` | `→` | `onSurfaceVariant` | `neutralColor` |

<Preview demo="stat/trend" />

```dart
// 상승
Stat(
  label: '신규 가입',
  value: '1,284',
  unit: '명',
  size: CoreComponentSize.sm,
  change: '+8.2%',
  changeType: CoreStatChangeType.positive,
)

// 하락
Stat(
  label: '취소율',
  value: '1.4',
  unit: '%',
  size: CoreComponentSize.sm,
  change: '-0.3%p',
  changeType: CoreStatChangeType.negative,
)

// 중립
Stat(
  label: '활성 세션',
  value: '892',
  size: CoreComponentSize.sm,
  change: '변동 없음',
  changeType: CoreStatChangeType.neutral,
)
```

- 변동 줄은 `change` 와 `changeType` 을 **둘 다** 줄 때만 그립니다. 하나만 주면 줄이 없습니다.
- `changeType` 은 `change` 의 글에서 알아내지 않습니다. `-` 로 시작하는 글에 `positive` 를 주면 `↑` 를 그립니다.
- 화살표는 아이콘이 아니라 글자입니다. 변동 글과 같은 글자 스타일과 색으로 그립니다.

### 오르면 나쁜 지표

이탈률이나 오류 수처럼 오를수록 나쁜 지표는 화살표를 숫자의 방향에 맞추고 색만 바꿉니다. 아래 코드는 `↑` 를 오류 글자색으로 그립니다. 내려가서 좋은 경우에는 `negative` 와 `negativeColor` 를 같은 방법으로 씁니다.

```dart
Stat(
  label: '이탈률',
  value: '3.2',
  unit: '%',
  change: '+0.5%p',
  changeType: CoreStatChangeType.positive,
  statStyle: CoreStatStyle(
    positiveColor: CoreColor.token(CoreColors.onErrorContainer),
  ),
)
```

## 단위와 설명 줄

<Preview demo="stat/unit" />

```dart
Stat(
  label: '활성 사용자',
  value: '128,450',
  unit: '명',
  change: '+5.2%',
  changeType: CoreStatChangeType.positive,
  description: '지난 30일',
)
```

- **`unit`** 은 값 뒤에 4 간격(`valueUnitGapStyle`)을 두고 값과 같은 글자 바닥선에 놓입니다. 값보다 작은 글자를 `onSurfaceVariant` 색으로 그려 값(`onSurface`)보다 약하게 읽힙니다.
- 단위를 `value` 에 붙여 써도 그려지지만, 그때는 단위가 값과 같은 글자 스타일이 됩니다.
- **`description`** 은 마지막 줄입니다. 기간이나 기준처럼 수치의 맥락을 `onSurfaceSubtle` 색으로 적습니다. 화살표와 추세 색은 붙지 않습니다.
- 라벨과 설명은 Regular 이고, 값, 단위, 변동 글은 그보다 굵습니다. `md` 의 단위는 `titleMedium` 역할에 굵기 500 을 씁니다.
- 줄 사이 간격은 `contentGapStyle` 입니다. 기본값은 `md` 10, `sm` 4 입니다.

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>
<a id="표시"></a>
<a id="상태-전환"></a>
<a id="애니메이션"></a>

## 상태

| 항목 | 동작 |
| --- | --- |
| 인터랙션 | 표시 전용입니다. 콜백을 받지 않고 hover, pressed, focus 상태를 그리지 않습니다. `icon` 에 넣은 위젯은 자기 동작을 그대로 가집니다. |
| 값 갱신 | `value` · `change` · `changeType` 을 바꿔 다시 그리면 글, 화살표, 색이 새 값으로 바뀝니다. |
| 애니메이션 | `Stat` 이 따로 움직이는 효과는 없습니다. |
| 로딩 | 로딩 상태를 고르는 속성이 없습니다. 글 슬롯은 모두 문자열이고 위젯 슬롯은 `icon` 하나이므로, 불러오는 동안에는 `Stat` 자리에 [Skeleton](/components/skeleton)을 직접 그립니다. |

### 빈 값

<Preview demo="stat/empty" />

수치를 아직 모르거나 없으면 `value` 를 생략합니다.

```dart
Stat(
  label: '이번 달 매출',
  unit: '원',
  description: '아직 집계되지 않았습니다',
)
```

- 값 자리에 `CoreStatContract.defaultEmptyValue`(`—`)를 값과 같은 글자 스타일로, 색만 `emptyValueColor`(`onSurfaceVariant`)로 그립니다.
- 단위는 그리지 않습니다. 카드 전체를 흐리게 하지 않으므로 레이블과 설명은 평소처럼 읽힙니다.
- `change` 와 `changeType` 을 함께 주면 값이 없어도 변동 줄은 그립니다. 비교할 수치가 없으면 두 값도 빼세요.
- 빈 문자열(`''`)은 빈 값이 아닙니다. `null` 일 때만 `—` 가 나옵니다.
- `—` 는 로딩 표시가 아닙니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>
<a id="do"></a>
<a id="dont"></a>

## 사용 가이드

### 이럴 때 씁니다

- 대시보드의 핵심 지표(KPI)를 카드로 보여 줄 때
- 매출, 사용자 수, 방문자 수처럼 주요 수치를 강조할 때
- 이전 기간과 비교한 증감을 함께 보여 줄 때
- 분석 리포트의 요약 수치를 격자로 나열할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 완료율이나 목표 달성률을 막대로 보여 줄 때 | [Progress](/components/progress) |
| 레이블과 변동 없이 움직이는 숫자만 필요할 때 | [NumberTicker](/components/number-ticker) |
| 레이블 없이 수치 글자만 적을 때 | [Text](/components/text) |
| 미디어, 본문, 액션을 자유롭게 조합할 때 | [Card](/components/card) |
| 여러 구간의 상태 이력을 보여 줄 때 | [Tracker](/components/tracker) |
| 시간에 따른 추이를 그래프로 보여 줄 때 | [TrendChart](/components/trend-chart). `summary` 슬롯에 `Stat` 을 넣을 수 있습니다. |

### 비교 기준, 방향, 단위

<Cards columns="2">
<Card demo="stat/do-period" tone="do" eyebrow="이렇게 하세요">

어느 기간과 비교한 변화인지 `description` 에 적습니다.

</Card>
<Card demo="stat/dont-period" tone="dont" eyebrow="이렇게 하지 마세요">

비교 기준이 없으면 `+11.7%` 가 지난달 대비인지 작년 대비인지 알 수 없습니다.

</Card>
<Card demo="stat/do-direction" tone="do" eyebrow="이렇게 하세요">

화살표는 숫자가 움직인 방향에 맞춥니다. 오르면 나쁜 지표는 `positiveColor` 를 오류 글자색으로 바꿉니다.

</Card>
<Card demo="stat/dont-direction" tone="dont" eyebrow="이렇게 하지 마세요">

늘어난 값(`+0.5%p`)에 `negative` 를 주면 `↓` 화살표와 변동 글이 서로 반대를 말합니다.

</Card>
<Card demo="stat/do-unit" tone="do" eyebrow="이렇게 하세요">

단위는 `unit` 으로 넘기고, 큰 수의 구분 기호는 `value` 에 직접 넣습니다.

</Card>
<Card demo="stat/dont-unit" tone="dont" eyebrow="이렇게 하지 마세요">

단위와 구분 기호가 없는 숫자는 무엇을 센 값인지 알기 어렵습니다.

</Card>
</Cards>

한 화면에는 가장 중요한 지표를 4개에서 8개 정도만 둡니다. 지표가 많아지면 무엇을 먼저 봐야 할지 알기 어렵습니다.

### 숫자가 움직이는 지표

`value` 는 문자열만 받으므로 다른 위젯을 값 자리에 넣을 수 없습니다. 숫자가 바뀔 때 움직이게 하려면 `NumberTicker.builder` 안에서 `Stat` 을 그립니다. `initialValue` 를 주지 않으면 처음에는 목표 숫자를 바로 보이고, `value` 가 바뀔 때 이어서 움직입니다. 천 단위 구분 기호는 `builder` 에서 직접 넣습니다.

```dart
NumberTicker.builder(
  value: orderCount,
  builder: (context, number, child) => Stat(
    label: '월간 주문',
    value: number.round().toString(),
    unit: '건',
  ),
)
```

<a id="그리드-레이아웃"></a>

## 배치

`Stat` 은 부모가 정해 준 너비를 채웁니다. 여러 장을 놓을 때는 부모가 열을 나눕니다.

<Preview demo="stat/grid" />

<Split>

<Code language="dart" title="Flutter">
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space12,
  children: [
    Expanded(
      child: Stat(
        label: '총 사용자',
        value: '12,480',
        unit: '명',
        size: CoreComponentSize.sm,
      ),
    ),
    Expanded(
      child: Stat(
        label: '새 주문',
        value: '384',
        unit: '건',
        size: CoreComponentSize.sm,
      ),
    ),
  ],
)
</Code>

<Code language="dart" title="Jaspr Web">
div(
  styles: Styles(raw: {
    'display': 'grid',
    'grid-template-columns': 'repeat(2, minmax(0, 1fr))',
    'gap': spaceCss(CoreSpace.space12),
  }),
  [
    Stat(
      label: '총 사용자',
      value: '12,480',
      unit: '명',
      size: CoreComponentSize.sm,
    ),
    Stat(
      label: '새 주문',
      value: '384',
      unit: '건',
      size: CoreComponentSize.sm,
    ),
  ],
)
</Code>

</Split>

- Flutter 의 `Row` 에서는 `Expanded` 나 `SizedBox` 로 너비를 줍니다. 너비를 주지 않으면 카드가 내용 너비를 따르고, 긴 설명 줄이 바뀌지 않아 넘칠 수 있습니다.
- Flutter 의 `Wrap` 에 그대로 넣으면 카드 한 장이 한 줄의 너비를 다 씁니다. 카드마다 `SizedBox` 로 너비를 정합니다.
- 위 Web 격자는 같은 줄의 카드 높이를 맞춥니다. 위 Flutter 코드의 `Row` 에서는 카드마다 자기 내용의 높이를 가집니다.
- 칸의 높이가 정해진 부모(`GridView` 의 기본 정사각 칸 등)에서는 칸이 카드 내용보다 낮으면 넘칩니다.

### 긴 글과 좁은 폭

<Preview demo="stat/long-text" />

긴 값은 카드 안에서 줄이 바뀝니다. 단위는 값의 **첫 줄** 바닥선에 맞춰 값의 뒤쪽에 놓이며, 마지막 줄로 따라 내려가지 않습니다.

| 줄 | Flutter | Jaspr Web |
| --- | --- | --- |
| `label` | 줄이 바뀌지 않습니다. 카드보다 길면 넘칩니다. | 줄이 바뀝니다. |
| `value` | 줄이 바뀝니다. | 줄이 바뀝니다. |
| `unit` | 줄이 바뀌지 않습니다. | 줄이 바뀌지 않습니다. |
| `change` | 줄이 바뀌지 않습니다. 카드보다 길면 넘칩니다. | 줄이 바뀝니다. |
| `description` | 줄이 바뀝니다. | 줄이 바뀝니다. |

`label` 의 줄 수를 정하는 `labelMaxLines` · `labelOverflow` 는 플랫폼마다 다르게 동작합니다.

- **Jaspr Web** — `labelMaxLines` 를 주면 그 줄 수에서 잘리고 말줄임이 붙습니다. 말줄임이 필요하면 `labelMaxLines` 를 함께 주세요. `labelOverflow: CoreTextOverflow.ellipsis` 만 주면 라벨이 한 줄이 되어, 카드보다 긴 라벨은 말줄임 없이 가장자리에서 잘립니다.
- **Flutter** — 라벨이 너비 제한을 받지 않아, 두 속성을 주어도 폭 때문에 생기는 줄바꿈이나 말줄임은 일어나지 않습니다. 라벨과 변동 글은 카드 폭 안에 들어가게 짧게 씁니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

### 파라미터와 스타일

- **종류와 내용** — 위젯 파라미터로 넘깁니다: `variant`, `size`, `label`, `value`, `unit`, `change`, `changeType`, `description`, `icon`, `labelMaxLines`, `labelOverflow`.
- **겉모습** — `statStyle`(`CoreStatStyle`) 하나로 덮어씁니다: 여백, 모서리, 채움, 선, 간격 셋, 글자 색 여덟, 글자 스타일 다섯. 필드 목록은 [API](#api) 끝의 표에 있습니다.
- **글자 색** — `labelColor` · `valueColor` 같은 `*Color` 필드로 정합니다. Flutter 는 `*TextStyle` 안에 적은 `color` 를 쓰지 않습니다.
- **아이콘** — `Stat` 은 `icon` 에 크기나 색을 주지 않습니다. 라벨 색에 맞추려면 `Icon` 의 `iconStyle` 로 직접 정합니다.

### 값이 정해지는 순서

```text
디자인 시스템 기본값                         // size 별 값, variant 별 값, 공통 기본값
  → CoreStatTheme.style                    // 프로젝트 공통
  → CoreStatTheme.variantStyles[variant]   // variant 별
  → statStyle                              // 인스턴스별
```

- 같은 필드를 여러 단계에서 정하면 뒤의 것이 이깁니다. 정하지 않은 필드는 앞의 값이 남습니다.
- 글자 스타일은 안의 값끼리 합칩니다. `fontWeight` 만 덮어쓰면 크기 표의 글자 역할은 그대로입니다.
- `CoreStatTheme.style` 에 정한 여백, 줄 간격, 글자 스타일은 `md` 와 `sm` 에 모두 적용됩니다.
- 카드 상자는 `OutlinedContainer` 라 테마의 서페이스 스타일이 닿습니다. `CoreComponentTheme.outlinedContainer` 에서 `Stat` 이 따로 정하지 않는 값(그림자 등)도 이 상자에 적용됩니다.

### 사용 예

<Split>

<Code language="dart" title="카드 하나만 바꾸기">
Stat(
  label: '활성 사용자',
  value: '128,450',
  unit: '명',
  icon: Icon(
    LucideIcons.calendar,
    iconStyle: CoreIconStyle(
      size: CoreIconSize.size16,
      color: CoreColor.token(CoreColors.onSurfaceVariant),
    ),
  ),
  statStyle: CoreStatStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    contentGapStyle: CoreGapStyle(size: CoreSpace.space8),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    stat: CoreStatTheme(
      style: CoreStatStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      ),
      variantStyles: {
        CoreStatVariant.filled: CoreStatStyle(
          backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
        ),
      },
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter 와 Web 코드가 같습니다. 간격 슬롯(`contentGapStyle` · `changeIconGapStyle` · `valueUnitGapStyle`)의 `size` 에는 `CoreSpace` 의 값을 쓰세요. Web 은 `CoreSpace` 단계가 아닌 값을 적은 크기대로 그리지 못합니다.

### 마케팅 KPI — display 타이포

<Preview demo="stat/display" />

`md` 의 값은 `headlineLarge` 역할(32 Bold)입니다. 홈 화면의 대표 지표처럼 더 큰 숫자가 필요하면 `valueTextStyle` 에 `CoreTextStyles.displaySmall` 을 넣습니다. 이 역할은 44 Bold, 줄 높이 1.4, 자간 −2% 이고, 기본 설정에서 화면 폭이 768 이상 1024 미만이면 36, 768 미만이면 28 입니다. Web 에서는 값 요소의 클래스가 `text-display-small` 로 바뀝니다. display 전용 `size` 값은 없습니다.

```dart
Stat(
  label: '활성 사용자',
  value: '128,450',
  unit: '명',
  statStyle: CoreStatStyle(
    valueTextStyle: CoreTextStyle.token(CoreTextStyles.displaySmall),
  ),
)
```

Web 은 값 요소에 글자 역할 클래스가 직접 붙어 있어, 바깥 요소에 준 CSS `font-size` 는 값에 닿지 않습니다. 크기는 `valueTextStyle` 로 바꿉니다.

### 면 없는 카드

<Preview demo="stat/plain" />

이미 상자 안에 놓을 때처럼 카드의 면이 필요 없으면, 선이 없는 `filled` 에서 채움과 모서리를 지웁니다. `outlined` 는 채움을 지워도 선이 남습니다. 안쪽 여백까지 없애려면 `padding` 에 `CoreEdgeInsets.zero` 를 줍니다.

```dart
Stat(
  label: '활성 사용자',
  value: '128,450',
  unit: '명',
  variant: CoreStatVariant.filled,
  statStyle: CoreStatStyle(
    backgroundColor: CoreColor.transparent,
    borderRadius: CoreBorderRadius.zero,
  ),
)
```

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

이미 만든 `Stat` 에 `withStyle` 을 이어 `statStyle` 을 덧붙일 수 있습니다. 생성자의 `statStyle` 인자와 같게 동작하고, 같은 필드는 나중에 이은 값이 이깁니다. `.radius4` 처럼 Core 토큰 상수와 이름이 같은 getter 도 있습니다. `withStyle` 을 한 번 더 줄인 것으로, 이름이 곧 값이라(`radius4` 는 `CoreRadius.radius4`) 어느 컴포넌트에서 써도 뜻이 같습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class StatChainExample extends StatefulWidget {
  const StatChainExample({super.key});

  @override
  State<StatChainExample> createState() => _StatChainExampleState();
}

class _StatChainExampleState extends State<StatChainExample> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        const Stat(
          label: '총매출',
          value: '4,523만 원',
          change: '+20.1%',
          changeType: CoreStatChangeType.positive,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        const Stat(
          label: '총매출',
          value: '4,523만 원',
          change: '+20.1%',
          changeType: CoreStatChangeType.positive,
        ).withStyle(
          const CoreStatStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
          ),
        ),
      ],
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class StatChainExample extends StatefulComponent {
  const StatChainExample({super.key});

  @override
  State<StatChainExample> createState() => _StatChainExampleState();
}

class _StatChainExampleState extends State<StatChainExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Stat(
          label: '총매출',
          value: '4,523만 원',
          change: '+20.1%',
          changeType: CoreStatChangeType.positive,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Stat(
          label: '총매출',
          value: '4,523만 원',
          change: '+20.1%',
          changeType: CoreStatChangeType.positive,
        ).withStyle(
          const CoreStatStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<Note>

색 getter(`.primary` 등)와 `backgroundColor` 는 카드의 채움만 바꾸고 글자색은 그대로 둡니다. 위 예제는 체인을 쓰는 방법을 보여 줍니다. CoUI 기본 색에서 `primary` · `tertiary` 채움은 라이트와 다크 모두 기본 글자색과 밝기가 가까워, 글자색을 그대로 두면 글자가 잘 보이지 않습니다. 아래처럼 그리는 줄의 글자색을 함께 바꾸세요.

</Note>

```dart
Stat(
  label: '총매출',
  value: '4,523만',
  unit: '원',
  change: '+20.1%',
  changeType: CoreStatChangeType.positive,
).primary.withStyle(
  CoreStatStyle(
    labelColor: CoreColor.token(CoreColors.onPrimary),
    valueColor: CoreColor.token(CoreColors.onPrimary),
    unitColor: CoreColor.token(CoreColors.onPrimary),
    positiveColor: CoreColor.token(CoreColors.onPrimary),
  ),
)
```

<a id="접근성-accessibility"></a>

## 접근성

`Stat` 은 글을 보여 주기만 합니다. 카드, 지표, 증감이라는 관계는 화면의 배치로만 표현됩니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | `Stat` 과 카드 상자는 `Semantics` 를 붙이지 않습니다. |
| Jaspr Web | 컴포넌트가 만드는 `div` · `span` 에는 role 과 `aria-*` 가 없습니다. `attributes` 로 준 값은 루트 `div` 에 붙습니다. |

### 키보드

없음. `Stat` 은 표시 전용이라 누르기 콜백이 없고 포커스를 받는 요소를 만들지 않습니다. Web 생성자는 이벤트 핸들러 파라미터를 받지 않습니다. `icon` 에 버튼을 넣으면 그 버튼의 키보드 동작을 따릅니다.

### 스크린 리더

- 내용은 레이블 → 아이콘 → 값 → 단위 → 화살표 → 변동 글 → 설명 순서로 놓입니다. 넘기지 않은 것은 빠집니다. Flutter 위젯 트리와 Web DOM 의 순서가 같습니다.
- `Stat` 은 `icon` 에 이름을 붙이지 않습니다. 아이콘에만 담긴 뜻은 `label` 이나 `description` 에도 적으세요.
- 화살표는 `↑` · `↓` · `→` 글자 그대로 들어갑니다. 보조 기술이 이 기호를 어떻게 읽는지는 도구마다 다를 수 있으므로, 방향이 꼭 전해져야 하면 `change` 를 `'20.1% 증가'` 처럼 씁니다.

카드를 한 문장으로 설명하려면 아래처럼 이름을 붙입니다. Flutter 의 `excludeSemantics: true` 는 카드 안의 글 대신 `label` 문장을 남깁니다. `icon` 에 버튼이 있으면 그 버튼의 정보까지 빠지므로 쓰지 마세요. Web 의 `role="group"` 은 묶음에 이름을 붙이며, 안의 글도 그대로 남습니다.

<Split>

<Code language="dart" title="Flutter">
Semantics(
  container: true,
  label: '월간 주문 1,284건, 지난 30일 동안 20.1% 증가',
  excludeSemantics: true,
  child: Stat(
    label: '월간 주문',
    value: '1,284',
    unit: '건',
    change: '+20.1%',
    changeType: CoreStatChangeType.positive,
    description: '지난 30일',
  ),
)
</Code>

<Code language="dart" title="Jaspr Web">
Stat(
  label: '월간 주문',
  value: '1,284',
  unit: '건',
  change: '+20.1%',
  changeType: CoreStatChangeType.positive,
  description: '지난 30일',
  attributes: {
    'role': 'group',
    'aria-label': '월간 주문 1,284건, 지난 30일 동안 20.1% 증가',
  },
)
</Code>

</Split>

### 포커스 관리

없음. 오버레이가 아닌 표시 전용 카드라 포커스를 옮기거나 가두지 않습니다.

### 알려진 제약

- 레이블과 값은 시맨틱으로 묶이지 않습니다. Web 은 `dl` · `dt` · `dd` 를 쓰지 않습니다.
- 변동 방향에는 "증가" · "감소" 같은 대체 글이 없습니다.
- 빈 값 `—` 에는 "값 없음" 같은 대체 글이 없습니다.
- 값이 바뀌어도 알리는 라이브 영역이 없습니다.
- Flutter 에서는 `label`, `unit`, 변동 줄의 글이 줄바꿈되지 않아, 글자 크기를 키우면 카드 밖으로 넘칠 수 있습니다.
- 라이트 모드의 `filled` 카드에서 설명 줄(`surfaceContainerLow` 위의 `onSurfaceSubtle`)의 글자 대비는 4.5:1 에 약간 못 미칩니다. CoUI 기본 색과, 색 하나로 만든 브랜드(`CoreBrand.fromColor`)가 해당합니다. `outlined` 카드(`surface` 위)에서는 같은 글자색이 4.5:1 을 넘습니다.

동작 줄이기, 고대비, 색 강제 모드처럼 모든 컴포넌트에 걸친 내용은 [접근성](/accessibility) 페이지에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`Stat` 의 이름과 내용 · 스타일 파라미터는 두 플랫폼이 같습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `icon` 타입 | `Widget?` | `Component?` |
| 변동 화살표 | `↑` · `↓` · `→` 글자 | 같습니다. |
| 값과 단위 | `Row` 의 글자 바닥선 정렬, 값은 `Flexible` | flex 의 글자 바닥선 정렬, 값은 줄어들며 줄바꿈 |
| 긴 `label` · `change` | 줄바꿈되지 않고 넘칩니다. | 줄바꿈됩니다. |
| `labelMaxLines` · `labelOverflow` | 폭 때문에 생기는 넘침에는 작동하지 않습니다. | `labelMaxLines` 로 줄 수를 제한합니다. `ellipsis` 만 주면 말줄임이 생기지 않습니다. |
| 간격 슬롯 | `size` 는 받은 값으로 계산합니다. `color` · `crossAxisExtent` 도 반영합니다. | `size` 만 씁니다. `CoreSpace` 단계가 아닌 값은 적은 크기대로 그리지 못합니다. |
| `*TextStyle` 안의 `color` | 쓰지 않고 `*Color` 의 색을 씁니다. | 적은 색이 CSS 에 함께 실려 결과가 Flutter 와 다를 수 있습니다. |
| 너비 제한이 없는 부모 | 카드가 내용 너비를 따릅니다. | 루트의 너비는 부모의 100% 입니다. |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` 가 루트 `div` 에 닿습니다. `tag` 는 반영되지 않습니다. |

<a id="props-parameters"></a>

## API

표의 `W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다.

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String` | 필수 | 지표 이름 |
| `value` | `String?` | `null` | 표시할 수치의 글. `null` 이면 `—` 를 `emptyValueColor` 로 그립니다. |
| `unit` | `String?` | `null` | 값 뒤에 놓는 단위(`명` · `%` · `원`). `value` 가 `null` 이면 그리지 않습니다. |
| `change` | `String?` | `null` | 변동 글. `changeType` 과 함께 줄 때만 그립니다. |
| `changeType` | `CoreStatChangeType?` | `null` | `positive` · `negative` · `neutral`. 화살표와 색을 정합니다. `change` 와 함께 줄 때만 적용됩니다. |
| `description` | `String?` | `null` | 마지막의 설명 줄 |
| `icon` | `W?` | `null` | 첫 줄 끝의 아이콘 |

### 모양

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `variant` | `CoreStatVariant` | `outlined` | 카드의 채움과 선 — `outlined` · `filled` |
| `size` | `CoreComponentSize` | `md` | 카드 크기 — `md` · `sm` |
| `labelMaxLines` | `int?` | `null` | 라벨의 최대 줄 수. 플랫폼별 동작은 [배치](#배치)를 보세요. |
| `labelOverflow` | `CoreTextOverflow?` | `null` | 라벨의 넘침 처리 — `clip` · `fade` · `ellipsis` · `visible`. 플랫폼별 동작은 [배치](#배치)를 보세요. |
| `statStyle` | `CoreStatStyle?` | `null` | 이 카드의 겉모습 덮어쓰기 |

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트 `div` 의 id |
| `classes` | `String?` | `null` | 루트에 덧붙이는 CSS 클래스 |
| `css` | `Styles?` | `null` | 루트의 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 루트의 HTML 속성 — `role`, `aria-label`, `data-*` 등 |
| `tag` | `String` | `'div'` | 생성자가 받지만 그려지는 루트에는 반영되지 않습니다. 루트는 항상 `div` 입니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreStatStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `padding` | `CoreEdgeInsets?` | Inner padding around the stat content. |
| `borderRadius` | `CoreBorderRadius?` | Outer border radius of the stat card. |
| `borderColor` | `CoreColor?` | Outer border colour. |
| `borderWidth` | `double?` | Outer border width (logical px). |
| `backgroundColor` | `CoreColor?` | Card background colour. |
| `contentGapStyle` | `CoreGapStyle?` | Space between the content rows of the card (label ↔ value ↔ change ↔ description), passed as is to the `Gap` between the rows. `null` uses [defaultContentGapStyle]. |
| `changeIconGapStyle` | `CoreGapStyle?` | Space between the change arrow and the change text inside the change row, passed as is to the `Gap`. `null` uses [defaultChangeIconGapStyle]. |
| `valueUnitGapStyle` | `CoreGapStyle?` | Space between the value and its unit inside the value row, passed as is to the `Gap`. `null` uses [defaultValueUnitGapStyle]. |
| `labelColor` | `CoreColor?` | Label text colour. |
| `valueColor` | `CoreColor?` | Value text colour. |
| `unitColor` | `CoreColor?` | Unit text colour. |
| `emptyValueColor` | `CoreColor?` | Colour of the empty-value placeholder drawn when the stat has no value. The placeholder keeps the value's text style; only the colour steps down. |
| `positiveColor` | `CoreColor?` | Colour of the change indicator when `changeType == positive`. |
| `negativeColor` | `CoreColor?` | Colour of the change indicator when `changeType == negative`. |
| `neutralColor` | `CoreColor?` | Colour of the change indicator when `changeType == neutral`. |
| `descriptionColor` | `CoreColor?` | Description (footnote) text colour. |
| `labelTextStyle` | `CoreTextStyle?` | Label text style override. |
| `valueTextStyle` | `CoreTextStyle?` | Value text style override. |
| `unitTextStyle` | `CoreTextStyle?` | Unit text style override. |
| `changeTextStyle` | `CoreTextStyle?` | Change indicator text style override. |
| `descriptionTextStyle` | `CoreTextStyle?` | Description (footnote) text style override. |

### `CoreStatStyle` 변형별 기본값 (`CoreStatVariantStyle`)

| 필드 | `outlined` | `filled` |
|------|------|------|
| `backgroundColor` | surface | surfaceContainerLow (fallback: surface) |
| `borderColor` | outlineVariant | transparent |
| `borderWidth` | stroke1 | 0 |

<!-- STYLE_TABLE:END -->

<Note>

`contentGapStyle` 을 정하지 않으면 크기별 기본 간격을 씁니다. `md` 는 10, `sm` 은 4 입니다. 세 간격 슬롯은 Flutter 에서만 `Gap` 에 그대로 넘어가고, Web 은 `size` 만 씁니다. `*TextStyle` 에 적은 글자색은 Flutter 에서 쓰이지 않으므로, 색은 `*Color` 필드로 정하세요.

</Note>

<a id="이전-api-에서-옮기기-migration"></a>

## 이전 API 에서 옮기기

- 기본 variant 가 `filled` 에서 `outlined` 로 바뀌었습니다. `variant` 를 적지 않은 `Stat` 은 `surface` 면에 `outlineVariant` 선으로 그려집니다. 선 없는 카드를 그대로 두려면 `variant: CoreStatVariant.filled` 를 적습니다.
- `size` 파라미터(`md` · `sm`)가 있습니다. 기본 `md` 는 이전과 같은 크기이고, 라벨과 설명 글자는 Regular 로, 단위는 Medium 으로 가벼워졌습니다.
- `CoreStatVariant` 에 `filled` 값이 있습니다. 이 enum 을 빠짐없이 나누는 `switch` 는 `filled` 갈래가 필요합니다.
- `value` 는 `String?` 입니다. 값을 넘기는 코드는 그대로 동작하고, `CoreStatContract` 를 직접 구현하거나 `stat.value` 를 읽는 코드는 `null` 을 다뤄야 합니다. 계약에는 `size` · `unit` · `description` 도 있습니다.
- 단위를 `value` 에 붙여 쓰던 곳(`'12,480명'`)은 `value: '12,480', unit: '명'` 으로 나누면 단위가 작은 글자로 값의 바닥선에 맞춰 그려집니다. 붙여 쓴 문자열도 그대로 동작합니다.

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="stat/related-card" title="Card">

`Stat` 보다 자유롭게 내용을 구성하는 상자입니다. 자세한 내용은 [Card](/components/card) 를 보세요.

</Card>
<Card demo="stat/related-progress" title="Progress">

목표 대비 진행률을 막대로 보여 줍니다. 자세한 내용은 [Progress](/components/progress) 를 보세요.

</Card>
<Card demo="stat/related-number-ticker" title="NumberTicker">

값이 바뀔 때 숫자를 이어서 넘겨 보여 줍니다. 자세한 내용은 [NumberTicker](/components/number-ticker) 를 보세요.

</Card>
</Cards>
