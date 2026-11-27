---
title: Progress
description: 작업이 얼마나 끝났는지 막대나 원형 고리로 보여 줍니다. 채움 색의 뜻(tone)과 크기(size)를 고르고, 끝난 비율을 모르면 막대를 불확정 상태로 둡니다.
category: display
platforms: [flutter, web]
related: [skeleton, loading, slider]
tags: [feedback, loading, indicator]
template: v2
source: display/progress
---

# Progress

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

작업 진행률을 보여 주는 컴포넌트입니다. 직선형 막대 `Progress` 와 원형 고리 `RadialProgress`, 두 위젯이 있습니다. 아래 플레이그라운드는 직선형이고, 원형은 [원형 진행률](#원형-진행률-radialprogress) 섹션에서 다룹니다. 속성을 바꿔 보며 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="progress" />

- 아무 값도 주지 않은 `Progress()` 는 불확정 막대입니다. 기본 크기는 `sm`, 기본 톤은 `primary` 입니다.
- 플레이그라운드는 라벨 · 값 · 캡션을 켠 채로 시작합니다. 세 칸은 모두 선택 사항이고, 값 칸의 글자는 직접 넣습니다. 막대가 `value` 를 보고 만들어 주지 않습니다.
- `value` 를 `null` 로 고르면 불확정 막대가 됩니다. 이때는 `segments` 와 `disableAnimation` 이 아무것도 바꾸지 않습니다.

## 구조

라벨을 모두 붙인 직선형 막대는 다섯 부분으로 이루어집니다.

<Anatomy demo="progress/anatomy">
<AnatomyItem part="label" side="top" name="label">

막대 위 왼쪽 칸 — 무엇의 진행인지 적습니다. 행의 남은 폭을 쓰고, 길면 줄이 바뀝니다. 보조 기술에는 막대의 이름이 됩니다.

</AnatomyItem>
<AnatomyItem select="[aria-hidden='true'] + div" side="top" name="valueLabel">

막대 위 오른쪽 칸 — 값을 적습니다(예: `62%`). 보조 기술은 이 칸을 따로 읽지 않습니다.

</AnatomyItem>
<AnatomyItem select="[role='progressbar'] > div:has(> div:only-child)" side="right" name="track">

막대의 바탕입니다. 모든 `tone` 에서 같은 중립색(`surfaceContainerHigh`)입니다. `segments` 를 주면 이 자리가 칸들로 바뀝니다.

</AnatomyItem>
<AnatomyItem select="[role='progressbar'] > div > div:only-child" side="left" name="indicator">

채움입니다. 폭이 진행 비율을, 색이 `tone` 을 나타냅니다.

</AnatomyItem>
<AnatomyItem select="[id$='-caption'] > span" side="right" name="caption">

막대 아래 칸 — 보조 설명입니다. 보조 기술에는 Web 에서 막대의 설명으로, Flutter 에서 이름에 이어지는 글로 전달됩니다.

</AnatomyItem>
</Anatomy>

```dart
Progress(
  value: 0.62,
  label: Text('팀 요금제'),
  valueLabel: Text('62%'),
  caption: Text('AI 사용량 · 18일 남음'),
)
```

Flutter와 Web 코드가 같습니다.

- `label` 과 `valueLabel` 은 막대 위의 한 행에, `caption` 은 막대 아래에 놓입니다. 칸과 막대 사이는 `labelGapStyle` · `captionGapStyle` 이 정하고 기본값은 `space8` 입니다.
- `label` 없이 `valueLabel` 만 주어도 값은 오른쪽 끝에 놓입니다.
- 세 칸이 모두 `null` 이면 칸을 담는 상자 없이 막대 하나만 그립니다.
- `valueLabel` 칸은 `100%` 의 폭을 미리 잡고 값을 끝에 붙이며, 숫자 폭을 고정합니다. 값이 `9%` 에서 `100%` 로 바뀌어도 칸 폭이 흔들리지 않습니다. `100%` 보다 넓은 글을 넣으면 칸이 그만큼 넓어집니다.

| 칸 | 글자 | 색 |
| --- | --- | --- |
| label | `labelMedium` (Medium) | `onSurface` |
| valueLabel | `labelMedium` · Regular | `onSurfaceVariant` |
| caption | `bodyXs` | `onSurfaceSubtle` |

칸에 넣은 `Text` 는 스타일을 따로 붙이지 않으면 위의 글자와 색을 이어받습니다. 색 체인(`.onSurfaceVariant` 등)만 붙이면 색만 바뀝니다. 글자 역할 체인(`.labelSmall` 등)은 두 플랫폼이 다릅니다. Flutter 는 칸의 스타일 대신 역할 체인의 기본 글자에서 다시 시작해 색이 `onSurface` 가 되고, Web 은 칸의 색을 그대로 둡니다. 칸 전체의 글자를 바꾸려면 `labelStyle` · `valueLabelStyle` · `captionStyle` 을 씁니다.

## 값과 범위

`value` 는 `min` 과 `max` 사이의 값입니다. 기본 범위는 `0.0`–`1.0` 이고, 채우는 비율은 `(value − min) / (max − min)` 입니다. `value` 가 `null`(기본값)이면 불확정 막대입니다.

```dart
// 기본 범위 0.0 ~ 1.0
Progress(value: 0.65)

// 범위를 직접 지정
Progress(value: 75, min: 0, max: 100)

// value 를 주지 않으면 불확정 막대
Progress()
```

범위를 벗어난 값은 두 플랫폼이 다르게 다룹니다.

- **Flutter** — 디버그 빌드에서 `assert` 오류가 납니다. `assert` 가 꺼진 빌드에서는 막대와 읽는 값을 0–100% 로 잘라 씁니다.
- **Jaspr Web** — 오류 없이 막대만 0–100% 로 잘라 그립니다. `aria-valuenow` 에는 넘긴 값이 그대로 실립니다.

두 플랫폼에서 같은 막대를 그리고 보조 기술에 범위를 벗어난 값을 보내지 않으려면, 넘기기 전에 값을 범위 안으로 자르세요(`value: ratio.clamp(0.0, 1.0)`).

`max` 는 `min` 보다 크게 둡니다. 둘이 같으면(예: 전체 항목 수가 0) 연속 막대를 Flutter 는 가득 찬 `100%` 로, Web 은 빈 막대로 그립니다. 전체가 0인 경우는 호출하는 쪽에서 따로 처리하세요.

## Variant

직선형에는 모양을 고르는 `variant` 가 없습니다. 대신 `tone` 이 **채움 색의 뜻**을 고릅니다. 기본값은 `primary` 입니다.

<VariantRow name="primary" component="progress" props="tone=primary">

보통의 진행입니다. `primary` 색으로 채웁니다.

</VariantRow>

<VariantRow name="success" component="progress" props="tone=success">

끝났거나 정상 범위입니다. `success` 색으로 채웁니다.

</VariantRow>

<VariantRow name="warning" component="progress" props="tone=warning">

곧 살펴야 합니다 — 한도에 가까운 사용량 같은 경우입니다. `warning` 색으로 채웁니다.

</VariantRow>

<VariantRow name="destructive" component="progress" props="tone=destructive">

실패했거나 막혔거나 한도를 넘었습니다. `error` 색으로 채웁니다.

</VariantRow>

```dart
Progress(value: 0.92, tone: CoreProgressTone.warning)
```

- 트랙은 모든 `tone` 에서 같은 중립색입니다. 칸의 글자색도 `tone` 을 따라가지 않습니다.
- 불확정 막대도 같은 `tone` 색으로 움직입니다.
- 색을 직접 정하면(`progressStyle.color`, 테마의 `color`, `.fillColor(...)`) 그 색이 `tone` 보다 우선합니다.
- `RadialProgress` 도 같은 `tone` 을 가집니다.

### 의미 체인

선형 진행 막대의 `.primary`, `.success`, `.warning`은 `tone`을 선택합니다. `Progress(value: 0.5).warning`은 테마의 warning 톤을 사용합니다. 채움색은 `.fillColor(.info)`, 트랙 색은 `.backgroundColor(.surfaceContainer)`로 각각 지정합니다.

## 크기

직선형의 `size` 는 막대 두께를 정합니다. 값은 `CoreProgressSize` 이고 기본값은 `sm` 입니다. 라벨 칸의 글자 크기는 바뀌지 않습니다. 아래의 두께는 `CoreProgressStyle.defaultsBySize` 의 논리 픽셀 값입니다.

<Preview demo="progress/sizes" />

```dart
Progress(value: 0.65, size: CoreProgressSize.lg)
```

`progressStyle.minHeight` 를 주면 `size` 의 두께 대신 그 값을 씁니다. Flutter 는 두께에 `theme.scaling` 을 곱하고, Web 은 `rem` 으로 그립니다. 원형의 크기는 [원형 진행률](#원형-진행률-radialprogress)에 있습니다.

## 형태

<Cards columns="3">
<Card demo="progress/shape-continuous" title="연속 막대">

기본 모양입니다. 채움의 폭이 진행 비율입니다.

</Card>
<Card demo="progress/shape-segments" title="단계형">

`segments` 를 주면 막대가 그 수의 칸으로 나뉩니다. 위 그림은 5칸입니다.

</Card>
<Card demo="progress/shape-square" title="각진 모서리">

`borderRadius` 는 트랙과 채움(단계형에서는 칸)에 함께 적용됩니다.

</Card>
</Cards>

모서리의 기본값은 `radius9999` 라, 트랙과 채움의 양 끝이 어느 두께에서나 반원입니다.

### 단계형

온보딩이나 가입 절차처럼 "몇 단계 중 몇 단계" 를 보여 줄 때 씁니다.

<Preview demo="progress/segments" />

```dart
Progress(
  value: 1,
  max: 2,
  segments: 2,
  size: CoreProgressSize.xs,
  label: Text('1 / 2단계'),
  progressStyle: CoreProgressStyle(
    labelStyle: CoreTextStyle(color: CoreColor.token(CoreColors.primary)),
  ),
)
```

채우는 칸 수는 **지나온 단계 수**, 곧 `(value − min) / (max − min) × segments` 의 정수 부분이며 `0` 과 `segments` 사이입니다. 지나온 칸은 채움 색, 나머지는 트랙 색입니다. 단계는 도달해야 지나간 것으로 셉니다. 아래는 4칸 막대입니다.

<Preview demo="progress/segment-count" />

- 곱셈의 부동소수점 오차로 정수 바로 아래가 된 값(`0.29 × 100` 은 `28.999…`)은 그 단계에 도달한 것으로 봅니다. 두 플랫폼은 같은 함수(`CoreProgressContract.filledSegmentsOf`)로 계산합니다.
- 칸은 폭을 똑같이 나누고, 높이와 모서리는 트랙과 같습니다. 칸 사이는 `segmentSpacing`(기본 `space4`)입니다. `space4` 이하는 테마의 밀도를 바꿔도 그대로이고, `space8` 처럼 더 큰 `CoreSpace` 단계를 직접 주면 밀도를 따라 바뀝니다. 단계에 없는 숫자는 Web 에서 밀도를 따라가지 않습니다.
- 단계 글(`1 / 2단계`)은 만들어 주지 않습니다. `label` 이나 `valueLabel` 에 직접 넣습니다.
- 불확정 막대에는 보여 줄 단계가 없어, `segments` 를 주어도 연속 막대로 움직입니다.
- `segments` 는 1 이상이어야 합니다.
- 칸 사이 간격의 합이 막대 폭보다 크면 칸이 들어갈 자리가 없어 넘칩니다. 단계가 아주 많으면 연속 막대를 쓰세요.

<a id="동작-스펙-behavior"></a>

## 상태

진행률은 표시 전용이라 hover · 포커스 · 비활성 상태가 없습니다. 상태는 `value` 와 `tone` 으로 나타냅니다.

<Preview demo="progress/states" />

| 상태 | 만드는 방법 | 알아 둘 점 |
| --- | --- | --- |
| 결정 | `value` 에 숫자 | 비율만큼 채웁니다. |
| 불확정 | `value: null` | 짧은 채움이 트랙을 지나갑니다. |
| 완료 | `value` 를 `max` 로 | 가득 채웁니다. 색이 저절로 바뀌거나 완료를 알리는 콜백은 없으므로, 필요하면 `tone` 을 직접 바꿉니다. |
| 실패 | `tone: CoreProgressTone.destructive` | 채움 색만 바뀝니다. 무엇이 실패했는지는 글로 알립니다. |

### 직선형

- `value` 가 바뀌면 채움 폭이 300ms(`CoreDuration.moderate`) 동안 `move` 곡선(ease-in-out)으로 바뀝니다. `progressStyle.duration` 으로 시간을 바꿉니다. 처음 그릴 때는 그 값에서 바로 시작합니다.
- 단계형은 칸 색이 같은 시간과 곡선으로 바뀝니다.
- 연속 막대의 채움 색이 바뀔 때(`tone` 전환 등), Flutter 는 색도 함께 서서히 바꾸고 Web 은 색을 바로 바꿉니다.
- `disableAnimation: true` 이면 폭과 색이 바로 바뀝니다. 불확정 막대의 움직임은 멈추지 않습니다.
- 불확정 막대는 트랙의 35%(`indeterminateFillRatio`)인 채움이 왼쪽 바깥에서 오른쪽 바깥까지 한 방향으로 지나가고, 다시 왼쪽에서 시작합니다. 한 번에 1500ms(`CoreDuration.indeterminate`)이며 같은 곡선을 씁니다. 한 번의 시간은 `indeterminateDuration` 으로 바꿉니다.

### 원형

- `RadialProgress` 에는 전환이 없습니다. `value` 가 바뀌면 두 플랫폼 모두 새 호를 바로 그립니다.
- 불확정 상태가 없습니다(`value` 는 필수). 비율을 모르는 작업에는 [Loading](/components/loading)이나 `Progress()` 를 씁니다.

### 동작 줄이기

사용자가 동작 줄이기를 요청하면 — Flutter 는 Android 의 애니메이션 삭제나 iOS 의 동작 줄이기, Web 은 `prefers-reduced-motion: reduce` — 500ms 이하의 전환은 시간 없이 바로 적용됩니다.

| 움직임 | 동작 줄이기를 켰을 때 |
| --- | --- |
| 채움 폭 · 칸 색 전환 (기본 300ms) | 바로 바뀝니다. |
| 500ms 보다 길게 지정한 `duration` | 킷은 시간을 줄이지 않습니다. 다만 Flutter 에서 Android 의 애니메이션 삭제를 켜면 Flutter 프레임워크가 이 전환을 훨씬 짧게 줄입니다. |
| 불확정 막대의 움직임 (기본 1500ms) | 계속 움직입니다. |

<Callout type="warning">

`indeterminateDuration` 은 500ms 보다 길게 둡니다. 500ms 이하는 동작 줄이기가 없애는 전환 시간으로 취급됩니다. 이 설정을 켠 환경에서 그런 값을 가진 불확정 막대를 그리면, Flutter 는 디버그 빌드에서 `assert` 오류가 나고 Web 은 채움이 트랙을 지나가지 않습니다.

</Callout>

## 원형 진행률 (RadialProgress)

고리 모양의 진행률입니다. `value` 는 **0–100 의 퍼센트**이며 `min` · `max` 는 없습니다. 범위를 벗어난 값은 두 플랫폼 모두 0–100 으로 잘라 그립니다. 호는 12시 방향에서 시작해 시계 방향으로 자라고, 양 끝이 둥급니다.

```dart
// 가운데에 퍼센트를 표시
RadialProgress(value: 75, showValueText: true)

// 크기(size)와 의미(tone)
RadialProgress(
  value: 50,
  size: CoreProgressSize.md,
  tone: CoreProgressTone.success,
)
```

- `showValueText: true` 는 가운데에 `75%` 모양의 글을 그립니다. 소수점 아래는 버립니다(`99.9` → `99%`).
- `child` 를 주면 그 위젯이 가운데 글을 대신하고 `showValueText` 는 쓰지 않습니다.
- 직선형과 달리 `label` · `valueLabel` · `caption` 칸이 없습니다. `segments` · `disableAnimation` 과 체인 getter 도 없습니다. 이름이나 설명은 바깥에 따로 둡니다.

### 크기와 톤

<Preview demo="progress/radial-sizes" />

- 크기는 `sm` · `md` · `lg` · `xl` 네 단계이고 기본값은 `lg` 입니다. `xs2` 와 `xs` 를 주면 `sm` 으로 그립니다.
- 기본 지름은 차례로 32 · 48 · 80 · 128, 링 두께는 3 · 4 · 6 · 8 (논리 픽셀)입니다.
- `size` 가 지름, 링 두께, 가운데 글자 역할을 함께 정합니다. 글자 역할은 `md` 가 `labelSmall`, `lg` 가 `titleMedium`, `xl` 이 `headlineLarge` 이고 색은 `onSurface` 입니다. `headlineLarge` 는 좁은 화면에서 글자가 더 작아집니다.
- `sm` 은 링이 작아 `showValueText` 를 켜도 글을 그리지 않습니다. `radialProgressStyle.valueTextStyle` 을 직접 주면 그립니다.

<Preview demo="progress/radial-tones" />

`tone` 은 호의 색만 바꿉니다. 트랙 링은 어느 톤에서나 중립색(`surfaceContainerHigh`)입니다.

### 가운데 내용 직접 넣기

<Preview demo="progress/radial-child" />

Flutter 는 `child` 를 링 가운데에 놓습니다. **Web 은 가운데로 옮기지 않고** 링 그림 뒤에 그대로 붙입니다. Web 에서는 아래처럼 가운데에 놓는 상자로 감쌉니다.

<Split>

<Code language="dart" title="Flutter">
RadialProgress(
  value: 75,
  tone: CoreProgressTone.success,
  child: Icon(LucideIcons.check),
)
</Code>

<Code language="dart" title="Jaspr Web">
RadialProgress(
  value: 75,
  tone: CoreProgressTone.success,
  child: div(
    styles: Styles(
      raw: {
        'position': 'absolute',
        'inset': '0',
        'display': 'flex',
        'align-items': 'center',
        'justify-content': 'center',
      },
    ),
    [Icon(LucideIcons.check)],
  ),
)
</Code>

</Split>

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

완료 비율을 아는 작업은 `Progress` 나 `RadialProgress` 로 보여 줍니다. 비율을 모르는 작업은 `Progress` 의 `value: null` 이나 [Loading](/components/loading)을 씁니다.

### 이럴 때 씁니다

- 파일 올리기 · 내려받기처럼 작업이 얼마나 끝났는지 보여 줄 때
- 목표 달성률이나 저장 공간 사용량 같은 비율을 보여 줄 때
- 사용량이 한도에 가깝거나 작업이 실패한 상태를 채움 색으로도 함께 알려야 할 때(`tone`)

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 작업 중이라는 표시만 필요할 때 | [Loading](/components/loading) |
| 불러올 콘텐츠의 자리와 모양을 미리 잡아 둘 때 — 자리 표시 모양은 호출하는 쪽에서 `Skeleton` 으로 짭니다 | [Skeleton](/components/skeleton) |
| 사용자가 값을 조절해야 할 때 | [Slider](/components/slider) |
| 두 끝 값을 조절해 구간을 입력받을 때 | [Range](/components/range) |
| 서로 다른 시점의 상태를 여러 칸으로 보여 줄 때 | [Tracker](/components/tracker) |

### Do

<Cards columns="3">
<Card demo="progress/do-labelled" tone="do" eyebrow="이렇게 하세요">

`label` 로 무엇의 진행인지 적습니다. 화면에 보이고 보조 기술의 이름도 됩니다.

</Card>
<Card demo="progress/do-radial-stat" tone="do" eyebrow="이렇게 하세요">

원형 진행률은 대시보드 통계처럼 자리가 좁은 카드에서 목표 달성률을 보여 주기 좋습니다.

</Card>
<Card demo="progress/do-caption" tone="do" eyebrow="이렇게 하세요">

진행이 느릴 때는 지금 무엇을 하는지 `caption` 으로 알립니다.

</Card>
</Cards>

```dart
RadialProgress(
  value: 75,
  showValueText: true,
)
```

### Don't

<Cards columns="2">
<Card demo="progress/dont-silent" tone="dont" eyebrow="이렇게 하지 마세요">

진행률이 멈춘 것처럼 보이는 상태를 아무 설명 없이 두지 마세요.

</Card>
<Card demo="progress/dont-tone-only" tone="dont" eyebrow="이렇게 하지 마세요">

실패나 경고를 채움 색만으로 알리지 마세요. `tone` 은 보조 기술이 읽는 값에 들어가지 않습니다.

</Card>
</Cards>

## 배치

직선형 막대는 부모의 폭을 채웁니다. 다른 내용과 한 줄에 놓을 때는 막대가 쓸 폭을 정합니다.

<Preview demo="progress/in-row" />

<Split>

<Code language="dart" title="Flutter">
Row(
  children: [
    Text('다운로드'),
    const Gap.space12(),
    Expanded(child: Progress(value: 0.42)),
    const Gap.space12(),
    Text('42%'),
  ],
)
</Code>

<Code language="dart" title="Jaspr Web">
div(
  styles: Styles(raw: {'display': 'flex', 'align-items': 'center'}),
  [
    Text('다운로드'),
    const Gap.space12(),
    div(
      styles: Styles(raw: {'flex': '1', 'min-width': '0'}),
      [Progress(value: 0.42)],
    ),
    const Gap.space12(),
    Text('42%'),
  ],
)
</Code>

</Split>

- **Flutter** — `Row` 처럼 폭을 제한하지 않는 부모에는 `Expanded` 나 `SizedBox` 로 폭을 주어야 합니다. 그대로 넣으면 레이아웃 오류가 납니다.
- **Flutter** — 연속 막대와 불확정 막대는 `LayoutBuilder` 를 씁니다. 자식의 내용 크기를 먼저 재는 `IntrinsicWidth` · `IntrinsicHeight` 안에는 둘 수 없습니다.
- `label` 과 `caption` 은 길면 줄이 바뀝니다. `valueLabel` 은 자기 폭을 줄이지 않으므로 짧게 씁니다. 긴 글을 넣으면 `label` 자리가 줄고 막대 폭을 넘칠 수 있습니다.
- `RadialProgress` 는 `size` 가 정한 지름의 정사각형입니다.

## 테마와 스타일

동작 · 종류 · 내용은 위젯 파라미터로 넘기고, 색 · 두께 · 시간 · 글자처럼 보이는 값은 `progressStyle`(`CoreProgressStyle`)이나 `radialProgressStyle`(`CoreRadialProgressStyle`) 하나로 덮어씁니다.

| 위젯 | 위젯 파라미터 | 스타일 |
| --- | --- | --- |
| `Progress` | `value` · `min` · `max` · `disableAnimation` · `segments` · `size` · `tone` · `label` · `valueLabel` · `caption` | `progressStyle` |
| `RadialProgress` | `value` · `showValueText` · `size` · `tone` · `child` | `radialProgressStyle` |

### 트랙과 채움 색

- 트랙의 기본색은 채움 색을 따라가지 않는 중립색 `surfaceContainerHigh` 입니다. 같은 색의 면 위에 놓으면 트랙이 보이지 않으므로 `backgroundColor` 를 바꿉니다.
- `backgroundAlpha` 를 주면 채움 색(원형은 호의 색)을 그만큼 옅게 만든 색이 트랙이 됩니다. `backgroundColor` 를 함께 주면 `backgroundColor` 가 우선합니다.

```dart
Progress(
  value: 0.5,
  progressStyle: CoreProgressStyle(backgroundAlpha: 0.2),
)
```

### 값이 정해지는 순서

뒤에 있을수록 우선하고, 정하지 않은 필드는 앞의 값이 남습니다.

```text
// Progress
디자인 시스템 기본값 (size 의 두께, tone 의 채움 색 포함)
  → CoreProgressTheme.style              // 모든 막대
  → CoreProgressTheme.toneStyles[tone]   // 그 tone 의 막대
  → progressStyle                        // 인스턴스별

// RadialProgress
디자인 시스템 기본값 (size 의 지름 · 두께 · 글자, tone 의 호 색 포함)
  → CoreRadialProgressTheme.style        // 모든 원형
  → radialProgressStyle                  // 인스턴스별
```

`size` 와 `tone` 은 위젯에서만 고르고 테마가 바꾸지 않습니다. 다만 테마에 **직접 적은 필드는 `size` · `tone` 이 고를 값보다 우선**합니다.

- `CoreProgressTheme.style` 에 `color` 를 적으면 모든 톤이 같은 색이 됩니다. 톤마다 색을 바꾸려면 `toneStyles` 에 적습니다.
- `style` 에 `minHeight` 를 적으면 `size` 를 바꿔도 두께가 그대로입니다.
- `CoreRadialProgressTheme` 에는 톤별 칸이 없습니다. `style` 의 `color` 는 모든 톤을 같은 색으로, `size` 는 모든 크기 단계를 같은 지름으로 만듭니다.

### 사용 예

<Split>

<Code language="dart" title="막대 하나만 바꾸기">
Progress(
  value: 0.5,
  progressStyle: CoreProgressStyle(
    color: CoreColor.token(CoreColors.tertiary),
    minHeight: CoreSpace.space12,
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    progress: CoreProgressTheme(
      style: CoreProgressStyle(segmentSpacing: CoreSpace.space8),
      toneStyles: {
        CoreProgressTone.primary: CoreProgressStyle(
          color: CoreColor.token(CoreColors.tertiary),
        ),
      },
    ),
    radialProgress: CoreRadialProgressTheme(
      style: CoreRadialProgressStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainerHighest),
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

이미 만든 `Progress` 에 `withStyle` 을 이어 `progressStyle` 을 덧붙일 수 있습니다. 생성자의 `progressStyle` 인자와 같게 동작하고, 나중에 이은 값이 같은 필드에서 우선합니다. `.radius9999` 처럼 Core 토큰 상수와 이름이 같은 getter 도 있습니다. `withStyle` 을 한 번 더 줄인 것으로, 이름이 곧 값이라(`radius9999` 는 `CoreRadius.radius9999`) 어느 컴포넌트에서 써도 뜻이 같습니다.

- `.fillColor(.primary)`는 채움색을 직접 지정하며 `tone`의 기본 채움색보다 우선합니다.
- `Progress(value: 0.5).success`는 성공 톤을 선택합니다. 트랙 색은 `.backgroundColor(.surfaceContainer)`로 정합니다.
- `.transparent` 만은 트랙을 비웁니다. 다른 컴포넌트에서처럼 "바탕 없음" 이라는 뜻입니다. 채움을 투명하게 하면 막대가 보이지 않기 때문입니다.
- `RadialProgress` 에는 체인이 없습니다.
- Web의 색 체인은 생성자에 지정한 HTML 속성을 보존합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ProgressChainExample extends StatefulWidget {
  const ProgressChainExample({super.key});

  @override
  State<ProgressChainExample> createState() => _ProgressChainExampleState();
}

class _ProgressChainExampleState extends State<ProgressChainExample> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        SizedBox(
          width: double.infinity,
          child: const Progress(value: 0.65).radius16.fillColor(.primary),
        ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(minHeight)까지 한 번에.
        SizedBox(
          width: double.infinity,
          child: const Progress(value: 0.65).withStyle(
            const CoreProgressStyle(
              color: .tertiary,
              borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              minHeight: CoreSpace.space16,
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
class ProgressChainExample extends StatefulComponent {
  const ProgressChainExample({super.key});

  @override
  State<ProgressChainExample> createState() => _ProgressChainExampleState();
}

class _ProgressChainExampleState extends State<ProgressChainExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Progress(value: 0.65).radius16.fillColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(minHeight)까지 한 번에.
        Progress(value: 0.65).withStyle(
          const CoreProgressStyle(
            color: .tertiary,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            minHeight: CoreSpace.space16,
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

### 기본값이 있는 곳

기본값은 `coui_core` 의 `CoreProgressStyle` 과 `CoreRadialProgressStyle` 에 있고, Flutter와 Web이 같은 값을 읽습니다.

| 이름 | 정하는 것 |
| --- | --- |
| `CoreProgressStyle.defaultsBySize[size]` | 직선형 두께 |
| `CoreProgressStyle.defaultsByTone[tone]` | 직선형 채움 색 |
| `CoreProgressStyle.defaultBackgroundColor` | 직선형 트랙 색 (`surfaceContainerHigh`) |
| `CoreProgressStyle.defaultBorderRadius` | 모서리 (`radius9999`) |
| `CoreProgressStyle.defaultDuration` | 값 전환 시간 (300ms) |
| `CoreProgressStyle.defaultIndeterminateDuration` | 불확정 막대가 한 번 지나가는 시간 (1500ms) |
| `CoreProgressStyle.defaultIndeterminateFillRatio` | 불확정 채움의 폭 비율 (0.35) |
| `CoreProgressStyle.defaultSegmentSpacing` | 칸 사이 간격 (`space4`) |
| `CoreProgressStyle.defaultLabelStyle` · `defaultValueLabelStyle` · `defaultCaptionStyle` | 세 칸의 글자 |
| `CoreProgressStyle.defaultLabelGapStyle` · `defaultCaptionGapStyle` | 칸과 막대 사이 (`space8`) |
| `CoreRadialProgressStyle.defaultsBySize[size]` | 원형의 지름 · 링 두께 · 가운데 글자 |
| `CoreRadialProgressStyle.defaultsByTone[tone]` | 원형의 호 색 |
| `CoreRadialProgressStyle.defaultBackgroundColor` | 원형의 트랙 색 (`surfaceContainerHigh`) |

<a id="접근성-accessibility"></a>

## 접근성

진행률은 표시 전용입니다. 보조 기술에 전달하는 정보는 위젯과 플랫폼에 따라 다릅니다. 움직임은 [동작 줄이기](#동작-줄이기)를 확인하세요.

### 역할

| 위젯 | Jaspr Web | Flutter |
| --- | --- | --- |
| `Progress` | `role="progressbar"` 와 `aria-valuemin` · `aria-valuemax`. `aria-valuenow` 는 값이 있을 때만. `label` 이 있으면 `aria-labelledby`, `caption` 이 있으면 `aria-describedby`, 단계형이면 `aria-valuetext` | `Semantics(value: …)` 만 붙입니다. progressbar 역할과 최솟값 · 최댓값은 없습니다. 칸이 있으면 `MergeSemantics` 로 한 노드가 됩니다. |
| `RadialProgress` | `role="progressbar"` 와 `aria-valuenow`(0–100 의 정수, 소수점 아래 버림). `aria-valuemin` · `aria-valuemax` 는 없어 ARIA 기본값 0–100 이 적용됩니다. | 시맨틱 정보를 붙이지 않습니다. |

Web 에서 컴포넌트가 직접 붙이는 위 표의 속성은 `attributes` 로 넘긴 같은 이름의 값보다 우선합니다. 컴포넌트가 붙이지 않는 속성은 넘긴 그대로 남습니다. `aria-label` 이나, 단계형이 아닌 막대의 `aria-valuetext` 가 그렇습니다.

### 키보드

없음. 진행률은 포커스를 받지 않고 `Tab` 순서에 들어가지 않습니다. 값을 바꾸는 키도 없습니다. 사용자가 값을 조절해야 하면 [Slider](/components/slider)를 씁니다.

### 스크린 리더

- **Jaspr Web** — `aria-valuenow` 에는 넘긴 값이 환산 없이 실리고(`Progress(value: 0.65)` → `0.65`) `aria-valuemin` · `aria-valuemax` 가 함께 있습니다. 이 값을 어떻게 읽는지는 화면 읽기 프로그램이 정합니다. 불확정 막대에는 `aria-valuenow` 가 없습니다.
- **Flutter** — `min`–`max` 를 0–100 으로 바꾸고 반올림한 백분율 문자열(`65%`)이 값이 됩니다. 불확정 막대는 `0%` 대신 현재 언어의 로딩 문구를 값으로 냅니다.
- **단계형** — 두 플랫폼 모두 백분율 대신 단계를 현재 언어의 문구로 알립니다(`Step 1 of 2`, `2단계 중 1단계`). 앱에 언어 설정이 없으면 영어입니다. Web 은 이 문구를 `aria-valuetext` 에 담고 `aria-valuenow` 등은 넘긴 값 그대로 둡니다. Flutter 는 같은 문구를 `Semantics` 의 값으로 냅니다.
- `label` 은 막대의 이름이 됩니다. `caption` 은 Web 에서 이름과 구분되는 설명(`aria-describedby`)이고, Flutter 에서는 한 노드로 합쳐져 이름에 이어집니다.
- `valueLabel` 은 값을 화면에 다시 적는 칸이라 따로 전달하지 않습니다.
- `tone` 은 색으로만 나타납니다. 실패나 경고는 `label` · `caption` 글로도 알립니다.
- 값이 바뀌었다고 알리는 라이브 영역은 두 플랫폼 모두 없습니다. 진행 상황을 소리로 알려야 하면 라이브 영역을 따로 둡니다.
- Flutter 의 `RadialProgress` 에서 전달되는 것은 가운데 내용뿐입니다. `showValueText` 의 퍼센트 글이나 `child` 가 가진 시맨틱입니다.

#### 이름 붙이기

보이는 이름은 두 플랫폼 모두 `Progress` 의 `label` 로 충분합니다. 화면에 라벨 없이 이름만 붙이거나 `RadialProgress` 에 이름을 붙이려면 플랫폼에 맞는 방법을 씁니다.

<Preview demo="progress/a11y-name" />

<Split>

<Code language="dart" title="Flutter">
Semantics(
  label: '파일 업로드',
  child: Progress(value: 0.4),
)

Semantics(
  label: '저장 공간',
  value: '75%',
  child: ExcludeSemantics(
    child: RadialProgress(value: 75, showValueText: true),
  ),
)
</Code>

<Code language="dart" title="Jaspr Web">
Progress(
  value: 0.4,
  attributes: {'aria-label': '파일 업로드'},
)

RadialProgress(
  value: 75,
  showValueText: true,
  attributes: {'aria-label': '저장 공간'},
)
</Code>

</Split>

### 포커스 관리

없음. 컨트롤도 오버레이도 아니므로 포커스를 옮기거나 가두지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | `Progress` 에 progressbar 역할과 최솟값 · 최댓값이 없습니다. 역할이 필요하면 바깥 `Semantics` 에 `role` · `value` · `minValue` · `maxValue` 를 직접 주고 안쪽은 `ExcludeSemantics` 로 감쌉니다. |
| Flutter | `RadialProgress` 에는 시맨틱 정보가 없습니다. 위의 예처럼 `Semantics` 로 이름과 값을 줍니다. |
| 공통 | `label` 이 없는 `Progress` 와 모든 `RadialProgress` 에는 기본 이름이 없습니다. |
| Jaspr Web | 범위를 벗어난 `value` 를 넘기면 `aria-valuenow` 도 `aria-valuemin`–`aria-valuemax` 를 벗어납니다. |
| Jaspr Web | 직선형의 트랙과 채움은 테두리 없이 배경색으로만 구분합니다. 운영체제의 색 강제 모드에서는 진행 위치가 보이지 않을 수 있습니다. `aria-*` 값은 그대로 남습니다. |
| Jaspr Web | `RadialProgress` 의 바깥 상자는 `rem`, 안의 링 그림은 `px` 입니다. 브라우저의 기본 글자 크기가 16px 이 아니면 링의 중심과 가운데 글의 위치가 어긋납니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

클래스 이름(`Progress` · `RadialProgress`), 파라미터 이름, 기본 범위(직선형 0.0–1.0, 원형 0–100)는 두 플랫폼이 같습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 슬롯 타입 | `Widget` | `Component` |
| 범위를 벗어난 직선형 값 | 디버그 빌드에서 `assert` 오류. `assert` 가 꺼지면 막대와 읽는 값을 자릅니다. | 막대만 자르고 `aria-valuenow` 는 넘긴 값 그대로입니다. |
| `max` 와 `min` 이 같은 연속 막대 | 가득 찬 막대 | 빈 막대 |
| 직선형 그리기 | `Container` 와 `AnimatedContainer` | `div` 와 인라인 스타일 |
| 라벨 칸 구조 | 칸이 있으면 `Column` 안에 라벨 행, 막대, 캡션 | 칸이 있으면 같은 순서의 세로 `flex` 상자. 이 상자가 `role="progressbar"` 입니다. |
| 단계형 그리기 | `Row(spacing: segmentSpacing)` 안의 `Expanded` 칸 | `flex` 행과 `column-gap`. 라벨 칸이 없으면 이 행이 `role="progressbar"` 입니다. |
| 값 전환 | 폭과 색을 `AnimatedContainer` 로 전환 | CSS `transition` — 연속 막대는 폭, 단계형은 칸 배경색 |
| 불확정 막대의 `indeterminateDuration` 변경 | 이미 그려진 막대는 처음의 시간을 계속 씁니다. | 바뀐 시간이 적용됩니다. |
| 원형 그리기 | `CustomPaint` | 인라인 `svg` 의 `circle` 두 개(트랙과 호) |
| 원형의 `child` | 링 가운데에 놓습니다. | 가운데로 옮기지 않습니다. [가운데 내용 직접 넣기](#가운데-내용-직접-넣기)처럼 감쌉니다. |
| 칸에 넣은 글자 역할 체인 | 색이 `onSurface` 가 됩니다. | 칸의 색을 유지합니다. |
| 크기 배율 | 두께, 원형 지름 등에 `theme.scaling` 을 곱합니다. | 막대 두께와 원형의 바깥 상자는 `rem`, 원형의 링 그림은 `px` 입니다. |
| 선 두께에 하한을 두는 서페이스 스타일 | 두꺼워진 링에 맞춰 반지름을 다시 계산합니다. | 선만 두꺼워지고 반지름은 그대로라, 링의 바깥 가장자리가 잘릴 수 있습니다. |
| HTML 속성 | 없음 — 이름은 `Semantics` 로 감쌉니다. | `id` · `classes` · `css` · `attributes` · `tag` |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. 표의 `W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다. 직선형의 값은 `min`–`max` 범위이고, 원형의 값은 0–100 퍼센트입니다.

### Progress (직선형)

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `double?` | `null` | 진행 값. `null` 이면 불확정 막대 |
| `min` | `double` | `0.0` | 최솟값 |
| `max` | `double` | `1.0` | 최댓값 |
| `disableAnimation` | `bool` | `false` | 값이 있는 막대의 전환을 끕니다. |
| `segments` | `int?` | `null` | 막대를 이 수의 칸으로 나눕니다. `null` 이면 연속 막대. 1 이상. 불확정 막대에서는 쓰지 않습니다. |
| `size` | `CoreProgressSize` | `sm` | 막대 두께 단계 |
| `tone` | `CoreProgressTone` | `primary` | 채움 색의 뜻 — `primary` · `success` · `warning` · `destructive` |
| `label` | `W?` | `null` | 막대 위 왼쪽 칸 — 이름 |
| `valueLabel` | `W?` | `null` | 막대 위 오른쪽 칸 — 값 |
| `caption` | `W?` | `null` | 막대 아래 칸 — 보조 설명 |
| `progressStyle` | `CoreProgressStyle?` | `null` | 보이는 값 덮어쓰기 |

### RadialProgress (원형)

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `double` | 필수 | 진행률(0–100). 범위를 벗어나면 잘라 씁니다. |
| `showValueText` | `bool` | `false` | 가운데에 퍼센트 글을 그립니다. `sm` 은 `valueTextStyle` 을 줄 때만 |
| `size` | `CoreProgressSize` | `lg` | 크기 단계. `xs2` · `xs` 는 `sm` 으로 그립니다. |
| `tone` | `CoreProgressTone` | `primary` | 호 색의 뜻 |
| `child` | `W?` | `null` | 가운데에 넣을 내용. 주면 퍼센트 글을 대신합니다. |
| `radialProgressStyle` | `CoreRadialProgressStyle?` | `null` | 보이는 값 덮어쓰기 |

<a id="coreradialprogressstyle-필드-chrome"></a>

#### `CoreRadialProgressStyle` 필드 (겉모습)

| 속성 | 타입 | 정하지 않았을 때 | 설명 |
| --- | --- | --- | --- |
| `color` | `CoreColor?` | `tone` 의 색 | 호 색. 주면 `tone` 보다 우선합니다. |
| `backgroundColor` | `CoreColor?` | `surfaceContainerHigh` | 트랙 링 색 |
| `backgroundAlpha` | `double?` | 중립색 트랙 | `backgroundColor` 가 없을 때, 호 색을 이 비율로 옅게 만든 트랙 |
| `size` | `double?` | `size` 단계의 지름 | 원의 지름(논리 픽셀) |
| `strokeWidth` | `double?` | `size` 단계의 두께 | 링 두께(논리 픽셀) |
| `valueTextStyle` | `CoreTextStyle?` | `size` 단계의 글자 역할과 `onSurface` | 가운데 퍼센트 글. 단계의 값 위에 준 필드만 덮어씁니다. |

### Web 전용

두 위젯에 모두 있습니다.

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `attributes` | `Map<String, String>?` | `null` | 루트 요소의 HTML 속성 — `aria-label`, `data-*` 등 |
| `id` · `classes` · `css` | `String?` · `String?` · `Styles?` | `null` | 루트의 id 와 배치용 클래스 · 스타일 |
| `tag` | `String` | `'div'` | 루트 요소의 태그. `Progress` 는 이 태그를 바꿀 수 있고, `RadialProgress` 의 루트는 늘 `div` 입니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreProgressStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `color` | `CoreColor?` | Progress fill colour override. |
| `backgroundColor` | `CoreColor?` | Track background colour override. `null` (default) → [defaultBackgroundColor], unless [backgroundAlpha] is stated. |
| `backgroundAlpha` | `double?` | Track background alpha — a track derived from the fill (`color` faded by this alpha) instead of the neutral [defaultBackgroundColor]. Applied only when [backgroundColor] is not set. `null` (default) → the neutral track. |
| `borderRadius` | `CoreBorderRadius?` | Border radius override. Applies to both track and indicator so rounded shapes remain visually consistent. |
| `minHeight` | `double?` | Minimum height (thickness) override (logical px). `null` defers to [defaultsBySize] for the active `CoreProgressSize`. |
| `duration` | `Duration?` | Determinate width transition duration override. |
| `indeterminateDuration` | `Duration?` | Indeterminate slide cycle duration override. |
| `indeterminateFillRatio` | `double?` | Indeterminate fill width as a share of the track, `0..1`. `null` defers to [defaultIndeterminateFillRatio]. Both platforms derive the slide's travel from it. |
| `labelStyle` | `CoreTextStyle?` | `label` cell text override, laid over [defaultLabelStyle] field by field. Whatever you put in the `label` slot inherits it as its text style. |
| `valueLabelStyle` | `CoreTextStyle?` | `valueLabel` cell text override, merged field by field onto [defaultValueLabelStyle]. |
| `captionStyle` | `CoreTextStyle?` | `caption` cell text override, merged field by field onto [defaultCaptionStyle]. |
| `labelGapStyle` | `CoreGapStyle?` | Spacer between the label row and the bar — drawn only when the bar has a `label` or `valueLabel`. Merged onto [defaultLabelGapStyle]. |
| `captionGapStyle` | `CoreGapStyle?` | Spacer between the bar and the caption — drawn only when the bar has a `caption`. Merged onto [defaultCaptionGapStyle]. |
| `segmentSpacing` | `double?` | Gap between the cells of a segmented bar (`Progress.segments`), in logical pixels — `Row.spacing` (Flutter) / the cell row's `column-gap` (Web). A continuous bar never reads it. `null` defers to [defaultSegmentSpacing]. |

<!-- STYLE_TABLE:END -->

<Note>

위 표는 직선형 `Progress` 의 스타일입니다. 두 가지를 덧붙입니다.

- `minHeight` 는 최솟값이 아니라 막대의 두께 그대로입니다.
- `duration` 은 채움 폭 전환과 단계형의 칸 색 전환 시간을 함께 정합니다. Flutter 의 연속 막대는 채움 색 전환에도 이 시간을 씁니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="progress/related-loading" title="Loading">

작업 중이라는 것만 알리는 움직이는 표시입니다. [Loading 문서](/components/loading)

</Card>
<Card demo="progress/related-skeleton" title="Skeleton">

불러올 콘텐츠의 자리를 미리 잡는 자리 표시입니다. [Skeleton 문서](/components/skeleton)

</Card>
<Card demo="progress/related-slider" title="Slider">

사용자가 값을 조절합니다. `Progress` 는 읽기 전용입니다. [Slider 문서](/components/slider)

</Card>
<Card demo="progress/related-tracker" title="Tracker">

여러 시점의 상태를 칸으로 나란히 보여 줍니다. [Tracker 문서](/components/tracker)

</Card>
</Cards>
