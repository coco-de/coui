---
title: Chip
description: 태그 · 필터 · 선택 상태를 보여 주는 칩입니다. 눌러서 선택을 바꾸고, 지우기 버튼으로 항목을 없앨 수 있습니다.
category: display
platforms: [flutter, web]
related: [chip-input, chip-group, badge, button]
tags: [interactive, tag, filter, selection]
template: v2
source: display/chip
---

# Chip

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 칩을 확인하고, 만들어진 코드를 복사하세요. 아무 값도 주지 않은 `Chip` 은 `outlined` · `neutral` · `high` · `md` · `rounded` 이고 꺼진 상태입니다.

<Playground component="chip" />

미리보기는 같은 속성의 꺼진 칩(왼쪽)과 켜진 칩(오른쪽)을 나란히 보여 줍니다. `variant` 는 꺼진 칩에서, `직접 지정한 색` 은 켜진 칩에서 차이가 보입니다. `직접 지정한 색` 은 `chipColor: CoreChipColor.custom` 과 `seedColor` 를 함께 넘기며, 씨드 색은 `emphasis: high` 로 켜진 칩에 입혀집니다.

`selected` 는 칩이 스스로 바꾸지 않습니다. 코드의 `isSelected` 처럼 부모가 값을 들고, `onTap` 에서 바꿔 다시 넘기세요. 미리보기의 칩은 마우스를 올리거나 누르면 그 상태를 그리지만 선택은 바뀌지 않습니다.

<Note>

`variant: filled` 와 `emphasis: low` 를 함께 고른 칩이 선택될 수 있으면(`selected` 이거나 `onTap` 이 있으면) 디버그 빌드에서 알려 줍니다. Flutter 는 `FlutterError.reportError` 로, Web 은 브라우저 콘솔 경고로 알립니다. 칩은 그대로 그려집니다.

</Note>

자주 쓰는 모양은 아래와 같습니다. Flutter와 Web 코드가 같습니다.

```dart
// 태그
Chip(label: 'Flutter')

// 지울 수 있는 태그
Chip(label: 'Dart', onRemove: removeDart)

// 선택할 수 있는 칩
Chip(
  label: '디자인',
  selected: isDesignSelected,
  onTap: toggleDesign,
)

// 앞에 아바타를 둔 칩
Chip(
  label: '홍길동',
  leading: Avatar(initials: '홍', size: CoreComponentSize.xs),
  onRemove: removeUser,
)
```

## 구조

칩은 면 하나 안에 앞 위젯, 키 글자, 라벨, 뒤 위젯, 지우기 버튼을 이 순서로 한 줄에 놓습니다. 라벨에 줄 수를 늘리면 라벨만 여러 줄이 됩니다. 값을 주지 않은 부분은 그리지 않고, 놓인 부분 사이에는 같은 간격(`iconLabelGapStyle`)을 둡니다.

<Anatomy demo="chip/anatomy">
<AnatomyItem part="container" name="Container">

채움, 테두리, 모서리. 최소 높이는 크기가 정하고 내용 줄을 가운데에 둡니다.

</AnatomyItem>
<AnatomyItem part="leading" name="leading">

앞 위젯 슬롯. 크기를 따로 주지 않은 아이콘은 칩 크기에 맞는 아이콘 크기를 받습니다.

</AnatomyItem>
<AnatomyItem select=".co-chip-body > span + div + span" side="top" name="prefixLabel">

라벨 앞의 키 글자. 필터 칩이 무엇을 거르는지 적습니다.

</AnatomyItem>
<AnatomyItem select=".co-chip-body > span + div + span + div + span" side="top" name="label">

칩의 글. `child` 를 주면 이 자리를 대신합니다.

</AnatomyItem>
<AnatomyItem select=".co-chip-body > span + div + span + div + span + div + span" side="top" name="trailing">

뒤 위젯 슬롯. 아이콘 크기와 색을 받는 방식은 `leading` 과 같습니다.

</AnatomyItem>
<AnatomyItem select="button[aria-label]" side="right" name="remove button">

`onRemove` 가 있고 `enabled` 일 때만 그립니다. `ghost` 버튼 안에 `x` 아이콘이 있습니다.

</AnatomyItem>
</Anatomy>

| 부분 | 넣는 파라미터 | 바꾸는 스타일 필드 |
| --- | --- | --- |
| 면 | 없음 | `backgroundColor` · `borderColor` · `borderWidth` · `borderRadius` · `padding` · `minHeight` · `contentAlignment` |
| 앞 위젯 | `leading` | `leadingIconStyle` |
| 키 글자 | `prefixLabel` | `prefixLabelStyle` |
| 라벨 | `label` 또는 `child` | `labelStyle` (`child` 는 아래 설명) |
| 뒤 위젯 | `trailing` | `trailingIconStyle` |
| 지우기 버튼 | `onRemove` | `closeButtonStyle` · `closeIconStyle` |
| 부품 사이 간격 | 없음 | `iconLabelGapStyle` |

### 라벨과 내용

<Preview demo="chip/truncation" />

- **`label`** 은 기본으로 한 줄이며 넘치면 말줄임표로 줄입니다. `labelMaxLines` 로 줄 수를 늘리면 칩 높이도 함께 늘어납니다. `labelOverflow` 는 넘친 글의 처리(`clip` · `fade` · `ellipsis` · `visible`)를 고릅니다. Web 은 이 가운데 일부를 똑같이 그립니다(플랫폼 차이 섹션).
- **`maxLength`** 는 `label` 이 이 길이보다 길면 앞부분만 남기고 `...` 을 붙입니다. 길이는 UTF-16 코드 단위로 세므로, 이모지처럼 두 단위를 쓰는 글자는 중간에서 잘릴 수 있습니다.
- **`child`** 를 주면 `label` 대신 그립니다. 이때 `maxLength` · `labelMaxLines` · `labelOverflow` 는 쓰이지 않습니다. `label` 을 함께 주면 화면에는 그리지 않지만 지우기 버튼의 이름에는 들어갑니다.
- **`child` 의 글자색** 은 플랫폼마다 다릅니다. Web 의 `child` 는 칩의 글자색과 라벨 글자 역할을 물려받습니다. `labelStyle` 에 직접 적은 굵기 · 크기는 `child` 로 이어지지 않습니다. Flutter 의 `child` 는 글자색 · 글자 역할 · `labelStyle` 을 받지 않으므로, 켜진 칩처럼 면이 진한 상태에서는 글자색을 직접 지정해야 합니다.

<a id="변형-variants"></a>

## Variant

겉모습을 정하는 속성은 넷이고, 각자 한 가지만 정합니다.

| 속성 | 정하는 것 | 값 (굵게 = 기본) |
| --- | --- | --- |
| `variant` | 꺼진 칩의 모양 | **`outlined`** · `filled` |
| `shape` | 칩의 윤곽 (형태 섹션) | **`rounded`** · `pill` |
| `emphasis` | 켜진 칩의 강조 | `low` · **`high`** |
| `chipColor` | 켜진 칩의 색 | **`neutral`** · `primary` · `custom` |

<a id="꺼진-칩의-모양-variant"></a>

### 꺼진 칩의 모양

<VariantRow name="outlined" component="chip" props="variant=outlined" label="추천">

투명한 채움에 옅은 테두리(`outlineVariant`)입니다. 선택과 필터 묶음에 두루 씁니다. 기본값입니다.

</VariantRow>

<VariantRow name="filled" component="chip" props="variant=filled" label="추천">

회색 채움(`surfaceContainerHigh`)이고, 테두리는 채움과 같은 색이라 보이지 않습니다. 추천 · 바로 실행 칩이나, 흰 화면에 가볍게 놓는 필터 줄에 씁니다.

</VariantRow>

<Preview demo="chip/variants" />

`variant` 는 꺼진 칩의 기본 색만 정합니다. 켜진 칩과 비활성 칩은 `variant` 가 달라도 같은 색으로 그립니다. 다만 `CoreChipTheme.variantStyles` 는 위젯에 넘긴 `variant` 값으로 찾으므로, 거기 적은 스타일은 켜진 칩과 비활성 칩에도 합쳐집니다.

```dart
Chip(
  label: '추천',
  variant: CoreChipVariant.filled,
  selected: isSelected,
  onTap: toggleRecommended,
)
```

<Note>

**`filled` 는 진한 선택(`emphasis: high`)과 씁니다.** 기본 CoUI 라이트 팔레트에서 `filled` 의 꺼진 채움(`surfaceContainerHigh`)과 `low` 로 켜진 채움(`neutral` 은 `surfaceContainerHighest`, `primary` 는 `primaryContainer` — 이 팔레트에서는 같은 색)의 밝기 대비는 약 1.08:1 입니다. 채움만으로는 두 상태를 가리기 어려우므로 `low` 를 쓰려면 `outlined` 를 고르세요. 디버그 빌드는 선택될 수 있는 `filled` + `low` 칩을 알려 줍니다. `ChipInput` 의 칩은 `filled` · `low` 이지만 선택되지 않아 대상이 아닙니다.

</Note>

회색 바탕 위에서는 `filled` 칩이 바탕에 묻힙니다. `surfaceContainer` 이상의 바탕에는 `outlined` 를 쓰세요.

<Preview demo="chip/grey-surface" />

<a id="색-chipcolor"></a>

### 색

`chipColor` 는 칩이 **켜질 때** 입는 색입니다. 꺼진 칩은 어느 값이든 같은 무채색으로 그립니다.

| `chipColor` | 켜진 칩 (`high`) | 켜진 칩 (`low`) |
| --- | --- | --- |
| `neutral` (기본) | `inverseSurface` 채움, `inverseOnSurface` 글자 | `surfaceContainerHighest` 채움, `onSurface` 글자 |
| `primary` | `primary` 채움, `onPrimary` 글자 | `primaryContainer` 채움, `onPrimaryContainer` 글자 |
| `custom` | `seedColor` 채움 | `seedColor` 를 쓰지 않는 중립색 (아래) |

<Preview demo="chip/colors" />

<Note>

기본 CoUI 팔레트의 `primary` 는 무채색입니다. 그래서 라이트 · 다크에서 `neutral` 과 `primary` 의 켜진 칩은 거의 같게 보입니다. 테마의 `primary` 에 브랜드 색을 두면 둘이 갈립니다.

</Note>

```dart
Chip(
  label: '디자인',
  chipColor: CoreChipColor.primary,
  selected: isDesignSelected,
  onTap: toggleDesign,
)
```

`chipColor` 에 넘길 수 있는 값은 `neutral` · `primary` · `custom` 셋입니다. 성공 · 경고처럼 뜻을 담은 상태 색은 [Badge](/components/badge) 를 씁니다. `Chip(...).secondary` · `.tertiary` 같은 체인 getter 는 인스턴스 하나의 배경색 토큰을 고르는 것이고 `CoreChipColor` 의 값이 아닙니다.

#### custom 과 seedColor

`chipColor: CoreChipColor.custom` 과 `seedColor` 를 함께 넘깁니다. `seedColor` 없이 `custom` 만 주면 `neutral` 처럼 그리고, `chipColor` 가 `custom` 이 아니면 `seedColor` 는 쓰이지 않습니다.

```dart
Chip(
  label: '직접 지정',
  chipColor: CoreChipColor.custom,
  seedColor: CoreColor.token(CoreColors.success),
  selected: true,
)
```

- **켜짐 · `high`** — 채움과 테두리가 `seedColor` 입니다. 글자색은 채움의 짝 색을 따릅니다. 짝이 있는 토큰이면 그 on-토큰(`success` → `onSuccess`)을 씁니다. 원시 색이면 흰색과 검은색 가운데 대비가 더 큰 쪽(같으면 흰색)을 쓰고, 짝이 없는 토큰이면 흰색을 씁니다. 다른 글자색은 `customSelectedForegroundColor` 로 지정합니다.
- **켜짐 · `low`** — `seedColor` 를 쓰지 않습니다. 채움은 `surfaceContainer`, 글자는 `onSurface` 입니다. 색을 넣으려면 `customLowSelectedBackgroundColor` · `customLowSelectedForegroundColor` 를 지정합니다.
- **꺼짐** — `neutral` 과 같은 무채색입니다. 임의 색은 바탕 위의 대비를 보장할 수 없기 때문입니다.
- **비활성** — `seedColor` 를 버리고 비활성 색으로 그립니다.

<a id="선택과-강조-selected-emphasis"></a>

### 선택과 강조

`selected` 와 `emphasis` 가 네 가지 모양을 고릅니다. 표는 `outlined` 기준입니다.

| `selected` | `emphasis` | 채움 | 테두리 | 라벨 |
| --- | --- | --- | --- | --- |
| 꺼짐 | `low` | 없음 | `outlineVariant` | `onSurfaceVariant` |
| 꺼짐 | `high` | 없음 | `outlineVariant` | `onSurface` |
| 켜짐 | `low` | 색의 연한 채움 | 채움과 같은 색 | 색 표의 `low` 글자색 |
| 켜짐 | `high` | 색의 진한 채움 | 채움과 같은 색 | 색 표의 `high` 글자색 |

<Preview demo="chip/emphasis" />

기본값에서 꺼진 칩의 `emphasis` 가 바꾸는 것은 글자색의 진하기입니다. 라벨뿐 아니라 색을 따로 정하지 않은 앞뒤 아이콘과 지우기 버튼의 `x` 도 같은 글자색을 씁니다. 키 글자색은 그대로입니다. 기본값이 `neutral` · `high` · `outlined` 이므로, 인자 없이 쓴 칩은 꺼지면 옅은 테두리이고 켜지면 반전 채움입니다.

### 의미 체인

칩의 `.primary`는 `chipColor: .primary`를 선택합니다. 선택 시 사용하는 색이며, `.outline`은 `variant: .outlined`를 선택합니다. `Chip(label: '태그', selected: true).primary.outline`처럼 조합할 수 있습니다.

## 크기

크기는 `CoreChipSize` 의 `sm` · `md` · `lg` 세 단계이고 기본값은 `md` 입니다. Button 이나 Badge 가 쓰는 `CoreComponentSize` 와는 다른 타입이라, 28 보다 작거나 40 보다 큰 단계는 없습니다.

<Preview demo="chip/sizes" />

| `size` | 최소 높이 | 좌우 · 위아래 여백 | 모서리 | 라벨 | 키 글자 | 앞뒤 아이콘 | 부품 간격 | 지우기 버튼 · `x` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `sm` | 28 | 10 · 2 | 6 | `labelSmall` 12 | `labelXs` 11 | 12 | 4 | 16 · 12 |
| `md` | 32 | 12 · 2 | 8 | `labelMedium` 13 | `labelSmall` 12 | 14 | 4 | 18 · 14 |
| `lg` | 40 | 14 · 2 | 10 | `labelLarge` 14 | `labelMedium` 13 | 16 | 6 | 20 · 16 |

- 높이는 최소 높이(`minHeight`)입니다. 내용이 더 크면 칩도 커지며, 위아래 여백 2는 그때 의미가 있습니다.
- 라벨과 키 글자의 굵기는 모든 크기에서 글자 역할의 500 으로, 옆에 놓는 Button 의 라벨과 같은 굵기입니다([타이포그래피](/guides/typography)). 선택해도 굵기가 바뀌지 않아 칩 줄이 다시 흐르지 않습니다.
- 표의 값과 굵기는 기본 서페이스 스타일 · 표준 밀도 기준입니다. 다른 [서페이스 스타일](/guides/surface-styles)이나 밀도(density) 설정은 모서리 같은 값을 옮길 수 있습니다.

## 형태

<a id="둥근-모서리와-알약-shape"></a>

### 둥근 모서리와 알약

`shape` 는 칩의 윤곽만 정합니다. 색 · 크기 · 상태와는 상관없습니다.

<Cards columns="2">
<Card component="chip" props="shape=rounded;selected=true" label="USD" title="rounded">

크기마다 정해진 모서리(6 · 8 · 10)를 씁니다. 태그와 선택 묶음에 씁니다. 기본값입니다.

</Card>
<Card component="chip" props="shape=pill;selected=true" label="USD" title="pill">

모든 크기에서 양 끝이 반원입니다. 필터 · 정렬 · 통화처럼 한 줄로 늘어선 칩에 씁니다.

</Card>
</Cards>

```dart
Chip(
  label: 'USD',
  shape: CoreChipShape.pill,
  selected: isUsdSelected,
  onTap: selectUsd,
)
```

- `pill` 은 특정 반경 값이 아니라 끝까지 둥근 모서리(`radius9999`)입니다. 두 플랫폼 모두 그릴 때 칩 높이의 절반으로 줄이므로(높이 28 · 32 · 40 이면 14 · 16 · 20), 라벨이 여러 줄이 되어 칩이 커져도 양 끝은 반원입니다.
- 지우기 버튼의 모서리는 `shape` 를 따르지 않습니다. `sm` 은 6, `md` · `lg` 는 8 입니다.
- `chipStyle` 이나 `CoreChipTheme` 의 스타일에 `borderRadius` 를 적으면 두 모양 모두 그 값을 씁니다. 이때 `shape` 를 바꿔도 모서리는 달라지지 않습니다.

<a id="필터-칩의-키-글자-prefixlabel"></a>

## 필터 칩의 키 글자

필터 칩은 무엇을 거르는지(키)와 지금 값(라벨)을 한 칩에 보여 줍니다. 키 글자는 `prefixLabel` 로 넘기며, 라벨보다 한 단계 작은 글자 역할로 라벨 앞에 그립니다.

<Preview demo="chip/prefix" />

```dart
Chip(
  variant: CoreChipVariant.filled,
  prefixLabel: '상태',
  label: isFiltered ? '진행 중' : '전체',
  trailing: Icon(LucideIcons.chevronDown),
  selected: isFiltered,
  onTap: openStatusFilter,
)
```

| 상태 | 키 글자 | 라벨 |
| --- | --- | --- |
| 꺼짐 · `high` | `onSurfaceVariant` | `onSurface` |
| 꺼짐 · `low` | `onSurfaceVariant` | `onSurfaceVariant` — 같은 색이라 크기로만 갈립니다 |
| 켜짐 | 라벨과 같은 색 | 색 표의 켜짐 글자색 |
| 비활성 | 라벨과 같은 색 | `disabledContent` |

- 키 글자는 한 줄을 지키며 줄어들지 않습니다. 칩이 좁아지면 라벨이 줄어듭니다. 키 글자보다 좁은 자리에는 맞출 수 없으니 키는 짧게 적습니다.
- 키의 글자 모양과 색은 `prefixLabelStyle` 로 덮습니다. 거기 적은 색은 모든 상태에 적용됩니다. `foregroundColor` 를 적으면 라벨과 함께 키 글자도 그 색이 됩니다.
- `child` 에 `Row` 를 넣어 같은 모양을 만들면 크기별 키 글자 역할과 상태별 키 색을 받지 못합니다.
- 칩은 목록을 열지 않습니다. 값을 고르는 화면은 `onTap` 에서 띄웁니다.

<a id="동작-스펙-behavior"></a>

## 상태

<Preview demo="chip/states" />

| 상태 | 조건 | 모양 |
| --- | --- | --- |
| 기본 | `selected: false` | `variant` 와 `emphasis` 가 정합니다. |
| 선택 | `selected: true` | `chipColor` 와 `emphasis` 가 정합니다. |
| Hover | `onTap` 이 있고 `enabled` | 칩의 글자색을 채움 위에 3% 덮습니다. |
| 키보드 포커스 | 위와 같음 | 글자색을 8% 덮고 포커스 링을 그립니다. |
| Pressed | 위와 같음 | 글자색을 12% 덮습니다. |
| 비활성 · 꺼짐 | `enabled: false` | `surface` 채움, `disabledOutline` 테두리, `disabledContent` 글자 |
| 비활성 · 선택 | `enabled: false`, `selected: true` | `disabledContainer` 채움, 테두리 없음, `disabledContent` 글자 |

- 덮는 비율은 `stateLayer`(기본 `CoreStateLayer.subtle`)가 정합니다. 여러 상태가 겹치면 Pressed, 키보드 포커스, Hover 순으로 하나를 그립니다.
- 누를 때 칩이 0.97 배로 살짝 줄어듭니다. 그림자를 넣는 서페이스 스타일에서는 두 플랫폼이 다릅니다(플랫폼 차이 섹션).
- 비활성 칩은 투명도를 낮추지 않고 전용 색으로 그립니다. 기본값에서는 `variant` 와 `chipColor` 에 따라 달라지지 않습니다. `chipStyle` 의 `backgroundColor` · `foregroundColor` · `borderColor` 는 비활성에서도 그대로 적용됩니다.
- `enabled: false` 면 `onRemove` 를 주어도 지우기 버튼을 그리지 않습니다.
- 누를 수 있는 칩의 커서는 손 모양이고, 비활성이면 금지 모양입니다.
- `onTap` 이 없는 칩은 표시 전용입니다. Hover · 포커스 · Pressed 의 색 변화와 커서를 바꾸지 않습니다.

### 인터랙션

- **칩 누르기** — `onTap` 을 부릅니다. `selected` 를 바꾸는 것은 부모입니다.
- **지우기 버튼** — `onRemove` 를 부릅니다. 목록에서 칩을 없애는 것은 부모입니다.
- **두 콜백을 함께 줄 때** — Flutter 는 지우기 버튼을 누르면 `onRemove` 만 부릅니다. Web 은 지우기 버튼의 누름이 칩까지 전달되어 `onTap` 도 함께 부릅니다.

### 상태 전환

- 선택 모양은 `selected` 파라미터가 정합니다. 칩은 선택 상태를 스스로 기억하거나 뒤집지 않습니다.
- Hover · 포커스 · Pressed 는 칩이 알아서 그리고, 입력이 끝나면 원래 모양으로 돌아옵니다.

### 애니메이션

- 채움과 테두리 색은 `transitionDuration`(기본 `CoreDuration.instant`, 100ms) 동안 바뀝니다. Web 은 글자색도 함께 전환하고, Flutter 의 라벨 색은 바로 바뀝니다.
- 동작 줄이기를 켜면 기본 전환과 그림자 모션은 시간 없이 바뀝니다.
- 칩이 나타나거나 사라지는 애니메이션은 칩에 없습니다. 지울 때의 움직임이 필요하면 목록을 그리는 쪽에서 넣습니다(Flutter 라면 `AnimatedSize` · `AnimatedOpacity` 같은 위젯).

<a id="캐스트-모션-castmotion"></a>

### 그림자 모션

`chipStyle` 의 `castMotion`(`CoreCastMotion`)은 서페이스 스타일이 넣는 그림자를 칩에 마우스를 올리거나 누를 때 어떻게 바꿀지 정합니다.

| 값 | 평소 | 마우스를 올리거나 누를 때 |
| --- | --- | --- |
| `defaultMotion` (기본) | 그림자가 있습니다. | 그림자가 사라지고 칩이 그 자리로 이동합니다. |
| `reverse` | 그림자가 없습니다. | 그림자가 생기고 칩이 반대 방향으로 이동합니다. |
| `noShadow` | 그림자가 없습니다. | 그림자와 위치가 그대로입니다. |

<Preview demo="chip/cast-motion" />

- 그림자의 위치 · 색 · 두께는 [서페이스 스타일](/guides/surface-styles)이 정합니다. 내장 서페이스 스타일 가운데 이 그림자를 넣는 것은 Neo-brutalism 입니다. 위 미리보기가 똑같아 보이면 지금 스타일이 그림자를 넣지 않는 것입니다.
- 마우스처럼 올려 둘 수 있는 입력에서는 hover 가, 터치에서는 누름이 모션을 켭니다. Web 은 `@media (hover: hover)` 로 이 둘을 가릅니다. Flutter 는 hover 와 누름을 모두 받으며, 터치에는 hover 가 없어 누름만 남습니다.
- 그림자가 숨는 시간은 `castHideDuration`(기본 50ms)입니다. Flutter 에서 칩이 이동하는 시간은 이 값이 아니라 `clickableStyle` 의 `pressDuration`(기본 100ms)을 따릅니다.
- 칩은 채움이 있는지 따지지 않고 그림자를 적용합니다. 기본 칩은 1px 테두리가 윤곽이 됩니다. 투명한 칩에 `borderWidth: 0` 을 주면 윤곽 없이 그림자만 보일 수 있습니다. 칩에는 그림자를 직접 지정하는 스타일 필드가 없습니다.
- 표시 전용 칩은 Flutter 에서 모션이 켜지지 않습니다. 그래서 `reverse` 면 그림자가 계속 숨어 있습니다. Web 은 `onTap` 이 없어도 비활성이 아니면 hover 나 누름에 모션이 켜집니다.
- Web 에서 `noShadow` 를 고른 활성 칩에는 칩의 `transitionDuration` 이 적용되지 않습니다. `CoUIWeb` 의 테마 전환 애니메이션이 켜져 있으면 색은 그 애니메이션을 따라 바뀝니다.

```dart
Chip(
  label: '필터',
  chipStyle: CoreChipStyle(castMotion: CoreCastMotion.noShadow),
  onTap: openFilter,
)
```

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 필터 옵션을 켜고 끄게 할 때
- 고른 항목을 지울 수 있는 태그로 보여 줄 때 (예: 메일 받는 사람 목록)
- 여러 개를 고르는 화면에서 고른 항목을 보여 줄 때
- 필터가 무엇을 거르는지와 지금 값을 한 번에 보여 줄 때 (`prefixLabel`)

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 누를 일이 없는 분류 · 상태 · 개수 표시 (한 번 누르는 동작은 `onPressed` 로 가능) | [Badge](/components/badge) |
| 선택하거나 지울 태그가 아니라 동작 하나를 실행하는 컨트롤 | [Button](/components/button) |
| 글을 직접 입력해 칩을 만드는 입력 칸 | [ChipInput](/components/chip-input) |
| 여러 칩의 단일 · 다중 선택과 선택 개수 제한을 관리 | [ChipGroup](/components/chip-group) |

<a id="do"></a>
<a id="dont"></a>

### 라벨 길이

<Cards columns="2">
<Card demo="chip/do-short" tone="do" eyebrow="이렇게 하세요">

라벨은 한두 낱말로 짧게 적습니다. 훑어보고 고르기 쉽습니다.

</Card>
<Card demo="chip/dont-long" tone="dont" eyebrow="이렇게 하지 마세요">

긴 문구는 좁은 자리에서 말줄임되어 끝까지 읽을 수 없습니다.

</Card>
</Cards>

### 색 고르기

<Cards columns="2">
<Card demo="chip/do-chip-color" tone="do" eyebrow="이렇게 하세요">

색은 `chipColor` 로 고릅니다. 채움 · 테두리 · 글자색이 상태에 맞춰 함께 바뀝니다.

</Card>
<Card demo="chip/dont-background" tone="dont" eyebrow="이렇게 하지 마세요">

선택할 수 있는 칩에 `backgroundColor` 만 칠하지 않습니다. 배경은 모든 상태에서 같아지고 글자색은 상태를 따라가므로, 꺼진 칩의 글자가 묻힙니다.

</Card>
</Cards>

### 필터 줄과 지우기

- 흰 화면에 가볍게 놓는 필터 줄은 `filled` + `high` 로, 회색 바탕에서는 `outlined` 로 그립니다.
- 읽기 전용으로 만들 때는 `enabled: false` 만 주어도 지우기 버튼이 숨습니다. 비활성 모양이 필요 없으면 `onRemove` 를 빼면 됩니다.
- Web 에서는 한 칩에 `onTap` 과 `onRemove` 를 함께 주지 않는 편이 안전합니다(상태 · 접근성 섹션).

## 배치

칩은 내용만큼의 너비를 차지합니다. 부모가 너비를 제한하면 라벨이 줄어듭니다. Flutter의 `Row` 처럼 자식에게 너비를 제한하지 않는 부모에서는 `Flexible(child: Chip(...))` 처럼 쓸 수 있는 너비를 넘겨야 말줄임이 됩니다. 칩을 내용보다 넓게 그리면 내용 줄은 가운데에 놓이며, `chipStyle` 의 `contentAlignment` 로 바꿉니다.

### 칩 그룹

`Chip` 에는 여러 칩을 배치하는 기능이 없습니다. Flutter는 `Wrap`, Web은 flex `div` 로 늘어놓습니다. 선택 상태까지 묶어 관리하려면 [ChipGroup](/components/chip-group) 을 씁니다.

<Preview demo="chip/group" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Wrap(
  spacing: CoreSpace.space8,
  runSpacing: CoreSpace.space8,
  children: [
    for (final tag in tags) Chip(label: tag, onRemove: () => removeTag(tag)),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(
  classes: 'flex flex-wrap gap-${CoreSpace.scale.space8}',
  [
    for (final tag in tags) Chip(label: tag, onRemove: () => removeTag(tag)),
  ],
)
```

  </TabItem>
</Tabs>

여러 개를 켜고 끄는 필터 묶음은 아래처럼 만듭니다. 두 플랫폼의 코드가 같습니다. `ChipGroup` 이 고른 값을 들고, 바뀔 때마다 `onChanged` 로 알려 줍니다.

```dart
ChipGroup<String>(
  items: categories,
  selectionMode: CoreChipGroupSelectionMode.multi,
  onChanged: updateCategories,
  chipBuilder: (category, {required selected, required enabled, required onTap}) =>
      Chip(
        label: category,
        chipColor: CoreChipColor.primary,
        selected: selected,
        enabled: enabled,
        onTap: onTap,
      ),
)
```

<a id="조합-예제"></a>

### 입력과 함께 쓰기

태그를 직접 입력받는 화면에는 [ChipInput](/components/chip-input) 을 씁니다. ChipInput 은 `chips` 목록을 `Chip` 으로 직접 그리므로, 칩 줄을 따로 만들 필요가 없습니다.

```dart
ChipInput(
  chips: tags,
  placeholder: '태그 추가',
  onSubmitted: addTag,
  onChanged: replaceTags,
)
```

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

색 · 크기 · 간격처럼 보이는 값과 안쪽 부품의 스타일은 `chipStyle`(`CoreChipStyle`) 하나로 바꿉니다.

<a id="시맨틱-vs-스타일"></a>

### 파라미터와 스타일

- **종류 · 상태 · 내용 · 동작** — 위젯 파라미터로 직접 넘깁니다: `chipColor`, `variant`, `emphasis`, `size`, `shape`, `selected`, `enabled`, `prefixLabel`, `label`, `labelMaxLines`, `labelOverflow`, `maxLength`, `child`, `leading`, `trailing`, `seedColor`, `onTap`, `onRemove`.
- **겉모습** — `chipStyle` 로 넘깁니다. 안쪽 부품은 `labelStyle` · `prefixLabelStyle` · `leadingIconStyle` · `trailingIconStyle` · `closeIconStyle` · `closeButtonStyle` · `clickableStyle` · `iconLabelGapStyle` 로 바꿉니다.
- **지우기 버튼** — 버튼 위젯을 바꿔 끼우는 파라미터는 없습니다. 칩이 `ghost` Button 을 그리며, 겉모습은 `closeButtonStyle` 로, `x` 아이콘은 `closeIconStyle` 로 바꿉니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

<Preview demo="chip/theme-order" />

```text
CoreChipStyle.defaultsBySize[size] → CoreChipStyle.defaultsByShape[shape]   // 디자인 시스템 기본값
  → CoreChipTheme.style                    // 프로젝트 공통
  → CoreChipTheme.colorStyles[chipColor]   // 색별
  → CoreChipTheme.variantStyles[variant]   // variant 별
  → chipStyle                              // 인스턴스별
```

- 뒤에 적은 값이 앞의 값을 이깁니다. 안쪽 부품의 스타일은 통째로 바뀌지 않고 필드끼리 합쳐진 뒤, 그 부품 자신의 기본값 위에 적용됩니다.
- 색은 상태에 따라 고릅니다. 합친 스타일에 `backgroundColor` · `foregroundColor` · `borderColor` 가 없으면 `CoreChipStyle.defaultsByColor`(또는 `seedColor`)의 상태별 색을 씁니다. 이 세 필드를 적으면 켜짐 · 꺼짐 · 비활성 모든 상태에서 그 색이 됩니다.
- `colorStyles` 와 `variantStyles` 는 상태가 아니라 위젯에 넘긴 `chipColor` · `variant` 값으로 찾습니다. `colorStyles` 의 `primary` 에 배경색을 적으면 꺼진 `primary` 칩에도 적용됩니다.
- 한 상태만 바꾸려면 `filledUnselectedBackgroundColor`, `lowUnselectedForegroundColor`, `lowUnselectedBorderColor`, `disabledSelectedBorderColor`, `custom` 으로 시작하는 필드처럼 상태가 이름에 있는 필드를 씁니다.
- `ChipInput` 이 안에 그리는 칩은 ChipInput 의 칩 기본값에 `chipInputStyle` 의 `chipStyle` 을 덮은 값이 `chipStyle` 자리로 들어옵니다.

<a id="사용-예-flutter"></a>
<a id="사용-예-web"></a>

### 사용 예

<Split>

<Code language="dart" title="칩 하나만 바꾸기">
Chip(
  label: '선택됨',
  chipColor: CoreChipColor.primary,
  selected: true,
  onRemove: removeChip,
  chipStyle: CoreChipStyle(
    padding: CoreEdgeInsets.symmetric(
      horizontal: CoreSpace.space12,
      vertical: CoreSpace.space6,
    ),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
    closeIconStyle: CoreIconStyle(size: CoreIconSize.size12),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    chip: CoreChipTheme(
      style: CoreChipStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
      ),
      variantStyles: {
        CoreChipVariant.filled: CoreChipStyle(
          filledUnselectedBackgroundColor:
              CoreColor.token(CoreColors.surfaceContainer),
        ),
      },
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다. 앱 전체 예제는 모든 칩의 모서리를 알약으로 만들고, `filled` 칩의 꺼진 채움을 바꿉니다.

<a id="테두리-없는-마케팅-크롬"></a>

### 테두리 없는 마케팅용 모양

기본 칩은 크기마다 정해진 모서리(`sm` 6 · `md` 8 · `lg` 10)와 1px 테두리를 그립니다. 알약이 필요하면 모서리를 적지 말고 `shape: CoreChipShape.pill` 을 씁니다. 포커스 링은 어느 쪽이든 칩의 모서리를 따릅니다.

<Preview demo="chip/borderless" />

```dart
Chip(
  label: '베타',
  chipStyle: const CoreChipStyle(
    borderWidth: CoreStrokeWidth.stroke0,
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
  ),
)
```

- `borderWidth: CoreStrokeWidth.stroke0` 은 두 플랫폼 모두 선을 그리지 않습니다.
- 이 스타일은 선택하지 않는 칩에만 쓰세요. `backgroundColor` 는 켜진 상태에도 적용되는데, 켜진 글자색은 그대로라 읽기 어려워집니다. 테두리 없는 회색 선택 칩은 `variant: CoreChipVariant.filled` 로 만듭니다.
- Web 은 모서리를 늘 인라인 스타일로 씁니다. `borderWidth` 를 적으면 선 굵기도 인라인이 됩니다. 제품 CSS 로 이 값을 덮으려면 `!important` 가 필요하므로, `chipStyle` 로 직접 바꾸는 편이 낫습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Chip` 에 `withStyle` 을 이어 `chipStyle` 을 덧붙일 수 있습니다. 같은 필드는 나중에 이은 값이 이깁니다. `.radius16`은 모서리 반경을, `.backgroundColor(.primary)`는 배경색을 지정합니다.

- 명시적 배경색은 모든 상태에 적용되고 글자색은 상태를 따라갑니다. 아래 예제의 첫 칩은 꺼져 있는 동안 `primary` 배경 위에 `onSurface` 글자가 놓여, 기본 CoUI 팔레트의 라이트 · 다크 모두에서 글자가 거의 보이지 않습니다. 선택할 수 있는 칩의 색은 `chipColor` 로 고르세요.
- Web 의 `withStyle` 과 getter 는 `classes` · `css` · `attributes` · `eventHandlers` 를 보존합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ChipChainExample extends StatefulWidget {
  const ChipChainExample({super.key});

  @override
  State<ChipChainExample> createState() => _ChipChainExampleState();
}

class _ChipChainExampleState extends State<ChipChainExample> {
  bool _comboSelected = false;
  bool _fullSelected = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Chip(
          label: '디자인',
          selected: _comboSelected,
          onTap: () => setState(() => _comboSelected = !_comboSelected),
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Chip(
          label: '직접 지정',
          selected: _fullSelected,
          onTap: () => setState(() => _fullSelected = !_fullSelected),
        ).withStyle(
          const CoreChipStyle(
            backgroundColor: .tertiaryContainer,
            foregroundColor: .onTertiaryContainer,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space12,
              vertical: CoreSpace.space4,
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
class ChipChainExample extends StatefulComponent {
  const ChipChainExample({super.key});

  @override
  State<ChipChainExample> createState() => _ChipChainExampleState();
}

class _ChipChainExampleState extends State<ChipChainExample> {
  bool _comboSelected = false;
  bool _fullSelected = false;

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Chip(
          label: '디자인',
          selected: _comboSelected,
          onTap: () => setState(() => _comboSelected = !_comboSelected),
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Chip(
          label: '직접 지정',
          selected: _fullSelected,
          onTap: () => setState(() => _fullSelected = !_fullSelected),
        ).withStyle(
          const CoreChipStyle(
            backgroundColor: .tertiaryContainer,
            foregroundColor: .onTertiaryContainer,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space12,
              vertical: CoreSpace.space4,
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

`onTap` 이 있는 칩은 버튼으로, 없는 칩은 글로 표시됩니다. 선택 여부는 두 플랫폼 모두 보조 기술에 전달하지 않습니다.

### 역할

| 대상 | Flutter | Web |
| --- | --- | --- |
| 누를 수 있는 칩 (`onTap`) | `Semantics(button: true, enabled: …)` | 바깥 `<div>` 에 `role="button"` |
| 표시 전용 칩 | 칩이 붙이는 `Semantics` 가 없습니다. | role 없는 `<div>` |
| 지우기 버튼 | 이름을 붙인 `Semantics(button: true, label: …)` 와 `ghost` Button | `<button type="button">` 에 `aria-label` |

`selected` 는 어느 쪽에도 실리지 않습니다. `aria-pressed` · `aria-selected` 도, Flutter 의 `selected:` 도 붙이지 않습니다.

### 키보드

| 키 | Flutter | Web |
| --- | --- | --- |
| `Tab` | 누를 수 있는 칩과 지우기 버튼이 각각 탭 순서의 한 자리입니다. | 같습니다. |
| `Enter` · `Space` (칩) | `onTap` 을 부릅니다. | `onTap` 을 부릅니다. |
| `Enter` · `Space` (지우기 버튼) | `onRemove` 를 부릅니다. | `onRemove` 를 부르고, `onTap` 이 있으면 그것도 부릅니다. |
| `Delete` · `Backspace` | 처리하지 않습니다. | 처리하지 않습니다. |

칩에 포커스를 둔 채 지우는 키는 없습니다. 지우려면 지우기 버튼으로 이동해야 합니다. 표시 전용 칩은 지우기 버튼만 탭 순서에 있습니다. 비활성 칩은 Web 에서 `tabindex` 가 없고, Flutter 에서는 기본 탐색 방식일 때 포커스를 받지 않습니다.

### 스크린 리더

- **칩의 내용** — 칩은 이름을 따로 붙이지 않습니다. 이름이 될 내용은 안에 그린 글이며, `prefixLabel` 이 라벨 앞에 놓입니다.
- **잘린 라벨** — `maxLength` 로 자른 칩의 글은 잘린 문자열과 `...` 입니다. 지우기 버튼의 이름에는 자르기 전의 `label` 전체가 들어갑니다.
- **지우기 버튼의 이름** — 아이콘만 있는 버튼이라 칩이 이름을 붙입니다. `prefixLabel` 과 `label` 을 이은 말을 현재 로케일의 `chipRemoveLabel` 에 넣습니다(영어 `Remove {label}`, 한국어 `{label} 제거`). 로케일 문구를 찾지 못하면 영어를 씁니다. 칩마다 글이 다르면 버튼 이름도 서로 갈립니다.
- **비활성** — 누를 수 있는 칩은 Web `aria-disabled="true"`, Flutter `Semantics(enabled: false)` 로 알립니다. 표시 전용 비활성 칩은 Web 에만 `aria-disabled` 가 남고 Flutter 에는 표시가 없습니다.
- **알림** — 칩이 선택되거나 지워진 것을 알리는 라이브 영역은 두 플랫폼 모두 없습니다.

#### 선택 상태 알리기

선택할 수 있는 칩은 상태를 직접 실어 주세요.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Semantics(
  selected: isDesignSelected,
  child: Chip(
    label: '디자인',
    selected: isDesignSelected,
    onTap: toggleDesign,
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
Chip(
  label: '디자인',
  selected: isDesignSelected,
  onTap: toggleDesign,
  attributes: {'aria-pressed': '$isDesignSelected'},
)
```

  </TabItem>
</Tabs>

Web 의 `attributes` 는 누를 수 있는 칩의 `role="button"` 요소에 붙습니다. 두 방법 모두 대상 기기의 보조 기술에서 어떻게 읽히는지 확인하세요.

### 포커스 관리

- 칩에는 `autofocus` 나 `focusNode` 파라미터가 없습니다. 화면에 나타날 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다.
- 지우기 버튼으로 칩을 지우면 포커스가 있던 버튼도 함께 사라집니다. 칩은 다음 칩이나 목록으로 포커스를 옮기지 않으므로, 필요하면 목록을 관리하는 쪽에서 옮깁니다.
- 포커스 링은 키보드 포커스일 때 보이고 칩의 모서리를 따릅니다. Flutter 는 포커스 강조가 켜지는 입력에서, Web 은 `:focus-visible` 일 때 그립니다.
- 지우기 버튼은 칩의 채움 위에 놓이므로, 버튼의 링과 버튼 사이 2px 간격을 `surface` 색 띠로 칠합니다(`CoreChipStyle.defaultCloseButtonStyle`).

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 선택 상태를 보조 기술에 전달하지 않습니다. 위의 방법으로 직접 실어 주세요. |
| Web | `onTap` 과 `onRemove` 를 함께 준 칩은 지우기 버튼을 눌러도 `onTap` 이 실행됩니다. 마우스와 키보드가 같습니다. |
| Web | `onTap` 과 `onRemove` 를 함께 준 칩은 `role="button"` 요소 안에 `<button>` 이 들어가는 구조입니다. 버튼 안에 버튼이 놓이므로, 대상 보조 기술에서 둘이 따로 읽히고 눌리는지 확인하세요. |
| 공통 | 지우기 버튼의 이름은 `prefixLabel` 과 `label` 에서만 만듭니다. `child` 만 준 칩은 항목 이름이 빠지므로 `label` 도 함께 주세요. |
| 공통 | 누를 수 있는 칩의 지우기 버튼은 그린 크기(기본 16 · 18 · 20)가 곧 누르는 영역입니다. 칩 전체에 이미 24 하한(`CoreTouchTarget.minimum`)이 있어 안쪽 버튼은 따로 넓히지 않습니다. 표시 전용 칩의 지우기 버튼은 누르는 영역을 24 까지 넓힙니다. |
| 공통 | `filled` + `low` 는 꺼진 채움과 켜진 채움의 차이가 작습니다(Variant 섹션). |
| 공통 | 선택을 알리는 체크 아이콘 같은 모양 표시가 없습니다. 상태는 채움 · 글자 · 테두리 색으로 나뉩니다. 색에 기대기 어렵다면 `leading` 에 체크 아이콘을 두는 식으로 모양 차이를 함께 주세요. |

누를 수 있는 칩의 24 하한은 그리는 크기를 그대로 두고 누르는 영역만 넓힙니다. Flutter 는 `TouchTarget`, Web 은 `coui-touch-target` 클래스를 씁니다. 기본 크기의 칩은 높이가 28 이상이라 높이는 넓어질 것이 없고, 여백이나 `minHeight` 를 줄여 24 보다 작게 그린 방향만 넓어집니다. Flutter 에서는 부모가 누름 위치를 넘겨 주는 범위 안에서만 넓어집니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

생성자의 칩 파라미터 이름과 기본값은 두 플랫폼이 같습니다. 다른 점은 아래와 같습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 슬롯 · 콜백 타입 | `Widget?` · `VoidCallback?` | `Component?` · `CoreVoidCallback?` |
| 생성자 | `const` 로 만들 수 있습니다. | `const` 생성자가 아닙니다. |
| `child` 의 글자 | 칩의 글자색 · 글자 역할을 받지 않습니다. | 물려받습니다. |
| `labelOverflow` | 고른 값을 Flutter 의 `TextOverflow` 로 넘깁니다. | 줄 수 제한 CSS 로 그립니다. `clip` · `fade` · `visible` 은 같은 CSS 가 되며, `visible` 이어도 넘친 글을 숨깁니다. |
| 지우기 버튼과 `onTap` | `onRemove` 만 실행합니다. | `onTap` 도 함께 실행합니다. |
| 키보드로 누를 때의 Pressed 색 | 잠깐 덮습니다. | 줄어드는 효과만 보이고 Pressed 색은 덮지 않습니다. |
| 색 전환 | 면과 테두리를 전환하고 라벨 색은 바로 바뀝니다. | 면 · 테두리 · 글자색을 전환합니다. |
| 그림자를 넣는 서페이스 스타일에서 누를 때 (`noShadow` 가 아닌 칩) | 줄어들지 않고 위치만 옮깁니다. | 이동과 함께 0.97 배로 줄어듭니다. |
| 그림자 이동 시간 | `clickableStyle` 의 `pressDuration` | `castHideDuration` |
| 표시 전용 칩의 그림자 모션 | 켜지지 않습니다. | 비활성이 아니면 켜집니다. |
| 그룹 배치 | `Wrap` | flex `div` |
| 크기 배율 | 여백 · 최소 높이 · 모서리 · 아이콘 크기에 `theme.scaling`(기본 `1`)을 곱합니다. 앞뒤 슬롯에 크기를 따로 주지 않은 `Icon` 은 칩이 넘긴 크기에 한 번 더 곱하므로, `1` 이 아닌 값에서는 두 번 곱해집니다. | 여백은 간격 토큰 변수(`--coui-space-*`)로, 최소 높이는 `rem` 으로 씁니다. |
| `filled` + `low` 알림 | `FlutterError.reportError` (디버그 빌드) | `console.warn` (디버그 빌드, 서버 렌더에서는 출력 없음) |
| HTML 속성 | 없음 | 아래 설명 참고 |

Web 의 `id` 와 `attributes` 는 누를 수 있는 칩이면 바깥 `role="button"` 요소에, 표시 전용 칩이면 칩 `<div>` 에 붙습니다. `classes` 와 `css` 는 두 경우 모두 칩 `<div>` 에 붙습니다. `eventHandlers` 는 표시 전용 칩에만 연결되고, 누를 수 있는 칩에는 연결되지 않습니다.

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. 표의 `W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다.

### 종류와 상태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `chipColor` | `CoreChipColor` | `neutral` | 켜진 칩의 색 — `neutral` · `primary` · `custom` |
| `variant` | `CoreChipVariant` | `outlined` | 꺼진 칩의 모양 — `outlined` · `filled` |
| `emphasis` | `CoreChipEmphasis` | `high` | 강조 — `low` · `high`. 기본값에서 꺼진 칩은 글자색의 진하기만 달라집니다. |
| `size` | `CoreChipSize` | `md` | 크기 — `sm` · `md` · `lg` |
| `shape` | `CoreChipShape` | `rounded` | 윤곽 — `rounded` · `pill` |
| `selected` | `bool` | `false` | 선택 여부. 칩이 스스로 바꾸지 않습니다. |
| `enabled` | `bool` | `true` | `false` 면 비활성 색으로 그리고, 누를 수 없으며 지우기 버튼을 숨깁니다. |

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `prefixLabel` | `String?` | `null` | 라벨 앞의 키 글자 |
| `label` | `String?` | `null` | 칩의 글. 지우기 버튼의 이름에도 쓰입니다. |
| `labelMaxLines` | `int?` | `null` | 라벨의 최대 줄 수. `null` 은 한 줄입니다. |
| `labelOverflow` | `CoreTextOverflow?` | `null` | 넘친 라벨의 처리. `null` 은 `ellipsis` 입니다. |
| `maxLength` | `int?` | `null` | 라벨을 이 길이(UTF-16 코드 단위)에서 자르고 `...` 을 붙입니다. 0 이상의 값을 줍니다. |
| `child` | `W?` | `null` | 라벨 대신 그리는 내용 |
| `leading` | `W?` | `null` | 라벨 앞의 위젯 |
| `trailing` | `W?` | `null` | 라벨 뒤의 위젯 |

### 동작

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `onTap` | `VoidCallback?` (Flutter) · `CoreVoidCallback?` (Web) | `null` | 칩을 누르면 부릅니다. `null` 이면 표시 전용 칩입니다. |
| `onRemove` | `VoidCallback?` (Flutter) · `CoreVoidCallback?` (Web) | `null` | 값을 주면 지우기 버튼을 그립니다. 비활성일 때는 그리지 않습니다. |

### 스타일

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `chipStyle` | `CoreChipStyle?` | `null` | 보이는 값 덮어쓰기 |
| `seedColor` | `CoreColor?` | `null` | `chipColor: custom` 의 색 |

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` · `classes` · `css` | `String?` · `String?` · `Styles?` | `null` | 칩의 id 와 배치용 클래스 · 스타일. 붙는 위치는 플랫폼 차이 섹션에 있습니다. |
| `attributes` | `Map<String, String>?` | `null` | HTML 속성 — `aria-pressed`, `data-*`, 테스트 id |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | DOM 이벤트. `onTap` 이 없는 칩에만 연결됩니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreChipStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Panel background fill colour override — wins across every state. `null` defers to the state-keyed [defaultsByColor] base; see the note above for why there is no `default*`. |
| `foregroundColor` | `CoreColor?` | Foreground (label) colour override — wins across every state, and is also the fallback the label / key / leading / trailing / close slots inherit when they carry no colour of their own. `null` defers to the state-keyed [defaultsByColor] base; see the note above. |
| `borderColor` | `CoreColor?` | Border stroke colour. |
| `borderWidth` | `double?` | Border stroke width (logical px). |
| `borderRadius` | `CoreBorderRadius?` | Border radius. `null` defers to the shape's corner ([defaultsByShape] — the full corner for `CoreChipShape.pill`), and for `CoreChipShape.rounded` to the size row's, `CoreChipStyle.defaultsBySize[size]!.borderRadius` — 6 · 8 · 10, the chip's height × 0.25 on a `CoreRadius` rung. A value here wins over both shapes. It is also the corner the focus ring follows. |
| `padding` | `CoreEdgeInsets?` | Padding. |
| `minHeight` | `double?` | Minimum chip height (logical px). Per-size default from [defaultsBySize] — the spec's height ladder, stated as a floor so the chip matches the control tier beside it rather than its own label. |
| `contentAlignment` | `CoreMainAxisAlignment?` | Where the content row (leading · key · label · trailing · close) sits along the chip's main axis when the chip is drawn wider than its content — a caller's fixed or stretched width. A chip that hugs its content has no free space, so the value changes nothing there. `null` defers to [defaultContentAlignment]. |
| `iconLabelGapStyle` | `CoreGapStyle?` | Gap between the parts of the content row — leading, key, label, trailing and close button. `null` uses the size row's gap, `CoreChipStyle.defaultsBySize[size]!.iconLabelGapStyle!`. |
| `closeIconStyle` | `CoreIconStyle?` | Style of the X icon inside the `onRemove` close button, passed to `Icon(iconStyle: …)` as is. Separate from [leadingIconStyle] / [trailingIconStyle], which style the leading / trailing content slots. |
| `transitionDuration` | `Duration?` | Transition duration for hover / focus / state colour changes. When null falls back to [defaultTransitionDuration]. |
| `castHideDuration` | `Duration?` | The engage-squash pair's shared clock — how long the shadow takes to hide and the chip takes to travel into the space it vacated. `null` defers to [defaultCastHideDuration]. Reduced-motion collapses this to zero on both platforms — state (the hide, the travel) is unaffected. |
| `labelStyle` | `CoreTextStyle?` | Label text style override. |
| `prefixLabelStyle` | `CoreTextStyle?` | Text style of the key drawn in front of the label (the widget's `prefixLabel`). `null` uses the size row's role, `CoreChipStyle.defaultsBySize[size]!.prefixLabelStyle`, over [defaultPrefixLabelStyle]. A colour set here wins over the key colour for the chip's current state and over [foregroundColor], the way a [labelStyle] colour does for the label. |
| `leadingIconStyle` | `CoreIconStyle?` | Leading icon style override. |
| `trailingIconStyle` | `CoreIconStyle?` | Trailing icon style override (does **not** affect the close button — [closeButtonStyle] does). |
| `closeButtonStyle` | `CoreButtonStyle?` | Style for the close (`onRemove`) button — its padding, corners and colours. Each close button is a `Button(variant: ghost)` inside; the X icon in it takes [closeIconStyle]. |
| `clickableStyle` | `CoreClickableStyle?` | Style for the `Clickable` around a tappable chip (`onTap != null`) — press scale, durations, focus ring, disabled opacity. Laid over [defaultClickableStyle] and passed to the `Clickable` as is; the `Clickable` fills in the rest. |
| `customDisabledBackgroundColor` | `CoreColor?` | Disabled custom-seed chip background override. `null` → [defaultCustomDisabledBackgroundColor]. |
| `customDisabledUnselectedBackgroundColor` | `CoreColor?` | Background of a **disabled, unselected** custom-seed chip — the surface behind a hairline, the row that keeps a never-selected chip from reading as a selected one. `null` → [defaultCustomDisabledUnselectedBackgroundColor]. |
| `customDisabledForegroundColor` | `CoreColor?` | Disabled custom-seed chip foreground override. `null` → [defaultCustomDisabledForegroundColor]. |
| `customDisabledBorderColor` | `CoreColor?` | Disabled custom-seed chip border override. `null` → [defaultCustomDisabledBorderColor]. |
| `customSelectedForegroundColor` | `CoreColor?` | Selected-state custom-seed chip label colour override. `null` → the seed's own on-colour, per [defaultCustomSelectedForegroundColorFor]. |
| `lowUnselectedForegroundColor` | `CoreColor?` | Label colour override for an unselected chip at [CoreChipEmphasis.low]; `null` → [CoreChipColorStyle.lowUnselectedFg] from [defaultsByColor] — the neutral row for [CoreChipColor.custom]. |
| `lowUnselectedBorderColor` | `CoreColor?` | Border colour override for an unselected chip at [CoreChipEmphasis.low]; falls back to [defaultLowUnselectedBorderColor]. |
| `filledUnselectedBackgroundColor` | `CoreColor?` | Fill override for an unselected, enabled chip at [CoreChipVariant.filled]; `null` → [defaultFilledUnselectedBackgroundColor]. The border follows it. |
| `disabledSelectedBorderColor` | `CoreColor?` | Border colour override for a **selected disabled** chip (any colour, custom seed included); falls back to [defaultDisabledSelectedBorderColor] — none. |
| `customLowSelectedBackgroundColor` | `CoreColor?` | Fill override for a selected custom-seed chip at [CoreChipEmphasis.low] — the tint a raw seed cannot derive on its own; falls back to [defaultCustomLowSelectedBackgroundColor]. |
| `customLowSelectedForegroundColor` | `CoreColor?` | Label override for a selected custom-seed chip at [CoreChipEmphasis.low]; falls back to [defaultCustomLowSelectedForegroundColor]. |
| `stateLayer` | `CoreStateLayer?` | Ramp laid over the chip's own fill while hovered, focused or pressed. Defaults to [defaultStateLayer]. |
| `castMotion` | `CoreCastMotion?` | What this chip's cast does when the chip is engaged. |

### `CoreChipStyle` 색별 기본값 (`CoreChipColorStyle`)

| 필드 | `neutral` | `primary` |
|------|------|------|
| `lowUnselectedFg` | onSurfaceVariant | onSurfaceVariant |
| `disabledSelectedBg` | disabledContainer | disabledContainer |
| `selectedBg` | inverseSurface | primary |
| `selectedFg` | inverseOnSurface | onPrimary |
| `lowSelectedBg` | surfaceContainerHighest | primaryContainer |
| `lowSelectedFg` | onSurface | onPrimaryContainer |
| `unselectedBg` | transparent | transparent |
| `unselectedFg` | onSurface | onSurface |
| `unselectedPrefixFg` | onSurfaceVariant | onSurfaceVariant |
| `borderColor` | outlineVariant | outlineVariant |
| `disabledBg` | surface | surface |
| `disabledFg` | disabledContent | disabledContent |
| `disabledBorderColor` | disabledOutline | disabledOutline |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 설명에 덧붙입니다. `castHideDuration` 은 Web 에서는 그림자와 칩 이동에 함께 쓰이지만, Flutter 에서는 그림자를 숨기는 시간만 바꾸고 칩 이동은 `clickableStyle` 의 `pressDuration` 을 따릅니다. `customSelectedForegroundColor` 는 `emphasis: high` 로 켜진 `custom` 칩에만 쓰이며, `low` 에는 `customLowSelectedForegroundColor` 를 씁니다. 색별 기본값 표에는 `custom` 열이 없습니다 — 꺼진 `custom` 칩은 `neutral` 열을 쓰고, `seedColor` 없는 `custom` 칩도 `neutral` 열을 씁니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="chip/related-chip-input" title="ChipInput">

글을 입력해 칩을 만들고 지우는 입력 칸입니다.

</Card>
<Card demo="chip/related-chip-group" title="ChipGroup">

여러 칩의 선택을 묶어 관리합니다.

</Card>
<Card demo="chip/related-badge" title="Badge">

누를 일이 없는 상태 · 개수 · 분류를 짧게 표시합니다.

</Card>
<Card demo="chip/related-button" title="Button">

선택이 아니라 동작 하나를 실행할 때 씁니다.

</Card>
</Cards>
