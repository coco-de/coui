---
title: Toggle
description: 하나의 설정을 켜고 끄는 스위치입니다. 바꾸는 즉시 반영되는 설정에 씁니다.
category: form
platforms: [flutter, web]
related: [checkbox, switch-field]
tags: [form-control, boolean, switch]
template: v2
source: form/toggle
---

# Toggle

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

켜짐과 크기를 바꿔 보며 토글을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="toggle" />

토글은 값을 스스로 바꾸지 않습니다. 누르면 `onChanged(!value)` 를 부르므로, 호출자가 새 값을 `value` 로 다시 넘겨야 썸이 움직입니다.

<a id="구조-anatomy"></a>

## 구조

토글은 트랙과 그 안을 움직이는 썸, 그리고 라벨로 이루어집니다.

<Anatomy demo="toggle/anatomy">
<AnatomyItem part="container" side="top" name="Container">

누르는 영역 전체. 트랙과 라벨을 함께 누를 수 있습니다.

</AnatomyItem>
<AnatomyItem select=".co-toggle-track" side="top" name="track">

켜짐과 꺼짐을 색으로 나타내는 알약 모양의 트랙입니다.

</AnatomyItem>
<AnatomyItem select=".co-toggle-track > span" side="left" name="thumb">

트랙 안을 좌우로 움직이는 손잡이. 켜지면 끝 쪽으로 갑니다.

</AnatomyItem>
<AnatomyItem select=".co-toggle-content > span:last-child" side="right" name="label">

라벨. 토글의 이름이 됩니다.

</AnatomyItem>
</Anatomy>

`prefix` 는 트랙 앞, `suffix` 는 트랙 뒤에 놓이는 위젯 슬롯입니다. `suffix` 와 `label` 을 함께 주면 플랫폼마다 결과가 다릅니다 — Flutter 는 `suffix` 만 그리고, Jaspr Web 은 `suffix` 뒤에 `label` 도 그립니다. 둘 중 하나만 쓰세요.

<a id="크기-토큰"></a>

## 크기

트랙 높이 16부터 32까지 5단계입니다. 트랙 폭은 높이 + 16, 썸은 높이 − 4 라서 썸이 움직이는 거리는 모든 크기에서 16 으로 같습니다.

<SizeSpec component="toggle" label="알림 받기" />

<Note>

`xs` 는 크기 행이 없어 `sm` 으로 그려집니다. 이 크기는 없어질 예정이고, assert 가 켜진 실행(디버그 빌드, Jaspr 정적 빌드의 사전 렌더)에서 한 번 경고를 남깁니다. `sm` 을 쓰세요.

</Note>

라벨이 있으면 행의 높이는 라벨 한 줄의 높이와 트랙 높이 중 큰 쪽입니다. 작은 크기에서는 라벨이, 큰 크기에서는 트랙이 높이를 정합니다.

<a id="동작-스펙-behavior"></a>
<a id="변형-variants"></a>
<a id="상태-전환"></a>

## 상태

토글의 variant 는 `defaultVariant` 하나입니다. 켜짐 여부와 `enabled` 가 모양을 정합니다.

<Preview demo="toggle/states" />

| 항목 | 동작 |
| --- | --- |
| 누를 때 | `onChanged(!value)` 를 부릅니다. 썸은 호출자가 새 `value` 를 넘길 때 움직입니다. |
| 켜짐 · 꺼짐 | 켜지면 트랙이 `primary`, 썸이 `onPrimary` 입니다. 꺼지면 트랙이 `surfaceContainerHighest`, 썸이 흰색입니다. |
| Hover · 눌림 | 트랙 위에 트랙 자신의 잉크(켜짐은 `surface`, 꺼짐은 `onSurface`)를 8% 로 덮고, 누르는 동안 16% 로 진하게 합니다. |
| 누르는 동안 크기 | 행 전체가 0.97배로 줄어듭니다. `toggleStyle.clickableStyle` 로 바꿀 수 있습니다. |
| Focus | 키보드로 포커스했을 때만 **트랙** 둘레에 링을 그립니다 — 트랙에서 2만큼 비운 뒤 2 두께의 링입니다. |
| 비활성 | 켜짐 트랙 `disabledContent`, 꺼짐 트랙 `disabledContainer`, 라벨 `disabledContent`. 켜짐 썸은 `surface`, 꺼짐 썸은 흰색입니다. Tab 순서에서 빠지고 hover 표시와 포커스 링이 없습니다 — Jaspr Web 은 마우스로 누르면 포커스가 갑니다(→ 알려진 제약). |
| 전환 시간 | 트랙 색과 썸 이동 모두 100ms, ease-in-out 입니다. 동작 줄이기를 켜면 바로 바뀝니다. |
| 활성 여부 | `enabled` 를 지정하지 않으면 `onChanged` 가 있을 때 활성입니다. |

<Note>

`enabled: true` 를 주고 `onChanged` 를 비우면 활성으로 보이고 포커스도 받지만, 눌러도 아무 일이 일어나지 않습니다. 읽기 전용으로 보여 줄 때는 `enabled: false` 를 함께 줍니다.

</Note>

### 전환 렌즈

사용자가 직접 켜고 끌 때(탭 · 클릭 · `Space` · `Enter`) 썸이 움직이는 **동안에만** 썸보다 조금 큰 투명한 알약(렌즈)이 썸을 따라갑니다. 앱이 코드로 값을 바꿀 때(폼 초기화 · "모두 켜기" 같은)는 썸만 움직이고 렌즈는 뜨지 않습니다.

- 멈춰 있는 토글에는 렌즈가 없습니다. 그래서 정지 상태의 크기 · 배치 · 픽셀은 렌즈와 무관합니다.
- 렌즈는 썸 이동과 같은 시간 동안 살고, 처음 4분의 1 동안 나타나 마지막 4분의 1 동안 사라집니다(`lensFadeFraction`).
- 기본 렌즈는 채움 · 테두리 · 그림자가 없습니다. 보이는 블러 · 굴절 · 가장자리 띠는 지금 서페이스 스타일이 떠 있는 표면에 주는 재질이라, 재질이 없는 스타일에서는 아무것도 보이지 않습니다.
- 비활성 토글과 동작 줄이기에서는 렌즈가 뜨지 않습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 저장 · 제출한 뒤에 반영되는 선택 | [Checkbox](/components/checkbox) |
| 일부만 고른 상태(불확정)가 필요할 때 | [Checkbox](/components/checkbox) |
| 라벨과 설명을 가진 설정 행 전체 | [SwitchField](/components/switch-field) |
| 두 아이콘이나 내용을 서로 바꿀 때 | [Swap](/components/swap) |
| 두 가지보다 많은 선택지 | [RadioGroup](/components/radio-group) · [Select](/components/select) |

<Note>

토글과 체크박스 모두 값이 바뀌면 바로 `onChanged` 를 부르고, 언제 반영할지는 호출자가 정합니다. 바로 반영되는 설정에는 토글을, 저장 버튼을 눌러야 반영되는 선택에는 체크박스를 씁니다.

</Note>

### 라벨과 반영 시점

<Cards columns="2">
<Card component="toggle" props="value=true" label="다크 모드" tone="do" eyebrow="이렇게 하세요">

라벨을 항상 붙입니다. 무엇을 켜고 끄는지 바로 알 수 있습니다.

</Card>
<Card component="toggle" props="value=true" tone="dont" eyebrow="이렇게 하지 마세요">

라벨이 없으면 무엇을 켜는지 알 수 없고, 스크린 리더가 읽을 이름도 없습니다.

</Card>
<Card component="toggle" props="value=true" label="알림 받기" tone="do" eyebrow="이렇게 하세요">

긍정형 라벨을 씁니다. 켜짐이 곧 "켜졌다" 로 읽힙니다.

</Card>
<Card component="toggle" props="value=true" label="알림 끄기" tone="dont" eyebrow="이렇게 하지 마세요">

부정형 라벨은 켰을 때 이중 부정이 되어 헷갈립니다.

</Card>
<Card demo="toggle/settings" tone="do" eyebrow="이렇게 하세요">

바꾸는 즉시 반영되는 설정 목록에 씁니다.

</Card>
<Card component="checkbox" props="checked=true" label="뉴스레터 구독" tone="do" eyebrow="대신 이렇게 하세요">

"저장" 을 눌러야 반영되는 설정이라면 체크박스를 씁니다. 토글은 바로 반영된다고 기대하게 만듭니다.

</Card>
</Cards>

<a id="스타일-시스템-style-system"></a>
<a id="스타일-시스템-togglestyle"></a>

## 테마와 스타일

크기는 위젯 속성 `size` 로 고르고, 트랙 · 썸의 색과 크기, hover 표시, 포커스 링, 라벨처럼 보이는 값은 `toggleStyle`(`CoreToggleStyle`) 하나로 덮어씁니다.

<Split>

<Code language="dart" title="토글 하나만 바꾸기">
Toggle(
  value: darkMode,
  onChanged: setDarkMode,
  label: '다크 모드',
  toggleStyle: CoreToggleStyle(
    trackActiveColor: CoreColor.token(CoreColors.success),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    toggle: CoreToggleTheme(
      style: CoreToggleStyle(
        trackActiveColor: CoreColor.token(CoreColors.success),
      ),
    ),
  ),
)
</Code>

</Split>

<Note>

비활성 상태의 트랙 · 썸 · 라벨 색은 `toggleStyle` 로 바꿀 수 없습니다. 비활성일 때는 인스턴스에 준 트랙 · 썸 색과 `labelStyle` 의 색도 무시하고 디자인 시스템의 비활성 색을 씁니다.

</Note>

<a id="togglestyle-슬롯"></a>

### 빠른 오버라이드 (Chain)

이미 만든 `Toggle` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `toggleStyle` 인자와 같게 동작합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ToggleChainExample extends StatefulWidget {
  const ToggleChainExample({super.key});

  @override
  State<ToggleChainExample> createState() => _ToggleChainExampleState();
}

class _ToggleChainExampleState extends State<ToggleChainExample> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return Toggle(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      label: '다크 모드',
    ).withStyle(
      const CoreToggleStyle(
        trackActiveColor: CoreColor.token(CoreColors.success),
        trackInactiveColor: CoreColor.token(CoreColors.outlineVariant),
        trackBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        thumbBorderRadius: CoreBorderRadius.all(CoreRadius.radius2),
        thumbShadow: CoreShadow.sm,
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class ToggleChainExample extends StatefulComponent {
  const ToggleChainExample({super.key});

  @override
  State<ToggleChainExample> createState() => _ToggleChainExampleState();
}

class _ToggleChainExampleState extends State<ToggleChainExample> {
  bool _value = false;

  @override
  Component build(BuildContext context) {
    return Toggle(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      label: '다크 모드',
    ).withStyle(
      const CoreToggleStyle(
        trackActiveColor: CoreColor.token(CoreColors.success),
        trackInactiveColor: CoreColor.token(CoreColors.outlineVariant),
        trackBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        thumbBorderRadius: CoreBorderRadius.all(CoreRadius.radius2),
        thumbShadow: CoreShadow.sm,
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
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
기본값 (defaultsByVariant[variant] · defaultsBySize[size] · default*)
  → CoreComponentTheme.toggle.style                    // 앱 전체
  → CoreComponentTheme.toggle.variantStyles[variant]   // 앱 전체, variant 별
  → toggleStyle                                        // 인스턴스
```

뒤로 갈수록 우선합니다. 토글을 안에 그리는 컴포넌트는 자기 값을 그 토글의 `toggleStyle` 로 넘깁니다. 라벨 글자는 `defaultLabelStyle`(색) 위에 크기 행의 역할이, 그 위에 `labelStyle` 이 얹힙니다.

트랙 크기를 바꿀 때는 `thumbOffset`(켜졌을 때 썸의 자리 = 트랙 폭 − 좌우 안쪽 여백 − 썸 크기)도 함께 맞춥니다. Flutter 는 썸을 트랙 높이에서 위아래 안쪽 여백을 뺀 정사각형으로 그려 `thumbSize` 를 따르지 않고, Jaspr Web 은 `thumbSize` 그대로 그립니다 — `thumbSize` 를 그 값과 다르게 주면 두 플랫폼의 썸 크기가 달라집니다. `thumbBorderRadius` 를 비우면 Flutter 는 썸을 원으로, Jaspr Web 은 트랙과 같은 모서리로 그립니다 — 트랙 모서리를 작게 바꾸면 두 플랫폼의 썸 모양이 달라집니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreToggleStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `thumbShadow` | `List<CoreShadowLayer>?` | Shadow layers on the moving thumb, independent of the track and lens. |
| `thumbShadowBaseColor` | `CoreColor?` | Base tint of [thumbShadow]; layer opacity and dark strength are retained. |
| `trackActiveColor` | `CoreColor?` | Track fill colour when on. |
| `trackInactiveColor` | `CoreColor?` | Track fill colour when off. |
| `trackBorderRadius` | `CoreBorderRadius?` | Track border radius override. |
| `trackWidth` | `double?` | Track width override (logical px). |
| `trackHeight` | `double?` | Track height override (logical px). |
| `thumbActiveColor` | `CoreColor?` | Thumb fill colour when on. |
| `thumbInactiveColor` | `CoreColor?` | Thumb fill colour when off. |
| `thumbSize` | `double?` | Thumb size (width = height) override (logical px). |
| `thumbBorderRadius` | `CoreBorderRadius?` | Thumb border radius override. |
| `thumbOffset` | `double?` | Thumb travel offset when on (logical px). `null` falls back to [defaultsBySize] for the widget's size. |
| `inactiveThumbOffset` | `double?` | Thumb resting (off-state) X translation (logical px). `null` falls back to [defaultInactiveThumbOffset] (0 — flush with the track's leading edge). |
| `padding` | `CoreEdgeInsets?` | Inner padding inside the track. `null` falls back to [defaultsBySize] for the widget's size. |
| `iconLabelGapStyle` | `CoreGapStyle?` | Style of the `Gap` between the toggle track and the prefix / suffix / label slots. `null` defers to the per-size default in [defaultsBySize], else [defaultIconLabelGapStyle]. |
| `colorTransitionDuration` | `Duration?` | Track colour transition duration. `null` falls back to [defaultColorTransitionDuration]. |
| `thumbTransitionDuration` | `Duration?` | Thumb travel transition duration. `null` falls back to [defaultThumbTransitionDuration]. |
| `stateLayer` | `CoreStateLayer?` | How strongly the track's own ink is laid over its fill while hovered / pressed. `null` falls back to [defaultStateLayer]. |
| `stateLayerActiveColor` | `CoreColor?` | The ink the state layer paints over the on track. `null` falls back to the variant's `activeStateLayer`. |
| `stateLayerInactiveColor` | `CoreColor?` | The ink the state layer paints over the off track. `null` falls back to the variant's `inactiveStateLayer`. |
| `focusOutlineStyle` | `CoreFocusOutlineStyle?` | Style of the focus outline drawn around the track. Merged on top of [defaultFocusOutlineStyle] and passed to `FocusOutline` as is. |
| `clickableStyle` | `CoreClickableStyle?` | Style of the toggle's `Clickable` — press scale, durations, disabled opacity. Merged on top of [defaultClickableStyle] and passed to the `Clickable` as is. |
| `labelStyle` | `CoreTextStyle?` | Label text style override — merged on top of [defaultLabelStyle] and the size row's role. |
| `lensOutset` | `CoreEdgeInsets?` | How far the transient lens reaches past the thumb on each side. `null` falls back to [defaultLensOutset]. |
| `lensContainerStyle` | `CoreOutlinedContainerStyle?` | Look of the lens shown only while the thumb travels — merged on top of [defaultLensContainerStyle] and passed to the lens as is. |
| `lensFadeFraction` | `double?` | Share of the thumb's travel the lens spends fading in, and again fading out. `null` falls back to [defaultLensFadeFraction]; a value below `0` or above [maxLensFadeFraction] is clamped to that bound. |

### `CoreToggleStyle` 변형별 기본값 (`CoreToggleVariantStyle`)

| 필드 | `defaultVariant` |
|------|------|
| `activeTrack` | primary |
| `inactiveTrack` | surfaceContainerHighest |
| `activeThumb` | onPrimary |
| `inactiveThumb` | CoreColor(0xFFFFFFFF) |
| `disabledActiveTrack` | disabledContent |
| `disabledInactiveTrack` | disabledContainer |
| `disabledThumb` | surface |
| `disabledInactiveThumb` | CoreColor(0xFFFFFFFF) |
| `disabledForegroundColor` | disabledContent |
| `activeStateLayer` | surface |
| `inactiveStateLayer` | onSurface |

<!-- STYLE_TABLE:END -->

<a id="접근성-accessibility"></a>

## 접근성

Flutter 는 `Semantics(toggled:)` 로, Jaspr Web 은 `role="switch"` 와 `aria-checked` 로 켜짐 여부를 알립니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | `Semantics(toggled: value)` 로 켜짐 여부를 알립니다. 안에 그리는 `Clickable` 의 버튼 역할은 끄므로 스위치로 읽힙니다. 비활성이면 비활성으로 알립니다. |
| Jaspr Web | 누르는 영역 한 곳에만 `role="switch"` · `aria-checked` · `tabindex` 가 붙고, 비활성이면 `aria-disabled="true"` 가 더해집니다. 트랙(과 그 안의 썸), 움직이는 동안의 렌즈는 `aria-hidden="true"` 입니다. |

`name` 을 주면 Jaspr Web 은 폼 제출용 숨은 `<input type="checkbox">` 를 함께 그립니다. 이 입력은 `aria-hidden="true"` · `tabindex="-1"` 이라 스크린 리더에도 Tab 순서에도 나타나지 않습니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Space` · `Enter` | 켜고 끕니다. 키를 누를 때 바뀝니다. |
| `Tab` | 다음 요소로 포커스를 옮깁니다. |
| `Shift` · `Tab` | 이전 요소로 포커스를 옮깁니다. |

<Note>

화살표로 켜고 끄는 조작은 없습니다. 비활성 토글은 포커스 순서에서 빠집니다.

</Note>

### 스크린 리더

접근 가능한 이름은 토글 안의 글자에서 옵니다 — `label` · `prefix` · `suffix` 에 넣은 글자가 이름이 됩니다. Flutter 는 `suffix` 가 있으면 `label` 을 그리지 않으므로 이름에서도 `label` 이 빠집니다. 글자가 하나도 없으면 이름이 비고, 리더는 역할과 상태만 읽습니다.

켜짐 · 꺼짐과 비활성은 두 플랫폼 모두 알립니다. 값이 바뀐 사실을 따로 알리는 라이브 리전은 없고, 상태는 토글 자신에 실려 있습니다.

### 포커스 관리

마운트될 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. 포커스 링은 키보드로 포커스했을 때만 트랙 둘레에 나타납니다. Flutter 는 링이 150ms 동안 나타나고, Jaspr Web 은 바로 나타납니다.

### 색 대비

꺼진 썸은 라이트 · 다크 모두 흰색입니다. 라이트의 꺼진 트랙 위에서 흰 썸은 색만으로는 그래픽 대비 3:1 에 미치지 못해, 모든 자세의 썸에 얇은 그림자(`defaultThumbShadow`)를 깔아 윤곽을 받칩니다. 상태는 색이 아니라 썸의 위치와 트랙 색이 함께 말합니다. 비활성은 투명도가 아니라 전용 비활성 색으로 나타내고, 꺼짐에서도 트랙 톤으로 활성과 구분됩니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | 라벨 없이 이름을 붙일 방법이 없습니다. 생성자가 `aria-label` 같은 속성을 받지 않습니다. |
| Flutter | 이름을 붙이는 전용 속성이 없어, 라벨 없는 토글은 호출자가 `Semantics(label:)` 로 감싸야 합니다. |
| Jaspr Web | `prefix` · `suffix` 안의 버튼이나 링크를 누르면 토글도 함께 바뀝니다. 슬롯에는 누르지 않는 내용만 둡니다. |
| Jaspr Web | 숨은 폼 입력에 `disabled` 가 없어 비활성 토글도 폼 제출에 값이 실리고, 켜짐이면 `on` 이 제출됩니다. |
| Jaspr Web | 비활성 토글도 마우스로 누르면 포커스를 받습니다(키 입력은 무시합니다). |
| Jaspr Web | 강제 색상(고대비) 모드에서는 포커스 링이 트랙이 아니라 행 전체에 그려집니다. |
| Flutter | 오른쪽에서 왼쪽으로 쓰는 언어에서도 썸은 왼쪽(꺼짐)에서 오른쪽(켜짐)으로 움직입니다. |
| Jaspr Web | 오른쪽에서 왼쪽으로 쓰는 언어에서는 꺼진 썸이 트랙의 오른쪽 끝에 놓이고, 켜면 오른쪽으로 더 움직여 트랙 밖으로 나갑니다. |
| Flutter | `name` 과 `controller` 는 받지만 아직 아무 일도 하지 않습니다. 값은 `value` 와 `onChanged` 로 다룹니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>
<a id="수용된-호환-예외와-공통-호출"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 켜짐 알림 | `Semantics(toggled:)` | `role="switch"` · `aria-checked` |
| `suffix` 와 `label` 을 함께 줄 때 | `suffix` 만 그립니다 | 둘 다 그립니다 |
| 썸 · 트랙 애니메이션 | `AnimatedPositioned` 와 트랙 색 전환 | CSS `transition` (`transform` · `background-color`) — 같은 100ms · ease-in-out |
| 포커스 링이 나타날 때 | 150ms 동안 나타납니다 | 바로 나타납니다 |
| 비활성 토글의 포커스 | 받지 않습니다 | Tab 에서는 빠지지만 마우스로 누르면 받습니다 |
| 폼 값 | `FormValueSupplier`. `name` 은 쓰지 않습니다 | `FormValueSupplier` 와, `name` 이 있으면 숨은 `<input type="checkbox">` |
| 전환 렌즈가 썸을 따라가는 방법 | 썸의 위치를 레이어로 따라갑니다 | 썸의 `transform` 전환을 그대로 따라 그립니다 |
| `thumbBorderRadius` 를 비울 때 | 원으로 그립니다 | 트랙의 모서리를 따릅니다 |
| `value` · `onChanged` | 둘 다 넘겨야 합니다 | 생략하면 `false` · `null` 입니다 |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다.

### 값과 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `bool` | 필수 (Web 은 `false`) | 켜짐 여부 |
| `onChanged` | `ValueChanged<bool>?` | 필수 (Web 은 `null`) | 반대 값을 받습니다. 값은 호출자가 반영합니다. |
| `label` | `String?` | `null` | 라벨. 이름이 됩니다. |
| `labelMaxLines` | `int?` | `null` | 라벨의 최대 줄 수. 지정하지 않으면 제한하지 않습니다. |
| `labelOverflow` | `CoreTextOverflow?` | `null` | 최대 줄 수를 넘긴 라벨의 처리 |
| `prefix` | `Widget?` | `null` | 트랙 앞 슬롯 |
| `suffix` | `Widget?` | `null` | 트랙 뒤 슬롯 |

### 상태와 형태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `enabled` | `bool?` | `null` | 지정하지 않으면 `onChanged` 유무로 정합니다. |
| `variant` | `CoreToggleVariant` | `defaultVariant` | 지금은 `defaultVariant` 하나입니다. |
| `size` | `CoreComponentSize` | `md` | 트랙 · 썸 · 라벨 크기. `sm` 부터 `xl2` 까지 |
| `toggleStyle` | `CoreToggleStyle?` | `null` | 보이는 값 덮어쓰기 |
| `name` | `String?` | `null` | 폼 제출 이름 (Web 만 숨은 입력으로 씁니다) |

### Flutter 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `focusNode` | `FocusNode?` | `null` | 포커스를 직접 제어할 때 |
| `statesController` | `WidgetStatesController?` | `null` | 상태를 직접 제어할 때 |
| `controller` | `ToggleController?` | `null` | 받지만 아직 쓰이지 않습니다. |

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card component="checkbox" props="checked=true" label="동의합니다" title="Checkbox">

저장한 뒤 반영되는 선택과 불확정 상태에 씁니다.

</Card>
<Card demo="toggle/related-switch-field" title="SwitchField">

라벨과 설명을 가진 설정 행 전체를 만듭니다.

</Card>
<Card demo="toggle/related-slider" title="Slider">

켜고 끄는 값이 아니라 범위 안의 값을 고를 때 씁니다.

</Card>
</Cards>
