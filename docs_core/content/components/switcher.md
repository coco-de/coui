---
title: Switcher
description: 슬라이드 전환과 드래그 제스처로 여러 뷰 사이를 오가는 스위처 컴포넌트
category: navigation
platforms: [flutter, web]
related: [tabs, carousel, swiper]
tags: [switcher, view, slide, swipe]
template: v2
source: navigation/switcher
---

# Switcher

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

보일 번호(`index`)와 움직이는 방향, 끌기를 바꿔 보며 전환을 확인하고, 만들어진 코드를 그대로 복사하세요. 끌기를 켠 코드의 `index` 는 상태 변수이고, 시작 번호는 코드 위 주석에 있습니다. 미리보기는 끌어서도 넘길 수 있고, 창 아래의 `index` 가 지금 보이는 번호입니다. 끌어서 바뀐 번호는 컨트롤과 코드에 반영되지 않으며, 컨트롤에서 다른 번호를 고르면 그 뷰로 넘어갑니다.

<Playground component="switcher" />

`Switcher` 는 `items` 가운데 `index`(0부터 셉니다)번째 뷰 하나를 보여 주고, `index` 가 바뀌면 새 뷰를 밀어 넣으며 옅게 겹치는 전환을 재생합니다. 끌어서 넘겨도 `index` 는 저절로 바뀌지 않습니다. `onIndexChanged` 가 알려 주는 번호를 상태에 반영해 다시 넘겨야 화면과 `index` 가 어긋나지 않습니다.

<Note>

Jaspr Web 에서 `direction` 을 `right` · `down` 으로 두면 `index` 1 부터는 빈 창이 보입니다. 오른쪽에서 왼쪽으로 쓰는 문서(`dir="rtl"`)에서는 `right` 대신 `left` 가 그렇게 됩니다. 웹 쪽의 결함이고, 자세한 내용은 [알려진 제약](#알려진-제약)에 있습니다.

</Note>

```dart
Switcher(
  index: index,
  onIndexChanged: (next) => setState(() => index = next),
  items: const [
    Text('페이지 1'),
    Text('페이지 2'),
    Text('페이지 3'),
  ],
)
```

두 플랫폼이 같은 코드를 씁니다. 다만 크기를 정하는 둘레의 코드는 다릅니다([배치](#배치)).

<a id="변형-variants"></a>
<a id="슬라이드-방향"></a>

## 전환 방향

`direction`(`CoreSwitcherDirection`, 기본 `left`)은 **`index` 가 늘 때** 뷰가 움직이는 방향입니다. `index` 가 줄면 같은 축에서 반대로 움직입니다. 끌어서 넘길 때는 이 이름의 방향으로 끌면 다음 뷰가 됩니다.

| `direction` | `index` 가 늘 때 | 다음 뷰로 끄는 방향 |
| --- | --- | --- |
| `left` (기본) | 새 뷰가 오른쪽에서 들어오고, 앞 뷰는 왼쪽으로 나갑니다. | 왼쪽 |
| `right` | 새 뷰가 왼쪽에서 들어오고, 앞 뷰는 오른쪽으로 나갑니다. | 오른쪽 |
| `up` | 새 뷰가 아래에서 들어오고, 앞 뷰는 위로 나갑니다. | 위 |
| `down` | 새 뷰가 위에서 들어오고, 앞 뷰는 아래로 나갑니다. | 아래 |

Flutter 는 네 방향을 모두 이렇게 그립니다. 왼쪽에서 오른쪽으로 쓰는 문서의 Jaspr Web 은 `left` · `up` 만 이렇게 그립니다. 나머지 방향과 오른쪽에서 왼쪽으로 쓰는 문서는 [알려진 제약](#알려진-제약)을 확인하세요.

```dart
Switcher(
  index: index,
  direction: CoreSwitcherDirection.up,
  onIndexChanged: (next) => setState(() => index = next),
  items: views,
)
```

<a id="인터랙션"></a>

## 끌어서 넘기기

`gestureEnabled`(기본 `true`)이면 마우스나 터치로 끌어 이웃한 뷰 사이를 훑을 수 있습니다. 두 플랫폼이 아래처럼 동작합니다.

| 순간 | 동작 |
| --- | --- |
| 끄는 동안 | 전환 시간 없이 포인터를 따라갑니다. 끈 거리를 창의 폭(`left` · `right`)이나 높이(`up` · `down`)로 나눈 만큼 번호가 움직이고, 두 뷰의 진하기도 그만큼 바뀝니다. 한 번에 여러 칸을 지날 수도 있습니다. |
| 양 끝 | 첫 뷰와 마지막 뷰에서 멈춥니다. 처음으로 돌아가지 않습니다. |
| 놓을 때 | 가장 가까운 번호에 맞추고 전환 시간 동안 자리를 잡습니다. 끄는 속도는 보지 않으므로, 빠르게 튕겨도 절반을 넘지 못하면 원래 뷰로 돌아갑니다. |
| `onIndexChanged` | 놓을 때 맞춘 번호로 불립니다. 번호가 그대로여도 불리고, 끌지 않고 안을 누르기만 해도(안의 버튼 포함) 지금 번호로 불립니다. 번호가 바뀐 때만 할 일이 있으면 이전 값과 견주세요. |
| `index` 를 바꿀 때 | `onIndexChanged` 는 불리지 않습니다. |
| 끄는 동안 `index` 가 바뀔 때 | Flutter 는 끌기를 멈추고 새 뷰로 갑니다. Jaspr Web 은 끄는 동안의 변경을 무시합니다. |

<a id="드래그-비활성화"></a>

### 끌기 끄기

`gestureEnabled: false` 면 끌기를 받지 않고 `index` 로만 넘깁니다. 목록과 격자 보기처럼 실수로 넘기면 안 되는 자리에 씁니다. 이때는 `onIndexChanged` 가 불리지 않습니다.

```dart
Switcher(
  index: index,
  gestureEnabled: false,
  items: views,
)
```

<a id="동작-스펙-behavior"></a>
<a id="애니메이션"></a>

## 상태

멈춰 있을 때는 `index` 번째 뷰 하나만 창에 보입니다.

<Preview demo="switcher/index" />

| 상태 | 모습과 전환 |
| --- | --- |
| 멈춤 | `index` 번째 뷰가 온전한 진하기로 보입니다. |
| 전환 중 | `index` 가 바뀌면 두 뷰가 `direction` 축을 따라 함께 움직이고, 나가는 뷰는 옅어지고 들어오는 뷰는 진해집니다. 시간은 `CoreDuration.moderate`(300ms), 곡선은 `CoreEasing.move` 입니다. |
| 두 칸 이상 건너뛸 때 | Flutter 는 사이의 뷰가 차례로 지나갑니다. Jaspr Web 은 사이의 뷰가 투명한 채라 처음 뷰와 마지막 뷰만 옅어지고 진해집니다. |
| 끄는 중 | 전환 시간이 0 이 되어 포인터를 바로 따라갑니다. |
| 동작 줄이기 | Flutter 는 500ms 이하의 전환을 바로 바꿉니다. Jaspr Web 은 전환을 줄이지 않습니다. |
| 비활성 | `enabled` 속성은 없습니다. 끌기만 `gestureEnabled: false` 로 끕니다. |

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

여러 뷰를 번호와 방향으로 바꿔 보여 주고, 끌어서도 넘기게 할 때 씁니다. Switcher 는 탭 라벨이나 내비게이션 바를 만들지 않습니다.

- 온보딩 단계처럼 순서가 있는 뷰를 밀어 넘길 때
- 목록과 격자처럼 보기 방식을 바꾸면서 움직임으로 이어 줄 때
- 끌어서 이웃한 뷰를 훑게 할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 라벨을 눌러 내용 섹션을 고를 때 | [Tabs](/components/tabs). Tabs 는 라벨 바만 그립니다. 탭과 패널을 한 상자로 묶으려면 [TabPane](/components/tab-pane)을 씁니다. |
| 하단 바 · 레일 · 사이드바의 최상위 화면을 바꾸고, 돌아와도 스크롤과 입력이 남아야 할 때 | [IndexedSwitcher](/components/indexed-switcher) |
| 두 상태(아이콘 · 글자 따위)만 맞바꿀 때 | [Swap](/components/swap) |
| 자동 재생, 위치 표시, 이전 · 다음 버튼이 필요한 슬라이드일 때 | [Carousel](/components/carousel) |
| 화면 가장자리에서 밀어 패널을 열 때 | [Swiper](/components/swiper) |

<a id="do"></a>
<a id="dont"></a>

### 상태 · 곡선 · 라벨

<Cards columns="2">
<Card tone="do" eyebrow="이렇게 하세요">

`onIndexChanged` 로 받은 번호를 상태에 반영합니다.

```dart
Switcher(
  index: index,
  onIndexChanged: (next) =>
      setState(() => index = next),
  items: views,
)
```

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

`index` 를 고정한 채 끌기를 켜 두지 않습니다. 화면은 넘어가는데 `index` 는 0 이라, 0 을 다시 넘겨도 첫 뷰로 돌아오지 않습니다.

```dart
Switcher(
  index: 0,
  items: views,
)
```

</Card>
<Card tone="do" eyebrow="이렇게 하세요">

전환 곡선은 처음과 끝을 지나치지 않는 것을 고릅니다.

```dart
CoreSwitcherStyle(
  curve: CoreEasing.enter,
)
```

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

끝을 지나쳤다 돌아오는 곡선은 쓰지 않습니다. Flutter 에서 마지막 뷰로 넘어가는 전환이 그 너머를 읽어 오류가 납니다.

```dart
CoreSwitcherStyle(
  curve: CoreEasing.feedback,
)
```

</Card>
<Card tone="do" eyebrow="이렇게 하세요">

라벨로 섹션을 고르게 하려면 `Tabs` 를 씁니다.

```dart
Tabs.labels(
  labels: const ['계정', '비밀번호'],
  selectedIndex: index,
  onChanged: (i) =>
      setState(() => index = i),
)
```

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

라벨 글자를 뷰로 넣어 탭처럼 쓰지 않습니다. 누를 수 있는 라벨이 생기지 않습니다.

```dart
Switcher(
  items: const [
    Text('계정'),
    Text('비밀번호'),
  ],
)
```

</Card>
</Cards>

## 배치

<Cards columns="2">
<Card demo="switcher/placement-sized" title="크기를 정한 자리">

폭과 높이를 정한 상자에 넣고, 뷰가 그 상자를 채우게 합니다. 두 플랫폼이 같게 보입니다.

</Card>
<Card demo="switcher/placement-buttons" title="선택 컨트롤과 함께">

버튼이나 `ToggleGroup` 으로 `index` 를 바꾸면 끌지 않고도 넘길 수 있습니다. Switcher 에는 키보드 조작이 없어, 이런 컨트롤이 키보드로 넘기는 길이 됩니다.

</Card>
</Cards>

Switcher 의 크기는 플랫폼마다 다르게 정해집니다. Flutter 는 보이는 뷰를 따르고, Jaspr Web 은 부모 상자를 채웁니다.

| 놓는 자리 | Flutter | Jaspr Web |
| --- | --- | --- |
| 폭과 높이를 정한 상자 | 뷰가 그 크기를 받습니다. | 모든 뷰가 같은 크기의 칸을 받습니다. 칸을 채우려면 뷰에 `h-full` 처럼 높이를 줍니다. 움직이는 축으로 창보다 큰 내용은 칸을 늘립니다([알려진 제약](#알려진-제약)). |
| 크기를 정하지 않은 자리(`left` · `right`) | 보이는 뷰의 크기를 따르고, 전환 중에는 두 뷰의 크기 사이를 지나갑니다. 크기가 다른 두 뷰는 움직이는 축과 직각 방향의 가운데에 맞춥니다. | 폭은 부모를 채우고, 높이는 가장 높은 뷰를 따릅니다. 낮은 뷰는 칸의 위쪽에 놓입니다. |
| 높이를 정하지 않은 자리(`up` · `down`) | 위와 같습니다. | 상자가 모든 뷰를 위아래로 쌓은 높이만큼 자리를 차지합니다. 부모의 높이를 정하세요. |

<Split>

<Code language="dart" title="Flutter">
SizedBox(
  width: 256,
  height: 112,
  child: Switcher(
    index: index,
    onIndexChanged: (next) => setState(() => index = next),
    items: const [
      Center(child: Text('개요')),
      Center(child: Text('상세')),
    ],
  ),
)
</Code>

<Code language="dart" title="Jaspr Web">
div(styles: Styles(raw: {'width': '16rem', 'height': '7rem'}), [
  Switcher(
    index: index,
    onIndexChanged: (next) => setState(() => index = next),
    items: [
      div(classes: 'flex h-full items-center justify-center', [Text('개요')]),
      div(classes: 'flex h-full items-center justify-center', [Text('상세')]),
    ],
  ),
])
</Code>

</Split>

<a id="스타일-시스템-style-system"></a>
<a id="시맨틱-vs-스타일"></a>
<a id="파라미터와-스타일"></a>

## 테마와 스타일

무엇을 보여 주고 어떻게 넘길지(`items` · `index` · `direction` · `gestureEnabled`)는 위젯 속성으로 넘기고, 전환 시간과 곡선은 `switcherStyle`(`CoreSwitcherStyle`) 하나로 바꿉니다. Switcher 는 색 · 여백 · 글자를 정하지 않습니다. 뷰의 모습은 `items` 에 넣은 것이 정합니다.

<Split>

<Code language="dart" title="Switcher 하나만 바꾸기">
Switcher(
  index: index,
  onIndexChanged: (next) => setState(() => index = next),
  switcherStyle: const CoreSwitcherStyle(
    duration: Duration(milliseconds: CoreDuration.slow),
    curve: CoreEasing.enter,
  ),
  items: views,
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    switcher: CoreSwitcherTheme(
      style: CoreSwitcherStyle(
        duration: Duration(milliseconds: CoreDuration.fast),
      ),
    ),
  ),
)
</Code>

</Split>

`curve` 는 두 플랫폼이 함께 쓰는 cubic-bezier 제어점 네 개(`CoreCubicBezier`, `CoreEasing.*`)입니다. Flutter 는 `Curve` 로, Jaspr Web 은 `cubic-bezier(…)` 로 바꿔 뷰의 이동과 진하기에 같이 씁니다. 전환 시간과 곡선은 `switcherStyle` 로만 정하고, Flutter 의 `Curve` 를 받는 속성은 없습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Switcher` 에 스타일을 덧붙일 때는 `withStyle` 을 이어 씁니다. 생성자의 `switcherStyle` 과 같게 동작하고, 여러 번 이으면 뒤의 값이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class SwitcherChainExample extends StatefulWidget {
  const SwitcherChainExample({super.key});

  @override
  State<SwitcherChainExample> createState() => _SwitcherChainExampleState();
}

class _SwitcherChainExampleState extends State<SwitcherChainExample> {
  int _index = 0;

  static const List<String> _labels = ['보기 A', '보기 B', '보기 C'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: CoreSpace.space256,
          height: CoreSize.size96,
          child:
              Switcher(
                index: _index,
                onIndexChanged: (next) => setState(() => _index = next),
                items: [
                  for (final label in _labels) Center(child: Text(label).titleMedium),
                ],
              ).withStyle(
                const CoreSwitcherStyle(
                  duration: Duration(milliseconds: CoreDuration.slow),
                  curve: CoreEasing.enter,
                ),
              ),
        ),
        const Gap.space16(),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (var idx = 0; idx < _labels.length; idx++)
              Padding(
                padding: const CoreEdgeInsets.symmetric(
                  horizontal: CoreSpace.space4,
                ).toValue(geometry: Theme.of(context).geometry),
                child: Button(
                  variant: idx == _index ? CoreButtonVariant.primary : CoreButtonVariant.outline,
                  onPressed: () => setState(() => _index = idx),
                  child: Text(_labels[idx]),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class SwitcherChainExample extends StatefulComponent {
  const SwitcherChainExample({super.key});

  @override
  State<SwitcherChainExample> createState() => _SwitcherChainExampleState();
}

class _SwitcherChainExampleState extends State<SwitcherChainExample> {
  int _index = 0;

  static const List<String> _labels = ['보기 A', '보기 B', '보기 C'];

  @override
  Component build(BuildContext context) {
    return div(
      [
        div(
          [
            Switcher(
              index: _index,
              onIndexChanged: (next) => setState(() => _index = next),
              items: [
                for (final label in _labels)
                  div(
                    [Text(label).titleMedium],
                    classes: 'flex items-center justify-center h-full',
                  ),
              ],
            ).withStyle(
              const CoreSwitcherStyle(
                duration: Duration(milliseconds: CoreDuration.slow),
                curve: CoreEasing.enter,
              ),
            ),
          ],
          styles: const Styles(
            raw: {'width': '16rem', 'height': '6rem'},
          ),
        ),
        Gap.space16(),
        div(
          [
            for (var idx = 0; idx < _labels.length; idx++)
              Button(
                variant: idx == _index ? CoreButtonVariant.primary : CoreButtonVariant.outline,
                onPressed: () => setState(() => _index = idx),
                child: Text(_labels[idx]),
              ),
          ],
          classes: 'flex flex-row flex-wrap justify-center gap-${CoreSpace.scale.space8}',
        ),
      ],
      classes: 'inline-flex flex-col items-center',
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreSwitcherStyle.defaultDuration / defaultCurve   // 디자인 시스템 기본값
  → CoreSwitcherTheme.style                        // 앱 전체
  → switcherStyle                                  // 인스턴스
```

뒤로 갈수록 우선합니다. `duration` 과 `curve` 는 따로 합쳐지므로, 한쪽만 주면 다른 쪽은 앞의 값이 남습니다.

<a id="접근성-accessibility"></a>

## 접근성

Switcher 는 보이는 뷰를 바꾸는 상자입니다. 접근 가능한 이름, 키보드 조작, 바뀜 알림은 만들지 않으므로 둘레의 컨트롤과 라벨로 채워야 합니다. 모든 컴포넌트에 공통인 축은 [전역 접근성 축](/accessibility)을 보세요.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | `Semantics(container: true)` 로 시맨틱 경계를 만듭니다. 묶음(group) 역할은 없습니다. `gestureEnabled` 면 끌기를 받는 영역이 스크롤 동작(위 · 아래 · 왼쪽 · 오른쪽)을 보조 기술에 알립니다. |
| Jaspr Web | 바깥 `div` 에 `role="group"` 이 붙습니다. 뷰를 담은 칸마다 `aria-hidden` 이 붙고, `index` 번째 칸만 `"false"` 입니다. |

어느 플랫폼에도 접근 가능한 이름을 받는 속성이 없습니다. Jaspr Web 은 `attributes: {'aria-label': '온보딩'}` 이 바깥 `div` 에 붙고(`role` 은 늘 `group` 입니다), Flutter 는 `Semantics(label: …)` 로 감쌉니다.

### 키보드

Switcher 가 처리하는 키는 없습니다.

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `←` · `→` · `↑` · `↓` | 없음 | 없음 |
| `Home` · `End` · `PageUp` · `PageDown` | 없음 | 없음 |
| `Tab` | Switcher 자신은 정지점이 아닙니다. | Switcher 자신은 정지점이 아닙니다. |

Jaspr Web 은 `onKeyDown` · `onKeyUp` 을 바깥 `div` 에 붙이지만 그 `div` 에는 `tabindex` 가 없어, 포커스가 뷰 안에 있을 때만 불립니다. 키보드로 넘기게 하려면 버튼 같은 컨트롤로 `index` 를 바꿉니다.

### 스크린 리더

- 뷰가 바뀐 것을 알리는 라이브 리전이 없습니다. 지금 몇 번째 뷰인지도 알려 주지 않습니다.
- **Jaspr Web** — 모든 뷰가 늘 DOM 에 있고, `index` 번째 뷰만 `aria-hidden="false"` 로 드러납니다.
- **Flutter** — 멈춰 있을 때는 보이는 뷰만 만들어 두므로 다른 뷰는 읽히지 않습니다. 전환하는 동안에는 두 뷰가 함께 있습니다.
- **Flutter** — `gestureEnabled` 면 스크린 리더의 스크롤 동작으로도 넘길 수 있습니다. 다음 뷰로 [끄는 방향](#전환-방향)과 같은 쪽의 스크롤은 한 칸 넘기고 반대쪽 스크롤은 한 칸 되돌리며, 두 경우 모두 맞춘 번호로 `onIndexChanged` 를 부릅니다. 움직이는 축과 직각인 스크롤은 뷰를 바꾸지 않고 지금 번호로 `onIndexChanged` 를 부릅니다. Jaspr Web 에는 이런 동작이 없습니다.

### 포커스 관리

- Switcher 는 포커스를 받지 않고, 옮기거나 가두지도 않습니다.
- `index` 가 바뀌어도 새로 보이는 뷰로 포커스를 옮기지 않습니다.
- Flutter 는 보이지 않게 된 뷰를 없앱니다. 그 안에 포커스가 있었으면 직전에 포커스를 가졌던 컨트롤로 돌아가고, 그런 컨트롤이 없으면 둘레의 포커스 범위에 남습니다.
- Jaspr Web 은 포커스가 보이지 않는 뷰 안에 그대로 남습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | `direction` 이 `right` · `down` 이면 `index` 1 부터 빈 창이 보입니다. 뷰를 늘어놓는 순서는 `left` · `up` 과 같은데 옮기는 방향만 반대라, 보여야 할 뷰가 창 밖으로 더 나갑니다. 끌어도 다음 뷰가 들어오지 않습니다. 왼쪽에서 오른쪽으로 쓰는 문서의 Jaspr Web 에서는 `left` · `up` 을 씁니다. |
| Jaspr Web | 오른쪽에서 왼쪽으로 쓰는 문서(`dir="rtl"`)에서는 뷰가 오른쪽부터 늘어서는데 옮기는 방향은 그대로입니다. 그래서 가로에서는 기본값인 `left` 가 `index` 1 부터 빈 창이 되고 `right` 는 뷰가 보입니다. `up` · `down` 은 글 방향의 영향을 받지 않습니다. |
| Flutter | 끝을 지나치는 곡선(`CoreEasing.easeOutBack` · `easeInBack` · `easeInOutBack`, 그리고 `easeOutBack` 과 같은 `feedback`)을 쓰면, 전환이 첫 뷰나 마지막 뷰 너머로 지나치는 순간 목록 밖의 번호를 읽어 오류가 납니다(`easeOutBack` 으로 마지막 뷰에 갈 때처럼). 가운데 뷰 사이에서는 이웃한 뷰가 잠깐 비칩니다. `enter` · `exit` · `move` 처럼 끝을 지나치지 않는 곡선을 씁니다. |
| 공통 | `gestureEnabled` 면 `onIndexChanged` 가 번호가 바뀌지 않아도 불립니다. 안의 버튼이나 빈 곳을 누르기만 해도 지금 번호로 불립니다. |
| 공통 | `index` 의 범위를 검사하지 않습니다. `0` 이상 `items.length` 미만을 벗어나면 Flutter 는 오류가 나고, Jaspr Web 은 모든 뷰가 숨은 빈 창이 됩니다. |
| Flutter | 지금 보이는 번호가 새 `items` 길이 이상이 되게 항목을 줄이면, 전환 시간이 있는 한 `index` 를 같은 순간에 범위 안으로 바꿔도 오류가 납니다. 전환이 이전 번호에서 시작해 줄어든 목록을 읽기 때문입니다. `key: ValueKey(items.length)` 를 주어 `Switcher` 를 새로 만들거나(뷰의 상태도 새로 시작합니다), 먼저 `index` 를 옮기고 전환이 끝난 뒤 항목을 줄입니다. |
| Jaspr Web | 보이지 않는 뷰가 탭 순서에 남습니다. 그 칸에는 `aria-hidden="true"` 와 투명도만 걸리고 `inert` 는 붙지 않습니다. 안의 버튼 · 링크는 보이지 않는 채로 `Tab` 이 닿고, 스크린 리더는 읽지 않습니다. 지금 뷰보다 뒤의 칸(`left` 면 오른쪽, `up` 이면 아래)에 포커스가 가면 브라우저가 창을 그 칸 쪽으로 스크롤해, 보이던 뷰까지 창 밖으로 밀려날 수 있습니다. 각 뷰 안의 컨트롤을 지금 `index` 에 따라 비활성으로 둡니다. 밀기와 끌기가 필요 없으면, 숨은 화면을 `inert` 로 두는 IndexedSwitcher 를 씁니다. |
| Jaspr Web | `aria-hidden` 은 `index` 만 따릅니다. 끌어서 다른 뷰로 넘긴 뒤 `index` 를 바꾸지 않으면, 보이는 뷰는 숨겨지고 보이지 않는 뷰가 드러난 채로 남습니다. `onIndexChanged` 로 `index` 를 갱신합니다. |
| Jaspr Web | 움직이는 축으로 창보다 큰 내용(`left` · `right` 에서는 줄을 바꿀 수 없는 긴 글이나 넓은 표, `up` · `down` 에서는 긴 목록)은 그 뷰의 칸을 창보다 크게 늘립니다. 칸의 최소 크기를 0 으로 두지 않기 때문입니다. 그러면 뒤의 칸이 밀려 전환 뒤의 위치가 어긋납니다. 칸에 스타일을 넣는 속성은 없으므로, 넘칠 수 있는 뷰는 `overflow-auto` 상자에 담고 그 상자의 폭(`up` · `down` 이면 높이)을 `16rem` 처럼 창과 같은 길이로 직접 정합니다. `100%` · `h-full` 처럼 부모를 따르는 크기는 칸이 늘어나는 것을 막지 못합니다. |
| Jaspr Web | 전환이 동작 줄이기 설정에 반응하지 않습니다. 300ms 이동과 옅어짐이 설정과 상관없이 재생됩니다. 끄려면 `CoreSwitcherStyle(duration: Duration.zero)` 를 넘깁니다. |
| Jaspr Web | 끄는 동안 글자 선택이나 페이지 스크롤을 막지 않습니다. 터치에서 브라우저가 끌기를 스크롤로 가져가면 끌기가 그 자리에서 끝납니다. 또 누른 버튼을 가리지 않아 마우스 오른쪽 버튼으로도 끌기가 시작됩니다. |
| Flutter | 실행 중에 `gestureEnabled` 를 바꾸면 안쪽 위젯을 새로 만듭니다. 뷰의 상태가 사라지고, 같은 순간에 바꾼 `index` 는 전환 없이 바뀝니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

두 플랫폼은 `items` · `index` · `direction` · `gestureEnabled` · `onIndexChanged` · `switcherStyle` 을 같은 이름과 기본값으로 받습니다. 그리는 방식과 아래 동작은 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 뷰의 타입 | `List<Widget>` | `List<Component>` |
| 그리는 방식 | 전환에 관여하는 두 뷰만 겹쳐 놓고 위치와 투명도를 계산합니다. | 모든 뷰를 한 줄에 늘어놓고 그 줄을 옮깁니다(CSS `transform`). |
| 크기 | 크기를 정하지 않은 쪽은 보이는 뷰를 따릅니다. | 부모 상자를 채웁니다([배치](#배치) 참고). |
| 보이지 않는 뷰의 상태 | 멈추면 없애므로 입력한 값과 스크롤 위치가 사라집니다. | DOM 에 남아 상태가 유지됩니다. |
| `right` · `down` | 표대로 움직입니다. | `index` 1 부터 빈 창이 보입니다. `dir="rtl"` 문서에서는 `left` · `down` 이 그렇습니다. |
| 두 칸 이상 건너뛸 때 | 사이의 뷰가 차례로 지나갑니다. | 처음 뷰와 마지막 뷰만 보입니다. |
| 끄는 동안 `index` 변경 | 끌기를 멈추고 새 뷰로 갑니다. | 무시합니다. |
| 끝을 지나치는 곡선 | 첫 뷰나 마지막 뷰 너머로 지나치면 오류가 납니다. | 지나쳤다가 돌아옵니다. |
| 범위 밖 `index` | 오류가 납니다. | 빈 창이 됩니다. |
| 동작 줄이기 | 500ms 이하의 전환을 바로 바꿉니다. | 줄이지 않습니다. |
| 보조 기술 | 시맨틱 경계. 멈춰 있을 때 숨은 뷰는 없습니다. `gestureEnabled` 면 스크롤 동작으로도 넘깁니다. | `role="group"` 과 칸마다 `aria-hidden`. 넘기는 동작은 없습니다. |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` · `onClick` 등을 바깥 `div` 에 붙입니다. `gestureEnabled` 면 `pointerdown` 은 끌기가 쓰므로 `eventHandlers` 의 `pointerdown` 은 덮입니다. |

<a id="props-parameters"></a>

## API

두 플랫폼이 같은 속성을 씁니다. 아래의 `W` 는 Flutter 의 `Widget`, Jaspr Web 의 `Component` 입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `items` | `List<W>` | 필수 | 번갈아 보여 줄 뷰. 하나 이상 넣습니다. |
| `index` | `int` | `0` | 보일 뷰의 번호(0부터). `0` 이상 `items.length` 미만이어야 합니다. |
| `direction` | `CoreSwitcherDirection` | `left` | `index` 가 늘 때 뷰가 움직이는 방향(`up` · `down` · `left` · `right`)입니다. 기본값은 `CoreSwitcherDirection.defaultDirection` 입니다. [전환 방향](#전환-방향)을 참고하세요. |
| `gestureEnabled` | `bool` | `true` | 끌어서 넘기기를 받습니다. |
| `onIndexChanged` | `void Function(int)?` | `null` | `gestureEnabled` 일 때, 끌기가 끝나거나 안을 눌렀다 뗄 때 맞춘 번호를 받습니다. `index` 를 바꿀 때는 불리지 않습니다. |
| `switcherStyle` | `CoreSwitcherStyle?` | `null` | 전환 시간과 곡선 |

`copyWith` 와 `withStyle` 은 두 플랫폼에 있습니다. Jaspr Web 은 HTML 속성과 DOM 이벤트 콜백도 받습니다(플랫폼 차이 참고).

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreSwitcherStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `duration` | `Duration?` | Slide / fade transition duration. |
| `curve` | `CoreCubicBezier?` | Slide / fade transition easing, as cubic-bezier control points. `null` → [defaultCurve]. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card component="tabs" props="variant=underline" title="Tabs">

라벨로 보기를 고르는 탭 바입니다.

</Card>
<Card demo="switcher/related-indexed-switcher" title="IndexedSwitcher">

모든 화면을 살려 둔 채 하나만 보여 줍니다.

</Card>
<Card demo="switcher/related-swap" title="Swap">

두 상태를 맞바꿉니다.

</Card>
<Card title="Carousel" href="/components/carousel" more="Carousel 보기">

자동 재생과 위치 표시가 있는 슬라이드입니다.

</Card>
<Card title="Swiper" href="/components/swiper" more="Swiper 보기">

가장자리에서 밀어 패널을 엽니다.

</Card>
</Cards>
