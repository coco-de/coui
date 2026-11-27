---
title: Loading
description: 작업이 진행 중임을 알리는 움직이는 표시입니다. 모양(variant), 색(tone), 크기를 따로 고릅니다.
category: display
platforms: [flutter, web]
related: [loading-region, skeleton, progress, empty-state]
tags: [loading, animation, feedback, async]
template: v2
source: display/loading
---

# Loading

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

비동기 작업이나 데이터를 불러오는 중임을 알리는 표시입니다. 얼마나 끝났는지는 말하지 않습니다. 속성을 바꿔 보며 확인하고, 만들어진 코드를 그대로 복사하세요. 아무 값도 주지 않은 `Loading()` 은 한 변이 16인 `spinner` 를 `primary` 톤으로 그립니다.

<Playground component="loading" />

- `componentSize` 의 기본값은 `null` 이고, 이때의 모양은 `xs` 와 같습니다. 플레이그라운드는 잘 보이도록 `lg` 에서 시작합니다.
- `inverse` 톤은 흰 바탕에서 보이지 않아, 미리보기가 `primary` 로 채운 면 위에 올립니다. 그 면은 `Loading` 이 그리지 않습니다.

<a id="변형-variants"></a>

## Variant

`variant` 는 모양을 고릅니다. 기본값은 `spinner` 입니다. 색(`tone`)과 크기(`componentSize`)는 네 모양에서 똑같이 고릅니다. 한 번 움직이는 시간은 [움직임](#움직임)에 모았습니다.

### Spinner

<VariantRow name="spinner" component="loading" props="variant=spinner;size=lg">

옅은 원(트랙) 위에서 원의 4분의 1(90°)인 호가 돕니다. 호의 양 끝은 둥글고, 12시에서 출발해 시계 방향으로 돕니다.

</VariantRow>

### Dots

<VariantRow name="dots" component="loading" props="variant=dots;size=lg">

점 셋을 점 지름의 절반만큼 띄워 놓습니다. 점의 자리와 크기는 그대로이고 불투명도만 바뀝니다. 처음에는 왼쪽부터 1 · 0.6 · 0.3이고, 가장 진한 점이 왼쪽에서 오른쪽으로 옮겨 갑니다.

</VariantRow>

### Bar

<VariantRow name="bar" component="loading" props="variant=bar;size=lg">

길이가 크기의 2배인 트랙 위에서, 트랙 길이의 35%인 막대가 두 끝 사이를 오갑니다. 차지하는 상자는 트랙(길이 × 두께) 그대로입니다.

</VariantRow>

### Pulse

<VariantRow name="pulse" component="loading" props="variant=pulse;size=lg">

지름이 크기의 40%인 가운데 점은 그대로 있고, 같은 색의 옅은 원이 점 크기에서 전체 크기까지 퍼지며 사라집니다. 퍼지기 시작할 때의 불투명도는 0.2입니다.

</VariantRow>

```dart
Loading() // spinner
Loading(variant: CoreLoadingVariant.dots)
Loading(variant: CoreLoadingVariant.bar)
Loading(variant: CoreLoadingVariant.pulse)
```

Flutter와 Web 코드가 같습니다.

<a id="톤-tone"></a>

## 톤

`tone` 은 지시자(호 · 점 · 막대 · 원) 색을 정합니다. `spinner` · `bar` 의 트랙 색도 함께 정합니다. `dots` · `pulse` 에는 트랙이 없습니다. `Loading` 은 둘레의 글자색이나 아이콘 색을 따라가지 않으므로, 놓는 바탕에 맞는 톤을 직접 고릅니다.

| 톤 | 지시자 | 트랙 | 쓰는 곳 |
| --- | --- | --- | --- |
| `primary` (기본) | `primary` | 중립 면 (`surfaceContainerHigh`) | 일반 면 위 |
| `neutral` | `onSurfaceVariant` | 중립 면 (`surfaceContainerHigh`) | 본문 옆의 조용한 로딩 |
| `inverse` | `onPrimary` | 지시자 색의 25% | `primary` 로 채운 면 위 |

<VariantRow name="primary" component="loading" props="tone=primary;size=lg">

브랜드 강조색입니다. 기본값입니다.

</VariantRow>

<VariantRow name="neutral" component="loading" props="tone=neutral;size=lg">

눈길을 덜 끌어야 하는 자리에 씁니다.

</VariantRow>

<VariantRow name="inverse" component="loading" props="tone=inverse;size=lg">

`primary` 와 짝을 이루는 `onPrimary` 색입니다. 라이트와 다크에서 색은 달라져도 `primary` 면과 짝인 것은 같습니다. 그 밖의 어두운 면에서는 대비를 직접 확인하세요.

</VariantRow>

```dart
Loading(tone: CoreLoadingTone.inverse)
```

<a id="크기-sizes"></a>

## 크기

`componentSize` 는 여섯 단계입니다. 단계마다 상자 크기, 선 두께, 점 지름, 막대 두께가 함께 정해집니다. 아래 미리보기는 `spinner` 이고, 표의 수는 논리 픽셀입니다.

<SizeSpec component="loading" />

- 「상자 한 변」은 `spinner` · `dots` · `pulse` 가 차지하는 정사각형의 한 변입니다. `bar` 는 길이가 그 2배인 띠입니다.
- `componentSize` 를 비우면 `xs` 행과 같게 그립니다. `md`(24)가 아닙니다.

나머지 세 모양은 단계마다 이렇게 그려집니다.

<Preview demo="loading/size-variants" />

```dart
Loading(componentSize: CoreComponentSize.lg)
```

### 픽셀 값으로 정하기

상자 한 변은 `loadingStyle` 의 `size` 에 직접 적을 수도 있습니다. 적은 `size` 는 `componentSize` 보다 우선합니다.

```dart
Loading(loadingStyle: CoreLoadingStyle(size: CoreSize.size64))
```

`componentSize` 없이 `size` 만 적으면 `dots` 의 점 지름은 `size` 의 1/4, `bar` 의 두께는 1/8, 길이는 2배가 되고, `pulse` 의 가운데 점은 40%입니다. `spinner` 의 선 두께는 크기를 따라가지 않고 2로 남습니다. 굵게 하려면 `strokeWidth` 를 함께 적습니다.

<Preview demo="loading/pixel-size" />

<Note>

`componentSize` 와 `size` 를 함께 주면 상자는 `size` 를 따르고, 선 두께 · 점 지름 · 막대 두께는 `componentSize` 단계에 남습니다. `dots` 는 점 셋과 두 간격을 합쳐 점 지름의 4배 폭이 필요합니다. `size` 가 그보다 작으면 Flutter는 레이아웃 넘침 오류를 내고, 웹은 점이 가로로 눌립니다. 이때는 `dotSize` 를 `size` 의 1/4 이하로 함께 적으세요. 테마에 적은 `size` 도 같습니다.

</Note>

<a id="동작-스펙-behavior"></a>

## 움직임

### 애니메이션

네 모양 모두 화면에 있는 동안 계속 반복합니다.

| 모양 | 한 주기 | 기본값 토큰 | 한 주기의 움직임 | 속도 |
| --- | --- | --- | --- | --- |
| `spinner` | 1000ms | `CoreDuration.ms1000` | 호가 한 바퀴 돕니다 | 일정합니다 |
| `dots` | 1000ms | `CoreDuration.ms1000` | 점마다 1/3 주기씩 어긋나며 불투명도가 1 · 0.3 · 0.6을 차례로 지납니다 | 값 사이를 일정하게 잇습니다 |
| `bar` | 1500ms | `CoreDuration.indeterminate` | 막대가 왼쪽 끝에서 오른쪽 끝까지 갔다가 돌아옵니다 | `CoreEasing.move` (ease-in-out) |
| `pulse` | 1000ms | `CoreDuration.ms1000` | 원이 퍼지며 사라진 뒤 처음부터 다시 퍼집니다 | `CoreEasing.move` (ease-in-out) |

주기는 `loadingStyle` 의 `duration` 으로 바꿉니다. 두 플랫폼의 코드가 같습니다.

```dart
Loading(
  loadingStyle: CoreLoadingStyle(
    duration: Duration(milliseconds: CoreDuration.ms2000),
  ),
)
```

### 동작 줄이기

운영체제에서 동작 줄이기를 켜도 기본 주기의 네 모양은 계속 움직입니다. 멈춘 표시는 아직 작업 중이라는 것을 알리지 못하기 때문입니다. 멈출지는 주기의 길이로 정해집니다.

| 주기 (`duration`) | 동작 줄이기를 켰을 때 |
| --- | --- |
| 500ms보다 긺 (기본값 전부) | 그대로 움직입니다 |
| 500ms 이하로 덮어씀 | 화면 전환에 쓰는 짧은 시간으로 보고 멈춥니다 |
| `Duration.zero` | 설정과 상관없이 멈춰 있습니다 |

멈췄을 때의 모습은 두 플랫폼이 같습니다.

- `spinner` — 호가 12시에서 시작하는 자리에 섭니다.
- `dots` — 세 점이 모두 불투명합니다.
- `bar` — 막대가 트랙의 왼쪽 끝에 섭니다.
- `pulse` — 가운데 점 둘레에 전체 크기의 옅은 원(불투명도 0.2)이 남습니다.

## 상태

### 인터랙션

- `Loading` 은 보여 주기만 합니다. 누르기 · 포커스 · 비활성 상태가 없습니다.
- 작업의 시작 · 완료 · 진행값 · 타이머를 알리는 콜백을 받지 않습니다.
- 뒤를 가리는 층도 그리지 않습니다. 작업 중에 뒤의 내용을 누르지 못하게 하려면 그 층은 따로 만들고 안에 `Loading` 을 둡니다.
- 웹의 `onClick` 같은 속성은 루트 `<span>` 에 이벤트를 연결할 뿐, 버튼의 역할이나 키보드 동작을 만들지 않습니다.

### 상태 전환

- 로딩 시작 — 화면에 넣으면 바로 그려지고 움직이기 시작합니다. 늦게 보여 주는 속성도, 나타날 때의 전환도 없습니다.
- 로딩 완료 — 부모가 조건에 따라 빼거나 실제 내용으로 바꿉니다.

```dart
isLoading ? Loading() : OrderList(orders: orders)
```

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 데이터를 불러오거나 저장하는 중이라는 것을 알릴 때
- 내용이 어떤 모양으로 올지 알 수 없는 비동기 작업을 기다릴 때
- 버튼을 누른 뒤 처리가 끝나기를 기다리는 상태를 보일 때
- 화면 전체를 가리는 대기 층 안에 표시를 둘 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 당겨서 새로고침하는 제스처와 그 진행 단계를 다룰 때 | [RefreshTrigger](/components/refresh-trigger) |
| 최종 콘텐츠의 모양을 미리 그릴 수 있을 때 — 그 자리의 모양은 호출하는 쪽이 만듭니다 | [Skeleton](/components/skeleton) |
| 완료율을 알고 보여야 할 때 — `Loading` 은 작업 중이라는 것만 알립니다 | [Progress](/components/progress) |
| 한 영역의 로딩을 원하는 문구로 알릴 때 | [LoadingRegion](/components/loading-region) |
| 불러오기가 끝났는데 보여 줄 데이터가 없을 때 | [EmptyState](/components/empty-state) |

<a id="do"></a>
<a id="dont"></a>

### 문구 · 개수 · 버튼

<Cards columns="2">
<Card demo="loading/do-caption" tone="do" eyebrow="이렇게 하세요">

무슨 작업인지 곁에 글로 적습니다. 기다리는 이유를 알면 덜 불안합니다.

</Card>
<Card demo="loading/dont-many" tone="dont" eyebrow="이렇게 하지 마세요">

행마다 표시를 따로 두지 않습니다. 표시 하나하나가 라이브 영역이라 같은 이름이 여러 번 생기고 화면도 어수선합니다. 영역에 하나만 둡니다.

</Card>
<Card demo="loading/do-button" tone="do" eyebrow="이렇게 하세요">

처리 중인 버튼은 `onPressed` 를 비워 다시 눌리지 않게 하고, 비활성 면에서도 보이는 `neutral` 톤을 씁니다.

</Card>
<Card demo="loading/dont-button-inverse" tone="dont" eyebrow="이렇게 하지 마세요">

비활성 버튼에는 `inverse` 를 쓰지 않습니다. 버튼 면이 `primary` 에서 비활성 면으로 바뀌어 `onPrimary` 색의 호가 묻힙니다.

</Card>
</Cards>

버튼 안의 로딩은 누른 것이 처리되고 있음을 바로 알립니다. `Button` 에는 로딩 전용 속성이 없으므로 `leading` 에 넣습니다.

```dart
Button(
  onPressed: isSubmitting ? null : handleSubmit,
  leading: isSubmitting ? Loading(tone: CoreLoadingTone.neutral) : null,
  child: Text(isSubmitting ? '제출 중...' : '제출하기'),
)
```

### 보여 줄지 정하기

**아주 짧은 작업에는 넣지 않습니다.** 표시가 잠깐 나타났다 사라지면 화면이 깜빡이는 것으로 보입니다. 300ms 안에 끝나는 작업이라면 넣지 않는 편이 낫습니다. `Loading` 에는 늦게 보여 주는 속성이 없으므로, 필요하면 부모가 시간을 재서 넣습니다.

<Code language="dart" title="이렇게 하지 마세요 (Flutter)">
// 50ms 면 끝나는 작업에도 표시가 번쩍였다가 사라집니다.
FutureBuilder(
  future: fastLocalOperation(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Loading();
    }
    return content;
  },
)
</Code>

**모양을 미리 알 수 있으면 Skeleton 을 씁니다.** 카드 목록처럼 구조가 정해진 자리는 [Skeleton](/components/skeleton) 으로 자리를 잡아 두면, 내용이 올 때 화면이 덜 움직입니다.

<Code language="dart" title="이렇게 하지 마세요 (Flutter)">
// 카드 목록 자리에 표시 하나만 두면, 내용이 오는 순간 화면이 크게 바뀝니다.
if (isLoading) {
  return Center(child: Loading());
}
return CardList(items: items);
</Code>

**가리는 범위는 바뀌는 곳까지만 둡니다.** 항목 하나를 더하는 작은 갱신에 화면 전체를 가리면 다른 일을 하지 못합니다. 바뀌는 영역에만 로딩을 둡니다.

<Code language="dart" title="이렇게 하지 마세요 (Flutter)">
Stacks(
  children: [
    MainContent(),
    // 작은 갱신인데 화면 전체를 막습니다.
    if (isLoading) FullPageLoadingOverlay(),
  ],
)
</Code>

**진행률을 알 수 있으면 Progress 를 씁니다.** 얼마나 남았는지 보이면 기다릴지 판단하기 쉽습니다.

```dart
Progress(value: uploadProgress) // 0.0 ~ 1.0
```

### 조합 예제

로딩 중 · 결과 없음 · 목록의 세 갈래를 나누는 Flutter 코드입니다. `AnimatedSwitcher` 와 `ListView` 는 Flutter 위젯이라 웹에서는 같은 세 갈래를 조건식으로 나눕니다.

<Code language="dart" title="Flutter">
Widget buildContent() {
  return AnimatedSwitcher(
    duration: Duration(milliseconds: CoreDuration.normal),
    child: isLoading
        ? Center(key: Key('loading'), child: Loading())
        : items.isEmpty
        ? EmptyState(
            key: Key('empty'),
            icon: Icon(LucideIcons.searchX),
            title: Text('결과가 없습니다'),
          )
        : ListView.builder(
            key: Key('list'),
            itemCount: items.length,
            itemBuilder: (context, index) => ItemTile(item: items[index]),
          ),
  );
}
</Code>

## 배치

### 문구와 함께

`Loading` 에는 보이는 라벨 속성이 없습니다. 글은 부모가 함께 놓습니다.

<Split>

<Code language="dart" title="Flutter">
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Loading(componentSize: CoreComponentSize.lg),
    const Gap.space8(),
    Text('데이터를 불러오는 중...').bodySmall.onSurfaceVariant,
  ],
)
</Code>

<Code language="dart" title="Jaspr Web">
div(
  classes: 'flex flex-col items-center',
  [
    Loading(componentSize: CoreComponentSize.lg),
    const Gap.space8(),
    Text('데이터를 불러오는 중...').bodySmall.onSurfaceVariant,
  ],
)
</Code>

</Split>

### 부모가 크기를 정할 때

Flutter의 `spinner` 는 부모가 너비와 높이를 모두 강제하면 `size` 대신 그 상자의 짧은 변에 맞춰 커집니다. 크기를 정한 `SizedBox` 바로 안이나 화면 전체를 채우는 자리에 그대로 두면 큰 원이 그려집니다. `Center` 로 감싸면 정한 크기로 그립니다. 웹은 감싸지 않아도 정한 크기를 지킵니다.

<Code language="dart" title="Flutter">
// 원이 128 상자만큼 커집니다.
SizedBox(
  width: CoreSize.size128,
  height: CoreSize.size128,
  child: Loading(),
)

// 16 크기의 원이 상자 가운데에 놓입니다.
SizedBox(
  width: CoreSize.size128,
  height: CoreSize.size128,
  child: Center(child: Loading()),
)
</Code>

한쪽 축만 늘이는 부모(`CrossAxisAlignment.stretch` 인 `Column` 등)에서는 원 크기가 그대로입니다. 이때 Flutter는 `spinner` · `dots` · `pulse` 를 늘어난 상자의 가운데에 그리고, `bar` 는 가로로는 시작 쪽, 세로로는 가운데에 그립니다.

### 긴 bar

`bar` 는 부모 폭을 채우지 않습니다. 길이는 늘 `size` 의 2배입니다. 더 길게 하려면 `size` 를 키우고, 두께가 함께 커지지 않도록 `barHeight` 를 같이 적습니다.

<Preview demo="loading/wide-bar" />

```dart
Loading(
  variant: CoreLoadingVariant.bar,
  loadingStyle: CoreLoadingStyle(
    size: CoreSize.size128,
    barHeight: CoreStrokeWidth.stroke4,
  ),
)
```

Flutter에서는 부모의 폭을 `bar` 길이보다 좁히지 마세요. 트랙만 좁아지고 막대는 원래 길이를 기준으로 움직여 트랙 밖으로 나갑니다.

## 테마와 스타일

### 파라미터와 스타일

- **종류** — `variant`, `tone`, `componentSize` 는 위젯 파라미터로 넘깁니다.
- **겉모습(색 · 크기 · 두께 · 모서리)과 한 주기의 길이** — `loadingStyle`(`CoreLoadingStyle`) 하나로 덮어씁니다.

### 모양마다 듣는 필드

| 필드 | 듣는 모양 |
| --- | --- |
| `color` · `size` · `duration` | 네 모양 모두 |
| `strokeWidth` | `spinner` |
| `trackColor` · `trackAlpha` | `spinner` · `bar` |
| `dotSize` | `dots` |
| `barHeight` | `bar` |
| `cornerRadius` | `dots` · `bar` · `pulse` |

### 값이 정해지는 순서

먼저 세 곳에 적은 값을 필드마다 합칩니다. 뒤로 갈수록 우선합니다.

```text
CoreLoadingTheme.style                    // 앱 전체
  → CoreLoadingTheme.variantStyles[variant]
  → loadingStyle                          // 인스턴스
```

합친 결과에 없는 값은 아래 순서로 채웁니다. 앞에 있는 것이 이깁니다.

| 값 | 정해지는 순서 |
| --- | --- |
| 상자 한 변 | 적은 `size` → `componentSize` 단계 → 16 |
| 지시자 색 | 적은 `color` → `tone` 의 색 |
| 트랙 색 | 적은 `trackColor` → 적은 `trackAlpha` 만큼 옅게 한 지시자 색 → `tone` 의 트랙 |
| 선 두께 | 적은 `strokeWidth` → `componentSize` 단계 → 2 |
| 점 지름 | 적은 `dotSize` → `componentSize` 단계 → 적은 `size` 의 1/4 → 4 |
| 막대 두께 | 적은 `barHeight` → `componentSize` 단계 → 적은 `size` 의 1/8 → 2 |
| 모서리 | 적은 `cornerRadius` → 9999 (완전히 둥글게) |
| 주기 | 적은 `duration` → 모양의 기본 주기 |

<Note>

테마에 적은 값은 호출하는 곳의 `componentSize` 와 `tone` 보다 앞섭니다. 테마에 `size` 를 적으면 모든 `componentSize` 의 상자 크기가 그 값이 되고, `color` 를 적으면 `inverse` 를 포함한 모든 톤의 지시자 색이 그 색이 됩니다.

</Note>

### 사용 예

<Split>

<Code language="dart" title="하나만 바꾸기">
Loading(
  componentSize: CoreComponentSize.xl,
  loadingStyle: CoreLoadingStyle(
    color: CoreColor.token(CoreColors.tertiary),
    trackColor: CoreColor.token(CoreColors.surfaceContainerHighest),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    loading: CoreLoadingTheme(
      variantStyles: {
        CoreLoadingVariant.spinner: CoreLoadingStyle(
          duration: Duration(milliseconds: CoreDuration.ms2000),
        ),
        CoreLoadingVariant.bar: CoreLoadingStyle(
          cornerRadius: CoreRadius.radius0,
        ),
      },
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다. 선을 굵게 하는 서페이스 스타일(neo-brutalism)을 켜면 두 플랫폼 모두 `spinner` 의 기본 선이 4 이상이 됩니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

이미 만든 `Loading` 위에 `withStyle` 로 스타일을 덧붙일 수 있습니다. 생성자의 `loadingStyle` 과 같게 동작하고, 겹치는 필드는 뒤에 붙인 값이 이깁니다.

<Preview component="loading" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class LoadingChainExample extends StatelessWidget {
  const LoadingChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Loading().withStyle(
      const CoreLoadingStyle(
        color: CoreColor.token(CoreColors.tertiary),
        trackColor: CoreColor.token(CoreColors.surfaceContainerHighest),
        size: CoreSize.size48,
        strokeWidth: CoreStrokeWidth.stroke4,
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class LoadingChainExample extends StatelessComponent {
  const LoadingChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Loading().withStyle(
      const CoreLoadingStyle(
        color: CoreColor.token(CoreColors.tertiary),
        trackColor: CoreColor.token(CoreColors.surfaceContainerHighest),
        size: CoreSize.size48,
        strokeWidth: CoreStrokeWidth.stroke4,
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

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Jaspr Web | 루트 `<span>` 에 `role="status"` 와 `aria-label` 을 붙입니다. `aria-live="polite"` 는 이 역할에 이미 담긴 값이라 속성으로 따로 붙이지 않습니다. `spinner` 의 SVG 두 개에는 `aria-hidden="true"` 가 붙습니다. |
| Flutter | `Semantics(liveRegion: true, label: ...)` 로 감쌉니다. 키트는 Flutter에서 status 역할을 라이브 영역으로 전하며, 의미 역할 값(`SemanticsRole`)은 따로 지정하지 않습니다. |

`Loading` 이 붙이는 역할과 이름 값은 호출하는 쪽에서 덮어쓸 수 없습니다. 웹은 `attributes` 에 `role` · `aria-label` 을 넣어도 `Loading` 의 값이 이기고, Flutter에는 라벨 파라미터가 없습니다.

### 키보드

없음. `Loading` 은 처리하는 키가 없고 Tab 순서에 들어가지 않습니다.

### 스크린 리더

- 이름은 로케일의 `loadingLabel` 입니다(Flutter `CoUILocalizations`, 웹 `CouiLocalizations`). 영어는 `Loading`, 한국어는 `로딩 중` 입니다. 그릴 때마다 지금 로케일에서 읽습니다.
- 앱 루트의 `supportedLocales` 기본값은 두 플랫폼 모두 `en-US` 하나라, 그대로 두면 영어로 알립니다. Flutter(`CoUIApp`)는 `supportedLocales` 에 그 언어를 넣어야 합니다. 웹(`CoUIWeb`)은 `locale` 을 직접 정하거나, `supportedLocales` 에 그 언어를 넣어 브라우저 언어와 맞춰지게 합니다. `locale` 을 정하지 않았으면, 맞는 언어가 없을 때와 서버에서 그릴 때 목록의 첫 언어를 씁니다.
- 라이브 영역 안에 글이 없습니다. 이름은 웹의 `aria-label`, Flutter의 `Semantics` 라벨에만 있습니다.
- 진행률은 알리지 않습니다. 값을 읽어 주어야 하면 [Progress](/components/progress)를 쓰세요.

#### 문구를 직접 정하기

"주문 목록을 불러오는 중" 처럼 무엇을 기다리는지 말하려면 [LoadingRegion](/components/loading-region)으로 감쌉니다. 영역이 `semanticLabel` 을 알리고, 안의 `Loading` 은 보조 기술에서 숨겨집니다. 영역 안의 내용은 모두 함께 숨겨지므로, 로딩 중에도 써야 하는 컨트롤은 밖에 둡니다.

```dart
LoadingRegion(
  semanticLabel: '주문 목록을 불러오는 중',
  child: Loading(),
)
```

#### 장식으로만 쓰기

곁의 글이 이미 같은 말을 하면 `Loading` 을 보조 기술에서 숨길 수 있습니다. 숨기면 `Loading` 의 알림도 없어지므로, 알려야 하는 글은 따로 알려지게 해야 합니다.

<Split>

<Code language="dart" title="Flutter">
ExcludeSemantics(child: Loading())
</Code>

<Code language="dart" title="Jaspr Web">
Loading(attributes: {'aria-hidden': 'true'})
</Code>

</Split>

### 포커스 관리

진입 · 이탈 · 가두기 모두 없음. 오버레이가 아니고 포커스를 옮기지 않습니다. 로딩이 끝나 `Loading` 이 사라질 때도 포커스를 옮기지 않으므로, 새로 나타난 내용으로 보내야 하면 부모가 합니다.

### 알려진 제약

- **인스턴스마다 이름을 바꾸는 파라미터가 없습니다.** 영역 단위의 문구는 `LoadingRegion` 으로 정합니다. 로케일 클래스의 `loadingLabel` 을 바꾸면 앱 전체에 적용되고, `Skeleton` 처럼 같은 문구를 읽는 컴포넌트도 함께 바뀝니다.
- **새로 나타난 표시가 읽힌다고 보장할 수 없습니다.** 라이브 영역은 흔히 안의 내용이 바뀔 때 알려지는데, `Loading` 의 영역에는 글이 없고 화면에 넣는 순간 영역이 생깁니다. 읽히는지는 화면 읽기 프로그램에 따라 다를 수 있습니다.
- **둘레의 이름에 섞일 수 있습니다.** 버튼 안에 두면 버튼의 이름에 로딩 문구가 함께 들어갈 수 있습니다. Flutter의 `Loading` 은 자기만의 의미 경계(`container`)를 만들지 않습니다. 버튼 글이 이미 상태를 말하면 위의 "장식으로만 쓰기" 방법으로 숨기세요.
- **동작 줄이기를 켜도 기본 주기에서는 멈추지 않습니다.** 멈춤 전용 속성은 없습니다. `duration` 에 `Duration.zero` 를 적으면 설정과 상관없이 멈춘 모습이 됩니다.
- **`duration` 을 500ms 이하로 줄이면 동작 줄이기에서 멈춥니다.** 계속 움직여야 하면 500ms보다 긴 값을 씁니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

생성자의 `variant` · `tone` · `componentSize` · `loadingStyle` 은 같고, 그리는 방식은 각 플랫폼을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 구조 | `Semantics` 라이브 영역 안에 `RepaintBoundary` 로 감싼 모양 하나를 둡니다 | `role="status"` 인 `<span>` 하나 안에 모양을 그리는 `<svg>` 나 `<span>` 을 둡니다 |
| `spinner` | `CustomPainter` 와 `AnimationController` | SVG 원 두 개와 CSS `@keyframes` 회전 |
| `dots` | `AnimationController` 로 프레임마다 불투명도를 계산 | CSS `@keyframes` 와 점마다 다른 `animation-delay` |
| `bar` | `AnimationController` 와 `Transform.translate` | CSS `@property` 와 `sin()` 으로 `translateX` 계산 |
| `pulse` | `AnimationController`, `Transform.scale`, `Opacity` | CSS `@keyframes` 의 `scale` · `opacity` |
| 색 | 테마의 색 구성에서 토큰 색을 읽어 칠합니다 | 토큰 색은 CSS 색 변수를 따르고, 직접 적은 색은 인라인 CSS가 됩니다 |
| 크기 배율 | 상자 · 점 · 막대 · 선 · 모서리에 테마의 크기 배율을 곱합니다 | 상자 · 점 · 막대는 `rem` 이라 브라우저의 글자 크기를 따르고, 선 두께는 `px` 입니다 |
| 부모가 너비 · 높이를 강제할 때 | `spinner` 가 그 크기로 커집니다 ([배치](#배치)) | 정한 크기를 지킵니다 |
| `dots` 의 점이 상자에 넘칠 때 | 레이아웃 넘침 오류 | 점이 가로로 눌립니다 |
| 오른쪽에서 왼쪽으로 쓰는 화면의 `bar` | 막대가 트랙 오른쪽 밖으로 나갑니다 | 트랙 안에서 오갑니다 |
| 동작 줄이기를 읽는 곳 | `MediaQuery.disableAnimations` (Android의 애니메이션 삭제) 또는 iOS의 동작 줄이기. `CoUIApp` 아래에서는 앱이 켜진 채 바꿔도 반영됩니다 | `prefers-reduced-motion` 미디어 쿼리 |
| 웹 전용 속성 | — | `id` · `classes` · `css` · `attributes` · 이벤트 속성 |

Flutter에서 글 방향이 오른쪽에서 왼쪽인 화면에 `bar` 를 둘 때는 아래처럼 왼쪽에서 오른쪽 방향으로 감싸면 트랙 안에서 움직입니다.

```dart
Directionality(
  textDirection: TextDirection.ltr,
  child: Loading(variant: CoreLoadingVariant.bar),
)
```

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 이름을 씁니다.

### 생성자

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `variant` | `CoreLoadingVariant` | `spinner` | 모양. `spinner` · `dots` · `bar` · `pulse` |
| `tone` | `CoreLoadingTone` | `primary` | 색. `primary` · `neutral` · `inverse` |
| `componentSize` | `CoreComponentSize?` | `null` | 크기 단계 `xs` · `sm` · `md` · `lg` · `xl` · `xl2`. 비우면 `xs` 와 같은 모양입니다 |
| `loadingStyle` | `CoreLoadingStyle?` | `null` | 이 인스턴스의 색 · 크기 · 두께 · 모서리 · 주기. 필드는 아래 표를 보세요 |

### 웹 전용 파라미터

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트 `<span>` 의 id. 비우면 인스턴스마다 만들어 붙입니다 |
| `classes` | `String?` | `null` | 루트의 클래스 뒤에 덧붙입니다 |
| `css` | `Styles?` | `null` | 루트의 인라인 스타일. 겹치는 속성은 이 값이 이깁니다 |
| `attributes` | `Map<String, String>?` | `null` | 루트의 HTML 속성. `role` · `aria-label` 은 `Loading` 의 값이 이깁니다 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | DOM 이벤트 이름마다의 처리기 |
| `onClick` · `onMouseEnter` · `onMouseLeave` | `UiMouseEventHandler?` | `null` | 루트의 마우스 이벤트 |
| `onKeyDown` · `onKeyUp` | `UiKeyboardEventHandler?` | `null` | 루트의 키 이벤트. 루트는 포커스를 받지 않습니다 |
| `onInput` · `onChange` | `UiInputEventHandler?` | `null` | 생성자는 받지만, 넘긴 함수가 불리지 않습니다. |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreLoadingStyle patch)` | `loadingStyle` 에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다 |
| `copyWith({variant, tone, componentSize, loadingStyle, key})` | 바꾼 값으로 사본을 만듭니다. 웹은 웹 전용 파라미터도 받습니다 |

### 테마 — `CoreLoadingTheme`

`CoreComponentTheme.loading` 에 둡니다.

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CoreLoadingStyle?` | `null` | 모든 `Loading` 에 적용합니다 |
| `variantStyles` | `Map<CoreLoadingVariant, CoreLoadingStyle>?` | `null` | 모양마다 `style` 위에 덮습니다 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreLoadingStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `color` | `CoreColor?` | Indicator colour override (fill of `dots` / `pulse` / `bar` fill, arc of `spinner`). |
| `trackColor` | `CoreColor?` | Explicit track colour override for `spinner` track ring and `bar` background. `null` (default) → renderer fades [color] by [trackAlpha] (falling back to [defaultTrackAlpha]) so the track inherits the indicator hue with a low-opacity tint. |
| `trackAlpha` | `double?` | Track fade alpha override (`0.0`–`1.0`). Applied to [color] to derive the implicit track tint when [trackColor] is null. `null` falls back to [defaultTrackAlpha]. |
| `size` | `double?` | Explicit pixel size override (logical px). |
| `strokeWidth` | `double?` | Spinner ring stroke width override (logical px). Only the `spinner` variant draws a ring; other variants ignore this. |
| `dotSize` | `double?` | `dots` diameter override (logical px). `null` takes the size step's dot ([defaultsBySize]), else [defaultDotSize] / [defaultDotSizeRatio]. |
| `barHeight` | `double?` | `bar` track thickness override (logical px). `null` takes the size step's track ([defaultsBySize]), else [defaultBarHeight] / [defaultBarHeightRatio]. |
| `cornerRadius` | `double?` | Indicator corner radius override (logical px). `null` falls back to [defaultCornerRadius] (`CoreRadius.radius9999` → fully round). |
| `duration` | `Duration?` | Per-instance animation cycle duration override. `null` falls back to [defaultsByVariant] for the active variant. |

### `CoreLoadingStyle` 변형별 기본값 (`CoreLoadingVariantStyle`)

| 필드 | `spinner` | `dots` | `bar` | `pulse` |
|------|------|------|------|------|
| `duration` | Duration(milliseconds: CoreDuration.ms1000) | Duration(milliseconds: CoreDuration.ms1000) | Duration(milliseconds: CoreDuration.indeterminate) | Duration(milliseconds: CoreDuration.ms1000) |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 `trackColor` · `trackAlpha` 설명은 지금 동작과 다릅니다. 두 값을 비우면 `primary` · `neutral` 톤은 트랙을 `surfaceContainerHigh` 로 칠하고, `inverse` 톤만 지시자 색을 25%로 옅게 합니다. 세 톤 모두 자기 트랙 색이나 옅기를 가져 `defaultTrackAlpha`(0.2)가 쓰이는 톤은 없습니다. `trackAlpha` 를 적으면 어느 톤에서든 지시자 색을 그만큼 옅게 한 색이 트랙이 됩니다(`trackColor` 를 적지 않았을 때). `cornerRadius` 는 `spinner` 에 듣지 않습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="loading/related-loading-region" title="LoadingRegion">

한 영역의 로딩을 원하는 문구로 한 번만 알립니다.

</Card>
<Card demo="loading/related-skeleton" title="Skeleton">

콘텐츠 모양을 예측할 수 있을 때 자리를 미리 잡습니다.

</Card>
<Card demo="loading/related-progress" title="Progress">

진행률을 알 때 얼마나 끝났는지 보입니다.

</Card>
<Card demo="loading/related-empty-state" title="EmptyState">

불러오기가 끝난 뒤 보여 줄 데이터가 없을 때 안내합니다.

</Card>
</Cards>
