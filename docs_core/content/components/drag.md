---
title: Drag
description: 드래그·드롭·재정렬을 조립하는 프리미티브 (DragScope / DragItem / DropZone / DragOverlay)
category: infra
platforms: [flutter, web]
related: [sortable, draggable-panel]
tags: [interactive, drag-drop, primitive]
---

# Drag

`Sortable` 과 `DraggablePanel` 이 쓰는 드래그 엔진을 그대로 노출한 프리미티브입니다. 준비된 컴포넌트로 표현되지 않는 상호작용(칸반 보드, 휴지통에 버리기, 캔버스 자유 배치)을 직접 조립할 때 씁니다.

무엇이 드래그인지 — 활성화 · 충돌 판정 · 세션 — 는 `coui_core` 의 순수 Dart 엔진이 소유하고, 각 플랫폼은 입력과 측정만 공급합니다. 그래서 Flutter 와 Web 이 같은 결정을 읽습니다.

## Live Preview

<LivePreview component="drag" variants="default,board,overlay" />

## 사용 시기 (When to Use)

**이 프리미티브를 사용하세요:**
- 여러 컨테이너 사이로 항목을 옮겨야 하는 경우 (칸반 보드)
- 드롭 대상이 리스트가 아닌 경우 (휴지통, 즐겨찾기 영역)
- 드래그 결과를 앱이 직접 해석해야 하는 경우

**대신 다른 컴포넌트를 사용하세요:**
- **[Sortable](/components/sortable)**: 한 목록 안에서 순서만 바꾸면 되는 경우 — 핸들·제거 버튼·정렬 수학이 이미 들어 있습니다
- **[DraggablePanel](/components/draggable-panel)**: 항목 재배치 대신 단일 패널의 위치·가장자리 도킹을 관리해야 할 때

## 구성 요소

| 컴포넌트 | 역할 |
|---|---|
| `DragScope` | 드래그 런타임 하나를 subtree 에 제공. 좌표계의 원점이자 참여자들의 측정 기준 |
| `DragItem` | 이 subtree 를 잡을 수 있게 만든다. 생명주기 콜백으로 의도를 보고 |
| `DragHandle` | 잡는 면을 자식으로 좁힌다 (없으면 항목 전체가 잡힌다) |
| `DropZone` | 착지 영역으로 등록. `builder` 로 드래그-오버 상태를 렌더 |
| `DragOverlay` | 끌리는 항목의 사본을 최상위 레이어에 그린다 |

## 기본 사용법 (Basic Usage)

가장 작은 완결 상호작용 — 항목 하나를 영역 하나로:

```dart
DragScope(
  child: Column(
    children: [
      DragItem(
        id: CoreDragId('card'),
        onDragEnd: (event) => setState(() => _dropped = event.overId == _bin),
        child: Card(child: Text('끌어 보세요').bodyMedium.onSurface),
      ),
      DropZone(
        id: _bin,
        builder: (context, dropDetails, child) =>
            Opacity(opacity: dropDetails.isOver ? 1 : 0.6, child: child),
        child: Text('여기에 놓으세요').bodyMedium.onSurfaceVariant,
      ),
    ],
  ),
)
```

## Props / Parameters

`W` 는 Flutter의 `Widget`, Web의 Jaspr `Component` 입니다.

다섯 프리미티브 모두 Flutter / Web 에서 동일한 named-properties API 를 노출합니다 (`child` 만 `Widget` ↔ `Component`).

### DragScope

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `child` | `W` | 필수 | 이 드래그 런타임을 공유할 subtree |
| `controller` | `DragScopeController?` | `null` | 직접 만든 런타임. `null` 이면 scope 가 자체 컨트롤러를 소유 |
| `announcements` | `bool` | `true` | 드래그 수명주기(집기 · 대상 진입 · 놓기 · 취소)를 스크린 리더에 알릴지 |

#### `DragScopeController`

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `modifiers` | `Iterable<CoreDragModifier>` | `const []` | 모든 이동에 적용되는 제약 (축 잠금 · 경계 · 격자). 순서대로 적용 |
| `autoScroll` | `CoreDragAutoScrollConfig` | `CoreDragAutoScrollConfig.standard` | 가장자리 자동 스크롤 세기 |
| `diagnostics` | `CoreDragDiagnosticsConfig` | `CoreDragDiagnosticsConfig.silent` | 중복 ID 등록 같은 배선 실수를 어디로 보고할지 (기본 침묵) |

### DragItem

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `id` | `CoreDragId` | 필수 | scope 안에서의 안정적인 정체성 |
| `child` | `W` | 필수 | 잡을 수 있는 콘텐츠 |
| `enabled` | `bool?` | `null` (= `true`) | 드래그 가능 여부 |
| `keyboardDraggable` | `bool` | `true` | 키보드 집기·이동·놓기 경로 활성화 |
| `data` | `Object?` | `null` | 드롭 시 앱이 해석할 임의 payload |
| `activationConstraint` | `CoreDragActivationConstraint` | `CoreDragActivationConstraint.immediate` | 드래그가 시작되는 조건 (즉시 / 이동 거리 / 지연) |
| `keyboardDragStep` | `double` | `25` | 화살표 키 한 번당 이동 거리 (논리 픽셀) |
| `label` | `String?` | `null` | 스크린 리더 라벨 |
| `hint` | `String?` | `null` | 스크린 리더 힌트 |
| `onDragStart` | `CoreDragStartCallback?` | `null` | 드래그 시작 |
| `onDragMove` | `CoreDragMoveCallback?` | `null` | 이동 중 (프레임마다) |
| `onDragEnd` | `CoreDragEndCallback?` | `null` | 놓임 — `event.overId` 로 착지 zone 확인 |
| `onDragCancel` | `CoreDragCancelCallback?` | `null` | Escape / 취소 |

### DragHandle

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `child` | `W` | 필수 | 잡는 면. 이 핸들이 있으면 항목의 나머지 영역은 잡히지 않음 |

### DropZone

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `id` | `CoreDragId` | 필수 | 착지 영역의 정체성 |
| `child` | `W` | 필수 | 영역 콘텐츠 |
| `builder` | `DropZoneBuilder?` | `null` | 드래그-오버 상태(`dropDetails.isOver`)를 반영해 `child` 를 감싸는 빌더 |
| `enabled` | `bool?` | `null` (= `true`) | 착지 대상으로 등록할지 |
| `data` | `Object?` | `null` | 앱이 해석할 임의 payload |

### DragOverlay

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `builder` | `DragOverlayBuilder` | 필수 | 활성 세션을 받아 최상위 레이어에 그릴 사본을 만드는 빌더 |

## 동작 스펙 (Behavior)

### DragItem 은 스스로 움직이지 않는다

끌린다고 해서 항목이 저절로 이동하지는 않습니다. 위치는 **소비처가 세션을 읽어** 정합니다.

의도된 설계입니다. `DraggablePanel` 같은 소비처는 같은 세션으로 이미 자기 위치를 계산하는데, 항목까지 스스로 움직이면 이동이 두 번 적용됩니다. 포인터를 따라가게 하려면:

```dart
final transform = DragScope.maybeOf(context)!.transformOf(id);
Transform.translate(offset: Offset(transform.x, transform.y), child: card)
```

### 트랙패드 두 손가락 제스처는 끌기를 시작하지 않는다

항목을 집는 것은 누른 채 움직이는 포인터(마우스 — 트랙패드 클릭과 클릭한 채 끌기 포함 —, 터치, 펜)뿐입니다. 트랙패드의 두 손가락 스크롤·팬·핀치는 끌기를 시작하지 않고 감싼 스크롤 영역으로 갑니다. Flutter 는 이 제스처를 `trackpad` 종류의 pan-zoom 이벤트로, Web 은 `wheel` 이벤트로 보내므로 두 플랫폼의 결과가 같습니다.

그래서 기본값 `immediate` 항목도 데스크톱의 두 손가락 스크롤은 가로채지 않습니다. 아래 `delay` 권고는 **터치** 스와이프-스크롤과 구분하기 위한 것입니다.

## 보드 — 컨테이너 사이 이동

**보드 컴포넌트는 없습니다.** 컬럼을 `DropZone` 으로, 카드를 `DragItem` 으로 두면 `CoreSortableAcross` 가 두 측정값을 읽어 착지 지점을 알려줍니다.

```dart
void handleDragEnd(CoreDragEndEvent event) {
  final result = CoreSortableAcross.resolve(
    activeId: event.session.activeId,
    containers: _board,
    itemRects: _controller.registry.itemRects,
    // 컬럼이 스스로 drop zone 으로 등록했으므로 측정값이 이미 여기 있다.
    containerRects: _controller.registry.dropZoneRects,
    pointer: event.session.pointer,
    transform: event.session.transform,
  );
  if (!result.moves) return;
  // result.fromContainer/fromIndex → result.toContainer/toIndex
}
```

`resolve` 는 착지 인덱스와 형제 변위를 **한 번에** 냅니다. 따로 계산하면 미리 보여준 자리와 실제로 놓이는 자리가 갈라집니다.

## 이동 제약 (Modifier)

축 잠금 · 경계 구속 · 격자 스냅은 엔진이 소유합니다. 렌더 시점에 좌표를 손으로 버리지 마세요.

```dart
DragScopeController(
  modifiers: [
    CoreDragModifiers.snapToGrid(x: CoreSpace.space8, y: CoreSpace.space8),
    CoreDragModifiers.restrictToRect,
  ],
)
```

**순서가 중요합니다 — 마지막 modifier 만 유지가 보장됩니다.** 경계로 자른 뒤 격자로 스냅하면 방금 지킨 경계를 도로 넘을 수 있으므로, 반드시 이겨야 하는 제약을 맨 뒤에 둡니다.

## 자동 스크롤

스크롤 컨테이너 안의 `DragScope` 는 가장자리에서 자동으로 스크롤합니다. 밴드 깊이에 비례해 속도가 붙고, 드래그가 끝나면 멈춥니다. 세기는 `DragScopeController(autoScroll:)` 로 조정합니다.

- 포인터 활성화 제약의 distance 단위는 논리 px, delay는 Duration입니다. 키보드 이동은 `keyboardDragStep`(기본 25 논리 px)씩 scope 좌표를 움직이며 같은 충돌·드롭 엔진을 사용합니다.
- Space / Enter로 집고 놓으며 Escape는 취소합니다. DragHandle이 등록되면 포인터 집기 면은 핸들로 좁혀집니다. disabled 항목은 세션을 시작하지 않습니다.
- 이벤트가 끝나도 앱 데이터의 위치·순서를 자동 변경하지 않습니다. onDragEnd의 overId를 읽어 재배치하고, DragOverlay / transform을 반영하는 것은 호출부입니다.

## 사용 가이드라인 (Usage Guidelines)

### ✅ Do

<Callout type="tip">

**스크롤 표면과 공유하는 항목은 `activationConstraint`에 `delay`를 줘서 스와이프-스크롤과 구분**

```dart
DragItem(
  id: CoreDragId('row-3'),
  activationConstraint: const CoreDragActivationConstraint(
    delay: Duration(milliseconds: 200),
  ),
  child: rowContent,
)
```

기본값 `immediate`는 포인터가 조금만 움직여도 드래그를 시작시켜, 스크롤 가능한 리스트 안에서는 스와이프-스크롤 의도를 드래그로 가로챕니다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**`DragItem`이 스스로 위치를 옮긴다고 가정하지 않기**

```dart
// ❌ transform 을 읽지 않음 — 드래그해도 카드가 움직이지 않는다
DragItem(
  id: CoreDragId('card'),
  child: Card(child: Text('끌어 보세요')),
)
```

위치는 소비처가 세션(`DragScope.maybeOf(context)!.transformOf(id)`)을 직접 읽어 반영해야 합니다. 항목까지 스스로 움직이면 `DraggablePanel` 같은 소비처의 이동 계산과 겹쳐 이동이 두 번 적용되기 때문에 의도적으로 비워뒀습니다.

</Callout>

### ✅ Do

<Callout type="tip">

**반드시 지켜야 하는 제약은 `modifiers` 리스트의 마지막에 두기**

```dart
DragScopeController(
  modifiers: [
    CoreDragModifiers.snapToGrid(x: CoreSpace.space8, y: CoreSpace.space8),
    CoreDragModifiers.restrictToRect, // 마지막 = 반드시 지켜지는 제약
  ],
)
```

modifier는 순서대로 적용되고 마지막 modifier만 유지가 보장됩니다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**필수 제약을 마지막이 아닌 자리에 두지 않기**

```dart
// ❌ restrictToRect 를 먼저 두면 뒤이은 snapToGrid 가 경계를 다시 넘길 수 있음
DragScopeController(
  modifiers: [
    CoreDragModifiers.restrictToRect,
    CoreDragModifiers.snapToGrid(x: CoreSpace.space8, y: CoreSpace.space8),
  ],
)
```

경계로 자른 뒤 격자로 스냅하면 방금 지킨 경계를 도로 넘을 수 있습니다.

</Callout>

## 접근성 (Accessibility)

### 역할

- **`DragItem`**
  - **Web**: `role="application"` · `aria-label`(=`label`) · `aria-description`(=`hint`) · `aria-grabbed`(드래그 중 `true`) · `aria-disabled` · `tabindex`(`0` / 비활성 `-1`) 을 루트 `<div>` 에 내보냅니다. `role="application"` 은 의도적입니다 — 이 역할이 없으면 스크린 리더의 브라우즈 모드 가상 커서가 화살표 키를 "포커스 이동"으로 삼켜 키보드 드래그가 조용히 동작하지 않습니다(구현 주석에 근거가 적혀 있습니다).
  - **Flutter**: `Semantics(enabled:, label:, hint:)` 를 설정합니다. `aria-grabbed` 에 대응하는 "집혀 있음" 시맨틱은 없습니다.
- **`DropZone`**
  - **Web**: `aria-dropeffect`(드래그가 위에 있으면 `move`, 아니면 `none`) 와 비활성 시 `aria-disabled` 를 내보냅니다. 역할이나 이름은 붙이지 않습니다.
  - **Flutter**: `Semantics(container: true)` 만 설정합니다 — 드래그-오버 상태도 비활성 상태도 보조 기술에 전달되지 않습니다.
- **`DragScope` · `DragOverlay` · `DragHandle`**: 레이아웃·상호작용 래퍼 자체에는 역할이 없습니다. Scope 는 좌표 원점과 발화 채널을 소유하고, Overlay 는 포인터를 받지 않는 사본(Flutter `IgnorePointer`, Web `pointer-events: none`), Handle 은 잡는 면만 좁히는 래퍼입니다.

### 키보드

`DragItem` 에 포커스가 있을 때 — 양 플랫폼 동일합니다.

| 키 | 동작 |
|----|------|
| `Tab` / `Shift+Tab` | `DragItem` 사이 이동 (항목 하나가 tab stop 하나) |
| `Space` / `Enter` | 집기 ↔ 놓기 (토글) |
| `←` `→` `↑` `↓` | 집은 뒤 `keyboardDragStep`(기본 25) 만큼 세션 포인터 이동 |
| `Escape` | 집은 뒤 드래그 취소 |

- 집지 않은 상태의 화살표는 이 컴포넌트가 처리하지 않습니다 — Flutter 는 `KeyEventResult.ignored` 를 돌려주고 Web 은 `preventDefault` 없이 반환하므로, 그 키는 프레임워크/브라우저의 기본 동작으로 넘어갑니다.
- `DropZone` 사이를 건너뛰는 키는 **없습니다**. 이동은 픽셀 단위 걸음뿐입니다.
- `DragHandle` 은 포커스를 받지 않습니다 (Flutter 는 `MouseRegion` 래퍼, Web 은 `tabindex` 없는 `<div>`). 핸들로 잡는 면을 좁혀도 키보드 드래그는 항목 자체에서 시작합니다.
- 비활성 항목(`enabled: false`)은 Web 에서 키 핸들러 자체가 붙지 않습니다.

### 스크린 리더

접근 가능한 이름의 출처는 `label`, 설명은 `hint` 입니다 — Flutter 는 `Semantics(label:, hint:)`, Web 은 `aria-label` / `aria-description` 으로 나갑니다. **둘 다 선택 파라미터이고 로케일 폴백이 없어**, 주지 않으면 항목에 이름이 없고 `child` 자신의 시맨틱만 남습니다. 드래그 가능한 항목에는 `label` 을 주세요.

`DragScope` 는 드래그의 네 순간 — **집기 · 대상 진입 · 놓기 · 취소** — 을 발화합니다.
문구는 로케일을 따르고, Flutter 는 `SemanticsService` 발화로, Web 은
`aria-live="polite"` 리전으로 같은 문장을 냅니다. 대상에서 나가는 것과 같은 대상을
다시 해석하는 것은 말하지 않습니다. 필요 없으면 `announcements: false` 로 끕니다.

### 포커스 관리

오버레이가 아니므로 진입 · 이탈 · 트랩이 모두 없습니다.

- 키보드 드래그 중에도 포커스는 `DragItem` 에 그대로 머뭅니다 — 드래그는 세션 상태일 뿐 포커스를 옮기지 않고, `Space`/`Enter` 로 놓거나 `Escape` 로 취소해도 포커스는 같은 항목에 남습니다.
- `DragOverlay` 는 사본을 최상위 레이어에 그리지만 포커스를 가져가지 않습니다.
- 비활성 항목은 traversal 에서 빠집니다 — Web `tabindex: '-1'`, Flutter `canRequestFocus: _enabled`.

### 알려진 제약

**Web `DragItem` 은 드래그 중이 아닐 때도 항상 `role="application"` 입니다.** 그 subtree 안에서는 스크린 리더의 브라우즈 모드가 꺼져, 항목 안의 텍스트 · 링크 · 버튼을 평소의 읽기 방식으로 훑을 수 없습니다. 화살표 키를 컴포넌트로 넘기기 위해 치른 대가입니다.

> 대안: 없습니다. `DragItem` 은 raw `StatefulComponent` 라 `attributes` 통과 슬롯이 없어 호출자가 역할을 덮을 수 없습니다. 항목 안에 읽을거리가 많다면 그 콘텐츠를 항목 밖에 두고 `DragHandle` 만 항목 안에 넣는 구성을 검토하세요.

**드롭 대상까지 픽셀로 걸어가야 합니다.** 화살표 한 번이 세션 포인터를 `keyboardDragStep`(기본 25) 만큼 옮기고 충돌은 기하로 판정되므로, 멀리 있는 `DropZone` 에 닿으려면 화살표를 여러 번 눌러야 합니다. 대상 진입은 `DragScope` 가 통보합니다.

> 대안: 드롭 영역이 성기게 배치된 화면이라면 호출부에서 `keyboardDragStep` 을 키우세요 — 정밀도와 맞바꾸는 선택입니다.

**Flutter 의 노드 속성에는 grabbed / dropeffect 에 대응하는 값이 없습니다.**
`DragScope` 의 순간별 발화와는 별개입니다 — 드래그 상태를 노드의 지속 속성으로
읽어야 한다면 호출부에서 보완해야 합니다.

> 대안: 호출자가 `DragScope.maybeOf(context)` 로 컨트롤러의 `activeId` / `session` 을 읽을 수 있으므로, 그 값을 근거로 자기 `Semantics` 나 통보를 직접 붙일 수 있습니다. 컴포넌트가 대신 해주지는 않습니다.
## 진단 (Diagnostics)

같은 `CoreDragId` 를 두 위젯이 등록하면 **나중 것이 조용히 이깁니다** — 그 뒤 정렬·드롭이 엉뚱한 항목을 옮기는데, 증상이 "가끔 다른 항목이 움직인다" 로만 보여 원인을 찾기 어렵습니다.

```dart
DragScope(
  controller: DragScopeController(
    diagnostics: CoreDragDiagnosticsConfig(
      onWarning: (message) => debugPrint(message),
    ),
  ),
  child: ...,
)
```

기본은 침묵입니다 — 디자인 시스템이 소비자 콘솔에 경고를 찍는 것은 앱이 정할 일이고, 고칠 수 있는 사람도 앱 작성자입니다. 같은 소유자가 다시 등록하는 것(리빌드)은 경고하지 않습니다.

## 크로스 플랫폼 차이점 (Platform Differences)

| 항목 | Flutter | Web |
|------|---------|-----|
| 포인터 수집 | gesture recognizer · 지연 multi-drag | pointerdown 이후 document pointer 스트림 |
| 측정 좌표 | RenderBox를 DragScope 원점으로 변환 | DOM rect를 scope 원점으로 변환 |
| 키보드 | Focus의 KeyEvent | DOM keydown |
| 레이아웃 관측 | 프레임 후 측정 | 요소 layout observer와 집기 직전 재측정 |
| 움직임·충돌 | 공유 Core drag runtime | 같은 Core drag runtime |

## 관련 컴포넌트

- [Sortable](/components/sortable) — 한 목록 안의 재정렬이 필요한 전부일 때
- [DraggablePanel](/components/draggable-panel) — 떠다니는 단일 패널
