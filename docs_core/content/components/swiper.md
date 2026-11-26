---
title: Swiper
description: 스와이프 제스처로 가장자리에서 오버레이 패널을 여는 컴포넌트
category: overlay
platforms: [flutter, web]
related: [drawer, carousel]
tags: [swiper, swipe, gesture, overlay, drawer]
template: v2
source: overlay/swiper
---

# Swiper

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 열린 패널을 확인하고, 그림 아래의 영역을 밀거나 **메뉴 열기**를 눌러 같은 속성의 `Swiper`를 실제로 열어 보세요. 만들어진 코드는 그대로 복사할 수 있습니다. `isOpen`과 `setOpen`은 앱이 갖는 상태와 그것을 바꾸는 함수입니다.

<Playground component="swiper" />

`Swiper`는 `child`를 감싸고, 그 위에서 시작한 스와이프를 받습니다. `position`이 왼쪽이면 오른쪽으로 밀 때 왼쪽 가장자리에서 패널이 손가락을 따라 나옵니다(Flutter는 [CoUIApp](/guides/theming)이나 `CoUILayer` 아래에서). 놓을 때 패널의 절반 이상이 나와 있으면 열리고, 아니면 도로 들어갑니다. 패널은 [Drawer](/components/drawer)가 그려서, 슬라이드 · 배경막 · 끌어서 닫기를 그대로 씁니다.

<Note>

무대의 위쪽 그림은 작은 화면 안에 열린 패널을 놓은 그림입니다. Flutter는 `Drawer` 위젯을 그대로 놓고, Web은 `Drawer`가 패널에 쓰는 것과 같은 모양으로 그립니다. 그림의 좌우 패널은 폭을 160으로 줄였습니다(실제 기본값은 400). 앱 테마의 색 · 글자 · 밀도와 `CoreDrawerTheme`, 서페이스 스타일의 재질은 그림에 닿지만, `CoreSwiperTheme`의 값과 여닫는 전환은 없습니다. 그 아래의 영역은 실제 `Swiper`입니다. 이 사이트에서 실제로 열 수 있는 것은 플레이그라운드뿐이고, 다른 미리보기는 정적입니다. Web의 `drawer` variant는 패널을 올린 곳이 아니라 페이지에서 가장 먼저 나오는 `CoUIWeb`(또는 `OverlayHost`)의 앱 화면을 줄입니다. 그래서 이 사이트의 Jaspr Web 미리보기에서는 플레이그라운드 바깥 화면까지 줄어들 수 있습니다. **배경막 탭 닫기 끄기**를 켜면 패널 안의 닫기 버튼이나 패널을 끌어 닫습니다. Jaspr Web은 `Escape`로도 닫힙니다.

</Note>

## 구조

<Anatomy demo="swiper/anatomy">
<AnatomyItem select="[data-docs-part=child]" side="top" name="child">

감싼 위젯입니다. 그림에서는 안내와 여는 버튼이 든 카드입니다. `Swiper`가 제자리에 그리는 것은 이 위젯뿐이고, 스와이프는 이 위젯 위에서 시작해야 합니다. 그림에서 뒤 화면 전체가 줄어 있는 것은 `drawer` variant가 이 위젯만이 아니라 앱 화면 전체를 줄이기 때문입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=barrier]" side="top" name="barrier">

뒤 화면을 어둡게 덮는 배경막입니다. 색은 `scrim`의 30%이고, `barrierDismissible`이 `true`면 눌러서 닫습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=panel]" side="left" name="panel">

`Drawer` 패널입니다. 배경은 `surfaceBright`이고 그림자는 없습니다. 좌우 패널은 폭 400에 화면 높이를 채우며, 모서리가 각지고 안쪽 변에 1px `outlineVariant` 선이 있습니다. 위아래 패널은 내용의 높이를 따르고, 화면 안쪽의 두 모서리가 16이며 선이 없습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=handle]" side="left" name="handle">

손잡이입니다. 화면 가운데를 향한 변에 놓입니다. 아래 패널은 위, 위 패널은 아래, 좌우 패널은 안쪽 변입니다. 길이 48 · 두께 6의 `surfaceContainer` 알약이고 둘레 여백은 8입니다. `showDragHandle: false`면 그리지 않습니다. 기본 다크 테마에서는 패널과 같은 색이라 보이지 않습니다([알려진 제약](#알려진-제약)).

</AnatomyItem>
<AnatomyItem select="[data-docs-part=overlayContent]" side="top" name="overlayContent">

패널에 넣은 위젯입니다. 둘레 여백은 좌우 24, 위아래 20입니다.

</AnatomyItem>
</Anatomy>

<a id="변형-variants"></a>

## Variant

`variant`는 `drawer`(기본)와 `sheet` 둘입니다. 두 variant의 패널은 같은 `Drawer`이고, variant는 `Drawer`에 주는 값 몇 가지와 뒤 화면을 줄일지를 정합니다.

<a id="드로어-drawer"></a>
<a id="시트-sheet"></a>

<Cards columns="2">
<Card component="swiper" props="variant=drawer;position=bottom" title="drawer (기본)">

열리는 정도에 맞춰 뒤 화면이 95%까지 줄고 모서리가 24까지 둥글어집니다. 패널은 `Drawer`의 기본 모양입니다.

</Card>
<Card component="swiper" props="variant=sheet;position=bottom" title="sheet">

뒤 화면은 그대로입니다. 패널의 모서리 · 선 · 그림자를 모두 없앱니다.

</Card>
</Cards>

| 항목 | `drawer` | `sheet` |
| --- | --- | --- |
| 뒤 화면 | 95%로 줄고 모서리 24 | 그대로 |
| 좌우 패널 | 각진 모서리, 안쪽 변 1px 선 | 각진 모서리, 선 없음 |
| 위아래 패널 | 화면 안쪽 모서리 16, 선 없음 | 각진 모서리, 선 없음 |
| 그림자 | `Drawer` 기본값(없음) | 없음. `CoreDrawerTheme`이 그림자를 정해도 없앱니다 |

내비게이션 메뉴처럼 뒤 화면을 한 단 물러나게 보이려면 `drawer`를, 아래에서 올라오는 동작 시트처럼 뒤 화면을 그대로 두려면 `sheet`에 `position: bottom`을 씁니다. 내비게이션 메뉴에 `sheet`를 쓰면 뒤 화면이 줄지 않아, 패널이 앞에 떠 있다는 느낌이 약해집니다.

뒤 화면을 줄이는 효과에는 앱의 바탕이 필요합니다. Flutter는 [CoUIApp](/guides/theming)이나 `CoUILayer` 아래에서, Web은 `CoUIWeb`이나 `OverlayHost`가 만드는 앱 영역이 있을 때 나옵니다.

### 닫힌 모습

닫혀 있으면 두 variant는 같게 보입니다. `Swiper`가 그리는 것은 `child`뿐입니다. 아래 두 미리보기는 `child`에 위치 버튼과 여는 버튼을 둔 예제입니다.

<Cards columns="2">
<Card component="swiper" example="default" title="drawer, 닫힌 상태">

`drawer` variant의 예제입니다.

</Card>
<Card component="swiper" example="sheet" title="sheet, 닫힌 상태">

`sheet` variant의 예제입니다.

</Card>
</Cards>

<Note>

이 사이트에서 위 두 미리보기는 정적이라 버튼을 누르거나 밀어도 바뀌지 않습니다. 열어 보려면 플레이그라운드를 쓰세요.

</Note>

<a id="동작-스펙-behavior"></a>

## 상태

`Swiper`는 열림 상태를 스스로 갖고, `open`과 `onOpenChanged`로 앱의 값과 맞춥니다.

### 열림 값 맞추기

| 상황 | 동작 |
| --- | --- |
| `open`이 `false`에서 `true`로 바뀜 | 패널을 열고 `onOpenChanged(true)`를 부릅니다. |
| `open`이 `true`에서 `false`로 바뀜 | 패널을 닫습니다. `onOpenChanged`는 부르지 않습니다. |
| 처음 그릴 때부터 `open: true` | 열지 않습니다. `false`였다가 `true`로 바뀌어야 열립니다. |
| 스와이프로 엶 | `open` 값과 상관없이 열고, 열리기로 정해지면 `onOpenChanged(true)`를 부릅니다. |
| 사용자가 닫음 | 패널을 닫고 `onOpenChanged(false)`를 부릅니다. |

`onOpenChanged`에서 `open`에 넘기는 값을 갱신하세요. 그러지 않으면 사용자가 패널을 닫은 뒤에도 앱의 값이 `true`로 남아, 버튼이 `true`를 다시 넣어도 바뀐 것이 없어 열리지 않습니다.

<a id="인터랙션"></a>

### 스와이프로 열기

1. `child` 위 아무 곳에서나 누릅니다. 화면 가장자리에서 시작할 필요는 없습니다.
2. `position`의 축으로 18 이상 움직이고, 그 축으로 움직인 거리가 다른 축 이상이면 스와이프로 봅니다. Web은 여는 방향만 받습니다.
3. 패널이 곧바로 나타나 손가락을 따라 나옵니다. 열린 정도는 움직인 거리를 패널의 크기(좌우는 폭, 위아래는 높이)로 나눈 값입니다.
4. 놓을 때 열린 정도가 절반(0.5) 이상이면 끝까지 열리고, 아니면 도로 들어갑니다. 도로 들어가면 `onOpenChanged`를 부르지 않습니다.

여는 판정은 거리만 봅니다. 빠르게 튕겨도 절반에 못 미치면 열리지 않고, 천천히 당겨도 절반 이상이면 열립니다. 절반이라는 문턱은 바꿀 수 없습니다.

Flutter에서 `CoUIApp`이나 `CoUILayer` 아래가 아니면 패널이 손가락을 따라오지 않고, 스와이프로 보는 순간 바로 열립니다. 이때는 여는 방향을 따지지 않아, `position` 축의 어느 방향으로 밀어도 열립니다.

### 닫기

| 방법 | 조건 |
| --- | --- |
| 배경막 누르기 | `barrierDismissible: true`(기본) |
| 패널 끌기 | 따로 켜지 않아도 되고, 끌 수 없게 바꾸는 파라미터는 없습니다. 패널 크기의 절반 이상 끌거나, 패널이 숨는 쪽으로 초당 400px 이상으로 튕기면 닫힙니다. 패널 안의 스크롤되는 내용 위에서 끌면 스크롤이 먼저 움직일 수 있습니다. |
| `Escape` | Web은 늘, Flutter는 `barrierDismissible: true`일 때(`CoUIApp` · `CoUILayer` 아래의 `drawer` variant는 [키보드](#키보드)를 보세요) |
| Android 뒤로 가기 | Flutter. `barrierDismissible`과 상관없습니다. |
| `open: false` | 앱의 코드. `onOpenChanged`는 부르지 않습니다. |
| `closeDrawer(context)` | Flutter. 패널 안의 `context`로 부릅니다. |

`Swiper`의 패널에는 제목도 닫기(×) 버튼도 없습니다. 눈에 보이는 닫는 길이 필요하면 `overlayContent`에 버튼을 넣으세요.

### 패널 안에서 닫기

두 플랫폼에서 같게 동작하는 방법은 `open`을 `false`로 바꾸는 것입니다. 앱의 값이 `true`일 때만 바뀐 것이 생기므로, `onOpenChanged`로 값을 맞춰 두어야 합니다. Flutter에서는 패널 안의 `context`로 `closeDrawer`를 불러도 됩니다. Web에는 `closeDrawer`가 없습니다.

```dart
// Flutter · Web
Button(onPressed: () => setState(() => isOpen = false), child: Text('닫기'))

// Flutter 전용
Builder(
  builder: (context) => Button(
    onPressed: () => closeDrawer<void>(context),
    child: const Text('닫기'),
  ),
)
```

### 스와이프 끄기

`enabled: false`는 스와이프만 끕니다. `open`으로는 그대로 열고 닫을 수 있습니다. Web은 이때 감싼 영역의 `touch-action`을 `auto`로 되돌려, 그 위에서의 터치 스크롤이 브라우저 기본대로 움직입니다.

### 애니메이션

- 열고 닫는 전환은 `drawerStyle`의 `openAnimationDuration`과 `closeAnimationDuration`이며 둘 다 기본 350ms입니다. 열 때 패널은 두 플랫폼 모두 `ease-out`(`CoreEasing.enter`)으로 미끄러집니다. 닫을 때 Flutter는 `easeOutCubic` 곡선을 거꾸로 따라가 천천히 출발해 빨라지고, Web은 `ease-out`이라 빠르게 출발해 느려집니다.
- 배경막과 `drawer` variant의 뒤 화면 축소도 같은 시간에 맞춰 움직입니다.
- 배경막 · 끌기 · `Escape` · Android 뒤로 가기 · `open: false` · `closeDrawer` 가운데 어느 방법으로 닫아도 닫히는 전환이 재생됩니다.
- 스와이프하는 동안에는 전환 없이 손가락을 그대로 따라갑니다.
- Flutter의 `CoUIApp` · `CoUILayer` 아래에서는 스와이프를 놓은 뒤 남은 거리를 곡선 없이 일정한 속도로 움직입니다. 걸리는 시간은 전환 시간에 남은 거리의 비율을 곱한 만큼입니다. Web은 놓은 뒤에도 `ease-out` 전환을 씁니다.
- 동작 줄이기를 켜면 전환이 즉시 끝납니다. 다만 Web은 이때도 뒤 화면의 `inert`를 푸는 것과, 사용자가 닫았을 때의 `onOpenChanged(false)`가 닫힘 전환 시간(기본 350ms)이 지난 뒤입니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

화면의 한 영역을 밀어 메뉴나 선택 패널을 여는 제스처가 필요할 때 씁니다.

- 화면 전체를 감싸, 옆으로 밀면 내비게이션 메뉴가 나오게 할 때
- 아래쪽 영역을 위로 밀어 동작 시트를 열 때
- 같은 패널을 버튼과 스와이프 두 가지로 열고 싶을 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 버튼이나 코드로만 가장자리 패널을 여닫을 때 | [Drawer](/components/drawer) |
| 패널에 제목 · 닫기(×) 버튼 · 아래 버튼 줄이 필요하거나, 끌어서 닫기를 꺼야 할 때 | [Drawer](/components/drawer) |
| 밀어서 콘텐츠를 넘겨 볼 때 | [Carousel](/components/carousel) |
| 목록의 한 행을 밀어 그 행의 동작을 보일 때 | [SwipeActions](/components/swipe-actions) |
| 당겨서 새로 고칠 때 | [RefreshTrigger](/components/refresh-trigger) |
| 고른 값에 따라 본문을 바꿔 끼울 때 | [Switcher](/components/switcher) |
| 트리거 옆에 작은 패널을 띄울 때 | [Popover](/components/popover) |

<a id="do"></a>
<a id="dont"></a>

### 스와이프와 버튼을 함께

<Cards columns="2">
<Card demo="swiper/do-button" tone="do" eyebrow="이렇게 하세요">

같은 패널을 여는 버튼을 함께 둡니다. 버튼과 스와이프가 같은 `open` · `onOpenChanged` 값을 씁니다. 키보드와 스크린 리더로는 스와이프할 수 없습니다.

</Card>
<Card demo="swiper/dont-gesture-only" tone="dont" eyebrow="이렇게 하지 마세요">

여는 길이 스와이프뿐이면 키보드와 스크린 리더 사용자는 패널을 열 수 없고, 다른 사용자도 패널이 있는 줄 모를 수 있습니다.

</Card>
</Cards>

### 패널 안의 닫기

<Cards columns="2">
<Card demo="swiper/do-close" tone="do" eyebrow="이렇게 하세요">

패널에는 닫기 버튼이 저절로 생기지 않습니다. `overlayContent`에 닫는 버튼을 넣습니다.

</Card>
<Card demo="swiper/dont-no-close" tone="dont" eyebrow="이렇게 하지 마세요">

배경막 · 끌기 · `Escape`에만 기대면 닫는 길이 눈에 보이지 않습니다.

</Card>
</Cards>

### 열림 값 갱신

<Split>

<Code language="dart" title="이렇게 하세요">
Swiper(
  open: isOpen,
  onOpenChanged: (value) => setState(() => isOpen = value),
  overlayContent: const Text('설정'),
  child: const Text('오른쪽으로 밀어 보세요'),
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 사용자가 패널을 닫아도 isOpen 은 true 로 남습니다.
// 버튼이 true 를 다시 넣어도 값이 그대로라 열리지 않습니다.
Swiper(
  open: isOpen,
  overlayContent: const Text('설정'),
  child: const Text('오른쪽으로 밀어 보세요'),
)
</Code>

</Split>

## 배치

`position`은 패널이 나올 가장자리를 정합니다. 미는 방향은 그 반대입니다.

| `position` | 패널이 나오는 곳 | 미는 방향 |
| --- | --- | --- |
| `left`(기본) | 왼쪽 가장자리 | 오른쪽 |
| `right` | 오른쪽 가장자리 | 왼쪽 |
| `top` | 위 가장자리 | 아래 |
| `bottom` | 아래 가장자리 | 위 |

<Cards columns="2">
<Card component="swiper" props="position=left" title="left">

오른쪽으로 밀면 왼쪽에서 나옵니다.

</Card>
<Card component="swiper" props="position=right" title="right">

왼쪽으로 밀면 오른쪽에서 나옵니다.

</Card>
<Card component="swiper" props="position=top" title="top">

아래로 밀면 위에서 나옵니다.

</Card>
<Card component="swiper" props="position=bottom" title="bottom">

위로 밀면 아래에서 나옵니다.

</Card>
</Cards>

### 감싸는 영역

스와이프를 받는 곳은 `child`가 차지한 영역입니다. 화면 전체를 감싸면 화면 어디에서 밀어도 열리고, 막대 하나만 감싸면 그 막대 위에서만 열립니다.

### 패널의 크기

| 가장자리 | 크기 |
| --- | --- |
| 좌우 | 폭 400(`drawerStyle.panelWidth`), 높이는 화면 전체. Flutter는 화면 폭을 넘지 않고, Web은 400 그대로라 좁은 화면에서는 화면 밖으로 넘칠 수 있습니다. |
| 위아래 | 내용의 높이를 따르고 화면 높이를 넘지 않습니다. `drawerStyle.panelHeight`를 주면 그 높이로 고정합니다. |

Flutter는 패널을 시스템 안전 영역 안에 놓고, Web은 화면 가장자리에 붙입니다.

### 긴 내용

Web은 패널의 내용 영역이 스스로 스크롤합니다. 다만 터치 화면에서는 `left` · `right` 패널의 내용이 가로로 넘치지 않으면, 세로로 넘쳐도 손가락으로 스크롤되지 않습니다. 마우스 휠과 트랙패드는 해당하지 않습니다. `Swiper`에는 끌어서 닫기를 끄는 파라미터가 없으므로, 터치로 스크롤해야 하는 긴 내용은 `top`이나 `bottom` 패널에 두세요.

Flutter는 스크롤해 주지 않으므로, 패널보다 길 수 있는 `overlayContent`는 `SingleChildScrollView`나 `ListView`로 만듭니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

`Swiper`의 겉모습은 `swiperStyle`(`CoreSwiperStyle`) 하나로 바꿉니다. 패널의 모양 · 크기 · 배경막 · 전환 시간 · 손잡이는 모두 그 안의 `drawerStyle`(`CoreDrawerStyle`)이 정합니다. 낱개 `dragHandle*` 필드는 폐기 예정(0.161부터)입니다. 지우기 전까지는 계속 읽고, 같은 값을 `drawerStyle`에도 주면 `drawerStyle`이 이깁니다. 두 플랫폼이 같은 코드를 씁니다.

<Split>

<Code language="dart" title="Swiper 하나만 바꾸기">
Swiper(
  swiperStyle: CoreSwiperStyle(
    drawerStyle: CoreDrawerStyle(
      panelWidth: CoreLayout.layout320,
      barrierOpacity: CoreOpacity.opacity40,
    ),
  ),
  overlayContent: const Text('설정'),
  child: const Text('오른쪽으로 밀어 보세요'),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    swiper: CoreSwiperTheme(
      style: CoreSwiperStyle(
        drawerStyle: CoreDrawerStyle(panelWidth: CoreLayout.layout320),
      ),
      variantStyles: {
        CoreSwiperVariant.sheet: CoreSwiperStyle(
          drawerStyle: CoreDrawerStyle(
            dragHandleColor: CoreColor.token(CoreColors.outline),
          ),
        ),
      },
    ),
  ),
)
</Code>

</Split>

패널의 밝기와 제목 글자 단계는 `Swiper`가 놓인 자리가 아니라 패널이 올라가는 자리(Flutter는 루트 `Navigator`, Web은 가장 가까운 `OverlayHost`)를 따릅니다. `BrightnessScope`나 `TypographyTierScope` 안에 `Swiper`를 두어도, 패널은 그 범위 밖에서 그려질 수 있습니다. Flutter에서는 화면의 한 부분에만 둔 `Theme`의 `CoreSwiperTheme`도 패널 모양에 닿지 않을 수 있습니다. `swiperStyle`은 두 플랫폼 모두 패널에 닿습니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreDrawerStyle 기본값                           // 디자인 시스템
  → CoreDrawerTheme.style                        // 앱의 모든 Drawer
  → CoreSwiperStyle.defaultsByVariant[variant]   // variant 가 Drawer 에 주는 값
  → CoreSwiperTheme.style.drawerStyle            // 앱의 모든 Swiper
  → CoreSwiperTheme.variantStyles[variant].drawerStyle
  → swiperStyle.drawerStyle                      // Swiper 하나
```

뒤로 갈수록 우선하고, 필드마다 따로 합쳐집니다. variant의 값이 `CoreDrawerTheme`보다 뒤에 있으므로, `CoreDrawerTheme`에서 `drawer` variant의 `backdropScale` · `backdropCornerRadius`나 `sheet` 패널의 모서리 · 선 · 그림자를 바꿔도 `Swiper`에는 닿지 않습니다. 이 값은 `CoreSwiperTheme`이나 `swiperStyle`의 `drawerStyle`에서 바꿉니다.

### 빠른 오버라이드 (Chain)

이미 만든 `Swiper` 인스턴스에 스타일을 빠르게 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `swiperStyle`과 같게 동작하지만, 이미 구성된 위젯 위에서 바로 이어 쓸 수 있고, 겹치는 필드는 뒤에 붙인 값이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class SwiperChainExample extends StatefulWidget {
  const SwiperChainExample({super.key});

  @override
  State<SwiperChainExample> createState() => _SwiperChainExampleState();
}

class _SwiperChainExampleState extends State<SwiperChainExample> {
  CoreSwiperPosition _position = CoreSwiperPosition.left;
  bool _open = false;

  Widget _positionButton(CoreSwiperPosition position, String label) {
    return Button(
      variant: _position == position ? .primary : .outline,
      size: .sm,
      onPressed: () => setState(() => _position = position),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Swiper(
      position: _position,
      open: _open,
      onOpenChanged: (isOpen) => setState(() => _open = isOpen),
      // Centered like the shadcn demo via `mainAxisAlignment` —
      // alignment is caller-owned (the drawer never centers content
      // itself). On the full-height left / right sides the column is
      // forced tall so the alignment centers; on content-sized
      // top / bottom sides the column wraps and it is a no-op.
      overlayContent: Padding(
        padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
        child: Column(
          crossAxisAlignment: .start,
          mainAxisAlignment: .center,
          mainAxisSize: .min,
          spacing: Theme.of(context).geometry.space(CoreSpace.space8),
          children: [
            const Text('대시보드'),
            const Text('설정'),
            const Text('프로필'),
            Button(
              variant: .outline,
              size: .sm,
              onPressed: () => setState(() => _open = false),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
      // The whole preview area is the swipe surface (the gesture layer
      // covers the Swiper child) — the card just labels it.
      child: SizedBox(
        width: double.infinity,
        height: CoreSpace.space256,
        child: Center(
          child: Card(
            child: Padding(
              padding: const CoreEdgeInsets.all(CoreSpace.space24).toValue(geometry: Theme.of(context).geometry),
              child: Column(
                mainAxisSize: .min,
                children: [
                  const Text('밀어 보세요!').titleMedium.onSurface,
                  const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space12)),
                  Join(
                    children: [
                      _positionButton(CoreSwiperPosition.left, '왼쪽'),
                      _positionButton(CoreSwiperPosition.right, '오른쪽'),
                      _positionButton(CoreSwiperPosition.top, '위'),
                      _positionButton(CoreSwiperPosition.bottom, '아래'),
                    ],
                  ),
                  const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space12)),
                  Button(
                    onPressed: () => setState(() => _open = true),
                    child: const Text('스와이퍼 열기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).withStyle(
      const CoreSwiperStyle(
        drawerStyle: CoreDrawerStyle(
          dragHandleColor: CoreColor.token(CoreColors.primary),
          dragHandleWidth: CoreSize.size64,
          dragHandleThickness: CoreStrokeWidth.stroke6,
          dragHandleBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class SwiperChainExample extends StatefulComponent {
  const SwiperChainExample({super.key});

  @override
  State<SwiperChainExample> createState() => _SwiperChainExampleState();
}

class _SwiperChainExampleState extends State<SwiperChainExample> {
  CoreSwiperPosition _position = CoreSwiperPosition.left;
  bool _open = false;

  Component _positionButton(CoreSwiperPosition position, String label) {
    return Button(
      variant: _position == position ? .primary : .outline,
      size: .sm,
      onPressed: () => setState(() => _position = position),
      child: Text(label),
    );
  }

  @override
  Component build(BuildContext context) {
    return Swiper(
      position: _position,
      open: _open,
      onOpenChanged: (isOpen) => setState(() => _open = isOpen),
      // Centered like the shadcn demo via `justify-center` —
      // alignment is caller-owned (the drawer never centers content
      // itself). On the full-height left / right sides `h-full` gives
      // the column room so the content centers; on content-sized
      // top / bottom sides it resolves to auto and is a no-op.
      overlayContent: div(
        classes:
            'flex h-full flex-col items-start justify-center '
            'gap-${CoreSpace.scale.space8} p-${CoreSpace.scale.space16}',
        [
          const Text('대시보드'),
          const Text('설정'),
          const Text('프로필'),
          Button(
            variant: .outline,
            size: .sm,
            onPressed: () => setState(() => _open = false),
            child: const Text('닫기'),
          ),
        ],
      ),
      // The whole preview area is the swipe surface (the gesture layer
      // covers the Swiper child) — the card just labels it.
      child: div(
        classes: 'flex w-full items-center justify-center',
        styles: Styles(
          raw: {'min-height': 'var(--coui-space-${CoreSpace.space256.toInt()})'},
        ),
        [
          Card(
            child: div(
              classes:
                  'flex flex-col items-center gap-${CoreSpace.scale.space12} '
                  'p-${CoreSpace.scale.space24}',
              [
                const Text('밀어 보세요!').titleMedium.onSurface,
                Join(
                  children: [
                    _positionButton(CoreSwiperPosition.left, '왼쪽'),
                    _positionButton(CoreSwiperPosition.right, '오른쪽'),
                    _positionButton(CoreSwiperPosition.top, '위'),
                    _positionButton(CoreSwiperPosition.bottom, '아래'),
                  ],
                ),
                Button(
                  onPressed: () => setState(() => _open = true),
                  child: const Text('스와이퍼 열기'),
                ),
              ],
            ),
          ),
        ],
      ),
    ).withStyle(
      const CoreSwiperStyle(
        drawerStyle: CoreDrawerStyle(
          dragHandleColor: CoreColor.token(CoreColors.primary),
          dragHandleWidth: CoreSize.size64,
          dragHandleThickness: CoreStrokeWidth.stroke6,
          dragHandleBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        ),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreSwiperStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `drawerStyle` | `CoreDrawerStyle?` | Style of the `Drawer` the swiper opens — panel surface, barrier, slide durations, drag-dismiss threshold and so on. Merges on top of the variant's partial style from [defaultsByVariant]. |
| `dragHandleColor` | `CoreColor?` | **Deprecated (since 0.161)** — Use drawerStyle: CoreDrawerStyle(dragHandleColor: …) — the handle is drawn by the composed Drawer. Still read until removed. Drag-handle colour — folds in under [drawerStyle]'s `dragHandleColor`, which wins when both are stated. |
| `dragHandleWidth` | `double?` | **Deprecated (since 0.161)** — Use drawerStyle: CoreDrawerStyle(dragHandleWidth: …) — the handle is drawn by the composed Drawer. Still read until removed. Drag-handle length — folds in under [drawerStyle]'s `dragHandleWidth`. |
| `dragHandleThickness` | `double?` | **Deprecated (since 0.161)** — Use drawerStyle: CoreDrawerStyle(dragHandleThickness: …) — the handle is drawn by the composed Drawer. Still read until removed. Drag-handle thickness — folds in under [drawerStyle]'s `dragHandleThickness`. |
| `dragHandleInset` | `double?` | **Deprecated (since 0.161)** — Use drawerStyle: CoreDrawerStyle(dragHandleInset: …) — the handle is drawn by the composed Drawer. Still read until removed. Space around the handle — folds in under [drawerStyle]'s `dragHandleInset`. |
| `dragHandleBorderRadius` | `CoreBorderRadius?` | **Deprecated (since 0.161)** — Use drawerStyle: CoreDrawerStyle(dragHandleBorderRadius: …) — the handle is drawn by the composed Drawer. Still read until removed. Drag-handle corner — folds in under [drawerStyle]'s `dragHandleBorderRadius`. |

### `CoreSwiperStyle` 변형별 기본값 (`CoreDrawerStyle`)

| 필드 | `drawer` | `sheet` |
|------|------|------|
| `backdropScale` | zoomBackdropScale | — |
| `backdropCornerRadius` | zoomBackdropCornerRadius | — |
| `panelBorderRadius` | — | zero |
| `panelBorderWidth` | — | 0 |
| `panelBoxShadow` | — | [] |

<!-- STYLE_TABLE:END -->

<Note>

변형별 기본값 표의 `zoomBackdropScale`은 0.95, `zoomBackdropCornerRadius`는 24입니다. `—`는 variant가 값을 정하지 않아 `Drawer`의 값(`CoreDrawerTheme` 포함)을 쓴다는 뜻입니다.

필드 표의 `drawerStyle` 설명에는 drag-dismiss threshold(끌어서 닫는 문턱)가 있지만, `CoreDrawerStyle`에는 그런 필드가 없습니다. `Swiper` 패널의 문턱은 패널 크기의 절반(0.5)이고 바꿀 수 없습니다.

</Note>

<a id="접근성-accessibility"></a>

## 접근성

`Swiper`는 `child`를 감싸 스와이프만 받고, 패널의 접근성은 `Drawer`를 따릅니다.

### 역할

| 부분 | Flutter | Jaspr Web |
| --- | --- | --- |
| 감싼 영역 | `child`를 `Semantics(expanded:)`로 감싸 열림 · 닫힘 상태만 말합니다. 역할과 이름은 없습니다. | 바깥 `<div>`에 `data-swiper-*` 속성이 있습니다. 열려 있을 때만 `aria-expanded="true"`를 붙이고, 닫혀 있으면 속성이 없어 접힌 상태는 말하지 않습니다. 역할과 이름은 없습니다. |
| 패널 | `Semantics(container: true)`로 묶인 영역입니다. `dialog` 역할과 이름은 없습니다. | `role="dialog"`와 `aria-modal="true"`. 이름은 없습니다. |
| 배경막 | 라우트의 배경막입니다. `barrierDismissible: true`면 Android · iOS · macOS에서 로케일의 닫기 문구(`dismissLabel`)를 이름으로 줍니다. | 역할도 이름도 없습니다. |
| 손잡이 | `ExcludeSemantics`로 보조 기술에서 뺍니다. | `aria-hidden="true"` |

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| 스와이프로 열기 | 없음(포인터 전용) | 없음(터치 · 마우스 · 펜) |
| `Escape` | `barrierDismissible: true`일 때 닫습니다. `CoUIApp` · `CoUILayer` 아래의 `drawer` variant는 패널 안에 포커스가 있으면 닫히지 않을 수 있습니다. | `barrierDismissible`과 상관없이 닫습니다. |
| `Tab` · `Shift+Tab` | `sheet`는 패널 안에서만 돌도록 묶지 않고, 뒤 화면의 라우트는 `Tab` 순서에서 빠집니다. `CoUIApp` · `CoUILayer` 아래의 `drawer`는 `Tab`으로 패널에 들어가지 못할 수 있습니다. | 뒤의 앱이 `inert`라 그쪽으로는 가지 않습니다. 패널 안에서 순환하지는 않습니다. |

`Swiper` 자신은 키를 처리하지 않고, `Escape`만 따로 끄는 파라미터도 없습니다. Flutter는 `barrierDismissible: false`면 `Escape`도 함께 꺼집니다. Web은 `Drawer`의 `dismissOnEscape` 기본값(`true`)이 늘 적용됩니다. Flutter의 `Drawer`는 `dismissOnEscape`를 읽지 않습니다.

### 스크린 리더

- 감싼 영역에도 패널에도 접근 가능한 이름이 없습니다. `Swiper`에는 이름을 주는 파라미터가 없고, 이름이 될 `Drawer`의 `title`도 넘기지 않습니다.
- 열림과 닫힘을 따로 알리지 않습니다. 상태는 감싼 영역의 펼침 상태(Flutter `expanded`, Web `aria-expanded`)로만 말합니다. Web은 열린 상태만 말합니다.
- 패널이 열려 있는 동안 뒤 화면은 보조 기술에서 빠집니다. Flutter는 라우트의 배경막이, Web은 앱 영역의 `inert`가 막습니다.
- 스와이프는 보조 기술로 할 수 없습니다. 여는 버튼을 함께 두세요.

### 포커스 관리

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Swiper` 자신 | 포커스를 받지 않습니다. | 포커스를 받지 않습니다(`tabindex` 없음). |
| 열 때 | 라우트가 열리며 포커스를 자기 범위로 가져옵니다. `sheet`의 패널은 그 라우트 안에 있습니다. `CoUIApp` · `CoUILayer` 아래의 `drawer`는 패널이 라우트 밖에 그려져 포커스가 패널로 들어가지 않을 수 있습니다. | 포커스를 옮기지 않습니다. 뒤의 앱이 `inert`가 되어, 직전에 포커스가 있던 요소는 포커스를 잃을 수 있습니다. |
| 닫을 때 | 라우트가 닫히며 포커스가 이전 화면의 범위로 돌아갑니다. | 이전 요소로 포커스를 되돌리지 않습니다. |
| 가두기 | 패널 안에서만 돌도록 묶지 않습니다. | 뒤의 앱은 `inert`로 막지만 패널 안에서 순환하지는 않습니다. |

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 처음 그릴 때의 `open: true`는 패널을 열지 않습니다. 처음부터 열어야 하면 첫 프레임 뒤에 `false`를 `true`로 바꾸세요. |
| 공통 | 기본 다크 테마(고대비 다크 포함)에서는 손잡이 색(`surfaceContainer`)이 패널 색(`surfaceBright`)과 같아 손잡이가 보이지 않습니다. 라이트에서도 패널과의 대비가 1.09:1로 옅습니다. `swiperStyle`의 `drawerStyle`에 `dragHandleColor`를 주어 바꿀 수 있습니다. |
| 공통 | 패널의 제목 · 이름 · 닫기 버튼을 줄 파라미터가 없습니다. 끌어서 닫기(`draggable`), 닫는 문턱, `dismissOnEscape` 같은 `Drawer`의 동작도 바꿀 수 없습니다. |
| 공통 | 여는 제스처는 포인터 전용입니다. 키보드 · 스크린 리더 사용자를 위한 여는 버튼이 필요합니다. |
| 공통 | 열린 패널은 열 때 받은 `overlayContent`를 그립니다. 열린 동안 바깥에서 새로 넘긴 값은, Web에서는 반영되지 않고 Flutter에서도 반영되지 않을 수 있습니다. 패널 안에서 바뀌는 값은 `overlayContent` 안의 상태 있는 위젯이 갖게 하세요. |
| 공통 | 감싼 영역 안의 `Slider`처럼 끌기를 직접 처리하는 컨트롤을 같은 축으로 움직이면, 패널도 함께 따라 나올 수 있습니다. |
| Flutter | `CoUIApp`이나 `CoUILayer` 아래가 아니면 패널이 손가락을 따라 나오지 않고, `position` 축으로 18 이상 밀면 여는 방향이 아니어도 바로 열립니다. |
| Flutter | 다른 제스처와 겨루지 않고 포인터를 듣기만 합니다. 감싼 영역 안의 목록을 같은 축으로 스크롤해도 패널이 열릴 수 있습니다. |
| Flutter | `open: false`는 루트 `Navigator`의 맨 위 라우트를 닫습니다. 패널 위에 다른 라우트(루트에 띄운 대화상자 등)가 있으면 패널 대신 그것이 닫힙니다. |
| Flutter | 열린 채로 `Swiper`가 트리에서 빠져도 패널은 닫히지 않고 남습니다. |
| Flutter | 스와이프하는 도중에 `enabled`가 `false`가 되거나 `Swiper`가 트리에서 빠지면, 따라 나오던 패널이 남거나 디버그 빌드에서 오류가 날 수 있습니다. |
| Flutter | `CoUIApp` · `CoUILayer` 아래의 `drawer` variant는 패널을 별도의 `Navigator`에 담습니다. 패널 안의 `Navigator.of(context).pop()`은 서랍을 닫지 않고, 패널만 사라진 채 배경막이 남을 수 있습니다. `closeDrawer(context)`를 쓰세요. |
| Flutter | 손가락을 따라 나오는 동안의 패널은 앱의 `Navigator` 밖에 그려집니다. `overlayContent`가 그릴 때 `Navigator`나 `Overlay`를 찾으면 스와이프하는 동안 오류가 날 수 있습니다. |
| Flutter | 접히는 화면에서는 손가락을 따라 나오는 동안의 패널이 접히는 부분을 피하지 않습니다. 그래서 패널이 접히는 부분에 걸쳐 있다가, 열린 뒤에 한쪽 화면으로 옮겨질 수 있습니다. |
| Flutter | 화면의 한 부분에만 둔 `Theme`의 `CoreSwiperTheme`은 패널 모양에 닿지 않을 수 있습니다. 패널은 올라가는 자리의 테마를 읽습니다. |
| Jaspr Web | 터치 화면에서는 `left` · `right` 패널의 내용이 가로로 넘치지 않으면, 세로로 넘쳐도 손가락으로 스크롤되지 않습니다. 긴 내용은 `top` · `bottom` 패널에 두세요. |
| Jaspr Web | `aria-expanded`는 열림 상태를 따라가지 못할 수 있습니다. `open: false`로 닫으면 `true`가 남고, `onOpenChanged`를 주지 않으면 스와이프로 열어도 붙지 않을 수 있습니다. |
| Jaspr Web | 감싼 영역에서 시작한 터치로는 `position`의 축 방향(`left` · `right`는 가로, `top` · `bottom`은 세로)으로 바깥 페이지를 스크롤할 수 없습니다. 감싸는 바깥 상자는 블록이라 `child` 옆의 빈 자리도 마찬가지입니다. `enabled: false`면 풀립니다. |
| Jaspr Web | 마우스로 밀면 글자가 선택되거나 이미지 · 링크의 브라우저 끌기가 시작돼 스와이프가 끊길 수 있습니다. 감싼 위젯에 `select-none` 클래스를 주면 글자 선택을 막을 수 있습니다. |
| Jaspr Web | 열 때 포커스를 옮기지 않고 닫을 때 되돌리지 않습니다. `inert`는 패널을 올린 `OverlayHost`의 앱 영역에만 붙어, 그 바깥의 요소는 막히지 않습니다. |
| Jaspr Web | 패널 위에 대화상자나 다른 서랍이 떠 있으면 `Escape` 한 번에 함께 닫힐 수 있습니다. |
| Jaspr Web | `drawer` variant는 패널이 열려 있는 동안 줄이는 앱 화면 요소를 블록 상자로 바꾸고 `transform`과 `overflow: clip`을 겁니다. 그 사이에 앱의 배치가 달라지거나, 그 안의 `position: fixed` 요소가 제자리에서 벗어날 수 있습니다. |

패널 자체의 다른 제약은 [Drawer의 알려진 제약](/components/drawer#알려진-제약)도 보세요.

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타깃)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

파라미터 이름과 기본값은 같고, 제스처를 받는 방법과 패널을 올리는 방법은 각 플랫폼을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 위젯 타입 | `Widget` | `Component` |
| 필요한 바탕 | 위에 `Navigator`가 있어야 합니다. | `CoUIWeb`이나 `OverlayHost` 아래여야 합니다. |
| 제스처를 받는 방법 | 감싼 영역의 포인터 이벤트를 듣기만 합니다(`Listener`). | 감싼 영역의 `pointerdown` 뒤에 문서의 포인터 이벤트를 따라갑니다. 첫 번째 포인터만, 마우스는 왼쪽 버튼만 받습니다. 창이 포커스를 잃거나 탭이 가려지면 취소합니다. |
| 스와이프로 보는 방향 | `position` 축이면 방향을 가리지 않고 시작합니다. 여는 반대 방향은 열린 정도가 0에 머뭅니다. `CoUIApp` · `CoUILayer` 아래가 아니면 반대 방향으로도 열립니다. | 여는 방향만 받습니다. |
| 따라오는 거리 | 스와이프로 본 뒤에 움직인 거리 | 누른 자리부터 움직인 거리 |
| 패널을 올리는 곳 | 루트 `Navigator`의 `PopupRoute`. `CoUIApp` · `CoUILayer` 아래의 `drawer` variant는 패널을 앱 바탕의 별도 층에 그립니다. | 가장 가까운 `OverlayHost`의 대화상자 층. 브라우저 top layer에 올립니다. |
| `drawer`가 줄이는 뒤 화면 | `Swiper` 위의 `CoUIApp` · `CoUILayer`가 감싼 앱 화면 | 페이지에서 가장 먼저 나오는 `CoUIWeb` · `OverlayHost`의 앱 화면. 패널을 올린 `OverlayHost`가 아닐 수 있습니다. |
| 여닫는 전환 | `SlideTransition` | 패널의 CSS `transform` 전환 |
| 사용자가 닫을 때 `onOpenChanged(false)` | 닫기 시작할 때 | 닫히는 전환 시간이 지난 뒤 |
| 패널 안에서 닫기 | `closeDrawer(context)` 또는 `open: false` | `open: false` |
| `Escape` | `barrierDismissible`을 따릅니다. | 늘 닫습니다. |
| 긴 내용 | 스스로 스크롤하지 않습니다. | 내용 영역이 스크롤합니다. 터치 화면의 `left` · `right` 패널은 세로로만 넘치는 내용이 손가락으로 스크롤되지 않습니다. |
| 안전 영역 | 패널을 안전 영역 안에 놓습니다. | 화면 가장자리에 붙입니다. |
| 열린 채 트리에서 빠질 때 | 패널이 남습니다. | 패널을 닫습니다. |
| 감싸는 구조 | `child`의 크기 그대로입니다. | `child`를 `<div>` 두 겹으로 감쌉니다. 바깥 상자는 블록이고 `touch-action`을 갖습니다. |

<a id="props-parameters"></a>

## API

`W`는 Flutter의 `Widget`, Web의 `Component`입니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `W` | 필수 | 감싸는 위젯. 스와이프를 받는 영역입니다. |
| `overlayContent` | `W` | 필수 | 패널에 담는 내용 |
| `position` | `CoreSwiperPosition` | `left` | 패널이 나오는 가장자리. `left` · `right` · `top` · `bottom` |
| `variant` | `CoreSwiperVariant` | `drawer` | `drawer`는 뒤 화면을 줄이고 `Drawer` 모양을 씁니다. `sheet`는 뒤 화면을 두고 모서리 · 선 · 그림자를 없앱니다. |
| `open` | `bool` | `false` | 앱이 정하는 열림 값. 처음 값이 아니라 바뀔 때 반영합니다. |
| `onOpenChanged` | `void Function(bool)?` | `null` | 열리거나 사용자가 닫을 때 부릅니다. `open: false`로 닫을 때는 부르지 않습니다. |
| `enabled` | `bool` | `true` | 스와이프로 여는 제스처를 켭니다. `open`에는 영향이 없습니다. |
| `showDragHandle` | `bool` | `true` | 패널의 손잡이를 그립니다. |
| `barrierDismissible` | `bool` | `true` | 배경막을 눌러 닫습니다. Flutter는 `Escape`도 이 값을 따릅니다. |
| `swiperStyle` | `CoreSwiperStyle?` | `null` | 겉모습을 바꾸는 값. 패널의 값은 그 안의 `drawerStyle`에 줍니다. |

Web의 `Swiper`는 `id` · `classes` · `css` · `attributes` · `eventHandlers`와 `onClick` · `onKeyDown` 같은 이벤트도 받고, 감싸는 바깥 `<div>`에 붙입니다.

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreSwiperStyle patch)` | `swiperStyle`에 `patch`를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch`가 이깁니다. |
| `copyWith({key, child, ...})` | 바꾼 값으로 사본을 만듭니다. Web은 `classes` · `attributes` 같은 Web 파라미터도 받습니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.swiper` | `CoreSwiperTheme?` | 앱 전체의 `Swiper` 테마 |
| `style` | `CoreSwiperStyle?` | 모든 variant에 적용합니다. |
| `variantStyles` | `Map<CoreSwiperVariant, CoreSwiperStyle>?` | variant마다 덮어씁니다. `style`보다 우선합니다. |

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="Drawer" href="/components/drawer" more="Drawer 보기">

버튼이나 코드로 여는 가장자리 패널입니다. `Swiper`의 패널도 이것입니다.

</Card>
<Card title="Carousel" href="/components/carousel" more="Carousel 보기">

밀어서 슬라이드를 넘겨 봅니다.

</Card>
<Card title="SwipeActions" href="/components/swipe-actions" more="SwipeActions 보기">

목록의 한 행을 밀어 그 행의 동작을 꺼냅니다.

</Card>
</Cards>
