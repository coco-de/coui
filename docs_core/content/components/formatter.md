---
title: Formatter
description: TextField · TextArea 에 넘기는 입력 서식기 모음입니다. 친 글자를 정수 · 소수 · 대소문자 · 정해진 길이 · 계산 결과로 고칠 때 씁니다.
category: formatter
platforms: [flutter, web]
related: [text-field, formatted-input, number-input, form-field]
tags: [formatter, input, mask, form]
template: v2
source: form/formatter
---

# Formatter

<a id="live-preview"></a>

## 플레이그라운드

서식기를 골라 입력창에 글자를 쳐 보고, 만들어진 코드를 그대로 복사하세요.

<Playground component="formatter" />

Formatter 는 위젯이 아니라 서식기를 만드는 팩토리 모음 `TextInputFormatters` 입니다. 화면에 그리는 것은 없고, 입력창에 목록으로 넘기면 친 글자를 고칩니다. 변환 규칙은 두 플랫폼이 함께 쓰는 `CoreInputFormatters` 에 있습니다. Flutter 는 그 규칙을 `TextInputFormatter` 로 감싸고, Web 은 입력창의 문자열에 바로 적용합니다.

`integerOnly` 에서는 `130` 을 치면 `100` 이 됩니다. `mathExpression` 은 `10/4` 를 치고 Enter 를 눌러야 `2.5` 로 바뀝니다. 플레이그라운드에서 서식기를 바꾸면 입력창이 비워집니다.

`time` 은 한 글자씩 칠 때 두 플랫폼의 결과가 갈립니다. 빈 칸에 `4`, `5` 를 차례로 치면 Flutter 는 `54`, Web 은 `45` 가 됩니다. 이유는 접근성의 알려진 제약에 있습니다.

<a id="사용법"></a>

## 붙이는 곳

서식기는 두 속성에 넘깁니다.

| 속성 | 있는 컴포넌트 | 도는 때 |
| --- | --- | --- |
| `inputFormatters` | [TextField](/components/text-field) · [TextArea](/components/text-area) | 사용자가 치거나 붙여넣어 글자가 바뀔 때 |
| `submitFormatters` | TextField | 제출할 때, `onSubmitted` 를 부른 다음. Web 은 Enter 키를 누를 때입니다. |

<Split>

<Code language="dart" title="치는 동안">
TextField(
  placeholder: Text('나이'),
  inputFormatters: [TextInputFormatters.integerOnly(min: 0, max: 120)],
  onChanged: setAge,
)
</Code>

<Code language="dart" title="제출할 때">
TextField(
  placeholder: Text('금액 계산'),
  submitFormatters: [TextInputFormatters.mathExpression()],
)
</Code>

</Split>

| 항목 | 동작 |
| --- | --- |
| 여러 개를 넘길 때 | 목록 순서대로 이어 돌립니다. 앞 서식기의 결과가 다음 서식기에 들어갑니다. |
| `onChanged` | `inputFormatters` 를 거친 글자를 받습니다. |
| 코드로 넣은 글자 | `initialValue` · `value`, Flutter 의 `controller.text` 로 넣는 순간에는 서식기가 돌지 않습니다. 처음 값은 사용자가 고치거나 제출하기 전까지 넣은 그대로 보입니다. `submitFormatters` 는 고치지 않은 처음 값을 제출할 때도 돕니다. |
| 제출할 때의 값 | `onSubmitted` 는 `submitFormatters` 를 거치기 **전** 글자를 받습니다. 제출 서식은 `onChanged` 를 부르지 않습니다. |
| 바뀐 글자 읽기 | [Form](/components/form) 안의 [FormField](/components/form-field) 에 `formKey` 를 주고 TextField 를 감싸면, `FormController` 의 `getValue(formKey)` 로 바뀐 글자를 읽습니다. TextArea 는 FormField 에 값을 알리지 않으므로 `onChanged` 로 받습니다. Flutter 는 `controller` 로도 읽습니다. Web 에서 Form 없이 `mathExpression` 을 쓰면 `onSubmitted` 로 받은 글자를 같은 서식기의 `formatInitial` 에 넣어 결과를 얻습니다. |

<a id="동작-스펙-behavior"></a>

## 서식기 종류

아래 장면은 빈 칸에 글자를 한 번에 넣었을 때(붙여넣기)의 결과입니다. 결과는 서식기를 직접 돌려 그립니다.

<Preview demo="formatter/samples" />

| 서식기 | 하는 일 |
| --- | --- |
| `integerOnly(min:, max:)` | 정수로 읽히는 글자를 받습니다. 읽을 수 없으면 이전 글자로 되돌리고, 범위를 벗어난 수는 경계값으로 바꿉니다. 앞의 `0` 은 지웁니다(`007` → `7`). 글자가 `-` 하나뿐이면 남기되, `min` 이 0 이상이면 받지 않습니다. 빈 칸은 그대로 둡니다. |
| `decimalOnly(decimalDigits:, min:, max:)` | 소수를 받습니다. `decimalDigits` 를 넘는 자리는 반올림하지 않고 버립니다. `decimalDigits: 0` 이면 소수점을 받지 않고, 두 번째 소수점은 늘 거절합니다. 치는 도중의 `-` · `.` · `-.` 은 설정이 받을 수 있으면 남깁니다. 범위 안의 글자는 친 그대로 두어 `1.50` 이 유지됩니다. 범위를 벗어나면 경계값으로 바꾸는데, `decimalDigits` 가 있으면 그 자릿수로(`10.00`), 없으면 뒤의 0 을 지워 적습니다. |
| `toUpperCase()` · `toLowerCase()` | 대문자 · 소문자로 바꿉니다. |
| `time(length:)` | 길이를 `length` 로 맞춥니다. 짧으면 앞을 `0` 으로 채우고, 길면 앞 글자를 버려 뒤의 `length` 글자를 남깁니다. 숫자인지 시각인지는 확인하지 않고 `:` 도 넣지 않습니다(`ab` 는 `length: 4` 에서 `00ab`). 직접 지워 빈 글자가 되면 `0` 이 `length` 개 채워집니다. TextField 의 지우기 버튼(`CoreInputFeature.clear`)은 서식기를 거치지 않아 칸이 비워집니다. |
| `mathExpression(context:)` | 글자를 식으로 읽어 계산 결과로 바꿉니다. 식을 읽을 수 없거나(`1+`) 결과가 수가 아니면(`abc`) 빈 글자가 됩니다. 소수 결과의 끝 `0` 은 지웁니다. `context` 는 식에서 이름으로 쓸 값입니다. |
| `allow(pattern)` | 정규식에 맞는 글자만 남깁니다. 글자를 **하나씩** 대조하므로 `r'\d{3}'` 처럼 여러 글자에 맞는 패턴은 모든 글자를 지웁니다. `TextInputFormatters` 에서는 Flutter 만 제공합니다. |
| `phoneText()` | 숫자와 맨 앞의 `+` 하나만 남깁니다. 남는 글자 가운데 맨 앞이면 되므로 `(+82) 10` 은 `+8210` 이 됩니다. `TextInputFormatters` 에서는 Flutter 만 제공합니다. |

<Note>

`mathExpression` 은 `submitFormatters` 에 답니다. `inputFormatters` 에 달면 식을 다 치기 전의 `1+` 를 계산할 수 없어, `+` 를 치는 순간 칸이 비워집니다.

</Note>

### 직접 만드는 서식기

`CoreInputFormatter` 를 상속해 `format(oldValue, newValue)` 를 구현하면 두 플랫폼이 같은 규칙을 씁니다. Flutter 는 `InputFormatter` 로 감싸 넘기고, Web 은 그대로 넘깁니다. `inputFormatters` 에서 `oldValue` 를 돌려주면 이번 수정을 거절합니다.

<Code language="dart" title="두 플랫폼이 함께 쓰는 규칙">
class NoSpaceFormatter extends CoreInputFormatter {
  const NoSpaceFormatter();

  @override
  String format(String oldValue, String newValue) => newValue.replaceAll(' ', '');
}
</Code>

<Split>

<Code language="dart" title="Flutter">
TextField(inputFormatters: const [InputFormatter(NoSpaceFormatter())])
</Code>

<Code language="dart" title="Jaspr Web">
TextField(inputFormatters: const [NoSpaceFormatter()])
</Code>

</Split>

Flutter 의 TextField 는 Flutter 의 `TextInputFormatter` 를 받으므로, `package:flutter/services.dart` 의 `FilteringTextInputFormatter` 같은 서식기도 같은 목록에 넣을 수 있습니다.

<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

입력창의 글자를 치는 동안이나 제출할 때 바로 고쳐야 할 때 씁니다. 입력창 모양은 그대로 두고 글자만 바꿉니다. 서식기는 검증 메시지를 만들지 않습니다. 빈 칸이나 치다 만 `-` 도 남을 수 있으므로 필수 입력과 업무 규칙은 따로 확인합니다. TextField 는 [Form](/components/form) 안의 [FormField](/components/form-field) `validator` 로 확인합니다. TextArea 는 FormField 에 값을 알리지 않으므로 `onChanged` 로 받아 직접 검사하고, 오류 문구를 FormField 의 `error` 에 넘깁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 구분자(`-` · `/` · 괄호)를 치는 동안 끼워 보여야 할 때 | [FormattedInput](/components/formatted-input) |
| 범위 안의 수를 증감 버튼과 함께 받거나, 하한 때문에 치던 앞부분이 바뀔 때(`integerOnly` 는 `2` 이상의 하한, `decimalOnly` 는 `0` 보다 크고 `1` 이 아닌 하한) | [NumberInput](/components/number-input). 직접 친 범위 밖의 수는 입력창을 벗어나거나 제출할 때 범위 안으로 맞춥니다. |
| 글자를 고치지 않고 범위를 벗어난 것만 알려야 할 때 | TextField 의 `min` · `max`. 범위를 벗어나면 오류 모양이 됩니다. |
| 필수 입력 · 업무 규칙처럼 메시지가 필요한 검사 | TextField 는 [Form](/components/form) 안의 [FormField](/components/form-field) `validator`. TextArea 는 `onChanged` 로 직접 검사해 FormField 의 `error` 에 넘깁니다. |

<a id="do"></a>
<a id="dont"></a>

### 범위 · 계산 · Web 팩토리

<Cards columns="2">
<Card tone="do" eyebrow="이렇게 하세요">

하한이 `0` 인 범위는 `min` · `max` 로 맞춥니다. `130` 을 치면 `120` 이 됩니다.

```dart
inputFormatters: [
  TextInputFormatters.integerOnly(
    min: 0,
    max: 120,
  ),
]
```

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

치는 동안 맞추는 범위에 `2` 이상의 하한을 두지 않습니다. `min: 14` 에서는 `2` 를 치는 순간 `14` 가 되어 `20` 을 칠 수 없습니다.

```dart
inputFormatters: [
  TextInputFormatters.integerOnly(
    min: 14,
  ),
]
```

</Card>
<Card tone="do" eyebrow="이렇게 하세요">

계산식은 제출할 때 계산합니다.

```dart
submitFormatters: [
  TextInputFormatters
      .mathExpression(),
]
```

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

치는 동안 계산하지 않습니다. `+` 를 치는 순간 칸이 비워집니다.

```dart
inputFormatters: [
  TextInputFormatters
      .mathExpression(),
]
```

</Card>
<Card tone="do" eyebrow="이렇게 하세요">

Web 에서 `allow` · `phoneText` 가 필요하면 `CoreInputFormatters` 를 씁니다.

```dart
CoreInputFormatters.allow(
  r'[0-9]',
)
```

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

Web 의 `TextInputFormatters` 에는 `allow` 가 없어 컴파일되지 않습니다.

```dart
TextInputFormatters.allow(
  r'[0-9]',
)
```

</Card>
</Cards>

<a id="접근성-accessibility"></a>

## 접근성

Formatter 는 아무것도 그리지 않습니다. `TextInputFormatters` 도 Flutter 의 `InputFormatter` 도 위젯이나 컴포넌트가 아니라서, 역할을 실을 요소도 시맨틱 노드도 없습니다. 여기서는 서식기가 입력창에 주는 영향을 적습니다. 전 컴포넌트에 공통인 축은 [전역 접근성 축](/accessibility)을 보세요.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 없습니다. `Semantics` 를 만들지 않습니다. |
| Jaspr Web | 없습니다. 팩토리는 `CoreInputFormatter` 를 돌려줄 뿐이라 `role` · `aria-*` 를 붙일 요소가 없습니다. |

접근성 트리에 나타나는 것은 서식기를 단 입력창이고, 역할은 그 입력창이 정합니다.

### 키보드

서식기는 키 입력을 직접 듣지 않습니다. 입력창이 넘기는 글자를 받아 고친 글자를 돌려줍니다. 치는 동안 Flutter 에서는 프레임워크가 `formatEditUpdate(oldValue, newValue)` 를, Web 에서는 입력창이 `input` 이벤트에서 `format(old, new)` 를 목록 순서대로 부릅니다.

| 상황 | 도는 서식기 |
| --- | --- |
| 글자 입력 · 붙여넣기 | `inputFormatters` |
| Enter 로 제출 | `submitFormatters`. Web 은 IME 로 조합 중인 글자를 확정하는 Enter 에는 돌리지 않습니다. |

### 스크린 리더

서식기가 직접 읽히는 것은 없습니다. 글자를 다시 쓰면 달라지는 것은 입력창의 값입니다. 서식기는 라이브 리전이나 상태 알림을 내지 않고, 글자를 버렸거나 바꿨다는 안내도 하지 않습니다.

<Note>

받는 글자와 범위는 라벨이나 도움말로 미리 알려 줍니다. 라벨 · 도움말이 보조 기술에 어디까지 닿는지는 [TextField 의 접근성](/components/text-field#접근성)을 보세요.

</Note>

### 포커스 관리

없음. 서식기는 포커스를 받는 요소를 만들지 않습니다. Flutter 에는 `FocusNode` 가 없고 Web 에는 `tabindex` 를 붙일 요소가 없습니다. 포커스는 처음부터 끝까지 입력창에 있습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 글자를 버리거나 바꿔도 알리지 않습니다. 스크린 리더 사용자는 친 글자가 버려진 것을 안내받지 못합니다. 입력 규칙은 입력창 쪽에서 알려야 합니다. 글자가 버려진 순간까지 알려야 하면 입력창 쪽에 라이브 리전을 직접 둡니다. |
| 공통 | `integerOnly` · `decimalOnly` 는 글자가 바뀔 때마다 범위를 적용합니다. 치는 도중의 앞부분이 `min` 보다 작으면 바로 `min` 으로 바뀝니다. 그래서 `integerOnly(min: 14)` 에서는 `20` 을, `decimalOnly(min: 0.5)` 에서는 `0.7` 을 차례로 칠 수 없습니다. 한 자리 하한도 같아서 `integerOnly(min: 5)` 에 `10` 을 차례로 치면 `50` 이 됩니다. `max` 가 음수이면 `max` 보다 큰 앞부분이 바로 `max` 로 바뀌어, `integerOnly(max: -10)` 에서는 `-20` 을 차례로 칠 수 없습니다. |
| 공통 | `mathExpression` 은 `Exception` 만 빈 글자로 바꿉니다. 계산 중에 난 `Error` 는 잡지 않으므로, `context` 에 없는 이름을 계산에 쓴 식(`1+x`)은 빈 글자가 되지 않고 오류를 냅니다. |
| Flutter | `InputFormatter` 는 글자를 다시 쓸 때 커서가 몇 번째 글자 뒤인지를 새 길이 안으로만 맞춥니다. 글자를 앞에 붙이거나 중간에서 버리면 커서가 원래 자리와 어긋납니다. `time` 은 빈 칸에서 시작하면 친 순서가 섞입니다. 코드를 따라 계산하면 `time(length: 2)` 에 `5`, `3` 을 차례로 칠 때 `35` 가 됩니다(Web 은 `53`). |
| Flutter | `InputFormatter` 가 글자를 다시 쓰면 IME 조합 범위가 남지 않습니다. |
| Jaspr Web | 서식기가 글자를 바꾸면 그 값을 `<input>` · `<textarea>` 에 바로 써서 커서가 끝으로 갑니다. 이미 친 값의 중간을 고칠 때마다 커서가 끝으로 튀어, 키보드나 스크린 리더로 앞부분을 고치기 어렵습니다. 커서 위치를 정하는 속성은 없습니다. |
| Jaspr Web | 입력 이벤트마다 서식기를 돌리고 IME 조합 중인지 가리지 않습니다. 조합 중인 글자를 버리거나 바꾸는 서식기를 달면 한글 입력이 끊길 수 있습니다. |
| Jaspr Web | `TextInputFormatters` 에 `allow` · `phoneText` 가 없습니다. 의도한 플랫폼 차이가 아니라 Web 쪽 팩토리가 빠진 상태이며, 같은 규칙은 `CoreInputFormatters` 에서 씁니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

클래스 이름 `TextInputFormatters` 와 공통 팩토리 여섯(`integerOnly` · `decimalOnly` · `toUpperCase` · `toLowerCase` · `time` · `mathExpression`)은 두 플랫폼이 같습니다. 돌려주는 타입과 글자를 다시 쓰는 방식은 각 플랫폼을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `TextInputFormatters` 의 팩토리 | 공통 여섯에 `allow` · `phoneText` 를 더한 여덟 | 공통 여섯. `allow` · `phoneText` 는 `CoreInputFormatters` 에 있습니다. |
| 돌려주는 타입 | Flutter 의 `TextInputFormatter`(`InputFormatter` 가 공통 규칙을 감쌉니다) | `CoreInputFormatter` |
| 서식기가 받는 값 | `TextEditingValue`. 글자를 고치고 선택 범위를 새 길이 안으로 맞춥니다. | 이전 · 새 문자열 |
| 수정을 거절해 글자가 이전 그대로일 때 `onChanged` | 부르지 않습니다. | 이전 글자로 부릅니다. |
| 글자를 바꾼 뒤 커서 | 같은 글자 번호를 새 길이 안으로 맞춥니다. | 브라우저가 끝으로 옮깁니다. |
| `submitFormatters` 가 도는 때 | `onSubmitted` 를 부를 때 | Enter 키. 조합을 확정하는 Enter 는 뺍니다. |
| `maxLength` 를 함께 줄 때 | 서식기를 돌린 다음에 길이를 제한합니다. | 네이티브 `maxlength` 속성이라 브라우저가 서식기보다 먼저 입력을 막습니다. |
| 직접 만든 서식기 | `InputFormatter` 로 감쌉니다. | `CoreInputFormatter` 를 그대로 넘깁니다. |

<a id="props"></a>
<a id="props-parameters"></a>

## API

`TextInputFormatters` 는 인스턴스를 만들지 않는 클래스라 생성자가 없습니다. 팩토리가 돌려준 값을 입력창의 서식기 목록에 넣습니다. 서식기에는 콜백과 비활성 상태가 없고, 비활성은 입력창이 정합니다.

### `TextInputFormatters` 팩토리

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `integerOnly` | `({int? min, int? max})` | 모두 `null` | 정수만 받고, 범위를 벗어난 수는 경계값으로 바꿉니다. |
| `decimalOnly` | `({int? decimalDigits, double? min, double? max})` | 모두 `null` | 소수를 받고 소수점 아래 자릿수와 범위를 제한합니다. |
| `toUpperCase` | `()` | — | 대문자로 바꿉니다. |
| `toLowerCase` | `()` | — | 소문자로 바꿉니다. |
| `time` | `({required int length})` | 필수 | 길이를 맞추고 앞을 `0` 으로 채웁니다. |
| `mathExpression` | `({Map<String, Object?>? context})` | `null` | 식을 계산한 결과로 바꿉니다. |
| `allow` | `(String pattern)` | 필수 | 정규식에 맞는 글자만 남깁니다. Flutter 전용입니다. |
| `phoneText` | `()` | — | 숫자와 맨 앞의 `+` 만 남깁니다. Flutter 전용입니다. |

### 팩토리 인자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `min` | `int?` · `double?` | `null` | `integerOnly`(`int?`) · `decimalOnly`(`double?`) 의 하한. 그 값도 범위에 듭니다. |
| `max` | `int?` · `double?` | `null` | 상한. 그 값도 범위에 듭니다. |
| `decimalDigits` | `int?` | `null` | `decimalOnly` 의 소수점 아래 최대 자릿수 |
| `length` | `int` | 필수 | `time` 이 맞추는 길이 |
| `context` | `Map<String, Object?>?` | `null` | `mathExpression` 의 식에서 이름으로 쓸 값 |
| `pattern` | `String` | 필수 | `allow` 가 글자마다 대조하는 정규식 원문 |

### `InputFormatter` (Flutter 전용)

공통 규칙을 Flutter 의 `TextInputFormatter` 로 감쌉니다. `InputFormatter(formatter)` 로 만듭니다. 넘기는 규칙이 상수면 `const` 를 붙일 수 있습니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `formatter` | `CoreInputFormatter` | 필수 | 감쌀 규칙. 위치 인자입니다. |

### `CoreInputFormatter`

직접 만드는 서식기의 바탕 클래스입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `format` | `String format(String oldValue, String newValue)` | — | 구현하는 규칙. 이전 글자와 새 글자를 받아 쓸 글자를 돌려줍니다. |
| `formatInitial` | `String formatInitial(String value)` | — | 이전 글자를 빈 문자열로 두고 `format` 을 부릅니다. |

`CoreInputFormatters` 는 위 팩토리 여덟을 모두 가진 두 플랫폼 공통 클래스이고, `CoreInputFormatter` 를 돌려줍니다.

### 입력창의 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `inputFormatters` | `List<TextInputFormatter>?` (Web `List<CoreInputFormatter>?`) | `null` | TextField · TextArea. 글자가 바뀔 때 돕니다. |
| `submitFormatters` | `List<TextInputFormatter>?` (Web `List<CoreInputFormatter>`) | `const []` | TextField. 제출할 때 돕니다. |

## 관련 컴포넌트

<Cards columns="3">
<Card demo="formatter/related-text-field" title="TextField">

서식기를 받는 한 줄 입력창입니다.

</Card>
<Card demo="formatter/related-formatted-input" title="FormattedInput">

구분자가 있는 형식을 마스크로 받습니다.

</Card>
<Card demo="formatter/related-number-input" title="NumberInput">

버튼으로 올리고 내리는 숫자 입력입니다.

</Card>
</Cards>
