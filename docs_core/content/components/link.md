---
title: Link
description: 다른 화면이나 URL 로 이동하는 글자 링크입니다. 문장 안에는 늘 밑줄이 있는 Link.inlineSpan 을, 목록 · 푸터처럼 홀로 놓이는 자리에는 Link 를 씁니다.
category: display
platforms: [flutter, web]
related: [button, text, breadcrumb]
tags: [link, navigation, text, anchor]
template: v2
source: text/link
---

# Link

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 링크를 확인하고, 만들어진 코드를 복사하세요. Flutter 의 `Link` 는 URL 을 직접 열지 않아 코드에 `onPressed` 가 들어가고, Web 은 `onPressed` 없이 `href` 로 이동합니다. 그래서 두 플랫폼의 코드가 다릅니다.

<Playground component="link" />

Web 미리보기의 링크는 실제 `<a href>` 라서 누르면 이동합니다. 미리보기의 주소는 이 페이지입니다. Flutter 미리보기의 `onPressed` 는 비어 있어 눌러도 이동하지 않습니다.

## 구조

링크는 라벨 하나와, 그 앞뒤에 둘 수 있는 두 슬롯으로 이루어집니다. `leading` · `trailing` 은 위젯 파라미터 이름과 같습니다.

<Anatomy demo="link/anatomy">
<AnatomyItem part="container" name="Container">

링크 전체입니다. 배경과 테두리는 없고, 포커스 링이 이 둘레에 그려집니다.

</AnatomyItem>
<AnatomyItem part="leading" name="leading">

라벨 앞의 아이콘 슬롯입니다. 선택 사항입니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="child">

라벨입니다. `child` 를 비우면 `href` 문자열이 라벨이 됩니다.

</AnatomyItem>
<AnatomyItem part="trailing" name="trailing">

라벨 뒤의 아이콘 슬롯입니다. 선택 사항입니다.

</AnatomyItem>
</Anatomy>

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 이동과 콜백

`href` 는 늘 필요합니다. 실제로 누가 이동하는지는 플랫폼과 `onPressed` 에 따라 다릅니다.

| 조합 | Flutter | Web |
| --- | --- | --- |
| `onPressed` 없음 | 눌러도 이동하지 않고 아무 일도 일어나지 않습니다. | `<a href>` 를 그리고 브라우저가 이동합니다. |
| `onPressed` 있음 | 콜백을 실행합니다. 화면 전환이나 URL 열기는 콜백에서 합니다. | `<div role="link">` 를 그리고 콜백만 실행합니다. `href` 는 `data-href` 속성으로 남고, 그 주소로 이동하지 않습니다. |

<Split>

<Code language="dart" title="Flutter">
Link(
  href: '/docs/theming',
  onPressed: openThemingGuide,
  child: Text('테마 가이드'),
)
</Code>

<Code language="dart" title="Web">
Link(
  href: '/docs/theming',
  child: Text('테마 가이드'),
)
</Code>

</Split>

<a id="external"></a>

### external — 새 탭

`external` 의 기본값은 `false` 입니다. 켰을 때 하는 일은 링크를 그리는 방식에 따라 다릅니다.

| 그리는 방식 | `external: true` 가 하는 일 |
| --- | --- |
| Web `Link`, `onPressed` 없음 | `<a>` 에 `target="_blank"` 와 `rel="noopener noreferrer"` 를 붙여 새 탭에서 엽니다. |
| Web `Link`, `onPressed` 있음 | `data-external="true"` 표시만 남깁니다. 새 창이 필요하면 콜백에서 엽니다. |
| Web `Link.inlineSpan` | `<a>` 에 `target` 과 `rel` 을 붙입니다. `onPressed` 를 주면 클릭은 콜백이 대신 처리합니다. |
| Flutter `Link` · `Link.inlineSpan` | 화면과 동작이 달라지지 않습니다. 콜백은 인자를 받지 않으므로, 앱 밖에서 열지는 `onPressed` 안에서 직접 정합니다. |

`external: true` 는 아이콘이나 안내 문구를 만들지 않습니다. 아이콘은 `trailing` 에 직접 넣고, 새 탭으로 열린다는 안내는 라벨에 적습니다.

### 이동하면서 클릭 기록하기 (Web)

Web `Link` 에서 `onPressed` 는 이동을 대신합니다. 이동은 그대로 두고 클릭만 함께 받으려면 `onPressed` 대신 Web 전용 `eventHandlers` 를 씁니다. `<a href>` 의 이동을 막지 않습니다.

```dart
// Web 전용
Link(
  href: '/pricing',
  eventHandlers: {
    'click': [(_) => recordPricingClick()],
  },
  child: Text('요금 보기'),
)
```

Web 에서 버튼 모양의 이동이면 [Button](/components/button) 의 `href` 를 씁니다. Web 의 `Button` 은 `href` 와 `onPressed` 를 함께 주면, 활성 상태에서 `<a href>` 를 그리고 이동을 막지 않은 채 콜백을 실행합니다.

<Note>

Web 의 콜백은 브라우저에서 실행되는 컴포넌트(`@client`) 안에서만 연결됩니다. 서버에서만 그린 화면에서는 `onPressed` 가 있는 `Link` 를 눌러도 아무 일도 일어나지 않습니다. `onPressed` 가 없는 링크는 `<a href>` 라서 이동에 클라이언트 코드가 필요하지 않습니다.

</Note>

<a id="변형-variants"></a>

## Variant

`variant`(`CoreLinkVariant`)는 색의 톤만 고릅니다. 밑줄은 `underline` 으로 따로 고르므로 두 값은 어느 조합으로도 쓸 수 있습니다.

<a id="default"></a>
<a id="muted"></a>

<VariantRow name="standard" component="link" props="variant=standard" label="자세히 보기">

링크 전용 색(`CoreColors.link`)을 씁니다. 링크라는 것을 알아봐야 하는 자리에 씁니다. 기본값입니다.

</VariantRow>

<VariantRow name="muted" component="link" props="variant=muted" label="이용약관">

보조 글자 색(`onSurfaceVariant`)을 씁니다. 푸터 · 캡션처럼 내용을 받치는 자리에 씁니다. 보조 설명 글자와 같은 색이라, 그런 글 사이에 섞이면 색으로는 링크를 알아볼 수 없습니다.

</VariantRow>

<a id="underline"></a>

## 밑줄

<Preview demo="link/underline" />

| `underline` | 평소 | hover · 눌림 · 키보드 포커스 |
| --- | --- | --- |
| `false` (기본값) | 밑줄이 없습니다. | `linkStyle.interactionTextDecoration` 의 장식을 보입니다. 기본값은 밑줄입니다. |
| `true` | 늘 밑줄이 있습니다. | 밑줄이 그대로 있습니다. |

- `underline: false` 는 목록 · 푸터 · 카드 하단처럼 홀로 놓이는 링크에 씁니다.
- 색만으로 링크를 알아보기 어려운 자리에는 `underline: true` 를 씁니다. 문장 안에는 늘 밑줄인 [`Link.inlineSpan`](#문장-안의-링크) 을 씁니다.
- 밑줄의 두께와 위치는 정하는 필드가 없고 글꼴 자체의 값(`post` 표)을 따릅니다. 밑줄 색은 글자색을 따라가며, `underlineColor` 를 지정하면 따로 정해집니다.
- 밑줄은 라벨에 그립니다. `leading` · `trailing` 아이콘에는 긋지 않습니다.

<a id="아이콘-leading-trailing"></a>

## 아이콘

<Preview demo="link/icons" />

`leading` 은 링크가 무엇인지, `trailing` 은 어디로 가는지를 알리는 아이콘에 씁니다. 아이콘은 라벨과 한 줄에서 세로 가운데에 놓입니다. 크기는 16(`CoreLinkStyle.defaultIconStyle`), 라벨과의 간격은 4(`CoreLinkStyle.defaultIconLabelGapStyle`)입니다.

아이콘은 링크의 글자색을 따르므로 `variant` 나 `color` 를 바꾸면 함께 바뀝니다. 아이콘만 다른 색이 필요하면 `linkStyle.iconStyle.color` 를 지정합니다. `Icon` 에 직접 준 `iconStyle` 이나 테마의 `CoreComponentTheme.icon` 에 정한 크기 · 색은 링크가 주는 값보다 우선합니다.

```dart
// Flutter 에서는 onPressed 를 함께 주고, 그 안에서 주소를 엽니다.
Link(
  href: 'https://github.com/coco-de/coui',
  external: true,
  trailing: Icon(LucideIcons.externalLink),
  child: Text('GitHub에서 보기 (새 탭)'),
)
```

<a id="문장-안의-링크-inline-span"></a>

## 문장 안의 링크

문단 · 표 칸 · 제목처럼 글이 흐르는 자리에는 위젯 `Link` 대신 `Link.inlineSpan` 을 씁니다.

<Preview demo="link/inline" />

- 주변 문장과 함께 줄이 바뀌고, 글자 크기 · 굵기 · 행간을 주변에서 물려받습니다. 색은 `CoreLinkStyle` 에서 옵니다.
- 문장 안에서는 색만으로 링크를 알아보기 어려워 늘 밑줄을 긋습니다. 끄는 파라미터는 없습니다.
- 위젯 `Link` 는 자기 라벨 역할(`labelXl`)로 글자를 그려 주변 글자와 모양이 달라집니다. Flutter 에서는 `WidgetSpan` 으로만 문장에 넣을 수 있어, 링크 글 중간에서 주변 문장과 함께 줄을 바꾸지도 못합니다. Web 에서 `onPressed` 가 있는 `Link` 는 `<div>` 라서 `<p>` 안에 넣을 수도 없습니다.
- 라벨은 `text` 로 줍니다. 링크 글 안에 굵게 · 코드 같은 모양이 있으면 `children` 을 씁니다. 둘 다 비우면 `href` 가 라벨이 됩니다. 두 값은 하나만 주세요. 함께 주면 Flutter 는 `text` 뒤에 `children` 을 이어 그리고, Web 은 `children` 만 그립니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart' show GestureRecognizer;

class ThemingNote extends StatefulWidget {
  const ThemingNote({required this.onOpenGuide, super.key});

  final VoidCallback onOpenGuide;

  @override
  State<ThemingNote> createState() => _ThemingNoteState();
}

class _ThemingNoteState extends State<ThemingNote> {
  // 탭 인식기는 이 State 가 가지고 있다가 정리합니다.
  final _recognizers = <GestureRecognizer>[];

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: '토큰을 덮어쓰기 전에 '),
          Link.inlineSpan(
            context,
            href: '/docs/theming',
            text: '테마 가이드',
            onPressed: widget.onOpenGuide,
            recognizers: _recognizers,
          ),
          const TextSpan(text: '를 먼저 읽어 주세요.'),
        ],
      ),
    ).bodyMedium;
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
import 'package:coui_web/coui_web.dart';

class ThemingNote extends StatelessComponent {
  const ThemingNote({super.key});

  @override
  Component build(BuildContext context) {
    return p([
      const Text('토큰을 덮어쓰기 전에 '),
      Link.inlineSpan(context, href: '/docs/theming', text: '테마 가이드'),
      const Text('를 먼저 읽어 주세요.'),
    ]);
  }
}
```

  </TabItem>
</Tabs>

| 플랫폼 | `onPressed` 없음 | `onPressed` 있음 |
| --- | --- | --- |
| Flutter | 색과 밑줄만 있는 글자입니다. 누를 수 없고 링크로 알려지지 않습니다. | `TapGestureRecognizer` 를 붙여 탭을 받습니다. 인식기를 담을 `recognizers` 목록을 함께 줍니다. 없으면 디버그 모드에서 단언 오류가 납니다. |
| Web | `<a href>` 로 이동합니다. | 클릭하면 이동 대신 콜백을 실행합니다. `href` 는 `<a>` 에 남습니다. |

Flutter 에서 `children` 안의 글자 조각은 모두 같은 탭 인식기를 받습니다. 이미 인식기가 있는 조각은 자기 것을 유지하고, `WidgetSpan` 에는 붙지 않습니다.

<a id="애니메이션"></a>

## 상태

링크에는 비활성 · 선택 상태가 없습니다. `enabled` 파라미터가 없고, 방문한 링크를 따로 칠하지도 않습니다.

| 상태 | 동작 |
| --- | --- |
| 기본 | `variant` 의 색입니다. `underline: false` 면 밑줄이 없습니다. |
| Hover | 포인터 커서로 바뀌고 밑줄을 보입니다. |
| 눌림 | 밑줄을 보입니다. 글자 크기는 줄어들지 않습니다(`pressedScale` 1.0). |
| 키보드 포커스 | 밑줄과 포커스 링(두께 2, 간격 2)을 보입니다. |
| 전환 | 테마나 `variant` 가 바뀌어 색이 달라질 때 150ms(`CoreDuration.fast`) 동안 `move` 곡선(ease-in-out)으로 바뀝니다. 밑줄은 서서히 나타나지 않고 한 번에 바뀝니다. Web 의 밑줄은 바로 바뀌고, Flutter 의 위젯 `Link` 는 이 전환 시간의 절반이 지날 때 바뀝니다. 동작 줄이기를 켜면 색과 밑줄 모두 바로 바뀝니다. |

밑줄 상태 셋(hover · 눌림 · 키보드 포커스)은 `underline: false` 인 위젯 `Link` 에 해당합니다. `underline: true` 와 `inlineSpan` 은 처음부터 밑줄이 있습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 본문 문장 가운데에 이동할 곳을 둘 때 (`Link.inlineSpan`)
- 목록 · 푸터 · 카드 하단에서 다른 화면으로 이동할 때 (`Link`)
- 다른 사이트로 나가는 이동을 알릴 때 (`external` 과 안내 글 · 아이콘)
- 이용약관 · 개인정보처리방침 같은 보조 링크를 둘 때 (`variant: CoreLinkVariant.muted`)

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 이동하거나 누를 일이 없는 글자 | [Text](/components/text) |
| 제출 · 삭제 같은 동작, 버튼 모양의 이동 | [Button](/components/button) |
| 목적지 하나가 아니라 상위 화면까지의 경로 | [Breadcrumb](/components/breadcrumb) |

### 문장 속과 라벨

<Cards columns="2">
<Card demo="link/do-inline" tone="do" eyebrow="이렇게 하세요">

문장 안에는 `Link.inlineSpan` 을 씁니다. 늘 밑줄이 있고 주변 글자의 크기를 따릅니다.

</Card>
<Card demo="link/dont-inline" tone="dont" eyebrow="이렇게 하지 마세요">

문장 안에 `underline: false` 인 `Link` 를 끼우면 평소에는 색으로만 구분됩니다. 라벨 글자 모양도 주변과 달라집니다.

</Card>
<Card demo="link/do-label" tone="do" eyebrow="이렇게 하세요">

라벨만 읽어도 어디로 가는지 알 수 있게 적습니다.

</Card>
<Card demo="link/dont-label" tone="dont" eyebrow="이렇게 하지 마세요">

"여기" 같은 라벨은 목적지를 말하지 않습니다. 링크만 모아 읽으면 구분할 수 없습니다.

</Card>
</Cards>

<a id="dont"></a>

### 이동과 동작

<Cards columns="2">
<Card demo="link/do-action" tone="do" eyebrow="이렇게 하세요">

데이터를 바꾸거나 일을 실행하는 것은 `Button` 으로 만듭니다.

</Card>
<Card demo="link/dont-action" tone="dont" eyebrow="이렇게 하지 마세요">

링크는 다른 곳으로 이동한다는 뜻입니다. 동작에 쓰면 보조 기술의 "링크" 안내와 실제로 일어나는 일이 어긋납니다.

</Card>
</Cards>

<a id="do"></a>

### 밖으로 나가는 링크

다른 사이트로 나가는 링크에는 `external: true` 를 적고, 새 탭으로 열린다는 것을 라벨에 적습니다. `external` 만으로 새 탭이 열리는 것은 Web 의 `Link` 와 `inlineSpan` 에 `onPressed` 를 주지 않았을 때입니다. Flutter 와 콜백으로 여는 링크는 `onPressed` 에서 여는 방법을 직접 정합니다.

<a id="스타일-시스템-style-system"></a>
<a id="스타일-커스터마이징-styling"></a>

## 테마와 스타일

이동과 동작, 내용, 종류를 정하는 값(`href` · `external` · `onPressed` · `child` · `leading` · `trailing` · `variant` · `underline`)은 위젯 파라미터로 넘깁니다. 색 · 전환 시간 · 라벨 글자 · 아이콘 · 간격 · 포커스 링 같은 겉모습은 `linkStyle`(`CoreLinkStyle`) 하나로 바꿉니다.

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
CoreLinkStyle.defaultsByVariant[variant], CoreLinkStyle.defaultX   // 디자인 시스템 기본값
  → CoreLinkTheme.style                      // 앱 전체
  → CoreLinkTheme.variantStyles[variant]     // 앱 전체, variant 별
  → linkStyle                                // 링크 하나
```

- 값은 필드마다 합칩니다. `labelStyle` · `clickableStyle` · `iconStyle` · `iconLabelGapStyle` 은 그 안의 필드까지 합칩니다.
- `CoreLinkTheme.style` 에 `color` 를 적으면 `standard` 와 `muted` 가 모두 그 색이 됩니다. 한 variant 만 바꾸려면 `variantStyles` 를 씁니다.
- 글자색은 위 순서로 모두 합친 다음에 `labelStyle.color`, `color`, variant 기본색 순으로 고릅니다. 그래서 테마에 `labelStyle.color` 를 두면 링크 하나에 적은 `color` 는 보이지 않습니다.
- 밑줄 색은 `underlineColor` 를 지정하지 않으면 글자색을 따릅니다.
- 포커스 링은 `CoreComponentTheme.clickable.style` 의 값도 읽으며, `linkStyle.clickableStyle` 이 그보다 우선합니다.

### 사용 예

<Split>

<Code language="dart" title="링크 하나만 바꾸기">
Link(
  href: '/terms',
  linkStyle: CoreLinkStyle(
    color: CoreColor.token(CoreColors.secondary),
    underlineColor: CoreColor.token(CoreColors.secondary),
  ),
  child: Text('보조 링크'),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    link: CoreLinkTheme(
      style: CoreLinkStyle(
        labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
      ),
      variantStyles: {
        CoreLinkVariant.muted: CoreLinkStyle(
          color: CoreColor.token(CoreColors.onSurface),
        ),
      },
    ),
  ),
)
</Code>

</Split>

두 예제의 스타일 값은 Flutter 와 Web 이 같습니다. Flutter 의 `Link` 에는 `onPressed` 를 함께 주어야 눌렀을 때 일이 일어납니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

이미 만든 `Link` 에 `withStyle` 을 이어 `linkStyle` 을 덧붙일 수 있습니다. 생성자의 `linkStyle` 과 같게 동작하고, 겹치는 필드는 뒤에 이은 값이 이깁니다.

<Preview component="link" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class LinkChainExample extends StatelessWidget {
  const LinkChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Link(
      href: '#',
      child: Text('자세히 보기'),
    ).withStyle(
      const CoreLinkStyle(
        color: CoreColor.token(CoreColors.secondary),
        underlineColor: CoreColor.token(CoreColors.tertiary),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class LinkChainExample extends StatelessComponent {
  const LinkChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Link(
      href: '#',
      child: const Text('자세히 보기'),
    ).withStyle(
      const CoreLinkStyle(
        color: CoreColor.token(CoreColors.secondary),
        underlineColor: CoreColor.token(CoreColors.tertiary),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

### 기본값이 있는 곳

Flutter 와 Web 이 `coui_core` 의 `CoreLinkStyle` 에 있는 같은 값을 읽습니다.

| 이름 | 값 |
| --- | --- |
| `CoreLinkStyle.defaultsByVariant[variant]` | variant 별 글자색과 밑줄 색 |
| `CoreLinkStyle.defaultInteractionTextDecoration` | 밑줄 |
| `CoreLinkStyle.defaultTransitionDuration` | 150ms (`CoreDuration.fast`) |
| `CoreLinkStyle.defaultLabelStyle` | `labelXl` 글자 역할 |
| `CoreLinkStyle.defaultClickableStyle` | 누름 크기 1.0 (줄어들지 않음) |
| `CoreLinkStyle.defaultIconStyle` | 크기 16, 색은 글자색 |
| `CoreLinkStyle.defaultIconLabelGapStyle` | 간격 4 |

<a id="접근성-accessibility"></a>

## 접근성

### 역할

| 그리는 방식 | 역할 |
| --- | --- |
| Flutter `Link` (모바일 · 데스크톱) | 한 노드에 링크와 버튼 표시가 함께 붙습니다. |
| Flutter `Link` (Flutter Web) | 버튼 표시만 붙고 링크 표시는 붙지 않습니다. |
| Flutter `Link.inlineSpan` | `onPressed` 가 있으면 탭 인식기가 링크로 표시합니다. 없으면 일반 글자입니다. |
| Jaspr Web `Link`, `onPressed` 없음 | 네이티브 `<a href>` 링크입니다. |
| Jaspr Web `Link`, `onPressed` 있음 | `<div role="link" tabindex="0">` 입니다. |
| Jaspr Web `Link.inlineSpan` | 네이티브 `<a href>` 링크입니다. |

### 키보드

| 대상 | `Tab` | `Enter` | `Space` |
| --- | --- | --- | --- |
| Flutter `Link` | 포커스가 옵니다. | `onPressed` 를 실행합니다. | `onPressed` 를 실행합니다. |
| Flutter `Link.inlineSpan` | 포커스가 오지 않습니다. | 해당 없음 | 해당 없음 |
| Web `<a href>` (`Link` · `inlineSpan`) | 포커스가 옵니다. | 이동합니다. | 링크를 실행하지 않습니다. 브라우저 기본 동작(페이지 스크롤)을 따릅니다. |
| Web `Link`, `onPressed` 있음 | 포커스가 옵니다. | `onPressed` 를 실행합니다. | `onPressed` 를 실행하고 페이지 스크롤을 막습니다. |
| Web `inlineSpan`, `onPressed` 있음 | 포커스가 옵니다. | `onPressed` 를 실행합니다. | 링크를 실행하지 않습니다. |

### 스크린 리더

위젯 `Link` 의 접근 가능한 이름은 `child` 의 글입니다. `child` 를 생략하면 `href` 문자열이 이름이 됩니다.

`leading` · `trailing` 에 넣은 아이콘에는 이름이 없습니다. 외부 링크 아이콘만으로는 새 탭이나 다른 사이트라는 뜻이 전달되지 않습니다. `external` 에 따라 붙는 안내 문구나 접근성 이름도 어느 플랫폼에도 없습니다. 알려야 할 내용은 라벨에 적습니다. Web 은 `attributes` 의 `aria-label` 로 이름을 바꿀 수 있습니다. 이때 화면에 보이는 글을 이름에 그대로 포함합니다.

라이브 영역은 없습니다.

### 포커스 관리

마운트될 때 포커스를 옮기지 않고 포커스를 가두지도 않습니다.

| 대상 | 포커스 링 |
| --- | --- |
| Flutter `Link` | 키보드로 이동해 왔을 때 `FocusOutline` 을 그립니다. |
| Web `Link` | `:focus-visible` 일 때 CoUI 포커스 링을 그립니다. `<a href>` 는 브라우저 기본 표시 대신 이 링을 씁니다. |
| Web `inlineSpan` | 위젯 `Link` 와 같은 링을 그립니다. |
| Flutter `inlineSpan` | 없습니다. 스팬은 포커스를 받지 않습니다. |

링의 색과 두께는 `linkStyle.clickableStyle.focusOutlineStyle` 의 `borderColor` · `borderWidth` 로, 링크에서 링 바깥 끝까지의 거리는 `align` 으로 바꿉니다. 링의 모서리는 `linkStyle.clickableStyle.borderRadius` 를 따릅니다. `focusOutlineStyle` 의 `borderRadius` · `ringOpacity` · `duration` 은 Flutter 에서만 반영합니다. 포커스를 받으면 `underline: false` 인 위젯 `Link` 도 밑줄을 보입니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 기본 링크(`underline: false`)는 평소에 색으로만 구분됩니다. 주변 글자와 색으로만 갈리는 자리에서는 색을 구별하기 어려운 사용자가 링크를 알아보지 못할 수 있습니다(WCAG 1.4.1). 문장 안은 `inlineSpan`, 그 밖에는 `underline: true` 를 씁니다. |
| 공통 | 비활성 상태가 없습니다. 이동할 수 없는 자리에는 `Link` 대신 `Text` 를 둡니다. |
| Flutter | `Link` 는 URL 을 열지 않습니다. `onPressed` 가 없어도 Tab 포커스를 받고, 커서와 밑줄이 반응하며, 활성 상태로 알려집니다. 누르면 아무 일도 일어나지 않습니다. |
| Flutter | `inlineSpan` 은 `Tab` 으로 닿을 수 없고 포커스 링이 없습니다. 키보드로 닿아야 하는 링크에는 위젯 `Link` 를 씁니다. |
| Flutter | `leading` · `trailing` 이 있는 링크는 라벨이 줄을 바꾸지 않습니다. 쓸 수 있는 폭보다 라벨과 아이콘이 길면 넘칩니다. 아이콘을 함께 쓰는 라벨은 짧게 적습니다. |
| Flutter | 위젯 `Link` 의 `labelStyle` 에 `CoreTextStyle.token` 으로 글자 역할을 주면 크기 · 행간 · 굵기 · 자간이 바뀌지 않습니다. `fontSize` · `fontWeight` 처럼 값을 직접 적습니다. |
| Flutter Web | 위젯 `Link` 는 링크가 아니라 버튼으로 알려집니다. |
| Jaspr Web | `onPressed` 가 있는 `Link` 는 `<a>` 가 아닙니다. 가운데 클릭, 컨텍스트 메뉴의 "새 탭에서 열기", 주소 미리보기 같은 브라우저의 링크 기능이 없고, 검색 엔진이 따라갈 `href` 도 없습니다. 이동만 하는 링크에는 `onPressed` 를 주지 않습니다. |
| Jaspr Web | `onPressed` 를 준 `inlineSpan` 은 `Ctrl` · `⌘` 를 누른 채 클릭해도 콜백을 실행하고 새 탭을 열지 않습니다. |

#### 전역 접근성

대비 · 동작 줄이기처럼 모든 컴포넌트에 함께 걸리는 항목은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`href` · `external` · `underline` · `variant` · `onPressed` · `child` · `leading` · `trailing` · `linkStyle` 은 두 플랫폼이 같은 이름을 씁니다. 이동을 처리하는 방식과 그리는 방식은 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 이동 | `onPressed` 에서 직접 처리합니다. | `onPressed` 가 없으면 브라우저가 이동합니다. |
| `href` 가 쓰이는 곳 | 위젯 `Link` 에서는 `child` 가 없을 때의 라벨입니다. | `<a href>` 의 주소입니다. 콜백이 있는 `Link` 에서는 `data-href` 입니다. `child` 가 없으면 라벨이기도 합니다. |
| `external` | 위젯이 읽지 않습니다. | `<a>` 로 그릴 때 `target` 과 `rel` 을 붙입니다. |
| 그리는 요소 | `Clickable` 안의 글자 | 콜백이 없으면 `<a href>`, 있으면 `<div role="link">` |
| 슬롯 타입 | `Widget?` | `Component?` |
| 콜백 타입 | `VoidCallback?` | `CoreVoidCallback?` |
| 문장 안 링크 | `TextSpan`. `onPressed` 가 있으면 `TapGestureRecognizer` 를 붙이고 `recognizers` 를 받습니다. | 인라인 `<a href>`. `recognizers` 파라미터가 없습니다. |
| 밑줄 상태 감지 | `Clickable` 의 hover · 포커스 · 눌림 콜백 | CSS 의 `:hover` · `:focus-visible` · `:active` |
| 밑줄 두께 · 위치 | `TextDecoration` 의 글꼴 기본값 | `text-decoration-thickness` 와 `text-underline-position` 모두 `from-font` (글꼴 기본값) |
| 문장 안 링크의 포커스 | 포커스 링과 키보드 실행이 없습니다. | CoUI 포커스 링을 그리고 `Enter` 로 실행합니다. |
| 포커스 링 조정 | `focusOutlineStyle` 의 `borderRadius` · `ringOpacity` · `duration` 도 반영합니다. | 이 세 필드는 읽지 않습니다. 모서리는 `clickableStyle.borderRadius` 로 정합니다. |
| 아이콘이 있는 긴 라벨 | 줄을 바꾸지 않습니다. | 라벨이 줄을 바꿀 수 있습니다. |
| HTML 속성 | 없습니다. | `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="props-parameters"></a>

## API

표의 `W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `href` | `String` | 필수 | 이동할 주소. `child` 가 없으면 이 문자열이 라벨이 됩니다. |
| `onPressed` | `VoidCallback?` (Flutter) · `CoreVoidCallback?` (Web) | `null` | 링크를 누르거나 키보드로 실행할 때 부릅니다. Web 에서는 이동을 대신합니다. |
| `external` | `bool` | `false` | 밖으로 나가는 링크인지 알립니다. 하는 일은 [external — 새 탭](#external-새-탭)의 표를 따릅니다. |
| `underline` | `bool` | `false` | 밑줄을 늘 그립니다. `false` 면 hover · 눌림 · 키보드 포커스 때 `interactionTextDecoration` 을 보입니다. |
| `variant` | `CoreLinkVariant` | `standard` | 색의 톤. `standard` 는 링크 색, `muted` 는 보조 글자 색입니다. |
| `child` | `W?` | `null` | 라벨 |
| `leading` | `W?` | `null` | 라벨 앞의 아이콘 |
| `trailing` | `W?` | `null` | 라벨 뒤의 아이콘 |
| `linkStyle` | `CoreLinkStyle?` | `null` | 겉모습 덮어쓰기 |

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트 요소(`<a>` 또는 `<div>`)의 id |
| `classes` | `String?` | `null` | 루트 요소에 더하는 CSS 클래스. 배치에 씁니다. |
| `css` | `Styles?` | `null` | 루트 요소의 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 루트 요소에 더하는 HTML 속성. `aria-label`, `data-*`, 테스트 id 등에 씁니다. |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 루트 요소의 DOM 이벤트. `onPressed` 가 있는 링크에서는 `click` · `keydown` · `keyup` · `mousedown` · `mouseup` · `mouseenter` · `mouseleave` · `focusout` 에 건 핸들러가 불리지 않습니다. |

### 문장 안의 링크 — `inlineSpan`

`Link.inlineSpan` 은 Flutter 에서 `InlineSpan`, Web 에서 `Component` 를 돌려줍니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `context` | `BuildContext` | 필수 (위치 인자) | 테마에서 링크 스타일을 읽습니다. |
| `href` | `String` | 필수 | 이동할 주소. `text` 와 `children` 이 없으면 라벨이 됩니다. |
| `text` | `String?` | `null` | 라벨 |
| `children` | `List<InlineSpan>?` (Flutter) · `List<Component>?` (Web) | `null` | 안에 서로 다른 글자 모양이 있는 라벨 |
| `onPressed` | `VoidCallback?` (Flutter) · `CoreVoidCallback?` (Web) | `null` | 누를 때 부릅니다. |
| `external` | `bool` | `false` | Web 은 `target` 과 `rel` 을 붙입니다. Flutter 는 읽지 않습니다. |
| `variant` | `CoreLinkVariant` | `standard` | 색의 톤 |
| `linkStyle` | `CoreLinkStyle?` | `null` | 두 플랫폼 모두 `color` · `underlineColor` 와 `labelStyle` 에 직접 적은 값을 씁니다. Web 은 `transitionDuration` 과 `clickableStyle` 의 포커스 링도 씁니다. 아이콘 · 간격 · `interactionTextDecoration` 은 쓰지 않습니다. |
| `recognizers` | `List<GestureRecognizer>?` (Flutter 전용) | `null` | 만든 탭 인식기를 담는 목록. `onPressed` 를 줄 때 필요하고, 담긴 인식기는 호출자가 정리합니다. |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreLinkStyle patch)` | `linkStyle` 에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다. |
| `copyWith({href, linkStyle, key, ...})` | 바꾼 값으로 사본을 만듭니다. `null` 을 넘긴 필드는 기존 값이 남습니다. Web 의 `classes` 는 값을 바꾸지 않고 기존 값 뒤에 덧붙입니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.link` | `CoreLinkTheme?` | 앱 전체의 `Link` 설정 |
| `CoreLinkTheme.style` | `CoreLinkStyle?` | 모든 링크에 적용합니다. |
| `CoreLinkTheme.variantStyles` | `Map<CoreLinkVariant, CoreLinkStyle>?` | variant 별로 `style` 위에 덧붙입니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreLinkStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `color` | `CoreColor?` | Link text colour override. |
| `underlineColor` | `CoreColor?` | Underline stroke colour override. Unset, the underline follows the text colour — including a [color] override. |
| `interactionTextDecoration` | `CoreTextDecoration?` | Decoration shown while the link is hovered, pressed or focused — unlike the Button `link` variant's hover decoration, focus counts here, and it counts the same on both platforms. A link whose `underline` flag is set is always underlined and has nothing to reveal. |
| `transitionDuration` | `Duration?` | Colour-transition duration override for hover / focus feedback. |
| `labelStyle` | `CoreTextStyle?` | Link label text style override (applied to the link's text child). |
| `clickableStyle` | `CoreClickableStyle?` | Style for the link's `Clickable` — press scale, durations, focus ring, disabled opacity. Laid over [defaultClickableStyle] and passed to the `Clickable` as is; the `Clickable` fills in the remaining defaults. |
| `iconStyle` | `CoreIconStyle?` | Style for the `leading` / `trailing` icons — size and colour. Laid over [defaultIconStyle]; a colour stated here pins the icons, unset they follow the link's text colour. |
| `iconLabelGapStyle` | `CoreGapStyle?` | Space between the label and a `leading` / `trailing` icon. Laid over [defaultIconLabelGapStyle] and passed to the `Gap` as is. |

### `CoreLinkStyle` 변형별 기본값 (`CoreLinkStyle`)

| 필드 | `standard` | `muted` |
|------|------|------|
| `color` | link | onSurfaceVariant |
| `underlineColor` | link | onSurfaceVariant |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 설명과 다르게 동작하는 곳이 있습니다.

- `transitionDuration` — hover · 포커스 때는 글자색이 바뀌지 않고 밑줄만 바뀝니다. 이 시간은 테마나 `variant` 가 바뀌어 색이 달라질 때 보입니다. Flutter 의 위젯 `Link` 는 밑줄도 이 시간의 절반이 지날 때 바꾸고, Web 의 밑줄은 바로 바뀝니다. Flutter 의 `inlineSpan` 은 이 필드를 쓰지 않습니다.
- `clickableStyle` — Web 의 `inlineSpan` 과 `onPressed` 가 없는 `Link` 는 `Clickable` 을 만들지 않습니다. 포커스 링(`focusOutlineStyle`)과 모서리(`borderRadius`)를 읽고, 링의 색이 바뀌는 시간은 `duration` 을 따릅니다. 누름 효과(`pressedScale` · `pressedTranslate` · `pressedBoxShadow`)는 적용하지 않습니다. Web 은 어느 링크에서도 `focusOutlineStyle` 의 `borderRadius` · `ringOpacity` · `duration` 을 읽지 않습니다. Flutter 의 `inlineSpan` 은 `clickableStyle` 을 쓰지 않습니다. `Link` 에는 비활성 상태가 없어 `disabledOpacity` 는 어느 링크에서도 보이지 않습니다.
- `labelStyle` — Flutter 의 위젯 `Link` 는 `CoreTextStyle.token` 으로 준 글자 역할의 크기 · 행간 · 굵기 · 자간을 반영하지 않습니다. 직접 적은 값은 반영합니다. Web 의 위젯 `Link` 는 역할도 반영합니다. `inlineSpan` 은 두 플랫폼 모두 역할을 쓰지 않고 직접 적은 값만 씁니다. 다만 Flutter 의 `inlineSpan` 에서 `letterSpacing` · `lineHeightPx` 는 `fontSize` 를 함께 적어야 반영됩니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="link/related-button" title="Button">

일을 실행하거나 버튼 모양으로 이동할 때 씁니다. [Button 보기](/components/button)

</Card>
<Card demo="link/related-text" title="Text">

이동하지 않는 글자를 표시합니다. [Text 보기](/components/text)

</Card>
<Card demo="link/related-breadcrumb" title="Breadcrumb">

상위 화면까지의 경로를 보여 줍니다. [Breadcrumb 보기](/components/breadcrumb)

</Card>
</Cards>
