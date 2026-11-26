---
title: Drawer
description: 드로어/사이드바 컴포넌트
category: overlay
platforms: [flutter, web]
related: [dialog, swiper, bottom-sheet]
tags: [panel, sidebar, interactive]
template: v2
source: overlay/drawer
---

# Drawer

<a id="live-preview"></a>

## 플레이그라운드

Drawer는 화면의 한 가장자리에서 밀려 나오는 모달 패널입니다. `openDrawer`를 불러 열고, 닫히면 그 `Future`가 결과와 함께 완료됩니다. 속성을 바꿔 보며 패널을 확인하고, **열어 보기**로 같은 속성의 서랍을 실제로 열어 보세요. 만들어진 코드는 그대로 복사할 수 있습니다.

<Playground component="drawer" />

<Note>

무대의 패널은 페이지 안의 작은 화면에 그린 그림입니다. 실제 서랍은 열리면 화면 전체를 덮습니다.

- 웹 그림은 열린 서랍이 쓰는 겉모습 값(기본값 · `CoreDrawerTheme` · 테마 · 서페이스 스타일)으로 그립니다. Flutter 그림은 실제 `Drawer` 위젯을 라우트 없이 놓은 것입니다.
- 그림은 누르거나 끌 수 없습니다. 끌어 닫기, 고무줄, 열고 닫는 전환, 배리어(어두운 막) 누르기는 열린 서랍에서만 볼 수 있습니다. 이 페이지의 다른 미리보기도 같은 그림입니다.
- 웹 팬에서 연 서랍은 페이지 전체를, Flutter 팬에서 연 서랍은 그 팬 안을 덮습니다.
- 무대가 좁으면 웹 그림은 좌우 서랍의 폭을 줄이고, Flutter 그림은 작은 화면 전체를 줄여 그립니다.

</Note>

## 구조

서랍은 뒤 화면을 덮는 배리어(어두운 막)와 한 가장자리에 붙은 패널로 이루어집니다. 아래는 하단 시트입니다.

<Anatomy demo="drawer/anatomy">
<AnatomyItem select="[data-docs-part=panel]" side="left" name="panel">

패널. 배경은 `surfaceBright`이고, 그림자는 기본으로 없습니다. 모서리와 테두리는 붙는 가장자리에 따라 다릅니다(아래 표).

</AnatomyItem>
<AnatomyItem select="[data-docs-part=handle]" side="top" name="showDragHandle">

손잡이. 화면 가운데를 향한 변에 둡니다. 하단 시트는 머리 줄 위, 상단 시트는 맨 아래(하단 영역이 있으면 그 아래), 좌우 서랍은 안쪽 변에 세로로 놓입니다. 크기는 48 × 6, 색은 `surfaceContainer`, 둘레 여백은 8입니다. 끌 수 있다는 표시일 뿐이며, 끌기는 패널 전체가 받습니다. 기본 다크 테마에서는 패널과 같은 색이라 보이지 않습니다([알려진 제약](#알려진-제약)).

</AnatomyItem>
<AnatomyItem select="[data-docs-part=title]" side="left" name="title · description">

`title`의 글자는 `titleMedium` · `onSurface`, `description`은 `bodySmall` · `onSurfaceVariant`이고 둘 사이는 4입니다. 둘 중 하나만 있어도 머리 줄이 생기고, 머리 줄 아래에 1px `outlineVariant` 구분선이 놓입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=close]" side="right" name="showCloseButton">

닫기(×) 버튼. `Button`의 `plain` · `sm` · `square`이며 32 × 32, 아이콘은 16입니다. 머리 줄이 있을 때만 그립니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=content]" side="right" name="content">

내용. 여백은 위아래 20, 좌우 24입니다. 좌우 서랍에서는 머리 줄과 하단 영역을 뺀 남은 높이를 채웁니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=footer]" side="left" name="footer">

하단 영역. 구분선 아래에 끝 쪽(왼쪽에서 오른쪽으로 읽으면 오른쪽)으로 정렬합니다. 여백은 위아래 16, 좌우 24입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=scrim]" side="top" name="barrier">

배리어. `scrim` 색을 30% 불투명도로 칠합니다. 열린 서랍에서는 누르면 닫힙니다(`barrierDismissible`).

</AnatomyItem>
</Anatomy>

머리 줄 여백은 위와 좌우 24, 아래 16이고, 제목 묶음과 닫기 버튼 사이는 16입니다.

| 항목 | 좌우 서랍 | 상하 시트 |
|---|---|---|
| 모서리 | 0 | 화면 가운데 쪽 두 모서리 16 |
| 테두리 | 화면 가운데 쪽 한 변에 1px `outlineVariant` | 없음 |
| 그림자 | 없음 | 없음 |
| 크기 | 폭 400, 높이는 화면 전체 | 폭은 화면 전체, 높이는 내용 높이(화면을 넘지 않음) |

<a id="동작-스펙-behavior"></a>

## 상태

Drawer는 `open` 같은 상태값으로 열고 닫지 않습니다. `openDrawer`를 부르면 열리고, 닫히면 그 `Future`가 완료됩니다.

<a id="기본-사용법-basic-usage"></a>
<a id="조합-예제"></a>

### 열기/닫기

패널 안에서 결과를 돌려주며 닫을 수 있습니다. Flutter는 `builder`가 받은 컨텍스트로 `closeDrawer`를 부르고, 웹은 `builder`가 받은 `close`를 부릅니다. 배리어, 끌기, `Escape`, × 버튼으로 닫으면 결과는 `null`입니다.

<Split>

<Code language="dart" title="Flutter">
final picked = await openDrawer<String>(
  context: context,
  side: CoreDrawerSide.right,
  builder: (drawerContext) => Drawer(
    title: '색상 선택',
    content: Button(
      onPressed: () => closeDrawer<String>(drawerContext, '파랑'),
      child: const Text('파랑'),
    ),
  ),
);
if (picked != null) applyColor(picked);
</Code>

<Code language="dart" title="Jaspr Web">
final picked = await openDrawer<String>(
  context: context,
  side: CoreDrawerSide.right,
  builder: (close) => Drawer(
    title: '색상 선택',
    content: Button(
      onPressed: () => close('파랑'),
      child: const Text('파랑'),
    ),
  ),
);
if (picked != null) applyColor(picked);
</Code>

</Split>

- 열린 패널은 서랍을 연 위젯의 `setState`를 따라가지 않습니다. 웹은 `builder`를 열 때 한 번만 부릅니다. 열린 동안 바뀌어야 하는 상태는 `content` 안의 상태 위젯이 직접 갖게 하세요.
- 끌기, 고무줄, 안전 영역, 뒤 화면 효과 같은 열기 옵션은 Flutter에서는 `openDrawer`에, 웹에서는 `Drawer`에 줍니다. `dismissOnEscape`는 웹에만 적용됩니다.

### 닫는 방법

| 방법 | 조건 |
|---|---|
| 배리어 누르기 | `barrierDismissible`(기본 `true`). Flutter는 `openDrawer`에, 웹은 `Drawer`에 줍니다 |
| 패널 끌기 · 플릭 | `draggable`(기본 `true`). 아래 [플릭으로 닫기](#플릭으로-닫기)를 보세요 |
| `Escape` | 웹은 `dismissOnEscape`(기본 `true`)를 따릅니다. Flutter는 `openDrawer(barrierDismissible:)`를 따릅니다. [알려진 제약](#알려진-제약)도 보세요 |
| × 버튼 | 머리 줄이 있고 `showCloseButton`이 `true`일 때 |
| 시스템 뒤로 가기(Flutter) | 서랍은 라우트라 뒤로 가기가 닫습니다. `barrierDismissible: false`여도 닫힙니다 |
| 코드 | Flutter는 `closeDrawer(context, result)`, 웹은 `close(result)` |

<a id="플릭으로-닫기-flick"></a>

### 플릭으로 닫기

짧고 빠르게 던지는 동작은 거리만 보면 패널을 조금만 움직이고 끝납니다. 그래서 놓는 순간의 속도도 함께 봅니다. 두 플랫폼은 같은 판정(`CoreDrawerContract.dismissesOnRelease`)을 씁니다. 속도는 닫히는 쪽을 +로 한 px/s 값입니다.

- 닫히는 쪽으로 끈 거리가 패널 자신의 길이(밀려 나오는 방향)의 `dragDismissThreshold`(기본 0.5) 이상이면 닫힙니다.
- 거리가 모자라도 닫히는 쪽으로 400 px/s(`CoreDrawerContract.defaultDismissVelocity`) 이상으로 놓으면 닫힙니다. 이 속도 기준은 손으로 만져 보며 정한 느낌 값이며, 위젯 파라미터도 `CoreDrawerStyle` 필드도 아니라서 서랍마다 바꿀 수 없습니다.
- 속도는 패널이 닫히는 쪽으로 실제로 움직였을 때만 셉니다. 거리가 기준을 넘었으면 놓는 순간 되돌려도 닫힙니다.
- 움직이지 않고 누르기만 한 것(탭)은 닫지 않습니다. `rubberBand`를 켜지 않은(기본) 서랍은 열리는 방향의 끌기를 무시합니다.
- Flutter는 제스처 인식기가 알려 주는 놓는 속도를 씁니다. 인식기가 던지기로 보지 않는 느린 놓음은 0입니다. 웹은 포인터 이동의 위치와 시각에서 최근 100ms의 속도를 읽습니다. 두 플랫폼 모두 마지막 이동 뒤 40ms 넘게 멈췄다가 놓으면 던진 것으로 보지 않습니다.

<a id="고무줄-rubberband"></a>

### 고무줄

붙은 패널은 이미 가장 많이 열린 자리에 있어, 열리는 방향으로는 더 갈 곳이 없습니다. 기본(`false`)에서는 그 방향의 끌기를 무시합니다. `rubberBand: true`는 그 끌기를 받아, 패널의 먼 쪽 가장자리가 손가락을 따라가되 갈수록 덜 따라가고, 놓으면 제자리로 돌아옵니다. "끝에 닿았다"와 "걸려서 안 움직인다"를 구별하게 해 주는 신호라서, 손으로 만지는 하단 시트나 피커에 어울립니다. 위쪽의 취소 · 완료 줄은 따로 있는 컴포넌트가 아니라, `content` 첫 줄에 `Button` 둘과 제목을 놓은 것입니다.

<Preview demo="drawer/rubber-band" height="340" />

<Split>

<Code language="dart" title="Flutter">
openDrawer<void>(
  context: context,
  side: CoreDrawerSide.bottom,
  rubberBand: true,
  builder: (drawerContext) => Drawer(
    showDragHandle: true,
    showCloseButton: false,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Button(
              variant: CoreButtonVariant.ghost,
              onPressed: () => closeDrawer<void>(drawerContext),
              child: const Text('취소'),
            ),
            Expanded(child: Center(child: Text('알림 시간').titleMedium)),
            Button(
              onPressed: () => closeDrawer<void>(drawerContext),
              child: const Text('완료'),
            ),
          ],
        ),
        timeList,
      ],
    ),
  ),
);
</Code>

<Code language="dart" title="Jaspr Web">
openDrawer<void>(
  context: context,
  side: CoreDrawerSide.bottom,
  builder: (close) => Drawer(
    rubberBand: true,
    showDragHandle: true,
    showCloseButton: false,
    content: div(classes: 'flex flex-col', [
      div(classes: 'flex items-center', [
        Button(
          variant: CoreButtonVariant.ghost,
          onPressed: close,
          child: const Text('취소'),
        ),
        div(classes: 'flex-1 text-center', [Text('알림 시간').titleMedium]),
        Button(onPressed: close, child: const Text('완료')),
      ]),
      timeList,
    ]),
  ),
);
</Code>

</Split>

- **붙은 변은 움직이지 않습니다.** 패널은 그 변을 고정한 채 밀려 나오는 방향으로 늘어납니다. 통째로 옮기면 붙은 변과 화면 가장자리 사이로 뒤 화면이 보이기 때문입니다. 닫히는 쪽으로 끌면 손가락과 1:1로 미끄러집니다. 어느 순간에도 패널은 미끄러지거나 늘어나거나 둘 중 하나입니다.
- **늘어나는 길이는 곡선이 정합니다.** 손가락이 제자리를 `x`px 넘어가면 먼 쪽 가장자리는 `L·(τ·x) / (L + τ·x)`만큼 나갑니다. `L`은 패널 길이의 10%, `τ`는 0.55입니다. 갈수록 덜 늘고 `L`을 넘지 않습니다. 300px 시트는 60px를 끌면 약 15.7px, 1000px를 끌어도 약 28.4px만 늘어납니다(한계는 30px). 손가락이 돌아오면 온 길을 그대로 되짚습니다.
- **닫기 판정은 고무줄과 상관없습니다.** 늘어난 패널은 닫히는 쪽으로 간 거리가 0이라, 열리는 방향으로 아무리 빠르게 던져도 닫히지 않습니다. 손가락을 되돌려 닫히는 쪽으로 끌면 제자리를 지나는 순간부터 거리가 쌓입니다.
- **놓으면 돌아옵니다.** 300ms 동안 점점 느려지며 제자리로 돌아오고, 튕기지 않습니다. 돌아오는 중에 다시 잡으면 지금 모습에서 이어서 끕니다.
- **터치로 하는 본문 스크롤과 다투지 않습니다.** 스크롤되는 본문에서 손가락으로 시작한 끌기는 본문이 받습니다. 웹의 좌우 서랍에는 예외가 있습니다([알려진 제약](#알려진-제약)). 손잡이와 머리 줄에서 시작한 끌기는 끌 수 있는 서랍이라면 패널을 끕니다.
  - Flutter는 안쪽 스크롤 위젯이 터치 끌기를 가져갑니다. `controller`와 `physics` 없이 만든 세로 `ListView`는 내용이 넘치지 않아도 끌기를 가져가므로, 그 위에서 시작한 끌기는 패널에 닿지 않을 수 있습니다. 스크롤 위젯이 없는 본문이나, 내용이 넘치지 않는 `SingleChildScrollView`에서는 패널이 끌립니다.
  - 웹은 내용이 넘치지 않는 본문에서 시작한 끌기로 패널을 끕니다. 넘치는 본문에서는 브라우저가 스크롤로 판단할 때까지 몇 px 동안 패널이 따라갔다가, 판단이 나면 돌아옵니다. 마우스로 본문을 끌면 본문은 스크롤되지 않고 패널이 따라갑니다. 좌우 서랍은 [알려진 제약](#알려진-제약)도 보세요.
- **읽는 방향과 상관없습니다.** `CoreDrawerSide`는 화면의 물리 방향이라, 오른쪽에서 왼쪽으로 읽는 로케일에서도 같은 변에 붙고 같은 쪽으로 늘어납니다.
- **동작 줄이기.** 손가락을 누른 채 늘어나는 것은 손가락의 움직임이라 그대로 따라갑니다. 돌아오는 전환은 동작 줄이기에서 바로 끝납니다.
- 늘어남은 크기만 바꾸는 변형이라 색, 재질, 테두리는 그대로입니다. 그래서 투명도 줄이기, 고대비, 색 강제 모드에서 따로 달라지는 것이 없습니다. 키보드와 스크린 리더에는 아무것도 더하지 않고, 닫는 방법도 그대로입니다.

#### 디자이너 판단 값

아래 값은 계산해 낸 값이 아니라 기기에서 만져 보며 정한 값입니다. 위젯 파라미터나 `CoreDrawerStyle` 필드로는 바꿀 수 없습니다.

| 값 | 상수 | 기본 |
|---|---|---|
| 최대로 늘어나는 비율 | `CoreDrawerRubberBand.defaultReach` | 0.1(패널 길이의 10%) |
| 첫 반응 | `CoreDrawerRubberBand.defaultTension` | 0.55 |
| 돌아오는 시간 | `CoreDrawerRubberBand.defaultSettleDuration` | `CoreDuration.moderate`(300ms) |
| 돌아오는 곡선 | `CoreDrawerRubberBand.defaultSettleEasing` | `CoreEasing.enter` |

고무줄은 기본이 꺼져 있고(`CoreDrawerContract.defaultRubberBand`), `rubberBand: true`로 켭니다.

#### 고무줄의 알려진 제약

- 패널 안의 글자와 버튼도 같은 비율로 늘어납니다. 비율은 최대 10%이고, 보통의 당김(30–60px)에서는 3–5%라 끄는 동안에만 보입니다.
- 둥근 모서리도 같이 늘어나 아주 약간 타원이 됩니다.

### 애니메이션

- 열고 닫는 전환은 각각 350ms입니다(`openAnimationDuration` · `closeAnimationDuration`).
- 패널은 열 때 두 플랫폼 모두 `CoreEasing.enter`(ease-out)로 미끄러집니다. 닫을 때 Flutter는 ease-out-cubic 곡선을 거꾸로 따라가 천천히 출발해 빨라지고, 웹은 열 때와 같은 ease-out이라 빠르게 출발해 느려집니다.
- 배리어는 웹에서 ease-out으로 나타나고 사라집니다. Flutter는 뒤 화면 효과를 쓰는 기본 구성(`CoUIApp`에서 `transformBackdrop: true`)에서는 일정한 속도로, 그 밖의 구성에서는 `Curves.ease`로 바뀝니다.
- 끄는 동안에는 전환 없이 손가락을 따라갑니다.
- 동작 줄이기에서는 열고 닫는 전환이 바로 끝납니다. 다만 웹은 닫은 서랍을 `closeAnimationDuration`이 지난 뒤에 치우므로, 그동안은 뒤 화면을 누를 수 없습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

- 필터, 설정, 상세 정보 같은 보조 내용을 화면 옆에서 보여 줄 때
- 지금 화면을 떠나지 않고 작업할 자리가 더 필요할 때
- 휴대폰의 탐색 메뉴를 만들 때

### 다른 컴포넌트가 더 맞는 경우

| 상황 | 컴포넌트 |
|---|---|
| 버튼 대신 화면의 한 영역을 밀어서 열게 하고 싶을 때 | [Swiper](/components/swiper) |
| 화면 가운데에서 흐름을 멈추고 응답을 받을 때 | [Dialog](/components/dialog) |
| 휴대폰에서 손잡이, 제목, 내용, 하단 바를 갖춘 하단 면이 필요할 때 | [BottomSheet](/components/bottom-sheet) |
| 특정 버튼 옆에 붙는 작은 패널이 필요할 때 | [Popover](/components/popover) |
| 무엇을 열지 않고 본문의 한 자리만 바꿀 때 | [Tabs](/components/tabs) |

<a id="do"></a>
<a id="dont"></a>

### 내용과 닫기

<Cards columns="2">
<Card demo="drawer/do-complex" tone="do" eyebrow="이렇게 하세요" title="입력을 받는 작업" height="340">

필터처럼 값을 고르고 확정하는 작업은 옆 서랍에 담고, 확정 버튼은 하단 영역에 둡니다.

</Card>
<Card demo="drawer/dont-confirm" tone="dont" eyebrow="이렇게 하지 마세요" title="짧은 확인" height="340">

예 · 아니요만 묻는 확인에는 [Dialog](/components/dialog)를 씁니다. 서랍은 여러 항목을 담는 패널입니다.

</Card>
<Card demo="drawer/do-title" tone="do" eyebrow="이렇게 하세요" title="제목과 닫기 버튼" height="340">

`title`을 주면 머리 줄과 × 버튼이 함께 생깁니다. 사용자가 어떤 패널인지 알고 쉽게 닫을 수 있습니다.

</Card>
<Card demo="drawer/dont-no-name" tone="dont" eyebrow="이렇게 하지 마세요" title="이름 없는 패널" height="340">

`title`도 `description`도 없으면 머리 줄과 × 버튼이 없고, 패널에는 이름이 없습니다.

</Card>
</Cards>

<a id="변형-variants"></a>
<a id="위치-side"></a>

## 배치

### 붙는 가장자리

| `side` | 어울리는 쓰임 |
|---|---|
| `left` | 탐색 메뉴 |
| `right` | 보조 상세 정보, 필터 |
| `bottom` | 휴대폰의 시트, 동작 목록 |
| `top` | 알림, 이벤트 |

- 어느 가장자리에 붙는지는 `openDrawer(side:)`가 정합니다. 패널은 붙은 변의 두 모서리를 평평하게 하고, 손잡이를 반대쪽(화면 가운데 쪽) 변에 둡니다.
- `Drawer(side:)`는 Flutter에서 라우트 없이 패널을 직접 그릴 때만 읽습니다(`Swiper`를 끄는 동안 따라 나오는 패널이 그렇습니다). 웹은 읽지 않습니다.
- `left`와 `right`는 화면의 물리 방향이라, 오른쪽에서 왼쪽으로 읽는 로케일에서도 같은 변입니다.

<Cards columns="2">
<Card component="drawer" props="side=left" title="left" height="340">

`Drawer(side:)`의 기본값입니다.

</Card>
<Card component="drawer" props="side=right" title="right" height="340">

본문 옆에 상세 정보를 여는 데 씁니다.

</Card>
<Card component="drawer" props="side=top" title="top" height="340">

높이는 내용만큼입니다.

</Card>
<Card component="drawer" props="side=bottom" title="bottom" height="340">

휴대폰의 시트에 씁니다.

</Card>
</Cards>

### 레이아웃

- 좌우 서랍은 폭 400(`CoreDrawerStyle.defaultPanelWidth`)에 화면 전체 높이입니다.
- 상하 시트는 화면 전체 폭이고, 높이는 내용 높이만큼이며 화면을 넘지 않습니다. `ListView`처럼 남는 자리를 모두 차지하는 내용은 화면 높이까지 늘어납니다.
- 크기는 `panelWidth` · `panelHeight`로 바꿉니다. Flutter는 `openDrawer(drawerStyle:)`에 줘야 적용되고, 웹은 `Drawer(drawerStyle:)`에 줍니다.
- 머리 줄과 하단 영역은 자리를 지키고 그 사이가 내용입니다. 웹은 내용이 넘치면 내용이 스크롤됩니다(터치 화면의 좌우 서랍에는 [예외](#알려진-제약)가 있습니다). Flutter는 스스로 스크롤하지 않으므로 긴 내용은 `ListView`나 `SingleChildScrollView`로 감싸세요. Flutter의 상하 시트에서 내용이 짧을 때도 본문을 끌어 닫게 하려면 `SingleChildScrollView`가 낫습니다([고무줄](#고무줄)의 본문 스크롤 항목).
- 좁은 화면에서 Flutter 서랍은 화면 폭에 맞춰 줄어듭니다. 웹의 좌우 서랍은 폭 400 그대로라, 화면이 400보다 좁으면 한쪽이 잘립니다.

<a id="하단-시트-손잡이-설명-닫기-버튼"></a>

### 하단 시트

통화나 국가처럼 목록에서 하나를 고르는 시트는 아래에서 올라오고, 위쪽에 손잡이를, 제목 아래에 한 줄 설명을 둡니다. 닫기는 배리어와 끌기에 맡기고 × 버튼은 끕니다. 머리 줄 아래 구분선을 없애려면 두께 0을 줍니다. 같은 `dividerStyle`이 하단 영역 위의 구분선에도 쓰여서, `footer`가 있으면 그 선도 함께 없어집니다.

<Preview demo="drawer/sheet" height="340" />

<Code language="dart" title="Flutter · 웹 공통">
openDrawer<void>(
  context: context,
  side: CoreDrawerSide.bottom,
  builder: (_) => Drawer(
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
</Code>

- **모서리 28은 기본값이 아닙니다.** 기본은 16입니다. 앱 전체는 `CoreDrawerTheme(style: CoreDrawerStyle(panelBorderRadius: …))`로, 한 곳만이면 위처럼 `drawerStyle`로 바꿉니다.
- 손잡이의 크기, 색, 여백은 `CoreDrawerStyle`의 `dragHandle*` 필드로 바꿉니다. `Swiper`가 그리는 손잡이도 같은 필드를 씁니다.
- Flutter의 `Column`은 기본이 최대 높이라, 하단 시트의 내용으로 쓸 때는 `mainAxisSize: MainAxisSize.min`으로 둡니다. 그대로 두면 시트가 화면 높이까지 늘어납니다. 웹의 세로 flex는 처음부터 내용 크기입니다.
- 휴대폰의 하단 패널에는 [BottomSheet](/components/bottom-sheet)를 권장합니다. `BottomSheet`는 손잡이, 제목, 내용, 하단 바를 갖춘 면과 배치를 맡고, 열고 닫지는 않습니다. `Drawer`의 `side: bottom`도 그대로 쓸 수 있고, 열고 닫는 일까지 맡습니다.

<a id="하단-영역-확인-취소-버튼"></a>

### 하단 영역

옆 패널에서 입력을 받고 확정하는 흐름은 `footer`에 버튼 줄을 넘깁니다. 구분선 아래에 끝 쪽 정렬로 놓이고, 좌우 서랍에서는 내용이 남는 높이를 채워 하단이 패널 바닥에 붙습니다. 버튼 사이 간격은 직접 만드는 `Row`(Flutter)나 `div`(웹)에서 정합니다.

<Preview demo="drawer/footer" height="340" />

<Split>

<Code language="dart" title="Flutter">
openDrawer<void>(
  context: context,
  side: CoreDrawerSide.right,
  builder: (drawerContext) => Drawer(
    title: '프로필',
    description: '다른 사람에게 보이는 모습을 바꿔요.',
    content: TextField(label: '이름'),
    footer: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: CoreSpace.space8,
      children: [
        Button(
          variant: CoreButtonVariant.secondary,
          onPressed: () => closeDrawer<void>(drawerContext),
          child: const Text('취소'),
        ),
        Button(
          onPressed: () {
            save();
            closeDrawer<void>(drawerContext);
          },
          child: const Text('저장'),
        ),
      ],
    ),
  ),
);
</Code>

<Code language="dart" title="Jaspr Web">
openDrawer<void>(
  context: context,
  side: CoreDrawerSide.right,
  builder: (close) => Drawer(
    title: '프로필',
    description: '다른 사람에게 보이는 모습을 바꿔요.',
    content: const TextField(label: '이름'),
    footer: div(classes: 'flex gap-${CoreSpace.scale.space8}', [
      Button(
        variant: CoreButtonVariant.secondary,
        onPressed: close,
        child: const Text('취소'),
      ),
      Button(
        onPressed: () {
          save();
          close();
        },
        child: const Text('저장'),
      ),
    ]),
  ),
);
</Code>

</Split>

<a id="안전영역-채움-fillsafearea"></a>

### 안전 영역 채움

기본(`false`)에서 Flutter의 패널은 안전 영역 안쪽에 놓입니다. 하단 시트는 홈 인디케이터만큼 화면 바닥 위에 떠 있고, 그 아래 띠에는 배리어가 보입니다. 면이 화면 바닥까지 채워지고 내용만 안전 영역 위에 놓이게 하려면 `fillSafeArea: true`를 씁니다.

<Split>

<Code language="dart" title="Flutter">
openDrawer<void>(
  context: context,
  side: CoreDrawerSide.bottom,
  fillSafeArea: true,
  builder: (_) => Drawer(content: sheetBody),
);
</Code>

<Code language="dart" title="Jaspr Web">
openDrawer<void>(
  context: context,
  side: CoreDrawerSide.bottom,
  builder: (_) => Drawer(fillSafeArea: true, content: sheetBody),
);
</Code>

</Split>

- 패널이 붙은 **한 변에만** 적용합니다(`bottom` 시트는 아래, `left` 서랍은 왼쪽). 나머지 세 변은 Flutter에서는 안전 영역 안쪽에 남고, 웹에서는 아무 여백도 더하지 않습니다.
- Flutter는 그 변의 안전 영역을 건너뛰고, 건너뛴 만큼을 패널 안쪽 여백으로 받습니다. 내용 안의 `MediaQuery`에는 그 값이 0으로 보여서, 내용이 `SafeArea`를 두어도 두 번 밀리지 않습니다. `panelHeight` · `panelWidth`로 정한 크기는 늘어난 부분까지 포함한 전체 크기입니다.
- 웹의 패널은 원래 화면 가장자리에 붙고 안전 영역을 스스로 처리하지 않습니다. `true`면 붙은 변에 `env(safe-area-inset-*)`만큼 안쪽 여백을 더합니다. 페이지가 `viewport-fit=cover`를 쓰지 않으면 브라우저가 0으로 알려 아무것도 달라지지 않습니다.

### 접히는 화면

접힘선이 화면을 나누면(힌지가 가리거나 반쯤 접혔을 때) 서랍은 한 조각 안에 붙습니다. 자기 가장자리가 놓인 조각이고, 그 가장자리의 가운데가 접힘선이면 위쪽, 그다음 글이 시작하는 쪽 조각입니다(`Dialog`가 열리는 쪽). 책처럼 접은 화면의 하단 시트는 한쪽 면의 폭으로, 세워 둔 화면의 하단 시트는 아래 반쪽 높이 안에 열립니다. 배리어는 화면 전체를 덮습니다. 화면 일부를 채운 내비게이터에 열면(`useRootNavigator: false`) 그 내비게이터의 가장자리가 기준입니다. 접힘선이 화면을 나누지 않으면 크기와 자리는 그대로입니다. 자세한 범위는 [접히는 화면](/guides/layout#접히는-화면)을 보세요.

<a id="탭-셸에서-userootnavigator-false-flutter"></a>

### 탭 셸에서 열기

Flutter의 `openDrawer`는 기본으로 루트 `Navigator`에 라우트를 올리므로, 시트와 배리어가 루트가 그리는 모든 것을 덮습니다. 탭마다 `Navigator`를 두는 앱(`StatefulShellRoute` 류)은 하단 내비게이션 바가 탭 `Navigator` 바깥에 있는 경우가 많아, 루트에 올린 시트가 그 바까지 덮습니다. `useRootNavigator: false`는 시트를 **가장 가까운** `Navigator`(탭 본문)에 올립니다.

<Code language="dart" title="Flutter">
openDrawer<void>(
  context: context, // 탭 페이지 안의 컨텍스트
  side: CoreDrawerSide.bottom,
  useRootNavigator: false,
  transformBackdrop: false,
  builder: (_) => Drawer(content: sheetBody),
);
</Code>

- 배리어와 시트는 그 `Navigator` 영역에만 그려지고, 바깥(하단 바)은 덮이지 않아 계속 누를 수 있습니다.
- 시트는 그 `Navigator`의 라우트입니다. 시스템 뒤로 가기를 현재 탭 `Navigator` 기준(`canPop` · `maybePop`)으로 처리하는 앱이라면 뒤로 가기가 시트를 닫을 수 있고, 루트에 올린 시트는 그 방법으로는 닿지 않습니다. `closeDrawer`와 끌어 닫기는 어느 쪽이든 시트를 올린 `Navigator`에서 닫습니다.
- 가장 가까운 `Navigator`가 루트면 두 값은 같습니다.
- 뒤 화면 효과(`transformBackdrop`)는 앱 전체를 줄이는 것이라, 루트가 아닌 `Navigator`에 올린 서랍에는 적용하지 않습니다.
- 웹에는 대응하는 파라미터가 없습니다. 웹의 `openDrawer`는 부른 자리 위의 **가장 가까운** `OverlayHost`에 올립니다.

<a id="스타일-시스템-style-system"></a>
<a id="스타일-시스템-drawerstyle"></a>

## 테마와 스타일

패널의 겉모습, 배리어, 전환 시간, 안쪽 부품은 `drawerStyle`(`CoreDrawerStyle`) 하나로 바꿉니다. 붙는 가장자리와 동작(`barrierDismissible` · `draggable` · `dismissOnEscape` 등)은 파라미터로 줍니다.

<Split>

<Code language="dart" title="Flutter · 서랍 하나만 바꾸기">
const panelStyle = CoreDrawerStyle(
  panelBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
  panelWidth: CoreLayout.layout320,
  barrierOpacity: CoreOpacity.opacity50,
  openAnimationDuration: Duration(milliseconds: CoreDuration.moderate),
  closeAnimationDuration: Duration(milliseconds: CoreDuration.normal),
);

openDrawer<void>(
  context: context,
  side: CoreDrawerSide.right,
  drawerStyle: panelStyle,
  builder: (_) => Drawer(
    title: '설정',
    drawerStyle: panelStyle,
    content: settings,
  ),
);
</Code>

<Code language="dart" title="Jaspr Web · 서랍 하나만 바꾸기">
const panelStyle = CoreDrawerStyle(
  panelBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
  panelWidth: CoreLayout.layout320,
  barrierOpacity: CoreOpacity.opacity50,
  openAnimationDuration: Duration(milliseconds: CoreDuration.moderate),
  closeAnimationDuration: Duration(milliseconds: CoreDuration.normal),
);

openDrawer<void>(
  context: context,
  side: CoreDrawerSide.right,
  builder: (_) => Drawer(
    title: '설정',
    drawerStyle: panelStyle,
    content: settings,
  ),
);
</Code>

</Split>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    drawer: CoreDrawerTheme(
      style: CoreDrawerStyle(barrierOpacity: CoreOpacity.opacity40),
    ),
  ),
)
</Code>

- Flutter는 패널을 그리는 필드(색, 모서리, 여백, 글자, 구분선, 손잡이, 닫기 버튼, 그림자)를 `Drawer(drawerStyle:)`에서 읽고, 폭 · 높이 · 배리어 색과 불투명도 · 전환 시간 · 뒤 화면 효과의 크기와 모서리는 `openDrawer(drawerStyle:)`나 앱 테마에서 읽습니다. 두 종류를 함께 바꿀 때는 위처럼 같은 값을 두 곳에 줍니다. 웹의 `openDrawer`에는 `drawerStyle`이 없고 `Drawer(drawerStyle:)` 하나에서 모두 읽습니다.
- 테마에 `panelBorderRadius`를 주면 좌우 서랍의 안쪽 모서리도 함께 둥글어집니다.

### 뒤 화면 효과

`transformBackdrop`(기본 `true`)은 서랍이 열릴 때 뒤의 앱 화면을 `backdropScale`만큼 줄이고, 모서리를 `backdropCornerRadius`로 둥글립니다. 기본 스타일은 줄이지 않고(1.0) 모서리도 0이라 배리어만 보입니다. 앱 화면이 뒤로 물러나는 효과는 `CoreDrawerStyle.zoomBackdropScale`(0.95)과 `zoomBackdropCornerRadius`(24)를 주면 켜집니다. `Swiper`의 `drawer` variant가 이 값을 씁니다.

- Flutter는 `CoUIApp`이 앱 위에 마련한 자리가 있을 때만 적용합니다. 없으면 아무것도 하지 않고, `useRootNavigator: false`로 루트가 아닌 내비게이터에 연 서랍에도 적용하지 않습니다.
- 웹은 문서에서 처음 찾은 `data-coui-backdrop` 요소를 직접 바꿉니다. 서랍은 브라우저의 최상위 층(Popover API)에 올라가 그 요소의 변형을 따라가지 않습니다. Popover API를 지원하지 않는 브라우저에서 그 요소가 서랍을 감싸고 있으면 효과를 적용하지 않습니다.

### 밝기와 글자 단계

서랍은 연 자리가 아니라 서랍이 올라가는 자리의 밝기와 글자 단계로 그립니다. 기본은 앱의 가장 바깥이라, 한 부분만 밝기를 바꾼 영역 안에서 열어도 앱의 밝기입니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreDrawerStyle 기본값        // 디자인 시스템 (붙는 가장자리에 따라 다른 값 포함)
  → CoreDrawerTheme.style      // 앱 전체
  → drawerStyle                // 서랍 하나
```

뒤로 갈수록 우선하고, 필드마다 따로 합쳐집니다. 모서리와 테두리 두께의 기본값은 붙는 가장자리에 따라 다릅니다.

### 빠른 오버라이드 (Chain)

이미 만든 `Drawer`에 `withStyle`로 스타일을 덧붙일 수 있습니다. 생성자의 `drawerStyle`에 합치는 것과 같습니다. Flutter에서 `withStyle`은 패널을 그리는 필드에만 닿으므로, 폭 · 배리어 · 전환 시간은 `openDrawer(drawerStyle:)`에 따로 줍니다. 아래 예제의 `titleStyle`은 Flutter에서는 글자 역할까지 바뀌고, 웹에서는 색만 바뀝니다.

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

<a id="접근성-accessibility"></a>

## 접근성

### 역할

- **Flutter**: 패널을 `Semantics(container: true, label: title)`로 감쌉니다. 대화상자 역할은 붙지 않습니다. 라우트 배리어의 이름은 로케일의 '닫기'(`dismissLabel`)입니다.
- **웹**: 패널에 `role="dialog"`와 `aria-modal="true"`를, `title`이 있을 때만 `aria-label`을 붙입니다. 배리어에는 역할과 이름을 붙이지 않습니다. 역할 없는 `div`는 접근성 트리에 나타나지 않기 때문이며, 바깥을 누르거나 `Escape`로 닫는 것은 그대로입니다.

### 키보드

| 키 | 동작 |
|---|---|
| `Escape` | 서랍을 닫습니다. 웹은 `dismissOnEscape`(기본 `true`)를 따릅니다. Flutter는 `openDrawer(barrierDismissible:)`를 따르고 `dismissOnEscape`는 읽지 않습니다 |
| `Tab` · `Shift+Tab` | 초점이 서랍 안에 있으면 서랍 안의 요소 사이를 이동합니다. 초점을 서랍에 가두지는 않습니다([포커스 관리](#포커스-관리)) |
| `Enter` · `Space` | 초점이 있는 요소(× 버튼 포함)를 누릅니다 |

화살표 키 처리는 없습니다. 끌어 닫기는 포인터 전용입니다. Flutter에서 `barrierDismissible: false`로 열고 × 버튼도 끄면, 키보드로 닫을 수 있는 버튼을 `content`나 `footer`에 두세요.

### 스크린 리더

- 이름은 `title` 하나에서만 옵니다. `title`이 없으면 두 플랫폼 모두 패널에 이름이 없습니다. `description`만 있으면 머리 줄은 생기지만 이름이 되지는 않습니다.
- `description`은 머리 줄의 글자로 읽힙니다. 이름이나 `aria-describedby`로 패널에 연결하지 않습니다.
- × 버튼의 이름은 두 플랫폼 모두 로케일의 '닫기'(`buttonClose`)입니다.
- 뒤 화면: Flutter는 모달 라우트의 배리어가 뒤 라우트를 접근성 트리에서 가립니다. 웹은 서랍을 올린 오버레이 호스트가 감싼 앱 내용에 `inert`를 붙입니다.
- 열리고 닫힐 때 따로 알리는 라이브 영역은 없습니다.
- 손잡이는 읽지 않습니다(Flutter `ExcludeSemantics`, 웹 `aria-hidden`).

### 포커스 관리

- **Flutter**: 뒤 화면 효과를 쓰는 기본 구성(`CoUIApp`)에서는 패널이 라우트 바깥 자리에 그려지므로, 열 때 초점이 서랍 안으로 옮겨 가지 않을 수 있습니다. 라우트 안에 그리는 구성(`transformBackdrop: false` 등)에서는 라우트의 초점 범위가 패널을 감쌉니다. 닫히면 아래 라우트로 돌아갑니다. 어느 구성에서도 초점을 서랍 안에 가두지 않아서, `Tab`이 서랍 끝을 지나면 서랍 바깥으로 넘어갈 수 있습니다. 앱의 루트 내비게이터에 `transformBackdrop: false`로 연 서랍은 Flutter Web에서 Flutter 화면 밖으로 나갈 수도 있습니다.
- **웹**: 열 때 초점을 옮기지 않고, 닫을 때 되돌리지도 않으며, 패널 안에 초점을 가두지 않습니다. 뒤의 앱 내용은 `inert`라 `Tab`으로 닿지 않고, 마지막 요소에서 `Tab`을 누르면 브라우저 쪽으로 나갈 수 있습니다.

### 알려진 제약

- **기본 다크 테마(고대비 다크 포함)에서는 손잡이가 보이지 않습니다.** 손잡이 색 `surfaceContainer`와 패널 색 `surfaceBright`가 같은 값입니다. 라이트에서도 패널과의 대비가 1.09:1로 옅습니다. 손잡이 색은 `CoreDrawerStyle`의 `dragHandleColor`로 바꿉니다.
- **Flutter의 `Drawer`는 여는 옵션을 읽지 않습니다.** `barrierDismissible` · `draggable` · `dragDismissThreshold` · `rubberBand` · `transformBackdrop` · `fillSafeArea`는 `openDrawer`에 줘야 합니다. `dismissOnEscape`는 Flutter에 대응이 없고, `openDrawer(barrierDismissible:)`가 `Escape`를 정합니다.
- **Flutter의 `Drawer(drawerStyle:)`에 준 `panelWidth` · `panelHeight` · `barrierColor` · `barrierOpacity` · `backdropScale` · `backdropCornerRadius` · `openAnimationDuration` · `closeAnimationDuration`은 적용되지 않습니다.** `openDrawer(drawerStyle:)`나 앱 테마에 주세요.
- Flutter의 기본 구성에서는 초점이 패널 안에 있을 때 `Escape`로 닫히지 않을 수 있습니다. × 버튼이나 닫는 버튼을 두세요.
- Flutter의 기본 구성에서 패널 안의 `Navigator.of(context).pop()`은 서랍을 닫지 않고, 배리어만 남길 수 있습니다. 서랍은 `closeDrawer`로 닫으세요.
- Flutter의 기본 구성에서는 패널 안의 `ModalRoute.of(context)`가 서랍의 라우트가 아닙니다. 그래서 `routeSettings`의 값이 읽히지 않고, 패널 안에 둔 `PopScope`는 서랍을 닫는 뒤로 가기를 막지 못할 수 있습니다. 패널에 필요한 값은 `builder`에서 직접 넘기세요.
- Flutter의 기본 구성에서 서랍 안에서 연 대화상자가 떠 있을 때 Android 뒤로 가기를 누르면, 서랍까지 함께 닫힐 수 있습니다.
- Flutter 패널은 화면 키보드를 피하지 않습니다. 하단 시트의 입력창이 키보드에 가릴 수 있습니다.
- Flutter 패널에는 대화상자 역할이 없습니다.
- 웹은 서랍이나 대화상자가 겹쳐 있거나 서랍 안에서 팝오버(`Select`처럼 `Popover`를 쓰는 컴포넌트 포함)를 열었을 때, `Escape` 한 번에 함께 닫힐 수 있습니다. 각 패널이 문서의 키 입력을 따로 듣기 때문입니다.
- 오른쪽에서 왼쪽으로 읽는 로케일에서는 좌우 서랍의 손잡이가 화면 가운데 쪽이 아니라 서랍이 붙은 가장자리 쪽에 놓일 수 있습니다.
- **웹의 터치 화면에서 좌우 서랍은, 본문이 가로로 넘치지 않으면 세로로 넘쳐도 손가락으로 스크롤되지 않습니다.** 마우스 휠과 트랙패드는 해당하지 않습니다. 스크롤이 필요한 좌우 서랍은 `draggable: false`로 두면 이 문제를 피할 수 있습니다.
- 웹에서는 마우스로 글자를 끌어 고르거나 `Slider`를 끌 때, 닫히는 방향의 움직임이 패널을 함께 끌 수 있습니다. 버튼을 누를 때 손가락이 닫히는 방향으로 조금 움직여도 패널이 먼저 움직이고 버튼이 눌리지 않을 수 있습니다.
- 웹의 뒤 화면 효과(`transformBackdrop`, 기본 `true`)는 크기를 줄이지 않는 기본 스타일에서도 `data-coui-backdrop` 요소를 블록 상자로 바꾸고 `transform`과 `overflow: clip`을 겁니다. 그 사이에 앱의 배치가 달라지거나, 그 요소 안의 `position: fixed` 요소가 제자리에서 벗어날 수 있습니다. 필요 없으면 `transformBackdrop: false`로 끄세요.
- 웹의 좌우 서랍은 화면이 400보다 좁아도 폭 400이라 한쪽이 잘립니다. 좁은 화면에서는 `panelWidth`를 화면보다 좁게 주거나 하단 시트를 쓰세요.
- 웹의 `titleStyle`은 색(과 글꼴 종류)만 바뀌고, 글자 역할 · 크기 · 굵기는 바뀌지 않습니다. `dividerStyle`은 색과 두께만 적용하며 `CoreDividerTheme`은 읽지 않습니다.
- 웹의 `inert`는 서랍을 올린 오버레이 호스트가 감싼 내용에만 붙습니다. 호스트 바깥의 요소는 서랍 뒤에서도 초점을 받을 수 있습니다.
- `title`도 `description`도 없으면 머리 줄이 없어 이름과 × 버튼이 모두 사라집니다. 웹에는 이름을 따로 줄 파라미터가 없습니다. 이름이나 × 버튼이 필요하면 `title`을 주세요. 닫기 버튼만 필요하면 `content` 안에 직접 둘 수 있습니다.

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타겟)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

| 항목 | Flutter | Jaspr Web |
|---|---|---|
| `builder` | `WidgetBuilder`(컨텍스트를 받습니다) | `Drawer Function(close)`. 열 때 한 번만 부릅니다 |
| 열기 옵션을 주는 곳 | `openDrawer` | `Drawer` |
| 닫기 | `closeDrawer(context, result)` | `builder`가 받은 `close(result)` |
| `Future`가 완료되는 때 | 닫기를 시작할 때 | `close`로 닫으면 바로, 그 밖에는 `closeAnimationDuration`(기본 350ms)이 지난 뒤. 동작 줄이기에서도 같습니다 |
| `Drawer`를 트리에 직접 놓으면 | 패널을 그 자리에 그립니다(`side`를 따릅니다) | 아무것도 그리지 않습니다 |
| `Drawer(side:)` | 라우트 밖에서만 읽습니다 | 읽지 않습니다 |
| 올라가는 곳 | 기본은 루트 내비게이터의 라우트 | 가장 가까운 `OverlayHost`의 대화상자 층. 호스트가 없으면 `StateError` |
| 긴 내용 | 스크롤 위젯으로 직접 감쌉니다 | 내용이 스크롤됩니다(터치 화면의 좌우 서랍에는 [예외](#알려진-제약)) |
| 좁은 화면의 좌우 서랍 | 화면 폭에 맞춰 줄어듭니다 | 400 그대로입니다 |
| 닫는 전환 | ease-out-cubic을 거꾸로 | ease-out |
| 배리어 전환 | 기본 구성은 일정한 속도, 그 밖에는 `Curves.ease` | ease-out |
| 끌기 | 제스처 인식기 | 포인터 이벤트. 처음 움직일 때부터 패널이 따라갑니다 |
| 플릭 속도 | 인식기가 알려 주는 놓는 속도 | 포인터 이동의 최근 100ms |
| 본문 위 터치 끌기 | 스크롤 위젯이 가져가고(`controller`와 `physics` 없이 만든 세로 `ListView`는 넘치지 않아도), 아니면 패널이 끌립니다 | 밀려 나오는 방향으로 내용이 넘치지 않으면 패널이 끌립니다 |
| 고무줄 그리기 | 붙은 변을 기준으로 위젯을 늘립니다 | CSS `transform`과 `transform-origin`으로 늘립니다 |
| 고무줄 복귀 중 다시 잡기 | 지금 모습에서 이어서 | 지금 화면의 `transform`을 읽어 이어서 |
| 패널 밖으로 나간 포인터 | 인식기가 계속 따라갑니다 | 고무줄을 켠 서랍은 마우스가 배리어로 나가도 패널에 넘겨줍니다. 터치는 처음 누른 요소가 계속 받습니다 |
| 안전 영역 | 패널이 안전 영역 안쪽에 놓이고, `fillSafeArea`는 붙은 변까지 면을 채웁니다 | 패널은 화면 가장자리에 붙고, `fillSafeArea`는 안쪽 여백만 더합니다 |
| 한쪽에만 있는 인자 | `useRootNavigator` · `routeSettings` · `animationHandle` · `drawerStyle` 등 `openDrawer`의 옵션 | `scrubController` |
| 시스템 뒤로 가기 | 서랍을 닫습니다 | 브라우저 뒤로 가기는 서랍을 닫지 않습니다 |
| `Escape` | `barrierDismissible`을 따릅니다 | `dismissOnEscape`를 따릅니다 |

<a id="props-parameters"></a>

## API

### 위젯 파라미터

`W`는 Flutter의 `Widget`, 웹의 `Component`입니다.

| 이름 | 타입 | 기본값 | 설명 |
|---|---|---|---|
| `content` | `W` | 필수 | 패널의 내용 |
| `side` | `CoreDrawerSide` | `left` | 붙는 가장자리. 여는 서랍의 가장자리는 `openDrawer(side:)`가 정합니다 |
| `title` | `String?` | `null` | 제목이자 패널의 이름 |
| `description` | `String?` | `null` | 제목 아래 한 줄 설명. `title`이나 `description` 하나만 있어도 머리 줄이 생깁니다 |
| `footer` | `W?` | `null` | 내용 아래의 하단 영역 |
| `showDragHandle` | `bool` | `false` | 손잡이를 그립니다 |
| `showCloseButton` | `bool` | `true` | 머리 줄의 × 버튼 |
| `barrierDismissible` | `bool` | `true` | 배리어를 눌러 닫습니다(웹) |
| `draggable` | `bool` | `true` | 패널을 끌어 닫습니다(웹) |
| `dragDismissThreshold` | `double` | `0.5` | 패널 길이 대비 닫기 거리 비율(0~1, 웹) |
| `rubberBand` | `bool` | `false` | 열리는 방향의 끌기를 늘어남으로 받습니다(웹) |
| `dismissOnEscape` | `bool` | `true` | `Escape`로 닫습니다(웹) |
| `transformBackdrop` | `bool` | `true` | 뒤 화면 효과(웹) |
| `fillSafeArea` | `bool` | `false` | 붙은 변의 안전 영역만큼 안쪽 여백을 둡니다(웹) |
| `drawerStyle` | `CoreDrawerStyle?` | `null` | 겉모습, 배리어, 전환, 안쪽 부품의 스타일 |

<Note>

설명에 (웹)이라고 적은 값은 웹의 `Drawer`에서만 읽습니다. Flutter에서 같은 일을 하려면 `openDrawer`의 같은 이름 인자를 쓰세요(`dismissOnEscape`는 대응이 없습니다). 웹의 `Drawer`는 `id` · `classes` · `css` · `attributes`를 받지 않습니다. 두 플랫폼 모두 `copyWith`와 `withStyle`을 제공합니다.

</Note>

<a id="opendrawert"></a>

### 여는 함수 — `openDrawer`

`openDrawer<T>`는 `Future<T?>`를 돌려줍니다. 값과 함께 닫으면 그 값으로, 그 밖의 방법으로 닫으면 `null`로 완료됩니다. 웹은 위에 오버레이 호스트(`CoUIWeb`이나 `OverlayHost`)가 없으면 `StateError`로 실패합니다. 웹은 끌기, 고무줄, 뒤 화면 효과 같은 옵션과 `drawerStyle`을 `builder`가 만든 `Drawer`에서 읽습니다.

| 이름 | 타입 | 기본값 | 설명 |
|---|---|---|---|
| `context` | `BuildContext` | 필수 | Flutter는 내비게이터를, 웹은 가장 가까운 오버레이 호스트를 여기서 찾습니다 |
| `builder` | `WidgetBuilder`(Flutter) · `Drawer Function(close)`(웹) | 필수 | 패널을 만듭니다 |
| `side` | `CoreDrawerSide` | 필수 | 붙는 가장자리 |
| `barrierDismissible` | `bool` | `true` | Flutter 전용. 배리어 누르기와 `Escape` |
| `draggable` | `bool` | `true` | Flutter 전용. 끌어 닫기 |
| `dragDismissThreshold` | `double` | `0.5` | Flutter 전용. 닫기 거리 비율 |
| `rubberBand` | `bool` | `false` | Flutter 전용. 끌 수 없는 서랍에서는 아무 일도 하지 않습니다 |
| `transformBackdrop` | `bool` | `true` | Flutter 전용. 뒤 화면 효과 |
| `fillSafeArea` | `bool` | `false` | Flutter 전용. 안전 영역 채움 |
| `useRootNavigator` | `bool` | `true` | Flutter 전용. `false`면 가장 가까운 `Navigator`에 올립니다 |
| `routeSettings` | `RouteSettings?` | `null` | Flutter 전용. 라우트의 이름과 인자이며 `NavigatorObserver`가 읽습니다. 패널 안의 `ModalRoute.of(context)?.settings`는 서랍을 라우트 안에 그리는 구성(`transformBackdrop: false` 등)에서만 이 값입니다 |
| `animationHandle` | `DrawerAnimationHandle?` | `null` | Flutter 전용. 열림 정도를 밖에서 움직일 때 씁니다 |
| `drawerStyle` | `CoreDrawerStyle?` | `null` | Flutter 전용. 폭, 높이, 배리어, 전환 시간, 뒤 화면 효과를 정합니다 |
| `scrubController` | `DrawerScrubController?` | `null` | 웹 전용. 열림 정도를 밖에서 움직일 때 씁니다 |

<a id="closedrawertcontext-result-flutter"></a>

### 닫는 함수 — `closeDrawer` (Flutter)

```dart
void closeDrawer<T>(BuildContext context, [T? result])
```

두 인자는 모두 위치 인자입니다. `context`에는 패널 안의 컨텍스트를 넘깁니다. `result`는 선택이며, `openDrawer`의 `Future`가 이 값으로 완료됩니다.

패널 안의 컨텍스트로 부르면 서랍을 올린 내비게이터(루트이거나, `useRootNavigator: false`로 연 가까운 내비게이터)의 맨 위 라우트를 닫습니다. 패널 밖의 컨텍스트로 부르면 루트 내비게이터의 맨 위 라우트를 닫으므로, 서랍이 아닌 페이지가 닫힐 수 있습니다. 웹에는 `closeDrawer`가 없고 `builder`의 `close`를 씁니다.

### 밖에서 열림 정도 다루기

`DrawerAnimationHandle`(Flutter)과 `DrawerScrubController`(웹)는 서랍의 열림 정도를 밖에서 움직일 때 씁니다. 웹의 `Swiper`는 끄는 동안 `DrawerScrubController`로 서랍을 손가락만큼 끌어냅니다. Flutter의 `Swiper`는 끄는 동안 같은 모양의 패널을 라우트 없이 따로 그리고, 열기로 정해지면 `DrawerAnimationHandle`로 여는 전환을 건너뜁니다. Flutter의 `DrawerBackdropLayer`는 뒤 화면 효과를 받는 자리이며 `CoUIApp`이 마련합니다.

### 테마 — `CoreDrawerTheme`

| 이름 | 타입 | 기본값 | 설명 |
|---|---|---|---|
| `style` | `CoreDrawerStyle?` | `null` | 앱 전체의 서랍 스타일. `CoreComponentTheme(drawer: ...)`에 넣습니다 |

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

<Note>

위 표의 설명 가운데 지금 동작과 다른 것이 있습니다.

- `panelPadding`의 기본값은 위아래 20, 좌우 24입니다.
- `dividerStyle`은 머리 줄 아래와 하단 영역 위의 구분선에 함께 적용합니다. 웹은 색과 두께만 읽습니다.
- 웹의 `titleStyle`은 색(과 글꼴 종류)만 적용합니다.
- Flutter는 `panelWidth` · `panelHeight` · `barrierColor` · `barrierOpacity` · `backdropScale` · `backdropCornerRadius` · `openAnimationDuration` · `closeAnimationDuration`을 `Drawer(drawerStyle:)`가 아니라 `openDrawer(drawerStyle:)`나 앱 테마에서 읽습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="Dialog" href="/components/dialog" more="Dialog 보기">

화면 가운데에서 응답을 받는 대화상자입니다. 짧은 확인과 입력에 씁니다.

</Card>
<Card title="Swiper" href="/components/swiper" more="Swiper 보기">

감싼 영역을 밀면 가장자리에서 서랍이 나옵니다.

</Card>
<Card title="BottomSheet" href="/components/bottom-sheet" more="BottomSheet 보기">

휴대폰 하단 패널의 면과 배치를 맡습니다.

</Card>
</Cards>
