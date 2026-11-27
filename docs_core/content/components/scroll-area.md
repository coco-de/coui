---
title: ScrollArea
description: 콘텐츠를 스크롤 가능한 뷰포트로 감싸고 디자인 시스템 스크롤바를 입히는 래퍼
category: display
platforms: [flutter, web]
related: [scrollbar, fade-scroll, scrollable-client]
tags: [scroll, overflow, viewport]
template: v2
source: layout/scroll_area
---

# ScrollArea

<a id="live-preview"></a>

## 플레이그라운드

`direction` · `maxHeight` · `showScrollbar`를 바꾸고 상자 안을 스크롤해 보세요. 가로 예시는 높이가 내용을 따르므로 `maxHeight`를 넣지 않습니다.

<Playground component="scroll-area" />

`ScrollArea`는 `child`를 한 방향으로 스크롤되는 영역에 담고 CoUI 스크롤바를 함께 그립니다. 바는 [Scrollbar](/components/scrollbar)이고 내용 위에 겹쳐 그려집니다. 내용의 가장자리를 흐리게 하지는 않습니다. 스크롤되는 내용을 놓는 코드는 Flutter의 `Column` · `Row`와 Web의 flex `div`로 달라, 만들어지는 코드가 두 플랫폼에서 다릅니다.

<a id="사용법"></a>
<a id="동작-스펙-behavior"></a>

## 스크롤 방향

`direction`(`CoreScrollAreaDirection`)은 스크롤할 방향 하나를 고릅니다. 값은 `vertical`(기본)과 `horizontal`이고, 두 방향을 함께 스크롤하는 값은 없습니다. 내용이 그 방향으로 영역보다 길 때 스크롤됩니다.

<Preview demo="scroll-area/directions" />

<Note>

웹 문서에서 플레이그라운드를 뺀 미리보기는 브라우저에서 실행되지 않아 thumb이 그려지지 않습니다. 상자 안은 스크롤할 수 있습니다. thumb은 [플레이그라운드](#플레이그라운드)에서 확인하세요.

</Note>

반대 방향으로 넘치는 내용은 스크롤되지 않습니다.

| `direction` | Flutter | Jaspr Web |
| --- | --- | --- |
| `vertical` | `child`의 폭을 영역의 폭 안으로 제한합니다. `Text`는 줄바꿈합니다. | 가로로 넘치는 내용은 잘립니다. |
| `horizontal` | `child`의 높이는 영역의 높이 제한을 따릅니다. | 세로로 넘치는 내용은 잘립니다. |

### 가로 스크롤의 내용

두 플랫폼에서 내용이 가로로 넘치게 만드는 방법이 다릅니다.

- Flutter는 `child`를 폭 제한 없이 배치합니다. `Row`가 그대로 가로로 길어집니다. 이때 긴 `Text`는 폭에 맞춰 줄바꿈하지 않고, `Row` 안의 `Expanded`는 레이아웃 오류가 납니다.
- Web은 글이 영역의 폭에서 줄바꿈합니다. `child`를 줄바꿈하지 않는 flex 행(`flex flex-row whitespace-nowrap`)으로 만듭니다.

<Split>

<Code language="dart" title="Flutter">
ScrollArea(
  direction: CoreScrollAreaDirection.horizontal,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    spacing: CoreSpace.space16,
    children: [
      for (final item in items) Text(item).bodyMedium,
    ],
  ),
)
</Code>

<Code language="dart" title="Web">
ScrollArea(
  direction: CoreScrollAreaDirection.horizontal,
  child: div(
    classes: 'flex flex-row whitespace-nowrap '
        'gap-${CoreSpace.scale.space16}',
    [
      for (final item in items) Text(item).bodyMedium,
    ],
  ),
)
</Code>

</Split>

Flutter의 가로 영역은 세로 마우스 휠만으로는 움직이지 않습니다. 기본 스크롤 설정에서는 Shift를 누른 채 휠을 돌립니다. 터치 끌기로도 움직입니다. Web에서 휠이 어떻게 동작하는지는 브라우저를 따릅니다.

## 뷰포트 크기

크기는 `scrollAreaStyle`의 `height` · `maxHeight`(logical px)로 정합니다. 두 값은 `direction`과 상관없이 영역의 높이에 적용됩니다. 폭을 정하는 필드는 없으므로 폭은 감싼 상자로 정합니다.

<Preview demo="scroll-area/sizes" />

가변 길이의 세로 목록에는 `maxHeight`를 씁니다. 두 플랫폼에서 같게 동작하려면 부모의 높이가 정해지지 않은 자리에 둡니다. `height`는 두 플랫폼에서 뜻이 다릅니다.

| 정한 값 | Flutter | Jaspr Web |
| --- | --- | --- |
| `maxHeight`만 | 내용 높이를 따르다가 `maxHeight`에서 멈춥니다. 부모가 높이를 하나로 강제하면 부모 높이를 씁니다. | 내용 높이를 따르다가 `maxHeight`에서 멈춥니다. 세로 방향은 부모의 높이가 정해져 있으면 내용이 짧아도 부모 높이와 `maxHeight` 가운데 작은 값이 됩니다. |
| `height`만 | 높이의 **상한**입니다. 내용이 짧으면 내용 높이가 됩니다. | **고정** 높이입니다. 내용이 짧아도 그 높이를 차지합니다. |
| 둘 다 | `height`만 상한으로 쓰고 `maxHeight`는 쓰지 않습니다. | CSS `height`와 `max-height`를 함께 적용합니다. 둘 가운데 작은 높이가 됩니다. |

Flutter에서는 부모의 제약이 먼저입니다. `SizedBox(height: …)`나 `Expanded`처럼 부모가 높이를 하나로 강제하면 `height` · `maxHeight` 대신 그 높이를 쓰고, 부모의 최대 높이가 더 작으면 거기에서 멈춥니다.

### 높이를 정하지 않았을 때

`height` · `maxHeight`가 모두 없으면 부모에 따라 달라집니다. 부모에 높이 제한이 없으면 영역이 내용만큼 늘어나 스크롤이 생기지 않고, 스크롤바도 나타나지 않습니다.

| 부모 | Flutter | Jaspr Web (`vertical`) |
| --- | --- | --- |
| 높이가 하나로 정해짐 | 그 높이를 채우고 넘치면 스크롤합니다. | 그 높이를 채우고 넘치면 스크롤합니다. |
| 최대 높이만 있음 | 내용 높이를 따르다가 최대 높이에서 멈추고 스크롤합니다. | 부모가 일반 block `div`이고 `max-height`만 있으면, 영역이 내용만큼 늘어나 부모를 넘치고 스크롤이 생기지 않습니다. |
| 높이 제한 없음 | 내용 높이가 됩니다. `Column`의 직계 자식이면 남은 공간보다 길 때 overflow 오류가 납니다. | 내용 높이가 됩니다. |

Web의 `horizontal` 영역은 부모 높이를 채우도록 지정하지 않아, 일반 block 배치에서는 높이가 내용을 따릅니다.

폭은 Web의 일반 block 배치에서는 부모 폭을 채웁니다. Flutter는 부모가 폭을 강제하지 않으면 내용의 폭만큼만 차지해, 세로 바가 글자 바로 옆에 놓일 수 있습니다. 그때는 `SizedBox(width: …)`로 감싸거나 `Column`에 `CrossAxisAlignment.stretch`를 둡니다.

## 스크롤바

`showScrollbar`는 스크롤바를 그릴지만 정합니다. 스크롤을 켜고 끄는 값이 아닙니다.

| `showScrollbar` | 스크롤바 | 스크롤 |
| --- | --- | --- |
| `true`(기본) | 내용이 넘치는 동안 늘 보입니다. 가만히 있어도 사라지지 않습니다. | 됩니다. |
| `false` | 그리지 않습니다. thumb을 끌 수도 없습니다. | 됩니다. |

Web의 thumb은 `ScrollArea`가 브라우저에서 실행되어야 그려집니다. 서버에서만 렌더한 경우와 색 강제 모드는 [알려진 제약](#알려진-제약)을 보세요.

스크롤할 때만 나타나는 `auto` · `thin` 표시를 고르거나 바 조작을 막는(`interactive`) 파라미터는 없습니다. 그런 설정이 필요하면 [Scrollbar](/components/scrollbar)를 직접 씁니다.

스타일을 덮어쓰지 않으면 바의 모양은 다음과 같습니다.

| 항목 | 기본값 |
| --- | --- |
| thumb 두께 | 6. thumb이나 바 영역에 포인터를 올리거나 thumb을 끄는 동안 8 |
| 가장자리 여백 | 2. 바 폭은 10입니다. |
| thumb 최소 길이 | 48. 보이는 영역이 더 작으면 여백을 뺀 길이를 씁니다. |
| thumb 색 | `on-surface` 25%. 올리거나 끄는 동안 `on-surface` 70% |
| 모서리 · 바 영역 색 | 알약 모양 · 투명 |

직접 그리는 바는 내용 위에 겹치므로 내용의 폭을 줄이지 않습니다. 글자가 가장자리까지 닿으면 `child` 안에 여백을 둡니다. 특히 가로 영역은 아래쪽 여백이 없으면 바가 글자를 덮을 수 있습니다.

thumb을 끌면 내용이 비례해서 움직이고, 바 영역에서 thumb이 아닌 곳을 누르면 그쪽으로 넘어갑니다. 입력 방식에 따른 차이는 [Scrollbar의 상태](/components/scrollbar#상태)에 있습니다.

## 스크롤 위치

로딩 · 선택 상태나 스크롤 값을 넘겨 주는 전용 콜백은 없고, `child`의 상태는 호출자가 관리합니다.

`controller`는 Flutter에만 있습니다. 넘기지 않으면 `ScrollArea`가 컨트롤러를 만들고 스스로 `dispose`합니다. 직접 넘긴 컨트롤러는 넘긴 쪽에서 `dispose`합니다.

```dart
// Flutter — controller는 State에서 만들고 dispose합니다.
ScrollArea(
  controller: controller,
  scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: 240),
  child: content,
)

// 맨 위로 옮길 때
controller.jumpTo(0);
```

| 하려는 일 | Flutter | Jaspr Web |
| --- | --- | --- |
| 위치 읽기 · 따라가기 | `controller.addListener`, 또는 바깥의 `NotificationListener<ScrollNotification>`(안쪽 스크롤의 알림도 함께 옵니다) | `eventHandlers`의 `scroll` |
| 위치 옮기기 | `controller` | 파라미터가 없습니다. 위치는 브라우저가 관리합니다. |

## 중첩 스크롤

`ScrollArea` 안에 `ScrollArea`를 둘 수 있습니다. 각 영역은 자기 스크롤을 따라가는 바를 따로 갖습니다. 아래는 세로 영역 안에 가로 영역을 둔 예시입니다. 웹 문서의 이 미리보기에는 thumb이 없고, 두 영역의 스크롤만 됩니다.

<Preview demo="scroll-area/inside" />

| 입력 | Flutter | Jaspr Web |
| --- | --- | --- |
| 마우스 휠 | 포인터 아래의 안쪽 영역이 휠 방향으로 더 움직일 수 있으면 안쪽이 받습니다. 끝에 닿았거나 방향이 다르면 바깥 영역이 받습니다. | 브라우저를 따릅니다. 안쪽이 끝에 닿으면 이어지는 스크롤이 바깥으로 넘어갈 수 있습니다. `ScrollArea`는 이를 막는 CSS를 붙이지 않습니다. |
| 같은 방향의 터치 끌기 | 안쪽 영역이 넘치면 안쪽이 끌기를 받습니다. 끝에 닿아도 그 끌기는 바깥으로 넘어가지 않습니다. | 브라우저를 따릅니다. |

- 같은 방향으로 겹칠 때는 안쪽에 `maxHeight`를 정합니다. 높이를 정하지 않은 안쪽 영역은 바깥의 스크롤 안에서 내용만큼 늘어나 따로 스크롤되지 않을 수 있습니다. 두 스크롤이 겹치면 어느 쪽이 움직일지 알기 어려우니 방향이 다른 구성을 먼저 검토합니다.
- Web에서 넘치는 안쪽 영역의 스크롤이 바깥으로 이어지지 않게 하려면 `css`에 `overscroll-behavior`를 정합니다.
- 키보드는 포커스가 있는 곳에 따라 달라집니다([키보드](#키보드)).

```dart
// Web
ScrollArea(
  css: Styles(
    raw: {'overscroll-behavior': 'contain'},
  ),
  scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: 160),
  child: content,
)
```

<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

내용 한 덩어리를 한 방향으로 스크롤하면서 CoUI 스크롤바를 늘 보이게 할 때 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| Flutter에 이미 있는 스크롤 뷰에 바만 붙일 때, `auto` · `thin` 표시나 `interactive`가 필요할 때 | [Scrollbar](/components/scrollbar) |
| 두 방향으로 스크롤하거나, 스크롤 위치와 보이는 영역의 크기를 받아 내용을 그릴 때 | [ScrollableClient](/components/scrollable-client) |
| 스크롤 영역 자체가 키보드 포커스를 받아 화살표 키로 움직여야 할 때 | [ScrollableClient](/components/scrollable-client) |
| 넘치는 가장자리를 흐리게 해 내용이 더 있음을 알릴 때 | [FadeScroll](/components/fade-scroll) |

기존 스크롤 영역에 가운데 버튼 자동 스크롤을 덧붙이려면 [ScrollViewInterceptor](/components/scrollview)를 씁니다.

### 항목이 아주 많은 목록

`ScrollArea`는 화면 밖의 항목까지 `child` 전체를 한 번에 만듭니다. Flutter에서 항목이 아주 많으면 필요한 항목만 만드는 `ListView.builder`를 쓰고, 바가 필요하면 `Scrollbar`로 감쌉니다. Flutter에서 `ScrollArea`의 `child`에 같은 방향의 `ListView`를 그대로 넣으면 목록의 크기를 정할 수 없어 레이아웃 오류가 납니다.

`ScrollArea` 안에서는 Flutter가 스크롤 뷰에 자동으로 붙이는 스크롤바가 꺼집니다. `child` 안의 다른 스크롤 뷰에 바가 필요하면 그 뷰를 `Scrollbar`로 감쌉니다.

<a id="do"></a>

### 가변 길이 내용에는 높이 제한

높이를 정할 곳이 없으면 영역이 내용만큼 늘어나 스크롤도 스크롤바도 생기지 않습니다. 부모가 높이를 정해 주지 않는 자리에서는 `maxHeight`를 적습니다.

<Split>

<Code language="dart" title="이렇게 하세요 — Flutter">
ScrollArea(
  scrollAreaStyle: const CoreScrollAreaStyle(
    maxHeight: 240,
  ),
  child: Column(
    children: [
      for (final item in items) Text(item),
    ],
  ),
)
</Code>

<Code language="dart" title="이렇게 하지 마세요 — Flutter">
// 부모에도 높이 제한이 없으면
// 내용만큼 늘어나고 스크롤되지 않습니다.
ScrollArea(
  child: Column(
    children: [
      for (final item in items) Text(item),
    ],
  ),
)
</Code>

</Split>

<a id="dont"></a>

### 스크롤바를 숨길 때

`showScrollbar: false`는 내용이 더 있다는 것을 알리는 바를 없애고, 대신할 표시를 넣지 않습니다. 잘린 항목, 가장자리 그라데이션, 페이지 표시, 화살표 버튼처럼 다른 단서가 있을 때만 숨깁니다. 그런 단서가 없으면 더 볼 내용이 있다는 것을 알기 어렵습니다. 마우스로 내용을 끌어서는 스크롤되지 않으므로, 바를 숨기면 마우스 사용자는 thumb도 끌 수 없습니다.

```dart
// 넘침을 알릴 다른 수단 없이 스크롤바만 숨깁니다 — 피하세요.
ScrollArea(
  showScrollbar: false,
  scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: 180),
  child: longContent,
)
```

## 테마와 스타일

높이와 스크롤바의 모양은 `scrollAreaStyle`(`CoreScrollAreaStyle`) 하나로 바꿉니다. 바의 모양은 그 안의 `scrollbarStyle`(`CoreScrollbarStyle`)에 적습니다. `direction` · `showScrollbar` · `controller`는 위젯 파라미터라 스타일이나 테마로 바꿀 수 없습니다. 안쪽 여백 · 폭 · 바탕색 · 테두리 필드는 없으므로 `child`나 감싼 상자에서 정합니다.

<Split>

<Code language="dart" title="하나만 바꾸기">
ScrollArea(
  scrollAreaStyle: const CoreScrollAreaStyle(
    maxHeight: 240,
    scrollbarStyle: CoreScrollbarStyle(
      thumbColor: CoreColor.token(
        CoreColors.primary,
      ),
      hoverThumbColor: CoreColor.token(
        CoreColors.primary,
      ),
    ),
  ),
  child: content,
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    scrollArea: CoreScrollAreaTheme(
      style: CoreScrollAreaStyle(
        scrollbarStyle: CoreScrollbarStyle(
          thumbColor:
              CoreScrollbarStyle.defaultThumbColor,
        ),
      ),
    ),
  ),
)
</Code>

</Split>

### 값이 정해지는 순서

뒤로 갈수록 우선하고, 필드마다 따로 합쳐집니다.

```text
높이 (height · maxHeight) — 디자인 시스템 기본값 없음
  CoreComponentTheme.scrollArea.style                    // 앱 전체
  → scrollAreaStyle                                      // 하나만

스크롤바 모양
  CoreScrollbarStyle 기본값
  → CoreComponentTheme.scrollbar.style                   // 모든 Scrollbar
  → ScrollArea의 thumb 색 (on-surface 25%)
  → CoreComponentTheme.scrollArea.style.scrollbarStyle   // 모든 ScrollArea
  → scrollAreaStyle.scrollbarStyle                       // 하나만
```

- `CoreScrollbarTheme`의 두께 · 여백 같은 값은 `ScrollArea`의 바에도 적용되지만, `thumbColor`는 `ScrollArea`의 thumb 색에 가려 적용되지 않습니다. 색은 `CoreScrollAreaTheme`이나 `scrollAreaStyle`에서 바꿉니다.
- `thumbColor`만 바꾸면 올리거나 끌 때의 색은 따라 바뀌지 않습니다. 같은 계열로 두려면 `hoverThumbColor`도 정합니다. 두께를 바꿀 때의 `hoverThickness`는 [Scrollbar의 테마와 스타일](/components/scrollbar#테마와-스타일)을 보세요.
- 테마에 `height` · `maxHeight`를 적으면 모든 `ScrollArea`에 적용됩니다. 인스턴스에서 값을 비우면 테마 값을 그대로 쓰므로, 비워서 해제할 수는 없습니다.
- Flutter는 `height` · `maxHeight`와 바의 두께 · 여백 · 최소 길이에 테마의 크기 배율을 곱합니다. Web은 `height` · `maxHeight`를 `rem`으로 그립니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

이미 만든 `ScrollArea`에 `withStyle`로 스타일을 덧붙일 수 있습니다. 생성자의 `scrollAreaStyle`에 주는 것과 같고, 여러 번 이으면 겹치는 값은 뒤의 것이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ScrollAreaChainExample extends StatelessWidget {
  const ScrollAreaChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child:
          ScrollArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Theme.of(context).geometry.space(CoreSpace.space8),
              children: [
                for (var i = 1; i <= 20; i += 1) Text('스크롤 항목 $i').bodyMedium,
              ],
            ),
          ).withStyle(
            const CoreScrollAreaStyle(
              height: CoreSpace.space192,
              maxHeight: CoreSpace.space192,
              scrollbarStyle: CoreScrollbarStyle(
                thumbColor: CoreColor.token(CoreColors.primary),
                thumbRadius: CoreBorderRadius.all(CoreRadius.radius9999),
                thickness: CoreStrokeWidth.stroke8,
              ),
            ),
          ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class ScrollAreaChainExample extends StatelessComponent {
  const ScrollAreaChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '260px'}),
      [
        ScrollArea(
          child: div(
            classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
            [
              for (var i = 1; i <= 20; i += 1) Text('스크롤 항목 $i').bodyMedium,
            ],
          ),
        ).withStyle(
          const CoreScrollAreaStyle(
            height: CoreSpace.space192,
            maxHeight: CoreSpace.space192,
            scrollbarStyle: CoreScrollbarStyle(
              thumbColor: CoreColor.token(CoreColors.primary),
              thumbRadius: CoreBorderRadius.all(CoreRadius.radius9999),
              thickness: CoreStrokeWidth.stroke8,
            ),
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

이 예제는 `hoverThumbColor`를 정하지 않아, 올리거나 끌면 thumb이 `primary`가 아니라 `on-surface` 70%가 됩니다. `thickness` 8은 올렸을 때의 기본 두께와 같아 두께는 바뀌지 않습니다.

</Note>

<a id="접근성-accessibility"></a>

## 접근성

### 역할

스크롤 영역 자체에는 두 플랫폼 모두 역할과 이름을 붙이지 않습니다. 함께 그리는 [Scrollbar](/components/scrollbar)가 화면에 보이지 않는 위치 노드를 하나 둡니다. 이 노드는 `showScrollbar: false`에서도 남습니다.

| 플랫폼 | 보조 기술이 받는 것 |
| --- | --- |
| Flutter | 스크롤 뷰가 제공하는 스크롤 시맨틱과, 값을 `'40%'`처럼 알리는 `slider` `Semantics` 노드 하나. 노드에 라벨은 없습니다. |
| Jaspr Web | 바깥 `<div>`에는 `role` · `aria-*`를 붙이지 않습니다(`attributes`로 넘긴 것은 그대로 붙습니다). 안에 시각적으로 숨긴 `<div role="scrollbar">` 하나를 두고 `aria-orientation` · `aria-valuenow` · `aria-valuemin="0"` · `aria-valuemax="100"` · `aria-controls`를 붙입니다. 이름은 없습니다. 그려진 thumb과 바 영역은 `aria-hidden`입니다. |

#### 영역 이름 붙이기

"여기가 공지 목록"처럼 영역의 이름이 필요하면 직접 붙입니다. Web은 `attributes`를 쓰고, 키보드로 확실히 닿게 하려면 `tabindex`도 함께 정합니다.

<Split>

<Code language="dart" title="Flutter — 이름 있는 묶음으로 감싸기">
Semantics(
  container: true,
  explicitChildNodes: true,
  label: '공지 목록',
  child: ScrollArea(
    scrollAreaStyle: const CoreScrollAreaStyle(
      maxHeight: 240,
    ),
    child: notices,
  ),
)
</Code>

<Code language="dart" title="Web — 스크롤 상자에 속성 붙이기">
ScrollArea(
  attributes: const {
    'tabindex': '0',
    'role': 'region',
    'aria-label': '공지 목록',
  },
  scrollAreaStyle: const CoreScrollAreaStyle(
    maxHeight: 240,
  ),
  child: notices,
)
</Code>

</Split>

Flutter의 코드는 영역 바깥에 이름 있는 묶음을 하나 더 만듭니다. 위치 노드에 이름이 붙는 것은 아닙니다.

### 키보드

`ScrollArea`가 직접 처리하는 키는 없습니다. 키보드 스크롤은 Flutter와 브라우저의 기본 동작을 따릅니다.

#### Flutter

Flutter의 기본 단축키는 **포커스가 있는 위젯을 감싼 가장 가까운 스크롤 뷰**를 움직입니다. `ScrollArea`는 스스로 포커스를 받지 않으므로, 안에 포커스를 받는 위젯이 없으면 이 단축키로 이 영역을 스크롤할 수 없습니다. 앱에서 `shortcuts`를 바꾸면 아래 표와 달라집니다.

| 실행 환경 | 조금씩(50) | 크게(보이는 높이의 80%) |
| --- | --- | --- |
| 웹 빌드 | 화살표 | Page Up · Page Down |
| macOS · iOS | ⌘ + 화살표 | Page Up · Page Down |
| Windows · Linux · Android | Ctrl + 화살표 | Page Up · Page Down |

- Home · End에는 기본 단축키가 없습니다. 웹 빌드가 아니면 수정 키 없는 화살표는 포커스 이동에 쓰입니다. 입력창처럼 키를 직접 쓰는 위젯에 포커스가 있으면 그 위젯의 동작이 먼저입니다.
- Page Up · Page Down은 세로 방향의 동작입니다.
- 겹친 영역에서는 가장 가까운 영역만 대상입니다. 키의 방향이 그 영역의 방향과 다르면 바깥 영역도 움직이지 않습니다. 예를 들어 가로 영역 안에 포커스가 있으면 위아래 키로 바깥 세로 영역이 움직이지 않습니다.

Flutter 웹 빌드에서 접근성 트리를 켠 경우의 위치 노드는 [Scrollbar의 키보드](/components/scrollbar#키보드)를 보세요.

#### Jaspr Web

스크롤 상자에는 `tabindex`가 없습니다. 안에 포커스를 받는 요소가 없는 스크롤 상자에 키보드 포커스를 주는지는 브라우저마다 다릅니다. 상자가 포커스를 받으면 브라우저의 스크롤 키로 움직입니다. 모든 브라우저에서 닿게 하려면 [영역 이름 붙이기](#영역-이름-붙이기)처럼 `tabindex="0"`을 정합니다.

`onKeyDown` · `onKeyUp`은 받은 처리기를 바깥 상자에 붙일 뿐입니다. 상자가 포커스를 받지 않으면 안쪽 요소에서 올라온 키 이벤트만 받습니다.

### 스크린 리더

영역에는 읽을 이름이 없고, 안의 내용은 각 요소가 가진 대로 전달됩니다. 위치 노드는 스크롤 위치를 0에서 100까지의 퍼센트로 알립니다. 바뀐 값을 따로 읽어 주는 라이브 영역은 없습니다.

| 조건 | Flutter | Jaspr Web |
| --- | --- | --- |
| 위치를 바꾸는 동작 | 내용이 넘치면 늘리기 · 줄이기 동작이 있고, 한 번에 스크롤 범위의 10%씩 움직입니다. 각 끝에서는 그 방향의 동작이 없습니다. | 위치 노드에는 동작이 없습니다. |
| 내용이 넘치지 않을 때 | 0%이고 늘리기 · 줄이기 동작이 없습니다. | 0%입니다. |
| 읽는 순서 | — | 위치 노드가 `child`보다 앞에 놓입니다. 화면에서 잘린 내용도 문서에 그대로 있습니다. |
| 브라우저에서 재기 전 | — | 0%입니다. |

### 포커스 관리

두 플랫폼 모두 `ScrollArea`는 스스로 포커스를 받도록 설정하지 않습니다. 포커스 표시를 그리지 않고, 포커스를 가두거나 되돌리지 않습니다. 안의 포커스를 받는 요소는 그대로 동작합니다.

- Flutter는 `FocusNode`를 두지 않아 영역이 Tab 순서에 들어가지 않습니다.
- Web은 `tabindex`를 붙이지 않습니다. 그래도 브라우저가 스크롤 상자를 Tab 순서에 넣을 수 있으며, 넣는지는 브라우저마다 다릅니다([키보드](#키보드)).

Tab으로 화면 밖의 요소에 이동하면, Flutter에서는 기본 포커스 이동이, Web에서는 브라우저가 그 요소가 보이도록 스크롤합니다. Web에서 `tabindex`를 직접 넣으면 `ScrollArea`가 따로 그리는 포커스 표시는 없으므로, 포커스가 눈에 보이는지 확인합니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 스크롤 영역 자체에는 역할과 이름이 없고, 위치 노드에도 이름이 없습니다. |
| 공통 | 기본 thumb 색(`on-surface` 25%)은 CoUI 기본 팔레트의 `surface` 위에서 비텍스트 대비 3:1(WCAG 1.4.11)에 못 미칩니다. 더 진하게 하려면 `thumbColor`를 정합니다. `CoreScrollbarStyle.defaultThumbColor`(50%)를 넣으면 [Scrollbar](/components/scrollbar)의 기본색이 됩니다. |
| 공통 | `showScrollbar: false`는 내용이 더 있다는 스크롤바 단서를 없애고 대신할 표시를 그리지 않습니다. 위치 노드는 남습니다. |
| 공통 | `showScrollbar: true`이고 내용이 넘치면 가장자리의 바 영역(기본 폭 10)이 포인터를 받아, 그 아래의 내용은 눌리지 않습니다. 터치가 주 입력인 Web 기기에서는 thumb 자리만 받습니다. |
| 공통 | `controller`는 Flutter에만 있어, 두 플랫폼에서 같은 코드로 특정 위치까지 스크롤할 수는 없습니다. |
| Flutter | `ScrollArea`는 포커스를 받지 않아, 안에 포커스를 받는 위젯이 없으면 기본 단축키로 스크롤할 수 없습니다. |
| Flutter | 실행 중에 `showScrollbar`를 바꾸면 안의 스크롤 뷰와 `child`가 다시 만들어져, `child`의 상태가 처음으로 돌아가고 스크롤 위치도 처음으로 돌아갈 수 있습니다. 테마까지 합친 `height` · `maxHeight`가 둘 다 없다가 하나라도 생기거나, 있다가 둘 다 없어져도 같습니다. 값의 크기만 바꾸는 것은 해당하지 않습니다. |
| Jaspr Web | 키보드 포커스가 스크롤 상자에 닿는지는 브라우저에 달려 있습니다. |
| Jaspr Web | thumb은 브라우저에서 실행되는 `ScrollArea`만 그립니다. 서버에서만 렌더하고 브라우저에서 깨우지 않으면(`@client` 밖), 브라우저 스크롤바도 숨긴 상태라 아무 바도 보이지 않습니다. 스크롤은 됩니다. |
| Jaspr Web | 색 강제 모드(`forced-colors: active`)에서는 `showScrollbar: true`일 때 직접 그린 thumb 대신 브라우저 스크롤바를 남깁니다. 이 바는 `scrollbarStyle`을 따르지 않고, 운영체제에 따라 내용 옆에 자리를 차지합니다. `false`는 이 모드에서도 숨깁니다. |
| Jaspr Web | 오른쪽에서 왼쪽으로 쓰는 화면의 가로 영역은 `aria-valuenow`가 어느 위치에서든 0입니다. |
| Jaspr Web | thumb은 스크롤할 때와, 스크롤 상자나 바로 아래 자식의 크기 · 목록이 바뀔 때 다시 계산합니다. 그 크기는 그대로인데 더 안쪽 요소만 달라지면 다음 스크롤에서 맞춰질 수 있습니다. |

바 자체의 그 밖의 제약은 [Scrollbar의 알려진 제약](/components/scrollbar#알려진-제약)에 있습니다.

동작 줄이기 · 고대비 · 최소 터치 타깃처럼 컴포넌트를 가로지르는 항목은 [전역 접근성 축](/accessibility)에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

두 플랫폼이 함께 갖는 파라미터는 이름과 기본값이 같습니다. 다음은 다른 점입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 스크롤하는 곳 | `SingleChildScrollView`를 `Scrollbar`로 감쌉니다. | 함께 쓰는 `Scrollbar`의 바깥 `<div>`가 `overflow`로 스크롤합니다. |
| 위치 제어 | `ScrollController`. 생략하면 안에서 만들고 `dispose`합니다. | 브라우저의 스크롤 |
| `height` | 높이의 상한 | 고정 높이 |
| `height`와 `maxHeight`를 함께 | `height`만 씁니다. | 둘 다 CSS로 적용합니다. |
| 부모가 높이를 정한 경우 | 부모가 높이를 강제하면 `height` · `maxHeight`보다 우선합니다. | CSS 규칙을 따릅니다. 세로 영역은 `height`가 없으면 `max-height` 안에서 부모 높이를 채웁니다. |
| 부모가 폭을 정하지 않은 경우 | 내용의 폭 | 일반 block 배치에서는 부모의 폭 |
| 가로로 넘치게 만들기 | `Row`처럼 가로로 긴 `child` | 줄바꿈하지 않는 flex 행 |
| 끝에서의 동작 | `CoUIApp`의 기본 스크롤 설정에서는 끝을 넘겨 끌면 튕깁니다. | 브라우저를 따릅니다. |
| 높이의 단위 | 테마의 크기 배율을 곱합니다. | `rem`이라 브라우저 글자 크기를 따릅니다. |
| 키보드 | 포커스가 안에 있을 때 Flutter의 기본 단축키 | 브라우저의 동작. 상자의 `tabindex`는 직접 정합니다. |
| 위치 안내 | `slider` 시맨틱 노드와 늘리기 · 줄이기 동작 | `role="scrollbar"` 노드, 동작 없음 |
| 터치로 thumb 잡기 | thumb 둘레 48 × 48 이상 | 바 폭(10) |
| 색 강제 모드 | — | 브라우저 스크롤바를 씁니다. |
| 추가 파라미터 | `controller` | `id` · `classes` · `css` · `attributes` · `eventHandlers`와 이벤트 처리기 |

<a id="props"></a>
<a id="props-parameters"></a>

## API

타입은 Flutter 기준입니다. Web의 `child`는 `Component`입니다.

### 위젯 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `Widget` | 필수 | 영역 안에서 스크롤되는 내용 |
| `direction` | `CoreScrollAreaDirection` | `CoreScrollAreaDirection.defaultDirection`(`vertical`) | 스크롤 방향. `vertical` · `horizontal` |
| `showScrollbar` | `bool` | `true` | 스크롤바를 그릴지. `false`여도 스크롤은 됩니다. |
| `scrollAreaStyle` | `CoreScrollAreaStyle?` | `null` | 높이와 스크롤바 모양(아래 필드 표) |
| `controller` | `ScrollController?` | `null` | Flutter 전용. 스크롤 위치를 밖에서 읽고 옮깁니다. |

### Web 전용 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 바깥 `<div>`의 `id` |
| `classes` | `String?` | `null` | 바깥 `<div>`의 기본 클래스에 더합니다. 내용의 배치(flex · grid · 간격)는 `child`에서 정합니다. |
| `css` | `Styles?` | `null` | 바깥 `<div>`의 인라인 스타일. `height` · `max-height` 뒤에 합치므로 같은 속성은 이 값이 이깁니다. |
| `attributes` | `Map<String, String>?` | `null` | 바깥 `<div>`의 HTML 속성 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | DOM 이벤트 처리기. `scroll` 처리기는 스크롤바의 처리와 함께 불립니다. |

`onClick` · `onKeyDown` · `onKeyUp` · `onMouseEnter` · `onMouseLeave`도 받아 바깥 `<div>`에 붙입니다. `onInput` · `onChange`는 생성자에 있지만, 넘긴 함수가 불리지 않습니다. 안의 입력에서 올라오는 `input` · `change` 이벤트는 `eventHandlers`로 받습니다.

### 그 밖의 멤버와 테마

두 플랫폼 모두 `copyWith`와 `withStyle(CoreScrollAreaStyle patch)`가 있습니다. `withStyle`은 `scrollAreaStyle`에 `patch`를 합친 사본을 돌려주고, 겹치는 값은 `patch`가 이깁니다. 앱 전체 기본값은 `CoreComponentTheme.scrollArea`의 `CoreScrollAreaTheme(style: …)`로 둡니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreScrollAreaStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `height` | `double?` | Fixed viewport height in logical pixels. When null the scroll area takes its parent's height (or its child's natural height when the parent sets no limit). |
| `maxHeight` | `double?` | Maximum viewport height in logical pixels. When set, the scroll area takes the child's natural height up to this maximum and scrolls when the child is taller. Combines with [height]: when both are set, each platform applies both. |
| `scrollbarStyle` | `CoreScrollbarStyle?` | Style of the `Scrollbar` inside — thumb colour, thickness, corner radius, minimum length, track colour. When null falls back to [defaultScrollbarStyle]; partial overrides merge on top of it. |

<!-- STYLE_TABLE:END -->

<Note>

표의 설명과 지금 동작이 다른 곳입니다. `height`는 Web에서는 고정 높이이지만 Flutter에서는 높이의 상한입니다. `height`를 비웠다고 늘 부모의 높이를 갖는 것은 아닙니다. Flutter는 부모가 높이를 강제할 때, Web의 세로 영역은 부모의 높이가 정해져 있을 때 부모 높이를 갖습니다. 같은 이유로 `maxHeight`만 정해도 이때는 내용이 짧은 영역이 늘어납니다. 두 값을 함께 정하면 Flutter는 `height`만 쓰고, Web은 둘 다 적용합니다. `scrollbarStyle`을 비우면 쓰는 `defaultScrollbarStyle`은 thumb 색만 정합니다. 나머지는 `CoreScrollbarTheme`과 `CoreScrollbarStyle`의 기본값을 따릅니다.

</Note>

## 관련 컴포넌트

<Cards columns="3">
<Card title="Scrollbar" href="/components/scrollbar" more="Scrollbar 보기">

스크롤 영역에 CoUI 스크롤바를 입히고, 언제 보일지 직접 정합니다.

</Card>
<Card title="FadeScroll" href="/components/fade-scroll" more="FadeScroll 보기">

넘치는 가장자리를 흐리게 해 내용이 더 있음을 알립니다.

</Card>
<Card title="ScrollableClient" href="/components/scrollable-client" more="ScrollableClient 보기">

두 방향 스크롤 위치를 받아 내용을 직접 그립니다.

</Card>
</Cards>
