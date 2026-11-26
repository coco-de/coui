---
title: Hover
description: 호버 상태를 추적하고 호버 시각 효과를 적용하는 래퍼 컴포넌트
category: control
platforms: [flutter, web]
related: [hover-card, tooltip, swap]
tags: [hover, effect, interaction, state]
template: v2
source: control/hover
---

# Hover

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

`effect`를 고르고 카드에 포인터를 올려 보세요. **onHover 값 보기**를 켜면 카드의 글자가 `onHover`가 알려 준 값을 보여 줍니다. 만들어진 코드는 두 플랫폼에서 그대로 쓸 수 있습니다.

<Playground component="hover" />

`Hover`는 자식(`child`)을 감싸 두 가지를 합니다. 포인터가 위에 있는 동안 시각 효과(`effect`)를 주고, 올라온 상태를 `onHover` · `onEnter` · `onExit`로 알려 줍니다. 효과는 포인터가 들어오는 즉시 켜지고, `onHover(true)`는 기본 설정에서 0.5초(`waitDuration`)를 머문 뒤에 옵니다. 마우스처럼 위에 올려 둘 수 있는 포인터를 위한 것이라, 키보드 포커스로는 아무 일도 일어나지 않습니다. 누르기(클릭)에 반응하는 효과는 따로 없습니다.

<Note>

`brighten`은 색 값에 배수를 곱해 밝게 하므로 흰 면에서는 차이가 보이지 않습니다. 그래서 `brighten`을 고르면 카드를 `primaryContainer`로 채웁니다. `shadow`를 고르면 카드가 자기 그림자를 겹쳐 그리지 않도록 `boxShadow: CoreShadow.none`을 줍니다. 두 값은 만들어진 코드에도 들어갑니다. 코드의 `setHovered`는 `onHover`가 준 값을 `hovered`에 담고 화면을 다시 그리는 앱의 함수입니다.

</Note>

## 효과

`effect`(`CoreHoverEffect`)는 포인터가 올라가 있는 동안 무엇을 바꿀지 정합니다. 기본값은 `none`입니다. 효과는 그려지는 모습만 바꾸고 둘레의 배치는 바꾸지 않습니다. 전환은 두 플랫폼 모두 `effectDuration`(기본 200ms)과 `CoreEasing.move` 곡선을 씁니다. Flutter의 `brighten`만 전환 없이 바로 바뀝니다([플랫폼 차이](#플랫폼-차이)).

| `effect` | 포인터가 올라가 있는 동안 | 값을 바꾸는 필드 (기본값) |
| --- | --- | --- |
| `none` | 모양은 그대로 두고 상태만 알립니다 | — |
| `scaleUp` | 가운데를 기준으로 키웁니다 | `scaleUpFactor` (1.05) |
| `scaleDown` | 가운데를 기준으로 줄입니다 | `scaleDownFactor` (0.95) |
| `fade` | 불투명도를 낮춥니다 | `fadeOpacity` (0.8) |
| `brighten` | 빨강 · 초록 · 파랑 값에 배수를 곱해 밝게 합니다. 흰색에 가까운 면에서는 차이가 거의 보이지 않습니다 | `brightenFactor` (1.1) |
| `shadow` | `child`가 그려진 모양을 따라 그림자를 드리웁니다 | `shadowBoxShadow` (`CoreShadow.lg`) · `shadowBaseColor` (`shadow` 토큰) |

### 그림자 효과

- 기본값처럼 안쪽(`inset`) 레이어가 없는 그림자는 감싼 상자가 아니라 `child`의 모양을 따릅니다. 모서리가 둥근 `Card`라면 그림자도 둥급니다.
- 기본값 `CoreShadow.lg`는 아래로 16, 번짐 40, `shadow` 색 12.5%인 한 겹입니다. 다크 테마에서는 불투명도에 4를 곱해(최대 1) 더 진하게 그립니다.
- `child`가 이미 그림자를 그리고 있으면 두 그림자가 겹쳐 쉬는 상태와 크게 달라 보입니다. `cardStyle`로 `elevation`이나 `boxShadow`를 준 `Card`가 그렇고, 그림자 없는 카드에도 그림자를 더하는 서페이스 스타일(`neoBrutalism` 같은) 아래에서도 그렇습니다. 카드는 `cardStyle: CoreCardStyle(boxShadow: CoreShadow.none)`으로 자기 그림자를 끕니다. 이미지나 아바타처럼 그림자가 없는 `child`를 써도 됩니다.

<a id="동작-스펙-behavior"></a>

## 상태

`Hover`는 두 가지를 따로 다룹니다. 효과는 포인터의 위치를 바로 따르고, `onHover`는 정한 시간을 기다린 뒤에 상태를 알립니다. 두 값을 같은 순간의 신호로 보지 마세요.

| 시점 | 일어나는 일 |
| --- | --- |
| 포인터가 들어옴 | `onEnter`를 바로 부르고 효과를 켭니다 |
| 들어온 채 `waitDuration`(기본 500ms)이 지남 | `onHover(true)` |
| 포인터가 나감 | `onExit`를 바로 부르고 효과를 끕니다 |
| 나간 뒤 `showDuration`(기본 200ms)이 지남 | `onHover(false)`. `true`를 알린 뒤 아직 `false`를 알리지 않았을 때만 부릅니다 |

- `true`를 알린 상태가 아닐 때 `waitDuration`이 지나기 전에 나가면 `onHover`는 `true`도 `false`도 부르지 않습니다.
- `minDuration`(기본 0)은 **포인터가 들어온 때**부터 잽니다. 나갈 때 들어온 지 `minDuration`이 지나지 않았으면 `showDuration` 대신 남은 시간 뒤에 `onHover(false)`를 부릅니다. 남은 시간이 `showDuration`보다 짧아도 `showDuration`을 더하지 않습니다. 예를 들어 `waitDuration` 500ms · `minDuration` 1초라면, 0.6초에 나가도 `onHover(false)`는 들어온 지 1초에 와서 `true`인 시간은 0.5초입니다.
- `onHover(false)`를 기다리는 동안 다시 들어오면 그 `false`는 취소되고, 계속 머무르면 `waitDuration` 뒤에 `onHover(true)`를 한 번 더 부릅니다. 그래서 `false` 없이 `true`가 두 번 이어질 수 있으니, 콜백은 같은 값을 다시 받아도 문제가 없게 만드세요. `waitDuration`이 지나기 전에 다시 나가면 두 번째 `true`는 오지 않고, 나간 뒤에 `false`가 옵니다.
- `Hover`가 화면에서 사라지면 기다리던 `onHover` 호출은 취소됩니다. `onHover(true)`를 받은 뒤에 사라지면 `onHover(false)`도 `onExit`도 오지 않을 수 있으니, 앱이 상태를 스스로 정리하세요.

```dart
Hover(
  waitDuration: Duration(milliseconds: CoreDuration.moderate),
  onEnter: prefetchDetail,
  onHover: (hovered) => setHighlighted(hovered),
  child: Card(
    variant: CoreCardVariant.outlined,
    child: Text('상세 보기'),
  ),
)
```

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

`Hover`는 그 자체로는 누르는 대상이 아닌 콘텐츠에 포인터 반응을 더할 때 씁니다.

- 카드나 이미지에 포인터를 올리면 커지거나 흐려지거나 그림자가 생기는 반응을 줄 때
- 포인터가 들어오고 나가는 것을 앱 코드가 알아야 할 때(미리 불러오기, 연결된 항목 강조)

위에 올려 둘 수 있는 포인터가 없으면 반응을 보지 못할 수 있으므로, 꼭 필요한 정보나 행동은 호버에만 두지 않습니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 포인터를 올리면 정보를 담은 카드를 띄울 때 | [HoverCard](/components/hover-card) |
| 짧은 도움말 한 줄을 띄울 때 | [Tooltip](/components/tooltip) |
| 눌러서 쓰는 카드에 호버 반응을 줄 때 | `onTap`을 준 [Card](/components/card) — 호버 그림자를 스스로 그립니다 |
| 클릭 · 포커스 · 키보드까지 필요한 영역을 직접 만들 때 | [Clickable](/components/clickable) |
| 상태에 따라 두 콘텐츠를 바꿔 보여 줄 때 | [Swap](/components/swap) |

<a id="do"></a>
<a id="dont"></a>

### 효과와 콜백 나누기

바로 보여야 하는 시각 반응은 `effect`에 맡기고, 잠깐 지나가는 포인터에는 반응하지 않아야 하는 일은 `onHover`에 둡니다. `Button`처럼 호버와 포커스 표시를 이미 가진 컨트롤에는 `Hover`를 덧씌워 중요한 피드백을 맡기지 않습니다.

<Split>

<Code language="dart" title="이렇게 하세요">
// 효과는 바로, 미리 보기는 머문 뒤에
Hover(
  effect: CoreHoverEffect.shadow,
  onHover: (hovered) => setPreview(hovered),
  child: Card(
    cardStyle: CoreCardStyle(
      boxShadow: CoreShadow.none,
    ),
    child: Text('요약'),
  ),
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 키보드로 온 사용자에게는
// 이 반응이 나타나지 않습니다.
Hover(
  effect: CoreHoverEffect.scaleUp,
  child: Button(
    onPressed: submit,
    child: Text('제출'),
  ),
)
</Code>

</Split>

## 테마와 스타일

효과의 배율 · 불투명도 · 그림자 · 전환 시간은 `hoverStyle`(`CoreHoverStyle`) 하나로 바꿉니다. 어떤 효과를 쓸지(`effect`)와 콜백은 위젯 파라미터라 스타일이나 테마로 바꿀 수 없습니다. `onHover`의 타이밍 세 값은 위젯 파라미터(`waitDuration` · `showDuration` · `minDuration`), `hoverStyle`, 테마로 줄 수 있습니다. 다만 Web은 `hoverStyle`의 타이밍을 읽지 않으니, 두 플랫폼에서 같게 하려면 위젯 파라미터나 테마를 씁니다.

<Split>

<Code language="dart" title="하나만 바꾸기">
Hover(
  effect: CoreHoverEffect.scaleUp,
  hoverStyle: CoreHoverStyle(
    scaleUpFactor: 1.02,
    effectDuration: Duration(
      milliseconds: CoreDuration.fast,
    ),
  ),
  child: Card(child: Text('요약')),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    hover: CoreHoverTheme(
      style: CoreHoverStyle(
        fadeOpacity: CoreOpacity.opacity60,
        waitDuration: Duration(
          milliseconds: CoreDuration.moderate,
        ),
      ),
    ),
  ),
)
</Code>

</Split>

### 빠른 오버라이드 (Chain)

이미 만든 `Hover`에는 `withStyle`을 이어 써서 스타일을 덧붙일 수 있습니다. 생성자의 `hoverStyle`에 주는 것과 같고, 여러 번 이으면 겹치는 값은 뒤의 것이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class HoverChainExample extends StatelessWidget {
  const HoverChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Hover(
      effect: CoreHoverEffect.scaleUp,
      child: Card(child: const Text('올려 보세요')),
    ).withStyle(
      const CoreHoverStyle(
        scaleUpFactor: 1.15,
        effectDuration: Duration(milliseconds: CoreDuration.moderate),
        waitDuration: Duration(milliseconds: CoreDuration.fast),
        shadowBoxShadow: CoreShadow.xl,
        shadowBaseColor: CoreColor.token(CoreColors.primary),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class HoverChainExample extends StatelessComponent {
  const HoverChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Hover(
      effect: CoreHoverEffect.scaleUp,
      child: Card(child: const Text('올려 보세요')),
    ).withStyle(
      const CoreHoverStyle(
        scaleUpFactor: 1.15,
        effectDuration: Duration(milliseconds: CoreDuration.moderate),
        waitDuration: Duration(milliseconds: CoreDuration.fast),
        shadowBoxShadow: CoreShadow.xl,
        shadowBaseColor: CoreColor.token(CoreColors.primary),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<Note>

이 예제의 효과는 `scaleUp`이라 `shadowBoxShadow`와 `shadowBaseColor`는 쓰이지 않습니다. 두 필드는 `effect`가 `shadow`일 때만 닿습니다. `waitDuration`은 `onHover`를 부르기까지의 시간에만 닿고, Web은 `hoverStyle`의 타이밍을 읽지 않습니다.

</Note>

<a id="resolve-chain"></a>

### 값이 정해지는 순서

뒤로 갈수록 우선하고, 필드마다 따로 합쳐집니다.

```text
Flutter — 효과의 값과 타이밍
  CoreHoverStyle 기본값
    → CoreHoverTheme.style                          // 앱 전체
    → waitDuration · showDuration · minDuration     // 타이밍만
    → hoverStyle                                    // 하나만

Jaspr Web — 효과의 값과 전환 시간
  CoreHoverStyle 기본값
    → CoreHoverTheme.style
    → hoverStyle

Jaspr Web — onHover 타이밍
  CoreHoverStyle 기본값
    → CoreHoverTheme.style
    → waitDuration · showDuration · minDuration     // hoverStyle은 읽지 않음
```

<a id="접근성-accessibility"></a>

## 접근성

`Hover`는 포인터 반응만 더하는 래퍼입니다. 보조 기술에 새로 알리는 것이 없고, 읽히는 이름과 역할은 모두 `child`의 것입니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 없습니다. 효과를 감싼 `MouseRegion`만 두고 `Semantics`를 붙이지 않습니다 |
| Jaspr Web | 없습니다. `role`도 `aria-*`도 없는 `<div>`이고, 호출자가 준 `attributes`만 붙습니다 |

이 영역에 이름이나 역할이 필요하면 `child`에서 붙입니다.

### 키보드

처리하는 키가 없습니다. Web은 `onKeyDown` · `onKeyUp`을 받아 바깥 `<div>`에 붙이지만, `attributes`로 직접 주지 않는 한 이 `<div>`에는 `tabindex`가 없어 포커스를 받은 자손에서 올라온 이벤트만 받습니다. Flutter에는 이런 파라미터가 없습니다.

### 스크린 리더

`child`가 말하는 그대로 읽힙니다. 호버 상태가 바뀌는 것을 따로 알리는 라이브 영역은 없습니다. Flutter의 `shadow` 효과는 그림자를 그리려고 `child`의 사본을 함께 그리지만, 사본은 `ExcludeSemantics`로 감싸 접근성 트리에서 뺍니다.

### 포커스 관리

바깥 상자는 포커스를 받지 않고 포커스 링도 그리지 않습니다. 두 플랫폼 모두 포커스를 듣지 않으므로, `child` 안의 요소가 포커스를 받아도 효과가 켜지지 않고 콜백도 오지 않습니다. 포커스에도 같은 반응이 필요하면 앱이 따로 만듭니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 포인터를 위한 컴포넌트입니다. 키보드 포커스로는 효과와 `onHover` · `onEnter` · `onExit`가 나타나지 않습니다. 이 반응으로만 전하는 정보나 행동을 두지 마세요 |
| 공통 | `onHover(false)` 없이 `onHover(true)`가 두 번 이어질 수 있고, `minDuration`은 `onHover(true)`가 온 때가 아니라 포인터가 들어온 때부터 잽니다([상태](#상태)) |
| 공통 | `Hover`가 호버 중에 사라지면 `onHover(false)`가 오지 않을 수 있습니다 |
| Flutter | 마우스와 스타일러스의 호버만 받습니다. 손가락 터치에는 반응하지 않습니다 |
| Flutter | `shadow` 효과는 `child`를 두 벌 이상 그립니다(기본 그림자는 두 벌). 사본은 상태를 따로 가집니다. `child`나 그 안의 위젯에 밖에서 만든 `GlobalKey`를 주면(`Form`의 키처럼) 같은 키가 두 곳에 놓여 오류가 날 수 있습니다. 사본에서는 포커스를 빼지 않아, `child`에 포커스를 받는 컨트롤이 있으면 `Tab`이 그림자로 쓰는 사본에도 멈출 수 있습니다. 그런 `child`에는 다른 효과를 쓰세요 |
| Flutter | 실행 중에 `effect`를 바꾸면 감싸는 위젯의 종류가 달라져(`scaleUp`과 `scaleDown` 사이는 같습니다), `child`가 다시 만들어지며 안의 상태가 초기화될 수 있습니다 |
| Jaspr Web | 효과와 콜백은 브라우저에서 실행되는 컴포넌트에서만 동작합니다. 서버에서만 렌더하고 브라우저에서 깨우지 않으면(`@client` 밖) 포인터를 올려도 아무 일도 없습니다 |
| Jaspr Web | 터치 화면의 브라우저는 탭한 뒤 마우스 이벤트를 대신 보내므로, 탭하면 효과가 켜지고 다른 곳을 탭할 때까지 남을 수 있습니다 |
| Jaspr Web | `scaleDown`은 감싼 상자 자체를 줄이므로, 포인터가 가장자리 바로 안쪽(줄어드는 만큼의 띠, 기본값은 양쪽 2.5%)에서 조금만 움직여도 상자가 포인터 밖으로 줄었다가 돌아오며 효과가 켜졌다 꺼졌다 합니다 |
| Jaspr Web | `onMouseEnter` · `onMouseLeave`와 `eventHandlers`의 `mouseenter` · `mouseleave`는 불리지 않습니다. `onEnter` · `onExit`를 쓰세요 |

#### 동작 줄이기

동작 줄이기를 켜도 효과는 그대로 적용되고, 시간만 줄입니다. 500ms 이하의 시간은 0으로 줄이고 더 긴 값은 그대로 둡니다.

| 시간 | Flutter | Jaspr Web |
| --- | --- | --- |
| 효과 전환(`effectDuration`) | 줄입니다 | 줄입니다 |
| `waitDuration` · `showDuration` · `minDuration` | 줄입니다. 기본값에서는 `onHover`가 거의 바로 옵니다 | 줄이지 않습니다 |

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타깃)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

클래스 이름과 파라미터 이름, 효과의 기본값은 같습니다. 다음은 다르게 동작하는 자리입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 슬롯과 콜백의 타입 | `Widget?`, `VoidCallback?`, `ValueChanged<bool>?` | `Component?`, `void Function()?`, `ValueChanged<bool>?` |
| 감싸는 상자 | `MouseRegion`. 배치에 상자를 더하지 않습니다 | `display: inline-block`인 `<div>` 하나 |
| 호버 감지 | `MouseRegion`의 들어옴 · 나감. 마우스와 스타일러스만 받습니다 | `mouseenter` · `mouseleave` 이벤트. CSS `:hover`가 아니라 브라우저에서 실행되는 코드가 효과를 켭니다 |
| 효과를 그리는 방식 | `AnimatedScale` · `AnimatedOpacity` · `ColorFiltered`, 그림자는 흐린 `child` 사본 | CSS `transform` · `opacity` · `filter`(`brightness` · `drop-shadow`)와 `transition` |
| `brighten`의 전환 | `effectDuration`과 상관없이 바로 바뀝니다 | `effectDuration` 동안 바뀝니다 |
| 확대 · 축소 중의 호버 영역 | 원래 자리 그대로입니다 | 커지거나 줄어든 모양을 따릅니다 |
| 서페이스 스타일의 그림자 모양 | 직접 정한 그림자에도 적용됩니다 | `CoreShadow` 단계를 기본 색으로 쓸 때 적용됩니다. 색이나 레이어를 직접 정하면 적은 모양 그대로 그립니다(다크 테마의 진하기 배수는 곱합니다) |
| 안쪽(`inset`) 그림자 레이어 | 바깥 그림자처럼 그립니다 | 감싼 `<div>`의 `box-shadow`로 그려, `child`에 가려 보이지 않을 수 있습니다 |
| `hoverStyle`의 타이밍 | 위젯 파라미터보다 우선합니다 | `onHover` 타이밍에 쓰지 않습니다 |
| 동작 줄이기 | 효과 전환과 타이밍을 함께 줄입니다 | 효과 전환만 줄입니다 |
| 추가 파라미터 | 없습니다 | `id` · `classes` · `css` · `attributes` · `eventHandlers`와 `onClick` 같은 이벤트 처리기 — 바깥 `<div>`에 붙습니다 |
| `css`로 효과 덮기 | — | `css`로 `transform` · `opacity` · `filter` · `transition`을 주면 효과의 같은 속성을 덮습니다 |

<a id="props-parameters"></a>

## API

아래 파라미터는 Flutter와 Jaspr Web에 모두 있습니다. 타입은 Flutter 기준이고, Web의 슬롯은 `Component`입니다. 모든 파라미터가 선택입니다.

### 위젯 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `Widget?` | `null` | 호버 영역으로 감쌀 콘텐츠. 비우면 Flutter는 빈 `SizedBox`, Web은 빈 `<div>`입니다 |
| `effect` | `CoreHoverEffect` | `CoreHoverEffect.defaultEffect`(`none`) | 포인터가 올라가 있는 동안의 시각 효과 |
| `onHover` | `ValueChanged<bool>?` | `null` | 정한 시간을 기다린 뒤의 호버 상태. [상태](#상태)를 보세요 |
| `onEnter` | `VoidCallback?` | `null` | 포인터가 들어오는 즉시 부릅니다 |
| `onExit` | `VoidCallback?` | `null` | 포인터가 나가는 즉시 부릅니다 |
| `waitDuration` | `Duration?` | `null` | `onHover(true)`까지 기다리는 시간(기본 500ms) |
| `showDuration` | `Duration?` | `null` | 나간 뒤 `onHover(false)`까지의 시간(기본 200ms) |
| `minDuration` | `Duration?` | `null` | 포인터가 들어온 때부터 잰 최소 시간(기본 0) |
| `hoverStyle` | `CoreHoverStyle?` | `null` | 효과의 값 · 전환 시간 · 타이밍 덮어쓰기 |

타이밍 세 값을 비웠을 때 어디서 값을 가져오는지와 우선순위는 플랫폼마다 다릅니다. [값이 정해지는 순서](#값이-정해지는-순서)를 보세요.

Web은 `id` · `classes` · `css` · `attributes` · `eventHandlers`와 `onClick` 같은 이벤트 처리기를 더 받아 바깥 `<div>`에 붙입니다. 다만 `onMouseEnter` · `onMouseLeave`는 받아도 부르지 않으므로 `onEnter` · `onExit`를 씁니다.

두 플랫폼 모두 `copyWith`와 `withStyle(CoreHoverStyle patch)`가 있습니다. 앱 전체 기본값은 `CoreComponentTheme.hover`의 `CoreHoverTheme(style: …)`로 둡니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreHoverStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `scaleUpFactor` | `double?` | Scale factor applied for the `scaleUp` effect override. `null` defers to [defaultScaleUpFactor]. |
| `scaleDownFactor` | `double?` | Scale factor applied for the `scaleDown` effect override. `null` defers to [defaultScaleDownFactor]. |
| `fadeOpacity` | `double?` | Opacity applied for the `fade` effect override. `null` defers to [defaultFadeOpacity]. |
| `brightenFactor` | `double?` | Brightness multiplier applied for the `brighten` effect override. `null` defers to [defaultBrightenFactor]. |
| `shadowBoxShadow` | `List<CoreShadowLayer>?` | Drop-shadow stack applied for the `shadow` effect override. `null` defers to [defaultShadowBoxShadow]. |
| `shadowBaseColor` | `CoreColor?` | Base colour the `shadow` effect's layers are tinted with override. `null` defers to [defaultShadowBaseColor]. |
| `effectDuration` | `Duration?` | Transition duration for the hover visual effect override. `null` defers to [defaultEffectDuration]. |
| `waitDuration` | `Duration?` | Delay before the hover state is reported as active override. `null` defers to [defaultWaitDuration]. |
| `showDuration` | `Duration?` | Delay before the hover state is reported as inactive after the pointer leaves override. `null` defers to [defaultShowDuration]. |
| `minDuration` | `Duration?` | Minimum duration the hover state stays active once reported override. `null` defers to [defaultMinDuration]. |

<!-- STYLE_TABLE:END -->

<Note>

표의 설명과 지금 동작이 다른 곳이 있습니다. Web은 `hoverStyle`의 `waitDuration` · `showDuration` · `minDuration`을 읽지 않고, 같은 필드를 테마(`CoreHoverTheme.style`)에 주면 읽습니다. `minDuration`은 `onHover(true)`를 보낸 때가 아니라 포인터가 들어온 때부터 잽니다. `shadow` 효과는 그림자 레이어의 `spreadRadius`를 쓰지 않습니다. 다만 Web에서 안쪽 레이어가 있는 그림자는 `box-shadow`로 그려 `spreadRadius`도 씁니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="HoverCard" href="/components/hover-card" more="HoverCard 보기">

포인터를 올리면 정보를 담은 카드를 띄웁니다.

</Card>
<Card title="Tooltip" href="/components/tooltip" more="Tooltip 보기">

포인터를 올리면 뜨는 짧은 안내입니다.

</Card>
<Card title="Swap" href="/components/swap" more="Swap 보기">

상태에 따라 두 콘텐츠를 전환 효과와 함께 바꿉니다.

</Card>
</Cards>
