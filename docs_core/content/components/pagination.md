---
title: Pagination
description: 대용량 콘텐츠를 여러 페이지로 나누어 탐색하는 페이지네이션 컴포넌트
category: navigation
platforms: [flutter, web]
related: [table, select]
tags: [pagination, navigation, list, table]
template: v2
source: navigation/pagination
---

# Pagination

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 페이지 줄을 확인하고, 만들어진 코드를 그대로 복사하세요. 번호 · 화살표 · `…` 를 누르면 그 페이지로 옮겨 갑니다. '좁은 폭' 을 켜면 폭에 맞춰 버튼이 줄어드는데, 코드는 바뀌지 않습니다.

<Playground component="pagination" />

`Pagination` 은 현재 페이지를 스스로 바꾸지 않습니다. `page`(1부터 셉니다)를 넘기고, `onPageChanged` 가 알려 주는 번호로 바꿔 다시 그립니다. 버튼 줄만 그리므로 데이터를 페이지로 나누고 불러오는 일은 호출하는 쪽이 합니다.

```dart
Pagination(
  page: page,
  totalPages: 10,
  onPageChanged: (next) => setState(() => page = next),
)
```

Flutter 와 Jaspr Web 이 같은 코드를 씁니다.

## 구조

이전 · 다음 화살표 사이에 페이지 번호와 생략 버튼(`…`)이 한 줄로 놓입니다. 번호 · `…` · 화살표 버튼은 36 정사각형(모서리 8)이고 버튼 사이는 4 입니다. 글자를 붙인 이전 · 다음만 [폭이 글자를 따릅니다](#이전-다음-라벨). 화살표는 16 크기이며 번호와 같은 색입니다.

<Anatomy demo="pagination/anatomy">
<AnatomyItem part="container" name="container">

버튼을 늘어놓는 줄입니다. 줄 자체에는 바탕과 테두리가 없습니다.

</AnatomyItem>
<AnatomyItem select="[role=button]" side="top" name="previous">

이전 페이지로 가는 화살표입니다.

</AnatomyItem>
<AnatomyItem select="[role=button] + [role=button]" side="top" name="first page">

번호 창 앞에 두 페이지 이상 숨었을 때 두는 1 페이지 버튼입니다. 뒤쪽의 마지막 페이지 버튼도 같은 규칙입니다. 처음 · 끝 페이지에는 예외가 있습니다([알려진 제약](#알려진-제약)).

</AnatomyItem>
<AnatomyItem select="[aria-current=page]" side="top" name="current page">

현재 페이지입니다. `primary` 로 채우고 숫자를 SemiBold 로 굵게 그립니다.

</AnatomyItem>
<AnatomyItem select="[aria-current=page] + [role=button] + [role=button]" side="top" name="ellipsis">

숨은 페이지를 대신하는 `…` 입니다. 누르면 번호 창에 가장 가까운 숨은 페이지로 옮겨 갑니다(예외는 [알려진 제약](#알려진-제약)).

</AnatomyItem>
<AnatomyItem select="[role=button]:last-child" side="right" name="next">

다음 페이지로 가는 화살표입니다.

</AnatomyItem>
</Anatomy>

<a id="변형-variants"></a>

## Variant

모양은 `standard`(`CorePaginationVariant`) 하나입니다. 보이는 페이지의 범위와 이전 · 다음 글자는 variant 가 아니라 [보이는 버튼](#보이는-버튼)의 속성으로 정합니다. `variant` 값은 앱 전체 테마의 `variantStyles` 를 찾는 키이기도 합니다.

<Preview component="pagination" props="page=2;totalPages=10" />

<Note>

Figma 의 `Variant=compact` 는 캔버스 전용이며 코드에 대응하는 값이 없습니다. 코드는 현재 페이지와 받은 폭에 따라 보이는 버튼을 스스로 줄입니다. `compact` 는 위 미리보기(`page: 2`, `totalPages: 10`)의 모양을 캔버스에 그려 둔 것입니다.

</Note>

## 보이는 버튼

번호 창은 현재 페이지를 가운데에 두고 `maxPages`(기본 3)개의 번호를 보여 줍니다. 앞이나 끝에서는 창이 1 페이지나 마지막 페이지에 붙고, 전체가 `maxPages` 이하면 모든 번호를 보여 줍니다. 현재 페이지가 창 가운데에 올 때는 창 밖에 페이지가 남은 쪽에 `…` 를 두고, 두 페이지 이상 남은 쪽에는 `…` 바깥에 1 페이지나 마지막 페이지 버튼도 둡니다.

아래는 `totalPages: 10`, `maxPages: 3` 일 때의 줄입니다. 대괄호는 현재 페이지입니다.

| `page` | 보이는 줄 |
| --- | --- |
| 1 | `‹ [1] 2 3 … 10 ›` |
| 2 | `‹ 1 [2] 3 … 10 ›` |
| 3 | `‹ … 2 [3] 4 … 10 ›` |
| 5 | `‹ 1 … 4 [5] 6 … 10 ›` |
| 8 | `‹ 1 … 7 [8] 9 … ›` |
| 10 | `‹ 1 … 8 9 [10] ›` |

<Preview demo="pagination/window" />

`maxPages` 는 홀수로 둡니다. 짝수일 때와, 현재 페이지를 창 가운데에 둘 수 없는 처음 · 끝 페이지에서는 `…` 와 첫 · 마지막 페이지 버튼이 위 설명과 다르게 놓일 수 있습니다([알려진 제약](#알려진-제약)).

### 첫 · 마지막 페이지 버튼

`showSkipToFirstPage` 와 `showSkipToLastPage` 는 둘 다 기본으로 켜져 있습니다. 끄면 그쪽에는 `…` 만 남습니다. 현재 페이지가 번호 창 가운데에 올 때, 숨은 페이지가 하나뿐인 쪽에는 켜 두어도 버튼 없이 `…` 만 두고 그 `…` 가 숨은 페이지로 옮깁니다. 처음 · 끝 페이지는 다르게 그릴 수 있습니다([알려진 제약](#알려진-제약)).

### 끝에서 화살표 숨기기

기본값에서는 첫 페이지의 이전 화살표와 마지막 페이지의 다음 화살표가 흐려진 채 남습니다. `hidePreviousOnFirstPage` 나 `hideNextOnLastPage` 를 켜면 그 화살표를 그리지 않습니다.

### 이전 · 다음 라벨

`showLabel: true` 면 화살표 옆에 로케일의 '이전' · '다음' 글자를 붙입니다. 이 두 버튼은 높이 36 을 지키고 폭은 글자에 맞춥니다(좌우 여백 12, 화살표와 글자 사이 4).

<Preview component="pagination" props="page=2;totalPages=3;showLabel=true" />

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>
<a id="상태-전환"></a>

## 상태

<Preview demo="pagination/states" />

<Note>

CoUI 기본 테마에서 비활성 현재 페이지의 바탕(`disabledContainer`)은 `surfaceContainer` 와 같은 색입니다. 그래서 `surfaceContainer` 로 채운 면(네이티브 문서 앱의 무대가 그렇습니다) 위에서는 비활성인 현재 페이지의 바탕이 구분되지 않고 흐린 숫자만 보입니다. `surface` 바탕인 웹 문서의 미리보기에서는 바탕이 보입니다.

</Note>

| 상태 | 모습 |
| --- | --- |
| 쉴 때 | 번호와 화살표는 `onSurfaceVariant`, `…` 는 `onSurfaceSubtle` 입니다. 바탕은 없습니다. 번호와 `…` 는 `bodyMedium`(14 Regular)입니다. |
| 현재 페이지 | `primary` 채움, `onPrimary` 글자, `labelLarge`(14) SemiBold. 포인터를 올려도 색이 바뀌지 않습니다. |
| Hover | `surfaceContainerHigh` 채움과 `onSurface` 글자입니다. Web 의 `…` 는 바뀌지 않습니다. |
| 눌림 | 누르는 동안 버튼이 97% 크기로 줄어듭니다. |
| 포커스 | 키보드로 포커스하면 버튼 바깥에 2 만큼 띄운 2 두께의 링을 그립니다. 기본값에서 링의 바깥 모서리는 12(버튼 모서리 8 에 링이 나간 거리 4 를 더한 값)이고, 링을 포함한 높이는 44 입니다. |
| 끝의 화살표 | 첫 페이지의 이전과 마지막 페이지의 다음은 50% 로 흐려지고 눌리지 않습니다. |
| 비활성 | 모든 번호 · `…` · 화살표가 `disabledContent`, 현재 페이지는 `disabledContainer` 채움입니다. 흐림을 겹치지 않고, 포인터와 키보드에 반응하지 않습니다. |

각 버튼의 동작은 다음과 같습니다.

- **번호 버튼**: 그 번호로 `onPageChanged` 를 부릅니다. 현재 페이지를 다시 눌러도 같은 번호로 부릅니다.
- **이전 · 다음**: 현재 페이지에서 1 을 빼거나 더한 번호를 알립니다.
- **첫 · 마지막 페이지 버튼**: 1 이나 `totalPages` 를 알립니다.
- **`…`**: 번호 창에 가장 가까운 숨은 페이지의 번호를 알립니다([알려진 제약](#알려진-제약)의 예외가 있습니다).

`enabled` 를 주지 않으면 `onPageChanged` 가 있을 때만 켜집니다. 그래서 `onPageChanged` 가 없는 `Pagination` 은 전체가 비활성 모양이 됩니다. `onPageChanged` 없이 `enabled: true` 를 주면 두 플랫폼이 다르게 그립니다([플랫폼 차이](#플랫폼-차이)).

<a id="애니메이션"></a>

### 전환 시간

색 전환은 150ms(`hoverDuration` 으로 바꿉니다), 눌러서 줄어드는 전환은 100ms 입니다. 동작 줄이기를 켜면 전환 없이 바로 바뀝니다. 페이지를 바꿀 때 따로 도는 애니메이션은 없고, 버튼의 색만 같은 150ms 전환을 따릅니다. 페이지 내용의 전환은 호출하는 쪽이 만듭니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

테이블 · 검색 결과 · 상품 목록처럼 많은 데이터를 페이지로 나누고, 원하는 페이지 번호로 바로 갈 수 있어야 할 때 씁니다. 행과 열을 그리는 일은 [Table](/components/table)이 맡고, 데이터를 나누고 불러오는 일은 호출하는 쪽이 합니다. 페이지가 많으면 첫 · 마지막 페이지 버튼(기본 켜짐)을 끄지 않고 두어, 번호 창에서 먼 1 페이지나 마지막 페이지로 바로 갈 수 있게 합니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 적은 수의 슬라이드 위치를 점으로 보여 줄 때 | [DotIndicator](/components/dot-indicator) |
| 이름이 붙은 보기를 바꿔 가며 볼 때 | [Tabs](/components/tabs) |
| 목록을 아래로 당겨 새로 고칠 때 | [RefreshTrigger](/components/refresh-trigger) |

<a id="do"></a>
<a id="dont"></a>

### 권장과 금지

<Cards columns="2">
<Card demo="pagination/do-multiple-pages" tone="do" eyebrow="이렇게 하세요">

페이지가 둘 이상일 때만 둡니다. 호출하는 쪽에서 `totalPages > 1` 일 때만 놓습니다.

</Card>
<Card demo="pagination/dont-single-page" tone="dont" eyebrow="이렇게 하지 마세요">

데이터가 한 페이지에 다 들어오면 두지 않습니다. 번호 하나와 눌리지 않는 화살표 둘만 남습니다.

</Card>
<Card tone="do" eyebrow="이렇게 하세요">

좁은 화면이 흔하면 `maxPages` 를 작게 둡니다. 폭이 모자라면 번호 창은 중간 크기를 거치지 않고 현재 페이지 하나로 줄어들므로, 작은 창일수록 번호가 오래 남습니다. 첫 · 마지막 페이지 버튼은 기본으로 켜져 있고, 좁아질 때는 번호 창보다 먼저 빠집니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

`maxPages` 를 짝수로 두지 않습니다. 번호 창과 `…` 가 어긋나 어떤 페이지는 줄에서 빠집니다. 3 · 5 · 7 처럼 홀수를 씁니다.

</Card>
</Cards>

## 배치

줄을 원하는 자리에 두는 방법은 플랫폼마다 다릅니다. Flutter 의 줄은 버튼이 차지하는 폭만큼이라 `Center` · `Align` 으로 자리를 정합니다. Web 의 줄 바깥은 flex `<div>` 라서 블록 부모 안에서는 부모 폭을 채우고 버튼이 왼쪽에 모입니다. 가운데에 두려면 레이아웃 클래스를 줍니다.

<Split>

<Code language="dart" title="Flutter — 가운데">
Center(
  child: Pagination(
    page: page,
    totalPages: 10,
    onPageChanged: handlePageChanged,
  ),
)
</Code>

<Code language="dart" title="Jaspr Web — 가운데">
Pagination(
  page: page,
  totalPages: 10,
  onPageChanged: handlePageChanged,
  classes: WebLayout.justifyCenter,
)
</Code>

</Split>

### 가용 폭에 맞추기

줄이 받은 폭보다 넓어지면, 넘치지 않도록 아래 순서로 하나씩 더 내려놓고 폭에 들어가는 첫 단계를 그립니다. 두 플랫폼이 같은 순서를 씁니다(`CorePaginationLayout.ladder`). 표의 예는 `page: 5`, `totalPages: 10`, `showLabel: true` 입니다.

| 단계 | 더 내려놓는 것 | 보이는 줄 |
| --- | --- | --- |
| 1 | 없음 | `‹ 이전 · 1 … 4 [5] 6 … 10 · 다음 ›` |
| 2 | 이전 · 다음 글자(접근성 이름으로는 남습니다) | `‹ 1 … 4 [5] 6 … 10 ›` |
| 3 | 첫 · 마지막 페이지 버튼 | `‹ … 4 [5] 6 … ›` |
| 4 | 번호 창을 현재 페이지 하나로 | `‹ … [5] … ›` |
| 5 | `…` | `‹ [5] ›` |

- 앞 단계보다 좁아지지 않는 단계는 건너뜁니다. 예를 들어 글자가 없는 줄에서 2단계는 건너뜁니다.
- 가장 좁은 단계도 들어가지 않으면 그 단계를 그대로 그립니다.
- 폭이 다시 넓어지면 넓은 단계로 돌아갑니다. 버튼 크기 · 간격 · 여백은 바뀌지 않고 버튼의 수와 글자만 바뀝니다.
- Flutter 에서 `Row` 안에 그대로 두거나 가로 스크롤 안에 두면 받는 폭이 무한이라 줄이지 않습니다. `Row` 안에서는 `Expanded` 나 `Flexible` 로 감쌉니다.
- Web 은 브라우저에서 깨어난 뒤에 폭을 잽니다. 서버에서만 그린 화면은 줄이지 않은 첫 단계입니다. 어느 상자의 폭을 재는지는 [플랫폼 차이](#플랫폼-차이)를 봅니다.

<a id="스타일-시스템-style-system"></a>
<a id="파라미터와-스타일"></a>
<a id="시맨틱-vs-스타일"></a>

## 테마와 스타일

페이지 · 동작 · 보이는 버튼은 위젯 속성으로 정하고, 겉모습(색 · 크기 · 간격)은 `paginationStyle`(`CorePaginationStyle`) 하나로 바꿉니다. 페이지 버튼은 [Button](/components/button) 컴포넌트를 쓰지 않고 `Clickable` 위에 그리므로, Button 의 스타일과 테마는 닿지 않습니다.

<Split>

<Code language="dart" title="Pagination 하나만 바꾸기">
Pagination(
  page: page,
  totalPages: 20,
  onPageChanged: handlePageChanged,
  paginationStyle: CorePaginationStyle(
    buttonSize: CoreSize.size40,
    buttonRadius: CoreBorderRadius.all(CoreRadius.radius12),
    clickableStyle: CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    pagination: CorePaginationTheme(
      style: CorePaginationStyle(
        activeBackgroundColor: CoreColor.token(CoreColors.tertiary),
        activeTextStyle: CoreTextStyle(
          color: CoreColor.token(CoreColors.onTertiary),
        ),
      ),
    ),
  ),
)
</Code>

</Split>

바꿀 때 알아 둘 점입니다.

- 포커스 링의 모서리는 `buttonRadius` 가 아니라 `clickableStyle.borderRadius` 를 따릅니다. 링의 바깥 모서리는 그 값(기본 8)에 링이 나간 거리 4 를 더한 값(기본 12)입니다. `buttonRadius` 를 바꾸면 `clickableStyle.borderRadius` 도 함께 바꿉니다.
- `textStyle` · `activeTextStyle` · `hoverTextStyle` 은 `color` 만 읽습니다. 쉬는 번호 · 현재 페이지 · hover 의 글자 색을 각각 정합니다.
- `buttonTextStyle` 은 모든 번호 · `…` · 이전 · 다음 글자의 글꼴을 정하고 색은 쓰지 않습니다. 현재 페이지에도 먼저 적용되고, `activeButtonTextStyle` 은 현재 페이지에만 그 위에 얹힙니다.
- `role`(`CoreSurfaceRole`)은 재질이 있는 서페이스 스타일에서 현재 페이지 버튼이 어떤 재질을 받는지 정합니다. 접근성 역할과는 별개입니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Pagination` 에 스타일을 덧붙이려면 `withStyle` 체인을 씁니다. 생성자의 `paginationStyle` 인자와 같게 동작합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class PaginationChainExample extends StatefulWidget {
  const PaginationChainExample({super.key});

  @override
  State<PaginationChainExample> createState() => _PaginationChainExampleState();
}

class _PaginationChainExampleState extends State<PaginationChainExample> {
  int _page = 3;

  @override
  Widget build(BuildContext context) {
    return Pagination(
      page: _page,
      totalPages: 10,
      onPageChanged: (p) => setState(() => _page = p),
    ).withStyle(
      const CorePaginationStyle(
        itemSpacing: CoreSpace.space8,
        buttonSize: CoreSize.size40,
        buttonRadius: CoreBorderRadius.all(CoreRadius.radius16),
        activeBackgroundColor: CoreColor.token(CoreColors.tertiary),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class PaginationChainExample extends StatefulComponent {
  const PaginationChainExample({super.key});

  @override
  State<PaginationChainExample> createState() => _PaginationChainExampleState();
}

class _PaginationChainExampleState extends State<PaginationChainExample> {
  int _page = 3;

  @override
  Component build(BuildContext context) {
    return Pagination(
      page: _page,
      totalPages: 10,
      onPageChanged: (value) => setState(() => _page = value),
    ).withStyle(
      const CorePaginationStyle(
        itemSpacing: CoreSpace.space8,
        buttonSize: CoreSize.size40,
        buttonRadius: CoreBorderRadius.all(CoreRadius.radius16),
        activeBackgroundColor: CoreColor.token(CoreColors.tertiary),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<Note>

위 예제는 `buttonRadius` 만 16 으로 바꾸므로 포커스 링의 모서리는 8 기준 그대로입니다. 맞추려면 `clickableStyle` 의 `borderRadius` 도 함께 줍니다.

</Note>

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CorePaginationStyle.defaultX                              // 기본값
  → CoreComponentTheme.pagination.style                   // 앱 전체
  → CoreComponentTheme.pagination.variantStyles[variant]  // 앱 전체, variant 별
  → paginationStyle                                       // 인스턴스
```

뒤로 갈수록 우선합니다.

<a id="접근성-accessibility"></a>

## 접근성

Web 은 줄을 `navigation` 랜드마크로, 현재 페이지를 `aria-current="page"` 로 알립니다. Flutter 는 줄에 이름을 붙이고 현재 페이지를 선택됨으로 알립니다.

### 역할

| 대상 | Flutter | Jaspr Web |
| --- | --- | --- |
| 줄 | 이름이 있는 컨테이너(`Semantics(container: true, label:)`). 내비게이션 역할은 없습니다 | `<div role="navigation" aria-label="…">`. 비활성이면 `aria-disabled="true"` |
| 번호 · 이전 · 다음 · `…` | 버튼. 눌리는지와 선택 여부를 함께 알립니다 | `role="button"`. 눌리면 `tabindex="0"`, 눌리지 않으면 `aria-disabled="true"` |
| 현재 페이지 | 선택됨(`selected: true`) | `aria-current="page"` |

줄의 이름은 두 플랫폼 모두 로케일의 `paginationLabel` 입니다(한국어 '페이지 매기기', 영어 'Pagination'). Web 의 `role` 과 `aria-label` 은 호출자가 넘긴 `attributes` 뒤에 쓰므로 덮을 수 없습니다. 속성 `role` 은 ARIA 역할이 아니라 서페이스 재질을 고르는 값입니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift` + `Tab` | 눌리는 버튼을 하나씩 앞 · 뒤로 옮깁니다 |
| `Enter` · `Space` | 포커스한 버튼을 누릅니다 |
| 화살표 | 이 컴포넌트는 따로 처리하지 않습니다. Flutter 네이티브 앱에서는 Flutter 의 기본 단축키가 누른 방향으로 포커스를 옮깁니다. Flutter Web 의 기본 단축키는 화살표를 스크롤에 쓰고 Jaspr Web 은 화살표를 처리하지 않아, 두 곳에서는 포커스가 옮겨 가지 않습니다 |
| `Home` · `End` | 따로 처리하지 않습니다. 처음과 끝으로 가려면 첫 · 마지막 페이지 버튼까지 `Tab` 합니다 |

`Enter` · `Space` 는 두 플랫폼 모두 버튼을 감싼 `Clickable` 이 처리합니다.

### 스크린 리더

| 버튼 | Flutter 의 이름 | Jaspr Web 의 이름 |
| --- | --- | --- |
| 번호 | 숫자('3') | 영어 'Page 3' |
| 이전 · 다음 | 로케일의 '이전' · '다음'. 화살표만 보일 때도 같은 이름입니다 | 같은 로케일 문구(`aria-label`) |
| `…` | '…' | 로케일의 `paginationJumpToPage`(한국어 '7 페이지로 이동') |

- 현재 페이지 버튼은 눌리고 포커스도 받으며, 누르면 같은 번호로 `onPageChanged` 를 다시 부릅니다.
- 끝의 흐린 화살표는 눌리지 않는 상태(Flutter `enabled: false`, Web `aria-disabled="true"`)로 알립니다. 전체가 비활성이면 모든 버튼이 그렇게 알리고, Web 의 현재 페이지 표시(`aria-current`)는 남습니다.
- 페이지가 바뀐 것을 따로 알리는 live region 은 없습니다. 바깥 코드가 `page` 를 바꾸면 알림 없이 바뀝니다.

### 포커스 관리

- 화면에 나타나거나 사라질 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다.
- 눌리는 버튼마다 `Tab` 정지점이 하나씩입니다. `maxPages` 가 기본값이면 많아야 9개입니다. 끝의 흐린 화살표와 비활성 줄의 버튼은 포커스를 받지 않습니다.
- 폭에 맞춰 줄였을 때 보이지 않는 단계의 버튼은 포커스를 받지 않고 보조 기술에도 전해지지 않습니다. Flutter 의 포커스에는 예외가 하나 있습니다([알려진 제약](#알려진-제약)).
- 페이지가 바뀌어도 컴포넌트는 포커스를 새 현재 페이지로 옮기지 않습니다. 버튼에 key 가 없어, 버튼 구성이 달라지면 포커스가 있던 자리에 다른 버튼이 올 수 있습니다.
- 줄이 짧아지거나 포커스가 있던 버튼이 눌리지 않게 되면(마지막 페이지에 도착한 다음 화살표 등) 그 버튼에 있던 포커스를 잃을 수 있습니다.
- 포커스 링은 키보드로 포커스했을 때 나타납니다(Flutter `FocusOutline`, Web `:focus-visible`).

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 전체가 `maxPages` 보다 많을 때, 현재 페이지를 번호 창 가운데에 둘 수 없는 처음 · 끝 페이지에서는 `…` 가 이미 보이는 번호로 옮깁니다. 이런 페이지는 양 끝에서 `maxPages` ÷ 2 (나머지는 버립니다)개씩이라, `maxPages: 3` 이면 1 페이지와 마지막 페이지, 5 면 앞의 두 페이지와 끝의 두 페이지입니다. 이 페이지들에서는 창 밖에 남은 페이지가 하나뿐이거나 없어도 첫 · 마지막 페이지 버튼이 함께 나올 수 있습니다. 예를 들어 `maxPages: 3` 에서 전체 5 의 1 페이지는 `‹ 1 2 3 … 5 ›`, 전체 4 의 4 페이지는 `‹ 1 … 2 3 4 ›` 입니다. 전체 4 의 1 페이지는 `‹ 1 2 3 … 4 ›` 로, 숨은 페이지 없이 `…` 를 그립니다. |
| 공통 | `maxPages` 가 짝수면 번호는 `maxPages` 개를 그리면서 `…` 는 한 칸 더 넓은 창을 기준으로 계산합니다. `maxPages: 4`, 전체 20 의 5 페이지는 창이 3 ~ 6 인데 뒤의 `…` 가 7 을 건너뛰고 8 로 옮깁니다. 같은 값에서 전체 10 의 8 페이지는 `1 … 6 7 8 9` 까지만 그려 10 페이지가 줄에서 빠집니다. 대신 홀수를 씁니다. |
| 공통 | `buttonRadius` 를 바꿔도 포커스 링의 모서리는 따라오지 않습니다. `clickableStyle.borderRadius` 를 함께 줍니다. |
| Flutter Web · Jaspr Web | 컴포넌트에 화살표 이동이 없어, 버튼 사이는 `Tab` 으로만 옮깁니다. 버튼 수만큼 `Tab` 을 눌러야 합니다. |
| Jaspr Web | 번호 버튼의 이름이 영어 'Page 3' 으로 고정되어 로케일을 따르지 않습니다. 버튼의 속성을 바꿀 방법이 없습니다. |
| Jaspr Web | `onPageChanged` 없이 `enabled: true` 를 주면 모든 버튼이 눌리지 않는 상태로 알려지고 흐려집니다. 평소 모양이 필요하면 `onPageChanged` 를 줍니다. |
| Jaspr Web | `…` 에는 hover 모양이 없습니다. |
| Flutter | `…` 의 이름이 '…' 뿐이라 어느 페이지로 옮기는지 말하지 않습니다. |
| Flutter | 줄에 내비게이션 역할이 없어, 랜드마크로 건너뛰어 올 수 없습니다. |
| Flutter | 폭이 좁아 버튼을 덜어 낸 상태에서 더 덜어 낼 단계가 없는 구성(예: `showLabel` 을 켜지 않은 `totalPages: 1`)으로 바뀌었다가, 덜어 내지 않아도 다 들어가는 구성이 되면 화면에 보이는 버튼에 `Tab` 이 닿지 않을 수 있습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

속성은 같고, 그리는 방식이 아래처럼 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 버튼 | `Clickable` 안의 `OutlinedContainer` | `Clickable` 안의 `<div>` |
| 줄의 폭 | 버튼이 차지하는 폭만큼 | 블록 부모 안에서는 부모 폭을 채우고 버튼을 왼쪽에 놓습니다 |
| `…` 의 hover | 번호 버튼처럼 채움과 글자 색이 바뀝니다 | 바뀌지 않습니다 |
| 색 전환 | 채움만 150ms. 글자와 화살표 색은 바로 바뀝니다 | 채움 · 글자 · 화살표 색이 함께 150ms |
| `onPageChanged` 없이 `enabled: true` | 평소 색. 번호 · `…` · 갈 곳이 있는 화살표는 눌리지만 아무 일도 없습니다 | 모든 버튼이 50% 로 흐려지고, 눌리지 않고, 포커스를 받지 않습니다 |
| 번호 버튼의 이름 | 숫자 | 영어 'Page 3' |
| `…` 의 이름 | '…' | '7 페이지로 이동'(로케일 문구) |
| 현재 페이지 | 선택됨 | `aria-current="page"` |
| 줄의 역할 | 이름만 있습니다 | `navigation` |
| 폭 재는 방법 | 레이아웃하면서 단계마다 놓아 보고, 들어가는 첫 단계를 그립니다 | 보이지 않는 사본(`inert`)을 `ResizeObserver` 로 잽니다. 서버에서 그린 첫 화면은 줄이지 않은 줄입니다 |
| 재는 폭 | 부모가 넘긴 최대 폭 | 부모를 거슬러 올라가며 flex · grid 항목과 inline · `contents` · absolute · fixed · float 상자를 건너뛰고, 처음 만나는 상자의 안쪽 폭 |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` (줄의 바깥 `<div>` 에 붙습니다) |

<Note>

Web 에서 폭을 나눠 가진 flex · grid 항목 바로 안에 줄을 두면, 그 항목을 건너뛰고 바깥 상자의 폭을 재므로 덜 줄일 수 있습니다. 항목 안에 블록 상자를 하나 더 두고 그 안에 놓으면 그 상자의 폭을 잽니다.

</Note>

<a id="props-parameters"></a>

## API

Flutter 와 Jaspr Web 이 같은 속성을 씁니다.

### 페이지와 이동

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `page` | `int` | 필수 | 현재 페이지(1부터). 범위를 벗어난 값을 맞춰 주지 않으므로 1 부터 `totalPages` 사이의 값을 넘깁니다. |
| `totalPages` | `int` | 필수 | 전체 페이지 수 |
| `onPageChanged` | `void Function(int)?` | `null` | 누른 버튼이 가리키는 페이지(1부터)를 받습니다. 현재 페이지를 눌러도 불립니다. |
| `enabled` | `bool?` | `null` | `null` 이면 `onPageChanged` 가 있을 때만 켜집니다. `false` 면 전체가 비활성 모양이 되고 어떤 버튼도 눌리지 않습니다. |

### 줄에 놓는 버튼

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `maxPages` | `int` | `3` | 번호 창에 보이는 번호의 최대 개수. 홀수를 씁니다. |
| `showSkipToFirstPage` | `bool` | `true` | 번호 창 앞에 두 페이지 이상 숨으면 1 페이지 버튼을 둡니다. 처음 · 끝 페이지에는 예외가 있습니다([알려진 제약](#알려진-제약)). |
| `showSkipToLastPage` | `bool` | `true` | 번호 창 뒤에 두 페이지 이상 숨으면 마지막 페이지 버튼을 둡니다. 처음 · 끝 페이지에는 예외가 있습니다([알려진 제약](#알려진-제약)). |
| `hidePreviousOnFirstPage` | `bool` | `false` | 첫 페이지에서 이전 화살표를 그리지 않습니다. |
| `hideNextOnLastPage` | `bool` | `false` | 마지막 페이지에서 다음 화살표를 그리지 않습니다. |
| `showLabel` | `bool` | `false` | 이전 · 다음 화살표 옆에 글자를 붙입니다. |

### 모양

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `variant` | `CorePaginationVariant` | `standard` | 시각 변형. 값은 `standard` 하나입니다. |
| `role` | `CoreSurfaceRole` | `defaultRole`(`content`) | 현재 페이지 버튼이 받는 서페이스 재질. 접근성 역할과 별개입니다. |
| `paginationStyle` | `CorePaginationStyle?` | `null` | 이 줄의 겉모습(색 · 크기 · 간격) |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CorePaginationStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `itemSpacing` | `double?` | Spacing between adjacent pagination buttons (logical px), applied as the host-layout `Row.spacing` (Flutter) / CSS flex `gap` (Web) of the outer pagination row. |
| `buttonSize` | `double?` | Width / height of a square pagination button (logical px). |
| `buttonRadius` | `CoreBorderRadius?` | Corner radius of a pagination button. |
| `labelButtonPadding` | `CoreEdgeInsets?` | Inner padding of the previous / next buttons in label mode (`showLabel: true`), whose width follows their content. Defaults to [defaultLabelButtonPadding]. |
| `buttonTextStyle` | `CoreTextStyle?` | Base text style override shared by every page-number / prev / next button (typography role + weight; carries no per-state colour). Layered on top of [defaultButtonTextStyle]. |
| `activeButtonTextStyle` | `CoreTextStyle?` | Typography override of the active (current) page button, layered on top of [buttonTextStyle] and [defaultActiveButtonTextStyle]. Carries no colour — that is [activeTextStyle]. |
| `activeBackgroundColor` | `CoreColor?` | Background colour of the active (current) page button. |
| `activeTextStyle` | `CoreTextStyle?` | Text colour override for the active (current) page button, carried via [CoreTextStyle.color] inside this slot. Defaults to [defaultActiveTextStyle]. The active button's typography is [activeButtonTextStyle], not this slot. |
| `hoverBackgroundColor` | `CoreColor?` | Background colour applied to a button on hover. |
| `hoverTextStyle` | `CoreTextStyle?` | Text colour override applied to a button on hover, carried via [CoreTextStyle.color] inside this slot. Defaults to [defaultHoverTextStyle]. |
| `textStyle` | `CoreTextStyle?` | Text colour override for an inactive / prev / next button, carried via [CoreTextStyle.color] inside this slot. The chevrons take it too. Defaults to [defaultTextStyle]. |
| `disabledColor` | `CoreColor?` | Override colour of every number, the `…` and the chevrons while the pagination is disabled. `null` defers to [defaultDisabledColor]. |
| `disabledBackgroundColor` | `CoreColor?` | Override fill of the active (current) page button while the pagination is disabled. `null` defers to [defaultDisabledBackgroundColor]. |
| `iconStyle` | `CoreIconStyle?` | Style of the previous / next chevron (its size; the colour is the button's foreground unless this slot states one). `null` defers to [defaultIconStyle]. |
| `hoverDuration` | `Duration?` | Colour-transition duration for button hover. `null` → token default ([defaultHoverDuration]). |
| `ellipsisStyle` | `CoreTextStyle?` | Ellipsis (`…`) text style override, layered on top of [defaultEllipsisStyle] — colour only by default, so the `…` takes the shared button typography ([buttonTextStyle]) and differs from a page number by its colour alone. A typography overlay stated here is applied to the `…` alone. |
| `clickableStyle` | `CoreClickableStyle?` | Style for each page button's `Clickable` — press scale, durations, focus ring, disabled opacity. Laid over [defaultClickableStyle] and passed to the `Clickable` as is, which fills in the rest. |

<!-- STYLE_TABLE:END -->

<Note>

`hoverBackgroundColor` 와 `hoverTextStyle` 은 Web 의 `…` 에는 적용되지 않습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="pagination/related-table" title="Table">

[Table](/components/table)은 페이지로 나눈 데이터를 행과 열로 보여 줍니다.

</Card>
<Card demo="pagination/related-select" title="Select">

페이지당 개수를 고르게 할 때 [Select](/components/select)를 함께 둡니다.

</Card>
<Card demo="pagination/related-dot-indicator" title="DotIndicator">

[DotIndicator](/components/dot-indicator)는 적은 수의 슬라이드 위치를 점으로 보여 줍니다.

</Card>
</Cards>
