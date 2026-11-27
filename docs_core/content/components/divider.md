---
title: Divider
description: 내용 묶음 사이를 가르는 선입니다. 가로 · 세로 방향이 있고, 선 사이에 "또는" 같은 라벨을 둘 수 있습니다.
category: display
platforms: [flutter, web]
related: [gap, resizable]
tags: [layout, visual-separator]
template: v2
source: display/divider
---

# Divider

<a id="live-preview"></a>
<a id="기본-사용법"></a>

## 플레이그라운드

속성을 바꿔 보며 구분선을 확인하고, 만들어진 코드를 그대로 복사하세요. 아무 값도 주지 않은 `Divider()` 는 부모의 폭을 채우는 가로선입니다.

<Playground component="divider" />

<Note>

무대의 글자와 부모 레이아웃은 선이 놓일 자리를 보여 주려고 둔 것입니다. 부모를 만드는 코드는 Flutter(`Column` · `Row`)와 Web(flex `div`)이 다릅니다. `child 위치` 를 `none` 으로 두면 라벨 없는 선이 됩니다.

</Note>

## 구조

라벨이 없는 구분선은 선 하나입니다. `child` 를 넣으면 앞 선 · 라벨 · 뒤 선으로 나뉩니다.

<Anatomy demo="divider/anatomy">
<AnatomyItem part="container" name="Container">

선과 라벨이 함께 놓이는 상자입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part='divider'] > div:first-child" side="top" name="leading line">

라벨 앞의 선입니다. `indent` 는 이 선의 시작 쪽을 줄입니다.

</AnatomyItem>
<AnatomyItem part="label" name="child">

라벨 슬롯입니다. 라벨과 선 사이의 여백은 `childPadding` 이 정합니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part='divider'] > div:last-child" side="top" name="trailing line">

라벨 뒤의 선입니다. `endIndent` 는 이 선의 끝 쪽을 줄입니다.

</AnatomyItem>
</Anatomy>

<a id="web-dom-구조-라벨이-있을-때"></a>

### Web 마크업

Web 의 라벨 없는 구분선은 `<div>` 하나입니다. 라벨이 있으면 바깥 `<div>` 가 격자(grid)가 되고, 그 안의 세 요소가 트랙을 하나씩 차지합니다. 아래는 기본 색과 기본 정렬의 가로선입니다.

```html
<!-- 라벨 없음 -->
<div class="shrink-0 w-full bg-outline-variant"
     style="height: …; margin-inline-start: …; margin-inline-end: …"></div>

<!-- 라벨 있음 -->
<div class="grid w-full items-center"
     style="grid-template-columns: minmax(0, 1fr) auto minmax(0, 1fr)">
  <div class="bg-outline-variant" style="height: …; margin-inline-start: …"></div>
  <div style="padding-left: …; padding-right: …">라벨</div>
  <div class="bg-outline-variant" style="height: …; margin-inline-end: …"></div>
</div>
```

- 비율이 있는 선 조각의 트랙은 `minmax(0, 1fr)` 입니다. 최솟값이 `0` 이라 라벨이 축 전체를 차지해도 선의 `margin` 이 트랙을 붙들지 않습니다. 비율이 0 인 조각의 트랙은 `auto` 이고, 길이가 그 조각의 여백이 됩니다.
- 가운데 트랙(`auto`)의 길이는 라벨을 따릅니다.
- 선의 여백은 `margin` 이고 트랙 안에 있습니다. 선은 트랙에서 자기 `margin` 을 뺀 만큼만 늘어나므로, 여백이 트랙의 비율을 바꾸지 않습니다.
- 가로선의 읽기 방향은 `dir` 이 정합니다. 격자의 첫 트랙과 `margin-inline-start` 가 같은 방향을 따르므로, `dir="rtl"` 에서는 앞 선이 오른쪽에 놓이고 `indent` 만큼 오른쪽에서 들여씁니다.
- 세로선은 `grid justify-items-center h-full` 과 `grid-template-rows` 를 쓰고, 여백은 `margin-top` · `margin-bottom` 입니다.
- 라벨 없는 선에 `indent` 나 `endIndent` 를 주면 `w-full` · `h-full` 대신 `calc(100% - 두 여백)` 길이를 인라인으로 정합니다. `100%` 에 `margin` 을 더하면 선이 반대쪽 가장자리 밖으로 넘치기 때문입니다.

## 방향

`orientation` 은 선이 놓이는 방향입니다. 선은 한 축을 부모만큼 채우고, 다른 축의 크기는 `thickness` 입니다.

| 값 | 채우는 길이 | `thickness` 가 정하는 것 |
| --- | --- | --- |
| `horizontal` (기본) | 부모의 폭 | 선의 높이 |
| `vertical` | 부모의 높이 | 선의 폭 |

<Preview demo="divider/orientation" />

세로선은 높이가 정해진 부모 안에 둡니다. 부모를 만드는 코드는 플랫폼마다 다릅니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
SizedBox(
  height: CoreSpace.space64,
  child: Divider(orientation: CoreDividerOrientation.vertical),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(
  [Divider(orientation: CoreDividerOrientation.vertical)],
  styles: Styles(raw: {'height': '${CoreSpace.space64}px'}),
)
```

  </TabItem>
</Tabs>

<a id="동작-스펙-behavior"></a>

## 라벨

`child` 슬롯(Flutter `Widget`, Web Jaspr `Component`)에 넣은 내용이 두 선 사이에 놓입니다. `Divider` 는 라벨의 글자 모양을 따로 정하지 않으므로 넣는 쪽에서 정합니다.

```dart
Divider(child: Text('또는').labelMedium.onSurfaceVariant)
```

### 라벨 위치

라벨은 라벨 여백까지 자기 길이를 그대로 갖고, 두 선 조각이 남은 길이를 나눠 갖습니다. `dividerStyle` 의 `childAlignment` 가 그 비율을 정합니다.

<Preview demo="divider/label-alignment" />

| 값 | 앞 조각 : 뒤 조각 | 결과 |
| --- | --- | --- |
| `center` (기본) | 1 : 1 | 두 조각의 길이가 같습니다. |
| `start` | 0 : 1 | 라벨이 시작 쪽으로 붙습니다. |
| `end` | 1 : 0 | 라벨이 끝 쪽으로 붙습니다. |

비율이 0 인 쪽에는 선이 그려지지 않고, 그 조각의 길이는 그쪽 여백(`indent` 또는 `endIndent`)과 같습니다. 가로선의 `start` · `end` 는 읽기 방향을 따르므로 오른쪽에서 왼쪽으로 읽는 환경에서는 좌우가 바뀝니다. 세로선의 `start` 는 위, `end` 는 아래입니다.

라벨과 라벨 여백을 합친 길이가 상자보다 길면 두 선은 모두 길이가 0 이 됩니다. 이때 라벨이 놓이는 위치는 [플랫폼 차이](#플랫폼-차이)에 있습니다.

### 라벨 여백

`childPadding` 은 라벨과 선 사이의 여백이고, 기본값은 `CoreEdgeInsets.symmetric(horizontal: CoreSpace.space8)` 입니다. 두 방향 모두 `horizontal` 값으로 정합니다. 세로선은 그 값을 라벨의 위 · 아래에 둡니다.

```dart
Divider(
  dividerStyle: CoreDividerStyle(
    childPadding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16),
  ),
  child: Text('또는').labelMedium.onSurfaceVariant,
)
```

<Note>

`childPadding` 은 `CoreEdgeInsets.symmetric(horizontal: …)` 모양으로 넘기세요. 두 플랫폼이 같은 모양으로 그리는 것은 `directional` 로 만들지 않았고, `left` 와 `right` 가 같으며, `top` · `bottom` 이 0 인 값입니다. 그 밖의 값에서 Flutter 는 네 값을 모두 적용하고(세로선에서는 위와 왼쪽, 아래와 오른쪽을 맞바꿉니다), Web 은 `left` 값 하나를 라벨 앞뒤에 똑같이 둡니다. `CoreEdgeInsets.directional` 값은 Flutter 에서 라벨이 없어도 `ArgumentError` 가 납니다.

</Note>

## 들여쓰기

`dividerStyle` 의 `indent` 는 선이 시작하는 쪽, `endIndent` 는 끝나는 쪽의 여백입니다. 기본값은 둘 다 0 이고, 단위는 논리 픽셀입니다.

| 방향 | `indent` | `endIndent` |
| --- | --- | --- |
| 가로 | 읽기 시작 쪽 (왼쪽에서 오른쪽으로 읽으면 왼쪽) | 읽기 끝 쪽 |
| 세로 | 위 | 아래 |

<Preview demo="divider/indent" />

```dart
Divider(
  dividerStyle: CoreDividerStyle(
    indent: CoreSpace.space16,
    endIndent: CoreSpace.space16,
  ),
)
```

- 라벨이 없으면 선의 길이는 부모의 길이에서 두 여백을 뺀 값입니다.
- 라벨이 있으면 `indent` 는 앞 선에, `endIndent` 는 뒤 선에 적용됩니다.
- 비율이 있는 조각의 여백은 자기 조각 안에서 선만 줄이고 라벨은 움직이지 않습니다. 기본 정렬에서 라벨이 상자에 들어가고 라벨 여백이 앞뒤로 같으면, 두 여백이 달라도 라벨은 상자의 정중앙에 있습니다.
- `start` · `end` 정렬에서 비율이 0 인 쪽의 여백은 라벨을 그만큼 안쪽으로 밉니다.
- 조각의 길이가 여백보다 짧으면 그 선은 그려지지 않습니다.

<a id="사용-시기"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

- 목록의 항목 묶음이나 화면의 섹션 사이에 눈에 보이는 경계가 필요할 때
- 폼이나 설정 화면에서 성격이 다른 항목을 가를 때
- "또는"처럼 라벨을 단 구분선이 필요할 때

<Cards columns="2">
<Card demo="divider/do-group" tone="do" eyebrow="이렇게 하세요" title="묶음의 경계에 둡니다">

성격이 다른 묶음 사이에만 선을 둡니다.

</Card>
<Card demo="divider/dont-every-row" tone="dont" eyebrow="이렇게 하지 마세요" title="줄마다 넣지 않습니다">

모든 줄 사이에 선이 있으면 어디가 묶음의 경계인지 알기 어렵습니다.

</Card>
</Cards>

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 선 없이 빈 자리만 필요할 때 | [Gap](/components/gap) |
| 끌어서 영역의 크기를 바꾸는 경계일 때 | [Resizable](/components/resizable) |
| `Menu` 안에서 항목 묶음을 나눌 때 | `CoreMenuItem.divider()` 항목. `Menu` 가 `Divider` 를 대신 그립니다. |

<a id="dont"></a>

### 의미가 있는 경계

`orientation` 은 선의 방향만 정합니다. 세로선으로 바꿔도 보조 기술에 구분선으로 알려지지 않습니다. 묶음의 경계라는 뜻까지 전해야 하면 `semantic: true` 를 줍니다. 플랫폼마다 붙는 정보는 접근성의 [역할](#역할)에 있습니다.

```dart
Divider(semantic: true)
```

<a id="do"></a>

## 배치

구분선은 자기 방향의 길이를 부모에게서 받습니다. 그 길이를 정해 주지 않는 부모 안에서는 따로 처리가 필요합니다.

### 세로선의 높이

Flutter 에서는 높이 제한이 없는 자리(`Column` 바로 아래의 `Row`, 세로 스크롤 안의 `Row` 등)에 둔 세로선은 길이가 0 이 됩니다. 에러는 나지 않습니다. `SizedBox` 로 높이를 정하거나, 옆 내용의 높이에 맞추려면 `IntrinsicHeight` 로 `Row` 를 감쌉니다. Web 의 세로선은 `height: 100%` 를 기준으로 하므로 부모에 높이를 정합니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: CoreSpace.space12,
    children: [
      Text('왼쪽'),
      Divider(orientation: CoreDividerOrientation.vertical),
      Text('오른쪽'),
    ],
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(
  [
    Text('왼쪽'),
    Divider(orientation: CoreDividerOrientation.vertical),
    Text('오른쪽'),
  ],
  classes: 'flex items-center gap-space12',
  styles: Styles(raw: {'height': '${CoreSpace.space24}px'}),
)
```

  </TabItem>
</Tabs>

### 행 안의 가로선

행에 라벨 없는 가로선을 그대로 넣으면 의도대로 놓이지 않습니다. Flutter 의 `Row` 는 `Expanded` 같은 래퍼가 없는 자식의 폭을 제한하지 않아 선의 길이가 0 이 됩니다. Web 의 선은 컨테이너 전체를 기준으로 폭을 잡고 줄어들지 않아(`shrink-0`), 옆 요소와 합치면 행을 넘칠 수 있습니다. 남은 폭만 채우려면 선을 감쌉니다.

<Preview demo="divider/in-row" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Row(
  spacing: CoreSpace.space12,
  children: [
    Text('이전 기록'),
    Expanded(child: Divider()),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(
  [
    Text('이전 기록'),
    div([Divider()], classes: 'flex-1'),
  ],
  classes: 'flex items-center gap-space12',
)
```

  </TabItem>
</Tabs>

### 굵기 방향의 크기를 고정하는 부모

Flutter 에서는 부모가 선의 굵기 방향 크기를 하나로 고정하면, 라벨 없는 선이 `thickness` 대신 그 크기로 칠해집니다. `SizedBox(height: CoreSpace.space32, child: Divider())` 는 높이 32 의 띠가 되고, `Column` 안에서 `Expanded` 로 감싼 가로선도 남은 높이를 모두 칠합니다. 선 위아래에 빈 자리가 필요하면 선의 앞뒤에 [Gap](/components/gap) 을 두거나 `Padding` 을 씁니다. Web 은 선의 굵기를 CSS `height` · `width` 로 직접 정하므로 부모의 크기를 정해도 굵기가 그대로입니다.

### 내용 폭을 따르는 부모

부모가 내용의 폭을 따르면(Flutter `IntrinsicWidth`, Web 의 `inline-block` 등) 라벨 있는 가로선은 남는 폭을 스스로 만들지 못합니다. 기본 정렬에서 구분선이 필요로 하는 폭은 라벨과 라벨 여백에, `indent` 와 `endIndent` 중 큰 값의 두 배를 더한 값입니다. 부모 안에 이보다 넓은 다른 내용이 없고 두 여백이 0 이면 선이 보이지 않으므로, 선이 보여야 하면 부모의 폭을 정합니다.

<a id="색상-토큰"></a>

## 테마와 스타일

겉모습은 `dividerStyle: CoreDividerStyle(...)` 하나로 바꿉니다. 아무 값도 정하지 않으면 아래 기본값을 씁니다.

| 항목 | 필드 | 기본값 |
| --- | --- | --- |
| 선 색 | `color` | `CoreColors.outlineVariant` 토큰 |
| 선 굵기 | `thickness` | `CoreStrokeWidth.stroke1` (1) |
| 선 여백 | `indent` · `endIndent` | 0 |
| 라벨 위치 | `childAlignment` | `center` |
| 라벨 여백 | `childPadding` | 가로 값 8 |

`CoreColor.token(...)` 으로 정한 색은 라이트 · 다크 같은 테마의 색 구성을 따라 바뀌고, `CoreColor(0xFF…)` 처럼 직접 적은 색은 그대로입니다.

<Split>

<Code language="dart" title="Divider 하나만 바꾸기">
Divider(
  dividerStyle: CoreDividerStyle(
    color: CoreColor.token(CoreColors.primary),
    thickness: CoreStrokeWidth.stroke2,
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    divider: CoreDividerTheme(
      style: CoreDividerStyle(thickness: CoreStrokeWidth.stroke2),
    ),
  ),
)
</Code>

</Split>

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
CoreDividerStyle 의 default 값       // 디자인 시스템 기본값
  → CoreComponentTheme.divider.style // 앱 전체
  → dividerStyle                     // Divider 하나
```

값은 필드마다 따로 합칩니다. 뒤 단계에서 정하지 않은 필드에는 앞 단계의 값이 남습니다.

앱 전체 값은 `Command` 의 구분선처럼 다른 컴포넌트가 안에서 그리는 `Divider` 에도 닿습니다. 그 컴포넌트가 직접 정해 넘기는 필드는 그 값이 우선합니다. 예를 들어 `Menu` 는 구분선의 색을 직접 넘기므로, 앱 전체의 `color` 는 `Menu` 의 선에 적용되지 않습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Divider` 에 `withStyle` 로 스타일을 덧붙일 수 있습니다. 생성자의 `dividerStyle` 과 같은 필드를 받고, 이미 정한 필드와 겹치면 나중에 붙인 값이 이깁니다.

<Preview demo="divider/chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class DividerChainExample extends StatelessWidget {
  const DividerChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider().withStyle(
      const CoreDividerStyle(
        color: CoreColor.token(CoreColors.primary),
        thickness: CoreStrokeWidth.stroke4,
        indent: CoreSpace.space24,
        endIndent: CoreSpace.space24,
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class DividerChainExample extends StatelessComponent {
  const DividerChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Divider().withStyle(
      const CoreDividerStyle(
        color: CoreColor.token(CoreColors.primary),
        thickness: CoreStrokeWidth.stroke4,
        indent: CoreSpace.space24,
        endIndent: CoreSpace.space24,
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

기본 구분선은 장식입니다. `semantic: true` 를 준 구분선만 의미 있는 경계라는 정보를 더합니다.

### 역할

| 설정 | Flutter | Web |
| --- | --- | --- |
| `semantic: false` (기본) | 선과 배치에 시맨틱 정보를 더하지 않습니다. | `role` · `aria-*` 를 붙이지 않은 `<div>` 입니다. 직접 넘긴 `attributes` 만 붙습니다. |
| `semantic: true` | 이름을 가진 `Semantics(container: true)` 로 감쌉니다. 구분선을 뜻하는 역할이나 조절 컨트롤(`slider`) 표시는 붙이지 않습니다. | `role="separator"` 와 `aria-label` 을 붙입니다. |

이름은 로케일 문자열 `dividerSeparatorLabel` 입니다. 한국어는 `구분선`, 영어는 `Separator` 이고, 번역이 없는 언어는 영어를 씁니다. `Menu` 의 `CoreMenuItem.divider()` 항목은 두 플랫폼 모두 `semantic: true` 로 그립니다.

### 키보드

없음. 누르거나 조절하는 컨트롤이 아니라서 처리하는 키가 없습니다.

### 스크린 리더

`semantic: false` 인 선에는 읽을 정보가 없습니다. `child` 에 넣은 글자는 자기 접근성 정보를 그대로 갖지만, 양옆의 선이 구분선이라는 정보는 더해지지 않습니다. `semantic: true` 면 위의 이름이 경계에 붙습니다. 실제로 읽는 방식은 플랫폼과 스크린 리더에 따라 다를 수 있습니다.

### 포커스 관리

없음. 포커스를 받지 않고 포커스 링도 그리지 않습니다. Flutter 구현에는 `Focus` · `FocusNode` 가 없고, Web 은 `tabindex` 를 붙이지 않아 Tab 순서에 들어가지 않습니다.

### 알려진 제약

- **방향을 알리지 않습니다.** 두 플랫폼 모두 `orientation` 을 접근성 정보로 넘기지 않습니다. Web 에서 세로 방향까지 알려야 하면 `semantic: true` 와 함께 `attributes: {'aria-orientation': 'vertical'}` 를 넘깁니다. Flutter 의 `Divider` 에는 방향을 전할 파라미터가 없습니다.
- **이름을 바꾸는 파라미터가 없습니다.** `semantic: true` 면 Web 에서 `attributes` 로 넘긴 `role` · `aria-label` 은 컴포넌트의 값으로 덮입니다. 다른 이름이 필요하면 `semantic` 을 끈 채로, Web 은 `attributes` 에 `role` 과 `aria-label` 을 직접 넘기고 Flutter 는 `Semantics` 로 감쌉니다.
- **`semantic: true` 와 `child` 를 함께 쓸 때는 주의합니다.** Web 은 라벨까지 감싼 바깥 요소에 `role="separator"` 를 붙입니다. WAI-ARIA 는 이 역할의 자식을 표현용(children presentational)으로 정하므로, 라벨 글자가 따로 전달된다고 기대하지 마세요. 라벨이 읽혀야 하면 `semantic` 을 켜지 않습니다.
- **Web 에는 구분선을 위한 강제 색상 모드 규칙이 없습니다.** 선은 테두리가 아니라 배경색으로 그립니다. 그 모드를 지원해야 하면 실제 환경에서 선이 보이는지 확인하세요.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
// 이름을 직접 정하는 구분선
Semantics(
  container: true,
  label: '지난 알림',
  child: Divider(),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
// 이름을 직접 정하는 구분선
Divider(attributes: {'role': 'separator', 'aria-label': '지난 알림'})
```

  </TabItem>
</Tabs>

감소된 모션 · 고대비처럼 컴포넌트 전반에 걸친 항목은 [전역 접근성 축](/accessibility)을 참고하세요.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

파라미터 이름은 같고, 그리는 방식과 아래 항목이 다릅니다.

| 항목 | Flutter | Web |
| --- | --- | --- |
| 그리는 방식 | 색을 칠한 `Container` 와 `Padding`. 라벨이 있으면 `Row` · `Column` | `<div>` 하나. 라벨이 있으면 격자 `<div>` 안의 세 요소 |
| 라벨과 선의 배치 | `Flexible` 조각이 남은 길이를 나누고, 각 조각이 자기 여백을 가집니다. | 격자 트랙 하나가 조각 하나이고, 선의 `margin` 이 트랙 안에 있습니다. |
| 가로선의 여백 방향 | `EdgeInsetsDirectional` 의 `start` · `end` | CSS `margin-inline-start` · `margin-inline-end` |
| 세로선의 부모 높이가 정해지지 않았을 때 | 선의 길이가 0 이고 에러는 나지 않습니다. | `height: 100%` 의 기준이 되는 높이가 필요합니다. |
| 부모가 굵기 방향 크기를 고정했을 때 | 라벨 없는 선이 그 크기로 두꺼워집니다. | 직접 정한 CSS 굵기를 씁니다. |
| 라벨이 상자보다 길 때 | 가로선의 글자 라벨은 줄이 바뀌지 않고, 레이아웃 넘침 오류가 보고됩니다. 가로선은 오른쪽에서 왼쪽으로 읽는 환경에서도 왼쪽 가장자리부터 놓입니다. | 오류 보고 없이 읽기 시작 쪽부터 놓입니다. 글자 라벨은 상자 폭 안에서 줄을 바꿀 수 있습니다. |
| 의미 있는 경계 | 이름 붙은 `Semantics` 컨테이너 | `role="separator"` 와 `aria-label` |
| `childPadding` | 네 값을 모두 적용합니다. | `left` 값 하나를 라벨 앞뒤에 둡니다. |
| `CoreEdgeInsets.directional` 인 `childPadding` | `ArgumentError` 가 납니다. | `start` 값을 라벨 앞뒤에 둡니다. |
| 밀도 | `indent` · `endIndent` · `childPadding` 이 밀도를 따라 움직입니다. 4 이하는 그대로입니다. | `CoreSpace` 단계의 값만 밀도를 따라 움직입니다. 단계 밖 숫자는 그대로입니다. |
| 테마의 크기 배율(`scaling`) | 굵기 · 선 여백 · 라벨 여백에 곱합니다. | 배율을 곱하지 않습니다. 여백은 `rem`, 굵기는 `px` 기준입니다. |
| 표면 스타일의 선 굵기 하한 | 0 이 아닌 모든 `thickness` 에 적용합니다. | `CoreStrokeWidth` 단계의 값에만 적용합니다. |
| 웹 전용 파라미터 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="레거시-vs-통일-비교-migration-notes"></a>

## 이전 API 에서 옮기기

이전 버전의 CoUI 를 쓰던 코드에는 선을 그리던 `Separator` 가 남아 있을 수 있습니다. 지금 두 플랫폼 패키지에는 `Separator` 위젯이 없고, 그 자리에는 `Divider` 를 씁니다.

| 옮기는 것 | `Divider` 에서 쓰는 곳 |
| --- | --- |
| 선 색 | `dividerStyle` 의 `color` |
| 선 굵기 | `dividerStyle` 의 `thickness` |
| 양쪽에 같은 여백 | `dividerStyle` 의 `indent` 와 `endIndent` 에 같은 값 |
| 양쪽이 다른 여백 | `indent` 와 `endIndent` 를 따로 |
| 선 사이의 글 | `child` |

```dart
Divider(
  dividerStyle: CoreDividerStyle(
    color: CoreColor.token(CoreColors.outline),
    thickness: CoreStrokeWidth.stroke2,
    indent: CoreSpace.space16,
    endIndent: CoreSpace.space16,
  ),
)
```

<a id="props"></a>
<a id="props-parameters"></a>

## API

공통 파라미터는 두 플랫폼의 이름이 같고, 슬롯 타입은 Flutter 가 `Widget`, Web 이 Jaspr `Component` 입니다. 비활성 · 선택 같은 상태나 누름 콜백 파라미터는 없습니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `orientation` | `CoreDividerOrientation` | `CoreDividerOrientation.horizontal` | 선의 방향 |
| `child` | `Widget?` · `Component?` | `null` | 선 사이에 놓는 라벨 슬롯 |
| `dividerStyle` | `CoreDividerStyle?` | `null` | 색 · 굵기 · 여백 · 라벨 위치 · 라벨 여백 |
| `semantic` | `bool` | `false` | 장식이 아니라 의미 있는 경계로 알릴지 |
| `key` | `Key?` | `null` | 위젯 · 컴포넌트의 키 |

Web 의 `Divider` 는 `id` · `classes` · `css` · `attributes` · `eventHandlers` 도 받습니다. 모두 바깥 요소에 붙으며, 라벨이 있으면 그 요소는 선과 라벨을 담는 격자 `<div>` 입니다.

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreDividerStyle patch)` | `dividerStyle` 에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다. |
| `copyWith({orientation, child, dividerStyle, semantic, key})` | 준 값을 바꾼 사본을 만듭니다. `null` 로 넘긴 값은 기존 값이 남습니다. Web 은 `id` · `classes` · `css` · `attributes` · `eventHandlers` 도 받고, `classes` 는 기존 값에 더해집니다. |

### 값 타입

- `CoreDividerOrientation`: `horizontal` · `vertical`
- `CoreDividerChildAlignment`: `center` · `start` · `end`

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.divider` | `CoreDividerTheme?` | `Divider` 의 앱 전체 설정 |
| `CoreDividerTheme.style` | `CoreDividerStyle?` | 모든 `Divider` 에 먼저 적용하는 스타일 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreDividerStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `color` | `CoreColor?` | Divider line colour override. |
| `thickness` | `double?` | Line thickness in logical pixels. |
| `indent` | `double?` | Start-side inset of the line, in logical pixels. |
| `endIndent` | `double?` | End-side inset of the line, in logical pixels. |
| `childAlignment` | `CoreDividerChildAlignment?` | Where the optional centered child sits along the divider main axis. Logical, so `start` / `end` follow the reading direction. Only observable when the divider has a child — a childless divider has no label to place. |
| `childPadding` | `CoreEdgeInsets?` | Padding around the optional centered child, applied along the divider's main axis only — it follows the divider's orientation. |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 `childPadding` 설명은 선 방향에만 적용된다고 적혀 있지만 지금 동작은 다릅니다. Flutter 는 네 값을 모두 적용하고 Web 은 `left` 값 하나만 읽습니다. 자세한 규칙은 [라벨 여백](#라벨-여백)에 있습니다.

</Note>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="divider/related-gap" title="Gap">

선 없이 빈 자리만 둡니다.

</Card>
<Card demo="divider/related-resizable" title="Resizable">

끌어서 영역의 크기를 바꾸는 경계입니다.

</Card>
</Cards>
