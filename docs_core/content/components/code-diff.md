---
title: CodeDiff
description: 추가 · 삭제 · 유지한 코드 줄을 색과 + · - 표시로 보여 주는 읽기 전용 뷰어입니다. 줄의 종류와 번호는 직접 정해 넘깁니다.
category: display
platforms: [flutter, web]
related: [code-snippet, diff]
tags: [code, diff, review, git]
template: v2
source: display/code_diff
---

# CodeDiff

<a id="live-preview"></a>

## 플레이그라운드

셋째 줄의 종류를 바꾸고, 긴 줄 · 줄 번호 숨기기 · 줄 누르기를 켜고 끄며 CodeDiff를 확인하세요. 만들어진 코드는 복사해 쓸 수 있습니다. 줄 누르기를 켜면 누른 줄이 diff 아래에 적히고, 코드에 나오는 `openLine`은 앱에서 만드는 함수입니다.

<Playground component="code-diff" />

CodeDiff는 두 코드를 비교해 주지 않습니다. 줄마다 추가 · 삭제 · 유지를 정한 `lines`를 받아 그 순서대로 그립니다.

## 구조

바깥 상자 안에 줄이 틈 없이 쌓이고, 줄마다 번호 · prefix · 코드가 차례로 놓입니다.

<Anatomy demo="code-diff/anatomy">
<AnatomyItem part="container" name="Container">

바깥 상자입니다. 기본은 `surfaceContainerLow` 면에 모서리 12이고 테두리가 없습니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="line number">

줄 번호 칸입니다. `showLineNumbers`가 `true`이고 그 줄에 `lineNumber`가 있을 때만 생깁니다.

</AnatomyItem>
<AnatomyItem select="span" side="top" name="prefix">

줄의 종류를 알리는 두 글자입니다. `+`나 `-` 뒤에 공백 하나가 붙고, 유지 줄은 공백 두 칸입니다. 기본 굵기는 700입니다.

</AnatomyItem>
<AnatomyItem select="span + div" side="top" name="text">

`CoreCodeDiffLine.text`입니다. 남은 폭을 모두 쓰고, 길면 줄을 바꿉니다.

</AnatomyItem>
</Anatomy>

기본값에서는 글이 한 줄에 들어가는 줄의 높이가 21입니다. 줄은 앞쪽 여백 12에서 시작하고, 폭 40인 번호 칸이 있으면 prefix가 52 위치에서 시작합니다. 번호와 코드는 모두 고정폭 글꼴 역할(`codeSm` · `codeMd`)을 씁니다.

<a id="동작-스펙-behavior"></a>

## 줄 종류

한 줄은 `CoreCodeDiffLine` 하나이고, `type`(`CoreCodeDiffLineType`)이 모습을 정합니다. 아래 색은 기본값입니다.

| 종류 | prefix | 줄 배경 | prefix · 번호 색 |
| --- | --- | --- | --- |
| `added` | `+` | `successContainer` | `onSuccessContainer` |
| `removed` | `-` | `errorContainer` | `onErrorContainer` |
| `unchanged` | 공백 두 칸 | 없음 | prefix는 `onSurface`, 번호는 `onSurfaceVariant` |

<Preview demo="code-diff/line-types" />

- 코드 글자색은 모든 줄에서 `onSurface`입니다. 추가 · 삭제 줄의 배경은 불투명하게 칠하고, 코드의 색은 바꾸지 않습니다.
- `text`는 줄 전체를 한 가지 글자 스타일로 그립니다. 구문 강조는 없고, 앞쪽 공백(들여쓰기)은 그대로 남습니다.
- 한 항목에는 코드 한 줄을 담습니다. `text`에 줄바꿈 문자가 있으면 한 항목이 여러 줄로 그려지고, 번호와 prefix는 첫 줄에만 붙습니다.

## 줄 번호

<Preview demo="code-diff/line-numbers" />

- 번호 칸은 하나입니다. 이전 번호와 이후 번호를 나란히 두는 두 칸 모양은 없습니다.
- `lineNumber`로 넘긴 값을 그대로 적습니다. 번호를 만들거나 줄 순서를 바꾸지 않으므로, 바뀐 줄처럼 같은 번호가 두 번 나와도 됩니다.
- `showLineNumbers: false`면 값이 있어도 번호 칸을 그리지 않습니다.
- `lineNumber`가 없는 줄에는 빈 칸도 두지 않습니다. 그 줄만 prefix와 코드가 앞으로 당겨집니다.
- 기본 폭 40은 숫자 자리 28과 코드 쪽 간격 12를 합친 값이고, 세 자리 번호를 기준으로 합니다. 네 자리 이상이면 `lineNumberWidth`를 넓히세요.

## 상태

기본은 표시만 합니다. `onLineTap`을 주면 유지 줄까지 모든 줄을 누를 수 있고, 누른 줄의 `CoreCodeDiffLine`을 넘겨받습니다. 줄마다 따로 켜고 끄는 값은 없고, 선택 · 비활성 상태를 정하는 속성도 없습니다. 글을 고치는 기능과 복사 버튼도 없습니다.

| 상태 | `onLineTap`을 준 줄 |
| --- | --- |
| Hover | 배경은 바뀌지 않고, 마우스 커서만 누를 수 있는 모양이 됩니다. |
| Pressed | 줄이 0.97배로 작아집니다(`CoreClickableStyle.defaultPressedScale`). 전환 시간은 100ms이고, 동작 줄이기를 켜면 전환 없이 바뀝니다. |
| Focus | 키보드로 이동하면 포커스 링을 그립니다. 기본 설정에서는 링이 일부 또는 전부 잘립니다([알려진 제약](#알려진-제약)). |
| 글자 선택 | 줄의 글자는 드래그로 선택되지 않습니다. |

눌림 크기와 전환, 포커스 링은 `CoreComponentTheme.clickable`을 따릅니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 코드 리뷰 화면에서 바뀐 줄을 보여 줄 때
- 마이그레이션 안내에서 이전 코드와 이후 코드를 줄 단위로 강조할 때
- 설정 값처럼 글로 적을 수 있는 변경 이력을 보여 줄 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 변경 표시 없이 구문 강조 · 복사 버튼이 있는 코드 블록 | [CodeSnippet](/components/code-snippet) |
| 코드 몇 줄만 색 띠로 가리킬 때 | [CodeSnippet](/components/code-snippet)의 `lineTones` |
| 두 화면이나 그림을 겹쳐 놓고 분할선으로 비교할 때 | [Diff](/components/diff) |

<a id="예제"></a>

### 줄 데이터 만들기

`lines`는 앱에서 만듭니다. 두 파일을 비교해야 하면 diff 도구나 라이브러리로 계산한 결과를 `CoreCodeDiffLine` 목록으로 옮깁니다. 아래 코드는 두 플랫폼이 같습니다.

```dart
CodeDiff(
  lines: const [
    CoreCodeDiffLine(
      text: 'class MyWidget extends StatelessWidget {',
      type: CoreCodeDiffLineType.unchanged,
      lineNumber: 1,
    ),
    CoreCodeDiffLine(
      text: "  return Text('Hello');",
      type: CoreCodeDiffLineType.removed,
      lineNumber: 2,
    ),
    CoreCodeDiffLine(
      text: "  return Text('Hello').bodyMedium;",
      type: CoreCodeDiffLineType.added,
      lineNumber: 2,
    ),
  ],
)
```

<a id="do"></a>
<a id="dont"></a>

### 바뀐 줄과 번호

<Cards columns="2">
<Card demo="code-diff/do-change" tone="do" eyebrow="이렇게 하세요">

추가 · 삭제된 줄이 있는 실제 변경을 보여 줍니다. `+` · `-`는 실제 글자라 색이 없어도 구분됩니다.

</Card>
<Card demo="code-diff/dont-unchanged" tone="dont" eyebrow="이렇게 하지 마세요">

유지 줄만 나열하지 않습니다. 바뀐 것이 없는 코드는 CodeSnippet으로 보여 줍니다.

</Card>
<Card demo="code-diff/do-numbered" tone="do" eyebrow="이렇게 하세요">

번호를 쓰면 모든 줄에 줍니다. prefix와 코드가 같은 위치에서 시작합니다.

</Card>
<Card demo="code-diff/dont-partial-number" tone="dont" eyebrow="이렇게 하지 마세요">

일부 줄의 번호만 비우지 않습니다. 그 줄의 prefix와 코드가 앞으로 당겨져 어긋납니다.

</Card>
</Cards>

바뀐 것이 없는 코드는 이렇게 씁니다.

```dart
CodeSnippet(code: 'final x = 1;', mode: 'dart')
```

## 배치

### 폭

| 플랫폼 | 폭이 정해지는 방식 |
| --- | --- |
| Flutter | 받은 폭을 모두 채웁니다. 폭이 정해진 부모가 필요해서, `Row`의 직계 자식처럼 폭 제한이 없는 자리에서는 레이아웃 오류가 납니다. `Row` 안에서는 `Expanded`로 감쌉니다. |
| Jaspr Web | 블록 부모에서는 폭을 채웁니다. 가로 flex나 가운데 정렬한 세로 flex 안에서는 내용에 따라 폭이 정해지므로, 채우려면 `classes: 'w-full'`을 줍니다. |

### 긴 줄

<Preview demo="code-diff/wrap" />

두 플랫폼 모두 가로 스크롤 없이 줄을 바꿉니다. 번호와 prefix는 첫 줄에 남고, 이어지는 줄은 코드 칸이 시작하는 위치에서 이어집니다. 한 줄에 들어가지 않는 긴 낱말은 중간에서 나눕니다. 줄바꿈을 끄는 속성은 없습니다. 웹의 조건은 [플랫폼 차이](#플랫폼-차이)를 보세요.

### 긴 diff

CodeDiff는 스스로 스크롤하지 않고, 받은 줄을 모두 한 번에 만듭니다. 줄 수만큼 높아지므로 파일 전체보다 바뀐 부분과 앞뒤 몇 줄을 넘기고, 높이를 제한해야 하면 스크롤 영역에 넣습니다.

<Tabs groupId="platform">
<TabItem label="Flutter" value="flutter">

```dart
SizedBox(
  height: 320,
  child: SingleChildScrollView(
    child: CodeDiff(lines: lines),
  ),
)
```

</TabItem>
<TabItem label="Web" value="web">

```dart
div(
  styles: Styles(raw: {'max-height': '20rem', 'overflow-y': 'auto'}),
  attributes: const {'tabindex': '0', 'role': 'region', 'aria-label': '변경 내용'},
  [CodeDiff(lines: lines)],
)
```

</TabItem>
</Tabs>

웹의 스크롤 상자는 예제처럼 flex가 아닌 `div`로 두고 그 안에 CodeDiff를 넣습니다. 높이가 정해진 세로 flex의 직계 자식으로 두면 CodeDiff의 상자가 줄어들어 아래 줄이 잘릴 수 있습니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

색 · 크기 · 간격 · 글자처럼 보이는 값은 `codeDiffStyle`(`CoreCodeDiffStyle`) 하나로 바꿉니다. 내용과 동작(`lines` · `showLineNumbers` · `onLineTap`)은 위젯 파라미터입니다.

### 값이 정해지는 순서

```text
CoreCodeDiffStyle.defaultX                 // 디자인 시스템 기본값
  → CoreComponentTheme.codeDiff?.style     // 앱 전체 (CoreCodeDiffTheme)
  → codeDiffStyle                          // CodeDiff 하나
```

뒤의 값이 이깁니다. `unchangedTextStyle` · `bodyTextStyle` · `gutterTextStyle`은 안의 속성끼리 합치고, 나머지 필드는 값 하나를 통째로 바꿉니다.

### 기본값

| 부분 | 필드 | 기본값 |
| --- | --- | --- |
| 바깥 면 | `surfaceColor` | `surfaceContainerLow` |
| 모서리 | `cornerRadius` | `CoreRadiusRole.panel`(12) |
| 테두리 | `borderWidth` · `outlineColor` | 0 · 투명 |
| 추가 줄 | `addedBackgroundColor` · `addedForegroundColor` | `successContainer` · `onSuccessContainer` |
| 삭제 줄 | `removedBackgroundColor` · `removedForegroundColor` | `errorContainer` · `onErrorContainer` |
| 코드 색 | `unchangedTextStyle`의 `color` | `onSurface` |
| 번호 색 | `lineNumberColor` | `onSurfaceVariant`(유지 줄) |
| 줄 여백 | `linePadding` | 좌우 12, 위아래 0 |
| 번호 칸 | `lineNumberWidth` · `lineNumberPadding` | 40 · 코드 쪽 12 |
| 코드 글자 | `bodyTypography` | `codeMd`(13, 줄 높이 21) |
| 번호 글자 | `gutterTypography` | `codeSm`(12, 줄 높이 21) |
| prefix 굵기 | `prefixFontWeight` | `CoreFontWeight.bold`(700) |

### 하나만 바꾸기와 앱 전체 바꾸기

<Preview demo="code-diff/style" />

위 그림은 아래의 "CodeDiff 하나만 바꾸기" 코드처럼 선을 두르고 줄 여백을 바꾼 모습입니다. 두 코드 모두 Flutter와 Web이 같습니다.

<Split>

<Code language="dart" title="CodeDiff 하나만 바꾸기">
CodeDiff(
  lines: lines,
  codeDiffStyle: const CoreCodeDiffStyle(
    borderWidth: CoreStrokeWidth.stroke1,
    outlineColor: CoreColor.token(CoreColors.outlineVariant),
    linePadding: CoreEdgeInsets.symmetric(
      horizontal: CoreSpace.space8,
      vertical: CoreSpace.space2,
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: const CoreComponentTheme(
    codeDiff: CoreCodeDiffTheme(
      style: CoreCodeDiffStyle(lineNumberWidth: CoreSpace.space48),
    ),
  ),
)
</Code>

</Split>

### 알아 둘 점

- **테두리** — `borderWidth`와 `outlineColor`를 함께 줍니다. 기본 선 색이 투명해 폭만 키우면 선이 보이지 않고, 기본 폭이 0이라 색만 줘도 선이 없습니다.
- **코드 색** — `unchangedTextStyle`에서는 `color`만 읽습니다. 이 색은 모든 줄의 코드와 유지 줄의 prefix에 적용됩니다.
- **글자 역할** — `bodyTypography` · `gutterTypography`에는 `CoreTypography.coui.codeSm`처럼 `CoreTypography.coui`의 역할을 그대로 넣습니다. Web은 그 밖의 값을 받으면 오류를 냅니다. 이 식은 `const`로 쓸 수 없습니다.
- **글자 일부** — 크기나 자간만 바꿀 때는 `bodyTextStyle`(prefix와 코드) · `gutterTextStyle`(번호)을 씁니다. 크기를 바꿀 때는 `lineHeightPx`도 함께 줍니다. 크기만 주면 Flutter는 줄 높이 21을 지키지만 Web은 줄 높이까지 바뀝니다. 두 스타일의 `color`와 `bodyTextStyle`의 `fontWeight`도 플랫폼마다 결과가 다릅니다([플랫폼 차이](#플랫폼-차이)).
- **방향이 있는 여백** — `linePadding`에 `CoreEdgeInsets.directional` 값을 넣으면 두 플랫폼 모두 오류가 납니다. `lineNumberPadding`은 방향이 있는 값을 받습니다.
- **바깥 상자** — `OutlinedContainer`로 그립니다. 그림자처럼 `CoreCodeDiffStyle`에 없는 값은 `CoreComponentTheme.outlinedContainer`와 앱의 서페이스 스타일을 따릅니다.
- **이전 필드** — `addedColor` · `removedColor` · `rowTintAlpha` · `lineNumberAlpha`는 deprecated이고 값을 줘도 아무것도 바뀌지 않습니다. 줄 배경은 `addedBackgroundColor` · `removedBackgroundColor`로, prefix와 번호 색은 `addedForegroundColor` · `removedForegroundColor`로 정합니다. 유지 줄의 번호 색은 `lineNumberColor`입니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `CodeDiff`에 `withStyle`을 이어 `codeDiffStyle`을 덧붙일 수 있습니다. 이미 `codeDiffStyle`이 있으면 그 위에 합치며, 합친 값을 생성자에 넘긴 것과 같게 동작합니다. 같은 필드는 나중에 이은 값이 이깁니다. 테두리 폭만 바꿀 때는 `borderWidth(width)` 메서드도 쓸 수 있습니다. 아래 예제는 모서리, 테두리, 추가 · 삭제 줄의 색, 줄 여백을 바꿉니다.

<Preview component="code-diff" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class CodeDiffChainExample extends StatelessWidget {
  const CodeDiffChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const CodeDiff(
      lines: [
        CoreCodeDiffLine(
          text: "import 'package:coui_flutter/coui_flutter.dart';",
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 1,
        ),
        CoreCodeDiffLine(
          text: '',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 2,
        ),
        CoreCodeDiffLine(
          text: 'class MyWidget extends StatelessWidget {',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 3,
        ),
        CoreCodeDiffLine(
          text: '  Widget build(BuildContext context) {',
          type: CoreCodeDiffLineType.removed,
          lineNumber: 4,
        ),
        CoreCodeDiffLine(
          text: '  Widget build(BuildContext context) {',
          type: CoreCodeDiffLineType.added,
          lineNumber: 4,
        ),
        CoreCodeDiffLine(
          text: "    return Text('Hello');",
          type: CoreCodeDiffLineType.removed,
          lineNumber: 5,
        ),
        CoreCodeDiffLine(
          text: "    return Text('Hello').bodyMedium;",
          type: CoreCodeDiffLineType.added,
          lineNumber: 5,
        ),
        CoreCodeDiffLine(
          text: '  }',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 6,
        ),
        CoreCodeDiffLine(
          text: '}',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 7,
        ),
      ],
    ).withStyle(
      const CoreCodeDiffStyle(
        cornerRadius: CoreBorderRadius.all(CoreRadius.radius4),
        borderWidth: CoreStrokeWidth.stroke2,
        outlineColor: CoreColor.token(CoreColors.primary),
        addedBackgroundColor: CoreColor.token(CoreColors.infoContainer),
        addedForegroundColor: CoreColor.token(CoreColors.onInfoContainer),
        removedBackgroundColor: CoreColor.token(CoreColors.warningContainer),
        removedForegroundColor: CoreColor.token(CoreColors.onWarningContainer),
        linePadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space16,
          vertical: CoreSpace.space4,
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class CodeDiffChainExample extends StatelessComponent {
  const CodeDiffChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const CodeDiff(
      lines: [
        CoreCodeDiffLine(
          text: "import 'package:coui_web/coui_web.dart';",
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 1,
        ),
        CoreCodeDiffLine(
          text: '',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 2,
        ),
        CoreCodeDiffLine(
          text: 'class MyWidget extends StatelessComponent {',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 3,
        ),
        CoreCodeDiffLine(
          text: '  Component build(BuildContext context) {',
          type: CoreCodeDiffLineType.removed,
          lineNumber: 4,
        ),
        CoreCodeDiffLine(
          text: '  Component build(BuildContext context) {',
          type: CoreCodeDiffLineType.added,
          lineNumber: 4,
        ),
        CoreCodeDiffLine(
          text: "    return text('Hello');",
          type: CoreCodeDiffLineType.removed,
          lineNumber: 5,
        ),
        CoreCodeDiffLine(
          text: "    return Text('Hello').bodyMedium;",
          type: CoreCodeDiffLineType.added,
          lineNumber: 5,
        ),
        CoreCodeDiffLine(
          text: '  }',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 6,
        ),
        CoreCodeDiffLine(
          text: '}',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 7,
        ),
      ],
    ).withStyle(
      const CoreCodeDiffStyle(
        cornerRadius: CoreBorderRadius.all(CoreRadius.radius4),
        borderWidth: CoreStrokeWidth.stroke2,
        outlineColor: CoreColor.token(CoreColors.primary),
        addedBackgroundColor: CoreColor.token(CoreColors.infoContainer),
        addedForegroundColor: CoreColor.token(CoreColors.onInfoContainer),
        removedBackgroundColor: CoreColor.token(CoreColors.warningContainer),
        removedForegroundColor: CoreColor.token(CoreColors.onWarningContainer),
        linePadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space16,
          vertical: CoreSpace.space4,
        ),
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

`onLineTap`이 없으면 CodeDiff는 읽기만 하는 글이고, `onLineTap`을 주면 줄마다 누를 수 있는 버튼이 됩니다.

### 역할

| 플랫폼 | 표시만 할 때 | `onLineTap`을 준 줄 |
| --- | --- | --- |
| Flutter | CodeDiff가 따로 붙이는 `Semantics`가 없고, 줄의 내용은 `Text` 위젯입니다. | 줄마다 `Semantics(button: true, enabled: true)`가 붙습니다. |
| Jaspr Web | 역할이 없는 `div` · `span`입니다. | 줄을 감싼 `div`에 `role="button"`과 `tabindex="0"`이 붙습니다. |

diff 전체를 알리는 역할이나 이름은 두 플랫폼 모두 없습니다. 웹은 `<pre>` · `<code>` · `<table>` · `<ins>` · `<del>`도 쓰지 않습니다.

### 키보드

| 키 | `onLineTap`을 준 줄의 동작 |
| --- | --- |
| `Tab` · `Shift+Tab` | 줄마다 한 번씩 멈추며 앞뒤로 이동합니다. |
| `Enter` · `Space` | 포커스가 있는 줄을 `onLineTap`에 넘깁니다. 웹에서는 `Space`를 눌러도 페이지가 스크롤되지 않습니다. |

CodeDiff는 화살표 키를 따로 처리하지 않습니다. 줄이 많으면 `Tab`으로 지나야 하는 곳도 그만큼 늘어납니다. 표시만 할 때는 `Tab`이 멈추는 곳이 없습니다.

### 스크린 리더

- 줄 안의 순서는 두 플랫폼 모두 번호(보일 때만), prefix, 코드입니다.
- prefix는 CSS로 그린 장식이 아니라 실제 글자라서, 추가 · 삭제 구분이 색에만 실리지 않습니다.
- "추가된 줄" 같은 말이나 라벨은 붙이지 않습니다. 구분을 말로 전해야 하면 "한 줄을 지우고 한 줄을 추가했습니다"처럼 요약 문장을 diff 앞에 적으세요.
- 누를 수 있는 줄에도 CodeDiff가 따로 정하는 이름은 없습니다.
- 줄 내용이 바뀌어도 알려 주는 라이브 영역은 없습니다.

#### diff 전체에 이름 붙이기

이름 있는 묶음이 필요하면 바깥에서 직접 붙입니다.

<Tabs groupId="platform">
<TabItem label="Flutter" value="flutter">

```dart
Semantics(
  container: true,
  explicitChildNodes: true,
  label: 'save 함수의 변경 내용',
  child: CodeDiff(lines: lines),
)
```

</TabItem>
<TabItem label="Web" value="web">

```dart
CodeDiff(
  lines: lines,
  attributes: const {'role': 'group', 'aria-label': 'save 함수의 변경 내용'},
)
```

</TabItem>
</Tabs>

### 포커스 관리

- 화면에 나타날 때 포커스를 가져가지 않고, 포커스를 가두지도 않습니다.
- 표시만 할 때는 포커스를 받는 부분이 없습니다. CodeDiff는 스크롤 영역도 만들지 않습니다. 스크롤 상자를 직접 두면 키보드로 스크롤할 수 있는지는 그 상자에서 챙깁니다([배치](#배치)).
- 누를 수 있는 줄의 포커스 링은 키보드로 이동할 때를 위한 표시입니다. Flutter는 포커스 하이라이트가 켜질 때, 웹은 `:focus-visible`일 때 그립니다.

### 알려진 제약

| 대상 | 내용 |
| --- | --- |
| 포커스 링 | 기본 설정에서 링은 줄의 바깥쪽에 그려지는데, 바깥 상자가 넘친 부분을 잘라 냅니다. 그래서 링의 좌우 변과 첫 줄의 윗변, 마지막 줄의 아랫변이 보이지 않고, 줄이 하나뿐이면 링이 보이지 않습니다. Flutter에서는 바로 아래 줄이 추가 · 삭제 줄이면 그 줄의 배경이 링의 아랫변도 덮습니다. |
| 누르는 영역 | 누를 수 있는 줄의 누르는 영역은 그린 줄 그대로라, 글이 한 줄에 들어가면 기본 높이가 21입니다. [접근성](/accessibility) 페이지의 최소 터치 타겟 24보다 낮고, 영역만 따로 넓히지 않습니다. 누를 수 있게 쓸 때는 `linePadding`의 위아래 값을 늘리세요. 기본 설정에서 `CoreSpace.space2`를 주면 한 줄 높이가 25입니다. 터치가 주된 화면의 권장값 48에는 더 큰 값이 필요합니다. |
| 코드 의미 | 웹에서 `<pre>` · `<code>`를 쓰지 않아, 마크업만으로는 이 부분이 코드라는 것을 알 수 없습니다. |
| 줄 번호 | 번호와 그 줄의 코드를 이어 주는 관계 정보가 없습니다. |
| 큰 글자 | Flutter에서 시스템 글자 크기를 키워도 번호 칸 폭은 `lineNumberWidth`에 테마의 크기 배율만 곱한 값 그대로입니다. 글자가 커지면 번호가 칸에 다 들어가지 않아 두 줄로 나뉠 수 있으므로, 큰 글자를 지원할 때는 `lineNumberWidth`를 넓히세요. |

동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타겟처럼 모든 컴포넌트에 함께 적용되는 기준은 [접근성](/accessibility) 페이지에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 그리는 방식 | `Column` 안에 줄마다 `Row`를 두고, 코드 칸은 `Expanded`입니다. | 줄마다 `div` 안에 번호 `div`, prefix `span`, 코드 `div`를 둡니다. |
| 폭 | 받은 폭을 채우며, 폭이 정해진 부모가 필요합니다. | 블록 부모에서는 채우고, 가로 flex나 가운데 정렬한 세로 flex에서는 내용에 따릅니다. |
| 긴 낱말 | 줄에 들어가지 않으면 중간에서 나눕니다. | `CoUIWeb`이 앱 루트에 둔 `overflow-wrap: break-word`를 물려받아 나눕니다. 이 값이 없는 곳에서는 긴 낱말의 넘친 부분이 잘립니다. |
| 누를 수 있는 줄 | `Clickable`이 탭, `Enter` · `Space`, 버튼 `Semantics`를 맡습니다. | `Clickable`이 만든 `div`가 클릭과 키 입력을 받습니다. |
| `onLineTap` 타입 | `ValueChanged<CoreCodeDiffLine>?` | `CoreValueChanged<CoreCodeDiffLine>?` |
| 글자 스타일의 색 | `bodyTextStyle` · `gutterTextStyle`의 `color`를 쓰지 않습니다. | `color`를 주면 줄 종류별 색까지 덮습니다. `bodyTextStyle`은 prefix와 코드, `gutterTextStyle`은 번호의 색을 바꿉니다. |
| prefix 굵기 | 늘 `prefixFontWeight`입니다. | `bodyTextStyle`에 `fontWeight`가 있으면 그 값이 이깁니다. |
| 굵기 값 | `prefixFontWeight`가 `CoreFontWeight`에 없는 값(예: 650)이면 400으로 그립니다. | 같은 값에서 `ArgumentError`가 납니다. |
| 크기만 변경 | `bodyTextStyle` · `gutterTextStyle`에 `fontSize`만 줘도 줄 높이는 21입니다. | 줄 높이도 글자 크기를 따라 바뀝니다. 기본 스타일시트에서 코드 글자를 15로 키우면 24가 됩니다. `lineHeightPx`를 함께 주면 그 값으로 정해집니다. |
| 앱 글자 설정 | `CoreTypography.coui`의 `codeMd` · `codeSm` 값을 바로 씁니다. 앱 테마의 `typography`나 `textScaling`을 바꿔도 CodeDiff의 글자는 따라가지 않습니다. | 스타일시트를 만들 때 `ThemeConfig`에 준 `typography`의 `codeMd` · `codeSm`을 따릅니다. |
| 글자 역할 | `bodyTypography` · `gutterTypography`에 `CoreTypography.coui` 밖의 `CoreTextStyle`도 받습니다. | `CoreTypography.coui`의 역할만 받습니다. 그 밖의 값은 `ArgumentError`입니다. |
| 크기 배율 | 번호 칸 폭, 줄 여백, 번호 여백에 테마의 크기 배율을 곱합니다. | 번호 칸 폭은 `rem`, 두 여백은 간격 변수나 `rem`으로 그립니다. |
| 웹 전용 속성 | 없습니다. 이름이나 크기는 바깥 위젯으로 정합니다. | `id` · `classes` · `css` · `attributes` · `eventHandlers`가 바깥 상자에 붙습니다. |

웹의 서버 렌더(SSR · 정적 생성)에는 한 가지 차이가 더 있습니다. `text`를 HTML로 옮긴 길이가 100자를 넘거나 줄바꿈 문자가 들어 있으면, 서버가 만든 HTML의 코드 칸에 줄바꿈과 들여쓰기가 함께 들어갑니다. 코드 칸은 공백을 그대로 그리므로 그 줄에 빈 줄과 들여쓰기가 보입니다. 브라우저에서 컴포넌트가 이어받아 동작하면(hydration) 원래 글로 바뀌고, 정적 HTML로만 두는 부분에는 남습니다.

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성 이름을 씁니다.

### 위젯 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `lines` | `List<CoreCodeDiffLine>` | 필수 | 위에서 아래로 그릴 줄 |
| `showLineNumbers` | `bool` | `true` | 번호 칸 표시. `lineNumber`가 있는 줄에만 칸이 생깁니다. |
| `onLineTap` | `ValueChanged<CoreCodeDiffLine>?` (Flutter) · `CoreValueChanged<CoreCodeDiffLine>?` (Web) | `null` | 주면 모든 줄을 누를 수 있고, 누른 줄을 넘깁니다. |
| `codeDiffStyle` | `CoreCodeDiffStyle?` | `null` | 보이는 값 덮어쓰기 |

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 바깥 상자의 id |
| `classes` | `String?` | `null` | 바깥 상자에 더하는 클래스 |
| `css` | `Styles?` | `null` | 바깥 상자에 더하는 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 바깥 상자의 HTML 속성 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 바깥 상자의 이벤트 처리기 |

### `CoreCodeDiffLine` — 라인 데이터

`lines`에 담아 넘기는 Dart 데이터 클래스입니다. 두 플랫폼이 같은 클래스를 쓰고, 생성자는 `const`입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `text` | `String` | 필수 | 줄의 글 |
| `type` | `CoreCodeDiffLineType` | 필수 | `added` · `removed` · `unchanged` |
| `lineNumber` | `int?` | `null` | 번호 칸에 적는 번호 |

### 메서드

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreCodeDiffStyle patch)` | `codeDiffStyle`에 `patch`를 합친 사본을 돌려줍니다. 같은 필드는 `patch`가 이깁니다. |
| `borderWidth(double value)` | 테두리 폭만 합친 사본을 돌려줍니다. |
| `copyWith({ lines, onLineTap, … })` | 넘긴 값만 바꾼 사본을 만듭니다. `null`을 넘기면 원래 값이 남으므로 `onLineTap`이나 `codeDiffStyle`을 지우는 데는 쓸 수 없습니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.codeDiff` | `CoreCodeDiffTheme?` | `style: CoreCodeDiffStyle?` 하나로 모든 CodeDiff의 값을 정합니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreCodeDiffStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `cornerRadius` | `CoreBorderRadius?` | Outer container border-radius. Falls back to [defaultCornerRadius]. |
| `borderWidth` | `double?` | Outer container border stroke width (logical px). Falls back to [defaultBorderWidth]. |
| `prefixFontWeight` | `int?` | Font weight applied to the `+ ` / `- ` / ` ` prefix span. Falls back to [defaultPrefixFontWeight]. |
| `surfaceColor` | `CoreColor?` | Outer container background colour. Falls back to [defaultSurfaceColor]. |
| `outlineColor` | `CoreColor?` | Outer container border colour. Falls back to [defaultOutlineColor] (transparent — only visible once [borderWidth] is raised). |
| `addedBackgroundColor` | `CoreColor?` | Band face of an added row — opaque, painted across the whole row. Falls back to [defaultAddedBackgroundColor]. |
| `addedForegroundColor` | `CoreColor?` | Ink of an added row's `+ ` prefix and gutter number — the colour drawn on [addedBackgroundColor]. Falls back to [defaultAddedForegroundColor]. |
| `removedBackgroundColor` | `CoreColor?` | Band face of a removed row — opaque, painted across the whole row. Falls back to [defaultRemovedBackgroundColor]. |
| `removedForegroundColor` | `CoreColor?` | Ink of a removed row's `- ` prefix and gutter number — the colour drawn on [removedBackgroundColor]. Falls back to [defaultRemovedForegroundColor]. |
| `addedColor` | `CoreColor?` | **Deprecated (since 0.162)** — Use addedBackgroundColor (the band) and addedForegroundColor (the prefix and gutter number) instead — the band is now an opaque container token, so one colour can no longer be both the tint and the ink. No longer used — setting it has no effect on either platform. Set [addedBackgroundColor] (the band) and [addedForegroundColor] (the prefix and gutter number) instead. |
| `removedColor` | `CoreColor?` | **Deprecated (since 0.162)** — Use removedBackgroundColor (the band) and removedForegroundColor (the prefix and gutter number) instead — the band is now an opaque container token, so one colour can no longer be both the tint and the ink. No longer used — setting it has no effect on either platform. Set [removedBackgroundColor] (the band) and [removedForegroundColor] (the prefix and gutter number) instead. |
| `unchangedTextStyle` | `CoreTextStyle?` | Text style carrying the diff body ink. Its colour is the ink of the diff text on every row — added, removed and unchanged — and of an unchanged row's blank prefix; a band never recolours code (sb8 — raw `unchangedTextColor` field removed). Falls back to [defaultUnchangedTextStyle]. |
| `lineNumberColor` | `CoreColor?` | Line-number gutter text colour on a plain (unchanged) row — opaque. A band row's number reads [addedForegroundColor] / [removedForegroundColor] instead. Falls back to [defaultLineNumberColor]. |
| `rowTintAlpha` | `double?` | **Deprecated (since 0.162)** — Use addedBackgroundColor / removedBackgroundColor instead — a band is an opaque container token, not success / error at a tint alpha. No longer used — setting it has no effect on either platform. A band is [addedBackgroundColor] / [removedBackgroundColor], an opaque container token, not success / error at a tint alpha. |
| `lineNumberAlpha` | `double?` | **Deprecated (since 0.162)** — Unused — the gutter number is an opaque token: lineNumberColor on a plain row, addedForegroundColor / removedForegroundColor on a band. Hierarchy is the token, not an alpha. No longer used — setting it has no effect on either platform. The gutter number is an opaque token ([lineNumberColor] / [addedForegroundColor] / [removedForegroundColor]); hierarchy is the token chosen, not an alpha. |
| `linePadding` | `CoreEdgeInsets?` | Padding inside each diff row. Falls back to [defaultLinePadding]. |
| `lineNumberPadding` | `CoreEdgeInsets?` | Padding around the line-number text. Falls back to [defaultLineNumberPadding]. |
| `lineNumberWidth` | `double?` | Total width of the line-number gutter cell, padding included (logical px, pre-scaling). Falls back to [defaultLineNumberWidth]. |
| `bodyTypography` | `CoreTextStyle?` | Typography role for the diff body text. Falls back to [defaultBodyTypography]. |
| `gutterTypography` | `CoreTextStyle?` | Typography role for the line-number gutter text. Falls back to [defaultGutterTypography]. |
| `bodyTextStyle` | `CoreTextStyle?` | Body text style override (the diff content). |
| `gutterTextStyle` | `CoreTextStyle?` | Line-number gutter text style override. |

<!-- STYLE_TABLE:END -->

<Note>

표의 설명과 함께 알아 둘 동작입니다. `unchangedTextStyle`은 `color`만 읽습니다. `bodyTypography`와 `bodyTextStyle`은 코드와 prefix에 함께 적용됩니다. `bodyTextStyle` · `gutterTextStyle`의 `color`는 Flutter에서는 쓰지 않고, Web에서는 줄 종류별 색을 덮습니다. Web에서 `bodyTextStyle`에 `fontWeight`가 있으면 prefix 굵기는 `prefixFontWeight`가 아니라 그 값입니다. `borderWidth`는 `outlineColor`가 투명하지 않을 때만 선으로 보입니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="code-diff/related-code-snippet" title="CodeSnippet">

변경 표시 없이 코드 블록 하나를 보여 줍니다. 구문 강조와 복사 버튼이 있습니다. [CodeSnippet 문서](/components/code-snippet)

</Card>
<Card demo="code-diff/related-diff" title="Diff">

두 콘텐츠를 한 틀에 겹쳐 놓고 분할선으로 비교합니다. [Diff 문서](/components/diff)

</Card>
</Cards>
