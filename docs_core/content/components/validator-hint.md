---
title: ValidatorHint
description: 폼 입력 아래에 놓는 검증 메시지 한 줄입니다. 심각도에 맞는 색과 아이콘으로 오류 · 경고 · 정보 · 성공 · 중립 문구를 보여 줄 때 씁니다.
category: form
platforms: [flutter, web]
related: [validated, form-control, form]
tags: [form, validation, message, hint]
template: v2
source: form/validator_hint
---

# ValidatorHint

<a id="live-preview"></a>
<a id="사용법"></a>

## 플레이그라운드

심각도(`type`)와 아이콘, 숨김을 바꿔 보며 힌트를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="validator-hint" />

`ValidatorHint`는 값을 검사하지 않습니다. 검사는 앱이 하고, 힌트를 보일지(`visible`)와 심각도(`type`)를 넘깁니다. `type`을 적지 않으면 `error`입니다.

## 구조

힌트는 앞자리 아이콘과 메시지를 한 줄에 놓습니다. 배경 · 테두리 · 안쪽 여백은 없고, 아이콘과 메시지는 같은 색을 씁니다. 메시지가 두 줄이 되면 아이콘은 두 줄의 세로 가운데에 옵니다.

<Anatomy demo="validator-hint/anatomy">
<AnatomyItem part="container" side="left" name="Container">

아이콘과 메시지를 한 줄에 놓습니다. 색을 따로 주지 않은 메시지 글자는 여기서 정한 색을 따릅니다.

</AnatomyItem>
<AnatomyItem part="leading" side="top" name="icon">

`type`마다 정해진 기본 아이콘(크기 16)입니다. `icon`을 넘기면 그 위젯이 대신합니다. 스크린 리더에는 숨깁니다.

</AnatomyItem>
<AnatomyItem part="label" side="right" name="message">

검증 메시지입니다. 글자는 `bodyXs`(크기 12 · 줄 높이 150%)이고, 아이콘과의 간격은 4입니다. `xs` · `sm` · `md` TextField의 도움말과 같은 글자 역할입니다(`lg` 이상 TextField의 도움말은 `bodySmall`).

</AnatomyItem>
</Anatomy>

### 앞자리 아이콘

`icon`은 기본 아이콘을 대신합니다. `Icon`에 색을 따로 주지 않으면 두 플랫폼 모두 힌트의 색을 따릅니다. Jaspr Web에서는 둘레의 아이콘 테마가 색을 정한 자리라면 그 색을 씁니다.

크기는 두 플랫폼이 다르게 정합니다. Flutter는 힌트의 아이콘 크기(16, `validatorHintStyle.iconStyle`에 크기를 주면 그 값)를 아이콘 테마로 내려 줍니다. Jaspr Web은 내려 주지 않아, 크기를 적지 않은 `Icon`은 둘레 아이콘 테마의 크기(`CoUIWeb` 바로 아래에서는 20)로 그려집니다. 두 플랫폼에서 같게 그리려면 `Icon`에 크기를 적습니다.

<Preview component="validator-hint" props="type=info;icon=lock" label="비밀번호는 암호화해 저장해요" />

```dart
ValidatorHint.info(
  message: Text('비밀번호는 암호화해 저장해요'),
  icon: Icon(
    LucideIcons.lock,
    iconStyle: CoreIconStyle(size: CoreIconSize.size16),
  ),
)
```

## Variant

`type` 하나가 색 · 기본 아이콘 · 스크린 리더에 알리는 방식을 함께 정합니다. 기본값은 `error`입니다.

<VariantRow name="error" component="validator-hint" props="type=error" label="다시 입력해 주세요">

값이 거부됐을 때 씁니다. 기본값입니다.

</VariantRow>

<VariantRow name="warning" component="validator-hint" props="type=warning" label="곧 만료됩니다">

문제가 될 수 있어 주의가 필요할 때 씁니다.

</VariantRow>

<VariantRow name="info" component="validator-hint" props="type=info" label="대소문자를 구분해요">

알아 두면 좋은 안내에 씁니다.

</VariantRow>

<VariantRow name="success" component="validator-hint" props="type=success" label="사용할 수 있어요">

검증을 통과했을 때 씁니다.

</VariantRow>

<VariantRow name="neutral" component="validator-hint" props="type=neutral" label="8자 이상">

심각도가 없는 줄입니다. 아직 채우지 않은 규칙이나 정해진 규칙을 그냥 적어 둘 때 씁니다. 스크린 리더에 따로 알리지 않습니다.

</VariantRow>

| `type` | 색 | 기본 아이콘 |
| --- | --- | --- |
| `error` | `error` | `circle-alert` |
| `warning` | `warning` | `triangle-alert` |
| `info` | `info` | `info` |
| `success` | `success` | `circle-check-big` |
| `neutral` | `onSurfaceVariant` | `circle-dashed` |

<Note>

`type`마다 이름 있는 생성자가 있습니다: `ValidatorHint.error` · `ValidatorHint.warning` · `ValidatorHint.info` · `ValidatorHint.success` · `ValidatorHint.neutral`. 기본 생성자에 그 `type`을 넘기는 것과 같고, 코드에서 의도가 바로 읽힙니다.

</Note>

<a id="동작-스펙-behavior"></a>

## 상태

hover · 눌림 · 포커스 · 비활성 같은 조작 상태는 없습니다. 무엇을 그릴지는 `visible`과 `type`이 정합니다.

| 항목 | 동작 |
| --- | --- |
| `visible: true` (기본) | 아이콘과 메시지를 그립니다. |
| `visible: false` | 아이콘 · 메시지를 그리지 않고 알림도 없습니다. Flutter는 크기 0인 위젯을 두고, Jaspr Web은 아무것도 그리지 않습니다. |
| 전환 | 나타나거나 사라질 때는 두 플랫폼 모두 애니메이션이 없습니다. `type`이 바뀌면 Flutter는 바로 바뀌고, Jaspr Web은 색이 이어서 바뀔 수 있습니다([플랫폼 차이](#플랫폼-차이)). |
| 검증과 콜백 | 값을 검사하지 않고, 상태를 바꾸는 콜백도 없습니다. 필드 값과 보임 여부는 앱이 관리합니다. |

### 규칙 목록

비밀번호 조건처럼 여러 줄을 나란히 둘 때는 아직 채우지 않은 규칙을 `neutral`, 채운 규칙을 `success`로 둡니다. 두 기본 아이콘(`circle-dashed` · `circle-check-big`)은 둘 다 원 모양이라 한 열에 놓아도 모양이 이어집니다.

<Preview demo="validator-hint/checklist" />

```dart
ValidatorHint(
  type: isLongEnough
      ? CoreValidatorHintType.success
      : CoreValidatorHintType.neutral,
  message: Text('8자 이상'),
)
```

<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

입력한 값의 검증 결과를 필드 가까이에 한 줄로 보여 줄 때 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| TextField 하나의 오류를 보여 줄 때 | [TextField](/components/text-field)의 `errorText` |
| 라벨 · 도움말 · 오류를 한 필드로 묶을 때 | [FormField](/components/form-field) |
| 감싼 TextField의 모양까지 오류로 바꾸면서 메시지를 붙일 때(모양이 바뀌는 범위는 [상태 전파](/components/validated#상태-전파)) | [Validated](/components/validated) |
| 규칙별 충족 여부를 배지 모양으로 보여 줄 때 | [ValidationBadge](/components/validation-badge) |
| 입력 값이 아닌 일(예: 저장)이 실패했고, 보여 줄 내용은 남아 있을 때 | [Alert](/components/alert) |
| 불러오기에 실패해 그 자리에 보여 줄 내용이 없을 때 | [EmptyState](/components/empty-state) |

FormField · Validated · InputOtp는 자기 메시지 줄을 `ValidatorHint`로 그립니다. 이들에 문구를 넘기면(FormField의 `error`, Validated의 `message`, InputOtp의 `errorText`) 힌트를 따로 놓지 않아도 됩니다. 다만 Validated는 `message`와 함께 `state`를 `invalid`나 `valid`로 넘길 때만 그립니다. 기본값 `pending`이면 그리지 않습니다.

<a id="do"></a>
<a id="dont"></a>

### 문구와 type

<Cards columns="2">
<Card demo="validator-hint/do-type" tone="do" eyebrow="이렇게 하세요">

뜻에 맞는 이름 있는 생성자를 씁니다. 성공은 `ValidatorHint.success`입니다. `Alert.success`처럼 코드에서 의도가 바로 읽힙니다.

</Card>
<Card demo="validator-hint/dont-type" tone="dont" eyebrow="이렇게 하지 마세요">

`type`을 빼면 기본값이 `error`라, 성공 문구가 오류 색과 아이콘으로 그려집니다.

</Card>
<Card demo="validator-hint/do-wording" tone="do" eyebrow="이렇게 하세요">

무엇을 해야 하는지 문구에 적습니다. 스크린 리더에는 색과 아이콘이 전해지지 않습니다.

</Card>
<Card demo="validator-hint/dont-wording" tone="dont" eyebrow="이렇게 하지 마세요">

무엇이 틀렸는지 알 수 없는 문구는 색과 아이콘을 보지 못하는 사용자에게 도움이 되지 않습니다.

</Card>
<Card demo="validator-hint/do-pending" tone="do" eyebrow="이렇게 하세요">

아직 채우지 않은 규칙은 `neutral`로 둡니다. 알릴 일이 없는 줄이라 스크린 리더에 따로 알리지 않습니다.

</Card>
<Card demo="validator-hint/dont-pending" tone="dont" eyebrow="이렇게 하지 마세요">

`info`로 두면 입력하기 전부터 정보 안내처럼 보이고, 줄마다 스크린 리더에 알리는 영역이 됩니다.

</Card>
</Cards>

## 배치

필드 바로 아래에, 필드와 시작선을 맞춰 둡니다. 자기 오류 줄이 없는 컨트롤(예: Checkbox)에는 이렇게 직접 놓습니다.

<Preview demo="validator-hint/placement-checkbox" />

<Split>

<Code language="dart" title="Flutter">
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Checkbox(
      checked: agreed,
      onChanged: setAgreed,
      label: '약관에 동의합니다',
    ),
    ValidatorHint.error(
      visible: showError,
      message: Text('약관에 동의해 주세요.'),
    ),
  ],
)
</Code>

<Code language="dart" title="Jaspr Web">
div(classes: 'flex flex-col items-start', [
  Checkbox(
    checked: agreed,
    onChanged: setAgreed,
    label: '약관에 동의합니다',
  ),
  ValidatorHint.error(
    visible: showError,
    message: Text('약관에 동의해 주세요.'),
    classes: 'm-0',
  ),
])
</Code>

</Split>

<Note>

Jaspr Web의 힌트는 인라인 상자(`inline-flex`)라, 블록 부모에 여러 개를 이어 넣으면 한 줄에 붙습니다. 위처럼 부모를 세로 flex로 둡니다. Web 코드의 `classes: 'm-0'`은 힌트의 `<p>`에 남는 브라우저 문단 여백을 지웁니다. 앱이 이미 그 여백을 초기화했다면 없어도 됩니다([플랫폼 차이](#플랫폼-차이)). Flutter의 `Column(spacing:)`은 숨긴 힌트도 자식으로 세어 간격이 남습니다. 간격까지 없애려면 `visible` 대신 `if`로 목록에서 뺍니다.

</Note>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

종류와 내용(`type` · `visible` · `icon` · `message`)은 위젯 속성으로 넘기고, 색 · 글자 · 아이콘 크기 · 간격은 `validatorHintStyle`(`CoreValidatorHintStyle`) 하나로 덮어씁니다.

- `accentColor` — 아이콘과 메시지의 색입니다. 비우면 `type`의 색을 씁니다.
- `messageTextStyle` — 메시지 글자입니다. 기본 `bodyXs` 위에 합칩니다. 여기에 적은 색은 쓰이지 않으니 색은 `accentColor`로 바꿉니다.
- `iconStyle` — 아이콘의 크기입니다(16). 기본 아이콘에 적용되고, Flutter에서는 크기를 적지 않은 직접 넘긴 `icon`에도 적용됩니다. 여기에 적은 색은 쓰이지 않습니다.
- `iconLabelGapStyle` — 아이콘과 메시지 사이의 간격입니다(4). Jaspr Web은 `size`만 읽습니다.

<Split>

<Code language="dart" title="힌트 하나만 바꾸기">
ValidatorHint.warning(
  message: Text('비밀번호가 곧 만료됩니다.'),
  validatorHintStyle: CoreValidatorHintStyle(
    messageTextStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
    iconStyle: CoreIconStyle(size: CoreIconSize.size14),
    iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    validatorHint: CoreValidatorHintTheme(
      style: CoreValidatorHintStyle(
        iconStyle: CoreIconStyle(size: CoreIconSize.size14),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      ),
    ),
  ),
)
</Code>

</Split>

<Note>

테마(`CoreValidatorHintTheme.style`)에는 `type`별 자리가 없습니다. 여기에 `accentColor`를 적으면 다섯 `type`이 모두 그 색이 됩니다. 또 FormField · Validated는 메시지 글자 역할(`bodySmall`)을, InputOtp는 아이콘 크기(14)를 안쪽 힌트에 직접 넘기며, 이 값은 테마보다 우선합니다. 그래서 테마의 `messageTextStyle`에 다른 글자 역할(`CoreTextStyle.token(...)`)을 적으면, FormField · Validated의 힌트에서는 그 역할과 거기에 함께 적은 크기 · 줄 높이가 쓰이지 않습니다. 역할 없이 `fontSize`만 적은 값은 그 힌트에도 적용됩니다. 테마에 적은 아이콘 크기는 InputOtp의 힌트에 닿지 않습니다. 안쪽 힌트의 값은 `formFieldStyle.validatorHintStyle` · `validatedStyle.validatorHintStyle` · `inputOtpStyle.errorValidatorHintStyle`로 바꿉니다.

</Note>

### 빠른 오버라이드 (Chain)

이미 만든 `ValidatorHint`에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `validatorHintStyle` 인자와 같게 동작하고, 겹치는 값은 뒤에 붙인 것이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ValidatorHintChainExample extends StatelessWidget {
  const ValidatorHintChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ValidatorHint(
      message: const Text('비밀번호는 8자 이상이어야 합니다.'),
      type: CoreValidatorHintType.error,
    ).withStyle(
      const CoreValidatorHintStyle(
        accentColor: CoreColor.token(CoreColors.warning),
        messageTextStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
        iconStyle: CoreIconStyle(size: CoreIconSize.size16),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class ValidatorHintChainExample extends StatelessComponent {
  const ValidatorHintChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return ValidatorHint(
      message: Text('비밀번호는 8자 이상이어야 합니다.'),
      type: CoreValidatorHintType.error,
    ).withStyle(
      const CoreValidatorHintStyle(
        accentColor: CoreColor.token(CoreColors.warning),
        messageTextStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
        iconStyle: CoreIconStyle(size: CoreIconSize.size16),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

### 값이 정해지는 순서

```text
기본값 (defaultsByType[type] · defaultMessageTextStyle · defaultIconStyle · defaultIconLabelGapStyle)
  → CoreComponentTheme.validatorHint.style   // 앱 전체
  → validatorHintStyle                       // 인스턴스
```

뒤로 갈수록 우선합니다. `messageTextStyle` · `iconStyle` · `iconLabelGapStyle`은 안의 값 단위로 합쳐집니다. 메시지와 기본 아이콘의 색은 마지막에 `accentColor`(없으면 `type`의 색)로 정해집니다.

<a id="접근성-accessibility"></a>

## 접근성

`neutral`이 아닌 힌트에는 새로 나타난 줄을 스크린 리더가 알리도록 표시를 붙입니다. 얼마나 급하게 알릴지는 `type`이 정합니다.

### 역할

검증 메시지는 대개 사용자가 제출하거나 필드를 떠난 *뒤에* 나타나고, 그때 포커스는 옮겨지지 않습니다. 알림이 없으면 리더는 새로 생긴 줄을 읽을 이유가 없습니다(WCAG 3.3.1). `type`과 알림 방식의 대응은 `CoreValidatorHintType.toSemanticRole()` 한 곳에 있고 두 플랫폼이 같이 읽습니다.

| `type` | Jaspr Web | Flutter |
| --- | --- | --- |
| `error` | `role="alert"` — 읽던 문장을 끊고 알립니다 | live region |
| `warning` · `info` · `success` | `role="status"` — 차례를 기다려 알립니다 | live region |
| `neutral` | 역할 없음 | live region 아님 |

`neutral`은 아직 채우지 않은 규칙처럼 보고할 일이 없는 줄이라 알리지 않습니다. 알리면 화면을 열 때 대기 중인 규칙을 모두 읽게 됩니다. Flutter는 알리는지 아닌지만 표현하므로 급한 정도의 차이는 Jaspr Web에만 있습니다. 플랫폼이 주는 기능의 차이입니다.

Jaspr Web에서 `attributes`로 `role`을 넘기면 그 값이 이깁니다. Flutter는 힌트를 따로 된 시맨틱 노드(`container`)로 두어, live region이 감싼 필드 전체가 아니라 이 줄이 되게 합니다.

### 키보드

키 입력을 처리하지 않습니다. 보여 주기만 하는 컴포넌트라 누르거나 이동하는 키가 없습니다.

### 스크린 리더

읽히는 것은 `message`의 글자입니다. "오류" 같은 심각도를 알리는 말은 붙지 않습니다. `type`은 알림의 급함(위 표)과 색 · 아이콘으로만 나타나므로, 스크린 리더 사용자에게 `warning` 힌트와 `success` 힌트는 **문구로만 구분됩니다**.

아이콘 자리는 두 플랫폼 모두 숨깁니다 — Flutter는 `ExcludeSemantics`, Jaspr Web은 아이콘을 감싼 `<span>`의 `aria-hidden="true"`입니다. `icon`으로 넘긴 위젯도 같이 숨기므로, 이름이 필요한 그림이나 누를 수 있는 것은 `icon`에 두지 않습니다.

### 포커스 관리

포커스를 받지 않습니다 — `FocusNode`(Flutter)도 `tabindex`(Jaspr Web)도 없고 포커스 링도 그리지 않습니다. 힌트가 나타나거나 사라질 때 포커스를 옮기지도 않습니다. Tab 순서에 없으므로 키보드 사용자는 주변 글을 읽어 나가다 마주칩니다.

숨긴 힌트(`visible: false`)는 Flutter에서는 크기 0인 위젯으로 남고, Jaspr Web에서는 DOM에 없습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 심각도의 종류는 스크린 리더에 따로 전해지지 않습니다. 알려야 하면 문구에 담습니다(예: `'오류: 비밀번호는 8자 이상이어야 합니다.'`). |
| 공통 | 힌트는 설명하는 필드와 스스로 연결되지 않습니다. [FormField](/components/form-field)는 두 플랫폼 모두 자기 오류를 필드 묶음에 잇습니다. Flutter는 묶음 `Semantics`의 `hint`를 쓰고, Jaspr Web은 `role="group"` 묶음의 `aria-describedby`를 씁니다. |
| 공통 | 단독 힌트를 직접 이을 때 Jaspr Web에서는 힌트에 `id`를 주고 필드에 `aria-describedby`를 겁니다. Jaspr Web의 TextField는 `attributes`의 `aria-*` 값을 `<input>`에 붙입니다. Flutter 힌트에는 `id` 같은 연결 속성이 없어, 필드의 시맨틱을 앱에서 직접 구성합니다. |
| 공통 | `icon`을 직접 넘겨 여러 `type`에 같은 아이콘을 쓰면, 화면에서 `type`을 가르는 것은 색과 문구만 남습니다. Jaspr Web은 [색 강제 모드](/accessibility#고대비와-색-강제-모드)에서 색까지 시스템 색으로 합쳐질 수 있어, 이때는 문구만 남습니다. 기본 아이콘은 `type`마다 모양이 달라 색 없이도 가를 수 있습니다. |
| 공통 | 테마에 `type`별 자리가 없어, 테마의 `accentColor`는 모든 `type`의 색을 하나로 만듭니다. |
| Jaspr Web | 직접 넘긴 `icon`에는 힌트의 아이콘 크기가 내려가지 않습니다. 크기를 적지 않은 `Icon`은 `CoUIWeb` 바로 아래에서 20으로 그려져 Flutter(16)와 다르고, `validatorHintStyle.iconStyle`의 크기도 닿지 않습니다. |
| Jaspr Web | 가장 바깥 요소가 `<p>`라 `message` · `icon`에 `div` 같은 블록 요소를 넣지 않습니다. 서버가 낸 HTML에서는 브라우저가 `<p>`를 먼저 닫아 그 내용이 힌트 밖으로 나갑니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

속성 이름은 같고, 다음은 플랫폼마다 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 구조 | `Row`(`mainAxisSize: min`) 안의 아이콘과 `Flexible` 메시지 | `inline-flex` `<p>` 안의 아이콘 `<span>`과 메시지 |
| 숨김 | `SizedBox.shrink()` — 크기 0인 위젯이 남습니다 | 아무것도 그리지 않습니다 |
| 알림 | `error` · `warning` · `info` · `success`는 live region | `error`는 `alert`, `warning` · `info` · `success`는 `status` |
| `type`이 바뀔 때 | 색이 바로 바뀝니다 | `CoUIWeb`의 색 전환(`enableThemeAnimation`, 기본 켜짐)이 적용되어 색이 150ms 동안 바뀝니다. 동작 줄이기에서는 바로 바뀝니다 |
| 바깥 여백 | 없습니다 | 가장 바깥 `<p>`의 여백을 킷이 지우지 않습니다. 킷의 Tailwind 설정은 초기화(preflight)를 끄므로, 앱이 브라우저 기본 스타일을 초기화하지 않으면 위아래 문단 여백이 생겨 필드와의 간격이나 부모의 `gap`에 더해집니다([빠른 시작](/getting-started#설치)). `classes: 'm-0'`으로 지웁니다 |
| 직접 넘긴 `icon` | 힌트의 색과 아이콘 크기를 아이콘 테마로 내려 줍니다 | 둘레 아이콘 테마에 색이 없으면 힌트의 글자 색을 이어받습니다. 크기는 내려 주지 않습니다 |
| `iconLabelGapStyle` | `Gap`에 그대로 넘깁니다 | `size`만 아이콘 뒤 여백으로 씁니다 |
| `message` | `null`일 수 있지만 인자는 꼭 적습니다 | 생략할 수 있습니다 |
| 웹 속성 | – | `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="props"></a>
<a id="props-parameters"></a>

## API

`W`는 위젯 슬롯의 타입입니다 — Flutter는 `Widget`, Jaspr Web은 `Component`입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `message` | `W?` | Flutter: 필수 인자 / Web: `null` | 검증 메시지. 두 플랫폼에서 같이 쓰는 코드에는 적습니다. |
| `type` | `CoreValidatorHintType` | `CoreValidatorHintType.defaultType` (`error`) | `error` · `warning` · `info` · `success` · `neutral`. 색 · 기본 아이콘 · 알림 방식을 정합니다. |
| `visible` | `bool` | `true` | `false`면 아이콘과 메시지를 그리지 않습니다. |
| `icon` | `W?` | `null` | 기본 아이콘을 대신합니다. |
| `validatorHintStyle` | `CoreValidatorHintStyle?` | `null` | 보이는 값 덮어쓰기 |

이름 있는 생성자(`ValidatorHint.error` · `.warning` · `.info` · `.success` · `.neutral`)는 `type`을 받지 않고 그 값으로 정합니다. 나머지 인자는 같습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreValidatorHintTypeStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `accentColor` | `CoreColor` | Accent colour applied to the icon and message text. |

<!-- STYLE_TABLE:END -->

<Note>

위 표는 `type`별 기본값(`defaultsByType`) 한 항목의 필드입니다. `validatorHintStyle`에 넣는 `CoreValidatorHintStyle`의 네 필드는 [테마와 스타일](#테마와-스타일)에 있습니다.

</Note>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="validator-hint/related-form-field" title="FormField">

라벨 · 입력 · 도움말과 오류를 한 필드로 묶고, 오류 줄을 이 힌트로 그립니다.

</Card>
<Card demo="validator-hint/related-validated" title="Validated">

감싼 필드에 검증 상태를 넘기고, 아래 메시지를 이 힌트로 그립니다.

</Card>
<Card demo="validator-hint/related-validation-badge" title="ValidationBadge">

규칙별 충족 여부를 배지로 보여 줍니다.

</Card>
<Card component="alert" props="variant=destructive" label="저장하지 못했어요" title="Alert">

저장처럼 입력 값이 아닌 일이 실패했고 보여 줄 내용은 남아 있을 때 알립니다.

</Card>
</Cards>
