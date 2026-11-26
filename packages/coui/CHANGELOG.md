# Changelog

## [0.2.0](https://github.com/coco-de/coui/compare/coui-v0.1.1...coui-v0.2.0) (2026-10-07)


### ⚠ BREAKING CHANGES

* **flutter:** iOS · Android 에서 CoUIApp 의 기본 배율이 1.25 에서 1 로 바뀌고 AdaptiveScaling.mobile 이 1 이 되어 scaling: .mobile 을 명시한 앱도 1.25 를 잃는다 — 이전 크기를 유지하려면 CoUIApp(scaling: const AdaptiveScaling(1.25)) 를 넘긴다.

### 기능

* **flutter:** 휴대폰 기본 배율을 1.25 에서 1 로 — AdaptiveScaling.mobile 을 1 로 ([#5316](https://github.com/coco-de/coui/issues/5316)) ([98f161e](https://github.com/coco-de/coui/commit/98f161e839f193962b3625aae0962c1acbebd00e)), closes [#5311](https://github.com/coco-de/coui/issues/5311)

## [0.1.1](https://github.com/coco-de/coui/compare/coui-v0.1.0...coui-v0.1.1) (2026-10-01)


### 버그 수정

* **web:** CoUIWeb·CoUIThemeController 소스 doc 정정 + CSS 없는 테마 이름 30개 deprecate ([#5133](https://github.com/coco-de/coui/issues/5133)) ([ec9c4e0](https://github.com/coco-de/coui/commit/ec9c4e0b574e647d995d42a213f84b4d24bcfa2b))
