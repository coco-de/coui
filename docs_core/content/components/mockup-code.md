---
title: MockupCode
description: 코드 에디터 스타일 프레임으로 스니펫을 보여주는 목업
category: display
platforms: [flutter, web]
related: [mockup, code-snippet, mockup-browser]
tags: [mockup, code, editor, presentation]
---

# MockupCode

코드 에디터 스타일 프레임으로 스니펫을 보여주는 목업입니다. 줄 번호는 `MockupCode.fromString` 의 `showLineNumbers` 로 켜고 끕니다. 구문 하이라이팅이 필요하면 `CodeSnippet` 을 쓰고, 세 목업의 전체 스펙은 [Mockup](/components/mockup) 을 보세요.

## Live Preview

<LivePreview component="mockup-code" variants="default,tones" />

## 사용 시기 (When to Use)

**이 컴포넌트를 사용하세요:**

- 문서에서 짧은 코드를 에디터 프레임으로 보여줄 때

**대신 다른 컴포넌트를 사용하세요:**

- 구문 하이라이팅이 있는 코드 블록은 `CodeSnippet`
- 브라우저·앱 창 프레임은 `MockupBrowser`

## 기본 사용법 (Basic Usage)

```dart
MockupCode.fromString(
  "void main() {\n  print('Hello!');\n}",
  showLineNumbers: true,
)
```

코드 블록의 겉모습은 `mockupCodeStyle` (`CoreMockupCodeStyle`) 한 곳으로 바꿉니다.

## Props / Parameters

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `lines` | `List<CoreCodeLine>` | 필수 | 표시할 text / 선택적 prefix 행 |
| `mockupCodeStyle` | `CoreMockupCodeStyle?` | `null` | 코드 프레임·행·텍스트의 겉모습을 바꾸는 값 묶음 |

### 줄 (CoreCodeLine)

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `text` | `String` | 필수 | 줄의 코드 · 출력 텍스트 |
| `prefix` | `String?` | `null` | 줄 번호나 `+` · `-` 같은 접두 기호 |
| `tone` | `CoreCodeLineTone` | `CoreCodeLineTone.neutral` | 줄이 말하는 뜻 (명령 · 경로 · 성공 · 실패 …). 색은 `mockupCodeStyle` 의 tone 색 슬롯이 정합니다 |

### 줄 tone (CoreCodeLineTone)

로그나 터미널 출력은 줄마다 뜻이 다릅니다. 앱이 줄에 색을 직접 적지 않고 뜻(`tone`)만 적으면, 색은 테마가 정합니다. tone 은 **글 색만** 바꿉니다. 서체 · 크기는 그대로이고, 접두(줄 번호) 색도 tone 과 상관없이 `prefixTextStyle` 을 따릅니다.

| tone | 뜻 | 색 슬롯 (`CoreMockupCodeStyle`) | 기본 색 |
|------|----|---------------------------------|---------|
| `neutral` | 일반 코드 · 출력 | 없음 — 코드 글 `textStyle` 의 색을 따릅니다 | `onSurface` |
| `muted` | 명령 에코 · 시각 같은 약한 글 | `mutedToneColor` | `onSurfaceVariant` |
| `link` | 경로 · URL | `linkToneColor` | `link` |
| `success` | 잘 끝난 단계 | `successToneColor` | `onSuccessContainer` |
| `warning` | 실패는 아니지만 눈여겨볼 것 | `warningToneColor` | `onWarningContainer` |
| `error` | 실패 | `errorToneColor` | `onErrorContainer` |

`success` · `warning` · `error` 는 같은 이름의 슬롯이 아니라 컨테이너 위 글 색(`onSuccessContainer` · `onWarningContainer` · `onErrorContainer`)을 씁니다. 코드 블록 면(`surfaceContainerLow`) 위에서 같은 이름의 슬롯은 Light 대비가 4.5:1 에 못 미치기 때문입니다. CoUI 팔레트의 Light 는 `success` 4.50 · `warning` 4.49 · `error` 4.47 이고, 브랜드가 쓰는 표준 매핑의 Light 는 4.37 · 1.67 · 4.30 으로 더 낮습니다. 컨테이너 위 글 색은 어느 쪽에서도 9 이상입니다.

```dart
MockupCode.fromList(const [
  CoreCodeLine(text: '> flutter run', prefix: '1', tone: .muted),
  CoreCodeLine(text: 'http://localhost:8080', prefix: '2', tone: .link),
  CoreCodeLine(text: 'lib/main.dart:12 failed', prefix: '3', tone: .error),
])
```

tone 을 적지 않은 줄은 `neutral` 이라 지금까지와 같은 색으로 그려집니다. 색을 바꾸려면 `mockupCodeStyle: CoreMockupCodeStyle(successToneColor: …)` 처럼 해당 슬롯을 적습니다.

### 팩토리

`MockupCode.fromString(code, showLineNumbers: true)` 는 줄바꿈으로 나누고 1-based prefix를 생성합니다. false이면 prefix를 생성하지 않습니다. `fromList` 는 전달한 CoreCodeLine 목록을 그대로 사용하므로 `tone` 이 있는 줄은 `fromList` 로 만듭니다 (`fromString` 은 모든 줄이 `neutral`).

## 동작 스펙 (Behavior)

- 행 순서와 text / prefix를 그대로 표시합니다. 구문 분석·강조·diff 계산·편집·복사 콜백·비활성 상태는 없습니다.
- 긴 코드 행은 줄바꿈하지 않는 표시이며 가용 폭 안에서 잘릴 수 있습니다. 복사·선택·구문 강조가 필요한 코드 블록이면 **[CodeSnippet](/components/code-snippet)**, 변경 행 비교이면 **[CodeDiff](/components/code-diff)** 입니다.
- 브라우저 창 틀이 필요한 화면 목업이면 **[MockupBrowser](/components/mockup-browser)** 입니다.

## 사용 가이드라인 (Usage Guidelines)

- 프레젠테이션용 프레임입니다. 편집 가능한 에디터로 쓰지 않습니다.
- 긴 파일 전체보다 짧은 스니펫에 맞습니다.

## 접근성 (Accessibility)

### 역할

편집기 역할이 없는 정적 코드 프레임입니다. Web 은 코드 텍스트를 표시하는
래퍼이며 Flutter 도 편집 가능한 필드를 만들지 않습니다.

### 키보드

프레임 자체의 키보드 조작은 없습니다. 입력·커서 이동·코드 편집 단축키를
제공하지 않습니다.

### 스크린 리더

안의 코드 텍스트가 읽힙니다. 코드의 목적을 설명해야 하면 호출부에서 이름·설명을
추가하세요. 줄 번호의 시각적 배치만으로 의미를 전달하지 마세요.

줄 `tone`(성공·경고·실패 등)은 색으로만 구분되고 접근성 트리에는 실리지 않습니다.
의미가 중요한 줄은 글에도 담으세요(예: `Error:` · `Warning:` 접두).

### 포커스 관리

자동 포커스·트랩·복귀가 없습니다. 인터랙티브 편집기가 아니라서 프레임 자신은
포커스를 소유하지 않습니다.

### 알려진 제약

코드의 목적·구문 의미를 자동 설명하거나 변경을 통보하지 않습니다. 편집이 필요한
경우 이 목업을 입력 필드로 쓰지 마세요. 공통 스펙은 [Mockup](/components/mockup)
을 보세요.
## 크로스 플랫폼 차이점 (Platform Differences)

| 항목 | Flutter | Web |
|------|---------|-----|
| 프레임 | OutlinedContainer 안 Column·Row | OutlinedContainer 안 행 div·span |
| prefix | 고정 너비 텍스트 박스 | prefix span |
| 본문 | Expanded 안 softWrap=false Text | nowrap·클립 텍스트 span |
| 이벤트·의미 보강 | 호출부 래퍼 | 외부 DOM 루트의 속성·이벤트 표면 |
