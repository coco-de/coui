---
title: MockupCode
description: 코드 편집기 모양의 틀에 짧은 코드와 터미널 출력을 줄 단위로 보여 주는 목업입니다. 줄마다 접두(줄 번호 · 기호)와 뜻(tone)을 정합니다.
category: display
platforms: [flutter, web]
related: [mockup, code-snippet, mockup-browser]
tags: [mockup, code, editor, presentation]
template: v2
source: display/mockup_code
---

# MockupCode

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

MockupCode 는 문서나 소개 화면에서 짧은 코드와 터미널 출력을 코드 편집기 모양의 틀에 담아 보여 줍니다. 마지막 줄의 뜻(`tone`)과 줄 번호를 바꿔 보고, 만들어진 코드를 복사하세요.

<Playground component="mockup-code" />

`tone` 이 `neutral` 이면 `MockupCode.fromString` 코드가, 다른 값이면 줄마다 `CoreCodeLine` 을 적는 `MockupCode.fromList` 코드가 나옵니다. Flutter 와 Web 코드는 같고, 틀의 폭은 부모를 따릅니다.

구문 강조 · 복사 버튼이 필요한 코드 블록에는 [CodeSnippet](/components/code-snippet) 을 씁니다. 목업 틀을 함께 설명하는 개요는 [Mockup](/components/mockup) 입니다.

## 구조

배경과 둥근 모서리를 가진 틀 안에 줄이 위에서 아래로 쌓입니다. 한 줄은 접두와 본문 두 칸입니다. 위젯을 끼우는 슬롯은 없고, 내용은 `lines` 에 담은 글로만 정합니다.

<Anatomy demo="mockup-code/anatomy">
<AnatomyItem part="container" name="Container">

코드 블록의 배경, 모서리, 안쪽 여백입니다. 테두리는 없습니다.

</AnatomyItem>
<AnatomyItem part="label" name="prefix">

`CoreCodeLine.prefix` 입니다. 줄 번호나 `$` · `+` · `-` 같은 기호를 담는 폭이 정해진 칸입니다. `prefix` 가 `null` 인 줄에는 이 칸이 없습니다.

</AnatomyItem>
<AnatomyItem select="span + span" side="right" name="text">

`CoreCodeLine.text` 입니다. 코드나 출력 한 줄이고, 폭이 모자라도 자동으로 줄을 바꾸지 않습니다.

</AnatomyItem>
</Anatomy>

<a id="줄-corecodeline"></a>

## 코드 줄

표시할 내용은 `CoreCodeLine` 목록입니다. 목록의 순서대로 `prefix` 와 `text` 를 그립니다. Web 은 글 안의 공백을 합쳐 그립니다([플랫폼 차이](#플랫폼-차이)).

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `text` | `String` | 필수 | 줄의 코드나 출력 글 |
| `prefix` | `String?` | `null` | 줄 번호나 `+` · `-` 같은 접두 기호 |
| `tone` | `CoreCodeLineTone` | `CoreCodeLineTone.neutral` | 줄의 뜻(명령 · 경로 · 성공 · 실패 등). 색은 `mockupCodeStyle` 의 tone 색 필드가 정합니다. |

### 팩토리

`MockupCode.fromString` 은 문자열을 줄 바꿈 문자(`\n`)에서 나눠 줄을 만듭니다. `showLineNumbers`(기본 `true`)가 켜져 있으면 1부터 센 번호를 `prefix` 로 붙이고, 끄면 `prefix` 를 만들지 않습니다. 모든 줄의 `tone` 은 `neutral` 입니다. 문자열이 줄 바꿈으로 끝나면 빈 줄이 하나 더 생기고, 번호를 켰으면 그 줄에도 번호가 붙습니다.

`MockupCode.fromList` 는 넘긴 목록을 그대로 씁니다. 접두 기호나 `tone` 이 필요하면 `fromList` 나 기본 생성자의 `lines` 를 씁니다.

<Preview demo="mockup-code/from-string" />

```dart
// 1부터 줄 번호를 붙입니다.
MockupCode.fromString('flutter pub get\nflutter run')

// 줄 번호 없이 그립니다.
MockupCode.fromString(
  'flutter pub get\nflutter run',
  showLineNumbers: false,
)
```

### 접두 기호와 정렬

`prefix` 에는 줄 번호뿐 아니라 `$` · `+` · `-` 같은 기호도 넣을 수 있습니다. 접두 칸은 `prefix` 가 `null` 이 아닌 줄에만 생깁니다. 그래서 접두가 있는 줄과 없는 줄을 섞으면 본문의 시작 자리가 어긋납니다. 열을 맞추려면 접두가 필요 없는 줄에 빈 문자열(`prefix: ''`)을 줍니다.

<Preview demo="mockup-code/prefix-symbols" />

```dart
MockupCode.fromList(const [
  CoreCodeLine(text: 'flutter test', prefix: r'$'),
  CoreCodeLine(text: 'All tests passed!', prefix: '', tone: CoreCodeLineTone.success),
])
```

접두 칸의 폭은 글에 맞춰 늘지 않습니다. 기본 폭 28은 고정 폭 글꼴 세 글자 안팎의 자리입니다. 네 자리 줄 번호처럼 더 긴 접두를 쓰면 `mockupCodeStyle` 의 `lineNumberWidth` 를 늘리세요.

<a id="줄-tone-corecodelinetone"></a>

## 줄의 뜻

로그나 터미널 출력은 줄마다 뜻이 다릅니다. 줄에 색을 직접 적지 않고 뜻(`tone`)을 적으면, 색은 스타일과 테마가 정합니다. `tone` 은 본문의 글 색만 바꿉니다. 글꼴과 크기는 그대로이고, 접두의 색은 `tone` 과 상관없이 `prefixTextStyle` 을 따릅니다.

<Preview demo="mockup-code/tones" />

| tone | 뜻 | 색을 바꾸는 필드 | 기본 색 |
| --- | --- | --- | --- |
| `neutral` (기본) | 일반 코드 · 출력 | 따로 없습니다. `textStyle` 의 색을 따릅니다. | `onSurface` |
| `muted` | 명령을 되풀이해 적은 줄, 시각처럼 약하게 보일 글 | `mutedToneColor` | `onSurfaceVariant` |
| `link` | 경로 · URL | `linkToneColor` | `link` |
| `success` | 잘 끝난 단계 | `successToneColor` | `onSuccessContainer` |
| `warning` | 실패는 아니지만 눈여겨볼 것 | `warningToneColor` | `onWarningContainer` |
| `error` | 실패 | `errorToneColor` | `onErrorContainer` |

`link` 는 글 색일 뿐 누를 수 있는 링크를 만들지 않습니다.

```dart
MockupCode.fromList(const [
  CoreCodeLine(text: '> flutter run', prefix: '1', tone: CoreCodeLineTone.muted),
  CoreCodeLine(text: 'http://localhost:8080', prefix: '2', tone: CoreCodeLineTone.link),
  CoreCodeLine(text: 'lib/main.dart:12 failed', prefix: '3', tone: CoreCodeLineTone.error),
])
```

`success` · `warning` · `error` 의 기본 색은 같은 이름의 색이 아니라 컨테이너 위에 쓰는 글 색(`onSuccessContainer` · `onWarningContainer` · `onErrorContainer`)입니다. 브랜드 팔레트를 표준 매핑(`CoreSemanticMappingSet.standard`)으로 읽으면 같은 이름의 상태 색은 코드 블록 배경 위의 글 색으로 쓰기에 대비가 모자랄 수 있습니다. 특히 표준 매핑의 라이트 `warning` 은 밝은 채움색입니다.

한 코드 블록에서만 색을 바꾸려면 해당 필드를 적습니다. `textStyle` 의 색을 바꾸면 `neutral` 줄의 색이 바뀌고, 다른 `tone` 의 줄은 각자의 필드 색을 그대로 씁니다.

```dart
MockupCode.fromList(
  const [
    CoreCodeLine(text: 'Error: build failed', tone: CoreCodeLineTone.error),
  ],
  mockupCodeStyle: const CoreMockupCodeStyle(
    errorToneColor: CoreColor.token(CoreColors.error),
  ),
)
```

<a id="동작-스펙-behavior"></a>

## 상태

MockupCode 는 정적인 표시입니다. 틀과 줄에는 hover · pressed · focus · disabled 상태가 없고, 줄을 누르거나 복사했을 때 부르는 콜백 파라미터도 없습니다.

| 항목 | 동작 |
| --- | --- |
| 순서 | `lines` 의 순서대로 그립니다. |
| 해석 | 구문 분석, 구문 강조, 변경 줄 계산을 하지 않습니다. |
| 편집 · 복사 | 입력 필드가 아니며, 복사 버튼과 복사 콜백이 없습니다. |
| 긴 줄 | 자동으로 줄을 바꾸지 않고 틀에서 잘립니다(배치 섹션). |

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 문서나 소개 화면에서 짧은 코드와 명령을 편집기 모양의 틀로 보여 줄 때
- 터미널 출력이나 로그처럼 줄마다 뜻이 다른 몇 줄을 보여 줄 때

보여 주기 위한 틀입니다. 코드를 편집하는 화면에는 쓰지 않습니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 구문 강조, 복사 버튼, 코드 선택, 긴 줄의 가로 스크롤이 필요할 때 | [CodeSnippet](/components/code-snippet) |
| 추가한 줄과 지운 줄을 비교할 때 | [CodeDiff](/components/code-diff) |
| 브라우저나 앱 창 모양의 틀이 필요할 때 | [MockupBrowser](/components/mockup-browser) |
| 사용자가 여러 줄의 글을 입력해야 할 때 | [TextArea](/components/text-area) |

### 담는 내용

<Cards columns="2">
<Card demo="mockup-code/do-short" tone="do" eyebrow="이렇게 하세요">

틀의 폭에 들어가는 짧은 줄 몇 개를 담습니다. 긴 파일 전체보다 짧은 스니펫에 맞습니다.

</Card>
<Card demo="mockup-code/dont-long" tone="dont" eyebrow="이렇게 하지 마세요">

긴 줄은 틀에서 잘립니다. 가로 스크롤이 없어 뒷부분을 볼 수 없습니다.

</Card>
<Card demo="mockup-code/do-tone-text" tone="do" eyebrow="이렇게 하세요">

뜻이 중요한 줄은 `Error:` 처럼 글에도 적습니다.

</Card>
<Card demo="mockup-code/dont-tone-only" tone="dont" eyebrow="이렇게 하지 마세요">

성공과 실패를 색으로만 나누지 않습니다. `tone` 은 스크린 리더에 전해지지 않고, 색을 구분하기 어려운 사람도 뜻을 놓칠 수 있습니다.

</Card>
</Cards>

## 배치

| 방향 | 크기 |
| --- | --- |
| 폭 | 부모의 폭을 채웁니다. |
| 높이 | 줄 수를 따릅니다. 세로 스크롤은 없습니다. |

- Flutter 에서는 폭이 정해진 부모가 필요합니다. `Row` 안에서는 `Expanded` 나 폭을 정한 `SizedBox` 로 감싸세요.
- Flutter 에서 부모의 높이가 줄을 모두 담지 못하면 넘침(overflow) 오류가 납니다. 높이가 정해진 자리에 줄이 많으면 `SingleChildScrollView` 처럼 세로로 스크롤하는 위젯으로 감싸세요.
- 기본값(크기 배율 1, 표준 밀도, 기본 글자 크기)에서 한 줄은 글의 줄 높이 21과 그 아래 간격 4를 차지하고, 틀의 위아래 여백은 10입니다. 두 줄이면 높이가 70입니다.
- 줄 간격은 마지막 줄 아래에도 붙습니다. 그래서 눈에 보이는 아래 여백은 14로 위 여백보다 4 큽니다.

### 긴 줄

<Preview demo="mockup-code/long-line" />

본문은 폭이 모자라도 줄을 바꾸지 않고 넘친 부분을 자릅니다. Flutter 는 오른쪽 안쪽 여백이 시작되는 곳에서, Web 은 틀의 오른쪽 가장자리에서 자릅니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

보여 줄 내용(`lines`)은 위젯 파라미터로 넘기고, 색 · 글자 모양 · 간격 · 모서리 같은 겉모습은 `mockupCodeStyle`(`CoreMockupCodeStyle`) 하나로 바꿉니다.

<Split>

<Code language="dart" title="코드 블록 하나만 바꾸기">
MockupCode.fromString(
  'flutter pub get\nflutter test\nflutter run',
  mockupCodeStyle: const CoreMockupCodeStyle(
    backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    prefixTextStyle: CoreTextStyle(color: CoreColor.token(CoreColors.link)),
    lineSpacing: CoreSpace.space8,
    lineNumberWidth: CoreSize.size40,
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    mockupCode: CoreMockupCodeTheme(
      style: CoreMockupCodeStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter 와 Web 코드가 같습니다. 아래는 첫 번째 예제의 값으로 그린 코드 블록입니다.

<Preview demo="mockup-code/theming" />

<a id="resolve-chain"></a>

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
CoreMockupCodeStyle 의 기본값            // 디자인 시스템 기본값
  → CoreComponentTheme.mockup.style      // 목업 공유 값 (backgroundColor · borderRadius 만)
  → CoreComponentTheme.mockupCode.style  // 앱 전체의 MockupCode
  → mockupCodeStyle                      // 코드 블록 하나
```

- 목업 공유 값에서 MockupCode 가 받는 필드는 `backgroundColor` 와 `borderRadius` 둘입니다. 이 공유 값은 다른 목업에도 적용됩니다.
- `textStyle` 과 `prefixTextStyle` 은 안의 값 단위로 합쳐집니다. 색만 적어도 기본 글자 역할 `codeSm`(CoUI 기본 타이포그래피에서는 고정 폭 글꼴, 글자 크기 12, 줄 높이 21)은 남습니다.
- `padding` 과 `borderRadius` 는 적은 값으로 통째로 바뀝니다.
- 틀은 `OutlinedContainer` 로 그립니다. 그림자 단계(`elevation`)처럼 MockupCode 가 정하지 않는 값은 `CoreComponentTheme.outlinedContainer` 의 `style` 을 따릅니다.

### 기본값이 있는 곳

기본값은 `coui_core` 의 `CoreMockupCodeStyle` 에 있고, Flutter 와 Web 이 같은 값을 읽습니다. 필드를 한 표로 모은 설명은 [Mockup 문서](/components/mockup#coremockupcodestyle)에 있습니다.

| 이름 | 값 | 쓰이는 곳 |
| --- | --- | --- |
| `CoreMockupCodeStyle.defaultBackgroundColor` | `surfaceContainerLow` | 코드 블록 배경(`backgroundColor`) |
| `CoreMockupCodeStyle.defaultTextStyle` | `codeSm` · `onSurface` | 본문 글자(`textStyle`) |
| `CoreMockupCodeStyle.defaultPrefixTextStyle` | `codeSm` · `onSurfaceVariant` | 접두 글자(`prefixTextStyle`) |
| `CoreMockupCodeStyle.defaultBorderRadius` | `CoreRadius.radius8` | 모서리(`borderRadius`) |
| `CoreMockupCodeStyle.defaultPadding` | 위아래 `space10`, 좌우 `space16` | 안쪽 여백(`padding`) |
| `CoreMockupCodeStyle.defaultLineSpacing` | `CoreSpace.space4` | 줄마다 아래에 두는 간격(`lineSpacing`) |
| `CoreMockupCodeStyle.defaultLineNumberWidth` | `CoreSize.size28` | 접두 칸의 폭(`lineNumberWidth`) |

`tone` 색의 기본값(`defaultMutedToneColor` · `defaultLinkToneColor` · `defaultSuccessToneColor` · `defaultWarningToneColor` · `defaultErrorToneColor`)은 [줄의 뜻](#줄의-뜻)의 표와 같습니다.

- 안쪽 여백은 앱의 밀도를 따릅니다. 기본값은 `compact` 에서 위아래 8 · 좌우 12, `spacious` 에서 위아래 12 · 좌우 20 이 됩니다. 줄 간격의 기본값 4와 접두 칸의 폭은 밀도로 바뀌지 않습니다.
- MockupCode 는 자기 그림자를 정하지 않습니다. 네오 브루탈리즘처럼 평평한 면에도 그림자를 주는 서피스 스타일에서는 두 플랫폼 모두 그 스타일의 그림자가 붙습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

이미 만든 MockupCode 에 `withStyle` 을 이어 스타일을 덧붙일 수 있습니다. 생성자의 `mockupCodeStyle` 처럼 동작하고, 겹치는 필드는 뒤에 이은 값이 이깁니다. `.radius12` · `.surfaceContainer` 처럼 Core 토큰과 이름이 같은 getter 도 있습니다. `.radiusN` 은 `borderRadius` 를, 색 getter 는 `backgroundColor` 를 정합니다.

```dart
// 모서리와 배경
MockupCode.fromString('flutter run').radius12.surfaceContainer

// getter 가 없는 필드는 withStyle 로 덧붙입니다.
MockupCode.fromString('flutter run').radius12.withStyle(
  const CoreMockupCodeStyle(lineSpacing: CoreSpace.space8),
)
```

<Note>

색 getter 는 배경만 바꾸고 글 색은 그대로 둡니다. `.primary` · `.error` 같은 진한 면을 고르면 본문, 접두, `tone` 색이 읽히지 않을 수 있습니다. `.success` · `.warning` · `.error` 는 줄의 `tone` 이 아니라 코드 블록의 배경색을 정합니다.

</Note>

<a id="접근성-accessibility"></a>

## 접근성

MockupCode 는 자기 역할과 이름이 없는 정적인 틀입니다. 보조 기술에는 안의 글이 전해집니다.

### 역할

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | 틀과 줄에 `Semantics` 를 붙이지 않고, 입력 필드도 만들지 않습니다. 접두와 본문은 각각 `Text` 입니다. |
| Jaspr Web | `<div>` 와 `<span>` 으로 그리고 `role` · `aria-*` 를 붙이지 않습니다. `<pre>` · `<code>` 요소가 아닙니다. 넘긴 `attributes` 는 루트 요소에 붙습니다. |

### 키보드

없음. 틀이 처리하는 키가 없고, 입력 · 커서 이동 · 편집 단축키도 없습니다.

### 스크린 리더

접두와 본문은 모두 평범한 글로 전해집니다. 접두에 숨김 표시를 붙이지 않으므로 줄 번호도 함께 읽힙니다. 번호를 읽히고 싶지 않으면 `MockupCode.fromString` 에 `showLineNumbers: false` 를 줘 번호를 만들지 마세요. 줄 번호의 화면 배치만으로 뜻을 전하지 말고, 알아야 할 내용은 글에 적으세요.

줄의 `tone`(성공 · 경고 · 실패 등)은 색에만 담기고 접근성 정보에는 실리지 않습니다. 뜻이 중요한 줄은 `Error:` · `Warning:` 처럼 글에도 담으세요.

코드가 무엇인지 알려야 하면 이름을 직접 붙입니다.

<Split>

<Code language="dart" title="Flutter">
Semantics(
  container: true,
  label: '설치 명령 예시',
  child: MockupCode.fromString('flutter pub get'),
)
</Code>

<Code language="dart" title="Jaspr Web">
MockupCode.fromString(
  'flutter pub get',
  attributes: {'role': 'group', 'aria-label': '설치 명령 예시'},
)
</Code>

</Split>

내용이 바뀐 것을 알리는 라이브 영역은 두 플랫폼 모두 없습니다.

### 포커스 관리

없음. 오버레이나 편집기가 아니어서 틀은 포커스를 받지 않고, 포커스를 옮기거나 가두거나 되돌리지 않습니다.

### 알려진 제약

| 항목 | 내용 |
| --- | --- |
| 코드의 뜻 | 두 플랫폼 모두 보조 기술에 "코드"라는 정보가 전해지지 않습니다. |
| 긴 줄 | 잘린 부분은 스크롤해 볼 수 없습니다. 화면을 확대하거나 폭이 좁아지면 보이는 글이 더 줄 수 있습니다. 읽어야 하는 코드는 [CodeSnippet](/components/code-snippet) 을 쓰세요. |
| 접두 칸 | 폭이 정해져 있어 긴 접두에 맞춰 늘지 않습니다. 넘치면 Flutter 는 접두를 여러 줄로 나눠 그 줄이 높아지고, Web 은 띄어쓰기가 없는 접두가 칸 밖으로 넘쳐 본문과 겹칠 수 있습니다. |
| 들여쓰기 (Web) | 줄 앞의 공백은 보이지 않고, 이어진 공백은 하나로 합쳐집니다. 들여쓰기가 뜻을 가지는 코드에는 맞지 않습니다. |
| 빈 줄 (Web) | 본문이 빈 줄은 접두에도 글이 없으면 한 줄 높이가 생기지 않고 줄 간격만 남습니다. 공백만 있는 글도 빈 글로 취급됩니다. |
| 틀의 경계 | 테두리가 없고 기본 배경이 옅어, 흰 바탕에서는 틀의 경계가 약하게 보입니다. |

#### 색 대비

CoUI 기본 팔레트의 라이트와 다크에서, 기본 배경(`surfaceContainerLow`) 위의 본문 · 접두 · `tone` 색은 모두 글자 대비 4.5:1 을 넘습니다. 배경색이나 글 색을 바꾸거나 다른 팔레트를 쓰면 대비를 다시 확인하세요.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

생성자의 `lines` · `mockupCodeStyle` 과 두 팩토리의 쓰는 법은 두 플랫폼이 같습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 틀과 줄 | `OutlinedContainer` 안의 `Column`. 줄마다 `Row` 하나입니다. | `OutlinedContainer` 안의 `<div>`. 줄마다 `<div>` 하나입니다. |
| 접두 | 폭을 정한 상자 안의 `Text` | 폭을 정한 `<span>` |
| 본문 | `Expanded` 안의 `Text(softWrap: false)` | `white-space: nowrap` 인 `<span>` |
| 긴 줄이 잘리는 곳 | 오른쪽 안쪽 여백이 시작되는 곳 | 틀의 오른쪽 가장자리 |
| 공백 | 적은 대로 그립니다. | 줄 앞의 공백은 사라지고, 이어진 공백과 탭은 공백 하나가 됩니다. |
| `text` 안의 줄 바꿈 문자 | 그 자리에서 줄을 바꿉니다. | 공백 하나로 합쳐집니다. |
| 본문과 접두가 모두 빈 줄 | 빈 글도 한 줄 높이를 차지합니다. | 줄 간격만 남습니다. |
| 글 선택 | `Text` 는 `SelectionArea` 안에서 선택됩니다. Flutter Web 의 `CoUIApp` 은 기본값(`enableWebTextSelection`)으로 선택 영역을 둡니다. | 브라우저의 글 선택을 그대로 씁니다. 접두도 선택할 수 있는 글입니다. |
| 폭 | 폭이 정해진 부모가 필요합니다. | 블록 폭(`w-full`)으로 부모를 채웁니다. |
| 크기 배율 | 여백, 모서리, 줄 간격, 접두 칸에 테마의 크기 배율을 곱합니다. | 여백, 줄 간격, 접두 칸을 `rem` 으로 그려 브라우저의 글자 크기를 따릅니다. |
| 앱 테마의 `outlinedContainer` 에 둔 `padding` · `width` | 적용되지 않습니다. MockupCode 의 값이 우선합니다. | `padding` 은 적용되지 않고 MockupCode 의 안쪽 여백만 남습니다. `width` 는 틀에 적용됩니다. |
| 이벤트 · 의미 더하기 | `GestureDetector` · `Semantics` 같은 감싸는 위젯으로 더합니다. | 루트 요소의 `attributes` · `eventHandlers` 로 더합니다. |
| 웹 전용 속성 | 해당 없음. `key` 를 받습니다. | `tag` · `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="props-parameters"></a>

## API

Flutter 와 Jaspr Web 이 같은 이름을 씁니다. 줄 하나를 나타내는 `CoreCodeLine` 의 속성은 [코드 줄](#코드-줄)에 있습니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `lines` | `List<CoreCodeLine>` | 필수 | 표시할 줄 |
| `mockupCodeStyle` | `CoreMockupCodeStyle?` | `null` | 코드 블록의 겉모습 |

### 팩토리 생성자

| 이름 | 설명 |
| --- | --- |
| `MockupCode.fromString(code, {showLineNumbers, mockupCodeStyle, key})` | 문자열을 줄 바꿈 문자에서 나눕니다. `showLineNumbers` 의 기본값은 `true` 이고, 켜면 1부터 센 번호가 `prefix` 가 됩니다. |
| `MockupCode.fromList(codeLines, {mockupCodeStyle, key})` | 넘긴 `CoreCodeLine` 목록을 그대로 씁니다. |

웹의 두 팩토리는 `id` · `classes` · `css` · `attributes` 도 받습니다. `tag` 와 `eventHandlers` 는 받지 않습니다.

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `tag` | `String` | `'div'` | 루트 요소의 태그 |
| `id` | `String?` | `null` | 루트 요소의 id |
| `classes` | `String?` | `null` | 루트 요소에 더하는 클래스 |
| `css` | `Styles?` | `null` | 루트 요소의 인라인 스타일. 코드 블록의 색과 모서리는 `mockupCodeStyle` 로 바꿉니다. |
| `attributes` | `Map<String, String>?` | `null` | 루트 요소의 HTML 속성 — `role`, `aria-label`, `data-*` |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 루트 요소의 이벤트 |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreMockupCodeStyle patch)` | 지금 스타일에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다. |
| `copyWith({lines, mockupCodeStyle, key})` | 바꾼 값으로 사본을 만듭니다. 웹은 `id` · `classes` · `css` · `attributes` · `eventHandlers` · `tag` 도 받으며, `classes` 는 기존 값을 바꾸지 않고 거기에 더합니다. |
| `.radius0` … `.radius9999` | `CoreRadius` 단계로 `borderRadius` 를 정하는 getter |
| `.primary` · `.secondary` · `.tertiary` · `.surface` · `.surfaceContainer` · `.error` · `.success` · `.warning` · `.info` · `.outline` · `.transparent` | `backgroundColor` 를 정하는 getter |

### 테마

| 이름 | 타입 | 적용 대상 |
| --- | --- | --- |
| `CoreComponentTheme.mockupCode` | `CoreMockupCodeTheme?` | 모든 `MockupCode` (`style`) |
| `CoreComponentTheme.mockup` | `CoreMockupTheme?` | 목업 공유 값(`style`). `MockupCode` 는 `backgroundColor` · `borderRadius` 를 받습니다. |

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="mockup-code/related-mockup" title="Mockup">

브라우저 창, 기기, 코드 블록 모양의 틀을 함께 설명하는 개요입니다. 그림은 그중 가로로 둔 태블릿 틀입니다. [Mockup 문서](/components/mockup)

</Card>
<Card demo="mockup-code/related-mockup-browser" title="MockupBrowser">

주소창과 창 컨트롤이 있는 창 틀입니다. [MockupBrowser 문서](/components/mockup-browser)

</Card>
<Card demo="mockup-code/related-code-snippet" title="CodeSnippet">

구문 강조와 복사 버튼이 있는 코드 블록입니다. [CodeSnippet 문서](/components/code-snippet)

</Card>
<Card demo="mockup-code/related-code-diff" title="CodeDiff">

추가한 줄과 지운 줄을 나눠 보여 줍니다. [CodeDiff 문서](/components/code-diff)

</Card>
</Cards>
