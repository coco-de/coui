---
title: Stacks
description: 자식을 z 축으로 겹쳐 쌓는 레이아웃 — `Stacks` + `Position` (Flutter `Stack` / `Positioned` 매핑)
category: layout
platforms: [flutter, web]
related: [group, resizable]
tags: [stack, layout, layer, z-stack, positioned]
---

# Stacks

z 축으로 자식을 겹쳐 그리는 레이아웃 primitive 입니다. 위젯 클래스 이름은 양
플랫폼 모두 **`Stacks`**, 절대 좌표로 배치되는 자식은 **`Position`** 입니다.
`StackLayout` 은 이 페이지를 가리키는 이름(경로 `/components/stack-layout`)일
뿐이고, 그런 클래스는 어느 플랫폼에도 없습니다.

Flutter 의 `Stack` 과 시맨틱이 1:1 동일하며 (`fit` / `alignment` / `clipBehavior` /
`textDirection`), 자식 중 `Position` 인 항목은 `top` / `right` / `bottom` /
`left` / `width` / `height` 로 절대 좌표 배치됩니다 — Flutter `Positioned` 와 동등.

카드 덱 같은 누적 겹침 효과는 자식들을 모두 `Position` 으로 감싸 `top: i * offset`
형태로 누적 좌표를 직접 지정해서 만듭니다.

## Live Preview

<LivePreview component="stack-layout" />

## 사용 시기 (When to Use)

**이 컴포넌트를 사용하세요:**
- 자식을 z 축으로 겹쳐야 할 때 (배지, 오버레이, 카드 덱)
- Flutter `Stack` / Web `position: absolute` 의 **양쪽 동일한 시맨틱** 이 필요할 때
- `Position` 으로 자식의 절대 좌표를 명시하고 싶을 때

**대신 다른 컴포넌트를 사용하세요:**
- `Resizable`: 분할 가능한 좌우/상하 영역이 필요할 때

## 기본 사용법 (Basic Usage)

```dart
// 카드 덱 — 자식들을 모두 Position 으로 감싸 누적 좌표 지정
Stacks(
  children: [
    for (var i = 0; i < labels.length; i++)
      Position(
        top: i * CoreSpace.space8,
        child: Card(child: Text(labels[i])),
      ),
  ],
)

// 일반 z 스택 — non-positioned 자식 + 우상단 배지
Stacks(
  children: [
    background,
    Position(
      top: CoreSpace.space8,
      right: CoreSpace.space8,
      child: badge,
    ),
  ],
)
```

Web 에서도 **동일한 생성자**로 사용합니다 — `children: List<Component>` 만 다릅니다.

## Props / Parameters

`W`는 합성 콘텐츠 타입으로 Flutter에서는 `Widget`, Web에서는 `Component`입니다. 위치와 크기 숫자는 논리 px 단위입니다.

### Stacks

| 이름 | 타입 (Flutter / Web) | 기본값 | 설명 |
|------|------|--------|------|
| `children` | `List<W>` | 필수 | 자식 목록. 마지막 자식이 최상단 |
| `alignment` | `CoreAlignment` | `CoreAlignment.topStart` | non-positioned 자식의 정렬 |
| `fit` | `CoreStackFit` | `CoreStackFit.loose` | 부모 constraint 전달 정책 (`loose` / `expand` / `passthrough`) |
| `clipBehavior` | `CoreClipBehavior` | `CoreClipBehavior.hardEdge` | overflow 클립 정책 (`none` / `hardEdge` / `antiAlias` / `antiAliasWithSaveLayer`) |
| `textDirection` | `CoreTextDirection?` | `null` | start/end 정렬을 ltr/rtl 로 해석할 방향 |

인스턴스별 스타일 슬롯은 없습니다 — 세 축(`alignment` / `fit` / `clipBehavior`)이
곧 이 컴포넌트의 겉모습 전부이고 위젯 파라미터로 직접 받습니다. Web 은 추가로
`id` / `classes` / `css` / `attributes` 와 DOM 이벤트 슬롯을 루트 `<div>` 로
통과시킵니다.

### Position

| 이름 | 타입 (Flutter / Web) | 기본값 | 설명 |
|------|------|--------|------|
| `child` | `W?` | 필수 인자 (nullable 허용) | 위치 지정할 자식 |
| `top` / `right` / `bottom` / `left` | `double?` | `null` | 스택 박스 가장자리에서의 거리 (logical px) |
| `width` / `height` | `double?` | `null` | 자식의 명시 크기 (logical px) |

`Position.fill({ ... })` 편의 생성자는 `top/right/bottom/left = 0` 으로
자식이 스택 전체를 채우게 합니다 — Flutter `Positioned` 의 `fill` 생성자에
대응합니다. 이 생성자는 `width` / `height` 를 받지 않습니다.

<a id="theming"></a>

## 스타일 시스템 (Style System)

### 테마 커스터마이징 (Theme Customization)

`CoreComponentTheme.stacks` 의 단일 `style` 슬롯에서 기본값을 오버라이드합니다.
`textDirection` 은 테마 슬롯에 없고 위젯 파라미터로만 받습니다:

```dart
CoreComponentTheme(
  stacks: CoreStacksTheme(
    style: CoreStacksStyle(
      alignment: CoreAlignment.topStart,
      fit: CoreStackFit.loose,
      clipBehavior: CoreClipBehavior.hardEdge,
    ),
  ),
)
```

## 동작 스펙 (Behavior)

자식을 선언 순서대로 겹쳐 그려 마지막 자식이 가장 위에 놓입니다. `Position` 자식은 스택 가장자리 기준 좌표·크기를 사용하고 나머지는 `alignment`·`fit`을 따릅니다. `Position.fill`은 네 가장자리 거리를 0으로 지정하며 폭·높이 인자를 받지 않습니다. 겹침과 클리핑만 담당하고 포커스 트랩·모달 배경 차단·선택 상태를 만들지 않습니다.

## 사용 가이드라인 (Usage Guidelines)

콘텐츠와 배지·스크림처럼 같은 영역에 겹칠 요소에는 Stacks를 사용합니다. 흐름 방향과 간격을 가진 배치는 [Frame](/components/frame), 사용자가 pane 크기를 조절해야 하면 [Resizable](/components/resizable)를 선택합니다.

### ✅ Do

<Callout type="tip">

**절대 좌표가 필요한 자식만 `Position` 으로 감싸기**

```dart
Stacks(
  alignment: CoreAlignment.center,
  children: [
    background,                                    // non-positioned → alignment 적용
    Position(top: CoreSpace.space8, right: CoreSpace.space8, child: badge),
  ],
)
```

절대 좌표가 필요한 자식만 `Position` 으로 감싸고 나머지는 `alignment` 에 맡기면, Flutter `Stack`/`Positioned` 와 동일한 시맨틱을 그대로 유지할 수 있습니다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**오버레이 아래 콘텐츠를 상호작용 가능한 채로 남겨두지 않기**

```dart
// ❌ 화면을 덮는 오버레이를 올렸지만 아래 폼은 그대로 상호작용 가능
Stacks(
  children: [
    interactiveForm,
    Position.fill(child: modalOverlay),
  ],
)
```

`Stacks` 는 가려진 레이어에 `ExcludeSemantics`/`inert` 를 걸지 않습니다 — 시각적으로 완전히 덮인 `interactiveForm` 도 여전히 Tab 으로 도달되고 스크린 리더에 읽힙니다. 오버레이 아래 콘텐츠의 상호작용을 실제로 막는 것은 호출자의 몫입니다.

</Callout>

### ✅ Do

<Callout type="tip">

**전체를 채우는 자식은 `Position.fill` 사용**

```dart
Position.fill(child: backdrop)
```

`top`/`right`/`bottom`/`left` 를 각각 `0` 으로 반복해서 채우는 대신 `Position.fill` 편의 생성자를 쓰면 스택 전체를 채우려는 의도가 코드에 그대로 드러납니다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**`Position.fill` 에 크기 지정 시도 금지**

```dart
// ❌ Position.fill 은 width / height 를 받지 않음
Position.fill(width: 200, height: 100, child: backdrop)
```

`Position.fill` 은 `top/right/bottom/left = 0` 만 고정하는 생성자라 `width`/`height` 파라미터가 없습니다 — 고정 크기가 필요하면 일반 `Position(width:, height:, ...)` 을 사용해야 합니다.

</Callout>

## 접근성 (Accessibility)

`Stacks` 는 시맨틱을 전혀 만들지 않는 순수 레이아웃 래퍼입니다. 리더가 읽는
내용은 전부 자식이 스스로 내보낸 것이며, 스택 자신은 아무것도 보태지 않습니다.

### 역할

- **Flutter**: `Stacks` 는 프레임워크 `Stack` 을, `Position` 은 프레임워크
  `Positioned` 를 그대로 반환합니다. `Semantics` 노드를 하나도 추가하지 않습니다.
- **Web**: 루트는 평범한 `<div>` 이고, `Position` 이 아닌 자식은 래퍼 `<div>` 로
  한 번 더 감쌉니다. `role` · `aria-*` · `tabindex` 를 붙이지 않습니다. 컴포넌트가
  스스로 만드는 속성은 `textDirection` 에서 온 `dir="ltr|rtl"` 하나뿐이고, 나머지
  `attributes` 는 호출자가 준 값이 그대로 통과합니다.

스택 영역에 역할(`region` · `group` 등)이나 이름이 필요하면 호출자가 직접 감싸서
붙여야 합니다.

### 키보드

처리하는 키가 없습니다. 양쪽 모두 자체 키 핸들러를 두지 않으며, Web 이 상속하는
`onKeyDown` / `onKeyUp` 은 호출자 통과용일 뿐 컴포넌트가 바인딩하는 키는 없습니다.

### 포커스 관리

포커스를 받지 않습니다. `FocusNode` 도 `tabindex` 도 없고, 포커스 트랩 · 복원 ·
순서 재정의를 하지 않습니다. 자식은 각자 가지고 온 포커스 가능성을 그대로 유지합니다.

### 스크린 리더

스택 자신은 읽히지 않습니다. Flutter 는 시맨틱 노드를 만들지 않아 자식만 자식
순서대로 읽히고, Web 은 일반 콘텐츠로 DOM 순서대로 읽힙니다. **리더가 따라가는
순서는 DOM 순서이지 시각적 z 순서나 `alignment` 가 아닙니다** — 마지막 자식이
화면에서 가장 위에 그려져도 읽히는 순서는 마지막입니다.

### 알려진 제약

- 겹친 자식은 **전부 동시에 트리에 존재**합니다. 가려진 레이어에 `inert` 나
  `ExcludeSemantics` 를 걸지 않으므로, 시각적으로 완전히 덮여 보이지 않는 레이어도
  여전히 읽히고 여전히 Tab 으로 도달합니다. 콘텐츠 위에 오버레이를 쌓는다면 가려진
  서브트리를 죽이는 것은 전적으로 호출자 몫입니다.
- 역할 · 레이블 · 그룹핑이 없어 스택은 리더의 구조 목록에 나타나지 않습니다.

이 컴포넌트가 직접 다루지 않는 축은 [전역 접근성 축](/accessibility) 에 있습니다.

## 크로스 플랫폼 차이점 (Platform Differences)

| 항목 | Flutter | Web |
| --- | --- | --- |
| 스택 배치 | 프레임워크 Stack | 루트 `<div>`와 비-Position 자식의 배치 래퍼 |
| 위치 지정 | 프레임워크 Positioned | Position의 CSS 위치 지정 |
| 클리핑 | `Clip` 정책으로 렌더 엔진에 전달 | CSS overflow와 레이어 배치 |
| 방향 | 프레임워크 TextDirection | 루트 `dir="ltr|rtl"` 속성 |

## 레거시 vs 통일 비교 (Migration Notes)

이전 버전의 Web CoUI 를 참조하는 코드에는 이 컴포넌트의 옛 이름이 Flutter 자체 위젯과 같았을 수 있습니다(겹침 대상: z축 레이어 위젯, 좌표 지정 위젯). Flutter 자체 위젯과 이름이 겹치면 프레임워크 심볼과 충돌하므로, Web 도 Flutter-first 원칙에 따라 `Stacks`/`Position` 으로 개명되었습니다.

| 항목 | 구버전 이름 | 통일 이름 |
|------|-------------|-----------|
| API | 동일 named properties | 동일 named properties |
| 이름 충돌 | Flutter/Dart 자체 위젯과 겹침 | 겹치지 않음 |

**마이그레이션**: 옛 이름을 각각 `Stacks`/`Position`/`Position.fill` 로 바꾸면 됩니다 — 파라미터는 그대로입니다.

## 관련 컴포넌트

- [Frame](./frame.md) — Auto Layout 프레임 (direction · gap · alignment)
- [Resizable](./resizable.md) — 분할 가능 영역
