---
title: LoadingRegion
description: 아직 내용이 오지 않은 영역의 "로딩 중" 을 한 번만 알리는 래퍼
category: display
platforms: [flutter, web]
related: [skeleton, loading]
tags: [loading, skeleton, accessibility, live-region]
---

# LoadingRegion

한 영역을 채우는 스켈레톤들을 감싸 **"로딩 중" 을 영역 단위로 한 번** 알립니다. 안쪽 스켈레톤은 자기가 영역 안에 있음을 알고 자기 알림을 끕니다 — 스켈레톤 열 개가 알림 열 번이 되지 않습니다. 화면에 그리는 것은 없습니다. 레이아웃 상자(flex · grid · flow)는 `child` 그대로입니다 — Web 에서 부모의 형제 선택자 기반 간격(`space-y-*` · `divide-*`)만 영역을 지나 `child` 에 닿지 않으므로, 영역의 부모에는 `gap` 을 쓰세요.

## Live Preview

<LivePreview component="loading-region" />

## 사용 시기 (When to Use)

**이 컴포넌트를 사용하세요:**
- 목록·표·카드 묶음처럼 **스켈레톤 여러 개가 한 영역**을 채울 때
- 화면에 로딩 중인 영역이 여럿이라 **무엇이** 로딩 중인지 말해야 할 때 (`semanticLabel: '주문 목록 불러오는 중'`)

**대신 다른 컴포넌트를 사용하세요:**
- **[Skeleton](/components/skeleton)** 하나만 단독으로 쓸 때 — 단독 스켈레톤은 스스로 알립니다
- **[Loading](/components/loading)**: 자리 모양을 흉내 낼 필요 없이 "작업 중" 만 보여 줄 때

## 기본 사용법 (Basic Usage)

```dart
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
```

로딩이 끝나면 호출하는 쪽 조건으로 영역째 실제 내용으로 바꿉니다.

```dart
isLoading
    ? LoadingRegion(child: orderSkeletons)
    : OrderList(orders: orders)
```

## Props / Parameters

### `LoadingRegion`

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `child` | `W` | 필수 | 로딩 중인 영역 — 보통 내용 자리를 채우는 스켈레톤들. 영역이 알리는 동안 보조 기술에서 숨겨집니다 |
| `semanticLabel` | `String?` | `null` | 알릴 문구. `null` 이면 렌더 시점 로케일의 로딩 문구(영어 "Loading", 한국어 "로딩 중")를 읽습니다 |

눈에 보이는 겉모습이 없어 Style · Theme 슬롯이 없습니다.

## 동작 스펙 (Behavior)

- 영역이 `status` 역할의 라이브 영역 하나가 되어 `semanticLabel`(또는 로케일 문구)을 알립니다. 정중한(polite) 알림이라 읽던 문장을 끊지 않습니다.
- 안쪽 `Skeleton` 은 영역 안에 있으면 자기 알림을 내지 않습니다. 영역 밖의 스켈레톤은 지금처럼 스스로 알립니다 — Flutter 에서는 영역 안에서 연 오버레이도 영역 밖에 그려지므로 그 안의 스켈레톤이 스스로 알립니다.
- 영역 안에 영역을 다시 두면 바깥 영역만 알립니다.
- `child` 는 영역이 알리는 동안 보조 기술에서 숨겨집니다. 로딩 중에 실제로 쓸 수 있는 내용은 영역 밖에 둡니다.
- 동작 줄이기 설정에서도 알림은 그대로입니다(스켈레톤 맥동만 멈춥니다).

## 사용 가이드라인 (Usage Guidelines)

### ✅ Do

<Callout type="tip">

**영역마다 무엇이 로딩 중인지 말하기**

```dart
LoadingRegion(semanticLabel: '주문 목록 불러오는 중', child: orderSkeletons)
LoadingRegion(semanticLabel: '추천 상품 불러오는 중', child: productSkeletons)
```

화면에 로딩 영역이 둘 이상이면 기본 문구("로딩 중")만으로는 어느 쪽인지 알 수 없습니다. 문구는 앱 콘텐츠라 호출자가 넘깁니다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**지금 쓸 수 있는 내용을 영역 안에 넣지 않기**

```dart
// ❌ 필터 버튼이 보조 기술에서 사라진다
LoadingRegion(
  child: Column(children: [filterBar, orderSkeletons]),
)
```

영역은 `child` 전체를 보조 기술에서 숨깁니다. 로딩과 상관없이 쓸 수 있는 컨트롤은 영역 밖에 두고, 스켈레톤만 감싸세요.

</Callout>

## 접근성 (Accessibility)

### 역할

- **Flutter**: `CoUISemantics(role: status, container: true)` — 라이브 영역 노드 하나에 문구가 붙습니다. `container` 라 라벨이 붙은 부모 노드에 섞이지 않습니다.
- **Web**: 시각적으로 숨긴(`sr-only`) `role="status"` 요소 하나가 문구를 **텍스트로** 담습니다. 라이브 영역은 이름이 아니라 내용을 읽기 때문입니다.

### 키보드

없습니다. 이 컴포넌트는 어떤 키도 처리하지 않습니다.

### 스크린 리더

- 영역 하나에 알림 하나입니다. 안쪽 스켈레톤은 알림을 만들지 않습니다(양 플랫폼 모두 `LoadingRegionScope` 를 읽습니다).
- **Flutter**: `child` 는 `ExcludeSemantics` 아래에 있습니다.
- **Web**: `child` 는 `aria-hidden="true"` 인 `display: contents` 요소 안에 있습니다 — 레이아웃 상자를 더하지 않습니다.

### 포커스 관리

포커스를 관리하지 않습니다. `child` 안의 포커스 가능한 요소는 보조 기술에서 숨겨진 채 포커스를 받을 수 있으므로, 로딩 중에 쓸 컨트롤은 영역 밖에 둡니다.

### 알려진 제약

- **Web — 삽입 순간에 이미 문구가 찬 상태로 나타납니다.** `Toast` 와 같은 방식입니다. 이렇게 삽입된 status 를 바로 읽는지는 스크린리더마다 다를 수 있어 실기 확인 항목입니다.
- **Web — `display: contents` 요소의 `aria-hidden`.** 현행 브라우저는 따르지만 오래된 브라우저에서는 무시될 수 있습니다.
- **Web — 부모의 형제 선택자 기반 간격은 `child` 에 닿지 않습니다.** 영역은 부모 안에 숨긴 안내 요소와 `display: contents` 래퍼, 둘을 형제로 끼웁니다. `space-y-*` · `divide-*` · `:first-child` 는 그 둘에 걸려 `child` 에는 간격이 생기지 않고, 영역이 빠지면 간격이 생겨 콘텐츠가 점프합니다. flex · grid 의 `gap` 은 영향이 없습니다.
- 영역은 내용을 통째로 숨깁니다. 일부만 로딩 중인 영역이라면 로딩 중인 부분만 감싸세요.

## 크로스 플랫폼 차이점 (Platform Differences)

| 항목 | Flutter | Web |
|------|---------|-----|
| 클래스명 | `LoadingRegion` | `LoadingRegion` |
| child 타입 | `Widget` | `Component` |
| 알림 | `CoUISemantics(role: status)` 라이브 영역 노드 | 숨긴 `role="status"` 요소의 텍스트 |
| 내용 숨김 | `ExcludeSemantics` | `aria-hidden="true"` + `display: contents` |
| 스켈레톤 침묵 | `LoadingRegionScope`(InheritedWidget) | `LoadingRegionScope`(InheritedComponent) |

## 관련 컴포넌트 (Related Components)

- **[Skeleton](/components/skeleton)**: 영역 안에서 내용 자리를 채우는 자리표시
- **[Loading](/components/loading)**: 자리 모양 없이 "작업 중" 만 보여 주는 표시
