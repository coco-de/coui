# Changelog

## [0.11.0](https://github.com/coco-de/coui/compare/coui_i10n-v0.10.0...coui_i10n-v0.11.0) (2026-11-23)


### 기능

* **color-picker:** 트리거를 필드로 그리고 인라인 표시를 더한다 (6508) ([449912d](https://github.com/coco-de/coui/commit/449912dd659547a86343cfa4a162bb432e2fe3d0))

## [0.10.0](https://github.com/coco-de/coui/compare/coui_i10n-v0.9.0...coui_i10n-v0.10.0) (2026-11-11)


### ⚠ BREAKING CHANGES

* **rich-editor:** `CoreRichEditorContract` 에 추상 getter `showSelectionToolbar` 가, `CoUILocalizations`/`CouiLocalizations` 에 `richEditorSelectionToolbar` 가 늘어 이들을 직접 구현한 클래스는 멤버를 추가해야 하고, 기본값이 켬이라 `RichEditor` 는 글자를 선택하면 서식 툴바를 띄운다 — 예전 동작은 `showSelectionToolbar: false`.

### 기능

* **i10n:** 한국어 컴포넌트 문구를 해요체로 맞춘다 ([#6117](https://github.com/coco-de/coui/issues/6117)) ([9a5ea11](https://github.com/coco-de/coui/commit/9a5ea11f7ac657f641e7e9fb64f40aa99cbd4ebc))
* **rich-editor:** 선택 영역 위에 뜨는 서식 툴바 RichEditorSelectionToolbar · showSelectionToolbar (리디자인 PR B) ([#6110](https://github.com/coco-de/coui/issues/6110)) ([7948887](https://github.com/coco-de/coui/commit/79488874f433ccfa4e301faa101ce9421ab1d8cf))


### 버그 수정

* **figma:** 예시 글자 다듬기 — Rich Editor · 입력 세 종 · Avatar 이니셜 · Chat · Banner ([#6140](https://github.com/coco-de/coui/issues/6140)) ([94a1f78](https://github.com/coco-de/coui/commit/94a1f78135f8918bd88fd6cbc84488e4a6d9eabf))

## [0.9.0](https://github.com/coco-de/coui/compare/coui_i10n-v0.8.2...coui_i10n-v0.9.0) (2026-11-09)


### ⚠ BREAKING CHANGES

* **rich-editor:** `CoreRichEditorFormat` 에 `blockType` 값이 늘고 기본 툴바의 첫 그룹이 제목 버튼 셋에서 블록 형식 버튼 하나가 된다 — 이 enum 을 빠짐없이 `switch` 하는 코드는 `blockType` 경우를 더해야 컴파일되고, 제목을 버튼으로 두려면 `toolbar:` 에 `heading1` · `heading2` · `heading3` 를 직접 넣는다. 이미지 버튼 글리프는 `image-plus` 에서 `image` 로 바뀐다.
* **forms:** External implementations of CoreNumberInputContract must provide errorText; custom locale interface implementations must provide calendarPreviousPeriod and calendarNextPeriod. Existing widget constructor calls remain supported.

### 기능

* **forms:** 폼 저작 제약과 오류 상태 개선 ([#6100](https://github.com/coco-de/coui/issues/6100)) ([3b810ad](https://github.com/coco-de/coui/commit/3b810ad2f7ee66e637e80a64706d99c6b65538f1))
* **rich-editor:** 툴바 블록 형식 드롭다운 · 왼쪽 여백 12 · 캔버스 빌더 (리디자인 PR A) ([#6105](https://github.com/coco-de/coui/issues/6105)) ([64a6206](https://github.com/coco-de/coui/commit/64a620641c497ad478922281dc4f21ac50cb575c))

## [0.8.2](https://github.com/coco-de/coui/compare/coui_i10n-v0.8.1...coui_i10n-v0.8.2) (2026-11-04)


### 버그 수정

* **i10n,flutter,web,figma:** 커맨드 푸터의 ↑ ↓ 한 쌍 라벨을 양방향 '이동'(commandMove)으로 바꾼다 ([#6014](https://github.com/coco-de/coui/issues/6014)) ([f397cca](https://github.com/coco-de/coui/commit/f397cca066ffb22a3c17048f83cb5c860aa731cc))

## [0.8.1](https://github.com/coco-de/coui/compare/coui_i10n-v0.8.0...coui_i10n-v0.8.1) (2026-11-04)


### 버그 수정

* **core,flutter,web,figma:** TimePicker 예시 · 구분자, FileInput 문구, ColorPicker 예시 값 ([#5993](https://github.com/coco-de/coui/issues/5993)) ([0c7b23e](https://github.com/coco-de/coui/commit/0c7b23ef8db0448cf31aac6053d13c84a722c395))

## [0.8.0](https://github.com/coco-de/coui/compare/coui_i10n-v0.7.0...coui_i10n-v0.8.0) (2026-11-01)


### ⚠ BREAKING CHANGES

* **core,flutter,web,docs:** CoreRichEditorFormat.shortcut 이 nullable 이 되고 enum 에 heading1–3 · image 가 추가되어, shortcut 을 null 확인 없이 읽는 코드와 이 enum 을 exhaustive switch 하는 코드는 새 값을 처리해야 한다.

### 기능

* **core,flutter,web,docs:** RichEditor — H1–H3 제목과 서버 연동 이미지 업로드 · 삭제 ([#5943](https://github.com/coco-de/coui/issues/5943)) ([538bba5](https://github.com/coco-de/coui/commit/538bba5c3409be160cb489120e08cf0a2d39188d))

## [0.7.0](https://github.com/coco-de/coui/compare/coui_i10n-v0.6.0...coui_i10n-v0.7.0) (2026-11-01)


### 기능

* **core,flutter,web,docs:** RichEditor — 서식 툴바가 붙은 WYSIWYG Markdown 글·댓글 작성기 ([#5871](https://github.com/coco-de/coui/issues/5871)) ([edba9b7](https://github.com/coco-de/coui/commit/edba9b7a0142660b8d036d90e4723b171f7e9f24))

## [0.6.0](https://github.com/coco-de/coui/compare/coui_i10n-v0.5.1...coui_i10n-v0.6.0) (2026-10-28)


### 기능

* **core,flutter,web:** NumberInput 신설 ([#5762](https://github.com/coco-de/coui/issues/5762) 일부) ([260750d](https://github.com/coco-de/coui/commit/260750d0986b4e87cdbb4288bdee96913ebd9221))

## [0.5.1](https://github.com/coco-de/coui/compare/coui_i10n-v0.5.0...coui_i10n-v0.5.1) (2026-10-28)


### 버그 수정

* **dot-indicator:** expose one accessible control per item ([#5743](https://github.com/coco-de/coui/issues/5743)) ([f7f5cc3](https://github.com/coco-de/coui/commit/f7f5cc35556ab59a488b59c2c25ca58995121c90))

## [0.5.0](https://github.com/coco-de/coui/compare/coui_i10n-v0.4.1...coui_i10n-v0.5.0) (2026-10-23)


### 기능

* **core,flutter,web,figma:** CodeSnippet 줄 톤 — lineTones (성공 · 경고 · 오류 줄 띠) ([#5591](https://github.com/coco-de/coui/issues/5591)) ([81f9c04](https://github.com/coco-de/coui/commit/81f9c0462b3af9001333ae4499df19a28cd163c2))
* **core,flutter,web,figma:** Progress 단계형 — segments (STEP n / N 로 나뉜 막대) ([#5584](https://github.com/coco-de/coui/issues/5584)) ([daba164](https://github.com/coco-de/coui/commit/daba1643207ccc09a9f61af81931269c4c1d4d37))
* **core,flutter,web,figma:** 화면 충실도 — 비교 시트 잔여 공백과 플랫폼 결함 (Epic [#5551](https://github.com/coco-de/coui/issues/5551)) ([e3e56a9](https://github.com/coco-de/coui/commit/e3e56a94ae7f8805e3c0bf0af83429d34b54921e))

## [0.4.1](https://github.com/coco-de/coui/compare/coui_i10n-v0.4.0...coui_i10n-v0.4.1) (2026-10-16)


### 버그 수정

* **i10n,tool:** 로컬라이제이션 · chain 산출물 생성기가 대상 디렉터리에 스크래치 파일을 쓰지 않는다 ([#5459](https://github.com/coco-de/coui/issues/5459)) ([6fe9408](https://github.com/coco-de/coui/commit/6fe9408357bf1c86586e6593a067ab4746861af8))
* **i10n:** 커밋된 OpenAI 키를 지우고 번역 스크립트가 OPENAI_API_KEY 를 읽게 한다 ([#5460](https://github.com/coco-de/coui/issues/5460)) ([5263c29](https://github.com/coco-de/coui/commit/5263c29fa1eb6e0b44af267be4eb242808410024))

## [0.4.0](https://github.com/coco-de/coui/compare/coui_i10n-v0.3.0...coui_i10n-v0.4.0) (2026-10-10)


### 기능

* **flutter,web:** 컴포넌트 chrome 11개 언어 — slang 단일 원본 + slang_gpt ([#5354](https://github.com/coco-de/coui/issues/5354)) ([5797ca7](https://github.com/coco-de/coui/commit/5797ca72adeff2f96dd68a0e75f723225002d0dc))

## [0.3.0](https://github.com/coco-de/coui/compare/coui_i10n-v0.2.0...coui_i10n-v0.3.0) (2026-10-03)


### 기능

* **core,flutter,web:** Calendar 에 날짜 마커를 그린다 — 날짜별 점 · 개수 · 접근성 레이블 ([#5258](https://github.com/coco-de/coui/issues/5258)) ([76d3f46](https://github.com/coco-de/coui/commit/76d3f46b655fd86a01802d71859b047d0a6311fd))

## [0.2.0](https://github.com/coco-de/coui/compare/coui_i10n-v0.1.0...coui_i10n-v0.2.0) (2026-08-31)


### ⚠ BREAKING CHANGES

* **deps:** #4439 — Flutter 3.47.0 · jaspr 0.23.4 로 툴체인 상향 ([#4440](https://github.com/coco-de/coui/issues/4440))

### 기타

* **deps:** [#4439](https://github.com/coco-de/coui/issues/4439) — Flutter 3.47.0 · jaspr 0.23.4 로 툴체인 상향 ([#4440](https://github.com/coco-de/coui/issues/4440)) ([a033bed](https://github.com/coco-de/coui/commit/a033beda885234867322886211f342e03e93ea41))

## 0.1.0
