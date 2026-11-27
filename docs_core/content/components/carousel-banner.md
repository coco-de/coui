---
title: CarouselBanner
description: 썸네일 옆에 제목과 보조 문구를 놓는 가로 홍보 띠입니다. Carousel 의 banner variant 에 넣으면 여러 장을 돌려 보여 줄 수 있습니다.
category: display
platforms: [flutter, web]
related: [carousel, card, banner]
tags: [carousel, banner, promotion, strip]
template: v2
source: display/carousel_banner
---

# CarouselBanner

<a id="live-preview"></a>

## 플레이그라운드

속성을 바꿔 보며 띠를 확인하고, 만들어진 코드를 복사하세요. 처음 상태는 `onTap` 을 준, 누를 수 있는 띠입니다. `onTap` 은 가만히 있는 띠의 색과 배치를 바꾸지 않으므로, 마우스를 올리거나 눌러서 커서와 눌림 반응을 확인하세요.

<Playground component="carousel-banner" />

<Note>

누를 수 있는 띠의 Web 코드에는 `classes: 'w-full'` 이 더 있습니다. Web 에서 `onTap` 을 준 띠는 부모에 따라 내용만큼의 폭만 차지할 수 있어, 부모 폭을 채우게 하는 클래스입니다([폭](#폭)).

</Note>

## 구조

띠는 앞쪽의 정사각 썸네일과, 제목 · 보조 문구를 위아래로 놓은 글 열로 이루어집니다. `thumbnail` · `title` · `description` 은 모두 선택이며, 넘기지 않은 것은 그리지 않습니다.

<Anatomy demo="carousel-banner/anatomy">
<AnatomyItem part="container" name="Container">

색을 입힌 띠입니다. 채움은 `primaryContainer`, 모서리는 12(`panel`)입니다. 안쪽 여백은 크기마다 다르고, 썸네일과 글 열은 세로 가운데에 맞춥니다.

</AnatomyItem>
<AnatomyItem select=".co-carousel-banner-thumbnail" side="top" name="thumbnail">

정사각 상자입니다. 모서리는 8, 채움은 `surface` 이며 상자 밖으로 넘치는 부분은 잘립니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part='title']" side="top" name="title">

제목 자리입니다. 보통 `Text` 를 넣습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part='description']" side="right" name="description">

제목 아래의 보조 문구 자리입니다. 제목과의 간격은 2입니다.

</AnatomyItem>
</Anatomy>

- 썸네일을 넘기지 않으면 썸네일과 그 뒤 간격을 함께 빼고, 글 열이 폭을 다 씁니다.
- 제목과 보조 문구 중 하나만 넘기면 그 하나만 그리고, 둘 사이 간격도 뺍니다.
- 순환 타이머, 이전 · 다음 버튼, 점 인디케이터는 이 컴포넌트에 없습니다. 돌려 보여 주는 일은 [Carousel](/components/carousel)이 맡습니다.

## 크기

`size` 는 `CoreCarouselBannerSize` 의 `sm`(기본) · `md` 두 가지입니다. 버튼이나 입력창의 크기 타입인 `CoreComponentSize` 와는 다른 타입입니다. 이 띠는 폼 안의 컨트롤이 아니라 화면 폭을 차지하는 띠라서, `sm` 은 휴대폰 폭, `md` 는 데스크톱 폭을 기준으로 정했습니다. 화면 폭에 따라 저절로 바뀌지는 않습니다.

<Preview demo="carousel-banner/sizes" />

| 항목 | `sm` (기본) | `md` |
| --- | --- | --- |
| 여백 | 16 | 20 |
| 썸네일 | 56 | 72 |
| 아이콘 | 24 | 24 |
| 썸네일 뒤 | 12 | 16 |
| 글 사이 | 2 | 2 |
| 제목 | `titleSmall` | `titleMedium` |
| 보조 문구 | `bodySmall` | `bodyMedium` |
| 기본 높이 | 88 | 112 |

숫자는 논리 px 이며, 크기 배율이 1인 기본 테마의 값입니다. 모서리는 두 크기가 같습니다(띠 12, 썸네일 8). 썸네일의 모서리를 띠보다 작게 둔 것은, 안에 놓인 그림이 띠와 같은 모서리를 쓰면 또 하나의 띠처럼 보이기 때문입니다.

### 높이

- **기본 높이는 썸네일이 있고 글 열이 썸네일보다 낮을 때의 값**입니다. 위 여백, 썸네일, 아래 여백을 더한 것입니다. 기본 글자에서는 제목 한 줄과 보조 문구 한 줄이 여기에 해당하고, 보조 문구를 빼도 높이는 같습니다.
- **제목과 보조 문구의 줄 수는 제한하지 않습니다.** 글이 길거나 폭이 좁으면 줄이 바뀌고, 글 열이 썸네일보다 높아지면 띠가 그만큼 늘어납니다. Web 의 `Carousel` 안에서는 다를 수 있습니다([Carousel 에 넣기](#carousel-에-넣기)).
- 썸네일을 빼면 높이는 글 열의 높이에 위아래 여백을 더한 값입니다.

<Preview demo="carousel-banner/wrapping" />

한 줄로 고정해야 하면 슬롯에 넣는 `Text` 에 `maxLines` 를 줍니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
CarouselBanner(
  thumbnail: Icon(LucideIcons.image),
  title: Text(
    promotionTitle,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  ),
  description: Text(
    promotionSummary,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
CarouselBanner(
  thumbnail: Icon(LucideIcons.image),
  title: Text(promotionTitle, maxLines: 1),
  description: Text(promotionSummary, maxLines: 1),
)
```

  </TabItem>
</Tabs>

## 썸네일 슬롯의 규칙

`thumbnail` 에는 어떤 위젯이든 넣을 수 있습니다. 아이콘을 넣을 때와 그림을 넣을 때 그려지는 모양이 다릅니다. 아래 미리보기의 그림 자리는 네트워크 없이 그리도록 색 면으로 대신했습니다.

<Preview demo="carousel-banner/thumbnail" />

상자의 채움(`thumbnailBackgroundColor`)은 투명한 그림처럼 넣은 위젯이 덮지 않는 곳에 보입니다.

### 아이콘

`Icon` 은 그림이 아니라 표시라서, 상자를 채우지 않고 **가운데에** 놓입니다. 기본 크기는 두 크기 모두 24, 색은 `onSurfaceVariant` 입니다. Lucide 아이콘의 획 두께는 따로 정하는 속성 없이 아이콘 크기에서 정해지며, 24에서는 1.5입니다. 번들에 없는 아이콘을 Web 에서 그리는 방법은 [Icon](/components/icon)에 있습니다.

아이콘의 크기와 색은 값마다 다음 순서로 찾고, 먼저 찾은 값을 씁니다.

1. `Icon` 의 `iconStyle`
2. 앱 테마의 Icon 스타일(`CoreComponentTheme.icon` 의 `style`)
3. 띠의 `thumbnailIconStyle`

그래서 앱 테마에서 Icon 의 크기나 색을 정해 두었다면, 썸네일 아이콘에도 `thumbnailIconStyle` 대신 그 값이 쓰입니다.

<Note>

Flutter 는 `thumbnail` 에 `Icon` 을 **직접** 넣었을 때만 가운데에 놓습니다. `Semantics` 처럼 받은 크기를 그대로 자식에게 주는 위젯으로 감싸 넘기면 아이콘이 상자 크기까지 늘어납니다. 감싸야 하면 감싼 위젯과 `Icon` 사이에 `Center` 를 둡니다. Web 은 상자가 flex 가운데 정렬이라, 감싼 아이콘도 자기 크기로 가운데에 놓입니다.

</Note>

### 그림

Flutter 는 `Icon` 이 아닌 위젯에 정사각 상자의 크기를 그대로 줍니다. Web 은 상자 바로 아래에 넣은 `img` 만 너비 · 높이 100% 로 맞추고, 그 밖의 요소는 자기 크기대로 가운데에 놓습니다.

**그림을 어떻게 맞출지는 띠가 정하지 않습니다.** 그림의 비율이 정사각과 다르면 아래처럼 달라집니다.

| 플랫폼 | 따로 정하지 않았을 때 |
| --- | --- |
| Flutter | `Image` 에 `fit` 을 주지 않으면 `BoxFit.scaleDown` 처럼 그립니다. 비율을 지킨 채 상자 안에 담기고, 상자보다 작은 그림은 키우지 않습니다. 남는 자리에는 상자의 채움이 보입니다. |
| Web | `img` 에 `display: block` 과 너비 · 높이 100% 가 붙고 `object-fit` 은 없어, 그림이 정사각에 맞춰 늘어납니다. 이 규칙은 CSS 우선순위가 가장 낮아, `img { height: auto }` 같은 페이지의 CSS 가 있으면 그쪽이 적용됩니다. |

두 플랫폼에서 똑같이 상자를 꽉 채우고 넘치는 부분을 자르려면 맞춤 방식을 직접 정합니다. Web 에서는 `img` 의 인라인 스타일에 너비 · 높이 · `object-fit` 을 함께 적습니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
CarouselBanner(
  thumbnail: Image.asset('assets/summer.png', fit: BoxFit.cover),
  title: Text('여름 세일'),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
CarouselBanner(
  thumbnail: img(
    src: '/images/summer.png',
    alt: '',
    styles: Styles(
      raw: {'width': '100%', 'height': '100%', 'object-fit': 'cover'},
    ),
  ),
  title: Text('여름 세일'),
)
```

  </TabItem>
</Tabs>

<a id="동작-스펙-behavior"></a>

## 상태

`onTap` 이 없으면 표시 전용 띠이고, `onTap` 을 주면 띠 전체를 누를 수 있습니다. 비활성을 따로 켜는 속성은 없습니다.

<Preview demo="carousel-banner/states" />

| 상태 | 동작 |
| --- | --- |
| 표시 전용 | 띠 자체는 포커스를 받지 않고 누름 반응이 없습니다. |
| Hover | 띠의 색은 바뀌지 않습니다. `onTap` 이 있으면 포인터 커서가 됩니다. |
| Pressed | `onTap` 이 있을 때, 누르는 동안 띠 전체가 0.97배로 줄어듭니다(`Clickable` 의 기본값, 전환 100ms). 동작 줄이기를 켜지 않은 상태에서는 키보드로 실행할 때도 같은 모양이 나타납니다. |
| 키보드 포커스 | `onTap` 이 있을 때 띠 바깥에 포커스 링을 그립니다([포커스 관리](#포커스-관리)). |
| 비활성 | 따로 없습니다. `onTap` 을 빼면 겉모습은 그대로인 표시 전용 띠가 됩니다. |

동작 줄이기 설정을 켜면 누름과 포커스 링의 전환 시간이 0이 됩니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 본문 사이에 얇은 홍보 띠를 놓을 때
- 홍보 여러 건을 돌려 보여 줄 때 — `Carousel(variant: CoreCarouselVariant.banner)` 의 `items` 에 넣습니다.
- 띠 전체를 눌러 한 가지 행동을 하게 할 때(`onTap`)

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 그림이 글 **위에** 오는 세로 카드 | [Card](/components/card) |
| 순환 없이 한 번 알리는 공지. 심각도 variant 나 닫기 버튼이 필요할 때 | [Banner](/components/banner) |
| 화면을 크게 차지하는 홍보 슬라이드 | [Carousel](/components/carousel) 의 `slide` variant |

### 문구와 행동

- 제목과 보조 문구는 한 줄에 들어갈 만큼 짧게 씁니다. 길면 줄이 바뀌어 띠가 높아질 수 있고, Web 의 `Carousel` 안에서는 뒤쪽이 잘릴 수 있습니다.
- 썸네일 그림은 정사각에 가까운 것을 씁니다. 비율이 다르면 맞춤 방식에 따라 잘리거나, 빈 자리가 생기거나, 늘어납니다([그림](#그림)).

<Cards columns="2">
<Card demo="carousel-banner/do-short" tone="do" eyebrow="이렇게 하세요">

제목과 보조 문구를 한 줄씩 짧게 씁니다.

</Card>
<Card demo="carousel-banner/dont-long" tone="dont" eyebrow="이렇게 하지 마세요">

긴 문장을 넣어 여러 줄로 만들지 않습니다. 띠가 높아지고 한눈에 읽기 어렵습니다.

</Card>
<Card demo="carousel-banner/do-whole-tap" tone="do" eyebrow="이렇게 하세요">

행동이 하나면 `onTap` 으로 띠 전체를 누르게 합니다.

</Card>
<Card demo="carousel-banner/dont-button-inside" tone="dont" eyebrow="이렇게 하지 마세요">

누를 수 있는 띠 안에 버튼을 또 넣지 않습니다. 버튼 안에 버튼이 겹치고, 누를 곳이 둘이 됩니다.

</Card>
</Cards>

### 왜 별도 컴포넌트인가

띠의 내용은 **슬라이드마다 다릅니다.** 배너 세 장은 `CarouselBanner` 세 개이고 각각 자기 그림과 문구를 갖습니다. `Carousel` 의 속성에는 이것을 한 벌밖에 담을 수 없습니다. 그래서 `Carousel` 은 점의 위치 같은 순환의 모양을 정하고, 이 컴포넌트는 한 슬라이드가 무엇을 담는지 정합니다.

[Card](/components/card)도 그림과 글을 담지만 `media` · `header` · `body` 를 위에서 아래로 쌓습니다. 이 띠는 가로 배치입니다.

<a id="기본-사용법"></a>
<a id="flutter"></a>
<a id="web"></a>

## 배치

### Carousel 에 넣기

`Carousel(variant: CoreCarouselVariant.banner)` 의 `items` 에 넣습니다. 이 variant 는 점 인디케이터를 띠 아래에 놓고, 이전 · 다음 버튼은 기본으로 끕니다.

<Preview demo="carousel-banner/in-carousel" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Carousel(
  transition: CoreCarouselTransition.sliding(),
  variant: CoreCarouselVariant.banner,
  items: [
    CarouselBanner(
      thumbnail: Image.asset('assets/summer.png', fit: BoxFit.cover),
      title: Text('여름 세일'),
      description: Text('전 품목 30% 할인'),
      onTap: openSale,
    ),
    CarouselBanner(
      thumbnail: Icon(LucideIcons.bell),
      title: Text('신간 입고'),
      description: Text('새 책 세 권'),
      onTap: openNewBooks,
    ),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
Carousel(
  variant: CoreCarouselVariant.banner,
  items: [
    CarouselBanner(
      thumbnail: img(
        src: '/images/summer.png',
        alt: '',
        styles: Styles(
          raw: {'width': '100%', 'height': '100%', 'object-fit': 'cover'},
        ),
      ),
      title: Text('여름 세일'),
      description: Text('전 품목 30% 할인'),
      onTap: openSale,
      classes: 'w-full',
    ),
    CarouselBanner(
      thumbnail: Icon(LucideIcons.bell),
      title: Text('신간 입고'),
      description: Text('새 책 세 권'),
      onTap: openNewBooks,
      classes: 'w-full',
    ),
  ],
)
```

  </TabItem>
</Tabs>

- `transition` 은 Flutter 에서는 꼭 넘겨야 하고, Web 에서는 넘기지 않으면 sliding 입니다.
- 슬라이드는 끌어서(`draggable`, 기본 `true`) 넘기거나 점을 눌러 고릅니다. 자동 재생은 `duration` 이나 `autoPlay: true` 로 켭니다.
- `showNavigation: true` 를 주면 32 크기의 이전 · 다음 버튼이 띠 위에 겹쳐 놓이며, 가로 캐러셀에서는 뒤쪽 끝에 나란히 모입니다. 마우스를 올리면 보입니다(Web 은 캐러셀 안에 포커스가 있어도 보입니다). 띠의 글을 가릴 수 있습니다.
- 누를 수 있는 띠를 넣기 전에 접근성의 [알려진 제약](#알려진-제약)을 확인하세요.

<Note>

**슬라이드의 높이를 맞추세요.** `Carousel` 의 높이를 따로 정하지 않으면, Flutter 는 지금 보이는 슬라이드의 높이를 다른 슬라이드에도 줍니다. 더 높은 띠가 섞여 있으면 레이아웃이 넘쳤다는 오류가 납니다. Web 의 기본 전환(sliding)은 가장 높은 슬라이드에 맞추고, 낮은 띠 아래에는 빈 자리가 남습니다. 모든 슬라이드의 글 줄 수와 썸네일 유무를 맞추거나, `Text` 에 `maxLines` 를 주세요.

**Web 에서는 글의 길이도 확인하세요.** sliding 전환의 슬라이드에는 최소 폭만 정해져 있습니다. 글을 한 줄로 놓았을 때의 띠가 캐러셀보다 넓으면, 줄이 바뀌지 않고 슬라이드가 넓어져 뒤쪽이 잘리고 슬라이드의 위치도 어긋납니다. `maxLines` 를 줘도 슬라이드의 폭은 줄지 않으므로, 한 줄로 놓아도 캐러셀 폭에 들어가는 짧은 글을 쓰세요.

</Note>

### 폭

| 띠 | Flutter | Web |
| --- | --- | --- |
| 표시 전용 | 부모가 준 폭을 채웁니다. | 띠에 `w-full` 이 붙어 부모 폭을 따릅니다. 아래의 `box-sizing` 설명도 확인하세요. |
| `onTap` 있음 | 부모가 준 폭을 채웁니다. | 띠를 감싼 바깥 상자가 `inline-flex` 입니다. block 부모(`Carousel` 의 슬라이드 포함) 안에서는 내용만큼의 폭이 되고, 자식을 늘리는 세로 flex 부모 안에서는 폭을 채웁니다. |

- Flutter 의 띠는 폭의 한계가 있는 부모가 필요합니다. `Row` 의 자식으로 바로 두면 레이아웃 오류가 나므로 `Expanded` 로 감쌉니다.
- Web 의 띠는 `box-sizing` 을 직접 정하지 않습니다. `coui_web` 의 Tailwind 설정은 기본 초기화 스타일(preflight)을 끕니다. 그래서 페이지에 `box-sizing: border-box` 를 적용하는 CSS 가 없으면, block 부모나 세로 flex 부모 안의 표시 전용 띠는 좌우 안쪽 여백만큼(`sm` 32, `md` 40) 부모보다 넓어집니다.

Web 에서 두 경우 모두 부모 폭에 맞추려면 클래스 둘을 함께 줍니다. `w-full` 은 누를 수 있는 띠의 바깥 상자를 넓히고, `box-border` 는 표시 전용 띠가 여백만큼 넘치지 않게 합니다.

```dart
// Web
CarouselBanner(
  title: Text('여름 세일'),
  onTap: openSale,
  classes: 'w-full box-border',
)
```

<a id="스타일-시스템-style-system"></a>
<a id="스타일-시스템"></a>

## 테마와 스타일

크기(`size`), 내용(`thumbnail` · `title` · `description`), 동작(`onTap`)은 위젯 속성으로 넘깁니다. 겉모습(색 · 크기 · 간격)과 안쪽 부품의 스타일은 `carouselBannerStyle`(`CoreCarouselBannerStyle`) 하나로 바꿉니다. 앱 전체의 값은 `CoreCarouselBannerTheme` 의 `style` 에 둡니다. 테마에는 크기별 자리가 없어, 적은 값은 `sm` 과 `md` 에 똑같이 적용됩니다.

| 자리 | 기본 색 토큰 | 바꾸는 필드 |
| --- | --- | --- |
| 띠 | `primaryContainer` | `backgroundColor` |
| 제목 | `onPrimaryContainer` | `titleStyle` |
| 보조 문구 | `onPrimaryContainer` | `descriptionStyle` |
| 썸네일 | `surface` | `thumbnailBackgroundColor` |
| 아이콘 | `onSurfaceVariant` | `thumbnailIconStyle` |

<Split>

<Code language="dart" title="띠 하나만 바꾸기">
CarouselBanner(
  thumbnail: Icon(LucideIcons.star),
  title: Text('회원 할인'),
  description: Text('묶음 상품 20% 할인'),
  carouselBannerStyle: CoreCarouselBannerStyle(
    backgroundColor: CoreColor.token(CoreColors.secondaryContainer),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    titleStyle: CoreTextStyle(
      color: CoreColor.token(CoreColors.onSecondaryContainer),
    ),
    descriptionStyle: CoreTextStyle(
      color: CoreColor.token(CoreColors.onSecondaryContainer),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    carouselBanner: CoreCarouselBannerTheme(
      style: CoreCarouselBannerStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      ),
    ),
  ),
)
</Code>

</Split>

두 예제는 두 플랫폼의 코드가 같습니다.

### 값이 정해지는 순서

<Preview demo="carousel-banner/theme-order" />

```text
디자인 시스템 기본값                          // 크기별 값은 defaultsBySize[size]
  → CoreComponentTheme.carouselBanner.style  // 앱 전체
  → carouselBannerStyle                      // 띠 하나
```

뒤로 갈수록 우선합니다. 필드마다 따로 합쳐지므로 앞에서 정한 다른 필드는 그대로 남습니다. 글자 · 아이콘 · 간격 스타일은 그 안의 필드끼리 합쳐집니다. 예를 들어 `titleStyle` 에 색만 주면 그 크기의 글자 역할은 그대로이고 색만 바뀝니다.

기본값은 두 곳에서 옵니다. `padding` · `thumbnailSize` · `thumbnailIconStyle` · 두 간격 · 두 글자 스타일은 `CoreCarouselBannerStyle.defaultsBySize[size]` 에서, `backgroundColor` · `borderRadius` · `thumbnailBorderRadius` · `thumbnailBackgroundColor` 는 이름이 `default` 로 시작하는 상수에서 옵니다. 테마에 `padding` 이나 `thumbnailSize` 를 적으면 두 크기가 같은 값을 쓰게 됩니다.

### 빠른 덮어쓰기

이미 만든 띠에 `.withStyle(CoreCarouselBannerStyle(...))` 을 이어 붙이면 그 값이 `carouselBannerStyle` 위에 합쳐지고, 뒤에 붙인 것이 이깁니다. 모서리나 색을 위한 짧은 getter 는 없습니다.

```dart
CarouselBanner(title: Text('여름 세일')).withStyle(
  CoreCarouselBannerStyle(
    thumbnailBorderRadius: CoreBorderRadius.all(CoreRadius.radius12),
  ),
)
```

<Preview component="carousel-banner" example="chain" />

위 예제는 띠와 썸네일의 채움만 바꿉니다. 글자색은 `onPrimaryContainer` 그대로이므로, 채움을 바꿀 때는 [색과 대비](#색과-대비)를 함께 확인하세요.

<a id="접근성-accessibility"></a>

## 접근성

### 역할

| 플랫폼 | `onTap` 있음 | `onTap` 없음 |
| --- | --- | --- |
| Flutter | `Clickable` 이 `Semantics(button: true, enabled: true)` 를 붙입니다. | 띠가 더하는 시맨틱이 없습니다. |
| Web | 바깥 상자가 `<div role="button" tabindex="0">` 입니다. | `role` 이 없는 `<div>` 입니다. |

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift` + `Tab` | 누를 수 있는 띠로 포커스를 옮깁니다. 표시 전용 띠 자체에는 서지 않습니다. |
| `Enter` · `Space` | 포커스된 띠의 `onTap` 을 실행합니다. |

화살표 키와 `Escape` 는 띠가 처리하지 않습니다. 슬라이드를 옮기는 일은 `Carousel` 쪽이며, `Carousel` 안에서의 `Tab` 순서에는 [알려진 제약](#알려진-제약)이 있습니다.

### 스크린 리더

- 띠에 이름(`aria-label` · `Semantics` 의 `label`)을 따로 붙이지 않습니다. 보조 기술에 건네는 글은 슬롯에 넣은 위젯에서 옵니다. 빠진 슬롯의 글을 대신 만들어 주지 않으므로, 제목 · 보조 문구 · 대체 텍스트가 모두 없는 누를 수 있는 띠에는 이름을 직접 주어야 합니다.
- `title` 은 제목(heading)으로 표시하지 않습니다.
- 썸네일의 대체 텍스트는 자동으로 만들지 않고, `Icon` 에도 이름이 붙지 않습니다. 뜻이 있는 그림이라면 Web 은 `img` 의 `alt`, Flutter 는 `Image` 의 `semanticLabel` 을 줍니다. 장식용 그림은 Web 에서 `alt: ''`, Flutter 에서 `excludeFromSemantics: true` 로 둡니다.
- Web 에서 `attributes: {'aria-label': '…'}` 을 주면, 누를 수 있는 띠는 `role="button"` 요소에 그 이름이 붙습니다.
- 띠와 `Carousel` 모두 알림 영역(live region)을 만들지 않으므로, 슬라이드가 바뀌어도 따로 알리지 않습니다.

### 포커스 관리

| 항목 | 동작 |
| --- | --- |
| 진입 | 포커스를 자동으로 옮기지 않습니다. `autofocus` 나 `FocusNode` 를 넘기는 속성도 없습니다. |
| 가두기 | 없음. 오버레이가 아니라 페이지 안의 띠입니다. |
| 표시 | 키보드로 포커스하면 띠 바깥에 포커스 링(간격 2, 굵기 2)을 그립니다. |
| 링 모서리 | 링은 띠의 모서리(12)가 아니라 `Clickable` 의 기본 모서리(4)를 기준으로 그립니다. `carouselBannerStyle` 의 `borderRadius` 를 바꿔도 링은 따라 바뀌지 않습니다. |

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | **`Carousel` 안에서는 포커스 링이 잘립니다.** 링은 띠 바깥에 그려지는데, 캐러셀은 슬라이드 영역을 넘는 부분을 자릅니다. 띠가 슬라이드를 꽉 채우면 링이 보이지 않습니다. 링이 필요하면 띠 둘레에 여백을 둔 래퍼를 슬라이드로 넣으세요. 둥근 모서리까지 보이려면 8 정도가 필요합니다. |
| Flutter | `Carousel` 은 높이를 재려고 지금 슬라이드를 안 보이게 한 벌 더 그리고, 앞뒤 슬라이드도 미리 그려 둡니다. 안 보이는 사본은 포인터와 시맨틱에서는 빠지지만, 이 사본도, 지금 보이지 않는 앞뒤 슬라이드도 포커스에서는 빠지지 않습니다. 누를 수 있는 띠를 넣으면 `Tab` 이 보이지 않는 띠에도 서고, 거기에서 `Enter` · `Space` 를 누르면 그 띠의 `onTap` 이 실행됩니다. |
| Web | sliding 전환에서 `Carousel` 은 순환을 위해 만든 복제 슬라이드에만 `inert` 를 붙입니다. 화면 밖에 있는 원래 슬라이드의 누를 수 있는 띠는 `Tab` 순서에 남습니다. |
| Web | `Carousel` 은 끌어 넘긴 뒤에 이어지는 클릭을 막지 않습니다. 누를 수 있는 띠를 마우스로 끌어 넘기면, 마우스 버튼을 놓을 때 `onTap` 도 실행될 수 있습니다. |
| Web | sliding 전환에서는 긴 글을 넣은 슬라이드가 캐러셀보다 넓어져 글이 잘릴 수 있습니다([Carousel 에 넣기](#carousel-에-넣기)). |
| 공통 | `onTap` 으로 다른 주소로 이동해도 띠는 링크가 아니라 버튼입니다. 새 탭으로 열기 같은 링크 동작은 없습니다. |

#### 색과 대비

제목과 보조 문구는 같은 `onPrimaryContainer` 토큰을 씁니다. 색을 입힌 면에서는 회색으로 한 단 낮춘 글이 읽기 어려워, 두 줄의 차이는 글자 크기와 굵기로 냅니다. `backgroundColor` 를 바꿔도 글자색은 따라 바뀌지 않으므로, `titleStyle` · `descriptionStyle` 의 색을 함께 정하고 대비를 확인하세요.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`size` · `thumbnail` · `title` · `description` · `onTap` · `carouselBannerStyle` 은 두 플랫폼이 같은 이름으로 씁니다.

| 항목 | Flutter | Web |
| --- | --- | --- |
| 슬롯 타입 | `Widget` | `Component` |
| 배치 | `Row` 와 `Expanded` 글 열 | flex 가로 배치. 글 열은 `flex-1` · `min-w-0` |
| 누름 띠 폭 | 부모 폭을 채웁니다. | 부모에 따라 내용만큼의 폭이 됩니다([폭](#폭)). |
| 감싼 `Icon` | 감싼 위젯에 따라 상자 크기로 늘어납니다([아이콘](#아이콘)). | 자기 크기로 가운데에 놓입니다. |
| 그림 맞춤 | `Image` 의 `fit` | `img` 의 CSS([그림](#그림)) |
| 크기 배율 | 테마의 크기 배율이 안쪽 여백, 썸네일, 간격에 곱해집니다. | 이 배율 단계가 없습니다. |
| 의미 | `button` 시맨틱 | `role="button"` · `tabindex="0"` |
| 전환 지정 | `Carousel` 의 `transition` 이 필수 | 기본값 sliding |
| 슬라이드 높이 | 높이를 정하지 않으면 지금 슬라이드의 높이를 씁니다. 더 높은 띠는 넘칩니다. | sliding 은 가장 높은 슬라이드에 맞춥니다. |
| 긴 슬라이드 글 | 캐러셀 폭 안에서 줄이 바뀝니다. | sliding 은 슬라이드가 넓어질 수 있습니다. |
| 복사 함수 | `withStyle` | `withStyle` · `copyWith` |

### Web 의 속성 전달

Web 의 `id` · `classes` · `css` · `attributes` · `eventHandlers` 가 붙는 곳은 `onTap` 유무에 따라 다릅니다.

- `onTap` 이 없으면 색을 입힌 띠 자체에 붙습니다.
- `onTap` 이 있으면 띠를 감싸는 `Clickable` 의 바깥 상자에 붙습니다. 이때 `click` · `mousedown` · `mouseup` · `mouseenter` · `mouseleave` · `focusout` · `keydown` · `keyup` 은 `Clickable` 이 직접 쓰므로, 같은 이름으로 넘긴 `eventHandlers` 는 불리지 않습니다. 누름은 `onTap` 으로 받습니다.

<a id="props"></a>
<a id="props-parameters"></a>

## API

모든 속성은 이름 있는 선택 인자입니다. Web 에서는 `Widget` 자리가 Jaspr 의 `Component` 입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `size` | `CoreCarouselBannerSize` | `sm` | 두 크기 `sm` · `md` 중 하나 |
| `thumbnail` | `Widget?` | `null` | 앞쪽의 아이콘이나 그림. `null` 이면 썸네일 자리를 뺍니다. |
| `title` | `Widget?` | `null` | 제목 |
| `description` | `Widget?` | `null` | 제목 아래의 보조 문구 |
| `onTap` | `void Function()?` | `null` | 주면 띠 전체를 누를 수 있고, 포커스와 키보드 실행이 생깁니다. |
| `carouselBannerStyle` | `CoreCarouselBannerStyle?` | `null` | 이 띠의 겉모습 덮어쓰기 |

### 플랫폼 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `key` | `Key?` | `null` | 두 플랫폼 |
| `id` | `String?` | `null` | Web. HTML `id` |
| `classes` | `String?` | `null` | Web. 더할 CSS 클래스 |
| `css` | `Styles?` | `null` | Web. 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | Web. HTML 속성 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | Web. DOM 이벤트 처리기 |

Web 의 `copyWith` 는 `null` 로 넘긴 값을 기존 값으로 두므로, 이미 넣은 `thumbnail` · `description` · `onTap` 을 `copyWith` 로 지울 수 없습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreCarouselBannerStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Strip fill override. `null` → [defaultBackgroundColor]. |
| `borderRadius` | `CoreBorderRadius?` | Strip corner override. `null` → [defaultBorderRadius]. |
| `padding` | `CoreEdgeInsets?` | Strip inset override. `null` → [defaultsBySize] for the active size. |
| `thumbnailSize` | `double?` | Thumbnail side length override (logical px). `null` → [defaultsBySize] for the active size. The thumbnail is square, and it is what sets the strip's height: inset + this + inset. |
| `thumbnailBorderRadius` | `CoreBorderRadius?` | Thumbnail corner override. `null` → [defaultThumbnailBorderRadius]. |
| `thumbnailBackgroundColor` | `CoreColor?` | Thumbnail placeholder fill override. `null` → [defaultThumbnailBackgroundColor]. |
| `thumbnailIconStyle` | `CoreIconStyle?` | How an `Icon` handed to the thumbnail slot is drawn — its size and its colour. `null` → [defaultsBySize] for the active size. |
| `thumbnailTextGapStyle` | `CoreGapStyle?` | Thumbnail → text column spacer. `null` → [defaultsBySize] for the active size. |
| `titleDescriptionGapStyle` | `CoreGapStyle?` | Title → description spacer. `null` → [defaultsBySize] for the active size. |
| `titleStyle` | `CoreTextStyle?` | Title typography override. `null` → [defaultsBySize] for the active size. |
| `descriptionStyle` | `CoreTextStyle?` | Description typography override. `null` → [defaultsBySize] for the active size. |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 설명과 지금 동작이 다른 부분이 있습니다(두 플랫폼 같음).

- `thumbnailSize` 에 적힌 높이(안쪽 여백 + 썸네일 + 안쪽 여백)는 글 열이 썸네일보다 낮을 때의 값입니다. 글 열이 더 높으면 띠가 늘어납니다([높이](#높이)).
- `thumbnailIconStyle` 보다 `Icon` 의 `iconStyle` 과 앱 테마의 Icon 스타일이 앞섭니다([아이콘](#아이콘)).

</Note>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="carousel-banner/related-carousel" title="Carousel">

`banner` variant 로 띠 여러 장을 돌려 보여 줍니다.

</Card>
<Card demo="carousel-banner/related-card" title="Card">

그림과 글을 위에서 아래로 쌓는 카드입니다.

</Card>
<Card demo="carousel-banner/related-banner" title="Banner">

페이지 전체에 해당하는 공지를 알립니다. 심각도 variant 와 닫기 버튼이 있습니다.

</Card>
</Cards>
