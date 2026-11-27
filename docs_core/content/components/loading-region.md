---
title: LoadingRegion
description: 아직 내용이 오지 않은 영역의 "로딩 중" 을 한 번만 알리는 래퍼
category: display
platforms: [flutter, web]
related: [skeleton, loading]
tags: [loading, skeleton, accessibility, live-region]
template: v2
source: display/loading_region
---

# LoadingRegion

<a id="live-preview"></a>

## 플레이그라운드

한 영역을 채우는 `Skeleton`들을 감싸 **"로딩 중"을 영역마다 한 번** 알립니다. 문구와 감싸기 여부를 바꿔 보고, 만들어진 코드를 복사하세요.

<Playground component="loading-region" />

LoadingRegion은 화면에 아무것도 그리지 않아, 감싸도 `Skeleton`의 모습은 그대로입니다. 그림에 적힌 "라이브 영역" 글은 문서가 덧붙인 설명으로, 지금 설정에서 만들어지는 라이브 영역의 수와 문구를 보여 줍니다. 라이브 영역은 내용이 새로 생기거나 바뀔 때 스크린 리더가 알릴 수 있게 표시한 영역입니다.

`영역 없이 Skeleton만 두기`를 켜면 `semanticLabel`을 줄 곳이 없어, `Skeleton`마다 로케일의 로딩 문구를 가진 라이브 영역이 생깁니다.

<a id="동작-스펙-behavior"></a>

## 알림 동작

감싸지 않은 `Skeleton`은 하나하나가 라이브 영역입니다. LoadingRegion으로 감싸면 안쪽 `Skeleton`은 자기가 영역 안에 있음을 알고 자기 알림을 끕니다. `Skeleton`이 열 개여도 라이브 영역은 하나입니다.

<Preview demo="loading-region/announcements" />

| 상황 | 결과 |
| --- | --- |
| 영역 하나 | 라이브 영역 하나가 `semanticLabel`을 알립니다. `null`이면 화면을 그리는 시점의 로케일 로딩 문구(영어 "Loading", 한국어 "로딩 중")를 씁니다. |
| 영역 안의 `Skeleton` | 자기 알림을 만들지 않습니다. 영역 밖의 `Skeleton`은 스스로 알립니다. |
| 영역 안의 영역 | 바깥 영역만 알립니다. 안쪽 영역은 `child`를 그대로 그리므로 안쪽에 준 `semanticLabel`은 쓰이지 않습니다. |
| 영역 안의 내용 | 영역이 있는 동안 보조 기술에서 숨겨집니다. |
| 동작 줄이기 설정 | 알림은 그대로이고 `Skeleton`의 맥동만 멈춥니다. |

영역 안에서 연 오버레이가 영역 바깥의 오버레이 층에 그려지면, 그 내용은 두 플랫폼 모두 영역 밖에 만들어집니다. 영역의 숨김이 닿지 않고, 그 안의 `Skeleton`은 스스로 알립니다. Flutter에서는 영역 바깥의 `Overlay`(앱의 `Overlay`처럼)에 올린 `OverlayEntry`가 그렇습니다. Web에서는 `CoUIWeb`이 두는 오버레이 층이 영역 바깥에 있을 때 `Dialog` · `Popover` · `DropdownMenu` · `Tooltip`이 그 층에 올리는 패널이 그렇습니다.

영역 안에 있는지를 확인해 알림을 끄는 컴포넌트는 `Skeleton`입니다. 예를 들어 영역 안에 둔 [Loading](/components/loading)은 자기 알림을 끄지 않지만, 영역의 숨김에 함께 가려집니다.

<a id="사용-시기-when-to-use"></a>

## 사용 가이드

### 이럴 때 씁니다

- 목록 · 표 · 카드 묶음처럼 **`Skeleton` 여러 개가 한 영역**을 채울 때
- 화면에 로딩 중인 영역이 여럿이라 **무엇이** 로딩 중인지 말해야 할 때 (`semanticLabel: '주문 목록 불러오는 중'`)

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| `Skeleton` 하나만 단독으로 둘 때. 단독 `Skeleton`은 스스로 알립니다. | [Skeleton](/components/skeleton) |
| 자리 모양을 흉내 낼 필요 없이 "작업 중"만 보여 줄 때 | [Loading](/components/loading) |

<a id="기본-사용법-basic-usage"></a>

### 기본 코드

한 영역을 채우는 `Skeleton`들을 `child` 하나로 묶어 감쌉니다. `Skeleton`의 크기는 Flutter에서는 숫자로, Web에서는 CSS 문자열로 줍니다.

<Split>

<Code language="dart" title="Flutter">
LoadingRegion(
  semanticLabel: '주문 목록 불러오는 중',
  child: Column(
    spacing: CoreSpace.space8,
    children: [
      Skeleton(height: 20),
      Skeleton(height: 20),
      Skeleton(height: 20),
    ],
  ),
)
</Code>

<Code language="dart" title="Jaspr Web">
LoadingRegion(
  semanticLabel: '주문 목록 불러오는 중',
  child: div(
    [
      Skeleton(height: '20px'),
      Skeleton(height: '20px'),
      Skeleton(height: '20px'),
    ],
    classes: 'flex flex-col gap-space8',
  ),
)
</Code>

</Split>

영역에는 켜고 끄는 파라미터가 없습니다. 로딩이 끝나면 앱이 가진 조건으로 **영역째** 실제 내용으로 바꿉니다. 아래의 `orderSkeletons`는 `Skeleton`을 담은 묶음이고, `OrderList`는 앱의 목록입니다.

<Code language="dart" title="로딩이 끝나면 영역째 바꾸기">
isLoading
    ? LoadingRegion(child: orderSkeletons)
    : OrderList(orders: orders)
</Code>

<a id="사용-가이드라인-usage-guidelines"></a>
<a id="do"></a>
<a id="dont"></a>

### 문구와 감싸는 범위

<Cards columns="2">
<Card demo="loading-region/do-name" tone="do" eyebrow="이렇게 하세요">

영역마다 무엇이 로딩 중인지 `semanticLabel`로 말합니다. 문구는 앱의 내용이라 직접 넘깁니다.

</Card>
<Card demo="loading-region/dont-default-label" tone="dont" eyebrow="이렇게 하지 마세요">

영역이 둘 이상인데 기본 문구만 쓰면 모두 같은 로딩 문구라 어느 쪽인지 알 수 없습니다.

</Card>
<Card demo="loading-region/do-skeletons-only" tone="do" eyebrow="이렇게 하세요">

로딩과 상관없이 쓸 수 있는 컨트롤은 영역 밖에 두고 `Skeleton`만 감쌉니다. 선은 영역의 범위를 보이려고 문서가 그린 것입니다.

</Card>
<Card demo="loading-region/dont-controls-inside" tone="dont" eyebrow="이렇게 하지 마세요">

영역은 `child` 전체를 보조 기술에서 숨깁니다. 안에 둔 필터 버튼도 함께 숨겨집니다.

</Card>
</Cards>

감싸는 범위는 코드로 이렇게 갈립니다. 예제는 Flutter이고, Web에서는 `Column` 자리에 flex `div`를 씁니다.

<Split>

<Code language="dart" title="이렇게 하세요">
Column(
  children: [
    filterBar,
    LoadingRegion(
      semanticLabel: '주문 목록 불러오는 중',
      child: orderSkeletons,
    ),
  ],
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 필터 버튼이 보조 기술에서 사라집니다.
LoadingRegion(
  child: Column(
    children: [filterBar, orderSkeletons],
  ),
)
</Code>

</Split>

## 배치

LoadingRegion은 눈에 보이는 레이아웃 상자를 더하지 않습니다. Flutter에서는 레이아웃이 `child` 그대로입니다. Web에서는 숨긴 안내 요소가 레이아웃 흐름 밖에 놓이고 `child`를 감싼 요소가 `display: contents`라서, flex · grid · 일반 흐름이 `child`를 영역의 부모 바로 아래에 있는 것처럼 배치합니다. 폭이나 안쪽 여백은 `child`에 줍니다.

<Preview demo="loading-region/layout-gap" />

### Web의 간격은 부모의 gap으로

Web의 영역은 부모 안에 형제 요소 둘(숨긴 안내 요소와 `display: contents` 래퍼)을 둡니다. 그래서 부모의 형제 선택자 기반 규칙(`space-y-*` · `divide-*` · `:first-child`)은 `child`가 아니라 이 두 요소를 대상으로 합니다. 래퍼에는 상자가 없어 래퍼가 받을 간격이나 구분선은 `child`에 나타나지 않습니다. 영역이 빠지고 실제 내용이 들어오면 그 내용에는 규칙이 걸려, 간격이 생기며 화면이 움직일 수 있습니다. flex · grid의 `gap`은 영향을 받지 않으므로 영역의 부모에는 `gap`을 씁니다.

<Code language="dart" title="Jaspr Web">
div(
  [
    Text('주문 내역').titleSmall,
    LoadingRegion(child: orderSkeletons),
    Text('최근 30일 기준').labelSmall,
  ],
  classes: 'flex flex-col gap-space12',
)
</Code>

### Web에서 둘 수 있는 자리

Web의 영역은 `<div>` 두 개를 만듭니다. `<p>` 안이나 `<ul>` · `<ol>` · `<table>` · `<tbody>`의 바로 아래처럼 HTML이 `<div>`를 허용하지 않는 자리에는 두지 않습니다. 이때는 목록이나 표를 바깥에서 감쌉니다.

## 테마와 스타일

LoadingRegion은 눈에 보이는 겉모습이 없습니다. 스타일 파라미터와 `CoreComponentTheme`의 자리가 없고, `withStyle` 체인도 없습니다. 자리표시의 색 · 모서리 · 맥동은 [Skeleton](/components/skeleton)의 `skeletonStyle`로 바꿉니다.

<a id="접근성-accessibility"></a>

## 접근성

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 문구를 라벨로 가진 라이브 영역 노드 하나를 만듭니다. `status` 역할은 Flutter에서 `liveRegion` 표시로 전해지고, `SemanticsRole`은 따로 붙지 않습니다. 노드를 따로 두므로(`container: true`) 라벨이 붙은 부모 노드에 섞이지 않습니다. Flutter SDK 문서는 Android · iOS의 라이브 영역 알림이 정중한(polite) 알림이며, 스크린 리더가 다른 것을 읽는 중이면 읽히지 않을 수 있다고 설명합니다. |
| Jaspr Web | 눈에 보이지 않게 숨긴(`sr-only`) `<div role="status">` 하나가 문구를 **글자로** 담습니다. 라이브 영역은 이름이 아니라 내용을 읽기 때문입니다. `aria-live`는 따로 붙이지 않고 `status` 역할의 기본값인 정중한(polite) 알림을 따릅니다. 정중한 알림은 읽던 문장을 끊지 않습니다. |

### 키보드

없음. LoadingRegion은 어떤 키도 처리하지 않습니다.

### 스크린 리더

- 영역 하나에 라이브 영역 하나입니다. 안쪽 `Skeleton`은 두 플랫폼 모두 자기 알림을 만들지 않습니다.
- 알리는 문구는 `semanticLabel`이고, 넘기지 않으면(`null`) 로케일의 로딩 문구입니다. 무엇이 로딩 중인지는 이 문구로 말합니다.
- Flutter의 `child`는 `ExcludeSemantics` 아래에 있어 시맨틱 트리에 들어가지 않습니다.
- Web의 `child`는 `aria-hidden="true"`인 `display: contents` 요소 안에 있습니다.

### 포커스 관리

LoadingRegion은 포커스를 옮기거나 가두지 않습니다. `child` 안의 포커스 가능한 요소는 보조 기술에서 숨겨진 채로 포커스를 받을 수 있고, 포인터로도 누를 수 있습니다. 로딩 중에 쓸 컨트롤은 영역 밖에 둡니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 로딩이 끝난 것은 알리지 않습니다. 영역을 실제 내용으로 바꿀 때 LoadingRegion이 따로 내는 안내는 없습니다. |
| 공통 | `child`는 통째로 숨겨집니다. 일부만 로딩 중이라면 로딩 중인 부분만 감쌉니다. |
| Jaspr Web | 안내 요소는 문구가 이미 든 상태로 삽입됩니다. [Toast](/components/toast) 카드의 `role="status"`도 같은 방식입니다. 이렇게 새로 삽입된 `status`를 바로 읽는지는 스크린 리더마다 다를 수 있으므로, 이 알림이 중요하면 지원하는 스크린 리더에서 확인하세요. |
| Jaspr Web | 내용 숨김은 `display: contents` 요소의 `aria-hidden`에 기댑니다. 오래된 브라우저에서는 무시될 수 있습니다. |
| Jaspr Web | 부모의 형제 선택자 기반 간격은 `child`에 닿지 않습니다. [배치](#배치)에서 설명합니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

클래스 이름과 `child` · `semanticLabel` 파라미터는 두 플랫폼이 같습니다. 알리고 숨기는 방법은 각 플랫폼의 접근성 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `child` 타입 | `Widget` | `Component` |
| 알림 | 문구를 라벨로 가진 라이브 영역 노드(`liveRegion`) | 숨긴 `role="status"` 요소의 글자 |
| 내용 숨김 | `ExcludeSemantics` | `aria-hidden="true"` + `display: contents` |
| 레이아웃 | `child` 그대로 | 형제 `<div>` 두 개가 생깁니다. 부모의 형제 선택자 규칙은 `child`에 닿지 않습니다. |
| `Skeleton`이 영역을 아는 방법 | `LoadingRegionScope`(`InheritedWidget`) | `LoadingRegionScope`(`InheritedComponent`) |
| 기본 문구를 읽는 곳 | `CoUILocalizations.of(context).loadingLabel` | `CouiLocalizations.of(context).loadingLabel` |

`LoadingRegionScope`는 패키지 밖으로 내보내지 않습니다. 알리는 영역 없이 `Skeleton`만 조용해지는 일을 막기 위해서입니다.

<a id="props-parameters"></a>

## API

두 플랫폼의 생성자는 모두 `const`입니다. Web의 LoadingRegion은 `id` · `classes` · `css` · `attributes`를 받지 않으므로, 모양과 배치는 `child`에서 정합니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `Widget` (Flutter) · `Component` (Web) | 필수 | 로딩 중인 영역. 보통 내용 자리를 채우는 `Skeleton`들입니다. 영역이 알리는 동안 보조 기술에서 숨겨집니다. |
| `semanticLabel` | `String?` | `null` | 알릴 문구. `null`이면 화면을 그리는 시점의 로케일 로딩 문구(영어 "Loading", 한국어 "로딩 중")를 씁니다. |

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="loading-region/related-skeleton" title="Skeleton">

영역 안에서 내용 자리를 채우는 자리표시입니다.

</Card>
<Card demo="loading-region/related-loading" title="Loading">

자리 모양 없이 "작업 중"만 보여 주는 표시입니다.

</Card>
</Cards>
