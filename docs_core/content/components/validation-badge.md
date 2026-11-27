---
title: ValidationBadge
description: 입력값 검증 규칙 하나의 대기 · 통과 · 실패를 아이콘과 글로 보여 주는 작은 배지입니다.
category: display
platforms: [flutter, web]
related: [status, text-field, form]
tags: [form, validation, feedback, password]
template: v2
source: display/validation_badge
---

# ValidationBadge

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

`ValidationBadge` 는 검증 규칙 하나의 결과를 아이콘과 글로 보여 줍니다. 비밀번호 조건이나 이메일 형식 같은 안내에 씁니다. 값을 검사하지는 않습니다. 앱이 검사하고 그 결과를 `state`(`pending` · `valid` · `invalid`)로 넘깁니다. 속성을 바꿔 보며 확인하고, 만들어진 코드를 복사하세요.

<Playground component="validation-badge" />

`상태 낱말` 은 `label` 뒤에 상태를 말하는 낱말을 붙입니다. 상태는 접근성 정보의 글에 저절로 들어가지 않으므로, 글로 전하려면 이렇게 적습니다([접근성](#접근성)). `아이콘 바꾸기` 는 지금 상태의 아이콘을 바꾸고, `테두리` 는 `borderWidth` 를 1 로 정합니다. 크기 선택지 `xs` · `sm` · `md` 는 차례로 `CoreValidationBadgeSize` 의 `extraSmall` · `small` · `medium` 입니다.

```dart
ValidationBadge(label: '8자 이상', state: CoreValidationState.valid)
```

Flutter와 Web 코드가 같습니다. `label` 과 `state` 는 꼭 넘겨야 합니다. `size` 를 주지 않으면 `small` 입니다.

## 구조

배지는 상자 하나에 상태 아이콘과 라벨을 한 줄로 담습니다.

<Anatomy demo="validation-badge/anatomy">
<AnatomyItem part="container" side="left" name="Container">

상태에 따라 칠이 달라지는 상자입니다. 높이는 크기마다 정해져 있고, 아이콘과 글을 세로 가운데에 둡니다. 테두리는 기본으로 그리지 않습니다.

</AnatomyItem>
<AnatomyItem part="leading" side="top" name="icon">

상태 아이콘입니다. 상태마다 기본 아이콘이 있고 `pendingIcon` · `validIcon` · `invalidIcon` 으로 바꿉니다. 아이콘을 빼는 파라미터는 없습니다.

</AnatomyItem>
<AnatomyItem part="label" side="right" name="label">

검증 규칙을 적는 `String` 입니다. 접근성 정보에 실리는 글도 이것뿐입니다. 기본은 한 줄이고, 넘치면 말줄임표로 자릅니다.

</AnatomyItem>
</Anatomy>

<a id="크기-sizes"></a>

## 크기

`size`(`CoreValidationBadgeSize`)는 `extraSmall` · `small`(기본) · `medium` 셋입니다.

<a id="medium-size"></a>

<SizeSpec component="validation-badge" props="state=valid" label="8자 이상" />

- 표의 첫 열 `xs` · `sm` · `md` 는 이 문서가 크기를 부르는 이름입니다. 코드에는 둘째 열의 이름을 씁니다.
- 높이는 고정값이고 내용은 그 안의 세로 가운데에 놓입니다. 폭은 내용을 따르며, 부모가 폭을 늘리면 늘어납니다([배치](#배치)).
- `medium` 은 `small` 보다 높이 · 좌우 여백 · 아이콘 · 간격 · 라벨 글자가 큽니다.
- 라벨의 글자 역할은 크기 순서대로 `labelXs` · `labelSmall` · `labelMedium` 입니다.
- `size` 는 위젯 파라미터로만 정합니다. 테마에는 크기 설정이 없습니다.

```dart
ValidationBadge(
  label: '대문자 포함',
  state: CoreValidationState.valid,
  size: CoreValidationBadgeSize.medium,
)
```

<a id="변형-variants"></a>
<a id="동작-스펙-behavior"></a>

## 상태

`ValidationBadge` 에는 `variant` 가 없습니다. 아이콘과 색은 `state`(`CoreValidationState`)가 정합니다.

<a id="pending"></a>

<VariantRow name="pending" component="validation-badge" props="state=pending;size=md" label="8자 이상">

입력하기 전이나 확인하기 전의 중립 상태입니다. `surfaceContainer` 칠에 `onSurfaceVariant` 색의 글자와 시계 아이콘(`LucideIcons.clock`)을 놓습니다.

</VariantRow>

<a id="default-valid"></a>

<VariantRow name="valid" component="validation-badge" props="state=valid;size=md" label="8자 이상">

규칙을 통과한 상태입니다. `successContainer` 칠에 `onSuccessContainer` 색의 글자와 체크 아이콘(`LucideIcons.check`)을 놓습니다.

</VariantRow>

<a id="invalid"></a>

<VariantRow name="invalid" component="validation-badge" props="state=invalid;size=md" label="8자 이상">

규칙을 통과하지 못한 상태입니다. `errorContainer` 칠에 `onErrorContainer` 색의 글자와 X 아이콘(`LucideIcons.x`)을 놓습니다.

</VariantRow>

### 상태를 정하는 방법

생성자에 `state` 를 직접 넘기거나, 팩토리 둘 중 하나를 씁니다.

| 방법 | 넘기는 값 | 정해지는 상태 |
| --- | --- | --- |
| `ValidationBadge(...)` | `state` | 넘긴 상태 |
| `ValidationBadge.fromBool` | `isValid` | `true` 면 `valid`, `false` 면 `invalid` 입니다. `pending` 은 만들지 않습니다. |
| `ValidationBadge.withPending` | `hasInput`, `isValid` | `hasInput` 이 `false` 면 `isValid` 와 관계없이 `pending` 입니다. `true` 면 `isValid` 에 따라 `valid` 나 `invalid` 입니다. |

아래는 입력하기 전과 `password` 를 입력한 때를 나눠 그린 그림입니다.

<Preview demo="validation-badge/with-pending" />

```dart
ValidationBadge.fromBool(label: '영문 대문자 포함', isValid: hasUpperCase)

ValidationBadge.withPending(
  label: '숫자 1개 이상',
  hasInput: password.isNotEmpty,
  isValid: hasNumber,
)
```

두 팩토리의 이름과 파라미터는 Flutter와 Web에서 같습니다. [Validated](/components/validated) 안에 놓아도 배지는 그 상태를 이어받지 않으므로 `state` 를 직접 넘깁니다.

### 인터랙션

- 표시 전용입니다. `onPressed` 가 없고 hover · pressed · focus · disabled 모양이 없습니다.
- 어느 상태도 움직이지 않습니다. `pending` 은 멈춘 시계 아이콘이며 돌아가는 진행 표시가 아닙니다. `pendingIcon` 에 `LucideIcons.loaderCircle` 같은 아이콘을 넣어도 돌지 않습니다. 확인하는 중임을 움직임으로 보여 주려면 [Loading](/components/loading) 을 곁에 둡니다.

### 상태 전환

`state` 를 바꿔 다시 그리면 전환 효과 없이 칠 · 글자색 · 아이콘이 바로 바뀝니다. `label` 은 앱이 바꾸지 않는 한 그대로입니다.

| 전환 | 바뀌기 전 | 바뀐 뒤 |
| --- | --- | --- |
| `pending` → `valid` | `surfaceContainer` 칠, 시계 | `successContainer` 칠, 체크 |
| `valid` → `invalid` | `successContainer` 칠, 체크 | `errorContainer` 칠, X |

### 아이콘 바꾸기

`pendingIcon` · `validIcon` · `invalidIcon` 은 각각 자기 상태에서만 쓰입니다. `fromBool` 은 `pending` 을 만들지 않아 `pendingIcon` 을 받지 않습니다. CoUI에 들어 있지 않은 아이콘을 쓸 때는 [플랫폼 차이](#플랫폼-차이)를 확인합니다.

<Preview demo="validation-badge/custom-icons" />

```dart
ValidationBadge(
  label: '충족',
  state: CoreValidationState.valid,
  validIcon: LucideIcons.circleCheck,
)
```

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 비밀번호를 정할 때 길이 · 대문자 · 숫자 같은 조건의 충족 여부를 입력에 맞춰 보여 줄 때
- 아이디나 이메일의 중복 확인 결과를 알릴 때
- 입력 필드 아래에 검증 규칙 여러 개를 목록으로 놓을 때
- 입력하는 동안의 검증 상태를 보여 줄 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 사람이나 시스템의 접속 · 운영 상태를 보여 줄 때 | [Status](/components/status) |
| 검증이 아닌 상태를 라벨로 적을 때 | [Badge](/components/badge) |
| 검증 메시지를 한 줄의 글로 보여 줄 때 | [ValidatorHint](/components/validator-hint) |
| 필드의 모양과 메시지를 같은 검증 상태로 맞출 때 | [Validated](/components/validated) |
| TextField 하나에 오류 문구를 붙일 때 | [TextField](/components/text-field)의 `errorText` |
| 폼을 보낸 뒤 전체 오류를 알릴 때 | [Banner](/components/banner) 또는 [Toast](/components/toast) |
| 아이콘 없이 오류 문구 글만 필요할 때 | [Text](/components/text) |

<a id="do"></a>
<a id="dont"></a>

### 이렇게 쓰세요

<Cards columns="2">
<Card demo="validation-badge/do-pending" tone="do" eyebrow="이렇게 하세요">

입력하기 전에는 `pending` 으로 둡니다. `withPending` 을 쓰면 `hasInput` 이 `true` 가 된 뒤에 `valid` 나 `invalid` 로 바뀝니다.

</Card>
<Card demo="validation-badge/dont-pending" tone="dont" eyebrow="이렇게 하지 마세요">

아직 입력하지 않았는데 모든 조건을 `invalid` 로 보이지 않습니다. 시작도 하기 전에 전부 실패한 것처럼 보여 부담을 줍니다.

</Card>
<Card demo="validation-badge/do-wording" tone="do" eyebrow="이렇게 하세요">

채워야 할 조건을 긍정형으로 적습니다. "대문자 미포함" 보다 "영문 대문자 포함" 이 분명합니다.

</Card>
<Card demo="validation-badge/dont-wording" tone="dont" eyebrow="이렇게 하지 마세요">

부정형 문장은 체크나 X와 함께 읽으면 통과했는지 헷갈립니다.

</Card>
<Card demo="validation-badge/do-count" tone="do" eyebrow="이렇게 하세요">

핵심 조건만 보입니다. 한 번에 5~6개 이내로 둡니다.

</Card>
<Card demo="validation-badge/dont-count" tone="dont" eyebrow="이렇게 하지 마세요">

조건을 한꺼번에 많이 늘어놓지 않습니다. 사용자의 읽는 부담이 커집니다.

</Card>
</Cards>

## 배치

### 조건 목록

규칙마다 배지 하나를 두고 위에서 아래로 쌓습니다. 아래는 `password` 를 입력한 때를 그린 그림입니다.

<Preview demo="validation-badge/checklist" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    ValidationBadge.withPending(
      label: '8자 이상',
      hasInput: password.isNotEmpty,
      isValid: password.length >= 8,
    ),
    Gap.space8(),
    ValidationBadge.withPending(
      label: '영문 대문자 포함',
      hasInput: password.isNotEmpty,
      isValid: hasUpperCase,
    ),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(
  classes: 'flex flex-col items-start gap-2',
  [
    ValidationBadge.withPending(
      label: '8자 이상',
      hasInput: password.isNotEmpty,
      isValid: password.length >= 8,
    ),
    ValidationBadge.withPending(
      label: '영문 대문자 포함',
      hasInput: password.isNotEmpty,
      isValid: hasUpperCase,
    ),
  ],
)
```

  </TabItem>
</Tabs>

<a id="조합-예제"></a>

### 입력 필드와 함께

[TextField](/components/text-field) 아래에 조건 목록을 놓습니다. 그림은 입력창을 읽기 전용으로 두어 배지가 바뀌지 않습니다. 앱에서는 `onChanged` 로 받은 값을 상태에 저장하고 다시 그립니다. 아래 코드의 `password` · `hasUpperCase` · `hasNumber` · `handlePasswordChange` 는 앱이 정합니다.

<Preview demo="validation-badge/with-field" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    TextField(
      label: '새 비밀번호',
      obscureText: true,
      onChanged: handlePasswordChange,
    ),
    Gap.space12(),
    ValidationBadge.withPending(
      label: '8자 이상',
      hasInput: password.isNotEmpty,
      isValid: password.length >= 8,
    ),
    Gap.space8(),
    ValidationBadge.withPending(
      label: '영문 대문자 포함',
      hasInput: password.isNotEmpty,
      isValid: hasUpperCase,
    ),
    Gap.space8(),
    ValidationBadge.withPending(
      label: '숫자 1개 이상',
      hasInput: password.isNotEmpty,
      isValid: hasNumber,
    ),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(
  classes: 'flex flex-col gap-3',
  [
    TextField(
      label: '새 비밀번호',
      obscureText: true,
      onChanged: handlePasswordChange,
    ),
    div(
      classes: 'flex flex-col items-start gap-2',
      [
        ValidationBadge.withPending(
          label: '8자 이상',
          hasInput: password.isNotEmpty,
          isValid: password.length >= 8,
        ),
        ValidationBadge.withPending(
          label: '영문 대문자 포함',
          hasInput: password.isNotEmpty,
          isValid: hasUpperCase,
        ),
        ValidationBadge.withPending(
          label: '숫자 1개 이상',
          hasInput: password.isNotEmpty,
          isValid: hasNumber,
        ),
      ],
    ),
  ],
)
```

  </TabItem>
</Tabs>

### 폭과 줄 수

<Preview demo="validation-badge/long-label" />

- 부모의 폭이 정해져 있으면 긴 라벨은 기본값에서 한 줄 말줄임표로 잘립니다.
- Flutter에서 `Row` 의 자식으로 바로 두면 배지에 폭 제한이 없어 긴 라벨이 줄지 않고 넘칩니다. `Flexible` 로 감쌉니다.
- 부모가 폭을 늘리면 배지도 늘어나고 내용은 앞쪽에 놓입니다. Flutter의 `Column(crossAxisAlignment: CrossAxisAlignment.stretch)` 나 세로 `ListView`, Web의 `align-items` 를 따로 정하지 않은 세로 flex 상자가 그렇습니다. 내용 폭으로 두려면 앞 맞춤(`CrossAxisAlignment.start` · `align-items: flex-start`)을 줍니다.
- `labelMaxLines` 를 늘려도 배지의 높이는 늘지 않습니다([알려진 제약](#알려진-제약)). 라벨은 한 줄에 들어갈 만큼 짧게 적습니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

### 파라미터와 스타일

- **위젯 파라미터** — `label`, `state`, `size`, `pendingIcon`, `validIcon`, `invalidIcon`, `labelMaxLines`, `labelOverflow`
- **상태별 색** — `style`(`CoreValidationBadgeStyle`)에 상태(`pending` · `valid` · `invalid`)마다 배경색(`…BackgroundColor`), 라벨 글자 스타일(`…LabelTextStyle`), 테두리 색(`…BorderColor`)이 있습니다.
- **모든 상태에 공통** — `style` 의 `borderWidth`, `iconStyle`, `iconLabelGapStyle`
- 높이 · 여백 · 모서리를 바꾸는 `style` 필드는 없습니다. 세 값은 `size` 의 단계가 정합니다.

글자색은 `…LabelTextStyle` 의 `color` 로 정합니다. `iconStyle` 에 색을 따로 주지 않으면 아이콘도 이 색을 따릅니다. Web에서 달라지는 경우는 [플랫폼 차이](#플랫폼-차이)에 있습니다. 테두리의 기본 굵기는 0 이라, 테두리 색은 `borderWidth` 를 0 보다 크게 주어야 보입니다. 기본 테두리 색은 `valid` 가 `success`, `invalid` 가 `error`, `pending` 이 `onSurfaceVariant` 이며 모두 불투명도 20% 입니다.

### 값이 정해지는 순서

뒤에 있을수록 우선합니다.

```text
defaultsBySize[size] + defaultsByState[state]   // 디자인 시스템 기본값
  → CoreValidationBadgeTheme.style              // 앱 전체
  → style                                       // 인스턴스별
```

- 크기 · 간격 · 라벨 글자 역할은 `defaultsBySize`, 상태별 색은 `defaultsByState` 가 정합니다.
- `…LabelTextStyle` 은 필드 단위로 합쳐집니다. 색만 바꿔도 크기의 글자 역할은 남습니다.
- 테마는 `style` 만 가집니다. `state` 와 `size` 는 바꾸지 않습니다.

### 사용 예

<Split>

<Code language="dart" title="한 배지의 pending 색 바꾸기">
ValidationBadge(
  label: '대문자 포함',
  state: CoreValidationState.pending,
  style: CoreValidationBadgeStyle(
    pendingBackgroundColor: CoreColor.token(CoreColors.infoContainer),
    pendingLabelTextStyle: CoreTextStyle(
      color: CoreColor.token(CoreColors.onInfoContainer),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체에 테두리 켜기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    validationBadge: CoreValidationBadgeTheme(
      style: CoreValidationBadgeStyle(
        borderWidth: CoreStrokeWidth.stroke1,
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다.

### 바탕과 서페이스 스타일

- `pending` 의 칠은 `surfaceContainer` 입니다. 같은 색으로 칠한 면 위에서는 상자 경계가 보이지 않고 아이콘과 글자만 보입니다. 그런 자리에서는 `pendingBackgroundColor` 를 바꾸거나 `borderWidth` 를 줍니다.
- 서페이스 스타일이 콘텐츠 면에 재질(반투명 · 흐림 같은 효과)을 정하면, 칠이 있는 배지도 그 재질을 따릅니다. 다만 Web에서 배경을 토큰이 아닌 색 값으로 직접 적으면 칠의 불투명도는 재질에 따라 바뀌지 않습니다. 배경을 투명하게 바꾼 상태에는 재질을 입히지 않습니다. 가장자리를 스스로 그리는 재질에서는 정한 테두리 색이 보이지 않을 수 있습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

`withStyle` 은 지금의 `style` 위에 넘긴 값을 합친 새 `ValidationBadge` 를 돌려줍니다. 같은 필드는 뒤에 적은 값이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ValidationBadgeChainExample extends StatelessWidget {
  const ValidationBadgeChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const ValidationBadge(
      label: '8자 이상',
      state: CoreValidationState.valid,
    ).withStyle(
      const CoreValidationBadgeStyle(
        validBackgroundColor: CoreColor.token(
          CoreColors.primary,
          opacity: CoreOpacity.opacity10,
        ),
        validBorderColor: CoreColor.token(CoreColors.primary),
        validLabelTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        borderWidth: CoreStrokeWidth.stroke2,
        iconStyle: CoreIconStyle(
          size: CoreIconSize.size16,
          color: CoreColor.token(CoreColors.primary),
        ),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class ValidationBadgeChainExample extends StatelessComponent {
  const ValidationBadgeChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const ValidationBadge(
      label: '8자 이상',
      state: CoreValidationState.valid,
    ).withStyle(
      const CoreValidationBadgeStyle(
        validBackgroundColor: CoreColor.token(
          CoreColors.primary,
          opacity: CoreOpacity.opacity10,
        ),
        validBorderColor: CoreColor.token(CoreColors.primary),
        validLabelTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        borderWidth: CoreStrokeWidth.stroke2,
        iconStyle: CoreIconStyle(
          size: CoreIconSize.size16,
          color: CoreColor.token(CoreColors.primary),
        ),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="접근성-accessibility"></a>

## 접근성

배지의 글은 `label` 하나입니다. 상태는 아이콘과 색으로 그리며, 접근성 정보의 글에는 저절로 들어가지 않습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 역할을 따로 지정하지 않습니다. 배지를 `Semantics(liveRegion: true)` 로 감쌉니다. 이름은 안의 `Text(label)` 에서 옵니다. |
| Jaspr Web | 루트 `<span>` 에 `role="status"`(암묵적 `aria-live="polite"`)를 붙입니다. `attributes` 에 다른 `role` 을 넘겨도 바뀌지 않습니다. 그 밖의 속성(`aria-*` 등)은 루트에 그대로 붙습니다. |

### 키보드

없음. 표시 전용이라 포커스를 받지 않고, 처리하는 키도 없습니다.

### 스크린 리더

- **읽히는 글** — `label` 문자열입니다. Flutter에서는 안의 `Text(label)` 이 접근성 정보의 이름이 됩니다. Web에서는 라벨 `<span>` 의 글이 영역의 내용입니다. `role="status"` 는 내용으로 이름을 만들지 않으므로 루트에 접근 가능한 이름이 따로 생기지는 않습니다.
- **상태 아이콘에는 대체 텍스트가 없습니다.** Flutter의 `Icon` 은 이름 없이 그립니다. Web의 기본 아이콘은 이름 · `role` · `aria-hidden` 이 없는 인라인 `<svg>` 이고, CoUI에 들어 있지 않은 아이콘으로 바꾸면 이름이 없는 `<iconify-icon>` 입니다.
- 그래서 `label` 이 같으면 `pending` · `valid` · `invalid` 가 접근성 정보에서 같은 글이 됩니다.

#### 상태가 바뀔 때

두 플랫폼 모두 배지를 live region 으로 둡니다. live region 은 영역의 글이 달라지는 것을 알리는 장치입니다. `state` 만 바뀌고 `label` 이 같으면 아이콘과 색은 달라져도 접근성 정보의 글은 그대로입니다. 이 전환이 말로 전해진다고 기대하지 마세요. 상태를 말하는 낱말을 `label` 에 넣으면 상태와 함께 글도 바뀝니다.

<Preview demo="validation-badge/state-words" />

```dart
ValidationBadge.fromBool(
  label: hasNumber ? '숫자 1개 이상 — 충족' : '숫자 1개 이상 — 미충족',
  isValid: hasNumber,
)
```

실제로 언제 무엇을 읽는지는 운영체제, 브라우저, 스크린 리더에 따라 다릅니다. 글을 담은 채 새로 나타난 live region 은 읽히지 않을 수도 있습니다. 꼭 알려야 하는 변화는 쓰는 환경에서 확인합니다.

#### 보이는 글은 두고 읽는 말만 바꾸기

Flutter에서는 `Semantics` 로 감싸 이름을 바꿀 수 있습니다. `excludeSemantics: true` 가 배지 안의 접근성 정보를 빼고 바깥의 `label` 을 대신 씁니다.

<Code language="dart" title="Flutter">
Semantics(
  container: true,
  liveRegion: true,
  label: hasNumber ? '숫자 1개 이상, 충족' : '숫자 1개 이상, 미충족',
  excludeSemantics: true,
  child: ValidationBadge.fromBool(label: '숫자 1개 이상', isValid: hasNumber),
)
</Code>

Web에서는 `attributes: {'aria-label': ...}` 가 루트에 그대로 붙습니다. 다만 live region 은 영역의 글을 알리므로 `aria-label` 만 바꾸면 알림이 없을 수 있습니다. 두 플랫폼에서 같은 방법을 쓰려면 상태를 `label` 에 적습니다.

#### 색에만 기대지 않기

기본 아이콘은 시계 · 체크 · X 로 모양이 서로 달라, 화면에서는 색 말고 모양으로도 세 상태를 가를 수 있습니다. 세 아이콘을 같은 모양으로 바꾸면 상태 차이는 색에 남습니다.

### 포커스 관리

없음. 오버레이가 아니고 포커스를 받지 않아, 포커스를 옮기거나 가두거나 되돌리지 않습니다.

### 알려진 제약

- 상태를 접근성 정보의 글에 넣어 주는 파라미터가 없습니다. 상태 아이콘의 대체 텍스트를 받는 파라미터도 없습니다.
- `state` 만 바뀌면 접근성 정보의 글은 달라지지 않습니다.
- live region 을 끄는 전용 파라미터가 없습니다. 배지마다 따로 live region 을 가지므로, 여러 배지의 라벨이 한 번에 바뀌면 각각이 알림 대상이 됩니다. 한 화면에 두는 배지 수를 줄이면 알림 대상도 줄어듭니다.
- 배지를 입력 필드와 잇는 전용 파라미터가 없습니다.
- 높이가 크기마다 고정이라, `labelMaxLines` 를 2 이상으로 주고 라벨이 두 줄이 되면 두 줄이 배지 안에 다 들어가지 않습니다. Flutter는 높이를 넘는 부분을 자릅니다(`labelOverflow` 가 `visible` 이면 자르지 않아 글이 배지 밖으로 벗어납니다). Web은 글이 칠의 위아래로 벗어납니다.
- Flutter의 배지 높이는 `theme.scaling` 을 따르고, 시스템의 글자 크기 설정(`MediaQuery.textScaler`)에 맞춰 늘지 않습니다. 글자를 크게 하면 라벨이 잘릴 수 있습니다.

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은
> [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

클래스 이름(`ValidationBadge`), 공통 파라미터, 기본값, 색 토큰, 기본 아이콘(`LucideIcons.clock` · `check` · `x`)은 두 플랫폼이 같습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 그리는 방법 | `Container` 안의 `Row` 에 `Icon`, `Gap`, `Flexible` 로 감싼 `Text` 를 놓습니다. | `<span role="status">` 안에 아이콘과 라벨 `<span>` 을 놓고, 둘 사이는 CSS `gap` 으로 띄웁니다. |
| 색을 칠하는 방법 | 색 토큰을 테마의 색으로 풀어 `BoxDecoration` 과 글자 스타일에 넣습니다. | 토큰 색은 클래스로, 직접 적은 색 값은 인라인 스타일로 붙입니다. |
| 아이콘 색 | `iconStyle` 에 색이 없으면 상태의 글자색입니다. 앱의 아이콘 테마 색은 배지 아이콘을 바꾸지 않습니다. | `iconStyle` 에 색이 없으면 배지의 글자색을 물려받습니다. `CoreComponentTheme.icon` 이나 바깥 `IconTheme` 에 색이 있으면 그 색을 씁니다. |
| CoUI에 들어 있지 않은 아이콘 | 캐시에 없으면 Iconify API에서 받아 오며, 그동안 아이콘 자리가 비어 있습니다. | `<iconify-icon>` 으로 그립니다. 페이지에 `iconScript()` 를 넣어야 보입니다. |
| `iconLabelGapStyle` | 스타일 전체를 `Gap` 에 넘깁니다. | `size` 만 적용합니다. |
| `labelOverflow` | `Text` 의 `TextOverflow` 가 됩니다. | `labelMaxLines` 나 `labelOverflow` 를 하나라도 주면 CSS line clamp 로 자릅니다. `fade` 의 흐림 효과가 없고, `visible` 로 두어도 넘친 부분은 가려집니다. |
| 높이를 넘는 여러 줄 | 높이를 넘는 부분이 잘립니다. `labelOverflow` 가 `visible` 이면 자르지 않아 글이 배지 밖으로 벗어납니다. | 글이 칠의 위아래로 벗어납니다. |
| 크기 배율 | 높이 · 여백 · 모서리 · 테두리 굵기 · 아이콘 · 간격에 `theme.scaling` 을 적용합니다. | 높이와 아이콘은 `rem` 이고, 여백 · 간격 · 모서리 · 테두리 굵기는 CSS 변수를 읽습니다. |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` 를 루트 `<span>` 에 붙입니다. |

<a id="props-parameters"></a>

## API

### 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String` | 필수 | 검증 조건을 적는 글 |
| `state` | `CoreValidationState` | 필수 | 검증 상태 — `pending`, `valid`, `invalid` |
| `size` | `CoreValidationBadgeSize?` | `null` (`small`) | 크기 — `extraSmall`, `small`, `medium` |
| `pendingIcon` | `IconName?` | `null` (`LucideIcons.clock`) | `pending` 상태의 아이콘 |
| `validIcon` | `IconName?` | `null` (`LucideIcons.check`) | `valid` 상태의 아이콘 |
| `invalidIcon` | `IconName?` | `null` (`LucideIcons.x`) | `invalid` 상태의 아이콘 |
| `labelMaxLines` | `int?` | `null` (1) | 라벨에 허용하는 줄 수. 배지의 높이는 늘지 않습니다. |
| `labelOverflow` | `CoreTextOverflow?` | `null` (`ellipsis`) | 넘친 라벨의 처리 — `clip`, `fade`, `ellipsis`, `visible`. Web의 차이는 [플랫폼 차이](#플랫폼-차이)에 있습니다. |
| `style` | `CoreValidationBadgeStyle?` | `null` | 이 인스턴스의 겉모습 덮어쓰기 |
| `key` | `Key?` | `null` | 위젯 · 컴포넌트의 키 |

### 팩토리와 복사

| 이름 | 반드시 넘기는 값 | 생성자와 다른 점 |
| --- | --- | --- |
| `ValidationBadge.fromBool` | `label`, `isValid` | `state` 와 `pendingIcon` 을 받지 않습니다. |
| `ValidationBadge.withPending` | `label`, `hasInput`, `isValid` | `state` 를 받지 않습니다. |

두 팩토리는 표에 적은 것 말고는 `key`, `labelMaxLines`, `labelOverflow`, `validIcon`, `invalidIcon`, `size`, `style` 을 받고, `withPending` 은 `pendingIcon` 도 받습니다. 웹 전용 속성은 받지 않습니다. 만든 인스턴스에서 값을 바꾼 새 배지가 필요하면 `copyWith` 를, 스타일만 덧붙이려면 `withStyle` 을 씁니다.

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트 `<span>` 의 id |
| `classes` | `String?` | `null` | 루트에 더하는 클래스 |
| `css` | `Styles?` | `null` | 루트에 더하는 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 루트의 HTML 속성. `role` 은 늘 `status` 입니다. |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 루트에 다는 DOM 이벤트 처리 함수 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreValidationBadgeStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `pendingBackgroundColor` | `CoreColor?` | Pending background color override. |
| `pendingLabelTextStyle` | `CoreTextStyle?` | Pending label text style override. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `pendingForegroundColor` field removed). `null` defers to [defaultPendingLabelTextStyle] over the per-size role from [defaultsBySize] `[size].labelStyle`. |
| `pendingBorderColor` | `CoreColor?` | Pending border color override. |
| `validBackgroundColor` | `CoreColor?` | Valid background color override. |
| `validLabelTextStyle` | `CoreTextStyle?` | Valid label text style override. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `validForegroundColor` field removed). `null` defers to [defaultValidLabelTextStyle] over the per-size role from [defaultsBySize] `[size].labelStyle`. |
| `validBorderColor` | `CoreColor?` | Valid border color override. |
| `invalidBackgroundColor` | `CoreColor?` | Invalid background color override. |
| `invalidLabelTextStyle` | `CoreTextStyle?` | Invalid label text style override. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `invalidForegroundColor` field removed). `null` defers to [defaultInvalidLabelTextStyle] over the per-size role from [defaultsBySize] `[size].labelStyle`. |
| `invalidBorderColor` | `CoreColor?` | Invalid border color override. |
| `iconLabelGapStyle` | `CoreGapStyle?` | Style of the gap between the icon and the label. `null` defers to [CoreValidationBadgeStyle.defaultsBySize] `[size].iconLabelGapStyle`. |
| `iconStyle` | `CoreIconStyle?` | Style of the state icon, passed to `Icon(iconStyle: …)`. `null` uses a base whose `size` comes from [CoreValidationBadgeStyle.defaultsBySize] `[size].iconSize` and whose `color` is the state's foreground colour. |
| `borderWidth` | `double?` | Border stroke width override (logical px). Overrides [defaultBorderWidth] when set. |

<!-- STYLE_TABLE:END -->

<Note>

`…LabelTextStyle` 의 `color` 는 `iconStyle` 에 색이 없으면 아이콘 색도 바꿉니다. `…BorderColor` 는 `borderWidth` 가 0 보다 클 때만 보이고, Flutter는 `borderWidth` 에 `theme.scaling` 을 곱해 그립니다. `iconStyle` 에 색이 없을 때 Web의 아이콘은 배지의 글자색을 물려받지만, 앱의 아이콘 테마나 바깥 `IconTheme` 에 색이 있으면 그 색을 씁니다. `iconLabelGapStyle` 은 Web에서 `size` 만 적용됩니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="validation-badge/related-validator-hint" title="ValidatorHint">

입력 아래에 놓는 검증 메시지 한 줄입니다. 자세한 내용은 [ValidatorHint](/components/validator-hint) 를 보세요.

</Card>
<Card demo="validation-badge/related-text-field" title="TextField">

배지와 함께 입력 검증 화면을 만드는 입력창입니다. 자세한 내용은 [TextField](/components/text-field) 를, 폼 전체의 검증 관리는 [Form](/components/form) 을 보세요.

</Card>
<Card demo="validation-badge/related-status" title="Status">

사람이나 시스템의 지금 상태를 작은 점으로 보여 줍니다. 검증 결과를 보여 주는 배지와 쓰임이 다릅니다. 자세한 내용은 [Status](/components/status) 를 보세요.

</Card>
<Card demo="validation-badge/related-badge" title="Badge">

검증이 아닌 상태 · 개수 · 분류를 짧게 적는 라벨입니다. 자세한 내용은 [Badge](/components/badge) 를 보세요.

</Card>
</Cards>
