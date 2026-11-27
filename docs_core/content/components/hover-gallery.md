---
title: HoverGallery
description: 한 자리에 여러 항목을 두고, 포인터가 놓인 가로 위치나 누른 위치에 맞는 항목 하나를 보여 줍니다.
category: display
platforms: [flutter, web]
related: [carousel, card-image, card, dot-indicator]
tags: [interactive, image, gallery, hover, preview]
template: v2
source: display/hover_gallery
---

# HoverGallery

<a id="live-preview"></a>

## 플레이그라운드

속성을 바꾼 뒤 갤러리 위에서 포인터를 좌우로 움직이거나 눌러 보세요. 항목에 적힌 번호가 지금 보이는 항목입니다. 만들어진 코드는 그대로 복사해 쓸 수 있습니다.

<Playground component="hover-gallery" />

미리보기의 색 면은 항목을 구분하려고 문서에서 칠한 것이라, 코드의 항목에는 번호 글자만 둡니다. Web 코드의 항목에 클래스와 `pointer-events`가 있는 이유는 [항목 채우기](#항목-채우기)에 있습니다.

## 구조

갤러리는 높이가 정해진 상자 하나와 그 안의 항목으로 이루어집니다. 화살표 버튼 · 점 · 캡션 같은 부품은 그리지 않습니다.

<Anatomy demo="hover-gallery/anatomy">
<AnatomyItem part="container" name="Container">

높이와 모서리를 정하는 상자입니다. 모서리 밖으로 나가는 부분은 잘립니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=hover-gallery-item]" side="right" name="item">

상자 안에 보이는 항목 하나입니다. `imageUrls`의 이미지이거나 `itemBuilder`가 만든 콘텐츠입니다. 그림의 색 면과 번호는 `itemBuilder`로 그린 예입니다.

</AnatomyItem>
</Anatomy>

항목을 고르는 가로 구간은 화면에 보이지 않습니다. 나누는 방법은 [인터랙션](#인터랙션)에 있습니다.

<a id="기본-사용법-basic-usage"></a>

## 항목 채우기

항목을 채우는 방법은 둘입니다.

| 방법 | 넘기는 값 | 쓰는 때 |
| --- | --- | --- |
| 이미지 주소 | `imageUrls` | 네트워크 이미지를 그대로 보여 줄 때. 갤러리가 이미지를 직접 그립니다. |
| 직접 만든 콘텐츠 | `itemCount` · `itemBuilder` | 앱에 담긴 이미지, 그림과 글을 함께 둔 항목, 색 면처럼 직접 그릴 때 |

### 이미지 주소

기본 코드는 두 플랫폼이 같습니다.

<Code language="dart" title="Flutter · Web">
HoverGallery(
  imageUrls: product.imageUrls,
)
</Code>

이미지를 상자에 맞추는 `fit`의 기본은 상자를 꽉 채우고 넘치는 부분을 자르는 `cover`입니다. 값의 타입은 플랫폼마다 다릅니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
HoverGallery(
  imageUrls: product.imageUrls,
  fit: BoxFit.contain,
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
HoverGallery(
  imageUrls: product.imageUrls,
  fit: 'contain', // CSS object-fit 값
)
```

  </TabItem>
</Tabs>

- Flutter는 `Image.network`, Web은 `<img>`로 그립니다.
- 불러오는 중이나 실패했을 때의 화면을 정하는 속성은 없습니다. 필요하면 `itemBuilder`로 직접 그립니다.
- Flutter는 지금 보이는 항목의 이미지만 만들어, 다른 이미지는 그 항목으로 바뀔 때 불러오기 시작합니다. Web은 처음부터 모든 `<img>`를 문서에 두며 `loading` 속성을 붙이지 않습니다.
- `fit`은 `imageUrls`로 그릴 때만 쓰입니다.

### 직접 만든 콘텐츠

`itemBuilder`는 0부터 시작하는 번호를 받아 그 번호의 콘텐츠를 돌려줍니다. 항목 수는 `itemCount`로 알립니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
final fills = [
  CoreColors.surfaceContainerHighest,
  CoreColors.surfaceContainerHigh,
  CoreColors.surfaceContainer,
];

HoverGallery(
  itemCount: fills.length,
  itemBuilder: (index) => ColoredBox(
    color: Theme.of(context).colorScheme.resolve(CoreColor.token(fills[index])).toValue(),
    child: Center(child: Text('${index + 1}').titleLarge),
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
final fills = [
  CoreColors.surfaceContainerHighest,
  CoreColors.surfaceContainerHigh,
  CoreColors.surfaceContainer,
];

HoverGallery(
  itemCount: fills.length,
  itemBuilder: (index) => div(
    classes: 'flex items-center justify-center w-full h-full',
    styles: Styles(raw: {
      'pointer-events': 'none',
      'background-color': CoreColor.token(fills[index]).toValue(),
    }),
    [Text('${index + 1}').titleLarge],
  ),
)
```

  </TabItem>
</Tabs>

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 크기 | 갤러리 크기로 채워 줍니다. | 맞춰 주지 않습니다. 가장 바깥 요소에 `w-full h-full`을 줍니다. |
| 만드는 범위 | 지금 보이는 번호로만 `itemBuilder`를 부릅니다. 전환하는 동안에는 나가는 항목도 남습니다. | 모든 번호의 항목을 만들어 겹쳐 두고 투명도만 바꿉니다. |
| 항목 안의 상태 | 다른 항목으로 바뀌고 전환이 끝나면 사라집니다. 다시 보일 때 새로 만듭니다. | 가려진 동안에도 남아 있습니다. |

<Note>

**Web의 `itemBuilder` 항목은 가장 바깥 요소에 `pointer-events: none`을 둡니다.** 갤러리는 포인터 이벤트가 닿은 가장 안쪽 요소를 기준으로 가로 위치(`offsetX`)를 읽습니다. 항목 안에 갤러리보다 좁은 요소(글자 · 아이콘 · 작은 상자)가 있으면, 그 위에서는 그 요소의 왼쪽 끝부터 잰 위치로 계산해 다른 번호의 항목이 보일 수 있습니다. 위 설정을 두면 항목 뒤에 있는, 갤러리와 같은 크기의 레이어가 이벤트를 받아 위치가 맞습니다. `imageUrls`의 이미지는 상자를 꽉 채우므로 따로 설정하지 않습니다.

Web의 항목은 보여 주기만 하는 콘텐츠로 만듭니다. 모든 항목이 같은 자리에 겹쳐 있어, 항목 안의 버튼 · 링크는 보이는 것이 눌린다고 보장되지 않습니다. 누르는 요소는 갤러리 밖에 둡니다.

</Note>

### 넘긴 값에 따른 결과

| 넘긴 값 | 결과 |
| --- | --- |
| `imageUrls`와 `itemBuilder`를 함께 | `imageUrls`를 씁니다. 항목 수는 목록의 길이이고 `itemBuilder` · `itemCount`는 쓰지 않습니다. |
| 빈 목록 `imageUrls: []`, 또는 `itemBuilder`와 `itemCount: 0` | 높이만 차지하는 빈 영역을 그립니다. |
| `imageUrls`가 없고 `itemBuilder` · `itemCount` 중 하나라도 빠짐 | Flutter debug 빌드는 생성자 `assert`에 걸립니다. |

`assert`가 없는 Web과 `assert`가 꺼진 Flutter release 빌드에서는, 항목 수를 알 수 없으면(둘 다 없거나 `itemBuilder`만 있으면) 빈 영역을 그립니다. `itemBuilder` 없이 1 이상의 `itemCount`만 넘기면 항목을 그리는 순간 null 검사 오류가 납니다.

<a id="동작-스펙-behavior"></a>

## 상태

갤러리가 스스로 기억하는 것은 지금 몇 번째 항목이 보이는지 하나입니다. 비활성 상태, 항목이 바뀐 것을 알리는 콜백, 바깥에서 번호를 정하는 속성은 없습니다.

### 인터랙션

<Preview demo="hover-gallery/zones" />

그림 아래의 칸은 구간을 설명하려고 문서에서 덧그린 것입니다. 갤러리의 폭을 항목 수로 똑같이 나누고, 구간마다 항목 하나가 대응합니다. 맨 왼쪽 구간이 첫 항목이며, 오른쪽에서 왼쪽으로 읽는 화면에서도 순서가 같습니다. 세로 위치는 보지 않습니다.

| 상황 | 보이는 항목 |
| --- | --- |
| 처음 | 첫 항목 |
| 마우스 포인터를 갤러리 위에서 움직일 때 | 포인터가 놓인 구간의 항목 |
| 클릭하거나 탭할 때 | 누른 구간의 항목 |
| 포인터가 갤러리를 벗어날 때 | 마지막으로 보이던 항목 그대로 |

손가락으로 쓸어 넘기는 제스처는 처리하지 않습니다. 터치 화면에서는 원하는 구간을 눌러 바꿉니다.

### 애니메이션

항목이 바뀌면 이전 항목은 사라지고 새 항목은 나타나는 크로스페이드가 `animationDuration`(기본 300ms) 동안 재생됩니다. Flutter는 `AnimatedSwitcher`의 페이드를 일정한 속도로, Web은 레이어의 `opacity`를 `--easing-ease` 곡선으로 바꿉니다. 동작 줄이기 설정에서의 차이는 [알려진 제약](#알려진-제약)에 있습니다.

### 항목 목록이 바뀔 때

목록이나 `itemCount`가 바뀌어도 갤러리는 보고 있던 번호를 그대로 둡니다. 항목이 남아 있는데 그 번호가 새 항목 수를 벗어나면 다음과 같이 됩니다.

| 플랫폼 | 결과 |
| --- | --- |
| Flutter | `imageUrls`는 목록 밖의 번호를 읽어 오류가 납니다. `itemBuilder`는 범위를 벗어난 번호를 받습니다. |
| Jaspr Web | 보이는 레이어가 없어 빈 상자가 됩니다. 포인터를 움직이거나 누르면 다시 보입니다. |

같은 자리에서 다른 상품의 이미지로 바꾸거나 목록이 줄어들 수 있으면, 목록과 함께 바뀌는 `key`를 줍니다. `key`가 바뀌면 갤러리는 첫 항목부터 다시 시작합니다.

<Code language="dart" title="Flutter · Web">
HoverGallery(
  key: ValueKey(Object.hashAll(product.imageUrls)),
  imageUrls: product.imageUrls,
)
</Code>

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 상품 목록에서 상세 화면을 열기 전에 여러 각도의 이미지를 미리 보여 줄 때
- 포트폴리오 격자에서 작업 화면 몇 장을 같은 자리에서 보여 줄 때
- 카탈로그에서 포인터를 옮기는 것만으로 빠르게 훑어보게 할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 이전 · 다음 버튼, 점 인디케이터, 끌어서 넘기기, 자동 재생이 필요할 때 | [Carousel](/components/carousel) |
| 이미지 한 장에 제목 · 부제를 붙이거나, 포인터를 올리면 이미지가 커지는 효과가 필요할 때(Flutter는 `onPressed`를 줄 때 커집니다) | [CardImage](/components/card-image) |

<a id="do"></a>
<a id="dont"></a>

### 항목 수

<Cards columns="2">
<Card demo="hover-gallery/do-few-items" tone="do" eyebrow="이렇게 하세요">

항목은 3~6개를 권합니다. 구간이 넓어 원하는 항목에서 멈추기 쉽습니다.

</Card>
<Card demo="hover-gallery/dont-many-items" tone="dont" eyebrow="이렇게 하지 마세요">

항목이 많으면 구간이 좁아집니다. 폭 240에 12개를 넣으면 한 구간이 20이라 원하는 항목에 맞추기 어렵습니다.

</Card>
</Cards>

### 이미지 비율

비율과 구도가 같은 이미지를 씁니다. 상자 크기는 항목이 바뀌어도 그대로라, 비율이 다른 이미지는 `fit`에 따라 잘리는 부분이나 남는 자리가 항목마다 달라집니다.

### 보조 미리 보기로 쓰기

키보드로는 항목을 바꿀 수 없습니다. 갤러리는 보조적인 미리 보기로 쓰고, [Carousel](/components/carousel)을 둔 상세 화면처럼 모든 이미지를 볼 수 있는 다른 길을 함께 둡니다.

### 현재 위치 표시

갤러리에는 지금 번호를 밖으로 알려 주는 속성이나 콜백이 없어, 바깥에 둔 [DotIndicator](/components/dot-indicator)를 맞춰 움직이는 방법을 제공하지 않습니다. 위치 표시가 필요하면 `itemBuilder`가 받은 번호로 항목 안에 함께 그립니다.

## 배치

### 폭과 높이

폭은 부모의 폭을 채우고, 높이는 `height` 스타일(기본 300)로 정합니다. 항목의 내용은 갤러리의 높이를 바꾸지 않으며, 비율로 높이를 정하는 속성은 없습니다. Flutter는 높이에 테마의 크기 배율(`scaling`)을 곱하고, Web은 `rem`으로 그립니다.

| 플랫폼 | 부모에게 필요한 것 |
| --- | --- |
| Flutter | 폭의 한계가 있어야 합니다. `Row`에 바로 넣거나 가로 스크롤 안에 두면 레이아웃 오류가 납니다. `Expanded`나 `SizedBox(width: …)`로 감쌉니다. |
| Jaspr Web | 폭이 정해져 있어야 합니다. 항목 레이어가 모두 절대 위치라 갤러리에는 내용에서 나오는 폭이 없습니다. 내용에 맞춰 폭을 정하는 부모(`w-fit` 상자) 안에서는 폭이 0이 되거나 옆 내용의 폭만큼 좁아집니다. |

Flutter 갤러리는 `LayoutBuilder`로 폭을 읽습니다. `IntrinsicWidth` · `IntrinsicHeight`처럼 자식의 크기를 미리 재는 부모 안에서는 debug 빌드에서 오류가 납니다. 이런 부모 안에서는 폭과 높이를 모두 정한 `SizedBox`로 갤러리를 감쌉니다. 한 방향만 정하면, 사이에 `Column`이나 `Row`가 있을 때 정하지 않은 방향까지 재어 같은 오류가 날 수 있습니다.

### 카드에 담기

<Preview demo="hover-gallery/in-card" />

두 플랫폼의 `Card`는 기본값(`CoreCardSizing.intrinsic`)에서 내용에 맞춰 폭을 정합니다. 갤러리에는 그 기준이 될 폭이 없으므로 폭을 함께 정합니다. 아래처럼 Flutter는 카드 바깥에서 폭을 정해 카드가 폭을 재지 않게 하고, Web은 `media`의 틀에 폭을 줍니다. 정하지 않으면 Flutter는 카드가 폭을 재야 하는 자리에서 위의 오류가 나고, Web은 카드가 글의 폭만큼 좁아지거나 갤러리가 보이지 않게 됩니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
SizedBox(
  width: CoreLayout.layout240,
  child: Card(
    media: HoverGallery(
      imageUrls: product.imageUrls,
      hoverGalleryStyle: const CoreHoverGalleryStyle(
        height: CoreSpace.space160,
        borderRadius: CoreBorderRadius.zero,
      ),
    ),
    body: Text(product.name),
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
Card(
  media: div(
    styles: Styles(raw: {'width': '15rem'}),
    [
      HoverGallery(
        imageUrls: product.imageUrls,
        hoverGalleryStyle: const CoreHoverGalleryStyle(
          height: CoreSpace.space160,
          borderRadius: CoreBorderRadius.zero,
        ),
      ),
    ],
  ),
  body: Text(product.name),
)
```

  </TabItem>
</Tabs>

### 카드를 눌러 이동할 때

| 플랫폼 | 갤러리 위를 눌렀을 때 |
| --- | --- |
| Flutter | 갤러리가 탭을 가져갑니다. 바깥의 `GestureDetector` · `Clickable`이나 `Card`의 `onTap`은 불리지 않습니다. |
| Jaspr Web | 누른 구간의 항목으로 바뀌고, 클릭이 바깥 요소까지 전달돼 바깥의 클릭 처리도 실행됩니다. |

두 플랫폼에서 같게 동작하게 하려면, 상세 화면으로 가는 버튼이나 링크를 갤러리 밖에 둡니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

상자의 모양과 전환 시간은 `hoverGalleryStyle` 하나로 바꿉니다. 필드는 높이(`height`), 모서리(`borderRadius`), 전환 시간(`animationDuration`) 셋입니다. 색 · 테두리 · 그림자 필드는 없으므로 항목 안에서 그리거나 갤러리를 감싼 요소에서 정합니다. 이미지를 맞추는 방식은 스타일이 아니라 `fit` 속성으로 정합니다.

<Split>

<Code language="dart" title="갤러리 하나만 바꾸기">
HoverGallery(
  imageUrls: product.imageUrls,
  hoverGalleryStyle: const CoreHoverGalleryStyle(
    height: CoreSpace.space200,
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    animationDuration: Duration(milliseconds: CoreDuration.fast),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: const CoreComponentTheme(
    hoverGallery: CoreHoverGalleryTheme(
      style: CoreHoverGalleryStyle(height: CoreSpace.space200),
    ),
  ),
)
</Code>

</Split>

<a id="resolve-chain"></a>

### 값이 정해지는 순서

뒤에 있는 것이 앞의 것을 필드마다 덮어씁니다. 어디에도 값이 없는 필드는 디자인 시스템의 기본값을 씁니다.

```text
CoreHoverGalleryStyle.defaultHeight · defaultBorderRadius · defaultAnimationDuration
  → CoreComponentTheme.hoverGallery.style   // 앱 전체
  → hoverGalleryStyle                       // 갤러리 하나
```

| 필드 | 기본값 | 화면에 그리는 값 |
| --- | --- | --- |
| `height` | 300 | Flutter는 크기 배율을 곱합니다. Web은 `rem`으로 바꿉니다(300은 `18.75rem`). |
| `borderRadius` | 네 모서리 16 | Flutter는 테마의 모서리 설정과 크기 배율을 반영합니다. Web은 모서리 토큰 단계면 `--coui-radius-*` 변수를, 그 밖의 값은 `px`를 씁니다. |
| `animationDuration` | 300ms | 동작 줄이기 설정에서는 [알려진 제약](#알려진-제약)의 표를 따릅니다. |

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 갤러리 위에 `withStyle`로 스타일을 덧붙일 수 있습니다. 생성자에서 받은 `hoverGalleryStyle`에 합친 사본을 돌려주며, 겹치는 필드는 뒤에 붙인 값이 이깁니다. `.radius0`부터 `.radius9999`까지의 getter는 모서리를 이름이 같은 `CoreRadius` 값으로 바꾸는 줄임 표기입니다. 아래 예에서는 마지막의 `.radius16`이 앞의 `radius24`를 덮습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class HoverGalleryChainExample extends StatefulWidget {
  const HoverGalleryChainExample({super.key});

  @override
  State<HoverGalleryChainExample> createState() => _HoverGalleryChainExampleState();
}

class _HoverGalleryChainExampleState extends State<HoverGalleryChainExample> {
  @override
  Widget build(BuildContext context) {
    return HoverGallery(
          imageUrls: [
            'https://picsum.photos/seed/a/400/300',
            'https://picsum.photos/seed/b/400/300',
            'https://picsum.photos/seed/c/400/300',
          ],
        )
        .withStyle(
          const CoreHoverGalleryStyle(
            height: CoreSpace.space256,
            animationDuration: Duration(milliseconds: CoreDuration.fast),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
          ),
        )
        .radius16;
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class HoverGalleryChainExample extends StatefulComponent {
  const HoverGalleryChainExample({super.key});

  @override
  State<HoverGalleryChainExample> createState() => _HoverGalleryChainExampleState();
}

class _HoverGalleryChainExampleState extends State<HoverGalleryChainExample> {
  @override
  Component build(BuildContext context) {
    return HoverGallery(
          imageUrls: [
            'https://picsum.photos/seed/a/400/300',
            'https://picsum.photos/seed/b/400/300',
            'https://picsum.photos/seed/c/400/300',
          ],
        )
        .withStyle(
          const CoreHoverGalleryStyle(
            height: CoreSpace.space256,
            animationDuration: Duration(milliseconds: CoreDuration.fast),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
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

갤러리는 포인터 입력(움직임 · 클릭 · 탭)에 맞춰 항목을 바꿉니다. 갤러리 전체가 이미지 묶음이라는 역할이나 이름은 두 플랫폼 모두 붙이지 않습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 갤러리가 직접 두는 `Semantics`는 없습니다. `GestureDetector`가 접근성 트리에 누르기(tap) 동작을 붙이고, `imageUrls`의 이미지는 이미지로 표시됩니다. |
| Jaspr Web | 루트 `<div>`에 `role`이나 `aria-*`를 붙이지 않습니다. `attributes`로 넘긴 값은 루트에 붙습니다. |

묶음에 이름이 필요하면 Web은 `attributes`로 주고, Flutter는 `Semantics`로 감쌉니다.

<Code language="dart" title="Web">
HoverGallery(
  attributes: const {'role': 'group', 'aria-label': '상품 이미지'},
  imageUrls: product.imageUrls,
)
</Code>

### 키보드

| 키 | 동작 |
| --- | --- |
| 없음 | 키보드로 항목을 바꾸는 방법이 없습니다. |

Flutter 갤러리는 키 처리를 두지 않고, Web 갤러리가 항목을 바꾸려고 듣는 이벤트는 `mousemove`와 `click`뿐입니다.

### 스크린 리더

`imageUrls`의 이미지 이름은 두 플랫폼 모두 지역화 문자열 `galleryImageLabel`에서 나옵니다. 번호는 1부터이며 한국어는 `갤러리 이미지 1`, 지역화 설정이 없으면 영어 `Gallery image 1`입니다. Flutter는 `Image.network`의 `semanticLabel`로, Web은 `<img>`의 `alt`로 넣습니다. `itemBuilder`로 그린 항목에는 갤러리가 이름을 붙이지 않으므로 항목 안에서 직접 줍니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 접근성 트리의 항목 | 지금 보이는 항목. 전환하는 동안에는 나가는 항목도 남아 있을 수 있습니다. | 모든 항목. 가려진 레이어는 `opacity: 0`일 뿐이라 트리에서 빠지지 않고, `aria-hidden` 같은 속성도 붙이지 않습니다. |
| 항목이 바뀐 알림 | 따로 알리지 않습니다. | 라이브 영역이 없습니다. |

#### Flutter의 누르기 동작

접근성 도구가 누르기 동작을 실행하면 손가락 위치 대신 Flutter가 정한 좌표가 갤러리에 전달됩니다. Flutter 3.50에서는 갤러리의 가운데라, 원하는 항목을 고르지 못하고 가운데 위치의 항목으로 바뀝니다. 항목이 3개면 두 번째입니다.

### 포커스 관리

오버레이가 아니므로 포커스를 옮기거나 가두지 않습니다. 갤러리 자체는 포커스를 받지 않습니다. Flutter에는 `Focus`가 없고 Web 루트에는 `tabindex`가 붙지 않습니다.

`itemBuilder` 항목에 포커스를 받는 요소를 넣으면 범위가 다릅니다. Flutter는 만들어져 있는 항목의 것만 있지만, Web은 모든 항목이 문서에 남아 있어 보이지 않는 항목의 요소에도 `Tab`이 닿습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 키보드로 항목을 바꿀 수 없고, 번호를 정하는 속성도 없습니다. 모든 이미지를 볼 수 있는 다른 길을 함께 둡니다. |
| 공통 | `imageUrls`에는 이미지마다 설명을 줄 수 없고 이름은 번호뿐입니다. 설명이 필요하면 `itemBuilder`에서 Flutter 이미지의 `semanticLabel`, Web `img`의 `alt`를 직접 줍니다. |
| Jaspr Web | 항목이 하나라도 있으면 `onClick`과 `eventHandlers`의 `click` · `mousemove`는 불리지 않습니다. 갤러리의 처리가 같은 이름의 이벤트를 덮어씁니다. 클릭 처리는 갤러리를 감싼 요소에 둡니다. `onMouseEnter` · `onMouseLeave` · `onKeyDown` · `onKeyUp`은 그대로 연결됩니다. |
| Jaspr Web | 항목 안의 버튼 · 링크는 보이는 것이 눌린다고 보장되지 않고, 가려진 항목의 요소도 `Tab` 순서에 남습니다. 누르는 요소는 갤러리 밖에 둡니다. |
| Flutter (iOS) | '동작 줄이기'를 켜도 크로스페이드 시간이 줄지 않습니다. |

#### 동작 줄이기

| 환경 | 크로스페이드 |
| --- | --- |
| Jaspr Web | `prefers-reduced-motion: reduce`이면 500ms 이하의 전환 시간(기본 300ms 포함)은 0이 됩니다. 500ms보다 길게 정한 값은 그대로입니다. |
| Flutter (Android · Web) | Android의 애니메이션 삭제나 브라우저의 동작 줄이기가 켜지면 Flutter 프레임워크가 전환 시간을 5%로 줄입니다. 기본값은 15ms가 됩니다. |
| Flutter (iOS) | 그대로 재생됩니다. 갤러리는 킷의 동작 줄이기 판정(`resolveReducedMotion`)을 쓰지 않습니다. |

iOS를 포함해 Flutter에서 전환을 끄려면 그 판정의 결과를 직접 반영합니다. 판정이 꺼져 있을 때 넘기는 `null`은 테마의 값이나 기본값을 씁니다.

```dart
// Flutter
HoverGallery(
  imageUrls: product.imageUrls,
  hoverGalleryStyle: CoreHoverGalleryStyle(
    animationDuration: resolveReducedMotion(context) ? Duration.zero : null,
  ),
)
```

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

클래스 이름과 구간을 나누는 방법은 같고, 그리는 방식과 입력을 받는 방식이 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 입력 | `MouseRegion`의 hover와 `GestureDetector`의 탭 | 루트 `<div>`의 `mousemove` · `click` |
| 마우스 버튼을 누른 채 움직일 때 | hover가 아니라서 움직임을 따라 바뀌지 않습니다. | 버튼 상태를 보지 않아 `mousemove`가 오면 바뀝니다. `imageUrls`의 `<img>`는 브라우저의 이미지 끌기를 막지 않아, 끄는 동안에는 따라 바뀌지 않을 수 있습니다. |
| 바깥의 누르기 처리 | 갤러리 위의 탭을 받지 못합니다. | 클릭이 바깥까지 전달됩니다. |
| 만드는 항목 | 지금 보이는 항목(전환 중에는 나가는 항목도) | 모든 항목. `opacity`로 하나를 보입니다. |
| `itemBuilder` 항목의 크기 | 갤러리 크기로 채워 줍니다. | `w-full h-full`을 직접 줍니다. |
| `itemBuilder` 항목의 포인터 설정 | 필요 없습니다. | 가장 바깥 요소에 `pointer-events: none` |
| 폭이 정해지지 않은 부모 | 폭에 한계가 없으면 레이아웃 오류가 납니다. | 폭이 0이 되거나 좁아질 수 있습니다. |
| 높이 | logical px에 크기 배율을 곱합니다. | `rem` |
| 전환 곡선 | 일정한 속도 | `--easing-ease` |
| 이미지 | `Image.network` · `fit`은 `BoxFit` | `<img>` · `fit`은 `object-fit` 문자열 |
| 필수 값 검사 | debug 빌드의 `assert` | 없습니다. |
| 동작 줄이기 | Android · Web에서는 5%로 짧아지고 iOS에서는 그대로입니다. | 500ms 이하의 전환은 0이 됩니다. |

<a id="props-parameters"></a>

## API

`W`는 Flutter의 `Widget`, Web의 Jaspr `Component`입니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `imageUrls` | `List<String>?` | `null` | 보여 줄 이미지 주소 목록. `itemBuilder`보다 우선합니다. |
| `itemBuilder` | `W Function(int index)?` | `null` | 번호(0부터)의 콘텐츠를 만듭니다. `itemCount`와 함께 씁니다. |
| `itemCount` | `int?` | `null` | `itemBuilder`로 그릴 때의 항목 수 |
| `fit` | Flutter `BoxFit` · Web `String?` | Flutter `BoxFit.cover` · Web `null`(`cover`로 그림) | `imageUrls`의 이미지를 상자에 맞추는 방식 |
| `hoverGalleryStyle` | `CoreHoverGalleryStyle?` | `null` | 높이 · 모서리 · 전환 시간 |

Flutter에서는 `imageUrls`가 없으면 `itemBuilder`와 `itemCount`를 모두 넘겨야 합니다. 두 플랫폼 모두 `key`를 받습니다. Web은 루트 `<div>`에 붙는 `id` · `classes` · `css` · `attributes` · `eventHandlers`와 공통 이벤트 콜백도 받습니다. 이 가운데 `onChange`는 갤러리의 항목이 바뀐 것을 알려 주는 콜백이 아닙니다. `onClick`은 항목이 있으면 불리지 않습니다([알려진 제약](#알려진-제약)).

### 메서드와 getter

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreHoverGalleryStyle patch)` | `hoverGalleryStyle`에 `patch`를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch`가 이깁니다. |
| `.radius0` … `.radius9999` | `borderRadius`만 해당 `CoreRadius` 값으로 합칩니다. |
| `copyWith(...)` | 넘긴 값만 바꾼 사본을 만듭니다. `null`을 넘기면 지금 값이 남습니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.hoverGallery` | `CoreHoverGalleryTheme?` | 앱 전체의 HoverGallery 테마 |
| `CoreHoverGalleryTheme.style` | `CoreHoverGalleryStyle?` | 모든 갤러리에 적용하는 스타일 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreHoverGalleryStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `height` | `double?` | Container height override (logical px, pre-scaling). |
| `borderRadius` | `CoreBorderRadius?` | Container border radius override (pre-scaling). |
| `animationDuration` | `Duration?` | Image transition animation duration override. |

<!-- STYLE_TABLE:END -->

<Note>

`animationDuration`은 `itemBuilder`로 그린 항목의 전환에도 적용됩니다. `height` 설명의 `pre-scaling`은 Flutter가 이 값에 크기 배율을 곱한다는 뜻이며, Web은 배율을 곱하지 않고 `rem`으로 그립니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="hover-gallery/related-carousel" title="Carousel">

버튼 · 점 · 끌기로 넘기는 슬라이드입니다. [Carousel 문서](/components/carousel)

</Card>
<Card demo="hover-gallery/related-card-image" title="CardImage">

이미지 한 장에 제목을 붙입니다. [CardImage 문서](/components/card-image)

</Card>
<Card demo="hover-gallery/related-card" title="Card">

갤러리와 상품 정보를 한 상자에 담습니다. [Card 문서](/components/card)

</Card>
<Card demo="hover-gallery/related-dot-indicator" title="DotIndicator">

몇 번째인지 점으로 보입니다. [DotIndicator 문서](/components/dot-indicator)

</Card>
</Cards>
