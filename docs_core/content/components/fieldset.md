---
title: Fieldset
description: 관련된 폼 필드를 그룹으로 묶는 컨테이너 컴포넌트
category: form
platforms: [flutter, web]
related: [form, text-field, checkbox]
tags: [layout, form-control, grouping]
template: v2
source: form/fieldset
---

# Fieldset

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

variant · 크기 · 설명 · 비활성을 바꿔 보며 Fieldset 을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="fieldset" />

Fieldset 은 범례(`legend`)와 설명(`description`) 아래에 필드를 세로로 놓아 한 묶음으로 보여 줍니다. 묶음의 경계는 `variant` 로 채운 패널 · 외곽선 · 상자 없음 중에서 고릅니다. Flutter 와 Jaspr Web 이 같은 `Fieldset` 을 씁니다. `legend` 와 `description` 은 문자열이 아니라 위젯이므로 `Text` 를 넘깁니다. Jaspr Web 에서 쓰는 `Text` 도 coui_web 이 내보내는 `Text` 라 Flutter 와 같은 글자 체인(`.bodyMedium.onSurface`)을 씁니다.

```dart
Fieldset(
  legend: Text('계정'),
  description: Text('로그인에 쓰는 정보예요.'),
  children: [
    TextField(placeholder: Text('이름')),
    TextField(placeholder: Text('이메일')),
  ],
)
```

## 구조

Fieldset 은 상자 하나 안에 머리(범례와 설명)와 필드 목록을 위에서 아래로 놓습니다. 범례 · 설명 · 필드는 모두 선택 사항입니다.

<Anatomy demo="fieldset/anatomy">
<AnatomyItem part="container" name="Container">

묶음의 상자. 채움 · 테두리 · 모서리 · 안쪽 여백은 variant 가 정합니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=legend]" side="top" name="legend">

묶음의 제목. 글자 크기는 `size` 가 정합니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=description]" side="right" name="description">

범례 아래의 보조 문구. 넘겼을 때만 그립니다.

</AnatomyItem>
<AnatomyItem select="input" side="right" name="children">

묶는 필드들. 상자 폭에 맞춰 늘어나고 같은 간격으로 쌓입니다.

</AnatomyItem>
</Anatomy>

- `legend` 와 `description` 중 하나만 넘겨도 머리가 생깁니다. 둘 다 없으면 머리와 그 아래 간격이 함께 없어지고 필드만 놓입니다.
- `children` 이 비어 있으면 필드 목록과 머리 아래 간격을 그리지 않습니다.
- 범례와 설명 자리는 안쪽 위젯에 글자 모양을 내려 줍니다. `Text` 에 크기나 색을 체인으로 직접 지정하면 그 값이 이깁니다 — 비활성 범례 색도 마찬가지입니다.

<a id="변형-variants"></a>

## Variant

variant 는 상자만 바꿉니다. 범례 · 설명 · 필드는 세 값이 같고, 기본값은 `filled` 입니다.

<a id="filled-기본"></a>

<VariantRow name="filled" component="fieldset" props="variant=filled;fields=1;width=compact" label="계정">

옅은 채움(`surface-container-low`)에 얇은 테두리를 두른 패널입니다.

</VariantRow>

<a id="outlined"></a>

<VariantRow name="outlined" component="fieldset" props="variant=outlined;fields=1;width=compact" label="계정">

`filled` 와 같은 테두리 · 모서리 · 안쪽 여백에서 채움만 뺍니다.

</VariantRow>

<a id="plain"></a>

<VariantRow name="plain" component="fieldset" props="variant=plain;fields=1;width=compact" label="계정">

상자를 그리지 않습니다. 범례 · 설명 · 필드가 페이지 위에 바로 놓이고 여백으로만 구분됩니다.

</VariantRow>

| variant | 채움 | 테두리 | 모서리 | 안쪽 여백 |
| --- | --- | --- | --- | --- |
| `filled` (기본) | `surface-container-low` | `outline-subtle` 1 | 16 | 16 |
| `outlined` | 없음 | `outline-subtle` 1 | 16 | 16 |
| `plain` | 없음 | 없음 | 0 | 0 |

<Note>

`filled` 의 옅은 채움과 `outlined` 의 옅은 테두리는 라이트 모드에서 바탕과 차이가 작아 잘 구분되지 않을 수 있습니다. 실제로 놓을 바탕 위에서 확인합니다.

</Note>

<Note>

`plain` 에 `fieldsetStyle` 로 `backgroundColor` 만 주면 안쪽 여백과 모서리 없이 채워지므로 `padding` · `borderRadius` 도 함께 적습니다. `borderColor` 만 주면 두께가 0 이라 선이 그려지지 않으므로 `borderWidth` 도 함께 적습니다. Flutter 의 `plain` 은 안쪽 입력의 포커스 링이 상자 가장자리에서 잘립니다([알려진 제약](/components/fieldset#알려진-제약)).

</Note>

### 의미 체인

`Fieldset`의 `.outline`은 `variant: .outlined`를 선택합니다. 테마가 윤곽선과 배경을 결정합니다.

## 크기

<SizeSpec component="fieldset" props="fields=1;width=compact" label="계정" />

`size` 는 범례 글자만 바꿉니다. `xs` · `sm` · `md` 는 `titleSmall`, `lg` · `xl` · `xl2` 는 `titleMedium` 이고 두 역할 모두 SemiBold 에 줄 높이 140% 입니다. 안쪽 여백 · 모서리 · 간격 · 설명 글자는 크기와 무관합니다. 안에 놓은 필드의 크기도 바뀌지 않으므로, 필드 크기는 필드마다 `size` 로 고릅니다.

<a id="동작-스펙-behavior"></a>
<a id="시각"></a>

## 상태

<Preview demo="fieldset/states" />

Fieldset 의 상태는 `enabled` 하나입니다. hover · 눌림 · 포커스 · 오류 · 로딩 상태는 없고, 값 제출이나 검증 콜백도 부르지 않습니다.

| `enabled: false` 일 때 | 동작 |
| --- | --- |
| 흐림 | 세 variant 모두 묶음 전체를 불투명도 50% 로 그립니다. |
| 범례 | 글자 색이 `disabled-content` 가 됩니다. `legendTextStyle` 에 준 색보다 이 색이 우선하며, 비활성 색은 `disabledLegendColor` 로 바꿉니다. |
| 설명 | 색은 그대로이고 전체 흐림만 받습니다. |
| 안쪽 | 묶음이 비활성이라는 설정을 안쪽에 전합니다. 이 설정을 읽는 부분은 자기 `enabled: true` 보다 이것을 따릅니다. 어디까지 따르는지는 아래 표에 있습니다. |

### 함께 꺼지는 입력

`enabled: false` 는 HTML 의 `<fieldset disabled>` 와 비슷하지만 네이티브 요소가 아니라서 아무 자식이나 막지는 않습니다. 이 설정을 읽는 부분만 막히고, 설정을 읽는 컴포넌트에도 남는 조작이 있습니다.

| 안에 놓은 것 | 비활성 Fieldset 안에서 |
| --- | --- |
| `TextField` | 비활성 모양이 되고 글자를 입력할 수 없습니다. Flutter 에서는 `Tab` 포커스를 여전히 받습니다. |
| `FormField` | 라벨이 비활성 모양이 되고, `FormField` 에 담은 것 전체가 마우스 · 터치 입력을 받지 않습니다. 설정을 읽지 않는 컨트롤은 키보드로 계속 조작됩니다. |
| `Select` · `Autocomplete` | 비활성 모양이 되고 포인터나 키보드로 목록을 열거나 값을 고를 수 없습니다. Flutter 에서는 `Tab` 정지점으로 남지만 입력 동작은 막힙니다. |
| `DatePicker` · `DateRangePicker` · `TimePicker` | Flutter 는 달력이나 시각 패널이 열리지 않습니다. Jaspr Web 은 입력 칸을 비활성 모양으로 그리지만, 팝오버 방식(기본)에서는 칸을 누르면 패널이 열립니다. |
| `NumberInput` | 글자 입력과 −/+ 버튼 조작이 막힙니다. Flutter 에서는 칸에 `Tab` 으로 들어가도 방향키 · 페이지 키와 보조 기술의 값 늘리기 · 줄이기로 값이 바뀌지 않습니다. |
| `ChipInput` · `PhoneInput` | 글자를 입력할 수 없습니다. `ChipInput` 칩의 지우기 버튼과 `PhoneInput` 의 국가 선택은 계속 눌립니다. |
| `InputOtp` · `FormattedInput` | Flutter 는 안의 입력 칸이 설정을 읽어 입력이 막힙니다. Jaspr Web 은 계속 입력됩니다. |
| `Checkbox` · `RadioGroup` · `Toggle` · `SwitchField` · `Slider` · `TextArea` · `Button` 처럼 설정을 읽지 않는 것 | 흐려지기만 하고 그대로 조작됩니다(`FormField` 에 담은 것은 위 행). 컴포넌트마다 `enabled: false` 를 줍니다. |

Fieldset 을 중첩하면 안쪽 Fieldset 도 바깥의 비활성을 이어받습니다. 안쪽이 `enabled: true` 여도 그 안에서 설정을 읽는 입력은 비활성입니다. 안쪽 상자는 바깥의 흐림만 받아 두 번 흐려지지 않고, 안쪽 범례는 활성 색 그대로입니다.

안쪽 입력이 여는 팝오버나 대화상자의 내용에는 이 설정이 전해지지 않습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

Fieldset 은 이런 경우에 씁니다.

- 긴 폼을 기본 정보 · 결제 정보 · 배송 정보처럼 주제별로 나눌 때
- 관련된 필드에 공통 제목(`legend`)이 필요할 때
- 그 묶음이 무엇을 위한 것인지 한 줄 설명(`description`)이 더 필요할 때
- 조건에 따라 필드 묶음 전체를 비활성화할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 필드 묶음 표시가 아니라 폼 전체의 검증 · 값 관리가 필요할 때 | [Form](/components/form) |
| 필드 하나에 라벨 · 오류 문구를 붙일 때 | [FormField](/components/form-field) |
| 묶음 없이 글자 입력 하나만 필요할 때 | [TextField](/components/text-field) |
| 폼이 아닌 일반 콘텐츠를 묶을 때 | [Card](/components/card) |

<a id="do"></a>
<a id="dont"></a>

### 제목과 비활성

<Cards columns="2">
<Card demo="fieldset/do-legend" tone="do" eyebrow="이렇게 하세요">

`legend` 로 묶음의 제목을 보여 주고, 무엇을 위한 묶음인지는 `description` 에 한 줄로 적습니다. 설명은 `bodySmall` · `on-surface-variant` 라 범례보다 한 단계 낮은 보조 문구로 읽힙니다.

</Card>
<Card demo="fieldset/dont-no-legend" tone="dont" eyebrow="이렇게 하지 마세요">

제목 없이 상자로만 묶으면 무엇의 묶음인지 알 수 없습니다.

</Card>
<Card demo="fieldset/do-disable-each" tone="do" eyebrow="이렇게 하세요">

비활성 설정을 읽지 않는 컴포넌트에는 `enabled: false` 를 따로 줍니다. 이 체크박스도 눌리지 않습니다.

</Card>
<Card demo="fieldset/dont-assume-disabled" tone="dont" eyebrow="이렇게 하지 마세요">

`Fieldset(enabled: false)` 가 모든 입력을 막는다고 기대하지 않습니다. 이 체크박스는 흐려 보이지만 비활성이 아니라서, 앱에서는 누르면 값이 바뀝니다.

</Card>
</Cards>

<a id="레이아웃"></a>

## 배치

### 폭

Fieldset 은 부모의 폭을 채우고, 안의 필드도 상자 폭에 맞춰 늘어납니다. `plain` 도 상자만 없을 뿐 같은 폭을 채웁니다.

Flutter 는 폭이 정해진 부모가 필요합니다. `Row` 바로 아래나 가로 스크롤처럼 폭이 정해지지 않은 자리에 두면 레이아웃 오류가 납니다. `Row` 바로 아래라면 `Expanded` 나 `SizedBox(width:)` 로, 가로 스크롤 안이라면 `SizedBox(width:)` 로 폭을 줍니다.

<a id="범례-설명-간격"></a>

### 머리와 필드 간격

세 variant 가 같은 기본값을 씁니다. 각 값은 `fieldsetStyle` 의 필드로 바꿉니다.

| 자리 | 기본값 | 바꾸는 필드 |
| --- | --- | --- |
| 범례 → 설명 | 4 | `legendDescriptionGapStyle` |
| 머리(범례 · 설명) → 첫 필드 | 12 | `headerFieldsGapStyle` |
| 필드 사이 | 16 | `fieldSpacing` |
| 범례 둘레의 안쪽 여백 | 0 (필드와 같은 시작선) | `legendPadding` |

`legendPadding` 은 범례에만 닿고 설명에는 닿지 않습니다. 필드 사이 16 은 라벨 없는 필드 둘이 한 묶음으로 읽히는 간격입니다. 필드마다 라벨과 도움말 줄이 있는 폼이라면 `fieldSpacing` 을 24 로 넓힙니다.

### 여러 묶음

긴 폼은 주제마다 Fieldset 하나로 나눕니다. Fieldset 은 바깥 여백을 갖지 않으므로 묶음 사이의 간격은 부모가 정합니다.

<Preview demo="fieldset/sections" />

<Split>

<Code language="dart" title="Flutter">
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: CoreSpace.space24,
  children: [
    Fieldset(legend: Text('기본 정보'), children: basicFields),
    Fieldset(legend: Text('배송 정보'), children: shippingFields),
  ],
)
</Code>

<Code language="dart" title="Jaspr Web">
div(classes: 'flex flex-col gap-${CoreSpace.scale.space24}', [
  Fieldset(legend: Text('기본 정보'), children: basicFields),
  Fieldset(legend: Text('배송 정보'), children: shippingFields),
])
</Code>

</Split>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

상자 · 간격 · 범례 · 설명의 겉모습은 `fieldsetStyle`(`CoreFieldsetStyle`) 하나로 덮어씁니다. 겉모습을 바꾸는 낱개 파라미터는 없습니다. 안에 놓은 필드의 겉모습은 필드마다 바꿉니다. 앱 전체 값은 `CoreFieldsetTheme` 의 `style`(모든 Fieldset)과 `variantStyles`(그 variant 만) 두 칸에 둡니다.

<a id="테마-커스터마이징-theme"></a>

<Split>

<Code language="dart" title="Fieldset 하나만 바꾸기">
Fieldset(
  legend: Text('결제 정보'),
  fieldsetStyle: CoreFieldsetStyle(
    fieldSpacing: CoreSpace.space24,
    legendTextStyle: CoreTextStyle(color: CoreColor.token(CoreColors.primary)),
  ),
  children: paymentFields,
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    fieldset: CoreFieldsetTheme(
      // 모든 Fieldset
      style: CoreFieldsetStyle(fieldSpacing: CoreSpace.space24),
      // plain 만
      variantStyles: {
        CoreFieldsetVariant.plain: CoreFieldsetStyle(fieldSpacing: CoreSpace.space32),
      },
    ),
  ),
)
</Code>

</Split>

### 값이 정해지는 순서

```text
기본값 (variant 행 · 크기 행 · default*)
  → CoreComponentTheme.fieldset.style                  // 모든 Fieldset
  → CoreComponentTheme.fieldset.variantStyles[variant] // 그 variant 만
  → fieldsetStyle                                      // 인스턴스
```

뒤로 갈수록 우선합니다. variant 행은 상자(채움 · 테두리 · 모서리 · 안쪽 여백)만 정하고, 크기 행은 범례 글자만 정합니다. 글자 스타일(`legendTextStyle` · `descriptionTextStyle`)과 간격 스타일은 안의 값끼리 합쳐지므로 색만 적어도 크기는 남습니다. `padding` · `legendPadding` · `borderRadius` 는 적은 값이 통째로 바꿉니다.

### 표면 스타일

재질(반투명 · 블러 · 유리 가장자리)을 가진 표면 스타일 `liquidGlass` 를 켜면 상자마다 받는 것이 다릅니다.

| 상자 | `liquidGlass` 를 켰을 때 |
| --- | --- |
| `filled` | 채움이 있는 패널이라 두 플랫폼 모두 재질을 받습니다. |
| `outlined` | 채움이 없습니다. Jaspr Web 은 재질을 받지 않고 `outline-subtle` 선을 그대로 그립니다. Flutter 는 그 선 대신 유리 가장자리를 그립니다. |
| `plain` | 그림자를 받지 않습니다. Jaspr Web 은 재질도 받지 않지만, Flutter 는 상자 자리의 둘레에 유리 가장자리를 그립니다. |

가장자리를 휘어 보이게 하는 효과를 지원하지 않는 Flutter 렌더러에서는 `outlined` 와 `plain` 에 약한 블러도 더해집니다.

표면 스타일이 컨트롤에 그림자를 더하는 경우에는 `filled` 와 `outlined` 가 그 그림자를 받습니다. `fieldsetStyle` 로 `outlined` 나 `plain` 에 채움 색을 주면 채움이 있는 상자가 되어 재질도 받습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Fieldset` 에 스타일을 덧붙이려면 `withStyle` 을 씁니다. 생성자의 `fieldsetStyle` 과 같게 동작하고, 같은 필드는 나중에 적은 값이 이깁니다. `.radius16` 처럼 Core 토큰 이름과 같은 getter 도 있습니다 — 반경 getter는 `borderRadius`를 바꿉니다. 아래 예제처럼 진한 배경색을 직접 쓰면 `legendTextStyle` · `descriptionTextStyle` 의 색도 함께 맞춥니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class FieldsetChainExample extends StatelessWidget {
  const FieldsetChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Fixed-width wrappers so the preview matches Web's
    // `w-${CoreSpace.scale.space256}` wrapper — the docs preview
    // pane is already centred, we just need a known cross-axis
    // size to keep both platforms visually identical.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        SizedBox(
          width: CoreSpace.space256,
          child: Fieldset(
            legend: const Text('계정'),
            children: [
              TextField(
                autofillHints: const [AutofillHints.name],
                placeholder: const Text('이름'),
              ),
              TextField(
                autofillHints: const [AutofillHints.email],
                placeholder: const Text('이메일'),
              ),
            ],
          ).radius16.backgroundColor(.primary),
        ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        SizedBox(
          width: CoreSpace.space256,
          child:
              Fieldset(
                legend: const Text('계정'),
                children: [
                  TextField(
                    autofillHints: const [AutofillHints.name],
                    placeholder: const Text('이름'),
                  ),
                  TextField(
                    autofillHints: const [AutofillHints.email],
                    placeholder: const Text('이메일'),
                  ),
                ],
              ).withStyle(
                const CoreFieldsetStyle(
                  backgroundColor: .tertiary,
                  borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
                  fieldSpacing: CoreSpace.space12,
                  padding: CoreEdgeInsets.symmetric(
                    horizontal: CoreSpace.space24,
                    vertical: CoreSpace.space8,
                  ),
                ),
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
class FieldsetChainExample extends StatelessComponent {
  const FieldsetChainExample({super.key});

  @override
  Component build(BuildContext context) {
    // Fixed-width wrappers keep the preview at the same width as
    // Flutter's `SizedBox(width: CoreSpace.space256)` — the docs
    // preview pane uses `align-items: center` for cross-platform
    // visual parity, so we anchor a known size instead of letting
    // the fieldset stretch to the pane's full inline-axis.
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        div(
          [
            Fieldset(
              legend: const Text('계정'),
              children: [
                TextField(
                  autofillHints: const ['name'],
                  placeholder: const Text('이름'),
                ),
                TextField(
                  autofillHints: const ['email'],
                  placeholder: const Text('이메일'),
                ),
              ],
            ).radius16.backgroundColor(.primary),
          ],
          classes: 'w-${CoreSpace.scale.space256}',
        ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        div(
          [
            Fieldset(
              legend: const Text('계정'),
              children: [
                TextField(
                  autofillHints: const ['name'],
                  placeholder: const Text('이름'),
                ),
                TextField(
                  autofillHints: const ['email'],
                  placeholder: const Text('이메일'),
                ),
              ],
            ).withStyle(
              const CoreFieldsetStyle(
                backgroundColor: .tertiary,
                borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
                fieldSpacing: CoreSpace.space12,
                padding: CoreEdgeInsets.symmetric(
                  horizontal: CoreSpace.space24,
                  vertical: CoreSpace.space8,
                ),
              ),
            ),
          ],
          classes: 'w-${CoreSpace.scale.space256}',
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

<a id="이전-모양에서-옮기기-migration"></a>

## 이전 모양에서 옮기기

- 기본 variant 가 외곽선만 있는 상자에서 `filled`(채운 패널)로 바뀌었습니다. `variant` 를 적지 않은 `Fieldset` 은 `surface-container-low` 로 채워 그립니다. 채움 없이 그리려면 `variant: CoreFieldsetVariant.outlined` 를 적습니다.
- 기본값이 바뀐 곳: 모서리 24 → 16, 테두리 색 `outline` → `outline-subtle`, 필드 사이 24 → 16, 범례 가로 여백 8 → 0. 범례와 첫 필드 사이는 24 → 12 이고, 이 간격(`headerFieldsGapStyle`)은 필드 사이 간격과 따로 정합니다. 안쪽 여백 16 과 테두리 두께 1 은 그대로입니다.
- 이전 값을 그대로 쓰려면 `outlined` 에 옛 값을 `fieldsetStyle` 로 적습니다. 프로젝트 전체에 적용하려면 같은 값을 `CoreFieldsetTheme.variantStyles` 의 `outlined` 에 둡니다.

```dart
Fieldset(
  variant: CoreFieldsetVariant.outlined,
  fieldsetStyle: CoreFieldsetStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    borderColor: CoreColor.token(CoreColors.outline),
    fieldSpacing: CoreSpace.space24,
    legendPadding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space8),
    headerFieldsGapStyle: CoreGapStyle(size: CoreSpace.space24),
  ),
  legend: Text('계정'),
  children: accountFields,
)
```

- `description` 속성과 `variant` 속성이 생겼습니다. `CoreFieldsetContract` 를 직접 구현하는 코드는 두 getter 를 더해야 합니다.
- `CoreFieldsetStyle` 에 `descriptionTextStyle` · `legendDescriptionGapStyle` · `headerFieldsGapStyle` 이, `CoreFieldsetTheme` 에 `variantStyles` 가 더해졌습니다.

<a id="접근성-accessibility"></a>

## 접근성

Fieldset 은 접근성 정보를 직접 붙이지 않습니다. 화면에서는 묶음으로 보여도 보조 기술에는 묶음으로 전해지지 않습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | `Semantics` 를 두지 않아, 이 입력들이 한 묶음이라는 사실이 보조 기술에 전해지지 않습니다. `description` 도 마찬가지입니다. |
| Jaspr Web | 루트는 네이티브 `<fieldset>` 이 아니라 `<div>` 이고 `role` 이 없습니다. 범례는 `<div>` 안의 `<span>` 이며(`<legend>` 아님) 설명은 `<div>` 입니다. 둘 다 `aria-labelledby` · `aria-describedby` 로 묶음과 이어지지 않습니다. 비활성이면 루트에 빈 `data-disabled` 속성이 붙지만, ARIA 속성이 아니라서 보조 기술은 읽지 않습니다. |

#### 묶음에 이름 붙이기

Jaspr Web 은 루트의 `attributes` 로 `role` 과 이름을 줄 수 있습니다. 범례로 넘기는 위젯에 `id` 를 주면 그 id 를 `aria-labelledby` 로 가리킬 수 있습니다.

```dart
Fieldset(
  attributes: {'role': 'group', 'aria-labelledby': 'shipping-legend'},
  legend: span(id: 'shipping-legend', [Text('배송지')]),
  children: shippingFields,
)
```

Flutter 는 `Semantics` 로 감싸 이름을 붙입니다. 화면의 범례와 이어지는 것이 아니라 이름을 따로 붙이는 방법입니다.

```dart
Semantics(
  container: true,
  label: '배송지',
  child: Fieldset(legend: Text('배송지'), children: shippingFields),
)
```

### 키보드

| 키 | 동작 |
| --- | --- |
| — | 이 컴포넌트가 처리하는 키는 없습니다. `Tab` · `Shift` + `Tab` 은 `children` 에 놓인 입력들을 차례로 지나갑니다. |

`Fieldset` 자체는 포커스를 받지 않아 Tab 정지점이 아니고, 묶음을 한 번에 건너뛰는 키도 없습니다.

비활성 묶음에서는 두 플랫폼이 다릅니다. Jaspr Web 에서는 비활성이 된 `<input>` 을 `Tab` 이 건너뜁니다. Flutter 에서는 비활성 설정을 읽은 `TextField` 도 `Tab` 정지점으로 남지만, `Select` · `Autocomplete` · `NumberInput` 의 키보드 입력은 값을 바꾸지 않습니다. 설정을 읽지 않는 컨트롤은 두 플랫폼 모두 평소처럼 포커스를 받습니다([알려진 제약](/components/fieldset#알려진-제약)).

### 스크린 리더

- 묶음의 이름이 없습니다(두 플랫폼). 범례는 묶음의 제목이 아니라 앞에 놓인 별개의 글자로 읽히고, 안쪽 입력들은 서로 관계없는 항목으로 나열됩니다. 설명도 묶음의 설명으로 이어지지 않습니다.
- 상태를 알리는 라이브 리전이 없어 `enabled` 가 바뀌어도 읽히는 것이 없습니다. 비활성은 비활성 설정을 읽은 입력이 각자 알립니다.
- 범례는 위젯을 받는 자리라, 제목 수준 같은 글자의 접근성 정보는 넘기는 위젯이 정합니다.

### 포커스 관리

화면에 나타날 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. 열고 닫는 패널이 아니라서 포커스를 돌려보낼 트리거도 없습니다. 마지막 입력에서 `Tab` 을 누르면 그대로 바깥으로 나갑니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | `enabled: false` 는 비활성 설정을 읽는 부분만 막습니다. Fieldset 은 읽지 않는 컴포넌트를 흐리게 그릴 뿐 Flutter 의 `IgnorePointer` 나 Web 의 포인터 차단 · `aria-disabled` 를 더하지 않아, 여전히 Tab 으로 닿고 누를 수 있습니다. `FormField` 에 담으면 마우스 · 터치는 막히지만 키보드 조작은 남습니다. 각자 `enabled: false` 를 줍니다([함께 꺼지는 입력](/components/fieldset#함께-꺼지는-입력)). |
| Flutter | 비활성 설정을 읽는 `TextField` 도 `Tab` 정지점으로 남습니다. `Select` · `Autocomplete` · `NumberInput` 에도 포커스가 닿지만, 해당 입력의 키보드 조작은 막힙니다. |
| Jaspr Web | `DatePicker` · `DateRangePicker` · `TimePicker` 는 팝오버 방식(기본)에서 입력 칸을 누르면 패널이 열리고, 거기서 값을 바꿀 수 있습니다. 비활성 묶음 안에서는 이 컴포넌트에도 `enabled: false` 를 줍니다. |
| 공통 | `ChipInput` · `PhoneInput` 의 버튼은 계속 눌립니다. 이 컴포넌트에도 `enabled: false` 를 줍니다. |
| Jaspr Web | `InputOtp` 와 `FormattedInput` 은 자기 `<input>` 을 직접 그려, 비활성 묶음 안에서도 입력됩니다. 이 컴포넌트에도 `enabled: false` 를 줍니다. |
| 공통 | 범례가 묶음의 이름으로 이어지지 않습니다. 위 [묶음에 이름 붙이기](/components/fieldset#묶음에-이름-붙이기)처럼 호출하는 쪽에서 붙입니다. |
| Flutter | 상자가 내용을 가장자리에서 잘라 냅니다. 안쪽 여백이 4 보다 작으면(`plain` 의 기본은 0) 안쪽 입력의 키보드 포커스 링(바깥으로 4)이 가장자리에서 잘립니다. |
| Flutter | `liquidGlass` 에서는 `outlined` 와 `plain` 에도 유리 가장자리가 그려지고, `outlined` 의 `outline-subtle` 선은 보이지 않습니다. 렌더러에 따라 약한 블러도 더해집니다([표면 스타일](/components/fieldset#표면-스타일)). |
| Jaspr Web | 생성자의 `eventHandlers` 는 받지만 루트에 붙이지 않아 아무 이벤트도 불리지 않습니다. |
| Jaspr Web | 색 강제(forced-colors) 모드에서는 글자 색이 시스템 색으로 바뀌어 비활성 범례의 색 차이가 사라지고, 남는 표시는 흐림(불투명도 50%)뿐입니다. 시스템의 비활성 색은 쓰지 않습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 루트 | `Opacity` → 폭을 채우는 `SizedBox` → `OutlinedContainer` 안의 `Column` | 네이티브 `<fieldset>` 이 아닌 `<div>` |
| 상자 | `OutlinedContainer` 가 채움 · 테두리 · 모서리 · 안쪽 여백을 그립니다 | 루트 `<div>` 에 같은 값을 클래스와 인라인 스타일로 싣습니다 |
| 폭 | 폭이 정해진 부모가 필요합니다 | 컨테이너의 폭을 채웁니다(`w-full`) |
| 범례 · 설명 | `Padding`(범례)과 `DefaultTextStyle` | 범례는 `<div>` 안의 `<span>`, 설명은 `<div>` 에 글자 스타일을 싣습니다 |
| 비활성 표시 | `Opacity` | `opacity-50` 과 `data-disabled` |
| 비활성 설정 전달 | `FormFieldScope`(`InheritedWidget`) | `FormFieldScope`(`InheritedComponent`, DOM 요소 없음) |
| 비활성 묶음 안의 날짜 · 시각 선택기 | 열리지 않습니다 | 팝오버 방식은 칸을 누르면 열립니다 |
| 비활성 묶음 안의 키보드 | `TextField` 도 `Tab` 포커스를 받고, `Select` · `Autocomplete` · `NumberInput` 이 키에 반응합니다 | 비활성이 된 `<input>` 은 `Tab` 이 건너뜁니다 |
| 비활성 묶음 안의 `InputOtp` · `FormattedInput` | 입력이 막힙니다 | 계속 입력됩니다 |
| `liquidGlass` 의 `outlined` · `plain` | 유리 가장자리를 그립니다 | 재질을 받지 않습니다(`outlined` 는 선을 그대로 그립니다) |
| 상자 밖으로 나가는 포커스 링 | 안쪽 여백이 4 보다 작으면 잘립니다 | 잘리지 않습니다 |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. `W` 는 Flutter의 `Widget`, Jaspr Web의 `Component` 입니다. 두 플랫폼 모두 `key` 를 받고, `copyWith` 로 일부 값을 바꾼 사본을 만들 수 있습니다.

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `legend` | `W?` | `null` | 묶음의 제목 |
| `description` | `W?` | `null` | 범례 아래의 보조 문구. 넘겼을 때만 그립니다. |
| `children` | `List<W>` | `const []` | 묶는 필드. 위에서 아래로 놓습니다. |

### 상태와 겉모습

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `variant` | `CoreFieldsetVariant` | `filled` | 묶음의 경계 — `filled` · `outlined` · `plain` |
| `enabled` | `bool` | `true` | `false` 면 묶음을 흐리게 그리고 비활성 설정을 안쪽에 전합니다. |
| `size` | `CoreComponentSize` | `md` | 범례 글자 크기 |
| `fieldsetStyle` | `CoreFieldsetStyle?` | `null` | 보이는 값 덮어쓰기 |

### Jaspr Web 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트 `<div>` 의 id |
| `classes` | `String?` | `null` | 루트에 더할 CSS 클래스 |
| `css` | `Styles?` | `null` | 루트의 인라인 스타일. 컴포넌트의 인라인 값 뒤에 합쳐집니다. |
| `attributes` | `Map<String, String>?` | `null` | 루트에 싣는 HTML 속성. `role` · `aria-*` 를 줄 때 씁니다. |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 받지만 루트에 붙이지 않습니다([알려진 제약](/components/fieldset#알려진-제약)). |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreFieldsetStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `padding` | `CoreEdgeInsets?` | Inner padding. |
| `fieldSpacing` | `double?` | Spacing between child widgets within the fieldset (logical px). |
| `borderRadius` | `CoreBorderRadius?` | Outer border radius. |
| `borderWidth` | `double?` | Outer border stroke width (logical px). |
| `backgroundColor` | `CoreColor?` | Container background colour. |
| `borderColor` | `CoreColor?` | Outer border stroke colour. |
| `legendPadding` | `CoreEdgeInsets?` | Padding applied around the legend widget. `null` defers to [defaultLegendPadding]. |
| `legendTextStyle` | `CoreTextStyle?` | Legend text style override. |
| `disabledLegendColor` | `CoreColor?` | Disabled-state legend colour override. `null` → [defaultDisabledLegendColor]. |
| `descriptionTextStyle` | `CoreTextStyle?` | Description text style override. `null` → [defaultDescriptionTextStyle]. |
| `legendDescriptionGapStyle` | `CoreGapStyle?` | Gap between the legend and the description. `null` → [defaultLegendDescriptionGapStyle]. |
| `headerFieldsGapStyle` | `CoreGapStyle?` | Gap between the header (legend, description) and the first field. `null` → [defaultHeaderFieldsGapStyle]. |

### `CoreFieldsetStyle` 변형별 기본값 (`CoreFieldsetStyle`)

| 필드 | `filled` | `outlined` | `plain` |
|------|------|------|------|
| `padding` | CoreEdgeInsets.all(CoreSpace.space16) | CoreEdgeInsets.all(CoreSpace.space16) | zero |
| `borderRadius` | CoreBorderRadius.all(CoreRadiusRole.surface) | CoreBorderRadius.all(CoreRadiusRole.surface) | zero |
| `borderWidth` | stroke1 | stroke1 | stroke0 |
| `backgroundColor` | surfaceContainerLow | transparent | transparent |
| `borderColor` | outlineSubtle | outlineSubtle | transparent |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="fieldset/related-form" title="Form">

폼 전체의 검증과 값을 관리합니다.

</Card>
<Card component="text-field" props="placeholder=이름" title="TextField">

글자 입력 하나를 받습니다. Fieldset 의 비활성 설정을 읽습니다.

</Card>
<Card component="checkbox" props="checked=true" label="동의합니다" title="Checkbox">

Fieldset 의 비활성 설정을 읽지 않으므로 `enabled` 를 따로 줍니다.

</Card>
</Cards>
