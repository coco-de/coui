---
title: Breakpoint
description: 현재 글로벌 viewport의 breakpoint/tier를 조회하는 non-widget 접근자
category: layout
platforms: [flutter, web]
related: [media-query, stage-container]
tags: [responsive, breakpoint, viewport, tier]
---

# Breakpoint

`Breakpoint`는 "지금 화면이 mobile/tablet/desktop 중 무엇인가"를 답하는 **non-widget 값 접근자**입니다. 렌더 산출물이 없습니다 — `MediaQueryVisibility`처럼 조건부로 `child`를 그리는 컴포넌트가 아니라, `BuildContext` 확장 getter(`context.breakpointTier` 등)로 값만 반환합니다. 값 분기(`if (context.isMobile) ... else ...`)는 직접 작성합니다.

## Live Preview

<LivePreview component="breakpoint" />

> 프리뷰의 두 `width` 값이 다른 것은 정상입니다 — Breakpoint 는 **자기 앱의 뷰포트**를 측정하므로, Web 데모는 브라우저 창 너비를, Flutter 데모는 페이지에 임베드된 Flutter 뷰(작은 앱 창)의 너비를 각각 보고합니다. 실제 Flutter 앱에서는 OS 창 너비가 측정됩니다.

라이브 프리뷰는 현재 `width`/`tier`/`coreBreakpoint`를 한 줄로 보여줍니다. 브라우저 창(또는 에뮬레이터)을 리사이즈하면 값이 갱신됩니다.

## 사용 시기

- 레이아웃을 mobile/tablet/desktop 3단계로 분기할 때 (`Scaffold`의 sidebar 유무, `NavigationBar` ↔ `NavigationBar(rail:)` 전환 등)
- 컴포넌트 내부에서 이미 존재하는 `CoreBreakpoint`(Tailwind 6단계 스케일) 소비처와 상호운용할 때
- `responsive_framework`의 `context.breakpoint...` 접근자를 CoUI 네이티브 접근자로 교체할 때 (아래 마이그레이션 가이드 참조)

값에 따라 **다른 위젯/컴포넌트를 통째로 교체**하고 싶다면 `Breakpoint` 대신 [MediaQuery](/components/media-query)(`MediaQueryVisibility`)를 사용하세요 — 그쪽은 `child`/`alternateChild` 슬롯을 직접 그립니다.

## 기본 사용법

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
// 주 조회 API — BuildContext 확장 getter
final tier = context.breakpointTier; // CoreBreakpointTier.mobile/.tablet/.desktop
if (context.isDesktop) {
  // sidebar 있는 레이아웃
}

// width까지 필요하면 Breakpoint(context) 인스턴스
final breakpoint = Breakpoint(context);
Text('width=${breakpoint.width} tier=${breakpoint.tier.name}');
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
// 주 조회 API — BuildContext 확장 getter (Flutter와 멤버명 동일)
final tier = context.breakpointTier; // CoreBreakpointTier.mobile/.tablet/.desktop
if (context.isDesktop) {
  // sidebar 있는 레이아웃
}

// width까지 필요하면 Breakpoint(context) 인스턴스
final breakpoint = Breakpoint(context);
Text('width=${breakpoint.width} tier=${breakpoint.tier.name}');
```

  </TabItem>
</Tabs>

⚠️ **Web은 `resolveBreakpoint`가 one-shot 관측**입니다 — SSR-safe하게 `window.innerWidth`(또는 서버에서는 폴백값 `0`)를 그 호출 시점에 한 번 읽을 뿐, 내부적으로 `ResizeObserver`/rebuild를 걸지 않습니다. 리사이즈에 실시간으로 반응하는 UI가 필요하면(라이브 프리뷰가 하는 것처럼) 소비 컴포넌트가 직접 작은 `StatefulComponent`를 만들어 `window` `resize` 리스너에서 `setState`를 호출하세요 — `StageContainer`/`Window`가 자기 로컬 측정에 쓰는 것과 동일한 패턴입니다. Flutter는 `MediaQuery.sizeOf(context)`가 `InheritedWidget` 의존성을 등록하므로 위젯이 리사이즈마다 자동으로 rebuild됩니다 — 별도 배선이 필요 없습니다.

## Props / Parameters

`Breakpoint`는 렌더 산출물이 없는 값 접근자이므로 겉모습을 바꾸는 값 묶음(`xxxStyle`)도, named 파라미터도 갖지 않습니다. 생성자가 받는 것은 관측 대상 컨텍스트 하나뿐입니다.

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `context` | `BuildContext` | 필수 (positional) | 글로벌 viewport 를 관측할 컨텍스트. Flutter·Web 동일 |

실제 소비는 생성자보다 아래 `BuildContext` 확장 getter 를 씁니다.

### API

`Breakpoint`는 렌더링하지 않으므로 named-properties 생성자 파라미터가 아니라 **`BuildContext` 확장 getter**로 노출됩니다. Flutter/Web 양쪽에서 멤버 이름이 완전히 동일합니다.

| 멤버 | 타입 | 설명 |
|------|------|------|
| `context.breakpointTier` | `CoreBreakpointTier` | 현재 tier — `mobile` / `tablet` / `desktop`. 가장 자주 쓰는 조회 API. |
| `context.coreBreakpoint` | `CoreBreakpoint` | 현재 활성 breakpoint(Tailwind 6단계: `xs`/`sm`/`md`/`lg`/`xl`/`xxl`). `responsive_framework`의 동명 `BuildContext.breakpoint` getter와의 충돌을 피하려 `breakpoint`가 아니라 `coreBreakpoint`로 명명됨. |
| `context.isMobile` | `bool` | `context.breakpointTier == CoreBreakpointTier.mobile`의 단축형. |
| `context.isTablet` | `bool` | `context.breakpointTier == CoreBreakpointTier.tablet`의 단축형. |
| `context.isDesktop` | `bool` | `context.breakpointTier == CoreBreakpointTier.desktop`의 단축형. |
| `Breakpoint(context).width` | `double` | 관측 시점의 글로벌 viewport 폭(logical px). `BuildContext` 확장에는 없고 `Breakpoint` 인스턴스에만 있음. |
| `Breakpoint(context).coreBreakpoint` | `CoreBreakpoint` | `context.coreBreakpoint`와 동일 — `Breakpoint`가 `CoreBreakpointContract`를 구현하는 인스턴스 형태. |
| `Breakpoint(context).tier` | `CoreBreakpointTier` | `context.breakpointTier`와 동일. |

### `resolveBreakpoint` — `boundaries` override

모든 접근자는 안에서 `resolveBreakpoint(context, {boundaries:})`를 호출합니다. `boundaries`는 **tier 경계를 재정의**하는 유일한 방법입니다 — 필요하면 직접 호출해 부분(partial) override할 수 있습니다(누락된 tier는 기본값으로 폴백). `boundaries`는 겉모습이 아니라 동작을 정하는 파라미터입니다 — 그래서 `CoreXxxStyle` 슬롯이 아니라 `CoreBreakpointContract.defaultBoundaries` 위에 직접 얹힙니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
final resolved = resolveBreakpoint(
  context,
  boundaries: {
    // tablet 경계만 sm(640px)으로 낮춤 — mobile/desktop 경계는 기본값 유지
    CoreBreakpointTier.tablet: CoreBreakpoint.sm,
  },
);
resolved.tier;       // 커스텀 경계로 판정된 CoreBreakpointTier
resolved.breakpoint; // CoreBreakpoint
resolved.width;      // double
```

  </TabItem>
  <TabItem label="Web" value="web">

`resolveBreakpoint`/`ResolvedBreakpoint`는 Web(`coui_web`)의 소스 파일에도 Flutter와 동일한 시그니처로 존재하지만, 현재 `coui_web.dart` 배럴은 상위 접근자(`Breakpoint`/`context.breakpointTier` 등)만 재노출하고 이 둘은 재노출하지 않습니다 — Web에서 `boundaries`를 override하려면 지금은 `context.breakpointTier`가 기본 경계로 판정한 값을 소비 측에서 직접 재해석해야 합니다. `resolveBreakpoint`가 배럴에 재노출되면 이 문서는 Flutter와 동일한 코드 샘플로 갱신됩니다.

  </TabItem>
</Tabs>

## 기본 tier 경계값

| Tier | 기준 `CoreBreakpoint` | 최소 너비 (px) |
|------|----------------------|-------------|
| `mobile` | `xs` | 0 |
| `tablet` | `md` | 768 |
| `desktop` | `lg` | 1024 |

## `CoreBreakpoint` 값 (6단계, Tailwind 표준)

| 이름 | 최소 너비 (px) |
|------|-------------|
| `xs` | 0 |
| `sm` | 640 |
| `md` | 768 |
| `lg` | 1024 |
| `xl` | 1280 |
| `xxl` | 1536 |

## 마이그레이션 가이드 — `responsive_framework` → CoUI

| 상황 | Before (`responsive_framework`) | After (CoUI) |
|------|----------------------------------|--------------|
| 모바일 판정 | `context.breakpoint.isMobile` | `context.isMobile` |
| 태블릿 판정 | `context.breakpoint.isTablet` | `context.isTablet` |
| 데스크탑 판정 | `context.breakpoint.isDesktop` | `context.isDesktop` |
| 특정 breakpoint보다 큼 (예: TABLET 초과) | `context.breakpoint.largerThan(TABLET)` | `context.isDesktop` (3-tier 모델에서 "TABLET보다 큼" = desktop) |
| 현재 breakpoint 이름 | `context.breakpoint.name` | `context.coreBreakpoint.name` (`'xs'`/`'sm'`/`'md'`/`'lg'`/`'xl'`/`'xxl'`) |
| 현재 viewport 폭 | `MediaQuery.of(context).size.width` | `Breakpoint(context).width` |
| 커스텀 breakpoint 등록 (`ResponsiveBreakpoints.builder(breakpoints: [...])`) | 앱 루트에서 전역 설정 | 호출부에서 `resolveBreakpoint(context, boundaries: {...})`로 필요한 곳만 override — 전역 설정 불필요 |

**왜 이관하는가**: `responsive_framework`는 Flutter 전용 패키지라 Web(Jaspr)에 대응이 없습니다. `Breakpoint`/`context.breakpointTier`는 `CoreBreakpoint.toTier()` 판정 로직을 공유합니다. 같은 관측 너비와 경계에는 같은 판정이지만, viewport 관측·갱신 시점은 아래 플랫폼 차이점처럼 다릅니다.

## 동작 스펙 (Behavior)

- getter를 읽을 때 글로벌 viewport 너비를 측정하고 `width >= minWidth` 를 만족하는 가장 큰 `CoreBreakpoint` 를 고릅니다. 너비 단위는 Flutter 논리 px / Web CSS px입니다.
- 기본 tier는 `mobile: xs(0)` · `tablet: md(768)` · `desktop: lg(1024)` 경계이며, 내부 `resolveBreakpoint(boundaries:)` 는 tier별 부분 경계 오버라이드를 받습니다.
- 값을 반환하는 접근자이며 렌더 노드 · 클릭 콜백 · 비활성 상태는 없습니다. 지역 패널의 가용 폭을 측정하는 기능도 아닙니다.

## 사용 가이드라인 (Usage Guidelines)

### ✅ Do

<Callout type="tip">

**픽셀 폭이 필요하면 `Breakpoint(context)` 인스턴스로 조회**

```dart
final width = Breakpoint(context).width;
if (width < 900) {
  // 3-tier 모델로 표현 안 되는 세밀한 분기
}
```

`BuildContext` 확장 getter(`context.breakpointTier` 등)는 tier 값만 제공합니다. 실제 픽셀 폭이 필요하면 `Breakpoint(context)` 인스턴스의 `.width` 를 써야 합니다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**`desktop` tier 하나로 세밀한 반응형 분기를 흉내내지 않기**

```dart
// ❌ desktop tier 하나에 1024px ~ 2560px 전부를 뭉뚱그림
if (context.isDesktop) {
  // ...
}
```

`desktop` tier 는 `CoreBreakpoint.lg`(1024px) 이상을 전부 포함합니다. 그 안에서 더 세분화된 분기가 필요하면 3-tier 대신 `context.coreBreakpoint`(6단계 Tailwind 스케일: `xs`/`sm`/`md`/`lg`/`xl`/`xxl`) 또는 `Breakpoint(context).width` 를 직접 비교하세요.

</Callout>

## 접근성 (Accessibility)

`Breakpoint`는 **렌더 산출물이 없는 값 접근자**입니다. Flutter·Web 어느 쪽도 `class Breakpoint implements CoreBreakpointContract` 일 뿐 `StatelessWidget` / `UiComponent` 를 상속하지 않아 DOM 노드도 semantics 노드도 만들지 않습니다. 화면에 나타나는 것은 이 값으로 분기한 소비 코드가 그린 결과뿐이고, 아래 네 축의 접근성 책임도 그쪽에 있습니다.

### 역할

없음. 양 플랫폼 모두 `Semantics` 호출도 `role` / `aria-*` 를 붙일 엘리먼트도 없습니다. 실제 소비 표면인 `BuildContext` 확장 getter(`context.breakpointTier` 등)도 값 하나를 돌려주는 순수 함수라 접근성 트리에 아무것도 남기지 않습니다.

### 키보드

없음. 두 플랫폼 다 키 이벤트를 구독하지 않고, 생성자가 받는 것은 관측 대상 `BuildContext` 하나뿐이라 이벤트 핸들러를 실을 표면 자체가 없습니다.

### 스크린 리더

리더가 읽는 것이 없습니다. 접근 가능한 이름도, 상태 통보(live region)도 없으며 tier 가 바뀌어도 **아무것도 안내되지 않습니다** — 안내가 필요하다면 tier 로 분기해 트리를 바꾸는 소비 코드가 직접 제공해야 합니다.

### 포커스 관리

없음. 포커스 가능한 노드를 만들지 않으므로 진입·이탈·트랩이 성립하지 않습니다 (Flutter 에 `FocusNode` / `Focus` 가 없고 Web 에 `tabindex` 를 실을 엘리먼트가 없습니다).

### 알려진 제약

이 접근자는 `CoreBreakpointTier` 값 하나를 돌려줄 뿐이므로, 접근성 측면에서 실제로 문제가 되는 지점은 **그 값이 언제 다시 평가되는가**입니다.

- **Web**: `resolveBreakpoint`는 호출 시점에 `window.innerWidth` 를 한 번 읽는 one-shot 관측이며 `ResizeObserver`나 rebuild 배선이 없습니다. 창 리사이즈뿐 아니라 **확대(zoom)로 인한 리플로우에서도** 소비 컴포넌트가 스스로 다시 빌드하지 않으면 tier가 갱신되지 않아, 확대한 사용자가 이전 tier의 레이아웃을 계속 보게 됩니다. 대안은 있습니다 — `coui_web` 배럴이 `listenForViewportResize` / `viewportSize` 를 함께 내보내므로, 소비 컴포넌트가 `StatefulComponent` 안에서 그 리스너로 `setState` 를 호출하면 됩니다(레포 안 선례: `ResponsiveRowColumn`).
- **SSR**: 서버에는 `dart:js` 가 없어 폭이 `0`으로 폴백되고 `CoreBreakpoint.xs` → `mobile` tier로 판정됩니다. 첫 페인트는 항상 mobile 분기이며 클라이언트에서 다시 평가될 때 레이아웃이 바뀔 수 있습니다.
- **Flutter**: `MediaQuery.widthOf(context)` 가 `InheritedWidget` 의존성을 등록하므로 리사이즈 시 위젯이 자동으로 rebuild되고 tier가 따라옵니다 — 별도 배선이 필요 없습니다. 위 두 항목은 Web 에만 해당합니다.

## 크로스 플랫폼 차이점 (Platform Differences)

| 항목 | Flutter | Web |
|------|---------|-----|
| 관측 | `MediaQuery.widthOf(context)` | 호출 시점 `window.innerWidth` |
| 리사이즈 갱신 | MediaQuery 의존성이 rebuild | 접근자 자체에는 resize 구독 없음. 소비자가 재평가해야 함 |
| 서버 렌더 | 네이티브 viewport | SSR stub 너비 `0` → `xs` / `mobile` |
| 판정 함수 공개 여부 | 배럴에서 `resolveBreakpoint` 노출 | 현재 배럴은 접근자만 노출. 이 함수의 export 누락은 공개 API 결손 |

## 관련 컴포넌트

- **[MediaQuery](/components/media-query)** — 값 대신 조건부로 `child`/`alternateChild`를 통째로 교체하고 싶을 때.
- **[StageContainer](/components/stage-container)** — breakpoint별 padding을 자동 적용하는 반응형 컨테이너.
