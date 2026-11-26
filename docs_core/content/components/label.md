---
title: Label
description: 글자에 앞 아이콘과 필수 표시를 붙여 보이는 정적 라벨입니다. 놓는 것만으로는 입력과 연결되지 않습니다.
category: display
platforms: [flutter, web]
related: [form, form-field, fieldset, validation-badge]
tags: [form, label, text]
template: v2
source: display/label
---

# Label

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

앞 아이콘 · 필수 표시 · 비활성을 바꿔 보며 Label 을 확인하고, 만들어진 코드를 복사하세요.

<Playground component="label" />

Label 은 글자(`text`)를 보이고, 필요하면 앞 아이콘(`icon`)과 필수 표시(`*`)를 붙입니다. 폼 입력의 위나 옆에 놓는 이름 글자에 씁니다. Flutter 와 Jaspr Web 이 같은 `Label` 을 씁니다.

<Note>

Label 을 입력 옆에 놓아도 둘은 연결되지 않습니다. 라벨을 눌러도 입력에 포커스가 가지 않고, Label 은 자기 글자를 입력의 이름으로 지정하지 않습니다. 자세한 내용은 [입력과 연결하기](#입력과-연결하기)를 보세요.

</Note>

## 구조

가로 한 줄에 앞 아이콘 · 글자 · 필수 표시를 차례로 놓습니다. 글자는 늘 있고, 나머지는 선택 사항입니다.

<Anatomy demo="label/anatomy">
<AnatomyItem part="container" side="left" name="Label">

세 부분을 세로 가운데에 맞춰 가로로 놓습니다. Flutter 는 `Row`, Jaspr Web 은 `<span>` 입니다. 배경 · 테두리 · 안쪽 여백은 없습니다.

</AnatomyItem>
<AnatomyItem part="leading" side="top" name="icon">

`icon` 을 줄 때만 그립니다. 기본 크기는 16 이고, 글자와의 간격은 6 입니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="text">

라벨 글자입니다. 기본은 `labelLarge` 역할에 medium 굵기, `onSurface` 색입니다.

</AnatomyItem>
<AnatomyItem select="div + span:last-child" side="right" name="isRequired">

`isRequired: true` 일 때만 붙는 `*` 입니다. 기본 색은 `error` 이고, 글자와의 간격은 4 입니다.

</AnatomyItem>
</Anatomy>

## 내용 구성

variant 나 크기 속성은 없습니다. `icon` 과 `isRequired` 로 라벨에 담을 것을 고릅니다.

<Preview demo="label/content" />

```dart
// 글자만
const Label(text: '이메일')

// 필수 표시
const Label(text: '이메일', isRequired: true)

// 앞 아이콘
const Label(text: '이메일', icon: Icon(LucideIcons.mail))

// 비활성
const Label(text: '이메일', disabled: true)
```

### 아이콘

`icon` 은 `Widget`(Web 은 `Component`)을 받습니다. Label 은 그 안의 [Icon](/components/icon) 에 크기 16 을 내려 주고, 색은 라벨 글자색을 따르게 합니다.

| 정한 곳 | 결과 |
| --- | --- |
| 아무것도 정하지 않음 | 크기 16, 라벨 글자색. 비활성이면 비활성 글자색입니다. |
| `labelStyle` 의 `iconStyle.size` | 그 크기를 씁니다. `iconStyle` 에서 Label 이 읽는 값은 `size` 뿐입니다. |
| 넘긴 `Icon` 의 `iconStyle`, 또는 앱 테마의 `CoreComponentTheme.icon` | 여기서 정한 크기와 색이 Label 이 내려 주는 값보다 앞섭니다. 이렇게 정한 아이콘 색은 비활성에서도 그대로입니다. |

<Note>

Flutter 에서 테마의 `scaling` 이 1 이 아니면, Label 이 크기를 내려 준 아이콘에는 배율이 두 번 곱해집니다. 예를 들어 `scaling: 1.25` 면 크기 16 인 아이콘이 20 이 아니라 25 로 그려집니다. 간격에는 한 번만 곱해집니다. `Icon(LucideIcons.mail, iconStyle: CoreIconStyle(size: CoreIconSize.size16))` 처럼 아이콘에 크기를 직접 정하면 한 번만 곱해집니다.

</Note>

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 상태

<Preview demo="label/states" />

| 항목 | 동작 |
| --- | --- |
| 기본 | 글자와 아이콘은 `onSurface`, 필수 표시는 `error` 색입니다. |
| 필수 | `isRequired: true` 면 `*` 를 붙입니다. 값이 비었는지 검사하지는 않습니다. |
| 비활성 | `disabled: true` 면 글자 · `*` · 아이콘이 `disabledTextStyle` 의 색 하나(기본 `disabledContent`)를 따릅니다. 색을 직접 정한 [아이콘](#아이콘)은 그 색이 남습니다. 포인터를 올리면 Flutter 는 `forbidden` 커서를, Jaspr Web 은 `not-allowed` 커서를 보입니다. |
| 상호작용 | 표시 전용입니다. hover · 눌림 · 포커스 상태가 없고, 클릭이나 탭 콜백도 없습니다. |
| 감싼 묶음 | [FormField](/components/form-field) · [Fieldset](/components/fieldset) 의 비활성 설정을 읽지 않습니다. 그 안에 직접 놓은 Label 도 `disabled` 를 따로 줘야 비활성 색이 됩니다. 비활성 Fieldset 이 묶음 전체를 흐리게 그리면 Label 도 함께 흐려집니다. |

### 비활성일 때 쓰는 값

| 항목 | 동작 |
| --- | --- |
| 색 | `disabledTextStyle` 의 색을 바꾸면 글자 · `*` · 아이콘이 함께 바뀝니다. `requiredColor` 는 활성 상태에만 적용됩니다. 비활성 필드에 붉은 `*` 가 남으면 지금 입력해야 한다는 뜻으로 읽히기 때문입니다. |
| 글자 모양 | `disabledTextStyle` 은 `textStyle` 이 아니라 비활성 기본값 위에 얹힙니다. `textStyle` 로 글자 역할이나 굵기를 바꿨다면 `disabledTextStyle` 에도 같은 값을 줘야 비활성에서도 유지됩니다. |
| 투명도 | `disabledOpacity` 의 기본값은 1 입니다. 비활성 라벨은 전용 색을 쓰고 있어, 투명도를 더 곱하면 대비가 뒤의 배경에 따라 달라집니다. 더 흐리게 하려면 `labelStyle` 에서 낮춥니다. |

```dart
const Label(
  text: '이메일',
  disabled: true,
  labelStyle: CoreLabelStyle(
    textStyle: CoreTextStyle.token(CoreTextStyles.titleMedium),
    disabledTextStyle: CoreTextStyle.token(CoreTextStyles.titleMedium),
  ),
)
```

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 컨트롤이나 설정 항목의 위나 옆에 이름 글자를 놓을 때
- 필수 항목을 `*` 로 보여야 할 때
- 이름 글자 앞에 메일 · 사용자 같은 아이콘을 함께 보일 때
- 컨트롤이 비활성이라는 것을 이름 글자에도 보여야 할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 폼과 관계없는 일반 글자 | [Text](/components/text) |
| `label` 속성이 있는 입력의 라벨 | 그 입력의 `label` — [TextField](/components/text-field) 등 |
| 크기(`size`)에 맞춘 글자, 위젯으로 만드는 라벨, 좁은 자리에서 줄을 바꾸는 긴 라벨 | [FormLabel](/components/form-label) |
| 라벨 · 도움말 · 오류 · 검증을 입력과 한 필드로 묶을 때 | [FormField](/components/form-field). 라벨을 눌러 입력에 포커스를 옮겨 주지는 않습니다. |
| 여러 라벨과 입력에 공통 제목(`legend`)과 비활성 설정이 필요할 때 | [Fieldset](/components/fieldset) |
| 필드 이름이 아니라 검증 결과(통과 · 실패 · 대기)를 보일 때 | [ValidationBadge](/components/validation-badge) |

### 비활성과 필수 표시

`Label` 의 `disabled` 는 라벨의 모습만 바꿉니다. 입력의 활성 상태와 같은 값에서 정해야 라벨과 입력이 서로 다른 상태로 보이지 않습니다.

```dart
// canEdit 하나로 둘을 함께 정합니다.
Label(text: '이메일', disabled: !canEdit)
TextField(enabled: canEdit)
```

<a id="do"></a>

<Cards columns="2">
<Card demo="label/do-sync-disabled" tone="do" eyebrow="이렇게 하세요">

입력이 비활성이면 라벨에도 `disabled: true` 를 줍니다.

</Card>
<Card demo="label/dont-unsynced" tone="dont" eyebrow="이렇게 하지 마세요">

입력만 비활성으로 두면 라벨은 활성처럼 보입니다.

</Card>
<Card demo="label/do-is-required" tone="do" eyebrow="이렇게 하세요">

필수 항목은 `isRequired` 로 표시합니다. `*` 가 `error` 색이 되고, 비활성일 때는 글자색을 따릅니다.

</Card>
<Card demo="label/dont-typed-asterisk" tone="dont" eyebrow="이렇게 하지 마세요">

별표를 글자에 직접 적으면 라벨 글자와 같은 색이 되고, `requiredColor` 로 따로 바꿀 수 없습니다.

</Card>
</Cards>

<a id="dont"></a>

### 입력과 연결하기

Label 을 컨트롤 옆에 놓기만 하고 둘이 연결됐다고 여기지 않습니다. 폐기가 예고된 `htmlFor` 를 줘도 연결되지 않습니다. 입력에 이름이 필요하면 입력 쪽에 지정합니다. Jaspr Web 의 [TextField](/components/text-field) 는 `label` 속성을 줘도 그 라벨이 `<input>` 에 연결되지 않습니다([TextField 의 알려진 제약](/components/text-field#알려진-제약)). 대신 `attributes` 로 받은 `aria-*` 속성을 안쪽 `<input>` 에 붙이므로, Label 에 `id` 를 주고 `aria-labelledby` 로 가리킬 수 있습니다. 이 방법으로도 라벨을 눌러 입력에 포커스를 옮길 수는 없습니다.

<Split>

<Code language="dart" title="Jaspr Web — 이렇게 하지 마세요">
// 보기에는 한 쌍이지만 입력에는 이름이 없습니다.
div(classes: 'flex flex-col', [
  Label(text: '이메일', isRequired: true),
  const Gap.space6(),
  TextField(),
])
</Code>

<Code language="dart" title="Jaspr Web — 입력에 이름 지정">
div(classes: 'flex flex-col', [
  Label(id: 'email-label', text: '이메일', isRequired: true),
  const Gap.space6(),
  TextField(
    required: true,
    attributes: {'aria-labelledby': 'email-label'},
  ),
])
</Code>

</Split>

Label 의 `*` 는 보조 기술에서 숨기지 않으므로 이렇게 만든 이름에는 별표도 들어갑니다. 별표를 이름에서 빼야 하면 기본 별표를 숨기는 [FormLabel](/components/form-label) 을 씁니다.

라벨 · 도움말 · 오류를 한 묶음으로 만들려면 [FormField](/components/form-field) 를 씁니다. `FormField` 의 `label` 은 필드 묶음의 이름이 됩니다. FormField 가 입력 요소에 이름을 지정하지는 않고, 라벨을 눌러도 입력에 포커스가 가지 않습니다.

```dart
FormField(
  label: '이메일',
  child: TextField(),
)
```

<a id="레이아웃"></a>

## 배치

라벨은 컨트롤의 위나 옆에 놓습니다.

<Preview demo="label/layout" />

| 항목 | 동작 |
| --- | --- |
| 순서 | 아이콘 → 글자 → `*` 순서로 놓고 세로 가운데를 맞춥니다. 오른쪽에서 왼쪽으로 쓰는 방향에서는 좌우가 바뀝니다. |
| 폭 | 부모가 폭을 늘리지 않으면 내용만큼 차지합니다. |
| 바깥 여백 | 없습니다. 컨트롤과의 간격은 [Gap](/components/gap) 이나 부모의 간격으로 둡니다. |
| 긴 글자 | Flutter 는 줄을 바꾸지 않아, 놓인 폭보다 길면 넘침 오류(`RenderFlex overflowed`)가 납니다. `Flexible` 로 감싸도 같습니다. Jaspr Web 은 폭이 모자라면 브라우저의 줄바꿈 규칙을 따릅니다. |
| 줄 수 · 말줄임 | `maxLines` · `overflow` 속성이 없습니다. 긴 라벨에는 [FormLabel](/components/form-label) 을 씁니다. |

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

무엇을 보일지는 위젯 파라미터(`text` · `icon` · `isRequired` · `disabled`)로 정합니다. 겉모습(색 · 크기 · 간격)과 글자 모양은 `labelStyle`(`CoreLabelStyle`) 하나로 바꿉니다.

### 토큰

| 항목 | 기본값 | 바꾸는 필드 |
| --- | --- | --- |
| 글자 | `labelLarge` 역할, `CoreFontWeight.medium`(500) | `textStyle` |
| 글자색 | `onSurface` | `textStyle` 의 `color` |
| 비활성 글자 | `labelLarge` 역할, medium, `disabledContent` | `disabledTextStyle` |
| 필수 표시 색 | `error`. 비활성이면 비활성 글자색 | `requiredColor`(활성 상태에만) |
| 아이콘 크기 | `CoreIconSize.size16` | `iconStyle` 의 `size` |
| 아이콘과 글자 사이 | `CoreSpace.space6` | `iconLabelGapStyle` |
| 글자와 `*` 사이 | `CoreSpace.space4` | `labelRequiredGapStyle` |
| 비활성 투명도 | `CoreOpacity.opacity100`(1) | `disabledOpacity` |

색은 토큰이라 라이트 · 다크 모드를 따라 바뀝니다. Jaspr Web 은 글자 역할과 토큰 색을 `text-label-large` · `text-on-surface` · `text-disabled-content` · `text-error` 같은 클래스로 붙이고, medium 굵기는 인라인 스타일로 붙입니다.

`textStyle` 에 색만 주면 `labelLarge` 역할과 medium 굵기는 그대로입니다. `*` 는 `textStyle` 의 글자 모양을 함께 쓰고 색만 `requiredColor` 를 따릅니다. 글자 역할을 바꿔도 medium 굵기는 남으므로, 굵기까지 바꾸려면 `copyWith` 로 함께 정합니다.

```dart
Label(
  text: '이메일',
  labelStyle: CoreLabelStyle(
    textStyle: const CoreTextStyle.token(CoreTextStyles.titleMedium)
        .copyWith(fontWeight: CoreFontWeight.semiBold),
  ),
)
```

<Split>

<Code language="dart" title="Label 하나만 바꾸기">
Label(
  text: '이메일',
  icon: Icon(LucideIcons.mail),
  isRequired: true,
  labelStyle: CoreLabelStyle(
    iconStyle: CoreIconStyle(size: CoreIconSize.size20),
    iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
    requiredColor: CoreColor.token(CoreColors.tertiary),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    label: CoreLabelTheme(
      style: CoreLabelStyle(
        requiredColor: CoreColor.token(CoreColors.tertiary),
      ),
    ),
  ),
)
</Code>

</Split>

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreLabelStyle 의 default 값           // 디자인 시스템 기본값
  → CoreComponentTheme.label.style    // 앱 전체
  → labelStyle                        // Label 하나
```

뒤로 갈수록 우선합니다. 비운 필드는 앞의 값을 유지합니다. `iconStyle` · `textStyle` · `disabledTextStyle` 과 두 간격 스타일도 안의 값을 하나씩 합칩니다. 글자 모양은 상태에 따라 한쪽만 씁니다. 활성이면 `textStyle` 쪽을, 비활성이면 `disabledTextStyle` 쪽을 위 순서로 합칩니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

이미 만든 `Label` 에 `withStyle` 로 스타일을 덧붙일 수 있습니다. 생성자의 `labelStyle` 과 같게 동작하고, 겹치는 필드는 뒤에 붙인 값이 이깁니다. 아래 예제의 `disabledOpacity` 는 `disabled: true` 일 때만 보입니다.

<Preview component="label" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class LabelChainExample extends StatelessWidget {
  const LabelChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Label(text: '이메일', isRequired: true).withStyle(
      const CoreLabelStyle(
        textStyle: CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        requiredColor: CoreColor.token(CoreColors.tertiary),
        labelRequiredGapStyle: CoreGapStyle(size: CoreSpace.space12),
        disabledOpacity: CoreOpacity.opacity50,
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class LabelChainExample extends StatelessComponent {
  const LabelChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Label(text: '이메일', isRequired: true).withStyle(
      const CoreLabelStyle(
        textStyle: CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        requiredColor: CoreColor.token(CoreColors.tertiary),
        labelRequiredGapStyle: CoreGapStyle(size: CoreSpace.space12),
        disabledOpacity: CoreOpacity.opacity50,
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

Label 은 글자를 보이는 표시 전용 컴포넌트입니다. 입력과의 관계나 필수 · 비활성 상태는 보조 기술에 알리지 않습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | Label 은 역할을 정하지 않습니다. `semanticLabel` 을 주면 `Semantics(label:)` 로, `htmlFor` 를 주면 `Semantics(identifier:)` 로 감싸지만 어느 쪽도 역할을 정하지 않습니다. 다만 `icon` 에 넘긴 [Icon](/components/icon) 의 그림에는 이름 없는 이미지 표시(`Semantics(image: true)`)가 붙습니다. |
| Jaspr Web | 루트는 늘 `<span>` 이고 `role` 을 붙이지 않습니다. `<label>` 요소가 아닙니다. 아이콘을 감싼 `<span>` 과 `*` 를 담은 `<span>` 에도 역할이 없습니다. |

### 키보드

없습니다. 처리하는 키가 없고 `Tab` 순서에 들어가지 않습니다. Flutter 구현에는 `Focus` 가 없고, Jaspr Web 은 `<span>` 에 `tabindex` 를 붙이지 않습니다.

### 스크린 리더

- 보이는 글자(`text`)를 읽습니다.
- `isRequired` 는 `*` 글자 하나로만 전합니다. `*` 를 숨기지 않으며, "필수" 라는 글자나 필수 상태를 더하지 않습니다. `*` 를 어떻게 읽는지는 보조 기술과 그 설정에 따라 다릅니다.
- Label 은 아이콘에 이름을 붙이지 않습니다. 아이콘만으로 뜻을 전하지 마세요. 아이콘의 역할 표시는 [역할](#역할)을 보세요.
- `disabled` 는 알리지 않습니다.
- live region 이 아니므로 글자가 바뀌어도 따로 알리지 않습니다.

#### `semanticLabel`

두 플랫폼에서 읽히는 결과가 다릅니다.

| 플랫폼 | 동작 |
| --- | --- |
| Flutter | 보이는 글자를 대신하지 않고 그 앞에 덧붙습니다. `semanticLabel: '이메일 입력'` 에 `isRequired: true` 면 `semanticLabel` · 라벨 글자 · `*` 가 모두 읽는 내용에 들어갑니다. |
| Jaspr Web | 루트 `<span>` 의 `aria-label` 이 됩니다. ARIA 는 역할이 없는 `<span>` 에 이름을 붙이는 것을 금지하므로, 브라우저와 보조 기술에 따라 무시될 수 있습니다. |

필수라는 것을 확실히 알려야 하면 `text` 에 글자로 적거나(`'이메일 (필수)'`), 입력 쪽에서 알립니다. Jaspr Web 의 TextField 는 `required: true` 면 `<input>` 에 `required` 속성을 붙입니다.

Flutter 에서 읽히는 글자를 통째로 바꾸려면 `excludeSemantics: true` 인 `Semantics` 로 감쌉니다.

```dart
// Flutter
Semantics(
  label: '이메일, 필수',
  excludeSemantics: true,
  child: const Label(text: '이메일', isRequired: true),
)
```

#### 입력의 이름

Label 은 자기 글자를 입력의 이름으로 지정하지 않습니다. 입력의 이름은 입력 쪽에서 정합니다. Jaspr Web 의 예는 [입력과 연결하기](#입력과-연결하기)에 있습니다.

### 포커스 관리

없습니다. 오버레이가 아니고 포커스를 받지 않아, 포커스를 옮기거나 가두거나 되돌리지 않습니다. 라벨을 눌러도 컨트롤로 포커스가 가지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 폐기가 예고된 `htmlFor` 는 라벨과 컨트롤을 잇지 않습니다. Jaspr Web 은 `<span>` 에 `for` 를 붙이는데, HTML 은 `<span>` 의 `for` 로 관계를 만들지 않습니다. Flutter 는 그 값을 `Semantics(identifier:)` 로만 전합니다. |
| 공통 | 라벨을 눌러도 컨트롤에 포커스가 가지 않습니다. |
| 공통 | 필수 여부는 `*` 글자로만 보이고, 필수 상태로 알리지 않습니다. |
| 공통 | `disabled: true` 를 상태로 알리지 않습니다. `aria-disabled` 와 `Semantics(enabled: false)` 를 붙이지 않습니다. |
| 공통 | 기본 `disabledOpacity` 가 1 이라, 기본값에서 비활성과 활성의 차이는 색과 포인터를 올렸을 때의 커서뿐입니다. |
| Flutter | `semanticLabel` 은 보이는 글자를 대신하지 않고 덧붙습니다. |
| Flutter | 긴 글자는 줄을 바꾸지 않고 넘칩니다. |
| Flutter | 테마의 `scaling` 이 1 이 아니면 Label 이 크기를 내려 준 아이콘에 배율이 두 번 곱해집니다. |
| Jaspr Web | `semanticLabel` 은 역할이 없는 `<span>` 의 `aria-label` 이라 무시될 수 있습니다. |
| Jaspr Web | 강제 색 모드(`forced-colors`)는 글자색을 시스템 색으로 바꾸므로, 색만으로는 비활성 라벨을 구분할 수 없습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

공통 속성의 이름은 같습니다. 그리는 방식과 보조 기술에 전하는 방식이 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 그리는 방식 | 내용 크기의 가로 `Row`(`MainAxisSize.min`) | `inline-flex` 인 `<span>`. `<label>` 요소가 아닙니다. |
| 긴 글자 | 줄을 바꾸지 않고 넘칩니다. | 줄을 바꿉니다. |
| 아이콘에 전하는 값 | `IconTheme` 로 크기와 색 | `IconTheme` 로 크기를 전하고, 색은 글자색을 상속합니다. |
| `scaling` | 간격에 한 번, Label 이 크기를 내려 준 아이콘에 두 번 곱합니다. | `scaling` 설정이 없습니다. 아이콘 크기는 `rem` 입니다. |
| `semanticLabel` | `Semantics(label:)`. 보이는 글자 앞에 덧붙습니다. | 루트 `<span>` 의 `aria-label` |
| `htmlFor`(폐기 예고) | `Semantics(identifier:)` | `<span>` 의 `for` 속성. 입력과 이어지지 않습니다. |
| 비활성 표시 | 비활성 글자색, `Opacity`, `SystemMouseCursors.forbidden` | 비활성 글자색, 인라인 `opacity`, `cursor-not-allowed` |
| Web 전용 속성 | — | `id` · `classes` · `css` · `attributes` |

<a id="props-parameters"></a>

## API

Flutter 와 Jaspr Web 이 같은 속성을 씁니다. `W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다.

### 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `text` | `String` | 필수 | 라벨 글자 |
| `icon` | `W?` | `null` | 글자 앞의 아이콘 |
| `isRequired` | `bool` | `false` | 글자 뒤에 `*` 를 붙입니다. 검사는 하지 않습니다. |
| `disabled` | `bool` | `false` | 비활성 모습으로 그립니다. 컨트롤에는 전해지지 않습니다. |
| `semanticLabel` | `String?` | `null` | 보조 기술에 전하는 글자. 플랫폼마다 결과가 다릅니다([스크린 리더](#스크린-리더)). |
| `htmlFor` | `String?` | `null` | **폐기 예고(Deprecated).** 어느 플랫폼에서도 라벨과 컨트롤을 잇지 않습니다([입력과 연결하기](#입력과-연결하기)). |
| `labelStyle` | `CoreLabelStyle?` | `null` | 색 · 크기 · 간격 · 글자 모양 덮어쓰기 |

### Web 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트 `<span>` 의 `id`. 입력의 `aria-labelledby` 가 가리킬 수 있습니다. |
| `classes` | `String?` | `null` | 루트에 덧붙이는 클래스 |
| `css` | `Styles?` | `null` | 루트의 인라인 스타일. Label 이 붙이는 인라인 값과 같은 속성이면 `css` 가 앞섭니다. |
| `attributes` | `Map<String, String>?` | `null` | 루트에 붙이는 HTML 속성. `htmlFor` · `semanticLabel` 을 주면 `for` · `aria-label` 은 그 값이 됩니다. |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreLabelStyle patch)` | `labelStyle` 에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다. |
| `copyWith({text, icon, …})` | 바꾼 값으로 사본을 만듭니다. 넘기지 않았거나 `null` 인 인자는 지금 값을 유지합니다. Web 은 `id` · `classes` · `css` · `attributes` 도 받고, `classes` 는 지금 클래스 뒤에 덧붙입니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.label` | `CoreLabelTheme?` | 앱 전체 기본값. `style: CoreLabelStyle?` 하나를 가집니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreLabelStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `iconStyle` | `CoreIconStyle?` | Leading icon style override. `size` defers to [defaultIconStyle]. |
| `iconLabelGapStyle` | `CoreGapStyle?` | Gap between the leading icon and the label text, passed to `Gap(gapStyle: …)` as is. |
| `labelRequiredGapStyle` | `CoreGapStyle?` | Gap between the label text and the required indicator (`*`), passed to `Gap(gapStyle: …)` as is. |
| `disabledOpacity` | `double?` | Opacity applied when `disabled` is `true`. |
| `requiredColor` | `CoreColor?` | Required indicator (`*`) colour override for the enabled state. While `disabled` the `*` follows the colour of [disabledTextStyle]. |
| `textStyle` | `CoreTextStyle?` | Text style override for the label text (enabled state). Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `textColor` field removed). |
| `disabledTextStyle` | `CoreTextStyle?` | Text style override for the label text when `disabled` is `true`. Mirrors [textStyle] but applies only in the disabled state, laid over [defaultDisabledTextStyle]. Text colour is carried via [CoreTextStyle.color] inside this slot. |

<!-- STYLE_TABLE:END -->

<Note>

표의 설명과 함께 알아 둘 지금 동작입니다.

- `iconStyle` 에서 Label 이 읽는 값은 `size` 뿐입니다. `color` 같은 다른 값은 두 플랫폼 모두 적용되지 않습니다. 아이콘 색을 따로 정하려면 넘기는 `Icon` 의 `iconStyle` 에 줍니다.
- `iconLabelGapStyle` · `labelRequiredGapStyle` 은 기본 간격(6 · 4) 위에 합친 값이 `Gap` 에 전해집니다.
- `textStyle` 은 `*` 의 글자 모양과 아이콘의 색에도 닿습니다. `*` 의 색은 `requiredColor` 가 정합니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

입력 값을 모아 검증하는 묶음은 [Form](/components/form) 으로 만듭니다.

<Cards columns="2">
<Card demo="label/related-form-field" title="FormField">

라벨 · 도움말 · 오류 · 검증을 입력과 한 필드로 묶습니다.

</Card>
<Card demo="label/related-form-label" title="FormLabel">

크기에 맞춰 글자가 바뀌고, 라벨과 필수 표시를 위젯으로 넘길 수 있는 폼 라벨입니다.

</Card>
<Card demo="label/related-fieldset" title="Fieldset">

여러 라벨과 입력을 제목이 있는 한 묶음으로 만듭니다.

</Card>
<Card demo="label/related-validation-badge" title="ValidationBadge">

검증 결과를 아이콘과 글자로 보입니다.

</Card>
</Cards>
