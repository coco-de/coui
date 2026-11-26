---
title: MultiAnswerCard
description: 선택 상태를 표시하는 카드형 답안 선택 컴포넌트
category: form
platforms: [flutter, web]
related: [multiple-choice, checkbox, card]
tags: [interactive, form-control, selection]
template: v2
source: form/multi_answer_card
---

# MultiAnswerCard

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

선택 · 비활성 상태와 답의 길이를 바꿔 보며 답안 카드를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="multi-answer-card" />

카드는 선택을 스스로 바꾸지 않습니다. 활성 카드를 누르면 `onChanged` 에 이 카드의 `value` 를 넘길 뿐입니다. 고른 답의 모음과 카드마다의 `selected` 는 호출자가 정하고, 새 `selected` 를 넘겨야 선택 표시가 바뀝니다. 플레이그라운드에서는 컨트롤로 선택을 바꿉니다. `value` 는 답을 구분하는 값이고 화면에는 그리지 않습니다.

## 구조

카드는 답 내용과 끝의 체크박스를 가로로 놓은 둥근 상자입니다. 카드 전체가 누르는 영역입니다.

<Anatomy demo="multi-answer-card/anatomy">
<AnatomyItem part="container" name="Container">

테두리를 두른 카드이자 누르는 영역입니다. 상태에 따라 바탕과 테두리 색이 바뀝니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="child">

답 내용입니다. 글 말고 다른 위젯도 넣을 수 있고, 체크박스를 뺀 남는 폭을 차지합니다.

</AnatomyItem>
<AnatomyItem select=".co-checkbox-box" side="right" name="checkbox">

선택 상태를 보여 주는 `lg` 크기의 [Checkbox](/components/checkbox) 입니다. 마우스나 손가락으로 여기를 눌러도 카드를 누른 것이 됩니다.

</AnatomyItem>
</Anatomy>

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 상태

variant 와 크기 속성은 없습니다. `selected` 와 `enabled`, 그리고 hover 가 카드의 모양을 정합니다.

<Preview demo="multi-answer-card/states" />

<Note>

CoUI 기본 테마에서 비활성 카드의 바탕(`disabledContainer`)은 `surfaceContainer` 와 같은 색입니다. 그래서 `surfaceContainer` 로 채운 면(네이티브 문서 앱의 무대가 그렇습니다) 위에서는 비활성 카드의 바탕이 구분되지 않고 테두리만 남습니다. hover 한 카드의 바탕(`surfaceContainer`)도 같은 면과 같은 색입니다.

</Note>

### 색

| 상태 | 바탕 | 테두리 | 글자 | 체크박스 |
| --- | --- | --- | --- | --- |
| 기본 | `surface` | `outlineVariant` | `onSurface` · `bodyLarge` (15 Regular) | 빈 상자 |
| Hover | `surfaceContainer` | `outline` | 기본과 같음 | 빈 상자 |
| 고름 | `primaryContainer` | `primary` | `onSurface` · `labelXl` (15 Medium) | 체크 |
| 비활성 | `disabledContainer` | `disabledOutline` | `disabledContent` · 15 Regular | 비활성 빈 상자 |
| 고름 · 비활성 | `disabledContainer` | `disabledOutline` | `disabledContent` · 15 Regular | 비활성 체크 |

테두리 두께는 모든 상태에서 1 입니다. 그래서 기본값에서는 hover 한 카드와 비활성 카드의 높이가 기본 카드와 같습니다. 고른 카드의 Medium 글자도 줄 높이를 150% 로 유지하므로, 줄 수가 같으면 선택해도 카드 높이가 변하지 않습니다. 다만 글꼴에 따라 Medium 글자가 더 넓게 그려지면, 한 줄을 거의 채우는 답은 고를 때 줄이 늘 수 있습니다.

여러 상태가 겹치면 비활성, 고름, hover 순서로 앞선 것의 모양을 그립니다. 그래서 hover 는 고르지 않은 활성 카드에만 보입니다. 비활성 카드는 골랐든 아니든 바탕 · 테두리 · 글자가 같고, 고른 상태는 체크박스만 보여 줍니다.

글자 모양과 색은 카드가 `child` 에 내려 줍니다. `child` 의 글자에 색을 직접 주면 비활성 글자색이 닿지 않고, 크기나 굵기를 직접 주면 고른 카드의 Medium 이 닿지 않을 수 있습니다.

### 동작

| 항목 | 동작 |
| --- | --- |
| 누를 때 | `onChanged` 에 `value` 를 넘깁니다. `selected` 는 저절로 바뀌지 않습니다. |
| 활성 여부 | `enabled`(기본 `true`)가 정합니다. `onChanged` 가 있는지는 보지 않습니다. |
| 눌림 | 활성 카드를 누르는 동안 카드 전체가 0.97배로 줄어듭니다. 고른 카드도 같고, `Space` · `Enter` 로 눌러도 줄어듭니다. |
| 커서 | 활성 카드는 손가락 모양, 비활성 카드는 금지 모양입니다. |
| Focus | 키보드로 포커스했을 때 카드 바깥에 2 만큼 비운 2 두께의 링을 그립니다. 링의 모서리는 카드 모서리를 따르지 않습니다(알려진 제약). |
| 비활성 | 눌러도 `onChanged` 를 부르지 않습니다. hover 모양과 눌림이 없고 Tab 순서에서 빠집니다. 카드를 흐리게(opacity) 하지 않고 비활성 색으로 그립니다. |
| 전환 시간 | 카드의 바탕 · 테두리 색은 200ms(`transitionDuration`), 체크박스의 표시는 [Checkbox](/components/checkbox) 의 300ms, 눌림은 100ms 동안 바뀝니다. 동작 줄이기에서는 바로 바뀝니다. |

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

퀴즈나 설문처럼 답을 카드로 크게 보여 주고, 고른 답을 카드 색과 체크박스로 함께 강조할 때 씁니다. 여러 장을 나열하면 여러 답을 고르는 목록이 됩니다. 카드를 묶는 컴포넌트는 없어서, 고른 답의 모음은 호출자가 듭니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 카드 없이 체크 하나를 두거나 불확정 상태가 필요할 때 | [Checkbox](/components/checkbox) |
| 여러 선택지 중 하나만 Chip 줄에서 고를 때 | [MultipleChoice](/components/multiple-choice) |
| 라디오 표시로 하나를 고를 때 | [RadioGroup](/components/radio-group) |
| 바텀시트나 패널의 선택지 목록에 앞 아이콘과 설명을 둘 때 | [OptionItem](/components/option-item) |
| 고르는 상태 없이 내용을 묶을 때 | [Card](/components/card) |

<a id="do"></a>
<a id="dont"></a>

### 선택 상태와 비활성

<Cards columns="2">
<Card tone="do" eyebrow="이렇게 하세요" title="selected 는 호출자가 계산합니다">

```dart
MultiAnswerCard<String>(
  value: option.id,
  selected: picked.contains(option.id),
  onChanged: (id) => setState(() => toggle(id)),
  child: Text(option.label),
)
```

`value` 는 답을 구분하는 값일 뿐입니다. 카드는 다른 카드의 선택을 알지 못하므로, 고른 답의 모음(`picked`)에서 `selected` 를 계산해 넘깁니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요" title="콜백만 빼서 읽기 전용 카드를 만들지 않습니다">

```dart
// enabled 는 기본이 true 라서 눌림 · 포커스 · 손가락 커서가 그대로입니다.
// 고르지 않은 카드라면 hover 모양도 남습니다.
MultiAnswerCard<String>(
  value: 'exercise',
  selected: true,
  child: Text('운동을 꾸준히 해요'),
)
```

누를 수 있는 것처럼 보이지만 눌러도 선택은 바뀌지 않습니다. 읽기 전용 카드에는 `enabled: false` 를 줍니다.

</Card>
</Cards>

## 배치

### 카드의 크기

표의 값은 기본 밀도의 값입니다.

| 항목 | 기본값 |
| --- | --- |
| 폭 | 받은 폭을 채웁니다. 내용이 남는 폭을 차지하고 긴 글은 줄을 바꿉니다. |
| 높이 | 내용과 안쪽 여백이 정합니다. 최소 높이를 정하는 값은 없습니다. |
| 안쪽 여백 | 16 (`padding`) |
| 테두리 · 모서리 | 1 · 12 |
| 내용과 체크박스 사이 | 12 (`checkboxGapStyle`) |
| 체크박스 | `lg` (박스 18) |
| 글자 | `bodyLarge` 15, 고른 카드는 `labelXl` 15 Medium (줄 높이 150%) |

- 체크박스는 끝쪽(왼쪽에서 오른쪽으로 읽는 화면에서는 오른쪽)에 놓이고, 내용이 여러 줄이어도 세로 가운데에 놓입니다.
- 안쪽 여백 16 과 체크박스 앞의 간격 12 는 밀도(`CoreDensity`)를 따라 4px 격자에서 한 칸 움직입니다. `compact` 에서는 12 · 8, `spacious` 에서는 20 · 16 이고, 카드 모서리 12 는 10 · 14 가 됩니다. 테두리와 체크박스 크기는 그대로입니다.
- Flutter 에서는 폭이 정해지지 않은 자리(`Row` 의 직접 자식이나 가로 스크롤 안)에 그대로 놓으면 레이아웃 오류가 납니다. `Expanded` 나 `SizedBox` 로 폭을 줍니다.

### 여러 줄 내용

`child` 에는 제목과 보조 글처럼 여러 줄도 넣을 수 있습니다. 그림의 아랫줄은 색(`onSurfaceVariant`)을 직접 준 글이라, 비활성 카드에서도 그 색이 남습니다. Flutter 에서 `Column` 을 넣을 때는 `mainAxisSize: MainAxisSize.min` 을 줍니다. 그러지 않으면 높이 상한만 있는 자리(`Center` 안이나 `Column` 의 `Flexible` 안 같은 곳)에서 카드가 그 상한까지 늘어납니다.

<Preview demo="multi-answer-card/content" />

### 목록으로 놓기

카드 사이의 간격은 호출자가 둡니다. 아래는 8 간격으로 놓고, 고른 답을 모음(`picked`)으로 드는 모양입니다.

<Preview demo="multi-answer-card/list" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Column(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space8,
  children: [
    for (final answer in answers)
      MultiAnswerCard<String>(
        value: answer.id,
        selected: picked.contains(answer.id),
        onChanged: toggleAnswer,
        child: Text(answer.label),
      ),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(
  [
    for (final answer in answers)
      MultiAnswerCard<String>(
        value: answer.id,
        selected: picked.contains(answer.id),
        onChanged: toggleAnswer,
        child: Text(answer.label),
      ),
  ],
  classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
)
```

  </TabItem>
</Tabs>

## 테마와 스타일

variant 와 크기 속성은 없습니다. 색 · 테두리 · 모서리 · 여백 · 글자처럼 보이는 값은 `multiAnswerCardStyle`(`CoreMultiAnswerCardStyle`) 하나로 덮어씁니다.

<Split>

<Code language="dart" title="카드 하나의 고른 색 바꾸기">
MultiAnswerCard<String>(
  value: 'exercise',
  selected: true,
  onChanged: toggleAnswer,
  multiAnswerCardStyle: CoreMultiAnswerCardStyle(
    selectedBackgroundColor: CoreColor.token(CoreColors.successContainer),
    selectedBorderColor: CoreColor.token(CoreColors.success),
    checkboxStyle: CoreCheckboxStyle(
      boxActiveColor: CoreColor.token(CoreColors.success),
    ),
  ),
  child: Text('운동을 꾸준히 해요'),
)
</Code>

<Code language="dart" title="앱 전체: 포커스 링을 카드 모서리에 맞추기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    multiAnswerCard: CoreMultiAnswerCardTheme(
      style: CoreMultiAnswerCardStyle(
        clickableStyle: CoreClickableStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
        ),
      ),
    ),
  ),
)
</Code>

</Split>

서페이스 스타일(유리 · 점토 등)의 재질은 네 상태의 카드 상자에 모두 적용됩니다.

### 안쪽 부품과 상태별 글자

- **체크박스** — `checkboxStyle` 로 바꿉니다. 크기 속성은 없어 `lg` 이고, 박스 크기는 `checkboxStyle` 의 `boxSize` 로 바꿉니다. 앱의 Checkbox 테마(`CoreComponentTheme.checkbox`)도 이 체크박스에 닿고, 카드의 `checkboxStyle` 이 그 위에 얹힙니다. 테마에서 Checkbox 의 `minHeight` 를 키우면 카드 안의 체크박스도 그 높이가 되어 카드가 함께 높아집니다.
- **누름 · 포커스** — `clickableStyle` 은 카드의 기본값 `disabledOpacity: 1`(비활성 카드를 흐리게 하지 않음) 위에 얹어 `Clickable` 에 넘깁니다. `pressedScale: 1` 이면 누를 때 줄어들지 않습니다. `borderRadius` 는 카드가 아니라 포커스 링의 모서리를 정합니다.
- **글자** — `bodyTextStyle` 은 고르지 않은 활성 카드(hover 포함)에만 닿습니다. 고른 카드는 `selectedBodyTextStyle`, 비활성 카드는 `disabledBodyTextStyle` 로 따로 바꿉니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `MultiAnswerCard` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `multiAnswerCardStyle` 인자와 같게 동작합니다. `.radius16` 처럼 Core 토큰 이름과 같은 getter 는 `withStyle` 을 더 짧게 쓴 것입니다. 모서리 getter 는 카드의 `borderRadius` 를 바꾸고, 색 getter 는 `backgroundColor`, 곧 고르지 않고 hover 하지 않은 활성 카드의 바탕만 바꿉니다.

<Note>

아래 예제의 첫 카드(`.radius16.primary`)는 처음에 고른 상태라 `.primary` 바탕이 보이지 않고 `primaryContainer` 바탕으로 그려집니다. 눌러서 선택을 풀고 포인터를 카드 밖으로 옮기면 `primary` 바탕이 보입니다. 색 getter 는 글자색을 바꾸지 않으므로, CoUI 기본 테마에서는 그 바탕 위의 `onSurface` 글자가 라이트 · 다크 모두 거의 보이지 않습니다. 화면에서 바탕을 진한 색으로 바꿀 때는 `withStyle` 로 `backgroundColor` · `hoverColor` 와 `bodyTextStyle` 의 글자색을 함께 정합니다. `bodyTextStyle` 은 hover 한 카드에도 쓰입니다.

</Note>

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class MultiAnswerCardChainExample extends StatefulWidget {
  const MultiAnswerCardChainExample({super.key});

  @override
  State<MultiAnswerCardChainExample> createState() => _MultiAnswerCardChainExampleState();
}

class _MultiAnswerCardChainExampleState extends State<MultiAnswerCardChainExample> {
  final Set<String> _selected = {'a'};

  void _toggle(String value) {
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        _selected.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        MultiAnswerCard<String>(
          value: 'a',
          selected: _selected.contains('a'),
          onChanged: _toggle,
          child: const Text('운동을 꾸준히 해요'),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        MultiAnswerCard<String>(
          value: 'b',
          selected: _selected.contains('b'),
          onChanged: _toggle,
          child: const Text('아침을 챙겨 먹어요'),
        ).withStyle(
          const CoreMultiAnswerCardStyle(
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
class MultiAnswerCardChainExample extends StatefulComponent {
  const MultiAnswerCardChainExample({super.key});

  @override
  State<MultiAnswerCardChainExample> createState() => _MultiAnswerCardChainExampleState();
}

class _MultiAnswerCardChainExampleState extends State<MultiAnswerCardChainExample> {
  final Set<String> _selected = {'a'};

  void _toggle(String value) {
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        _selected.add(value);
      }
    });
  }

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        MultiAnswerCard<String>(
          value: 'a',
          selected: _selected.contains('a'),
          onChanged: _toggle,
          child: Text('운동을 꾸준히 해요'),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        MultiAnswerCard<String>(
          value: 'b',
          selected: _selected.contains('b'),
          onChanged: _toggle,
          child: Text('아침을 챙겨 먹어요'),
        ).withStyle(
          const CoreMultiAnswerCardStyle(
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
기본값 (CoreMultiAnswerCardStyle.default*)
  → CoreComponentTheme.multiAnswerCard.style   // 앱 전체
  → multiAnswerCardStyle                       // 인스턴스
```

뒤로 갈수록 우선합니다. 카드는 자기 값을 안의 체크박스에 `checkboxStyle` 로 넘기므로, 체크박스에서는 그 값이 이렇게 얹힙니다([Checkbox 의 순서](/components/checkbox#값이-정해지는-순서)).

```text
Checkbox 기본값 (lg 크기)
  → CoreComponentTheme.checkbox.style                  // 앱 전체의 Checkbox
  → 카드의 checkboxStyle (카드 테마 위에 multiAnswerCardStyle)
```

<a id="접근성-accessibility"></a>

## 접근성

카드는 버튼으로 알려집니다. 선택 상태는 Jaspr Web 만 `aria-pressed` 로 알리고, Flutter 는 알리지 않습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 카드를 감싼 `Clickable` 이 버튼과 활성 여부(`enabled`)를 알립니다. 선택 상태를 알리는 시맨틱은 없습니다. 안의 체크박스는 의미 트리에서 빠집니다(`ExcludeSemantics`). |
| Jaspr Web | 카드를 감싼 `<div>` 에 `role="button"` 과 `aria-pressed`(`true` · `false`)가 붙습니다. 비활성이면 `aria-disabled="true"` 가 붙고 `tabindex` 가 빠집니다. 안의 체크박스를 감싼 요소는 `aria-hidden="true"` 입니다. |

Jaspr Web 에서 `attributes` 에 넣은 값은 카드가 붙인 속성 뒤에 합쳐져 같은 이름을 덮습니다. `role` 이나 `tabindex` 를 바꿀 수 있지만, `aria-pressed` 는 없앨 수 없고 값만 바꿀 수 있습니다. 하나만 고르는 목록에는 `role` 을 덮어쓰기보다 [RadioGroup](/components/radio-group) 이나 [MultipleChoice](/components/multiple-choice) 를 씁니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Space` · `Enter` | 활성 카드의 `onChanged` 에 `value` 를 넘깁니다. 키를 뗄 때가 아니라 누를 때 부릅니다. |
| `Tab` | 다음 요소로 포커스를 옮깁니다. 활성 카드마다 Flutter 는 한 번, Jaspr Web 은 두 번 멈춥니다(카드, 그다음 안의 체크박스). |
| `Shift` · `Tab` | 이전 요소로 포커스를 옮깁니다. |

<Note>

비활성 카드는 Tab 순서에서 빠집니다. 화살표 · `Home` · `End` 는 처리하지 않고, 여러 장을 놓아도 한 정지점으로 묶지 않습니다.

</Note>

### 스크린 리더

- **이름** — 카드 안의 글자에서 옵니다. 이름만 정하는 속성은 없어서 `child` 에 글자가 없으면 이름이 빕니다. Jaspr Web 에서는 `attributes` 로 `aria-label` 을 줄 수 있습니다.
- **선택** — Jaspr Web 은 `aria-pressed` 로 알립니다. Flutter 는 알리지 않습니다(알려진 제약).
- **비활성** — Flutter 는 `Semantics(enabled: false)` 로, Jaspr Web 은 `aria-disabled="true"` 로 알립니다.
- **알림** — 선택이 바뀐 사실을 따로 알리는 라이브 리전은 없습니다.

### 포커스 관리

마운트될 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. 포커스 링은 키보드로 포커스했을 때만 카드 바깥에 나타납니다. Flutter 는 눌러도 포커스를 옮기지 않습니다. Jaspr Web 은 활성 카드를 마우스로 누르면 카드에 포커스가 가지만 링은 보이지 않습니다. Jaspr Web 의 두 번째 정지점(안의 체크박스)에 키보드로 닿으면 체크박스 둘레에 Checkbox 의 링이 보입니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | 활성 카드마다 Tab 정지점이 둘입니다. 안의 체크박스를 감싼 요소는 `aria-hidden` 이지만 `inert` 가 아니어서, `role="checkbox"` · `tabindex="0"` 인 체크박스에 포커스가 갑니다. 거기서 `Space` · `Enter` 를 눌러도 카드의 `onChanged` 는 불리지 않습니다. 보조 기술에서 숨긴 요소에 포커스가 가서 스크린 리더가 알맞게 읽지 못할 수 있습니다. |
| Flutter | 선택 상태가 스크린 리더에 닿지 않습니다. 선택은 색과 체크박스로만 보입니다. `Semantics(selected: picked.contains(id), child: MultiAnswerCard(...))` 처럼 카드에 넘긴 값으로 감싸 알립니다. |
| 공통 | 카드를 [FormField](/components/form-field) 안에 두면 안의 체크박스가 선택 여부(`bool?`)를 필드 값으로 알립니다. 카드의 `value` 는 알리지 않고, 한 필드에 카드가 여러 장이면 마지막에 알린 값만 남습니다. 카드를 FormField 의 입력으로 쓰지 않습니다. |
| 공통 | 포커스 링의 모서리가 카드 모서리를 따르지 않습니다. 링은 카드 모서리가 아니라 `Clickable` 의 기본 모서리 4 에서 계산해, 기본 밀도에서 링의 바깥 모서리가 16(카드 12 + 4)이 아닌 8 이 됩니다. `multiAnswerCardStyle` 의 `borderRadius` 를 바꿔도 링은 따라가지 않습니다. `clickableStyle` 의 `borderRadius` 를 카드와 같은 값으로 맞춥니다. |
| Flutter | `selectedBorderWidth` 를 `borderWidth` 와 다르게 주면, 고른 채 비활성인 카드의 크기가 다른 상태와 달라집니다. 비활성 카드는 `borderWidth` 로 그리면서 여백은 고른 카드의 것을 쓰기 때문입니다. |
| Flutter | `borderColor` · `hoverBorderColor` · `selectedBorderColor` · `disabledBorderColor` 를 완전히 투명한 색(`CoreColor.transparent` 처럼 알파 0)으로 주면 그 상태의 테두리 두께가 0 이 됩니다. 일부 상태만 투명하면, 기본 두께에서는 투명한 상태와 아닌 상태를 오갈 때 카드 높이가 2 달라지고 내용이 1 씩 밀립니다. 테두리를 감추려면 투명색 대신 그 상태의 바탕과 같은 색을 줍니다. |
| Jaspr Web | `selectedBorderWidth` 를 `borderWidth` 보다 얇게 주면 효과가 없습니다. 고른 카드도 `borderWidth` 로 그립니다. |
| Jaspr Web | `onClick` · `onChange` · `onInput` · `onKeyDown` · `onKeyUp` · `onMouseEnter` · `onMouseLeave` 는 받지만 불리지 않습니다. `onChange` · `onInput` 은 이벤트 값이 문자열일 때만 부르게 되어 있는데, 브라우저는 이벤트 객체를 넘깁니다. 나머지 다섯은 카드를 감싼 `Clickable` 이 같은 이벤트를 직접 쓰면서 덮습니다. 누름은 `onChanged` 로 받습니다. |
| Jaspr Web | `eventHandlers` 의 `click` · `mousedown` · `mouseup` · `mouseenter` · `mouseleave` · `focusout` · `keydown` · `keyup` 핸들러도 `Clickable` 에 덮여 불리지 않습니다. 카드 안에서 올라온 `change` · `input` 같은 그 밖의 이벤트는 받습니다. |
| Jaspr Web | 카드 안에 버튼이나 링크를 넣으면, 그것을 눌러도 카드의 `onChanged` 가 함께 불립니다. |
| 공통 | `Space` · `Enter` 를 누르고 있으면 키가 반복될 때마다 `onChanged` 가 다시 불립니다. |
| 공통 | 카드를 묶는 그룹이 없어, 여러 개를 고를 수 있는 목록인지나 목록의 몇 번째인지를 알리지 않습니다. |

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은
> [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

두 플랫폼은 속성의 이름 · 기본값이 같고, 렌더링은 각 플랫폼의 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 선택 상태 알림 | 없음 | `aria-pressed` |
| 활성 카드의 Tab 정지점 | 하나 | 둘(카드, 안의 체크박스) |
| 안의 체크박스 감추기 | `IgnorePointer` · `ExcludeFocus` · `ExcludeSemantics` 로 감쌉니다 | `pointer-events-none` · `aria-hidden` 인 `<div>` 로 감쌉니다. 포커스는 막지 않습니다 |
| 상태가 바뀔 때의 전환 | 바탕과 테두리는 `AnimatedContainer` 로, 테두리 두께 차이를 메우는 여백은 `AnimatedPadding` 으로 전환합니다. 글자 모양과 색은 바로 바뀝니다 | 카드의 CSS `transition-all` 로 전환합니다. 글자색과 굵기도 함께 전환합니다 |
| hover 감지 | `Clickable` 안의 `MouseRegion` | `mouseenter` · `mouseleave` |
| 투명한 테두리 색 | 그 상태의 테두리 두께가 0 이 됩니다(알려진 제약) | 두께를 그대로 둡니다 |
| `borderWidth` 보다 굵은 `selectedBorderWidth` | 실제 테두리를 그리고 다른 상태의 안쪽 여백으로 크기를 맞춥니다(고른 비활성 카드는 예외) | `borderWidth` 테두리에 안쪽 그림자를 덧그려 크기를 유지합니다 |
| `borderWidth` 보다 얇은 `selectedBorderWidth` | 고른 카드를 얇게 그립니다 | 효과가 없습니다 |
| `child` 안의 아이콘 색 | 카드의 글자색을 따라가지 않습니다. 비활성 카드에서도 그대로라 `iconStyle` 로 직접 정합니다 | 색을 따로 주지 않은 아이콘은 글자색(`currentColor`)을 따라갑니다 |
| `child` 안의 버튼을 누를 때 | 안쪽 버튼만 실행됩니다 | 안쪽 버튼과 카드의 `onChanged` 가 함께 실행됩니다 |
| 비활성 커서 | `forbidden` | `not-allowed` |
| 마우스로 눌렀을 때 포커스 | 옮기지 않습니다 | 활성 카드로 옮깁니다(링은 없음) |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` 를 받습니다. `onClick` 같은 DOM 콜백도 받지만 불리지 않습니다(알려진 제약) |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. `T` 는 답을 구분하는 값의 타입이고, 표의 `W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다. Jaspr Web 은 여기에 `id` · `classes` · `css` · `attributes` · `eventHandlers` 와 `onChange` · `onClick` · `onInput` · `onKeyDown` · `onKeyUp` · `onMouseEnter` · `onMouseLeave` 를 더 받습니다. 다만 이 일곱 콜백은 불리지 않고, `eventHandlers` 도 일부 이벤트는 받지 못합니다([알려진 제약](/components/multi-answer-card#알려진-제약)). `id` · `classes` · `css` 는 카드 상자가 아니라 카드를 감싼 누름 요소에 붙습니다.

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `T` | 필수 | 카드가 나타내는 값. 누르면 `onChanged` 에 이 값을 넘깁니다. |
| `child` | `W` | 필수 | 답 내용 |

### 상태와 겉모습

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `selected` | `bool` | `false` | 이 답이 골라졌는지 |
| `enabled` | `bool` | `true` | 누를 수 있는지. `onChanged` 가 있는지와 무관합니다. |
| `multiAnswerCardStyle` | `CoreMultiAnswerCardStyle?` | `null` | 보이는 값 덮어쓰기 |

### 콜백

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `onChanged` | `void Function(T)?` | `null` | 활성 카드를 누르면 `value` 를 넘겨 부릅니다. |

이미 만든 카드에는 `withStyle` 로 같은 값을 덧붙일 수 있고([빠른 덮어쓰기](/components/multi-answer-card#빠른-덮어쓰기)), `copyWith` 로 속성을 바꾼 새 카드를 만들 수 있습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreMultiAnswerCardStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Card background colour override (unselected). |
| `selectedBackgroundColor` | `CoreColor?` | Card background colour override (selected). |
| `borderColor` | `CoreColor?` | Card border colour override (unselected). |
| `selectedBorderColor` | `CoreColor?` | Card border colour override (selected). |
| `hoverColor` | `CoreColor?` | Card hover background colour override. |
| `hoverBorderColor` | `CoreColor?` | Card border colour override while hovered (enabled, unselected). |
| `disabledBackgroundColor` | `CoreColor?` | Card background colour override when disabled. |
| `disabledBorderColor` | `CoreColor?` | Card border colour override when disabled. |
| `borderWidth` | `double?` | Card border width override (unselected, logical px). |
| `selectedBorderWidth` | `double?` | Card border width override (selected, logical px). |
| `borderRadius` | `CoreBorderRadius?` | Card border radius override. |
| `padding` | `CoreEdgeInsets?` | Card content padding override. |
| `transitionDuration` | `Duration?` | Transition duration override for selected / hover state changes; `null` → [defaultTransitionDuration]. |
| `bodyTextStyle` | `CoreTextStyle?` | Body text style for the caller-supplied child widget (typography role + colour in one `CoreTextStyle`). `null` defers to [defaultBodyTextStyle] — the design-system base typography, so the card text matches the Web side's inherited `bodyMedium` base. |
| `selectedBodyTextStyle` | `CoreTextStyle?` | Body text style override while selected (enabled). `null` defers to [defaultSelectedBodyTextStyle]. |
| `disabledBodyTextStyle` | `CoreTextStyle?` | Body text style override when disabled. `null` defers to [defaultDisabledBodyTextStyle]. |
| `checkboxGapStyle` | `CoreGapStyle?` | Gap between the answer content and the trailing checkbox. Laid over [defaultCheckboxGapStyle] and passed to the `Gap` as is. |
| `checkboxStyle` | `CoreCheckboxStyle?` | Style for the trailing `Checkbox`. Laid over [defaultCheckboxStyle] and passed to the `Checkbox` as is, which fills in the rest. |
| `clickableStyle` | `CoreClickableStyle?` | Style for the card's `Clickable` — press scale, durations, focus ring, disabled opacity. Laid over [defaultClickableStyle] and passed to the `Clickable` as is, which fills in the rest. |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 설명은 소스 주석에서 만들어지며, 몇 필드는 설명이 지금 동작을 다 담지 못합니다.

- `bodyTextStyle` — 설명의 `bodyMedium` 과 달리 기본 글자는 두 플랫폼 모두 `bodyLarge`(15)입니다. 고르지 않은 활성 카드(hover 포함)에만 닿습니다.
- `backgroundColor` · `borderColor` — 고르지 않고 hover 하지 않은 활성 카드에만 씁니다. hover 한 카드는 `hoverColor` · `hoverBorderColor` 를, 비활성 카드는 `disabledBackgroundColor` · `disabledBorderColor` 를 씁니다.
- `borderWidth` — 설명은 고르지 않은 카드라고 적지만, 고른 채 비활성인 카드에도 씁니다.
- `selectedBorderWidth` — 고른 활성 카드의 두께입니다. `borderWidth` 와 다른 값을 줄 때의 동작은 [플랫폼 차이](/components/multi-answer-card#플랫폼-차이)에 있습니다.
- `clickableStyle` — 카드의 기본값 `disabledOpacity: 1` 위에 합쳐 `Clickable` 에 넘깁니다. `borderRadius` 는 카드가 아니라 포커스 링의 모서리를 정합니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="multi-answer-card/related-multiple-choice" title="MultipleChoice">

여러 선택지 중 하나를 Chip 줄에서 고릅니다. [MultipleChoice](/components/multiple-choice) 문서에서 속성을 봅니다.

</Card>
<Card component="checkbox" props="checked=true" label="약관에 동의합니다" title="Checkbox">

카드 없이 체크 하나를 둡니다. 답안 카드 끝의 표시도 이 컴포넌트입니다.

</Card>
<Card component="option-item" props="selection=multiple;selected=true" label="무료 배송" title="OptionItem">

선택지 목록의 한 줄입니다. 여럿을 고르는 줄은 끝에 체크박스를 그립니다.

</Card>
</Cards>

고르는 상태 없이 내용을 묶는 상자는 [Card](/components/card) 입니다.
