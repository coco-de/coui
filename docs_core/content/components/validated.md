---
title: Validated
description: 폼 필드를 감싸 검증 결과를 필드에 전달하고, 아래에 검증 메시지를 보이는 래퍼입니다. 입력값이 맞는지 틀렸는지를 필드와 문장으로 함께 알릴 때 씁니다.
category: form
platforms: [flutter, web]
related: [form-control, validator-hint, form]
tags: [form, validation]
template: v2
source: form/validated
---

# Validated

<a id="live-preview"></a>
<a id="사용법"></a>

## 플레이그라운드

상태와 메시지를 바꿔 보며 Validated를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="validated" />

Validated는 값을 검사하지 않습니다. 검사는 앱이 하고, 결과를 `state`(`pending` · `valid` · `invalid`)로 넘깁니다. `pending`이면 `message`를 넘겨도 그리지 않습니다.

## 구조

Validated는 감싼 필드(`child`)와 그 아래의 메시지 줄로 이루어집니다. 따로 감싸는 테두리나 링은 그리지 않습니다.

<Anatomy demo="validated/anatomy">
<AnatomyItem part="container" side="top" name="Container">

필드와 메시지를 위아래로 놓는 래퍼입니다. 자기 배경 · 테두리 · 안쪽 여백은 없습니다.

</AnatomyItem>
<AnatomyItem select="div:has(> input)" side="right" name="child">

감싼 필드입니다. `invalid`이면 안의 TextField가 자기 오류 모양(테두리와 포커스 링)을 켭니다.

</AnatomyItem>
<AnatomyItem part="leading" side="left" name="icon">

메시지 앞의 아이콘입니다. `invalid`는 `circle-alert`, `valid`는 `circle-check-big`입니다.

</AnatomyItem>
<AnatomyItem part="label" side="right" name="message">

`message`를 [ValidatorHint](/components/validator-hint)로 그린 줄입니다. 필드와의 간격은 4입니다. Jaspr Web에서는 앱의 브라우저 기본 스타일 초기화에 따라 더 벌어질 수 있습니다([플랫폼 차이](#플랫폼-차이)).

</AnatomyItem>
</Anatomy>

<a id="동작-스펙-behavior"></a>

## 상태

variant와 크기는 없습니다. `state` 하나가 필드와 메시지를 함께 정합니다.

<Preview demo="validated/states" />

| `state` | 감싼 TextField | 메시지 |
| --- | --- | --- |
| `pending` (기본값) | 자기 모양 그대로입니다. | `message`를 넘겨도 그리지 않습니다. |
| `valid` | 자기 모양 그대로입니다. | `success` 색과 `circle-check-big` 아이콘 |
| `invalid` | 테두리와 포커스 링이 `error` 색이 됩니다. 테두리 굵기는 그대로입니다. | `error` 색과 `circle-alert` 아이콘 |

| 항목 | 동작 |
| --- | --- |
| `message`가 없을 때 | 메시지 줄과 간격이 없습니다. `invalid`는 필드 모양만 바꿉니다. |
| 비활성 필드 | 비활성 모양이 오류 모양보다 앞섭니다. 메시지는 그대로 보입니다. |
| 필드 자신의 오류 | `errorText`를 가진 TextField, `min` · `max`를 벗어난 값이 든 TextField, [FormField](/components/form-field)의 `error` 아래에 있는 TextField는 `valid` · `pending`으로 감싸도 오류 모양입니다. 필드의 오류와 Validated의 `invalid` 중 하나만 있어도 오류 모양이 됩니다. |
| `filled` · `plain` TextField | `invalid`에서는 원래 variant 대신 `error` variant(`surface` 채움과 `error` 테두리)로 그립니다. |
| `liquidGlass` 서페이스 스타일 | 대비를 높이는 설정을 켜지 않았다면 TextField의 쉬는 테두리가 보이지 않습니다. 필드의 `invalid` 표시는 포커스했을 때의 링에만 보입니다. |

## 상태 전파

Validated는 `child` 아래의 모든 위젯에 상태를 내려보내고, 그 값을 읽는 것은 TextField입니다. [Select](/components/select) · [DatePicker](/components/date-picker)의 입력 상자처럼 TextField를 안에 그리는 컴포넌트는 그 TextField가 값을 읽습니다. 틀을 따로 그리는 입력은 틀이 바뀌지 않습니다. [PhoneInput](/components/phone-input)은 안쪽 TextField의 채움 · 테두리 · 링을 감추어 보이는 변화가 없고, [ChipInput](/components/chip-input)은 틀 안의 입력 줄에만 `surface` 채움과 오류 테두리가 생깁니다. TextArea · Checkbox · RadioGroup · Toggle처럼 TextField를 쓰지 않는 필드는 `invalid`에서도 모양이 그대로이고 메시지만 보입니다.

<Preview demo="validated/propagation" />

| 항목 | 동작 |
| --- | --- |
| 여러 필드를 감쌀 때 | 안의 모든 TextField가 같은 상태를 받습니다. 필드마다 따로 감싸세요. |
| Validated를 겹칠 때 | 가장 가까운 Validated의 상태를 받습니다. 안쪽의 `pending`은 바깥의 `invalid`를 가립니다. |
| 직접 만든 필드 | Flutter에서는 `Data.maybeOf<CoreValidationState>(context)`로 읽을 수 있습니다. Jaspr Web에서는 상태를 읽는 타입을 `coui_web.dart`로 내보내지 않습니다. |
| 열린 패널 | Flutter에서는 Validated 안에서 연 팝오버 · 대화상자 · 토스트 안의 TextField도 같은 상태를 받습니다. Jaspr Web은 `CoUIWeb`의 오버레이 층에 띄운 패널에 상태가 닿지 않습니다. |

<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

필드와 메시지를 한 묶음으로 두고, 앱이 정한 검증 결과를 필드 모양과 문장으로 함께 보일 때 씁니다. 확인에 시간이 걸리는 검사(예: 닉네임 중복 확인)는 결과가 나오기 전까지 `pending`으로 둡니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| TextField 하나에 오류 문구만 붙일 때 | [TextField](/components/text-field)의 `errorText` — 테두리와 문구가 함께 바뀝니다. |
| 라벨 · 필수 표시 · 폼 검증까지 한 묶음일 때 | [FormField](/components/form-field) |
| 필드 없이 메시지 한 줄만 보일 때 | [ValidatorHint](/components/validator-hint) |
| 비밀번호 규칙처럼 조건마다 충족 여부를 보일 때 | [ValidationBadge](/components/validation-badge) |
| 저장 · 불러오기 요청이 실패했을 때 | [Alert](/components/alert) |

<Note>

Jaspr Web의 TextField `errorText` 문구에는 `role`이 없어, 문구가 나타나도 따로 알리지 않습니다. Validated의 메시지 줄은 `role`을 가집니다(→ 접근성). 오류 문구를 필드 묶음에 연결해야 하면 FormField를 쓰세요. Jaspr Web의 FormField는 `role="group"` 묶음에 `aria-describedby`로 오류 문구를 잇습니다.

</Note>

<a id="do"></a>
<a id="dont"></a>

### 감싸는 방법

<Cards columns="2">
<Card demo="validated/do-state" tone="do" eyebrow="이렇게 하세요">

오류 모양은 `state`에 맡깁니다. 필드에는 색을 따로 주지 않습니다.

</Card>
<Card demo="validated/dont-border-color" tone="dont" eyebrow="이렇게 하지 마세요">

필드에 `borderColor`를 직접 주면 쉬는 상태에서 그 색이 상태보다 앞섭니다. 그림처럼 `valid`인데 빨간 테두리가 남고, 다른 색을 주면 `invalid`의 오류 테두리가 가려집니다.

</Card>
<Card demo="validated/do-per-field" tone="do" eyebrow="이렇게 하세요">

필드마다 따로 감쌉니다. 틀린 필드만 오류 모양이 됩니다.

</Card>
<Card demo="validated/dont-wrap-group" tone="dont" eyebrow="이렇게 하지 마세요">

여러 필드를 한꺼번에 감싸면 맞게 쓴 필드까지 오류 모양이 됩니다.

</Card>
</Cards>

검증 중에는 `pending`을 넘기고, 결과가 나오면 `valid`나 `invalid`로 바꿉니다.

```dart
Validated(
  state: isSubmitting
      ? CoreValidationState.pending
      : (hasError ? CoreValidationState.invalid : CoreValidationState.valid),
  message: Text(errorText ?? '입력값이 확인되었습니다.'),
  child: TextField(placeholder: const Text('이름')),
)
```

<Note>

`state`가 `valid`나 `invalid`일 때 TextField에 `errorText`를 주고 Validated에 `message`도 주면 문구가 두 줄 나옵니다. 둘 중 한 곳에만 씁니다.

</Note>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

Validated의 겉모습은 `validatedStyle`(`CoreValidatedStyle`) 하나로 바꿉니다. 필드는 둘입니다 — 필드와 메시지 사이 간격(`fieldMessageGapStyle`, 기본 4)과 메시지 줄의 모양(`validatorHintStyle`, 기본 글자 역할 `bodySmall`)입니다.

<Split>

<Code language="dart" title="Validated 하나만 바꾸기">
Validated(
  state: CoreValidationState.invalid,
  message: Text('필수 항목입니다.'),
  validatedStyle: CoreValidatedStyle(
    fieldMessageGapStyle: CoreGapStyle(size: CoreSpace.space8),
  ),
  child: TextField(),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    validated: CoreValidatedTheme(
      style: CoreValidatedStyle(
        fieldMessageGapStyle: CoreGapStyle(size: CoreSpace.space8),
      ),
    ),
  ),
)
</Code>

</Split>

<Note>

필드의 오류 모양은 TextField의 것입니다. 바꾸려면 `validatedStyle`이 아니라 TextField의 스타일이나 TextField 테마의 `error` variant를 바꿉니다.

</Note>

### 빠른 오버라이드 (Chain)

이미 만든 `Validated`에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `validatedStyle` 인자와 같게 동작합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ValidatedChainExample extends StatelessWidget {
  const ValidatedChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child:
          Validated(
            state: CoreValidationState.invalid,
            message: const Text('필수 항목입니다.'),
            child: TextField(placeholder: const Text('이름')),
          ).withStyle(
            const CoreValidatedStyle(
              fieldMessageGapStyle: CoreGapStyle(size: CoreSpace.space16),
              validatorHintStyle: CoreValidatorHintStyle(
                accentColor: CoreColor.token(CoreColors.warning),
                iconStyle: CoreIconStyle(size: CoreIconSize.size16),
                iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
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
class ValidatedChainExample extends StatelessComponent {
  const ValidatedChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '320px'}),
      [
        Validated(
          state: CoreValidationState.invalid,
          message: Text('필수 항목입니다.'),
          child: TextField(placeholder: Text('이름')),
        ).withStyle(
          const CoreValidatedStyle(
            fieldMessageGapStyle: CoreGapStyle(size: CoreSpace.space16),
            validatorHintStyle: CoreValidatorHintStyle(
              accentColor: CoreColor.token(CoreColors.warning),
              iconStyle: CoreIconStyle(size: CoreIconSize.size16),
              iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
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

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
CoreValidatedStyle.default*             // 간격 4 · 메시지 글자 bodySmall
  → CoreComponentTheme.validated.style  // 앱 전체
  → validatedStyle                      // 인스턴스
```

여기서 정해진 `validatorHintStyle`은 메시지 줄(ValidatorHint)에 인스턴스 값으로 넘어갑니다.

```text
CoreValidatorHintStyle 기본값 (defaultsByType · default*)
  → CoreComponentTheme.validatorHint.style  // 앱 전체
  → 위에서 정해진 validatorHintStyle        // Validated가 넘긴 값
```

- Validated가 메시지 글자 역할로 `bodySmall`을 넘기므로, `validatorHint` 테마의 `messageTextStyle`에 다른 글자 역할을 적어도 Validated 안에서는 `bodySmall`로 그립니다. 바꾸려면 `validatedStyle.validatorHintStyle`이나 `validated` 테마에 적습니다.
- 메시지의 색은 `accentColor`로만 바뀝니다. `messageTextStyle`과 `iconStyle`에 준 색은 덮입니다.
- `accentColor`는 하나라, 지정하면 `valid`와 `invalid` 메시지가 같은 색이 됩니다.

<a id="접근성-accessibility"></a>

## 접근성

Validated는 자기 역할을 갖지 않습니다. 알림은 안의 메시지 줄이, 필드의 오류 표시는 필드가 맡습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | Validated는 `Semantics`를 만들지 않습니다. 메시지 줄은 ValidatorHint가 자기 시맨틱 노드로 두고 live region으로 표시합니다. |
| Jaspr Web | 래퍼 `<div>`에는 `role` · `aria-*`가 없습니다. 필요하면 `attributes`로 직접 줍니다. 메시지 줄은 `<p>`이고 `invalid`면 `role="alert"`, `valid`면 `role="status"`입니다. |

### 키보드

없음. 처리하는 키가 없습니다. 감싼 필드의 키보드 동작은 그대로입니다.

### 스크린 리더

읽히는 것은 `message`의 글자입니다. 아이콘은 숨깁니다(Flutter `ExcludeSemantics`, Jaspr Web `aria-hidden="true"`). "오류" · "성공" 같은 말은 덧붙지 않으므로, 결과를 문장에 담으세요.

| 상태 | 메시지 줄의 알림 | 감싼 TextField |
| --- | --- | --- |
| `pending` | 메시지 줄이 없습니다. | 추가로 알리는 것이 없습니다. |
| `valid` | Flutter live region · Jaspr Web `role="status"` | 추가로 알리는 것이 없습니다. |
| `invalid` | Flutter live region · Jaspr Web `role="alert"` | Jaspr Web만 `<input>`에 `aria-invalid="true"`를 붙입니다. |

메시지 줄은 필드와 설명 관계로 이어지지 않습니다. 필드에 포커스해도 메시지가 함께 읽히지 않습니다. Jaspr Web에서 이으려면 `message`로 `id`를 가진 요소를 넘기고, TextField의 `attributes`에 `aria-describedby`로 그 `id`를 줍니다. TextField는 `aria-*` 속성을 `<input>`에 붙입니다.

```dart
// Jaspr Web
Validated(
  state: CoreValidationState.invalid,
  message: span(id: 'nickname-message', [Text('이미 사용 중인 닉네임입니다.')]),
  child: TextField(
    label: '닉네임',
    attributes: {'aria-describedby': 'nickname-message'},
  ),
)
```

`message` 없이 `invalid`만 넘기면, Jaspr Web은 TextField의 `aria-invalid`만 남고 Flutter는 색만 바뀝니다.

### 포커스 관리

Validated는 포커스를 받지 않고 옮기지도 않습니다. `invalid`가 되어도 그 필드로 포커스를 옮기지 않으며, 포커스를 가두지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 오류 모양은 TextField가 자기 채움 · 테두리 · 링에 그립니다. TextArea · Checkbox · RadioGroup 같은 필드는 `invalid`에서도 모양이 그대로입니다. 틀을 따로 그리는 입력은 틀이 바뀌지 않아, PhoneInput은 보이는 변화가 없고 ChipInput은 틀 안의 입력 줄만 바뀝니다. |
| 공통 | 메시지가 필드와 이어지지 않습니다(`aria-describedby`나 그에 해당하는 시맨틱이 없습니다). |
| 공통 | 틀린 필드로 포커스를 옮기지 않습니다. |
| 공통 | `pending`은 넘긴 메시지를 알리지 않고 숨깁니다. |
| Flutter | 감싼 필드에 오류라는 시맨틱 값이 붙지 않습니다. |
| Flutter | `invalid` 안에서 연 팝오버 · 대화상자 · 토스트 안의 TextField까지 오류 모양이 됩니다. 감싼 필드가 아닌 입력에도 상태가 닿습니다. |
| Jaspr Web | 비활성 TextField는 비활성 모양으로 그리지만 `aria-invalid="true"`는 붙습니다. |
| Jaspr Web | 직접 만든 컴포넌트는 Validated의 상태를 읽을 수 없습니다. |

폼 제출 검증에 쓴다면 필드의 오류 표시, 설명 연결, 실패했을 때의 포커스 이동을 앱에서 확인하세요.

#### 색에만 기대지 않기

메시지 줄은 색과 아이콘 모양이 함께 결과를 말하지만, 필드의 오류 표시는 테두리와 포커스 링의 색뿐입니다. `liquidGlass` 서페이스 스타일에서는 대비를 높이는 설정을 켜지 않았다면 두 플랫폼 모두 쉬는 테두리가 보이지 않아, 포커스하기 전까지 필드에는 오류 표시가 없습니다. 그래서 `invalid`에는 메시지를 꼭 함께 넣으세요. 고대비 · 강제 색상처럼 모든 컴포넌트에 함께 걸리는 설정은 [전역 접근성 축](/accessibility)에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 상태를 내려보내고 배치하는 방식은 각 플랫폼을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 상태를 내려보내는 방법 | `Data<CoreValidationState>.inherit` — 직접 만든 위젯도 읽을 수 있습니다. | 패키지 안의 범위 컴포넌트 — `coui_web.dart`로 내보내지 않습니다. |
| 열린 팝오버 · 대화상자 | 상태가 닿습니다. | `CoUIWeb`의 오버레이 층에 띄운 패널에는 닿지 않습니다. |
| 필드 · 메시지 배치 | `Column`(`mainAxisSize.min` · `crossAxisAlignment.start`)과 `Gap` — 자식은 자기 폭으로 시작 쪽에 놓입니다. | `flex flex-col` `<div>`와 `Gap` — 폭을 직접 정하지 않은 자식은 래퍼 폭까지 늘어납니다. Flutter에서는 내용만큼만 차지하는 버튼도 여기서는 래퍼 폭까지 넓어집니다. 폭을 직접 정한 자식은 그 폭을 지킵니다. |
| 메시지 줄의 바깥 여백 | 없습니다. 필드와의 간격은 `Gap` 값(기본 4)입니다. | 메시지 줄이 `<p>`인데 그 여백을 킷이 지우지 않습니다. 킷의 Tailwind 설정은 초기화(preflight)를 끕니다. 앱이 브라우저 기본 스타일을 초기화하지 않으면 `<p>`의 위아래 여백이 `Gap` 값에 더해집니다([빠른 시작](/getting-started#설치)). |
| 감싼 TextField의 오류 알림 | 없습니다. | `<input>`에 `aria-invalid="true"` |
| 필드와 메시지 연결 | 앱에서 필드의 시맨틱을 직접 구성합니다. | 메시지 요소의 `id`를 TextField의 `aria-describedby`로 직접 줍니다. |
| 메시지 줄 알림 | live region | `role="alert"` · `role="status"` |
| 웹 전용 속성 | — | `id` · `classes` · `css` · `attributes` · `eventHandlers`(래퍼 `<div>`에 붙습니다) |

<a id="props"></a>
<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. `W`는 Flutter의 `Widget`, Jaspr Web의 `Component`입니다. 네 속성은 모두 생략할 수 있습니다.

### 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `state` | `CoreValidationState` | `pending` | 검증 결과. `pending` · `valid` · `invalid` 중 하나입니다. 감싼 필드에 내려가고 메시지의 모양을 정합니다. |
| `message` | `W?` | `null` | 필드 아래에 보일 메시지. `pending`이면 그리지 않습니다. |
| `child` | `W?` | `null` | 감싸는 필드. 비우면 필드 자리 없이 위 간격(기본 4)과 메시지 줄만 그립니다. 메시지를 그리지 않는 때(`pending`이거나 `message`가 없을 때)에는 보이는 것이 없습니다. |
| `validatedStyle` | `CoreValidatedStyle?` | `null` | 보이는 값 덮어쓰기 |

Jaspr Web은 루트 `<div>`에 그대로 붙는 `id` · `classes` · `css` · `attributes` · `eventHandlers`도 받습니다.

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreValidatedStyle patch)` | `validatedStyle`에 `patch`를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch`가 이깁니다. |
| `copyWith({state, message, child, validatedStyle, key})` | 바꾼 값으로 사본을 만듭니다. Jaspr Web은 `id` · `classes` · `css` · `attributes` · `eventHandlers`도 받습니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.validated` | `CoreValidatedTheme?` | 앱 전체 기본값. `style`(`CoreValidatedStyle?`) 하나를 가집니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreValidatedStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `validatorHintStyle` | `CoreValidatorHintStyle?` | Style of the `ValidatorHint` that shows the message under the field. Laid over [defaultValidatorHintStyle] and passed to it as is. |
| `fieldMessageGapStyle` | `CoreGapStyle?` | Gap between the wrapped child and the message, passed to the `Gap` that separates them. `null` defers to [defaultFieldMessageGapStyle]. |

<!-- STYLE_TABLE:END -->

## 관련 컴포넌트

<Cards columns="3">
<Card demo="validated/related-validator-hint" title="ValidatorHint">

필드 없이 아이콘이 붙은 검증 메시지 한 줄을 그립니다.

</Card>
<Card demo="validated/related-text-field" title="TextField">

`errorText`로 오류 모양과 문구를 함께 보입니다.

</Card>
<Card demo="validated/related-form-field" title="FormField">

라벨 · 설명 · 오류를 필드 하나로 묶고 폼 검증에 씁니다.

</Card>
</Cards>
