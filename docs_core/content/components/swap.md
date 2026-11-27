---
title: Swap
description: 두 콘텐츠 가운데 하나만 보여 주고 서로 맞바꿉니다. 전환 효과는 교차 페이드 · 회전 · 뒤집기 가운데에서 고릅니다.
category: display
platforms: [flutter, web]
related: [toggle, collapsible, switch-field, switcher]
tags: [swap, toggle, animation, state]
template: v2
source: display/swap
---

# Swap

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

`Swap` 은 같은 자리에 겹쳐 둔 두 콘텐츠 가운데 하나를 보여 줍니다. `checked` 가 `false` 면 `offContent`, `true` 면 `onContent` 입니다. `onToggle` 을 주면 누를 수 있는 토글 버튼이 되고, 주지 않으면 `checked` 를 따라 바뀌기만 하는 표시가 됩니다. 무대의 Swap 을 눌러 전환을 확인하세요.

<Playground component="swap" />

- `켜짐` 은 `checked` 를 정합니다. 무대에서 눌러 바꾼 값은 이 컨트롤에 반영되지 않습니다. `표시 전용` 을 켜면 눌러도 바뀌지 않으니 `켜짐` 으로 바꿉니다.
- 아이콘 면에는 글자가 없어, 누를 수 있을 때는 접근 가능한 이름을 `메뉴` 로 줍니다. Flutter 는 `MergeSemantics` 와 `Semantics` 로 감싸고 Web 은 `attributes` 에 `aria-label` 을 넣어 두 코드가 다릅니다([이름 주기](#아이콘만-넣었다면-이름을-줍니다)).
- `animation` 을 `rotate`, `면 내용` 을 `text` 로 두고 `checked` 상태로 만들면 글자가 거꾸로 보입니다([전환 효과](#전환-효과)).

## 구조

<Preview demo="swap/faces" />

| 부분 | 하는 일 |
| --- | --- |
| `offContent` | `checked: false` 일 때 보이는 면입니다. |
| `onContent` | `checked: true` 일 때 보이는 면입니다. |
| 누르는 상자 | `onToggle` 을 줄 때만 생기며 두 면을 감쌉니다. 커서, 누를 때 줄어드는 반응, 키보드 포커스 링을 맡습니다. |

두 면은 같은 자리의 가운데에 겹쳐 놓입니다. Swap 은 배경 · 테두리 · 안쪽 여백을 그리지 않으므로 겉모습은 면에 넣은 내용이 정합니다.

두 면을 그리는 방법은 플랫폼과 전환 효과에 따라 다릅니다.

| 구성 | 만들어 두는 면 | 면이 가진 상태 |
| --- | --- | --- |
| Jaspr Web (모든 효과) | 둘 다 | 맞바꿔도 남습니다. |
| Flutter `none` · `rotate` | 둘 다 | 맞바꿔도 남습니다. |
| Flutter `flip` | 지금 보이는 면 하나 | 면의 위젯이 가진 상태(입력값 · 스크롤 위치 따위)는 면이 바뀌면 새로 시작합니다. 남겨야 하는 값은 Swap 바깥에 둡니다. |

## 전환 효과

`animation`(`CoreSwapAnimation`)은 면이 바뀌는 모습을 고릅니다. 기본값은 `none` 입니다. 아래는 모두 `checked: true` 에서 멈춘 모습이고, `offContent` 는 `꺼짐`, `onContent` 는 `켜짐` 입니다. 움직임은 [플레이그라운드](#플레이그라운드)에서 눌러 확인합니다.

<VariantRow name="none" component="swap" props="animation=none;checked=true;face=text;interactive=false">

교차 페이드입니다. 한 면은 옅어지고 다른 면은 진해집니다. 이름이 `none` 이어도 바로 바뀌지는 않습니다.

</VariantRow>

<VariantRow name="rotate" component="swap" props="animation=rotate;checked=true;face=text;interactive=false">

두 면을 담은 상자를 180° 돌리면서 교차 페이드합니다. `onContent` 를 따로 되돌려 놓지 않으므로, `checked: true` 인 동안 `onContent` 는 180° 돌아간 모습으로 보입니다.

</VariantRow>

<VariantRow name="flip" component="swap" props="animation=flip;checked=true;face=text;interactive=false">

세로축(Y축)으로 180° 뒤집습니다. 교차 페이드는 없고, 절반을 돌 때 보이는 면이 바뀝니다. `onContent` 는 미리 뒤집어 두어 다 돌면 바로 선 모습입니다.

</VariantRow>

### 시간과 동작 줄이기

- 전환 시간의 기본값은 `CoreDuration.moderate`(300ms), 곡선은 `CoreEasing.move` 입니다. 시간은 `swapStyle` 의 `duration` 으로 바꾸며, 곡선을 바꾸는 속성은 없습니다.
- 처음 그릴 때는 전환 없이 `checked` 의 모습으로 나타납니다.
- 효과 없이 바로 맞바꾸려면 `duration` 에 `Duration.zero` 를 줍니다.
- 동작 줄이기를 켜면 두 플랫폼 모두 500ms 이하의 전환을 바로 바꿉니다. Swap 은 500ms 보다 긴 값은 줄이지 않습니다. 다만 Android 의 애니메이션 삭제 설정에서는 Flutter 프레임워크가 500ms 보다 긴 전환도 정한 시간의 5% 로 돌립니다.

<a id="동작-스펙-behavior"></a>

## 상태

| 상태 | 모습과 동작 |
| --- | --- |
| `checked: false` (기본) | `offContent` 가 보입니다. |
| `checked: true` | `onContent` 가 보입니다. |
| 누를 수 있음 (`onToggle` 있음) | 커서가 누를 수 있는 모양(pointer)이 됩니다. 기본 hover 모양은 없습니다. |
| 누름 | 누르는 상자가 기본값 0.97 배로 줄었다가 돌아옵니다. |
| 키보드 포커스 | 누르는 상자에 포커스 링이 그려집니다. |
| 표시 전용 (`onToggle: null`) | 누름 반응과 포커스가 없습니다. 흐려지지 않습니다. |
| 비활성 | `enabled` 속성과 흐린 비활성 모습이 없습니다. |
| 동작 줄이기 | 위 [시간과 동작 줄이기](#시간과-동작-줄이기)를 따릅니다. |

### 값은 앱이 가집니다

`Swap` 은 `checked` 를 스스로 바꾸지 않습니다. 처음 값만 넘기고 맡기는 방식은 없습니다.

- 누르면 `onToggle` 에 `!checked` 를 넘겨 부를 뿐입니다. 새 `checked` 를 넘겨야 화면이 바뀝니다.
- 받은 값을 반영하지 않으면 보이는 면은 그대로입니다.
- 앱이 코드로 `checked` 를 바꿔도 같은 전환이 일어납니다. 이때 `onToggle` 은 부르지 않습니다.
- `checked` 를 생략하면 `false` 입니다.

```dart
// StatefulWidget(Web 은 StatefulComponent)의 build 안
Swap(
  checked: _muted,
  offContent: Text('소리 켜짐'),
  onContent: Text('음소거'),
  onToggle: (value) => setState(() => _muted = value),
)
```

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 다크 · 라이트 모드 아이콘을 맞바꿀 때
- 음소거와 소리 켜기 아이콘을 맞바꿀 때
- 메뉴 열기와 닫기처럼 두 상태의 전환을 효과로 보여 줄 때
- 밖에서 정해지는 두 상태를 표시만 할 때 (`onToggle` 없이)

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 켜짐 · 꺼짐 트랙이 있는 설정 | [Toggle](/components/toggle) |
| 라벨과 설명이 있는 설정 행 | [SwitchField](/components/switch-field) |
| 여러 뷰를 번호로 옮겨 다닐 때 | [Switcher](/components/switcher) |
| 내용 영역을 접고 펼 때 | [Collapsible](/components/collapsible) |

<a id="do"></a>
<a id="dont"></a>

### 전환 효과와 설정 항목

<Cards columns="2">
<Card demo="swap/do-symmetric-rotate" tone="do" eyebrow="이렇게 하세요">

`rotate` 에는 180° 돌려도 같은 모양인 면을 씁니다. 그림은 `checked: true` 의 닫기 아이콘입니다.

</Card>
<Card demo="swap/dont-rotate-text" tone="dont" eyebrow="이렇게 하지 마세요">

`rotate` 에 글자를 넣지 않습니다. `checked: true` 의 글자가 거꾸로 보입니다. 글자에는 `none` 이나 `flip` 을 씁니다. `flip` 에는 크기가 같은 두 면을 넣습니다([배치](#배치)).

</Card>
<Card demo="swap/do-setting-toggle" tone="do" eyebrow="이렇게 하세요">

켜고 끄는 설정에는 라벨을 단 `Toggle` 을 씁니다. 트랙이 누를 수 있는 설정임을 보여 줍니다.

</Card>
<Card demo="swap/dont-setting-swap" tone="dont" eyebrow="이렇게 하지 마세요">

글자만 넣은 `Swap` 을 설정 항목으로 쓰지 않습니다. `onToggle` 이 있어도 멈춘 모습은 보통 글자와 같습니다.

</Card>
</Cards>

### 누를 수 있게 하려면 `onToggle` 을 줍니다

`onToggle` 이 있는지에 따라 버튼 역할 · 포커스 · 키보드 조작이 함께 정해집니다. 콜백이 없는 `Swap` 은 표시 전용이라 눌러서 바꿀 수 없습니다.

`Swap` 밖의 컨트롤로 값을 바꾸는 화면이라면 `onToggle` 없이 `checked` 만 넘깁니다.

### 아이콘만 넣었다면 이름을 줍니다

`Swap` 에는 라벨 파라미터가 없습니다. 아이콘만 넣으면 접근 가능한 이름이 없으므로 직접 줍니다. 누를 수 있는 Swap 의 이름은 상태가 바뀌어도 같게 둡니다. 켜짐은 눌림 상태가 알려 줍니다.

누를 수 있는 Flutter `Swap` 은 시맨틱 노드가 둘로 나뉩니다. `Semantics(label:)` 로만 감싸면 이름이 누르기 동작과 눌림 상태가 없는 바깥쪽에 붙으므로, 그 바깥을 `MergeSemantics` 로 한 번 더 감싸 하나로 합칩니다.

<Split>

<Code language="dart" title="Flutter">
MergeSemantics(
  child: Semantics(
    label: '다크 모드',
    child: Swap(
      checked: _dark,
      offContent: Icon(LucideIcons.sun),
      onContent: Icon(LucideIcons.moon),
      onToggle: (value) => setState(() => _dark = value),
    ),
  ),
)
</Code>

<Code language="dart" title="Jaspr Web">
Swap(
  checked: _dark,
  offContent: Icon(LucideIcons.sun),
  onContent: Icon(LucideIcons.moon),
  onToggle: (value) => setState(() => _dark = value),
  attributes: {'aria-label': '다크 모드'},
)
</Code>

</Split>

### 누를 수 있는 Swap 의 면에는 조작 요소를 넣지 않습니다

`onToggle` 이 있으면 상자 전체가 버튼 하나입니다. 면 안에 버튼 · 링크 · 입력을 넣으면 버튼 안에 버튼이 겹칩니다. Web 에서는 면 안 버튼의 클릭이 바깥까지 전달되어 `onToggle` 도 함께 불립니다. 두 면이 각자 조작 요소를 가져야 하면 `onToggle` 을 빼고, 면 바깥의 컨트롤로 `checked` 를 바꿉니다.

## 배치

Swap 의 크기는 두 면의 크기에서 나옵니다. 크기를 고르는 파라미터는 없습니다.

| `animation` | Flutter | Jaspr Web |
| --- | --- | --- |
| `none` · `rotate` | 두 면 가운데 더 넓은 너비와 더 높은 높이 | 같습니다. |
| `flip` | 지금 보이는 면의 크기. 두 면의 크기가 다르면 절반을 돌 때 크기가 바뀝니다. | `checked` 와 관계없이 `offContent` 의 크기 |

아래는 `checked: false` 의 모습입니다. `offContent` 는 `끔`, `onContent` 는 `알림 켜짐` 입니다. `none` 은 넓은 면의 자리를 미리 잡고, `flip` 은 `끔` 의 너비만 차지합니다.

<Preview demo="swap/sizing" />

- 작은 면은 상자의 가운데에 놓입니다.
- `none` · `rotate` 에서 누를 수 있는 Swap 은 보이는 면이 더 작아도 상자 전체가 눌립니다.
- Web 의 `flip` 은 `onContent` 를 `offContent` 크기의 상자에 겹쳐 놓습니다. `onContent` 가 더 크면 상자 밖으로 넘치거나 좁은 너비에 맞춰 줄이 바뀝니다. `flip` 에는 크기가 같은 두 면을 넣습니다.
- 누를 수 있는 영역은 상자 크기 그대로이고 최소 크기를 더하지 않습니다. CoUI 앱의 기본 크기(20) 아이콘만 넣으면 전역 [최소 히트 영역](/accessibility#최소-터치-타겟) 24×24 보다 작으므로, 면을 더 크게 만들어 넓힙니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

무엇을 보여 주고 언제 바꿀지는 위젯 파라미터로 넘기고, 전환 시간 · 면의 기본 글자 모양 · 누르는 상자의 반응은 `swapStyle`(`CoreSwapStyle`) 하나로 바꿉니다.

### 파라미터와 스타일

- **위젯 파라미터** — `offContent`, `onContent`, `checked`, `animation`, `onToggle`
- **전환 시간** — `swapStyle` 의 `duration`
- **면의 기본 글자 모양** — `swapStyle` 의 `textStyle`. 기본값은 `bodyMedium` 역할과 `onSurface` 색입니다.
- **누르는 상자** — `swapStyle` 의 `clickableStyle`. `onToggle` 이 있을 때만 쓰입니다. 누를 때의 크기와 시간, 포커스 링을 바꿉니다.

### 값이 정해지는 순서

뒤에 있을수록 우선합니다.

```text
CoreSwapStyle 의 기본값 (defaultDuration · defaultTextStyle · defaultClickableStyle)
  → CoreSwapTheme.style          // 앱 전체
  → swapStyle                    // 인스턴스별
```

`textStyle` 과 `clickableStyle` 은 필드 단위로 합쳐집니다. 색만 바꿔도 기본 글자 역할은 남습니다. `clickableStyle` 에서 아무도 정하지 않은 필드는 누르는 상자(`Clickable`)의 테마와 기본값을 따릅니다.

### 면의 글자와 아이콘 색

`textStyle` 이 면에 넣은 내용에 닿는 범위는 플랫폼마다 다릅니다.

| 면에 넣은 것 | Flutter | Jaspr Web |
| --- | --- | --- |
| 체인 없는 `Text` | `textStyle` 을 따릅니다. | `textStyle` 을 따릅니다. |
| `.labelMedium` 같은 글자 역할 체인을 붙인 `Text` | `bodyMedium` · `onSurface` 에서 다시 시작해 그 위에 역할을 얹습니다. `textStyle` 의 색은 남지 않습니다. | 역할은 체인을 따르고, 색을 정하지 않으면 `textStyle` 의 색을 이어받습니다. |
| 색을 따로 정하지 않은 `Icon` | `textStyle` 의 색이 닿지 않고 주변 아이콘 테마의 색을 씁니다. | 둘레에 아이콘 색을 정한 테마가 없으면 `textStyle` 의 색을 이어받습니다. |

두 플랫폼에서 같은 아이콘 색이 필요하면 `Icon` 의 `iconStyle` 에 색을 줍니다. `textStyle` 의 글자 크기는 `Icon` 의 크기를 바꾸지 않습니다.

### 사용 예

<Split>

<Code language="dart" title="Swap 하나만 바꾸기">
Swap(
  checked: _on,
  offContent: Text('꺼짐'),
  onContent: Text('켜짐'),
  onToggle: (value) => setState(() => _on = value),
  swapStyle: const CoreSwapStyle(
    duration: Duration(milliseconds: CoreDuration.fast),
    textStyle: CoreTextStyle(
      color: CoreColor.token(CoreColors.primary),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    swap: CoreSwapTheme(
      style: CoreSwapStyle(
        duration: Duration(milliseconds: CoreDuration.fast),
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter 와 Web 코드가 같습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

`withStyle` 은 지금의 `swapStyle` 위에 넘긴 값을 합친 새 `Swap` 을 돌려줍니다. 같은 필드는 뒤에 적은 값이 이깁니다. 아래 예제는 전환 시간을 500ms 로 늘리고, 면의 글자 모양과 포커스 링의 모서리를 바꿉니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class SwapChainExample extends StatefulWidget {
  const SwapChainExample({super.key});

  @override
  State<SwapChainExample> createState() => _SwapChainExampleState();
}

class _SwapChainExampleState extends State<SwapChainExample> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Swap(
      checked: _checked,
      onContent: const Text('켜짐'),
      offContent: const Text('꺼짐'),
      onToggle: (v) => setState(() => _checked = v),
    ).withStyle(
      const CoreSwapStyle(
        duration: Duration(milliseconds: CoreDuration.slow),
        textStyle: CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        clickableStyle: CoreClickableStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class SwapChainExample extends StatefulComponent {
  const SwapChainExample({super.key});

  @override
  State<SwapChainExample> createState() => _SwapChainExampleState();
}

class _SwapChainExampleState extends State<SwapChainExample> {
  bool _checked = false;

  @override
  Component build(BuildContext context) {
    return Swap(
      checked: _checked,
      onContent: Text('켜짐'),
      offContent: Text('꺼짐'),
      onToggle: (v) => setState(() => _checked = v),
    ).withStyle(
      const CoreSwapStyle(
        duration: Duration(milliseconds: CoreDuration.slow),
        textStyle: CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        clickableStyle: CoreClickableStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
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

`onToggle` 이 있으면 토글 버튼이 되고, 없으면 `Swap` 은 역할 · 포커스 · 키 처리를 더하지 않습니다.

### 역할

| 구성 | Flutter | Jaspr Web |
| --- | --- | --- |
| `onToggle` 있음 | 버튼 시맨틱을 더하고, 눌림 상태(`toggled`)에 `checked` 를 담습니다. | `role="button"` 과 `aria-pressed="true"` 또는 `"false"` 를 가진 `<div>` 입니다. |
| `onToggle` 없음 | `Swap` 이 더하는 시맨틱이 없습니다. | `role` 과 `tabindex` 가 없는 `<div>` 입니다. |

역할은 `switch` 나 `checkbox` 가 아니라 눌림 상태를 가진 버튼입니다. Web 에서는 `attributes` 에 같은 이름의 속성을 주면 그 값이 우선합니다.

### 키보드

`onToggle` 이 있을 때만 동작합니다.

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift+Tab` | 누르는 상자로 들어오고 나갑니다. |
| `Enter` | `onToggle` 을 부릅니다. |
| `Space` | `onToggle` 을 부릅니다. |

- 두 플랫폼 모두 키를 떼기 전, 누르는 순간에 부릅니다.
- `Enter` 나 `Space` 를 누르고 있으면 키 반복마다 `onToggle` 을 다시 부릅니다.
- Web 은 처리한 키에 `preventDefault()` 를 부릅니다. Web 의 키 처리는 누르는 상자 자체에 포커스가 있을 때만 하며, 안쪽 요소에서 올라온 키 입력은 처리하지 않습니다.
- 방향키와 `Escape` 는 처리하지 않습니다.
- 표시 전용 `Swap` 은 어떤 키도 처리하지 않습니다.

### 스크린 리더

- `Swap` 은 이름을 따로 만들지 않습니다. 이름은 보이는 면의 내용에서 오거나 직접 준 이름에서 옵니다. 이름 없는 아이콘만 넣으면 읽을 이름이 없습니다([이름 주기](#아이콘만-넣었다면-이름을-줍니다)).
- 보이는 면의 글자를 이름으로 쓰면 상태가 바뀔 때 이름도 바뀝니다.
- 표시 전용 `Swap` 의 면은 평범한 콘텐츠로 읽힙니다. 면이 바뀌어도 `Swap` 은 따로 알리지 않습니다. 사용자가 알아야 하는 변화는 앱에서 알립니다.
- Web 의 표시 전용 `Swap` 은 역할이 없는 `<div>` 라 `aria-label` 만으로는 이름이 전달되지 않을 수 있습니다. 아이콘만 있는 표시라면 `attributes` 에 알맞은 `role`(예: `img`)을 함께 줍니다.

#### 숨은 면

보이지 않는 면은 포인터 · 포커스 · 스크린 리더에서 빠집니다. 빠지는 방법과 시점은 다음과 같습니다.

| 구성 | 포인터와 포커스 | 스크린 리더 |
| --- | --- | --- |
| Jaspr Web (모든 효과) | 숨는 면에 `inert` 를 붙입니다. `checked` 가 바뀌는 즉시 적용됩니다. | `inert` 인 면은 접근성 트리에서도 빠집니다. |
| Flutter `none` · `rotate` | `checked` 가 바뀌는 즉시 숨는 면의 포인터 입력과 포커스를 막습니다. | 전환이 끝나면 불투명도가 0 인 면은 시맨틱 트리에서 빠집니다. 전환하는 동안에는 두 면이 모두 트리에 있고, 숨는 면의 동작은 막힙니다. |
| Flutter `flip` | 지금 보이는 면만 있습니다. 절반을 돌기 전까지는 이전 면이 입력과 포커스를 받습니다. | 지금 보이는 면만 트리에 있습니다. |

### 포커스 관리

- `onToggle` 이 있으면 누르는 상자가 포커스를 받습니다. Web 은 `tabindex="0"` 을 붙이고, 포커스 링은 두 플랫폼 모두 키보드로 이동할 때를 위한 표시입니다.
- `Swap` 을 눌러 상태가 바뀌어도 누르는 상자를 새로 만들지 않아 상자의 포커스는 남습니다.
- 숨은 면 안의 요소는 포커스를 받지 않습니다. Flutter `flip` 은 절반을 돌 때 면이 바뀝니다.
- 표시 전용 `Swap` 의 면 안에 포커스가 있을 때 그 면이 숨으면, `Swap` 은 포커스를 새 면으로 옮기지 않습니다. 필요하면 앱에서 옮깁니다.
- 포커스를 가두거나 되돌리지 않습니다.
- 표시 전용 `Swap` 은 스스로 포커스 대상이 되지 않습니다. 보이는 면에 넣은 조작 요소는 그대로 포커스를 받습니다.

### 알려진 제약

- `rotate` 는 `checked: true` 인 동안 `onContent` 가 180° 돌아간 모습입니다.
- Flutter `flip` 은 보이는 면 하나만 만듭니다. 면의 상태가 이어지지 않고, 조작 대상은 `checked` 가 바뀌는 때가 아니라 절반을 돌 때 바뀝니다.
- Web `flip` 의 크기는 `offContent` 만 따릅니다.
- 누를 수 있는 Flutter `Swap` 은 버튼 시맨틱 선언이 두 겹이라 노드가 둘로 나뉩니다. 누르기 · 포커스 동작, 눌림 상태(`toggled`), 보이는 면의 글자는 안쪽 노드에 함께 실리고, 바깥 선언의 버튼 · 활성 상태는 여기에 합쳐지지 않습니다. 바깥에서 `Semantics(label:)` 로만 준 이름도 바깥쪽에 남으므로 `MergeSemantics` 로 합칩니다([이름 주기](#아이콘만-넣었다면-이름을-줍니다)).
- 누를 수 있는 Web `Swap` 은 `onClick` · `onKeyDown` · `onKeyUp` · `onMouseEnter` · `onMouseLeave` 를 부르지 않습니다. `eventHandlers` 의 `click` · `keydown` · `keyup` · `mouseenter` · `mouseleave` · `mousedown` · `mouseup` · `focusout` 항목도 불리지 않습니다. 값의 변화는 `onToggle` 로 받습니다.
- 누를 수 있는 Web `Swap` 은 면 안에 넣은 버튼을 클릭해도 `onToggle` 을 부릅니다.
- 실행 중에 `onToggle` 을 `null` 과 콜백 사이에서 바꾸면 감싸는 구조가 달라져 두 면을 새로 만듭니다. 면이 가진 상태가 이어지지 않습니다.
- 라벨 파라미터와 `enabled` 파라미터가 없습니다.
- 누르는 영역의 최소 크기를 보장하지 않습니다.

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은
> [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`offContent` · `onContent` · `checked` · `animation` · `onToggle` · `swapStyle` 은 두 플랫폼에서 이름과 기본값이 같습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 클래스 이름 | `Swap` | `Swap` |
| 면의 타입 | `Widget` | `Component` |
| 전환을 그리는 방법 | `AnimationController` 와 `Transform`, `Opacity` | CSS `transform` · `opacity` 와 `transition` |
| 누르기 | `Clickable` 의 탭 | 누르는 상자의 `click` 이벤트 |
| 숨은 면 (`none` · `rotate`) | 포인터 · 포커스를 막고 불투명도 0 으로 둡니다. | `inert` |
| `flip` 이 만드는 면 | 보이는 면 하나 | 둘 다 |
| `flip` 의 크기 | 보이는 면 | `offContent` |
| `flip` 의 조작 대상이 바뀌는 때 | 절반을 돌 때 | `checked` 가 바뀌는 즉시 |
| 아이콘 색과 `textStyle` | 닿지 않습니다. | 이어받을 수 있습니다([범위](#면의-글자와-아이콘-색)). |
| 면 안 버튼을 눌렀을 때 (`onToggle` 있음) | 안쪽 버튼이 탭을 가져갑니다. | 안쪽 버튼의 동작과 `onToggle` 이 함께 실행됩니다. |
| 동작 줄이기 신호 | `MediaQuery.disableAnimations` 또는 `AccessibilityFeatures.reduceMotion` | `@media (prefers-reduced-motion: reduce)` |
| HTML 속성과 이벤트 | 없음 | [웹 전용](#웹-전용) 파라미터 |

<a id="props-parameters"></a>

## API

표의 `W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다.

### 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `offContent` | `W` | 필수 | `checked: false` 일 때 보이는 면 |
| `onContent` | `W` | 필수 | `checked: true` 일 때 보이는 면 |
| `checked` | `bool` | `false` | 지금 상태 |
| `animation` | `CoreSwapAnimation` | `CoreSwapAnimation.none` | 전환 효과 — none, rotate, flip |
| `onToggle` | `ValueChanged<bool>?` | `null` | 누르면 `!checked` 를 받는 콜백. `null` 이면 표시 전용입니다. |
| `swapStyle` | `CoreSwapStyle?` | `null` | 이 인스턴스의 전환 시간 · 글자 모양 · 누름 반응 |
| `key` | `Key?` | `null` | 위젯 · 컴포넌트의 키 |

### 웹 전용

아래 값은 가장 바깥 요소에 붙습니다. `onToggle` 이 있으면 누르는 상자, 없으면 Swap 의 `<div>` 입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 바깥 요소의 id |
| `classes` | `String?` | `null` | 바깥 요소에 더하는 클래스 |
| `css` | `Styles?` | `null` | 바깥 요소에 더하는 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 바깥 요소의 HTML 속성. 같은 이름의 컴포넌트 값보다 우선합니다. |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 이벤트 이름별 리스너. 누를 수 있을 때 불리지 않는 이름은 [알려진 제약](#알려진-제약)에 있습니다. |
| `onClick` | `UiMouseEventHandler?` | `null` | 클릭 리스너. 표시 전용일 때만 불립니다. |
| `onKeyDown` | `UiKeyboardEventHandler?` | `null` | keydown 리스너. 표시 전용일 때만 불립니다. |
| `onKeyUp` | `UiKeyboardEventHandler?` | `null` | keyup 리스너. 표시 전용일 때만 불립니다. |
| `onMouseEnter` | `UiMouseEventHandler?` | `null` | mouseenter 리스너. 표시 전용일 때만 불립니다. |
| `onMouseLeave` | `UiMouseEventHandler?` | `null` | mouseleave 리스너. 표시 전용일 때만 불립니다. |
| `onInput` | `UiInputEventHandler?` | `null` | 컴포넌트 공통 파라미터입니다. 지금은 브라우저의 `input` 이벤트가 이 리스너에 전달되지 않습니다. 값의 변화는 `onToggle` 로 받습니다. |
| `onChange` | `UiInputEventHandler?` | `null` | 컴포넌트 공통 파라미터입니다. 지금은 브라우저의 `change` 이벤트가 이 리스너에 전달되지 않습니다. 값의 변화는 `onToggle` 로 받습니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreSwapStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `duration` | `Duration?` | Animation duration override. |
| `textStyle` | `CoreTextStyle?` | Body typography role override applied to the swap slots' children. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `textColor` field removed). |
| `clickableStyle` | `CoreClickableStyle?` | Style for the `Clickable` around the swap when it is interactive (`onToggle != null`) — press scale, durations, focus ring, disabled opacity. Laid over [defaultClickableStyle] and passed to the `Clickable` as is; the `Clickable` fills in the rest. |

<!-- STYLE_TABLE:END -->

<Note>

`clickableStyle` 의 `disabledOpacity` 는 `Swap` 에서 쓰이지 않습니다. 누를 수 있는 `Swap` 은 늘 활성이고, `onToggle` 이 없으면 누르는 상자를 만들지 않습니다. `textStyle` 의 색은 Flutter 의 `Icon` 에 닿지 않습니다([면의 글자와 아이콘 색](#면의-글자와-아이콘-색)).

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="swap/related-toggle" title="Toggle">

트랙과 썸으로 켜짐과 꺼짐을 보여 주는 스위치입니다. 자세한 내용은 [Toggle](/components/toggle) 을 보세요.

</Card>
<Card demo="swap/related-switch-field" title="SwitchField">

라벨 · 설명 · 스위치를 한 행에 묶은 설정 항목입니다. 자세한 내용은 [SwitchField](/components/switch-field) 를 보세요.

</Card>
<Card demo="swap/related-collapsible" title="Collapsible">

제목을 눌러 아래 내용을 접고 폅니다. 자세한 내용은 [Collapsible](/components/collapsible) 을 보세요.

</Card>
<Card demo="swap/related-switcher" title="Switcher">

여러 뷰 가운데 하나를 번호로 골라 밀어 넘깁니다. 자세한 내용은 [Switcher](/components/switcher) 를 보세요.

</Card>
</Cards>
