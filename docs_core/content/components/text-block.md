---
title: TextBlock
description: 시맨틱 역할(문단·제목·인용)을 가진 prose 텍스트 블록
category: text
platforms: [flutter, web]
related: [text, selectable-text]
tags: [text, typography, prose, heading]
template: v2
source: text/text_block
---

# TextBlock

<a id="live-preview"></a>
<a id="사용법"></a>

## 플레이그라운드

`element`와 `presets`를 바꿔 보며 글 블록을 확인하고, 만들어진 코드를 그대로 복사하세요. 코드는 두 플랫폼에서 같습니다.

<Playground component="text-block" />

`TextBlock`은 글 한 덩어리를 그립니다. `element`는 그 글이 문서에서 하는 일(문단 · 제목 · 인용 · 코드 등)을 정하고, 두 플랫폼은 그에 맞는 글자 모양을 고릅니다. 제목(`h1`–`h6`)은 접근성 정보에도 제목 수준을 담고(플랫폼마다 전해지는 범위는 [접근성](#접근성)에 있습니다), Web은 `element`와 같은 이름의 HTML 태그로 그립니다. 겉모습만 바꾸려면 `element`는 두고 `presets`를 줍니다. 두 플랫폼이 함께 쓰는 속성에는 클릭 콜백 · 선택 · 편집 기능이 없습니다.

<Note>

코드의 `context`는 `build` 메서드가 받는 값입니다. 플레이그라운드의 프리셋은 모두 두 플랫폼에서 `context`를 받습니다. `blockquote`나 `pre`에 프리셋을 주면 두 플랫폼의 글자 색이나 서체가 달라질 수 있습니다([프리셋](#프리셋)).

</Note>

<a id="동작-스펙-behavior"></a>

## 요소

`element`(`CoreTextBlockElement`)는 14가지이고 기본값은 `p`입니다. 크기와 굵기는 CoUI 기본 글자 스케일의 값이고, 제목 크기는 화면 폭 1024 이상일 때의 값입니다.

| `element` | 글자 역할 | 크기 · 굵기 | 제목 수준 |
| --- | --- | --- | --- |
| `p` | `bodyMedium` | 14 Regular | — |
| `span` | `bodyMedium` | 14 Regular | — |
| `h1` | `displaySmall` | 44 Bold | 1 |
| `h2` | `headlineLarge` | 32 Bold | 2 |
| `h3` | `headlineSmall` | 24 Bold | 3 |
| `h4` | `titleLarge` | 20 SemiBold | 4 |
| `h5` | `titleMedium` | 18 SemiBold | 5 |
| `h6` | `titleSmall` | 16 SemiBold | 6 |
| `blockquote` | `bodyMedium` | 14 Regular | — |
| `pre` | `codeMd` (고정폭) | 13 Regular | — |
| `label` | `labelLarge` | 14 Medium | — |
| `strong` | `bodyMedium` + Bold | 14 Bold | — |
| `em` | `bodyMedium` + 기울임 | 14 Regular, 기울임 | — |
| `small` | `bodySmall` | 13 Regular | — |

- 줄 높이는 제목과 `label`이 글자 크기의 140%, `p` · `span` · `blockquote` · `strong` · `em` · `small`이 150%입니다. `pre`의 줄은 21px로 고정입니다.
- 글자 색을 정하는 것은 `blockquote`(`onSurfaceVariant`)와 `pre`(`onSurface`)뿐입니다. 나머지는 둘레의 글자 색을 따릅니다.
- Web은 `element`와 같은 이름의 태그(`<p>`, `<h2>`, `<blockquote>` 등)로 그립니다.

<Preview demo="text-block/headings" />

<Preview demo="text-block/body" />

### 화면 폭에 따른 제목 크기

`h1` · `h2` · `h3`의 크기는 화면 폭에 따라 바뀝니다. 앱 루트(`CoUIApp` · `CoUIWeb`)의 글자 단계를 따르기 때문입니다. 같은 글자 역할을 쓰는 `heading1`–`heading3` 프리셋도 함께 바뀌고, 나머지 요소는 어느 폭에서나 같은 크기입니다.

| `element` | 폭 768 미만 | 폭 768–1023 | 폭 1024 이상 |
| --- | --- | --- | --- |
| `h1` | 28 | 36 | 44 |
| `h2` | 24 | 28 | 32 |
| `h3` | 16 | 20 | 24 |

폭 768 미만에서는 `h3`(16)이 `h4`(20)와 `h5`(18)보다 작게 보입니다. 768–1023에서는 `h3`과 `h4`가 모두 20이고 굵기만 다릅니다(Bold · SemiBold). 폭과 상관없이 크기를 고정하려면 `CoUIApp(typographyTier:)` · `CoUIWeb(typographyTier:)`를 주고, 화면 일부만 고정하려면 `TypographyTierScope`를 씁니다([타이포그래피](/guides/typography)).

## 인용과 코드 상자

`blockquote`와 `pre`만 글 둘레에 상자를 그립니다. 상자의 값과 상자 안 글자는 `textBlockStyle` 하나로 바꿉니다.

| 항목 | `blockquote` | `pre` |
| --- | --- | --- |
| 상자 | 왼쪽 선 3px(`outlineVariant`), 글이 시작하는 쪽 안쪽 여백 16 | `surfaceContainer` 채움, 모서리 4, 안쪽 여백 좌우 6 · 위아래 1 |
| 글자 | `bodyMedium`, `onSurfaceVariant` | `codeMd`(고정폭 13, 줄 21), `onSurface` |

서페이스 스타일의 선 굵기 · 모서리 설정과 밀도의 간격 설정은 이 상자에도 적용됩니다. 상자의 폭, 인용 글의 위치, `pre`의 줄바꿈은 플랫폼마다 다릅니다([플랫폼 차이](#플랫폼-차이)).

<Preview demo="text-block/boxes" />

<Note>

`pre`의 채움(`surfaceContainer`)은 같은 색의 면 위에서는 상자 경계가 구분되지 않습니다. 위 미리보기와 [테마와 스타일](#테마와-스타일)의 미리보기는 상자를 `surface` 색 `Card` 안에 두었고, 바깥 외곽선은 `Card`의 것입니다.

</Note>

## 프리셋

`presets`는 미리 정해 둔 글자 모양(`TextBlockStyle`)의 목록입니다. 두 플랫폼에 같은 이름의 값과 함수가 있습니다. `context`를 받는 함수는 Flutter에서 넘긴 `context`의 테마에서 글자 스케일과 색을 읽어 프리셋을 만듭니다.

| 프리셋 | 코드 | 글자 |
| --- | --- | --- |
| heading1 | `TextBlock.heading1(context)` | `displaySmall` |
| heading2 | `TextBlock.heading2(context)` | `headlineLarge` |
| heading3 | `TextBlock.heading3(context)` | `headlineSmall` |
| heading4 | `TextBlock.heading4(context)` | `titleLarge` |
| lead | `TextBlock.lead(context)` | `titleLarge`, `onSurfaceVariant` |
| lg | `TextBlock.lg(context)` | `titleMedium` |
| sm | `TextBlock.sm(context)` | `labelLarge`, 줄 높이 100% |
| muted | `TextBlock.muted(context)` | `bodySmall`, `onSurfaceVariant` |
| inlineCode | `TextBlock.inlineCode(context)` | `bodySmall`, 고정폭, SemiBold, `surfaceContainer` 배경 |
| paragraph | `TextBlock.paragraph` | 넉넉한 줄 높이. Flutter는 글자 크기의 2배(14에서 28px), Web은 28px 고정 |
| bold | `TextBlock.bold` | Bold |
| italic | `TextBlock.italic` | 기울임 |
| quote | `TextBlock.quote` | 기울임. Web은 글이 시작하는 쪽의 선과 안쪽 여백도 정합니다 |
| truncate | `TextBlock.truncate` | 넘치는 글을 말줄임(…)으로 줄입니다. 줄바꿈 문자가 없는 글은 한 줄이 됩니다. 인라인 태그에서는 Web의 동작이 다릅니다([플랫폼 차이](#플랫폼-차이)) |
| wrap | `TextBlock.wrap` | Web은 긴 낱말을 꺾습니다. Flutter는 바꾸는 것이 없습니다 |

`element`는 문서 속 역할이고, `presets`는 겉모습입니다. 제목처럼 크게 보이는 문단은 `element`를 `p`로 두고 `heading3` 같은 프리셋을 줍니다.

<Preview demo="text-block/presets" />

**프리셋을 합치는 방식은 플랫폼마다 다릅니다.**

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 합치는 방식 | 요소의 글자 위에 프리셋을 차례로 덮습니다. 겹치는 값은 뒤의 프리셋이 이깁니다 | 요소의 글자를 빼고 프리셋의 클래스만 붙입니다 |
| 겹치는 값 | 넘긴 순서대로 | 같은 값을 정하는 클래스끼리는 넘긴 순서가 아니라 스타일시트의 순서가 정합니다 |
| `blockquote` · `pre`에 준 색 없는 프리셋 | 요소의 글자 색이 남습니다 | 요소의 글자 색이 빠지고 둘레의 색을 따릅니다 |
| `pre`에 준 `heading1`–`heading4` · `lead` · `lg` · `sm` · `muted` | 본문 서체로 바뀝니다 | `pre` 태그의 고정폭 서체가 남습니다 |

- Web에서 `bold` · `italic` · `paragraph` · `quote` · `truncate` · `wrap`만 주면 요소의 글자 역할(크기 · 줄 높이 · 굵기 · 자간)이 함께 빠집니다. 프리셋이 정하지 않은 값은 부모에게서 이어받고, 제목 태그에는 브라우저의 기본 제목 크기가 남을 수 있습니다.
- `blockquote` · `pre`가 아닌 요소에서 `bold` · `italic`을 두 플랫폼에서 같게 그리려면 `lg`처럼 크기를 가진 프리셋 뒤에 함께 넘깁니다. 크기를 가진 프리셋은 하나만 넘기세요. 둘을 넘기면 Web은 넘긴 순서가 아니라 스타일시트의 순서로 크기를 정합니다. `heading2`와 `lg`는 어느 순서로 넘겨도 `heading2` 크기로 그립니다.
- Web에서 `presets`를 주면 `blockQuoteTextStyle` · `inlineCodeTextStyle`은 적용되지 않습니다. 상자는 그대로 그립니다.

<Split>

<Code language="dart" title="두 플랫폼에서 같게">
TextBlock(
  text: '결제 요약',
  presets: [
    TextBlock.lg(context),
    TextBlock.bold,
  ],
)
</Code>

<Code language="dart" title="Web에서 제목 크기가 빠짐">
TextBlock(
  text: '결제 요약',
  element: CoreTextBlockElement.h3,
  presets: [TextBlock.bold],
)
</Code>

</Split>

## 자식 목록

`children`이 `null`이 아니면 `text`는 쓰지 않습니다. 빈 목록이어도 같습니다. 자식은 `element`가 고른 글자 모양을 이어받고, 자식이 직접 정한 값이 그 위에 얹힙니다. 놓는 방식은 플랫폼마다 다릅니다.

| 자식 | Flutter | Jaspr Web |
| --- | --- | --- |
| 하나 | 그대로 그립니다 | 태그 안에 그대로 둡니다 |
| 둘 이상 | 시작 쪽에 맞춘 세로 `Column`에 놓아, 자식 하나가 한 줄이 됩니다 | 태그 안에 차례로 둡니다. `Text`처럼 글 안에 흐르는 자식은 한 문장으로 이어집니다 |

한 문단 안에서 글자를 섞을 때, Flutter는 `Text.rich` 하나를 자식으로 넣고 Web은 `Text`를 나란히 넣습니다.

<Split>

<Code language="dart" title="Flutter">
TextBlock(
  children: [
    Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '저장 안 한 '),
          TextSpan(
            text: '변경 사항',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  ],
)
</Code>

<Code language="dart" title="Jaspr Web">
TextBlock(
  children: [
    Text('저장 안 한 '),
    Text('변경 사항').bold,
  ],
)
</Code>

</Split>

<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

제목 · 문단 · 인용 · 코드처럼 문서의 구조를 가진 글에 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 라벨처럼 짧은 글의 글자 모양만 정할 때 | [Text](/components/text) |
| 사용자가 글을 선택해 복사해야 할 때 | [SelectableText](/components/selectable-text) |
| 이름과 값을 짝지어 보일 때 | [DefinitionList](/components/definition-list) |
| 페이지 맨 위에 제목 · 설명 · 행동을 함께 놓을 때 | [PageHeader](/components/page-header) |
| 코드를 구문 강조와 함께 보일 때 | [CodeSnippet](/components/code-snippet) |

<a id="do"></a>
<a id="dont"></a>

### 제목은 요소로, 크기는 프리셋으로

아래 두 쌍은 글자 크기와 굵기가 같습니다(둘째 쌍의 `lead`는 옅은 글자색도 정합니다). 고르는 기준은 겉모습이 아니라 보조 기술에 알려지는 구조입니다.

<Cards columns="2">
<Card demo="text-block/do-heading" tone="do" eyebrow="이렇게 하세요" title="구역 제목은 element">

`element`로 제목 수준을 정하면 글자 모양과 접근성 정보가 함께 정해집니다.

</Card>
<Card demo="text-block/dont-heading-look" tone="dont" eyebrow="이렇게 하지 마세요" title="모양만 제목">

`presets`로 제목처럼 보이게만 하면 요소는 `p`라서 제목으로 알려지지 않습니다.

</Card>
<Card demo="text-block/do-preset" tone="do" eyebrow="이렇게 하세요" title="강조 크기는 presets">

문단은 `p`로 두고 `lead` 같은 프리셋으로 크게 그립니다.

</Card>
<Card demo="text-block/dont-element-size" tone="dont" eyebrow="이렇게 하지 마세요" title="크기용 제목">

크게 보이려고 `h4`를 고르면 이 문장이 문서의 제목이 됩니다.

</Card>
</Cards>

## 테마와 스타일

`blockquote`와 `pre`의 상자와 글자는 `textBlockStyle`(`CoreTextBlockStyle`) 하나로 덮어씁니다. 다른 요소에는 `textBlockStyle`이 닿지 않습니다.

`CoreComponentTheme`에는 TextBlock 자리가 없어 앱 전체에 `textBlockStyle`을 줄 곳은 없습니다. 앱 전체의 글자는 테마의 글자 스케일(`CoreTypography`)을, 색은 색 스킴을 바꾸면 따라옵니다([타이포그래피](/guides/typography)).

<Split>

<Code language="dart" title="인용 선 바꾸기">
TextBlock(
  text: '색은 상태를 알릴 때만 씁니다.',
  element: CoreTextBlockElement.blockquote,
  textBlockStyle: CoreTextBlockStyle(
    blockQuoteBorderColor:
        CoreColor.token(CoreColors.primary),
    blockQuoteBorderWidth:
        CoreStrokeWidth.stroke4,
  ),
)
</Code>

<Code language="dart" title="코드 글자 색만 바꾸기">
TextBlock(
  text: 'flutter pub get',
  element: CoreTextBlockElement.pre,
  textBlockStyle: CoreTextBlockStyle(
    inlineCodeTextStyle: CoreTextStyle(
      color:
          CoreColor.token(CoreColors.primary),
    ),
  ),
)
</Code>

</Split>

`blockQuoteTextStyle` · `inlineCodeTextStyle`에 색이나 굵기만 주면 요소의 기본 글자 위에 그 값만 얹힙니다. 아래 미리보기는 인용 선을 `primary` 4px로, 코드 상자를 `primaryContainer` 채움 · 모서리 8 · `onPrimaryContainer` 글자로 바꾼 것입니다.

<Preview demo="text-block/override" />

### 빠른 덮어쓰기

이미 만든 `TextBlock`에는 `withStyle`로 스타일을 덧붙일 수 있습니다. 생성자의 `textBlockStyle`과 같게 동작하고, 이어서 부르면 겹치는 값은 뒤의 것이 이깁니다.

```dart
TextBlock(
  text: '인용문',
  element: CoreTextBlockElement.blockquote,
).withStyle(
  const CoreTextBlockStyle(
    blockQuoteBorderWidth: CoreStrokeWidth.stroke4,
  ),
)
```

### 값이 정해지는 순서

```text
상자와 상자 안 글자
  CoreTextBlockStyle.default*     // 디자인 시스템 기본값
    → textBlockStyle · withStyle  // 이 블록 하나

요소의 글자와 presets
  Flutter    : element의 글자 위에 presets를 차례로 덮음
  Jaspr Web  : presets가 있으면 element의 글자 대신 presets
```

<a id="접근성-accessibility"></a>

## 접근성

### 역할

| `element` | Flutter | Jaspr Web |
| --- | --- | --- |
| `h1`–`h6` | `Semantics(headingLevel:)`에 1–6을 줍니다 | `<h1>`–`<h6>` 태그 |
| `blockquote` · `pre` | 역할을 더하지 않습니다. 상자는 모습일 뿐입니다 | `<blockquote>` · `<pre>` 태그 |
| 나머지 | 역할을 더하지 않습니다 | 같은 이름의 태그 |

Web은 `role`이나 `aria-*` 속성을 스스로 붙이지 않고, 뜻은 태그가 나타냅니다.

### 키보드

처리하는 키가 없습니다.

### 스크린 리더

| 플랫폼 | 읽히는 방식 |
| --- | --- |
| Flutter | `h1`–`h6`은 제목 수준 정보를 담습니다. Flutter web에는 수준까지 전해지고, iOS와 Android 9 이상에는 제목인지만 전해지며 수준 번호는 전해지지 않습니다. macOS · Windows · Linux 데스크톱 앱에서는 제목으로 알려지지 않을 수 있습니다. 다른 요소는 일반 글로 읽힙니다 |
| Jaspr Web | 제목 태그는 수준과 함께 문서의 제목 목록에 들어갑니다. `blockquote` · `label` 등은 태그의 뜻이 그대로 남습니다. `strong` · `em` · `small`을 따로 알려 주는지는 스크린 리더와 설정에 따라 다를 수 있습니다 |

두 플랫폼이 함께 뜻을 전하는 것은 제목뿐입니다. 그 제목도 Flutter 데스크톱 앱에서는 알려지지 않을 수 있습니다([알려진 제약](#알려진-제약)).

### 포커스 관리

포커스를 받지 않고, 포커스를 옮기지도 않습니다. Flutter는 스스로 글 선택을 켜지 않아, `SelectionArea` 같은 선택 영역 안에서만 글을 선택할 수 있습니다. `CoUIApp`은 Flutter web에서 앱 전체를 선택 영역으로 감싸므로(`enableWebTextSelection`, 기본 `true`) 그 앱의 글은 기본으로 선택됩니다. Web의 글은 브라우저의 기본 선택 동작을 따릅니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 제목 수준은 `element`가 그대로 정합니다. 크기만 키우려고 `h1`을 고르면 문서의 제목 구조도 바뀝니다. 크기만 바꿀 때는 `presets`를 씁니다 |
| 공통 | 폭 768 미만에서는 `h3`이 `h4` · `h5`보다 작게 그려져, 크기 순서가 제목 수준의 순서와 어긋납니다 |
| 공통 | 오른쪽에서 왼쪽으로 쓰는 언어에서도 `blockquote`의 선은 왼쪽에 남고 안쪽 여백만 글이 시작하는 오른쪽으로 옮겨 갑니다. 그래서 글과 선 사이의 간격이 사라지고, 글이 선에 붙거나 겹칠 수 있습니다 |
| Flutter | 제목 말고는 뜻을 알리는 접근성 정보가 없습니다. 강조나 인용이라는 뜻이 꼭 전해져야 하면 글에 담거나 `Semantics` 라벨로 보탭니다 |
| Flutter 데스크톱 | `TextBlock`은 `Semantics`에 `headingLevel`만 주고 `header`는 켜지 않습니다. Flutter 3.47 · 3.50 엔진의 macOS · Windows · Linux 접근성 코드는 `header`만 보고 `headingLevel`은 쓰지 않아, 스크린 리더에 제목으로 알려지지 않을 수 있습니다 |
| Jaspr Web | `label`에 `for` 속성을 붙이지 않습니다. 컨트롤을 `children` 안에 두거나 `attributes: {'for': 컨트롤의 id}`를 줘야 컨트롤과 연결됩니다 |

고대비 · 색 강제 모드처럼 모든 컴포넌트에 함께 적용되는 설정은 [전역 접근성 축](/accessibility)에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

속성과 프리셋의 이름은 같고, 다음은 플랫폼마다 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 구조 | `text`는 `Text`로 그리고, `children`은 `DefaultTextStyle` 아래에 둡니다. 제목은 `Semantics`, `blockquote` · `pre`는 `DecoratedBox` · `Padding`으로 감쌉니다 | `element` 이름의 태그 하나. 상자도 이 태그에 직접 그립니다 |
| 태그의 기본 여백 | 없습니다 | 킷은 브라우저의 기본 여백을 지우지 않습니다. 킷의 Tailwind 설정은 초기화(preflight)를 끄므로, 앱이 기본 스타일을 초기화하지 않으면 `<p>` · 제목 · `<pre>`에는 위아래 여백이, `<blockquote>`에는 위아래 여백과 좌우 40px 여백이 남습니다([빠른 시작](/getting-started#설치)). `classes: 'm-0'`으로 지웁니다. 이 문서 사이트는 자체 초기화 CSS를 써서 미리보기에는 이 여백이 없습니다 |
| 상자 폭 | 부모가 늘이지 않으면 글 크기만큼 | `<blockquote>` · `<pre>`는 블록 요소라 보통 부모 폭을 채웁니다 |
| 인용 글의 위치(기본값) | 선을 안쪽 여백 위에 그려, 글이 상자 가장자리에서 16 안쪽에서 시작합니다 | 선 3px 뒤에 여백 16이 놓여, 글이 19 안쪽에서 시작합니다 |
| 줄바꿈과 공백 | 좁으면 줄을 꺾고, 글의 줄바꿈 문자와 공백을 그대로 그립니다 | 대부분의 요소는 줄바꿈 문자와 이어진 공백을 한 칸으로 합칩니다. `pre`는 그대로 두지만 긴 줄을 꺾지 않아 상자 밖으로 넘칩니다. 가로 스크롤은 `classes: 'overflow-x-auto'`로 붙입니다 |
| 글 안에 흐르는 요소 | 모든 요소가 위젯 하나로 부모의 배치를 따릅니다 | `span` · `label` · `strong` · `em` · `small`은 인라인 태그라, 부모가 줄을 나누지 않으면 앞뒤 글과 한 줄에 이어집니다 |
| 자식이 둘 이상 | 세로 `Column` | 태그 안에 차례로 |
| 프리셋 | 글자 모양(`TextStyle`)을 요소 글자 위에 덮습니다 | 클래스(`TextBlockStyle`)가 요소 글자를 대신합니다([프리셋](#프리셋)) |
| 제목 프리셋(`heading1`–`heading4`) | 글자 역할의 자간 | 자간을 -0.025em으로 바꾸고, 80px의 `scroll-margin`을 더합니다 |
| `inlineCode` 프리셋 | 글자 뒤에만 배경을 칠합니다 | 요소 상자에 배경 · 모서리 4 · 좌우 여백 6을 줍니다. 위아래 여백은 적용되지 않습니다 |
| `quote` 프리셋 | 기울임만 | 기울임에 선의 굵기 · 색과 안쪽 여백을 더합니다. 선 모양(`border-style`)은 정하지 않아, 앱의 초기화 CSS가 정해 주지 않으면 `blockquote`가 아닌 요소에는 선이 보이지 않을 수 있습니다 |
| `truncate` 프리셋 | 폭을 처음 넘는 줄 끝에 말줄임을 붙이고 그 뒤 줄은 버립니다. 글에 줄바꿈 문자가 있으면 그 앞의 짧은 줄은 남습니다 | 줄바꿈 문자까지 공백으로 합쳐 한 줄로 둡니다. `span` · `label` · `strong` · `em` · `small`은 인라인 태그라, 부모의 배치가 블록처럼 만들지 않으면 말줄임 없이 넘칩니다. 그때는 `classes: 'block'`을 줍니다 |
| 텍스트 선택 | 선택 영역 안에서만 됩니다. `CoUIApp`은 Flutter web에서 앱 전체를 선택 영역으로 감쌉니다(`enableWebTextSelection`) | 브라우저 기본 |
| 웹 전용 속성 | — | `id` · `classes` · `css` · `attributes` · `eventHandlers`가 태그에 붙습니다 |

Figma의 TextBlock 속성 `Show title` · `Title` · `Show paragraph` · `Paragraph` · `Show quote` · `Show code`는 Figma 전용이라 코드에 대응하는 API가 없습니다. 코드의 `TextBlock`은 요소 하나를 그리므로, 제목과 문단은 `TextBlock` 두 개로 씁니다.

<a id="props"></a>
<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 이름을 씁니다. `W`는 Flutter의 `Widget`, Web의 `Component`입니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `text` | `String?` | `null` | 그릴 글. `children`이 `null`이 아니면 쓰지 않습니다. 둘 다 없으면 빈 글입니다 |
| `element` | `CoreTextBlockElement` | `CoreTextBlockElement.p` | 문서에서의 역할. 글자 모양과 Web 태그, 제목의 접근성 정보를 정합니다([요소](#요소)) |
| `presets` | `List<TextBlockStyle>?` | `null` | 글자 모양 프리셋([프리셋](#프리셋)) |
| `textBlockStyle` | `CoreTextBlockStyle?` | `null` | `blockquote` · `pre`의 상자와 글자를 덮어쓰는 값 |
| `children` | `List<W>?` | `null` | 자식 목록([자식 목록](#자식-목록)) |

### 웹 전용 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 태그의 `id` |
| `classes` | `String?` | `null` | 태그에 덧붙이는 클래스 |
| `css` | `Styles?` | `null` | 태그에 덧붙이는 인라인 스타일. 상자 값과 겹치면 이쪽이 이깁니다 |
| `attributes` | `Map<String, String>?` | `null` | 태그에 붙이는 HTML 속성 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 태그에 붙이는 DOM 이벤트 처리기 |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreTextBlockStyle patch)` | `textBlockStyle`에 `patch`를 합친 사본을 돌려줍니다. 겹치는 값은 `patch`가 이깁니다 |
| `copyWith(...)` | 바꾼 값으로 사본을 만듭니다. `null`을 넘기면 지금 값이 남습니다. Web은 웹 전용 속성도 받고, `classes`는 바꾸지 않고 지금 값에 덧붙입니다 |

프리셋의 타입 `TextBlockStyle`은 Flutter에서는 `TextStyle`을, Web에서는 클래스 문자열을 담습니다. 위의 [프리셋](#프리셋) 값과 함수로 만듭니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreTextBlockStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `blockQuoteBorderColor` | `CoreColor?` | Left accent-border colour override for `blockquote`. `null` defers to [defaultBlockQuoteBorderColor]. |
| `blockQuoteBorderWidth` | `double?` | Left accent-border stroke width override for `blockquote` (logical px). |
| `blockQuotePadding` | `CoreEdgeInsets?` | Left indent between the `blockquote` accent border and its text. Defaults to the start side only ([defaultBlockQuotePadding]); you can pass a four-side `CoreEdgeInsets` to pad the other sides too. |
| `blockQuoteTextStyle` | `CoreTextStyle?` | Text override for the `blockquote` element — typography role and colour together. `null` defers to [defaultBlockQuoteTextStyle]; a partial style (a colour alone, a weight alone) is laid over the default, so the role the default states is kept. |
| `inlineCodeBackgroundColor` | `CoreColor?` | Surface-fill colour override of the `pre` inline-code box. `null` defers to [defaultInlineCodeBackgroundColor]. |
| `inlineCodeRadius` | `double?` | Corner radius override of the `pre` inline-code surface box (logical px). |
| `inlineCodePadding` | `CoreEdgeInsets?` | Inner padding override inside the `pre` inline-code surface box. |
| `inlineCodeTextStyle` | `CoreTextStyle?` | Text override for the `pre` inline-code box — typography role and colour together. `null` defers to [defaultInlineCodeTextStyle]; a partial style (a colour alone, a weight alone) is laid over the default, so the role the default states is kept. |

<!-- STYLE_TABLE:END -->

<Note>

`blockQuotePadding`의 기본값은 글이 시작하는 쪽에만 16입니다. 표의 "Left indent"는 왼쪽에서 오른쪽으로 쓰는 화면의 모습이고, 오른쪽에서 왼쪽으로 쓰는 화면에서는 이 여백이 오른쪽에 놓입니다. 선은 두 경우 모두 왼쪽입니다. `muted` · `lead` 프리셋의 색(`onSurfaceVariant`)은 `textBlockStyle`로 바뀌지 않습니다.

</Note>

## 관련 컴포넌트

<Cards columns="3">
<Card title="Text" href="/components/text" more="Text 보기">

글자 모양을 체인으로 정하는 글 컴포넌트입니다.

</Card>
<Card title="SelectableText" href="/components/selectable-text" more="SelectableText 보기">

선택해서 복사할 수 있는 글입니다.

</Card>
<Card title="DefinitionList" href="/components/definition-list" more="DefinitionList 보기">

용어와 설명을 한 쌍으로 묶어 보입니다.

</Card>
</Cards>
