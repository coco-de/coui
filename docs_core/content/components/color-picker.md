---
title: ColorPicker
description: 색상을 선택하고 편집하는 색상 선택기 컴포넌트
category: form
platforms: [flutter, web]
related: [text-field, slider]
tags: [interactive, form-control, color]
template: v2
source: form/color_picker
---

# ColorPicker

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 ColorPicker 를 확인하고, 만들어진 코드를 복사하세요. 트리거를 누르면 실제 패널이 열립니다. `promptMode` 를 `inline` 으로 바꾸면 패널이 그 자리에 펼쳐지고, 트리거가 없으므로 `showHexInput` 은 효과가 없습니다. 색의 타입이 달라 코드는 플랫폼마다 따로 보입니다.

<Playground component="color-picker" />

색은 Flutter 에서는 `Color`, Web 에서는 `#RRGGBB` 문자열로 주고받습니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
ColorPicker(
  color: _color, // Color(0xFF3B82F6)
  onChanged: (color) => setState(() => _color = color),
)

// 알파 막대를 보이고 HSL 입력으로 시작
ColorPicker(
  color: _color,
  onChanged: handleColorChanged,
  showAlpha: true,
  pickerMode: CoreColorPickerMode.hsl,
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
ColorPicker(
  color: _hex, // '#3B82F6'
  onChanged: (hex) => setState(() => _hex = hex),
)

ColorPicker(
  color: _hex,
  onChanged: handleColorChanged,
  showAlpha: true,
  pickerMode: CoreColorPickerMode.hsl,
)
```

  </TabItem>
</Tabs>

## 구조

기본 모양은 다른 입력과 같은 필드형 트리거입니다. 필드 상자 안에 색 견본(스와치), 고른 색의 hex, 아래 꺾쇠가 10 간격으로 놓입니다. 상자의 폭은 내용에 맞고 184 보다 좁아지지 않습니다.

<Anatomy demo="color-picker/anatomy">
<AnatomyItem part="container" side="left" name="trigger">

필드 상자. `surface` 바탕, `outlineVariant` 테두리 1, 모서리 10 입니다. 안쪽 여백은 시작 · 위 · 아래 4, 끝 12 입니다.

</AnatomyItem>
<AnatomyItem select="button" side="top" name="swatch">

32 크기, 모서리 6 의 색 견본. `outlineVariant` 테두리 1 을 두릅니다.

</AnatomyItem>
<AnatomyItem select="button + span" side="right" name="value">

고른 색의 hex(`labelMedium`, `onSurface`). 색이 없으면 자리표시 글자(`bodySmall`, `onSurfaceVariant`)를 보입니다. 기본 문구는 "고른 색이 없어요" 입니다.

</AnatomyItem>
<AnatomyItem select="svg" side="right" name="chevron">

16 크기의 아래 꺾쇠(`onSurfaceVariant`).

</AnatomyItem>
</Anatomy>

트리거를 누르면 열리는 패널은 위에서부터 제목(`dialogTitle` 을 준 경우), 모드 탭, 채도 · 명도 영역, 색조 막대, 알파 막대(`showAlpha`), HEX · 채널 입력, 최근 색, 액션 줄 순서입니다.

<Anatomy demo="color-picker/panel-anatomy">
<AnatomyItem part="container" side="left" name="panel">

패널 상자. 내용 폭 240, 안쪽 여백 16, 모서리 14, 묶음 사이 간격 16 입니다.

</AnatomyItem>
<AnatomyItem select="[role=radiogroup]" side="right" name="mode tabs">

RGB · HSL · HSV 를 고르는 탭. 패널 폭을 셋으로 나눕니다.

</AnatomyItem>
<AnatomyItem select="[role=radiogroup] + div" side="left" name="saturation · value">

가로가 채도, 세로가 명도인 정사각 영역. 둥근 핸들이 고른 지점을 가리킵니다.

</AnatomyItem>
<AnatomyItem select="[role=slider]" side="right" name="hue">

색조 막대.

</AnatomyItem>
<AnatomyItem select="[role=slider] + [role=slider]" side="left" name="alpha">

`showAlpha` 를 켜면 보이는 알파 막대. 표시만 합니다.

</AnatomyItem>
<AnatomyItem select="input" side="left" name="HEX · channels">

전체 값을 고치는 HEX 칸과, 모드에 따른 채널 칸 셋.

</AnatomyItem>
<AnatomyItem select="[role=button]" side="left" name="recent colors">

최근에 저장한 색. 기록 범위에 색이 있을 때만 보입니다.

</AnatomyItem>
<AnatomyItem select="button" side="left" name="eye dropper">

화면에서 색을 뽑는 버튼. 브라우저가 지원할 때만 보입니다.

</AnatomyItem>
<AnatomyItem select="button + div + span" side="right" name="compare">

인라인 패널에만 있는 이전 · 현재 색 비교 칸. 팝오버 패널에는 이 자리에 취소 · 저장 버튼이 놓입니다.

</AnatomyItem>
</Anatomy>

<Note>

위의 패널은 그림이 아니라 인라인 모드의 실제 `ColorPicker` 입니다. 팝오버로 여는 패널도 같은 부품을 쓰지만, 비교 칸 대신 취소 · 저장 버튼이 있고 그림자를 두릅니다. 실제 팝오버는 플레이그라운드의 트리거로 열어 보세요. 문서 사이트의 이 그림은 서버에서 미리 그린 화면이라 어느 브라우저에서나 스포이드 버튼이 보입니다. 실제 앱에서는 지원하지 않는 브라우저와 Flutter 네이티브 앱에서 이 버튼이 보이지 않습니다.

</Note>

<a id="변형-variants"></a>

## 표시 방식

variant 와 크기 축은 없습니다. 패널을 어떻게 보일지는 `promptMode` 로 고릅니다.

| `promptMode` | 모양 |
| --- | --- |
| `popover` (기본) | 닫힌 트리거를 보이고, 누르면 패널이 팝오버로 열립니다. 저장해야 색이 확정됩니다. |
| `inline` | 트리거 없이 패널을 그 자리에 펼쳐 둡니다. 고치는 대로 확정됩니다. |
| `dialog` | 지금은 `popover` 와 똑같이 그립니다. |

### 팝오버

<Preview demo="color-picker/popover" />

패널은 트리거 아래 가운데에 4 떨어져 열리고, 화면 가장자리에 닿으면 반대쪽으로 뒤집거나 안으로 밀어 넣습니다(가장자리 여백 8). 페이지를 스크롤해도 닫히지 않습니다. 패널은 `surfaceBright` 바탕, `outlineVariant` 테두리 1, 모서리 14, 그림자 `lg` 이고, 내용 폭 240 에 안쪽 여백 16, 묶음 사이 간격 16 입니다. 배경은 막지 않습니다.

<a id="swatch-hex-텍스트-입력"></a>

### 트리거 옆 hex 입력

`showHexInput: true`(또는 `showLabel: true`)면 트리거 오른쪽에 8 떨어져 폭 96 의 `md` [TextField](/components/text-field) 가 붙습니다. `#RRGGBB` 6자리(`#` 는 빼도 됩니다)가 되는 순간, 저장을 누르지 않아도 `onChanged` 를 부릅니다. `showLabel` 은 라벨 글자를 그리지 않고 같은 입력을 켭니다.

```dart
ColorPicker(
  color: _color, // Web 은 '#3B82F6' 같은 문자열
  showHexInput: true,
  onChanged: handleColorChanged,
)
```

<Note>

이 입력은 팝오버의 트리거 안에 있어서, 입력을 누르면 팝오버도 함께 열리고 닫힙니다. 열린 상태에서 여기에 새 색을 넣은 뒤 패널의 저장을 누르면, 패널에 남아 있던 옛 색이 방금 넣은 색을 덮어쓸 수 있습니다([알려진 제약](/components/color-picker#알려진-제약)).

</Note>

<a id="인라인-inline"></a>

### 인라인

`promptMode: CoreColorPickerPromptMode.inline` 은 테마 편집기처럼 색을 계속 보며 고르는 화면을 위한 모양입니다. 패널 상자는 [Popup](/components/popup)(`inlinePanelStyle`, 모서리 14, 그림자 없음)이고, 색을 고치는 대로 `onChanged` 를 부르므로 취소 · 저장 대신 이전 / 현재 색 비교 칸이 액션 줄 끝에 놓입니다.

<Preview demo="color-picker/inline" height="hug" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
ColorPicker(
  color: _color,
  promptMode: CoreColorPickerPromptMode.inline,
  onChanged: (color) => setState(() => _color = color),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
ColorPicker(
  color: _hex,
  promptMode: CoreColorPickerPromptMode.inline,
  onChanged: (hex) => setState(() => _hex = hex),
)
```

  </TabItem>
</Tabs>

- 비교 칸의 "이전" 은 고치기 전에 받은 색입니다. picker 가 내보내지 않은 색을 새로 넘기면 그 색이 새 "이전" 이 됩니다.
- 인라인에서 고른 색은 최근 색에 넣지 않습니다. 넣으면 드래그하는 동안의 모든 색이 기록됩니다.
- `enabled: false` 면 패널은 보이지만 입력을 받지 않습니다. 모드 탭 · HEX 칸 · 채널 칸 · 최근 색 · 스포이드 버튼은 비활성 모양이 되고, 채도 · 명도 영역, 색조 · 알파 막대, 비교 칸의 모양은 그대로입니다.
- `showHexInput` · `showLabel` 은 효과가 없습니다. 패널에는 늘 HEX 칸이 있습니다.

<a id="동작-스펙-behavior"></a>
<a id="상태-전환"></a>

## 상태

<Preview demo="color-picker/states" />

| 상태 | 보이는 모습과 동작 |
| --- | --- |
| 고른 색 | 스와치를 그 색으로 채우고 hex 를 보입니다. |
| 색 없음 | 채움 없는 점선 스와치와 자리표시 글자를 보입니다. |
| 마우스 올림 | 필드 상자의 모양은 바뀌지 않습니다. 누르기 커서는 두 플랫폼 모두 스와치 위에서만 보입니다. |
| 열림 (팝오버) | 150ms 동안 열리고 100ms 동안 닫힙니다. 트리거를 다시 누르거나 바깥을 누르면 닫히고, Web 은 `Escape` 로도 닫힙니다. |
| 비활성 (팝오버 모드) | 스와치 테두리가 `disabledOutline` 이 되고, 채운 스와치는 반투명해집니다(점선 스와치는 점선 색만 바뀝니다). 필드 상자 · 글자 · 꺾쇠는 그대로입니다. 팝오버를 만들지 않아 열리지 않고, 트리거 옆 hex 입력도 비활성입니다. [인라인](/components/color-picker#인라인-inline)의 비활성은 따로 설명합니다. |

`enabled` 의 기본값은 `true` 이고, `onChanged` 를 주지 않아도 바뀌지 않습니다.

<a id="색-없음-empty-swatch"></a>

### 색 없음

색 없음은 별도 속성이 아니라 값으로 나타냅니다. Flutter 는 완전히 투명한 `Color`(알파 0), Web 은 `#` 뒤에 16진수 6자리가 오지 않는 문자열(빈 문자열 등)입니다. Web 에서는 `#FFF` 같은 3자리, 8자리, `#` 가 없는 값도 색 없음으로 읽습니다.

- 트리거는 채움 없는 점선(대시 3, 간격 2, 선 폭 1) 스와치와 `placeholder`(기본 "고른 색이 없어요", `triggerPlaceholderTextStyle`)를 보입니다.
- 처음부터 색이 없으면 패널은 검정(`#000000`)에서 시작합니다. Flutter 는 넘긴 투명 색의 RGB 에서 시작하므로, `Color(0x00000000)` 을 넘기면 검정입니다.
- 팝오버에서 고치면 트리거가 채워지고, 취소하면 다시 점선으로 돌아갑니다. 아무것도 고치지 않고 저장하면 그 시작 색이 확정됩니다.

<a id="색-commit-흐름"></a>

### 값이 확정되는 때

| 조작 | `onChanged` | 최근 색에 넣기 |
| --- | --- | --- |
| 팝오버 패널에서 고치기 (드래그 · 입력 · 최근 색 · 스포이드) | 부르지 않습니다. 트리거가 미리 보여 줍니다. | 넣지 않습니다. |
| 팝오버의 저장 | 부릅니다. | 넣습니다. |
| 취소 · 트리거 다시 누르기 · 바깥 누르기 · `Escape`(Web) | 부르지 않고 마지막으로 확정한 색으로 되돌립니다. | 넣지 않습니다. |
| 트리거 옆 hex 입력 | 6자리가 되는 즉시 부릅니다. | Flutter 는 넣고, Web 은 넣지 않습니다. |
| 인라인 패널에서 색을 바꾸는 모든 조작 | 바로 부릅니다. | 넣지 않습니다. |

```text
팝오버: 트리거 누름 → 패널에서 고치기 (트리거가 미리 보임) → 저장 → onChanged → 최근 색에 추가
인라인: 패널에서 고치기 → onChanged
```

`onChanged` 가 넘기는 색은 불투명하고, Web 은 대문자 `#RRGGBB` 입니다. 반투명한 색이 든 최근 색 칸을 고른 경우는 예외입니다([알려진 제약](/components/color-picker#알려진-제약)). picker 는 확정한 색을 스스로 기억하므로, 팝오버에서 저장한 색은 `color` 를 다시 넘기지 않아도 트리거에 남습니다.

<a id="인터랙션"></a>

### 패널 조작

- **모드 탭** — 묶음 토글 [ToggleGroup](/components/toggle-group) 입니다(`size: sm`, 칸 26 · 트랙 32). 모드를 바꾸면 색은 그대로이고 채널 입력만 바뀝니다. 모양은 `modeTabsStyle` 로 바꿉니다.
- **채도 · 명도 영역** — 240 × 240, 모서리 8, 테두리 없음. 누르거나 끌면 채도와 명도를 함께 정합니다. 고른 지점에 지름 18 의 핸들이 놓입니다. 핸들은 고른 색으로 채우고 흰 테두리 3 과 가장 옅은 그림자를 두릅니다. 흰 테두리는 다크에서도 흰색입니다. 마우스를 올리면 십자 커서가 보입니다.
- **색조 막대** — 높이 8, 모서리 4, 테두리 없음. 위에 지름 18 의 핸들(고른 색 채움, 흰 테두리 3)이 얹히고, 누르는 영역의 높이는 18 입니다. 마우스를 올리면 좌우 조절 커서가 보입니다.
- **알파 막대** — `showAlpha` 를 켜면 보이는 같은 모양의 막대입니다. 입력을 받지 않습니다.
- **HEX · 채널 줄** — 맨 앞의 HEX 칸은 채널 칸의 2배 폭입니다. 채널은 모드에 따라 R · G · B(0–255), H(0–360) · S · L(0–100), H · S · V 입니다. 범위를 넘는 수는 범위 안으로 맞추고, 숫자가 아닌 글자는 무시합니다. 입력은 `sm` [TextField](/components/text-field) 이고, 칸 위의 이름표(`onSurfaceSubtle`)는 입력과 2 떨어집니다.
- **최근 색 줄** — "최근 사용" 제목 아래(간격 8)에 최근에 저장한 색이 한 줄로 놓입니다. 누르면 패널의 색이 그 색이 됩니다.
- **액션 줄** — 왼쪽에 스포이드(`ghost`), 오른쪽에 취소(`ghost`)와 저장(`primary`)이 놓입니다. 모두 `sm` 버튼입니다. 인라인은 취소 · 저장 대신 24 크기의 칸 둘로 된 비교 칸을 둡니다.

<a id="eyedropper"></a>

### 스포이드

`enableEyeDropper`(기본 `true`)이고 브라우저가 `window.EyeDropper` 를 지원하면 액션 줄에 스포이드 버튼이 보입니다. 지원은 Chromium 95 이상에 있고, Firefox 와 Safari 에는 없습니다. Flutter 는 웹으로 빌드했을 때만 지원하고, 네이티브 앱에는 보이지 않습니다. Web 은 서버 렌더와 첫 화면에서는 버튼을 그렸다가, 지원하지 않는 브라우저면 숨깁니다. 뽑은 색은 팝오버에서는 저장 전의 색이 되고, 인라인에서는 바로 확정됩니다.

<a id="최근-색-recent-colors"></a>

## 최근 색

`ColorPicker` 는 `RecentColorsScope` 로 최근 색 기록을 나눕니다. 같은 범위의 picker 들은 같은 기록을 보므로, 한 picker 에서 저장한 색은 다른 picker 의 최근 색 줄에도 바로 나타납니다(Flutter 팝오버는 아래 안내를 보세요). `CoUIApp` · `CoUIWeb` 이 앱 전체의 범위를 하나 세우므로 따로 감싸지 않아도 최근 색이 쌓입니다. 앱 전체의 시작 값 · 개수 · 저장 알림은 `CoUIApp` · `CoUIWeb` 의 `initialRecentColors` · `maxRecentColors` · `onRecentColorsChanged` 로 정합니다. 범위 밖에서는 최근 색 줄이 없고 확정 알림만 동작합니다.

<Preview demo="color-picker/recent" height="hug" />

화면마다 기록을 나누려면 그 화면을 범위로 감쌉니다. picker 는 가장 가까운 범위를 씁니다. Flutter 의 팝오버 패널만 다릅니다(아래 안내).

```dart
RecentColorsScope(
  initialRecentColors: [
    CoreColor.fromHex('#3B82F6'),
    CoreColor.fromHex('#E11D48'),
  ],
  maxRecentColors: 10,
  onRecentColorsChanged: (colors) => persist(colors),
  child: ColorPaletteEditor(),
)
```

- `initialRecentColors` 는 범위를 처음 만들 때 한 번만 읽습니다. 최근 색이 앞에 옵니다.
- 색을 새로 더할 때(저장 · `addHistory`) `maxRecentColors`(기본 10)를 넘으면 오래된 색부터 버립니다. `initialRecentColors` · `setHistory` 로 넣은 긴 목록은 다음에 색을 더할 때까지 자르지 않습니다. 이미 있는 색을 다시 넣으면 맨 앞으로 옮깁니다.
- `onRecentColorsChanged` 는 기록이 바뀔 때마다 불립니다. 앱이 저장해 두는 자리입니다.
- 코드에서 기록을 바꾸려면 `RecentColorsScope.maybeOf(context)` 로 받은 객체의 `addHistory` · `setHistory` · `clear` 를 씁니다.

<Note>

Flutter 에서 팝오버 패널은 앱의 맨 위 층에 그려져, 최근 색 줄이 화면에 따로 세운 범위가 아니라 `CoUIApp` 의 범위를 읽습니다. 저장한 색은 트리거 쪽의 가장 가까운 범위에 들어갑니다. 화면별 기록을 보이려면 인라인 모드를 쓰세요. Web 은 팝오버에서도 가장 가까운 범위를 씁니다.

</Note>

<a id="그리드-토큰"></a>

### 그리드 값

최근 색 칸은 20 크기, 모서리 6, 사이 4 이고 한 줄에 10개까지 보입니다. `recentSwatchSize` · `recentSwatchSpacing` · `recentColumns` 로 바꿉니다. 줄은 하나라 `recentColumns` 를 넘는 색은 보이지 않습니다. 지금 색과 같은 칸은 Flutter 에서는 `primary` 테두리 2, Web 에서는 `outlineVariant` 테두리 2 와 `primary` 링으로 표시합니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

브랜드 색 · 테마 색처럼 정해진 목록에 없는 색을 사용자가 직접 정하거나, HEX · RGB · HSL · HSV 값으로 색을 받아야 할 때 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 색을 편집하지 않고 이름 붙은 테마를 고를 때 | [ThemeController](/components/theme-controller) |
| 정해진 색 목록에서 하나만 고를 때 | [Select](/components/select) |
| 색 코드 문자열만 받으면 될 때(검증은 앱이 맡습니다) | [TextField](/components/text-field) |
| 색이 아니라 숫자 하나를 조절할 때 | [Slider](/components/slider) |

<a id="do"></a>
<a id="dont"></a>

### 라벨과 미리보기

<Cards columns="2">
<Card demo="color-picker/do-label" tone="do" eyebrow="이렇게 하세요">

`FormField(label:)` 로 감싸 무엇의 색인지 보여 줍니다. `ColorPicker` 는 라벨을 그리지 않습니다.

</Card>
<Card demo="color-picker/dont-no-label" tone="dont" eyebrow="이렇게 하지 마세요">

라벨 없이 두지 않습니다. 트리거에는 색과 hex 만 보여 무슨 색을 정하는지 알 수 없습니다.

</Card>
<Card tone="do" eyebrow="이렇게 하세요">

함께 써야 하는 picker 는 같은 최근 색 범위 아래에 둡니다. 앱 전체 기록의 시작 값은 `CoUIApp` · `CoUIWeb` 의 `initialRecentColors` 로 줍니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

팝오버의 `onChanged` 가 드래그할 때마다 불릴 것이라고 기대하지 않습니다. 저장하기 전에는 불리지 않습니다. 고르는 동안 화면을 바로 바꾸려면 인라인 모드를 씁니다. 반대로 트리거 옆 hex 입력은 저장 없이 바로 부르므로, 모든 호출을 저장으로 여기지 않습니다.

</Card>
</Cards>

<a id="스타일-시스템-style-system"></a>
<a id="시맨틱-vs-스타일"></a>

## 테마와 스타일

### 파라미터와 스타일

- **값 · 동작 · 표시 방식**은 위젯 속성으로 정합니다 — `color`, `onChanged`, `enabled`, `promptMode`, `pickerMode`, `showHexInput`, `showLabel`, `showAlpha`, `enableEyeDropper`.
- **내용**은 위젯을 넣습니다 — `dialogTitle`, `placeholder`.
- **보이는 값**(색 · 크기 · 간격)은 `colorPickerStyle`(`CoreColorPickerStyle`) 하나로 바꿉니다. 안에 그리는 부품은 그 부품의 Style 을 그대로 넘깁니다 — 팝오버는 `popoverStyle`(`CorePopoverStyle`), 인라인 패널 상자는 `inlinePanelStyle`(`CorePopupStyle`), 트리거 옆 hex 입력은 `hexInputStyle`(`CoreTextFieldStyle`), 모드 탭은 `modeTabsStyle`(`CoreToggleGroupStyle`), 최근 색 칸의 누르기 모양은 `recentSwatchClickableStyle`(`CoreClickableStyle`)입니다.
- **라벨 · 설명 · 오류 문구**는 `ColorPicker` 가 그리지 않습니다. `FormField(label:, description:, error:)` 로 감싸고 그 `formFieldStyle` 로 꾸밉니다. `CoreColorPickerStyle` 의 `labelStyle` · `descriptionStyle` · `errorStyle` 은 효과가 없고 폐기 예고됐습니다.

<a id="migration-옛-평면-필드-새-위치-매핑"></a>
<a id="migration-옛-필드-새-위치-매핑"></a>

팝오버와 트리거 사이 간격은 `popoverStyle.placementOffset`, 패널 안쪽 여백은 `popoverStyle.panelStyle.padding` 으로 바꿉니다. 팝오버를 트리거의 어느 쪽에 맞출지 정하는 속성은 없습니다. 옛 `popoverAlignment` · `popoverAnchorAlignment` 에는 대응하는 값이 없고, 옛 `popoverPadding` 은 `popoverStyle.panelStyle.padding` 입니다.

<a id="사용-예-flutter"></a>
<a id="사용-예-web"></a>
<a id="theme-오버라이드"></a>

<Split>

<Code language="dart" title="ColorPicker 하나만 바꾸기">
ColorPicker(
  color: color, // Web 은 '#3B82F6' 같은 문자열
  showHexInput: true,
  onChanged: handleColorChanged,
  colorPickerStyle: CoreColorPickerStyle(
    swatchBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    popoverStyle: CorePopoverStyle(
      panelStyle: CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
        padding: CoreEdgeInsets.all(CoreSpace.space16),
      ),
      placementOffset: CoreSpace.space8,
    ),
    hexInputStyle: CoreTextFieldStyle(
      borderColor: CoreColor.token(CoreColors.primary),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    colorPicker: CoreColorPickerTheme(
      style: CoreColorPickerStyle(
        popoverStyle: CorePopoverStyle(
          panelStyle: CorePopupStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
          ),
        ),
      ),
    ),
  ),
)
</Code>

</Split>

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreColorPickerStyle 의 기본값 (default*)
  → CoreComponentTheme.colorPicker.style    // 앱 전체
  → colorPickerStyle                        // 인스턴스
```

뒤로 갈수록 우선합니다. 안의 부품은 각자 자기 기본값과 테마를 먼저 받고, 그 위에 `ColorPicker` 가 넘기는 값과 `colorPickerStyle` 의 부품 스타일이 얹힙니다. `ColorPicker` 는 팝오버 패널의 모서리 14 를 넘기므로, `CorePopoverTheme` 으로 패널 모서리를 바꿔도 이 패널은 14 그대로입니다. 이 패널은 `popoverStyle.panelStyle` 로 바꿉니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `ColorPicker` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 씁니다. 생성자의 `colorPickerStyle` 인자와 같게 동작합니다.

<Preview component="color-picker" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ColorPickerChainExample extends StatefulWidget {
  const ColorPickerChainExample({super.key});

  @override
  State<ColorPickerChainExample> createState() => _ColorPickerChainExampleState();
}

class _ColorPickerChainExampleState extends State<ColorPickerChainExample> {
  Color _color = const Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return ColorPicker(
      color: _color,
      showHexInput: true,
      onChanged: (value) {
        setState(() => _color = value);
      },
    ).withStyle(
      const CoreColorPickerStyle(
        swatchSize: CoreSpace.space48,
        hexInputWidth: CoreSpace.space112,
        swatchGapStyle: CoreGapStyle(size: CoreSpace.space12),
        swatchBorderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        borderColor: CoreColor.token(CoreColors.primary),
        borderWidth: CoreStrokeWidth.stroke2,
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class ColorPickerChainExample extends StatefulComponent {
  const ColorPickerChainExample({super.key});

  @override
  State<ColorPickerChainExample> createState() => _ColorPickerChainExampleState();
}

class _ColorPickerChainExampleState extends State<ColorPickerChainExample> {
  String _color = '#3B82F6';

  @override
  Component build(BuildContext context) {
    return ColorPicker(
      color: _color,
      showHexInput: true,
      onChanged: (value) {
        setState(() => _color = value);
      },
    ).withStyle(
      const CoreColorPickerStyle(
        swatchSize: CoreSpace.space48,
        hexInputWidth: CoreSpace.space112,
        swatchGapStyle: CoreGapStyle(size: CoreSpace.space12),
        swatchBorderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        borderColor: CoreColor.token(CoreColors.primary),
        borderWidth: CoreStrokeWidth.stroke2,
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

트리거의 hex 는 화면에 보이는 글자라 두 플랫폼 모두 읽힙니다. 키보드로 쓸 수 있는 범위는 플랫폼마다 크게 다릅니다 — Flutter 에서는 팝오버를 키보드로 열 수 없습니다.

### 역할

| 요소 | Flutter | Jaspr Web |
| --- | --- | --- |
| 루트 | 역할 없음 | 팝오버 모드는 `role="group"`(비활성이면 역할 없음). 인라인은 `role="group"` 이고 비활성이면 `aria-disabled` |
| 트리거 | 열림 여부(`expanded`)만 알립니다. 누르기 동작은 알리지 않습니다. | 트리거 줄에 `role="group"`(비활성이면 `aria-disabled`). 줄을 감싼 팝오버 틀에 `aria-haspopup="dialog"` · `aria-expanded`, 열려 있는 동안 `aria-controls` |
| 스와치 | 역할 없음, 포커스를 받지 않음 | `<button type="button">` |
| 팝오버 패널 | 역할 없는 묶음 | `role="dialog"` |
| 인라인 패널 상자 | 역할 없는 묶음 | `role="menu"` |
| 모드 탭 | 하나만 고르는 선택 항목 | `role="radiogroup"` 안의 `role="radio"` · `aria-checked` |
| 채도 · 명도 영역 | 없음 | 역할 없는 `<div>` |
| 색조 · 알파 막대 | 없음 | `role="slider"`(값 속성 없음) |
| HEX · 채널 입력 | 텍스트 필드 | `<input>` |
| 최근 색 | 버튼 | `role="button"` |
| 스포이드 · 취소 · 저장 | 버튼 | `<button>` |

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` | 팝오버 모드의 스와치는 정지점이 아닙니다. `showHexInput` · `showLabel` 을 켜면 hex 입력이 정지점입니다. 인라인 패널은 모드 탭 · 입력 · 최근 색 · 버튼이 정지점입니다. | 스와치 → (트리거 옆 hex 입력). 열린 팝오버 패널은 페이지 내용 뒤의 층에 있어, 트리거 뒤의 페이지 요소를 모두 지난 다음에 닿습니다. 패널 안은 모드 탭(정지점 하나) → HEX → 채널 → 최근 색 → 스포이드 → 취소 → 저장 순서입니다. |
| `Enter` · `Space` | 팝오버를 열 수 없습니다. 패널 안의 모드 탭 · 버튼은 누릅니다. | 스와치에서 팝오버를 여닫습니다. |
| `Escape` | 팝오버가 닫히지 않습니다. | 팝오버를 닫습니다. |
| 모드 탭의 방향키 · `Home` · `End` | 전용 이동이 없습니다. 칸마다 `Tab` 정지점입니다. | 좌우 · 상하 방향키(끝에서 순환)와 `Home` · `End` 가 모드를 바로 바꿉니다. |
| 문자 · 숫자 | HEX · 채널 칸과 트리거 옆 hex 입력으로 값을 정합니다. | 같습니다. |
| 채도 · 명도 · 색조의 방향키 | 동작하지 않습니다. | 동작하지 않고, 포커스도 받지 못합니다. |

### 스크린 리더

- **트리거 이름** — Web 은 스와치 버튼에 "색상 선택" 이름이 붙습니다. Flutter 스와치에는 이름이 없고, 트리거는 열림 여부만 알립니다. 고른 hex 는 두 플랫폼 모두 글자로 읽힙니다.
- **패널 이름** — Web 의 팝오버 `role="dialog"` 에는 이름이 없습니다. 그 안의 내용 상자에 "색상 선택기" `aria-label` 이 있지만 역할이 없는 `<div>` 입니다. Flutter 에는 이름이 없습니다.
- **모드 탭** — 두 플랫폼 모두 고른 상태를 알립니다. Web 의 `radiogroup` 에는 이름이 없습니다.
- **영역과 막대** — Web 은 채도 · 명도 영역에 "채도 및 명도", 막대에 "색조" · "알파" 이름을 붙이지만 값은 알리지 않습니다. Flutter 는 이름도 값도 없습니다.
- **입력** — 두 플랫폼 모두 HEX · 채널 칸에 이름이 없습니다. 칸 위의 이름표는 입력과 연결되지 않은 글자입니다.
- **최근 색** — Web 은 칸마다 "최근 색상 #RRGGBB" 이름을 붙입니다. Flutter 칸에는 이름이 없습니다. 지금 색과 같은 칸이라는 것은 어느 쪽도 알리지 않습니다.
- **스포이드** — 두 플랫폼 모두 "화면에서 색상 추출" 이름을 붙입니다.
- 색이 바뀐 것을 알리는 라이브 리전은 없습니다.

이름 문구는 한국어 로케일의 값입니다.

### 포커스 관리

- 팝오버를 열어도 포커스를 패널로 옮기지 않습니다.
- 닫아도 포커스를 트리거로 되돌리지 않습니다.
- 포커스를 가두지 않습니다. 팝오버는 배경을 막지 않으며, 모달 대화상자로 바꾸는 방법은 없습니다(`promptMode: dialog` 도 팝오버입니다).

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | 키보드로 팝오버를 열 수 없습니다. 트리거가 누르기 동작을 알리지 않아 보조 기술로도 열기 어렵습니다. 키보드 사용자에게는 인라인 모드나 `showHexInput` 을 씁니다. |
| 공통 | 채도 · 명도 영역과 색조 막대는 키보드로 조작할 수 없습니다. HEX · 채널 칸이 대신합니다. |
| Jaspr Web | 채도 · 명도 영역과 색조 막대는 마우스 이벤트만 받아 터치 드래그가 동작하지 않고, 끄는 동안 영역 밖으로 나가면 따라오지 않습니다. |
| Jaspr Web | 색조를 지금 색의 hex 에서 다시 계산합니다. 흰색 · 회색 · 검정을 고르면 영역의 바탕이 빨강 기준으로 바뀌고, 그 상태에서는 색조 막대를 움직여도 색이 바뀌지 않습니다. |
| 공통 | 알파 막대는 표시만 합니다. 결과에는 알파가 없습니다. Flutter 는 반투명 색을 넘겨도 불투명하게 돌려주고, Web 은 8자리 hex 를 색 없음으로 읽습니다. |
| 공통 | 패널의 HEX · 채널 칸과 트리거 옆 hex 입력은 값이 바뀌면 새로 만들어져 포커스가 빠집니다. 그래서 채널 칸에는 여러 자리 값을 이어서 치기 어렵습니다. 값을 붙여넣거나 HEX 칸에 6자리를 입력하세요. |
| 공통 | 트리거 옆 hex 입력을 누르면 팝오버도 함께 열리고 닫힙니다. |
| 공통 | 팝오버가 열린 채 트리거 옆 hex 입력에 새 색을 넣으면 `onChanged` 는 새 색으로 불리지만, Flutter 의 패널은 옛 색에 머뭅니다. Web 은 그 색을 `color` 로 다시 넘기지 않을 때 그렇습니다. 이 상태에서 저장을 누르면 옛 색으로 `onChanged` 가 다시 불립니다. 입력한 뒤에는 저장 대신 취소하거나 바깥을 눌러 닫으세요. |
| 공통 | 최근 색에는 불투명한 색만 넣습니다. `initialRecentColors` · `setHistory` · `addHistory` 로 반투명한 색을 넣고 그 칸을 고르면, Web 은 8자리 hex 를 그대로 넘기고 Flutter 는 검정이 됩니다. |
| Flutter | 팝오버 모드에서 `color` 를 코드에서 바꾸면, 팝오버를 열 때 트리거가 마지막으로 저장한 옛 색으로 돌아가고 취소해도 옛 색이 남습니다. `key: ValueKey(color)` 를 주면 새 색으로 다시 만듭니다. |
| Flutter | 인라인 패널은 처음 만든 뒤에 바꾼 `pickerMode` 를 따르지 않습니다. |
| Flutter | 팝오버의 최근 색 줄은 화면에 따로 세운 `RecentColorsScope` 를 읽지 못합니다([최근 색](/components/color-picker#최근-색-recent-colors)). |
| Flutter | 최근 색 기록에 토큰 색(`CoreColor.token`)이 있으면 최근 색 줄을 그릴 때 오류가 납니다. `CoreColor.fromHex` 처럼 값이 정해진 색을 넣습니다. |
| Flutter | 기본 폭(240)에서는 채널 칸이 좁아 `103` · `164` 같은 3자리 값이 끝에서 잘려 보입니다(문서 사이트의 Flutter 미리보기에서 확인). `popoverWidth` 로 패널을 넓힙니다. |
| Jaspr Web | `maxRecentColors` 가 `recentColumns` 보다 크면 보이지 않는 최근 색 칸에도 `Tab` 과 스크린 리더가 닿습니다. |
| Jaspr Web | 인라인 패널 상자가 `role="menu"` 로 알려집니다. |
| 공통 | `Form` · `FormField` 에 값을 보고하지 않습니다. |
| 공통 | `FormField(enabled: false)` 는 마우스 · 터치 입력을 막고 안쪽의 글자 입력(트리거 옆 hex 입력, 인라인의 HEX · 채널 칸)을 비활성으로 만들지만, picker 의 `enabled` 는 그대로입니다. 스와치는 비활성 모양이 되지 않습니다. Web 에서는 키보드로 스와치를 눌러 팝오버를 열고 색을 저장할 수 있고, 인라인의 최근 색 · 스포이드는 두 플랫폼 모두 키보드로 누를 수 있습니다. 막으려면 `enabled: false` 를 직접 줍니다. |
| 공통 | 팝오버 모드의 비활성 모습은 스와치(와 트리거 옆 hex 입력)에만 나타납니다. 인라인은 모드 탭 · 입력 · 최근 색 · 스포이드 버튼도 비활성 모양이 되지만, 채도 · 명도 영역과 막대, 비교 칸은 그대로입니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `color` · `onChanged` 의 타입 | `Color` | `String`(`#RRGGBB`, `onChanged` 는 대문자) |
| 색 없음 | 알파 0 인 `Color` | `#` 뒤에 16진수 6자리가 오지 않는 문자열 |
| `dialogTitle` · `placeholder` | `Widget` | `Component` |
| 색조 | 따로 기억해 흰색 · 검정을 골라도 영역의 색조가 남습니다 | hex 에서 다시 계산합니다 |
| 팝오버 닫기 | 바깥 누르기 | 바깥 누르기 · `Escape` |
| 키보드로 열기 | 할 수 없습니다 | 스와치에서 `Enter` · `Space` |
| 팝오버를 다시 열 때의 모드 탭 | `pickerMode` 로 돌아갑니다 | 마지막에 고른 모드가 남습니다 |
| 인라인에서 `pickerMode` 를 바꾸면 | 따르지 않습니다 | 따릅니다 |
| 채도 · 명도 · 색조의 터치 드래그 | 동작합니다 | 동작하지 않습니다 |
| 채널 칸의 화면 키보드 | 숫자 키보드 | 기본 키보드 |
| 팝오버의 최근 색 범위 | 앱의 맨 위 층에서 보이는 범위 | 가장 가까운 범위 |
| 트리거 옆 hex 입력의 최근 색 | 넣습니다 | 넣지 않습니다 |
| 기록이 빈 최근 색 | 범위가 있으면 입력 줄과 액션 줄 사이가 32 로 벌어집니다 | 간격 16 그대로 |
| 넘치는 최근 색 | `recentColumns` 개까지만 그립니다 | 모두 그리고 넘치는 줄은 숨깁니다 |
| 선택한 최근 색 표시 | `primary` 테두리 2 | `outlineVariant` 테두리 2 와 `primary` 링(마우스를 올리면 칸에 옅은 링) |
| 알파 막대 | 투명에서 지금 색으로 | 체크 무늬 위에 같은 그라디언트 |
| HTML 속성 · DOM 이벤트 | 없음 | 루트에 `id` · `classes` · `css` · `attributes` · 이벤트 |

<a id="props-parameters"></a>

## API

Flutter 와 Jaspr Web 이 같은 속성을 씁니다. 색의 타입만 다릅니다 — 아래 표의 `Color` 는 Web 에서 `String`(hex)입니다.

### 값과 콜백

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `color` | `Color` | 필수 | 지금 색. 색 없음은 [색 없음](/components/color-picker#색-없음-empty-swatch) 참고 |
| `onChanged` | `void Function(Color)?` | `null` | 확정한 색을 받습니다. [값이 확정되는 때](/components/color-picker#색-commit-흐름) |

### 상태와 형태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `enabled` | `bool?` | `null` → `true` | `false` 면 비활성. `onChanged` 유무와 상관없습니다. |
| `promptMode` | `CoreColorPickerPromptMode?` | `null` → `popover` | `popover` · `inline` · `dialog`(`popover` 와 같게 그림) |
| `pickerMode` | `CoreColorPickerMode?` | `null` → `rgb` | 처음 보이는 채널 입력(`rgb` · `hsl` · `hsv`) |
| `showHexInput` | `bool?` | `null` → `false` | 트리거 옆 hex 입력(팝오버 모드) |
| `showLabel` | `bool?` | `null` → `false` | `showHexInput` 과 같은 입력을 켭니다. 라벨 글자는 그리지 않습니다. |
| `showAlpha` | `bool?` | `null` → `false` | 알파 막대(표시만) |
| `enableEyeDropper` | `bool?` | `null` → `true` | 지원하는 브라우저에서 스포이드 버튼 |

### 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `dialogTitle` | `Widget?` (Web `Component?`) | `null` | 패널 맨 위에 놓을 위젯 |
| `placeholder` | `Widget?` (Web `Component?`) | `null` | 색이 없을 때 트리거 글자 자리에 놓을 위젯. `null` 이면 로케일의 자리표시 문구 |

### 그 밖

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `controller` | `Object?` | `null` | 받지만 아무 효과가 없습니다. 팝오버를 코드로 여닫는 방법은 없습니다. |
| `colorPickerStyle` | `CoreColorPickerStyle?` | `null` | 보이는 값 덮어쓰기 |

`copyWith` 로 속성을 바꾼 사본을, `withStyle(patch)` 로 `colorPickerStyle` 에 값을 덧붙인 사본을 만듭니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreColorPickerStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `swatchSize` | `double?` | Trigger swatch button width/height override (logical px). |
| `hexInputWidth` | `double?` | Hex input field width override (logical px). |
| `swatchGapStyle` | `CoreGapStyle?` | Horizontal gap between the swatch and the hex input, passed to `Gap(gapStyle: …)`. |
| `popoverWidth` | `double?` | Popover panel width override (logical px). |
| `popoverSpacing` | `double?` | Vertical spacing between popover sections override (logical px, pre-scaling). Raw primitive — flows directly into `Column.spacing` (Flutter) and the `flex flex-col` parent's CSS `gap` (Web), not a `Gap` slot. Falls back to [defaultPopoverSpacing] when null. |
| `sliderHeight` | `double?` | Hue / alpha slider track height override (logical px). |
| `modeInputSpacing` | `double?` | Horizontal spacing between RGB / HSL / HSV mode input cells override (logical px, pre-scaling). Raw primitive — flows directly into `Row.spacing` (Flutter) and the `flex` parent's CSS `gap` (Web), not a `Gap` slot. Falls back to [defaultModeInputSpacing] when null. |
| `modeInputLabelGapStyle` | `CoreGapStyle?` | Vertical gap between a mode input cell's label and its number field, passed to `Gap(gapStyle: …)`. |
| `actionRowGapStyle` | `CoreGapStyle?` | Horizontal gap between the Cancel and Save buttons in the action row, passed to `Gap(gapStyle: …)`. |
| `eyeDropperIconStyle` | `CoreIconStyle?` | Style of the eye-dropper button's icon, passed to `Icon(iconStyle: …)`. Falls back to [defaultEyeDropperIconStyle] when null. |
| `recentSwatchSize` | `double?` | Recent-color swatch side length override (logical px). |
| `recentSwatchSpacing` | `double?` | Spacing (logical px) between recent-color swatches override — raw primitive, drives `Wrap.spacing/runSpacing` (Flutter) and CSS `gap` (Web), not a `Gap` slot. |
| `recentColumns` | `int?` | Recent-colors grid column count override. |
| `swatchBorderRadius` | `CoreBorderRadius?` | Corner radius override for the trigger swatch button. |
| `sliderBorderRadius` | `CoreBorderRadius?` | Corner radius override for the hue / alpha slider bars. Falls back to [defaultSliderBorderRadius] when null. |
| `recentSwatchBorderRadius` | `CoreBorderRadius?` | Corner radius override for a recent-color swatch. Falls back to [defaultRecentSwatchBorderRadius] when null. |
| `saturationValueBorderRadius` | `CoreBorderRadius?` | Corner radius override for the 2D saturation/value area inside the popover. |
| `pickMarkerSize` | `double?` | Side override (logical px) of the round picked-point handle on the saturation/value area and the hue bar. Falls back to [defaultPickMarkerSize] when null. |
| `pickMarkerBorderColor` | `CoreColor?` | Handle ring colour override. Falls back to [defaultPickMarkerBorderColor] when null. |
| `pickMarkerBorderWidth` | `double?` | Handle ring width override (logical px). Falls back to [defaultPickMarkerBorderWidth] when null. |
| `pickMarkerShadow` | `List<CoreShadowLayer>?` | Shadow layers under both picked-point handles. Falls back to [defaultPickMarkerShadow] when null. |
| `hueMarkerFillColor` | `CoreColor?` | **Deprecated (since 0.190)** — The hue-bar handle is filled with the current colour, like the saturation handle — nothing reads this fill any more. Former hue-bar handle fill. The handle is filled with the current colour now, so nothing reads it. |
| `hueMarkerBorderColor` | `CoreColor?` | Hue-bar handle border colour override. Falls back to [defaultHueMarkerBorderColor] when null. |
| `hueMarkerBorderWidth` | `double?` | Hue-bar handle border width override (logical px). Falls back to [defaultHueMarkerBorderWidth] when null. |
| `emptySwatchDashLength` | `double?` | Dash length override (logical px) of the empty swatch's dashed outline. Falls back to [defaultEmptySwatchDashLength] when null. |
| `emptySwatchDashSpacing` | `double?` | Dash gap override (logical px) of the empty swatch's dashed outline. Falls back to [defaultEmptySwatchDashSpacing] when null. |
| `borderColor` | `CoreColor?` | Border colour override for the trigger swatch and the recent-colour swatches. Falls back to [defaultBorderColor] when null. |
| `borderWidth` | `double?` | Border stroke width override (logical px) for the trigger swatch and the recent-colour swatches. Falls back to [defaultBorderWidth] when null. |
| `disabledBorderColor` | `CoreColor?` | Border colour override for the trigger swatch when disabled. Falls back to [defaultDisabledBorderColor] (`disabledOutline` token) when null. |
| `selectedRingColor` | `CoreColor?` | Ring colour override for the currently-selected recent-color swatch. Falls back to [defaultSelectedRingColor] (`primary` token) when null. |
| `recentSwatchBorderWidth` | `double?` | Border stroke width override (logical px) for an unselected recent-color swatch. Falls back to [defaultRecentSwatchBorderWidth] when null. |
| `recentSwatchSelectedBorderWidth` | `double?` | Border stroke width override (logical px) for the currently-selected recent-color swatch. Falls back to [defaultRecentSwatchSelectedBorderWidth] when null. |
| `transitionDuration` | `Duration?` | Transition duration override for the swatch hover / focus colour transitions and the recent-swatch ring transition. Falls back to [defaultTransitionDuration] when null. |
| `popoverStyle` | `CorePopoverStyle?` | Popover style for the popover-mode picker — the look of its trigger and dropdown. |
| `dialogStyle` | `CoreDialogStyle?` | Dialog style for the modal-mode picker. |
| `swatchButtonStyle` | `CoreButtonStyle?` | Style applied to each preset / history color swatch button. |
| `recentSwatchClickableStyle` | `CoreClickableStyle?` | Style for each recent-color swatch's `Clickable` — press, focus ring and cursor overrides for the swatch. Laid over [defaultRecentSwatchClickableStyle] and passed to `Clickable(clickableStyle:)` as is. |
| `hexInputStyle` | `CoreTextFieldStyle?` | Style applied to the hex input field (`showHexInput: true`). |
| `modeTabsStyle` | `CoreToggleGroupStyle?` | Style for the mode tabs, passed to their `ToggleGroup(toggleGroupStyle: …)` as is. |
| `modeInputLabelStyle` | `CoreTextStyle?` | Channel caption (`R` / `G` / `B`) text style override. Falls back to [defaultModeInputLabelStyle] when null. |
| `triggerBackgroundColor` | `CoreColor?` | Fill of the field-shaped trigger. Falls back to [defaultTriggerBackgroundColor] when null. |
| `triggerBorderColor` | `CoreColor?` | Border colour of the field-shaped trigger. Falls back to [defaultTriggerBorderColor] when null. |
| `triggerBorderWidth` | `double?` | Border width (logical px) of the field-shaped trigger. Falls back to [defaultTriggerBorderWidth] when null. |
| `triggerBorderRadius` | `CoreBorderRadius?` | Corner radius of the field-shaped trigger. Falls back to [defaultTriggerBorderRadius] when null. |
| `triggerPadding` | `CoreEdgeInsets?` | Inner padding of the field-shaped trigger. Falls back to [defaultTriggerPadding] when null. |
| `triggerSpacing` | `double?` | Spacing (logical px) between the trigger's swatch, text and chevron. Falls back to [defaultTriggerSpacing] when null. |
| `triggerMinWidth` | `double?` | Minimum width (logical px) of the field-shaped trigger. Falls back to [defaultTriggerMinWidth] when null. |
| `triggerValueTextStyle` | `CoreTextStyle?` | Text style of the trigger's hex value, shown when a colour is picked. Falls back to [defaultTriggerValueTextStyle] when null. |
| `triggerPlaceholderTextStyle` | `CoreTextStyle?` | Text style of the trigger's placeholder, shown when no colour is picked. Falls back to [defaultTriggerPlaceholderTextStyle] when null. |
| `triggerChevronIconStyle` | `CoreIconStyle?` | Style of the chevron at the end of the trigger. Falls back to [defaultTriggerChevronIconStyle] when null. |
| `recentTitleTextStyle` | `CoreTextStyle?` | Text style of the title above the recent colours. Falls back to [defaultRecentTitleTextStyle] when null. |
| `recentTitleGapStyle` | `CoreGapStyle?` | Gap between the recent-colours title and the swatches, passed to `Gap(gapStyle: …)`. Falls back to [defaultRecentTitleGapStyle] when null. |
| `modeHexInputFlex` | `int?` | How much wider the HEX input cell grows than each channel cell — a flex weight against the channel cells' `1`. Falls back to [defaultModeHexInputFlex] when null. |
| `compareSwatchSize` | `double?` | Side (logical px) of each half of the inline panel's previous / current comparison cell. Falls back to [defaultCompareSwatchSize] when null. |
| `compareBorderRadius` | `CoreBorderRadius?` | Corner radius of the inline panel's comparison cell. Falls back to [defaultCompareBorderRadius] when null. |
| `compareBorderColor` | `CoreColor?` | Border colour of the inline panel's comparison cell. Falls back to [defaultCompareBorderColor] when null. |
| `compareBorderWidth` | `double?` | Border width (logical px) of the inline panel's comparison cell. Falls back to [defaultCompareBorderWidth] when null. |
| `inlinePanelStyle` | `CorePopupStyle?` | Style of the panel box the inline presentation draws in place, passed to `Popup(popupStyle: …)`. Falls back to [defaultInlinePanelStyle] when null. |
| `labelStyle` | `CoreTextStyle?` | **Deprecated (since 0.183)** — Wrap the picker in FormField(label: …) and style the label with its formFieldStyle.formLabelStyle instead — ColorPicker draws no label, so this slot never had an effect. Label text style. |
| `descriptionStyle` | `CoreTextStyle?` | **Deprecated (since 0.183)** — Wrap the picker in FormField(description: …) and style the text with its formFieldStyle.descriptionTextStyle instead — ColorPicker draws no description, so this slot never had an effect. Description / helper text style. |
| `errorStyle` | `CoreTextStyle?` | **Deprecated (since 0.183)** — Wrap the picker in FormField(error: …) and style the message with its formFieldStyle.validatorHintStyle instead — ColorPicker draws no error text, so this slot never had an effect. Error text style. |

<!-- STYLE_TABLE:END -->

<Note>

표의 설명 중 일부는 지금 동작과 다릅니다.

- `popoverWidth` 는 패널의 내용 폭(기본 240)입니다. 팝오버 패널은 안쪽 여백 16 을 더해 272 폭이고(테두리 1 은 그 여백 안에 그립니다), 인라인 패널에도 닿습니다.
- `swatchButtonStyle` 은 최근 색 칸이 아니라 트리거 스와치에 닿고, 그중 너비와 `borderRadius` 만 읽습니다. 적으면 `swatchSize` · `swatchBorderRadius` 보다 우선합니다.
- `borderWidth` 는 트리거 스와치(색 없음의 점선 포함)에만 닿습니다. 최근 색 칸의 테두리 폭은 `recentSwatchBorderWidth` · `recentSwatchSelectedBorderWidth` 로 바꿉니다. `borderColor` 는 트리거 스와치와 최근 색 칸 모두에 닿습니다(Flutter 의 고른 칸만 `selectedRingColor` 를 씁니다).
- `pickMarkerBorderColor` · `pickMarkerBorderWidth` 는 채도 · 명도 핸들에만 닿습니다. 색조 핸들의 테두리는 `hueMarkerBorderColor` · `hueMarkerBorderWidth` 로 바꿉니다. `pickMarkerSize` · `pickMarkerShadow` 는 두 핸들에 닿습니다.
- `dialogStyle` 은 효과가 없습니다.
- `popoverStyle` 의 `triggerStyle` 은 트리거 모양을 바꾸지 않습니다. 트리거는 `trigger` 로 시작하는 필드로 바꿉니다.
- `hexInputStyle` 은 트리거 옆 hex 입력에만 닿고, 패널의 HEX · 채널 칸에는 닿지 않습니다.
- `recentSwatchSpacing` · `recentColumns` 의 최근 색은 두 플랫폼 모두 한 줄입니다. `recentColumns` 는 그 줄에 보이는 개수입니다.
- `transitionDuration` 은 Flutter 에서 효과가 없습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card component="text-field" props="placeholder=#3B82F6" title="TextField">

색 코드를 글자로만 받습니다.

</Card>
<Card component="slider" props="value=50" title="Slider">

숫자 하나를 끌어서 조절합니다.

</Card>
<Card demo="color-picker/related-select" title="Select">

정해진 색 목록에서 하나를 고릅니다.

</Card>
</Cards>

패널을 띄우는 [Popover](/components/popover) 와 인라인 상자를 그리는 [Popup](/components/popup) 도 함께 보세요.
