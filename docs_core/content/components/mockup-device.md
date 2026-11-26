---
title: MockupDevice
description: 폰·태블릿 디바이스 베젤 프레임 목업
category: display
platforms: [flutter, web]
related: [mockup, mockup-foldable, mockup-browser, card]
tags: [mockup, device, phone, tablet, presentation]
---

# MockupDevice

폰·태블릿 디바이스 베젤 프레임 목업입니다. 기본 `device` 는 폰이고, 태블릿은 `device: .tablet` 입니다. 카메라·상태 표시줄·홈 제스처 바·SafeArea·가로 방향의 스펙은 [Mockup](/components/mockup) 에 있습니다.

## Live Preview

<LivePreview component="mockup-device" variants="default,flat,screen-brightness" />

## 사용 시기 (When to Use)

**이 컴포넌트를 사용하세요:**

- 랜딩이나 문서에서 앱 화면을 기기 프레임 안에 보여줄 때

**대신 다른 컴포넌트를 사용하세요:**

- 가운데가 접히는 기기는 [`MockupFoldable`](/components/mockup-foldable)
- 브라우저·앱 창 프레임은 `MockupBrowser`
- 코드 에디터 프레임은 `MockupCode`

## 기본 사용법 (Basic Usage)

```dart
MockupDevice(
  child: Text('App Screen').bodyMedium.onSurface,
)

MockupDevice(
  device: .tablet,
  child: Text('App Screen').bodyMedium.onSurface,
)

// 가로로 돌린 폰 — 카메라가 화면 왼쪽 가장자리로 가고 상태 표시줄은 없다
MockupDevice(
  orientation: .landscape,
  child: Text('App Screen').bodyMedium.onSurface,
)

// 마감을 flat 으로 — 기기 그림이 아니라 미리보기 틀로 쓴다
MockupDevice(
  finish: .flat,
  child: Text('App Screen').bodyMedium.onSurface,
)

// 장식과 그 장식이 확보하던 안전 여백을 각각 끈다
MockupDevice(
  showCamera: false,
  showStatusBar: false,
  showGestureBar: false,
  child: Text('App Screen').bodyMedium.onSurface,
)

// 어두운 화면 안에 밝은 앱을 미리 보인다 — 화면만 그 밝기로 그린다
MockupDevice(
  finish: .flat,
  screenBrightness: .light,
  child: Text('App Screen').bodyMedium.onSurface,
)
```

레일·베젤·화면·카메라·버튼·안테나 띠·상태 표시줄·홈 제스처 바의 겉모습은 전부 `mockupDeviceStyle` (`CoreMockupDeviceStyle`) 하나로 바꿉니다.

## Props / Parameters

`W` 는 Flutter의 Widget / Web의 Jaspr Component입니다.

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `child` | `W` | 필수 | 기기 화면 안 콘텐츠 |
| `device` | `CoreMockupDevice` | `phone` | phone / tablet |
| `orientation` | `CoreMockupOrientation` | `portrait` | portrait / landscape |
| `finish` | `CoreMockupDeviceFinish` | `realistic` | realistic(기기 그림) / flat(장식 없는 미리보기 틀) |
| `width` | `double?` | `null → 마감별(realistic 320 · flat 256)` | 기기 본체 너비 (논리 px). 높이는 화면 비율·베젤에서 파생. flat 의 256 은 화면 240 + 링 8×2 |
| `showCamera` | `bool?` | `null → 마감을 따름` | 카메라 장식과 해당 안전 여백. `null` 이면 realistic 은 그리고 flat 은 그리지 않는다 |
| `showStatusBar` | `bool?` | `null → 마감을 따름` | 화면 위쪽 상태 표시줄(시계·신호·Wi-Fi·배터리)과 해당 상단 안전 여백. `null` 이면 realistic 은 그리고 flat 은 그리지 않는다. 가로로 돌린 폰은 상태 표시줄이 없어 무시한다 |
| `showGestureBar` | `bool?` | `null → 마감을 따름` | 홈 제스처 바 장식과 해당 안전 여백. `null` 이면 realistic 은 그리고 flat 은 그리지 않는다 |
| `screenBrightness` | `CoreBrightness?` | `null → 페이지의 밝기` | 화면과 그 위의 콘텐츠·상태 표시줄·홈 제스처 바를 그릴 밝기. 본체·베젤·버튼은 페이지의 밝기를 따른다 |
| `mockupDeviceStyle` | `CoreMockupDeviceStyle?` | `null` | 하드웨어·화면·상태 표시줄·제스처 바의 겉모습을 바꾸는 값 묶음 |

## 동작 스펙 (Behavior)

- `finish` 는 기기 그림(realistic)과 미리보기 틀(flat)을 가릅니다. realistic 이 기본이며 아래 하드웨어 설명은 모두 realistic 의 것입니다. flat 은 레일·버튼·안테나 띠·림 광택·렌즈·몸체 그림자를 그리지 않고, 두께 8 의 링과 반경 32 의 몸체에 반경 24 의 화면이 놓인 틀입니다. 링과 몸체 색은 테마의 `surfaceContainerHighest` 를 따라 밝기에 맞게 바뀌고, 화면 면은 realistic 과 같은 `surface` 입니다.
- flat 의 화면 비율은 1:2 이고 `device` 와 무관합니다 — 태블릿도 1:2 이며 가로로 돌리면 2:1 입니다. 기본 본체 너비 256 은 화면 폭 240 에 링 8×2 를 더한 값이라 화면이 240×480 으로 서고, `width` 를 적으면 그 값이 이깁니다. flat 은 기기를 그린 그림이 아니라 화면 콘텐츠를 담는 틀입니다.
- `showCamera` / `showStatusBar` / `showGestureBar` 를 적지 않으면(`null`) 마감을 따릅니다 — realistic 은 셋 다 그리고 flat 은 셋 다 그리지 않습니다. 명시하면 마감과 무관하게 그 값이 이기므로 flat 에서도 `true` 를 적으면 해당 장식과 안전 여백이 생깁니다.
- 화면 내용은 카메라·상태 표시줄·홈 바를 피하는 목업 안전 영역 안에 놓습니다. showCamera / showStatusBar / showGestureBar를 끄면 그 장식과 대응 여백도 없어지고, 세 옵션은 서로 독립입니다. 위 여백은 상태 표시줄 높이와 위쪽 가장자리를 파고든 카메라의 몫 중 큰 쪽이고, 가로로 돌린 폰은 왼쪽 가장자리의 카메라 몫이 왼쪽 여백으로 잡힙니다.
- 상태 표시줄은 화면의 `backgroundColor` 를 바탕으로 한 불투명 줄이며 자식 위, 카메라 뒤에 놓입니다. 상태 표시줄과 홈 제스처 바의 길이는 iOS point 로 저작하고 기기·방향별 고정 배율로 그립니다. 본체 너비가 달라져도 카메라·상태 표시줄의 세로 위치, 글자·아이콘 크기와 홈 바 길이는 유지됩니다. 폰 상태 표시줄의 좌우 그룹은 고정 폭의 영역에서 가운데 정렬되고 그 영역은 화면 양쪽 가장자리에 고정됩니다. 태블릿의 두 그룹도 양쪽 가장자리에 붙습니다. 하드웨어 길이는 논리 px 그대로입니다.
- device / orientation / width로 본체·화면·버튼·안테나 띠 지오메트리를 계산합니다. 폰은 카메라 알약이 화면을 파고 안테나 띠가 있으며, 태블릿은 카메라가 위쪽 베젤 띠 안에 있고 안테나 띠가 없습니다. 돌리면 버튼과 안테나 띠의 변이 시계방향으로 한 칸 옮겨 가고 폰의 카메라는 화면 왼쪽 가장자리로 갑니다.
- realistic 하드웨어(몸체·림·베젤·버튼·카메라·안테나 띠)의 색은 디자이너 사본의 값을 그대로 적은 리터럴이라, 앱의 밝기나 고대비 설정이 바뀌어도, 앱이 브랜드 팔레트를 써도 기기는 그대로이고 화면·상태 표시줄·홈 제스처 바만 바뀝니다. 슬롯별 기본값은 [Mockup](/components/mockup) 에 있습니다. 버튼 광택·림 글로·베젤 안쪽 그림자·몸체 드롭 섀도는 흰색이나 검정을 알파로 겹친 광학 효과로 역시 리터럴이고, 몸체 아래 그림자는 어느 모드에서나 검정입니다.
- `screenBrightness` 를 적으면 화면을 [`BrightnessScope`](/guides/theming#부분-트리만-다른-밝기로) 로 감쌉니다. 화면 면과 그 위의 콘텐츠·상태 표시줄·카메라·홈 제스처 바가 그 밝기의 색(팔레트·고대비·서페이스 스타일이 굽힌 색)과 그림자 세기, 재질의 채움 몫·어둡게 하기로 그려지고, 본체·베젤·버튼은 페이지의 밝기에 남습니다 — 어두운 편집기 안에 밝은 앱 화면을 미리 보이는 경우입니다. 지오메트리는 어느 밝기에서나 같습니다. 적지 않으면(`null`) 화면도 페이지의 밝기를 따릅니다.
- 상태 표시줄의 시각·날짜·배터리 문구(`9:41` · `오전` · `4월 1일 수요일` · `100%`)는 캡처한 한 순간의 표본이라 시간이 흐르지 않고 로케일도 따르지 않습니다.
- 실제 OS 전환·기기 입력·회전 콜백·비활성 상태·애니메이션은 제공하지 않습니다.
- child의 컨트롤은 목업 안에서 그대로 동작합니다. 주소창이 있는 창 프레임이면 **[MockupBrowser](/components/mockup-browser)**, 코드 편집기 장식이면 **[MockupCode](/components/mockup-code)** 입니다.

## 사용 가이드라인 (Usage Guidelines)

- 스크린샷처럼 가벼운 자식을 넣습니다. 애니메이션이 많은 앱 트리를 프레임 안에 렌더하면 성능이 나빠집니다.
- 실제 앱 UI 의 컨테이너로 쓰지 않습니다. 문서·프레젠테이션·데모용입니다.

## 접근성 (Accessibility)

### 역할

정적 디바이스 프레임이며 폰·태블릿 운영체제 역할을 붙이지 않습니다.
안의 `child` 는 자기 시맨틱을 유지합니다.

### 키보드

프레임 자체의 키보드 조작은 없습니다. 안에 넣은 컨트롤만 자신의 키보드 동작을
유지하며, 베젤의 버튼·상태 표시줄·제스처 바는 동작하는 시스템 컨트롤이 아닙니다.

### 스크린 리더

자식 콘텐츠가 읽힙니다. 상태 표시줄은 운영체제를 그린 그림이라 양 플랫폼 모두 보조 기술에서 숨깁니다
(Flutter 는 시맨틱 트리에서 빼고, Web 은 `aria-hidden="true"`). 기기 모양이나 스크린샷 자체의
설명이 필요하면 호출부가 의미와 이름을 제공해야 합니다. Web 프레임은 순수 래퍼입니다.

### 포커스 관리

프레임은 포커스를 자동으로 옮기거나 가두지 않습니다. 자식은 카메라·상태 표시줄·제스처 바를
피하는 안전 영역 안에 놓이고 자신의 포커스 동작을 유지합니다.

### 알려진 제약

기기 프레임 그림만으로 운영체제 내비게이션이나 화면의 대체 텍스트가 생기지
않습니다. 상태 표시줄의 시각·날짜·배터리 문구는 실제 시스템 상태가 아니라 고정된
표본입니다. 공통 스펙은 [Mockup](/components/mockup) 을 보세요.

## 크로스 플랫폼 차이점 (Platform Differences)

| 항목 | Flutter | Web |
|------|---------|-----|
| 하드웨어 | Stacks·Position·OutlinedContainer | 같은 부품의 절대 배치 DOM |
| 림 하이라이트·글로 | `CustomPaint` 로 박스 안쪽에 stroke (글로는 그라디언트 셰이더 + `ImageFiltered` 블러) | 안쪽 링 `<div>`, 글로는 그라디언트를 링 마스크로 잘라 블러·불투명도 래퍼에 담음 |
| 상태 표시줄 글리프 | `CoreVectorGlyph` 경로를 `CustomPaint` 로 채움 | 글리프마다 인라인 `<svg>` 의 `<path>` (`fill-rule` 포함) |
| 상태 표시줄 글자 | 역할을 푼 `TextStyle` 의 글자 크기를 화면 배율로 줄이고 호스트 글자 배율은 받지 않음 | 역할 클래스에 배율을 곱한 인라인 `font-size` |
| 상태 표시줄 접근성 | `ExcludeSemantics` 로 시맨틱 트리에서 뺌 | `aria-hidden="true"` |
| 안전영역 | 목업 MediaQuery와 SafeArea를 주입해 이중 inset 방지 (왼쪽·위·오른쪽·아래) | 화면 콘텐츠 래퍼의 CSS inset (네 변) |
| 화면 클립 | ClipRRect | 화면 overflow·radius |
| 호스트 속성 | key | tag · id · attributes · 이벤트 전달 |
| flat 의 경계 | 링·몸체가 `surfaceContainerHighest` 면 하나로 그려짐 | 같은 면 색을 `bg-surface-container-highest` 클래스로 그림 |
| `screenBrightness` | 화면을 `BrightnessScope` 로 감싸 그 밝기의 테마(`CoUIApp` 이 발행한 것)로 다시 해석 | 화면을 `data-theme` 를 단 상자 없는 래퍼(`display: contents`)로 감싸고, 스타일시트의 범위 규칙이 색 변수를 다시 선언 |

### flat 과 강제 색 모드

flat 은 레일·바깥 선·베젤 선이 없어 링과 화면·페이지를 가르는 경계가 면 색 하나뿐입니다. 면 색 대비는 페이지 위에서 Dark 1.77, Light 1.25 로 장식적인 경계에 머뭅니다. 강제 색 모드(Windows 고대비 등)는 면 색을 시스템 색으로 바꾸므로 그 모드에서는 링과 화면의 구분이 사라질 수 있습니다. 그 모드에서도 틀의 윤곽이 필요하면 realistic 을 쓰거나 호출부가 `mockupDeviceStyle` 로 경계 색·두께를 명시합니다.
