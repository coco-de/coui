Earlier releases are available in the [changelog archive](https://github.com/coco-de/coui/blob/main/docs/changelog/coui_core.md).

## Unreleased

- feat: opt-in adaptive AppBar action rails through Scaffold, shared glass capsules, physical safe-area detection and mixed text/icon groups.

## Unreleased — consumer form authoring

- Add the glass navigation bar's swell to `CoreGlassNavigationMotion`: `swell`, `barScale`, `barSwell` (3 %) and `barSwellGrip`, and `barSwellOrigin` — the point along the bar it grows from, the lens's place mirrored about the middle. The swell rises while the lens is held or still travelling and settles back with one small dip; reduced motion keeps it at rest, and the platform clock runs until it has settled.
- Add `CorePageTransitionStyle`, `CorePageTransitionTheme` and `CoreComponentTheme.pageTransition`: how a new screen arrives and leaves where the platform has no page motion of its own. It rises into place by `slideDistance` while it fades in over `CoreDuration.slow`, and a closed screen sinks while it fades out over `CoreDuration.moderate`; the screen underneath stays put.
- Add `CoreFoldLayout`, `CoreFold`, `CoreFoldState`, `CoreFoldableKind`, `CoreFoldPosture` and `CoreViewportRect`: the one rule both platforms read a foldable's screen by — which folds cross the viewport and split it (a hinge, or anything half open; a seamless screen lying flat reads as one surface, as Flutter's dialog route reads it), the segments, the kind of device (`flip` or `fold`, read from the shape the fold leaves so it holds however the device is turned), how it is held (`flat`, `tabletop`, `book`), and the segment a panel with no anchor opens in.
- Add `CoreIndexedSwitcherStyle`, `CoreIndexedSwitcherTheme`, `CoreIndexedSwitcherContract` and the `CoreComponentTheme.indexedSwitcher` slot — the fade-through timing of the new `IndexedSwitcher`: the outgoing view fades out over `CoreDuration.instant` on `CoreEasing.exit`, then the incoming one fades in over `CoreDuration.normal` on `CoreEasing.enter`.
- Add `CoreStrokeWidth.activeBoundaryAt` and `CoreSurfaceGeometryConstraint.activeBoundary`, folded by `atDevicePixelRatio` beside the hairline: below a 2x screen the active boundary (`stroke1_5`) draws one pixel wide, as Chrome already drew it, and from 2x up at its own 1.5 (#6131).
- Add `CssVariableGenerator.lineHeightCss`, `roundToPixelCss`, `inheritedLineHeightCss` and `leadingVar` — the whole-pixel line box the Web draws to match Flutter's engine, and the multiplier it hands down (#6131).
- Add `CoreStrokeWidth.hairlineAt` and `CoreSurfaceGeometryConstraint.hairline` / `atDevicePixelRatio`: the hairline step draws one pixel wide below a 2x screen on both platforms, as the Web's `--coui-stroke-width-0_5` already did (#6131).
- Add the optional `NumberInput.errorText` contract so validation messages are distinct from normal descriptions.

## [0.192.0](https://github.com/coco-de/coui/compare/coui_core-v0.191.0...coui_core-v0.192.0) (2026-11-24)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** `Fieldset` 의 기본 모양이 채운 패널(`filled`)로 바뀌고(모서리 24→16, 테두리 `outline`→`outline-subtle`, 필드 사이 24→16, 범례 가로 여백 8→0), `CoreFieldsetContract` 에 `description` · `variant` getter 가 더해져 계약을 직접 구현하는 코드는 둘을 구현해야 한다.

### 기능

* **core,figma:** Window 스냅 바 · 칸 · 미리보기를 리디자인 사본대로 ([#6646](https://github.com/coco-de/coui/issues/6646)) ([1d82058](https://github.com/coco-de/coui/commit/1d820587ce435f38bb5c7556c8c712a75a13bdce))
* **core,flutter,web,figma:** Fieldset 변형(filled · outlined · plain) · 설명 줄 · 필드 간격 16 · 모서리 16 ([#6668](https://github.com/coco-de/coui/issues/6668)) ([4f26cfb](https://github.com/coco-de/coui/commit/4f26cfb5111e80812e9d891ad8b4d87429dc1ef5))
* **core,flutter,web,figma:** WindowPanel 기본 모양을 리디자인 사본에 맞춘다 ([#6641](https://github.com/coco-de/coui/issues/6641)) ([8d08756](https://github.com/coco-de/coui/commit/8d08756e8e4fd18788a9f7a429450c801d2d1e8d))
* **core:** PageHeader 제목과 행동 사이를 16 으로 넓힌다 ([#6644](https://github.com/coco-de/coui/issues/6644)) ([f63d0f1](https://github.com/coco-de/coui/commit/f63d0f10bd66294ad97954fc37d4ce0925a18391))
* **dialog:** 패널 폭 560 · 280 과 barrier 딤 opacity/scrim 연결 ([#6664](https://github.com/coco-de/coui/issues/6664)) ([f542b35](https://github.com/coco-de/coui/commit/f542b358b694cea2e62430e77e00bfb2e340b0b8))


### 버그 수정

* **core,figma:** WindowPanel 닫기 × 의 평소 색을 리디자인 사본대로 surface-variant 로 ([#6663](https://github.com/coco-de/coui/issues/6663)) ([3c91379](https://github.com/coco-de/coui/commit/3c9137952b5a7d8f041908b048a97b0edb726c7f))
* **guards:** scaffold 앱 바 레일 팝업 스타일이 만든 가드 실패 두 건을 닫는다 ([#6672](https://github.com/coco-de/coui/issues/6672)) ([eae925f](https://github.com/coco-de/coui/commit/eae925fe10f798500009d78623372d675825a772))

## [0.191.0](https://github.com/coco-de/coui/compare/coui_core-v0.190.1...coui_core-v0.191.0) (2026-11-23)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** Stepper 의 현재 단계 원이 indicatorActiveColor 가 아니라 indicatorCurrentColor · indicatorCurrentBorderColor 를 읽고 (기본 surface 채움 + primary 테두리, 번호는 onSurface), connectorMargin · connectorMarginVertical 기본값이 8 · 4 에서 0 으로 바뀐다 — 가로 연결선은 이제 원 양옆의 반쪽 선이라 connectorMargin 은 원과 반쪽 선 사이 여백을 뜻한다. 기존에 indicatorActiveColor 로 현재 단계 채움을 바꿨다면 indicatorCurrentColor 로 옮긴다.
* **core,figma:** Checkbox 의 미선택 박스 테두리와 RadioGroup 의 쉬는 고리가 모든 크기(카드 변형 포함, 비활성 포함)에서 1px 로 그려진다(이전 1.5, RadioGroup xl · xl2 는 2) — 이전 굵기가 필요하면 CoreCheckboxStyle(boxBorderWidth: CoreStrokeWidth.stroke1_5) · CoreRadioGroupStyle(indicatorBorderWidth: …) 로 적는다.
* **phone-input:** initialCountry 와 initialValue 를 적지 않은 PhoneInput 은 대한민국(+82)으로 시작하고, onChanged · 폼 값의 국가 번호도 +82 로 보고된다(예: 5551234567 → +825551234567). 미국을 기본으로 쓰던 앱은 initialCountry: CoreCountry.unitedStates 를 넘긴다.

### 기능

* **app-bar:** adapt glass actions to a foldable right control rail ([#6483](https://github.com/coco-de/coui/issues/6483)) ([5761caa](https://github.com/coco-de/coui/commit/5761caaf6b17bb2801b87e25928c2a87d156ec3f))
* **banner:** 좁으면 버튼 줄을 다음 줄로 내리고 제목을 Medium 으로 둔다 ([#6484](https://github.com/coco-de/coui/issues/6484)) ([cade0e4](https://github.com/coco-de/coui/commit/cade0e4f0561033cb5d54f2c7f6aeb489d9756f4))
* **calendar:** 오늘을 시계에서 읽고 파리티 캡처는 고정한 날짜로 찍는다 ([#6539](https://github.com/coco-de/coui/issues/6539)) ([8f7c5d7](https://github.com/coco-de/coui/commit/8f7c5d755d3a7ec1ac1d424b99ead1e45141a7e8))
* **card-image:** 카드를 테두리 있는 상자로 감싸고 이미지 틀을 각지게 한다 (6503) ([f24d9d7](https://github.com/coco-de/coui/commit/f24d9d7845d3d376880bb5a0207ce8d7a35e1611))
* **chip-group:** 머리를 제목 · 안내 두 줄로 두고 캔버스의 흐림이 칩을 가리지 않게 한다 (6489) ([c136e5b](https://github.com/coco-de/coui/commit/c136e5b8cf2db4ef901e2d8e47a58151ac4ac96e))
* **color-picker:** 트리거를 필드로 그리고 인라인 표시를 더한다 (6508) ([449912d](https://github.com/coco-de/coui/commit/449912dd659547a86343cfa4a162bb432e2fe3d0))
* **command:** 행 여백 · 아이콘 색을 다시 정하고 대화상자 검색 줄에 Esc 키캡을 둔다 (6501) ([a4952fa](https://github.com/coco-de/coui/commit/a4952fa68b64f73b88b59c2268715a309ace4c80))
* **core,figma:** Checkbox · RadioGroup 미선택 테두리를 모든 크기에서 1 로 ([#6551](https://github.com/coco-de/coui/issues/6551)) ([a4416e4](https://github.com/coco-de/coui/commit/a4416e4db9fc0f0748851abd7eed9efaaf4f3e62))
* **core,figma:** StarRating · Star 켜진 별을 primary, 빈 별을 outline-variant 로 ([#6569](https://github.com/coco-de/coui/issues/6569)) ([b1bafe7](https://github.com/coco-de/coui/commit/b1bafe7f7834ea8919ed7229663dcf39ce3fd389))
* **core,flutter,web,figma:** BottomActionBar 에 summaryCompact 배치를 더한다 ([#6589](https://github.com/coco-de/coui/issues/6589)) ([bebf375](https://github.com/coco-de/coui/commit/bebf375ad038e674a58f1f3ffeb753157cfb3664))
* **core,flutter,web,figma:** Link 에 leading · trailing 아이콘 슬롯을 더한다 ([#6595](https://github.com/coco-de/coui/issues/6595)) ([3c9a052](https://github.com/coco-de/coui/commit/3c9a05271657b9e29d68d604582a462b5d8cb537))
* **core,flutter,web,figma:** Menubar 바 · 트리거를 리디자인에 맞춘다 ([#6570](https://github.com/coco-de/coui/issues/6570)) ([b7567dd](https://github.com/coco-de/coui/commit/b7567dd036adba08e4b7675fd451dabb825270a4))
* **core,flutter,web,figma:** PageHeader 의 행동을 제목 줄로 옮긴다 ([#6597](https://github.com/coco-de/coui/issues/6597)) ([8c6c3a8](https://github.com/coco-de/coui/commit/8c6c3a8e183fd8cb55299fa69f94b56ddf1e4cc5))
* **core,flutter,web,figma:** Stepper 현재 단계를 surface 원 + primary 테두리로, 가로는 같은 폭 칸과 반쪽 연결선으로 ([#6571](https://github.com/coco-de/coui/issues/6571)) ([2e32f8c](https://github.com/coco-de/coui/commit/2e32f8cc6203c89d27b2f2994fa454aef8101c77))
* **core,flutter,web:** 서랍 · 토스트 · 팝오버가 접힘선을 넘지 않는다 ([#6605](https://github.com/coco-de/coui/issues/6605)) ([30e1f6f](https://github.com/coco-de/coui/commit/30e1f6f33621e86159f219ba29ee46e2c203c360)), closes [#6602](https://github.com/coco-de/coui/issues/6602)
* **core,flutter,web:** Join 기본 반경 10 · 입력 + 버튼 예제 · 이음매 1px ([#6586](https://github.com/coco-de/coui/issues/6586)) ([89e3e0f](https://github.com/coco-de/coui/commit/89e3e0facc88d2cc9d21e0fa1f5da7efe2bebdba))
* **core:** 모달 배경막을 30% 로 옅게 한다 ([#6585](https://github.com/coco-de/coui/issues/6585)) ([b6e4711](https://github.com/coco-de/coui/commit/b6e471154b0aba2d2a1a8ba8e0641d065745ea90))
* **description-card:** 크기마다 여백 · 모서리 · 행 간격을 두고 enabled 를 더한다 (6500) ([55baaf1](https://github.com/coco-de/coui/commit/55baaf1a12359b51753e0c7bda7aed83e4a9c16d))
* **dock:** 막대를 둥근 판으로 그리고 앱 칸을 가운데로 모은다 (6506) ([3dc4b90](https://github.com/coco-de/coui/commit/3dc4b90a7c350c1b1d83bc175801cb7d75697b80))
* **empty-state:** compact 를 패널 안의 빈 자리답게 조인다 ([#6480](https://github.com/coco-de/coui/issues/6480)) ([704346f](https://github.com/coco-de/coui/commit/704346fc79b45345a7cbb5323a4442893d333931))
* **input-otp:** 칸에 커서를 두고 빈 칸과 채운 칸을 바탕 · 테두리로 가른다 (6495) ([9f66a2b](https://github.com/coco-de/coui/commit/9f66a2bb95eb551ca39ab195fcb881f8f1936175))
* **mockup:** 접힘 각도를 조절하는 MockupFoldable 을 추가한다 ([#6510](https://github.com/coco-de/coui/issues/6510)) ([666ac00](https://github.com/coco-de/coui/commit/666ac00da3eccbb1a32131578428ff9ed7dbc949))
* **option-item:** 선택 항목을 테두리 있는 카드로 그린다 ([#6485](https://github.com/coco-de/coui/issues/6485)) ([93285d6](https://github.com/coco-de/coui/commit/93285d656d3a85f060810e9031a9785974950240))
* **phone-input:** 기본 국가를 대한민국(+82)으로 바꾼다 ([#6494](https://github.com/coco-de/coui/issues/6494)) ([70e3ccd](https://github.com/coco-de/coui/commit/70e3ccd81ea323cb484b5e2dd922e8cd1421a3b9))
* **tracker:** 정상 구간은 옅게, 구간 사이는 4 로 띄운다 ([#6477](https://github.com/coco-de/coui/issues/6477)) ([57ca4d9](https://github.com/coco-de/coui/commit/57ca4d98a842627b6953c1bcc995d03938d55530))


### 버그 수정

* **core,web,figma,docs:** main 의 CI 가드와 테스트를 다시 초록으로 맞춘다 ([#6509](https://github.com/coco-de/coui/issues/6509)) ([882f71c](https://github.com/coco-de/coui/commit/882f71c53aaaf18aa00dd3a4c551b4888e337776))
* **navigation-bar:** follow only visible outer content scrolling ([#6478](https://github.com/coco-de/coui/issues/6478)) ([5efd1ca](https://github.com/coco-de/coui/commit/5efd1cafb94979c96af9896aee8de4ffaa7413b5))
* **scaffold:** align adaptive app-bar rails with iPhone Duo ([#6599](https://github.com/coco-de/coui/issues/6599)) ([35786c4](https://github.com/coco-de/coui/commit/35786c4fedce22e45ea6d14f6b85ae1d03999ebb))


### 문서

* 문서 시안 반영 뒤 남은 죽은 코드와 사실 오류를 정리한다 ([#6598](https://github.com/coco-de/coui/issues/6598)) ([b57e9d5](https://github.com/coco-de/coui/commit/b57e9d5830cafdb0e6259a73b71a3541146db473))
* Blocks · Resources 페이지를 시안의 구성과 글로 바꾼다 ([#6564](https://github.com/coco-de/coui/issues/6564)) ([6466762](https://github.com/coco-de/coui/commit/64667625086a8bd11ba2a659985e3500550ecb83))

## [0.190.1](https://github.com/coco-de/coui/compare/coui_core-v0.190.0...coui_core-v0.190.1) (2026-11-19)


### 버그 수정

* **icon:** [#6436](https://github.com/coco-de/coui/issues/6436) preserve Iconify JSON transformations ([#6437](https://github.com/coco-de/coui/issues/6437)) ([f27dc73](https://github.com/coco-de/coui/commit/f27dc733a85fb1af499112a4ebf8affab58674f9))
* **web:** FormLabel·ValidatorHint 간격을 RTL에서도 유지한다 ([#6423](https://github.com/coco-de/coui/issues/6423)) ([314bd93](https://github.com/coco-de/coui/commit/314bd9321cb56ee7e5dbea741741ef8cbbf74df9))

## [0.190.0](https://github.com/coco-de/coui/compare/coui_core-v0.189.0...coui_core-v0.190.0) (2026-11-18)


### 기능

* **navigation-bar:** 하단 바 항목은 96 까지만 늘어나고 남는 폭은 가운데로 모은다 ([#6410](https://github.com/coco-de/coui/issues/6410)) ([e2d2dbf](https://github.com/coco-de/coui/commit/e2d2dbf21ab7e6ae3c05389f11b271dc7ef39889))

## [0.189.0](https://github.com/coco-de/coui/compare/coui_core-v0.188.0...coui_core-v0.189.0) (2026-11-18)


### 기능

* **core,flutter,web:** 본문을 스크롤하면 떠 있는 내비게이션 바가 줄어든다 ([#6400](https://github.com/coco-de/coui/issues/6400)) ([5889bb7](https://github.com/coco-de/coui/commit/5889bb76383b8cee2c0a1c23a6b046d5a4e60747))
* **navigation-bar:** 하단 바(Indicator=color)는 면 없이 색과 굵기로만 선택을 표시한다 ([#6397](https://github.com/coco-de/coui/issues/6397)) ([329f9ea](https://github.com/coco-de/coui/commit/329f9ea83de4c17be99b9b24e9fbfa4d817ba538))


### 버그 수정

* **web:** honor existing duration and disabled-color styles ([#6391](https://github.com/coco-de/coui/issues/6391)) ([0b4c49d](https://github.com/coco-de/coui/commit/0b4c49d10969a9daa6028753222c2678e8f6beca))

## [0.188.0](https://github.com/coco-de/coui/compare/coui_core-v0.187.0...coui_core-v0.188.0) (2026-11-18)


### 기능

* **navigation-bar:** 구분선을 연하게, 선택 표시를 항목 전체 네모로 ([#6384](https://github.com/coco-de/coui/issues/6384)) ([2bca2b7](https://github.com/coco-de/coui/commit/2bca2b7a45b43cbed74cbad88d38d1c62951dcfb))

## [0.187.0](https://github.com/coco-de/coui/compare/coui_core-v0.186.0...coui_core-v0.187.0) (2026-11-18)


### 기능

* **core,flutter,web:** 접히는 화면을 두 플랫폼에서 읽고 flip · fold 를 구분한다 ([#6381](https://github.com/coco-de/coui/issues/6381)) ([220c153](https://github.com/coco-de/coui/commit/220c15370a66c44f53d6747d04c1df018074192c))
* **flutter,web:** 리퀴드 글래스 바가 렌즈를 든 동안 캡슐째 부풀고, 유리 대화상자 그림자를 박스 밖에 칠한다 ([#6378](https://github.com/coco-de/coui/issues/6378)) ([6a755a0](https://github.com/coco-de/coui/commit/6a755a02b1ccf104847c7d9371e0524b5f867802))
* **flutter,web:** 새 화면이 열리고 닫힐 때 화면 전환 모션을 넣는다 ([#6373](https://github.com/coco-de/coui/issues/6373)) ([245f3c5](https://github.com/coco-de/coui/commit/245f3c5e8b385387f9b59ae6cffa6dcc625c0508))

## [0.186.0](https://github.com/coco-de/coui/compare/coui_core-v0.185.0...coui_core-v0.186.0) (2026-11-17)


### 기능

* **flutter,web:** 바의 동작을 옆 자리로 나누는 actionsAxis · BarAction 을 추가하고 세로 그룹 아이콘과 레일 툴팁을 맞춘다 ([#6368](https://github.com/coco-de/coui/issues/6368)) ([7d491be](https://github.com/coco-de/coui/commit/7d491be2901b493884259c0601c82f3bfbe03504))
* **flutter,web:** go_router 셸 브랜치 전환에 모션을 주는 IndexedSwitcher 를 더한다 ([#6369](https://github.com/coco-de/coui/issues/6369)) ([da560c1](https://github.com/coco-de/coui/commit/da560c1d9e4a1b02c4c7e61401e063dfa69ba7c9))

## [0.185.0](https://github.com/coco-de/coui/compare/coui_core-v0.184.1...coui_core-v0.185.0) (2026-11-17)


### ⚠ BREAKING CHANGES

* **flutter,web:** 리퀴드 글래스 아래의 `NavigationBar(mode: rail)` 이 화면 가장자리에 붙은 판이 아니라 둘레 여백 8 의 떠 있는 캡슐로 그려지고, 라벨을 숨기며(`labelMode` 기본값 `none`), 아이콘 뒤 알약 대신 렌즈로 선택을 표시한다(`indicator` 기본값 `color`). 라벨과 알약은 `labelMode: .all` · `indicator: .fill` 을 직접 주면 돌아온다. 붙은 판 모양으로 되돌리는 값은 없고, 그 바에만 `navigationBarStyle.surfaceStyle: .defaultStyle` 을 주면 유리 재질 없이 붙은 레일로 그려진다.

### 기능

* **flutter,web:** 리퀴드 글래스 레일을 세로 탭 바 캡슐로 그리고 ToolbarGroup 에 세로 방향을 추가한다 ([#6359](https://github.com/coco-de/coui/issues/6359)) ([ef3c25d](https://github.com/coco-de/coui/commit/ef3c25d58d321353df73c3fa8a59040402bb7e6b))

## [0.184.1](https://github.com/coco-de/coui/compare/coui_core-v0.184.0...coui_core-v0.184.1) (2026-11-17)


### 버그 수정

* 1배 화면에서 1.5px 선(꺼진 체크박스 · 라디오 틀)을 두 플랫폼 모두 1px 로 그린다 ([#6351](https://github.com/coco-de/coui/issues/6351)) ([db1917e](https://github.com/coco-de/coui/commit/db1917e88cda4bb8b7d19407441b04e597711bc6))

## [0.184.0](https://github.com/coco-de/coui/compare/coui_core-v0.183.3...coui_core-v0.184.0) (2026-11-17)


### ⚠ BREAKING CHANGES

* **glass:** liquid_glass_widgets 1.17.4 반영 — SwitchField 는 콜백이 없으면 비활성 · Flutter 3.50.0 · Jaspr 0.24 베타 선 상향 ([#6339](https://github.com/coco-de/coui/issues/6339))

### 버그 수정

* 파리티 공통 계약 복구와 Loading 주기 갱신 ([#6343](https://github.com/coco-de/coui/issues/6343)) ([6db2278](https://github.com/coco-de/coui/commit/6db2278fdd5a8178502207a7bb8b7cd03f29bc7f))
* **core:** 경고 배경(warning/100) 채도를 다른 상태 배경에 맞춤 ([#6340](https://github.com/coco-de/coui/issues/6340)) ([8d1831f](https://github.com/coco-de/coui/commit/8d1831f8e462c77da20aa49c665f6fda25a909c9))
* **glass:** liquid_glass_widgets 1.17.4 반영 — SwitchField 는 콜백이 없으면 비활성 · Flutter 3.50.0 · Jaspr 0.24 베타 선 상향 ([#6339](https://github.com/coco-de/coui/issues/6339)) ([127e88d](https://github.com/coco-de/coui/commit/127e88df1ae78776ac4f4b60d3cf3ecbf820f93f))

## [0.183.3](https://github.com/coco-de/coui/compare/coui_core-v0.183.2...coui_core-v0.183.3) (2026-11-17)


### 버그 수정

* **flutter:** 1배 화면의 가는 선을 Web 처럼 1px 로 그린다 ([#6337](https://github.com/coco-de/coui/issues/6337)) ([91421d5](https://github.com/coco-de/coui/commit/91421d512acf292b5eb04a7646c47f844008dcd3))
* **web:** 글줄 상자를 Flutter 처럼 정수 픽셀로 그린다 ([#6336](https://github.com/coco-de/coui/issues/6336)) ([7819bc1](https://github.com/coco-de/coui/commit/7819bc1209f4c0e0c6614b782cffc9cec355a29b))

## [0.183.2](https://github.com/coco-de/coui/compare/coui_core-v0.183.1...coui_core-v0.183.2) (2026-11-16)


### 버그 수정

* **core:** 한 플랫폼만 읽던 Style 값을 두 플랫폼이 같이 읽는다 ([#6325](https://github.com/coco-de/coui/issues/6325)) ([1765df9](https://github.com/coco-de/coui/commit/1765df948ccc01e12f75020911bdd856fa176655)), closes [#6323](https://github.com/coco-de/coui/issues/6323)

## [0.183.1](https://github.com/coco-de/coui/compare/coui_core-v0.183.0...coui_core-v0.183.1) (2026-11-16)


### 문서

* **core:** Style 필드 표를 킷을 쓰는 사람의 말로 쓴다 ([#6321](https://github.com/coco-de/coui/issues/6321)) ([98a404a](https://github.com/coco-de/coui/commit/98a404ae6e4f50810a72a600f72f47256147ed13)), closes [#6317](https://github.com/coco-de/coui/issues/6317) [#6316](https://github.com/coco-de/coui/issues/6316)

## [0.183.0](https://github.com/coco-de/coui/compare/coui_core-v0.182.0...coui_core-v0.183.0) (2026-11-16)


### 기능

* **core,flutter,web:** Web CodeSnippet 이 JSON · YAML · SQL 을 Flutter 와 같은 문법으로 칠한다 ([#6309](https://github.com/coco-de/coui/issues/6309)) ([9c6a167](https://github.com/coco-de/coui/commit/9c6a16709231cdc2da494b67728c27315f712f5f))

## [0.182.0](https://github.com/coco-de/coui/compare/coui_core-v0.181.0...coui_core-v0.182.0) (2026-11-13)


### 기능

* **core:** Tabs underline 바탕선을 outlineSubtle 로 ([#6299](https://github.com/coco-de/coui/issues/6299)) ([6df0835](https://github.com/coco-de/coui/commit/6df08354e07007935b8a115a0669069fa608eb06))
* **core:** Toggle 꺼짐 핸들을 흰색으로, 핸들에 연한 기본 그림자 ([#6286](https://github.com/coco-de/coui/issues/6286)) ([15b87c1](https://github.com/coco-de/coui/commit/15b87c1f47b78148bd3dc52e73e645aa82d4615b))
* **core:** Toggle 비활성 꺼짐 핸들도 흰색으로 ([#6295](https://github.com/coco-de/coui/issues/6295)) ([1e129bb](https://github.com/coco-de/coui/commit/1e129bb552514954cc1b34af2f164655d3fcd2ed))
* **flutter,web:** AppBar 가운데 제목을 양옆 같은 폭 사이 바 가운데에 둔다 ([#6301](https://github.com/coco-de/coui/issues/6301)) ([e3ab376](https://github.com/coco-de/coui/commit/e3ab376d333ad5c8364e7021e9daad6d41c61a23))


### 버그 수정

* **flutter,web:** defer scrollbar layout reports and repair Web geometry guards ([#6270](https://github.com/coco-de/coui/issues/6270)) ([b4f24d2](https://github.com/coco-de/coui/commit/b4f24d2fde9a1519cd927da9954e6f30470ad5b0)), closes [#6268](https://github.com/coco-de/coui/issues/6268)
* **time-picker:** 세그먼트 숫자를 headlineMedium 으로 줄이고 텍스트 스타일을 붙인다 ([#6262](https://github.com/coco-de/coui/issues/6262)) ([a0752eb](https://github.com/coco-de/coui/commit/a0752eb3d972b20616b4c3ccc4f9029b42cac57a))

## [0.181.0](https://github.com/coco-de/coui/compare/coui_core-v0.180.0...coui_core-v0.181.0) (2026-11-12)


### 기능

* **banner:** 상태 면 위 버튼의 상태 레이어를 버튼 모양으로 넓힌다 ([#6235](https://github.com/coco-de/coui/issues/6235)) ([daec939](https://github.com/coco-de/coui/commit/daec93939427286adfbf30493efdfab5289a50ef))
* **core:** 고대비 모드에서 옮긴 선택 면의 글자는 7:1 을 지킨다 ([#6237](https://github.com/coco-de/coui/issues/6237)) ([646be3f](https://github.com/coco-de/coui/commit/646be3f62b6751903b240db295ec2c814f6003ef))
* **core:** 미라클 알람 브랜드를 추가하고 브랜드가 Light 버튼 글자색을 진술할 수 있게 한다 ([#6251](https://github.com/coco-de/coui/issues/6251)) ([b8e7248](https://github.com/coco-de/coui/commit/b8e7248c7d57f045391b6478695786de9e3a83c1))
* **core:** 브랜드 색 하나로 브랜드를 만든다 ([#6233](https://github.com/coco-de/coui/issues/6233)) ([b49cfb6](https://github.com/coco-de/coui/commit/b49cfb6bc3e34b701f1f34bfd03eff4a6e561fc4))


### 버그 수정

* **banner,toast:** 닫기 x 글리프를 md 정사각 버튼의 18 로 맞춘다 ([#6257](https://github.com/coco-de/coui/issues/6257)) ([faba2a7](https://github.com/coco-de/coui/commit/faba2a732bdf2904ed38cfd2d43b4ad45f024450))
* **banner,toast:** 액션 여백 plain 전용 · Toast 닫기 40 원 · 정사각 닫기 글리프 ✓→✕ ([#6246](https://github.com/coco-de/coui/issues/6246)) ([69ad40d](https://github.com/coco-de/coui/commit/69ad40dc48d4928c48d888a081c4f6df8e64c626))
* **core,flutter,web,figma:** SidebarItem 비활성 행의 trailing 글리프가 비활성 색을 따른다 (Part of [#6008](https://github.com/coco-de/coui/issues/6008)) ([#6230](https://github.com/coco-de/coui/issues/6230)) ([ffc44c7](https://github.com/coco-de/coui/commit/ffc44c77953fb2585fb269d56b130643362fef02))
* **toast:** 닫기 버튼을 토스트 높이의 가운데에 놓는다 ([#6249](https://github.com/coco-de/coui/issues/6249)) ([49079fb](https://github.com/coco-de/coui/commit/49079fbd9958a9d2d973918d343ffef67f49093d))

## [0.180.0](https://github.com/coco-de/coui/compare/coui_core-v0.179.0...coui_core-v0.180.0) (2026-11-11)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** CouiSuccessRamp 와 CouiSuccessRamp.s450, Web 변수 --coui-success-450, Figma color/coui/success/450 을 deprecation 없이 삭제한다 — CouiPalette.success 는 CouiStatusRamp 이고 450 을 읽던 곳은 success.s400 을 읽는다(새 400 과 같은 자리). 네 상태 램프의 모든 단계 값도 바뀐다.
* **rich-editor:** `CoreRichEditorContract` 에 추상 getter `showSelectionToolbar` 가, `CoUILocalizations`/`CouiLocalizations` 에 `richEditorSelectionToolbar` 가 늘어 이들을 직접 구현한 클래스는 멤버를 추가해야 하고, 기본값이 켬이라 `RichEditor` 는 글자를 선택하면 서식 툴바를 띄운다 — 예전 동작은 `showSelectionToolbar: false`.

### 기능

* **button:** 상태 면 위 plain 버튼에 상태 레이어를 실어 hover 를 보인다 ([#6222](https://github.com/coco-de/coui/issues/6222)) ([d494fb6](https://github.com/coco-de/coui/commit/d494fb65cc1cda5dca284d08060c0c6b8d57e5c1))
* **core,figma:** 브랜드 확장 컬렉션 통일 — 코드 브랜드가 정본 (Part of [#6118](https://github.com/coco-de/coui/issues/6118)) ([#6150](https://github.com/coco-de/coui/issues/6150)) ([a10d8f3](https://github.com/coco-de/coui/commit/a10d8f39fe850e627ce0cf31b621e40d653049bd))
* **core,figma:** 아이콘 슬롯 색을 콘텐츠 컬렉션 모드로 — 바꿔 넣어도 상태를 따라간다 (Part of [#6008](https://github.com/coco-de/coui/issues/6008)) ([#6158](https://github.com/coco-de/coui/issues/6158)) ([147326c](https://github.com/coco-de/coui/commit/147326cea7cc605d33e286aa8650a1dd87dcbfa2))
* **core,figma:** 표준 매핑의 선택 면이 바탕에서 최소 간격을 지킨다 ([#6205](https://github.com/coco-de/coui/issues/6205)) ([82e1308](https://github.com/coco-de/coui/commit/82e130806283ef04f62a6aa1497d9e2bbd570522))
* **core,flutter,web,docs:** Filter 폭 채우기(fillWidth) — 트랙이 부모 폭을 채우고 칸이 그 폭을 똑같이 나눈다 ([#6156](https://github.com/coco-de/coui/issues/6156)) ([824a4ae](https://github.com/coco-de/coui/commit/824a4ae887b566db501f808ad67227ae1661a7ce)), closes [#6155](https://github.com/coco-de/coui/issues/6155)
* **core,flutter,web,figma:** 도크 위쪽 구분선 굵기를 Style 필드 borderWidth 로 올리고 Web 이 그 폭을 띠에 알린다 ([#6165](https://github.com/coco-de/coui/issues/6165)) ([#6206](https://github.com/coco-de/coui/issues/6206)) ([706bee3](https://github.com/coco-de/coui/commit/706bee382380b776fef4ec46ec1aa8f8119e3c68))
* **core,flutter,web,figma:** 상태색 램프 개편 — 네 램프 11 단계, success/450 삭제 (Part of [#6028](https://github.com/coco-de/coui/issues/6028)) ([#6149](https://github.com/coco-de/coui/issues/6149)) ([48fcbba](https://github.com/coco-de/coui/commit/48fcbba295ec3c7b19c0a879b9b440f928a19704))
* **core,flutter,web,figma:** RichEditor 목록 들여쓰기를 Style 필드 listIndent 로 올린다 ([#6169](https://github.com/coco-de/coui/issues/6169)) ([5c62444](https://github.com/coco-de/coui/commit/5c6244414d2be6d9fda7997ea79f1522f711b188)), closes [#6164](https://github.com/coco-de/coui/issues/6164)
* **core,flutter,web,figma:** TimePicker 편집 칸에 안쪽 테두리를 두고 FileInput 끌어다 놓기 테두리를 실선으로 그린다 ([#6208](https://github.com/coco-de/coui/issues/6208)) ([68db01a](https://github.com/coco-de/coui/commit/68db01aabfa662d4fa1f99e43f8f180b1f114b5b))
* **core:** CoUI 기본 팔레트를 무채색 neutral 로 — primary 프리미티브 제거 ([#6143](https://github.com/coco-de/coui/issues/6143)) ([b982b93](https://github.com/coco-de/coui/commit/b982b932a6c4a9975c66ec993ecd7879df205e30))
* **figma:** 캔버스 예시 글자를 디자이너 확정 대조표대로 한국어로 ([#6120](https://github.com/coco-de/coui/issues/6120)) ([8bbf118](https://github.com/coco-de/coui/commit/8bbf1184e6ee8531aa6306e64da723b896608d29))
* **rich-editor:** 선택 영역 위에 뜨는 서식 툴바 RichEditorSelectionToolbar · showSelectionToolbar (리디자인 PR B) ([#6110](https://github.com/coco-de/coui/issues/6110)) ([7948887](https://github.com/coco-de/coui/commit/79488874f433ccfa4e301faa101ce9421ab1d8cf))


### 버그 수정

* **core,figma:** 아이콘에 쓰인 테두리 토큰 둘을 콘텐츠 토큰으로 바로잡는다 (Part of [#6008](https://github.com/coco-de/coui/issues/6008)) ([#6192](https://github.com/coco-de/coui/issues/6192)) ([9b8a134](https://github.com/coco-de/coui/commit/9b8a134ee5e5d3aa80aa687861dafa292b7eca1c))
* **core,flutter,web,figma,docs:** main 의 깨진 CI 가드와 테스트를 모두 초록으로 되돌린다 ([#6147](https://github.com/coco-de/coui/issues/6147)) ([cdc824e](https://github.com/coco-de/coui/commit/cdc824ec78a88f33c4820fc39f01a284139895f8))
* **core,flutter,web:** 눌림 가능한 CardImage 의 안쪽 여백·화살표를 Web 과 같게 맞춘다 ([#6129](https://github.com/coco-de/coui/issues/6129)) ([#6146](https://github.com/coco-de/coui/issues/6146)) ([00fd2d5](https://github.com/coco-de/coui/commit/00fd2d56450007f885a2b16b8b7e6ebbdb24d55f))
* **core,flutter,web:** ChipInput 입력 필드가 Web 처럼 자기 줄의 남는 폭을 채운다 ([#6136](https://github.com/coco-de/coui/issues/6136)) ([7250c70](https://github.com/coco-de/coui/commit/7250c707eeaa4b7bb2894e322f8766e6399910ce))
* **core,flutter,web:** TextField · TextArea 의 바깥 포커스 링이 마우스로 누른 포커스에는 뜨지 않게 한다 ([#6119](https://github.com/coco-de/coui/issues/6119)) ([ca82ec0](https://github.com/coco-de/coui/commit/ca82ec029e6f0af83f0061cb00ffcf23b1de592b)), closes [#6116](https://github.com/coco-de/coui/issues/6116)
* **core:** ChipInput 에 포커스해도 안쪽 입력 칸 둘레에 상자가 그려지지 않는다 ([#6138](https://github.com/coco-de/coui/issues/6138)) ([#6139](https://github.com/coco-de/coui/issues/6139)) ([511a65c](https://github.com/coco-de/coui/commit/511a65c336ab07b418ecb495f2f0e04baaa69e52))


### 문서

* **core,figma:** 익스포터 주석을 라이브러리 브랜드 하나 + 값 표 구조에 맞춘다 (Part of [#6118](https://github.com/coco-de/coui/issues/6118)) ([#6157](https://github.com/coco-de/coui/issues/6157)) ([5813058](https://github.com/coco-de/coui/commit/581305832c3ab5f6da4bad473067caa7b71550d3))

## [0.179.0](https://github.com/coco-de/coui/compare/coui_core-v0.178.0...coui_core-v0.179.0) (2026-11-09)


### ⚠ BREAKING CHANGES

* **rich-editor:** `CoreRichEditorFormat` 에 `blockType` 값이 늘고 기본 툴바의 첫 그룹이 제목 버튼 셋에서 블록 형식 버튼 하나가 된다 — 이 enum 을 빠짐없이 `switch` 하는 코드는 `blockType` 경우를 더해야 컴파일되고, 제목을 버튼으로 두려면 `toolbar:` 에 `heading1` · `heading2` · `heading3` 를 직접 넣는다. 이미지 버튼 글리프는 `image-plus` 에서 `image` 로 바뀐다.
* **forms:** External implementations of CoreNumberInputContract must provide errorText; custom locale interface implementations must provide calendarPreviousPeriod and calendarNextPeriod. Existing widget constructor calls remain supported.

### 기능

* add optional Tree root visibility and row spacing ([#6109](https://github.com/coco-de/coui/issues/6109)) ([d317c64](https://github.com/coco-de/coui/commit/d317c64b011e347c68b168257dced2ff6bc50d28))
* **forms:** 폼 저작 제약과 오류 상태 개선 ([#6100](https://github.com/coco-de/coui/issues/6100)) ([3b810ad](https://github.com/coco-de/coui/commit/3b810ad2f7ee66e637e80a64706d99c6b65538f1))
* **rich-editor:** 툴바 블록 형식 드롭다운 · 왼쪽 여백 12 · 캔버스 빌더 (리디자인 PR A) ([#6105](https://github.com/coco-de/coui/issues/6105)) ([64a6206](https://github.com/coco-de/coui/commit/64a620641c497ad478922281dc4f21ac50cb575c))


### 버그 수정

* **carousel-banner:** 아이콘 24·Web 이미지 채움과 원래 글리프 캡처 ([#6094](https://github.com/coco-de/coui/issues/6094)) ([171d23b](https://github.com/coco-de/coui/commit/171d23be1cb22c75e56fcc03dfd5b93b87c89f95))
* **command:** honor confirmed fullscreen and Leading defaults ([#6098](https://github.com/coco-de/coui/issues/6098)) ([a59cc7d](https://github.com/coco-de/coui/commit/a59cc7d6ed56aa06a4fa6001d032240107f16501))
* **navigation-bar:** 하단 바 구분선을 위 패딩에 겹쳐 높이 80 으로 ([#6103](https://github.com/coco-de/coui/issues/6103)) ([fc4564e](https://github.com/coco-de/coui/commit/fc4564e08838cc06bebac0c2f2a68d5013b448ee))
* **text-field:** plain 비활성에서 면·테두리를 그리지 않는다 ([#6099](https://github.com/coco-de/coui/issues/6099)) ([f417621](https://github.com/coco-de/coui/commit/f417621db5dd2dab4772f7e56ae19eb71d52263c))
* **text:** apply confirmed inline padding and primary cursor ([#6097](https://github.com/coco-de/coui/issues/6097)) ([b632308](https://github.com/coco-de/coui/commit/b632308e17d8dadb8235a59ba13de92f8feee4b6))

## 0.161.0 (Unreleased)

- Share native glass toolbar capsule geometry and grouped-button defaults across AppBar and ToolbarGroup.
- Share displacement maps and SVG filters between DOM Web and Flutter Web; compensate the 8-bit neutral-map bias so flat content does not drift with glass strength.
- Share frame-rate independent Liquid Glass navigation springs, momentum and deformation between Flutter and Web.
- Add material overrides for popup/menubar surfaces, grouped toolbar capsules, and explicit standard menu action icons.
- Clarify Liquid Glass selection with a visible capsule and palette accent, preserving authored colours.
- Add component material overrides for AppBar and NavigationBar.

## [0.178.0](https://github.com/coco-de/coui/compare/coui_core-v0.177.0...coui_core-v0.178.0) (2026-11-06)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** CoreHoverCardStyle 의 backgroundColor · borderColor · borderRadius · padding · panelMaxWidth 필드가 사라지고 합성한 Popup 의 CorePopupStyle 을 담는 panelStyle 슬롯 하나로 모였다(maxWidth 는 panelStyle.maxWidth).
* **core,flutter,web,figma:** `CouiPalette` 의 `success` · `info` · `warning` · `error` 매개변수 타입이 `CouiToneRamp` 에서 `CouiStatusRamp`(success 는 `CouiSuccessRamp`)로 좁아지고, CoUI `:root` 에 `--coui-<status>-950` 넷과 `--coui-success-450` 이 더해지며, CoUI Dark 의 상태 컨테이너와 success · info on-container 색이 바뀐다.
* **core,flutter,web,figma:** `ResolvedNavigationMenu`(Flutter)의 생성자가 `contentTriggerButtonStyle` · `openTriggerButtonStyle` 를, Web `ResolvedNavigationMenuTrigger` 의 생성자가 `buttonStyle` 을 필수로 요구한다(리졸버만 만드는 객체). 렌더 변화: 기본 트리거 안쪽 여백이 16/8 에서 12/8(chevron 있는 트리거는 시작 12 · 끝 8)로, 열림 · 호버 배경이 surface-container-highest 에서 surface-container 로, 바 안 트리거 간격이 4 에서 2 로, chevron 이 on-surface 에서 on-surface-variant 로, 드롭다운 판 모서리가 16 에서 12 로 바뀐다.
* **core,flutter,web,figma:** `ResolvedTooltip.border`(Flutter) 가 없어지고, 박스형 서페이스 스타일(예: neoBrutalism)에서 Tooltip 판이 스타일이 주던 컨트롤 테두리를 더 이상 받지 않는다. 기본 라벨 굵기가 SemiBold 에서 역할의 Medium 으로 바뀐다.
* **core,flutter,web,figma:** `CoreCommandStyle` 의 활성 행 막대 필드 `itemActiveIndicatorColor` · `itemActiveIndicatorWidth` · `itemActiveIndicatorInset` · `itemActiveIndicatorRadius` 와 그 `default*` 4개를 deprecation 없이 제거했다(활성 행은 `itemHighlightColor` 채움만으로 표시하며 Flutter `ResolvedCommand.itemActiveIndicator*` · Web `ResolvedCommand.itemIndicator` 도 함께 없어진다). 이 필드를 `commandStyle` 에 넘기던 코드는 컴파일되지 않으며, 행 모서리 기본값은 6 에서 8, 두 줄 행의 제목은 title 역할(SemiBold)에서 본문 역할(Regular), 설명은 13 Medium 에서 12 Regular(sm · md)로 바뀌어 렌더가 달라진다.
* **core,flutter,web,figma:** `Stepper` 의 `enabled` 가 새로 생겨 `null` 이면 `onStepChanged != null` 을 따르므로, 콜백 없이 쓰던 `Stepper` 는 이제 비활성 색으로 그려진다(활성 색은 `enabled: true`). `CoreStepperContract.enabled` 추가와 `resolveStepper(enabled:)` required, 기본 색 · 역할 · 간격(`connectorMargin` 4 → 8) 변경, Figma 변형 축 `Disabled=…` → `Enabled=…`(값 반전).
* **core,flutter,web,figma:** `CoreThemeControllerStyle` 의 선택 배지 필드 `badgeSize` · `badgeBackgroundColor` · `badgeIconStyle` · `disabledBadgeBackgroundColor` 를 @Deprecated 없이 제거한다 — 선택은 `selectedBorderColor` 고리와 접근성 속성(Flutter `Semantics.selected` · Web `aria-pressed`)이 알리므로 네 필드를 쓰던 코드는 지우면 되고, 기본값도 바뀐다(버튼 원형 32 · 40 · 48, 팔레트 24 · 32 · 40, 바탕 없음, 쉬는 테두리 0, 선택 고리 onSurface, 라벨 labelSmall · labelMedium · labelLarge).
* **core,flutter,web,figma:** end 정렬(자기 alignment 또는 Chat(alignment: end) 안)의 ChatBubble 은 variant · tail 을 적지 않으면 primary 말풍선에 꼬리가 end 쪽으로 그려지고(이전: neutral · 꼬리 없음), ChatBubble 의 variant · alignment · tail 필드와 CoreChatBubbleContract 의 같은 getter 타입이 nullable 로 바뀐다 — 예전 모양은 variant: CoreChatBubbleVariant.neutral, tail: false 를 직접 적는다.
* **timeline:** `CoreTimelineStyle.connectorOvershoot` 가 `connectorSpacing` 으로 개명되고 의미가 뒤집혔다 — 예전에는 연결선이 행 간격을 넘어 뻗는 길이(클수록 길어짐)였고 선은 점 바로 아래에서 시작했지만, 이제는 연결선 양끝이 점과 떨어지는 간격(클수록 짧아짐)이다. 예전 값 N 과 같은 끝 위치는 `connectorSpacing = dotTopMargin - N` 이고 시작은 항상 점 아래 `connectorSpacing` 에서 시작하므로 예전 모양을 그대로 재현하는 값은 없다. `ResolvedTimeline.connectorEndIndent` 는 제거되고 `connectorSpacing` · `connectorReach` 가 생겼다(Flutter 공개 심볼). `@Deprecated` 없이 바로 개명했다.

### 기능

* **core,flutter,web,figma:** 묶음 토글 크기 — md 40 · sm 32, Filter size ([#6022](https://github.com/coco-de/coui/issues/6022)) ([18a2071](https://github.com/coco-de/coui/commit/18a2071e78aa87a47f3f05c7a190657a4922d846))
* **core,flutter,web,figma:** Breadcrumb — 항목 글자 Regular · 안쪽 여백 2/4 · 간격 4 · 구분자 subtle · 포커스 링 10 · 비활성 색 (Part of [#5965](https://github.com/coco-de/coui/issues/5965)) ([#6054](https://github.com/coco-de/coui/issues/6054)) ([2b0060f](https://github.com/coco-de/coui/commit/2b0060fd953c5c6edf2a2dc1fd74bfa1f390370e))
* **core,flutter,web,figma:** Chat — 오른쪽(end) 정렬 말풍선은 primary · 꼬리 end 가 기본 (Part of [#5986](https://github.com/coco-de/coui/issues/5986)) ([#6047](https://github.com/coco-de/coui/issues/6047)) ([eac91e1](https://github.com/coco-de/coui/commit/eac91e1760585a6b079eb0126ef7c00efa64239a))
* **core,flutter,web,figma:** NumberTicker 값 글자를 Title/Large 로, 캔버스 라벨은 Body/XS (Part of [#5983](https://github.com/coco-de/coui/issues/5983)) ([#6033](https://github.com/coco-de/coui/issues/6033)) ([a8f27fa](https://github.com/coco-de/coui/commit/a8f27fa9d260c24c1626742a1a27495fdeff04c5))
* **core,flutter,web,figma:** Pagination — 칸 36 · 간격 4 · 숫자 Regular · 선택 SemiBold · 화살표 16 · 포커스 링 12 · 비활성 색 (Part of [#5965](https://github.com/coco-de/coui/issues/5965)) ([#6056](https://github.com/coco-de/coui/issues/6056)) ([d9c9513](https://github.com/coco-de/coui/commit/d9c951334cbd634008bb1f79b2d97028e1a91bb1))
* **figma:** Countdown 캔버스 — 네 칸 같은 폭(최소 size/56) · 좌우 여백 space/8 · 단위 글자 Body/XS (Part of [#5983](https://github.com/coco-de/coui/issues/5983)) ([#6030](https://github.com/coco-de/coui/issues/6030)) ([123be85](https://github.com/coco-de/coui/commit/123be8553306d9f8f4df85efcfb7dd62eac1426c))
* **selectable-text:** 선택 영역 채움을 primary-container 로 칠하고 알파 곱을 없앤다 (Part of [#5982](https://github.com/coco-de/coui/issues/5982)) ([#6035](https://github.com/coco-de/coui/issues/6035)) ([1655c7d](https://github.com/coco-de/coui/commit/1655c7dbeda671b0af6dc0b70c49dd147db00563))
* **text-block:** 인용 선 · 여백과 인용 · 코드 글자 역할 기본값을 바꾼다 (Part of [#5982](https://github.com/coco-de/coui/issues/5982)) ([#6034](https://github.com/coco-de/coui/issues/6034)) ([c00f4ce](https://github.com/coco-de/coui/commit/c00f4ce18d78d8d056e80c73f2ae903a6719b505))
* **timeline:** 점 10 · 연결선 outline-variant · 제목 Label/Large · 연결선 간격 connectorSpacing ([#6036](https://github.com/coco-de/coui/issues/6036)) ([b767c74](https://github.com/coco-de/coui/commit/b767c741deb422535b1303b65608ea72cfcd1833))


### 버그 수정

* **core,flutter,web,figma:** 달력 날짜 글자 굵기 · 월 제목 역할 · 범위 점 색을 디자이너 결정대로 바꾼다 ([#6042](https://github.com/coco-de/coui/issues/6042)) ([5a71106](https://github.com/coco-de/coui/commit/5a711064095bd04fa6554934a798ecd85aaf2345))
* **core,flutter,web,figma:** 달력 범위 안쪽 날짜 글자색을 onPrimaryContainer 로 바꾼다 ([#6031](https://github.com/coco-de/coui/issues/6031)) ([6beaf53](https://github.com/coco-de/coui/commit/6beaf5346774672dc3c909c4ad42bb77354f4551))
* **core,flutter,web,figma:** 묶음 토글 트랙 surface-container · Filter sm 초기화 26 정사각 ([#6076](https://github.com/coco-de/coui/issues/6076)) ([f4d17ee](https://github.com/coco-de/coui/commit/f4d17eeeae9363e3c711e170d5c49adffca0261f))
* **core,flutter,web,figma:** Carousel — 이전 · 다음 버튼은 불투명한 raised 면 · 인디케이터는 primary / outline · 배너 변형은 버튼을 끝에 모은다 (Part of [#5985](https://github.com/coco-de/coui/issues/5985)) ([#6051](https://github.com/coco-de/coui/issues/6051)) ([a582d37](https://github.com/coco-de/coui/commit/a582d37c24db3752665dce0b41f4fedc1bee84b4))
* **core,flutter,web,figma:** CarouselBanner — 띠 모서리 12 · 썸네일의 아이콘은 행의 크기와 색으로 가운데에 그린다 (Part of [#5985](https://github.com/coco-de/coui/issues/5985)) ([#6050](https://github.com/coco-de/coui/issues/6050)) ([42cf42c](https://github.com/coco-de/coui/commit/42cf42c55e93ea360a2b0dbd8566777dd596bb9b))
* **core,flutter,web,figma:** Chat — 머리글 · 바닥글 글자를 사본의 Label/Small · Body/XS 로 (Part of [#5986](https://github.com/coco-de/coui/issues/5986)) ([#6084](https://github.com/coco-de/coui/issues/6084)) ([8e79692](https://github.com/coco-de/coui/commit/8e796925fe36fd9d5506e0ca4258ae49870ae9d5))
* **core,flutter,web,figma:** Chip 닫기 아이콘 12 · 14 · 16, 닫기 버튼 16 · 18 · 20, 내용은 가운데로 놓는다 ([#6074](https://github.com/coco-de/coui/issues/6074)) ([b84019b](https://github.com/coco-de/coui/commit/b84019bec7a1bc800be0678b48eee827124ed3f8))
* **core,flutter,web,figma:** Command — 필터 칩 선택은 primary-container · 그룹 제목 12 Medium (Part of [#5968](https://github.com/coco-de/coui/issues/5968)) ([#6059](https://github.com/coco-de/coui/issues/6059)) ([951a5a2](https://github.com/coco-de/coui/commit/951a5a26fafcb3044b04906633b5ddf79c69aa71))
* **core,flutter,web,figma:** CommandItem — 행 모서리 8 · 두 줄 행 제목·설명 Regular · 활성 막대 제거 (Part of [#5968](https://github.com/coco-de/coui/issues/5968)) ([#6058](https://github.com/coco-de/coui/issues/6058)) ([8e569c1](https://github.com/coco-de/coui/commit/8e569c1472f58eb7dd9254cdad6c9f0db21021d5))
* **core,flutter,web,figma:** Dark 상태색 컨테이너를 팔레트의 Dark 전용 950 단계로, success 글자를 450 · info 글자를 500 으로 연결한다 ([#6065](https://github.com/coco-de/coui/issues/6065)) ([72a0623](https://github.com/coco-de/coui/commit/72a0623a43baca99c83d1a7502fada4b4052603c))
* **core,flutter,web,figma:** HoverCard — 트리거와 카드 사이 4 · 모서리 12 · 바탕 surface-bright (Part of [#5967](https://github.com/coco-de/coui/issues/5967)) ([#6063](https://github.com/coco-de/coui/issues/6063)) ([4a2d8af](https://github.com/coco-de/coui/commit/4a2d8af36b90f35937f86d63f6bebefa53a29454))
* **core,flutter,web,figma:** HoverCard — 판을 Card 가 아니라 Popup 으로 합성한다 (Part of [#5967](https://github.com/coco-de/coui/issues/5967)) ([#6079](https://github.com/coco-de/coui/issues/6079)) ([9e4f9dc](https://github.com/coco-de/coui/commit/9e4f9dcb18c6aa4ea937687c904a1ebb61158758))
* **core,flutter,web,figma:** ItemPicker 구역 라벨을 Label/Small · on-surface-subtle 로 바꾼다 ([#6029](https://github.com/coco-de/coui/issues/6029)) ([98a5c72](https://github.com/coco-de/coui/commit/98a5c72812ab75005c1cebdb082e5bb34088cea5))
* **core,flutter,web,figma:** main CI 가드를 끝까지 돌게 한다 — 코드 쪽 부채 정리와 남은 부채의 ratchet ([#6073](https://github.com/coco-de/coui/issues/6073)) ([eda625c](https://github.com/coco-de/coui/commit/eda625c5a380b29603a1f62bb6eb80772eab39d3))
* **core,flutter,web,figma:** Menu — 그룹 제목 12 Medium · 제목 아래 4 · 구분선 위아래 4 (Part of [#5967](https://github.com/coco-de/coui/issues/5967)) ([#6064](https://github.com/coco-de/coui/issues/6064)) ([7ad1d8d](https://github.com/coco-de/coui/commit/7ad1d8de580d0007280ec7a33d40732de0f4deda))
* **core,flutter,web,figma:** MenuItem 위험 항목의 활성 상태는 바탕만 채우고 글자색은 그대로 둔다 ([#6045](https://github.com/coco-de/coui/issues/6045)) ([b23bd96](https://github.com/coco-de/coui/commit/b23bd9652904265b686b5e61955de9d0d56b78ce))
* **core,flutter,web,figma:** NavigationMenu — 트리거 안쪽 여백 12/8 · 열린 항목 surface-container · chevron on-surface-variant · 판 모서리 12 (Part of [#5967](https://github.com/coco-de/coui/issues/5967)) ([#6061](https://github.com/coco-de/coui/issues/6061)) ([1af9187](https://github.com/coco-de/coui/commit/1af91877c4777e41db296f93db1ba194efec6442))
* **core,flutter,web,figma:** Popover — 트리거와 판 사이 간격 8 → 4 (Part of [#5967](https://github.com/coco-de/coui/issues/5967)) ([#6062](https://github.com/coco-de/coui/issues/6062)) ([65b8f41](https://github.com/coco-de/coui/commit/65b8f41fae67a489a279379639f0c7f41c438f24))
* **core,flutter,web,figma:** Stepper — 완료·현재 원은 primary, 다음 단계는 테두리 원, 비활성은 disabled 색 (Part of [#5966](https://github.com/coco-de/coui/issues/5966)) ([#6057](https://github.com/coco-de/coui/issues/6057)) ([9706951](https://github.com/coco-de/coui/commit/97069516a9baf516e8dfd74108cbab19445456e1))
* **core,flutter,web,figma:** Steps — 다음 단계는 테두리 원 · 지난 구간 연결선은 primary · 번호와 제목 SemiBold (Part of [#5966](https://github.com/coco-de/coui/issues/5966)) ([#6053](https://github.com/coco-de/coui/issues/6053)) ([2b6e5da](https://github.com/coco-de/coui/commit/2b6e5dad6c2b56d8b7868d20df886f7de187e2d5))
* **core,flutter,web,figma:** ThemeController — 칸 사이 12 · 칸 최소 폭 48 · 예시 테마마다 다른 팔레트 색 (Part of [#5987](https://github.com/coco-de/coui/issues/5987)) ([#6049](https://github.com/coco-de/coui/issues/6049)) ([5240a9f](https://github.com/coco-de/coui/commit/5240a9f4287fa7ae78f73c2fe5e876b47d17a935))
* **core,flutter,web,figma:** ThemeSwatch — 바탕 없는 원형 고리와 반원 팔레트, 선택은 배지 대신 고리로 (Part of [#5987](https://github.com/coco-de/coui/issues/5987)) ([#6048](https://github.com/coco-de/coui/issues/6048)) ([2533d6e](https://github.com/coco-de/coui/commit/2533d6e40fd8d36046c1d96115bd736e6a49f622))
* **core,flutter,web,figma:** Tooltip — 글자 12 Medium · 판 테두리 없음 (Part of [#5967](https://github.com/coco-de/coui/issues/5967)) ([#6060](https://github.com/coco-de/coui/issues/6060)) ([65dc2b6](https://github.com/coco-de/coui/commit/65dc2b60911a2878b0b9dbe430b245768a9a312f))
* **core,flutter,web:** main 에서 깨진 가드 3개와 테스트 5개 파일을 고친다 ([#6052](https://github.com/coco-de/coui/issues/6052)) ([1dd36c7](https://github.com/coco-de/coui/commit/1dd36c7b33aabb6a736a8c41481c3456a0d45581))
* **core,web:** Command 행 8 에 맞춰 반경 규칙 테스트와 룰 문장을 현재 값에 맞춘다 (Part of [#5968](https://github.com/coco-de/coui/issues/5968)) ([#6078](https://github.com/coco-de/coui/issues/6078)) ([c162580](https://github.com/coco-de/coui/commit/c1625807a760b31fc6d0115c21c1702418e06c9b))
* **core:** Dark 상태색 on-container 글자를 400 단계로 읽는다 ([#6037](https://github.com/coco-de/coui/issues/6037)) ([6697333](https://github.com/coco-de/coui/commit/6697333687f823db5b2793aef569bce34f65c1be))
* **figma:** Command fullscreen child 아이콘의 실제 크기 반영 ([#6091](https://github.com/coco-de/coui/issues/6091)) ([76a8257](https://github.com/coco-de/coui/commit/76a825726dbacc28e39bef2cbd9682075b3f9f4b))
* **menu:** 리디자인 사본의 호스트 행 모서리 8 반영 ([#6089](https://github.com/coco-de/coui/issues/6089)) ([5a88dc0](https://github.com/coco-de/coui/commit/5a88dc00fd7b8aaa4af29f062b25ecd3016e124e))
* **stepper:** 세로 제목 중심 정렬과 33/11 연결선 반영 ([#6090](https://github.com/coco-de/coui/issues/6090)) ([9e81a19](https://github.com/coco-de/coui/commit/9e81a193adc3ab8b78a2f140af924b9c175bb7dc))
* **tracker:** 막대 모서리 기본값을 radius/4 에서 2 로 ([#6032](https://github.com/coco-de/coui/issues/6032)) ([1b61e3d](https://github.com/coco-de/coui/commit/1b61e3d83bde0047a304ca120f77df4cf3dfe82e))

## [0.177.0](https://github.com/coco-de/coui/compare/coui_core-v0.176.0...coui_core-v0.177.0) (2026-11-04)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** TextField 계열 값 · 자리표시자 글자의 줄 높이가 140% 에서 역할 값(Body/Medium · Body/Large 150%)으로 바뀌고, 한 줄 입력 상자는 모든 크기에서 크기 단 높이에 글줄을 세로 가운데로 둔다 — TextField · Select 의 sm 은 33.6 에서 32 로, TextField xs 는 29.6 에서 24 로 낮아지고(md 40 · lg 48 · xl 56 · xl2 64 는 그대로), 여러 줄 TextField 는 줄마다 1.4 높아지며, NumberInput 값 글자가 Label/Large(Medium)에서 Body/Medium(Regular)으로 바뀌고, Flutter 의 가운데 정렬 TextField 값이 0.5px 오른쪽으로 옮겨진다. 이전 렌더가 필요하면 `textFieldStyle: CoreTextFieldStyle(padding: <크기 행 패딩>, baseTextStyle: CoreTextStyle.token(CoreTextStyles.bodyMedium).copyWith(lineHeight: CoreLineHeight.h140))` 를 넘긴다(NumberInput 값은 `fieldStyle: CoreTextFieldStyle(valueStyle: CoreTextStyle.token(CoreTextStyles.labelLarge))`).

### 버그 수정

* **core,flutter,web,figma:** 선택된 비활성 목적지가 선택 표시를 흐리게 남기고, Web 포커스 8% 레이어가 실제로 칠해진다 ([#6003](https://github.com/coco-de/coui/issues/6003)) ([899539d](https://github.com/coco-de/coui/commit/899539d77f1e67b19ba7c5dea83cdcef9459b6bc))
* **core,flutter,web,figma:** 한 줄 입력 상자를 크기 단 높이에 두고 값 글자는 역할 줄 높이로 세로 가운데에 그린다 ([#6009](https://github.com/coco-de/coui/issues/6009)) ([6991716](https://github.com/coco-de/coui/commit/6991716b7b9bc0a732def8e712b3442751876491))
* **core,flutter,web:** Dark 상태 아이콘 500 · SidebarItem 선택 배경 surfaceContainer · Stat filled surfaceContainerLow ([#6015](https://github.com/coco-de/coui/issues/6015)) ([ef150af](https://github.com/coco-de/coui/commit/ef150afa8f3f319157e30fbc06146f319dba4688))

## [0.176.0](https://github.com/coco-de/coui/compare/coui_core-v0.175.1...coui_core-v0.176.0) (2026-11-04)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** labelMode 를 주지 않은 NavigationBar · NavigationBarItem(mode: bar)이 아이콘만 그리던 것에서 모든 목적지에 라벨을 그리도록 바뀐다(바 높이 80 은 그대로, 이전 모습은 labelMode: CoreNavigationLabelMode.none 으로 되돌리며 이때 목적지는 64×40 · 바 56 · 터치 영역 48 이다). indicator fill 의 쌓인 목적지는 surfaceContainerHigh 타일 대신 primaryContainer 알약으로 선택을 그리고 selectedBackgroundColor 를 읽지 않으며(알약 색은 selectedIconAnchorColor), 선택된 목적지도 hover · focus · pressed 상태 레이어를 받는다.

### 기능

* **core:** ✨ RichEditor 리디자인 — 툴바를 입력 칸 테두리 안으로 · 구분선 · trailing 슬롯 ([#5989](https://github.com/coco-de/coui/issues/5989)) ([2b0cee1](https://github.com/coco-de/coui/commit/2b0cee1a56e6f631bc097e64ae497d9214e3414f))


### 버그 수정

* **core,flutter,web,figma:** DatePicker 설명 문구는 활성에서 on-surface-subtle, 비활성에서 disabled-content 로 칠한다 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5977](https://github.com/coco-de/coui/issues/5977)) ([6a6ab63](https://github.com/coco-de/coui/commit/6a6ab6305fd9ba06198494c8aaa372f513a09c8d))
* **core,flutter,web,figma:** FileInput 설명 문구 Regular · 제목 on-surface · 설명 on-surface-subtle ([#5996](https://github.com/coco-de/coui/issues/5996)) ([871e6dd](https://github.com/coco-de/coui/commit/871e6dd3a13cd83cc3c8d999d93c763367ef93af))
* **core,flutter,web,figma:** NavigationBar 포커스 링을 타일과 동심으로 맞추고 캔버스 예시를 결정대로 그린다 (Part of [#5740](https://github.com/coco-de/coui/issues/5740)) ([#5999](https://github.com/coco-de/coui/issues/5999)) ([fd848b5](https://github.com/coco-de/coui/commit/fd848b523460d5f394684143b0a92df88afcd220))
* **core,flutter,web,figma:** NavigationBar 하단 바 기본 라벨 · 세 라벨 배치의 primaryContainer 선택 · 선택 위 상태 레이어 ([#6002](https://github.com/coco-de/coui/issues/6002)) ([183029c](https://github.com/coco-de/coui/commit/183029c8004dfd1f18ef7ec1de38856a261652f2))
* **core,flutter,web,figma:** TimePicker 예시 · 구분자, FileInput 문구, ColorPicker 예시 값 ([#5993](https://github.com/coco-de/coui/issues/5993)) ([0c7b23e](https://github.com/coco-de/coui/commit/0c7b23ef8db0448cf31aac6053d13c84a722c395))
* **core:** Stat sm 값 글자의 굵기 덧씌움을 지워 titleLarge 역할 그대로 그린다 ([#5978](https://github.com/coco-de/coui/issues/5978)) ([67776d9](https://github.com/coco-de/coui/commit/67776d95cc12b7224d920af6ebf507d92fbf07fd))
* **figma:** PhoneInput 번호 칸 · ChipInput 힌트 색 · 세그먼트와 피커 값의 자간을 코드와 맞춘다 (Part of [#5831](https://github.com/coco-de/coui/issues/5831) · [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5997](https://github.com/coco-de/coui/issues/5997)) ([884ee65](https://github.com/coco-de/coui/commit/884ee65fa0c27f46b61f7d34bfcbd99382547b67))

## [0.175.1](https://github.com/coco-de/coui/compare/coui_core-v0.175.0...coui_core-v0.175.1) (2026-11-02)


### 버그 수정

* **core,flutter,web,figma:** 캔버스 확인 뒤 입력 계열 여백 · 비활성 색을 맞춘다 (Part of [#5831](https://github.com/coco-de/coui/issues/5831)) ([#5953](https://github.com/coco-de/coui/issues/5953)) ([2dd894e](https://github.com/coco-de/coui/commit/2dd894efe4b5a197cd164ee83b8674e7f5865dfc))
* **core,flutter,web,figma:** BottomSheet 의 액션 영역은 바탕 없이 아래에 고정되고, 위 구분선은 내용이 이어질 때만 보인다 (Part of [#5833](https://github.com/coco-de/coui/issues/5833)) ([#5955](https://github.com/coco-de/coui/issues/5955)) ([c89d47f](https://github.com/coco-de/coui/commit/c89d47fbe917e555cbaa8a3e93e01da6ea3cf926))
* **core,flutter,web,figma:** RadialProgress xl 글자 · Loading dots 물결 · Status busy 막대 끝 (Part of [#5879](https://github.com/coco-de/coui/issues/5879)) ([#5956](https://github.com/coco-de/coui/issues/5956)) ([de63db8](https://github.com/coco-de/coui/commit/de63db8738565badcb12839c452f2260f034caae))

## [0.175.0](https://github.com/coco-de/coui/compare/coui_core-v0.174.0...coui_core-v0.175.0) (2026-11-01)


### ⚠ BREAKING CHANGES

* **core,flutter,web,docs:** CoreRichEditorFormat.shortcut 이 nullable 이 되고 enum 에 heading1–3 · image 가 추가되어, shortcut 을 null 확인 없이 읽는 코드와 이 enum 을 exhaustive switch 하는 코드는 새 값을 처리해야 한다.

### 기능

* **core,flutter,web,docs:** RichEditor — H1–H3 제목과 서버 연동 이미지 업로드 · 삭제 ([#5943](https://github.com/coco-de/coui/issues/5943)) ([538bba5](https://github.com/coco-de/coui/commit/538bba5c3409be160cb489120e08cf0a2d39188d))
* **core,flutter,web,figma,docs:** TimePicker · ToggleGroup — 칸 hover 를 상태 레이어로 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5938](https://github.com/coco-de/coui/issues/5938)) ([274b0d4](https://github.com/coco-de/coui/commit/274b0d442d66574f251affba56f7e60fa93951aa))
* **core,flutter,web,figma,docs:** TimePicker AM/PM 을 세로 ToggleGroup 으로 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5939](https://github.com/coco-de/coui/issues/5939)) ([ad25b8e](https://github.com/coco-de/coui/commit/ad25b8e2181c7b557b2e76dbff380e9f53fccfcb))
* **core,flutter,web,figma,docs:** ToggleGroup — 세로 방향(direction) 추가 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5932](https://github.com/coco-de/coui/issues/5932)) ([14af131](https://github.com/coco-de/coui/commit/14af1311a25a2dfc62a67aeff77f8e175c4ba922))


### 버그 수정

* **core,flutter,web,figma:** DatePicker 설명 문구를 12(bodyXs)로 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5929](https://github.com/coco-de/coui/issues/5929)) ([774ac57](https://github.com/coco-de/coui/commit/774ac57c4bcb40cc1d3a16118787ddaa4fbe43bb))
* **core,flutter,web,figma:** Fab 액션 항목 행 모서리를 8 로 되돌림 (Part of [#5883](https://github.com/coco-de/coui/issues/5883)) ([#5931](https://github.com/coco-de/coui/issues/5931)) ([b894798](https://github.com/coco-de/coui/commit/b894798622e2b2b3010ef540633b8e0258c53573))
* **core,flutter,web,figma:** MultipleChoice 미선택 칩 neutral·low · Slider 부모 폭 고정 (Part of [#5880](https://github.com/coco-de/coui/issues/5880)) ([#5937](https://github.com/coco-de/coui/issues/5937)) ([f367d82](https://github.com/coco-de/coui/commit/f367d82e45fa8cb8d4a208937ca4e428640c6f88))
* **core,flutter,web,figma:** StarRating 표시만 반 단계 · MultipleChoice 선택 칩 Emphasis low (Part of [#5880](https://github.com/coco-de/coui/issues/5880)) ([#5930](https://github.com/coco-de/coui/issues/5930)) ([7fb21ab](https://github.com/coco-de/coui/commit/7fb21abd82bb0873b5c2b902099357637fde74d5))

## [0.174.0](https://github.com/coco-de/coui/compare/coui_core-v0.173.0...coui_core-v0.174.0) (2026-11-01)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma,docs:** Basic 의 showTrailingIcon 기본값이 false 에서 true 로 바뀌어 trailing 이 없는 Basic 은 이제 chevron-right 를 그리고, Stat 의 기본 variant 도 filled 에서 outlined 로 바뀌어 variant 를 적지 않은 Stat 은 outline-variant 선으로 그려진다. 옛 모습은 Basic(showTrailingIcon: false) 와 Stat(variant: CoreStatVariant.filled) 로 되돌린다.
* **core,flutter,web,figma,docs:** EmptyState 의 기본 variant 가 compact 에서 normal 로 바뀌어 variant 를 적지 않은 EmptyState 의 패딩 · 최소 높이 · 글자 크기가 달라지고, 모든 변형의 아이콘 크기와 neutral 아이콘 색(on-surface-subtle → on-surface-variant)이 바뀌며 아이콘이 원형 상자에 담긴다. 이전 모양이 필요하면 variant: CoreEmptyStateVariant.compact 를 명시한다.

### 기능

* **core,flutter,web,docs:** RichEditor — 서식 툴바가 붙은 WYSIWYG Markdown 글·댓글 작성기 ([#5871](https://github.com/coco-de/coui/issues/5871)) ([edba9b7](https://github.com/coco-de/coui/commit/edba9b7a0142660b8d036d90e4723b171f7e9f24))
* **core,flutter,web,figma,docs:** ✨ 표시 카드 정리 — DescriptionCard · Basic · Stat 리디자인 ([#5832](https://github.com/coco-de/coui/issues/5832)) ([#5837](https://github.com/coco-de/coui/issues/5837)) ([cc7b345](https://github.com/coco-de/coui/commit/cc7b34515122a97b3d5b27b8559345719f9a2454))
* **core,flutter,web,figma,docs:** ✨ EmptyState — success 톤 · large 변형 · 원형 아이콘 상자, 기본 변형은 normal ([#5836](https://github.com/coco-de/coui/issues/5836)) ([ad3b421](https://github.com/coco-de/coui/commit/ad3b421db2ff1aef5c30e9aa8fd9aa2a8d62701d))
* **core,flutter,web,figma,docs:** 입력 계열 확장 리디자인 — ItemPicker · MultiAnswerCard · FormattedInput · ObjectInput · PhoneInput · ChipInput · Sortable ([#5831](https://github.com/coco-de/coui/issues/5831)) ([#5838](https://github.com/coco-de/coui/issues/5838)) ([2f54389](https://github.com/coco-de/coui/commit/2f543893970aef030e2f00503229007e4df6b671))
* **core,flutter,web,figma,docs:** Autocomplete 일치 구간 강조와 Popup 테두리 outline-variant (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5905](https://github.com/coco-de/coui/issues/5905)) ([0e43b4c](https://github.com/coco-de/coui/commit/0e43b4c9b56462ce707c53c0c3e1142d9360d397))
* **core,flutter,web,figma,docs:** ColorPicker 리디자인 — 모드 탭을 ToggleGroup 으로, 핸들 · 빈 스와치 · 한 줄 최근 색 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5906](https://github.com/coco-de/coui/issues/5906)) ([7225a1c](https://github.com/coco-de/coui/commit/7225a1c9fc3db9274495e7192e11bc1f2fa93a00))
* **core,flutter,web,figma,docs:** DatePicker · DateRangePicker — 트리거를 읽기 전용 TextField 로 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5927](https://github.com/coco-de/coui/issues/5927)) ([ccddaf3](https://github.com/coco-de/coui/commit/ccddaf3c1b858efce5ff77e2c81548ece4ab5b41))
* **core,flutter,web,figma,docs:** FileInput 구조 — 원형 아이콘 상자, 제목·안내문 묶음, 여백 32/24 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5910](https://github.com/coco-de/coui/issues/5910)) ([06e729b](https://github.com/coco-de/coui/commit/06e729b2abb02da7fbbadc895f50663cf8783732))
* **core,flutter,web,figma,docs:** FileInput 점선 6/4 · outline-variant 와 DatePicker 트리거 포커스 primary (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5904](https://github.com/coco-de/coui/issues/5904)) ([7ee6a5b](https://github.com/coco-de/coui/commit/7ee6a5bd1d4a63ab3a40a99bf55168ff34962b9f))
* **core,flutter,web,figma,docs:** Filter 가 ToggleGroup 을 합성한다 — 구분선 · 비활성 · 안쪽 여백 3 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5907](https://github.com/coco-de/coui/issues/5907)) ([5c6e0d3](https://github.com/coco-de/coui/commit/5c6e0d30ede619acc68ce8a695ce64a6b71790ba))
* **core,flutter,web,figma,docs:** MultipleChoice 가 Chip 을 합성한다 — 옵션 32 높이 · 8 간격 (Part of [#5880](https://github.com/coco-de/coui/issues/5880)) ([#5902](https://github.com/coco-de/coui/issues/5902)) ([a1659ea](https://github.com/coco-de/coui/commit/a1659ea9b91068661cfc1d53a0b94353dc2c8367))
* **core,flutter,web,figma,docs:** Popup 테두리 AppBar 유리 예외 · NavigationMenu 테두리 · Autocomplete 강조 행 · Filter 구분선 간격 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5909](https://github.com/coco-de/coui/issues/5909)) ([8ffddc5](https://github.com/coco-de/coui/commit/8ffddc57e59328e056428db4c95fc84c59edca9b))
* **core,flutter,web,figma,docs:** TimePicker — 트리거는 부모 폭 채움, 시·분 칸 64×56 · 편집 칸은 primary-container 면 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5911](https://github.com/coco-de/coui/issues/5911)) ([fc7114c](https://github.com/coco-de/coui/commit/fc7114c838beeb2a3b760558dcf14f530910021c))
* **core,flutter,web,figma,docs:** TimePicker — 트리거를 읽기 전용 TextField 로, AM/PM 을 ToggleGroup 으로 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5908](https://github.com/coco-de/coui/issues/5908)) ([079675d](https://github.com/coco-de/coui/commit/079675d0408bcff97622cc8808d1b6c2aabf78e2))
* **core,flutter,web,figma,docs:** ToggleGroup — 묶음 토글을 공용 컴포넌트로 더한다 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5903](https://github.com/coco-de/coui/issues/5903)) ([1c058d0](https://github.com/coco-de/coui/commit/1c058d0b768dcc7b4d59cf6127f46e74ce25deba))
* **core,flutter,web,figma,docs:** ToggleGroup 크기 단계 md/sm — 판 안 토글은 sm (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5913](https://github.com/coco-de/coui/issues/5913)) ([e7e3d50](https://github.com/coco-de/coui/commit/e7e3d50f3435e3fd8570cfbba806c071c707e89b))
* **core,flutter,web,figma,docs:** ToggleGroup 폭 채움 옵션과 ColorPicker 핸들 · 막대 테두리 확정 반영 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5912](https://github.com/coco-de/coui/issues/5912)) ([51220b6](https://github.com/coco-de/coui/commit/51220b6f3a38106cbe55442d9b00ab04f369646d))
* **core,flutter,web,figma:** Slider 슬롯 · 손잡이 그림자 · 손잡이 포커스 링과 StarRating 별 · 크기 · 값 표시를 사본에 맞춘다 (Part of [#5880](https://github.com/coco-de/coui/issues/5880)) ([#5901](https://github.com/coco-de/coui/issues/5901)) ([5702584](https://github.com/coco-de/coui/commit/57025842f1a297c489cb9c506610764f31581958))
* **core:** BottomActionBar 에 weighted · icon · summary 배치를 더한다 ([#5870](https://github.com/coco-de/coui/issues/5870)) ([5822157](https://github.com/coco-de/coui/commit/5822157ea6c7a67dd356c5dc5ce77b26536928bb))
* **core:** BottomSheet 를 더한다 (Part of [#5833](https://github.com/coco-de/coui/issues/5833)) ([#5874](https://github.com/coco-de/coui/issues/5874)) ([53f8ef9](https://github.com/coco-de/coui/commit/53f8ef9a69ae513995c48da0e4eec74b2134cbf6))
* **core:** Calendar · Autocomplete · FileInput 모양을 사본에 맞춘다 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5894](https://github.com/coco-de/coui/issues/5894)) ([b055710](https://github.com/coco-de/coui/commit/b0557101486846b615450df34c6a395681657815))
* **core:** CoUI Light 상태색 on-container 글자를 s800 에서 s700 으로 올린다 ([#5876](https://github.com/coco-de/coui/issues/5876)) ([6822c61](https://github.com/coco-de/coui/commit/6822c618048a6cb85f8095ee4decb28a6b075c79))
* **core:** Drawer 뒤 화면이 기본으로 물러나지 않는다 (Part of [#5833](https://github.com/coco-de/coui/issues/5833)) ([#5892](https://github.com/coco-de/coui/issues/5892)) ([fb07816](https://github.com/coco-de/coui/commit/fb07816590a4a22ca6fafa188f33afcdb7da013f))
* **core:** Drawer 옆 패널을 400 폭 · 안쪽 한 변 경계로 바꾸고 하단 영역을 더한다 (Part of [#5833](https://github.com/coco-de/coui/issues/5833)) ([#5875](https://github.com/coco-de/coui/issues/5875)) ([fd62739](https://github.com/coco-de/coui/commit/fd6273984bbb21200462f542328841e10351d76c))
* **core:** Fab 메뉴 패널 여백을 목록 여백 6 으로 맞춘다 (Part of [#5883](https://github.com/coco-de/coui/issues/5883)) ([#5899](https://github.com/coco-de/coui/issues/5899)) ([00bc31b](https://github.com/coco-de/coui/commit/00bc31be81e9bb745fc04fe62e7d1a13807549da))
* **core:** Filter 를 묶음 토글 기준으로 맞추고 초기화 버튼을 맨 뒤로 옮긴다 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5891](https://github.com/coco-de/coui/issues/5891)) ([f7df1af](https://github.com/coco-de/coui/commit/f7df1afa9be82381e3216a5b8dc8d5f4d0881038))
* **core:** Indicator 가 배지 둘레(surface 2px)를 그린다 (Part of [#5879](https://github.com/coco-de/coui/issues/5879)) ([#5888](https://github.com/coco-de/coui/issues/5888)) ([0c509a6](https://github.com/coco-de/coui/commit/0c509a6692c849d50d780f030c2ab54664faa38c))
* **core:** ItemPicker 비활성 행 글자와 체크가 비활성 전경색을 쓴다 ([#5865](https://github.com/coco-de/coui/issues/5865)) ([35ada10](https://github.com/coco-de/coui/commit/35ada108419023ecbe4cd0e2b7f5cd9f8727a1dc))
* **core:** Loading dots · bar · pulse 모양을 사본대로 맞춘다 (Part of [#5879](https://github.com/coco-de/coui/issues/5879)) ([#5893](https://github.com/coco-de/coui/issues/5893)) ([be78898](https://github.com/coco-de/coui/commit/be7889818dad8f7b041d8a4f6476f160cac67a42))
* **core:** OptionItem · OptionList 를 더한다 (Part of [#5833](https://github.com/coco-de/coui/issues/5833)) ([#5872](https://github.com/coco-de/coui/issues/5872)) ([176fa23](https://github.com/coco-de/coui/commit/176fa2360861b54164228d59ee4b660a5e66e6dc))
* **core:** PhoneInput 국가 목록의 국기를 선택기와 같은 14 로 그린다 (Part of [#5884](https://github.com/coco-de/coui/issues/5884)) ([#5885](https://github.com/coco-de/coui/issues/5885)) ([bb1808f](https://github.com/coco-de/coui/commit/bb1808fcac6c59b7e2d69302369827d2b3d562fb))
* **core:** PhoneInput 번호 칸 여백을 읽기 방향 14 / 12 로 둔다 ([#5864](https://github.com/coco-de/coui/issues/5864)) ([08d7416](https://github.com/coco-de/coui/commit/08d7416e76d30ac3c85be9b8d02aa63fba189cac))
* **core:** Progress 라벨 굵기와 칸 간격을 사본에 맞춘다 (Part of [#5879](https://github.com/coco-de/coui/issues/5879)) ([#5886](https://github.com/coco-de/coui/issues/5886)) ([6b0e49a](https://github.com/coco-de/coui/commit/6b0e49ab4ef5ae504acba83259c2145aaa01e732))
* **core:** RadialProgress 에 Size · Tone, Loading 에 Tone 을 더하고 Progress 불확정 폭을 맞춘다 (Part of [#5879](https://github.com/coco-de/coui/issues/5879)) ([#5890](https://github.com/coco-de/coui/issues/5890)) ([8bda125](https://github.com/coco-de/coui/commit/8bda12584fdb713e7589201aa46629d71e2b17e7))
* **core:** Resizable 상태별 선과 포커스 링, Popup 여백 프리셋을 더한다 (Part of [#5883](https://github.com/coco-de/coui/issues/5883)) ([#5887](https://github.com/coco-de/coui/issues/5887)) ([d91afff](https://github.com/coco-de/coui/commit/d91afff5ab6e4c282b21593cfcea611cb47480ff))
* **core:** Slider · Range 사본 값을 맞춘다 (Part of [#5880](https://github.com/coco-de/coui/issues/5880)) ([#5898](https://github.com/coco-de/coui/issues/5898)) ([0482e75](https://github.com/coco-de/coui/commit/0482e7596906eab93bd9b96a05a72aa51425b18a))
* **core:** Sortable 비활성 전경색 ([#5866](https://github.com/coco-de/coui/issues/5866)) ([56eea2f](https://github.com/coco-de/coui/commit/56eea2f585df38d4a96d3de3021c982e67a606db))
* **core:** Status 막대 길이 · 라벨 색 · offline 링 색을 디자이너 확인 값으로 맞춘다 (Part of [#5879](https://github.com/coco-de/coui/issues/5879)) ([#5900](https://github.com/coco-de/coui/issues/5900)) ([73b2fda](https://github.com/coco-de/coui/commit/73b2fdacccf93ccbbc5838000d82eb3fbc2ffc1d))
* **core:** Status 접속 상태와 ValidationBadge 크기를 사본에 맞추고 Indicator 둘레 반경을 Core 로 올린다 (Part of [#5879](https://github.com/coco-de/coui/issues/5879)) ([#5896](https://github.com/coco-de/coui/issues/5896)) ([f21ba09](https://github.com/coco-de/coui/commit/f21ba091c9c0564dbb364da8d2049c7689affa3a))
* **core:** TabPane 앞 · 뒤 슬롯 아이콘을 16 으로 맞춘다 (Part of [#5882](https://github.com/coco-de/coui/issues/5882)) ([#5895](https://github.com/coco-de/coui/issues/5895)) ([3cb74c6](https://github.com/coco-de/coui/commit/3cb74c640bc8e95ec3b143f96f43375993005685))
* **core:** TabPane boxed 를 밑줄 탭 + 카드로 바꾸고 editorStrip 값을 맞춘다 (Part of [#5882](https://github.com/coco-de/coui/issues/5882)) ([#5889](https://github.com/coco-de/coui/issues/5889)) ([85d0678](https://github.com/coco-de/coui/commit/85d0678a9cdcf2eb523625472c3f12f8c542d698))


### 버그 수정

* **core,flutter,docs:** 유리 팝오버는 페이드 중에도 배경 흐림을 지킨다 — 패널을 감싸지 않고 재질을 페이드한다 ([#5856](https://github.com/coco-de/coui/issues/5856)) ([4b835bc](https://github.com/coco-de/coui/commit/4b835bc867b497c566df277d9a4ceeda73e40cc9))
* **core,flutter,web,docs:** Dock 막대는 내용이 크면 자란다 — height 는 최소 높이다 ([#5858](https://github.com/coco-de/coui/issues/5858)) ([99a567a](https://github.com/coco-de/coui/commit/99a567a8a1f0cc345a94e187b944055395e6c9b8))
* **core,flutter,web,figma:** 비활성 Filter 의 구분선을 disabled-outline 으로 그린다 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5919](https://github.com/coco-de/coui/issues/5919)) ([c833dc2](https://github.com/coco-de/coui/commit/c833dc2ebda98bb7492d6d7d7c5e686866a3dd2c))
* **core,flutter,web,figma:** 비활성 TimePicker · DatePicker 의 아이콘이 필드의 비활성 색을 따른다 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5916](https://github.com/coco-de/coui/issues/5916)) ([68d664b](https://github.com/coco-de/coui/commit/68d664ba6f4680b6b540bcc78959bd8d69162358))
* **core,flutter,web,figma:** DatePicker 오류 문구를 12 크기로 그리고 비활성이면 disabled-content 로 그린다 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5925](https://github.com/coco-de/coui/issues/5925)) ([0000878](https://github.com/coco-de/coui/commit/0000878ad8fdf5a534e4bd72db918070f78a4d76))
* **core,flutter,web,figma:** FileInput 높이 224(파일 행 기본 숨김)와 비활성 면 · 테두리 · 내용 disabled 토큰 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5921](https://github.com/coco-de/coui/issues/5921)) ([a90d8ef](https://github.com/coco-de/coui/commit/a90d8efe9f350a8dc0b6fa236f4658d3b17739f0))
* **core,flutter,web,figma:** FileInput 드래그 중 업로드 아이콘이 primary 로 칠해진다 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5924](https://github.com/coco-de/coui/issues/5924)) ([b74b4ca](https://github.com/coco-de/coui/commit/b74b4ca9ca5822fe71a4d86d9623f29d79de4301))
* **core,flutter,web,figma:** TimePicker 활성 시계 아이콘이 on-surface-variant 를 그린다 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5920](https://github.com/coco-de/coui/issues/5920)) ([46368b1](https://github.com/coco-de/coui/commit/46368b1e8a1d3b164fdac4701945898bf96f4ba8))
* **core,web,docs:** Safari 에서 서리·음영이 유리의 흐림을 지우지 않게 한다 — WebKit 은 첫 페인트부터, 그 밖은 런타임이 알린 뒤 두 항을 뺀다 ([#5855](https://github.com/coco-de/coui/issues/5855)) ([ceb99ce](https://github.com/coco-de/coui/commit/ceb99cef23ebb8125bbe870de6a3d37867f4effd))
* **core:** DatePicker 활성 달력 아이콘이 on-surface-variant 를 그린다 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5922](https://github.com/coco-de/coui/issues/5922)) ([7cd5739](https://github.com/coco-de/coui/commit/7cd57391372244af06f2b42714db73db69f39037))
* **core:** PhoneInput 번호 칸 여백을 읽기 방향 12 / 14 로 바로잡는다 ([#5869](https://github.com/coco-de/coui/issues/5869)) ([7d3ae10](https://github.com/coco-de/coui/commit/7d3ae10e6267c93f1543df1f35869132a57ce758))


### 리팩터링

* **core,flutter,web,figma,docs:** ContextMenu 들어 올림의 시각 값을 CoreContextMenuStyle 필드로 옮긴다 ([#5860](https://github.com/coco-de/coui/issues/5860)) ([7bc0a70](https://github.com/coco-de/coui/commit/7bc0a703bf255fdcda13d50ecdb0f18085a99270))

## [0.173.0](https://github.com/coco-de/coui/compare/coui_core-v0.172.0...coui_core-v0.173.0) (2026-10-29)


### 기능

* **core,flutter,web,docs:** ✨ iOS 27 유리 재질 — 서리 · 몸체 음영 튜닝 필드와 수치 프리셋 ios27 ([#5823](https://github.com/coco-de/coui/issues/5823)) ([aba0ab7](https://github.com/coco-de/coui/commit/aba0ab7078ae8cba3a7268d10433e8eb4ba8ab06))
* **core,flutter,web,figma,docs:** ✨ ContextMenu liftChild — 길게 누르면 child 를 들어 올리고 닫으면 원본으로 접는다 (옵트인) ([#5826](https://github.com/coco-de/coui/issues/5826)) ([46dae48](https://github.com/coco-de/coui/commit/46dae4871535b04028b4d29ed80098111db9e806))
* **core,flutter,web,figma:** ✨ Drawer — 열린 방향으로 더 끌면 고무줄처럼 늘어난다 (rubberBand, 기본은 꺼짐) ([#5821](https://github.com/coco-de/coui/issues/5821)) ([e8cda89](https://github.com/coco-de/coui/commit/e8cda89bb31312c935c3dc4ab8692087a6454a83))
* **core,flutter,web,tool,docs:** ✨ 적응형 품질 — 프레임이 디스플레이 속도를 못 지킬 때 유리를 매끄러움과 맞바꾼다 (adaptiveQuality, 기본은 꺼짐) ([#5824](https://github.com/coco-de/coui/issues/5824)) ([33d685b](https://github.com/coco-de/coui/commit/33d685b6568ebb9a54b856e5e4faae9b526dbefc))


### 버그 수정

* **core,flutter,web:** InputOtp 칸 테두리를 TextField 와 같은 단계로 (outlineVariant · hover outline) ([#5818](https://github.com/coco-de/coui/issues/5818)) ([0e36b4e](https://github.com/coco-de/coui/commit/0e36b4e8423e9f26a99a8a567f506ff0c38db3bb))
* **core,flutter,web:** Safari · Firefox 에는 굴절 참조를 붙이지 않는다 — 층이 다시 만들어지면 참조가 든 목록은 그려지지 않는다 ([#5819](https://github.com/coco-de/coui/issues/5819)) ([9f43945](https://github.com/coco-de/coui/commit/9f43945f1c9b7afe49f8219b1d339389dae7308f))

## [0.172.0](https://github.com/coco-de/coui/compare/coui_core-v0.171.0...coui_core-v0.172.0) (2026-10-28)

### 기능

* **swipe-actions:** add shared gesture contracts and theme ([#5809](https://github.com/coco-de/coui/pull/5809)) ([7646e9b](https://github.com/coco-de/coui/commit/7646e9bdbd3e665f0f51cc225d1a817c607adb35))

### 버그 수정

* **select:** allow content-width option panels ([#5810](https://github.com/coco-de/coui/issues/5810)) ([9aa27f7](https://github.com/coco-de/coui/commit/9aa27f7afd83147370037180294151f527e4ff04))

## [0.171.0](https://github.com/coco-de/coui/compare/coui_core-v0.170.0...coui_core-v0.171.0) (2026-10-28)


### 기능

* **outlined-container:** optionally preserve transparent border space ([ef67795](https://github.com/coco-de/coui/commit/ef677954fed71b9ae7705042db034a62a609acd6))

## [0.170.0](https://github.com/coco-de/coui/compare/coui_core-v0.169.0...coui_core-v0.170.0) (2026-10-28)


### 기능

* **core,flutter,web,figma,docs:** ✨ ContextMenu 에 글라이드로 고르기 · 미리보기 · 선택 햅틱을 더한다 ([#5803](https://github.com/coco-de/coui/issues/5803)) ([2acc41d](https://github.com/coco-de/coui/commit/2acc41dc3ff4e870e5a1027200d6f729bc3c1f0e))

## [0.169.0](https://github.com/coco-de/coui/compare/coui_core-v0.168.0...coui_core-v0.169.0) (2026-10-28)


### 기능

* **core,flutter,web,docs:** ✨ 서페이스 튜닝에 모드별 채도·빛의 방향과 굴절 법칙을 더한다 ([#5795](https://github.com/coco-de/coui/issues/5795)) ([90cb7fe](https://github.com/coco-de/coui/commit/90cb7fea249c725cae607c611d0c4addf8eb904e))
* **glass:** ✨ liquid_glass_widgets 1.15 변경 반영 ([#5784](https://github.com/coco-de/coui/issues/5784)) ([8932fbf](https://github.com/coco-de/coui/commit/8932fbf69a166505b2ed13777935e666a976e3a0))


### 버그 수정

* **core,flutter,web,docs:** ✨ 여백이 다른 라벨 Divider 의 라벨을 Web 에서도 상자 정중앙에 둔다 ([#5794](https://github.com/coco-de/coui/issues/5794)) ([fb0a322](https://github.com/coco-de/coui/commit/fb0a32227a9f038c2bc2755c9ed0d4a01e8d062c))
* **figma:** classify native caret height as host-derived ([#5791](https://github.com/coco-de/coui/issues/5791)) ([be7d3ae](https://github.com/coco-de/coui/commit/be7d3ae965da1c33f79b3d55ceb3804860d75502))
* **figma:** support analyzer AST changes in style reader ([#5790](https://github.com/coco-de/coui/issues/5790)) ([b3e3ea5](https://github.com/coco-de/coui/commit/b3e3ea53ba74ecf9197590d13a53b3230b27c31d))

## [0.168.0](https://github.com/coco-de/coui/compare/coui_core-v0.167.0...coui_core-v0.168.0) (2026-10-28)


### 기능

* **core,flutter,web,figma,docs:** TextArea 설명과 글자 수 사이 12, InputOtp lg 칸 테두리 1 ([#5781](https://github.com/coco-de/coui/issues/5781)) ([f589a89](https://github.com/coco-de/coui/commit/f589a89f8997dc0c0de3e83e439ff2b4979aea9c))

## [0.167.0](https://github.com/coco-de/coui/compare/coui_core-v0.166.0...coui_core-v0.167.0) (2026-10-28)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma,docs:** display · headline 여섯 역할이 뷰포트 폭에 따라 작아진다 — 768 미만(mobile)은 36 · 32 · 28 · 24 · 20 · 16, 1024 미만(tablet)은 44 · 40 · 36 · 28 · 24 · 20 이고 1024 이상은 지금과 같다(52 · 48 · 44 · 32 · 28 · 24), mobile 의 headlineSmall 자간은 −1% 다. 모든 CoUIApp · CoUILayer · CoUIWeb 앱에 기본으로 적용되어 Text 체인 · TextBlock h1–h3 · PageHeader 제목 · Countdown · Stat 값 · AppBar prominent 제목도 함께 작아지고, Avatar 이니셜 · 배지와 TimePicker 세그먼트 행은 데스크톱 크기로 고정된다. 이전 크기를 유지하려면 CoUIApp(typographyTier: CoreBreakpointTier.desktop) · CoUILayer(typographyTier: CoreBreakpointTier.desktop) · CoUIWeb(typographyTier: CoreBreakpointTier.desktop) 로 고정한다. 함께 바뀌는 것: CoreTypography 의 == 가 22 역할의 값 비교가 되고, CoUIThemeController.setCustomTheme 이 타이포 변수를 더는 쓰지 않으며, Web Avatar 의 내용 · 배지와 TimePicker 세그먼트 행이 상자 없는 [data-coui-typography-tier] 래퍼 안에 놓여 직계 자식 선택자(>)가 닿지 않는다.

### 기능

* **core,flutter,web,figma,docs:** ✨ display · headline 을 뷰포트 단계(mobile · tablet · desktop)로 줄인다 ([#5774](https://github.com/coco-de/coui/issues/5774)) ([884c4cf](https://github.com/coco-de/coui/commit/884c4cf58d88114df651048927fb39ca04314900)), closes [#5568](https://github.com/coco-de/coui/issues/5568)


### 버그 수정

* **core,flutter,web,figma,docs:** 입력의 포커스 · 오류 테두리를 1 로, InputOtp lg 숫자를 SemiBold 로 ([#5780](https://github.com/coco-de/coui/issues/5780)) ([f60fa0f](https://github.com/coco-de/coui/commit/f60fa0f91a62702d79c6325b5c1c98552fb2abfe))
* **core,flutter,web,figma:** 비활성 Select 의 글자와 화살표를 필드의 비활성 색으로 그린다 ([#5777](https://github.com/coco-de/coui/issues/5777)) ([fe2aff4](https://github.com/coco-de/coui/commit/fe2aff4cd2888940f9cf5d394dd66fc97bd9c741))
* **guards:** reader census G3 상한을 NumberInput 이 더한 2 만큼 올린다 ([#5778](https://github.com/coco-de/coui/issues/5778)) ([ab181c6](https://github.com/coco-de/coui/commit/ab181c6e4d07b46625f62323388712e56fce172b))

## [0.166.0](https://github.com/coco-de/coui/compare/coui_core-v0.165.0...coui_core-v0.166.0) (2026-10-28)


### 기능

* **core,flutter,web,figma,docs:** 제목 역할 굵기를 700 에서 600 으로 낮춘다 ([6046f2a](https://github.com/coco-de/coui/commit/6046f2aee8cd76810a512159983a9bc93548044c))
* **core,flutter,web:** NumberInput 신설 ([#5762](https://github.com/coco-de/coui/issues/5762) 일부) ([260750d](https://github.com/coco-de/coui/commit/260750d0986b4e87cdbb4288bdee96913ebd9221))
* **figma,docs:** PanelHeader 기본 행동을 plain 버튼과 뒤 화살표로 맞춘다 ([#5768](https://github.com/coco-de/coui/issues/5768)) ([9066d8c](https://github.com/coco-de/coui/commit/9066d8ca60c13e9202f77eb5bb7123fe2f3d0b58))


### 버그 수정

* **number-input:** preserve numeric precision and accessible actions ([f689ad3](https://github.com/coco-de/coui/commit/f689ad335d3ef4985d33218bb2d4583b08ae6492))


### 리팩터링

* **core,flutter,web,docs:** NumberInput 크기를 자기 단계 enum 으로 두고 버튼 단계를 그 안에서 정한다 ([895240b](https://github.com/coco-de/coui/commit/895240b54838c72d466da152c2dd9765c7918f59))

## [0.165.0](https://github.com/coco-de/coui/compare/coui_core-v0.164.0...coui_core-v0.165.0) (2026-10-28)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma,docs:** ResolvedColorScheme 생성자가 errorIcon · successIcon · warningIcon · infoIcon 을 required 로 받고 CoreColorScheme 이 같은 필드를 가진다 — resolved() 로 만드는 경로는 그대로이고, ResolvedColorScheme 을 직접 만들거나 CoreSchemeSource 를 구현하는 앱은 칸을 더해야 한다. CoUI 상태 원시값이 바뀌어 상태 색을 쓰는 모든 렌더가 달라진다.
* **core,flutter,web,figma,docs:** `CoreButtonVariant` 에 `tonal` 멤버가 추가되어, 앱에서 이 enum 을 기본 분기 없이 exhaustive `switch` 하던 코드는 컴파일되지 않는다 — `tonal` 분기를 추가해야 한다. `outline` 버튼의 테두리 색이 `outline` 에서 더 옅은 `outlineVariant` 로 바뀌어 outline 버튼을 쓰는 화면의 골든/스냅숏이 움직인다.

### 기능

* **core,figma,docs:** ✨ 소비 파일 점검 — 스타일 없이 그린 글자와 CoUI 컴포넌트 글자 덮어쓰기를 목록으로 ([#5745](https://github.com/coco-de/coui/issues/5745)) ([2b94ec9](https://github.com/coco-de/coui/commit/2b94ec95e99990ff3e8dd70957139f63609e2c2e))
* **core,flutter,web,figma,docs:** ✨ Button tonal 변형 추가 · outline 테두리를 outlineVariant 로 ([#5704](https://github.com/coco-de/coui/issues/5704)) ([4c94c21](https://github.com/coco-de/coui/commit/4c94c21c23572a2616f0f08fa405c9031421fc82))
* **core,flutter,web,figma,docs:** ✨ Fab 메뉴를 MenuItem lg 행과 Fab 자신의 패널로 바꾼다 ([#5713](https://github.com/coco-de/coui/issues/5713)) ([e8a6b3b](https://github.com/coco-de/coui/commit/e8a6b3bf728c3ffa6ea07de402b3dc0ac1c7a288))
* **core,flutter,web,figma,docs:** ✨ Sidebar 신설 — 사이드바와 부품 6개 ([#5738](https://github.com/coco-de/coui/issues/5738)) ([#5750](https://github.com/coco-de/coui/issues/5750)) ([c121408](https://github.com/coco-de/coui/commit/c121408fd75cf1321fc01fce7694280eae616fcc))
* **core,flutter,web,figma,docs:** ✨ Tag — 분류색으로 구분만 하는 표시 전용 태그 (새 컴포넌트) ([#5706](https://github.com/coco-de/coui/issues/5706)) ([fba5789](https://github.com/coco-de/coui/commit/fba57897ebcc5267c1a0560541e30cf9932c0da9))
* **core,flutter,web,figma,docs:** ✨ 상태 색 램프를 새 값으로 바꾸고 상태 표시 슬롯 넷을 더한다 ([#5726](https://github.com/coco-de/coui/issues/5726)) ([3d092c0](https://github.com/coco-de/coui/commit/3d092c0603a73627c41fd2e83cc4c16a9ef0fb6d))
* **core,flutter,web,figma,docs:** NavigationBar 선택 표시 축을 더하고 미선택 목적지를 연하게 그린다 ([#5744](https://github.com/coco-de/coui/issues/5744)) ([deb49b5](https://github.com/coco-de/coui/commit/deb49b5fe068a2d3a0518361629e778fae0c0b87))
* **core,flutter,web,figma,docs:** 입력 필드 경계를 한 톤 낮추고 filled 변형을 더한다 ([#5757](https://github.com/coco-de/coui/issues/5757)) ([0b0199e](https://github.com/coco-de/coui/commit/0b0199eaa4688109370780588654ef381b328ce8))
* **core,flutter,web,figma,docs:** 컨트롤 라벨 굵기 · destructive 평소 옅은 error-container ([#5719](https://github.com/coco-de/coui/issues/5719)) ([bac19fb](https://github.com/coco-de/coui/commit/bac19fb66f46310516fd0e719484f62222088c97))
* **core:** CoUI Light 비활성 글자를 neutral 400, Dark outline-variant 를 neutral 800 으로 옮긴다 ([#5751](https://github.com/coco-de/coui/issues/5751)) ([584aec6](https://github.com/coco-de/coui/commit/584aec6bdbe0e902f49690e2ac7a231f0c1d4591))
* **dot-indicator:** allow an elongated active marker ([#5737](https://github.com/coco-de/coui/issues/5737)) ([8ba1d24](https://github.com/coco-de/coui/commit/8ba1d248ef933be77feb1462011fd7a8efcc1198))
* **phone-input:** ✨ 전화번호 입력 필드 스타일 슬롯 추가 ([#5729](https://github.com/coco-de/coui/issues/5729)) ([b99be7b](https://github.com/coco-de/coui/commit/b99be7b2b33bdc8df27c973fcb4decb1b731864c))
* **radio-group:** ✨ 기본 높이를 보존하는 선택 패딩 슬롯 ([#5734](https://github.com/coco-de/coui/issues/5734)) ([76afcb8](https://github.com/coco-de/coui/commit/76afcb83cc6ab847ae02061df299317cfa588158))
* **select:** ✨ 비대화형 트리거 suffix 슬롯 지원 ([#5717](https://github.com/coco-de/coui/issues/5717)) ([277fe35](https://github.com/coco-de/coui/commit/277fe351598014abd8aa678ea31361e6407fee40))
* **tabs:** preserve long labels with opt-in horizontal scrolling ([4905b3d](https://github.com/coco-de/coui/commit/4905b3d1c393792bbf6fb358bcdcd2c496b29d95))
* **tabs:** support scrollable long labels ([8c12495](https://github.com/coco-de/coui/commit/8c124952603382172045d3188b0277ca79deb423))
* **text-field:** support optional caret height ([#5742](https://github.com/coco-de/coui/issues/5742)) ([6450212](https://github.com/coco-de/coui/commit/6450212cf24e96fa1c1dfa88b308a0eeed24a89f))
* **toggle:** ✨ 기본 외형을 보존하는 손잡이 그림자 슬롯 ([#5730](https://github.com/coco-de/coui/issues/5730)) ([7c46236](https://github.com/coco-de/coui/commit/7c462368dc6aa02230480472a919e917e4a34bfb))


### 버그 수정

* **badge:** wrap long labels within available width on Flutter and Web ([#5724](https://github.com/coco-de/coui/issues/5724)) ([7ae06d2](https://github.com/coco-de/coui/commit/7ae06d2899ce068d494c433333a36b78ab8075a2))
* **figma:** resolve core primitives in reader census ([#5754](https://github.com/coco-de/coui/issues/5754)) ([cc72667](https://github.com/coco-de/coui/commit/cc7266787123492e422bda6460f9ea81c76f4ff1))

## [0.164.0](https://github.com/coco-de/coui/compare/coui_core-v0.163.0...coui_core-v0.164.0) (2026-10-23)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma,docs:** CoreToastStyle.defaultMessageStyle 이 static const → static final(굵기 덧씌움 때문) — const 문맥에서 쓰던 코드는 컴파일되지 않는다. 기본 Toast 모습이 어두운 말풍선으로 바뀐다(Dark 에서는 밝은 말풍선).
* **core:** CoreTextStyle.merge 가 다른 역할을 나중에 얹으면 앞 역할 위의 크기 · 줄 높이 덧씌움을 더 이상 물려주지 않는다 — Flutter FormattedInput 36 → 39px, ObjectInput 양쪽(줄 18.2 → 21) · 웹 ChipInput 입력 줄이 역할이 정한 줄 상자로 돌아가며 굵기 · 서체 · 자간 · 색은 그대로 합쳐진다.

### 기능

* **core,flutter,web,figma,docs:** ✨ Dialog actionsLayout — 행동 버튼이 행의 폭을 채우는 stretch ([#5629](https://github.com/coco-de/coui/issues/5629)) ([#5674](https://github.com/coco-de/coui/issues/5674)) ([c025e7e](https://github.com/coco-de/coui/commit/c025e7e8eb60243ec8796466bd315c5e42cc5bdd))
* **core,flutter,web,figma,docs:** ✨ InputOtp lg 를 채운 칸으로 — surfaceContainer 면 · 입력 칸 primary 1.5, Show separator ([#5695](https://github.com/coco-de/coui/issues/5695)) ([5d8fd43](https://github.com/coco-de/coui/commit/5d8fd43a4066be2cc0afd3e21ef57ab9874306d4))
* **core,flutter,web,figma,docs:** ✨ Toast 기본을 디자이너 손편집의 어두운 말풍선으로 — inverse 쌍 · 모서리 16 · shadow-sm ([#5693](https://github.com/coco-de/coui/issues/5693)) ([cda01ea](https://github.com/coco-de/coui/commit/cda01ea7181a95e8421e8c922d81c956c3c6aa46))
* **core,flutter,web,figma:** ✨ Alert 제목을 톤의 색으로 — info · success · warning · destructive 는 on{Tone}Container ([#5683](https://github.com/coco-de/coui/issues/5683)) ([a548873](https://github.com/coco-de/coui/commit/a548873772c24c5413604ee9bff183867eeb9727))
* **core,flutter,web:** ✨ RadioGroup card 타일을 손편집 시안대로 — surface / primaryContainer 면, 선택 테두리 2, xl 타이틀 타일 ([#5694](https://github.com/coco-de/coui/issues/5694)) ([fcfbd29](https://github.com/coco-de/coui/commit/fcfbd297b9d4d46635643704b6dd48847f9e5493))
* **core,flutter,web:** ✨ 하단 바가 surface 면 · 12/8 패딩 · 기기 아래 안전 영역을 스스로 받는다 ([#5696](https://github.com/coco-de/coui/issues/5696)) ([717b997](https://github.com/coco-de/coui/commit/717b997f49bfca16e779575ce0158278178904e5))


### 버그 수정

* **core,flutter,web,docs:** 🐛 Scrollbar 가 내용 폭을 차지하지 않는다 — Web 은 오버레이 thumb, Flutter 는 스크롤러가 폭을 채운다 ([#5685](https://github.com/coco-de/coui/issues/5685)) ([#5697](https://github.com/coco-de/coui/issues/5697)) ([4898a60](https://github.com/coco-de/coui/commit/4898a60ba392936f44f3202595ddc829cd8756e3))
* **core,web:** 🐛 PhoneInput · ChipInput 안쪽 입력의 caret 이 잘리지 않게 모서리를 각지게 진술한다 ([#5676](https://github.com/coco-de/coui/issues/5676)) ([#5678](https://github.com/coco-de/coui/issues/5678)) ([2d8a3ee](https://github.com/coco-de/coui/commit/2d8a3eecb74e80a0a279016f8fd7fce426caa688))
* **core:** 🐛 나중에 진술한 다른 역할이 앞 역할의 크기·줄 상자를 이긴다 — FormattedInput 이 Flutter 에서 21px 줄을 잃던 것 ([#5677](https://github.com/coco-de/coui/issues/5677)) ([#5681](https://github.com/coco-de/coui/issues/5681)) ([f3e180b](https://github.com/coco-de/coui/commit/f3e180bbac32e49fcfb01a3368ea68a87f7d776b))


### 문서

* **docs,core:** 공개 문서와 예제에서 특정 서비스 이름 · 업종 문구를 걷어낸다 ([#5682](https://github.com/coco-de/coui/issues/5682)) ([18d84ed](https://github.com/coco-de/coui/commit/18d84ed4ac173ae5b0d3fa52968ba14bc5775b85))

## [0.163.0](https://github.com/coco-de/coui/compare/coui_core-v0.162.0...coui_core-v0.163.0) (2026-10-23)


### ⚠ BREAKING CHANGES

* **core,flutter,web:** Select 트리거 기본 폭이 내용 폭(intrinsic)에서 부모 폭 채움(expand)으로 바뀐다 — Flutter 에서 loose 한 부모(Center · Column · Wrap)는 hug 대신 가용 폭을 채우고, 웹은 입력창 기본 폭(≈200) 대신 부모 폭을 채운다. 가로가 무한한 부모(Row)에서는 이전처럼 내용 폭이다. hug 로 되돌리려면 `popoverStyle: CorePopoverStyle(triggerSizing: .intrinsic)` 을 준다.

### 기능

* **core,flutter,web,figma,docs:** ✨ Chip shape — 양 끝이 반원인 pill 모양 선택지 ([#5664](https://github.com/coco-de/coui/issues/5664)) ([dc464a1](https://github.com/coco-de/coui/commit/dc464a1539cb94a31338e5e94f649ee4392400d2))
* **core,flutter,web,figma,docs:** ✨ InputOtp size — 큰 칸 lg ([#5631](https://github.com/coco-de/coui/issues/5631)) ([#5665](https://github.com/coco-de/coui/issues/5665)) ([b2416a8](https://github.com/coco-de/coui/commit/b2416a8ab70f0223b33a78af79be55644a318f5e)), closes [#5663](https://github.com/coco-de/coui/issues/5663)
* **core,flutter,web,figma,docs:** Toast 아이콘을 끌 수 있게 — showIcon (기본 켜짐) ([#5628](https://github.com/coco-de/coui/issues/5628)) ([#5636](https://github.com/coco-de/coui/issues/5636)) ([affc0ad](https://github.com/coco-de/coui/commit/affc0ad389fb166b48351dfb0ebdd0cdf6b5865f))
* **core,flutter,web,figma:** ✨ AppBar prominent — 한 줄에 큰 제목 ([#5632](https://github.com/coco-de/coui/issues/5632)) ([#5655](https://github.com/coco-de/coui/issues/5655)) ([71fb07c](https://github.com/coco-de/coui/commit/71fb07c267f43c8941fff74ccca13b1ce9c86635))
* **core,flutter,web,figma:** ✨ BottomActionBar — 화면 아래 고정 행동 영역 (새 컴포넌트) ([#5654](https://github.com/coco-de/coui/issues/5654)) ([10fd256](https://github.com/coco-de/coui/commit/10fd256158a56110b1fa34ab52017574cdd9ff8b)), closes [#5633](https://github.com/coco-de/coui/issues/5633)
* **core,flutter,web,figma:** ChatBubble 꼬리 쪽 모서리 — tailEdge · tailCornerRadius ([#5599](https://github.com/coco-de/coui/issues/5599)) ([c30d65e](https://github.com/coco-de/coui/commit/c30d65ecd4e23b43587ae1726410a46e74ef9afd))
* **core,flutter,web,figma:** CodeSnippet 줄 톤 — lineTones (성공 · 경고 · 오류 줄 띠) ([#5591](https://github.com/coco-de/coui/issues/5591)) ([81f9c04](https://github.com/coco-de/coui/commit/81f9c0462b3af9001333ae4499df19a28cd163c2))
* **core,flutter,web,figma:** Drawer 하단 시트 — 손잡이 · 설명 · 닫기 버튼 끄기 ([#5589](https://github.com/coco-de/coui/issues/5589)) ([d05b923](https://github.com/coco-de/coui/commit/d05b923f7f553c3abd8e27df60a680eba5bd9461))
* **core,flutter,web,figma:** NavigationBar 선택 점 — selectionMark · Figma 글자 탭 자세 ([#5590](https://github.com/coco-de/coui/issues/5590)) ([ff96d8a](https://github.com/coco-de/coui/commit/ff96d8a4406c05e56ff47748918c895766a83c85))
* **core,flutter,web,figma:** NavigationBarItem — 바 밖에서 쓰는 사이드바 한 줄 ([#5596](https://github.com/coco-de/coui/issues/5596)) ([2a35b6a](https://github.com/coco-de/coui/commit/2a35b6a444921d69a100889935eec12267c21231))
* **core,flutter,web,figma:** PageHeader · PanelHeader — 좁으면 행동이 글 아래로 ([#5592](https://github.com/coco-de/coui/issues/5592)) ([dc9970e](https://github.com/coco-de/coui/commit/dc9970ef72a366579d0042a3b108257908fa42f8))
* **core,flutter,web,figma:** Tabs 닫기 × — CoreTabItem.onClose 를 Tabs 도 그린다 ([#5604](https://github.com/coco-de/coui/issues/5604)) ([05c8139](https://github.com/coco-de/coui/commit/05c81395b501d388fc880bdfbc386bdb9dfa5738))
* **core,flutter,web,figma:** 화면 충실도 — 비교 시트 잔여 공백과 플랫폼 결함 (Epic [#5551](https://github.com/coco-de/coui/issues/5551)) ([e3e56a9](https://github.com/coco-de/coui/commit/e3e56a94ae7f8805e3c0bf0af83429d34b54921e))
* **core,flutter,web:** MockupDevice 화면 밝기 — screenBrightness · BrightnessScope ([#5601](https://github.com/coco-de/coui/issues/5601)) ([2261b00](https://github.com/coco-de/coui/commit/2261b00b84f851dcd347552ed3fb48cf7980f53d))


### 버그 수정

* **core,flutter,web:** 🐛 Select 트리거가 부모 폭을 채운다 — 필드 트리거 popover 의 expand 를 Select 에도 ([#5649](https://github.com/coco-de/coui/issues/5649)) ([#5651](https://github.com/coco-de/coui/issues/5651)) ([39498bc](https://github.com/coco-de/coui/commit/39498bc4832427c1bf23df6c5a1eb4dc1b77127c))
* **core,flutter,web:** AppBar centerTitle 을 재질과 무관하게 바 전체 기준으로 — 밀림 · 말줄임 ([#5615](https://github.com/coco-de/coui/issues/5615)) ([b1d73fd](https://github.com/coco-de/coui/commit/b1d73fdbead2a40a38caae8a4f71744cb31b8bbe))
* **core,flutter,web:** Tree 노드 빌더 넷을 계약에 — CoreTreeContract&lt;W&gt; ([#5610](https://github.com/coco-de/coui/issues/5610)) ([2b21b91](https://github.com/coco-de/coui/commit/2b21b91580a7ffb207e5d705b0cf576c87060569))
* **figma,core:** export-dart — 굵기는 int, 자간은 em(이름에 단위) ([#5597](https://github.com/coco-de/coui/issues/5597)) ([5086cc7](https://github.com/coco-de/coui/commit/5086cc7d122f25635f2de476f137245901eee31d))

## [0.162.0](https://github.com/coco-de/coui/compare/coui_core-v0.161.1...coui_core-v0.162.0) (2026-10-21)


### ⚠ BREAKING CHANGES

* CoUI v2 — 모든 브랜드 · 앱의 기본 렌더가 바뀌고(Dark CTA 흰색, 글자 역할 · Geist Mono, 한 겹 그림자, 부품 기본값), Badge 는 tone × variant × form 으로, 여러 계약 · Resolved 타입에 필수 칸이 늘었다. 옛 코드 → 새 코드 표는 [#5587](https://github.com/coco-de/coui/pull/5587) 본문에 있다.

### 기능

* CoUI v2 — Draft.v2 를 새 기본 모습으로 ([#5587](https://github.com/coco-de/coui/issues/5587)) ([196b4a0](https://github.com/coco-de/coui/commit/196b4a04c163818021d2dff37ca100fdab5d5cb2))


### 버그 수정

* **core,flutter,web,figma:** MockupDevice 그림자를 v1 두 겹으로 되돌린다 ([#5585](https://github.com/coco-de/coui/issues/5585)) ([b75ca8d](https://github.com/coco-de/coui/commit/b75ca8d2990c4588b5fa6f83a33d1e118183d5d1))

### CoUI v2 — 승격 머지 커밋(#5587) 아래 들어간 하위 PR

* **P1 색:** v2 색 자리 — 새 슬롯 6개(`onSurfaceSubtle` · `surfaceRaised` · `syntax*` 4)와 공용 구문 그룹, 기존 팔레트 · 매핑은 그대로 ([#5493](https://github.com/coco-de/coui/pull/5493))
* **P1 색:** CoUI Dark · HCDark 의 주 액션을 neutral 로 — Dark CTA · 선택 컨트롤 · 포커스 링이 흰색 ([#5500](https://github.com/coco-de/coui/pull/5500))
* **P2 글자:** 글자 역할 22 · Geist Mono · 21px ([#5494](https://github.com/coco-de/coui/pull/5494))
* **P2 글자:** DescriptionCard md · lg 제목을 라벨 한 단 위로, FormattedInput · ObjectInput 값 글자를 `codeMd` 로 ([#5501](https://github.com/coco-de/coui/pull/5501))
* **P2 글자:** Text 체인의 역할 순서 · 코드 줄 배율 · 서체 스택 (#5495 · #5496 · #5497) ([#5514](https://github.com/coco-de/coui/pull/5514))
* **P3 기하:** modal 반경 20 · stroke 1.5 · space 18 · 한 겹 검정 그림자와 Dark 세기 · scrim 0.6 ([#5487](https://github.com/coco-de/coui/pull/5487))
* **P4 기본값:** 입력 — Button 아이콘 · 간격 · 라벨 600, 입력 활성 경계 1.5, Radio 켜진 고리, Toggle 폭, Kbd 면, Chip 6/8/10 ([#5521](https://github.com/coco-de/coui/pull/5521))
* **P4 기본값:** 표시 — Avatar · Progress sm, 중립 트랙, Alert 가운데 정렬, Toast 올린 면, Tooltip 꼬리 0, EmptyState compact, Stat 패딩 ([#5516](https://github.com/coco-de/coui/pull/5516))
* **P4 기본값:** navshell — 판 안 행 6 · MenuItem 36 · Tabs 굵기 · Dialog 640 · Card filled · 판 surfaceBright ([#5517](https://github.com/coco-de/coui/pull/5517))
* **P4 기본값:** 제품 — ChatBubble 판 · TabPane 에디터 스트립 · Tree 코드 서체 · CodeSnippet · CodeDiff · MockupCode ([#5518](https://github.com/coco-de/coui/pull/5518))
* **P5 구조:** Badge 축 재설계 — tone × variant(filled · tonal · outlined) × form, 기본 neutral · tonal · label · md ([#5522](https://github.com/coco-de/coui/pull/5522))
* **P5 구조:** 입력 — TextArea footer · RadioGroup card 타일 · Radio description · Chip prefixLabel ([#5535](https://github.com/coco-de/coui/pull/5535))
* **P5 구조:** 표시 — Steps list · 공개 StepItem, Alert inline · leading, Progress tone · 라벨 칸, Stat filled 기본 · 단위 · 설명, Avatar shape ([#5532](https://github.com/coco-de/coui/pull/5532))
* **P5 구조:** navshell — NavigationBar 모드 칸 · item.badge · footer, CommandSearch(새), AppBar dense, Tabs pill 트랙 ([#5534](https://github.com/coco-de/coui/pull/5534))
* **P5 구조:** 제품 — ChatBubble plain · 꼬리 기본 꺼짐, TabPane 표시줄 · 닫기 24, Tree 줄 28, MockupDevice flat, MockupCode tone ([#5533](https://github.com/coco-de/coui/pull/5533))
* **P6 Figma:** TreeItem · TabPaneTab 세트, DefinitionList rich 값, Checkbox Show label, NavigationBarItem 상태 축 ([#5550](https://github.com/coco-de/coui/pull/5550))
* **고침:** CodeSnippet 단색 면 복사 버튼 포커스 링 ([#5523](https://github.com/coco-de/coui/pull/5523))
* **고침:** Dark 떠 있는 판의 선 `outlineSubtle` 을 neutral/800 으로 ([#5529](https://github.com/coco-de/coui/pull/5529))
* **고침:** v2 의 `@Deprecated` 시작 버전을 0.162 로 ([#5543](https://github.com/coco-de/coui/pull/5543))
* **P7 기준선:** v2 전체 파리티 baseline 재촬영 — 2,966항목 · 11,008파일 ([#5548](https://github.com/coco-de/coui/pull/5548))

옛 코드 → 새 코드 표와 되돌리는 한 줄은 [#5587](https://github.com/coco-de/coui/pull/5587) 본문에 있다. MockupDevice 그림자는 v1 그대로다([#5585](https://github.com/coco-de/coui/pull/5585)).

## [0.161.1](https://github.com/coco-de/coui/compare/coui_core-v0.161.0...coui_core-v0.161.1) (2026-10-21)


### 버그 수정

* **flutter,web,core:** Liquid Glass AppBar의 네이티브 표면 구성 개선 ([#5545](https://github.com/coco-de/coui/issues/5545)) ([de5e46f](https://github.com/coco-de/coui/commit/de5e46f0f21a00e4fc6173661bf5ac71a6b880b1))

## [0.161.0](https://github.com/coco-de/coui/compare/coui_core-v0.160.0...coui_core-v0.161.0) (2026-10-19)


### 기능

* **figma:** AppBar leading · trailing 교체 슬롯 — props.slots 가 List&lt;W&gt; 를 repeated 로 담는다 (P6-b) ([#5512](https://github.com/coco-de/coui/issues/5512)) ([cc9e5cd](https://github.com/coco-de/coui/commit/cc9e5cd0fb80673efe4eacafa28db79fbafbe55e)), closes [#5509](https://github.com/coco-de/coui/issues/5509)
* Liquid Glass 내비게이션 제스처와 컴포넌트 재질 오버라이드 ([#5502](https://github.com/coco-de/coui/issues/5502)) ([24a90a2](https://github.com/coco-de/coui/commit/24a90a2f735728f13dee17676df24a5594e7e08a))


### 버그 수정

* align Web and Flutter Liquid Glass interactions ([#5506](https://github.com/coco-de/coui/issues/5506)) ([05d7eba](https://github.com/coco-de/coui/commit/05d7ebacd7b3938fc68fd5c308f76037c99fbb78))

## 0.127.15 (2026-06-16)

### Refactored
- #2585 — DaisyUI color 레이어 전면 제거 (color_style.dart 삭제 + chain naming M3화) (#2601)

---

## Unreleased

- feat(tree): shared node-to-folder drop rules and consumer-owned callback contract (#5090).
- feat(tree): `CoreTreeNode.canHaveChildren` and optional lazy/virtual Tree contract (#5081).

## [0.160.0](https://github.com/coco-de/coui/compare/coui_core-v0.159.0...coui_core-v0.160.0) (2026-10-16)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** `CoreButtonVariant.link` · `CoreButtonStyle.hoverTextDecoration` · `Text.thenButton` 을 지웠다 — 링크는 `Link` / `Link.inlineSpan` / `plain`, `thenButton` 은 `Text.thenLink` 로 옮기고, secondary · destructive · 비활성 글자색과 라이트 `error-pressed` 값이 바뀌었으며 DatePicker · TimePicker 오류 트리거는 destructive 대신 `errorTriggerStyle`(테두리 · 포커스 링 `error`)로 그린다.
* **core,web,figma:** ResolvedColorScheme 생성자가 분류색 45슬롯(categoryRed … categoryGrayOutline)을 required 로 받는다 — resolved() 로 만드는 경로는 그대로다.
* **core,flutter,web:** 꺼진 custom Chip 은 seedColor 를 칠하지 않고 neutral 과 같은 무채(라벨 on-surface · on-surface-variant, 테두리 outline-variant)로 그려진다. seedColor 는 켜진 칩에만 닿는다.
* **core,flutter,web,figma:** Progress 의 팔레트 getter(.primary · .secondary · .tertiary · .surface · .surfaceContainer · .error · .success · .warning · .info · .outline)가 트랙(backgroundColor) 대신 채움(color)을 칠한다 — 트랙 색이 필요하면 withStyle(CoreProgressStyle(backgroundColor: …)) 을 쓴다(.transparent 는 지금처럼 트랙을 비운다). Web Progress · RadialProgress 의 트랙이 원시 채움색에서 기본 primary 대신 그 색을 옅게 따라간다. CoreToggleVariantStyle 생성자가 필수 인자 disabledInactiveThumb 를 받고, 비활성 꺼진 Toggle 손잡이가 surface 에서 disabledContent 로 바뀐다. Flutter Dialog 본문 기본 색이 onSurface 에서 onSurfaceVariant 로 바뀌고(Web 과 같아짐), 색을 말하지 않는 leading · trailing 슬롯이 Material 바깥 기본값 대신 패널 전경(onSurface)을 받는다 — 본문을 되돌리려면 CoreDialogStyle(contentStyle: CoreTextStyle(color: CoreColor.token(CoreColors.onSurface))).
* **core,flutter,web,figma:** `KeyboardShortcut`(Flutter·Web), `CoreKeyboardShortcutContract`·`CoreKeyboardShortcutStyle`·`CoreKeyboardShortcutTheme`, `CoreComponentTheme.keyboardShortcut`, Flutter `KeyboardShortcutDisplayMapper`·`KeyboardShortcutDisplayHandle`·`KeyboardShortcutDisplayBuilder`, `CoreKbdStyle.separatorTextStyle` 이 예고 없이 제거됐다 — `KeyboardShortcut(keys: k)` → `Kbd(keys: k)`, `spacing: s` → `kbdStyle: CoreKbdStyle(keySeparatorSpacing: s)`, `fromActivator(activator: a)` → `Kbd(keys: kbdKeysFromActivator(a))`(수정키 순서 Ctrl → Alt → ⌘ → Shift 가 Ctrl → Alt → Shift → ⌘ 로 바뀐다); 그대로 치환하면 "+" 가 사라지고 키캡 간격 기본값이 space2 에서 space4 로 바뀌며, `CoreKbdContract` 에 `label` 이 추가되고 Kbd 하나는 접근 이름 하나로 읽힌다.
* **core,flutter,web,figma:** CoreChipColor 에서 secondary · tertiary 가 없어지고(neutral · primary · custom 만 남는다 — 분류 표시 색은 Badge), CoreChipStyle.defaultsByVariant 가 defaultsByColor 로 바뀌고, CoreChipTheme.variantStyles 의 키가 CoreChipColor 에서 CoreChipVariant 로 바뀌어 색 키는 colorStyles 로 옮겨야 하고, resolveChip · resolveChipRules 가 variant 를 필수로 받고, Chip 의 꺼진 high 는 어느 색이든 무채(라벨 onSurface · 테두리 outlineVariant)가 되고, Figma Chip 의 색 축 이름이 Variant 에서 Color 로 바뀌고 secondary · tertiary 변형이 은퇴한다.
* **core,flutter,web,figma:** `CoreLinkStyle.underlineOffset` · `defaultColor` · `defaultUnderlineColor` 와 `Link.inlineSpan(underline:)` 를 제거하고 `Link.underline` 기본값을 true 에서 false 로 바꿨다 — 단독 링크의 상시 밑줄이 사라지므로 밑줄이 필요한 곳은 `underline: true` 를, 색은 `variant`(standard · muted)를 쓴다
* **core,flutter,web,figma:** Chip 의 꺼진 low 는 어느 Variant 든 무채(라벨 onSurfaceVariant · 테두리 outlineVariant)가 되고, neutral 꺼진 high 의 테두리는 outlineVariant, neutral 켜진 high 의 채움은 inverseSurface(라벨 inverseOnSurface)로 바뀌며, Chip · ChipInput 의 라벨 굵기가 500 에서 400 으로 바뀌고, CoreChipStyle.defaultLabelStyle 과 defaultsBySize 가 const 에서 final 이 되어 const 문맥에서는 쓸 수 없다.
* **core:** CoUI 팔레트의 neutral 원시값 15개(`CouiColorPresets.palette.neutral`)가 채도 50% 값으로 바뀌어, neutral 을 쓰는 표면 · 글자 · 테두리가 두 모드 모두 덜 푸르게 렌더된다(흰 바탕 대비는 단계마다 0.12 이내로 같다). 이전 색이 필요하면 자체 `PrimitiveColors` 팔레트를 `CoreSemanticMappingSet.standard.bind` 로 묶은 `CoreSchemeSource` 를 넘긴다.
* **core,flutter,web,figma:** 포커스 링 간격 띠의 기본값이 surface 에서 투명으로 바뀌어 대부분의 컨트롤에서 링과 컨트롤 사이가 비어 보이고(바탕을 모르는 컴포넌트만 CoreFocusRing.opaqueOffsetColor 로 띠를 칠한다), Web 의 focusRingScopedRule 은 box-shadow 대신 outline 선언을 내며 important 파라미터는 무시된다(@Deprecated), focusRingIsClassSafe 는 이제 outline 이 클래스로 표현되고 띠가 칠해지지 않을 때만 true 이다.
* **core,flutter,web,figma:** 12개 컨트롤(TextField · TextArea · TimePicker · PhoneInput · InputOTP · ChipInput · ObjectInput · ItemPicker · FileInput · Checkbox · RadioGroup · MultipleChoice)의 enabled 테두리 기본값이 outline-variant 에서 outline 으로 바뀌어 렌더가 달라지고, 글자 입력 9곳의 hover 테두리는 on-surface 가 되며(TextField · TextArea 는 outline 에서 바뀌고, 나머지 7곳은 hover 테두리가 새로 생긴다), TextField 를 합성하는 Select · Autocomplete · ColorPicker 와 Fieldset 의 테두리도 함께 움직이고, Web FileInput 의 hover 는 primary 글자색 · 배경 대신 테두리 단계가 되며, CoreChipInputStyle · CoreObjectInputStyle · CoreItemPickerStyle · CorePhoneInputStyle · CoreInputOtpStyle · CoreFileInputStyle 에 hoverBorderColor 가 CoreTimePickerStyle 에 segmentHoverBorderColor 가 더해지고 Web resolveChipInputRules 는 enabled 를 required 로 받는다.
* **core,flutter,web:** Scrollbar 의 기본 모양이 바뀐다 — thumb 이 outline 불투명에서 on-surface 50% 알파로, 두께 7 에서 6 으로, 반경 4 에서 알약으로 바뀌고 가장자리에서 2 떨어진다. Web 은 스크롤바가 차지하는 폭이 7 에서 10 으로 늘어 내용 폭이 3 줄어든다. thin 의 두께는 3.5 에서 3 이 된다. CoreScrollbarStyle 에 thumbInset · hoverThumbColor · hoverThickness 가 추가될 뿐 제거 · 개명된 공개 표면은 없다.
* **core,figma:** Skeleton 기본값 렌더가 바뀐다 - 맥동 시작 50% -> 70%, rectangular 반경 4 -> 8, text 줄 16 / 간격 8 -> 12 / 12 (세트 높이 64 -> 60). 옛 모양을 지키려면 CoreSkeletonStyle(fromOpacity: CoreOpacity.opacity50, lineHeight: CoreSize.size16, lineSpacing: CoreSpace.space8, borderRadius: CoreBorderRadius.all(CoreRadius.radius4)) 로 덮는다. lineHeight 만 덮던 호출자는 간격이 8 -> 12 라 줄 사이가 4px 넓어진다.
* **core,flutter,web,figma:** 모든 Lucide 아이콘의 획이 크기 ÷ 12 에서 max(1.25, 크기 ÷ 16)(토큰 px)으로 바뀌어 렌더가 달라지고, CoreCheckboxStyle.defaultMarkThickness 가 1.5 에서 1.25 로 내려가며(일부 선택 가로줄 두께), Flutter resolveIcon 은 icon · data 인자를 받고 ResolvedIcon 은 svgString 을 요구하며 ResolvedCheckbox 는 checkmarkSize 를 없애고 disabledCheckmarkIconStyle 을 더한다.
* **core:** 라이트 모드의 outline-variant 가 neutral/200(#E4E6E9) 에서 neutral/300(#CDD1D7) 으로 한 단계 진해져, 이 슬롯을 쓰는 구분선 · 입력과 OutlinedContainer 테두리 · 비활성 표시가 라이트에서 더 진하게 렌더된다. 이전 색이 필요하면 라이트 스킴을 `CoreColorScheme.copyWith(outlineVariant: …)` 로 덮는다.

### 기능

* **core,figma:** Skeleton 리디자인 — 맥동 시작 70%, 사각형 반경 8, 텍스트 줄 12 / 간격 12 ([#5408](https://github.com/coco-de/coui/issues/5408)) ([c7fe05d](https://github.com/coco-de/coui/commit/c7fe05da77c0280980bf61185126261f2d06a1d1))
* **core,figma:** 밀도 · 그림자 · 재질을 Figma 라이브러리의 모드로 싣는다 ([#5427](https://github.com/coco-de/coui/issues/5427)) ([65618bb](https://github.com/coco-de/coui/commit/65618bb891da96f7e37371a6599bb3c8d3da055b))
* **core,figma:** 서페이스 스타일의 기하(반경 · 선 두께)를 Figma 모드로 고를 수 있게 한다 ([#5412](https://github.com/coco-de/coui/issues/5412)) ([75a88b5](https://github.com/coco-de/coui/commit/75a88b55b661a97d751008e47c5984967ddf4694))
* **core,flutter,web,figma:** Button 리디자인 — secondary 는 container 로, destructive 는 채움으로, link 는 걷어내고 피커 오류는 트리거 스타일로 옮긴다 ([#5486](https://github.com/coco-de/coui/issues/5486)) ([3a1ca62](https://github.com/coco-de/coui/commit/3a1ca6279c01fb04231674cecbe2cee446c85d20))
* **core,flutter,web,figma:** Chip 꺼진 low 를 무채로, neutral 선택을 반전 채움으로, 라벨을 400 으로 한다 ([#5450](https://github.com/coco-de/coui/issues/5450)) ([570d47d](https://github.com/coco-de/coui/commit/570d47d24304202fd8a89ea986412d71ab6c58ba))
* **core,flutter,web,figma:** Chip 색 축을 neutral · primary 둘로 줄이고 꺼진 모양 축 variant(outlined · filled)를 더한다 ([#5458](https://github.com/coco-de/coui/issues/5458)) ([b76d0f2](https://github.com/coco-de/coui/commit/b76d0f2eb675bc847c9705b517a25f2dc2eca59e))
* **core,flutter,web,figma:** Kbd 키캡 리디자인 — surface 채움 · outline-subtle 헤어라인 · 키마다 shadow/xs ([#5407](https://github.com/coco-de/coui/issues/5407)) ([d93a927](https://github.com/coco-de/coui/commit/d93a927fba86f85a9c910fbc9ec21acbe64de86c))
* **core,flutter,web,figma:** Kbd 키캡을 나란히 놓고 한 이름으로 읽으며 KeyboardShortcut 을 지운다 ([#5473](https://github.com/coco-de/coui/issues/5473)) ([9eab38a](https://github.com/coco-de/coui/commit/9eab38afc10159d4422cbc29e9f068484bdc0951))
* **core,flutter,web,figma:** Label 비활성 글자 · 필수 표시 · 아이콘을 disabled-content 한 색으로 칠한다 ([#5403](https://github.com/coco-de/coui/issues/5403)) ([fe9619a](https://github.com/coco-de/coui/commit/fe9619ac837457119835e14b6e4f1d42985508e1))
* **core,flutter,web,figma:** Link 리디자인 — 시맨틱 색 link, Variant × Underline, 상호작용 밑줄 ([#5451](https://github.com/coco-de/coui/issues/5451)) ([35c7cb2](https://github.com/coco-de/coui/commit/35c7cb21265162179e4e5a4b86e642ae08f6bad8))
* **core,flutter,web,figma:** Lucide 아이콘 획을 크기가 정하는 규칙 하나로 — 체크박스 가로줄은 규칙 하한에 맞춘다 ([#5399](https://github.com/coco-de/coui/issues/5399)) ([f2ff87e](https://github.com/coco-de/coui/commit/f2ff87e98a54e36d8c309ba95dd17c561715ef86))
* **core,flutter,web,figma:** 컨트롤 경계를 outline 으로, 글자 입력 hover 를 on-surface 로 — 아홉 컨트롤에 hover 테두리 단계를 둔다 ([#5416](https://github.com/coco-de/coui/issues/5416)) ([483e573](https://github.com/coco-de/coui/commit/483e573c899fe4435715967815fa4b758325b1e7))
* **core,flutter,web,figma:** 포커스 링 간격 띠를 기본 투명으로 하고 바탕을 모르는 곳만 surface 로 칠한다 ([#5425](https://github.com/coco-de/coui/issues/5425)) ([c2f7d9c](https://github.com/coco-de/coui/commit/c2f7d9c34514c3904416c3d39c2ae4cf66352ef7))
* **core,flutter,web:** Scrollbar 리디자인 — 알약 thumb · 가장자리 여백 · hover 두께 ([#5409](https://github.com/coco-de/coui/issues/5409)) ([cc770c3](https://github.com/coco-de/coui/commit/cc770c396f8efb668f039b31629c3898fe229b1a))
* **core,flutter,web:** 밀도 축 — 간격 · 컨트롤 행 높이 · 행의 모서리를 사다리 위에서 한 칸 옮긴다 ([#5426](https://github.com/coco-de/coui/issues/5426)) ([f83b8bc](https://github.com/coco-de/coui/commit/f83b8bcab954add88c97cf5cb19515ddbec2e772))
* **core,flutter,web:** 밀도 축 후속 — 사다리에 앉은 필드 셋 · resolver 로 올린 간격 · 양쪽에 닿는 여백 ([#5436](https://github.com/coco-de/coui/issues/5436)) ([642e9db](https://github.com/coco-de/coui/commit/642e9db2a082b6b026c85a64691ea6d0a815540a))
* **core,flutter,web:** 타입 스케일의 역할에 서체를 적어 제목에 표시용 서체를 쓸 수 있게 한다 ([#5410](https://github.com/coco-de/coui/issues/5410)) ([81351d9](https://github.com/coco-de/coui/commit/81351d9ee56a6e8340eba515f60a72bf3aee8739))
* **core,flutter,web:** 한국어 어절 단위 줄바꿈 — Text 체인의 keepAll ([#5457](https://github.com/coco-de/coui/issues/5457)) ([6c03a48](https://github.com/coco-de/coui/commit/6c03a48807249e3589c560aa02e03d0bcb58be02))
* **core,web,figma:** 브랜드 밖 분류색(category) — 시맨틱 45슬롯과 원시값 117개를 더한다 ([#5474](https://github.com/coco-de/coui/issues/5474)) ([d635e4a](https://github.com/coco-de/coui/commit/d635e4a17eebfbcae6ad874693b515cf56b89f5e))


### 버그 수정

* **core,flutter,web,figma:** 두 플랫폼 결함 넷 — Dialog 글자색 출처 · Progress 색 체인 · TabPane tabPadding · 비활성 Toggle 꺼진 손잡이 ([#5476](https://github.com/coco-de/coui/issues/5476)) ([85df32c](https://github.com/coco-de/coui/commit/85df32c36bd7ba98cfdec3893a5f88930893d66e))
* **core,flutter,web:** 꺼진 custom Chip 을 neutral 과 같은 무채로 그린다 ([#5477](https://github.com/coco-de/coui/issues/5477)) ([464517d](https://github.com/coco-de/coui/commit/464517d2309245d94fdb9f82387616c105036eab))
* **core:** neutral 원시값 채도를 50% 로 낮춘다 ([#5447](https://github.com/coco-de/coui/issues/5447)) ([86355b8](https://github.com/coco-de/coui/commit/86355b88427b965c67366afcca57e35f0b0ddf3b))
* **core:** outline-variant 라이트 값을 neutral/300 으로 올린다 ([#5402](https://github.com/coco-de/coui/issues/5402)) ([0ca0d18](https://github.com/coco-de/coui/commit/0ca0d1817f97fd36b3f55b8876d4b5a2a763c44d))
* **core:** 아이콘 생성기가 lib 안에 스크래치 파일을 쓰지 않는다 — 익스포터 테스트 경합 ([#5455](https://github.com/coco-de/coui/issues/5455)) ([7093ed1](https://github.com/coco-de/coui/commit/7093ed1021ad85180935552235177c351723f77f))

## [0.159.0](https://github.com/coco-de/coui/compare/coui_core-v0.158.1...coui_core-v0.159.0) (2026-10-12)


### ⚠ BREAKING CHANGES

* **core,flutter,web:** CoUI `:root` 의 프리미티브 CSS 변수 64개(`--coui-neutral-pure-white` … `--coui-error-darkest`)가 `--coui-<family>-<step>` 67개로 바뀌고 CoUI 기본 테마 색이 바뀐다(브랜드 PrimitiveColors 출력은 그대로). `CoreSurfaceToken.opacity` 의 타입이 `double` 에서 `CoreSurfaceOpacity` 로 바뀐다(`opacityIn(theme)` 또는 `.light` · `.dark` 로 읽는다). `ResolvedColorScheme` 생성자가 `outlineSubtle` 을 required 로 받는다. display · title 역할 굵기가 700 이 되고 Card 머리글 · Footer 섹션 제목 · EmptyState 제목이 역할 굵기를 따른다(Steps · Stepper 는 지금 단계만 700). 컨트롤 반경이 크기마다 달라진다(xs 6 · sm 8 · md 10 · lg 12 · xl 14 · xl2 16, 크기 없이 합성된 버튼 · 입력은 md 10). `CategoryBreakdown` 기본 범주 색에서 `tertiary` 가 빠진다(7 → 6색). `CoreMockupDeviceStyle` 의 하드웨어 색 기본값 12개가 Semantic 고정 슬롯에서 디자이너 사본 hex 로 바뀌어, 기기 몸체가 브랜드 테마에서도 브랜드 primary 를 따르지 않는다.
* **core,flutter,web:** Flutter · Web `TripleDots`, `CoreTripleDotsContract` · `CoreTripleDotsStyle` · `CoreTripleDotsTheme`, `CoreComponentTheme.tripleDots` 를 제거했다. 대체는 `Icon(LucideIcons.ellipsis)` (세로는 `LucideIcons.ellipsisVertical`)이고, count · dotSize · spacing 은 대응이 없으며 색은 `iconStyle` 로, 접근 가능한 이름은 호출하는 쪽이 붙인다.

### 기능

* **core,flutter,web:** CoUI 컬러 개편 — 고정 hex 숫자 단계 팔레트 · primary 잉크 · tertiary = primary ([#5339](https://github.com/coco-de/coui/issues/5339)) ([1c3de79](https://github.com/coco-de/coui/commit/1c3de79bea3e4d87a00cc0e591f8f10833c79bc6))
* **core,flutter,web:** TripleDots 를 제거한다 — 대체는 Icon(LucideIcons.ellipsis) ([#5390](https://github.com/coco-de/coui/issues/5390)) ([6990968](https://github.com/coco-de/coui/commit/6990968a9f29c218d070357637d9960d04c8a47c))

## [0.158.1](https://github.com/coco-de/coui/compare/coui_core-v0.158.0...coui_core-v0.158.1) (2026-10-11)


### 버그 수정

* **flutter,web:** Pagination 행이 가용 폭을 넘으면 단계적으로 줄인다 ([#5365](https://github.com/coco-de/coui/issues/5365)) ([e4b4ddd](https://github.com/coco-de/coui/commit/e4b4ddd3d2472e5666bee14e33621ee178514ac9))

## [0.158.0](https://github.com/coco-de/coui/compare/coui_core-v0.157.0...coui_core-v0.158.0) (2026-10-10)


### ⚠ BREAKING CHANGES

* **core:** MockupBrowser의 기본 렌더가 툴바 오버레이와 캡슐 구조로 바뀌고, 기본 chromeWidth가 6에서 0으로, radius가 16에서 14로, 주소 텍스트가 labelMedium에서 labelSmall로 바뀌며 신호등이 시맨틱 상태색을 따릅니다. 기존 속성 이름과 동작은 유지합니다.
* **mockup:** CoreMockupDeviceLayout.compute callers must provide systemBarReferenceScale and landscapeSystemBarReferenceScale. MockupDevice system chrome now retains its authored dimensions when width changes; explicit reference-scale style overrides control its size.

### 기능

* **core,flutter,web:** 라벨 SwitchField·Checkbox 행에 테마로 켜는 최소 높이 슬롯 ([#5357](https://github.com/coco-de/coui/issues/5357)) ([fabc35b](https://github.com/coco-de/coui/commit/fabc35bc2a2ff2027487ffcdc6ac15d5a3d815bf))
* **core,flutter,web:** 추이 차트 TrendChart — 시계열 선 · 막대 + 기간 칩 + 요약 슬롯 ([#5360](https://github.com/coco-de/coui/issues/5360)) ([aad6259](https://github.com/coco-de/coui/commit/aad6259d50eb674dace93c380de1cbe3f11f3d9e))
* **core,flutter,web:** 카테고리 분포 CategoryBreakdown — 가로 막대 · 도넛 + 범례 · 접근성 ([#5362](https://github.com/coco-de/coui/issues/5362)) ([d77192c](https://github.com/coco-de/coui/commit/d77192ccf0954efe8b3f79a2f7eac3abb187a2b7))
* **core:** MockupBrowser 툴바·캡슐 리디자인 ([#5343](https://github.com/coco-de/coui/issues/5343)) ([33b5c33](https://github.com/coco-de/coui/commit/33b5c3365d58299aa2b4889ad8a58571ff0f442f))
* **flutter,web:** 컴포넌트 chrome 11개 언어 — slang 단일 원본 + slang_gpt ([#5354](https://github.com/coco-de/coui/issues/5354)) ([5797ca7](https://github.com/coco-de/coui/commit/5797ca72adeff2f96dd68a0e75f723225002d0dc))


### 버그 수정

* **flutter,web:** Pagination 라벨 모드 이전/다음 버튼 폭을 콘텐츠로 정한다 ([#5363](https://github.com/coco-de/coui/issues/5363)) ([1545281](https://github.com/coco-de/coui/commit/1545281332b13d394fe17a828dc1433f78fbca52))
* **flutter:** 컴포넌트 기본 아이콘을 패키지에 번들해 네트워크 없이 그린다 ([#5358](https://github.com/coco-de/coui/issues/5358)) ([e67dbf5](https://github.com/coco-de/coui/commit/e67dbf5afe27c9a29b95f75eb02a91860d868530))
* **mockup:** preserve system chrome geometry when resizing ([#5345](https://github.com/coco-de/coui/issues/5345)) ([e53e4cc](https://github.com/coco-de/coui/commit/e53e4cc4f00c454e574e21f6d8fdef9a7de7ca33)), closes [#5344](https://github.com/coco-de/coui/issues/5344)

## [0.157.0](https://github.com/coco-de/coui/compare/coui_core-v0.156.0...coui_core-v0.157.0) (2026-10-08)


### ⚠ BREAKING CHANGES

* **core,flutter,web:** MockupDevice 의 gestureBarHeight · gestureBarOffset 단위가 px 에서 iOS pt × 화면 배율로 바뀌고 gestureBarWidthRatio 는 deprecated 이며, CoreMockupDeviceLayout.compute · safeAreaInsets 의 시그니처와 ResolvedMockupDevice 필드가 바뀌고, mockupDeviceStyle.containerStyle.backgroundColor 로는 몸체 색을 더 이상 바꿀 수 없으며 (railColor · frameColor 를 쓴다), 하드웨어 기본 색이 hex 에서 Semantic 고정 슬롯으로 바뀌어 기본 모노크롬에서는 몸체 중간이 더 어둡고(#7d7f82 → #4d4e51) 렌즈 코어의 파란 링이 회색조가 되며 브랜드 램프를 읽는 매핑에서는 기기가 브랜드 색을 띤다

### 기능

* **core,flutter,web:** MockupDevice 리디자인 — 기기 모양 · 상태 표시줄 · 홈 인디케이터를 디자이너 사본대로 그린다 ([#5333](https://github.com/coco-de/coui/issues/5333)) ([f7a292c](https://github.com/coco-de/coui/commit/f7a292cd81984043d93eede87029f310c5e09db2))

## [0.156.0](https://github.com/coco-de/coui/compare/coui_core-v0.155.0...coui_core-v0.156.0) (2026-10-08)


### 기능

* **core:** 반경 역할 토큰 CoreRadiusRole — 부품 4 · 컨트롤 8 · 패널 12 · 표면 16 ([#5337](https://github.com/coco-de/coui/issues/5337)) ([5214c89](https://github.com/coco-de/coui/commit/5214c89420cf92699ba9d237a96c42885d31c9eb))

## [0.155.0](https://github.com/coco-de/coui/compare/coui_core-v0.154.0...coui_core-v0.155.0) (2026-10-07)


### ⚠ BREAKING CHANGES

* **core,flutter,web:** `CoreSkeletonStyle.duration` 은 이제 두 플랫폼 모두 맥동 왕복 한 번(쉼 → 정점 → 쉼)의 길이이고 기본값은 2000ms 다 — Flutter 에서 `duration` 을 직접 넘기던 호출자는 같은 값으로 두 배 빠르게 맥동하므로 지금 속도를 지키려면 값을 두 배로 넘긴다(Web 은 뜻이 같다).
* **core,flutter,web:** Skeleton(Flutter · Web)의 기본 생성자 · Skeleton.circle · Skeleton.text · copyWith 에서 enabled 파라미터가, CoreSkeletonContract 에서 enabled getter 가 제거됐다 — `Skeleton(enabled: isLoading)` 은 `if (isLoading) Skeleton(...)` 로 옮긴다. enabled: false 가 남기던 자리가 없어지므로 형제를 세어 간격을 주는 레이아웃(Flutter Column(spacing:), Web space-y-*)에서는 간격이 한 칸 줄어든다. asSkeleton(enabled:) 는 그대로다.

### 기능

* **core,flutter,web:** LoadingRegion — 로딩 알림을 영역 단위 한 번으로 ([#5309](https://github.com/coco-de/coui/issues/5309)) ([ad8aebc](https://github.com/coco-de/coui/commit/ad8aebc1464fb7ee42019e4a42fdfad626658615)), closes [#5281](https://github.com/coco-de/coui/issues/5281)
* **core,flutter,web:** Skeleton 의 enabled 를 제거한다 — 그릴지는 호출하는 쪽 조건이 정한다 ([#5275](https://github.com/coco-de/coui/issues/5275)) ([751cb4f](https://github.com/coco-de/coui/commit/751cb4f0c8d13db35e26278c907613c2edf41278))
* **core,flutter,web:** Tree 노드별 맥락 메뉴 — 행 우클릭에 ContextMenu 항목 (nodeContextMenu) ([#5273](https://github.com/coco-de/coui/issues/5273)) ([766ee95](https://github.com/coco-de/coui/commit/766ee9559bdd365e98a43a8a36e64a00adb68584))
* **core,flutter,web:** 동작 줄이기에서 Skeleton 맥동을 쉼 끝에 멈춘다 ([#5307](https://github.com/coco-de/coui/issues/5307)) ([d21f267](https://github.com/coco-de/coui/commit/d21f2673d6de056c2390f8d3858d0e4fb9a0e4f8)), closes [#5280](https://github.com/coco-de/coui/issues/5280)
* **core:** a11y/pointer-target-min 24 를 내보내고, 장치가 지키는 24 를 그 값 하나로 읽는다 ([#5292](https://github.com/coco-de/coui/issues/5292)) ([21ba169](https://github.com/coco-de/coui/commit/21ba1698ad8f0d5d3d9d1f96683a17bac0b74e1e)), closes [#5223](https://github.com/coco-de/coui/issues/5223)
* **core:** Skeleton 채움을 surface-container-highest 로, rectangular 반경을 4 로 ([#5288](https://github.com/coco-de/coui/issues/5288)) ([0a55370](https://github.com/coco-de/coui/commit/0a553703cb78468848b4f83c42669167e0e5915a))
* **flutter:** asSkeleton · SkeletonTheme 폐기 예고 — 대체는 Skeleton + LoadingRegion ([#5310](https://github.com/coco-de/coui/issues/5310)) ([9c318b6](https://github.com/coco-de/coui/commit/9c318b6fc99cb8a8822748d01b83840c9f493f3d))
* **toggle:** 스위치에 전환 중에만 뜨는 유리 렌즈를 단다 ([#5196](https://github.com/coco-de/coui/issues/5196)) ([ae43134](https://github.com/coco-de/coui/commit/ae431340e562c006093995d370ce962ab513dc75))


### 버그 수정

* **core,flutter,web,figma:** TextField 상자가 control-size 를 최소 높이로 읽는다 — md 이상이 Button · 캔버스와 같은 높이 ([#5284](https://github.com/coco-de/coui/issues/5284)) ([f77427d](https://github.com/coco-de/coui/commit/f77427def287a6c065de9c7a3ac6efa44e7e427d)), closes [#5222](https://github.com/coco-de/coui/issues/5222)
* **core,flutter,web:** Skeleton 맥동 duration 을 왕복 한 번으로 — 두 플랫폼 같은 속도 · 같은 곡선 ([#5289](https://github.com/coco-de/coui/issues/5289)) ([151c820](https://github.com/coco-de/coui/commit/151c820de9ca75f8ebfca7bc0beaa2f3306ab667)), closes [#5279](https://github.com/coco-de/coui/issues/5279)
* **core:** 대비 게이트가 CoUI 가 실제로 그리는 매핑을 잰다 ([#5320](https://github.com/coco-de/coui/issues/5320)) ([8e36056](https://github.com/coco-de/coui/commit/8e36056ea3eaf58548f4011933c8cc78f18dcee6))
* **figma:** 캔버스가 코드와 같은 모양을 그리게 맞춘다 — 기본값 · Tabs 탭 3 · 아이콘 크기 ([#5308](https://github.com/coco-de/coui/issues/5308)) ([70766d5](https://github.com/coco-de/coui/commit/70766d55f98c68c819c3b8b847cdd9a6a37e33c3))

## [0.154.0](https://github.com/coco-de/coui/compare/coui_core-v0.153.0...coui_core-v0.154.0) (2026-10-03)


### 기능

* **core,flutter,web:** Tree 이름 바꾸기를 밖에서 시작하는 컨트롤러 (CoreTreeController) ([#5253](https://github.com/coco-de/coui/issues/5253)) ([b258990](https://github.com/coco-de/coui/commit/b25899019c56c038e6658380039b67597a658f4e))
* **core:** 색 대비 비율 · 상대 휘도 · WCAG 판정을 공개 API 로 제공한다 ([#5257](https://github.com/coco-de/coui/issues/5257)) ([9eb0393](https://github.com/coco-de/coui/commit/9eb039354957602078b6e1ecb6d48939b8c1a07f)), closes [#5255](https://github.com/coco-de/coui/issues/5255)

## [0.153.0](https://github.com/coco-de/coui/compare/coui_core-v0.152.0...coui_core-v0.153.0) (2026-10-03)


### 기능

* **core,flutter,web:** Calendar 에 날짜 마커를 그린다 — 날짜별 점 · 개수 · 접근성 레이블 ([#5258](https://github.com/coco-de/coui/issues/5258)) ([76d3f46](https://github.com/coco-de/coui/commit/76d3f46b655fd86a01802d71859b047d0a6311fd))
* **core,flutter,web:** Tree 폴더 행 누름으로 여닫기 · 인라인 이름 바꾸기 (더블클릭 · F2) ([#5250](https://github.com/coco-de/coui/issues/5250)) ([f60a7a1](https://github.com/coco-de/coui/commit/f60a7a1519716dfb703c4cfb0ebd72844f484d57))
