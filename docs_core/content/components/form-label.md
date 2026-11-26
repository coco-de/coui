---
title: FormLabel
description: 폼 입력 필드용 라벨 (필수 표시 옵션 포함)
category: form
platforms: [flutter, web]
related: [form-field, text-field, label, form, validator-hint]
tags: [form, label, field]
template: v2
source: form/form_label
---

# FormLabel

<a id="live-preview"></a>
<a id="사용법"></a>

## 플레이그라운드

속성을 바꿔 보며 라벨을 확인하고, 만들어진 코드를 복사하세요.

<Playground component="form-label" />

FormLabel 은 폼 입력의 이름을 보이는 라벨입니다. `isRequired` 를 켜면 라벨 뒤에 필수 표시(`*`)를 붙입니다. `isRequired` 와 `enabled` 는 라벨의 모습만 바꿉니다. 값이 비었는지 검사하지 않고, 입력을 비활성으로 만들지도 않습니다.

"직접 만든 필수 표시" 는 별표 대신 `requiredIndicator` 에 `Text('(필수)')` 를 넘깁니다. `isRequired` 가 켜져 있을 때만 보입니다. Jaspr Web 은 직접 넘긴 표시를 라벨에 간격 없이 붙여 그립니다([필수 표시](/components/form-label#필수-표시)).

[TextField](/components/text-field) · [TextArea](/components/text-area) · [FormField](/components/form-field) 는 자기 `label` 을 FormLabel 로 그립니다. 어떤 값을 넘기는지는 [관련 컴포넌트](/components/form-label#관련-컴포넌트)에 있습니다.

## 구조

라벨과, 필수일 때 뒤에 붙는 필수 표시로 이루어집니다.

<Anatomy demo="form-label/anatomy">
<AnatomyItem part="container" side="left" name="FormLabel">

라벨과 필수 표시를 가로로 놓는 한 줄입니다. Jaspr Web 에서는 `<label>` 요소입니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="label">

`label` 에 넘긴 위젯으로, 보통 `Text` 입니다. 글자 역할은 `size` 가 고르고, 색은 `onSurfaceVariant` 입니다.

</AnatomyItem>
<AnatomyItem select="[aria-hidden]" side="right" name="requiredIndicator">

`isRequired` 가 `true` 일 때만 그립니다. `requiredIndicator` 를 비우면 `error` 색 `*` 이고, 라벨과의 간격은 4 입니다.

</AnatomyItem>
</Anatomy>

## 필수 표시

왼쪽은 기본 별표, 오른쪽은 `requiredIndicator` 에 글자를 넘긴 모습입니다.

<Preview demo="form-label/required" />

| 항목 | 기본 `*` | 직접 넘긴 `requiredIndicator` |
| --- | --- | --- |
| 글자 모양 | 라벨과 같습니다 | `Text` 는 라벨의 글자 모양을 이어받습니다 |
| 색 | `requiredColor`, 비우면 `error` | `Text` 는 라벨 색을 이어받습니다. `requiredColor` 는 닿지 않습니다 |
| 라벨과의 간격 | `requiredIndicatorGapStyle`, 기본 4 | Flutter 는 같은 간격을 두고, Jaspr Web 은 간격 없이 붙입니다 |
| 보조 기술 | 읽지 않습니다 | 숨기지 않아 그대로 읽힙니다 |

```dart
FormLabel(
  label: Text('이메일'),
  isRequired: true,
  requiredIndicator: Text('(필수)'),
)
```

`isRequired` 가 `false` 면 `requiredIndicator` 를 넘겨도 그리지 않습니다. 필수 표시는 화면에 보이는 표시일 뿐입니다. 값이 비었는지는 [FormField](/components/form-field) 의 `validator` 같은 검증이 확인합니다.

## 크기

`size` 는 라벨의 글자 역할만 고릅니다. `xs` · `sm` · `md` 는 `labelMedium`, `lg` · `xl` · `xl2` 는 `labelLarge` 입니다. 기본 별표는 라벨과 같은 글자라 함께 바뀌고, 색과 간격은 모든 크기에서 같습니다.

<SizeSpec component="form-label" label="이메일" props="isRequired=true" />

[TextField](/components/text-field) 는 자기 `size` 를 라벨에 그대로 넘깁니다. 직접 놓는 라벨에도 옆 입력의 `size` 를 주면 TextField 의 라벨과 같은 글자가 됩니다.

<a id="동작-스펙-behavior"></a>

## 상태

<Preview demo="form-label/states" />

| 항목 | 동작 |
| --- | --- |
| 기본 | 라벨 글자는 `onSurfaceVariant` 입니다. 라벨은 입력의 이름이라, 입력한 값이 더 도드라지게 읽히도록 한 단계 옅게 둡니다. |
| 필수 | `isRequired: true` 면 라벨 뒤에 필수 표시를 붙입니다. 값을 검사하지는 않습니다. |
| 비활성 | `enabled: false` 면 라벨 글자와 기본 `*` 가 `disabledColor`(기본 `disabledContent`)가 됩니다. `labelStyle` 에 준 색도 덮습니다. 색을 정하지 않은 직접 만든 표시(`Text('(필수)')`)는 라벨 색을 이어받아 함께 바뀝니다. 라벨 위젯이나 표시가 스스로 정한 색(`Text('이메일').onPrimaryContainer`)은 남습니다. |
| 상호작용 | hover · 눌림 · 포커스 상태가 없습니다. 값과 `onChanged` 같은 컴포넌트 콜백도 없습니다. Jaspr Web 의 `eventHandlers` 는 `<label>` 에 DOM 이벤트 처리기를 붙일 뿐입니다. |
| 입력과의 관계 | 라벨의 `enabled` 는 입력에 전해지지 않습니다. 직접 놓은 라벨이라면 입력에도 `enabled: false` 를 따로 줍니다. |

<Note>

[FormField](/components/form-field) 가 비활성이면 라벨 글자는 `onSurfaceSubtle` 이 되지만 필수 표시는 `error` 색 그대로입니다. FormField 가 안쪽 FormLabel 에 `enabled` 를 넘기지 않기 때문입니다.

[TextField](/components/text-field) 와 [TextArea](/components/text-area) 는 자기가 `enabled: false` 일 때 라벨과 `*` 를 함께 흐리게 그립니다. TextField 는 비활성 FormField · [Fieldset](/components/fieldset) 안에 있을 때도 그렇습니다. TextArea 의 라벨은 감싼 쪽의 비활성 상태를 따르지 않습니다. 비활성 FormField 안에서는 활성 색 그대로이고, 비활성 Fieldset 안에서는 묶음 전체가 반투명해질 뿐 라벨 색은 바뀌지 않습니다.

</Note>

<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

폼 입력의 이름을 화면에 보일 때 씁니다. `label` 속성이 있는 입력은 그 속성을 쓰고, FormLabel 은 `label` 속성이 없는 입력(Slider · ToggleGroup 등)이나 직접 만든 입력 위에 놓습니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| `label` 속성이 있는 입력의 라벨 | 그 입력의 `label` — [TextField](/components/text-field) · [TextArea](/components/text-area) · [Select](/components/select) 는 `required` 도 받습니다 |
| 라벨 · 도움말 · 오류 · 검증을 한 필드로 묶을 때 | [FormField](/components/form-field) |
| 아이콘을 붙인 정적 라벨 | [Label](/components/label) |
| 여러 입력을 묶은 제목 | [Fieldset](/components/fieldset) |

### 필수 표시와 라벨 자리

<a id="do"></a>
<a id="dont"></a>

<Cards columns="2">
<Card demo="form-label/do-is-required" tone="do" eyebrow="이렇게 하세요">

필수 칸은 `isRequired` 로 표시합니다. 별표가 `error` 색이 되고, 보조 기술은 별표를 읽지 않습니다.

</Card>
<Card demo="form-label/dont-typed-asterisk" tone="dont" eyebrow="이렇게 하지 마세요">

별표를 라벨 글자에 직접 적지 않습니다. 라벨과 같은 색이 되고, 보조 기술에는 별표까지 라벨 글자로 전해집니다.

</Card>
<Card demo="form-label/do-field-label" tone="do" eyebrow="이렇게 하세요">

TextField 에는 `label` 과 `required` 를 넘깁니다. 라벨의 크기와 비활성 색이 입력을 따라갑니다. 그림은 비활성 TextField 입니다.

</Card>
<Card demo="form-label/dont-separate-label" tone="dont" eyebrow="이렇게 하지 마세요">

FormLabel 을 따로 올려 두면 `size` 와 `enabled` 를 손으로 맞춰야 합니다. 그림은 입력만 비활성이라 라벨이 활성처럼 보입니다.

</Card>
</Cards>

## 배치

좁은 자리의 긴 라벨은 줄을 바꿉니다.

<Preview demo="form-label/layout" />

| 항목 | 동작 |
| --- | --- |
| 폭 | 부모가 폭을 늘리지 않으면 내용만큼 차지합니다. |
| 방향 | 라벨 다음에 필수 표시를 가로로 놓고 세로 가운데를 맞춥니다. 오른쪽에서 왼쪽으로 쓰는 언어에서는 좌우가 바뀝니다. |
| 긴 라벨 | 줄을 바꿉니다. 필수 표시는 여러 줄 라벨의 세로 가운데에 놓입니다. |
| 줄 수 제한 | FormLabel 에는 속성이 없습니다. `label` 에 넘기는 `Text` 의 `maxLines` · `overflow` 로 정합니다. `overflow` 의 타입은 Flutter 가 `TextOverflow`, Jaspr Web 이 `CoreTextOverflow` 입니다. |
| Flutter 의 `Row` 안 | `Row` 는 자식의 폭을 제한하지 않아 긴 라벨이 줄을 바꾸지 않습니다. `Flexible` 이나 `Expanded` 로 감쌉니다. |
| 입력과의 간격 | FormLabel 은 바깥 여백을 두지 않습니다. 직접 놓을 때는 [Gap](/components/gap) 을 둡니다. 참고로 FormField 는 8 을, TextField 와 TextArea 는 `md` 이하에서 6, `lg` 이상에서 8 을 기본으로 둡니다. |

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

FormLabel 의 겉모습은 `formLabelStyle`(`CoreFormLabelStyle`) 하나로 바꿉니다. 필드는 라벨 글자(`labelStyle`), 필수 표시의 색(`requiredColor`)과 간격(`requiredIndicatorGapStyle`), 비활성 색(`disabledColor`)입니다. variant 는 없습니다.

<Split>

<Code language="dart" title="라벨 하나만 바꾸기">
FormLabel(
  label: Text('이메일'),
  isRequired: true,
  formLabelStyle: CoreFormLabelStyle(
    requiredColor: CoreColor.token(CoreColors.tertiary),
    requiredIndicatorGapStyle: CoreGapStyle(size: CoreSpace.space8),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    formLabel: CoreFormLabelTheme(
      style: CoreFormLabelStyle(
        requiredColor: CoreColor.token(CoreColors.tertiary),
      ),
    ),
  ),
)
</Code>

</Split>

### 값이 정해지는 순서

```text
size 의 라벨 글자(labelMedium · labelLarge, onSurfaceVariant)와 default*
  → CoreComponentTheme.formLabel.style   // 앱 전체
  → formLabelStyle                       // 라벨 하나
  → enabled: false 면 라벨과 기본 별표의 색은 disabledColor
```

뒤로 갈수록 우선합니다. `labelStyle` 은 크기의 기본값 위에 얹힙니다. 색만 주면 크기에 맞는 글자 역할이 남고, 글자 역할을 주면 모든 크기에서 그 역할을 씁니다.

앱 전체 값은 다른 컴포넌트가 안에서 그리는 라벨에도 닿습니다. 다만 그 컴포넌트가 직접 넘기는 값이 앞섭니다.

| 라벨을 그리는 컴포넌트 | 앱 전체 값보다 앞서는 것 |
| --- | --- |
| TextField | `textFieldStyle.labelStyle`(지정했을 때), 비활성 색 `labelDisabledColor`(늘 넘깁니다) |
| TextArea | `textAreaStyle.labelStyle`(지정했을 때), 비활성 색 `labelDisabledColor` 와 필수 표시 색 `requiredMarkColor`(둘 다 늘 넘깁니다) |
| FormField | `formFieldStyle.formLabelStyle`(지정했을 때). 비활성일 때는 FormField 의 비활성 라벨 색(`disabledFormLabelStyle`, 기본 `onSurfaceSubtle`)도 앞섭니다. `formLabelStyle` 의 `labelStyle` 에 색을 줬으면 비활성에서도 그 색입니다. FormField 는 FormLabel 을 비활성으로 만들지 않으므로 `disabledColor` 는 쓰이지 않습니다. |

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `FormLabel` 에 `withStyle` 로 스타일을 덧붙일 수 있습니다. 생성자의 `formLabelStyle` 과 같게 동작하고, 겹치는 필드는 뒤에 붙인 값이 이깁니다.

<Preview component="form-label" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class FormLabelChainExample extends StatelessWidget {
  const FormLabelChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FormLabel(
      label: const Text('이메일'),
      isRequired: true,
    ).withStyle(
      const CoreFormLabelStyle(
        labelStyle: CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        requiredColor: CoreColor.token(CoreColors.tertiary),
        requiredIndicatorGapStyle: CoreGapStyle(size: CoreSpace.space12),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class FormLabelChainExample extends StatelessComponent {
  const FormLabelChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return FormLabel(
      label: Text('이메일'),
      isRequired: true,
    ).withStyle(
      const CoreFormLabelStyle(
        labelStyle: CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        requiredColor: CoreColor.token(CoreColors.tertiary),
        requiredIndicatorGapStyle: CoreGapStyle(size: CoreSpace.space12),
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

FormLabel 은 이름을 글자로 보일 뿐, 놓는 것만으로는 입력의 이름이 되지 않습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 의미 정보(`Semantics`)를 붙이지 않습니다. 라벨 글자는 일반 글자로 남습니다. |
| Jaspr Web | 네이티브 `<label>` 요소입니다. 컴포넌트는 `for` · `role` · `aria-*` 를 이 요소에 붙이지 않습니다. 기본 별표를 담은 `<span>` 에만 `aria-hidden="true"` 를 붙입니다. |

### 키보드

없습니다. 처리하는 키가 없고 `Tab` 순서에도 들어가지 않습니다. 라벨을 눌러도 포커스가 옮겨 가지 않습니다. Jaspr Web 에서 `for` 로 네이티브 입력에 직접 연결한 라벨은 브라우저가 누름을 그 입력에 전합니다.

### 스크린 리더

- 라벨 글자를 읽습니다.
- 입력의 접근 가능한 이름은 입력 쪽에서 따로 정해야 합니다. TextField · TextArea 의 `label` 속성으로 그린 라벨도 두 플랫폼 모두 입력의 이름으로 연결되지 않습니다.
- 기본 `*` 는 읽지 않습니다(Flutter 는 `ExcludeSemantics`, Jaspr Web 은 `aria-hidden="true"`). 직접 넘긴 `requiredIndicator` 는 숨기지 않아 그대로 읽힙니다. 장식으로만 쓰는 표시라면 직접 숨기세요.
- `isRequired` 와 `enabled` 는 알리지 않습니다. 필수와 비활성은 입력 쪽에도 알려야 합니다. FormField 의 `required: true` 는 Jaspr Web 의 필드 그룹에 `aria-required` 를 붙이지만, `group` 은 이 속성을 지원하는 역할이 아니라 읽지 않을 수 있습니다. Flutter 의 FormField 는 필수 여부를 알리지 않습니다.

#### 입력에 이름 연결하기

[FormField](/components/form-field) 의 `label` 도 FormLabel 로 그립니다. Jaspr Web 은 필드 그룹의 `aria-labelledby` 가 이 라벨을 가리키고, Flutter 는 같은 글자를 필드 그룹의 `Semantics.label` 로 둡니다. 두 경우 모두 이름이 붙는 곳은 필드 그룹이고, Jaspr Web 의 입력 요소 자체에는 붙지 않습니다.

Jaspr Web 에서 TextField 의 입력에 직접 이름을 주려면, FormLabel 에 `id` 를 주고 TextField 의 `attributes` 로 `aria-labelledby` 를 넘깁니다. `aria-*` 속성은 안쪽 `<input>` 에 붙고, 숨긴 별표는 이름에서 빠집니다. 필수라는 것은 TextField 의 `required: true` 가 `<input>` 의 `required` 속성으로 알립니다. 이 방법으로는 라벨을 눌러도 입력에 포커스가 가지 않습니다.

```dart
// Jaspr Web
div(classes: 'flex flex-col', [
  FormLabel(id: 'email-label', label: Text('이메일'), isRequired: true),
  const Gap.space6(),
  TextField(
    required: true,
    attributes: {'aria-labelledby': 'email-label'},
  ),
])
```

`attributes: {'for': 'email'}` 을 넘기면 `<label>` 에 `for` 가 붙습니다. 브라우저는 그 `id` 를 가진 네이티브 입력 요소가 있어야 둘을 잇습니다. TextField 와 TextArea 의 `id` 는 바깥 상자에 붙고, 안쪽 입력의 `id` 를 정하는 속성은 없습니다. TextField 는 FormField 안이거나 `features` 가 있을 때만 안쪽 입력에 컴포넌트가 만든 `id` 를 답니다. 공개된 이름이 아니므로 `for` 연결에 쓰지 않습니다.

### 포커스 관리

없습니다. 포커스를 받지 않고, 옮기거나 가두지도 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | `isRequired` 와 `enabled` 는 모습만 바꾸고 보조 기술에 알리지 않습니다. |
| 공통 | 직접 넘긴 `requiredIndicator` 는 숨기지 않아 그대로 읽히고, `requiredColor` 가 닿지 않습니다. |
| 공통 | TextField · TextArea 의 `label` 로 그린 라벨도 입력의 이름으로 연결되지 않습니다. |
| 공통 | FormField 가 비활성이어도 안쪽 라벨의 필수 표시는 `error` 색 그대로입니다. |
| 공통 | TextArea 의 라벨은 감싼 FormField · Fieldset 의 비활성 상태를 따르지 않습니다. |
| Jaspr Web | 직접 넘긴 `requiredIndicator` 는 라벨에 간격 없이 붙습니다. `requiredIndicatorGapStyle` 은 기본 별표에만 적용됩니다. |
| Jaspr Web | `for` 를 스스로 붙이지 않고, TextField 와 TextArea 의 안쪽 입력을 `for` 로 연결하는 공개된 방법이 없습니다. `aria-labelledby` 는 TextField 에서는 안쪽 입력에 붙지만, TextArea 에서는 바깥 상자에 붙어 입력의 이름이 되지 않습니다. |
| Flutter | 라벨을 입력에 연결하는 수단이 없습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

두 플랫폼이 함께 쓰는 속성은 이름이 같습니다. 그리는 방식과 입력을 연결하는 방법이 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 그리는 방식 | `DefaultTextStyle` 안의 가로 `Row` | 가로 flex 인 `<label>` |
| 글자 모양 전달 | `DefaultTextStyle` 로 안쪽 `Text` 에 전합니다 | `<label>` 의 글자 클래스를 안쪽 `Text` 가 상속합니다 |
| `label` 인자 | 반드시 적습니다(`null` 가능) | 생략할 수 있습니다 |
| 직접 넘긴 `requiredIndicator` 의 간격 | 기본 별표와 같은 간격 | 간격 없음 |
| `requiredIndicatorGapStyle` | `Gap` 에 그대로 넘깁니다 | `size` 만 읽어 기본 별표의 앞 여백(`margin-inline-start`)으로 씁니다 |
| 기본 별표 숨김 | `ExcludeSemantics` | `aria-hidden="true"` |
| 입력 연결 | 수단이 없습니다 | `id` 와 TextField 의 `aria-labelledby`, 직접 만든 네이티브 입력에는 `attributes` 의 `for` |
| 라벨 누르기 | 아무 일도 없습니다 | `for` 로 연결했으면 브라우저가 입력에 전합니다 |
| FormField 의 `labelWidget` | FormLabel 안에 넣어 그립니다 | FormLabel 없이 받은 그대로 그립니다 |
| Web 전용 속성 | — | `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="props"></a>
<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. `W` 는 Flutter의 `Widget`, Web의 Jaspr `Component` 입니다.

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `W?` | 필수 (Web 은 `null`) | 라벨 콘텐츠. `null` 이면 필수 표시만 그립니다. |
| `requiredIndicator` | `W?` | `null` | 직접 만든 필수 표시. 비우면 `*` 입니다. `isRequired` 가 `false` 면 그리지 않습니다. |

### 상태와 형태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `isRequired` | `bool` | `false` | 라벨 뒤에 필수 표시를 붙입니다. 검사는 하지 않습니다. |
| `enabled` | `bool` | `true` | `false` 면 라벨과 기본 필수 표시를 비활성 색으로 그립니다. 입력에는 닿지 않습니다. |
| `size` | `CoreComponentSize` | `md` | 라벨의 글자 역할을 고릅니다. |
| `formLabelStyle` | `CoreFormLabelStyle?` | `null` | 보이는 값 덮어쓰기 |

### Web 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | `<label>` 의 `id`. 입력의 `aria-labelledby` 가 가리킬 수 있습니다. |
| `classes` | `String?` | `null` | `<label>` 에 덧붙이는 클래스 |
| `css` | `Styles?` | `null` | `<label>` 의 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | `<label>` 에 그대로 붙는 HTML 속성(`for` 등) |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | `<label>` 의 DOM 이벤트 |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreFormLabelStyle patch)` | `formLabelStyle` 에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다. |
| `copyWith({label, isRequired, …})` | 바꾼 값으로 사본을 만듭니다. Web 은 `id` · `classes` · `css` · `attributes` · `eventHandlers` 도 받습니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.formLabel` | `CoreFormLabelTheme?` | 앱 전체 기본값. `style: CoreFormLabelStyle?` 하나를 가집니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreFormLabelStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `labelStyle` | `CoreTextStyle?` | Label typography — role + colour. `null` → the size-keyed default in [defaultsBySize]. Overriding only the colour keeps the default role, and vice versa, because this override is laid over that size default. |
| `requiredColor` | `CoreColor?` | Override colour applied to the required indicator while enabled. |
| `requiredIndicatorGapStyle` | `CoreGapStyle?` | Gap between the label and the required indicator, passed to `Gap(gapStyle: …)` as is. Laid over the design-system default ([defaultRequiredIndicatorGapStyle]). |
| `disabledColor` | `CoreColor?` | Override colour applied to the label and the required indicator while `CoreFormLabelContract.enabled` is `false`. `null` → the design-system [defaultDisabledColor]. |

<!-- STYLE_TABLE:END -->

<Note>

표의 설명 가운데 아래 내용은 지금 동작이 더 좁거나 다릅니다.

- `requiredColor` 는 기본 `*` 에만 적용됩니다. 직접 넘긴 `requiredIndicator` 의 색은 바꾸지 않습니다.
- `requiredIndicatorGapStyle` 은 Flutter 에서만 `Gap` 에 그대로 넘어갑니다. Jaspr Web 은 `size` 만 읽어 기본 `*` 의 앞 여백으로 쓰고, 직접 넘긴 표시에는 적용하지 않습니다.
- `disabledColor` 는 라벨 글자와 기본 `*` 에 적용됩니다. 색을 정하지 않은 직접 만든 표시도 라벨 색을 이어받아 함께 바뀝니다. 스스로 색을 정한 표시나 라벨 위젯은 그 색이 남습니다.

</Note>

## 관련 컴포넌트

FormLabel 을 안에서 그리는 컴포넌트와, 라벨에 넘기는 값입니다.

| 컴포넌트 | 라벨에 넘기는 값 | 비활성일 때 |
| --- | --- | --- |
| [FormField](/components/form-field) | `label` · `labelMaxLines` · `labelOverflow` · `required` · `size` · `formFieldStyle.formLabelStyle`. Flutter 에서 `labelWidget` 을 주면 `label` 대신 그 위젯을 넣고, 줄 수 속성 둘은 쓰지 않습니다. | 라벨 글자만 `onSurfaceSubtle` 이 됩니다. 필수 표시는 `error` 색 그대로입니다. |
| [TextField](/components/text-field) | `label` · `labelMaxLines` · `labelOverflow` · `required` · `size` · 활성 여부 · `textFieldStyle` 의 `labelStyle` · `labelDisabledColor` | 라벨과 `*` 가 `labelDisabledColor`(기본 `onSurfaceSubtle`)가 됩니다. 비활성 FormField · Fieldset 안에 있을 때도 같습니다. |
| [TextArea](/components/text-area) | TextField 와 같은 속성(활성 여부는 TextArea 의 `enabled`)과 `textAreaStyle` 의 `labelStyle` · `labelDisabledColor` · `requiredMarkColor` | TextArea 가 `enabled: false` 일 때만 라벨과 `*` 가 `labelDisabledColor`(기본 `onSurfaceSubtle`)가 됩니다. 비활성 FormField · Fieldset 안에 두기만 해서는 라벨 색이 바뀌지 않습니다. |
| [Select](/components/select) | 트리거를 TextField 로 그려, `label` · `labelMaxLines` · `labelOverflow` · `required` · `size` · 활성 여부가 TextField 를 거쳐 같은 라벨이 됩니다. | TextField 와 같습니다. |
| [NumberInput](/components/number-input) | 필드를 TextField 로 그려, `label` · `size` · 활성 여부가 TextField 를 거쳐 같은 라벨이 됩니다. `required` 는 받지 않습니다. | TextField 와 같습니다. |

[Form](/components/form) 의 검증에 참여하는 필드는 FormField 로 만듭니다.

<Cards columns="3">
<Card demo="form-label/related-form-field" title="FormField">

라벨 · 도움말 · 오류 · 검증을 한 필드로 묶습니다.

</Card>
<Card demo="form-label/related-text-field" title="TextField">

`label` 과 `required` 를 주면 입력 위에 라벨을 그립니다.

</Card>
<Card demo="form-label/related-label" title="Label">

아이콘을 붙일 수 있는 정적 라벨입니다. FormLabel 과는 다른 컴포넌트입니다.

</Card>
</Cards>
