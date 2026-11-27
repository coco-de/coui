---
title: FadeScroll
description: 내용을 한 방향으로 스크롤하게 담고, 가려진 내용이 있는 쪽 가장자리를 투명하게 흐립니다.
category: display
platforms: [flutter, web]
related: [chip-group, scroll-area, overflow-marquee, scrollable-client]
tags: [scroll, fade, overflow, mask]
template: v2
source: layout/fade_scroll
---

# FadeScroll

<a id="live-preview"></a>

## 플레이그라운드

스크롤 축과 페이드 길이를 바꾸고 상자를 스크롤해 보세요. 만들어진 코드는 그대로 복사할 수 있습니다.

<Playground component="fade-scroll" />

`FadeScroll`은 자식을 스크롤 영역에 담고, 내용이 더 이어지는 쪽 가장자리를 서서히 투명하게 만듭니다. 가장자리에 색을 덧칠하지 않고 내용의 불투명도를 낮추는 마스크라서, 흐려진 자리에는 뒤의 바탕이 비칩니다. 자식에게 스크롤 뷰나 컨트롤러를 따로 붙이지 않아도 됩니다.

처음에는 끝 쪽만 흐립니다. 스크롤하면 시작 쪽도 흐려지고, 끝에 닿으면 끝 쪽이 선명해집니다. Web은 브라우저에 따라 끝 쪽 페이드가 남습니다([알려진 제약](#알려진-제약)). 페이드 길이 컨트롤은 `startOffset`과 `endOffset`에 같은 값을 넣습니다.

<a id="기본-사용법-basic-usage"></a>

## 방향

`direction`으로 스크롤 축을 고릅니다. 기본값은 `CoreFadeScrollDirection.vertical`이고, 한 번에 한 축만 스크롤합니다.

| 값 | 스크롤 | 시작 쪽 | 끝 쪽 |
| --- | --- | --- | --- |
| `vertical` | 위아래 | 위 | 아래 |
| `horizontal` | 좌우 | 왼쪽 | 오른쪽 |

<Preview demo="fade-scroll/directions" />

<Note>

웹 문서의 본문 미리보기는 서버에서 그린 화면 그대로입니다. 그래서 Web 미리보기는 스크롤해도 페이드가 바뀌지 않습니다. 스크롤을 따라 바뀌는 모습은 플레이그라운드에서 확인하세요.

</Note>

세로 목록은 기본값만으로 충분합니다. 아래 가로 예제는 페이드 길이를 32로 줄였습니다. `items`와 `cards`는 화면에서 만든 목록입니다. 크기를 주는 방법은 [배치](#배치)를 보세요.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
// 세로 — 높이를 정한 곳에 둡니다
SizedBox(
  height: CoreSpace.space240,
  child: FadeScroll(
    child: Column(children: items),
  ),
)

// 가로 — 앞뒤 페이드 길이 32
FadeScroll(
  direction: CoreFadeScrollDirection.horizontal,
  fadeScrollStyle: const CoreFadeScrollStyle(
    startOffset: CoreSpace.space32,
    endOffset: CoreSpace.space32,
  ),
  child: Row(children: cards),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
// 세로 — 높이를 정한 부모에 둡니다
div(
  styles: Styles(raw: {'height': '240px'}),
  [
    FadeScroll(child: div(items)),
  ],
)

// 가로 — 앞뒤 페이드 길이 32
FadeScroll(
  direction: CoreFadeScrollDirection.horizontal,
  fadeScrollStyle: const CoreFadeScrollStyle(
    startOffset: CoreSpace.space32,
    endOffset: CoreSpace.space32,
  ),
  child: div(
    cards,
    styles: Styles(raw: {'display': 'flex', 'width': 'max-content'}),
  ),
)
```

  </TabItem>
</Tabs>

<a id="동작-스펙-behavior"></a>

## 상태

`FadeScroll`에는 비활성이나 선택 같은 상태가 없습니다. 달라지는 것은 어느 가장자리가 흐린지이고, 스크롤 위치가 정합니다.

| 위치 | 시작 쪽 | 끝 쪽 |
| --- | --- | --- |
| 다 보임 | 선명 | 선명 |
| 처음 | 선명 | 흐림 |
| 중간 | 흐림 | 흐림 |
| 끝 | 흐림 | 선명 |

<Preview demo="fade-scroll/states" />

위 표는 Flutter와, `ScrollTimeline`을 지원하는 브라우저의 Web이 계산을 마친 화면입니다. 처음이나 끝의 위치에서 조금이라도 벗어나면 그 쪽의 페이드 구간 전체가 켜집니다. 켜지고 꺼질 때의 애니메이션은 없습니다. 내용이 스스로 움직이지 않으며, 끝에 닿았음을 알리는 콜백도 없습니다. Flutter에서 위치를 읽어야 하면 `controller`를 넘기세요.

페이드를 다시 계산하는 때는 플랫폼마다 다릅니다.

| 플랫폼 | 다시 계산하는 때 |
| --- | --- |
| Flutter | 첫 프레임을 그린 직후 한 번, 그 뒤에는 스크롤로 위치가 움직일 때입니다. `FadeScroll`이 다시 빌드될 때도 계산하지만, 그때 읽는 크기는 직전 화면의 것입니다. |
| Web — `ScrollTimeline` 지원 | 브라우저가 실제 위치와 크기를 따라 갱신합니다. 내용이나 글꼴이 바뀌어 넘침이 달라져도 스크롤 없이 반영합니다. |
| Web — 미지원 | 스크롤할 때와 스크롤 상자의 크기가 바뀔 때입니다. |

`ScrollTimeline` 지원은 `ScrollTimeline`과 애니메이션의 `rangeStart` · `rangeEnd`를 모두 쓸 수 있는 브라우저를 말합니다. 둘 중 하나라도 없으면 미지원입니다.

## 페이드 구간

`startOffset`은 시작 쪽, `endOffset`은 끝 쪽 페이드의 길이(논리 픽셀)입니다. 기본값은 둘 다 40입니다. 그 방향에 가려진 내용이 있을 때만 흐려지고, 0을 주면 그 쪽은 흐려 보이지 않습니다. Web의 예외는 [알려진 제약](#알려진-제약)에 있습니다.

<Preview demo="fade-scroll/offsets" />

Flutter는 길이에 테마의 크기 배율(`theme.scaling`)을 곱합니다. Web은 적은 값을 그대로 CSS px로 씁니다.

두 길이의 합은 스크롤 축 방향의 상자 길이를 넘지 않게 둡니다. 넘으면 두 플랫폼이 다르게 그립니다. Web의 끝 쪽 페이드는 시작 쪽이 선명할 때에도 `startOffset` 지점보다 앞에서 시작하지 않습니다. 예를 들어 높이 120인 상자에 앞뒤 96을 주면, 첫 화면의 아래 페이드는 Flutter(크기 배율 1)에서 96이고 Web에서 24입니다.

<a id="do"></a>

## 스크롤 막대

`showScrollbar`의 기본값은 `false`입니다. 막대를 숨겨도 스크롤은 됩니다.

| 플랫폼 | `showScrollbar: true`일 때 |
| --- | --- |
| Flutter | CoUI `Scrollbar`를 씁니다. 스크롤하는 동안 나타났다가 사라지고, 막대 자리에 포인터를 올려도 나타납니다. `CoreComponentTheme.scrollbar`의 스타일을 따르며, 페이드 마스크 바깥에 그립니다. |
| Web | 브라우저의 기본 스크롤바를 숨기지 않습니다. 보이는 시점과 모양은 브라우저와 운영체제를 따르며, CoUI의 스크롤바 스타일은 적용되지 않습니다. |

스크롤 위치를 보여 주고 싶을 때 켭니다. 다만 Flutter에서는 가만히 있는 동안 막대가 보이지 않으므로, 아래에 내용이 더 있다는 표시를 막대에만 맡기지 마세요.

<Preview demo="fade-scroll/scrollbar" />

```dart
FadeScroll(
  showScrollbar: true,
  child: content,
)
```

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

보이는 영역 너머에 내용이 더 있다는 것을 가장자리에서 보여 줄 때 씁니다.

- 가로로 넘치는 칩 · 카드 줄
- 높이를 정한 목록이나 패널
- 대화상자나 서랍의 긴 본문

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 페이드 없이 CoUI 스크롤바를 둔 스크롤 영역 | [ScrollArea](/components/scroll-area) |
| 스크롤바의 표시 방식이나 축을 직접 정할 때 | [Scrollbar](/components/scrollbar) |
| 넘친 글을 자동으로 흘려 보여 줄 때 | [OverflowMarquee](/components/overflow-marquee) |
| 두 축을 함께 스크롤하며 위치를 받아 그릴 때 | [ScrollableClient](/components/scrollable-client) |
| 칩을 고르는 가로 줄 | [ChipGroup](/components/chip-group)의 `scroll` 배치 |
| 항목이 많아 필요한 만큼만 만들어야 하는 목록 | Flutter의 `ListView.builder`처럼 스스로 스크롤하는 목록. `FadeScroll`은 자식 전체를 한 번에 만듭니다. |

<a id="dont"></a>

### 키보드로도 끝까지 볼 수 있게

`FadeScroll`은 스크롤 영역을 초점 대상으로 만들지 않습니다. 키보드로 읽어야 하는 내용이라면 링크 · 버튼 · 입력처럼 초점을 받는 항목이 함께 있는지 확인하세요. 그런 항목을 둘 수 없다면 Flutter에서는 `controller`를 넘기고, 초점과 키 입력을 앱에서 받아 위치를 옮기세요. Web은 안쪽 스크롤 상자에 속성을 붙일 수 없습니다.

<Cards columns="2">
<Card demo="fade-scroll/do-focusable" tone="do" eyebrow="이렇게 하세요" title="초점을 받는 항목 담기">

항목이 초점을 받으므로 키보드를 쓰는 사람의 초점이 이 영역 안으로 들어올 수 있습니다.

</Card>
<Card demo="fade-scroll/dont-text-only" tone="dont" eyebrow="이렇게 하지 마세요" title="긴 글만 담기">

안에 초점을 받는 항목이 없습니다. Flutter에서는 키보드로 이 영역을 스크롤할 수 없습니다.

</Card>
</Cards>

### 상자에 맞는 페이드 길이

페이드 구간의 내용은 읽기 어렵습니다. 스크롤 축의 길이에 견줘 짧게 두고, 앞뒤를 더한 값이 그 길이를 넘지 않게 합니다.

<Cards columns="2">
<Card demo="fade-scroll/do-short-fade" tone="do" eyebrow="이렇게 하세요" title="짧은 페이드">

높이 120인 상자에 24를 주면 대부분의 줄이 선명하게 남습니다.

</Card>
<Card demo="fade-scroll/dont-long-fade" tone="dont" eyebrow="이렇게 하지 마세요" title="상자보다 과한 페이드">

같은 상자에 56을 주면 처음 화면부터 아래쪽 절반 가까이가 흐립니다. 중간 위치에서는 선명한 곳이 가운데 8만 남습니다.

</Card>
</Cards>

## 배치

스크롤 축의 길이가 정해진 곳에 두어야 내용이 넘치고, 넘쳐야 스크롤과 페이드가 생깁니다.

| 상황 | Flutter | Web |
| --- | --- | --- |
| 세로 | `SizedBox`나 `Expanded`로 높이를 정합니다. 높이 제한이 없으면 내용만큼 커집니다. 부모가 폭을 강제하지 않으면 폭은 내용을 따릅니다. | 바깥 상자가 부모를 채우므로 부모에 높이를 정합니다. 높이가 없으면 내용만큼 커집니다. 폭은 부모의 폭을 채웁니다. |
| 가로 | 폭이 정해진 곳에 둡니다. 부모가 높이를 강제하지 않으면 높이는 내용을 따릅니다. | 자식 줄이 상자보다 넓어야 합니다. flex 줄에는 `width: max-content`를 주어 항목이 줄어들지 않게 합니다. |

`Column` 안에서 남는 높이를 목록에 줄 때는 아래처럼 둡니다. `list`는 화면에서 만든 목록 내용입니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Column(
  children: [
    Text('알림').titleMedium,
    Expanded(
      child: FadeScroll(child: list),
    ),
    Button(onPressed: close, child: Text('닫기')),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(
  styles: Styles(
    raw: {'display': 'flex', 'flex-direction': 'column', 'height': '320px'},
  ),
  [
    Text('알림').titleMedium,
    div(
      styles: Styles(raw: {'flex': '1', 'min-height': '0'}),
      [FadeScroll(child: list)],
    ),
    Button(onPressed: close, child: Text('닫기')),
  ],
)
```

  </TabItem>
</Tabs>

Flutter에서는 자식이 `SingleChildScrollView` 안에 놓여 스크롤 축 방향의 길이 제한이 없습니다. 그래서 다음 제한이 있습니다.

- 스크롤 축 방향으로는 `Expanded`를 쓸 수 없습니다. 예를 들어 세로 `FadeScroll` 바로 안의 `Column`이 그렇습니다.
- 같은 방향으로 스크롤하는 `ListView` · `GridView`를 크기 제한 없이 넣을 수 없습니다.
- 가로 방향은 `IntrinsicHeight`로 내용의 높이를 미리 잽니다. 이 계산을 지원하지 않는 `LayoutBuilder` · `ListView` · `GridView` 같은 위젯은 그대로 담지 마세요.

## 테마와 스타일

겉모습은 `fadeScrollStyle`로 바꿉니다. 타입은 `CoreFadeScrollStyle`이고 필드는 `startOffset` · `endOffset` · `gradient` 셋입니다.

### 값이 정해지는 순서

뒤로 갈수록 우선합니다. 필드마다 따로 합치며, `gradient`는 목록 전체가 바뀝니다.

```text
CoreFadeScrollStyle.defaultStartOffset · defaultEndOffset · defaultGradient
  → CoreComponentTheme.fadeScroll.style   // 앱 전체
  → fadeScrollStyle                       // FadeScroll 하나
```

<Split>

<Code language="dart" title="FadeScroll 하나만 바꾸기">
FadeScroll(
  fadeScrollStyle: const CoreFadeScrollStyle(
    startOffset: CoreSpace.space24,
    endOffset: CoreSpace.space64,
  ),
  child: content,
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: const CoreComponentTheme(
    fadeScroll: CoreFadeScrollTheme(
      style: CoreFadeScrollStyle(endOffset: CoreSpace.space64),
    ),
  ),
)
</Code>

</Split>

앱 전체 값은 `FadeScroll`을 안에서 쓰는 컴포넌트에도 닿을 수 있습니다. Flutter의 [TabPane](/components/tab-pane) 탭 줄은 자기 스타일을 넘기지 않아 이 값을 그대로 받습니다. [ChipGroup](/components/chip-group)의 `scroll` 배치는 페이드 길이를 직접 넘기므로 길이는 이 값을 따르지 않습니다. 앱 전체 `gradient`는 Flutter의 칩 줄에는 적용되지 않고, Web의 칩 줄에는 `CoreChipGroupStyle.fadeColor`를 정하지 않았을 때 적용됩니다.

### gradient

`gradient`는 마스크의 불투명도를 정합니다. 기본값은 `onSurface`에서 투명으로 가는 두 색입니다.

| 목록의 자리 | 쓰이는 곳 |
| --- | --- |
| 첫 색 | 흐려지지 않는 안쪽 |
| 마지막 색 | 흐려지는 가장자리의 맨 끝 |

- 불투명도만 반영됩니다. 색상을 바꿔도 가장자리에 색이 입혀지지 않습니다.
- 첫 색과 마지막 색 사이의 색은 읽지 않습니다.
- 첫 색은 불투명하게 두세요. 반투명하면 페이드가 켜졌을 때 안쪽 내용까지 옅어집니다.
- 빈 목록은 넘기지 마세요. 읽을 색이 없어 오류가 납니다.

아래 값은 가장자리 끝에 내용이 20%만큼 남게 합니다. Web의 첫 화면과 미지원 브라우저에서는 이 값과 상관없이 흐린 가장자리가 완전히 투명해집니다. 다만 미지원 브라우저의 끝 쪽은 끝에 닿으면 20%가 됩니다([플랫폼 차이](#플랫폼-차이)).

```dart
const CoreFadeScrollStyle(
  gradient: [
    CoreColor.token(CoreColors.onSurface),
    CoreColor.token(CoreColors.onSurface, opacity: CoreOpacity.opacity20),
  ],
)
```

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `FadeScroll`에 `withStyle`로 스타일을 덧붙일 수 있습니다. `fadeScrollStyle`에 값을 합친 사본을 돌려주며, 겹치는 필드는 뒤에 붙인 값이 이깁니다. 아래 예제는 앞뒤 페이드 길이를 80으로 늘립니다. `gradient`는 불투명도만 쓰이므로 `primary`를 넣어도 가장자리에 그 색이 나타나지 않습니다.

<Preview component="fade-scroll" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class FadeScrollChainExample extends StatelessWidget {
  const FadeScrollChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CoreSpace.space200,
      child:
          FadeScroll(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 20; i += 1)
                  Padding(
                    padding: const CoreEdgeInsets.symmetric(
                      vertical: CoreSpace.space8,
                      horizontal: CoreSpace.space16,
                    ).toValue(geometry: Theme.of(context).geometry),
                    child: Text('항목 ${i + 1}').bodyMedium.onSurface,
                  ),
              ],
            ),
          ).withStyle(
            const CoreFadeScrollStyle(
              startOffset: CoreSpace.space80,
              endOffset: CoreSpace.space80,
              gradient: [
                CoreColor.token(CoreColors.primary),
                CoreColor.transparent,
              ],
            ),
          ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class FadeScrollChainExample extends StatelessComponent {
  const FadeScrollChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        FadeScroll(
          child: div([
            for (var i = 0; i < 20; i += 1)
              div(
                [Text('항목 ${i + 1}').bodyMedium.onSurface],
                classes: 'py-${CoreSpace.scale.space8} px-${CoreSpace.scale.space16}',
              ),
          ]),
        ).withStyle(
          const CoreFadeScrollStyle(
            startOffset: CoreSpace.space80,
            endOffset: CoreSpace.space80,
            gradient: [
              CoreColor.token(CoreColors.primary),
              CoreColor.transparent,
            ],
          ),
        ),
      ],
      classes: 'inline-flex',
      styles: Styles(raw: {'height': '${CoreSpace.space200}px'}),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="접근성-accessibility"></a>

## 접근성

`FadeScroll`은 내용을 담는 틀입니다. 영역의 이름이나 "내용이 더 있다"는 안내를 스스로 만들지 않습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | `FadeScroll`이 따로 붙이는 `Semantics`는 없습니다. 안의 `SingleChildScrollView`가 Flutter의 기본 스크롤 시맨틱을 만듭니다. |
| Web | 두 겹의 `<div>`이고 `role` · `aria-*`를 붙이지 않습니다. 막대를 숨길 때는 `<style>` 하나가 더 들어갑니다. |

#### 스크롤바를 켠 Flutter

`showScrollbar: true`면 CoUI `Scrollbar`가 slider 시맨틱 노드를 하나 더합니다. 이름은 없고, 값은 스크롤 위치의 백분율입니다. 넘치는 내용이면 늘리기 · 줄이기 동작으로 스크롤할 수 있는 거리의 10%씩 움직이며, 처음과 끝에서는 갈 수 있는 쪽의 동작만 있습니다.

#### 영역에 이름 주기

영역을 찾고 구분해야 한다면 이름을 직접 줍니다. `content`는 화면에서 만든 내용입니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Semantics(
  container: true,
  label: '알림 목록',
  child: FadeScroll(child: content),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
// 바깥 <div> 에 붙습니다
FadeScroll(
  attributes: const {'role': 'region', 'aria-label': '알림 목록'},
  child: content,
)
```

  </TabItem>
</Tabs>

### 키보드

| 플랫폼 | 동작 |
| --- | --- |
| Flutter | `FadeScroll`이 처리하는 키는 없습니다. Flutter의 스크롤 단축키는 초점이 있는 위젯을 감싼 스크롤 영역에 작용하므로, 이 영역은 초점이 안의 위젯에 있을 때 단축키를 받습니다. |
| Web | 키 처리기를 스스로 등록하지 않습니다. `onKeyDown` · `onKeyUp`을 넘기면 바깥 `<div>`에 붙습니다. 키로 스크롤하는 방법은 브라우저를 따릅니다. |

Flutter의 기본 단축키를 바꾸지 않았다면, 초점이 안에 있을 때 스크롤 축에 맞는 아래 키가 스크롤합니다. 초점을 받은 위젯이 같은 키를 스스로 쓰면 다를 수 있습니다.

| 빌드 · 축 | 스크롤하는 키 |
| --- | --- |
| 네이티브 · 세로 | `PageUp` · `PageDown`, `Ctrl` + 위 · 아래 화살표 |
| 네이티브 · 가로 | `Ctrl` + 왼쪽 · 오른쪽 화살표 |
| Flutter 웹 · 세로 | `PageUp` · `PageDown`, 위 · 아래 화살표 |
| Flutter 웹 · 가로 | 왼쪽 · 오른쪽 화살표 |

iOS와 macOS의 네이티브 빌드는 `Ctrl` 대신 `Command`를 씁니다. 네이티브 빌드에서 화살표만 누르면 스크롤 대신 초점 이동을 시도합니다.

### 스크린 리더

페이드는 겉모습만 바꾸는 마스크라 글이나 이름, 알림을 만들지 않습니다. `FadeScroll`에는 "내용이 더 있다"고 알리는 글이나 라이브 영역이 없습니다. 그 정보가 필요하면 항목 수처럼 읽을 수 있는 글로 함께 적으세요. 자식 내용에는 `FadeScroll`이 붙이는 이름이 없습니다.

### 포커스 관리

`FadeScroll`은 초점을 받거나 옮기거나 가두지 않고, 포커스 링도 그리지 않습니다. Flutter에서는 `FocusNode` · `Focus`를 두지 않고, Web에서는 `tabindex`를 스스로 붙이지 않습니다. Flutter의 기본 초점 이동은 Tab으로 옮겨 간 위젯이 보이도록 스크롤합니다.

### 알려진 제약

#### 두 플랫폼 공통

- 막대를 숨긴 기본 상태에서 `FadeScroll`이 주는 넘침 표시는 페이드뿐이고, 눈으로만 알 수 있습니다.
- 마스크는 안의 모든 것에 걸립니다. 페이드 구간에 놓인 항목은 초점을 받아도 포커스 링과 함께 흐려집니다.
- 스크롤 영역을 초점 대상으로 만들지 않습니다. Flutter에서는 안에 초점을 받는 위젯이 없으면 키보드로 스크롤할 수 없습니다.
- 가로 페이드는 왼쪽을 시작, 오른쪽을 끝으로 정해 그립니다. 오른쪽에서 왼쪽으로 배치하는 화면(RTL)에서는 스크롤이 오른쪽에서 시작해 흐려지는 쪽이 맞지 않습니다.

#### Flutter

- 첫 화면 뒤에 내용이나 영역의 크기만 바뀌면 페이드를 다시 계산하지 않습니다. 예를 들어 목록이 늦게 도착해 넘치게 되어도, 스크롤하거나 `FadeScroll`이 한 번 더 빌드되기 전까지 페이드가 없을 수 있습니다. 목록이 바뀔 때 `FadeScroll`의 `key`를 함께 바꾸면 처음부터 다시 계산합니다. 이때 `FadeScroll`이 만든 스크롤 위치와 자식의 상태는 처음으로 돌아갑니다.
- 페이드가 하나도 없는 화면과 하나라도 있는 화면을 오갈 때 스크롤 뷰와 그 아래를 새로 만듭니다. 넘치는 내용은 첫 프레임 직후에 한 번 이 전환을 거칩니다. 그때 `GlobalKey`가 없는 자식의 State는 한 번 버려지고 다시 만들어져 `initState`가 다시 실행됩니다. 그 뒤에도 전환이 일어나면 입력 중인 글이나 펼침 여부처럼 자식이 스스로 가진 상태가 처음으로 돌아갈 수 있습니다. 지켜야 하는 상태는 `FadeScroll` 바깥의 State나 컨트롤러에 두세요.
- 실행 중에 `direction`이나 `showScrollbar`를 바꿔도 그 아래를 새로 만듭니다. 스크롤 위치는 보통 처음으로 돌아가는데, 페이드는 바꾸기 전 위치로 계산되어 다음에 스크롤하거나 다시 빌드될 때까지 어긋날 수 있습니다. 두 값을 바꿀 때는 `key`도 함께 바꾸세요.
- `showScrollbar: true`의 slider 노드에는 이름이 없습니다.

#### Web

- `ScrollTimeline` 미지원 브라우저에서는 기본 `gradient`의 끝 쪽 페이드가 끝까지 스크롤해도, 내용이 다 들어가도 남습니다. 마지막 항목이 선명해야 하면 내용 끝에 `endOffset`만큼 여백을 두세요.
- 미지원 브라우저에서는 내용만 바뀌면 다음에 스크롤하거나 스크롤 상자의 크기가 바뀔 때까지 페이드가 갱신되지 않습니다.
- 미지원 브라우저에서는 실행 중에 `FadeScroll`이 다시 빌드되면, 중간 위치여도 첫 화면의 모양(시작 쪽 선명, 끝 쪽 흐림)으로 돌아갑니다. 다음에 스크롤하거나 스크롤 상자의 크기가 바뀌면 위치에 맞춰집니다.
- 브라우저에서 컴포넌트가 실행되기 전에는 내용이 다 들어가도 끝 쪽 페이드를 그립니다. `ScrollTimeline` 지원 브라우저는 실행된 뒤 이 페이드를 없앱니다. 서버에서만 그리는 화면에서는 그대로 남습니다.
- `id` · `classes` · `attributes`와 이벤트는 바깥 `<div>`에 붙습니다. 실제로 스크롤하는 안쪽 `<div>`에 속성을 붙이는 방법은 없습니다.

전역으로 적용되는 항목(감소된 모션 · 고대비 · 강제 색상 등)은 [전역 접근성 축](/accessibility)을 참고하세요. 페이드를 켜고 끄는 데에는 애니메이션이 없습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

클래스 이름과 공통 속성은 같고, 스크롤과 마스크는 각 플랫폼의 방식을 씁니다.

- 스크롤: Flutter는 `SingleChildScrollView`와 `ScrollController`를, Web은 넘치면 스크롤하는 안쪽 `<div>`를 씁니다.
- 마스크: Flutter는 `ShaderMask`와 `LinearGradient`(`BlendMode.dstIn`)로, Web은 CSS `mask-image: linear-gradient(...)`로 그립니다.

| 항목 | Flutter | Web |
| --- | --- | --- |
| 첫 화면 | 첫 프레임에는 페이드가 없고 직후에 계산합니다. | 실행 전에는 시작 쪽은 선명하고 끝 쪽은 흐립니다. |
| 끝 판정 | 처음이나 끝의 위치에서 벗어났는지를 여유 없이 봅니다. | `ScrollTimeline` 지원은 여유가 없고, 미지원은 1px의 여유를 둡니다. |
| 마지막 색 | 가장자리 맨 끝의 불투명도 | `ScrollTimeline` 지원은 같습니다. 실행 전과 미지원 브라우저의 흐린 가장자리는 마지막 색과 상관없이 완전히 투명해집니다. 미지원 브라우저의 끝 쪽은 끝에 닿으면 마지막 색의 불투명도가 됩니다. |
| 페이드 길이 | `theme.scaling`을 곱합니다. | 적은 값을 CSS px로 씁니다. |
| 두 길이의 합이 상자보다 길 때 | 시작 쪽이 선명하면, 상자보다 짧은 `endOffset`은 그 길이대로 흐립니다. | 끝 쪽 페이드가 `startOffset` 지점보다 앞에서 시작하지 않아 더 짧아집니다. |
| 켠 스크롤바 | CoUI `Scrollbar` | 브라우저 기본 스크롤바 |
| 숨긴 스크롤바 | 안쪽 위젯의 `ScrollBehavior`를 바꿉니다(표 다음 설명 참고). | 이 스크롤 상자의 막대만 CSS로 숨깁니다. |
| 다른 축 | 부모의 크기 제약을 자식에게 전합니다. | 넘치는 부분을 잘라 냅니다. |
| 전용 속성 | `controller` | `id` · `classes` · `css` · `attributes`와 DOM 이벤트 |

<Note>

Flutter에서 `showScrollbar: false`(기본값)는 `FadeScroll` 아래의 스크롤 설정을, 스크롤바만 뺀 Flutter 기본 `ScrollBehavior`로 바꿉니다. 그래서 `CoUIApp(scrollBehavior:)`처럼 앱에 정한 스크롤 설정이 이 영역과 그 안의 다른 스크롤 뷰에는 적용되지 않습니다. `CoUIApp`의 기본 설정은 모든 플랫폼에서 끝이 튕기지만, 이 안에서는 Android · Windows · Linux 등에서 끝에 멈춥니다. `true`면 앱의 설정을 이어받고 자동 스크롤바만 끕니다.

</Note>

<a id="props-parameters"></a>

## API

`W`는 Flutter의 `Widget`, Web의 Jaspr `Component`입니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `W` | 필수 | 스크롤할 내용 |
| `direction` | `CoreFadeScrollDirection` | `CoreFadeScrollDirection.vertical` | 스크롤 축. `vertical` 또는 `horizontal` |
| `showScrollbar` | `bool` | `false` | 스크롤바를 보일지 |
| `fadeScrollStyle` | `CoreFadeScrollStyle?` | `null` | 페이드 길이와 마스크의 불투명도 |

### Flutter 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `controller` | `ScrollController?` | `null` | 비우면 `FadeScroll`이 만들고 해제합니다. 넘긴 컨트롤러는 해제하지 않으므로 만든 쪽에서 해제합니다. |

### Web 전용

모두 바깥 `<div>`에 적용됩니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | HTML `id` |
| `classes` | `String?` | `null` | 기본 클래스 뒤에 덧붙이는 CSS 클래스 |
| `css` | `Styles?` | `null` | 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | HTML 속성 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 이름으로 지정하는 DOM 이벤트 |
| `onClick` · `onMouseEnter` · `onMouseLeave` | `UiMouseEventHandler?` | `null` | 마우스 이벤트 |
| `onKeyDown` · `onKeyUp` | `UiKeyboardEventHandler?` | `null` | 키보드 이벤트 |
| `onInput` · `onChange` | `UiInputEventHandler?` | `null` | 입력 이벤트 |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreFadeScrollStyle patch)` | `fadeScrollStyle`에 `patch`를 합친 사본을 돌려줍니다. |
| `copyWith({direction, showScrollbar, ...})` | 넘긴 값만 바꾼 사본을 돌려줍니다. `null`을 넘기면 지금 값이 남습니다. |

### 테마와 기본값

| 이름 | 타입 | 값 |
| --- | --- | --- |
| `CoreComponentTheme.fadeScroll` | `CoreFadeScrollTheme?` | `style: CoreFadeScrollStyle?` 하나를 가집니다. |
| `CoreFadeScrollStyle.defaultStartOffset` | `double` | 40 |
| `CoreFadeScrollStyle.defaultEndOffset` | `double` | 40 |
| `CoreFadeScrollStyle.defaultGradient` | `List<CoreColor>` | `onSurface` 토큰, 투명 |
| `CoreFadeScrollDirection.defaultDirection` | `CoreFadeScrollDirection` | `vertical` |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreFadeScrollStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `startOffset` | `double?` | Pixel offset from the start edge over which the fade ramps up. |
| `endOffset` | `double?` | Pixel offset from the end edge over which the fade ramps down. |
| `gradient` | `List<CoreColor>?` | Optional gradient color stops applied to the fade. The list is interpolated from the visible edge inward. |

<!-- STYLE_TABLE:END -->

<Note>

표의 `gradient` 설명과 지금 동작은 다릅니다. 목록 전체를 이어 그리지 않고 첫 색과 마지막 색의 불투명도만 씁니다. 첫 색이 흐려지지 않는 안쪽, 마지막 색이 가장자리의 맨 끝입니다. Web의 예외는 [플랫폼 차이](#플랫폼-차이)를 보세요.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="fade-scroll/related-scroll-area" title="ScrollArea">

페이드 없이 CoUI 스크롤바를 두는 스크롤 영역입니다.

</Card>
<Card demo="fade-scroll/related-chip-group" title="ChipGroup">

`scroll` 배치의 칩 줄을 `FadeScroll`로 그립니다.

</Card>
</Cards>

넘친 글을 자동으로 흘려 보여 줄 때는 [OverflowMarquee](/components/overflow-marquee)를, 두 축을 함께 스크롤하며 위치를 받아 그릴 때는 [ScrollableClient](/components/scrollable-client)를 보세요.
