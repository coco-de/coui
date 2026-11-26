# Changelog

## [4.0.1](https://github.com/coco-de/coui/compare/coui_mcp-v4.0.0...coui_mcp-v4.0.1) (2026-10-23)


### 문서

* **flutter,docs,mcp:** 📝 InputOtp — 없어진 otpToString 안내를 String.fromCharCodes 로, coui_mcp 예제를 현재 API 로 ([#5673](https://github.com/coco-de/coui/issues/5673)) ([8e7f5f1](https://github.com/coco-de/coui/commit/8e7f5f1eb23e5f001c323066bc7f0b87212d681f))

## [4.0.0](https://github.com/coco-de/coui/compare/coui_mcp-v3.1.0...coui_mcp-v4.0.0) (2026-10-16)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** `CoreButtonVariant.link` · `CoreButtonStyle.hoverTextDecoration` · `Text.thenButton` 을 지웠다 — 링크는 `Link` / `Link.inlineSpan` / `plain`, `thenButton` 은 `Text.thenLink` 로 옮기고, secondary · destructive · 비활성 글자색과 라이트 `error-pressed` 값이 바뀌었으며 DatePicker · TimePicker 오류 트리거는 destructive 대신 `errorTriggerStyle`(테두리 · 포커스 링 `error`)로 그린다.
* **core,flutter,web,figma:** `KeyboardShortcut`(Flutter·Web), `CoreKeyboardShortcutContract`·`CoreKeyboardShortcutStyle`·`CoreKeyboardShortcutTheme`, `CoreComponentTheme.keyboardShortcut`, Flutter `KeyboardShortcutDisplayMapper`·`KeyboardShortcutDisplayHandle`·`KeyboardShortcutDisplayBuilder`, `CoreKbdStyle.separatorTextStyle` 이 예고 없이 제거됐다 — `KeyboardShortcut(keys: k)` → `Kbd(keys: k)`, `spacing: s` → `kbdStyle: CoreKbdStyle(keySeparatorSpacing: s)`, `fromActivator(activator: a)` → `Kbd(keys: kbdKeysFromActivator(a))`(수정키 순서 Ctrl → Alt → ⌘ → Shift 가 Ctrl → Alt → Shift → ⌘ 로 바뀐다); 그대로 치환하면 "+" 가 사라지고 키캡 간격 기본값이 space2 에서 space4 로 바뀌며, `CoreKbdContract` 에 `label` 이 추가되고 Kbd 하나는 접근 이름 하나로 읽힌다.
* **core,figma:** Skeleton 기본값 렌더가 바뀐다 - 맥동 시작 50% -> 70%, rectangular 반경 4 -> 8, text 줄 16 / 간격 8 -> 12 / 12 (세트 높이 64 -> 60). 옛 모양을 지키려면 CoreSkeletonStyle(fromOpacity: CoreOpacity.opacity50, lineHeight: CoreSize.size16, lineSpacing: CoreSpace.space8, borderRadius: CoreBorderRadius.all(CoreRadius.radius4)) 로 덮는다. lineHeight 만 덮던 호출자는 간격이 8 -> 12 라 줄 사이가 4px 넓어진다.

### 기능

* **core,figma:** Skeleton 리디자인 — 맥동 시작 70%, 사각형 반경 8, 텍스트 줄 12 / 간격 12 ([#5408](https://github.com/coco-de/coui/issues/5408)) ([c7fe05d](https://github.com/coco-de/coui/commit/c7fe05da77c0280980bf61185126261f2d06a1d1))
* **core,flutter,web,figma:** Button 리디자인 — secondary 는 container 로, destructive 는 채움으로, link 는 걷어내고 피커 오류는 트리거 스타일로 옮긴다 ([#5486](https://github.com/coco-de/coui/issues/5486)) ([3a1ca62](https://github.com/coco-de/coui/commit/3a1ca6279c01fb04231674cecbe2cee446c85d20))
* **core,flutter,web,figma:** Kbd 키캡을 나란히 놓고 한 이름으로 읽으며 KeyboardShortcut 을 지운다 ([#5473](https://github.com/coco-de/coui/issues/5473)) ([9eab38a](https://github.com/coco-de/coui/commit/9eab38afc10159d4422cbc29e9f068484bdc0951))

## [3.1.0](https://github.com/coco-de/coui/compare/coui_mcp-v3.0.0...coui_mcp-v3.1.0) (2026-09-23)


### 기능

* **lints:** k 접두 · handle 어간 · child 마지막을 CI 가 막는다 ([#5021](https://github.com/coco-de/coui/issues/5021)) ([b786ce1](https://github.com/coco-de/coui/commit/b786ce1795ecc9061dabd4cd156f198af3b117d0))

## [3.0.0](https://github.com/coco-de/coui/compare/coui_mcp-v2.0.1...coui_mcp-v3.0.0) (2026-08-31)


### ⚠ BREAKING CHANGES

* **deps:** #4439 — Flutter 3.47.0 · jaspr 0.23.4 로 툴체인 상향 ([#4440](https://github.com/coco-de/coui/issues/4440))

### 기타

* **deps:** [#4439](https://github.com/coco-de/coui/issues/4439) — Flutter 3.47.0 · jaspr 0.23.4 로 툴체인 상향 ([#4440](https://github.com/coco-de/coui/issues/4440)) ([a033bed](https://github.com/coco-de/coui/commit/a033beda885234867322886211f342e03e93ea41))

## [2.0.1](https://github.com/coco-de/coui/compare/coui_mcp-v2.0.0...coui_mcp-v2.0.1) (2026-08-12)


### 버그 수정

* **coui_mcp:** pub workspace 미등록으로 인한 MCP 서버 부팅 실패 및 리소스 URI 파싱 버그 수정 ([#3782](https://github.com/coco-de/coui/issues/3782)) ([1a241e8](https://github.com/coco-de/coui/commit/1a241e8287a443dd1a31015a0679a57afc510c92))
* **parity:** 문서↔코드 · Flutter↔Web 드리프트 실측 수정 + 게이트 4종 ([#3440](https://github.com/coco-de/coui/issues/3440)) ([3953ef5](https://github.com/coco-de/coui/commit/3953ef58f8d3e60ae07a33db9fe2295077ab3992))
