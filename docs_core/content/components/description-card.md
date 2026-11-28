---
title: DescriptionCard
description: 라벨과 값을 짝지어 카드 하나에 정리해 보여 줍니다. 주문 상세 · 프로필 · 관리 기록처럼 사실을 한곳에 모아 읽을 때 씁니다.
category: display
platforms: [flutter, web]
related: [card, stat, table, definition-list]
tags: [metadata, information, dashboard, profile, detail]
template: v2
source: display/description_card
---

# DescriptionCard

<a id="live-preview"></a>

## 플레이그라운드

속성을 바꿔 보며 카드를 확인하고, 만들어진 코드를 복사하세요. `rows` 만 넘긴 `DescriptionCard` 는 `outlined` · `md` · `horizontal` 이고 제목이 없습니다. `요청 사항` 행에는 값이 없어 처음에는 보이지 않고, 빈 값 자리 표시를 켜면 나타납니다. 코드의 `showDetails` 는 앱에서 만드는 함수 이름입니다.

<Playground component="description-card" />

## 구조

바탕 상자 하나 안에 제목 줄, 행 목록, 하단 액션이 위에서 아래로 놓입니다. 필수 값은 행 목록 `rows` 하나이고, 나머지 부분은 해당 값을 넘길 때만 그립니다.

<Anatomy demo="description-card/anatomy">
<AnatomyItem part="container" name="Container">

바탕, 테두리, 모서리, 안쪽 여백. 어떤 모양인지는 `variant` 와 `size` 가 정합니다.

</AnatomyItem>
<AnatomyItem part="leading" side="top" name="titleLeading">

제목 앞 슬롯. 크기나 색을 따로 적지 않은 `Icon` 은 크기 단계의 아이콘 크기와 `onSurfaceVariant` 색을 받습니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="title">

카드 제목 글. 모든 크기에서 SemiBold 입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=title-trailing]" side="top" name="titleTrailing">

제목 줄 끝에 놓는 슬롯. 상태 배지 같은 짧은 표시를 둡니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=row-leading]" side="left" name="row leading">

`DescriptionRow.leading`. 라벨 앞에 놓습니다.

</AnatomyItem>
<AnatomyItem select="div:has(> [data-docs-part=row-leading])" side="right" name="row">

행 하나. `DescriptionRow` 의 `label` 과 `value`(또는 `valueWidget`)가 짝을 이룹니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=row-trailing]" side="right" name="row trailing">

`DescriptionRow.trailing`. 값 뒤에 놓습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=bottom-action]" side="left" name="bottomAction">

카드 아래쪽의 액션 영역. 버튼처럼 이 카드의 내용에 이어지는 동작을 둡니다.

</AnatomyItem>
</Anatomy>

제목 아래, 행 사이, 하단 액션 위의 선은 1px `Divider` 이고 색은 기본 `outlineVariant` 입니다.

## Variant

`variant` 는 바탕과 테두리를 고릅니다. 기본값은 `outlined` 입니다.

<Preview demo="description-card/variants" />

| variant | 바탕과 테두리 | 좌우 안쪽 여백 |
| --- | --- | --- |
| `outlined` (기본) | `surface` 바탕과 1px `outlineVariant` 테두리 | 있음 |
| `filled` | `surfaceContainer` 바탕, 테두리 없음 | 있음 |
| `ghost` | 바탕과 테두리 없음 | 없음 |

`ghost` 는 상자 경계가 보이지 않아 좌우 안쪽 여백까지 뺍니다. 위아래 여백은 남고, 내용은 카드를 담은 자리와 같은 선에 맞춰집니다. `descriptionCardStyle` 이나 테마에 `padding` 을 적으면 `ghost` 에서도 그 값을 그대로 씁니다.

### 의미 체인

`DescriptionCard`의 `.outline`은 `variant: .outlined`를 선택합니다. 테마가 윤곽선과 배경을 결정합니다.

## 크기

`size` 는 `CoreDescriptionCardSize` 의 다섯 단계이고 기본값은 `md` 입니다. 안쪽 여백, 모서리, 간격, 글자가 함께 바뀝니다.

<Preview demo="description-card/sizes" />

아래 숫자는 기본 테마의 논리 픽셀 값입니다. 글자 칸은 글자 크기입니다.

| size | 안쪽 여백 · 모서리 | 제목 · 라벨 · 값 글자 | 행 위아래 · 라벨과 값 사이 |
| --- | --- | --- | --- |
| `xs` | 12 · 12 | 13 · 12 · 12 | 6 · 6 |
| `sm` | 14 · 14 | 14 · 13 · 13 | 6 · 8 |
| `md` | 16 · 16 | 15 · 14 · 14 | 8 · 12 |
| `lg` | 18 · 16 | 16 · 15 · 15 | 8 · 16 |
| `xl` | 20 · 16 | 20 · 15 · 16 | 10 · 20 |

위 표의 "라벨과 값 사이" 는 가로 레이아웃의 간격입니다. 아래는 나머지 값입니다.

| size | 세로 레이아웃의 라벨과 값 사이 | 구분선 앞뒤 간격 | 제목 아이콘 |
| --- | --- | --- | --- |
| `xs` | 2 | 8 | 16 |
| `sm` | 2 | 8 | 16 |
| `md` | 4 | 10 | 18 |
| `lg` | 6 | 10 | 20 |
| `xl` | 8 | 12 | 20 |

- 글자 굵기는 모든 크기에서 같습니다. 제목은 SemiBold(600), 라벨은 Regular(400), 값은 Medium(500)입니다.
- 행끼리는 붙어 있고(`rowSpacing` 0), 각 행이 위아래 여백(`rowPadding`)을 가집니다.
- 슬롯의 아이콘과 옆 글자 사이는 모든 크기에서 8 입니다. 세로 레이아웃의 행 앞 슬롯과 라벨 사이만 6 입니다.

## 형태

### 레이아웃

`layout` 은 한 행 안에서 라벨과 값을 놓는 방향입니다. 기본값은 `horizontal` 입니다.

<Preview demo="description-card/layouts" />

- **`horizontal`** — 라벨과 값을 한 줄에 놓고 행 안에서 세로 가운데에 맞춥니다. 값 글자는 끝 쪽에 맞춥니다.
- **`vertical`** — 라벨 아래에 값을 놓고 값은 시작 쪽에서 읽습니다. `alignment` 와 `valueTextAlign` 은 쓰이지 않습니다. 행의 `leading` · `trailing` 위치는 두 플랫폼이 다릅니다(플랫폼 차이 섹션).

### 가로 정렬

`alignment` 는 가로 레이아웃에서 값이 차지하는 자리를 고릅니다. 기본값은 `fixed` 입니다.

<Preview demo="description-card/alignment" />

- **`fixed`** — 라벨은 글자 폭만 쓰고, 값 자리가 남은 폭을 채웁니다. 값 글자는 그 자리 안에서 `valueTextAlign`(기본 `end`)을 따릅니다. 이름과 달리 라벨 열의 폭을 행마다 같게 맞추지는 않습니다.
- **`spaceBetween`** — 라벨과 값을 양 끝에 놓고, 값은 자기 글자만큼만 자리를 씁니다. 짧은 값이라면 `fixed` 의 기본 모습과 같아 보입니다. 긴 값이 올 수 있는 카드에는 `fixed` 를 쓰세요. Flutter 의 `spaceBetween` 은 값을 줄이지 않습니다(배치 섹션).

<a id="동작-스펙-behavior"></a>

## 행과 값

`rows` 는 넘긴 순서대로 그립니다. 행 하나는 `DescriptionRow` 이고 `label` 만 필수입니다. 정렬 · 필터 · 선택 기능은 없습니다.

### 앞뒤 슬롯과 커스텀 값

행마다 `leading` · `trailing` 슬롯을 둘 수 있고, 문자열 대신 위젯을 값으로 보이려면 `valueWidget` 을 씁니다.

<Preview demo="description-card/row-slots" />

- `valueWidget` 이 있으면 `value` 는 그리지 않으므로 생략해도 됩니다.
- `valueTextStyle` 과 강조 굵기는 문자열 값에 쓰는 설정입니다. 커스텀 위젯의 모양은 그 위젯에서 정합니다.
- 행의 `leading` · `trailing` 은 카드가 크기를 맞춰 주지 않습니다. 크기 단계의 아이콘 설정을 받는 슬롯은 `titleLeading` 하나입니다.
- 가로 `fixed` 에서 커스텀 값이 놓이는 방식은 두 플랫폼이 다릅니다. Flutter 는 위젯이 남은 폭 전체를 받으므로 끝에 맞추려면 `Align` 으로 감쌉니다. Web 은 값의 글자 정렬(`valueTextAlign`, 기본 끝 쪽)을 가진 상자가 감싸므로, 배지처럼 글줄에 놓이는 요소는 그대로 끝에 맞춰집니다.

<Tabs groupId="platform">
<TabItem label="Flutter" value="flutter">

```dart
DescriptionRow(
  label: '배송 상태',
  valueWidget: Align(
    alignment: AlignmentDirectional.centerEnd,
    child: Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('배송 완료')),
  ),
)
```

</TabItem>
<TabItem label="Web" value="web">

```dart
DescriptionRow(
  label: '배송 상태',
  valueWidget: Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('배송 완료')),
)
```

</TabItem>
</Tabs>

### 강조 행

합계나 점수처럼 눈에 먼저 들어와야 하는 행에는 `isEmphasized: true` 를 줍니다.

```dart
DescriptionRow(label: '합계', value: '369,000원', isEmphasized: true)
```

- 값이 Bold(700)가 됩니다. 라벨은 다른 행과 같은 모양이라 두 열이 그대로 읽힙니다.
- 카드의 `emphasizedLabelTextStyle` · `emphasizedValueTextStyle` 은 강조 행에만 적용됩니다. 행마다 `labelTextStyle` · `valueTextStyle` 을 적지 않아도 강조 모양이 한 카드 안에서 같게 유지됩니다.
- `emphasizedValueTextStyle` 이나 그 행의 `valueTextStyle` 에 `fontWeight` 를 적으면 자동 Bold 대신 적은 굵기를 씁니다. 카드 공통의 `valueTextStyle.fontWeight` 는 강조 행에서 자동 Bold 에 덮입니다.
- 값이 없어 자리 표시를 그리는 행에는 자동 Bold 를 적용하지 않습니다.

### 빈 값

`value` 와 `valueWidget` 이 **둘 다** `null` 인 행이 빈 행입니다. 빈 문자열 `''` 은 값으로 보고 그대로 그립니다.

<Preview demo="description-card/empty" />

- **`hide`** (기본값) — 빈 행과 그 행의 구분선을 그리지 않습니다. 모든 행이 빈 행이면 행 목록만 비고, 넘긴 제목과 하단 액션은 남습니다.
- **`placeholder`** — 값 자리에 `emptyPlaceholder`(기본 `'-'`)를 40% 불투명도로 그립니다. 흐리게 하기 전의 색은 두 플랫폼이 다릅니다(플랫폼 차이 섹션).

```dart
DescriptionCard(
  emptyValueBehavior: CoreDescriptionCardEmptyBehavior.placeholder,
  emptyPlaceholder: '정보 없음',
  rows: [
    DescriptionRow(label: '등급', value: 'Gold'),
    DescriptionRow(label: '추천인'),
  ],
)
```

### 긴 값

`valueOverflow` 는 문자열 값이 자리보다 길 때의 처리입니다. `wrap`(기본값)은 줄을 바꾸고, `ellipsis` 는 한 줄로 두고 말줄임합니다. 라벨에는 적용되지 않으며, 커스텀 `valueWidget` 의 줄바꿈은 그 위젯에서 정합니다.

<Preview demo="description-card/overflow" />

<Note>

Flutter 의 `alignment: spaceBetween` 에서는 `valueOverflow` 가 효과를 내지 않습니다. 값의 폭이 제한되지 않아 긴 값이 행 밖으로 넘칩니다. 가로 레이아웃에서 긴 값을 보이려면 `fixed` 를 씁니다.

</Note>

### 라벨과 값의 색

`rowWeight` 는 라벨과 값 가운데 어느 쪽을 진한 색으로 칠할지 고릅니다. 색만 맞바꾸고 글자 굵기는 그대로입니다.

<Preview demo="description-card/row-weight" />

| rowWeight | 라벨 색 | 값 색 |
| --- | --- | --- |
| `valueProminent` (기본) | `onSurfaceVariant` | `onSurface` |
| `labelProminent` | `onSurface` | `onSurfaceVariant` |

## 제목과 하단 액션

제목 영역은 `title` 을 줄 때만, 하단 액션 영역은 `bottomAction` 을 줄 때만 만들어집니다.

<Preview demo="description-card/title-action" />

- `title` 이 `null` 이면 `titleLeading` · `titleTrailing` 과 제목 구분선도 그리지 않습니다.
- 긴 제목은 Flutter 에서 한 줄로 말줄임되고, Web 에서는 줄이 바뀝니다.
- `showDivider: false` 는 제목 아래의 선만 지웁니다. 선 앞뒤의 간격은 남습니다.
- `showRowDividers` 는 행 사이의 선입니다. 마지막 행 아래에는 선이 없습니다.
- `showBottomActionDivider: false` 는 하단 액션 위의 선과 그 아래 간격을 함께 뺍니다. 행과 액션 사이의 간격 하나는 남습니다.
- 하단 액션의 폭은 두 플랫폼이 다릅니다. Flutter 는 위젯의 자기 폭으로 시작 쪽에 놓고, Web 은 카드 폭만큼 늘립니다. 두 플랫폼에서 같은 모습이 필요하면 `Button` 에 `expanded: true` 를 줍니다.

```dart
DescriptionCard(
  title: '주문 상세',
  titleLeading: Icon(LucideIcons.info),
  titleTrailing: Badge(tone: CoreBadgeTone.success, child: Text('완료')),
  rows: [
    DescriptionRow(label: '상품', value: 'AirPods'),
    DescriptionRow(label: '합계', value: '369,000원'),
  ],
  bottomAction: Button(
    variant: CoreButtonVariant.outline,
    expanded: true,
    onPressed: showReceipt,
    child: Text('영수증 보기'),
  ),
)
```

## 상태

아무 콜백도 주지 않은 카드는 표시용입니다. 카드에 `onTap` 을 주면 카드 전체가, 행에 `onTap` 을 주면 그 행이 눌립니다. 둘 다 `Clickable` 로 감싸 만듭니다.

<Preview demo="description-card/states" />

| 상태 | 조건 | 동작 |
| --- | --- | --- |
| 표시용 | `onTap` 과 행의 `onTap` 이 없음 | 카드 자체는 누르기에 반응하지 않습니다. |
| 누르기 | 카드 `onTap` 또는 행 `onTap` | 클릭 커서와 키보드 포커스 링이 생기고, `Enter` · `Space` 로도 실행합니다. |
| 비활성 | 누를 곳이 있는데 `enabled: false` | 카드와 행이 눌리지 않고 내용이 흐려지며, 커서가 누를 수 없음으로 바뀝니다. |

- 기본 테마에서는 마우스를 올리거나 눌러도 색과 크기가 바뀌지 않습니다. 카드와 행은 면이 넓어, 누를 때 줄어드는 효과를 꺼 두었습니다.
- 누를 수 있는 카드와 행 안의 글자는 드래그로 선택할 수 없습니다. 주문번호처럼 복사해야 하는 값이 있으면 표시용 카드에 두고 동작은 버튼으로 둡니다.
- `enabled` 를 적지 않으면 누를 곳이 있을 때 켜집니다. `enabled: true` 만으로는 누를 수 있게 되지 않습니다.
- 비활성일 때는 제목, 행, 하단 액션 영역과 그 안의 아이콘 · 구분선만 40% 불투명도(`disabledContentOpacity`)로 흐려지고 바탕과 테두리는 그대로입니다. 누를 곳이 없는 카드는 `enabled: false` 여도 흐려지지 않습니다.
- 하단 액션이나 행 슬롯에 넣은 버튼은 흐려져도 스스로 비활성이 되지 않습니다. 함께 막으려면 그 버튼에도 `enabled: false` 를 줍니다.

행만 누르게 하려면 카드의 `onTap` 없이 행에 `onTap` 을 줍니다. 아래는 세로 레이아웃의 예입니다.

<Preview demo="description-card/row-tap" />

```dart
DescriptionCard(
  layout: CoreDescriptionCardLayout.vertical,
  rows: [
    DescriptionRow(label: '배송지', value: '중구 예시로 123', onTap: editAddress),
    DescriptionRow(label: '결제 수단', value: '계좌 이체', onTap: editPayment),
    DescriptionRow(label: '합계', value: '369,000원'),
  ],
)
```

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 주문 상세, 프로필, 관리 기록, 시험 결과처럼 라벨과 값의 쌍을 한 장에 모아 보일 때
- 합계나 점수 행 하나를 강조해야 할 때 (`isEmphasized: true`)
- 모아 둔 사실 아래에 이어지는 동작이 있을 때 (`bottomAction`)

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 카드 상자나 행 누르기 없이 용어와 설명의 관계만 나열할 때 | [DefinitionList](/components/definition-list) |
| 여러 건을 열로 맞춰 정렬하거나 비교할 때 | [Table](/components/table) |
| 핵심 수치 하나를 보일 때 | [Stat](/components/stat) |
| 라벨과 값의 행이 아니라 자유로운 내용을 담을 때 | [Card](/components/card) |

<a id="do"></a>

### 강조는 필요한 행에만

<Cards columns="2">
<Card demo="description-card/do-emphasis" tone="do" eyebrow="이렇게 하세요">

합계처럼 결론이 되는 행 하나에만 `isEmphasized` 를 줍니다.

</Card>
<Card demo="description-card/dont-emphasis" tone="dont" eyebrow="이렇게 하지 마세요">

모든 행을 강조하면 어느 값이 결론인지 드러나지 않습니다.

</Card>
</Cards>

<a id="dont"></a>

### 누를 곳은 겹치지 않게

<Cards columns="2">
<Card demo="description-card/do-action" tone="do" eyebrow="이렇게 하세요">

하단 액션에 버튼을 두면 카드는 표시용으로 둡니다. 누를 곳이 하나로 보입니다.

</Card>
<Card demo="description-card/dont-action" tone="dont" eyebrow="이렇게 하지 마세요">

누를 수 있는 카드 안에 버튼을 두면 누를 곳이 겹칩니다. Web 에서는 버튼을 눌러도 카드의 `onTap` 이 함께 실행됩니다.

</Card>
</Cards>

카드의 `onTap` 과 행의 `onTap` 도 함께 주지 않습니다. 카드 버튼 안에 행 버튼이 들어가는 구조가 되고, Web 에서는 행을 마우스로 누르면 두 콜백이 모두 실행됩니다. Flutter 에서는 안쪽 행만 눌립니다.

```dart
// 하지 마세요 — 카드 전체와 행이 모두 눌립니다
DescriptionCard(
  onTap: openDetail,
  rows: [
    DescriptionRow(label: '주문번호', value: 'ORD-2025-00391', onTap: openOrder),
  ],
)
```

## 배치

### 폭과 높이

- 표시용 카드는 부모가 주는 폭을 채웁니다.
- Flutter 의 카드는 폭의 상한이 있어야 합니다. `Row` 안에 둘 때는 `Expanded` 나 폭을 정한 `SizedBox` 로 감쌉니다.
- 높이는 내용만큼 늘어납니다. 카드 안에 스크롤은 없으므로, 행이 많으면 카드를 스크롤 영역 안에 둡니다.
- Web 에서 카드에 `onTap` 을 주면 카드가 `inline-flex` 래퍼에 담깁니다. 블록 부모 안에서는 카드가 내용 폭으로 줄 수 있으니, 부모 폭을 채우려면 `classes: 'w-full'` 을 줍니다.

```dart
// Web
DescriptionCard(
  classes: 'w-full',
  onTap: openOrder,
  rows: rows,
)
```

<Note>

Web 에서는 카드에 `onTap` 이 없으면 지금 `classes` 가 반영되지 않습니다. 행에만 `onTap` 을 준 카드도 같습니다. 배치 클래스가 필요하면 바깥을 `div` 로 감쌉니다.

</Note>

### 긴 라벨과 긴 값

- Flutter 의 가로 레이아웃은 라벨의 폭을 줄이거나 줄을 바꾸지 않습니다. 좁은 화면에서 긴 라벨이 필요하면 `layout: CoreDescriptionCardLayout.vertical` 을 씁니다.
- Flutter 의 `spaceBetween` 은 값도 줄이지 않습니다. 길이를 알 수 없는 값은 `fixed` 에 놓습니다.
- Web 의 가로 레이아웃은 좁은 자리에서 라벨이 줄을 바꾸고, 문자열 값은 `valueOverflow` 에 따라 줄을 바꾸거나 말줄임합니다.

### Web 의 누를 수 있는 가로 행

Web 에서 가로 레이아웃의 행에 `onTap` 을 주면, 그 행의 내용이 카드 폭을 채우지 않고 내용 폭으로 놓입니다. 그래서 값이 끝 쪽에 맞춰지지 않고 라벨 가까이에 붙습니다. 행 구분선은 그대로 카드 폭입니다. 지금은 세로 레이아웃을 쓰거나, 행 대신 `trailing` · `bottomAction` 의 버튼, 또는 카드의 `onTap` 으로 동작을 둡니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

어떤 내용을 어떻게 놓을지는 위젯 파라미터로 정하고, 색 · 크기 · 간격 · 글자처럼 보이는 값은 `descriptionCardStyle`(`CoreDescriptionCardStyle`)로 바꿉니다. 앱 전체의 값은 `CoreComponentTheme.descriptionCard` 의 `CoreDescriptionCardTheme.style` 에 둡니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreDescriptionCardStyle 기본값 (defaultsByVariant · defaultsBySize · defaultXxx)
  → CoreComponentTheme.descriptionCard.style   // 앱 전체
  → descriptionCardStyle                       // 이 카드
```

행의 글자는 그 위에 다음 순서로 한 번 더 겹칩니다. 뒤가 우선합니다.

```text
크기 단계의 글자 + rowWeight 색
  → labelTextStyle · valueTextStyle
  → emphasizedLabelTextStyle · emphasizedValueTextStyle   // 강조 행, 값에는 자동 Bold
  → row.labelTextStyle · row.valueTextStyle               // 이 행
  → 자리 표시 색                                           // 빈 값 자리 표시 행의 값
```

- 뒤 단계는 값을 적은 필드만 덮습니다. 글자 스타일, `*GapStyle`, `titleLeadingIconStyle`, `clickableStyle` 은 그 안에서도 적은 값만 덮으므로, `fontSize` 만 적으면 색과 굵기는 앞 단계의 값이 남습니다. `padding` · `rowPadding` · `boxShadow` 는 통째로 바뀝니다.
- 테마의 `style` 은 모든 `variant` 와 `size` 에 똑같이 적용됩니다. 예를 들어 테마에 `padding` 을 적으면 크기 단계별 여백과 `ghost` 의 좌우 여백 0 대신 그 값이 쓰입니다. `backgroundColor` 를 적으면 `ghost` 에도 바탕이 생깁니다.
- `filled` 와 `ghost` 는 테두리 굵기가 0 입니다. 선을 두르려면 `borderColor` 와 `borderWidth` 를 함께 적습니다.
- `titleTextStyle` 은 제목에만 적용됩니다. 크기 단계의 글자와 SemiBold 위에 `fontSize` · `fontWeight` · `letterSpacing` · `fontFamily` · `lineHeight` · `lineHeightPx` · `color` 가운데 적은 값을 겹치고, 행의 글자는 바꾸지 않습니다.
- 제목 색은 `titleColor` 와 `titleTextStyle.color` 중 하나로만 정하세요. 둘을 함께 적으면 Flutter 는 `titleColor`, Web 은 `titleTextStyle.color` 를 칠합니다.
- 글자 크기나 글꼴은 `fontSize` · `fontFamily` 로 직접 적습니다. 행의 글자 스타일은 역할 토큰(`CoreTextStyle.token`)에서 `color` 만 읽습니다. 제목에 역할 토큰을 주면 크기 단계가 이미 정한 글자 크기 · 줄 높이 · 굵기 · 자간은 그대로 남습니다.

### 사용 예

<Split>

<Code language="dart" title="카드 하나만 바꾸기">
DescriptionCard(
  rows: [
    DescriptionRow(label: '상품', value: '369,000원'),
    DescriptionRow(label: '합계', value: '372,000원', isEmphasized: true),
  ],
  descriptionCardStyle: CoreDescriptionCardStyle(
    borderColor: CoreColor.token(CoreColors.primary),
    rowPadding: CoreEdgeInsets.symmetric(vertical: CoreSpace.space12),
    labelTextStyle: CoreTextStyle(fontSize: CoreFontSize.s12),
    emphasizedValueTextStyle: CoreTextStyle(
      color: CoreColor.token(CoreColors.primaryText),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    descriptionCard: CoreDescriptionCardTheme(
      style: CoreDescriptionCardStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
        dividerColor: CoreColor.token(CoreColors.outline),
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter 와 Web 코드가 같습니다. 아래는 첫 번째 예제를 그린 모습입니다.

<Preview demo="description-card/styled" />

그림자와 누르기 설정에는 다음을 알아 두세요.

- `boxShadow` 로 직접 준 그림자는 지금 카드의 둥근 모서리를 따르지 않고 직각 모서리 상자로 그려집니다. 두 플랫폼이 같습니다.
- `shadowBaseColor` 는 `boxShadow` 를 직접 준 카드의 그림자 색에만 쓰입니다.
- `clickableStyle` 하나가 누를 수 있는 카드와 행에 함께 적용됩니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `DescriptionCard` 에 `withStyle` 을 이어 `descriptionCardStyle` 에 값을 덧붙일 수 있습니다. 같은 필드를 여러 번 적으면 나중에 이은 값이 이깁니다. `.radius16` 처럼 Core 토큰 상수와 이름이 같은 getter 는 `withStyle` 을 짧게 쓴 것입니다. `radius*` 는 모서리(`borderRadius`)를, `.primary` 같은 색 getter 는 바탕(`backgroundColor`)만 바꿉니다. `.outline` 은 색 getter 가 아니라 `variant: .outlined` 를 고릅니다. `backgroundColor` · `borderColor` · `borderWidth` · `contentPadding` 메서드로는 바탕색, 테두리 색과 두께, 안쪽 여백을 값으로 줄 수 있습니다. 글자색은 그대로이므로 진한 바탕을 쓸 때는 라벨 · 값 · 제목의 색도 함께 지정해 대비를 확인하세요.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class DescriptionCardChainExample extends StatelessWidget {
  const DescriptionCardChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        const DescriptionCard(
          title: '주문 상세',
          rows: [
            DescriptionRow(label: '주문번호', value: 'ORD-2025-00391'),
            DescriptionRow(label: '상품', value: 'AirPods Pro 2'),
            DescriptionRow(
              label: '합계',
              value: '369,000원',
              isEmphasized: true,
            ),
          ],
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        const DescriptionCard(
          title: '주문 상세',
          rows: [
            DescriptionRow(label: '주문번호', value: 'ORD-2025-00391'),
            DescriptionRow(label: '상품', value: 'AirPods Pro 2'),
            DescriptionRow(
              label: '합계',
              value: '369,000원',
              isEmphasized: true,
            ),
          ],
        ).withStyle(
          const CoreDescriptionCardStyle(
            backgroundColor: .tertiary,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            rowSpacing: CoreSpace.space12,
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
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
class DescriptionCardChainExample extends StatelessComponent {
  const DescriptionCardChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        const DescriptionCard(
          title: '주문 상세',
          rows: [
            DescriptionRow(label: '주문번호', value: 'ORD-2025-00391'),
            DescriptionRow(label: '상품', value: 'AirPods Pro 2'),
            DescriptionRow(
              label: '합계',
              value: '369,000원',
              isEmphasized: true,
            ),
          ],
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        const DescriptionCard(
          title: '주문 상세',
          rows: [
            DescriptionRow(label: '주문번호', value: 'ORD-2025-00391'),
            DescriptionRow(label: '상품', value: 'AirPods Pro 2'),
            DescriptionRow(
              label: '합계',
              value: '369,000원',
              isEmphasized: true,
            ),
          ],
        ).withStyle(
          const CoreDescriptionCardStyle(
            backgroundColor: .tertiary,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            rowSpacing: CoreSpace.space12,
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
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

### 기본값이 있는 곳

기본값은 `coui_core` 의 `CoreDescriptionCardStyle` 에 있고 Flutter 와 Web 이 같은 값을 읽습니다.

- `defaultsByVariant` — `variant` 별 바탕, 테두리 색 · 굵기, 좌우 여백 사용 여부
- `defaultsBySize` — 크기 단계별 모서리, 여백, 간격, 제목 아이콘, 글자 역할
- `defaultTitleColor` (`onSurface`) · `defaultTitleTextStyle` (SemiBold)
- `defaultDividerColor` (`outlineVariant`)
- `defaultRowLeadingGapStyle` (6)
- `defaultValueTextAlign` (`end`)
- `defaultDisabledContentOpacity` (0.4)
- `defaultClickableStyle` — 누를 때 줄이지 않음(`pressedScale: 1`). 비활성일 때 카드 전체를 한 번 더 흐리지 않습니다.

라벨과 값의 색은 `rowWeight` 별 표인 `kCoreDescriptionCardRowWeightColors` 에서 옵니다.

<a id="접근성-accessibility"></a>

## 접근성

`DescriptionCard` 는 표시용일 때 글을 배치하는 상자입니다. 카드의 `onTap` 이나 행의 `onTap` 을 줄 때만 그 자리에 버튼 정보가 생깁니다.

### 역할

| 상태 | Flutter | Web |
| --- | --- | --- |
| 표시용 | 카드가 따로 붙이는 `Semantics` 가 없습니다. | `role` 이 없는 `div` 와 `span` 입니다. |
| 누르기 | `Clickable` 이 `Semantics(button: true, enabled: ...)` 를 붙입니다. | 카드나 행을 감싼 `div` 에 `role="button"` 이 붙고, 비활성이면 `aria-disabled="true"` 가 붙습니다. |

- 제목은 일반 글자입니다. 두 플랫폼 모두 제목(heading)으로 표시하지 않습니다.
- 카드가 그리는 구분선은 장식용 `Divider` 라 구분선 역할이나 이름을 붙이지 않습니다.

### 키보드

카드 자체는 키를 처리하지 않습니다. 아래는 누를 수 있는 카드와 행의 동작입니다.

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift` + `Tab` | 누를 수 있는 카드와 행 사이를 옮겨 갑니다. 비활성이면 멈추지 않습니다. |
| `Enter` · `Space` | 포커스를 가진 카드나 행의 콜백을 실행합니다. |

- 카드가 방향키나 `Home` · `End` 에 따로 연결한 동작은 없습니다.
- 카드와 행에 모두 `onTap` 이 있을 때, 행에 포커스를 두고 누른 키는 그 행만 실행합니다.
- Web 에서 누를 수 있는 카드 안의 버튼을 `Enter` · `Space` 로 누르면 브라우저의 클릭이 바깥으로 전달되어 카드의 `onTap` 도 실행됩니다.

### 스크린 리더

- 라벨과 값은 각각의 글자입니다. 어느 값이 어느 라벨의 것인지 알려 주는 정보는 붙지 않습니다. Web 에서도 `dl` · `dt` · `dd`, 목록 · 묶음 역할, `aria-labelledby` 를 쓰지 않습니다. 이 관계를 마크업으로 전해야 하면 Web 에서 `dl` 로 그리는 [DefinitionList](/components/definition-list)를 검토하세요.
- 카드는 이름이나 설명, 값이 바뀌었다는 알림을 따로 만들지 않습니다.
- `hide` 로 숨긴 빈 행은 화면에도 접근성 정보에도 없습니다.
- 자리 표시는 `emptyPlaceholder` 글자 그대로이며 "값 없음" 이라는 별도 정보는 없습니다. 기호 `'-'` 만으로 뜻이 전해지지 않으면 `'정보 없음'` 같은 말을 씁니다.
- `isEmphasized` 와 `rowWeight` 는 모양만 바꿉니다. 꼭 전해야 하는 뜻은 라벨의 말에 담습니다.

#### 이름 붙이기

Web 은 `attributes` 로 이름을 붙일 수 있습니다. 표시용 카드는 역할이 없으므로 `role="group"` 과 `aria-label` 을 함께 줍니다. 누를 수 있는 카드에서는 `attributes` 가 버튼 역할을 가진 바깥 `div` 에 붙습니다. Flutter 에는 카드의 이름을 따로 받는 파라미터가 없습니다.

```dart
// Web
DescriptionCard(
  attributes: {'role': 'group', 'aria-label': '주문 상세'},
  rows: rows,
)
```

### 포커스 관리

- 표시용 카드는 포커스를 받지 않습니다. 슬롯에 넣은 버튼 같은 컨트롤은 자기 동작대로 포커스를 받습니다.
- 카드는 마운트될 때 포커스를 옮기지 않고, 포커스를 가두거나 되돌리지 않습니다.
- 누를 수 있는 카드와 행은 각각 포커스를 받습니다. Web 은 활성인 카드 · 행의 `div` 에 `tabindex="0"` 을 붙이고, 비활성이면 붙이지 않습니다.
- 포커스 링은 Flutter 에서는 `Clickable` 이, Web 에서는 `:focus-visible` 일 때 그립니다.
- 링의 모서리는 카드의 모서리를 따르지 않고 `Clickable` 의 기본값 4 를 씁니다. 카드에 맞추려면 `clickableStyle` 의 `borderRadius` 를 적습니다. 이 값은 누를 수 있는 행에도 함께 적용됩니다.

```dart
DescriptionCard(
  onTap: openOrder,
  rows: rows,
  descriptionCardStyle: CoreDescriptionCardStyle(
    clickableStyle: CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  ),
)
```

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 라벨과 값의 짝이 접근성 정보로 연결되지 않고, 제목은 heading 이 아닙니다. |
| 공통 | 누를 수 있는 행의 누르는 영역은 그려진 크기 그대로입니다. `md` 의 한 줄 행도 높이가 44 보다 낮습니다. |
| 공통 | `ghost` 는 좌우 안쪽 여백이 없고 카드가 바깥을 잘라, 누를 수 있는 행의 포커스 링 좌우가 잘립니다. `padding` 을 적어 좌우에 자리를 두세요. |
| 공통 | 빈 값 자리 표시는 40% 불투명도라 흐리게 보입니다. 꼭 읽어야 하는 안내라면 `value` 로 직접 넘깁니다. |
| Web | 카드와 행을 모두 누를 수 있게 하면 `role="button"` 안에 `role="button"` 이 들어갑니다. |
| Web | 누를 수 있는 가로 레이아웃의 행은 내용 폭으로 놓여, 값이 끝 쪽에 맞춰지지 않습니다. |
| Flutter | 가로 레이아웃의 긴 라벨과 `spaceBetween` 의 긴 값은 줄지 않고 넘칩니다. |
| Flutter | 카드의 접근 가능한 이름을 받는 파라미터가 없습니다. |

동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타겟처럼 모든 컴포넌트에 걸리는 기준은 [전역 접근성 축](/accessibility)에서 설명합니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`rows` 와 카드의 속성, `descriptionCardStyle` 은 두 플랫폼이 같은 이름을 씁니다. `DescriptionRow` 라는 이름도 같고, 안에 담는 타입만 Flutter 의 `Widget`, Web 의 Jaspr `Component` 로 다릅니다. 행의 `onTap` 과 커스텀 값은 두 플랫폼 모두 지원합니다. 다르게 동작하는 부분은 다음과 같습니다.

| 항목 | Flutter | Web |
| --- | --- | --- |
| 누르기 처리 | `Clickable` 의 제스처와 키보드 단축키 | `Clickable` 의 `click` 과 키보드 이벤트 |
| 겹친 누르기 | 안쪽 컨트롤이나 행만 눌립니다. | 클릭이 바깥으로 전달되어 카드의 `onTap` 도 실행됩니다. |
| 누를 수 있는 카드의 폭 | 부모가 주는 폭을 채웁니다. | `inline-flex` 래퍼에 담겨, 블록 부모에서는 내용 폭으로 줄 수 있습니다. |
| 누를 수 있는 가로 행 | 카드 폭을 채웁니다. | 내용 폭으로 놓입니다. |
| 긴 제목 | 한 줄 말줄임 | 줄바꿈 |
| 가로 레이아웃의 긴 라벨 | 줄지 않고 넘칩니다. | 줄이 바뀝니다. |
| `spaceBetween` 의 긴 값 | 줄지 않고 넘칩니다. | `valueOverflow` 를 따릅니다. |
| 가로 `fixed` 의 커스텀 값 | 남은 폭 전체를 받습니다. 정렬은 위젯이 정합니다. | `valueTextAlign` 을 따르는 상자(기본 끝 정렬) 안에 놓이고, 크기 단계의 값 글자 · 색을 물려받습니다. `ellipsis` 면 상자에 말줄임 설정이 함께 걸립니다. |
| 세로 레이아웃의 행 슬롯 | `leading` 오른쪽에 라벨과 값이 정렬되고 `trailing` 은 행 끝 위쪽에 놓입니다. | `leading` 은 라벨 앞에만 놓여 값이 카드 시작 선에서 시작하고, `trailing` 은 값 아래에 놓입니다. |
| 세로 레이아웃의 커스텀 값 | 위젯의 자기 폭 | 행 폭으로 늘어날 수 있습니다. `div` 로 감싸면 막을 수 있습니다. |
| 하단 액션 폭 | 위젯의 자기 폭 | 카드 폭으로 늘어납니다. |
| 자리 표시 색 | `rowWeight` 가 정한 라벨 색의 40% | `rowWeight` 가 정한 값 색의 40% |
| 제목 색 두 값 | `titleColor` 와 `titleTextStyle.color` 를 함께 적으면 `titleColor` | 함께 적으면 `titleTextStyle.color` |
| 앱의 글자 단계 | 앱 테마의 `typography` 를 바꿔도 카드의 제목 · 라벨 · 값은 CoUI 기본 글자 단계로 그립니다. | `text-label-large` 같은 글자 단계 클래스를 써서 스타일시트의 글자 단계를 따릅니다. |
| 스타일 값의 변환 | `Color` · `EdgeInsets` · `BoxShadow` 로 바꿔 그립니다. | CSS 클래스와 인라인 스타일로 바꿔 그립니다. |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` (API 의 Web 전용) |

Flutter 에서 카드의 글꼴이나 글자 크기를 바꾸려면 `descriptionCardStyle` 또는 `CoreDescriptionCardTheme.style` 의 `titleTextStyle` · `labelTextStyle` · `valueTextStyle` 에 `fontFamily` · `fontSize` 를 직접 적습니다.

<a id="props-parameters"></a>

## API

표의 `W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다. `W?` 는 선택 슬롯입니다. 아래 표에는 위젯 생성자의 파라미터를 적고, 겉모습을 바꾸는 값은 `descriptionCardStyle` 안에 있습니다.

### 카드 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `rows` | `List<DescriptionRow>` | 필수 | 행 데이터 목록. 넘긴 순서대로 그립니다. |
| `size` | `CoreDescriptionCardSize` | `md` | 크기 단계 — `xs` · `sm` · `md` · `lg` · `xl` |
| `layout` | `CoreDescriptionCardLayout` | `horizontal` | 라벨과 값의 방향 — `horizontal` · `vertical` |
| `variant` | `CoreDescriptionCardVariant` | `outlined` | 바탕과 테두리 — `filled` · `outlined` · `ghost` |
| `alignment` | `CoreDescriptionCardAlignment` | `fixed` | 가로 레이아웃의 값 자리 — `fixed` · `spaceBetween` |
| `valueOverflow` | `CoreDescriptionCardOverflow` | `wrap` | 긴 문자열 값 — `wrap` · `ellipsis` |
| `rowWeight` | `CoreDescriptionCardRowWeight` | `valueProminent` | 진한 색을 쓰는 쪽 — `valueProminent` · `labelProminent` |
| `emptyValueBehavior` | `CoreDescriptionCardEmptyBehavior` | `hide` | 빈 행 처리 — `hide` · `placeholder` |
| `emptyPlaceholder` | `String` | `'-'` | `placeholder` 일 때 값 자리에 그리는 글 |
| `title` | `String?` | `null` | 카드 제목 |
| `titleLeading` | `W?` | `null` | 제목 앞 슬롯. `title` 이 있을 때만 그립니다. |
| `titleTrailing` | `W?` | `null` | 제목 줄 끝 슬롯. `title` 이 있을 때만 그립니다. |
| `showDivider` | `bool` | `true` | 제목 아래 구분선 |
| `showRowDividers` | `bool` | `true` | 마지막 행을 뺀 각 행 아래의 구분선 |
| `bottomAction` | `W?` | `null` | 하단 액션 영역 |
| `showBottomActionDivider` | `bool` | `true` | 하단 액션 위의 구분선 |
| `onTap` | `VoidCallback?` | `null` | 카드를 눌렀을 때의 콜백 |
| `enabled` | `bool?` | `null` | 카드와 행이 누르기에 반응하는지. `null` 이면 누를 곳이 있을 때 켜집니다. |
| `descriptionCardStyle` | `CoreDescriptionCardStyle?` | `null` | 이 카드의 보이는 값 덮어쓰기 |

이미 만든 카드에는 `withStyle(patch)`, `radius*` · 색 getter, `backgroundColor` · `borderColor` · `borderWidth` · `contentPadding` 메서드를 이어 쓸 수 있습니다(테마와 스타일의 빠른 덮어쓰기). `.outline` 은 variant 를 바꿉니다. `copyWith` 로 일부 값을 바꾼 복사본도 만들 수 있습니다. `null` 을 넘긴 값은 원래 값이 남습니다.

### `DescriptionRow`

`DescriptionRow` 는 Flutter 에서 `CoreDescriptionRow<Widget>`, Web 에서 `CoreDescriptionRow<Component>` 의 다른 이름입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String` | 필수 | 행 라벨 |
| `value` | `String?` | `null` | 행의 문자열 값 |
| `valueWidget` | `W?` | `null` | 값 자리에 그릴 위젯. `value` 보다 우선합니다. |
| `leading` | `W?` | `null` | 라벨 앞 슬롯 |
| `trailing` | `W?` | `null` | 값 뒤 슬롯 |
| `onTap` | `VoidCallback?` | `null` | 행을 눌렀을 때의 콜백 |
| `labelTextStyle` | `CoreTextStyle?` | `null` | 이 행의 라벨 글자 덮어쓰기 |
| `valueTextStyle` | `CoreTextStyle?` | `null` | 이 행의 값 글자 덮어쓰기 |
| `isEmphasized` | `bool` | `false` | 강조 행. 값이 Bold 가 되고 카드의 강조 글자 스타일을 적용합니다. |

### Web 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 카드의 바깥 요소 id. `onTap` 이 있으면 버튼 역할의 `div` 에 붙습니다. |
| `classes` | `String?` | `null` | 배치용 클래스. 지금은 `onTap` 이 있는 카드에만 반영됩니다. |
| `css` | `Styles?` | `null` | 바깥 요소의 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 바깥 요소의 HTML 속성 — `aria-label`, `data-*` 등 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 바깥 요소의 DOM 이벤트. `onTap` 이 있는 카드에서는 `click` · `keydown` 처럼 `Clickable` 이 쓰는 이름의 처리기가 `Clickable` 의 것으로 바뀝니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreDescriptionCardStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Card background fill colour. |
| `borderColor` | `CoreColor?` | Card border stroke colour. |
| `borderWidth` | `double?` | Card border stroke width (logical px, pre-scaling). |
| `borderRadius` | `CoreBorderRadius?` | Card corner override. Defaults come from [defaultsBySize] — 12 at xs, 14 at sm, 16 from md up. |
| `padding` | `CoreEdgeInsets?` | Card content padding override. |
| `boxShadow` | `List<CoreShadowLayer>?` | Card box shadow override. |
| `shadowBaseColor` | `CoreColor?` | Shadow base colour override — foundation of the elevation shadow stack. Defaults to [defaultShadowBaseColor] when unset. |
| `dividerColor` | `CoreColor?` | Divider line colour (title / inter-row / bottom-action separators inside the card). |
| `titleColor` | `CoreColor?` | Title slot text colour override. Defaults to [defaultTitleColor] when unset. |
| `rowSpacing` | `double?` | Vertical spacing between rows (logical px). Drives the `Column`-spacing-equivalent main-axis distance between consecutive rows. Stays a flat double — the rows wrapper consumes this scalar either via `gap-${tailwindSpace}` (Web) or `Gap` (Flutter). |
| `rowPadding` | `CoreEdgeInsets?` | Inset around each row's content. The default is vertical only — rows sit edge to edge and the divider under each row (but the last) lands at the bottom of this inset. Defaults come from [defaultsBySize]. |
| `columnGapStyle` | `CoreGapStyle?` | Horizontal gap between label and value in horizontal layouts, passed to `Gap(gapStyle: …)` on both platforms. |
| `iconLabelGapStyle` | `CoreGapStyle?` | Gap between a leading or trailing icon and the text next to it, in the title and in each row, passed to `Gap(gapStyle: …)`. A vertical-layout row's leading icon takes [rowLeadingGapStyle] instead. |
| `labelValueGapStyle` | `CoreGapStyle?` | Gap between label and value in the vertical layout, passed to `Gap(gapStyle: …)` on both platforms. |
| `titleContentGapStyle` | `CoreGapStyle?` | Vertical spacing around the title divider and the bottom-action separator, passed to `Gap(gapStyle: …)`. Defaults come from [defaultsBySize]. |
| `rowLeadingGapStyle` | `CoreGapStyle?` | Gap between a row's leading icon and its label in the vertical layout, passed to `Gap(gapStyle: …)`. Defaults to [defaultRowLeadingGapStyle] when unset. |
| `labelTextStyle` | `CoreTextStyle?` | Default label text slot style (per-row, before emphasis). Exposes the full typographic surface (fontSize / fontWeight / letterSpacing / color). |
| `valueTextStyle` | `CoreTextStyle?` | Default value text slot style (per-row, before emphasis). |
| `titleTextStyle` | `CoreTextStyle?` | Title text slot style. Laid over the per-size role and [defaultTitleTextStyle] (SemiBold). |
| `titleLeadingIconStyle` | `CoreIconStyle?` | Size and colour an icon handed to `titleLeading` draws at — an `Icon` there without its own size or colour takes these. Defaults come from [defaultsBySize] (16 at xs · sm, 18 at md, 20 at lg · xl, `onSurfaceVariant`). |
| `valueTextAlign` | `CoreTextAlign?` | Horizontal alignment of a row's value text in the horizontal layouts. Defaults to [defaultValueTextAlign] (end). |
| `disabledContentOpacity` | `double?` | Opacity of the card's content — the title, the rows and the bottom action region, with their icons and dividers — while the card is disabled (`enabled: false` on a card with a tap target). The background and border stay at full strength. Defaults to [defaultDisabledContentOpacity]. |
| `emphasizedLabelTextStyle` | `CoreTextStyle?` | Emphasised label text slot style (applied to rows with `isEmphasized: true`). |
| `emphasizedValueTextStyle` | `CoreTextStyle?` | Emphasised value text slot style (applied to rows with `isEmphasized: true`). |
| `clickableStyle` | `CoreClickableStyle?` | Style for the `Clickable` used when the card or a row is tappable — press scale, durations, focus ring, disabled opacity. Laid over [defaultClickableStyle] and passed to the `Clickable` as is; the `Clickable` fills in the remaining defaults. |

### `CoreDescriptionCardStyle` 변형별 기본값 (`CoreDescriptionCardVariantStyle`)

| 필드 | `filled` | `outlined` | `ghost` |
|------|------|------|------|
| `backgroundColor` | surfaceContainer | surface | null |
| `borderWidth` | 0 | stroke1 | 0 |
| `borderColor` | — | outlineVariant | — |
| `padsHorizontally` | — | — | false |

<!-- STYLE_TABLE:END -->

<Note>

표의 설명과 함께 알아 둘 지금 동작입니다.

- `labelTextStyle` · `valueTextStyle` · `emphasizedLabelTextStyle` · `emphasizedValueTextStyle` 과 행의 글자 스타일은 `fontSize` · `fontWeight` · `fontFamily` · `letterSpacing` · `lineHeight` 처럼 직접 적은 값을 반영합니다. 역할 토큰(`CoreTextStyle.token`)은 `color` 만 반영하고 토큰이 가리키는 글자 모양은 적용하지 않습니다.
- `boxShadow` 로 준 그림자는 `borderRadius` 를 따르지 않고 직각 모서리로 그려집니다.
- `shadowBaseColor` 는 `boxShadow` 를 직접 준 경우에만 그림자에 쓰입니다.
- Flutter 와 Web 은 `titleColor` 와 `titleTextStyle.color` 를 함께 적었을 때의 우선순위가 다릅니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="description-card/related-card" title="Card">

라벨과 값의 행이 아니라 자유로운 내용을 담는 상자입니다.

</Card>
<Card demo="description-card/related-stat" title="Stat">

핵심 수치 하나를 크게 보입니다.

</Card>
<Card demo="description-card/related-table" title="Table">

여러 건의 데이터를 행과 열로 맞춰 비교합니다.

</Card>
<Card demo="description-card/related-definition-list" title="DefinitionList">

카드 상자 없이 용어와 설명의 짝을 나열합니다.

</Card>
</Cards>
