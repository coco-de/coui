---
title: Autocomplete
description: 입력하는 동안 맞는 추천을 목록으로 보여 주고, 고른 추천을 입력에 적용하는 텍스트 입력입니다.
category: form
platforms: [flutter, web]
related: [text-field, select, chip-input]
tags: [interactive, form-control, suggestions]
template: v2
source: form/autocomplete
---

# Autocomplete

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 Autocomplete 를 확인하고, 만들어진 코드를 그대로 복사하세요. 무대의 필드를 눌러 입력하면 제안 목록이 열립니다.

<Playground component="autocomplete" />

Autocomplete 는 [TextField](/components/text-field) 입력과, 그 아래에 열리는 [Popover](/components/popover) 제안 목록으로 이루어집니다. 입력할 때마다 `suggestions` 에서 맞는 추천을 걸러 보여 주고, 하나를 고르면 `mode` 에 따라 입력에 적용합니다. 목록에 없는 글자도 그대로 입력 값이 됩니다 — 정해진 값 중 하나만 받아야 하면 [Select](/components/select) 를 씁니다.

`value` 는 처음 값이고, 그 뒤의 입력은 Autocomplete 가 들고 있습니다. 호출자가 다른 `value` 를 넘기면 그 값으로 바뀝니다. `null` 은 지금 값을 그대로 두므로, 비우려면 빈 글자(`''`)를 넘깁니다.

## 구조

열린 Autocomplete 는 입력 필드와 그 아래의 제안 목록 패널로 이루어지고, 패널 안에 걸러진 추천이 한 행씩 놓입니다.

<Anatomy demo="autocomplete/anatomy">
<AnatomyItem select="[aria-haspopup=dialog]" side="left" name="field">

입력 필드. Autocomplete 가 그리는 TextField 이고, 비어 있으면 `placeholder` 를 보여 줍니다. 크기는 TextField 의 기본인 `md`(높이 40)이고, 부모의 가로 폭을 채웁니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=panel]" side="right" name="panel">

제안 목록 패널. 필드 아래 4 떨어져 열리고, 폭은 필드보다 좁아지지 않으며 긴 추천이 있으면 그만큼 넓어집니다. 상자는 Popover 가 그리는 패널이고 배경 `surfaceBright`, 테두리 1 `outlineVariant`, 모서리 12, 그림자 `lg`, 안쪽 여백 6 입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=option]" side="left" name="option">

추천 한 행. 안쪽 여백 8, 모서리 8, 글자는 `bodyMedium` · `onSurfaceVariant` 입니다. 포인터가 올라간 행과 키보드로 강조한 행은 `surfaceContainerHigh` 로 채웁니다(이 그림의 첫 행). 행 사이에는 간격이 없습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=match]" side="right" name="match">

검색어와 일치하는 구간. `onSurface` SemiBold 로 그려, 나머지 글자와 굵기 · 색으로 구분됩니다.

</AnatomyItem>
</Anatomy>

<Note>

열린 목록은 그림입니다. 실제 목록은 필드에 포커스가 있을 때만 열리고 화면 위 층에 올라가므로 이 자리에 열어 둘 수 없습니다. 패널 상자는 킷의 Popup 으로 그려 Popup 테마(`CoreComponentTheme.popup`)는 따르지만, Popover 테마(`CoreComponentTheme.popover`)의 패널 값은 따르지 않습니다. 행은 `CoreAutocompleteStyle` 의 기본값으로 그려, `CoreComponentTheme.autocomplete` · `autocompleteStyle` 의 덮어쓰기는 패널에도 행에도 닿지 않습니다. 실제 목록은 플레이그라운드의 필드에 입력해 열어 봅니다.

</Note>

목록은 화면 위 층에 그려져 둘레 상자의 `overflow` · `transform` 에 잘리지 않고, 화면 가장자리에 닿으면 반대쪽으로 뒤집히거나 옆으로 밀려 화면 안에 머뭅니다(Select 와 같습니다). 자리는 필드 아래 시작선(`bottomStart`)이고, 이 자리와 목록의 폭 규칙은 속성으로 바꿀 수 없습니다. Flutter 에서 가로가 무한한 부모(`Row`)에는 채울 폭이 없어 필드가 내용 폭이 되고, `Expanded` · `SizedBox` 로 폭을 주면 그 폭을 따릅니다.

## 적용 방식

추천을 고르면 `mode` 에 따라 입력에 적용합니다. 목록을 거르는 글자도 `mode` 가 정합니다. 기본값은 `replaceWord` 입니다.

| `mode` | 입력 (커서는 끝) | 거르는 글자 | `바나나` 를 고른 뒤 |
| --- | --- | --- | --- |
| `replaceAll` | `바` | 입력 전체 `바` | `바나나` |
| `replaceWord` | `사과 바` | 커서가 있는 단어 `바` | `사과 바나나` |
| `append` | `바` | 입력 전체 `바` | `바바나나` |

- `replaceAll` 은 값 하나를 통째로 채우는 검색 필드에 씁니다. 고른 추천이 입력 전체를 바꿉니다.
- `replaceWord` 의 단어는 띄어쓰기로 나눕니다. 커서가 단어 가운데 있으면 커서 뒤의 글자까지 그 단어 전체를 바꿉니다. 커서 자리에 단어가 없으면(띄어쓰기 바로 뒤의 끝처럼) 검색어가 비어 추천 전체가 나오고, 고른 추천이 그 자리에 들어갑니다. 고르면 커서는 넣은 추천 바로 뒤에 놓입니다(Web 은 다시 그린 뒤 브라우저가 커서를 놓습니다 — 플랫폼 차이). 목록은 글자를 칠 때 걸러지므로, 커서만 다른 단어로 옮겨서는 다시 걸러지지 않습니다(알려진 제약).
- `append` 는 구분자를 넣지 않고 입력 전체로 거릅니다. 그래서 이미 쓴 글자 뒤에 새 단어를 이어 쓰면 그 단어로 목록이 좁혀지지 않고(입력 전체를 포함하는 추천만 남습니다), 목록을 거른 글자가 고른 추천 앞에 그대로 남습니다.

<a id="동작-스펙-behavior"></a>

## 거르기와 강조

<Preview demo="autocomplete/match" />

- **거르기** — 앞뒤 공백을 지운 검색어를 대소문자 없이 포함하는 추천만 남깁니다. 검색어는 `replaceWord` 에서는 커서가 있는 단어, 나머지 모드에서는 입력 전체입니다. 남은 추천은 `suggestions` 의 순서대로 놓이고 개수 상한은 없습니다. 검색어가 비면 추천 전체가 나옵니다.
- **강조** — 각 추천에서 검색어와 처음 일치하는 구간을 `onSurface` SemiBold 로, 나머지 글자를 `onSurfaceVariant` Regular 로 그립니다. 일치가 앞 · 가운데 · 끝 어디에 있어도 같고(그림의 서울역 · 구서울역사 · 남서울), 검색어가 비면 강조하지 않습니다. 포인터나 키보드로 강조한 행(그림의 둘째 행)도 같은 구간을 굵기로 구분합니다 — 강조한 행은 채움만 바뀌고, 일치하지 않는 글자는 `onSurfaceVariant` 그대로입니다.
- 두 플랫폼이 같은 나눔(`CoreAutocompleteMatch`)을 읽어 같은 글자를 강조합니다. 소문자로 바꾸면 글자 수가 달라지는 글자가 든 추천은 강조하지 않습니다. 일치 구간의 글자 스타일은 `matchTextStyle` 로 바꿉니다.
- 목록을 열어 둔 채 `suggestions` 가 바뀌어도(비동기로 늦게 도착한 목록 등) 다시 걸러 보여 줍니다. 필드에 포커스가 있는데 맞는 추천이 없어 닫혀 있던 목록은, 그때 맞는 추천이 생기면 열립니다.

## 상태

필드의 모양은 TextField 를 따르고, 목록이 열리고 닫히는 규칙만 Autocomplete 가 더합니다.

<Preview demo="autocomplete/states" />

| 항목 | 동작 |
| --- | --- |
| 쉴 때 · Hover · Focus | 필드는 TextField 의 기본 모양을 그대로 씁니다. |
| 열림 | 필드에 포커스가 있고, `enabled` 이고, 걸러진 추천이 하나 이상이면 열립니다. 빈 필드에 포커스만 줘도 추천 전체가 열립니다. |
| 닫힘 | 포커스가 떠나거나, 바깥을 누르거나, `Escape` 를 누르거나, 추천을 고르면 닫힙니다. 걸러진 추천이 없어져도 닫힙니다. |
| 다시 열림 | 추천을 골라 닫은 뒤에는 다음 입력이나 다시 준 포커스에서 열립니다. 부모가 `value` 를 갱신한 것만으로는 다시 열리지 않습니다. `Escape` 로 닫은 뒤도 같지만, Web 은 `value` · `suggestions` 가 바뀌면 다시 열립니다(알려진 제약). |
| 강조한 행 | 포인터가 올라간 행과 키보드로 강조한 행을 같은 채움(`surfaceContainerHigh`)으로 그립니다. 둘이 다른 행을 가리킬 수 있고, `Enter` 는 키보드로 강조한 행을 고릅니다. 글자를 쳐서 입력이 바뀌면 키보드 강조는 풀립니다(Web 은 `suggestions` · `value` 가 바뀔 때는 풀지 않습니다 — 알려진 제약). |
| 비활성 | 입력할 수 없고 목록이 열리지 않습니다. |
| 스크롤 | 행이 240 보다 길어지면 목록 안에서 스크롤합니다(`dropdownMaxHeight`). 필드가 놓인 페이지를 스크롤해도 목록은 닫히지 않습니다. |
| 전환 시간 | 목록은 150ms 동안 열리고 100ms 동안 닫힙니다. |

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

자유롭게 입력받되 추천으로 입력을 돕고 싶을 때 씁니다 — 검색어 입력에 추천어를 함께 보여 주는 자리가 대표적입니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 정해진 선택지 중 하나만 받아야 하고, 목록 밖의 글자가 값이 되면 안 될 때 | [Select](/components/select) |
| 추천 없이 글자만 받을 때 | [TextField](/components/text-field) |
| 여러 값을 하나씩 칩으로 모을 때 | [ChipInput](/components/chip-input) |
| 화면의 명령이나 페이지를 찾아 실행할 때 | [Command](/components/command) |

<a id="do"></a>
<a id="dont"></a>

### 적용 방식 고르기

<Cards columns="2">
<Card component="autocomplete" props="mode=replaceAll;placeholder=역 이름 검색" tone="do" eyebrow="이렇게 하세요">

값 하나를 채우는 검색 필드에는 `replaceAll` 을 줍니다. 고른 추천이 입력 전체를 바꿉니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

태그처럼 여러 값을 이어 붙이려고 `append` 를 쓰지 않습니다. 구분자를 넣지 않고 입력 전체로 거르므로, `바` 에서 `바나나` 를 고르면 `바바나나` 가 됩니다. 띄어쓰기로 나눈 단어를 하나씩 완성하려면 기본값 `replaceWord` 를, 값을 칩으로 모으려면 ChipInput 을 씁니다.

</Card>
</Cards>

### 값 받기

`onChanged` 는 입력이 바뀔 때마다 그 글자를, 추천을 고르면 적용된 뒤의 입력 전체를 줍니다. `onSelected` 는 고른 추천의 원문이라 `replaceWord` · `append` 에서는 입력과 다릅니다 — 그 값을 `value` 로 되돌려 넘기면 입력의 나머지 글자가 사라집니다.

<Split>

<Code language="dart" title="이렇게 하세요">
Autocomplete(
  suggestions: stations,
  value: query,
  onChanged: (text) => setState(() => query = text),
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 고른 추천 하나가 입력 전체를 덮습니다.
// '부산 서' 에서 '서울역' 을 고르면 '서울역' 만 남습니다.
Autocomplete(
  suggestions: stations,
  value: query,
  onSelected: (picked) => setState(() => query = picked),
)
</Code>

</Split>

### 추천 목록

거르기는 입력마다 `suggestions` 전체를 훑는 단순 비교이고, 검색어가 비면 상한 없이 전부 목록에 나옵니다. 목록이 크면 호출자가 미리 좁혀 넘깁니다.

<Split>

<Code language="dart" title="이렇게 하세요">
// 입력에 맞는 후보를 먼저 좁혀서 넘깁니다.
Autocomplete(
  suggestions: searchStations(query, limit: 20),
  value: query,
  onChanged: updateQuery,
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 수백 개 항목을 그대로 넘깁니다.
Autocomplete(
  suggestions: allStationNames,
  onSelected: handleSelected,
)
</Code>

</Split>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

보이는 값은 `autocompleteStyle`(`CoreAutocompleteStyle`) 하나로 덮어씁니다. 행의 글자 · 채움 · 여백 · 모서리와 목록의 최대 높이는 직접 필드로 주고, 필드와 패널 사이 간격은 `popoverStyle`(`CorePopoverStyle`)로, 패널 상자의 배경 · 테두리 · 모서리 · 그림자 · 여백은 그 안의 `panelStyle`(`CorePopupStyle`)로 줍니다.

입력 필드의 모양은 Autocomplete 가 정하지 않습니다. 안의 TextField 는 앱 전체의 TextField 테마(`CoreComponentTheme.textField`)를 따르고, Autocomplete 하나의 필드만 바꾸는 자리는 없습니다.

<Split>

<Code language="dart" title="Autocomplete 하나만 바꾸기">
Autocomplete(
  suggestions: stations,
  onChanged: setQuery,
  autocompleteStyle: CoreAutocompleteStyle(
    dropdownMaxHeight: CoreSpace.space160,
    optionHoverColor: CoreColor.token(CoreColors.surfaceContainerHighest),
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
    autocomplete: CoreAutocompleteTheme(
      style: CoreAutocompleteStyle(
        dropdownMaxHeight: CoreSpace.space160,
      ),
    ),
  ),
)
</Code>

</Split>

### 값이 정해지는 순서

```text
기본값 (CoreAutocompleteStyle.default*)
  → CoreComponentTheme.autocomplete.style   // 앱 전체
  → autocompleteStyle                        // 인스턴스
```

뒤로 갈수록 우선합니다. 글자 필드(`dropdownTextStyle` · `matchTextStyle` · `optionHoverTextStyle`)는 기본값 위에 합쳐지므로 바꿀 것만 적습니다.

목록 패널은 Popover 를 거쳐 한 번 더 이어집니다. Autocomplete 가 넘기는 값(필드 폭 채우기, 간격 4, 패널 여백 6)은 앱 전체의 Popover 테마(`CoreComponentTheme.popover`)보다 우선합니다. 패널 상자의 나머지 값(배경 · 테두리 · 모서리 · 그림자)은 Popover 테마의 `panelStyle`, Popup 테마(`CoreComponentTheme.popup`), Popup 기본값 순으로 찾습니다. Autocomplete 는 이 값들을 넘기지 않으므로, Popover 테마로 바꾼 패널의 모서리 · 배경은 Autocomplete 의 목록에도 닿습니다. 패널 여백은 Autocomplete 가, 최소 폭(0)은 Popover 가 넘기므로 Popup 테마로는 바뀌지 않습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Autocomplete` 에 `withStyle` 로 스타일을 덧붙일 수 있습니다. 생성자의 `autocompleteStyle` 과 같게 동작하고, 겹치는 필드는 뒤에 붙인 값이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class AutocompleteChainExample extends StatefulWidget {
  const AutocompleteChainExample({super.key});

  @override
  State<AutocompleteChainExample> createState() => _AutocompleteChainExampleState();
}

class _AutocompleteChainExampleState extends State<AutocompleteChainExample> {
  String _value = '';

  @override
  Widget build(BuildContext context) {
    return Autocomplete(
      suggestions: const ['사과', '바나나', '체리', '포도', '딸기'],
      value: _value,
      placeholder: '과일을 검색해 주세요',
      onSelected: (v) => setState(() => _value = v),
    ).withStyle(
      const CoreAutocompleteStyle(
        dropdownMaxHeight: CoreSpace.space160,
        optionHoverColor: CoreColor.token(CoreColors.primary),
        optionHoverTextStyle: CoreTextStyle.token(
          CoreTextStyles.bodySmall,
          color: CoreColor.token(CoreColors.onPrimary),
        ),
        optionBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        optionPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space12,
          vertical: CoreSpace.space8,
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class AutocompleteChainExample extends StatefulComponent {
  const AutocompleteChainExample({super.key});

  @override
  State<AutocompleteChainExample> createState() => _AutocompleteChainExampleState();
}

class _AutocompleteChainExampleState extends State<AutocompleteChainExample> {
  String _value = '';

  @override
  Component build(BuildContext context) {
    return Autocomplete(
      suggestions: const ['사과', '바나나', '체리', '포도', '딸기'],
      value: _value,
      placeholder: '과일을 검색해 주세요',
      onSelected: (v) => setState(() => _value = v),
    ).withStyle(
      const CoreAutocompleteStyle(
        dropdownMaxHeight: CoreSpace.space160,
        optionHoverColor: CoreColor.token(CoreColors.primary),
        optionHoverTextStyle: CoreTextStyle.token(
          CoreTextStyles.bodySmall,
          color: CoreColor.token(CoreColors.onPrimary),
        ),
        optionBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        optionPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space12,
          vertical: CoreSpace.space8,
        ),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<Note>

이 예제는 고른 추천(`onSelected`)으로 값을 바꿉니다. 여러 단어를 입력하는 필드라면 값은 `onChanged` 로 받습니다(사용 가이드의 값 받기).

</Note>

<a id="접근성-accessibility"></a>

## 접근성

Jaspr Web 은 입력을 `role="combobox"`, 목록을 `role="listbox"`, 행을 `role="option"` 으로 알립니다. Flutter 에는 이 역할이 없어 목록이 열렸는지와 키보드로 강조한 행만 알립니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 전체를 `Semantics(container: true)` 로 감싸고, 목록이 열렸는지를 필드 쪽의 `expanded` 로 알립니다. 키보드로 강조한 행은 `selected` 입니다. 행을 고르는 동작은 탭으로 옵니다. combobox · listbox · option 역할은 내보내지 않습니다. |
| Jaspr Web | 입력 `<input>` 에 `role="combobox"` · `aria-expanded` · `aria-controls`(목록을 가리킵니다 — 닫혀 있을 때도 붙어, 그때는 문서에 없는 목록을 가리킵니다) · `aria-autocomplete="list"` 가 붙고, 목록이 열려 있고 키보드로 강조한 행이 있을 때만 `aria-activedescendant` 가 그 행을 가리킵니다. 목록은 `role="listbox"`, 행은 `<button type="button" role="option">` 입니다. 행의 `aria-selected` 는 키보드 강조를 뜻합니다 — 입력 값과 같은 추천이라는 뜻이 아닙니다. 목록은 Popover 가 그리는 `role="dialog"` 상자 안에 있습니다. |

### 키보드

포커스는 언제나 입력에 머물고, 열린 목록 안에서는 강조만 움직입니다.

| 키 | 목록이 열려 있을 때 | 목록이 닫혀 있을 때 |
| --- | --- | --- |
| `↓` · `↑` | 강조를 한 칸 옮깁니다. 끝에서 돌아갑니다. 강조가 없으면 `↓` 는 첫 행, `↑` 는 마지막 행으로 갑니다. | 필드가 받습니다. 목록을 열지 않습니다. |
| `Enter` | 강조한 행을 고르고 닫습니다. 강조가 없으면 필드가 받습니다(폼 제출 등). | 필드가 받습니다. |
| `Escape` | 닫습니다. 값은 바뀌지 않습니다. | 처리하지 않습니다. |
| `Tab` · `Shift+Tab` | 다음 · 이전 요소로 가며 목록이 닫힙니다. | 다음 · 이전 요소로 |
| 글자 · `←` · `→` · `Home` · `End` | 필드의 편집 키입니다. 글자를 치면 다시 거르고 키보드 강조가 풀립니다. | 같습니다. 글자를 쳐서 맞는 추천이 생기면 목록이 열립니다. |

포인터로도 추천을 고를 수 있습니다.

### 스크린 리더

- 행의 이름은 추천 글자입니다. 일치 구간을 나눠 그려도 한 이름으로 읽힙니다.
- **Jaspr Web** — 리더는 입력의 `aria-activedescendant` 가 가리키는 행을 읽습니다.
- **Flutter** — 강조가 옮겨 갈 때 따로 읽어 주지 않습니다. 강조한 행에 `selected` 를 붙일 뿐이고, 포커스는 입력에 남습니다.
- 입력의 이름을 줄 라벨 슬롯이 없고, 목록에도 이름이 없습니다. Web 에서는 `placeholder` 가 입력의 유일한 이름입니다.

목록이 열리고 닫힌 것, 걸러진 추천의 개수, 고른 추천이 적용된 것을 알리는 라이브 리전은 없습니다. 펼침 상태와 강조한 행은 위의 역할 · 상태로 알립니다.

### 포커스 관리

- **진입** — `Tab` 으로 입력에 닿습니다. 포커스를 받으면 걸러진 추천이 있는 한 목록이 열립니다. 비어 있는 필드면 추천 전체입니다.
- **열려 있는 동안** — 포커스는 입력에 머뭅니다. 목록은 배경을 막지 않고 포커스를 가두지 않습니다. Flutter 오버레이에 자동 포커스 처리가 있지만, 입력이 이미 포커스를 가지고 있어 일어나지 않습니다.
- **고를 때** — Web 은 행을 누르는 순간 포커스 이동을 막아, 고른 뒤에도 포커스가 입력에 있습니다. Flutter 는 모바일 앱에서 손가락으로 고를 때만 포커스가 입력에 남습니다. 마우스 · 스타일러스로 누르거나 데스크톱 · 웹 빌드에서 누르면, 누르는 순간 필드의 포커스가 풀립니다(알려진 제약).
- **이탈** — 포커스가 입력을 떠나면 목록이 닫힙니다. 포커스가 목록 안으로 들어가지 않으므로, 닫을 때 포커스를 되돌릴 곳도 없습니다.
- Web 의 행은 `<button>` 이라 포커스를 받을 수 있지만, 목록은 문서의 다른 자리(오버레이 층)에 그려지고 입력에서 `Tab` 을 누르면 목록이 닫혀 실제로는 닿지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 닫힌 목록을 키보드로 열 수 없습니다. `↓` · `Alt+↓` 는 목록을 열지 않고, 글자를 다시 치거나 포커스를 다시 줘야 열립니다. |
| 공통 | `replaceWord` 에서 글자를 치지 않고 커서만 옮기면(`←` · `→` · 클릭) 목록이 다시 걸러지지 않습니다. 그 상태에서 고르면 두 플랫폼이 다른 단어를 바꿉니다(플랫폼 차이). |
| 공통 | 라벨 · 도움말 · 오류 문구 슬롯이 없습니다. 바깥에 따로 둔 글자는 입력에 연결되지 않습니다. |
| 공통 | 거르기에 개수 상한이 없습니다. 검색어가 비면 넘긴 목록 전체가 행이 됩니다. |
| 공통 | `Form` · `FormField` 에 값을 보고하지 않습니다. 제출할 값은 `onChanged` 로 받아 직접 들고 있어야 합니다. |
| Flutter | combobox · listbox · option 역할이 없고, 키보드 강조가 옮겨 가도 읽어 주지 않습니다. |
| Flutter | `required` · `name` 이 아무것도 바꾸지 않습니다. 라벨이 없어 필수 표시도 나오지 않습니다. |
| Flutter | 포커스가 떠났다가 돌아와 목록이 다시 열리면, 앞서 키보드로 강조한 행이 그대로 강조돼 있어 `Enter` 가 그 행을 고릅니다. Web 은 강조 없이 열립니다. |
| Flutter | 마우스 · 스타일러스로, 또는 데스크톱 · 웹 빌드에서 추천을 누르면, 누르는 순간 필드의 포커스가 풀려 목록이 닫히기 시작합니다. 손을 떼면 고른 추천이 적용되지만 포커스는 필드에 돌아오지 않습니다. 목록이 닫히는 시간(100ms, 동작 줄이기에서는 바로)보다 오래 누르고 있으면 고름이 적용되지 않을 수 있습니다. 모바일 앱에서 손가락으로 고를 때는 일어나지 않습니다. |
| Jaspr Web | 목록이 열린 채 `Escape` 를 누르면, 같은 키를 문서에서 듣는 둘레의 Dialog 도 함께 닫힐 수 있습니다. Flutter 는 키를 목록에서 멈춥니다. |
| Jaspr Web | `Escape` 로 닫은 뒤 `value` · `suggestions` 가 바뀌면 목록이 다시 열립니다. 목록이 닫히는 동안(100ms) 친 글자는 목록을 다시 열지 않고, 그다음 글자에서 열립니다. |
| Jaspr Web | 목록이 열린 채 `suggestions` · `value` 가 바뀌면 키보드 강조가 같은 순번에 남아, `Enter` 가 새 목록의 그 순번 추천을 고릅니다. Flutter 는 강조를 풉니다. |
| Jaspr Web | 포인터를 올린 채 고르거나 닫으면, 다시 열었을 때 그 순번의 행이 포인터 없이도 채워진 채 보일 수 있습니다. 포인터를 행 위로 움직이면 풀립니다. Flutter 는 닫힐 때 포인터 상태도 버립니다. |
| Jaspr Web | 키보드로 옮긴 강조가 목록의 보이는 범위 밖으로 나가도 스크롤하지 않습니다. Flutter 는 강조한 행이 보이도록 스크롤합니다. |
| Jaspr Web | 입력에 이름을 줄 수 없습니다. `placeholder` 가 유일한 이름이고, 생성자의 `attributes` 는 바깥 틀에 붙어 입력에 닿지 않습니다. |
| Jaspr Web | 입력을 감싼 틀에도 `aria-haspopup="dialog"` · `aria-expanded` 가 붙어, 펼침 상태가 입력과 틀에 두 번 실립니다. |
| Jaspr Web | `<input>` 에 `autocomplete` 속성을 내보내지 않습니다. 브라우저의 자동 완성을 끄지도 켜지도 않습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링과 키 처리는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 입력 필드 | `TextField`(EditableText) | `TextField`(`<input>`) |
| 목록 | `Popover` 의 떠 있는 패널 | 같은 구성. 패널은 오버레이 호스트에 그려집니다 |
| 역할 | 펼침 상태와 강조한 행의 선택 상태만 | `combobox` · `listbox` · `option` |
| 강조 알림 | 없음 | `aria-activedescendant` |
| 강조한 행 스크롤 | 강조한 행을 목록 가운데로 스크롤합니다 | 스크롤하지 않습니다 |
| 다시 열 때의 강조 | 앞서 키보드로 강조한 행이 남아 있을 수 있습니다 | 닫히면 키보드 강조가 풀립니다. 포인터를 올렸던 순번의 행은 포인터를 행 위로 움직일 때까지 채워진 채 보일 수 있습니다 |
| 목록이 열린 채 `suggestions` · `value` 가 바뀔 때 | 키보드 강조가 풀립니다 | 키보드 강조가 같은 순번에 남습니다 |
| 포인터로 고르기 | 손을 뗄 때(탭) | 누르는 순간 |
| 고른 뒤 포커스 | 모바일 앱에서 손가락으로 고르면 입력에 남습니다. 마우스 · 스타일러스와 데스크톱 · 웹 빌드에서는 누르는 순간 풀립니다 | 입력에 남습니다 |
| 커서만 옮긴 뒤 고를 때 (`replaceWord`) | 옮긴 커서가 있는 단어를 바꿉니다 | 마지막으로 글자를 치거나 추천을 넣은 자리의 단어를 바꿉니다 |
| 행 채움 전환 | 바로 바뀝니다 | 짧게 바뀝니다(`transition-colors`) |
| `Escape` | 목록이 받아 바깥으로 넘기지 않습니다 | 문서에서 듣는 Popover 가 닫고, 바깥의 Dialog 도 같은 키를 받을 수 있습니다 |
| `Escape` 뒤 다시 열림 | 다음 입력 · 다시 준 포커스 | 그 밖에 `value` · `suggestions` 가 바뀔 때도 |
| 고른 뒤 커서 | 넣은 추천 바로 뒤에 놓습니다 | 값을 다시 그린 뒤 브라우저가 놓습니다 |
| `required` · `name` | 바뀌는 것이 없습니다 | `<input required>` · `<input name>` |
| 콜백 타입 | `ValueChanged<String>?` | `CoreValueChanged<String>?` |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `onClick` 등 (바깥 틀에 붙습니다) |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다.

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `suggestions` | `List<String>` | 필수 | 추천 글자 목록. 걸러진 추천이 이 순서대로 행이 됩니다. |
| `value` | `String?` | `null` | 처음 입력 값. 호출자가 다른 값을 넘기면 그 값으로 바뀝니다. `null` 은 지금 값을 그대로 두므로, 비우려면 빈 글자를 넘깁니다. |
| `placeholder` | `String?` | `null` | 비어 있을 때 보이는 안내 |

### 상태와 동작

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `mode` | `CoreAutocompleteMode` | `replaceWord` | 거르는 글자와 고른 추천을 적용하는 방식 — replaceAll, replaceWord, append |
| `enabled` | `bool` | `true` | false 면 입력할 수 없고 목록이 열리지 않습니다. |
| `required` | `bool` | `false` | Web 은 `<input required>` 를 붙입니다. Flutter 에서는 바뀌는 것이 없습니다. |
| `name` | `String?` | `null` | Web 은 `<input name>` 이라 HTML `<form>` 제출에 실립니다. Flutter 에서는 쓰이지 않습니다. |
| `autocompleteStyle` | `CoreAutocompleteStyle?` | `null` | 보이는 값 덮어쓰기 |

### 콜백

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `onChanged` | `ValueChanged<String>?` (Web `CoreValueChanged<String>?`) | `null` | 입력이 바뀔 때마다 그 글자를, 추천을 고르면 적용된 뒤의 입력 전체를 받습니다. |
| `onSelected` | `ValueChanged<String>?` (Web `CoreValueChanged<String>?`) | `null` | 고른 추천의 원문을 받습니다. 같은 선택에서 `onChanged` 다음에 불리고, 그 뒤 목록이 닫힙니다. |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreAutocompleteStyle patch)` | `autocompleteStyle` 에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다. |
| `copyWith({suggestions, value, mode, …})` | 바꾼 값으로 사본을 만듭니다. 웹은 `id` · `classes` · `css` · `attributes` · 이벤트도 받습니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.autocomplete` | `CoreAutocompleteTheme?` | `style` 하나만 가집니다. variant 별 덮어쓰기는 없습니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreAutocompleteStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `popoverStyle` | `CorePopoverStyle?` | Style for the `Popover` that wraps the input (trigger) and the suggestion panel. Sets the gap between input and panel, and the panel box's border, corners, shadow and padding (through `popoverStyle.panelStyle`, a `CorePopupStyle`). `null` leaves the panel at the design-system `Popup` defaults. |
| `dropdownTextStyle` | `CoreTextStyle?` | Suggestion / option text style override (enabled / non-hovered) for the part of the label that does not match the query. Text colour is carried via [CoreTextStyle.color] inside this slot. |
| `matchTextStyle` | `CoreTextStyle?` | Text style override for the part of the label that matches the query (SemiBold `onSurface` by default). Merged over the label's base style, so a caller states only what differs. |
| `dropdownMaxHeight` | `double?` | Suggestion-list maximum height override (logical px). Constrains the option list, not the panel box (which is owned by the composed `Popover`). Defaults to [defaultDropdownMaxHeight]. |
| `optionHoverColor` | `CoreColor?` | Option hover background colour override. |
| `optionHoverTextStyle` | `CoreTextStyle?` | Option text style override applied when the option is hovered. Text colour is carried via [CoreTextStyle.color] inside this slot. |
| `optionBorderRadius` | `CoreBorderRadius?` | Option row border radius override. |
| `optionPadding` | `CoreEdgeInsets?` | Option row padding override. |

<!-- STYLE_TABLE:END -->

<Note>

`optionHoverColor` · `optionHoverTextStyle` 은 포인터가 올라간 행만이 아니라 키보드로 강조한 행에도 쓰입니다. `dropdownMaxHeight` 는 행 목록의 높이이고, 패널 상자는 그보다 안쪽 여백과 테두리만큼 큽니다.

`popoverStyle` 을 비워 두어도 패널은 Popup 의 기본값 그대로가 아닙니다. Autocomplete 가 필드 폭 채우기 · 간격 4 · 패널 여백 6 을 넘기고, Popover 가 패널의 최소 폭을 0 으로 둡니다(Popup 의 기본값은 여백 16 · 최소 폭 128). `popoverStyle` 에 준 값은 이 위에 합쳐집니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card component="select" props="placeholder=카테고리를 선택하세요" title="Select">

정해진 선택지 중 하나만 고르게 합니다. 목록 밖의 글자는 값이 되지 않습니다.

</Card>
<Card component="text-field" props="placeholder=직접 입력" title="TextField">

추천 없이 글자만 받습니다. Autocomplete 의 입력 필드이기도 합니다.

</Card>
<Card demo="autocomplete/related-chip-input" title="ChipInput">

입력한 값을 칩으로 하나씩 모읍니다.

</Card>
</Cards>
