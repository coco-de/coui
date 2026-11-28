---
title: CodeSnippet
description: 코드를 구문 강조와 함께 보여 주고 클립보드에 복사할 수 있는 코드 블록입니다. 줄 번호와 줄 톤 띠를 켤 수 있습니다.
category: display
platforms: [flutter, web]
related: [code-diff, mockup-code, kbd, text]
tags: [code, syntax-highlighting, developer]
template: v2
source: display/code_snippet
---

# CodeSnippet

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

`code` 에 보여 줄 코드를, `mode` 에 언어 이름을 넘깁니다. 두 값은 꼭 있어야 하고, 다른 값을 더하지 않으면 줄 번호 없이 복사 버튼이 있는 코드 블록이 됩니다. 속성을 바꿔 보며 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="code-snippet" />

가장 짧은 모양은 아래와 같습니다. Flutter와 Web 코드가 같습니다.

```dart
CodeSnippet(
  code: '''
void main() {
  print('Hello, CoUI!');
}''',
  mode: 'dart',
)
```

## 구조

코드 블록은 바깥 상자 안에 코드 영역을 두고, 오른쪽 위에 액션과 복사 버튼을 겹쳐 놓습니다.

<Anatomy demo="code-snippet/anatomy">
<AnatomyItem part="container" name="Container">

배경과 모서리, 테두리를 가진 바깥 상자입니다. 기본은 `surfaceContainerLow` 면에 모서리 8이고 테두리는 없습니다.

</AnatomyItem>
<AnatomyItem select="pre" side="top" name="code">

`code` 를 그리는 영역입니다. 글자는 `codeSm` 역할(고정폭 12px, 줄 높이 21px)이고, 안쪽 여백은 위아래 10 · 좌우 12입니다. 긴 줄은 줄바꿈하지 않고 이 영역 안에서 가로로 스크롤합니다.

</AnatomyItem>
<AnatomyItem select="code span" side="top" name="showLineNumbers">

1부터 매기는 줄 번호입니다. 오른쪽에 맞추고 코드와 12를 띄웁니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=actions]" side="top" name="actions">

복사 버튼 앞에 놓는 위젯 목록입니다. 그림에서는 언어를 적은 Badge 하나를 넣었습니다.

</AnatomyItem>
<AnatomyItem select="button[aria-label]" side="right" name="showCopyButton">

`code` 를 클립보드에 쓰는 28 × 28 버튼입니다. 아이콘은 16이고, 상자의 위와 오른쪽에서 6씩 떨어져 있습니다.

</AnatomyItem>
</Anatomy>

<Note>

문서 사이트에서 본문의 그림은 서버가 그린 정적인 미리보기라 복사 버튼이 동작하지 않습니다. 복사 동작은 위 플레이그라운드에서 확인합니다.

</Note>

## 언어와 구문 강조

`mode` 는 어느 문법으로 칠할지 고르는 문자열입니다. 대소문자를 구분합니다.

| `mode` 값 | 칠하는 문법 |
| --- | --- |
| `dart` · `javascript` · `js` · `ts` | Dart |
| `json` | JSON |
| `yaml` · `yml` | YAML |
| `sql` | SQL |
| 그 밖의 값 (`bash` · `SQL` 등) | 없음 — 한 가지 색 |

어느 값이 어느 문법을 쓰는지는 `CoreCodeSnippetContract.grammarOf` 가 정하고 두 플랫폼이 함께 읽습니다. 문법이 없으면 이 함수는 `null` 을 돌려줍니다. 다른 언어의 문법을 빌려 칠하면 틀린 색이 나올 수 있습니다. 예를 들어 Dart 문법은 YAML 에 적은 URL 의 `//` 뒤를 주석으로 읽습니다. JavaScript 와 TypeScript 만 전용 문법 없이 Dart 문법으로 읽습니다.

<Preview demo="code-snippet/languages" />

두 플랫폼 모두 순수 Dart 패키지 `syntax_highlight_lite` 로 칠합니다. Dart 문법은 그 패키지에 들어 있고, JSON · YAML · SQL 문법은 CoUI 패키지가 함께 싣습니다. 색은 조각의 종류마다 테마의 색 토큰을 씁니다.

| 조각 | 색 |
| --- | --- |
| 키워드, `true` · `false` · `null` 같은 언어 상수 | `syntaxKeyword` |
| 타입 · 클래스 이름, 숫자 | `syntaxType` |
| 함수 · 메서드 이름, JSON · YAML 의 키 | `syntaxFunction` |
| 문자열 | `syntaxString` |
| 구두점 · 연산자 · 괄호, 주석 | `onSurfaceVariant` |
| 문법이 오류로 표시한 글 | `onErrorContainer` |
| 그 밖의 글 | 코드 색 (`codeTextStyle.color`, 기본 `onSurface`) |

표는 CoUI 가 정한 대응입니다. 어떤 글이 어느 종류가 되는지는 문법이 나누는 대로입니다. 한 가지 예외로, JSON 문법이 '구분자가 와야 할 자리'라고 오류로 표시한 글은 `syntaxType` 으로 칠합니다. 함께 싣는 JSON 문법은 객체 · 배열 안의 숫자에도 이 표시를 붙이기 때문입니다. 그래서 JSON 에서 이 표시가 붙은 잘못된 글은 오류 색으로 드러나지 않습니다.

### 면과 구문 강조

구문 색은 정해진 면 위에서만 씁니다. 면(`backgroundColor`)은 아래 세 가지로 나뉘고, 강조는 강조 톤에서만 켜집니다. 다른 두 가지에서는 코드 전체가 코드 색 하나로 나옵니다.

- **강조 톤** — 불투명한 `surface` · `surfaceContainerLow`(기본) · `surfaceContainer` · `surfaceContainerHigh` · `errorContainer` · `successContainer` · `warningContainer` · `infoContainer`
- **솔리드 역할 면** — 불투명한 `primary` · `secondary` · `tertiary` · `error` · `success` · `warning` · `info` · `outline`
- **그 밖의 면** — `surfaceContainerHighest` · `primaryContainer` 같은 다른 토큰, 반투명한 토큰, 직접 적은 색, 투명

<Preview demo="code-snippet/faces" />

| 면 | 구문 강조 | 줄 번호와 복사 글리프 |
| --- | --- | --- |
| 강조 톤 | 켜짐 | 번호는 `onSurfaceVariant`, 글리프는 복사 버튼의 글자색 |
| 솔리드 역할 면 | 꺼짐 | 면의 짝 색 — `primary` 면이면 `onPrimary`, `outline` 면은 `surface` |
| 그 밖의 면 | 꺼짐 | 번호는 `onSurfaceVariant`, 글리프는 복사 버튼의 글자색 |

- 판단은 배경의 토큰 이름과 투명도만 보며, 두 플랫폼이 같은 함수(`CoreSyntaxFaces.admits`)를 씁니다.
- 네 가지 구문 색(`syntaxKeyword` · `syntaxType` · `syntaxFunction` · `syntaxString`)은 CoUI 기본 색에서 강조 톤 여덟 면 위의 대비 4.5 : 1 을 기준으로 검사하는 색입니다. 화면에 그릴 때 대비를 재지는 않으므로, 브랜드 색을 쓰면 같은 면에서도 글자가 읽히는지 직접 확인합니다.
- `.primary` 같은 색 getter 는 배경과 코드 색을 함께 정합니다. 마지막에 적은 색 getter 가 둘을 정합니다.
- `backgroundColor` 만 바꾸면 코드 색은 기본 `onSurface` 그대로입니다. 솔리드 역할 면이나 직접 적은 색을 배경으로 쓰면 `codeTextStyle.color` 를 함께 정합니다.
- 솔리드 역할 면의 줄 번호 · 복사 글리프 · 복사 버튼의 포커스 링 색은 면을 getter, `withStyle`, 앱 테마 중 어디서 골라도 같게 따라옵니다. `.primary.surface` 는 기본 색으로 돌아오고 `.surface.primary` 는 `onPrimary` 가 됩니다.
- `lineNumberTextStyle.color`, `copyIconStyle.color`, `copyButtonStyle.focusOutlineStyle` 에 직접 적은 색은 짝 색보다 우선합니다.
- `.transparent` 는 배경을 비우고 코드 색을 `onSurface` 로 정합니다. 뒤에 무엇이 있는지 알 수 없으므로 강조는 꺼집니다.

<a id="줄-톤-line-tones"></a>

## 줄 톤

바뀐 줄이나 오류가 난 줄을 띠로 가리킵니다. `lineTones` 에 줄 번호(1부터)와 톤을 적습니다. 줄은 `code` 를 줄바꿈 문자로 나눠 세고, 코드에 없는 번호는 무시합니다.

<Preview demo="code-snippet/line-tones" />

```dart
CodeSnippet(
  code: "void main() {\n  final greeting = 'Hello, CoUI!';\n  print(greting);\n}",
  mode: 'dart',
  showLineNumbers: true,
  lineTones: {2: CoreCodeLineTone.success, 3: CoreCodeLineTone.error},
)
```

Flutter와 Web 코드가 같습니다.

| 톤 | 띠의 기본 색 | 바꾸는 필드 |
| --- | --- | --- |
| `success` | `successContainer` | `successLineColor` |
| `warning` | `warningContainer` | `warningLineColor` |
| `error` | `errorContainer` | `errorLineColor` |
| 그 밖 | 띠를 그리지 않음 (`neutral` · `muted` · `link`) | 없음 |

- 띠의 높이는 그 줄의 높이이고, 줄 번호 · 코드 · 양옆 안쪽 여백 아래에 깔립니다. 긴 줄이 있으면 띠도 그 줄 끝까지 이어지고, 가로로 스크롤하면 줄과 함께 움직입니다.
- 띠 위의 코드와 줄 번호는 원래 색을 유지합니다.
- `success` · `error` 의 기본 띠 색은 [CodeDiff](/components/code-diff) 가 추가 · 삭제한 줄에 까는 것과 같은 토큰입니다.
- 띠는 색이라서 보조 기술에는 톤을 말로 함께 전합니다(접근성 섹션).

<Note>

솔리드 역할 면에서도 띠는 같은 컨테이너 색이고, 줄 번호와 색 getter 가 정한 코드 색은 면의 짝 색입니다. 그래서 띠 위의 글자가 거의 보이지 않을 수 있습니다. `.primary` 면은 CoUI 기본 라이트 · 다크 색으로 계산하면 `success` · `error` 띠 위의 대비가 1.3 : 1 아래입니다. 줄 톤은 구문 강조가 켜지는 면에서 쓰거나, 띠 색 필드를 면에 맞게 직접 정합니다.

</Note>

줄마다 추가 · 삭제 데이터가 있고 `+` · `-` 표시까지 필요하면 [CodeDiff](/components/code-diff) 를 씁니다. 줄 톤은 보통의 코드에서 몇 줄을 가리킬 때 씁니다.

<a id="동작-스펙-behavior"></a>

## 상태

코드 블록에는 선택 · 비활성 · 오류 같은 상태를 정하는 파라미터가 없습니다. 누를 때 달라지는 것은 복사 버튼입니다.

### 인터랙션

| 상황 | 동작 |
| --- | --- |
| 복사 | `code` 문자열을 그대로 클립보드에 씁니다. 줄 번호, 줄 톤의 설명 글, 색은 들어가지 않습니다. |
| 복사 직후 | 아이콘이 체크 표시로 바뀌고 `CoreCodeSnippetContract.copiedFeedbackDuration`(2초) 뒤에 돌아옵니다. 그 사이에 다시 복사하면 시간을 새로 셉니다. |
| 복사 결과 | 체크 표시는 쓰기가 끝나기를 기다리지 않고 바로 바뀝니다. 실패를 알리는 표시는 없습니다. |
| 추가 동작 | `onCopy` 를 부릅니다. 부르는 시점은 플랫폼마다 다릅니다(플랫폼 차이). 토스트는 저절로 뜨지 않습니다. |
| Hover | 글리프가 `onSurfaceVariant` 에서 `onSurface` 로 바뀝니다. 솔리드 역할 면이거나 `copyIconStyle.color` 를 정하면 글리프 색은 바뀌지 않습니다. |
| 비활성 | 복사 버튼은 비활성이 되지 않습니다. 필요 없으면 `showCopyButton: false` 로 숨깁니다. |

복사한 뒤에 안내를 띄우려면 `onCopy` 에 직접 연결합니다.

```dart
CodeSnippet(
  code: 'flutter pub get',
  mode: 'bash',
  onCopy: showCopiedMessage,
)
```

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 문서 · 튜토리얼 · 도움말에서 코드 예시를 보여 줄 때
- API 응답이나 설정 파일의 내용을 보여 줄 때
- 사용자가 코드나 명령을 복사해 가야 할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 키 하나나 키 조합을 안내할 때 | [Kbd](/components/kbd) |
| 줄마다 추가 · 삭제 · 유지 데이터가 있을 때 | [CodeDiff](/components/code-diff) |
| 코드 편집기 모양의 틀에 줄마다 뜻에 맞는 글자색을 줄 때 | [MockupCode](/components/mockup-code) |
| 코드가 아닌 글을 선택할 수 있게 보여 줄 때 | [SelectableText](/components/selectable-text) |
| 코드가 아닌 일반 글 | [Text](/components/text) |

<a id="do"></a>

### 언어 이름과 코드 다듬기

<Cards columns="2">
<Card demo="code-snippet/do-mode" tone="do" eyebrow="이렇게 하세요">

`mode` 는 표에 있는 이름 그대로 소문자로 적습니다. 언어를 맞게 적으면 그 문법으로 칠합니다.

</Card>
<Card demo="code-snippet/dont-mode" tone="dont" eyebrow="이렇게 하지 마세요">

`'SQL'` 처럼 표에 없는 값은 색 없이 그립니다.

</Card>
<Card demo="code-snippet/do-trim" tone="do" eyebrow="이렇게 하세요">

`code` 앞뒤의 불필요한 빈 줄은 지우고 넘깁니다.

</Card>
<Card demo="code-snippet/dont-trim" tone="dont" eyebrow="이렇게 하지 마세요">

끝의 줄바꿈도 한 줄로 셉니다. 내용 없이 번호만 있는 줄이 아래에 하나 더 생깁니다.

</Card>
</Cards>

```dart
CodeSnippet(
  code: 'SELECT * FROM users WHERE active = true;',
  mode: 'sql',
)
```

<a id="dont"></a>

### 긴 코드

파일 전체처럼 긴 코드를 그대로 두면 페이지가 그만큼 길어집니다. 높이를 정해 두려면 `maxHeight` 를 씁니다. 두 플랫폼 모두 그 높이를 넘는 부분을 안에서 세로로 스크롤합니다. 다만 컴포넌트가 코드 영역에 키보드 정지점을 두지 않으므로(접근성 섹션), 키보드 사용자가 모든 줄을 꼭 읽어야 하면 높이를 제한하지 않습니다.

```dart
CodeSnippet(
  code: fileContent,
  mode: 'dart',
  codeSnippetStyle: CoreCodeSnippetStyle(maxHeight: 300),
)
```

## 배치

### 긴 줄과 좁은 너비

두 플랫폼 모두 긴 줄을 줄바꿈하지 않고 코드 영역 안에서 가로로 스크롤합니다. 복사 버튼과 액션은 스크롤을 따라 움직이지 않고 오른쪽 위에 남습니다.

<Preview demo="code-snippet/long-line" />

Web 루트에는 `min-width: 0` 이 있어 flex 칸에 바로 놓으면 칸 폭에 맞춰 줄어듭니다. 스니펫을 감싼 상자가 flex 칸이면 그 상자에도 `min-width: 0` 을 주고, grid 라면 열을 `minmax(0, 1fr)` 로 둡니다. 그러지 않으면 긴 줄만큼 칸이 넓어져 페이지가 가로로 넘칠 수 있습니다.

### 높이 제한

<Preview demo="code-snippet/max-height" />

`minWidth` · `maxWidth` · `minHeight` · `maxHeight` 는 코드 영역의 크기를 제한합니다. 기본값은 없어서, 정하지 않으면 스타일로 거는 제한이 없습니다.

### 액션과 복사 버튼

`actions` 에 넣은 위젯은 복사 버튼 앞에 받은 순서대로 놓이고, 사이 간격은 `actionGapStyle`(기본 4)입니다. `showCopyButton: false` 여도 액션은 보입니다.

```dart
CodeSnippet(
  code: source,
  mode: 'dart',
  actions: [Badge(child: Text('Dart'))],
)
```

이 묶음은 코드 위에 겹쳐 놓입니다. 코드 영역에 버튼 자리를 따로 비워 두지 않고, 복사 버튼은 배경이 투명해 아래의 글자와 겹쳐 보입니다.

- **첫 줄이 긴 코드** — 첫 줄이 버튼 아래로 지나갑니다.
- **상자가 코드 폭일 때** (Flutter 의 기본 모양, Web 에서 폭이 내용에 맞춰지는 자리) — 첫 줄이 가장 긴 줄이면 그 끝이 복사 버튼과 겹칩니다. 한 줄짜리 코드가 늘 여기에 해당합니다.

짧은 한 줄 코드는 오른쪽 여백을 늘려 버튼 자리를 만듭니다. 첫 줄이 긴 코드는 같은 방법으로 위쪽 여백(`top`)을 `CoreSpace.space40` 으로 늘려 코드를 버튼 아래로 내립니다. 액션을 더했다면 그 크기만큼 더 비웁니다.

```dart
CodeSnippet(
  code: 'flutter pub get',
  mode: 'bash',
  codeSnippetStyle: CoreCodeSnippetStyle(
    padding: CoreEdgeInsets.only(
      left: CoreSpace.space12,
      top: CoreSpace.space10,
      right: CoreSpace.space40,
      bottom: CoreSpace.space10,
    ),
  ),
)
```

### Flutter 에서 폭 정하기

Web 의 루트는 블록 상자라 블록 부모의 폭을 채웁니다. Flutter 의 배경 상자는 코드 폭을 따르고, 줄 톤 띠를 그릴 때는 받을 수 있는 최대 폭을 채웁니다. 그래서 놓는 자리에 따라 두 가지를 확인합니다.

- **폭을 강제하는 부모** (`ListView`, `Column(crossAxisAlignment: CrossAxisAlignment.stretch)`, `SizedBox(width: …)`) — 띠가 없고 코드가 그 폭보다 좁으면, 배경 상자는 코드 폭에 머무는데 복사 버튼과 액션은 강제된 폭의 오른쪽 끝에 놓여 상자 밖으로 떨어집니다. `Align` 으로 감싸면 버튼이 상자 안에 놓입니다.
- **폭이 정해지지 않는 부모** — 띠를 그리는 스니펫은 `Row` 의 일반 자식처럼 폭의 상한이 없는 자리에서 레이아웃 오류가 납니다. `IntrinsicWidth` · `IntrinsicHeight` 아래에서도 오류가 납니다. 기본 크기 방식의 CoUI `Card` 는 폭이 강제되지 않으면 안에서 `IntrinsicWidth` 를 씁니다. `Row` 에서는 `Expanded` 로 감싸고, `Card` 는 `cardStyle: CoreCardStyle(sizing: CoreCardSizing.expand)` 로 바꿉니다.

<Code language="dart" title="Flutter">
Align(
  alignment: Alignment.topLeft,
  child: CodeSnippet(code: source, mode: 'dart'),
)
</Code>

## 테마와 스타일

코드, 언어, 줄 번호, 줄 톤, 버튼 표시처럼 무엇을 보여 줄지는 위젯 파라미터로 넘깁니다. 색 · 여백 · 글자처럼 보이는 값과 안쪽 부품의 스타일은 `codeSnippetStyle`(`CoreCodeSnippetStyle`) 하나로 덮어씁니다. 앱 전체의 기본값은 `CoreComponentTheme` 의 `codeSnippet`(`CoreCodeSnippetTheme`)에 둡니다.

### 값이 정해지는 순서

```text
CoreCodeSnippetStyle 의 default 값               // 디자인 시스템 기본값
  → 솔리드 역할 면의 짝 색                        // 줄 번호 · 복사 글리프 · 포커스 링 색만
  → CoreCodeSnippetTheme.style                    // 앱 전체
  → codeSnippetStyle (withStyle · getter 포함)    // 인스턴스별
```

- 뒤에 있는 값이 앞의 값을 필드마다 덮습니다. 안쪽 글자 · 버튼 · 아이콘 · 간격 스타일도 그 안의 필드끼리 합칩니다.
- 짝 색은 테마와 인스턴스를 합친 뒤의 배경을 보고 고릅니다.
- 복사 버튼은 `defaultCopyButtonStyle` 에 `copyButtonStyle` 을 합친 값을 Button 의 인스턴스 스타일로 받습니다. 그래서 여기에 값이 있는 필드는 Button 테마보다 우선합니다.
- 복사 아이콘은 `defaultCopyIconStyle` 에 `copyIconStyle` 을, 액션 간격은 `defaultActionGapStyle` 에 `actionGapStyle` 을 합칩니다.
- 코드의 글자 역할은 `codeTypography` 로 바꾸고, 크기 · 굵기 · 글꼴 · 색을 따로 얹을 때는 `codeTextStyle` 을 씁니다. 코드 색은 `codeTextStyle.color` 로 정합니다.
- 테두리는 `borderColor` 와 `borderWidth` 를 함께 정해야 보입니다. 기본 선 색은 투명이라 너비만 주면 선이 없고, 기본 너비는 0이라 색만 주어도 선이 없습니다.
- `padding` 은 `CoreEdgeInsets.all` · `symmetric` · `only` · `fromLTRB` 로 적습니다. 읽기 방향을 따르는 `CoreEdgeInsets.directional` 을 넣으면 두 플랫폼 모두 `ArgumentError` 가 납니다.

### 사용 예

<Split>

<Code language="dart" title="스니펫 하나만 바꾸기">
CodeSnippet(
  code: source,
  mode: 'dart',
  codeSnippetStyle: CoreCodeSnippetStyle(
    padding: CoreEdgeInsets.all(CoreSpace.space24),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    borderColor: CoreColor.token(CoreColors.outlineVariant),
    borderWidth: CoreStrokeWidth.stroke1,
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    codeSnippet: CoreCodeSnippetTheme(
      style: CoreCodeSnippetStyle(
        borderColor: CoreColor.token(CoreColors.outlineVariant),
        borderWidth: CoreStrokeWidth.stroke1,
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다. 다크 테마를 따로 넘기는 앱은 그 테마에도 같은 `coreComponentTheme` 를 넘깁니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

`withStyle` 을 이어 이미 만든 `CodeSnippet` 에 `codeSnippetStyle` 을 덧붙일 수 있습니다. 같은 필드는 나중에 적은 값이 이깁니다. `.radius16` 같은 getter 는 이름이 같은 `CoreRadius` 값을 정합니다. 색 getter(`.primary` · `.secondary` · `.tertiary` · `.surface` · `.surfaceContainer` · `.error` · `.success` · `.warning` · `.info` · `.outline` · `.transparent`)는 배경과 코드 색을 함께 정합니다. `backgroundColor` · `borderColor` · `borderWidth` · `contentPadding` 메서드로는 바탕색, 테두리 색과 폭, 안쪽 여백을 값으로 줍니다. `backgroundColor(color)` 는 색 getter 와 달리 코드 색을 정하지 않습니다. 코드 색은 앞서 정한 값이나 테마의 값이 없으면 `onSurface` 로 남으므로, 솔리드 역할 면을 고를 때는 색 getter 를 쓰거나 `codeTextStyle` 의 색을 함께 정해 대비를 확인하세요. 아래 예제의 두 번째 스니펫은 `borderWidth` 를 적지만 `borderColor` 가 없어 선은 보이지 않습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class CodeSnippetChainExample extends StatefulWidget {
  const CodeSnippetChainExample({super.key});

  @override
  State<CodeSnippetChainExample> createState() => _CodeSnippetChainExampleState();
}

class _CodeSnippetChainExampleState extends State<CodeSnippetChainExample> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        CodeSnippet(
          code: "void main() {\n  print('Hello, CoUI!');\n}",
          mode: 'dart',
          showLineNumbers: true,
          showCopyButton: true,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        CodeSnippet(
          code: "void main() {\n  print('Hello, CoUI!');\n}",
          mode: 'dart',
          showLineNumbers: true,
          showCopyButton: true,
        ).withStyle(
          const CoreCodeSnippetStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            codeTextStyle: CoreTextStyle(
              color: CoreColor.token(CoreColors.onTertiary),
            ),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
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
class CodeSnippetChainExample extends StatefulComponent {
  const CodeSnippetChainExample({super.key});

  @override
  State<CodeSnippetChainExample> createState() => _CodeSnippetChainExampleState();
}

class _CodeSnippetChainExampleState extends State<CodeSnippetChainExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        CodeSnippet(
          code: "void main() {\n  print('Hello, CoUI!');\n}",
          mode: 'dart',
          showLineNumbers: true,
          showCopyButton: true,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        CodeSnippet(
          code: "void main() {\n  print('Hello, CoUI!');\n}",
          mode: 'dart',
          showLineNumbers: true,
          showCopyButton: true,
        ).withStyle(
          const CoreCodeSnippetStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            codeTextStyle: CoreTextStyle(
              color: CoreColor.token(CoreColors.onTertiary),
            ),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
          ),
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

<a id="토큰-기반-스타일링"></a>

### 기본값이 있는 곳

기본값은 `coui_core` 의 `CoreCodeSnippetStyle` 에 있고, Flutter와 Web이 같은 값을 읽습니다.

| 이름 | 값 |
| --- | --- |
| `defaultBackgroundColor` | `surfaceContainerLow` |
| `defaultBorderColor` | 투명 |
| `defaultBorderWidth` | 0 |
| `defaultBorderRadius` | 8 |
| `defaultPadding` | 위아래 10 · 좌우 12 |
| `defaultCodeTypography` | `codeSm` 역할 |
| `defaultCodeTextStyle` | 색 `onSurface` |
| `defaultLineNumberTextStyle` | 색 `onSurfaceVariant` |
| `defaultLineNumberMargin` | 12 |
| `defaultPreMargin` | 0 |
| `defaultCopyButtonOffset` | 6 |
| `defaultCopyButtonStyle` | 28 × 28, 모서리 8, 안쪽 여백 0, 전환 150ms |
| `defaultCopyIconStyle` | 아이콘 16 |
| `defaultActionGapStyle` | 4 |
| `defaultSuccessLineColor` | `successContainer` |
| `defaultWarningLineColor` | `warningContainer` |
| `defaultErrorLineColor` | `errorContainer` |

<a id="접근성-accessibility"></a>

## 접근성

복사 버튼에는 번역되는 이름이 붙고, 줄 톤은 색과 함께 말로도 전합니다. 코드 영역에는 이름이나 키보드 정지점을 따로 두지 않습니다.

### 역할

| 부분 | Flutter | Jaspr Web |
| --- | --- | --- |
| 바깥 | 이름 없는 `Semantics(container: true)` 경계 | role · ARIA 속성을 붙이지 않은 `<div>`. `attributes` 로 넘긴 것만 붙습니다. |
| 코드 | `SelectableText`. 접근성 정보에서는 읽기 전용 텍스트 필드입니다. | `<pre><code>` |
| 복사 버튼 | CoUI `Button` 을 `Semantics(button: true, label: …)` 로 감쌉니다. | `aria-label` 을 가진 `<button type="button">` |

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift+Tab` | 복사 버튼과, `actions` 에 넣은 포커스를 받는 컨트롤로 이동합니다. 액션이 복사 버튼보다 앞에 놓입니다. |
| `Enter` · `Space` | 포커스가 복사 버튼에 있으면 복사합니다. Flutter 는 `Button` 이 쓰는 `Clickable` 의 단축키가, Web 은 네이티브 `<button>` 이 처리합니다. |

코드 영역을 위한 키 처리는 없습니다. Web 은 `<pre>` 에 `tabindex` 를 주지 않습니다. Flutter 의 `SelectableText` 는 포커스 순회에서 건너뛰는(`skipTraversal`) 초점 노드를 써서 `Tab` 이 멈추지 않습니다.

### 스크린 리더

- **복사 버튼** — 두 플랫폼 모두 CoUI 번역 문자열 `codeSnippetCopyLabel` 을 이름으로 씁니다(영어 `Copy code`, 한국어 `코드 복사`).
- **코드** — Web 은 `<code>` 안의 글이, Flutter 는 `SelectableText` 의 글이 접근성 정보에 담깁니다.
- **줄 톤** — 띠마다 줄 번호와 톤을 말로 붙입니다(영어 `Line 2: success`, 한국어 `2번째 줄: 성공`). Web 은 띠 안의 화면에 보이지 않는(`sr-only`) 글이고 마크업에서 코드보다 앞에 놓입니다. Flutter 는 띠 자리의 시맨틱 노드이고, 순서 값을 주어 코드보다 앞에 오게 합니다. 띠를 그려도 Flutter 의 줄 번호와 코드는 띠가 없을 때처럼 각자의 노드로 남습니다.
- **복사 완료** — 따로 알리지 않습니다. 아이콘만 바뀌고 버튼의 이름은 그대로이며, 라이브 영역이 없습니다. 알려야 하면 `onCopy` 에서 안내를 띄웁니다.

### 포커스 관리

코드 블록은 화면에 나타날 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. 복사할 때도 포커스를 옮기는 코드는 없고 버튼의 아이콘만 바뀝니다.

복사 버튼은 `Button` 의 포커스 링을 씁니다. 기본값은 두께 2의 링을 버튼에서 2 띄우고 그 사이는 칠하지 않으며, 링 색은 `focusRing` 입니다. 솔리드 역할 면에서는 링 색만 줄 번호 · 복사 글리프와 같은 면의 짝 색이 되고, 두께와 간격은 그대로입니다. CoUI 기본 색의 라이트 · 다크 · 고대비 라이트 · 고대비 다크에서 이 짝 색과 면의 대비는 4.5 : 1 이상입니다. 브랜드 색에서는 직접 확인합니다.

`copyButtonStyle.focusOutlineStyle` 이나 `CoreCodeSnippetTheme` 에 링 색을 적으면 그 색이 이깁니다. 반면 앱의 Button 테마에 적은 링 색은 솔리드 역할 면에서 짝 색에 집니다.

### 알려진 제약

- **코드 블록에 이름이 없습니다.** 영역 이름이 필요하면 Web 은 `attributes: {'role': 'region', 'aria-label': '예제 코드'}` 를 넘기고, Flutter 는 `Semantics(container: true, label: '예제 코드', child: …)` 로 감쌉니다.
- **눈으로는 줄 톤을 색으로만 구분합니다.** 줄 앞에 기호를 그리지 않습니다. 색을 구분하기 어려운 사용자를 위해 톤의 뜻을 코드 주석이나 바깥의 문장으로 함께 적거나, `+` · `-` 표시가 있는 [CodeDiff](/components/code-diff) 를 씁니다.
- **솔리드 역할 면과 줄 톤을 함께 쓰면 띠 위의 글자가 거의 보이지 않을 수 있습니다.** 줄 톤 섹션의 안내를 따릅니다.
- **줄 번호를 접근성 정보에서 빼지 않습니다.** 번호를 숨기는 설정이 코드에 없어 보조 기술이 숫자를 읽을 수 있습니다. 스크린 리더 사용자가 주 독자라면 `showLineNumbers: false`(기본값)를 씁니다.
- **Web 에서 줄 번호나 줄 톤을 켜면 `<code>` 의 글에 번호와 띠의 숨긴 글도 들어갑니다.** `<code>` 의 글을 통째로 읽는 스크립트를 따로 만들면 그 글까지 가져갑니다. 컴포넌트의 복사 버튼은 `code` 값만 씁니다.
- **넘친 코드를 키보드로 옮겨 보는 것을 보장하지 않습니다.** 코드 영역에 컴포넌트가 두는 정지점과 키 처리가 없습니다. Web 의 `attributes` 는 바깥 `<div>` 에 닿으므로, 거기에 `tabindex` 를 줘도 스크롤하는 `<pre>` 에는 정지점이 생기지 않습니다. 긴 코드는 `maxHeight` 없이 펼치고, 줄은 짧게 나눕니다.
- **언어 이름은 전달되지 않습니다.** `mode` 는 색을 고르는 데만 쓰고, `<code>` 의 속성이나 Flutter 의 시맨틱으로 내보내지 않습니다. 언어를 알려야 하면 코드 블록 곁에 글로 적습니다.
- **복사 버튼과 액션이 코드와 겹칠 수 있습니다.** 첫 줄이 길거나, 상자가 코드 폭인데 첫 줄이 가장 긴 줄일 때입니다. 배치 섹션의 여백 방법을 씁니다.

동작 줄이기 · 고대비처럼 모든 컴포넌트에 함께 적용되는 기준은 [전역 접근성 축](/accessibility) 페이지에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

공통 파라미터의 이름과 기본값은 두 플랫폼이 같고, Web 에는 HTML 속성을 넘기는 파라미터가 더 있습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 타입 | `Widget`, `VoidCallback?` | `Component`, `CoreVoidCallback?` |
| 코드 그리기 | `SelectableText` 의 `TextSpan` | `<pre><code>` 안의 `<span>` |
| 색 | 지금 테마의 색 값으로 계산합니다. | CSS 변수를 가리켜, 변수 값이 바뀌면 브라우저가 다시 칠합니다. |
| 추가 문법 | JSON · YAML · SQL 문법을 패키지 자산에서 비동기로 읽습니다. | 패키지 코드에 함께 컴파일되어 있습니다. |
| 첫 화면 | 강조기를 준비하는 동안에는 구문 색 · 줄 번호 · 띠 없이 코드만 그리고, 긴 줄은 줄바꿈합니다. 준비되면 완성된 모양이 됩니다. `mode` 를 바꿀 때도 다시 준비합니다. | 서버가 그린 마크업부터 색 · 줄 번호 · 띠가 있습니다. |
| 복사 | `Clipboard.setData` 가 끝난 뒤 `onCopy` 를 부릅니다. | `navigator.clipboard.writeText` 를 부르고 결과를 기다리지 않은 채 `onCopy` 를 부릅니다. 이 API 가 없는 환경을 따로 처리하지 않습니다. 브라우저에서 실행되지 않는 정적인 마크업에서는 버튼을 눌러도 복사되지 않습니다. |
| 상자 폭 | 코드 폭. 띠가 있으면 받을 수 있는 최대 폭 (배치 섹션) | 블록 부모의 폭 |
| 가로 스크롤 | 가로 `SingleChildScrollView` | `<pre>` 의 `overflow-x: auto` |
| 크기 제한 | `BoxConstraints`. 높이를 넘으면 세로 `SingleChildScrollView` | CSS `min-*` · `max-*`. `maxHeight` 를 주면 `overflow-y: auto` |
| `preMargin` | 적용하지 않습니다. | `<pre>` 의 바깥 여백이 됩니다. |
| 역할 토큰 | `codeTextStyle` · `lineNumberTextStyle` 의 토큰도 읽습니다. | 두 슬롯의 역할 토큰은 읽지 않습니다. 코드의 역할은 `codeTypography` 로 바꿉니다. |
| 줄 톤 띠 | 코드 뒤를 `CustomPaint` 로 칠합니다. 줄마다 높이를 잽니다. | 코드 뒤에 `1lh` 높이의 행을 쌓습니다. |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` 가 루트 `<div>` 에 닿습니다. |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. 표의 `W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `code` | `String` | 필수 | 보여 주고 복사하는 코드 |
| `mode` | `String` | 필수 | 구문 강조의 언어 이름. 언어와 구문 강조 섹션의 표를 따릅니다. |
| `showLineNumbers` | `bool` | `false` | 줄 번호를 보일지 정합니다. |
| `lineTones` | `Map<int, CoreCodeLineTone>` | `const {}` | 1부터 센 줄 번호마다의 톤. `success` · `warning` · `error` 만 띠를 그립니다. |
| `showCopyButton` | `bool` | `true` | 복사 버튼을 보일지 정합니다. |
| `actions` | `List<W>` | `const []` | 오른쪽 위, 복사 버튼 앞에 놓는 위젯 |
| `onCopy` | `VoidCallback?` (Flutter) · `CoreVoidCallback?` (Web) | `null` | 복사할 때 함께 부르는 함수 |
| `codeSnippetStyle` | `CoreCodeSnippetStyle?` | `null` | 보이는 값과 안쪽 부품의 스타일 |

`copyWith` 는 같은 파라미터를 바꾼 새 인스턴스를 만들고, `withStyle` 은 `codeSnippetStyle` 에 값을 합친 인스턴스를 만듭니다.

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트의 id |
| `classes` | `String?` | `null` | 루트에 더하는 클래스 |
| `css` | `Styles?` | `null` | 루트에 더하는 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 루트의 HTML 속성 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 루트의 이벤트 처리 |

### 테마 — `CoreCodeSnippetTheme`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CoreCodeSnippetStyle?` | `null` | 모든 `CodeSnippet` 에 적용하는 스타일. 인스턴스의 `codeSnippetStyle` 이 그 위를 덮습니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreCodeSnippetStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Container background colour. `null` defers to [defaultBackgroundColor]. |
| `borderColor` | `CoreColor?` | Outer border stroke colour. `null` defers to [defaultBorderColor]. |
| `borderWidth` | `double?` | Outer border stroke width (logical px). |
| `borderRadius` | `CoreBorderRadius?` | Outer border radius. `null` defers to [defaultBorderRadius]. |
| `padding` | `CoreEdgeInsets?` | Inner padding applied to the code area. `null` defers to [defaultPadding]. |
| `codeTypography` | `CoreTextStyle?` | Code body typography role. `null` defers to [defaultCodeTypography]. |
| `codeTextStyle` | `CoreTextStyle?` | Rendered code text style override (layered on [codeTypography]). Carries the code foreground colour via [CoreTextStyle.color] — the ink of the plain text and of every span the highlighter leaves uncoloured. `null` defers to [defaultCodeTextStyle]. |
| `lineNumberTextStyle` | `CoreTextStyle?` | Line-number gutter text style override. Its colour is the gutter number's ink; `null` defers to [defaultLineNumberTextStyle] (`onSurfaceVariant`). |
| `preMargin` | `double?` | `<pre>` wrapper outer margin (logical px). `null` defers to [defaultPreMargin]. |
| `lineNumberMargin` | `double?` | Line-number gutter right margin (logical px). `null` defers to [defaultLineNumberMargin]. |
| `lineNumberAlpha` | `double?` | **Deprecated (since 0.162)** — Unused — the gutter number is an opaque token: state lineNumberTextStyle.color (default defaultLineNumberTextStyle, onSurfaceVariant). Hierarchy is the token, not an alpha. No longer read on any platform. To change the line numbers' colour, set [lineNumberTextStyle]'s colour instead: the numbers are set apart by a solid colour token, not by an alpha over the code colour. |
| `copyButtonOffset` | `double?` | Copy button corner offset — top + right (logical px): where the button sits inside its corner wrapper. `null` defers to [defaultCopyButtonOffset]. |
| `minWidth` | `double?` | Minimum width of the code display area (logical px). `null` leaves the area unconstrained on that edge. |
| `maxWidth` | `double?` | Maximum width of the code display area (logical px). `null` leaves the area unconstrained on that edge. No `default*` — see [minWidth] for why a value here would change what every snippet renders. |
| `minHeight` | `double?` | Minimum height of the code display area (logical px). `null` leaves the area unconstrained on that edge. No `default*` — see [minWidth]. |
| `maxHeight` | `double?` | Maximum height of the code display area (logical px). `null` leaves the area unconstrained on that edge. When set, the code area scrolls vertically past the cap on both platforms (Flutter's enclosing `SingleChildScrollView`, Web's `overflow-y: auto`). |
| `copyButtonStyle` | `CoreButtonStyle?` | Style for the copy button — size, radius, padding, foreground, transition. Laid over [defaultCopyButtonStyle] and passed as is to `Button(variant:.plain, buttonStyle: …)` on both platforms. On a solid role face the focus ring's colour is the face's ink ([inkOnFace]); a ring colour stated here replaces it. |
| `copyIconStyle` | `CoreIconStyle?` | Copy button icon style override, merged on top of [defaultCopyIconStyle]: `size` defers to it. `color` has no default — the glyph follows the copy button's foreground through its states — so a colour stated here pins the glyph in every state. A solid role face states its ink here ([inkOnFace]), and the glyph keeps it through hover. |
| `actionGapStyle` | `CoreGapStyle?` | Gap slot between sibling action widgets in the top-right area. `null` defers to [defaultActionGapStyle]. |
| `successLineColor` | `CoreColor?` | Band colour override for [CoreCodeLineTone.success] lines. `null` defers to [defaultSuccessLineColor]. |
| `warningLineColor` | `CoreColor?` | Band colour override for [CoreCodeLineTone.warning] lines. |
| `errorLineColor` | `CoreColor?` | Band colour override for [CoreCodeLineTone.error] lines. |

<!-- STYLE_TABLE:END -->

<Note>

표의 설명과 지금 동작이 다른 곳이 있습니다. `preMargin` 은 Web 에만 적용되고 Flutter 의 그림은 바뀌지 않습니다. `codeTextStyle` · `lineNumberTextStyle` 에 넣은 역할 토큰은 Web 이 읽지 않습니다.

</Note>

<a id="레거시-vs-통일-비교-migration-notes"></a>

## 이전 이름에서 옮기기

웹에서 `CodeBlock` 이라는 이름으로 찾고 있었다면 `CodeSnippet` 입니다. CoUI 는 Flutter 쪽 이름을 따라 두 플랫폼 모두 `CodeSnippet` 을 쓰며, 지금 패키지에는 `CodeBlock` 클래스가 없습니다. 옛 코드를 옮길 때는 파라미터를 위 API 표와 대조합니다.

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="code-snippet/related-code-diff" title="CodeDiff">

줄마다 추가 · 삭제 · 유지를 표시합니다. 변경 내용을 보일 때 씁니다.

</Card>
<Card demo="code-snippet/related-mockup-code" title="MockupCode">

코드 편집기 모양의 틀입니다. 구문 강조와 복사 버튼은 없습니다.

</Card>
<Card demo="code-snippet/related-kbd" title="Kbd">

키보드 키와 키 조합을 키캡으로 보여 줍니다.

</Card>
<Card demo="code-snippet/related-text" title="Text">

코드가 아닌 일반 글에 씁니다.

</Card>
</Cards>
