# Changelog

## [0.6.0](https://github.com/coco-de/coui/compare/coui_lints-v0.5.0...coui_lints-v0.6.0) (2026-11-17)


### ⚠ BREAKING CHANGES

* **glass:** liquid_glass_widgets 1.17.4 반영 — SwitchField 는 콜백이 없으면 비활성 · Flutter 3.50.0 · Jaspr 0.24 베타 선 상향 ([#6339](https://github.com/coco-de/coui/issues/6339))

### 버그 수정

* **glass:** liquid_glass_widgets 1.17.4 반영 — SwitchField 는 콜백이 없으면 비활성 · Flutter 3.50.0 · Jaspr 0.24 베타 선 상향 ([#6339](https://github.com/coco-de/coui/issues/6339)) ([127e88d](https://github.com/coco-de/coui/commit/127e88df1ae78776ac4f4b60d3cf3ecbf820f93f))

## [0.5.0](https://github.com/coco-de/coui/compare/coui_lints-v0.4.0...coui_lints-v0.5.0) (2026-10-16)


### 기능

* **core,flutter,web:** 밀도 축 — 간격 · 컨트롤 행 높이 · 행의 모서리를 사다리 위에서 한 칸 옮긴다 ([#5426](https://github.com/coco-de/coui/issues/5426)) ([f83b8bc](https://github.com/coco-de/coui/commit/f83b8bcab954add88c97cf5cb19515ddbec2e772))

## [0.4.0](https://github.com/coco-de/coui/compare/coui_lints-v0.3.0...coui_lints-v0.4.0) (2026-09-23)


### 기능

* **lints:** copyWith 가 필드를 빠뜨리면 CI 가 막는다 — avoid_incomplete_copy_with ([#5017](https://github.com/coco-de/coui/issues/5017)) ([1e8bfe2](https://github.com/coco-de/coui/commit/1e8bfe2cb95a5ef74b9eda15137a964c65311406))
* **lints:** k 접두 · handle 어간 · child 마지막을 CI 가 막는다 ([#5021](https://github.com/coco-de/coui/issues/5021)) ([b786ce1](https://github.com/coco-de/coui/commit/b786ce1795ecc9061dabd4cd156f198af3b117d0))

## [0.3.0](https://github.com/coco-de/coui/compare/coui_lints-v0.2.0...coui_lints-v0.3.0) (2026-08-31)


### ⚠ BREAKING CHANGES

* **deps:** #4439 — Flutter 3.47.0 · jaspr 0.23.4 로 툴체인 상향 ([#4440](https://github.com/coco-de/coui/issues/4440))

### 기타

* **deps:** [#4439](https://github.com/coco-de/coui/issues/4439) — Flutter 3.47.0 · jaspr 0.23.4 로 툴체인 상향 ([#4440](https://github.com/coco-de/coui/issues/4440)) ([a033bed](https://github.com/coco-de/coui/commit/a033beda885234867322886211f342e03e93ea41))

## [0.2.0](https://github.com/coco-de/coui/compare/coui_lints-v0.1.0...coui_lints-v0.2.0) (2026-08-12)


### 기능

* **icon:** 출하 컴포넌트를 Lucide 하나로 — 그리고 글리프 정체에 걸린 동작 분리 ([#3419](https://github.com/coco-de/coui/issues/3419)) ([63d7df1](https://github.com/coco-de/coui/commit/63d7df13a73780df19fcb52670649ff02f874149))
* Project [#3294](https://github.com/coco-de/coui/issues/3294) — 디자인 시스템 견고화 (접근성 축 10건 + 서피스 프리셋 축 4건) ([#3349](https://github.com/coco-de/coui/issues/3349)) ([5b6287d](https://github.com/coco-de/coui/commit/5b6287d1c48b73eb208b3838bd94effb9d9b1711))


### 버그 수정

* **docs:** Jaspr 0.23.2 최신화 + CI Flutter 3.44.8 상향 + "On this page" 앵커/스타일 수정 ([#3489](https://github.com/coco-de/coui/issues/3489)) ([87ca07b](https://github.com/coco-de/coui/commit/87ca07be932fb8eb09f63cbe0edd8efc26d0747d))

## 0.1.0

- Initial release. Nine analysis rules mirroring the mechanically-checkable
  parts of `.claude/rules/`:
  - `avoid_framework_import`
  - `prefer_stacks_and_position`
  - `avoid_material_icon_glyph`
  - `prefer_text_chain`
  - `avoid_hardcoded_duration`
  - `avoid_hardcoded_chrome_literal`
  - `avoid_dynamic_event_target`
  - `avoid_override_prefixed_resolved_field`
  - `avoid_local_token_constant`
