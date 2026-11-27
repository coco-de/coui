---
title: AspectRatioBox
description: 콘텐츠를 가로세로 비율이 정해진 상자에 담습니다. 부모가 폭을 정하면 높이는 비율에서 나옵니다.
category: display
platforms: [flutter, web]
related: [card, responsive-container]
tags: [aspect-ratio, layout, ratio]
template: v2
source: display/aspect_ratio_box
---

# AspectRatioBox

<a id="live-preview"></a>
<a id="사용법"></a>

## 플레이그라운드

비율과 부모의 폭을 바꿔 보며 상자를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="aspect-ratio-box" />

`AspectRatioBox`는 `ratio`(너비 ÷ 높이)에 맞춘 상자를 만들고 `child`를 그 상자에 채웁니다. 상자 자체에는 배경 · 테두리 · 여백이 없습니다. 미리보기에 보이는 색은 `child`로 넣은 [Card](/components/card)의 것입니다. '부모 폭'은 상자의 속성이 아니라 상자를 감싼 부모의 폭입니다.

## 비율

`ratio`는 너비를 높이로 나눈 값입니다. 1보다 크면 가로로 긴 상자, 1이면 정사각형, 1보다 작으면 세로로 긴 상자입니다. `16 / 9`처럼 나눗셈 그대로 적으면 어떤 비율인지 바로 읽힙니다.

<Preview demo="aspect-ratio-box/ratios" />

위 상자들은 폭이 같고 비율만 다릅니다. 그래서 높이가 달라집니다.

### 쓸 수 없는 값

`ratio`는 0보다 큰 유한한 수여야 합니다. 0, 음수, `double.nan`, 무한대를 넘기면 대신 다음 값을 씁니다. 앞의 값이 없을 때 뒤의 값으로 넘어갑니다.

1. 테마의 `CoreComponentTheme.aspectRatioBox.style.defaultRatio`
2. `CoreAspectRatioBoxStyle.defaultDefaultRatio`(`1.0`, 정사각형)

<Preview demo="aspect-ratio-box/fallback" />

이 문서의 테마에는 `defaultRatio`가 없어, 위의 네 상자는 모두 정사각형입니다.

<Note>

테마의 `defaultRatio`는 검사하지 않고 그대로 씁니다. 상자의 `ratio`와 테마의 값이 모두 쓸 수 없는 값이면, Flutter는 개발 모드에서 단언(assert) 오류가 나고 Web은 상자의 높이가 0이 됩니다. 테마에는 0보다 큰 유한한 수만 넣으세요.

</Note>

<a id="동작-스펙-behavior"></a>

## 상자의 크기

상자에는 크기 단계(`size`)가 없습니다. 크기는 부모와 `ratio`가 함께 정합니다. 보통은 부모가 폭을 정하고, 높이는 폭 ÷ `ratio`가 됩니다.

<Preview demo="aspect-ratio-box/widths" />

위의 세 상자는 모두 `16 / 9`입니다. 폭이 96 · 160 · 240이면 높이는 54 · 90 · 135입니다.

부모의 조건에 따른 결과는 두 플랫폼이 다음과 같습니다.

| 부모의 조건 | Flutter | Jaspr Web |
| --- | --- | --- |
| 폭에 한도가 있고 높이는 자유 (`Column`, 세로 스크롤) | 허락되는 가장 넓은 폭을 쓰고, 높이는 폭 ÷ `ratio` | 부모의 폭을 쓰고, 높이는 폭 ÷ `ratio` |
| 계산한 높이가 부모의 최대 높이보다 큼 | 높이를 최대 높이에 맞추고 폭을 줄입니다. 부모가 폭을 고정했으면 폭을 지키고 비율을 포기합니다. | 부모의 높이는 계산에 넣지 않아, 상자가 부모보다 높아질 수 있습니다. |
| 폭과 높이가 모두 고정 | `ratio`를 쓰지 않고 부모가 정한 크기가 됩니다. | 높이는 폭 ÷ `ratio`입니다. 부모가 상자를 세로로 늘이는 경우는 [배치](#배치)를 보세요. |
| 폭은 한도가 없고 높이에만 한도 (`Row`, 가로 스크롤) | 폭 = 높이 × `ratio` | 높이에서 폭을 계산하지 않습니다. 폭은 부모의 CSS 배치에서 나옵니다. |
| 폭과 높이 모두 한도가 없음 | 개발 모드에서 레이아웃 오류가 납니다. | — |

`child`는 상자의 크기를 받습니다. Flutter는 상자 크기로 고정한 제약을 넘기고, Web은 직계 자식 요소에 `width: 100%` · `height: 100%`를 줍니다. 폭이 정해진 상자는 내용이 많아도 길어지지 않고, 넘치는 내용을 자르지도 않습니다.

<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

이미지 · 동영상 · 지도처럼 폭이 바뀌어도 모양을 지켜야 하는 자리에 씁니다. 이미지 자르기, 로딩, 재생, 누르기는 `child`가 맡습니다. 상자에는 비활성 상태가 없고, `onPressed` 같은 누름 파라미터도 없습니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 폭과 높이를 모두 직접 정할 때 | Flutter의 `SizedBox`, Web은 `width` · `height` 스타일 |
| 제목 · 본문 같은 내용을 한 면에 묶을 때 | [Card](/components/card). 비율 상자를 Card의 `media`에 넣어 함께 쓸 수도 있습니다. |
| 본문 폭의 상한을 두고 가운데에 놓을 때 | [ResponsiveContainer](/components/responsive-container) |
| 긴 글처럼 내용에 따라 높이가 늘어야 할 때 | 비율 상자 없이 부모에 바로 놓습니다. |

<a id="do"></a>
<a id="dont"></a>

### 비율은 확인한 값으로

쓸 수 없는 값은 정사각형(또는 테마의 비율)으로 바뀝니다. 계산한 값을 그대로 넘기면 계산이 잘못돼도 상자 모양만 달라지므로, 두 값이 0보다 큰지 먼저 확인하세요.

<Split>

<Code language="dart" title="이렇게 하세요">
AspectRatioBox(
  ratio: 16 / 9,
  child: media,
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// height가 0이면 무한대나 NaN, width가 0이면 0이나 NaN이 됩니다.
// 모두 쓸 수 없는 값이라, 의도하지 않은 비율로 그려집니다.
AspectRatioBox(
  ratio: width / height,
  child: media,
)
</Code>

</Split>

### 이미지의 맞춤 방식

상자는 `child`의 크기만 정합니다. 이미지가 그 크기를 어떻게 채울지는 이미지에 정합니다. 상자를 빈틈없이 채우려면 다음처럼 적습니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
AspectRatioBox(
  ratio: 16 / 9,
  child: Image.network(
    coverUrl,
    fit: BoxFit.cover,
    semanticLabel: '책 표지',
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
AspectRatioBox(
  ratio: 16 / 9,
  child: img(src: coverUrl, alt: '책 표지', classes: 'object-cover'),
)
```

  </TabItem>
</Tabs>

맞춤 방식을 적지 않으면 두 플랫폼이 다르게 그립니다.

| 이미지 | 적지 않았을 때 |
| --- | --- |
| Flutter `Image` | `BoxFit.scaleDown`입니다. 이미지의 비율을 지키며 가운데에 놓고, 상자보다 크면 줄이고 작으면 키우지 않습니다. |
| Web `img` | CSS 기본값 `object-fit: fill`입니다. 상자 크기에 맞춰 늘어나므로, 비율이 다른 이미지는 찌그러집니다. |

## 배치

폭을 정해 주는 부모 안에 두는 것이 기본입니다. 아래의 경우에는 결과가 달라지므로 확인하세요.

### 나란히 놓기

한 줄에 상자를 여러 개 놓을 때는 상자마다 폭을 나눠 줍니다.

<Preview demo="aspect-ratio-box/split" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Row(
  children: [
    Expanded(child: AspectRatioBox(ratio: 4 / 3, child: first)),
    const Gap.space8(),
    Expanded(child: AspectRatioBox(ratio: 4 / 3, child: second)),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(classes: 'flex items-start', [
  div(classes: 'flex-1', [AspectRatioBox(ratio: 4 / 3, child: first)]),
  const Gap.space8(),
  div(classes: 'flex-1', [AspectRatioBox(ratio: 4 / 3, child: second)]),
])
```

  </TabItem>
</Tabs>

### Flutter의 Row와 GridView

`Row`는 `Expanded` · `Flexible`이 아닌 자식에게 폭의 한도를 주지 않습니다. 이때 높이에 한도가 있으면 폭은 높이 × `ratio`가 됩니다. `Column` 안의 `Row`처럼 높이에도 한도가 없으면 레이아웃 오류가 납니다. 위의 예처럼 `Expanded`로 감싸거나, `SizedBox`로 폭이나 높이를 정하세요.

`GridView`는 칸의 폭과 높이를 모두 정해 주므로 칸에 바로 넣은 상자의 `ratio`가 쓰이지 않습니다. 칸의 비율은 `gridDelegate`의 `childAspectRatio` 같은 값으로 정합니다.

### Web의 flex 행과 grid

CSS의 flex 행과 grid는 기본으로 자식을 세로로 늘입니다(`align-items: stretch`). 상자가 이렇게 늘어나면 높이가 비율이 아니라 그 줄의 높이를 따릅니다. 부모에 `items-start`를 두거나, 위의 예처럼 상자를 `div`로 한 번 감쌉니다.

### 내용만큼만 넓어지는 부모

Web에서는 `child`가 상자의 크기 계산에 들어가지 않습니다. 그래서 `w-fit` 부모나, `items-center` · `items-start`를 둔 세로 flex 안의 폭 없는 `div`처럼 내용만큼만 넓어지는 부모에서는 상자의 폭이 0이 될 수 있습니다. 옆에 글이 있으면 상자가 그 글의 폭을 따라갑니다. 이런 부모에는 폭을 정해 주세요.

`Card`의 기본 폭(`CoreCardSizing.intrinsic`)은 내용을 따릅니다. Flutter에서는 부모가 폭을 고정하면 그 폭이 되지만, Web은 그때도 내용만큼입니다. 비율 상자를 `media`에 넣으면 Web에서는 상자가 폭을 보태지 않아, 카드의 폭은 글 같은 나머지 내용에서 나옵니다. Flutter에서는 상자의 `child`가 알려 주는 내용 폭도 함께 셉니다. 카드가 부모 폭을 채우게 하려면 다음처럼 적습니다. 코드는 두 플랫폼이 같습니다.

```dart
Card(
  variant: CoreCardVariant.outlined,
  cardStyle: const CoreCardStyle(sizing: CoreCardSizing.expand),
  media: AspectRatioBox(ratio: 16 / 9, child: cover),
  body: Text('책 제목'),
)
```

Flutter에서는 `IntrinsicWidth`처럼 자식의 내용 크기를 묻는 부모에게도 상자가 값을 알려 줍니다. 한쪽 길이를 알면 다른 쪽을 `ratio`로 계산하고, 모르면 `child`의 내용 크기를 돌려줍니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

상자에는 겉모습이 없어서, 생성자에 `CoreAspectRatioBoxStyle`을 받는 파라미터가 없습니다. 상자마다 정하는 값은 `ratio`입니다. 배경 · 테두리 · 모서리 · 여백은 `child`에 정합니다. Card라면 `cardStyle`을 씁니다.

테마가 바꿀 수 있는 값은 `defaultRatio` 하나입니다. 이 값은 **쓸 수 없는 `ratio`가 들어왔을 때 대신 쓰는 비율**이며, 앱에 있는 모든 상자의 비율을 바꾸지 않습니다. `ratio`는 필수 파라미터이고, 0보다 큰 유한한 값을 넘긴 상자는 테마에 값이 있어도 넘긴 비율 그대로입니다.

<Split>

<Code language="dart" title="상자 하나의 비율">
AspectRatioBox(
  ratio: 4 / 3,
  child: media,
)
</Code>

<Code language="dart" title="앱 전체의 대신 쓸 비율">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: const CoreComponentTheme(
    aspectRatioBox: CoreAspectRatioBoxTheme(
      style: CoreAspectRatioBoxStyle(defaultRatio: 16 / 9),
    ),
  ),
)
</Code>

</Split>

이렇게 만든 `ThemeData`는 Flutter에서는 `CoUIApp`의 `theme`에, Web에서는 `CoUIWeb`의 `theme`에 넘깁니다.

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
CoreAspectRatioBoxStyle.defaultDefaultRatio             // 디자인 시스템 기본값 1.0
  → CoreComponentTheme.aspectRatioBox.style.defaultRatio  // 앱 전체, 검사하지 않음
  → ratio                                                 // 상자 하나, 0보다 큰 유한한 수일 때
```

<a id="접근성-accessibility"></a>

## 접근성

### 역할

없음. 상자는 배치만 맡고 역할을 더하지 않습니다. Flutter는 `AspectRatio` 위젯을 돌려줄 뿐 `Semantics`를 붙이지 않습니다. Web은 `div` 셋(바깥, 높이를 만드는 빈 칸, 내용 칸)을 그리고, 스스로 `role`이나 `aria-*`를 붙이지 않습니다.

### 키보드

없음. 상자에는 누를 수 있는 것이 없고, 두 플랫폼 모두 상자가 스스로 처리하는 키가 없습니다.

### 스크린 리더

상자가 더하는 이름 · 설명 · 알림은 없습니다. 전달할 내용은 `child`에 담습니다. Web의 빈 칸 `div`에는 글자도 이름도 없습니다.

이미지에 뜻이 있으면 위의 이미지 예처럼 이미지에 대체 텍스트를 줍니다(Flutter `semanticLabel`, Web `alt`). 직접 그린 그림처럼 상자 전체에 이름이 필요하면 직접 붙입니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Semantics(
  label: '매장 위치 지도',
  image: true,
  child: AspectRatioBox(ratio: 4 / 3, child: mapDrawing),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
AspectRatioBox(
  ratio: 4 / 3,
  attributes: const {'role': 'img', 'aria-label': '매장 위치 지도'},
  child: mapDrawing,
)
```

  </TabItem>
</Tabs>

### 포커스 관리

없음. 상자는 포커스를 받지 않고 포커스 링도 그리지 않습니다. Flutter에는 `Focus`가 없고, Web은 스스로 `tabindex`를 붙이지 않습니다. 포커스를 옮기거나 가두거나 되돌리는 동작도 없습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 상자의 높이는 내용에 따라 늘지 않습니다. 글자를 크게 키우면 `child`의 글이 상자에 다 들어가지 않아, 잘리거나 상자 밖으로 넘칠 수 있습니다. 꼭 읽어야 하는 긴 글은 상자 밖에 두세요. |
| Flutter | 생성자에 이름을 받는 파라미터가 없습니다. 상자에 이름을 붙이려면 `Semantics`로 감쌉니다. |

모든 컴포넌트에 공통으로 적용되는 축은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`ratio`와 `child`는 두 플랫폼이 같습니다. 크기를 만드는 방식은 각 플랫폼을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 그리는 방식 | `AspectRatio` 위젯 | `div` 셋. 바깥(`relative w-full`) 안에, `padding-top`(100 ÷ `ratio` %)으로 높이를 만드는 빈 칸과 상자를 덮는 내용 칸(`absolute inset-0`)을 둡니다. |
| 크기의 기준 | 부모가 주는 폭 · 높이의 한도 | 폭. 높이를 계산할 때 부모의 높이는 보지 않습니다. |
| 높이에 맞추기 | 폭의 한도가 없거나 높이가 모자라면, 부모가 허락하는 범위에서 높이로 폭을 계산합니다. | 높이에서 폭을 계산하지 않습니다. 원하는 높이가 있으면 부모의 폭을 높이 × `ratio`로 정합니다. |
| `child` 채우기 | 상자 크기로 고정한 제약을 넘깁니다. `child`가 다른 크기를 정해도 상자의 크기가 됩니다. | 내용 칸의 `coui-aspect-fill` 클래스가 직계 자식 요소에 `width: 100%` · `height: 100%`를 줍니다. 자식이 인라인 스타일로 정한 폭 · 높이(예: `CoreCardSizing.fixed`에 크기를 준 Card)는 이 값보다 우선합니다. `span` 같은 인라인 요소에는 CSS 규칙상 이 크기가 적용되지 않습니다. |
| 채우는 규칙이 있는 곳 | 위젯 안 | `CoUIWeb`이 함께 넣는 스타일입니다. `Theme`만으로 감싼 화면에는 이 규칙이 없어 `child`가 상자 크기로 늘어나지 않을 수 있습니다. |
| 맞춤을 적지 않은 이미지 | 비율을 지킵니다(`BoxFit.scaleDown`). | 상자 크기에 맞춰 늘어납니다(`object-fit: fill`). |
| `ratio`와 테마 값이 모두 쓸 수 없는 값 | 개발 모드에서 단언 오류 | 상자의 높이가 0 |
| 웹 전용 파라미터 | — | `id` · `classes` · `css` · `attributes` · `eventHandlers`. 바깥 `div`에 붙습니다. |
| 사본 만들기 | 없음 | `copyWith` |

<a id="props"></a>
<a id="props-parameters"></a>

## API

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `ratio` | `double` | 필수 | 너비 ÷ 높이. 0보다 큰 유한한 수여야 합니다. 그 밖의 값이면 테마의 `defaultRatio`를, 테마에도 없으면 `1.0`을 씁니다. |
| `child` | Flutter `Widget`, Web `Component` | 필수 | 상자에 채우는 콘텐츠 |

두 플랫폼 모두 `key`를 받습니다. Web은 바깥 `div`에 붙는 `id` · `classes` · `css` · `attributes` · `eventHandlers`도 받습니다. `classes`는 컴포넌트의 클래스에 덧붙고, `css`는 인라인 스타일입니다. 그래서 `css`로 정한 `width`는 상자의 기본 폭(`w-full`)보다 우선합니다. `css`로 높이를 정하면 비율이 깨집니다.

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `copyWith({ratio, child, ...})` | Web 전용. 넘긴 값만 바꾼 사본을 만듭니다. `id` · `classes` · `css` · `attributes` · `eventHandlers` · `key`도 바꿀 수 있습니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.aspectRatioBox` | `CoreAspectRatioBoxTheme?` | 이 컴포넌트의 테마 자리 |
| `CoreAspectRatioBoxTheme.style` | `CoreAspectRatioBoxStyle?` | 대신 쓸 비율을 담습니다. |
| `CoreAspectRatioBoxStyle.defaultDefaultRatio` | `double` | `1.0`. 상자와 테마에 쓸 값이 없을 때의 상수 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreAspectRatioBoxStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `defaultRatio` | `double?` | Project-level fallback ratio (`width / height`) when the widget caller supplies a value that is not strictly positive. `null` defers to [defaultDefaultRatio] (square). |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 설명은 0보다 크지 않은 값을 말하지만, 지금 코드는 무한대를 넘겨도 `defaultRatio`를 씁니다. `NaN`도 마찬가지입니다.

</Note>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="aspect-ratio-box/related-card" title="Card">

비율 상자를 `media`에 넣어 표지와 설명을 한 장에 묶습니다.

</Card>
<Card demo="aspect-ratio-box/related-responsive-container" title="ResponsiveContainer">

본문 폭의 상한을 정합니다. 안에 둔 비율 상자의 높이는 그 폭에서 나옵니다.

</Card>
</Cards>
