---
title: Tabs
description: 같은 맥락의 내용을 여러 보기로 나눌 때, 보여 줄 보기를 고르는 탭 바입니다. pill과 underline 두 모양과 세 가지 크기가 있습니다.
category: navigation
platforms: [flutter, web]
related: [accordion, tab-pane, navigation-bar]
tags: [interactive, panel, switching]
template: v2
source: navigation/tabs
---

# Tabs

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 탭 바를 확인하고, 만들어진 코드를 그대로 복사하세요. 탭을 눌러 선택을 바꾸고, 닫기 버튼으로 탭을 닫아 볼 수 있습니다.

<Playground component="tabs" />

`Tabs`는 선택된 탭을 스스로 기억하지 않습니다. 지금 선택된 탭의 인덱스(0부터 셉니다)를 `selectedIndex`로 넘기고, `onChanged`가 알려 주는 새 인덱스로 바꿔 다시 그립니다. `Tabs`는 탭 바만 그리므로, 고른 탭에 맞는 내용은 호출하는 쪽이 바 아래에 그립니다.

```dart
Tabs(
  tabs: const [
    CoreTabItem(label: '계정'),
    CoreTabItem(label: '비밀번호'),
  ],
  selectedIndex: index,
  onChanged: (i) => setState(() => index = i),
)
```

라벨 문자열만 있으면 `Tabs.labels`로 줄여 쓸 수 있습니다. 나머지 속성은 같습니다.

```dart
Tabs.labels(
  labels: const ['계정', '비밀번호'],
  selectedIndex: index,
  onChanged: (i) => setState(() => index = i),
)
```

<a id="구조-anatomy"></a>

## 구조

탭 바는 탭을 늘어놓은 목록과, 선택된 탭을 알리는 지시자로 이루어집니다. 탭 하나는 라벨을 갖고, 필요하면 배지와 닫기 버튼을 더합니다.

<Anatomy demo="tabs/anatomy">
<AnatomyItem part="container" name="Container">

탭 목록 전체. pill은 둥근 트랙을 채우고, underline은 아래 선을 그립니다.

</AnatomyItem>
<AnatomyItem select="span:has(> [aria-selected=true])" name="indicator">

선택된 탭을 알리는 지시자. pill은 트랙보다 한 단 밝은 칩, underline은 탭 아래의 밑줄입니다.

</AnatomyItem>
<AnatomyItem select="[role=tab] > span > span:first-child" name="label">

탭 이름. 필수이며 접근 가능한 이름이 됩니다.

</AnatomyItem>
<AnatomyItem select="[role=tab] > span > span:last-child" name="badge">

라벨 뒤의 배지 슬롯. 선택 사항입니다.

</AnatomyItem>
<AnatomyItem select="button" name="onClose">

라벨과 배지 뒤의 닫기 버튼. `onClose`를 주면 생깁니다.

</AnatomyItem>
</Anatomy>

<a id="변형-variants"></a>

## Variant

탭 바가 놓일 자리에 따라 두 가지 중 하나를 고릅니다.

<a id="필-탭-default"></a>

<VariantRow name="pill" component="tabs" props="variant=pill">

기본 모양입니다. 둥근 트랙(`surfaceContainer`) 안에서 선택된 탭을 한 단 밝은 칩(`surfaceRaised`)으로 띄웁니다. Light에서는 흰 칩, Dark에서는 트랙보다 밝은 칩입니다.

</VariantRow>

<a id="라인-탭"></a>

<VariantRow name="underline" component="tabs" props="variant=underline">

트랙 없이 탭을 늘어놓고, 바 아래에 선(`outlineSubtle`)을 그어 내용과 나눕니다. 선택된 탭 아래에는 `primary` 밑줄을 그립니다. 아래 선은 탭 바 상자의 것이라 `expand: false`여도 부모가 준 폭 전체에 그려지고, 탭은 글이 시작하는 쪽에 붙습니다.

</VariantRow>

<Note>

탭과 내용 패널을 한 상자로 묶거나 탭을 끌어 순서를 바꾸려면 별도 컴포넌트인 [TabPane](/components/tab-pane)을 씁니다. TabPane은 `CoreTabItem`의 `content`를 패널로 그리고, `reorderable`과 자기 스타일 `CoreTabPaneStyle`을 가집니다.

</Note>

## 크기

바의 바깥 높이를 세 단계 중 하나로 고릅니다. 기본 밀도에서는 같은 크기의 Button · TextField와 한 줄에 놓으면 높이가 맞습니다. 탭 높이는 밀도(`CoreDensity`)를 따라 움직이지 않으므로, compact · spacious에서는 높이가 바뀌는 Button · TextField와 달라집니다. 라벨 글자 크기도 단계에 맞춰 함께 바뀝니다.

<SizeSpec component="tabs" />

pill은 트랙이 단계 높이에 서고, 탭은 트랙 안쪽 여백(`tabBarPadding`)의 위아래를 뺀 높이입니다. underline은 트랙이 없어 탭이 단계 높이입니다. 단계가 트랙의 높이인지 탭의 높이인지는 변형별 기본값의 `sizeRungIsTrack`이 정합니다(pill `true`, underline `false`). 라벨 글자 크기는 두 변형이 같고, 두 변형 모두 선택된 탭의 라벨이 한 단계 굵습니다.

<Note>

`size`의 타입은 `CoreTabsSize`(sm · md · lg)입니다. Button의 `CoreComponentSize`와 다른, 이 컴포넌트만의 세 단계입니다. `size`는 위젯 속성으로만 고르고 테마로는 바꿀 수 없습니다. 높이 자체는 `tabsStyle`의 `itemHeight`로 덮어쓸 수 있고, 그러면 pill의 트랙이 그 높이에 섭니다. `tabBarPadding`을 바꾸면 탭이 그만큼 줄거나 늘고 트랙 높이는 그대로입니다.

</Note>

## 배지와 닫기 버튼

탭 하나에 숫자 배지와 닫기 버튼을 더할 수 있습니다. 두 플랫폼이 같은 모양으로 그리고, 두 변형도 같은 자리에 둡니다.

<a id="배지-탭"></a>

### 배지

`CoreTabItem`의 `badge`에 `Badge`를 넘기면 라벨 뒤에 그려집니다.

<Preview demo="tabs/badge" />

```dart
Tabs(
  tabs: const [
    CoreTabItem(
      label: '받은편지함',
      badge: Badge(
        variant: CoreBadgeVariant.filled,
        form: CoreBadgeForm.count,
        size: CoreComponentSize.xs,
        child: Text('3'),
      ),
    ),
    CoreTabItem(label: '보낸편지함'),
  ],
  selectedIndex: index,
  onChanged: (i) => setState(() => index = i),
)
```

배지는 호출자가 다 만들어 넘기는 위젯 슬롯이라 자기 색을 직접 칠하고, 라벨 색을 물려받지 않습니다. 라벨과의 간격만 `CoreTabsStyle`의 `labelBadgeGapStyle`(기본 `CoreSpace.space6`)이 정합니다. 배지가 없는 탭에는 간격도 생기지 않습니다. TabPane은 자기 간격(`CoreTabPaneStyle`의 `labelBadgeGapStyle`)을 따로 가집니다.

<a id="닫을-수-있는-탭"></a>

### 닫기 버튼

`CoreTabItem`의 `onClose`를 넘기면 라벨과 배지 뒤에 닫기 버튼이 그려집니다. 열린 파일처럼 사용자가 목록에서 빼는 탭에 씁니다.

<Preview demo="tabs/closable" />

```dart
Tabs(
  tabs: [
    for (final (i, file) in openFiles.indexed)
      CoreTabItem(label: file, onClose: () => close(i)),
  ],
  selectedIndex: index,
  onChanged: (i) => setState(() => index = i),
)
```

| 항목 | 동작 |
| --- | --- |
| 선택과의 관계 | 닫기 버튼은 탭을 고르는 영역 밖에 있어, 눌러도 `onChanged`가 불리지 않고 `onClose`만 불립니다. |
| 목록에서 빼기 | `Tabs`는 탭을 지우지 않습니다. 목록에서 그 항목을 빼고 `selectedIndex`를 고치는 것은 호출자의 일입니다. |
| 모양 | `Button(variant: .ghost)`입니다. 상자는 `closeButtonStyle`(24 × 24, 안쪽 여백 0, 모서리 6), 글리프는 `closeIconStyle`(12, `onSurfaceSubtle`)이 정합니다. |
| 간격 | 라벨 · 배지와의 간격은 배지와 같은 `labelBadgeGapStyle`입니다. |
| Hover · Pressed | 상태 레이어가 닫기 버튼까지 포함한 탭 상자 전체에 덮입니다. |
| 비활성 탭 | 닫기 버튼은 흐려지지 않고 그대로 동작합니다. 탭을 고르는 영역 밖이라 탭의 비활성 상태가 닿지 않습니다. |
| 이름 | 아이콘만 있는 버튼이라, 렌더할 때의 언어로 된 닫기 문구가 접근 가능한 이름이 됩니다. |

`onClose`가 없는 탭은 모양이 바뀌지 않습니다. 닫기 버튼을 탭을 고르는 영역 밖에 두는 규칙은 TabPane과 같습니다.

<a id="동작-스펙-behavior"></a>
<a id="비활성화-탭"></a>
<a id="상태-레이어-hover-pressed"></a>

## 상태

탭은 선택 여부와 활성 여부에 따라 모양이 바뀝니다.

<Preview demo="tabs/states" />

| 항목 | 동작 |
| --- | --- |
| 선택됨 | pill은 칩을, underline은 밑줄을 그립니다. 라벨은 `onSurface` · SemiBold입니다. |
| 기본 | 라벨은 `onSurfaceSubtle` · Medium입니다. |
| Hover · Pressed | 활성 탭 위에 `onSurface` 8% · 16% 상태 레이어를 덮습니다. 비활성 탭에는 덮지 않습니다. |
| Focus | 키보드로 포커스하면 링이 나타납니다. pill의 링은 칩 모서리(`activeIndicatorRadius`)를 따르고, underline의 링은 각집니다. |
| 비활성 | 라벨을 `disabledContent` 색으로 그리고, 탭을 고르는 영역이 `clickableStyle`의 비활성 불투명도(기본 50%)로 한 번 더 흐려집니다. 닫기 버튼이 없는 탭은 탭 상자 전체가, 있는 탭은 라벨과 배지 쪽만 흐려집니다. 눌러도 선택되지 않습니다. |
| 선택된 탭이 비활성 | 어느 탭이 지금 탭인지는 계속 보이도록 지시자를 남기고 색만 바꿉니다. pill의 칩은 `disabledContainer`, underline의 밑줄은 `disabledContent`입니다. |
| `onChanged`가 없을 때 | 모든 탭이 비활성으로 그려집니다. |
| 전환 시간 | 지시자와 탭 상자는 `indicatorTransitionDuration`(기본 `CoreDuration.instant`, 100ms) 동안 바뀝니다. 동작 줄이기 설정에서는 바로 바뀝니다. |

Hover와 Pressed는 Flutter에서는 탭의 `Clickable`이, 웹에서는 CSS `:hover` · `:active`가 감지합니다. 닫기 버튼이 있는 탭은 탭 상자에서 감지합니다.

### 탭 전환

- 탭을 누르면 `onChanged`가 그 탭의 인덱스로 불립니다. 화면은 호출자가 `selectedIndex`를 바꿔 다시 그릴 때 바뀝니다.
- 닫기 버튼을 누르면 `onClose`만 불리고 `onChanged`는 불리지 않습니다.
- 탭을 바꿔도 포커스는 방금 누른 탭에 남습니다.

### 스와이프

- `swipeable: true`(기본값)이면 탭 바를 좌우로 밀어 이웃한 탭으로 옮깁니다. 비활성 탭은 건너뛰고, 오른쪽에서 왼쪽으로 쓰는 언어에서는 방향이 반대입니다.
- `scrollable: true`이거나 `onChanged`가 없으면 스와이프로 탭이 바뀌지 않습니다.
- 기준값은 `tabsStyle`의 `swipeSensitivity`(기본 20)인데, 두 플랫폼이 다르게 읽습니다. Flutter는 손을 뗄 때의 가로 속도(초당 px), 웹은 터치로 움직인 가로 거리(px)를 이 값과 견줍니다. 웹은 세로보다 가로로 더 움직였을 때만, 그리고 터치에서만 넘어갑니다. 마우스로 끌어서는 넘어가지 않습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 언제 쓰나

- 관련된 내용을 여러 패널로 나눠 바꿔 볼 때
- 같은 맥락의 다른 보기를 보여 줄 때 (개요 · 상세 · 리뷰)
- 페이지를 옮기지 않고 내용을 바꿀 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 탭과 내용 패널을 한 상자로 묶고, 닫기 · 순서 바꾸기까지 할 때 | [TabPane](/components/tab-pane) |
| 앱의 주요 화면 사이를 오갈 때 (바 · 레일 · 사이드바) | [NavigationBar](/components/navigation-bar) |
| 모든 섹션을 한 페이지에서 펼치고 접을 때 | [Accordion](/components/accordion) |
| 내용 패널 없이 값 하나를 고를 때 | [RadioGroup](/components/radio-group) |
| 패널 없이 선택지 하나를 고르는 것이 목적일 때 | [Select](/components/select) |
| 자유로운 보기를 밀어서 넘길 때 | [Switcher](/components/switcher) |
| 고르는 값 없이 공간을 따라 포커스만 옮길 때 | [Subfocus](/components/subfocus) |
| 위쪽 드롭다운 내비게이션 | [NavigationMenu](/components/navigation-menu) |
| 번호로 데이터 페이지를 넘길 때 | [Pagination](/components/pagination) |

`Tabs`는 `CoreTabItem`의 `content`를 그리지 않습니다. 탭과 패널을 함께 그려야 하면 TabPane을 씁니다.

### 라벨과 묶음

<Cards columns="2">
<Card demo="tabs/do-short-labels" tone="do" eyebrow="이렇게 하세요">

탭 라벨은 한두 단어로 짧고 분명하게 씁니다.

</Card>
<Card demo="tabs/dont-long-labels" tone="dont" eyebrow="이렇게 하지 마세요">

긴 라벨은 탭 바를 넓히고 훑어보기 어렵게 합니다.

</Card>
<Card demo="tabs/do-related" tone="do" eyebrow="이렇게 하세요">

설정처럼 같은 맥락의 하위 분류를 탭으로 나눕니다.

</Card>
<Card demo="tabs/dont-unrelated" tone="dont" eyebrow="이렇게 하지 마세요">

서로 관계없는 기능은 탭이 아니라 별도 화면으로 나눕니다.

</Card>
</Cards>

## 배치

<Cards columns="2">
<Card demo="tabs/placement-expand" title="가로 채우기">

폭이 정해진 자리에서는 `expand: true`로 탭을 같은 폭으로 나눠 가로를 채웁니다.

</Card>
<Card demo="tabs/placement-underline" title="내용 위의 탭 바">

고른 탭의 내용은 탭 바 바로 아래에 둡니다. underline의 아래 선은 탭이 차지하지 않은 폭까지 이어집니다.

</Card>
</Cards>

## 긴 번역과 확대 글자

폭이 정해진 부모 안에서 `scrollable: true`를 쓰면 각 탭이 라벨, 배지, 닫기 버튼에 필요한 폭을 지키고 가로로 스크롤합니다. Flutter와 웹 모두 `Tabs`, `Tabs.labels`, `copyWith`에 같은 속성이 있습니다.

<Preview demo="tabs/scrollable" />

```dart
Tabs.labels(
  labels: const ['계정 및 개인정보 설정', '알림 및 접근성 환경설정'],
  selectedIndex: selectedIndex,
  onChanged: onChanged,
  scrollable: true,
)
```

- 이 모드에서는 `expand`를 함께 지정해도 탭을 같은 폭으로 나누지 않습니다.
- 가로로 끄는 동작은 스크롤에 쓰이므로 `swipeable`로 탭을 바꾸는 기능은 멈춥니다.
- 키보드 포커스와 `Enter` · `Space` 선택은 그대로입니다. 포커스가 화면 밖의 탭으로 가면 그 탭이 보이도록 스크롤합니다. Flutter는 `Tabs`가, 웹은 브라우저가 스크롤합니다.
- 기본값 `false`에서는 폭 · 모양 · 스와이프 동작이 그대로입니다.

긴 라벨을 `expand`만으로 나누면 라벨이 차지하는 폭이 나눠 받은 폭보다 클 수 있습니다. 좁은 화면에서는 스크롤 모드를 쓰세요.

<a id="스타일-시스템-style-system"></a>
<a id="테마-설정"></a>

## 테마와 스타일

variant와 size는 위젯 속성으로 고르고, 색 · 여백 · 높이처럼 보이는 값은 `tabsStyle`로 덮어씁니다. `tabs` · `selectedIndex` · `onChanged` · `expand` · `swipeable`처럼 내용과 동작은 위젯 속성으로 넘깁니다.

<Split>

<Code language="dart" title="탭 바 하나만 바꾸기">
Tabs(
  tabs: const [
    CoreTabItem(label: '계정'),
    CoreTabItem(label: '비밀번호'),
  ],
  selectedIndex: index,
  onChanged: (i) => setState(() => index = i),
  tabsStyle: const CoreTabsStyle(
    tabPadding: CoreEdgeInsets.symmetric(
      horizontal: CoreSpace.space16,
    ),
    tabSpacing: CoreSpace.space8,
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기 (coreComponentTheme)">
CoreComponentTheme(
  tabs: CoreTabsTheme(
    style: CoreTabsStyle(
      tabSpacing: CoreSpace.space4,
    ),
    variantStyles: {
      CoreTabVariant.underline: CoreTabsStyle(
        activeIndicatorThickness: CoreStrokeWidth.stroke3,
      ),
    },
  ),
)
</Code>

</Split>

<a id="resolve-chain"></a>

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
CoreTabsStyle.defaultX / defaultsByVariant   // 디자인 시스템 기본값
  → CoreTabsTheme.style                      // 프로젝트 공통
  → CoreTabsTheme.variantStyles[variant]     // 프로젝트 variant 별
  → widget.tabsStyle                         // 인스턴스별
```

### 빠른 오버라이드 (Chain)

이미 만든 `Tabs` 인스턴스에 스타일을 빠르게 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `tabsStyle`과 같게 동작하지만, 이미 만든 위젯 위에서 바로 이어 쓸 수 있습니다. 나중에 이은 `withStyle`이 같은 필드에서 이깁니다.

`.surfaceContainer`처럼 Core 토큰 이름과 같은 이름의 짧은 getter도 있습니다. `withStyle`을 한 번 더 줄인 것이고, 이름이 곧 값이라(`.surfaceContainer`는 `CoreColors.surfaceContainer`) 어느 컴포넌트에서 써도 뜻이 같습니다. `Tabs`에서 이 getter는 `backgroundColor`, 곧 pill의 트랙 색을 바꿉니다. underline은 바를 채우지 않으므로 바뀌는 것이 없습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class TabsChainExample extends StatefulWidget {
  const TabsChainExample({super.key});

  @override
  State<TabsChainExample> createState() => _TabsChainExampleState();
}

class _TabsChainExampleState extends State<TabsChainExample> {
  static const _contents = [
    '계정 설정을 관리해요.',
    '여기에서 비밀번호를 바꿔요.',
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tabs(
              tabs: const [
                CoreTabItem(label: '계정'),
                CoreTabItem(label: '비밀번호'),
              ],
              selectedIndex: _index,
              onChanged: (i) => setState(() => _index = i),
            )
            .withStyle(
              const CoreTabsStyle(
                tabPadding: CoreEdgeInsets.symmetric(
                  horizontal: CoreSpace.space16,
                  vertical: CoreSpace.space8,
                ),
                containerRadius: CoreBorderRadius.all(CoreRadius.radius24),
                tabSpacing: CoreSpace.space8,
              ),
            )
            .surfaceContainer,
        const Gap.space16(),
        Text(_contents[_index]).bodyMedium.onSurface,
      ],
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class TabsChainExample extends StatefulComponent {
  const TabsChainExample({super.key});

  @override
  State<TabsChainExample> createState() => _TabsChainExampleState();
}

class _TabsChainExampleState extends State<TabsChainExample> {
  static const _contents = [
    '계정 설정을 관리해요.',
    '여기에서 비밀번호를 바꿔요.',
  ];

  int _index = 0;

  @override
  Component build(BuildContext context) {
    return div(
      [
        Tabs(
              tabs: const [
                CoreTabItem(label: '계정'),
                CoreTabItem(label: '비밀번호'),
              ],
              selectedIndex: _index,
              onChanged: (index) => setState(() => _index = index),
            )
            .withStyle(
              const CoreTabsStyle(
                tabPadding: CoreEdgeInsets.symmetric(
                  horizontal: CoreSpace.space16,
                  vertical: CoreSpace.space8,
                ),
                containerRadius: CoreBorderRadius.all(CoreRadius.radius24),
                tabSpacing: CoreSpace.space8,
              ),
            )
            .surfaceContainer,
        Gap.space16(),
        Text(_contents[_index]).bodyMedium.onSurface,
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="접근성-accessibility"></a>

## 접근성

웹은 `role="tablist"` · `role="tab"`으로 탭 목록임을 알리고, Flutter는 탭을 선택 상태가 있는 버튼으로 알립니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 탭 목록은 역할도 이름도 없는 `Semantics(container: true)`입니다. 탭은 `Clickable`의 버튼 시맨틱 위에 `Semantics(button: true, selected:, enabled:)`가 붙어, 탭이 아니라 버튼으로 알려집니다. |
| Jaspr Web | 탭 목록은 `role="tablist"`, 탭은 `role="tab"`과 `aria-selected="true"` / `"false"`입니다. 비활성 탭에는 `aria-disabled="true"`가 붙습니다. |

`Tabs`는 탭 바만 그립니다. 탭에는 패널을 가리키는 `aria-controls`가 없고, `role="tabpanel"`은 패널을 함께 그리는 TabPane에 있습니다.

웹 루트의 `role`은 호출자가 넘긴 `attributes` 뒤에 쓰여 덮을 수 없지만, `aria-label`은 막지 않으므로 `attributes: {'aria-label': …}`로 탭 목록 이름을 붙일 수 있습니다.

```html
<div role="tablist">
  <div role="tab" aria-selected="true" tabindex="0">…계정…</div>
  <div role="tab" aria-selected="false" tabindex="-1">…비밀번호…</div>
  <div role="tab" aria-selected="false" tabindex="-1" aria-disabled="true">…알림…</div>
</div>
```

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` | 활성 탭마다 포커스가 멈춥니다. | 탭 목록 전체가 포커스 한 번입니다. 선택된 탭으로 들어갑니다. |
| `ArrowLeft` · `ArrowRight` | 탭 전용 이동이 없고, 앱의 기본 방향 포커스 이동을 따릅니다. | 이전 · 다음 탭으로 포커스를 옮기고, 끝에서는 반대쪽 끝으로 돌아갑니다. |
| `Home` · `End` | 없습니다. | 첫 탭 · 마지막 탭으로 포커스를 옮깁니다. |
| `Enter` · `Space` | 포커스된 탭을 고릅니다. | 포커스된 탭을 고릅니다. |

<Note>

웹은 탭 목록의 수동 선택 방식을 따릅니다. 화살표는 포커스만 옮기고, 탭은 `Enter`나 `Space`로 고릅니다. 비활성 탭에도 화살표로 닿지만 고를 수는 없습니다. TabPane도 같은 키를 따릅니다.

</Note>

웹의 키보드 이동은 매일 밤 문서 사이트를 실제 브라우저로 열고 키를 눌러, 포커스가 기대한 탭으로 옮겨 갔는지 확인합니다(`tool/parity/keyboard_probe.dart`).

### 스크린 리더

- 접근 가능한 이름은 `CoreTabItem`의 `label`에서 옵니다. 필수 파라미터라 이름 없는 탭이 생기지 않습니다.
- 선택 상태는 Flutter `selected: true`, 웹 `aria-selected="true"`로 알립니다. Flutter는 역할이 버튼이라 "선택된 버튼"으로, 웹은 "선택된 탭"으로 읽혀 문구가 다릅니다.
- 비활성 탭(`enabled: false`이거나 `onChanged`가 없을 때)은 Flutter `enabled: false`, 웹 `aria-disabled="true"`로 알립니다.
- 닫기 버튼은 탭과 따로 읽히는 버튼입니다. 렌더할 때의 언어로 된 닫기 문구가 이름이 됩니다(Flutter `Semantics(label:)`, 웹 `aria-label`).
- 탭 목록 자체에는 두 플랫폼 모두 기본 이름이 없습니다. 웹은 `aria-label`을 붙이고, Flutter는 바깥을 `Semantics`로 감쌉니다.
- 스와이프나 다른 코드로 `selectedIndex`가 바뀌어도 그 변화는 따로 알리지 않습니다.

### 포커스 관리

- 오버레이가 아니므로 마운트될 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. `Tab`은 마지막 탭을 지나 바깥으로 나갑니다.
- 포커스가 멈추는 횟수는 Flutter가 활성 탭마다 한 번, 웹이 탭 목록 전체에 한 번입니다. Flutter의 비활성 탭은 포커스를 받지 않습니다.
- 닫기 버튼은 두 플랫폼 모두 탭과 따로 포커스가 멈추는 곳입니다. 웹의 화살표 이동에는 들어가지 않습니다.
- `onChanged`는 선택만 바꾸고, 포커스는 방금 누른 탭에 남습니다.
- 포커스 링은 탭의 `Clickable`이 그립니다(Flutter `FocusOutline`, 웹 `:focus-visible`). 키보드로 포커스했을 때만 나타납니다. 닫기 버튼이 있는 탭은 탭을 고르는 영역에 링이 그려집니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | 탭이 `tab` 역할로 알려지지 않습니다. 선택 상태는 전달되지만 "몇 개 중 몇 번째 탭" 같은 목록 정보는 전달되지 않고, 두 시맨틱 모두 컴포넌트 안에서 만들어져 호출부에서 바꿀 수 없습니다. |
| Flutter | 탭 전용 화살표 이동이 없습니다. 화살표는 프레임워크의 방향 이동이라 웹의 순환 · `Home` · `End`와 다릅니다. |
| Jaspr Web | 오른쪽에서 왼쪽으로 쓰는 언어에서도 `ArrowRight`가 다음 탭(인덱스 +1)으로 옮깁니다. 화면에서는 왼쪽 탭입니다. |
| 공통 | 탭이 내용 패널과 연결되어 있지 않아, 스크린 리더 사용자가 탭에서 패널로 바로 옮겨 갈 수 없습니다. 패널을 함께 그리는 TabPane을 쓰거나, 패널에 직접 `role="tabpanel"`과 이름을 붙입니다. |
| 공통 | 스와이프로 탭을 넘기는 길은 포인터 전용입니다. 키보드로는 대상 탭까지 포커스를 옮긴 뒤 `Enter` · `Space`로 고르면 됩니다. |
| 공통 | pill의 선택되지 않은 라벨(`onSurfaceSubtle`)은 트랙 위에서 CoUI Light 기준 4.26 : 1(Dark 4.71 : 1)로, 글자 대비 기준 4.5 : 1에 못 미칩니다. 선택은 칩이 알리므로 디자이너가 받아들인 예외입니다. |
| 공통 | 선택은 채움 · 밑줄과 굵기(선택 SemiBold, 나머지 Medium)로 구분합니다. 시스템이 색을 강제하는 모드에서 채움이 사라져도 굵기 차이는 남고, 선택 상태는 계속 알립니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 시맨틱 | 역할 없는 `Semantics(container: true)` 안의 버튼(`selected`) | `role="tablist"` · `role="tab"` · `aria-selected` |
| 키보드 이동 | 활성 탭마다 포커스, 화살표는 앱의 방향 포커스 이동 | 탭 목록에 포커스 한 번, 화살표 · `Home` · `End`로 탭 사이 이동 |
| 비활성 탭 | 포커스를 받지 않습니다. | 화살표로 닿고 `aria-disabled="true"`, 고를 수 없습니다. |
| 스와이프 | 가로 드래그를 놓을 때의 속도와 `swipeSensitivity`를 견줍니다. | 터치로 움직인 가로 거리와 `swipeSensitivity`를 견줍니다. 마우스 드래그로는 넘어가지 않습니다. |
| 가로 스크롤 (`scrollable`) | `SingleChildScrollView`. 포커스된 탭이 보이도록 `Tabs`가 스크롤합니다. | `overflow-x: auto`. 포커스된 탭은 브라우저가 보이도록 스크롤합니다. |
| 탭 높이 | 단계 높이가 하한이라, 글자가 커지면 탭이 자랍니다. | 단계 높이로 고정합니다. `scrollable: true`일 때만 하한입니다. |
| Hover · Pressed 감지 | 탭의 `Clickable`. 닫기 버튼이 있는 탭은 상자의 `MouseRegion` · `Listener`. | CSS `:hover` · `:active`. 닫기 버튼이 있는 탭은 상자에 붙습니다. |
| 탭 목록 이름 | 바깥을 `Semantics`로 감쌉니다. | `attributes: {'aria-label': …}` |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. `W`는 위젯 슬롯의 타입으로, Flutter에서는 `Widget`, 웹에서는 `Component`입니다.

### Tabs 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `tabs` | `List<CoreTabItem<W>>` | 필수 | 탭 목록 |
| `selectedIndex` | `int` | 필수 | 선택된 탭의 인덱스. 0부터 셉니다. |
| `onChanged` | `CoreValueChanged<int>?` | `null` | 탭을 고를 때 새 인덱스로 불립니다. 없으면 모든 탭이 비활성입니다. |
| `variant` | `CoreTabVariant` | `pill` | pill, underline |
| `size` | `CoreTabsSize` | `md` | sm, md, lg. 테마로는 바꿀 수 없습니다. |
| `expand` | `bool` | `false` | 탭을 같은 폭으로 나눠 가로를 채웁니다. |
| `scrollable` | `bool` | `false` | 라벨 폭을 지키며 가로로 스크롤합니다. `expand`보다 우선하고, 스와이프로 탭을 바꾸는 기능을 멈춥니다. |
| `swipeable` | `bool` | `true` | 좌우로 밀어 탭을 바꿉니다. |
| `tabsStyle` | `CoreTabsStyle?` | `null` | 보이는 값 덮어쓰기 |

`Tabs.labels`는 `tabs` 대신 문자열 목록 `labels`를 받아 같은 탭 바를 만듭니다. 웹은 HTML 속성을 위한 `id` · `classes` · `css` · `attributes` · `eventHandlers`도 받습니다.

<a id="coretabitem"></a>

### CoreTabItem 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String` | 필수 | 탭 이름. 접근 가능한 이름이 됩니다. |
| `enabled` | `bool` | `true` | `false`면 고를 수 없는 비활성 탭입니다. |
| `badge` | `W?` | `null` | 라벨 뒤의 배지 |
| `onClose` | `CoreVoidCallback?` | `null` | 지정하면 닫기 버튼을 그립니다. 눌러도 `onChanged`는 불리지 않습니다. |
| `content` | `W?` | `null` | 내용 패널. TabPane의 `boxed` 변형만 그립니다. `Tabs`는 무시합니다. |
| `leading` | `W?` | `null` | 라벨 앞 위젯. TabPane만 그립니다. |
| `trailing` | `W?` | `null` | 라벨 · 배지 뒤 위젯. TabPane만 그리고, 탭을 고르는 영역 밖에 두어 그 안의 버튼을 눌러도 `onChanged`가 불리지 않습니다. 닫기에는 `onClose`를 권장합니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreTabsStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Tab-bar row background colour. `null` → variant default. |
| `activeIndicatorColor` | `CoreColor?` | Active-indicator (pill fill / underline) colour. `null` → variant default. |
| `activeIndicatorRadius` | `CoreBorderRadius?` | Active-indicator border radius. `null` → token default. |
| `activeIndicatorThickness` | `double?` | Active-indicator (underline) thickness (logical px). `null` → token default. |
| `borderColor` | `CoreColor?` | Tab/content separator border colour (underline variant). `null` → variant default. |
| `borderWidth` | `double?` | Tab/content separator border thickness (logical px; underline variant). `null` → token default. |
| `activeContentColor` | `CoreColor?` | Active tab content colour. `null` → token default. |
| `inactiveContentColor` | `CoreColor?` | Inactive tab content colour. `null` → variant default. |
| `tabBarPadding` | `CoreEdgeInsets?` | Tab-bar container padding. `null` → variant default. Only the `pill` track applies it; the `underline` bar has no container inset. |
| `tabPadding` | `CoreEdgeInsets?` | Per-tab button padding. `null` → variant default. |
| `containerRadius` | `CoreBorderRadius?` | Tab-bar container corner radius. `null` → token default. Applies only to the `pill` variant. |
| `indicatorTransitionDuration` | `Duration?` | Active-indicator colour-transition duration. `null` → token default ([defaultIndicatorTransitionDuration]). |
| `swipeSensitivity` | `double?` | Minimum horizontal swipe speed that switches the tab, in logical px per second. It is a speed, not a layout size, so it is used unscaled. `null` → token default ([defaultSwipeSensitivity]). |
| `tabSpacing` | `double?` | Space between adjacent tab buttons (logical px). `null` → the variant row's [CoreTabVariantStyle.tabSpacing], then [defaultTabSpacing]. |
| `itemHeight` | `double?` | The bar's size rung (logical px). `null` → the widget's `size`-keyed entry in [defaultsBySize]. A `pill` bar draws its track at this height and each tab at it less [tabBarPadding]'s top and bottom; an `underline` bar draws each tab at it — see [defaultsBySize]. Distinct from `CoreTabPaneStyle.defaultBarHeight` (the surrounding `TabPane` bar container). |
| `disabledContentColor` | `CoreColor?` | Label / indicator colour when a tab item is disabled (`CoreTabItem.enabled == false`). `null` → token default ([defaultDisabledContentColor]). |
| `hoverStateLayerColor` | `CoreColor?` | Hover state-layer colour, laid over the tab item while the pointer is over it (and the item is enabled). `null` → token default ([defaultHoverStateLayerColor]). |
| `pressedStateLayerColor` | `CoreColor?` | Pressed state-layer colour. `null` → token default ([defaultPressedStateLayerColor]). |
| `contentTextStyle` | `CoreTextStyle?` | Content / tab-label text style override. `null` → the variant row's [CoreTabVariantStyle.contentTextStyle] where it states one, else the widget's `size`-keyed entry in [defaultsBySize], which varies by rung (one label role per rung, `md` being [defaultContentTextStyle]) — not a single flat default. A `fontWeight` stated here wins over the variant row's per-selection weights. |
| `clickableStyle` | `CoreClickableStyle?` | Style for each tab's `Clickable` — press scale, durations, focus ring, disabled opacity. Laid over [defaultClickableStyle] and passed to the `Clickable` as is; it fills the unset fields with its own defaults. |
| `labelBadgeGapStyle` | `CoreGapStyle?` | Gap between a tab's label and its `CoreTabItem.badge`. `null` → token default ([defaultLabelBadgeGapStyle]). Laid over that default and passed to the tab's `Gap` as is. The same gap separates the label (and badge) from the close button. |
| `closeButtonStyle` | `CoreButtonStyle?` | Style for the close button a tab draws after its label and badge when given `CoreTabItem.onClose`. Laid over [defaultCloseButtonStyle] and passed to that `Button` as is; it fills the unset fields with its own defaults. |
| `closeIconStyle` | `CoreIconStyle?` | Style for the close glyph. Laid over [defaultCloseIconStyle] and passed to its `Icon` as is. |

### `CoreTabsStyle` 변형별 기본값 (`CoreTabVariantStyle`)

| 필드 | `pill` | `underline` |
|------|------|------|
| `activeIndicatorColor` | surfaceRaised | primary |
| `disabledIndicatorColor` | disabledContainer | disabledContent |
| `inactiveContentColor` | onSurfaceSubtle | onSurfaceSubtle |
| `tabBarPadding` | CoreEdgeInsets.all(CoreSpace.space2) | zero |
| `tabPadding` | CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12) | zero |
| `backgroundColor` | surfaceContainer | — |
| `activeFontWeight` | semiBold | semiBold |
| `inactiveFontWeight` | medium | medium |
| `tabSpacing` | space2 | space20 |
| `sizeRungIsTrack` | true | false |
| `borderColor` | — | outlineSubtle |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="tabs/related-tab-pane" title="TabPane">

탭과 내용 패널을 한 상자로 묶고, 닫기와 순서 바꾸기를 더합니다.

</Card>
<Card demo="tabs/related-accordion" title="Accordion">

모든 섹션을 한 페이지에 두고 펼치고 접습니다.

</Card>
<Card demo="tabs/related-navigation-bar" title="NavigationBar">

앱의 주요 화면 사이를 오갑니다.

</Card>
</Cards>
