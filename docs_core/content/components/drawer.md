---
title: Drawer
description: 드로어/사이드바 컴포넌트
category: overlay
platforms: [flutter, web]
related: [dialog, navigation]
tags: [panel, sidebar, interactive]
---

# Drawer

화면 측면에서 슬라이드하여 나타나는 모달 패널 컴포넌트입니다. 명령형 API (`openDrawer`) 로 호출하여 표시하고, 사용자가 닫으면 `Future` 가 결과와 함께 완료됩니다.

## Live Preview

<LivePreview component="drawer" />

## 사용 시기 (When to Use)

**이 컴포넌트를 사용하세요:**
- 보조 콘텐츠(필터, 설정, 상세 정보)를 화면 옆에서 슬라이드로 보여줄 때
- 메인 콘텐츠를 가리지 않고 추가 작업 공간이 필요할 때
- 모바일 네비게이션 메뉴를 구현할 때

**대신 다른 컴포넌트를 사용하세요:**
- **[Swiper](/components/swiper)**: 명령형 openDrawer 호출 대신 가장자리 드래그로 열리는 인터랙션이 필요할 때
- **[Dialog](/components/dialog)**: 가장자리 sheet 대신 중앙 모달 표면이 필요할 때
- **[Popover](/components/popover)**: 화면 가장자리 대신 트리거에 앵커된 패널이 필요할 때
- **[Tabs](/components/tabs)**: 오버레이를 열지 않고 본문 패널 하나를 교체해야 할 때

## 기본 사용법 (Basic Usage)

CoUI 는 Flutter 와 Web 에서 동일한 명령형 API 를 제공합니다. 아래 예제 코드는 양쪽 플랫폼에서 그대로 사용할 수 있습니다.

```dart
// 트리거 버튼 클릭 시 드로어 열기
Button(
  variant: CoreButtonVariant.outline,
  onPressed: () {
    openDrawer<void>(
      context: context,
      side: CoreDrawerSide.left,
      builder: (close) => Drawer(
        title: '메뉴',
        content: Column(  // Web 은 div(...)
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('대시보드'),
            Text('설정'),
            Text('프로필'),
          ],
        ),
      ),
    );
  },
  child: const Text('패널 열기'),
)
```

`openDrawer<T>` 는 `Future<T?>` 를 반환합니다 — 사용자가 패널 안에서 `close(value)` 를 호출하면 그 값으로, 배리어/드래그/Escape/× 버튼으로 닫으면 `null` 로 완료됩니다.

```dart
// 결과를 받아오는 패턴
final picked = await openDrawer<String>(
  context: context,
  side: CoreDrawerSide.right,
  builder: (close) => Drawer(
    title: '색상 선택',
    content: ColorList(onPick: (c) => close(c.name)),
  ),
);
```

## Props / Parameters

`W` 는 Flutter의 `Widget`, Web의 Jaspr `Component` 입니다.

### `Drawer`

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `content` | `W` | 필수 | 드로어 내부에 표시할 콘텐츠 |
| `side` | `CoreDrawerSide` | `CoreDrawerSide.left` | 슬라이드 인 방향 (`left` / `right` / `top` / `bottom`) |
| `title` | `String?` | `null` | 드로어 상단 제목 텍스트 |
| `description` | `String?` | `null` | 제목 아래 보조 문장 — 패널이 무엇을 하는지 한 문장으로. `title` 이나 `description` 중 하나만 있어도 헤더가 그려진다 |
| `barrierDismissible` | `bool` | `true` | 배리어(스크림) 클릭 시 드로어 닫기 |
| `transformBackdrop` | `bool` | `true` | 뒤 화면 효과 사용 여부. 기본 스타일은 축소 없음(`backdropScale` 1.0 · 모서리 0 — 어두운 막만 덮는다)이라 눈에 보이는 효과가 없고, 스타일에 `CoreDrawerStyle.zoomBackdropScale`(0.95) · `zoomBackdropCornerRadius`(24)를 주면 열릴 때 앱 콘텐츠를 뒤로 축소(shadcn zoom-out — scale + 코너 클립)한다. 스와이퍼의 `drawer` 변형은 이 효과를 켠 스타일을 쓴다. sheet 는 이 변형이 없는 drawer. Flutter 는 `CoUIApp` 의 backdrop 호스트 필요(없으면 no-op). Web 은 드로어 루트를 브라우저 **top-layer**(Popover API)로 승격해 조상 transform 을 벗어난 뒤 첫 `data-coui-backdrop` 래퍼를 직접 스타일(Vaul 방식) — SSR+아일랜드처럼 래퍼가 드로어 DOM 을 포함하는 구조에서도 동작. Popover API 미지원 브라우저는 그 구조에서만 안전하게 no-op(자식은 조상 transform 을 벗어날 수 없음) |
| `draggable` | `bool` | `true` | 패널을 끌어 닫을 수 있다. 놓을 때 거리가 `dragDismissThreshold` 이상이거나, 닫히는 가장자리 쪽으로 빠르게 던지면(플릭, 400 px/s 이상) 닫힌다 — 아래 "플릭으로 닫기" 참고 |
| `dragDismissThreshold` | `double` | `0.5` | 닫기 이동 비율 기준 (단위 없는 0~1 비율) — 패널 **자신의** 슬라이드 축 길이 대비. **거리 기준만** 정한다 — 속도 기준(`CoreDrawerContract.defaultDismissVelocity`)은 위젯 파라미터가 아니다. 두 플랫폼이 같은 판정(`CoreDrawerContract.dismissesOnRelease`)을 쓴다 |
| `rubberBand` | `bool` | `false` | 열린 방향으로 더 끌어도 멈추지 않고, 패널의 먼 쪽 가장자리가 갈수록 덜 따라오며 늘어났다가 놓으면 도킹된 자리로 돌아온다. **무엇이 닫히는지는 고무줄과 무관하다** — 아래 "고무줄" 참고. `draggable` 처럼 Flutter 에서 실제로 결정하는 것은 `openDrawer(rubberBand:)` 이고 Web 은 panel 의 같은 이름 파라미터를 읽는다 |
| `showDragHandle` | `bool` | `false` | 손잡이(pill)를 화면 중앙을 향한 변에 그린다 — 하단 시트는 위, 상단 시트는 아래, 측면 드로어는 안쪽 변에 세로로. 끌 수 있다는 표시일 뿐 장식이며, 드래그 자체는 패널 전체가 받는다 |
| `footer` | `W?` | `null` | 콘텐츠 아래 하단 영역 — 있으면 구분선(`outlineVariant` 1) 아래에 오른쪽 정렬로 그려진다. 버튼과 버튼 사이 간격은 호출자가 자기 `Row` / `div` 에서 정한다. 좌·우 드로어에서는 내용이 남는 높이를 채우므로 하단이 패널 바닥에 붙는다 |
| `showCloseButton` | `bool` | `true` | 헤더의 × 버튼. 끄면 배리어·드래그·Escape(Web)·뒤로 가기(Flutter)로 닫는다 |
| `fillSafeArea` | `bool` | `false` | 패널이 붙은 **한 변**에서 표면(배경·테두리·반경·그림자)이 시스템 안전영역(홈 인디케이터·제스처 바·노치)까지 채워진다. 콘텐츠는 그 인셋만큼 패널 안쪽 패딩으로 비켜선다. Flutter 는 위 `transformBackdrop` 과 같은 방식 — 실제로 결정하는 것은 `openDrawer(fillSafeArea:)` 이고 Web 은 panel 의 같은 이름 파라미터를 읽는다. 아래 "안전영역 채움" 참고 |
| `dismissOnEscape` | `bool` | `true` | Escape 키로 닫기 (Web 전용) |
| `drawerStyle` | `CoreDrawerStyle?` | `null` | 패널 겉모습 / 배리어 / 애니메이션 / 안쪽 부품의 스타일(titleStyle·closeButtonStyle)을 바꾸는 값 묶음 |

### API

### `openDrawer<T>(...)`

| 인자 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `context` | `BuildContext` | 필수 | 가장 가까운 `CoUIWeb` / `CoUIApp` 또는 `OverlayHost` ancestor 를 찾는 데 사용 |
| `builder` | `WidgetBuilder` (Flutter) / `Drawer Function(close)` (Web) | 필수 | 드로어 panel 을 빌드하는 함수. Web 빌더는 `close([T?])` 콜백을 받아 panel 안에서 결과와 함께 닫을 수 있음 |
| `side` | `CoreDrawerSide` | 필수 | 슬라이드 인 방향 (`left` / `right` / `top` / `bottom`) |
| `barrierDismissible` | `bool` | `true` | 배리어 클릭 dismiss (Flutter — Web 은 panel 의 같은 이름 파라미터를 읽음) |
| `draggable` | `bool` | `true` | 드래그 dismiss (Flutter — Web 은 panel 의 같은 이름 파라미터를 읽음) |
| `rubberBand` | `bool` | `false` | 열린 방향 드래그를 늘어남으로 받아 준다 (Flutter — Web 은 panel 의 같은 이름 파라미터를 읽음). 끌 수 없는 패널(`draggable: false`)에서는 할 일이 없다 |
| `transformBackdrop` | `bool` | `true` | backdrop 축소 변형 (Flutter — Web 은 panel 의 같은 이름 파라미터를 읽음). Flutter 에서 `useRootNavigator: false` 로 root 가 아닌 Navigator 에 올리면 적용되지 않는다 |
| `fillSafeArea` | `bool` | `false` | 패널이 붙은 변에서 안전영역까지 표면을 채움 (Flutter — Web 은 panel 의 같은 이름 파라미터를 읽음) |
| `useRootNavigator` | `bool` | `true` | drawer route 를 올릴 Navigator. `true` = root Navigator, `false` = `Navigator.of(context)` 가 찾는 **가장 가까운** Navigator (Flutter 전용 — 아래 참고) |
| `routeSettings` | `RouteSettings?` | `null` | drawer route 의 이름·인자 — `NavigatorObserver`(분석, 이름으로 route 를 구분하는 라우터)가 그 이름으로 push/pop 을 보고, 패널 안의 `ModalRoute.of(context)?.settings` 로도 읽힌다. `null` 이면 이름 없는 route (Flutter 전용 — Web 은 관찰할 navigator 스택이 없다) |
| `animationHandle` | `DrawerAnimationHandle?` | `null` | 열림 진행도를 외부에서 읽는 핸들 (Flutter 전용) |
| `drawerStyle` | `CoreDrawerStyle?` | `null` | route 수준의 겉모습(배리어 색·애니메이션 duration)을 정하는 데 사용 (Flutter 전용) |
| `scrubController` | `DrawerScrubController?` | `null` | 열림 진행도를 외부 제스처로 스크럽 (Web 전용) |

### `closeDrawer<T>(context, [result])` (Flutter)

명령형으로 가장 위 드로어를 닫습니다 (`Navigator.pop` 과 동일한 의미).
**패널 안쪽 context** 로 부르세요 — 드로어를 올린 Navigator(root 이거나
`useRootNavigator: false` 로 연 가장 가까운 Navigator)를 패널이 알고 있어서
그 Navigator 에서 정확히 닫습니다. 패널 밖 context 는 알 수 있는 게 없어 root
Navigator 로 폴백합니다.
Web 은 `builder` 의 `close([T?])` 콜백을 사용하세요.

## 하단 시트 — 손잡이 · 설명 · 닫기 버튼

통화·국가처럼 목록에서 하나를 고르는 시트는 아래에서 올라오고, 위쪽에 손잡이를, 제목 아래에 한 줄 설명을 둡니다. 닫기는 배리어와 드래그에 맡기고 × 버튼은 끕니다. 헤더 아래 구분선을 없애려면 두께 0 을 지정합니다.

<LivePreview component="drawer" variant="sheet" chain="off" />

```dart
openDrawer<void>(
  context: context,
  side: CoreDrawerSide.bottom,
  builder: (close) => Drawer(
    title: '통화 선택',
    description: '받으실 통화를 선택해 주세요',
    showDragHandle: true,
    showCloseButton: false,
    drawerStyle: const CoreDrawerStyle(
      panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius28),
      dividerStyle: CoreDividerStyle(thickness: CoreStrokeWidth.stroke0),
    ),
    content: currencyList,
  ),
);
```

## 하단 영역 — 확인 · 취소 버튼

옆 패널에서 입력을 받고 확정하는 흐름은 `footer` 에 버튼 줄을 넘깁니다. 구분선 아래에 오른쪽 정렬로 놓이고, 좌/우 드로어에서는 내용이 남는 높이를 채워 하단이 패널 바닥에 붙습니다. 버튼 사이 간격은 호출자가 자기 `Row`(Flutter) / `div`(Web) 에서 정합니다.

<LivePreview component="drawer" variant="footer" chain="off" />

```dart
openDrawer<void>(
  context: context,
  side: CoreDrawerSide.right,
  builder: (close) => Drawer(
    title: '프로필',
    description: '다른 사람에게 보이는 모습을 바꿔요.',
    content: form,
    footer: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: CoreSpace.space8,
      children: [
        Button(variant: CoreButtonVariant.secondary, onPressed: cancel, child: const Text('취소')),
        Button(variant: CoreButtonVariant.primary, onPressed: save, child: const Text('저장')),
      ],
    ),
  ),
);
```

- **어느 변에 붙는지는 `openDrawer(side:)` 가 정합니다.** 패널은 자기를 연 라우트(Flutter) / 엔트리(Web)의 변에 붙고, 그 변의 두 모서리를 평평하게 하고, 손잡이를 반대쪽(화면 중앙 쪽) 변에 둡니다. `Drawer(side:)` 는 Flutter 에서 라우트 밖에 패널을 직접 그릴 때(`Swiper` 의 고스트 패널)만 쓰이고, Web 은 언제나 엔트리의 변을 따릅니다.
- **시트 모서리 28 은 기본값이 아닙니다.** 기본 반경(`CoreDrawerStyle.defaultPanelBorderRadius` = 16)은 그대로 두고, 앱 전체에 적용하려면 테마의 `CoreDrawerTheme(style: CoreDrawerStyle(panelBorderRadius: …))` 로, 한 곳만이면 위처럼 `drawerStyle` 로 지정합니다.
- 손잡이의 크기·색·여백은 `CoreDrawerStyle.dragHandle*` 로 바꿉니다 (기본 48 × 6, `surfaceContainer`, 둘레 8). `Swiper` 가 그리는 손잡이도 같은 필드를 씁니다.
- **시트는 내용 높이만큼 올라옵니다.** Flutter 의 `Column` 은 기본이 최대 높이라 하단 시트의 내용으로 쓸 때는 `mainAxisSize: MainAxisSize.min` 으로 둡니다 — 그대로 두면 시트가 화면 상한까지 늘어납니다. Web 의 flex 열은 처음부터 내용 크기입니다.
- **모바일의 하단 패널에는 [BottomSheet](/components/bottom-sheet) 를 권장합니다.** 손잡이 · 제목 · 내용 · 하단 바를 갖춘 면이 따로 있습니다. `Side=bottom` 은 그대로 쓸 수 있고, 열고 닫는 일까지 `Drawer` 가 맡습니다.

## 고무줄 — `rubberBand`

도킹된 패널은 이미 가장 열린 자리에 있어서 열린 방향으로는 더 끌 곳이 없습니다. 기본(`false`)에서는 그 방향의 드래그를 패널이 무시하고 그대로 서 있습니다. `rubberBand: true` 는 그 드래그를 **받아 줍니다**: 패널의 먼 쪽 가장자리가 손가락을 따라 나가되 갈수록 덜 따라가고, 놓으면 도킹된 자리로 돌아옵니다. 손가락이 "한계에 닿았다"와 "걸려서 안 움직인다"를 구별하게 해 주는 신호라서, 손으로 만지는 하단 시트·피커에 어울립니다. 상단의 완료/취소 바는 새 컴포넌트가 아니라 `content` 첫 줄에 `Button` 둘과 제목을 놓은 조합입니다.

<LivePreview component="drawer" variant="rubber-band" chain="off" />

```dart
openDrawer<void>(
  context: context,
  side: CoreDrawerSide.bottom,
  rubberBand: true, // Web 은 Drawer(rubberBand: true)
  builder: (ctx) => Drawer(
    showDragHandle: true,
    showCloseButton: false,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Button(
              variant: CoreButtonVariant.ghost,
              onPressed: () => closeDrawer<void>(ctx),
              child: const Text('취소'),
            ),
            Expanded(child: Center(child: Text('알림 시간').titleMedium)),
            Button(
              onPressed: () => closeDrawer<void>(ctx),
              child: const Text('완료'),
            ),
          ],
        ),
        timeList,
      ],
    ),
  ),
);
```

- **화면에 붙은 변은 움직이지 않습니다.** 패널은 도킹된 변을 고정점으로 슬라이드 축 방향으로 **늘어납니다**(scale) — 통째로 옮기지 않습니다. 옮기면 도킹된 변이 화면 가장자리에서 떨어져 그 틈으로 배경이 보입니다. 닫는 쪽으로 끄는 드래그는 손가락과 1:1 로 미끄러집니다. 한 번의 제스처에서 패널은 미끄러지거나 늘어나거나 둘 중 하나입니다.
- **늘어난 길이는 곡선이 정합니다.** 손가락이 도킹을 `x` px 넘어 끌었을 때 먼 쪽 가장자리는 `L·(τ·x) / (L + τ·x)` 만큼 나갑니다 (`L` = `reach` × 패널 길이, `τ` = `tension`). 이 곡선은 단조 증가하고, 오목하고(한 픽셀당 반응이 계속 줄고), 0 에서 0 이며, `L` 을 넘지 않습니다 — 300 px 시트는 60 px 끌면 약 15.7 px, 1000 px 끌어도 28.4 px 가 한계라서 패널이 화면 밖으로 밀려 나갈 수 없습니다. 곡선이 손가락 위치의 함수이므로 손가락이 돌아오면 온 길을 그대로 되짚습니다. 계산은 Core `CoreDrawerRubberBand` 한 곳이고, 입력과 기대 표시를 적은 표(`coui_core/test/fixtures/drawer_rubber_band_vectors.json`)를 Core · Flutter · Web VM 테스트와 Chrome 프로브가 함께 읽습니다.
- **닫기 판정은 고무줄과 무관합니다.** 늘어난 패널은 닫는 쪽으로 간 거리가 0 입니다(`CoreDrawerRubberBand.dismissDistanceOf`). 그래서 열린 방향으로 아무리 빠르게 던져도(플릭) 닫히지 않고, 거리·속도 판정(`CoreDrawerContract.dismissesOnRelease`)은 닫는 쪽으로 끈 만큼만 셉니다. 늘어난 거리를 닫기 거리로 세면 한 번 힘껏 당겼다 놓는 되튐이 닫기가 되기 때문입니다. 손가락을 돌려 닫는 쪽으로 끌면 도킹을 지나는 순간부터 거리가 쌓입니다.
- **놓으면 돌아옵니다.** 놓은 자세에서 도킹으로 `CoreDrawerRubberBand.defaultSettleDuration`(`CoreDuration.moderate`, 300 ms) 동안 `CoreEasing.enter` 로 감속하며 돌아오고, 튕기지 않습니다. 돌아오는 중에 다시 잡으면 도킹이 아니라 **지금 있는 자세**에서 이어 끕니다 — 점프가 없습니다.
- **본문 스크롤과 다투지 않습니다.** 손가락이 스크롤되는 본문 위에서 시작하면 본문이 스크롤합니다. Flutter 는 제스처 경쟁에서 스크롤 가능한 자식이 이기므로 패널은 늘어나지 않습니다. Web 은 브라우저가 터치를 스크롤로 판정할 때까지(몇 픽셀의 터치 슬롭) 패널이 따라갔다가, 판정이 나면 포인터를 취소(`pointercancel`)해 늘어났던 만큼 돌아옵니다. 내용이 넘치지 않는 본문과 손잡이·헤더는 언제나 패널을 끕니다.
- **로케일 방향과 무관합니다.** `CoreDrawerSide` 는 물리 방향(`left` / `right` / `top` / `bottom`)이라 RTL 에서도 같은 변에 붙고 같은 쪽으로 늘어납니다. 네 변이 같은 곡선을 씁니다.
- **움직임 줄이기.** 손가락을 누른 채 늘어나는 동안은 손가락 자신의 움직임(직접 조작)이라 그대로 따라갑니다. 돌아오는 전환은 전환 tier(`CoreDuration.moderate`)라 동작 줄이기에서 즉시 끝납니다 — Flutter 는 `resolveMotionDuration` 이 0 을 돌려주고, Web 은 `prefers-reduced-motion` 이 duration 변수를 0 으로 덮습니다.
- **다른 축.** 늘어남은 변형(scale)일 뿐 색·재질·경계를 건드리지 않으므로 투명도 줄이기 · 고대비 · 강제 색상 모드에서 할 일이 없습니다. 키보드와 스크린 리더에는 아무것도 더하지 않습니다 — 닫기 경로(배리어 · Escape · × 버튼 · 뒤로 가기)는 그대로입니다.

### 디자이너 판단 값

아래 값은 계산해 낸 값이 아니라 기기에서 만져 보고 정한 느낌 값(**디자이너 판단 값**)입니다. 각각 Core 의 상수 한 곳에만 있고, 위젯 파라미터도 `CoreDrawerStyle` 필드도 아닙니다 — 살아 있는 제스처와 비교하며 곡선에 들어가는 값이지 화면에 그리는 겉모습이 아니기 때문입니다.

| 값 | 위치 | 기본 | 대안과 바꾸는 법 |
|---|---|---|---|
| 최대로 늘어나는 비율 | `CoreDrawerRubberBand.defaultReach` | `0.1` (패널 길이의 10 %) | `0.05` 는 거의 보이지 않고 `0.15` 는 더 느슨하다 — 상수 한 줄 |
| 첫 반응 | `CoreDrawerRubberBand.defaultTension` | `0.55` | `1` 은 곡선이 꺾이기 전까지 손가락과 1:1, `0.4` 는 더 단단한 벽 — 상수 한 줄 |
| 돌아오는 시간 | `CoreDrawerRubberBand.defaultSettleDuration` | `CoreDuration.moderate` (300 ms) | `CoreDuration.normal`(200 ms)은 산뜻하고 `CoreDuration.slow`(500 ms)는 묵직하다 — 상수 한 줄 |
| 돌아오는 곡선 | `CoreDrawerRubberBand.defaultSettleEasing` | `CoreEasing.enter` | `CoreEasing.move` 는 출발도 부드러워 머뭇거리는 느낌 — 상수 한 줄 |
| 기본으로 켤지 | `CoreDrawerContract.defaultRubberBand` | `false` | `true` 면 끌 수 있는 모든 드로어가 고무줄 — 상수 한 줄 |

### 고무줄의 알려진 제약

- **패널이 통째로 늘어납니다 — 안의 글자와 버튼도 함께.** 변형으로 그리므로 늘어난 동안은 콘텐츠도 같은 비율로 (하단·상단 시트는 세로로, 좌·우 드로어는 가로로) 늘어납니다. 비율은 최대 `reach`(10 %)이고 보통의 당김(30–60 px)에서는 3–5 % 라 제스처 동안만 보입니다. 면만 늘리고 콘텐츠는 그대로 두려면 면(배경 · 테두리 · 반경 · 그림자)을 패널 밖에서 따로 그려야 하는데, 면은 `Drawer` 위젯 안쪽에서 그려져 이 계층이 나눌 수 없습니다.
- **드래그 중 모서리 처리는 다루지 않습니다.** 둥근 모서리도 같은 비율로 늘어나 아주 약간 타원이 됩니다.
- **Web 의 마우스는 패널을 벗어날 수 있습니다.** 포인터 캡처는 패널이 움직이기 시작한 첫 이동에서 걸리는데, 빠른 마우스 당김은 그 첫 이동에서 이미 패널 밖에 있습니다. 그래서 고무줄이 켜진 드로어는 배리어도 같은 포인터 핸들러를 달고 들은 것을 패널로 넘깁니다. 터치는 처음 누른 요소가 포인터를 갖기 때문에 이 경로가 필요 없습니다.

## 안전영역 채움 — `fillSafeArea`

기본(`false`)에서 Flutter 의 패널은 `SafeArea` **안쪽**에 놓입니다. 하단 시트는
홈 인디케이터 인셋만큼 화면 바닥 위에 떠 있고, 그 아래 띠에는 스크림이 보입니다.
많은 모바일 시트 디자인은 반대로 표면이 화면 바닥까지 채워지고 콘텐츠만 인셋
위에 있습니다. 그때 `fillSafeArea: true` 를 씁니다.

```dart
openDrawer<void>(
  context: context,
  side: CoreDrawerSide.bottom,
  fillSafeArea: true,
  builder: (ctx) => Drawer(
    side: CoreDrawerSide.bottom,
    content: ...,
  ),
);
```

- **패널이 붙은 한 변에만** 적용됩니다 (`bottom` 시트는 아래, `left` 드로어는
  왼쪽…). 나머지 세 변은 기존처럼 안전영역 안쪽에 남습니다.
- Flutter: `SafeArea` 가 그 한 변을 건너뛰고, 건너뛴 인셋을 패널이 표면 **안쪽**
  패딩으로 흡수합니다. 그래서 콘텐츠는 인셋을 침범하지 않고, 콘텐츠 안의
  `MediaQuery` 에서는 그 인셋이 이미 소비된 값(0)으로 보입니다 — 콘텐츠가 자기
  `SafeArea` 를 두어도 두 번 밀리지 않습니다. 고정 크기(`panelHeight` /
  `panelWidth`)는 이 확장분을 포함한 표면 전체 크기입니다.
- Web: 패널은 원래 뷰포트 가장자리에 붙어 있고 스스로 인셋을 처리하지 않으므로
  `false` 는 아무것도 바꾸지 않습니다. `true` 이면 붙은 변에 `env(safe-area-inset-*)`
  패딩을 더해 콘텐츠가 인셋을 비켜서게 합니다. 페이지가 `viewport-fit=cover` 를
  쓰지 않으면 브라우저가 인셋을 0 으로 보고하므로 no-op 입니다.

## 탭 셸에서 — `useRootNavigator: false` (Flutter)

`openDrawer` 는 기본으로 root `Navigator` 에 route 를 올리므로 시트와 스크림이
root 가 그리는 모든 것을 덮습니다. 탭마다 Navigator 를 두는 앱(`StatefulShellRoute`
류)에서는 하단 내비게이션 바가 탭 Navigator **바깥**에 있는 경우가 많고, 그러면
root 시트가 그 바까지 덮습니다. `useRootNavigator: false` 는 시트를 **가장 가까운**
Navigator(탭 본문)에 올려 이를 피합니다.

```dart
openDrawer<void>(
  context: context, // 탭 페이지 안쪽 context
  side: CoreDrawerSide.bottom,
  useRootNavigator: false,
  transformBackdrop: false,
  builder: (ctx) => Drawer(side: CoreDrawerSide.bottom, content: ...),
);
```

- 스크림과 시트가 그 Navigator 영역에만 그려지고, 그 밖의 영역(하단 바)은 덮이지
  않아 계속 탭할 수 있습니다.
- 시트는 그 Navigator 의 route 입니다. 시스템 뒤로 가기를 현재 탭 Navigator 기준
  (`canPop`/`maybePop`)으로 처리하는 셸이라면 뒤로 가기가 시트를 닫을 수 있고,
  root 에 올린 시트는 그 경로로는 닿지 않습니다. `closeDrawer` 와 드래그 dismiss 는
  어느 쪽이든 시트를 올린 Navigator 에서 닫습니다.
- 가장 가까운 Navigator 가 root 라면 두 값은 같습니다.
- 배경 축소(`transformBackdrop`)는 앱 셸 전체를 스케일하는 변형이라 한 Navigator
  에 속한 route 가 소유할 수 없습니다 — root 가 아닌 Navigator 에 올리면 적용되지
  않습니다(호스트가 없을 때와 같은 조용한 no-op).
- Web 에는 대응하는 파라미터가 없습니다. Web 의 `openDrawer` 는 호출 지점 위쪽의
  **가장 가까운** `OverlayHost` 에 올라가고(root 를 강제하지 않음), 고를 Navigator
  스택이 없기 때문입니다.

<a id="스타일-시스템-drawerstyle"></a>
## 스타일 시스템 (Style System)

Drawer 의 패널 겉모습 / 배리어 / 애니메이션 / 안쪽 부품의 미세 조정은 전부
`drawerStyle` (`CoreDrawerStyle`) 하나로 바꿉니다. 종류를 고르는 값 (`side`) 과
동작 정책 (`barrierDismissible`, `draggable`, `dismissOnEscape`) 은 위젯
파라미터로 직접 넘깁니다.

```dart
openDrawer(
  context: context,
  side: CoreDrawerSide.right,
  builder: (ctx) => Drawer(
    title: '설정',
    content: ...,
    drawerStyle: CoreDrawerStyle(
      panelBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius24),
      panelWidth: CoreLayout.layout320,
      barrierColor: CoreColor.token(CoreColors.scrim),
      barrierOpacity: CoreOpacity.opacity50,
      openAnimationDuration: Duration(milliseconds: CoreDuration.moderate),
      closeAnimationDuration: Duration(milliseconds: CoreDuration.normal),
      titleStyle: CoreTextStyle.token(
        CoreTextStyles.titleLarge,
        color: CoreColor.token(CoreColors.onSurface),
      ),
    ),
  ),
)
```

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreDrawerStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `panelBackgroundColor` | `CoreColor?` | Panel background fill colour override. |
| `panelBorderColor` | `CoreColor?` | Panel border stroke colour override. |
| `panelBorderRadius` | `CoreBorderRadius?` | Panel border radius override. When null, a `left` / `right` drawer defers to [defaultSidePanelBorderRadius] and a `top` / `bottom` sheet to [defaultPanelBorderRadius]. |
| `panelBorderWidth` | `double?` | Panel border stroke width override (logical px). When null, a `left` / `right` drawer defers to [defaultPanelBorderWidth] (1) and a `top` / `bottom` sheet to [defaultSheetPanelBorderWidth] (none). The line is drawn on the panel's inner edge only. |
| `panelWidth` | `double?` | Panel width override for `left` / `right` drawers (logical px). |
| `panelHeight` | `double?` | Panel height override for `top` / `bottom` drawers (logical px). `null` (the default) sizes the panel to its content, up to the viewport. |
| `panelPadding` | `CoreEdgeInsets?` | Panel inner content padding override. When null, defers to [defaultPanelPadding] (24 on all sides). Pass `CoreEdgeInsets.zero` to suppress the default content padding when the panel's `content` supplies its own. |
| `headerPadding` | `CoreEdgeInsets?` | Header padding override. When null, defers to [defaultHeaderPadding] (24 above and at the sides, 16 below). |
| `headerSpacing` | `double?` | Space between the title block and the close button (logical px, pre-scaling). `null` → [defaultHeaderSpacing]. |
| `footerPadding` | `CoreEdgeInsets?` | Padding of the footer row (the `footer` slot), below its divider. `null` → [defaultFooterPadding]. |
| `panelBoxShadow` | `List<CoreShadowLayer>?` | Panel elevation shadow override. When null, no shadow ([defaultPanelBoxShadow]). |
| `shadowBaseColor` | `CoreColor?` | Base colour the [panelBoxShadow] layers tint against. When null, defers to [defaultShadowBaseColor] (the `shadow` token). |
| `barrierColor` | `CoreColor?` | Barrier (scrim) overlay colour override. |
| `barrierOpacity` | `double?` | Barrier (scrim) opacity multiplier override (0.0 – 1.0). When null, defers to [defaultBarrierOpacity] (0.3). |
| `backdropScale` | `double?` | Backdrop scale-down factor override (0.0 – 1.0). When null, defers to [defaultBackdropScale] (1.0 — no zoom-out). Only takes effect when the widget's `transformBackdrop` behaviour flag is on. |
| `backdropCornerRadius` | `CoreBorderRadius?` | Corner radius override for the scaled backdrop clip. When null, defers to [defaultBackdropCornerRadius]. A different radius per corner works on both platforms. |
| `openAnimationDuration` | `Duration?` | Open animation duration override. |
| `closeAnimationDuration` | `Duration?` | Close animation duration override. |
| `titleStyle` | `CoreTextStyle?` | Header title text style override, laid over [defaultTitleStyle] (`titleMedium` role + `onSurface` tone). |
| `closeButtonStyle` | `CoreButtonStyle?` | Header close (dismiss) button style override. |
| `dividerStyle` | `CoreDividerStyle?` | Style of the header divider (the line under the title row). Merged onto [defaultDividerStyle], which is empty, so `Divider`'s own default applies; then passed to `Divider(dividerStyle: …)` as is. |
| `descriptionStyle` | `CoreTextStyle?` | Header description text style override — overlaid on [defaultDescriptionStyle] (`bodySmall` + `onSurfaceVariant`). |
| `titleDescriptionGapStyle` | `CoreGapStyle?` | Spacer between the title and the description — drawn only when the drawer has both. Merged onto [defaultTitleDescriptionGapStyle]. |
| `dragHandleColor` | `CoreColor?` | Grab-handle pill colour override. |
| `dragHandleWidth` | `double?` | Grab-handle pill length along the edge it lies on (logical px) — a horizontal pill on a top / bottom panel, a vertical one on a side drawer. |
| `dragHandleThickness` | `double?` | Grab-handle pill thickness across that edge (logical px). |
| `dragHandleInset` | `double?` | Space around the pill — between it and the panel edge, and between it and what sits beside it (logical px). |
| `dragHandleBorderRadius` | `CoreBorderRadius?` | Grab-handle pill corner radius override. |

<!-- STYLE_TABLE:END -->

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
design system default
  → CoreDrawerTheme.style                       // 프로젝트 공통
  → 부모 컴포넌트 슬롯 오버라이드
  → widget.drawerStyle                          // 인스턴스별
```

### 빠른 오버라이드 (Chain)

이미 만든 `Drawer` 인스턴스에 스타일을 빠르게 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 style 슬롯 인자와 동일하게 동작하지만, 이미 구성된 위젯 위에서 바로 이어 쓸 수 있습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class DrawerChainExample extends StatelessWidget {
  const DrawerChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.left,
          builder: (ctx) =>
              Drawer(
                title: '메뉴',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('대시보드'),
                    Text('설정'),
                    Text('프로필'),
                  ],
                ),
              ).withStyle(
                const CoreDrawerStyle(
                  panelBackgroundColor: CoreColor.token(
                    CoreColors.surfaceContainerHighest,
                  ),
                  panelBorderColor: CoreColor.token(CoreColors.primary),
                  panelBorderWidth: CoreStrokeWidth.stroke2,
                  panelBorderRadius: CoreBorderRadius.all(
                    CoreRadius.radius32,
                  ),
                  panelPadding: CoreEdgeInsets.all(CoreSpace.space32),
                  titleStyle: CoreTextStyle.token(
                    CoreTextStyles.titleLarge,
                    color: CoreColor.token(CoreColors.primary),
                  ),
                ),
              ),
        );
      },
      child: const Text('패널 열기'),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class DrawerChainExample extends StatelessComponent {
  const DrawerChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.left,
          builder: (close) =>
              Drawer(
                title: '메뉴',
                content: div(
                  [
                    const Text('대시보드'),
                    const Text('설정'),
                    const Text('프로필'),
                  ],
                  classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
                ),
              ).withStyle(
                const CoreDrawerStyle(
                  panelBackgroundColor: CoreColor.token(
                    CoreColors.surfaceContainerHighest,
                  ),
                  panelBorderColor: CoreColor.token(CoreColors.primary),
                  panelBorderWidth: CoreStrokeWidth.stroke2,
                  panelBorderRadius: CoreBorderRadius.all(
                    CoreRadius.radius32,
                  ),
                  panelPadding: CoreEdgeInsets.all(CoreSpace.space32),
                  titleStyle: CoreTextStyle.token(
                    CoreTextStyles.titleLarge,
                    color: CoreColor.token(CoreColors.primary),
                  ),
                ),
              ),
        );
      },
      child: const Text('패널 열기'),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

## 변형 (Variants)

### 위치 (Side)

```dart
openDrawer(side: CoreDrawerSide.left, ...)    // 좌측
openDrawer(side: CoreDrawerSide.right, ...)   // 우측
openDrawer(side: CoreDrawerSide.top, ...)     // 상단
openDrawer(side: CoreDrawerSide.bottom, ...)  // 하단
```

좌/우 드로어는 기본 너비 400 px (`CoreDrawerStyle.defaultPanelWidth`), 상/하 드로어는 기본적으로 **콘텐츠 크기**(뷰포트 상한 캡 — `ListView` 같은 greedy 콘텐츠는 상한까지 채움)입니다.

## 동작 스펙 (Behavior)

### 열기/닫기

`Drawer` 는 **명령형(imperative) 컴포넌트** 입니다 (shadcn_flutter / shadcn-ui 와 동일한 모델). 상태 boolean 으로 제어하지 않고, `openDrawer` 를 호출해 표시하고 다음 중 하나로 닫힙니다:

1. 배리어(스크림) 탭 — `barrierDismissible: true` (default)
2. 패널 드래그 — `draggable: true` (default). 놓았을 때 패널 자신의 길이 대비 50 % 이상이면 닫히고, 거리가 모자라도 닫히는 가장자리 쪽으로 400 px/s 이상으로 놓으면(플릭) 닫힘. 움직이지 않은 누름(탭)은 닫지 않는다
3. Escape 키 — `dismissOnEscape: true` (default, Web)
4. × 버튼 클릭 — 헤더(`title` 또는 `description`)가 있고 `showCloseButton: true` (default) 일 때
5. 빌더의 `close([result])` 콜백 (Web) / `closeDrawer(context, result)` (Flutter)

### 플릭으로 닫기 (Flick)

짧고 빠른 스트로크는 거리로만 보면 패널의 작은 조각만 덮고 손가락이 떠나므로, 사용자의 의도(던짐)와 달리 되돌아갑니다. 그래서 놓는 순간의 **속도**도 함께 봅니다.

- 닫히는 가장자리 쪽으로 `CoreDrawerContract.defaultDismissVelocity`(**400 px/s**) 이상이면 거리와 무관하게 닫힙니다. 단위는 항상 **px/s** 입니다 — 브라우저의 이벤트는 밀리초 단위라 0.4 px/ms 가 400 px/s 입니다.
- 이 기준은 디자이너 판단으로 정한 느낌 값이지 계산해 낸 값이 아닙니다. 위젯 파라미터도 `CoreDrawerStyle` 필드도 아니며(그리는 값이 아니라 살아 있는 제스처와 비교하는 값), 판정 함수의 `velocityThreshold` 인자로만 바꿀 수 있습니다.
- 속도는 **패널이 가장자리 쪽으로 실제로 움직였을 때만** 셈합니다. 움직이지 않은 채의 빠른 속도, 도킹된 쪽으로 향하는 속도는 던짐이 아닙니다. 반대로 속도가 거리 판정을 뒤집지는 않습니다 — 50 % 넘게 끌었다면 놓는 순간 되돌려도 닫힙니다.
- **측정**: Flutter 는 제스처 인식기의 `DragEndDetails.primaryVelocity`(px/s, 인식기가 fling 으로 보지 않는 느린 놓음은 0)를 닫히는 방향 부호로 바꿔 넘깁니다. Web 은 `pointermove` 의 위치와 이벤트 시각(`timeStamp`, ms)을 Core 의 `CoreDragVelocityTracker` 에 넣어 최근 100 ms 의 최소제곱 기울기를 읽습니다(샘플 사이가 40 ms 넘게 비면 멈춘 것). 놓는 이벤트는 샘플이 아니라 **묻는 시각**입니다 — 마지막 이동 뒤 40 ms 넘게 가만히 있다가 놓으면(`velocityAt`) 던짐이 아닙니다. Flutter 의 `VelocityTracker` 도 인식기가 물을 때 마지막 샘플이 40 ms 넘게 오래됐으면 0 으로 답하므로 두 플랫폼이 같게 읽습니다.
- 두 플랫폼은 같은 벡터 표(`coui_core/test/fixtures/drag_release_vectors.json`)로 고정됩니다.

### 애니메이션

- **슬라이드**: 350 ms `ease-out` (열기) / `ease-out-cubic` (닫기) — `CoreDrawerStyle.defaultOpenAnimationDuration` / `defaultCloseAnimationDuration`
- **배리어 페이드**: 350 ms `ease-out` (양쪽 동일)
- **드래그 중**: transition 일시 정지 (panel 이 손가락을 즉시 따라감)
- **고무줄 복귀**: 300 ms `CoreEasing.enter` — `CoreDrawerRubberBand.defaultSettleDuration` / `defaultSettleEasing`. 전환 tier 라 동작 줄이기에서 즉시

### 레이아웃

- 좌/우 드로어: 너비 `CoreDrawerStyle.defaultPanelWidth` (400 px) × 화면 전체 높이
- 상/하 드로어: 화면 전체 너비 × **콘텐츠 높이** (뷰포트 상한 캡; shadcn_flutter 와 동일 모델)
- `CoreDrawerStyle.panelWidth` / `panelHeight` 로 오버라이드 가능
- 좌/우 드로어의 모서리는 0, 안쪽 한 변(화면 중앙 쪽)에만 `outlineVariant` 1 의 경계를 그리고 그림자는 없습니다. 상/하 시트는 안쪽 모서리 16, 경계 없음, 그림자 없음입니다.
- 헤더는 위 24 · 좌우 24 · 아래 16 이고 위쪽에 맞춰 놓이며 제목과 닫기 버튼 사이는 16 입니다. 닫기 버튼은 `Button` plain · sm · square(32) 입니다. 내용 여백은 위아래 20 · 좌우 24 이고, 좌/우 드로어에서는 남는 높이를 채웁니다.
- 하단(`footer`)은 기본 꺼짐이며 슬롯을 넘기면 그려집니다. 여백은 위아래 16 · 좌우 24(`footerPadding`)입니다.
- 닫기 드래그는 바깥 방향 이동만 누적하고, 놓는 순간 그 거리가 패널 자신의 슬라이드 축 길이의 `dragDismissThreshold` 이상이거나 놓는 속도가 플릭 기준(아래) 이상이면 닫힙니다. 두 플랫폼이 같은 판정 함수(`CoreDrawerContract.dismissesOnRelease`)에 같은 패널 길이와 같은 부호의 속도를 넘깁니다.
- 손잡이는 하단 시트의 헤더 위, 상단 시트의 콘텐츠 아래, 측면 드로어의 안쪽 변(본문 옆에 세로로)에 놓입니다.
- 접힘선이 화면을 나누면(힌지가 가리거나 반쯤 접혔을 때) 드로어는 한 조각 안에 붙습니다 — 자기 가장자리가 놓인 조각이고, 그 가장자리 가운데가 접힘선이면 위쪽, 그다음 글이 시작하는 쪽 조각입니다(`Dialog` 가 열리는 쪽). 책처럼 접은 화면의 하단 시트는 한쪽 면의 폭으로, 세워 둔 화면의 하단 시트는 아래 반쪽 높이 안에 열립니다. 배경막은 화면 전체를 덮습니다. 화면 일부를 채운 내비게이터에 열면(`useRootNavigator: false`) 그 내비게이터의 가장자리가 기준입니다. 접힘선이 화면을 나누지 않으면 위의 크기 그대로입니다. → [접히는 화면](/guides/layout#접히는-화면)

## 사용 가이드라인 (Usage Guidelines)

### ✅ Do

<Callout type="tip">

**드로어에 명확한 제목과 닫기 방법을 제공하세요.**

```dart
openDrawer(
  context: context,
  side: CoreDrawerSide.right,
  builder: (close) => Drawer(
    title: '필터 설정',
    content: FilterPanel(onApply: (f) => close(f)),
  ),
)
```

`title` 이 있으면 자동으로 헤더 + × 버튼이 그려집니다. 사용자가 어떤 패널인지 파악하고 쉽게 닫을 수 있습니다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**짧은 확인 메시지에 Drawer 를 사용하지 마세요.**

```dart
openDrawer(
  context: context,
  side: CoreDrawerSide.bottom,
  builder: (close) => Drawer(
    content: Text('정말 삭제하시겠습니까?'),
  ),
)
```

간단한 확인은 `Dialog` 가 더 적합합니다. `Drawer` 는 복잡한 콘텐츠/네비게이션용입니다.

</Callout>

### ✅ Do

<Callout type="tip">

**콘텐츠에 맞는 `side` 를 선택하세요.**

- 네비게이션 메뉴 → `left`
- 보조 상세 / 필터 패널 → `right`
- 모바일 시트 / 액션 → `bottom`
- 알림 / 이벤트 시트 → `top`

사용자 기대에 맞는 방향이어야 직관적입니다.

</Callout>

## 접근성 (Accessibility)

### 역할

- **Flutter**: 패널을 `Semantics(container: true, label: title)` 로 감쌉니다 — `title` 이 `null` 이면 **이름 없는 컨테이너**가 됩니다. 드로어는 `Navigator.push` 로 올라간 `PopupRoute` 라 안드로이드 시스템 뒤로가기가 그대로 닫습니다. 라우트 배리어의 이름은 `CoUILocalizations.of(context).dismissLabel` 입니다.
- **Web**: 패널에 `role="dialog"` + `aria-modal="true"` 를, `title` 이 있을 때만 `aria-label={title}` 을 내보냅니다. 배리어에는 role/`aria-label` 을 **의도적으로 붙이지 않습니다** — role 없는 `<div>` 는 접근성 트리에 노출되지 않으므로 이름을 줄 대상이 없고, dismiss 기능(바깥 클릭·Escape)은 그대로입니다.

### 키보드

| 키 | 동작 |
|----|------|
| `Escape` | 드로어 닫기 — Web 은 `dismissOnEscape`(기본 `true`)가 gate 이고, **Flutter 는 `dismissOnEscape` 를 읽지 않고** `openDrawer(barrierDismissible:)`(기본 `true`)가 gate 입니다 |
| `Tab` / `Shift+Tab` | 드로어 안 요소 간 이동 |
| `Enter` / `Space` | 포커스된 요소(헤더 × 버튼 포함) 활성화 |

화살표 키 처리는 없습니다. 드래그로 닫기는 포인터 전용이지만 Escape·× 버튼·배리어가 같은 결과를 주므로 키보드 경로가 막히지는 않습니다.

### 스크린 리더

- **이름은 `title` 하나에서만 옵니다.** Flutter 는 `Semantics(label: title)`, Web 은 `aria-label={title}` 입니다. `title` 을 주지 않으면 양쪽 다 이름이 없습니다. `description` 만 있으면 헤더는 그려지지만 이름이 되지는 않습니다.
- **`description` 은 헤더 안의 텍스트로 읽힙니다.** 양쪽 모두 이름이나 `aria-describedby` 로 패널에 연결하지 않습니다.
- **헤더 × 버튼은 양 플랫폼 모두 `buttonClose`(ko: "닫기")를 이름으로 갖습니다.** Web 은 `aria-label`, Flutter 는 `Semantics(label:)` 로 같은 로컬라이제이션 키를 씁니다.
- **배경은 양쪽 모두 가려집니다.** Flutter 는 모달 라우트의 `ModalBarrier` 가 `BlockSemantics` 로, Web 은 `modal: true` 마운트가 앱 콘텐츠 서브트리에 `inert` 를 붙여 접근성 트리·탭 순서·히트 테스트에서 뺍니다.
- 상태 통보(live region)는 없습니다.

### 포커스 관리

- **진입** — Flutter: 라우트가 자기 포커스 스코프를 첫 포커스로 세우므로 포커스가 드로어 안으로 들어갑니다. Web: 포커스를 옮기는 코드가 **없습니다**(오버레이 경로 전체에 `focus()` 호출 0건) — 대신 배경이 `inert` 가 됩니다.
- **이탈** — Flutter: 라우트 pop 과 함께 이전 스코프로 돌아갑니다. Web: 트리거로 포커스를 되돌리는 코드가 없습니다.
- **트랩** — Flutter: `_DrawerRoute` 는 `traversalEdgeBehavior` 를 지정하지 않아 `Navigator` 기본값을 씁니다(네이티브 `parentScope`, Flutter Web `leaveFlutterView`) — `Dialog` 와 달리 **드로어 안에서 순환하지 않습니다**. 다만 배경 라우트는 모달 아래에서 순회 대상에서 빠집니다. Web: `inert` 로 배경만 차단되고 패널 안 순환은 없습니다 — 마지막 요소에서 `Tab` 은 브라우저 UI 로 나갔다가 돌아옵니다.

### 알려진 제약

- **Flutter 에서는 `Drawer(dismissOnEscape:)` / `barrierDismissible:` / `draggable:` / `rubberBand:` 가 무시됩니다.** `openDrawer` 가 패널 위젯의 필드를 읽지 않고 자기 동명 파라미터만 사용하므로, Escape·배리어·드래그·고무줄 정책은 `openDrawer(barrierDismissible: …, draggable: …, rubberBand: …)` 로 주어야 합니다. Web 은 패널 필드가 그대로 적용됩니다.
- **`title` 도 `description` 도 없으면 헤더가 통째로 없습니다** — 이름도 × 버튼도 사라지므로, 배리어·Escape 외의 닫기 어포던스가 필요하면 `title` 을 주거나 `content` 안에 직접 넣으세요. `showCloseButton: false` 도 × 버튼을 없앱니다.
- **손잡이는 장식입니다** — Flutter 는 `ExcludeSemantics`, Web 은 `aria-hidden="true"` 로 보조 기술에 아무것도 더하지 않습니다. 끌어서 닫는 것은 포인터 사용자를 위한 지름길이고, 다른 닫기 경로(배리어·Escape·× 버튼·뒤로 가기)는 그대로입니다.
- **backdrop-transform 모드(기본값)에서 패널 안의 `Navigator.of(context).pop()` 은 드로어를 닫지 않습니다.** 패널이 앱 셸 host 를 통해 그려지면서 안쪽에 `Navigator` 가 하나 더 서기 때문에 그쪽이 pop 됩니다 — 드로어를 닫을 때는 `closeDrawer(context, result)`(Flutter) / 빌더의 `close([result])`(Web)를 쓰세요.
- **Web 은 열 때 포커스를 옮기지 않고 닫을 때 되돌리지도 않습니다.**

전역으로 적용되는 축(동작 줄이기·고대비·색 강제 모드·최소 터치 타겟)은
[전역 접근성 축](/accessibility)에 있습니다.

## 크로스 플랫폼 차이점 (Platform Differences)

`Drawer` 는 Flutter / Web 에서 동일한 명령형 API (`openDrawer<T>`, `Drawer` panel) 를 공유합니다. 아래는 플랫폼 내부 구현 차이만 나열합니다.

| 항목 | Flutter | Web |
|------|---------|-----|
| 오버레이 마운트 | `Navigator.push(_DrawerRoute<T>)` | `OverlayHost.dialog` 레이어 portal |
| 애니메이션 | `SlideTransition + Tween<Offset>` 350 ms `Curves.easeOut` | CSS `transform: translateX` 350 ms `ease-out` |
| 배리어 | `PopupRoute.barrierColor` | `<div class="absolute inset-0">` + click handler |
| 드래그 dismiss | `GestureDetector + onVertical/HorizontalDrag*` (패널 렌더 박스 길이 대비) | `pointerdown/move/up/cancel` + 첫 이동에서 pointer capture, 패널 `touch-action: none` (패널 `getBoundingClientRect()` 길이 대비) |
| 플릭 속도 | 인식기의 `DragEndDetails.primaryVelocity`(px/s)를 닫히는 방향 부호로 | `pointermove` 위치 + `event.timeStamp`(ms)를 Core `CoreDragVelocityTracker` 에 넣고, 놓는 이벤트의 시각으로 `velocityAt` 을 물어 px/s 로 읽어 같은 부호로 (마지막 이동 뒤 40 ms 넘게 멈췄으면 0 — Flutter 인식기와 같다) |
| 본문 위 터치 드래그 | 스크롤할 수 있는 자식이 드래그를 가져가고(gesture arena), 아니면 시트가 끌린다 | 본문은 스크롤 컨테이너라, 내용이 넘치면 본문이 스크롤되고 넘치지 않으면(`ResizeObserver` 측정) 시트가 끌린다. 손잡이·헤더는 언제나 시트를 끈다 |
| 고무줄 그리기 | 도킹 변을 `alignment` 로 한 `Transform`(scale)을 드래그 값으로 다시 그림 | `transform: scaleX/scaleY(k)` + `transform-origin: <도킹 변>` (미끄러질 때는 `translate`) |
| 고무줄 복귀 | `AnimationController` + 같은 `Cubic` 곡선, 길이는 `resolveMotionDuration` (동작 줄이기에서 0) | CSS `transition: transform` — 길이는 duration 변수(동작 줄이기에서 0 으로 덮임), 곡선은 같은 cubic-bezier |
| 복귀 중 다시 잡기 | 컨트롤러가 들고 있는 현재 자세에서 이어서 | `getComputedStyle(panel).transform` 을 읽어 그 자세에서 이어서 |
| 패널 밖으로 나간 포인터 | 제스처 인식기가 포인터를 계속 따라감 | 마우스: 캡처가 걸리기 전에는 배리어가 같은 핸들러로 받아 패널에 넘김. 터치: 처음 누른 요소가 암묵적으로 포인터를 가짐 |
| 닫기 API | `closeDrawer(context, result)` 또는 `Navigator.pop(ctx, result)` | builder 의 `close([result])` 콜백 |
| 시스템 back | `PopScope` 자동 | (없음) |

## 관련 컴포넌트 (Related Components)

- **[Dialog](/components/dialog)**: 모달 대화상자. 짧은 확인/입력에 적합 (Drawer 는 복잡한 콘텐츠용)
- **[Navigation](/components/navigation)**: 네비게이션 컴포넌트. Drawer 안에 배치하여 모바일 메뉴 구현
- **[Popover](/components/popover)**: 요소에 붙는 팝업. Drawer 보다 작고 특정 컨텍스트에 연결

### 조합 예제

```dart
// 모바일 필터 드로어 패턴
final filter = await openDrawer<FilterValue>(
  context: context,
  side: CoreDrawerSide.right,
  builder: (close) => Drawer(
    title: '필터',
    content: FilterPanel(
      onApply: (value) => close(value),
    ),
  ),
);
if (filter != null) applyFilter(filter);
```
