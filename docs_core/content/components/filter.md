---
title: Filter
description: 상호 배타적인 옵션을 토글 버튼 그룹으로 묶는 분절형 필터 컨트롤
category: form
platforms: [flutter, web]
related: [radio-group, tabs, chip-group]
tags: [form-control, segmented, selection]
template: v2
source: control/filter
---

# Filter

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 Filter 를 확인하고, 만들어진 코드를 그대로 복사하세요. 칸을 눌러 선택을 바꾸고, 초기화 버튼으로 선택을 비울 수 있습니다.

<Playground component="filter" />

Filter 는 여러 보기 조건 중 하나를 고릅니다. 라디오 묶음처럼 한 번에 하나만 고를 수 있습니다. 선택한 값은 Filter 가 기억하지 않습니다. 지금 값을 `groupValue` 로 넘기고, `onValueChanged` 가 알려 주는 새 값으로 바꿔 다시 그립니다.

```dart
Filter<String>(
  groupValue: selected,
  onValueChanged: (value) => setState(() => selected = value),
  items: const [
    CoreFilterItem(value: 'all', label: '전체'),
    CoreFilterItem(value: 'active', label: '진행 중'),
    CoreFilterItem(value: 'done', label: '완료'),
  ],
)
```

## 구조

트랙, 칸, 선택한 칸의 면은 [ToggleGroup](/components/toggle-group) 이 그립니다. Filter 는 트랙 안쪽 끝에 구분선과 초기화 버튼을 더합니다. 두 플랫폼의 구조가 같습니다.

<Anatomy demo="filter/anatomy">
<AnatomyItem part="container" name="Container">

칸을 담는 트랙. `surfaceContainer` 채움과 둥근 모서리를 갖습니다.

</AnatomyItem>
<AnatomyItem select="[role=radio][aria-checked=true] div" side="top" name="selected">

선택한 칸. `surfaceRaised` 면과 가장 작은 그림자로 트랙 위에 올라옵니다.

</AnatomyItem>
<AnatomyItem part="label" name="label">

칸 이름(`CoreFilterItem.label`). 화면에 그리지 않아도 접근 가능한 이름이 됩니다.

</AnatomyItem>
<AnatomyItem select="[role=radio] ~ div:last-child div:first-child" side="top" name="divider">

칸과 초기화 버튼을 나누는 두께 1 의 `outlineVariant` 선. 길이는 `md` 16 · `sm` 14 이고, 초기화 버튼이 보일 때만 그립니다.

</AnatomyItem>
<AnatomyItem select="button" side="right" name="reset">

초기화 버튼. `ghost` 모양 · `sm` 크기의 정사각 [Button](/components/button) 에 ✕ 아이콘을 넣은 것입니다. 한 변의 길이와 ✕ 크기는 이 Button 의 `sm` 이 아니라 Filter 의 `size` 가 정합니다.

</AnatomyItem>
</Anatomy>

### 칸의 모양

선택지는 `items` 의 `CoreFilterItem` 으로 줍니다. 칸은 라벨만, 아이콘과 라벨, 아이콘만의 세 모양이 있습니다. `icon` 은 호출자가 만든 위젯(Flutter `Widget` · Jaspr `Component`)이고, 선택 상태에 맞는 크기와 색을 칸에서 물려받습니다.

<Preview demo="filter/item-shapes" />

```dart
Filter<String>(
  groupValue: selected,
  onValueChanged: (value) => setState(() => selected = value),
  items: [
    CoreFilterItem(value: 'all', label: '전체'),
    CoreFilterItem(
      value: 'upcoming',
      label: '예정',
      icon: Icon(LucideIcons.calendar),
    ),
    CoreFilterItem(
      value: 'starred',
      label: '관심',
      icon: Icon(LucideIcons.star),
      showLabel: false, // 아이콘만 그립니다. label 은 접근 이름으로 남습니다.
    ),
  ],
)
```

`icon` 없이 `showLabel: false` 만 주면 글자도 아이콘도 없는 빈 칸이 됩니다.

<a id="변형-variants"></a>

## Variant

variant 는 `segmented` 하나입니다.

<VariantRow name="segmented" component="filter" props="variant=segmented;showResetButton=true">

트랙 위에서 선택한 칸이 올라오는 분절형입니다. 기본값입니다.

</VariantRow>

<Note>

모양이 하나라 `variant` 를 바꿔도 겉모습은 달라지지 않습니다. 이 값은 테마의 `variantStyles` 에서 어느 값을 쓸지 고르는 데 씁니다.

</Note>

<Note label="미리보기 배경">

트랙은 `surfaceContainer` 라 같은 색으로 채운 면 위에서는 윤곽이 보이지 않습니다. `surface` 바탕 위에서는 트랙이 보입니다.

</Note>

<a id="레이아웃"></a>

## 크기

`size` 는 `sm` 과 `md`(기본값) 두 단계입니다. `xs` · `lg` · `xl` · `xl2` 는 `md` 로 그립니다. Filter 만의 크기 타입은 없고, 다른 컴포넌트와 같은 `CoreComponentSize` 를 씁니다. 같은 `size` 를 안에 있는 ToggleGroup 에 넘겨 트랙과 칸의 크기를 정하고, 초기화 버튼과 구분선의 크기는 Filter 가 크기마다 따로 정합니다. 표의 숫자는 표준 밀도 기준입니다.

<SizeSpec component="filter" props="showResetButton=true" />

<Note>

`md` 의 초기화 버튼 모서리는 8 로 칸 모서리(6)와 다릅니다. `sm` 은 둘 다 6 입니다. 칸 아이콘은 두 크기 모두 16 이고, 초기화 버튼의 ✕ 만 `sm` 에서 14 로 줄어듭니다.

</Note>

### 칸의 폭

칸의 높이는 정해져 있고, 칸은 높이보다 좁아지지 않습니다. 라벨 폭은 선택했을 때의 SemiBold 글자로 잽니다. 그래서 선택이 옮겨 가도 칸 폭과 전체 폭이 변하지 않습니다.

| 칸의 모양 | `md` | `sm` |
| --- | --- | --- |
| 라벨만 | 라벨 폭 + 20 (최소 32) | 라벨 폭 + 16 (최소 26) |
| 아이콘과 라벨 | 라벨 폭 + 36 | 라벨 폭 + 32 |
| 아이콘만 | 32 × 32 | 26 × 26 |

아이콘과 라벨을 함께 두면 아이콘과 라벨 사이는 8 이고, 아이콘 쪽 바깥 여백(`md` 2 · `sm` 0)이 라벨 쪽 바깥 여백(`md` 10 · `sm` 8)보다 좁습니다.

### 밀도

앱 밀도(compact · spacious)를 바꿔도 Filter 의 높이는 `md` 40, `sm` 32 그대로입니다. 칸 높이(32 · 26), 초기화 버튼 크기, 트랙 안쪽 여백(4 · 3)이 움직이지 않기 때문입니다. 라벨의 좌우 여백, 마지막 칸과 구분선 사이의 간격, 일부 모서리는 밀도를 따라 바뀝니다. 옆에 놓은 `md` 입력창은 compact 에서 32, spacious 에서 48 로 바뀌므로, 표준 밀도가 아니면 같은 줄에서 높이가 맞지 않습니다.

<a id="동작-스펙-behavior"></a>
<a id="시각"></a>

## 상태

<Preview demo="filter/states" />

| 항목 | 동작 |
| --- | --- |
| 선택한 칸 | `surfaceRaised` 면과 가장 작은 그림자(`CoreShadow.xs`)를 갖고, 라벨은 `onSurface` · SemiBold 입니다. |
| 다른 칸 | 채움이 없어 트랙이 그대로 보이고, 라벨과 아이콘은 `onSurfaceVariant` 입니다. |
| 선택 없음 | `groupValue` 가 `null` 이거나 어느 항목의 `value` 와도 같지 않으면 올라오는 칸이 없습니다. |
| Hover | 칸 위에 `onSurface` 3% 를 덮습니다. 선택한 칸도 같습니다. |
| 눌림 | 누르는 동안 칸이 0.97 배로 줄어듭니다. |
| Focus | 키보드로 포커스하면 칸 바깥에 링을 그립니다. |
| 초기화 버튼 | hover 와 눌림은 `ghost` [Button](/components/button) 을 따르고, ✕ 색은 `onSurfaceVariant` 그대로입니다. |
| 색 전환 | 선택이 바뀔 때 150ms 동안 색이 바뀝니다. 동작 줄이기 설정에서는 바로 바뀝니다. |

### 선택과 초기화

- 칸을 누르면 `onValueChanged` 가 그 칸의 `value` 로 불립니다. 화면은 호출자가 `groupValue` 를 바꿔 다시 그릴 때 바뀝니다.
- 이미 선택한 칸을 다시 눌러도 선택이 풀리지 않고, 같은 값으로 `onValueChanged` 가 다시 불립니다.
- 구분선과 초기화 버튼은 `showResetButton: true` 이고 `onReset` 이 있을 때만 보입니다. 선택이 없을 때도 보입니다.
- 초기화 버튼은 `onReset` 만 부릅니다. 선택은 호출자가 `groupValue` 를 `null` 로 바꿔 비웁니다.
- Filter 는 걸러 낼 데이터나 본문을 갖지 않습니다. 선택에 맞게 목록을 바꾸는 것은 호출자의 일입니다.

### 비활성

`enabled: false` 로 끕니다. `enabled` 가 `null`(기본값)이면 켜진 상태입니다.

- 트랙은 `disabledContainer`, 선택한 칸은 그림자 없이 `surfaceContainerHigh`, 글자와 칸 아이콘은 `disabledContent` 입니다.
- 구분선은 `disabledOutline`, 초기화 버튼의 ✕ 는 `disabledContent` 입니다.
- 칸과 초기화 버튼은 누를 수 없습니다. 칸에는 hover 표시가 없습니다. Jaspr Web 의 초기화 버튼은 [알려진 제약](/components/filter#알려진-제약)을 보세요.
- 칸 하나만 끄는 속성은 없습니다. 고를 수 없는 값은 `items` 에서 뺍니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 언제 쓰나

- 목록 위에서 보기 조건 하나를 바로 바꿀 때 (상태, 분류, 정렬 기준)
- 선택지가 적고 모두 늘 보여야 할 때
- 선택을 해제하는 버튼이 함께 필요할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 초기화 버튼 없이 값 하나를 고르거나, 칸을 세로로 놓을 때 | [ToggleGroup](/components/toggle-group) |
| 폼에서 라디오 입력으로 값을 받을 때 | [RadioGroup](/components/radio-group) |
| 선택에 따라 보여 줄 내용(탭)을 바꿀 때 | [Tabs](/components/tabs), 내용 패널까지 그리려면 [TabPane](/components/tab-pane) |
| 여러 조건을 함께 켤 때 | [ChipGroup](/components/chip-group) |
| 선택지가 많아 한 줄에 들어가지 않을 때 | [Select](/components/select) |

<a id="do"></a>

### 선택 해제

선택이 없는 상태가 의미 있으면 `showResetButton` 과 `onReset` 을 함께 줍니다. 둘 중 하나만 주면 초기화 버튼이 보이지 않습니다.

<Preview demo="filter/do-reset" />

```dart
Filter<String>(
  groupValue: selected,
  onValueChanged: (value) => setState(() => selected = value),
  showResetButton: true,
  onReset: () => setState(() => selected = null),
  items: items,
)
```

<a id="dont"></a>

### 라벨과 조건

<Cards columns="2">
<Card demo="filter/do-short-labels" tone="do" eyebrow="이렇게 하세요">

라벨은 한두 단어로 짧게 쓰고, 선택지는 몇 개만 둡니다.

</Card>
<Card demo="filter/dont-long-labels" tone="dont" eyebrow="이렇게 하지 마세요">

긴 라벨은 트랙을 넓힙니다. Filter 는 칸을 다음 줄로 넘기거나 가로로 스크롤하지 않습니다.

</Card>
<Card demo="filter/do-multi" tone="do" eyebrow="이렇게 하세요">

함께 켤 수 있는 조건은 ChipGroup 의 다중 선택으로 받습니다.

</Card>
<Card demo="filter/dont-multi" tone="dont" eyebrow="이렇게 하지 마세요">

함께 켤 수 있는 조건을 Filter 에 두면 하나만 고를 수 있습니다. `groupValue` 는 값 하나입니다.

</Card>
</Cards>

## 배치

<Cards columns="2">
<Card demo="filter/placement-toolbar" title="같은 줄">

표준 밀도에서 `md` Filter(40)는 `md` 입력창과, `sm`(32)은 `sm` 컨트롤과 높이가 같습니다.

</Card>
<Card demo="filter/placement-fill" title="가로 채우기">

좁은 열에서는 `fillWidth: true` 로 위아래의 폭 가득한 내용과 가장자리를 맞춥니다.

</Card>
</Cards>

### 폭 채우기

`fillWidth: true` 를 주면 트랙이 부모가 주는 폭을 채우고, 칸이 그 폭을 똑같이 나눠 가집니다. 휴대폰 폭의 열처럼 필터가 위아래의 폭 가득한 내용과 가장자리를 맞춰야 할 때 씁니다. ToggleGroup 에 Filter 의 모양을 옮겨 붙일 필요가 없습니다. 두 플랫폼의 코드가 같습니다.

```dart
Filter<String>(
  groupValue: selected,
  onValueChanged: (value) => setState(() => selected = value),
  fillWidth: true,
  items: const [
    CoreFilterItem(value: 'all', label: '전체'),
    CoreFilterItem(value: 'active', label: '진행 중'),
    CoreFilterItem(value: 'done', label: '완료'),
  ],
)
```

- 구분선과 초기화 버튼은 제 폭 그대로 트랙 끝에 남고, 칸이 나머지를 똑같이 나눕니다. 칸 안의 내용은 가운데에 놓입니다.
- 칸 사이 간격, 트랙 안쪽 여백, 구분선 앞뒤 간격은 그대로입니다.
- 칸은 모두 같은 폭을 받으므로, 가장 긴 라벨이 그 폭에 들어가는 자리에서 씁니다.
- 부모의 폭이 정해져 있어야 합니다. Flutter 에서 `Row` 안에 두면 `Expanded` 나 `SizedBox` 로 폭을 줍니다.

### 좁은 화면

칸은 한 줄에 놓이고, 칸을 다음 줄로 넘기거나 가로로 스크롤하지 않습니다. 기본(`fillWidth: false`)에서는 트랙이 칸 내용만큼만 차지합니다. 그 폭보다 좁은 자리에서는 Flutter 는 넘침 오류가 나고, Jaspr Web 은 칸의 라벨이 줄을 바꾸거나 밖으로 넘칩니다. 선택지를 줄이거나 [Select](/components/select) 로 바꿉니다.

### 떠 있는 패널 안

다크 모드에서는 떠 있는 패널(`surfaceBright`)과 트랙(`surfaceContainer`)이 같은 색입니다. 패널 안에 둘 때는 트랙을 한 단 밝게 지정합니다. 시간 선택기와 색 선택기가 패널 안의 ToggleGroup 에 쓰는 방식과 같습니다.

```dart
Filter<String>(
  groupValue: selected,
  onValueChanged: (value) => setState(() => selected = value),
  items: items,
  filterStyle: const CoreFilterStyle(
    toggleGroupStyle: CoreToggleGroupStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
    ),
  ),
)
```

<a id="스타일-커스터마이징-style"></a>
<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

variant · 크기 · 초기화 버튼 · 폭 채우기는 위젯 속성으로 고르고, 보이는 값은 `filterStyle`(`CoreFilterStyle`) 하나로 덮어씁니다.

- **트랙과 칸** — `toggleGroupStyle`(`CoreToggleGroupStyle`). ToggleGroup 의 스타일을 그대로 받습니다.
- **초기화 버튼** — `resetButtonStyle`(`CoreButtonStyle`). 크기(`width` · `height`), 모서리, 글자색, ✕ 아이콘(`leadingIconStyle`), 전환 시간(`animationDuration`)을 정합니다. 정사각 버튼이라 `padding` 은 적용되지 않으므로, 안쪽 여백은 `iconShapePadding` 으로 줍니다. ✕ 색을 바꿀 때는 `foregroundColor` 와 `hoverForegroundColor` 를 함께 줍니다. 하나만 주면 다른 상태에는 `onSurfaceVariant` 가 남습니다.
- **구분선** — `dividerStyle` · `disabledDividerColor` · `dividerHeight`.
- **간격** — 마지막 칸에서 구분선까지는 `dividerLeadingSpacing`(기본 6), 구분선에서 초기화 버튼까지는 `trailingSpacing`(기본 2)입니다. 버튼 안에 ✕ 둘레의 여백이 있어 2 만으로도 선의 양쪽이 비슷하게 보입니다.

트랙과 칸을 정하는 낱개 필드(`backgroundColor` · `itemPadding` 등)는 deprecated 입니다. 아직은 `toggleGroupStyle` 아래에 합쳐 적용되며, 둘 다 주면 `toggleGroupStyle` 이 우선합니다. 두 값을 서로 다른 곳에서 줘도 같습니다. 예를 들어 앱의 Filter 테마(`CoreFilterTheme.style`)에 준 `toggleGroupStyle` 은 `filterStyle` 에 준 낱개 필드보다 우선합니다.

<Split>

<Code language="dart" title="Filter 하나만 바꾸기">
Filter<String>(
  groupValue: selected,
  onValueChanged: (value) => setState(() => selected = value),
  items: items,
  filterStyle: const CoreFilterStyle(
    toggleGroupStyle: CoreToggleGroupStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainerHighest),
      itemSpacing: CoreSpace.space4,
    ),
    dividerHeight: CoreSize.size24,
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    filter: CoreFilterTheme(
      style: CoreFilterStyle(
        trailingSpacing: CoreSpace.space4,
      ),
    ),
  ),
)
</Code>

</Split>

<a id="테마-커스터마이징-theme"></a>

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
디자인 시스템 기본값 (CoreFilterStyle.default* · defaultsBySize[size])
  → CoreComponentTheme.filter.style                    // 앱 전체
  → CoreComponentTheme.filter.variantStyles[variant]   // 앱 전체, variant 별
  → filterStyle                                        // 인스턴스
```

칸은 ToggleGroup 이 그리므로 앱의 ToggleGroup 테마(`CoreComponentTheme.toggleGroup`)도 칸에 닿습니다. Filter 쪽에서 정한 값이 있으면 그 값이 우선합니다. 초기화 버튼과 구분선은 [Button](/components/button) 과 [Divider](/components/divider) 이므로 그 컴포넌트의 앱 테마도 받고, Filter 가 넘기는 값이 그 위에 얹힙니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Filter` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `filterStyle` 과 같게 동작합니다. `.radius16` 처럼 Core 토큰 이름과 같은 짧은 getter 도 있습니다. 모서리 getter 는 트랙의 모서리를, 색 getter 는 트랙의 채움을 바꿉니다(`.transparent` 는 트랙 채움을 비웁니다).

<Preview component="filter" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class FilterChainExample extends StatefulWidget {
  const FilterChainExample({super.key});

  @override
  State<FilterChainExample> createState() => _FilterChainExampleState();
}

class _FilterChainExampleState extends State<FilterChainExample> {
  String? _selected = 'svelte';

  void handleValueChanged(String value) {
    setState(() => _selected = value);
  }

  void handleReset() {
    setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Filter<String>(
          groupValue: _selected,
          onValueChanged: handleValueChanged,
          onReset: handleReset,
          showResetButton: true,
          items: const [
            CoreFilterItem(value: 'svelte', label: 'Svelte'),
            CoreFilterItem(value: 'vue', label: 'Vue'),
            CoreFilterItem(value: 'react', label: 'React'),
          ],
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Filter<String>(
          groupValue: _selected,
          onValueChanged: handleValueChanged,
          onReset: handleReset,
          showResetButton: true,
          items: const [
            CoreFilterItem(value: 'svelte', label: 'Svelte'),
            CoreFilterItem(value: 'vue', label: 'Vue'),
            CoreFilterItem(value: 'react', label: 'React'),
          ],
        ).withStyle(
          const CoreFilterStyle(
            toggleGroupStyle: CoreToggleGroupStyle(
              backgroundColor: CoreColor.token(CoreColors.tertiary),
              borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              itemBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
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
class FilterChainExample extends StatefulComponent {
  const FilterChainExample({super.key});

  @override
  State<FilterChainExample> createState() => _FilterChainExampleState();
}

class _FilterChainExampleState extends State<FilterChainExample> {
  String? _selected = 'svelte';

  void handleValueChanged(String value) {
    setState(() => _selected = value);
  }

  void handleReset() {
    setState(() => _selected = null);
  }

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Filter<String>(
          groupValue: _selected,
          onValueChanged: handleValueChanged,
          onReset: handleReset,
          showResetButton: true,
          items: const [
            CoreFilterItem(value: 'svelte', label: 'Svelte'),
            CoreFilterItem(value: 'vue', label: 'Vue'),
            CoreFilterItem(value: 'react', label: 'React'),
          ],
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Filter<String>(
          groupValue: _selected,
          onValueChanged: handleValueChanged,
          onReset: handleReset,
          showResetButton: true,
          items: const [
            CoreFilterItem(value: 'svelte', label: 'Svelte'),
            CoreFilterItem(value: 'vue', label: 'Vue'),
            CoreFilterItem(value: 'react', label: 'React'),
          ],
        ).withStyle(
          const CoreFilterStyle(
            toggleGroupStyle: CoreToggleGroupStyle(
              backgroundColor: CoreColor.token(CoreColors.tertiary),
              borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              itemBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
              padding: CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space24,
                vertical: CoreSpace.space8,
              ),
            ),
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

<a id="접근성-accessibility"></a>

## 접근성

Jaspr Web 은 Filter 를 라디오 묶음으로 알리고, Flutter 는 칸마다 상호 배타 그룹의 선택 상태를 알립니다.

### 역할

| 부분 | Flutter | Jaspr Web |
| --- | --- | --- |
| 묶음 | 그룹 노드가 없습니다 | `role="radiogroup"`. 비활성이면 `aria-disabled="true"` |
| 칸 | 선택 상태(`checked`), 상호 배타 그룹, 활성 여부, 이름 | `role="radio"` · `aria-checked` · `aria-label`. 비활성이면 `aria-disabled="true"` |
| 초기화 버튼 | 이름이 있는 버튼 | `aria-label` 이 있는 `<button>`. 비활성이면 `disabled` |
| 구분선 | 알리지 않습니다 | 역할 없음 |

두 플랫폼 모두 칸은 버튼 역할로 알리지 않습니다. 라벨 폭을 잡아 두는 숨은 SemiBold 글자는 보조 기술에서 빠집니다(Flutter `Visibility(visible: false)`, Jaspr Web `aria-hidden="true"`).

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` | 칸마다 멈추고, 그다음 초기화 버튼에 멈춥니다 | 묶음에서 한 번 멈추고(선택한 칸, 없으면 첫 칸), 그다음 초기화 버튼에 멈춥니다 |
| `Enter` · `Space` | 포커스한 칸을 고르거나 초기화합니다 | 같습니다 |
| `←` · `↑` · `→` · `↓` | Filter 의 전용 처리가 없고 선택은 바뀌지 않습니다. 앱의 기본 단축키대로, 네이티브 앱에서는 그 방향으로 포커스만 옮기고 Flutter web 에서는 화면을 스크롤합니다 | `←` · `↑` 는 이전 칸, `→` · `↓` 는 다음 칸으로 포커스를 옮기고 그 칸을 고릅니다. 끝에서는 반대쪽 끝으로 돌아갑니다 |
| `Home` · `End` | Filter 의 전용 처리가 없습니다 | 첫 칸 · 마지막 칸으로 옮기고 고릅니다 |

Jaspr Web 은 라디오 묶음의 키보드 방식을 따릅니다. 초기화 버튼은 칸 뒤에 있으므로 `Tab` 순서에서 묶음의 마지막입니다. 비활성 Filter 는 칸과 초기화 버튼이 모두 `Tab` 순서에서 빠지고, Jaspr Web 의 화살표도 동작하지 않습니다.

### 스크린 리더

- 칸의 접근 가능한 이름은 `CoreFilterItem.label` 입니다(Jaspr Web `aria-label`, Flutter `Semantics(label:)`). 아이콘만 그리는 칸도 이름을 갖습니다.
- 선택 상태는 Jaspr Web `aria-checked`, Flutter `Semantics(checked:)` 로 전달합니다.
- 초기화 버튼의 이름은 렌더할 때의 언어로 된 문구입니다(영어 `"Reset filter"`, 한국어 `"필터 초기화"`).
- 선택이 바뀐 것을 따로 알리는 라이브 리전은 없습니다.
- 묶음 자체에는 이름이 없습니다. 무엇을 고르는 필터인지 알려야 하면 바깥을 감싸 이름을 줍니다. Flutter 는 `Semantics(container: true, label: '주문 상태', child: …)`, Jaspr Web 은 `role="group"` 과 `aria-label` 을 단 `div` 로 감쌉니다.

### 포커스 관리

- 오버레이가 아니므로 마운트될 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다.
- 포커스 링은 칸마다 `Clickable` 이 그리고, 키보드로 포커스했을 때만 나타납니다.
- 선택이 바뀌어도 Filter 는 포커스를 따로 옮기지 않습니다. 키보드로 고른 뒤에는 포커스가 그 칸에 남습니다.
- 초기화 버튼은 선택을 비워도 계속 보이므로, 키보드로 누른 뒤에도 포커스가 버튼에 남습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 칸 하나만 비활성으로 두거나, 보이는 라벨과 다른 접근 이름을 줄 수 없습니다. |
| 공통 | 아이콘과 라벨을 함께 둔 칸은 아이콘 쪽 여백이 라벨 쪽보다 좁습니다. |
| 공통 | 키보드 포커스 링의 모서리는 칸 모서리(6)가 아니라 `Clickable` 의 기본 모서리(4)를 기준으로 그립니다. |
| 공통 | `Form` · `FormField` 에 값을 보고하지 않습니다. 제출할 값은 `onValueChanged` 로 받아 직접 들고 있어야 합니다. |
| Flutter | 칸마다 `Tab` 이 멈추고, 화살표로 선택을 바꾸지 않습니다. 칸은 `Enter` · `Space` 로 고릅니다. |
| Flutter | 라벨이 보이는 칸은 접근 이름과 화면의 글자가 한 노드로 합쳐져, 스크린 리더가 이름을 두 번 읽을 수 있습니다. |
| Flutter | `CoUIApp(scaling:)` 이 1 이 아니면 초기화 버튼의 높이에 배율이 두 번 곱해지고, 배율이 1 보다 크면 폭도 그 높이를 따라갑니다. 예를 들어 1.25 에서는 `md` 초기화 버튼이 40 × 40 이 아니라 50 × 50 이 되고 트랙도 따라 높아집니다. 기본 배율 1 에서는 나타나지 않습니다. |
| Jaspr Web | 묶음에 이름을 줄 속성이 없습니다. `Filter` 생성자는 `id` 만 받고 `attributes` · `classes` · `css` 를 받지 않습니다. 이름이 필요하면 바깥을 감쌉니다. |
| Jaspr Web | 초기화 버튼에 포커스가 있을 때도 화살표 · `Home` · `End` 가 칸의 키로 처리되어 선택이 바뀝니다. 화살표는 지금 선택한 칸(없으면 첫 칸)을 기준으로 옮깁니다. |
| Jaspr Web | 비활성 Filter 에서도 초기화 버튼에 포인터를 올리면 옅은 hover 채움이 보입니다. 누를 수는 없습니다. |
| Jaspr Web | 초기화 버튼이 `role="radiogroup"` 안에 있습니다. 라디오 묶음은 라디오만 담는 역할이라, 보조 기술에 따라 버튼이 묶음의 일부로 읽힐 수 있습니다. |

대비 · 모션처럼 모든 컴포넌트에 같이 적용되는 것은 [전역 접근성 축](/accessibility) 에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

속성은 같고, 렌더링과 키보드는 각 플랫폼의 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 선택 알림 | 칸마다 `checked` · 상호 배타 그룹 | `radiogroup` · `radio` · `aria-checked` |
| `Tab` | 칸마다 멈춥니다 | 묶음에서 한 번 멈춥니다 |
| 화살표 · `Home` · `End` | 선택을 바꾸지 않습니다 | 칸을 옮기며 고릅니다 |
| 색 전환 | `AnimatedContainer` | CSS transition |
| 라벨 폭 유지 | 보이지 않는 SemiBold 글자가 폭을 잡습니다 | `aria-hidden` 사본이 폭을 잡습니다 |
| 폭 채우기(`fillWidth`) | 칸마다 `Expanded` | 트랙은 부모 폭, 칸마다 `flex: 1 1 0%` · `min-width: 0` |
| 폭이 모자랄 때 | 넘침 오류가 납니다 | 라벨이 줄을 바꾸거나 칸 밖으로 넘칩니다 |
| 비활성 초기화 버튼의 hover | 표시가 없습니다 | 옅은 채움이 보입니다 |
| HTML `id` | 해당 없음 (`key`) | `id` 를 트랙에 붙입니다 |
| `copyWith` 의 `attributes` · `classes` · `css` | 해당 없음 | 인자는 있지만 적용하지 않습니다 |

<a id="props-parameters"></a>

## API

`T` 는 선택 값의 타입이고, `W` 는 Flutter `Widget` · Jaspr `Component` 입니다.

### 내용

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `items` | `List<CoreFilterItem<T, W>>` | 필수 | 선택지. 하나 이상이어야 합니다. |
| `groupValue` | `T?` | 필수 | 지금 선택한 값. 항목의 `value` 와 `==` 로 비교합니다. `null` 이면 선택한 칸이 없습니다. |

### 상태와 형태

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `variant` | `CoreFilterVariant` | `segmented` | 모양. 지금은 하나입니다. |
| `size` | `CoreComponentSize` | `md` | `sm` 이 아닌 값은 `md` 로 그립니다. |
| `showResetButton` | `bool` | `false` | 초기화 버튼을 보입니다. `onReset` 도 있어야 보입니다. |
| `enabled` | `bool?` | `null` | `null` 이면 켜진 상태이고, `false` 면 입력을 받지 않습니다. |
| `fillWidth` | `bool` | `false` | 트랙이 부모 폭을 채우고 칸이 그 폭을 똑같이 나눕니다. |
| `filterStyle` | `CoreFilterStyle?` | `null` | 겉모습을 바꾸는 값 묶음. |

### 콜백

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `onValueChanged` | `void Function(T)` | 필수 | 칸을 누르면 그 칸의 값으로 불립니다. 이미 선택한 칸을 눌러도 불립니다. |
| `onReset` | `void Function()?` | `null` | 초기화 버튼을 누르면 불립니다. |

### `CoreFilterItem`

선택지 하나입니다. 두 플랫폼이 같은 타입을 씁니다. `items` 목록 안에 바로 쓰면 `W` 는 따로 적지 않아도 추론됩니다.

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `T` | 필수 | 이 칸의 값. `groupValue` 와 `==` 로 비교합니다. |
| `label` | `String` | 필수 | 칸의 이름. `showLabel: false` 여도 접근 가능한 이름으로 남습니다. |
| `icon` | `W?` | `null` | 라벨 앞에 그리는 아이콘. 크기와 색은 `toggleGroupStyle` 의 `iconStyle` · `selectedIconStyle` · `disabledIconStyle` 이 정합니다. |
| `showLabel` | `bool` | `true` | 라벨을 그릴지. `icon` 이 있고 `false` 면 아이콘만 있는 정사각 칸이 됩니다. |

### 테마

`CoreComponentTheme(filter: CoreFilterTheme(...))` 로 앱 전체 값을 정합니다.

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CoreFilterStyle?` | `null` | 모든 Filter 에 적용합니다. |
| `variantStyles` | `Map<CoreFilterVariant, CoreFilterStyle>?` | `null` | variant 별로 덮어씁니다. `style` 보다 우선합니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreFilterStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | **Deprecated (since 0.173)** — Use toggleGroupStyle — the segments are a composed ToggleGroup now; the value still reaches it until removed. Background fill of the filter container. |
| `selectedColor` | `CoreColor?` | **Deprecated (since 0.173)** — Use toggleGroupStyle — the segments are a composed ToggleGroup now; the value still reaches it until removed. Background fill of the currently selected filter item. |
| `borderRadius` | `CoreBorderRadius?` | **Deprecated (since 0.173)** — Use toggleGroupStyle — the segments are a composed ToggleGroup now; the value still reaches it until removed. Container corner radius. |
| `itemBorderRadius` | `CoreBorderRadius?` | **Deprecated (since 0.173)** — Use toggleGroupStyle — the segments are a composed ToggleGroup now; the value still reaches it until removed. Per-item corner radius. |
| `padding` | `CoreEdgeInsets?` | **Deprecated (since 0.173)** — Use toggleGroupStyle — the segments are a composed ToggleGroup now; the value still reaches it until removed. Padding inside the filter container. |
| `itemPadding` | `CoreEdgeInsets?` | **Deprecated (since 0.173)** — Use toggleGroupStyle — the segments are a composed ToggleGroup now; the value still reaches it until removed. Padding inside each filter item — the segment's own uniform inset around `[icon][label box]`. |
| `labelPadding` | `CoreEdgeInsets?` | **Deprecated (since 0.173)** — Use toggleGroupStyle — the segments are a composed ToggleGroup now; the value still reaches it until removed. Inset of the label box inside a segment (painted only when the item shows its label). |
| `itemHeight` | `double?` | **Deprecated (since 0.173)** — Use toggleGroupStyle — the segments are a composed ToggleGroup now; the value still reaches it until removed. Fixed segment height (logical px); content centres vertically. |
| `itemSpacing` | `double?` | **Deprecated (since 0.173)** — Use toggleGroupStyle — the segments are a composed ToggleGroup now; the value still reaches it until removed. Spacing between filter items (logical px). Maps to native `Row.spacing` on Flutter and CSS flex `gap` on Web. |
| `resetButtonStyle` | `CoreButtonStyle?` | Reset (clear-selection) button style override. |
| `selectedFontWeight` | `int?` | **Deprecated (since 0.173)** — Use toggleGroupStyle — the segments are a composed ToggleGroup now; the value still reaches it until removed. Font weight applied to the currently selected item label (CSS font-weight integer). |
| `transitionDuration` | `Duration?` | **Deprecated (since 0.173)** — Use toggleGroupStyle — the segments are a composed ToggleGroup now; the value still reaches it until removed. Selection-state colour transition duration. |
| `labelTextStyle` | `CoreTextStyle?` | **Deprecated (since 0.173)** — Use toggleGroupStyle — the segments are a composed ToggleGroup now; the value still reaches it until removed. Label text style override applied to every unselected filter item label and the reset icon. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `foregroundColor` field removed). |
| `selectedLabelTextStyle` | `CoreTextStyle?` | **Deprecated (since 0.173)** — Use toggleGroupStyle — the segments are a composed ToggleGroup now; the value still reaches it until removed. Label text style override applied to the currently selected item label. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `selectedForegroundColor` field removed). |
| `iconStyle` | `CoreIconStyle?` | **Deprecated (since 0.173)** — Use toggleGroupStyle — the segments are a composed ToggleGroup now; the value still reaches it until removed. Style for the icon you pass to an unselected segment — size and colour. Handed to the `ToggleGroup` that draws the segments (see [toggleGroupStyle]). |
| `selectedIconStyle` | `CoreIconStyle?` | **Deprecated (since 0.173)** — Use toggleGroupStyle — the segments are a composed ToggleGroup now; the value still reaches it until removed. Style for the icon you pass to the selected segment. Handed to the `ToggleGroup` that draws the segments (see [toggleGroupStyle]). |
| `clickableStyle` | `CoreClickableStyle?` | **Deprecated (since 0.173)** — Use toggleGroupStyle — the segments are a composed ToggleGroup now; the value still reaches it until removed. Style for each item's `Clickable` — press scale, durations, focus ring, disabled opacity. Handed to the `ToggleGroup` that draws the segments (see [toggleGroupStyle]). |
| `toggleGroupStyle` | `CoreToggleGroupStyle?` | Style for the segments, which are a `ToggleGroup`. Laid over [defaultToggleGroupStyle] and the deprecated flat fields (see [toggleGroupStyleFor]), then passed to `ToggleGroup(toggleGroupStyle:)` as is; the group fills the unset fields with its own defaults. |
| `dividerStyle` | `CoreDividerStyle?` | Style of the hairline between the segments and the reset button. Laid over [defaultDividerStyle] and passed to `Divider(dividerStyle:)` as is. |
| `disabledDividerColor` | `CoreColor?` | Colour of the hairline while the filter is disabled. Applied on top of [dividerStyle] only when the filter is disabled; falls back to [defaultDisabledDividerColor]. |
| `dividerHeight` | `double?` | Length of the hairline (logical px). |
| `dividerLeadingSpacing` | `double?` | Distance from the last segment to the hairline (logical px, edge to edge). Counted from the segment, not from the group's own item gap. |
| `trailingSpacing` | `double?` | Spacing between the hairline and the reset button (logical px). |

<!-- STYLE_TABLE:END -->

<Note>

표의 `labelTextStyle` 설명 가운데 초기화 아이콘에 관한 부분은 지금 동작과 다릅니다. 이 필드는 초기화 아이콘에 닿지 않고(아이콘 색은 `resetButtonStyle` 이 정합니다), 선택하지 않은 칸과 선택한 칸의 글자에 모두 적용됩니다. 또 낱개 필드 가운데 채움색(`backgroundColor` · `selectedColor`), 글자 스타일(`labelTextStyle` · `selectedLabelTextStyle`), 아이콘 스타일(`iconStyle` · `selectedIconStyle`)은 비활성일 때 쓰이지 않습니다. 비활성 모양은 `toggleGroupStyle` 의 `disabledBackgroundColor` · `disabledSelectedColor` · `disabledLabelTextStyle` · `disabledIconStyle` 로 바꿉니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="filter/related-toggle-group" title="ToggleGroup">

Filter 의 트랙과 칸을 그리는 부품입니다. 초기화 버튼 없이 값 하나를 고를 때 씁니다.

</Card>
<Card component="radio-group" props="orientation=horizontal;options=2" title="RadioGroup">

폼에서 라디오 입력으로 값 하나를 받습니다.

</Card>
<Card component="tabs" title="Tabs">

보여 줄 내용을 바꾸는 탭 바입니다.

</Card>
<Card demo="filter/related-chip-group" title="ChipGroup">

여러 조건을 함께 고를 때 씁니다.

</Card>
</Cards>
