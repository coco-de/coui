---
title: Mockup
description: 브라우저 창, 폰 · 태블릿, 코드 블록 모양의 틀 안에 화면과 코드를 담아 보여 주는 목업 컴포넌트 모음입니다.
category: display
platforms: [flutter, web]
related: [mockup-browser, mockup-code, mockup-device, mockup-foldable, card, code-snippet]
tags: [mockup, device-frame, browser, presentation]
template: v2
source: display
---

# Mockup

<a id="live-preview"></a>

## 플레이그라운드

목업은 화면이나 코드를 실제 기기 · 창처럼 감싸는 틀입니다. 문서, 랜딩 페이지, 스크린샷 소개처럼 보여 주는 자리에 씁니다. 틀의 종류를 골라 보고, 만들어진 코드를 복사하세요.

<Playground component="mockup" />

미리보기의 폰과 태블릿은 `width` 를 줄여 그렸고, 코드에도 그 값이 들어 있습니다. 브라우저 창과 코드 틀은 부모의 폭을 채웁니다. 미리보기의 브라우저 창 높이는 바깥 상자가 정한 것이라, 코드만 옮기면 창의 높이는 `child` 를 따릅니다.

이 페이지는 `MockupBrowser` · `MockupDevice` · `MockupCode` 세 컴포넌트의 개요입니다. 기기 장식의 규칙, 세 컴포넌트의 스타일 필드, 값이 정해지는 순서, 옮겨 오기를 여기에서 함께 설명합니다. 접히는 기기를 그리는 `MockupFoldable` 은 자기 페이지가 있습니다.

| 컴포넌트 | 그리는 틀 | 자세한 문서 |
| --- | --- | --- |
| `MockupBrowser` | 창 컨트롤과 주소창이 있는 창. `addressBar: null` 이면 앱 창입니다. | [MockupBrowser](/components/mockup-browser) |
| `MockupDevice` | 폰 · 태블릿 기기 | [MockupDevice](/components/mockup-device) |
| `MockupCode` | 줄 번호를 둘 수 있는 코드 블록 | [MockupCode](/components/mockup-code) |
| `MockupFoldable` | 가운데가 접히는 기기 | [MockupFoldable](/components/mockup-foldable) |

<a id="변형-variants"></a>
<a id="기본-사용법-basic-usage"></a>

## 목업 종류

틀마다 컴포넌트가 따로 있고, 기기의 종류와 방향은 `MockupDevice` 의 속성으로 고릅니다. 데스크톱 앱 창은 별도 컴포넌트가 아니라 `MockupBrowser(addressBar: null)` 입니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
// 브라우저 목업
MockupBrowser(
  addressBar: 'https://example.com',
  child: Image.asset('assets/screenshots/dashboard.png'),
)

// 기기 목업 — 기본은 폰
MockupDevice(
  child: Image.asset('assets/screenshots/app_home.png'),
)

// 기기 목업 — 태블릿
MockupDevice(
  device: .tablet,
  child: Image.asset('assets/screenshots/app_home_tablet.png'),
)

// 코드 목업
MockupCode.fromString('flutter pub get\nflutter run')

// 앱 창 목업 — 주소창 없이 창 컨트롤만
MockupBrowser(
  addressBar: null,
  child: Text('앱 내용'),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
// 브라우저 목업
MockupBrowser(
  addressBar: 'https://example.com',
  child: img(src: 'screenshot.png', alt: '대시보드 화면'),
)

// 기기 목업 — 기본은 폰
MockupDevice(
  child: img(src: 'app-screenshot.png', alt: '앱 화면'),
)

// 기기 목업 — 태블릿
MockupDevice(
  device: .tablet,
  child: img(src: 'tablet-screenshot.png', alt: '태블릿 앱 화면'),
)

// 코드 목업
MockupCode.fromString(
  'npm i\ninstalling...\nDone!',
  showLineNumbers: true,
)

// 앱 창 목업 — 주소창 없이 창 컨트롤만
MockupBrowser(
  addressBar: null,
  child: Text('앱 내용'),
)
```

  </TabItem>
</Tabs>

### Browser

창 컨트롤 · 이전/다음 · 주소창 · 공유와 새 탭이 있는 웹 페이지 틀입니다. 콘텐츠 면이 창 전체를 채우고, 흐림 효과가 있는 반투명 툴바가 그 위에 겹칩니다. `child` 는 툴바 아래에서 시작합니다.

<Preview demo="mockup/browser" />

```dart
MockupBrowser(
  addressBar: 'example.com/docs',
  child: DashboardScreenshot(),
)
```

창 컨트롤과 아이콘은 그림이라 누를 수 없고, `addressBar` 는 입력창이 아니라 보여 주기만 하는 글입니다. 긴 주소는 한 줄로 두고 말줄임표로 줄입니다. 자세한 내용은 [MockupBrowser](/components/mockup-browser) 를 보세요.

### App

데스크톱 앱 창입니다. `MockupBrowser` 에 `addressBar: null` 을 넘기면 주소창 · 이전/다음 · 공유와 새 탭이 빠지고 창 컨트롤만 남습니다.

<Preview demo="mockup/app-window" />

```dart
MockupBrowser(
  addressBar: null,
  child: AppContent(),
)
```

창 컨트롤까지 없애려면 `showControls: false` 를 함께 넘깁니다. 둘 다 빼도 툴바의 자리는 남고, `child` 는 계속 그 아래에서 시작합니다.

### Phone · Tablet

`MockupDevice` 의 `device` 속성입니다. 기본 마감(`realistic`)은 레일 · 베젤 · 화면 · 카메라 · 하드웨어 버튼 · 상태 표시줄 · 홈 제스처 바를 갖춘 기기를 그립니다. 폰과 태블릿은 같은 규칙으로 그리고 화면 비율, 모서리, 베젤 두께, 카메라 위치, 버튼 배치, 안테나 띠, 상태 표시줄 구성이 다릅니다.

| `device` | 특징 |
| --- | --- |
| `phone` (기본) | 화면을 파낸 알약 모양 카메라와 안테나 띠 여섯 개 |
| `tablet` | 화면 위 베젤 띠 안의 작은 카메라. 안테나 띠가 없습니다. |

<Preview component="mockup" example="phone" />

<Preview component="mockup" example="tablet" />

```dart
MockupDevice(
  child: MobileAppPreview(),
)

MockupDevice(
  device: .tablet,
  child: TabletAppPreview(),
)
```

기기 그림 대신 장식 없는 미리보기 틀이 필요하면 `finish: .flat` 을 씁니다. 이 마감은 카메라 · 상태 표시줄 · 홈 제스처 바가 기본으로 꺼집니다. `screenBrightness` 는 페이지의 밝기와 상관없이 화면만 밝게 또는 어둡게 그립니다. 두 속성의 자세한 동작은 [MockupDevice](/components/mockup-device), 접히는 기기는 [MockupFoldable](/components/mockup-foldable) 을 보세요.

### Portrait · Landscape

`orientation` 속성입니다. 어떤 기기인지(`device`)와 어느 방향으로 들었는지는 따로 정합니다.

<Preview component="mockup" example="landscape" />

```dart
MockupDevice(
  orientation: .landscape,
  child: PhoneLandscapePreview(),
)

MockupDevice(
  device: .tablet,
  orientation: .landscape,
  child: TabletAppPreview(),
)
```

돌린 몸체는 **버튼도 함께 옮깁니다**. 가로는 세워 든 자세를 시계 방향으로 90° 돌린 것이라, 버튼이 붙는 변은 따로 정하지 않고 저절로 정해집니다. 태블릿은 볼륨 버튼이 왼쪽에서 위로, 전원 버튼이 위에서 오른쪽으로 갑니다. 폰은 볼륨 버튼이 왼쪽에서 위로, 전원 버튼이 오른쪽에서 아래로 갑니다. 안테나 띠도 재는 끝과 거리는 그대로 두고 변만 시계 방향으로 한 칸 옮겨 갑니다.

변을 따라 **얼마나 들어간 자리**인지와 버튼이 **얼마나 긴지**는 `landscape*` 필드(`landscapePowerButtonLength` · `landscapePowerButtonOffset` 등)가 따로 정합니다. 디자인에서 가로 자세의 자리를 따로 잡았기 때문입니다.

돌린 자세는 하드웨어 말고도 달라집니다. 아래 표는 기본 마감 기준이고, 홈 제스처 바의 값은 iOS point 입니다.

| 항목 | 폰 | 태블릿 |
| --- | --- | --- |
| 카메라 | 화면의 **왼쪽 가장자리**에 선 세로 알약, 렌즈는 위쪽 끝 | 위쪽 베젤 띠 가운데 (그대로) |
| 상태 표시줄 | 없음 (`showStatusBar` 를 켜도 같습니다) | 있음 — 높이는 세로와 같습니다 |
| 안전 여백 | 왼쪽에 카메라 몫, 위쪽은 `0` | 위쪽에 상태 표시줄 몫 (세로와 같습니다) |
| 홈 제스처 바 | 막대 폭 `209`, 영역 높이 `21` | 막대 폭 `314`, 영역 높이 `20` (세로와 같습니다) |

화면 비율(`screenAspectWidth` · `screenAspectHeight`)은 **긴 변을 먼저** 읽는 비율일 뿐이고 방향을 정하지 않습니다. 어느 쪽이 길어지는지는 `orientation` 하나가 정합니다.

### Code

코드 편집기 모양의 틀입니다. `MockupCode.fromString` 은 문자열을 줄 바꿈으로 나누고, `showLineNumbers`(기본 `true`)가 켜져 있으면 1부터 줄 번호를 붙입니다. 구문 강조 · 복사 · 편집 기능은 없습니다. 틀보다 긴 줄은 줄을 바꾸지 않고 잘립니다.

<Preview demo="mockup/code" />

```dart
MockupCode.fromString(
  'flutter pub get\nflutter test\nflutter build web',
  showLineNumbers: true,
)
```

<Note>

Web 은 줄 앞의 공백(들여쓰기)과 이어진 공백이 합쳐져 보입니다. Flutter 는 공백을 그대로 그립니다.

</Note>

줄마다 뜻(명령 · 경로 · 성공 · 실패 등)을 정하는 방법은 [MockupCode](/components/mockup-code) 를 보세요.

## 기기 장식과 안전 영역

이 절은 `MockupDevice` 의 기본 마감(`realistic`)을 설명합니다.

### 카메라·상태 표시줄·홈 제스처 바 표시

Flutter 와 Web 모두 `showCamera` · `showStatusBar` · `showGestureBar` 로 각각 켜고 끕니다. 적지 않으면(`null`) 마감을 따릅니다. `realistic` 은 셋 다 그리고 `flat` 은 셋 다 그리지 않으며, 폰과 태블릿에 똑같이 적용됩니다. 직접 적은 값은 마감과 상관없이 그대로 씁니다.

- `showCamera: false` 는 컷아웃 · 렌즈 · 코어 · 반짝임을 모두 숨깁니다.
- `showStatusBar: false` 는 화면 위쪽의 시계 · 신호 · Wi-Fi · 배터리 줄을 숨깁니다.
- `showGestureBar: false` 는 화면 아래쪽의 홈 제스처 바를 숨깁니다.

세 옵션은 서로 독립이고, 각각 **장식과 그 장식이 비워 두던 안전 여백**을 함께 다룹니다. 본체와 화면의 크기는 그대로입니다. `copyWith` 나 스타일 체인을 써도 정한 표시 여부가 유지됩니다.

<Preview demo="mockup/decorations" />

```dart
MockupDevice(
  showCamera: false,
  showStatusBar: false,
  showGestureBar: false,
  child: Text('앱 화면'),
)
```

가로로 돌린 폰(`phone` + `orientation: .landscape`)은 상태 표시줄을 그리지 않습니다. 실제 기기가 그 자세에서 숨기기 때문이며, `showStatusBar` 를 켜도 달라지지 않습니다. 태블릿은 두 방향 모두 상태 표시줄을 그립니다.

Figma 에서는 `❖ MockupDevice` 인스턴스의 **Show camera** · **Show status bar** · **Show gesture bar** BOOLEAN 속성으로 조절합니다. **Show status bar** 는 상태 표시줄이 있는 변형(폰 세로, 태블릿 두 방향)에만 연결됩니다. 폰 가로 변형에는 상태 표시줄 자체가 없고, `flat` 변형에는 세 장식을 그리지 않습니다. 화면에 담을 앱 화면은 `child` 와 같은 자리인 **Child** 교체(INSTANCE_SWAP) 속성으로 넣습니다.

### 상태 표시줄과 홈 제스처 바

두 요소의 길이는 **iOS point** 로 적고, 기기와 방향마다 정해 둔 배율로 그립니다. 본체 너비를 바꿔도 높이 · 세로 위치 · 글자 · 아이콘 · 홈 바 길이는 그대로이고 놓이는 영역만 늘어납니다.

- 배율은 `systemBarReferenceScale` · `landscapeSystemBarReferenceScale` 입니다. 폰 세로는 `144 / 402`, 폰 가로는 `312 / 874`, 태블릿은 두 방향 모두 `144 / 402` 입니다.
- 폰 상태 표시줄의 좌우 그룹은 폭과 가장자리 여백이 고정된 영역에 놓입니다. 이 영역은 화면 양쪽 가장자리를 기준으로 자리를 잡고, 내용은 영역 안에서 가운데 정렬됩니다. 태블릿의 두 그룹은 영역 없이 양쪽 가장자리 쪽에 붙습니다. 두 기기 모두 가장자리에서 `statusBarInset` 만큼 안쪽입니다.
- `statusBar*` · `gestureBar*` 길이와 상태 표시줄 글자 크기에는 이 고정 배율을 곱합니다. 카메라 · 버튼 같은 하드웨어 길이도 너비를 따라 커지지 않습니다.
- Flutter 테마의 크기 배율은 따로 적용됩니다. 여기에서 그대로라고 한 것은 목업의 `width` 를 바꿨을 때입니다.

상태 표시줄은 화면의 `backgroundColor` 를 바탕으로 칠한 불투명한 줄입니다. 자식 위에 놓이고 카메라 **뒤**에 놓입니다. 그래서 폰의 카메라 알약은 상태 표시줄 안에 놓입니다. 담는 항목은 기기마다 다릅니다.

| 기기 | 왼쪽 | 오른쪽 |
| --- | --- | --- |
| `phone` | 시계 `9:41` | 신호 · Wi-Fi · 배터리(바깥 윤곽 · 남은 양 · 꼭지) |
| `tablet` | 시계 `9:41` `오전` · 날짜 `4월 1일 수요일` | Wi-Fi · `100%` · 배터리 |

시각 · 날짜 · 배터리 글은 한 순간을 찍은 화면의 예시라 로케일을 따르지 않고, 바꾸는 속성도 없습니다. 신호 · Wi-Fi · 태블릿 배터리 그림과 폰 배터리의 꼭지는 벡터 경로(`CoreVectorGlyph`)이고 두 플랫폼이 같은 경로를 그립니다. 폰 배터리의 윤곽과 남은 양은 모서리가 둥근 사각형입니다.

홈 제스처 바는 `on-surface` 색의 **불투명한** 막대입니다. 막대만 그리고 그 영역의 바탕은 칠하지 않습니다(화면이 이미 그 자리를 칠합니다). 막대는 가로 가운데에서 화면 아래 가장자리로부터 `gestureBarOffset` 만큼 떨어져 놓입니다. 모서리 반경은 높이의 절반보다 조금 작아 알약 모양은 아닙니다.

### 카메라 · 안테나 띠

카메라가 놓이는 자리는 기기에 따라 다릅니다(`cameraPlacement`).

| 항목 | 폰 | 태블릿 |
| --- | --- | --- |
| 위치 | 화면을 파낸 알약 — `screen` | 화면 위 베젤 띠 안의 작은 원 — `bezel` |
| 크기 | 알약 `45 × 13`, 화면 위에서 `4` | 원 `4 × 4`, 베젤 띠 위에서 `2`, 가로 가운데 |
| 렌즈 | 알약 오른쪽 끝의 렌즈 링 `6.5` 와 코어 `3.9` | 링 없음 — 원 자체가 렌즈이고 안에 코어 `2.4` |
| 가로 | 세운 자세를 **반시계 방향으로 돌려** 화면 **왼쪽 가장자리**에 세로 알약(`13 × 45`)으로 서고, 렌즈는 위쪽 끝 | 방향과 상관없이 위쪽 베젤 띠 가운데 |

코어에는 원형 그라디언트(`coreGradient`)와 왼쪽 위의 작은 반짝임이 있습니다. 반짝임의 크기와 위치는 코어 지름에 대한 비율이고, 카메라를 돌려도 왼쪽 위에 남습니다. `cutoutColor` 를 정하면 코어도 그 단색이 되고, 정하지 않으면 그라디언트입니다.

안테나 띠는 **폰에만** 있습니다. 길이는 `1.9`, 두께는 레일 폭(`railWidth`)과 같아 베젤 바깥의 몸체 고리를 가로지릅니다. 한 변에 하나 또는 두 개씩 모두 여섯 개입니다. 가로로 돌리면 같은 띠가 재는 끝과 거리를 그대로 두고 변만 시계 방향으로 한 칸 옮겨 갑니다(좌표를 통째로 돌린 것은 아닙니다). 태블릿은 `antennaBandLength: 0` 이라 띠가 없습니다.

### 자식 콘텐츠의 SafeArea

`child` 는 카메라 · 상태 표시줄 · 홈 제스처 바를 피하는 안전 영역 안에 놓입니다. 네 변의 여백은 각각 **그 변의 장식이 보일 때만** 생깁니다.

| 변 | 여백 |
| --- | --- |
| 위 | 상태 표시줄이 보이면 그 높이. 카메라가 **화면 위쪽 가장자리를 파고** 있으면 카메라의 아래쪽 끝에, 화면 가장자리와 카메라 사이의 간격만큼을 더한 값. 둘 중 큰 쪽입니다. |
| 왼쪽 | 카메라가 **화면 왼쪽 가장자리**에 서 있을 때(가로로 돌린 폰)만, 카메라의 안쪽 끝에 같은 방식의 간격을 더한 값 |
| 아래 | 홈 제스처 바가 보이면 그 영역 높이(`gestureBarAreaHeight`)와 막대가 차지하는 높이 중 큰 쪽 |
| 오른쪽 | 항상 `0` |

태블릿의 카메라는 화면 밖 베젤에 있어 위 여백을 만들지 않으므로, 태블릿의 위 여백은 상태 표시줄 높이입니다. 각 표시 옵션은 자기 여백만 없앱니다. 상태 표시줄을 끄면 폰은 카메라가 필요한 여백만 남고, 태블릿은 `0` 이 됩니다. 여백은 하드웨어처럼 기기에 고정된 **실제 왼쪽 · 오른쪽**이라 글자 방향을 따라 뒤집히지 않습니다. 상태 표시줄의 두 그룹도 같아서, 오른쪽에서 왼쪽으로 쓰는 문서에서도 항목 순서와 간격이 왼쪽부터 그대로 놓입니다. `mockupDeviceStyle` 로 하드웨어의 크기 · 위치를 바꾸거나 Flutter 의 테마 배율을 바꾸면 안전 영역도 함께 계산됩니다. 렌즈나 코어를 키워 카메라가 더 깊이 들어오면 여백도 커집니다. 여백은 화면 크기를 넘지 않습니다.

Flutter 는 목업 화면을 기준으로 한 `MediaQuery`(화면 크기와 여백)와 `SafeArea` 를 씁니다. 바깥 기기의 노치나 키보드 여백은 섞이지 않고, 자식이 다시 `SafeArea` 를 써도 여백이 두 번 생기지 않습니다. Web 은 같은 계산으로 얻은 값을 콘텐츠의 안쪽 여백으로 씁니다. Figma 는 표시 옵션에 연결한 Auto Layout 여백을 씁니다.

### SafeArea와 자식 배경색 맞추기

`mockupDeviceStyle.backgroundColor` 는 **자식 뒤의 화면 전체**를 칠합니다. 안전 영역 바깥의 여백과 상태 표시줄의 바탕까지 포함합니다. 기본값은 테마의 `surface` 입니다. 자식의 배경색을 알아서 따라가지는 않습니다. 아래 첫 번째 화면처럼 `child` 에만 색을 칠하면 여백이 남으므로, 두 번째 화면처럼 같은 색을 화면에 지정하세요.

<Preview demo="mockup/safe-area-fill" />

```dart
// Flutter 와 Web 에서 같은 API 를 씁니다.
MockupDevice(
  mockupDeviceStyle: const CoreMockupDeviceStyle(
    backgroundColor: CoreColor.token(CoreColors.primaryContainer),
  ),
  child: Text('앱 화면'),
)
```

자식을 투명하게 두면 화면의 배경을 그대로 함께 씁니다. 반투명한 색은 `MockupDevice` 에 한 번만 칠해야 콘텐츠 부분이 두 번 겹쳐 여백보다 진해지지 않습니다. 다만 상태 표시줄은 같은 색을 화면 위에 한 번 더 칠하므로, 반투명한 색을 쓰면 상태 표시줄 띠가 더 진해집니다. Widgetbook 의 `backgroundColor` 색 컨트롤에서 값을 바꿔 볼 수 있고, Figma 에서는 `screen` 의 Fill 이 콘텐츠와 투명한 여백 뒤까지 이어집니다.

<a id="동작-스펙-behavior"></a>

## 상태

`MockupBrowser` · `MockupDevice` · `MockupCode` 에는 hover · pressed · disabled 같은 상태가 없습니다.

### 인터랙션

- 기본은 움직임이 없는 틀입니다. 주소창, 하드웨어, 상태 표시줄, 코드 틀의 장식은 실제 브라우저 · 운영체제 · 편집기처럼 동작하지 않습니다.
- 기기 목업의 상태 표시줄은 한 순간을 찍은 화면이라 시계가 흐르지 않고 로케일도 따르지 않습니다(`9:41` · `오전` · `4월 1일 수요일` · `100%`).
- `child` 에 넣은 버튼 · 입력 같은 컨트롤은 틀 안에서 그대로 동작합니다.

### 상태 전환

세 컴포넌트에는 상태 전환이 없습니다. `device` 나 `orientation` 같은 값을 바꾸면 새 모습을 바로 그립니다. 접힘 각도에 따라 움직이는 기기는 [MockupFoldable](/components/mockup-foldable) 입니다.

### 애니메이션

세 컴포넌트에는 자체 애니메이션이 없습니다. 자식의 애니메이션은 그대로 동작합니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 랜딩 페이지나 문서에서 앱 · 웹 화면을 기기나 창 틀 안에 보여 줄 때
- 기술 문서에서 짧은 코드를 편집기 모양의 틀로 보여 줄 때
- 데모나 소개 화면에서 스크린샷을 실제 기기처럼 보여 줄 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 기기 · 창 장식 없이 콘텐츠 면만 필요할 때 | [Card](/components/card) |
| 코드를 선택 · 복사하거나 구문 강조해야 할 때 | [CodeSnippet](/components/code-snippet) |
| 가운데가 접히는 기기가 필요할 때 | [MockupFoldable](/components/mockup-foldable) |

### 화면에 담는 내용

실제 화면과 비슷한 예시 콘텐츠를 담으세요. 디자인 리뷰나 문서에서 실제로 어떻게 보일지 전하기 쉽습니다. 랜딩 페이지의 첫 화면에는 실제 앱의 스크린샷을 기기 목업에 담으면 앱의 모습이 그대로 전해집니다.

<Preview demo="mockup/do-sample-screen" />

목업은 자식을 그대로 그립니다. 애니메이션이 많은 앱 전체를 넣으면 그 렌더링 비용이 그대로 들기 때문에, 보여 주기만 할 화면은 스크린샷 이미지가 가볍습니다.

<Split>

<Code language="dart" title="이렇게 하세요">
MockupDevice(
  child: Image.asset(
    'assets/screenshots/app_home.png',
    fit: BoxFit.cover,
  ),
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 움직이는 앱 전체를 틀 안에 띄웁니다.
MockupDevice(
  child: MaterialApp(
    home: ComplexAppWithManyAnimations(),
  ),
)
</Code>

</Split>

<a id="do"></a>
<a id="dont"></a>

코드 틀에는 한눈에 읽히는 짧은 코드를 담으세요. 편집기 모양의 틀은 짧은 예제를 돋보이게 하지만, 긴 줄은 잘리고 스크롤해서 볼 수 없습니다.

<Cards columns="2">
<Card demo="mockup/do-short-code" tone="do" eyebrow="이렇게 하세요">

틀의 폭 안에 들어가는 짧은 줄을 담습니다.

</Card>
<Card demo="mockup/dont-long-code" tone="dont" eyebrow="이렇게 하지 마세요">

폭을 넘는 줄은 뒷부분이 보이지 않습니다. 읽고 복사할 코드는 [CodeSnippet](/components/code-snippet) 에 담으세요.

</Card>
</Cards>

### 실제 앱의 틀로 쓰지 않습니다

목업은 문서, 발표, 데모, Widgetbook 처럼 보여 주는 용도입니다. 실제 앱의 레이아웃 컨테이너로 쓰면 사용자가 헷갈리고 필요 없는 장식이 한 겹 늘어납니다.

<Split>

<Code language="dart" title="이렇게 하세요">
// 문서 · 소개 화면 안에서 보여 줍니다.
MockupBrowser(
  addressBar: 'example.com',
  child: Image.asset('assets/screenshots/landing.png'),
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 실제 앱 화면을 기기 틀로 감쌉니다.
Scaffold(
  child: MockupDevice(
    child: actualAppContent,
  ),
)
</Code>

</Split>

## 배치

| 컴포넌트 | 폭 | 높이 |
| --- | --- | --- |
| `MockupBrowser` | 부모의 폭을 채웁니다. | `child` 높이에 툴바 자리(기본 `44`)를 더합니다. 부모가 높이를 정하면 그 높이를 채웁니다. `child` 가 없으면 툴바 자리만 남습니다. |
| `MockupDevice` | `width`. 비우면 `realistic` 은 `320`, `flat` 은 `256` | 화면 비율과 베젤에서 계산합니다. 너비 320 의 세로 폰은 약 `675`, 태블릿은 약 `454`, 가로 폰은 약 `156` 입니다. |
| `MockupCode` | 부모의 폭을 채웁니다. | 줄 수를 따릅니다. |

- Flutter 에서 `MockupBrowser` · `MockupCode` 는 폭이 정해진 부모가 필요합니다. `Row` 안에서는 `Expanded` 나 `SizedBox` 로 감싸세요.
- `MockupDevice` 는 부모의 폭에 맞춰 줄지 않습니다. 모든 부품의 자리를 `width` 로 계산하므로, 좁은 자리에는 `width` 를 직접 줄여 적으세요.
- Flutter 의 `MockupDevice` 는 받은 폭 안에서 본체를 위쪽 가운데에 둡니다. 부모가 높이의 한계를 정하면 그 높이도 모두 차지하고 본체는 위에 놓입니다. Web 은 본체 크기의 `inline-flex` 상자라서 정렬은 부모의 레이아웃을 따릅니다.

### 조합 예제

랜딩 페이지의 첫 화면처럼 설명과 목업을 나란히 놓는 Flutter 코드입니다.

```dart
Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CoUI로 아름다운 UI 만들기').headlineLarge.onSurface,
          const Gap.space16(),
          Text('Flutter와 Web을 동시에 지원하는 디자인 시스템').bodyMedium.onSurfaceVariant,
          const Gap.space24(),
          Button(
            onPressed: handleGetStarted,
            child: const Text('시작하기'),
          ),
        ],
      ),
    ),
    const Gap.space32(),
    Expanded(
      child: MockupBrowser(
        addressBar: 'https://example.com',
        child: Image.asset('assets/screenshots/landing.png'),
      ),
    ),
  ],
)
```

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

보여 줄 내용과 동작을 고르는 값(`addressBar` · `showControls` · `device` · `orientation` · `finish` · `width` · `lines` 등)은 생성자 속성이고, 색 · 크기 · 간격 · 모서리 같은 겉모습은 컴포넌트마다 있는 스타일 속성 하나(`mockupBrowserStyle` · `mockupDeviceStyle` · `mockupCodeStyle`)로 바꿉니다. `CoreMockupTheme.style`(`CoreMockupStyle`)은 목업들이 함께 쓰는 겉모습 값입니다.

<Split>

<Code language="dart" title="목업 하나만 바꾸기">
MockupBrowser(
  addressBar: 'example.com',
  mockupBrowserStyle: const CoreMockupBrowserStyle(
    contentBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
  ),
  child: Text('페이지 콘텐츠'),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    mockupBrowser: CoreMockupBrowserTheme(
      style: CoreMockupBrowserStyle(toolbarHeight: CoreSpace.space48),
    ),
    mockupCode: CoreMockupCodeTheme(
      style: CoreMockupCodeStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      ),
    ),
    mockupDevice: CoreMockupDeviceTheme(
      deviceStyles: {
        CoreMockupDevice.tablet: CoreMockupDeviceStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
        ),
      },
    ),
  ),
)
</Code>

</Split>

<a id="resolve-chain"></a>

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
MockupBrowser · MockupCode
  CoreMockupBrowserStyle · CoreMockupCodeStyle 기본값
    → CoreComponentTheme.mockup.style                        // 목업 공유 값
    → CoreComponentTheme.mockupBrowser · mockupCode 의 style  // 컴포넌트별 앱 값
    → mockupBrowserStyle · mockupCodeStyle                    // 인스턴스별

MockupDevice
  CoreMockupDeviceStyle 기본값과 defaultsByDevice[device]
    → CoreMockupDeviceStyle.defaultsByFinish[finish]
    → CoreComponentTheme.mockup.style                        // 목업 공유 값
    → CoreComponentTheme.mockupDevice.style
    → CoreComponentTheme.mockupDevice.deviceStyles[device]   // 기기별 앱 값
    → CoreComponentTheme.mockupDevice.finishStyles[finish]   // 마감별 앱 값
    → mockupDeviceStyle                                      // 인스턴스별
```

공유 값은 컴포넌트마다 받는 필드가 다릅니다.

| 공유 필드 | MockupBrowser | MockupDevice | MockupCode |
| --- | --- | --- | --- |
| backgroundColor | 창 몸체 채움 | 화면 채움 | 코드 블록 배경 |
| borderColor | 창 테두리 | 림 선 | 받지 않음 |
| frameColor | 받지 않음 | 몸체 단색(`railColor`) | 받지 않음 |
| borderRadius | 창 모서리 | 몸체 모서리 | 코드 블록 모서리 |

공유 값은 `flat` 마감의 값보다 뒤에 놓입니다. 그래서 공유 `borderRadius` 를 정하면 `flat` 틀의 모서리 기본값도 덮습니다. 공유 `frameColor` 도 `flat` 의 `railColor` 를 덮지만, `flat` 은 레일 폭이 `0` 이라 보이는 고리는 베젤이므로 모습은 달라지지 않습니다. `flat` 만 다시 정하려면 `finishStyles` 를 쓰세요. 고리 색은 `bezelColor` 입니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 목업에는 `withStyle` 체인으로 스타일을 덧붙일 수 있습니다. 생성자의 스타일 속성과 같게 동작하고, 겹치는 필드는 뒤에 붙인 값이 이깁니다. `.radius8` · `.surfaceContainer` 처럼 Core 토큰 상수와 이름이 같은 getter 도 있습니다. 이름이 곧 값이라(`.radius8` 은 `CoreRadius.radius8`) 어느 목업에서나 같은 값을 뜻합니다. `MockupBrowser` · `MockupDevice` · `MockupCode` 모두 같은 `.radiusN` · `.색이름` getter 를 갖습니다.

```dart
// 코드 틀의 모서리와 배경
MockupCode.fromString('flutter run').radius12.surfaceContainer

// 기기 화면의 배경
MockupDevice(child: Text('앱 화면')).surfaceContainer

// getter 에 없는 필드는 withStyle 로 덧붙입니다.
MockupBrowser(
  addressBar: 'example.com',
  child: Text('페이지 콘텐츠'),
).radius8.withStyle(
  const CoreMockupBrowserStyle(
    contentBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
  ),
)
```

`.radiusN` 은 `borderRadius` 를, 색 getter 는 `backgroundColor` 를 정합니다. `MockupDevice` 의 `backgroundColor` 는 화면 채움이고 `MockupCode` 는 코드 블록 배경입니다. `MockupBrowser` 의 `backgroundColor` 는 콘텐츠 면 뒤의 창 몸체라 기본 상태에서는 보이지 않습니다. 창 안의 색은 위 예처럼 `contentBackgroundColor` 로 바꾸세요.

### CoreMockupBrowserStyle

콘텐츠 면(`surface`)이 창 전체를 채우고, 툴바는 그 위의 정해진 자리에 겹칩니다. 툴바는 `surfaceContainerLow` 88% 채움과 배경 흐림 20, `surfaceContainer` 아래 구분선을 씁니다. 이전/다음 묶음과 공유 · 새 탭 묶음은 높이 28 의 캡슐이고, 주소창에는 자물쇠와 새로고침 아이콘이 있습니다. 창 맨 위 층이 `outlineVariant` 1px 테두리와 흰색 35% 의 안쪽 윗선을 그립니다. `child` 가 없으면 툴바 높이만 남습니다. 컴포넌트는 부모의 크기를 따르며, Figma 의 미리보기 크기는 380×200 입니다.

| 슬롯 | 타입 | 기본값 | 비고 |
| --- | --- | --- | --- |
| `backgroundColor` | `CoreColor?` | `surfaceContainerLow` | 창 몸체 채움. 콘텐츠 면 뒤에 깔립니다. |
| `borderColor` | `CoreColor?` | `outlineVariant` | 창 테두리 색 |
| `borderWidth` | `double?` | `CoreStrokeWidth.stroke1` | 창 테두리 두께 (logical px) |
| `borderRadius` | `CoreBorderRadius?` | `radius14` | 창 모서리 |
| `boxShadow` | `List<CoreShadowLayer>?` | `CoreShadow.xl` | 창 그림자. 한 겹(아래로 24, 번짐 64, 12.5%)입니다. 빈 리스트를 넘기면 이 그림자를 그리지 않습니다. |
| `chromeWidth` | `double?` | `CoreSpace.space0` | 좌 · 우 · 하에서 `child` 를 안으로 들이는 두께. 콘텐츠 면의 칠은 창 전체 그대로입니다. |
| `contentBackgroundColor` | `CoreColor?` | `surface` | 콘텐츠 면 채움. 창 전체를 덮습니다. |
| `contentBorderRadius` | `CoreBorderRadius?` | 계산값 | 콘텐츠 면의 모서리. 비우면 모서리마다 `borderRadius − chromeWidth`(0 이상)입니다. |
| `toolbarHeight` | `double?` | `CoreSpace.space44` | 창 위 가장자리에서 잰 툴바 높이 (logical px) |
| `toolbarPadding` | `CoreEdgeInsets?` | 좌우 `space12` | 툴바 안쪽 여백. 창의 바깥 가장자리에서 잽니다. |
| `toolbarSpacing` | `double?` | `CoreSpace.space8` | 툴바 묶음(컨트롤 · 이전/다음 · 주소창 · 공유와 새 탭) 사이 간격 |
| `controlSize` | `double?` | `CoreSize.size8` | 창 컨트롤 점 지름 |
| `controlSpacing` | `double?` | `CoreSpace.space6` | 창 컨트롤 점 사이 간격 |
| `controlBorderRadius` | `CoreBorderRadius?` | `radius9999` | 창 컨트롤 점 모서리 |
| `controlCloseColor` · `controlMinimizeColor` · `controlMaximizeColor` | `CoreColor?` | `error` · `warning` · `success` | 창 컨트롤 색. 지금 테마를 따릅니다. |
| `navSpacing` | `double?` | `CoreSpace.space8` | 이전 · 다음 화살표 사이 간격 |
| `navIconStyle` | `CoreIconStyle?` | 12 · `onSurfaceVariant` | 이전 아이콘 |
| `navDisabledIconStyle` | `CoreIconStyle?` | 12 · `disabledContent` | 다음 아이콘(쓸 수 없는 모양) |
| `actionIconStyle` | `CoreIconStyle?` | 12 · `onSurfaceVariant` | 공유 · 새 탭 아이콘 |
| `addressBarHeight` | `double?` | `CoreSpace.space28` | 주소창 높이 (logical px) |
| `addressBarPadding` | `CoreEdgeInsets?` | 좌우 `space8` | 주소창 안쪽 여백 |
| `addressBarBorderRadius` | `CoreBorderRadius?` | `radius9999` | 주소창 모서리 |
| `addressBarBackgroundColor` | `CoreColor?` | `surfaceContainer` 70% | 주소창 채움 |
| `addressBarTextStyle` | `CoreTextStyle?` | `labelSmall` · `onSurfaceVariant` | 주소창 글자 모양(색 포함) |
| `addressBarTextAlign` | `CoreTextAlign?` | `center` | 주소창 글 정렬. 정하지 않으면 주소는 앞쪽에서 시작하므로, 가운데에 두려면 `CoreTextAlign.center` 를 직접 적습니다. |
| `toolbarBackgroundColor` | `CoreColor?` | `surfaceContainerLow` 88% | 툴바 채움 |
| `toolbarBorderColor` · `toolbarBorderWidth` | `CoreColor?` · `double?` | `surfaceContainer` · `stroke1` | 툴바 아래 구분선 |
| `toolbarBlur` | `double?` | 20 | 툴바 뒤를 흐리게 하는 정도 |
| `capsuleBackgroundColor` | `CoreColor?` | `surfaceContainer` 70% | 이전/다음 · 공유와 새 탭 캡슐 채움 |
| `capsuleBorderRadius` · `capsulePadding` · `capsuleHeight` | `CoreBorderRadius?` · `CoreEdgeInsets?` · `double?` | `radius9999` · 좌우 `space8` · `space28` | 캡슐의 모서리 · 안쪽 여백 · 높이 |
| `actionSpacing` | `double?` | `space8` | 공유 · 새 탭 사이 간격 |
| `addressBarSpacing` · `domainSpacing` | `double?` | `space6` · 3 | 주소창 안의 간격 · 자물쇠와 주소 사이 간격 |
| `addressIconStyle` | `CoreIconStyle?` | 10 · `onSurfaceVariant` | 자물쇠 · 새로고침 아이콘 |
| `contentTextStyle` | `CoreTextStyle?` | `bodySmall` · `onSurfaceVariant` | 자식이 물려받는 글자 모양. 역할이나 색을 따로 정하지 않은 `Text` 가 이 값을 그대로 씁니다. |
| `highlightColor` · `highlightWidth` | `CoreColor?` · `double?` | 흰색 35% · `stroke1` | 창 안쪽 윗선 |

<Note>

콘텐츠 면이 창 전체를 덮으므로 `backgroundColor`(공유 `backgroundColor` 와 색 getter 포함)는 `contentBackgroundColor` 를 투명하거나 반투명하게 했을 때만 비쳐 보입니다. `chromeWidth` 를 늘려도 마찬가지입니다.

</Note>

### CoreMockupDeviceStyle

기기 목업은 부품의 자리를 하나씩 적지 않고 같은 규칙으로 계산합니다. 베젤은 네 변이 같은 두께이고 화면은 몸체 가장자리에서 `railWidth + bezelWidth` 만큼 안쪽에 있습니다. 베젤과 화면의 모서리는 몸체 모서리에서 각각의 거리를 빼서 동심원이 되고(서피스 스타일이 모서리를 바꿀 때의 Web 은 [플랫폼 차이](#플랫폼-차이)를 보세요), 버튼이 붙는 변은 `device` 와 `orientation` 에서 정해집니다. 그래서 `bezelRadius` · `screenRadius` 같은 필드는 없습니다. `cameraColor` 라는 필드도 없습니다. 렌즈 링을 품은 컷아웃은 화면에 뚫린 구멍이라 `cutoutColor` 를, 링이 없는 컷아웃은 그 자체가 렌즈라 `lensColor` 를 씁니다.

색과 길이는 두 종류입니다. 아래 설명은 기본 마감(`realistic`) 기준입니다.

- **하드웨어** — 레일 · 림 · 베젤 · 버튼 · 카메라 · 안테나 띠. 색은 디자인에서 정한 고정 값이라 밝기 · 고대비 모드와도, 앱의 팔레트와도 상관이 없고(실제 기기는 다크 모드에서 색이 바뀌지 않고 앱의 브랜드 색으로 칠해져 있지도 않습니다), 길이는 논리 px 입니다. 몸체 채움 · 림 · 베젤 · 버튼 밑바탕 · 렌즈 · 코어 · 안테나 띠가 여기에 속합니다. 버튼 광택 · 림의 번짐 빛 · 베젤 안쪽 그림자 · 버튼 두께의 음영 · 몸체 아래 그림자는 흰색이나 검정을 투명도로 겹친 효과이고 역시 고정 값입니다. 몸체 아래 그림자는 어느 모드에서나 검정입니다.
- **운영체제 화면** — 화면 채움 · 상태 표시줄 · 홈 제스처 바. 색은 지금 테마(`surface` · `on-surface`)를 따르고, `statusBar*` · `gestureBar*` 길이는 iOS point 이며 기기 · 방향별 고정 배율로 그립니다.

하드웨어 색은 테마 색을 읽지 않습니다. 그래서 모드를 바꾸면 화면 · 상태 표시줄 · 홈 제스처 바만 바뀌고 기기는 그대로이며, 브랜드 팔레트를 쓰는 앱에서도 기기 색은 같습니다. 기기 색을 바꾸려면 아래 슬롯에 색을 직접 넘깁니다. `flat` 마감의 링과 몸체 색은 예외로 테마의 `surfaceContainerHighest` 를 따릅니다.

몸체 채움은 그라디언트가 기본입니다. `railColor`(목업 공유 `frameColor` 포함)를 정하면 몸체가 그 단색이 되고, `railGradient` 를 정하면 `railColor` 보다 우선합니다. 코어 채움도 같은 규칙입니다. `cutoutColor` 를 정하면 단색, `coreGradient` 를 정하면 그라디언트입니다.

#### 몸체 · 림

| 슬롯 | 타입 | 기본값 | 비고 |
| --- | --- | --- | --- |
| `backgroundColor` | `CoreColor?` | `surface` | 자식과 안전 여백 뒤, 상태 표시줄 바탕까지의 화면 채움. 테마를 따릅니다. |
| `railGradient` | `CoreGradient?` | 위→아래 `#C3C4C6` · `#7D7F82` · `#7D7F82` · `#AEAFB2` (0 · 0.1 · 0.9 · 1) | 몸체 채움. 가로 · 세로 모두 위→아래이고 `railColor` 보다 우선합니다. |
| `railColor` | `CoreColor?` | `#7D7F82` | 몸체를 단색으로 만듭니다. 직접 정했을 때만 그려집니다. 기본값은 그라디언트의 가운데 색입니다. |
| `borderRadius` | `CoreBorderRadius?` | 기기별 | 몸체 모서리. 베젤은 여기서 `railWidth` 를, 화면은 `railWidth + bezelWidth` 를 뺍니다. |
| `railWidth` | `double?` | `3` | 몸체 가장자리에서 베젤까지의 고리 두께. 림과 안테나 띠가 이 안에 놓입니다. |
| `borderColor` | `CoreColor?` | `#646568` | 림 선 색. 몸체 가장자리 안쪽의 선입니다. |
| `borderWidth` | `double?` | `CoreStrokeWidth.stroke1` | 림 선 두께 |
| `rimHighlightColor` | `CoreColor?` | `#FFFFFF` | 림 바로 안쪽의 밝은 가는 선 |
| `rimHighlightWidth` | `double?` | `0.5` | 상자 안쪽으로 그립니다. `0` 이면 그리지 않습니다. |
| `rimHighlightInset` | `double?` | `0.4` | 몸체의 위 · 아래 가장자리에서만 들여 씁니다(왼쪽 · 오른쪽은 그대로). 모서리 반경은 몸체의 값을 줄이지 않습니다. |
| `rimGlowGradient` | `CoreGradient?` | 위→아래 `#FFFFFF` → 투명 (0 → 0.51) | 림의 번짐 빛. 방향은 가로 · 세로 모두 위→아래이고 모드와 상관없습니다. |
| `rimGlowOpacity` | `double?` | `CoreOpacity.opacity50` | 번짐 빛 선 전체의 불투명도(색 정지점마다 곱하지 않습니다) |
| `rimGlowWidth` | `double?` | `0.6` | 상자 안쪽으로 그립니다. `0` 이면 그리지 않습니다. |
| `rimGlowTopInset` | `double?` | `0.8` | 몸체의 위 가장자리에서만 들여 씁니다. |
| `rimGlowBottomInset` | `double?` | `0.4` | 몸체의 아래 가장자리에서만 들여 씁니다. 림의 밝은 선과 같은 값이라 두 선이 함께 끝납니다. |
| `rimGlowBlur` | `double?` | `0.8` | 번짐 빛 선에만 거는 흐림 반경 |

#### 베젤 · 화면

| 슬롯 | 타입 | 기본값 | 비고 |
| --- | --- | --- | --- |
| `bezelWidth` | `double?` | 기기별 | 베젤 두께. 화면은 몸체 가장자리에서 `railWidth + bezelWidth` 만큼 안쪽입니다. |
| `bezelColor` | `CoreColor?` | `#000000` | 베젤 채움 |
| `bezelBorderColor` | `CoreColor?` | `#27282B` | 베젤 상자 **바깥**(레일 위)에 그리는 윤곽선 |
| `bezelBorderWidth` | `double?` | `0.5` | 그림의 선이라 서피스 스타일이 테두리를 굵게 해도 그대로입니다(림의 밝은 선과 번짐 빛, 배터리 윤곽선도 같습니다). |
| `bezelInnerShadowColor` | `CoreColor?` | `#FFFFFF` 16% (`0x29FFFFFF`) | 베젤 안쪽 그림자. 유리에 흰색을 투명도로 겹친 효과라 모드와 상관없습니다. 투명도를 색에 담고 위치 이동은 `(0, 0)` 입니다. |
| `bezelInnerShadowBlur` | `double?` | `0.5` | 안쪽 그림자의 흐림 |
| `bezelInnerShadowSpread` | `double?` | `0.3` | 안쪽 그림자의 퍼짐 |
| `screenAspectWidth` · `screenAspectHeight` | `double?` | 기기별 | 화면 비율의 두 값. **방향은 정하지 않습니다.** 긴 변을 먼저 읽는 비율이고, 어느 쪽이 길어지는지는 `orientation` 이 정합니다. |
| `containerStyle` | `CoreOutlinedContainerStyle?` | 그림자 `CoreMockupDeviceStyle.defaultBodyShadow`, 그림자 색 `#000000` | 몸체를 그리는 `OutlinedContainer` 에 넘기는 안쪽 부품의 스타일. 몸체 채움은 `railGradient` · `railColor` 가 정합니다. 기본 그림자는 두 겹(아래로 14 · 번짐 28 · 퍼짐 −5 · 8%, 아래로 6 · 번짐 10 · 퍼짐 −3 · 5%)입니다. 그림자 색(`shadowBaseColor`)이 고정 검정이라 다크 모드에서도 흰 빛무리가 생기지 않고, 다크 모드라고 진해지지도 않습니다. |

#### 카메라

| 슬롯 | 타입 | 기본값 | 비고 |
| --- | --- | --- | --- |
| `cameraPlacement` | `CoreMockupCameraPlacement?` | 기기별 | `screen` 은 화면을 파낸 알약, `bezel` 은 화면 위 베젤 띠 안입니다. 카메라 부품이 어느 공간에 놓일지를 정합니다. |
| `cameraWidth` · `cameraHeight` | `double?` | 기기별 | 세워 든 알약의 긴 변 · 짧은 변 |
| `cameraOffset` | `double?` | 기기별 | 카메라가 놓인 공간(화면 또는 베젤)의 위 가장자리에서의 거리. 돌린 폰은 화면의 **왼쪽** 가장자리에서 잽니다. |
| `lensSize` · `lensOffset` | `double?` | 기기별 | 렌즈 링 지름 · 알약 끝에서의 거리(세운 자세는 오른쪽 끝, 돌린 폰은 위쪽 끝). `lensSize: 0` 이면 링이 없습니다. |
| `cameraCoreSize` | `double?` | 기기별 | 렌즈 코어 지름 |
| `lensColor` | `CoreColor?` | `#000000` | 렌즈 링의 색. 링이 없으면 컷아웃 자체의 색입니다. |
| `cutoutColor` | `CoreColor?` | `#000000` | 렌즈 링을 품은 컷아웃의 색. 정하면 코어도 이 단색이 됩니다. |
| `coreGradient` | `CoreGradient?` | 원형 `#000000` · `#0A3348` · `#0C3B52` · `#105171` · `#0C3B52` · `#000000` (0.2 · 0.35 · 0.5 · 0.62 · 0.8 · 1) | 코어 채움. 코어의 가운데에서 가장자리까지입니다. 가운데가 검정, 그 둘레가 파란 유리 광택, 가장자리가 다시 검정입니다. |
| `lensHighlightColor` | `CoreColor?` | `#FFFFFF` | 코어 위의 반짝임 |
| `lensHighlightSizeRatio` | `double?` | `4/15` | 코어 지름에 대한 반짝임 지름의 비율 |
| `lensHighlightOffsetXRatio` · `lensHighlightOffsetYRatio` | `double?` | `2/15` · `1/15` | 코어의 왼쪽 · 위쪽에서 반짝임까지의 거리를 코어 지름에 대한 비율로 적습니다. 자세와 상관없이 왼쪽 위에 놓입니다. |

#### 하드웨어 버튼

| 슬롯 | 타입 | 기본값 | 비고 |
| --- | --- | --- | --- |
| `buttonColor` | `CoreColor?` | `#AEAFB2` | 버튼 밑바탕 단색. 그 위에 광택과 음영이 겹칩니다. 몸체 색을 따라가지 않는 별도의 색입니다. |
| `buttonLengthGradient` | `CoreGradient?` | 색 정지점 8개 — 양 끝 가까이의 밝은 띠와 어두운 띠(흰색 · 검정의 투명도) | 길이 방향 광택. 세로 버튼은 위→아래, 가로 버튼은 왼쪽→오른쪽으로 돌려 쓰므로 `begin` · `end` 는 읽지 않습니다. |
| `buttonDepthColor` | `CoreColor?` | `#000000` 35% | 두께 방향 음영. 몸체에 가까운 쪽이 이 색이고 먼 쪽은 투명합니다. |
| `buttonThickness` · `buttonProtrusion` | `double?` | `CoreStrokeWidth.stroke2` · `1.5` | 버튼 두께 · 몸체 밖으로 나오는 거리. 나머지(`0.5`)는 몸체 뒤로 들어갑니다. |
| `powerButtonLength` · `powerButtonOffset` | `double?` | 기기별 | 세워 든 자세의 전원 버튼 길이 · 위치(변 길이에 대한 비율). 길이가 `0` 이면 버튼이 없습니다. |
| `volumeButtonLength` · `volumeButtonOffset` | `double?` | 기기별 | 세워 든 자세의 볼륨 버튼 길이 · 위치(비율). 길이가 `0` 이면 버튼이 없습니다. |
| `volumeButtonSpacing` | `double?` | 기기별 | 두 볼륨 버튼 사이 간격. `0` 이면 버튼 하나입니다. |
| `landscapePowerButtonLength` · `landscapePowerButtonOffset` | `double?` | 기기별 | `orientation: .landscape` 일 때의 전원 버튼 길이 · 위치(비율) |
| `landscapeVolumeButtonLength` · `landscapeVolumeButtonOffset` | `double?` | 기기별 | 같은 자세의 볼륨 버튼 |

버튼이 **어느 변**에 붙는지는 세워 든 자세를 시계 방향으로 한 변씩 돌려 정합니다. 그 변을 따라 **얼마나 들어가는지**와 **얼마나 긴지**만 `landscape*` 필드에 따로 적습니다. 디자인에서 가로 자세의 자리를 따로 잡았기 때문이며, 태블릿의 가로 버튼은 세로 버튼과 길이도 다릅니다.

#### 안테나 띠

| 슬롯 | 타입 | 기본값 | 비고 |
| --- | --- | --- | --- |
| `antennaBandLength` | `double?` | 기기별 | 띠 길이. `0` 이면 띠가 없습니다. 두께는 `railWidth` 입니다. |
| `antennaGradient` | `CoreGradient?` | 위→아래 `#FCFCFD` → `#E4E5E7` | 띠 하나하나의 위→아래(눕힌 띠도 자기 기준) |
| `antennaOpacity` | `double?` | `0.7` | 띠 하나에 거는 불투명도 |
| `antennaSideNearOffset` · `antennaSideFarOffset` | `double?` | `35.782` · `35.745` | 세운 자세에서 양쪽 변의 띠 두 쌍이 위쪽 끝 · 아래쪽 끝에서 떨어진 거리. 위아래가 대칭이 아니라 값이 서로 다릅니다. |
| `antennaTopOffset` · `antennaBottomOffset` | `double?` | `35.659` · `31.549` | 윗변 띠(오른쪽 끝에서) · 아랫변 띠(왼쪽 끝에서)의 거리 |

#### 상태 표시줄

길이는 모두 iOS point 입니다. 높이 · 위치 · 간격은 기기마다 다르고, 시각 · 날짜 · 배터리 글과 그림 모양은 필드가 아니라 고정 값입니다.

| 슬롯 | 타입 | 기본값 | 비고 |
| --- | --- | --- | --- |
| `systemBarReferenceWidth` · `landscapeSystemBarReferenceWidth` | `double?` | 기기별 | 상태 표시줄 · 홈 제스처 바의 기준 iOS 폭(세운 자세 · 돌린 자세). `0` 이하이면 두 요소의 배율이 0이 됩니다. |
| `systemBarReferenceScale` · `landscapeSystemBarReferenceScale` | `double?` | 기기별 | iOS point 를 논리 px 로 바꾸는 고정 배율. 본체 너비와 상관없습니다. |
| `statusBarHeight` · `landscapeStatusBarHeight` | `double?` | 기기별 | 상태 표시줄 높이. `0` 이면 그리지 않습니다(폰 가로). |
| `statusBarInset` | `double?` | 기기별 | 화면 옆 가장자리에서 첫 · 마지막 그룹까지 |
| `statusBarContentCenter` | `double?` | 기기별 | 막대 위쪽에서, 모든 글자와 그림의 가운데를 맞추는 선까지의 거리 |
| `statusBarWingWidth` | `double?` | 기기별 | `0` 보다 크면 각 그룹을 그 폭의 영역에서 가운데 정렬합니다(폰). 영역은 화면 가장자리에서 `statusBarInset` 만큼 안쪽에 놓입니다. `0` 이면 두 그룹이 `statusBarInset` 을 남기고 양쪽 가장자리 쪽에 붙습니다(태블릿). |
| `statusBarTrailingInset` | `double?` | 기기별 | 오른쪽 영역이 바깥쪽에 더 비워 두는 거리. 영역 폭이 있을 때만 뜻이 있습니다. |
| `statusBarTrailingSpacing` | `double?` | 기기별 | 오른쪽 그룹의 항목 사이 간격 |
| `statusBarClockSpacing` | `double?` | `CoreSpace.space2` | 시계와 오전/오후 표시 사이(태블릿) |
| `statusBarLeadingSpacing` | `double?` | `CoreSpace.space8` | 시계 묶음과 날짜 사이(태블릿) |
| `statusBarTextStyle` | `CoreTextStyle?` | 기기별 — 폰 `titleSmall`, 태블릿 `labelLarge`, 색은 `on-surface` | 시계 · 날짜 · 배터리 글. 글자 역할과 색을 정하면 글자 크기는 기기 · 방향별 고정 배율로 줄어듭니다. |
| `statusBarIconColor` | `CoreColor?` | `on-surface` | 신호 · Wi-Fi 그림, 폰 배터리의 남은 양, 태블릿 배터리 |
| `statusBarBatteryBorderColor` | `CoreColor?` | `on-surface` 35% | 폰 배터리의 바깥 윤곽 |
| `statusBarBatteryCapColor` | `CoreColor?` | `on-surface` 40% | 폰 배터리의 꼭지 |

#### 홈 제스처 바

길이는 모두 iOS point 입니다.

| 슬롯 | 타입 | 기본값 | 비고 |
| --- | --- | --- | --- |
| `gestureBarColor` | `CoreColor?` | `on-surface` | 막대 색. 불투명합니다. |
| `gestureBarWidth` · `landscapeGestureBarWidth` | `double?` | 기기별 | 막대 폭(세운 자세 · 돌린 자세) |
| `gestureBarHeight` | `double?` | `5` | 막대 두께 |
| `gestureBarOffset` | `double?` | `CoreSpace.space8` | 화면 아래 가장자리에서 막대 아랫변까지 |
| `gestureBarRadius` | `double?` | `CoreRadius.radius2` | 막대 모서리. 높이의 절반보다 조금 작아 끝이 둥글 뿐 알약은 아닙니다. |
| `gestureBarAreaHeight` · `landscapeGestureBarAreaHeight` | `double?` | 기기별 | 막대가 보일 때 아래 안전 여백으로 비워 두는 영역의 높이 |
| `gestureBarWidthRatio` | `double?` | 없음 | **Deprecated (since 0.154)** — 막대를 화면 폭의 비율로 고정합니다. 정하면 `gestureBarWidth` 보다 우선합니다. `gestureBarWidth` · `landscapeGestureBarWidth` 로 옮기세요. |

#### 기기별 기본값 (`defaultsByDevice`)

| 필드 | `phone` | `tablet` |
| --- | --- | --- |
| `screenAspectWidth` : `screenAspectHeight` | `9 : 19.5` | `299 : 433` |
| `borderRadius` | `CoreRadius.radius24` | `CoreRadius.radius16` |
| 레일 + 베젤 | `3 + 5` — 화면이 몸체 가장자리에서 `8` | `3 + 8` — `11` |
| `cameraPlacement` | `screen` | `bezel` |
| 카메라 | 알약 `45 × 13`(`cutoutColor`), 위에서 `4`, 렌즈 링 `6.5`(끝에서 `3.25`), 코어 `3.9` | 원 `4 × 4`(`lensColor`), 베젤 띠 위에서 `2`, 링 없음, 코어 `2.4` |
| 전원 버튼 | 오른쪽, 위에서 `0.30`, 길이 `40` | 위, 오른쪽 끝에서 `0.1167`, 길이 `45.433` |
| 볼륨 버튼 | 왼쪽, 위에서 `0.20`, 길이 `26` × 2 (간격 `8`) | 왼쪽, 위에서 `0.1838`, 길이 `33.317` × 1 |
| 전원 버튼 (가로) | 아래, 오른쪽 끝에서 `0.30`, 길이 `40` | 오른쪽, 위에서 `0.1550`, 길이 `49.522` |
| 볼륨 버튼 (가로) | 위, 왼쪽에서 `0.20`, 길이 `26` × 2 (간격 `8`) | 위, 왼쪽에서 `0.6205`, 길이 `36.316` × 1 |
| `antennaBandLength` | `1.9` (여섯 개) | `0` (없음) |
| 기준 폭 (세로 · 가로) | `402` · `874` | 약 `834.7` · 약 `1208.8` |
| 고정 배율 (세로 · 가로) | `144 / 402` · `312 / 874` | `144 / 402` · `144 / 402` |
| 상태 표시줄 높이 (세로 · 가로) | `59` · 없음 | `32` · `32` |
| `statusBarInset` · `statusBarWingWidth` | `24` · `101` | `16` · `0` |
| `statusBarContentCenter` | `32.5` | `16` |
| `statusBarTrailingInset` · `statusBarTrailingSpacing` | `2` · `6` | `0` · `4` |
| `statusBarTextStyle` | `titleSmall` | `labelLarge` |
| 홈 제스처 바 폭 (세로 · 가로) | `144` · `209` | `314` · `314` |
| 홈 제스처 바 영역 높이 (세로 · 가로) | `34` · `21` | `20` · `20` |

#### 마감별 기본값 (`defaultsByFinish`)

`realistic` 은 아무것도 덮지 않습니다. `flat` 은 기기와 상관없이 아래 값을 기기별 기본값 위에 덮습니다.

| 항목 | `flat` 의 값 |
| --- | --- |
| 몸체 모서리 | `radius32` (화면은 `24`) |
| 링 | 베젤 `8`, `bezelColor` · `railColor` 는 `surfaceContainerHighest`, `railWidth` 는 `0` |
| 화면 비율 | `1 : 2` (태블릿도 같고, 가로로 돌리면 `2 : 1`) |
| 그리지 않는 것 | 림 선 · 림의 밝은 선 · 번짐 빛 · 베젤 윤곽 · 안쪽 그림자 · 렌즈 링 · 버튼 · 안테나 띠 · 몸체 그림자 |
| 기본 너비 | `256` (화면 `240` 과 링 `8` 두 개). 너비는 스타일 필드가 아니라 `width` 속성의 기본값입니다. |
| 카메라 · 상태 표시줄 · 홈 제스처 바 | 기본으로 끕니다. `show*` 속성의 기본값입니다. |

### CoreMockupCodeStyle

| 슬롯 | 타입 | 기본값 | 비고 |
| --- | --- | --- | --- |
| `backgroundColor` | `CoreColor?` | `surfaceContainerLow` | 코드 블록 배경색 |
| `textStyle` | `CoreTextStyle?` | `codeSm` · `onSurface` | 코드 글자 모양(색 포함) |
| `prefixTextStyle` | `CoreTextStyle?` | `codeSm` · `onSurfaceVariant` | 줄 번호 같은 접두 글자 모양(색 포함) |
| `borderRadius` | `CoreBorderRadius?` | `radius8` | 코드 블록 모서리 |
| `padding` | `CoreEdgeInsets?` | 위아래 `space10`, 좌우 `space16` | 코드 블록 안쪽 여백 |
| `lineSpacing` | `double?` | `space4` | 줄마다 아래에 두는 간격 (logical px) |
| `lineNumberWidth` | `double?` | `CoreSize.size28` | 줄 번호 열 폭 (logical px) |
| `mutedToneColor` | `CoreColor?` | `onSurfaceVariant` | `CoreCodeLineTone.muted` 줄의 글 색 |
| `linkToneColor` | `CoreColor?` | `link` | `CoreCodeLineTone.link` 줄의 글 색 |
| `successToneColor` | `CoreColor?` | `onSuccessContainer` | `CoreCodeLineTone.success` 줄의 글 색 |
| `warningToneColor` | `CoreColor?` | `onWarningContainer` | `CoreCodeLineTone.warning` 줄의 글 색 |
| `errorToneColor` | `CoreColor?` | `onErrorContainer` | `CoreCodeLineTone.error` 줄의 글 색. `neutral` 줄은 따로 슬롯이 없고 `textStyle` 의 색을 따릅니다. |

<a id="접근성-accessibility"></a>

## 접근성

### 역할

`MockupBrowser` · `MockupDevice` · `MockupCode` 는 모두 자기 역할을 만들지 않습니다. 틀은 장식이고, 스크린 리더에는 안에 넣은 콘텐츠만 전해지는 것이 의도한 동작입니다.

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | 틀을 `Semantics` 로 감싸지 않습니다. 상태 표시줄을 빼는 `ExcludeSemantics` 만 있습니다. 틀 자체를 설명해야 하면 호출하는 쪽에서 `Semantics(container: true, label: '브라우저 목업: 문서 화면', child: …)` 처럼 감싸세요. |
| Jaspr Web | 컴포넌트가 붙이는 `role` · `aria-*` 가 루트에 없고, 넘긴 `attributes` 가 루트에 그대로 붙습니다. 이름이 필요하면 `attributes: {'role': 'group', 'aria-label': '…'}` 처럼 역할과 함께 넘기세요. 루트 태그는 `tag`(기본 `'div'`)로 바꿀 수 있습니다. |

순수한 장식은 읽히지 않습니다. `MockupBrowser` 의 창 컨트롤 점은 Web 에서 빈 `<div>`, Flutter 에서 글이 없는 상자입니다. `MockupDevice` 의 카메라 · 홈 제스처 바 · 버튼도 같습니다. 글이 있는 상태 표시줄은 Web 에서 `aria-hidden="true"` 를 붙이고 Flutter 에서는 시맨틱 트리에서 뺍니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| 없음 | 목업 틀이 처리하는 키가 없습니다. |

틀은 포커스 대상이 아닙니다. Flutter 에는 틀 자체의 `Focus` · `GestureDetector` · `onTap` 이 없고, Web 루트에는 `tabindex` 나 키 처리를 붙이지 않습니다. 틀 안에 넣은 자식의 키보드 동작은 그대로 유지됩니다. 창 컨트롤과 기기 버튼 그림은 실제 버튼이 아닙니다.

### 스크린 리더

틀 자체에는 접근 가능한 이름이 없고 상태를 알리는 것도 없습니다(실시간 알림 영역이 없는 정적인 틀입니다). 다만 틀이 그리는 아래 글은 **실제 글로 읽힙니다**.

- `MockupBrowser.addressBar` 는 두 플랫폼 모두 평범한 글입니다. 스크린 리더는 주소를 본문처럼 읽고, 주소창이라는 맥락은 전해지지 않습니다.
- `MockupCode` 의 줄 번호(`CoreCodeLine.prefix`)도 평범한 글입니다. 숨김 표시를 붙이지 않아 코드 본문과 섞여 `1 void main() { 2 print(...)` 처럼 읽힙니다.
- 줄의 `tone`(성공 · 경고 · 실패 등)은 색으로만 구분되고 접근성 정보에는 실리지 않습니다. 뜻이 중요한 줄은 `Error:` 처럼 글에도 담으세요.

> 줄 번호를 읽히고 싶지 않으면 `MockupCode.fromString(code, showLineNumbers: false)` 로 번호 자체를 만들지 마세요.

화면에 담은 스크린샷의 대체 텍스트는 목업이 만들지 않습니다. 이미지에 직접 설명을 붙이세요.

### 포커스 관리

없음. 오버레이가 아니므로 포커스를 옮기거나 가두거나 되돌리지 않습니다. 틀은 포커스를 요청하지 않고 자식의 이동 순서에도 관여하지 않습니다.

### 알려진 제약

| 항목 | 내용 |
| --- | --- |
| 코드의 의미 | `MockupCode` 는 `<pre>` · `<code>` 가 아닙니다. Web 은 루트와 줄이 `<div>` · `<span>` 이고 Flutter 는 `Text` 뿐이라 보조 기술에 "코드"로 전해지지 않습니다. Web 은 기본 생성자의 `tag` 로 루트 태그만 바꿀 수 있고 줄의 구조는 그대로이며, Flutter 에는 대응하는 설정이 없습니다. 코드의 의미가 필요하면 [CodeSnippet](/components/code-snippet) 을 쓰세요. |
| 들여쓰기 | Web 의 `MockupCode` 는 줄 앞의 공백과 이어진 공백이 합쳐져 보입니다. 들여쓰기가 뜻을 가지는 코드에는 맞지 않습니다. |
| 긴 코드 줄 | 두 플랫폼 모두 줄을 바꾸지 않고 틀에서 잘라 냅니다. 스크롤 영역이 아니라서 잘린 부분은 볼 방법이 없고, 글자를 확대하거나 폭이 좁아지면 잘리는 부분이 늘 수 있습니다. 줄을 틀 폭에 맞게 짧게 두거나, 읽어야 하는 코드는 [CodeSnippet](/components/code-snippet) 을 쓰세요. |
| 좁은 자리 | `MockupDevice` 는 부모의 폭에 맞춰 줄지 않습니다. 좁은 화면에서는 `width` 를 줄여 적어야 합니다. |
| 장식 | 주소창 · 창 컨트롤 · 기기 버튼 · 상태 표시줄은 그림이라 동작하지 않습니다. 실제 브라우저나 운영체제의 UI 처럼 안내하지 마세요. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

클래스 이름(`MockupBrowser` · `MockupDevice` · `MockupCode`)과 공통 속성은 두 플랫폼이 같습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 창 · 코드 틀 | `OutlinedContainer` 로 색 · 모서리를 그립니다. 테두리는 브라우저 창에만 있습니다. | `OutlinedContainer`(`<div>` 와 CSS) |
| 브라우저의 층 | `Stacks` 안에 콘텐츠 면, 흐림을 거는 툴바, 맨 위 테두리 | 같은 순서의 절대 배치 `<div>`. 흐림은 `backdrop-filter` 입니다. |
| 브라우저 안쪽 윗선 | `InsetShadow`(`CustomPaint`) | 안쪽 `box-shadow` |
| 브라우저 주소창 | `Expanded` 안의 알약 상자와 한 줄 말줄임 `Text` | 남은 폭을 채우는 `<div>` 알약과 말줄임 글 |
| 앱 창 (`addressBar: null`) | 주소창 · 화살표 · 공유 위젯이 트리에 없습니다. | 해당 `<div>` 가 DOM 에 없습니다. |
| 기기 틀 | `Stacks` 안에 버튼, `OutlinedContainer` 본체, 베젤, `ClipRRect` 화면. 카메라 · 상태 표시줄 · 제스처 바는 `Position` 으로 놓습니다. | 같은 구조의 `<div>`. 버튼 · 카메라 · 상태 표시줄 · 제스처 바는 미리 계산한 인라인 절대 배치입니다. |
| 림의 밝은 선 · 번짐 빛 | `CustomPaint` 로 상자 안쪽에 선을 그립니다(번짐 빛은 그라디언트와 `ImageFiltered` 흐림). | 안쪽 링 `<div>`. 번짐 빛은 그라디언트를 링 모양으로 잘라 흐림 · 불투명도를 겁니다. |
| 상태 표시줄 그림 | `CoreVectorGlyph` 경로를 `CustomPaint` 로 채웁니다. | 그림마다 인라인 `<svg>` 의 `<path>`(`fill-rule` 포함) |
| 상태 표시줄 글자 | 글자 크기에 화면 배율을 곱하고, 기기의 글자 크기 설정은 받지 않습니다. | 글자 크기에 화면 배율을 곱해 그립니다. |
| 상태 표시줄 접근성 | `ExcludeSemantics` 로 시맨틱 트리에서 뺍니다. | `aria-hidden="true"` |
| 안전 여백 | 목업 화면을 기준으로 한 `MediaQuery` 와 `SafeArea` 로 네 변을 줍니다. | 콘텐츠 래퍼의 네 변 `padding` |
| `screenBrightness` | 화면을 `BrightnessScope` 로 감싸 그 밝기의 테마로 다시 그립니다. | `data-theme` 를 단 상자 없는 래퍼(`display: contents`)로 감쌉니다. |
| 폭 | `MockupBrowser` · `MockupCode` 는 폭이 정해진 부모가 필요합니다. | 블록 폭(`w-full`)으로 부모를 채웁니다. |
| 기기의 가로 위치 | 받은 폭의 위쪽 가운데 | 본체 크기의 `inline-flex` 상자 |
| `child` 의 크기 | `MockupDevice` 의 `child` 는 안전 영역의 크기를 그대로 받아 채웁니다. `MockupBrowser` 는 부모가 높이를 정하면 툴바 아래의 남은 높이를 `child` 에 줍니다. | `child` 는 블록 흐름에 놓여 높이가 저절로 채워지지 않습니다. 남은 높이를 채우려면 `child` 에 `height: 100%` 를 줍니다. |
| 서피스 스타일이 바꾼 모서리 | 기기는 바뀐 몸체 반경에서 베젤 · 화면 반경을 다시 계산합니다. | 기기의 세 반경을 원래 값에서 계산해 적고, 모서리 토큰과 같은 값만 스타일을 따라 바뀝니다. 모서리를 바꾸는 스타일에서는 동심원이 어긋날 수 있습니다. |
| 코드의 공백 | 그대로 그립니다. | 줄 앞의 공백과 이어진 공백이 합쳐집니다. |
| 크기 배율 | 기기 · 브라우저 · 코드 틀의 길이에 테마의 크기 배율이 적용됩니다. | `rem` 으로 그려 브라우저의 글자 크기를 따릅니다. |
| 웹 전용 속성 | `key` 만 받습니다. | `tag` · `id` · `classes` · `css` · `attributes` · `eventHandlers` |

그림자는 컴포넌트마다 다릅니다.

- `MockupBrowser` 의 창은 `CoreMockupBrowserStyle.defaultBoxShadow`(`CoreShadow.xl`, 한 겹)를 씁니다. 테마가 다크면 진해지고, 서피스 스타일이 그림자 모양을 바꾸면 두 플랫폼 모두 따라갑니다.
- `MockupDevice` 의 몸체는 `CoreMockupDeviceStyle.defaultBodyShadow`(두 겹)를 모드와 상관없는 검정으로 그립니다. 색이 고정된 이 그림자는 Web 에서 `--shadow-*` 변수를 거치지 않아, 서피스 스타일이 바꾼 그림자 모양은 Flutter 에만 적용됩니다.
- `MockupCode` 는 자기 그림자가 없습니다. 네오 브루탈리즘처럼 평평한 표면에도 그림자를 주는 서피스 스타일에서는 두 플랫폼 모두 그 스타일의 그림자가 붙습니다.

`MockupCode` 에는 테두리가 없습니다(`CoreMockupCodeStyle` 에 테두리 색 필드가 없습니다). 배경색과 모서리로만 틀을 만듭니다.

<a id="마이그레이션-migration"></a>

## 옮겨 오기

이전 버전의 코드를 지금 API 로 바꿀 때 확인할 내용입니다.

### 상태 표시줄 · 홈 제스처 바 · 하드웨어 기본값

**제스처 바 길이의 단위가 바뀌었습니다.** `gestureBarHeight` · `gestureBarOffset` 은 논리 px 가 아니라 **iOS point** 이고, 기기 · 방향별 고정 배율로 그립니다. 폰 세로의 배율은 `144 / 402` 입니다. px 로 적었던 값은 같은 숫자로 그려지지 않습니다. 예를 들어 `gestureBarHeight: 4` 는 폰 세로에서 약 `1.43px` 로 그려지므로 값을 point 로 다시 정합니다.

```dart
// 이전 — 제스처 바를 화면 폭의 비율과 px 로 적었습니다.
MockupDevice(
  mockupDeviceStyle: CoreMockupDeviceStyle(
    gestureBarWidthRatio: 0.5,
    gestureBarHeight: 6,
  ),
  child: screenshot,
)

// 지금 — point 로 적으면 기기 · 방향별 고정 배율로 그립니다.
MockupDevice(
  mockupDeviceStyle: CoreMockupDeviceStyle(
    gestureBarWidth: 200,
    gestureBarHeight: 8,
  ),
  child: screenshot,
)
```

`gestureBarWidthRatio` 는 deprecated (since 0.154) 입니다. 정하면 막대를 계속 그 화면 폭 비율에 고정하고 `gestureBarWidth` 보다 우선하므로 동작은 유지되지만, 막대 길이는 비율이 아니라 point 로 적으세요. `CoreMockupDeviceStyle.defaultBezelWidth` · `defaultCameraCoreSize` · `defaultGestureBarWidthRatio` 도 deprecated (since 0.154) 입니다. 베젤 두께 · 코어 지름 · 막대 폭은 기기마다 다른 값이라 `CoreMockupDeviceStyle.defaultsByDevice[device]` 에서 읽습니다.

**기본 모양이 바뀌었습니다.** 값을 적지 않은 코드도 그림이 달라집니다.

- 상태 표시줄을 기본으로 그리고 위쪽 안전 여백을 비워 둡니다. 그 여백이 필요 없으면 `showStatusBar: false` 를 적습니다(폰은 카메라 몫의 여백만 남습니다).
- 홈 제스처 바가 `on-surface` 의 **불투명한** 막대입니다(이전에는 20%).
- 몸체가 단색이 아니라 그라디언트이고 림의 밝은 선과 번짐 빛, 베젤 윤곽과 안쪽 그림자, 폰의 안테나 띠가 생겼습니다. 레일 색(`railColor` 또는 공유 `frameColor`)을 정했다면 몸체는 계속 그 단색입니다.
- `buttonColor` 는 레일 색과 다른 값이며 광택 아래의 밑바탕 단색입니다.
- 하드웨어 기본값이 레일 `3`, 베젤 폰 `5` · 태블릿 `8`, 폰 카메라 `45 × 13` 알약, 버튼 두께 `2`, 돌출 `1.5` 로 바뀌었습니다.
- 태블릿은 비율이 `299 : 433`, 모서리가 `radius16` 이고 카메라가 화면 안이 아니라 위쪽 베젤 띠에 있습니다. 같은 `width` 에서 이전의 `3:4` 보다 깁니다.
- 가로로 돌린 폰의 카메라는 화면 위 가운데가 아니라 왼쪽 가장자리에 있습니다.

### 가로는 비율이 아니라 `orientation` 이 말한다

이전 `MockupDevice` 는 가로를 따로 두지 않고, `screenAspectWidth` 가 `screenAspectHeight` 보다 크면 가로로 읽었습니다. 지금은 **`orientation` 하나가 방향을 정하고**, 비율은 방향 없이 긴 변을 먼저 읽는 값입니다.

```dart
// 이전 — 비율을 뒤집어 가로를 만들었습니다.
MockupDevice(
  device: .tablet,
  mockupDeviceStyle: CoreMockupDeviceStyle(
    screenAspectWidth: 4,
    screenAspectHeight: 3,
  ),
  child: screenshot,
)

// 지금
MockupDevice(
  device: .tablet,
  orientation: .landscape,
  child: screenshot,
)
```

이전 방식으로 가로 비율을 적어 두었다면 그 기기는 이제 **세로로 그려집니다.** 비율을 긴 변부터 읽고 `orientation` 의 기본값이 `portrait` 이기 때문입니다. `orientation: .landscape` 를 적고 비율 값은 지우면 됩니다.

폰도 가로를 가집니다. 돌린 몸체는 버튼도 함께 옮기므로 폰 가로는 볼륨 버튼이 위, 전원 버튼이 아래입니다. 버튼을 좌우 변에 그대로 두던 이전 모습과 다릅니다.

### MockupPhone → MockupDevice

`MockupPhone` 은 `MockupDevice` 로 이름이 바뀌었습니다. `device` 의 기본값이 `phone` 이라 새 이름으로 바꾸기만 하면 폰을 그립니다. 이전 이름(`MockupPhone` 타입 별칭, `mockupPhoneStyle` 속성)은 두 플랫폼 어디에도 없으므로 아래처럼 고쳐야 컴파일됩니다.

```dart
// 이전
MockupPhone(
  mockupPhoneStyle: CoreMockupDeviceStyle(borderColor: CoreColor.token(CoreColors.outline)),
  child: screenshot,
)

// 지금
MockupDevice(
  mockupDeviceStyle: CoreMockupDeviceStyle(borderColor: CoreColor.token(CoreColors.outline)),
  child: screenshot,
)
```

**이름만 바꾸면 끝나지 않습니다.** 그림이 달라집니다.

- 기본 화면 비율이 `9:16` 에서 `9:19.5` 로 바뀌어 같은 `width` 에서 기기가 더 깁니다.
- 이전의 `innerPadding` 이 없습니다. 대신 `child` 는 보이는 장식이 비워 두는 안전 여백 안에 놓입니다.
- 카메라가 흐름에서 빠져 화면 위에 겹칩니다. 위쪽 베젤만 두껍던 비대칭이 없어졌습니다.
- 레일 · 림 · 베젤 · 버튼이 밝기 · 고대비 모드와 상관없는 고정 색이 되고, 몸체에 어느 모드에서나 검정인 그림자(`CoreMockupDeviceStyle.defaultBodyShadow`)가 생깁니다.

**사라진 필드와 대신 쓸 것**

| 이전 필드 | 대신 쓸 것 |
| --- | --- |
| `frameColor` | `railColor` |
| `outerPadding` | `railWidth` 와 `bezelWidth` (네 변이 같습니다) |
| `innerPadding` | 없음. 화면 여백은 안전 영역이 정합니다. |
| `screenBorderRadius` | 없음. `borderRadius − (railWidth + bezelWidth)` 로 계산합니다. |
| `cameraBorderRadius` | 없음. 카메라 짧은 변의 절반으로 계산합니다. |
| `cameraSize` | `cameraWidth` · `cameraHeight` |
| `cameraPadding` | `cameraOffset` (화면 위 가장자리에서의 거리) |
| `cameraColor` | 없음. 렌즈 링을 품은 컷아웃은 `cutoutColor`, 링이 없는 컷아웃은 `lensColor` |

위 표의 `frameColor` 는 이전 기기 스타일의 필드입니다. 목업 공유 스타일 `CoreMockupStyle` 의 `frameColor` 는 지금도 있습니다.

<a id="props-parameters"></a>

## API

`W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다. 컴포넌트마다 콘텐츠를 넣는 자리와 스타일 속성 하나가 있습니다.

### MockupBrowser

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `showControls` | `bool` | `true` | 툴바 왼쪽에 창 컨트롤 세 점을 그립니다. `false` 면 그 자리만큼 주소창이 넓어집니다. |
| `addressBar` | `String?` | `'example.com'` | 주소창에 보여 줄 글. `null` 이면 주소창 · 이전/다음 · 공유와 새 탭을 빼고 창 컨트롤만 남깁니다(데스크톱 앱 창). |
| `child` | `W?` | `null` | 창 안에 넣을 내용 |
| `mockupBrowserStyle` | `CoreMockupBrowserStyle?` | `null` | 창 몸체 · 툴바 · 콘텐츠 면의 겉모습 |

### MockupDevice

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `W` | 필수 | 카메라 · 상태 표시줄 · 홈 제스처 바를 피하는 안전 영역 안에 놓을 화면 내용 |
| `device` | `CoreMockupDevice` | `CoreMockupDevice.phone` | 그릴 기기 — `phone` · `tablet` |
| `orientation` | `CoreMockupOrientation` | `CoreMockupOrientation.portrait` | 기기를 든 방향 — `portrait` · `landscape` |
| `finish` | `CoreMockupDeviceFinish` | `CoreMockupDeviceFinish.realistic` | 마감 — `realistic`(기기 그림) · `flat`(장식 없는 미리보기 틀). 자세한 내용은 [MockupDevice](/components/mockup-device) |
| `width` | `double?` | `null → 마감별(realistic 320 · flat 256)` | 기기 본체 너비(logical px · Web px). 높이는 화면 비율과 베젤에서 계산합니다. |
| `showCamera` | `bool?` | `null → 마감을 따름` | 카메라 컷아웃 · 렌즈 · 코어를 보일지. 끄면 카메라가 비워 두던 안전 여백도 없어집니다. |
| `showStatusBar` | `bool?` | `null → 마감을 따름` | 화면 위쪽 상태 표시줄을 보일지. 끄면 위쪽 안전 여백 중 상태 표시줄 몫이 없어집니다. 가로로 돌린 폰은 상태 표시줄이 없어 이 값을 무시합니다. |
| `showGestureBar` | `bool?` | `null → 마감을 따름` | 홈 제스처 바를 보일지. 끄면 아래쪽 안전 여백도 없어집니다. |
| `screenBrightness` | `CoreBrightness?` | `null → 페이지의 밝기` | 화면과 그 위의 콘텐츠 · 상태 표시줄 · 홈 제스처 바를 그릴 밝기. 본체 · 베젤 · 버튼은 페이지의 밝기를 따릅니다. |
| `mockupDeviceStyle` | `CoreMockupDeviceStyle?` | `null` | 레일 · 베젤 · 화면 · 카메라 · 버튼 · 안테나 띠 · 상태 표시줄 · 제스처 바의 겉모습 |

겉모습을 바꾸는 속성은 `mockupDeviceStyle` 하나입니다. 이전 이름으로 호출하던 코드는 [옮겨 오기](#옮겨-오기)를 보세요.

### MockupCode

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `lines` | `List<CoreCodeLine>` | 필수 | 표시할 코드 줄. 아래 팩토리 생성자로 문자열에서 만들 수 있습니다. |
| `mockupCodeStyle` | `CoreMockupCodeStyle?` | `null` | 코드 블록의 겉모습 |

### 팩토리 생성자

| 이름 | 설명 |
| --- | --- |
| `MockupCode.fromString(code, {showLineNumbers = true, mockupCodeStyle})` | 문자열을 줄 바꿈으로 나눕니다. `showLineNumbers` 가 `true` 면 1부터 줄 번호를 `prefix` 로 붙이고, `false` 면 `prefix` 를 만들지 않습니다. 모든 줄의 `tone` 은 `neutral` 입니다. |
| `MockupCode.fromList(codeLines, {mockupCodeStyle})` | 넘긴 `CoreCodeLine` 목록을 그대로 씁니다. 줄마다 `tone` 을 정하려면 이쪽을 씁니다. |

두 팩토리는 `key` 도 받습니다. Web 의 팩토리는 `id` · `classes` · `css` · `attributes` 를 더 받고, `tag` · `eventHandlers` 는 받지 않습니다.

### 코드 줄 — CoreCodeLine

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `text` | `String` | 필수 | 줄의 코드나 출력 글 |
| `prefix` | `String?` | `null` | 줄 번호나 `+` · `-` 같은 접두 기호 |
| `tone` | `CoreCodeLineTone` | `CoreCodeLineTone.neutral` | 줄의 뜻. 글 색만 바꾸며 색은 `mockupCodeStyle` 의 tone 색 슬롯이 정합니다. |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(patch)` | 세 컴포넌트 모두에 있습니다. 지금 스타일에 `patch` 를 합친 사본을 돌려주며 겹치는 필드는 `patch` 가 이깁니다. |
| `copyWith(...)` | 바꾼 값으로 사본을 만듭니다. `MockupBrowser` 의 `addressBar` 는 함수로 받아, `copyWith(addressBar: () => null)` 로 앱 창으로 바꿀 수 있습니다. |

웹의 세 컴포넌트는 루트 요소에 적용되는 `tag`(기본 `'div'`) · `id` · `classes` · `css` · `attributes` · `eventHandlers` 도 받습니다.

### 테마

| 이름 | 타입 | 적용 대상 |
| --- | --- | --- |
| `CoreComponentTheme.mockup` | `CoreMockupTheme?` | 목업 공유 값(`style: CoreMockupStyle?`) |
| `CoreComponentTheme.mockupBrowser` | `CoreMockupBrowserTheme?` | `MockupBrowser` (`style`) |
| `CoreComponentTheme.mockupDevice` | `CoreMockupDeviceTheme?` | `MockupDevice` (`style` · `deviceStyles` · `finishStyles`) |
| `CoreComponentTheme.mockupCode` | `CoreMockupCodeTheme?` | `MockupCode` (`style`) |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreMockupStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Background color for the mockup content area. When null, each variant uses its own default (`surfaceContainerLow` on Code and on the Browser's window body, `surface` on the Device screen). |
| `borderColor` | `CoreColor?` | Border / outline color of the mockup frame. When null, each bordered variant uses its own default: `outlineVariant` on Browser, and on Device a hardware rim colour that stays the same in light and dark mode. Code has no border. |
| `frameColor` | `CoreColor?` | Frame fill color for the mockup outer shell (Device variant only — its body). |
| `borderRadius` | `CoreBorderRadius?` | Border radius override for the outer frame. When null, each variant uses its own default — `radius8` (Code), `radius14` (Browser), `radius24` / `radius16` (Device phone / tablet). |

<!-- STYLE_TABLE:END -->

<Note>

표의 `backgroundColor` 설명은 콘텐츠 영역이라고 하지만, `MockupBrowser` 에서는 콘텐츠 면 뒤의 창 몸체를 칠합니다. 기본 상태에서는 콘텐츠 면에 가려 보이지 않으므로 창 안의 색은 `contentBackgroundColor` 로 바꾸세요. `borderRadius` 설명에 없는 `flat` 마감의 기기 몸체 기본값은 `radius32` 입니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="mockup/related-mockup-browser" title="MockupBrowser">

주소창과 창 컨트롤이 있는 창 틀입니다. [MockupBrowser 문서](/components/mockup-browser)

</Card>
<Card demo="mockup/related-mockup-device" title="MockupDevice">

폰 · 태블릿 기기 틀입니다. [MockupDevice 문서](/components/mockup-device)

</Card>
<Card demo="mockup/related-mockup-code" title="MockupCode">

코드 편집기 모양의 틀입니다. [MockupCode 문서](/components/mockup-code)

</Card>
<Card demo="mockup/related-mockup-foldable" title="MockupFoldable">

가운데가 접히는 기기 틀이 필요할 때 씁니다. [MockupFoldable 문서](/components/mockup-foldable)

</Card>
<Card demo="mockup/related-card" title="Card">

기기 · 창 장식 없이 콘텐츠를 담는 면이 필요할 때 씁니다. [Card 문서](/components/card)

</Card>
<Card demo="mockup/related-code-snippet" title="CodeSnippet">

구문 강조가 있는 코드 블록이 필요할 때 씁니다. [CodeSnippet 문서](/components/code-snippet)

</Card>
</Cards>
