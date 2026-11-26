---
title: NumberInput
description: 버튼으로 올리고 내리는 한 줄 숫자 입력 — 인원 · 수량처럼 작은 수
category: form
platforms: [flutter, web]
related: [text-field, stepper, button]
tags: [interactive, form-control, number]
template: v2
source: form/number_input
---

# NumberInput

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 NumberInput 을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="number-input" />

NumberInput 은 `[ − ] 값 [ + ]` 한 줄로 숫자를 올리고 내리는 입력입니다. 인원 · 수량처럼 작은 수를 고를 때 씁니다. 필드 상자 전체가 [TextField](/components/text-field) 이고, 두 [Button](/components/button) 은 그 안의 앞 · 뒤 자리에 놓입니다. 그래서 테두리 · 채움 · hover · 포커스 · 오류 · 라벨 · 도움말이 TextField 와 같은 값이고, 테두리와 채움이 두 버튼까지 감쌉니다. 두 버튼과 위 · 아래 화살표 키는 값을 `step` 만큼 움직이고, 값은 늘 `min` ~ `max` 안에 머뭅니다. 끝에 닿으면 그 방향의 버튼이 비활성이 됩니다.

<a id="구조-anatomy"></a>

## 구조

NumberInput 은 라벨, 필드 안의 두 버튼과 값 칸, 도움말로 이루어집니다.

<Anatomy demo="number-input/anatomy">
<AnatomyItem select="label" side="left" name="label">

필드 위의 이름. `label` 이 `null` 이면 그리지 않습니다.

</AnatomyItem>
<AnatomyItem select="button" side="left" name="decrease">

값을 `step` 만큼 줄이는 정사각 버튼 — `Button` 의 `plain` · `square` 입니다. `min` 에 닿으면 비활성이 됩니다.

</AnatomyItem>
<AnatomyItem select="input" side="top" name="value">

가운데 정렬한 값 칸. 숫자를 직접 입력할 수도 있습니다.

</AnatomyItem>
<AnatomyItem select="input + span > button" side="right" name="increase">

값을 `step` 만큼 늘리는 정사각 버튼. `max` 에 닿으면 비활성이 됩니다.

</AnatomyItem>
<AnatomyItem select="p" side="left" name="description">

필드 아래 도움말. `errorText` 가 있으면 그 문구로 바뀝니다.

</AnatomyItem>
</Anatomy>

필드의 상자(테두리 · 채움)는 TextField 가 그립니다. 두 버튼은 좌우로 테두리 안쪽에서 4 떨어져 놓이고 위아래로는 필드 가운데에 놓입니다. 버튼과 값 칸 사이에는 간격이 없습니다.

<a id="변형-variants"></a>

## Variant

배경이 있는 화면에서는 filled 를, 그 밖에는 기본(defaultVariant)을 씁니다. 각 variant 는 TextField 의 같은 이름의 variant 로 그립니다.

<a id="variant-defaultvariant"></a>

<VariantRow name="defaultVariant" component="number-input" props="variant=defaultVariant;label=인원">

테두리가 있는 기본 필드입니다. 채움 `surface`, 테두리 `outlineVariant`.

</VariantRow>

<a id="variant-filled"></a>

<VariantRow name="filled" component="number-input" props="variant=filled;label=인원">

테두리 대신 채움(`surfaceContainer`)으로 경계를 나타냅니다. 테두리가 채움과 같은 색이라 면으로 읽힙니다. 카드나 시트 안처럼 이미 틀이 있는 면 위에 씁니다.

</VariantRow>

<a id="variant-error"></a>

<VariantRow name="error" component="number-input" props="variant=error;label=인원">

테두리가 `error` 색입니다. 모양만 바꾸고 문구는 그리지 않습니다 — 검증 메시지는 `errorText` 로 줍니다.

</VariantRow>

<Note>

`errorText` 를 주면 `variant: error` 없이도 오류 테두리와 문구가 함께 켜지고, `null` 로 바꾸면 도움말이 돌아옵니다. filled 에 `errorText` 를 주면 채움 대신 오류 모양으로 그립니다. `description` 은 일반 도움말이라 `variant: error` 에서도 설명 색 그대로입니다.

filled 의 채움은 `surfaceContainer` 라, 라이트 모드에서 같은 색으로 채운 면 위에 놓으면 채움으로는 경계가 구분되지 않습니다. `surface` 바탕 위에서는 채움으로 경계가 보입니다.

</Note>

## 크기

필드 높이 32 · 40 · 48 의 3단계입니다. 양 끝 버튼은 필드보다 한 단 낮은 Button(24 · 32 · 40)입니다. 세 크기 모두 버튼은 좌우로 테두리 안쪽 4, 위아래로 테두리 안쪽 3 떨어져 필드 가운데에 놓입니다.

<SizeSpec component="number-input" />

<Note>

필드는 같은 이름의 TextField 단(sm · md · lg)을 따르므로, 같은 크기의 TextField 와 한 줄에 놓입니다. 필드 폭은 테두리 · 여백(4) · 두 버튼 · 값 칸(32 · 40 · 48)을 더한 값이고, `numberInputStyle` 의 `width` 로 바꿀 수 있습니다. 값 글자는 세 크기 모두 `bodyMedium`(14 · 행간 150%)으로, 다른 입력의 값과 같은 본문 글자입니다.

</Note>

<a id="동작-스펙-behavior"></a>
<a id="상태-전환"></a>

## 상태

필드는 TextField 의 상태를, 두 버튼은 Button 의 `plain` 상태를 따릅니다.

<Preview demo="number-input/states" />

| 항목 | 동작 |
| --- | --- |
| 쉴 때 | 테두리 `outlineVariant`, 채움 `surface`, 값 `onSurface`. filled 는 채움 · 테두리 `surfaceContainer` |
| Hover | 필드의 테두리가 `outline` 으로 한 단 진해집니다. filled 는 채움 · 테두리가 `surfaceContainerHigh` 가 됩니다. 오류 필드는 `error` 그대로입니다. |
| Focus | 값 칸에 포커스가 있으면 테두리가 `primary`(오류 필드는 `error`)로 바뀝니다. 굵기는 1 그대로라 필드 크기가 변하지 않습니다. 키보드로 포커스했을 때만 바깥에 링을 그립니다. |
| 오류 | `errorText` 나 `variant: error` 면 테두리 · hover · 포커스가 모두 `error` 입니다. `errorText` 가 있으면 도움말 자리에 그 문구를 `error` 색으로 보입니다. |
| 비활성 | 채움 `disabledContainer`, 테두리 `disabledOutline`, 값 `disabledContent`(filled 는 채움 · 테두리 `surfaceContainerLow`). 두 버튼도 비활성이고 키에 반응하지 않습니다. 비활성이 오류 모양보다 우선하지만 `errorText` 문구는 보입니다. |
| 끝에 닿음 | 값이 `min` 이면 − 버튼이, `max` 이면 + 버튼이 비활성이 됩니다. 반대쪽 버튼은 그대로 눌립니다. |
| 두 버튼 | 바탕 없이 글리프만 그립니다 — 쉴 때 `onSurfaceVariant`, hover `onSurface`, 비활성 `disabledContent`. |

<a id="인터랙션"></a>

### 값을 움직이는 방법

- − · + 버튼은 값을 `step` 만큼 움직이고 `onChanged` 를 부릅니다.
- 위 · 아래 화살표는 `step`, Page Up · Page Down 은 `step × 10` 만큼 움직입니다. 포커스가 값 칸과 두 버튼 중 어디에 있어도 됩니다.
- 값은 `min` ~ `max` 를 넘지 않습니다. 끝을 넘는 걸음은 끝에서 멈춥니다.
- `enabled: false` 면 버튼도 키도 값을 움직이지 않습니다.

### 직접 입력한 값

값 칸에 숫자를 직접 입력할 수 있습니다. 범위 안의 숫자는 입력하는 즉시 값이 되고 `onChanged` 가 불립니다. 범위 밖이거나 아직 숫자가 아닌 입력(`-` 하나처럼)은 값 칸의 포커스가 빠지거나 Enter 를 누를 때 확정합니다 — 범위 밖은 가까운 끝으로, 숫자가 아니면 이전 값으로 돌아갑니다. 값 칸에서 버튼으로 포커스를 옮길 때도 확정합니다.

Jaspr Web 에서는 범위 밖의 수를 입력하면 필드가 오류 모양이 됩니다(→ [알려진 제약](#알려진-제약)).

### 처음 값과 바뀐 값

- 시작 값은 `value`, 없으면 `initialValue`, 그것도 없으면 `min`, 그것도 없으면 `0` 입니다. 시작 값도 `min` ~ `max` 안으로 맞춥니다.
- `value` 는 바뀔 때만 읽습니다. 호출자가 다른 `value` 를 넘기면 그 값으로 바뀌고, 이때는 `onChanged` 가 불리지 않습니다. 사용자가 버튼 · 키 · 입력으로 바꾼 값은 호출자가 다시 넘기지 않아도 칸에 바로 보입니다 — 그 뒤 호출자가 이전과 같은 `value` 를 다시 넘겨도 되돌아가지 않습니다.
- `min` · `max` 가 바뀌면 지금 값을 새 범위 안으로 맞춥니다. 이때도 `onChanged` 는 불리지 않습니다.

### 소수 값

`step` 이 소수여도 `0.1 + 0.2` 가 `0.3` 으로 보이도록, 움직인 값을 `step` 과 지금 값 가운데 소수 자릿수가 많은 쪽에서 반올림합니다. 정수인 값은 소수점 없이 보입니다(`3.0` 이 아니라 `3`).

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 자릿수가 많은 숫자나 단위가 붙는 값을 자유롭게 입력할 때 | [TextField](/components/text-field) |
| 범위 안에서 대략적인 값을 끌어서 고를 때 | [Slider](/components/slider) |
| 숫자 입력이 아니라 단계 이동을 보여 줄 때 | [Stepper](/components/stepper) |

<a id="do"></a>
<a id="dont"></a>

### 범위와 라벨

<Cards columns="2">
<Card component="number-input" props="label=인원;description=최대 8명까지 예약할 수 있어요" tone="do" eyebrow="이렇게 하세요">

범위가 정해진 값에는 `min` · `max` 를 함께 줍니다 — 끝의 버튼이 저절로 비활성이 됩니다. 라벨로 무엇의 수인지 말하고, 단위나 범위는 `description` 에 적습니다.

</Card>
<Card component="number-input" tone="dont" eyebrow="이렇게 하지 마세요">

라벨이 없으면 무엇을 세는 수인지 알 수 없습니다.

</Card>
<Card demo="number-input/do-text-field" tone="do" eyebrow="대신 이렇게 하세요">

전화번호 · 금액처럼 자릿수가 많은 값은 TextField 로 입력받습니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

자릿수가 많은 값을 버튼으로 하나씩 올리고 내리게 하지 않습니다.

</Card>
</Cards>

범위와 라벨을 함께 준 예입니다. 두 플랫폼의 코드가 같습니다.

<Tabs groupId="platform">
<TabItem label="Flutter" value="flutter">

```dart
NumberInput(
  label: '인원',
  description: '최대 8명까지 예약할 수 있어요',
  initialValue: 2,
  min: 1,
  max: 8,
  size: CoreNumberInputSize.lg,
  onChanged: setGuests,
)
```

</TabItem>
<TabItem label="Web" value="web">

```dart
NumberInput(
  label: '인원',
  description: '최대 8명까지 예약할 수 있어요',
  initialValue: 2,
  min: 1,
  max: 8,
  size: CoreNumberInputSize.lg,
  onChanged: setGuests,
)
```

</TabItem>
</Tabs>

`step` 에는 양수를 줍니다 — 0 이나 음수는 assert 가 켜진 실행에서 실패합니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

variant · 크기와 범위 · 걸음은 위젯 속성으로 고르고, 보이는 값은 `numberInputStyle`(`CoreNumberInputStyle`) 하나로 덮어씁니다. NumberInput 은 두 컴포넌트를 안에 그리므로 각 부품의 스타일을 그 컴포넌트의 Style 그대로 넘깁니다 — 필드는 `fieldStyle`(`CoreTextFieldStyle`), 양 끝 버튼은 `buttonStyle`(`CoreButtonStyle`, 두 버튼에 같은 값)입니다. 그 둘 말고 NumberInput 의 스타일이 직접 가진 값은 필드 폭(`width`) 하나이고, 필드에는 기본 `fieldStyle` — 여백(좌우 4 · 위아래 3), 버튼과 값 칸 사이 간격 0, 가운데 정렬, 값 글자 `bodyMedium` — 을 넘깁니다.

<a id="테마로-덮어쓰기"></a>

<Split>

<Code language="dart" title="NumberInput 하나만 바꾸기">
NumberInput(
  value: guests,
  min: 1,
  max: 8,
  onChanged: setGuests,
  numberInputStyle: CoreNumberInputStyle(
    width: CoreSize.size128,
    fieldStyle: CoreTextFieldStyle(
      borderColor: CoreColor.token(CoreColors.outline),
    ),
    buttonStyle: CoreButtonStyle(
      foregroundColor: CoreColor.token(CoreColors.primary),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 · variant 별 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    numberInput: CoreNumberInputTheme(
      style: CoreNumberInputStyle(
        buttonStyle: CoreButtonStyle(
          hoverForegroundColor: CoreColor.token(CoreColors.primary),
        ),
      ),
      variantStyles: {
        CoreNumberInputVariant.filled: CoreNumberInputStyle(
          buttonStyle: CoreButtonStyle(
            foregroundColor: CoreColor.token(CoreColors.onSurface),
          ),
        ),
      },
    ),
  ),
)
</Code>

</Split>

이미 만든 `NumberInput` 에는 `withStyle` 체인으로 스타일을 덧붙일 수도 있습니다. 생성자의 `numberInputStyle` 인자와 같게 동작합니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
기본값 (defaultsBySize[size].width · defaultFieldStyle · defaultButtonStyle)
  → CoreComponentTheme.numberInput.style                    // 앱 전체
  → CoreComponentTheme.numberInput.variantStyles[variant]   // 앱 전체, variant 별
  → numberInputStyle                                        // 인스턴스
```

뒤로 갈수록 우선합니다. `variantStyles` 는 위젯의 `variant` 로 찾습니다 — `errorText` 만 주고 `variant` 를 지정하지 않으면 `variantStyles[CoreNumberInputVariant.error]` 는 쓰이지 않습니다.

안의 TextField 와 Button 은 각자 자기 테마(`CoreComponentTheme.textField` · `button`)를 먼저 받고, 그 위에 NumberInput 이 넘기는 값과 `fieldStyle` · `buttonStyle` 이 얹힙니다. 그래서 `CoreTextFieldTheme` 으로 테두리 색을 바꾸면 NumberInput 의 필드도 따라오지만, NumberInput 이 필드에 정하는 여백(좌우 4 · 위아래 3) · 버튼과 값 칸 사이 간격(0) · 가운데 정렬 · 값 글자(`bodyMedium`)는 TextField 테마로 바뀌지 않고 `fieldStyle` 로 바꿉니다.

<a id="접근성-accessibility"></a>

## 접근성

두 버튼은 이름을 가진 버튼으로 알립니다. Jaspr Web 은 값 칸을 숫자 입력(`spinbutton`)으로 알리고, Flutter 는 필드를 감싼 `Semantics` 에 지금 값과 늘리기 · 줄이기 동작을 싣습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 값 칸은 텍스트 필드 노드입니다. 필드 전체(라벨 · 두 버튼 · 도움말 포함)를 감싼 `Semantics` 가 지금 값과 늘린 값 · 줄인 값, 늘리기 · 줄이기 동작을 싣습니다 — 끝에 닿은 쪽의 동작은 빠집니다. 두 버튼은 이름 · 활성 상태를 가진 버튼 노드이고, 활성일 때 누르기 동작을 가집니다. |
| Jaspr Web | 값 칸은 `<input type="number">` 라 `spinbutton` 역할이고, `min` · `max` 가 속성으로 붙습니다. 두 버튼은 `aria-label` 이 붙은 `<button>` 이고, 비활성이면 `disabled` · `aria-disabled="true"` 가 붙어 Tab 순서에서 빠집니다. |

### 키보드

| 키 | 동작 |
| --- | --- |
| `↑` · `↓` | 값을 `step` 만큼 늘리고 줄입니다. 포커스가 값 칸과 두 버튼 중 어디에 있어도 됩니다. Jaspr Web 은 브라우저의 기본 증감을 막고 이 동작만 합니다. |
| `PageUp` · `PageDown` | 값을 `step × 10` 만큼 늘리고 줄입니다. |
| `Enter` | 값 칸에서는 입력한 값을 확정합니다. 버튼에서는 그 버튼을 누릅니다. |
| `Space` | 버튼에서 그 버튼을 누릅니다. |
| `Tab` · `Shift` · `Tab` | − 버튼 · 값 칸 · + 버튼 순서로 지납니다. 비활성 버튼은 건너뜁니다. |

`Home` · `End` 는 처리하지 않습니다 — 끝 값으로 가려면 `PageUp` · `PageDown` 을 되풀이하거나 값을 입력합니다. 비활성이면 어느 키에도 반응하지 않습니다.

### 스크린 리더

- 두 버튼의 이름은 로케일의 "줄이기" · "늘리기" 입니다(`numberInputDecrease` · `numberInputIncrease`).
- **Jaspr Web** — 브라우저가 값 칸을 `spinbutton` 으로 알리고 지금 값과 `min` · `max` 를 함께 넘깁니다. `errorText` 가 있으면 값 칸이 `aria-invalid="true"` 가 됩니다. 값 칸의 이름은 비어 있습니다(→ 알려진 제약).
- **Flutter** — 필드를 감싼 `Semantics` 에 늘리기 · 줄이기 동작을 실어, 보조 기술이 그 동작으로 값을 움직일 수 있습니다.

두 플랫폼 모두 값이 바뀐 사실을 따로 알리는 라이브 리전은 없습니다.

### 포커스 관리

`Tab` 으로 − 버튼, 값 칸, + 버튼에 차례로 닿습니다. 마운트될 때 포커스를 옮기지 않고, 포커스를 가두지 않습니다. 값 칸에서 포커스가 빠지면(버튼으로 옮길 때도) 입력한 값을 확정합니다. 필드 바깥의 포커스 링은 키보드로 값 칸에 포커스했을 때만 그리고, 마우스 · 터치로 값 칸을 누르면 테두리 색만 `primary` 로 바뀝니다. 두 버튼은 키보드로 포커스하면 Button 자신의 포커스 링을 그립니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 끝에 닿아 버튼이 비활성이 될 때, 그 버튼에 있던 포커스를 NumberInput 이 값 칸으로 옮기지 않습니다. 포커스가 어디로 가는지는 플랫폼이 정합니다. |
| Jaspr Web | `label` 이 값 칸에 연결되지 않아 값 칸의 접근 가능한 이름이 비어 있습니다(TextField 와 같습니다). 생성자의 `attributes` 는 바깥 `<div>` 에 붙어 값 칸에 닿지 않습니다. |
| Jaspr Web | `description` · `errorText` 문구가 `aria-describedby` 로 연결되지 않습니다. `variant: error` 만 주면 `aria-invalid` 도 붙지 않습니다. |
| Jaspr Web | 범위 밖의 수를 입력하면 필드가 오류 테두리와 `aria-invalid` 를 얻고, 확정해 값이 바뀌면 풀립니다. 값이 이미 `min` · `max` 에 있을 때 그 밖의 수를 입력하면, 확정해 끝 값으로 돌아간 뒤에도 다음 입력까지 오류 모양이 남습니다. Flutter 는 범위 밖의 수에 테두리가 바뀌지 않습니다. |
| Jaspr Web | 포커스가 − · + 버튼에 있어도 필드 테두리가 포커스 색으로 바뀝니다. Flutter 는 값 칸에 포커스가 있을 때만 바뀝니다. |
| Jaspr Web | `step` 이 `<input>` 의 속성으로 실리지 않습니다. 브라우저는 `step` 이 없는 숫자 입력의 간격을 1 로 보므로, 소수 `step` 으로 만든 값은 `<form>` 의 제약 검사에서 맞지 않는 값으로 걸릴 수 있습니다. |
| Jaspr Web | 생성자의 `onKeyDown` 과 `eventHandlers` 의 `keydown` · `focusout` 은 NumberInput 자신의 처리기에 덮여 불리지 않습니다. |
| Flutter | `label` · `errorText` 가 시맨틱 노드에 닿지 않습니다(TextField 와 같습니다). |

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은
> [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API 는 같지만, 값 칸과 키 처리는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 값 칸 | 글자 입력 `TextField` — `0-9` · `.` · `e` · `E` · `+` · `-` 만 받습니다 | `<input type="number">` — 받는 글자는 브라우저가 정합니다. 브라우저의 위 · 아래 스피너는 숨깁니다 |
| 화면 키보드 | 소수점이 있는 숫자 키보드. `min` 이 없거나 음수면 부호 키도 냅니다 | `type="number"` 에 맞춰 브라우저가 고릅니다 |
| 키 처리 | 필드를 감싼 `Focus` 가 키를 받습니다 | 바깥 `<div>` 의 `keydown` 이 받고, 브라우저의 기본 증감은 막습니다 |
| 확정 시점 | 값 칸의 포커스가 빠질 때 · `onSubmitted`(Enter · 키보드의 완료) | 바깥 `<div>` 의 `focusout` · Enter |
| 범위 밖 수를 입력했을 때 | 테두리 그대로 | 오류 테두리 · `aria-invalid` — 확정해 값이 바뀌면 풀리고, 값이 이미 끝에 있었으면 다음 입력까지 남습니다 |
| 버튼에 포커스가 있을 때 필드 테두리 | 쉬는 색 그대로 | 포커스 색(`primary`) |
| 접근성 역할 | 필드를 감싼 `Semantics` 의 늘리기 · 줄이기 동작 | 값 칸의 `spinbutton` 역할 |
| 캐럿 | 합성한 TextField 의 기본값 — 굵기 2 · 모서리 2 · `primary`, 값 바로 뒤(간격 0), 높이는 값 줄 상자(`bodyMedium` 14 × 1.5 = 21). iOS · macOS 는 프레임워크가 줄 상자보다 2 높게(23) 그립니다 | 브라우저가 그리는 캐럿. CSS 로 정하는 것은 색(`primary`)뿐이라 굵기 · 모서리 · 높이는 브라우저 몫입니다 |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `onClick` 등 — 바깥 `<div>` 에 붙습니다 |

이름 · 기본값 · 순서는 두 플랫폼이 같습니다.

<a id="props-parameters"></a>

## API

Flutter 와 Jaspr Web 이 같은 속성을 씁니다.

### 값

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `double?` | `null` | 지금 값. 바뀔 때만 읽습니다 — 사용자가 옮긴 값은 다시 넘기지 않아도 보입니다. |
| `initialValue` | `double?` | `null` | `value` 가 없을 때의 시작 값. `null` 이면 `min`, 그것도 없으면 `0` |
| `min` | `double?` | `null` | 가장 작은 값. 닿으면 − 버튼이 비활성 |
| `max` | `double?` | `null` | 가장 큰 값. 닿으면 + 버튼이 비활성 |
| `step` | `double` | `1` | 버튼 한 번 · 화살표 한 번에 움직이는 양. 양수여야 합니다. |
| `onChanged` | `ValueChanged<double>?` (Web `CoreValueChanged<double>?`) | `null` | 값이 바뀔 때 — 버튼 · 키 · 범위 안의 입력 · 확정 |

### 상태와 형태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `variant` | `CoreNumberInputVariant` | `defaultVariant` | defaultVariant, filled, error |
| `size` | `CoreNumberInputSize` | `md` | sm, md, lg |
| `enabled` | `bool?` | `null` | `null` 이면 켜짐. `onChanged` 유무와 상관없습니다. |
| `numberInputStyle` | `CoreNumberInputStyle?` | `null` | 보이는 값 덮어쓰기 |

### 글자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String?` | `null` | 필드 위 이름 |
| `description` | `String?` | `null` | 필드 아래 도움말. `errorText` 가 있으면 숨깁니다. |
| `errorText` | `String?` | `null` | 도움말을 대신할 오류 문구. 오류 테두리와 오류 색을 함께 켭니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreNumberInputStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `width` | `double?` | The whole field's width (logical px), border to border. `null` → the size row's width. |
| `buttonStyle` | `CoreButtonStyle?` | Style for the two step buttons, passed to each `Button` as is. |
| `fieldStyle` | `CoreTextFieldStyle?` | Style for the `TextField` inside, passed to it as is. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>
<a id="조합-예제"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="number-input/related-text-field" title="TextField">

자릿수가 많은 숫자나 단위가 붙는 값을 자유롭게 입력받습니다. NumberInput 의 필드 모양이 여기서 옵니다.

</Card>
<Card title="Button" href="/components/button" more="Button 보기">

양 끝 버튼은 Button 의 `plain` · `square` 입니다.

</Card>
<Card title="Stepper" href="/components/stepper" more="Stepper 보기">

숫자 입력이 아니라 단계 이동을 보여 줍니다.

</Card>
</Cards>
