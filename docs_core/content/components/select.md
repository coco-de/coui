---
title: Select
description: 펼침 목록에서 정해진 선택지 하나를 고르게 하는 입력입니다.
category: form
platforms: [flutter, web]
related: [text-field, menu, autocomplete]
tags: [form-control, dropdown, picker]
template: v2
source: form/select
---

# Select

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 Select 를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="select" />

Select 는 읽기 전용 [TextField](/components/text-field) 트리거와, 누르면 열리는 [Popover](/components/popover) 목록으로 이루어집니다. 목록의 각 행은 [MenuItem](/components/menu-item) 입니다. `value` 는 처음 고른 값이고, 사용자가 고르면 호출자가 다시 넘기지 않아도 트리거에 바로 표시됩니다. 호출자가 다른 `value` 를 넘기면 그 값으로 바뀝니다.

<a id="구조-anatomy"></a>

## 구조

Select 는 라벨, 트리거, 꺾쇠, 도움말로 이루어지고, 누르면 아래에 선택지 목록이 열립니다.

<Anatomy demo="select/anatomy">
<AnatomyItem select="label > span" side="left" name="label">

트리거 위의 필드 라벨.

</AnatomyItem>
<AnatomyItem select="input" side="left" name="trigger">

고른 값을 보여 주는 닫힌 필드. 아무것도 고르지 않았으면 `placeholder` 를 보여 줍니다.

</AnatomyItem>
<AnatomyItem select="svg" side="right" name="suffix">

트리거 오른쪽의 꺾쇠. `suffix` 로 다른 글자나 아이콘으로 바꿀 수 있습니다.

</AnatomyItem>
<AnatomyItem select="p" side="left" name="description">

트리거 아래 도움말. `errorText` 가 있으면 그 문구로 바뀝니다.

</AnatomyItem>
</Anatomy>

선택지는 `items` 의 `CoreSelectItem(value:, label:)` 로 줍니다. 행의 내용을 바꾸려면 `CoreSelectItem.child` 에 위젯을 넣습니다 — 트리거에는 고른 행의 `label` 이 그대로 표시되므로 행이 복잡해도 트리거는 단순합니다. 고를 수 있는 선택지가 하나도 없으면 목록에 빈 상태 문구가 나옵니다.

<a id="변형-variants"></a>

## Variant

배경이 있는 화면에서는 filled 를, 그 밖에는 기본(defaultVariant)을 씁니다.

<VariantRow name="defaultVariant" component="select" props="variant=defaultVariant;placeholder=카테고리를 선택하세요">

테두리가 있는 기본 트리거입니다.

</VariantRow>

<VariantRow name="filled" component="select" props="variant=filled;placeholder=카테고리를 선택하세요">

테두리 대신 채움으로 경계를 나타냅니다. 카드나 시트 안처럼 이미 틀이 있는 면 위에 씁니다.

</VariantRow>

<Note>

error 는 보통 직접 고르지 않습니다. `errorText` 를 주면 켜지고, 비활성일 때는 꺼집니다. filled 에 `errorText` 를 주면 채움 대신 오류 모양으로 그립니다.

</Note>

## 크기

트리거 높이 32 · 40 · 48 의 3단계입니다. 옵션 행도 같은 이름의 단을 따르며, `md` 행은 트리거(40)보다 한 단 낮은 36 입니다.

<SizeSpec component="select" props="placeholder=선택" />

<Note>

값 글자는 세 크기 모두 14 입니다(TextField 의 값 글자와 같습니다). 목록 패널은 크기와 무관하게 안쪽 여백 6, 모서리 12, 행 사이 간격 2 이고, 트리거와 4 떨어져 열립니다. 행의 모서리는 패널 안에 맞춰 모든 크기에서 6 입니다.

</Note>

<a id="동작-스펙-behavior"></a>
<a id="상태-전환"></a>

## 상태

트리거는 TextField 의 상태를 따르고, 눌렀을 때 채움을 덮는 것만 Select 가 더합니다.

<Preview demo="select/states" />

| 항목 | 동작 |
| --- | --- |
| 쉴 때 | 테두리 `outlineVariant`, 채움 `surface` |
| Hover | 테두리가 `outline` 으로 한 단 진해집니다. 채움은 바뀌지 않습니다. |
| 눌림 | 채움 위에 `onSurface` 12% 를 덮습니다. 테두리는 누른다고 바뀌지 않고 Focus · Hover 행을 따르므로, 포커스가 있으면 `primary` 입니다 — 열린 목록을 닫으려고 다시 누를 때가 그렇고, Web 에서는 입력 부분을 누르는 순간 포커스가 들어옵니다. |
| Focus | 테두리가 `primary` 로 바뀝니다. 키보드로 포커스했을 때만 바깥에 링을 그립니다. 테두리 굵기는 1 그대로라 트리거 크기가 변하지 않습니다. |
| 오류 | 모든 상태에서 테두리와 링이 `error` 입니다. `errorText` 가 있으면 도움말 대신 그 문구를 보여 줍니다. |
| 비활성 | 테두리 `disabledOutline`, 채움 `disabledContainer`, 값 `disabledContent`. 비활성이 오류보다 우선합니다. 목록이 열리지 않습니다. |
| 고른 행 | 행 맨 앞에 체크 표시를 그리고, 행을 `primary` 로 채워 `onPrimary` 글자로 그립니다. 체크 칸은 모든 행에 비워 두어 라벨 시작선이 흔들리지 않습니다. |
| 열고 닫기 | 트리거를 누르면 열리고 닫힙니다. 고르면 닫히고, 바깥을 누르거나 `Escape` 를 눌러도 닫힙니다. |
| 스크롤 | 트리거가 놓인 스크롤 영역이 움직이면 목록이 닫힙니다(`closeOnScroll`). 목록 안의 스크롤은 닫지 않습니다. |
| 전환 시간 | 트리거 색은 150ms, 목록은 150ms 동안 열리고 100ms 동안 닫힙니다. |

<a id="드롭다운-열기닫기"></a>

### 목록의 폭과 자리

- 트리거는 부모의 가로 폭을 채웁니다. 내용 폭으로 줄이려면 `selectStyle: CoreSelectStyle(popoverStyle: CorePopoverStyle(triggerSizing: .intrinsic))` 을 줍니다. Flutter 에서 가로가 무한한 부모(`Row`)에는 채울 폭이 없어 트리거가 내용 폭이 되고, `Expanded` · `SizedBox` 로 폭을 주면 그 폭을 따릅니다.
- 목록의 폭은 기본적으로 트리거 폭과 같습니다(`anchorFixedSize`). 좁은 트리거에서 선택지가 잘리면 `popoverWidthConstraint: CorePopoverConstraint.anchorMinSize` 로 트리거 폭을 최소로 쓰면서 내용에 맞게 넓힙니다.
- 목록의 자리는 `popoverPlacement`(기본 `bottomStart`), 화면 가장자리에서의 처리는 `popoverCollision` 이 정합니다. 목록이 300 보다 길면 그 안에서 스크롤합니다(`optionsPanelMaxHeight`).

<a id="타입어헤드-검색-아님"></a>

### 글자 키는 이동이지 검색이 아닙니다

Select 는 목록을 거르지 않습니다. 글자 키를 누르면 그 글자로 시작하는 다음 선택지로 **이동**합니다. 500ms 안에 이어 친 글자는 하나의 앞부분으로 봅니다. 입력하면서 목록을 좁히려면 [Autocomplete](/components/autocomplete) 를 씁니다. Select 는 하나만 고릅니다 — 여러 개를 고르려면 ChipGroup 의 다중 선택이나 Checkbox 목록을 씁니다.

<a id="트리거-보조-문구"></a>

### 트리거 오른쪽 글자

`suffix` 로 기본 꺾쇠를 다른 글자나 아이콘으로 바꿀 수 있습니다. 고르는 동작은 Select 가 맡으므로, `suffix` 에 버튼이나 포커스를 받는 입력을 넣지 않습니다.

<Preview demo="select/suffix" />

```dart
Select<String>(
  value: 'KRW',
  suffix: Text('변경'),
  onChanged: setCurrency,
  items: const [
    CoreSelectItem(value: 'KRW', label: 'KRW'),
    CoreSelectItem(value: 'USD', label: 'USD'),
  ],
)
```

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 정해진 값이 아니라 자유롭게 입력받을 때 | [TextField](/components/text-field) |
| 입력하면서 선택지를 좁혀 고를 때 | [Autocomplete](/components/autocomplete) |
| 선택지가 적고 모두 한눈에 보여야 할 때 | [RadioGroup](/components/radio-group) |
| 값을 고르는 것이 아니라 행동을 고를 때 | [DropdownMenu](/components/dropdown-menu) |
| 목록이 아닌 입력 · 행동 패널 | [Popover](/components/popover) |

### 라벨과 선택지

<Cards columns="2">
<Card component="select" props="label=국가;placeholder=국가를 선택하세요" tone="do" eyebrow="이렇게 하세요">

라벨을 보여 주고, `placeholder` 로 무엇을 골라야 하는지 안내합니다.

</Card>
<Card component="select" tone="dont" eyebrow="이렇게 하지 마세요">

라벨도 안내도 없는 빈 트리거는 무엇을 골라야 하는지 알 수 없습니다.

</Card>
<Card demo="select/related-autocomplete" tone="do" eyebrow="이렇게 하세요">

선택지가 수십 개면 입력하며 좁혀 고르는 Autocomplete 를 씁니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

수백 개의 선택지를 Select 에 늘어놓지 않습니다. 목록이 길어지고 글자 키로도 닿기 어렵습니다.

</Card>
</Cards>

<a id="스타일-시스템-style-system"></a>
<a id="스타일-시스템-selectstyle"></a>

## 테마와 스타일

variant · 크기와 목록의 자리 · 폭 · 스크롤 정책은 위젯 속성으로 고르고, 보이는 값은 `selectStyle`(`CoreSelectStyle`) 하나로 덮어씁니다. Select 는 세 컴포넌트를 안에 그리므로, 각 부품의 스타일을 그 컴포넌트의 Style 그대로 넘깁니다 — 트리거는 `triggerStyle`(`CoreTextFieldStyle`), 목록 패널은 `popoverStyle`(`CorePopoverStyle`), 행은 `optionStyle`(`CoreMenuItemStyle`).

<Split>

<Code language="dart" title="Select 하나만 바꾸기">
Select(
  items: items,
  value: category,
  onChanged: setCategory,
  selectStyle: CoreSelectStyle(
    optionsPanelMaxHeight: 240,
    triggerStyle: CoreTextFieldStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
    popoverStyle: CorePopoverStyle(
      panelStyle: CorePopupStyle(
        padding: CoreEdgeInsets.all(CoreSpace.space8),
      ),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    select: CoreSelectTheme(
      style: CoreSelectStyle(
        optionsPanelMaxHeight: 240,
      ),
    ),
  ),
)
</Code>

</Split>

<a id="selectstyle-슬롯"></a>
<a id="aschild-패턴-옵션-행-위젯-주입"></a>
<a id="커스텀-옵션-행"></a>

### 행의 내용 바꾸기

행의 여백이나 글자처럼 모양을 바꿀 때는 `optionStyle` 을, 행에 들어갈 **내용**을 바꿀 때는 `CoreSelectItem.child` 를 씁니다.

```dart
CoreSelectItem(
  value: 'apple',
  label: '사과',
  child: Row(
    spacing: CoreSpace.space8,
    children: [Icon(LucideIcons.apple), Text('사과').bodyMedium],
  ),
)
```

`child` 가 없으면 `label` 이 행에 그려집니다. 행 안의 글자에는 색을 직접 정하지 않습니다 — 고른 행은 글자를 `onPrimary` 로 그리는데, 직접 정한 색은 고른 행에서도 그 색으로 남아 `primary` 바탕 위에서 읽기 어려워집니다. 트리거에는 언제나 `label` 이 표시됩니다.

### 빠른 오버라이드 (Chain)

이미 만든 `Select` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `selectStyle` 인자와 같게 동작합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class SelectChainExample extends StatefulWidget {
  const SelectChainExample({super.key});

  @override
  State<SelectChainExample> createState() => _SelectChainExampleState();
}

class _SelectChainExampleState extends State<SelectChainExample> {
  String? _value = 'apple';

  void handleChanged(String value) {
    setState(() => _value = value);
  }

  @override
  Widget build(BuildContext context) {
    return Select<String>(
      items: const [
        CoreSelectItem(value: 'apple', label: '사과'),
        CoreSelectItem(value: 'banana', label: '바나나'),
        CoreSelectItem(value: 'orange', label: '오렌지'),
      ],
      value: _value,
      placeholder: '과일을 선택해 주세요',
      onChanged: handleChanged,
    ).withStyle(
      const CoreSelectStyle(
        optionSpacing: CoreSpace.space4,
        trailingIconStyle: CoreIconStyle(
          size: CoreSize.size20,
          color: CoreColor.token(CoreColors.primary),
        ),
        placeholderColor: CoreColor.token(CoreColors.onSurfaceVariant),
        contentColor: CoreColor.token(CoreColors.primary),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class SelectChainExample extends StatefulComponent {
  const SelectChainExample({super.key});

  @override
  State<SelectChainExample> createState() => _SelectChainExampleState();
}

class _SelectChainExampleState extends State<SelectChainExample> {
  String? _value = 'apple';

  void handleChanged(String value) {
    setState(() => _value = value);
  }

  @override
  Component build(BuildContext context) {
    return Select<String>(
      items: const [
        CoreSelectItem(value: 'apple', label: '사과'),
        CoreSelectItem(value: 'banana', label: '바나나'),
        CoreSelectItem(value: 'orange', label: '오렌지'),
      ],
      value: _value,
      placeholder: '과일을 선택해 주세요',
      onChanged: handleChanged,
    ).withStyle(
      const CoreSelectStyle(
        optionSpacing: CoreSpace.space4,
        trailingIconStyle: CoreIconStyle(
          size: CoreSize.size20,
          color: CoreColor.token(CoreColors.primary),
        ),
        placeholderColor: CoreColor.token(CoreColors.onSurfaceVariant),
        contentColor: CoreColor.token(CoreColors.primary),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<Note>

활성 상태에서 꺾쇠는 `placeholderColor` 색으로 그려집니다 — `trailingIconStyle` 의 `color` 는 쓰이지 않습니다. 꺾쇠 색을 바꾸려면 `placeholderColor` 를 바꿉니다(빈 트리거의 안내 글자 색도 함께 바뀝니다).

</Note>

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
기본값 (default* · defaultsBySize[size])
  → CoreComponentTheme.select.style                    // 앱 전체
  → CoreComponentTheme.select.variantStyles[variant]   // 앱 전체, variant 별
  → selectStyle                                        // 인스턴스
```

뒤로 갈수록 우선합니다. `variantStyles` 는 위젯의 `variant` 로 찾습니다 — `errorText` 만 주고 `variant` 를 지정하지 않으면 `variantStyles[CoreSelectVariant.error]` 는 쓰이지 않습니다. 안의 TextField · Popover · MenuItem 은 각자 자기 테마를 먼저 받고, 그 위에 Select 가 넘기는 값(트리거의 눌림 채움과 글자 색, 패널의 여백 · 모서리 · 간격, 행의 모서리)과 `selectStyle` 의 부품 스타일이 얹힙니다. 그래서 `CorePopoverTheme` 으로 패널 모서리를 바꿔도 Select 의 패널은 12 그대로이고, Select 의 패널은 `popoverStyle` 로 바꿉니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreSelectStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `triggerStyle` | `CoreTextFieldStyle?` | Look of the trigger field, passed as is to the `TextField` inside. `null` uses [defaultTriggerStyle]. |
| `popoverStyle` | `CorePopoverStyle?` | Style for the popover: the look of the options panel and its gap from the trigger. `null` uses [defaultPopoverStyle]. |
| `optionStyle` | `CoreMenuItemStyle?` | Look of each option row, passed as is to its `MenuItem`. `null` uses [defaultOptionStyle]. |
| `emptyStateStyle` | `CoreTextStyle?` | Empty-state text style (rendered when the list is empty). |
| `optionsPanelMaxHeight` | `double?` | Maximum height of the option list in the panel before it scrolls (logical px). It limits the list, Select's own scroll area, not the panel box; set the panel's look (background / border / radius / padding / shadow) through [popoverStyle]`.panelStyle` (a `CorePopupStyle`). |
| `optionSpacing` | `double?` | Gap between consecutive option rows. `null` → [defaultOptionSpacing]. |
| `trailingIconStyle` | `CoreIconStyle?` | Icon style of the trigger's chevron. `null` uses the size ladder ([defaultsBySize]). The colour follows [placeholderColor]. |
| `placeholderColor` | `CoreColor?` | Trigger placeholder text colour override (shown when no value is selected). Defaults to [defaultPlaceholderColor]. Also the chevron colour. |
| `selectedIconColor` | `CoreColor?` | Selected-option mark colour override. Defaults to [defaultSelectedIconColor]. |
| `emptyStateInsets` | `CoreEdgeInsets?` | Empty-state surface padding override (around the "no results" text). Defaults to [defaultEmptyStateInsets]. |
| `emptyStateColor` | `CoreColor?` | Empty-state text colour override. Defaults to [defaultEmptyStateColor]. |
| `contentColor` | `CoreColor?` | Trigger content (selected value) text colour override. `null` → [defaultContentColor]. |

<!-- STYLE_TABLE:END -->

<a id="접근성-accessibility"></a>

## 접근성

Jaspr Web 은 트리거를 `role="combobox"`, 목록을 `role="listbox"`, 행을 `role="option"` 으로 알립니다. Flutter 에는 이 역할이 없어 행의 선택 상태와 트리거의 열림 상태만 알립니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 트리거는 읽기 전용 텍스트 필드(값 = 고른 라벨)이고, 열림 여부를 `expanded` 로 알립니다. 행은 역할 없이 선택 · 활성 상태만 알립니다. combobox · listbox 역할은 내보내지 않습니다. |
| Jaspr Web | 트리거 `<input readonly>` 에 `role="combobox"` · `aria-expanded` · `aria-haspopup="listbox"` · `aria-controls` · `aria-autocomplete="none"` 이 붙고, 열려 있는 동안 `aria-activedescendant` 가 하이라이트된 행을 가리킵니다. 목록은 `role="listbox"`, 행은 `role="option"` · `aria-selected` 입니다. |

### 키보드

포커스는 언제나 트리거에 머물고, 열린 목록 안에서는 하이라이트만 움직입니다.

| 키 | 닫혀 있을 때 | 열려 있을 때 |
| --- | --- | --- |
| `Enter` · `Space` | 엽니다 | 하이라이트된 행을 고르고 닫습니다. 하이라이트가 없으면 아무 일도 하지 않습니다. |
| `Alt` · `↓` | 값은 그대로 두고 엽니다 | 하이라이트를 한 칸 내립니다 |
| `↓` · `↑` | **값을** 다음 · 이전 선택지로 바로 바꿉니다(끝에서 멈춤) | 하이라이트를 옮깁니다(끝에서 돌아감) |
| `Home` · `End` | 첫 · 마지막 값으로 바꿉니다 | 첫 · 마지막 행을 하이라이트합니다 |
| 글자 키 | 그 글자로 시작하는 다음 선택지로 값을 옮깁니다 | 그 글자로 시작하는 행으로 하이라이트를 옮깁니다 |
| `Escape` | — | 닫습니다. 값은 바뀌지 않고 포커스는 트리거에 남습니다. |
| `Tab` · `Shift` · `Tab` | 다음 · 이전 요소로 | 닫고 다음 · 이전 요소로 |

`PageUp` · `PageDown` 은 처리하지 않습니다. 열 때는 고른 행이 하이라이트되고, 아무것도 고르지 않았으면 하이라이트 없이 열립니다.

### 스크린 리더

- **Jaspr Web** — 리더는 트리거의 `aria-activedescendant` 가 가리키는 행을 읽습니다. 트리거의 값은 고른 라벨입니다. `errorText` 가 있으면 트리거가 `aria-invalid="true"` 가 되고, `required` 면 `required` 가 붙습니다.
- **Flutter** — 목록이 열려 하이라이트가 놓이거나 옮겨 갈 때마다 그 행의 `label` 을 읽어 줍니다. 플랫폼이 읽어 주기를 지원하지 않으면 아무것도 쌓지 않습니다. 필수 · 오류 상태는 알리지 않습니다.

두 플랫폼 모두 값이 바뀐 사실을 알리는 라이브 리전은 따로 없습니다.

### 포커스 관리

`Tab` 으로 트리거에 닿고, 목록을 열어도 포커스는 옮겨지지 않습니다(목록은 배경을 막지 않습니다). 키보드로 고르거나 `Escape` 로 닫으면 포커스는 트리거에 남습니다. 포커스를 가두지 않고, 트리거의 포커스 링은 키보드로 포커스했을 때만 나타납니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | `label` 이 트리거 입력에 연결되지 않아, 입력의 이름은 `placeholder` 에서만 옵니다. `label` 은 열린 목록의 `aria-label` 로만 쓰입니다. 생성자의 `attributes` 는 바깥 틀에 붙어 입력에 닿지 않습니다. |
| Jaspr Web | `description` · `errorText` 문구가 `aria-describedby` 로 연결되지 않습니다. `variant: error` 만 주면 `aria-invalid` 도 붙지 않습니다. |
| Jaspr Web | 키보드로 옮긴 하이라이트가 화면에 보이지 않습니다(스크린 리더에는 전달됩니다). Flutter 는 행에 옅은 채움을 깝니다. |
| Jaspr Web | 마우스로 선택지를 고르면 포커스가 트리거로 돌아오지 않을 수 있습니다. Flutter 는 돌아옵니다. |
| Jaspr Web | Dialog 안에서 목록을 연 채 `Escape` 를 누르면 Dialog 까지 닫힐 수 있습니다. |
| Flutter | combobox · listbox · option 역할을 알리지 않습니다. |
| 공통 | `CoreSelectItem(enabled: false)` 선택지는 목록에 나오지 않습니다(흐린 행으로 보이지 않습니다). 키보드로도 닿지 않습니다. |
| 공통 | 아무것도 고르지 않고 연 목록에서 `↑` 를 누르면 마지막 행이 아니라 끝에서 두 번째 행이 하이라이트됩니다. |
| 공통 | 하이라이트된 행이 목록 밖으로 나가도 스크롤해 보여 주지 않습니다. |
| 공통 | `Form` · `FormField` 에 값을 보고하지 않습니다. 제출할 값은 `onChanged` 로 받아 직접 들고 있어야 합니다. |
| 공통 | `selectedIconColor` 는 아직 화면에 반영되지 않습니다. 고른 행의 체크는 행의 글자 색(`onPrimary`)으로 그려집니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 목록 구현 | `Popover` · `TextField` 트리거 · `MenuItem` 행 | 같은 합성. 목록은 오버레이 호스트에 그려집니다 |
| 역할 | 행의 선택 상태와 트리거의 열림 상태만 | `combobox` · `listbox` · `option` |
| 하이라이트 알림 | 하이라이트된 행의 `label` 을 읽어 줍니다 | `aria-activedescendant` |
| 하이라이트 표시 | 행에 옅은 채움. 고른 행은 고른 채움이 덮어 하이라이트가 보이지 않으므로, 값이 있는 채로 열면 한 칸 옮길 때까지 보이지 않습니다 | 보이지 않음 |
| 마우스로 고른 뒤 포커스 | 트리거로 돌아옵니다 | 돌아오지 않을 수 있습니다 |
| 글자 키 | 같은 글자를 반복하면 앞부분이 길어집니다. 이어 친 앞부분도 지금 선택지의 다음부터 돌아가며 찾으므로, 지금 선택지가 맞아도 맞는 다른 선택지가 있으면 그리로 옮겨 갑니다 | 같은 글자를 반복하면 그 글자로 시작하는 다음 선택지로 돕니다. 이어 친 앞부분은 지금 선택지부터 찾으므로, 지금 선택지가 맞으면 그대로 머뭅니다 |
| `Escape` | 바깥(Dialog 등)으로 전달하지 않습니다 | 바깥으로 전달될 수 있습니다 |
| 필수 · 오류 알림 | 알리지 않습니다 | `required` · `aria-invalid` |
| `CoreSelectItem.child` | `Widget` | `Component` |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `onClick` 등 (바깥 틀에 붙습니다) |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. `T` 는 값의 타입입니다.

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `items` | `List<CoreSelectItem<T>>` | 필수 | 선택지 목록 |
| `value` | `T?` | `null` | 고른 값. 호출자가 다른 값을 넘기면 바뀝니다. |
| `placeholder` | `String?` | `null` | 아무것도 고르지 않았을 때 보이는 안내 |
| `label` | `String?` | `null` | 트리거 위 필드 라벨 |
| `labelMaxLines` | `int?` | `null` | 라벨의 최대 줄 수. 지정하지 않으면 제한하지 않습니다. |
| `labelOverflow` | `CoreTextOverflow?` | `null` | 최대 줄 수를 넘긴 라벨의 처리 |
| `description` | `String?` | `null` | 트리거 아래 도움말. `errorText` 가 있으면 숨깁니다. |
| `errorText` | `String?` | `null` | 지정하면 오류 상태가 됩니다. |
| `suffix` | `Widget?` (Web `Component?`) | `null` | 기본 꺾쇠 대신 그릴 글자나 아이콘. 누르는 요소는 넣지 않습니다. |

### 상태와 형태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `variant` | `CoreSelectVariant` | `defaultVariant` | defaultVariant, error, filled |
| `size` | `CoreSelectSize` | `md` | sm, md, lg |
| `required` | `bool` | `false` | 라벨에 필수 표시를 붙입니다. |
| `enabled` | `bool` | `true` | false 면 비활성. `onChanged` 유무와 상관없습니다. |
| `selectStyle` | `CoreSelectStyle?` | `null` | 보이는 값 덮어쓰기 |

### 목록과 콜백

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `onChanged` | `void Function(T value)?` | `null` | 고른 값을 받습니다. 이미 고른 값을 다시 골라도 불립니다. |
| `popoverPlacement` | `CorePopoverPlacement` | `bottomStart` | 목록이 열리는 자리 |
| `popoverCollision` | `Set<CorePopoverCollision>` | `CorePopoverStyle.defaultCollision` | 화면 가장자리에서의 처리 |
| `popoverWidthConstraint` | `CorePopoverConstraint` | `anchorFixedSize` | 목록과 트리거의 폭 관계 |
| `closeOnScroll` | `bool` | `true` | 트리거가 놓인 스크롤 영역이 움직이면 목록을 닫습니다. |

### CoreSelectItem

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `T` | 필수 | 이 선택지의 값 |
| `label` | `String` | 필수 | 행과 트리거에 보이는 글자 |
| `child` | `Object?` | `null` | 행에 대신 그릴 위젯(Flutter `Widget`, Web `Component`) |
| `enabled` | `bool` | `true` | false 면 목록에서 빠집니다. |

<a id="관련-컴포넌트-related-components"></a>
<a id="조합-예제"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card component="text-field" props="placeholder=직접 입력" title="TextField">

정해진 선택지 없이 자유롭게 입력받습니다.

</Card>
<Card demo="select/related-autocomplete" title="Autocomplete">

입력하면서 선택지를 좁혀 고릅니다.

</Card>
<Card component="radio-group" props="orientation=horizontal;options=2" title="RadioGroup">

선택지가 적을 때 모두 펼쳐 두고 고릅니다.

</Card>
</Cards>
