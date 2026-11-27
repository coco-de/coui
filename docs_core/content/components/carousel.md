---
title: Carousel
description: 여러 장의 콘텐츠를 같은 자리에서 넘겨 보여 줍니다. 끌기, 이전 · 다음 버튼, 점 인디케이터, 자동 재생으로 넘깁니다.
category: display
platforms: [flutter, web]
related: [carousel-banner, hover-gallery, dot-indicator]
tags: [carousel, slider, slideshow, gallery]
template: v2
source: display/carousel
---

# Carousel

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 캐러셀을 확인하고, 만들어진 코드를 복사하세요. `slides` 와 `banners` 는 앱이 만드는 슬라이드 목록입니다. 끌거나 점을 눌러 넘깁니다. 이전 · 다음 버튼은 `slide` variant 에서 캐러셀에 포인터를 올리면 보이고, `banner` 에서는 기본으로 꺼져 있습니다.

<Playground component="carousel" />

<Note>

컨트롤을 바꾸면 캐러셀이 첫 장부터 다시 시작합니다. `sliding` 과 `fading` 의 차이는 장을 넘길 때 보이고, 슬라이드 폭 비율을 0.8 로 두면 멈춘 상태에서도 보입니다. **자동 재생**을 켜면 코드에 `waitOnStart: true` 를 함께 적습니다. 이 값이 없으면 캐러셀이 뜨자마자 첫 전환이 일어나고, Flutter 에서는 포인터를 올린 채 누른 이전 버튼이나 점이 자동 전환에 덮일 수 있습니다([조심할 것](#조심할-것)).

</Note>

가장 짧은 모양은 슬라이드 목록 하나입니다. `transition` 은 Flutter 에서 필수이고, Web 에서는 생략하면 sliding 입니다. 두 플랫폼에서 같은 줄을 쓰려면 `transition: CoreCarouselTransition.sliding()` 을 적습니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Carousel(
  transition: CarouselTransition.sliding(),
  items: [
    SizedBox(height: 160, child: Center(child: Text('첫째 장'))),
    SizedBox(height: 160, child: Center(child: Text('둘째 장'))),
    SizedBox(height: 160, child: Center(child: Text('셋째 장'))),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
Carousel(
  items: [
    div([const Text('첫째 장').bodyMedium.onSurface]),
    div([const Text('둘째 장').bodyMedium.onSurface]),
    div([const Text('셋째 장').bodyMedium.onSurface]),
  ],
)
```

  </TabItem>
</Tabs>

## 구조

캐러셀은 슬라이드를 잘라 보여 주는 뷰포트, 이전 · 다음 버튼, 점으로 이루어집니다. 점은 [DotIndicator](/components/dot-indicator), 이전 · 다음 버튼은 [Button](/components/button) 입니다.

<Anatomy demo="carousel/anatomy">
<AnatomyItem part="container" name="Viewport">

슬라이드를 잘라 보여 주는 상자입니다. 모서리는 `borderRadius`(기본 16)이고, 캐러셀이 따로 칠하는 배경은 없습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=slide]" side="top" name="Slide">

`items` 의 한 장, 또는 `itemBuilder` 가 만든 한 장입니다. 넘기는 방향의 크기는 `sizeConstraint`(기본 뷰포트 전체)가 정합니다.

</AnatomyItem>
<AnatomyItem select="button" side="top" name="Previous · Next">

원형 `sm` 버튼 두 개입니다. 지름 32 의 불투명한 `surfaceRaised` 면에 1px `outlineVariant` 선과 `CoreShadow.sm` 그림자를 두어, 슬라이드 위에서도 경계가 보입니다. 실제로는 포인터를 올리기 전까지 보이지 않는데, 이 그림에서는 늘 보이게 그렸습니다.

</AnatomyItem>
<AnatomyItem select="[role=tablist]" side="right" name="Indicator">

점 한 줄입니다. 지금 장의 점은 `primary`, 나머지는 `outline` 색이라 단독 DotIndicator 의 기본색(`onSurface` · `outlineVariant`)과 다릅니다. 지금 장의 점도 원형입니다. `slide` variant 에서는 뷰포트 안, 아래에서 16 띄운 자리에 겹쳐 놓입니다.

</AnatomyItem>
</Anatomy>

## Variant

`variant`(`CoreCarouselVariant`)는 무엇을 넘겨 보여 주는지를 고릅니다. 점이 놓이는 자리와 이전 · 다음 버튼의 기본 표시가 함께 정해집니다.

<VariantRow name="slide" component="carousel" props="variant=slide" label="slide">

기본값입니다. 어떤 콘텐츠든 한 장씩 보여 줍니다. 점은 뷰포트 위에 겹치고, 이전 · 다음 버튼은 기본으로 켜져 있습니다.

</VariantRow>

<VariantRow name="banner" component="carousel" props="variant=banner" label="banner">

얇은 홍보 띠입니다. 점은 뷰포트 아래에 따로 놓입니다. `CarouselBanner` 의 `sm` 띠는 높이가 88 이라 버튼 두 개가 내용을 가리므로, 이전 · 다음 버튼은 기본으로 꺼져 있습니다. 슬라이드에는 [CarouselBanner](/components/carousel-banner) 를 넣습니다.

</VariantRow>

| 항목 | `slide` | `banner` |
| --- | --- | --- |
| 점 자리 | 뷰포트 안, `indicatorInset`(기본 아래 16) | 뷰포트 아래. 사이 간격은 `indicatorBelowGapStyle`(기본 0) |
| 버튼 기본값 | 보임 | 숨김 (`showNavigation: true` 로 켭니다) |
| 버튼 자리 (가로) | 양 끝에 하나씩 | 둘을 오른쪽 끝에 모으고 `navGapStyle`(기본 4)만큼 띄움 |
| 점의 포커스 링 | 링 안쪽 간격을 `surface` 색으로 칠함 | 간격이 투명함 |

미리보기는 배너 세 장을 순환하는 예입니다. 썸네일, 제목, 보조 문구는 장마다 `CarouselBanner` 가 갖습니다. 아래 코드는 같은 구성을 두 장으로 줄여 적은 것입니다.

<Preview component="carousel" example="banner" />

```dart
Carousel(
  variant: CoreCarouselVariant.banner,
  transition: CoreCarouselTransition.sliding(),
  items: [
    CarouselBanner(
      thumbnail: Icon(LucideIcons.image),
      title: Text('신간 안내'),
      description: Text('새 책 3권'),
    ),
    CarouselBanner(
      thumbnail: Icon(LucideIcons.image),
      title: Text('회원 할인'),
      description: Text('묶음 20%'),
    ),
  ],
)
```

## 크기

`size`(`CoreCarouselSize`)는 캐러셀의 폭이나 높이가 아니라 점의 크기를 고릅니다. 캐러셀의 크기는 부모와 슬라이드가 정합니다([배치](#배치)).

<Preview demo="carousel/sizes" />

| size | 점 지름 | 점 사이 |
| --- | --- | --- |
| `sm` | 6 | 6 |
| `md` (기본) | 8 | 8 |

표의 값은 DotIndicator 의 크기별 기본값입니다. `carouselStyle` 의 `indicatorSize` · `indicatorSpacing` 이나 `CoreDotIndicatorTheme` 의 값을 주면 그 값이 대신 쓰입니다.

<a id="동작-스펙-behavior"></a>

## 상태

### 이전·다음 버튼

- 포인터가 캐러셀 위에 있을 때만 나타납니다. `navFadeDuration`(기본 200ms) 동안 서서히 바뀝니다. 점이 뷰포트 아래에 있는 `banner` 에서는 점 위에 올려도 나타납니다.
- Web 은 캐러셀 안의 요소에 포커스가 있어도 나타납니다. Flutter 는 포인터만 봅니다.
- 투명한 동안에도 버튼은 그 자리에 있어 누를 수 있습니다.
- Flutter 의 터치 입력은 hover 를 만들지 않아 버튼이 나타나지 않습니다. 터치 화면에서도 쓰는 캐러셀은 점을 남겨 두세요.
- `showNavigation: false` 면 그리지 않습니다.

### 자동 재생

- `autoPlay` 를 생략하면 `duration` 이나 `durationBuilder` 를 준 캐러셀만 자동으로 넘어갑니다. `autoPlay: true` 만 주면 3초(`CoreCarouselStyle.defaultAutoplayInterval`) 간격이고, `autoPlay: false` 는 `duration` 이 있어도 끕니다.
- 한 장에 머무는 시간은 `durationBuilder(index)`, `duration`, 기본 3초의 순서로 정해집니다. `autoplaySpeed` 를 주면 자동 전환의 길이가 그 값이 되고 머무는 시간도 그만큼 늘어납니다.
- `waitOnStart: false`(기본)면 캐러셀이 뜨자마자 첫 전환이 일어나고, `true` 면 한 번 기다린 뒤 넘어갑니다.
- `autoplayReverse: true` 는 거꾸로 넘깁니다.
- `pauseOnHover: true`(기본)면 포인터가 캐러셀 위에 있는 동안 자동 전환을 멈춥니다. 다시 이어지는 방식은 [플랫폼마다 다릅니다](#플랫폼-차이).
- 자동 재생을 멈추는 버튼은 없습니다. 필요하면 앱에 버튼을 두고 `autoPlay` 를 바꾸세요. Flutter 에서 끈 자동 재생을 다시 켤 때는 [조심할 것](#조심할-것)을 보세요.

### 끌기

- `draggable: true`(기본)면 넘기는 방향으로 끌 수 있습니다. 놓으면 장에 맞춰 멈추고, 빠르게 밀었을 때는 관성이 줄어든 뒤에 멈춥니다.
- `disableOverheadScrolling: true`(기본)면 빠르게 밀어도 한 번에 한 장까지만 넘어갑니다. 천천히 끌어 놓을 때의 제한은 [플랫폼마다 다릅니다](#플랫폼-차이).
- `disableDraggingVelocity: true` 는 관성 없이 놓은 자리에서 바로 맞춥니다.

### 끝에서

- `wrap: true`(기본)는 마지막 장 다음에 첫 장이 이어집니다.
- `wrap: false` 는 순환하지 않습니다. 장수를 알아야 하므로 `items` 나 `itemCount` 를 줍니다. 끝에서도 이전 · 다음 버튼은 비활성 모양으로 바뀌지 않습니다.
- 자동 재생과 함께 쓸 때는 `wrap: true` 로 두세요. `wrap: false` 에서 Web 은 끝 장에서 멈추고, Flutter 는 장을 차례대로 넘기지 않습니다([조심할 것](#조심할-것)).

## 전환과 정렬

- `transition` 은 `sliding`(밀어 넘김)과 `fading`(겹쳐 바꿈) 중 하나입니다. `CoreCarouselTransition.sliding(gap: …)` 의 `gap` 은 장 사이 간격이며 `fading` 에는 간격이 없습니다.
- `speed`(기본 200ms)는 전환 시간, `curve`(기본 `CoreEasing.move`)는 가속 곡선입니다.
- `sizeConstraint` 는 한 장이 넘기는 방향으로 차지하는 크기입니다. `CoreCarouselSizeConstraint.fractional(0.8)` 은 뷰포트의 80%, `CoreCarouselSizeConstraint.fixed(240)` 은 정한 길이입니다.
- `alignment`(`start` · `center` · `end`, 기본 `center`)는 지금 장을 뷰포트의 어디에 둘지 정합니다. 장이 뷰포트보다 작을 때만 차이가 보입니다.
- `reverse: true` 는 놓는 순서를 뒤집습니다. 이때 `onIndexChanged` 와 점의 번호는 놓인 자리의 번호이고, `index` 번 자리에는 `items[(-index) % items.length]` 가 보입니다.

<Preview demo="carousel/peek" />

<Note>

`fading` 은 장을 같은 자리에 겹쳐 둡니다. 두 플랫폼 모두 투명한 다른 장이 위에 놓여 누름을 먼저 받을 수 있습니다. 버튼이나 링크처럼 누를 것이 든 슬라이드에는 `sliding` 을 쓰세요.

</Note>

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

여러 이미지나 콘텐츠를 같은 자리에서 슬라이드쇼로 보여 줄 때, 프로모션 배너를 순환시킬 때 씁니다.

### 다른 컴포넌트가 더 맞는 경우

- 시간이나 이전 · 다음 탐색 없이, 포인터가 놓인 가로 위치에 따라 이미지만 바꾼다면 [HoverGallery](/components/hover-gallery)
- 화면 가장자리의 패널을 밀어서 연다면 [Swiper](/components/swiper)

### 슬라이드 넘기기

- 장이 정해져 있으면 `items`, 필요할 때 만들려면 `itemBuilder` 와 `itemCount` 를 줍니다.
- `itemBuilder` 와 `durationBuilder` 가 받는 번호는 장수의 범위를 벗어날 수 있습니다. `index % 장수` 로 감싸서 쓰세요.
- `items` 가 빈 목록이면 Flutter 캐러셀은 오류가 납니다. 보여 줄 장이 없을 때는 캐러셀을 그리지 마세요.
- 모든 장의 높이를 같게 맞추세요. 두 플랫폼이 높이를 잡는 방법이 달라, 장마다 높이가 다르면 빈 자리가 생기거나 잘리거나 넘칩니다.

```dart
Carousel(
  transition: CoreCarouselTransition.sliding(),
  itemCount: books.length,
  itemBuilder: (context, index) => buildSlide(books[index % books.length]),
)
```

점은 장수와 지금 위치를 함께 알려 줍니다.

<Cards columns="2">
<Card demo="carousel/do-cue" tone="do" eyebrow="이렇게 하세요" title="점을 남겨 둡니다">

다음 장이 있다는 것과 지금 위치가 보입니다.

</Card>
<Card demo="carousel/dont-no-cue" tone="dont" eyebrow="이렇게 하지 마세요" title="점까지 감춥니다">

`banner` 는 버튼이 기본으로 꺼져 있어, 점까지 끄면 장이 더 있는지 알 수 없습니다.

</Card>
</Cards>

<a id="dont"></a>

### 순환하지 않을 때는 장수를 알립니다

`wrap: false` 인데 `items` 도 `itemCount` 도 없으면 Flutter 는 assert 에 걸리고, Web 은 장을 하나도 그리지 않습니다.

```dart
// 이렇게 하지 않습니다 — 마지막 장이 어디인지 알 수 없습니다.
Carousel(
  wrap: false,
  transition: CoreCarouselTransition.sliding(),
  itemBuilder: (context, index) => buildSlide(index),
)

// 장수를 함께 줍니다.
Carousel(
  wrap: false,
  transition: CoreCarouselTransition.sliding(),
  itemCount: slides.length,
  itemBuilder: (context, index) => buildSlide(index % slides.length),
)
```

## 배치

### 크기를 정하는 방법

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 폭 | `slide` 는 지금 장이 부모 안에서 차지하는 폭(부모가 폭을 정하면 그 폭). `banner` 는 부모가 허용하는 가장 넓은 폭 | 부모의 폭을 채움 (`w-full`) |
| 높이 (가로) | 지금 장이 스스로 갖는 높이. 부모가 높이를 정하면 그 높이를 따름. `banner` 는 점 줄까지 포함 | 뷰포트는 `sliding` 이면 가장 높은 장, `fading` 이면 지금 장의 높이 |

- 색만 칠한 빈 상자처럼 높이를 스스로 갖지 않는 장은 캐러셀의 높이를 만들지 못합니다. 두 플랫폼에서 모두 통하는 방법은 슬라이드에 높이를 주는 것입니다. Flutter 는 대신 캐러셀을 높이가 정해진 상자에 넣어도 됩니다. Web 의 가로 `sliding` 은 상자나 캐러셀에 높이를 줘도 장이 따라 늘어나지 않습니다.
- Flutter 의 `slide` 는 장이 폭을 채우지 않으면, 부모가 폭을 정하지 않은 자리에서 캐러셀의 폭도 줄어듭니다.
- Flutter 의 `banner` 는 폭이 정해진 자리에 놓으세요. `Row` 의 직접 자식처럼 폭 제한이 없는 자리에서는 오류가 납니다.
- Flutter 는 크기를 재려고 지금 장을 보이지 않게 한 번 더 놓습니다. 슬라이드에 `GlobalKey` 를 쓰지 마세요. `LayoutBuilder` 처럼 스스로 갖는 크기를 계산해 주지 않는 위젯은 가로 방향에서는 높이를, 세로 방향에서는 폭을 정한 `SizedBox` 안에 두세요.
- Web 의 순환 복제 장과 `fading` 의 높이용 사본도 같은 슬라이드를 한 번 더 그립니다. 슬라이드 안에 `id` 를 두면 같은 `id` 가 문서에 두 번 생길 수 있습니다.

<a id="do"></a>

### 세로 방향

`direction: CoreAxis.vertical` 은 위아래로 넘깁니다. 높이를 직접 정해 주세요. 방법은 플랫폼마다 다릅니다.

<Preview demo="carousel/vertical" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
SizedBox(
  width: 320,
  height: 160,
  child: Carousel(
    direction: CoreAxis.vertical,
    transition: CarouselTransition.sliding(),
    items: slides,
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
Carousel(
  direction: CoreAxis.vertical,
  css: Styles(raw: {'height': '10rem'}),
  carouselStyle: CoreCarouselStyle(
    navInset: CoreEdgeInsets.symmetric(vertical: CoreSpace.space16),
  ),
  items: slides,
)
```

  </TabItem>
</Tabs>

- Flutter 는 높이를 정해 주지 않으면 지금 장의 높이를 따릅니다. 폭도 부모가 정하지 않으면 지금 장이 스스로 갖는 폭이 됩니다.
- Web 은 슬라이드를 보고 세로 뷰포트의 높이를 정하지 못합니다. 캐러셀의 바깥 상자에는 부모의 높이를 채우는 스타일도 없으니, `css` 나 `classes` 로 캐러셀에 직접 높이를 주세요.
- 이전 · 다음 버튼은 Flutter 에서는 세로 방향에서도 좌우에, Web 에서는 위아래에 놓입니다. 아이콘은 두 플랫폼 모두 좌우 화살표입니다.
- Web 은 버튼의 위아래 여백으로 `navInset` 의 `top` · `bottom` 을 읽습니다. 기본값은 좌우 여백뿐이라, 위 예처럼 값을 주지 않으면 버튼이 위아래 가장자리에 붙습니다.
- 점은 Flutter 에서는 가로 한 줄 그대로이고, Web 에서는 세로로 쌓입니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

색 · 크기 · 간격과 안쪽 부품의 스타일은 `carouselStyle`(`CoreCarouselStyle`) 하나로 바꿉니다. 자동 재생, 순환, 점과 버튼의 표시 같은 동작은 위젯 파라미터로 넘깁니다.

<a id="시맨틱-vs-스타일"></a>

### 파라미터와 스타일

- **종류 · 배치 · 동작** — 위젯 파라미터로 직접 넘깁니다. `variant`, `size`, `autoPlay`, `wrap`, `pauseOnHover`, `showIndicators`, `showNavigation`, `currentIndex`, `onIndexChanged` 가 여기에 들어갑니다.
- **겉모습(색 · 크기 · 간격)과 안쪽 부품의 스타일** — `CoreCarouselStyle` 로 넘깁니다. `borderRadius` · `indicatorActiveColor` · `indicatorInactiveColor` · `indicatorSize` · `indicatorSpacing` · `indicatorInset` · `navInset` · `controlOverlayColor` · `navFadeDuration` · `indicatorBelowGapStyle` · `navGapStyle` · `prevNextButtonStyle` · `overlayIndicatorFocusOutlineStyle`.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreCarouselStyle 의 default 상수        // 디자인 시스템 기본값
  → CoreCarouselTheme.style             // 프로젝트 공통
  → carouselStyle                       // 인스턴스별
```

- 뒤의 값이 이깁니다. 안쪽 부품의 스타일(`prevNextButtonStyle`, `indicatorBelowGapStyle`, `navGapStyle`, `overlayIndicatorFocusOutlineStyle`)은 필드 하나씩 합쳐집니다.
- 이전 · 다음 버튼은 `defaultPrevNextButtonStyle` 위에 `prevNextButtonStyle` 을 합쳐 [Button](/components/button) 의 `buttonStyle` 로 넘깁니다. 이렇게 넘긴 필드는 버튼 테마(`CoreButtonTheme`)보다 우선합니다.
- 버튼 면 색은 `controlOverlayColor` 가 `prevNextButtonStyle` 의 `backgroundColor` 보다 우선합니다. Web 에서 `prevNextButtonStyle.backgroundColor` 에 토큰 색을 주면 기본 면 색의 클래스가 함께 붙어, 어느 색이 보일지 보장되지 않습니다. 버튼 면 색은 `controlOverlayColor` 로 바꾸세요.
- 점은 DotIndicator 가 그립니다. `CoreDotIndicatorTheme` 의 점 크기와 간격은 캐러셀의 점에도 적용되지만, 두 점 색은 캐러셀이 늘 직접 넘기므로 `indicatorActiveColor` · `indicatorInactiveColor` 로 바꿉니다.

### 사용 예

<Split>

<Code language="dart" title="캐러셀 하나만 바꾸기">
Carousel(
  transition: CoreCarouselTransition.sliding(),
  carouselStyle: CoreCarouselStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    indicatorActiveColor: CoreColor.token(CoreColors.tertiary),
    controlOverlayColor: CoreColor.token(CoreColors.surfaceContainer),
    navInset: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space8),
    prevNextButtonStyle: CoreButtonStyle(
      borderColor: CoreColor.token(CoreColors.outline),
    ),
  ),
  items: slides,
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    carousel: CoreCarouselTheme(
      style: CoreCarouselStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
        indicatorSpacing: CoreSpace.space6,
      ),
    ),
  ),
)
</Code>

</Split>

두 예제의 코드는 Flutter 와 Web 에서 같습니다. `slides` 의 타입만 각 플랫폼의 위젯 목록입니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Carousel` 에 `withStyle` 을 이어 `carouselStyle` 에 값을 덧붙일 수 있습니다. 나중에 이은 값이 같은 필드에서 이깁니다. `.radius16` 처럼 `CoreRadius` 상수와 이름이 같은 getter 는 `borderRadius` 를 그 값으로 둡니다. 아래 예의 `.radius16` 은 기본값과 같은 값입니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class CarouselChainExample extends StatefulWidget {
  const CarouselChainExample({super.key});

  @override
  State<CarouselChainExample> createState() => _CarouselChainExampleState();
}

class _CarouselChainExampleState extends State<CarouselChainExample> {
  @override
  Widget build(BuildContext context) {
    return Carousel(
          transition: CarouselTransition.sliding(),
          items: [
            Container(
              alignment: Alignment.center,
              color: const Color(0xFF3B82F6),
              padding: const CoreEdgeInsets.all(CoreSpace.space64).toValue(geometry: Theme.of(context).geometry),
              child: const Text(
                '슬라이드 1',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            Container(
              alignment: Alignment.center,
              color: const Color(0xFF22C55E),
              padding: const CoreEdgeInsets.all(CoreSpace.space64).toValue(geometry: Theme.of(context).geometry),
              child: const Text(
                '슬라이드 2',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            Container(
              alignment: Alignment.center,
              color: const Color(0xFFF97316),
              padding: const CoreEdgeInsets.all(CoreSpace.space64).toValue(geometry: Theme.of(context).geometry),
              child: const Text(
                '슬라이드 3',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        )
        .withStyle(
          const CoreCarouselStyle(
            indicatorActiveColor: CoreColor.token(CoreColors.tertiary),
            indicatorSize: CoreSpace.space12,
            indicatorSpacing: CoreSpace.space12,
          ),
        )
        .radius16;
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class CarouselChainExample extends StatefulComponent {
  const CarouselChainExample({super.key});

  @override
  State<CarouselChainExample> createState() => _CarouselChainExampleState();
}

class _CarouselChainExampleState extends State<CarouselChainExample> {
  int _index = 0;

  @override
  Component build(BuildContext context) {
    return Carousel(
          currentIndex: _index,
          onIndexChanged: (idx) => setState(() => _index = idx),
          items: [
            div(
              [Text('슬라이드 1')],
              styles: Styles(
                raw: {
                  'background': '#3B82F6',
                  'color': 'white',
                  'font-size': '18px',
                  'display': 'flex',
                  'align-items': 'center',
                  'justify-content': 'center',
                  'padding': 'var(--coui-space-64)',
                },
              ),
            ),
            div(
              [Text('슬라이드 2')],
              styles: Styles(
                raw: {
                  'background': '#22C55E',
                  'color': 'white',
                  'font-size': '18px',
                  'display': 'flex',
                  'align-items': 'center',
                  'justify-content': 'center',
                  'padding': 'var(--coui-space-64)',
                },
              ),
            ),
            div(
              [Text('슬라이드 3')],
              styles: Styles(
                raw: {
                  'background': '#F97316',
                  'color': 'white',
                  'font-size': '18px',
                  'display': 'flex',
                  'align-items': 'center',
                  'justify-content': 'center',
                  'padding': 'var(--coui-space-64)',
                },
              ),
            ),
          ],
        )
        .withStyle(
          const CoreCarouselStyle(
            indicatorActiveColor: CoreColor.token(CoreColors.tertiary),
            indicatorSize: CoreSpace.space12,
            indicatorSpacing: CoreSpace.space12,
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

### 역할

| 부분 | Flutter | Jaspr Web |
| --- | --- | --- |
| 캐러셀 | 역할과 이름이 없습니다. | 바깥 `<div>` 가 `role="region"` 이고 `aria-label` 은 로케일 문구 `carouselLabel`(한국어 "캐러셀")입니다. |
| 슬라이드 | 역할과 이름이 없습니다. | 역할과 이름이 없습니다. |
| 이전 · 다음 | `Semantics(button: true)` 에 "이전 슬라이드" · "다음 슬라이드" 이름을 붙입니다. | `<button type="button">` 에 같은 문구의 `aria-label` 을 붙입니다. |
| 점 | 점 묶음의 이름은 "페이지 탐색"입니다. 점마다 "1번 항목으로 이동" 같은 이름과 버튼 · 선택 상태가 있습니다. | 묶음은 `role="tablist"` 와 "페이지 탐색" 이름, 점은 `role="tab"` 과 "1번 항목으로 이동" 같은 이름을 갖습니다. 지금 점에는 `aria-current="true"` 가 붙습니다. |
| 사본 | 크기를 재는 사본은 `ExcludeSemantics` 로 뺍니다. | 순환 복제 장은 `inert`, `fading` 의 높이용 사본은 `inert` 와 `aria-hidden="true"` 입니다. |

이름은 앱의 로케일을 따릅니다(위의 문구는 한국어). Web 의 `role` 과 `aria-label` 은 `attributes` 로 같은 키를 넘겨도 캐러셀의 값이 남습니다.

### 키보드

| 키 | 포커스 위치 | 동작 | 플랫폼 |
| --- | --- | --- | --- |
| `Enter` · `Space` | 이전 · 다음 버튼 | 이전 장 · 다음 장 | Flutter · Web |
| `←` · `→` | 점 묶음 | 이전 점 · 다음 점의 장으로 이동 | Flutter · Web (Web 은 가로 방향) |
| `↑` · `↓` | 점 묶음 | 이전 점 · 다음 점의 장으로 이동 | Web 의 세로 방향 |

- 점 묶음은 `Tab` 정지점 하나입니다. 화살표 키는 양 끝에서 멈추고 순환하지 않으며, `Home` · `End` 는 받지 않습니다.
- Flutter 는 세로 캐러셀에서도 점이 가로로 놓여 `←` · `→` 를 받습니다.
- 캐러셀 바깥 상자가 처리하는 키는 두 플랫폼 모두 없습니다. 끌기는 포인터 전용이라, `showIndicators` 와 `showNavigation` 을 모두 끄면 캐러셀 자체로는 키보드로 장을 넘길 수 없습니다.

### 스크린 리더

- 장이 바뀐 것을 알리는 라이브 영역, "3장 중 1장" 같은 안내, `aria-roledescription` 은 없습니다. 지금 위치를 담는 것은 점의 선택 상태(Flutter)와 `aria-current`(Web)뿐입니다.
- Flutter 의 이전 · 다음 버튼은 투명한 동안에도 semantics 트리에 이름과 함께 남습니다.
- Web 은 지금 장이 아닌 실제 장을 보조 기술에서 숨기지 않습니다. 숨기는 것은 순환 복제 장과 `fading` 의 높이용 사본뿐입니다.

### 포커스 관리

- 장이 바뀌어도 캐러셀은 포커스를 옮기지 않습니다. 포커스를 가두거나 되돌리지도 않습니다.
- Web 의 바깥 상자에는 `tabindex` 가 없습니다. 이전 · 다음 버튼은 포커스를 받으면 나타납니다.
- Flutter 의 이전 · 다음 버튼은 투명한 상태에서도 포커스를 받습니다. 포커스만으로는 나타나지 않아 포커스 링도 보이지 않습니다.
- 지금 장이 아닌 장의 컨트롤에도 `Tab` 이 닿을 수 있습니다. Web 은 실제 장을 모두 문서에 두고, `inert` 는 순환 복제 장과 `fading` 의 높이용 사본에만 붙입니다. Flutter 는 화면 밖에 만들어 둔 이웃 장의 컨트롤이 포커스 순서에 남습니다.
- Flutter 는 크기를 재는 사본에서 포커스를 빼지 않습니다. 지금 장에 컨트롤이 있으면 보이지 않는 같은 컨트롤에도 포커스가 갈 수 있습니다.
- 이전 · 다음 버튼은 슬라이드 위에 놓이므로, 포커스 링과 버튼 사이의 간격을 `surface` 색으로 칠합니다. `slide` variant 의 점도 같고(`overlayIndicatorFocusOutlineStyle` 로 바꿉니다), 점이 뷰포트 아래에 놓이는 `banner` 에서는 간격이 투명합니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 자동 재생을 멈추는 컨트롤이 없습니다. 일시 정지는 포인터를 올렸을 때뿐이고, 키보드 포커스로는 멈추지 않습니다. 자동 재생을 쓰면 멈춤 버튼을 함께 두세요. |
| 공통 | 동작 줄이기 설정을 켜도 장을 넘기는 전환과 자동 재생은 그대로입니다. 이전 · 다음 버튼이 나타나는 전환(기본 200ms)은 즉시가 됩니다. |
| 공통 | 장이 바뀐 것과 장수를 알려 주는 안내가 없습니다. 필요하면 `onIndexChanged` 로 앱이 알려 주세요. |
| 공통 | 투명한 이전 · 다음 버튼도 누를 수 있습니다. |
| 공통 | `fading` 에서는 투명한 장이 누름을 먼저 받을 수 있습니다. |
| Flutter | 캐러셀의 역할과 이름이 없고 이름을 주는 파라미터도 없습니다. `carouselLabel` 문구는 Flutter 캐러셀에 붙지 않습니다. 필요하면 `Semantics` 로 감싸 이름을 주세요. |
| Flutter | 포인터가 캐러셀 위에 없으면, 키보드 포커스를 받은 이전 · 다음 버튼이 보이지 않습니다. |
| Flutter | 크기를 재는 사본의 컨트롤이 포커스를 받을 수 있습니다. |
| Flutter | `sliding` 전환에서 슬라이드 크기를 비율(기본값 포함)로 정한 캐러셀은, 너비(세로 방향은 높이)가 0 이 되면 레이아웃에서 예외를 던집니다. 접거나 숨기는 영역에서는 크기가 0 인 동안 캐러셀을 만들지 마세요. |
| Jaspr Web | `attributes` 로 캐러셀의 이름을 바꿀 수 없습니다. |

모션 감소, 고대비, 최소 터치 타깃처럼 모든 컴포넌트에 공통인 항목은 [전역 접근성 축](/accessibility) 에 정리되어 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

Flutter 전용인 `controller` 와 Web 의 HTML 속성을 빼면 파라미터 이름이 같습니다. 위치를 다루는 방식과 그리는 방법은 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 슬라이드 타입 | `Widget` | `Component` |
| `transition` | 필수 | 생략하면 `sliding` |
| `currentIndex` | 화면에 반영하지 않음 | 시작 위치. 값이 바뀌면 그 장으로 이동 (`onIndexChanged` 는 부르지 않음) |
| 직접 제어 | `controller` | `currentIndex` |
| 번호 알림 | 끌거나 전환하는 중에 가장 가까운 장이 바뀔 때. 여러 장을 건너뛰면 지나는 번호도 올 수 있음 | 이동을 시작할 때. `sliding` 이 양 끝을 이어 넘을 때는 전환이 끝난 뒤 |
| 만드는 장 | 지금 위치 둘레의 장과 크기를 재는 사본 | 모든 장과 순환 복제 장 |
| 장수 생략 | `itemBuilder` 만 주면 끝없이 넘김 (점은 없음) | 장을 그리지 않음. `itemCount` 필요 |
| 장이 하나 | 점 하나와 켜 둔 버튼을 그림. 자동 재생도 돌아 같은 장이 넘어감 | 점, 버튼, 자동 재생이 없음 |
| 호버 뒤 | 간격을 처음부터 다시 셈. `waitOnStart: false` 면 바로 넘김 | 간격을 계속 세고, 올려 둔 동안의 차례만 건너뜀 |
| 느린 끌기 | 가장 가까운 장에 맞춤 (한 장 제한 없음) | `disableOverheadScrolling` 이면 한 장까지 |
| `navInset` | 네 방향 모두 버튼 둘레의 여백 | 넘기는 방향의 두 값만 (가로 `left` · `right`, 세로 `top` · `bottom`) |
| `fixed` 크기 | 논리 px | 값을 16 으로 나눈 `rem` |
| 세로 방향 | 버튼 좌우, 점 가로 | 버튼 위아래, 점 세로 |
| 그리는 방법 | `sliding` 은 `Position` 이동, `fading` 은 `Opacity` | `sliding` 은 flex 줄의 `translate`, `fading` 은 CSS `opacity` |
| 순환 | 계속 이어지는 위치 값 | `sliding` 은 복제 장으로 넘긴 뒤 제자리로 순간 이동 |
| 곡선 | `curve` → `Cubic` | `curve` → `cubic-bezier()` |
| 끌기 입력 | `GestureDetector` | `pointerdown` 뒤에 문서의 포인터 이벤트 |
| 자동 재생 | `Ticker` | 이어 거는 `Timer` |
| 호버 감지 | `MouseRegion` | 자동 재생 멈춤은 `mouseenter` · `mouseleave`, 버튼 표시는 CSS 호버 |
| 버튼 표시 | `AnimatedOpacity` (`navFadeDuration` · `CoreEasing.move`) | 버튼을 감싼 `<div>` 의 `opacity` (`Button` 자체가 아님). 시간과 곡선은 Flutter 와 같음 |

### 조심할 것

**Flutter**

- `pauseOnHover` 로 자동 재생이 멈춘 상태에서 이전 · 다음 버튼이나 점을 누르거나 마우스로 천천히 끌어 놓으면, `waitOnStart: false` 에서는 자동 전환이 곧바로 덮어써, 고른 장이 아니라 자동 재생이 넘기는 방향의 장으로 갈 수 있습니다. `waitOnStart: true` 로 두세요.
- 지금 위치 둘레의 장만 만들고, 장이 넘어가면 같은 자리를 다른 장이 이어받습니다. 슬라이드 위젯의 `State`(입력한 값, 펼침 상태 등)는 다른 장으로 옮겨 가거나 처음 값으로 돌아갈 수 있습니다. 지켜야 하는 값은 캐러셀 바깥에 두세요.
- 실행 중에 `autoPlay` 를 `true` 로 바꿔도 곧바로 돌기 시작하지 않습니다. 포인터를 올렸다 내리거나 장이 한 번 움직여야 시작합니다. 바로 시작해야 하면 `key` 를 바꿔 캐러셀을 새로 만들고, 위치를 이어 가려면 같은 `controller` 를 넘기세요.
- `wrap: false` 에 자동 재생을 켜면, 첫 장에서의 자동 전환이 다음 장이 아니라 마지막 장으로 향합니다. 차례대로 넘기려면 `wrap: true` 를 쓰세요.
- 처음 장과 마지막 장 사이를 넘는 동안, 또는 `wrap: false` 의 마지막 장에서 다음을 누르면 `onIndexChanged` 가 장수와 같은 번호를 줄 수 있습니다. 받은 번호도 `index % 장수` 로 감싸세요.
- 여러 바퀴를 돈 뒤에 점을 누르면 지나온 바퀴를 되감으며 이동합니다.
- 세로 방향에서 `sizeConstraint` 가 비율(기본값 포함)이면, 끈 거리를 높이가 아니라 폭을 기준으로 셉니다. 폭과 높이가 다르면 장이 손가락과 다른 빠르기로 움직입니다.

**Jaspr Web**

- `sliding` 이 양 끝을 이어 넘는 순간 자동 재생의 `durationBuilder` 가 `-1` 이나 장수와 같은 번호를 받을 수 있습니다. `index % 장수` 로 감싸세요.
- `durationBuilder` 에 `build` 안에서 새로 만드는 함수를 넘기면, 부모가 다시 그려질 때마다 자동 재생 타이머를 처음부터 다시 겁니다. `waitOnStart: false` 면 그때마다 바로 넘어가므로, `onIndexChanged` 에서 `setState` 를 부르는 화면은 장이 쉬지 않고 넘어갈 수 있습니다. `State` 의 메서드나 최상위 함수를 넘기세요.
- 캐러셀을 처음 만들 때 장이 둘 미만이면 자동 재생을 걸지 않고, 장수만 늘어나서는 시작하지 않습니다. 장을 불러온 뒤에 캐러셀을 만들거나, 불러온 뒤 `key` 를 바꿔 새로 만드세요.
- 캐러셀의 `onMouseEnter` · `onMouseLeave` 와, `eventHandlers` 의 `mouseenter` · `mouseleave` · `pointerdown` 은 캐러셀이 쓰는 처리로 바뀌어 불리지 않습니다. 필요하면 캐러셀을 감싼 `div` 에 거세요.
- `sliding` 의 장은 최소 크기(`min-width`, 세로는 `min-height`)만 갖습니다. 가로 방향에서 줄을 바꾸지 않고 놓았을 때의 폭이 장보다 넓은 내용(긴 문장, 큰 이미지)은 장을 넓혀 위치가 어긋날 수 있습니다. 슬라이드 내용의 폭을 길이 값으로 제한하세요.

<a id="props-parameters"></a>

## API

`W` 는 Flutter 의 `Widget`, Web 의 `Component` 입니다. `items` 와 `itemBuilder` 중 하나는 주어야 합니다. Flutter 는 둘 다 없으면 assert 에 걸리고, Web 은 장을 그리지 않습니다.

<a id="공통-flutter-web"></a>

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `items` | `List<W>?` | `null` | 슬라이드 목록 |
| `itemBuilder` | `CoreCarouselItemBuilder<W>?` | `null` | 필요할 때 장을 만드는 함수 `(Object context, int index)`. 둘 다 주면 이것을 씁니다. 번호는 범위를 벗어날 수 있습니다. |
| `itemCount` | `int?` | `null` | 장수. 생략하면 `items` 의 길이입니다. 점을 그리려면 장수가 있어야 합니다. |

### 모양과 배치

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `variant` | `CoreCarouselVariant` | `slide` | `slide` 또는 `banner` |
| `size` | `CoreCarouselSize` | `md` | 점 크기 (`sm` · `md`) |
| `showIndicators` | `bool` | `true` | 점 표시 |
| `showNavigation` | `bool?` | `null` | 이전 · 다음 버튼 표시. `null` 이면 `slide` 는 보이고 `banner` 는 숨깁니다. |
| `direction` | `CoreAxis` | `horizontal` | 넘기는 방향 |
| `reverse` | `bool` | `false` | 놓는 순서 뒤집기 |
| `sizeConstraint` | `CoreCarouselSizeConstraint` | `fractional(1)` | 넘기는 방향의 장 크기. `fractional` 또는 `fixed` |
| `alignment` | `CoreCarouselAlignment` | `center` | 지금 장의 자리 (`start` · `center` · `end`) |
| `carouselStyle` | `CoreCarouselStyle?` | `null` | 겉모습과 안쪽 부품의 스타일 |

### 전환

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `transition` | `CoreCarouselTransition` | Flutter 필수 · Web `sliding` | 전환 방식과 장 사이 간격 |
| `curve` | `CoreCubicBezier` | `CoreEasing.move` | 전환의 가속 곡선 |
| `speed` | `Duration` | `CoreCarouselStyle.defaultTransitionSpeed` | 전환 시간 (200ms) |

### 자동 재생 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `autoPlay` | `bool?` | `null` | 자동 재생. `null` 이면 `duration` 이나 `durationBuilder` 가 있을 때 켭니다. |
| `duration` | `Duration?` | `null` | 한 장에 머무는 시간. 없으면 3초 |
| `durationBuilder` | `CoreCarouselDurationBuilder?` | `null` | 장마다 머무는 시간. `null` 을 돌려주면 `duration`, 그것도 없으면 3초 |
| `autoplaySpeed` | `Duration?` | `null` | 자동 전환 시간. 머무는 시간에도 더해집니다. `null` 이면 `speed` |
| `autoplayReverse` | `bool` | `false` | 거꾸로 넘기기 |
| `waitOnStart` | `bool` | `false` | 첫 자동 전환 전에 한 번 기다리기 |
| `pauseOnHover` | `bool` | `true` | 포인터를 올린 동안 자동 전환 멈추기 |

### 이동과 끌기

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `currentIndex` | `int` | `0` | Web 의 시작 위치이며, 값을 바꾸면 그 장으로 옮깁니다. Flutter 는 화면에 반영하지 않습니다. |
| `onIndexChanged` | `void Function(int)?` | `null` | 지금 장의 번호가 바뀔 때. 부르는 때는 플랫폼마다 다릅니다. |
| `wrap` | `bool` | `true` | 순환. `false` 면 `items` 나 `itemCount` 가 필요합니다. |
| `draggable` | `bool` | `true` | 끌어서 넘기기 |
| `disableDraggingVelocity` | `bool` | `false` | 끌기의 관성 끄기 |
| `disableOverheadScrolling` | `bool` | `true` | 한 번의 끌기를 한 장으로 제한 ([플랫폼 차이](#플랫폼-차이)) |

Web 에서 `currentIndex` 는 마지막으로 준 값과 다를 때만 반영됩니다. 앱에서도 위치를 옮긴다면 `onIndexChanged` 로 상태를 맞춰 두세요.

### Flutter 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `controller` | `CarouselController?` | `null` | 코드로 장을 옮기는 컨트롤러 |

`CarouselController` 는 `animateNext` · `animatePrevious` · `animateTo` · `animateSnap` · `jumpTo` 로 위치를 옮깁니다. `value` 는 이어지는 위치 값이라 정수일 때 장에 딱 맞고, 순환하면 장수를 넘거나 음수가 됩니다. 장 번호는 `getCurrentIndex(itemCount)` 로 읽는데, 전환 중에는 소수일 수 있습니다. 처음 위치는 `CarouselController()..jumpTo(2)` 처럼 정합니다.

```dart
final controller = CarouselController();

Carousel(
  controller: controller,
  transition: CarouselTransition.sliding(),
  items: slides,
)

// 버튼 처리 등에서
controller.animateNext(CoreCarouselStyle.defaultTransitionSpeed);
```

Flutter 에는 짧은 별칭 `CarouselAlignment` · `CarouselSizeConstraint` · `CarouselFixedConstraint` · `CarouselFractionalConstraint` · `CarouselItemBuilder` · `CarouselDurationBuilder` 가 있습니다. Web 에 있는 별칭은 `CarouselItemBuilder` 와 `CarouselDurationBuilder` 둘뿐입니다. 두 플랫폼에서 같은 코드를 쓰려면 `CoreCarouselTransition` · `CoreCarouselAlignment` · `CoreCarouselSizeConstraint` 를 씁니다.

Flutter 의 `CarouselTransition` 은 별칭이 아니라 `CoreCarouselTransition` 을 상속한 Flutter 전용 클래스입니다. `transition` 은 두 타입을 모두 받습니다. `CarouselTransition` 을 상속하면 `layout` 으로 장을 놓는 방법을 직접 만들 수도 있습니다.

### Web 의 HTML 속성

Web 의 `Carousel` 은 `id` · `classes` · `css` · `attributes` · `eventHandlers` 와 `onClick` · `onKeyDown` 같은 이벤트도 받아 바깥 `<div>` 에 붙입니다. `role` 과 `aria-label` 은 캐러셀의 값이 남고, 마우스 · 포인터 이벤트 일부는 [조심할 것](#조심할-것)처럼 불리지 않습니다.

### 체인과 사본

- `withStyle(CoreCarouselStyle patch)` 는 `carouselStyle` 에 `patch` 를 합친 사본을 돌려줍니다.
- `radius0` 부터 `radius64` 까지와 `radius9999` getter 는 `borderRadius` 를 같은 이름의 `CoreRadius` 값으로 둡니다.
- `copyWith` 는 넘긴 값만 바꾼 사본을 만듭니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreCarouselStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `borderRadius` | `CoreBorderRadius?` | Outer carousel viewport corner radius. Falls back to [defaultBorderRadius]. |
| `indicatorActiveColor` | `CoreColor?` | Active indicator dot fill colour. |
| `indicatorInactiveColor` | `CoreColor?` | Inactive indicator dot fill colour. |
| `indicatorSize` | `double?` | Indicator dot diameter (logical px). |
| `indicatorSpacing` | `double?` | Native `Row.spacing` between indicator dots — forwarded to `CoreDotIndicatorStyle.spacing`, applied as inter-dot Flex spacing (not a `Gap` widget) in logical px. |
| `indicatorInset` | `CoreEdgeInsets?` | Inset of the indicator row from the viewport edge. Typically only the `bottom` side is non-zero (default `CoreEdgeInsets.only(bottom: CoreSpace.space16)`); each side applies on its own, so you can set any side (e.g. push the row up or pad it horizontally). |
| `navInset` | `CoreEdgeInsets?` | Inset of the previous / next buttons from the viewport edge — typically symmetric horizontal (default `CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16)`). It becomes the padding around the buttons, so you can pad any side. |
| `controlOverlayColor` | `CoreColor?` | Surface (background) colour applied behind the prev / next nav controls. `null` → [defaultControlOverlayColor]. |
| `navFadeDuration` | `Duration?` | Fade duration for the prev / next nav buttons revealing on carousel hover (hidden until the pointer is over the viewport). `null` → [defaultNavFadeDuration]. |
| `indicatorBelowGapStyle` | `CoreGapStyle?` | Spacer between the viewport and the indicator row when the widget's `variant` is `banner` — forwarded straight to `Gap(gapStyle: …)`. Unused by the `overlay` placement, whose row is anchored by [indicatorInset] instead. `null` → [defaultIndicatorBelowGapStyle]. |
| `navGapStyle` | `CoreGapStyle?` | Space between the previous and the next button when the widget's `variant` is `banner`, passed as is to `Gap(gapStyle: …)`. `null` uses [defaultNavGapStyle]. |
| `prevNextButtonStyle` | `CoreButtonStyle?` | Look of the previous / next buttons — colours, border, padding, shadow. Laid over [defaultPrevNextButtonStyle]. |
| `overlayIndicatorFocusOutlineStyle` | `CoreFocusOutlineStyle?` | Focus ring of the indicator dots when they overlay the slide (the `slide` variant), passed on as the indicator row's `CoreDotIndicatorStyle.focusOutlineStyle`. Laid over [defaultOverlayIndicatorFocusOutlineStyle]. |

<!-- STYLE_TABLE:END -->

<Note>

- 표의 `overlay` 배치는 `slide` variant 를 말합니다.
- `navInset` 을 네 방향 모두 읽는 것은 Flutter 입니다. Web 은 넘기는 방향의 두 값만 씁니다.
- `controlOverlayColor` 를 주면 `prevNextButtonStyle.backgroundColor` 대신 이 색이 버튼 면이 됩니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="carousel/related-carousel-banner" title="CarouselBanner">

`banner` variant 의 슬라이드로 넣는 홍보 띠입니다. [CarouselBanner 문서](/components/carousel-banner)

</Card>
<Card demo="carousel/related-dot-indicator" title="DotIndicator">

캐러셀의 점을 그리는 컴포넌트입니다. [DotIndicator 문서](/components/dot-indicator)

</Card>
<Card demo="carousel/related-hover-gallery" title="HoverGallery">

포인터가 놓인 가로 위치에 따라 이미지를 바꿉니다. [HoverGallery 문서](/components/hover-gallery)

</Card>
</Cards>
