---
title: Mockup
description: 브라우저, 폰·태블릿, 코드 에디터 등 디바이스 프레임을 시뮬레이션하는 목업 컴포넌트
category: display
platforms: [flutter, web]
related: [mockup-browser, mockup-code, mockup-device, mockup-foldable, card, code-snippet]
tags: [mockup, device-frame, browser, presentation]
---

# Mockup

콘텐츠를 실제 디바이스나 앱 화면처럼 감싸는 목업 프레임 컴포넌트입니다. 문서, 랜딩 페이지, 스크린샷 등 시각적 프레젠테이션에 활용됩니다.

## Live Preview

<LivePreview component="mockup" variants="phone,tablet,landscape,browser,code,app" />

## 사용 시기 (When to Use)

**이 컴포넌트를 사용하세요:**
- 랜딩 페이지에서 앱/웹 화면을 디바이스 프레임 안에 표시할 때
- 기술 문서에서 코드 예제를 코드 에디터 스타일로 표시할 때
- 데모나 쇼케이스에서 스크린샷을 실제 기기처럼 보여줄 때

**대신 다른 컴포넌트를 사용하세요:**
- **[Card](/components/card)**: 기기·창 장식 없이 콘텐츠 표면만 필요할 때
- **[CodeSnippet](/components/code-snippet)**: 편집기 장식 대신 코드 선택·복사·구문 강조가 필요할 때

## 기본 사용법 (Basic Usage)

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
// 브라우저 목업
MockupBrowser(
  addressBar: 'https://coui.cocode.im',
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

// 코드 에디터 목업
MockupCode.fromString('void main() {\n  runApp(const MyApp());\n}')

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
  addressBar: 'https://coui.cocode.im',
  child: img(src: 'screenshot.png', alt: 'CoUI 디자인 시스템'),
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

// 코드 목업 (fromString 팩토리 생성자)
MockupCode.fromString(
  'npm i coui\ninstalling...\nDone!',
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

### 빠른 오버라이드 (Chain)

이미 만든 목업 인스턴스에 스타일을 빠르게 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 style 슬롯 인자와 동일하게 동작하지만, 이미 구성된 위젯 위에서 바로 이어 쓸 수 있습니다. `.radius8`/`.primary`처럼 Core 토큰 상수 이름과 똑같은 이름의 getter도 있습니다 — `withStyle`을 한 번 더 줄인 sugar로, 이름이 곧 값이라(radius8 == `CoreRadius.radius8`, primary == `CoreColors.primary`) 어느 컴포넌트에서 써도 뜻이 갈리지 않습니다. `MockupBrowser` / `MockupDevice` / `MockupCode` 세 컴포넌트 모두 동일한 `.radiusN` / `.colorName` 체인을 갖습니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
MockupBrowser(
  addressBar: 'https://coui.dev',
  child: Text('페이지 콘텐츠').bodyMedium.onSurface,
).radius8.primary
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
MockupBrowser(
  addressBar: 'https://coui.dev',
  child: Text('페이지 콘텐츠').bodyMedium.onSurface,
).radius8.primary
```

  </TabItem>
</Tabs>

### 카메라·상태 표시줄·홈 제스처 바 표시

Flutter와 Web 모두 `showCamera`, `showStatusBar`, `showGestureBar`로 각각 켜고 끕니다.
기본값은 셋 다 `true`이며 `phone`과 `tablet`에 동일하게 적용됩니다.
`showCamera: false`는 컷아웃·렌즈·코어 전체를 숨기고, `showStatusBar: false`는
화면 위쪽의 시계·신호·Wi-Fi·배터리 줄을, `showGestureBar: false`는 아래쪽의
홈 제스처 바를 숨깁니다. 세 옵션은 서로 독립이고, 각각 **장식과 그 장식이 확보하던
안전 여백**을 함께 제어합니다. 본체와 화면 크기는 유지됩니다.
`copyWith`나 스타일 체인을 사용해도 설정한 표시 여부가 유지됩니다.

```dart
MockupDevice(
  showCamera: false,
  showStatusBar: false,
  showGestureBar: false,
  child: Text('앱 화면'),
)
```

가로로 돌린 폰(`phone` + `orientation: .landscape`)은 상태 표시줄을 그리지 않습니다 —
실제 기기가 그 자세에서 숨기기 때문에 `showStatusBar` 를 켜도 달라지는 것이 없습니다.
태블릿은 두 방향 모두 상태 표시줄을 그립니다.

Figma에서는 `❖ MockupDevice` 인스턴스의 **Show camera**, **Show status bar**,
**Show gesture bar** BOOLEAN 프로퍼티로 조절합니다. **Show status bar** 는 상태
표시줄이 있는 변형(phone 세로 · tablet 두 방향)에만 연결되고, phone 가로 변형에는
상태 표시줄 자체가 없습니다. 화면에 담을 앱 화면은 `child` 와 같은 자리인
**Child** 교체(INSTANCE_SWAP) 프로퍼티로 넣습니다.

### 상태 표시줄과 홈 제스처 바

두 요소의 길이는 **iOS point** 로 저작하고, Figma의 기준 크기에서 정한 배율로 그립니다.
본체 너비를 바꿔도 높이·세로 위치·글자·아이콘·홈 바 크기는 유지되고 배치 영역만 늘어납니다.

- 배율은 `systemBarReferenceScale` / `landscapeSystemBarReferenceScale` 입니다.
  폰 세로는 `144 / 402`, 가로는 `312 / 874`, 태블릿은 두 방향 모두 `144 / 402` 입니다.
- 폰 상태 표시줄의 좌우 날개는 폭과 가장자리 여백을 유지하며 화면 양쪽 가장자리에 고정됩니다.
  날개 안의 콘텐츠는 가운데 정렬합니다. 태블릿의 두 그룹도 양쪽 가장자리에 붙습니다.
- `statusBar*` · `gestureBar*` 길이와 타이포그래피 역할의 글자 크기는 이 고정 배율로
  iOS point에서 논리 px로 변환합니다. 하드웨어 길이도 너비에 따라 확대하지 않습니다.
- 앱 테마의 배율은 별도로 적용됩니다. 여기서 유지하는 것은 목업의 `width` 변경 시 동작입니다.

상태 표시줄은 불투명하게 그립니다. 바탕은 화면의 `backgroundColor` 이고, 자식 위에 놓이며
카메라 **뒤**에 놓입니다 — 폰의 카메라 알약이 상태 표시줄 안에 앉습니다. 구성은 기기마다 다릅니다.

| | 왼쪽 | 오른쪽 |
|---|------|--------|
| `phone` | 시계 `9:41` | 신호 · Wi-Fi · 배터리 (바깥 윤곽 · 레벨 · 꼭지) |
| `tablet` | 시계 `9:41` `오전` · 날짜 `4월 1일 수요일` | Wi-Fi · `100%` · 배터리 |

표시되는 시각·날짜·배터리 문구는 캡처한 한 순간의 화면이라 로케일을 따르지 않고 호출자가
바꾸는 입력도 아닙니다. 신호·Wi-Fi·배터리 글리프는 벡터 경로(`CoreVectorGlyph`)이며
양 플랫폼이 같은 경로 데이터를 그립니다.

홈 제스처 바는 `on-surface` 색의 **불투명** 막대입니다. 막대만 그리고 영역의 바탕은
그리지 않습니다 (화면이 이미 같은 색입니다). 막대는 가로 가운데에서 화면 아래 가장자리로부터
`gestureBarOffset` 만큼 떨어져 놓이고, 모서리는 높이의 절반보다 조금 작은 반경입니다 (알약이 아닙니다).

### 카메라 · 안테나 띠

카메라는 기기에 따라 서로 다른 공간에 앉습니다 (`cameraPlacement`).

| | 폰 | 태블릿 |
|---|----|--------|
| 위치 | 화면을 파낸 알약 — `screen` | 화면 위 베젤 띠 안의 작은 원 — `bezel` |
| 크기 | 알약 `45 × 13`, 화면 위에서 `4` | 원 `4 × 4`, 베젤 띠 위에서 `2`, 가로 가운데 |
| 렌즈 | 알약 오른쪽 끝에 렌즈 링 `6.5` + 코어 `3.9` | 링 없음 — 원 자체가 렌즈, 안에 코어 `2.4` |
| 가로 | 세운 자세를 **반시계로 돌려** 화면 **왼쪽 가장자리**에 세로 알약(`13 × 45`)으로 서고 렌즈가 위쪽 끝으로 간다 | 방향과 무관하게 위쪽 베젤 띠 가운데 |

코어에는 방사형 그라디언트(`coreGradient`)와 왼쪽 위의 작은 하이라이트가 있습니다.
하이라이트는 코어 지름의 비율로 저작하고 카메라를 돌려도 같이 돌지 않습니다.
`cutoutColor` 를 말하면 코어도 그 단색이 됩니다 — 말하지 않으면 그라디언트입니다.

안테나 띠는 **폰에만** 있습니다. 길이 `1.9`, 두께는 레일 폭(`railWidth`)과 같아서 베젤
바깥의 몸체 고리를 정확히 가로지르고, 한 변에 하나 또는 두 개씩 모두 여섯 개입니다. 가로로
돌리면 같은 띠들이 같은 끝·같은 거리를 지킨 채 변만 시계 방향으로 한 칸 옮겨 갑니다
(회전한 좌표가 아닙니다). 태블릿은 `antennaBandLength: 0` 이라 띠가 없습니다.

### 자식 콘텐츠의 SafeArea

자식은 목업의 카메라·상태 표시줄·홈 제스처 바를 피하는 안전 영역 안에 배치됩니다.
네 변의 여백은 각각 **자기 장식이 보일 때만** 확보됩니다.

| 변 | 여백 |
|----|------|
| 위 | 상태 표시줄이 보이면 그 높이, 카메라가 **화면의 위쪽 가장자리를 파고** 있으면 카메라 아래쪽 끝 + 같은 간격 — 둘 중 큰 쪽 |
| 왼쪽 | 카메라가 **화면의 왼쪽 가장자리에** 서 있을 때(가로로 돌린 폰)만 카메라의 안쪽 끝 + 같은 간격 |
| 아래 | 홈 제스처 바가 보이면 영역 높이(`gestureBarAreaHeight`)와 막대가 차지하는 높이 중 큰 쪽 |
| 오른쪽 | 항상 `0` |

태블릿의 카메라는 화면 밖 베젤에 있어 위 여백에 기여하지 않고, 태블릿의 위 여백은 상태
표시줄 높이입니다. 각 표시 옵션은 자기 여백만 풀어 줍니다 — 상태 표시줄을 끄면 폰은
카메라가 요구하는 여백으로, 태블릿은 `0` 으로 줄어듭니다. 여백은 하드웨어처럼 기기에
고정된 **물리** 방향(왼쪽 · 오른쪽)이며 텍스트 방향을 따라 뒤집히지 않습니다. 상태 표시줄의
두 그룹도 같아서, 문서가 RTL 이어도 항목 순서와 간격이 왼쪽에서 오른쪽으로 그대로 놓입니다.
`mockupDeviceStyle`로 하드웨어 크기·위치를 바꾸거나 테마 배율을 바꾸면
안전 영역도 함께 계산됩니다. 렌즈나 코어를 키워 카메라가 더 깊이 들어오면 그만큼
여백도 커집니다.

Flutter에서는 목업 화면 기준 `MediaQuery`와 `SafeArea`를 사용합니다.
호스트 기기의 노치·키보드 여백은 섞이지 않고, 자식이 다시 `SafeArea`를
사용해도 여백이 중복되지 않습니다. Web은 동일한 계산의 콘텐츠 패딩을,
Figma는 표시 옵션에 연결된 Auto Layout 여백을 사용합니다.

### SafeArea와 자식 배경색 맞추기

`mockupDeviceStyle.backgroundColor`는 **자식 뒤의 화면 전체** — SafeArea 여백과 그 위에
놓이는 상태 표시줄의 바탕까지 — 를 칠합니다. 기본값은 테마의 `surface`이며, 자식에 별도
배경이 있다면 같은 색을 지정하면 됩니다. 자식의 불투명한 배경색을 자동으로 추론하지는 않습니다.

```dart
// Flutter와 Web에 동일한 API를 사용합니다.
MockupDevice(
  mockupDeviceStyle: const CoreMockupDeviceStyle(
    backgroundColor: CoreColor(0xFFFFE0B2),
  ),
  child: Text('앱 화면'),
)
```

자식을 투명하게 두면 위 배경을 그대로 공유합니다. 반투명 색도 MockupDevice에
한 번만 칠해야 콘텐츠 부분이 이중 합성되어 SafeArea보다 진해지지 않습니다.
Widgetbook의 `backgroundColor` 색상 컨트롤에서 바로 확인할 수 있습니다.
Figma에서도 `screen`의 Fill이 콘텐츠와 투명한 SafeArea 여백 뒤까지 이어집니다.

## Props / Parameters

`W` 는 Flutter의 Widget / Web의 Jaspr Component입니다. 각 목업은 조립용 콘텐츠 슬롯과 자신만의 스타일 슬롯을 제공합니다.

각 목업은 별도의 통일 컴포넌트 (`MockupBrowser` / `MockupDevice` /
`MockupCode`) 로 제공됩니다. 겉모습 · 색 · 모서리 반경을 바꾸는 값은
모두 각 컴포넌트의 `*Style` 슬롯 하나로 넣습니다. 데스크톱 앱 창은 별도
컴포넌트가 아니라 `MockupBrowser(addressBar: null)` 입니다.

### MockupBrowser

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `showControls` | `bool` | `true` | 툴바 왼쪽에 창 컨트롤 세 점을 그립니다. `false` 면 그 자리만큼 주소창이 넓어집니다 |
| `addressBar` | `String?` | `'example.com'` | 주소창에 표시할 텍스트. `null` 이면 주소창 · 이전/다음 · 액션 아이콘을 트리에서 빼고 창 컨트롤만 남깁니다 (데스크톱 앱 창) |
| `child` | `W?` | `null` | 콘텐츠 카드 안에 들어갈 내용 |
| `mockupBrowserStyle` | `CoreMockupBrowserStyle?` | `null` | 창 몸체 · 툴바 · 콘텐츠 카드의 겉모습 · 색 · 모서리 반경을 바꾸는 값 묶음 |

### MockupDevice

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `child` | `W` | 필수 | 목업 카메라·상태 표시줄·홈 제스처 바를 피하는 안전 영역 안에 배치할 화면 내용 |
| `device` | `CoreMockupDevice` | `CoreMockupDevice.phone` | 그릴 기기 — `phone` · `tablet` |
| `orientation` | `CoreMockupOrientation` | `CoreMockupOrientation.portrait` | 기기를 든 방향 — `portrait` · `landscape` |
| `finish` | `CoreMockupDeviceFinish` | `CoreMockupDeviceFinish.realistic` | 마감 — `realistic`(기기 그림) · `flat`(장식 없는 미리보기 틀). 자세한 내용은 [MockupDevice](/components/mockup-device) |
| `width` | `double?` | `null → 마감별(realistic 320 · flat 256)` | 기기 본체 폭 (logical px / Web px). 높이는 화면 비율과 베젤에서 파생된다 |
| `showCamera` | `bool?` | `null → 마감을 따름` | 카메라 컷아웃·렌즈·코어 전체의 표시 여부. realistic 은 켜고 flat 은 끈다. 끄면 카메라가 확보하던 안전 여백도 해제한다 |
| `showStatusBar` | `bool?` | `null → 마감을 따름` | 화면 위쪽 상태 표시줄(시계·신호·Wi-Fi·배터리)의 표시 여부. realistic 은 켜고 flat 은 끈다. 끄면 상단 안전 여백도 해제한다. 가로로 돌린 폰은 상태 표시줄이 없어 이 값을 무시한다 |
| `showGestureBar` | `bool?` | `null → 마감을 따름` | 홈 제스처 바의 표시 여부. realistic 은 켜고 flat 은 끈다. 끄면 하단 안전 여백도 해제한다 |
| `mockupDeviceStyle` | `CoreMockupDeviceStyle?` | `null` | 레일·베젤·화면·카메라·버튼·안테나 띠·상태 표시줄·제스처 바의 겉모습을 바꾸는 값 묶음 |

겉모습을 바꾸는 곳은 `mockupDeviceStyle` 하나뿐이다. 옛 이름으로 호출하던 코드는 아래 [마이그레이션](#마이그레이션-migration) 을 보세요.

### MockupCode

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `lines` | `List<CoreCodeLine>` | 필수 | 표시할 코드 라인 (factory 생성자로 문자열에서 변환 가능) |
| `mockupCodeStyle` | `CoreMockupCodeStyle?` | `null` | 코드 블록의 겉모습을 바꾸는 값 묶음 (아래 표) |

## 스타일 시스템 (Style System)

세 목업 컴포넌트는 각자 전용 Style 슬롯을 갖습니다. `CoreMockupTheme.style`
(`CoreMockupStyle`)은 목업들이 함께 쓰는 공통 겉모습 값이며,
값이 정해지는 순서에서 컴포넌트별 Theme 보다 앞에 놓입니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreMockupStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Background color for the mockup content area. When null, each variant uses its own default (`surfaceContainerLow` on Code and on the Browser's window body, `surface` on the Device screen). |
| `borderColor` | `CoreColor?` | Border / outline color of the mockup frame. When null, each bordered variant uses its own default: `outlineVariant` on Browser, and on Device a hardware rim colour that stays the same in light and dark mode. Code has no border. |
| `frameColor` | `CoreColor?` | Frame fill color for the mockup outer shell (Device variant only — its body). |
| `borderRadius` | `CoreBorderRadius?` | Border radius override for the outer frame. When null, each variant uses its own default — `radius8` (Code), `radius14` (Browser), `radius24` / `radius16` (Device phone / tablet). |

<!-- STYLE_TABLE:END -->

### CoreMockupBrowserStyle

콘텐츠(`surface`)는 창 전체를 채우고, 툴바가 그 위에 절대 위치로 겹칩니다. 툴바는 `surfaceContainerLow` 88% 채움과 배경 블러 20, `surfaceContainer` 아래 구분선을 사용합니다. 탐색과 공유·새 탭 그룹은 높이 28의 캡슐이고 주소창에는 자물쇠와 새로고침 아이콘이 있습니다. 창 맨 위 레이어가 `outlineVariant` 1px 테두리와 흰색 35% 안쪽 하이라이트를 그립니다. `child`가 없으면 툴바 높이만 남습니다. 예제와 Figma 프리뷰 크기는 380×200이며 컴포넌트는 부모 크기를 따릅니다.

| 슬롯 | 타입 | 기본값 | 비고 |
|------|------|--------|------|
| `backgroundColor` | `CoreColor?` | `surfaceContainerLow` | 창 몸체 채움. |
| `borderColor` | `CoreColor?` | `outlineVariant` | 창 몸체 테두리 colour. |
| `borderWidth` | `double?` | `CoreStrokeWidth.stroke1` | 창 몸체 테두리 두께 (logical px). |
| `borderRadius` | `CoreBorderRadius?` | `radius14` | 창 몸체 모서리. |
| `boxShadow` | `List<CoreShadowLayer>?` | 2단 그림자 (14/28/−5, 6/10/−3; 8%/5%) | 창 몸체 그림자. 빈 리스트면 그림자 없음. |
| `chromeWidth` | `double?` | `CoreSpace.space0` | 몸체 바깥 가장자리에서 콘텐츠 카드까지의 좌 · 우 · 하 두께 (logical px). 테두리는 이 안쪽에 그려집니다. |
| `contentBackgroundColor` | `CoreColor?` | `surface` | 콘텐츠 카드 채움. |
| `contentBorderRadius` | `CoreBorderRadius?` | 파생 | 콘텐츠 카드 모서리. 비워 두면 `borderRadius − chromeWidth` (모서리별, 0 하한) 로 몸체와 동심을 유지합니다. |
| `toolbarHeight` | `double?` | `CoreSpace.space44` | 몸체 바깥 가장자리에서 잰 툴바 높이 (logical px). |
| `toolbarPadding` | `CoreEdgeInsets?` | 좌우 `space12` | 툴바 내부 패딩. 좌 · 상 · 우 변은 몸체 바깥 가장자리에서 잽니다. |
| `toolbarSpacing` | `double?` | `CoreSpace.space8` | 툴바 그룹(컨트롤 · 이전/다음 · 주소창 · 액션) 사이 간격. |
| `controlSize` | `double?` | `CoreSize.size8` | 창 컨트롤 점 지름. |
| `controlSpacing` | `double?` | `CoreSpace.space6` | 창 컨트롤 점 사이 간격. |
| `controlBorderRadius` | `CoreBorderRadius?` | `radius9999` | 창 컨트롤 점 모서리. |
| `controlCloseColor` / `controlMinimizeColor` / `controlMaximizeColor` | `CoreColor?` | `error` / `warning` / `success` | 창 컨트롤 색. 활성 테마를 따릅니다. |
| `navSpacing` | `double?` | `CoreSpace.space8` | 이전 · 다음 chevron 사이 간격. |
| `navIconStyle` | `CoreIconStyle?` | 12 · `onSurfaceVariant` | 이전 chevron 아이콘. |
| `navDisabledIconStyle` | `CoreIconStyle?` | 12 · `disabledContent` | 다음 chevron 아이콘 (비활성 표현). |
| `actionIconStyle` | `CoreIconStyle?` | 12 · `onSurfaceVariant` | 공유 · 새 탭 아이콘. |
| `addressBarHeight` | `double?` | `CoreSpace.space28` | 주소창 높이 (logical px). |
| `addressBarPadding` | `CoreEdgeInsets?` | 좌우 `space8` | 주소창 내부 패딩. |
| `addressBarBorderRadius` | `CoreBorderRadius?` | `radius9999` | 주소창 모서리. |
| `addressBarBackgroundColor` | `CoreColor?` | `surfaceContainer` 70% | 주소창 채움. |
| `addressBarTextStyle` | `CoreTextStyle?` | `labelSmall` · `onSurfaceVariant` | 주소창 텍스트 타이포그래피 (색 포함). |
| `addressBarTextAlign` | `CoreTextAlign?` | `center` | 주소창 텍스트 정렬. |
| `toolbarBackgroundColor` | `CoreColor?` | `surfaceContainerLow` 88% | 오버레이 채움. |
| `toolbarBorderColor` / `toolbarBorderWidth` | `CoreColor?` / `double?` | `surfaceContainer` / `stroke1` | 툴바 아래 구분선. |
| `toolbarBlur` | `double?` | 20 | 배경 블러. |
| `capsuleBackgroundColor` | `CoreColor?` | `surfaceContainer` 70% | 탐색 · 액션 캡슐 채움. |
| `capsuleBorderRadius` / `capsulePadding` / `capsuleHeight` | radius / insets / double | `radius9999` / 좌우 `space8` / `space28` | 탐색 · 액션 캡슐 기하. |
| `actionSpacing` | `double?` | `space8` | 공유 · 새 탭 간격. |
| `addressBarSpacing` / `domainSpacing` | `double?` | `space6` / 3 | 주소창 슬롯 · 자물쇠와 도메인 간격. |
| `addressIconStyle` | `CoreIconStyle?` | 10 · `onSurfaceVariant` | 자물쇠 · 새로고침. |
| `contentTextStyle` | `CoreTextStyle?` | `bodySmall` · `onSurfaceVariant` | 자식의 기본 타이포그래피. |
| `highlightColor` / `highlightWidth` | `CoreColor?` / `double?` | 흰색 35% / `stroke1` | 안쪽 위 하이라이트. |

### CoreMockupDeviceStyle

기기 목업은 숫자 묶음이 아니라 규칙 하나로 그려진다 — 베젤은 사방 균일한 inset(`railWidth + bezelWidth`)이고, 베젤·화면 radius 는 본체 radius 에서 파생되어 동심을 이루며, 버튼이 어느 변에 붙는지는 `orientation` 에서 파생된다(세운 자세를 시계방향 90° 회전). 그래서 `bezelRadius`·`screenRadius` 같은 필드는 없다. 카메라 컷아웃 색도 필드가 아니다 — 렌즈 링을 품은 컷아웃은 화면에 뚫린 구멍이라 `cutoutColor` 를, 링이 없는 컷아웃은 그 자체가 렌즈라 `lensColor` 를 받는다.

색과 길이에는 두 종류가 있다.

- **하드웨어** — 레일·림·베젤·버튼·카메라·안테나 띠. 색은 **디자이너 사본의 값을 그대로 적은 리터럴**이라 밝기·고대비 모드와도, 앱의 팔레트와도 무관하고(실제 기기는 다크 모드에서 색이 바뀌지 않고, 앱의 브랜드 색으로 칠해져 있지도 않다) 길이는 논리 px 입니다. 몸체 채움 · 림 · 베젤 · 버튼 밑바탕 · 렌즈 · 코어 · 안테나 띠가 여기에 속합니다. 버튼 광택 · 림 글로 · 베젤 안쪽 그림자 · 버튼 두께 음영 · 몸체 드롭 섀도는 흰색이나 검정을 알파로 겹친 광학 효과이고, 역시 리터럴입니다. 몸체 아래 그림자는 어느 모드에서나 검정입니다.
- **운영체제 화면** — 화면 채움·상태 표시줄·홈 제스처 바. 색은 활성 테마(`surface` · `on-surface`)를 따르고 `statusBar*` · `gestureBar*` 길이는 iOS point이며 기기·방향별 고정 배율로 그립니다.

하드웨어 색은 시맨틱 슬롯을 읽지 않습니다. 그래서 모드를 바꾸면 화면 · 상태 표시줄 · 홈 제스처 바만 바뀌고 기기는 그대로이며, 브랜드 팔레트를 쓰는 앱에서도 기기 색은 같습니다. 기기 색을 바꾸려면 아래 슬롯에 색을 직접 넘깁니다.

몸체 채움은 그라디언트가 기본입니다. `railColor` (목업 공유 `frameColor` 포함)를 말하면 몸체가 그 단색이 되고, `railGradient` 를 말하면 `railColor` 보다 우선합니다. 코어 채움도 같은 규칙입니다 — `cutoutColor` 를 말하면 단색, `coreGradient` 를 말하면 그라디언트입니다.

#### 몸체 · 림

| 슬롯 | 타입 | 기본값 | 비고 |
|------|------|--------|------|
| `backgroundColor` | `CoreColor?` | `surface` | 자식과 SafeArea 여백 뒤, 상태 표시줄 바탕까지의 화면 채움. 테마를 따른다. |
| `railGradient` | `CoreGradient?` | 위→아래 `#C3C4C6` · `#7D7F82` · `#7D7F82` · `#AEAFB2` (0 · 0.1 · 0.9 · 1) | 몸체 채움. 가로·세로 모두 위→아래. `railColor` 보다 우선한다. |
| `railColor` | `CoreColor?` | `#7D7F82` | 몸체를 단색으로 만든다. 말했을 때만 그려진다. 기본값은 그라디언트의 가운데 색이다. |
| `borderRadius` | `CoreBorderRadius?` | 기기별 | 본체 radius. 베젤은 `− railWidth`, 화면은 `− inset` 으로 파생. |
| `railWidth` | `double?` | `3` | 몸체 가장자리에서 베젤까지의 고리 두께. 림과 안테나 띠가 이 안에 놓인다. |
| `borderColor` | `CoreColor?` | `#646568` | 림 stroke — 몸체 안쪽 가장자리. |
| `borderWidth` | `double?` | `CoreStrokeWidth.stroke1` | 림 stroke 두께. |
| `rimHighlightColor` | `CoreColor?` | `#FFFFFF` | 림 바로 안쪽의 밝은 헤어라인. |
| `rimHighlightWidth` | `double?` | `0.5` | 박스 안쪽으로 그린다. |
| `rimHighlightInset` | `double?` | `0.4` | 몸체의 위·아래 가장자리에서만 들여 쓴다 (왼쪽·오른쪽은 그대로). 모서리 radius 는 몸체의 것을 줄이지 않는다. |
| `rimGlowGradient` | `CoreGradient?` | 위→아래 `#FFFFFF` → 투명 (0 → 0.51) | 림 글로 stroke. 방향은 가로·세로 모두 위→아래. 흰색이 투명으로 사라지는 광학 효과라 모드와 무관하다. |
| `rimGlowOpacity` | `double?` | `CoreOpacity.opacity50` | stroke 전체에 거는 불투명도 (stop 마다 곱하지 않는다). |
| `rimGlowWidth` | `double?` | `0.6` | 박스 안쪽으로 그린다. |
| `rimGlowTopInset` | `double?` | `0.8` | 몸체의 위 가장자리에서만 들여 쓴다. |
| `rimGlowBottomInset` | `double?` | `0.4` | 몸체의 아래 가장자리에서만 들여 쓴다. 림 하이라이트와 같은 값이라 두 stroke 가 같이 끝난다. |
| `rimGlowBlur` | `double?` | `0.8` | 글로 stroke 에만 거는 레이어 블러 반경. |

#### 베젤 · 화면

| 슬롯 | 타입 | 기본값 | 비고 |
|------|------|--------|------|
| `bezelWidth` | `double?` | 기기별 | 베젤 두께. 화면 inset 은 `railWidth + bezelWidth`. |
| `bezelColor` | `CoreColor?` | `#000000` | 베젤 채움. |
| `bezelBorderColor` | `CoreColor?` | `#27282B` | 베젤 박스 **바깥**(레일 위)에 그리는 윤곽선. |
| `bezelBorderWidth` | `double?` | `0.5` | 그림의 선이라 서피스 스타일의 stroke 바닥값이 올리지 않는다 (림 stroke · 배터리 윤곽선도 같다). |
| `bezelInnerShadowColor` | `CoreColor?` | `#FFFFFF` 16% (`0x29FFFFFF`) | 베젤 안쪽 그림자. 유리에 흰색을 알파로 겹친 광학 효과라 모드와 무관하다. 알파를 색에 담는다. 오프셋은 `(0, 0)`. |
| `bezelInnerShadowBlur` | `double?` | `0.5` | |
| `bezelInnerShadowSpread` | `double?` | `0.3` | |
| `screenAspectWidth` / `screenAspectHeight` | `double?` | 기기별 | 화면 비율의 두 항. **방향은 말하지 않는다** — 긴 변 먼저 읽는 비례이고, 어느 쪽이 길어지는지는 `orientation` 이 정한다. |
| `containerStyle` | `CoreOutlinedContainerStyle?` | 그림자 `CoreShadow.xl`, 그림자 색 `#000000` | 합성한 `OutlinedContainer` 본체에 넘기는 안쪽 부품의 스타일. 몸체 채움은 `railGradient` · `railColor` 가 정한다. 그림자 색(`shadowBaseColor`)은 검정 리터럴이라 Dark 에서도 흰 빛무리가 생기지 않는다. |

#### 카메라

| 슬롯 | 타입 | 기본값 | 비고 |
|------|------|--------|------|
| `cameraPlacement` | `CoreMockupCameraPlacement?` | 기기별 | `screen` 은 화면을 파낸 알약, `bezel` 은 화면 위 베젤 띠 안. 카메라 부품이 놓이는 공간을 정한다. |
| `cameraWidth` / `cameraHeight` | `double?` | 기기별 | 세워 든 알약의 긴 변 · 짧은 변. |
| `cameraOffset` | `double?` | 기기별 | 카메라가 앉은 공간(화면 또는 베젤 박스)의 위 가장자리에서의 거리. 돌린 폰은 화면의 **왼쪽** 가장자리에서 잰다. |
| `lensSize` / `lensOffset` | `double?` | 기기별 | 렌즈 링 지름 · 알약 끝에서의 거리 (세운 자세는 오른쪽 끝, 돌린 폰은 위쪽 끝). `lensSize: 0` 이면 링 없음. |
| `cameraCoreSize` | `double?` | 기기별 | 렌즈 코어 지름. |
| `lensColor` | `CoreColor?` | `#000000` | 렌즈 링, 또는 링이 없을 때 컷아웃 자체. |
| `cutoutColor` | `CoreColor?` | `#000000` | 렌즈 링을 품은 컷아웃. 말하면 코어도 이 단색이 된다. |
| `coreGradient` | `CoreGradient?` | 방사형 `#000000` · `#0A3348` · `#0C3B52` · `#105171` · `#0C3B52` · `#000000` (0.2 · 0.35 · 0.5 · 0.62 · 0.8 · 1) | 코어 채움 — 코어 박스의 중심에서 가장자리까지. 가운데가 검정, 그 둘레가 파란 유리 광택, 가장자리가 다시 검정이다. |
| `lensHighlightColor` | `CoreColor?` | `#FFFFFF` | 코어 위의 반짝임. |
| `lensHighlightSizeRatio` | `double?` | `4/15` | 코어 지름 대비 하이라이트 지름. |
| `lensHighlightOffsetXRatio` / `lensHighlightOffsetYRatio` | `double?` | `2/15` · `1/15` | 코어의 왼쪽·위쪽에서 하이라이트까지의 거리, 코어 지름 대비. 자세와 무관하게 왼쪽 위에 놓인다. |

#### 하드웨어 버튼

| 슬롯 | 타입 | 기본값 | 비고 |
|------|------|--------|------|
| `buttonColor` | `CoreColor?` | `#AEAFB2` | 버튼 밑바탕 단색 — 그 위에 광택 두 겹이 올라간다. 몸체를 따라가지 않는 자기 색이다. |
| `buttonLengthGradient` | `CoreGradient?` | 8 stop, 위→아래로 저작 — 양 끝 가까이에 밝은 띠와 어두운 띠 (흰색 · 검정 알파 리터럴) | 길이 방향 광택. 세로 버튼은 위→아래, 가로 버튼은 왼쪽→오른쪽으로 돌려 쓰므로 `begin` · `end` 는 읽지 않는다. |
| `buttonDepthColor` | `CoreColor?` | `#000000` 35% | 두께 방향 음영 — 몸체에 가까운 쪽이 이 색이고 먼 쪽은 투명. |
| `buttonThickness` / `buttonProtrusion` | `double?` | `CoreStrokeWidth.stroke2` · `1.5` | 버튼 두께 · 본체 밖으로 돌출하는 거리. 나머지(`0.5`)는 몸체 뒤로 들어간다. |
| `powerButtonLength` / `powerButtonOffset` | `double?` | 기기별 | 세워 든 자세의 전원 버튼 길이 · 위치(변 길이 대비 비율). |
| `volumeButtonLength` / `volumeButtonOffset` | `double?` | 기기별 | 세워 든 자세의 볼륨 버튼 길이 · 위치(비율). |
| `volumeButtonSpacing` | `double?` | 기기별 | 두 볼륨 버튼 사이 간격. `0` 이면 버튼 하나. |
| `landscapePowerButtonLength` / `landscapePowerButtonOffset` | `double?` | 기기별 | `orientation: .landscape` 일 때의 전원 버튼 길이 · 위치(비율). |
| `landscapeVolumeButtonLength` / `landscapeVolumeButtonOffset` | `double?` | 기기별 | 같은 자세의 볼륨 버튼. |

버튼이 **어느 변**에 붙는지는 파생되고(세운 자세를 시계방향으로 한 변씩 돌린다), 그 변을 따라 **얼마나 들어가는지**와 **얼마나 긴지**만 `landscape*` 필드에서 적는다 — 캔버스가 그 자리를 회전이 아니라 눈으로 잡기 때문이다. 태블릿의 가로 버튼은 세로 버튼과 길이도 다르다.

#### 안테나 띠

| 슬롯 | 타입 | 기본값 | 비고 |
|------|------|--------|------|
| `antennaBandLength` | `double?` | 기기별 | 띠 길이. `0` 이면 띠 없음. 두께는 `railWidth`. |
| `antennaGradient` | `CoreGradient?` | 위→아래 `#FCFCFD` → `#E4E5E7` | 띠 하나하나의 위→아래 (눕힌 띠도 자기 기준). |
| `antennaOpacity` | `double?` | `0.7` | 띠 하나에 거는 불투명도. |
| `antennaSideNearOffset` / `antennaSideFarOffset` | `double?` | `35.782` · `35.745` | 세운 자세에서 양쪽 변 띠 두 쌍이 위쪽 끝 · 아래쪽 끝에서 떨어진 거리. 캔버스가 위아래 대칭이 아니라 서로 다른 값이다. |
| `antennaTopOffset` / `antennaBottomOffset` | `double?` | `35.659` · `31.549` | 윗변 띠(오른쪽 끝에서) · 아랫변 띠(왼쪽 끝에서)의 거리. |

#### 상태 표시줄

길이는 모두 iOS point 입니다. 높이·위치·간격은 기기마다 다르고, 시각·날짜·배터리 문구와 글리프 모양은 필드가 아니라 고정 상수입니다.

| 슬롯 | 타입 | 기본값 | 비고 |
|------|------|--------|------|
| `systemBarReferenceWidth` / `landscapeSystemBarReferenceWidth` | `double?` | 기기별 | 상태 표시줄·홈 제스처 바를 저작한 폭 (세운 자세 · 돌린 자세). 기준 iOS 폭. 0 이하이면 시스템 바 배율이 0이 된다. |
| `systemBarReferenceScale` / `landscapeSystemBarReferenceScale` | `double?` | 기기별 | iOS point를 논리 px로 변환하는 고정 배율. 본체 너비와 독립적이다. |
| `statusBarHeight` / `landscapeStatusBarHeight` | `double?` | 기기별 | 상태 표시줄 높이. `0` 이면 그리지 않는다 (폰 가로). |
| `statusBarInset` | `double?` | 기기별 | 화면 옆 가장자리에서 첫·마지막 그룹까지. |
| `statusBarContentCenter` | `double?` | 기기별 | 막대 위쪽에서, 모든 글자와 글리프가 가운데 놓이는 선까지의 거리. |
| `statusBarWingWidth` | `double?` | 기기별 | `0` 보다 크면 각 그룹이 고정 폭의 박스 안에 가운데 정렬된다(폰). 박스는 화면 가장자리에 고정된다. `0` 이면 두 그룹이 양쪽 가장자리에 붙는다(태블릿). |
| `statusBarTrailingInset` | `double?` | 기기별 | 오른쪽 날개가 바깥쪽에 더 비워 두는 거리. 날개가 있을 때만 의미가 있다. |
| `statusBarTrailingSpacing` | `double?` | 기기별 | 오른쪽 그룹 항목 사이 간격. |
| `statusBarClockSpacing` | `double?` | `CoreSpace.space2` | 시계와 AM/PM 사이 (태블릿). |
| `statusBarLeadingSpacing` | `double?` | `CoreSpace.space8` | 시계 묶음과 날짜 사이 (태블릿). |
| `statusBarTextStyle` | `CoreTextStyle?` | 기기별 — 폰 `titleSmall`, 태블릿 `labelLarge` + `on-surface` | 시계·날짜·배터리 문구. 역할과 색으로 저작하고, 글자 크기가 기기·방향별 고정 배율로 줄어든다. |
| `statusBarIconColor` | `CoreColor?` | `on-surface` | 신호·Wi-Fi 글리프, 폰 배터리의 레벨, 태블릿 배터리. |
| `statusBarBatteryBorderColor` | `CoreColor?` | `on-surface` 35% | 폰 배터리의 바깥 윤곽. |
| `statusBarBatteryCapColor` | `CoreColor?` | `on-surface` 40% | 폰 배터리의 꼭지. |

#### 홈 제스처 바

길이는 모두 iOS point 입니다.

| 슬롯 | 타입 | 기본값 | 비고 |
|------|------|--------|------|
| `gestureBarColor` | `CoreColor?` | `on-surface` | 막대 색. 불투명. |
| `gestureBarWidth` / `landscapeGestureBarWidth` | `double?` | 기기별 | 막대 폭 (세운 자세 · 돌린 자세). |
| `gestureBarHeight` | `double?` | `5` | 막대 두께. |
| `gestureBarOffset` | `double?` | `CoreSpace.space8` | 화면 아래 가장자리에서 막대 아랫변까지. |
| `gestureBarRadius` | `double?` | `CoreRadius.radius2` | 막대 모서리. 높이의 절반보다 조금 작아서 끝이 둥글 뿐 알약은 아니다. |
| `gestureBarAreaHeight` / `landscapeGestureBarAreaHeight` | `double?` | 기기별 | 보이는 막대가 아래 안전 여백으로 확보하는 영역 높이. |
| `gestureBarWidthRatio` | `double?` | 없음 | **Deprecated (since 0.154)** — 막대를 화면 폭의 비율로 고정한다. 말하면 `gestureBarWidth` 보다 우선한다. `gestureBarWidth` · `landscapeGestureBarWidth` 로 옮긴다. |

#### 기기별 기본값 (`defaultsByDevice`)

| 필드 | `phone` | `tablet` |
|------|---------|----------|
| `screenAspectWidth` : `screenAspectHeight` | `9 : 19.5` | `299 : 433` (캔버스 화면 박스 `299 × 433` 의 비례) |
| `borderRadius` | `CoreRadius.radius24` | `CoreRadius.radius16` |
| 레일 + 베젤 | `3 + 5` — 화면이 몸체 가장자리에서 `8` | `3 + 8` — `11` |
| `cameraPlacement` | `screen` | `bezel` |
| 카메라 | 알약 `45 × 13` (`cutoutColor`), 위에서 `4`, 렌즈 링 `6.5` (끝에서 `3.25`), 코어 `3.9` | 원 `4 × 4` (`lensColor`), 베젤 띠 위에서 `2`, 링 없음, 코어 `2.4` |
| 전원 버튼 | 우측, 위에서 `0.30`, 길이 `40` | 위, 오른쪽 끝에서 `0.1167`, 길이 `45.433` |
| 볼륨 버튼 | 좌측, 위에서 `0.20`, 길이 `26` × 2 (간격 `8`) | 좌측, 위에서 `0.1838`, 길이 `33.317` × 1 |
| 전원 버튼 (가로) | 아래, 오른쪽 끝에서 `0.30`, 길이 `40` | 우측, 위에서 `0.1550`, 길이 `49.522` |
| 볼륨 버튼 (가로) | 위, 왼쪽에서 `0.20`, 길이 `26` | 위, 왼쪽에서 `0.6205`, 길이 `36.316` |
| `antennaBandLength` | `1.9` (여섯 개) | `0` (없음) |
| 기준 폭 (세로 · 가로) | `402` · `874` | 약 `834.7` · 약 `1208.8` |
| 고정 배율 (세로 · 가로) | `144 / 402` · `312 / 874` | `144 / 402` · `144 / 402` |
| 상태 표시줄 높이 (세로 · 가로) | `59` · 없음 | `32` · `32` |
| `statusBarInset` / `statusBarWingWidth` | `24` / `101` | `16` / `0` |
| `statusBarContentCenter` | `32.5` | `16` |
| `statusBarTrailingInset` / `statusBarTrailingSpacing` | `2` / `6` | `0` / `4` |
| `statusBarTextStyle` | `titleSmall` | `labelLarge` |
| 홈 제스처 바 폭 (세로 · 가로) | `144` · `209` | `314` · `314` |
| 홈 제스처 바 영역 높이 (세로 · 가로) | `34` · `21` | `20` · `20` |

### CoreMockupCodeStyle

| 슬롯 | 타입 | 비고 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | 코드 블록 배경 colour. |
| `textStyle` | `CoreTextStyle?` | 코드 텍스트 타이포그래피 (색 포함). |
| `prefixTextStyle` | `CoreTextStyle?` | 줄 번호 / prefix 타이포그래피 (색 포함). |
| `borderRadius` | `CoreBorderRadius?` | 외부 컨테이너 border radius. |
| `padding` | `CoreEdgeInsets?` | 코드 블록 내부 패딩. |
| `lineSpacing` | `double?` | 라인 사이 간격 (logical px). |
| `lineNumberWidth` | `double?` | 줄 번호 열 폭 (logical px). |
| `mutedToneColor` | `CoreColor?` | `CoreCodeLineTone.muted` 줄 글 색. 기본 `onSurfaceVariant`. |
| `linkToneColor` | `CoreColor?` | `CoreCodeLineTone.link` 줄 글 색. 기본 `link`. |
| `successToneColor` | `CoreColor?` | `CoreCodeLineTone.success` 줄 글 색. 기본 `onSuccessContainer`. |
| `warningToneColor` | `CoreColor?` | `CoreCodeLineTone.warning` 줄 글 색. 기본 `onWarningContainer`. |
| `errorToneColor` | `CoreColor?` | `CoreCodeLineTone.error` 줄 글 색. 기본 `onErrorContainer`. `neutral` 줄은 슬롯 없이 `textStyle` 색을 따릅니다. |

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
Core{Variant}Style.defaultX                                  // 디자인 시스템 기본값
  → CoreMockupTheme.style                                    // 목업 공유 겉모습
  → CoreMockup{Variant}Theme.style                           // 프로젝트 공통
  → widget.mockup{Variant}Style                              // 인스턴스별
```

`MockupDevice` 는 `CoreMockupDeviceStyle.defaultsByDevice[device]` 가 기본값 층에, `CoreMockupDeviceStyle.defaultsByFinish[finish]` 가 그 위에 flat 마감의 값을 덮고, `CoreMockupDeviceTheme.finishStyles[finish]` 가 `deviceStyles[device]` 뒤 위젯 앞에서 마감별 프로젝트 override 를 받으며, `CoreMockupDeviceTheme.deviceStyles[device]` 가 `CoreMockupDeviceTheme.style` 과 위젯 사이에 끼어 기기별 프로젝트 override 를 받는다.

## 변형 (Variants)

### Browser
창 컨트롤 · 이전/다음 · 주소창 · 액션이 있는 웹 페이지 프레임입니다.

```dart
MockupBrowser(
  addressBar: 'https://example.com/dashboard',
  child: DashboardScreenshot(),
)
```

### Phone · Tablet
`MockupDevice` 의 `device` 축입니다. 레일·이너 베젤·화면·카메라·하드웨어 버튼·상태 표시줄·홈 제스처 바를 갖춘 기기 프레임이며, 폰과 태블릿은 같은 규칙에서 비율·radius·베젤 두께·카메라 위치·버튼 배치·안테나 띠·시스템 바 구성만 다릅니다. 폰은 화면을 파낸 카메라 알약과 안테나 띠 여섯 개를 갖고, 태블릿은 화면 위 베젤 띠 안의 작은 카메라를 갖고 안테나 띠가 없습니다.

```dart
MockupDevice(
  child: MobileAppPreview(),
)

MockupDevice(
  device: .tablet,
  child: TabletAppPreview(),
)
```

### Portrait · Landscape
`orientation` 축입니다. `device` 와 직교하며 — 기기가 무슨 하드웨어인지와 그걸 어느 방향으로 들었는지는 다른 질문입니다.

돌린 몸체는 **버튼을 데리고 갑니다**. 세워 든 자세가 정본이고 가로는 그것을 시계방향으로 90° 돌린 것이라, 버튼이 앉는 변은 저작하지 않고 파생됩니다 — 태블릿은 volume 이 왼쪽 → 위로, power 가 위 → 오른쪽으로 갑니다. 폰은 volume 왼쪽 → 위, power 오른쪽 → 아래. 안테나 띠도 같은 끝·같은 거리를 지킨 채 변만 시계방향으로 한 칸 옮겨 갑니다.

변을 따라 **얼마나 들어간 자리**인지와 버튼이 **얼마나 긴지**는 파생하지 않고 `landscape*` 필드(`landscapePowerButtonLength` · `landscapePowerButtonOffset` 등)가 저작합니다 — 캔버스가 그 위치를 회전이 아니라 눈으로 잡기 때문입니다.

돌린 자세는 하드웨어 말고도 달라집니다.

| | 폰 | 태블릿 |
|---|----|--------|
| 카메라 | 화면의 **왼쪽 가장자리**에 선 세로 알약, 렌즈는 위쪽 끝 | 위쪽 베젤 띠 가운데 (그대로) |
| 상태 표시줄 | 없음 (`showStatusBar` 무시) | 있음 — 높이는 세로와 같다 |
| 안전 여백 | 왼쪽에 카메라 몫, 위쪽은 `0` | 위쪽에 상태 표시줄 몫 (세로와 같다) |
| 홈 제스처 바 | 막대 폭 `209`, 영역 높이 `21` | 막대 폭 `314`, 영역 높이 `20` (세로와 같다) |

화면 비율(`screenAspectWidth` / `screenAspectHeight`)은 **긴 변 먼저** 읽는 비례일 뿐이고 방향을 말하지 않습니다. 어느 쪽이 길어지는지는 `orientation` 하나가 정합니다.

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

### Code
코드 에디터 스타일의 프레임입니다. 선택적으로 줄 번호가 표시됩니다.

```dart
MockupCode.fromString(
  'print("Hello, World!");',
  showLineNumbers: true,
)
```

### App
데스크톱 앱 창 프레임입니다. `MockupBrowser` 에 `addressBar: null` 을 넘기면 주소창 · 이전/다음 · 액션이 빠지고 창 컨트롤만 남습니다.

```dart
MockupBrowser(
  addressBar: null,
  child: AppContent(),
)
```

창 컨트롤까지 없애려면 `showControls: false` 를 함께 넘깁니다.

## 마이그레이션 (Migration)

### 상태 표시줄 · 홈 제스처 바 · 하드웨어 기본값

**제스처 바 길이의 단위가 바뀌었다.** `gestureBarHeight` · `gestureBarOffset` 은 이제 논리 px 가 아니라
**iOS point** 이고, 기기·방향별 고정 배율로 그립니다. 폰 세로의 배율은 `144 / 402` 입니다.
px로 저작했던 값은 같은 숫자로 그려지지 않습니다. 예를 들어 `gestureBarHeight: 4`는
폰 세로에서 약 `1.43px`로 그려집니다. 값을 point로 다시 정합니다.

```dart
// before — 제스처 바를 화면 폭 비율과 px 로 저작했다
MockupDevice(
  mockupDeviceStyle: CoreMockupDeviceStyle(
    gestureBarWidthRatio: 0.5,
    gestureBarHeight: 6,
  ),
  child: screenshot,
)

// after — point 로 저작하면 화면 폭에 맞춰 함께 줄어든다
MockupDevice(
  mockupDeviceStyle: CoreMockupDeviceStyle(
    gestureBarWidth: 200,
    gestureBarHeight: 8,
  ),
  child: screenshot,
)
```

`gestureBarWidthRatio` 는 deprecated (since 0.154) 이다. 말하면 계속 막대를 그 화면 폭 비율에 고정하고
`gestureBarWidth` 보다 우선하므로 동작은 유지되지만, 막대를 비율이 아니라 point 길이로 저작한다.
`CoreMockupDeviceStyle.defaultBezelWidth` · `defaultCameraCoreSize` · `defaultGestureBarWidthRatio` 도
deprecated (since 0.154) 이다 — 베젤 두께·코어 지름·막대 폭은 기기마다 다른 값이라
`CoreMockupDeviceStyle.defaultsByDevice[device]` 에서 읽는다.

**기본 모양이 바뀌었다.** 값을 말하지 않은 호출부도 그림이 달라진다.

- 상태 표시줄이 기본으로 그려지고 위 안전 여백을 확보한다. 그 여백이 필요 없으면 `showStatusBar: false` (폰은 카메라 몫의 여백만 남는다).
- 홈 제스처 바가 `on-surface` **불투명**이다 (옛 20%).
- 몸체가 단색이 아니라 그라디언트이고 림 하이라이트·글로, 베젤 윤곽·안쪽 그림자, 폰의 안테나 띠가 생겼다. 레일 색(`railColor` · 공유 `frameColor`)을 말했다면 몸체는 계속 그 단색이다.
- `buttonColor` 가 레일 색과 같은 값이 아니다 — 광택 두 겹 아래의 밑바탕 단색이다.
- 레일 `3` · 베젤 폰 `5` / 태블릿 `8` · 카메라 폰 `45 × 13` 알약 · 버튼 두께 `2` · 돌출 `1.5` 로 하드웨어 기본값이 달라졌다.
- 태블릿은 비율이 `299 : 433`, radius 가 `radius16` 이고 카메라가 화면 안이 아니라 위쪽 베젤 띠에 있다. 같은 `width` 에서 옛 `3:4` 보다 길다.
- 가로로 돌린 폰의 카메라가 화면 위 가운데가 아니라 왼쪽 가장자리로 간다.

### 가로는 비율이 아니라 `orientation` 이 말한다

옛 `MockupDevice` 는 가로를 별도 축으로 두지 않고 `screenAspectWidth` 가
`screenAspectHeight` 보다 크면 가로로 읽었다. 이제 **`orientation` 이 그 하나의
출처**이고, 비율은 방향을 말하지 않는 비례 — 긴 변 먼저 읽는다 — 로만 남는다.

```dart
// before — 비율을 뒤집어 가로를 만들었다
MockupDevice(
  device: .tablet,
  mockupDeviceStyle: CoreMockupDeviceStyle(
    screenAspectWidth: 4,
    screenAspectHeight: 3,
  ),
  child: screenshot,
)

// after
MockupDevice(
  device: .tablet,
  orientation: .landscape,
  child: screenshot,
)
```

옛 방식으로 가로 비율을 저작해 두었다면 그 기기는 이제 **세로로 그려진다** —
비율이 긴 변 먼저 읽는 세로 비례로 정규화되고 `orientation` 이 기본값 `portrait` 이기 때문이다.
`orientation: .landscape` 를 주고 비율 override 는 지우면 된다.

폰도 이제 가로를 갖는다. 돌린 몸체는 버튼을 데려가므로 폰 가로는 volume 이 위,
power 가 아래다 — 옛 코드가 그리던(좌우 변에 그대로 두는) 모습과 다르다.

### MockupPhone → MockupDevice

`MockupPhone` 은 `MockupDevice` 로 이름이 바뀌었다. `device` 의 기본값이 `phone` 이라 새 이름으로 바꾸기만 하면 그대로 폰을 그린다. 옛 이름(`MockupPhone` 타입 별칭, 파라미터 `mockupPhoneStyle`)은 어느 플랫폼에도 없다 — 아래처럼 고쳐야 컴파일된다.

```dart
// before
MockupPhone(
  mockupPhoneStyle: CoreMockupDeviceStyle(borderColor: CoreColor.token(CoreColors.outline)),
  child: screenshot,
)

// after
MockupDevice(
  mockupDeviceStyle: CoreMockupDeviceStyle(borderColor: CoreColor.token(CoreColors.outline)),
  child: screenshot,
)
```

**기계적 치환만으로는 끝나지 않는 부분** — 그림이 달라진다:

- 기본 화면 비율이 `9:16` 에서 `9:19.5` 로 바뀌어 같은 `width` 에서 기기가 더 길다.
- 화면에 여백이 없다 — 옛 `innerPadding` 이 사라져 `child` 가 화면을 가장자리까지 채운다.
- 카메라가 흐름에서 빠져 화면 위에 겹친다. 상단 베젤이 두꺼웠던 비대칭이 없어진다.
- 레일·림·베젤·버튼이 밝기·고대비 모드와 무관한 고정 색이 되고 본체에 어느 모드에서나 검정인 그림자(`CoreShadow.xl`)가 생긴다.

**사라진 필드와 대체:**

| 옛 필드 | 대체 |
|---------|------|
| `frameColor` | `railColor` |
| `outerPadding` | `railWidth` + `bezelWidth` (사방 균일) |
| `innerPadding` | 없음 — 화면은 캔버스 |
| `screenBorderRadius` | 없음 — `borderRadius − (railWidth + bezelWidth)` 로 파생 |
| `cameraBorderRadius` | 없음 — 카메라 짧은 변의 절반으로 파생 |
| `cameraSize` | `cameraWidth` / `cameraHeight` |
| `cameraPadding` | `cameraOffset` (화면 위 가장자리에서의 거리) |
| `cameraColor` | 없음 — 렌즈 링을 품은 컷아웃은 `cutoutColor`, 링이 없는 컷아웃(그 자체가 렌즈)은 `lensColor` |

## 동작 스펙 (Behavior)

### 인터랙션

- 이 페이지는 **[MockupBrowser](/components/mockup-browser)** / **[MockupDevice](/components/mockup-device)** / **[MockupCode](/components/mockup-code)** 패밀리의 개요입니다. 주소·하드웨어·상태 표시줄·코드 장식은 실제 브라우저·OS·편집기의 동작을 만들지 않습니다.
- 기본적으로 정적 프레임으로 인터랙션 없음
- 기기 목업의 상태 표시줄은 한 순간을 찍은 화면이라 시계가 흐르지 않고 로케일도 따르지 않습니다 (`9:41` · `오전` · `4월 1일 수요일` · `100%`)
- `child`에 인터랙션 가능한 위젯을 넣으면 프레임 안에서 동작

### 상태 전환

- 정적 컴포넌트로 별도 상태 전환 없음

### 애니메이션

- 별도 애니메이션 없음 (자식 위젯의 애니메이션은 그대로 동작)

## 사용 가이드라인 (Usage Guidelines)

### ✅ Do

<Callout type="tip">

**랜딩 페이지 히어로 섹션에 실제 앱 스크린샷을 Device 목업으로 표시**

```dart
MockupDevice(
  child: Image.asset(
    'assets/screenshots/app_home.png',
    fit: BoxFit.cover,
  ),
)
```

디바이스 프레임 안의 스크린샷은 앱의 실제 UI를 자연스럽게 보여줘 사용자 신뢰를 높인다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**실제 동작하는 복잡한 앱을 Device 목업 안에 렌더링**

```dart
// ❌ 성능 문제 야기할 수 있음
MockupDevice(
  child: MaterialApp(
    home: ComplexAppWithManyAnimations(),
  ),
)
```

목업 안에 무거운 위젯을 렌더링하면 성능 문제가 발생한다. 스크린샷 이미지로 대체하는 것이 좋다.

</Callout>

### ✅ Do

<Callout type="tip">

**문서에서 코드 예제를 Code 목업으로 표시해 가독성 향상**

```dart
MockupCode.fromString(
  "Button(\n  onPressed: handlePressed,\n  child: const Text('클릭'),\n)",
)
```

코드 에디터 스타일 프레임이 코드 블록을 더 전문적이고 읽기 쉽게 만든다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**실제 사용자 인터페이스에 Mockup을 UI 컨테이너로 사용**

```dart
// ❌ 실제 앱 UI에 Device 목업 사용
Scaffold(
  body: MockupDevice( // 실제 앱인데 기기 프레임?
    child: actualAppContent,
  ),
)
```

Mockup은 프레젠테이션/문서 목적이며 실제 앱 UI 컨테이너로 사용하면 혼란스럽고 불필요한 비주얼 레이어를 추가한다.

</Callout>

### ✅ Do

<Callout type="tip">

**목업에는 실제와 유사한 예시 콘텐츠를 사용하세요.**

```dart
MockupDevice(
  child: AppScreenPreview(
    // 실제 앱 화면과 유사한 내용
    content: RealisticDemoContent(),
  ),
)
```

실제와 유사한 콘텐츠로 목업을 채우면 디자인 리뷰나 문서에서 컴포넌트의 실제 사용 모습을 효과적으로 전달할 수 있습니다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**목업을 실제 프로덕션 레이아웃의 컨테이너로 사용하지 마세요.**

```dart
// ❌ 실제 앱에서 Mockup을 레이아웃으로 사용
Scaffold(
  body: MockupBrowser(
    addressBar: 'https://example.com',
    child: actualAppContent,  // 실제 콘텐츠
  ),
)
```

Mockup은 문서화, 프레젠테이션, Widgetbook 등 데모 목적으로만 사용합니다. 실제 앱 레이아웃으로는 사용하지 마세요.

</Callout>

## 접근성 (Accessibility)

### 역할

세 목업(`MockupBrowser` · `MockupDevice` · `MockupCode`) 모두 자기 역할을 내보내지 않습니다 — 프레임은 장식이고, 스크린 리더에는 안에 넣은 콘텐츠만 노출되는 것이 의도한 동작입니다.

- **Flutter**: 세 파일 모두 프레임을 `Semantics` 로 감싸지 않습니다(`MockupDevice` 의 상태 표시줄을 빼는 `ExcludeSemantics` 하나만 있습니다). `Container` + `BoxDecoration` 으로 프레임을 그릴 뿐이라 시맨틱 노드를 만들지 않습니다. 프레임 자체를 설명해야 하면 호출자가 `Semantics(label: '브라우저 목업: CoUI 문서')` 로 감싸세요.
- **Web**: 세 컴포넌트 모두 `configureAttributes` override 가 없고 루트는 `attributes: componentAttributes` 로 나가므로, 컴포넌트가 강제하는 `role` / `aria-*` 가 없고 호출자 속성이 그대로 통과합니다 — `MockupBrowser(attributes: {'aria-label': '...'})` 처럼 실으면 됩니다. 루트 태그도 `tag` 파라미터로 바꿀 수 있습니다(기본 `'div'`).
- 순수 장식 요소는 어느 쪽에서도 읽히지 않습니다 — `MockupBrowser` 창 버튼의 점 세 개는 Web 에서 빈 `<div>`, Flutter 에서 텍스트 없는 `_ControlDot` 이고, `MockupDevice` 의 카메라 컷아웃 · 상태 표시줄 · 홈 제스처 바도 같습니다 (글자가 있는 상태 표시줄은 Web 에서 `aria-hidden="true"` 를 붙이고 Flutter 에서는 시맨틱 트리에서 뺍니다).

### 키보드

| 키 | 동작 |
|----|------|
| 없음 | 목업 프레임이 처리하는 키가 없습니다 |

세 목업 모두 포커스 대상이 아닙니다 — Flutter 에 `Focus` / `GestureDetector` / `onTap` 이 없고, Web 루트에 `tabindex` 도 `keydown` 도 붙지 않습니다. 프레임 안에 넣은 자식의 키보드 동작은 그대로 유지됩니다.

### 스크린 리더

프레임 자체에는 접근 가능한 이름이 없고, 상태 통보도 없습니다(live region 없음 — 정적 프레임입니다). 다만 프레임이 그리는 **두 텍스트는 장식이 아니라 실제 텍스트로 읽힙니다**:

- `MockupBrowser.addressBar` 는 양 플랫폼 모두 평범한 텍스트 노드입니다 (Flutter `Text(addressBar, ...)`, Web `Text(addressBar)`). 스크린 리더는 URL 문자열을 본문 텍스트처럼 읽고, "주소창"이라는 맥락은 전달되지 않습니다.
- `MockupCode` 의 줄 번호(`CoreCodeLine.prefix`)도 마찬가지로 평범한 텍스트 노드로 나갑니다 — 양 플랫폼 모두 `aria-hidden` 을 붙이지 않아 코드 본문과 섞여 `1 void main() { 2 print(...)` 처럼 읽힙니다.

> 줄 번호를 읽히고 싶지 않으면 `MockupCode.fromString(code, showLineNumbers: false)` 로 `prefix` 자체를 만들지 않는 편이 확실합니다.

### 포커스 관리

오버레이가 아니므로 진입 · 이탈 · 트랩이 모두 없습니다. 프레임은 포커스를 요청하지 않고 자식의 traversal 순서에도 관여하지 않습니다.

### 알려진 제약

**`MockupCode` 에는 코드 시맨틱이 없습니다.** 루트가 `<div>`(기본 `tag`)이고 줄은 `<div>` / `<span>` 이라 `<pre>` · `<code>` 어느 것도 아니며, Flutter 쪽도 `Text` 뿐입니다. 그래서 보조기술에 "코드"로 전달되지 않고, 공백·들여쓰기의 의미도 보존되지 않습니다.

> 대안: Web 은 `MockupCode(tag: 'pre')` 로 루트 태그를 바꿀 수 있습니다. Flutter 에는 대응하는 손잡이가 없습니다 — 코드 시맨틱이 실제로 필요하면 목업 대신 [CodeSnippet](/components/code-snippet) 을 쓰세요.

**긴 코드 줄은 잘리고 스크롤할 수 없습니다.** Flutter 는 `Text(..., softWrap: false)` 로 줄바꿈을 끄고, Web 은 줄에 `whitespace-nowrap` 을 주고 루트에서 `overflow-hidden` 으로 잘라냅니다. 양쪽 다 스크롤 컨테이너가 아니라서, 프레임 너비를 넘긴 코드는 확대하거나 창을 좁힐수록 도달할 방법이 사라집니다.

> 대안: 목업 안의 코드 줄을 프레임 너비에 맞게 짧게 유지하세요. 실제로 읽어야 하는 코드라면 [CodeSnippet](/components/code-snippet) 이 맞는 컴포넌트입니다.

## 크로스 플랫폼 차이점 (Platform Differences)

| 항목 | Flutter | Web |
|------|---------|-----|
| 클래스명 | `MockupBrowser` / `MockupDevice` 등 | `MockupBrowser` / `MockupDevice` 등 |
| 프레임 렌더링 (browser · code) | `OutlinedContainer` / `Container` + `BoxDecoration` (색 · `borderRadius`, 보더는 browser 만) | `OutlinedContainer` / `<div>` + `border-radius` |
| 기기 프레임 | `Stacks` 안에 버튼 `Position` + 합성한 `OutlinedContainer` 본체 → 베젤 → `ClipRRect` 화면, 카메라·상태 표시줄·제스처 바는 화면 위 `Position` | 같은 트리를 `<div>` 로 — 버튼·카메라·상태 표시줄·제스처 바는 미리 계산한 inline 절대 배치 |
| 림 하이라이트·글로 | `CustomPaint` 로 박스 안쪽에 stroke (글로는 그라디언트 셰이더 + `ImageFiltered` 블러) | 안쪽 링 `<div>`, 글로는 그라디언트를 링 마스크로 잘라 블러·불투명도 래퍼에 담는다 |
| 상태 표시줄 글리프 | `CoreVectorGlyph` 경로를 `CustomPaint` 로 채운다 | 글리프마다 인라인 `<svg>` 의 `<path>` (`fill-rule` 포함) |
| 상태 표시줄 글자 | 역할을 푼 `TextStyle` 의 글자 크기를 화면 배율로 줄이고 호스트 글자 배율은 받지 않는다 | 역할 클래스에 배율을 곱한 인라인 `font-size` |
| 상태 표시줄 접근성 | `ExcludeSemantics` 로 시맨틱 트리에서 뺀다 | `aria-hidden="true"` |
| 안전 여백 | 목업 화면 기준 `MediaQuery` 와 `SafeArea` 로 왼쪽·위·오른쪽·아래 네 변을 준다 | 콘텐츠 래퍼의 네 변 `padding` |
| 브라우저 주소창 | `Expanded` › `Container` (pill decoration) + `Text` | flex `1` `<div>` (pill) + `Text` |
| `MockupBrowser` 창 몸체 | `OutlinedContainer` (`containerStyle` 로 fill · 테두리 · radius · 그림자) | `OutlinedContainer` (`box-shadow` 포함) |
| `MockupBrowser` 콘텐츠 카드 | `Stack` › `Container` (clip) › `Padding(contentInset)` | `relative` body › `overflow: hidden` 콘텐츠 › 패딩 `<div>` |
| `MockupBrowser` 앱 창 (`addressBar: null`) | 주소창 · chevron · 액션 위젯이 트리에 없음 | 해당 `<div>` 가 DOM 에 없음 |

`MockupBrowser` · `MockupCode` 는 어느 플랫폼에서도 `CustomPaint` / `CustomPainter` 없이 박스
decoration 으로 프레임을 그립니다. `MockupCode` 는 보더가 없습니다 (`CoreMockupCodeStyle`
에 `borderColor` 필드 자체가 없음) — 배경색과 radius 만으로 프레임을 만듭니다.
그림자는 `MockupBrowser` 의 창 몸체와 `MockupDevice` 의 본체가 갖습니다 — 둘 다
`OutlinedContainer` 를 합성하므로 그 primitive 가 기본 `CoreShadow.xl` 을 그립니다.
`MockupDevice` 는 그 그림자의 색을 모드와 무관한 검정으로 정해 두는데, Web 에서는 이 고정색
그림자가 서피스 스타일이 휘는 `--shadow-*` 변수를 거치지 않아 스타일의 그림자 모양은
Flutter 에서만 따라옵니다.
`MockupCode` 는 그림자가 없고, Web 에서도 `box-shadow` 를 쓰지 않습니다.

## 관련 컴포넌트 (Related Components)

- **[MockupFoldable](/components/mockup-foldable)**: 가운데가 접히는 기기 프레임이 필요할 때 사용
- **[Card](/components/card)**: 단순한 콘텐츠 컨테이너가 필요할 때 사용
- **[CodeSnippet](/components/code-snippet)**: 코드 하이라이팅이 필요한 코드 블록에 사용

### 조합 예제

```dart
// 랜딩 페이지 히어로 섹션
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
        addressBar: 'https://coui.cocode.im',
        child: Image.asset('assets/screenshots/landing.png'),
      ),
    ),
  ],
)
```
