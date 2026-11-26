---
title: MediaQuery
description: 반응형 브레이크포인트 기반 조건부 표시/숨김 컴포넌트
category: layout
platforms: [flutter, web]
related: [scrollable-client]
tags: [responsive, breakpoint, visibility]
---

# MediaQuery

`MediaQueryVisibility`는 **감싸는 박스의 너비**에 따라 `child`를 보이거나 `alternateChild`로 대체합니다. 임의 px(`minWidth`/`maxWidth`)과 Tailwind-표준 breakpoint(`minBreakpoint`/`maxBreakpoint`) 양쪽을 지원합니다.

재는 축이 viewport 가 아니라 **컨테이너**라는 점이 중요합니다 — Flutter 는 `LayoutBuilder` 의 부모 제약을 읽고(제약이 무한이면 주변 `MediaQuery` 의 너비를 대신 씀), Web 은 wrapper 에 `container-type: inline-size` 를 실어 `@container` 질의를 씁니다. 사이드바 안에 넣으면 화면이 넓어도 사이드바 폭을 기준으로 판정됩니다.

## Live Preview

<LivePreview component="media-query" />

## 사용 시기

- 작은 화면에서는 모바일 전용 UI, 큰 화면에서는 데스크탑 UI를 보여줄 때
- 폭이 좁을 때만 특정 도움말/축약 뷰를 보여주고 싶을 때
- 광고/배너처럼 특정 해상도 이상에서만 노출하고 싶을 때

## 기본 사용법

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
MediaQueryVisibility(
  minBreakpoint: .md,        // ≥ 768px에서 child 표시
  alternateChild: Text('모바일 전용'),
  child: Text('md 이상 전용'),
)

// 임의 px
MediaQueryVisibility(
  minWidth: 900,
  maxWidth: 1280,
  child: Text('900–1280px 범위에서만 표시'),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
MediaQueryVisibility(
  minBreakpoint: .md,
  alternateChild: div([Text('모바일 전용').bodyMedium.onSurface]),
  child: div([Text('md 이상 전용').bodyMedium.onSurface]),
)

// 임의 px — CoUI가 scoped @container 규칙을 inline으로 주입합니다
MediaQueryVisibility(
  minWidth: 900,
  maxWidth: 1280,
  child: div([Text('900–1280px 범위에서만 표시').bodyMedium.onSurface]),
)
```

  </TabItem>
</Tabs>

<a id="props"></a>
## Props / Parameters

`W` 는 Flutter의 `Widget`, Web의 Jaspr `Component` 입니다. `W?` 는 선택 슬롯입니다.

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `child` | `W` | 필수 | 범위 내일 때 보여줄 콘텐츠 |
| `alternateChild` | `W?` | `null` | 범위 밖일 때 대체 콘텐츠 |
| `minWidth` | `double?` | `null` | 최소 컨테이너 너비 (px) |
| `maxWidth` | `double?` | `null` | 최대 컨테이너 너비 (px) |
| `minBreakpoint` | `CoreBreakpoint?` | `null` | 최소 breakpoint (xs/sm/md/lg/xl/xxl) |
| `maxBreakpoint` | `CoreBreakpoint?` | `null` | 최대 breakpoint |

우선순위: `minWidth`/`maxWidth` (widget) > `minBreakpoint`/`maxBreakpoint` (widget) > `CoreMediaQueryVisibilityTheme.style` 의 px > 그 style 의 breakpoint.

## 브레이크포인트 값

| 이름 | 최소 너비 (px) |
|------|-------------|
| `xs` | 0 |
| `sm` | 640 |
| `md` | 768 |
| `lg` | 1024 |
| `xl` | 1280 |
| `xxl` | 1536 |

## 동작 스펙 (Behavior)

- 문서의 컴포넌트 API는 `MediaQueryVisibility` 입니다. 부모 컨테이너 너비가 min/max 범위 안이면 child, 밖이면 alternateChild를 표시합니다. alternateChild가 없으면 해당 영역을 비웁니다.
- 명시한 width가 같은 끝의 breakpoint보다 우선합니다. breakpoint의 **minWidth** 를 경계로 쓰므로 maxBreakpoint=md는 tablet 전체가 아니라 768 논리 px 경계입니다. min/max는 포함 범위이며 역전된 범위는 호출부가 피해야 합니다.
- 자체 콜백·포커스·비활성 상태는 없습니다. 너비 값을 읽어 분기 로직을 직접 작성하려면 **[Breakpoint](/components/breakpoint)**, 콘텐츠 두 슬롯을 교체하려면 MediaQueryVisibility입니다.

## 사용 가이드라인 (Usage Guidelines)

### ✅ Do

<Callout type="tip">

**임의 px 대신 breakpoint 토큰 사용**

```dart
MediaQueryVisibility(
  minBreakpoint: .md,
  alternateChild: const Text('모바일 전용'),
  child: const Text('데스크탑 전용'),
)
```

`CoreBreakpoint`(xs/sm/md/lg/xl/xxl)는 디자인 시스템 전체가 공유하는 척도입니다. `minWidth`/`maxWidth` 로 임의 px 를 직접 넣으면 다른 컴포넌트의 브레이크포인트와 어긋날 수 있습니다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**좁은 컨테이너 안에 넣고 화면 전체 폭을 기대하지 않기**

```dart
// ❌ 사이드바 폭(예: 300px) 기준으로 판정됨 — 화면 전체 폭이 아님
Sidebar(
  child: MediaQueryVisibility(
    minWidth: 900,
    child: const Text('900px 이상에서만'),
  ),
)
```

`MediaQueryVisibility` 는 viewport 가 아니라 **감싸는 컨테이너의 너비**를 기준으로 판정합니다(Flutter `LayoutBuilder` 부모 제약 / Web `@container`). 좁은 컨테이너 안에 넣으면 화면이 아무리 넓어도 그 컨테이너 폭 기준으로 숨겨집니다.

</Callout>

## 접근성 (Accessibility)

### 역할

반응형 가시성 유틸리티이므로 **자체 semantics 를 만들지 않습니다**. Flutter 는 `LayoutBuilder` 가 `SizedBox(child: …)` 를 돌려줄 뿐 `Semantics` 호출이 없고, Web 은 CSS containment(`container-type: inline-size`) 를 실어 나르는 wrapper `<div>` 와 주입된 `<style>` 요소만 내보내며 `role` / `aria-*` 를 붙이지 않습니다. 접근성 트리에 나타나는 것은 통과한 `child`(또는 `alternateChild`) 뿐입니다.

### 키보드

처리하는 키가 없습니다. 양쪽 생성자 모두 이벤트 파라미터 자체를 노출하지 않습니다.

### 포커스 관리

포커스 대상이 아니며 포커스를 관리하지도 않습니다. Flutter 에 `FocusNode` / `Focus` / `ExcludeFocus` 가 없고, Web 에 `tabindex` / `inert` / `focus-visible` 이 없습니다. Web 에서 숨겨진 분기가 포커스 순서 밖으로 빠지는 것은 오직 `display: none` 덕분이며, `inert` 나 `aria-hidden` 이 붙어서가 아닙니다.

### 스크린 리더

분기를 다루는 방식이 플랫폼마다 다릅니다. **Flutter 는 조건에 맞는 분기만 build** 하므로 맞지 않는 쪽은 애초에 생성되지 않아 semantics 트리에 닿지 않습니다. **Web 은 두 분기를 모두 DOM 에 렌더**한 뒤 scoped `@container` 규칙으로 `display: none` / `display: contents` 를 뒤집습니다 — `display: none` 은 숨겨진 분기를 접근성 트리에서 제거하므로, 일반적인 브라우저에서 중복 안내가 생기지는 않습니다.

### 알려진 제약

- **Web 에서는 숨겨진 분기가 서빙되는 HTML 에 그대로 남아 있습니다.** 크롤러, 페이지 내 찾기, computed `display` 를 보지 않는 도구는 그 내용을 그대로 봅니다. Flutter 에는 이 노출이 없습니다.
- **억제 수단이 `display: none` 하나뿐입니다** — `aria-hidden` 도 `inert` 도 없으므로, 소비자 CSS 가 `display` 를 덮어쓰면 숨겨져 있어야 할 분기가 접근성 트리와 포커스 순서에 그대로 되살아납니다.
- **너비에만 반응합니다** — 높이·orientation·`prefers-*` 같은 사용자 선호 질의는 다루지 않습니다. 그 축들은 [전역 접근성 축](/accessibility) 이 담당합니다.
- **Web 은 경계값이 설정되지 않으면 규칙 자체를 주입하지 않고 빠져나갑니다** — `minWidth` / `maxWidth` / `minBreakpoint` / `maxBreakpoint` 중 아무것도 주지 않으면 `alternateChild` 에 도달할 방법이 없습니다.

## 크로스 플랫폼 차이점 (Platform Differences)

| 항목 | Flutter | Web |
|------|---------|-----|
| 관측 | LayoutBuilder의 maxWidth. unbounded이면 MediaQuery viewport fallback | 너비 100% 루트의 CSS container query |
| 비활성 분기 | 해당 child를 트리에 올리지 않음 | 두 슬롯은 DOM에 남고 display로 선택 |
| resize | 부모 constraint 변경에 rebuild | CSS가 컨테이너 너비에 반응. JS 리스너 불필요 |
| 경계 없는 경우 | child 선택 | child 직접 렌더 또는 primary 래퍼 |

Web은 현재 범위 밖 CSS를 min-1 / max+1 px로 구성해 소수점 너비에서 Flutter의 엄격한 비교와 1px 미만의 경계 결손이 있습니다. 반올림된 기기 이름 대신 실제 가용 폭을 검증하세요.

## 관련 컴포넌트

- **[Scrollable Client](/components/scrollable-client)** — 스크롤 가능한 컨테이너에 반응형 컨텐츠를 넣을 때.
