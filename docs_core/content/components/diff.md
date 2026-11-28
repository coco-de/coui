---
title: Diff
description: 두 콘텐츠를 한 프레임에 겹쳐 놓고, 분할선을 좌우로 옮기며 비교합니다.
category: display
platforms: [flutter, web]
related: [code-diff, carousel, hover-gallery]
tags: [comparison, before-after, slider]
template: v2
source: display/diff
---

# Diff

<a id="live-preview"></a>

## 플레이그라운드

속성을 바꾼 뒤 미리보기의 손잡이를 끌거나 프레임을 눌러 보세요. `조작 끄기`를 켜면 분할선이 움직이지 않습니다.

<Playground component="diff" />

코드의 `originalPhoto` · `editedPhoto`는 비교할 두 콘텐츠를 넣는 자리의 이름입니다. 코드를 복사한 뒤 이 두 자리에 실제 콘텐츠를 넣습니다. 미리보기의 풍경은 문서에서 색 토큰으로 그린 그림입니다. `initialPosition`을 바꾸면 문서가 미리보기를 새로 만들어 그 위치에서 시작합니다.

## 구조

프레임 하나에 두 층을 겹칩니다. 분할선 왼쪽에는 `before`, 오른쪽에는 `after`가 보입니다. 두 콘텐츠의 차이를 계산하지 않고, 위에 놓은 `before` 층을 분할 위치까지만 보이도록 잘라 냅니다.

<Anatomy demo="diff/anatomy">
<AnatomyItem part="container" name="Frame">

두 콘텐츠를 담는 상자입니다. 폭을 채우고 `aspectRatio`(기본 16:9)로 높이를 정하며, 모서리는 16입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=diff-before]" side="top" name="before">

분할선 왼쪽에 보이는 콘텐츠입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=diff-after]" side="top" name="after">

분할선 오른쪽에 보이는 콘텐츠입니다. 프레임 전체에 깔리고 그 위에 `before`가 놓입니다.

</AnatomyItem>
<AnatomyItem select=".coui-diff-handle-strip" side="top" name="분할선">

두 콘텐츠의 경계를 보이는 폭 2의 선입니다. 조작할 수 있을 때는 이 선을 따라 손잡이를 잡는 영역이 놓입니다.

</AnatomyItem>
<AnatomyItem select=".coui-diff-handle-disc" side="right" name="손잡이">

분할선 가운데의 지름 40 원입니다. 좌우 화살표 아이콘이 들어가며 아이콘 모양을 바꾸는 속성은 없습니다. `interactive: false`면 그리지 않습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=diff-label]" side="top" name="beforeLabel · afterLabel">

프레임 위쪽 두 모서리의 이름표입니다. 넘긴 콘텐츠를 작은(`sm`) [Badge](/components/badge)로 감싸 모서리에서 12만큼 안쪽에 그립니다. 넘기지 않으면 그리지 않습니다.

</AnatomyItem>
</Anatomy>

### 프레임의 가장자리

프레임 둘레에는 `outlineSubtle` 색의 폭 1 선이 안쪽에 그려집니다. 프레임 크기는 그대로이고 콘텐츠의 가장자리를 그만큼 덮습니다. 비교하는 그림이 페이지 바탕과 같은 색이어도 경계를 알 수 있도록 둔 선입니다. `diffStyle`의 `borderWidth`를 `0`으로 주면 그리지 않습니다.

두 콘텐츠 · 분할선 · 이름표 · 가장자리 선은 프레임의 둥근 모양에 맞춰 잘립니다. 손잡이는 잘리는 층 바깥에 있어, 분할선이 맨 끝에 있어도 프레임 모서리에 잘리지 않습니다.

## 콘텐츠 채우기

`before`와 `after`에는 Flutter의 `Widget`, Web의 Jaspr `Component`를 넣습니다. 사진, 글, 직접 만든 화면을 모두 넣을 수 있습니다. 두 콘텐츠를 같은 크기와 구도로 만들면 분할선에서 자연스럽게 이어집니다.

| 플랫폼 | 콘텐츠 크기 |
| --- | --- |
| Flutter | Diff가 두 콘텐츠를 프레임 크기로 채워 줍니다. |
| Jaspr Web | 콘텐츠를 담는 층만 프레임 크기입니다. 콘텐츠의 가장 바깥 요소에 `w-full h-full`을 줍니다. |

Flutter에서 배경 없는 콘텐츠를 넣을 때는 [인터랙션](#인터랙션)의 누름 조건도 확인합니다.

### 사진 비교

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Diff(
  ariaLabel: '보정 전과 보정 후 사진 비교',
  before: Image.asset('assets/original.jpg', fit: BoxFit.cover),
  after: Image.asset('assets/edited.jpg', fit: BoxFit.cover),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
Diff(
  ariaLabel: '보정 전과 보정 후 사진 비교',
  before: img(src: '/images/original.jpg', alt: '', classes: 'w-full h-full object-cover'),
  after: img(src: '/images/edited.jpg', alt: '', classes: 'w-full h-full object-cover'),
)
```

  </TabItem>
</Tabs>

### 글자 비교

같은 글을 두 면에 같은 자리로 놓으면 색이나 글꼴의 차이를 비교할 수 있습니다. 가운데에는 손잡이가 놓이므로 이 예는 글을 아래쪽에 둡니다.

<Preview demo="diff/content-text" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
final colors = Theme.of(context).colorScheme;

Diff(
  ariaLabel: '채운 배경과 표면 배경 글자 비교',
  before: ColoredBox(
    color: colors.primary.toValue(),
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: CoreSpace.space16),
        child: Text('CoUI').displaySmall.onPrimary,
      ),
    ),
  ),
  after: ColoredBox(
    color: colors.surfaceContainer.toValue(),
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: CoreSpace.space16),
        child: Text('CoUI').displaySmall.onSurface,
      ),
    ),
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
final colors = context.colorScheme;

Diff(
  ariaLabel: '채운 배경과 표면 배경 글자 비교',
  before: div(
    classes: 'w-full h-full flex items-end justify-center bg-${colors.primary}',
    [
      div(
        styles: Styles(raw: {'padding-bottom': 'var(--coui-space-16)'}),
        [Text('CoUI').displaySmall.onPrimary],
      ),
    ],
  ),
  after: div(
    classes: 'w-full h-full flex items-end justify-center bg-${colors.surfaceContainer}',
    [
      div(
        styles: Styles(raw: {'padding-bottom': 'var(--coui-space-16)'}),
        [Text('CoUI').displaySmall.onSurface],
      ),
    ],
  ),
)
```

  </TabItem>
</Tabs>

<a id="동작-스펙-behavior"></a>

## 상태

Diff가 기억하는 값은 분할 위치입니다. 손잡이는 마우스를 올렸는지, 잡고 있는지, 키보드 포커스를 보일지에 따라 모양이 바뀝니다.

### 분할 위치

<Preview demo="diff/positions" />

위치는 `0`~`1`의 비율이며 프레임의 왼쪽 끝이 `0`입니다. 값은 왼쪽에 보이는 `before`의 폭 비율과 같습니다. `0`이면 `after`만, `1`이면 `before`만 보입니다.

- 시작 위치는 `diffStyle`의 `initialPosition`(기본 `0.5`)입니다. `0`~`1`을 벗어난 값은 가까운 끝으로 맞춥니다.
- 위치는 Diff가 스스로 기억합니다. 바깥에서 현재 위치를 정하는 속성은 없습니다.
- 조작으로 위치가 정해지기 전에는 `initialPosition`을 바꾸면 분할선도 따라갑니다. 한 번 옮긴 뒤에는 그 위치가 남으며, `before` · `after`를 바꿔도 시작 위치로 돌아가지 않습니다. 시작 위치에서 다시 시작하려면 `key`를 바꿉니다.
- `onPositionChanged`는 끌기 · 누르기 · 키보드로 위치를 옮길 때 같은 `0`~`1` 값을 전달합니다. 직전에 전달한 값과 같으면 다시 부르지 않습니다.

<Code language="dart" title="Flutter · Web">
Diff(
  key: ValueKey(photoId),
  ariaLabel: '보정 전과 보정 후 사진 비교',
  before: originalPhoto,
  after: editedPhoto,
  onPositionChanged: (position) => saveSplit(position),
)
</Code>

### 인터랙션

손잡이를 중심으로 폭이 `handleHitSize`(기본 44)인 보이지 않는 띠가 프레임 높이 전체에 놓입니다. 이 띠가 분할선을 잡는 영역이라 손잡이를 정확히 겨냥하지 않아도 됩니다.

| 입력 | 동작 |
| --- | --- |
| 마우스로 잡는 영역 끌기 | 분할선이 따라 움직입니다. 잡은 자리와 분할선 사이의 거리를 유지해, 누르는 순간에는 분할선이 포인터 쪽으로 옮겨 가지 않습니다. |
| 마우스로 그 밖을 누르기 | 누른 자리로 옮깁니다. 누른 채 끌면 이어서 움직입니다. |
| 터치 · 펜으로 짧게 누르기 | 누른 자리로 옮깁니다. 잡는 영역 밖을 눌러도 됩니다. |
| 터치 · 펜으로 잡는 영역을 좌우로 끌기 | 분할선이 따라 움직입니다. |
| 터치 · 펜으로 영역 밖에서 끌기 | 분할선은 움직이지 않습니다. 세로로 끌어 페이지를 스크롤할 수 있습니다. |
| 키보드 | [키보드](#키보드) 표를 따릅니다. |

- 마우스 포인터가 잡는 영역 위에 있으면 커서가 좌우 크기 조절 모양으로 바뀝니다.
- 마우스는 주 버튼(보통 왼쪽 버튼)으로만 분할선을 움직입니다.
- 마우스로 끄는 동안에는 포인터가 프레임 밖으로 나가도 이어지며, 위치는 양 끝에서 멈춥니다.
- Flutter에서는 잡는 영역 밖을 누를 때, 누른 자리의 콘텐츠가 누름을 받아야 Diff도 알아차립니다. 사진이나 `ColoredBox`처럼 영역 전체가 누름을 받는 콘텐츠는 어디를 눌러도 됩니다. `after`에 글만 놓고 배경을 두지 않으면, 잡는 영역 밖의 빈 곳을 눌러도 분할선이 옮겨 가지 않을 수 있습니다. 이때는 `after`를 `ColoredBox`로 감쌉니다. Web은 콘텐츠를 담는 층이 누름을 받으므로 빈 곳을 눌러도 옮겨 갑니다.

### 손잡이의 모양

손잡이는 상태에 따라 그림자와 크기가 바뀝니다.

| 상태 | 손잡이 |
| --- | --- |
| 기본 | 그림자 `handleShadow`(기본 `sm`) |
| 마우스 올림 | 잡는 영역에 올리면 그림자가 `handleHoverShadow`(기본 `md`)로 바뀝니다. 올려 두는 입력이 없는 터치 기기에서는 나타나지 않습니다. |
| 잡는 중 | `handlePressedScale`(기본 `0.94`)로 줄고 그림자가 `handlePressedShadow`(기본 `xs`)로 바뀝니다. 터치로 끌 때와 마우스로 프레임을 눌러 분할선을 옮길 때도 같습니다. |
| 키보드 포커스 | 손잡이 둘레에 포커스 링(`focusOutlineStyle`)이 나타납니다. [포커스 관리](#포커스-관리)를 따릅니다. |

크기와 그림자는 `handleTransitionDuration`(기본 150ms)에 걸쳐 바뀝니다. 동작 줄이기 설정에서는 이 시간이 500ms 이하이면 `0`이 됩니다. 분할선이 자리를 옮길 때는 전환 애니메이션이 없습니다.

### 조작 끄기

`interactive: false`면 손잡이와 잡는 영역 없이 분할선만 그립니다. 누르기 · 끌기 · 키보드로 위치가 바뀌지 않고, `Tab` 정지점도 아닙니다(Flutter의 방향 탐색 모드는 [알려진 제약](#알려진-제약)을 봅니다). 흐리게 표시하는 비활성 모양은 없습니다.

<Cards columns="2">
<Card demo="diff/state-interactive" title="interactive: true">

손잡이를 그리고 분할선을 옮길 수 있습니다. 기본값입니다.

</Card>
<Card demo="diff/state-static" title="interactive: false">

분할선만 그립니다. 처음부터 조작을 끈 Diff의 분할선은 `initialPosition`에 머뭅니다.

</Card>
</Cards>

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 보정 전과 후, 라이트와 다크, 두 디자인 시안처럼 같은 구도의 이미지를 비교할 때
- 어느 쪽이 전이고 후인지 이름표로 알려야 할 때
- 같은 글에 적용한 두 글꼴이나 색 토큰을 비교할 때
- 두 콘텐츠를 같은 자리에 겹치고 경계를 옮겨 가며 보여 주고 싶을 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 코드 변경 사항을 줄 단위로 보여 줄 때 | [CodeDiff](/components/code-diff) |
| 셋 이상의 콘텐츠를 차례로 넘겨 볼 때. Diff의 자리는 `before` · `after` 둘뿐입니다. | [Carousel](/components/carousel) |

<a id="do"></a>
<a id="dont"></a>

### 이름과 이름표

`ariaLabel`에는 무엇과 무엇을 비교하는지 적습니다. 기본값이 `null`이라 넘기지 않으면 Diff가 붙이는 접근성 이름이 없습니다. 이름표는 화면에 보이는 표시이므로 이름표를 두어도 `ariaLabel`은 따로 지정합니다.

<Code language="dart" title="Flutter · Web">
Diff(
  ariaLabel: '보정 전과 보정 후 풍경 비교',
  beforeLabel: Text('전'),
  afterLabel: Text('후'),
  before: originalPhoto,
  after: editedPhoto,
)
</Code>

<Cards columns="2">
<Card demo="diff/do-labels" tone="do" eyebrow="이렇게 하세요">

이름표는 한두 단어로 씁니다. 콘텐츠를 가리는 면적이 작습니다.

</Card>
<Card demo="diff/dont-long-labels" tone="dont" eyebrow="이렇게 하지 마세요">

긴 문장을 넣지 않습니다. 콘텐츠를 많이 가리고, 좁은 프레임에서는 두 이름표가 겹칩니다.

</Card>
</Cards>

이름표는 포인터를 받지 않습니다. 버튼을 넣어도 마우스나 터치로 눌리지 않고, 그 자리를 누르면 조작 가능한 Diff의 분할선이 옮겨 갑니다.

### 콘텐츠는 보여 주기만 하는 것으로

조작할 수 있는 Diff의 `before` · `after`에는 버튼 · 입력창 같은 조작 요소를 넣지 않습니다.

- 마우스로 안의 요소를 눌러도 Diff가 그 누름을 함께 받아 분할선을 옮기거나 잡습니다.
- 안의 요소에 포커스가 있을 때 누른 [키보드](#키보드) 표의 키를 Diff가 받아 분할선을 옮길 수 있습니다. Web은 이때 그 키의 브라우저 기본 동작도 막습니다.
- Web은 마우스 누름의 브라우저 기본 동작을 막고 포커스를 프레임으로 가져옵니다.

## 배치

### 폭과 높이

높이를 직접 정하는 속성은 없습니다. 폭이 정해지면 `폭 ÷ aspectRatio`(기본 16:9)가 높이입니다.

| 상황 | Flutter | Jaspr Web |
| --- | --- | --- |
| 부모 폭이 정해짐 | 그 폭을 채웁니다. | 그 폭을 채웁니다(`width: 100%`). |
| 부모의 높이 제한 | 부모가 높이를 고정했거나 높이의 상한이 `폭 ÷ aspectRatio`보다 작으면 부모의 제한을 따릅니다. 이때는 비율이 유지되지 않습니다. | 높이를 따로 두지 않고 CSS `aspect-ratio`를 씁니다. 보통의 블록 배치에서는 부모 높이와 상관없이 폭에서 높이가 나옵니다. |
| 폭의 한계가 없음 | 높이의 한계가 있으면 높이에서 폭을 계산합니다. 둘 다 없으면 레이아웃 오류가 납니다. | 아래 설명을 봅니다. |

Web의 Diff는 안의 층이 모두 절대 위치라 내용에서 나오는 폭이 없습니다. 내용에 맞춰 폭을 정하는 상자(`w-fit` 상자, 가로 flex 안의 폭 없는 `div`) 안에서는 폭이 0이 될 수 있으므로, 폭을 정한 상자에 둡니다.

Flutter의 Diff는 `LayoutBuilder`를 씁니다. `IntrinsicWidth` · `IntrinsicHeight`처럼 자식의 크기를 미리 재는 부모 안에서는 debug 빌드에서 오류가 납니다. 기본 설정의 `Card`도 부모가 폭을 하나로 고정해 주지 않으면 안의 폭을 먼저 잽니다. 이런 곳에서는 폭과 높이를 모두 정한 `SizedBox`로 감쌉니다.

### 고정 비율 끄기

`aspectRatio`를 `0` 이하로 주면 고정 비율을 쓰지 않습니다. Flutter는 부모가 허용하는 폭과 높이를 채우므로 둘 다 한계가 있어야 합니다. Web은 안의 층에서 높이가 나오지 않으므로 `css`로 높이를 정합니다.

### 끝 위치의 손잡이

분할선이 맨 끝에 있으면 손잡이의 절반(기본 20)이 프레임 밖으로 나가고, 포커스 링은 그보다 더 나갑니다. 바깥 요소가 넘친 부분을 자르면 손잡이와 링이 잘리므로 양옆에 여유를 둡니다. Flutter에서는 프레임 밖으로 나간 부분을 누를 수 없습니다.

### 글자 방향

오른쪽에서 왼쪽으로 쓰는 화면에서도 `before`는 왼쪽, `after`는 오른쪽입니다. 이름표의 모서리와 방향키의 방향도 바뀌지 않습니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

겉모습(색 · 크기 · 간격)과 프레임 비율 · 시작 위치 · 키보드 이동 폭은 `diffStyle` 하나로 바꿉니다.

| 대상 | 필드 |
| --- | --- |
| 프레임 | `borderRadius` · `borderColor` · `borderWidth` · `aspectRatio` · `initialPosition` |
| 분할선 | `resizerColor` · `resizerWidth` · `resizerShadow` |
| 손잡이 | `handleSize` · `handleHitSize` · `handleColor` · `handleBorderColor` · `handleBorderWidth` · `handleIconStyle` |
| 손잡이 상태 | `handleShadow` · `handleHoverShadow` · `handlePressedShadow` · `handlePressedScale` · `handleTransitionDuration` |
| 이름표 | `labelInset` · `labelBadgeStyle` |
| 포커스 링 | `focusOutlineStyle` |
| 키보드 | `keyboardStep` · `keyboardPageStep` |

### 기본값

| 필드 | 기본값 |
| --- | --- |
| `borderRadius` | 네 모서리 16 |
| `borderColor` · `borderWidth` | `outlineSubtle` · 1 |
| `resizerColor` · `resizerWidth` | `surfaceRaised` · 2 |
| `resizerShadow` | `CoreShadow.sm` |
| `handleSize` · `handleHitSize` | 40 · 44 |
| `handleColor` | `surfaceRaised` |
| `handleBorderColor` · `handleBorderWidth` | `outlineVariant` · 1 |
| `handleShadow` | `CoreShadow.sm` |
| `handleHoverShadow` | `CoreShadow.md` |
| `handlePressedShadow` | `CoreShadow.xs` |
| `handlePressedScale` | 0.94 |
| `handleTransitionDuration` | 150ms |
| `handleIconStyle` | 크기 16 · `onSurface` |
| `labelInset` | 네 방향 12 |
| `labelBadgeStyle` | 채움 `surfaceRaised` · 글자 `onSurface` |
| `focusOutlineStyle` | 알약 모양 링, 링과 손잡이 사이에 `surface` 색 띠 |
| `aspectRatio` · `initialPosition` | 16/9 · 0.5 |
| `keyboardStep` · `keyboardPageStep` | 0.05 · 0.1 |

### 바꾸는 방법

<Preview demo="diff/theme-style" />

<Split>

<Code language="dart" title="Diff 하나만 바꾸기">
Diff(
  ariaLabel: '보정 전과 보정 후 풍경 비교',
  before: originalPhoto,
  after: editedPhoto,
  diffStyle: const CoreDiffStyle(
    aspectRatio: 4 / 3,
    resizerColor: CoreColor.token(CoreColors.primary),
    resizerWidth: CoreStrokeWidth.stroke4,
    handleSize: CoreSpace.space48,
    handleHitSize: CoreSpace.space56,
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: const CoreComponentTheme(
    diff: CoreDiffTheme(
      style: CoreDiffStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        keyboardStep: 0.02,
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web의 코드가 같습니다. `handleSize`를 키울 때는 `handleHitSize`도 그 이상으로 둡니다. 이유는 [플랫폼 차이](#플랫폼-차이)에 있습니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreDiffStyle.defaultX              // 디자인 시스템 기본값
  → CoreComponentTheme.diff.style   // 앱 전체
  → diffStyle                       // 인스턴스별
```

- 뒤의 값이 앞의 값을 필드마다 덮어씁니다.
- `handleIconStyle` · `labelBadgeStyle` · `focusOutlineStyle`은 그 안의 필드끼리 합칩니다. 적지 않은 필드에는 Diff의 기본값이 남습니다.
- `labelInset`과 그림자 목록은 값 전체가 바뀝니다.
- 이름표는 `Badge`이므로 Badge의 테마도 받습니다. 겹치는 필드는 `labelBadgeStyle`(Diff의 기본값 포함)이 이깁니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Diff`에 `withStyle`을 이어 스타일을 덧붙일 수 있습니다. 생성자에서 받은 `diffStyle`에 합친 사본을 돌려주며, 겹치는 필드는 뒤에 붙인 값이 이깁니다. `.radius0`부터 `.radius9999`까지의 getter는 `borderRadius`를 이름이 같은 `CoreRadius` 값으로 바꾸는 줄임 표기입니다. `borderColor(color)` · `borderWidth(width)` 메서드는 `borderColor`와 `borderWidth`를 각각 바꿉니다. 아래 예는 4:3 프레임에 `tertiary` 색의 폭 4 분할선을 두고 모서리를 16으로 정합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class DiffChainExample extends StatelessWidget {
  const DiffChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Diff(
          ariaLabel: '보정 전과 보정 후 풍경 비교',
          beforeLabel: Text('전'),
          afterLabel: Text('후'),
          before: _Landscape(vivid: false),
          after: _Landscape(vivid: true),
        )
        .withStyle(
          const CoreDiffStyle(
            resizerColor: CoreColor.token(CoreColors.tertiary),
            resizerWidth: CoreStrokeWidth.stroke4,
            aspectRatio: 4 / 3,
          ),
        )
        .radius16;
  }
}

/// A sky, a sun and two hills drawn from colour tokens. Every size and
/// position is a fraction of the frame, so the scene scales with it.
class _Landscape extends StatelessWidget {
  const _Landscape({required this.vivid});

  /// Muted greys when false, the status colours when true.
  final bool vivid;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sky = (vivid ? colors.infoContainer : colors.surfaceContainer).toValue();
    final sun = (vivid ? colors.warning : colors.outlineVariant).toValue();
    final farHill = (vivid ? colors.info : colors.outlineVariant).toValue();
    final nearHill = (vivid ? colors.success : colors.outline).toValue();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Stacks(
          children: [
            Position.fill(child: ColoredBox(color: sky)),
            Position(
              left: width * 0.42,
              top: height * 0.12,
              width: width * 0.16,
              height: width * 0.16,
              child: ClipOval(child: ColoredBox(color: sun)),
            ),
            Position(
              left: width * -0.42,
              top: height * 0.55,
              width: width * 1.6,
              height: width * 1.6,
              child: ClipOval(child: ColoredBox(color: farHill)),
            ),
            Position(
              left: width * 0.15,
              top: height * 0.72,
              width: width * 1.3,
              height: width * 1.3,
              child: ClipOval(child: ColoredBox(color: nearHill)),
            ),
          ],
        );
      },
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class DiffChainExample extends StatelessComponent {
  const DiffChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Diff(
          ariaLabel: '보정 전과 보정 후 풍경 비교',
          beforeLabel: Text('전'),
          afterLabel: Text('후'),
          before: _Landscape(vivid: false),
          after: _Landscape(vivid: true),
        )
        .withStyle(
          const CoreDiffStyle(
            resizerColor: CoreColor.token(CoreColors.tertiary),
            resizerWidth: CoreStrokeWidth.stroke4,
            aspectRatio: 4 / 3,
          ),
        )
        .radius16;
  }
}

/// A sky, a sun and two hills drawn from colour tokens. Every size and
/// position is a fraction of the frame, so the scene scales with it.
class _Landscape extends StatelessComponent {
  const _Landscape({required this.vivid});

  /// Muted greys when false, the status colours when true.
  final bool vivid;

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    final sky = vivid ? cs.infoContainer : cs.surfaceContainer;
    final sun = vivid ? cs.warning : cs.outlineVariant;
    final farHill = vivid ? cs.info : cs.outlineVariant;
    final nearHill = vivid ? cs.success : cs.outline;

    return div(
      [
        _disc(sun, left: '42%', top: '12%', size: '16%'),
        _disc(farHill, left: '-42%', top: '55%', size: '160%'),
        _disc(nearHill, left: '15%', top: '72%', size: '130%'),
      ],
      classes: 'relative w-full h-full overflow-hidden bg-$sky',
    );
  }

  Component _disc(
    CoreColor? color, {
    required String left,
    required String top,
    required String size,
  }) {
    return div(
      const [],
      classes: 'absolute rounded-${CoreRadius.scale.radius9999} bg-$color',
      styles: Styles(
        raw: {'left': left, 'top': top, 'width': size, 'aspect-ratio': '1'},
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

`interactive`가 `true`면 분할 위치를 `0`~`100`의 슬라이더 값으로 전달합니다. `false`면 값이 없는 묶음이 됩니다. 전역으로 적용되는 항목은 [전역 접근성 축](/accessibility)에 있습니다.

### 역할

| 상태 | Flutter | Jaspr Web |
| --- | --- | --- |
| 조작 가능 | `Semantics`의 slider 표시와 `value` · `minValue` `0` · `maxValue` `100`, 이름은 `label` | 루트의 `role="slider"` · `aria-valuemin="0"` · `aria-valuemax="100"` · `aria-valuenow` · `aria-valuetext` |
| 조작 끔 | 역할과 값 없이 `label`만 받는 컨테이너 | `role="group"`, 값 속성 없음 |

- 슬라이더의 역할과 값은 프레임에 붙습니다. 손잡이와 잡는 영역에는 역할과 이름을 붙이지 않으며, 손잡이의 화살표 아이콘은 두 플랫폼 모두 보조 기술에서 숨깁니다.
- Web은 `attributes`를 먼저 합칩니다. 그 뒤에 `role`을, 조작 가능할 때는 `aria-value*`와 `tabindex`도 Diff의 값으로 덮어씁니다. `aria-label`은 `ariaLabel`을 넘기면 덮고, `null`이면 `attributes`의 값이 남습니다.

### 키보드

프레임에 포커스가 있을 때 동작합니다. 위치는 `0`~`1` 사이라 끝을 넘는 키는 끝에서 멈춥니다.

| 키 | 동작 |
| --- | --- |
| `←` | `keyboardStep`(기본 `0.05`)만큼 왼쪽으로 |
| `→` | `keyboardStep`만큼 오른쪽으로 |
| `PageDown` | `keyboardPageStep`(기본 `0.1`)만큼 왼쪽으로 |
| `PageUp` | `keyboardPageStep`만큼 오른쪽으로 |
| `Home` | 맨 왼쪽(`0`)으로. `after`만 보입니다. |
| `End` | 맨 오른쪽(`1`)으로. `before`만 보입니다. |

- 이동 폭은 프레임 폭에 대한 비율입니다. 기본값 `0.05`는 5%, `0.1`은 10%입니다.
- `↑` · `↓`는 처리하지 않습니다.
- 방향은 글자 방향이 아니라 화면의 왼쪽과 오른쪽입니다.
- Flutter는 `Shift` · `Ctrl` · `Alt` · `Meta`를 함께 누른 조합을 처리하지 않습니다. Web은 이 키들을 구분하지 않고 위 표대로 처리합니다.
- 조작을 끄면 Flutter는 키를 연결하지 않고, Web은 Diff의 키 처리를 붙이지 않습니다.

### 스크린 리더

값을 읽는 문장은 지역화 문자열 `diffPositionLabel(percent)`에서 나옵니다. `percent`는 분할 위치에 100을 곱해 반올림한 정수로, 왼쪽에 보이는 `before`의 폭 비율입니다. 한국어는 `분할 지점 40%`이고, 지역화 설정이 없으면 영어 `Split at 40%`입니다. Web의 `aria-valuenow`에도 같은 정수가 들어갑니다.

| 플랫폼 | 이름 |
| --- | --- |
| Flutter | `ariaLabel`이 `label`이 됩니다. `before` · `after` · 이름표 안의 글자는 의미 트리에서 빼지 않으므로 슬라이더의 이름에 함께 합쳐질 수 있습니다. |
| Jaspr Web | Diff가 이름으로 붙이는 속성은 `aria-label`(`ariaLabel`) 하나입니다. |

비교하는 두 쪽이 무엇인지는 `ariaLabel`에 적습니다. 값이 바뀔 때 Diff는 슬라이더의 값을 갱신하며, 별도의 라이브 영역이나 알림 호출은 두지 않습니다.

### 포커스 관리

Diff는 포커스를 가두거나 다른 곳으로 되돌리지 않으며, 처음 화면에서 스스로 포커스를 가져가지 않습니다.

- 조작할 수 있을 때 `Tab`으로 도달합니다. Flutter는 `FocusableActionDetector`가 켜지고 Web은 루트에 `tabindex="0"`이 붙습니다. 포커스를 받는 것은 프레임 전체입니다.
- 마우스로 누르면 두 플랫폼 모두 프레임으로 포커스를 옮깁니다. Flutter는 터치로 짧게 누르거나 잡는 영역을 끌어도 옮깁니다. Web에서 터치로 눌렀을 때의 포커스는 브라우저의 기본 동작을 따릅니다.
- 포커스 링은 프레임이 아니라 손잡이 둘레에 그립니다. 키보드로 도달하면 나타나고, 마우스로 눌러 생긴 포커스에는 나타나지 않습니다. Flutter는 터치로 생긴 포커스에도 링을 보이지 않습니다. 이때도 키는 바로 동작하며, [키보드](#키보드) 표의 키를 누르면 링이 나타납니다. Flutter에서 키보드로 돌아와도 링이 바로 보이지 않는 경우는 [알려진 제약](#알려진-제약)에 있습니다.
- 링이 보이는 상태에서 마우스로 프레임을 누르면 링이 사라집니다.
- 링을 보일지는 Flutter는 포커스 강조 모드와 포인터로 생긴 포커스인지를 함께 보고 정합니다. Web은 포커스를 받는 순간의 `:focus-visible` 판정과 마우스 누름인지를 함께 봅니다. Web 루트에는 `outline-none` 클래스가 있어, 평소에는 브라우저 윤곽선 대신 손잡이의 링이 포커스를 알립니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | `ariaLabel`의 기본값이 `null`이라 넘기지 않으면 Diff가 붙이는 이름이 없습니다. 항상 넘깁니다. |
| 공통 | `↑` · `↓`로는 값을 바꿀 수 없습니다. |
| 공통 | 오른쪽에서 왼쪽으로 쓰는 화면에서도 `before`의 자리와 방향키의 방향을 뒤집지 않습니다. |
| 공통 | `interactive: false`는 비활성이나 읽기 전용 슬라이더가 아닙니다. 값이 없는 묶음이 되며 `aria-disabled` 같은 상태를 알리지 않습니다. |
| 공통 | CoUI 다크 테마에서는 분할선과 손잡이의 `surfaceRaised`가 어두운 색이라 어두운 그림 위에서 흐리게 보일 수 있습니다. 손잡이 테두리(`outlineVariant`)도 채움과 같은 색입니다. 필요하면 `resizerColor` · `handleColor` · `handleBorderColor`를 바꿉니다. |
| Flutter | 의미 트리에 값 올리기 · 내리기 동작(`onIncrease` · `onDecrease`)이 없습니다. 보조 기술의 값 조절 동작으로는 위치를 바꿀 수 없습니다. |
| Flutter | 방향 탐색 모드(`NavigationMode.directional`)에서는 `interactive: false`인 Diff도 포커스를 받을 수 있습니다. 키로 위치는 바뀌지 않습니다. |
| Flutter | 터치로 Diff를 누른 뒤 키를 쓰지 않고 포커스가 다른 곳으로 옮겨 가면, 나중에 `Tab`으로 돌아와도 [키보드](#키보드) 표의 키를 누르기 전까지 링이 보이지 않을 수 있습니다. |
| Flutter | 분할선이 맨 끝에 있으면 잡는 영역 가운데 프레임 안쪽 절반(기본 22)만 누를 수 있습니다. |
| Jaspr Web | 조작 가능한 Diff에 포커스가 있으면 [키보드](#키보드) 표의 키는 `Alt` 같은 키를 함께 눌러도 분할선을 옮기고 브라우저의 기본 동작을 막습니다. 같은 키를 쓰는 브라우저 단축키가 동작하지 않을 수 있습니다. |
| Jaspr Web | 조작 가능한 Diff에서는 `onKeyDown`과 `eventHandlers`의 `keydown` · `pointerdown` · `focus` · `blur`가 불리지 않습니다. Diff의 처리가 같은 이름의 이벤트를 덮어씁니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

생성자의 주요 속성과 기본값은 같고, 그리는 방식과 입력을 받는 방식이 다릅니다.

- **층 자르기** — Flutter: `ClipRect`와 분할 위치까지 자르는 clipper. Jaspr Web: `before` 층의 CSS `clip-path`.
- **마우스** — Flutter: 프레임을 감싼 `Listener`가 누름 · 이동 · 뗌을 받습니다. Jaspr Web: 루트의 `pointerdown`에서 시작하고 이동 · 뗌은 문서의 리스너가 받습니다.
- **터치 끌기** — Flutter: 잡는 영역에 가로 끌기 인식기가 있습니다. Jaspr Web: 잡는 영역에 `touch-action: pan-y`를 두고 포인터 이벤트를 받습니다.
- **탭 판정** — Flutter: 프레임워크의 탭 인식 기준. Jaspr Web: 누른 자리에서 가로 · 세로 10px 안에 머물다 떼면 탭입니다. 벗어나거나 `pointercancel`이 오면 탭이 아닙니다.
- **빈 곳 누르기** — Flutter: 잡는 영역 밖에서는 누른 자리의 콘텐츠가 누름을 받아야 분할선이 옮겨 갑니다. Jaspr Web: 콘텐츠를 담는 층이 누름을 받습니다.
- **터치 눌림 모양** — Flutter: 가로 끌기로 인식한 뒤부터 보입니다. Jaspr Web: 잡는 영역에 손가락이 닿으면 바로 보입니다.
- **올림 모양** — Flutter: `MouseRegion`의 들어옴 · 나감. Jaspr Web: `:hover`(`hover: hover`인 환경).
- **잡는 중 모양** — Flutter: 위젯의 상태가 크기와 그림자를 바꿉니다. Jaspr Web: 잡고 있는 동안 루트에 `data-coui-dragging` 속성이 붙고 CSS가 크기와 그림자를 바꿉니다.
- **포커스 링 판정** — Flutter: 포커스 강조 모드. Jaspr Web: `:focus-visible`.
- **보조 키 조합** — Flutter: 처리하지 않습니다. Jaspr Web: 보조 키를 구분하지 않고 처리합니다.
- **콘텐츠 크기** — Flutter: 프레임 크기로 채워 줍니다. Jaspr Web: `w-full h-full`을 직접 줍니다.
- **부모의 높이 제한** — Flutter: 높이를 고정했거나 상한이 모자라면 비율보다 앞섭니다. Jaspr Web: 블록 배치에서는 `aspect-ratio`에 따라 폭에서 높이가 나옵니다.
- **프레임 밖 손잡이** — Flutter: 밖으로 나간 부분은 누를 수 없습니다. Jaspr Web: 밖으로 나간 부분도 누를 수 있습니다.
- **큰 손잡이** — Flutter: `handleSize`를 `handleHitSize`보다 크게 주어도 보이는 원의 지름은 `handleHitSize`를 넘지 않습니다. Jaspr Web: `handleSize`대로 그립니다. 잡는 영역의 폭은 `handleHitSize` 그대로입니다.
- **테두리 `0`** — Flutter: `handleBorderWidth: 0`이어도 1 물리 픽셀의 가는 선이 남습니다. 선을 숨기려면 `handleBorderColor`를 투명하게 줍니다. Jaspr Web: `handleBorderWidth: 0`이면 선이 없습니다.
- **손잡이 · 선 크기** — Flutter: logical px에 테마의 크기 배율(`scaling`)을 곱합니다. Jaspr Web: `rem`으로 그립니다.

<a id="props-parameters"></a>

## API

`W`는 Flutter의 `Widget`, Web의 Jaspr `Component`입니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `before` | `W` | 필수 | 분할선 왼쪽에 보이는 콘텐츠 |
| `after` | `W` | 필수 | 분할선 오른쪽에 보이는 콘텐츠 |
| `beforeLabel` | `W?` | `null` | 왼쪽 위 이름표의 내용. `Badge`로 감싸 그립니다. |
| `afterLabel` | `W?` | `null` | 오른쪽 위 이름표의 내용 |
| `onPositionChanged` | `void Function(double position)?` | `null` | 조작으로 위치가 바뀔 때 `0`~`1` 값을 받습니다. |
| `interactive` | `bool` | `true` | 손잡이를 그리고 마우스 · 터치 · 펜 · 키보드 조작을 받습니다. |
| `ariaLabel` | `String?` | `null` | 접근성 이름 |
| `diffStyle` | `CoreDiffStyle?` | `null` | 겉모습 · 비율 · 시작 위치 · 키보드 이동 폭 |

두 플랫폼 모두 `key`를 받습니다. Web은 루트에 붙는 `id` · `classes` · `css` · `attributes` · `eventHandlers`와 공통 이벤트 콜백도 받습니다. 조작 가능할 때 불리지 않는 이벤트는 [알려진 제약](#알려진-제약)에 있습니다.

### 메서드와 getter

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreDiffStyle patch)` | `diffStyle`에 `patch`를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch`가 이깁니다. |
| `.radius0` … `.radius9999` | `borderRadius`만 해당 `CoreRadius` 값으로 합칩니다. |
| `borderColor(CoreColor value)` | `borderColor`만 합칩니다. |
| `borderWidth(double value)` | `borderWidth`만 합칩니다. |
| `copyWith(...)` | 넘긴 값만 바꾼 사본을 만듭니다. `null`을 넘기면 지금 값이 남습니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.diff` | `CoreDiffTheme?` | 앱 전체의 Diff 테마 |
| `CoreDiffTheme.style` | `CoreDiffStyle?` | 모든 Diff에 적용하는 스타일 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreDiffStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `borderRadius` | `CoreBorderRadius?` | Container border radius override. |
| `borderColor` | `CoreColor?` | Frame edge colour override. `null` → [defaultBorderColor]. |
| `borderWidth` | `double?` | Frame edge width override (logical px). `0` draws no edge. `null` → [defaultBorderWidth]. |
| `resizerColor` | `CoreColor?` | Resizer line colour override. `null` → [defaultResizerColor]. |
| `resizerWidth` | `double?` | Resizer line width override (logical px, pre-scaling). `null` → [defaultResizerWidth]. |
| `resizerShadow` | `List<CoreShadowLayer>?` | Resizer line cast override. An empty list draws no cast. `null` → [defaultResizerShadow]. |
| `handleSize` | `double?` | Handle diameter override (logical px, pre-scaling). `null` → [defaultHandleSize]. |
| `handleHitSize` | `double?` | Width of the area that accepts a grab around the handle (logical px, pre-scaling). `null` → [defaultHandleHitSize]. |
| `handleColor` | `CoreColor?` | Handle fill override. `null` → [defaultHandleColor]. |
| `handleBorderColor` | `CoreColor?` | Handle edge colour override. `null` → [defaultHandleBorderColor]. |
| `handleBorderWidth` | `double?` | Handle edge width override (logical px). `null` → [defaultHandleBorderWidth]. |
| `handleShadow` | `List<CoreShadowLayer>?` | Handle cast at rest. An empty list draws no cast. `null` → [defaultHandleShadow]. |
| `handleHoverShadow` | `List<CoreShadowLayer>?` | Handle cast while the pointer is over it. `null` → [defaultHandleHoverShadow]. |
| `handlePressedShadow` | `List<CoreShadowLayer>?` | Handle cast while it is being dragged. `null` → [defaultHandlePressedShadow]. |
| `handlePressedScale` | `double?` | Scale of the handle while it is being dragged, as a ratio of its own size. `1` turns the shrink off. `null` → [defaultHandlePressedScale]. |
| `handleTransitionDuration` | `Duration?` | Time the handle takes to change between rest, hover and pressed. `null` → [defaultHandleTransitionDuration]. |
| `handleIconStyle` | `CoreIconStyle?` | Look of the glyph on the handle — size and colour. Laid over [defaultHandleIconStyle]. |
| `labelInset` | `CoreEdgeInsets?` | Distance of the label chips from the frame's top corners. Laid over [defaultLabelInset]. |
| `labelBadgeStyle` | `CoreBadgeStyle?` | Look of the label chips, handed to the `Badge` each one is drawn with. Laid over [defaultLabelBadgeStyle]. |
| `focusOutlineStyle` | `CoreFocusOutlineStyle?` | Focus ring of the handle. Laid over [defaultFocusOutlineStyle]. |
| `aspectRatio` | `double?` | Container aspect ratio (width / height) — it sets the box's proportions. |
| `initialPosition` | `double?` | Where the split bar starts (0.0 — 1.0), applied at first render. When `interactive: true`, dragging moves it from there. |
| `keyboardStep` | `double?` | Position delta applied per arrow-key press (`[0, 1]` units) override. Falls back to [defaultKeyboardStep] when null. |
| `keyboardPageStep` | `double?` | Position delta applied per Page Up / Page Down press (`[0, 1]` units) override. Falls back to [defaultKeyboardPageStep] when null. |

<!-- STYLE_TABLE:END -->

<Note>

- 표는 `labelInset`을 기본값 위에 덮는다고(Laid over) 적지만, 실제로는 방향별로 합치지 않고 값 전체를 바꿉니다. `CoreEdgeInsets.only(top: CoreSpace.space8)`을 넘기면 `left` · `right`는 `0`이 됩니다. 방향은 `left` · `right`로 적습니다. Flutter는 `CoreEdgeInsets.directional` 값을 받으면 오류를 냅니다.
- `initialPosition`은 처음 그릴 때만 읽는 값이 아닙니다. 조작으로 위치가 정해지기 전에는 바뀐 값이 반영됩니다.
- `aspectRatio`가 `0` 이하면 고정 비율을 쓰지 않습니다([고정 비율 끄기](#고정-비율-끄기)).
- 설명의 `pre-scaling`은 Flutter가 이 값에 크기 배율을 곱한다는 뜻입니다. Web은 배율을 곱하지 않고 `rem`으로 그립니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="diff/related-code-diff" title="CodeDiff">

코드 변경 사항을 줄 단위로 보여 줍니다. [CodeDiff 문서](/components/code-diff)

</Card>
<Card demo="diff/related-carousel" title="Carousel">

여러 콘텐츠를 차례로 넘겨 봅니다. [Carousel 문서](/components/carousel)

</Card>
<Card demo="diff/related-hover-gallery" title="HoverGallery">

포인터가 놓인 위치에 맞는 항목 하나를 보여 줍니다. [HoverGallery 문서](/components/hover-gallery)

</Card>
</Cards>
