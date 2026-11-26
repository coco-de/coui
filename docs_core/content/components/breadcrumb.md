---
title: Breadcrumb
description: 현재 페이지의 위치를 계층적으로 나타내는 탐색 경로 컴포넌트
category: navigation
platforms: [flutter, web]
related: [navigation-bar, tabs, link]
tags: [breadcrumb, navigation, hierarchy]
template: v2
source: navigation/breadcrumb
---

# Breadcrumb

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

항목 수와 구분자를 바꿔 보며 탐색 경로를 확인하고, 만들어진 코드를 그대로 복사하세요. 앞 항목을 누르면 경로 아래에 `onItemTap` 이 받은 번호가 보입니다.

<Playground component="breadcrumb" />

`items` 의 마지막 항목은 지금 보고 있는 위치라 누를 수 없습니다. 앞 항목을 누르면 `onItemTap` 이 그 항목의 번호(0부터)를 받습니다. 화면을 옮기는 일은 이 콜백에서 합니다. Flutter와 Jaspr Web의 코드는 같습니다.

```dart
Breadcrumb(
  items: const [
    CoreBreadcrumbItem(label: '홈', href: '/'),
    CoreBreadcrumbItem(label: '카테고리', href: '/category'),
    CoreBreadcrumbItem(label: '상품 상세'),
  ],
  onItemTap: openCrumb,
)
```

## 구조

탐색 경로는 항목과 그 사이의 구분자를 가로 한 줄로 늘어놓습니다.

<Anatomy demo="breadcrumb/anatomy">
<AnatomyItem part="container" name="Container">

항목과 구분자를 담는 가로 줄. 보조 기술에는 탐색 영역(navigation 랜드마크)으로 알립니다. 자기 채움 · 테두리 · 안쪽 여백은 없습니다.

</AnatomyItem>
<AnatomyItem select="[role=link]" name="item">

현재 위치 앞의 항목. 활성 상태이고 `onItemTap` 이 있으면 누를 수 있습니다. 글자 둘레에 안쪽 여백(`itemPadding`, 위아래 2 · 좌우 4)이 있고, 포커스 링은 이 여백까지 감쌉니다.

</AnatomyItem>
<AnatomyItem select="span[aria-hidden]" name="separator">

항목 사이의 chevron(`LucideIcons.chevronRight`). 누를 수 없고, 양옆을 4씩 띄웁니다.

</AnatomyItem>
<AnatomyItem select="[aria-current=page]" side="right" name="current">

마지막 항목. 지금 보고 있는 위치라 누를 수 없습니다. 앞 항목과 달리 `onSurface` 색과 `labelLarge`(Medium) 글자를 씁니다.

</AnatomyItem>
</Anatomy>

## 항목

`items` 에는 맨 위 단계부터 지금 위치까지 `CoreBreadcrumbItem` 을 순서대로 넣습니다. 항목이 가진 값은 `label`(필수)과 `href`(선택) 둘입니다. 라벨은 문자열만 받으므로 항목마다 아이콘이나 다른 위젯을 넣을 수는 없습니다.

| 항목 | 동작 |
| --- | --- |
| 마지막 항목 | 현재 위치입니다. `onItemTap` 이 있어도 누를 수 없습니다. |
| 앞 항목 | 활성 상태이고 `onItemTap` 이 있으면 누를 수 있습니다. 누르면 `onItemTap` 이 `items` 안의 번호(0부터)를 받습니다. |
| `href` | 두 플랫폼 모두 이 값으로 이동하지 않는 정보용 값입니다. Flutter는 읽지 않고, 웹은 누를 수 있는 항목에 `data-href` 속성으로 남겨 도구가 읽을 수 있게 합니다. |
| 항목이 하나일 때 | 현재 위치 하나만 그리고 구분자는 없습니다. |
| 빈 목록 | 항목도 구분자도 그리지 않습니다. 웹에는 빈 `role="navigation"` 상자가 남습니다. |
| 긴 라벨 | 줄을 바꾸거나 말줄임표로 자르지 않습니다. 길어진 경로를 다루는 방법은 [배치](#배치)에 있습니다. |
| 가운데 접기 | 가운데 항목을 `…` 로 접는 기능은 없습니다. 줄여서 보이려면 호출자가 `items` 를 줄여 넘깁니다. 이때 `onItemTap` 의 번호는 넘긴 목록 안의 번호입니다. |

이동할 곳은 항목 번호로 찾습니다.

```dart
final steps = [
  (label: '홈', path: '/'),
  (label: '프로젝트', path: '/projects'),
  (label: 'CoUI', path: '/projects/coui'),
];

Breadcrumb(
  items: [
    for (final step in steps)
      CoreBreadcrumbItem(label: step.label, href: step.path),
  ],
  onItemTap: (index) => openPath(steps[index].path),
)
```

<a id="변형-variants"></a>

## 구분자

variant는 `standard` 하나이고, 구분자는 항상 chevron(`LucideIcons.chevronRight`)입니다. 글리프를 바꾸는 속성은 없고, 크기 · 색 · 양옆 간격을 `breadcrumbStyle` 로 바꿉니다.

<Preview demo="breadcrumb/separator" />

| 바꿀 것 | 기본값 | `breadcrumbStyle` 필드 |
| --- | --- | --- |
| 크기 | 16 | `separatorIconStyle` 의 `size` |
| 색 | `onSurfaceSubtle` | `separatorIconStyle` 의 `color` |
| 양옆 간격 | 4 (이웃한 두 항목 상자 사이는 4 + 16 + 4 = 24) | `itemSeparatorGapStyle` |

미리보기의 둘째 줄처럼 크기 · 색 · 간격을 바꾸는 코드입니다.

```dart
Breadcrumb(
  items: items,
  onItemTap: openCrumb,
  breadcrumbStyle: const CoreBreadcrumbStyle(
    separatorIconStyle: CoreIconStyle(
      size: CoreIconSize.size12,
      color: CoreColor.token(CoreColors.primary),
    ),
    itemSeparatorGapStyle: CoreGapStyle(size: CoreSpace.space8),
  ),
)
```

`separatorIconStyle` 은 적은 값만 바꿉니다. 크기만 적으면 색은 기본값 그대로입니다. 비활성 상태의 구분자는 여기에 적은 색 대신 `disabledColor` 를 씁니다.

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>
<a id="상태-전환"></a>
<a id="애니메이션"></a>

## 상태

활성 여부는 `enabled` 를 지정하지 않으면 `onItemTap` 이 있는지로 정합니다(`enabled ?? (onItemTap != null)`).

<Preview demo="breadcrumb/states" />

| 위 미리보기 | 색 | 누를 수 있는 항목 |
| --- | --- | --- |
| `onItemTap` 있음 | 아래 표의 기본 색 | 앞 항목 |
| `onItemTap` 없음 (`enabled: false` 와 같은 모양) | 항목과 구분자 모두 `disabledContent` | 없음 |
| `enabled: true`, `onItemTap` 없음 | 아래 표의 기본 색 | 없음. 보여 주기만 합니다. |

| 부분 | 기본 | Hover | 비활성 |
| --- | --- | --- | --- |
| 앞 항목 | `onSurfaceVariant` · `bodyMedium`(14 Regular) | `onSurface` (누를 수 있을 때만) | `disabledContent` |
| 현재 항목 | `onSurface` · `labelLarge`(14 Medium) | 바뀌지 않음 | `disabledContent` |
| 구분자 | `onSurfaceSubtle` | 바뀌지 않음 | `disabledContent` |

| 항목 | 동작 |
| --- | --- |
| Hover 전환 | 글자색이 `hoverDuration`(기본 `CoreDuration.fast`, 150ms) 동안 바뀝니다. |
| 눌림 | 눌러도 줄어들지 않습니다. 눌림 축소(`pressedScale`)를 끈 상태가 기본값이고, `clickableStyle` 로 다시 켤 수 있습니다. |
| Focus | 키보드로 포커스하면 항목 상자 둘레에 `focusRing` 색 링(간격 2 · 두께 2)이 나타납니다. 항목 상자의 모서리는 6, 링 바깥 모서리는 10입니다. |
| 커서 | 누를 수 있는 항목은 손가락 모양 커서를 씁니다. |
| 비활성 | 모든 항목과 구분자를 `disabledContent` 색(`disabledColor` 로 바꿉니다)으로 그리고, hover · 포커스 · 누르기가 없습니다. `itemColor` · `currentItemColor` · `itemHoverColor` 나 구분자 색을 적어 두어도 비활성 색이 앞섭니다. |

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>
<a id="do"></a>
<a id="dont"></a>

## 사용 가이드

### 언제 쓰나

- 세 단계 이상인 계층에서 지금 위치를 알려 줄 때
- 상위 단계로 빨리 돌아가야 할 때 (쇼핑몰 카테고리, 관리자 설정)
- 문서 · 파일 탐색기처럼 깊은 계층을 오갈 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 부모-자식 경로가 아니라 같은 단계의 패널 하나를 고를 때 | [Tabs](/components/tabs) |
| 앱의 주요 화면 사이를 오갈 때 | [NavigationBar](/components/navigation-bar) |
| 목적지가 하나뿐이거나, 웹에서 새 탭 열기 같은 브라우저의 링크 기능이 필요할 때(`onPressed` 없이 씁니다) | [Link](/components/link) |
| 여러 페이지로 나뉜 목록을 번호로 넘길 때 | [Pagination](/components/pagination) |

### 경로 구성

<Cards columns="2">
<Card demo="breadcrumb/do-current" tone="do" eyebrow="이렇게 하세요">

지금 보는 화면까지 넣습니다. 마지막 항목은 저절로 누를 수 없는 현재 위치가 됩니다.

</Card>
<Card demo="breadcrumb/dont-missing-current" tone="dont" eyebrow="이렇게 하지 마세요">

'데이터' 화면인데 '데이터'를 빼면 '라이브러리'가 현재 위치가 되어, '라이브러리'로 돌아갈 수 없습니다.

</Card>
<Card demo="breadcrumb/do-deep" tone="do" eyebrow="이렇게 하세요">

세 단계 이상인 계층에서 상위 단계를 한눈에 보이고 바로 돌아가게 합니다.

</Card>
<Card demo="breadcrumb/dont-two-levels" tone="dont" eyebrow="이렇게 하지 마세요">

두 단계뿐이면 뒤로 가기 버튼이나 Link로 충분합니다. 탐색 경로는 화면만 복잡하게 합니다.

</Card>
</Cards>

## 배치

경로는 늘 한 줄이라, 자리보다 길어도 줄을 바꾸지 않습니다. Flutter는 부모의 최대 폭 안에서 가로로 스크롤합니다. 웹은 경로의 폭이 자리의 폭에 묶여야 스크롤하는데, 부모에 폭을 정해도 묶이지 않는 배치가 있습니다(아래 표). 미리보기는 폭 240 안에 둔 긴 경로입니다.

<Preview demo="breadcrumb/overflow" />

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 폭 | 내용만큼 차지하고, 부모의 최대 폭을 넘지 않습니다. | 내용만큼 차지합니다. 루트에 최대 폭이 없어, 블록 부모나 자식을 가로로 늘리지 않는 세로 flex(`items-start` · `items-center`) 안에서는 부모에 폭을 정해 두어도 긴 경로가 넘칠 수 있습니다. 스크롤시키려면 `classes: 'max-w-full'` 을 줍니다. |
| 넘칠 때 | 가로 스크롤 영역입니다. 스크롤바는 그리지 않고, 끌어서 스크롤하는 것은 터치만 받습니다. | `overflow-x: auto`. 스크롤바와 끌기는 브라우저를 따릅니다. |
| 높이 | 가장 큰 부분의 높이입니다. 기본값에서 앞 항목이 있으면 25(글자 줄 21 + 위아래 여백 2씩)입니다. | 같습니다. |

```dart
// Jaspr Web: 좁은 자리에서는 폭 상한을 줍니다.
Breadcrumb(
  items: items,
  onItemTap: openCrumb,
  classes: 'max-w-full',
)
```

<a id="스타일-시스템-style-system"></a>
<a id="파라미터와-스타일"></a>
<a id="시맨틱-vs-스타일"></a>

## 테마와 스타일

내용과 동작은 위젯 속성(`items` · `onItemTap` · `enabled` · `variant`)으로 넘기고, 색 · 글자 · 여백 · 간격과 안쪽 부품의 스타일은 `breadcrumbStyle`(`CoreBreadcrumbStyle`) 하나로 바꿉니다.

<Split>

<Code language="dart" title="경로 하나만 바꾸기">
Breadcrumb(
  items: items,
  onItemTap: openCrumb,
  breadcrumbStyle: const CoreBreadcrumbStyle(
    currentItemColor: CoreColor.token(CoreColors.primary),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    breadcrumb: CoreBreadcrumbTheme(
      style: CoreBreadcrumbStyle(
        itemSeparatorGapStyle: CoreGapStyle(size: CoreSpace.space8),
      ),
    ),
  ),
)
</Code>

</Split>

### 글자와 색

색은 아래 표를 왼쪽부터 보고 처음으로 적혀 있는 값을 씁니다. 글자는 앞의 글자 위에 뒤의 값을 겹칩니다. 비활성 상태에서는 어느 색을 적었든 `disabledColor` 를 씁니다.

| 부분 | 순서 |
| --- | --- |
| 앞 항목의 색 | `itemColor` → `itemTextStyle` 의 색 → `onSurfaceVariant` |
| 현재 항목의 색 | `currentItemColor` → `itemColor` → `itemTextStyle` 의 색 → `onSurface` |
| Hover 색 | `itemHoverColor` → `onSurface` |
| 앞 항목의 글자 | `bodyMedium` 위에 `itemTextStyle` |
| 현재 항목의 글자 | `labelLarge` 위에 `itemTextStyle`, 그 위에 `currentItemTextStyle` |

- `itemColor` 만 주면 현재 항목도 같은 색이 됩니다. 구분하려면 `currentItemColor` 도 함께 줍니다.
- `itemTextStyle` 에 다른 글자 역할(예: `bodySmall`)을 주면 현재 항목도 그 역할을 씁니다. 현재 항목만 굵게 두려면 `currentItemTextStyle` 로 다시 정합니다.
- `currentItemTextStyle` 의 색은 쓰지 않습니다. 현재 항목의 색은 `currentItemColor` 로 바꿉니다.
- 웹은 한 가지 조합에서 현재 항목의 크기 · 줄 높이가 위 순서와 다르게 정해집니다. 조합은 [알려진 제약](#알려진-제약)에 있습니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreBreadcrumbStyle.default*                          // 디자인 시스템 기본값
  → CoreComponentTheme.breadcrumb.style               // 앱 전체
  → CoreComponentTheme.breadcrumb.variantStyles[variant]  // 앱 전체, variant 별
  → breadcrumbStyle                                   // 인스턴스
```

뒤로 갈수록 우선합니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Breadcrumb` 에는 `withStyle` 로 스타일을 덧붙입니다. 생성자의 `breadcrumbStyle` 과 같게 동작하고, 겹치는 값은 나중에 붙인 것이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class BreadcrumbChainExample extends StatelessWidget {
  const BreadcrumbChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Breadcrumb(
      items: const [
        CoreBreadcrumbItem(label: '홈', href: '/'),
        CoreBreadcrumbItem(label: '라이브러리', href: '/components'),
        CoreBreadcrumbItem(label: '데이터'),
      ],
      onItemTap: (index) {},
    ).withStyle(
      const CoreBreadcrumbStyle(
        itemSeparatorGapStyle: CoreGapStyle(size: CoreSpace.space16),
        itemColor: CoreColor.token(CoreColors.onSurfaceVariant),
        currentItemColor: CoreColor.token(CoreColors.primary),
        itemHoverColor: CoreColor.token(CoreColors.tertiary),
        separatorIconStyle: CoreIconStyle(
          size: CoreSize.size12,
          color: CoreColor.token(CoreColors.outline),
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class BreadcrumbChainExample extends StatelessComponent {
  const BreadcrumbChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Breadcrumb(
      items: const [
        CoreBreadcrumbItem(label: '홈', href: '/'),
        CoreBreadcrumbItem(label: '라이브러리', href: '/components'),
        CoreBreadcrumbItem(label: '데이터'),
      ],
      onItemTap: (index) {},
    ).withStyle(
      const CoreBreadcrumbStyle(
        itemSeparatorGapStyle: CoreGapStyle(size: CoreSpace.space16),
        itemColor: CoreColor.token(CoreColors.onSurfaceVariant),
        currentItemColor: CoreColor.token(CoreColors.primary),
        itemHoverColor: CoreColor.token(CoreColors.tertiary),
        separatorIconStyle: CoreIconStyle(
          size: CoreSize.size12,
          color: CoreColor.token(CoreColors.outline),
        ),
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

경로 전체는 이름이 붙은 탐색 영역으로, 누를 수 있는 항목은 링크로 알립니다.

### 역할

| 부분 | Flutter | Jaspr Web |
| --- | --- | --- |
| 루트 | `CoUISemantics(role: .navigation, label:, container: true)`. `<nav>` 에 해당하는 탐색 랜드마크입니다. | `<div role="navigation" aria-label="…">` |
| 누를 수 있는 항목 | `Clickable` 의 버튼 시맨틱 위에 `Semantics(link: true)` 를 더합니다. | `Clickable` 의 `role="button"` 을 `role="link"` 로 바꿉니다. `href` 가 있으면 `data-href` 로 남깁니다. `<a>` 가 아닙니다. |
| 현재 항목 | 따로 표시하지 않습니다. 일반 글자입니다. | `aria-current="page"` |
| 비활성 | 항목을 누르는 영역 없이 글자로만 그립니다. 비활성이라는 표시는 없습니다. | 루트에 `aria-disabled="true"`. 항목에는 역할이 붙지 않습니다. |
| 구분자 | chevron 그림에 이름 없는 이미지 시맨틱이 붙습니다. | `<span aria-hidden="true">` 로 접근성 트리에서 뺍니다. |

웹의 마크업은 이런 모양입니다.

```html
<div role="navigation" aria-label="탐색 경로">
  <div role="link" tabindex="0" data-href="/"><div><span>홈</span></div></div>
  <div></div>
  <span aria-hidden="true">…chevron…</span>
  <div></div>
  <div aria-current="page"><span>데이터</span></div>
</div>
```

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` · `Shift+Tab` | 누를 수 있는 항목 사이를 차례로 옮깁니다. | 같습니다. |
| `Enter` · `Space` | 포커스한 항목의 번호로 `onItemTap` 을 부릅니다. | 같습니다. |
| `←` · `→` | 컴포넌트가 따로 처리하지 않습니다. 앱의 기본 단축키를 따릅니다(네이티브는 방향으로 포커스 이동, Flutter 웹은 스크롤). | 컴포넌트가 따로 처리하지 않습니다. 브라우저의 기본 동작을 따릅니다. |

### 스크린 리더

- 항목의 이름은 `CoreBreadcrumbItem` 의 `label` 입니다. 필수 값입니다.
- 탐색 영역의 이름은 렌더할 때의 언어에서 `breadcrumbLabel` 문구로 정합니다(한국어 "탐색 경로", 영어 "Breadcrumb"). 웹은 `role` 과 `aria-label` 을 호출자의 `attributes` 보다 뒤에 쓰므로 `attributes` 로는 바꿀 수 없습니다.
- 현재 위치는 웹에서만 `aria-current="page"` 로 알립니다.
- 구분자는 웹에서는 읽지 않습니다. Flutter에서는 이름 없는 이미지로 남습니다.
- `onItemTap` 이 없거나 비활성이면 두 플랫폼 모두 항목이 링크가 아닙니다. 비활성이라는 사실은 웹만 루트의 `aria-disabled` 로 알립니다.
- `items` 가 바뀌어도 따로 알리는 라이브 리전은 없습니다.

### 포커스 관리

- 마운트되거나 사라질 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. `onItemTap` 뒤에도 컴포넌트가 포커스를 옮기지는 않습니다.
- 포커스가 멈추는 곳은 누를 수 있는 항목마다 하나입니다. 항목이 N개이고 활성이면 N−1곳이고, 비활성이거나 `onItemTap` 이 없으면 없습니다. 현재 항목과 구분자는 멈추지 않습니다.
- 넘친 경로에서 보이지 않는 항목으로 `Tab` 이 가면 Flutter는 기본 포커스 이동이, 웹은 브라우저가 그 항목이 보이도록 스크롤합니다.
- 포커스 링은 항목의 `Clickable` 이 그립니다(Flutter `FocusOutline`, 웹 `:focus-visible`).

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | 현재 위치를 보조 기술에 알리지 않습니다. 항목을 위젯으로 받지 않아 현재 항목에만 시맨틱을 더할 수도 없습니다. 화면에서는 색과 글자 굵기로만 구분합니다. |
| Flutter | 비활성을 알리지 않습니다. 항목은 누를 수 없는 글자로 읽힙니다. |
| Flutter | 구분자마다 이름 없는 이미지 시맨틱이 붙습니다. |
| Flutter | 끌어서 스크롤하는 것은 터치만 받아, 넘친 경로를 마우스로 끌어 옮길 수 없습니다. 트랙패드 스크롤을 끌기 제스처로 보내는 네이티브 데스크톱에서는 트랙패드로도 움직이지 않습니다. |
| Flutter | 넘쳐서 스크롤하는 동안에는 스크롤 영역이 상자 밖을 잘라, 포커스 링의 위아래(스크롤이 처음 위치면 첫 항목의 왼쪽도)가 보이지 않습니다. |
| Jaspr Web | 루트가 `overflow-x: auto` 라 상자 밖으로 나가는 부분이 잘립니다. 포커스 링은 항목 상자 바깥 4까지 그려지고 루트에는 안쪽 여백이 없어, 링의 위아래(첫 항목은 왼쪽도)가 보이지 않습니다. 루트에 `classes: 'p-space4'` 처럼 안쪽 여백을 주면 보입니다. |
| Jaspr Web | 진짜 링크(`<a href>`)가 아닙니다. 새 탭 열기나 주소 미리 보기 같은 브라우저의 링크 기능이 없고, 보조 기술도 목적지 주소를 알 수 없습니다. 이동은 `onItemTap` 으로만 합니다. |
| Jaspr Web | `itemColor`(또는 `itemTextStyle` 의 색)에 색 토큰이 아닌 값을 주면 hover해도 색이 바뀌지 않습니다. 인라인으로 쓴 글자색이 hover 규칙보다 앞서기 때문입니다. Flutter는 바뀝니다. 색 토큰을 쓰면 두 플랫폼이 같습니다. |
| Jaspr Web | hover 색 전환 시간을 숫자 그대로 써서 '동작 줄이기' 설정에도 줄지 않습니다. 끄려면 `hoverDuration: Duration.zero` 를 줍니다. Flutter는 설정을 켜면 바로 바뀝니다. |
| Jaspr Web | `itemTextStyle` 에 글자 역할 없이 크기나 줄 높이를 주고, `currentItemTextStyle` 에는 크기 · 줄 높이 없이 `labelLarge` 가 아닌 글자 역할을 주면, 현재 항목에 `itemTextStyle` 의 크기 · 줄 높이가 남습니다. Flutter는 새 역할의 크기 · 줄 높이로 그립니다. `itemTextStyle` 에도 글자 역할을 적으면 두 플랫폼이 같습니다. |
| 공통 | 항목이 목록(`ol` · `li`)으로 묶이지 않아 "몇 개 중 몇 번째" 인지 알리지 않습니다. |
| 공통 | 누르는 영역은 그린 항목 상자와 같고, 넓히는 장치가 없습니다. 높이는 기본값에서 25지만, 아주 짧은 라벨은 폭이 24보다 좁을 수 있습니다. `itemPadding` 으로 상자를 키웁니다. |
| 공통 | 오른쪽에서 왼쪽으로 쓰는 언어에서도 chevron 은 뒤집히지 않고 오른쪽을 가리킵니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 루트 | 가로 `SingleChildScrollView` 안의 `Row` | `<div role="navigation">` (`inline-flex` · `overflow-x: auto`) |
| `href` | 쓰지 않습니다. | 누를 수 있는 항목의 `data-href` 속성 |
| 현재 위치 알림 | 없습니다. | `aria-current="page"` |
| 비활성 알림 | 없습니다. | 루트의 `aria-disabled="true"` |
| 구분자 | 이름 없는 이미지 시맨틱 | `aria-hidden="true"` |
| Hover 감지 | 항목 `Clickable` 의 `onHover` | CSS `:hover` |
| Hover 전환 곡선 | `CoreEasing.move` (ease-in-out) | Tailwind 기본 곡선 `cubic-bezier(0.4, 0, 0.2, 1)` |
| 동작 줄이기 | hover 색이 바로 바뀝니다. | 전환 시간이 그대로입니다. |
| 좁은 폭 | 부모의 최대 폭 안에서 스크롤하고 스크롤바를 그리지 않습니다. | 블록 부모나 `items-start` · `items-center` 인 세로 flex 안에서는 부모에 폭이 있어도 `classes: 'max-w-full'` 을 줘야 스크롤합니다. |
| 웹 전용 속성 | 없습니다. | `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. 웹은 HTML 속성을 위한 `id` · `classes` · `css` · `attributes` · `eventHandlers` 도 받습니다.

### Breadcrumb 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `items` | `List<CoreBreadcrumbItem>` | 필수 | 맨 위 단계부터 지금 위치까지. 마지막 항목이 현재 위치입니다. |
| `onItemTap` | `CoreValueChanged<int>?` | `null` | 앞 항목을 누르면 그 번호(0부터)를 받습니다. 타입은 `void Function(int)` 입니다. |
| `enabled` | `bool?` | `null` | 지정하지 않으면 `onItemTap` 이 있을 때 활성입니다. |
| `variant` | `CoreBreadcrumbVariant` | `standard` | 지금은 `standard` 하나입니다. 테마의 `variantStyles` 를 고릅니다. |
| `breadcrumbStyle` | `CoreBreadcrumbStyle?` | `null` | 보이는 값 덮어쓰기 |

### CoreBreadcrumbItem 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `label` | `String` | 필수 | 항목 글자. 접근 가능한 이름이 됩니다. |
| `href` | `String?` | `null` | 항목의 주소를 적는 정보용 값. 이동에는 쓰지 않고, 웹은 누를 수 있는 항목에 `data-href` 로 남겨 도구가 읽을 수 있게 합니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreBreadcrumbStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `itemSeparatorGapStyle` | `CoreGapStyle?` | Style of the `Gap` between an item, its separator and the next item. `null` defers to [defaultItemSeparatorGapStyle]. |
| `itemColor` | `CoreColor?` | Override colour applied to inactive (link) items. `null` defers to [itemTextStyle]'s colour, then [defaultItemColor]. |
| `currentItemColor` | `CoreColor?` | Override colour applied to the current (last) item. |
| `itemHoverColor` | `CoreColor?` | Override hover colour applied to an interactive link item. `null` defers to [defaultItemHoverColor]. |
| `disabledColor` | `CoreColor?` | Override colour of every item label and of the separator while the breadcrumb is disabled. `null` defers to [defaultDisabledColor]. |
| `itemTextStyle` | `CoreTextStyle?` | Item text style — applies to every breadcrumb item (link and current). `null` defers to [defaultItemTextStyle] for the links. |
| `currentItemTextStyle` | `CoreTextStyle?` | Text style of the current (last) item, layered on top of [itemTextStyle]. `null` defers to [defaultCurrentItemTextStyle]. |
| `itemPadding` | `CoreEdgeInsets?` | Inset around each item label (inside the focus ring). `null` defers to [defaultItemPadding]. |
| `separatorIconStyle` | `CoreIconStyle?` | Separator icon style (size / colour of the chevron glyph). |
| `hoverDuration` | `Duration?` | Override colour-transition duration for link hover. `null` defers to [defaultHoverDuration]. |
| `clickableStyle` | `CoreClickableStyle?` | Style of the `Clickable` that wraps each link item (interactive items only). Merged on top of [defaultClickableStyle] and passed to `Clickable(clickableStyle:)` as is. |

<!-- STYLE_TABLE:END -->

<Note>

표의 설명에 덧붙일 지금 동작이 두 가지 있습니다. `itemColor` 는 앞 항목의 색이지만, `currentItemColor` 를 주지 않으면 현재 항목도 이 색을 씁니다. `currentItemTextStyle` 의 `color` 는 두 플랫폼 모두 쓰지 않습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="breadcrumb/related-tabs" title="Tabs">

같은 단계의 보기 중 하나를 골라 바꿔 봅니다.

</Card>
<Card demo="breadcrumb/related-navigation-bar" title="NavigationBar">

앱의 주요 화면 사이를 오갑니다.

</Card>
<Card demo="breadcrumb/related-link" title="Link">

목적지 하나로 가는 링크 글자입니다. 웹에서는 `onPressed` 를 주지 않으면 브라우저의 진짜 링크로 그립니다.

</Card>
</Cards>
