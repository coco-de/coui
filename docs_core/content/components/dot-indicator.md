---
title: DotIndicator
description: 캐러셀이나 온보딩에서 전체 가운데 지금 몇 번째인지를 점으로 보여 줍니다. 누를 수 있게 만들면 점이나 화살표 키로 위치를 옮깁니다.
category: display
platforms: [flutter, web]
related: [carousel, pagination, steps, progress]
tags: [navigation, pagination, visual-indicator]
template: v2
source: display/dot_indicator
---

# DotIndicator

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 점 표시를 확인하고, 만들어진 코드를 그대로 복사하세요. 점 표시는 선택을 기억하지 않습니다. `onChanged` 로 받은 번호를 상태에 담아 `index` 로 다시 넘겨야 현재 점이 옮겨 갑니다. 세로로 놓는 모습은 [방향](#방향)에서 봅니다.

<Playground component="dot-indicator" />

## 구조

점 표시는 바깥 상자 하나와 `length` 개의 점으로 이루어집니다. `index` 번 점(0부터 셉니다)이 현재 점입니다.

<Anatomy demo="dot-indicator/anatomy">
<AnatomyItem part="container" name="Container">

점을 한 줄이나 한 열로 놓는 상자입니다. 둘레 여백은 `padding`(기본 8)이고, 배경과 테두리는 칠하지 않습니다.

</AnatomyItem>
<AnatomyItem select="[aria-current] > div" side="top" name="Active dot">

`index` 번 점입니다. 기본은 `onSurface` 로 채운 원이고, `activeLength` 로 놓이는 방향의 길이를 늘릴 수 있습니다.

</AnatomyItem>
<AnatomyItem select="[role=tab]:last-child > div" side="right" name="Inactive dot">

나머지 점입니다. 기본은 `outlineVariant` 로 채운 원이고 테두리 폭은 0 입니다.

</AnatomyItem>
</Anatomy>

<a id="크기별-기본값-coredotindicatorstyledefaultsbysize"></a>

## 크기

`size`(`CoreDotIndicatorSize`)는 점 지름과 점 사이 간격을 함께 고릅니다. 둘레 여백의 기본값 8 은 크기와 무관합니다.

<Preview demo="dot-indicator/sizes" />

| size | 점 지름 `dotSize` | 점 사이 `spacing` |
| --- | --- | --- |
| `sm` | 6 | 6 |
| `md` (기본) | 8 | 8 |
| `lg` | 12 | 12 |

```dart
DotIndicator(
  index: currentPage,
  length: 4,
  size: CoreDotIndicatorSize.lg,
)
```

- 이 값은 `CoreDotIndicatorStyle.defaultsBySize` 에 있습니다.
- `CoreDotIndicatorTheme` 이나 `dotIndicatorStyle` 에 `dotSize` · `spacing` 을 주면 크기별 값 대신 그 값을 씁니다. 예를 들어 테마에 `dotSize` 를 주면 `size` 를 바꿔도 점 지름은 그대로입니다.
- Flutter 는 크기별 기본값과 `padding` 에 테마의 `scaling` 을 곱합니다. 직접 준 `dotSize` · `spacing` · `activeLength` 에는 곱하지 않고, `padding` 은 직접 줘도 곱합니다. Web 은 점 크기를 `rem` 으로 정해 브라우저의 글자 크기를 따릅니다.

<a id="변형-variants"></a>
<a id="기본형-가로"></a>
<a id="세로형"></a>

## 방향

`direction`(`CoreAxis`)은 점을 놓는 축입니다. 기본인 `horizontal` 은 가로로, `vertical` 은 위에서 아래로 놓습니다. 화살표 키도 같은 축을 따릅니다.

<Preview demo="dot-indicator/directions" />

```dart
// 가로 (기본)
DotIndicator(index: 1, length: 4)
```

```dart
// 세로
DotIndicator(
  index: 1,
  length: 4,
  direction: CoreAxis.vertical,
)
```

Flutter와 Web 코드가 같습니다.

## 현재 점 모양

기본 모습은 현재 점과 나머지 점이 모두 채운 원이고 색만 다릅니다. 모양까지 다르게 하려면 `dotIndicatorStyle` 의 아래 필드를 씁니다.

<Preview demo="dot-indicator/active-shape" />

- `activeLength` — 놓이는 방향으로 잰 현재 점의 길이입니다. 가로 방향에서는 너비, 세로 방향에서는 높이입니다. 생략하면 적용된 `dotSize` 와 같아 원이고, 더 크게 주면 기본 모서리에서 알약 모양이 됩니다.
- `inactiveColor` · `inactiveBorderColor` · `inactiveBorderWidth` — 나머지 점을 링으로 바꿉니다. `inactiveColor: CoreColor.transparent` 만 주면 테두리 폭이 0 이라 점이 보이지 않으므로 `inactiveBorderWidth` 를 함께 줍니다.
- `borderRadius` — 현재 점과 나머지 점에 함께 적용됩니다. 기본은 `CoreRadius.radius9999` 입니다.

```dart
// 현재 점을 길게
DotIndicator(
  index: currentPage,
  length: 4,
  dotIndicatorStyle: CoreDotIndicatorStyle(activeLength: CoreSpace.space24),
)
```

```dart
// 나머지 점을 링으로
DotIndicator(
  index: currentPage,
  length: 4,
  dotIndicatorStyle: CoreDotIndicatorStyle(
    inactiveColor: CoreColor.transparent,
    inactiveBorderColor: CoreColor.token(CoreColors.outline),
    inactiveBorderWidth: CoreStrokeWidth.stroke2,
  ),
)
```

Flutter와 Web 코드가 같습니다.

<a id="클릭-가능형"></a>
<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 상태

`onChanged` 를 주고 `length` 가 1 이상이면 누를 수 있는 점 표시가 됩니다. `onChanged: null` 이면 위치만 보여 주는 표시 전용입니다. 가만히 있을 때의 모습은 두 경우가 같습니다.

<Preview demo="dot-indicator/states" />

이 그림에서는 마우스를 올려 hover 를 볼 수 있습니다. 눌러서 옮기는 동작은 [플레이그라운드](#플레이그라운드)에서 확인하세요.

| 항목 | 동작 |
| --- | --- |
| 선택 | `index` 번 점이 현재 점입니다. 부모가 `index` 를 바꿔야 옮겨 갑니다. 페이지 내용도 점 표시가 바꾸지 않습니다. |
| 누르기 | 누른 점의 번호로 `onChanged` 를 부릅니다. 현재 점을 눌러도 그 번호로 부릅니다. |
| 화살표 키 | 놓인 축의 화살표가 이전 · 다음 번호로 `onChanged` 를 부릅니다. 양 끝에서는 반대쪽으로 돌아가지 않습니다. |
| Hover | 누를 수 있는 점 표시의 나머지 점이 1.1배로 커집니다. 현재 점은 그대로입니다. 테두리 폭이 있으면 선 색도 `hoverBorderColor` 로 바뀝니다. hover 가 켜지는 범위와 Web 의 선 색 예외는 [플랫폼 차이](#플랫폼-차이)에 있습니다. |
| 키보드 포커스 | 현재 점 둘레에 포커스 링을 그립니다. |
| 표시 전용 | hover 확대, 키보드 조작, 포커스 링이 없습니다. |
| 범위 밖 `index` | 현재 점이 없습니다. 값을 검사하지 않으므로 0 이상 `length - 1` 이하의 번호를 넘기세요. |
| `length: 0` | 점이 없고 접근성 정보에서도 빠집니다. Flutter 는 크기가 0 이고, Web 은 둘레 여백만 남습니다. |

### 애니메이션

전환 시간은 `transitionDuration`(기본 200ms, `CoreDuration.normal`)입니다. 어느 변화에 쓰이는지는 플랫폼마다 다릅니다.

| 변화 | Flutter | Jaspr Web |
| --- | --- | --- |
| 선택 이동 | 전환 없이 바로 바뀜 | 색과 길이가 전환됨 |
| hover 확대 | `AnimatedScale` 전환 | CSS 전환 |
| 점의 크기 · 색 값 변경 | 선택이 그대로면 `AnimatedContainer` 전환 | CSS 전환 |
| 동작 줄이기 | 500ms 이하의 전환 시간을 0 으로 | 전환 시간이 그대로 |

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 캐러셀이나 `PageView` 에서 지금 몇 번째 장인지 보여 줄 때
- 온보딩 화면에서 전체 단계 가운데 지금 위치를 알려 줄 때
- 적은 수의 장을 점을 눌러 바로 옮겨 가게 할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 슬라이드를 넘기는 상자까지 필요할 때 (점이 함께 들어 있습니다) | [Carousel](/components/carousel) |
| 완료 · 진행 중 · 대기처럼 단계마다 상태가 있을 때 | [Steps](/components/steps) |
| 진행한 정도를 막대로 보여 줄 때 | [Progress](/components/progress) |
| 페이지 번호를 보고 골라 이동할 때 | [Pagination](/components/pagination) |

<a id="do"></a>
<a id="dont"></a>

### 점 개수와 모양

<Cards columns="2">
<Card demo="dot-indicator/do-few" tone="do" eyebrow="이렇게 하세요">

점은 적게 둡니다. 5개 이하를 권장합니다. 그래야 지금 위치가 한눈에 읽힙니다.

</Card>
<Card demo="dot-indicator/dont-many" tone="dont" eyebrow="이렇게 하지 마세요">

점을 15개씩 늘어놓으면 몇 번째인지 세어야 압니다. 장이 많으면 Pagination 을 검토하세요.

</Card>
<Card demo="dot-indicator/do-shape" tone="do" eyebrow="이렇게 하세요">

색 차이를 알아보기 어려운 사람도 고를 수 있게, `activeLength` 나 링으로 현재 점의 모양을 다르게 합니다.

</Card>
<Card demo="dot-indicator/dont-tiny" tone="dont" eyebrow="이렇게 하지 마세요">

누르는 점을 작게 줄이지 않습니다. 이 예(점 4 · 간격 4 · 여백 0)는 가운데 점의 누름 영역(가로 × 세로)이 Flutter 8 × 4, Web 8 × 24 입니다.

</Card>
</Cards>

## 배치

### 자리와 정렬

Flutter 의 점 표시는 점과 여백만큼의 크기라 `Center` 나 `Align` 으로 자리를 잡습니다. Web 의 바깥 상자는 블록 flex 상자라 블록 부모 안에서는 폭을 다 채우고, 가로 방향의 점은 글이 시작하는 쪽에 붙습니다. 가운데에 두려면 부모를 가운데 정렬하거나 `classes: 'justify-center'` 를 줍니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Center(
  child: DotIndicator(index: currentPage, length: 4),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
DotIndicator(
  index: currentPage,
  length: 4,
  classes: 'justify-center',
)
```

  </TabItem>
</Tabs>

### 좁은 너비

두 플랫폼 모두 점을 줄바꿈하거나 스크롤하지 않습니다. Flutter 는 부모가 필요한 길이보다 좁으면 점 칸마다 같은 길이를 상한으로 두어, 바깥 여백까지 든 양 끝 점부터 눌립니다. 자리가 좁은 화면에서는 `length` 가 들어가는지 확인하세요.

### 슬라이드 위에 겹칠 때

기본 점 색은 `onSurface` 와 `outlineVariant` 라, 사진이나 색이 있는 면 위에서는 잘 안 보일 수 있습니다. 뒤 배경에 맞춰 `activeColor` · `inactiveColor` 를 주고, 포커스 링과 점 사이의 틈도 칠하려면 `focusOutlineStyle` 에 `offsetColor: CoreFocusRing.opaqueOffsetColor` 를 줍니다. [Carousel](/components/carousel) 의 `slide` variant 는 겹친 점에 이 틈 색을 줍니다.

### 페이지와 연동

페이지가 바뀌면 `index` 를 맞추고, 점을 누르면 페이지를 옮깁니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Column(
  children: [
    Expanded(
      child: PageView(
        controller: pageController,
        onPageChanged: (next) => setState(() => currentPage = next),
        children: pages,
      ),
    ),
    DotIndicator(
      index: currentPage,
      length: pages.length,
      onChanged: (next) => pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: CoreDuration.moderate),
        curve: Curves.easeInOut,
      ),
    ),
    const Gap.space24(),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div([
  pages[currentPage],
  DotIndicator(
    index: currentPage,
    length: pages.length,
    onChanged: (next) => setState(() => currentPage = next),
    classes: 'justify-center',
  ),
])
```

  </TabItem>
</Tabs>

### 조합 예제

Carousel 은 점을 스스로 그리므로 보통은 따로 놓지 않습니다. 점을 직접 놓으려면 `showIndicators: false` 로 끄고 DotIndicator 를 잇습니다. 밖에서 장을 옮기는 방법은 플랫폼마다 다릅니다. Flutter 는 `CarouselController` 를 쓰고, Web 은 `currentIndex` 를 바꿉니다. 이어 쓸 때 조심할 점은 Carousel 문서에 있습니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
// State 의 필드
final controller = CarouselController();
int currentPage = 0;

// build 안
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Carousel(
      controller: controller,
      transition: CoreCarouselTransition.sliding(),
      showIndicators: false,
      onIndexChanged: (next) => setState(() => currentPage = next % slides.length),
      items: slides,
    ),
    DotIndicator(
      index: currentPage,
      length: slides.length,
      onChanged: (next) => controller.animateTo(
        next.toDouble(),
        const Duration(milliseconds: CoreDuration.moderate),
        Curves.easeInOut,
      ),
    ),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
// State 의 필드
int currentPage = 0;

// build 안
div([
  Carousel(
    currentIndex: currentPage,
    showIndicators: false,
    onIndexChanged: (next) => setState(() => currentPage = next % slides.length),
    items: slides,
  ),
  DotIndicator(
    index: currentPage,
    length: slides.length,
    onChanged: (next) => setState(() => currentPage = next),
    classes: 'justify-center',
  ),
])
```

  </TabItem>
</Tabs>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

겉모습과 크기를 세밀하게 바꾸는 값은 `dotIndicatorStyle`(`CoreDotIndicatorStyle`) 하나에 담습니다. 무엇을 보여 줄지와 동작은 위젯 파라미터 `index` · `length` · `onChanged` · `direction` · `size` 로 정합니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreDotIndicatorStyle 의 기본값 · defaultsBySize[size]   // 디자인 시스템 기본값
  → CoreDotIndicatorTheme.style                        // 프로젝트 공통
  → dotIndicatorStyle                                  // 인스턴스별
```

- 필드마다 합쳐지고 뒤의 값이 이깁니다. `focusOutlineStyle` 도 안쪽 필드마다 합쳐집니다.
- `size` 는 위젯에서만 고르며 테마에는 그 자리가 없습니다. 다만 테마의 `dotSize` · `spacing` 은 크기별 기본값보다 우선합니다.
- Carousel 은 자기 점 색을 늘 `dotIndicatorStyle` 로 넘깁니다. 그래서 `CoreDotIndicatorTheme` 의 `activeColor` · `inactiveColor` 는 캐러셀의 점에 보이지 않습니다.

### 기본값

| 필드 | 기본값 |
| --- | --- |
| `dotSize` · `spacing` | [크기](#크기) 표의 값 |
| `activeLength` | 적용된 `dotSize` |
| `padding` | 네 방향 `CoreSpace.space8` |
| `borderRadius` | `CoreRadius.radius9999` |
| `activeColor` | `onSurface` |
| `inactiveColor` | `outlineVariant` |
| `inactiveBorderColor` | `outlineVariant` |
| `inactiveBorderWidth` | 0 |
| `hoverBorderColor` | `primary` |
| `transitionDuration` | 200ms |

### 사용 예

<Split>

<Code language="dart" title="점 표시 하나만 바꾸기">
DotIndicator(
  index: currentPage,
  length: 4,
  dotIndicatorStyle: CoreDotIndicatorStyle(
    activeColor: CoreColor.token(CoreColors.primary),
    inactiveColor: CoreColor.token(CoreColors.surfaceContainerHigh),
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderColor: CoreColor.token(CoreColors.primary),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    dotIndicator: CoreDotIndicatorTheme(
      style: CoreDotIndicatorStyle(
        activeColor: CoreColor.token(CoreColors.primary),
        activeLength: CoreSpace.space24,
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `DotIndicator` 에 `withStyle` 을 이어 `dotIndicatorStyle` 에 값을 덧붙일 수 있습니다. 지금 스타일 위에 합쳐지고, 나중에 이은 값이 같은 필드에서 이깁니다. `.radius4` 처럼 `CoreRadius` 상수와 이름이 같은 getter 는 `borderRadius` 를 그 값으로 둡니다. 아래 예는 점 지름이 16 이라 `.radius16` 을 준 점도 원으로 보입니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class DotIndicatorChainExample extends StatefulWidget {
  const DotIndicatorChainExample({super.key});

  @override
  State<DotIndicatorChainExample> createState() => _DotIndicatorChainExampleState();
}

class _DotIndicatorChainExampleState extends State<DotIndicatorChainExample> {
  int _index = 2;

  @override
  Widget build(BuildContext context) {
    return DotIndicator(
          index: _index,
          length: 5,
          onChanged: (v) => setState(() => _index = v),
        )
        .withStyle(
          const CoreDotIndicatorStyle(
            activeColor: CoreColor.token(CoreColors.tertiary),
            dotSize: CoreSpace.space16,
            spacing: CoreSpace.space12,
          ),
        )
        .radius16;
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class DotIndicatorChainExample extends StatefulComponent {
  const DotIndicatorChainExample({super.key});

  @override
  State<DotIndicatorChainExample> createState() => _DotIndicatorChainExampleState();
}

class _DotIndicatorChainExampleState extends State<DotIndicatorChainExample> {
  int _index = 2;

  @override
  Component build(BuildContext context) {
    return DotIndicator(
          index: _index,
          length: 5,
          onChanged: (v) => setState(() => _index = v),
        )
        .withStyle(
          const CoreDotIndicatorStyle(
            activeColor: CoreColor.token(CoreColors.tertiary),
            dotSize: CoreSpace.space16,
            spacing: CoreSpace.space12,
          ),
        )
        .radius16;
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="접근성-accessibility"></a>

## 접근성

누를 수 있는 점 표시는 전체가 탭 정지 하나이고 점마다 번호가 든 이름을 가집니다. 표시 전용은 전체 가운데 지금 위치를 이름 하나로 전달합니다.

### 역할

| 대상 | Flutter | Jaspr Web |
| --- | --- | --- |
| 그룹 | 이름을 가진 `Semantics` 컨테이너. 따로 정한 role 은 없습니다. | `role="tablist"` + `aria-label`, `tabindex="0"` |
| 점 | 이름, 버튼, 선택 여부(`selected`)를 합친 노드 하나 | `role="tab"` + `aria-label`, `tabindex="-1"`. 현재 점에 `aria-current="true"` |
| 표시 전용 | 위치 이름을 가진 노드 하나. 점은 따로 드러나지 않고 버튼이나 누르기 동작이 없습니다. | 바깥 상자에 `role="group"` + 위치 이름, 점은 `aria-hidden="true"` |
| 점 0개 | 접근성 트리에서 제외 | `role="group"` + `aria-hidden="true"`, 이름 없음 |

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` | 누를 수 있는 점 표시는 전체가 탭 정지 하나입니다. 점 하나하나와 표시 전용은 탭 순서에 들지 않습니다. |
| `→` · `←` | 가로 방향에서 다음 · 이전 번호로 `onChanged` 를 부릅니다. |
| `↓` · `↑` | 세로 방향에서 다음 · 이전 번호로 `onChanged` 를 부릅니다. |
| `Enter` · `Space` | 점 표시가 처리하지 않습니다. 화살표를 누르면 바로 `onChanged` 가 불립니다. |
| `Home` · `End` | 점 표시가 처리하지 않습니다. |

첫 점과 마지막 점에서 바깥쪽 화살표를 누르면 `onChanged` 를 부르지 않습니다. 선택은 부모가 `index` 를 바꿔야 옮겨 갑니다.

### 스크린 리더

이름은 CoUI 로컬라이제이션 문구에서 오며, 두 플랫폼의 문구가 같습니다.

| 대상 | 문구 | 영어 · 한국어 |
| --- | --- | --- |
| 그룹 | `dotIndicatorLabel` | Page navigation · 페이지 탐색 |
| 점 | `dotIndicatorGoToItem` | Go to item 2 · 2번 항목으로 이동 |
| 표시 전용 | `dotIndicatorPosition` | Item 2 of 5 · 전체 5개 항목 중 2번째 |

- 선택 여부는 Flutter 는 `selected` 로, Web 은 `aria-current="true"` 로 전달합니다.
- 선택이 바뀐 것을 따로 알리는 live region 은 없습니다. Web 은 `aria-activedescendant` 도 두지 않고, 화살표로 옮기는 동안 포커스는 그룹에 남습니다. 바뀐 내용을 알려야 하면 앱의 페이지 내용 쪽에서 알리세요.

### 포커스 관리

| 항목 | 동작 |
| --- | --- |
| 처음 | 화면에 나타날 때 포커스를 옮기지 않습니다. |
| 탭 정지 | 누를 수 있을 때 그룹 하나입니다. 점은 Flutter 는 `ExcludeFocus`, Web 은 `tabindex="-1"` 로 탭 순서에서 빠집니다. |
| 점을 누를 때 | Web 은 점이 받은 포커스를 `focusin` 에서 그룹으로 옮겨 화살표 키가 이어집니다. Flutter 는 점을 눌러도 그룹에 포커스를 주지 않습니다. 화살표 키는 그룹이 포커스를 가진 동안에만 듣습니다. |
| 포커스 링 | 현재 점 둘레에만, 키보드 포커스를 보여 줄 때 그립니다(Flutter 는 `FocusableActionDetector` 의 포커스 강조, Web 은 그룹의 `:focus-visible`). 현재 점이 없으면 링도 없습니다. Web 의 색 강제 모드에서는 `CoUIWeb` 의 공통 규칙이 점의 링을 끄고 그룹 둘레에 시스템 포커스 링을 그립니다. |
| 가두기 | 없습니다. `Tab` 은 그룹 밖으로 나갑니다. |

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 점이 무엇을 가리키는지는 번호로만 전달됩니다. 이름을 인스턴스마다 바꾸는 파라미터가 없어, 바꾸려면 로컬라이제이션 클래스의 문구를 바꿔야 합니다. |
| 공통 | 표시 전용 점 위에서도 누를 수 있는 것처럼 클릭 커서가 나타나고, 누르는 동안 누름 효과가 걸립니다. 눌러도 일어나는 일은 없습니다. |
| 공통 | 가로 방향의 화살표는 글 방향을 따르지 않습니다. 오른쪽에서 왼쪽(RTL)으로 놓이면 점의 순서가 뒤집히는데 `→` 는 여전히 다음 번호라, 화면에서는 왼쪽 점으로 옮겨 갑니다. |
| Flutter | 포커스 링이 보이는 상태에서 `onChanged` 를 `null` 로 바꾸면, 표시 전용이 된 뒤에도 현재 점의 링이 남습니다. |
| Jaspr Web | `role="tablist"` · `role="tab"` 을 쓰지만 `aria-selected` · `aria-controls` · `aria-orientation` 은 붙이지 않습니다. 세로 방향도 방향 정보를 따로 알리지 않습니다. |
| Jaspr Web | 바깥 상자의 `role`, 점이 있을 때의 `aria-label`, 누를 수 있을 때의 `tabindex` 는 `attributes` 로 덮을 수 없습니다. |
| Jaspr Web | 그룹에 포커스가 있으면 `Alt` · `Ctrl` · `⌘` 와 함께 누른 축 방향 화살표도 받습니다. `preventDefault` 를 부르고 선택을 옮겨, 그 조합에 걸린 브라우저 단축키를 가로챌 수 있습니다. |
| Jaspr Web | 동작 줄이기를 켜도 점의 전환 시간이 줄지 않습니다. |
| 공통 | `sm` · `md` 는 놓이는 방향의 누름 영역이 끝 점까지 모두 24 보다 좁습니다(가운데 점은 12 · 16). Flutter 의 `sm` 은 두께도 22 입니다. 아래 표를 보세요. |

#### 누름 영역

이웃한 점은 사이 간격을 반씩 나눠 가집니다. 아래는 기본 스타일을 가로 방향으로 놓았을 때의 값(가로 × 세로, 논리 px)입니다. Flutter 는 `scaling` 이 1, Web 은 브라우저 글자 크기가 16px 일 때입니다. 세로 방향에서는 두 값이 서로 바뀝니다.

| size | Flutter 가운데 · 끝 | Web 가운데 · 끝 |
| --- | --- | --- |
| `sm` | 12 × 22 · 17 × 22 | 12 × 24 · 18 × 24 |
| `md` | 16 × 24 · 20 × 24 | 16 × 24 · 20 × 24 |
| `lg` | 24 × 28 · 26 × 28 | 24 × 24 · 24 × 24 |

Flutter 의 누름 영역은 점에 둘레 여백과 간격의 몫을 더한 칸이라, `padding` 을 줄이면 함께 줄어듭니다.

#### 색에 기대는 구분

기본 모습은 현재 점과 나머지 점이 둘 다 채운 원이라 색으로만 구별합니다. `activeLength` 나 링을 주면 모양으로도 구별됩니다([현재 점 모양](#현재-점-모양)).

동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타겟처럼 여러 컴포넌트에 걸리는 기준은 [전역 접근성 축](/accessibility)에 있습니다. 점 표시가 그 기준과 다른 곳은 위 표에 적었습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 생성자 | `const` 로 만들 수 있음 | `const` 생성자가 아님 |
| 선택 이동 | 전환 없이 바로 바뀜 | `transitionDuration` 동안 전환 |
| 동작 줄이기 | 500ms 이하의 전환 시간을 0 으로 | 점의 전환 시간이 그대로 |
| 누른 뒤 포커스 | 그룹에 주지 않음 | 점이 받은 포커스를 그룹으로 옮김 |
| hover 가 켜지는 범위 | 그려진 점 위 | 점 둘레의 [누름 영역](#누름-영역)까지 |
| 보조 키 + 화살표 | 반응하지 않음 | 축 방향 화살표면 반응함 |
| 바깥 상자 폭 | 점에 맞춤 | 블록 부모 안에서 폭을 채움 |
| 누름 영역 두께 | 둘레 여백 + 점 (기본 22 · 24 · 28) | 기본 크기 모두 24 |
| 크기 배율 | 테마의 `scaling` | `rem` (브라우저 글자 크기) |
| 포커스 링 | `FocusOutline` 의 원 · 알약 링. 모서리는 `circleBorderRadius` 를 읽고, `CoreFocusOutlineTheme` 도 적용됨 | 점의 CSS `outline`. `focusOutlineStyle` 의 `align` · `borderWidth` · `borderColor` · `offsetColor` · `ringOpacity` 를 읽고, `CoreFocusOutlineTheme` 은 적용되지 않음 |
| hover 선 색 | 테두리 폭이 있으면 `inactiveBorderColor` 를 줘도 `hoverBorderColor` 로 바뀜 | `inactiveBorderColor` 를 주면 인라인 스타일이 앞서 바뀌지 않음 |
| 점 0개 | 크기 0 | 둘레 여백이 남음 |
| 접근성 표현 | 이름 · 버튼 · `selected` | `tablist` · `tab` · `aria-current` · `group` |
| 전환 구현 | `AnimatedContainer` · `AnimatedScale` | CSS transition |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="props-parameters"></a>

## API

아래 위젯 속성은 두 플랫폼이 같습니다.

### 위젯

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `index` | `int` | 필수 | 현재 점의 번호. 0부터 셉니다. |
| `length` | `int` | 필수 | 점 개수 |
| `onChanged` | `CoreDotIndicatorOnChanged?` | `null` | `void Function(int index)`. 주면 누를 수 있게 됩니다. |
| `direction` | `CoreAxis` | `CoreAxis.horizontal` | 점을 놓는 축 |
| `size` | `CoreDotIndicatorSize` | `CoreDotIndicatorSize.md` | 점 지름과 간격 — `sm` · `md` · `lg` |
| `dotIndicatorStyle` | `CoreDotIndicatorStyle?` | `null` | 겉모습과 크기 덮어쓰기 |

두 플랫폼 모두 `key` 를 받습니다. `copyWith` 와 `withStyle` 도 있습니다.

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `attributes` | `Map<String, String>?` | `null` | 바깥 상자의 HTML 속성. 컴포넌트가 정하는 `role` · `aria-label` · `tabindex` 는 [알려진 제약](#알려진-제약)을 보세요. |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 바깥 상자의 이벤트. 누를 수 있을 때는 `keydown` · `focusin` 이 컴포넌트의 처리로 바뀌어 불리지 않습니다. |
| `id` · `classes` · `css` | `String?` · `String?` · `Styles?` | `null` | 바깥 상자의 id, 덧붙일 클래스, 인라인 스타일 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreDotIndicatorStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `spacing` | `double?` | Spacing between individual dots (logical px). `null` defers to [defaultsBySize] for the active `CoreDotIndicatorSize`. |
| `padding` | `CoreEdgeInsets?` | Uniform padding around the dot indicator container. |
| `dotSize` | `double?` | Dot size override (logical px). `null` defers to [defaultsBySize] for the active `CoreDotIndicatorSize`. |
| `activeLength` | `double?` | Active indicator length along the layout axis, in logical pixels. When omitted, it uses the [dotSize] in effect and stays circular. |
| `borderRadius` | `CoreBorderRadius?` | Dot border radius override. |
| `activeColor` | `CoreColor?` | Active dot colour override. |
| `inactiveColor` | `CoreColor?` | Inactive dot fill override. Defaults to [defaultInactiveColor] — a solid `outlineVariant` disc. `CoreColor.transparent` restores a ring (fill absent, [inactiveBorderColor] alone). |
| `inactiveBorderColor` | `CoreColor?` | Inactive dot border colour override. |
| `inactiveBorderWidth` | `double?` | Inactive dot border width override (logical px). |
| `hoverBorderColor` | `CoreColor?` | Hover border colour override for clickable inactive dots. `null` defers to [defaultHoverBorderColor]. Only reaches the screen when a border width is stated — see [defaultInactiveBorderWidth]. |
| `transitionDuration` | `Duration?` | Transition duration override for active / hover state changes. `null` defers to [defaultTransitionDuration]. |
| `focusOutlineStyle` | `CoreFocusOutlineStyle?` | Focus ring drawn around the selected dot while the indicator group has keyboard focus (like a radio group, the group is one tab stop and arrow keys move the selection). Passed on as is; fields left unset take the focus ring's own defaults. |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 설명에 더해 지금 동작은 이렇습니다.

- `padding` 은 설명의 `Uniform` 과 달리 네 변의 값이 서로 달라도 됩니다(`CoreEdgeInsets.only` 등). 다만 `CoreEdgeInsets.directional` 을 주면 두 플랫폼 모두 그릴 때 `ArgumentError` 가 납니다.
- `inactiveColor: CoreColor.transparent` 만으로는 링이 되지 않습니다. `inactiveBorderWidth` 의 기본값이 0 이라 폭을 함께 줘야 선이 보입니다.
- `transitionDuration` 은 Flutter 에서 선택이 옮겨 가는 순간에는 쓰이지 않습니다.
- `hoverBorderColor` 는 Web 에서 `inactiveBorderColor` 를 함께 주면 보이지 않습니다.
- `focusOutlineStyle` 에서 읽는 필드는 플랫폼마다 다릅니다([플랫폼 차이](#플랫폼-차이)).

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="dot-indicator/related-carousel" title="Carousel">

슬라이드를 넘기는 상자입니다. 장이 여럿이면 DotIndicator 로 점을 함께 그립니다. [Carousel 문서](/components/carousel)

</Card>
<Card demo="dot-indicator/related-pagination" title="Pagination">

페이지 번호를 눌러 이동합니다. [Pagination 문서](/components/pagination)

</Card>
<Card demo="dot-indicator/related-steps" title="Steps">

단계마다 완료 · 진행 중 · 대기 같은 상태를 보여 줍니다. [Steps 문서](/components/steps)

</Card>
<Card demo="dot-indicator/related-progress" title="Progress">

진행한 정도를 막대로 보여 줍니다. [Progress 문서](/components/progress)

</Card>
</Cards>
