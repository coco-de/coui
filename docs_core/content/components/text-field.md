---
title: TextField
description: 한 줄 텍스트를 입력받는 기본 입력 컴포넌트입니다. 라벨, 도움말, 오류 문구를 함께 다룹니다.
category: form
platforms: [flutter, web]
related: [select, text-area, form]
tags: [form-control, text, interactive]
template: v2
source: form/text_field
---

# TextField

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 입력창을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="text-field" />

<a id="구조-anatomy"></a>

## 구조

입력창은 라벨, 컨테이너, 입력 값, 도움말로 이루어집니다.

<Anatomy demo="text-field/anatomy">
<AnatomyItem select="label" side="left" name="label">

입력할 내용을 알려 줍니다. 항상 보여 주는 것을 권장합니다.

</AnatomyItem>
<AnatomyItem select="div:has(> input)" side="left" name="Container">

테두리와 배경. 상태에 따라 테두리가 바뀝니다.

</AnatomyItem>
<AnatomyItem select="input" side="right" name="value">

입력 값. 비어 있으면 placeholder를 보여 줍니다.

</AnatomyItem>
<AnatomyItem select="p" side="left" name="description">

도움말. 오류일 때는 errorText로 바뀝니다.

</AnatomyItem>
</Anatomy>

<a id="변형-variants"></a>

## Variant

배경이 있는 화면에서는 filled를, 다른 표면 안에 들어가면 plain을, 그 밖에는 기본(defaultVariant)을 씁니다.

<VariantRow name="defaultVariant" component="text-field" props="variant=defaultVariant;placeholder=이메일">

기본 입력창입니다. 흰 배경의 폼에 씁니다.

</VariantRow>

<VariantRow name="filled" component="text-field" props="variant=filled;placeholder=이메일">

회색 배경으로 영역을 구분합니다. 카드나 시트 안처럼 배경이 있는 곳에 씁니다.

</VariantRow>

<VariantRow name="plain" component="text-field" props="variant=plain;placeholder=검색">

상자 · 테두리 · 채움 없이 글자와 커서만 그립니다. Command 검색 줄이나 메뉴 필터처럼 다른 표면 안에 들어가는 입력창에 씁니다.

</VariantRow>

<Note>

error는 직접 고르지 않습니다. errorText를 지정하면 켜지고, 비활성일 때는 꺼집니다. 모양은 상태 섹션의 오류를 보세요.

</Note>

### 의미 체인

`TextField().error`는 `variant: .error`의 시각 스타일을 선택합니다. 검증에 실패하면 `errorText` 또는 폼 검증을 통해 실제 오류와 메시지를 전달합니다.

## 크기

Button과 같은 높이 사다리를 써서 한 줄에 함께 놓을 수 있습니다.

<SizeSpec component="text-field" props="placeholder=이메일" />

`xs`는 호환용 크기입니다. 새 입력창과 기존 `xs` 입력창을 갱신할 때는 `sm`을 사용하세요.

<a id="동작-스펙-behavior"></a>

## 상태

입력창은 다섯 가지 상태를 가집니다.

<Preview demo="text-field/states" />

| 항목 | 동작 |
| --- | --- |
| Focus | 테두리 색이 바뀝니다. 굵기는 그대로라 상자 크기가 변하지 않습니다. |
| 오류 | 테두리와 도움말이 오류 색으로 바뀝니다. errorText를 지정하면 켜집니다. |
| 비활성 | 값을 바꿀 수 없고 포커스도 받지 않습니다. |
| 읽기 전용 | 값을 선택하고 복사할 수는 있지만 바꿀 수 없습니다. |

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 여러 줄을 입력받을 때 | [TextArea](/components/text-area) |
| 정해진 선택지에서 고를 때 | [Select](/components/select) |
| 날짜를 고를 때 | [DatePicker](/components/date-picker) |

### 라벨과 오류

<Cards columns="2">
<Card demo="text-field/do-visible-label" tone="do" eyebrow="이렇게 하세요">

라벨을 항상 보여 주고, placeholder에는 예시를 씁니다.

</Card>
<Card demo="text-field/dont-placeholder-label" tone="dont" eyebrow="이렇게 하지 마세요">

placeholder를 라벨 대신 쓰면 입력하는 순간 무엇을 쓰던 중인지 사라집니다.

</Card>
<Card demo="text-field/do-helpful-error" tone="do" eyebrow="이렇게 하세요">

오류 문구에는 고치는 방법을 함께 씁니다.

</Card>
<Card demo="text-field/dont-vague-error" tone="dont" eyebrow="이렇게 하지 마세요">

무엇이 잘못됐는지만 말하면 다음 행동을 알 수 없습니다.

</Card>
</Cards>

<a id="접근성-accessibility"></a>

## 접근성

편집 표면은 Flutter의 텍스트 필드 노드와 웹의 네이티브 `<input>`입니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 편집 표면이 만드는 텍스트 필드 노드에 활성 상태와 포커스 동작이 붙습니다. |
| Jaspr Web | 네이티브 `<input>`의 역할(`textbox`)을 그대로 씁니다. |

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` | 다음 입력창으로 이동합니다. |
| `Shift` · `Tab` | 이전 입력창으로 이동합니다. |
| `Enter` | 한 줄 입력창에서는 `onSubmitted`를 부릅니다. |

### 스크린 리더

<Preview demo="text-field/a11y-label" />

웹에서 입력창의 이름은 `placeholder`나 `title`에서 옵니다. `label`은 화면에 보이지만 아직 입력창의 이름으로 연결되지 않습니다. 웹은 오류 상태를 `aria-invalid`로 알리지만 오류 문구는 함께 읽히지 않고, 값 변경은 알리지 않습니다.

<Note>

라벨을 숨겨야 할 때도 접근 가능한 이름은 반드시 지정합니다. 웹에서는 지금 `title`로 지정할 수 있습니다.

</Note>

### 포커스 관리

마운트될 때 포커스를 옮기지 않습니다. `autofocus: true`를 주면 처음 그려질 때 포커스를 가져갑니다. 포커스를 가두지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | `label`이 `<input>`에 연결되지 않습니다. 라벨을 눌러도 포커스가 옮겨 가지 않습니다. |
| Jaspr Web | `description` · `errorText`가 `aria-describedby`로 연결되지 않아, 오류 상태(`aria-invalid`)는 알려도 오류 문구는 함께 읽히지 않습니다. |
| Flutter | `label` · `errorText`가 시맨틱 노드에 닿지 않습니다. |
| Jaspr Web | 비밀번호 보기 · 지우기 버튼에 키보드로 닿을 수 없습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 편집 표면 | `EditableText` | 네이티브 `<input>` |
| 라벨 | 입력창 위에 그립니다. 시맨틱에는 닿지 않습니다. | `<label>`로 그립니다. 입력창과 연결되지 않습니다. |
| 오류 | 오류 색과 문구로 그립니다. | 오류 색과 문구로 그리고 `aria-invalid`를 붙입니다. 문구는 입력창과 연결되지 않습니다. |
| 자동 완성 | `autofillHints` | `autocomplete` 속성 |

<a id="props-parameters"></a>
<a id="스타일-시스템-style-system"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다.

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String?` | `null` | 입력창 라벨 |
| `placeholder` | `Widget?` | `null` | 비어 있을 때 보이는 예시 |
| `description` | `String?` | `null` | 입력창 아래 도움말 |
| `errorText` | `String?` | `null` | 지정하면 오류 상태가 됩니다. |
| `prefix` | `Widget?` | `null` | 입력 값 앞 아이콘 |
| `suffix` | `Widget?` | `null` | 입력 값 뒤 아이콘 |

### 상태와 형태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `variant` | `CoreTextFieldVariant?` | `null` | 지정하지 않으면 defaultVariant. defaultVariant, filled, error, plain |
| `size` | `CoreComponentSize` | `md` | 권장 크기: sm, md, lg, xl, xl2 |
| `enabled` | `bool` | `true` | false면 비활성 |
| `readOnly` | `bool` | `false` | 값을 바꿀 수 없게 합니다. |
| `obscureText` | `bool` | `false` | 비밀번호처럼 값을 가립니다. |
| `textFieldStyle` | `CoreTextFieldStyle?` | `null` | 보이는 값 덮어쓰기 |

### 콜백과 제어

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `controller` | `TextEditingController?` | `null` | 값을 직접 제어할 때 |
| `onChanged` | `ValueChanged<String>?` | `null` | 값이 바뀔 때 |
| `onSubmitted` | `ValueChanged<String>?` | `null` | Enter로 제출할 때 |
| `focusNode` | `FocusNode?` | `null` | 포커스를 직접 제어할 때 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreTextFieldStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Background fill colour override. |
| `borderColor` | `CoreColor?` | Border stroke colour override (idle state). |
| `focusBorderColor` | `CoreColor?` | Border stroke colour when the field is focused. |
| `hoverBorderColor` | `CoreColor?` | Border stroke colour while the pointer is over the field. `null` → the variant's `hoverBorderColor` (`on-surface` on the ordinary field, `error` on the error one). |
| `stateLayer` | `CoreStateLayer?` | The wash laid over the fill while hovered / focused / pressed. `null` → the variant's own ramp (`CoreTextFieldVariantStyle.stateLayer`). A composing parent states its own ramp here — `Select`'s trigger is pressed-only, because its hover is a border step and its focus is the ring. |
| `errorBorderColor` | `CoreColor?` | Border stroke colour when the field is in error state. |
| `borderWidth` | `double?` | Border stroke width override (logical px, pre-scaling) — the resting boundary, which stays in the layout. `null` → [defaultBorderWidth]. |
| `activeBorderWidth` | `double?` | Width of the active boundary (logical px, pre-scaling) — a focused field, or one wearing the error variant while enabled (`disabled > error`). `null` → [defaultActiveBorderWidth]. |
| `borderRadius` | `CoreBorderRadius?` | Border radius override (pre-scaling). `null` → the size row's corner (`defaultsBySize[size].borderRadius`, the control height × 0.25). |
| `height` | `double?` | Fixed height override (logical px). Stating it fixes the box and drops the size row's floor ([minHeight]). |
| `minHeight` | `double?` | Minimum height of the box (logical px). `null` defers to the size row's control height in [defaultsBySize]; `0` states no floor at all — what a chromeless composition (a field inside another component's frame) says. See [boxMinHeight]. |
| `maxHeight` | `double?` | Maximum height constraint (logical px). |
| `padding` | `CoreEdgeInsets?` | Padding override (logical px). |
| `labelPadding` | `CoreEdgeInsets?` | Padding applied to the label element. `null` defers to [defaultLabelPadding]. |
| `descriptionPadding` | `CoreEdgeInsets?` | Padding applied to the description / error helper text element. `null` defers to [defaultDescriptionPadding]. |
| `rowSpacing` | `double?` | Native `Row.spacing` between the prefix / input / suffix row children (logical px). `null` defers to [defaultRowSpacing]. |
| `iconStyle` | `CoreIconStyle?` | Icon size shared by the leading and trailing icons — only its `size` is read, and a size in [leadingIconStyle] / [trailingIconStyle] wins over it. `null` defers to `CoreTextFieldStyle.defaultsBySize[size]!.iconStyle!`. |
| `fileLabelFontWeight` | `int?` | Font weight applied to the file-upload `<input type="file">` label segment. `null` defers to [defaultFileLabelFontWeight]. |
| `transitionDuration` | `Duration?` | How long the field's look (border, fill) takes to change between states. `null` defers to [defaultTransitionDuration]. |
| `textAlign` | `CoreTextAlign?` | Horizontal text alignment override. `null` defers to [defaultTextAlign]. |
| `textAlignVertical` | `CoreVerticalAlign?` | Vertical alignment of the text within the input. `null` defers to [defaultTextAlignVertical]. |
| `crossAxisAlignment` | `CoreVerticalAlign?` | Vertical alignment override for the prefix / input / suffix row. `null` defers to [defaultCrossAxisAlignment]. |
| `cursorColor` | `CoreColor?` | Cursor colour override. |
| `cursorWidth` | `double?` | Cursor width override (logical px). |
| `cursorHeight` | `double?` | Cursor height override (logical px before text scaling). |
| `cursorRadius` | `CoreBorderRadius?` | Cursor corner radius override. |
| `labelDisabledColor` | `CoreColor?` | Disabled-state label text colour override. `null` → [defaultLabelDisabledColor]. |
| `descriptionColor` | `CoreColor?` | Description / helper text colour override. `null` → [defaultDescriptionColor]. |
| `affixColor` | `CoreColor?` | Prefix / suffix affix glyph colour override. `null` → [defaultAffixColor]. |
| `errorColor` | `CoreColor?` | Error helper-text colour override. `null` → [defaultErrorColor]. |
| `selectionColor` | `CoreColor?` | Text-selection tint colour override. `null` → [defaultSelectionColor]. |
| `backgroundCursorColor` | `CoreColor?` | Background-cursor (composition/IME) colour override. `null` → [defaultBackgroundCursorColor]. |
| `focusOutlineStyle` | `CoreFocusOutlineStyle?` | Focus ring override ([CoreFocusOutlineStyle]) — ring colour, radius, width, offset and the colour of the band in the offset. `null` (or any field left unset in it) defers to [defaultFocusOutlineStyle]. A `borderColor` stated here outranks [focusBorderColor] and the variant's focus-ring tone; a `borderRadius` stated here outranks the field's own [borderRadius]. |
| `baseTextStyle` | `CoreTextStyle?` | Base text style applied to the value / placeholder / affix slots before each one's own style override merges on top. `null` defers to `CoreTextFieldStyle.defaultsBySize[size]!.baseTextStyle!` (size-aware — `bodyMedium` for xs/sm/md/lg, `bodyLarge` for xl/xl2, each at the role's own line height). |
| `labelStyle` | `CoreTextStyle?` | Label text style override — forwarded whole into the composed `FormLabel`'s own `formLabelStyle.labelStyle` slot (child-component- composition). By design has no `default` of its own here: `TextField` never merges this onto its own [baseTextStyle], because `FormLabel` owns the label's per-size ladder on its own split point (`CoreFormLabelStyle.defaultsBySize`). `null` → `FormLabel`'s own size-keyed default. |
| `placeholderStyle` | `CoreTextStyle?` | Placeholder text style override, laid over [baseTextStyle] — the same per-size base the input value uses. Unset, the placeholder keeps the field's own typography. |
| `valueStyle` | `CoreTextStyle?` | Input value text style override, laid over [baseTextStyle] like [placeholderStyle], so the caret's line box and the value text share the one per-size base. |
| `descriptionStyle` | `CoreTextStyle?` | Description / helper text style override. |
| `errorStyle` | `CoreTextStyle?` | Error text style override. |
| `leadingIconStyle` | `CoreIconStyle?` | Leading icon style override. |
| `trailingIconStyle` | `CoreIconStyle?` | Trailing icon style override. No `default*` — second rung of the precedence chain documented on [leadingIconStyle]; a value here would shadow the shared [iconStyle] slot and the size table. |
| `featureButtonStyle` | `CoreButtonStyle?` | Style for the field's feature buttons (clear / password toggle). Laid over [defaultFeatureButtonStyle] and the size row's own `featureButtonStyle` (the row's corner), then passed as is to `Button(variant:.plain, buttonStyle: …)` on both platforms. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="text-field/related-select" title="Select">

정해진 선택지에서 하나를 고릅니다.

</Card>
<Card demo="text-field/related-text-area" title="TextArea">

여러 줄 텍스트를 입력받습니다.

</Card>
<Card demo="text-field/related-form" title="Form">

입력 요소를 묶고 한 번에 검증합니다.

</Card>
</Cards>
