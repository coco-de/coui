---
title: IndexedSwitcher
description: 모든 화면을 살려 둔 채 하나만 보여 주고, 바꿀 때 앞 화면이 사라진 뒤 새 화면이 나타나는 화면 전환 컴포넌트
category: navigation
platforms: [flutter, web]
related: [switcher, navigation-bar, tabs]
tags: [indexed-switcher, destination, tab, shell, go_router, fade]
template: v2
source: navigation/indexed_switcher
---

# IndexedSwitcher

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

`index`를 바꿔 보며 전환을 확인하고, 만들어진 코드를 그대로 복사하세요. 미리보기 화면의 버튼을 몇 번 누르고 다른 화면에 다녀오면, 누른 횟수가 남아 있습니다.

<Playground component="indexed-switcher" />

IndexedSwitcher는 `children`을 모두 만들어 둔 채로 `index`(0부터 셉니다)의 화면 하나만 보여 줍니다. 화면을 바꾸는 컨트롤은 그리지 않으므로, 내비게이션 바 · 레일 · 사이드바 · 탭처럼 순번을 정하는 쪽의 값을 `index`로 넘깁니다. 코드의 `HomeScreen` 같은 이름은 앱의 화면이 들어갈 자리입니다.

```dart
IndexedSwitcher(
  index: _index,
  children: const [
    HomeScreen(),
    SearchScreen(),
    SettingsScreen(),
  ],
)
```

Flutter의 `IndexedStack`처럼 화면 상태를 지키고, 화면을 바꿀 때 앞 화면이 먼저 사라진 뒤 새 화면이 나타나는 전환(페이드 스루)을 더합니다. `IndexedStack`의 `alignment` · `sizing` · `clipBehavior` · `textDirection`은 받지 않고, Flutter에서는 그 기본값처럼 화면을 시작 쪽 위에 놓습니다.

<a id="동작-스펙-behavior"></a>

## 상태

화면 하나의 모습은 `index`에 따라 아래 셋 중 하나입니다. variant와 크기 단계는 없습니다.

<Preview demo="indexed-switcher/fade-through" />

위 그림은 `홈`에서 `검색`으로 바꾸는 전환의 네 순간을 멈춰 그린 것입니다. 실제 전환은 플레이그라운드에서 볼 수 있습니다.

| 화면 | 모습 | 누르기 · 키보드 포커스 · 보조 기술 |
| --- | --- | --- |
| `index`의 화면 | 앞 화면이 사라진 뒤 `enterDuration`(`CoreDuration.normal`, 200ms) 동안 `enterCurve`(`CoreEasing.enter`)로 나타납니다. | 받습니다. 아직 투명한 동안에도 받습니다. |
| 직전까지 보이던 화면 | `exitDuration`(`CoreDuration.instant`, 100ms) 동안 `exitCurve`(`CoreEasing.exit`)로 흐려진 뒤 숨습니다. | 바뀌는 순간부터 받지 않습니다. |
| 나머지 화면 | 숨어 있고, 상태는 남습니다. | 받지 않습니다. |

### 전환

- `index`가 바뀌면 앞 화면이 먼저 사라지고, 그다음 새 화면이 나타납니다. 두 화면이 반쯤씩 겹쳐 보이는 순간이 없습니다. 기본값으로는 전체가 `CoreDuration.moderate`(300ms)입니다.
- 처음 그릴 때는 모션 없이 `index`의 화면을 바로 보여 줍니다.
- 전환 도중에 다시 바꾸면, 직전까지 보여 주던 화면은 그때의 진하기에서부터 흐려집니다. 반쯤 나타난 화면이 순간 다시 진해지지 않습니다.
- 새 화면은 `exitDuration`만큼 기다린 뒤 나타납니다. 직전 화면이 아직 나타나기 전이었어도 기다립니다.
- 그보다 앞서 흐려지던 화면이 어떻게 끝나는지는 플랫폼마다 다릅니다([플랫폼 차이](#플랫폼-차이)).
- 동작 줄이기 설정이 켜져 있으면 500ms 이하의 시간은 0이 됩니다. 기본값은 두 시간 모두 여기에 해당해 화면이 바로 바뀝니다. 500ms보다 길게 정한 시간은 Jaspr Web과 iOS의 동작 줄이기에서는 줄지 않습니다. Flutter에서 `disableAnimations`(Android의 애니메이션 끄기)가 켜져 있으면, Flutter가 그 긴 시간도 원래의 5%로 줄여 돌립니다.

### 화면 상태

- 보이지 않는 화면도 만들어 둡니다. 스크롤 위치, 입력한 값, 화면 안에서 이동한 기록(Flutter의 화면 안 `Navigator`)이 다른 화면에 다녀와도 남습니다. Jaspr Web에서 화면 안에 스크롤 상자를 만든다면 [알려진 제약](#알려진-제약)도 함께 확인하세요.
- 처음 그릴 때 모든 화면을 만듭니다. 무거운 화면은 첫 화면이 아니어도 그때 함께 만들어집니다.
- 숨은 화면 안의 애니메이션은 계속 돕니다(`IndexedStack`과 같습니다).
- 화면의 상태는 `children`의 자리(순번)에 붙습니다. 목록의 순서를 바꾸거나 가운데에 화면을 끼우고 빼면, 밀린 자리의 상태는 사라지거나(위젯 종류가 다를 때) 다른 화면으로 넘어갑니다(종류가 같을 때). 순서와 개수를 고정해 두세요.
- 화면에 `ValueKey` 같은 보통의 `key`를 줘도 상태가 화면을 따라가지 않습니다. 키가 달라진 자리는 새로 만들어집니다.
- 순서를 꼭 바꿔야 하면 화면마다 `GlobalKey`를 만들어 부모의 `State`에 두고 넘깁니다. Flutter에서는 화면의 상태가 따라갑니다. Jaspr Web에서도 `State`는 따라가지만, 화면의 DOM 요소를 떼었다 다시 붙이므로 그 안의 스크롤 위치와 포커스는 남지 않을 수 있습니다.

### 입력

- 누르기 · 키보드 포커스 · 보조 기술은 `index`의 화면만 받습니다. 새 화면은 바뀌는 순간부터 받고, 아직 투명한 처음 100ms(기본값) 동안에도 받습니다.
- 사라지는 화면은 흐려지는 동안에도 받지 않습니다. 아직 보이는 그 자리를 눌러도 사라지는 화면에는 닿지 않고, `index`의 화면이 그 자리를 덮고 있으면 그 화면이 받습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

- 하단 내비게이션 바 · 레일 · 사이드바로 최상위 화면 사이를 오갈 때
- go_router `StatefulShellRoute`의 탭 전환에 모션을 붙일 때
- 화면을 바꿨다 돌아와도 스크롤 위치와 입력 내용이 남아 있어야 할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 순서가 있는 보기를 한 방향으로 밀어 넘기고, 끌어서도 넘길 때 | [Switcher](/components/switcher). Flutter의 Switcher는 넘기는 두 보기만 그리므로 지나간 보기의 상태가 남지 않습니다. |
| 두 상태를 바꿔 가며 보여 줄 때 | [Swap](/components/swap) |
| 탭 줄과 내용 상자가 한 덩어리로 필요할 때 | [TabPane](/components/tab-pane) |

<a id="do"></a>
<a id="dont"></a>

### 화면과 순서

<Cards columns="2">
<Card tone="do" eyebrow="이렇게 하세요">

화면의 상태는 그 화면 안에 둡니다. 화면이 계속 만들어져 있어, 탭을 바꿨다 돌아와도 남습니다.

```dart
IndexedSwitcher(
  index: _tab,
  children: const [
    HomeScreen(),
    SearchScreen(),
  ],
)
```

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

온보딩처럼 앞뒤가 있는 단계에 쓰지 않습니다. 방향이 있는 이동은 밀어 넘기는 [Switcher](/components/switcher)가 보여 줍니다.

```dart
IndexedSwitcher(
  index: _step,
  children: onboardingSteps,
)
```

</Card>
<Card tone="do" eyebrow="이렇게 하세요">

조건에 따라 달라지는 화면은 같은 자리에서 바꿉니다. 다른 화면의 자리는 그대로입니다.

```dart
children: [
  HomeScreen(),
  signedIn
      ? InboxScreen()
      : SignInScreen(),
  SettingsScreen(),
]
```

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

조건에 따라 가운데 화면을 끼우거나 빼지 않습니다. `SettingsScreen`의 자리가 밀려 상태를 잃습니다.

```dart
children: [
  HomeScreen(),
  if (signedIn) InboxScreen(),
  SettingsScreen(),
]
```

</Card>
</Cards>

## 배치

<Cards columns="2">
<Card demo="indexed-switcher/with-navigation-bar" title="내비게이션 바와">

[NavigationBar](/components/navigation-bar)의 `selectedIndex`와 `index`에 같은 값을 넘기고, `onSelected`에서 그 값을 바꿉니다. 바는 구분선 · 제목 · 빈칸을 빼고 목적지만 세므로, 목적지 순서를 `children` 순서에 맞춥니다.

</Card>
<Card demo="indexed-switcher/with-tabs" title="탭 바와">

[Tabs](/components/tabs)는 탭 바만 그립니다. 고른 탭의 내용을 IndexedSwitcher에 두면, 탭을 바꿔도 내용의 상태가 남습니다.

</Card>
</Cards>

### 크기를 정하는 방식

<Preview demo="indexed-switcher/sizing" />

내용에 맞춰 크기가 정해질 때는, 보이는 화면이 아니라 가장 큰 화면에 맞춥니다(`IndexedStack`과 같습니다). 위의 두 칸은 같은 `children`에 `index`만 다른데 크기가 같습니다. 점선은 IndexedSwitcher의 크기를 알아보도록 둘레에 8만큼 띄워 그렸습니다.

| 플랫폼 | 부모와의 관계 |
| --- | --- |
| Flutter | 부모가 크기를 강제하지 않으면 가장 큰 화면의 크기이고, 강제하면 그 크기입니다. `Column` 안에서 남은 높이를 채우려면 `Expanded`로 감쌉니다. |
| Jaspr Web | 루트에 `h-full`이 있어, 부모에 정해진 높이가 있으면 그 높이를 채웁니다. 다만 높이를 길이로 정하지 않은 화면의 내용이 그보다 길면, 숨은 화면이어도 화면을 담는 칸이 모두 그 길이까지 늘어 부모를 넘칩니다([알려진 제약](#알려진-제약)). 정해진 높이가 없으면 가장 큰 화면의 높이입니다. 블록 배치에서 폭은 부모 폭을 채웁니다. |

## go_router 와 함께 쓰기

go_router의 `StatefulShellRoute.indexedStack`은 탭을 바꿀 때 모션이 없습니다. 탭 화면을 담는 틀을 IndexedSwitcher로 바꾸면 전환에 모션이 붙고, 각 탭의 화면 상태는 그대로 남습니다. `StatefulShellRoute.indexedStack(...)` 대신 `StatefulShellRoute(navigatorContainerBuilder: ...)`를 씁니다.

```dart
StatefulShellRoute(
  navigatorContainerBuilder: (context, navigationShell, children) =>
      IndexedSwitcher(
        index: navigationShell.currentIndex,
        children: children,
      ),
  builder: (context, state, navigationShell) =>
      AppShell(navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(routes: [homeRoute]),
    StatefulShellBranch(routes: [searchRoute]),
    StatefulShellBranch(routes: [profileRoute]),
  ],
)
```

`indexedStack`은 보이지 않는 갈래의 애니메이션을 `TickerMode`로 멈춥니다. IndexedSwitcher는 멈추지 않으므로, 똑같이 멈추려면 갈래마다 `TickerMode`로 감쌉니다.

```dart
navigatorContainerBuilder: (context, navigationShell, children) =>
    IndexedSwitcher(
      index: navigationShell.currentIndex,
      children: [
        for (final (index, branch) in children.indexed)
          TickerMode(
            enabled: index == navigationShell.currentIndex,
            child: branch,
          ),
      ],
    ),
```

탭 안에서 새 화면이 열리는 전환은 IndexedSwitcher가 아니라 각 `GoRoute`가 돌려주는 페이지가 정합니다. go_router는 앱이 Material · Cupertino 앱이 아니면 `builder:`로 만든 화면에 전환을 붙이지 않는데, `CoUIApp`은 둘 다 아닙니다. 새 화면에도 모션을 붙이려면 `pageBuilder`에서 `RoutePage`를 돌려주세요.

```dart
GoRoute(
  path: 'detail',
  pageBuilder: (context, state) =>
      RoutePage(key: state.pageKey, child: const DetailScreen()),
)
```

새 화면이 플랫폼마다 어떻게 들어오는지와 시간을 바꾸는 법은 [모션 가이드](/guides/animation)의 화면 전환 절에 있습니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

IndexedSwitcher에는 색 · 간격 같은 겉모습 값이 없습니다. 바꿀 수 있는 것은 전환의 두 시간과 두 곡선이고, 모두 `indexedSwitcherStyle`(`CoreIndexedSwitcherStyle`) 하나로 정합니다. 곡선은 `CoreEasing`의 값 같은 `CoreCubicBezier` 제어점으로 넘깁니다.

<Split>

<Code language="dart" title="IndexedSwitcher 하나만 바꾸기">
IndexedSwitcher(
  index: _index,
  indexedSwitcherStyle: const CoreIndexedSwitcherStyle(
    enterDuration: Duration(milliseconds: CoreDuration.moderate),
    enterCurve: CoreEasing.move,
  ),
  children: screens,
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: const CoreComponentTheme(
    indexedSwitcher: CoreIndexedSwitcherTheme(
      style: CoreIndexedSwitcherStyle(
        enterDuration: Duration(milliseconds: CoreDuration.moderate),
      ),
    ),
  ),
)
</Code>

</Split>

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `IndexedSwitcher`에 `withStyle`로 스타일을 덧붙일 수 있습니다. 생성자의 `indexedSwitcherStyle`과 같게 동작하고, 겹치는 필드는 `withStyle`에 넘긴 값이 이깁니다. 아래 예제는 앞 화면이 흐려지는 시간을 없애고, 새 화면이 `CoreDuration.slow`(500ms) 동안 나타나게 합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class IndexedSwitcherChainExample extends StatefulWidget {
  const IndexedSwitcherChainExample({super.key});

  @override
  State<IndexedSwitcherChainExample> createState() => _IndexedSwitcherChainExampleState();
}

class _IndexedSwitcherChainExampleState extends State<IndexedSwitcherChainExample> {
  int _index = 0;

  static const List<String> _labels = ['홈', '검색', '프로필'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: CoreSpace.space256,
          height: CoreSize.size96,
          child:
              IndexedSwitcher(
                index: _index,
                children: [
                  for (final label in _labels) Center(child: Text(label).titleMedium),
                ],
              ).withStyle(
                const CoreIndexedSwitcherStyle(
                  exitDuration: Duration.zero,
                  enterDuration: Duration(milliseconds: CoreDuration.slow),
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
class IndexedSwitcherChainExample extends StatefulComponent {
  const IndexedSwitcherChainExample({super.key});

  @override
  State<IndexedSwitcherChainExample> createState() => _IndexedSwitcherChainExampleState();
}

class _IndexedSwitcherChainExampleState extends State<IndexedSwitcherChainExample> {
  int _index = 0;

  static const List<String> _labels = ['홈', '검색', '프로필'];

  @override
  Component build(BuildContext context) {
    return div(
      [
        div(
          [
            IndexedSwitcher(
              index: _index,
              children: [
                for (final label in _labels)
                  div(
                    [Text(label).titleMedium],
                    classes: 'flex items-center justify-center h-full',
                  ),
              ],
            ).withStyle(
              const CoreIndexedSwitcherStyle(
                exitDuration: Duration.zero,
                enterDuration: Duration(milliseconds: CoreDuration.slow),
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

뒤로 갈수록 우선합니다.

```text
CoreIndexedSwitcherStyle.defaultExitDuration … defaultEnterCurve  // 디자인 시스템 기본값
  → CoreComponentTheme.indexedSwitcher.style                       // 앱 전체
  → indexedSwitcherStyle                                           // 인스턴스
```

<a id="접근성-accessibility"></a>

## 접근성

IndexedSwitcher는 자기 역할을 갖지 않고, `index`의 화면만 보조 기술과 키보드에 남깁니다. 모션 감소 · 고대비처럼 모든 컴포넌트에 공통인 설정은 [전역 접근성 축](/accessibility)에 정리되어 있습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 이름이나 역할이 있는 시맨틱 노드를 만들지 않고, 보이는 화면의 시맨틱을 그대로 둡니다. 숨은 화면과 사라지는 화면은 시맨틱 트리에서 뺍니다. |
| Jaspr Web | 루트와 화면을 담는 `<div>`에는 `role` · `aria-*`가 없습니다. 숨은 화면과 사라지는 화면의 `<div>`에는 `inert`를 붙입니다. |

### 키보드

없음. 처리하는 키가 없습니다. 화면을 바꾸는 것은 `index`를 정하는 쪽(내비게이션 바 · 탭 등)입니다. 숨은 화면과 사라지는 화면 안의 요소는 `Tab` 순서에서 빠집니다.

### 스크린 리더

- `index`의 화면만 읽힙니다. 새 화면은 전환이 시작되는 순간부터 읽을 수 있고, 아직 투명한 동안에도 그렇습니다.
- 화면이 바뀌었다고 알리는 영역(live region)은 없습니다.

### 포커스 관리

- 앞 화면 안에 있던 키보드 포커스는 화면이 바뀌는 순간 그 화면에서 빠집니다. IndexedSwitcher는 새 화면으로 포커스를 옮기지 않으므로, 두고 싶은 자리가 있으면 앱이 직접 옮깁니다.
- 빠진 포커스는 플랫폼마다 다르게 처리됩니다. Flutter에서는 같은 `FocusScope`에서 앞서 포커스를 받았고 지금도 받을 수 있는 컨트롤로 프레임워크가 포커스를 돌려줄 수 있고, 그런 컨트롤이 없으면 어느 컨트롤에도 서지 않습니다. Jaspr Web에는 다른 컨트롤로 포커스를 옮기는 처리가 없습니다.
- IndexedSwitcher는 포커스를 받지 않고, 포커스를 가두지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 화면이 바뀐 것을 알리지 않습니다. 바뀐 화면의 제목이 읽혀야 하면 앱이 새 화면의 제목으로 포커스를 옮기거나 알림을 보냅니다. |
| 공통 | 숨은 화면 안의 애니메이션을 멈추지 않습니다(`IndexedStack`과 같습니다). 동작 줄이기 설정이 켜져 있어도 IndexedSwitcher가 줄이는 것은 자기 전환의 시간뿐입니다. |
| Jaspr Web · Flutter(iOS) | 500ms보다 긴 `exitDuration` · `enterDuration`은 동작 줄이기에서도 줄지 않아, 그 시간만큼 전환이 돕니다. Flutter에서 `disableAnimations`가 켜진 경우는 다릅니다([플랫폼 차이](#플랫폼-차이)). |
| 공통 | `index`가 `children` 범위를 벗어나면 오류 없이 아무 화면도 보이지 않습니다. `IndexedStack`은 이때 디버그 모드에서 오류를 냅니다. |
| Flutter | 앞 화면이 흐려지는 동안 `index`를 다시 바꾸면, 흐려지던 화면은 그 자리에서 바로 사라집니다. 바꾼 곳이 바로 그 화면이면, 흐려지던 진하기가 아니라 0에서부터 다시 나타납니다. |
| Jaspr Web | 부모에 높이를 정해 두어도, `h-full`이나 내용에 높이를 맡긴 화면의 내용이 더 길면 숨은 화면이어도 모든 화면의 칸이 그 길이까지 늘어 부모를 넘칩니다. 보이는 화면이 짧아도 같습니다. 화면의 가장 바깥 요소를 `h-full overflow-y-auto`로 만들어도 늘어난 높이를 받아 그 안에서 스크롤하지 않습니다. 그래서 바깥 상자에서 스크롤하게 되면 스크롤 위치가 화면마다 따로 남지 않습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

Flutter와 Jaspr Web은 같은 `children` · `index` · `indexedSwitcherStyle`과 같은 전환 순서 · 기본 시간 · 곡선을 씁니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 화면을 두는 방법 | `Stacks` 안에 화면마다 같은 래퍼를 둡니다. | 루트 격자(`grid`)의 한 칸에 화면마다 `<div>`를 겹쳐 둡니다. |
| 숨은 화면 | 그리지 않지만 크기는 잽니다. | `visibility: hidden`과 `inert`를 붙입니다. 자리를 차지하고 문서에 남습니다. |
| 서버 렌더 | — | 모든 화면의 마크업이 문서에 들어갑니다. |
| 전환이 도는 때 | 위젯의 `index`가 바뀔 때 | CSS transition이라, 브라우저에서 같은 IndexedSwitcher의 `index`가 바뀔 때만 돕니다. 문서를 새로 불러오는 이동이나 서버에서만 그리는 컴포넌트에서는 돌지 않습니다. |
| 전환 중에 한 번 더 바꿀 때 | 직전까지 보여 주던 화면 하나만 이어서 흐려집니다. 그보다 앞서 흐려지던 화면은 바로 사라지고, 그 화면으로 되돌아가면 0에서부터 나타납니다. | 화면마다 CSS transition이라, 지금 진하기에서 이어 갑니다. |
| 크기 | 부모가 크기를 강제하지 않으면 가장 큰 화면의 크기입니다. 부모의 최대 높이가 정해져 있으면 화면도 그 안에 놓여, 긴 `ListView`는 그 안에서 스크롤합니다. | `h-full`이라 부모에 정해진 높이가 있으면 채우고, 블록 배치에서는 부모 폭을 채웁니다. 높이를 길이로 정하지 않은 화면의 내용이 부모보다 길면(숨은 화면 포함) 부모를 넘치고, 화면 안의 `h-full` 스크롤이 생기지 않습니다. |
| 작은 화면의 자리 | 자기 크기로 시작 쪽 위에 놓입니다. | 화면의 `<div>`는 루트의 칸 전체를 씁니다. 그 안에서 폭을 정하지 않은 블록 요소는 칸의 폭까지 늘어납니다. |
| 앞 화면에 있던 포커스 | 같은 `FocusScope`에서 앞서 포커스를 받은 컨트롤 가운데 지금 받을 수 있는 것으로 돌아갈 수 있습니다. | 다른 컨트롤로 옮기는 처리가 없습니다. |
| 동작 줄이기 | Android의 애니메이션 끄기(`disableAnimations`)와 iOS의 동작 줄이기 설정을 읽습니다. `disableAnimations`가 켜지면 500ms보다 긴 시간도 Flutter가 원래의 5%로 줄이고, iOS의 동작 줄이기에서는 그대로입니다. | 브라우저의 `prefers-reduced-motion`을 따릅니다. 500ms보다 긴 시간은 그대로입니다. |
| 라우터 | go_router의 `StatefulShellRoute`에서 갈래를 담는 틀로 씁니다. | go_router는 Flutter 패키지입니다. Web 앱은 자기 라우터의 상태로 `index`를 넘깁니다. |
| 웹 전용 속성 | — | `id` · `classes` · `css` · `attributes` · `eventHandlers`(루트 `<div>`에 붙습니다) |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. `W`는 Flutter의 `Widget`, Jaspr Web의 `Component`입니다. 콜백은 없습니다. `index`는 바깥에서 관리합니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `children` | `List<W>` | 필수 | 오갈 화면. 모두 만들어 둔 채로 두고 `index`의 화면만 보여 줍니다. |
| `index` | `int` | `0` | 보여 줄 화면의 순번(0부터). 범위를 벗어나면 아무 화면도 보이지 않습니다. |
| `indexedSwitcherStyle` | `CoreIndexedSwitcherStyle?` | `null` | 이 인스턴스의 전환 시간과 곡선 |

Jaspr Web은 루트 `<div>`에 붙는 `id` · `classes` · `css` · `attributes` · `eventHandlers`도 받습니다.

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreIndexedSwitcherStyle patch)` | `indexedSwitcherStyle`에 `patch`를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch`가 이깁니다. |
| `copyWith({key, index, indexedSwitcherStyle, children})` | 바꾼 값으로 사본을 만듭니다. Jaspr Web은 `id` · `classes` · `css` · `attributes` · `eventHandlers`도 받습니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.indexedSwitcher` | `CoreIndexedSwitcherTheme?` | 앱 전체 기본값. `style`(`CoreIndexedSwitcherStyle?`) 하나를 가집니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreIndexedSwitcherStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `exitDuration` | `Duration?` | How long the outgoing view takes to fade out. |
| `enterDuration` | `Duration?` | How long the incoming view takes to fade in, once the outgoing view is gone. |
| `exitCurve` | `CoreCubicBezier?` | Easing of the fade-out, as cubic-bezier control points. |
| `enterCurve` | `CoreCubicBezier?` | Easing of the fade-in, as cubic-bezier control points. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="indexed-switcher/related-switcher" title="Switcher">

순서가 있는 보기를 밀어 넘깁니다. [Switcher 문서](/components/switcher)

</Card>
<Card demo="indexed-switcher/related-navigation-bar" title="NavigationBar">

최상위 화면을 고르는 하단 바 · 레일입니다. [NavigationBar 문서](/components/navigation-bar)

</Card>
<Card demo="indexed-switcher/related-tabs" title="Tabs">

라벨로 보기를 고르는 탭 바입니다. [Tabs 문서](/components/tabs)

</Card>
</Cards>
