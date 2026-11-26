---
title: FormattedInput
description: 전화번호 · 카드 번호 · 날짜처럼 형식이 정해진 값을 받는 입력창입니다. 구분자는 치는 동안 저절로 끼워집니다.
category: form
platforms: [flutter, web]
related: [text-field, input-otp, form-field]
tags: [interactive, form-control, masked-input]
template: v2
source: form/formatted_input
---

# FormattedInput

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

마스크를 바꿔 보며 FormattedInput 을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="formatted-input" />

FormattedInput 은 구분자와 편집 자리가 정해진 값을 받습니다. 마스크는 `parts` 로 정하지만 화면에는 **실제 입력창 하나**만 그립니다 — 치는 동안 구분자(`-` · `/` · 괄호)가 저절로 끼워지고, `onChanged` 는 구분자를 뺀 값을 받습니다. 플레이그라운드의 custom 은 기본 마스크가 없는 사업자등록번호(`___-__-_____`)를 `parts` 로 만든 예입니다.

## 구조

입력창은 상자, 앞 요소, 입력, 뒤 요소로 이루어집니다. 앞뒤 요소는 넣을 때만 그립니다.

<Anatomy demo="formatted-input/anatomy">
<AnatomyItem part="container" side="left" name="Container">

테두리와 채움. 상태에 따라 테두리 색이 바뀝니다. 상자는 마스크를 몇 부분으로 나누든 하나입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=leading]" side="top" name="leading">

입력 앞에 놓는 위젯. 아이콘이나 짧은 글자를 넣습니다.

</AnatomyItem>
<AnatomyItem select="input" side="top" name="field">

마스크가 들어가는 입력창 하나. 구분자도 이 입력창 글자의 일부이고, 구분자만 따로 지울 수는 없습니다. 비어 있으면 마스크 모양을 자리 표시로 보여 줍니다.

</AnatomyItem>
<AnatomyItem select="button" side="right" name="trailing">

입력 뒤에 놓는 위젯. 인증번호 보내기 같은 버튼을 넣습니다.

</AnatomyItem>
</Anatomy>

## 마스크

마스크는 `CoreFormattedInputPart` 의 목록입니다. 편집 자리 `CoreFormattedInputPart.editable(length:, pattern:, placeholder:)` 는 글자 `length` 개를 받고, 구분자 `CoreFormattedInputPart.static(text)` 는 정해진 글자를 그립니다. 몇 부분으로 나누든 입력창은 하나이고, 자리를 옮겨 다니는 포커스 이동은 없습니다.

<Preview demo="formatted-input/masks" />

<a id="한국-휴대폰-프리셋"></a>

### 기본 마스크

흔한 모양은 생성자로 바로 씁니다. 숫자만 받는 자리와 알맞은 자동 완성 힌트가 함께 오므로, 같은 모양을 `parts` 로 다시 만들 때 흔한 실수(패턴 누락, 길이 오류, 힌트 누락)를 피할 수 있습니다.

| 생성자 | 모양 | 값 → 보이는 값 |
| --- | --- | --- |
| `FormattedInput.koreanPhone` | `___-____-____` (3-4-4) | `01012345678` → `010-1234-5678` |
| `FormattedInput.phone` | `(___) ___-____` | `5551234567` → `(555) 123-4567` |
| `FormattedInput.creditCard` | `____ ____ ____ ____` | `4111111111111111` → `4111 1111 1111 1111` |
| `FormattedInput.date` | `__/__/____` | `12252026` → `12/25/2026` |

네 마스크의 편집 자리는 모두 숫자(`\d`)만 받습니다. 같은 목록은 `CoreFormattedInputMasks.koreanPhone` 처럼 따로 쓸 수 있습니다. `.koreanPhone` 은 11자리 휴대폰 번호 모양이라, 지역 번호 길이가 다른 유선 전화번호는 맞지 않습니다.

### 직접 만드는 마스크

기본 마스크가 없는 모양은 `parts` 를 직접 줍니다.

```dart
// 사업자등록번호 ___-__-_____
FormattedInput(
  parts: const [
    CoreFormattedInputPart.editable(length: 3, pattern: r'\d'),
    CoreFormattedInputPart.static('-'),
    CoreFormattedInputPart.editable(length: 2, pattern: r'\d'),
    CoreFormattedInputPart.static('-'),
    CoreFormattedInputPart.editable(length: 5, pattern: r'\d'),
  ],
  onChanged: setBusinessNumber,
)
```

- `pattern` 은 글자 하나에 맞춰 보는 정규식 원문입니다(`r'\d'`). 지정하지 않은 자리는 마스크의 구분자 글자가 아닌 모든 글자를 받습니다.
- 빈 자리는 `placeholder` 글자(기본 `_`)로 자리 표시에 그립니다.
- 마스크는 모양만 맞춥니다. `.date` 에는 `99/99/9999` 도 들어갑니다 — 날짜가 맞는지는 `onChanged` 로 받은 값을 직접 검사합니다.

<Note>

받을 글자는 자리마다가 아니라 마스크 전체로 거릅니다. 어느 편집 자리의 `pattern` 에든 맞는 글자는 받고, 받은 글자는 앞 자리부터 차례로 채웁니다. 숫자 자리와 글자 자리를 섞은 마스크에서는 글자 자리에 숫자가 들어갈 수 있습니다.

</Note>

<a id="동작-스펙-behavior"></a>

## 상태

입력창은 아래 표의 다섯 모습을 가집니다. 장면은 빈 칸 · 입력 중 · 다 채움 · Focus · 비활성 입력창을 나란히 그리고, Hover 는 무대의 입력창에 포인터를 올려 봅니다. 장면의 Focus 칸은 포커스 테두리 색을 쉬는 테두리와 Hover 테두리에 고정해 그렸습니다.

<Preview demo="formatted-input/states" />

| 항목 | 동작 |
| --- | --- |
| 쉴 때 | 테두리 `outlineVariant`, 채움 `surface`. 비어 있으면 마스크 모양(`___-____-____`)을 자리 표시로 보여 줍니다. |
| 입력 중 | 친 만큼만 보입니다. 구분자는 그 뒤 자리에 첫 글자를 쳤을 때 붙고, 아직 치지 않은 자리와 그 뒤의 구분자는 그리지 않습니다. |
| Hover | 테두리가 `outline` 으로 한 단 진해집니다. 포커스가 있거나 비활성일 때는 바뀌지 않습니다. |
| Focus | 테두리가 `primary` 로 바뀝니다. 바깥 링은 그리지 않고, 키보드로 들어왔는지 포인터로 눌렀는지를 가리지 않습니다. 테두리 굵기는 그대로라 상자 크기가 변하지 않습니다. |
| 비활성 | 채움 `disabledContainer`, 테두리 `disabledOutline`, 값과 자리 표시 `disabledContent`. 불투명도로 흐리게 하지 않습니다. 포커스를 받지 않고 값을 바꿀 수 없습니다. |

겹치면 비활성이 Focus 를, Focus 가 Hover 를 이깁니다. FormattedInput 자신에는 오류 모양이 없습니다 — 오류 문구가 필요하면 [FormField](/components/form-field) 로 감싸 `error` 로 보여 줍니다.

<a id="인터랙션"></a>

## 입력 동작

치는 동안 같은 마스크 엔진(`CoreFormattedInputMaskEngine`)이 두 플랫폼에서 값을 다시 맞춥니다.

| 친 글자 | 보이는 값 | `onChanged` 가 받는 값 |
| --- | --- | --- |
| `010` | `010` | `010` |
| `0101` | `010-1` | `0101` |
| `01012345678` | `010-1234-5678` | `01012345678` |

- **구분자를 넘는 Backspace**: 캐럿이 구분자 바로 뒤에 있어도 Backspace 는 구분자가 아니라 그 앞 숫자를 지웁니다. 지운 자리 뒤의 글자는 앞으로 당겨집니다.
- **붙여넣기 · 중간 편집**: 붙이거나 중간에 넣은 글자에서 받을 수 있는 글자만 골라 한 번에 다시 맞춥니다. `010-1234-5678` 을 붙이든 `01012345678` 을 붙이든 같은 값이 됩니다.
- **넘치는 글자**: 편집 자리 수를 넘는 글자는 버립니다.
- **`onChanged`**: 구분자를 뺀 값을 받습니다. 화면에 보이는 문자열이 아닙니다. 받을 수 없는 글자를 쳐서 값이 그대로여도 한 번 불립니다.
- **`value`**: 처음 값입니다. 바깥에서 다른 값을 넘기면 그 값을 같은 엔진으로 맞춰 보여 줍니다. 이때는 `onChanged` 가 불리지 않습니다. `value` 는 걸러지지 않습니다 — 구분자가 든 값(`010-1234-5678`)이나 `pattern` 에 맞지 않는 글자를 넘기면 그 글자가 그대로 자리에 들어가 모양이 깨집니다(`010--123-4-56`). 편집 자리 글자만 이어 붙여 넘깁니다.

<Note>

`parts` 를 바꾸는 화면에서는 `key` 도 함께 바꿉니다. 부분 수가 같은 마스크로 바꾸면(`koreanPhone` 과 `date` 는 둘 다 다섯 부분) 보이는 값이 새 마스크로 다시 맞춰지지 않습니다.

</Note>

<a id="자동완성-autofill"></a>

## 자동 완성

입력창이 하나라 브라우저 · OS 의 자동 완성과 비밀번호 관리자 확장이 일반 입력창처럼 찾아서 채웁니다. 채운 값도 같은 엔진으로 맞춰집니다. `autofillHints` 는 `TextField.autofillHints` 와 같은 이름 · 같은 타입이고, 값은 그 플랫폼의 말을 씁니다.

| 생성자 | Flutter | Jaspr Web |
| --- | --- | --- |
| `.koreanPhone` · `.phone` | `[AutofillHints.telephoneNumber]` | `['tel']` |
| `.creditCard` | `[AutofillHints.creditCardNumber]` | `['cc-number']` |
| `.date` · `parts` 로 만든 마스크 | 없음 | 없음 |

직접 만든 마스크나 `.date` 는 `autofillHints` 를 직접 줍니다. Web 은 여러 값을 공백으로 이어 `<input>` 의 `autocomplete` 속성에 쓰고, 값이 없으면 속성을 붙이지 않습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 형식 없이 자유롭게 입력받을 때 | [TextField](/components/text-field) |
| 국가를 고르고 그 나라의 번호를 받을 때 | [PhoneInput](/components/phone-input) |
| 문자열 하나 대신 이름 붙은 구간마다 값을 받을 때 | [ObjectInput](/components/object-input) |
| 고정 길이 인증 코드를 받고 다 치면 알려야 할 때 | [InputOtp](/components/input-otp) |
| 시간을 고르는 화면이 필요할 때 | [TimePicker](/components/time-picker) |
| 입력창 모양 없이 입력 글자만 바꿀 때 | [Formatter](/components/formatter) |

<a id="do"></a>
<a id="dont"></a>

### 라벨과 날짜 순서

<Cards columns="2">
<Card demo="formatted-input/do-form-field" tone="do" eyebrow="이렇게 하세요">

FormField 로 라벨과 도움말을 붙입니다.

</Card>
<Card demo="formatted-input/dont-bare-mask" tone="dont" eyebrow="이렇게 하지 마세요">

라벨 없이 마스크만 두지 않습니다. 밑줄로 된 자리 표시는 무엇을 입력하는지 말해 주지 못합니다.

</Card>
<Card demo="formatted-input/do-iso-date" tone="do" eyebrow="이렇게 하세요">

연-월-일로 쓰는 화면은 그 순서의 마스크를 `parts` 로 만듭니다.

</Card>
<Card demo="formatted-input/dont-us-date" tone="dont" eyebrow="이렇게 하지 마세요">

`.date` 는 마지막 자리가 네 자리라 연도가 끝에 옵니다. 연도부터 치면 `20/26/1225` 가 됩니다.

</Card>
</Cards>

<a id="조합-예제"></a>

### 라벨은 FormField 로

FormattedInput 에는 라벨 · 도움말 · 오류 문구가 없습니다. 필요하면 컴포넌트를 늘리지 않고 [FormField](/components/form-field) 로 감쌉니다 — 라벨과 도움말이 그려지고, 두 플랫폼 모두 그 묶음에 이름과 설명이 붙습니다.

```dart
FormField(
  label: '휴대폰 번호',
  description: '인증번호를 받을 번호를 입력하세요.',
  required: true,
  child: FormattedInput.koreanPhone(
    onChanged: setPhone,
  ),
)
```

<Note>

FormField 의 `validator` 는 이 값을 받지 않습니다 — FormattedInput 은 감싼 FormField 에 값을 보고하지 않습니다. `onChanged` 로 받은 값을 직접 검사해 FormField 의 `error` 로 넘깁니다.

</Note>

<a id="폭"></a>

## 배치

- 입력창은 **부모가 준 폭을 채웁니다.** Flutter 와 Web 이 같고, TextField · Autocomplete 같은 다른 입력창과도 같습니다. `leading` · `trailing` 이 있으면 입력은 그 둘이 남긴 폭을 채웁니다.
- 폭을 줄이려면 **부모에 폭을 줍니다** — Flutter 는 `SizedBox` · `ConstrainedBox`, Web 은 감싼 요소의 폭(또는 `css`)입니다. 루트에 `classes: 'w-64'` 를 얹는 방식은 입력창이 이미 가진 `w-full` 과 겹쳐 이기지 못할 수 있습니다.
- Flutter 에서 폭이 정해지지 않은 `Row` 에 그대로 넣으면 TextField 와 마찬가지로 예외가 납니다 — `Expanded` 나 `SizedBox` 로 폭을 줍니다.

<a id="leading-trailing-조합-인증번호-발송-버튼"></a>

### 입력창 안의 버튼

`trailing` 에 버튼을 넣으면 "입력창 + 버튼" 을 따로 줄을 나누지 않고 한 컨트롤로 묶습니다. 전화번호 인증 화면이 그렇습니다.

<Preview demo="formatted-input/trailing-action" />

```dart
FormattedInput.koreanPhone(
  onChanged: setPhone,
  trailing: Button(
    variant: CoreButtonVariant.plain,
    size: CoreComponentSize.sm,
    onPressed: sendCode,
    child: Text('인증번호 보내기'),
  ),
)
```

`leading` · 입력 · `trailing` 사이는 8 떨어집니다(`contentSpacing`). `trailing` 의 버튼은 입력과 따로 포커스를 받아, 입력 다음의 Tab 정지점이 됩니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

보이는 값은 `formattedInputStyle`(`CoreFormattedInputStyle`) 하나로 덮어씁니다. 상자는 하나라 칸마다 간격이나 폭을 정하는 값은 없고, 구분자는 입력창 글자의 일부라 따로 색 · 글자를 갖지 않습니다. 안쪽 입력의 모양과 값 · 자리 표시 글자는 `segmentInputStyle`(`CoreTextFieldStyle`) 로 바꿉니다.

<Split>

<Code language="dart" title="FormattedInput 하나만 바꾸기">
FormattedInput.koreanPhone(
  onChanged: setPhone,
  formattedInputStyle: CoreFormattedInputStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    segmentInputStyle: CoreTextFieldStyle(
      textAlign: CoreTextAlign.start,
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    formattedInput: CoreFormattedInputTheme(
      style: CoreFormattedInputStyle(
        height: CoreControlSize.heightMd,
      ),
    ),
  ),
)
</Code>

</Split>

<a id="상자"></a>

### 기본 모양

| 항목 | 값 |
| --- | --- |
| 높이 | 48 — 컨트롤 높이 사다리의 `lg` 행이라 TextField `lg` 와 한 줄에 놓입니다. 앱의 밀도를 따라 한 칸 움직이고, 직접 적은 `height` 는 그대로입니다. |
| 모서리 | 12 |
| 여백 | 좌우 14, 위아래 0 — 높이가 줄을 가운데에 둡니다. |
| 간격 | `leading` · 입력 · `trailing` 사이 8 |
| 테두리 | 1 |
| 값 글자 | `codeMd` 역할(13 · 줄 높이 21 · 고정폭), 가운데 정렬 |
| 자리 표시 글자 | `bodySmall` 역할(13) |

Flutter 의 안쪽 입력은 `plain` 변형의 `lg` TextField 이고, 기본 `segmentInputStyle` 이 그 채움을 비우고 테두리 굵기 · 여백 · 최소 높이를 0 으로 둡니다. 안쪽 포커스 링도 기본 `segmentInputStyle` 이 꺼 둡니다(`focusOutlineStyle` 을 투명하게, 굵기를 0 으로) — `segmentInputStyle` 로 `focusOutlineStyle` 을 다시 주면 Flutter 에서만 안쪽 링이 되살아납니다. Web 은 테두리 없는 투명한 `<input>` 이고 브라우저의 포커스 윤곽선을 늘 끕니다. 그래서 두 플랫폼 모두 상자 안에 상자가 생기지 않습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `FormattedInput` 에 `withStyle` 을 이어 쓰면 생성자의 `formattedInputStyle` 과 같게 동작합니다. `.radius12` · `.primary` 처럼 Core 토큰과 같은 이름의 짧은 이름도 있습니다 — 반경 이름은 `borderRadius` 를, 색 이름은 채움(`backgroundColor`)을 바꿉니다. 이름이 곧 값이라(`radius12` 는 `CoreRadius.radius12`) 어느 컴포넌트에서 써도 뜻이 같습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class FormattedInputChainExample extends StatelessWidget {
  const FormattedInputChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        FormattedInput.phone(
          onChanged: (value) => debugPrint('Phone: $value'),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        FormattedInput.phone(
          onChanged: (value) => debugPrint('Phone: $value'),
        ).withStyle(
          const CoreFormattedInputStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class FormattedInputChainExample extends StatelessComponent {
  const FormattedInputChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        FormattedInput.phone(
          onChanged: (value) => print('Phone: $value'),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        FormattedInput.phone(
          onChanged: (value) => print('Phone: $value'),
        ).withStyle(
          const CoreFormattedInputStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

### 값이 정해지는 순서

```text
기본값 (CoreFormattedInputStyle.default*)
  → CoreComponentTheme.formattedInput.style    // 앱 전체
  → formattedInputStyle                         // 인스턴스
```

뒤로 갈수록 우선합니다. variant 가 없어 `variantStyles` 는 없습니다. `segmentInputStyle` 은 `defaultSegmentInputStyle` 위에 얹혀 안쪽 입력에 넘어갑니다. Flutter 의 안쪽 TextField 는 앱의 TextField 테마를 먼저 받으므로, FormattedInput 이 정하지 않은 값(커서 색 같은)은 그 테마를 따릅니다. Web 의 `<input>` 은 TextField 가 아니라 그 테마를 받지 않습니다.

<a id="접근성-accessibility"></a>

## 접근성

편집 표면은 입력창 하나입니다 — Flutter 는 안쪽 TextField, Web 은 네이티브 `<input type="text">` 입니다. FormattedInput 자신은 역할도 이름도 더하지 않습니다. 전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타깃)은 [전역 접근성 축](/accessibility)에 있습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 안쪽 TextField 가 만드는 텍스트 필드 노드에 활성 상태와 포커스 동작이 붙습니다. FormattedInput 은 시맨틱을 더하지 않습니다. |
| Jaspr Web | 네이티브 `<input>` 의 역할(`textbox`)을 그대로 씁니다. 바깥 `<div>` 에는 역할이 없고, 생성자의 `attributes` 는 이 `<div>` 에 붙습니다. |

### 키보드

이 컴포넌트가 따로 묶는 키는 없습니다. 입력 · 캐럿 · 선택은 입력창의 기본 동작이고, 마스크 엔진이 입력 뒤에 값을 다시 맞출 뿐입니다.

| 키 | 동작 |
| --- | --- |
| 글자 · 숫자 | 다음 편집 자리에 들어갑니다. 그 앞이 구분자면 구분자를 먼저 붙입니다. 받을 수 없는 글자는 버립니다. |
| `Backspace` | 캐럿 앞 글자를 지웁니다. 캐럿 바로 앞이 구분자면 그 앞 숫자를 지웁니다. |
| 화살표 · `Home` · `End` | 입력창 안에서 캐럿을 옮깁니다. 마스크 안에 따로 멈추는 곳은 없습니다. |
| `Tab` · `Shift` · `Tab` | 다음 · 이전 요소로 옮깁니다. `trailing` 에 버튼이 있으면 입력 다음이 그 버튼입니다. |

### 스크린 리더

- 값은 구분자가 든 문자열 하나로 읽힙니다(`010-1234-5678`). 칸마다 따로 읽히지 않습니다.
- 비어 있으면 마스크 모양이 자리 표시로 갑니다 — Web 은 `placeholder` 속성, Flutter 는 `hintText` 입니다.
- FormattedInput 은 입력창에 이름을 붙이지 않습니다. [FormField](/components/form-field) 로 감싸면 라벨과 도움말이 그 묶음에 붙습니다(Flutter 는 라벨 · 힌트를 단 `Semantics`, Web 은 `role="group"` 의 `aria-labelledby` · `aria-describedby`). 입력창 자체가 아니라 둘러싼 묶음의 이름입니다.
- 값이 바뀐 사실을 알리는 라이브 리전은 없습니다.

Flutter 에서 입력창에 이름을 바로 주려면 바깥을 `Semantics` 로 감쌉니다.

```dart
Semantics(
  label: '휴대폰 번호',
  child: FormattedInput.koreanPhone(onChanged: setPhone),
)
```

### 포커스 관리

탭 정지점은 안쪽 입력 하나입니다. 바깥 상자는 포커스를 받지 않고, Web 은 `tabindex` 를 더하지 않아 네이티브 `<input>` 의 포커스를 그대로 씁니다. 포커스 표시는 상자 테두리 색이 바뀌는 것 하나입니다. 마운트될 때 포커스를 옮기지 않고, 포커스를 가두지도 되돌리지도 않습니다. 비활성이면 포커스를 받지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 입력창에 이름을 붙이는 속성(`label` · `semanticLabel`)이 없습니다. FormField 는 묶음에 이름을 붙일 뿐입니다. |
| Jaspr Web | 이름이 없으면 브라우저가 자리 표시(`___-____-____`)를 입력창의 이름으로 읽습니다. 생성자의 `attributes` 는 바깥 `<div>` 에 붙어 `<input>` 에 닿지 않으므로, 여기에 `aria-label` 을 넣어도 입력창의 이름이 되지 않습니다. 생성자의 `id` 도 바깥 `<div>` 의 것이고 `<input>` 의 id 는 컴포넌트가 정하므로, `<label for>` 로 입력창에 이름을 이을 수도 없습니다. |
| 공통 | `FormField(enabled: false)` · `Fieldset(enabled: false)` 로 감싸도 FormattedInput 은 비활성이 되지 않습니다 — Flutter 는 안쪽 입력만 막히고 상자는 활성 모양으로 남고, Web 은 그대로 입력됩니다. 비활성은 FormattedInput 의 `enabled` 로 줍니다. |
| 공통 | 키보드 포커스에도 바깥 링이 없고 테두리 색만 바뀝니다. Select 는 키보드로 포커스하면 바깥 링을 그립니다. |
| 공통 | `Form` · `FormField` 에 값을 보고하지 않습니다. FormField 의 `validator` 는 이 값을 받지 않습니다. |
| 공통 | 구분자 바로 앞에서 `Delete` 를 누르면 구분자 뒤 숫자가 아니라 캐럿 앞 숫자가 지워집니다. |
| 공통 | 받을 글자를 자리마다 가리지 않습니다 — 숫자 자리와 글자 자리를 섞은 마스크에서는 글자 자리에 숫자가 들어갈 수 있습니다. |
| 공통 | 부분 수가 같은 `parts` 로 바꾸면 보이는 값을 새 마스크로 다시 맞추지 않습니다. |
| 공통 | 바깥에서 넘긴 `value` 는 친 글자와 달리 걸러지지 않습니다 — 구분자나 `pattern` 에 맞지 않는 글자가 그대로 자리에 들어갑니다. |
| Flutter | 숫자만 받는 마스크에도 숫자 키패드를 띄우지 않고 글자 키보드를 엽니다. |
| Flutter | `value` 를 `null` 로 되돌려도 칸을 비우지 않습니다. 부분 수가 다른 마스크로 바꾸면서 `value` 도 함께 바꾸면, 새 `value` 대신 앞서 있던 값을 새 마스크에 맞춥니다. |
| Jaspr Web | 부분 수가 다른 `parts` 로 바꾸면 친 값이 아니라 `value` 로 다시 맞춥니다 — `value` 를 넘기지 않는 입력창은 칸이 비고, 이때 `onChanged` 는 불리지 않습니다. |
| Jaspr Web | `placeholder` 를 빈 글자로 준 편집 자리가 있으면 `maxlength` 가 마스크보다 짧아져 끝까지 칠 수 없습니다. |
| Jaspr Web | `segmentInputStyle.valueStyle` 로 값 글자의 역할을 바꿔도 값은 고정폭 서체로 그립니다. Flutter 는 바꾼 역할의 서체로 그립니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 입력창 | `plain` 변형 `lg` TextField 하나 | 네이티브 `<input type="text">` 하나 |
| 포커스 표시 | `FocusNode` 로 테두리 색을 바꿉니다 | `focus` · `blur` 이벤트로 테두리 색을 바꿉니다 |
| 숫자 키패드 | 띄우지 않습니다 | 모든 편집 자리가 `r'\d'` 면 `inputmode="numeric"` |
| 길이 제한 | 넘치는 글자를 엔진이 버립니다 | 같고, `maxlength` 를 마스크 전체 길이로 둡니다 — 다 찬 칸의 중간에는 더 칠 수 없습니다 |
| 자동 완성 값 | `AutofillHints.*` | HTML `autocomplete` 값(`tel` · `cc-number`) |
| `value` 를 `null` 로 | 칸을 그대로 둡니다 | 칸을 비웁니다 |
| 부분 수가 다른 마스크로 | 친 값을 새 마스크에 맞춥니다 | `value` 로 다시 맞춥니다(없으면 비웁니다) |
| `segmentInputStyle` | 안쪽 TextField 에 그대로 넘깁니다 | 채움 · 테두리 · 여백 · 정렬 · 값 글자 · 자리 표시 글자만 읽습니다(자리 표시는 역할과 색만). 값 글자는 역할을 바꿔도 고정폭 서체입니다. |
| 앱의 TextField 테마 | 안쪽 TextField 에 닿습니다 | 닿지 않습니다 |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `onClick` 등 (바깥 `<div>` 에 붙습니다) |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다.

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `parts` | `List<CoreFormattedInputPart>` | 필수 | 마스크. 마스크 생성자는 이 값을 정해 두고 받지 않습니다. |
| `value` | `String?` | `null` | 편집 자리만 이어 붙인 값(구분자 없음). 처음 값이고, 바깥에서 바꾸면 그 값으로 다시 맞춥니다. |
| `leading` | `Widget?` (Web `Component?`) | `null` | 입력 앞에 놓는 위젯 |
| `trailing` | `Widget?` (Web `Component?`) | `null` | 입력 뒤에 놓는 위젯 |

### 상태와 형태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `enabled` | `bool` | `true` | false 면 비활성. `onChanged` 유무와 상관없습니다. |
| `formattedInputStyle` | `CoreFormattedInputStyle?` | `null` | 보이는 값 덮어쓰기 |

### 콜백과 입력

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `onChanged` | `ValueChanged<String>?` (Web `CoreValueChanged<String>?`) | `null` | 구분자를 뺀 값을 받습니다. |
| `autofillHints` | `Iterable<String>?` | 생성자마다 다름 | 자동 완성 힌트. Flutter 는 `AutofillHints.*`, Web 은 HTML `autocomplete` 값 |

<a id="팩토리-생성자"></a>

### 마스크 생성자

입력 글자만 바꾸고 마스크 상자는 필요 없으면 [Formatter](/components/formatter) 를 씁니다.

| 생성자 | 마스크 | `autofillHints` 기본값 |
| --- | --- | --- |
| `FormattedInput.phone` | `CoreFormattedInputMasks.phone` — `(___) ___-____` | 전화번호 |
| `FormattedInput.koreanPhone` | `CoreFormattedInputMasks.koreanPhone` — `___-____-____` | 전화번호 |
| `FormattedInput.creditCard` | `CoreFormattedInputMasks.creditCard` — `____ ____ ____ ____` | 카드 번호 |
| `FormattedInput.date` | `CoreFormattedInputMasks.date` — `__/__/____` | 없음 |

### `CoreFormattedInputPart`

편집 자리는 `CoreFormattedInputPart.editable`, 구분자는 `CoreFormattedInputPart.static` 으로 만듭니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `length` | `int` | 필수 (`.editable`) | 편집 자리가 받는 글자 수 |
| `pattern` | `String?` | `null` | 받을 글자의 정규식 원문(`r'\d'`). 없으면 구분자 글자가 아닌 모든 글자 |
| `placeholder` | `String` | `'_'` | 빈 자리를 자리 표시에 그리는 글자 |
| `text` | `String?` | 필수 (`.static`) | 구분자가 그리는 글자 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreFormattedInputStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Container background colour override. |
| `borderColor` | `CoreColor?` | Container border colour override. |
| `hoverBorderColor` | `CoreColor?` | Container border colour override while the pointer is over the container. `null` → [defaultHoverBorderColor]. Never applied while the container is focused (the focus border wins) or disabled. |
| `disabledBackgroundColor` | `CoreColor?` | Container background colour while the field is disabled. `null` uses [defaultDisabledBackgroundColor]. |
| `disabledBorderColor` | `CoreColor?` | Container border colour while the field is disabled. `null` uses [defaultDisabledBorderColor]. |
| `disabledForegroundColor` | `CoreColor?` | Value / placeholder text colour while the field is disabled. `null` → [defaultDisabledForegroundColor]. |
| `focusBorderColor` | `CoreColor?` | Container focus-ring border colour override. |
| `borderRadius` | `CoreBorderRadius?` | Container border radius override. |
| `borderWidth` | `double?` | Container border width override (logical px). |
| `padding` | `CoreEdgeInsets?` | Container padding override. |
| `height` | `double?` | Container height override (logical px). `null` → [defaultHeight], which moves with the density; a stated height stays as stated. |
| `contentSpacing` | `double?` | Gap between the `leading` / field / `trailing` children override (logical px). `null` → [defaultContentSpacing]. |
| `segmentInputStyle` | `CoreTextFieldStyle?` | Style for the `TextField` the segments are typed into — its look plus the value / placeholder text. Laid over [defaultSegmentInputStyle] and passed to that one `TextField` on both platforms. |

<!-- STYLE_TABLE:END -->

<Note>

`focusBorderColor` 는 포커스 동안의 상자 테두리 색입니다 — 바깥 링은 그리지 않습니다. `segmentInputStyle` 은 Flutter 에서는 안쪽 TextField 에 그대로 넘어가지만, Web 에는 TextField 가 없어 그중 채움 · 테두리 색과 굵기 · 여백 · 정렬 · 값 글자 · 자리 표시 글자만 `<input>` 에 옮겨집니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card component="text-field" props="placeholder=이름을 입력하세요" title="TextField">

형식 없이 한 줄 텍스트를 입력받습니다.

</Card>
<Card demo="formatted-input/related-input-otp" title="InputOtp">

고정 길이 인증 코드를 칸마다 받습니다.

</Card>
<Card demo="formatted-input/related-form-field" title="FormField">

라벨 · 도움말 · 오류 문구가 필요하면 이 컴포넌트로 감쌉니다.

</Card>
</Cards>
