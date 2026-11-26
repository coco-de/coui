---
title: Text
description: 일관된 타이포그래피를 제공하는 텍스트 컴포넌트
category: display
platforms: [flutter, web]
related: [link, badge]
tags: [typography, content, display]
---

# Text

`Text` 는 시멘틱 typography 토큰을 적용해 일관된 텍스트 렌더링을 제공하는 컴포넌트입니다. Flutter 와 Web 양쪽이 거의 동일한 사용 패턴을 갖도록 설계되어, 같은 코드 모양으로 양쪽 플랫폼 모두 작성 가능합니다.

## ⚡ 권장 패턴: chain 사용

CoUI Text 의 권장 사용법은 **chain modifier** 입니다. `.bodyMedium` / `.onPrimaryContainer` / `.semiBold` / `.italic` 처럼 token 이름을 chain 으로 적용하면 양쪽 플랫폼이 일관된 결과를 보장합니다.

```dart
// ✅ 권장: chain only
Text('안녕하세요').bodyMedium.semiBold.onPrimaryContainer
Text('오류').bodySmall.onErrorContainer.underline
Text('긴 문장').s14.maxLines(2).overflow(CoreTextOverflow.ellipsis)

// ⚠️ 비권장: 직접 TextStyle 주입
// `style:` 와 같은 직접 prop 은 다른 디자인 시스템과의 호환을 위해 유지
// 되어 있지만, 양쪽 플랫폼의 동작 일치를 보장하기 어려운 케이스가 있어
// 권장하지 않습니다. CoUI 표준 chain 으로 작성하세요.
Text('안녕하세요', style: theme.typography.bodyMedium.copyWith(...))
```

### chain 이 주변 스타일과 합쳐지는 규칙

chain 은 **이름을 댄 속성만** 덮고, 나머지는 둘러싼 텍스트 스타일(슬롯 기본값 · 부모가 깐 스타일)에서 이어받습니다. 양 플랫폼이 같습니다.

- **역할을 댄 chain** (`.titleMedium`, `.bodySmall` …) 은 그 역할로 크기·굵기·행간·자간을 새로 정합니다.
- **역할 없이 굵기 · 색 · 크기만 준 chain** (`.semiBold`, `.onSurfaceVariant`, `.s14` …) 은 그 속성만 바꿉니다. 예를 들어 `titleMedium` 을 깔아 둔 카드 헤더에 `Text('제목').onSurfaceVariant` 를 넣으면 색만 바뀌고 크기와 굵기는 헤더의 `titleMedium` 그대로입니다.

슬롯이 깐 스타일을 버리고 다른 역할로 시작하고 싶으면 역할을 적으세요 — `Text('제목').bodyMedium.onSurfaceVariant`.

## Live Preview

<LivePreview component="text" />

### Per-facet variants

<LivePreview component="text" variants="typography-display,typography-headline,typography-title,typography-body,typography-weight,typography-primitive,colors-brand,colors-status,colors-surface,modifiers,wrap,keep-all,textstyle,opacity,rich" />

## 사용 시기 (When to Use)

**이 컴포넌트를 사용하세요:**
- 시멘틱 typography (display / headline / title / body / label) 가 필요할 때
- 토큰 기반 색상 / 굵기 / 기울임 등 chain 으로 스타일을 표현하고 싶을 때
- light / dark 테마 변경에 자동 반응해야 할 때

**대신 다른 컴포넌트를 사용하세요:**
- `Badge`: 텍스트를 배지 형태로 강조할 때
- `TextField`: 사용자 텍스트 입력이 필요할 때
- `Link`: 클릭 가능한 링크 텍스트가 필요할 때

## 기본 사용법 (Basic Usage)

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
// 기본 텍스트 — bodyMedium + onSurface 자동 적용
Text('안녕하세요')

// chain — 시멘틱 typography
Text('헤딩').headlineLarge
Text('본문').bodyMedium

// chain — 색상
Text('강조').onPrimaryContainer
Text('에러 메시지').onErrorContainer

// chain — 조합 (뒤가 override)
Text('제목').headlineSmall.semiBold.onPrimaryContainer

// TextStyle 직접 — CoUI 토큰 사용 (Flutter SDK 표준)
Text(
  '커스텀',
  style: TextStyle(
    color: cs.primary,
    fontSize: CoreFontSize.s14,
    fontWeight: CoreFontWeight.semiBold.weight,  // .weight: int → FontWeight
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
// 기본 텍스트 — bodyMedium + onSurface 자동 적용
Text('안녕하세요')

// chain — 시멘틱 typography (Flutter 와 동일)
Text('헤딩').headlineLarge
Text('본문').bodyMedium

// chain — 색상 (Flutter 와 동일)
Text('강조').onPrimaryContainer
Text('에러 메시지').onErrorContainer

// chain — 조합 (뒤가 override)
Text('제목').headlineSmall.semiBold.onPrimaryContainer

// TextStyle 직접 — CoUI 토큰 사용 (Flutter 와 같은 파라미터 + 같은 토큰)
Text(
  '커스텀',
  style: TextStyle(
    color: cs.primary,
    fontSize: CoreFontSize.s14,
    fontWeight: CoreFontWeight.scale.semibold,   // .scale.semibold: String 토큰
  ),
)
```

  </TabItem>
</Tabs>

## Props / Parameters

`Text` 는 양 플랫폼에서 같은 이름 `Text` 를 씁니다. Web 은 CoUI 가 소유한 `Text` 컴포넌트이고, Flutter 는 SDK `Text` 위젯을 그대로 쓰며 chain 이 그 위에 얹힙니다 — 따라서 아래 파라미터 이름은 양쪽 동일하고 타입만 플랫폼 native 로 갈립니다.

| 속성 | 타입 (Flutter / Web) | 기본값 | 설명 |
|------|------|--------|------|
| `data` | `String` | 필수 (첫 positional 인자) | 표시할 텍스트 |
| `style` | `TextStyle?` | `null` | 직접 스타일 주입 (chain 권장) |
| `softWrap` | `bool?` | `null` (→ `true`) | 공백에서 줄바꿈 허용 |
| `overflow` | `TextOverflow?` / `CoreTextOverflow?` | `null` | 넘칠 때 처리 (`ellipsis` 등) |
| `maxLines` | `int?` | `null` | 최대 줄 수 클램프 |
| `textAlign` | `TextAlign?` / `CoreTextAlign?` | `null` | 가로 정렬 |
| `textDirection` | `TextDirection?` / `CoreTextDirection?` | `null` | 읽기 방향 (Web → `dir` 속성) |
| `locale` | `Locale?` / `String?` (BCP 47) | `null` | 로케일 (Web → `lang` 속성) |
| `semanticsLabel` | `String?` | `null` | 접근성 이름 override (Web → `aria-label`) |
| `textScaler` | `TextScaler?` / `double?` | `null` | 텍스트 배율 |

`Text.rich(InlineSpan)` 생성자는 `data` 대신 `textSpan` 을 받고 나머지 파라미터는 동일합니다.

Web 전용 `styleBuilder: TextStyleBuilder?` 는 chain modifier 가 build 시점에 토큰을 읽도록 채우는 내부 슬롯입니다 — 직접 넘기는 대신 chain 을 쓰세요.

## chain 메서드

### Typography (시멘틱) — 22

| chain | Tailwind 클래스 |
|---|---|
| `.displayLarge` / `.displayMedium` / `.displaySmall` | `text-display-large` / `text-display-medium` / `text-display-small` |
| `.headlineLarge` / `.headlineMedium` / `.headlineSmall` | `text-headline-large` / `text-headline-medium` / `text-headline-small` |
| `.titleLarge` / `.titleMedium` / `.titleSmall` | `text-title-large` / `text-title-medium` / `text-title-small` |
| `.bodyLarge` / `.bodyMedium` / `.bodySmall` / `.bodyXs` | `text-body-large` / `text-body-medium` / `text-body-small` / `text-body-xs` |
| `.labelXl2` / `.labelXl` / `.labelLarge` / `.labelMedium` / `.labelSmall` / `.labelXs` | `text-label-xl2` / `text-label-xl` / `text-label-large` / `text-label-medium` / `text-label-small` / `text-label-xs` |
| `.codeXs` / `.codeSm` / `.codeMd` | `text-code-xs` / `text-code-sm` / `text-code-md` |

code 역할은 고정폭(`Geist Mono`)이고 줄 높이가 21px 로 고정입니다. Web 에서는 서체가 `text-code-*` 클래스 하나에 함께 실리므로 `font-mono` 를 따로 붙이지 않습니다. 역할별 값과 고르는 기준은 [타이포그래피](/guides/typography) 에 있습니다.

### Font size · line height (primitive) — 21 · 7

역할 없이 크기나 행간 하나만 바꿉니다. `CoreFontSize` · `CoreLineHeight` 와 1:1 입니다.

- 크기: `.s10` `.s11` `.s12` `.s13` `.s14` `.s15` `.s16` `.s18` `.s20` `.s24` `.s28` `.s32` `.s36` `.s40` `.s44` `.s48` `.s52` `.s60` `.s72` `.s96` `.s128`
- 행간: `.h100` `.h120` `.h140` `.h150` `.h160` `.h180` `.h200`

### Font weight (primitive) — 9

`.thin` (100) / `.extraLight` (200) / `.light` (300) / `.regular` (400) / `.medium` (500) / `.semiBold` (600) / `.bold` (700) / `.extraBold` (800) / `.black` (900)

### 색상 (ColorScheme M3 토큰) — 39 + 7 alias

`theme.colorScheme.<token>` chain 으로 노출. **build 시점에 테마에서 값을 읽어** Theme override 자동 반영.

**accent 7 종의 *채움(fill)* 은 텍스트 색에서 빠집니다** — Web 은 제거, Flutter 는 `@Deprecated`. 이유는 아래 "accent 를 텍스트 색으로 쓸 때".

| 카테고리 | chain |
|---|---|
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
| **Aliases** (7) | `.accent` (= `.tertiary`) / `.accentForeground` (= `.onTertiary`) / `.neutral` (= `.outline`) / `.neutralForeground` (= `.onSurfaceVariant`) / `.baseContent` (= `.onSurface`) / `.primaryForeground` (= `.onPrimary`) / `.secondaryForeground` (= `.onSecondary`) |

### accent 를 텍스트 색으로 쓸 때

accent 토큰(`.primary` / `.secondary` / `.tertiary` / `.error` / `.success` / `.warning` / `.info`)은 **채움(fill)** 으로 설계됐고, 그 위에 얹을 전경이 `on*` 로 따로 있습니다. 그래서 **텍스트 색으로는 제공되지 않습니다** — 두 플랫폼 모두 getter 자체가 없어 아래 ❌ 는 컴파일되지 않습니다.

**accent 색조의 텍스트가 필요하면 `.on{Role}Container` 를 쓰세요.**

```dart
// ❌ 두 플랫폼 모두 없음 — 컴파일되지 않는다
Text('디스크 공간 부족').bodyMedium.warning
Text('활성 사용자').bodyMedium.primary

// ✅ 같은 색조, 페이지 위에서 읽히는 톤
Text('디스크 공간 부족').bodyMedium.onWarningContainer
Text('활성 사용자').bodyMedium.onPrimaryContainer
```

#### 왜 통과하던 여섯까지 뺐나

`.warning` 은 처음부터 불가능했습니다. warning 은 `onWarning` 이 백색이 아니라 **흑색**인 유일한 role 이고, 이는 그 fill 이 *설계상 밝다*는 말과 같습니다 — 경고색은 노랑이기 때문입니다. 페이지 위 텍스트로 그리면 1.82:1 이 나오고, fill 을 어둡게 해 고치면 그 위에 얹힌 흑색 전경이 깨집니다.

나머지 여섯은 **통과했습니다** — 실측 4.63:1~7.04:1 로 WCAG 1.4.3 의 4.5:1 위입니다. 뺀 이유는 읽히지 않아서가 아니라 **여유가 그것뿐**이어서입니다. `check_contrast.dart` 가 이 쌍들을 감사한 이유 자체가 "팔레트를 조금만 조정해도 이 선을 넘는다" 였고, 브랜드 색 한 번 조정에 읽히지 않게 되는 표현 수단은 계속 제공할 만한 것이 아닙니다.

그리고 대체 톤은 이미 있었습니다 — 예제들이 이미 `on{Role}Container` 를 쓰고 있었고, 그 톤은 페이지 위에서 감사됩니다.

#### fill 자체는 그대로입니다

`Badge` / `Alert` / `Banner` 의 accent variant 는 채움 + 짝 전경을 계속 씁니다. 바뀐 건 **"채움을 텍스트 색으로 빌려 쓰는" 경로 하나**뿐입니다.

`scripts/guards/tokens/check_accent_text_contrast.sh` 가 7 role 전부에 대해 이 상태를 지킵니다 — getter 가 되살아나면 실패합니다. 그게 없으면 `check_contrast.dart` 에서 그 쌍들을 뺀 것이 "고치기" 가 아니라 "발견을 지우기" 가 됩니다.

### 스타일 modifier — 4

`.italic` / `.underline` / `.lineThrough` / `.overline`

### 어절 단위 줄바꿈 — `.keepAll`

한국어 글자는 기본 줄바꿈에서 **음절 사이에서도** 꺾입니다 — 폭이 모자라면 `리포머 심화 플로우와 회복 스트레` / `칭` 처럼 한 단어가 두 줄로 찢어집니다. `.keepAll` 을 붙이면 어절 사이에서만 줄을 바꿉니다(CSS `word-break: keep-all`). 위 Per-facet variants 의 `keep-all` 이 같은 제목을 같은 폭에 두고 둘을 비교합니다.

```dart
// Flutter · Web 동일
Text('리포머 심화 플로우와 회복 스트레칭').titleMedium.keepAll
Text('오늘 수업은 취소되었습니다.').bodyMedium.keepAll.lineLimit(2)
```

**언제 쓰나**: 한국어 제목, 카드 · 목록 행의 제목, 짧은 라벨처럼 한두 줄로 읽히고 단어가 찢어지면 읽기가 끊기는 글자. 긴 본문에도 쓸 수 있지만 줄 끝이 더 들쭉날쭉해집니다.

**기본값이 아닌 이유**: Flutter 에는 줄바꿈 방식을 고르는 API 가 없어서 체인은 자기가 감싼 `Text` 만 다시 그릴 수 있습니다. 기본으로 켜면 체인을 단 글자와 그냥 `Text` 가 한 화면에서 다르게 꺾이고, Web 은 CSS 상속으로 더 넓게 닿아 두 플랫폼이 갈립니다. 그래서 켜는 자리를 호출자가 정합니다.

**두 플랫폼이 하는 일**

| | Flutter | Web |
|---|---|---|
| 방법 | 어절 안 글자 사이에 보이지 않는 U+2060 WORD JOINER 를 넣은 문자열로 그 `Text` 를 다시 그림 | 그 `Text` 요소에 `word-break: keep-all` + `overflow-wrap: anywhere` |
| 문자열 | 그리는 데만 바뀜 — 스크린 리더가 읽는 이름과 `SelectionArea` 안에서 복사되는 글자는 원문 | 바뀌지 않음 |
| 한 줄보다 긴 어절 | 그 어절 안에서 꺾음 | 그 어절 안에서 꺾음 |

어느 글자 쌍을 잇는지는 두 플랫폼이 `coui_core` 의 `CoreKeepAll` 한 곳을 따릅니다 — 띄어쓰기 · 문장부호 뒤 · 이모지 앞뒤의 줄바꿈 기회는 그대로이고, 숫자와 라틴 글자는 붙어 있는 한글과 한 어절로 묶입니다(`2개`, `iPhone케이스`).

**도달 범위 — 여기까지만 닿습니다**

- 닿는 곳: `.keepAll` 을 단 `Text` 의 글자 — `Text('…')` 의 문자열, `Text.rich` 의 모든 `TextSpan` 글자(span 경계에 걸친 어절도 하나로 잇습니다).
- 닿지 않는 곳: `SelectableText` · 입력 필드처럼 선택 · 편집하는 글자, `.keepAll` 을 단 위젯 안에 들어 있는 다른 `Text`, `.then*` 으로 이은 글자, `WidgetSpan` 안의 위젯. 컴포넌트가 스스로 그리는 라벨에도 닿지 않습니다.
- 한 줄보다 긴 어절이 같은 줄의 다른 글자 뒤에서 시작하면, Web 은 그 어절을 새 줄로 넘긴 뒤 나누고 Flutter 는 그 줄에서부터 나눌 수 있습니다.
- 기본 다국어 평면 밖의 글자(드문 확장 한자 등)는 Chrome 이 글자로 보지 않아 keep-all 에서도 그 앞뒤에서 꺾이고, Flutter 도 같게 맞춥니다.
- Flutter 위젯 테스트에서 `find.text('원문')` 은 그려진 문자열과 비교하므로 맞지 않습니다 — `find.bySemanticsLabel('원문')` 을 쓰세요.

## 스타일 시스템 (Style System)

### TextStyle

#### Flutter

Flutter SDK `TextStyle` 그대로 사용 — 모든 Flutter 표준 prop (`fontSize`, `fontWeight`, `color`, `decoration`, `shadows`, `foreground`, ...) 사용 가능.

```dart
Text('안녕', style: theme.typography.bodyMedium.copyWith(
  fontWeight: FontWeight.w600,
  color: theme.colorScheme.error.toValue(),
))
```

#### Web

Web `TextStyle` 은 **Flutter SDK `TextStyle` 과 동일한 파라미터 이름** 을 사용합니다. 타입만 플랫폼별로 자연스럽게 다릅니다 — 색 · 굵기 · 폰트패밀리는 Tailwind 토큰 `String` (Flutter 는 `Color` / `FontWeight`) 이고, decoration 계열과 `fontStyle` 은 열거형입니다.

```dart
class TextStyle {
  final String? color;                          // 'primary' (Tailwind color token)
  final String? backgroundColor;                // 'surface-container'
  final double? fontSize;                       // CoreFontSize.s14 등
  final String? fontWeight;                     // 'semibold' (CoreFontWeight.scale.*)
  final FontStyle? fontStyle;                   // FontStyle.italic / .normal (coui_web enum)
  final String? fontFamily;                     // 'sans' / 'mono'
  final double? letterSpacing;                  // em
  final double? wordSpacing;                    // em
  final double? height;                         // line-height multiplier
  final CoreTextDecoration? decoration;         // .underline / .overline / .lineThrough / .none
  final String? decorationColor;                // Tailwind color token
  final CoreTextDecorationStyle? decorationStyle; // .solid / .double / .dotted / .dashed / .wavy
  final double? decorationThickness;            // 입력은 px (rem 으로 내보냄)
  final List<Shadow>? shadows;                  // Shadow(color: 'shadow', offset: (dx:, dy:), blurRadius:)
}
```

build 시 token 필드는 Tailwind 클래스로 조립되고 (`text-${color}` · `bg-${backgroundColor}` · `font-${fontWeight}` · `font-${fontFamily}` · `italic` / `not-italic` · decoration utility · `decoration-${decorationColor}`), 수치 필드는 inline CSS 로 나갑니다 (`font-size` / `text-decoration-thickness` 는 `rem`, `line-height` 는 배수, `letter-spacing` / `word-spacing` 은 `em`, `shadows` 는 `text-shadow`). 이 패턴은 코드베이스의 다른 컴포넌트들(`'bg-${cs.primary}'` 등 string-token 보간) 과 일관됩니다.

시멘틱 typography 적용은 chain 으로 (`Text('hi').bodyMedium`) — chain 이 내부적으로 `CoreTypography.coui` 의 토큰을 읽어 `TextStyle` 의 `fontSize`/`fontWeight`/`height`/`letterSpacing` 을 채워줍니다.

<a id="chain-동작-메커니즘"></a>

## 동작 스펙 (Behavior)

체인은 왼쪽부터 적용하고 같은 속성은 뒤의 modifier가 덮습니다. 타이포 역할·색 토큰은 빌드 시점 테마에서 해석합니다. `softWrap`·`overflow`·`maxLines`는 줄바꿈과 넘침 표현을 정하고, `Text.rich`는 문자열 대신 span 트리를 렌더합니다. Text 자체에는 입력·선택 상태·클릭 콜백이 없습니다. 일반 Text의 선택은 Flutter의 주변 SelectionArea나 브라우저 정책에 따릅니다.

```dart
Text('안녕').bodyLarge.semiBold
Text('안녕').headlineSmall.italic.onTertiaryContainer
```

Flutter chain은 WrappedText를 통해 SDK Text의 스타일을 합성하고 Web은 스타일 class와 inline CSS를 가진 `<span>`으로 렌더합니다. `textScaler`는 배율이며 Flutter의 비선형 TextScaler와 Web의 숫자 배율은 같은 타입이 아닙니다. 크기 primitive는 논리 px, Web raw letter/word spacing은 em, line-height는 배수입니다.

## 사용 가이드라인 (Usage Guidelines)

일반 라벨·짧은 텍스트의 시각 스타일에는 Text chain을 사용합니다. 제목·문단·인용의 구조 의미는 [TextBlock](/components/text-block), 명시적인 선택·복사 표면은 [SelectableText](/components/selectable-text), 클릭 가능한 링크는 [Link](/components/link)를 선택합니다.

### ✅ Do

<Callout type="tip">

**시맨틱 typography / 색상은 chain 으로 적용**

```dart
Text('제목').headlineSmall.semiBold.onPrimaryContainer
```

이유: chain 은 build 시점에 `CoreTypography` / `theme.colorScheme` 토큰에서 값을 읽으므로 light/dark 테마 전환에 자동 반응하고, Flutter와 Web이 같은 토큰 이름을 참조해 두 플랫폼 렌더링이 어긋나지 않습니다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**`style:`에 raw 리터럴을 직접 박지 않기**

```dart
// ❌ 하드코딩된 값 — 테마와 무관하게 고정됨
Text(
  '가격',
  style: TextStyle(fontSize: 14, color: Color(0xFF111111)),
)
```

이유: `style:` 프로퍼티는 다른 디자인 시스템과의 호환을 위해 유지되지만, raw 값은 테마 토큰을 거치지 않아 다크모드 전환에 반응하지 않고 Web 쪽 동일 컴포넌트와 값이 갈릴 위험이 있습니다. CoUI 토큰(`CoreFontSize.*` / `cs.*`)을 참조하거나 chain 을 쓰세요.

</Callout>

## 접근성 (Accessibility)

### 역할

**양 플랫폼 모두 `role` 을 내보내지 않습니다** — 이름은 표시되는 문자열 자체에서 나옵니다.

Web `Text` 는 단일 `<span>` 이고, 내보내는 접근성 관련 속성은 `dir` · `lang` · `aria-label` 셋뿐입니다 (`text.dart:445-461`). `Text.rich` 의 각 `TextSpan` 도 자기 `lang` / `aria-label` 만 붙입니다 (`text.dart:499-502`).

Flutter `Text` 는 SDK 위젯 그대로입니다 — 배럴이 `package:flutter/widgets.dart` 를 re-export 하면서 `Icon` 등은 hide 하지만 `Text` 는 그대로 통과시킵니다 (`coui_flutter.dart:25-35`). chain (`.bodyMedium` / `.onSurface` / …) 은 `DefaultTextStyle.merge` 로 스타일만 얹고 semantics 를 건드리지 않으므로 (`text.dart:1238-1246`), 텍스트 노드의 semantics 는 `RichText` / `RenderParagraph` 가 자동으로 만듭니다.

### 키보드

처리하는 키가 없습니다. Web `Text` 는 이벤트 핸들러 파라미터를 아예 노출하지 않고 (`text.dart:252-265`), Flutter SDK `Text` 도 제스처를 갖지 않습니다. 텍스트 선택이나 링크 동작이 필요하면 `SelectableText` / `Link` 를 쓰세요.

### 스크린 리더

접근 가능한 이름의 출처는 **표시 문자열 자체**입니다 — 평문은 `data`, `Text.rich` 는 span 트리 전체. `semanticsLabel` 을 주면 그것이 이름이 됩니다 (Flutter 는 원문을 빼고 치환, Web 은 `aria-label` 로 얹음 — 아래 제약 참조).

**시각적으로 잘려도 원문 전체가 읽힙니다.** 자르는 일이 양쪽 모두 그리기 단계에서만 일어나기 때문입니다 — Web 은 `maxLines` / `overflow` 를 CSS(`-webkit-line-clamp` 등)로만 적용해 DOM 텍스트를 그대로 두고 (`text.dart:442`), Flutter 는 두 값을 `RichText` 로 넘길 뿐입니다 (`text.dart:977-982`). 즉 말줄임된 문장도 스크린 리더에는 끝까지 안내됩니다.

상태 통보는 없습니다 — live region 배선이 어느 쪽에도 없습니다.

`locale` 의 도달 범위는 플랫폼마다 다릅니다. Web 은 `lang` 속성으로 내보내 보조기술이 언어별 음성으로 전환할 수 있지만 (`text.dart:447`), Flutter 는 그 값을 `RichText` 의 글꼴 선택 입력으로만 전달하므로 (`text.dart:983`) 발음에는 영향을 주지 않습니다. `textDirection` 은 양쪽 다 도달합니다 (Web `dir` `text.dart:446`, Flutter `RichText.textDirection` `text.dart:975`).

### 포커스 관리

포커스 대상이 아닙니다. 양 플랫폼 모두 `FocusNode` / `Focus` / `tabindex` 가 없어 traversal 정지점이 되지 않습니다. 오버레이가 아니므로 진입·이탈·트랩 모두 해당 없습니다.

### 알려진 제약

- **Flutter chain 의 `.semanticsLabel(...)` 은 원문을 대체하지 않습니다.** 이 chain 은 `Semantics(label: value, child: this)` 로 감싸기만 하고 `ExcludeSemantics` 를 두지 않습니다 (`text.dart:886`). 같은 파일의 합성 경로가 SDK 형태(`Semantics(label:) + ExcludeSemantics`)를 그대로 미러하는 것과 대비됩니다 (`text.dart:1004-1009`). 확실히 치환하려면 chain 대신 **생성자 파라미터** `Text('...', semanticsLabel: '...')` 를 쓰세요.
- **Web `semanticsLabel` 은 role 없는 `<span>` 에만 얹힙니다.** `aria-label` 이 붙는 대상이 role 을 갖지 않는 제네릭 요소라 (`text.dart:448`, `:455-461`), 규격상 이름 지정이 허용되는 자리가 아니어서 브라우저·보조기술에 따라 무시될 수 있습니다. 게다가 Web `Text` 는 `UiComponent` 가 아니라 `StatelessComponent` 라 (`text.dart:250`) `attributes` / `id` 가 없어 **그 요소에 role 을 직접 실을 수도 없습니다** — 확실히 이름을 주려면 role 을 가진 조상 요소 쪽에 붙이세요.
- **`.then*` 합성 텍스트는 OS 글자 크기 배율을 따르지 않습니다.** `Text('a').thenText('b')` 는 `textScaler` 를 명시하지 않으면 `TextScaler.noScaling` 으로 렌더되고 (`text.dart:981`), chain 을 거친 수신자에서 떨어지는 경로도 `RichText` 기본값이 같은 `noScaling` 입니다 (`text.dart:766-768`). 단독 `Text` 가 `MediaQuery.textScalerOf` 를 따르는 것과 달라, 시스템 글자 크기를 키운 사용자에게 합성 구간만 커지지 않습니다. Web 은 `rem` 기반이라 이 비대칭이 없습니다 (`text.dart:418-427`).
- **"굵은 텍스트" 접근성 설정은 Flutter 에만 도달합니다.** Flutter 경로는 `MediaQuery.boldTextOf` 를 읽어 폰트 굵기를 올리지만 (`text.dart:960-964`), Web 쪽 `Text` 에는 대응하는 신호가 없습니다 — 플랫폼 기능 차이이며 우회 경로가 없습니다.

### 색상 대비

- 본문 텍스트: 배경 대비 WCAG AA (4.5:1) 이상
- 보조 텍스트 (`.neutralForeground`): 배경 대비 최소 3:1
- light / dark 토글 시 CSS variable (`--coui-on-surface` 등) 자동 반응 — text 색이 테마에 맞게 자동 전환

모션 감소 · 고대비 · 최소 터치 타깃처럼 모든 컴포넌트에 공통으로 적용되는 축은 [전역 접근성 축](/accessibility) 에 정리되어 있습니다.

## 크로스 플랫폼 차이점 (Platform Differences)

**핵심**: 양쪽 모두 같은 CoUI 토큰 (`cs.primary` / `CoreFontWeight.scale.semibold` 등) 을 사용합니다. 단 ColorScheme/Typography 가 *반환하는 타입* 이 플랫폼 native API 에 맞춰 다릅니다.

| prop | Flutter 반환 타입 | Web 반환 타입 |
|---|---|---|
| `cs.primary` | `Color` (dart:ui) — 위젯에 직접 주입 | `String` 'primary' — Tailwind 클래스 보간 |
| `CoreFontWeight.scale.semibold` | (Flutter는 보통 `FontWeight.w600` 사용) | `String` 'semibold' — Tailwind 클래스 보간 |
| `CoreFontSize.s14` / `CoreLineHeight.h160` | `double` | `double` ✅ (양쪽 동일) |
| `decoration` | `TextDecoration` (combinable) | `CoreTextDecoration` enum (단일 값 — 조합 불가) |
| `fontStyle` | Flutter SDK `FontStyle` enum | coui_web `FontStyle` enum (`.italic` / `.normal`) |
| `shadows` | `List<Shadow>` (`Color` / `Offset`) | `List<Shadow>` (토큰 `String` / `(dx:, dy:)` 레코드) |

**파라미터 이름 양쪽 동일** + **토큰 이름 양쪽 동일** — `Text('hi', style: TextStyle(color: cs.primary, fontSize: ..., fontWeight: ...))` 형태로 사용자 코드가 같은 모양. 다른 컴포넌트들 (`Card(cardStyle: CoreCardStyle(backgroundColor: cs.surface))` 등) 과 동일한 토큰 패턴.

**chain 표현 (`Text('hi').bodyMedium.onPrimaryContainer.semiBold`) 은 양쪽 100% 동일.**

## 관련 컴포넌트 (Related Components)

- **[Link](/components/link)**: 클릭 가능한 링크 텍스트
- **[Badge](/components/badge)**: 텍스트 배지 (상태/카운트 강조)
- **[Tooltip](/components/tooltip)**: 호버 시 추가 설명 표시
