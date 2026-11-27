---
title: MockupFoldable
description: 접힘 각도를 조절할 수 있는 폴더블 기기 프레임 목업
category: display
platforms: [flutter, web]
related: [mockup-device, mockup, mockup-browser]
tags: [mockup, device, foldable, fold, presentation]
template: v2
source: display/mockup_foldable
---

# MockupFoldable

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

가운데가 접히는 기기를 그린 프레임 목업입니다. 접힘 각도 `foldAngle` 하나로 닫힘 · 반접힘 · 펼침과 그 사이의 모든 각도를 그리고, 각도가 바뀌면 기기가 3D 로 접히고 펴집니다. 펼치면 가로로 놓인 태블릿이고, 닫으면 접힌 반쪽의 뒷면에 폰 화면(커버 화면)이 나옵니다.

속성을 바꿔 보며 기기를 확인하고, 만들어진 코드를 그대로 복사하세요. 미리보기 화면의 글은 화면 안의 위젯이 읽은 [접힘](#접힘-읽기)이고, 코드의 `AppScreen` 은 화면에 놓을 여러분의 위젯입니다.

<Playground component="mockup-foldable" />

```dart
// 펼친 기기 — foldAngle 을 적지 않으면 180(펼침)입니다
MockupFoldable(
  child: Text('앱 화면').bodyMedium.onSurface,
)

// 책처럼 반쯤 연 기기
MockupFoldable(
  foldAngle: CoreMockupFold.halfOpen,
  child: Text('앱 화면').bodyMedium.onSurface,
)

// 닫힌 기기 — child 는 커버 화면에 놓입니다
MockupFoldable(
  foldAngle: CoreMockupFold.closed,
  child: Text('앱 화면').bodyMedium.onSurface,
)

// 각도를 바꾸면 기기가 그 각도로 접히고 펴집니다
MockupFoldable(
  foldAngle: _angle,
  child: Text('앱 화면').bodyMedium.onSurface,
)
```

## 구조

펼친 기기를 예로 든 부분입니다. 칠한 면이 `child` 가 받는 자리이고, 화면 오른쪽의 남은 열이 상태 아일랜드의 자리입니다.

<Anatomy demo="mockup-foldable/anatomy">
<AnatomyItem part="container" name="body">

펼친 본체입니다. 가로로 놓인 [`MockupDevice`](/components/mockup-device) 태블릿이고, 이 크기가 컴포넌트의 무대입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=content]" side="top" name="child">

켜진 화면에 놓이는 콘텐츠입니다. 상태 아일랜드의 열을 뺀 자리를 받습니다.

</AnatomyItem>
<AnatomyItem select="[aria-hidden=true] > span" side="top" name="clock">

상태 아일랜드의 시각입니다. 커버 화면에서는 이 위에 카메라가 하나 더 있습니다.

</AnatomyItem>
<AnatomyItem select="svg" side="right" name="status indicator">

상태 아일랜드의 상태 표시입니다. 와이파이 그림을 감싼 고리와 그 아래 점 넷입니다.

</AnatomyItem>
</Anatomy>

- 본체를 따로 그리지 않습니다. 펼친 본체와 커버는 두 `MockupDevice`(가로 태블릿과 폰)이고, 이 컴포넌트는 두 얼굴의 카메라 장식과 상태 표시줄을 끈 채 [상태 아일랜드](#상태-아일랜드)를 대신 그립니다.
- 커버는 왼쪽 반쪽의 뒷면입니다. 너비는 펼친 본체의 절반이고 높이는 같습니다. 경첩 쪽 모서리는 곧게, 바깥 모서리는 본체처럼 둥글게 그립니다.
- 접힌 동안에는 두 반쪽의 바깥 옆면(`thickness`)과, 비스듬히 돌아선 면을 덮는 그늘도 그립니다.
- Figma 라이브러리에는 이 컴포넌트의 페이지가 없습니다.

<a id="동작-스펙-behavior"></a>

## 상태

접힘에 따라 달라지는 모습은 모두 `foldAngle` 하나가 정합니다. 두 반쪽 사이의 각도(도)이고, 0 이 닫힘, 180 이 펼침입니다. 범위 밖 값은 가까운 끝으로 읽습니다. `-40` 은 0, `400` 은 180 입니다.

<Cards columns="2">
<Card component="mockup-foldable" props="foldAngle=180;width=240" title="180 — 펼침">

안쪽 화면이 한 장으로 놓입니다. 기본값입니다.

</Card>
<Card component="mockup-foldable" props="foldAngle=144;width=240" title="144 — 반접힘">

책처럼 반쯤 연 자세입니다. `child` 는 좌우 두 칸으로 읽습니다.

</Card>
<Card component="mockup-foldable" props="foldAngle=45;width=240" title="45 — 안쪽 화면이 어두워지는 구간">

안쪽 화면은 30 에서 60 사이에서 꺼지고 켜집니다. 45 에서는 그 중간입니다.

</Card>
<Card component="mockup-foldable" props="foldAngle=0;width=240" title="0 — 닫힘">

`child` 가 커버 화면에 놓입니다.

</Card>
</Cards>

각도의 이름과 경계는 `CoreMockupFold` 의 상수입니다.

| 상수 | 값 | 뜻 |
| --- | --- | --- |
| `CoreMockupFold.closed` | 0 | 닫힘 |
| `CoreMockupFold.coverLitUntil` | 10 | 이 각도까지 커버 화면이 다 켜져 있습니다 |
| `CoreMockupFold.coverUntil` | 30 | 이 각도까지 `child` 가 커버 화면에 놓입니다 |
| `CoreMockupFold.innerLitFrom` | 60 | 이 각도부터 안쪽 화면이 다 켜집니다 |
| `CoreMockupFold.halfOpen` | 144 | 책처럼 반쯤 연 자세 |
| `CoreMockupFold.flatFrom` | 150 | 이 각도부터 `child` 가 펼쳐진 접힘으로 읽습니다 |
| `CoreMockupFold.flat` | 180 | 펼침 |

### 상태 전환

| 각도 | `child` 가 놓이는 화면 | `child` 가 읽는 자세 | `child` 조작 |
| --- | --- | --- | --- |
| 180 | 안쪽 | 펼침(`flat`), 한 칸 | 됩니다 |
| 150 이상 180 미만 | 안쪽 | 펼침(`flat`), 한 칸 | 안 됩니다 |
| 30 초과 150 미만 | 안쪽 | 책(`book`), 좌우 두 칸 | 안 됩니다 |
| 0 이상 30 이하 | 커버 | 접힘 없음(`null`), 한 칸 | 됩니다 |

- 읽는 자세가 펼침으로 바뀌는 150 과 화면을 다시 조작할 수 있는 180 은 다릅니다. 그 사이의 화면은 아직 휘어 있어 조작할 수 없습니다.
- 커버 화면은 10 에서 30 으로 가며 어두워지고, 안쪽 화면은 30 에서 60 으로 가며 밝아집니다. 정확히 30 에서는 두 화면이 모두 꺼져 보입니다.
- 화면이 바뀌면 `child` 는 새 화면의 크기로 다시 놓이고, 상태는 유지됩니다.
- 컴포넌트의 무대는 어느 각도에서나 펼친 본체의 크기입니다. 닫힌 기기는 그 가운데에 서고, 접는 동안 보는 쪽으로 다가온 반쪽은 무대 밖으로 조금 나가 그려질 수 있습니다.

### 애니메이션

- `foldAngle` 이 바뀌면 지금 그려진 각도에서 새 각도까지 `CoreDuration.slow`(500ms) 동안 `CoreEasing.move` 곡선으로 움직입니다. 처음 그릴 때는 움직이지 않고 받은 각도에 서 있습니다.
- 움직이는 도중에 값이 다시 바뀌면 그 자리에서 새 각도로 향합니다.
- 길이와 곡선은 `mockupFoldableStyle` 의 `duration` · `curve` 로 바꿉니다. `Duration.zero` 면 각도를 그 자리에서 따라갑니다.
- 운영체제의 동작 줄이기가 켜져 있으면 500ms 이하의 움직임은 새 각도로 바로 바뀝니다. 기본 길이도 여기에 듭니다.
- 500ms 보다 긴 `duration` 은 이 컴포넌트가 줄이지 않습니다. 다만 Android 의 애니메이션 삭제처럼 Flutter 의 `disableAnimations` 를 켜는 설정에서는 Flutter 의 `AnimationController` 가 길이를 5% 로 줄이므로, 긴 움직임도 그만큼 짧아집니다.
- Web 에서 하이드레이트하지 않은 정적 마크업은 각도가 바뀌지 않습니다. 이 문서의 본문 미리보기가 그렇고, 움직임은 플레이그라운드에서 볼 수 있습니다.

### 인터랙션

- 프레임 자체는 입력을 받지 않습니다. 각도는 앱 코드가 `foldAngle` 로 정하고, 버튼이나 슬라이더 같은 컨트롤도 앱 코드가 따로 둡니다.
- `child` 의 컨트롤은 화면이 한 장으로 놓인 동안 동작합니다. 펼친 안쪽 화면(180)과 커버 화면(30 이하)입니다.
- 안쪽 화면이 휘어 있는 동안(30 초과 180 미만)에는 두 반쪽이 서로 다른 평면에 놓이므로 `child` 를 조작할 수 없는 그림으로 보입니다.
- 상태 아일랜드는 입력을 받지 않습니다.

## 접힘 읽기

화면에 놓인 위젯은 실제 폴더블 기기에서와 같은 호출 `FoldScope.of(context)` 로 접힘을 읽습니다. 두 플랫폼의 호출이 같습니다. 읽는 값은 목업 화면의 것이고, 목업을 놓은 페이지나 실제 기기의 접힘은 섞이지 않습니다.

<Preview demo="mockup-foldable/fold-reading" />

| 읽는 값 | 안쪽 화면, 150 이상 | 안쪽 화면, 150 미만 | 커버 화면 |
| --- | --- | --- | --- |
| `folds` | 화면 가운데를 세로로 지나는 접힘 하나(펼침) | 같은 자리의 접힘 하나(반쯤 접힘) | 없음 |
| `posture` | `CoreFoldPosture.flat` | `CoreFoldPosture.book` | `null` |
| `segments` | 화면 전체 한 칸 | 좌우 두 칸 | 화면 전체 한 칸 |
| `kind` (기본 화면 비율) | `CoreFoldableKind.fold` | `CoreFoldableKind.fold` | `null` |

- `context` 는 `MockupFoldable` 아래의 것이어야 합니다. 화면에 놓을 위젯을 따로 만들고 그 `build` 에서 읽으세요. 목업을 만드는 쪽의 `context` 로 읽으면 페이지의 접힘이 나옵니다.
- 칸의 좌표는 화면 전체를 기준으로 합니다. 오른쪽 칸에는 상태 아일랜드의 열이 들어 있으므로, 두 번째 칸의 너비를 그대로 쓰지 말고 남은 자리를 채우세요.
- Web 에서 목업의 칸 좌표는 루트 글자 크기 16px 을 기준으로 한 길이입니다. CSS 에 옮길 때는 아래 예처럼 `pinnedLengthCss` 로 `rem` 으로 바꾸세요. `px` 로 적으면 루트 글자 크기가 다른 환경에서 접힘 자리와 어긋납니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class AppScreen extends StatelessWidget {
  const AppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fold = FoldScope.of(context);
    if (!fold.isSplit) {
      return Center(child: Text('목록').bodyMedium.onSurface);
    }

    return Row(
      children: [
        // 첫 칸의 너비만큼 두면 두 번째 내용이 접힘 너머에서 시작합니다
        SizedBox(
          width: fold.segments.first.width,
          child: Center(child: Text('목록').bodyMedium.onSurface),
        ),
        Expanded(child: Center(child: Text('상세').bodyMedium.onSurface)),
      ],
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class AppScreen extends StatelessComponent {
  const AppScreen({super.key});

  @override
  Component build(BuildContext context) {
    final fold = FoldScope.of(context);
    if (!fold.isSplit) {
      return div(classes: 'flex h-full w-full items-center justify-center', [
        Text('목록').bodyMedium.onSurface,
      ]);
    }

    return div(classes: 'flex h-full w-full', [
      // 첫 칸의 너비만큼 두면 두 번째 내용이 접힘 너머에서 시작합니다
      div(
        classes: 'flex shrink-0 items-center justify-center',
        styles: Styles(raw: {'width': pinnedLengthCss(fold.segments.first.width)}),
        [Text('목록').bodyMedium.onSurface],
      ),
      div(classes: 'flex min-w-0 flex-1 items-center justify-center', [
        Text('상세').bodyMedium.onSurface,
      ]),
    ]);
  }
}
```

  </TabItem>
</Tabs>

## 상태 아일랜드

화면 위쪽을 가로지르는 상태 표시줄은 없습니다. 운영체제의 표시는 화면 오른쪽 끝의 세로 열인 상태 아일랜드에 놓입니다. 커버 화면에서는 맨 위가 카메라이고 그 아래에 시각과 상태 표시가 오며, 안쪽 화면에는 카메라 없이 시각과 상태 표시만 있습니다.

<Cards columns="2">
<Card component="mockup-foldable" props="foldAngle=0;width=240" title="기본">

커버 화면의 카메라, 시각, 상태 표시가 위에서 아래로 놓입니다.

</Card>
<Card component="mockup-foldable" props="foldAngle=0;width=240;showCamera=false" title="showCamera: false">

카메라가 빠지고 시각이 그 자리로 올라옵니다.

</Card>
<Card component="mockup-foldable" props="foldAngle=0;width=240;showStatus=false" title="showStatus: false">

시각과 상태 표시가 두 화면에서 빠집니다. 커버에는 카메라만 남고, 열도 그대로입니다.

</Card>
<Card component="mockup-foldable" props="foldAngle=0;width=240;showCamera=false;showStatus=false" title="둘 다 false">

열이 사라지고 `child` 가 그 자리까지 씁니다.

</Card>
</Cards>

안쪽 화면에는 카메라가 없으므로 `showStatus: false` 하나로 안쪽 화면의 열이 사라집니다. `showCamera` 는 커버 화면에만 닿습니다.

### 길이와 배율

- 길이 필드(`islandWidth` · `islandOffset` · `islandCameraSize`)는 iOS 포인트로 적습니다. 그 화면을 그리는 `MockupDevice` 가 운영체제의 길이를 그리는 배율로 그립니다.
- 기본 배율은 `CoreMockupFoldableStyle.defaultSystemScale`(0.478)입니다. 기본 너비의 안쪽 화면(458px)이 958 포인트짜리 화면을 나타내는 배율입니다.
- 본체의 `width` 를 바꿔도 아일랜드의 크기는 그대로입니다. 그래서 작은 기기일수록 열이 화면을 크게 차지합니다. 기본값에서 열은 약 46px 이고, 너비 240 의 커버 화면(104px)에서는 약 58px 가 `child` 의 자리로 남습니다.
- 열은 화면보다 넓어지지 않습니다.
- 배율은 안쪽 화면이 `innerDeviceStyle` 의 `landscapeSystemBarReferenceScale`, 커버 화면이 `coverDeviceStyle` 의 `systemBarReferenceScale` 입니다.

```dart
// 화면을 실제 크기(1 포인트 = 1px)로 보여줄 때는 두 얼굴의 배율을 1 로 적습니다
MockupFoldable(
  width: 980,
  mockupFoldableStyle: const CoreMockupFoldableStyle(
    innerDeviceStyle: CoreMockupDeviceStyle(
      landscapeSystemBarReferenceScale: 1,
    ),
    coverDeviceStyle: CoreMockupDeviceStyle(systemBarReferenceScale: 1),
  ),
  child: Text('앱 화면').bodyMedium.onSurface,
)
```

### 색과 글자

색과 글자는 `islandCameraColor` · `islandTextStyle` · `islandIconColor` · `islandDotColor` 로 바꿉니다. 기본값의 시각과 상태 표시는 `onSurface` 를 읽어 화면의 밝기를 따르고, 카메라는 어느 밝기에서나 같은 색입니다.

<Preview demo="mockup-foldable/island-style" />

```dart
MockupFoldable(
  foldAngle: CoreMockupFold.closed,
  width: 280,
  mockupFoldableStyle: const CoreMockupFoldableStyle(
    // 열을 넓히고 상태 표시의 고리 색을 바꿉니다 (점 넷은 islandDotColor)
    islandWidth: CoreSize.size112,
    islandIconColor: CoreColor.token(CoreColors.primary),
  ),
  child: AppScreen(),
)
```

- 시각의 문구(`9:41`), 상태 표시의 그림, 카메라 · 시각 · 상태 표시 사이의 간격은 견본이라 바꿀 수 없습니다.
- 열의 바탕은 화면의 바탕색입니다. `child` 가 자기 바탕색을 칠하면 열만 다른 색으로 남으므로, 그때는 두 얼굴의 `backgroundColor` 를 같은 색으로 적습니다.
- 오른쪽에서 왼쪽으로 읽는 앱에서도 열은 화면의 오른쪽에 있습니다.

```dart
MockupFoldable(
  mockupFoldableStyle: const CoreMockupFoldableStyle(
    innerDeviceStyle: CoreMockupDeviceStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
    coverDeviceStyle: CoreMockupDeviceStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  ),
  child: AppScreen(),
)
```

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 랜딩이나 문서에서 앱 화면을 폴더블 기기 안에 보여줄 때
- 앱이 접힘에 어떻게 반응하는지(커버 화면 · 반접힘 · 펼침)를 한 화면에서 시연할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 접히지 않는 폰 · 태블릿 프레임 | [MockupDevice](/components/mockup-device) |
| 브라우저 · 데스크톱 앱 창 프레임 | [MockupBrowser](/components/mockup-browser) |

<a id="do"></a>

### 슬라이더로 끌 때는 바로 따라가게

각도를 연속으로 바꾸는 컨트롤을 붙이면 `duration` 을 0 으로 둡니다. 기본 길이(500ms)로 두면 값이 바뀔 때마다 움직임이 새로 시작해 기기가 손가락을 뒤늦게 따라옵니다.

<Split>

<Code language="dart" title="이렇게 하세요">
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    MockupFoldable(
      foldAngle: _angle,
      mockupFoldableStyle: const CoreMockupFoldableStyle(
        duration: Duration.zero,
      ),
      child: AppScreen(),
    ),
    Slider(
      value: _angle,
      min: CoreMockupFold.closed,
      max: CoreMockupFold.flat,
      onChanged: (value) => setState(() => _angle = value),
    ),
  ],
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 끄는 동안 기기가 늘 한 발 늦습니다
MockupFoldable(
  foldAngle: _angle,
  child: AppScreen(),
)
</Code>

</Split>

첫 예의 `Column` 은 Flutter 코드입니다. Web 에서는 `Column` 자리에 세로로 쌓는 `div` 를 둡니다.

<a id="dont"></a>

### 조작은 펼치거나 닫은 상태에서

<Cards columns="2">
<Card demo="mockup-foldable/do-flat-controls" tone="do" eyebrow="이렇게 하세요">

눌러 보여야 하는 화면은 펼치거나(180) 닫은(`CoreMockupFold.closed`) 상태로 둡니다. 닫는 쪽은 10 을 넘으면 커버 화면이 어두워지고 30 에서는 검게 보입니다.

</Card>
<Card demo="mockup-foldable/dont-bent-controls" tone="dont" eyebrow="이렇게 하지 마세요">

반접힘에는 조작해야 하는 화면을 두지 않습니다. 버튼이 보여도 눌리지 않고, 가운데에 놓은 컨트롤은 접힌 자리에 걸칠 수 있습니다.

</Card>
</Cards>

### 화면에 넣는 내용

- 스크린샷처럼 가벼운 자식을 넣습니다. 이 컴포넌트는 실제 앱 UI 의 컨테이너가 아니라 문서 · 프레젠테이션 · 데모용입니다.
- 화면의 모서리는 둥글고 위쪽에 띠가 없습니다. 모서리에 바짝 붙인 내용은 잘리므로, `child` 에 안쪽 여백을 두거나 가운데에 놓습니다.

## 배치

### 너비와 높이

- `width` 는 펼친 본체의 너비(논리 px)입니다. 기본값은 `CoreMockupFoldableStyle.defaultWidth`(480)이고, 프로젝트 테마로는 바꿀 수 없습니다.
- 높이를 정하는 파라미터는 없습니다. 안쪽 화면의 비율(기본 433 : 299)과 본체의 레일 · 베젤 두께에서 나옵니다. 기본값에서 너비 480 의 높이는 약 338 입니다.
- 커버는 언제나 펼친 본체의 절반 너비에 같은 높이입니다.
- 옆면 두께(`thickness`)와 아일랜드의 크기는 `width` 를 따라 바뀌지 않습니다.

아래 둘은 기본 너비로 그린 반접힘과 닫힘입니다. 닫힌 기기도 펼친 본체와 같은 크기의 무대 가운데에 섭니다. 카드보다 넓은 부분은 잘려 보입니다.

<Cards columns="1">
<Card component="mockup-foldable" example="half-open" title="반접힘 · 기본 너비">

`foldAngle` 이 `CoreMockupFold.halfOpen` 인 기기입니다.

</Card>
<Card component="mockup-foldable" example="closed" title="닫힘 · 기본 너비">

`foldAngle` 이 `CoreMockupFold.closed` 인 기기입니다.

</Card>
</Cards>

### 부모보다 넓을 때

기기의 그림은 부모에 맞춰 줄어들지 않습니다. Flutter 는 부모가 더 좁으면 무대의 상자만 좁아지고, Web 은 부모가 flex 면 바깥 상자만 줄어들 수 있습니다. 두 경우 모두 그림은 `width` 크기 그대로라 자리 밖으로 넘칩니다. 좁은 화면에서도 보여야 하면 그 자리에 들어가는 `width` 를 정하세요.

### 차지하는 자리

- Flutter: 너비나 높이에 상한이 있는 자리에서는 그 방향으로 상한까지 차지하고, 기기를 위쪽 가운데에 둡니다. `Center` 안에서도 기기는 위에 붙습니다. `Column` 의 자식처럼 높이에 상한이 없는 자리에서는 높이가 기기만큼이므로, 세로 가운데에 두려면 `mainAxisSize: MainAxisSize.min` 인 `Column` 으로 감싼 것을 가운데에 놓습니다.
- Web: 펼친 본체 크기의 `inline-flex` 상자 하나를 차지합니다. 가운데에 두려면 부모에서 정렬합니다.

### 안전 영역

`child` 는 화면에서 상태 아일랜드의 열(오른쪽)을 뺀 자리에 놓입니다. `showGestureBar: true` 면 두 화면에 홈 제스처 바를 그리고 아래쪽의 그 자리도 비웁니다. 기본값은 `false` 입니다. [`MockupDevice`](/components/mockup-device)는 기본 마감에서 홈 제스처 바를 그리지만, 이 컴포넌트는 달라고 해야 그립니다.

Flutter 의 `child` 가 `MediaQuery` 로 읽는 크기는 열까지 포함한 화면 전체입니다. `child` 가 실제로 쓸 수 있는 폭이 필요하면 `LayoutBuilder` 로 읽습니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

내용 · 각도 · 크기처럼 무엇을 보여줄지는 위젯 파라미터로 넘기고, 겉모습과 움직임은 `mockupFoldableStyle`(`CoreMockupFoldableStyle`) 하나로 바꿉니다.

### 파라미터와 스타일

- **위젯 파라미터** — `child`, `foldAngle`, `width`, `showCamera`, `showStatus`, `showGestureBar`, `screenBrightness`
- **`mockupFoldableStyle`** — 두 얼굴의 겉모습(`innerDeviceStyle` · `coverDeviceStyle`), 옆면과 그늘(`thickness` · `edgeColor` · `shadeColor` · `shadeOpacity`), 꺼진 화면의 색(`screenOffColor`), 보는 거리(`perspective`), 상태 아일랜드(`island` 로 시작하는 필드), 움직임(`duration` · `curve`)

### `mockupFoldableStyle`

기기의 겉모습은 두 `MockupDevice` 의 것입니다. 펼친 본체는 `innerDeviceStyle`, 커버는 `coverDeviceStyle` 로 바꾸고, 두 값 모두 [`CoreMockupDeviceStyle`](/components/mockup#coremockupdevicestyle) 입니다. 커버의 크기는 고를 수 없습니다. `coverDeviceStyle` 에 화면 비율을 적어도 언제나 펼친 본체의 절반 너비에 같은 높이입니다.

```dart
MockupFoldable(
  mockupFoldableStyle: const CoreMockupFoldableStyle(
    // 반쪽을 더 두껍게, 더 가까이서 본 것처럼 보입니다
    thickness: CoreSize.size16,
    perspective: 2,
    // 커버의 베젤만 더 두껍게 합니다
    coverDeviceStyle: CoreMockupDeviceStyle(bezelWidth: CoreSpace.space8),
  ),
  child: Text('앱 화면').bodyMedium.onSurface,
)
```

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
CoreMockupFoldableStyle.defaultX        // 디자인 시스템 기본값
  → CoreMockupFoldableTheme.style       // 프로젝트 공통
  → mockupFoldableStyle                 // 기기 하나
```

- 테마와 인스턴스가 함께 적은 값은 필드마다 인스턴스가 이깁니다. `innerDeviceStyle` · `coverDeviceStyle` · `islandTextStyle` 은 안의 필드끼리 합치므로, 한 필드만 적어도 나머지가 남습니다.
- 합친 `innerDeviceStyle` 은 `defaultInnerDeviceStyle` 위에, `coverDeviceStyle` 은 `defaultCoverDeviceStyle` 위에 얹어 각 `MockupDevice` 의 `mockupDeviceStyle` 로 넘깁니다.
- 그래서 프로젝트의 `MockupDevice` 테마(`CoreMockupTheme` · `CoreMockupDeviceTheme`)는 이 컴포넌트가 직접 적지 않는 필드에만 닿습니다. 화면의 `backgroundColor` 가 그런 필드입니다.
- 이 컴포넌트가 직접 적는 필드는 테마가 같은 필드를 적어도 이 컴포넌트의 값이 남습니다. 두 얼굴의 몸체 · 테두리 색, 림 광택의 굵기, 모서리, 레일 · 베젤 두께, 화면 비율, 운영체제 길이의 배율과 버튼 설정(펼친 본체는 색 · 길이 · 자리, 커버는 길이 0), 커버의 안테나 띠 길이(0)가 그렇습니다. 이런 값은 `innerDeviceStyle` · `coverDeviceStyle` 로 바꿉니다. 커버의 화면 비율만은 바꿀 수 없습니다.
- 몸체의 그라디언트(`railGradient`)는 이 컴포넌트가 적지 않습니다. `MockupDevice` 테마에 적혀 있으면 몸체 색 대신 그 그라디언트가 그려집니다.
- `coverDeviceStyle.borderRadius` 를 비우면 커버의 바깥 모서리는 펼친 본체의 오른쪽 모서리를 따릅니다.

### 화면만 다른 밝기로

`screenBrightness` 는 두 화면과 그 위의 `child` · 시각 · 상태 표시 · 홈 제스처 바를 그 밝기로 그립니다. 본체 · 베젤 · 버튼은 페이지의 밝기를 따릅니다. 적지 않으면 화면도 페이지의 밝기입니다.

<Preview component="mockup-foldable" props="screenBrightness=dark;width=280" />

```dart
MockupFoldable(
  screenBrightness: CoreBrightness.dark,
  width: 280,
  child: AppScreen(),
)
```

### 사용 예

<Split>

<Code language="dart" title="기기 하나만 바꾸기">
MockupFoldable(
  foldAngle: CoreMockupFold.halfOpen,
  mockupFoldableStyle: const CoreMockupFoldableStyle(
    edgeColor: CoreColor.token(CoreColors.outline),
    shadeOpacity: CoreOpacity.opacity60,
    duration: Duration(milliseconds: CoreDuration.fast),
  ),
  child: AppScreen(),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    mockupFoldable: CoreMockupFoldableTheme(
      style: CoreMockupFoldableStyle(
        shadeOpacity: CoreOpacity.opacity60,
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다.

### 기본값이 있는 곳

기본값은 `coui_core` 의 `CoreMockupFoldableStyle` 에 있고 두 플랫폼이 같은 값을 읽습니다.

| 이름 | 값 | 설명 |
| --- | --- | --- |
| `CoreMockupFoldableStyle.defaultWidth` | 480 | 펼친 본체의 너비 |
| `CoreMockupFoldableStyle.defaultInnerDeviceStyle` | 회색 몸체, 모서리 36 | 위쪽 가장자리의 볼륨 버튼 둘과 오른쪽 가장자리의 전원 버튼. 모두 접히지 않는 반쪽에 있습니다 |
| `CoreMockupFoldableStyle.defaultCoverDeviceStyle` | 같은 회색 몸체 | 버튼과 안테나 띠가 없습니다 |
| `CoreMockupFoldableStyle.defaultSystemScale` | 0.478 | iOS 포인트를 논리 px 로 바꾸는 배율 |
| `CoreMockupFoldableStyle.defaultThickness` | 12 | 옆면 두께 |
| `CoreMockupFoldableStyle.defaultPerspective` | 2.5 | 보는 거리(펼친 본체 너비의 배수). 작을수록 다가온 반쪽의 깊이가 과장됩니다 |
| `CoreMockupFoldableStyle.defaultEdgeColor` | 몸체의 회색 | 옆면 색 |
| `CoreMockupFoldableStyle.defaultScreenOffColor` | 검정(베젤 색) | 꺼진 화면 |
| `CoreMockupFoldableStyle.defaultShadeColor` | 검정(베젤 색) | 돌아선 면의 그늘 |
| `CoreMockupFoldableStyle.defaultShadeOpacity` | 0.4 | 옆으로 선 면의 그늘 세기. 정면을 향한 면에는 그늘이 없습니다 |
| `CoreMockupFoldableStyle.defaultIslandWidth` | 96 (포인트) | 아일랜드 열의 너비 |
| `CoreMockupFoldableStyle.defaultIslandOffset` | 30 (포인트) | 화면 위에서 아일랜드가 시작하는 거리 |
| `CoreMockupFoldableStyle.defaultIslandCameraSize` | 36 (포인트) | 커버 카메라의 지름 |
| `CoreMockupFoldableStyle.defaultIslandCameraColor` | 검정 | 카메라 색 |
| `CoreMockupFoldableStyle.defaultIslandTextStyle` | `titleSmall`, `onSurface` | 시각의 글자 |
| `CoreMockupFoldableStyle.defaultIslandIconColor` | `onSurface` | 상태 표시의 고리와 그 안의 그림 |
| `CoreMockupFoldableStyle.defaultIslandDotColor` | `onSurface` 30% | 상태 표시의 점 넷 |
| `CoreMockupFoldableStyle.defaultDuration` | `CoreDuration.slow` (500ms) | 접는 움직임의 길이 |
| `CoreMockupFoldableStyle.defaultCurve` | `CoreEasing.move` | 접는 움직임의 곡선 |

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

이미 만든 `MockupFoldable` 에 `withStyle` 을 이어 스타일을 덧붙일 수 있습니다. `mockupFoldableStyle` 에 같은 값을 넘기는 것과 결과가 같고, 겹치는 필드는 나중에 이은 값이 이깁니다. 아래 예는 반쪽을 더 두껍게, 더 가까이서 본 것처럼, 그늘을 더 짙게 만듭니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class MockupFoldableChainExample extends StatelessWidget {
  const MockupFoldableChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MockupFoldable(
      foldAngle: CoreMockupFold.halfOpen,
      child: Center(child: Text('앱 화면').bodyMedium.onSurface),
    ).withStyle(
      // 반쪽을 더 두껍게, 더 가까이서 본 것처럼, 돌아선 반쪽의 그늘을 더 짙게
      const CoreMockupFoldableStyle(
        thickness: CoreSize.size16,
        perspective: 2,
        shadeOpacity: CoreOpacity.opacity60,
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class MockupFoldableChainExample extends StatelessComponent {
  const MockupFoldableChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return MockupFoldable(
      foldAngle: CoreMockupFold.halfOpen,
      child: div(
        classes: 'flex h-full w-full items-center justify-center',
        [Text('앱 화면').bodyMedium.onSurface],
      ),
    ).withStyle(
      // 반쪽을 더 두껍게, 더 가까이서 본 것처럼, 돌아선 반쪽의 그늘을 더 짙게
      const CoreMockupFoldableStyle(
        thickness: CoreSize.size16,
        perspective: 2,
        shadeOpacity: CoreOpacity.opacity60,
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

### 역할

기기를 그린 프레임이며, 컴포넌트가 역할이나 이름을 붙이지 않습니다. 운영체제의 역할도 흉내 내지 않습니다. 화면이 한 장으로 놓인 동안 안의 `child` 는 자기 시맨틱을 유지합니다. Web 의 바깥 상자는 컴포넌트가 `role` 을 붙이지 않은 `<div>` 입니다.

### 키보드

없음. 프레임이 처리하는 키가 없습니다. 각도를 바꾸는 컨트롤은 앱 코드가 두는 것이고, 키보드 동작은 그 컨트롤의 것입니다. 안쪽 화면이 휘어 있는 동안에는 `child` 의 컨트롤에 키보드로 갈 수 없습니다.

### 스크린 리더

| 상태 | `child` |
| --- | --- |
| 펼친 안쪽 화면(180) | 읽힙니다 |
| 휘어 있는 안쪽 화면(30 초과 180 미만) | 읽히지 않습니다 |
| 커버 화면(30 이하) | 읽힙니다 |

상태 아일랜드(카메라 · 시각 · 상태 표시)는 운영체제를 그린 그림이라 두 플랫폼 모두 보조 기술에서 숨깁니다. Flutter 는 시맨틱 트리에서 빼고, Web 은 `aria-hidden="true"` 를 붙입니다.

접힌 각도나 자세를 말로 알려주지 않습니다. 각도가 뜻을 가지면 목업 곁에 그 상태를 글로 적으세요.

### 포커스 관리

프레임은 포커스를 옮기거나 가두지 않습니다. 안쪽 화면이 휘어 있는 동안에는 `child` 가 포커스를 받지 않습니다. 화면에 보이는 것이 그림이라 포커스가 놓인 자리를 그릴 수 없기 때문입니다. Flutter 는 `ExcludeFocus` 로, Web 은 `inert` 로 막습니다. 접기 전에 `child` 안에 있던 포커스를 컴포넌트가 다시 펼친 뒤에 되돌려 놓지는 않습니다.

### 알려진 제약

- 안쪽 화면이 휘어 있는 동안에는 조작할 수 없고 보조 기술에도 드러나지 않습니다. 150 이상 180 미만처럼 `child` 가 펼침으로 읽는 구간도 그렇습니다. 그 상태로 오래 보여주는 화면이면 무엇이 그려져 있는지를 글로 함께 적으세요.
- 커버 화면이 어두워지는 구간(10 초과 30 이하)의 `child` 는 계속 커버에 놓여 있습니다. 정확히 30 에 멈추면 화면은 검게 보이지만 `child` 는 입력을 받고 보조 기술에도 읽힙니다. 닫힌 모습으로 멈출 때는 `CoreMockupFold.closed` 를 쓰세요.
- 기기 그림만으로 화면의 대체 텍스트가 생기지 않습니다. 기기 모양이나 스크린샷의 설명이 필요하면 따로 제공해야 합니다.
- 아일랜드의 시각과 상태 표시는 실제 시스템 상태가 아니라 고정된 견본입니다. 시각은 Flutter 에서 시스템의 글자 크기 설정을 따르지 않습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

위젯 파라미터와 각도의 규칙, 반쪽이 놓이는 자리의 계산은 두 플랫폼이 같습니다. 그리는 방법은 다음이 다릅니다.

| 항목 | Flutter | Web |
| --- | --- | --- |
| 반쪽의 자리 | 공통 계산이 낸 변환 행렬을 `Transform` 에 넘깁니다 | 같은 단계를 `rem` 길이의 CSS transform 함수로 적습니다. 루트 글자 크기를 따라갑니다 |
| 크기 배율 | 본체 · 옆면 · 아일랜드 상자에 테마의 크기 배율(`theme.scaling`)을 곱합니다. 시각의 글자에는 곱하지 않습니다 | `rem` 으로 그립니다 |
| 차지하는 자리 | 너비 · 높이의 상한까지 차지하고(상한이 없는 방향은 기기만큼) 기기를 위쪽 가운데에 둡니다 | 펼친 본체 크기의 `inline-flex` 상자입니다 |
| 휘어 있는 화면의 그림 | 펼친 본체를 이미지로 떠서 두 반쪽에 그립니다. `child` 가 다시 그려지면 이미지도 다시 뜹니다 | 펼친 본체를 반쪽마다 한 번씩 더 그립니다 |
| 휘어 있는 동안의 `child` | 원본의 입력 · 포커스 · 시맨틱을 막습니다 | 원본을 보이지 않게 두고 `inert` 로 막습니다. 두 사본은 `inert` 이고 `aria-hidden` 입니다 |
| 움직임 | `AnimationController` | 브라우저의 프레임마다 각도를 다시 계산합니다. 서버에서는 받은 각도를 그대로 그립니다 |
| 동작 줄이기의 근거 | Android 의 `disableAnimations`, iOS 의 동작 줄이기 | `prefers-reduced-motion` |
| `child` 가 읽는 접힘 | 목업 화면의 `MediaQuery` 에 접힘을 실어 `FoldScope.of` 가 읽습니다 | 목업이 `child` 를 감싼 범위를 `FoldScope.of` 가 읽습니다 |
| `child` 가 비우는 열 | 화면의 `MediaQuery` 에 오른쪽 여백으로 싣고 `SafeArea` 로 비웁니다. `child` 안의 `SafeArea` 가 같은 여백을 한 번 더 비우지 않습니다 | 콘텐츠 상자의 오른쪽 안쪽 여백으로 비웁니다 |
| 상태 표시의 그림 | 벡터 경로를 직접 그립니다 | 같은 경로를 인라인 SVG 로 그립니다 |
| 호스트 속성 | `key` | `id` · `classes` · `css` · `attributes` · `eventHandlers` · `key` |

### Flutter 에서 알아둘 것

- 휘어 있는 화면의 그림은 `child` 가 다시 그려질 때 갱신됩니다. 스크롤 뷰 안처럼 자기 다시 그리기 경계 안에서만 바뀌면 그 변화를 바로 알지 못합니다. 그런 변화는 접는 움직임이 끝날 때, 그리고 각도는 그대로인 채 이 컴포넌트가 다시 빌드될 때 반영됩니다.
- 웹뷰 · 지도 같은 플랫폼 뷰는 그 그림에 찍히지 않습니다.

### Web 에서 알아둘 것

- `child` 가 안쪽 화면에 있고 화면이 휘어 있으면 `child` 를 세 번 만듭니다. 보이지 않는 원본 하나와 반쪽마다 사본 하나입니다. 커버 화면에서는 하나만 만듭니다.
- 사본은 새로 만든 것이라, 상태를 가진 `child` 가 그동안 바꾼 값은 사본에 보이지 않고 처음 값으로 보입니다. 상태를 만들 때 시작하는 요청이나 타이머도 사본마다 다시 시작합니다.
- 문서에서 하나뿐이어야 하는 것(`GlobalKey`, 요소 `id`, 같은 이름의 라디오 묶음)을 가진 `child` 는 휘어 있는 상태로 쓰지 않습니다.
- Chrome 은 3D 로 돌린 큰 레이어를 낮은 해상도로 그릴 수 있습니다. 본체 너비가 약 800px 를 넘으면 휘어 있는 화면이 고해상도 디스플레이에서 조금 흐리게 보일 수 있습니다.
- `child` 의 레이아웃이 뷰포트 폭을 읽는 CSS 미디어 쿼리에 기대면, 화면이 커버로 바뀌어도 그 레이아웃은 바뀌지 않습니다. 화면 크기에 따라 달라져야 하는 레이아웃은 자기 상자의 폭을 읽게 하세요.

<a id="props-parameters"></a>

## API

### 생성자

두 플랫폼이 같은 이름을 씁니다. `W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다.

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `W` | 필수 | 켜진 화면에 놓이는 콘텐츠. 펼친 동안은 안쪽 화면, 거의 닫히면 커버 화면에 놓이고 화면이 바뀌어도 상태를 유지합니다 |
| `foldAngle` | `double` | `180` | 두 반쪽 사이의 각도(도). `CoreMockupFold.closed`(0) · `halfOpen`(144) · `flat`(180)과 그 사이의 값. 범위 밖 값은 가까운 끝으로 읽습니다 |
| `width` | `double?` | `null` → 480 | 펼친 본체의 너비(논리 px). 커버는 그 절반 너비이고, 어느 각도에서나 무대는 펼친 본체 크기입니다 |
| `showCamera` | `bool` | `true` | 커버 화면의 카메라. 커버의 상태 아일랜드 맨 위에 놓이는 둥근 구멍입니다. 안쪽 화면에는 카메라가 없습니다 |
| `showStatus` | `bool` | `true` | 두 화면의 시각과 상태 표시. 카메라도 함께 없는 화면에서는 열이 사라지고 `child` 가 그 자리까지 씁니다 |
| `showGestureBar` | `bool` | `false` | 두 화면의 홈 제스처 바와 그 아래쪽 안전 여백 |
| `screenBrightness` | `CoreBrightness?` | `null` → 페이지의 밝기 | 두 화면과 그 위의 콘텐츠를 그릴 밝기 |
| `mockupFoldableStyle` | `CoreMockupFoldableStyle?` | `null` | 접힘의 겉모습과 움직임을 바꾸는 값 묶음 |
| `key` | `Key?` | `null` | 위젯 · 컴포넌트의 키 |

### Web 전용

바깥 상자에 붙는 속성입니다.

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 바깥 상자의 `id` |
| `classes` | `String?` | `null` | 바깥 상자에 덧붙이는 CSS 클래스 |
| `css` | `Styles?` | `null` | 바깥 상자의 인라인 스타일. 컴포넌트의 크기 스타일 뒤에 합칩니다. 안의 그림은 따라 바뀌지 않으므로 크기는 `width` 로 정합니다 |
| `attributes` | `Map<String, String>?` | `null` | 바깥 상자의 HTML 속성 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 바깥 상자의 이벤트 처리 |

### 메서드

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreMockupFoldableStyle patch)` | `mockupFoldableStyle` 에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다 |
| `copyWith({...})` | 적은 값만 바꾼 사본을 만듭니다. 적지 않거나 `null` 로 넘긴 값은 지금 값이 남습니다. Web 의 `classes` 는 바꾸지 않고 덧붙입니다 |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.mockupFoldable` | `CoreMockupFoldableTheme?` | 앱 전체의 `MockupFoldable` 설정 |
| `CoreMockupFoldableTheme.style` | `CoreMockupFoldableStyle?` | 모든 기기에 먼저 적용하는 스타일 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreMockupFoldableStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `innerDeviceStyle` | `CoreMockupDeviceStyle?` | The look of the open body — the tablet the device is when unfolded. `null` leaves this device's own body: graphite, with rounder corners than the kit's tablet. |
| `coverDeviceStyle` | `CoreMockupDeviceStyle?` | The look of the cover — the phone on the back of the half that folds over. `null` leaves this device's own cover: graphite, with no buttons or antenna bands. |
| `thickness` | `double?` | How deep each half is, in logical px — the strip that shows when a half is seen edge on. `null` uses `CoreMockupFoldableStyle.defaultThickness`. |
| `perspective` | `double?` | How far away the device is seen from, in open-body widths. A smaller value exaggerates the depth of a half turned towards the viewer. `null` uses `CoreMockupFoldableStyle.defaultPerspective`. |
| `edgeColor` | `CoreColor?` | The colour of a half's outer edge. `null` uses `CoreMockupFoldableStyle.defaultEdgeColor`. |
| `screenOffColor` | `CoreColor?` | The colour of a screen that is off: the cover while the device is open, the inner screen while it is shut. `null` uses `CoreMockupFoldableStyle.defaultScreenOffColor`. |
| `shadeColor` | `CoreColor?` | The colour laid over a half that is turned away from the viewer. `null` uses `CoreMockupFoldableStyle.defaultShadeColor`. |
| `shadeOpacity` | `double?` | How strong the shade is over a half seen edge on, 0 to 1; a half facing the viewer has none. `null` uses `CoreMockupFoldableStyle.defaultShadeOpacity`. |
| `islandWidth` | `double?` | How wide the column at the screen's right edge is, in iOS points — the room the camera, the clock and the status indicator stand in, and the room the content keeps clear while any of them shows. `null` uses `CoreMockupFoldableStyle.defaultIslandWidth`. |
| `islandOffset` | `double?` | How far below the screen's top edge the island starts, in iOS points. `null` uses `CoreMockupFoldableStyle.defaultIslandOffset`. |
| `islandCameraSize` | `double?` | The diameter of the cover's camera, in iOS points. `null` uses `CoreMockupFoldableStyle.defaultIslandCameraSize`. |
| `islandCameraColor` | `CoreColor?` | The fill of the cover's camera. `null` uses `CoreMockupFoldableStyle.defaultIslandCameraColor`. |
| `islandTextStyle` | `CoreTextStyle?` | The text style of the island's clock — a role and a colour, set at its iOS size and drawn at the face's system scale. `null` uses `CoreMockupFoldableStyle.defaultIslandTextStyle`. |
| `islandIconColor` | `CoreColor?` | The colour of the status indicator's ring and the glyph inside it. `null` uses `CoreMockupFoldableStyle.defaultIslandIconColor`. |
| `islandDotColor` | `CoreColor?` | The colour of the four dots that close the status indicator's ring. `null` uses `CoreMockupFoldableStyle.defaultIslandDotColor`. |
| `duration` | `Duration?` | How long the device takes to reach a new fold angle. Zero follows the angle at once, which is what a slider driving it wants. `null` uses `CoreMockupFoldableStyle.defaultDuration`. |
| `curve` | `CoreCubicBezier?` | The easing of the move to a new fold angle. `null` uses `CoreMockupFoldableStyle.defaultCurve`. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="mockup-foldable/related-mockup-device" title="MockupDevice">

접히지 않는 폰 · 태블릿 프레임입니다. 이 컴포넌트의 두 얼굴이 이것입니다. [MockupDevice 보기](/components/mockup-device)

</Card>
<Card demo="mockup-foldable/related-mockup-browser" title="MockupBrowser">

브라우저 창과 데스크톱 앱 창 프레임입니다. 그림은 주소창을 뺀 앱 창입니다. [MockupBrowser 보기](/components/mockup-browser)

</Card>
<Card title="Mockup">

목업의 홈 제스처 바 · 안전 여백과 [`CoreMockupDeviceStyle` 의 필드](/components/mockup#coremockupdevicestyle)를 모아 설명합니다. [Mockup 보기](/components/mockup)

</Card>
</Cards>
