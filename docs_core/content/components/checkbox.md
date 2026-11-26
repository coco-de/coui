---
title: Checkbox
description: 하나 이상의 항목을 고르게 하는 체크박스입니다. 일부만 고른 상태(불확정)도 나타냅니다.
category: form
platforms: [flutter, web]
related: [toggle, radio-group, switch-field]
tags: [form-control, selection, boolean]
template: v2
source: form/checkbox
---

# Checkbox

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

값과 크기를 바꿔 보며 체크박스를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="checkbox" />

값은 `checked` 하나가 세 상태를 나릅니다 — `true`(선택), `false`(해제), `null`(불확정). 체크박스는 값을 스스로 바꾸지 않습니다. 누르면 다음 값으로 `onChanged` 를 부르므로, 호출자가 그 값을 `checked` 로 다시 넘겨야 화면이 바뀝니다.

<a id="구조-anatomy"></a>

## 구조

체크박스는 박스와 라벨, 그리고 선택 사항인 설명과 슬롯으로 이루어집니다.

<Anatomy demo="checkbox/anatomy">
<AnatomyItem part="container" name="Container">

누르는 영역 전체. 박스 · 라벨 · 설명을 함께 누를 수 있습니다.

</AnatomyItem>
<AnatomyItem select=".co-checkbox-box" side="top" name="box">

선택하면 `primary` 로 채워지고 체크 표시가, 불확정이면 가로줄이 나타납니다.

</AnatomyItem>
<AnatomyItem select=".flex-col > span:first-child" side="top" name="label">

라벨. 체크박스의 이름이 됩니다.

</AnatomyItem>
<AnatomyItem select=".flex-col > span:last-child" side="right" name="description">

라벨 아래의 보조 문장. 선택 사항입니다.

</AnatomyItem>
</Anatomy>

`prefix` 는 박스 앞, `trailing` 은 행 끝에 놓이는 위젯 슬롯입니다. `suffix` 는 플랫폼마다 놓이는 자리가 다릅니다 — Flutter 에서는 라벨 자리를 대신하고, Jaspr Web 에서는 박스와 라벨 사이에 라벨과 함께 그려집니다(플랫폼 차이 참고).

## 크기

박스 12부터 24까지 6단계입니다. 체크 표시, 가로줄, 박스와 라벨 사이 간격, 글자 크기가 함께 바뀝니다.

<SizeSpec component="checkbox" label="동의합니다" />

<Note>

테두리 두께(1)와 박스 모서리(4), 가로줄 두께(1.25)는 크기와 무관하게 같습니다. 체크 표시는 Lucide 아이콘이라 [Lucide 획 규칙](/components/icon#lucide-획-규칙)을 따르고, 모든 크기에서 하한인 1.25 로 그려져 가로줄과 같은 두께로 읽힙니다.

</Note>

<a id="동작-스펙-behavior"></a>
<a id="변형-variants"></a>

## 상태

체크박스에는 variant 가 없습니다. 값(`true` · `false` · `null`)과 `enabled` 가 모양을 정합니다.

<Preview demo="checkbox/states" />

| 항목 | 동작 |
| --- | --- |
| 누를 때 (`tristate: false`) | 선택 ↔ 해제를 오갑니다. 불확정(`null`)에서 누르면 선택이 됩니다. |
| 누를 때 (`tristate: true`) | 선택 → 해제 → 불확정 → 선택 순으로 돕니다. 키보드로 누를 때도 같습니다. |
| 선택 · 불확정 | 박스를 `primary` 로 채우고 테두리도 같은 색이 됩니다. 체크 표시와 가로줄은 `onPrimary` 입니다. |
| Hover · 눌림 | 박스 둘레로 각 변 4만큼(박스 + 8, 모서리 8) `onSurface` 를 8% 로 칠하고, 누르는 동안 16% 로 진하게 합니다. Flutter 는 이 표시를 박스 뒤에 그려 선택된 박스의 채움은 그대로이고, Jaspr Web 은 박스 위에 겹쳐 그려 선택된 박스의 `primary` 채움도 함께 옅게 물듭니다. |
| 누르는 동안 크기 | 행 전체가 0.97배로 줄어듭니다. `checkboxStyle.clickableStyle` 로 바꿀 수 있습니다. |
| Focus | 키보드로 포커스했을 때만 **박스** 둘레에 링을 그립니다 — 박스에서 2만큼 비운 뒤 2 두께의 링입니다. 행 전체를 감싸지 않습니다. |
| 비활성 | 박스 채움 `disabledContainer`, 테두리 `disabledOutline`, 체크 표시 · 라벨 · 설명 `disabledContent`. Tab 순서에서 빠지고 hover 표시와 포커스 링이 없습니다 — Jaspr Web 은 마우스로 누르면 포커스가 가지만 링은 그리지 않습니다. `labelStyle` · `descriptionStyle` 에 직접 준 색은 비활성에서도 남습니다. |
| 전환 시간 | 박스 색 · 체크 표시 · hover 표시가 300ms 동안 바뀝니다. 동작 줄이기를 켜면 바로 바뀝니다. |
| 활성 여부 | `enabled` 를 지정하지 않으면 `onChanged` 가 있을 때 활성입니다. |
| 정렬 | `description` 이 있으면 박스를 라벨 첫 줄 위쪽에 맞추고, 없으면 가운데에 맞춥니다. |

<a id="상태-전환"></a>

### 불확정 — 전체 선택

하위 항목 중 일부만 골랐을 때, 위의 "전체 선택" 체크박스를 불확정으로 둡니다.

<Preview demo="checkbox/select-all" />

```dart
Checkbox(
  checked: allChecked ? true : (noneChecked ? false : null),
  tristate: true,
  label: '전체 선택',
  onChanged: toggleAll,
)
```

불확정을 화면에 보여 주기만 할 때는 `checked: null` 이면 됩니다. 누를 때 불확정을 다시 거치게 하려면 `tristate: true` 를 함께 줍니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 켜는 즉시 반영되는 설정 | [Toggle](/components/toggle) |
| 라벨과 설명을 가진 켜고 끄는 설정 행 | [SwitchField](/components/switch-field) |
| 여러 선택지 중 하나만 고를 때 | [RadioGroup](/components/radio-group) |
| 선택지를 펼쳐 두지 않고 하나를 고를 때 | [Select](/components/select) |

### 라벨

<Cards columns="2">
<Card component="checkbox" props="checked=false" label="마케팅 이메일 수신에 동의합니다" tone="do" eyebrow="이렇게 하세요">

라벨을 항상 붙입니다. 라벨까지 눌러서 고를 수 있어 누르기 쉽습니다.

</Card>
<Card component="checkbox" props="checked=false" tone="dont" eyebrow="이렇게 하지 마세요">

라벨이 없으면 무엇을 고르는지 알 수 없고, 스크린 리더가 읽을 이름도 없습니다.

</Card>
<Card component="checkbox" props="checked=true" label="알림 받기" tone="do" eyebrow="이렇게 하세요">

긍정형 라벨을 씁니다. 체크가 곧 "켜짐" 으로 읽힙니다.

</Card>
<Card component="checkbox" props="checked=true" label="알림 받지 않기" tone="dont" eyebrow="이렇게 하지 마세요">

부정형 라벨은 체크했을 때 이중 부정이 되어 헷갈립니다.

</Card>
</Cards>

<a id="스타일-시스템-style-system"></a>
<a id="스타일-시스템-checkboxstyle"></a>

## 테마와 스타일

크기는 위젯 속성 `size` 로 고르고, 박스의 색 · 테두리 · hover 표시 · 포커스 링 · 글자처럼 보이는 값은 `checkboxStyle`(`CoreCheckboxStyle`) 하나로 덮어씁니다.

<Split>

<Code language="dart" title="체크박스 하나만 바꾸기">
Checkbox(
  checked: agreed,
  onChanged: setAgreed,
  label: '동의합니다',
  checkboxStyle: CoreCheckboxStyle(
    boxActiveColor: CoreColor.token(CoreColors.tertiary),
    boxBorderRadius: CoreBorderRadius.all(CoreRadius.radius2),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    checkbox: CoreCheckboxTheme(
      style: CoreCheckboxStyle(
        minHeight: CoreA11ySize.touchTarget,
      ),
    ),
  ),
)
</Code>

</Split>

### 빠른 오버라이드 (Chain)

이미 만든 `Checkbox` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `checkboxStyle` 인자와 같게 동작합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class CheckboxChainExample extends StatefulWidget {
  const CheckboxChainExample({super.key});

  @override
  State<CheckboxChainExample> createState() => _CheckboxChainExampleState();
}

class _CheckboxChainExampleState extends State<CheckboxChainExample> {
  bool? _checked = false;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      checked: _checked,
      label: '약관 동의',
      onChanged: (value) => setState(() => _checked = value),
    ).withStyle(
      const CoreCheckboxStyle(
        boxBorderColor: CoreColor.token(CoreColors.primary),
        boxBorderWidth: CoreStrokeWidth.stroke2,
        boxBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        boxSize: CoreSize.size24,
        indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class CheckboxChainExample extends StatefulComponent {
  const CheckboxChainExample({super.key});

  @override
  State<CheckboxChainExample> createState() => _CheckboxChainExampleState();
}

class _CheckboxChainExampleState extends State<CheckboxChainExample> {
  bool? _checked = false;

  @override
  Component build(BuildContext context) {
    return Checkbox(
      checked: _checked,
      label: '약관 동의',
      onChanged: (value) => setState(() => _checked = value),
    ).withStyle(
      const CoreCheckboxStyle(
        boxBorderColor: CoreColor.token(CoreColors.primary),
        boxBorderWidth: CoreStrokeWidth.stroke2,
        boxBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        boxSize: CoreSize.size24,
        indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
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
기본값 (default* · defaultsBySize[size])
  → CoreComponentTheme.checkbox.style   // 앱 전체
  → checkboxStyle                       // 인스턴스
```

뒤로 갈수록 우선합니다. 체크박스를 안에 그리는 컴포넌트(MultiAnswerCard 등)는 자기 값을 그 체크박스의 `checkboxStyle` 로 넘깁니다. 라벨과 설명 글자는 역할 기본값 위에 크기 행의 글자 크기가 얹히고, 그 위에 테마와 인스턴스 값이 얹힙니다.

<Note>

체크 표시의 크기는 `checkmarkSize` 와 `checkmarkIconStyle.size` 둘 다로 줄 수 있습니다. 둘 다 주면 `checkmarkIconStyle.size` 가 이깁니다.

</Note>

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreCheckboxStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `boxBackgroundColor` | `CoreColor?` | Resting (unchecked) box fill colour override. `null` defers to [defaultBoxBackgroundColor]. |
| `boxActiveColor` | `CoreColor?` | Box fill colour when checked or indeterminate — the border takes the same colour, so the stroke blends into the fill. `null` defers to [defaultBoxActiveColor]. |
| `boxBorderColor` | `CoreColor?` | Resting (unchecked) box stroke colour override. `null` defers to [defaultBoxBorderColor]. |
| `boxBorderWidth` | `double?` | Box stroke width override (logical px, pre-scaling). `null` defers to [defaultBoxBorderWidth]. |
| `boxBorderRadius` | `CoreBorderRadius?` | Box corner override. `null` defers to [defaultBoxBorderRadius]. The focus ring's corner derives from this one (plus its own offset), so the ring stays concentric with a rounder box. |
| `boxSize` | `double?` | Box size (width = height) override (logical px). `null` defers to [defaultsBySize] for the widget's size. |
| `checkmarkSize` | `double?` | Checkmark glyph icon size override (logical px). `null` falls back to [defaultsBySize] for the widget's size, unless `checkmarkIconStyle.size` sets one. |
| `indeterminateLength` | `double?` | Indeterminate dash *length* override (logical px) — the dash is a horizontal pill [markThickness] tall. `null` falls back to [defaultsBySize] for the widget's size. |
| `indeterminateBorderRadius` | `CoreBorderRadius?` | Corner of the indeterminate dash. `null` → [defaultIndeterminateBorderRadius] (a pill). |
| `markThickness` | `double?` | Thickness of the indeterminate dash — one constant across sizes. The checkmark is an icon and follows the icon stroke rule, not this value. `null` defers to [defaultMarkThickness]. |
| `disabledBackgroundColor` | `CoreColor?` | Box fill when disabled. `null` → [defaultDisabledBackgroundColor]. |
| `disabledBorderColor` | `CoreColor?` | Box stroke when disabled. `null` → [defaultDisabledBorderColor]. |
| `disabledForegroundColor` | `CoreColor?` | Label and description foreground when disabled. `null` → [defaultDisabledForegroundColor]. |
| `disabledCheckmarkColor` | `CoreColor?` | Checkmark / dash colour when disabled. `null` → [defaultDisabledCheckmarkColor]. |
| `stateLayer` | `CoreStateLayer?` | Ramp the halo is painted at while hovered or pressed. `null` → [defaultStateLayer]. The focus rung is unused — focus draws the ring. |
| `stateLayerColor` | `CoreColor?` | Halo ink. `null` → [defaultStateLayerColor]. |
| `stateLayerSpread` | `double?` | How far the halo reaches beyond the box on each side (logical px, pre-scaling). `null` → [defaultStateLayerSpread]. |
| `stateLayerBorderRadius` | `CoreBorderRadius?` | Halo corner. `null` → [defaultStateLayerBorderRadius]. |
| `indicatorLabelGapStyle` | `CoreGapStyle?` | Gap between the checkbox box and the label / prefix / suffix slot, passed to the `Gap` between them as is. `null` defers to [defaultsBySize] for the widget's size, then to [defaultIndicatorLabelGapStyle]. |
| `transitionDuration` | `Duration?` | State-change transition duration override (box colour fade + glyph slot scale / opacity + halo fade). `null` defers to [defaultTransitionDuration]. |
| `checkmarkIconStyle` | `CoreIconStyle?` | Checkmark icon style override (size / colour). Merged on top of `CoreIconStyle(size: checkmarkSize)` and [defaultCheckmarkIconStyle], so a colour-only override keeps the size-ladder glyph and a size-only override keeps the `onPrimary` ink. |
| `clickableStyle` | `CoreClickableStyle?` | Style for the checkbox's `Clickable` — press scale, durations, disabled opacity. Laid over [defaultClickableStyle] and passed to the `Clickable` as is, which fills what is left unset with its own defaults. Its `focusOutlineStyle` has no effect here — see [focusOutlineStyle]. |
| `focusOutlineStyle` | `CoreFocusOutlineStyle?` | Focus ring the checkbox draws around its box while focused. Laid over [defaultFocusOutlineStyle]; the corner comes from the box. |
| `labelStyle` | `CoreTextStyle?` | Label text style override. |
| `descriptionStyle` | `CoreTextStyle?` | Description text style override — the supporting line under the label. `null` defers to [defaultsBySize] for the widget's size (which carries only the `fontSize` step), then to [defaultDescriptionStyle] for the role and colour. |
| `labelDescriptionGapStyle` | `CoreGapStyle?` | Vertical gap between the label and the description below it. `null` defers to [defaultLabelDescriptionGapStyle]. |
| `minHeight` | `double?` | Minimum height of the pressable row — box, label and description together — before scaling. The row keeps its cross-axis alignment in the extra height and stays the press area as a whole, so a theme can give every checkbox a touch target (for example `CoreA11ySize.touchTarget`). Falls back to [defaultMinHeight]. |

<!-- STYLE_TABLE:END -->

<a id="접근성-accessibility"></a>

## 접근성

Flutter 는 `Semantics(checked:, mixed:)` 로, Jaspr Web 은 `role="checkbox"` 와 `aria-checked` 로 체크 상태를 알립니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | `Semantics(checked:)` 로 선택 여부를, 불확정이면 `mixed` 를 함께 알립니다. 안에 그리는 `Clickable` 의 버튼 역할은 끄므로 "버튼" 이 아니라 체크박스로 읽힙니다. 비활성이면 비활성으로 알립니다. |
| Jaspr Web | 누르는 영역 한 곳에만 `role="checkbox"` · `aria-checked`(`true` · `false` · `mixed`) · `tabindex` 가 붙고, 비활성이면 `aria-disabled="true"` 가 더해집니다. 안쪽 박스와 체크 표시는 아무 역할도 갖지 않습니다. |

`name` 을 주면 Jaspr Web 은 폼 제출용 숨은 `<input type="checkbox">` 를 함께 그립니다. 이 입력은 `aria-hidden="true"` · `tabindex="-1"` 이라 스크린 리더에도 Tab 순서에도 나타나지 않습니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Space` · `Enter` | 다음 값으로 바꿉니다. 네이티브 체크박스와 달리 `Enter` 로도 바뀌고, 키를 뗄 때가 아니라 누를 때 바뀝니다. |
| `Tab` | 다음 요소로 포커스를 옮깁니다. 체크박스마다 한 번 멈춥니다. |
| `Shift` · `Tab` | 이전 요소로 포커스를 옮깁니다. |

<Note>

비활성 체크박스는 포커스 순서에서 빠집니다. 화살표 · `Home` · `End` · `Escape` 는 처리하지 않습니다.

</Note>

### 스크린 리더

접근 가능한 이름은 체크박스 안의 **글자 전체**에서 옵니다 — `label` 뿐 아니라 `description`, `prefix` · `suffix` · `trailing` 에 넣은 글자도 이름에 합쳐집니다. 그래서 `description` 은 보조 설명이 아니라 이름의 일부로 읽힙니다. 글자가 하나도 없으면 이름이 비고, 리더는 역할과 상태만 읽습니다.

선택 · 해제 · 불확정과 비활성은 두 플랫폼 모두 알립니다. 값이 바뀐 사실을 따로 알리는 라이브 리전은 없고, 상태는 체크박스 자신에 실려 있습니다.

### 포커스 관리

마운트될 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. 포커스 링은 키보드로 포커스했을 때만 박스 둘레에 나타납니다. Jaspr Web 은 마우스로 눌러도 체크박스에 포커스가 가지만, 이때는 링이 보이지 않습니다. Flutter 는 눌러도 포커스를 옮기지 않습니다.

### 터치 타깃

박스가 작아도 누르는 영역은 최소 24×24 입니다 — Flutter 는 행 전체를, Jaspr Web 은 박스를 넓힙니다. 행 전체의 높이를 48 까지 키우려면 테마에서 `minHeight` 를 켭니다(위 "앱 전체 기본값 바꾸기"). 행이 그 높이 이상이 되고, 늘어난 높이까지 눌립니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | 라벨 없이 이름을 붙일 방법이 없습니다. 생성자가 `aria-label` 같은 속성을 받지 않습니다. |
| Jaspr Web | `prefix` · `suffix` · `trailing` 안의 버튼이나 링크를 누르면 체크박스도 함께 바뀝니다. 슬롯에는 아이콘처럼 누르지 않는 내용만 둡니다. |
| 공통 | `description` 이 `aria-describedby` 같은 보조 설명으로 연결되지 않고 이름에 합쳐집니다. |
| 공통 | `Space` · `Enter` 를 누르고 있으면 키가 반복될 때마다 다시 바뀝니다. |
| Jaspr Web | 강제 색상(고대비) 모드에서는 포커스 링이 박스가 아니라 행 전체에 그려집니다. |
| Jaspr Web | 숨은 폼 입력은 선택일 때만 값(`on`)을 보내고, 불확정은 보내지 않습니다. |
| Flutter | `name` 과 `controller` 는 받지만 아직 아무 일도 하지 않습니다. 값은 `checked` 와 `onChanged` 로 다룹니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 체크 상태 알림 | `Semantics(checked:, mixed:)` | `role="checkbox"` · `aria-checked` |
| `suffix` | 라벨 자리를 대신합니다(라벨은 그리지 않음) | 박스와 라벨 사이에 라벨과 함께 그립니다 |
| 폼 값 | `FormValueSupplier`. `name` 은 쓰지 않습니다 | `FormValueSupplier` 와, `name` 이 있으면 숨은 `<input type="checkbox">` |
| 포커스 · 상태 제어 | `focusNode` · `statesController` | 브라우저 포커스와 CSS 상태 |
| 마우스로 눌렀을 때 포커스 | 옮기지 않습니다 | 체크박스로 옮깁니다(링은 없음) |
| 최소 누르는 영역(24) | 행 전체를 넓힙니다 | 박스를 넓힙니다 |
| `minHeight` | 화면 배율(`scaling`)을 곱합니다 | rem 으로 내보내 브라우저 글자 크기를 따릅니다 |
| `checked` · `onChanged` | 둘 다 넘겨야 합니다 | 생략하면 `false` · `null` 입니다 |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다.

### 값과 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `checked` | `bool?` | 필수 (Web 은 `false`) | `true` 선택 · `false` 해제 · `null` 불확정 |
| `onChanged` | `ValueChanged<bool?>?` | 필수 (Web 은 `null`) | 다음 값을 받습니다. 값은 호출자가 반영합니다. |
| `tristate` | `bool` | `false` | 누를 때 불확정을 거칩니다. |
| `label` | `String?` | `null` | 라벨. 이름이 됩니다. |
| `labelMaxLines` | `int?` | `null` | 라벨의 최대 줄 수. 지정하지 않으면 제한하지 않습니다. |
| `labelOverflow` | `CoreTextOverflow?` | `null` | 최대 줄 수를 넘긴 라벨의 처리 |
| `description` | `String?` | `null` | 라벨 아래 보조 문장 |
| `prefix` | `Widget?` | `null` | 박스 앞 슬롯 |
| `suffix` | `Widget?` | `null` | Flutter 는 라벨 자리, Web 은 박스와 라벨 사이 |
| `trailing` | `Widget?` | `null` | 행 끝 슬롯 |

### 상태와 형태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `enabled` | `bool?` | `null` | 지정하지 않으면 `onChanged` 유무로 정합니다. |
| `size` | `CoreComponentSize` | `md` | 박스 · 간격 · 글자 크기 |
| `checkboxStyle` | `CoreCheckboxStyle?` | `null` | 보이는 값 덮어쓰기 |
| `name` | `String?` | `null` | 폼 제출 이름 (Web 만 숨은 입력으로 씁니다) |

### Flutter 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `focusNode` | `FocusNode?` | `null` | 포커스를 직접 제어할 때 |
| `statesController` | `WidgetStatesController?` | `null` | 상태를 직접 제어할 때 |
| `controller` | `CheckboxController?` | `null` | 받지만 아직 쓰이지 않습니다. |

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="checkbox/related-toggle" title="Toggle">

켜는 즉시 반영되는 설정에 씁니다.

</Card>
<Card demo="checkbox/related-radio-group" title="RadioGroup">

여러 선택지 중 하나만 고릅니다.

</Card>
<Card demo="checkbox/related-switch-field" title="SwitchField">

라벨과 설명을 가진 켜고 끄는 설정 행입니다.

</Card>
</Cards>
