---
title: ThemeController
description: 팔레트 색상 프리뷰가 있는 테마 스와치를 그리드로 표시하는 통합 테마 선택 컴포넌트
category: control
platforms: [flutter, web]
related: [toggle, select]
tags: [theme-controller, theme, picker, swatch]
template: v2
source: control/theme_controller
---

# ThemeController

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

크기 · 팔레트 색 수 · 테마 수 · 잠금을 바꿔 보며 테마 선택기를 확인하고, 만들어진 코드를 그대로 복사하세요. 미리보기의 원을 누르면 선택이 옮겨 갑니다.

<Playground component="theme-controller" />

`ThemeController` 는 고른 테마를 앱에 적용하지도, 선택을 스스로 바꾸지도 않습니다. 원을 누르면 그 테마의 `name` 을 `onThemeChanged` 로 알립니다. 호출자가 앱의 테마를 바꾸고 그 이름을 `selectedTheme` 으로 다시 넘겨야 선택이 옮겨 갑니다. 이미 고른 원을 다시 눌러도 같은 이름으로 다시 알립니다.

```dart
ThemeController(
  selectedTheme: selected,
  onThemeChanged: (name) => setState(() => selected = name),
  themes: const [
    CoreThemeOption(
      name: '오션',
      primaryColor: CoreColor.fromRGB(14, 165, 233),
      secondaryColor: CoreColor.fromRGB(99, 102, 241),
    ),
    CoreThemeOption(
      name: '숲',
      primaryColor: CoreColor.fromRGB(34, 197, 94),
      secondaryColor: CoreColor.fromRGB(132, 204, 22),
    ),
  ],
)
```

Flutter 와 Jaspr Web 이 같은 코드를 씁니다.

## 구조

테마 선택기는 테마마다 스와치 하나를 줄바꿈 격자로 놓습니다. 스와치 하나는 원 버튼 · 간격 · 테마 이름을 위에서 아래로 쌓은 칸이고, 원 버튼은 팔레트 원을 둘러싸는 고리 자리입니다.

<Anatomy demo="theme-controller/anatomy">
<AnatomyItem part="container" side="right" name="grid">

스와치를 놓는 바깥 상자입니다. 채움과 테두리가 없습니다.

</AnatomyItem>
<AnatomyItem select=".co-theme-swatch-palette" side="top" name="palette">

테마의 색을 보여 주는 원입니다. 옵션이 가진 색 수만큼 나뉩니다.

</AnatomyItem>
<AnatomyItem select="[aria-pressed=true]" side="top" name="button">

누를 수 있는 원 버튼입니다. 바탕 없이 고리만 그립니다. 쉬는 동안에는 고른 스와치만 고리를 두릅니다.

</AnatomyItem>
<AnatomyItem part="label" side="left" name="label">

원 아래의 테마 이름(`CoreThemeOption.name`)입니다.

</AnatomyItem>
</Anatomy>

### 라벨

- 버튼 아래에 `labelGapStyle` 간격(6)을 두고 `name` 을 `labelStyle` 로 그립니다. 글자 역할은 크기마다 `labelSmall` · `labelMedium` · `labelLarge` 입니다.
- 글자색은 상태를 따릅니다. 고르지 않은 스와치는 `onSurfaceVariant`, 고른 스와치는 `onSurface`, 잠긴 스와치는 `disabledContent` 입니다.
- 스와치 하나의 높이는 버튼 + 간격 + 라벨 한 줄입니다. `md` 는 40 + 6 + `labelMedium` 한 줄입니다.
- 라벨은 버튼 밖에 있습니다. 눌리는 곳은 원 버튼(32 · 40 · 48)뿐이고, 이름을 눌러도 선택되지 않습니다.

## 팔레트 프리뷰

<Preview demo="theme-controller/palette" />

스와치는 원 하나를 옵션이 가진 색 수만큼 같은 폭의 세로 띠로 나눕니다. 순서는 `primaryColor` → `secondaryColor` → `accentColor` → `neutralColor` 이고, 글이 시작하는 쪽부터 놓입니다. 비워 둔 색은 건너뜁니다. 두 색이면 반원 두 개가 됩니다. 세 색 · 네 색도 띠의 폭은 같지만, 원으로 잘라 내므로 가운데 띠가 가장자리 띠보다 넓은 면적을 차지합니다.

색을 점으로 따로 늘어놓지 않고 한 원을 나눕니다. 그래서 스와치는 색 여러 개의 나열이 아니라 테마 하나로 읽히고, 색을 몇 개 넘기든 원의 크기는 `previewSize` 그대로입니다.

- 팔레트는 스타일이 아니라 데이터입니다. 색은 `CoreThemeOption` 으로 넘기고, 스타일은 원의 크기 · 모서리(`previewSize` · `previewBorderRadius`), 눌렀을 때 줄어드는 양(`pressedPreviewShrink`), 잠겼을 때의 채움(`disabledPreviewColor`)만 정합니다.
- `CoreColor.token(...)` 으로 넘긴 색은 지금 테마를 따라 바뀝니다. 위의 '모노' 가 그렇습니다. `CoreColor.fromRGB(...)` 처럼 값을 직접 넘긴 색은 어느 테마에서나 같습니다.
- 팔레트 원 자체는 색 표본이라 서페이스 스타일의 재질을 받지 않습니다. 원을 둘러싼 버튼은 Flutter 의 `liquidGlass` 에서 다르게 그려질 수 있습니다(→ 알려진 제약).

<a id="크기-sizes"></a>

## 크기

`size` 는 `CoreThemeControllerSize` 의 `sm` · `md`(기본) · `lg` 입니다. `CoreComponentSize` 가 아닌 이 컴포넌트만의 값입니다. 크기 하나가 버튼 · 팔레트 원 · 이름 글자를 함께 정합니다. 기본 서페이스 스타일과 표준 밀도에서 버튼은 어느 크기에서나 원(모서리가 한 변의 절반)이고, 팔레트 원은 버튼 안쪽 4 에 앉습니다. 폭 2 의 선택 고리와 팔레트 원 사이에는 2 의 틈이 남습니다.

<SizeSpec component="theme-controller" props="count=2" />

<Note>

- 스와치 한 칸의 최소 폭 `swatchMinWidth` 는 크기와 상관없이 48 입니다.
- 크기 표의 값은 `themeControllerStyle` 의 `buttonSize` · `buttonRadius` · `previewSize` · `buttonSpacing` · `labelGapStyle` · `labelStyle` 로 하나씩 바꿀 수 있습니다. `buttonSize` 만 바꾸면 모서리와 팔레트 원은 그대로입니다. 기본 모양을 지키려면 `buttonRadius`(한 변의 절반)와 `previewSize`(버튼보다 8 작게)도 함께 바꿉니다.
- 앱 밀도(`compact` · `spacious`)는 스와치 사이 12 를 8 · 16 으로, 버튼과 이름 사이 6 을 4 · 8 로 바꿉니다. 버튼 · 팔레트 원의 크기와 최소 칸 폭은 그대로입니다. `compact` 에서는 `sm` 버튼의 모서리가 14 로 줄어듭니다(→ 알려진 제약).
- `neoBrutalism` 서페이스 스타일은 버튼 모서리를 4 로 줄여 고리를 둥근 사각형으로 만들고, 고리 두께를 4 로 올립니다. 그러면 선택 고리와 팔레트 원 사이의 틈이 없어집니다. 팔레트 원은 원 그대로입니다.

</Note>

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 상태

variant 는 없습니다. `selectedTheme` 과 두 잠금(`ThemeController.enabled` · `CoreThemeOption.enabled`), 포인터와 키보드의 상호작용이 모양을 정합니다.

<Preview demo="theme-controller/states" />

| 상태 | 고리 | 팔레트 원 | 이름 글자 |
| --- | --- | --- | --- |
| 기본(고르지 않음) | 없음 | 옵션의 색 | `onSurfaceVariant` |
| Hover(고르지 않음) | `outlineVariant` 2 | 옵션의 색 | `onSurfaceVariant` |
| 눌림(고르지 않음) | `outlineVariant` 2 | 지름이 2 줄어듦 | `onSurfaceVariant` |
| 선택 | `onSurface` 2 | 옵션의 색 | `onSurface` |
| 선택 · 눌림 | `onSurface` 2 | 지름이 2 줄어듦 | `onSurface` |
| 비활성 | 없음 | `disabledContainer` 한 색 | `disabledContent` |
| 비활성 · 선택 | `disabledOutline` 2 | `disabledContainer` 한 색 | `disabledContent` |

표의 값은 `themeControllerStyle` 의 필드로 바꿉니다.

| 바꿀 것 | 필드 |
| --- | --- |
| 고른 스와치의 고리 | `selectedBorderColor` · `selectedBorderWidth` |
| 고르지 않은 스와치의 쉬는 고리 | `unselectedBorderColor` · `unselectedBorderWidth`(기본 0 — 그리지 않음) |
| hover · 눌림 고리 | `hoverBorderColor` · `hoverBorderWidth` |
| 눌릴 때 팔레트 원이 줄어드는 양 | `pressedPreviewShrink` |
| 잠긴 스와치 | `disabledBorderColor` · `disabledPreviewColor` · `disabledLabelColor` |
| 잠기지 않은 이름의 글자색 | `labelColor` · `selectedLabelColor` |

- 고른 스와치는 hover · 눌림에서도 선택 고리의 색과 두께가 그대로입니다.
- 누르는 동안에는 원 버튼 전체도 `Clickable` 의 눌림 효과로 0.97 배가 됩니다(100ms, 동작 줄이기를 켜면 바로). 고리 두께와 팔레트 원의 크기는 두 플랫폼 모두 바로 바뀝니다. 고리 색과 이름 글자색은 Flutter 에서는 바로 바뀌고, Jaspr Web 에서는 `CoUIWeb` 의 테마 전환(`enableThemeAnimation`, 기본 켜짐)을 타고 150ms 동안 바뀝니다(동작 줄이기를 켜면 바로).
- 키보드로 포커스한 스와치에는 `Clickable` 의 포커스 링이 생깁니다.
- 활성 스와치의 커서는 손 모양, 잠긴 스와치의 커서는 금지 모양입니다.

<Note>

CoUI 기본 색에서 `disabledContainer` 는 `surfaceContainer` 와 같은 색입니다. 그래서 `surfaceContainer` 로 채운 면(네이티브 문서 앱의 무대가 그렇습니다) 위에서는 잠긴 팔레트 원이 바탕에 묻혀 고리와 이름만 보입니다.

</Note>

<a id="선택-표시-배지-없이-고리로"></a>

### 선택 표시

선택 표시는 배지 없이 팔레트를 둘러싸는 고리와 이름 글자색입니다.

- 고리는 브랜드 색이 아니라 본문 글자색(`onSurface`)입니다. 안의 팔레트에 어떤 색을 넘겨도 고리가 읽혀야 하기 때문입니다.
- Jaspr Web 의 고리는 그림자가 아니라 CSS 테두리입니다. 그래서 색을 시스템 색으로 강제하는 화면(Windows 고대비 · forced-colors)에서도 시스템 테두리 색으로 남아, 고른 스와치를 다른 스와치와 구별합니다.
- 선택은 색에만 기대지 않고 접근성 속성으로도 알립니다. Flutter 는 `Semantics(selected:)`, Jaspr Web 은 `aria-pressed` 입니다.
- `selectedTheme` 은 각 `name` 과 `==` 로 비교합니다. 같은 `name` 이 없으면 아무 스와치도 고른 모양이 아니고, 같은 `name` 이 둘이면 둘 다 고른 모양이 됩니다.

<a id="비활성-두-범위"></a>

### 비활성

잠금은 두 범위로 나뉘고 합쳐집니다. 둘 중 하나라도 `false` 면 그 스와치는 잠깁니다.

- **컨트롤 전체** — `ThemeController(enabled: false)`. 읽기 전용 설정 구획처럼 모두 한꺼번에 잠글 때 씁니다.
- **테마 하나** — `CoreThemeOption(enabled: false)`. 지금 요금제에 없는 테마처럼 한 항목만 잠글 때 씁니다. 존재하는 테마이므로 잠긴 스와치도 제자리를 지킵니다.

<Preview demo="theme-controller/locked" />

잠긴 스와치는 흐리게 처리하지 않고 전용 색으로 바꿉니다(`Clickable` 의 비활성 불투명도를 100% 로 둡니다). 팔레트 원의 모든 띠는 색을 버리고 `disabledPreviewColor` 한 색이 됩니다 — 색이 남아 있으면 아직 고를 수 있는 것처럼 보이기 때문입니다. 고른 스와치는 잠겨도 고리 폭 2 를 지키고 색만 `disabledOutline` 으로 바뀌며, 고르지 않은 잠긴 스와치는 고리가 없습니다. 잠긴 스와치는 hover · 눌림에 반응하지 않고 `Tab` 순서에서 빠집니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

설정 화면처럼 사용자가 여러 색 테마 중 하나를 미리 보고 고를 때 씁니다. 컴포넌트는 고른 테마의 이름만 알립니다. 앱의 테마를 바꾸고 `selectedTheme` 을 갱신하는 것은 호출자의 몫입니다. 고른 값을 폼에 싣지도 않습니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 라이트 · 다크처럼 두 상태를 켜고 끌 때 | [Toggle](/components/toggle) · [SwitchField](/components/switch-field) |
| 색 미리보기 없이 글자 목록으로 충분할 때 | [Select](/components/select) |
| 테마가 아닌 일반 선택지를 폼에서 고를 때 | [RadioGroup](/components/radio-group) |
| 임의의 색 하나를 직접 정할 때 | [ColorPicker](/components/color-picker) |

### 선택지

<a id="do"></a>
<a id="dont"></a>

<Cards columns="2">
<Card component="theme-controller" props="count=3" tone="do" eyebrow="이렇게 하세요">

`selectedTheme` 에는 `themes` 의 `name` 하나를 그대로 넘깁니다. `name` 은 서로 다르게 정합니다.

</Card>
<Card demo="theme-controller/dont-mismatch" tone="dont" eyebrow="이렇게 하지 마세요">

대소문자 · 번역 · 내부 식별자처럼 `name` 과 다른 문자열을 넘기면 어느 원에도 고리가 생기지 않습니다.

</Card>
<Card demo="theme-controller/dont-light-dark" tone="dont" eyebrow="이렇게 하지 마세요">

라이트 · 다크 두 가지만 바꾸는 데 쓰지 않습니다. 이 격자는 여러 팔레트 중 하나를 고르는 화면입니다.

</Card>
<Card component="switch-field" props="value=true" label="다크 모드" tone="do" eyebrow="대신 이렇게 하세요">

켜고 끄는 질문 하나라면 스위치가 지금 상태를 더 분명하게 보여 줍니다.

</Card>
</Cards>

팔레트 색은 보조 기술이 읽지 않으므로, `name` 만 듣고도 어떤 테마인지 알 수 있게 짓습니다.

## 배치

### 줄바꿈 격자

스와치는 적은 순서대로 가로로 놓이고, 폭이 모자라면 다음 줄로 넘어갑니다. 줄 안의 간격과 줄 사이 간격은 모두 `buttonSpacing`(기본 12)입니다. 정렬이나 열 수를 정하는 속성은 없습니다.

- Jaspr Web 의 루트는 `flex-wrap` `<div>` 입니다. block 부모에서는 부모 폭을 채우고, 스와치는 시작 쪽부터 놓입니다.
- Flutter 의 루트는 `Wrap` 입니다. 부모가 폭을 강제하지 않으면 가장 긴 줄만큼의 폭만 차지합니다.

가운데에 놓으려면 이렇게 감쌉니다. Flutter 는 묶음 전체가 가운데로 오고 각 줄은 시작 쪽에서 맞춰집니다. Jaspr Web 의 `justify-center` 는 줄마다 가운데로 맞춥니다.

<Split>

<Code language="dart" title="Flutter">
Center(
  child: ThemeController(
    selectedTheme: selected,
    onThemeChanged: selectTheme,
    themes: themes,
  ),
)
</Code>

<Code language="dart" title="Jaspr Web">
ThemeController(
  classes: 'justify-center',
  selectedTheme: selected,
  onThemeChanged: selectTheme,
  themes: themes,
)
</Code>

</Split>

<a id="칸-폭-간격"></a>

### 칸 폭과 간격

<Preview demo="theme-controller/long-name" />

스와치 한 칸(버튼 · 간격 · 이름)은 `swatchMinWidth`(48) 이상입니다. 고정 폭이 아니라 최소 폭이라, 이름이 짧으면 버튼과 이름이 48 칸의 가운데에 서고, 이름이 더 길면 그 칸만 넓어집니다. 이름은 말줄임하지 않습니다. 이름이 부모의 폭보다 길면 여러 줄로 넘어가고, Jaspr Web 에서는 띄어쓰기 없는 긴 영문 낱말이 부모 밖으로 넘칠 수 있습니다.

<a id="스타일-시스템-style-system"></a>
<a id="시맨틱-vs-스타일"></a>
<a id="파라미터와-스타일"></a>

## 테마와 스타일

종류 · 내용 · 동작(`size` · `themes` · `selectedTheme` · `onThemeChanged` · `enabled`)은 컴포넌트 속성으로 정합니다. 색 · 크기 · 간격 같은 겉모습과 안쪽 부품의 스타일은 `themeControllerStyle`(`CoreThemeControllerStyle`) 하나로 덮어씁니다. 필드 전체는 [필드 표](#corethemecontrollerstyle-필드)에 있습니다. 팔레트 색은 스타일이 아니라 `CoreThemeOption` 의 데이터입니다. variant 가 없어 테마에도 `style` 하나만 있습니다.

<Split>

<Code language="dart" title="하나만 바꾸기">
ThemeController(
  selectedTheme: selected,
  onThemeChanged: selectTheme,
  themes: themes,
  themeControllerStyle: CoreThemeControllerStyle(
    selectedBorderColor: CoreColor.token(CoreColors.primary),
    selectedLabelColor: CoreColor.token(CoreColors.primary),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    themeController: CoreThemeControllerTheme(
      style: CoreThemeControllerStyle(
        buttonSpacing: CoreSpace.space16,
      ),
    ),
  ),
)
</Code>

</Split>

<Note>

앱 전체 값은 크기 행보다 우선합니다. `buttonSize` · `previewSize` · `buttonRadius` · `buttonSpacing` · `labelGapStyle` · `labelStyle` 을 앱 전체에 적으면 세 크기 모두에 같은 값이 적용됩니다.

</Note>

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `ThemeController` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `themeControllerStyle` 인자와 같게 동작하고, 겹치는 필드는 나중에 덧붙인 값이 이깁니다. 아래 예는 버튼을 64 로, 모서리를 4 로, 선택 고리를 `primary` 색 3 으로 바꿉니다. 팔레트 원은 크기 행의 값 32(`md`) 그대로라 고리와 원 사이가 넓어집니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ThemeControllerChainExample extends StatefulWidget {
  const ThemeControllerChainExample({super.key});

  @override
  State<ThemeControllerChainExample> createState() => _ThemeControllerChainExampleState();
}

class _ThemeControllerChainExampleState extends State<ThemeControllerChainExample> {
  String _selected = '오션';

  @override
  Widget build(BuildContext context) {
    return ThemeController(
      selectedTheme: _selected,
      onThemeChanged: (name) => setState(() => _selected = name),
      themes: const [
        CoreThemeOption(
          name: '오션',
          primaryColor: CoreColor.fromRGB(14, 165, 233),
          secondaryColor: CoreColor.fromRGB(99, 102, 241),
        ),
        CoreThemeOption(
          name: '포레스트',
          primaryColor: CoreColor.fromRGB(34, 197, 94),
          secondaryColor: CoreColor.fromRGB(132, 204, 22),
        ),
        CoreThemeOption(
          name: '선셋',
          primaryColor: CoreColor.fromRGB(249, 115, 22),
          secondaryColor: CoreColor.fromRGB(239, 68, 68),
        ),
      ],
    ).withStyle(
      const CoreThemeControllerStyle(
        buttonSize: CoreSize.size64,
        buttonRadius: CoreBorderRadius.all(CoreRadius.radius4),
        selectedBorderColor: CoreColor.token(CoreColors.primary),
        selectedBorderWidth: CoreStrokeWidth.stroke3,
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class ThemeControllerChainExample extends StatefulComponent {
  const ThemeControllerChainExample({super.key});

  @override
  State<ThemeControllerChainExample> createState() => _ThemeControllerChainExampleState();
}

class _ThemeControllerChainExampleState extends State<ThemeControllerChainExample> {
  String _selected = '오션';

  @override
  Component build(BuildContext context) {
    return ThemeController(
      selectedTheme: _selected,
      onThemeChanged: (name) => setState(() => _selected = name),
      themes: const [
        CoreThemeOption(
          name: '오션',
          primaryColor: CoreColor.fromRGB(14, 165, 233),
          secondaryColor: CoreColor.fromRGB(99, 102, 241),
        ),
        CoreThemeOption(
          name: '포레스트',
          primaryColor: CoreColor.fromRGB(34, 197, 94),
          secondaryColor: CoreColor.fromRGB(132, 204, 22),
        ),
        CoreThemeOption(
          name: '선셋',
          primaryColor: CoreColor.fromRGB(249, 115, 22),
          secondaryColor: CoreColor.fromRGB(239, 68, 68),
        ),
      ],
    ).withStyle(
      const CoreThemeControllerStyle(
        buttonSize: CoreSize.size64,
        buttonRadius: CoreBorderRadius.all(CoreRadius.radius4),
        selectedBorderColor: CoreColor.token(CoreColors.primary),
        selectedBorderWidth: CoreStrokeWidth.stroke3,
      ),
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
기본값 (CoreThemeControllerStyle 의 default*)      // 크기 행이 적지 않은 필드
  → CoreThemeControllerStyle.defaultsBySize[size]  // 크기 행 (sm · md · lg)
  → CoreComponentTheme.themeController.style       // 앱 전체
  → themeControllerStyle                           // 인스턴스
```

뒤로 갈수록 우선합니다. 안쪽 부품의 스타일은 이렇게 닿습니다.

- `labelStyle` 은 기본 글자 역할 위에 위 순서의 값을 합친 뒤, 상태에 맞는 라벨 색을 입힙니다.
- `labelGapStyle` · `clickableStyle` 은 `Gap` · `Clickable` 에 넘깁니다. 두 부품의 앱 전체 테마(`CoreComponentTheme.gap` · `clickable`)는 그 아래에 깔려, `ThemeController` 가 넘긴 값이 이깁니다. 그래서 간격 6 과 비활성 불투명도 100% 는 두 부품의 테마가 아니라 `themeControllerStyle` 로 바꿉니다.

<a id="접근성-accessibility"></a>

## 접근성

Flutter 는 선택 상태를 `Semantics(selected:)` 로, Jaspr Web 은 `aria-pressed` 로 알립니다. 동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟 같은 전역 축은 [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 스와치마다 원 버튼에 `Semantics(selected:, button: true, enabled:, label: name)` 를 붙입니다. 그 버튼을 감싼 `Clickable` 도 버튼 역할과 활성 여부를 선언합니다(→ 알려진 제약). 루트 `Wrap` 에는 역할이 없습니다. |
| Jaspr Web | 스와치마다 `Clickable` 의 `<div role="button">` 에 `aria-label`(테마 이름)과 `aria-pressed`(선택 여부)가 붙습니다. 활성이면 `tabindex="0"`, 잠겼으면 `tabindex` 없이 `aria-disabled="true"` 입니다. 루트 `<div>` 에는 역할도 `aria-*` 도 없고, 호출자가 `attributes` 로 넘긴 속성만 붙습니다. |

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` · `Shift` + `Tab` | 활성 스와치마다 멈춥니다. | 활성 스와치마다 멈춥니다. |
| `Enter` · `Space` | 포커스한 스와치의 이름으로 `onThemeChanged` 를 부릅니다. | 포커스한 스와치의 이름으로 `onThemeChanged` 를 부릅니다. |
| `↑` `↓` `←` `→` | 컴포넌트가 처리하지 않습니다. 데스크톱 · 모바일의 Flutter 기본 단축키는 그 방향으로 포커스를 옮기고, Flutter 웹 기본값은 화살표를 스크롤에 씁니다. | 처리하지 않아 브라우저의 기본 동작(스크롤)이 그대로 일어납니다. |
| `Home` · `End` · `Escape` | 처리하지 않습니다. | 처리하지 않습니다. |

### 스크린 리더

- 버튼의 이름은 `CoreThemeOption.name` 하나에서 옵니다. Flutter 는 `Semantics.label`, Jaspr Web 은 `aria-label` 입니다. 팔레트 색은 읽히지 않습니다.
- 이름 글자는 버튼 밖의 별도 요소라, 화면을 차례로 읽으면 같은 이름을 버튼에서 한 번, 글자에서 또 한 번 만날 수 있습니다.
- 선택은 색이나 모양이 아니라 속성으로 알립니다. Jaspr Web 은 `aria-pressed`(눌린 토글 버튼), Flutter 는 선택됨 상태입니다.
- 잠긴 스와치는 Flutter `Semantics(enabled: false)`, Jaspr Web `aria-disabled="true"` 로 비활성을 알리고 눌리지 않습니다.
- 라이브 리전이 없습니다. 누른 스와치에 포커스가 있고 호출자가 `selectedTheme` 을 갱신하면, 리더가 그 스와치의 선택 상태가 바뀐 것을 읽을 수 있습니다. 하지만 이전에 고른 스와치가 풀렸다는 것과 앱의 테마가 바뀌었다는 것은 따로 알리지 않습니다. 테마 적용은 `onThemeChanged` 를 받은 호출자의 몫입니다.

#### 묶음에 이름 붙이기

컴포넌트에는 묶음의 이름을 정하는 속성이 없습니다. 필요하면 이렇게 붙입니다.

<Split>

<Code language="dart" title="Flutter">
Semantics(
  container: true,
  label: '테마',
  child: ThemeController(
    selectedTheme: selected,
    onThemeChanged: selectTheme,
    themes: themes,
  ),
)
</Code>

<Code language="dart" title="Jaspr Web">
ThemeController(
  attributes: {'role': 'group', 'aria-label': '테마'},
  selectedTheme: selected,
  onThemeChanged: selectTheme,
  themes: themes,
)
</Code>

</Split>

### 포커스 관리

- 마운트할 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. 마지막 스와치에서 `Tab` 을 누르면 다음 요소로 빠져나갑니다.
- 키보드로 스와치를 눌러도 포커스는 그 스와치에 남습니다.
- 포커스 링은 원 버튼을 감싼 `Clickable` 의 링이고, 키보드로 포커스했을 때 보입니다. Flutter 는 `FocusOutline` 으로, Jaspr Web 은 `:focus-visible` 로 그립니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 스와치들이 하나의 선택 묶음이라는 것을 알리지 않습니다. 'N 개 중 몇 번째' 같은 안내가 없습니다. 묶음의 이름만 감싸서 붙일 수 있습니다(→ 스크린 리더). |
| 공통 | roving tabindex(묶음에 `Tab` 정지점을 하나만 두는 방식)를 쓰지 않습니다. 활성 스와치마다 `Tab` 정지점이 하나씩 있어, 묶음을 지나가려면 스와치 수만큼 `Tab` 을 눌러야 합니다. 화살표로 옮기는 동작은 컴포넌트에 없습니다(→ 키보드). Jaspr Web 은 `Clickable` 이 활성 스와치에 `tabindex="0"` 을 넣고, 호출자가 스와치의 속성을 바꿀 방법이 없습니다. |
| 공통 | 눌리는 곳은 원 버튼뿐입니다. 이름을 눌러도 선택되지 않고, `sm` 의 누를 수 있는 크기는 32 × 32 입니다. |
| 공통 | 포커스 링의 모서리는 `Clickable` 의 기본 모서리 4 를 따라, 원 버튼 둘레에 원이 아닌 둥근 사각형이 그려집니다. 원으로 맞추려면 `themeControllerStyle` 에 `clickableStyle: CoreClickableStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius9999))` 를 줍니다. |
| 공통 | 밀도 `compact` 에서는 `sm` 버튼의 모서리가 16 에서 14 로 줄고 버튼 크기 32 는 그대로라, 고리가 원이 아닙니다. 원으로 두려면 `buttonRadius: CoreBorderRadius.all(CoreRadius.radius9999)` 를 줍니다. |
| Flutter | `liquidGlass` 서페이스 스타일에서는 원 버튼의 테두리 색이 투명해지고 모든 스와치에 같은 유리 가장자리가 그려져, 선택 · hover 고리가 보이지 않을 수 있습니다. 그러면 고른 테마는 화면에서 이름 글자색으로만 구분됩니다. 고대비 화면에서는 테두리가 돌아옵니다. |
| Flutter | 원 버튼의 버튼 역할과 활성 여부를 `Clickable` 과 안쪽 `Semantics` 가 각각 선언합니다. Flutter 는 같은 선언이 겹치는 두 접근성 노드를 합치지 않으므로, 이름이 있는 버튼 바깥에 이름 없는 버튼 노드가 하나 더 생길 수 있습니다. |
| Jaspr Web | 색을 강제 치환하는 화면(forced-colors)에서는 브라우저가 배경색도 시스템 색으로 바꾸므로 팔레트 색이 보이지 않습니다. 그 화면에서는 테마를 이름으로 구분합니다. |
| Jaspr Web | `labelStyle` 에 색을 넣으면 잠긴 스와치의 이름에도 그 색이 닿습니다. 직접 값인 색은 기본 `disabledLabelColor` 대신 보이고, 토큰 색은 비활성 색과 함께 붙어 어느 색이 보일지 스타일시트 순서에 달립니다. 라벨 색은 `labelColor` · `selectedLabelColor` · `disabledLabelColor` 로 바꿉니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`themes` · `selectedTheme` · `onThemeChanged` · `size` · `enabled` · `themeControllerStyle` 은 두 플랫폼이 같은 API 입니다. 렌더링은 각 플랫폼의 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 루트 | `Wrap`. 부모가 폭을 강제하지 않으면 가장 긴 줄만큼의 폭입니다. | `flex-wrap` `<div>`. block 부모에서는 부모 폭을 채웁니다. |
| 원 버튼 | `Clickable` 안의 `OutlinedContainer` 가 고리를 그립니다. | `Clickable` 안의 `<div>` 가 CSS 테두리로 고리를 그립니다. |
| hover · 눌림 | `Clickable.onHover` · `onPressedChange` 를 받아 고리와 팔레트 크기를 고릅니다. | 범위를 좁힌 `<style>` 규칙의 `:hover` · `:active` 가 고리(`!important`)를 바꾸고, 팔레트는 `transform: scale()` 로 줄입니다. |
| 키보드로 누를 때 | 잠깐 눌린 상태가 되어 팔레트 원이 줄었다 돌아옵니다. | `Clickable` 의 0.97 배 효과만 보이고, 팔레트 원과 hover 고리는 바뀌지 않습니다. |
| 상태가 바뀔 때의 색 | 고리 색과 이름 글자색이 바로 바뀝니다. | `enableThemeAnimation`(기본 켜짐)이면 150ms 동안 바뀝니다. |
| `liquidGlass` 의 고리 | 보이지 않을 수 있습니다(→ 알려진 제약). | 그대로 그립니다. |
| `hoverBorderWidth: 0` | hover 동안 고리 폭이 0 이 됩니다. `unselectedBorderWidth` 로 준 쉬는 고리도 사라집니다. | hover 규칙을 만들지 않아 쉬는 고리가 남습니다. |
| 팔레트 | `ClipRRect` 안의 `Row` 를 `Expanded` `ColoredBox` 가 나눕니다. | `overflow: hidden` `<div>` 를 `flex-1` 조각이 나눕니다. |
| 라벨 | `Gap` + `Text` | `Gap` + `<div>` 안의 `Text` |
| 선택 알림 | `Semantics(selected:)` | `aria-pressed` |
| 크기 단위 | logical px. `CoUIApp(scaling:)` 배율이 버튼 · 팔레트 원 · 스와치 간격 · 최소 칸 폭에도 곱해집니다. | 버튼 · 팔레트 원 · 간격 · 최소 칸 폭은 `rem` 이라 브라우저의 기본 글자 크기를 따릅니다. 고리 두께와 모서리는 px 입니다. |
| 웹 전용 속성 | — | `id` · `classes` · `css` · `attributes` · `eventHandlers`(루트 `<div>`) |

<a id="props-parameters"></a>

## API

Flutter 와 Jaspr Web 이 같은 속성 이름을 씁니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `themes` | `List<CoreThemeOption>` | 필수 | 고를 수 있는 테마. 적은 순서대로 놓입니다. |
| `selectedTheme` | `String?` | `null` | 고른 테마의 `name`. 같은 `name` 이 없으면 아무것도 고른 모양이 아닙니다. |
| `onThemeChanged` | `void Function(String)` | 필수 | 누른 스와치의 `name` 을 받습니다. 이미 고른 스와치를 눌러도 부릅니다. |
| `size` | `CoreThemeControllerSize` | `md` | 스와치 크기 `sm` · `md` · `lg`. 원 버튼이 32 · 40 · 48 입니다. 크기마다의 값은 `CoreThemeControllerStyle.defaultsBySize` 가 정합니다. |
| `enabled` | `bool` | `true` | `false` 면 모든 스와치를 잠급니다. 테마 하나만 잠그려면 `CoreThemeOption.enabled` 를 씁니다. |
| `themeControllerStyle` | `CoreThemeControllerStyle?` | `null` | 보이는 값 덮어쓰기 |
| `id` | `String?` | `null` | Web 전용. 루트 `<div>` 의 id |
| `classes` | `String?` | `null` | Web 전용. 루트에 덧붙이는 class. 정렬 같은 배치에 씁니다. |
| `css` | `Styles?` | `null` | Web 전용. 루트의 inline 스타일 |
| `attributes` | `Map<String, String>?` | `null` | Web 전용. 루트의 HTML 속성(`role` · `aria-label` 등) |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | Web 전용. 루트의 DOM 이벤트 |

`withStyle(patch)` 는 `themeControllerStyle` 에 `patch` 를 합친 사본을 돌려줍니다.

### `CoreThemeOption`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `name` | `String` | 필수 | 테마 이름. 스와치의 라벨이자 접근성 이름이고, `onThemeChanged` 가 받는 값입니다. 목록 안에서 서로 다르게 둡니다. |
| `primaryColor` | `CoreColor` | 필수 | 팔레트의 첫 번째 색 |
| `secondaryColor` | `CoreColor?` | `null` | 팔레트의 두 번째 색 |
| `accentColor` | `CoreColor?` | `null` | 팔레트의 세 번째 색 |
| `neutralColor` | `CoreColor?` | `null` | 팔레트의 네 번째 색 |
| `enabled` | `bool` | `true` | `false` 면 이 테마만 잠급니다. 자리는 지키고 팔레트 색을 버립니다. |

### 테마

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `CoreComponentTheme.themeController` | `CoreThemeControllerTheme?` | `null` | `style: CoreThemeControllerStyle?` 하나를 가집니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreThemeControllerStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `buttonSize` | `double?` | Size of each theme button (logical px). |
| `previewSize` | `double?` | Size of each colour-preview circle (logical px). |
| `buttonSpacing` | `double?` | Spacing between adjacent theme buttons (logical px) — consumed as native `Wrap.spacing` / `Wrap.runSpacing` on Flutter and as the flex container `gap` CSS property on Web. |
| `swatchMinWidth` | `double?` | Minimum width of one swatch cell (logical px) — the cell grows past it when the theme name is wider; see [defaultSwatchMinWidth]. |
| `buttonRadius` | `CoreBorderRadius?` | Corner radius of a theme button. |
| `previewBorderRadius` | `CoreBorderRadius?` | Corner radius of the colour-preview circle inside a swatch button. Defaults to a fully round dot — see [defaultPreviewBorderRadius]. |
| `selectedBorderColor` | `CoreColor?` | Border colour of the selected theme button. |
| `unselectedBorderColor` | `CoreColor?` | Border colour of an unselected theme button. |
| `selectedBorderWidth` | `double?` | Border thickness of the selected theme button (logical px). |
| `unselectedBorderWidth` | `double?` | Border thickness of an unselected theme button (logical px). |
| `hoverBorderColor` | `CoreColor?` | Ring colour of an unselected, enabled swatch while it is hovered or pressed. The selected swatch keeps [selectedBorderColor] in those states; a disabled one reacts to neither. |
| `hoverBorderWidth` | `double?` | Ring thickness of an unselected, enabled swatch while it is hovered or pressed (logical px). |
| `buttonBackgroundColor` | `CoreColor?` | Background of a swatch button. |
| `pressedPreviewShrink` | `double?` | How much the palette circle's diameter shrinks while its swatch is pressed (logical px). The corner radius is [previewBorderRadius] — fully round — so the circle stays a circle at the smaller size. |
| `disabledBorderColor` | `CoreColor?` | Border colour of a **disabled** swatch button. |
| `disabledPreviewColor` | `CoreColor?` | Fill of every palette segment on a **disabled** swatch. |
| `disabledLabelColor` | `CoreColor?` | Label colour on a **disabled** swatch. |
| `labelStyle` | `CoreTextStyle?` | Text style of the swatch label — typography only; the colour comes from [labelColor] / [selectedLabelColor] / [disabledLabelColor]. |
| `labelColor` | `CoreColor?` | Colour of the swatch label while the swatch is interactive and not selected. |
| `selectedLabelColor` | `CoreColor?` | Colour of the label of the selected, interactive swatch. |
| `labelGapStyle` | `CoreGapStyle?` | Gap between a swatch button and its label. |
| `clickableStyle` | `CoreClickableStyle?` | Style for each swatch's `Clickable` — press scale, durations, focus ring, disabled opacity. Laid over [defaultClickableStyle] and passed to the `Clickable` as is; the `Clickable` fills in the rest. |

<!-- STYLE_TABLE:END -->

<Note>

표의 `labelStyle` 설명과 달리, `labelStyle` 에 색을 넣으면 그 색이 `labelColor` 와 `selectedLabelColor` 보다 우선합니다. 그러면 고른 테마의 이름도 고르지 않은 이름과 같은 색이 됩니다. 잠긴 이름에는 Flutter 만 `disabledLabelColor` 를 지키고, Jaspr Web 은 `labelStyle` 의 색이 닿습니다(→ 알려진 제약). 라벨 색은 `labelColor` · `selectedLabelColor` · `disabledLabelColor` 로 바꿉니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card component="toggle" props="value=true" label="다크 모드" title="Toggle">

라이트 · 다크처럼 두 가지를 켜고 끌 때 씁니다.

</Card>
<Card component="select" props="placeholder=테마 선택" title="Select">

색 미리보기 없이 글자 목록으로 충분할 때 씁니다.

</Card>
<Card component="radio-group" props="options=2;orientation=horizontal" title="RadioGroup">

폼 안에서 일반 선택지 하나를 고를 때 씁니다.

</Card>
<Card component="color-picker" props="color=#6750A4" title="ColorPicker">

테마가 아니라 색 하나를 직접 정할 때 씁니다.

</Card>
</Cards>
