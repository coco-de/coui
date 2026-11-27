---
title: Icon
description: Iconify 아이콘을 이름 하나로 가리켜 Flutter와 Web에서 같은 코드로 그립니다. 크기와 색은 직접 정하거나 놓인 자리의 값을 따릅니다.
category: display
platforms: [flutter, web]
related: [button, badge, fab]
tags: [icon, display, visual]
template: v2
source: icon
---

# Icon

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

아이콘 · 크기 · 색을 바꿔 보며 Icon을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="icon" />

`Icon`은 첫 번째 인자로 `IconName`을 받고, 겉모습은 `iconStyle`(`CoreIconStyle`)로 정합니다. 필드는 크기(`size`)와 색(`color`) 둘입니다. 둘 다 비우면 놓인 자리의 값을 따릅니다. 기본 설정의 `CoUIApp` · `CoUIWeb` 바로 아래에서 크기를 비우면 20으로 그립니다. 위 코드는 Flutter와 Web에서 같습니다.

## 아이콘 세트

`IconName`은 Iconify의 아이콘 id(`접두어:이름`)를 담는 값입니다. 네 세트는 상수로 들어 있습니다.

| 상수 모음 | 접두어 | 예 |
| --- | --- | --- |
| `LucideIcons` | `lucide` | `LucideIcons.house` |
| `RadixIcons` | `radix-icons` | `RadixIcons.chevronLeft` |
| `BootstrapIcons` | `bi` | `BootstrapIcons.gear` |
| `HeroIcons` | `heroicons` | `HeroIcons.arrowLeft` |

그 밖의 Iconify 세트는 접두어와 이름을 직접 적습니다.

```dart
const Icon(LucideIcons.house)
const Icon(RadixIcons.chevronLeft)
const Icon(BootstrapIcons.gear)
const Icon(HeroIcons.arrowLeft)       // 접미사가 없는 이름
const Icon(HeroIcons.arrowLeftSolid)  // 접미사가 붙은 이름 (heroicons:arrow-left-solid)
const Icon(IconName('tabler', 'home'))
```

- 앱에서는 어느 세트든 쓸 수 있지만, CoUI 컴포넌트가 직접 그리는 아이콘은 `LucideIcons`만 씁니다. 세트마다 격자와 획이 달라 같은 크기에서도 무게가 다르게 보일 수 있으므로, 나란히 놓는 컨트롤은 한 세트로 맞추는 편이 좋습니다.
- `HeroIcons`의 채운 모양 · 작은 크기용 모양은 `arrowLeftSolid` · `arrowLeft20Solid`처럼 접미사가 붙은 상수로 따로 있습니다. `.outline`은 자기 자신을 돌려주고, `.solid` · `.mini` · `.micro`는 이름은 두고 접두어를 `heroicons-solid` · `heroicons-mini` · `heroicons-micro`로 바꾼 `IconName`을 돌려줍니다. 접미사 상수와는 다른 id이며, getter라서 `const` 표현식에는 쓸 수 없습니다.
- `package:coui_flutter/coui_flutter.dart`는 Flutter SDK의 `Icon` 대신 CoUI의 `Icon`을 내보냅니다. 생성자는 `IconName`을 받으며, Material의 `IconData`는 받지 않습니다.
- `LucideIcons.house`처럼 패키지에 들어 있는 아이콘은 네트워크 없이 그려집니다. 상수가 있다고 모두 들어 있는 것은 아니며, 그 밖의 아이콘은 직접 등록하지 않았다면 데이터를 받아 와야 합니다. [불러오기](#불러오기)를 보세요.

<a id="크기-권장값"></a>

## 크기

크기는 `iconStyle`의 `size` 하나로 정합니다. 가로와 세로가 같은 상자이고, 정사각형이 아닌 글리프는 비율을 지켜 그 안에 맞춥니다. `size`는 `double`이라 어떤 값도 줄 수 있고, `CoreIconSize`에는 이름 붙은 값 열 개(`size10`부터 `size48`까지)가 있습니다.

<Preview demo="icon/sizes" />

### 크기를 비웠을 때

아이콘에도 앱 테마(`CoreIconTheme`)에도 크기가 없으면 놓인 자리가 정합니다.

| 놓인 자리 | 크기 |
| --- | --- |
| 기본 설정의 `CoUIApp`(Flutter) · `CoUIWeb`(Web) 아래 | 20 (`CoreIconStyle.defaultAmbientSize`) |
| `Button` · `Badge`처럼 아이콘 크기를 정하는 슬롯 안 | 그 컴포넌트의 크기 단계가 정한 값. 예를 들어 `md` 버튼의 앞뒤 아이콘은 16입니다. |
| 크기를 주는 `IconTheme`이 없는 곳 | 24 (`CoreIconStyle.defaultSize`) |

### 크기 배율

`size`에는 배율을 곱하기 전의 값을 적습니다.

| 플랫폼 | 동작 |
| --- | --- |
| Flutter | `Icon`이 고른 크기에 테마의 크기 배율(`ThemeData.scaling`)을 곱합니다. `CoUIApp(scaling: AdaptiveScaling(1.25))`에서 `size: 20`은 25로 그려집니다. 배율을 미리 곱해 넘기면 한 번 더 곱해집니다. |
| Web | 배율을 곱하지 않고 `size ÷ 16`을 `rem`으로 씁니다. 그래서 브라우저의 루트 글자 크기를 따릅니다. |

<Note>

Flutter에서 배율이 1이 아니면 곱셈이 두 번 일어나는 자리가 있습니다.

- 앱 루트 아래에서 크기를 비운 아이콘은 `ThemeData.iconTheme.medium`을 읽습니다. 위의 `AdaptiveScaling(1.25)`는 글자 배율도 1.25라 이 값에 먼저 곱하고, `Icon`이 크기 배율을 다시 곱합니다. 그래서 25가 아니라 31.25로 그려집니다.
- `Badge` · `Chip` · `Label` · `Dock` · `EmptyState`는 크기 배율을 곱한 값을 아이콘 자리의 `IconTheme`으로 넘깁니다. 그 자리에 크기를 비운 `Icon`을 넣으면 크기 배율이 한 번 더 곱해집니다. `Button`은 곱하기 전의 값을 넘깁니다.

두 경우 모두 `Icon`은 넘겨받은 값을 토큰 크기로 읽으므로, Lucide 획도 이미 곱한 값을 기준으로 정해집니다.

</Note>

### Lucide 획 규칙

Lucide 원본은 24 격자에 `stroke-width="2"`로 그려져 있습니다. 그대로 쓰면 렌더 획이 크기 ÷ 12가 되어, 10에서는 1px보다 가늘어지고 크기가 커질수록 함께 굵어집니다. Icon은 이 값 대신 Core의 규칙 하나(`CoreIconStroke`)로 아이콘 크기에서 획을 정하며, Flutter와 Web이 같은 규칙을 읽습니다.

```text
렌더 획 = max(1.25, 토큰 크기 ÷ 16)
SVG stroke-width (24 격자) = 렌더 획 × 24 ÷ 토큰 크기 = max(1.5, 30 ÷ 토큰 크기)
```

렌더 획은 토큰 px로 잰 화면 위 두께이고, SVG `stroke-width`는 글리프 안 24 격자의 값입니다. SVG가 `크기 ÷ 24` 비율로 그려지므로 같은 렌더 획이 크기마다 다른 SVG 값이 됩니다. 20 이하는 1.25로 같고, 그보다 크면 크기를 따라 굵어집니다. SVG 값은 소수점 넷째 자리까지 씁니다.

| 토큰 크기 | 렌더 획 | SVG `stroke-width` |
| --- | --- | --- |
| 10 | 1.25 | 3 |
| 12 | 1.25 | 2.5 |
| 14 | 1.25 | 2.1429 |
| 16 | 1.25 | 1.875 |
| 18 | 1.25 | 1.6667 |
| 20 | 1.25 | 1.5 |
| 24 | 1.5 | 1.5 |
| 28 | 1.75 | 1.5 |
| 32 | 2 | 1.5 |
| 48 | 3 | 1.5 |

표에 없는 크기도 같은 식을 씁니다(8은 1.25, 22는 1.375).

- **토큰 크기**: `Icon`이 크기 배율을 곱하기 전의 크기입니다. 배율이 상자를 키우면 획도 같은 비율로 커집니다. 크기 배율이 1.25인 Flutter 앱에서 토큰 20은 25 상자에 1.5625 획으로 그려집니다.
- **Lucide만**: 접두어가 `lucide`인 아이콘에만 적용합니다. 다른 세트의 획은 원본 그대로입니다.
- **원본 값 2만**: 글리프 안의 `stroke-width="2"`만 바꾸고, 다른 굵기는 그대로 둡니다.
- **선 굵기 토큰과 분리**: `CoreStrokeWidth`나 `--coui-stroke-width-*`를 읽지 않습니다. 네오브루탈리즘처럼 테두리를 굵게 하는 서페이스 스타일에서도 아이콘은 굵어지지 않습니다.
- **스타일 필드 없음**: 획은 크기에서 나오는 값이라 `CoreIconStyle`에는 획 필드가 없습니다.
- **다른 컴포넌트의 아이콘**: 컴포넌트가 `Icon`으로 그리는 Lucide 아이콘도 같은 규칙을 따릅니다. [Checkbox](/components/checkbox)의 체크 표시는 `LucideIcons.check`이고, 기본 크기(8~16)가 모두 하한에 걸려 1.25로 그려집니다. 중간 상태 가로줄의 기본 두께(`markThickness`)도 같은 하한 값(`CoreIconStroke.minRenderedWidth`)을 씁니다.

## 색

색은 `iconStyle`의 `color`(`CoreColor`)로 정하며, 두 플랫폼의 타입이 같습니다. `CoreColor.token(CoreColors.error)`처럼 토큰으로 주면 지금 테마와 밝기를 따라가고, `CoreColor(0xFFE11D48)`처럼 값을 직접 적으면 밝기가 바뀌어도 그대로입니다.

<Preview demo="icon/colors" />

### 색상 처리 차이점

| 항목 | Flutter | Web |
| --- | --- | --- |
| 색을 비웠을 때(앱 테마에도 없으면) | 가장 가까운 `IconTheme`의 색. `CoUIApp`은 `onSurface`를 줍니다. 둘레의 글자색(`DefaultTextStyle`)은 따르지 않습니다. | `IconTheme`이 색을 주면 그 색을 씁니다. 없으면 색을 지정하지 않아 둘레의 CSS 글자색(`currentColor`)을 이어받습니다. |
| 색을 칠하는 방법 | `ColorFilter.mode(color, BlendMode.srcIn)` | 토큰 색은 `text-{token}` 클래스, 직접 적은 색은 인라인 `color` |
| 여러 색으로 그려진 아이콘 | 글리프 전체를 한 색으로 칠합니다. | `currentColor`로 그린 부분만 바뀌고, 색이 따로 적힌 부분은 그대로입니다. |

<Note>

Flutter에서 위에 `IconTheme`이 하나도 없으면 `onSurface`가 아니라 Flutter SDK의 `IconTheme` 기본색인 검정이 들어옵니다.

</Note>

<a id="동작-스펙-behavior"></a>

## 불러오기

CoUI 컴포넌트가 직접 그리는 Lucide 아이콘은 대부분 패키지에 들어 있습니다(`CoreBundledIcons`). Lucide 전체가 들어 있는 것은 아닙니다. 이 목록에 있는 아이콘은 앱에서 직접 써도 네트워크 없이 그립니다. 들어 있는지는 `CoreBundledIcons.icons.containsKey(LucideIcons.house.id)`로 확인합니다. 그 밖의 아이콘은 직접 등록하지 않았다면 Iconify에서 받아 옵니다.

<Note>

컴포넌트가 그리는 아이콘 가운데 아래는 지금 목록에 없어, 직접 등록하지 않으면 다른 아이콘처럼 받아 옵니다. Flutter는 `preload`로 미리 받거나 `register`로 등록해 둘 수 있습니다. Web은 아래의 폴백 스크립트가 필요하고, Iconify에 데이터를 직접 등록할 수도 있습니다.

- `StepItem`의 진행 중(`circle-dot`) · 대기(`circle`) 상태 아이콘
- 메뉴 라디오 항목의 기본 선택 표시(`CoreMenuRadioMark.dot`, `circle-dot`)
- 메뉴 표준 명령(`CoreMenuAction`) 가운데 `cut` · `paste` · `undo` · `redo` · `delete`의 기본 아이콘

</Note>

| 아이콘 | Flutter | Web |
| --- | --- | --- |
| 패키지에 든 것 | 첫 빌드에서 데이터를 바로 읽습니다. 네트워크를 기다리지 않습니다. | 인라인 `<svg>`로 그립니다. 스크립트나 Iconify 요청이 필요 없고, 서버 렌더 마크업에도 들어갑니다. |
| 그 밖의 것 | `IconResolver`의 캐시를 읽고, 없으면 받아 옵니다. 데이터가 올 때까지 같은 크기의 빈 정사각형을 둡니다. | `<iconify-icon>` 요소를 냅니다. 그리려면 아래의 폴백 스크립트가 필요합니다. |

### 미리 받기와 직접 등록 (Flutter)

번들에 없는 아이콘은 앱을 시작할 때 `preload`로 미리 받아 둘 수 있습니다.

```dart
await IconResolver.instance.preload([
  LucideIcons.trash2.id,
  LucideIcons.phone.id,
]);
```

직접 만든 SVG는 id를 정해 등록합니다. 그 id를 쓰는 `Icon`을 화면에 올리기 전에 등록하세요.

```dart
IconResolver.instance.register(
  'brand:mark',
  const IconSvgData(body: '<path fill="currentColor" d="M4 4h16v16H4z"/>'),
);

const Icon(IconName('brand', 'mark'))
```

- 등록한 값이 같은 id의 번들 아이콘보다 우선합니다.
- 등록 · 번들 · 메모리에 없는 아이콘은 먼저 디스크 캐시를 읽고, 거기에도 없으면 Iconify API(`https://api.iconify.design`)에 요청합니다.
- 받지 못하면 오류를 내지 않고 빈 정사각형으로 남습니다. 그 `Icon`은 스스로 다시 시도하지 않으며, 아이콘이 바뀌거나 위젯이 새로 만들어질 때 다시 읽습니다.
- 디스크 캐시의 위치는 `IconResolver.instance.cacheDir`이고, 기본값은 상대 경로 `.coui_icons_cache`입니다. 쓰지 못해도 오류를 내지 않습니다. Flutter Web에는 디스크 캐시가 없습니다.
- 디스크 파일은 세트(접두어)마다 하나이고, 새로 받을 때마다 그 요청에서 받은 내용으로 덮어씁니다. 같은 세트를 여러 번에 나눠 받으면 마지막 요청분만 파일에 남습니다.

### Web 폴백 스크립트

번들 밖의 아이콘을 쓰면 페이지 `<head>`에 `iconScript()`를 넣습니다. 외부 스크립트 두 개를 불러옵니다. Iconify의 `iconify-icon`(기본값은 jsDelivr의 2.1.0)과, Lucide 획 규칙을 적용하는 CoUI의 `packages/coui_web/iconify_stroke.js`입니다. 뒤의 것은 Jaspr가 같은 출처에서 제공하는 패키지 파일입니다. 인라인 스크립트나 `onload` 속성은 넣지 않습니다.

두 번째 주소의 기본값은 페이지 주소를 기준으로 찾는 상대 주소입니다. `<base>`가 없으면 `/guide/intro` 페이지는 `/guide/packages/…`를 찾으므로, 이런 페이지가 있는 사이트는 `normalizerSrc: '/packages/coui_web/iconify_stroke.js'`처럼 루트 기준 주소를 넘기세요. 직접 호스팅하면 두 주소를 각각 지정합니다.

```dart
iconScript(
  src: '/vendor/iconify-icon.js',
  normalizerSrc: '/vendor/coui-iconify-stroke.js',
)
```

- CSP를 쓰면 `script-src`에 두 스크립트의 출처를 허용합니다. 번들 밖 아이콘의 데이터를 Iconify API에서 받는다면 그 API의 출처도 `connect-src`에 허용해야 합니다.
- Iconify의 JavaScript API(`addIcon` · `addCollection`)로 등록한 아이콘도 쓸 수 있습니다. 번들 아이콘은 Iconify를 거치지 않으므로, 같은 id로 등록해도 번들의 글리프가 그려집니다. Dart에서 아이콘 데이터를 등록하는 API는 Web에 없습니다.
- Iconify의 `<script>`만 직접 넣으면 번들 밖 Lucide 아이콘에는 획 규칙이 적용되지 않습니다. `iconScript()`로 바꾸거나 CoUI 스크립트도 함께 불러오세요. 스크립트가 늦게 도착하면 도착한 뒤에 적용됩니다.
- CoUI 스크립트는 Iconify의 공유 데이터는 바꾸지 않고 아이콘마다 사본을 만들어 획을 바꿉니다. 그래서 같은 글리프를 서로 다른 크기로 함께 둘 수 있습니다.
- `mode` · `rotate` · `flip` 같은 Iconify 속성은 `attributes`로 넘기며, `<iconify-icon>`으로 그리는 번들 밖 아이콘에만 효과가 있습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 버튼 · 메뉴 · 탐색 항목의 글에 시각적인 단서를 더할 때
- 자리가 좁아 아이콘만 둘 때. 이때는 이름을 반드시 따로 붙입니다(접근성 섹션).

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 눌러서 동작을 실행해야 할 때. `Icon`에는 `onPressed`가 없습니다. | [Button](/components/button) 안에 아이콘을 넣습니다. |
| 화면 위에 떠 있는 주요 동작 | [Fab](/components/fab) |
| 숫자나 상태를 표시할 때 | [Badge](/components/badge). 아이콘 모서리에 얹으려면 [Indicator](/components/indicator)로 조합합니다. |

<a id="do"></a>
<a id="dont"></a>

### 색과 크기는 자리에 맡기기

<Cards columns="2">
<Card demo="icon/do-inherit" tone="do" eyebrow="이렇게 하세요">

색을 비우면 아이콘이 버튼의 글자색을 따라갑니다. 버튼 종류가 바뀌어도 색을 다시 정하지 않아도 됩니다.

</Card>
<Card demo="icon/dont-color" tone="dont" eyebrow="이렇게 하지 마세요">

아이콘에 색을 직접 주면 버튼이 정한 색을 덮습니다. 여기서는 채운 버튼의 면에 아이콘이 묻힙니다.

</Card>
<Card demo="icon/do-size" tone="do" eyebrow="이렇게 하세요">

크기를 비우면 버튼의 크기 단계에 맞는 값이 들어갑니다.

</Card>
<Card demo="icon/dont-size" tone="dont" eyebrow="이렇게 하지 마세요">

작은 버튼의 아이콘에 큰 크기를 직접 주면 단계의 값이 덮여 글과의 비례가 깨집니다.

</Card>
</Cards>

### 아이콘 세트는 나란히 섞지 않기

<Split>

<Code language="dart" title="이렇게 하세요">
// 짝이 되는 아이콘은 같은 세트에서 고릅니다.
Icon(LucideIcons.chevronLeft)
Icon(LucideIcons.chevronRight)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 격자와 획이 다른 두 세트가 나란히 놓입니다.
Icon(LucideIcons.chevronLeft)
Icon(RadixIcons.chevronRight)
</Code>

</Split>

## 배치

### 컴포넌트 슬롯에 넣기

`Button`의 `leading` · `trailing`이나 `Badge`의 `leading`에는 스타일을 비운 `Icon`을 넣습니다. 컴포넌트가 둘레에 `IconTheme`을 두어 크기를 정하고, 아이콘 색은 컴포넌트의 색을 따라갑니다. `Button`은 글 옆의 아이콘과 `square` · `circle` 버튼의 아이콘에 서로 다른 크기를 씁니다(`md`는 16과 18).

<Preview demo="icon/slots" />

```dart
Button(
  onPressed: download,
  leading: const Icon(LucideIcons.download),
  child: const Text('내려받기'),
)
```

슬롯이 주는 값은 `IconTheme`으로 전해지므로, 아이콘의 `iconStyle`과 앱 테마의 `CoreIconTheme`이 슬롯의 값보다 우선합니다.

### 직접 만든 영역에 한꺼번에 정하기

여러 아이콘의 크기와 색을 한 번에 정하려면 `IconTheme`으로 감쌉니다. `IconTheme`을 쓰는 방법은 두 플랫폼이 다릅니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
IconTheme.merge(
  data: const IconThemeData(size: CoreIconSize.size16),
  child: const Row(
    mainAxisSize: MainAxisSize.min,
    children: [Icon(LucideIcons.check), Icon(LucideIcons.x)],
  ),
)
```

`IconTheme.merge`는 적지 않은 값을 위에서 이어받습니다. `IconTheme(...)` 생성자는 위의 값을 통째로 바꾸므로, 색을 적지 않으면 검정, 크기를 적지 않으면 24가 됩니다. 여기의 `IconThemeData`는 Flutter SDK의 것이라 `color`가 Flutter의 `Color`입니다.

  </TabItem>
  <TabItem label="Web" value="web">

```dart
IconTheme(
  data: const IconThemeData(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.primary),
  ),
  child: div([
    const Icon(LucideIcons.check),
    const Icon(LucideIcons.x),
  ]),
)
```

Web의 `Icon`은 가장 가까운 `IconTheme` 하나만 읽고, 위의 값과 합치지 않습니다. 색만 담아 감싸면 앱 루트의 크기 20도 가려져 24가 됩니다. 크기만 담으면 색은 CSS 글자색을 이어받습니다.

  </TabItem>
</Tabs>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

겉모습은 `iconStyle`(`CoreIconStyle`) 하나로 바꿉니다. 앱 전체에는 `CoreComponentTheme`의 `icon` 자리에 `CoreIconTheme(style: ...)`을 둡니다.

<Split>

<Code language="dart" title="아이콘 하나만 바꾸기">
const Icon(
  LucideIcons.heart,
  iconStyle: CoreIconStyle(
    size: CoreIconSize.size28,
    color: CoreColor.token(CoreColors.tertiary),
  ),
)
</Code>

<Code language="dart" title="여러 곳에서 같은 값 쓰기">
const dangerIcon = CoreIconStyle(
  size: CoreIconSize.size20,
  color: CoreColor.token(CoreColors.error),
);

const Icon(LucideIcons.triangleAlert, iconStyle: dangerIcon)
const Icon(LucideIcons.x, iconStyle: dangerIcon)
</Code>

</Split>

<a id="resolve-chain"></a>

### 값이 정해지는 순서

<Preview demo="icon/theme-order" />

뒤로 갈수록 우선합니다. `size`와 `color`는 따로 정해지므로, 한 필드는 `iconStyle`에서, 다른 필드는 `IconTheme`에서 올 수 있습니다.

```text
아무 값도 없을 때              // 크기 24, 색은 플랫폼마다 다릅니다(색 섹션)
  → 가장 가까운 IconTheme      // 앱 루트, 컴포넌트 슬롯, 직접 감싼 것
  → CoreIconTheme.style        // 앱 테마
  → iconStyle                  // 아이콘 하나
```

- 앱 테마는 컴포넌트 슬롯의 `IconTheme`보다 우선합니다. `CoreIconTheme`에 `color`를 주면 슬롯에 넣은 아이콘이 채운 버튼 안에서도 그 색이 되고, `size`를 주면 버튼의 크기 단계와 상관없이 같은 크기가 됩니다.
- 컴포넌트가 자기 아이콘의 `iconStyle`에 직접 넣는 값은 위 순서의 마지막 자리라 앱 테마보다 우선합니다.
- `Button`의 `leadingIconStyle` · `trailingIconStyle`처럼 컴포넌트 스타일에 있는 아이콘 값은 슬롯에 넣은 아이콘에 `IconTheme`으로 전해집니다. 그래서 위 순서에서 `IconTheme` 자리입니다.

### 테마 연동

앱 전체에서 크기를 비운 아이콘을 슬롯 안의 것까지 같은 크기로 맞춥니다. 아래 코드는 두 플랫폼에서 같고, 만든 테마를 `CoUIApp` · `CoUIWeb`의 `theme`에 넘깁니다. `darkTheme`을 따로 넘기는 앱은 그쪽에도 같은 `coreComponentTheme`을 넣습니다.

```dart
final theme = ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: const CoreComponentTheme(
    icon: CoreIconTheme(
      style: CoreIconStyle(size: CoreIconSize.size20),
    ),
  ),
);
```

`color`도 같은 자리에 줄 수 있지만, 위에서 본 것처럼 색을 비운 모든 아이콘에 적용됩니다. 버튼처럼 배경이 다른 자리의 아이콘까지 같은 색이 됩니다.

### 앱의 기본 크기만 바꾸기

버튼처럼 크기를 정하는 슬롯은 그대로 두고 앱 루트의 기본 크기만 바꾸려면, 테마 대신 루트의 `IconTheme` 값을 바꿉니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
final theme = ThemeData.fromCore(
  CoreThemePresets.light,
  iconTheme: const IconThemeProperties(
    medium: IconThemeData(size: CoreIconSize.size24),
  ),
);
```

`CoUIApp`은 `iconTheme.medium`을 앱 루트의 `IconTheme`으로 둡니다. 색은 `onSurface`로 덮어씁니다.

  </TabItem>
  <TabItem label="Web" value="web">

```dart
CoUIWeb(
  theme: ThemeData.light,
  child: IconTheme(
    data: const IconThemeData(size: CoreIconSize.size24),
    child: App(),
  ),
)
```

`CoUIWeb`이 두는 루트 값(20)보다 `child`에 둔 `IconTheme`이 가까우므로, 그 안에서는 이 값이 쓰입니다. 다만 팝오버 · 메뉴 · 툴팁 · 대화상자처럼 `CoUIWeb`의 오버레이 층에 뜨는 패널은 `child` 바깥에서 그려집니다. 그 안의 아이콘은 여기서 감싼 값을 받지 않으므로, 필요하면 패널 내용도 `IconTheme`으로 감싸세요.

  </TabItem>
</Tabs>

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Icon`에 `withStyle`로 스타일을 덧붙일 수 있습니다. 생성자의 `iconStyle`에 합친 새 `Icon`을 돌려주며, 겹치는 필드는 뒤에 붙인 값이 이깁니다. 아래 예제는 크기 28로 만든 아이콘에 크기 32와 `primary` 색을 덧붙입니다. 기본 CoUI 팔레트의 `primary`는 무채색이라 둘레의 글자색과 거의 같아 보입니다.

<Preview component="icon" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class IconChainExample extends StatelessWidget {
  const IconChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      LucideIcons.house,
      iconStyle: CoreIconStyle(size: 28),
    ).withStyle(
      const CoreIconStyle(
        size: CoreIconSize.size32,
        color: CoreColor.token(CoreColors.primary),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class IconChainExample extends StatelessComponent {
  const IconChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Icon(
      LucideIcons.house,
      iconStyle: CoreIconStyle(size: 28),
    ).withStyle(
      const CoreIconStyle(
        size: CoreIconSize.size32,
        color: CoreColor.token(CoreColors.primary),
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

`Icon`은 표시 전용 그림이며, 두 플랫폼 모두 이름을 만들지 않습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | `Icon`이 따로 정하는 역할은 없습니다. 그림을 그리는 `SvgPicture`가 라벨이 빈 이미지 표시(`Semantics(image: true, label: '')`)를 더합니다. 별도 노드를 강제하지 않아(`container: false`) 둘레의 노드에 합쳐질 수 있습니다. 아이콘 데이터를 기다리는 빈 정사각형에는 이 표시도 없습니다. |
| Web | `role`과 `aria-*`를 붙이지 않습니다. 번들 아이콘은 `focusable="false"`와 `data-icon`을 가진 `<svg>`이고, 그 밖은 `<iconify-icon>` 요소입니다. `attributes`로 넘긴 속성은 그 요소에 그대로 붙습니다. |

`aria-hidden`이나 `ExcludeSemantics`는 자동으로 붙지 않습니다. 옆의 글이 같은 뜻을 말하는 장식용 아이콘을 확실히 빼려면 Flutter는 `ExcludeSemantics`로 감싸고, Web은 `attributes: {'aria-hidden': 'true'}`를 넘깁니다.

### 키보드

없음. 처리하는 키가 없습니다. Flutter의 생성자는 `key` · `icon` · `iconStyle`만 받아 제스처나 포커스 파라미터가 없습니다. Web은 `eventHandlers`를 받지만 `tabindex`를 붙이지 않습니다.

### 스크린 리더

`Icon`에서 나오는 이름은 없고, 상태 변화를 알리는 라이브 영역도 없습니다. 뜻이 있는 아이콘은 이름을 따로 붙입니다.

<Preview demo="icon/a11y-name" />

글 없이 홀로 선 아이콘에는 직접 이름을 붙입니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Semantics(
  label: '주의',
  child: const Icon(LucideIcons.triangleAlert),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
const Icon(
  LucideIcons.triangleAlert,
  attributes: {'role': 'img', 'aria-label': '주의'},
)
```

  </TabItem>
</Tabs>

아이콘만 넣은 버튼은 버튼이 하는 일을 이름으로 붙입니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Button(
  shape: CoreButtonShape.square,
  onPressed: search,
  child: Semantics(label: '검색', child: const Icon(LucideIcons.search)),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
Button(
  shape: CoreButtonShape.square,
  onPressed: search,
  attributes: const {'aria-label': '검색'},
  child: const Icon(LucideIcons.search),
)
```

  </TabItem>
</Tabs>

### 포커스 관리

없음. 포커스를 받는 요소가 아닙니다. Flutter에는 `Focus`가 없고 Web에는 `tabindex`가 없습니다. 오버레이가 아니므로 포커스를 옮기거나 가두지도 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 이름을 받는 파라미터가 없습니다. 공통 계약(`CoreIconContract`)에는 `icon`과 `iconStyle`만 있어, 이름을 붙이는 코드는 위처럼 플랫폼마다 다릅니다. |
| 공통 | 오른쪽에서 왼쪽으로 읽는 화면에서도 `Icon`은 글리프를 좌우로 뒤집지 않습니다. 방향을 뜻하는 아이콘은 방향에 맞는 것을 골라 넣습니다. |
| Flutter | 시스템의 글자 크기 설정(`MediaQuery`의 `textScaler`)은 아이콘 크기에 반영되지 않습니다. Web의 아이콘은 `rem`이라 브라우저의 루트 글자 크기를 따릅니다. |
| Flutter | 번들 밖 아이콘은 데이터를 받기 전까지 빈 상자이고, 받지 못하면 그대로 남습니다. 뜻이 있는 아이콘의 이름은 위처럼 `Icon` 바깥에 붙이세요. |
| Web | 번들 밖 아이콘의 서버 렌더 마크업에는 그림이 없습니다. 브라우저에서 Iconify 스크립트가 실행되고 데이터가 있어야 보입니다. |

모든 컴포넌트에 함께 적용되는 항목은 [전역 접근성 축](/accessibility)에 정리되어 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`icon` · `iconStyle` · `withStyle`은 두 플랫폼이 같습니다. 그리는 방식과 불러오는 방식은 각 플랫폼을 따릅니다.

| 항목 | Flutter | Web |
| --- | --- | --- |
| 그리는 것 | `SvgPicture.string` | 번들 아이콘은 인라인 `<svg>`, 그 밖은 `<iconify-icon icon="id">` |
| 크기 | 크기에 `ThemeData.scaling`을 곱한 정사각 상자. 부모의 제약이 있으면 그 제약을 따릅니다. | `width` · `height` · `font-size`를 `rem` 인라인 스타일로 씁니다. 번들 `<svg>`는 글줄에서 `inline-block`, `vertical-align: -0.125em`입니다. |
| 색을 비웠을 때 | `IconTheme`의 색 | `IconTheme`의 색, 없으면 CSS `currentColor` |
| 색 적용 범위 | 글리프 전체 | `currentColor`로 그린 부분 |
| `IconTheme` | Flutter SDK의 것. `IconTheme.merge`로 합칠 수 있습니다. | CoUI의 것(`size` · `color`). 가장 가까운 하나만 읽습니다. |
| 번들 밖 아이콘 | `IconResolver`가 받아 캐시합니다. Flutter Web이 아니면 디스크에도 둡니다. | `iconify-icon` 스크립트가 받아 그립니다. |
| 아이콘 데이터 등록 | `IconResolver.instance.register`. 번들보다 우선합니다. | Iconify의 `addIcon` · `addCollection`. 번들 아이콘은 바꾸지 못합니다. |
| Lucide 획 | 번들 · 받아 온 것 · 등록한 것 모두 | 번들은 `Icon`이, 번들 밖은 CoUI 스크립트가 적용합니다. |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="props-parameters"></a>

## API

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `icon` | `IconName` | 필수 (첫 번째 위치 인자) | 그릴 아이콘 |
| `iconStyle` | `CoreIconStyle?` | `null` | 크기와 색 |

두 플랫폼 모두 `key`를 받습니다.

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 그리는 요소의 id |
| `classes` | `String?` | `null` | 배치용 클래스. 색 클래스와 함께 붙습니다. |
| `css` | `Styles?` | `null` | 인라인 스타일. 크기 · 색 스타일 뒤에 합쳐집니다. |
| `attributes` | `Map<String, String>?` | `null` | HTML 속성(`aria-label`, `aria-hidden`, Iconify 속성 등) |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | DOM 이벤트 |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreIconStyle patch)` | `iconStyle`에 `patch`를 합친 사본. 겹치는 필드는 `patch`가 이깁니다. |
| `copyWith({icon, iconStyle, key})` | 바꾼 값으로 사본을 만듭니다. Web은 `id` · `classes` · `css` · `attributes` · `eventHandlers`도 받으며, `classes`는 기존 값에 덧붙습니다. |

### 아이콘 값

| 이름 | 설명 |
| --- | --- |
| `IconName(prefix, name)` | 세트 접두어와 이름. `const`로 만들 수 있습니다. |
| `IconName.id` | `prefix:name` 형식의 Iconify id |
| `IconName.withPrefix(prefix)` | 접두어만 바꾼 `IconName` |
| `StyledIconName.styles` | `HeroIcons` 상수가 갖는 모양 이름 → 접두어 표. `.solid` · `.mini` · `.micro`가 읽습니다. |
| `IconSvgData(body, width, height)` | SVG 안쪽 마크업과 원본 크기. 모두 이름 있는 인자이고, `width` · `height`의 기본값은 24입니다. |

### `IconResolver` (Flutter)

| 이름 | 설명 |
| --- | --- |
| `IconResolver.instance.preload(icons, {useLocalCache})` | id 목록을 디스크 캐시나 Iconify API에서 미리 받습니다. `useLocalCache`(기본 `true`)를 끄면 디스크를 읽지 않습니다. |
| `IconResolver.instance.register(id, data)` | `IconSvgData`를 직접 등록합니다. |
| `IconResolver.instance.get(id)` | 등록 · 번들 · 메모리 캐시에서 바로 읽습니다. 없으면 `null`입니다. |
| `IconResolver.instance.has(id)` | `get`으로 읽을 수 있는지 알려 줍니다. |
| `IconResolver.instance.loadFromDisk()` | 디스크에 저장된 세트를 모두 메모리로 읽습니다. |
| `IconResolver.instance.clearCache()` | 메모리와 디스크의 캐시를 비웁니다. 직접 등록한 아이콘도 지워지고, 번들 아이콘은 남습니다. |
| `IconResolver.instance.clearMemoryCache()` | 메모리 캐시만 비웁니다. 직접 등록한 아이콘도 지워집니다. |
| `IconResolver.instance.cacheDir` | 디스크 캐시 폴더. 기본값은 `.coui_icons_cache`입니다. |

### 웹 스크립트 함수

`iconScript()`가 받는 이름 있는 인자입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `version` | `String` | `'2.1.0'` | jsDelivr에서 불러올 `iconify-icon` 버전. `src`를 주면 쓰지 않습니다. |
| `src` | `String?` | `null` | Iconify 스크립트 주소 |
| `normalizerSrc` | `String` | `'packages/coui_web/iconify_stroke.js'` | CoUI의 Lucide 획 스크립트 주소 |

### 테마와 기본값

| 이름 | 값 · 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.icon` | `CoreIconTheme?` | 앱 테마의 Icon 자리 |
| `CoreIconTheme.style` | `CoreIconStyle?` | 모든 `Icon`에 적용하는 크기 · 색 |
| `CoreIconStyle.defaultSize` | 24 | 크기를 어디서도 받지 못했을 때의 값 |
| `CoreIconStyle.defaultAmbientSize` | 20 | `CoUIApp` · `CoUIWeb`이 루트 `IconTheme`에 두는 크기의 기본값 |
| `CoreIconStyle.defaultColor` | `onSurface` | Flutter 코드의 마지막 대체색. Flutter의 `IconTheme.of`는 늘 색을 돌려주므로 실제로는 이 값까지 내려가지 않으며, Web은 읽지 않습니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreIconStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `size` | `double?` | Icon size in logical pixels (Flutter) / CSS pixels (Web). `null` inherits it — from the surrounding `IconTheme`, else [defaultSize]. |
| `color` | `CoreColor?` | Icon colour. `null` → inherit. |

<!-- STYLE_TABLE:END -->

<Note>

표의 `null` 설명은 앱 테마 단계를 줄여 적은 것입니다. `iconStyle`에서 비운 필드는 먼저 앱 테마(`CoreIconTheme`)의 값을 쓰고, 그다음 가장 가까운 `IconTheme`을 따릅니다. 아무 값도 없을 때의 색은 [색 섹션](#색)처럼 플랫폼마다 다릅니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="icon/related-button" title="Button">

아이콘을 `leading` · `trailing`이나 버튼 내용으로 넣습니다. 슬롯 아이콘의 스타일은 `buttonStyle`의 `leadingIconStyle` · `trailingIconStyle`로 바꿉니다.

</Card>
<Card demo="icon/related-badge" title="Badge">

짧은 상태 · 개수 라벨입니다. 앞뒤 아이콘 슬롯이 있습니다.

</Card>
<Card demo="icon/related-fab" title="Fab">

화면 위에 떠 있는 동작 버튼입니다. `trigger`에 아이콘을 넣습니다.

</Card>
</Cards>
