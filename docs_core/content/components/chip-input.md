---
title: ChipInput
description: 칩(태그) 형태로 여러 항목을 입력하고 관리하는 컴포넌트입니다. Enter 로 확정한 글을 부모가 칩 목록에 더하고, 칩마다 지우기 버튼이 붙습니다.
category: form
platforms: [flutter, web]
related: [chip, text-field, autocomplete]
tags: [interactive, form-control, multi-select, tags]
template: v2
source: form/chip_input
---

# ChipInput

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

칩을 지우고 새 칩을 입력해 보며 ChipInput 을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="chip-input" />

칩 목록(`chips`)은 부모가 들고 있는 `List<String>` 입니다. ChipInput 은 Enter 로 확정한 글을 `onSubmitted` 로, 칩을 지운 목록을 `onChanged` 로 알릴 뿐 목록을 스스로 바꾸지 않습니다. 플레이그라운드의 미리보기는 두 콜백에서 목록을 바꿔 다시 넘깁니다.

`붙여넣기 나누기` 를 켜고 `서울, 부산; 제주` 처럼 쉼표 · 세미콜론 · 줄바꿈 · 탭으로 나뉜 글을 붙여 넣으면 칩 여러 개가 한 번에 생깁니다. `최대 3개` 를 켜고 칩을 하나 더 넣으면 입력 칸이 사라집니다.

## 구조

프레임 하나 안에 칩들과 입력 칸이 한 줄로 이어지고, 줄이 모자라면 다음 줄로 넘어갑니다.

<Anatomy demo="chip-input/anatomy">
<AnatomyItem select="[role=group]" side="left" name="Container">

테두리 · 면 · 모서리. 칩과 입력 칸을 담고, 포커스 링도 이 프레임 둘레에 그립니다.

</AnatomyItem>
<AnatomyItem select=".co-chip-body" side="top" name="chip">

입력한 값 하나. Chip 컴포넌트를 `sm` 크기 · `filled` · `low` 로 그립니다.

</AnatomyItem>
<AnatomyItem select=".co-chip-body + .co-chip-body button" side="top" name="remove">

그 칩을 지웁니다. 비활성일 때는 빠집니다.

</AnatomyItem>
<AnatomyItem select="input" side="right" name="input">

글을 쓰는 칸. Enter 를 누르면 칩 추가를 요청합니다. 비어 있으면 안내 문구(`placeholder`)를 보여 줍니다.

</AnatomyItem>
</Anatomy>

| 부분 | 기본값 |
| --- | --- |
| 프레임 | 면 `surface`, 테두리 `outlineVariant` 1px, 모서리 12. 안쪽 여백은 위 · 아래 6, 시작 10, 끝 14 이고 시작 · 끝은 읽기 방향을 따릅니다. 최소 높이는 컨트롤 사다리의 `md` 행(40)입니다. 칩이 한 줄 들어가면 칩 28 에 위 · 아래 여백 6 과 테두리 1 이 더해져 42 가 되어, 옆의 `md` TextField(40)보다 2 높습니다. |
| 칩 | Chip 의 `sm` 행(높이 28, 모서리 6, `labelSmall` 글자)을 `filled` · `low` 로 그립니다 — 면 `surfaceContainerHigh`, 글자 `onSurfaceVariant`, 따로 보이는 테두리는 없습니다. 칩끼리, 줄끼리 6 떨어집니다. |
| 지우기 버튼 | 칩 끝의 16×16 `ghost` 버튼에 12 크기 `x` 아이콘. |
| 입력 칸 | 테두리 · 면이 없는 `plain` TextField 입니다. 칩 간격(6)에 입력 칸 앞 여백(4)이 더해져 마지막 칩과 10 떨어져 시작하고, 글자는 `bodyMedium` · `onSurface` 입니다. |

<Note>

칩은 선택 상태를 갖지 않습니다. 그래서 칩 모양(`filled` · `low` · `sm`)은 고정이고, ChipInput 에는 칩의 variant · 크기를 고르는 속성이 없습니다. 칩의 색 · 모서리 · 지우기 버튼은 `chipInputStyle` 의 `chipStyle` 로 바꿉니다.

</Note>

<a id="동작-스펙-behavior"></a>

## 상태

<Preview demo="chip-input/states" />

<Note>

Hover 칸은 테두리를 hover 색(`outline`)으로 고정해 그렸고, Focus 는 이 그림에 없습니다 — 플레이그라운드에서 입력 칸을 눌러 확인하세요.

</Note>

| 상태 | 모양 |
| --- | --- |
| 기본 | 면 `surface` 에 `outlineVariant` 테두리. |
| 칩 있음 | 칩 뒤에 입력 칸이 이어집니다. 줄에 자리가 모자라면 입력 칸이 다음 줄로 갑니다(줄 바꿈을 보세요). |
| Hover | 포인터가 프레임(칩 · 입력 칸 위 포함)에 올라가면 테두리가 `outline` 으로 한 단계 진해집니다(`hoverBorderColor`). |
| Focus | 프레임 바깥에 `focusRing` 색 2px 링을 그리고, 프레임과 링 사이 2px 는 비워 둡니다. 테두리는 쉬는 색 그대로입니다. 마우스로 눌러 들어가도 링을 그립니다. |
| 한도 도달 | 칩 수가 `maxChips` 에 닿으면 입력 칸을 숨깁니다. 칩을 지우면 다시 나타납니다. |
| 비활성 | 면 `disabledContainer`, 테두리 `disabledOutline`. 칩은 지우기 버튼 없이 면 `surface` · `disabledOutline` 테두리 · `disabledContent` 글자로 그리고, 입력 칸은 입력을 받지 않습니다. 입력 칸의 글자와 안내 문구는 `disabledContent` 로 그립니다. 불투명도를 낮추는 방식이 아니라 비활성 전용 색으로 그립니다. |

상태가 겹치면 `비활성 > 포커스 > hover > 쉬는 상태` 순서로 하나만 그립니다. 포커스된 프레임은 링이 상태를 말하므로 hover 단계를 그리지 않고, 비활성 프레임에는 hover 단계가 없습니다. Flutter 에서 이 '포커스'는 입력 칸의 포커스입니다 — 지우기 버튼에 포커스가 있을 때는 링이 없고, 포인터가 올라가면 hover 단계를 그립니다. 웹은 안의 무엇이든 포커스를 가지면 링을 그리고 hover 단계를 그리지 않습니다.

<Note>

비활성 프레임의 면(`disabledContainer`)은 CoUI 라이트의 `surfaceContainer` 와 같은 값이라, 그 색으로 채운 면 위에서는 테두리로만 구분됩니다. `surface` 바탕 위에서는 면 색으로도 구분됩니다.

</Note>

## 칩 추가와 제거

| 동작 | 결과 |
| --- | --- |
| Enter | 입력한 글의 앞뒤 공백을 지우고, 비어 있지 않으면 `onSubmitted(text)` 를 부른 뒤 입력 칸을 비웁니다. 빈 글이면 아무것도 하지 않습니다. |
| 칩 추가 | `chips` 에 자동으로 더하지 않습니다. 부모가 `onSubmitted` 에서 새 목록을 만들어 넘겨야 칩이 보입니다. |
| 지우기 버튼 | 그 칩을 뺀 새 목록으로 `onChanged` 를 부릅니다. 넘겨받은 목록은 고치지 않습니다. |
| 같은 값 | 걸러 내지 않습니다. 이미 있는 글을 다시 입력해도 그대로 `onSubmitted` 로 옵니다 — 중복을 막을지는 부모가 정합니다. |
| `maxChips` | 한도에 닿으면 입력 칸을 숨겨 더 입력할 수 없게 합니다. 칩 수를 자르지는 않으므로, 부모가 `chips` 로 더 많이 넘기면 그대로 그립니다. |
| 한글 조합 중 Enter | 웹은 조합을 확정하는 Enter(`isComposing` 이거나 keyCode 229)에서 칩을 만들지 않습니다. Flutter 의 Enter 는 따로 키를 처리하지 않고 텍스트 필드의 제출을 따르며, 같은 확인 코드는 없습니다. |

`onChanged` 가 오는 때는 둘입니다 — 칩을 지웠을 때와, `pasteSplitter` 로 붙여 넣은 글을 칩으로 나눴을 때. 손으로 입력한 칩은 `onSubmitted` 로만 옵니다.

## 붙여넣기

`pasteSplitter` 를 주면 붙여 넣은 글이 칩이 됩니다. 기본값 `null` 이면 붙여넣기는 평소처럼 글을 입력 칸에 넣고 Enter 를 기다립니다.

<Split>

<Code language="dart" title="흔한 구분자로 나누기">
ChipInput(
  chips: tags,
  // 쉼표 · 세미콜론 · 줄바꿈 · 탭
  pasteSplitter: CoreChipInputContract.splitOnCommonSeparators,
  onChanged: setTags,
  onSubmitted: addTag,
)
</Code>

<Code language="dart" title="구분자를 정해서 나누기">
ChipInput(
  chips: tags,
  pasteSplitter: CoreChipInputContract.splitOn(RegExp(r'\s+')),
  onChanged: setTags,
  onSubmitted: addTag,
)
</Code>

</Split>

| 항목 | 동작 |
| --- | --- |
| 다듬기 | 나눈 값마다 앞뒤 공백을 지우고, 비거나 공백뿐인 값은 버립니다. |
| 한도 | `maxChips` 의 남은 자리만큼만 앞에서부터 받습니다. 남은 자리가 없거나 받을 값이 없으면 아무것도 부르지 않습니다. |
| 알림 | 늘어난 목록으로 `onChanged` 를 한 번 부릅니다. 값마다 `onSubmitted` 를 부르지 않으므로, 붙여넣기를 칩으로 받으려면 `onChanged` 가 있어야 합니다. |
| 구분자 없는 글 | 칩 하나가 됩니다. 입력 칸에 남지 않습니다. |
| 입력 칸 | 붙여 넣은 글을 입력 칸에 넣지 않습니다. 입력 칸에 이미 쓰던 글은 그대로 둡니다. |

나누기 · 다듬기 · 한도는 두 플랫폼이 같은 함수(`CoreChipInputContract.chipsAfterPaste`)를 거칩니다.

<Note>

Flutter 는 붙여넣기 단축키(`Ctrl` · `V`, `⌘` · `V`)만 칩으로 나눕니다. 메뉴의 붙여넣기처럼 단축키를 거치지 않는 붙여넣기는 글을 입력 칸에 그대로 넣습니다. 웹은 브라우저의 붙여넣기를 모두 칩으로 나눕니다. 알려진 제약을 보세요.

</Note>

## 줄 바꿈

<Preview demo="chip-input/wrap" />

칩이 프레임 폭을 넘으면 다음 줄로 이어지고, 각 줄 안에서 세로 가운데에 놓입니다. 칩 사이와 줄 사이는 같은 간격(`chipSpacing`, 기본 6)입니다. 줄이 늘어도 모서리(12)는 그대로입니다.

입력 칸은 글 폭으로 정해지지 않고 **자기 줄의 남는 폭을 채웁니다**(두 플랫폼 같습니다). 현재 줄에 80(입력 칸의 여백 포함, `CoreChipInputContract.defaultInputMinWidth`)이 남아 있으면 칩과 같은 줄에 놓이고, 모자라면 다음 줄을 열어 그 줄 전체를 씁니다. 줄을 정할 때 입력한 글을 읽지 않으므로, 긴 글을 입력해도 입력 칸이 다른 줄로 옮겨 가지 않고 칸 안에서 스크롤됩니다.

칩 하나가 줄보다 길면 칩 글자가 한 줄로 잘리고 말줄임표가 붙습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

태그 · 키워드 · 받는 사람처럼 사용자가 자유롭게 지어 넣는 값을 여러 개 받을 때 씁니다. 넣은 값이 칩으로 보이고 하나씩 지울 수 있습니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 자유 글을 새로 만들지 않고 정해진 항목에서 하나 또는 여럿을 고를 때 | [ChipGroup](/components/chip-group) |
| 글 하나를 입력하며 추천 목록에서 고를 때 | [Autocomplete](/components/autocomplete) |
| 값 하나만 입력받을 때 | [TextField](/components/text-field) |
| 정해진 선택지에서 하나를 고를 때 | [Select](/components/select) |

<a id="do"></a>
<a id="dont"></a>

### 칩에 넣을 값

<Cards columns="2">
<Card demo="chip-input/do-short-tags" tone="do" eyebrow="이렇게 하세요">

칩 하나에는 낱말 하나를 넣습니다. 한눈에 읽히고, 지울 칩을 고르기 쉽습니다.

</Card>
<Card demo="chip-input/dont-sentence-tags" tone="dont" eyebrow="이렇게 하지 마세요">

문장을 칩으로 만들면 칩이 줄을 다 차지하고 글이 잘립니다. 긴 글은 TextArea 로 받습니다.

</Card>
</Cards>

### 콜백 둘을 함께 연결

`onSubmitted` 는 Enter 로 확정한 글만 넘길 뿐 `chips` 에 더하지 않습니다. 새 칩을 보이려면 `onSubmitted` 에서 목록에 더하고, 지우기 · 붙여넣기를 받으려면 `onChanged` 에서 목록을 바꿉니다.

<Split>

<Code language="dart" title="이렇게 하세요">
ChipInput(
  chips: tags,
  onChanged: (chips) => setState(() => tags = chips),
  onSubmitted: (text) => setState(() => tags = [...tags, text]),
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// onChanged 만 연결하면 Enter 로 입력한 칩이 생기지 않습니다.
ChipInput(
  chips: tags,
  onChanged: (chips) => setState(() => tags = chips),
)
</Code>

</Split>

<a id="조합-예제"></a>

### 라벨과 설명

ChipInput 에는 라벨 · 설명 · 오류 문구가 없습니다. 필요하면 컴포넌트를 늘리지 않고 [FormField](/components/form-field) 로 감쌉니다.

```dart
FormField(
  label: '태그',
  description: 'Enter 로 태그를 추가하세요.',
  child: ChipInput(
    chips: tags,
    placeholder: '태그를 입력해 주세요',
    onChanged: (chips) => setState(() => tags = chips),
    onSubmitted: (text) => setState(() => tags = [...tags, text]),
  ),
)
```

FormField 로 감싸면 라벨이 그 묶음의 이름이 되고, 설명 · 오류 문구가 그 묶음의 설명으로 이어집니다(웹 `aria-labelledby` · `aria-describedby`, Flutter `Semantics` 의 `label` · `hint`).

<Note>

ChipInput 에는 오류 상태가 없습니다. FormField 가 오류 문구를 보이면 프레임 테두리는 그대로이고, 안쪽 입력 칸에만 `error` 색 1px 테두리와 `surface` 면이 그려집니다 — 입력 칸이 FormField 의 오류를 따로 받기 때문입니다. `FormField(enabled: false)` 도 입력 칸만 막고, 칩 · 지우기 버튼 · 프레임은 활성으로 남습니다. 비활성으로 보이려면 ChipInput 에도 `enabled: false` 를 줍니다. 알려진 제약을 보세요.

</Note>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

내용과 동작은 위젯 파라미터(`chips` · `placeholder` · `enabled` · `maxChips` · `onChanged` · `onSubmitted` · `pasteSplitter`)로 넘기고, 색 · 크기 · 간격처럼 보이는 값은 `chipInputStyle`(`CoreChipInputStyle`) 하나로 덮어씁니다. ChipInput 에는 variant · size 가 없습니다.

### 안쪽 부품의 스타일

| 필드 | 받는 부품 | 정하지 않으면 |
| --- | --- | --- |
| `chipStyle` | 각 칩(`CoreChipStyle`) | `CoreChipInputStyle.defaultChipStyle`(12 크기 `x` 아이콘, 16×16 지우기 버튼) 위에 얹혀 각 Chip 에 그대로 넘어가고, 나머지는 Chip 의 `sm` 행이 채웁니다. |
| `inputTextStyle` | 입력 칸의 글자(`CoreTextStyle`) | `bodyMedium` · `onSurface`. 글자 역할과 색을 함께 적습니다. |
| `focusOutlineStyle` | 프레임의 포커스 링(`CoreFocusOutlineStyle`) | 포커스 링의 기본값(`focusRing` 색, 2px, 간격 2px). 모서리는 프레임 모서리를 따릅니다. |

<Note>

Flutter 는 지금 `inputTextStyle` 을 입력 칸에 넘기지 않습니다. 웹은 입력 칸의 글자에 반영합니다. 알려진 제약을 보세요.

</Note>

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
CoreChipInputStyle.default…          // 디자인 시스템 기본값
  → CoreComponentTheme.chipInput.style // 앱 전체
  → chipInputStyle                    // ChipInput 하나
```

### 사용 예

<Split>

<Code language="dart" title="ChipInput 하나만 바꾸기">
ChipInput(
  chips: tags,
  onChanged: setTags,
  onSubmitted: addTag,
  chipInputStyle: CoreChipInputStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    chipSpacing: CoreSpace.space4,
    chipStyle: CoreChipStyle(
      filledUnselectedBackgroundColor: CoreColor.token(CoreColors.primaryContainer),
      lowUnselectedForegroundColor: CoreColor.token(CoreColors.onPrimaryContainer),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    chipInput: CoreChipInputTheme(
      style: CoreChipInputStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다. `CoreChipInputTheme` 은 `style` 하나만 가집니다.

칩은 `filled` · `low` 로 그리므로, 칩의 면은 `filledUnselectedBackgroundColor`(테두리가 면을 따라옵니다), 글자와 지우기 아이콘은 `lowUnselectedForegroundColor` 로 바꿉니다 — 비활성 칩은 비활성 색으로 남습니다. `backgroundColor` · `foregroundColor` 는 모든 상태를 이기므로, 그것으로 바꾸면 비활성 칩도 그 색으로 남고, 칩 둘레에는 바뀌지 않은 회색(`surfaceContainerHigh`) 테두리가 보입니다.

### 기본값이 있는 곳

ChipInput 의 기본값은 전부 `coui_core` 의 `CoreChipInputStyle` · `CoreChipInputContract` 에 있고, Flutter와 Web이 같은 값을 읽습니다.

| 이름 | 값 | 설명 |
| --- | --- | --- |
| `CoreChipInputStyle.defaultBackgroundColor` | `surface` | 프레임 면 |
| `CoreChipInputStyle.defaultBorderColor` | `outlineVariant` | 쉬는 테두리 |
| `CoreChipInputStyle.defaultHoverBorderColor` | `outline` | hover 테두리 |
| `CoreChipInputStyle.defaultDisabledBackgroundColor` | `disabledContainer` | 비활성 면 |
| `CoreChipInputStyle.defaultDisabledBorderColor` | `disabledOutline` | 비활성 테두리 |
| `CoreChipInputStyle.defaultBorderWidth` | `CoreStrokeWidth.stroke1` (1px) | 테두리 굵기 |
| `CoreChipInputStyle.defaultBorderRadius` | `CoreRadius.radius12` | 모서리. 줄이 늘어도 그대로입니다. |
| `CoreChipInputStyle.defaultMinHeight` | `CoreControlSize.heightMd` (40) | 최소 높이 — 옆의 `md` TextField 와 같은 행. 칩이 들어가면 칩 28 · 여백 · 테두리로 42 가 됩니다. |
| `CoreChipInputStyle.defaultPadding` | 시작 10 · 위 6 · 끝 14 · 아래 6 | 안쪽 여백. 시작 · 끝은 읽기 방향을 따릅니다. |
| `CoreChipInputStyle.defaultInputPadding` | 시작 4 | 입력 칸 앞 여백 |
| `CoreChipInputStyle.defaultChipSpacing` | `CoreSpace.space6` | 칩 사이 · 줄 사이 간격 |
| `CoreChipInputStyle.defaultInputTextStyle` | `bodyMedium` · `onSurface` | 입력 글자 |
| `CoreChipInputStyle.defaultChipStyle` | 12 크기 `x` 아이콘 · 16×16 지우기 버튼 | 칩 스타일의 바탕 |
| `CoreChipInputStyle.chipVariant` · `chipEmphasis` · `chipSize` | `filled` · `low` · `sm` | 칩 모양 — 고정 |
| `CoreChipInputStyle.fieldVariant` | `plain` | 입력 칸 모양 — 고정 |
| `CoreChipInputContract.defaultInputMinWidth` | `CoreSize.size80` | 입력 칸이 칩과 한 줄에 놓이는 데 필요한 폭 |

<Note>

`CoreChipInputStyle.defaultPlaceholderColor`(`placeholder`)는 선언돼 있지만 지금 두 플랫폼 모두 읽지 않습니다. 안내 문구의 색은 안쪽 TextField 가 정합니다.

</Note>

### 밀도와 서페이스 스타일

| 축 | 동작 |
| --- | --- |
| 밀도 | 기본 최소 높이는 컨트롤 사다리의 `md` 행이라 앱의 밀도(`compact` · `spacious`)에서 옆의 TextField 와 함께 한 칸 움직입니다. 안쪽 여백 · 칩 간격도 함께 움직입니다. 직접 적은 `minHeight` 는 그대로입니다. 프레임 모서리(기본 12)는 반경 단계를 따라 한 칸 움직이고(`compact` 10 · `spacious` 14), 칩 모서리(6)는 `spacious` 에서 8 이 됩니다(`compact` 에서는 그대로). 칩 높이(28)는 움직이지 않습니다. |
| 서페이스 스타일 | 프레임 면은 내용 층의 재질을 받습니다 — 유리 류 스타일에서는 반투명해지고 뒤를 흐립니다. 그림자를 따로 정하지 않은 프레임이라, 스타일이 주는 그림자도 받습니다. |

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `ChipInput` 에 `withStyle` 을 이어 `chipInputStyle` 을 덧붙일 수 있습니다. 생성자의 `chipInputStyle` 과 같게 동작하고, 나중에 이은 `withStyle` 이 같은 필드에서 이깁니다. `.radius16` 처럼 Core 토큰 상수와 이름이 같은 getter 도 있습니다 — `withStyle` 을 한 번 더 줄인 것으로, 이름이 곧 값이라(`radius16` 은 `CoreRadius.radius16`) 어느 컴포넌트에서 써도 뜻이 같습니다.

<Preview component="chip-input" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ChipInputChainExample extends StatefulWidget {
  const ChipInputChainExample({super.key});

  @override
  State<ChipInputChainExample> createState() => _ChipInputChainExampleState();
}

class _ChipInputChainExampleState extends State<ChipInputChainExample> {
  List<String> _chips = const <String>['Flutter', 'Dart'];

  void handleChanged(List<String> chips) {
    setState(() {
      _chips = chips;
    });
  }

  void handleSubmitted(String text) {
    setState(() {
      _chips = [..._chips, text];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        ChipInput(
          chips: _chips,
          placeholder: '태그를 입력해 주세요',
          onChanged: handleChanged,
          onSubmitted: handleSubmitted,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        ChipInput(
          chips: _chips,
          placeholder: '태그를 입력해 주세요',
          onChanged: handleChanged,
          onSubmitted: handleSubmitted,
        ).withStyle(
          const CoreChipInputStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
            chipSpacing: CoreSpace.space8,
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
class ChipInputChainExample extends StatefulComponent {
  const ChipInputChainExample({super.key});

  @override
  State<ChipInputChainExample> createState() => _ChipInputChainExampleState();
}

class _ChipInputChainExampleState extends State<ChipInputChainExample> {
  List<String> _chips = const <String>['Flutter', 'Dart'];

  void handleChanged(List<String> chips) {
    setState(() {
      _chips = chips;
    });
  }

  void handleSubmitted(String text) {
    setState(() {
      _chips = [..._chips, text];
    });
  }

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        ChipInput(
          chips: _chips,
          placeholder: '태그를 입력해 주세요',
          onChanged: handleChanged,
          onSubmitted: handleSubmitted,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        ChipInput(
          chips: _chips,
          placeholder: '태그를 입력해 주세요',
          onChanged: handleChanged,
          onSubmitted: handleSubmitted,
        ).withStyle(
          const CoreChipInputStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
            chipSpacing: CoreSpace.space8,
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

<Note>

색 getter(`.primary` 등)는 프레임 면(`backgroundColor`)만 칠합니다. 입력 글자와 칩의 색은 그대로라, 진한 면에서는 글자 대비가 떨어집니다. 진한 면을 쓰려면 `withStyle` 로 `inputTextStyle` · `chipStyle` 의 색을 함께 정합니다(Flutter 의 입력 글자는 알려진 제약을 보세요).

</Note>

<a id="접근성-accessibility"></a>

## 접근성

프레임은 칩들과 입력 칸을 하나로 묶어 이름을 붙이고, 지우기 버튼마다 어떤 칩을 지우는지 이름에 적습니다. 이름은 렌더할 때 지금 로케일에서 읽습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 프레임을 시맨틱 노드 하나로 묶고 이름 `칩 입력`(영어 `Chip input`)을 붙입니다. 따로 붙는 역할은 없습니다. 지우기 버튼은 `Semantics(button: true)` 와 이름을 가집니다. |
| Jaspr Web | 프레임 `<div>` 에 `role="group"` 과 `aria-label`(`칩 입력` · `Chip input`)이 붙습니다. 입력 칸은 네이티브 `<input>`, 지우기 버튼은 `<button>` 입니다. |

지우기 버튼의 이름은 칩 글자를 넣은 문구입니다 — 한국어 `{칩} 제거`, 영어 `Remove {chip}`.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` | 칩의 지우기 버튼을 앞에서부터 차례로 거친 뒤 입력 칸에 닿습니다. |
| `Shift` · `Tab` | 거꾸로 이동합니다. |
| `Enter` (입력 칸) | 칩 추가를 요청합니다(`onSubmitted`). |
| `Enter` · `Space` (지우기 버튼) | 그 칩을 지웁니다(`onChanged`). |
| 붙여넣기 단축키 | `pasteSplitter` 가 있으면 붙여 넣은 글을 칩으로 나눕니다. |
| `Backspace` 로 마지막 칩 지우기 | 없음 |
| `←` · `→` 로 칩 사이 이동 | 없음 |

칩 사이를 오가는 조작이 없어, 가운데 칩을 지우려면 `Tab` 으로 그 지우기 버튼까지 이동해야 합니다.

### 스크린 리더

지우기 버튼마다 어떤 칩을 지우는지 읽고, 프레임은 묶음의 이름(`칩 입력`)을 가집니다. 입력 칸에는 이름을 붙이는 파라미터가 없습니다 — 무엇을 입력하는 칸인지 알려야 하면 FormField 로 감싸 라벨을 붙입니다.

**칩이 더해지거나 지워진 사실을 알리는 라이브 영역은 두 플랫폼 모두 없습니다** — 조작한 결과가 통보되지 않습니다.

### 포커스 관리

- **진입** — 마운트될 때 포커스를 옮기지 않습니다. Flutter 는 프레임 어디를 눌러도 입력 칸으로 포커스를 넘깁니다. 웹은 입력 칸을 직접 눌러야 합니다.
- **Enter 뒤** — 칩을 요청한 뒤에도 포커스는 입력 칸에 있습니다. Flutter 는 `onSubmitted` 를 부른 뒤 입력 칸에 포커스를 다시 줍니다.
- **칩 제거** — 칩에는 고유 키가 없어 화면의 칩이 자리 순서로 이어집니다. 그래서 가운데 칩을 지우면 그 자리에 다음 칩이 들어오고, 포커스는 그 자리의 지우기 버튼 — 이제 다음 칩의 것 — 에 남습니다(버튼 이름도 그 칩으로 바뀝니다). 목록의 마지막 칩을 지우면 그 버튼이 사라져 포커스를 잃습니다. 포커스를 일부러 옮기는 동작은 없습니다.
- **가두기** — 없습니다. 포커스는 프레임 밖으로 그대로 나갑니다.
- **포커스 링** — Flutter 는 입력 칸이 포커스를 가질 때만 프레임에 링을 그립니다. 웹은 `:focus-within` 이라 지우기 버튼에 포커스가 있을 때도 프레임에 링을 그립니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 칩이 더해지거나 지워진 것을 보조 기술에 알리지 않습니다. |
| 공통 | 마지막 칩을 지우면 포커스를 잃습니다. 다른 칩을 지우면 포커스가 그 자리에 들어온 다음 칩의 지우기 버튼에 남아, `Enter` 를 다시 누르면 그 칩도 지웁니다. |
| 공통 | 오류 상태가 없습니다. FormField 의 오류 문구가 보이면 프레임은 그대로이고, 안쪽 입력 칸에만 `error` 색 1px 테두리와 `surface` 면이 그려집니다. |
| 공통 | `FormField(enabled: false)` 는 안쪽 입력 칸만 막습니다. 칩 · 지우기 버튼 · 프레임은 활성으로 남으므로 ChipInput 에도 `enabled: false` 를 줍니다. |
| Jaspr Web | 지우기 버튼은 16×16 으로 그리지만, 포인터는 버튼 가운데에서 24×24 범위까지 받습니다. |
| Flutter | 지우기 버튼은 16×16 으로 그리고, 포인터를 받는 범위는 라벨 쪽으로만 24 까지 넓어집니다 — 버튼이 칩 내용 줄의 끝에 있어, 칩 끝 쪽과 위아래로는 그 줄의 경계에서 멈춥니다. 그리는 크기를 키우려면 두 플랫폼 모두 `chipStyle` 의 `closeButtonStyle` 을 바꿉니다. |
| Flutter | `inputTextStyle` 이 입력 칸의 글자에 닿지 않습니다. 계산은 하지만 안쪽 TextField 에 넘기지 않아, 입력 글자는 TextField 의 기본 글자(`bodyMedium` · `onSurface`)로 그려집니다. |
| Flutter | 붙여넣기 단축키만 칩으로 나눕니다. 메뉴의 붙여넣기처럼 단축키를 거치지 않는 붙여넣기는 글을 입력 칸에 그대로 넣습니다. |
| Flutter | 지우기 버튼에 포커스가 있을 때 프레임에 링을 그리지 않고, 포인터가 올라가면 hover 테두리를 그립니다(웹은 링을 그리고 hover 테두리를 그리지 않습니다). |
| Flutter | 입력 칸이 칩과 한 줄에 놓이는 폭(80)에는 `theme.scaling` 을 곱하지 않습니다. 배율을 키운 앱에서는 칩과 여백이 커져도 이 폭은 80 그대로입니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API 는 같지만, 렌더링과 입력 처리는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 입력 칸 | `EditableText` | 네이티브 `<input>` |
| 줄 배치 | 전용 레이아웃(`ChipInputWrap`)이 남는 폭을 입력 칸에 줍니다. | `flex-wrap` 과 `flex: 1` · `min-width` 입력 칸 |
| 포커스 링 | `FocusOutline` — 입력 칸이 포커스를 가질 때 | `:focus-within` `outline` — 안의 무엇이든 포커스를 가질 때 |
| 호버 테두리 | `MouseRegion` 이 호버를 감지하고 미리 계산해 둔 `hoverBorderColor` 를 고릅니다. | 토큰이면 `hover:border-*` 클래스(`focus-within:hover:` 로 쉬는 테두리를 되살려 포커스가 우선), 토큰이 아닌 색은 `:not(:focus-within):hover` 범위 지정 규칙 |
| 프레임 누르기 | 입력 칸에 포커스를 넘깁니다. | 아무것도 하지 않습니다. |
| 커서 | 프레임 위에서 글자 커서, 비활성이면 기본 화살표 | 입력 칸 위에서 글자 커서, 비활성 프레임은 `not-allowed` |
| 입력 버퍼 | 내부 `TextEditingController` | 안쪽 `<input>` 의 값 |
| Enter | 텍스트 필드의 제출 | `keydown` 에서 직접 처리하고 기본 동작을 막아, 둘러싼 `<form>` 이 제출되지 않습니다. |
| 한글 조합 중 Enter | 텍스트 입력 프레임워크를 따릅니다. | `isComposing` 이거나 keyCode 229 이면 칩을 만들지 않습니다. |
| 붙여넣기 나누기 | `PasteTextIntent`(붙여넣기 단축키)를 가로챕니다. | DOM `paste` 이벤트 — 모든 붙여넣기 |
| `inputTextStyle` | 입력 칸에 닿지 않습니다. | 입력 칸 글자에 반영합니다. |
| 묶음의 이름 | `Semantics(container: true, label:)` | `role="group"` · `aria-label` |
| 크기 배율 | 스타일을 계산할 때 `theme.scaling` 을 곱합니다(입력 칸이 줄에 놓이는 폭 80 은 곱하지 않습니다). | `rem` 이 브라우저 글자 배율을 따릅니다. |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` 가 프레임 `<div>` 에 닿습니다. `attributes` 의 `role` · `aria-label` 은 ChipInput 이 정한 값이 이깁니다. |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다.

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `chips` | `List<String>` | `const []` | 지금 칩 목록. 부모가 들고 넘깁니다. |
| `placeholder` | `String?` | `null` | 입력 칸이 비었을 때의 안내 문구 |

### 상태와 형태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `enabled` | `bool` | `true` | false 면 입력과 지우기를 막습니다. |
| `maxChips` | `int?` | `null` | 최대 칩 수. 닿으면 입력 칸을 숨깁니다. `null` 은 무제한 |
| `chipInputStyle` | `CoreChipInputStyle?` | `null` | 프레임과 칩 · 입력 칸의 보이는 값 덮어쓰기 |

### 콜백

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `onChanged` | `ValueChanged<List<String>>?` (웹 `CoreValueChanged<List<String>>?`) | `null` | 칩을 지웠을 때, 붙여 넣은 글을 칩으로 나눴을 때 새 목록 |
| `onSubmitted` | `ValueChanged<String>?` (웹 `CoreValueChanged<String>?`) | `null` | Enter 로 확정한 글(앞뒤 공백을 지운 것). 빈 글이면 부르지 않습니다. |
| `pasteSplitter` | `List<String> Function(String pasted)?` | `null` | 붙여 넣은 글을 칩 값으로 나눕니다. `null` 이면 붙여넣기는 평소대로 입력 칸에 들어갑니다. |

### 붙여넣기를 나누는 도구

| 이름 | 설명 |
| --- | --- |
| `CoreChipInputContract.splitOnCommonSeparators` | 쉼표 · 세미콜론 · 줄바꿈 · 탭으로 나눕니다. `pasteSplitter` 에 그대로 넘깁니다. |
| `CoreChipInputContract.splitOn(Pattern separator)` | 정한 구분자로 나누는 함수를 만듭니다. |
| `CoreChipInputContract.chipsAfterPaste(...)` | 두 플랫폼이 붙여넣기에 쓰는 계산 — 나누고, 다듬고, `maxChips` 로 자릅니다. 붙여넣기가 더한 것이 없으면 받은 목록을 그대로 돌려줍니다. |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreChipInputStyle patch)` | `chipInputStyle` 에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다. |
| `.radius0` … `.radius9999` | `borderRadius` 를 그 `CoreRadius` 단계로 둡니다. |
| `.primary` · `.secondary` · `.tertiary` · `.surface` · `.surfaceContainer` · `.error` · `.success` · `.warning` · `.info` · `.outline` · `.transparent` | `backgroundColor` 를 그 색으로 둡니다. |

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 프레임 `<div>` 의 id |
| `classes` | `String?` | `null` | 프레임에 더하는 클래스 |
| `css` | `Styles?` | `null` | 프레임에 더하는 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 프레임에 더하는 속성. `role` · `aria-label` 은 ChipInput 이 정한 값(`group` · `칩 입력`)이 이깁니다. |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 프레임에 거는 이벤트 처리기 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreChipInputStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Container background fill colour override. |
| `borderColor` | `CoreColor?` | Container border stroke colour override. |
| `hoverBorderColor` | `CoreColor?` | Container border stroke colour override while the pointer is over the frame. `null` → [defaultHoverBorderColor]. Never applied while the frame holds focus (the focus ring owns that state) or while it is disabled. |
| `disabledBackgroundColor` | `CoreColor?` | Container fill override while the frame is disabled. `null` → [defaultDisabledBackgroundColor]. |
| `disabledBorderColor` | `CoreColor?` | Container border stroke colour override while the frame is disabled. `null` → [defaultDisabledBorderColor]. |
| `borderWidth` | `double?` | Container border stroke width override (logical px). |
| `borderRadius` | `CoreBorderRadius?` | Container border radius override. |
| `minHeight` | `double?` | Container minimum height override (logical px). |
| `padding` | `CoreEdgeInsets?` | Container padding override. |
| `inputPadding` | `CoreEdgeInsets?` | Inset around the inline entry field override. `null` → [defaultInputPadding]. |
| `chipSpacing` | `double?` | Gap between chip badges override (logical px). |
| `inputTextStyle` | `CoreTextStyle?` | Inline text-entry (`<input>` / `EditableText`) text style override. The typography role and the text colour ([CoreTextStyle.color]) both go in this one style. |
| `chipStyle` | `CoreChipStyle?` | Style of the chips in the field (a [CoreChipStyle]). Laid over [defaultChipStyle] and passed to each `Chip`, which fills in every field neither of them states. |
| `focusOutlineStyle` | `CoreFocusOutlineStyle?` | Focus ring the **frame** draws while the field (or anything inside it) has focus. Left `null`, every ring field falls back to `FocusOutline`'s own defaults. Not the `focusOutlineStyle:` inside [chromelessFieldStyle], which belongs to the inner `TextField` and *suppresses* its ring — this slot is the visible one. |

<!-- STYLE_TABLE:END -->

<Note>

표의 두 설명은 Flutter 에서 지금 동작과 다릅니다. `inputTextStyle` 은 Flutter 의 입력 칸에 닿지 않습니다 — 입력 글자는 안쪽 TextField 의 기본 글자(`bodyMedium` · `onSurface`)로 그립니다. `focusOutlineStyle` 의 링은 Flutter 에서 입력 칸이 포커스를 가질 때만 그리고, 지우기 버튼에 포커스가 있을 때는 그리지 않습니다. 웹은 표의 설명대로 동작합니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="chip-input/related-chip" title="Chip">

칩 하나를 표시합니다. 고를 수 있거나 지울 수 있는 칩도 만듭니다.

</Card>
<Card demo="chip-input/related-text-field" title="TextField">

한 줄 글 하나를 입력받습니다.

</Card>
<Card demo="chip-input/related-autocomplete" title="Autocomplete">

입력하며 추천 목록에서 값을 고릅니다.

</Card>
<Card demo="chip-input/related-form-field" title="FormField">

라벨 · 설명 · 오류 문구를 붙입니다. ChipInput 은 라벨 슬롯을 갖지 않습니다.

</Card>
</Cards>
