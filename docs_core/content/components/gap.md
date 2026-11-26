---
title: Gap
description: Row · Column 안의 두 요소 사이에 간격 토큰만큼 빈 자리를 둡니다. 부모의 방향을 따라 가로나 세로로 자리를 차지합니다.
category: layout
platforms: [flutter, web]
related: [join, divider]
tags: [gap, spacing, layout, utility]
template: v2
source: layout/gap
---

# Gap

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

간격과 부모의 방향을 바꿔 보며 Gap을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="gap" />

`size`는 `CoreSpace` 단계의 숫자입니다. 16을 고르면 `Gap.space16()`입니다. 부모 방향을 바꾸면 같은 Gap이 세로 간격이 됩니다. Gap에는 방향을 정하는 속성이 없습니다.

간격 컴포넌트는 셋이고, 이 페이지가 함께 다룹니다.

| 컴포넌트 | 쓰는 곳 |
| --- | --- |
| `Gap` | `Row` · `Column` 안에서 정해진 간격을 둘 때 |
| `MaxGap` | 정해진 간격까지만 차지하고, 공간이 모자라면 줄어들어야 할 때 |
| `SliverGap` | `CustomScrollView`의 sliver 사이에 간격을 둘 때 |

## 크기

간격은 `CoreSpace` 단계 하나로 고릅니다. 단계마다 `const` 생성자가 있어 `Gap.space0()`부터 `Gap.space256()`까지 쓸 수 있습니다.

<Preview demo="gap/sizes" />

| 항목 | 동작 |
| --- | --- |
| 기본값 | 간격을 정하지 않은 `Gap()`은 테마의 값을, 테마에도 없으면 `CoreGapStyle.defaultSize`(4)를 씁니다. |
| 이름 있는 생성자 | `Gap.space16()`은 `Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16))`와 같습니다. `MaxGap` · `SliverGap`도 같은 이름을 가집니다. |
| 밀도 | 앱의 밀도(`CoUIApp(density:)` · `CoUIWeb(density:)`)가 `compact`나 `spacious`면 간격이 4px 격자에서 한 칸씩 움직입니다. 4 이하는 움직이지 않고, `crossAxisExtent`도 움직이지 않습니다. |

<a id="동작-스펙-behavior"></a>

## 방향 자동 감지

Gap에는 방향을 정하는 속성이 없습니다. 바로 위 부모가 가로로 늘어서면 가로 간격, 세로로 쌓이면 세로 간격이 됩니다. 교차축으로는 기본적으로 부모를 넓히지 않습니다.

<Preview demo="gap/direction" />

| 플랫폼 | 방향을 읽는 곳 |
| --- | --- |
| Flutter | 바로 위 `Row` · `Column` · `Flex`의 방향. 부모가 `Flex`가 아니면 Gap을 감싼 스크롤 영역의 방향을 쓰고, 그것도 없으면 오류가 납니다. |
| Jaspr Web | 부모의 `flex-direction`. 길이를 `flex-basis`로 정하므로 부모가 flex일 때만 자리를 차지합니다. |

<Note>

Flutter에서는 Gap을 `Flex`의 직계 자식으로 둡니다. `Padding`으로 감싸거나 `Wrap` 안에 두면 부모의 방향을 읽지 못해, 스크롤 방향을 쓰거나 오류가 납니다.

</Note>

<a id="maxgap-사용법"></a>

## MaxGap

`MaxGap`은 정해진 간격까지만 차지하고, 부모의 남은 공간이 그보다 작으면 남은 만큼으로 줄어듭니다. 폭이 좁아지면 간격도 좁아져도 되는 자리에 씁니다.

<Preview demo="gap/max-gap" />

```dart
Row(
  children: [
    Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text('A')),
    const MaxGap.space64(),
    Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text('B')),
  ],
)
```

| 플랫폼 | 줄어드는 방식 |
| --- | --- |
| Flutter | `Flexible`로 감싸 남은 공간까지만 받습니다. 그래서 `Row` · `Column` · `Flex`의 직계 자식이어야 합니다. |
| Jaspr Web | `flex-shrink: 1`로 줄고, `max-width` · `max-height`로 정해진 간격을 넘지 않습니다. 두 축에 함께 걸리므로 교차축 길이도 그 값을 넘지 않습니다. |

<a id="slivergap-사용법"></a>

## SliverGap

`SliverGap`은 `CustomScrollView`의 `slivers` 사이에 둡니다. sliver 목록 안에서 정해진 길이만큼 스크롤 공간을 차지합니다.

<Preview component="gap" example="sliver" />

```dart
CustomScrollView(
  slivers: [
    SliverToBoxAdapter(child: Text('위')),
    const SliverGap.space24(),
    SliverToBoxAdapter(child: Text('가운데')),
    const SliverGap(
      gapStyle: CoreGapStyle(
        size: CoreSpace.space24,
        color: CoreColor.token(CoreColors.error),
      ),
    ),
    SliverToBoxAdapter(child: Text('아래')),
  ],
)
```

<Note>

웹에는 sliver가 없어 `SliverGap`이 `Gap`과 같은 flex 간격으로 그려집니다. API는 같습니다. 교차축은 sliver 목록이 정하므로 `crossAxisExtent`를 읽지 않고, `SliverGap.expand`는 없습니다.

</Note>

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

`Row` · `Column` 안에서 자식 사이에 간격이 필요할 때 씁니다. 빈 `SizedBox` 대신 쓰면 간격이라는 뜻이 코드에 드러나고, 값도 토큰 단계에서 고르게 됩니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 요소 둘레에 사방 여백을 둘 때 | Flutter의 `Padding`, 웹은 여백 클래스(`p-*`) |
| `Row` · `Column`의 남은 공간을 모두 채울 때 | Flutter의 `Spacer`, 웹은 늘어나는 flex 자식(`flex-1`) |
| 빈 공간 대신 선으로 나눌 때 | [Divider](/components/divider) |
| 요소끼리 테두리를 맞대고 붙일 때 | [Join](/components/join) |

### 간격 값

간격은 토큰 단계로 고릅니다. `Gap.spaceN()`은 단계만 받으므로, 단계 밖 숫자는 `gapStyle`에 숫자를 직접 적어야 들어갑니다.

<Split>

<Code language="dart" title="이렇게 하세요">
Column(
  children: [
    TitleWidget(),
    const Gap.space16(),
    BodyWidget(),
    const Gap.space24(),
    ActionWidget(),
  ],
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 왜 13인지 알 수 없고, 화면마다 간격이 어긋납니다.
const Gap(gapStyle: CoreGapStyle(size: 13))
const Gap(gapStyle: CoreGapStyle(size: 27))
</Code>

</Split>

### 여백이 아니라 사이 간격

Gap은 자식과 자식 사이의 간격에만 씁니다. 컨테이너의 안쪽 여백은 Flutter의 `Padding`이나 웹의 여백 클래스(`p-*`)로 둡니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

Gap · MaxGap · SliverGap은 모두 `gapStyle` 하나로 겉모습을 정합니다. 필드는 간격(`size`), 교차축 길이(`crossAxisExtent`), 채우는 색(`color`) 셋이고, 세 컴포넌트가 같은 `CoreGapStyle`을 씁니다. `MaxGapStyle` · `SliverGapStyle`은 따로 없습니다.

<Split>

<Code language="dart" title="Gap 하나만 바꾸기">
const Gap(
  gapStyle: CoreGapStyle(
    size: CoreSpace.space24,
    crossAxisExtent: CoreSize.size16,
    color: CoreColor.token(CoreColors.error),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    gap: CoreGapTheme(
      style: CoreGapStyle(size: CoreSpace.space8),
    ),
    maxGap: CoreMaxGapTheme(
      style: CoreGapStyle(size: CoreSpace.space8),
    ),
  ),
)
</Code>

</Split>

<a id="테마-프로젝트-공통"></a>

### 값이 정해지는 순서

뒤로 갈수록 우선합니다. 세 컴포넌트는 각자 자기 테마 자리를 읽습니다. `Gap`은 `CoreComponentTheme.gap`, `MaxGap`은 `maxGap`, `SliverGap`은 `sliverGap`입니다.

```text
CoreGapStyle.defaultSize          // 디자인 시스템 기본값 (size만 있습니다)
  → CoreComponentTheme.gap.style  // 앱 전체
  → gapStyle                      // Gap 하나
```

### 교차축과 색

| 필드 | 비웠을 때 | 정했을 때 |
| --- | --- | --- |
| `crossAxisExtent` | Flutter는 교차축 길이가 0이고 부모가 늘일 때만 따라 늘어납니다. 웹은 부모의 교차축만큼 늘어납니다(`align-self: stretch`). | 교차축 길이를 그 값으로 정합니다. `Gap.expand`는 이 값을 `double.infinity`로 둡니다. |
| `color` | 투명합니다. | Gap의 사각형을 그 색으로 칠합니다. |

<Note>

색은 교차축 길이가 있어야 보입니다. Flutter는 `crossAxisExtent`를 비우면 부모가 교차축을 늘이지 않는 한(`CrossAxisAlignment.stretch`) 아무것도 칠하지 않고, 웹은 부모의 교차축만큼 칠합니다. 두 플랫폼에서 같게 보이려면 `crossAxisExtent`를 함께 정하되 `size`보다 크지 않게 둡니다. 웹 flex 부모는 기본으로 자식을 교차축만큼 늘이므로(`align-items: stretch`) `crossAxisExtent`를 정해도 띠가 부모의 교차축만큼 늘어납니다. Flutter `Row` · `Column`의 기본(가운데 정렬)과 맞추려면 웹 부모에 `items-center`를 둡니다. 이유는 플랫폼 차이를 보세요.

</Note>

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 Gap 위에 `withStyle`로 스타일을 덧붙일 수 있습니다. 생성자의 `gapStyle`과 같게 동작하고, 겹치는 필드는 뒤에 붙인 값이 이깁니다.

<Preview component="gap" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class GapChainExample extends StatelessWidget {
  const GapChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('A'),
        ),
        const Gap.space16().withStyle(
          const CoreGapStyle(
            size: CoreSpace.space64,
            crossAxisExtent: CoreSpace.space24,
            color: CoreColor.token(CoreColors.primary),
          ),
        ),
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('B'),
        ),
      ],
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class GapChainExample extends StatelessComponent {
  const GapChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('A'),
        ),
        const Gap.space16().withStyle(
          const CoreGapStyle(
            size: CoreSpace.space64,
            crossAxisExtent: CoreSpace.space24,
            color: CoreColor.token(CoreColors.primary),
          ),
        ),
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('B'),
        ),
      ],
      classes: 'inline-flex flex-row items-center',
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="접근성-accessibility"></a>

## 접근성

Gap은 보조 기술에 아무것도 알리지 않는 빈 공간입니다. 세 컴포넌트 모두, 두 플랫폼 모두 같습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 없습니다. `Gap` · `MaxGap` · `SliverGap`이 그리는 렌더 객체가 시맨틱 정보를 내지 않아 접근성 트리에 노드가 생기지 않습니다. |
| Jaspr Web | 없습니다. 자식 없는 `<div>` 하나이고 `role` · `aria-*`를 붙이지 않습니다. |

### 키보드

없음. 처리하는 키가 없습니다.

### 스크린 리더

읽을 것이 없습니다. 웹의 Gap은 내용도 역할도 없는 빈 요소이고, Flutter는 노드를 만들지 않습니다. 웹에는 `<div>`가 하나 더 생기고 Flutter에는 생기지 않지만, 이 차이는 안내에 나타나지 않습니다.

`gapStyle.color`로 칠해도 마찬가지입니다. 색은 Flutter에서는 사각형 채움, 웹에서는 `background-color`일 뿐 이름도 역할도 만들지 않습니다.

### 포커스 관리

없음. 포커스를 받지 않습니다. Flutter에는 `Focus`가 없고 웹에는 `tabindex`가 없어 Tab 순서에 들어가지 않습니다. 오버레이가 아니므로 포커스를 옮기거나 가두지도 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 색을 칠한 Gap은 구분선으로 읽히지 않습니다. 눈에는 경계선이지만 보조 기술에는 그 경계가 없습니다. 구분이 뜻을 가지면 `Divider(semantic: true)`를 쓰세요. Flutter는 라벨을 붙인 `Semantics`를, 웹은 `role="separator"`와 같은 라벨을 붙입니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 그리는 방식과 방향을 읽는 방식이 각 플랫폼을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 그리는 방식 | 자체 렌더 객체 `RenderGap` · `RenderSliverGap` | 자식 없는 `<div>`와 인라인 CSS(`flex-basis` · `flex-shrink`). 스스로 붙이는 클래스는 없습니다. |
| 방향 | 바로 위 `Flex`의 방향. 없으면 감싼 스크롤 영역의 방향 | 부모의 `flex-direction` |
| 부모가 flex가 아닐 때 | 스크롤 영역 안이면 그 방향을 쓰고, 아니면 오류가 납니다. | `flex-basis`가 듣지 않아 간격만큼 자리를 차지하지 않습니다. |
| `crossAxisExtent`를 비웠을 때 | 교차축 0. 부모가 늘이면 따라 늘어납니다. | 부모의 교차축만큼 늘어납니다(`align-self: stretch`). |
| `crossAxisExtent`를 정했을 때 | 교차축 길이만 정합니다. | 같은 값이 `min-width` · `min-height`로 함께 걸려, `size`보다 크면 간격도 그만큼 길어집니다. |
| `Gap.expand` · `MaxGap.expand` | 부모가 허락하는 교차축 최대 길이까지 늘어납니다. 그 길이가 무한한 자리(`Column` 안의 `Row` 등)에서는 레이아웃 오류가 납니다. | 무한대가 CSS 길이가 되지 못해 교차축을 채우지 않습니다. 부모가 늘일 때만 늘어납니다. |
| `SliverGap` | sliver 목록 안의 간격 | `Gap`과 같은 flex 간격. 교차축은 늘 부모만큼입니다. |
| 색 | 테마의 색 스킴에서 지금 밝기에 맞는 색으로 칠합니다. | 인라인 `background-color`. 색 변수라 밝기를 바꾸면 따라갑니다. |
| 단계 밖 값과 밀도 | 밀도에 따라 다음 칸으로 옮겨집니다. | 숫자 그대로 그립니다. 밀도가 닿지 않습니다. |
| 크기 배율 | 간격과 교차축 길이에 테마의 크기 배율을 곱합니다. | `rem`으로 그려 브라우저의 글자 크기를 따릅니다. |
| 웹 전용 속성 | — | `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 이름을 씁니다. 세 컴포넌트의 생성자는 `gapStyle` 하나만 받습니다. 자식 · 콜백 · 비활성 상태가 없고, `size` · `crossAxisExtent`는 논리 픽셀입니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `gapStyle` | `CoreGapStyle?` | `null` | 간격 · 교차축 길이 · 색. 비우면 테마의 값을, 그다음 `CoreGapStyle.defaultSize`(4)를 씁니다. |

웹의 세 컴포넌트는 루트 `<div>`에 그대로 붙는 `id` · `classes` · `css` · `attributes` · `eventHandlers`도 받습니다.

### 이름 있는 생성자

| 이름 | 있는 곳 | 설명 |
| --- | --- | --- |
| `.space0()` … `.space256()` | `Gap` · `MaxGap` · `SliverGap` | `CoreSpace` 단계마다 하나씩 있는 `const` 생성자. `gapStyle: CoreGapStyle(size: CoreSpace.spaceN)`과 같습니다. |
| `.expand(mainAxisExtent, {color})` | `Gap` · `MaxGap` | 주축은 `mainAxisExtent`, 교차축은 `double.infinity`로 둡니다. `SliverGap`에는 없습니다. |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreGapStyle patch)` | `gapStyle`에 `patch`를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch`가 이깁니다. |
| `copyWith({gapStyle, key})` | 바꾼 값으로 사본을 만듭니다. 웹은 `id` · `classes` · `css` · `attributes` · `eventHandlers`도 받습니다. |

### 테마

| 이름 | 타입 | 읽는 컴포넌트 |
| --- | --- | --- |
| `CoreComponentTheme.gap` | `CoreGapTheme?` | `Gap` |
| `CoreComponentTheme.maxGap` | `CoreMaxGapTheme?` | `MaxGap` |
| `CoreComponentTheme.sliverGap` | `CoreSliverGapTheme?` | `SliverGap` |

세 테마 모두 `style: CoreGapStyle?` 하나만 가집니다. `SliverGap`은 `crossAxisExtent`를 읽지 않습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreGapStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `size` | `double?` | Gap size along the parent's main axis (logical px). `null` inherits from the theme or the design-system default ([defaultSize]). |
| `crossAxisExtent` | `double?` | Gap size along the parent's cross axis (logical px). `null` leaves the cross axis to the parent — Web stretches (`align-self: stretch`), Flutter passes `RenderGap` a `0` extent the parent may stretch. |
| `color` | `CoreColor?` | Fill colour painted across the gap's rectangle. `null` keeps the gap transparent. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="gap/related-join" title="Join">

요소끼리 테두리를 맞대고 한 덩어리로 붙입니다.

</Card>
<Card demo="gap/related-divider" title="Divider">

빈 공간 대신 선으로 영역을 나눕니다.

</Card>
</Cards>
