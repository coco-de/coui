---
title: CardImage
description: 이미지 하나와 제목 · 부제 · 앞뒤 슬롯을 한 상자에 담는 카드입니다. onPressed 를 주면 카드 전체가 버튼 하나가 됩니다.
template: v2
source: layout/card_image
---

# CardImage

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

`CardImage` 는 이미지(`image`)와 글 줄(`leading` · `title` · `subtitle` · `trailing`)을 테두리와 둥근 모서리를 가진 상자 하나에 담습니다. 속성을 바꿔 보며 카드를 확인하고, 만들어진 코드를 복사하세요. 코드의 `photo` · `thumbnail` 은 직접 준비하는 이미지이고, `openPhoto` 는 직접 만드는 함수입니다. 이 페이지의 미리보기는 네트워크 없이 그리도록 사진 자리에 색 면과 아이콘을 넣었습니다.

<Playground component="card-image" />

<a id="import"></a>

Flutter는 `package:coui_flutter/coui_flutter.dart`, Web은 `package:coui_web/coui_web.dart` 를 import 합니다.

## 구조

<Anatomy demo="card-image/anatomy">
<AnatomyItem part="container" name="Container">

카드 상자(`containerStyle`). `surface` 바탕에 1px `outlineVariant` 테두리와 모서리 16 을 두고 안의 내용을 자릅니다. 아래에 14 의 여백이 있고 `CoreShadow.xs` 의 옅은 그림자를 드리웁니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=image]" side="right" name="image">

이미지 슬롯. 필수입니다. 둘레의 이미지 칸(`frameStyle`)은 `surfaceContainer` 바탕이고 테두리와 모서리가 없습니다. 위쪽 모서리는 카드 상자가 자릅니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=leading]" side="left" name="leading">

글 앞 슬롯. 아이콘 같은 것을 넣습니다. 선택 사항입니다.

</AnatomyItem>
<AnatomyItem part="label" name="title">

제목 슬롯. 15 SemiBold, `onSurface` 입니다. 선택 사항입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=subtitle]" side="right" name="subtitle">

제목 아래 부제 슬롯. 13, `onSurfaceVariant` 입니다. 선택 사항입니다.

</AnatomyItem>
<AnatomyItem part="trailing" name="trailing">

글 뒤 슬롯. 주지 않으면 오른쪽 화살표(`chevron-right`)가 그려집니다.

</AnatomyItem>
</Anatomy>

- 이미지와 글 줄 사이는 12 입니다(`imageContentGapStyle`).
- 글 줄(`contentStyle`)은 글이 시작하는 쪽에서 14, 끝나는 쪽에서 10 안쪽에 놓입니다. 오른쪽에서 왼쪽으로 쓰는 언어에서는 두 값의 방향이 바뀝니다.
- `leading` · 가운데 글 · `trailing` 사이는 12, 제목과 부제 사이는 2 입니다.

### 기본 화살표

`trailing` 을 주지 않으면 글 줄 끝에 화살표가 그려집니다. `onPressed` 가 없는 표시용 카드에도 그려집니다. 화살표를 끄는 파라미터는 없습니다. 다른 것을 보이려면 `trailing` 에 넣고, 보이지 않게만 하려면 색을 투명하게 덮습니다. 색만 바꾸는 방법이라 화살표의 자리는 남습니다.

```dart
CardImage(
  image: thumbnail,
  title: Text('산 풍경'),
  cardImageStyle: const CoreCardImageStyle(
    contentStyle: CoreBasicStyle(
      trailingIconStyle: CoreIconStyle(color: CoreColor.transparent),
    ),
  ),
)
```

## 이미지 슬롯

### 이미지 넣기

`image` 는 위젯(Flutter) 또는 컴포넌트(Web)를 받는 슬롯입니다. URL 이나 파일 경로를 받는 파라미터는 없습니다. Flutter의 `Image.asset` · `Image.network` · `Image.memory` 나 Web의 `img` 처럼 직접 만든 이미지를 넣습니다. 이미지가 아닌 위젯 · 컴포넌트도 넣을 수 있습니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
CardImage(
  image: AspectRatioBox(
    ratio: 16 / 9,
    child: Image.asset(
      'assets/mountain.jpg',
      fit: BoxFit.cover,
      semanticLabel: '해가 뜨는 산',
    ),
  ),
  title: const Text('산 풍경'),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
CardImage(
  image: AspectRatioBox(
    ratio: 16 / 9,
    child: img(
      src: '/images/mountain.jpg',
      alt: '해가 뜨는 산',
      styles: Styles(raw: {'object-fit': 'cover'}),
    ),
  ),
  title: Text('산 풍경'),
  css: Styles(raw: {'width': '100%'}),
)
```

  </TabItem>
</Tabs>

### 비율과 크기

`CardImage` 에는 크기 단계나 이미지 비율 파라미터가 없습니다. 이미지의 크기는 넣은 이미지와 카드의 폭에 따라 정해집니다. 카드의 폭은 [카드의 너비](#카드의-너비)를 봅니다.

- **비율 정하기** — 세로 배치에서는 [AspectRatioBox](/components/aspect-ratio-box)로 감쌉니다. 두 플랫폼에서 `ratio` 와 `child` 를 같게 씁니다. 비율에 맞춰 이미지를 채우려면 Flutter는 `fit: BoxFit.cover`, Web은 `object-fit: cover` 를 줍니다.
- **Flutter의 이미지 폭** — 세로 배치는 이미지 슬롯의 폭을 카드 안쪽 폭으로 고정합니다. 이미지에 다른 `width` 를 주어도 카드 폭을 따릅니다.
- **Web의 이미지 폭** — 이미지는 자기 CSS 폭을 지킵니다. 카드보다 좁으면 남는 자리에 이미지 칸의 바탕이 보입니다.
- **자리 잡아 두기** — 크기를 정하지 않은 네트워크 이미지는 불러오기 전과 후의 높이가 다를 수 있습니다. 비율이나 높이를 정해 두면 카드 높이가 흔들리지 않습니다.

<Preview demo="card-image/image-ratios" />

### 불러오는 중과 실패

`CardImage` 에는 불러오는 중 · 실패 상태와 대체 이미지를 받는 파라미터가 없습니다. 두 경우는 `image` 에 넣는 쪽에서 처리합니다. 아래 미리보기는 자리 표시 모양을 직접 만들어 슬롯에 넣은 예입니다.

<Preview demo="card-image/placeholders" />

Flutter의 네트워크 이미지는 `loadingBuilder` 와 `errorBuilder` 로 대신 보일 위젯을 정합니다. `loadingPlaceholder` · `failedPlaceholder` 는 직접 만드는 위젯입니다.

```dart
Image.network(
  photoUrl,
  fit: BoxFit.cover,
  semanticLabel: '해가 뜨는 산',
  loadingBuilder: (context, child, progress) =>
      progress == null ? child : loadingPlaceholder,
  errorBuilder: (context, error, stackTrace) => failedPlaceholder,
)
```

Web은 `img` 의 `events` 로 `load` · `error` 이벤트를 받고, 상태를 가진 컴포넌트에서 슬롯에 넣는 내용을 바꿉니다.

### 이미지 위에 얹는 내용

`CardImage` 에는 이미지 위에 얹는 전용 슬롯이 없습니다. `image` 슬롯 안에서 겹쳐 그린 라벨이나 배지는 이미지의 일부가 됩니다. hover 확대와 비활성의 흐림이 함께 적용되고, 확대한 부분은 이미지 칸에서 잘립니다. 확대와 따로 놓아야 하면 [Card](/components/card)의 `media` 와 `overlay` 슬롯을 씁니다.

<a id="동작-스펙-behavior"></a>

## 상태

카드가 컨트롤인지는 `onPressed` 가 정합니다. 활성 여부는 `enabled ?? (onPressed != null)` 이고, `onPressed` 가 없으면 `enabled: true` 를 주어도 누를 수 없습니다.

<Preview demo="card-image/states" />

| 상태 | 조건 | 동작과 모습 |
| --- | --- | --- |
| 누를 수 있음 | `onPressed` 를 주고 `enabled` 를 생략하거나 `true` | 클릭 · 탭 · `Enter` · `Space` 로 `onPressed` 를 실행합니다. |
| 비활성 | `onPressed` 를 주고 `enabled: false` | `onPressed` 를 실행하지 않습니다. 이미지와 글 줄을 `disabledContentOpacity`(기본 `CoreOpacity.disabled`, 40%)로 흐리게 그리고 상자의 그림자를 거둡니다(`disabledContainerStyle`). 상자의 바탕과 테두리는 그대로입니다. |
| 표시용 | `onPressed` 없음 | 컨트롤이 아닙니다. `enabled` 값은 겉모습도 역할도 바꾸지 않습니다. |

### Hover 확대

마우스를 올리면 이미지 칸 안의 이미지가 `normalScale`(기본 1)에서 `hoverScale`(기본 1.05)로 커집니다. `hoverDuration`(기본 150ms, `CoreDuration.fast`) 동안 `CoreEasing.move` 곡선으로 바뀌고, 커진 부분은 이미지 칸에서 잘립니다. 상자와 글 줄의 크기는 그대로입니다.

- Flutter는 **누를 수 있는 카드만** 확대합니다. 비활성 카드와 표시용 카드는 확대하지 않습니다.
- Web은 **모든 카드**를 확대합니다. 비활성 카드와 표시용 카드도 포함합니다.
- 확대를 끄려면 `hoverScale` 을 `normalScale` 과 같게 줍니다(기본값에서는 `hoverScale: 1`).
- 동작 줄이기를 켜면 두 플랫폼 모두 기본 전환 시간이 사라져 크기가 바로 바뀝니다. 확대 자체는 남습니다.

### 누르는 동안

Flutter의 누를 수 있는 카드는 누르고 있는 동안 카드 전체가 기본 95%로 줄어듭니다. Web 카드에는 누름 반응이 없습니다. hover 와 누름에서 두 플랫폼 모두 카드 상자의 바탕과 테두리 색은 바꾸지 않습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 갤러리 · 상품 · 기사처럼 썸네일과 제목 · 부제를 한 카드로 보여줄 때
- 카드 전체를 눌러 상세 내용을 여는 블록이 필요할 때 (`onPressed`)
- 이미지와 글을 세로 또는 가로로 나란히 둘 때 (`direction`)

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| `media` · `header` · `body` · `footer` 를 자유롭게 채우거나 이미지 위에 요소를 얹을 때 | [Card](/components/card) |
| 얼굴 사진이나 이니셜만 보여줄 때 | [Avatar](/components/avatar) |
| 라벨과 값으로 된 정보를 나열할 때 | [DescriptionCard](/components/description-card) |
| 포인터 위치에 따라 여러 이미지를 바꿔 보여줄 때 | [HoverGallery](/components/hover-gallery) |
| 글 없이 이미지의 비율만 맞출 때 | [AspectRatioBox](/components/aspect-ratio-box) |

### 누르는 카드 만들기

카드를 누를 수 있게 하려면 `onPressed` 를 넘깁니다. `onPressed` 가 있어야 카드가 버튼으로 동작합니다.

```dart
CardImage(
  image: thumbnail,
  title: Text('산 풍경'),
  onPressed: openPhoto,
)
```

`CardImage` 에는 `href` 파라미터가 없어 링크가 아니라 버튼입니다. 링크가 필요하면 `onPressed` 없는 카드의 슬롯에 [Link](/components/link)를 둡니다. Web의 `Link` 는 `onPressed` 를 주지 않으면 실제 `<a href>` 가 되어, 새 탭으로 열기 같은 브라우저의 링크 동작을 그대로 쓸 수 있습니다. Flutter의 `Link` 는 주소를 직접 열지 않으므로 `onPressed` 에서 이동합니다.

<a id="do"></a>
<a id="dont"></a>

<Cards columns="2">
<Card demo="card-image/do-action" tone="do" eyebrow="이렇게 하세요">

카드 하나에는 동작 하나를 두고, 눌렀을 때 일어나는 일을 제목과 부제로 알립니다.

</Card>
<Card demo="card-image/dont-inner-button" tone="dont" eyebrow="이렇게 하지 마세요">

누를 수 있는 카드의 `trailing` 에 버튼을 넣지 않습니다. 컨트롤이 겹치고, Web에서는 안쪽 버튼에서 `Enter` 를 눌러도 카드의 `onPressed` 가 실행됩니다.

</Card>
<Card demo="card-image/do-disabled" tone="do" eyebrow="이렇게 하세요">

비활성 카드는 `onPressed` 를 그대로 두고 `enabled: false` 를 줍니다.

</Card>
<Card demo="card-image/dont-disabled" tone="dont" eyebrow="이렇게 하지 마세요">

`onPressed` 없이 `enabled: false` 만 주면 표시용 카드와 똑같이 보이고 읽힙니다. 쓸 수 없는 상태라는 것이 전달되지 않습니다.

</Card>
</Cards>

## 배치

### 세로와 가로

`cardImageStyle` 의 `direction` 으로 고릅니다. 기본값 `CoreAxis.vertical` 은 이미지를 위에, `CoreAxis.horizontal` 은 이미지를 글 앞쪽 옆에 둡니다.

<Preview demo="card-image/horizontal" />

가로 배치에서는 이미지에 너비와 높이를 정해 넣습니다. 기본값은 방향에 따라 바뀌지 않으므로 다음 두 가지가 보입니다. 미리보기의 첫째 카드가 기본값이고, 둘째 카드가 아래 코드로 바꾼 것입니다.

- 카드 상자의 아래 여백 14 가 남아 이미지 아래에 빈 띠가 생깁니다.
- 글 줄에는 위 여백이 없어 글이 카드 위쪽에 붙습니다.

```dart
const CoreCardImageStyle(
  direction: CoreAxis.horizontal,
  containerStyle: CoreOutlinedContainerStyle(padding: CoreEdgeInsets.zero),
  contentStyle: CoreBasicStyle(
    padding: CoreEdgeInsets.directional(
      start: CoreSpace.space14,
      top: CoreSpace.space14,
      end: CoreSpace.space10,
    ),
  ),
)
```

<Note>

Flutter의 가로 카드는 받은 높이를 모두 채우므로, 높이를 제한하지 않는 부모(`Column`, 세로 스크롤)에 그대로 두면 레이아웃 오류가 납니다. `IntrinsicHeight` 로 감싸 내용 높이에 맞추거나 높이를 정해 줍니다. 또 Flutter 가로 카드의 글은 줄바꿈되지 않아, 카드가 쓸 수 있는 폭보다 길면 넘칩니다. Flutter에서 쓰는 가로 카드에는 짧은 글을 씁니다.

</Note>

### 카드의 너비

`CardImage` 에는 너비 파라미터가 없습니다. 세로 카드의 폭은 플랫폼마다 다르게 정해집니다.

| 플랫폼 | 폭 | 정하는 방법 |
| --- | --- | --- |
| Flutter | 부모가 허용하는 폭을 모두 채웁니다. 폭을 제한하지 않는 부모(`Row` 등)에서는 레이아웃 오류가 납니다. | `SizedBox` 의 `width` 나 `Expanded` 로 폭을 정합니다. |
| Web | 내용의 폭을 따릅니다(`w-fit`). 폭이 고정된 이미지가 부모보다 넓으면 카드도 부모를 넘을 수 있습니다. | 부모의 폭을 채우려면 `css: Styles(raw: {'width': '100%'})` 를 줍니다. |

Web에서 `AspectRatioBox` 처럼 자기 폭이 없는 이미지를 넣을 때는 카드의 폭을 `css` 로 정하세요. 그러지 않으면 카드 폭이 글의 폭을 따라가고 이미지도 그 폭으로 그려집니다. 세로 카드의 긴 글은 두 플랫폼 모두 카드 폭 안에서 줄바꿈됩니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

내용과 동작은 위젯 파라미터로 넘깁니다(`image` · `title` · `subtitle` · `leading` · `trailing` · `onPressed` · `enabled`). 겉모습, 배치 방향, hover 확대는 `cardImageStyle`(`CoreCardImageStyle`) 하나로 덮어씁니다.

<Preview demo="card-image/styled" />

### 값이 정해지는 순서

```text
CoreCardImageStyle 의 기본값                  // defaultContainerStyle, defaultFrameStyle, defaultContentStyle …
  → CoreCardImageTheme.style                  // 앱 전체
  → cardImageStyle                            // 인스턴스별
  → 비활성일 때만: defaultDisabledContainerStyle 에 disabledContainerStyle 을 합친 값을 상자 위에 얹음
```

- 같은 값은 뒤가 이깁니다. `containerStyle` · `frameStyle` · `contentStyle` · `imageContentGapStyle` 은 안의 필드 단위로 합쳐집니다. `padding` 같은 필드 하나는 통째로 바뀝니다.
- 합친 값은 각각 `OutlinedContainer`, `Basic`, `Gap` 에 그 인스턴스의 스타일로 넘어갑니다. 그래서 카드 기본값이 정한 필드는 앱의 `outlinedContainer` · `basic` · `gap` 테마보다 우선하고, 정하지 않은 필드는 그 테마를 따릅니다. 예를 들어 카드 상자의 바탕 · 테두리 · 모서리는 `outlinedContainer` 테마의 영향을 받습니다.
- 카드 상자의 그림자는 `boxShadow` 로 바꿉니다. 기본값이 `boxShadow` 를 정하고 있어 `containerStyle` 의 `elevation` 만 주면 달라지지 않습니다. 그림자를 없애려면 `boxShadow: CoreShadow.none` 을 줍니다.
- 카드 상자의 모서리는 `containerStyle.borderRadius` 입니다. `frameStyle.borderRadius` 는 안쪽 이미지 칸의 모서리입니다.

### 테마

한 카드만 바꿀 때는 `cardImageStyle`, 앱 전체의 기본값은 `CoreCardImageTheme` 으로 덮어씁니다. 두 예제 모두 Flutter와 Web 코드가 같습니다.

<Split>

<Code language="dart" title="카드 하나만 바꾸기">
CardImage(
  image: thumbnail,
  title: Text('산 풍경'),
  cardImageStyle: CoreCardImageStyle(
    containerStyle: CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      boxShadow: CoreShadow.none,
    ),
    imageContentGapStyle: CoreGapStyle(size: CoreSpace.space8),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    cardImage: CoreCardImageTheme(
      style: CoreCardImageStyle(
        direction: CoreAxis.horizontal,
        hoverScale: 1.1,
        imageContentGapStyle: CoreGapStyle(size: CoreSpace.space16),
      ),
    ),
  ),
)
</Code>

</Split>

앱 전체의 `direction` 을 가로로 바꾸면 모든 카드에 [배치](#배치)의 가로 조건이 적용됩니다.

### 슬롯의 글 스타일

`title` · `subtitle` 에 아무 체인도 붙이지 않은 `Text` 를 넣으면 카드의 글자 스타일이 적용됩니다. Flutter에서 `.labelMedium` 처럼 글자 역할을 고르는 체인을 붙인 `Text` 는 카드의 글자 스타일을 이어받지 않고, 기본 글자 모양과 색에서 다시 시작합니다. 카드 안의 글자 스타일은 `contentStyle` 의 `titleTextStyle` · `subtitleTextStyle` 로 바꿉니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

이미 만든 `CardImage` 에 `withStyle` 을 이어 `cardImageStyle` 을 덧붙일 수 있습니다. 생성자의 `cardImageStyle` 인자와 같게 동작하고, 나중에 이은 `withStyle` 이 같은 필드에서 이깁니다. `.radius4` 처럼 Core 토큰 상수와 이름이 같은 getter 도 있습니다 — `withStyle` 을 한 번 더 줄인 것으로, 이름이 곧 값입니다(`radius4` 는 `CoreRadius.radius4`).

이 getter 들은 카드 상자가 아니라 **이미지 칸**(`frameStyle`)을 바꿉니다. 모서리 getter 는 이미지 칸의 모서리를, 색 getter 는 이미지 칸의 바탕을 바꿉니다. 바탕색은 이미지가 칸을 덮지 않거나 투명한 곳에만 보입니다. 아래 예제의 이미지 주소는 예시이므로 직접 쓰는 이미지로 바꿔 넣으세요.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class CardImageChainExample extends StatelessWidget {
  const CardImageChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        SizedBox(
          width: 240,
          child: CardImage(
            image: Image.network(
              'https://picsum.photos/seed/coui/240/160',
              width: 240,
              height: 160,
              fit: BoxFit.cover,
            ),
            title: const Text('산 풍경'),
            subtitle: const Text('해 뜰 무렵 촬영'),
            onPressed: () {},
          ).radius16.primary,
        ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(frameStyle.borderColor)
        // 까지 한 번에.
        SizedBox(
          width: 240,
          child:
              CardImage(
                image: Image.network(
                  'https://picsum.photos/seed/coui/240/160',
                  width: 240,
                  height: 160,
                  fit: BoxFit.cover,
                ),
                title: const Text('산 풍경'),
                subtitle: const Text('해 뜰 무렵 촬영'),
                onPressed: () {},
              ).withStyle(
                const CoreCardImageStyle(
                  frameStyle: CoreOutlinedContainerStyle(
                    backgroundColor: CoreColor.token(
                      CoreColors.tertiaryContainer,
                    ),
                    borderColor: CoreColor.token(CoreColors.tertiary),
                    borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
                  ),
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
class CardImageChainExample extends StatelessComponent {
  const CardImageChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        div(
          [
            CardImage(
              image: img(
                src: 'https://picsum.photos/seed/coui/240/160',
                classes: 'block object-cover',
                styles: Styles(
                  raw: const {
                    'width': '240px',
                    'height': '160px',
                    'margin': '0',
                  },
                ),
              ),
              title: Text('산 풍경'),
              subtitle: Text('해 뜰 무렵 촬영'),
              onPressed: () {},
            ).radius16.primary,
          ],
          styles: Styles(raw: const {'width': '240px'}),
        ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(frameStyle.borderColor)
        // 까지 한 번에.
        div(
          [
            CardImage(
              image: img(
                src: 'https://picsum.photos/seed/coui/240/160',
                classes: 'block object-cover',
                styles: Styles(
                  raw: const {
                    'width': '240px',
                    'height': '160px',
                    'margin': '0',
                  },
                ),
              ),
              title: Text('산 풍경'),
              subtitle: Text('해 뜰 무렵 촬영'),
              onPressed: () {},
            ).withStyle(
              const CoreCardImageStyle(
                frameStyle: CoreOutlinedContainerStyle(
                  backgroundColor: CoreColor.token(
                    CoreColors.tertiaryContainer,
                  ),
                  borderColor: CoreColor.token(CoreColors.tertiary),
                  borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
                ),
              ),
            ),
          ],
          styles: Styles(raw: const {'width': '240px'}),
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

<a id="접근성-accessibility"></a>

## 접근성

### 역할

카드가 컨트롤인지는 `onPressed` 와 `enabled` 로 갈리고, 그 판정은 두 플랫폼이 같습니다.

| 조건 | Flutter | Web 루트 `<div>` |
| --- | --- | --- |
| `onPressed` 있음 · 활성 | `Button(variant: CoreButtonVariant.fixed)` 으로 감싸 `Semantics(button: true, enabled: true)` 가 붙습니다. | `role="button"` · `tabindex="0"` |
| `onPressed` 있음 · `enabled: false` | 같은 버튼이 `Semantics(enabled: false)` 로 알려집니다. | `role="button"` · `aria-disabled="true"`, `tabindex` 를 붙이지 않습니다. |
| `onPressed` 없음 | 버튼으로 감싸지 않은 일반 콘텐츠입니다. | 역할을 붙이지 않습니다. 직접 `attributes` 로 넣은 것만 남습니다. |

- Web에서 `onPressed` 가 있는 카드의 `role` 과 활성 카드의 `tabindex` 는 `attributes` 에 같은 이름을 넣어도 컴포넌트의 값이 적용됩니다.
- 링크 역할은 없습니다. `onPressed` 로 화면을 이동해도 보조 기술에는 버튼으로 전달됩니다.

### 키보드

| 키 | Flutter | Web |
| --- | --- | --- |
| `Tab` | 누를 수 있는 카드는 탭 순서의 한 자리입니다. | 같습니다(`tabindex="0"`). |
| `Enter` · `Space` | `onPressed` 를 실행합니다. | 루트의 `keydown` 에서 키의 기본 동작을 막고 `onPressed` 를 실행합니다. |
| 화살표 | 카드가 따로 처리하지 않습니다. | 카드가 따로 처리하지 않습니다. |

비활성 카드와 표시용 카드에는 키보드 활성화가 없습니다.

### 스크린 리더

카드의 이름을 받는 파라미터는 없습니다.

- **Web의 버튼 이름** — `role="button"` 요소는 안의 내용으로 이름을 만듭니다. `leading` · `title` · `subtitle` · `trailing` 의 글과 이미지의 `alt` 가 이름에 들어가므로, 같은 말을 두 곳에 적으면 두 번 읽힐 수 있습니다. 이름을 직접 정하려면 `attributes: {'aria-label': '산 풍경 사진 열기'}` 를 넘깁니다. 화면에 보이는 제목은 이름에 그대로 포함합니다.
- **Flutter의 버튼 이름** — 카드는 `label` 을 설정하지 않고, 슬롯의 글을 버튼과 나누는 설정도 하지 않습니다. 그래서 글은 Flutter의 기본 시맨틱 병합에 따라 버튼의 이름으로 합쳐집니다. `semanticLabel` 을 준 `Image` 는 따로 된 노드가 되어 이 이름에 합쳐지지 않습니다. 아이콘이나 이미지를 함께 넣은 카드가 실제로 어떻게 읽히는지는 대상 기기의 화면 낭독기로 확인합니다.
- **표시용 카드** — 두 플랫폼 모두 카드에 버튼 역할이 없고, 슬롯의 글과 이미지의 설명이 일반 콘텐츠로 남습니다. Web 루트는 역할 없는 `<div>` 라서 `aria-label` 만으로는 이름이 읽히지 않을 수 있습니다.
- **비활성** — Flutter는 `Semantics(enabled: false)`, Web은 `aria-disabled="true"` 로 지금 쓸 수 없는 버튼임을 알립니다.
- 기본 화살표에는 따로 붙는 이름이 없습니다. 상태 변화를 알리는 라이브 영역은 없습니다.

#### 이미지의 대체 텍스트

`CardImage` 는 대체 텍스트를 받지 않으므로 `image` 에 넣는 쪽에서 정합니다.

| 이미지 | Flutter | Web |
| --- | --- | --- |
| 정보가 있는 이미지 | `Image` 의 `semanticLabel`. 이 값을 주면 이미지가 자기 시맨틱 노드를 가집니다. | `img` 의 `alt` |
| 장식 이미지 | `excludeFromSemantics: true` | `alt: ''` |
| 이미지 요소가 아닌 그림 | `Semantics(label: ..., image: true)` 로 감쌉니다. | `attributes` 에 `role="img"` 와 `aria-label` 을 줍니다. |

<Preview demo="card-image/a11y-name" />

위 카드의 그림은 이미지 요소가 아니라서, Flutter는 `Semantics` 로, Web은 `role="img"` 와 `aria-label` 로 "해가 뜨는 산" 이라는 설명을 붙였습니다.

### 포커스 관리

- 카드는 마운트될 때 포커스를 옮기지 않고, 포커스를 가두지 않습니다.
- Flutter의 누를 수 있는 카드는 키보드로 포커스를 받으면 CoUI 포커스 링을 그립니다. 비활성 카드는 탭 순서에서 빠지고, 표시용 카드는 포커스 대상이 아닙니다.
- Web의 누를 수 있는 카드는 `tabindex="0"` 으로 탭 순서에 들어갑니다. 컴포넌트가 그리는 링은 없고 브라우저의 기본 outline 에 맡깁니다. 비활성 카드에는 `tabindex` 가 붙지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 카드의 이름 · 이미지의 대체 텍스트 · 링크 주소를 받는 전용 파라미터가 없습니다. |
| 공통 | 기본 화살표를 끄는 파라미터가 없고, 표시용 카드에도 그려집니다. |
| 공통 | 불러오는 중 · 실패 상태가 없습니다. |
| 공통 | hover 확대와 누르는 동안의 크기 변화는 눈에 보이는 표현일 뿐, 보조 기술에 전달되지 않습니다. |
| Web | 비활성 카드와 표시용 카드도 hover 하면 이미지가 커집니다. 눌리지 않는데도 반응하는 것처럼 보일 수 있습니다. |
| Web | 누를 수 있는 카드 안의 버튼 · 링크에서 `Enter` · `Space` 를 누르면 그 `keydown` 이 카드까지 전달됩니다. 카드는 키의 기본 동작을 막고 자기 `onPressed` 를 실행합니다. 안쪽 버튼 · 링크의 클릭도 전파를 막지 않으면 카드의 `onPressed` 까지 실행합니다. |
| Web | 누를 수 있는 활성 카드에는 직접 넘긴 `onClick` · `onKeyDown`(`eventHandlers` 의 `click` · `keydown` 포함)이 연결되지 않습니다. 누름은 `onPressed` 로 받습니다. |
| Web | `onMouseEnter` · `onMouseLeave`(`eventHandlers` 의 `mouseenter` · `mouseleave` 포함)는 어느 카드에서도 호출되지 않습니다. |
| Web | `aria-disabled="true"` 는 안내만 합니다. 비활성 카드나 표시용 카드에 직접 넘긴 `onClick` 은 실행됩니다. |
| Web | `onInput` · `onChange` 는 넘겨도 불리지 않습니다. 이벤트 값이 문자열일 때만 부르게 되어 있는데, 브라우저는 이벤트 객체를 넘깁니다. |
| Web | 포커스 표시는 브라우저 기본 outline 이고, 이를 바꾸는 `cardImageStyle` 필드가 없습니다. |
| Flutter | 포커스 링의 모서리는 카드 상자의 모서리(기본 16)를 따르지 않고, 감싸는 `Button` 의 모서리(`md` 크기, 기본 10)를 기준으로 합니다. `containerStyle.borderRadius` 를 바꿔도 링은 따라가지 않습니다. |
| Flutter | 가로 배치의 글은 줄바꿈되지 않아 폭이 모자라면 넘칩니다. 가로 배치는 높이가 제한된 부모가, 세로 배치는 폭이 제한된 부모가 필요합니다. |
| Flutter | 글 슬롯을 하나도 주지 않아도 간격과 화살표 줄을 그립니다. |

모션 감소 · 고대비 · 최소 터치 타깃처럼 모든 컴포넌트에 공통으로 적용되는 내용은 [전역 접근성 축](/accessibility)에 정리되어 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`image` · `title` · `subtitle` · `leading` · `trailing` · `onPressed` · `enabled` · `cardImageStyle` 은 두 플랫폼이 같은 API 입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 슬롯 타입 | `Widget` / `Widget?` | `Component` / `Component?` |
| 누를 수 있는 카드 | `Button(variant: CoreButtonVariant.fixed)` | 루트 `<div>` 의 `role="button"` · `click` · `keydown` |
| 세로 카드의 폭 | 부모가 허용하는 폭을 채웁니다. | 내용의 폭(`w-fit`)을 따릅니다. |
| 세로 배치의 이미지 폭 | 카드 안쪽 폭으로 고정합니다. | 이미지의 CSS 폭을 지킵니다. |
| 가로 배치의 높이 | 받은 높이를 채웁니다. 이미지 칸과 글 줄이 그 높이로 늘어나, 제목 · 부제는 위쪽에 남고 `leading` · `trailing` 은 글 줄의 세로 가운데에 옵니다. | 내용 높이를 따릅니다. 이미지와 글 줄은 위쪽에서 시작해 자기 높이를 지킵니다. |
| 가로 배치의 긴 글 | 줄바꿈되지 않고 넘칩니다. | 줄바꿈됩니다. |
| 글 슬롯이 하나도 없을 때 | 이미지 아래에 간격과 화살표 줄을 그립니다. | 간격과 글 줄을 그리지 않습니다. 상자의 아래 여백 14 는 남습니다. |
| hover 확대 | 누를 수 있는 카드만 | 모든 카드 |
| 누르는 동안 | 카드가 기본 95%로 줄어듭니다. | 변화가 없습니다. |
| 비활성 카드 안의 색을 정하지 않은 아이콘 | 감싼 `Button` 의 비활성 색(`disabledContent`)으로 바뀌고 흐림도 적용됩니다. 기본 화살표는 자기 색을 지킵니다. | 색은 바뀌지 않고 흐림만 적용됩니다. |
| 커서 | 누를 수 있으면 클릭 커서, 비활성이면 금지 커서 | 누를 수 있을 때만 `cursor-pointer` 를 붙입니다. |
| 포커스 표시 | CoUI 포커스 링 | 브라우저 기본 outline |
| 글 선택 | 누를 수 있는 카드(비활성 포함)의 글은 선택 대상에서 빠집니다. 표시용 카드는 선택을 막지 않습니다. | 모든 카드의 루트에 `select-none` 이 붙습니다. |
| 크기 배율 | 간격과 모서리에 `theme.scaling` 을 곱합니다. | `rem` 이 브라우저 글자 배율에 반응합니다. |
| HTML 속성과 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · 이벤트 파라미터가 있습니다. |

<a id="props-parameters"></a>

## API

표의 `W` 는 Flutter의 `Widget`, Web의 Jaspr `Component` 입니다. 겉모습을 바꾸는 값은 `cardImageStyle` 안에 있습니다.

### 내용 슬롯

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `image` | `W` | 필수 | 대표 이미지 |
| `title` | `W?` | `null` | 제목 |
| `subtitle` | `W?` | `null` | 제목 아래 부제 |
| `leading` | `W?` | `null` | 글 앞 슬롯 (아이콘 등) |
| `trailing` | `W?` | `null` | 글 뒤 슬롯. `null` 이면 오른쪽 화살표를 그립니다. |

### 동작과 모습

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `onPressed` | `CoreVoidCallback?` | `null` | 누름 콜백. 주면 카드 전체가 버튼이 됩니다. |
| `enabled` | `bool?` | `null` | `null` 이면 `onPressed != null` 을 따릅니다. `false` 는 `onPressed` 가 있는 카드를 비활성으로 만듭니다. |
| `cardImageStyle` | `CoreCardImageStyle?` | `null` | 겉모습 · 배치 방향 · hover 확대를 바꾸는 값 묶음. 아래 `CoreCardImageStyle` 표를 봅니다. |

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트 `<div>` 의 id |
| `classes` | `String?` | `null` | 루트에 더하는 클래스 |
| `css` | `Styles?` | `null` | 루트의 인라인 스타일. 폭 같은 배치에 씁니다. |
| `attributes` | `Map<String, String>?` | `null` | 루트의 HTML 속성. `role` · `tabindex` 의 우선순위는 접근성의 역할을 봅니다. |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 루트의 이벤트. `click` · `keydown` · `mouseenter` · `mouseleave` 의 제약은 접근성의 알려진 제약을 봅니다. 슬롯에서 올라오는 `input` · `change` 는 여기로 받습니다. |
| `onClick` | `UiMouseEventHandler?` | `null` | 누를 수 있는 활성 카드에서는 연결되지 않습니다. |
| `onKeyDown` | `UiKeyboardEventHandler?` | `null` | 누를 수 있는 활성 카드에서는 연결되지 않습니다. |
| `onKeyUp` | `UiKeyboardEventHandler?` | `null` | 루트의 `keyup` |
| `onMouseEnter` | `UiMouseEventHandler?` | `null` | 호출되지 않습니다. |
| `onMouseLeave` | `UiMouseEventHandler?` | `null` | 호출되지 않습니다. |
| `onInput` | `UiInputEventHandler?` | `null` | 넘겨도 불리지 않습니다. `input` 은 `eventHandlers` 로 받습니다. |
| `onChange` | `UiInputEventHandler?` | `null` | 넘겨도 불리지 않습니다. `change` 는 `eventHandlers` 로 받습니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreCardImageStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `containerStyle` | `CoreOutlinedContainerStyle?` | Style for the card's own box — the `OutlinedContainer` that holds the image and the text and draws the card's fill, border, corners and clip. Laid over [defaultContainerStyle] and passed as is to `OutlinedContainer(containerStyle: …)`; anything neither states is the container's own default. |
| `disabledContainerStyle` | `CoreOutlinedContainerStyle?` | What the card's box changes while the card is disabled — a pressable card (`onPressed` set) with `enabled: false`. By default it drops the cast. Laid over [defaultDisabledContainerStyle], and what it states wins over [containerStyle] while disabled. |
| `frameStyle` | `CoreOutlinedContainerStyle?` | Style for the frame around the image — the `OutlinedContainer` that draws its fill, border, corners and shadow. Laid over [defaultFrameStyle] and passed as is to `OutlinedContainer(containerStyle: …)`. |
| `contentStyle` | `CoreBasicStyle?` | Style for the text row under the image — the `Basic` that lays out `leading`, `title`, `subtitle` and `trailing`. Laid over [defaultContentStyle] and passed as is to `Basic(basicStyle: …)`; anything neither states is `Basic`'s own default. |
| `disabledContentOpacity` | `double?` | Opacity of the image and the text row while the card is disabled — a pressable card (`onPressed` set) with `enabled: false`. The card's own box, border and fill stay at full strength. `null` defers to [defaultDisabledContentOpacity]. |
| `imageContentGapStyle` | `CoreGapStyle?` | Space between the image and the text. Laid over [defaultImageContentGapStyle] and passed as is to `Gap(gapStyle: …)`. |
| `hoverScale` | `double?` | Image scale factor when the card is hovered. |
| `normalScale` | `double?` | Image scale factor when the card is idle. |
| `hoverDuration` | `Duration?` | Hover scale transition duration override. `null` defers to [defaultHoverDuration]. |
| `direction` | `CoreAxis?` | Layout direction of the image relative to the text slot. |

<!-- STYLE_TABLE:END -->

<Note>

`direction: CoreAxis.horizontal` 에서는 `contentStyle` 이 꾸미는 글 줄이 이미지 아래가 아니라 옆에 놓입니다. `hoverScale` 이 적용되는 카드는 플랫폼마다 다릅니다([Hover 확대](#hover-확대)). `normalScale` 은 두 플랫폼의 모든 카드에서 평소 크기로 쓰입니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="card-image/related-card" title="Card">

`media` · `header` · `body` · `footer` 슬롯을 자유롭게 채우는 카드입니다. [Card 문서](/components/card)

</Card>
<Card demo="card-image/related-aspect-ratio-box" title="AspectRatioBox">

정한 가로세로 비율의 상자입니다. `image` 슬롯의 비율을 정할 때 씁니다. [AspectRatioBox 문서](/components/aspect-ratio-box)

</Card>
<Card demo="card-image/related-description-card" title="DescriptionCard">

라벨과 값으로 된 정보를 나열하는 카드입니다. [DescriptionCard 문서](/components/description-card)

</Card>
<Card demo="card-image/related-avatar" title="Avatar">

얼굴 사진이나 이니셜을 보여주는 컴포넌트입니다. [Avatar 문서](/components/avatar)

</Card>
</Cards>
