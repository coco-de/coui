---
title: Kbd
description: 키보드 키 한 개나 키 조합을 키캡으로 보여 줍니다. 단축키를 안내할 때 쓰며, 단축키를 등록하거나 실행하지는 않습니다.
category: display
platforms: [flutter, web]
related: [code-snippet, command, tooltip]
tags: [keyboard, shortcut, visual]
template: v2
source: display/kbd
---

# Kbd

<a id="live-preview"></a>

## 플레이그라운드

키 목록, 키캡 사이 간격, 키마다 붙는 그림자를 바꿔 보며 Kbd를 확인하고, 만들어진 코드를 그대로 복사하세요. 두 플랫폼의 코드가 같습니다.

<Playground component="kbd" />

키 한 개는 키캡 하나이고, `Kbd` 하나는 조합 하나입니다. 키가 여러 개면 키캡을 받은 순서대로 나란히 놓으며, 키 사이에 `+` 같은 글자는 그리지 않습니다. 단축키 안내, 도움말 페이지, 커맨드 팔레트에 씁니다.

두 플랫폼은 키캡을 같은 토큰으로 그립니다. 글자는 `labelXs` 역할(본문 서체)이고, `surface` 배경에 `outlineSubtle` 색의 0.5 테두리와 `CoreRadius.radius4` 모서리를 씁니다. 키캡은 페이지와 같은 면을 가는 테두리로 구분합니다. 기본 그림자는 없고, `keyShadow` 에 적은 그림자만 키마다 붙습니다. 아이콘 키 안의 아이콘 색처럼 플랫폼마다 달라지는 것은 [플랫폼 차이](#플랫폼-차이)에 있습니다.

## 구조

Kbd는 키캡을 한 줄에 놓는 바깥 상자와 키캡으로 이루어집니다.

<Anatomy demo="kbd/anatomy">
<AnatomyItem part="container" name="Container">

키캡을 받은 순서대로 놓는 상자입니다. 자기 배경과 테두리는 없고 키캡 사이 간격만 정합니다. 조합 전체의 접근 가능한 이름이 여기에 붙습니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="Key cap">

키 하나를 담는 상자입니다. 배경, 가는 테두리, 모서리, 안쪽 여백이 있고 키 글자나 `keyContent` 를 가운데에 놓습니다.

</AnatomyItem>
</Anatomy>

Flutter의 `Kbd.icon` 은 바깥 상자 없이 키캡 하나만 그립니다.

<a id="기본-사용법-basic-usage"></a>

## 키 하나 · 조합 · 아이콘 키

생성자는 셋이고 두 플랫폼의 이름이 같습니다.

<Cards columns="3">
<Card demo="kbd/constructor-keys" title="Kbd">

키 목록을 받아 키마다 키캡 하나를 그립니다.

</Card>
<Card demo="kbd/constructor-single" title="Kbd.single">

키 글자 하나를 받습니다. `Kbd(keys: [keyText])` 와 같은 모습입니다.

</Card>
<Card demo="kbd/constructor-icon" title="Kbd.icon">

위젯 하나를 키캡 하나에 담습니다. `label` 이 이 키의 이름입니다.

</Card>
</Cards>

| 생성자 | 받는 값 | 접근 가능한 이름 | `const` |
| --- | --- | --- | --- |
| `Kbd` | `keys`(필수), `kbdStyle` | `keys` 를 공백으로 이은 문자열 | 가능 |
| `Kbd.single` | `keyText`(필수), `kbdStyle` | `keyText` | 불가 |
| `Kbd.icon` | `keyContent`(필수), `label`, `kbdStyle` | `label`. 없으면 이름이 없습니다 | 가능 |

키 하나부터 네 개까지 같은 방법으로 그립니다.

<Preview demo="kbd/counts" />

```dart
// 키 하나
const Kbd(keys: ['Esc'])

// 키 조합 (2개)
const Kbd(keys: ['Ctrl', 'C'])

// 키 3개
const Kbd(keys: ['Ctrl', 'Shift', 'P'])

// 키 4개 — OS 가 정한 단축키를 보여 줄 때만 (macOS: 화면 일부를 클립보드로)
const Kbd(keys: ['⌃', '⇧', '⌘', '4'])

// 맥 스타일
const Kbd(keys: ['⌘', 'K'])

// 방향키
const Kbd(keys: ['↑'])

// 키 하나를 받는 생성자 — const 로 만들 수 없습니다
Kbd.single(keyText: '⌘')

// 아이콘 키 — label 이 이 키의 접근 가능한 이름입니다
const Kbd.icon(
  keyContent: Icon(
    LucideIcons.cornerDownLeft,
    iconStyle: CoreIconStyle(
      size: CoreIconSize.size12,
      color: CoreColor.token(CoreColors.onSurfaceVariant),
    ),
  ),
  label: '확인',
)

// 키캡 사이 간격 바꾸기
const Kbd(
  keys: ['Ctrl', 'C'],
  kbdStyle: CoreKbdStyle(keySeparatorSpacing: CoreSpace.space8),
)
```

`Kbd.icon` 은 `⌘` · `↵` 같은 기호 글자가 글꼴 대체에 따라 플랫폼마다 다른 모양으로 보이는 것을 피할 때 씁니다. 같은 아이콘을 넘기면 두 플랫폼이 같은 아이콘 그림을 그립니다. 다만 `LucideIcons.command` 처럼 패키지에 담겨 있지 않은 아이콘은 Web에서 [Icon](/components/icon)의 `iconScript()` 를 페이지에 넣어야 보입니다. 예제의 `cornerDownLeft` 는 패키지에 담겨 있습니다. `keyContent` 와 `keys` 는 함께 쓸 수 없어서 `Kbd.icon` 의 `keys` 는 빈 목록입니다. `copyWith` 로는 `keyContent` 와 `label` 을 바꿀 수 없고, `copyWith(keys: ...)` 를 불러도 아이콘 키로 남습니다.

`Kbd` 는 아이콘의 크기와 색을 정하지 않습니다. 크기를 비우면 앱의 기본 아이콘 크기(20)가 쓰여 글자 키보다 키캡이 커지고, 색을 비우면 두 플랫폼의 색이 달라질 수 있습니다. 위 예제처럼 크기와 색을 `Icon` 에 직접 주세요.

## 예시 단축키

<Preview demo="kbd/shortcut-list" />

```dart
// 복사
const Kbd(keys: ['Ctrl', 'C'])

// 붙여넣기
const Kbd(keys: ['Ctrl', 'V'])

// 전체 선택
const Kbd(keys: ['Ctrl', 'A'])

// 커맨드 팔레트 (macOS)
const Kbd(keys: ['⌘', 'K'])

// 저장
const Kbd(keys: ['Ctrl', 'S'])

// 실행 취소
const Kbd(keys: ['Ctrl', 'Z'])

// 화면 일부를 클립보드로 (macOS, OS 가 정한 단축키 — 4개 키)
const Kbd(keys: ['⌃', '⇧', '⌘', '4'])
```

## ShortcutActivator에서 키 목록 만들기

`kbdKeysFromActivator` 는 Flutter 전용 최상위 함수입니다. `ShortcutActivator` 하나를 받아 `Kbd` 에 넘길 `List<String>` 을 돌려줍니다. 앱에서 단축키에 쓰는 `ShortcutActivator` 를 그대로 보여 줄 때 씁니다. 이 함수는 키 이름만 만들고, 단축키를 등록하거나 키 입력을 듣지 않습니다. Web에는 `ShortcutActivator` 가 없으므로 키 목록을 직접 넘깁니다.

<Preview demo="kbd/activator" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

const saveAs = SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true);

// Ctrl · Shift · S
Kbd(keys: kbdKeysFromActivator(saveAs))
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
const Kbd(keys: ['Ctrl', 'Shift', 'S'])
```

  </TabItem>
</Tabs>

`LogicalKeyboardKey` 는 `coui_flutter` 에 들어 있지 않으므로 `flutter/services.dart` 를 함께 가져옵니다.

수정키가 먼저 오고 순서는 Apple Human Interface Guidelines의 Ctrl → Alt → Shift → ⌘ 입니다. 그다음에 함께 누르는 키가 옵니다.

| 넘기는 값 | 읽는 것 |
| --- | --- |
| `SingleActivator` | `control` · `alt` · `shift` · `meta` 와 `trigger` |
| `CharacterActivator` | `control` · `alt` · `meta` 와 대문자로 바꾼 `character`. `Shift` 는 붙지 않습니다 |
| `LogicalKeySet` | 수정키는 왼쪽과 오른쪽을 구분하지 않고 읽습니다. 나머지 키는 키 번호(`keyId`) 순으로 놓아, 집합을 만든 순서와 관계없이 결과가 같습니다 |
| 그 밖의 `ShortcutActivator` | 빈 목록. 빈 목록을 받은 `Kbd` 는 키캡을 그리지 않습니다 |

| 키 | 표기 |
| --- | --- |
| Control · Alt · Shift · Meta | `Ctrl` · `Alt` · `Shift` · `⌘` |
| Enter · 왼쪽 · 오른쪽 · 위 · 아래 | `↵` · `←` · `→` · `↑` · `↓` |
| 그 밖의 키 | Flutter의 `LogicalKeyboardKey.keyLabel` 그대로입니다. Esc 키는 `Escape` 로 나옵니다 |

- 이 함수는 실행 중인 OS를 보지 않습니다. Windows에서도 Meta 키는 `⌘` 이고, macOS에서도 Option 키는 `Alt` 입니다.
- Space 키의 `keyLabel` 은 공백 한 칸이라 글자가 보이지 않는 키캡이 됩니다. 이때는 `keys: ['Ctrl', 'Space']` 처럼 직접 적으세요.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

다음 경우에 씁니다.

- 단축키나 키 조합을 눈에 보이게 안내할 때
- 도움말 페이지나 온보딩에서 키보드 사용법을 설명할 때
- 커맨드 팔레트의 항목 옆에 단축키를 보여 줄 때
- 접근성 안내 문서에서 키보드 탐색 방법을 설명할 때
- Flutter의 `ShortcutActivator` 로 정한 단축키를 그대로 보여 줄 때 (`kbdKeysFromActivator`, Flutter 전용)

다른 컴포넌트가 `Kbd` 를 안에서 그리기도 합니다. [Command](/components/command)의 키 안내, [Sidebar](/components/sidebar)의 `SidebarSearch` 단축키, [RichEditor](/components/rich-editor) 툴바의 툴팁이 그렇고, 세 곳 모두 `kbdStyle` 로 모양을 바꿉니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 여러 줄 코드나 복사 기능이 필요할 때 | [CodeSnippet](/components/code-snippet) |
| 키 상자 없이 문자열만 보일 때, 문장 안에서 단축키를 적을 때 | [Text](/components/text). `Ctrl+S` 처럼 글자로 씁니다 |
| 눌러서 동작을 실행해야 할 때 | [Button](/components/button) |

<a id="인터랙션"></a>

### 표시 전용

- 클릭, hover, 눌림, 비활성 상태가 없습니다.
- 단축키를 등록하거나 키 입력을 받지 않습니다. 키를 동작에 연결하는 일은 그 단축키를 가진 앱 코드나 컴포넌트가 합니다.
- `keys` 는 넘긴 순서대로 그리고, 빈 목록은 키캡을 그리지 않습니다.
- `Kbd.icon` 은 `keyContent` 하나를 키캡 하나 안에 그립니다.

<a id="키는-몇-개까지-key-count"></a>

### 키는 몇 개까지

**앱이 정하는 단축키는 3개까지. 4개는 OS가 정한 단축키(⌃⇧⌘4 등)를 보여 줄 때만.**

| 키 수 | 쓰는 곳 |
| --- | --- |
| 1 ~ 3 | 앱이 정하는 단축키 |
| 4 | OS가 정한 단축키를 보여 줄 때만 |

이 기준은 사용 지침이고, 코드에는 키 수 상한이 없습니다. 조합의 폭은 [키 수와 너비](#키-수와-너비)에서 확인하세요.

<a id="do"></a>
<a id="dont"></a>

### 권장과 금지

`Kbd` 는 받은 글자를 그대로 보여 줄 뿐 OS를 보고 표기를 바꾸지 않습니다. 플랫폼에 따라 어느 표기를 쓸지는 호출자가 정합니다.

```dart
const Kbd(keys: ['⌘', 'K']) // macOS
const Kbd(keys: ['Ctrl', 'K']) // Windows / Linux
```

<Cards columns="2">
<Card demo="kbd/do-platform" tone="do" eyebrow="이렇게 하세요">

사용하는 사람의 OS에 맞는 키 표기를 넘깁니다.

</Card>
<Card demo="kbd/dont-plus" tone="dont" eyebrow="이렇게 하지 마세요">

키 사이에 `+` 를 키로 끼워 넣지 않습니다. 키캡이 이미 키를 나누고 있고, 간격은 `keySeparatorSpacing` 이 정합니다.

</Card>
<Card demo="kbd/do-text" tone="do" eyebrow="이렇게 하세요">

문장 안의 단축키는 `Ctrl+S` 처럼 글자로 씁니다.

</Card>
<Card demo="kbd/dont-in-sentence" tone="dont" eyebrow="이렇게 하지 마세요">

문장 중간에 키캡을 끼워 넣지 않습니다. `Kbd` 는 문장 밖에서 키를 키캡으로 보여 줄 때 씁니다.

</Card>
<Card demo="kbd/do-three" tone="do" eyebrow="이렇게 하세요">

앱이 직접 정하는 단축키는 3개 안에서 해결합니다.

</Card>
<Card demo="kbd/dont-four" tone="dont" eyebrow="이렇게 하지 마세요">

앱이 정하는 단축키에 4개 키를 쓰지 않습니다. 키 글자가 많아지면 폭도 커집니다.

</Card>
</Cards>

- 조합의 폭보다 좁은 칸에 넣지 마세요. 키캡이 줄어들지 않으므로 조합이 칸 밖으로 넘칩니다.
- `Kbd` 를 누를 수 있는 버튼처럼 쓰지 마세요. 표시 전용입니다. 클릭이 필요하면 [Button](/components/button)을 씁니다.

<a id="동작-스펙-behavior"></a>

## 배치

### 레이아웃

- 바깥 상자는 내용만큼만 차지하는 가로 한 줄입니다. Flutter는 `Row`(`mainAxisSize: MainAxisSize.min`), Web은 `inline-flex` 상자입니다. 키캡은 받은 순서대로 놓고 사이는 `keySeparatorSpacing`(기본 `CoreSpace.space4`)만 띄웁니다. 키 사이에 그리는 글자는 없습니다.
- 키캡의 안쪽 여백은 위아래 `CoreSpace.space2`, 좌우 `CoreSpace.space6` 입니다. 이 여백을 포함한 안쪽 영역의 최소 정사각이 `keyMinSize`(기본 `CoreSize.size18`)이고, 보이는 테두리는 그 바깥에 더해집니다. 예를 들어 기본 서페이스 스타일에서 `keyMinSize: 40`, `keyBorderWidth: 2` 이면 짧은 키의 바깥 크기는 44×44px입니다. 테두리 색이 투명하면 폭이 0이 되어 자리를 차지하지 않습니다.
- 기본 `labelXs` 는 11px에 줄 높이 배수 1.4입니다. 11 × 1.4 = 15.4인 줄은 두 플랫폼 모두 15px로 그려집니다(줄 높이는 정수 픽셀). 기본 스타일 · Pretendard 500 · 1배 화면에서 잰 키 높이는 두 플랫폼 모두 21px입니다. 줄 15에 위아래 여백 2씩과 위아래 테두리 1씩을 더한 값입니다.
- 0.5 테두리는 2배 미만 화면에서 두 플랫폼 모두 1px, 2배부터 0.5px로 그려집니다.
- 테두리 색은 `outlineSubtle`, 폭은 `CoreStrokeWidth.stroke0_5`, 배경은 `surface`, 모서리는 `CoreRadius.radius4` 이고 그림자는 없습니다(`CoreShadow.none`).
- `keyShadow` 에 적은 그림자는 키캡마다 붙고, 키를 늘어놓은 줄에는 붙지 않습니다. 그림자를 적지 않으면 서페이스 스타일도 키캡에 그림자를 더하지 않습니다. 적으면 서페이스 스타일이 그 그림자의 번짐과 위치를 바꿀 수 있고, 가장자리 안쪽 빛을 정한 스타일은 그 빛도 함께 그립니다. Web에서 번짐과 위치가 바뀌는 것은 `CoreShadow.xs` 같은 `CoreShadow` 단계 값을 적었을 때입니다. 단계 값과 다르게 직접 만든 그림자는 Web에서 번짐과 위치를 적은 그대로 씁니다.
- 키가 놓이는 방향은 글 방향을 따릅니다. 오른쪽에서 왼쪽으로 쓰는(RTL) 화면에서는 첫 키가 오른쪽 끝에 놓입니다. 접근 가능한 이름은 `keys` 순서 그대로입니다. 이런 화면에서도 왼쪽부터 놓으려면 Web은 `attributes: {'dir': 'ltr'}` 를 넘기고, Flutter는 바깥을 `Directionality(textDirection: TextDirection.ltr)` 로 감쌉니다.
- 조합은 한 줄을 유지하고 줄어들지 않습니다. 칸이 모자라면 글자가 잘리는 대신 조합이 칸 밖으로 넘칩니다. Web은 밖으로 삐져나오고, Flutter는 개발 모드에서 Row 오버플로 오류를 알립니다.

### 키 수와 너비

코드에는 키 수 상한이 없어 4개도 그대로 그려집니다. 아래는 기본 스타일, Pretendard 500, `labelXs` 11px, 키 간격 4px, 기본 테두리, 1배 화면에서 잰 너비입니다(Flutter는 논리 픽셀, Web은 CSS 픽셀). 글꼴, 서페이스 스타일, 배율, 안쪽 여백을 바꾸면 다시 재세요.

| 조합 | Flutter | Web |
| --- | --- | --- |
| `⌃ ⇧ ⌘ 4` (4개) | 약 104.50px | 약 104.52px |
| `Ctrl Alt Shift F5` (4개) | 약 134.44px | 약 134.45px |

두 조합 모두 240px 칸보다는 좁지만, 같은 줄의 라벨과 간격까지 포함한 남는 폭을 확인해야 합니다. `⌃ ⇧ ⌘ 4` 는 120px 칸에 들어가고 80px 칸에서는 넘칩니다. `Ctrl Alt Shift F5` 는 120px 칸에서도 넘칩니다. 키 수만 보고 고정 폭을 정하지 말고 실제 조합을 기준으로 칸 너비를 정하세요.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

보여 줄 내용은 위젯 파라미터(`keys` · `keyContent` · `label`)로 넘기고, 겉모습(색 · 크기 · 간격)과 글자 스타일은 `kbdStyle`(`CoreKbdStyle`) 하나로 바꿉니다. 키캡 사이 간격은 `keySeparatorSpacing` 이고 기본값은 `CoreSpace.space4`(4px)입니다. 키 사이에 그리는 글자가 없어, 이웃 키캡과 키캡의 그림자를 떼어 놓는 것은 이 간격입니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
CoreKbdStyle.defaultX 상수          // 디자인 시스템 기본값
  → CoreKbdTheme.style              // 앱 전체 (CoreComponentTheme.kbd)
  → kbdStyle                        // Kbd 하나
```

- 필드마다 따로 합칩니다. `keyTextStyle` 은 글자 스타일의 속성 단위로 한 번 더 합쳐져, 색만 적어도 `labelXs` 역할은 남습니다. `keyPadding` · `keyRadius` · `keyShadow` 는 적은 값이 통째로 바꿉니다.
- 다른 컴포넌트가 안에 그리는 `Kbd` 에는 그 컴포넌트의 `kbdStyle` 이 마지막 자리로 들어옵니다.

<Split>

<Code language="dart" title="Kbd 하나만 바꾸기">
const Kbd(
  keys: ['⌘', 'K'],
  kbdStyle: CoreKbdStyle(
    keyBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    keyRadius: CoreBorderRadius.all(CoreRadius.radius8),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    kbd: CoreKbdTheme(
      style: CoreKbdStyle(keyShadow: CoreShadow.xs),
    ),
  ),
)
</Code>

</Split>

### 토큰

| 항목 | Flutter | Web |
| --- | --- | --- |
| 키 글자 | `labelXs` 역할(11px · 본문 서체) | `labelXs` 역할(11px · 본문 서체), `text-label-xs` 클래스 |
| 글자 굵기 | 역할의 500 | 역할의 500 |
| 글자 색 | `colorScheme.onSurfaceVariant` | `text-on-surface-variant` |
| 배경 | `colorScheme.surface` | `bg-surface` |
| 테두리 | `outlineSubtle`, 폭 0.5 | `border border-outline-subtle` 와 `var(--coui-stroke-width-0_5)` |
| 모서리 | `BorderRadius`(`CoreRadius.radius4`) | 인라인 `border-radius` |
| 그림자(적었을 때) | `InjectedCast`(상자 바깥에만 칠함) | 인라인 `box-shadow`(`CoreShadow.xs` 면 `var(--shadow-xs)`) |
| 키 사이 간격 | `Row.spacing` = `keySeparatorSpacing` | flex `gap` = `keySeparatorSpacing` |

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

이미 만든 `Kbd` 에 `withStyle` 을 이어 `kbdStyle` 을 덧붙일 수 있습니다. 생성자의 `kbdStyle` 과 같게 동작하고, 겹치는 필드는 나중에 이은 값이 이깁니다. `Kbd.icon` 에 이어도 아이콘 키로 남습니다.

<Preview component="kbd" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class KbdChainExample extends StatelessWidget {
  const KbdChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Kbd(keys: ['Ctrl', 'C']).withStyle(
      const CoreKbdStyle(
        keyRadius: CoreBorderRadius.all(CoreRadius.radius9999),
        keyBackgroundColor: CoreColor.token(CoreColors.primaryContainer),
        keyBorderColor: CoreColor.token(CoreColors.primary),
        keyBorderWidth: CoreStrokeWidth.stroke2,
        keyPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space12,
          vertical: CoreSpace.space6,
        ),
        keyTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelMedium,
          color: CoreColor.token(CoreColors.onPrimaryContainer),
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class KbdChainExample extends StatelessComponent {
  const KbdChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Kbd(keys: ['Ctrl', 'C']).withStyle(
      const CoreKbdStyle(
        keyRadius: CoreBorderRadius.all(CoreRadius.radius9999),
        keyBackgroundColor: CoreColor.token(CoreColors.primaryContainer),
        keyBorderColor: CoreColor.token(CoreColors.primary),
        keyBorderWidth: CoreStrokeWidth.stroke2,
        keyPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space12,
          vertical: CoreSpace.space6,
        ),
        keyTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelMedium,
          color: CoreColor.token(CoreColors.onPrimaryContainer),
        ),
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

`Kbd` 하나는 조합 하나이며 **접근 가능한 이름도 하나**입니다. 이름이 있으면 키캡이 하나씩 따로 읽히지 않습니다.

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | 전체를 `Semantics(label: ..., excludeSemantics: true)` 로 감싸 안쪽 키캡 글자를 의미 트리에서 뺍니다. 따로 역할을 붙이지 않습니다. 별도의 의미 노드를 강제하지도 않아, 놓인 자리에 따라 옆의 글과 한 노드로 합쳐질 수 있습니다. |
| Web | 루트 `<span>` 에 `role="img"` 와 `aria-label` 을 붙이고, 안의 키캡은 장식으로 취급됩니다. 네이티브 `<kbd>` 요소는 쓰지 않습니다. |

이름이 없는 `Kbd`(`label` 없는 `Kbd.icon`, 빈 `keys`)에는 Flutter의 이름도, Web의 `role` 도 붙지 않습니다.

### 키보드

없음. 처리하는 키가 없고 생성자로 붙일 수도 없습니다. Web의 세 생성자는 내용 파라미터와 `key` · `kbdStyle` · `attributes` · `classes` · `css` · `id` 만 받고 `eventHandlers` · `onKeyDown` · `onClick` 을 받지 않습니다. Flutter 생성자에도 콜백이 없습니다. 이 컴포넌트는 단축키를 **표시**할 뿐 실행하지 않습니다. 실제 키 연결은 그 단축키를 가진 쪽에 있습니다.

### 스크린 리더

접근 가능한 이름은 `keys` 에 넣은 문자열에서 옵니다. 키 글자를 **공백으로 이은 하나의 이름**이라 `Kbd(keys: ['Ctrl', 'S'])` 의 이름은 "Ctrl S"입니다. 키 사이에 글자를 그리지 않으므로 `+` 도 이름에 없습니다. `⌘` 같은 기호 키는 글자 그대로 이름에 들어가며, 어떻게 발음하는지는 스크린 리더에 달려 있습니다.

`Kbd.icon` 은 `label` 이 그 키의 이름입니다. `label: '위로'` 면 "위로"가 이름입니다. `label` 을 주지 않으면 `Kbd` 는 이름을 붙이지 않고, 아이콘만 담은 키는 읽히지 않습니다. Command 푸터의 "이동" 옆 화살표 키처럼 이웃 글이 이미 동작을 말하는 자리에서는 비워 두고, 키가 혼자 서 있는 자리에서는 `label` 을 주세요.

기호 키가 원하는 대로 읽히지 않으면 이름을 바꿀 수 있습니다. Web은 `attributes` 의 `aria-label` 이 컴포넌트가 붙인 이름보다 우선하고, Flutter는 바깥을 `Semantics` 로 감쌉니다.

<Split>

<Code language="dart" title="Web">
const Kbd(
  keys: ['⌘', 'K'],
  attributes: {'aria-label': 'Command K'},
)
</Code>

<Code language="dart" title="Flutter">
Semantics(
  label: 'Command K',
  excludeSemantics: true,
  child: const Kbd(keys: ['⌘', 'K']),
)
</Code>

</Split>

상태를 알리는 기능은 없습니다. 두 플랫폼 모두 live region이 아닙니다.

### 포커스 관리

없음. 포커스를 받지 않습니다. Flutter에는 `Focus` 가 없고 Web에는 기본 `tabindex` 가 없어 두 플랫폼 모두 Tab 순서에 들어가지 않습니다. 오버레이가 아니므로 포커스를 옮기거나 가두지도 않습니다.

### 알려진 제약

- **`aria-keyshortcuts` 를 붙이지 않습니다.** `Kbd` 는 단축키를 표시만 합니다. 단축키를 가진 컨트롤이 스크린 리더에 단축키를 알리게 하려면 그 컨트롤에 `aria-keyshortcuts` 를 직접 넣어야 합니다.
- **Web 루트 태그를 `<kbd>` 로 바꿀 수 없습니다.** 세 생성자 모두 루트가 `<span>` 이라 네이티브 키보드 입력 의미를 얻을 수 없습니다. 접근 가능한 이름은 `role="img"` 와 `aria-label` 이 맡습니다.
- **Web의 색 강제 모드에서 키캡 경계는 테두리에 달려 있습니다.** 기본 테두리는 CSS `border` 라서 이 모드에서 시스템 색으로 남습니다. 배경색 차이와 `box-shadow` 에는 기댈 수 없습니다. `keyBorderColor` 를 투명하게 바꾸면 테두리 폭이 0이 되어, 색 강제 모드의 경계를 따로 정한 서페이스 스타일이 아니면 키캡 상자가 보이지 않을 수 있습니다.
- **Flutter의 `keyContent` 는 키캡의 글자색과 글자 스타일을 받지 않습니다.** 아이콘 색을 비우면 주변 `IconTheme` 의 색이 쓰이고, `keyTextStyle` 을 바꿔도 따라가지 않습니다.
- **최소 터치 타깃은 적용 대상이 아닙니다.** 키캡의 기본 최소 크기(`CoreSize.size18`, 18px)는 24px보다 작지만, 두 플랫폼 모두 누를 수 있는 요소가 아닙니다.

동작 줄이기, 고대비처럼 모든 컴포넌트에 공통으로 적용되는 축은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

생성자 이름과 파라미터 이름은 같고, Web에는 HTML 속성을 받는 파라미터가 더 있습니다. 그리는 방식과 아래 항목이 다릅니다.

| 항목 | Flutter | Web |
| --- | --- | --- |
| 키 나열 | `Row.spacing` 과 키마다 상자 하나 | 바깥 `<span>` 안의 키 `<span>` 들을 flex `gap` 으로 나열 |
| 키 사이 글자 | 없음 | 없음 |
| 접근 가능한 이름 | `Semantics` 라벨(키캡 글자는 의미 트리에서 제외) | 루트 `<span role="img" aria-label>`, 키캡은 장식 |
| 키의 의미 | 네이티브 키보드 입력 의미 없음 | 네이티브 `<kbd>` 가 아닌 `<span>` 글자 |
| 아이콘 키 | `Widget` `keyContent` 와 `label` | `Component` `keyContent` 와 `label` |
| 색을 비운 아이콘 | 주변 `IconTheme` 의 색. `CoUIApp` 바로 아래에서는 `onSurface` | 주변 `IconTheme` 에 색이 있으면 그 색, 없으면 키캡의 글자색(`currentColor`). `CoUIWeb` 이 맨 바깥에 두는 `IconTheme` 에는 색이 없음 |
| `keyContent` 에 글자를 넣을 때 | 주변 글자 스타일로 그림 | 키캡의 글자 스타일을 물려받음 |
| `ShortcutActivator` 변환 | `kbdKeysFromActivator` | 없음. 키 목록을 직접 넘김 |
| 좁은 칸 | 키캡이 줄어들지 않고 Row 오버플로로 알림 | `flex-shrink: 0` 으로 줄어들지 않고 칸 밖으로 넘침 |
| 0.5 테두리 | 2배 미만 화면 1px, 2배부터 0.5. `CoUIApp` 이 화면 배율을 테마에 반영 | 2배 미만 화면 1px, 2배부터 0.5px(`--coui-stroke-width-0_5`) |
| 투명한 테두리 | 폭 0 | 폭 0, `border` 클래스 없음 |
| 키 그림자(적었을 때) | 상자 바깥에만 칠함. 안쪽(inset) 층은 그리지 않음 | CSS `box-shadow`. 안쪽(inset) 층도 CSS에 들어감 |
| 크기 배율 | `keyMinSize` 와 키 간격에 테마의 크기 배율(`scaling`)을 곱함 | `scaling` 값이 없음. 최소 크기와 키 간격은 `rem` 단위라 브라우저의 기본 글자 크기를 따름 |
| 웹 전용 속성 | 없음 | `id` · `classes` · `css` · `attributes` |

두 플랫폼 모두 서페이스 스타일이 키캡에 닿습니다. 테두리의 최소 굵기를 정한 스타일은 기본 테두리를 더 굵게 만들고, 반투명 재질을 쓰는 스타일은 배경이 있는 키캡에 그 재질을 입힙니다.

## KeyboardShortcut 에서 옮겨 오기

`KeyboardShortcut` 컴포넌트는 없습니다. 같은 일을 `Kbd` 가 합니다.

| 이전 | 이후 |
| --- | --- |
| `KeyboardShortcut(keys: k)` | `Kbd(keys: k)` |
| `KeyboardShortcut(keys: k, spacing: s)` | `Kbd(keys: k, kbdStyle: CoreKbdStyle(keySeparatorSpacing: s))` |
| `KeyboardShortcut.fromActivator(activator: a)` (Flutter) | `Kbd(keys: kbdKeysFromActivator(a))` |

그대로 바꾸면 모양과 순서가 달라집니다.

- 키 사이의 `+` 글자가 없고, 키캡 간격 기본값은 `space2` 가 아니라 `space4` 입니다. 문장 안에서 단축키를 적을 때의 `+` 는 `Ctrl+S` 처럼 글자로 씁니다.
- `fromActivator` 가 내던 수정키 순서 Ctrl → Alt → ⌘ → Shift 는 Apple HIG의 Ctrl → Alt → Shift → ⌘ 가 됩니다.
- `CoreKeyboardShortcutContract` · `CoreKeyboardShortcutStyle` · `CoreKeyboardShortcutTheme` · `CoreComponentTheme.keyboardShortcut` 이 없으므로 간격은 `CoreKbdStyle.keySeparatorSpacing` 으로 줍니다. 그릴 구분자가 없어 `CoreKbdStyle.separatorTextStyle` 도 없습니다.
- Flutter의 `KeyboardShortcutDisplayMapper` · `KeyboardShortcutDisplayHandle` · `KeyboardShortcutDisplayBuilder` 도 없습니다.

<a id="props-parameters"></a>

## API

Flutter와 Web이 같은 이름을 씁니다. Flutter 전용 함수 `kbdKeysFromActivator(ShortcutActivator activator)` 의 동작은 [ShortcutActivator에서 키 목록 만들기](#shortcutactivator에서-키-목록-만들기)에 있습니다.

### 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `keys` | `List<String>` | `Kbd` 에서 필수 | 보여 줄 키 목록. 넘긴 순서대로 키캡을 놓습니다. `Kbd.single` 은 `[keyText]`, `Kbd.icon` 은 빈 목록입니다. |
| `keyContent` | Flutter `Widget?` · Web `Component?` | `null` | `Kbd.icon` 전용이며 거기서는 필수입니다. 키캡 하나에 담는 위젯입니다. |
| `label` | `String?` | `null` | `Kbd.icon` 전용. 그 키의 접근 가능한 이름입니다. 글자 키의 이름은 `keys` 에서 만듭니다. |
| `kbdStyle` | `CoreKbdStyle?` | `null` | 안쪽 여백 · 간격 · 모서리 · 색 · 그림자 · 글자 스타일을 바꾸는 값 묶음입니다. |
| `key` | `Key?` | `null` | 위젯 키입니다. |

`Kbd.single` 은 `keys` 대신 `keyText`(`String`, 필수)를 받습니다.

### 웹 전용 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트 `<span>` 의 `id` |
| `classes` | `String?` | `null` | 루트에 덧붙이는 CSS 클래스 |
| `css` | `Styles?` | `null` | 루트에 덧붙이는 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 루트의 HTML 속성. 컴포넌트가 붙인 `role` · `aria-label` 과 겹치면 이 값이 우선합니다. |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreKbdStyle patch)` | `kbdStyle` 에 `patch` 를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch` 가 이깁니다. |
| `copyWith({key, keys, kbdStyle})` | 바꾼 값으로 사본을 만듭니다. 아이콘 키는 `keys` 를 넘겨도 아이콘 키로 남습니다. Web은 `id` · `classes` · `css` · `attributes` 도 받으며, `classes` 는 기존 값에 덧붙입니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.kbd` | `CoreKbdTheme?` | 앱 전체의 `Kbd` 테마 자리입니다. |
| `CoreKbdTheme.style` | `CoreKbdStyle?` | 모든 `Kbd` 에 적용합니다. 인스턴스의 `kbdStyle` 이 이깁니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreKbdStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `keyPadding` | `CoreEdgeInsets?` | Padding inside each key box. |
| `keySeparatorSpacing` | `double?` | Spacing (logical px) between adjacent key boxes — rendered as `Row.spacing` (Flutter) / flex container `gap` (Web). N-sibling 균등 분포 (Key, Key, Key) 패턴. See [defaultKeySeparatorSpacing]. |
| `keyMinSize` | `double?` | Minimum key-box square extent — see [defaultKeyMinSize]. |
| `keyRadius` | `CoreBorderRadius?` | Border radius of key boxes. |
| `keyBackgroundColor` | `CoreColor?` | Background colour of each key box. |
| `keyBorderColor` | `CoreColor?` | Border colour of each key box. |
| `keyBorderWidth` | `double?` | Border stroke width of each key box — see [defaultKeyBorderWidth]. Drawn only while [keyBorderColor] is visible. |
| `keyShadow` | `List<CoreShadowLayer>?` | Shadow of each key box — see [defaultKeyShadow]. An empty list draws no shadow. |
| `keyTextStyle` | `CoreTextStyle?` | Text style applied to the key label characters. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="CodeSnippet" href="/components/code-snippet" more="CodeSnippet 보기">

여러 줄 코드나 명령어 블록을 보여 줍니다.

</Card>
<Card demo="kbd/related-command" title="Command" href="/components/command" more="Command 보기">

푸터에 키 하나짜리 `Kbd` 힌트를 놓는 커맨드 팔레트입니다. 위 그림은 푸터처럼 키캡과 글을 나란히 놓은 것입니다.

</Card>
<Card demo="kbd/related-tooltip" title="Tooltip">

아이콘 버튼의 단축키를 안내할 때 [Tooltip](/components/tooltip) 과 함께 씁니다. 툴팁 안에 `Kbd` 를 넣으려면 `tooltipChild` 에 둡니다. 버튼의 접근 가능한 이름은 툴팁에 맡기지 말고 버튼에 따로 줍니다. 위 그림은 툴팁이 닫혀 있는 버튼이라 `Kbd` 는 툴팁이 열려야 보입니다.

</Card>
</Cards>
