---
title: MockupBrowser
description: 주소창과 창 컨트롤이 있는 브라우저 창 틀에 화면을 담아 보여 줍니다. 주소창을 빼면 데스크톱 앱 창이 됩니다.
category: display
platforms: [flutter, web]
related: [mockup, mockup-device, mockup-code, card]
tags: [mockup, browser, window, presentation]
template: v2
source: display/mockup_browser
---

# MockupBrowser

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

화면을 브라우저 창이나 데스크톱 앱 창 모양의 틀에 담아 보여 주는 컴포넌트입니다. 창 컨트롤과 주소창을 켜고 꺼 보고, 만들어진 코드를 복사하세요.

<Playground component="mockup-browser" />

데스크톱 앱 창은 별도 컴포넌트가 아니라 `MockupBrowser(addressBar: null)` 입니다. 미리보기의 창 크기는 바깥 상자가 정한 것이라, 코드만 옮기면 크기는 부모와 `child` 를 따릅니다([배치](#배치)).

여러 목업을 함께 다루는 개요, 스타일 필드의 타입 · 기본값 표, 이전 버전에서 옮겨 오는 방법은 [Mockup](/components/mockup) 에 있습니다.

## 구조

창 몸체 위에 콘텐츠 면이 창 전체를 덮고, 흐림 효과가 있는 반투명 툴바가 그 위쪽에 겹칩니다. 테두리는 맨 위 층에 따로 그려, 콘텐츠와 툴바가 테두리를 가리지 않습니다. `child` 는 툴바 아래에서 시작합니다.

<Anatomy demo="mockup-browser/anatomy">
<AnatomyItem part="container" name="Window">

창 전체입니다. 둥근 모서리(14), 바깥 테두리, 흰색 35% 의 안쪽 윗선, 그림자를 가집니다.

</AnatomyItem>
<AnatomyItem select="div:first-child + div > div:first-child" side="top" name="window controls">

지름 8 의 점 셋입니다. 색은 지금 테마의 `error` · `warning` · `success` 를 따릅니다. `showControls: false` 면 그리지 않습니다.

</AnatomyItem>
<AnatomyItem select="div:has(> svg[data-icon='lucide:chevron-left'])" side="top" name="navigation">

이전 · 다음 화살표를 담은 높이 28 의 캡슐입니다. 다음 화살표는 쓸 수 없는 색(`disabledContent`)으로 그립니다.

</AnatomyItem>
<AnatomyItem select="div:has(> svg[data-icon='lucide:rotate-cw'])" side="top" name="address bar">

남은 폭을 채우는 높이 28 의 알약입니다. 자물쇠, `addressBar` 글, 새로고침 아이콘을 담습니다.

</AnatomyItem>
<AnatomyItem select="div:has(> svg[data-icon='lucide:share'])" side="top" name="actions">

공유와 새 탭 아이콘을 담은 높이 28 의 캡슐입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=content]" side="right" name="child">

창 안에 넣는 내용입니다. 높이 44 의 툴바 자리 아래에 놓입니다.

</AnatomyItem>
</Anatomy>

`addressBar: null` 이면 3 · 4 · 5번 부분을 만들지 않습니다.

## 창 구성

variant 속성은 없습니다. 툴바에 무엇을 그릴지는 `addressBar` 와 `showControls` 두 속성이 정합니다.

<Preview demo="mockup-browser/compositions" />

| `addressBar` | `showControls` | 툴바에 그리는 것 |
| --- | --- | --- |
| 문자열 | `true` (기본) | 창 컨트롤 · 이전/다음 · 주소창 · 공유와 새 탭 |
| 문자열 | `false` | 이전/다음 · 주소창 · 공유와 새 탭. 주소창이 그만큼 넓어집니다. |
| `null` | `true` | 창 컨트롤 (데스크톱 앱 창) |
| `null` | `false` | 없음. 툴바 자리와 아래 구분선은 남고, `child` 는 계속 그 아래에서 시작합니다. |

`addressBar` 를 적지 않으면 `'example.com'` 이 들어갑니다. 앱 창을 만들려면 `null` 을 직접 적으세요. `null` 이면 주소창 · 화살표 · 공유와 새 탭을 감추는 것이 아니라 만들지 않습니다. 빈 문자열(`''`)은 `null` 이 아니므로 글이 없는 주소창이 남습니다.

<Split>

<Code language="dart" title="웹 페이지">
MockupBrowser(
  addressBar: 'https://example.com',
  child: Text('페이지 콘텐츠'),
)
</Code>

<Code language="dart" title="데스크톱 앱 창">
MockupBrowser(
  addressBar: null,
  child: Text('앱 콘텐츠'),
)
</Code>

</Split>

## 주소창

`addressBar` 는 입력창이 아니라 보여 주기만 하는 글입니다. 어떤 문자열이든 그대로 적고, 주소 형식을 검사하거나 그 주소로 이동하지 않습니다. 자물쇠 아이콘은 주소가 무엇이든 함께 그립니다.

<Preview demo="mockup-browser/address" />

| 상황 | 동작 |
| --- | --- |
| 정렬을 정하지 않음 | 자물쇠와 주소가 주소창 앞쪽에 붙고, 새로고침 아이콘은 뒤쪽 끝에 놓입니다. |
| `addressBarTextAlign` 을 스타일이나 앱 테마에서 정함 | 글 칸이 자물쇠와 새로고침 사이의 남은 폭을 채우고, 그 안에서 정렬합니다. 자물쇠는 앞쪽에 그대로 있습니다. |
| 주소가 칸보다 긺 | 한 줄로 두고 말줄임표로 줄입니다. |

<Note>

`CoreMockupBrowserStyle` 의 `defaultAddressBarTextAlign` 은 `center` 이지만, 정렬을 정하지 않은 주소는 위처럼 앞쪽에서 시작합니다. 가운데에 두려면 `addressBarTextAlign: CoreTextAlign.center` 를 직접 적으세요.

</Note>

<a id="동작-스펙-behavior"></a>

## 상태

`MockupBrowser` 에는 hover · pressed · disabled 같은 상태가 없고, 타이머나 상태 전환도 없습니다.

| 부분 | 동작 |
| --- | --- |
| 창 컨트롤 · 화살표 · 자물쇠 · 새로고침 · 공유 · 새 탭 | 장식입니다. 누를 수 없고 URL 이동 · 닫기 · 최소화 콜백이 없습니다. |
| 주소창 | 표시용 글입니다. 입력을 받지 않습니다. |
| `child` | 안에 넣은 버튼 · 입력 같은 컨트롤은 그대로 동작합니다. 맨 위의 테두리 층은 포인터 입력을 가로채지 않습니다. |

흐리게 그린 다음 화살표도 모양일 뿐이며, 이를 켜거나 끄는 속성은 없습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 문서 · 랜딩 · 쇼케이스에서 웹 페이지를 주소창이 있는 창 안에 보여 줄 때
- 창 컨트롤만 있는 데스크톱 앱 창 그림이 필요할 때 (`addressBar: null`)

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 폰 · 태블릿 베젤이 필요할 때 | [MockupDevice](/components/mockup-device) |
| 코드 줄을 편집기 모양의 틀에 보여 줄 때 | [MockupCode](/components/mockup-code) |
| 끌어 옮기고 크기를 바꾸는 창이 필요할 때 | [Window](/components/window) |
| 창 장식 없이 콘텐츠 면만 필요할 때 | [Card](/components/card) |

### 보여 주는 자리에만 씁니다

화면을 창처럼 감싸 보여 주는 틀입니다. 실제 앱의 레이아웃 컨테이너로 쓰지 않습니다. 동작하지 않는 창 컨트롤과 주소창이 실제 컨트롤로 보일 수 있습니다.

### 주소창 문구

주소창 문구는 한 줄로 두고, 창 폭 안에서 끝까지 읽히게 짧게 적습니다.

<Cards columns="2">
<Card demo="mockup-browser/do-short-address" tone="do" eyebrow="이렇게 하세요">

어떤 화면인지 알 수 있는 짧은 주소를 적습니다.

</Card>
<Card demo="mockup-browser/dont-long-address" tone="dont" eyebrow="이렇게 하지 마세요">

경로와 쿼리까지 붙인 긴 주소는 뒷부분이 잘려 보이지 않습니다.

</Card>
</Cards>

### 화면 이미지의 대체 텍스트

목업은 안에 담은 화면의 설명을 만들지 않습니다. 스크린샷을 넣을 때는 이미지에 대체 텍스트를 직접 붙이세요.

<Split>

<Code language="dart" title="Flutter">
MockupBrowser(
  addressBar: 'example.com',
  child: Image.asset(
    'assets/screenshots/dashboard.png',
    fit: BoxFit.cover,
    semanticLabel: '대시보드 화면',
  ),
)
</Code>

<Code language="dart" title="Jaspr Web">
MockupBrowser(
  addressBar: 'example.com',
  child: img(
    src: 'screenshots/dashboard.png',
    alt: '대시보드 화면',
    classes: 'block w-full',
  ),
)
</Code>

</Split>

## 배치

크기 속성은 없습니다. 창의 크기는 부모와 `child` 가 정합니다. Figma 의 미리보기 크기는 380×200 입니다.

<Preview demo="mockup-browser/sizing" />

| 조건 | 크기 |
| --- | --- |
| 폭 | 부모의 폭을 채웁니다. |
| 부모가 높이를 정하지 않음 | `child` 높이에 툴바 자리(기본 `44`)를 더합니다. `chromeWidth`(기본 `0`)를 정하면 아래쪽에 그만큼 더합니다. |
| `child` 가 없음 | 부모가 높이를 정하지 않으면 툴바 자리만 남습니다. |
| 부모가 높이를 정함 | 창이 그 높이를 채우고, `child` 는 툴바 자리 아래의 영역에 놓입니다. |

- Flutter 에서는 폭이 정해진 부모가 필요합니다. `Row` 안에서는 `Expanded` 나 `SizedBox` 로 감싸세요.
- 부모가 높이를 정하면 Flutter 의 `child` 는 남은 영역의 크기를 그대로 받으므로, 가운데에 놓으려면 `Center` 로 감쌉니다. Web 의 블록 `child` 는 자기 높이만 가지므로, 영역을 다 쓰려면 `child` 에 높이를 채우는 클래스(`h-full`)를 줍니다.
- 콘텐츠 면의 칠은 창 전체를 덮지만 `child` 의 영역은 툴바 아래에서 시작합니다. 툴바의 흐림 효과를 보여 주려고 `child` 를 툴바 뒤까지 올리는 속성은 없습니다.
- 좁은 자리에서는 창 컨트롤과 두 캡슐은 줄지 않고 주소창이 줄어듭니다. Flutter 에서 필요한 최소 폭은 [알려진 제약](#알려진-제약)을 보세요.

## 테마와 스타일

무엇을 보여 줄지 고르는 값(`showControls` · `addressBar` · `child`)은 위젯 속성으로 넘깁니다. 색 · 크기 · 간격 · 모서리 · 아이콘과 글자 모양은 `mockupBrowserStyle`(`CoreMockupBrowserStyle`) 하나로 바꿉니다.

<Split>

<Code language="dart" title="창 하나만 바꾸기">
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
  ),
)
</Code>

</Split>

<Preview demo="mockup-browser/styled" />

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
CoreMockupBrowserStyle 의 기본값
  → CoreComponentTheme.mockup.style          // 목업 공유 값
  → CoreComponentTheme.mockupBrowser.style   // 앱의 모든 MockupBrowser
  → mockupBrowserStyle                       // 인스턴스별
```

- 목업 공유 값(`CoreMockupStyle`) 중에서는 `backgroundColor` · `borderColor` · `borderRadius` 만 받습니다. `frameColor` 는 읽지 않습니다.
- 아이콘 스타일(`navIconStyle` · `navDisabledIconStyle` · `actionIconStyle` · `addressIconStyle`)과 글자 스타일(`addressBarTextStyle` · `contentTextStyle`)은 안의 값끼리 합칩니다. 아이콘 색만 정하면 크기는 기본값이 남습니다.
- `boxShadow` 는 목록 전체를 바꿉니다. 빈 리스트를 넘기면 창의 기본 그림자를 그리지 않습니다.

### 바꾸는 곳과 필드

| 바꾸는 곳 | 필드 |
| --- | --- |
| 창 몸체와 테두리 | `backgroundColor` · `borderColor` · `borderWidth` · `borderRadius` · `boxShadow` · `highlightColor` · `highlightWidth` |
| 콘텐츠 면 | `contentBackgroundColor` · `contentBorderRadius` · `contentTextStyle` · `chromeWidth` |
| 툴바 | `toolbarHeight` · `toolbarPadding` · `toolbarSpacing` · `toolbarBackgroundColor` · `toolbarBlur` · `toolbarBorderColor` · `toolbarBorderWidth` |
| 창 컨트롤 | `controlSize` · `controlSpacing` · `controlBorderRadius` · `controlCloseColor` · `controlMinimizeColor` · `controlMaximizeColor` |
| 화살표 · 공유와 새 탭 캡슐 | `capsuleHeight` · `capsulePadding` · `capsuleBorderRadius` · `capsuleBackgroundColor` · `navSpacing` · `actionSpacing` · `navIconStyle` · `navDisabledIconStyle` · `actionIconStyle` |
| 주소창 | `addressBarHeight` · `addressBarPadding` · `addressBarBorderRadius` · `addressBarBackgroundColor` · `addressBarTextStyle` · `addressBarTextAlign` · `addressBarSpacing` · `domainSpacing` · `addressIconStyle` |

필드마다의 타입과 기본값은 [Mockup 의 CoreMockupBrowserStyle 표](/components/mockup#coremockupbrowserstyle)에 있습니다.

- `backgroundColor` 는 콘텐츠 면 뒤의 창 몸체를 칠합니다. 콘텐츠 면이 창 전체를 덮으므로 `contentBackgroundColor` 가 불투명하면 보이지 않습니다. 창 안의 색은 `contentBackgroundColor` 로 바꾸세요.
- `chromeWidth` 는 왼쪽 · 오른쪽 · 아래에서 `child` 를 안으로 들이는 두께입니다. 콘텐츠 면의 칠은 창 전체 그대로입니다.
- `contentBorderRadius` 를 비우면 모서리마다 `borderRadius` 에서 `chromeWidth` 를 뺀 값(0 이상)을 씁니다.
- `contentTextStyle`(기본 `bodySmall` · `onSurfaceVariant`)은 `child` 가 물려받는 글자 모양입니다. 역할이나 색을 따로 정하지 않은 `Text` 는 두 플랫폼 모두 이 값을 씁니다. 역할 체인을 붙인 `Text` 는 플랫폼마다 색이 달라질 수 있으니 `.titleSmall.onSurface` 처럼 색까지 적으세요([플랫폼 차이](#플랫폼-차이)).

### 빠른 덮어쓰기 (체인)

이미 만든 `MockupBrowser` 에 `withStyle` 로 스타일을 덧붙일 수 있습니다. 생성자의 `mockupBrowserStyle` 과 같게 동작하고, 겹치는 필드는 뒤에 붙인 값이 이깁니다. Core 토큰과 이름이 같은 getter 도 있습니다.

| getter | 정하는 필드 |
| --- | --- |
| `.radius0` · `.radius2` · `.radius4` · `.radius6` · `.radius8` · `.radius10` · `.radius12` · `.radius14` · `.radius16` · `.radius20` · `.radius24` · `.radius28` · `.radius32` · `.radius36` · `.radius40` · `.radius48` · `.radius56` · `.radius64` · `.radius9999` | `borderRadius` |
| `.primary` · `.secondary` · `.tertiary` · `.surface` · `.surfaceContainer` · `.error` · `.success` · `.warning` · `.info` · `.outline` · `.transparent` | `backgroundColor` |

색 getter 가 칠하는 `backgroundColor` 는 콘텐츠 면에 가려지므로, 기본 상태에서는 색 getter 를 붙여도 창의 색이 달라지지 않습니다. 창 안의 색은 `withStyle` 로 `contentBackgroundColor` 를 정하세요.

<Code language="dart" title="체인으로 덧붙이기">
MockupBrowser(
  addressBar: 'example.com',
  child: Text('페이지 콘텐츠'),
).radius8.withStyle(
  const CoreMockupBrowserStyle(
    contentBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
  ),
)
</Code>

### 기본값이 있는 곳

겉모습의 기본값은 `coui_core` 의 `CoreMockupBrowserStyle` 에 있는 `default…` 상수이고, Flutter와 Web이 같은 값을 읽습니다. `contentBorderRadius` 는 상수 없이 위의 규칙으로 계산합니다. `showControls` · `addressBar` 의 기본값은 `CoreMockupBrowserContract.defaultShowControls` · `defaultAddressBar` 입니다.

<a id="접근성-accessibility"></a>

## 접근성

### 역할

보여 주기만 하는 틀이며, 브라우저나 앱이라는 역할을 스스로 붙이지 않습니다. 안의 `child` 는 자기 의미를 유지합니다.

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | 창을 감싸는 `Semantics` 를 만들지 않습니다. 창을 설명해야 하면 `Semantics(container: true, label: '브라우저 목업: 문서 화면', child: …)` 처럼 감싸세요. |
| Jaspr Web | 컴포넌트가 붙이는 `role` · `aria-*` 가 없고, 넘긴 `attributes` 는 루트에 그대로 붙습니다. 이름이 필요하면 `attributes: {'role': 'group', 'aria-label': '…'}` 처럼 역할과 함께 넘기세요. |

### 키보드

| 키 | 동작 |
| --- | --- |
| 없음 | 창 틀이 처리하는 키가 없습니다. |

`child` 안의 링크 · 버튼은 각자의 키보드 동작을 유지합니다. 창 컨트롤 그림은 실제 닫기 · 최소화 버튼이 아닙니다.

### 스크린 리더

- 주소창 글은 평범한 글로 읽힙니다. 주소창이라는 맥락은 전해지지 않습니다. 말줄임표로 잘려 보여도 글 전체가 접근성 정보에 남습니다.
- 창 컨트롤 점에는 글이 없고, 아이콘에는 이름이 없습니다. 자물쇠 그림은 보안 상태를 알려 주지 않습니다.
- Web 의 DOM 에서는 콘텐츠 면이 툴바보다 앞에 있습니다. 문서 순서대로 읽으면 `child` 를 지난 뒤에 주소 글이 나옵니다.
- 화면 이미지의 대체 텍스트는 직접 붙여야 합니다.

### 포커스 관리

없음. 오버레이가 아니므로 포커스를 옮기거나 가두거나 되돌리지 않습니다. 틀은 포커스를 받지 않고 `child` 의 포커스 순서를 그대로 둡니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 주소창은 편집할 수 있는 입력이 아니며 창 컨트롤도 동작하지 않습니다. 실제 브라우저 UI 처럼 안내하지 마세요. |
| 공통 | 콘텐츠 면은 `child` 를 자기 경계에서 잘라 냅니다. 창 가장자리에 바로 붙인 컨트롤은 바깥에 그리는 포커스 링이 잘릴 수 있으니 안쪽 여백을 두세요. |
| Flutter | 툴바의 점 · 캡슐 · 아이콘은 줄지 않습니다. 기본 스타일에서 창 컨트롤과 주소창을 함께 보이면 계산상 약 225(창 컨트롤을 끄면 약 181) 논리 px 의 폭이 필요하고, 그보다 좁으면 툴바가 넘칩니다. 테마의 크기 배율이나 밀도를 바꾸면 이 값도 달라집니다. |

여러 목업에 공통인 접근성 내용은 [Mockup](/components/mockup) 에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

공통 속성의 이름과 기본값은 같고, 그리는 방식은 각 플랫폼을 따릅니다. Web 의 `child` 타입은 `Widget` 대신 `Component` 입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 몸체 | `OutlinedContainer` 안의 `Stacks` 에 콘텐츠 면 · 툴바 · 맨 위 테두리를 겹칩니다. | 루트 `<div>` 안의 `OutlinedContainer` 에 같은 세 층의 `<div>` 를 겹칩니다. |
| 툴바 흐림 | `ClipRRect` 안의 `BackdropFilter` | `backdrop-filter` |
| 안쪽 윗선 | `InsetShadow`. 창의 바깥 가장자리부터 그려 위쪽 테두리 선에 겹칩니다. 서피스 스타일의 그림자 변형도 받아, 네오 브루탈리즘에서는 흰 띠가 위와 왼쪽 가장자리에 더 두껍게 보입니다. | 안쪽 `box-shadow`. 위쪽 테두리 선 바로 안쪽에 그리며, 서피스 스타일이 이 선의 위치를 옮기지 않습니다. |
| 주소 | `Expanded` 알약 안의 한 줄 말줄임 `Text` | 남은 폭을 채우는 알약 `<div>` 안의 한 줄 말줄임 글 |
| 앱 창 (`addressBar: null`) | 주소창 · 화살표 · 공유 위젯이 트리에 없습니다. | 해당 `<div>` 가 DOM 에 없습니다. |
| 콘텐츠 클립 | 둥근 모서리로 자르는 `Container` 와 `Padding` | 넘침을 숨기는 `<div>` 와 안쪽 여백 `<div>` |
| 폭 | 폭이 정해진 부모가 필요합니다. | 블록 폭(`w-full`)으로 부모를 채웁니다. |
| 부모가 높이를 정했을 때의 `child` | 남은 영역의 크기를 그대로 받습니다. | 블록 요소는 자기 높이만 가집니다. |
| 색을 정하지 않은 `child` 의 `Icon` | 주변 `IconTheme` 의 색을 씁니다. `CoUIApp` 기본값은 `onSurface` 입니다. | 글자색을 물려받아 `contentTextStyle` 의 색을 따릅니다. |
| 색 없이 역할 체인만 붙인 `child` 의 `Text` | 역할 체인은 기본 글자색(`onSurface`)에서 시작합니다. | `contentTextStyle` 의 색을 물려받습니다. |
| 툴바 위쪽 모서리 | 창 모서리와 같이 서피스 스타일과 밀도가 반영됩니다. | `borderRadius` 의 숫자를 그대로 `rem` 으로 씁니다. 서피스 스타일이 모서리를 바꾸거나 `--coui-radius-*` 를 덮어쓰면 창 모서리와 다를 수 있습니다. |
| 크기 배율 | 창의 길이에 테마의 크기 배율이 적용됩니다. | 높이와 간격은 `rem` 단위라 브라우저의 글자 크기를 따릅니다. 테두리 두께는 `px` 입니다. |
| 루트 설정 | `key` | `key` 와 함께 `tag` · `id` · `classes` · `css` · `attributes` · `eventHandlers` |

툴바의 아이콘은 패키지에 들어 있어, Web 에서도 `iconScript()` 없이 그려집니다.

<a id="props-parameters"></a>

## API

`W` 는 Flutter의 `Widget`, Web의 Jaspr `Component` 입니다.

### 생성자

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `showControls` | `bool` | `true` | 툴바 앞쪽에 창 컨트롤 점 셋을 그립니다. `false` 면 점만 빠집니다. |
| `addressBar` | `String?` | `'example.com'` | 주소창에 보여 줄 글. `null` 이면 주소창 · 이전/다음 · 공유와 새 탭을 만들지 않습니다. |
| `child` | `W?` | `null` | 창 안에 넣을 내용. 툴바 자리 아래에 놓입니다. |
| `mockupBrowserStyle` | `CoreMockupBrowserStyle?` | `null` | 창 몸체 · 툴바 · 콘텐츠 면의 겉모습 |
| `key` | `Key?` | `null` | 위젯 · 컴포넌트 식별 키 |

### Web 전용 속성

모두 루트 요소에 적용됩니다.

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `tag` | `String` | `'div'` | 루트 요소의 태그 |
| `id` | `String?` | `null` | 루트 요소의 `id` |
| `classes` | `String?` | `null` | 루트에 덧붙일 클래스 |
| `css` | `Styles?` | `null` | 루트에 덧붙일 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 루트에 붙일 HTML 속성 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 루트에 연결할 이벤트 처리 함수 |

### 그 밖의 멤버

- `withStyle(patch)` — 지금 스타일에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다.
- `copyWith(...)` — 바꾼 값으로 사본을 만들고, 넘기지 않은 값은 그대로 둡니다. `addressBar` 는 함수로 받으므로 `copyWith(addressBar: () => null)` 로 앱 창으로 바꿀 수 있습니다. `child` 와 `mockupBrowserStyle` 은 `copyWith` 로 비울 수 없습니다. Web 에서 넘긴 `classes` 는 기존 값을 바꾸지 않고 함께 남습니다.

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.mockupBrowser` | `CoreMockupBrowserTheme?` | 앱의 모든 `MockupBrowser` 에 적용합니다. `style: CoreMockupBrowserStyle?` 하나를 가집니다. |
| `CoreComponentTheme.mockup` | `CoreMockupTheme?` | 목업 공유 값. `style: CoreMockupStyle?` 중 `backgroundColor` · `borderColor` · `borderRadius` 를 받습니다. |

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="mockup-browser/related-mockup" title="Mockup">

앱 창 · 코드 틀 같은 목업을 함께 설명하는 개요입니다. [Mockup 문서](/components/mockup)

</Card>
<Card demo="mockup-browser/related-mockup-device" title="MockupDevice">

폰 · 태블릿 베젤이 필요할 때 씁니다. [MockupDevice 문서](/components/mockup-device)

</Card>
<Card demo="mockup-browser/related-mockup-code" title="MockupCode">

코드 줄을 편집기 모양의 틀에 담습니다. [MockupCode 문서](/components/mockup-code)

</Card>
<Card demo="mockup-browser/related-card" title="Card">

창 장식 없이 콘텐츠를 담는 면이 필요할 때 씁니다. [Card 문서](/components/card)

</Card>
</Cards>
