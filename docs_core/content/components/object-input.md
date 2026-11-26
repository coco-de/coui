---
title: ObjectInput
description: 연 · 월 · 일처럼 이름을 가진 칸 여러 개를 구분자로 이어 한 상자에서 입력받는 컴포넌트입니다. 칸마다의 값을 이름별로 받아야 할 때 씁니다.
category: form
platforms: [flutter, web]
related: [formatted-input, text-field]
tags: [interactive, form-control, structured-input]
template: v2
source: form/object_input
---

# ObjectInput

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

칸 묶음과 상태를 바꿔 보며 ObjectInput 을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="object-input" />

ObjectInput 은 `fields` 에 적은 칸을 한 상자 안에 차례로 놓습니다. 어느 칸이든 값이 바뀌면 `onChanged` 가 **모든 칸의 값**을 `Map<String, String>`(칸의 `key` → 값)으로 받습니다. 처음 값(`values`)이 없고 아직 치지 않은 칸은 빈 문자열입니다. 문자열 하나에 마스크를 씌우는 [FormattedInput](/components/formatted-input) 과 달리 값을 칸 이름별로 나눠 받습니다.

기본 칸 폭이 네 글자보다 좁아, 플레이그라운드의 날짜 칸에서 `2026` 값(두 플랫폼)과 `YYYY` 안내 글자(Jaspr Web)가 잘려 보입니다([칸 폭](#칸-폭)).

<a id="상자"></a>

## 구조

상자 하나 안에 앞 슬롯, 칸, 구분자, 뒤 슬롯이 한 줄로 놓입니다. 앞뒤 슬롯과 구분자는 줄 때만 그립니다.

<Anatomy demo="object-input/anatomy">
<AnatomyItem part="container" name="Container">

상자. 테두리 · 채움 · 포커스 표시는 이 상자 하나가 그립니다. 높이 48, 모서리 12, 좌우 여백 14, 안에 놓인 요소 사이 간격 4, 테두리 1 입니다.

</AnatomyItem>
<AnatomyItem part="leading" side="top" name="leading">

첫 칸 앞의 위젯 슬롯입니다. ObjectInput 은 슬롯에 크기나 색을 따로 정하지 않습니다.

</AnatomyItem>
<AnatomyItem select="span" side="top" name="separator">

`separator` 로 준 글자를 칸 사이마다 그립니다. 13 크기(`bodySmall`), `onSurfaceSubtle` 색, 좌우 여백 2 입니다. 마지막 칸 뒤에는 그리지 않습니다.

</AnatomyItem>
<AnatomyItem select="span + div + span + div" side="top" name="field">

칸 하나. `plain` 변형 `lg` 크기의 [TextField](/components/text-field) 에서 테두리 · 채움 · 여백을 모두 없애, 상자 안에 상자가 생기지 않습니다. 값은 13 크기 고정폭(`codeMd`), 빈 칸의 `placeholder` 는 15 크기 본문 글자(`bodyLarge`)이고 둘 다 가운데 정렬입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=trailing]" side="right" name="trailing">

마지막 칸 뒤의 위젯 슬롯입니다. 단위나 짧은 글자, 버튼을 놓습니다.

</AnatomyItem>
</Anatomy>

상자 높이 48 은 컨트롤 높이 사다리의 `lg` 행이라 [TextField](/components/text-field) `lg` 와 한 줄에 놓입니다. 앱의 밀도를 따라 한 칸 움직이고(compact 40, spacious 56), `objectInputStyle` 의 `height` 로 직접 준 값은 그대로입니다.

## 필드와 값

칸 하나는 `CoreObjectInputField` 하나입니다.

```dart
ObjectInput(
  fields: const [
    CoreObjectInputField(key: 'year', placeholder: 'YYYY', maxLength: 4, pattern: r'\d'),
    CoreObjectInputField(key: 'month', placeholder: 'MM', maxLength: 2, pattern: r'\d'),
    CoreObjectInputField(key: 'day', placeholder: 'DD', maxLength: 2, pattern: r'\d'),
  ],
  separator: '/',
  onChanged: setBirthDate,
)
```

| 항목 | 동작 |
| --- | --- |
| `key` | 값 맵에서 쓰는 이름입니다. 칸마다 다르게 줍니다. |
| `placeholder` | 빈 칸에 보이는 글자입니다. |
| `maxLength` | 칠 수 있는 최대 글자 수이고, 칸 폭도 이 수로 정합니다. 생략하면 글자 수를 제한하지 않고, 폭은 `placeholder` 글자 수로 정합니다. |
| `pattern` | 글자 하나하나가 맞아야 하는 정규식 원문(`r'\d'`)입니다. 맞지 않는 글자는 치거나 붙여 넣을 때 빼고 넣습니다. 생략하면 글자를 거르지 않습니다. |

- ObjectInput 은 `key` 이름으로 칸의 종류를 알아채지 않습니다. 숫자만 받으려면 `pattern` 을 줍니다.
- `pattern` 은 글자를 하나씩만 봅니다. `99` 월처럼 칸의 값이 말이 되는지는 `onChanged` 로 받은 값을 직접 검사합니다.
- 칸을 다 채워도 다음 칸으로 넘어가지 않습니다. `Tab` 이나 누르기로 옮깁니다.
- `values` 는 **처음 값**입니다. 화면에 올라간 뒤 다른 `values` 를 넘겨도 칸은 바뀌지 않습니다. 새 값으로 다시 시작하려면 ObjectInput 의 `key` 를 바꿔 새로 만듭니다. `fields` 의 칸 수가 바뀌면 그때의 `values` 를 다시 읽습니다.
- `values` 는 `pattern` 과 `maxLength` 로 거르지 않습니다. 넘긴 글자가 그대로 칸에 들어갑니다.

### 칸 폭

칸 폭은 입력한 값과 상관없이 정해집니다. 글자 하나 폭 12(`charWidth`)에 `maxLength`(없으면 `placeholder` 글자 수)를 곱하고, `maxLength` 가 있으면 글자 수 구간의 상한으로 자릅니다.

| `maxLength` | 상한 | 기본 폭 |
| --- | --- | --- |
| 1 · 2 | `shortFieldMaxWidth` 28 | 12 · 24 |
| 3 · 4 | `mediumFieldMaxWidth` 28 | 28 |
| 5 이상 | `longFieldMaxWidth` 48 | 48 |
| 없음 | 상한 없음 | 12 × `placeholder` 글자 수 |

<Preview demo="object-input/widths" />

위 그림은 폭을 견주려고 칸에 담기는 짧은 `placeholder` 를 썼습니다. 칸보다 넓은 글자는 잘립니다.

- 구간의 경계는 `shortFieldMaxChars`(2)와 `mediumFieldMaxChars`(4)로 바꿉니다. 기본값은 앞의 두 상한이 모두 28 이라, `shortFieldMaxChars` 를 `mediumFieldMaxChars` 이하에서 바꾸는 것만으로는 폭이 달라지지 않습니다.
- Flutter 는 폭에 화면 배율(`scaling`)을 곱하고, Jaspr Web 은 rem 으로 내보내 브라우저 글자 크기를 따릅니다.

<Note>

아래는 기본값 · 기본 배율로 계산한 것이고 화면에서 잰 값이 아닙니다. 값 글자(13 크기 Geist Mono)는 숫자 하나가 약 7.8 입니다. Jaspr Web 의 입력은 칸 폭을 다 쓰지만, Flutter 는 가운데 정렬 입력의 커서 자리로 6 을 빼서 스크롤 없이 담기는 폭이 `칸 폭 − 6` 입니다.

- **네 자리 칸**(폭 28): 두 플랫폼 모두 숫자 네 개(약 31)와 15 크기 `YYYY` placeholder(약 37)가 잘려 보일 수 있습니다.
- **Flutter 의 세 자리 · 한 자리 칸**(폭 28 · 12): 담기는 폭이 22 · 6 이라, 숫자 세 개(약 23)나 한 개(약 8)도 치는 동안 앞쪽이 조금 밀려 잘릴 수 있습니다.
- **`MM` 같은 넓은 두 자리 placeholder**(약 25): 두 자리 칸의 폭 24 를 조금 넘습니다. 폭은 `charWidth × 글자 수` 와 상한 중 작은 쪽이라, `shortFieldMaxWidth` 만 늘려서는 24 를 넘지 않습니다.
- **긴 칸**(폭 48): 숫자는 Jaspr Web 에서 여섯 개, Flutter 에서 다섯 개까지 담깁니다. 더 긴 값은 `longFieldMaxWidth` 를 늘립니다.

`mediumFieldMaxWidth` 를 48 로 늘리면 네 자리 칸은 48, 세 자리 칸은 36 이 됩니다. `charWidth` 를 14 로 늘리면 두 자리 칸은 28, 한 자리 칸은 14 가 되고, `maxLength` 가 없는 칸의 폭도 함께 넓어집니다.

</Note>

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 상태

ObjectInput 에는 variant 가 없습니다. 포인터 · 포커스 · `enabled` 가 상자의 모양을 정합니다.

<Preview demo="object-input/states" />

장면의 Focus 입력창은 포커스 테두리 색을 쉬는 테두리와 Hover 테두리에 고정해 그렸습니다. Hover 는 빈 칸 · 값 입력창에 포인터를 올려 봅니다.

| 항목 | 동작 |
| --- | --- |
| 쉴 때 | 상자 채움 `surface`, 테두리 `outlineVariant`. 칸에는 자기 테두리와 채움이 없습니다. 구분자는 `onSurfaceSubtle`, 빈 칸의 글자는 `placeholder` 색입니다. |
| Hover | 상자 어디에 올려도(칸 위 포함) 테두리가 `outline` 으로 한 단 진해집니다(`hoverBorderColor`). |
| Focus | 상자 안 어디든 포커스가 들어오면(앞뒤 슬롯의 버튼 포함) 테두리가 `primary` 로 바뀝니다. 굵기는 1 그대로이고 바깥 링은 없습니다. 키보드로 들어왔는지 눌러서 들어왔는지를 가리지 않습니다. 칸마다의 포커스 링은 꺼 두어, 어느 칸에 있는지는 커서가 보여 줍니다. |
| 비활성 | `enabled: false`. 상자 채움 `disabledContainer`, 테두리 `disabledOutline`, 칸의 글자와 구분자 `disabledContent`. 불투명도로 흐리게 하지 않습니다. 칸에 입력할 수 없고 포커스 테두리도 그리지 않습니다. |

겹치면 비활성이 Focus 를, Focus 가 Hover 를 이깁니다. 비활성일 때는 `backgroundColor` · `borderColor` 대신 `disabledBackgroundColor` · `disabledBorderColor` · `disabledSeparatorColor` 가 쓰입니다. `enabled` 의 기본값은 `onChanged` 유무와 상관없이 `true` 입니다. `liquidGlass` 서페이스 스타일에서는 Hover · Focus 의 테두리 변화가 보이지 않습니다(접근성의 [알려진 제약](#알려진-제약)).

ObjectInput 에는 오류 모양이 없습니다. 오류 문구는 [FormField](/components/form-field) 의 `error` 로 보여 줍니다 — 상자 테두리는 오류 색으로 바뀌지 않습니다(접근성의 알려진 제약).

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

연 · 월 · 일, 시 · 분처럼 뜻이 다른 칸 여러 개를 한 줄에서 받고, 값을 칸 이름별로 다뤄야 할 때 ObjectInput 을 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 문자열 하나에 마스크를 씌워, 칸을 옮기지 않고 이어 치게 할 때 | [FormattedInput](/components/formatted-input) |
| 값 하나를 자유롭게 입력받을 때 | [TextField](/components/text-field) |
| 고정 길이 인증 코드를 받을 때 | [InputOtp](/components/input-otp) |
| 달력에서 날짜를 고를 때 | [DatePicker](/components/date-picker) |
| 시각을 고르는 화면이 필요할 때 | [TimePicker](/components/time-picker) |
| 정해진 선택지에서 고를 때 | [Select](/components/select) |

<a id="do"></a>
<a id="dont"></a>

### 라벨과 입력 제한

<Cards columns="2">
<Card demo="object-input/do-form-field" tone="do" eyebrow="이렇게 하세요">

FormField 의 라벨로 무엇을 받는지 알립니다. 라벨이 칸 묶음의 이름이 됩니다.

</Card>
<Card demo="object-input/dont-bare" tone="dont" eyebrow="이렇게 하지 마세요">

라벨 없이 칸만 두지 않습니다. 상자에는 이름이 없어 `00:00` 만으로는 무엇을 받는지 알 수 없습니다.

</Card>
<Card demo="object-input/do-pattern" tone="do" eyebrow="이렇게 하세요">

`pattern: r'\d'` 로 칸마다 받을 글자를 정합니다.

</Card>
<Card demo="object-input/dont-no-pattern" tone="dont" eyebrow="이렇게 하지 마세요">

`pattern` 이 없으면 어떤 글자든 `maxLength` 까지 들어갑니다. `key` 를 `hour` 로 지어도 숫자만 받지 않습니다.

</Card>
</Cards>

<Note>

거른 글자는 아무 안내 없이 빠집니다. 숫자만 받는 칸이라면 `placeholder` 나 FormField 의 `description` 으로 먼저 알려 줍니다.

</Note>

## 배치

- 상자 폭은 안에 든 것(앞뒤 슬롯 · 칸 · 구분자 · 간격 · 여백)만큼입니다. 부모가 폭을 늘리면(Flutter 의 `CrossAxisAlignment.stretch` 인 `Column`, FormField) 상자만 늘고 칸은 앞쪽에 모입니다.
- 칸은 한 줄에 놓이고 다음 줄로 넘어가지 않습니다. Flutter 는 칸 폭이 정해져 있어, 부모가 안의 내용보다 좁으면 넘침(overflow) 오류가 납니다.
- 칸이 많아 한 줄에 담기 어려우면 ObjectInput 하나에 모으지 말고 [TextField](/components/text-field) 를 나눠 놓습니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

상자의 색 · 크기 · 간격과 안쪽 칸의 모양은 `objectInputStyle`(`CoreObjectInputStyle`) 하나로 덮어씁니다. 칸은 TextField 라 칸의 모양, 값 글자, placeholder 글자는 그 안의 `fieldInputStyle`(`CoreTextFieldStyle`)로 바꿉니다. variant 와 size 속성은 없습니다.

<Split>

<Code language="dart" title="ObjectInput 하나만 바꾸기">
ObjectInput(
  fields: birthDateFields,
  separator: '.',
  onChanged: setBirthDate,
  objectInputStyle: CoreObjectInputStyle(
    focusBorderColor: CoreColor.token(CoreColors.tertiary),
    mediumFieldMaxWidth: CoreSpace.space48,
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    objectInput: CoreObjectInputTheme(
      style: CoreObjectInputStyle(
        height: CoreControlSize.heightMd,
      ),
    ),
  ),
)
</Code>

</Split>

상자는 카드 · 본문 패널과 같은 층의 표면이라, 서페이스 스타일을 켜면 그 층의 재질을 받습니다. `liquidGlass` 는 재질이 가장자리를 직접 그려 상자 테두리 색을 투명하게 합니다.

<Note>

`.primary` 같은 색 getter 와 `backgroundColor` 는 상자 채움만 바꿉니다. 칸의 글자 · placeholder · 구분자 색은 그대로라, 진한 채움을 줄 때는 `fieldInputStyle` 과 `separatorTextStyle` 의 색도 함께 정하고 대비를 확인합니다.

</Note>

### 빠른 오버라이드 (Chain)

이미 만든 `ObjectInput` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `objectInputStyle` 인자와 같게 동작합니다. `.radius16` 처럼 Core 토큰 상수와 이름이 같은 짧은 getter 도 있습니다 — 반경 getter 는 `borderRadius` 를, 색 getter 는 상자 채움(`backgroundColor`)을 바꿉니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ObjectInputChainExample extends StatelessWidget {
  const ObjectInputChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        ObjectInput(
          fields: const [
            CoreObjectInputField(
              key: 'year',
              placeholder: 'YYYY',
              maxLength: 4,
              pattern: r'\d',
            ),
            CoreObjectInputField(
              key: 'month',
              placeholder: 'MM',
              maxLength: 2,
              pattern: r'\d',
            ),
            CoreObjectInputField(
              key: 'day',
              placeholder: 'DD',
              maxLength: 2,
              pattern: r'\d',
            ),
          ],
          separator: '/',
          onChanged: (values) => debugPrint('$values'),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        ObjectInput(
          fields: const [
            CoreObjectInputField(
              key: 'year',
              placeholder: 'YYYY',
              maxLength: 4,
              pattern: r'\d',
            ),
            CoreObjectInputField(
              key: 'month',
              placeholder: 'MM',
              maxLength: 2,
              pattern: r'\d',
            ),
            CoreObjectInputField(
              key: 'day',
              placeholder: 'DD',
              maxLength: 2,
              pattern: r'\d',
            ),
          ],
          separator: '/',
          onChanged: (values) => debugPrint('$values'),
        ).withStyle(
          const CoreObjectInputStyle(
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
class ObjectInputChainExample extends StatelessComponent {
  const ObjectInputChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        ObjectInput(
          fields: const [
            CoreObjectInputField(
              key: 'year',
              placeholder: 'YYYY',
              maxLength: 4,
              pattern: r'\d',
            ),
            CoreObjectInputField(
              key: 'month',
              placeholder: 'MM',
              maxLength: 2,
              pattern: r'\d',
            ),
            CoreObjectInputField(
              key: 'day',
              placeholder: 'DD',
              maxLength: 2,
              pattern: r'\d',
            ),
          ],
          separator: '/',
          onChanged: (values) => print('$values'),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        ObjectInput(
          fields: const [
            CoreObjectInputField(
              key: 'year',
              placeholder: 'YYYY',
              maxLength: 4,
              pattern: r'\d',
            ),
            CoreObjectInputField(
              key: 'month',
              placeholder: 'MM',
              maxLength: 2,
              pattern: r'\d',
            ),
            CoreObjectInputField(
              key: 'day',
              placeholder: 'DD',
              maxLength: 2,
              pattern: r'\d',
            ),
          ],
          separator: '/',
          onChanged: (values) => print('$values'),
        ).withStyle(
          const CoreObjectInputStyle(
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
기본값 (CoreObjectInputStyle.default*)
  → CoreComponentTheme.objectInput.style    // 앱 전체
  → objectInputStyle                        // 인스턴스
```

뒤로 갈수록 우선합니다. variant 가 없어 `variantStyles` 는 없습니다. `fieldInputStyle` 은 `defaultFieldInputStyle` 위에 얹혀 칸의 TextField 에 `textFieldStyle` 로 넘어갑니다. 칸은 실제 TextField 라 앱의 TextField 테마(`plain` variant 설정 포함)를 먼저 받고, 그 위에 ObjectInput 이 넘기는 값이 얹힙니다.

<a id="접근성-accessibility"></a>

## 접근성

ObjectInput 은 스스로 역할이나 이름을 더하지 않습니다. 읽히고 조작되는 것은 칸마다의 TextField 입니다. 전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타깃)은 [전역 접근성 축](/accessibility)에 있습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | `Semantics` 로 만드는 이름 · 묶음 · 역할이 없습니다. 칸마다 TextField 의 텍스트 필드 노드가 있습니다. |
| Jaspr Web | 루트는 `role` · `aria-*` 가 없는 `<div>` 이고, `<fieldset>` · `<legend>` · `<label>` 도 없습니다. 칸을 감싼 `<div>` 와 구분자 `<span>` 에도 역할이 없고, 칸마다 네이티브 `<input>` 이 있습니다. |

#### 칸 묶음에 이름 붙이기

[FormField](/components/form-field) 의 `label` 로 감싸면 두 플랫폼 모두 묶음에 이름이 붙습니다 — Jaspr Web 은 `role="group"` 과 `aria-labelledby`, Flutter 는 `Semantics(container: true, label:)` 입니다. 라벨을 화면에 두지 않으려면 Jaspr Web 은 `attributes` 로 루트에 직접 붙이고, Flutter 는 바깥을 `Semantics` 로 감쌉니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Semantics(
  container: true,
  label: '생년월일',
  child: ObjectInput(fields: birthDateFields, separator: '/'),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
ObjectInput(
  fields: birthDateFields,
  separator: '/',
  attributes: const {'role': 'group', 'aria-label': '생년월일'},
)
```

  </TabItem>
</Tabs>

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` | 다음 칸으로 옮깁니다. 마지막 칸에서는 뒤 슬롯의 버튼이나 상자 밖의 다음 요소로 갑니다. Flutter 는 첫 칸 앞에 상자 정지점이 하나 더 있습니다(→ 포커스 관리). |
| `Shift` · `Tab` | 이전 칸 · 이전 요소로 옮깁니다. |

ObjectInput 이 직접 처리하는 키는 없습니다. 글자 입력 · 커서 · 선택은 각 TextField 가 맡습니다. 칸을 다 채웠을 때의 자동 이동, 빈 칸에서 `Backspace` 로 앞 칸에 돌아가기, 화살표로 칸 옮기기는 두 플랫폼 모두 없습니다. Jaspr Web 의 `onKeyDown` · `onKeyUp` 은 칸에서 올라온 키 이벤트를 받는 자리일 뿐, ObjectInput 이 따로 하는 일은 없습니다.

### 스크린 리더

- 칸마다 TextField 의 입력이 따로 읽힙니다. Jaspr Web 의 입력 이름은 `placeholder` 에서만 옵니다. 칸에 이름을 붙이는 속성은 두 플랫폼 모두 없습니다.
- Flutter 는 빈 칸일 때만 `placeholder` 글자가 접근성 트리에 있고, 값을 치면 빠집니다.
- 구분자 글자는 감추지 않아 칸 사이에서 함께 읽힙니다.
- ObjectInput 은 칸의 개수나 위치("3개 중 2번째"), 칸 사이의 관계를 알리지 않습니다. 상자 테두리가 바뀌는 것도 따로 알리지 않습니다.
- `pattern` · `maxLength` 때문에 들어가지 않은 글자는 알리지 않습니다.

### 포커스 관리

- 화면에 올라갈 때 포커스를 옮기지 않습니다. `autofocus` · `focusNode` · 컨트롤러 속성이 없어, ObjectInput 의 속성으로는 칸에 포커스를 줄 수 없습니다.
- 포커스를 가두거나 되돌리지 않습니다.
- 포커스 표시는 상자 테두리 색 하나입니다. 칸마다의 링은 꺼 둡니다. `liquidGlass` 에서는 이 테두리 색도 보이지 않습니다.
- Flutter 는 상자 전체를 감싼 `Focus` 가 기본 설정이라 포커스를 받을 수 있어, 첫 칸 앞에 `Tab` 정지점이 하나 더 생깁니다. 비활성이어도 남습니다.
- Flutter 는 `enabled: false` 여도 각 칸이 `Tab` 정지점으로 남습니다. 이때 상자는 포커스 테두리를 그리지 않고 칸의 링과 커서도 없어, 코드상 포커스 표시가 보이지 않습니다. Jaspr Web 의 비활성 `<input>` 은 `Tab` 순서에서 빠집니다.
- Jaspr Web 의 루트 `<div>` 에는 `tabindex` 가 없어 정지점이 아닙니다. `focusin` · `focusout` 으로 테두리 색만 바꾸고, `enabled: false` 면 두 이벤트를 듣지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 칸 묶음에 역할도 이름도 없어, 연 · 월 · 일 칸이 서로 무관한 입력 세 개로 읽힙니다. 위의 방법으로 이름을 붙입니다. |
| 공통 | 칸마다 이름을 붙이는 속성이 없습니다. |
| 공통 | 여러 칸 입력에서 흔한 자동 이동 · `Backspace` 되돌아가기 · 화살표 이동이 없습니다. |
| 공통 | 구분자가 스크린 리더에서 감춰지지 않습니다. |
| 공통 | `pattern` · `maxLength` 로 거른 글자를 알리지 않습니다. |
| 공통 | 칸마다의 포커스 링이 꺼져 있어, 지금 어느 칸인지는 커서만 보여 줍니다. |
| 공통 | 오류 속성이 없습니다. FormField 의 `error` 로 감싸면 상자는 그대로이고 안쪽 칸만 오류 상태가 됩니다 — 코드상 포커스한 칸 둘레에 오류 색 선(1)이 생겨 상자 안에 상자가 보입니다. |
| 공통 | 감싼 `FormField(enabled: false)` · `Fieldset(enabled: false)` 로는 칸만 비활성 상태가 되고, 상자와 구분자는 비활성 색으로 바뀌지 않습니다. 대신 `FormField` 는 두 플랫폼 모두 안쪽 전체(앞뒤 슬롯 포함)의 포인터 입력을 막고, `Fieldset` 은 묶음 전체를 반투명하게(50%) 합니다. Flutter 에서는 `Tab` 으로 들어가면 상자 테두리가 포커스 색이 됩니다. 상자까지 비활성으로 보이려면 ObjectInput 에 `enabled: false` 를 줍니다. |
| 공통 | `liquidGlass` 서페이스 스타일에서는 상자 테두리가 투명해, 코드상 Hover · Focus 테두리가 보이지 않습니다. 칸의 링도 꺼져 있어 포커스는 커서만 보여 줍니다. |
| 공통 | `fields` 의 칸 수를 그대로 둔 채 `key` 를 바꾸면 `onChanged` 의 맵에 옛 이름이 남습니다. 바뀐 칸에 Flutter 는 옛 글자를 그대로 보여 주고, Jaspr Web 은 빈 칸을 보여 줍니다. ObjectInput 의 `key` 를 함께 바꿉니다. |
| 공통 | 기본 칸 폭이 좁아 네 자리 값(`2026`)이 두 플랫폼에서 잘리고, Jaspr Web 에서는 `YYYY` 안내 글자도 잘립니다. 계산상 `MM` 안내 글자도, 커서 자리로 6 을 더 빼는 Flutter 의 세 자리 · 한 자리 칸에 치는 값도 잘릴 수 있습니다([칸 폭](#칸-폭)). |
| Flutter | 상자가 `Tab` 정지점을 하나 더 차지합니다. `enabled: false` 여도 상자와 칸이 모두 정지점으로 남고, 포커스 표시는 보이지 않습니다. |
| Flutter | 감싼 FormField 에 값을 보고하지 않아 `validator` 가 이 값을 받지 못합니다. `onChanged` 로 받은 값을 검사해 FormField 의 `error` 로 넘깁니다. |
| Jaspr Web | `pattern` 을 입력 필터뿐 아니라 `<input>` 의 `pattern` 속성에도 넣습니다. 브라우저는 이 속성을 값 전체에 맞춰 보므로, `r'\d'` 칸에 두 글자 이상 들어가면 브라우저 검증에서는 맞지 않는 값이 됩니다. 직접 만든 네이티브 `<form>` 안에서는 제출이 막힐 수 있습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링과 몇 가지 동작은 각 플랫폼의 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 칸 | `TextField`(`EditableText`) | `TextField`(네이티브 `<input>`) |
| 칸 폭 | 화면 배율(`scaling`)을 곱한 값. 값은 커서 자리(기본 6)를 뺀 폭에 담깁니다 | rem — 브라우저 글자 크기를 따릅니다. 값이 칸 폭 전체를 씁니다 |
| 포커스 감지 | `Focus` 위젯. 상자도 `Tab` 정지점입니다 | `focusin` · `focusout`. 상자는 정지점이 아닙니다 |
| 비활성일 때 `Tab` | 상자와 각 칸이 정지점으로 남습니다 | 비활성 `<input>` 은 순서에서 빠집니다 |
| Hover 테두리 | `MouseRegion` 으로 감지해 Hover 모양을 고릅니다 | 토큰 색은 `hover:border-*` 클래스(포커스 중에는 붙이지 않음), 쉬는 테두리나 Hover 색이 토큰이 아니면 `:hover` 규칙 |
| 비활성 커서 | 칸 위에서 금지 커서 | 상자에 `cursor-not-allowed` |
| `pattern` 에 맞지 않는 글자를 칠 때 | `onChanged` 를 부르지 않습니다 | 값이 그대로여도 `onChanged` 를 부릅니다 |
| 붙여넣기 | `pattern` 으로 거른 뒤 `maxLength` 로 자릅니다 | 브라우저가 `maxlength` 로 먼저 자른 뒤 `pattern` 으로 거릅니다 |
| `pattern` | 입력 필터 | 입력 필터와 `<input pattern>` 속성 |
| FormField 값 | 보고하지 않습니다 | `Map<String, String>` 을 보고합니다. `validator` 가 `ReplaceResult` 를 돌려주면 그 값으로 칸을 바꾸고 `onChanged` 를 부릅니다 |
| `leading` · `trailing` | `Widget` | `Component` |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` · `onClick` 등. 루트 `<div>` 에 붙습니다 |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. `leading` · `trailing` 의 타입은 Flutter `Widget`, Jaspr Web `Component` 이고, 값은 두 플랫폼 모두 `Map<String, String>` 입니다.

### 칸과 값

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `fields` | `List<CoreObjectInputField>` | 필수 | 칸 목록. 적은 순서로 놓습니다. |
| `values` | `Map<String, String>?` | `null` | 처음 값(칸 `key` → 값) |
| `separator` | `String?` | `null` | 칸 사이에 그릴 글자 |
| `leading` | `Widget?` | `null` | 첫 칸 앞 슬롯 |
| `trailing` | `Widget?` | `null` | 마지막 칸 뒤 슬롯 |

### 상태와 콜백

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `enabled` | `bool` | `true` | `false` 면 비활성 |
| `onChanged` | `void Function(Map<String, String>)?` | `null` | 값이 바뀔 때 모든 칸의 값을 받습니다. |

### 폭과 모양

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `shortFieldMaxChars` | `int` | `2` | 짧은 칸 구간의 `maxLength` 상한 |
| `mediumFieldMaxChars` | `int` | `4` | 중간 칸 구간의 상한. 넘으면 긴 칸입니다. |
| `objectInputStyle` | `CoreObjectInputStyle?` | `null` | 보이는 값 덮어쓰기 |

### CoreObjectInputField

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `key` | `String` | 필수 | 값 맵에서 쓰는 이름 |
| `placeholder` | `String` | 필수 | 빈 칸에 보이는 글자 |
| `maxLength` | `int?` | `null` | 최대 글자 수. 칸 폭도 정합니다. |
| `pattern` | `String?` | `null` | 글자 하나가 맞아야 하는 정규식 원문 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreObjectInputStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Container background colour override. |
| `borderColor` | `CoreColor?` | Container border colour override. |
| `hoverBorderColor` | `CoreColor?` | Container border colour override while the pointer is over the container. `null` → [defaultHoverBorderColor]. Never applied while the container is focused (the focus border wins) or disabled. |
| `focusBorderColor` | `CoreColor?` | Container focus-ring border colour override. |
| `disabledBackgroundColor` | `CoreColor?` | Container background colour override while disabled. `null` → [defaultDisabledBackgroundColor]. |
| `disabledBorderColor` | `CoreColor?` | Container border colour override while disabled. `null` → [defaultDisabledBorderColor]. |
| `disabledSeparatorColor` | `CoreColor?` | Field separator text colour override while disabled. `null` → [defaultDisabledSeparatorColor]. |
| `borderRadius` | `CoreBorderRadius?` | Container border radius override. |
| `borderWidth` | `double?` | Container border width override (logical px). |
| `padding` | `CoreEdgeInsets?` | Container padding override. |
| `height` | `double?` | Container height override (logical px). `null` → [defaultHeight], which moves with the density; a stated height stays as stated. |
| `fieldSpacing` | `double?` | Gap between the container's children override (logical px). `null` → [defaultFieldSpacing]. |
| `separatorTextStyle` | `CoreTextStyle?` | Field separator text style override (typography role / font / colour). |
| `fieldInputStyle` | `CoreTextFieldStyle?` | Style override for each field's `TextField` — its look plus the value and placeholder typography. Passed to every field's `TextField` on both platforms. |
| `shortFieldMaxWidth` | `double?` | Max-width override for short fields (1–2 chars) (logical px). |
| `mediumFieldMaxWidth` | `double?` | Max-width override for medium fields (3–4 chars) (logical px). |
| `longFieldMaxWidth` | `double?` | Max-width override for long fields (5+ chars) (logical px). |
| `separatorPadding` | `CoreEdgeInsets?` | Custom padding around the field separator glyph (pre-scaling). `null` → [defaultSeparatorPadding]. |
| `charWidth` | `double?` | Per-character width used to size a field to its `maxChars` bucket (logical px, pre-scaling). `null` → [defaultCharWidth]. |

<!-- STYLE_TABLE:END -->

<Note>

`focusBorderColor` 는 따로 그리는 링이 아니라 포커스가 있을 때의 상자 테두리 색입니다. 표의 "1–2 chars" · "3–4 chars" 는 `shortFieldMaxChars` · `mediumFieldMaxChars` 의 기본값 기준이고, `charWidth` 는 `maxLength`(없으면 `placeholder` 글자 수)에 곱합니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="object-input/related-formatted-input" title="FormattedInput">

문자열 하나를 마스크에 맞춰 입력받습니다.

</Card>
<Card demo="object-input/related-text-field" title="TextField">

값 하나를 자유롭게 입력받습니다.

</Card>
<Card demo="object-input/related-form-field" title="FormField">

라벨 · 도움말 · 오류 문구를 붙입니다.

</Card>
</Cards>
