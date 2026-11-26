---
title: SelectableText
description: 사용자가 선택하고 복사할 수 있는 텍스트 컴포넌트
category: text
platforms: [flutter, web]
related: [text, code-snippet, link]
tags: [text, selection, copy, typography]
template: v2
source: text/selectable
---

# SelectableText

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

글자를 끌어 선택한 뒤 복사해 보세요. 속성을 바꾸면 만들어진 코드가 함께 바뀝니다.

<Playground component="selectable-text" />

`SelectableText`는 읽기만 하는 글을 선택하고 복사할 수 있게 그립니다. Flutter에서는 Material의 `SelectableText`가 선택을 맡고, Jaspr Web은 `<span>` 하나에 `select-text` 클래스를 붙여 브라우저의 선택을 씁니다. 아무것도 바꾸지 않으면 `bodyMedium`(크기 14 · Regular · 줄 높이 21)에 `onSurface` 색입니다.

<Note>

**선택 색 바꾸기**는 `selectionColor`를 `info` 25%로 바꿉니다. 선택 색은 글자를 끌어 선택해야 보입니다. **onTap 횟수 보기**는 `onTap`이 불린 횟수를 글 아래에 보여 줍니다. 코드의 `countTap`과 `tapCount`는 횟수를 하나 올리고 화면을 다시 그리는 앱의 함수와 값입니다. 미리보기와 코드는 글이 여러 줄이 되도록 폭 240의 상자에 담습니다.

</Note>

## 글자 모양

글자는 `selectableTextStyle`의 `textStyle`로 바꿉니다. 비워 두면 `bodyMedium`과 `onSurface`이고, 적은 값만 그 위에 덮입니다. 글자 역할(`CoreTextStyle.token`)을 주면 크기 · 줄 높이 · 굵기가 그 역할의 값이 되고, `CoreTextStyle(fontSize: …)`처럼 값만 주면 적은 값만 바뀝니다. 이때 줄 높이는 배수라 새 크기를 따라갑니다.

<Preview demo="selectable-text/styles" height="hug" />

<Code language="dart" title="크기와 굵기만 바꾸기">
const SelectableText(
  '주문 번호 A1B2-C3D4',
  selectableTextStyle: CoreSelectableTextStyle(
    textStyle: CoreTextStyle(
      fontSize: CoreFontSize.s18,
      fontWeight: CoreFontWeight.semiBold,
    ),
  ),
)
</Code>

<Note>

크기 · 굵기 · 색은 바깥에서 물려받지 않습니다. 컴포넌트가 이 값을 자기 글에 직접 정하므로, 옅은 글자색을 내려 주는 상자 안에서도 `onSurface`로 그립니다. 다른 모양이 필요하면 `selectableTextStyle`에 적습니다. 서체를 물려받는지는 두 플랫폼이 다릅니다([플랫폼 차이](#플랫폼-차이)).

</Note>

## 여러 조각으로 된 글

`SelectableText.rich`는 글 하나 대신 자식 목록(`children`)을 받습니다. 두 플랫폼에서 같은 코드를 쓸 수 있지만, 자식을 놓는 방식과 복사되는 내용은 다릅니다.

<Preview demo="selectable-text/rich" />

<Code language="dart" title="두 조각">
SelectableText.rich(
  children: [
    Text('주문 번호 '),
    Text('A1B2-C3D4').bold,
  ],
)
</Code>

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 놓는 방식 | 자식마다 글줄 안의 상자 하나(`WidgetSpan`, 아래 맞춤)로 놓습니다. 한 자식의 긴 글은 그 상자 안에서만 줄이 바뀝니다 | `<span>` 안에 자식을 차례로 넣어, 글처럼 이어집니다 |
| `textStyle` | 자식에는 닿지 않습니다. 자식은 `SelectableText` 바깥의 글자 모양을 따릅니다 | CoUI `Text` 자식은 따로 정하지 않은 크기와 색을 물려받습니다 |
| 선택과 복사 | 자식 안의 글자는 `SelectableText`의 선택 대상이 아닙니다. 선택해서 복사하면 글자 대신 자리표시 문자(`U+FFFC`)가 담길 수 있습니다. `CoUIApp`이 앱 전체를 선택 영역으로 감싼 Flutter web에서는 자식 `Text`가 그 앱 전체 선택에는 들어갈 수 있습니다 | 브라우저가 자식의 글자까지 선택하고 복사합니다 |

<Note>

Flutter에서 사용자가 복사해야 하는 값은 `.rich`에 넣지 말고, 글 하나를 받는 기본 생성자로 씁니다.

</Note>

<a id="레이아웃"></a>

## 줄 수 제한

같은 `maxLines`도 두 플랫폼에서 다르게 보입니다.

<Preview demo="selectable-text/max-lines" height="hug" />

| `maxLines` | Flutter | Jaspr Web |
| --- | --- | --- |
| 비움 | 줄 수 제한 없이 줄을 바꿉니다. `minLines`를 주면 그 줄 수만큼의 높이는 늘 차지합니다 | 줄 수 제한 없이 줄을 바꿉니다 |
| `1` | 줄을 바꾸지 않고 한 줄로 그립니다. 넘친 글은 말줄임표 없이 가려지고, 상자 안에서 가로로 스크롤되는 부분이 됩니다. iOS에서는 손가락으로 밀어서 스크롤할 수 없습니다 | 첫 줄만 보이고, 넘치면 말줄임표로 끝납니다 |
| `2` 이상 | 높이를 그 줄 수만큼 차지해, 짧은 글도 높이가 같습니다(`minLines`를 비웠을 때). 넘친 글은 상자 안에서 세로로 스크롤해 보고, 말줄임표는 없습니다 | 글이 차지하는 만큼만 높이를 쓰고, 넘치면 그 줄 수에서 잘려 말줄임표로 끝납니다 |

Web에서 `maxLines`를 주면 루트의 `display`가 `-webkit-box`로 바뀝니다. 그래서 글줄 사이에 이어 놓았던 `SelectableText`도 자기 줄을 차지합니다.

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 상태

선택은 기본으로 켜져 있습니다. `enableInteractiveSelection: false`로 끕니다.

| `enableInteractiveSelection` | Flutter | Jaspr Web |
| --- | --- | --- |
| `true`(기본) | 마우스로 끌거나 길게 눌러 선택합니다. 선택 손잡이와 복사 메뉴는 Flutter의 것입니다 | 브라우저의 선택입니다. `select-text`를 붙여, 부모가 `user-select: none`이어도 선택할 수 있습니다 |
| `false` | 선택할 수 없고, `onTap`도 불리지 않습니다 | `select-none`으로 선택을 막습니다. `onTap`은 그대로 불립니다 |

### 선택 색

선택한 부분의 배경은 `primaryContainer`이고, 선택한 글자의 색은 바뀌지 않습니다. 선택 강조는 글자 뒤에 칠해지므로, 컴포넌트는 불투명도를 따로 곱하지 않고 준 색을 알파까지 그대로 씁니다. 그래서 `selectionColor`에 `opacity: CoreOpacity.opacity25`를 주면 두 플랫폼 모두 25%로 칠합니다.

### 누르기

`onTap`은 글을 누를 때 부르는 콜백입니다.

| 플랫폼 | 언제 불리나 |
| --- | --- |
| Flutter | 마우스로 한 번 누르거나 손가락으로 한 번 탭할 때 부릅니다. 글자를 끌어 선택할 때는 부르지 않습니다 |
| Jaspr Web | 루트 `<span>`의 `click` 이벤트에 연결합니다. 글 안에서 누르고 글 안에서 놓으면, 글자를 끌어 선택한 뒤에도 불립니다 |

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

읽기만 하는 값을 사용자가 가져가야 할 때 씁니다. 주문 번호, ID, 주소, 설치 명령처럼 옮겨 적다가 틀리기 쉬운 글이 그렇습니다. 평범한 `Text`가 원래 선택되는지는 실행하는 곳에 따라 다릅니다.

| 실행하는 곳 | 평범한 `Text` | `SelectableText`가 필요한 경우 |
| --- | --- | --- |
| Flutter 모바일 · 데스크톱 | `SelectionArea` 같은 선택 영역 안이 아니면 선택되지 않습니다 | 선택하고 복사하게 할 때 |
| `CoUIApp`으로 만든 Flutter web | 기본으로 선택됩니다. `CoUIApp`이 앱 전체를 선택 영역으로 감쌉니다(`enableWebTextSelection`, 기본 `true`) | 앱 전체 선택을 껐지만 이 글은 선택되게 할 때 |
| Jaspr Web | 브라우저가 기본으로 선택하게 둡니다 | 부모의 `user-select: none` 안에서도 선택되게 할 때 |

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 선택과 복사를 따로 챙길 필요가 없는 글 | [Text](/components/text) |
| Flutter에서 여러 `Text`를 이어서 한 번에 선택하게 할 때 | Flutter의 `SelectionArea` |
| 복사 버튼이 있는 코드 블록 | [CodeSnippet](/components/code-snippet) |
| 사용자가 값을 고쳐 써야 할 때 | [TextField](/components/text-field), 여러 줄이나 입력 칸 크기 조절이 필요하면 [TextArea](/components/text-area) |
| 눌러서 이동하거나 일을 실행할 때 | [Link](/components/link) · [Button](/components/button) |
| 제목 · 인용처럼 문서의 구조를 나타낼 때 | [TextBlock](/components/text-block) |

<a id="do"></a>
<a id="dont"></a>

<Cards columns="2">
<Card demo="selectable-text/do-copy" tone="do" eyebrow="이렇게 하세요" title="가져갈 값에 쓰기">

주문 번호처럼 옮겨 적다가 틀리기 쉬운 값은 선택해서 복사할 수 있게 둡니다.

</Card>
<Card demo="selectable-text/dont-edit" tone="dont" eyebrow="이렇게 하지 마세요" title="입력 자리처럼 쓰기">

글을 고칠 수 없습니다. 값을 받아야 하면 [TextField](/components/text-field)를 씁니다.

</Card>
</Cards>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

글자 · 선택 색 · 캐럿 모양은 `selectableTextStyle`(`CoreSelectableTextStyle`) 하나로 바꿉니다. 줄 수 · 정렬 · 선택 여부 같은 동작은 위젯 파라미터입니다.

<Split>

<Code language="dart" title="하나만 바꾸기">
SelectableText(
  '주문 번호 A1B2-C3D4',
  selectableTextStyle: CoreSelectableTextStyle(
    textStyle: CoreTextStyle.token(
      CoreTextStyles.titleMedium,
    ),
    selectionColor: CoreColor.token(
      CoreColors.infoContainer,
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    selectableText: CoreSelectableTextTheme(
      style: CoreSelectableTextStyle(
        selectionColor: CoreColor.token(
          CoreColors.infoContainer,
        ),
      ),
    ),
  ),
)
</Code>

</Split>

<a id="토큰"></a>

### 필드가 닿는 곳

| 필드 | 타입 | 비웠을 때 | Flutter | Jaspr Web |
| --- | --- | --- | --- | --- |
| `textStyle` | `CoreTextStyle?` | `bodyMedium` + `onSurface` | 글자 모양. `.rich`의 자식에는 닿지 않습니다 | 글자 모양. `.rich` 안의 CoUI `Text` 자식은 크기와 색을 물려받습니다 |
| `selectionColor` | `CoreColor?` | `primaryContainer` | 선택한 부분의 배경색 | 브라우저 선택(`::selection`)의 배경색 |
| `cursorColor` | `CoreColor?` | `primary` | 캐럿 색. `showCursor: true`일 때 보입니다 | `caret-color`로 붙습니다. 고칠 수 없는 글에는 보통 캐럿이 보이지 않습니다 |
| `cursorWidth` | `double?` | `2`(`CoreFocusRing.ringWidth`) | 캐럿 폭. 캐럿을 숨겨도 글 뒤에 이 값에 1을 더한 폭을 비웁니다 | 글 뒤에 같은 폭(이 값 + 1)을 비우고, `--coui-caret-width` 변수에 담습니다 |
| `cursorHeight` | `double?` | 글줄에 맞춤 | 캐럿 높이 | `--coui-caret-height` 변수에만 담깁니다 |
| `cursorRadius` | `CoreBorderRadius?` | 각진 모서리. iOS · macOS에서는 Flutter가 2로 둥글립니다 | 왼쪽 위 모서리 값 하나를 네 모서리에 씁니다 | `--coui-caret-radius` 변수에만 담깁니다 |

Web의 `--coui-caret-*` 변수는 정한 캐럿 크기를 도구가 읽을 수 있게 남겨 두는 값입니다. 브라우저의 캐럿 모양은 바꾸지 않습니다.

### 빠른 오버라이드 (Chain)

이미 만든 `SelectableText`에는 `withStyle`을 이어 스타일을 덧붙일 수 있습니다. 생성자의 `selectableTextStyle`에 주는 것과 같고, 겹치는 값은 뒤에 이은 것이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class SelectableTextChainExample extends StatelessWidget {
  const SelectableTextChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const SelectableText(
      '이 글자는 선택해서 복사할 수 있어요.',
    ).withStyle(
      const CoreSelectableTextStyle(
        textStyle: CoreTextStyle.token(
          CoreTextStyles.bodyLarge,
          color: CoreColor.token(CoreColors.primary),
        ),
        cursorColor: CoreColor.token(CoreColors.primary),
        cursorWidth: CoreStrokeWidth.stroke3,
        cursorRadius: CoreBorderRadius.all(CoreRadius.radius4),
        selectionColor: CoreColor.token(
          CoreColors.primary,
          opacity: CoreOpacity.opacity25,
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class SelectableTextChainExample extends StatelessComponent {
  const SelectableTextChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const SelectableText(
      '이 글자는 선택해서 복사할 수 있어요.',
    ).withStyle(
      const CoreSelectableTextStyle(
        textStyle: CoreTextStyle.token(
          CoreTextStyles.bodyLarge,
          color: CoreColor.token(CoreColors.primary),
        ),
        cursorColor: CoreColor.token(CoreColors.primary),
        cursorWidth: CoreStrokeWidth.stroke3,
        cursorRadius: CoreBorderRadius.all(CoreRadius.radius4),
        selectionColor: CoreColor.token(
          CoreColors.primary,
          opacity: CoreOpacity.opacity25,
        ),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<Note>

이 예제의 캐럿 값(`cursorColor` · `cursorWidth` · `cursorRadius`)은 캐럿이 보여야 드러납니다. Flutter는 `showCursor: true`일 때만 캐럿을 그리고, Web의 글에는 보통 캐럿이 없습니다. 다만 `cursorWidth`는 캐럿이 보이지 않아도 글 뒤에 비우는 폭을 바꿉니다.

</Note>

<a id="resolve-chain"></a>

### 값이 정해지는 순서

뒤로 갈수록 우선하고 필드마다 따로 합칩니다. `textStyle`도 크기 · 색 같은 안쪽 값끼리 합칩니다. 다만 앞 단계에서 글자 역할과 함께 정한 크기와 줄 높이는, 뒤에서 다른 글자 역할을 주면 따라오지 않고 새 역할의 값이 됩니다.

```text
CoreSelectableTextStyle 기본값                  // textStyle · cursorColor · cursorWidth · selectionColor
  → CoreComponentTheme.selectableText.style     // 앱 전체
  → selectableTextStyle                         // 하나만
```

<a id="접근성-accessibility"></a>

## 접근성

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | `semanticsLabel`이 없으면 접근성 트리에 읽기 전용 글 입력 칸(`isTextField` · `isReadOnly`)으로 올라갑니다. 그래서 스크린 리더가 입력란이라고 안내할 수 있습니다. `semanticsLabel`을 주면 안쪽 글은 트리에서 빠지고, 라벨을 가진 노드가 대신합니다 |
| Jaspr Web | `role`이 없는 `<span>`입니다. `textDirection`은 `dir`, `semanticsLabel`은 `aria-label`로 붙습니다. `attributes`도 그대로 붙지만, 두 파라미터를 주면 같은 이름의 `dir` · `aria-label`은 파라미터 값이 우선합니다 |

### 키보드

CoUI가 따로 처리하는 키는 없습니다. 아래는 Flutter와 브라우저가 원래 하는 동작입니다.

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` | 여기에 멈추지 않습니다. 프레임워크가 만드는 포커스 노드가 `Tab` 순서를 건너뛰며, `focusNode`를 받지 않아 이 동작을 바꿀 수 없습니다 | 멈추지 않습니다. `<span>`에 `tabindex`가 없습니다 |
| 전체 선택 · 복사 (`⌘A` · `⌘C`, `Ctrl+A` · `Ctrl+C`) | 글을 눌러 포커스를 받았거나 `autofocus`로 받은 뒤에는 이 글을 대상으로 합니다 | 브라우저의 동작입니다. 복사는 지금 선택한 부분을 복사하고, 전체 선택은 이 글만이 아니라 페이지를 고릅니다 |
| `Enter` · `Space` | `onTap`을 부르지 않습니다 | `onTap`을 부르지 않습니다. `Space`는 브라우저 기본 동작(페이지 스크롤)을 할 수 있습니다 |

`onTap`은 키보드로 부를 수 없습니다.

### 스크린 리더

`semanticsLabel`을 주지 않으면 화면에 그리는 글(`text`나 `children`)이 그대로 읽힐 내용입니다. `semanticsLabel`의 뜻은 플랫폼마다 다릅니다. Flutter는 글을 라벨로 바꿔 읽게 하고, Web은 글을 그대로 둔 채 `<span>`에 `aria-label`만 더합니다.

선택한 범위가 바뀌거나 복사해도 따로 알리지 않습니다. 두 플랫폼 모두 라이브 영역이 없습니다.

### 포커스 관리

오버레이가 아니라서 포커스를 옮기거나 가두지 않습니다.

| 플랫폼 | 동작 |
| --- | --- |
| Flutter | 글을 누르거나 끌어 선택하면 포커스를 받습니다. 포커스 링은 그리지 않고, `showCursor`를 켜면 캐럿이 보입니다. 앱이 실행 중일 때 포커스가 다른 곳으로 가면 선택이 풀립니다. `autofocus: true`는 처음 그릴 때 포커스를 요청합니다. `focusNode`를 받지 않아 코드로 포커스를 옮길 수는 없습니다 |
| Jaspr Web | `attributes`로 `tabindex`를 주지 않으면 포커스를 받지 않습니다. `autofocus` 파라미터는 없습니다 |

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | `onTap`에는 키보드 경로가 없어, 마우스와 터치를 쓰지 않는 사용자는 그 동작을 실행할 수 없습니다. 눌러야 하는 것은 [Link](/components/link)나 [Button](/components/button)으로 만듭니다 |
| 공통 | 선택한 범위를 알려 주는 콜백이 없습니다 |
| Flutter | `.rich`의 자식 글자는 복사에 담기지 않을 수 있고, `textStyle`도 자식에 닿지 않습니다([여러 조각으로 된 글](#여러-조각으로-된-글)) |
| Flutter | `enableInteractiveSelection: false`면 `onTap`도 불리지 않습니다 |
| Flutter | `maxLines`가 2 이상이면 짧은 글도 그 줄 수만큼 높이를 차지합니다(`minLines`를 비웠을 때) |
| Jaspr Web | `semanticsLabel`은 역할이 없는 `<span>`의 `aria-label`이 됩니다. ARIA는 이런 요소에 이름 붙이는 것을 허용하지 않아 보조 기술이 무시할 수 있습니다. 읽혀야 하는 말은 화면의 글에 담습니다. 라벨이 꼭 필요하면 `attributes: {'role': 'img'}`처럼 이름을 붙일 수 있는 역할을 함께 줄 수 있습니다. 다만 스크린 리더가 이 글을 그림으로 안내하고, 안쪽 글은 따로 읽지 않을 수 있습니다 |
| Jaspr Web | `maxLines`는 보이는 줄만 자릅니다. 잘린 글은 DOM에 남아 있어 스크린 리더가 전부 읽을 수 있고, 펼치는 버튼은 컴포넌트에 없습니다. 펼칠 수 있어야 하면 앱이 `maxLines`를 바꿉니다 |
| Jaspr Web | 루트가 인라인 `<span>`이라, 부모가 보통의 블록 상자면 `textAlign`이 보이지 않습니다([플랫폼 차이](#플랫폼-차이)) |
| Jaspr Web | 색 토큰이 아닌 값(`CoreColor(0xFF…)` 같은)으로 준 `selectionColor`는 바깥 `<span>`에만 겁니다. `.rich`의 자식 요소 안에는 칠해지지 않을 수 있습니다 |
| Jaspr Web | `onTap`을 주면 `eventHandlers`의 `click`은 불리지 않습니다 |

전역으로 적용되는 대비 · 동작 줄이기 같은 축은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

클래스와 생성자 이름은 같습니다. 선택을 맡는 쪽이 Flutter와 브라우저로 달라 다음이 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 선택 | Material `SelectableText`의 선택. 선택 손잡이 · 복사 메뉴 · 돋보기는 Flutter의 것입니다 | `<span>`과 CSS `user-select`를 쓰는 브라우저의 선택 |
| 둘레 글과의 선택 | `CoUIApp`이 Flutter web에 세우는 앱 전체 선택에 이어지지 않고 따로 선택합니다. `.rich`의 자식 `Text`는 예외일 수 있습니다 | 페이지의 다른 글과 이어서 선택할 수 있습니다 |
| `.rich` 자식 | 글줄 안의 상자(`WidgetSpan`). 이 컴포넌트의 선택 · 복사와 `textStyle`이 자식 글자에 닿지 않습니다 | `<span>` 안의 자식 요소. [여러 조각으로 된 글](#여러-조각으로-된-글) 참고 |
| 서체 | `textStyle`이나 글자 역할이 서체를 정하지 않으면 본문 서체(Pretendard)로 그립니다. 둘레의 서체를 물려받지 않습니다 | 서체를 정하지 않으면 둘레의 서체를 물려받습니다. 고정폭 상자 안에서는 고정폭으로 그립니다 |
| `maxLines` | 줄 수만큼의 높이와 상자 안 스크롤 | 줄 수에서 자르고 말줄임표 |
| `textAlign` | 글 상자 안에서 정렬합니다. 부모가 폭을 정해 주지 않으면 상자가 글 폭이라, 한 줄 글은 움직여 보이지 않습니다. `SizedBox(width:)`처럼 폭을 정한 상자에 둡니다 | 인라인 `<span>`에는 `text-align`이 적용되지 않습니다. flex · grid 부모의 항목이 되거나, `maxLines` 또는 `classes: 'block'`을 주면 적용됩니다. 상자가 글 폭이면 한 줄 글은 움직여 보이지 않습니다 |
| 줄 바꿈 문자(`\n`) | 줄을 바꿉니다 | 부모가 따로 정하지 않으면 빈칸으로 보입니다. 줄을 나누려면 `css: Styles(raw: {'white-space': 'pre-wrap'})`를 줍니다 |
| 선택을 껐을 때의 `onTap` | 불리지 않습니다 | 불립니다 |
| 누른 것으로 보는 때 | 끌어서 선택할 때는 부르지 않습니다 | 글 안에서 끌어 선택하고 놓으면, 선택한 뒤에도 불립니다 |
| `semanticsLabel` | 글을 대신합니다 | `aria-label`을 더합니다 |
| 캐럿 크기 | `cursorWidth` · `cursorHeight` · `cursorRadius`에 테마의 크기 배율을 곱합니다 | `rem`으로 정해 브라우저의 글자 크기를 따릅니다 |
| 서버 렌더 | 해당 없음 | 선택은 브라우저가 하므로 서버에서 그린 글도 선택됩니다. `onTap`은 브라우저에서 실행되는 컴포넌트에서만 불립니다 |
| 한쪽에만 있는 파라미터 | `autofocus` · `showCursor` · `minLines` | `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="props-parameters"></a>

## API

타입의 `W`는 `.rich` 자식의 타입으로, Flutter는 `Widget`, Web은 `Component`입니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `text` | `String?` | — | 표시할 글. 기본 생성자의 첫 번째 위치 인자이고 필수입니다. `.rich`에서는 `null`입니다 |
| `children` | `List<W>?` | — | `.rich`의 필수 인자. 기본 생성자에서는 `null`입니다 |
| `selectableTextStyle` | `CoreSelectableTextStyle?` | `null` | 글자 · 선택 색 · 캐럿 모양. [필드가 닿는 곳](#필드가-닿는-곳) |
| `maxLines` | `int?` | `null` | 줄 수 제한. [줄 수 제한](#줄-수-제한). Flutter는 1 이상이어야 합니다 |
| `textAlign` | `CoreTextAlign?` | `null` | 가로 정렬(`start` · `end` · `center` · `justify` · `left` · `right`). 비우면 위에서 내려온 정렬을 따릅니다 |
| `textDirection` | `CoreTextDirection?` | `null` | 글 방향(`ltr` · `rtl`). 비우면 위에서 내려온 방향을 따릅니다 |
| `enableInteractiveSelection` | `bool` | `true` | 선택을 허용합니다. [상태](#상태) |
| `semanticsLabel` | `String?` | `null` | 보조 기술에 줄 라벨. 플랫폼마다 뜻이 다릅니다([접근성](#접근성)) |
| `onTap` | `void Function()?` | `null` | 글을 누를 때 부릅니다. [누르기](#누르기) |
| `autofocus` | `bool` | `false` | Flutter만. 처음 그릴 때 포커스를 요청합니다 |
| `showCursor` | `bool` | `false` | Flutter만. 포커스가 있을 때 캐럿을 보입니다 |
| `minLines` | `int?` | `null` | Flutter만. 늘 차지할 최소 줄 수. 1 이상이고 `maxLines`를 넘지 않아야 합니다 |

Web은 `id` · `classes` · `css` · `attributes` · `eventHandlers`를 더 받아 루트 `<span>`에 붙입니다. `classes`는 컴포넌트의 클래스 뒤에 더하고, `css`는 컴포넌트의 인라인 스타일보다 우선합니다.

### 그 밖의 멤버와 테마

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreSelectableTextStyle patch)` | `selectableTextStyle`에 `patch`를 합친 사본을 돌려줍니다. 겹치는 값은 `patch`가 이깁니다 |
| `copyWith({text, selectableTextStyle, …})` | 바꾼 값으로 사본을 만듭니다 |
| `CoreComponentTheme.selectableText` | `CoreSelectableTextTheme(style: …)`로 앱 전체 기본 스타일을 둡니다 |

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="Text" href="/components/text" more="Text 보기">

글자 역할과 색을 골라 쓰는 기본 글입니다.

</Card>
<Card title="CodeSnippet" href="/components/code-snippet" more="CodeSnippet 보기">

복사 버튼이 있는 코드 블록입니다.

</Card>
<Card title="Link" href="/components/link" more="Link 보기">

눌러서 이동하는 글자 링크입니다.

</Card>
</Cards>
