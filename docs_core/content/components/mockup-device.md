---
title: MockupDevice
description: 앱 화면을 폰 · 태블릿 기기 틀이나 장식 없는 미리보기 틀 안에 담아 보여 주는 목업입니다.
category: display
platforms: [flutter, web]
related: [mockup, mockup-foldable, mockup-browser, card]
tags: [mockup, device, phone, tablet, presentation]
template: v2
source: display/mockup_device
---

# MockupDevice

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

`MockupDevice` 는 `child` 로 받은 화면을 폰 · 태블릿 틀 안에 보여 줍니다. 아무 값도 주지 않으면 세로로 든 폰을 기기 그림(`realistic`)으로 그립니다. 속성을 바꿔 보며 확인하고, 만들어진 코드를 복사하세요.

<Playground component="mockup-device" />

미리보기는 `width` 를 `200` 으로 줄여 시작합니다. `showCamera` · `showStatusBar` · `showGestureBar` · `screenBrightness` 의 `null` 은 속성을 적지 않은 상태이고, 앞의 셋은 마감을, 마지막은 페이지의 밝기를 따릅니다.

```dart
// 기본은 세로로 든 폰입니다
MockupDevice(
  child: Text('앱 화면').bodyMedium.onSurface,
)

// 태블릿
MockupDevice(
  device: .tablet,
  child: Text('앱 화면').bodyMedium.onSurface,
)

// 가로로 돌린 폰 — 카메라가 화면 왼쪽 가장자리로 가고 상태 표시줄은 없습니다
MockupDevice(
  orientation: .landscape,
  child: Text('앱 화면').bodyMedium.onSurface,
)

// 기기 그림 대신 장식 없는 미리보기 틀
MockupDevice(
  finish: .flat,
  child: Text('앱 화면').bodyMedium.onSurface,
)

// 장식과 그 장식이 비워 두던 안전 여백을 각각 끕니다
MockupDevice(
  showCamera: false,
  showStatusBar: false,
  showGestureBar: false,
  child: Text('앱 화면').bodyMedium.onSurface,
)

// 화면만 밝은 모드로 그립니다. 틀은 페이지의 밝기를 따릅니다
MockupDevice(
  finish: .flat,
  screenBrightness: .light,
  child: Text('앱 화면').bodyMedium.onSurface,
)
```

## 구조

아래는 기본 마감의 폰입니다. 칠한 면이 `child` 가 놓이는 안전 영역입니다.

<Anatomy demo="mockup-device/anatomy">
<AnatomyItem part="container" name="body">

기기 몸체입니다. 바깥 고리(레일)와 림, 그 안의 검은 베젤, 화면이 차례로 놓입니다. 폰에는 몸체를 가로지르는 안테나 띠 여섯 개가 있습니다.

</AnatomyItem>
<AnatomyItem select="div:first-child" side="right" name="button">

몸체 옆으로 나온 하드웨어 버튼입니다. 폰은 전원 버튼 하나와 볼륨 버튼 둘입니다. 그림이라 누를 수 없습니다.

</AnatomyItem>
<AnatomyItem select="div[aria-hidden=true] + div" side="top" name="camera">

카메라입니다. 폰은 화면을 파낸 알약 모양이고, 태블릿은 화면 위 베젤 안의 작은 원입니다.

</AnatomyItem>
<AnatomyItem select="div[aria-hidden=true]" side="left" name="status bar">

시계와 신호 · Wi-Fi · 배터리를 그린 상태 표시줄입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=content]" side="right" name="child">

화면에 담는 내용입니다. 카메라 · 상태 표시줄 · 홈 제스처 바를 피한 자리를 받습니다.

</AnatomyItem>
<AnatomyItem select="div[aria-hidden=true] ~ div:last-child" side="right" name="gesture bar">

화면 아래의 홈 제스처 바입니다.

</AnatomyItem>
</Anatomy>

부품의 자리는 하나씩 적지 않고 같은 규칙으로 계산합니다.

- 화면은 몸체 가장자리에서 `railWidth + bezelWidth` 만큼 안쪽에 있습니다. 네 변이 같고, 기본값은 폰 `8`, 태블릿 `11`, `flat` 마감 `8` 입니다.
- 베젤과 화면의 모서리 반경은 몸체 반경에서 안쪽으로 들어온 거리를 빼서 정합니다. 서피스 스타일이나 밀도가 모서리를 바꾸는 경우의 차이는 [플랫폼 차이](#플랫폼-차이)에 있습니다.
- 버튼이 붙는 변은 `device` 와 `orientation` 이 정합니다.

## 기기와 방향

`device` 는 어떤 기기를 그릴지, `orientation` 은 그 기기를 어느 방향으로 드는지를 정합니다. 두 값은 따로 고릅니다.

<Preview demo="mockup-device/devices" />

| 항목 | `phone` (기본) | `tablet` |
| --- | --- | --- |
| 화면 비율 (짧은 변 : 긴 변) | `9 : 19.5` | `299 : 433` |
| 몸체 모서리 | `radius24` | `radius16` |
| 카메라 | 화면을 파낸 알약 | 화면 위 베젤 안의 작은 원 |
| 하드웨어 버튼 (세로) | 오른쪽에 전원 하나, 왼쪽에 볼륨 둘 | 위에 전원 하나, 왼쪽에 볼륨 하나 |
| 안테나 띠 | 여섯 개 | 없음 |
| 상태 표시줄 | 시계 / 신호 · Wi-Fi · 배터리 | 시계 · 오전 · 날짜 / Wi-Fi · 배터리 글 · 배터리 |

### 폰의 방향

<Preview demo="mockup-device/orientation-phone" />

### 태블릿의 방향

<Preview demo="mockup-device/orientation-tablet" />

`orientation: .landscape` 로 바꾸면 다음이 달라집니다.

- 버튼과 안테나 띠가 붙는 변이 시계 방향으로 한 칸 옮겨 갑니다. 폰은 볼륨 버튼이 왼쪽에서 위로, 전원 버튼이 오른쪽에서 아래로 갑니다. 태블릿은 볼륨 버튼이 왼쪽에서 위로, 전원 버튼이 위에서 오른쪽으로 갑니다.
- 폰의 카메라는 화면 **왼쪽 가장자리**에 세로로 섭니다. 태블릿의 카메라는 위쪽 베젤 가운데에 그대로 있습니다.
- 폰은 상태 표시줄을 그리지 않습니다. `showStatusBar: true` 를 적어도 같습니다. 태블릿은 두 방향 모두 그립니다.

화면 비율을 정하는 `screenAspectWidth` · `screenAspectHeight` 는 방향을 정하지 않습니다. 큰 값을 긴 변으로 읽고, 어느 쪽이 길어질지는 `orientation` 만 정합니다.

<a id="동작-스펙-behavior"></a>

## 마감

`finish` 는 기기를 그린 그림(`realistic`)과 화면을 담는 미리보기 틀(`flat`)을 가릅니다.

<Preview demo="mockup-device/finish" />

| 항목 | `realistic` (기본) | `flat` |
| --- | --- | --- |
| 틀 | 레일 · 림 · 림의 빛 · 베젤 · 버튼 · 안테나 띠(폰) · 몸체 그림자 | 두께 `8` 의 링 하나. 레일 · 버튼 · 안테나 띠 · 림의 빛 · 렌즈 링 · 그림자가 없습니다. |
| 모서리 | 기기별 | 몸체 `32`, 화면 `24` |
| 화면 비율 | 기기별 | `1 : 2` (가로로 돌리면 `2 : 1`) |
| 기본 `width` | `320` | `256` — 화면 `240 × 480`, 몸체 `256 × 496` |
| 카메라 · 상태 표시줄 · 홈 제스처 바 | 그립니다. | 그리지 않습니다. |
| 틀의 색 | 고정 색 | 테마의 `surfaceContainerHighest` — 밝기에 따라 바뀝니다. |

- `flat` 의 화면 비율은 `device` 와 상관없이 `1 : 2` 입니다. 장식을 켜지 않고 테마의 기기별 값도 따로 없으면 `phone` 과 `tablet` 의 그림이 같습니다.
- 화면은 두 마감 모두 `surface` 로 칠합니다.
- `flat` 에서도 `showCamera` · `showStatusBar` · `showGestureBar` 에 `true` 를 적으면 해당 장식과 안전 여백이 생깁니다. 장식의 모양과 위치는 `device` 를 따릅니다.

아래는 기본 너비로 그린 `flat` 틀입니다. 장식이 없으면 안전 여백도 없어서, 여백을 두지 않은 내용은 화면 왼쪽 위에 붙고 둥근 모서리에 일부가 가려집니다.

<Preview component="mockup-device" example="flat" />

아래는 `flat` 틀에 장식을 켠 모습입니다.

<Preview demo="mockup-device/flat-decorations" />

## 크기

`MockupDevice` 에는 `CoreComponentSize` 크기 단계가 없습니다. 몸체의 너비 `width` 하나를 정하면 높이가 따라옵니다.

- 화면 너비는 `width − 2 × (railWidth + bezelWidth)` 입니다. 화면 높이는 이 너비와 화면 비율에서 나오고, 몸체 높이는 화면 높이에 위아래 안쪽 거리를 더한 값입니다.
- 기본 너비 `320` 의 높이는 세로 폰이 약 `675`, 세로 태블릿이 약 `454`, 가로 폰이 약 `156`, 가로 태블릿이 약 `228` 입니다.
- `width` 는 방향과 상관없이 **가로 길이**입니다. 같은 `width` 로 가로로 돌리면 낮고 넓은 기기가 됩니다. 세로 기기를 그대로 눕힌 크기가 필요하면 세로 몸체의 높이를 `width` 로 적으세요.

<Preview demo="mockup-device/widths" />

`width` 를 바꿔도 모든 것이 같은 비율로 커지지는 않습니다.

- 레일 · 베젤 두께와 카메라 크기, 버튼의 길이와 두께는 논리 px 값 그대로입니다. 버튼의 위치는 변의 길이에 대한 비율이라 몸체를 따라 움직입니다.
- 상태 표시줄과 홈 제스처 바의 길이는 iOS point 로 정해 두고 기기 · 방향별 고정 배율로 그립니다. 상태 표시줄의 높이와 세로 위치, 글자 · 아이콘 크기, 홈 제스처 바의 길이는 그대로입니다.
- 상태 표시줄의 두 묶음은 화면 양쪽 가장자리를 따라갑니다. 폰은 가장자리에 붙은 고정 폭 영역 안에서 각 묶음을 가운데에 놓고, 태블릿은 두 묶음을 가장자리 쪽으로 붙입니다.
- 그래서 세로 폰의 `width` 를 약 `140` 보다 작게 하면 상태 표시줄의 오른쪽 그림이 카메라에 가리기 시작합니다.

Flutter 는 여기에 테마의 크기 배율(`ThemeData.scaling`)을 곱해 그립니다. 상태 표시줄의 글자 크기는 예외입니다. 크기 배율은 곱하지 않고, 테마의 글자 크기에 목업의 고정 배율을 곱합니다.

## 장식과 안전 영역

`showCamera` · `showStatusBar` · `showGestureBar` 는 카메라, 상태 표시줄, 홈 제스처 바를 각각 켜고 끕니다. 적지 않으면(`null`) 마감을 따라 `realistic` 은 셋 다 그리고 `flat` 은 셋 다 그리지 않습니다. 직접 적은 값은 마감과 상관없이 그대로 씁니다. 세 값은 서로 독립이고, 장식을 끄면 그 장식이 비워 두던 안전 여백도 없어집니다. 몸체와 화면의 크기는 그대로입니다.

<Preview demo="mockup-device/safe-area" />

`child` 는 보이는 장식을 피한 안전 영역에 놓입니다. 오른쪽에서 왼쪽으로 쓰는 문서에서도 왼쪽 · 오른쪽은 뒤집히지 않습니다.

| 변 | 여백이 생기는 때와 크기 |
| --- | --- |
| 위 | 상태 표시줄의 높이와, 화면 위쪽을 파고든 카메라가 차지하는 깊이(화면 가장자리와의 간격을 카메라 아래에도 더한 값) 중 큰 쪽 |
| 왼쪽 | 카메라가 화면 왼쪽 가장자리에 설 때(가로 폰)만, 같은 방식으로 계산한 카메라의 깊이 |
| 아래 | 홈 제스처 바가 보일 때 그 영역의 높이. 스타일로 막대를 더 높이 올리면 막대가 닿는 높이 |
| 오른쪽 | 없음 |

기본값으로 그리면 세로 폰은 위 약 `21` · 아래 약 `12`, 가로 폰은 왼쪽 `21` · 아래 약 `7.5`, 태블릿은 위 약 `11.5` · 아래 약 `7` 입니다. 이 값은 `width` 를 바꿔도 같습니다. 태블릿의 카메라는 화면 밖 베젤에 있어 여백을 만들지 않습니다. 스타일로 카메라를 키우거나 옮기면 여백도 함께 다시 계산하며, 여백은 화면 크기를 넘지 않습니다.

### 상태 표시줄과 홈 제스처 바

- 상태 표시줄의 시각 · 오전 표시 · 날짜 · 배터리 글(`9:41` · `오전` · `4월 1일 수요일` · `100%`)은 한 순간을 찍은 예시입니다. 시간이 흐르지 않고 로케일을 따르지 않으며, 바꾸는 속성도 없습니다.
- 상태 표시줄은 화면의 `backgroundColor` 로 칠한 줄입니다. `child` 위, 카메라 아래에 놓입니다.
- 홈 제스처 바는 화면 아래 가운데에 놓는 막대입니다. 기본색은 불투명한 `onSurface` 이고, 막대 둘레는 따로 칠하지 않습니다.
- 글자 · 아이콘 · 홈 제스처 바의 기본색은 `onSurface` 를 바탕으로 합니다(폰 배터리의 윤곽과 꼭지는 옅게 칠합니다). `backgroundColor` 만 바꿔도 이 색들은 따라 바뀌지 않으므로, 진한 채움에는 [색을 함께](#진한-화면-채움) 바꾸세요.

### `child` 가 받는 자리

`child` 는 축소해서 그리지 않고 목업 화면 크기의 자리에서 그대로 배치합니다. 기본 너비의 세로 폰이라면 화면은 너비 `304`, 높이 약 `659` 입니다. 크기와 화면 정보를 `child` 에게 알려 주는 방식은 플랫폼마다 다릅니다.

| 항목 | Flutter | Web |
| --- | --- | --- |
| 크기 | 안전 영역을 꼭 채우는 크기를 받습니다. | 안전 영역만큼 안쪽 여백을 둔 상자 안의 평범한 블록입니다. 높이를 채우려면 `h-full` 처럼 직접 정합니다. |
| 화면 정보 | `MediaQuery` 의 `size` 는 안전 여백을 포함한 목업 화면 크기입니다. 안전 여백은 목업이 이미 비웠으므로 `child` 에서 읽는 `padding` · `viewPadding` · `viewInsets` · `systemGestureInsets` 는 모두 `0` 입니다. | CSS 미디어 쿼리는 목업이 아니라 브라우저 창을 기준으로 합니다. |
| 넘치는 내용 | 화면에서 잘립니다. 긴 내용은 `child` 안에 스크롤을 두세요. 넘친 `Column` 은 오버플로 오류를 냅니다. | 화면에서 잘립니다. 긴 내용은 `child` 안에 스크롤 영역을 두세요. |

Flutter 에서는 목업이 안전 영역을 `SafeArea` 로 이미 비워 두므로 `child` 가 `SafeArea` 를 다시 써도 여백이 두 번 생기지 않습니다. 바깥 기기의 노치나 키보드 여백도 섞이지 않습니다.

`MockupDevice` 는 `child` 의 글자 모양 · 글자색 · 아이콘 색을 정하지 않습니다. 역할과 색을 적지 않은 `Text` 는 목업 바깥의 값을 물려받으므로, 화면 위의 글에는 `.onSurface` 처럼 색을 적으세요. `screenBrightness` 를 적은 화면에서는 물려받는 기본 글자색과 아이콘 색이 그 밝기의 `onSurface` 가 됩니다.

## 화면 밝기

`screenBrightness` 는 페이지의 밝기와 상관없이 **화면만** 밝게 또는 어둡게 그립니다. 어두운 편집기 화면 안에서 밝은 앱을 미리 보여 줄 때 씁니다. 적지 않으면(`null`) 화면도 페이지의 밝기를 따릅니다.

<Preview demo="mockup-device/screen-brightness" />

- 화면 채움, `child`, 상태 표시줄, 홈 제스처 바가 지정한 밝기의 색과 그림자 세기로 그려집니다. 팔레트, 고대비 설정, 서피스 스타일의 색 조정과 재질의 불투명도 · 어둡기도 그 밝기의 값을 씁니다.
- 몸체 · 베젤 · 버튼은 페이지의 밝기에 남습니다. 크기와 위치는 어느 밝기에서나 같습니다.
- 화면을 [`BrightnessScope`](/guides/theming#부분-트리만-다른-밝기로) 로 감싸는 것과 같은 방식입니다. Flutter 의 `MediaQuery.platformBrightness` 는 바꾸지 않습니다.

## 상태

hover · pressed · focus · disabled 상태가 없는 정적인 틀입니다.

- 하드웨어 버튼, 상태 표시줄, 홈 제스처 바는 그림입니다. 운영체제 화면 전환, 기기 입력, 회전 콜백은 없습니다.
- `device` · `orientation` 같은 값을 바꾸면 새 모습을 그립니다. 목업이 스스로 움직이는 애니메이션은 없습니다.
- `child` 에 넣은 버튼 · 입력 같은 컨트롤은 틀 안에서도 그대로 동작합니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

랜딩 페이지, 문서, 발표, 데모에서 앱 화면을 기기 틀 안에 보여 줄 때 씁니다.

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 가운데가 접히는 기기 | [MockupFoldable](/components/mockup-foldable) |
| 브라우저 창이나 앱 창 틀 | [MockupBrowser](/components/mockup-browser) |
| 코드 편집기 모양의 틀 | [MockupCode](/components/mockup-code) |
| 기기 장식 없이 콘텐츠를 담는 면 | [Card](/components/card) |

### 화면에는 가벼운 내용을 담습니다

목업은 `child` 를 그대로 그리므로 렌더링 비용도 그대로 듭니다. 보여 주기만 할 화면은 스크린샷 이미지가 가볍습니다.

<Split>

<Code language="dart" title="Flutter">
MockupDevice(
  child: Image.asset(
    'assets/screenshots/app_home.png',
    semanticLabel: '앱 홈 화면',
    fit: BoxFit.cover,
  ),
)
</Code>

<Code language="dart" title="Web">
MockupDevice(
  child: img(
    src: '/images/app_home.png',
    alt: '앱 홈 화면',
    classes: 'w-full h-full object-cover',
  ),
)
</Code>

</Split>

### 배경색은 화면에 칠합니다

`mockupDeviceStyle.backgroundColor` 는 `child` 뒤의 화면 전체를 칠합니다. 안전 영역 바깥과 상태 표시줄의 바탕까지 포함합니다. `child` 의 배경색을 알아서 따라가지는 않습니다.

<Cards columns="2">
<Card demo="mockup-device/do-screen-fill" tone="do" eyebrow="이렇게 하세요">

화면의 `backgroundColor` 를 칠하고 `child` 는 투명하게 둡니다. 위아래 여백까지 한 색이 됩니다.

</Card>
<Card demo="mockup-device/dont-child-fill" tone="dont" eyebrow="이렇게 하지 마세요">

`child` 에만 색을 칠하면 안전 여백 자리에 다른 색의 띠가 남습니다.

</Card>
</Cards>

반투명한 색은 상태 표시줄이 같은 색을 한 번 더 칠하므로 그 띠가 더 진해집니다. 이어진 한 색이 필요하면 불투명한 색을 쓰세요.

### 실제 앱의 틀로 쓰지 않습니다

목업은 보여 주기 위한 그림입니다. 실제 앱의 레이아웃 컨테이너로 쓰면 동작하지 않는 상태 표시줄과 버튼이 진짜 화면에 한 겹 더 생깁니다.

<Split>

<Code language="dart" title="이렇게 하세요">
// 소개 화면의 한 부분으로 앱의 모습을 보여 줍니다
MockupDevice(
  width: 240,
  child: appPreview,
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 사용자가 실제로 쓰는 앱 전체를 기기 틀로 감쌉니다
MockupDevice(
  child: actualApp,
)
</Code>

</Split>

## 배치

`MockupDevice` 는 부모의 너비에 맞춰 스스로 줄지 않습니다. 모든 부품의 자리를 `width` 로 계산하므로, 좁은 자리에는 `width` 를 줄여 적으세요. Flutter 에서 부모가 몸체보다 좁거나 낮으면 몸체 바탕만 부모 크기로 눌리고, 베젤 · 화면 · 버튼은 계산한 자리에 남아 그림이 어긋납니다.

| 항목 | Flutter | Web |
| --- | --- | --- |
| 놓이는 방식 | 부모가 최대 크기를 정해 준 방향으로는 그 크기를 다 차지하고, 몸체를 위쪽 가운데에 둡니다. | 몸체 크기의 `inline-flex` 상자입니다. 정렬은 부모 레이아웃이 정합니다. |
| 여러 대를 나란히 | `Wrap` 안에서는 목업 하나가 한 줄을 다 차지합니다. 각 목업을 몸체 너비(`width` 에 크기 배율을 곱한 값)의 `SizedBox` 에 담으세요. | flex 행에 둘 때는 목업이 눌려 줄지 않도록 `flex: none` 인 칸에 담으세요. |
| 좁은 자리 | `FittedBox(fit: BoxFit.scaleDown, ...)` 로 감싸면 그림 전체가 함께 줄어듭니다. | `width` 를 줄여 적습니다. |

버튼은 몸체 옆으로 조금 나옵니다. 나온 부분은 컴포넌트의 크기에 들어가지 않으므로, 둘레를 잘라 내는 컨테이너에 딱 맞춰 넣지 마세요.

## 테마와 스타일

무엇을 보여 줄지는 위젯 속성(`device` · `orientation` · `finish` · `width` · `show*` · `screenBrightness`)이 정하고, 색 · 크기 · 모서리 같은 겉모습은 `mockupDeviceStyle`(`CoreMockupDeviceStyle`) 하나로 바꿉니다. `width` 는 스타일이나 테마에서 바꿀 수 없습니다.

기본 마감의 색은 고정 색과 테마를 따르는 색으로 나뉩니다.

| 부분 | 기본색 | 밝기 · 팔레트 |
| --- | --- | --- |
| 하드웨어 — 몸체 · 림 · 베젤 · 버튼 · 카메라 · 안테나 띠 | 디자인에서 정한 고정 색 | 밝기, 고대비 설정, 앱의 팔레트를 따르지 않습니다. |
| 버튼 광택 · 림의 번짐 빛 · 베젤 안쪽 그림자 · 몸체 그림자 | 흰색이나 검정에 투명도를 준 고정 색 | 몸체 그림자는 어느 모드에서나 검정입니다. |
| 화면 · 상태 표시줄 · 홈 제스처 바 | `surface` · `onSurface` | 테마를 따릅니다. |

기기 색을 바꾸려면 스타일 필드에 색을 직접 적습니다. 몸체 채움은 위에서 아래로 가는 그라디언트가 기본입니다. `railColor`(목업 공유 `frameColor` 포함)를 적으면 그 단색이 되고, `railGradient` 를 적으면 `railColor` 보다 우선합니다. 렌즈 코어도 같은 방식이라, `cutoutColor` 를 적으면 단색이 되고 `coreGradient` 가 그보다 우선합니다.

`flat` 마감은 베젤이 곧 링이고 몸체는 그 아래에 완전히 덮입니다. 링 색은 `bezelColor` 로 바꾸고, 모서리 가장자리에 다른 색이 비치지 않도록 `railColor` 에도 같은 색을 적으세요. 같은 이유로 `railColor` · `borderColor` 나 목업 공유 `frameColor` · `borderColor` 만 바꾸면 `flat` 틀에서는 달라진 것이 보이지 않습니다.

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
CoreMockupDeviceStyle 의 기본값과 defaultsByDevice[device]
  → CoreMockupDeviceStyle.defaultsByFinish[finish]          // flat 만 값이 있습니다
  → CoreComponentTheme.mockup.style                         // 목업 공유 값
  → CoreComponentTheme.mockupDevice.style
  → CoreComponentTheme.mockupDevice.deviceStyles[device]    // 기기별 앱 값
  → CoreComponentTheme.mockupDevice.finishStyles[finish]    // 마감별 앱 값
  → mockupDeviceStyle                                       // 인스턴스별
```

- 목업 공유 값(`CoreMockupStyle`)은 `backgroundColor`(화면 채움), `borderColor`(림 선), `frameColor`(몸체 단색, `railColor` 로 읽습니다), `borderRadius`(몸체 모서리)를 전합니다.
- 테마의 값은 `flat` 마감의 기본값보다 뒤에 놓입니다. 그래서 공유 값, `style`, `deviceStyles` 에 적은 모서리 · 두께 같은 값은 `flat` 틀의 기본값도 덮습니다. `flat` 만 다시 정하려면 `finishStyles` 를 쓰세요.
- `statusBarTextStyle` 과 `containerStyle` 은 적은 부분만 덮고 나머지는 앞의 값을 유지합니다.

<Split>

<Code language="dart" title="목업 하나만 바꾸기">
MockupDevice(
  mockupDeviceStyle: const CoreMockupDeviceStyle(
    railColor: CoreColor.token(CoreColors.primary),
    borderColor: CoreColor.token(CoreColors.outline),
  ),
  child: Text('앱 화면').bodyMedium.onSurface,
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    mockupDevice: CoreMockupDeviceTheme(
      deviceStyles: {
        CoreMockupDevice.tablet: CoreMockupDeviceStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
        ),
      },
      finishStyles: {
        CoreMockupDeviceFinish.flat: CoreMockupDeviceStyle(
          bezelColor: CoreColor.token(CoreColors.surfaceContainer),
          railColor: CoreColor.token(CoreColors.surfaceContainer),
        ),
      },
    ),
  ),
)
</Code>

</Split>

### 진한 화면 채움

화면을 진한 색으로 칠할 때는 상태 표시줄과 홈 제스처 바의 색도 함께 적습니다.

```dart
MockupDevice(
  mockupDeviceStyle: const CoreMockupDeviceStyle(
    backgroundColor: CoreColor.token(CoreColors.primary),
    statusBarTextStyle: CoreTextStyle(
      color: CoreColor.token(CoreColors.onPrimary),
    ),
    statusBarIconColor: CoreColor.token(CoreColors.onPrimary),
    statusBarBatteryBorderColor: CoreColor.token(
      CoreColors.onPrimary,
      opacity: CoreOpacity.opacity40,
    ),
    statusBarBatteryCapColor: CoreColor.token(
      CoreColors.onPrimary,
      opacity: CoreOpacity.opacity40,
    ),
    gestureBarColor: CoreColor.token(CoreColors.onPrimary),
  ),
  child: Text('앱 화면').bodyMedium.onPrimary,
)
```

### 빠른 덮어쓰기 (체인)

`withStyle` 은 지금 `mockupDeviceStyle` 에 넘긴 값을 합친 사본을 돌려주고, 겹치는 필드는 뒤에 적은 값이 이깁니다. `.radius8` 처럼 `CoreRadius` 단계와 이름이 같은 getter 는 몸체 모서리를, `.surfaceContainer` 처럼 색 토큰과 이름이 같은 getter 는 **화면 채움**을 바꿉니다. `.outline` 도 테두리가 아니라 화면 채움입니다.

```dart
// 몸체 모서리와 화면 채움
MockupDevice(
  child: Text('앱 화면').bodyMedium.onSurface,
).radius32.surfaceContainer

// getter 에 없는 필드는 withStyle 로 적습니다
MockupDevice(
  finish: .flat,
  child: Text('앱 화면').bodyMedium.onSurface,
).withStyle(
  const CoreMockupDeviceStyle(bezelWidth: CoreSpace.space12),
)
```

기본값은 `coui_core` 의 `CoreMockupDeviceStyle` 에 있고 Flutter 와 Web 이 같은 값을 읽습니다. 필드마다의 타입과 기본값은 [Mockup 의 CoreMockupDeviceStyle 표](/components/mockup#coremockupdevicestyle)에 있습니다.

<a id="접근성-accessibility"></a>

## 접근성

### 역할

정적인 기기 틀이며 자기 역할을 만들지 않습니다. 폰 · 태블릿 운영체제의 역할도 붙이지 않습니다. `child` 는 자기 시맨틱을 그대로 가집니다.

- Flutter 는 틀을 `Semantics` 로 감싸지 않습니다. 틀 자체에 설명이 필요하면 `Semantics` 로 감싸 이름을 주세요.
- Web 은 루트에 `role` · `aria-*` 를 붙이지 않고, 넘긴 `attributes` 를 루트에 그대로 붙입니다. 이름이 필요하면 `attributes: {'role': 'group', 'aria-label': '…'}` 처럼 역할과 함께 넘기세요.

### 키보드

없음. 틀은 처리하는 키가 없습니다. 베젤의 버튼, 상태 표시줄, 홈 제스처 바는 동작하는 컨트롤이 아닙니다. `child` 에 넣은 컨트롤은 자기 키보드 동작을 유지합니다.

### 스크린 리더

`child` 의 내용이 읽힙니다. 상태 표시줄은 운영체제를 그린 그림이라 두 플랫폼 모두 보조 기술에서 숨깁니다(Flutter 는 `ExcludeSemantics`, Web 은 `aria-hidden="true"`). 카메라 · 홈 제스처 바 · 버튼에는 글이 없습니다. 기기 모양이나 화면에 담은 스크린샷의 설명은 목업이 만들지 않으므로, 이미지에 대체 텍스트를 직접 붙이세요.

### 포커스 관리

없음. 오버레이가 아니므로 포커스를 옮기거나 가두거나 되돌리지 않습니다. `child` 의 포커스 동작과 순서는 그대로입니다.

### 알려진 제약

- 기기 그림만으로는 화면의 대체 텍스트가 생기지 않습니다.
- 상태 표시줄의 글은 실제 시스템 상태가 아닌 고정된 예시이고, 앱의 언어와 상관없이 같은 글입니다.
- 부모가 몸체보다 좁아도 목업은 스스로 줄지 않습니다.
- 상태 표시줄 글자는 목업 배율로 줄여 그려 아주 작습니다. 읽어야 하는 정보를 대신할 수 없습니다.
- `flat` 마감은 링과 화면 · 페이지의 경계가 면 색 차이뿐입니다. [flat 과 강제 색 모드](#flat-과-강제-색-모드)를 보세요.
- Web 은 서피스 스타일이나 밀도가 모서리를 바꾸면 몸체 · 베젤 · 화면의 모서리가 서로 어긋날 수 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

위젯 이름과 공통 속성은 두 플랫폼이 같습니다. `child` 가 받는 자리의 차이는 [장식과 안전 영역](#장식과-안전-영역)에 있습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 하드웨어 | `Stacks` · `Position` · `OutlinedContainer` | 같은 부품을 절대 위치로 놓은 DOM |
| 림의 밝은 선 · 번짐 빛 | `CustomPaint` 로 상자 안쪽에 선을 그립니다. 번짐 빛은 그라디언트 선에 `ImageFiltered` 흐림을 겁니다. | 안쪽 링 `<div>`. 번짐 빛은 그라디언트를 링 모양으로 잘라 흐림 · 불투명도 래퍼에 담습니다. |
| 상태 표시줄 그림 | `CoreVectorGlyph` 경로를 `CustomPaint` 로 채웁니다. | 그림마다 인라인 `<svg>` 의 `<path>`(`fill-rule` 포함) |
| 상태 표시줄 글자 | 테마의 글자 크기에 목업 배율을 곱합니다. 기기의 글자 크기 설정(`textScaler`)은 받지 않습니다. | 테마의 글자 크기에 목업 배율을 곱해 그립니다. |
| 상태 표시줄 접근성 | `ExcludeSemantics` | `aria-hidden="true"` |
| 안전 영역 | 목업 기준의 `MediaQuery` 와 `SafeArea` (네 변) | 화면 콘텐츠 래퍼의 안쪽 여백 (네 변) |
| 화면 자르기 | `ClipRRect` | 화면 `<div>` 의 `overflow` 와 `border-radius` |
| `flat` 의 링 | 지금 테마의 `surfaceContainerHighest` 색으로 칠합니다. | 같은 색을 `bg-surface-container-highest` 클래스로 칠합니다. |
| `screenBrightness` | 화면을 `BrightnessScope` 로 감싸 그 밝기의 테마로 다시 그립니다. 두 밝기의 테마는 `CoUIApp` 이 전달합니다. 그 밖에서는 둘레 테마와 다른 밝기에 CoUI 기본 색을 씁니다. | 화면을 `data-theme` 가 붙은 상자 없는 래퍼(`display: contents`)로 감싸고, 스타일시트의 범위 규칙이 색 변수를 다시 선언합니다. 실행 중에 `CoUIThemeController.setCustomTheme` 으로 바꾼 팔레트는 이 범위에 닿지 않습니다. |
| 서피스 스타일 · 밀도의 모서리 | 몸체 모서리를 먼저 바꾸고, 그 값에서 거리를 빼서 베젤 · 화면 모서리를 정합니다. | 모서리마다 값을 따로 냅니다. `--coui-radius-*` 단계와 같은 값만 바뀌고 나머지는 그대로라, 셋이 같은 중심의 곡선에서 벗어날 수 있습니다. |
| 서피스 스타일의 그림자 | 몸체 그림자에 스타일의 그림자 모양이 적용됩니다. | 몸체 그림자는 기본 모양 그대로입니다. |
| 크기 | 테마의 크기 배율을 곱합니다. 상태 표시줄의 글자 크기에는 곱하지 않습니다. | 위치와 크기는 `rem` 이라 브라우저의 글자 크기를 따릅니다. |
| 추가 속성 | `key` | `tag` · `id` · `classes` · `css` · `attributes` · `eventHandlers` · `key` |

### flat 과 강제 색 모드

`flat` 은 레일과 바깥 선 · 베젤 선이 없어 링을 화면 · 페이지와 가르는 것이 면 색뿐입니다. CoUI 기본 테마에서 링 색과 `surface` 의 명도 대비는 라이트 약 `1.25 : 1`, 다크 약 `1.76 : 1` 이라 장식 수준의 경계입니다. 강제 색 모드(Windows 고대비 등)는 면 색을 시스템 색으로 바꾸므로 링과 화면의 구분이 사라질 수 있습니다.

그 모드에서도 윤곽이 필요하면 `realistic` 마감을 쓰거나 선을 직접 정합니다. `flat` 은 `railWidth` 가 `0` 이라 베젤이 몸체 전체를 덮습니다. 몸체 선(`borderColor` · `borderWidth`)은 `railWidth` 를 선 두께만큼 함께 적어야 보입니다.

```dart
MockupDevice(
  finish: .flat,
  mockupDeviceStyle: const CoreMockupDeviceStyle(
    railWidth: CoreStrokeWidth.stroke1,
    borderWidth: CoreStrokeWidth.stroke1,
    borderColor: CoreColor.token(CoreColors.outline),
  ),
  child: Text('앱 화면').bodyMedium.onSurface,
)
```

이렇게 하면 화면이 네 변에서 선 두께만큼 줄어듭니다. 화면 크기를 지키면서 평소 화면에 선만 두르려면 `bezelBorderColor` · `bezelBorderWidth` 로 링 바깥에 그립니다. Web 은 이 바깥 선을 `box-shadow` 로 그려 강제 색 모드에서는 남지 않습니다. 모든 `flat` 틀에 적용하려면 같은 값을 `finishStyles` 에 적으세요.

<a id="props-parameters"></a>

## API

`W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다.

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `W` | 필수 | 화면의 안전 영역에 놓는 내용 |
| `device` | `CoreMockupDevice` | `CoreMockupDevice.phone` | 그릴 기기 — `phone` · `tablet` |
| `orientation` | `CoreMockupOrientation` | `CoreMockupOrientation.portrait` | 기기를 든 방향 — `portrait` · `landscape` |
| `finish` | `CoreMockupDeviceFinish` | `CoreMockupDeviceFinish.realistic` | 마감 — `realistic`(기기 그림) · `flat`(장식 없는 미리보기 틀) |
| `width` | `double?` | `null` → `realistic` `320`, `flat` `256` | 몸체 너비(논리 px). 높이는 화면 비율과 베젤에서 계산합니다. |
| `showCamera` | `bool?` | `null` → 마감을 따름 | 카메라와 그 안전 여백. `realistic` 은 켜고 `flat` 은 끕니다. |
| `showStatusBar` | `bool?` | `null` → 마감을 따름 | 상태 표시줄과 그 안전 여백. 기본 스타일의 가로 폰은 상태 표시줄이 없어 이 값을 적어도 달라지지 않습니다. |
| `showGestureBar` | `bool?` | `null` → 마감을 따름 | 홈 제스처 바와 아래 안전 여백 |
| `screenBrightness` | `CoreBrightness?` | `null` → 페이지의 밝기 | 화면과 그 위의 내용 · 상태 표시줄 · 홈 제스처 바를 그릴 밝기 |
| `mockupDeviceStyle` | `CoreMockupDeviceStyle?` | `null` | 하드웨어 · 화면 · 상태 표시줄 · 홈 제스처 바의 겉모습 |

### Web 전용

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `tag` | `String` | `'div'` | 루트 요소의 태그 |
| `id` | `String?` | `null` | 루트 요소의 id |
| `classes` | `String?` | `null` | 루트에 덧붙이는 CSS 클래스 |
| `css` | `Styles?` | `null` | 루트에 덧붙이는 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 루트에 붙이는 HTML 속성 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 루트에 붙이는 이벤트 처리기 |

두 플랫폼 모두 `key` 를 받습니다.

### 메서드

- `withStyle(patch)` — 지금 `mockupDeviceStyle` 에 `patch` 를 합친 사본을 돌려줍니다.
- `copyWith(...)` — 넘긴 값만 바꾼 사본을 돌려줍니다. `null` 을 넘긴 속성은 지금 값을 유지합니다. Web 의 `classes` 는 바꾸지 않고 지금 값에 덧붙입니다.

### 테마

| 이름 | 타입 | 적용 대상 |
| --- | --- | --- |
| `CoreComponentTheme.mockupDevice` | `CoreMockupDeviceTheme?` | `MockupDevice` 의 앱 기본값 |
| `CoreMockupDeviceTheme.style` | `CoreMockupDeviceStyle?` | 모든 `MockupDevice` |
| `CoreMockupDeviceTheme.deviceStyles` | `Map<CoreMockupDevice, CoreMockupDeviceStyle>?` | 기기별 |
| `CoreMockupDeviceTheme.finishStyles` | `Map<CoreMockupDeviceFinish, CoreMockupDeviceStyle>?` | 마감별 |
| `CoreComponentTheme.mockup` | `CoreMockupTheme?` | 목업이 함께 쓰는 값 |

## 관련 컴포넌트

<Cards columns="2">
<Card demo="mockup-device/related-mockup" title="Mockup">

코드 틀을 포함한 목업 모음의 개요와 `CoreMockupDeviceStyle` 필드 표가 있습니다. [Mockup 문서](/components/mockup)

</Card>
<Card demo="mockup-device/related-mockup-foldable" title="MockupFoldable">

가운데가 접히는 기기 틀이 필요할 때 씁니다. [MockupFoldable 문서](/components/mockup-foldable)

</Card>
<Card demo="mockup-device/related-mockup-browser" title="MockupBrowser">

주소창과 창 컨트롤이 있는 창 틀입니다. [MockupBrowser 문서](/components/mockup-browser)

</Card>
<Card demo="mockup-device/related-card" title="Card">

기기 장식 없이 콘텐츠를 담는 면이 필요할 때 씁니다. [Card 문서](/components/card)

</Card>
</Cards>
