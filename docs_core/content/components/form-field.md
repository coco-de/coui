---
title: FormField
description: 라벨 · 도움말 · 오류 · 글자 수를 입력 하나와 묶고, 그 입력을 폼 검증에 연결하는 폼 필드
category: form
platforms: [flutter, web]
related: [form, fieldset, text-field, form-label, validator-hint]
tags: [form, field, label, error]
template: v2
source: form/form_field
---

# FormField

<a id="live-preview"></a>
<a id="사용법"></a>

## 플레이그라운드

크기 · 필수 · 도움말 · 오류 · 글자 수 · 라벨 옆 동작 · 비활성을 바꿔 보며 FormField 를 확인하고, 만들어진 코드를 복사하세요.

<Playground component="form-field" />

FormField 는 라벨 줄, 입력(`child`), 그 아래의 도움말 · 오류 · 글자 수를 세로로 쌓는 틀입니다. Flutter 와 Jaspr Web 이 같은 속성을 씁니다. [Form](/components/form) 의 `children` 에는 직접 넣습니다 — Form 은 필드를 자동으로 감싸지 않습니다. Form 이 없어도 라벨 · 도움말 · 직접 넘긴 `error` 는 그대로 그리고, `validator` 만 `controller` 가 있는 Form 안에서 실행됩니다.

미리보기의 글자 수는 고정 문구입니다. FormField 는 글자를 세지 않습니다. 코드의 `setNickname` · `showNicknameGuide` 는 앱의 함수입니다.

```dart
FormField(
  label: '이메일',
  description: '회사 이메일을 입력하세요.',
  required: true,
  child: TextField(placeholder: Text('you@company.com')),
)
```

## 구조

필드는 위에서부터 라벨 줄, 입력, 아래 줄입니다. 라벨 줄의 끝에는 `labelAction` 을, 아래 줄의 끝에는 `counterText` 를 놓을 수 있습니다.

<Anatomy demo="form-field/anatomy">
<AnatomyItem part="container" side="left" name="FormField">

라벨 줄 · 입력 · 아래 줄을 세로로 쌓는 틀. 줄 사이는 8 입니다.

</AnatomyItem>
<AnatomyItem part="label" side="left" name="label">

`label` 의 글자. 필드의 이름이 됩니다.

</AnatomyItem>
<AnatomyItem select="label [aria-hidden]" side="top" name="required">

`required: true` 일 때 붙는 필수 표시 `*`.

</AnatomyItem>
<AnatomyItem select="button" side="right" name="labelAction">

라벨 줄 끝에 놓는 링크나 버튼.

</AnatomyItem>
<AnatomyItem select="input" side="right" name="child">

감싸는 입력. 여기서는 TextField 입니다.

</AnatomyItem>
<AnatomyItem select="p" side="left" name="description">

도움말. 오류가 있으면 같은 자리에 오류 문구가 대신 나옵니다.

</AnatomyItem>
<AnatomyItem select="p ~ span:last-child" side="right" name="counterText">

아래 줄 끝의 글자 수 같은 문구.

</AnatomyItem>
</Anatomy>

- 라벨은 [FormLabel](/components/form-label) 이, 오류 문구는 [ValidatorHint](/components/validator-hint) 가 그립니다.
- `label` 과 `labelWidget` 이 모두 없으면 라벨 줄과 그 아래 간격이 없습니다. 이때는 `labelAction` 과 필수 표시도 그리지 않습니다.
- `description` · 오류 · `counterText` 가 모두 없으면 아래 줄과 그 위 간격이 없습니다.

## 크기

<SizeSpec component="form-field" props="width=compact;required=true" label="이메일" />

`size` 는 라벨 글자만 바꿉니다. FormField 는 값을 FormLabel 에 그대로 넘기고, FormLabel 의 크기 행이 `xs` · `sm` · `md` 에는 `labelMedium`, `lg` · `xl` · `xl2` 에는 `labelLarge` 를 씁니다. 두 역할 모두 Medium 이고 줄 높이는 140% 입니다. 필수 표시 `*` 도 라벨과 같은 글자 크기입니다. 기본값은 `md` 입니다.

도움말 · 오류 · 글자 수 · 간격은 크기와 상관없이 같습니다. `child` 의 크기도 바뀌지 않으므로, 입력의 크기는 입력의 `size` 로 따로 정합니다.

<a id="동작-스펙-behavior"></a>

## 라벨 줄과 아래 줄

<Preview demo="form-field/rows" />

| 항목 | 동작 |
| --- | --- |
| `label` | 라벨 글자입니다. `labelMaxLines` 와 `labelOverflow` 로 줄 수와 넘침 처리를 정합니다. 두 값은 `label` 글자에만 적용됩니다. `labelMaxLines` 를 주지 않으면 줄 수를 제한하지 않지만, `labelOverflow` 가 `ellipsis` 면 두 플랫폼 모두 라벨이 한 줄이 됩니다. |
| `labelWidget` | `label` 대신 그립니다. 두 플랫폼의 처리가 다릅니다([플랫폼 차이](/components/form-field#플랫폼-차이)). 필드의 이름이 필요하면 `label` 을 씁니다. |
| `labelAction` | 라벨 줄의 끝에 놓고, 라벨과는 8 이상 떨어뜨립니다. 다른 화면으로 가면 [Link](/components/link), 그 자리에서 무언가를 열면 `Button(variant: CoreButtonVariant.plain)` 을 씁니다. Flutter 는 자리가 모자라면 라벨이 줄을 바꿉니다. |
| `description` · `error` | 같은 자리를 씁니다. 오류가 있으면 도움말 대신 오류를 보입니다. `validator` 의 오류가 `error` 보다 우선합니다. |
| `counterText` | 아래 줄의 끝에 놓습니다. 도움말이나 오류가 함께 있으면 두 글의 윗줄을 맞추고 8 이상 띄웁니다. 도움말과 오류가 없어도 이 줄은 남고, 글자 수는 끝에 놓입니다. |

`counterText` 는 완성한 문장을 받습니다. FormField 는 감싼 입력의 글자 길이를 읽지 않고, `0 / 20` 의 구분 기호와 순서는 언어마다 다를 수 있어 호출자가 만듭니다.

```dart
FormField(
  label: '닉네임',
  counterText: '${nickname.length} / 20',
  child: TextField(onChanged: setNickname),
)
```

비밀번호 칸에 "비밀번호 찾기" 를 붙이는 구성입니다.

```dart
FormField(
  label: '비밀번호',
  labelAction: Button(
    variant: CoreButtonVariant.plain,
    size: CoreComponentSize.sm,
    onPressed: handleForgotPassword,
    child: Text('비밀번호 찾기'),
  ),
  child: TextField(placeholder: Text('비밀번호'), obscureText: true),
)
```

## 상태

<Preview demo="form-field/states" />

| 상태 | 정하는 값 | 모습과 동작 |
| --- | --- | --- |
| 도움말 | `description` | 입력 아래에 `bodySmall` · `onSurfaceVariant` 로 보입니다. |
| 오류 | `validator` 의 결과 또는 `error` | 도움말 자리에 오류 아이콘과 문구를 `bodySmall` · `error` 색으로 보입니다. TextField 와 TextField 를 상자로 쓰는 입력은 테두리도 `error` 가 됩니다([비활성과 오류가 닿는 입력](/components/form-field#비활성과-오류가-닿는-입력)). |
| 필수 | `required` | 라벨 뒤에 `error` 색의 `*` 를 붙입니다. 표시일 뿐이며, 빈 값을 막으려면 `validator` 를 줍니다. |
| 비활성 | `enabled: false`, 또는 비활성 [Fieldset](/components/fieldset) 이나 비활성 FormField 의 안 | 라벨 글자가 `onSurfaceSubtle` 이 됩니다. 필수 표시는 `error` 색 그대로이고 도움말 · 글자 수의 색도 그대로입니다. 필드 전체(`labelAction` 포함)가 포인터 입력을 받지 않고, 안쪽 입력에 비활성 상태를 전합니다. |

FormField 에는 hover · 눌림 · 포커스 · 로딩 상태가 없고, 입력 · 제출 · 선택 콜백도 없습니다.

### 비활성과 오류가 닿는 입력

<Preview demo="form-field/scope-inputs" />

비활성과 오류 상태는 `child` 안에서 이 상태를 받는 부분에만 닿습니다. 두 플랫폼에서 TextField 와, TextField 로 상자를 그리는 입력이 받습니다. 포인터는 `enabled: false` 가 필드 전체에서 막지만, 키보드는 막지 않습니다.

| 안에 둔 것 | 비활성 필드 안에서 |
| --- | --- |
| `TextField` | 비활성 모습이 되고 입력할 수 없습니다. Flutter 에서는 `Tab` 포커스를 여전히 받습니다. |
| `Select` · `Autocomplete` | 비활성 모습이 됩니다. Jaspr Web 은 조작할 수 없지만, Flutter 는 `Tab` 으로 들어가 키보드로 값을 바꿀 수 있습니다. |
| `NumberInput` | 글자를 입력할 수 없습니다. −/+ 버튼은 두 플랫폼 모두 `Tab` 으로 닿아 눌리고, 버튼에서 방향키 · `PageUp` · `PageDown` 으로도 값이 바뀝니다. Flutter 는 입력 칸에서도 이 키로 값이 바뀝니다. |
| `DatePicker` · `DateRangePicker` · `TimePicker` | 읽기 전용 TextField 인 여는 칸이 비활성 상자가 됩니다. Jaspr Web 의 `DatePicker` · `DateRangePicker` 는 빈 칸의 안내 글자와 달력 아이콘이 활성 색으로 남습니다. |
| `ChipInput` | 글자를 입력할 수 없습니다. 칩의 제거 버튼은 두 플랫폼 모두 `Tab` 으로 닿아 칩을 지울 수 있고, `onChanged` 가 불립니다. |
| `PhoneInput` | 번호는 입력할 수 없습니다. Jaspr Web 은 국가 선택 버튼이 `Tab` 으로 닿아 국가를 바꿀 수 있고, 값도 바뀝니다. Flutter 의 국가 선택은 키보드로 열리지 않습니다. |
| `InputOtp` · `FormattedInput` | Flutter 는 안의 입력 칸이 상태를 받아 입력이 막힙니다. Jaspr Web 은 받지 않아 키보드로 계속 입력됩니다. |
| `Checkbox` · `Toggle` · `SwitchField` · `RadioGroup` · `TextArea` · `Slider` · `Button` 처럼 상태를 받지 않는 것 | 활성 모습 그대로이고, `Tab` 으로 들어가 키보드로 조작할 수 있습니다. |

비활성 필드를 확실히 막으려면 입력에도 `enabled: false` 를 줍니다.

```dart
FormField(
  label: '알림 설정',
  enabled: canEdit,
  child: Checkbox(checked: notify, enabled: canEdit, onChanged: setNotify),
)
```

오류 상태도 같은 방식입니다. TextField 와, TextField 를 상자로 쓰는 `NumberInput` · `Select` · `Autocomplete` · `DatePicker` · `DateRangePicker` · `TimePicker` 는 테두리가 `error` 가 됩니다. 문구는 FormField 만 보이므로 입력에 오류 문구를 다시 주지 않습니다. `Checkbox` · `Toggle` · `RadioGroup` · `TextArea` 의 모습과 `PhoneInput` · `InputOtp` · `FormattedInput` 의 바깥 상자는 바뀌지 않습니다. `ChipInput` 은 칩 틀이 아니라 틀 안쪽 입력 줄에 `error` 테두리가 따로 생깁니다([알려진 제약](/components/form-field#알려진-제약)).

이 상태는 `child` 의 위젯 트리 안에서만 전해집니다. 입력이 여는 팝오버나 대화상자의 내용에는 전해지지 않으므로, 오류 필드에서 연 대화상자의 입력이 오류 모양이 되거나 비활성 필드에서 연 패널의 입력이 막히지 않습니다.

## 값과 검증

`FormController` 를 준 [Form](/components/form) 안에 FormField 를 두면, 입력이 알린 값이 컨트롤러에 모이고 `validator` 의 결과가 필드의 아래 줄에 나타납니다. 값을 따로 연결할 코드는 필요 없습니다.

```dart
const emailKey = FormKey<String>('email');

final controller = FormController(); // 다 쓰면 controller.dispose()

Form(
  controller: controller,
  children: [
    FormField(
      label: '이메일',
      required: true,
      formKey: emailKey,
      validator: const RequiredValidator<String>(),
      child: TextField(placeholder: Text('you@company.com')),
    ),
  ],
)
```

`RequiredValidator` 는 검증 시점을 보지 않아, 위 필드는 비어 있으면 화면에 나타나자마자 오류를 보입니다. 제출할 때부터 보이게 하려면 [검증기를 직접 만듭니다](/components/form#검증기-직접-만들기). 제출 흐름은 [Form 의 제출](/components/form#제출)을 보세요.

| 항목 | 동작 |
| --- | --- |
| `validator` | `controller` 가 있는 Form 안에서만 실행됩니다. 비우면 이 필드는 검사하지 않고, 값은 컨트롤러에 그대로 모입니다. |
| `formKey` | `controller.getValue(formKey)` 로 값을 읽고, 다른 필드의 검증기가 `shouldRevalidate` 로 이 필드의 변화를 따라갈 때 씁니다. 비우면 필드마다 새 키가 생깁니다. |
| 검증 시점 | 컨트롤러가 검증기를 부를 때 `FormValidationMode` 를 넘깁니다. 값을 처음 알리면 `initial`, 바뀌면 `changed`, 호출자가 `controller.revalidate` 를 부르면 넘긴 모드입니다. FormField 에는 시점을 고르는 속성이 없고, 언제 오류를 낼지는 검증기가 정합니다. |
| 보이는 오류 | 검증 결과가 `InvalidResult` 면 그 문구를 보입니다. 통과했거나 비동기 검사를 기다리는 중이거나 `ReplaceResult` 면 `error` 속성의 문구(있을 때)를 보입니다. |
| 값의 타입 | 검증기의 타입은 입력이 알리는 값의 타입과 맞아야 합니다. 예를 들어 `Checkbox` 를 감싼 필드에 `RequiredValidator<String>` 을 주면 실행 중에 타입 오류가 납니다. |
| 입력 수 | 필드 하나에는 값을 알리는 입력 하나를 둡니다. 둘 이상이면 마지막에 알린 값이 필드의 값이 됩니다. |

값을 알리는 입력은 `TextField`(빈 글자는 `null`), `NumberInput`(안의 TextField 에 적힌 글자를 알립니다), `Checkbox`, `Toggle` · `SwitchField`, `RadioGroup`, `InputOtp`, `PhoneInput` 입니다. Flutter 의 `ObjectFormField` 와 Jaspr Web 의 `ObjectInput` 도 알립니다. 입력마다의 값 타입은 [Form 의 값을 보고하는 입력](/components/form#값을-보고하는-입력)에 있습니다.

`Select` · `Autocomplete` · `TextArea` · `Slider` · `DatePicker` 처럼 값을 알리지 않는 입력은 검증기가 실행되지 않습니다. `onChanged` 로 값을 받아 직접 검사하고 `error` 에 넘깁니다.

`selection` 이 `multiple` 인 `OptionItem`(`OptionList` 안 포함)과 `MultiAnswerCard`, 체크 목록 줄이 있는 Flutter 의 `RichEditor` 는 안의 체크 표시가 `bool?` 값을 알립니다. 필드의 입력으로 쓰지 않습니다.

`ReplaceResult` 는 입력이 자기 값을 알리고 돌려받은 것만 그 입력에 전달됩니다. `TextField` 는 글자를 그 값으로 바꾸고, `Checkbox` · `Toggle` · `RadioGroup` 은 `onChanged` 로 넘깁니다. `controller.revalidate` 나 다른 필드의 변화(`shouldRevalidate`)로 다시 검사해 나온 `ReplaceResult` 는 전달되지 않습니다.

<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

FormField 는 라벨이나 오류 자리가 없는 입력(`ChipInput` · `FormattedInput` 처럼)에 라벨 · 도움말 · 오류를 붙이거나, 입력을 Form 검증에 연결하거나, 라벨 줄에 링크나 버튼을 둘 때 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 검증 없이 입력 하나에 라벨 · 오류만 필요할 때 | 입력의 `label` · `errorText` — [TextField](/components/text-field), [Select](/components/select) |
| 라벨과 필수 표시만 필요할 때 | [FormLabel](/components/form-label) |
| 안내나 오류 문구 한 줄만 필요할 때 | [ValidatorHint](/components/validator-hint) |
| 여러 필드를 제목 아래 묶고 묶음 단위로 끌 때 | [Fieldset](/components/fieldset) |
| 여러 필드의 검증과 값을 한 번에 다룰 때 | [Form](/components/form) — FormField 를 담습니다 |

FormField 안의 `TextField` · `Select` 에는 `label` · `description` · `errorText` 를 함께 주지 않습니다. 라벨과 문구가 두 번 보입니다.

<a id="do"></a>
<a id="dont"></a>

### 라벨과 오류

<Cards columns="2">
<Card demo="form-field/do-label" tone="do" eyebrow="이렇게 하세요">

`label` 은 글자로 넘깁니다. 필드 전체에 이름이 붙고, 필수 표시와 크기별 글자가 함께 적용됩니다.

</Card>
<Card demo="form-field/dont-label-widget" tone="dont" eyebrow="이렇게 하지 마세요">

`labelWidget` 만 넘기면 FormField 가 필드의 이름을 지정하지 않습니다. Jaspr Web 에서는 `required` 를 줘도 필수 표시가 붙지 않습니다.

</Card>
<Card demo="form-field/do-error-with-rule" tone="do" eyebrow="이렇게 하세요">

오류가 보이는 동안 `description` 은 숨습니다. 고치는 데 필요한 기준은 오류 문구에 적습니다.

</Card>
<Card demo="form-field/dont-error-without-rule" tone="dont" eyebrow="이렇게 하지 마세요">

도움말과 오류가 함께 보인다고 생각하면 안 됩니다. "8자 이상" 이라는 기준이 오류가 뜨는 순간 사라집니다.

</Card>
</Cards>

## 배치

| 항목 | 동작 |
| --- | --- |
| 폭 | 부모의 폭을 채우고 `child` 도 폭 끝까지 늘립니다. |
| Flutter 의 부모 | 가로가 정해진 부모 안에 둡니다. `Row` 안에서는 `Expanded` 나 `SizedBox(width:)` 로 폭을 줍니다. |
| 줄 간격 | 라벨 줄과 입력, 입력과 아래 줄 사이는 8 입니다(`labelInputGapStyle` 하나가 둘 다 정합니다). |
| 줄 안 간격 | 라벨과 `labelAction`, 문구와 글자 수는 8 이상 떨어집니다. 라벨과 필수 표시 사이는 4 입니다. |
| 바깥 여백 | 없습니다. 필드 사이의 간격은 부모가 정합니다. [Form](/components/form) 은 `rowSpacing`(기본 24)을 씁니다. |
| 밀도 | 8 짜리 간격은 앱의 밀도를 따르고, 4 짜리 필수 표시 간격은 그대로입니다. |

## 테마와 스타일

겉모습은 `formFieldStyle`(`CoreFormFieldStyle`) 하나로 바꿉니다. 색 · 간격 · 글자를 직접 받는 낱개 파라미터는 없습니다. 앱 전체 값은 `CoreComponentTheme.formField` 의 `style` 에 둡니다.

<Split>

<Code language="dart" title="필드 하나만 바꾸기">
FormField(
  label: '이메일',
  formFieldStyle: CoreFormFieldStyle(
    labelInputGapStyle: CoreGapStyle(size: CoreSpace.space4),
  ),
  child: TextField(placeholder: Text('you@company.com')),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    formField: CoreFormFieldTheme(
      style: CoreFormFieldStyle(
        labelInputGapStyle: CoreGapStyle(size: CoreSpace.space4),
      ),
    ),
  ),
)
</Code>

</Split>

### 부분마다 바꾸는 값

| 부분 | 기본값 | `formFieldStyle` 에서 바꾸는 값 |
| --- | --- | --- |
| 라벨 | `labelMedium` 또는 `labelLarge`(크기별) · `onSurfaceVariant` | `formLabelStyle` |
| 비활성 라벨 | `onSurfaceSubtle` | `disabledFormLabelStyle` |
| 필수 표시 | `error` 색, 라벨과 4 | `formLabelStyle` 의 `requiredColor` · `requiredIndicatorGapStyle` |
| 도움말 | `bodySmall` · `onSurfaceVariant` | `descriptionTextStyle` |
| 오류 문구 | `bodySmall` · `error` 색, 아이콘 16, 아이콘과 글자 사이 4 | `errorValidatorHintStyle` · `validatorHintStyle` |
| 글자 수 | `bodySmall` · `onSurfaceVariant` | `counterTextStyle` |
| 라벨 줄 ↔ 입력 ↔ 아래 줄 | 8 | `labelInputGapStyle` |
| 라벨 ↔ `labelAction` | 8 이상 | `labelActionGapStyle` |
| 문구 ↔ 글자 수 | 8 이상 | `footerGapStyle` |

- 비활성 라벨의 색은 `disabledFormLabelStyle` 로 바꿉니다. `formLabelStyle` 의 `labelStyle` 에 색을 주면 그 색이 비활성에서도 남습니다.
- FormField 는 FormLabel 을 비활성으로 만들지 않으므로, `formLabelStyle` 의 `disabledColor` 는 FormField 안에서 쓰이지 않습니다.

### 값이 정해지는 순서

```text
기본값 (CoreFormFieldStyle.default* · FormLabel 의 크기 행)
  → CoreComponentTheme.formField.style   // 앱 전체
  → formFieldStyle                       // 필드 하나

비활성 라벨: 비활성 기본값 → disabledFormLabelStyle → formLabelStyle
오류 문구:   오류 기본값   → errorValidatorHintStyle → validatorHintStyle
```

뒤에 있는 값이 앞의 값을 덮습니다. 라벨과 오류 문구에는 `CoreComponentTheme.formLabel` 과 `CoreComponentTheme.validatorHint` 의 값도 적용되지만, FormField 가 정한 값(비활성 라벨 색, 오류 문구의 `bodySmall`)이 그보다 우선합니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `FormField` 에 스타일을 덧붙이려면 `withStyle` 을 씁니다. 생성자의 `formFieldStyle` 과 같게 동작하고, 같은 값은 나중에 적은 것이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class FormFieldChainExample extends StatelessWidget {
  const FormFieldChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child:
          FormField(
            label: '이메일',
            description: '회사 이메일을 입력하세요.',
            required: true,
            child: TextField(
              autofillHints: const [AutofillHints.email],
              placeholder: const Text('you@company.com'),
            ),
          ).withStyle(
            const CoreFormFieldStyle(
              labelInputGapStyle: CoreGapStyle(size: CoreSpace.space24),
              formLabelStyle: CoreFormLabelStyle(
                labelStyle: CoreTextStyle.token(
                  CoreTextStyles.titleSmall,
                  color: CoreColor.token(CoreColors.primary),
                ),
                requiredColor: CoreColor.token(CoreColors.tertiary),
                requiredIndicatorGapStyle: CoreGapStyle(
                  size: CoreSpace.space8,
                ),
              ),
              descriptionTextStyle: CoreTextStyle.token(
                CoreTextStyles.labelSmall,
                color: CoreColor.token(CoreColors.onSurfaceVariant),
              ),
            ),
          ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class FormFieldChainExample extends StatelessComponent {
  const FormFieldChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '320px'}),
      [
        FormField(
          label: '이메일',
          description: '회사 이메일을 입력하세요.',
          required: true,
          child: TextField(
            autofillHints: const ['email'],
            placeholder: Text('you@company.com'),
          ),
        ).withStyle(
          const CoreFormFieldStyle(
            labelInputGapStyle: CoreGapStyle(size: CoreSpace.space24),
            formLabelStyle: CoreFormLabelStyle(
              labelStyle: CoreTextStyle.token(
                CoreTextStyles.titleSmall,
                color: CoreColor.token(CoreColors.primary),
              ),
              requiredColor: CoreColor.token(CoreColors.tertiary),
              requiredIndicatorGapStyle: CoreGapStyle(size: CoreSpace.space8),
            ),
            descriptionTextStyle: CoreTextStyle.token(
              CoreTextStyles.labelSmall,
              color: CoreColor.token(CoreColors.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="접근성-accessibility"></a>

## 접근성

FormField 는 필드 전체를 하나의 묶음으로 만들고, 이름 · 설명 · 상태를 그 묶음에 붙입니다. `child` 는 호출자의 입력이라 FormField 가 입력 요소에 속성을 넣지는 않습니다.

### 역할

| 요소 | Flutter | Jaspr Web |
| --- | --- | --- |
| 필드 | `Semantics(container: true)` 노드. `label` 이 이름, 오류 또는 `description` 이 힌트(`hint`), `enabled` 가 활성 여부 | `<div role="group">` 과 아래 속성 |
| 라벨 | [FormLabel](/components/form-label). 필수 표시 `*` 는 읽지 않습니다. | `for` 가 없는 `<label>`. `*` 는 `aria-hidden="true"` |
| 오류 문구 | 라이브 영역 | `role="alert"` |

Jaspr Web 의 묶음이 갖는 속성입니다. 라벨 · 도움말 · 오류의 id 는 필드마다 따로 만듭니다.

| Web 속성 | 붙는 조건 |
| --- | --- |
| `aria-labelledby` | `label` 글자를 그릴 때(`labelWidget` 이 없을 때). 그 `<label>` 을 가리킵니다. |
| `aria-describedby` | 오류가 있으면 오류 문구, 없고 `description` 이 있으면 도움말 |
| `aria-invalid="true"` | 보이는 오류가 있을 때 |
| `aria-required="true"` | `required: true` |
| `aria-disabled="true"` | 비활성일 때 |

Flutter 의 힌트는 검증 결과가 바뀔 때마다 다시 만들어, 제출 뒤에 나타난 검증 문구를 따라갑니다.

단독 [Label](/components/label) 은 두 플랫폼 모두 입력과 연결되지 않으며, 그 `htmlFor` 파라미터는 폐기가 예고돼 있습니다. 라벨 · 도움말 · 오류를 입력과 함께 묶으려면 FormField 를 씁니다.

### 키보드

FormField 가 직접 처리하는 키는 없습니다. 키 동작은 모두 `child` 와 `labelAction` 의 것입니다. 라벨 줄이 입력보다 앞에 있으므로 `Tab` 은 `labelAction` 을 먼저 지난 뒤 입력으로 갑니다.

비활성 필드에서도 키보드는 FormField 가 막지 않습니다. 어느 입력이 키보드로 남는지는 [비활성과 오류가 닿는 입력](/components/form-field#비활성과-오류가-닿는-입력)을 보세요. `labelAction` 도 포인터만 막힙니다.

### 스크린 리더

- **이름과 설명** — 묶음에 들어갈 때 `label` 이 이름으로, 도움말이나 오류가 설명으로 붙습니다. 오류가 보이는 동안에는 도움말을 그리지 않으므로 설명도 오류가 됩니다.
- **묶음의 이름** — 이 이름은 묶음의 것이지 입력의 것이 아닙니다. 리더가 입력으로 바로 가면 입력 자신의 이름만 읽을 수 있습니다. 입력에도 이름이 필요하면 두 플랫폼 모두 `child` 쪽에 직접 지정합니다. Jaspr Web 의 TextField 는 `attributes` 에 `aria-label` 을 줍니다.
- **오류 알림** — 오류 문구가 나타나면 알립니다(Web `role="alert"`, Flutter 라이브 영역). 제출 뒤에 포커스를 옮기지 않아도 새 오류를 읽습니다. 처음부터 있는 `description` 은 알리지 않습니다.
- **필수** — 두 플랫폼 모두 `*` 는 읽지 않습니다. Web 은 묶음에 `aria-required` 를 붙이지만 `group` 은 이 속성을 지원하는 역할이 아니라 읽지 않을 수 있고, Flutter 는 필수 여부를 알리지 않습니다.
- **글자 수** — Web 의 `counterText` 는 `aria-describedby` 에 들어가지 않고, 값이 바뀌어도 알리지 않습니다.

### 포커스 관리

FormField 는 포커스를 갖지 않습니다. 포커스를 옮기거나 가두거나 되돌리지 않고, 포커스 링도 그리지 않습니다. 라벨을 눌러도 입력에 포커스가 가지 않으며, 검증에 실패해도 오류 필드로 옮기지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | `enabled: false` 가 직접 막는 것은 포인터뿐입니다. 비활성 상태를 받지 않는 입력(`Checkbox` · `Toggle` · `RadioGroup` · `TextArea` 등)은 활성 모습이고 키보드로 조작됩니다. |
| 공통 | `NumberInput` 의 −/+ 버튼은 비활성 필드 안에서도 키보드로 눌리고, 버튼에서 방향키 · `PageUp` · `PageDown` 으로도 값이 바뀝니다. |
| 공통 | 비활성 필드의 `ChipInput` 은 칩 제거 버튼이 키보드로 눌립니다. |
| 공통 | TextField 의 `features`(지우기 · 비밀번호 보기) 버튼은 비활성 상태를 받지 않습니다. 기본값에서는 `Tab` 순서에 없지만, `skipInputFeatureFocusTraversal: false` 면 `Tab` 으로 닿아 눌립니다. |
| 공통 | 오류 필드의 `ChipInput` 은 칩 틀의 테두리가 그대로이고, 틀 안쪽 입력 줄에 `error` 테두리가 따로 그려집니다. |
| 공통 | `labelWidget` 만 넘기면 FormField 가 필드의 이름(Flutter `Semantics` 의 `label`, Web `aria-labelledby`)을 지정하지 않습니다. |
| 공통 | `controller.revalidate` 나 다른 필드의 변화로 다시 검사해 나온 `ReplaceResult` 는 입력에 전달되지 않고, 필드에 문구 없이 `controller.errors` 에 남습니다. |
| 공통 | `validator` 만 바꾸면 입력 값이 바뀌기 전까지 컨트롤러는 전에 받은 검증기를 씁니다. |
| 공통 | 화면에서 뺀 필드의 값과 오류는 컨트롤러에 남습니다. |
| Flutter | `Select` · `Autocomplete` 는 비활성 필드 안에서도 `Tab` 으로 들어가 키보드로 값을 바꿀 수 있고, `NumberInput` 은 입력 칸에서도 방향키 · `PageUp` · `PageDown` 으로 값이 바뀝니다. |
| Flutter | 오류 필드의 `FormattedInput` 은 입력 줄에 포커스가 있으면 안쪽에 `error` 테두리가 생깁니다. |
| Flutter | 필수 필드라는 것을 보조 기술에 알리지 않습니다. 알려야 하면 `label` 문구에 함께 적습니다(예: "이메일 (필수)"). |
| Flutter | `child` 안에서 연 대화상자나 팝오버의 `Checkbox` · `Toggle` · `RadioGroup` · `InputOtp` · `PhoneInput` 이 이 필드에 값을 알립니다. 그 안의 `TextField` 는 알리지 않습니다. |
| Flutter | 컨트롤러가 알림을 보낼 때 새 프레임을 요청하지 않아, 비동기 검증 결과가 다음 프레임까지 늦게 보일 수 있습니다. |
| Jaspr Web | 라벨 · 도움말 · 오류는 묶음에만 연결되고 입력 요소의 이름 · 설명이 되지 않습니다. |
| Jaspr Web | `required` 는 묶음의 `aria-required` 로만 전하는데, `group` 은 이 속성을 지원하는 역할이 아닙니다. |
| Jaspr Web | `labelWidget` 을 주면 `label` 을 함께 줘도 묶음에 `aria-labelledby` 가 붙지 않고, 필수 표시 · 크기별 글자 · 비활성 라벨 색도 적용되지 않습니다. |
| Jaspr Web | `InputOtp` · `FormattedInput` 은 비활성 상태를 받지 않아, 비활성 필드 안에서도 키보드로 입력됩니다. |
| Jaspr Web | 비활성 필드의 `PhoneInput` 은 키보드로 국가를 바꿀 수 있습니다. |
| Jaspr Web | 비활성 필드의 `DatePicker` · `DateRangePicker` 는 빈 칸의 안내 글자와 달력 아이콘을 활성 색으로 그립니다. |
| Jaspr Web | 폭이 좁고 도움말 · 오류 문구가 길면 글자 수(`counterText`)가 `0 /` 와 `20` 처럼 두 줄로 꺾일 수 있습니다. Flutter 는 글자 수를 한 줄로 두고 문구를 꺾습니다(문서 사이트의 플레이그라운드에서 확인). |

#### 비활성 표시

비활성 필드를 눈으로 구분하는 것은 색뿐입니다. 라벨이 `onSurfaceVariant` 에서 `onSurfaceSubtle` 로 한 단계 낮아지고, 필수 표시는 `error` 색 그대로입니다. 색에 대한 전반적인 처리는 [접근성](/accessibility)에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

속성 이름과 검증 순서는 두 플랫폼이 같습니다. 값을 연결하는 방식, 알리는 방식, 일부 라벨 처리가 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 값 보고 연결 | `Data` 로 필드를 내려 줍니다 | `FormFieldHandleScope` |
| 컨트롤러 찾기 | `Data.maybeOf<FormController>(context)` | `FormControllerScope.maybeOf(context)` |
| 검증 갱신 | `ValueListenableBuilder` 로 상태를 쓰는 부분만 다시 만듭니다 | 컨트롤러 알림을 받아 `setState` |
| 비활성 · 오류 전달 | `FormFieldScope`(`InheritedWidget`) | `FormFieldScope`(`InheritedComponent`) |
| 비활성 포인터 차단 | `IgnorePointer` | `pointer-events: none` |
| 필드 이름과 설명 | `Semantics` 의 `label` · `hint` | `role="group"` 의 `aria-labelledby` · `aria-describedby` |
| 필수 알림 | 없습니다 | `aria-required`(읽지 않을 수 있습니다) |
| `labelWidget` | FormLabel 안에 넣어 필수 표시를 붙이고, 스타일을 정하지 않은 글자에는 크기별 글자와 비활성 색을 적용합니다. `label` 도 함께 주면 그 글자를 `Semantics` 의 `label` 로 씁니다. | 받은 그대로 그립니다. `label` 을 함께 줘도 묶음에 `aria-labelledby` 를 붙이지 않습니다. |
| `labelMaxLines` 의 넘침 | `labelOverflow` 를 따르고, 비우면 잘라 냅니다(`clip`) | 줄 수를 자르는 CSS(`-webkit-line-clamp`)라 `labelOverflow` 와 상관없이 말줄임표가 붙습니다 |
| `InputOtp` · `FormattedInput` 의 비활성 | 안의 입력 칸이 상태를 받아 입력이 막힙니다 | 상태를 받지 않아 키보드로 입력됩니다 |
| 비활성 `TextField` 의 포커스 | `Tab` 포커스를 받습니다 | `<input disabled>` 라 받지 않습니다 |
| `Select` · `Autocomplete` 키보드(비활성) | 조작됩니다 | 조작되지 않습니다 |
| `PhoneInput` 의 국가 선택(비활성) | 키보드로 열리지 않습니다 | `Tab` 으로 닿아 국가를 바꿀 수 있습니다 |
| `child` 안에서 연 대화상자 · 팝오버의 입력 | `TextField` 를 뺀 값 보고 입력이 이 필드에 알립니다 | 알리지 않습니다 |
| 좁은 폭의 `counterText` | 한 줄을 지킵니다 | 문구와 함께 줄어 두 줄로 꺾일 수 있습니다 |
| HTML 속성 | 없습니다 | `id` · `classes` · `css` |

<a id="props"></a>
<a id="props-parameters"></a>

## API

Flutter 와 Jaspr Web 이 같은 속성을 씁니다. `W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다. 일부 값만 바꾼 사본은 `copyWith` 로, 스타일만 덧붙인 사본은 `withStyle` 로 만듭니다.

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String?` | `null` | 라벨 글자. 필드의 이름이 됩니다. |
| `labelWidget` | `W?` | `null` | `label` 대신 그릴 위젯([플랫폼 차이](/components/form-field#플랫폼-차이)) |
| `labelMaxLines` | `int?` | `null` | `label` 의 최대 줄 수. 비우면 제한하지 않습니다(`labelOverflow` 가 `ellipsis` 면 한 줄). |
| `labelOverflow` | `CoreTextOverflow?` | `null` | 넘친 `label` 의 처리(`clip` · `fade` · `ellipsis` · `visible`) |
| `labelAction` | `W?` | `null` | 라벨 줄 끝의 링크나 버튼. 라벨이 없으면 그리지 않습니다. |
| `child` | `W?` | `null` | 입력 위젯 |
| `description` | `String?` | `null` | 입력 아래의 도움말. 오류가 있으면 숨깁니다. |
| `error` | `String?` | `null` | 직접 넘기는 오류 문구. `validator` 의 오류가 있으면 그 문구가 우선합니다. |
| `counterText` | `String?` | `null` | 아래 줄 끝의 글자 수 같은 문구 |

### 상태와 형태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `required` | `bool` | `false` | 라벨에 필수 표시를 붙입니다. 검사하지 않습니다. |
| `enabled` | `bool` | `true` | `false` 면 비활성입니다. 비활성 Fieldset 이나 비활성 FormField 안에서는 `true` 여도 비활성입니다. |
| `size` | `CoreComponentSize` | `md` | 라벨의 크기 단계. FormLabel 에 넘깁니다. |

### 검증

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `validator` | `Validator<dynamic>?` | `null` | `child` 가 알린 값을 검사합니다. `controller` 가 있는 Form 안에서만 실행됩니다. |
| `formKey` | `FormKey<dynamic>?` | `null` | 컨트롤러에서 이 필드를 가리키는 키. 비우면 필드마다 새로 만듭니다. |

### 스타일

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `formFieldStyle` | `CoreFormFieldStyle?` | `null` | 라벨 · 도움말 · 오류 · 글자 수 · 간격의 겉모습 |

### Web 전용

`name` · `autocomplete` 같은 HTML 폼 속성은 FormField 가 아니라 입력에 줍니다. Jaspr Web 의 TextField 는 `name` 과 `autofillHints` 로 받습니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 묶음 요소의 id |
| `classes` | `String?` | `null` | 묶음 요소에 더할 클래스 |
| `css` | `Styles?` | `null` | 묶음 요소에 더할 스타일 |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.formField` | `CoreFormFieldTheme?` | `style`(`CoreFormFieldStyle?`)이 모든 FormField 에 적용됩니다. |

## 관련 컴포넌트

<Cards columns="2">
<Card component="form" props="mode=submitted" title="Form">

필드를 담고, 컨트롤러로 값을 모아 검증합니다.

</Card>
<Card component="fieldset" props="fields=1;width=compact" label="계정" title="Fieldset">

여러 필드를 범례 아래 묶습니다. 비활성 상태는 안의 FormField 에도 전해집니다.

</Card>
<Card demo="form-field/related-form-label" title="FormLabel">

FormField 의 라벨을 그립니다. 라벨과 필수 표시만 필요하면 따로 씁니다.

</Card>
<Card demo="form-field/related-validator-hint" title="ValidatorHint">

FormField 의 오류 문구를 그립니다. 안내 한 줄만 필요하면 따로 씁니다.

</Card>
</Cards>
