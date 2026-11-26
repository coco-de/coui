---
title: Scrollbar
description: 스크롤 영역에 테마된 스크롤바를 입히는 래퍼
category: control
platforms: [flutter, web]
related: [scroll-area, resizable]
tags: [scroll, scrollbar, overflow]
template: v2
source: infra/scrollbar
---

# Scrollbar

<a id="live-preview"></a>

## 플레이그라운드

`visibility` · `axis` · `interactive`를 바꾸고 상자를 스크롤해 보세요. 처음 값은 thumb이 늘 보이는 `always`입니다. `auto`를 고르면 가만히 있을 때는 thumb이 숨고, 스크롤하거나 바에 포인터를 가져가면 나타납니다.

<Playground component="scrollbar" />

`Scrollbar`는 스크롤 영역에 디자인 시스템의 스크롤바를 입힙니다. 스크롤바는 내용 위에 겹쳐 그려지므로 내용의 폭을 줄이지 않습니다. 감싸는 방식은 플랫폼마다 다릅니다. Flutter에서는 스크롤 뷰를 감싸고, Web에서는 `Scrollbar` 자신이 스크롤 상자가 됩니다. 그래서 만들어지는 코드가 두 플랫폼에서 다릅니다.

<Note>

Flutter 코드의 `controller`는 State에서 만들고 `dispose`하는 `ScrollController`입니다. Flutter의 `always`는 컨트롤러를 넘기지 않으면 첫 프레임에 debug 오류를 냅니다. 가로 예제는 바가 글자를 덮지 않도록 내용 아래에 여백 12를 둡니다.

</Note>

<a id="레이아웃"></a>

## 구조

<Anatomy demo="scrollbar/anatomy">
<AnatomyItem part="container" name="스크롤 영역">

내용이 넘치면 스크롤되는 상자입니다. Flutter에서는 감싼 스크롤 뷰이고, Web에서는 `Scrollbar`가 그리는 `<div>`입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=track]" side="top" name="바 영역">

가장자리를 따라 놓인 띠입니다. 기본 폭은 10이고 눌러서 한 화면 가까이 넘길 수 있습니다. 기본 `trackColor`는 투명합니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=thumb]" side="right" name="thumb">

지금 보는 위치와 비율을 보여 주는 알약 모양 손잡이입니다. 두께 6, 가장자리에서 2 떨어져 있습니다.

</AnatomyItem>
</Anatomy>

<Note>

이 페이지의 웹 정지 화면은 그림입니다. Web의 thumb은 브라우저에서 스크롤 상자를 잰 뒤에 그려지는데, 플레이그라운드를 뺀 미리보기는 브라우저에서 실행되지 않기 때문입니다. 그림은 `CoreScrollbarStyle`의 기본값과 같은 위치 계산을 씁니다. 색과 모서리는 밝기 모드와 테마의 CSS 변수를 따르지만, 앱 전체 설정(`CoreScrollbarTheme`)은 그림에 반영되지 않습니다.

</Note>

바 폭은 `thickness`에 `thumbInset`의 두 배를 더한 값입니다. 기본값은 10(6 + 2 × 2)이고 `thin`은 7입니다. 이 폭은 내용 옆에 따로 비워 두는 자리가 아니라 내용 위에 겹치는 영역입니다. 그래서 스크롤바가 있든 없든 내용의 폭은 같습니다. Web의 색 강제 모드만 예외로, 브라우저 스크롤바를 씁니다([알려진 제약](#알려진-제약)).

thumb의 길이는 전체 내용 가운데 보이는 비율만큼입니다. 양 끝에 `thumbInset`만큼 여백을 둡니다. 내용이 아무리 길어도 48(`minThumbLength`)보다 짧아지지 않으며, 보이는 영역이 그보다 작으면 여백을 뺀 길이를 다 씁니다. 길이와 위치를 계산하는 방법은 두 플랫폼이 같습니다.

`thumbInset`의 여백은 thumb을 둥근 모서리에서 떼어 놓지만, 큰 모서리까지 모두 피하지는 못합니다. 모서리가 둥근 컨테이너의 가장자리에 스크롤 영역을 딱 붙이면 thumb 끝이 모서리 곡선 밖으로 나갈 수 있습니다. 반경이 약 10보다 크면 그렇습니다. 스크롤 영역을 컨테이너 가장자리에서 3 이상 안쪽에 두면 반경 16까지는 걸리지 않습니다.

<a id="사용법"></a>

## 스크롤 영역과 연결

<Split>

<Code language="dart" title="Flutter — 스크롤 뷰를 감쌉니다">
SizedBox(
  height: 240,
  child: Scrollbar(
    child: ListView(
      children: [
        ...List.generate(
          40,
          (index) => Text('항목 ${index + 1}').bodyMedium,
        ),
      ],
    ),
  ),
)
</Code>

<Code language="dart" title="Web — Scrollbar가 스크롤 상자입니다">
Scrollbar(
  axis: CoreScrollbarAxis.vertical,
  css: Styles(
    raw: {'max-height': '240px'},
  ),
  child: div(
    classes: 'flex flex-col',
    [
      ...List.generate(
        40,
        (index) => Text('항목 ${index + 1}').bodyMedium,
      ),
    ],
  ),
)
</Code>

</Split>

### Flutter는 스크롤 뷰를 감쌉니다

- `Scrollbar`는 스크롤을 만들지 않습니다. 스크롤 뷰가 아닌 위젯만 감싸면 바도 스크롤도 생기지 않습니다.
- 바로 안쪽의 스크롤 뷰를 따라갑니다. 그 스크롤 뷰 안에 다시 넣은 스크롤 뷰는 따라가지 않습니다.
- `controller`는 선택입니다. 넘기지 않아도 thumb 끌기와 위치 안내가 동작합니다.
- 감싼 영역 안에서는 Flutter가 스크롤 뷰에 자동으로 붙이는 스크롤바를 끕니다. 안에 다시 넣은 스크롤 뷰도 마찬가지이므로, 그 뷰에도 바가 필요하면 `Scrollbar`를 하나 더 씁니다.
- `CoUIApp`의 기본 스크롤 설정은 데스크톱(macOS · Windows · Linux)의 세로 스크롤 뷰에 이 `Scrollbar`를 이미 붙입니다. 가로 스크롤 뷰와 모바일(Android · iOS · Fuchsia)에는 붙이지 않으니, 그곳에 바가 필요하면 직접 감쌉니다. `scrollBehavior`를 바꾼 앱에는 해당하지 않을 수 있습니다.

### Web은 `Scrollbar`가 스크롤 상자입니다

- `Scrollbar`가 그리는 `<div>`가 스크롤합니다. `child`에는 스크롤할 내용만 둡니다. 안쪽에 스크롤 상자를 따로 만들면 그 상자의 스크롤은 따라가지 않습니다.
- 스크롤 상자는 `vertical`이면 부모의 높이를(`h-full`), `horizontal`이면 부모의 폭을(`w-full`), `both`면 둘 다를 채웁니다. 세로 스크롤은 부모의 높이가 정해져 있지 않으면 상자가 내용만큼 늘어나 생기지 않습니다. 부모에 높이를 주거나 `css`로 `max-height`를 정합니다.
- 내용의 배치(flex · grid · 간격)는 `child`에서 정합니다. 바깥 상자에는 thumb을 담는 요소도 자식으로 있어서, `classes`로 바깥 상자를 flex로 만들고 간격을 주면 내용 앞에 빈틈이 생길 수 있습니다.

## 축

`axis`(`CoreScrollbarAxis`)의 기본값은 `both`이고, 플랫폼마다 뜻이 다릅니다. Web에서는 스크롤할 수 있는 방향을 정하고, Flutter에서는 따라갈 스크롤 뷰를 고릅니다.

| `axis` | Web | Flutter |
| --- | --- | --- |
| `both` | 두 방향으로 스크롤하고, 넘치는 방향마다 thumb을 그립니다 | 방향과 상관없이 바로 안쪽 스크롤 뷰를 따라갑니다. thumb은 한 번에 한 방향만 그립니다 |
| `vertical` | 세로로만 스크롤합니다. 가로로 넘치는 내용은 잘립니다 | 세로 스크롤 뷰만 따라갑니다 |
| `horizontal` | 가로로만 스크롤합니다. 세로로 넘치는 내용은 잘립니다 | 가로 스크롤 뷰만 따라갑니다 |

Flutter에서 `axis`는 스크롤을 막지 않습니다. 세로 스크롤 뷰 안에 가로 스크롤 뷰를 넣으면, 바깥 `Scrollbar`는 `axis: horizontal`이어도 안쪽 가로 뷰를 따라가지 않습니다. 두 방향의 바가 모두 필요하면 스크롤 뷰마다 `Scrollbar`를 하나씩 두거나, 두 방향으로 움직이는 내용에는 [ScrollableClient](/components/scrollable-client)를 검토합니다.

<a id="동작-스펙-behavior"></a>
<a id="모양"></a>

## 상태

### 표시 정책

`visibility`(`CoreScrollbarVisibility`)는 thumb을 언제 얼마나 두껍게 보일지 정합니다. 어떤 값을 골라도 스크롤은 됩니다.

| `visibility` | thumb이 보이는 때 | 두께 |
| --- | --- | --- |
| `auto`(기본) | 스크롤할 때 나타나고, 마지막 스크롤 뒤 600ms가 지나면 사라집니다. 바에 포인터를 가져가거나 thumb을 잡아도 보입니다 | 6 |
| `always` | 늘 보입니다 | 6 |
| `thin` | `auto`와 같습니다 | 3(올리거나 끌면 4) |
| `hidden` | 그리지 않습니다. 스크롤과 위치 안내는 그대로입니다 | — |

`auto`와 `thin`은 300ms에 걸쳐 나타나고 사라지며, 이 시간과 600ms 대기는 두 플랫폼이 같습니다. thumb을 잡고 있는 동안에는 사라지지 않습니다. `interactive: true`면 포인터를 바에 올려 둔 동안에도 남습니다. 다만 Flutter에서는 그동안 휠 같은 방법으로 스크롤하고 포인터를 움직이지 않으면, 포인터가 바 위에 있어도 사라집니다. thumb을 끌었다 놓고 움직이지 않을 때도 사라질 수 있습니다. 내용이 넘치지 않으면 어떤 값이든 thumb을 그리지 않습니다.

<Preview demo="scrollbar/visibility" />

### 올림과 끌기

포인터를 thumb이나 바 영역에 올리거나 thumb을 끄는 동안에는 색이 `on-surface` 50%에서 70%로 진해지고, 두께가 6에서 8로 굵어집니다. 두 플랫폼 모두 200ms 동안 바뀝니다. 바 폭은 그대로라서 굵어진 만큼 가장자리 여백이 2에서 1로 줄고, 옆의 내용은 밀리지 않습니다.

<Preview demo="scrollbar/states" />

### 바 누르기

- thumb을 끌면 끈 거리에 비례해 내용이 움직입니다.
- 바 영역에서 thumb이 아닌 곳을 누르면, 누른 쪽으로 보이는 영역의 80%만큼 100ms에 걸쳐 넘어갑니다. Web은 터치로는 넘어가지 않고, 터치가 주 입력인 기기(`pointer: coarse`)에서는 마우스 · 펜으로도 넘어가지 않습니다. Flutter는 바가 보이는 동안에는 터치로 눌러도 넘어갈 수 있습니다.
- 터치로 thumb을 잡는 영역은 다릅니다. Flutter는 thumb 둘레를 48 × 48 이상으로 넓혀 받고, Web은 바 폭(10)만큼만 받습니다.

`interactive: false`면 thumb을 끌 수도, 바를 눌러 넘길 수도 없습니다. 두 플랫폼 모두 바가 포인터를 받지 않으므로 그 자리를 누르면 아래 내용이 눌립니다. 올렸을 때의 모양도 생기지 않아, `auto` · `thin`은 스크롤할 때만 보입니다. 스크롤 자체는 막지 않습니다.

<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

Flutter의 스크롤 뷰에 CoUI 스크롤바를 붙이거나, 바를 언제 보일지와 조작할 수 있는지를 직접 정할 때 씁니다. Web에서는 내용을 스크롤 상자로 만들면서 같은 바를 입힐 때 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 높이를 정해 스크롤 영역까지 한 번에 만들 때 | [ScrollArea](/components/scroll-area) |
| 두 방향 스크롤 위치로 내용을 직접 그릴 때 | [ScrollableClient](/components/scrollable-client) |
| 넘치는 가장자리를 흐리게 해 더 있음을 알릴 때 | [FadeScroll](/components/fade-scroll) |

<a id="do"></a>

### 컨트롤러는 스크롤 뷰와 같은 것

Flutter에서 `controller`를 넘긴다면 스크롤 뷰가 쓰는 것과 같은 컨트롤러를 넘깁니다. 어느 스크롤 뷰에도 붙지 않은 컨트롤러를 넘기면 thumb 끌기와 바 누르기가 되지 않습니다. `interactive: true`이거나 `visibility: always`이면 바가 나타날 때 debug 빌드에서 오류도 납니다. 다른 스크롤 뷰의 컨트롤러를 넘기면 thumb을 끌 때 그 뷰가 움직일 수 있습니다.

<Split>

<Code language="dart" title="이렇게 하세요">
Scrollbar(
  controller: controller,
  child: ListView(
    controller: controller,
    children: items,
  ),
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// otherController가 어느 스크롤 뷰에도
// 붙지 않으면 thumb을 끌 수 없고,
// debug 빌드에서 오류가 납니다.
Scrollbar(
  controller: otherController,
  child: ListView(children: items),
)
</Code>

</Split>

<a id="dont"></a>

### 스크롤을 막는 속성이 아닙니다

`interactive`는 바를 조작하는 것만 막습니다. 휠 · 터치 · 키보드 스크롤은 스크롤 영역이 그대로 처리합니다.

<Code language="dart" title="바만 조작할 수 없게 — 내용은 계속 스크롤됩니다">
Scrollbar(
  interactive: false,
  child: content,
)
</Code>

## 테마와 스타일

thumb의 색 · 두께 · 모서리 · 가장자리 여백 · 최소 길이와 바 영역의 색은 `scrollbarStyle`(`CoreScrollbarStyle`) 하나로 바꿉니다. `axis` · `visibility` · `interactive`는 위젯 파라미터라 스타일이나 테마로 바꿀 수 없습니다. 아래 코드의 `content`는 Flutter에서는 스크롤 뷰, Web에서는 스크롤할 내용입니다.

<Split>

<Code language="dart" title="하나만 바꾸기">
Scrollbar(
  scrollbarStyle: CoreScrollbarStyle(
    thumbColor: CoreColor.token(
      CoreColors.primary,
    ),
    hoverThumbColor: CoreColor.token(
      CoreColors.primary,
    ),
  ),
  child: content,
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    scrollbar: CoreScrollbarTheme(
      style: CoreScrollbarStyle(
        thickness: CoreSize.size8,
        hoverThickness: CoreSize.size10,
      ),
    ),
  ),
)
</Code>

</Split>

함께 정해야 하는 값이 있습니다.

- `thumbColor`만 바꾸면 올리거나 끌 때의 색은 기본값(`on-surface` 70%)으로 바뀝니다. 같은 계열로 두려면 `hoverThumbColor`도 정합니다.
- `hoverThickness`의 기본값 8은 `thickness`를 따라 커지지 않습니다. `thickness`를 8보다 크게 하고 `hoverThickness`를 비우면 올렸을 때 thumb이 오히려 얇아집니다.
- 올렸을 때의 두께는 바 폭(`thickness` + `thumbInset` × 2)을 넘지 않습니다.

### 빠른 오버라이드 (Chain)

이미 만든 `Scrollbar` 인스턴스에 스타일을 빠르게 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `scrollbarStyle`에 주는 것과 같고, 여러 번 이으면 겹치는 값은 뒤의 것이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ScrollbarChainExample extends StatefulWidget {
  const ScrollbarChainExample({super.key});

  @override
  State<ScrollbarChainExample> createState() => _ScrollbarChainExampleState();
}

class _ScrollbarChainExampleState extends State<ScrollbarChainExample> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 160,
      child:
          Scrollbar(
            controller: _controller,
            child: SingleChildScrollView(
              controller: _controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Theme.of(context).geometry.space(CoreSpace.space8),
                children: [
                  for (var i = 1; i <= 20; i += 1) Text('스크롤 항목 $i').bodyMedium,
                ],
              ),
            ),
          ).withStyle(
            const CoreScrollbarStyle(
              thumbColor: CoreColor.token(CoreColors.primary),
              thumbRadius: CoreBorderRadius.all(CoreRadius.radius9999),
              thickness: CoreStrokeWidth.stroke8,
              trackColor: CoreColor.token(CoreColors.surfaceContainerHigh),
            ),
          ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class ScrollbarChainExample extends StatelessComponent {
  const ScrollbarChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '240px', 'height': '160px'}),
      [
        Scrollbar(
          child: div(
            classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
            [
              for (var i = 1; i <= 20; i += 1) Text('스크롤 항목 $i').bodyMedium,
            ],
          ),
        ).withStyle(
          const CoreScrollbarStyle(
            thumbColor: CoreColor.token(CoreColors.primary),
            thumbRadius: CoreBorderRadius.all(CoreRadius.radius9999),
            thickness: CoreStrokeWidth.stroke8,
            trackColor: CoreColor.token(CoreColors.surfaceContainerHigh),
          ),
        ),
      ],
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<Note>

이 예제는 `hoverThumbColor`를 정하지 않아, 올리거나 끌면 thumb이 `primary`가 아니라 `on-surface` 70%가 됩니다. `thickness`가 hover 기본값과 같은 8이라 두께는 바뀌지 않습니다.

</Note>

<a id="resolve-chain"></a>

### 값이 정해지는 순서

뒤로 갈수록 우선하고, 필드마다 따로 합쳐집니다.

```text
CoreScrollbarStyle 기본값
  → CoreScrollbarTheme.style      // 앱 전체 (CoreComponentTheme.scrollbar)
  → scrollbarStyle                // 하나만
```

합친 값에 `thin`은 두 두께(`thickness` · `hoverThickness`)를 절반으로 줄여 적용합니다. Flutter는 두께 · 여백 · 최소 길이에 테마의 크기 배율도 곱합니다.

[ScrollArea](/components/scroll-area)는 thumb 색 기본값을 `on-surface` 25%로 낮춰 `scrollbarStyle`로 넘깁니다. 그래서 `CoreScrollbarTheme`에 적은 `thumbColor`는 ScrollArea의 바에 적용되지 않습니다. ScrollArea의 바 색은 `scrollAreaStyle`의 `scrollbarStyle`이나 `CoreScrollAreaTheme`에서 바꿉니다.

<a id="접근성-accessibility"></a>

## 접근성

### 역할

그려지는 thumb과 따로, 화면에 보이지 않는 노드가 스크롤 위치를 알립니다. 스크롤 영역 자체의 역할은 바꾸지 않으므로 안쪽 내용의 의미는 그대로입니다.

| 플랫폼 | 내보내는 것 |
| --- | --- |
| Jaspr Web | `axis`에 든 축마다 하나씩 시각적으로 숨긴 `<div role="scrollbar">`를 둡니다(`axis: both`면 두 개). `aria-orientation` · `aria-valuenow` · `aria-valuemin="0"` · `aria-valuemax="100"` · `aria-controls`(스크롤 상자)를 붙이고, 이름(`aria-label`)은 붙이지 않습니다. 그려진 thumb과 바 영역은 `aria-hidden`입니다 |
| Flutter | Flutter에는 scrollbar 역할이 없어 `slider`로 표시한 `Semantics` 노드 하나를 두고, 값을 `'40%'`처럼 알립니다. 내용을 가리지 않도록 왼쪽 위 1 × 1 크기입니다 |

### 키보드

스크롤바가 처리하는 키는 없습니다. thumb과 위치를 알리는 노드는 Tab으로 멈추는 자리로 만들지 않았습니다(Flutter에는 `FocusNode`가 없고, Web에는 `tabindex`가 없습니다). 키보드 스크롤은 감싼 스크롤 영역과 브라우저 · Flutter의 기본 동작이 맡습니다. 다만 Flutter 앱을 웹으로 빌드해 접근성 트리를 켜면, 늘리기 · 줄이기 동작이 있는 위치 노드는 `<input type="range">`가 되어 브라우저 포커스를 받을 수 있습니다.

Web의 스크롤 상자에는 `tabindex`가 없습니다. 안에 포커스를 받는 요소가 없는 스크롤 상자에 브라우저가 키보드 포커스를 주는지는 브라우저마다 다를 수 있습니다. 키보드로 확실히 스크롤하게 하려면 `attributes`로 직접 정합니다.

```dart
Scrollbar(
  axis: CoreScrollbarAxis.vertical,
  attributes: {
    'tabindex': '0',
    'role': 'region',
    'aria-label': '공지 목록',
  },
  child: notices,
)
```

[ScrollArea](/components/scroll-area)도 Web에서는 이 `Scrollbar`가 스크롤 상자라 `tabindex`가 없고, 같은 `attributes`로 정합니다.

Web의 `onKeyDown` · `onKeyUp`은 받은 처리기를 바깥 상자에 붙입니다. 상자가 포커스를 받지 않으면 안쪽 요소에서 올라온 키 이벤트만 받습니다.

### 스크린 리더

스크롤 위치를 0에서 100까지의 퍼센트로 알리고, 스크롤하면 값이 바뀝니다. 바뀌는 것을 따로 읽어 주는 라이브 영역은 없습니다. 위치 안내는 `visibility: hidden`에서도, `interactive: false`에서도 남습니다.

| 조건 | Flutter | Jaspr Web |
| --- | --- | --- |
| 위치를 바꾸는 동작 | `interactive: true`이고 내용이 넘치면 늘리기 · 줄이기 동작을 알립니다. 한 번에 스크롤 범위의 10%씩 움직이고, 끝에서는 그 방향의 동작이 없습니다 | 없습니다. 키보드 스크롤은 [키보드](#키보드)를 보세요 |
| `interactive: false` | 늘리기 · 줄이기 동작이 없습니다 | 노드에 `aria-disabled="true"`를 붙입니다. 이 노드는 원래 동작이 없어 상태만 알립니다 |
| 내용이 넘치지 않을 때 | 0%이고 동작이 없습니다 | 넘치지 않는 축의 노드도 0%로 남습니다 |
| 아직 알 수 없을 때 | 따라갈 스크롤 뷰가 없으면 값 없는 빈 노드입니다 | 브라우저에서 스크롤 상자를 재기 전에는 0%입니다 |

### 포커스 관리

스크롤바는 포커스를 받지 않고, 포커스를 옮기거나 가두지 않습니다. 위치를 알리는 노드는 보이지 않아 포커스 링을 그릴 자리가 없으므로, 일부러 Tab 정지점으로 두지 않았습니다. 보이지 않는 정지점은 포커스가 사라진 것처럼 보이기 때문입니다(WCAG 2.4.7). 내용 안의 포커스를 받는 요소는 그대로 동작합니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | thumb은 브라우저에서 실행되는 `Scrollbar`만 그립니다. 서버에서만 렌더하고 브라우저에서 깨우지 않으면(`@client` 밖), 브라우저 스크롤바도 숨긴 상태라 아무 바도 보이지 않습니다. 스크롤은 됩니다 |
| Jaspr Web | 색 강제 모드(`forced-colors: active`)에서는 직접 그린 thumb이 배경색으로 바뀌어 보이지 않으므로, 대신 시스템 색으로 보이는 브라우저 스크롤바를 그대로 둡니다. 그 바는 `scrollbarStyle` · `thin` · `interactive`를 따르지 않고, 운영체제에 따라 내용 옆에 자리를 차지합니다. `hidden`은 이 모드에서도 바를 숨깁니다 |
| Jaspr Web | 내용이 넘치고 `interactive: true`이면(`hidden` 제외) 바 영역(기본 폭 10)과 thumb 자리가 내용 위에서 포인터를 받고, `auto` · `thin`에서 바가 숨어 있어도 받습니다. 그래서 터치가 주 입력이 아닌 기기에서는 그 아래에 놓인 내용이 눌리지 않습니다. 터치가 주 입력인 기기에서는 thumb 자리만 받으며, 그 자리에서 쓸기를 시작하면 내용 대신 thumb이 끌릴 수 있습니다. Flutter는 숨은 바가 누르기를 받지 않습니다 |
| Jaspr Web | 마우스 단추를 가리지 않아, 오른쪽 · 가운데 단추로 눌러도 thumb 끌기와 바 누르기가 시작됩니다. Flutter는 기본(왼쪽) 단추로만 시작합니다 |
| Jaspr Web | thumb은 스크롤할 때와, 스크롤 상자나 바로 아래 자식의 크기 · 목록이 바뀔 때 다시 계산합니다. 그 크기는 그대로인데 더 안쪽 요소만 넘치면 다음 스크롤에서 맞춰질 수 있습니다 |
| Jaspr Web | 두께와 여백은 `rem`이라 브라우저 글자 크기를 따르지만, 길이와 위치 계산에 쓰는 여백 · 최소 길이는 px입니다. 글자 크기가 16px이 아니면 조금 어긋납니다 |
| Jaspr Web | 오른쪽에서 왼쪽으로 쓰는 화면의 가로 스크롤은 `aria-valuenow`가 어디에서든 0입니다. thumb은 맞게 움직입니다 |
| Jaspr Web | `interactive: false`는 `overscroll-behavior: contain`도 함께 적용합니다. 스크롤이 끝에 닿아도 바깥 스크롤로 이어지지 않습니다 |
| Flutter | `visibility: always`를 `controller` 없이 쓰면 첫 프레임에 debug 오류가 납니다. release 빌드에는 영향이 없고 둘째 프레임부터 정상으로 동작하지만, 위젯 테스트는 이 오류를 받아 처리하지 않으면 실패합니다 |
| Flutter | `thumbRadius`는 왼쪽 위 모서리의 값을 네 모서리에 모두 씁니다 |
| Flutter | `axis: both`여도 thumb은 한 번에 한 방향만 그립니다([축](#축)) |
| Flutter | 실행 중에 `visibility`를 `hidden`과 다른 값 사이에서 바꾸면 안의 스크롤 뷰가 다시 만들어져 스크롤 위치가 처음으로 돌아갈 수 있습니다 |
| 공통 | `controller`는 Flutter에만 있습니다. 두 플랫폼에서 같은 코드로 스크롤 위치를 옮기는 방법은 없습니다 |

#### 색 대비

thumb의 기본색은 글자색 `on-surface`를 50%(올리거나 끌 때 70%) 불투명도로 겹친 색이라, 라이트에서는 바탕보다 어둡게, 다크에서는 밝게 보입니다. CoUI 팔레트의 `surface` · `surfaceBright` · `surfaceContainerHigh` 위에서는 라이트 · 다크 모두 비텍스트 대비 3:1(WCAG 1.4.11)을 넘습니다. 더 진한 면이나 다른 팔레트 위에 두거나 색을 바꾸면 직접 확인하세요. ScrollArea의 25% 기본색은 이 대비를 맞춘 값이 아닙니다.

#### 동작 줄이기

| 전환 | Flutter | Jaspr Web |
| --- | --- | --- |
| 나타남 · 사라짐(300ms) | 이 설정을 따로 읽지 않습니다. Android의 애니메이션 삭제에서는 Flutter가 시간을 크게 줄이고, iOS의 동작 줄이기에서는 300ms 그대로입니다 | 바로 바뀝니다 |
| 올림 · 끌기의 모양(200ms) | 바로 바뀝니다 | 바로 바뀝니다 |
| 사라지기 전 600ms · 바를 눌러 넘기는 100ms | 그대로입니다 | 그대로입니다 |

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타깃)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

두 플랫폼이 함께 갖는 파라미터는 이름과 기본값이 같습니다. 다음은 다른 자리입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 하는 일 | 스크롤 뷰를 감싸 바를 겹쳐 그립니다 | `Scrollbar`가 스크롤하는 `<div>`가 됩니다 |
| 그리는 방식 | `RawScrollbar`가 화면에 겹쳐 그립니다 | 브라우저 스크롤바는 CSS만으로 모든 브라우저에서 내용 위에 띄울 수 없어 숨기고(`scrollbar-width: none` · `::-webkit-scrollbar`), 높이 0인 `sticky` 요소에 담은 `<div>` thumb을 내용 위에 그립니다 |
| `axis` | 따라갈 스크롤 뷰를 고릅니다 | 스크롤할 수 있는 방향을 정합니다 |
| 자동 적용 | `CoUIApp` 데스크톱의 세로 스크롤 뷰 | 없습니다 |
| 스크롤 위치 | `ScrollController`(선택) | 브라우저의 스크롤 |
| 위치 안내 | `slider` 시맨틱 노드 하나와 늘리기 · 줄이기 동작 | 축마다 `role="scrollbar"` 노드, 동작 없음 |
| 바 누르기 | 마우스 · 펜 · 터치. 바가 보이는 동안 받습니다 | 마우스 · 펜. 바가 숨어 있어도 받지만, 터치가 주 입력인 기기에서는 받지 않습니다 |
| 터치로 thumb 잡기 | thumb 둘레 48 × 48 이상 | 바 폭(10) |
| 포인터를 바에 둔 채 스크롤하거나 끌기를 놓을 때 | `auto` · `thin`은 휠 같은 방법으로 스크롤하면 포인터가 바 위에 있어도 thumb이 사라지고, 포인터를 움직이면 다시 나타납니다. 끌기를 놓은 뒤에도 사라질 수 있습니다 | 포인터가 바 위에 있으면 남습니다 |
| 모서리 | 왼쪽 위 값을 네 모서리에 씁니다 | 네 모서리를 그대로 씁니다 |
| 크기 | 두께 · 여백 · 최소 길이에 테마의 크기 배율을 곱합니다 | 두께 · 여백은 `rem`, 길이 계산은 px입니다 |
| 기기 안전 영역 | `MediaQuery`의 여백을 피해 그립니다 | 반영하지 않습니다 |
| 오른쪽에서 왼쪽 | 세로 바가 왼쪽에 놓입니다 | 같습니다 |
| 색 강제 모드 | — | 브라우저 스크롤바를 씁니다 |
| 추가 파라미터 | `controller` | `id` · `classes` · `css` · `attributes` · `eventHandlers`와 `onClick` 같은 이벤트 처리기 |

<a id="props"></a>
<a id="props-parameters"></a>

## API

타입은 Flutter 기준이고, Web의 `child`는 `Component?`입니다.

### 위젯 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `Widget` | 필수 | Flutter는 감쌀 스크롤 뷰, Web은 스크롤할 내용입니다. Web은 `null`도 받지만 생략할 수는 없습니다 |
| `axis` | `CoreScrollbarAxis` | `CoreScrollbarAxis.defaultAxis`(`both`) | `both` · `vertical` · `horizontal`. 뜻이 플랫폼마다 다릅니다([축](#축)) |
| `visibility` | `CoreScrollbarVisibility` | `CoreScrollbarVisibility.defaultVisibility`(`auto`) | `auto` · `always` · `thin` · `hidden`([표시 정책](#표시-정책)) |
| `interactive` | `bool` | `true` | thumb 끌기와 바 누르기를 받을지. 스크롤은 막지 않습니다 |
| `scrollbarStyle` | `CoreScrollbarStyle?` | `null` | 겉모습 덮어쓰기(아래 필드 표) |
| `controller` | `ScrollController?` | `null` | Flutter 전용. 넘기지 않아도 끌기와 위치 안내가 동작합니다. 넘긴다면 스크롤 뷰와 같은 것을 씁니다 |

Web은 `id` · `classes` · `css` · `attributes` · `eventHandlers`와 `onClick` · `onKeyDown` 같은 이벤트 처리기를 더 받아 바깥 `<div>`에 붙입니다. `classes`는 기본 클래스에 더하고, `css`는 기본 인라인 스타일 뒤에 합칩니다. `eventHandlers`의 `scroll` 처리기는 스크롤바의 처리와 함께 불립니다.

두 플랫폼 모두 `copyWith`와 `withStyle(CoreScrollbarStyle patch)`가 있습니다. 앱 전체 기본값은 `CoreComponentTheme.scrollbar`의 `CoreScrollbarTheme(style: …)`로 둡니다. 선택 상태나, 내용을 대신 만드는 builder 파라미터는 없습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreScrollbarStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `thumbColor` | `CoreColor?` | Thumb colour override. The alpha lives in the colour itself, so one field carries both the ink and how strongly it shows. |
| `hoverThumbColor` | `CoreColor?` | Thumb colour while the pointer is on the thumb or it is being dragged. `null` → [defaultHoverThumbColor]. |
| `thumbRadius` | `CoreBorderRadius?` | Thumb corner radius override. |
| `thickness` | `double?` | Thumb thickness (logical px, pre-scaling). |
| `hoverThickness` | `double?` | Thumb thickness while the pointer is on the thumb or it is being dragged (logical px, pre-scaling). `null` → [defaultHoverThickness]. |
| `thumbInset` | `double?` | Gap between the thumb and the edge it hugs, on every side (logical px, pre-scaling). `null` → [defaultThumbInset]. |
| `minThumbLength` | `double?` | Minimum thumb length (logical px, pre-scaling). `null` → token default ([defaultMinThumbLength]). |
| `trackColor` | `CoreColor?` | Track colour override. `null` → [defaultTrackColor] (transparent — the thumb floats over the content with no visible gutter). |

<!-- STYLE_TABLE:END -->

<Note>

표의 설명과 지금 동작이 다르거나 더 있는 곳입니다. `hoverThumbColor`와 `hoverThickness`는 thumb뿐 아니라 바 영역에 포인터를 올려도 적용됩니다. `hoverThickness`는 바 폭을 넘지 않습니다. 비운 값의 기본값은 `thumbColor`가 `on-surface` 50%, `hoverThumbColor`가 70%, `thumbRadius`가 알약 모양, `thickness`가 6, `hoverThickness`가 8, `thumbInset`이 2, `minThumbLength`가 48, `trackColor`가 투명입니다. 표의 "pre-scaling"은 Flutter가 테마의 크기 배율을 곱하기 전의 값이라는 뜻이고, Web은 두께와 여백을 `rem`으로 그립니다.

</Note>

## 관련 컴포넌트

<Cards columns="3">
<Card title="ScrollArea" href="/components/scroll-area" more="ScrollArea 보기">

스크롤 영역을 만들고 이 스크롤바를 함께 그립니다.

</Card>
<Card title="ScrollableClient" href="/components/scrollable-client" more="ScrollableClient 보기">

두 방향 스크롤 위치를 받아 내용을 직접 그립니다.

</Card>
<Card title="FadeScroll" href="/components/fade-scroll" more="FadeScroll 보기">

넘치는 가장자리를 흐리게 해 내용이 더 있음을 알립니다.

</Card>
</Cards>
