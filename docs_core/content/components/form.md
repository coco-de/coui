---
title: Form
description: 폼 유효성 검증 컴포넌트
category: form
platforms: [flutter, web]
related: [text-field, select, checkbox, button]
tags: [form-control, validation, submit]
template: v2
source: form/form
---

# Form

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

검증 시점을 바꾸고 제출 버튼을 눌러 보며 Form 을 확인하고, 만들어진 코드를 복사하세요.

<Playground component="form" />

Form 은 `children` 을 세로로 쌓고, `showActions` 를 켜면 맨 아래에 버튼 줄을 둡니다. 크기나 variant 처럼 겉모습을 고르는 속성은 없습니다. `controller`(`FormController`)를 주면 그 안의 [FormField](/components/form-field)가 입력 값을 모으고, `validator` 로 검사한 오류를 필드 아래에 보여 줍니다.

"검증 시점" 은 Form 의 속성이 아닙니다. 미리보기의 검증기가 어느 시점부터 검사할지를 고릅니다. `initial` 은 킷의 `RequiredValidator` 이고, `changed` 와 `submitted` 는 [검증기 직접 만들기](/components/form#검증기-직접-만들기)의 `RequiredFrom` 입니다. `submitted` 에서는 제출한 뒤 보인 오류가 글자를 고치기 시작하면 사라집니다 — 검증기가 값이 바뀐 시점은 통과시키기 때문입니다. 코드의 `handleSubmit` 은 [제출](/components/form#제출)의 함수입니다.

## 구조

Form 은 필드를 쌓는 줄과, 켜면 생기는 버튼 줄로 이루어집니다. 필드 한 줄은 보통 FormField 하나이고, 라벨 · 입력 · 도움말은 FormField 가 그립니다.

<Anatomy demo="form/anatomy">
<AnatomyItem part="container" name="Form">

필드와 버튼 줄을 세로로 쌓는 틀. 줄 사이 간격은 `rowSpacing`(기본 24)입니다.

</AnatomyItem>
<AnatomyItem select="[role=group]" side="right" name="FormField">

입력 하나를 감싸는 틀. 라벨 · 입력 · 아래 줄 사이는 8 입니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="label">

`FormField` 의 `label`. `required` 면 뒤에 `*` 가 붙습니다.

</AnatomyItem>
<AnatomyItem select="input" side="left" name="child">

호출자가 넣는 입력. 여기서는 TextField 입니다.

</AnatomyItem>
<AnatomyItem select="p" side="right" name="description">

도움말. 오류가 있으면 같은 자리에 오류 문구가 대신 나옵니다.

</AnatomyItem>
<AnatomyItem select="[role=group] + div:last-child" side="right" name="actions">

`showActions` 를 켰을 때의 버튼 줄. 보조 버튼이 앞, 주 버튼이 뒤입니다.

</AnatomyItem>
</Anatomy>

## 액션 행

`showActions: true` 를 주면 `children` 뒤의 마지막 줄에 보조 버튼과 주 버튼을 둡니다. 위는 버튼을 넘기지 않은 상태이고, 아래는 직접 만든 버튼을 넘긴 상태입니다.

<Preview demo="form/actions" />

| 항목 | 동작 |
| --- | --- |
| 켜기 | `showActions` 가 `true` 일 때만 그립니다. 기본은 `false` 입니다. |
| 자리 | 마지막 줄이고, 위 줄과의 간격은 다른 줄과 같은 `rowSpacing` 입니다. 글이 끝나는 쪽(왼쪽에서 오른쪽으로 쓰는 언어에서는 오른쪽)에 모으고, 두 버튼 사이는 `actionSpacing`(기본 8)입니다. |
| 순서 | 보조 버튼 다음에 주 버튼 |
| 기본 버튼 | `primaryAction` 을 비우면 화면 언어의 "제출" 버튼(`primary`)을, `secondaryAction` 을 비우면 "취소" 버튼(`ghost`)을 그립니다. 둘 다 `onPressed` 가 없어 **비활성으로 그려지고 눌리지 않습니다.** |
| 보조 버튼 감추기 | `showSecondaryAction: false` 를 줍니다. `secondaryAction: null` 은 "버튼 없음" 이 아니라 기본 버튼입니다. |
| `onSubmit` 과의 관계 | 버튼은 `onSubmit` 을 부르지 않습니다. 동작하는 버튼은 `onPressed` 를 달아 `primaryAction` · `secondaryAction` 에 넘깁니다. |

```dart
Form(
  showActions: true,
  secondaryAction: Button(
    variant: CoreButtonVariant.ghost,
    onPressed: handleCancel,
    child: Text('이전'),
  ),
  primaryAction: Button(onPressed: handleSubmit, child: Text('저장')),
  children: [
    FormField(label: '이름', child: TextField(placeholder: Text('홍길동'))),
  ],
)
```

<a id="변형-variants"></a>

## 상태

Form 자체에는 상태가 없습니다. 아래는 필드를 감싸는 FormField 의 상태입니다.

<Preview demo="form/states" />

| 항목 | 동작 |
| --- | --- |
| 도움말 | `description` 을 입력 아래에 `bodySmall` · `onSurfaceVariant` 로 보여 줍니다. |
| 오류 | `validator` 가 오류를 내면 그 문구를, 아니면 `error` 속성의 문구를 도움말 자리에 보여 줍니다. 둘은 함께 보이지 않습니다. 안의 TextField(TextField 로 트리거를 그리는 Select 포함)는 테두리가 `error` 로 바뀝니다. |
| 필수 | `required: true` 면 라벨 뒤에 `*` 를 붙입니다. **표시만 합니다.** 값이 비었는지는 `validator` 가 검사합니다. |
| 비활성 | `enabled: false` 면 라벨 글자가 `onSurfaceSubtle` 이 되고(필수 표시는 `error` 색 그대로) 필드 전체의 포인터 입력을 막습니다. 안의 TextField 는 비활성 모습이 됩니다. [Fieldset](/components/fieldset) 이 `enabled: false` 면 FormField 의 `enabled` 와 상관없이 비활성입니다. |
| 라벨 옆 동작 | `labelAction` 은 라벨 줄 끝에 놓입니다. "비밀번호 찾기" 같은 링크나 버튼에 씁니다. 라벨이 없으면 그려지지 않습니다. |
| 글자 수 | `counterText` 는 아래 줄 끝에 놓입니다. `0 / 40` 같은 문구는 호출자가 만들어 넘깁니다. 도움말과 오류가 없어도 이 줄은 남습니다. |

### 에러 상태

```dart
FormField(
  label: '이메일',
  error: '올바른 이메일을 입력하세요',
  required: true,
  child: TextField(placeholder: Text('이메일')),
)
```

### 설명 텍스트

```dart
FormField(
  label: '비밀번호',
  description: '8자 이상, 대소문자 및 숫자를 포함하세요',
  child: TextField(placeholder: Text('비밀번호'), obscureText: true),
)
```

### 비활성화

```dart
FormField(
  label: '이름',
  enabled: false,
  child: TextField(placeholder: Text('수정 불가')),
)
```

<Note>

Checkbox · Toggle · RadioGroup · TextArea 처럼 FormField 의 비활성 상태를 받지 않는 입력은 `enabled: false` 안에서도 활성 모습이고, 키보드로 값을 바꿀 수 있습니다. 이런 입력에는 입력에도 `enabled: false` 를 줍니다.

</Note>

<a id="동작-스펙-behavior"></a>

## 검증

검증기와 `FormValidationMode`, 컨트롤러의 검증 순서는 `coui_core` 에 있어 두 플랫폼이 같습니다. `FormController` · `FormKey` 도 두 플랫폼에서 같은 이름으로 씁니다. 일부 입력의 값 타입, 알리는 방식처럼 다른 점은 [플랫폼 차이](/components/form#플랫폼-차이)에 있습니다.

<a id="controlled-form-flutterweb-공통"></a>

### 컨트롤러 연결

`Form(controller:)` 안에서 `FormField(validator:)` 를 쓰면, [값을 보고하는 입력](/components/form#값을-보고하는-입력)이 값을 알릴 때마다 검사 결과가 필드에 나타납니다. 필드마다 따로 연결할 것은 없습니다. `validator` 가 없는 필드의 값도 컨트롤러에 모입니다. `RequiredFrom` 과 `MustAgree` 는 [검증기 직접 만들기](/components/form#검증기-직접-만들기)에서 정의합니다.

```dart
const emailKey = FormKey<String>('email');
const agreeKey = FormKey<bool>('agree');

final controller = FormController(); // 다 쓰면 controller.dispose()

Form(
  controller: controller,
  children: [
    FormField(
      formKey: emailKey,
      label: '이메일',
      required: true,
      validator: const RequiredFrom(FormValidationMode.submitted),
      child: TextField(placeholder: Text('name@company.com')),
    ),
    FormField(
      formKey: agreeKey,
      label: '약관 동의',
      required: true,
      validator: const MustAgree(),
      child: Checkbox(checked: agreed, onChanged: setAgreed),
    ),
  ],
)

// 값과 오류 읽기 (두 플랫폼 같음)
final email = controller.getValue(emailKey);
final allValues = controller.values;
final errors = controller.errors;
final emailError = controller.getSyncError(emailKey);
```

`formKey` 를 주지 않으면 필드마다 새 키가 만들어집니다. 값을 읽거나 다른 필드의 변화를 따라가려면 키를 줍니다.

| 멤버 | 설명 |
| --- | --- |
| `controller.values` | 값을 보고한 필드의 지금 값. 키는 `FormKey` 입니다. |
| `controller.errors` | 오류를 낸 필드의 결과. 비동기 검사를 기다리는 필드는 `WaitingResult` 로 들어갑니다. |
| `controller.validities` | 값을 보고한 모든 필드의 검사 결과(값 또는 `Future`) |
| `controller.getValue(key)` | 그 필드의 값. 없으면 `null` |
| `controller.hasValue(key)` | 그 필드에 `null` 이 아닌 값이 있는지 |
| `controller.getError(key)` | 그 필드의 결과. 비동기 검사 중이면 `Future` |
| `controller.getSyncError(key)` | 같은 결과를 바로 읽습니다. 검사 중이면 `WaitingResult` |
| `controller.revalidate(context, mode)` | 검증기가 있는 모든 필드를 `mode` 로 다시 검사합니다. 반환값은 없습니다. |
| `controller.addListener(listener)` | 값이나 결과가 바뀌면 부릅니다. |
| `controller.dispose()` | 다 쓴 컨트롤러를 정리합니다. |

### 값을 보고하는 입력

검증기는 값을 보고하는 입력에만 실행됩니다.

| 입력 | Flutter 의 값 | Jaspr Web 의 값 |
| --- | --- | --- |
| `TextField` | `String`, 빈 글자는 `null` | 같음 |
| `NumberInput` | 안의 TextField 가 적힌 글자(`String`)를 보고합니다 | 같음 |
| `Checkbox` | `bool?` | `bool?` |
| `Toggle` · `SwitchField` | `bool` | `bool` |
| `RadioGroup` | 선택지의 타입 `T`, 고르지 않으면 `null` | `String`, 고르지 않으면 `null` |
| `InputOtp` | 칸마다의 값을 담은 `List<int?>` | `String` |
| `PhoneInput` | `CorePhoneNumber` (`PhoneNumber`) | `CorePhoneNumber` (`PhoneInputValue`) |
| `ObjectInput` | 보고하지 않습니다 | `Map<String, String>` |

Flutter 의 `ObjectFormField` 도 자기 값을 보고합니다. 이 표에 없는 입력(Select · Autocomplete · TextArea · Slider · DatePicker 등)은 값을 알리지 않아, 그 필드의 검증기는 실행되지 않고 `controller.values` 에도 들어가지 않습니다. 이런 값은 `onChanged` 로 받아 직접 검사하고 `FormField` 의 `error` 에 넘깁니다.

예외가 있습니다. `selection` 이 `multiple` 인 `OptionItem`(`OptionList` 안에 둔 것 포함)과 `MultiAnswerCard` 는 안에 그리는 체크 표시(`Checkbox`)가 체크 상태(`bool?`)를 알립니다. Flutter 의 `RichEditor` 도 문서에 체크 목록 줄이 있으면 그 체크 표시가 같은 값을 알립니다. 그래서 이것들은 FormField 의 입력으로 쓰지 않습니다. 필드 하나에 체크 표시가 여러 개면 마지막에 알린 상태 하나만 필드 값으로 남습니다.

<a id="유효성-검증-모드-formvalidationmode"></a>

### 검증 시점

컨트롤러는 검증기를 부를 때마다 지금이 어느 때인지를 `FormValidationMode` 로 넘깁니다.

| 모드 | 넘기는 때 |
| --- | --- |
| `initial` | 입력이 값을 처음 알릴 때. 필드가 화면에 나타날 때입니다. |
| `changed` | 값이 바뀔 때. 바뀐 필드를 검사하고, `shouldRevalidate` 가 `true` 인 다른 필드도 같은 모드로 다시 검사합니다. |
| `submitted` | 호출자가 `controller.revalidate` 에 이 모드를 넘길 때. Form 은 스스로 부르지 않습니다. |

시점을 고르는 속성은 Form 에도 FormController 에도 없습니다. 언제부터 오류를 보일지는 검증기가 마지막 인자(`lifecycle`)를 보고 정합니다. 내장 검증기는 이 값에 따라 판정을 바꾸지 않아서, `RequiredValidator` 를 단 빈 필드는 **화면에 나타나자마자** 오류를 보입니다.

### 제출

Form 은 제출을 대신하지 않습니다. 버튼의 `onPressed` 에서 `revalidate` 를 부른 뒤 `controller.errors` 를 확인합니다. 검증 메시지의 언어를 정하는 객체가 플랫폼마다 다릅니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
void handleSubmit() {
  controller.revalidate(
    CoUIValidationContext(context),
    FormValidationMode.submitted,
  );
  if (controller.errors.isEmpty) submit(controller.values);
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
void handleSubmit() {
  controller.revalidate(
    CoUIWebValidationContext(
      localizations: CouiLocalizations.of(context),
    ),
    FormValidationMode.submitted,
  );
  if (controller.errors.isEmpty) submit(controller.values);
}
```

  </TabItem>
</Tabs>

동기 검증기의 결과는 `revalidate` 가 끝나면 바로 `errors` 에 반영됩니다. 비동기 검증기는 끝날 때까지 `errors` 에 `WaitingResult` 가 남으므로, 끝난 뒤의 결과는 `addListener` 로 받습니다. Web 에서 `localizations` 를 넘기지 않으면 `revalidate` 가 만드는 기본 문구가 영어가 됩니다.

<a id="validator-시스템-flutterweb-공통"></a>

### 검증기

검증기는 `coui_core` 에 있어 두 플랫폼이 같은 것을 씁니다.

| 검증기 | 막는 경우 |
| --- | --- |
| `RequiredValidator<T>` | 값이 `null` 이거나 빈 `String` 일 때. 문구는 `message` 로 바꾸고, 비우면 화면 언어의 기본 문구를 씁니다. |
| `NotValidator<T>` | 감싼 검증기가 통과할 때 |
| `CompositeValidator<T>` | 담은 검증기 중 하나라도 막을 때(AND). 처음 막은 결과를 보여 줍니다. |
| `OrValidator<T>` | 하나라도 통과하면 통과시키는 조합(OR)입니다. 지금은 모두 막아도 통과시켜, 아무 값도 막지 않습니다(알려진 제약). |
| `PhoneValidator` | `PhoneInput` 의 번호가 비어 있을 때 |

```dart
// AND — 모두 통과해야 합니다 (& · + · combine)
final both = const RequiredValidator<String>() & customValidator;

// OR — 지금은 모두 실패해도 통과합니다 (알려진 제약)
final either = aValidator | bValidator;

// NOT — 결과를 뒤집습니다. ~ 연산자는 없습니다.
final inverted = NotValidator(customValidator);
```

`RequiredValidator` 는 "값이 있는가" 만 봅니다. 체크하지 않은 Checkbox 와 꺼진 Toggle 은 `false` 를 보고하므로 `RequiredValidator<bool>` 을 통과합니다. 번호를 적지 않은 PhoneInput 도 값이 있어 통과합니다(`PhoneValidator` 를 씁니다). Flutter 의 InputOtp 는 빈 칸이 담긴 목록을, Jaspr Web 의 ObjectInput 은 모든 칸이 비어 있어도 `Map` 을 보고해 역시 통과합니다.

### 검증기 직접 만들기

`Validator<T>` 를 상속해 `validate` 를 구현합니다. 통과하면 `null` 을, 막으려면 `InvalidResult` 를 돌려줍니다. 값을 고쳐 넣게 하려면 `ReplaceResult` 를 돌려줍니다. 입력이 자기 값을 알리고 돌려받은 `ReplaceResult` 만 그 입력에 전달됩니다. TextField 는 글자를 그 값으로 바꾸고, Checkbox · Toggle · RadioGroup 은 `onChanged` 로 넘깁니다. `revalidate` 나 다른 필드의 변화로 다시 검사해 나온 `ReplaceResult` 는 입력에 전달되지 않습니다. `revalidate` 에서 나온 결과는 필드에 문구 없이 `controller.errors` 에 남아 `errors.isEmpty` 검사를 막으므로, `submitted` 에서 값을 고치는 검증기는 만들지 않습니다.

```dart
/// from 시점부터 빈 값을 막고, 그 전에는 통과시킵니다.
class RequiredFrom extends Validator<String> {
  const RequiredFrom(this.from);

  final FormValidationMode from;

  @override
  ValidationResult? validate(
    CoreValidationContext context,
    String? value,
    FormValidationMode lifecycle,
  ) {
    if (lifecycle.index < from.index) return null;
    if (value != null && value.isNotEmpty) return null;
    return InvalidResult(context.messages.formNotEmpty, state: lifecycle);
  }
}

/// 약관에 동의하지 않으면 막습니다. 처음 나타날 때는 통과시킵니다.
class MustAgree extends Validator<bool> {
  const MustAgree();

  @override
  ValidationResult? validate(
    CoreValidationContext context,
    bool? value,
    FormValidationMode lifecycle,
  ) {
    if (lifecycle == FormValidationMode.initial || value == true) return null;
    return InvalidResult('약관에 동의해 주세요.', state: lifecycle);
  }
}
```

다른 필드에 따라 결과가 달라지는 검증기는 `shouldRevalidate` 로 어느 필드가 바뀔 때 다시 검사할지 알립니다. 다른 필드의 값은 생성자에 넣지 말고 `validate` 안에서 컨트롤러로 읽습니다.

```dart
const passwordKey = FormKey<String>('password');

class MatchesPassword extends Validator<String> {
  const MatchesPassword(this.controller);

  final FormController controller;

  @override
  ValidationResult? validate(
    CoreValidationContext context,
    String? value,
    FormValidationMode lifecycle,
  ) {
    if (lifecycle == FormValidationMode.initial) return null;
    if (value == controller.getValue(passwordKey)) return null;
    return InvalidResult('비밀번호가 서로 다릅니다.', state: lifecycle);
  }

  @override
  bool shouldRevalidate(CoreFormKey<dynamic> source) => source == passwordKey;
}
```

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

여러 입력의 검증을 한 번에 관리할 때, 제출 전에 입력을 검사해 필드마다 오류를 알릴 때, 비밀번호 확인처럼 필드끼리 값이 얽힐 때 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 입력이 하나뿐이고 폼 검증이 필요 없을 때 | [TextField](/components/text-field) — 자기 `label` · `errorText` 가 있습니다 |
| 검증 없이 묶음 제목과 묶음 단위 비활성만 필요할 때 | [Fieldset](/components/fieldset) |

### 필수 표시와 오류 문구

<a id="do"></a>
<a id="dont"></a>

<Cards columns="2">
<Card demo="form/do-required" tone="do" eyebrow="이렇게 하세요">

필수 칸을 `required` 로 표시합니다. 어느 칸을 채워야 하는지 먼저 알면 제출 실패가 줄어듭니다. 검사하려면 `validator` 도 함께 줍니다.

</Card>
<Card demo="form/dont-required" tone="dont" eyebrow="이렇게 하지 마세요">

필수와 선택을 가리지 않고 늘어놓으면 무엇을 채워야 하는지 알 수 없습니다.

</Card>
<Card demo="form/do-helpful-error" tone="do" eyebrow="이렇게 하세요">

오류 문구에 고치는 방법을 적습니다. 기준을 알면 바로 고칠 수 있습니다.

</Card>
<Card demo="form/dont-vague-error" tone="dont" eyebrow="이렇게 하지 마세요">

무엇이 틀렸는지 알 수 없는 문구는 여러 번 다시 입력하게 만듭니다.

</Card>
</Cards>

### 조합 예제

회원가입 폼입니다. `controller` 와 `handleSignUp` 은 [제출](/components/form#제출)처럼 만들고, 오류는 제출할 때부터 보이게 `RequiredFrom` 을 씁니다.

```dart
Form(
  controller: controller,
  showActions: true,
  showSecondaryAction: false,
  primaryAction: Button(onPressed: handleSignUp, child: Text('가입하기')),
  children: [
    FormField(
      label: '이름',
      required: true,
      validator: const RequiredFrom(FormValidationMode.submitted),
      child: TextField(placeholder: Text('홍길동')),
    ),
    FormField(
      label: '이메일',
      required: true,
      validator: const RequiredFrom(FormValidationMode.submitted),
      child: TextField(placeholder: Text('example@email.com')),
    ),
    FormField(
      label: '비밀번호',
      required: true,
      description: '8자 이상, 대소문자 및 숫자를 포함하세요',
      validator: const RequiredFrom(FormValidationMode.submitted),
      child: TextField(placeholder: Text('비밀번호'), obscureText: true),
    ),
  ],
)
```

## 배치

| 항목 | 동작 |
| --- | --- |
| 방향 | 세로로 쌓습니다. 가로로 놓는 속성은 없습니다. |
| 줄 간격 | `rowSpacing`, 기본 24. 버튼 줄도 한 줄이라 같은 간격입니다. |
| 폭 | 자식을 부모 폭 끝까지 늘립니다. `children` 에 직접 둔 Button 도 폭 전체를 차지합니다. |
| Flutter 의 부모 | 가로가 정해진 부모 안에 둡니다. `Row` 안에서는 `Expanded` 나 `SizedBox` 로 폭을 줍니다. |
| 스크롤 | Form 은 스크롤을 만들지 않습니다. 긴 폼은 스크롤하는 부모 안에 둡니다. |
| 밀도 | `rowSpacing` 과 `actionSpacing` 은 앱의 밀도를 따릅니다. |

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

Form 에서 바꿀 수 있는 겉모습 값은 간격 두 개(`CoreFormStyle`)입니다. Form 에는 `formStyle` 속성이 없어서, 폼 하나는 `rowSpacing` · `actionSpacing` 속성으로 바꾸고 앱 전체 기본값은 `CoreComponentTheme.form` 에 둡니다. 필드의 겉모습은 FormField 의 `formFieldStyle`(`CoreFormFieldStyle`)이나 `CoreComponentTheme.formField` 로 바꿉니다.

<Split>

<Code language="dart" title="폼 하나만 바꾸기">
Form(
  rowSpacing: CoreSpace.space16,
  actionSpacing: CoreSpace.space12,
  showActions: true,
  children: fields,
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    form: CoreFormTheme(
      style: CoreFormStyle(rowSpacing: CoreSpace.space16),
    ),
  ),
)
</Code>

</Split>

### 값이 정해지는 순서

```text
CoreFormStyle.defaultRowSpacing · defaultActionSpacing   // 24 · 8
  → CoreComponentTheme.form.style                        // 앱 전체
  → rowSpacing · actionSpacing                           // Form 하나
```

뒤로 갈수록 우선합니다.

<a id="접근성-accessibility"></a>

## 접근성

Form 은 보조 기술에 알리는 정보를 따로 붙이지 않습니다. 필드의 이름 · 설명 · 오류는 FormField 가 알립니다.

### 역할

| 요소 | Flutter | Jaspr Web |
| --- | --- | --- |
| Form | 의미 정보를 붙이지 않는 `Column`. `controller` 를 자손에게 내려 줄 뿐입니다. | `onSubmit` 이 있으면 `<form>`, 없으면 `<div>` 이고 `tag` 가 이 판단을 덮습니다. `role` 과 `aria-*` 를 붙이지 않습니다. |
| FormField | `Semantics(container: true, enabled:, label:, hint:)` | `<div role="group">` 에 `aria-labelledby` · `aria-describedby`, 오류면 `aria-invalid="true"`, 필수면 `aria-required="true"`, 비활성이면 `aria-disabled="true"` |
| 라벨 | FormLabel. 필수 표시 `*` 는 읽지 않습니다. | `<label>` 이지만 `for` 가 없고 입력을 감싸지도 않습니다. 그룹에만 `aria-labelledby` 로 연결하고 입력 요소에는 연결하지 않습니다. `*` 는 `aria-hidden="true"` 입니다. |
| 오류 문구 | 라이브 영역 | `role="alert"` |
| 버튼 줄 | Button | Button. 기본 버튼은 `disabled` 입니다. |

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` | 다음 포커스 가능한 요소(대개 다음 필드)로 옮깁니다. |
| `Shift` · `Tab` | 이전 요소로 옮깁니다. |
| `Enter` | Web 에서 루트가 `<form>` 이면 브라우저의 암묵적 제출이 일어날 수 있습니다. 조건은 아래와 같습니다. |

Form 과 FormField 는 어떤 키도 직접 처리하지 않습니다. 필드 사이를 건너뛰거나 묶음 단위로 옮기는 단축키는 없습니다.

#### Web 에서 Enter 로 제출

- 루트 태그는 `onSubmit` 이 있으면 `<form>` 이고, `tag` 를 주면 그 값이 이깁니다. `tag: 'form'` 이면 `onSubmit` 없이도 `<form>`, `tag: 'div'` 면 `onSubmit` 이 있어도 `<div>` 입니다.
- CoUI Button 의 기본 `type` 은 `button` 이라 폼 안에 제출 버튼이 없습니다. 제출 버튼이 없는 폼은 글자를 받는 입력이 하나일 때만 `Enter` 로 제출됩니다. Button 에 `attributes: {'type': 'submit'}` 을 넘기면 제출 버튼이 되고, 누르면 그 버튼의 `onPressed` 와 폼의 `onSubmit` 이 둘 다 불립니다.
- `onSubmit` 을 부르는 처리는 브라우저의 기본 동작을 막지 않아, 제출이 일어나면 페이지 전송까지 이어집니다.

두 플랫폼 모두 제출 버튼의 `onPressed` 에서 검증과 제출을 직접 부르는 구성이 안전합니다.

### 스크린 리더

- **이름** — `FormField(label:)` 의 글자입니다. Web 은 FormLabel 에 만든 id 를 그룹의 `aria-labelledby` 가 가리키고, Flutter 는 같은 글자를 `Semantics.label` 로 둡니다. `labelWidget` 을 넘기면 Web 은 `label` 을 함께 줘도 `aria-labelledby` 를 붙이지 않아 그룹에 이름이 없습니다. Flutter 는 `labelWidget` 안의 글자가 필드 노드에 합쳐져 함께 읽힙니다.
- **설명과 오류** — `description` 은 Web 에서 그룹의 `aria-describedby` 로, Flutter 에서 필드 노드의 `Semantics.hint` 로 연결됩니다. 오류가 생기면 그 자리를 오류 문구가 대신합니다. 오류 아이콘은 읽지 않습니다.
- **오류 알림** — 오류 문구가 나타나면 알립니다. Web 은 `role="alert"`, Flutter 는 라이브 영역입니다.
- **필수** — Web 은 그룹에 `aria-required` 를 붙입니다. `group` 은 이 속성을 지원하는 역할이 아니라서 보조 기술이 읽지 않을 수 있습니다. `*` 글자는 두 플랫폼 모두 읽지 않고, Flutter 는 필수 여부를 알리지 않습니다.
- **글자 수** — Web 의 `counterText` 는 `aria-describedby` 에 들어가지 않습니다.

### 포커스 관리

- **진입** — 화면에 나타날 때 포커스를 옮기지 않습니다. 첫 필드에 자동으로 들어가지 않습니다.
- **이동** — 포커스를 가두지 않습니다. 마지막 요소에서 `Tab` 을 누르면 폼 밖으로 나갑니다. 순서는 `children` 에 적은 순서 그대로입니다.
- **제출 실패** — 오류 필드로 포커스를 옮기지 않습니다. 키보드로 버튼을 눌렀다면 포커스는 버튼에 남고, 포인터로 누르면 버튼이 포커스를 받지 않을 수 있습니다. 옮기려면 `revalidate` 뒤에 키를 필드 순서대로 `controller.getSyncError` 로 확인하고, 처음 걸린 입력에 포커스를 줍니다(Flutter 는 `focusNode.requestFocus()`, Web 은 그 입력의 DOM 요소를 찾아 `focus()`).

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 내장 검증기는 검증 시점을 보지 않아, `RequiredValidator` 를 단 빈 필드는 화면에 나타나자마자 오류를 보입니다. 시점을 늦추려면 [검증기를 직접 만듭니다](/components/form#검증기-직접-만들기). |
| 공통 | `OrValidator`(OR 연산자 조합)는 담은 검증기가 모두 막아도 통과합니다. 지금은 쓰지 않습니다. |
| 공통 | `RequiredValidator` 는 `false` 를 보고한 Checkbox · Toggle, 번호 없는 PhoneInput, (Flutter) 빈 InputOtp, (Jaspr Web) 빈 ObjectInput 을 통과시킵니다. |
| 공통 | 값을 보고하지 않는 입력은 검증기가 실행되지 않습니다. 필수 Select 가 비어 있어도 `controller.errors` 는 비어 있어 제출 검사를 통과합니다. |
| 공통 | `selection` 이 `multiple` 인 `OptionItem`(`OptionList` 안 포함)과 `MultiAnswerCard`, Flutter 에서는 체크 목록 줄이 있는 `RichEditor` 도 FormField 안에 두면 안쪽 체크 표시가 `bool?` 값을 보고합니다. 여러 개면 마지막에 알린 값이 필드 값이 됩니다. |
| 공통 | `revalidate` 에서 나온 `ReplaceResult` 는 입력에 전달되지 않고, 필드에 문구 없이 `controller.errors` 에 남습니다. |
| 공통 | 한 FormField 에 값을 보고하는 입력을 둘 이상 두면 마지막에 알린 값이 필드의 값이 됩니다. |
| 공통 | 컨트롤러는 한 번 값을 받은 필드를 지우지 않습니다. 화면에서 뺀 필드의 값과 오류가 `values` · `errors` 에 남고 `revalidate` 도 검사합니다. |
| 공통 | `validator` 를 바꿔도 입력 값이 바뀌기 전까지 컨트롤러는 전에 받은 검증기를 씁니다. `revalidate` 도 같습니다. |
| 공통 | `NotValidator` 로 감싼 검증기의 `shouldRevalidate` 는 전달되지 않습니다. |
| 공통 | 동기 검증기의 결과에는 필드 키가 붙지 않습니다. `controller.errors` 의 값에서 `.key` 를 읽으면 오류가 나므로 맵의 키를 씁니다. |
| 공통 | 비동기 검사를 기다리는 동안 필드에는 아무 표시가 없습니다(`error` 속성이 있으면 그 문구가 보입니다). |
| 공통 | 기본 버튼은 `onPressed` 가 없어 비활성입니다. |
| 공통 | `FormField(enabled: false)` 는 포인터 입력만 직접 막습니다. 비활성 상태를 받지 않는 입력(Checkbox · Toggle · RadioGroup · TextArea 등)은 활성 모습이고, `Tab` 으로 들어가 키보드로 값을 바꿀 수 있습니다. |
| 공통 | 제출이 실패해도 첫 오류 필드로 포커스가 옮겨 가지 않습니다. |
| Flutter | `Form.onSubmit` 은 받기만 하고 부르지 않습니다. |
| Flutter | 필수 필드라는 것을 보조 기술에 알리지 않습니다. |
| Flutter | 컨트롤러는 알림을 보낼 때 새 프레임을 요청하지 않습니다. 화면에 다른 변화가 없으면 비동기 검사 결과의 표시와 `addListener` 호출이 다음 프레임까지 늦어질 수 있습니다. |
| Jaspr Web | 라벨 · 도움말 · 오류는 그룹(`role="group"`)에만 연결되고, 입력 요소 자체의 이름 · 설명이 되지 않습니다. 오류일 때 TextField 의 입력에는 `aria-invalid` 만 따로 붙습니다. 입력에 이름이 필요하면 TextField 의 `attributes` 로 `aria-label` 을 줍니다. |
| Jaspr Web | FormField 의 `required` 는 그룹의 `aria-required` 로만 전하는데, `group` 은 이 속성을 지원하는 역할이 아닙니다. |
| Jaspr Web | `<form>` 의 제출이 브라우저 기본 동작을 막지 않아 페이지가 다시 불러와질 수 있습니다. |
| Jaspr Web | Form 과 FormField 는 `attributes` 를 받지 않아 `aria-label` 같은 속성을 직접 붙일 수 없습니다. |
| Jaspr Web | FormField 의 `labelWidget` 은 받은 그대로 그려, 필수 표시 · 크기 · 비활성 라벨 색이 붙지 않고 그룹의 이름도 없습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

속성 이름과 검증 순서는 같습니다. 알림 방식과 HTML 처리, 일부 입력의 값이 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 루트 | `Column`(내용 높이, 자식을 폭 끝까지) | 세로 flex `<div>` 또는 `<form>` (`tag`) |
| `onSubmit` | 부르지 않습니다 | `<form>` 의 `submit` 이벤트에서 부릅니다(`tag: 'div'` 면 일어나지 않습니다) |
| 컨트롤러 공유 | `Data.maybeOf<FormController>(context)` | `FormControllerScope.maybeOf(context)` |
| 컨트롤러 알림 | `ChangeNotifier`. 프레임이 끝난 뒤 알립니다 | 리스너 목록. 마이크로태스크로 알립니다 |
| 검증 메시지 언어 | `CoUIValidationContext(context)` — 화면의 언어 | `CoUIWebValidationContext(localizations:)` — 넘기지 않으면 영어 |
| `FormKey` | 위젯 키(`LocalKey`)로도 씁니다 | 폼 식별용입니다 |
| `RadioGroup` 값 | `T` | `String` |
| `InputOtp` 값 | `List<int?>` | `String` |
| `ObjectInput` | 값을 보고하지 않습니다 | `Map<String, String>` 을 보고합니다 |
| FormField 의 `labelWidget` | FormLabel 안에 넣어 필수 표시 · 크기 · 비활성 색을 적용합니다 | 받은 그대로 그립니다 |
| 필드 이름 | `label` 글자. `labelWidget` 안의 글자도 같은 노드에 합쳐집니다 | `label` 글자. `labelWidget` 이 있으면 이름이 없습니다 |
| 필수 알림 | 없습니다 | 그룹의 `aria-required`(보조 기술이 읽지 않을 수 있습니다) |
| 비활성 입력 차단 | `IgnorePointer` | `pointer-events: none` |
| 간격 | 앱의 크기 배율과 밀도를 따릅니다 | rem 길이와 밀도를 따릅니다(브라우저 글자 크기 반영) |
| HTML 속성 | 없습니다 | Form: `id` · `classes` · `css` · `tag`. FormField: `id` · `classes` · `css` |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. `W` 는 Flutter의 `Widget`, Web의 Jaspr `Component` 입니다.

### 내용과 컨트롤러

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `children` | `List<W>?` | `null` | 폼의 줄. 적은 순서대로 위에서 아래로 놓습니다. |
| `controller` | `FormController?` | `null` | 값을 모으고 검사합니다. 안의 FormField 가 씁니다. |

### 버튼 줄

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `showActions` | `bool` | `false` | 마지막 줄에 버튼 줄을 둡니다. |
| `primaryAction` | `W?` | `null` | 주 버튼. `null` 이면 "제출" 기본 버튼(비활성) |
| `secondaryAction` | `W?` | `null` | 보조 버튼. `null` 이면 "취소" 기본 `ghost` 버튼(비활성) |
| `showSecondaryAction` | `bool` | `true` | `false` 면 주 버튼만 남깁니다. |

### 간격과 콜백

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `rowSpacing` | `double?` | `null` | 줄 사이 간격. 비우면 테마의 값, 그다음 24 |
| `actionSpacing` | `double?` | `null` | 두 버튼 사이 간격. 비우면 테마의 값, 그다음 8 |
| `onSubmit` | `void Function()?` | `null` | Web 의 `<form>` 제출에서 부릅니다. Flutter 는 부르지 않습니다. 버튼과 연결되지 않습니다. |

### Web 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `tag` | `String?` | `null` | 루트 태그. 비우면 `onSubmit` 이 있을 때 `form`, 없으면 `div` |

웹의 Form 은 루트 요소에 붙는 `id` · `classes` · `css` 도 받습니다. `attributes` 와 DOM 이벤트는 받지 않습니다.

### `FormField`

필드 하나의 라벨 · 입력 · 도움말을 묶습니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String?` | `null` | 필드 라벨. 필드의 이름이 됩니다. |
| `labelMaxLines` | `int?` | `null` | `label` 의 최대 줄 수. 지정하지 않으면 제한하지 않습니다. |
| `labelOverflow` | `CoreTextOverflow?` | `null` | 최대 줄 수를 넘긴 라벨의 처리(`clip` · `fade` · `ellipsis` · `visible`) |
| `labelWidget` | `W?` | `null` | 라벨 글자 대신 그릴 위젯(플랫폼 차이 참고) |
| `labelAction` | `W?` | `null` | 라벨 줄 끝의 링크나 버튼 |
| `child` | `W?` | `null` | 입력 위젯 |
| `description` | `String?` | `null` | 입력 아래 도움말. 오류가 있으면 숨깁니다. |
| `error` | `String?` | `null` | 직접 넘기는 오류 문구. 컨트롤러의 검사 결과가 있으면 그 문구가 우선합니다. |
| `counterText` | `String?` | `null` | 아래 줄 끝의 글자 수 같은 문구 |
| `required` | `bool` | `false` | 라벨에 필수 표시를 붙입니다. 검사는 하지 않습니다. |
| `enabled` | `bool` | `true` | `false` 면 비활성 |
| `size` | `CoreComponentSize` | `md` | 라벨의 크기 단계. FormLabel 에 넘깁니다. |
| `validator` | `Validator<dynamic>?` | `null` | 입력 값을 검사합니다. `controller` 가 있는 Form 안에서만 실행됩니다. |
| `formKey` | `FormKey<dynamic>?` | `null` | 컨트롤러에서 이 필드를 가리키는 키. 비우면 자동으로 만듭니다. |
| `formFieldStyle` | `CoreFormFieldStyle?` | `null` | 라벨 · 도움말 · 오류 · 간격의 겉모습 |

### 테마

| 이름 | 타입 | 읽는 컴포넌트 |
| --- | --- | --- |
| `CoreComponentTheme.form` | `CoreFormTheme?` | Form (`style: CoreFormStyle?`) |
| `CoreComponentTheme.formField` | `CoreFormFieldTheme?` | FormField (`style: CoreFormFieldStyle?`) |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreFormStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `rowSpacing` | `double?` | Inter-item spacing (logical px, pre-scaling) between adjacent form rows. Flows directly into `Column.spacing` (Flutter) or flex `gap` CSS (Web) — both are native paint-API arguments that consume raw doubles, so this slot stays scalar (`double?`). `null` defers to [defaultRowSpacing]. |
| `actionSpacing` | `double?` | Spacing between the two action buttons (logical px, pre-scaling). Same native-paint-API scalar shape as [rowSpacing]. `null` defers to [defaultActionSpacing]. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card component="text-field" props="placeholder=example@email.com" title="TextField">

글자를 받는 입력. FormField 안에서 값을 보고하고 오류 테두리를 받습니다.

</Card>
<Card component="select" props="placeholder=국가를 선택하세요" title="Select">

선택지에서 하나를 고릅니다. 값을 FormField 에 보고하지 않으므로 `onChanged` 로 받아 검사합니다.

</Card>
<Card component="checkbox" props="checked=false" label="약관에 동의합니다" title="Checkbox">

약관 동의에 씁니다. 동의했는지는 값이 `true` 인지로 검사합니다.

</Card>
<Card component="button" props="variant=primary" label="제출" title="Button">

버튼 줄의 `primaryAction` · `secondaryAction` 에 넣습니다.

</Card>
</Cards>
