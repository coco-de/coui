---
title: Link
description: 내부 또는 외부 URL로 이동하는 링크 텍스트 컴포넌트. 문장 안에 놓이는 링크는 Underline=true를 쓴다(색만으로는 주변 글자와 구분되지 않는다). Underline=false는 단독으로 놓이는 링크(목록 · 푸터 · 카드 하단)에 쓰고, hover · pressed · focus 때 밑줄이 나타난다. muted는 보조 위치(푸터 등)의 링크다.
category: display
platforms: [flutter, web]
related: [button, text, breadcrumb]
tags: [link, navigation, text, anchor]
---

# Link

내부 라우팅 또는 외부 URL로 이동하는 링크 텍스트 컴포넌트입니다. 링크 전용 색(`color/link`)으로 링크임을 알리고, 밑줄은 hover · pressed · focus 때 나타납니다. 문장 안에서는 `Link.inlineSpan`이 늘 밑줄로 그립니다.

## Live Preview

<LivePreview component="link" variants="default,muted,underline,external,icons" />

## 사용 시기 (When to Use)

**이 컴포넌트를 사용하세요:**
- 본문 텍스트 중간에 인라인 링크가 필요할 때
- 외부 사이트로 이동하는 링크를 명시적으로 표시할 때
- 이용약관, 개인정보처리방침 같은 보조 링크가 필요할 때

**대신 다른 컴포넌트를 사용하세요:**
- **[Text](/components/text)**: URL 이동·활성화 없이 정적 텍스트만 표시할 때
- **[Button](/components/button)**: 인라인 링크 대신 버튼 모양이 필요한 액션·이동 CTA일 때
- **[Breadcrumb](/components/breadcrumb)**: 목적지 하나 대신 부모-자식 탐색 경로를 표시할 때

## 기본 사용법 (Basic Usage)

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
// 기본 링크 (링크 색, 밑줄은 hover · pressed · focus 때)
Link(
  href: '#',
  child: Text('자세히 보기'),
)

// 외부 URL 링크 (새 탭)
Link(
  href: 'https://example.com',
  external: true,
  child: Text('외부 링크'),
)

// 늘 밑줄인 링크
Link(
  href: '#',
  underline: true,
  child: Text('항상 밑줄 표시'),
)

// 보조 위치의 링크 (푸터, 캡션)
Link(
  href: '#',
  variant: CoreLinkVariant.muted,
  child: Text('이용약관'),
)

// 탭 콜백 사용
Link(
  href: 'https://coui.cocode.im',
  onPressed: handleOpenDocs,
  child: Text('CoUI 문서'),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
// 기본 링크 (링크 색, 밑줄은 hover · pressed · focus 때)
Link(
  href: '#',
  child: const Text('자세히 보기'),
)

// 외부 URL 링크 (새 탭)
Link(
  href: 'https://example.com',
  external: true,
  child: const Text('외부 링크'),
)

// 늘 밑줄인 링크
Link(
  href: '#',
  underline: true,
  child: const Text('항상 밑줄 표시'),
)

// 보조 위치의 링크 (푸터, 캡션)
Link(
  href: '#',
  variant: CoreLinkVariant.muted,
  child: const Text('이용약관'),
)

// 클릭 콜백 사용
Link(
  href: 'https://coui.cocode.im',
  onPressed: handleOpenDocs,
  child: const Text('CoUI 문서'),
)
```

  </TabItem>
</Tabs>

### 문장 안의 링크 (Inline Span)

문단 · 표 셀 · 헤딩처럼 **텍스트 흐름 안**에 링크를 넣을 때는 위젯 `Link` 대신
`Link.inlineSpan(...)` 을 씁니다. 위젯 `Link` 는 Flutter 에서 `WidgetSpan` 으로만
문장에 들어가 조각째로 움직여 줄바꿈되지 않고, 라벨을 `bodyMedium` 역할로 그려
주변 글자와 크기가 달라집니다. `Link.inlineSpan` 은 주변 문장과 함께 줄바꿈되고
크기 · 굵기 · 행간을 주변에서 상속하며, 색만 `CoreLinkStyle` 에서 가져옵니다.
문장 안에서는 색만으로 링크를 알아보기 어려우므로 **늘 밑줄**로 그립니다 — 끄는 플래그가
없습니다. Web 에서는 같은 `<a href>` 이므로 단독 `Link` 와 같은 포커스 링을 그립니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
// 탭 인식기는 이 State 가 소유하고 dispose 한다.
final _recognizers = <GestureRecognizer>[];

@override
void dispose() {
  for (final r in _recognizers) {
    r.dispose();
  }
  super.dispose();
}

@override
Widget build(BuildContext context) {
  for (final r in _recognizers) {
    r.dispose();
  }
  _recognizers.clear();

  return Text.rich(
    TextSpan(
      children: [
        const TextSpan(text: '토큰을 덮어쓰기 전에 '),
        Link.inlineSpan(
          context,
          href: '/docs/theming',
          text: '테마 가이드',
          onPressed: handleOpenTheming,
          recognizers: _recognizers,
        ),
        const TextSpan(text: '를 먼저 읽어 주세요.'),
      ],
    ),
  ).bodyMedium;
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
Component build(BuildContext context) {
  return Component.element(
    tag: 'p',
    children: [
      const Text('토큰을 덮어쓰기 전에 '),
      Link.inlineSpan(context, href: '/docs/theming', text: '테마 가이드'),
      const Text('를 먼저 읽어 주세요.'),
    ],
  );
}
```

  </TabItem>
</Tabs>

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `context` | `BuildContext` | 필수 (위치 인자) | 테마에서 `CoreLinkStyle` 을 해석할 컨텍스트 |
| `href` | `String` | 필수 | 이동할 URL. `text` · `children` 이 모두 없으면 이 문자열이 링크 텍스트가 됨 |
| `text` | `String?` | `null` | 링크 텍스트 |
| `children` | `List<InlineSpan>?` (Flutter) / `List<Component>?` (Web) | `null` | 링크 텍스트에 굵게 · 코드 같은 인라인 스타일이 있을 때. Flutter 는 안쪽 모든 텍스트 조각에 같은 탭 인식기를 붙임 |
| `onPressed` | `VoidCallback?` (Flutter) / `CoreVoidCallback?` (Web) | `null` | 탭/클릭 시 호출. Web 은 `href` 를 유지한 채 이동 대신 콜백을 실행 |
| `external` | `bool` | `false` | 외부 링크 여부. Web 에서 `target="_blank"` + `rel="noopener noreferrer"` |
| `variant` | `CoreLinkVariant` | `standard` | 링크의 색 톤. `muted` 는 보조 텍스트 색 |
| `linkStyle` | `CoreLinkStyle?` | `null` | 색 오버라이드. `labelStyle` 은 명시한 필드만 적용되고 타이포 역할은 주변을 따름 |
| `recognizers` | `List<GestureRecognizer>?` (Flutter 전용) | `null` | `onPressed` 가 있을 때 만든 `TapGestureRecognizer` 를 담을 목록. 호출자가 소유하고 dispose 함 |

## Props / Parameters

`W` 는 Flutter의 `Widget`, Web의 Jaspr `Component` 입니다. `W?` 는 선택 슬롯입니다.

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `href` | `String` | 필수 | 이동할 URL. `child`가 없으면 이 문자열이 링크 텍스트로 렌더링됨 |
| `onPressed` | `VoidCallback?` (Flutter) / `CoreVoidCallback?` (Web) | `null` | 활성화(탭/클릭/키보드 Enter) 시 호출되는 콜백 |
| `external` | `bool` | `false` | 외부 링크 여부. Web에서 `target="_blank"` + `rel="noopener noreferrer"` 의도 적용 |
| `underline` | `bool` | `false` | 밑줄을 늘 그릴지 여부. `false` 면 hover · pressed · focus 때만 `CoreLinkStyle.interactionTextDecoration`(기본 밑줄)이 나타남 |
| `variant` | `CoreLinkVariant` | `standard` | 링크의 색 톤 — `standard`(링크 색) · `muted`(보조 텍스트 색). 밑줄 여부와 별개의 축 |
| `child` | `W?` | `null` | 링크 내용. `null`이면 `href`가 일반 텍스트로 렌더링됨 |
| `leading` | `W?` | `null` | 라벨 앞의 내용 — 보통 링크가 무엇인지 알리는 아이콘. 링크의 글자 색과 `iconStyle` 크기(16)를 받고, 라벨과 `iconLabelGapStyle`(4) 만큼 떨어집니다. 밑줄은 라벨에만 그립니다 |
| `trailing` | `W?` | `null` | 라벨 뒤의 내용 — 보통 어디로 가는지 알리는 아이콘(사이트 밖으로 나가는 링크의 외부 링크 아이콘). `leading` 과 같은 모양 · 간격 |
| `linkStyle` | `CoreLinkStyle?` | `null` | 색상 / 밑줄 색상 / 상호작용 밑줄 / 전환 duration / 라벨 텍스트 스타일 오버라이드 |

### 빠른 오버라이드 (Chain)

이미 만든 `Link` 인스턴스에 스타일을 빠르게 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 style 슬롯 인자와 동일하게 동작하지만, 이미 구성된 위젯 위에서 바로 이어 쓸 수 있습니다.

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

<a id="스타일-커스터마이징-styling"></a>
## 스타일 시스템 (Style System)

겉모습은 전부 `linkStyle` 하나(`CoreLinkStyle`)로 바꿉니다. 변형별 기본 색은
`CoreLinkStyle.defaultsByVariant`에, 프로젝트 단위 덮어쓰기는 `CoreLinkTheme.style` ·
`CoreLinkTheme.variantStyles[variant]`에 있습니다.

밑줄의 **두께와 위치는 필드가 아닙니다** — 글꼴 자체의 값(`post` 표)을 쓰며, Web 은
`text-underline-position: from-font` + `text-decoration-thickness: from-font`, Flutter 는
`TextDecoration` 기본값입니다. 밑줄 색은 글자 색을 따라가고, `underlineColor` 를 지정했을 때만
따로 정해집니다.

```dart
Link(
  href: '#',
  linkStyle: const CoreLinkStyle(
    color: CoreColor.token(CoreColors.secondary),
    underlineColor: CoreColor.token(CoreColors.secondary),
  ),
  child: Text('보조 링크'),
)
```

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

## 변형 (Variants)

### Default
링크 전용 색(`color/link`)을 씁니다. 밑줄은 hover · pressed · focus 때 나타납니다. 단독으로 놓이는 링크의 기본 모양입니다.

```dart
Link(
  href: '#',
  child: Text('자세히 보기'),
)
```

### Muted
`variant: CoreLinkVariant.muted` 로 보조 텍스트 색을 씁니다. 푸터 · 캡션처럼 내용을 받치는 자리의 링크에 맞고, 링크 색이 내용과 다투지 않게 합니다.

```dart
Link(
  href: '#',
  variant: CoreLinkVariant.muted,
  child: Text('이용약관'),
)
```

### Underline
`underline: true` 로 밑줄을 늘 그립니다. 색만으로 링크를 알아보기 어려운 자리에 씁니다. 문장 안은 `Link.inlineSpan` 이 이 모양입니다.

```dart
Link(
  href: '#',
  underline: true,
  child: Text('항상 밑줄 표시'),
)
```

### External
`external: true`로 Web native anchor 경로에서 새 탭을 사용합니다. Flutter·콜백 경로는 호출부가 이동을 처리합니다.

```dart
Link(
  href: 'https://example.com',
  external: true,
  child: Text('외부 링크'),
)
```

### 아이콘 (Leading · Trailing)
`leading` · `trailing` 에 아이콘을 넣으면 라벨과 한 줄로 세로 가운데에 놓입니다. 아이콘은 링크의 글자 색을 따르므로 `variant` 나 `color` 를 바꿔도 함께 바뀝니다. 아이콘만 다른 색이 필요하면 `linkStyle.iconStyle.color` 를 지정합니다. `external: true` 만으로는 아이콘이 생기지 않습니다 — 필요한 쪽이 직접 넣습니다.

```dart
Link(
  href: 'https://github.com/coco-de/coui',
  external: true,
  trailing: Icon(LucideIcons.externalLink),
  child: Text('GitHub에서 보기'),
)
```

## 동작 스펙 (Behavior)

### 인터랙션

- **클릭/탭**: onPressed가 있으면 콜백을 실행합니다. Flutter는 URL을 자체 이동하지 않으므로 호출부가 라우팅·외부 열기를 제공합니다
- **호버 · 눌림 · 포커스**: 커서가 포인터로 바뀌고, `underline: false` 인 링크는 밑줄을 보입니다(`CoreLinkStyle.interactionTextDecoration`). 세 상태 모두 두 플랫폼에서 같습니다
- **Web 포커스 링**: `<a href>` 경로도 `Clickable` 이 그리는 것과 같은 CoUI 포커스 링(2px · 간격 2)을 그립니다. 브라우저 기본 표시는 쓰지 않습니다
- **Web 네이티브 이동**: onPressed가 없으면 `<a href>` 를 렌더하고 external이면 새 탭을 사용합니다. 콜백 경로는 Clickable + data-href여서 href 자동 이동은 하지 않습니다
- 버튼 모양을 가진 이동 CTA이면 **[Button](/components/button)** 의 href 경로, 문장·보조 텍스트의 링크이면 Link입니다. Link에 콜백을 추가하면 Web의 native anchor 경로가 바뀌므로 분석용 콜백이 native 이동과 함께 필요할 때도 Button(href:, onPressed:) 계약을 확인하세요.

### 애니메이션

- 색상 전환: 150ms ease-in-out (`CoreLinkStyle.transitionDuration`). 밑줄은 나타나고 사라질 때 보간되지 않고 바뀝니다

## 사용 가이드라인 (Usage Guidelines)

### ✅ Do

<Callout type="tip">

**외부 URL 에는 `external: true` 명시**

```dart
Link(
  href: 'https://example.com',
  external: true,
  child: Text('외부 링크'),
)
```

이유: `external: true` 는 Web 에서 `target="_blank"` + `rel="noopener noreferrer"` 를 실제로 적용하고, Flutter 에서도 `onPressed` 핸들러가 외부 이동 의도를 판단할 수 있는 신호가 됩니다. 생략하면 두 플랫폼 모두 새 탭/보안 처리를 임의로 판단해야 합니다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**탐색이 아닌 액션 트리거에 사용 금지**

```dart
// ❌ 페이지 이동이 아니라 폼 제출 액션인데 Link 사용
Link(href: '#', onPressed: submitForm, child: Text('제출'))
```

이유: `Link` 는 Web `role="link"` / Flutter `Semantics(link: true)` 로 노출되어 스크린 리더가 "다른 곳으로 이동한다"고 안내합니다. 실제로는 폼을 제출하는 액션이라면 시맨틱과 실제 동작이 어긋나므로 `Button` 을 사용해야 합니다.

</Callout>

## 접근성 (Accessibility)

### 역할

- **Flutter**: 링크 텍스트를 `Semantics(button: true, link: true)` 로 감쌉니다 (`link.dart:101-103`). 그 바깥의 `Clickable` 이 다시 `Semantics(enabled: …, button: true)` 를 얹으므로 (`clickable.dart:509-513`), 이 컴포넌트는 링크이면서 동시에 버튼으로 표시됩니다.
- **Web**: `Clickable` 루트에 `role="link"` 를 실어 `Clickable` 의 기본 `role="button"` 을 덮습니다 (`link.dart:127`, `clickable.dart:436`·`:441` — 호출자·합성자 attributes 가 나중에 병합되어 이깁니다). 활성 상태이므로 `tabindex="0"` 이 함께 붙습니다 (`clickable.dart:437`). `href` 는 `data-href`, `external` 은 `data-external="true"` 라는 data 속성으로만 나가며 (`link.dart:128-129`) 접근성 트리에는 노출되지 않습니다.

### 키보드

| 키 | Flutter | Web |
|----|---------|-----|
| `Tab` | 링크로 포커스 — `Clickable` 의 `FocusableActionDetector` (`clickable.dart:484-487`) | 링크로 포커스 — `tabindex="0"` (`clickable.dart:437`) |
| `Enter` | `onPressed` 호출 — `SingleActivator(.enter) → ActivateIntent` (`clickable.dart:14-17`) | `onPressed` 호출 — `keydown` 의 `'Enter'` 분기 (`clickable.dart:374-378`) |
| `Space` | `onPressed` 호출 — `SingleActivator(.space)` (`clickable.dart:14-17`) | `onPressed` 호출 — `keydown` 의 `' '` / `'Spacebar'` 분기 (`clickable.dart:374-378`) |

`Space` 로도 활성화되는 것은 `Clickable` 이 두 키를 함께 소유하기 때문이며, 네이티브 `<a>`(Enter 전용)와 다릅니다. 링크에 포커스가 있는 동안 `Space` 는 페이지 스크롤 대신 링크를 실행합니다.

`Link.inlineSpan` 은 Flutter 에서 `Tab` 으로 도달하지 않습니다 — `TextSpan` 은
포커스 노드가 아니기 때문입니다. 키보드로 반드시 닿아야 하는 링크는 위젯 `Link` 를
쓰세요.

### 스크린 리더

접근 가능한 이름은 `child` 의 내용이고, `child` 를 생략하면 `href` 문자열이 그대로 이름이 됩니다 (Flutter `link.dart:104` `child ?? Text(href)`, Web `link.dart:111-113`).

같은 링크가 플랫폼마다 다르게 안내됩니다 — Flutter 는 `link` 와 `button` 플래그를 함께 세워 두 역할이 겹쳐 읽히고, Web 은 `role="link"` 하나만 노출합니다.

live region 은 없습니다. 그리고 `external: true` 는 어느 플랫폼에서도 통보되지 않습니다 — Web 은 `data-external` 이라는 data 속성일 뿐이고 (`link.dart:129`), Flutter 의 `build` 는 `external` 을 읽지 않습니다 (`link.dart:74-109`).

### 포커스 관리

오버레이가 아니므로 **진입·이탈 시 포커스 이동이 없고 트랩도 없습니다**. 포커스 표시는 `Clickable.focusOutline` 기본값이 `true` 라 양 플랫폼 모두 그려집니다 — Flutter 는 `FocusOutline` 위젯, Web 은 `focus-visible:` 의사 클래스 규칙입니다. Web 의 `<a href>` 경로(콜백 없음)와 `Link.inlineSpan` 은 `Clickable` 을 거치지 않으므로 같은 링을 앵커 자신이 그립니다 — 브라우저 기본 표시 대신 CoUI 링입니다. 포커스를 받으면 `underline: false` 링크도 밑줄을 보입니다.

### 알려진 제약

- **`external: true` 가 새 탭도, 보안 속성도, 통보도 만들지 않습니다** — Web 이 내보내는 것은 `data-external="true"` 뿐이고 `target` / `rel` 은 어디에도 없습니다 (`link.dart:123-142`, 파일 전체 `target`·`noopener` 0건). "새 창에서 열림" 이 보조 기술에 전달되지 않고 실제 새 탭도 열리지 않습니다. 대안: 새 창 이동은 `onPressed` 에서 직접 구현하고, `attributes` 진입점이 열려 있으므로 (`link.dart:126` — 호출자 attributes 가 먼저 펼쳐지고 `role`/`data-*` 만 덮어씁니다) `attributes: {'aria-label': '문서 (새 창에서 열림)'}` 로 이름에 명시합니다.
- **`onPressed` 가 있으면 네이티브 `<a href>` 가 아닙니다** — Web 은 콜백이 있는 링크를 `<div role="link">` 로 렌더하고 `href` 는 `data-href` 로만 나가므로, 가운데 클릭 · 컨텍스트 메뉴의 "새 탭에서 열기" · 상태 표시줄 URL 미리보기 같은 브라우저 링크 어포던스가 없습니다. 이동만 하는 링크는 콜백을 주지 않으면 실제 `<a href>` 입니다. 대안: 이동 링크에는 `onPressed` 를 주지 않습니다.
- **밑줄이 늘 있지는 않습니다** — 기본값(`underline: false`)의 단독 링크는 hover · pressed · focus 때에만 밑줄을 보이므로 평소에는 색으로 구분됩니다. 그래서 **문장 안의 링크에는 쓰지 마세요** — 주변 글자와 색으로만 갈리면 색각 이상 사용자와 OS 색 강제 모드에서 링크임을 알 수 없습니다(WCAG 1.4.1). 문장 안은 `Link.inlineSpan` 을 쓰면 늘 밑줄이고, 그 밖의 자리에서 늘 밑줄이 필요하면 `underline: true` 입니다.
- **`onPressed` 가 `null` 이어도 포커스를 받습니다** — `Link` 는 `Clickable.enabled` 를 넘기지 않아 항상 기본값 `true` 로 합성됩니다 (Flutter `clickable.dart:76`, Web `clickable.dart:91`). 그래서 아무 일도 하지 않는 링크에도 `tabindex="0"` 이 붙고 Tab 이 멈춥니다. 대안: 핸들러가 없는 `Link` 를 렌더하지 않고 `Text` 를 씁니다.

이 컴포넌트가 직접 다루지 않는 대비·모션 등 전역 축은 [전역 접근성 축](/accessibility) 에서 한 곳으로 관리됩니다.

## 크로스 플랫폼 차이점 (Platform Differences)

| 항목 | Flutter | Web |
|------|---------|-----|
| 클래스명 | `Link` | `Link` |
| 렌더 요소 | Clickable + link 시맨틱·텍스트 | 콜백 없음: `<a href>`, 있음: Clickable의 `<div role="link">` |
| 외부 링크 | 호스트가 onPressed에서 처리 | native anchor 경로에서만 target=_blank |
| 문장 안 링크 | `Link.inlineSpan` → `TextSpan` + `TapGestureRecognizer` | `Link.inlineSpan` → 인라인 `<a href>` |
| 문장 안 링크의 포커스 | 포커스 링 · 키보드 활성화 없음 (`TextSpan` 은 포커스 노드가 아님) | CoUI 포커스 링 · `Enter` (`<a href>` 가 포커스를 받음) |
| 상호작용 밑줄 상태 감지 | `Clickable` 의 hover · focus · pressed 콜백 → 다시 그림 | CSS `hover:` · `focus-visible:` · `active:` (콜백 경로는 `group-*`) |
| 밑줄 두께 · 위치 | 글꼴 기본값 (`TextDecoration`) | `from-font` (글꼴 기본값) |

## 관련 컴포넌트 (Related Components)

- **[Button](/components/button)**: 탐색이 아닌 액션 실행에 사용
- **[Text](/components/text)**: 링크가 없는 일반 텍스트에 사용
- **[Breadcrumb](/components/breadcrumb)**: 계층적 페이지 탐색 경로 표시에 사용
