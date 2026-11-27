---
title: Text
description: 일관된 타이포그래피를 제공하는 텍스트 컴포넌트
category: display
platforms: [flutter, web]
related: [link, badge]
tags: [typography, content, display]
template: v2
source: text
---

# Text

<a id="live-preview"></a>

## 플레이그라운드

역할 · 색 · 꾸밈 · 줄바꿈을 바꿔 보고, 만들어진 코드를 복사하세요. 코드는 두 플랫폼이 같습니다. 미리보기는 줄바꿈을 볼 수 있도록 폭 240 의 상자에 담습니다. 이 폭은 코드에 들어 있지 않습니다.

<Playground component="text" />

<a id="권장-패턴-chain-사용"></a>
<a id="기본-사용법-basic-usage"></a>
<a id="chain-동작-메커니즘"></a>
<a id="동작-스펙-behavior"></a>

## 체인으로 쓰기

`Text` 는 두 플랫폼에서 이름이 같습니다. Flutter 에서는 SDK 의 `Text` 위젯 그대로이고, Jaspr Web 에서는 CoUI 의 `Text` 컴포넌트입니다. 글의 모양은 `.bodyMedium` · `.onPrimaryContainer` · `.semiBold` · `.italic` 처럼 점으로 이어 붙이는 chain 으로 정하기를 권합니다. 역할과 색은 지금 테마의 값을 따르므로 라이트 · 다크 전환과 테마 교체가 함께 반영됩니다.

<Code language="dart" title="Flutter · Jaspr Web">
// 아무것도 붙이지 않으면 둘러싼 글자 스타일을 따릅니다
Text('안녕하세요')
// 글자 역할
Text('헤딩').headlineLarge
Text('본문').bodyMedium
// 글자색
Text('강조').onPrimaryContainer
Text('에러 메시지').onErrorContainer
// 이어 붙이기
Text('제목').headlineSmall.semiBold.onPrimaryContainer
Text('안내').headlineSmall.italic.onTertiaryContainer
Text('오류').bodySmall.onErrorContainer.underline
Text('긴 문장').s14.lineLimit(2).ellipsis
</Code>

`style:` 파라미터로 `TextStyle` 을 직접 넘길 수도 있습니다. 다른 디자인 시스템의 코드와 맞출 때를 위해 남겨 둔 방법이고, 두 플랫폼의 타입이 달라 권하지 않습니다([TextStyle](#textstyle)).

```dart
// 권하지 않습니다. myStyle 은 플랫폼의 TextStyle 입니다
Text('안녕하세요', style: myStyle)
```

`Text` 에는 입력, 선택 상태, 누름 콜백이 없습니다. Flutter 의 chain 은 SDK `Text` 를 감싸 `DefaultTextStyle` 로 스타일을 얹는 위젯(`WrappedText`)을 돌려줍니다. Web 의 chain 은 새 `Text` 를 돌려주고, 이 `Text` 는 클래스와 인라인 CSS 를 가진 `<span>` 하나를 그립니다.

### chain 이 주변 스타일과 합쳐지는 규칙

아무것도 붙이지 않은 `Text` 는 둘러싼 글자 스타일을 따릅니다. 컴포넌트의 슬롯이나 부모가 정한 스타일이 그것입니다. 앱 루트(`CoUIApp` · `CoUIWeb`)가 `bodyMedium` 과 `onSurface` 를 깔아 두므로, 따로 정한 것이 없는 자리에서는 그 모양입니다.

**역할 없는 chain**(굵기 · 크기 · 색 · 꾸밈 등)은 두 플랫폼 모두 이름 댄 속성만 바꾸고 나머지는 둘러싼 스타일에서 이어받습니다(`.opacity` 의 시작 색은 [꾸밈과 투명도](#꾸밈과-투명도) 참고). 예를 들어 `titleMedium` 이 깔린 카드 헤더에 `Text('제목').onSurfaceVariant` 를 넣으면 색만 바뀌고 크기와 굵기는 헤더의 값 그대로입니다.

**역할 chain**(`.titleMedium` · `.bodySmall` 등)은 크기 · 굵기 · 행간 · 자간을 그 역할의 값으로 새로 정합니다. 색과 서체는 플랫폼에 따라 다릅니다.

| 색 chain 없이 역할 chain 을 붙였을 때 | Flutter | Jaspr Web |
| --- | --- | --- |
| 색 | `onSurface` 로 돌아갑니다. 테마의 그 역할에 색이 있으면 그 색입니다 | 둘러싼 색을 그대로 물려받습니다 |
| code 가 아닌 역할의 서체 | 역할의 서체를 씁니다. 기본 스케일에서는 Pretendard 입니다 | `typography` 가 그 역할에 서체를 정했으면 그 서체를 쓰고, 아니면(기본 스케일) 둘러싼 서체를 물려받습니다 |
| code 역할의 서체 (기본 스케일) | 고정폭 | 고정폭 |

색이 정해진 슬롯에서 역할을 바꿀 때는 색도 함께 적습니다. 예를 들어 `primary` 버튼의 라벨에 `Text('저장').labelMedium` 만 쓰면 Flutter 에서는 라벨이 `onSurface` 로 칠해집니다. `Text('저장').labelMedium.onPrimary` 로 적으면 두 플랫폼의 색이 같습니다. 슬롯이 정한 스타일을 버리고 다른 역할로 시작할 때도 `Text('제목').bodyMedium.onSurfaceVariant` 처럼 역할과 색을 적습니다.

이어 붙이는 순서는 두 플랫폼이 같습니다.

- chain 은 왼쪽부터 적용하고, 같은 속성은 뒤의 것이 덮습니다.
- 역할은 앞에 적은 크기 · 굵기 · 행간 · 서체를 덮습니다. 색 · 기울임 · 자간 · 꾸밈 선은 남습니다. `Text('…').s20.codeSm` 은 12px 이므로 역할을 먼저 적습니다.
- 역할 뒤에 적은 크기 · 굵기 · 행간은 그 속성만 바꿉니다. `.codeMd.s16` 은 16px 글자를 21px 줄에 그리고, 그 뒤의 `.h140` 같은 행간 chain 은 고정 줄 높이를 대신합니다.

<a id="per-facet-variants"></a>
<a id="chain-메서드"></a>

## 체인 메서드

이 절의 이름은 두 플랫폼에 모두 있습니다. Flutter 에만 있는 것은 [API](#flutter-에만-있는-chain)에 따로 적었습니다.

<a id="typography-시멘틱-22"></a>

### 타이포그래피 역할

역할은 22개입니다. Flutter 는 `theme.typography` 의 같은 이름 값을 읽고, Web 은 `text-{role}` 클래스 하나를 붙입니다. 역할 값을 바꿔 chain 에 반영하려면 Flutter 는 `ThemeData` 의 `typography` 를, Web 은 `ThemeConfig.from` 에 넘기는 `typography` 를 바꿉니다([타이포그래피의 쓰는 법](/guides/typography#쓰는-법)).

| chain | Web 의 Tailwind 클래스 |
| --- | --- |
| `.displayLarge` / `.displayMedium` / `.displaySmall` | `text-display-large` / `text-display-medium` / `text-display-small` |
| `.headlineLarge` / `.headlineMedium` / `.headlineSmall` | `text-headline-large` / `text-headline-medium` / `text-headline-small` |
| `.titleLarge` / `.titleMedium` / `.titleSmall` | `text-title-large` / `text-title-medium` / `text-title-small` |
| `.bodyLarge` / `.bodyMedium` / `.bodySmall` / `.bodyXs` | `text-body-large` / `text-body-medium` / `text-body-small` / `text-body-xs` |
| `.labelXl2` / `.labelXl` / `.labelLarge` / `.labelMedium` / `.labelSmall` / `.labelXs` | `text-label-xl2` / `text-label-xl` / `text-label-large` / `text-label-medium` / `text-label-small` / `text-label-xs` |
| `.codeXs` / `.codeSm` / `.codeMd` | `text-code-xs` / `text-code-sm` / `text-code-md` |

code 역할은 기본 스케일에서 고정폭(`Geist Mono`)이고 줄 높이가 21px 로 고정입니다. Web 에서는 서체가 `text-code-*` 클래스 하나에 함께 실리므로 `font-mono` 를 따로 붙이지 않습니다. display · headline 여섯 역할은 화면 폭이 좁아지면 작아집니다. 역할별 값과 고르는 기준은 [타이포그래피](/guides/typography)에 있습니다.

<Preview demo="text/roles-heading" height="hug" />

<Preview demo="text/roles-body" height="hug" />

<a id="font-size-line-height-primitive-21-7"></a>

### 크기 · 행간 · 자간

역할 없이 한 가지만 바꿉니다. 이름은 `CoreFontSize` · `CoreLineHeight` · `CoreLetterSpacing` 의 값을 따릅니다.

- 크기(21개): `.s10` `.s11` `.s12` `.s13` `.s14` `.s15` `.s16` `.s18` `.s20` `.s24` `.s28` `.s32` `.s36` `.s40` `.s44` `.s48` `.s52` `.s60` `.s72` `.s96` `.s128`
- 행간(7개, 글자 크기의 배수): `.h100` `.h120` `.h140` `.h150` `.h160` `.h180` `.h200`
- 자간(6개, em): `.tighter` (-0.05) · `.tight` (-0.025) · `.normalSpacing` (0) · `.wide` (0.025) · `.wider` (0.05) · `.widest` (0.1)

<a id="font-weight-primitive-9"></a>

### 굵기와 서체

굵기는 9개입니다. `.thin` (100) / `.extraLight` (200) / `.light` (300) / `.regular` (400) / `.medium` (500) / `.semiBold` (600) / `.bold` (700) / `.extraBold` (800) / `.black` (900)

서체 chain 은 `.sans`(Pretendard) · `.serif` · `.mono`(Geist Mono, 한글은 Pretendard)입니다. CoUI 가 정한 명조 서체는 없습니다(`CoreFontFamily.serif` 는 빈 문자열). 그래서 `.serif` 는 두 플랫폼의 결과가 같지 않을 수 있습니다.

<Preview demo="text/weights" height="hug" />

크기 · 행간 · 자간 · 서체 chain 을 하나씩 건 모양입니다.

<Preview demo="text/primitives" height="hug" />

<a id="스타일-modifier-4"></a>

### 꾸밈과 투명도

`.italic` / `.underline` / `.lineThrough` / `.overline` 입니다. 꾸밈 선은 글자색을 따릅니다. 선 chain 을 둘 이어 붙이면 뒤의 것 하나만 남습니다.

Flutter 에서는 예외가 있습니다. 글자색을 생성자의 `style:` 에 적고 선 chain 을 붙이면, 선은 그 색이 아니라 chain 이 정한 색으로 그립니다. 색 chain 도 역할 chain 도 없으면 둘러싼 글자색입니다. 이때는 색을 chain 으로 적거나 `style:` 에 `decorationColor` 를 함께 적습니다.

`.opacity(value)` 는 글자색의 알파를 `value`(0~1)로 바꿉니다. 원래 알파에 곱하지 않습니다. 색 chain 뒤에 적고, 한 번만 적습니다. 뒤에 오는 색 chain 은 알파까지 새로 정합니다. 앞에 색 chain 이 없으면 Flutter 는 둘러싼 글자색에서, Web 은 `onSurface` 에서 시작합니다. `style:` 에 적은 색에는 `.opacity` 의 결과가 보이지 않습니다.

<Preview demo="text/modifiers" height="hug" />

### 값을 직접 넘기는 chain

이름 있는 chain 에 없는 값은 아래 메서드로 넘깁니다. 가능하면 위의 이름 chain 이나 `CoreFontSize` 같은 토큰 값을 씁니다.

| chain | 값 |
| --- | --- |
| `.fontSize(value)` | 글자 크기(논리 px) |
| `.fontWeight(value)` | `CoreFontWeight` 의 정수(100~900). 목록에 없는 수는 400 입니다 |
| `.lineHeight(value)` | 행간 배수 |
| `.letterSpacing(value)` | 자간(em) |
| `.decoration(value)` | `CoreTextDecoration` 하나 |
| `.opacity(value)` | 글자색의 알파(0~1) |

<a id="색상-colorscheme-m3-토큰-39-7-alias"></a>

## 글자색

색 chain 은 `theme.colorScheme` 의 같은 이름 색을 그릴 때 읽으므로 테마를 바꾸면 따라 바뀝니다. 이름 있는 색 chain 은 39개입니다.

<Preview demo="text/colors" height="hug" />

| 묶음 | chain |
| --- | --- |
| **Surface** (8) | `.surface` `.surfaceDim` `.surfaceBright` `.surfaceContainerLowest` `.surfaceContainerLow` `.surfaceContainer` `.surfaceContainerHigh` `.surfaceContainerHighest` |
| **On surface + tint** (3) | `.onSurface` `.onSurfaceVariant` `.surfaceTint` |
| **Primary** (3) | `.onPrimary` `.primaryContainer` `.onPrimaryContainer` |
| **Secondary** (3) | `.onSecondary` `.secondaryContainer` `.onSecondaryContainer` |
| **Tertiary** (3) | `.onTertiary` `.tertiaryContainer` `.onTertiaryContainer` |
| **Error** (3) | `.onError` `.errorContainer` `.onErrorContainer` |
| **Success** (3) | `.onSuccess` `.successContainer` `.onSuccessContainer` |
| **Warning** (3) | `.onWarning` `.warningContainer` `.onWarningContainer` |
| **Info** (3) | `.onInfo` `.infoContainer` `.onInfoContainer` |
| **Outline** (2) | `.outline` `.outlineVariant` |
| **Inverse** (3) | `.inverseSurface` `.inverseOnSurface` `.inversePrimary` |
| **Misc** (2) | `.shadow` `.scrim` |

다른 이름도 몇 개 있습니다. `.primaryForeground` 는 `.onPrimary`, `.secondaryForeground` 는 `.onSecondary` 와 같고 두 플랫폼에 있습니다. `.foreground` 는 `.onSurface` 와 같고 Flutter 에만 있습니다.

이름이 있다고 어느 바탕에서나 읽히는 것은 아닙니다. `.surface…` 는 바탕에 쓰는 색이고, `…Container` 는 옅은 채움에 쓰는 색입니다. `.onPrimary` · `.onError` 처럼 채움에 짝이 되는 전경색은 그 채움 위에서 씁니다.

### accent 를 텍스트 색으로 쓸 때

accent 색(`primary` · `secondary` · `tertiary` · `error` · `success` · `warning` · `info`)은 **채움**에 쓰는 색이고, 그 위에 얹는 전경색이 `on*` 로 따로 있습니다. 그래서 이 일곱 이름의 글자색 chain 은 두 플랫폼 모두 없습니다. 아래 ❌ 줄은 컴파일되지 않습니다.

```dart
// ❌ 두 플랫폼 모두 없음
Text('디스크 공간 부족').bodyMedium.warning
Text('활성 사용자').bodyMedium.primary

// ✅ 같은 계열의 글자색
Text('디스크 공간 부족').bodyMedium.onWarningContainer
Text('활성 사용자').bodyMedium.onPrimaryContainer
```

<a id="왜-통과하던-여섯까지-뺐나"></a>

accent 계열의 글자가 필요하면 `.on{Role}Container` 를 씁니다. 옅은 채움 `{role}Container` 와 짝이 되는 색입니다. CoUI 기본 테마의 `primary` 계열은 무채색이라 `.onPrimaryContainer` 는 라이트에서는 검정에, 다크에서는 흰색에 가까운 색입니다. 브랜드 색이 있는 테마에서는 그 테마의 값을 따릅니다.

#### fill 자체는 그대로입니다

`Badge` 의 `filled` 처럼 컴포넌트가 accent 색을 채움으로 쓰고 그 위에 짝 전경색을 얹는 것은 그대로입니다. 없는 것은 채움색을 글자색으로 빌려 쓰는 chain 입니다.

## 줄바꿈과 넘침

| chain | 하는 일 |
| --- | --- |
| `.lineLimit(n)` | 최대 `n` 줄까지 그립니다 |
| `.ellipsis` | 넘친 글을 말줄임표로 줄입니다 |
| `.fade` | Flutter 는 넘치는 끝을 흐리게 그립니다. Web 에는 흐림 효과가 없고 `overflow: hidden` 만 붙입니다 |
| `.visible` | 넘친 글을 상자 밖까지 그립니다 |
| `.keepAll` | 어절 사이에서 줄을 바꿉니다 |

잘라내기(clip) chain 은 없습니다. 위젯을 자르는 `.clip` 확장과 이름이 겹치기 때문입니다. 필요하면 `overflow` 파라미터를 씁니다. `Text` 에 같은 이름의 필드가 있어 `maxLines` · `overflow` · `textAlign` · `softWrap` 이라는 이름의 chain 은 없습니다. 줄 수와 넘침은 위의 chain 이나 파라미터로, `textAlign` 과 `softWrap` 은 파라미터로 적습니다.

<Preview demo="text/wrap" height="hug" />

| 적은 것 | Flutter | Jaspr Web |
| --- | --- | --- |
| `.lineLimit(2)` 만 | 두 줄에서 자르고 말줄임표를 붙이지 않습니다(둘러싼 스타일이 넘침 처리를 정하지 않았을 때) | 두 줄에서 자르고 말줄임표를 붙입니다 |
| `.ellipsis` 만 | 처음 넘치는 줄 끝에 말줄임표를 붙이고 뒤의 줄은 버립니다. 긴 한 문단은 한 줄이 됩니다 | 줄을 바꾸지 않습니다. `<span>` 이 인라인이라, `Text` 가 상자 폭을 차지하는 자리(기본 정렬의 flex 열 자식 등)가 아니면 말줄임표 없이 상자 밖으로 나갑니다 |
| `.lineLimit(1).ellipsis` | 한 줄과 말줄임표 | 한 줄과 말줄임표 |

한 줄 말줄임을 두 플랫폼에서 함께 얻으려면 `.lineLimit(1).ellipsis` 로 적습니다. Web 에서 줄 수를 제한한 `Text` 는 `display` 가 `-webkit-box` 가 되어 자기 줄을 차지합니다. 이때 `overflow` 값을 바꿔도 넘친 줄은 숨겨집니다.

### 어절 단위 줄바꿈 — `.keepAll`

한국어는 기본 줄바꿈에서 **음절 사이에서도** 줄이 바뀝니다. 폭이 모자라면 `리포머 심화 플로우와 회복 스트레` / `칭` 처럼 한 낱말이 두 줄로 갈립니다. `.keepAll` 을 붙이면 어절 사이에서 줄을 바꿉니다(CSS `word-break: keep-all`). 아래는 같은 제목을 같은 폭에 두고 비교한 것입니다.

<Preview demo="text/keep-all" height="hug" />

<Code language="dart" title="Flutter · Jaspr Web">
Text('리포머 심화 플로우와 회복 스트레칭').titleMedium.keepAll
Text('오늘 수업은 취소되었습니다.').bodyMedium.keepAll.lineLimit(2)
</Code>

**언제 쓰나**: 한국어 제목, 카드 · 목록 행의 제목, 짧은 라벨처럼 한두 줄로 읽고 낱말이 갈리면 읽기가 끊기는 글에 씁니다. 긴 본문에도 쓸 수 있지만 줄 끝이 더 들쭉날쭉해집니다.

**기본값이 아닌 이유**: Flutter 에는 줄바꿈 방식을 고르는 API 가 없어 chain 은 자기가 감싼 `Text` 만 다시 그릴 수 있습니다. 기본으로 켜면 chain 을 단 글과 평범한 `Text` 가 다르게 꺾이고, Web 은 CSS 상속으로 더 넓게 닿아 두 플랫폼이 갈립니다. 그래서 켜는 자리를 직접 고릅니다.

| | Flutter | Jaspr Web |
| --- | --- | --- |
| 방법 | 어절 안 글자 사이에 보이지 않는 `U+2060 WORD JOINER` 를 넣은 문자열로 그 `Text` 를 다시 그립니다 | 그 `Text` 요소에 `word-break: keep-all` 과 `overflow-wrap: anywhere` 를 붙입니다 |
| 문자열 | 그릴 때만 바뀝니다. 스크린 리더에 알리는 이름과 선택 영역에서 복사되는 글은 원문입니다 | 바뀌지 않습니다 |
| 한 줄보다 긴 어절 | 그 어절 안에서 줄을 바꿉니다 | 그 어절 안에서 줄을 바꿉니다 |

어느 글자 쌍을 이을지는 `coui_core` 의 `CoreKeepAll` 규칙을 기준으로 합니다. Flutter 는 이 규칙을 직접 쓰고, 이 규칙은 Chrome 의 keep-all 을 따라 만든 것입니다. 띄어쓰기, 문장부호 뒤, 이모지 앞뒤에서는 줄이 바뀔 수 있고, 한글에 붙은 숫자와 라틴 글자는 한 어절로 묶입니다(`2개`, `iPhone케이스`).

**닿는 범위**

- `.keepAll` 을 붙인 `Text` 의 글에 닿습니다. `Text('…')` 의 문자열과 `Text.rich` 의 모든 `TextSpan` 글자입니다. span 경계에 걸친 어절도 하나로 잇습니다.
- Flutter 에서는 `SelectableText` 와 입력 필드의 글, `.keepAll` 을 붙인 위젯 안의 다른 `Text`, `.then*` 으로 이은 글, `WidgetSpan` 안의 위젯에 닿지 않습니다.
- 컴포넌트가 스스로 그리는 라벨에는 닿지 않습니다.
- 한 줄보다 긴 어절이 같은 줄의 다른 글 뒤에서 시작하면, Web 은 그 어절을 새 줄로 넘긴 뒤 나누고 Flutter 는 그 줄에서부터 나눌 수 있습니다.
- 기본 다국어 평면 밖의 글자(드문 확장 한자 등)는 Chrome 이 keep-all 에서 이어 주지 않아 그 앞뒤에서 줄이 바뀔 수 있고, Flutter 도 같게 맞춥니다.
- Flutter 위젯 테스트에서 `.keepAll` 로 다시 그린 글은 `find.text('원문')` 에 맞지 않습니다. `find.bySemanticsLabel('원문')` 을 씁니다.

## 여러 조각으로 된 글

`Text.rich` 는 문자열 대신 `TextSpan` 트리를 받아 한 문단 안에서 조각마다 다른 모양을 줍니다. 바깥의 chain 은 문단 전체에, span 의 `style` 은 그 조각과 아래 조각에 적용됩니다. span 의 `style` 은 chain 이 아니라 `TextStyle` 이라서 색과 굵기를 적는 타입이 플랫폼마다 다릅니다.

<Preview demo="text/rich" />

<Split>

<Code language="dart" title="Flutter">
final colors = Theme.of(context).colorScheme;

Text.rich(
  TextSpan(
    text: '섞어 쓰기: ',
    children: [
      TextSpan(
        text: '안내',
        style: TextStyle(
          color: colors.onInfoContainer.toValue(),
          fontWeight: CoreFontWeight.semiBold.weight,
        ),
      ),
    ],
  ),
).bodyMedium.onSurface
</Code>

<Code language="dart" title="Jaspr Web">
final colors = context.colorScheme;

Text.rich(
  TextSpan(
    text: '섞어 쓰기: ',
    children: [
      TextSpan(
        text: '안내',
        style: TextStyle(
          color: '${colors.onInfoContainer}',
          fontWeight: CoreFontWeight.scale.semibold,
        ),
      ),
    ],
  ),
).bodyMedium.onSurface
</Code>

</Split>

Flutter 는 `WidgetSpan` 과 `recognizer` 를 포함한 SDK 의 span 을 그대로 씁니다. Web 의 `InlineSpan` 은 `TextSpan` 뿐이며, span 의 `TextStyle` 에 적은 `role` 과 `wordBreakKeepAll` 은 적용하지 않습니다.

문장 안의 링크는 `Link.inlineSpan` 을 씁니다. Flutter 는 `InlineSpan` 을 돌려줘 span 트리에 넣고, Web 은 컴포넌트를 돌려줘 `Text` 옆에 둡니다([문장 안의 링크](/components/link#문장-안의-링크)).

### 뒤에 이어 붙이기 (Flutter)

Flutter 에는 위젯 뒤에 span 을 붙이는 `.then(span)` · `.thenText(text)` · `.thenLink(href: …)` 가 있습니다. Web 에는 없습니다.

<Code language="dart" title="Flutter — then 을 먼저, chain 을 뒤에">
const Text('이용하기 전에 확인하세요. ')
    .thenLink(href: '/terms', text: '약관 보기', onPressed: openTerms)
    .bodyMedium
</Code>

`openTerms` 는 약관을 여는 앱의 함수입니다. Flutter 의 문장 속 링크는 `href` 를 스스로 열지 않으므로 여는 동작을 `onPressed` 에 적습니다. 이 링크는 `Tab` 으로 닿지 않습니다([키보드](#키보드)).

- 맨 `Text` 에 `.then*` 을 먼저 붙이고 chain 을 뒤에 적으면 문단 전체에 스타일이 적용됩니다.
- chain 을 먼저 건 뒤에 `.then*` 을 붙이면, 붙인 조각은 둘러싼 글자 스타일을 받지 않습니다. 뒤에 chain 을 더해도 같으므로, 이때는 span 에 `style` 을 직접 적습니다.
- `.thenLink` 는 마지막에 한 번만 붙입니다. 그 뒤에 `.then*` 을 더 붙이면 붙인 조각이 둘러싼 글자 스타일을 받지 않습니다. 링크 뒤에 글이 이어지거나 링크가 둘 이상이면 `Text.rich` 와 `Link.inlineSpan` 을 씁니다.
- `Text.rich` 에 바로 `.then*` 을 붙이면 원래의 span 트리가 그려지지 않습니다. 조각은 `Text.rich` 의 `children` 에 넣습니다.

## 선택과 복사

`Text` 에는 선택을 켜고 끄는 파라미터나 선택 콜백이 없습니다. 평범한 `Text` 를 선택할 수 있는지는 실행하는 곳을 따릅니다.

| 실행하는 곳 | 평범한 `Text` |
| --- | --- |
| Flutter 모바일 · 데스크톱 | `SelectionArea` 같은 선택 영역 안이 아니면 선택되지 않습니다 |
| `CoUIApp` 으로 만든 Flutter web | 기본으로 선택됩니다. `CoUIApp` 이 앱 내용을 선택 영역으로 감쌉니다(`enableWebTextSelection`, 기본 `true`) |
| Jaspr Web | 브라우저의 선택 정책을 따릅니다. 부모가 `user-select: none` 이면 선택되지 않습니다 |

주문 번호처럼 사용자가 꼭 선택해 가져가야 하는 값에는 [SelectableText](/components/selectable-text)를 씁니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- display · headline · title · body · label 처럼 정해진 글자 역할이 필요할 때
- 본문보다 옅은 보조 글을 `.onSurfaceVariant` 로 그릴 때
- 색 · 굵기 · 기울임을 토큰 이름의 chain 으로 정할 때
- 라이트 · 다크 테마 전환을 따라가야 하는 글을 그릴 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 글을 배지 모양으로 강조할 때 | [Badge](/components/badge) |
| 사용자가 글을 입력할 때 | [TextField](/components/text-field) |
| 눌러서 이동하는 글일 때 | [Link](/components/link) |
| 선택과 복사를 보장해야 할 때 | [SelectableText](/components/selectable-text) |
| 제목 · 문단 · 인용처럼 문서 속 역할에 맞는 요소로 적어야 할 때(제목 수준은 두 플랫폼 모두 접근성 정보에 담깁니다) | [TextBlock](/components/text-block) |

<a id="do"></a>
<a id="dont"></a>

<Cards columns="2">
<Card demo="text/do-role-order" tone="do" eyebrow="이렇게 하세요" title="역할을 먼저 적기">

`.bodyMedium.s24` 는 본문 역할에서 크기만 24 로 바꿉니다.

</Card>
<Card demo="text/dont-role-order" tone="dont" eyebrow="이렇게 하지 마세요" title="크기 뒤에 역할 적기">

`.s24.bodyMedium` 은 역할이 크기를 덮어 14 로 보입니다.

</Card>
<Card demo="text/do-error-color" tone="do" eyebrow="이렇게 하세요" title="글로 읽는 색 쓰기">

`.onErrorContainer` 처럼 글자에 쓸 토큰을 고릅니다. 테마가 바뀌면 함께 바뀝니다.

</Card>
<Card demo="text/dont-faint-color" tone="dont" eyebrow="이렇게 하지 마세요" title="구분선 색을 글에 쓰기">

`.outlineVariant` 는 옅은 구분선 색이라 흰 바탕의 글은 읽기 어렵습니다.

</Card>
<Card demo="text/do-keep-all" tone="do" eyebrow="이렇게 하세요" title="한국어 제목에 keepAll">

좁은 자리의 제목은 `.keepAll` 로 낱말을 지킵니다.

</Card>
<Card demo="text/dont-split-word" tone="dont" eyebrow="이렇게 하지 마세요" title="낱말이 갈리게 두기">

기본 줄바꿈은 낱말 가운데에서도 줄을 바꿉니다.

</Card>
</Cards>

### style 에 고정 값을 적지 않기

```dart
// ❌ 테마와 상관없이 고정되는 값 (Flutter)
Text(
  '가격',
  style: TextStyle(fontSize: 14, color: Color(0xFF111111)),
)

// ✅ 토큰을 읽는 chain (두 플랫폼)
Text('가격').bodyMedium.onSurface
```

직접 적은 색과 크기는 테마 토큰을 거치지 않아 다크 모드에 따라 바뀌지 않고, 다른 플랫폼의 같은 화면과 값이 갈리기 쉽습니다. `style:` 을 써야 한다면 `CoreFontSize` 와 `colorScheme` 같은 CoUI 토큰을 적습니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

`Text` 에는 `textStyle` 같은 CoUI 스타일 슬롯이나 컴포넌트 테마가 없습니다. 한 곳의 모양은 chain 으로 바꿉니다. 앱 전체의 글자 크기 · 굵기 · 서체는 `typography` 로(Flutter 는 `ThemeData`, Web 은 `ThemeConfig.from` 에 넘깁니다), 색은 `colorScheme` 으로 바꿉니다. `typography` 를 넘기는 법은 [타이포그래피의 쓰는 법](/guides/typography#쓰는-법)에 있습니다.

### 값이 정해지는 순서

글자 모양은 아래 순서로 정해지며 뒤의 것이 이깁니다.

| 순서 | Flutter | Jaspr Web |
| --- | --- | --- |
| 1 | 둘러싼 `DefaultTextStyle` (앱 루트, 컴포넌트의 슬롯) | 부모에게서 물려받는 CSS |
| 2 | chain. 역할 chain 이 있으면 `bodyMedium` 과 `onSurface` 에서 시작해 chain 을 얹습니다 | chain 이 붙인 클래스와 인라인 CSS. 크기 · 행간 · 자간의 인라인 값은 역할 클래스를 이깁니다 |
| 3 | 생성자의 `style:` 에 적은 속성 (`inherit` 이 기본값일 때) | 생성자의 `style:` 에 적은 필드 |
| 4 | 시스템의 굵은 글자 설정이 켜져 있으면 굵기를 bold 로 바꿉니다 | 해당 없음 |

줄 수와 넘침은 순서가 다릅니다. Flutter 는 생성자의 `maxLines` · `overflow` 가 `.lineLimit` · `.ellipsis` 보다 우선합니다. Web 은 뒤에 붙인 chain 이 생성자 값을 바꿉니다.

### TextStyle

`style:` 은 그 플랫폼의 `TextStyle` 을 받습니다. 파라미터 이름은 비슷하지만 값의 타입이 다릅니다.

<Split>

<Code language="dart" title="Flutter — 토큰으로 직접 적기">
final colors = Theme.of(context).colorScheme;

Text(
  '커스텀',
  style: TextStyle(
    color: colors.onPrimaryContainer.toValue(),
    fontSize: CoreFontSize.s14,
    fontWeight: CoreFontWeight.semiBold.weight,
  ),
)
</Code>

<Code language="dart" title="Jaspr Web — 토큰으로 직접 적기">
final colors = context.colorScheme;

Text(
  '커스텀',
  style: TextStyle(
    color: '${colors.onPrimaryContainer}',
    fontSize: CoreFontSize.s14,
    fontWeight: CoreFontWeight.scale.semibold,
  ),
)
</Code>

</Split>

#### Flutter

Flutter SDK 의 `TextStyle` 그대로입니다. `fontSize` · `fontWeight` · `color` · `decoration` · `shadows` · `foreground` 같은 표준 속성을 모두 쓸 수 있습니다. 테마의 역할 값은 `CoreTextStyle` 이므로, 거기서 시작할 때는 `toValue(theme: theme)` 로 바꾼 뒤 고칩니다.

<Code language="dart" title="Flutter — 역할 값에서 시작하기">
final theme = Theme.of(context);

Text(
  '안녕',
  style: theme.typography.bodyMedium
      .toValue(theme: theme)
      .copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onErrorContainer.toValue(),
      ),
)
</Code>

#### Web

CoUI 의 `TextStyle` 이며 필드는 [API](#textstyle-jaspr-web)에 있습니다. 색 · 굵기 · 서체는 Tailwind 이름 문자열이고, 기울임과 꾸밈 선은 enum 입니다. 그릴 때 이름 필드는 클래스(`text-{color}` · `bg-{backgroundColor}` · `font-{fontWeight}` · `font-{fontFamily}` · `italic` / `not-italic` · 꾸밈 선 클래스 · `decoration-{decorationColor}`)가 되고, 숫자 필드는 인라인 CSS 가 됩니다. `fontSize` 와 `decorationThickness` 는 `rem`, `height` 는 행간 배수(줄 상자는 정수 px 로 맞춤), `letterSpacing` · `wordSpacing` 은 `em`, `decorationStyle` 은 `text-decoration-style` 입니다.

<a id="접근성-accessibility"></a>

## 접근성

### 역할

`Text` 는 두 플랫폼 모두 역할을 따로 정하지 않습니다. 이름은 화면의 문자열에서 나옵니다. `.headlineLarge` 같은 역할 chain 은 보이는 모양만 정하고 제목 수준을 알리지 않습니다. 제목 구조가 필요하면 [TextBlock](/components/text-block)을 씁니다.

Web 의 `Text` 는 `<span>` 하나이며, 접근성에 쓰이는 속성은 `dir` · `lang` · `aria-label` 입니다. `Text.rich` 의 `TextSpan` 은 자기 `lang` 과 `aria-label` 을 붙입니다. Flutter 의 `Text` 는 SDK 위젯 그대로이고, 스타일 chain 은 접근성 정보를 바꾸지 않습니다(`.semanticsLabel` chain 은 예외입니다).

### 키보드

처리하는 키가 없습니다. Web 의 `Text` 에는 이벤트 핸들러 파라미터가 없고, Flutter SDK 의 `Text` 에도 제스처 파라미터가 없습니다. 링크 동작은 [Link](/components/link), 선택은 [SelectableText](/components/selectable-text)를 씁니다.

Flutter 의 `.thenLink` 나 `Link.inlineSpan` 으로 문장에 넣은 링크는 `Tab` 으로 닿지 않습니다. 키보드로 닿아야 하는 링크에는 위젯 `Link` 를 씁니다.

### 스크린 리더

- 이름은 표시하는 문자열입니다. `Text.rich` 는 span 트리의 글입니다.
- 생성자의 `semanticsLabel` 을 주면 그 값을 이름으로 씁니다. Flutter 는 원문을 접근성 정보에서 빼고 이 값으로 바꾸며, Web 은 `aria-label` 을 붙입니다([알려진 제약](#알려진-제약)). Flutter 에서 이름을 바꿀 때는 chain 이 아니라 생성자의 `Text('…', semanticsLabel: '…')` 를 씁니다. Web 에서 이름이 꼭 필요하면 역할이 있는 바깥 요소에 붙입니다.
- `maxLines` · `lineLimit` · 말줄임으로 화면에서 잘려도 접근성 정보에는 원문 전체가 남습니다. 자르는 일은 그릴 때만 일어납니다.
- 글이 바뀌었을 때 스스로 알리는 live region 은 없습니다.
- `locale` 은 Web 에서 `lang` 속성이 됩니다. Flutter 에서는 글꼴 선택에 쓰이고 접근성 정보의 언어 속성으로도 붙습니다. 읽는 음성이 실제로 바뀌는지는 플랫폼과 스크린 리더에 달려 있습니다.
- `textDirection` 은 Web 에서 `dir` 속성, Flutter 에서 문단의 읽기 방향이 됩니다.
- `.keepAll` 을 붙인 글도 원문으로 알립니다.

### 포커스 관리

없음. `Text` 는 포커스를 받지 않고 Tab 정지점이 되지 않습니다. 화면을 덮는 컴포넌트가 아니므로 포커스를 옮기거나 가두는 동작도 없습니다.

### 알려진 제약

- Flutter 의 `.semanticsLabel(...)` chain 은 원문을 대신하지 않습니다. `Semantics(label:)` 로 감쌀 뿐 원문을 접근성 정보에서 빼지 않습니다. 맨 `Text` 에는 같은 이름의 필드가 있어 다른 chain 뒤에서만 부를 수 있습니다.
- Web 의 `semanticsLabel` 은 역할이 없는 `<span>` 에 `aria-label` 로 붙습니다. ARIA 는 이런 일반 요소에 이름 붙이기를 허용하지 않아 브라우저나 스크린 리더가 무시할 수 있습니다. `Text` 에는 `id` · `classes` · `attributes` 파라미터가 없어 그 `<span>` 에 역할을 줄 수도 없습니다. `TextSpan` 의 `semanticsLabel` 도 역할이 없는 `<span>` 의 `aria-label` 입니다.
- Flutter 의 `.then*` 으로 붙인 조각은 시스템 글자 크기 배율을 따르지 않습니다. 맨 `Text` 에 바로 붙이면 문단 전체가 따르지 않으며, 그 `Text` 에 `textScaler` 를 주면 그 값을 씁니다. 평범한 `Text` 는 `MediaQuery` 의 배율을 따릅니다.
- 시스템의 굵은 글자 설정은 Flutter 에만 반영됩니다. Web 의 `Text` 는 이런 설정을 읽지 않습니다.

#### 색상 대비

- 색 chain 은 바탕과의 대비를 검사하지 않습니다. 직접 고른 조합의 대비는 자동으로 보정되지 않습니다.
- WCAG 1.4.3(AA)의 기준은 일반 글자가 바탕과 4.5:1 이상, 큰 글자(24px 이상, 또는 굵은 약 18.7px 이상)가 3:1 이상입니다.
- 라이트 · 다크를 바꾸면 Web 은 `--coui-on-surface` 같은 CSS 변수가, Flutter 는 테마의 `colorScheme` 이 바뀌어 색 chain 이 함께 바뀝니다.

모션 감소 · 고대비 · 최소 터치 타깃처럼 모든 컴포넌트에 공통인 내용은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

[체인 메서드](#체인-메서드)와 [글자색](#글자색)에서 두 플랫폼에 있다고 적은 chain 은 이름이 같습니다. 두 플랫폼 모두 같은 CoUI 토큰을 쓰지만, `TextStyle` 에 넣는 타입과 일부 동작은 다릅니다.

### 타입

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `colorScheme` 의 색을 `TextStyle` 에 넣기 | `CoreColor` 를 `.toValue()` 로 `Color` 로 바꿉니다 | `CoreColor` 를 문자열에 넣어(`'${colors.onSurface}'`) Tailwind 색 이름으로 만듭니다 |
| 굵기 | `FontWeight` (`FontWeight.w600` 또는 `CoreFontWeight.semiBold.weight`) | `String` (`CoreFontWeight.scale.semibold`) |
| `CoreFontSize` · `CoreLineHeight` | `double` | `double` |
| `decoration` | `TextDecoration` (`TextDecoration.combine` 으로 여러 선) | `CoreTextDecoration` 하나 |
| `fontStyle` | Flutter 의 `FontStyle` | `coui_web` 의 `FontStyle` (`.italic` · `.normal`) |
| `shadows` | `List<Shadow>` (`Color` · `Offset`) | `List<Shadow>` (색 이름 문자열 · `(dx:, dy:)` 레코드) |
| `TextStyle` 의 `letterSpacing` · `wordSpacing` | 논리 px | em |
| `textScaler` | `TextScaler` (비선형 배율 가능) | 숫자 배율 |

### 동작

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| chain 을 붙일 수 있는 대상 | 모든 위젯. 안쪽의 맨 `Text` 에 스타일이 내려갑니다 | `Text` 만 |
| chain 결과의 타입 | `Text` 가 아닌 `Widget`(대부분 `TextModifier`) | `Text` |
| 색 chain 없는 역할 chain 의 색 | `onSurface` (테마 역할에 색이 있으면 그 색) | 상속 |
| code 가 아닌 역할 chain 의 서체 | 역할의 서체(정하지 않은 역할은 Pretendard) | 역할에 서체를 정했으면 그 서체, 아니면 상속 |
| 색 chain 없는 `.opacity` | 둘러싼 글자색에서 시작 | `onSurface` 에서 시작 |
| `.opacity` 두 번 | 뒤의 알파가 적용됩니다 | 색 클래스가 올바르게 만들어지지 않으므로 한 번만 씁니다 |
| `.lineLimit` 만 · `.ellipsis` 만 | [줄바꿈과 넘침](#줄바꿈과-넘침)의 표 | [줄바꿈과 넘침](#줄바꿈과-넘침)의 표 |
| `textAlign` | `Text` 가 받은 폭 안에서 정렬합니다 | `<span>` 이 인라인이라 상자 폭을 차지하는 자리(기본 정렬의 flex 열 자식 등)나 줄 수를 제한한 때에 보입니다 |
| 생성자의 `maxLines` · `overflow` 와 chain | 생성자 값이 우선 | 뒤의 chain 이 우선 |
| `textScaler` 와 `TextSpan` | 문단 전체에 적용 | span 의 `TextStyle` 에 직접 적은 `fontSize` 에는 곱하지 않습니다 |
| `TextSpan` 의 종류 | SDK 의 span (`WidgetSpan`, `recognizer` 등) | `TextSpan` 만 |
| 평범한 `Text` 의 선택 | [선택과 복사](#선택과-복사)의 표 | [선택과 복사](#선택과-복사)의 표 |
| 시스템의 굵은 글자 설정 | 반영 | 반영하지 않음 |
| Flutter 에만 있는 chain | [목록](#flutter-에만-있는-chain) | 없음 |

<a id="props-parameters"></a>

## API

### 생성자

`Text(data, …)` 는 문자열을, `Text.rich(textSpan, …)` 는 `InlineSpan` 을 첫 위치 인자로 받습니다. `data` 와 `styleBuilder` 를 뺀 아래 파라미터는 두 플랫폼의 두 생성자에 모두 있습니다. 타입이 다른 것은 Flutter / Web 순서로 적었습니다.

| 이름/속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `data` | `String` | 필수 | 표시할 글. `Text.rich` 에는 없고 대신 `textSpan` 을 받습니다 |
| `style` | `TextStyle?` | `null` | 직접 적는 스타일. chain 보다 우선합니다 |
| `softWrap` | `bool?` | `null` | `false` 면 줄을 바꾸지 않습니다. `null` 이면 둘러싼 설정을 따르며 보통 줄을 바꿉니다 |
| `overflow` | `TextOverflow?` / `CoreTextOverflow?` | `null` | 넘친 글의 처리 |
| `maxLines` | `int?` | `null` | 최대 줄 수 |
| `textAlign` | `TextAlign?` / `CoreTextAlign?` | `null` | 가로 정렬 |
| `textDirection` | `TextDirection?` / `CoreTextDirection?` | `null` | 읽기 방향. Web 은 `dir` 속성 |
| `locale` | `Locale?` / `String?` (BCP 47) | `null` | 언어. Web 은 `lang` 속성 |
| `semanticsLabel` | `String?` | `null` | 접근성 이름. Web 은 `aria-label` |
| `textScaler` | `TextScaler?` / `double?` | `null` | 글자 배율. `null` 이면 Flutter 는 `MediaQuery` 의 배율을 따르고, Web 은 배율을 따로 곱하지 않습니다 |
| `styleBuilder` | `TextStyleBuilder?` (Web 만) | `null` | chain 이 채우는 자리. 직접 넘기지 말고 chain 을 씁니다 |

Flutter SDK 의 `Text` 는 이 밖에도 `strutStyle` · `textWidthBasis` · `textHeightBehavior` · `selectionColor` · `semanticsIdentifier` 같은 SDK 파라미터와 사용 중단된 `textScaleFactor` 를 받습니다. Web 의 `Text` 에는 이 이름들이 없습니다.

### TextSpan

| 이름/속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `text` | `String?` | `null` | 이 조각의 글 |
| `children` | `List<InlineSpan>?` | `null` | `text` 뒤에 이어지는 조각 |
| `style` | `TextStyle?` | `null` | 이 조각과 아래 조각의 스타일 |
| `semanticsLabel` | `String?` | `null` | 이 조각의 접근성 이름 |
| `locale` | `Locale?` / `String?` | `null` | 이 조각의 언어 |

Flutter 의 `TextSpan` 에는 `recognizer` · `mouseCursor` · `onEnter` · `onExit` · `semanticsIdentifier` · `spellOut` 도 있습니다.

### TextStyle (Jaspr Web)

모든 필드는 선택이고 기본값은 `null` 입니다. `null` 인 필드는 둘러싼 스타일을 따릅니다. `copyWith` · `merge` · `withRole` 로 새 값을 만들 수 있고, `merge` 는 넘긴 쪽의 `null` 이 아닌 필드가 이깁니다.

| 이름/속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `color` | `String?` | `null` | Tailwind 글자색 이름 |
| `backgroundColor` | `String?` | `null` | Tailwind 배경색 이름 |
| `fontSize` | `double?` | `null` | 글자 크기(px 값, `rem` 으로 바꿔 씀) |
| `fontWeight` | `String?` | `null` | 굵기 이름 (`CoreFontWeight.scale`) |
| `fontStyle` | `FontStyle?` | `null` | `.italic` · `.normal` |
| `fontFamily` | `String?` | `null` | 서체 이름 (`CoreFontFamily.scale`) |
| `letterSpacing` | `double?` | `null` | 자간(em) |
| `wordSpacing` | `double?` | `null` | 낱말 간격(em) |
| `height` | `double?` | `null` | 행간 배수 |
| `decoration` | `CoreTextDecoration?` | `null` | 꾸밈 선 |
| `decorationColor` | `String?` | `null` | 꾸밈 선의 Tailwind 색 이름 |
| `decorationStyle` | `CoreTextDecorationStyle?` | `null` | `.solid` · `.double` · `.dotted` · `.dashed` · `.wavy` |
| `decorationThickness` | `double?` | `null` | 꾸밈 선 두께(px 값) |
| `shadows` | `List<Shadow>?` | `null` | 글자 그림자 |
| `role` | `String?` | `null` | 글자 역할 이름(`body-medium` 등). 보통은 역할 chain 을 씁니다. span 에서는 적용하지 않습니다 |
| `wordBreakKeepAll` | `bool?` | `null` | 어절 단위 줄바꿈. 보통은 `.keepAll` 을 씁니다. span 에서는 적용하지 않습니다 |

### Shadow (Jaspr Web)

| 이름/속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `color` | `String?` | `null` | 색 토큰 이름(`'shadow'` 처럼). `null` 이면 글자색을 따릅니다 |
| `offset` | `({double dx, double dy})` | `(dx: 0, dy: 0)` | 그림자 위치(CSS px) |
| `blurRadius` | `double` | `0` | 흐림 반경(CSS px) |

### Flutter 에만 있는 chain

| chain | 설명 |
| --- | --- |
| `.color(CoreColor value)` | `colorScheme` 에서 값을 찾아 글자색으로 칠합니다. 대비는 직접 확인합니다 |
| `.decorationColor(CoreColor value)` | 꾸밈 선의 색 |
| `.semanticsLabel(String value)` | 접근성 라벨을 더합니다([알려진 제약](#알려진-제약)) |
| `.foreground` | `.onSurface` 와 같은 색 |
| `.then(InlineSpan span)` · `.thenText(String text)` | 뒤에 조각을 붙입니다([뒤에 이어 붙이기](#뒤에-이어-붙이기-flutter)) |
| `.thenLink(...)` | 뒤에 글 속 링크를 붙입니다. `href`(필수) · `text` · `children` · `onPressed` · `external`(기본 `false`) · `variant`(기본 `defaultVariant`) · `linkStyle` 을 받습니다 |
| `(...)` 호출 | `Text('안녕').bodyMedium(letterSpacing: 0.5)` 처럼 `TextStyle` 속성을 chain 위에 얹습니다. 이름 chain 에 없는 값을 넣는 방법이며, 결과 타입이 `TextModifier` 인 chain 뒤에서 부릅니다. `.fontSize(value)` 처럼 `Widget` 을 돌려주는 메서드 바로 뒤에서는 부를 수 없습니다 |

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="text/related-link" title="Link">

눌러서 이동하는 글에 씁니다. [Link 보기](/components/link)

</Card>
<Card demo="text/related-selectable-text" title="SelectableText">

선택해서 복사해야 하는 글에 씁니다. [SelectableText 보기](/components/selectable-text)

</Card>
<Card demo="text/related-text-block" title="TextBlock">

제목 · 문단 · 인용처럼 문서의 구조를 나타냅니다. [TextBlock 보기](/components/text-block)

</Card>
<Card demo="text/related-badge" title="Badge">

상태 · 개수 · 분류를 짧은 라벨로 강조합니다. [Badge 보기](/components/badge)

</Card>
<Card title="Tooltip">

글이나 컨트롤에 짧은 설명을 덧붙입니다. [Tooltip 보기](/components/tooltip)

</Card>
</Cards>
