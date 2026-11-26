## Unreleased

- Ignore NumberTicker's queued initial animation after disposal while preserving its active interpolation and public API (#6553).
- Keep disabled ColorPicker panels visible while blocking keyboard and pointer edits, preserving external color/history updates and ignoring late eyedropper results after disable or disposal (#6548).
- Hide ColorPicker's eyedropper on unsupported hosts after client initialization, preserving initial SSR and supported-host output (#6543).
- Let both non-flip Swap faces reserve their natural size and share the clickable region, with parent constraints and caller CSS priority preserved (#6487).
- feat: opt-in adaptive AppBar action rails through Scaffold, shared glass capsules, physical safe-area detection and mixed text/icon groups.

## Unreleased

- The floating liquid-glass `NavigationBar` (bar and rail) grows by 3 % while its lens is held or still travelling, through the CSS `scale` and `transform-origin` of the bar, about the same point and on the same spring as Flutter. The runtime measures the bar as it is drawn and places the lens and reads the finger in the bar as it is laid out, so the lens stays on its destination while the bar is grown. Reduced motion keeps the bar at rest.
- `CoUIWeb` states a page transition in the document head: a page opened by a link rises into place while it fades in, and a step back plays the page left sinking and fading over the page returned to — the motion and timing Flutter uses, from `CorePageTransitionStyle`. It reaches server-rendered and pre-built pages navigated as documents; a reduced-motion request, or both durations at zero, turns it off. While it plays Chrome sends clicks to the document, so the page takes clicks again when it ends. Adds `resolvePageTransitionRules` / `ResolvedPageTransitionRules`.
- Add `FoldScope.of(context)`: `CoUIWeb` reads the browser's viewport segments and its posture media query (Chromium) and publishes them through the shared `CoreFoldLayout` rule, so a page reads the same segments, kind and posture as Flutter. A browser reports segments only while the fold splits the page, so a seamless screen lying flat reads as no fold; Safari and Firefox report none.
- On a screen a fold splits, the `Dialog` panel opens in one segment — the one at the top of the reading start, where Flutter's dialog route opens it — centred on it and sized by it through `env(viewport-segment-*)`.
- The `Dialog` panel's width, its 640 cap and its height cap now take in its padding and border (`box-sizing: border-box`), as Flutter's do: it was 48 px wider than its Flutter twin on a wide page and ran past a narrow one.
- Add `IndexedSwitcher`: every child stays in the document in one grid cell, hidden slots are `inert` and `visibility: hidden`, and the switch is a CSS fade through on the `--coui-duration-*` variables, so a reduced-motion request makes it instant.
- Draw a FadeScroll at its start before its measurer runs: the leading edge no longer fades on first paint, matching Flutter's settled viewport, while the trailing fade stays (#6131).
- Centre the Accordion chevron on its trigger row and turn it about its own centre, as Flutter does; the icon sat on the label's text line and rotated about that line, 1.5px off in both states (#6131).
- State `--coui-stroke-width-1_5` as 1px below a 2x screen and 1.5px from 2x up, in the same media rule as the hairline, so every browser and every non-border use of the step agree with Flutter's frame (#6131).
- Draw every text line box on a whole pixel, the box Flutter's text engine lays each line out in, so text stacks to the same height on both platforms; role classes and inline line heights round, and the multiplier still reaches text that changes only its size (#6131).
- Reserve the caret room Flutter's selectable text keeps after its glyphs on SelectableText and CodeSnippet, so both are as wide as their Flutter twins (#6131).
- Let the FileInput drop zone fill its clickable host when a caller supplies a width, while preserving intrinsic sizing without a width (#6131).
- Keep dashed and dotted SVG corners on the existing radius token path so Frame, Button, OutlinedContainer, FileInput, and ColorPicker follow the active surface geometry (#6131).
- Preserve explicit updates, repeated settlements, and reuse of the public DrawerScrubController across Drawer mounts while ignoring late input from cancelled Swiper gestures.
- Match Loading.bar's full-cycle easing and sine motion to Flutter, and keep Swiper pointer tracking alive through the modal inert backdrop with complete gesture cleanup (#6294, #6296).
- Paint the Tabs underline inside its existing height, keep responsive columns content-sized unless stretched, and preserve selected ToggleGroup label weight when disabled (#6288, #6290, #6292).
- Draw the Loading spinner's existing Core arc from noon with round caps, matching Flutter without changing its public API (#6293).
- Add optional `NumberInput.errorText`, expose TextField error state on the actual input with `aria-invalid`, and localize Calendar navigation names.
- Preserve TextField placeholder typography independently of its value, including body hints over code values (#6275).
- Keep Toast content beside its icon, let Accordion follow parent width constraints, and restore the icon-only navigation rail's Core minimum width (#6274, #6276, #6277).

## [0.192.0](https://github.com/coco-de/coui/compare/coui_web-v0.191.0...coui_web-v0.192.0) (2026-11-24)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** `Fieldset` 의 기본 모양이 채운 패널(`filled`)로 바뀌고(모서리 24→16, 테두리 `outline`→`outline-subtle`, 필드 사이 24→16, 범례 가로 여백 8→0), `CoreFieldsetContract` 에 `description` · `variant` getter 가 더해져 계약을 직접 구현하는 코드는 둘을 구현해야 한다.

### 기능

* **core,figma:** Window 스냅 바 · 칸 · 미리보기를 리디자인 사본대로 ([#6646](https://github.com/coco-de/coui/issues/6646)) ([1d82058](https://github.com/coco-de/coui/commit/1d820587ce435f38bb5c7556c8c712a75a13bdce))
* **core,flutter,web,figma:** Fieldset 변형(filled · outlined · plain) · 설명 줄 · 필드 간격 16 · 모서리 16 ([#6668](https://github.com/coco-de/coui/issues/6668)) ([4f26cfb](https://github.com/coco-de/coui/commit/4f26cfb5111e80812e9d891ad8b4d87429dc1ef5))
* **core,flutter,web,figma:** WindowPanel 기본 모양을 리디자인 사본에 맞춘다 ([#6641](https://github.com/coco-de/coui/issues/6641)) ([8d08756](https://github.com/coco-de/coui/commit/8d08756e8e4fd18788a9f7a429450c801d2d1e8d))
* **dialog:** 패널 폭 560 · 280 과 barrier 딤 opacity/scrim 연결 ([#6664](https://github.com/coco-de/coui/issues/6664)) ([f542b35](https://github.com/coco-de/coui/commit/f542b358b694cea2e62430e77e00bfb2e340b0b8))


### 버그 수정

* **core,figma:** WindowPanel 닫기 × 의 평소 색을 리디자인 사본대로 surface-variant 로 ([#6663](https://github.com/coco-de/coui/issues/6663)) ([3c91379](https://github.com/coco-de/coui/commit/3c9137952b5a7d8f041908b048a97b0edb726c7f))
* **web:** 입력 포커스 색을 실제 프레임 테두리에 적용 ([#6648](https://github.com/coco-de/coui/issues/6648)) ([3eda7b0](https://github.com/coco-de/coui/commit/3eda7b0ba17123841c30f858778f4257d93831cb))
* **web:** emit selection and footer focus through paint protocols ([#6629](https://github.com/coco-de/coui/issues/6629)) ([#6638](https://github.com/coco-de/coui/issues/6638)) ([00440fc](https://github.com/coco-de/coui/commit/00440fcd74fb7d7b629ba443b1eb5199ebd77835))
* **web:** TextArea raw 테두리와 disabled 프레임 색상 반영 ([#6670](https://github.com/coco-de/coui/issues/6670)) ([21d59bc](https://github.com/coco-de/coui/commit/21d59bce0014804aac3bb7bf0c7f9f6d06100df1))

## [0.191.0](https://github.com/coco-de/coui/compare/coui_web-v0.190.1...coui_web-v0.191.0) (2026-11-23)


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
* **description-card:** 크기마다 여백 · 모서리 · 행 간격을 두고 enabled 를 더한다 (6500) ([55baaf1](https://github.com/coco-de/coui/commit/55baaf1a12359b51753e0c7bda7aed83e4a9c16d))
* **dock:** 막대를 둥근 판으로 그리고 앱 칸을 가운데로 모은다 (6506) ([3dc4b90](https://github.com/coco-de/coui/commit/3dc4b90a7c350c1b1d83bc175801cb7d75697b80))
* **empty-state:** compact 를 패널 안의 빈 자리답게 조인다 ([#6480](https://github.com/coco-de/coui/issues/6480)) ([704346f](https://github.com/coco-de/coui/commit/704346fc79b45345a7cbb5323a4442893d333931))
* **input-otp:** 칸에 커서를 두고 빈 칸과 채운 칸을 바탕 · 테두리로 가른다 (6495) ([9f66a2b](https://github.com/coco-de/coui/commit/9f66a2bb95eb551ca39ab195fcb881f8f1936175))
* **mockup:** 접힘 각도를 조절하는 MockupFoldable 을 추가한다 ([#6510](https://github.com/coco-de/coui/issues/6510)) ([666ac00](https://github.com/coco-de/coui/commit/666ac00da3eccbb1a32131578428ff9ed7dbc949))
* **option-item:** 선택 항목을 테두리 있는 카드로 그린다 ([#6485](https://github.com/coco-de/coui/issues/6485)) ([93285d6](https://github.com/coco-de/coui/commit/93285d656d3a85f060810e9031a9785974950240))
* **phone-input:** 기본 국가를 대한민국(+82)으로 바꾼다 ([#6494](https://github.com/coco-de/coui/issues/6494)) ([70e3ccd](https://github.com/coco-de/coui/commit/70e3ccd81ea323cb484b5e2dd922e8cd1421a3b9))
* **tracker:** 정상 구간은 옅게, 구간 사이는 4 로 띄운다 ([#6477](https://github.com/coco-de/coui/issues/6477)) ([57ca4d9](https://github.com/coco-de/coui/commit/57ca4d98a842627b6953c1bcc995d03938d55530))


### 버그 수정

* **color-picker:** respect disabled input on both renderers ([#6550](https://github.com/coco-de/coui/issues/6550)) ([7f18d40](https://github.com/coco-de/coui/commit/7f18d4060eae7783742a91df782565242bc17ac1))
* **core,web,figma,docs:** main 의 CI 가드와 테스트를 다시 초록으로 맞춘다 ([#6509](https://github.com/coco-de/coui/issues/6509)) ([882f71c](https://github.com/coco-de/coui/commit/882f71c53aaaf18aa00dd3a4c551b4888e337776))
* **flutter,web:** guard deferred work after component disposal ([#6584](https://github.com/coco-de/coui/issues/6584)) ([ec6fd6a](https://github.com/coco-de/coui/commit/ec6fd6ae7f2c590fdd49b2c6793ab3f8d5b5a155))
* **navigation-bar:** follow only visible outer content scrolling ([#6478](https://github.com/coco-de/coui/issues/6478)) ([5efd1ca](https://github.com/coco-de/coui/commit/5efd1cafb94979c96af9896aee8de4ffaa7413b5))
* **parity:** Web 캡처를 안정화하고 누락된 baseline을 채운다 ([#6542](https://github.com/coco-de/coui/issues/6542)) ([6882d1d](https://github.com/coco-de/coui/commit/6882d1d41c872b6285b5f12d169b5c3d9b21f59a))
* **scaffold:** align adaptive app-bar rails with iPhone Duo ([#6599](https://github.com/coco-de/coui/issues/6599)) ([35786c4](https://github.com/coco-de/coui/commit/35786c4fedce22e45ea6d14f6b85ae1d03999ebb))
* **web:** hide unsupported ColorPicker eyedropper ([#6546](https://github.com/coco-de/coui/issues/6546)) ([57e30c2](https://github.com/coco-de/coui/commit/57e30c22ac7a02a0914eeb2f9c942cb85d44471a))
* **web:** honor zero-duration NumberTicker transitions and preserve idle builders ([#6565](https://github.com/coco-de/coui/issues/6565)) ([b2a4cee](https://github.com/coco-de/coui/commit/b2a4cee517e9e5f7b8644ed0874f97399e0c7be0))
* **web:** ignore NumberTicker startup after disposal ([#6554](https://github.com/coco-de/coui/issues/6554)) ([f065aa9](https://github.com/coco-de/coui/commit/f065aa96ae52d7c54862c611adb77095694a1f32))
* **web:** preserve authored Tag label colors ([#6621](https://github.com/coco-de/coui/issues/6621)) ([49622bb](https://github.com/coco-de/coui/commit/49622bb8e9dd45f4597bb949c0e2c72b085c7738))
* **web:** preserve both non-flip Swap faces in natural layout ([#6499](https://github.com/coco-de/coui/issues/6499)) ([1a856ad](https://github.com/coco-de/coui/commit/1a856ad934b7023a5cfdf42ac86d03068a4fd74f))
* **web:** preserve control opacity scopes and close colors ([#6617](https://github.com/coco-de/coui/issues/6617)) ([54417c1](https://github.com/coco-de/coui/commit/54417c107f87b6444291c9f71eff5b90540c706f))
* **web:** preserve explicit DisclosureBadge label colors ([#6616](https://github.com/coco-de/coui/issues/6616)) ([9372b03](https://github.com/coco-de/coui/commit/9372b033a53f6a5079c5a05e88bfbb26e615c8f1))
* **web:** preserve fractional OverflowMarquee fade lengths ([#6604](https://github.com/coco-de/coui/issues/6604)) ([566b1c5](https://github.com/coco-de/coui/commit/566b1c55ae2a0ff6dfd5b73d787ef0fc5e2b475f))
* **web:** preserve nested feedback text colors ([#6615](https://github.com/coco-de/coui/issues/6615)) ([dabd23f](https://github.com/coco-de/coui/commit/dabd23f1cb5318aea869e8afc497bede48217438))
* **web:** retain raw selection and Command panel colors ([#6609](https://github.com/coco-de/coui/issues/6609)) ([84df6e1](https://github.com/coco-de/coui/commit/84df6e1479b5824fdb94968165d91fec39359a9f))


### 문서

* 문서 시안 반영 뒤 남은 죽은 코드와 사실 오류를 정리한다 ([#6598](https://github.com/coco-de/coui/issues/6598)) ([b57e9d5](https://github.com/coco-de/coui/commit/b57e9d5830cafdb0e6259a73b71a3541146db473))

## [0.190.1](https://github.com/coco-de/coui/compare/coui_web-v0.190.0...coui_web-v0.190.1) (2026-11-19)


### 버그 수정

* **icon:** [#6438](https://github.com/coco-de/coui/issues/6438) preserve the declared square viewport ([#6441](https://github.com/coco-de/coui/issues/6441)) ([6ec4d20](https://github.com/coco-de/coui/commit/6ec4d2078eb9dd3844febec56b41493be54fae91))
* **web:** [#6439](https://github.com/coco-de/coui/issues/6439) forward raw Loading indicator colors ([#6442](https://github.com/coco-de/coui/issues/6442)) ([bad8ebd](https://github.com/coco-de/coui/commit/bad8ebdc8d2c512d216f00c98cb2064f97d51333))
* **web:** compose token Tabs state washes over the selected fill ([#6450](https://github.com/coco-de/coui/issues/6450)) ([ad1ba78](https://github.com/coco-de/coui/commit/ad1ba78e9dc2f7c33b8f5dd41c511cac4b312d38))
* **web:** FormLabel·ValidatorHint 간격을 RTL에서도 유지한다 ([#6423](https://github.com/coco-de/coui/issues/6423)) ([314bd93](https://github.com/coco-de/coui/commit/314bd9321cb56ee7e5dbea741741ef8cbbf74df9))
* **web:** Frame의 기존 image·gradient·color 합성을 복구한다 ([#6433](https://github.com/coco-de/coui/issues/6433)) ([e8f89cd](https://github.com/coco-de/coui/commit/e8f89cd1a1696039feef7a53088d468b8713a5e5))
* **web:** Frame의 clip 우선순위와 소수 정렬 좌표를 보존한다 ([#6430](https://github.com/coco-de/coui/issues/6430)) ([e8ef253](https://github.com/coco-de/coui/commit/e8ef25314a456f9192f9ae9833d0ebc625f89d41))
* **web:** honor raw Tabs state layers with existing motion timing ([#6446](https://github.com/coco-de/coui/issues/6446)) ([64dd884](https://github.com/coco-de/coui/commit/64dd884831f12ee4d39aef9be3263481e94b168e))
* **web:** isolate automatic roving focus owners per Element ([#6445](https://github.com/coco-de/coui/issues/6445)) ([b5a18a2](https://github.com/coco-de/coui/commit/b5a18a24b38481f853cc4770137fa60dfbbd7a5d))
* **web:** isolate DotIndicator state values on rendered dots ([#6449](https://github.com/coco-de/coui/issues/6449)) ([c6690e1](https://github.com/coco-de/coui/commit/c6690e18cd13484a7b33a61806cf7b7938e6bee3))
* **web:** isolate Join child rules and verify real scope remounts ([#6455](https://github.com/coco-de/coui/issues/6455)) ([b6b181a](https://github.com/coco-de/coui/commit/b6b181aafb4375ee2c636b350ae31f36f4a7b3f4))
* **web:** preserve Toggle and Chip backgrounds during state washes ([#6457](https://github.com/coco-de/coui/issues/6457)) ([fab3c99](https://github.com/coco-de/coui/commit/fab3c999e282e63d629cecc2f1adee0a72b70e85))
* **web:** register existing Core opacity utility scale ([#6444](https://github.com/coco-de/coui/issues/6444)) ([0a23b3c](https://github.com/coco-de/coui/commit/0a23b3cc9832beef730c01330b6fee2c832ecef6))

## [0.190.0](https://github.com/coco-de/coui/compare/coui_web-v0.189.0...coui_web-v0.190.0) (2026-11-18)


### 기능

* **navigation-bar:** 하단 바 항목은 96 까지만 늘어나고 남는 폭은 가운데로 모은다 ([#6410](https://github.com/coco-de/coui/issues/6410)) ([e2d2dbf](https://github.com/coco-de/coui/commit/e2d2dbf21ab7e6ae3c05389f11b271dc7ef39889))


### 버그 수정

* **web:** 14종 컴포넌트 스타일을 실제 Element에 귀속한다 ([#6419](https://github.com/coco-de/coui/issues/6419)) ([9364fcb](https://github.com/coco-de/coui/commit/9364fcbe8d1c8c3569bb5ba3e4710a7989cb053e))
* **web:** isolate stateful scopes across ten components ([#6413](https://github.com/coco-de/coui/issues/6413)) ([6d81740](https://github.com/coco-de/coui/commit/6d81740ae3272e60baf1d23c909b8b83e9d8db36))
* **web:** keep compact caption spacing in its fold ([#6414](https://github.com/coco-de/coui/issues/6414)) ([ce6a391](https://github.com/coco-de/coui/commit/ce6a391641bf56337df702035327f5c5fb2cba0a))
* **web:** separate FadeScroll server and client owners ([#6411](https://github.com/coco-de/coui/issues/6411)) ([7fc04b0](https://github.com/coco-de/coui/commit/7fc04b0843bfa893e0ab4cc9b9cd980f826f929e))

## [0.189.0](https://github.com/coco-de/coui/compare/coui_web-v0.188.0...coui_web-v0.189.0) (2026-11-18)


### 기능

* **core,flutter,web:** 본문을 스크롤하면 떠 있는 내비게이션 바가 줄어든다 ([#6400](https://github.com/coco-de/coui/issues/6400)) ([5889bb7](https://github.com/coco-de/coui/commit/5889bb76383b8cee2c0a1c23a6b046d5a4e60747))
* **navigation-bar:** 하단 바(Indicator=color)는 면 없이 색과 굵기로만 선택을 표시한다 ([#6397](https://github.com/coco-de/coui/issues/6397)) ([329f9ea](https://github.com/coco-de/coui/commit/329f9ea83de4c17be99b9b24e9fbfa4d817ba538))


### 버그 수정

* **web:** bind FadeScroll masks to actual overflow and owner state ([#6401](https://github.com/coco-de/coui/issues/6401)) ([9b7d301](https://github.com/coco-de/coui/commit/9b7d30150315df33c88c27197f9c4d8c35b85737))
* **web:** honor existing duration and disabled-color styles ([#6391](https://github.com/coco-de/coui/issues/6391)) ([0b4c49d](https://github.com/coco-de/coui/commit/0b4c49d10969a9daa6028753222c2678e8f6beca))
* **web:** preserve host head assets across CoUI roots ([#6396](https://github.com/coco-de/coui/issues/6396)) ([ce2cda1](https://github.com/coco-de/coui/commit/ce2cda121c98494c10f2f983b15f53772dd168b7))

## [0.188.0](https://github.com/coco-de/coui/compare/coui_web-v0.187.0...coui_web-v0.188.0) (2026-11-18)


### 기능

* **navigation-bar:** 구분선을 연하게, 선택 표시를 항목 전체 네모로 ([#6384](https://github.com/coco-de/coui/issues/6384)) ([2bca2b7](https://github.com/coco-de/coui/commit/2bca2b7a45b43cbed74cbad88d38d1c62951dcfb))

## [0.187.0](https://github.com/coco-de/coui/compare/coui_web-v0.186.0...coui_web-v0.187.0) (2026-11-18)


### 기능

* **core,flutter,web:** 접히는 화면을 두 플랫폼에서 읽고 flip · fold 를 구분한다 ([#6381](https://github.com/coco-de/coui/issues/6381)) ([220c153](https://github.com/coco-de/coui/commit/220c15370a66c44f53d6747d04c1df018074192c))
* **flutter,web:** 리퀴드 글래스 바가 렌즈를 든 동안 캡슐째 부풀고, 유리 대화상자 그림자를 박스 밖에 칠한다 ([#6378](https://github.com/coco-de/coui/issues/6378)) ([6a755a0](https://github.com/coco-de/coui/commit/6a755a02b1ccf104847c7d9371e0524b5f867802))
* **flutter,web:** 새 화면이 열리고 닫힐 때 화면 전환 모션을 넣는다 ([#6373](https://github.com/coco-de/coui/issues/6373)) ([245f3c5](https://github.com/coco-de/coui/commit/245f3c5e8b385387f9b59ae6cffa6dcc625c0508))


### 버그 수정

* **web:** 유리 패널이 열리고 닫히는 동안에도 뒤를 흐리게 유지한다 ([#6382](https://github.com/coco-de/coui/issues/6382)) ([2b1a43f](https://github.com/coco-de/coui/commit/2b1a43f3e0331244ac7bd126b4e6974a2c8b6b79))

## [0.186.0](https://github.com/coco-de/coui/compare/coui_web-v0.185.0...coui_web-v0.186.0) (2026-11-17)


### 기능

* **flutter,web:** 바의 동작을 옆 자리로 나누는 actionsAxis · BarAction 을 추가하고 세로 그룹 아이콘과 레일 툴팁을 맞춘다 ([#6368](https://github.com/coco-de/coui/issues/6368)) ([7d491be](https://github.com/coco-de/coui/commit/7d491be2901b493884259c0601c82f3bfbe03504))
* **flutter,web:** go_router 셸 브랜치 전환에 모션을 주는 IndexedSwitcher 를 더한다 ([#6369](https://github.com/coco-de/coui/issues/6369)) ([da560c1](https://github.com/coco-de/coui/commit/da560c1d9e4a1b02c4c7e61401e063dfa69ba7c9))


### 버그 수정

* **web:** DescriptionCard의 구분선 간격과 행 상태를 보존한다 ([#6361](https://github.com/coco-de/coui/issues/6361)) ([d551700](https://github.com/coco-de/coui/commit/d5517009091e44620e02d3dd32483ca1b559e479))

## [0.185.0](https://github.com/coco-de/coui/compare/coui_web-v0.184.1...coui_web-v0.185.0) (2026-11-17)


### ⚠ BREAKING CHANGES

* **flutter,web:** 리퀴드 글래스 아래의 `NavigationBar(mode: rail)` 이 화면 가장자리에 붙은 판이 아니라 둘레 여백 8 의 떠 있는 캡슐로 그려지고, 라벨을 숨기며(`labelMode` 기본값 `none`), 아이콘 뒤 알약 대신 렌즈로 선택을 표시한다(`indicator` 기본값 `color`). 라벨과 알약은 `labelMode: .all` · `indicator: .fill` 을 직접 주면 돌아온다. 붙은 판 모양으로 되돌리는 값은 없고, 그 바에만 `navigationBarStyle.surfaceStyle: .defaultStyle` 을 주면 유리 재질 없이 붙은 레일로 그려진다.

### 기능

* **flutter,web:** 리퀴드 글래스 레일을 세로 탭 바 캡슐로 그리고 ToolbarGroup 에 세로 방향을 추가한다 ([#6359](https://github.com/coco-de/coui/issues/6359)) ([ef3c25d](https://github.com/coco-de/coui/commit/ef3c25d58d321353df73c3fa8a59040402bb7e6b))


### 버그 수정

* DescriptionCard의 기존 제목 스타일 설정을 양 플랫폼에 반영한다 ([#6356](https://github.com/coco-de/coui/issues/6356)) ([6b18d85](https://github.com/coco-de/coui/commit/6b18d85de9f445ddd1fefe50804dc7be7af00b07))

## [0.184.1](https://github.com/coco-de/coui/compare/coui_web-v0.184.0...coui_web-v0.184.1) (2026-11-17)


### 버그 수정

* 1배 화면에서 1.5px 선(꺼진 체크박스 · 라디오 틀)을 두 플랫폼 모두 1px 로 그린다 ([#6351](https://github.com/coco-de/coui/issues/6351)) ([db1917e](https://github.com/coco-de/coui/commit/db1917e88cda4bb8b7d19407441b04e597711bc6))
* **web:** 가로 스크롤 목록의 첫 화면에서 앞쪽을 흐리지 않는다 ([#6349](https://github.com/coco-de/coui/issues/6349)) ([8dace57](https://github.com/coco-de/coui/commit/8dace578bbce57171dad98a5937803c29b66a403))
* **web:** 아코디언 꺾쇠를 제 자리에서 가운데에 놓고 제 중심으로 돌린다 ([#6350](https://github.com/coco-de/coui/issues/6350)) ([799cad4](https://github.com/coco-de/coui/commit/799cad4a59201f9e4933aa35011d87c4e9932ef4))

## [0.184.0](https://github.com/coco-de/coui/compare/coui_web-v0.183.3...coui_web-v0.184.0) (2026-11-17)


### ⚠ BREAKING CHANGES

* **glass:** liquid_glass_widgets 1.17.4 반영 — SwitchField 는 콜백이 없으면 비활성 · Flutter 3.50.0 · Jaspr 0.24 베타 선 상향 ([#6339](https://github.com/coco-de/coui/issues/6339))

### 버그 수정

* 파리티 공통 계약 복구와 Loading 주기 갱신 ([#6343](https://github.com/coco-de/coui/issues/6343)) ([6db2278](https://github.com/coco-de/coui/commit/6db2278fdd5a8178502207a7bb8b7cd03f29bc7f))
* **glass:** liquid_glass_widgets 1.17.4 반영 — SwitchField 는 콜백이 없으면 비활성 · Flutter 3.50.0 · Jaspr 0.24 베타 선 상향 ([#6339](https://github.com/coco-de/coui/issues/6339)) ([127e88d](https://github.com/coco-de/coui/commit/127e88df1ae78776ac4f4b60d3cf3ecbf820f93f))

## [0.183.3](https://github.com/coco-de/coui/compare/coui_web-v0.183.2...coui_web-v0.183.3) (2026-11-17)


### 버그 수정

* **web:** 글줄 상자를 Flutter 처럼 정수 픽셀로 그린다 ([#6336](https://github.com/coco-de/coui/issues/6336)) ([7819bc1](https://github.com/coco-de/coui/commit/7819bc1209f4c0e0c6614b782cffc9cec355a29b))
* **web:** preserve Kbd interior minimum outside its border ([#6333](https://github.com/coco-de/coui/issues/6333)) ([887f2a3](https://github.com/coco-de/coui/commit/887f2a364a0ff2d63514da8c6f3403b0276f57fa))
* **web:** propagate FileInput host width to its drop zone ([#6330](https://github.com/coco-de/coui/issues/6330)) ([c2ad35f](https://github.com/coco-de/coui/commit/c2ad35fc14730184ce65c2335c3b619f5e8170f2))

## [0.183.2](https://github.com/coco-de/coui/compare/coui_web-v0.183.1...coui_web-v0.183.2) (2026-11-16)


### 버그 수정

* **frame,parity:** 점선 테두리와 텍스트 측정 정합성 수정 ([#6318](https://github.com/coco-de/coui/issues/6318)) ([57bd843](https://github.com/coco-de/coui/commit/57bd843314a31e6b254ee44cbf120a51822e2079))

## [0.183.1](https://github.com/coco-de/coui/compare/coui_web-v0.183.0...coui_web-v0.183.1) (2026-11-16)


### 버그 수정

* **core:** 한 플랫폼만 읽던 Style 값을 두 플랫폼이 같이 읽는다 ([#6325](https://github.com/coco-de/coui/issues/6325)) ([1765df9](https://github.com/coco-de/coui/commit/1765df948ccc01e12f75020911bdd856fa176655)), closes [#6323](https://github.com/coco-de/coui/issues/6323)

## [0.183.0](https://github.com/coco-de/coui/compare/coui_web-v0.182.0...coui_web-v0.183.0) (2026-11-16)


### 기능

* **core,flutter,web:** Web CodeSnippet 이 JSON · YAML · SQL 을 Flutter 와 같은 문법으로 칠한다 ([#6309](https://github.com/coco-de/coui/issues/6309)) ([9c6a167](https://github.com/coco-de/coui/commit/9c6a16709231cdc2da494b67728c27315f712f5f))


### 버그 수정

* **parity:** 캡처 조건과 Web 렌더·애니메이션·스와이프 결함 수정 ([#6297](https://github.com/coco-de/coui/issues/6297)) ([0459dd7](https://github.com/coco-de/coui/commit/0459dd702f2a66aa2c68b2046ab2c5c97f9e65dc))
* **web:** CodeSnippet 이 싣지 않은 문법의 mode 를 Dart 문법으로 칠하지 않는다 ([#6303](https://github.com/coco-de/coui/issues/6303)) ([e5a4219](https://github.com/coco-de/coui/commit/e5a4219c82629cce76ff115531d0129b62b1c3ea))

## [0.182.0](https://github.com/coco-de/coui/compare/coui_web-v0.181.0...coui_web-v0.182.0) (2026-11-13)


### 기능

* **core:** Tabs underline 바탕선을 outlineSubtle 로 ([#6299](https://github.com/coco-de/coui/issues/6299)) ([6df0835](https://github.com/coco-de/coui/commit/6df08354e07007935b8a115a0669069fa608eb06))
* **core:** Toggle 꺼짐 핸들을 흰색으로, 핸들에 연한 기본 그림자 ([#6286](https://github.com/coco-de/coui/issues/6286)) ([15b87c1](https://github.com/coco-de/coui/commit/15b87c1f47b78148bd3dc52e73e645aa82d4615b))
* **core:** Toggle 비활성 꺼짐 핸들도 흰색으로 ([#6295](https://github.com/coco-de/coui/issues/6295)) ([1e129bb](https://github.com/coco-de/coui/commit/1e129bb552514954cc1b34af2f164655d3fcd2ed))
* **flutter,web:** AppBar 가운데 제목을 양옆 같은 폭 사이 바 가운데에 둔다 ([#6301](https://github.com/coco-de/coui/issues/6301)) ([e3ab376](https://github.com/coco-de/coui/commit/e3ab376d333ad5c8364e7021e9daad6d41c61a23))


### 버그 수정

* **flutter,web:** 남은 파리티 결함과 캡처 입력 차이를 바로잡는다 ([#6284](https://github.com/coco-de/coui/issues/6284)) ([b5ed390](https://github.com/coco-de/coui/commit/b5ed3907f36b7c0ad7d2ecfac2ad0b72040d75df)), closes [#6274](https://github.com/coco-de/coui/issues/6274) [#6275](https://github.com/coco-de/coui/issues/6275) [#6276](https://github.com/coco-de/coui/issues/6276) [#6277](https://github.com/coco-de/coui/issues/6277) [#6278](https://github.com/coco-de/coui/issues/6278) [#6280](https://github.com/coco-de/coui/issues/6280) [#6281](https://github.com/coco-de/coui/issues/6281) [#6282](https://github.com/coco-de/coui/issues/6282)
* **flutter,web:** defer scrollbar layout reports and repair Web geometry guards ([#6270](https://github.com/coco-de/coui/issues/6270)) ([b4f24d2](https://github.com/coco-de/coui/commit/b4f24d2fde9a1519cd927da9954e6f30470ad5b0)), closes [#6268](https://github.com/coco-de/coui/issues/6268)
* **time-picker:** 세그먼트 숫자를 headlineMedium 으로 줄이고 텍스트 스타일을 붙인다 ([#6262](https://github.com/coco-de/coui/issues/6262)) ([a0752eb](https://github.com/coco-de/coui/commit/a0752eb3d972b20616b4c3ccc4f9029b42cac57a))
* **web:** Dock 막대가 리셋 없는 페이지에서도 Core 최소 높이를 지키고, 낡은 파리티 프로브 단언 넷을 맞춘다 ([#6265](https://github.com/coco-de/coui/issues/6265)) ([8ebb4d4](https://github.com/coco-de/coui/commit/8ebb4d41cafa26884643af1d1c3e4b1cdd605e36)), closes [#6247](https://github.com/coco-de/coui/issues/6247)

## [0.181.0](https://github.com/coco-de/coui/compare/coui_web-v0.180.1...coui_web-v0.181.0) (2026-11-12)


### 기능

* **banner:** 상태 면 위 버튼의 상태 레이어를 버튼 모양으로 넓힌다 ([#6235](https://github.com/coco-de/coui/issues/6235)) ([daec939](https://github.com/coco-de/coui/commit/daec93939427286adfbf30493efdfab5289a50ef))


### 버그 수정

* **banner,toast:** 닫기 x 글리프를 md 정사각 버튼의 18 로 맞춘다 ([#6257](https://github.com/coco-de/coui/issues/6257)) ([faba2a7](https://github.com/coco-de/coui/commit/faba2a732bdf2904ed38cfd2d43b4ad45f024450))
* **banner,toast:** 액션 여백 plain 전용 · Toast 닫기 40 원 · 정사각 닫기 글리프 ✓→✕ ([#6246](https://github.com/coco-de/coui/issues/6246)) ([69ad40d](https://github.com/coco-de/coui/commit/69ad40dc48d4928c48d888a081c4f6df8e64c626))
* **core,flutter,web,figma:** SidebarItem 비활성 행의 trailing 글리프가 비활성 색을 따른다 (Part of [#6008](https://github.com/coco-de/coui/issues/6008)) ([#6230](https://github.com/coco-de/coui/issues/6230)) ([ffc44c7](https://github.com/coco-de/coui/commit/ffc44c77953fb2585fb269d56b130643362fef02))
* **toast:** 닫기 버튼을 토스트 높이의 가운데에 놓는다 ([#6249](https://github.com/coco-de/coui/issues/6249)) ([49079fb](https://github.com/coco-de/coui/commit/49079fbd9958a9d2d973918d343ffef67f49093d))
* **web:** 잘림 호스트의 투명 테두리를 패딩으로 접어 liquidGlass 띠가 모든 엔진에서 바깥 가장자리에 닿게 한다 ([#6217](https://github.com/coco-de/coui/issues/6217)) ([#6221](https://github.com/coco-de/coui/issues/6221)) ([a1b3a26](https://github.com/coco-de/coui/commit/a1b3a266268bf8b782846e997a874662ae3ea43e))

## [0.180.1](https://github.com/coco-de/coui/compare/coui_web-v0.180.0...coui_web-v0.180.1) (2026-11-11)


### 버그 수정

* **tabs:** center underline labels in the full tab height ([#6228](https://github.com/coco-de/coui/issues/6228)) ([dd2eef8](https://github.com/coco-de/coui/commit/dd2eef822f8ce934562416541adc019d063aa1a6))

## [0.180.0](https://github.com/coco-de/coui/compare/coui_web-v0.179.0...coui_web-v0.180.0) (2026-11-11)


### ⚠ BREAKING CHANGES

* **rich-editor:** `CoreRichEditorContract` 에 추상 getter `showSelectionToolbar` 가, `CoUILocalizations`/`CouiLocalizations` 에 `richEditorSelectionToolbar` 가 늘어 이들을 직접 구현한 클래스는 멤버를 추가해야 하고, 기본값이 켬이라 `RichEditor` 는 글자를 선택하면 서식 툴바를 띄운다 — 예전 동작은 `showSelectionToolbar: false`.

### 기능

* **button:** 상태 면 위 plain 버튼에 상태 레이어를 실어 hover 를 보인다 ([#6222](https://github.com/coco-de/coui/issues/6222)) ([d494fb6](https://github.com/coco-de/coui/commit/d494fb65cc1cda5dca284d08060c0c6b8d57e5c1))
* **core,flutter,web,docs:** Filter 폭 채우기(fillWidth) — 트랙이 부모 폭을 채우고 칸이 그 폭을 똑같이 나눈다 ([#6156](https://github.com/coco-de/coui/issues/6156)) ([824a4ae](https://github.com/coco-de/coui/commit/824a4ae887b566db501f808ad67227ae1661a7ce)), closes [#6155](https://github.com/coco-de/coui/issues/6155)
* **core,flutter,web,figma:** 도크 위쪽 구분선 굵기를 Style 필드 borderWidth 로 올리고 Web 이 그 폭을 띠에 알린다 ([#6165](https://github.com/coco-de/coui/issues/6165)) ([#6206](https://github.com/coco-de/coui/issues/6206)) ([706bee3](https://github.com/coco-de/coui/commit/706bee382380b776fef4ec46ec1aa8f8119e3c68))
* **core,flutter,web,figma:** RichEditor 목록 들여쓰기를 Style 필드 listIndent 로 올린다 ([#6169](https://github.com/coco-de/coui/issues/6169)) ([5c62444](https://github.com/coco-de/coui/commit/5c6244414d2be6d9fda7997ea79f1522f711b188)), closes [#6164](https://github.com/coco-de/coui/issues/6164)
* **core,flutter,web,figma:** TimePicker 편집 칸에 안쪽 테두리를 두고 FileInput 끌어다 놓기 테두리를 실선으로 그린다 ([#6208](https://github.com/coco-de/coui/issues/6208)) ([68db01a](https://github.com/coco-de/coui/commit/68db01aabfa662d4fa1f99e43f8f180b1f114b5b))
* **core:** CoUI 기본 팔레트를 무채색 neutral 로 — primary 프리미티브 제거 ([#6143](https://github.com/coco-de/coui/issues/6143)) ([b982b93](https://github.com/coco-de/coui/commit/b982b932a6c4a9975c66ec993ecd7879df205e30))
* **figma:** 캔버스 예시 글자를 디자이너 확정 대조표대로 한국어로 ([#6120](https://github.com/coco-de/coui/issues/6120)) ([8bbf118](https://github.com/coco-de/coui/commit/8bbf1184e6ee8531aa6306e64da723b896608d29))
* **i10n:** 한국어 컴포넌트 문구를 해요체로 맞춘다 ([#6117](https://github.com/coco-de/coui/issues/6117)) ([9a5ea11](https://github.com/coco-de/coui/commit/9a5ea11f7ac657f641e7e9fb64f40aa99cbd4ebc))
* **rich-editor:** 선택 영역 위에 뜨는 서식 툴바 RichEditorSelectionToolbar · showSelectionToolbar (리디자인 PR B) ([#6110](https://github.com/coco-de/coui/issues/6110)) ([7948887](https://github.com/coco-de/coui/commit/79488874f433ccfa4e301faa101ce9421ab1d8cf))


### 버그 수정

* **core,figma:** 아이콘에 쓰인 테두리 토큰 둘을 콘텐츠 토큰으로 바로잡는다 (Part of [#6008](https://github.com/coco-de/coui/issues/6008)) ([#6192](https://github.com/coco-de/coui/issues/6192)) ([9b8a134](https://github.com/coco-de/coui/commit/9b8a134ee5e5d3aa80aa687861dafa292b7eca1c))
* **core,flutter,web,figma,docs:** main 의 깨진 CI 가드와 테스트를 모두 초록으로 되돌린다 ([#6147](https://github.com/coco-de/coui/issues/6147)) ([cdc824e](https://github.com/coco-de/coui/commit/cdc824ec78a88f33c4820fc39f01a284139895f8))
* **core,flutter,web:** 눌림 가능한 CardImage 의 안쪽 여백·화살표를 Web 과 같게 맞춘다 ([#6129](https://github.com/coco-de/coui/issues/6129)) ([#6146](https://github.com/coco-de/coui/issues/6146)) ([00fd2d5](https://github.com/coco-de/coui/commit/00fd2d56450007f885a2b16b8b7e6ebbdb24d55f))
* **core,flutter,web:** ChipInput 입력 필드가 Web 처럼 자기 줄의 남는 폭을 채운다 ([#6136](https://github.com/coco-de/coui/issues/6136)) ([7250c70](https://github.com/coco-de/coui/commit/7250c707eeaa4b7bb2894e322f8766e6399910ce))
* **core,flutter,web:** TextField · TextArea 의 바깥 포커스 링이 마우스로 누른 포커스에는 뜨지 않게 한다 ([#6119](https://github.com/coco-de/coui/issues/6119)) ([ca82ec0](https://github.com/coco-de/coui/commit/ca82ec029e6f0af83f0061cb00ffcf23b1de592b)), closes [#6116](https://github.com/coco-de/coui/issues/6116)
* **core:** ChipInput 에 포커스해도 안쪽 입력 칸 둘레에 상자가 그려지지 않는다 ([#6138](https://github.com/coco-de/coui/issues/6138)) ([#6139](https://github.com/coco-de/coui/issues/6139)) ([511a65c](https://github.com/coco-de/coui/commit/511a65c336ab07b418ecb495f2f0e04baaa69e52))
* **figma:** 예시 글자 다듬기 — Rich Editor · 입력 세 종 · Avatar 이니셜 · Chat · Banner ([#6140](https://github.com/coco-de/coui/issues/6140)) ([94a1f78](https://github.com/coco-de/coui/commit/94a1f78135f8918bd88fd6cbc84488e4a6d9eabf))
* **flutter,web,docs:** RichEditor 의 빈 편집기 안내가 한 줄 말줄임 대신 여러 줄로 감긴다 ([#6159](https://github.com/coco-de/coui/issues/6159)) ([#6160](https://github.com/coco-de/coui/issues/6160)) ([b39352d](https://github.com/coco-de/coui/commit/b39352d7d6b97f34adc7ffbce7949f7a7f081c0f))
* **flutter,web:** 프레임 있는 필드는 박스 전체가 탭을 받고 눌림 워시가 박스 전체에 칠해진다 ([#6122](https://github.com/coco-de/coui/issues/6122)) ([#6132](https://github.com/coco-de/coui/issues/6132)) ([2e8afe3](https://github.com/coco-de/coui/commit/2e8afe38976afc3e22b3dff7cc722ea8ebfc9c3c))
* **flutter,web:** RichEditor 의 본문 높이와 목록 간격·들여쓰기를 두 플랫폼이 같게 그린다 ([#6128](https://github.com/coco-de/coui/issues/6128)) ([#6151](https://github.com/coco-de/coui/issues/6151)) ([94b9392](https://github.com/coco-de/coui/commit/94b939290944cf1a871637e4be9b8e004f563141))
* **web:** 내비게이션 바에 넣었던 효과 없는 위쪽 변 폭 넘김을 걷어낸다 ([#6165](https://github.com/coco-de/coui/issues/6165)) ([#6216](https://github.com/coco-de/coui/issues/6216)) ([42cb8b2](https://github.com/coco-de/coui/commit/42cb8b2e99229ff5b720b314f05ee55abc9e49da))
* **web:** 드래그 패널의 스크롤을 안쪽 요소로 옮겨 liquidGlass 띠가 바깥 가장자리까지 닿게 한다 ([#6165](https://github.com/coco-de/coui/issues/6165)) ([#6215](https://github.com/coco-de/coui/issues/6215)) ([fbd2aa7](https://github.com/coco-de/coui/commit/fbd2aa7ff167ce68480a053fba9a1d469efa0855))
* **web:** 배너 · 스캐폴드 헤더 · 탭 패널이 자기 선 폭을 알려 liquidGlass 띠가 바깥 가장자리까지 닿게 한다 ([#6165](https://github.com/coco-de/coui/issues/6165)) ([#6209](https://github.com/coco-de/coui/issues/6209)) ([7d4c224](https://github.com/coco-de/coui/commit/7d4c2247e8c7dd37ca26a56eb054f9716d72d819))
* **web:** 블록 안 인라인 자식의 줄 상자 strut 로 FormField · Popover · MultiAnswerCard 가 Flutter 보다 커지지 않게 한다 ([#6170](https://github.com/coco-de/coui/issues/6170)) ([#6174](https://github.com/coco-de/coui/issues/6174)) ([2aecca1](https://github.com/coco-de/coui/commit/2aecca12292bf6a205304983548a982ee84de5ee))
* **web:** 숫자 입력의 네이티브 스핀 버튼을 없애 값 글자가 가운데에 앉게 한다 ([#6167](https://github.com/coco-de/coui/issues/6167)) ([#6189](https://github.com/coco-de/coui/issues/6189)) ([3c52a9e](https://github.com/coco-de/coui/commit/3c52a9e14533c6a66b88e2587ede72a66d651279))
* **web:** 입력 필드의 상자를 항상 래퍼로 두고 liquidGlass 가장자리 띠가 테두리 상자까지 닿게 한다 ([#6125](https://github.com/coco-de/coui/issues/6125)) ([#6168](https://github.com/coco-de/coui/issues/6168)) ([3d5ec4e](https://github.com/coco-de/coui/commit/3d5ec4e0737e7a0f39d9e67297b655e6a2ff17f7))
* **web:** 자기 내용을 자르는 표면이 잘린다고 알려 liquidGlass 띠가 바깥 가장자리까지 닿게 한다 ([#6165](https://github.com/coco-de/coui/issues/6165)) ([#6212](https://github.com/coco-de/coui/issues/6212)) ([78ac140](https://github.com/coco-de/coui/commit/78ac140022d139b47ab97276ff1859c970c99a56))
* **web:** 점선 Frame 이 테두리 두께를 레이아웃에 잡아 Flutter 와 같은 크기가 되게 한다 ([#6171](https://github.com/coco-de/coui/issues/6171)) ([#6181](https://github.com/coco-de/coui/issues/6181)) ([14bff2f](https://github.com/coco-de/coui/commit/14bff2f68d8f94c91c02bd3a2220b7c2f5326952))
* **web:** 테두리를 가진 표면이 자기 선 폭을 알려 liquidGlass 가장자리 띠가 바깥 가장자리까지 닿게 한다 ([#6165](https://github.com/coco-de/coui/issues/6165)) ([#6198](https://github.com/coco-de/coui/issues/6198)) ([fd4bb55](https://github.com/coco-de/coui/commit/fd4bb55caa6ee313dfe232d065f4b4df52e20454))
* **web:** 폭 띠를 진술한 팝업 패널은 내용 폭에 맞춰 띠 안에서 정해진다 ([#6126](https://github.com/coco-de/coui/issues/6126)) ([#6142](https://github.com/coco-de/coui/issues/6142)) ([0f4a102](https://github.com/coco-de/coui/commit/0f4a102154f9c9cbab312070d4186735c0c82890))
* **web:** 한 변에만 테두리가 있는 막대가 그 변의 선 폭을 알려 liquidGlass 띠가 위쪽 가장자리까지 닿게 한다 ([#6165](https://github.com/coco-de/coui/issues/6165)) ([#6204](https://github.com/coco-de/coui/issues/6204)) ([ab6a96d](https://github.com/coco-de/coui/commit/ab6a96d10b1357c88a445a32be339f980e2aa408))
* **web:** Card 의 단일 자식 래퍼를 flex 열로 두어 인라인 글자의 strut 로 카드가 커지지 않게 한다 ([#6177](https://github.com/coco-de/coui/issues/6177)) ([#6182](https://github.com/coco-de/coui/issues/6182)) ([d828478](https://github.com/coco-de/coui/commit/d828478ba59cc1a637e8b4f26310192263100189))
* **web:** Chip 재질 가장자리 띠 폭이 CoreChipStyle.defaultBorderWidth 를 거친다 ([#6196](https://github.com/coco-de/coui/issues/6196)) ([#6197](https://github.com/coco-de/coui/issues/6197)) ([094d057](https://github.com/coco-de/coui/commit/094d057a65c0547755ee9b18907be089164f0936))
* **web:** DragItem 은 높이를 채우는 투명 래퍼로, 대기 중 DragOverlay 는 0×0 상자로 둔다 ([#6173](https://github.com/coco-de/coui/issues/6173)) ([#6179](https://github.com/coco-de/coui/issues/6179)) ([2d980fd](https://github.com/coco-de/coui/commit/2d980fde97643c06adc38238e2a3f0b5b3d27865))
* **web:** Popup · Menubar 막대의 테두리가 패딩 안쪽에 겹치게 해 Flutter 와 같은 크기를 잡는다 ([#6191](https://github.com/coco-de/coui/issues/6191)) ([#6194](https://github.com/coco-de/coui/issues/6194)) ([934e7bd](https://github.com/coco-de/coui/commit/934e7bd905f6dae7445ee6a5375de664d90c37ea))
* **web:** TextArea 의 상자를 항상 래퍼로 두고 liquidGlass 가장자리 띠가 닿게 한다 ([#6166](https://github.com/coco-de/coui/issues/6166)) ([#6195](https://github.com/coco-de/coui/issues/6195)) ([bb386bd](https://github.com/coco-de/coui/commit/bb386bdc6fcbfcff20cc2ed5671a858392c8e69e))

## [0.179.0](https://github.com/coco-de/coui/compare/coui_web-v0.178.0...coui_web-v0.179.0) (2026-11-09)


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
* **web:** normalize unbundled Lucide icon strokes ([#6095](https://github.com/coco-de/coui/issues/6095)) ([d85e192](https://github.com/coco-de/coui/commit/d85e192a018b7d893dcf158909787295b215e957))

## 0.161.0 (Unreleased)

- Normalize unbundled Lucide strokes with the shared Core rule in SVG, mask and background modes; `iconScript()` also loads the same-origin companion asset, with `normalizerSrc` for mirrors.

- Match native glass AppBar action capsules, centered titles, toolbar control sizes and soft scroll edges. Rebuild structural chrome when the document material changes, retain independent refraction at rest, and respect contrast/transparency preferences.
- Share refraction maps with Flutter Web and compensate neutral-map sampling offsets, including during navigation lens activation.
- Keep hidden Liquid Glass surfaces idle until measurable and preserve newly authored blur when shown.

- Preserve shared surface refraction and rims after framework style rewrites, retaining newly authored blur values.

- Match Flutter navigation drag/lens motion, controlled selection, RTL, reduced motion and local material changes.
- Keep toggle lenses on the thumb compositor timeline and honor Core track dimensions; preserve popover morphs during positioning and local panel overrides.
- Align transparent AppBar material, tab touch gestures and slider drag preview/cleanup with Flutter.
- Add material overrides for popup/menubar surfaces, grouped toolbar capsules, and explicit standard menu action icons.
- Clarify Liquid Glass selection with a visible capsule and palette accent, preserving authored colours.
- Add component material overrides for AppBar and NavigationBar.
- Apply local materials independently of the document preset, including dark mode, accessibility and refraction runtime updates.

## [0.178.0](https://github.com/coco-de/coui/compare/coui_web-v0.177.0...coui_web-v0.178.0) (2026-11-06)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** CoreHoverCardStyle 의 backgroundColor · borderColor · borderRadius · padding · panelMaxWidth 필드가 사라지고 합성한 Popup 의 CorePopupStyle 을 담는 panelStyle 슬롯 하나로 모였다(maxWidth 는 panelStyle.maxWidth).
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
* **menu:** 리디자인 사본의 호스트 행 모서리 8 반영 ([#6089](https://github.com/coco-de/coui/issues/6089)) ([5a88dc0](https://github.com/coco-de/coui/commit/5a88dc00fd7b8aaa4af29f062b25ecd3016e124e))
* **stepper:** 세로 제목 중심 정렬과 33/11 연결선 반영 ([#6090](https://github.com/coco-de/coui/issues/6090)) ([9e81a19](https://github.com/coco-de/coui/commit/9e81a193adc3ab8b78a2f140af924b9c175bb7dc))
* **tracker:** 막대 모서리 기본값을 radius/4 에서 2 로 ([#6032](https://github.com/coco-de/coui/issues/6032)) ([1b61e3d](https://github.com/coco-de/coui/commit/1b61e3d83bde0047a304ca120f77df4cf3dfe82e))

## [0.177.0](https://github.com/coco-de/coui/compare/coui_web-v0.176.0...coui_web-v0.177.0) (2026-11-04)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** TextField 계열 값 · 자리표시자 글자의 줄 높이가 140% 에서 역할 값(Body/Medium · Body/Large 150%)으로 바뀌고, 한 줄 입력 상자는 모든 크기에서 크기 단 높이에 글줄을 세로 가운데로 둔다 — TextField · Select 의 sm 은 33.6 에서 32 로, TextField xs 는 29.6 에서 24 로 낮아지고(md 40 · lg 48 · xl 56 · xl2 64 는 그대로), 여러 줄 TextField 는 줄마다 1.4 높아지며, NumberInput 값 글자가 Label/Large(Medium)에서 Body/Medium(Regular)으로 바뀌고, Flutter 의 가운데 정렬 TextField 값이 0.5px 오른쪽으로 옮겨진다. 이전 렌더가 필요하면 `textFieldStyle: CoreTextFieldStyle(padding: <크기 행 패딩>, baseTextStyle: CoreTextStyle.token(CoreTextStyles.bodyMedium).copyWith(lineHeight: CoreLineHeight.h140))` 를 넘긴다(NumberInput 값은 `fieldStyle: CoreTextFieldStyle(valueStyle: CoreTextStyle.token(CoreTextStyles.labelLarge))`).

### 버그 수정

* **core,flutter,web,figma:** 선택된 비활성 목적지가 선택 표시를 흐리게 남기고, Web 포커스 8% 레이어가 실제로 칠해진다 ([#6003](https://github.com/coco-de/coui/issues/6003)) ([899539d](https://github.com/coco-de/coui/commit/899539d77f1e67b19ba7c5dea83cdcef9459b6bc))
* **core,flutter,web,figma:** 한 줄 입력 상자를 크기 단 높이에 두고 값 글자는 역할 줄 높이로 세로 가운데에 그린다 ([#6009](https://github.com/coco-de/coui/issues/6009)) ([6991716](https://github.com/coco-de/coui/commit/6991716b7b9bc0a732def8e712b3442751876491))
* **core,flutter,web:** Dark 상태 아이콘 500 · SidebarItem 선택 배경 surfaceContainer · Stat filled surfaceContainerLow ([#6015](https://github.com/coco-de/coui/issues/6015)) ([ef150af](https://github.com/coco-de/coui/commit/ef150afa8f3f319157e30fbc06146f319dba4688))
* **i10n,flutter,web,figma:** 커맨드 푸터의 ↑ ↓ 한 쌍 라벨을 양방향 '이동'(commandMove)으로 바꾼다 ([#6014](https://github.com/coco-de/coui/issues/6014)) ([f397cca](https://github.com/coco-de/coui/commit/f397cca066ffb22a3c17048f83cb5c860aa731cc))

## [0.176.0](https://github.com/coco-de/coui/compare/coui_web-v0.175.1...coui_web-v0.176.0) (2026-11-04)


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

## [0.175.1](https://github.com/coco-de/coui/compare/coui_web-v0.175.0...coui_web-v0.175.1) (2026-11-02)


### 버그 수정

* **core,flutter,web,figma:** 캔버스 확인 뒤 입력 계열 여백 · 비활성 색을 맞춘다 (Part of [#5831](https://github.com/coco-de/coui/issues/5831)) ([#5953](https://github.com/coco-de/coui/issues/5953)) ([2dd894e](https://github.com/coco-de/coui/commit/2dd894efe4b5a197cd164ee83b8674e7f5865dfc))
* **core,flutter,web,figma:** BottomSheet 의 액션 영역은 바탕 없이 아래에 고정되고, 위 구분선은 내용이 이어질 때만 보인다 (Part of [#5833](https://github.com/coco-de/coui/issues/5833)) ([#5955](https://github.com/coco-de/coui/issues/5955)) ([c89d47f](https://github.com/coco-de/coui/commit/c89d47fbe917e555cbaa8a3e93e01da6ea3cf926))
* **core,flutter,web,figma:** RadialProgress xl 글자 · Loading dots 물결 · Status busy 막대 끝 (Part of [#5879](https://github.com/coco-de/coui/issues/5879)) ([#5956](https://github.com/coco-de/coui/issues/5956)) ([de63db8](https://github.com/coco-de/coui/commit/de63db8738565badcb12839c452f2260f034caae))

## [0.175.0](https://github.com/coco-de/coui/compare/coui_web-v0.174.0...coui_web-v0.175.0) (2026-11-01)


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

## [0.174.0](https://github.com/coco-de/coui/compare/coui_web-v0.173.0...coui_web-v0.174.0) (2026-11-01)


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
* **core:** Drawer 뒤 화면이 기본으로 물러나지 않는다 (Part of [#5833](https://github.com/coco-de/coui/issues/5833)) ([#5892](https://github.com/coco-de/coui/issues/5892)) ([fb07816](https://github.com/coco-de/coui/commit/fb07816590a4a22ca6fafa188f33afcdb7da013f))
* **core:** Drawer 옆 패널을 400 폭 · 안쪽 한 변 경계로 바꾸고 하단 영역을 더한다 (Part of [#5833](https://github.com/coco-de/coui/issues/5833)) ([#5875](https://github.com/coco-de/coui/issues/5875)) ([fd62739](https://github.com/coco-de/coui/commit/fd6273984bbb21200462f542328841e10351d76c))
* **core:** Fab 메뉴 패널 여백을 목록 여백 6 으로 맞춘다 (Part of [#5883](https://github.com/coco-de/coui/issues/5883)) ([#5899](https://github.com/coco-de/coui/issues/5899)) ([00bc31b](https://github.com/coco-de/coui/commit/00bc31be81e9bb745fc04fe62e7d1a13807549da))
* **core:** Filter 를 묶음 토글 기준으로 맞추고 초기화 버튼을 맨 뒤로 옮긴다 (Part of [#5881](https://github.com/coco-de/coui/issues/5881)) ([#5891](https://github.com/coco-de/coui/issues/5891)) ([f7df1af](https://github.com/coco-de/coui/commit/f7df1afa9be82381e3216a5b8dc8d5f4d0881038))
* **core:** Indicator 가 배지 둘레(surface 2px)를 그린다 (Part of [#5879](https://github.com/coco-de/coui/issues/5879)) ([#5888](https://github.com/coco-de/coui/issues/5888)) ([0c509a6](https://github.com/coco-de/coui/commit/0c509a6692c849d50d780f030c2ab54664faa38c))
* **core:** ItemPicker 비활성 행 글자와 체크가 비활성 전경색을 쓴다 ([#5865](https://github.com/coco-de/coui/issues/5865)) ([35ada10](https://github.com/coco-de/coui/commit/35ada108419023ecbe4cd0e2b7f5cd9f8727a1dc))
* **core:** Loading dots · bar · pulse 모양을 사본대로 맞춘다 (Part of [#5879](https://github.com/coco-de/coui/issues/5879)) ([#5893](https://github.com/coco-de/coui/issues/5893)) ([be78898](https://github.com/coco-de/coui/commit/be7889818dad8f7b041d8a4f6476f160cac67a42))
* **core:** OptionItem · OptionList 를 더한다 (Part of [#5833](https://github.com/coco-de/coui/issues/5833)) ([#5872](https://github.com/coco-de/coui/issues/5872)) ([176fa23](https://github.com/coco-de/coui/commit/176fa2360861b54164228d59ee4b660a5e66e6dc))
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
* **guard:** recognize nested item picker icon override ([#5843](https://github.com/coco-de/coui/issues/5843)) ([8026ccb](https://github.com/coco-de/coui/commit/8026ccb81ea0d370b223da3639e3eeee6e3e4979))
* preserve text selection alpha and hide OTP buffer selection ([#5840](https://github.com/coco-de/coui/issues/5840)) ([a044ade](https://github.com/coco-de/coui/commit/a044ade1753683d8acad6e46a85b014150fe3e32))
* **web,docs:** 중첩된 SwipeActions 행의 액션은 바깥 행의 호출자 핸들러에 닿지 않는다 ([#5846](https://github.com/coco-de/coui/issues/5846)) ([228b251](https://github.com/coco-de/coui/commit/228b251c4194525b339518ff89fa56d42b874eed))
* **web:** preserve FormattedInput placeholder color overrides ([#5848](https://github.com/coco-de/coui/issues/5848)) ([ac95d88](https://github.com/coco-de/coui/commit/ac95d886abdaa1dd5261c7d1566a8ba8b0828170))


### 리팩터링

* **core,flutter,web,figma,docs:** ContextMenu 들어 올림의 시각 값을 CoreContextMenuStyle 필드로 옮긴다 ([#5860](https://github.com/coco-de/coui/issues/5860)) ([7bc0a70](https://github.com/coco-de/coui/commit/7bc0a703bf255fdcda13d50ecdb0f18085a99270))

## [0.173.0](https://github.com/coco-de/coui/compare/coui_web-v0.172.0...coui_web-v0.173.0) (2026-10-29)


### 기능

* **core,flutter,web,docs:** ✨ iOS 27 유리 재질 — 서리 · 몸체 음영 튜닝 필드와 수치 프리셋 ios27 ([#5823](https://github.com/coco-de/coui/issues/5823)) ([aba0ab7](https://github.com/coco-de/coui/commit/aba0ab7078ae8cba3a7268d10433e8eb4ba8ab06))
* **core,flutter,web,figma,docs:** ✨ ContextMenu liftChild — 길게 누르면 child 를 들어 올리고 닫으면 원본으로 접는다 (옵트인) ([#5826](https://github.com/coco-de/coui/issues/5826)) ([46dae48](https://github.com/coco-de/coui/commit/46dae4871535b04028b4d29ed80098111db9e806))
* **core,flutter,web,figma:** ✨ Drawer — 열린 방향으로 더 끌면 고무줄처럼 늘어난다 (rubberBand, 기본은 꺼짐) ([#5821](https://github.com/coco-de/coui/issues/5821)) ([e8cda89](https://github.com/coco-de/coui/commit/e8cda89bb31312c935c3dc4ab8692087a6454a83))
* **core,flutter,web,tool,docs:** ✨ 적응형 품질 — 프레임이 디스플레이 속도를 못 지킬 때 유리를 매끄러움과 맞바꾼다 (adaptiveQuality, 기본은 꺼짐) ([#5824](https://github.com/coco-de/coui/issues/5824)) ([33d685b](https://github.com/coco-de/coui/commit/33d685b6568ebb9a54b856e5e4faae9b526dbefc))


### 버그 수정

* **core,flutter,web:** InputOtp 칸 테두리를 TextField 와 같은 단계로 (outlineVariant · hover outline) ([#5818](https://github.com/coco-de/coui/issues/5818)) ([0e36b4e](https://github.com/coco-de/coui/commit/0e36b4e8423e9f26a99a8a567f506ff0c38db3bb))
* **core,flutter,web:** Safari · Firefox 에는 굴절 참조를 붙이지 않는다 — 층이 다시 만들어지면 참조가 든 목록은 그려지지 않는다 ([#5819](https://github.com/coco-de/coui/issues/5819)) ([9f43945](https://github.com/coco-de/coui/commit/9f43945f1c9b7afe49f8219b1d339389dae7308f))
* **web,flutter,docs:** 밝기 범위 안에서 연 Web 패널도 그 범위의 밝기로 그린다 ([#5830](https://github.com/coco-de/coui/issues/5830)) ([dca3131](https://github.com/coco-de/coui/commit/dca31312011cde38cce56b414b4225edf0d7979e)), closes [#5828](https://github.com/coco-de/coui/issues/5828)

## [0.172.0](https://github.com/coco-de/coui/compare/coui_web-v0.171.0...coui_web-v0.172.0) (2026-10-28)

### 기능

* **swipe-actions:** add accessible swipeable list actions ([#5809](https://github.com/coco-de/coui/pull/5809)) ([7646e9b](https://github.com/coco-de/coui/commit/7646e9bdbd3e665f0f51cc225d1a817c607adb35))

### 버그 수정

* **select:** honor closeOnScroll for trigger ancestors and the viewport ([#5812](https://github.com/coco-de/coui/pull/5812)) ([f8f0aff](https://github.com/coco-de/coui/commit/f8f0affe988f4c79d2788b6424d25666155e04fc))
* **select:** allow content-width option panels ([#5810](https://github.com/coco-de/coui/issues/5810)) ([9aa27f7](https://github.com/coco-de/coui/commit/9aa27f7afd83147370037180294151f527e4ff04))

## [0.171.0](https://github.com/coco-de/coui/compare/coui_web-v0.170.0...coui_web-v0.171.0) (2026-10-28)


### 기능

* **outlined-container:** optionally preserve transparent border space ([ef67795](https://github.com/coco-de/coui/commit/ef677954fed71b9ae7705042db034a62a609acd6))

## [0.170.0](https://github.com/coco-de/coui/compare/coui_web-v0.169.0...coui_web-v0.170.0) (2026-10-28)


### 기능

* **core,flutter,web,figma,docs:** ✨ ContextMenu 에 글라이드로 고르기 · 미리보기 · 선택 햅틱을 더한다 ([#5803](https://github.com/coco-de/coui/issues/5803)) ([2acc41d](https://github.com/coco-de/coui/commit/2acc41dc3ff4e870e5a1027200d6f729bc3c1f0e))


### 버그 수정

* **web:** honor reduced motion for custom durations ([#5799](https://github.com/coco-de/coui/issues/5799)) ([b45737c](https://github.com/coco-de/coui/commit/b45737c4c400c3959c86efde5cfa6cb09e337422))

## [0.169.0](https://github.com/coco-de/coui/compare/coui_web-v0.168.0...coui_web-v0.169.0) (2026-10-28)


### 기능

* **core,flutter,web,docs:** ✨ 서페이스 튜닝에 모드별 채도·빛의 방향과 굴절 법칙을 더한다 ([#5795](https://github.com/coco-de/coui/issues/5795)) ([90cb7fe](https://github.com/coco-de/coui/commit/90cb7fea249c725cae607c611d0c4addf8eb904e))
* **glass:** ✨ liquid_glass_widgets 1.15 변경 반영 ([#5784](https://github.com/coco-de/coui/issues/5784)) ([8932fbf](https://github.com/coco-de/coui/commit/8932fbf69a166505b2ed13777935e666a976e3a0))
* **overlay:** ✨ 모달 메뉴 · 팝오버의 스크린 리더용 닫기 동작 ([#5789](https://github.com/coco-de/coui/issues/5789)) ([7f53395](https://github.com/coco-de/coui/commit/7f53395df9c704e31c93b2733db99294d9a70f71))


### 버그 수정

* **core,flutter,web,docs:** ✨ 여백이 다른 라벨 Divider 의 라벨을 Web 에서도 상자 정중앙에 둔다 ([#5794](https://github.com/coco-de/coui/issues/5794)) ([fb0a322](https://github.com/coco-de/coui/commit/fb0a32227a9f038c2bc2755c9ed0d4a01e8d062c))

## [0.168.0](https://github.com/coco-de/coui/compare/coui_web-v0.167.0...coui_web-v0.168.0) (2026-10-28)


### 기능

* **core,flutter,web,figma,docs:** TextArea 설명과 글자 수 사이 12, InputOtp lg 칸 테두리 1 ([#5781](https://github.com/coco-de/coui/issues/5781)) ([f589a89](https://github.com/coco-de/coui/commit/f589a89f8997dc0c0de3e83e439ff2b4979aea9c))


### 버그 수정

* **web,docs:** 글자 단계를 고정한 범위 안에서 연 Web 패널도 그 단계로 그린다 ([#5782](https://github.com/coco-de/coui/issues/5782)) ([156a1a3](https://github.com/coco-de/coui/commit/156a1a31560fe56356f4f89d8aab56ab7184b8ab))

## [0.167.0](https://github.com/coco-de/coui/compare/coui_web-v0.166.0...coui_web-v0.167.0) (2026-10-28)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma,docs:** display · headline 여섯 역할이 뷰포트 폭에 따라 작아진다 — 768 미만(mobile)은 36 · 32 · 28 · 24 · 20 · 16, 1024 미만(tablet)은 44 · 40 · 36 · 28 · 24 · 20 이고 1024 이상은 지금과 같다(52 · 48 · 44 · 32 · 28 · 24), mobile 의 headlineSmall 자간은 −1% 다. 모든 CoUIApp · CoUILayer · CoUIWeb 앱에 기본으로 적용되어 Text 체인 · TextBlock h1–h3 · PageHeader 제목 · Countdown · Stat 값 · AppBar prominent 제목도 함께 작아지고, Avatar 이니셜 · 배지와 TimePicker 세그먼트 행은 데스크톱 크기로 고정된다. 이전 크기를 유지하려면 CoUIApp(typographyTier: CoreBreakpointTier.desktop) · CoUILayer(typographyTier: CoreBreakpointTier.desktop) · CoUIWeb(typographyTier: CoreBreakpointTier.desktop) 로 고정한다. 함께 바뀌는 것: CoreTypography 의 == 가 22 역할의 값 비교가 되고, CoUIThemeController.setCustomTheme 이 타이포 변수를 더는 쓰지 않으며, Web Avatar 의 내용 · 배지와 TimePicker 세그먼트 행이 상자 없는 [data-coui-typography-tier] 래퍼 안에 놓여 직계 자식 선택자(>)가 닿지 않는다.

### 기능

* **core,flutter,web,figma,docs:** ✨ display · headline 을 뷰포트 단계(mobile · tablet · desktop)로 줄인다 ([#5774](https://github.com/coco-de/coui/issues/5774)) ([884c4cf](https://github.com/coco-de/coui/commit/884c4cf58d88114df651048927fb39ca04314900)), closes [#5568](https://github.com/coco-de/coui/issues/5568)


### 버그 수정

* **core,flutter,web,figma,docs:** 입력의 포커스 · 오류 테두리를 1 로, InputOtp lg 숫자를 SemiBold 로 ([#5780](https://github.com/coco-de/coui/issues/5780)) ([f60fa0f](https://github.com/coco-de/coui/commit/f60fa0f91a62702d79c6325b5c1c98552fb2abfe))
* **core,flutter,web,figma:** 비활성 Select 의 글자와 화살표를 필드의 비활성 색으로 그린다 ([#5777](https://github.com/coco-de/coui/issues/5777)) ([fe2aff4](https://github.com/coco-de/coui/commit/fe2aff4cd2888940f9cf5d394dd66fc97bd9c741))

## [0.166.0](https://github.com/coco-de/coui/compare/coui_web-v0.165.0...coui_web-v0.166.0) (2026-10-28)


### 기능

* **core,flutter,web,figma,docs:** 제목 역할 굵기를 700 에서 600 으로 낮춘다 ([6046f2a](https://github.com/coco-de/coui/commit/6046f2aee8cd76810a512159983a9bc93548044c))
* **core,flutter,web:** NumberInput 신설 ([#5762](https://github.com/coco-de/coui/issues/5762) 일부) ([260750d](https://github.com/coco-de/coui/commit/260750d0986b4e87cdbb4288bdee96913ebd9221))
* **figma,docs:** PanelHeader 기본 행동을 plain 버튼과 뒤 화살표로 맞춘다 ([#5768](https://github.com/coco-de/coui/issues/5768)) ([9066d8c](https://github.com/coco-de/coui/commit/9066d8ca60c13e9202f77eb5bb7123fe2f3d0b58))


### 리팩터링

* **core,flutter,web,docs:** NumberInput 크기를 자기 단계 enum 으로 두고 버튼 단계를 그 안에서 정한다 ([895240b](https://github.com/coco-de/coui/commit/895240b54838c72d466da152c2dd9765c7918f59))

## [0.165.0](https://github.com/coco-de/coui/compare/coui_web-v0.164.0...coui_web-v0.165.0) (2026-10-28)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma,docs:** ResolvedColorScheme 생성자가 errorIcon · successIcon · warningIcon · infoIcon 을 required 로 받고 CoreColorScheme 이 같은 필드를 가진다 — resolved() 로 만드는 경로는 그대로이고, ResolvedColorScheme 을 직접 만들거나 CoreSchemeSource 를 구현하는 앱은 칸을 더해야 한다. CoUI 상태 원시값이 바뀌어 상태 색을 쓰는 모든 렌더가 달라진다.
* **core,flutter,web,figma,docs:** `CoreButtonVariant` 에 `tonal` 멤버가 추가되어, 앱에서 이 enum 을 기본 분기 없이 exhaustive `switch` 하던 코드는 컴파일되지 않는다 — `tonal` 분기를 추가해야 한다. `outline` 버튼의 테두리 색이 `outline` 에서 더 옅은 `outlineVariant` 로 바뀌어 outline 버튼을 쓰는 화면의 골든/스냅숏이 움직인다.

### 기능

* **core,flutter,web,figma,docs:** ✨ Button tonal 변형 추가 · outline 테두리를 outlineVariant 로 ([#5704](https://github.com/coco-de/coui/issues/5704)) ([4c94c21](https://github.com/coco-de/coui/commit/4c94c21c23572a2616f0f08fa405c9031421fc82))
* **core,flutter,web,figma,docs:** ✨ Fab 메뉴를 MenuItem lg 행과 Fab 자신의 패널로 바꾼다 ([#5713](https://github.com/coco-de/coui/issues/5713)) ([e8a6b3b](https://github.com/coco-de/coui/commit/e8a6b3bf728c3ffa6ea07de402b3dc0ac1c7a288))
* **core,flutter,web,figma,docs:** ✨ Sidebar 신설 — 사이드바와 부품 6개 ([#5738](https://github.com/coco-de/coui/issues/5738)) ([#5750](https://github.com/coco-de/coui/issues/5750)) ([c121408](https://github.com/coco-de/coui/commit/c121408fd75cf1321fc01fce7694280eae616fcc))
* **core,flutter,web,figma,docs:** ✨ Tag — 분류색으로 구분만 하는 표시 전용 태그 (새 컴포넌트) ([#5706](https://github.com/coco-de/coui/issues/5706)) ([fba5789](https://github.com/coco-de/coui/commit/fba57897ebcc5267c1a0560541e30cf9932c0da9))
* **core,flutter,web,figma,docs:** ✨ 상태 색 램프를 새 값으로 바꾸고 상태 표시 슬롯 넷을 더한다 ([#5726](https://github.com/coco-de/coui/issues/5726)) ([3d092c0](https://github.com/coco-de/coui/commit/3d092c0603a73627c41fd2e83cc4c16a9ef0fb6d))
* **core,flutter,web,figma,docs:** NavigationBar 선택 표시 축을 더하고 미선택 목적지를 연하게 그린다 ([#5744](https://github.com/coco-de/coui/issues/5744)) ([deb49b5](https://github.com/coco-de/coui/commit/deb49b5fe068a2d3a0518361629e778fae0c0b87))
* **core,flutter,web,figma,docs:** 입력 필드 경계를 한 톤 낮추고 filled 변형을 더한다 ([#5757](https://github.com/coco-de/coui/issues/5757)) ([0b0199e](https://github.com/coco-de/coui/commit/0b0199eaa4688109370780588654ef381b328ce8))
* **core,flutter,web,figma,docs:** 컨트롤 라벨 굵기 · destructive 평소 옅은 error-container ([#5719](https://github.com/coco-de/coui/issues/5719)) ([bac19fb](https://github.com/coco-de/coui/commit/bac19fb66f46310516fd0e719484f62222088c97))
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
* **badge:** 긴 레이블이 부모 너비 안에서 줄바꿈되도록 수정 ([#5732](https://github.com/coco-de/coui/issues/5732)) ([a53b6eb](https://github.com/coco-de/coui/commit/a53b6ebc92fc69378ab41daefd3f426d293ed20b))
* **banner:** omit zero-width bottom rule on Flutter ([#5746](https://github.com/coco-de/coui/issues/5746)) ([0e3a01f](https://github.com/coco-de/coui/commit/0e3a01fd548f0df93c52b6e7f6693f0c2a508e9a))
* **dot-indicator:** expose one accessible control per item ([#5743](https://github.com/coco-de/coui/issues/5743)) ([f7f5cc3](https://github.com/coco-de/coui/commit/f7f5cc35556ab59a488b59c2c25ca58995121c90))
* **flutter:** 캐러셀 순환 인덱스와 활성 표시 계산 수정 ([#5714](https://github.com/coco-de/coui/issues/5714)) ([64ecb8d](https://github.com/coco-de/coui/commit/64ecb8dde69f0bcc970e4d93a6e500ec44ac472c))
* **focus-outline:** 0폭 포커스 링의 잔여 테두리 제거 ([#5728](https://github.com/coco-de/coui/issues/5728)) ([30c8075](https://github.com/coco-de/coui/commit/30c8075547939b96f6daf23117994bca307da940))
* **input-otp:** announce validation errors independently of code ([#5733](https://github.com/coco-de/coui/issues/5733)) ([1d02378](https://github.com/coco-de/coui/commit/1d0237815bc311bda951d1ac861ab1b9dbb9bb46))
* **outlined-container:** 🐛 0폭 테두리의 Flutter hairline 제거 ([a3e03ed](https://github.com/coco-de/coui/commit/a3e03ede073af406a99ccd72e1768002f58f4700))
* **outlined-container:** 🐛 Flutter의 0폭 테두리 hairline 제거 ([1e9e42c](https://github.com/coco-de/coui/commit/1e9e42c748584f2221d0534cd75df99752a71abb))
* **outlined-container:** 🐛 Web RGB 채널과 투명도 구분 ([#5721](https://github.com/coco-de/coui/issues/5721)) ([05003b8](https://github.com/coco-de/coui/commit/05003b86413c5ebc580e76ca188dc566a29127c9))
* **text-field:** 🐛 재구성 시 입력값과 커서 유지 ([5489742](https://github.com/coco-de/coui/commit/5489742a9f3b0bbf3f718d9d7ee5d2dc11d18740))
* **text-field:** 🐛 재구성 시 입력값과 커서 유지 ([491f3a7](https://github.com/coco-de/coui/commit/491f3a7684b361e14d223effb6eff06a7f2e7018))
* **web:** restore keyboard focus rings after pointer interaction ([#5761](https://github.com/coco-de/coui/issues/5761)) ([e624604](https://github.com/coco-de/coui/commit/e624604c826da2ce6a337b5930dcf0aa342de2ad))

## [0.164.0](https://github.com/coco-de/coui/compare/coui_web-v0.163.0...coui_web-v0.164.0) (2026-10-23)


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
* **web:** 🐛 Carousel 이전/다음 버튼이 Flutter 처럼 페이드로 드러난다 — 페이드를 감싸는 앵커로 옮기고 banner 호버 영역을 루트로 ([#5686](https://github.com/coco-de/coui/issues/5686)) ([#5691](https://github.com/coco-de/coui/issues/5691)) ([e8c4937](https://github.com/coco-de/coui/commit/e8c493759f47f0d4cf156e06f7a91b2cb58a16e0))
* **web:** 🐛 CarouselBanner 썸네일의 placeholder 아이콘이 박스를 채운다 — 좌상단에 24px 로 붙던 것 ([#5699](https://github.com/coco-de/coui/issues/5699)) ([3cd8853](https://github.com/coco-de/coui/commit/3cd885389392e7474270d8ff65bf2022b4ff2534))
* **web:** 🐛 ChipGroup scroll 레이아웃이 Web 에서 스크롤된다 — 루트가 부모 폭에 클램프되고 스크롤 행이 칩 폭을 갖는다 ([#5687](https://github.com/coco-de/coui/issues/5687)) ([#5692](https://github.com/coco-de/coui/issues/5692)) ([73a062f](https://github.com/coco-de/coui/commit/73a062f0bdd3812bb04436d15dcea09538397aac))

## [0.163.0](https://github.com/coco-de/coui/compare/coui_web-v0.162.0...coui_web-v0.163.0) (2026-10-23)


### ⚠ BREAKING CHANGES

* **web:** 웹 FormattedInput 의 기본 폭이 내용 폭(≈178px)에서 부모 폭으로 바뀐다. 좁게 쓰던 웹 소비자는 감싼 요소(또는 css)로 폭을 줘야 하고, 루트에 classes: 'w-64' 를 얹는 방식은 w-full 과 겹쳐 이기지 못할 수 있다. Flutter 는 변화 없음.
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
* **flutter,web:** 🐛 ThemeController — Flutter 팔레트가 높이 0 으로 접히던 것과 Web 선택 배지가 테두리 안쪽에 붙던 것을 고친다 ([#5644](https://github.com/coco-de/coui/issues/5644)) ([#5648](https://github.com/coco-de/coui/issues/5648)) ([53d31c7](https://github.com/coco-de/coui/commit/53d31c75a0e4de4e66e69a6d0cf2662355fdbaea))
* **web:** 🐛 FormattedInput 이 부모 폭을 채운다 — 웹 루트의 inline-flex 를 flex w-full 로 ([#5666](https://github.com/coco-de/coui/issues/5666)) ([#5668](https://github.com/coco-de/coui/issues/5668)) ([b30e5f0](https://github.com/coco-de/coui/commit/b30e5f04de6d646fee74b7768322bb7319b588d4))
* **web:** 🐛 overlay 패널을 top layer 로 올려 호스트 조상의 transform 에 좌표가 틀어지지 않게 한다 ([#5621](https://github.com/coco-de/coui/issues/5621)) ([#5625](https://github.com/coco-de/coui/issues/5625)) ([3b73122](https://github.com/coco-de/coui/commit/3b731227093539cd4c545e472becc41a12da816f))
* **web:** 🐛 TextField plain 이 쉬는 상태에 1px 테두리를 그리지 않게 한다 ([#5641](https://github.com/coco-de/coui/issues/5641)) ([#5645](https://github.com/coco-de/coui/issues/5645)) ([855e9d4](https://github.com/coco-de/coui/commit/855e9d48b0caca95e4ec5fae4ac0304fcef7140e))

## [0.162.0](https://github.com/coco-de/coui/compare/coui_web-v0.161.1...coui_web-v0.162.0) (2026-10-21)


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

## [0.161.1](https://github.com/coco-de/coui/compare/coui_web-v0.161.0...coui_web-v0.161.1) (2026-10-21)


### 버그 수정

* **flutter,web,core:** Liquid Glass AppBar의 네이티브 표면 구성 개선 ([#5545](https://github.com/coco-de/coui/issues/5545)) ([de5e46f](https://github.com/coco-de/coui/commit/de5e46f0f21a00e4fc6173661bf5ac71a6b880b1))

## [0.161.0](https://github.com/coco-de/coui/compare/coui_web-v0.160.0...coui_web-v0.161.0) (2026-10-19)


### 기능

* Liquid Glass 내비게이션 제스처와 컴포넌트 재질 오버라이드 ([#5502](https://github.com/coco-de/coui/issues/5502)) ([24a90a2](https://github.com/coco-de/coui/commit/24a90a2f735728f13dee17676df24a5594e7e08a))


### 버그 수정

* align Web and Flutter Liquid Glass interactions ([#5506](https://github.com/coco-de/coui/issues/5506)) ([05d7eba](https://github.com/coco-de/coui/commit/05d7ebacd7b3938fc68fd5c308f76037c99fbb78))
* keep hidden glass surfaces idle until measurable ([#5510](https://github.com/coco-de/coui/issues/5510)) ([7fadf98](https://github.com/coco-de/coui/commit/7fadf98715514bf32cfa777308dcd34f0675b442))

## 0.127.15 (2026-06-16)

### Refactored
- #2585 — DaisyUI color 레이어 전면 제거 (color_style.dart 삭제 + chain naming M3화) (#2601)

---

## Unreleased

- feat(tree): mirror node drag/drop intent, target feedback and keyboard input (#5090).
- feat(tree): mirror the opt-in lazy loading, stable node ids, slots and windowed rendering (#5081).

## [0.160.0](https://github.com/coco-de/coui/compare/coui_web-v0.159.0...coui_web-v0.160.0) (2026-10-16)


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

### 기능

* **core,figma:** Skeleton 리디자인 — 맥동 시작 70%, 사각형 반경 8, 텍스트 줄 12 / 간격 12 ([#5408](https://github.com/coco-de/coui/issues/5408)) ([c7fe05d](https://github.com/coco-de/coui/commit/c7fe05da77c0280980bf61185126261f2d06a1d1))
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
* **flutter,web,figma:** [#5429](https://github.com/coco-de/coui/issues/5429) — 서페이스 재질을 두 플랫폼이 같은 자리에 그린다 ([#5435](https://github.com/coco-de/coui/issues/5435)) ([79e24e4](https://github.com/coco-de/coui/commit/79e24e401d141219226d3a98e2efb02681b1b56a))
* **flutter,web,figma:** 서페이스 재질 파리티 후속 — 배지 재질 · 토큰 알파 × 몫 · 림은 진술한 스택에만 ([#5461](https://github.com/coco-de/coui/issues/5461)) ([92ee096](https://github.com/coco-de/coui/commit/92ee09639dfed6fbd439ecb51c0b471bbd6ea4f4))
* **web:** [#5448](https://github.com/coco-de/coui/issues/5448) — NavigationBar 바 모드 아이템 칩이 칸 폭을 채워 가운데에 놓인다 ([#5449](https://github.com/coco-de/coui/issues/5449)) ([9c8d84f](https://github.com/coco-de/coui/commit/9c8d84fe9ba6af366a9f2d40eb1580840209c9c9))

## [0.159.0](https://github.com/coco-de/coui/compare/coui_web-v0.158.1...coui_web-v0.159.0) (2026-10-12)


### ⚠ BREAKING CHANGES

* **core,flutter,web:** CoUI `:root` 의 프리미티브 CSS 변수 64개(`--coui-neutral-pure-white` … `--coui-error-darkest`)가 `--coui-<family>-<step>` 67개로 바뀌고 CoUI 기본 테마 색이 바뀐다(브랜드 PrimitiveColors 출력은 그대로). `CoreSurfaceToken.opacity` 의 타입이 `double` 에서 `CoreSurfaceOpacity` 로 바뀐다(`opacityIn(theme)` 또는 `.light` · `.dark` 로 읽는다). `ResolvedColorScheme` 생성자가 `outlineSubtle` 을 required 로 받는다. display · title 역할 굵기가 700 이 되고 Card 머리글 · Footer 섹션 제목 · EmptyState 제목이 역할 굵기를 따른다(Steps · Stepper 는 지금 단계만 700). 컨트롤 반경이 크기마다 달라진다(xs 6 · sm 8 · md 10 · lg 12 · xl 14 · xl2 16, 크기 없이 합성된 버튼 · 입력은 md 10). `CategoryBreakdown` 기본 범주 색에서 `tertiary` 가 빠진다(7 → 6색). `CoreMockupDeviceStyle` 의 하드웨어 색 기본값 12개가 Semantic 고정 슬롯에서 디자이너 사본 hex 로 바뀌어, 기기 몸체가 브랜드 테마에서도 브랜드 primary 를 따르지 않는다.
* **core,flutter,web:** Flutter · Web `TripleDots`, `CoreTripleDotsContract` · `CoreTripleDotsStyle` · `CoreTripleDotsTheme`, `CoreComponentTheme.tripleDots` 를 제거했다. 대체는 `Icon(LucideIcons.ellipsis)` (세로는 `LucideIcons.ellipsisVertical`)이고, count · dotSize · spacing 은 대응이 없으며 색은 `iconStyle` 로, 접근 가능한 이름은 호출하는 쪽이 붙인다.

### 기능

* **core,flutter,web:** CoUI 컬러 개편 — 고정 hex 숫자 단계 팔레트 · primary 잉크 · tertiary = primary ([#5339](https://github.com/coco-de/coui/issues/5339)) ([1c3de79](https://github.com/coco-de/coui/commit/1c3de79bea3e4d87a00cc0e591f8f10833c79bc6))
* **core,flutter,web:** TripleDots 를 제거한다 — 대체는 Icon(LucideIcons.ellipsis) ([#5390](https://github.com/coco-de/coui/issues/5390)) ([6990968](https://github.com/coco-de/coui/commit/6990968a9f29c218d070357637d9960d04c8a47c))

## [0.158.1](https://github.com/coco-de/coui/compare/coui_web-v0.158.0...coui_web-v0.158.1) (2026-10-11)


### 버그 수정

* **flutter,web:** Pagination 행이 가용 폭을 넘으면 단계적으로 줄인다 ([#5365](https://github.com/coco-de/coui/issues/5365)) ([e4b4ddd](https://github.com/coco-de/coui/commit/e4b4ddd3d2472e5666bee14e33621ee178514ac9))

## [0.158.0](https://github.com/coco-de/coui/compare/coui_web-v0.157.0...coui_web-v0.158.0) (2026-10-10)


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
* **flutter,web:** 가로 Stepper 단계 열이 행 폭을 넘지 않게 한다 ([#5356](https://github.com/coco-de/coui/issues/5356)) ([0284f1f](https://github.com/coco-de/coui/commit/0284f1f46f1e363d90a208c126702cf7c3030357))
* **flutter:** 컴포넌트 기본 아이콘을 패키지에 번들해 네트워크 없이 그린다 ([#5358](https://github.com/coco-de/coui/issues/5358)) ([e67dbf5](https://github.com/coco-de/coui/commit/e67dbf5afe27c9a29b95f75eb02a91860d868530))
* **mockup:** preserve system chrome geometry when resizing ([#5345](https://github.com/coco-de/coui/issues/5345)) ([e53e4cc](https://github.com/coco-de/coui/commit/e53e4cc4f00c454e574e21f6d8fdef9a7de7ca33)), closes [#5344](https://github.com/coco-de/coui/issues/5344)

## [0.157.0](https://github.com/coco-de/coui/compare/coui_web-v0.156.0...coui_web-v0.157.0) (2026-10-08)


### ⚠ BREAKING CHANGES

* **core,flutter,web:** MockupDevice 의 gestureBarHeight · gestureBarOffset 단위가 px 에서 iOS pt × 화면 배율로 바뀌고 gestureBarWidthRatio 는 deprecated 이며, CoreMockupDeviceLayout.compute · safeAreaInsets 의 시그니처와 ResolvedMockupDevice 필드가 바뀌고, mockupDeviceStyle.containerStyle.backgroundColor 로는 몸체 색을 더 이상 바꿀 수 없으며 (railColor · frameColor 를 쓴다), 하드웨어 기본 색이 hex 에서 Semantic 고정 슬롯으로 바뀌어 기본 모노크롬에서는 몸체 중간이 더 어둡고(#7d7f82 → #4d4e51) 렌즈 코어의 파란 링이 회색조가 되며 브랜드 램프를 읽는 매핑에서는 기기가 브랜드 색을 띤다

### 기능

* **core,flutter,web:** MockupDevice 리디자인 — 기기 모양 · 상태 표시줄 · 홈 인디케이터를 디자이너 사본대로 그린다 ([#5333](https://github.com/coco-de/coui/issues/5333)) ([f7a292c](https://github.com/coco-de/coui/commit/f7a292cd81984043d93eede87029f310c5e09db2))

## [0.156.0](https://github.com/coco-de/coui/compare/coui_web-v0.155.1...coui_web-v0.156.0) (2026-10-07)


### ⚠ BREAKING CHANGES

* **flutter:** iOS · Android 에서 CoUIApp 의 기본 배율이 1.25 에서 1 로 바뀌고 AdaptiveScaling.mobile 이 1 이 되어 scaling: .mobile 을 명시한 앱도 1.25 를 잃는다 — 이전 크기를 유지하려면 CoUIApp(scaling: const AdaptiveScaling(1.25)) 를 넘긴다.
* **core,flutter,web:** `CoreSkeletonStyle.duration` 은 이제 두 플랫폼 모두 맥동 왕복 한 번(쉼 → 정점 → 쉼)의 길이이고 기본값은 2000ms 다 — Flutter 에서 `duration` 을 직접 넘기던 호출자는 같은 값으로 두 배 빠르게 맥동하므로 지금 속도를 지키려면 값을 두 배로 넘긴다(Web 은 뜻이 같다).
* **core,flutter,web:** Skeleton(Flutter · Web)의 기본 생성자 · Skeleton.circle · Skeleton.text · copyWith 에서 enabled 파라미터가, CoreSkeletonContract 에서 enabled getter 가 제거됐다 — `Skeleton(enabled: isLoading)` 은 `if (isLoading) Skeleton(...)` 로 옮긴다. enabled: false 가 남기던 자리가 없어지므로 형제를 세어 간격을 주는 레이아웃(Flutter Column(spacing:), Web space-y-*)에서는 간격이 한 칸 줄어든다. asSkeleton(enabled:) 는 그대로다.

### 기능

* **core,flutter,web:** LoadingRegion — 로딩 알림을 영역 단위 한 번으로 ([#5309](https://github.com/coco-de/coui/issues/5309)) ([ad8aebc](https://github.com/coco-de/coui/commit/ad8aebc1464fb7ee42019e4a42fdfad626658615)), closes [#5281](https://github.com/coco-de/coui/issues/5281)
* **core,flutter,web:** Skeleton 의 enabled 를 제거한다 — 그릴지는 호출하는 쪽 조건이 정한다 ([#5275](https://github.com/coco-de/coui/issues/5275)) ([751cb4f](https://github.com/coco-de/coui/commit/751cb4f0c8d13db35e26278c907613c2edf41278))
* **core,flutter,web:** Tree 노드별 맥락 메뉴 — 행 우클릭에 ContextMenu 항목 (nodeContextMenu) ([#5273](https://github.com/coco-de/coui/issues/5273)) ([766ee95](https://github.com/coco-de/coui/commit/766ee9559bdd365e98a43a8a36e64a00adb68584))
* **core,flutter,web:** 동작 줄이기에서 Skeleton 맥동을 쉼 끝에 멈춘다 ([#5307](https://github.com/coco-de/coui/issues/5307)) ([d21f267](https://github.com/coco-de/coui/commit/d21f2673d6de056c2390f8d3858d0e4fb9a0e4f8)), closes [#5280](https://github.com/coco-de/coui/issues/5280)
* **core:** a11y/pointer-target-min 24 를 내보내고, 장치가 지키는 24 를 그 값 하나로 읽는다 ([#5292](https://github.com/coco-de/coui/issues/5292)) ([21ba169](https://github.com/coco-de/coui/commit/21ba1698ad8f0d5d3d9d1f96683a17bac0b74e1e)), closes [#5223](https://github.com/coco-de/coui/issues/5223)
* **flutter:** asSkeleton · SkeletonTheme 폐기 예고 — 대체는 Skeleton + LoadingRegion ([#5310](https://github.com/coco-de/coui/issues/5310)) ([9c318b6](https://github.com/coco-de/coui/commit/9c318b6fc99cb8a8822748d01b83840c9f493f3d))
* **flutter:** 휴대폰 기본 배율을 1.25 에서 1 로 — AdaptiveScaling.mobile 을 1 로 ([#5316](https://github.com/coco-de/coui/issues/5316)) ([98f161e](https://github.com/coco-de/coui/commit/98f161e839f193962b3625aae0962c1acbebd00e)), closes [#5311](https://github.com/coco-de/coui/issues/5311)
* **toggle:** 스위치에 전환 중에만 뜨는 유리 렌즈를 단다 ([#5196](https://github.com/coco-de/coui/issues/5196)) ([ae43134](https://github.com/coco-de/coui/commit/ae431340e562c006093995d370ce962ab513dc75))


### 버그 수정

* **core,flutter,web,figma:** TextField 상자가 control-size 를 최소 높이로 읽는다 — md 이상이 Button · 캔버스와 같은 높이 ([#5284](https://github.com/coco-de/coui/issues/5284)) ([f77427d](https://github.com/coco-de/coui/commit/f77427def287a6c065de9c7a3ac6efa44e7e427d)), closes [#5222](https://github.com/coco-de/coui/issues/5222)
* **core,flutter,web:** Skeleton 맥동 duration 을 왕복 한 번으로 — 두 플랫폼 같은 속도 · 같은 곡선 ([#5289](https://github.com/coco-de/coui/issues/5289)) ([151c820](https://github.com/coco-de/coui/commit/151c820de9ca75f8ebfca7bc0beaa2f3306ab667)), closes [#5279](https://github.com/coco-de/coui/issues/5279)
* **figma:** 캔버스가 코드와 같은 모양을 그리게 맞춘다 — 기본값 · Tabs 탭 3 · 아이콘 크기 ([#5308](https://github.com/coco-de/coui/issues/5308)) ([70766d5](https://github.com/coco-de/coui/commit/70766d55f98c68c819c3b8b847cdd9a6a37e33c3))

## [0.155.1](https://github.com/coco-de/coui/compare/coui_web-v0.155.0...coui_web-v0.155.1) (2026-10-03)


### 버그 수정

* **flutter:** scrollbar semantics의 본문 클릭 차단 수리 ([#5266](https://github.com/coco-de/coui/issues/5266)) ([e266186](https://github.com/coco-de/coui/commit/e26618638c8d84e26c79b02d1ba040a3638e37fe))

## [0.155.0](https://github.com/coco-de/coui/compare/coui_web-v0.154.0...coui_web-v0.155.0) (2026-10-03)


### 기능

* **core,flutter,web:** Tree 이름 바꾸기를 밖에서 시작하는 컨트롤러 (CoreTreeController) ([#5253](https://github.com/coco-de/coui/issues/5253)) ([b258990](https://github.com/coco-de/coui/commit/b25899019c56c038e6658380039b67597a658f4e))

## [0.154.0](https://github.com/coco-de/coui/compare/coui_web-v0.153.0...coui_web-v0.154.0) (2026-10-03)


### 기능

* **core,flutter,web:** Calendar 에 날짜 마커를 그린다 — 날짜별 점 · 개수 · 접근성 레이블 ([#5258](https://github.com/coco-de/coui/issues/5258)) ([76d3f46](https://github.com/coco-de/coui/commit/76d3f46b655fd86a01802d71859b047d0a6311fd))
* **core,flutter,web:** Tree 폴더 행 누름으로 여닫기 · 인라인 이름 바꾸기 (더블클릭 · F2) ([#5250](https://github.com/coco-de/coui/issues/5250)) ([f60a7a1](https://github.com/coco-de/coui/commit/f60a7a1519716dfb703c4cfb0ebd72844f484d57))

## [0.153.0](https://github.com/coco-de/coui/compare/coui_web-v0.152.0...coui_web-v0.153.0) (2026-10-02)


### 기능

* **core,flutter,web:** Skeleton 의 enabled 를 폐기 예고한다 — 대체는 호출자의 조건부 렌더 ([#5242](https://github.com/coco-de/coui/issues/5242)) ([cfa7fba](https://github.com/coco-de/coui/commit/cfa7fba5cc3814b033428e09b2d39f92c6fd2207))


### 버그 수정

* **flutter:** Skeleton 맥동이 채움의 알파에 곱해진다 — .transparent 가 검정으로 맥동하던 것 ([#5243](https://github.com/coco-de/coui/issues/5243)) ([7ffe64f](https://github.com/coco-de/coui/commit/7ffe64f4a715821c5e4f389d84e05bbbd8c4fda1))

## [0.152.0](https://github.com/coco-de/coui/compare/coui_web-v0.151.0...coui_web-v0.152.0) (2026-10-02)


### ⚠ BREAKING CHANGES

* **web:** Web `IconThemeData.color` 가 `String?`(Tailwind 토큰 이름)에서 `CoreColor?` 로 바뀐다 — `IconThemeData(color: 'on-surface')` 는 `IconThemeData(color: CoreColor.token(CoreColors.onSurface))` 로 쓴다. 토큰 색만 쓰는 기본 경로의 렌더는 바뀌지 않는다.

### 기능

* **core,flutter,web:** TextField · TextArea · Toggle 의 xs 를 예고한다 — assert 가 켜진 실행에서 한 번 로그 ([#5230](https://github.com/coco-de/coui/issues/5230)) ([eb4f70d](https://github.com/coco-de/coui/commit/eb4f70da3715691835bf1132ffb7b4cb2d9610ba))


### 버그 수정

* **core,flutter,web,figma:** EmptyState 캔버스를 코드대로 — compact 제목 역할 · 아이콘 48/32 · 간격 · 폭 · 기본 변형 ([#5216](https://github.com/coco-de/coui/issues/5216)) ([beb78d8](https://github.com/coco-de/coui/commit/beb78d831d282e68d6578b6ceae17383092ec56f))
* **web:** Icon 이 토큰 없는 raw 색을 inline 으로 칠한다 — text-#hex 클래스로 사라지던 색 ([#5215](https://github.com/coco-de/coui/issues/5215)) ([bc95d28](https://github.com/coco-de/coui/commit/bc95d287f9bf58c4d9dbcf4fe52bf450812a4bee)), closes [#5191](https://github.com/coco-de/coui/issues/5191)


### 리팩터링

* **flutter,web:** TextField 가 크기 행을 resolveSizeRow 로 고른다 ([#5225](https://github.com/coco-de/coui/issues/5225)) ([f653639](https://github.com/coco-de/coui/commit/f6536396c39886d073d317b34446da5de2df410a)), closes [#5218](https://github.com/coco-de/coui/issues/5218)

## [0.151.0](https://github.com/coco-de/coui/compare/coui_web-v0.150.0...coui_web-v0.151.0) (2026-10-01)


### ⚠ BREAKING CHANGES

* **mockup:** MockupBrowser 의 chromeWidth · toolbarHeight · toolbarPadding(좌·상·우)은 이제 몸체 바깥 가장자리에서 재므로 기본 창이 2px 낮아지고 카드·툴바 내용이 1px 바깥으로 옮겨진다(테두리를 두껍게 해도 창 크기는 그대로). 또 양 플랫폼 MockupBrowser.copyWith 의 addressBar 가 String? 에서 ValueGetter<String?> 로 바뀌어 `copyWith(addressBar: 'x')` 는 `copyWith(addressBar: () => 'x')` 로 고쳐야 한다.
* **core,flutter,web:** Web `Button` 이 인라인 스타일에서 `--btn-icon-size` · `--btn-icon-color` · `--btn-icon-color-hover` · `--btn-icon-color-disabled` 를 더 이상 내지 않는다(읽는 곳이 없던 변수). 대신 크기가 지정되지 않은 `Icon` 이 Button 사이즈 사다리(xs 16 · sm/md 20 · lg/xl 24 · xl2 28)를 따르므로, xs·lg·xl·xl2 Button 안의 맨 `Icon` 과 Web FAB 글리프(20 → 24/24/28)의 렌더 크기가 Flutter 와 같게 바뀐다. FAB 의 `buttonStyle.height/width` 는 여전히 `diameter` 가 이긴다.
* **text_field,phone_input,web:** Flutter `TextField.onTapUpOutside` 의 타입이 `TapRegionCallback?` 에서 `TapRegionUpCallback?`(PointerUpEvent)으로 바뀌고 `CoreTextFieldContract` 에 `TapUpOutCb` 타입 파라미터가 추가된다 — 콜백 인자를 `PointerDownEvent` 로 명시한 호출부는 `PointerUpEvent` 로 고친다(이전에는 호출된 적이 없다). `TextField` / `TextArea` 의 확대경 기본값이 비활성에서 플랫폼 확대경으로 바뀌고(끄려면 `TextMagnifierConfiguration.disabled`), 읽기 전용 `TextArea` 도 탭으로 포커스·선택을 받는다.
* **flutter:** JoinItemData 와 ResolvedJoin 생성자가 required `coreBorderRadius`(CoreBorderRadius, 스케일 전 값)를 받는다. 두 클래스를 직접 생성하던 코드는 스케일·geometry 적용 전의 같은 코너 값을 함께 넘겨야 한다 — 이미 스케일된 borderRadius 를 되돌려 넣으면 링이 두 번 스케일된다.

### 기능

* **core,flutter,web:** DraggablePanel dockType outside 도킹 구현 ([#2945](https://github.com/coco-de/coui/issues/2945)) ([#5089](https://github.com/coco-de/coui/issues/5089)) ([6f48d56](https://github.com/coco-de/coui/commit/6f48d5677b03cdd78d987bcd5f9362c310000711))
* **core,flutter,web:** Sortable 을 키보드로 재정렬한다 — 핸들 포커스 · 한 칸 이동 · 위치 안내 ([#4113](https://github.com/coco-de/coui/issues/4113)) ([#5183](https://github.com/coco-de/coui/issues/5183)) ([82863b2](https://github.com/coco-de/coui/commit/82863b2241bc989dc23b24f6a3ae30fa9af714df))
* **tree:** [#5136](https://github.com/coco-de/coui/issues/5136) 포인터 드래그 프록시와 계층별 삽입 공간 ([bfc23b1](https://github.com/coco-de/coui/commit/bfc23b1c70be60ff8ff465d4d6c1d67bf9377b7d))
* **tree:** preview depth-aware placement and reorder intent ([#5136](https://github.com/coco-de/coui/issues/5136)) ([0f0572b](https://github.com/coco-de/coui/commit/0f0572b6944f12f956efd438a0e6399bc2144901))


### 버그 수정

* **a11y:** 24 미만 버튼 터치 하한 전수 적용 · Checkbox 접근성 문서와 형제 id 중복 고정 ([#3969](https://github.com/coco-de/coui/issues/3969), [#4115](https://github.com/coco-de/coui/issues/4115)) ([#5124](https://github.com/coco-de/coui/issues/5124)) ([508b7b9](https://github.com/coco-de/coui/commit/508b7b9e082f0453788522fa5c0d75f7fd5eb3cb))
* **a11y:** 검증 에러 통보 · 팝업 열림 · 선택 상태가 리더에 닿게 한다 ([#4155](https://github.com/coco-de/coui/issues/4155)) ([#5099](https://github.com/coco-de/coui/issues/5099)) ([93240b1](https://github.com/coco-de/coui/commit/93240b1f064a9b0b9fd95c13a3381a696091ef8c))
* **core,flutter,web:** FAB 아이콘 슬롯 clobber 해소 + Web Button 이 아이콘 스타일을 실제로 소비 ([#4136](https://github.com/coco-de/coui/issues/4136)) ([#5098](https://github.com/coco-de/coui/issues/5098)) ([4bc8771](https://github.com/coco-de/coui/commit/4bc87712ca96d2b61bac9097b8ee15751f93adea))
* **core,flutter:** badge 포커스 링 기본 슬롯에 offsetColor 를 채워 Flutter 가 offset 밴드를 그리게 한다 ([#5154](https://github.com/coco-de/coui/issues/5154)) ([5e7c0de](https://github.com/coco-de/coui/commit/5e7c0de5967cddcb77ef1ba822062f0df8a21288))
* **flutter:** Join 안 포커스 링이 seam 쪽 모서리를 각지게 그린다 ([#4262](https://github.com/coco-de/coui/issues/4262)) ([#5156](https://github.com/coco-de/coui/issues/5156)) ([cd36f74](https://github.com/coco-de/coui/commit/cd36f742f487c4480a09374559d9872deac35d57))
* **l10n:** 정오·자정 AM/PM 과 시각 0-패딩을 coui_core 한 곳에서 계산 ([#3383](https://github.com/coco-de/coui/issues/3383)) ([#5085](https://github.com/coco-de/coui/issues/5085)) ([7e4824a](https://github.com/coco-de/coui/commit/7e4824a24d1edd0e60493d242722edd3f1f7c7fc))
* **mockup:** MockupBrowser 창 거리를 바깥 가장자리에서 재고 copyWith 로 주소창을 지울 수 있게 ([#5170](https://github.com/coco-de/coui/issues/5170)) ([9f7f1c7](https://github.com/coco-de/coui/commit/9f7f1c74284abd913482ef6122963b36a7a23cd6))
* **text_field,phone_input,web:** 부채 4건 — obscureText seed 문서화 · PhoneInput placeholder · 선언만 된 파라미터 배선 · CDN 위생 ([#5092](https://github.com/coco-de/coui/issues/5092)) ([50e5bca](https://github.com/coco-de/coui/commit/50e5bca1ec1cb1536fabfe0a6e7e6adb893b1dcf))
* **tree:** honor token guards and refresh figma export ([#5136](https://github.com/coco-de/coui/issues/5136)) ([287a739](https://github.com/coco-de/coui/commit/287a739837e2f66a47c858b51f13024ce04da0f6))
* **web,guards:** z-index 가드를 CI 에 배선하고 Dock -z-10 리터럴 정리 + 미배선 가드 검출 가드 ([#5167](https://github.com/coco-de/coui/issues/5167)) ([acf496b](https://github.com/coco-de/coui/commit/acf496ba4080c4b46c6db10eb0ba1d9394549b86))
* **web,parity:** 기본 elevation 카드 표면 림 · 프루닝 재확인 거짓 불일치 제거 ([#5123](https://github.com/coco-de/coui/issues/5123)) ([5bd7a9c](https://github.com/coco-de/coui/commit/5bd7a9ce990c387bd9bf78eb1a45de1644a85756))
* **web:** CoUIWeb·CoUIThemeController 소스 doc 정정 + CSS 없는 테마 이름 30개 deprecate ([#5133](https://github.com/coco-de/coui/issues/5133)) ([ec9c4e0](https://github.com/coco-de/coui/commit/ec9c4e0b574e647d995d42a213f84b4d24bcfa2b))
* **web:** text_area 포커스 링을 컴포넌트 default 슬롯 위에 쌓고 박스 모서리를 따라가게 한다 ([#4138](https://github.com/coco-de/coui/issues/4138)) ([#5153](https://github.com/coco-de/coui/issues/5153)) ([b0cfeb3](https://github.com/coco-de/coui/commit/b0cfeb31fec1b802f74762871099403db47b936e))

## [0.150.0](https://github.com/coco-de/coui/compare/coui_web-v0.149.0...coui_web-v0.150.0) (2026-09-28)


### 기능

* **tree:** cross-platform node-to-folder drag/drop ([#5090](https://github.com/coco-de/coui/issues/5090)) ([#5103](https://github.com/coco-de/coui/issues/5103)) ([82ad175](https://github.com/coco-de/coui/commit/82ad17525cda9718535d665b1a4cc3c48609a3cf))
* **tree:** lazy loading, stable keys and virtual rows ([#5081](https://github.com/coco-de/coui/issues/5081)) ([#5097](https://github.com/coco-de/coui/issues/5097)) ([97e14e7](https://github.com/coco-de/coui/commit/97e14e747371d7fb3a8f888464a1ba48dd59d04e))
* **tree:** 파일과 노드를 탐색 트리 행 사이에 직접 드롭 ([#5104](https://github.com/coco-de/coui/issues/5104)) ([#5105](https://github.com/coco-de/coui/issues/5105)) ([2db7bcc](https://github.com/coco-de/coui/commit/2db7bcc4bcecff4dc85d390ad2ac310766438025))


### 버그 수정

* **web:** 임의 boxBorderWidth override 가 Checkbox 렌더를 크래시시키던 경로를 emit family 로 막는다 ([#5093](https://github.com/coco-de/coui/issues/5093)) ([2af55a7](https://github.com/coco-de/coui/commit/2af55a7964037e42aecf1fc252a207bb04a4f841))

## [0.149.0](https://github.com/coco-de/coui/compare/coui_web-v0.148.0...coui_web-v0.149.0) (2026-09-28)


### ⚠ BREAKING CHANGES

* **flutter:** 역할 없이 굵기·색·크기·장식만 준 Flutter Text chain 은 이제 bodyMedium/onSurface 로 리셋되지 않고 주변 텍스트 스타일(슬롯 기본값·부모의 DefaultTextStyle)을 상속한다 — 예전 리셋 동작이 필요하면 역할을 명시한다(`Text('제목').semiBold` → `Text('제목').bodyMedium.semiBold`).

### 기능

* Block Hero with Layout=center|split ([#5062](https://github.com/coco-de/coui/issues/5062)) ([5fc7fd0](https://github.com/coco-de/coui/commit/5fc7fd0f4968d665eb70d9b97cf74aed04171da9))
* **drawer:** openDrawer 에 useRootNavigator · fillSafeArea — 탭 셸 하단 시트 ([#5075](https://github.com/coco-de/coui/issues/5075)) ([ebeb823](https://github.com/coco-de/coui/commit/ebeb823a4a2e6bdfc2661f7a289e8c969e85253f))
* **flutter:** 역할 없는 Text chain 이 주변 텍스트 스타일을 상속한다 ([#4080](https://github.com/coco-de/coui/issues/4080)) ([#5052](https://github.com/coco-de/coui/issues/5052)) ([833f693](https://github.com/coco-de/coui/commit/833f69331735694cbd9a2dab16620fd8e3f137bf))
* **web:** collection ARIA role 이 약속한 키보드를 컴포넌트별로 — tree · tablist · listbox · menubar · radiogroup ([#3968](https://github.com/coco-de/coui/issues/3968)) ([#5057](https://github.com/coco-de/coui/issues/5057)) ([3292445](https://github.com/coco-de/coui/commit/329244595cb63cabf76a1db963b1528d3f68b551))


### 버그 수정

* **figma:** Carousel radius16 and NavigationBar 10px section captions ([24000f4](https://github.com/coco-de/coui/commit/24000f4b4ef40adcb62589a33dfee4c12c57ce50))
* **text-field:** TextField 가 FormField 에 값을 보고한다 — FormValueSupplier 복원 ([#5072](https://github.com/coco-de/coui/issues/5072)) ([5a46aad](https://github.com/coco-de/coui/commit/5a46aad35907fb5592f0548f38c661f0863ae397))

## [0.148.0](https://github.com/coco-de/coui/compare/coui_web-v0.147.0...coui_web-v0.148.0) (2026-09-23)


### 기능

* **button:** Web 과 데스크톱 Flutter 에도 누름 축소를 — CoreButtonStyle.pressedScale 한 필드에서 ([#5047](https://github.com/coco-de/coui/issues/5047)) ([3a886c3](https://github.com/coco-de/coui/commit/3a886c31ddedf8592482f482f6f0b94c5ce15944)), closes [#4427](https://github.com/coco-de/coui/issues/4427)
* **core,flutter,web,docs:** HeroSection appear-on-scroll entrance ([#5033](https://github.com/coco-de/coui/issues/5033)) ([474b5f1](https://github.com/coco-de/coui/commit/474b5f14e7abf722110b459d3e0a9e4f55d49bfc))
* **core,flutter,web:** [#5036](https://github.com/coco-de/coui/issues/5036) — Button href 가 활성일 때 진짜 &lt;a&gt; 다 ([#5038](https://github.com/coco-de/coui/issues/5038)) ([c847b6d](https://github.com/coco-de/coui/commit/c847b6d402d9cd5eed896aec3336dd21c3a2092c))
* **core,flutter,web:** TabPane editorStrip — official IDE strip-only API ([#5032](https://github.com/coco-de/coui/issues/5032)) ([ff0fd28](https://github.com/coco-de/coui/commit/ff0fd28d12bae435feab680fd392a5c11d738bb9))
* **core,flutter,web:** 드래그가 스크린 리더에 말하고, 배선 실수를 보고한다 ([#4939](https://github.com/coco-de/coui/issues/4939)) ([#5012](https://github.com/coco-de/coui/issues/5012)) ([bf562af](https://github.com/coco-de/coui/commit/bf562af04531e931678cec415d33704712dc5a62))
* **core,flutter,web:** 라벨 보유 컨트롤에 labelMaxLines · labelOverflow 노출 ([#2880](https://github.com/coco-de/coui/issues/2880)) ([#5040](https://github.com/coco-de/coui/issues/5040)) ([1636f6d](https://github.com/coco-de/coui/commit/1636f6dbcdcb42cc40e12a881bbdf7658b3a3c2f))
* **core,flutter,web:** 타이핑한 dial code 로 국가를 고른다 — 모호하면 그대로 둔다 ([#5031](https://github.com/coco-de/coui/issues/5031)) ([c407b89](https://github.com/coco-de/coui/commit/c407b89ffeb22391d84583b63b53d3ecfc991f49)), closes [#4247](https://github.com/coco-de/coui/issues/4247)
* **core,web:** 브랜드 accent 역할과 마케팅 크롬 레시피 ([#5045](https://github.com/coco-de/coui/issues/5045)) ([e89068a](https://github.com/coco-de/coui/commit/e89068a0a9e85d1a860ce151f7842d716b70ad86))
* **flutter,web:** Link.inlineSpan — 문장 안에서 줄바꿈되고 주변 타이포를 따르는 링크 ([#5046](https://github.com/coco-de/coui/issues/5046)) ([a0d2446](https://github.com/coco-de/coui/commit/a0d2446b62a283735a8e177cb428f4724ecc00cf))
* **lints:** copyWith 가 필드를 빠뜨리면 CI 가 막는다 — avoid_incomplete_copy_with ([#5017](https://github.com/coco-de/coui/issues/5017)) ([1e8bfe2](https://github.com/coco-de/coui/commit/1e8bfe2cb95a5ef74b9eda15137a964c65311406))
* **lints:** k 접두 · handle 어간 · child 마지막을 CI 가 막는다 ([#5021](https://github.com/coco-de/coui/issues/5021)) ([b786ce1](https://github.com/coco-de/coui/commit/b786ce1795ecc9061dabd4cd156f198af3b117d0))


### 버그 수정

* **a11y:** Chip 제거 버튼에 이름과 터치 하한을, Web Checkbox 에서 중복 정체성을 걷어낸다 ([#5018](https://github.com/coco-de/coui/issues/5018)) ([94d4563](https://github.com/coco-de/coui/commit/94d45631f780d6b84bed50970570a108f7a4cbd9))
* **web:** [#3708](https://github.com/coco-de/coui/issues/3708) — Sortable .horizontal/.grid 아이템 폭 = 콘텐츠 폭 ([#5024](https://github.com/coco-de/coui/issues/5024)) ([5dc42e0](https://github.com/coco-de/coui/commit/5dc42e0d0a3455b0683ccae5bc1bca8ad7f989c1))
* **web:** [#5027](https://github.com/coco-de/coui/issues/5027) — text_field 값/placeholder/affix 가 size-table 의 line-height overlay 를 잃지 않는다 ([#5028](https://github.com/coco-de/coui/issues/5028)) ([6f18a0d](https://github.com/coco-de/coui/commit/6f18a0dbaaacf18c5ae0e179cf87c2343a338202))
* **web:** Frame row/column 자식을 Flutter 처럼 non-shrink 기본으로 ([#5051](https://github.com/coco-de/coui/issues/5051)) ([d0bb33d](https://github.com/coco-de/coui/commit/d0bb33d136a586276dbc0fe97b537c1a1f2a5305)), closes [#3127](https://github.com/coco-de/coui/issues/3127)


### 리팩터링

* **core,flutter,web:** Label.htmlFor 를 deprecate 하고 라벨↔컨트롤 연결을 FormField 로 안내한다 ([#5030](https://github.com/coco-de/coui/issues/5030)) ([965b364](https://github.com/coco-de/coui/commit/965b364ddc4c9d6a5e6a4e3a8d2b71eeddecca90))

## [0.147.0](https://github.com/coco-de/coui/compare/coui_web-v0.146.0...coui_web-v0.147.0) (2026-09-20)


### 기능

* **core,flutter,web,docs:** Command keywords + shadcn-parity 문서 예시 ([#4989](https://github.com/coco-de/coui/issues/4989)) ([#4990](https://github.com/coco-de/coui/issues/4990)) ([3ba75b8](https://github.com/coco-de/coui/commit/3ba75b82e3e3e3f9e4bfef2ba234689601862cab))

## [0.146.0](https://github.com/coco-de/coui/compare/coui_web-v0.145.0...coui_web-v0.146.0) (2026-09-17)


### ⚠ BREAKING CHANGES

* **core,flutter:** `CoreGlassMaterial` 과 그 층 모델이 사라진다 — `CoreSurfaceToken.glass` 는 `material:` 을 받지 않고, `CoreSurfaceToken.glass` 필드와 `toJson()` 의 `'glass'` 키가 없어진다. `CoreColorScheme` 의 `glassTint`/`glassHighlight`/`glassShadow`/`glassIllumination` 과 같은 이름의 `CoreColors` 토큰 4개, `ResolvedColorScheme` 의 같은 super-parameter 4개도 함께 사라진다 — 어떤 팔레트도 채우지 않고 CSS 생성기도 내보내지 않던 슬롯이라, 반투명 표면은 `liquidGlass` 서페이스 스타일이 `opacity`/`blurRadius` 로 진술한다. Flutter `Switcher.curve` 와 `resolveSwitcher(legacyCurve:)` 도 사라진다 — 전환 easing 은 `switcherStyle: CoreSwitcherStyle(curve: CoreEasing.*)` 로 들어가고, 그것만이 Web 트윈이 읽을 수 있는 형태다.
* **core,flutter,web:** `CoreThemeData.cornerStyle` 과 `.defaultMotion` 이 `copyWith` 파라미터·`toJson()` 키와 함께 제거됐다 — 직렬화된 테마가 더 이상 `cornerStyle`·`defaultMotion` 을 싣지 않는다. 모서리 기하는 표면 기하 제약으로, 모션은 duration·easing tier 로 진술한다. `Text` 체인의 `.primary`·`.secondary`·`.tertiary`·`.error`·`.success`·`.warning`·`.info` 가 제거됐다 — `.on{Role}Container` 를 쓴다(Web 은 애초에 그것만 있었다). `MockupPhone` typedef · `MockupDevice.mockupPhoneStyle` · `CoreComponentTheme.mockupPhone` · `CoreEasing.standard`·`.decelerate`·`.accelerate`·`.spring` · `ColorPalette` · `CoreContentPadding` · `saturationColorMatrix` · `AxisDirectional` · `resolveTimePicker(scopeId:)` 도 제거됐다.
* **core,flutter,web:** `CoreCheckboxState` enum(과 `toChecked`/`fromChecked`) · `CoreCheckboxVariant` enum · `CoreCheckboxVariantStyle` 클래스 · `CoreCheckboxStyle` 의 `defaultsByVariant` 와 `indeterminateSize` · `CoreCheckboxTheme.variantStyles` · Flutter `Checkbox.state` getter 가 제거됐다 — 체크 상태는 tristate `bool?` 이고 checkbox 에는 variant 축이 없다. `CoreScaffoldStyle` 의 `headerPadding` · `headerSpacing` · `headerActionSpacing` 과 그 `default*` 셋, 그리고 양 플랫폼 `AppBar.scaffoldStyle` 과 `resolveAppBar(legacyScaffoldPatch:)` 파라미터도 제거됐다 — AppBar 의 chrome 은 `appBarStyle` 로 직접 진술한다. 레포 안에 이 값들을 실제로 넘기는 호출자가 하나도 없어 렌더는 바뀌지 않는다.

### 기능

* **core,flutter,web:** checkbox·scaffold deprecation 14 심볼 제거 — 웨이브 2 완료 ([#4964](https://github.com/coco-de/coui/issues/4964)) ([d6d47dd](https://github.com/coco-de/coui/commit/d6d47ddef89c270aeb5c191176d2cb1265f65f7b))
* **core,flutter,web:** 인프라 deprecation 29 심볼 제거 — 웨이브 3b ([#4968](https://github.com/coco-de/coui/issues/4968)) ([ec557aa](https://github.com/coco-de/coui/commit/ec557aa465a4137e12417aa866763bcc815a4701))
* **core,flutter:** glass 층 모델과 Switcher.curve 제거 — 결정 (B) 적용 ([#4970](https://github.com/coco-de/coui/issues/4970)) ([584c943](https://github.com/coco-de/coui/commit/584c9437275261f58758431c0935b6e47b9c91f5))
* **docs-site:** 홈을 컴포넌트 쇼케이스 랜딩으로 재구축 — 히어로 · 대표 컴포넌트 · 카테고리 · 푸터 ([#4986](https://github.com/coco-de/coui/issues/4986)) ([5513054](https://github.com/coco-de/coui/commit/55130546e645dcd00fc3c372500ce76c11b76566))


### 버그 수정

* **parity:** [#4873](https://github.com/coco-de/coui/issues/4873) — Web 예제·컴포넌트 root 가 800 을 채우지 않고 hug 한다 ([#4966](https://github.com/coco-de/coui/issues/4966)) ([108c4c2](https://github.com/coco-de/coui/commit/108c4c2ccfee5f96c5d9663ccce31db644390721))
* **parity:** [#4874](https://github.com/coco-de/coui/issues/4874) — Join 교차축 fill 이 버튼 높이를 덮지 않고 ChipGroup 이 hug 한다 ([#4967](https://github.com/coco-de/coui/issues/4967)) ([c7bb343](https://github.com/coco-de/coui/commit/c7bb3437df8bdfd008b970821435bac5ab667ac0))

## [0.145.0](https://github.com/coco-de/coui/compare/coui_web-v0.144.0...coui_web-v0.145.0) (2026-09-17)


### ⚠ BREAKING CHANGES

* **core,flutter,web:** `CoreMenuStyle` 의 `itemButtonStyle` · `itemPadding` · `itemContentGapStyle` · `shortcutTextStyle` · `chevronIconStyle` · `markIconStyle` 과 그 `default*` 7 개가 제거됐다 — 전부 `itemStyle: CoreMenuItemStyle(...)` 안의 대응 필드로 옮긴다. `CoreSelectStyle` 의 `optionButtonStyle` · `searchInputStyle` · `searchInputPadding` 과 그 `default*` 셋, `CoreSelectContract` 의 `searchable` · `searchPlaceholder` · `onSearchChanged`(및 양 플랫폼 `Select` 위젯의 그 셋)도 제거됐다. Select 의 검색 표면은 대체재가 없다 — 타입어헤드가 필요하면 `Autocomplete` 를 쓴다. 이 필드들을 아무도 넘기지 않으면 렌더는 그대로다(default 경로에서 fold 가 no-op 이었다); 실제로 넘기던 호출자만 영향을 받는다.
* **core,flutter,web:** `CoreCardImageStyle` 의 `backgroundColor` · `borderColor` · `borderRadius` 와 `defaultBackgroundColor` · `defaultBorderColor` · `defaultBorderRadius` 가 제거됐다 — 셋 다 `frameStyle: CoreOutlinedContainerStyle(...)` 안의 같은 이름 필드로 옮긴다. `CorePhoneInputContract` 의 `filterZeroCode` · `filterCountryCode` 와 `CorePhoneNumber.fromInput` 의 같은 이름 파라미터, 그리고 양 플랫폼 `PhoneInput` 위젯의 두 필드가 제거됐다 — 대체재는 없다. 두 플래그는 어떤 resolver 도 읽지 않았으므로(양 플랫폼 `fromInput` 이 `filterPlusCode` 만 읽는다) 제거가 동작을 바꾸지 않는다. 앱 렌더 변화는 없지만 **다음 Generate 에서 Figma 캔버스의 CardImage 프레임이 채움+보더에서 투명으로 바뀐다** — 캔버스가 코드가 칠한 적 없는 것을 그리고 있던 것의 교정이다.
* **core,flutter,web:** `CoreBannerVariant.default_` 와 `CoreToastVariant.default_` 별칭이 제거됐다 — `neutral` / `success` 를 직접 쓴다. `CoreBannerStyle`·`CoreBannerVariantStyle`·`CoreToastVariantStyle` 의 `background` · `foreground`, `CoreBannerStyle.defaultDismissForegroundOpacity` · `defaultDismissHoverForegroundOpacity`, `CoreCommandStyle` 의 `disabledAlpha` · `emptyStyle` · `chromelessSearchFieldStyle` 도 제거됐다. **이 중 둘은 렌더를 바꾼다**: Web banner 의 닫기 글리프가 더 이상 70% 로 흐려지지 않고(Flutter 와 일치), Command 의 비활성 행이 알파 곱 대신 `itemDisabledForegroundColor` 를 칠한다. 닫기 글리프 색을 바꾸려면 `closeButtonStyle.foregroundColor` / `hoverForegroundColor` 로 토큰을 직접 진술한다.
* **core:** `CoreObjectInputStyle` 의 `shortFieldMaxChars` · `mediumFieldMaxChars`, `CoreBadgeStyle`·`CoreBadgeVariantStyle` 의 `background` · `foreground` · `hoverBackground`, `CoreWindowStyle.resizeThickness`, `CoreDrawerStyle.dragDismissThreshold`, `CoreSkeletonStyle`·`CoreSkeletonVariantStyle` 의 `background`, `CoreToggleStyle` 의 `disabledTrack` · `disabledForeground`, `CoreRadioGroupStyle` 의 `disabledBackground` · `disabledForeground`, `CoreDialogStyle` 의 `background` · `foreground`, `CoreChipStyle` 의 `defaultHoverOpacity` · `defaultLowUnselectedForegroundColor`, `CoreTabContract` typedef, `CoreAspectRatioBoxStyle.designSystemRatio` 와 각각의 `default*` 가 제거됐다. 대부분 `Color` 접미사가 붙은 이름으로 바뀐 것이라 기계적 치환이 안전하다 — 다만 `resizeThickness` 는 Style 이 아니라 **위젯 파라미터** `Window(resizeThickness:)` 가 정본이고 그쪽은 그대로다.
* **core,flutter,web:** `CoreButtonVariant` 의 `text` · `card` 값이 제거됐다 — `text` 는 `link` 또는 `plain` 으로, `card` 는 `outline` + `withStyle(borderRadius: radius16)` 으로 대체한다. `CoreButtonStyle`·`CoreButtonVariantStyle` 의 색 별칭 13 개, `CoreFabStyle` 의 `actionLabel{BackgroundColor,BoxShadow,Padding,BorderRadius}` · `actionDiameter` · `actionGapStyle`, `CoreTextAreaStyle`·`CoreTextFieldStyle` 의 `background` · `scrollPadding` 과 그 `default*` 들도 함께 제거됐다. 전부 이름만 바뀐 것이라 메시지가 가리키는 대체재로 기계적 치환이 안전하다 — 단 `scrollPadding` 은 Style 이 아니라 **위젯 파라미터** 쪽(`CoreTextAreaContract.defaultScrollPadding`)이 정본이고 그쪽은 그대로 있다.
* **core,flutter,web:** `CoreAlertStyle` 의 `background` · `foreground` · `dismissIdleOpacity` · `defaultDismissIdleOpacity` 와 `CoreAlertVariantStyle` 의 `background` · `foregroundColor` · `borderColor` 가 제거됐다. `background`/`foreground` 는 `backgroundColor`/`foregroundColor` 로 이름만 바뀐 것이라 기계적 치환이 안전하다. `dismissIdleOpacity` 는 대체재가 없다 — 닫기 글리프 색은 `closeButtonStyle.foregroundColor` / `hoverForegroundColor` 로 토큰을 직접 진술한다. `CoreAlertVariantStyle` 의 셋은 렌더에 도달한 적이 없어 제거가 시각을 바꾸지 않는다.

### 기능

* **core,flutter,web:** alert 의 deprecation 7 심볼 제거 — 웨이브 1 첫 조각 ([#4952](https://github.com/coco-de/coui/issues/4952)) ([0c382eb](https://github.com/coco-de/coui/commit/0c382ebfe6c2e25dd8b5596cb201bcb06b658164))
* **core,flutter,web:** banner·command·toast deprecation 12 심볼 제거 — 웨이브 2 시작 ([#4957](https://github.com/coco-de/coui/issues/4957)) ([faf9b8f](https://github.com/coco-de/coui/commit/faf9b8f7ec6898b9bd8ecce6ef133695f4f33f20))
* **core,flutter,web:** button·fab·text_area·text_field deprecation 38 심볼 제거 ([#4955](https://github.com/coco-de/coui/issues/4955)) ([3c325bb](https://github.com/coco-de/coui/commit/3c325bbf053d9022c56e41d299d8db989d85d904))
* **core,flutter,web:** card_image·phone_input deprecation 10 심볼 제거 ([#4958](https://github.com/coco-de/coui/issues/4958)) ([315566e](https://github.com/coco-de/coui/commit/315566e1df6f997ad12c11eb609f303158f04e7e))
* **core,flutter,web:** menu·select deprecation 22 심볼 제거 ([#4960](https://github.com/coco-de/coui/issues/4960)) ([a0cd0b3](https://github.com/coco-de/coui/commit/a0cd0b3f4a13ab41c4e53f9d02317f92b3be27e4))
* **core:** W1 잔여 11 컴포넌트 deprecation 25 심볼 제거 — 웨이브 1 완료 ([#4956](https://github.com/coco-de/coui/issues/4956)) ([fe67057](https://github.com/coco-de/coui/commit/fe670578941aeb9d0da7596183bb9a50dd45a1c8))

## [0.144.0](https://github.com/coco-de/coui/compare/coui_web-v0.143.0...coui_web-v0.144.0) (2026-09-17)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** `CoreTabVariantStyle` 이 required `disabledIndicatorColor` 를 받는다. 이 클래스를 직접 만들어 `CoreTabsTheme.variantStyles` 에 넣던 코드는 그 값을 더해야 한다 — 면을 칠하는 변형이면 `CoreColor.token(CoreColors.disabledContainer)`, 선을 그리는 변형이면 `CoreColor.token(CoreColors.disabledContent)`. 그리고 `pill` 의 "비활성 + 선택" 채움이 `surface`(Flutter) · `disabled-content`(Web) 에서 둘 다 `disabled-container` 로 바뀌므로 그 자세의 렌더가 달라진다.

### 기능

* **core,flutter,web,figma:** 비활성 선택 탭의 표시는 변형마다 다른 토큰 — 알약은 면, 밑줄은 선 ([#4924](https://github.com/coco-de/coui/issues/4924)) ([42806b3](https://github.com/coco-de/coui/commit/42806b3ac3bdb806577dcca51bf770b5f41716a3))
* **core,flutter,web:** FileInput 이 받은 파일을 저장한다 — 행 저장 버튼 + CoFileSaver ([#4934](https://github.com/coco-de/coui/issues/4934)) ([#4938](https://github.com/coco-de/coui/issues/4938)) ([02a997d](https://github.com/coco-de/coui/commit/02a997d5e0c5e85b340a11de38ea44e54a949981))
* **core,flutter,web:** FileInput 이 실제 파일 드롭을 받는다 — desktop_drop + Web 폴더 순회 ([#4932](https://github.com/coco-de/coui/issues/4932)) ([#4936](https://github.com/coco-de/coui/issues/4936)) ([b74dc4a](https://github.com/coco-de/coui/commit/b74dc4a6a71de75f75d6e9d88a006bbc85dda77d))
* **core,flutter,web:** FileInput 이 폴더를 고르고 그 안의 파일을 받는다 ([#4933](https://github.com/coco-de/coui/issues/4933)) ([#4937](https://github.com/coco-de/coui/issues/4937)) ([12c1681](https://github.com/coco-de/coui/commit/12c16817ea287fd805f769e0e14b7085186325f7))

## [0.143.0](https://github.com/coco-de/coui/compare/coui_web-v0.142.0...coui_web-v0.143.0) (2026-09-15)


### ⚠ BREAKING CHANGES

* **core:** `CoreMockupDeviceContract` 가 `orientation` getter 를 요구하고 `resolveMockupDevice` / `CoreMockupDeviceLayout.compute` 가 required `orientation` 을 받는다. 가로를 `screenAspectWidth`/`screenAspectHeight` 로 저작하던 호출은 이제 세로로 그려진다 — 비율이 긴 변 먼저로 정규화되고 방향은 `orientation` 이 정하므로, `orientation: .landscape` 로 옮기고 비율 override 는 지운다. 폰 가로의 버튼도 좌우 변에서 위/아래 변으로 옮겨간다.
* **core,flutter,web,figma:** `Tabs.size` 와 `CoreTabsContract.size` 가 `CoreComponentSize` 에서 `CoreTabsSize`(sm/md/lg)로 바뀐다 — `xs`/`xl`/`xl2` 는 사라지고, `CoreTabsStyle.defaultsBySize` 의 키도 같이 바뀐다. `CoreEmptyStateStyle` 은 `maxDescriptionWidth` 가 `maxTextWidth` 로 개명되고 `backgroundColor`·`borderColor`·`borderWidth`·`borderRadius`·`iconContainerSize`·`iconContainerColor`·`iconContainerShape`·`iconColorAlpha`·`borderAlpha`·`descriptionAlpha`·`iconSizeRatio` 열한 필드와 `CoreEmptyStateIconShape` enum 이 제거된다 — 리디자인이 그 필드들이 그리던 박스와 아이콘 컨테이너를 없앴으므로 후임이 없다.

### 기능

* **core,flutter,web,figma:** EmptyState 는 상자를 버리고, Tabs 는 사다리를 좁힌다 ([06da3df](https://github.com/coco-de/coui/commit/06da3dfbbe0473d907c46acd803a7c765f09f6ec))
* **core:** [#4914](https://github.com/coco-de/coui/issues/4914) — MockupDevice 의 Orientation 축, 돌린 몸체가 버튼을 데려간다 ([5d6024a](https://github.com/coco-de/coui/commit/5d6024a3a99600b92f3eaf384d33619161b4ddc0))
* **mockup-device:** 카메라·제스처 바 표시 옵션과 SafeArea ([#4918](https://github.com/coco-de/coui/issues/4918)) ([bb430b1](https://github.com/coco-de/coui/commit/bb430b1b39156f60c040142ef0a270ce774bf9bc)), closes [#4913](https://github.com/coco-de/coui/issues/4913)

## [0.142.0](https://github.com/coco-de/coui/compare/coui_web-v0.141.1...coui_web-v0.142.0) (2026-09-15)


### ⚠ BREAKING CHANGES

* **core:** `CoreMockupDeviceStyle`(옛 `CoreMockupPhoneStyle`)의 `cameraColor` 가 제거됐다 — 카메라 컷아웃은 렌즈 링을 품으면 `cutoutColor`, 링이 없으면(컷아웃 자체가 렌즈) `lensColor` 를 받으므로 그 두 슬롯으로 옮긴다. (#4895 에서 이미 반영)
* **core:** MockupPhone 이 MockupDevice 로 개명됐고(Flutter·Core 는 deprecated 별칭 유지, Web 은 별칭 없음) CoreMockupPhoneStyle 의 frameColor·screenBorderRadius·cameraBorderRadius·outerPadding·innerPadding·cameraSize·cameraPadding 이 제거됐다(frameColor → railColor, 나머지는 railWidth·bezelWidth·파생 radius·카메라 필드로 대체) — 화면에 inset 이 없어지고 기본 비율이 9:16 → 9:19.5 로 바뀌며 resolveMockupPhone/ResolvedMockupPhone 은 device 인자를 받는 resolveMockupDevice/ResolvedMockupDevice 가 됐다.
* **core:** `MockupBrowser.addressBar` 가 `String?`(기본 `'example.com'`, `null` = 데스크톱 앱 창)·`child` 가 선택으로 풀리고 `showControls`(기본 true)가 생기며, 창 몸체가 두께를 갖는 구조(몸체 `surfaceContainer` · 테두리 `outlineVariant` · 그림자 `xl` · 콘텐츠 카드 `surface`, 구분선 제거)로 바뀌어 기존 렌더가 달라진다. Web `MockupWindow` 는 삭제되고 Flutter/Core `MockupWindow` 는 `@Deprecated` — 대체는 `MockupBrowser(showControls: true, addressBar: null)` 이며 바 기하가 40→44 · 패딩 12→16 · 간격 8→12 · 컨트롤 12→8 로 바뀐다.
* **core:** 박스형 TextField 의 hover·focus 배경 워시가 사라져 상태를 테두리로만 표현하고, plain TextField 의 좌우 여백이 0 이 되며, errorText 가 있는 비활성 TextField·TextArea 는 에러 테두리·채움 대신 비활성 chrome 을 그린다(에러 메시지 스타일은 Theme error 행을 그대로 따른다).
* **core:** CoreFormFieldContract 에 size getter 가 추가돼 이 인터페이스를 직접 implements 한 코드는 컴파일이 깨지고, Fieldset(enabled: false) 가 이제 FormFieldScope 로 안의 FormField 와 TextField(및 TextField 를 합성한 입력)를 실제로 비활성으로 그린다 — 전에는 legend 만 흐려지고 자식은 활성이었다.

### 기능

* **core:** FormFieldScope — FormField·Fieldset 이 비활성·에러를 자식 입력에 전파, TextField 가 첫 consumer ([#4888](https://github.com/coco-de/coui/issues/4888)) ([5b46ed4](https://github.com/coco-de/coui/commit/5b46ed4a9fa05e76f3a01d21a5e88774a5f9c214))
* **core:** MockupBrowser 가 MockupWindow 를 흡수한다 — 두께 있는 창·앱 모드·showControls, MockupWindow 폐기 예고 ([#4894](https://github.com/coco-de/coui/issues/4894)) ([a439e41](https://github.com/coco-de/coui/commit/a439e41d24f344fa7259d1870f0bb256de6f78df))
* **core:** MockupPhone → MockupDevice — Device 축(phone·tablet), 동심 베젤 규칙, 테마 불변 하드웨어 색 ([#4895](https://github.com/coco-de/coui/issues/4895)) ([0fa452c](https://github.com/coco-de/coui/commit/0fa452c81f0937f5c90094bec943b3efc4a60c05))


### 버그 수정

* **core:** [#4856](https://github.com/coco-de/coui/issues/4856) — TextField/TextArea 상태 모델: 워시 → 테두리, disabled &gt; error ([#4889](https://github.com/coco-de/coui/issues/4889)) ([cc5312c](https://github.com/coco-de/coui/commit/cc5312c533879a972b222249a807eee827106b96))
* **core:** [#4856](https://github.com/coco-de/coui/issues/4856) A-2 — DatePicker 트리거의 error 값 색도 합성한 Button 이 소유한다 ([#4883](https://github.com/coco-de/coui/issues/4883)) ([c5b77eb](https://github.com/coco-de/coui/commit/c5b77ebd63c827024b2458b2bf861ae217e3f2a6))


### 문서

* **core:** 카메라 색 슬롯의 행방을 doc 에 적는다 — cameraColor 는 cutoutColor · lensColor 로 갔다 ([#4905](https://github.com/coco-de/coui/issues/4905)) ([248b6db](https://github.com/coco-de/coui/commit/248b6db097335f66c04700e9631b4013dae54583))

## [0.141.1](https://github.com/coco-de/coui/compare/coui_web-v0.141.0...coui_web-v0.141.1) (2026-09-14)


### 버그 수정

* **core:** [#4865](https://github.com/coco-de/coui/issues/4865) — 합성한 Button 이 비활성 트리거 값 색을 소유한다 ([#4878](https://github.com/coco-de/coui/issues/4878)) ([0b469e1](https://github.com/coco-de/coui/commit/0b469e166a00bb545e0117ff2b752361ad0f64ed))

## [0.141.0](https://github.com/coco-de/coui/compare/coui_web-v0.140.0...coui_web-v0.141.0) (2026-09-13)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** `ResolvedTextArea` 의 `labelTextStyle` 과 `requiredMarkColor` 가 `labelFormLabelStyle`(Flutter) 하나로, Web 의 `label` · `requiredMark` 가 `formLabelStyle` + `labelHost` 로 바뀐다. 위젯이 읽는 paint-ready artifact 라 공개 컴포넌트 API 는 그대로다. `CoreTextAreaStyle.defaultLabelStyle` 은 deprecated — 인스턴스별 역할은 계속 `labelStyle` 슬롯으로 간다.
* **core,flutter,web,figma:** 선택된 disabled Chip 이 채움색 1px 보더 대신 보더 없이 그려져 한 쪽당 1px 좁아지고, Chip `sm` 라벨 자간이 −0.12 에서 −0.06 으로 바뀐다. ChipInput 의 삭제 배지 라벨은 14px 로 유지된다(범위 밖). `CoreChipStyle.disabledSelectedBorderColor` 로 인스턴스별 재지정할 수 있다.
* **fieldset:** CoreFieldsetContract 에 size getter 가 추가됐다 — CoreFieldsetContract<W> 를 직접 구현하는 외부 클래스는 이 getter를 새로 구현해야 한다.
* **text-field:** ResolvedTextField.labelTextStyle(Flutter)이 labelFormLabelStyle로, Web ResolvedTextField.label이 formLabelStyle로 이름과 타입이 바뀌었다. CoreTextFieldStyle.defaultLabelStyle / defaultValueStyle / defaultPlaceholderStyle static const가 제거됐다.
* **form-label:** CoreFormLabelContract 에 size·enabled 두 필드가 추가돼 그 인터페이스를 implements 하는 코드는 두 게터를 구현해야 한다(양 플랫폼 FormLabel 자신은 이미 반영됨, 기본값 CoreComponentSize.md/true 라 기존 호출부는 변경 없이 그대로 동작).

### 기능

* **fieldset:** Size 축 + disabled legend 색 + fieldSpacing 24 로 정정 ([c5bcaf3](https://github.com/coco-de/coui/commit/c5bcaf3fc86e64868a0ec031cc7fdafa109da33a))
* **form-label:** FormLabel 이 Size 축 + disabled 톤을 받는다 ([fcd75d8](https://github.com/coco-de/coui/commit/fcd75d80855b3d4221605a501299f794b82ea10d))
* **form:** actions row — primaryAction/secondaryAction slots, independent of onSubmit ([67d0bdb](https://github.com/coco-de/coui/commit/67d0bdb833f2b3d6a95f16686f9618de886e7a77))
* **form:** 액션 행을 캔버스에 맞춘다 — showSecondaryAction · 로케일 라벨 · Figma 프로퍼티 표기 ([#4792](https://github.com/coco-de/coui/issues/4792)) ([66c9fc1](https://github.com/coco-de/coui/commit/66c9fc10de7fb30e610f8e3542a0629c662b3f1f))
* **mockup:** Core·Figma·Web·Flutter 정합 ([#4766](https://github.com/coco-de/coui/issues/4766)) ([#4776](https://github.com/coco-de/coui/issues/4776)) ([a6377ac](https://github.com/coco-de/coui/commit/a6377ac7c7070601f7879e11a92bc0ca5f289b27))
* **surface:** 리퀴드 글래스를 iOS 26 기준으로 — 카드도 유리, 윤곽 림, 렌즈 돔, 독의 액체 알약 ([#4781](https://github.com/coco-de/coui/issues/4781)) ([9b5b081](https://github.com/coco-de/coui/commit/9b5b08185d9a79e9cf7eb29350f3f96d767000b2))
* **text-field:** value/placeholder 타이포 사다리 도입 + label을 FormLabel에 완전 위임 ([2210c26](https://github.com/coco-de/coui/commit/2210c266c2e752308867c1bec24d99374b8ed264))


### 버그 수정

* **core,flutter,web,figma:** [#4858](https://github.com/coco-de/coui/issues/4858) — TextArea 라벨의 역할은 FormLabel 이 정한다 ([#4861](https://github.com/coco-de/coui/issues/4861)) ([04549e4](https://github.com/coco-de/coui/commit/04549e4cce88ae4f504356c5608f90611202e444))
* **core,flutter,web,figma:** 선택된 disabled Chip 의 보이지 않는 보더를 없애고, 라벨 사다리를 역할로 진술한다 ([#4849](https://github.com/coco-de/coui/issues/4849)) ([bf1d61a](https://github.com/coco-de/coui/commit/bf1d61a6ab7ab54d324f1c1c3caeafbfcc2a992c))
* **core:** [#4577](https://github.com/coco-de/coui/issues/4577) — CoreTabContract 를 CoreTabsContract 로 개명 ([#4834](https://github.com/coco-de/coui/issues/4834)) ([38b05e7](https://github.com/coco-de/coui/commit/38b05e73e6679e743fed7c78be017c367cbbebbd))
* **figma:** FormLabel/Fieldset/Form 배치의 Figma 빌더 후속 작업 미완 정리 ([9dd1f2f](https://github.com/coco-de/coui/commit/9dd1f2f59f54fe00f2208fba16450c1bdf78f5da))
* **select:** 캔버스 대조 — 트리거 행간 120%, 셰브론 전 rung 20, focus 포즈의 caret 숨김, 문구 "Select an option" ([#4753](https://github.com/coco-de/coui/issues/4753)) ([35b69ac](https://github.com/coco-de/coui/commit/35b69ac42a37b1ceb2e578351504000f6bd65913))
* **text-area:** 사이즈 사다리 6단 확장 + hover 보더 + disabled 배경 + description 사다리 정합 ([e371a93](https://github.com/coco-de/coui/commit/e371a93ead170d54249d8c889d8d609e77d896a6))
* **web:** 자간 오버레이가 em 비율을 rem 변환기에 넣던 잠복 버그를 고친다 ([f0cc540](https://github.com/coco-de/coui/commit/f0cc540efd3b21b0bfcd9f0cd6db661ece3bb269))

## [0.140.0](https://github.com/coco-de/coui/compare/coui_web-v0.139.0...coui_web-v0.140.0) (2026-09-09)


### ⚠ BREAKING CHANGES

* **select:** `CoreButtonVariantStyle.radius` 가 `double?` 이 되어(null = 사이즈 래더) 이를 double 로 읽던 코드는 `CoreButtonStyle.borderRadiusFor` 를 거쳐야 하고, primary/secondary 의 hover/pressed 는 워시가 아니라 `primaryHover`/`primaryPressed` 등 새 ColorScheme 슬롯으로 그려지며(사용자 ColorScheme 은 `fromMap` 기본값으로 채워진다), lg/xl/xl2 의 가로 패딩과 sm/xl 의 gap, lg 이상 반경이 사이즈 래더 값으로 바뀌고, `link`/`plain` 의 inline padding 이 0 이 되며, `card` 는 deprecated 다.
* **radius:** Button 의 lg/xl/xl2 radius 가 12/12/16 → 8 로, Fieldset 이 16 → 24 로 바뀐다. CoreRadius.radius18 이 사라진다(미출시 #4729 의 도입분).
* **checkbox:** Checkbox(state:) 가 checked: bool? 로, onChanged 가 ValueChanged<bool?> 로 바뀌고 variant 파라미터가 사라진다. 미체크 보더 outline-variant · 라벨 400/160% · 마크 두께 1.5 · disabled 토큰으로 렌더가 달라진다.
* **toggle:** Toggle 의 xs 사이즈가 사라지고(sm 으로 clamp), 미선택 thumb 이 surface 로, 라벨이 500/120% → 400/160% 로, thumb inset 이 3 → 2 로 바뀌어 렌더가 달라진다. CoreToggleVariantStyle 생성자의 disabledTrack 이 disabledActiveTrack/disabledInactiveTrack 으로 갈린다.
* **radio_group:** RadioGroup 의 미선택 링이 outline → outlineVariant 로, 라벨이 500/120% → 400/160% 로, disabled 색이 disabled 토큰 계열로 바뀌어 렌더가 달라진다. Figma 세트의 Variant/Enabled/Focused 축은 State/Show focus ring 으로 대체된다(renames 로 재조준).
* **menu:** `CoreButtonVariantStyle.radius` 가 `double?` 이 되어(null = 사이즈 래더) 이를 double 로 읽던 코드는 `CoreButtonStyle.borderRadiusFor` 를 거쳐야 하고, primary/secondary 의 hover/pressed 는 워시가 아니라 `primaryHover`/`primaryPressed` 등 새 ColorScheme 슬롯으로 그려지며(사용자 ColorScheme 은 `fromMap` 기본값으로 채워진다), lg/xl/xl2 의 가로 패딩과 sm/xl 의 gap, lg 이상 반경이 사이즈 래더 값으로 바뀌고, `link`/`plain` 의 inline padding 이 0 이 되며, `card` 는 deprecated 다.
* **button:** `CoreButtonVariantStyle.radius` 가 `double?` 이 되어(null = 사이즈 래더) 이를 double 로 읽던 코드는 `CoreButtonStyle.borderRadiusFor` 를 거쳐야 하고, primary/secondary 의 hover/pressed 는 워시가 아니라 `primaryHover`/`primaryPressed` 등 새 ColorScheme 슬롯으로 그려지며(사용자 ColorScheme 은 `fromMap` 기본값으로 채워진다), lg/xl/xl2 의 가로 패딩과 sm/xl 의 gap, lg 이상 반경이 사이즈 래더 값으로 바뀌고, `link`/`plain` 의 inline padding 이 0 이 되며, `card` 는 deprecated 다.
* **core,flutter,web:** `ThemeController.variant` 가 사라지고 `size`(`CoreThemeControllerSize`) · `enabled` 가 생긴다 — `CoreThemeControllerVariant` 와 `CoreThemeControllerVariantStyle` 삭제, `CoreThemeControllerTheme.variantStyles` 삭제, `CoreThemeControllerStyle.defaultLabelStyle` 이 색을 잃고 `defaultLabelColor` 로 갈라지며, 라벨·선택 배지가 새로 그려지고 disabled 가 opacity 대신 색 토큰으로 바뀌어 렌더가 달라진다.
* **core,flutter,web:** `Chip.size` 는 `CoreComponentSize` 가 아니라 `CoreChipSize`(sm·md·lg) 를 받는다 — `xs`·`xl`·`xl2` 는 사라지고, `CoreChipColorStyle` 생성자는 `lowUnselectedFg`·`disabledSelectedBg` 를 요구하며, 미선택 disabled 칩의 배경이 `surface` 로, disabled 라벨이 `disabled-content` 로, low 미선택 라벨이 chip 색으로 바뀌어 렌더가 달라진다.

### 기능

* ADE 테마를 위한 CoUI 적용 한계와 범용 갭 옵트인 ([#4741](https://github.com/coco-de/coui/issues/4741)) ([#4750](https://github.com/coco-de/coui/issues/4750)) ([3b9c751](https://github.com/coco-de/coui/commit/3b9c75117934967d9aec09ebb12a9fae47371f01))
* **button:** Button · Menu 개편 — 색 슬롯 5 · radius18 · 사이즈 래더 · 컨테이너 스왑 · 제너레이터 계약 ([#4729](https://github.com/coco-de/coui/issues/4729)) ([b615d49](https://github.com/coco-de/coui/commit/b615d49186ffd205bdf5570b10a38b14f24f7878))
* **checkbox:** Checkbox 리디자인 — Checked 값 축·State 축·마크 두께 1.5·halo·밴드+링을 캔버스 그대로 ([#4736](https://github.com/coco-de/coui/issues/4736)) ([e670978](https://github.com/coco-de/coui/commit/e6709781e9e93d681dba1dbb3a8c267158816b7d))
* **command:** Command 리디자인 계약 — Presentation·Size 축, 스코프 칩, 두 채널 활성 행 ([#4725](https://github.com/coco-de/coui/issues/4725)) ([b1c7b23](https://github.com/coco-de/coui/commit/b1c7b23769fe671ea25e9f744d39d6013ece9233))
* **core,flutter,web:** Chip 이 캔버스가 정한 192 를 그린다 — 사다리 셋, disabled 두 줄, low 미선택 라벨은 그 색 ([b4f7216](https://github.com/coco-de/coui/commit/b4f72162ac4844e31f66d4105f12b1716e738950))
* **core,flutter,web:** ThemeController 가 테마를 보여준다 — 사다리 셋 · 등분 팔레트 · 선택 배지 · 색으로 말하는 disabled ([7d1eb39](https://github.com/coco-de/coui/commit/7d1eb39774af9fa9442f3c96ab9c8e1aed4c4fda))
* **menu:** Button · Menu 개편 §6·§8 — MenuItem 계약·위젯·빌더, Menu 가 행을 합성한다 ([#4733](https://github.com/coco-de/coui/issues/4733)) ([e2f8f64](https://github.com/coco-de/coui/commit/e2f8f6427fab9ae798e57d2dc558ac0cc56c6485))
* **radio_group:** RadioGroup 리디자인 — State 축·halo·밴드+링·라벨 사다리를 캔버스 그대로 ([#4734](https://github.com/coco-de/coui/issues/4734)) ([43ec7fe](https://github.com/coco-de/coui/commit/43ec7fe9d2e4f4bc0ce2aa013619469bd82e84f0))
* **radius:** Radius 정본 — 모든 컨트롤 8 고정, Button 사이즈 사다리 제거, radius18 삭제 ([#4737](https://github.com/coco-de/coui/issues/4737)) ([60a5fa5](https://github.com/coco-de/coui/commit/60a5fa5092f9002c73af2a919d7dbb1263b3edd0))
* **select:** Select 리디자인 — TextField 트리거·MenuItem 옵션·워시는 pressed 만, 캔버스 그대로 (09-09 개정) ([#4739](https://github.com/coco-de/coui/issues/4739)) ([c90a135](https://github.com/coco-de/coui/commit/c90a135e32ec18e7eb25e57421812448d97ba9ee))
* **toggle:** Toggle 리디자인 — xs 삭제, thumb=trackH−4, surface thumb, 트랙 상태 레이어·밴드+링을 캔버스 그대로 ([#4735](https://github.com/coco-de/coui/issues/4735)) ([d225196](https://github.com/coco-de/coui/commit/d22519689b5c26827a2a4712c77812e58bc2e1c9))


### 버그 수정

* **guards:** [#4731](https://github.com/coco-de/coui/issues/4731) — ThemeController 의 Icon·Stacks 간선을 이름과 사유로 적는다 ([350dbac](https://github.com/coco-de/coui/commit/350dbaccb9b0dc6a71d889ef2db8ed4bf9a1c92f))

## [0.139.0](https://github.com/coco-de/coui/compare/coui_web-v0.138.0...coui_web-v0.139.0) (2026-09-08)


### ⚠ BREAKING CHANGES

* **core,flutter,web:** `CoreFabSize.mini` 의 지름이 40 에서 48 로 커진다. 이름은 그대로이므로 컴파일은 깨지지 않지만 mini FAB 을 쓰는 화면의 레이아웃이 8px 만큼 달라진다. 메뉴 행 높이도 40 에서 48 로 커진다.

### 기능

* **core,flutter,web:** FAB 이 디자이너가 그린 것을 그린다 — mini 는 48 이 되고, 라벨을 가진 Extended 가 생긴다 ([d0f26ca](https://github.com/coco-de/coui/commit/d0f26ca217b9733a303b678154ccfd4f2b36723a))
* **core:** `CoreLayout` — 패널·오버레이의 상한/하한을 담는 세 번째 치수 네임스페이스 ([#4721](https://github.com/coco-de/coui/issues/4721)) ([22b36d2](https://github.com/coco-de/coui/commit/22b36d24eea34265636c197190e0e58ebde8aea6))

## [0.138.0](https://github.com/coco-de/coui/compare/coui_web-v0.137.0...coui_web-v0.138.0) (2026-09-07)


### 기능

* **core,flutter,web,figma:** 탭이 라벨 앞뒤로 무언가를 걸 수 있다 — 에디터 스트립의 파일 글리프와 닫기 ([#4691](https://github.com/coco-de/coui/issues/4691)) ([#4706](https://github.com/coco-de/coui/issues/4706)) ([89ee36b](https://github.com/coco-de/coui/commit/89ee36b4dcd6ce72f0718e42372c301fb021ff33))

## [0.137.0](https://github.com/coco-de/coui/compare/coui_web-v0.136.0...coui_web-v0.137.0) (2026-09-07)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** 비활성 탭 라벨이 `onSurfaceVariant` 로 흐려진다 — 지금까지는 ambient 텍스트 색(보통 `onSurface`)을 상속해 활성 탭과 같은 색이었다. 이전 그림이 필요하면 `tabPaneStyle: CoreTabPaneStyle(inactiveContentColor: CoreColor.token(CoreColors.onSurface))` 로 되돌린다. API 는 그대로다.

### 기능

* **core,flutter,web,figma:** TabPane 스트립이 자기 배경을 갖는다 ([#4687](https://github.com/coco-de/coui/issues/4687)) ([#4703](https://github.com/coco-de/coui/issues/4703)) ([f1f3c1b](https://github.com/coco-de/coui/commit/f1f3c1bc909b870a49753591422c13dd9be2cffa))
* **core,flutter,web,figma:** TabPane 이 활성/비활성 탭 라벨을 색으로 구분한다 ([#4688](https://github.com/coco-de/coui/issues/4688)) ([#4704](https://github.com/coco-de/coui/issues/4704)) ([c4a8a46](https://github.com/coco-de/coui/commit/c4a8a46420e7595a57d19d7ba554cf6502f1b495))
* **core,flutter,web,figma:** TabPane 탭 사이에 구분선을 그릴 수 있다 ([#4690](https://github.com/coco-de/coui/issues/4690)) ([#4705](https://github.com/coco-de/coui/issues/4705)) ([20d087b](https://github.com/coco-de/coui/commit/20d087bb7fe712ada0f2b42606b704e281b3f5b6))


### 버그 수정

* **core,flutter,web,figma:** TabPane 의 탭 테두리와 패널 테두리를 두 필드로 나눈다 ([#4686](https://github.com/coco-de/coui/issues/4686)) ([#4693](https://github.com/coco-de/coui/issues/4693)) ([2b5740b](https://github.com/coco-de/coui/commit/2b5740beba648008cdffe503260fa422051a8cd1))
* **flutter:** AppBar 단일 행이 제목의 자기 inset 을 그린다 — Web 과 8px 어긋나던 것 ([#4698](https://github.com/coco-de/coui/issues/4698)) ([76b7f1f](https://github.com/coco-de/coui/commit/76b7f1fe80aa723f59e6d96441cf85932e6939e2)), closes [#4692](https://github.com/coco-de/coui/issues/4692)

## [0.136.0](https://github.com/coco-de/coui/compare/coui_web-v0.135.0...coui_web-v0.136.0) (2026-09-07)


### ⚠ BREAKING CHANGES

* **core,flutter,web:** `CoreNavigationBarStyle.sectionLabelRole` 과 `defaultSectionLabelTextStyle` 의 타이포 역할이 `labelSmall`(10px)에서 `labelLarge`(14px)로 바뀌어 rail·sidebar 의 섹션 머리말이 커진다. 이전 크기가 필요하면 `navigationBarStyle: CoreNavigationBarStyle(sectionLabelTextStyle: CoreTextStyle.token(CoreTextStyles.labelSmall))` 로 인스턴스에서 되돌린다.
* **core,flutter,web,figma:** `CoreFooterStyle.defaultBackgroundColor` 가 `surfaceContainer` 에서 `surface` 로 바뀌어 기본 Footer 의 배경 톤이 페이지 배경과 같아진다 — 이전 톤이 필요하면 `footerStyle: CoreFooterStyle(backgroundColor: CoreColor.token(CoreColors.surfaceContainer))` 를 명시한다. 생성자 파라미터는 전부 기본값이 있어 기존 호출은 그대로 컴파일된다.

### 기능

* **core,flutter,web,figma:** Footer 가 디자이너의 두 축을 갖고 legal 블록을 얻는다 ([#4671](https://github.com/coco-de/coui/issues/4671)) ([81031c9](https://github.com/coco-de/coui/commit/81031c93ab857a854b197a513314edf612a4d7c7))


### 버그 수정

* **core,flutter,web:** 내비게이션 섹션 머리말이 디자이너가 고른 역할을 쓴다 ([#4682](https://github.com/coco-de/coui/issues/4682)) ([23e137c](https://github.com/coco-de/coui/commit/23e137cc65e4ed74fb34acbe12e54ef67813e42c))

## [0.135.0](https://github.com/coco-de/coui/compare/coui_web-v0.134.0...coui_web-v0.135.0) (2026-09-05)


### ⚠ BREAKING CHANGES

* **flutter,web,figma:** `TabPane` 의 기본 렌더가 바뀐다 — 포커스 탭의 아래 테두리가 사라지고, 탭 스트립이 `borderRadius` 의 위 모서리 반경(`barHeight` 상한)만큼 양쪽에서 들여지며, 스트립이 패널 윗선 위로 `borderWidth` 만큼 겹친다. API 와 `CoreTabPaneStyle` 필드는 그대로다. 이전처럼 스트립을 왼쪽 끝에 붙이려면 `tabPaneStyle: CoreTabPaneStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius0))` 로 반경을 0 으로 두면 inset 도 0 이 된다.

### 버그 수정

* **flutter,web,figma:** TabPane 탭이 패널과 한 외곽선을 공유한다 ([#4665](https://github.com/coco-de/coui/issues/4665)) ([ca26821](https://github.com/coco-de/coui/commit/ca2682195a38811511ab9a05626dc6c9bae86ffd))

## [0.134.0](https://github.com/coco-de/coui/compare/coui_web-v0.133.0...coui_web-v0.134.0) (2026-09-03)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** `Carousel.indicatorPlacement` 가 사라지고 `variant` 가 그 자리를 받는다 — `indicatorPlacement: .below` 는 `variant: CoreCarouselVariant.banner` 로. `showNavigation` 이 `bool?` 이 되어 기본값이 variant 에서 파생되므로, `banner` 에서 좌우 버튼이 필요하면 `showNavigation: true` 를 명시한다. 배너 슬라이드를 `Card` 로 합성하던 코드는 `CarouselBanner` 로 바꾼다.
* **core,flutter,web,figma:** 세 가지 기본 렌더가 바뀐다. (1) `DotIndicator` 활성 점이 `primary` 대신 `onSurface` 이고 비활성 점 테두리가 사라진다(폭 0), (2) `Carousel` 좌우 버튼이 40 에서 32 로 줄고 `below` 배치의 점 간격이 0 이 된다, (3) `Banner` 의 `action:` 이 `Button` 이면 라벨이 변형 foreground 를 입는다. 이전 모습이 필요하면 각각 `dotIndicatorStyle: CoreDotIndicatorStyle(activeColor: CoreColor.token(CoreColors.primary), inactiveBorderWidth: CoreStrokeWidth.stroke2, inactiveColor: CoreColor.transparent)`, `carouselStyle: CoreCarouselStyle(navInset: …, indicatorBelowGapStyle: CoreGapStyle(size: CoreSpace.space8))`, `action: Button(buttonStyle: CoreButtonStyle(foregroundColor: …))`.
* **core,flutter,web,figma:** `DotIndicator` 의 비활성 점이 투명이 아니라 `outlineVariant` 로 채워진다 — `inactiveColor` 를 주지 않던 모든 사용처의 렌더가 바뀐다. 이전 모습이 필요하면 `dotIndicatorStyle: CoreDotIndicatorStyle(inactiveColor: CoreColor.transparent)`.
* **core,flutter,web,figma:** DotIndicator 의 기본 점 크기가 12 → 8 이 된다(기본 크기 md). `CoreDotIndicatorStyle.defaultDotSize` · `defaultSpacing` 정적 필드는 `defaultsBySize` 표로 대체됐다 — 직접 참조하던 코드는 `defaultsBySize[CoreDotIndicatorSize.defaultSize]` 를 읽는다. 점 12 를 원하면 `size: .lg`.
* **core,flutter,web,figma:** `CoreFilterItem<T>` 가 `CoreFilterItem<T, W>` 가 된다 — 명시 제네릭으로 쓰던 코드는 `<T, Widget>` / `<T, Component>` 로 바꾼다(추론으로 만드는 호출은 그대로). `CoreFilterStyle.defaultItemPadding` 이 h16/v8 에서 8 사방으로, 세그먼트 높이가 32 고정으로, reset 이 plain·md 에서 ghost·sm·square 로 바뀌어 Filter 의 렌더가 달라진다.
* `CoreBadgeContract.child` 가 `W` 에서 `W?` 로 바뀌고 `CoreBadgeContract.form` getter 가 새로 생긴다. 이 계약을 직접 `implements` 하는 코드는 두 멤버를 갱신해야 한다. Flutter/Web `Badge` 위젯 사용처는 영향이 없다 — `child` 는 더 관대해진 방향이고 `form` 은 `CoreBadgeForm.count` 기본값을 갖는다.
* **core,flutter,web,figma:** AppBar 의 withStyle patch 타입이 CoreScaffoldStyle 에서 CoreAppBarStyle 로 바뀌고, ResolvedScaffold 에서 headerPadding/headerSpacing/ headerActionSpacing 이 빠진다(소비 위젯 0). scaffoldStyle 파라미터는 deprecated 매핑으로 동작을 유지한다.
* **core:** 
* **core:** 플레이스홀더가 자기 색 슬롯을 갖는다 ([#4477](https://github.com/coco-de/coui/issues/4477))
* **deps:** #4439 — Flutter 3.47.0 · jaspr 0.23.4 로 툴체인 상향 ([#4440](https://github.com/coco-de/coui/issues/4440))
* **core:** ResolvedColorScheme 생성자에 primaryText· primaryTextLarge 필수 파라미터가 추가된다. CoreColorScheme 를 직접 구현/생성하는 소비자는 두 슬롯을 채워야 한다.
* **surface:** #4217 — 유리 오버레이가 자기 트리거에서 자라난다 ([#4302](https://github.com/coco-de/coui/issues/4302))
* **surface:** Text 체인의 accent fill getter 6종이 Web 에서 제거되고 Flutter 에서 deprecated 됐다. `.on{Role}Container` 로 교체한다.
* **core,flutter,web:** #4082 — #4001 후속 4건 (resizable 정규화 · focus-ring 슬롯/합성 3건) ([#4121](https://github.com/coco-de/coui/issues/4121))
* **flutter,web:** #3979 — a11y 감사 후속 5건 (Scrollbar 접근성 노드·값 축·플랫폼 대칭 + TimePicker 링) ([#3999](https://github.com/coco-de/coui/issues/3999))

### 기능

* **a11y:** [#3391](https://github.com/coco-de/coui/issues/3391) — nav 패밀리 role seat + Flutter expanded 배선 ([#3424](https://github.com/coco-de/coui/issues/3424)) ([c81ef74](https://github.com/coco-de/coui/commit/c81ef74cef84ab48cb75460a851d11f279e18de0))
* **a11y:** [#3426](https://github.com/coco-de/coui/issues/3426) — EmptyState 에 톤 축 (실패인 빈 상태 vs 그냥 빈 상태) ([#3431](https://github.com/coco-de/coui/issues/3431)) ([915fbb2](https://github.com/coco-de/coui/commit/915fbb2cc2a2145934a260496662e6019bbb14c7))
* **a11y:** 포인터 타겟 하한 — 그리는 크기가 아니라 닿는 범위를 넓힌다 ([#3410](https://github.com/coco-de/coui/issues/3410)) ([def5370](https://github.com/coco-de/coui/commit/def5370fd4753d95e5169a32ab47819cbb818c60))
* **autocomplete:** [#4189](https://github.com/coco-de/coui/issues/4189) — 키보드로 제안에 도달할 수 있게 한다 ([#4225](https://github.com/coco-de/coui/issues/4225)) ([188ac60](https://github.com/coco-de/coui/commit/188ac60d56c18139b796f3aaf63158f403f1bda3))
* Badge 가 점을 그릴 수 있게 된다 — 캔버스의 Style 축을 흡수 ([#4606](https://github.com/coco-de/coui/issues/4606)) ([e454861](https://github.com/coco-de/coui/commit/e4548610f49ef6f7b41cdb6c591fab5a9eb3e5d8))
* **core,flutter,web,docs:** [#4413](https://github.com/coco-de/coui/issues/4413) — 브라우저가 여는 Disclosure ([#4415](https://github.com/coco-de/coui/issues/4415)) ([e5ded92](https://github.com/coco-de/coui/commit/e5ded921fb3e6924d6fa1b1e4c4f0c09a4bfa9d0))
* **core,flutter,web,figma:** [#4544](https://github.com/coco-de/coui/issues/4544) — ValidatorHint 에 neutral 을 더한다 ([#4545](https://github.com/coco-de/coui/issues/4545)) ([9a41de0](https://github.com/coco-de/coui/commit/9a41de07e69bdb99d5d69094c651db4d0c865518))
* **core,flutter,web,figma:** AppBar 가 디자이너 세트를 스펙으로 얻는다 — 계약 신설 · 양 플랫폼 이동 · 빌더 등록 ([7c154ba](https://github.com/coco-de/coui/commit/7c154ba1f85c8b74747ad2c7398112c4d8dc0e44))
* **core,flutter,web,figma:** Carousel 이 디자이너의 두 축을 갖고, 배너 슬라이드가 CarouselBanner 로 독립한다 ([#4654](https://github.com/coco-de/coui/issues/4654)) ([964043b](https://github.com/coco-de/coui/commit/964043b73658dcfd1a44fa2659612e3b0e8012d8))
* **core,flutter,web,figma:** Carousel 이 인디케이터 위치 축을 갖는다 — 디자이너의 배너 세트를 합성으로 흡수한다 ([#4647](https://github.com/coco-de/coui/issues/4647)) ([be17989](https://github.com/coco-de/coui/commit/be1798996c11ae5848016e2999039430b8adf9c1))
* **core,flutter,web,figma:** DotIndicator 가 크기 축을 갖는다 — 디자이너의 sm·md·lg 세트를 코드가 뒷받침하고 빌더가 그대로 그린다 ([#4646](https://github.com/coco-de/coui/issues/4646)) ([c5ecf34](https://github.com/coco-de/coui/commit/c5ecf347292be5b74f63b23ed4fdbd020ce5fd38))
* **core,flutter,web,figma:** DotIndicator 비활성 점이 속을 채운다 — Carousel 좌우 버튼은 Button 의 circle 멤버를 합성한다 ([#4650](https://github.com/coco-de/coui/issues/4650)) ([4374e24](https://github.com/coco-de/coui/commit/4374e2457dc8dd9623b0acf67d4f0caffa11edc2))
* **core,flutter,web,figma:** Filter 세그먼트가 아이콘을 갖고 정사각으로 접힌다 — 디자이너의 세그먼트 프로퍼티를 흡수한다 ([#4628](https://github.com/coco-de/coui/issues/4628)) ([bc544e4](https://github.com/coco-de/coui/commit/bc544e431e99add953277472193e60cd90a5a3af))
* **core,flutter,web,figma:** FormField 에 labelAction · counterText 를 더한다 ([#4548](https://github.com/coco-de/coui/issues/4548)) ([be90fce](https://github.com/coco-de/coui/commit/be90fce189afb1772a1a25ba09c8c21e26e41c22))
* **core,flutter,web,figma:** NavigationBar 디자이너 편집 + NavigationBarItem 반영 ([#4444](https://github.com/coco-de/coui/issues/4444)) ([41483ae](https://github.com/coco-de/coui/commit/41483ae5eb0ff5f9cda1f8c34eaab15ba5e7c1c2))
* **core,flutter,web,figma:** Size 3계층 토큰 시스템 + Figma 7컬렉션 라이브 파일 완전 정렬 ([#4214](https://github.com/coco-de/coui/issues/4214)) ([d911b53](https://github.com/coco-de/coui/commit/d911b53524945ddb3386187a8fd60176efdd1f0a))
* **core,flutter,web,figma:** 디자이너가 캔버스에서 되돌린 값들을 코드로 옮긴다 — 점 색·테두리, nav 32, 배너 액션 라벨, 인프라 자리표시 ([#4652](https://github.com/coco-de/coui/issues/4652)) ([40ea8c8](https://github.com/coco-de/coui/commit/40ea8c8b38f78602eef18e2a96c2ec25ef8d9b48))
* **core,flutter,web:** [#3763](https://github.com/coco-de/coui/issues/3763) — Core↔docs 정합 잔여 트랙 완료 (Epic K 치수표 확정 + Track B 정리) ([#3916](https://github.com/coco-de/coui/issues/3916)) ([00070c9](https://github.com/coco-de/coui/commit/00070c9c45ae22064fadbac4b4df2ac59228bc65))
* **core,flutter,web:** [#4218](https://github.com/coco-de/coui/issues/4218) — 채도와 엣지 시인이 양 플랫폼 픽셀에 도달한다 ([#4230](https://github.com/coco-de/coui/issues/4230)) ([0266bc2](https://github.com/coco-de/coui/commit/0266bc219a86ee0035bafedf94d9be90209b3bf6))
* **core,flutter,web:** [#4351](https://github.com/coco-de/coui/issues/4351) — 마커가 자기 역할을 나른다 ([#4376](https://github.com/coco-de/coui/issues/4376)) ([e2670a9](https://github.com/coco-de/coui/commit/e2670a97b8440e002e2a8c2fb63923414a0698f3))
* **core,flutter,web:** [#4352](https://github.com/coco-de/coui/issues/4352) — 중첩 정책을 축으로 올려 두 플랫폼을 맞춘다 ([#4377](https://github.com/coco-de/coui/issues/4377)) ([a872768](https://github.com/coco-de/coui/commit/a872768f983372980bab5225cd942fc7eac271e3))
* **core,flutter,web:** Chip 에 emphasis 축을 추가한다 — 조용한 레지스터 ([#4488](https://github.com/coco-de/coui/issues/4488)) ([e55dbf4](https://github.com/coco-de/coui/commit/e55dbf43a6946d8b2fefa4fe8d81ad9a6506caf5))
* **core:** [#2870](https://github.com/coco-de/coui/issues/2870) — 표면 하이라이트 팔레트 슬롯 + clay inset rim ([#3405](https://github.com/coco-de/coui/issues/3405)) ([8c00ec5](https://github.com/coco-de/coui/commit/8c00ec540ce2e01a98872fd0efaae7392213e6cd))
* **core:** [#3345](https://github.com/coco-de/coui/issues/3345) — 서피스 기하 재지정 (radius + stroke) ([#3354](https://github.com/coco-de/coui/issues/3354)) ([5613f56](https://github.com/coco-de/coui/commit/5613f5687c0e209b1503c0fd3659db309978cc05))
* **core:** [#3351](https://github.com/coco-de/coui/issues/3351) — 그림자 기하 재지정 + neo-brutalism 서명 그림자 ([#3358](https://github.com/coco-de/coui/issues/3358)) ([ed792fc](https://github.com/coco-de/coui/commit/ed792fc1085a0058d699956797a718b67c23679c))
* **core:** [#3352](https://github.com/coco-de/coui/issues/3352) — 프리셋 경계 색 재지정 (outlineEmphasis) ([#3355](https://github.com/coco-de/coui/issues/3355)) ([4108ee0](https://github.com/coco-de/coui/commit/4108ee0f3df7a633641ed187446f172779967c9d))
* **core:** [#3356](https://github.com/coco-de/coui/issues/3356) — 프리셋 typography weight 축 (neo-brutalism 레시피 완성) ([#3359](https://github.com/coco-de/coui/issues/3359)) ([0b98ac0](https://github.com/coco-de/coui/commit/0b98ac0038c01cd2214cd669877c9bc92b6fb7ad))
* **core:** [#4219](https://github.com/coco-de/coui/issues/4219) — 앱이 글래스 재질을 정한다 (CoreSurfaceTuning) ([#4254](https://github.com/coco-de/coui/issues/4254)) ([c20829f](https://github.com/coco-de/coui/commit/c20829fb5c9628a9d75a7c4352450c7cb2bc03d2))
* **core:** [#4402](https://github.com/coco-de/coui/issues/4402) — 캐스트가 engage 될 때 무엇을 할지 컨트롤이 말하게 한다 ([#4412](https://github.com/coco-de/coui/issues/4412)) ([e22b207](https://github.com/coco-de/coui/commit/e22b207e46bd293c53327e3758c15c9ab701de66))
* **core:** [#4509](https://github.com/coco-de/coui/issues/4509) — Chip 이 상태 레이어를 그린다 (hover · focus · pressed) ([#4522](https://github.com/coco-de/coui/issues/4522)) ([f7fe6e5](https://github.com/coco-de/coui/commit/f7fe6e598434fdd8d30da147313622a00da81ccb))
* **core:** [#4509](https://github.com/coco-de/coui/issues/4509) — NavigationBarItem 이 상태 레이어를 그린다, 그리고 다크의 구멍을 메운다 ([#4517](https://github.com/coco-de/coui/issues/4517)) ([8e29e56](https://github.com/coco-de/coui/commit/8e29e56846eaca5d19dc152056a3390eec5a6a70))
* **core:** [#4509](https://github.com/coco-de/coui/issues/4509) — TextField 가 상태 레이어를 그린다 (hover · focus · pressed) ([#4516](https://github.com/coco-de/coui/issues/4516)) ([f060cea](https://github.com/coco-de/coui/commit/f060cea10768ed3841e457bffcd4dce0b5a17a0f))
* **core:** [#4523](https://github.com/coco-de/coui/issues/4523) — Checkbox 라벨이 사이즈 축을 타고, description·trailing 슬롯이 생긴다 ([#4524](https://github.com/coco-de/coui/issues/4524)) ([8bfadf5](https://github.com/coco-de/coui/commit/8bfadf593939a8729234cc71547f2c3f3aae05e8))
* **core:** Banner emphasis 축 · Alert 재설계 · Button 상태 레이어와 포커스 링 ([#4505](https://github.com/coco-de/coui/issues/4505)) ([636cda0](https://github.com/coco-de/coui/commit/636cda075bebb9769127d9a04f0565b62ea256cf))
* **core:** display 역할이 regular(400) 로 — light 는 대형 제목에서 획이 사라진다 ([#4617](https://github.com/coco-de/coui/issues/4617)) ([d35041b](https://github.com/coco-de/coui/commit/d35041b0f65e55c086d425abb536ecd71bccb634))
* **core:** label role 이 body 보다 무거워지고, 계열이 사다리 끝까지 이어진다 ([#4556](https://github.com/coco-de/coui/issues/4556)) ([3629255](https://github.com/coco-de/coui/commit/3629255985a679086c3a100741a3002bb082ded1))
* **core:** 눌림 chrome 축 — 이동과 그림자 ([#3399](https://github.com/coco-de/coui/issues/3399)) ([6821dd1](https://github.com/coco-de/coui/commit/6821dd1000b6a3b28a8b9f3079958aec4d1020a9))
* **core:** 브랜드가 시맨틱 매핑을 소유한다 — Figma 토큰 편집 역동기화 ([#4434](https://github.com/coco-de/coui/issues/4434)) ([96ba6e9](https://github.com/coco-de/coui/commit/96ba6e976d19765d3d09966daabaa4422c09cabb))
* **core:** 시맨틱 role seat — Core 가 들고 있던 raw ARIA 문자열 제거 ([#3403](https://github.com/coco-de/coui/issues/3403)) ([766360a](https://github.com/coco-de/coui/commit/766360a38dcc32b8163b8ec7cd3f57462d79777a))
* **core:** 플레이스홀더가 자기 색 슬롯을 갖는다 ([#4477](https://github.com/coco-de/coui/issues/4477)) ([a24b142](https://github.com/coco-de/coui/commit/a24b1423e276ab88a05ea010a908e1ed6a4b4b09))
* **coui:** DefinitionList · DisclosureBadge 신설 ([#4260](https://github.com/coco-de/coui/issues/4260)) ([ae07784](https://github.com/coco-de/coui/commit/ae07784601d55b23b6de805b3744a0a080001719))
* **cross-platform:** [#4186](https://github.com/coco-de/coui/issues/4186) — 잔여 3건 (divider childAlignment · 피드백 전역 opt-out · Web 버튼 chrome 전환) ([#4257](https://github.com/coco-de/coui/issues/4257)) ([ed2b409](https://github.com/coco-de/coui/commit/ed2b409f58b92cdcca3c941497bf78aa436942c7)), closes [#4200](https://github.com/coco-de/coui/issues/4200) [#4201](https://github.com/coco-de/coui/issues/4201) [#4202](https://github.com/coco-de/coui/issues/4202)
* **figma:** 브랜드 축 — 브랜드별 Semantic/Color 컬렉션 + 리바인딩 플러그인 커맨드 ([#4290](https://github.com/coco-de/coui/issues/4290)) ([ff0d254](https://github.com/coco-de/coui/commit/ff0d2540cf92a8a06272367dfdec3e0577dc9a72))
* **flutter,web,figma:** TextField suffix 에 글자가 들어간다 — 코드가 먼저 타이포를 말하고, 캔버스가 슬롯을 얻는다 ([#4611](https://github.com/coco-de/coui/issues/4611)) ([d636914](https://github.com/coco-de/coui/commit/d6369146e4a8371df5987b5ab2b87a3c81ceda19))
* FormattedInput 단일 필드 마스크 재설계 — 백스페이스 연속성 · 커스텀 마스크 · 자동완성 ([#3866](https://github.com/coco-de/coui/issues/3866)) ([#3900](https://github.com/coco-de/coui/issues/3900)) ([68e8513](https://github.com/coco-de/coui/commit/68e8513867da78c58b3421791e32b759e651cb39))
* **i18n:** [#3429](https://github.com/coco-de/coui/issues/3429) — 논리 방향 inset (가로 비대칭 4건 전부) ([#3438](https://github.com/coco-de/coui/issues/3438)) ([ee951e4](https://github.com/coco-de/coui/commit/ee951e419b99d5356ebc3882c866155f8c7dd205))
* **icon:** 아이콘 크기 사다리 — 실제 결함은 네임스페이스 반전이었다 ([#3420](https://github.com/coco-de/coui/issues/3420)) ([625baa4](https://github.com/coco-de/coui/commit/625baa49cca467a0cfeec898285f8f4dd1a5cdee))
* **icon:** 출하 컴포넌트를 Lucide 하나로 — 그리고 글리프 정체에 걸린 동작 분리 ([#3419](https://github.com/coco-de/coui/issues/3419)) ([63d7df1](https://github.com/coco-de/coui/commit/63d7df13a73780df19fcb52670649ff02f874149))
* neo-brutalism 대각선 그림자·press-squash(Button/Fab) + card_image OutlinedContainer 합성 ([#4178](https://github.com/coco-de/coui/issues/4178)) ([78d74e6](https://github.com/coco-de/coui/commit/78d74e6e610babf82c78719b16b227db01dc8de9))
* **phone_input:** 전화번호 완전성 validator — Form 이 "완전한 번호" 를 말할 수단 ([#4243](https://github.com/coco-de/coui/issues/4243)) ([a36fe90](https://github.com/coco-de/coui/commit/a36fe90f6f8970b68f4edc92e6f1e1683c744fb9))
* Project [#3294](https://github.com/coco-de/coui/issues/3294) — 디자인 시스템 견고화 (접근성 축 10건 + 서피스 프리셋 축 4건) ([#3349](https://github.com/coco-de/coui/issues/3349)) ([5b6287d](https://github.com/coco-de/coui/commit/5b6287d1c48b73eb208b3838bd94effb9d9b1711))
* **state:** [#3318](https://github.com/coco-de/coui/issues/3318) — 로딩 슬롯 판정: 필요한 컴포넌트가 없다 ([#3439](https://github.com/coco-de/coui/issues/3439)) ([3ec5ec7](https://github.com/coco-de/coui/commit/3ec5ec7425d2ac1c8501b15e5afbd39342d07d99))
* **surface:** [#4208](https://github.com/coco-de/coui/issues/4208) — 앱이 서페이스 프리셋을 자기 값으로 튜닝한다 ([#4240](https://github.com/coco-de/coui/issues/4240)) ([44093f7](https://github.com/coco-de/coui/commit/44093f75698976755992e85af17e642260ce4794))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 두 플랫폼이 같은 실루엣을 각자 스펠링한다 ([#4299](https://github.com/coco-de/coui/issues/4299)) ([e137e70](https://github.com/coco-de/coui/commit/e137e709c81e181d1f3af03a6b61a94058e5f8e8))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 모프 클립을 양 플랫폼에 세운다 ([#4300](https://github.com/coco-de/coui/issues/4300)) ([9c39a2b](https://github.com/coco-de/coui/commit/9c39a2b65b63b6e6d00b5283fe656366685c4d61))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 유리 오버레이가 자기 트리거에서 자라난다 ([#4302](https://github.com/coco-de/coui/issues/4302)) ([57e1e0f](https://github.com/coco-de/coui/commit/57e1e0f3c25194608fa541c597e329f0684674a4))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 유리 표면의 경계는 재질이 그린다 ([#4284](https://github.com/coco-de/coui/issues/4284)) ([9edf08e](https://github.com/coco-de/coui/commit/9edf08e93243224043b6a8153edfe8196d45e2b9))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 유리가 유리처럼 보일 만큼 재질을 올린다 ([#4306](https://github.com/coco-de/coui/issues/4306)) ([fa604e5](https://github.com/coco-de/coui/commit/fa604e567b29779c6f7bf9542c24fc774879c060))
* **surface:** [#4222](https://github.com/coco-de/coui/issues/4222) — 굴절은 축이 아니라 표면이 여는 역량이다 ([#4270](https://github.com/coco-de/coui/issues/4270)) ([f3bf226](https://github.com/coco-de/coui/commit/f3bf226879382ecb1e064dcffbc22cdd80488c48))
* **surface:** [#4323](https://github.com/coco-de/coui/issues/4323) — 어느 컴포넌트가 표면인지 목록이 아니라 규칙이 답한다 ([#4332](https://github.com/coco-de/coui/issues/4332)) ([729469c](https://github.com/coco-de/coui/commit/729469cf75bb7260fc00fd3205bac80a4a1b4fbd))
* **surface:** [#4325](https://github.com/coco-de/coui/issues/4325) — 떠 있는 패널 넷이 재질을 받는다 (flutter 8→12 · web 9→13) ([#4335](https://github.com/coco-de/coui/issues/4335)) ([ac46cf1](https://github.com/coco-de/coui/commit/ac46cf1a97211d313398044a20e00e39ae7870c2))
* **surface:** [#4326](https://github.com/coco-de/coui/issues/4326) — 컨테이너 크롬 둘이 재질을 받고, 다섯은 근거와 함께 받지 않는다 ([#4337](https://github.com/coco-de/coui/issues/4337)) ([96a286d](https://github.com/coco-de/coui/commit/96a286d94f1b1a7e05c37b8f956a57f84268049b))
* **surface:** [#4327](https://github.com/coco-de/coui/issues/4327) — 카탈로그 감사가 재질도 본다, 그리고 중첩 유리를 찾았다 ([#4338](https://github.com/coco-de/coui/issues/4338)) ([b2f3ebb](https://github.com/coco-de/coui/commit/b2f3ebb1150bafa064d1e119a33a5fd436906c7d))
* **surface:** [#4329](https://github.com/coco-de/coui/issues/4329) — 투명도 줄이기 폴백을 Flutter 에서도 켤 수 있게 한다 ([#4341](https://github.com/coco-de/coui/issues/4341)) ([5bff601](https://github.com/coco-de/coui/commit/5bff601e25cce6793ad51c724fc0e7681ecc1661))
* **surface:** [#4369](https://github.com/coco-de/coui/issues/4369) — 바닥값이 못 올리는 0 에, 스타일이 경계를 직접 기여한다 ([#4370](https://github.com/coco-de/coui/issues/4370)) ([ab9694b](https://github.com/coco-de/coui/commit/ab9694bd8512e646939b21435f4109a0752aed20))
* **theme:** [#2865](https://github.com/coco-de/coui/issues/2865) — Neo-brutalism 프리셋 (첫 E2E) + docs 스타일 스위처 ([#3357](https://github.com/coco-de/coui/issues/3357)) ([40d6999](https://github.com/coco-de/coui/commit/40d69999eac9210c1050a71e9394c7f30d7e31b6))
* **theme:** [#3183](https://github.com/coco-de/coui/issues/3183) — 내비 표면이 재질을 받고, 떠 있을 수 있다 ([#3436](https://github.com/coco-de/coui/issues/3436)) ([7ae43c4](https://github.com/coco-de/coui/commit/7ae43c42ba4ebdc5e0dc66011627ef29fb5b4e1d))
* **theme:** 그림자 미러 축 — 배율로는 두 번째 방향을 만들 수 없다 ([#3414](https://github.com/coco-de/coui/issues/3414)) ([8691726](https://github.com/coco-de/coui/commit/86917267025647d0d210208a87046e195f4f0874))
* **theme:** 남은 프리셋 3종 (Glass · Neumorphism · Claymorphism) + orphan surface 필드 배선 ([#3362](https://github.com/coco-de/coui/issues/3362)) ([536bafc](https://github.com/coco-de/coui/commit/536bafceb1be2faf85fdda7e8aae755e559e3e98))
* **theme:** 표면 스타일이 반경 범위를 진술 — 사다리 위 재배치 ([#3407](https://github.com/coco-de/coui/issues/3407)) ([9c39d49](https://github.com/coco-de/coui/commit/9c39d490fb70f613d034ff39423e725cdddaace3))
* **web,core:** [#4217](https://github.com/coco-de/coui/issues/4217) — 투명도 줄이기 요청에 유리가 답한다 (G5) ([#4305](https://github.com/coco-de/coui/issues/4305)) ([1f40f64](https://github.com/coco-de/coui/commit/1f40f6400f9ce3429281a90d4932b08175d1b15d))
* **web:** [#3318](https://github.com/coco-de/coui/issues/3318) 선행 — 스켈레톤 표준 확정 + 정직하지 않은 클래스 삭제 ([#3437](https://github.com/coco-de/coui/issues/3437)) ([ebb1f67](https://github.com/coco-de/coui/commit/ebb1f676f8f3ef3eafeaa739b57d8f1f1fa3c575))
* **web:** [#3434](https://github.com/coco-de/coui/issues/3434) — glass 표면 처리에 Web transport (프리셋이 실제로 유리가 된다) ([#3435](https://github.com/coco-de/coui/issues/3435)) ([b6f620a](https://github.com/coco-de/coui/commit/b6f620a461b39449cb8272fe3e6d5359c6e49471))
* **web:** [#3763](https://github.com/coco-de/coui/issues/3763) — Core↔docs 정합 트랙 A(Web transport 결함) 완료 ([#3845](https://github.com/coco-de/coui/issues/3845)) ([5e558b9](https://github.com/coco-de/coui/commit/5e558b94bc79e8fcffae810e892b45876c9600f5))
* **web:** 컴포넌트 그림자가 CSS 변수를 지나게 함 — 프리셋이 절반만 닿던 것 ([#3398](https://github.com/coco-de/coui/issues/3398)) ([00f7ece](https://github.com/coco-de/coui/commit/00f7ece8dfe48a68a50158def0442c0bdd504050))


### 버그 수정

* [#3843](https://github.com/coco-de/coui/issues/3843) [#3846](https://github.com/coco-de/coui/issues/3846) — Sortable 드래그 행 z-order + 핸들 아이콘 정렬 ([#3847](https://github.com/coco-de/coui/issues/3847)) ([7d68e39](https://github.com/coco-de/coui/commit/7d68e39b70e8b50c5fef3e85b8e5e7dba12aa770))
* **a11y:** [#3432](https://github.com/coco-de/coui/issues/3432) — 문서화가 드러낸 배선 결함 6건 ([#3442](https://github.com/coco-de/coui/issues/3442)) ([fb64ea1](https://github.com/coco-de/coui/commit/fb64ea1570bf5103c1079630cc1a69459f5fb3b4))
* **a11y:** [#4117](https://github.com/coco-de/coui/issues/4117) — 아이콘 전용 affordance 10곳에 접근 가능한 이름 부여 ([#4124](https://github.com/coco-de/coui/issues/4124)) ([c25d77d](https://github.com/coco-de/coui/commit/c25d77d92472f31414421b89b80c75ddf72dc3c1))
* **a11y:** [#4155](https://github.com/coco-de/coui/issues/4155) — Status live region 파리티 + 미번역 기본 라벨 제거 ([#4156](https://github.com/coco-de/coui/issues/4156)) ([4502688](https://github.com/coco-de/coui/commit/4502688e103bfba82360101d7aa82fdbf6fb5cc3))
* **a11y:** 링크·푸터 시맨틱 복구 + Chip·Avatar·Badge 전달 인자 + 정적 사이트 다크 모드 경로 ([#4271](https://github.com/coco-de/coui/issues/4271)) ([0a20bfc](https://github.com/coco-de/coui/commit/0a20bfcea18e16231b272f6267d01d46675e5c0f))
* **alert:** 박스를 직접 그리는 대신 OutlinedContainer 를 합성한다 ([#4249](https://github.com/coco-de/coui/issues/4249)) ([1466afc](https://github.com/coco-de/coui/commit/1466afc9aa718859ab86f8694560fa2f142e9d94))
* **autocomplete:** [#4187](https://github.com/coco-de/coui/issues/4187) — 패널을 텍스트 편집이 아니라 props 에 재조정 ([#4213](https://github.com/coco-de/coui/issues/4213)) ([cf5a6a1](https://github.com/coco-de/coui/commit/cf5a6a10434e26030355244c8cbd71455d41aa69))
* **autocomplete:** [#4188](https://github.com/coco-de/coui/issues/4188) — replaceWord 가 캐럿 위치의 단어를 완성한다 ([#4215](https://github.com/coco-de/coui/issues/4215)) ([cf69ea0](https://github.com/coco-de/coui/commit/cf69ea02ecf7ea66b0cc2d6de224b5c50303fe46))
* **badge:** 스타일의 캐스트를 받는다 + 변환을 한 함수로 모은다 ([#4252](https://github.com/coco-de/coui/issues/4252)) ([2857959](https://github.com/coco-de/coui/commit/2857959c642eaf43fb2f34ca41dbeceddd0ed851))
* **chip:** [#4289](https://github.com/coco-de/coui/issues/4289) · [#4294](https://github.com/coco-de/coui/issues/4294) 를 main 으로 다시 올린다 (스택 베이스로 머지돼 도달 못 함) ([#4298](https://github.com/coco-de/coui/issues/4298)) ([c3794d6](https://github.com/coco-de/coui/commit/c3794d6c2d08d1f54b436a0414ed7a487e5d22db)), closes [#4293](https://github.com/coco-de/coui/issues/4293)
* **command:** 헤더 안 Command 팔레트가 뷰포트 전체를 못 쓰던 문제 수정 ([#4378](https://github.com/coco-de/coui/issues/4378)) ([f67053c](https://github.com/coco-de/coui/commit/f67053cbc7aae57a760985df34fd51de6d97738f))
* **core,flutter,web,figma:** Toast 액션이 슬랩 위에서 읽힌다 — 2.1:1 과 1.0:1 을 고친다 ([#4610](https://github.com/coco-de/coui/issues/4610)) ([73b93fe](https://github.com/coco-de/coui/commit/73b93fe582a6966c2a5b48a7be00dc7bea2c6fff))
* **core,flutter,web:** [#3495](https://github.com/coco-de/coui/issues/3495) — 드래그-스크롤 뷰포트를 보조 기술·키보드에 노출 ([#3958](https://github.com/coco-de/coui/issues/3958)) ([cd1a0f7](https://github.com/coco-de/coui/commit/cd1a0f7e0c513349fcce5aec7cb2a684b40f6923))
* **core,flutter,web:** [#3502](https://github.com/coco-de/coui/issues/3502) B — warning fill 을 텍스트 색에서 분리 (WCAG 1.4.3) ([#3973](https://github.com/coco-de/coui/issues/3973)) ([3c4e8d2](https://github.com/coco-de/coui/commit/3c4e8d2206a7e065a4f99129443bfad5cd69a70a))
* **core,flutter,web:** [#4082](https://github.com/coco-de/coui/issues/4082) — [#4001](https://github.com/coco-de/coui/issues/4001) 후속 4건 (resizable 정규화 · focus-ring 슬롯/합성 3건) ([#4121](https://github.com/coco-de/coui/issues/4121)) ([edf91db](https://github.com/coco-de/coui/commit/edf91db8f06b411496f091d65387e90fdf6a3957))
* **core,flutter,web:** [#4126](https://github.com/coco-de/coui/issues/4126) — [#4082](https://github.com/coco-de/coui/issues/4082) 후속 3건 (circle 링 죽은 필드 · badge offset 색 · 슬롯 clobber) ([#4139](https://github.com/coco-de/coui/issues/4139)) ([c9d60b7](https://github.com/coco-de/coui/commit/c9d60b78942e32bc8980e8c2e40e87e772988d67))
* **core,flutter,web:** [#4405](https://github.com/coco-de/coui/issues/4405) — 참조 reverse 캐스트 모션을 양 플랫폼에 구현 ([#4432](https://github.com/coco-de/coui/issues/4432)) ([6bf6cf0](https://github.com/coco-de/coui/commit/6bf6cf0684cd12bf7910dcce31dda7cd9f8d4883))
* **core:** [#4237](https://github.com/coco-de/coui/issues/4237) — 두 엣지 run 이 양 모드에서 다 보인다 ([#4241](https://github.com/coco-de/coui/issues/4241)) ([9460b01](https://github.com/coco-de/coui/commit/9460b01ddfa1f1b3d4cc2c63178cf58aa7423a51))
* **core:** 비활성 라벨을 읽을 수 있게 한다 — disabled-content 는 그래픽 전용 ([#4489](https://github.com/coco-de/coui/issues/4489)) ([b9f19db](https://github.com/coco-de/coui/commit/b9f19db12c5ab9bb8f43ba80c9060dfcdbfc67c0))
* **docs:** Jaspr 0.23.2 최신화 + CI Flutter 3.44.8 상향 + "On this page" 앵커/스타일 수정 ([#3489](https://github.com/coco-de/coui/issues/3489)) ([87ca07b](https://github.com/coco-de/coui/commit/87ca07be932fb8eb09f63cbe0edd8efc26d0747d))
* **drawer:** backdropCornerRadius가 비대칭 override를 유실하던 문제 수정 ([#3262](https://github.com/coco-de/coui/issues/3262)) ([a329148](https://github.com/coco-de/coui/commit/a329148c5aa820216d6942e285c0610b19e1b231))
* **figma,core:** 라벨 행간 120% + Fab 를 메뉴로 + Toast/Chip/Toggle 캔버스 결함 정리 ([2aea28a](https://github.com/coco-de/coui/commit/2aea28a061eb5b7974eba8423731f789aead09dc))
* **flutter,web:** [#3771](https://github.com/coco-de/coui/issues/3771) — Form + Layout/Nav + Display + Overlay/Misc 25개 컴포넌트의 border/radius가 surface-style geometry 축을 안 탐 (Batch 1-5/5) ([#3828](https://github.com/coco-de/coui/issues/3828)) ([18f2df8](https://github.com/coco-de/coui/commit/18f2df82a359ff8fb9ebb9d52025b18a9119e1e2))
* **flutter,web:** [#3825](https://github.com/coco-de/coui/issues/3825) — Scaffold 중첩 시 main 랜드마크를 하나만 낸다 ([#4075](https://github.com/coco-de/coui/issues/4075)) ([571700f](https://github.com/coco-de/coui/commit/571700f7a2418fbee1efaea7a8b65c277e7d0440))
* **flutter,web:** [#3864](https://github.com/coco-de/coui/issues/3864) — 슬라이더 paint 와 input 을 inset 모델로 통일 ([#3865](https://github.com/coco-de/coui/issues/3865)) ([1c2d136](https://github.com/coco-de/coui/commit/1c2d136d19d9e52dbc4ea1125a75b3275d7b714f))
* **flutter,web:** [#3979](https://github.com/coco-de/coui/issues/3979) — a11y 감사 후속 5건 (Scrollbar 접근성 노드·값 축·플랫폼 대칭 + TimePicker 링) ([#3999](https://github.com/coco-de/coui/issues/3999)) ([5a017c9](https://github.com/coco-de/coui/commit/5a017c95449e6883eb287158ff8013023b285431))
* **flutter,web:** 라벨을 한 곳에서만 그린다 — FormField 경로 정상화 + Web TextField 의 FormLabel 합성 ([#4448](https://github.com/coco-de/coui/issues/4448)) ([009de4f](https://github.com/coco-de/coui/commit/009de4f50e9aee79b23074f5eab1f4fd1f9f700f))
* **flutter,web:** 캘린더 헤더가 담기지 못할 때를 말하게, 그리고 그 테스트가 매일 다른 것을 묻지 않게 ([12a0b6f](https://github.com/coco-de/coui/commit/12a0b6fead25284eec590fe62abbee3485163a06))
* **flutter:** [#3718](https://github.com/coco-de/coui/issues/3718) — Command/Kbd border 가 surface-style geometry(strokeFloor)를 안 탐 ([#3719](https://github.com/coco-de/coui/issues/3719)) ([ad5e7fc](https://github.com/coco-de/coui/commit/ad5e7fc5c0d89f877081e37acad67602780e9919))
* **flutter:** hover 채움 아래로 캐스트가 비치지 않는다 ([#4276](https://github.com/coco-de/coui/issues/4276)) ([ff06bc0](https://github.com/coco-de/coui/commit/ff06bc096b931ee6e5418d0fc5536544fbf71bbf))
* **form:** 가려진 필드가 스펠체크·자동수정·IME 학습에 도달하지 않는다 ([#3409](https://github.com/coco-de/coui/issues/3409)) ([51b8a11](https://github.com/coco-de/coui/commit/51b8a115aa6ce97d833acb3a5dd1038ee118e945)), closes [#3385](https://github.com/coco-de/coui/issues/3385)
* **form:** 폼 입력 계약 4건 — 선언만 되고 아무도 안 읽던 필드 배선 ([#4224](https://github.com/coco-de/coui/issues/4224)) ([cb09aa9](https://github.com/coco-de/coui/commit/cb09aa95213ff6598781f63c36b0243bd6342458))
* **layout:** Epic D 4건 — join 포커스 링 · table intrinsic · stepper 앵커 · resizable optionalDivider ([#4255](https://github.com/coco-de/coui/issues/4255)) ([f1ccc24](https://github.com/coco-de/coui/commit/f1ccc249d1487f3545092db7ba01519d1c69647e))
* **menubar:** [#4165](https://github.com/coco-de/coui/issues/4165) — 열린 상태에서 형제 트리거 호버 시 메뉴 전환 ([#4167](https://github.com/coco-de/coui/issues/4167)) ([5049ae7](https://github.com/coco-de/coui/commit/5049ae7ba385dc398f7bbac5c25cd472af791c8c))
* **navigation_menu:** [#4163](https://github.com/coco-de/coui/issues/4163) — 호버 애니메이션 Web/Flutter 파리티 (닫힘 디바운스 + 패널 전환 슬라이드) ([#4168](https://github.com/coco-de/coui/issues/4168)) ([22e257a](https://github.com/coco-de/coui/commit/22e257af8aaf1219646f8c4f58dba6884dcae1c8))
* **navigation_menu:** [#4175](https://github.com/coco-de/coui/issues/4175) — QA 후속 회귀 4건 ([#4177](https://github.com/coco-de/coui/issues/4177)) ([52449d4](https://github.com/coco-de/coui/commit/52449d49c0f95bea4ed5992d2acacef6ba417383))
* **nav:** 선택 상태가 색으로만 구분되던 것에 비-색 신호 추가 ([#3394](https://github.com/coco-de/coui/issues/3394)) ([127b239](https://github.com/coco-de/coui/commit/127b239ccad07b02b802c122a37671e1807b49a7))
* **overlay:** [#3699](https://github.com/coco-de/coui/issues/3699) — Tooltip tooltipChild 기본 가시성 + panelMaxWidth 슬롯 ([#3700](https://github.com/coco-de/coui/issues/3700)) ([f898acb](https://github.com/coco-de/coui/commit/f898acb27cddc8f1151bc6fdd43294dc9e918c99))
* **parity:** [#3644](https://github.com/coco-de/coui/issues/3644) — WebLifecycleProbe 퇴장 관측을 child rebuild로 교정 ([#3668](https://github.com/coco-de/coui/issues/3668)) ([0001685](https://github.com/coco-de/coui/commit/00016853c9321ee6a50c2707a5a3163f81dd945c))
* **parity:** 문서↔코드 · Flutter↔Web 드리프트 실측 수정 + 게이트 4종 ([#3440](https://github.com/coco-de/coui/issues/3440)) ([3953ef5](https://github.com/coco-de/coui/commit/3953ef58f8d3e60ae07a33db9fe2295077ab3992))
* **phone_input:** 입력값을 추측하지 않는다 — 타이핑된 다이얼 코드만 벗긴다 ([#4245](https://github.com/coco-de/coui/issues/4245)) ([8dde2aa](https://github.com/coco-de/coui/commit/8dde2aa7481d89ee009fb1c17ff6bfc47761f086))
* **resizable:** [#4265](https://github.com/coco-de/coui/issues/4265) — optionalDivider 가 드래그 중에도 드러나 있게 한다 ([#4267](https://github.com/coco-de/coui/issues/4267)) ([172b598](https://github.com/coco-de/coui/commit/172b59894261ce4f40f9f3cdfd5ac0de056621f0))
* **surface:** Avatar · MockupWindow · Command 이 스타일의 캐스트를 받는다 ([#4261](https://github.com/coco-de/coui/issues/4261)) ([8c50735](https://github.com/coco-de/coui/commit/8c5073564ec9c74a00c4cbcccd519d1770b385f7))
* **surface:** EmptyState · CodeSnippet · Table 이 스타일의 캐스트를 받는다 ([#4256](https://github.com/coco-de/coui/issues/4256)) ([88270b5](https://github.com/coco-de/coui/commit/88270b5829df4b9ce3874e1b44d30180f86ba18c))
* **surface:** Fieldset · Chip · Kbd 이 스타일의 캐스트를 받는다 ([#4253](https://github.com/coco-de/coui/issues/4253)) ([ee34305](https://github.com/coco-de/coui/commit/ee3430590223539ece7f7996133c36edfc31a306))
* **surface:** 스타일 캐스트가 양 플랫폼에 같게 도달한다 ([#4242](https://github.com/coco-de/coui/issues/4242)) ([b01584f](https://github.com/coco-de/coui/commit/b01584fba7938b050e8bf275a4f90f8e93ffc1ec))
* **surface:** 캐스트가 그리지 않은 박스에서 나오거나, 그린 박스에서 빠지던 5건 ([#4269](https://github.com/coco-de/coui/issues/4269)) ([8c92b6b](https://github.com/coco-de/coui/commit/8c92b6b89a075945301c61cd22bd3058305c7d24))
* **surface:** 폼 컨트롤 5종이 스타일의 캐스트를 받는다 ([#4263](https://github.com/coco-de/coui/issues/4263)) ([9231e42](https://github.com/coco-de/coui/commit/9231e42924fab0e4335506455c25bb38e8079550))
* **surface:** 프레임·바 6종이 스타일의 캐스트를 받는다 ([#4266](https://github.com/coco-de/coui/issues/4266)) ([4d24238](https://github.com/coco-de/coui/commit/4d2423863059ff3cb05a8d33635478eecf541d5f))
* **upstream:** shadcn_flutter 0.0.53 감사 확정 13건 이식 ([#4206](https://github.com/coco-de/coui/issues/4206)) ([b01519b](https://github.com/coco-de/coui/commit/b01519b2ba4fb18673d0cb359320f771bbb7934a))
* **web,docs:** command chain 순열의 색상 크래시·투명 배경 파리티를 고친다 ([#4446](https://github.com/coco-de/coui/issues/4446)) ([f7918b9](https://github.com/coco-de/coui/commit/f7918b9fd8987e1c46417d1df19232aa6ce4cb87))
* **web,flutter:** [#4407](https://github.com/coco-de/coui/issues/4407) — press 전환을 duration 변수 경유로, 상태는 유지 ([#4425](https://github.com/coco-de/coui/issues/4425)) ([af9fd27](https://github.com/coco-de/coui/commit/af9fd2735bba596b936dbb227f6c82b3d73856c2))
* **web:** [#3264](https://github.com/coco-de/coui/issues/3264) — Phase 6 inline px 3건을 design-token 마커로 정당화 ([#3275](https://github.com/coco-de/coui/issues/3275)) ([170ba03](https://github.com/coco-de/coui/commit/170ba035ca2e2a80b5d18a508266718f2092e72f))
* **web:** [#3269](https://github.com/coco-de/coui/issues/3269) — TextField disabled 라벨 recolor 실동작 (resolver-time, Flutter 파리티) ([#3288](https://github.com/coco-de/coui/issues/3288)) ([93b08bf](https://github.com/coco-de/coui/commit/93b08bfa626ed6f96741ffbe234d0eb2f6f023d2))
* **web:** [#3276](https://github.com/coco-de/coui/issues/3276) — border-width rem → px 고정 (47 사이트 + strokeWidthCss + Phase 7 가드) ([#3279](https://github.com/coco-de/coui/issues/3279)) ([262e076](https://github.com/coco-de/coui/commit/262e0765f3456a9e0c4e4115fd68dd7b6a953a09))
* **web:** [#3495](https://github.com/coco-de/coui/issues/3495) — ScrollableClient 뷰포트에 UA 포커스 아웃라인 억제 추가 ([#3976](https://github.com/coco-de/coui/issues/3976)) ([27916dc](https://github.com/coco-de/coui/commit/27916dcf68f949915132802f09357ee931f198b2))
* **web:** [#3704](https://github.com/coco-de/coui/issues/3704) — DotIndicator 의 hover 가 터치 타겟 오버레이에 가려 죽어 있었다 ([#3709](https://github.com/coco-de/coui/issues/3709)) ([dc4475d](https://github.com/coco-de/coui/commit/dc4475d03e5e0f066f14c0db68eeeec108cbb0dc))
* **web:** [#3705](https://github.com/coco-de/coui/issues/3705) — 포인터 타겟 확장이 자기 안쪽을 가리지 않게 ([#3717](https://github.com/coco-de/coui/issues/3717)) ([e511b8e](https://github.com/coco-de/coui/commit/e511b8e9333a76791f3b7d6296496bc61906fa2a))
* **web:** [#3776](https://github.com/coco-de/coui/issues/3776) — theme_config.dart Tailwind screens를 CoreBreakpoint에 배선 ([#3835](https://github.com/coco-de/coui/issues/3835)) ([b3d7b34](https://github.com/coco-de/coui/commit/b3d7b34d703809d4c563749297127da087cefe7c))
* **web:** [#3829](https://github.com/coco-de/coui/issues/3829) — DraggablePanel 이 드래그 스코프가 렌더한 박스에 높이를 잃는다 ([#3830](https://github.com/coco-de/coui/issues/3830)) ([0e622f7](https://github.com/coco-de/coui/commit/0e622f73c3cb03dcbddee8624301b385bd561b4f))
* **web:** [#4312](https://github.com/coco-de/coui/issues/4312) — press 이동이 컨트롤의 위치를 덮지 않게 한다 ([#4313](https://github.com/coco-de/coui/issues/4313)) ([e014328](https://github.com/coco-de/coui/commit/e0143283bf0403acd2ee911f3778c753c19194ed))
* **web:** [#4314](https://github.com/coco-de/coui/issues/4314) — Sortable 이 자기 슬롯 위에서도 포인터를 따라오게 한다 ([#4315](https://github.com/coco-de/coui/issues/4315)) ([5cdde40](https://github.com/coco-de/coui/commit/5cdde40459b4e20762ff92bd38d88b5a21b630fa))
* **web:** [#4403](https://github.com/coco-de/coui/issues/4403) — 캐스트 engage 트리거를 기기 능력으로 가른다 ([#4418](https://github.com/coco-de/coui/issues/4418)) ([8a3cc45](https://github.com/coco-de/coui/commit/8a3cc453243ab930f68023eedcfe0ba36a81b6d0))
* **web:** [#4414](https://github.com/coco-de/coui/issues/4414) — 인라인 box-shadow 에 막힌 Button focus ring 을 !important 로 되살린다 ([#4417](https://github.com/coco-de/coui/issues/4417)) ([3a5b012](https://github.com/coco-de/coui/commit/3a5b0120803c96b0c5c56f749b4c83f0b680ce71))
* **web:** [#4421](https://github.com/coco-de/coui/issues/4421) — 키보드 Space/Enter 활성화에 press 어포던스를 준다 ([#4423](https://github.com/coco-de/coui/issues/4423)) ([d02a213](https://github.com/coco-de/coui/commit/d02a2135378ad1311fe881dd75158e29a7ad58ec))
* **web:** Avatar 이니셜/child 콘텐츠가 OutlinedContainer 합성 후 중앙정렬 안 됨 ([#4586](https://github.com/coco-de/coui/issues/4586)) ([aef05ee](https://github.com/coco-de/coui/commit/aef05ee00937fc582339e5bc12356686004efa70))
* **web:** neo-brutalism strokeFloor not reaching Web stroke/line-width emits ([#3809](https://github.com/coco-de/coui/issues/3809)) ([675779b](https://github.com/coco-de/coui/commit/675779b63bfafbd13380c687ff19861812801000))
* **web:** neoBrutalism press 그림자가 박스와 같이 미끄러지는 cascade 충돌을 고친다 ([#4491](https://github.com/coco-de/coui/issues/4491)) ([2bba1c8](https://github.com/coco-de/coui/commit/2bba1c82797aa2800d7eca905c1d215e3d8ecace))
* **web:** pseudo-state 색 raw override 크래시 해소 — class XOR scoped &lt;style&gt; emit ([#3265](https://github.com/coco-de/coui/issues/3265)) ([87d94ef](https://github.com/coco-de/coui/commit/87d94efe6fec2fc0385ef7dba7117275d4c358d9))
* **web:** radius 19계단 전부가 변수로 나간다 — 두 목록을 하나로 합친다 ([#4297](https://github.com/coco-de/coui/issues/4297)) ([c500688](https://github.com/coco-de/coui/commit/c500688e6991dc8a7f1acaaa10090350c3ac53f9)), closes [#4296](https://github.com/coco-de/coui/issues/4296)
* **web:** Text 체인 role 클래스로 emit — neoBrutalism weightFloor 반영 ([#4450](https://github.com/coco-de/coui/issues/4450)) ([1dec5f1](https://github.com/coco-de/coui/commit/1dec5f178c895b0ffd521a527f82ef0704256b01)), closes [#4449](https://github.com/coco-de/coui/issues/4449)
* **web:** 고대비가 장식 프리셋에 지던 순서를 특이도로 뒤집음 ([#3373](https://github.com/coco-de/coui/issues/3373)) ([41c534a](https://github.com/coco-de/coui/commit/41c534a85ab7f1bac6eb12da8d4efed574882deb))
* **web:** 그림자로만 경계를 그리는 프리셋에 forced-colors 경계를 실제로 그림 ([#3369](https://github.com/coco-de/coui/issues/3369)) ([3c5fc9d](https://github.com/coco-de/coui/commit/3c5fc9d91f8ceda619dd9f144e6b165e2301a824))
* **web:** 채움 없는 버튼이 비켜준 적 없는 자리로 들어가지 않게 한다 ([#4318](https://github.com/coco-de/coui/issues/4318)) ([7c2c95c](https://github.com/coco-de/coui/commit/7c2c95cb34da624f38ea861abbaba262adb52df5))
* **web:** 캐스트가 hoverable 카드에도 도달한다 ([#4244](https://github.com/coco-de/coui/issues/4244)) ([5d2501b](https://github.com/coco-de/coui/commit/5d2501bb3b7e399952b537ae9239f0c53ca76029))


### 리팩터링

* **group:** deprecate Group — duplicates Stacks + Position ([#4094](https://github.com/coco-de/coui/issues/4094)) ([de4f177](https://github.com/coco-de/coui/commit/de4f177a2328688d291d28ac454d2ac28dccb53e))
* **web:** [#3285](https://github.com/coco-de/coui/issues/3285) — check_web_resolver 가드 green (Flutter 가드 미러 + 진짜 위반 실해소) ([#3287](https://github.com/coco-de/coui/issues/3287)) ([7884fc0](https://github.com/coco-de/coui/commit/7884fc0f616afd1607ad9a90f86b14a39e07206b))
* **web:** [#3848](https://github.com/coco-de/coui/issues/3848) — Sortable 의 픽셀에 닿지 않는 선언 정리 ([#3849](https://github.com/coco-de/coui/issues/3849)) ([2b05851](https://github.com/coco-de/coui/commit/2b05851c1340e4ff8a6e15d63ccc009372c19c2b))


### 문서

* **rules:** [#3319](https://github.com/coco-de/coui/issues/3319) — 폼 밖 에러 표면 결정 + 톤별 통보 방식 ([#3425](https://github.com/coco-de/coui/issues/3425)) ([af73647](https://github.com/coco-de/coui/commit/af73647171e825ae2d9362491fc0acc63404032d))


### 기타

* **deps:** [#4439](https://github.com/coco-de/coui/issues/4439) — Flutter 3.47.0 · jaspr 0.23.4 로 툴체인 상향 ([#4440](https://github.com/coco-de/coui/issues/4440)) ([a033bed](https://github.com/coco-de/coui/commit/a033beda885234867322886211f342e03e93ea41))

## [0.133.0](https://github.com/coco-de/coui/compare/coui_web-v0.132.0...coui_web-v0.133.0) (2026-09-03)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** `CoreFilterItem<T>` 가 `CoreFilterItem<T, W>` 가 된다 — 명시 제네릭으로 쓰던 코드는 `<T, Widget>` / `<T, Component>` 로 바꾼다(추론으로 만드는 호출은 그대로). `CoreFilterStyle.defaultItemPadding` 이 h16/v8 에서 8 사방으로, 세그먼트 높이가 32 고정으로, reset 이 plain·md 에서 ghost·sm·square 로 바뀌어 Filter 의 렌더가 달라진다.
* `CoreBadgeContract.child` 가 `W` 에서 `W?` 로 바뀌고 `CoreBadgeContract.form` getter 가 새로 생긴다. 이 계약을 직접 `implements` 하는 코드는 두 멤버를 갱신해야 한다. Flutter/Web `Badge` 위젯 사용처는 영향이 없다 — `child` 는 더 관대해진 방향이고 `form` 은 `CoreBadgeForm.count` 기본값을 갖는다.
* **core,flutter,web,figma:** AppBar 의 withStyle patch 타입이 CoreScaffoldStyle 에서 CoreAppBarStyle 로 바뀌고, ResolvedScaffold 에서 headerPadding/headerSpacing/ headerActionSpacing 이 빠진다(소비 위젯 0). scaffoldStyle 파라미터는 deprecated 매핑으로 동작을 유지한다.
* **core:** 
* **core:** 플레이스홀더가 자기 색 슬롯을 갖는다 ([#4477](https://github.com/coco-de/coui/issues/4477))
* **deps:** #4439 — Flutter 3.47.0 · jaspr 0.23.4 로 툴체인 상향 ([#4440](https://github.com/coco-de/coui/issues/4440))
* **core:** ResolvedColorScheme 생성자에 primaryText· primaryTextLarge 필수 파라미터가 추가된다. CoreColorScheme 를 직접 구현/생성하는 소비자는 두 슬롯을 채워야 한다.
* **surface:** #4217 — 유리 오버레이가 자기 트리거에서 자라난다 ([#4302](https://github.com/coco-de/coui/issues/4302))
* **surface:** Text 체인의 accent fill getter 6종이 Web 에서 제거되고 Flutter 에서 deprecated 됐다. `.on{Role}Container` 로 교체한다.
* **core,flutter,web:** #4082 — #4001 후속 4건 (resizable 정규화 · focus-ring 슬롯/합성 3건) ([#4121](https://github.com/coco-de/coui/issues/4121))
* **flutter,web:** #3979 — a11y 감사 후속 5건 (Scrollbar 접근성 노드·값 축·플랫폼 대칭 + TimePicker 링) ([#3999](https://github.com/coco-de/coui/issues/3999))

### 기능

* **a11y:** [#3391](https://github.com/coco-de/coui/issues/3391) — nav 패밀리 role seat + Flutter expanded 배선 ([#3424](https://github.com/coco-de/coui/issues/3424)) ([c81ef74](https://github.com/coco-de/coui/commit/c81ef74cef84ab48cb75460a851d11f279e18de0))
* **a11y:** [#3426](https://github.com/coco-de/coui/issues/3426) — EmptyState 에 톤 축 (실패인 빈 상태 vs 그냥 빈 상태) ([#3431](https://github.com/coco-de/coui/issues/3431)) ([915fbb2](https://github.com/coco-de/coui/commit/915fbb2cc2a2145934a260496662e6019bbb14c7))
* **a11y:** 포인터 타겟 하한 — 그리는 크기가 아니라 닿는 범위를 넓힌다 ([#3410](https://github.com/coco-de/coui/issues/3410)) ([def5370](https://github.com/coco-de/coui/commit/def5370fd4753d95e5169a32ab47819cbb818c60))
* **autocomplete:** [#4189](https://github.com/coco-de/coui/issues/4189) — 키보드로 제안에 도달할 수 있게 한다 ([#4225](https://github.com/coco-de/coui/issues/4225)) ([188ac60](https://github.com/coco-de/coui/commit/188ac60d56c18139b796f3aaf63158f403f1bda3))
* Badge 가 점을 그릴 수 있게 된다 — 캔버스의 Style 축을 흡수 ([#4606](https://github.com/coco-de/coui/issues/4606)) ([e454861](https://github.com/coco-de/coui/commit/e4548610f49ef6f7b41cdb6c591fab5a9eb3e5d8))
* **core,flutter,web,docs:** [#4413](https://github.com/coco-de/coui/issues/4413) — 브라우저가 여는 Disclosure ([#4415](https://github.com/coco-de/coui/issues/4415)) ([e5ded92](https://github.com/coco-de/coui/commit/e5ded921fb3e6924d6fa1b1e4c4f0c09a4bfa9d0))
* **core,flutter,web,figma:** [#4544](https://github.com/coco-de/coui/issues/4544) — ValidatorHint 에 neutral 을 더한다 ([#4545](https://github.com/coco-de/coui/issues/4545)) ([9a41de0](https://github.com/coco-de/coui/commit/9a41de07e69bdb99d5d69094c651db4d0c865518))
* **core,flutter,web,figma:** AppBar 가 디자이너 세트를 스펙으로 얻는다 — 계약 신설 · 양 플랫폼 이동 · 빌더 등록 ([7c154ba](https://github.com/coco-de/coui/commit/7c154ba1f85c8b74747ad2c7398112c4d8dc0e44))
* **core,flutter,web,figma:** Filter 세그먼트가 아이콘을 갖고 정사각으로 접힌다 — 디자이너의 세그먼트 프로퍼티를 흡수한다 ([#4628](https://github.com/coco-de/coui/issues/4628)) ([bc544e4](https://github.com/coco-de/coui/commit/bc544e431e99add953277472193e60cd90a5a3af))
* **core,flutter,web,figma:** FormField 에 labelAction · counterText 를 더한다 ([#4548](https://github.com/coco-de/coui/issues/4548)) ([be90fce](https://github.com/coco-de/coui/commit/be90fce189afb1772a1a25ba09c8c21e26e41c22))
* **core,flutter,web,figma:** NavigationBar 디자이너 편집 + NavigationBarItem 반영 ([#4444](https://github.com/coco-de/coui/issues/4444)) ([41483ae](https://github.com/coco-de/coui/commit/41483ae5eb0ff5f9cda1f8c34eaab15ba5e7c1c2))
* **core,flutter,web,figma:** Size 3계층 토큰 시스템 + Figma 7컬렉션 라이브 파일 완전 정렬 ([#4214](https://github.com/coco-de/coui/issues/4214)) ([d911b53](https://github.com/coco-de/coui/commit/d911b53524945ddb3386187a8fd60176efdd1f0a))
* **core,flutter,web:** [#3763](https://github.com/coco-de/coui/issues/3763) — Core↔docs 정합 잔여 트랙 완료 (Epic K 치수표 확정 + Track B 정리) ([#3916](https://github.com/coco-de/coui/issues/3916)) ([00070c9](https://github.com/coco-de/coui/commit/00070c9c45ae22064fadbac4b4df2ac59228bc65))
* **core,flutter,web:** [#4218](https://github.com/coco-de/coui/issues/4218) — 채도와 엣지 시인이 양 플랫폼 픽셀에 도달한다 ([#4230](https://github.com/coco-de/coui/issues/4230)) ([0266bc2](https://github.com/coco-de/coui/commit/0266bc219a86ee0035bafedf94d9be90209b3bf6))
* **core,flutter,web:** [#4351](https://github.com/coco-de/coui/issues/4351) — 마커가 자기 역할을 나른다 ([#4376](https://github.com/coco-de/coui/issues/4376)) ([e2670a9](https://github.com/coco-de/coui/commit/e2670a97b8440e002e2a8c2fb63923414a0698f3))
* **core,flutter,web:** [#4352](https://github.com/coco-de/coui/issues/4352) — 중첩 정책을 축으로 올려 두 플랫폼을 맞춘다 ([#4377](https://github.com/coco-de/coui/issues/4377)) ([a872768](https://github.com/coco-de/coui/commit/a872768f983372980bab5225cd942fc7eac271e3))
* **core,flutter,web:** Chip 에 emphasis 축을 추가한다 — 조용한 레지스터 ([#4488](https://github.com/coco-de/coui/issues/4488)) ([e55dbf4](https://github.com/coco-de/coui/commit/e55dbf43a6946d8b2fefa4fe8d81ad9a6506caf5))
* **core:** [#2870](https://github.com/coco-de/coui/issues/2870) — 표면 하이라이트 팔레트 슬롯 + clay inset rim ([#3405](https://github.com/coco-de/coui/issues/3405)) ([8c00ec5](https://github.com/coco-de/coui/commit/8c00ec540ce2e01a98872fd0efaae7392213e6cd))
* **core:** [#3345](https://github.com/coco-de/coui/issues/3345) — 서피스 기하 재지정 (radius + stroke) ([#3354](https://github.com/coco-de/coui/issues/3354)) ([5613f56](https://github.com/coco-de/coui/commit/5613f5687c0e209b1503c0fd3659db309978cc05))
* **core:** [#3351](https://github.com/coco-de/coui/issues/3351) — 그림자 기하 재지정 + neo-brutalism 서명 그림자 ([#3358](https://github.com/coco-de/coui/issues/3358)) ([ed792fc](https://github.com/coco-de/coui/commit/ed792fc1085a0058d699956797a718b67c23679c))
* **core:** [#3352](https://github.com/coco-de/coui/issues/3352) — 프리셋 경계 색 재지정 (outlineEmphasis) ([#3355](https://github.com/coco-de/coui/issues/3355)) ([4108ee0](https://github.com/coco-de/coui/commit/4108ee0f3df7a633641ed187446f172779967c9d))
* **core:** [#3356](https://github.com/coco-de/coui/issues/3356) — 프리셋 typography weight 축 (neo-brutalism 레시피 완성) ([#3359](https://github.com/coco-de/coui/issues/3359)) ([0b98ac0](https://github.com/coco-de/coui/commit/0b98ac0038c01cd2214cd669877c9bc92b6fb7ad))
* **core:** [#4219](https://github.com/coco-de/coui/issues/4219) — 앱이 글래스 재질을 정한다 (CoreSurfaceTuning) ([#4254](https://github.com/coco-de/coui/issues/4254)) ([c20829f](https://github.com/coco-de/coui/commit/c20829fb5c9628a9d75a7c4352450c7cb2bc03d2))
* **core:** [#4402](https://github.com/coco-de/coui/issues/4402) — 캐스트가 engage 될 때 무엇을 할지 컨트롤이 말하게 한다 ([#4412](https://github.com/coco-de/coui/issues/4412)) ([e22b207](https://github.com/coco-de/coui/commit/e22b207e46bd293c53327e3758c15c9ab701de66))
* **core:** [#4509](https://github.com/coco-de/coui/issues/4509) — Chip 이 상태 레이어를 그린다 (hover · focus · pressed) ([#4522](https://github.com/coco-de/coui/issues/4522)) ([f7fe6e5](https://github.com/coco-de/coui/commit/f7fe6e598434fdd8d30da147313622a00da81ccb))
* **core:** [#4509](https://github.com/coco-de/coui/issues/4509) — NavigationBarItem 이 상태 레이어를 그린다, 그리고 다크의 구멍을 메운다 ([#4517](https://github.com/coco-de/coui/issues/4517)) ([8e29e56](https://github.com/coco-de/coui/commit/8e29e56846eaca5d19dc152056a3390eec5a6a70))
* **core:** [#4509](https://github.com/coco-de/coui/issues/4509) — TextField 가 상태 레이어를 그린다 (hover · focus · pressed) ([#4516](https://github.com/coco-de/coui/issues/4516)) ([f060cea](https://github.com/coco-de/coui/commit/f060cea10768ed3841e457bffcd4dce0b5a17a0f))
* **core:** [#4523](https://github.com/coco-de/coui/issues/4523) — Checkbox 라벨이 사이즈 축을 타고, description·trailing 슬롯이 생긴다 ([#4524](https://github.com/coco-de/coui/issues/4524)) ([8bfadf5](https://github.com/coco-de/coui/commit/8bfadf593939a8729234cc71547f2c3f3aae05e8))
* **core:** Banner emphasis 축 · Alert 재설계 · Button 상태 레이어와 포커스 링 ([#4505](https://github.com/coco-de/coui/issues/4505)) ([636cda0](https://github.com/coco-de/coui/commit/636cda075bebb9769127d9a04f0565b62ea256cf))
* **core:** display 역할이 regular(400) 로 — light 는 대형 제목에서 획이 사라진다 ([#4617](https://github.com/coco-de/coui/issues/4617)) ([d35041b](https://github.com/coco-de/coui/commit/d35041b0f65e55c086d425abb536ecd71bccb634))
* **core:** label role 이 body 보다 무거워지고, 계열이 사다리 끝까지 이어진다 ([#4556](https://github.com/coco-de/coui/issues/4556)) ([3629255](https://github.com/coco-de/coui/commit/3629255985a679086c3a100741a3002bb082ded1))
* **core:** 눌림 chrome 축 — 이동과 그림자 ([#3399](https://github.com/coco-de/coui/issues/3399)) ([6821dd1](https://github.com/coco-de/coui/commit/6821dd1000b6a3b28a8b9f3079958aec4d1020a9))
* **core:** 브랜드가 시맨틱 매핑을 소유한다 — Figma 토큰 편집 역동기화 ([#4434](https://github.com/coco-de/coui/issues/4434)) ([96ba6e9](https://github.com/coco-de/coui/commit/96ba6e976d19765d3d09966daabaa4422c09cabb))
* **core:** 시맨틱 role seat — Core 가 들고 있던 raw ARIA 문자열 제거 ([#3403](https://github.com/coco-de/coui/issues/3403)) ([766360a](https://github.com/coco-de/coui/commit/766360a38dcc32b8163b8ec7cd3f57462d79777a))
* **core:** 플레이스홀더가 자기 색 슬롯을 갖는다 ([#4477](https://github.com/coco-de/coui/issues/4477)) ([a24b142](https://github.com/coco-de/coui/commit/a24b1423e276ab88a05ea010a908e1ed6a4b4b09))
* **coui:** DefinitionList · DisclosureBadge 신설 ([#4260](https://github.com/coco-de/coui/issues/4260)) ([ae07784](https://github.com/coco-de/coui/commit/ae07784601d55b23b6de805b3744a0a080001719))
* **cross-platform:** [#4186](https://github.com/coco-de/coui/issues/4186) — 잔여 3건 (divider childAlignment · 피드백 전역 opt-out · Web 버튼 chrome 전환) ([#4257](https://github.com/coco-de/coui/issues/4257)) ([ed2b409](https://github.com/coco-de/coui/commit/ed2b409f58b92cdcca3c941497bf78aa436942c7)), closes [#4200](https://github.com/coco-de/coui/issues/4200) [#4201](https://github.com/coco-de/coui/issues/4201) [#4202](https://github.com/coco-de/coui/issues/4202)
* **figma:** 브랜드 축 — 브랜드별 Semantic/Color 컬렉션 + 리바인딩 플러그인 커맨드 ([#4290](https://github.com/coco-de/coui/issues/4290)) ([ff0d254](https://github.com/coco-de/coui/commit/ff0d2540cf92a8a06272367dfdec3e0577dc9a72))
* **flutter,web,figma:** TextField suffix 에 글자가 들어간다 — 코드가 먼저 타이포를 말하고, 캔버스가 슬롯을 얻는다 ([#4611](https://github.com/coco-de/coui/issues/4611)) ([d636914](https://github.com/coco-de/coui/commit/d6369146e4a8371df5987b5ab2b87a3c81ceda19))
* FormattedInput 단일 필드 마스크 재설계 — 백스페이스 연속성 · 커스텀 마스크 · 자동완성 ([#3866](https://github.com/coco-de/coui/issues/3866)) ([#3900](https://github.com/coco-de/coui/issues/3900)) ([68e8513](https://github.com/coco-de/coui/commit/68e8513867da78c58b3421791e32b759e651cb39))
* **i18n:** [#3429](https://github.com/coco-de/coui/issues/3429) — 논리 방향 inset (가로 비대칭 4건 전부) ([#3438](https://github.com/coco-de/coui/issues/3438)) ([ee951e4](https://github.com/coco-de/coui/commit/ee951e419b99d5356ebc3882c866155f8c7dd205))
* **icon:** 아이콘 크기 사다리 — 실제 결함은 네임스페이스 반전이었다 ([#3420](https://github.com/coco-de/coui/issues/3420)) ([625baa4](https://github.com/coco-de/coui/commit/625baa49cca467a0cfeec898285f8f4dd1a5cdee))
* **icon:** 출하 컴포넌트를 Lucide 하나로 — 그리고 글리프 정체에 걸린 동작 분리 ([#3419](https://github.com/coco-de/coui/issues/3419)) ([63d7df1](https://github.com/coco-de/coui/commit/63d7df13a73780df19fcb52670649ff02f874149))
* neo-brutalism 대각선 그림자·press-squash(Button/Fab) + card_image OutlinedContainer 합성 ([#4178](https://github.com/coco-de/coui/issues/4178)) ([78d74e6](https://github.com/coco-de/coui/commit/78d74e6e610babf82c78719b16b227db01dc8de9))
* **phone_input:** 전화번호 완전성 validator — Form 이 "완전한 번호" 를 말할 수단 ([#4243](https://github.com/coco-de/coui/issues/4243)) ([a36fe90](https://github.com/coco-de/coui/commit/a36fe90f6f8970b68f4edc92e6f1e1683c744fb9))
* Project [#3294](https://github.com/coco-de/coui/issues/3294) — 디자인 시스템 견고화 (접근성 축 10건 + 서피스 프리셋 축 4건) ([#3349](https://github.com/coco-de/coui/issues/3349)) ([5b6287d](https://github.com/coco-de/coui/commit/5b6287d1c48b73eb208b3838bd94effb9d9b1711))
* **state:** [#3318](https://github.com/coco-de/coui/issues/3318) — 로딩 슬롯 판정: 필요한 컴포넌트가 없다 ([#3439](https://github.com/coco-de/coui/issues/3439)) ([3ec5ec7](https://github.com/coco-de/coui/commit/3ec5ec7425d2ac1c8501b15e5afbd39342d07d99))
* **surface:** [#4208](https://github.com/coco-de/coui/issues/4208) — 앱이 서페이스 프리셋을 자기 값으로 튜닝한다 ([#4240](https://github.com/coco-de/coui/issues/4240)) ([44093f7](https://github.com/coco-de/coui/commit/44093f75698976755992e85af17e642260ce4794))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 두 플랫폼이 같은 실루엣을 각자 스펠링한다 ([#4299](https://github.com/coco-de/coui/issues/4299)) ([e137e70](https://github.com/coco-de/coui/commit/e137e709c81e181d1f3af03a6b61a94058e5f8e8))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 모프 클립을 양 플랫폼에 세운다 ([#4300](https://github.com/coco-de/coui/issues/4300)) ([9c39a2b](https://github.com/coco-de/coui/commit/9c39a2b65b63b6e6d00b5283fe656366685c4d61))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 유리 오버레이가 자기 트리거에서 자라난다 ([#4302](https://github.com/coco-de/coui/issues/4302)) ([57e1e0f](https://github.com/coco-de/coui/commit/57e1e0f3c25194608fa541c597e329f0684674a4))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 유리 표면의 경계는 재질이 그린다 ([#4284](https://github.com/coco-de/coui/issues/4284)) ([9edf08e](https://github.com/coco-de/coui/commit/9edf08e93243224043b6a8153edfe8196d45e2b9))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 유리가 유리처럼 보일 만큼 재질을 올린다 ([#4306](https://github.com/coco-de/coui/issues/4306)) ([fa604e5](https://github.com/coco-de/coui/commit/fa604e567b29779c6f7bf9542c24fc774879c060))
* **surface:** [#4222](https://github.com/coco-de/coui/issues/4222) — 굴절은 축이 아니라 표면이 여는 역량이다 ([#4270](https://github.com/coco-de/coui/issues/4270)) ([f3bf226](https://github.com/coco-de/coui/commit/f3bf226879382ecb1e064dcffbc22cdd80488c48))
* **surface:** [#4323](https://github.com/coco-de/coui/issues/4323) — 어느 컴포넌트가 표면인지 목록이 아니라 규칙이 답한다 ([#4332](https://github.com/coco-de/coui/issues/4332)) ([729469c](https://github.com/coco-de/coui/commit/729469cf75bb7260fc00fd3205bac80a4a1b4fbd))
* **surface:** [#4325](https://github.com/coco-de/coui/issues/4325) — 떠 있는 패널 넷이 재질을 받는다 (flutter 8→12 · web 9→13) ([#4335](https://github.com/coco-de/coui/issues/4335)) ([ac46cf1](https://github.com/coco-de/coui/commit/ac46cf1a97211d313398044a20e00e39ae7870c2))
* **surface:** [#4326](https://github.com/coco-de/coui/issues/4326) — 컨테이너 크롬 둘이 재질을 받고, 다섯은 근거와 함께 받지 않는다 ([#4337](https://github.com/coco-de/coui/issues/4337)) ([96a286d](https://github.com/coco-de/coui/commit/96a286d94f1b1a7e05c37b8f956a57f84268049b))
* **surface:** [#4327](https://github.com/coco-de/coui/issues/4327) — 카탈로그 감사가 재질도 본다, 그리고 중첩 유리를 찾았다 ([#4338](https://github.com/coco-de/coui/issues/4338)) ([b2f3ebb](https://github.com/coco-de/coui/commit/b2f3ebb1150bafa064d1e119a33a5fd436906c7d))
* **surface:** [#4329](https://github.com/coco-de/coui/issues/4329) — 투명도 줄이기 폴백을 Flutter 에서도 켤 수 있게 한다 ([#4341](https://github.com/coco-de/coui/issues/4341)) ([5bff601](https://github.com/coco-de/coui/commit/5bff601e25cce6793ad51c724fc0e7681ecc1661))
* **surface:** [#4369](https://github.com/coco-de/coui/issues/4369) — 바닥값이 못 올리는 0 에, 스타일이 경계를 직접 기여한다 ([#4370](https://github.com/coco-de/coui/issues/4370)) ([ab9694b](https://github.com/coco-de/coui/commit/ab9694bd8512e646939b21435f4109a0752aed20))
* **theme:** [#2865](https://github.com/coco-de/coui/issues/2865) — Neo-brutalism 프리셋 (첫 E2E) + docs 스타일 스위처 ([#3357](https://github.com/coco-de/coui/issues/3357)) ([40d6999](https://github.com/coco-de/coui/commit/40d69999eac9210c1050a71e9394c7f30d7e31b6))
* **theme:** [#3183](https://github.com/coco-de/coui/issues/3183) — 내비 표면이 재질을 받고, 떠 있을 수 있다 ([#3436](https://github.com/coco-de/coui/issues/3436)) ([7ae43c4](https://github.com/coco-de/coui/commit/7ae43c42ba4ebdc5e0dc66011627ef29fb5b4e1d))
* **theme:** 그림자 미러 축 — 배율로는 두 번째 방향을 만들 수 없다 ([#3414](https://github.com/coco-de/coui/issues/3414)) ([8691726](https://github.com/coco-de/coui/commit/86917267025647d0d210208a87046e195f4f0874))
* **theme:** 남은 프리셋 3종 (Glass · Neumorphism · Claymorphism) + orphan surface 필드 배선 ([#3362](https://github.com/coco-de/coui/issues/3362)) ([536bafc](https://github.com/coco-de/coui/commit/536bafceb1be2faf85fdda7e8aae755e559e3e98))
* **theme:** 표면 스타일이 반경 범위를 진술 — 사다리 위 재배치 ([#3407](https://github.com/coco-de/coui/issues/3407)) ([9c39d49](https://github.com/coco-de/coui/commit/9c39d490fb70f613d034ff39423e725cdddaace3))
* **web,core:** [#4217](https://github.com/coco-de/coui/issues/4217) — 투명도 줄이기 요청에 유리가 답한다 (G5) ([#4305](https://github.com/coco-de/coui/issues/4305)) ([1f40f64](https://github.com/coco-de/coui/commit/1f40f6400f9ce3429281a90d4932b08175d1b15d))
* **web:** [#3318](https://github.com/coco-de/coui/issues/3318) 선행 — 스켈레톤 표준 확정 + 정직하지 않은 클래스 삭제 ([#3437](https://github.com/coco-de/coui/issues/3437)) ([ebb1f67](https://github.com/coco-de/coui/commit/ebb1f676f8f3ef3eafeaa739b57d8f1f1fa3c575))
* **web:** [#3434](https://github.com/coco-de/coui/issues/3434) — glass 표면 처리에 Web transport (프리셋이 실제로 유리가 된다) ([#3435](https://github.com/coco-de/coui/issues/3435)) ([b6f620a](https://github.com/coco-de/coui/commit/b6f620a461b39449cb8272fe3e6d5359c6e49471))
* **web:** [#3763](https://github.com/coco-de/coui/issues/3763) — Core↔docs 정합 트랙 A(Web transport 결함) 완료 ([#3845](https://github.com/coco-de/coui/issues/3845)) ([5e558b9](https://github.com/coco-de/coui/commit/5e558b94bc79e8fcffae810e892b45876c9600f5))
* **web:** 컴포넌트 그림자가 CSS 변수를 지나게 함 — 프리셋이 절반만 닿던 것 ([#3398](https://github.com/coco-de/coui/issues/3398)) ([00f7ece](https://github.com/coco-de/coui/commit/00f7ece8dfe48a68a50158def0442c0bdd504050))


### 버그 수정

* [#3843](https://github.com/coco-de/coui/issues/3843) [#3846](https://github.com/coco-de/coui/issues/3846) — Sortable 드래그 행 z-order + 핸들 아이콘 정렬 ([#3847](https://github.com/coco-de/coui/issues/3847)) ([7d68e39](https://github.com/coco-de/coui/commit/7d68e39b70e8b50c5fef3e85b8e5e7dba12aa770))
* **a11y:** [#3432](https://github.com/coco-de/coui/issues/3432) — 문서화가 드러낸 배선 결함 6건 ([#3442](https://github.com/coco-de/coui/issues/3442)) ([fb64ea1](https://github.com/coco-de/coui/commit/fb64ea1570bf5103c1079630cc1a69459f5fb3b4))
* **a11y:** [#4117](https://github.com/coco-de/coui/issues/4117) — 아이콘 전용 affordance 10곳에 접근 가능한 이름 부여 ([#4124](https://github.com/coco-de/coui/issues/4124)) ([c25d77d](https://github.com/coco-de/coui/commit/c25d77d92472f31414421b89b80c75ddf72dc3c1))
* **a11y:** [#4155](https://github.com/coco-de/coui/issues/4155) — Status live region 파리티 + 미번역 기본 라벨 제거 ([#4156](https://github.com/coco-de/coui/issues/4156)) ([4502688](https://github.com/coco-de/coui/commit/4502688e103bfba82360101d7aa82fdbf6fb5cc3))
* **a11y:** 링크·푸터 시맨틱 복구 + Chip·Avatar·Badge 전달 인자 + 정적 사이트 다크 모드 경로 ([#4271](https://github.com/coco-de/coui/issues/4271)) ([0a20bfc](https://github.com/coco-de/coui/commit/0a20bfcea18e16231b272f6267d01d46675e5c0f))
* **alert:** 박스를 직접 그리는 대신 OutlinedContainer 를 합성한다 ([#4249](https://github.com/coco-de/coui/issues/4249)) ([1466afc](https://github.com/coco-de/coui/commit/1466afc9aa718859ab86f8694560fa2f142e9d94))
* **autocomplete:** [#4187](https://github.com/coco-de/coui/issues/4187) — 패널을 텍스트 편집이 아니라 props 에 재조정 ([#4213](https://github.com/coco-de/coui/issues/4213)) ([cf5a6a1](https://github.com/coco-de/coui/commit/cf5a6a10434e26030355244c8cbd71455d41aa69))
* **autocomplete:** [#4188](https://github.com/coco-de/coui/issues/4188) — replaceWord 가 캐럿 위치의 단어를 완성한다 ([#4215](https://github.com/coco-de/coui/issues/4215)) ([cf69ea0](https://github.com/coco-de/coui/commit/cf69ea02ecf7ea66b0cc2d6de224b5c50303fe46))
* **badge:** 스타일의 캐스트를 받는다 + 변환을 한 함수로 모은다 ([#4252](https://github.com/coco-de/coui/issues/4252)) ([2857959](https://github.com/coco-de/coui/commit/2857959c642eaf43fb2f34ca41dbeceddd0ed851))
* **chip:** [#4289](https://github.com/coco-de/coui/issues/4289) · [#4294](https://github.com/coco-de/coui/issues/4294) 를 main 으로 다시 올린다 (스택 베이스로 머지돼 도달 못 함) ([#4298](https://github.com/coco-de/coui/issues/4298)) ([c3794d6](https://github.com/coco-de/coui/commit/c3794d6c2d08d1f54b436a0414ed7a487e5d22db)), closes [#4293](https://github.com/coco-de/coui/issues/4293)
* **command:** 헤더 안 Command 팔레트가 뷰포트 전체를 못 쓰던 문제 수정 ([#4378](https://github.com/coco-de/coui/issues/4378)) ([f67053c](https://github.com/coco-de/coui/commit/f67053cbc7aae57a760985df34fd51de6d97738f))
* **core,flutter,web,figma:** Toast 액션이 슬랩 위에서 읽힌다 — 2.1:1 과 1.0:1 을 고친다 ([#4610](https://github.com/coco-de/coui/issues/4610)) ([73b93fe](https://github.com/coco-de/coui/commit/73b93fe582a6966c2a5b48a7be00dc7bea2c6fff))
* **core,flutter,web:** [#3495](https://github.com/coco-de/coui/issues/3495) — 드래그-스크롤 뷰포트를 보조 기술·키보드에 노출 ([#3958](https://github.com/coco-de/coui/issues/3958)) ([cd1a0f7](https://github.com/coco-de/coui/commit/cd1a0f7e0c513349fcce5aec7cb2a684b40f6923))
* **core,flutter,web:** [#3502](https://github.com/coco-de/coui/issues/3502) B — warning fill 을 텍스트 색에서 분리 (WCAG 1.4.3) ([#3973](https://github.com/coco-de/coui/issues/3973)) ([3c4e8d2](https://github.com/coco-de/coui/commit/3c4e8d2206a7e065a4f99129443bfad5cd69a70a))
* **core,flutter,web:** [#4082](https://github.com/coco-de/coui/issues/4082) — [#4001](https://github.com/coco-de/coui/issues/4001) 후속 4건 (resizable 정규화 · focus-ring 슬롯/합성 3건) ([#4121](https://github.com/coco-de/coui/issues/4121)) ([edf91db](https://github.com/coco-de/coui/commit/edf91db8f06b411496f091d65387e90fdf6a3957))
* **core,flutter,web:** [#4126](https://github.com/coco-de/coui/issues/4126) — [#4082](https://github.com/coco-de/coui/issues/4082) 후속 3건 (circle 링 죽은 필드 · badge offset 색 · 슬롯 clobber) ([#4139](https://github.com/coco-de/coui/issues/4139)) ([c9d60b7](https://github.com/coco-de/coui/commit/c9d60b78942e32bc8980e8c2e40e87e772988d67))
* **core,flutter,web:** [#4405](https://github.com/coco-de/coui/issues/4405) — 참조 reverse 캐스트 모션을 양 플랫폼에 구현 ([#4432](https://github.com/coco-de/coui/issues/4432)) ([6bf6cf0](https://github.com/coco-de/coui/commit/6bf6cf0684cd12bf7910dcce31dda7cd9f8d4883))
* **core:** [#4237](https://github.com/coco-de/coui/issues/4237) — 두 엣지 run 이 양 모드에서 다 보인다 ([#4241](https://github.com/coco-de/coui/issues/4241)) ([9460b01](https://github.com/coco-de/coui/commit/9460b01ddfa1f1b3d4cc2c63178cf58aa7423a51))
* **core:** 비활성 라벨을 읽을 수 있게 한다 — disabled-content 는 그래픽 전용 ([#4489](https://github.com/coco-de/coui/issues/4489)) ([b9f19db](https://github.com/coco-de/coui/commit/b9f19db12c5ab9bb8f43ba80c9060dfcdbfc67c0))
* **docs:** Jaspr 0.23.2 최신화 + CI Flutter 3.44.8 상향 + "On this page" 앵커/스타일 수정 ([#3489](https://github.com/coco-de/coui/issues/3489)) ([87ca07b](https://github.com/coco-de/coui/commit/87ca07be932fb8eb09f63cbe0edd8efc26d0747d))
* **drawer:** backdropCornerRadius가 비대칭 override를 유실하던 문제 수정 ([#3262](https://github.com/coco-de/coui/issues/3262)) ([a329148](https://github.com/coco-de/coui/commit/a329148c5aa820216d6942e285c0610b19e1b231))
* **figma,core:** 라벨 행간 120% + Fab 를 메뉴로 + Toast/Chip/Toggle 캔버스 결함 정리 ([2aea28a](https://github.com/coco-de/coui/commit/2aea28a061eb5b7974eba8423731f789aead09dc))
* **flutter,web:** [#3771](https://github.com/coco-de/coui/issues/3771) — Form + Layout/Nav + Display + Overlay/Misc 25개 컴포넌트의 border/radius가 surface-style geometry 축을 안 탐 (Batch 1-5/5) ([#3828](https://github.com/coco-de/coui/issues/3828)) ([18f2df8](https://github.com/coco-de/coui/commit/18f2df82a359ff8fb9ebb9d52025b18a9119e1e2))
* **flutter,web:** [#3825](https://github.com/coco-de/coui/issues/3825) — Scaffold 중첩 시 main 랜드마크를 하나만 낸다 ([#4075](https://github.com/coco-de/coui/issues/4075)) ([571700f](https://github.com/coco-de/coui/commit/571700f7a2418fbee1efaea7a8b65c277e7d0440))
* **flutter,web:** [#3864](https://github.com/coco-de/coui/issues/3864) — 슬라이더 paint 와 input 을 inset 모델로 통일 ([#3865](https://github.com/coco-de/coui/issues/3865)) ([1c2d136](https://github.com/coco-de/coui/commit/1c2d136d19d9e52dbc4ea1125a75b3275d7b714f))
* **flutter,web:** [#3979](https://github.com/coco-de/coui/issues/3979) — a11y 감사 후속 5건 (Scrollbar 접근성 노드·값 축·플랫폼 대칭 + TimePicker 링) ([#3999](https://github.com/coco-de/coui/issues/3999)) ([5a017c9](https://github.com/coco-de/coui/commit/5a017c95449e6883eb287158ff8013023b285431))
* **flutter,web:** 라벨을 한 곳에서만 그린다 — FormField 경로 정상화 + Web TextField 의 FormLabel 합성 ([#4448](https://github.com/coco-de/coui/issues/4448)) ([009de4f](https://github.com/coco-de/coui/commit/009de4f50e9aee79b23074f5eab1f4fd1f9f700f))
* **flutter,web:** 캘린더 헤더가 담기지 못할 때를 말하게, 그리고 그 테스트가 매일 다른 것을 묻지 않게 ([12a0b6f](https://github.com/coco-de/coui/commit/12a0b6fead25284eec590fe62abbee3485163a06))
* **flutter:** [#3718](https://github.com/coco-de/coui/issues/3718) — Command/Kbd border 가 surface-style geometry(strokeFloor)를 안 탐 ([#3719](https://github.com/coco-de/coui/issues/3719)) ([ad5e7fc](https://github.com/coco-de/coui/commit/ad5e7fc5c0d89f877081e37acad67602780e9919))
* **flutter:** hover 채움 아래로 캐스트가 비치지 않는다 ([#4276](https://github.com/coco-de/coui/issues/4276)) ([ff06bc0](https://github.com/coco-de/coui/commit/ff06bc096b931ee6e5418d0fc5536544fbf71bbf))
* **form:** 가려진 필드가 스펠체크·자동수정·IME 학습에 도달하지 않는다 ([#3409](https://github.com/coco-de/coui/issues/3409)) ([51b8a11](https://github.com/coco-de/coui/commit/51b8a115aa6ce97d833acb3a5dd1038ee118e945)), closes [#3385](https://github.com/coco-de/coui/issues/3385)
* **form:** 폼 입력 계약 4건 — 선언만 되고 아무도 안 읽던 필드 배선 ([#4224](https://github.com/coco-de/coui/issues/4224)) ([cb09aa9](https://github.com/coco-de/coui/commit/cb09aa95213ff6598781f63c36b0243bd6342458))
* **layout:** Epic D 4건 — join 포커스 링 · table intrinsic · stepper 앵커 · resizable optionalDivider ([#4255](https://github.com/coco-de/coui/issues/4255)) ([f1ccc24](https://github.com/coco-de/coui/commit/f1ccc249d1487f3545092db7ba01519d1c69647e))
* **menubar:** [#4165](https://github.com/coco-de/coui/issues/4165) — 열린 상태에서 형제 트리거 호버 시 메뉴 전환 ([#4167](https://github.com/coco-de/coui/issues/4167)) ([5049ae7](https://github.com/coco-de/coui/commit/5049ae7ba385dc398f7bbac5c25cd472af791c8c))
* **navigation_menu:** [#4163](https://github.com/coco-de/coui/issues/4163) — 호버 애니메이션 Web/Flutter 파리티 (닫힘 디바운스 + 패널 전환 슬라이드) ([#4168](https://github.com/coco-de/coui/issues/4168)) ([22e257a](https://github.com/coco-de/coui/commit/22e257af8aaf1219646f8c4f58dba6884dcae1c8))
* **navigation_menu:** [#4175](https://github.com/coco-de/coui/issues/4175) — QA 후속 회귀 4건 ([#4177](https://github.com/coco-de/coui/issues/4177)) ([52449d4](https://github.com/coco-de/coui/commit/52449d49c0f95bea4ed5992d2acacef6ba417383))
* **nav:** 선택 상태가 색으로만 구분되던 것에 비-색 신호 추가 ([#3394](https://github.com/coco-de/coui/issues/3394)) ([127b239](https://github.com/coco-de/coui/commit/127b239ccad07b02b802c122a37671e1807b49a7))
* **overlay:** [#3699](https://github.com/coco-de/coui/issues/3699) — Tooltip tooltipChild 기본 가시성 + panelMaxWidth 슬롯 ([#3700](https://github.com/coco-de/coui/issues/3700)) ([f898acb](https://github.com/coco-de/coui/commit/f898acb27cddc8f1151bc6fdd43294dc9e918c99))
* **parity:** [#3644](https://github.com/coco-de/coui/issues/3644) — WebLifecycleProbe 퇴장 관측을 child rebuild로 교정 ([#3668](https://github.com/coco-de/coui/issues/3668)) ([0001685](https://github.com/coco-de/coui/commit/00016853c9321ee6a50c2707a5a3163f81dd945c))
* **parity:** 문서↔코드 · Flutter↔Web 드리프트 실측 수정 + 게이트 4종 ([#3440](https://github.com/coco-de/coui/issues/3440)) ([3953ef5](https://github.com/coco-de/coui/commit/3953ef58f8d3e60ae07a33db9fe2295077ab3992))
* **phone_input:** 입력값을 추측하지 않는다 — 타이핑된 다이얼 코드만 벗긴다 ([#4245](https://github.com/coco-de/coui/issues/4245)) ([8dde2aa](https://github.com/coco-de/coui/commit/8dde2aa7481d89ee009fb1c17ff6bfc47761f086))
* **resizable:** [#4265](https://github.com/coco-de/coui/issues/4265) — optionalDivider 가 드래그 중에도 드러나 있게 한다 ([#4267](https://github.com/coco-de/coui/issues/4267)) ([172b598](https://github.com/coco-de/coui/commit/172b59894261ce4f40f9f3cdfd5ac0de056621f0))
* **surface:** Avatar · MockupWindow · Command 이 스타일의 캐스트를 받는다 ([#4261](https://github.com/coco-de/coui/issues/4261)) ([8c50735](https://github.com/coco-de/coui/commit/8c5073564ec9c74a00c4cbcccd519d1770b385f7))
* **surface:** EmptyState · CodeSnippet · Table 이 스타일의 캐스트를 받는다 ([#4256](https://github.com/coco-de/coui/issues/4256)) ([88270b5](https://github.com/coco-de/coui/commit/88270b5829df4b9ce3874e1b44d30180f86ba18c))
* **surface:** Fieldset · Chip · Kbd 이 스타일의 캐스트를 받는다 ([#4253](https://github.com/coco-de/coui/issues/4253)) ([ee34305](https://github.com/coco-de/coui/commit/ee3430590223539ece7f7996133c36edfc31a306))
* **surface:** 스타일 캐스트가 양 플랫폼에 같게 도달한다 ([#4242](https://github.com/coco-de/coui/issues/4242)) ([b01584f](https://github.com/coco-de/coui/commit/b01584fba7938b050e8bf275a4f90f8e93ffc1ec))
* **surface:** 캐스트가 그리지 않은 박스에서 나오거나, 그린 박스에서 빠지던 5건 ([#4269](https://github.com/coco-de/coui/issues/4269)) ([8c92b6b](https://github.com/coco-de/coui/commit/8c92b6b89a075945301c61cd22bd3058305c7d24))
* **surface:** 폼 컨트롤 5종이 스타일의 캐스트를 받는다 ([#4263](https://github.com/coco-de/coui/issues/4263)) ([9231e42](https://github.com/coco-de/coui/commit/9231e42924fab0e4335506455c25bb38e8079550))
* **surface:** 프레임·바 6종이 스타일의 캐스트를 받는다 ([#4266](https://github.com/coco-de/coui/issues/4266)) ([4d24238](https://github.com/coco-de/coui/commit/4d2423863059ff3cb05a8d33635478eecf541d5f))
* **upstream:** shadcn_flutter 0.0.53 감사 확정 13건 이식 ([#4206](https://github.com/coco-de/coui/issues/4206)) ([b01519b](https://github.com/coco-de/coui/commit/b01519b2ba4fb18673d0cb359320f771bbb7934a))
* **web,docs:** command chain 순열의 색상 크래시·투명 배경 파리티를 고친다 ([#4446](https://github.com/coco-de/coui/issues/4446)) ([f7918b9](https://github.com/coco-de/coui/commit/f7918b9fd8987e1c46417d1df19232aa6ce4cb87))
* **web,flutter:** [#4407](https://github.com/coco-de/coui/issues/4407) — press 전환을 duration 변수 경유로, 상태는 유지 ([#4425](https://github.com/coco-de/coui/issues/4425)) ([af9fd27](https://github.com/coco-de/coui/commit/af9fd2735bba596b936dbb227f6c82b3d73856c2))
* **web:** [#3264](https://github.com/coco-de/coui/issues/3264) — Phase 6 inline px 3건을 design-token 마커로 정당화 ([#3275](https://github.com/coco-de/coui/issues/3275)) ([170ba03](https://github.com/coco-de/coui/commit/170ba035ca2e2a80b5d18a508266718f2092e72f))
* **web:** [#3269](https://github.com/coco-de/coui/issues/3269) — TextField disabled 라벨 recolor 실동작 (resolver-time, Flutter 파리티) ([#3288](https://github.com/coco-de/coui/issues/3288)) ([93b08bf](https://github.com/coco-de/coui/commit/93b08bfa626ed6f96741ffbe234d0eb2f6f023d2))
* **web:** [#3276](https://github.com/coco-de/coui/issues/3276) — border-width rem → px 고정 (47 사이트 + strokeWidthCss + Phase 7 가드) ([#3279](https://github.com/coco-de/coui/issues/3279)) ([262e076](https://github.com/coco-de/coui/commit/262e0765f3456a9e0c4e4115fd68dd7b6a953a09))
* **web:** [#3495](https://github.com/coco-de/coui/issues/3495) — ScrollableClient 뷰포트에 UA 포커스 아웃라인 억제 추가 ([#3976](https://github.com/coco-de/coui/issues/3976)) ([27916dc](https://github.com/coco-de/coui/commit/27916dcf68f949915132802f09357ee931f198b2))
* **web:** [#3704](https://github.com/coco-de/coui/issues/3704) — DotIndicator 의 hover 가 터치 타겟 오버레이에 가려 죽어 있었다 ([#3709](https://github.com/coco-de/coui/issues/3709)) ([dc4475d](https://github.com/coco-de/coui/commit/dc4475d03e5e0f066f14c0db68eeeec108cbb0dc))
* **web:** [#3705](https://github.com/coco-de/coui/issues/3705) — 포인터 타겟 확장이 자기 안쪽을 가리지 않게 ([#3717](https://github.com/coco-de/coui/issues/3717)) ([e511b8e](https://github.com/coco-de/coui/commit/e511b8e9333a76791f3b7d6296496bc61906fa2a))
* **web:** [#3776](https://github.com/coco-de/coui/issues/3776) — theme_config.dart Tailwind screens를 CoreBreakpoint에 배선 ([#3835](https://github.com/coco-de/coui/issues/3835)) ([b3d7b34](https://github.com/coco-de/coui/commit/b3d7b34d703809d4c563749297127da087cefe7c))
* **web:** [#3829](https://github.com/coco-de/coui/issues/3829) — DraggablePanel 이 드래그 스코프가 렌더한 박스에 높이를 잃는다 ([#3830](https://github.com/coco-de/coui/issues/3830)) ([0e622f7](https://github.com/coco-de/coui/commit/0e622f73c3cb03dcbddee8624301b385bd561b4f))
* **web:** [#4312](https://github.com/coco-de/coui/issues/4312) — press 이동이 컨트롤의 위치를 덮지 않게 한다 ([#4313](https://github.com/coco-de/coui/issues/4313)) ([e014328](https://github.com/coco-de/coui/commit/e0143283bf0403acd2ee911f3778c753c19194ed))
* **web:** [#4314](https://github.com/coco-de/coui/issues/4314) — Sortable 이 자기 슬롯 위에서도 포인터를 따라오게 한다 ([#4315](https://github.com/coco-de/coui/issues/4315)) ([5cdde40](https://github.com/coco-de/coui/commit/5cdde40459b4e20762ff92bd38d88b5a21b630fa))
* **web:** [#4403](https://github.com/coco-de/coui/issues/4403) — 캐스트 engage 트리거를 기기 능력으로 가른다 ([#4418](https://github.com/coco-de/coui/issues/4418)) ([8a3cc45](https://github.com/coco-de/coui/commit/8a3cc453243ab930f68023eedcfe0ba36a81b6d0))
* **web:** [#4414](https://github.com/coco-de/coui/issues/4414) — 인라인 box-shadow 에 막힌 Button focus ring 을 !important 로 되살린다 ([#4417](https://github.com/coco-de/coui/issues/4417)) ([3a5b012](https://github.com/coco-de/coui/commit/3a5b0120803c96b0c5c56f749b4c83f0b680ce71))
* **web:** [#4421](https://github.com/coco-de/coui/issues/4421) — 키보드 Space/Enter 활성화에 press 어포던스를 준다 ([#4423](https://github.com/coco-de/coui/issues/4423)) ([d02a213](https://github.com/coco-de/coui/commit/d02a2135378ad1311fe881dd75158e29a7ad58ec))
* **web:** Avatar 이니셜/child 콘텐츠가 OutlinedContainer 합성 후 중앙정렬 안 됨 ([#4586](https://github.com/coco-de/coui/issues/4586)) ([aef05ee](https://github.com/coco-de/coui/commit/aef05ee00937fc582339e5bc12356686004efa70))
* **web:** neo-brutalism strokeFloor not reaching Web stroke/line-width emits ([#3809](https://github.com/coco-de/coui/issues/3809)) ([675779b](https://github.com/coco-de/coui/commit/675779b63bfafbd13380c687ff19861812801000))
* **web:** neoBrutalism press 그림자가 박스와 같이 미끄러지는 cascade 충돌을 고친다 ([#4491](https://github.com/coco-de/coui/issues/4491)) ([2bba1c8](https://github.com/coco-de/coui/commit/2bba1c82797aa2800d7eca905c1d215e3d8ecace))
* **web:** pseudo-state 색 raw override 크래시 해소 — class XOR scoped &lt;style&gt; emit ([#3265](https://github.com/coco-de/coui/issues/3265)) ([87d94ef](https://github.com/coco-de/coui/commit/87d94efe6fec2fc0385ef7dba7117275d4c358d9))
* **web:** radius 19계단 전부가 변수로 나간다 — 두 목록을 하나로 합친다 ([#4297](https://github.com/coco-de/coui/issues/4297)) ([c500688](https://github.com/coco-de/coui/commit/c500688e6991dc8a7f1acaaa10090350c3ac53f9)), closes [#4296](https://github.com/coco-de/coui/issues/4296)
* **web:** Text 체인 role 클래스로 emit — neoBrutalism weightFloor 반영 ([#4450](https://github.com/coco-de/coui/issues/4450)) ([1dec5f1](https://github.com/coco-de/coui/commit/1dec5f178c895b0ffd521a527f82ef0704256b01)), closes [#4449](https://github.com/coco-de/coui/issues/4449)
* **web:** 고대비가 장식 프리셋에 지던 순서를 특이도로 뒤집음 ([#3373](https://github.com/coco-de/coui/issues/3373)) ([41c534a](https://github.com/coco-de/coui/commit/41c534a85ab7f1bac6eb12da8d4efed574882deb))
* **web:** 그림자로만 경계를 그리는 프리셋에 forced-colors 경계를 실제로 그림 ([#3369](https://github.com/coco-de/coui/issues/3369)) ([3c5fc9d](https://github.com/coco-de/coui/commit/3c5fc9d91f8ceda619dd9f144e6b165e2301a824))
* **web:** 채움 없는 버튼이 비켜준 적 없는 자리로 들어가지 않게 한다 ([#4318](https://github.com/coco-de/coui/issues/4318)) ([7c2c95c](https://github.com/coco-de/coui/commit/7c2c95cb34da624f38ea861abbaba262adb52df5))
* **web:** 캐스트가 hoverable 카드에도 도달한다 ([#4244](https://github.com/coco-de/coui/issues/4244)) ([5d2501b](https://github.com/coco-de/coui/commit/5d2501bb3b7e399952b537ae9239f0c53ca76029))


### 리팩터링

* **group:** deprecate Group — duplicates Stacks + Position ([#4094](https://github.com/coco-de/coui/issues/4094)) ([de4f177](https://github.com/coco-de/coui/commit/de4f177a2328688d291d28ac454d2ac28dccb53e))
* **web:** [#3285](https://github.com/coco-de/coui/issues/3285) — check_web_resolver 가드 green (Flutter 가드 미러 + 진짜 위반 실해소) ([#3287](https://github.com/coco-de/coui/issues/3287)) ([7884fc0](https://github.com/coco-de/coui/commit/7884fc0f616afd1607ad9a90f86b14a39e07206b))
* **web:** [#3848](https://github.com/coco-de/coui/issues/3848) — Sortable 의 픽셀에 닿지 않는 선언 정리 ([#3849](https://github.com/coco-de/coui/issues/3849)) ([2b05851](https://github.com/coco-de/coui/commit/2b05851c1340e4ff8a6e15d63ccc009372c19c2b))


### 문서

* **rules:** [#3319](https://github.com/coco-de/coui/issues/3319) — 폼 밖 에러 표면 결정 + 톤별 통보 방식 ([#3425](https://github.com/coco-de/coui/issues/3425)) ([af73647](https://github.com/coco-de/coui/commit/af73647171e825ae2d9362491fc0acc63404032d))


### 기타

* **deps:** [#4439](https://github.com/coco-de/coui/issues/4439) — Flutter 3.47.0 · jaspr 0.23.4 로 툴체인 상향 ([#4440](https://github.com/coco-de/coui/issues/4440)) ([a033bed](https://github.com/coco-de/coui/commit/a033beda885234867322886211f342e03e93ea41))

## [0.132.0](https://github.com/coco-de/coui/compare/coui_web-v0.131.0...coui_web-v0.132.0) (2026-09-02)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** `CoreFilterItem<T>` 가 `CoreFilterItem<T, W>` 가 된다 — 명시 제네릭으로 쓰던 코드는 `<T, Widget>` / `<T, Component>` 로 바꾼다(추론으로 만드는 호출은 그대로). `CoreFilterStyle.defaultItemPadding` 이 h16/v8 에서 8 사방으로, 세그먼트 높이가 32 고정으로, reset 이 plain·md 에서 ghost·sm·square 로 바뀌어 Filter 의 렌더가 달라진다.

### 기능

* **core,flutter,web,figma:** Filter 세그먼트가 아이콘을 갖고 정사각으로 접힌다 — 디자이너의 세그먼트 프로퍼티를 흡수한다 ([#4628](https://github.com/coco-de/coui/issues/4628)) ([bc544e4](https://github.com/coco-de/coui/commit/bc544e431e99add953277472193e60cd90a5a3af))

## [0.131.0](https://github.com/coco-de/coui/compare/coui_web-v0.130.0...coui_web-v0.131.0) (2026-09-02)


### ⚠ BREAKING CHANGES

* `CoreBadgeContract.child` 가 `W` 에서 `W?` 로 바뀌고 `CoreBadgeContract.form` getter 가 새로 생긴다. 이 계약을 직접 `implements` 하는 코드는 두 멤버를 갱신해야 한다. Flutter/Web `Badge` 위젯 사용처는 영향이 없다 — `child` 는 더 관대해진 방향이고 `form` 은 `CoreBadgeForm.count` 기본값을 갖는다.
* **core,flutter,web,figma:** AppBar 의 withStyle patch 타입이 CoreScaffoldStyle 에서 CoreAppBarStyle 로 바뀌고, ResolvedScaffold 에서 headerPadding/headerSpacing/ headerActionSpacing 이 빠진다(소비 위젯 0). scaffoldStyle 파라미터는 deprecated 매핑으로 동작을 유지한다.

### 기능

* Badge 가 점을 그릴 수 있게 된다 — 캔버스의 Style 축을 흡수 ([#4606](https://github.com/coco-de/coui/issues/4606)) ([e454861](https://github.com/coco-de/coui/commit/e4548610f49ef6f7b41cdb6c591fab5a9eb3e5d8))
* **core,flutter,web,figma:** AppBar 가 디자이너 세트를 스펙으로 얻는다 — 계약 신설 · 양 플랫폼 이동 · 빌더 등록 ([7c154ba](https://github.com/coco-de/coui/commit/7c154ba1f85c8b74747ad2c7398112c4d8dc0e44))
* **core:** display 역할이 regular(400) 로 — light 는 대형 제목에서 획이 사라진다 ([#4617](https://github.com/coco-de/coui/issues/4617)) ([d35041b](https://github.com/coco-de/coui/commit/d35041b0f65e55c086d425abb536ecd71bccb634))
* **flutter,web,figma:** TextField suffix 에 글자가 들어간다 — 코드가 먼저 타이포를 말하고, 캔버스가 슬롯을 얻는다 ([#4611](https://github.com/coco-de/coui/issues/4611)) ([d636914](https://github.com/coco-de/coui/commit/d6369146e4a8371df5987b5ab2b87a3c81ceda19))


### 버그 수정

* **core,flutter,web,figma:** Toast 액션이 슬랩 위에서 읽힌다 — 2.1:1 과 1.0:1 을 고친다 ([#4610](https://github.com/coco-de/coui/issues/4610)) ([73b93fe](https://github.com/coco-de/coui/commit/73b93fe582a6966c2a5b48a7be00dc7bea2c6fff))
* **figma,core:** 라벨 행간 120% + Fab 를 메뉴로 + Toast/Chip/Toggle 캔버스 결함 정리 ([2aea28a](https://github.com/coco-de/coui/commit/2aea28a061eb5b7974eba8423731f789aead09dc))
* **flutter,web:** 캘린더 헤더가 담기지 못할 때를 말하게, 그리고 그 테스트가 매일 다른 것을 묻지 않게 ([12a0b6f](https://github.com/coco-de/coui/commit/12a0b6fead25284eec590fe62abbee3485163a06))

## [0.130.0](https://github.com/coco-de/coui/compare/coui_web-v0.129.0...coui_web-v0.130.0) (2026-08-31)


### ⚠ BREAKING CHANGES

* **core:** 
* **core:** 플레이스홀더가 자기 색 슬롯을 갖는다 ([#4477](https://github.com/coco-de/coui/issues/4477))
* **deps:** #4439 — Flutter 3.47.0 · jaspr 0.23.4 로 툴체인 상향 ([#4440](https://github.com/coco-de/coui/issues/4440))
* **core:** ResolvedColorScheme 생성자에 primaryText· primaryTextLarge 필수 파라미터가 추가된다. CoreColorScheme 를 직접 구현/생성하는 소비자는 두 슬롯을 채워야 한다.

### 기능

* **core,flutter,web,docs:** [#4413](https://github.com/coco-de/coui/issues/4413) — 브라우저가 여는 Disclosure ([#4415](https://github.com/coco-de/coui/issues/4415)) ([e5ded92](https://github.com/coco-de/coui/commit/e5ded921fb3e6924d6fa1b1e4c4f0c09a4bfa9d0))
* **core,flutter,web,figma:** [#4544](https://github.com/coco-de/coui/issues/4544) — ValidatorHint 에 neutral 을 더한다 ([#4545](https://github.com/coco-de/coui/issues/4545)) ([9a41de0](https://github.com/coco-de/coui/commit/9a41de07e69bdb99d5d69094c651db4d0c865518))
* **core,flutter,web,figma:** FormField 에 labelAction · counterText 를 더한다 ([#4548](https://github.com/coco-de/coui/issues/4548)) ([be90fce](https://github.com/coco-de/coui/commit/be90fce189afb1772a1a25ba09c8c21e26e41c22))
* **core,flutter,web,figma:** NavigationBar 디자이너 편집 + NavigationBarItem 반영 ([#4444](https://github.com/coco-de/coui/issues/4444)) ([41483ae](https://github.com/coco-de/coui/commit/41483ae5eb0ff5f9cda1f8c34eaab15ba5e7c1c2))
* **core,flutter,web:** [#4351](https://github.com/coco-de/coui/issues/4351) — 마커가 자기 역할을 나른다 ([#4376](https://github.com/coco-de/coui/issues/4376)) ([e2670a9](https://github.com/coco-de/coui/commit/e2670a97b8440e002e2a8c2fb63923414a0698f3))
* **core,flutter,web:** [#4352](https://github.com/coco-de/coui/issues/4352) — 중첩 정책을 축으로 올려 두 플랫폼을 맞춘다 ([#4377](https://github.com/coco-de/coui/issues/4377)) ([a872768](https://github.com/coco-de/coui/commit/a872768f983372980bab5225cd942fc7eac271e3))
* **core,flutter,web:** Chip 에 emphasis 축을 추가한다 — 조용한 레지스터 ([#4488](https://github.com/coco-de/coui/issues/4488)) ([e55dbf4](https://github.com/coco-de/coui/commit/e55dbf43a6946d8b2fefa4fe8d81ad9a6506caf5))
* **core:** [#4402](https://github.com/coco-de/coui/issues/4402) — 캐스트가 engage 될 때 무엇을 할지 컨트롤이 말하게 한다 ([#4412](https://github.com/coco-de/coui/issues/4412)) ([e22b207](https://github.com/coco-de/coui/commit/e22b207e46bd293c53327e3758c15c9ab701de66))
* **core:** [#4509](https://github.com/coco-de/coui/issues/4509) — Chip 이 상태 레이어를 그린다 (hover · focus · pressed) ([#4522](https://github.com/coco-de/coui/issues/4522)) ([f7fe6e5](https://github.com/coco-de/coui/commit/f7fe6e598434fdd8d30da147313622a00da81ccb))
* **core:** [#4509](https://github.com/coco-de/coui/issues/4509) — NavigationBarItem 이 상태 레이어를 그린다, 그리고 다크의 구멍을 메운다 ([#4517](https://github.com/coco-de/coui/issues/4517)) ([8e29e56](https://github.com/coco-de/coui/commit/8e29e56846eaca5d19dc152056a3390eec5a6a70))
* **core:** [#4509](https://github.com/coco-de/coui/issues/4509) — TextField 가 상태 레이어를 그린다 (hover · focus · pressed) ([#4516](https://github.com/coco-de/coui/issues/4516)) ([f060cea](https://github.com/coco-de/coui/commit/f060cea10768ed3841e457bffcd4dce0b5a17a0f))
* **core:** [#4523](https://github.com/coco-de/coui/issues/4523) — Checkbox 라벨이 사이즈 축을 타고, description·trailing 슬롯이 생긴다 ([#4524](https://github.com/coco-de/coui/issues/4524)) ([8bfadf5](https://github.com/coco-de/coui/commit/8bfadf593939a8729234cc71547f2c3f3aae05e8))
* **core:** Banner emphasis 축 · Alert 재설계 · Button 상태 레이어와 포커스 링 ([#4505](https://github.com/coco-de/coui/issues/4505)) ([636cda0](https://github.com/coco-de/coui/commit/636cda075bebb9769127d9a04f0565b62ea256cf))
* **core:** label role 이 body 보다 무거워지고, 계열이 사다리 끝까지 이어진다 ([#4556](https://github.com/coco-de/coui/issues/4556)) ([3629255](https://github.com/coco-de/coui/commit/3629255985a679086c3a100741a3002bb082ded1))
* **core:** 브랜드가 시맨틱 매핑을 소유한다 — Figma 토큰 편집 역동기화 ([#4434](https://github.com/coco-de/coui/issues/4434)) ([96ba6e9](https://github.com/coco-de/coui/commit/96ba6e976d19765d3d09966daabaa4422c09cabb))
* **core:** 플레이스홀더가 자기 색 슬롯을 갖는다 ([#4477](https://github.com/coco-de/coui/issues/4477)) ([a24b142](https://github.com/coco-de/coui/commit/a24b1423e276ab88a05ea010a908e1ed6a4b4b09))


### 버그 수정

* **command:** 헤더 안 Command 팔레트가 뷰포트 전체를 못 쓰던 문제 수정 ([#4378](https://github.com/coco-de/coui/issues/4378)) ([f67053c](https://github.com/coco-de/coui/commit/f67053cbc7aae57a760985df34fd51de6d97738f))
* **core,flutter,web:** [#4405](https://github.com/coco-de/coui/issues/4405) — 참조 reverse 캐스트 모션을 양 플랫폼에 구현 ([#4432](https://github.com/coco-de/coui/issues/4432)) ([6bf6cf0](https://github.com/coco-de/coui/commit/6bf6cf0684cd12bf7910dcce31dda7cd9f8d4883))
* **core:** 비활성 라벨을 읽을 수 있게 한다 — disabled-content 는 그래픽 전용 ([#4489](https://github.com/coco-de/coui/issues/4489)) ([b9f19db](https://github.com/coco-de/coui/commit/b9f19db12c5ab9bb8f43ba80c9060dfcdbfc67c0))
* **flutter,web:** 라벨을 한 곳에서만 그린다 — FormField 경로 정상화 + Web TextField 의 FormLabel 합성 ([#4448](https://github.com/coco-de/coui/issues/4448)) ([009de4f](https://github.com/coco-de/coui/commit/009de4f50e9aee79b23074f5eab1f4fd1f9f700f))
* **web,docs:** command chain 순열의 색상 크래시·투명 배경 파리티를 고친다 ([#4446](https://github.com/coco-de/coui/issues/4446)) ([f7918b9](https://github.com/coco-de/coui/commit/f7918b9fd8987e1c46417d1df19232aa6ce4cb87))
* **web,flutter:** [#4407](https://github.com/coco-de/coui/issues/4407) — press 전환을 duration 변수 경유로, 상태는 유지 ([#4425](https://github.com/coco-de/coui/issues/4425)) ([af9fd27](https://github.com/coco-de/coui/commit/af9fd2735bba596b936dbb227f6c82b3d73856c2))
* **web:** [#4403](https://github.com/coco-de/coui/issues/4403) — 캐스트 engage 트리거를 기기 능력으로 가른다 ([#4418](https://github.com/coco-de/coui/issues/4418)) ([8a3cc45](https://github.com/coco-de/coui/commit/8a3cc453243ab930f68023eedcfe0ba36a81b6d0))
* **web:** [#4414](https://github.com/coco-de/coui/issues/4414) — 인라인 box-shadow 에 막힌 Button focus ring 을 !important 로 되살린다 ([#4417](https://github.com/coco-de/coui/issues/4417)) ([3a5b012](https://github.com/coco-de/coui/commit/3a5b0120803c96b0c5c56f749b4c83f0b680ce71))
* **web:** [#4421](https://github.com/coco-de/coui/issues/4421) — 키보드 Space/Enter 활성화에 press 어포던스를 준다 ([#4423](https://github.com/coco-de/coui/issues/4423)) ([d02a213](https://github.com/coco-de/coui/commit/d02a2135378ad1311fe881dd75158e29a7ad58ec))
* **web:** Avatar 이니셜/child 콘텐츠가 OutlinedContainer 합성 후 중앙정렬 안 됨 ([#4586](https://github.com/coco-de/coui/issues/4586)) ([aef05ee](https://github.com/coco-de/coui/commit/aef05ee00937fc582339e5bc12356686004efa70))
* **web:** neoBrutalism press 그림자가 박스와 같이 미끄러지는 cascade 충돌을 고친다 ([#4491](https://github.com/coco-de/coui/issues/4491)) ([2bba1c8](https://github.com/coco-de/coui/commit/2bba1c82797aa2800d7eca905c1d215e3d8ecace))
* **web:** Text 체인 role 클래스로 emit — neoBrutalism weightFloor 반영 ([#4450](https://github.com/coco-de/coui/issues/4450)) ([1dec5f1](https://github.com/coco-de/coui/commit/1dec5f178c895b0ffd521a527f82ef0704256b01)), closes [#4449](https://github.com/coco-de/coui/issues/4449)


### 기타

* **deps:** [#4439](https://github.com/coco-de/coui/issues/4439) — Flutter 3.47.0 · jaspr 0.23.4 로 툴체인 상향 ([#4440](https://github.com/coco-de/coui/issues/4440)) ([a033bed](https://github.com/coco-de/coui/commit/a033beda885234867322886211f342e03e93ea41))

## [0.129.0](https://github.com/coco-de/coui/compare/coui_web-v0.128.0...coui_web-v0.129.0) (2026-08-18)


### ⚠ BREAKING CHANGES

* **surface:** #4217 — 유리 오버레이가 자기 트리거에서 자라난다 ([#4302](https://github.com/coco-de/coui/issues/4302))

### 기능

* **coui:** DefinitionList · DisclosureBadge 신설 ([#4260](https://github.com/coco-de/coui/issues/4260)) ([ae07784](https://github.com/coco-de/coui/commit/ae07784601d55b23b6de805b3744a0a080001719))
* **figma:** 브랜드 축 — 브랜드별 Semantic/Color 컬렉션 + 리바인딩 플러그인 커맨드 ([#4290](https://github.com/coco-de/coui/issues/4290)) ([ff0d254](https://github.com/coco-de/coui/commit/ff0d2540cf92a8a06272367dfdec3e0577dc9a72))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 두 플랫폼이 같은 실루엣을 각자 스펠링한다 ([#4299](https://github.com/coco-de/coui/issues/4299)) ([e137e70](https://github.com/coco-de/coui/commit/e137e709c81e181d1f3af03a6b61a94058e5f8e8))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 모프 클립을 양 플랫폼에 세운다 ([#4300](https://github.com/coco-de/coui/issues/4300)) ([9c39a2b](https://github.com/coco-de/coui/commit/9c39a2b65b63b6e6d00b5283fe656366685c4d61))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 유리 오버레이가 자기 트리거에서 자라난다 ([#4302](https://github.com/coco-de/coui/issues/4302)) ([57e1e0f](https://github.com/coco-de/coui/commit/57e1e0f3c25194608fa541c597e329f0684674a4))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 유리 표면의 경계는 재질이 그린다 ([#4284](https://github.com/coco-de/coui/issues/4284)) ([9edf08e](https://github.com/coco-de/coui/commit/9edf08e93243224043b6a8153edfe8196d45e2b9))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 유리가 유리처럼 보일 만큼 재질을 올린다 ([#4306](https://github.com/coco-de/coui/issues/4306)) ([fa604e5](https://github.com/coco-de/coui/commit/fa604e567b29779c6f7bf9542c24fc774879c060))
* **surface:** [#4323](https://github.com/coco-de/coui/issues/4323) — 어느 컴포넌트가 표면인지 목록이 아니라 규칙이 답한다 ([#4332](https://github.com/coco-de/coui/issues/4332)) ([729469c](https://github.com/coco-de/coui/commit/729469cf75bb7260fc00fd3205bac80a4a1b4fbd))
* **surface:** [#4325](https://github.com/coco-de/coui/issues/4325) — 떠 있는 패널 넷이 재질을 받는다 (flutter 8→12 · web 9→13) ([#4335](https://github.com/coco-de/coui/issues/4335)) ([ac46cf1](https://github.com/coco-de/coui/commit/ac46cf1a97211d313398044a20e00e39ae7870c2))
* **surface:** [#4326](https://github.com/coco-de/coui/issues/4326) — 컨테이너 크롬 둘이 재질을 받고, 다섯은 근거와 함께 받지 않는다 ([#4337](https://github.com/coco-de/coui/issues/4337)) ([96a286d](https://github.com/coco-de/coui/commit/96a286d94f1b1a7e05c37b8f956a57f84268049b))
* **surface:** [#4327](https://github.com/coco-de/coui/issues/4327) — 카탈로그 감사가 재질도 본다, 그리고 중첩 유리를 찾았다 ([#4338](https://github.com/coco-de/coui/issues/4338)) ([b2f3ebb](https://github.com/coco-de/coui/commit/b2f3ebb1150bafa064d1e119a33a5fd436906c7d))
* **surface:** [#4329](https://github.com/coco-de/coui/issues/4329) — 투명도 줄이기 폴백을 Flutter 에서도 켤 수 있게 한다 ([#4341](https://github.com/coco-de/coui/issues/4341)) ([5bff601](https://github.com/coco-de/coui/commit/5bff601e25cce6793ad51c724fc0e7681ecc1661))
* **surface:** [#4369](https://github.com/coco-de/coui/issues/4369) — 바닥값이 못 올리는 0 에, 스타일이 경계를 직접 기여한다 ([#4370](https://github.com/coco-de/coui/issues/4370)) ([ab9694b](https://github.com/coco-de/coui/commit/ab9694bd8512e646939b21435f4109a0752aed20))
* **web,core:** [#4217](https://github.com/coco-de/coui/issues/4217) — 투명도 줄이기 요청에 유리가 답한다 (G5) ([#4305](https://github.com/coco-de/coui/issues/4305)) ([1f40f64](https://github.com/coco-de/coui/commit/1f40f6400f9ce3429281a90d4932b08175d1b15d))


### 버그 수정

* **chip:** [#4289](https://github.com/coco-de/coui/issues/4289) · [#4294](https://github.com/coco-de/coui/issues/4294) 를 main 으로 다시 올린다 (스택 베이스로 머지돼 도달 못 함) ([#4298](https://github.com/coco-de/coui/issues/4298)) ([c3794d6](https://github.com/coco-de/coui/commit/c3794d6c2d08d1f54b436a0414ed7a487e5d22db)), closes [#4293](https://github.com/coco-de/coui/issues/4293)
* **web:** [#4312](https://github.com/coco-de/coui/issues/4312) — press 이동이 컨트롤의 위치를 덮지 않게 한다 ([#4313](https://github.com/coco-de/coui/issues/4313)) ([e014328](https://github.com/coco-de/coui/commit/e0143283bf0403acd2ee911f3778c753c19194ed))
* **web:** [#4314](https://github.com/coco-de/coui/issues/4314) — Sortable 이 자기 슬롯 위에서도 포인터를 따라오게 한다 ([#4315](https://github.com/coco-de/coui/issues/4315)) ([5cdde40](https://github.com/coco-de/coui/commit/5cdde40459b4e20762ff92bd38d88b5a21b630fa))
* **web:** radius 19계단 전부가 변수로 나간다 — 두 목록을 하나로 합친다 ([#4297](https://github.com/coco-de/coui/issues/4297)) ([c500688](https://github.com/coco-de/coui/commit/c500688e6991dc8a7f1acaaa10090350c3ac53f9)), closes [#4296](https://github.com/coco-de/coui/issues/4296)
* **web:** 채움 없는 버튼이 비켜준 적 없는 자리로 들어가지 않게 한다 ([#4318](https://github.com/coco-de/coui/issues/4318)) ([7c2c95c](https://github.com/coco-de/coui/commit/7c2c95cb34da624f38ea861abbaba262adb52df5))

## [0.128.0](https://github.com/coco-de/coui/compare/coui_web-v0.127.17...coui_web-v0.128.0) (2026-08-12)


### ⚠ BREAKING CHANGES

* **surface:** Text 체인의 accent fill getter 6종이 Web 에서 제거되고 Flutter 에서 deprecated 됐다. `.on{Role}Container` 로 교체한다.
* **core,flutter,web:** #4082 — #4001 후속 4건 (resizable 정규화 · focus-ring 슬롯/합성 3건) ([#4121](https://github.com/coco-de/coui/issues/4121))
* **flutter,web:** #3979 — a11y 감사 후속 5건 (Scrollbar 접근성 노드·값 축·플랫폼 대칭 + TimePicker 링) ([#3999](https://github.com/coco-de/coui/issues/3999))

### 기능

* **a11y:** [#3391](https://github.com/coco-de/coui/issues/3391) — nav 패밀리 role seat + Flutter expanded 배선 ([#3424](https://github.com/coco-de/coui/issues/3424)) ([c81ef74](https://github.com/coco-de/coui/commit/c81ef74cef84ab48cb75460a851d11f279e18de0))
* **a11y:** [#3426](https://github.com/coco-de/coui/issues/3426) — EmptyState 에 톤 축 (실패인 빈 상태 vs 그냥 빈 상태) ([#3431](https://github.com/coco-de/coui/issues/3431)) ([915fbb2](https://github.com/coco-de/coui/commit/915fbb2cc2a2145934a260496662e6019bbb14c7))
* **a11y:** 포인터 타겟 하한 — 그리는 크기가 아니라 닿는 범위를 넓힌다 ([#3410](https://github.com/coco-de/coui/issues/3410)) ([def5370](https://github.com/coco-de/coui/commit/def5370fd4753d95e5169a32ab47819cbb818c60))
* **autocomplete:** [#4189](https://github.com/coco-de/coui/issues/4189) — 키보드로 제안에 도달할 수 있게 한다 ([#4225](https://github.com/coco-de/coui/issues/4225)) ([188ac60](https://github.com/coco-de/coui/commit/188ac60d56c18139b796f3aaf63158f403f1bda3))
* **core,flutter,web,figma:** Size 3계층 토큰 시스템 + Figma 7컬렉션 라이브 파일 완전 정렬 ([#4214](https://github.com/coco-de/coui/issues/4214)) ([d911b53](https://github.com/coco-de/coui/commit/d911b53524945ddb3386187a8fd60176efdd1f0a))
* **core,flutter,web:** [#3763](https://github.com/coco-de/coui/issues/3763) — Core↔docs 정합 잔여 트랙 완료 (Epic K 치수표 확정 + Track B 정리) ([#3916](https://github.com/coco-de/coui/issues/3916)) ([00070c9](https://github.com/coco-de/coui/commit/00070c9c45ae22064fadbac4b4df2ac59228bc65))
* **core,flutter,web:** [#4218](https://github.com/coco-de/coui/issues/4218) — 채도와 엣지 시인이 양 플랫폼 픽셀에 도달한다 ([#4230](https://github.com/coco-de/coui/issues/4230)) ([0266bc2](https://github.com/coco-de/coui/commit/0266bc219a86ee0035bafedf94d9be90209b3bf6))
* **core:** [#2870](https://github.com/coco-de/coui/issues/2870) — 표면 하이라이트 팔레트 슬롯 + clay inset rim ([#3405](https://github.com/coco-de/coui/issues/3405)) ([8c00ec5](https://github.com/coco-de/coui/commit/8c00ec540ce2e01a98872fd0efaae7392213e6cd))
* **core:** [#3345](https://github.com/coco-de/coui/issues/3345) — 서피스 기하 재지정 (radius + stroke) ([#3354](https://github.com/coco-de/coui/issues/3354)) ([5613f56](https://github.com/coco-de/coui/commit/5613f5687c0e209b1503c0fd3659db309978cc05))
* **core:** [#3351](https://github.com/coco-de/coui/issues/3351) — 그림자 기하 재지정 + neo-brutalism 서명 그림자 ([#3358](https://github.com/coco-de/coui/issues/3358)) ([ed792fc](https://github.com/coco-de/coui/commit/ed792fc1085a0058d699956797a718b67c23679c))
* **core:** [#3352](https://github.com/coco-de/coui/issues/3352) — 프리셋 경계 색 재지정 (outlineEmphasis) ([#3355](https://github.com/coco-de/coui/issues/3355)) ([4108ee0](https://github.com/coco-de/coui/commit/4108ee0f3df7a633641ed187446f172779967c9d))
* **core:** [#3356](https://github.com/coco-de/coui/issues/3356) — 프리셋 typography weight 축 (neo-brutalism 레시피 완성) ([#3359](https://github.com/coco-de/coui/issues/3359)) ([0b98ac0](https://github.com/coco-de/coui/commit/0b98ac0038c01cd2214cd669877c9bc92b6fb7ad))
* **core:** [#4219](https://github.com/coco-de/coui/issues/4219) — 앱이 글래스 재질을 정한다 (CoreSurfaceTuning) ([#4254](https://github.com/coco-de/coui/issues/4254)) ([c20829f](https://github.com/coco-de/coui/commit/c20829fb5c9628a9d75a7c4352450c7cb2bc03d2))
* **core:** 눌림 chrome 축 — 이동과 그림자 ([#3399](https://github.com/coco-de/coui/issues/3399)) ([6821dd1](https://github.com/coco-de/coui/commit/6821dd1000b6a3b28a8b9f3079958aec4d1020a9))
* **core:** 시맨틱 role seat — Core 가 들고 있던 raw ARIA 문자열 제거 ([#3403](https://github.com/coco-de/coui/issues/3403)) ([766360a](https://github.com/coco-de/coui/commit/766360a38dcc32b8163b8ec7cd3f57462d79777a))
* **cross-platform:** [#4186](https://github.com/coco-de/coui/issues/4186) — 잔여 3건 (divider childAlignment · 피드백 전역 opt-out · Web 버튼 chrome 전환) ([#4257](https://github.com/coco-de/coui/issues/4257)) ([ed2b409](https://github.com/coco-de/coui/commit/ed2b409f58b92cdcca3c941497bf78aa436942c7)), closes [#4200](https://github.com/coco-de/coui/issues/4200) [#4201](https://github.com/coco-de/coui/issues/4201) [#4202](https://github.com/coco-de/coui/issues/4202)
* FormattedInput 단일 필드 마스크 재설계 — 백스페이스 연속성 · 커스텀 마스크 · 자동완성 ([#3866](https://github.com/coco-de/coui/issues/3866)) ([#3900](https://github.com/coco-de/coui/issues/3900)) ([68e8513](https://github.com/coco-de/coui/commit/68e8513867da78c58b3421791e32b759e651cb39))
* **i18n:** [#3429](https://github.com/coco-de/coui/issues/3429) — 논리 방향 inset (가로 비대칭 4건 전부) ([#3438](https://github.com/coco-de/coui/issues/3438)) ([ee951e4](https://github.com/coco-de/coui/commit/ee951e419b99d5356ebc3882c866155f8c7dd205))
* **icon:** 아이콘 크기 사다리 — 실제 결함은 네임스페이스 반전이었다 ([#3420](https://github.com/coco-de/coui/issues/3420)) ([625baa4](https://github.com/coco-de/coui/commit/625baa49cca467a0cfeec898285f8f4dd1a5cdee))
* **icon:** 출하 컴포넌트를 Lucide 하나로 — 그리고 글리프 정체에 걸린 동작 분리 ([#3419](https://github.com/coco-de/coui/issues/3419)) ([63d7df1](https://github.com/coco-de/coui/commit/63d7df13a73780df19fcb52670649ff02f874149))
* neo-brutalism 대각선 그림자·press-squash(Button/Fab) + card_image OutlinedContainer 합성 ([#4178](https://github.com/coco-de/coui/issues/4178)) ([78d74e6](https://github.com/coco-de/coui/commit/78d74e6e610babf82c78719b16b227db01dc8de9))
* **phone_input:** 전화번호 완전성 validator — Form 이 "완전한 번호" 를 말할 수단 ([#4243](https://github.com/coco-de/coui/issues/4243)) ([a36fe90](https://github.com/coco-de/coui/commit/a36fe90f6f8970b68f4edc92e6f1e1683c744fb9))
* Project [#3294](https://github.com/coco-de/coui/issues/3294) — 디자인 시스템 견고화 (접근성 축 10건 + 서피스 프리셋 축 4건) ([#3349](https://github.com/coco-de/coui/issues/3349)) ([5b6287d](https://github.com/coco-de/coui/commit/5b6287d1c48b73eb208b3838bd94effb9d9b1711))
* **state:** [#3318](https://github.com/coco-de/coui/issues/3318) — 로딩 슬롯 판정: 필요한 컴포넌트가 없다 ([#3439](https://github.com/coco-de/coui/issues/3439)) ([3ec5ec7](https://github.com/coco-de/coui/commit/3ec5ec7425d2ac1c8501b15e5afbd39342d07d99))
* **surface:** [#4208](https://github.com/coco-de/coui/issues/4208) — 앱이 서페이스 프리셋을 자기 값으로 튜닝한다 ([#4240](https://github.com/coco-de/coui/issues/4240)) ([44093f7](https://github.com/coco-de/coui/commit/44093f75698976755992e85af17e642260ce4794))
* **surface:** [#4222](https://github.com/coco-de/coui/issues/4222) — 굴절은 축이 아니라 표면이 여는 역량이다 ([#4270](https://github.com/coco-de/coui/issues/4270)) ([f3bf226](https://github.com/coco-de/coui/commit/f3bf226879382ecb1e064dcffbc22cdd80488c48))
* **theme:** [#2865](https://github.com/coco-de/coui/issues/2865) — Neo-brutalism 프리셋 (첫 E2E) + docs 스타일 스위처 ([#3357](https://github.com/coco-de/coui/issues/3357)) ([40d6999](https://github.com/coco-de/coui/commit/40d69999eac9210c1050a71e9394c7f30d7e31b6))
* **theme:** [#3183](https://github.com/coco-de/coui/issues/3183) — 내비 표면이 재질을 받고, 떠 있을 수 있다 ([#3436](https://github.com/coco-de/coui/issues/3436)) ([7ae43c4](https://github.com/coco-de/coui/commit/7ae43c42ba4ebdc5e0dc66011627ef29fb5b4e1d))
* **theme:** 그림자 미러 축 — 배율로는 두 번째 방향을 만들 수 없다 ([#3414](https://github.com/coco-de/coui/issues/3414)) ([8691726](https://github.com/coco-de/coui/commit/86917267025647d0d210208a87046e195f4f0874))
* **theme:** 남은 프리셋 3종 (Glass · Neumorphism · Claymorphism) + orphan surface 필드 배선 ([#3362](https://github.com/coco-de/coui/issues/3362)) ([536bafc](https://github.com/coco-de/coui/commit/536bafceb1be2faf85fdda7e8aae755e559e3e98))
* **theme:** 표면 스타일이 반경 범위를 진술 — 사다리 위 재배치 ([#3407](https://github.com/coco-de/coui/issues/3407)) ([9c39d49](https://github.com/coco-de/coui/commit/9c39d490fb70f613d034ff39423e725cdddaace3))
* **web:** [#3318](https://github.com/coco-de/coui/issues/3318) 선행 — 스켈레톤 표준 확정 + 정직하지 않은 클래스 삭제 ([#3437](https://github.com/coco-de/coui/issues/3437)) ([ebb1f67](https://github.com/coco-de/coui/commit/ebb1f676f8f3ef3eafeaa739b57d8f1f1fa3c575))
* **web:** [#3434](https://github.com/coco-de/coui/issues/3434) — glass 표면 처리에 Web transport (프리셋이 실제로 유리가 된다) ([#3435](https://github.com/coco-de/coui/issues/3435)) ([b6f620a](https://github.com/coco-de/coui/commit/b6f620a461b39449cb8272fe3e6d5359c6e49471))
* **web:** [#3763](https://github.com/coco-de/coui/issues/3763) — Core↔docs 정합 트랙 A(Web transport 결함) 완료 ([#3845](https://github.com/coco-de/coui/issues/3845)) ([5e558b9](https://github.com/coco-de/coui/commit/5e558b94bc79e8fcffae810e892b45876c9600f5))
* **web:** 컴포넌트 그림자가 CSS 변수를 지나게 함 — 프리셋이 절반만 닿던 것 ([#3398](https://github.com/coco-de/coui/issues/3398)) ([00f7ece](https://github.com/coco-de/coui/commit/00f7ece8dfe48a68a50158def0442c0bdd504050))


### 버그 수정

* [#3843](https://github.com/coco-de/coui/issues/3843) [#3846](https://github.com/coco-de/coui/issues/3846) — Sortable 드래그 행 z-order + 핸들 아이콘 정렬 ([#3847](https://github.com/coco-de/coui/issues/3847)) ([7d68e39](https://github.com/coco-de/coui/commit/7d68e39b70e8b50c5fef3e85b8e5e7dba12aa770))
* **a11y:** [#3432](https://github.com/coco-de/coui/issues/3432) — 문서화가 드러낸 배선 결함 6건 ([#3442](https://github.com/coco-de/coui/issues/3442)) ([fb64ea1](https://github.com/coco-de/coui/commit/fb64ea1570bf5103c1079630cc1a69459f5fb3b4))
* **a11y:** [#4117](https://github.com/coco-de/coui/issues/4117) — 아이콘 전용 affordance 10곳에 접근 가능한 이름 부여 ([#4124](https://github.com/coco-de/coui/issues/4124)) ([c25d77d](https://github.com/coco-de/coui/commit/c25d77d92472f31414421b89b80c75ddf72dc3c1))
* **a11y:** [#4155](https://github.com/coco-de/coui/issues/4155) — Status live region 파리티 + 미번역 기본 라벨 제거 ([#4156](https://github.com/coco-de/coui/issues/4156)) ([4502688](https://github.com/coco-de/coui/commit/4502688e103bfba82360101d7aa82fdbf6fb5cc3))
* **a11y:** 링크·푸터 시맨틱 복구 + Chip·Avatar·Badge 전달 인자 + 정적 사이트 다크 모드 경로 ([#4271](https://github.com/coco-de/coui/issues/4271)) ([0a20bfc](https://github.com/coco-de/coui/commit/0a20bfcea18e16231b272f6267d01d46675e5c0f))
* **alert:** 박스를 직접 그리는 대신 OutlinedContainer 를 합성한다 ([#4249](https://github.com/coco-de/coui/issues/4249)) ([1466afc](https://github.com/coco-de/coui/commit/1466afc9aa718859ab86f8694560fa2f142e9d94))
* **autocomplete:** [#4187](https://github.com/coco-de/coui/issues/4187) — 패널을 텍스트 편집이 아니라 props 에 재조정 ([#4213](https://github.com/coco-de/coui/issues/4213)) ([cf5a6a1](https://github.com/coco-de/coui/commit/cf5a6a10434e26030355244c8cbd71455d41aa69))
* **autocomplete:** [#4188](https://github.com/coco-de/coui/issues/4188) — replaceWord 가 캐럿 위치의 단어를 완성한다 ([#4215](https://github.com/coco-de/coui/issues/4215)) ([cf69ea0](https://github.com/coco-de/coui/commit/cf69ea02ecf7ea66b0cc2d6de224b5c50303fe46))
* **badge:** 스타일의 캐스트를 받는다 + 변환을 한 함수로 모은다 ([#4252](https://github.com/coco-de/coui/issues/4252)) ([2857959](https://github.com/coco-de/coui/commit/2857959c642eaf43fb2f34ca41dbeceddd0ed851))
* **core,flutter,web:** [#3495](https://github.com/coco-de/coui/issues/3495) — 드래그-스크롤 뷰포트를 보조 기술·키보드에 노출 ([#3958](https://github.com/coco-de/coui/issues/3958)) ([cd1a0f7](https://github.com/coco-de/coui/commit/cd1a0f7e0c513349fcce5aec7cb2a684b40f6923))
* **core,flutter,web:** [#3502](https://github.com/coco-de/coui/issues/3502) B — warning fill 을 텍스트 색에서 분리 (WCAG 1.4.3) ([#3973](https://github.com/coco-de/coui/issues/3973)) ([3c4e8d2](https://github.com/coco-de/coui/commit/3c4e8d2206a7e065a4f99129443bfad5cd69a70a))
* **core,flutter,web:** [#4082](https://github.com/coco-de/coui/issues/4082) — [#4001](https://github.com/coco-de/coui/issues/4001) 후속 4건 (resizable 정규화 · focus-ring 슬롯/합성 3건) ([#4121](https://github.com/coco-de/coui/issues/4121)) ([edf91db](https://github.com/coco-de/coui/commit/edf91db8f06b411496f091d65387e90fdf6a3957))
* **core,flutter,web:** [#4126](https://github.com/coco-de/coui/issues/4126) — [#4082](https://github.com/coco-de/coui/issues/4082) 후속 3건 (circle 링 죽은 필드 · badge offset 색 · 슬롯 clobber) ([#4139](https://github.com/coco-de/coui/issues/4139)) ([c9d60b7](https://github.com/coco-de/coui/commit/c9d60b78942e32bc8980e8c2e40e87e772988d67))
* **core:** [#4237](https://github.com/coco-de/coui/issues/4237) — 두 엣지 run 이 양 모드에서 다 보인다 ([#4241](https://github.com/coco-de/coui/issues/4241)) ([9460b01](https://github.com/coco-de/coui/commit/9460b01ddfa1f1b3d4cc2c63178cf58aa7423a51))
* **docs:** Jaspr 0.23.2 최신화 + CI Flutter 3.44.8 상향 + "On this page" 앵커/스타일 수정 ([#3489](https://github.com/coco-de/coui/issues/3489)) ([87ca07b](https://github.com/coco-de/coui/commit/87ca07be932fb8eb09f63cbe0edd8efc26d0747d))
* **flutter,web:** [#3771](https://github.com/coco-de/coui/issues/3771) — Form + Layout/Nav + Display + Overlay/Misc 25개 컴포넌트의 border/radius가 surface-style geometry 축을 안 탐 (Batch 1-5/5) ([#3828](https://github.com/coco-de/coui/issues/3828)) ([18f2df8](https://github.com/coco-de/coui/commit/18f2df82a359ff8fb9ebb9d52025b18a9119e1e2))
* **flutter,web:** [#3825](https://github.com/coco-de/coui/issues/3825) — Scaffold 중첩 시 main 랜드마크를 하나만 낸다 ([#4075](https://github.com/coco-de/coui/issues/4075)) ([571700f](https://github.com/coco-de/coui/commit/571700f7a2418fbee1efaea7a8b65c277e7d0440))
* **flutter,web:** [#3864](https://github.com/coco-de/coui/issues/3864) — 슬라이더 paint 와 input 을 inset 모델로 통일 ([#3865](https://github.com/coco-de/coui/issues/3865)) ([1c2d136](https://github.com/coco-de/coui/commit/1c2d136d19d9e52dbc4ea1125a75b3275d7b714f))
* **flutter,web:** [#3979](https://github.com/coco-de/coui/issues/3979) — a11y 감사 후속 5건 (Scrollbar 접근성 노드·값 축·플랫폼 대칭 + TimePicker 링) ([#3999](https://github.com/coco-de/coui/issues/3999)) ([5a017c9](https://github.com/coco-de/coui/commit/5a017c95449e6883eb287158ff8013023b285431))
* **flutter:** [#3718](https://github.com/coco-de/coui/issues/3718) — Command/Kbd border 가 surface-style geometry(strokeFloor)를 안 탐 ([#3719](https://github.com/coco-de/coui/issues/3719)) ([ad5e7fc](https://github.com/coco-de/coui/commit/ad5e7fc5c0d89f877081e37acad67602780e9919))
* **flutter:** hover 채움 아래로 캐스트가 비치지 않는다 ([#4276](https://github.com/coco-de/coui/issues/4276)) ([ff06bc0](https://github.com/coco-de/coui/commit/ff06bc096b931ee6e5418d0fc5536544fbf71bbf))
* **form:** 가려진 필드가 스펠체크·자동수정·IME 학습에 도달하지 않는다 ([#3409](https://github.com/coco-de/coui/issues/3409)) ([51b8a11](https://github.com/coco-de/coui/commit/51b8a115aa6ce97d833acb3a5dd1038ee118e945)), closes [#3385](https://github.com/coco-de/coui/issues/3385)
* **form:** 폼 입력 계약 4건 — 선언만 되고 아무도 안 읽던 필드 배선 ([#4224](https://github.com/coco-de/coui/issues/4224)) ([cb09aa9](https://github.com/coco-de/coui/commit/cb09aa95213ff6598781f63c36b0243bd6342458))
* **layout:** Epic D 4건 — join 포커스 링 · table intrinsic · stepper 앵커 · resizable optionalDivider ([#4255](https://github.com/coco-de/coui/issues/4255)) ([f1ccc24](https://github.com/coco-de/coui/commit/f1ccc249d1487f3545092db7ba01519d1c69647e))
* **menubar:** [#4165](https://github.com/coco-de/coui/issues/4165) — 열린 상태에서 형제 트리거 호버 시 메뉴 전환 ([#4167](https://github.com/coco-de/coui/issues/4167)) ([5049ae7](https://github.com/coco-de/coui/commit/5049ae7ba385dc398f7bbac5c25cd472af791c8c))
* **navigation_menu:** [#4163](https://github.com/coco-de/coui/issues/4163) — 호버 애니메이션 Web/Flutter 파리티 (닫힘 디바운스 + 패널 전환 슬라이드) ([#4168](https://github.com/coco-de/coui/issues/4168)) ([22e257a](https://github.com/coco-de/coui/commit/22e257af8aaf1219646f8c4f58dba6884dcae1c8))
* **navigation_menu:** [#4175](https://github.com/coco-de/coui/issues/4175) — QA 후속 회귀 4건 ([#4177](https://github.com/coco-de/coui/issues/4177)) ([52449d4](https://github.com/coco-de/coui/commit/52449d49c0f95bea4ed5992d2acacef6ba417383))
* **nav:** 선택 상태가 색으로만 구분되던 것에 비-색 신호 추가 ([#3394](https://github.com/coco-de/coui/issues/3394)) ([127b239](https://github.com/coco-de/coui/commit/127b239ccad07b02b802c122a37671e1807b49a7))
* **overlay:** [#3699](https://github.com/coco-de/coui/issues/3699) — Tooltip tooltipChild 기본 가시성 + panelMaxWidth 슬롯 ([#3700](https://github.com/coco-de/coui/issues/3700)) ([f898acb](https://github.com/coco-de/coui/commit/f898acb27cddc8f1151bc6fdd43294dc9e918c99))
* **parity:** [#3644](https://github.com/coco-de/coui/issues/3644) — WebLifecycleProbe 퇴장 관측을 child rebuild로 교정 ([#3668](https://github.com/coco-de/coui/issues/3668)) ([0001685](https://github.com/coco-de/coui/commit/00016853c9321ee6a50c2707a5a3163f81dd945c))
* **parity:** 문서↔코드 · Flutter↔Web 드리프트 실측 수정 + 게이트 4종 ([#3440](https://github.com/coco-de/coui/issues/3440)) ([3953ef5](https://github.com/coco-de/coui/commit/3953ef58f8d3e60ae07a33db9fe2295077ab3992))
* **phone_input:** 입력값을 추측하지 않는다 — 타이핑된 다이얼 코드만 벗긴다 ([#4245](https://github.com/coco-de/coui/issues/4245)) ([8dde2aa](https://github.com/coco-de/coui/commit/8dde2aa7481d89ee009fb1c17ff6bfc47761f086))
* **resizable:** [#4265](https://github.com/coco-de/coui/issues/4265) — optionalDivider 가 드래그 중에도 드러나 있게 한다 ([#4267](https://github.com/coco-de/coui/issues/4267)) ([172b598](https://github.com/coco-de/coui/commit/172b59894261ce4f40f9f3cdfd5ac0de056621f0))
* **surface:** Avatar · MockupWindow · Command 이 스타일의 캐스트를 받는다 ([#4261](https://github.com/coco-de/coui/issues/4261)) ([8c50735](https://github.com/coco-de/coui/commit/8c5073564ec9c74a00c4cbcccd519d1770b385f7))
* **surface:** EmptyState · CodeSnippet · Table 이 스타일의 캐스트를 받는다 ([#4256](https://github.com/coco-de/coui/issues/4256)) ([88270b5](https://github.com/coco-de/coui/commit/88270b5829df4b9ce3874e1b44d30180f86ba18c))
* **surface:** Fieldset · Chip · Kbd 이 스타일의 캐스트를 받는다 ([#4253](https://github.com/coco-de/coui/issues/4253)) ([ee34305](https://github.com/coco-de/coui/commit/ee3430590223539ece7f7996133c36edfc31a306))
* **surface:** 스타일 캐스트가 양 플랫폼에 같게 도달한다 ([#4242](https://github.com/coco-de/coui/issues/4242)) ([b01584f](https://github.com/coco-de/coui/commit/b01584fba7938b050e8bf275a4f90f8e93ffc1ec))
* **surface:** 캐스트가 그리지 않은 박스에서 나오거나, 그린 박스에서 빠지던 5건 ([#4269](https://github.com/coco-de/coui/issues/4269)) ([8c92b6b](https://github.com/coco-de/coui/commit/8c92b6b89a075945301c61cd22bd3058305c7d24))
* **surface:** 폼 컨트롤 5종이 스타일의 캐스트를 받는다 ([#4263](https://github.com/coco-de/coui/issues/4263)) ([9231e42](https://github.com/coco-de/coui/commit/9231e42924fab0e4335506455c25bb38e8079550))
* **surface:** 프레임·바 6종이 스타일의 캐스트를 받는다 ([#4266](https://github.com/coco-de/coui/issues/4266)) ([4d24238](https://github.com/coco-de/coui/commit/4d2423863059ff3cb05a8d33635478eecf541d5f))
* **upstream:** shadcn_flutter 0.0.53 감사 확정 13건 이식 ([#4206](https://github.com/coco-de/coui/issues/4206)) ([b01519b](https://github.com/coco-de/coui/commit/b01519b2ba4fb18673d0cb359320f771bbb7934a))
* **web:** [#3495](https://github.com/coco-de/coui/issues/3495) — ScrollableClient 뷰포트에 UA 포커스 아웃라인 억제 추가 ([#3976](https://github.com/coco-de/coui/issues/3976)) ([27916dc](https://github.com/coco-de/coui/commit/27916dcf68f949915132802f09357ee931f198b2))
* **web:** [#3704](https://github.com/coco-de/coui/issues/3704) — DotIndicator 의 hover 가 터치 타겟 오버레이에 가려 죽어 있었다 ([#3709](https://github.com/coco-de/coui/issues/3709)) ([dc4475d](https://github.com/coco-de/coui/commit/dc4475d03e5e0f066f14c0db68eeeec108cbb0dc))
* **web:** [#3705](https://github.com/coco-de/coui/issues/3705) — 포인터 타겟 확장이 자기 안쪽을 가리지 않게 ([#3717](https://github.com/coco-de/coui/issues/3717)) ([e511b8e](https://github.com/coco-de/coui/commit/e511b8e9333a76791f3b7d6296496bc61906fa2a))
* **web:** [#3776](https://github.com/coco-de/coui/issues/3776) — theme_config.dart Tailwind screens를 CoreBreakpoint에 배선 ([#3835](https://github.com/coco-de/coui/issues/3835)) ([b3d7b34](https://github.com/coco-de/coui/commit/b3d7b34d703809d4c563749297127da087cefe7c))
* **web:** [#3829](https://github.com/coco-de/coui/issues/3829) — DraggablePanel 이 드래그 스코프가 렌더한 박스에 높이를 잃는다 ([#3830](https://github.com/coco-de/coui/issues/3830)) ([0e622f7](https://github.com/coco-de/coui/commit/0e622f73c3cb03dcbddee8624301b385bd561b4f))
* **web:** neo-brutalism strokeFloor not reaching Web stroke/line-width emits ([#3809](https://github.com/coco-de/coui/issues/3809)) ([675779b](https://github.com/coco-de/coui/commit/675779b63bfafbd13380c687ff19861812801000))
* **web:** 고대비가 장식 프리셋에 지던 순서를 특이도로 뒤집음 ([#3373](https://github.com/coco-de/coui/issues/3373)) ([41c534a](https://github.com/coco-de/coui/commit/41c534a85ab7f1bac6eb12da8d4efed574882deb))
* **web:** 그림자로만 경계를 그리는 프리셋에 forced-colors 경계를 실제로 그림 ([#3369](https://github.com/coco-de/coui/issues/3369)) ([3c5fc9d](https://github.com/coco-de/coui/commit/3c5fc9d91f8ceda619dd9f144e6b165e2301a824))
* **web:** 캐스트가 hoverable 카드에도 도달한다 ([#4244](https://github.com/coco-de/coui/issues/4244)) ([5d2501b](https://github.com/coco-de/coui/commit/5d2501bb3b7e399952b537ae9239f0c53ca76029))


### 리팩터링

* **group:** deprecate Group — duplicates Stacks + Position ([#4094](https://github.com/coco-de/coui/issues/4094)) ([de4f177](https://github.com/coco-de/coui/commit/de4f177a2328688d291d28ac454d2ac28dccb53e))
* **web:** [#3848](https://github.com/coco-de/coui/issues/3848) — Sortable 의 픽셀에 닿지 않는 선언 정리 ([#3849](https://github.com/coco-de/coui/issues/3849)) ([2b05851](https://github.com/coco-de/coui/commit/2b05851c1340e4ff8a6e15d63ccc009372c19c2b))


### 문서

* **rules:** [#3319](https://github.com/coco-de/coui/issues/3319) — 폼 밖 에러 표면 결정 + 톤별 통보 방식 ([#3425](https://github.com/coco-de/coui/issues/3425)) ([af73647](https://github.com/coco-de/coui/commit/af73647171e825ae2d9362491fc0acc63404032d))

## [0.127.17](https://github.com/coco-de/coui/compare/coui_web-v0.127.16...coui_web-v0.127.17) (2026-07-23)


### 버그 수정

* **web:** [#3264](https://github.com/coco-de/coui/issues/3264) — Phase 6 inline px 3건을 design-token 마커로 정당화 ([#3275](https://github.com/coco-de/coui/issues/3275)) ([170ba03](https://github.com/coco-de/coui/commit/170ba035ca2e2a80b5d18a508266718f2092e72f))
* **web:** [#3269](https://github.com/coco-de/coui/issues/3269) — TextField disabled 라벨 recolor 실동작 (resolver-time, Flutter 파리티) ([#3288](https://github.com/coco-de/coui/issues/3288)) ([93b08bf](https://github.com/coco-de/coui/commit/93b08bfa626ed6f96741ffbe234d0eb2f6f023d2))
* **web:** [#3276](https://github.com/coco-de/coui/issues/3276) — border-width rem → px 고정 (47 사이트 + strokeWidthCss + Phase 7 가드) ([#3279](https://github.com/coco-de/coui/issues/3279)) ([262e076](https://github.com/coco-de/coui/commit/262e0765f3456a9e0c4e4115fd68dd7b6a953a09))


### 리팩터링

* **web:** [#3285](https://github.com/coco-de/coui/issues/3285) — check_web_resolver 가드 green (Flutter 가드 미러 + 진짜 위반 실해소) ([#3287](https://github.com/coco-de/coui/issues/3287)) ([7884fc0](https://github.com/coco-de/coui/commit/7884fc0f616afd1607ad9a90f86b14a39e07206b))

## [0.127.16](https://github.com/coco-de/coui/compare/coui_web-v0.127.15...coui_web-v0.127.16) (2026-07-21)


### 버그 수정

* **drawer:** backdropCornerRadius가 비대칭 override를 유실하던 문제 수정 ([#3262](https://github.com/coco-de/coui/issues/3262)) ([a329148](https://github.com/coco-de/coui/commit/a329148c5aa820216d6942e285c0610b19e1b231))
* **web:** pseudo-state 색 raw override 크래시 해소 — class XOR scoped &lt;style&gt; emit ([#3265](https://github.com/coco-de/coui/issues/3265)) ([87d94ef](https://github.com/coco-de/coui/commit/87d94efe6fec2fc0385ef7dba7117275d4c358d9))

## 0.127.14 (2026-06-16)

### Refactored
- #2593 — card de-prefix (co_card→card, legacy SurfaceCard→surface_card.dart) (#2599)

---

## 0.127.13 (2026-06-16)

### Refactored
- #2593 — color_picker de-prefix (co_color_picker→color_picker, legacy→_internal) (#2597)

---

## 0.127.12 (2026-06-16)

### Refactored
- #2593 — tooltip de-prefix (legacy TooltipContainer 삭제 + co_tooltip→tooltip) (#2596)

---

## 0.127.11 (2026-06-16)

### Refactored
- #2593 — toast de-prefix (legacy ToastTheme 삭제 + co_toast→toast) (#2595)

---

## 0.127.10 (2026-06-16)

### Refactored
- #2593 — button de-prefix 완료 (legacy 37 클래스 삭제 + co_button→button) (#2594)

---

## 0.127.9 (2026-06-16)

### Refactored
- #2584 — de-prefix radio_group (companion rename) (#2592)

---

## 0.127.8 (2026-06-16)

### Refactored
- #2584 — 파일 de-prefix (clickable companion + render_co_grid) (#2591)

---

## 0.127.7 (2026-06-16)

### Refactored
- #2584 — 파일 de-prefix 배치2c (대형 companion 5개 의미명 분리) (#2590)

---

## 0.127.6 (2026-06-16)

### Refactored
- #2584 — 파일 de-prefix 배치2b (작은 companion 4개 병합) (#2589)

---

## 0.127.5 (2026-06-16)

### Refactored
- #2584 — 파일 de-prefix 배치2a (작은 companion 4개 위젯 파일로 병합) (#2587)

---

## 0.127.4 (2026-06-16)

### Refactored
- #2584 — coui_flutter 파일 de-prefix 배치1 (legacy 형제 없는 co_*.dart 136 rename) (#2586)

---

## 0.127.3 (2026-06-16)

### Refactored
- #2512 — remove DaisyUI colour aliases (15 scheme fields + theme_config keys) (#2583)

---

## 0.127.2 (2026-06-16)

### Refactored
- #2554 — relocate DateConstants → CoreCalendarGridData (#2582)

---

## 0.127.1 (2026-06-16)

### Refactored
- #2553 — relocate ColorConstants → CoreColorConversion (#2581)

---

## 0.127.0 (2026-06-16)

### Added
- #2533 — app-shell capability parity (onNavigationNotification / supportedLocales / pixelSnap) (#2577)

---

## 0.126.0 (2026-06-15)

### Added
- #2531 — global surfaceBlur/surfaceOpacity on Web ThemeData (#2575)

---

## 0.125.0 (2026-06-15)

### Added
- #2530 — Web ThemeData.fromCore + CoreThemePresets wiring (#2574)

---

## 0.124.0 (2026-06-15)

### Added
- #2529 — wire CoUIWeb.enableScrollInterception to the CoUI autoscroll engine (#2573)

---

## 0.123.0 (2026-06-15)

### Added
- #2528 — CoUIWeb.color → <meta name="theme-color"> sync (#2572)

---

## 0.122.0 (2026-06-15)

### Added
- #2527 — CoUIWeb.enableThemeAnimation (dark-toggle cross-fade) (#2571)

---

## 0.121.1 (2026-06-15)

### Fixed
- #2526 — Web shadows use the designer 2-layer spec (--shadow-* vars) (#2570)

---

## 0.121.0 (2026-06-15)

### Added
- #2524 — wire designSystem → adapter → resolve into the theme path (#2568)

---

## 0.120.1 (2026-06-15)

### Fixed
- #2523 — CoreThemeData defaultMotion/defaultSurface equality + toJson 정합 (#2567)

---

## 0.120.0 (2026-06-15)

### Added
- #2522 — DesignSystemAdapter.resolveCornerStyle / resolveSurface (#2566)

---

## 0.119.2 (2026-06-15)

### Fixed
- #2521 — selectable selection tint → CoUI primary (no Material clash) (#2565)

---

## 0.119.1 (2026-06-15)

### Refactored
- #2519 — Material Icons.* doc examples → CoUI icon set (#2564)

---

## 0.119.0 (2026-06-15)

### Added
- #2518 — de-prefix collision guard + material-import-ban docs (#2563)

---

## 0.118.2 (2026-06-15)

### Refactored
- #2517 — de-prefix docs_site (CoXxx->bare across examples/registry/md/nav/search) (#2561)

---

## 0.118.1 (2026-06-15)

### Refactored
- #2516 — de-prefix coui_web (Co->bare, co_*.dart->*.dart, barrel hide Gap/Position) + align to core renames (#2560)

---

## 0.118.0 (2026-06-15)

### Added
- E3 de-prefix — coui_core + coui_flutter Co→bare + delete legacy (S3.1/S3.2/S3.3) (#2559)

---

## 0.117.16 (2026-06-15)

### Refactored
- #2511 — CoreDuration 비-ms 잔재(회전각 삭제 / 배율 migrate / dead scale 키) 정리 (#2558)

---

## 0.117.15 (2026-06-15)

### Refactored
- #2510 — AnimationConstants 완전 삭제, CoreDuration 직접 경유 + 룰 갱신 (#2557)

---

## 0.117.14 (2026-06-15)

### Refactored
- #2509 — effect_style.dart (dead styling 레이어) 삭제 (#2556)

---

## 0.117.13 (2026-06-15)

### Refactored
- #2508 — LayoutConstants (Core-canonical-dup) 삭제, Core 직접 사용 (#2555)

---

## 0.117.12 (2026-06-15)

### Refactored
- #2507 — web dead 클러스터(SpacingScale + theme.dart hub + Spacing re-export) 삭제 (#2552)

---

## 0.117.11 (2026-06-15)

### Refactored
- #2506 — ColorSchemes·kDefaultLightCoreColorArgb (DaisyUI 기본색) 삭제 (#2551)

---

## 0.117.10 (2026-06-15)

### Refactored
- #2505 — RadiusScale(DaisyUI box/field/selector) 삭제, CoreRadius 정본화 (#2550)

---

## 0.117.9 (2026-06-15)

### Refactored
- #2504 — no-op 헬퍼·중복·죽은 메서드 정리 (buildCoreScheme 외) (#2548)

---

## 0.117.8 (2026-06-15)

### Fixed
- #2503 — Flutter color_conversion 색공간 수학 → CoreColorConversion dedup (#2547)

---

## 0.117.7 (2026-06-15)

### Fixed
- #2502 — CoreThemeData typography·ThemeData coreTypography equality 누락 수정 (#2545)

---

## 0.117.6 (2026-06-15)

### Documentation
- #2501 — 서술형 룰은 코드 Story PR 동봉(선기술 금지) 정책 명문화 (#2544)

---

## 0.117.5 (2026-06-15)

### Documentation
- #2500 — design-tokens.md DaisyUI radius cruft 제거 (CoreRadiusScale 죽은참조) (#2543)

---

## 0.117.4 (2026-06-15)

### Documentation
- #2499 — unify-* 스킬 + verify.md CoXxx → bare (#2542)

---

## 0.117.3 (2026-06-15)

### Documentation
- #2498 — cross-platform/api.md + principles CoXxx → bare (#2541)

---

## 0.117.2 (2026-06-15)

### Documentation
- #2497 — naming.md Co 접두 제거 → bare 규약 + Core/CoUI 경계 (#2540)

---

## 0.117.1 (2026-06-15)

### Fixed
- 🐛 CoMenuOverlayController 배럴 export 추가 (MenuItem 외부 구현 가능화) (#2538)

---

## 0.117.0 (2026-06-15)

### Added
- ✨ CoResizable showDragHandle (모바일 grab 핸들) — Flutter + Web (#2495)

---

## 0.116.2 (2026-06-15)

### Fixed
- #2493 — CoTabs underline SSR 크래시 해결 (backgroundColor! → ?? transparent) (#2494)

---

## 0.116.1 (2026-06-15)

### Fixed
- #2491 — tap 오버레이 trigger 비경쟁 감지 + context-menu 레이아웃 (#2492)

---

## 0.116.0 (2026-06-15)

### Added
- #2489 — 앵커드 오버레이를 단일 공유 엔진으로 이주 (tooltip·hovercard·menu) (#2490)

### Fixed
- #2487 — 오버레이 기본 핸들러 cross-platform 일관화 (mobileMode 분기 제거) (#2488)

---

## 0.115.0 (2026-06-14)

### Added
- CoDraggablePanel — generic 플로팅 드래그 패널 (Flutter + Web unified) (#2485)

### Fixed
- CoDraggablePanel — 하단 도킹 시 패널이 위로 펼쳐지도록 (clip 방지) (#2486)

---

## 0.114.1 (2026-06-13)

### Fixed
- CoDraggablePanel — 하단 도킹 시 패널이 위로 펼쳐지도록 (clip 방지) (#2486)

---

## 0.114.0 (2026-06-13)

### Added
- CoDraggablePanel — generic 플로팅 드래그 패널 (Flutter + Web unified) (#2485)

---

## 0.113.2 (2026-06-12)

### Fixed
- #2302 — color_picker role=tab + command role=listbox (a11y role-loss) (#2482)

---

## 0.113.1 (2026-06-12)

### Refactored
- #2302 — #19 batch1: co_badge hand-rolled clickable → CoClickable (#2481)

---

## 0.113.0 (2026-06-12)

### Added
- #2365 — PR2: CoButton transport off deprecated Clickable → CoClickable (#2480)

---

## 0.112.0 (2026-06-12)

### Added
- #2365 — PR1: CoClickable 제스처 확장 (secondary/tertiary/long-press + marginAlignment) (#2479)

---

## 0.111.0 (2026-06-12)

### Added
- #2463 — accordion·time_picker 라벨 레이아웃 → resolver slot (render-only) (#2478)

---

## 0.110.0 (2026-06-12)

### Added
- #2463 — button expanded-label 레이아웃 → resolver slot (render-only) (#2477)

---

## 0.109.0 (2026-06-12)

### Added
- #2474 — CoListRow/CoListCol → UiComponent (sweep 완결) (#2476)

---

## 0.108.0 (2026-06-12)

### Added
- #2474 — 단일-root raw StatelessComponent → UiComponent 통일 (15개) (#2475)

---

## 0.107.0 (2026-06-12)

### Added
- #2454 — E6: stateless base 단일화 (UiComponent slim collapse) (#2472)

---

## 0.106.0 (2026-06-12)

### Added
- #2467 — E5: 나머지 StatefulComponent → UiStatefulComponent passthrough (#2471)

---

## 0.105.1 (2026-06-11)

### Refactored
- #2456 — 옛 Styling-DSL husk 28파일 전면 삭제 (B) (#2469)

---

## 0.105.0 (2026-06-11)

### Added
- #2453 — WebChrome mixin + UiStatefulComponent passthrough 기반 (E1-E4) (#2466)

---

## 0.104.2 (2026-06-11)

### Refactored
- #2452 — ui_component LEAN: 죽은 Styling-era 머신러리 제거 (D) (#2465)

---

## 0.104.1 (2026-06-11)

### Fixed
- #2451 — WebLayout interleaved 구조 토큰 완전 분해 (#2464)

---

## 0.104.0 (2026-06-11)

### Added
- #2451 — WebLayout 전체 구조 레이아웃 어휘(atom+combo) + 컴포넌트 전수 DRY (G/C2) (#2462)

---

## 0.103.0 (2026-06-11)

### Added
- #2450 — 앵커 오버레이 6종을 OverlayPositioner로 통합 (engine superset) (#2460)

---

## 0.102.0 (2026-06-11)

### Added
- #2450 — 통합 오버레이 엔진(OverlayPositioner) + tooltip 첫 소비자 (#2459)

---

## 0.101.9 (2026-06-11)

### Refactored
- #2450 — FloatingController id-기반으로 (SSR-safe 소비 가능하게) (#2458)

---

## 0.101.8 (2026-06-11)

### Refactored
- #24 — alert → UiComponent 승격 (attributes passthrough, clean-4 완료) (#2448)

---

## 0.101.7 (2026-06-11)

### Refactored
- #24 — footer·multiple_choice·dock → UiComponent 승격 (attributes passthrough) (#2447)

---

## 0.101.6 (2026-06-11)

### Fixed
- check_web_resolver — RULE A 제거 (canonical Web EMIT과 충돌) (#2446)

---

## 0.101.5 (2026-06-10)

### Refactored
- #2317 — alert·banner·drawer·filter affordance → CoButton(plain) 정통 (최종 배치) (#2445)

---

## 0.101.4 (2026-06-10)

### Refactored
- #2317 — text_field feature 버튼 → CoButton(plain) 정통 대칭 (nested 슬롯) (#2444)

---

## 0.101.3 (2026-06-10)

### Refactored
- #2317 — code_snippet copy + toast close → CoButton(plain) 정통 (#2443)

---

## 0.101.2 (2026-06-10)

### Refactored
- #2317 — chip_input remove → CoButton(plain) 완전 정통 (양쪽+nested 슬롯+체인+raw-forward) (#2442)

---

## 0.101.1 (2026-06-10)

### Refactored
- #2317 — atomic Co 합성 (Stack/Positioned·feature 버튼) (#2438)

---

## 0.101.0 (2026-06-10)

### Added
- #2317 — 구현대칭 (showCursor·onTap*·formatters·features) (#2437)

---

## 0.100.11 (2026-06-10)

### Refactored
- canonical sweep 11 — Flutter scheme.<token> → Core default (8개) + gate scheme 확장 (#2436)

---

## 0.100.10 (2026-06-10)

### Refactored
- canonical sweep 10 — form/frame/drawer + gate 갭(token list/scheme.resolve/resolved.toValue) (#2435)

---

## 0.100.9 (2026-06-10)

### Refactored
- infra full-canonical sweep (#2434)

---

## 0.100.8 (2026-06-10)

### Refactored
- canonical sweep 8 — button/table/calendar/date_picker/text_field 등 + resolved.toValue gate [9] (#2433)

---

## 0.100.7 (2026-06-10)

### Refactored
- resolver/Style canonical sweep 7 — form/menu/text_field + gate 갭(colorScheme.resolve) (#2432)

---

## 0.100.6 (2026-06-09)

### Refactored
- resolver/Style canonical sweep 6 — 12 컴포넌트 (form/menu/util) + use-site Flutter-first (#2431)

---

## 0.100.5 (2026-06-09)

### Refactored
- 배치22 + gate [9] 위젯 render-only(use-site칸 4/6) + use-site 수정 (#2430)

---

## 0.100.4 (2026-06-09)

### Refactored
- resolver/Style canonical sweep 4 — 12 컴포넌트 (display/overlay/layout) (#2429)

---

## 0.100.3 (2026-06-09)

### Refactored
- * scaling을 Stage2 EMIT으로 (return→local 마이그 84 resolver) + 배치16 sweep (#2428)

---

## 0.100.2 (2026-06-09)

### Refactored
- resolver/Style canonical sweep 2 — 20 컴포넌트 (form/nav/overlay/layout) + nullable scaling 룰 (#2427)

---

## 0.100.1 (2026-06-09)

### Refactored
- resolver/Style canonical 통일 — 변환헬퍼 3-layer + emit family + 39 컴포넌트 sweep + gate (#2426)

---

## 0.100.0 (2026-06-09)

### Added
- #2317 — placeholderWidget cross-platform 통일 (Flutter↔Web) (#2425)
- #2302 — CoSeparator indent support (#2397)

### Fixed
- 🐛 OTP 입력 완료 시 자동 키보드 해제 + Web 완료 감지 복구 (#2395)
- #2302 — required-indicator colour stays a token, drop CoreColor round-trip (#2409)
- #2302 — trailing icon uses placeholder colour token, drop CoreColor round-trip (#2408)
- #2302 — divider token raw-forward, fix divider thickness double-scale (#2405)
- #2302 — leading + dismiss icon colours stay tokens, drop resolve→re-wrap round-trips (#2404)
- #2302 — chevron icon colour stays a token, drop resolve→re-wrap round-trip (#2403)
- #2302 — divider separator slot from border token, drop CoreColor round-trip (#2402)
- #2302 — bake foreground token into reset-icon slot, drop CoreColor round-trip (#2401)
- #2302 — bake per-type accent into icon slot, drop CoreColor round-trip (#2400)
- #2302 — CoListing divider as nested CoreDividerStyle slot (rule 2.2) (#2399)
- #2302 — dropdown/context menu divider as nested CoreSeparatorStyle slot (rule 2.2) (#2398)
- #2302 — CoMenu divider as nested CoreSeparatorStyle slot (rule 2.2) (#2396)

### Refactored
- #2302 — resolver-output 변수명 정규화 style → resolved (Pattern N, 18파일) (#2424)
- #2302 — co_calendar widget render-only (per-state CoreButtonStyle slots) (#2423)
- #2302 — co_text_area widget render-only (focus slot + paint-ready text/colours) (#2422)
- #2302 — co_phone_input widget render-only (separator/chevron/text slots) (#2421)
- #2302 — co_text_field widget render-only (focus-ring double-scale + paint-ready text) (#2420)
- #2302 — co_file_input widget render-only (per-state slots, token+opacity icons) (#2419)
- #2302 — co_command widget render-only (paint-ready text styles + footer/search bake) (#2418)
- #2302 — co_tree widget render-only (chevron/icon slots + selected-bg bake) (#2417)
- #2302 — co_stepper widget render-only (connector slot + check-icon double-scale) (#2416)
- #2302 — widget render-only, bake header icon + divider tokens + resolved shadow (#2415)
- #2302 — widget render-only, bake header styles + fade gradient tokens (#2414)
- #2302 — widget render-only, per-state option styles + check-icon token (fix double-scale) (#2413)
- #2302 — bake copy-icon foreground token, drop CoreColor round-trip (#2412)
- #2302 — widget render-only, bake close-icon token + resolve cursor colour (#2411)
- #2302 — make widget render-only, resolver bakes paint-ready text styles (#2410)
- #2302 — drop pre-existing Hungarian token-suffix locals (code_diff/form_field/checkbox) (#2407)
- #2302 — drop Hungarian token-suffix locals from round-trip fixes (#2406)

---

## 0.99.0 (2026-06-08)

### Added
- #2317 — placeholderWidget cross-platform 통일 (Flutter↔Web) (#2425)

---

## 0.98.27 (2026-06-08)

### Refactored
- #2302 — resolver-output 변수명 정규화 style → resolved (Pattern N, 18파일) (#2424)

---

## 0.98.26 (2026-06-08)

### Refactored
- #2302 — co_calendar widget render-only (per-state CoreButtonStyle slots) (#2423)

---

## 0.98.25 (2026-06-08)

### Refactored
- #2302 — co_text_area widget render-only (focus slot + paint-ready text/colours) (#2422)

---

## 0.98.24 (2026-06-08)

### Refactored
- #2302 — co_phone_input widget render-only (separator/chevron/text slots) (#2421)

---

## 0.98.23 (2026-06-08)

### Refactored
- #2302 — co_text_field widget render-only (focus-ring double-scale + paint-ready text) (#2420)

---

## 0.98.22 (2026-06-08)

### Refactored
- #2302 — co_file_input widget render-only (per-state slots, token+opacity icons) (#2419)

---

## 0.98.21 (2026-06-08)

### Refactored
- #2302 — co_command widget render-only (paint-ready text styles + footer/search bake) (#2418)

---

## 0.98.20 (2026-06-08)

### Refactored
- #2302 — co_tree widget render-only (chevron/icon slots + selected-bg bake) (#2417)

---

## 0.98.19 (2026-06-08)

### Refactored
- #2302 — co_stepper widget render-only (connector slot + check-icon double-scale) (#2416)

---

## 0.98.18 (2026-06-08)

### Refactored
- #2302 — widget render-only, bake header icon + divider tokens + resolved shadow (#2415)

---

## 0.98.17 (2026-06-08)

### Refactored
- #2302 — widget render-only, bake header styles + fade gradient tokens (#2414)

---

## 0.98.16 (2026-06-08)

### Refactored
- #2302 — widget render-only, per-state option styles + check-icon token (fix double-scale) (#2413)

---

## 0.98.15 (2026-06-08)

### Refactored
- #2302 — bake copy-icon foreground token, drop CoreColor round-trip (#2412)

---

## 0.98.14 (2026-06-08)

### Refactored
- #2302 — widget render-only, bake close-icon token + resolve cursor colour (#2411)

---

## 0.98.13 (2026-06-08)

### Refactored
- #2302 — make widget render-only, resolver bakes paint-ready text styles (#2410)

---

## 0.98.12 (2026-06-08)

### Fixed
- #2302 — required-indicator colour stays a token, drop CoreColor round-trip (#2409)

---

## 0.98.11 (2026-06-08)

### Fixed
- #2302 — trailing icon uses placeholder colour token, drop CoreColor round-trip (#2408)

---

## 0.98.10 (2026-06-08)

### Refactored
- #2302 — drop pre-existing Hungarian token-suffix locals (code_diff/form_field/checkbox) (#2407)

---

## 0.98.9 (2026-06-08)

### Refactored
- #2302 — drop Hungarian token-suffix locals from round-trip fixes (#2406)

---

## 0.98.8 (2026-06-08)

### Fixed
- #2302 — divider token raw-forward, fix divider thickness double-scale (#2405)

---

## 0.98.7 (2026-06-08)

### Fixed
- #2302 — leading + dismiss icon colours stay tokens, drop resolve→re-wrap round-trips (#2404)

---

## 0.98.6 (2026-06-08)

### Fixed
- #2302 — chevron icon colour stays a token, drop resolve→re-wrap round-trip (#2403)

---

## 0.98.5 (2026-06-08)

### Fixed
- #2302 — divider separator slot from border token, drop CoreColor round-trip (#2402)

---

## 0.98.4 (2026-06-08)

### Fixed
- #2302 — bake foreground token into reset-icon slot, drop CoreColor round-trip (#2401)

---

## 0.98.3 (2026-06-08)

### Fixed
- #2302 — bake per-type accent into icon slot, drop CoreColor round-trip (#2400)

---

## 0.98.2 (2026-06-08)

### Fixed
- #2302 — CoListing divider as nested CoreDividerStyle slot (rule 2.2) (#2399)

---

## 0.98.1 (2026-06-08)

### Fixed
- #2302 — dropdown/context menu divider as nested CoreSeparatorStyle slot (rule 2.2) (#2398)

---

## 0.98.0 (2026-06-08)

### Added
- #2302 — CoSeparator indent support (#2397)

---

## 0.97.18 (2026-06-08)

### Fixed
- #2302 — CoMenu divider as nested CoreSeparatorStyle slot (rule 2.2) (#2396)

---

## 0.97.17 (2026-06-08)

### Refactored
- Part of #2302 — Component.text → CoUI Text component (63 files) (#2394)

---

## 0.97.16 (2026-06-08)

### Fixed
- #2319 — dropdown/context menu items render as CoButton(variant: menu) (#2392)

---

## 0.97.15 (2026-06-08)

### Fixed
- #2319 — expanded CoButton fills width (trailing flush-right), Flutter+Web (#2391)

---

## 0.97.14 (2026-06-08)

### Fixed
- #2313 — co_menu 아이템 라벨 색 theme.colorScheme 하드코딩 → per-state CoreTextStyle 슬롯 (#2390)

---

## 0.97.13 (2026-06-07)

### Fixed
- #2317 — CoDatePicker initialView param 추가 (Flutter parity) (#2389)

---

## 0.97.12 (2026-06-07)

### Fixed
- #2317 — CoHover hoverStyle param 추가 (Flutter parity) (#2388)

---

## 0.97.11 (2026-06-07)

### Fixed
- #2317 — enabled nullable 정렬 (button/checkbox/radio_group/toggle, Flutter parity) (#2387)

---

## 0.97.10 (2026-06-07)

### Fixed
- #2319 — CoWindowActions IconButton.ghost+Material Icons → CoButton+CoIcon (#2386)

---

## 0.97.9 (2026-06-07)

### Fixed
- #2319 — card_image _wrapColor(toARGB32) round-trip 제거 (#2385)

---

## 0.97.8 (2026-06-07)

### Fixed
- #2319 — rating IconTheme.merge round-trip → resolver per-state CoreIconStyle (#2384)

---

## 0.97.7 (2026-06-07)

### Fixed
- #2319 — scroll_area/scrollable_client thumbColor CoreColor(toARGB32()) round-trip 제거 (#2383)

---

## 0.97.6 (2026-06-07)

### Fixed
- #2319 — sortable drag-proxy Material(elevation:) → CoUI BoxShadow (#2382)

---

## 0.97.5 (2026-06-07)

### Fixed
- #2322 — sb-guard-a-color-path Web multi-line color .toValue() → scheme.resolve + 가드 강화 (#2381)

---

## 0.97.4 (2026-06-07)

### Fixed
- #2337 UiComponent 승격 (룰 10) — 단일 styled-root 5 컴포넌트 (#2380)

---

## 0.97.3 (2026-06-07)

### Fixed
- #2346 Web typography 수동 emit → toInlineCss() (44 컴포넌트, letterSpacing/lineHeight 보정) (#2379)

---

## 0.97.2 (2026-06-07)

### Fixed
- #2310 Resolved concept-drift rename — tree chevronTurnsDuration → transitionDuration (#2378)

---

## 0.97.1 (2026-06-05)

### Fixed
- #2323 CoInput preview-test 회귀 — defaultTextStyle token form (tailwindTypographyRole throw 해소) (#2377)

---

## 0.97.0 (2026-06-05)

### Added
- #2362 Web parity — input_otp obscured dot + sortable drag proxy (Web Guard E→0) (#2376)

---

## 0.96.91 (2026-06-04)

### Fixed
- #2369 Web Resolver C 94→0 — 30 컴포넌트 number_ticker 전면 통일 (#2375)

---

## 0.96.90 (2026-06-04)

### Fixed
- #2369 Web Resolver C — hover_card behavioral timing → 별도 resolver (A 패턴 reference) (#2374)

---

## 0.96.89 (2026-06-04)

### Fixed
- #2369 Web Resolver Guard F(single-inline-signature) 1→0 — refresh_trigger gap (#2373)

---

## 0.96.88 (2026-06-04)

### Fixed
- #2369 Web Resolver Guard E(coverage) 16→3 — Flutter↔Web 필드 parity 복구 (#2372)

---

## 0.96.87 (2026-06-04)

### Fixed
- #2369 Web Resolver Guard D(chaining) 10건 0 — gap slot default + dial-code role 통합 (#2371)

---

## 0.96.86 (2026-06-04)

### Fixed
- #2312 guard-green — Flutter Resolver E + four-principle (5 컴포넌트) green 완성 (#2370)

---

## 0.96.85 (2026-06-04)

### Fixed
- #2312 guard-green — Resolver Guard D(40) + Web A(122) 전부 0 (#2368)

---

## 0.96.84 (2026-06-04)

### Documentation
- 인터랙션/Hover/Clickable 정공법을 CLAUDE.md + unify-component 스킬에 codify (#2367)

---

## 0.96.83 (2026-06-04)

### Fixed
- #2312 — sortable handle/remove chrome → CoreButtonStyle 통합 + removeButton error-hover 정통화 (#2366)

---

## 0.96.82 (2026-06-04)

### Fixed
- #2363 — CoreButtonStyle hover 색 per-instance override 추가 (idle/hover 비대칭 결함 해소) (#2364)

---

## 0.96.81 (2026-06-04)

### Fixed
- #2312 — co_formatted_input segmentGap/charWidth default 직접참조 제거 (#2360)

---

## 0.96.80 (2026-06-04)

### Fixed
- #2312 — co_input_otp obscured dot default 직접참조 + widget scaling 제거 (#2359)

---

## 0.96.79 (2026-06-04)

### Fixed
- #2312 — co_sortable widget default 직접참조 제거 (proxy) (#2357)
- pagination ellipsis letterSpacing fallback common-token leak 제거 (#2358)

---

## 0.96.78 (2026-06-04)

### Fixed
- pagination ellipsis letterSpacing fallback common-token leak 제거 (#2358)

---

## 0.96.77 (2026-06-04)

### Fixed
- Resolved durationMs → duration (A-패턴, Flutter 이름 일치) (#2355)

---

## 0.96.76 (2026-06-04)

### Fixed
- multiple_choice Resolved optionPadding axis 분해 제거 (룰 4) (#2354)

---

## 0.96.75 (2026-06-04)

### Fixed
- #2347 — typography 변환 color dark-mode + apply/merge 단일화 (#2353)

---

## 0.96.74 (2026-06-04)

### Fixed
- #2347 — letterSpacing em→px 변환 통일 (23 사이트 + scale 2중곱) (#2352)

---

## 0.96.73 (2026-06-04)

### Refactored
- #2347 — fontWeight int→FontWeight 변환 fontWeightFromInt 통합 (#2351)

---

## 0.96.72 (2026-06-04)

### Fixed
- #2348 — typography Tailwind 키 .scale 단일소스 배선 (#2350)

---

## 0.96.71 (2026-06-04)

### Fixed
- #2342 — Web typography override 완전화 (toInlineCss letterSpacing + 헬퍼 전환 + role 동적) (#2345)

---

## 0.96.70 (2026-06-04)

### Fixed
- #2313 — tree typography role 하드코딩 정정 (theme.typography.bodyMedium → resolveTypographyRole) (#2341)

---

## 0.96.69 (2026-06-04)

### Fixed
- #2313 — sb-state co_tree label 텍스트색 state → CoreTextStyle 슬롯 (#2340)

---

## 0.96.68 (2026-06-04)

### Refactored
- #2311 — Curves 토큰화 (#2339)

---

## 0.96.67 (2026-06-04)

### Refactored
- #2314 — sb-naming int? durationMs → Duration? duration (Hungarian Ms suffix 제거) (#2338)

---

## 0.96.66 (2026-06-04)

### Documentation
- CLAUDE.md 룰 9 (Resolved 비대칭 정당) + 룰 10 (Web base class) (#2336)

---

## 0.96.65 (2026-06-04)

### Refactored
- #2315 — orphan default const 삭제 (참조 0 dead code) (#2335)

---

## 0.96.64 (2026-06-04)

### Refactored
- #2333 — sb-resolver-sig Anti-B-1 local var scaling → return 이동 (#2334)

---

## 0.96.63 (2026-06-04)

### Refactored
- #2326 — sb-resolver-signature-unification followup (Anti-B-2 return 안 압축 분리) (#2332)

---

## 0.96.62 (2026-06-04)

### Refactored
- #2308 — sb-font-weight-resolution-dry 파일로컬 FontWeight helper 중복 제거 (#2331)

---

## 0.96.61 (2026-06-04)

### Fixed
- #2307 — sb-edgeinsets-axis-borrowing co_tree itemPadding axis 차용 제거 (#2330)

---

## 0.96.60 (2026-06-04)

### Fixed
- #2306 — sb-text-style-repackage unified widget 안 theme.typography.X.copyWith() 재포장 → resolver paint-ready TextStyle 슬롯 (#2329)

---

## 0.96.59 (2026-06-04)

### Fixed
- #2305 — sb-icon-style-repackage unified widget 안 CoIcon(iconStyle: CoreIconStyle()) 재포장 → Style 슬롯 (#2328)

---

## 0.96.58 (2026-06-04)

### Fixed
- #2304 — sb-gap-style-repackage unified widget 안 CoGap 1-off 재포장 → Style 슬롯 (#2327)

---

## 0.96.57 (2026-06-04)

### Documentation
- CLAUDE.md 룰 8 (legacy/@Deprecated sweep 제외) 추가 (#2325)

---

## 0.96.56 (2026-06-04)

### Documentation
- #2303 — CLAUDE.md 카탈로그 정합성 수정 (CoreBorderWidth 가상 enum → CoreStrokeWidth 실재 namespace) (#2324)

---

## 0.96.55 (2026-06-03)

### Fixed
- #2210 — sb-web-resolved-raw-double Web ResolvedCo* 안 raw double → domain (#2299)

---

## 0.96.54 (2026-06-03)

### Fixed
- #2210 — sb-anti-b-axis-extract resolver axis 추출 제거 (CoreEdgeInsets 통째) (#2298)

---

## 0.96.53 (2026-06-03)

### Fixed
- #2210 — sb-inset-to-edgeinsets raw double inset → CoreEdgeInsets (#2297)

---

## 0.96.52 (2026-06-03)

### Fixed
- #2210 — sb-duration-int-dedup int Ms default 중복 제거 (#2296)

---

## 0.96.51 (2026-06-03)

### Fixed
- #2210 — sb-resolver-signature-unification Anti-B 시그니처 통일 (8건) (#2295)

---

## 0.96.50 (2026-06-03)

### Fixed
- #2210 — sb-naming-cleanup hungarian suffix + axis prefix 제거 (#2294)

---

## 0.96.49 (2026-06-03)

### Fixed
- #2210 — sb-anti-g paint-ready → domain 역바운드 제거 (Anti-Pattern G) (#2293)

---

## 0.96.48 (2026-06-03)

### Fixed
- #2210 — sb-opacity-tokens raw 0.X → CoreOpacity tokens (9 components) (#2292)

---

## 0.96.47 (2026-06-03)

### Fixed
- #2210 — sb10 Web inline CSS + Tailwind axis 분해 정통화 (#2291)

---

## 0.96.46 (2026-06-03)

### Fixed
- #2210 — sb9b additive nested slots for child components (alert/banner/calendar/carousel/color_picker/sortable/toast) (#2290)

---

## 0.96.45 (2026-06-03)

### Fixed
- #2210 — sb9a chip_input chipStyle + drawer closeButtonStyle nested slot (#2289)

---

## 0.96.44 (2026-06-03)

### Fixed
- #2210 — sb8 followup remaining text color → CoreTextStyle slot (14 components) (#2288)

---

## 0.96.43 (2026-06-03)

### Fixed
- #2210 — sb8 text color/typography 분산 → CoreTextStyle nested slot (~30 components) (#2287)

---

## 0.96.42 (2026-06-02)

### Fixed
- #2210 — sb7 raw double *IconSize → CoreIconStyle nested slot (~26 components) (#2286)

---

## 0.96.41 (2026-06-02)

### Fixed
- #2210 — sb6 raw double gap → CoreGapStyle / xxxSpacing (4 components) (#2285)

---

## 0.96.40 (2026-06-02)

### Fixed
- #2210 — sb4+sb5 잔여 16건 + stale test sync (#2284)

---

## 0.96.39 (2026-06-02)

### Fixed
- #2210 — sb4-followup + sb5 padding/borderRadius → domain types (#2283)

---

## 0.96.38 (2026-06-02)

### Fixed
- #2210 — sb4 raw double padding → CoreEdgeInsets + axis rename (28 components) (#2282)

---

## 0.96.37 (2026-06-02)

### Documentation
- strengthen Anti-Pattern B with unified resolver signature (#2281)

---

## 0.96.36 (2026-06-02)

### Documentation
- add rule 2.4 — 필드 이름에 axis prefix/suffix 금지 (#2280)

---

## 0.96.35 (2026-06-02)

### Fixed
- #2210 — sb3 axis-decomposed padding → CoreEdgeInsets (20 components) (#2279)

---

## 0.96.34 (2026-06-02)

### Fixed
- #2210 — sb-shadow shadow axis decomposition removal (#2278)

---

## 0.96.33 (2026-06-02)

### Fixed
- #2210 — sb1 double default jossom dedup (#2277)

---

## 0.96.32 (2026-06-02)

### Documentation
- expand rule 2 with domain type catalog + child composition rule (#2276)

---

## 0.96.31 (2026-06-02)

### Fixed
- #2210 — single source defaults (MockupPhone width + Popover viewport) (#2275)

---

## 0.96.30 (2026-06-02)

### Fixed
- #2210 — viewportPadding 타입 정통화 (double? → CoreEdgeInsets?) (#2274)

---

## 0.96.29 (2026-06-02)

### Fixed
- #2210 — apply scaling to CoIcon resolver (Anti-Pattern F, PR 2/2) (#2273)

---

## 0.96.28 (2026-06-02)

### Fixed
- #2210 — nested Style slot raw forward 정통화 (PR 1/2 for CoIcon scaling) (#2272)

---

## 0.96.27 (2026-06-02)

### Documentation
- add "Layer Sub-batch 정통화 룰" section (#2270)

---

## 0.96.26 (2026-06-01)

### Refactored
- Batch 5 — alert/drawer/swiper/toast RULE E (10 fields) (#2259)

---

## 0.96.25 (2026-06-01)

### Refactored
- Batch 4 — sortable/text_area/text_field/accordion/card/focus_outline/tabs RULE E (#2258)

---

## 0.96.24 (2026-06-01)

### Refactored
- Batch 3 — formatted_input/input/phone_input/code_snippet/color_picker/rating RULE E (#2257)

---

## 0.96.23 (2026-06-01)

### Refactored
- Batch 2 — button/fab/avatar/banner/code_snippet RULE E (5 components, badge skip) (#2256)

---

## 0.96.22 (2026-06-01)

### Refactored
- Batch 1 — select + dropdown_menu RULE E coverage (Flutter 91→12) (#2255)

---

## 0.96.21 (2026-06-01)

### Refactored
- #2228 Theme-Style 슬롯 정통화 sweep — 7 Themes (#2248)

---

## 0.96.20 (2026-06-01)

### Refactored
- #2228 Anti F (resolver scaling missing) cleanup — 23 files (#2247)

---

## 0.96.19 (2026-06-01)

### Refactored
- #2228 Anti C cleanup (19) + KeyboardShortcut Theme 정통화 (#2246)

---

## 0.96.18 (2026-06-01)

### Refactored
- #2228 Group 15 (D-cat) + interleave eradication sweep (#2245)

---

## 0.96.17 (2026-06-01)

### Refactored
- #2228 Group 14 (C-cat) — Padding/Offset 의미명 rename (#2244)

---

## 0.96.16 (2026-06-01)

### Refactored
- #2228 Group 13 (B-cat) — 10 컴포넌트 native Row/Column/Wrap.spacing rename (#2243)

---

## 0.96.15 (2026-06-01)

### Refactored
- #2228 Group 12 — TimePicker/Tracker/ValidatorHint/WindowPanel/ValidationBadge (#2242)

---

## 0.96.14 (2026-06-01)

### Refactored
- #2228 Group 11 — Sortable/Stepper/Steps/SwitchField/Timeline/RefreshTrigger (#2241)

---

## 0.96.13 (2026-06-01)

### Refactored
- #2228 Group 10 — Range/Rating/Select (+ correct mis-classification) (#2240)

---

## 0.96.12 (2026-06-01)

### Refactored
- #2228 fix mis-classified 12 components — GapStyle 환원 → double Spacing (균등분포 native API) (#2239)

---

## 0.96.11 (2026-06-01)

### Refactored
- #2228 Group 9 — MockupWindow/MultipleChoice/NavigationMenu/PhoneInput/RadioGroup + Anti A radio_group (#2238)

---

## 0.96.10 (2026-06-01)

### Refactored
- #2228 Group 8 — Fab/Footer/ItemPicker/Listing/Menu (#2237)

---

## 0.96.9 (2026-06-01)

### Refactored
- #2228 Group 7 — ColorPicker/Command/DatePicker/Dialog/Dock (#2236)

---

## 0.96.8 (2026-06-01)

### Refactored
- #2228 Group 6 — Calendar/Chat/ChipGroup/ChipInput/EmptyState (#2235)

---

## 0.96.7 (2026-06-01)

### Refactored
- #2228 Group 5 — Card/CardImage/DescriptionCard + Anti A fix (#2234)

---

## 0.96.6 (2026-06-01)

### Refactored
- #2228 Group 4 — Label/Kbd/Basic/Breadcrumb/Collapsible + Anti A breadcrumb (#2233)

---

## 0.96.5 (2026-06-01)

### Refactored
- #2228 Group 3 — Form/FormField/FormControl/FormLabel/Fieldset (#2232)

---

## 0.96.4 (2026-06-01)

### Refactored
- #2228 Group 2 — Button/Chip/Toggle/Checkbox (#2231)

---

## 0.96.3 (2026-06-01)

### Refactored
- #2228 Group 1 — Alert/Badge/Banner/Toast/Validated + CoGap self-scale (#2230)

---

## 0.96.2 (2026-06-01)

### Documentation
- Epic foundation — CLAUDE.md gap/spacing rule + 7 CI guards (baseline-only) (#2229)

---

## 0.96.1 (2026-06-01)

### Fixed
- 🐛 CoInputOtp 셀이 좁은 컨테이너에서 넘치지 않도록 FittedBox scaleDown 적용 (#2226)

---

## 0.96.0 (2026-05-31)

### Added
- #2205 — CoreButtonVariant.plain (muted content-fade hover) (#2209)

### Documentation
- #2202 — gap/margin 의 `Rem` 접미사 허용 명문화 + 가드 확장 (#2204)

---

## 0.95.34 (2026-05-31)

### Refactored
- #1659 — Co* 조합 통일 (#2200)

---

## 0.95.33 (2026-05-31)

### Refactored
- #1659 — Web raw input→CoTextField parity (#2196)

---

## 0.95.32 (2026-05-31)

### Refactored
- #1659 — Co* 조합 통일(safe 부분) (#2195)

---

## 0.95.31 (2026-05-31)

### Refactored
- #1659 — Co* 조합 통일(safe 부분) (#2194)

---

## 0.95.30 (2026-05-31)

### Refactored
- #1659 — Co* 조합 통일(safe 부분) (#2189)

---

## 0.95.29 (2026-05-31)

### Refactored
- #1659 — Co* 조합 통일(safe 부분) (#2187)

---

## 0.95.28 (2026-05-31)

### Refactored
- #1659 — Co* 조합 통일(safe 부분) (#2182)

---

## 0.95.27 (2026-05-31)

### Refactored
- #1659 — Co* 조합 통일 (#2178)

---

## 0.95.26 (2026-05-31)

### Refactored
- #1659 — Co* 조합 통일 (#2173)

---

## 0.95.25 (2026-05-31)

### Refactored
- #1659 — Co* 조합 통일 (#2167)

---

## 0.95.24 (2026-05-31)

### Refactored
- #1659 — Co* 조합 통일 (#2161)

---

## 0.95.23 (2026-05-31)

### Refactored
- #1659 — Co* 조합 통일 (#2156)

---

## 0.95.22 (2026-05-31)

### Refactored
- #1659 — Co* 조합 통일 (#2153)

---

## 0.95.21 (2026-05-31)

### Refactored
- #1659 — Co* 조합 통일 (#2148)

---

## 0.95.20 (2026-05-31)

### Fixed
- CoSeparator Flutter 색상 토큰 scheme 해석 (Flutter↔Web 색 불일치) (#2143)

### Refactored
- #1659 — separator 여백을 CoreEdgeInsets 도메인 타입으로 (컨벤션 정정) (#2142)
- defaultColorFor → static const defaultColor + 멤버 순서 정리 (#2144)

---

## 0.95.19 (2026-05-31)

### Refactored
- defaultColorFor → static const defaultColor + 멤버 순서 정리 (#2144)

---

## 0.95.18 (2026-05-31)

### Fixed
- CoSeparator Flutter 색상 토큰 scheme 해석 (Flutter↔Web 색 불일치) (#2143)

---

## 0.95.17 (2026-05-31)

### Fixed
- #1659 — Web divider 여백을 CoSeparator css 가 아닌 래퍼로 (Flutter 미러) (#2141)

---

## 0.95.16 (2026-05-31)

### Refactored
- #1659 — divider 를 CoSeparator 조합으로 통일 (파일럿) (#2140)

---

## 0.95.15 (2026-05-30)

### Fixed
- #2136 — CoScrollableClient 2D 뷰포트 리사이즈 시 빈 화면/크래시 (orphan child) (#2138)

---

## 0.95.14 (2026-05-30)

### Fixed
- #2136 — scrollable_client/table 프리뷰 안 보임 (2D 뷰포트 first-paint canvas-lock) (#2137)

---

## 0.95.13 (2026-05-30)

### Fixed
- 색-렌더 잔여 6건 — bare CSS var 투명 + inline-vs-pseudo (#2135)

---

## 0.95.12 (2026-05-30)

### Fixed
- tracker 안 보임 — CoTooltip consumer classes 를 root 에 적용 (0-width 세그먼트) (#2133)

---

## 0.95.11 (2026-05-30)

### Fixed
- #2129 — docs SSR 빌드 복구 (chat toRgba / window SSR DOM / tracker.md 손상) (#2131)

---

## 0.95.10 (2026-05-30)

### Fixed
- #2129 — widgetbook CoGap(size:) → gapStyle 마이그 (배포/CI 차단 해소) (#2130)

---

## 0.95.9 (2026-05-30)

### Fixed
- #2126 #2127 — textArea focus 테두리색 + textField focus content 가림 (#2128)

---

## 0.95.8 (2026-05-30)

### Fixed
- #2122 #2123 — inline 토큰 색상 투명 + unresolved-token ARGB 크래시 (#2125)

---

## 0.95.7 (2026-05-30)

### Fixed
- #1603 — Flutter color-path #1601 회귀 일소 + lint widget 확장 (#2121)

---

## 0.95.6 (2026-05-30)

### Fixed
- #1603 — file_input dashed painter .topLeft.x reach-in 제거 (#2116)

---

## 0.95.5 (2026-05-28)

### Documentation
- unify-component 룰 (v) 추가 — CoreXxxTokens 파일 폐기 + 4-side 어댑터 강제 (#1695)

---

## 0.95.4 (2026-05-27)

### Fixed
- star_rating Web — scheme.resolve(c).toValue() 정공법 통일 (#1652)

---

## 0.95.3 (2026-05-27)

### Fixed
- star_rating PoC 패턴 통일 — dead code 삭제 + scheme.resolve(c).toValue() 정공법 (#1651)

---

## 0.95.2 (2026-05-27)

### Fixed
- #1648 A 카테고리 통일 — scheme.resolveColor 폐기 + scheme.resolve(c).toValue() 두 단계 (#1650)

---

## 0.95.1 (2026-05-27)

### Fixed
- #1648 Phase 9-12 정공법 재마이그 + kRemDivisor 통일 + design-token-guard escape hatch (#1649)

---

## 0.95.0 (2026-05-27)

### Added
- #1646 모든 토큰 카테고리 CSS variable single-source 통일 (#1647)

---

## 0.94.12 (2026-05-26)

### Fixed
- #1615 Phase 12 — Design Token Guard phase 6 final cleanup (E 카테고리 완료) (#1645)

---

## 0.94.11 (2026-05-26)

### Fixed
- #1614 Phase 11 — window left/top/width/height/thickness px → rem (#1644)

---

## 0.94.10 (2026-05-26)

### Fixed
- #1613 Phase 10 — focus_outline radius9999 + outlined_container border-width px → rem (#1643)

---

## 0.94.9 (2026-05-26)

### Fixed
- #1612 Phase 9 — letter-spacing px → rem (6 컴포넌트) (#1642)

---

## 0.94.8 (2026-05-26)

### Fixed
- #1611 Phase 8 — overflow_marquee _mapCurve → CoreMarqueeCurve.toValue() (#1641)

---

## 0.94.7 (2026-05-26)

### Fixed
- #1610 Phase 7 — badge token resolution sweep (#1640)

---

## 0.94.6 (2026-05-26)

### Fixed
- #1609 Phase 6 — chip token resolution sweep (#1639)

---

## 0.94.5 (2026-05-26)

### Fixed
- #1608 Phase 5 — focus_outline token resolution sweep (#1638)

---

## 0.94.4 (2026-05-26)

### Fixed
- #1607 Phase 4 — card_image token resolution sweep (#1637)

---

## 0.94.3 (2026-05-26)

### Fixed
- #1606 Phase 3 — file_input token resolution sweep (#1636)

---

## 0.94.2 (2026-05-26)

### Fixed
- #1605 Phase 2 — text_field token resolution sweep (#1635)

---

## 0.94.1 (2026-05-26)

### Fixed
- #1604 alert AB 검증 — dcm arguments-ordering 1건 fix (#1634)

---

## 0.94.0 (2026-05-26)

### Added
- #1601 PoC — Resolver/Resolved Style Contract for button + alert + card (#1602)

---

## 0.93.4 (2026-05-22)

### Documentation
- Resolver/Resolved Style Contract 설계 RFC 추가 (#1578)

---

## 0.93.3 (2026-05-20)

### Refactored
- ♻️ chat/command/fab 등 Co* API 마이그레이션 + filter_tokens import 수정 (#1539)

---

## 0.93.2 (2026-05-18)

### Documentation
- 🗂️ 전체 컴포넌트 위반 인벤토리 + sweep batch plan (#1486)

---

## 0.93.1 (2026-05-18)

### Documentation
- 🧭 /unify-component — Phase 6f 반영 + Styling marker anti-pattern 정정 (#1483)

---

## 0.93.0 (2026-05-18)

### Added
- 🧱 그룹 B 부분 — DropdownMenu + Pagination implements contract (#1482)

---

## 0.92.5 (2026-05-15)

### Fixed
- 🐛 jaspr build 깨짐 — unresolved token toRgba 호출 + Phase 1 pubspec 회귀 (#1469)

---

## 0.92.4 (2026-05-15)

### Refactored
- 🧱 variant_style 15개 흡수 — Epic #1415 acceptance criteria 완료 (#1463)

---

## 0.92.3 (2026-05-15)

### Fixed
- 🧪 theme_data_test 10 failure 수정 (#1462)

---

## 0.92.2 (2026-05-15)

### Refactored
- 🧱 Phase 6f — Style/Theme/Contract phantom generic 완전 제거 (75+ 컴포넌트) (#1461)

---

## 0.92.1 (2026-05-14)

### Refactored
- 🧱 Color System Unification — CoreColor 단일 + ThemeData.colorScheme 양 플랫폼 통일 (#1460)

---

## 0.92.0 (2026-05-13)

### Added
- ✨ CoreDrawerStyle 에 panelPadding 필드 추가 (#1458)

---

## 0.91.9 (2026-05-12)

### Refactored
- 🔧 옵션 A defaults — Display C 첫 컴포넌트 (#1450)

---

## 0.91.8 (2026-05-12)

### Refactored
- 🔧 옵션 A defaults — overflow_marquee / divider / breadcrumb / separator (#1439) (#1449)

---

## 0.91.7 (2026-05-12)

### Refactored
- 🔧 옵션 A — per-variant Defaults class (Material `_FilledCardDefaultsM3` pattern) (#1434)

---

## 0.91.6 (2026-05-12)

### Documentation
- switch defaults pattern to Material's per-variant Defaults class (옵션 A) (#1433)

---

## 0.91.5 (2026-05-12)

### Refactored
- apply single-entry-point resolver to 12 Flutter components (Phase 2 batch 1) (#1413)

---

## 0.91.4 (2026-05-12)

### Documentation
- add single-entry-point resolver pattern guide (#1409)

---

## 0.91.3 (2026-05-12)

### Refactored
- remove nested Style API from gap/swap/indicator/keyboard_shortcut (#1408)

---

## 0.91.2 (2026-05-12)

### Fixed
- preexisting 테스트 6 케이스 정리 (#1407)

---

## 0.91.1 (2026-05-12)

### Fixed
- chip_input/validation_badge/pagination 테스트 + golden 재생성 (#1406)

---

## 0.91.0 (2026-05-12)

### Added
- nested Style API 도입 + Object? color → <Clr> generic (#1405)

---

## 0.90.0 (2026-05-12)

### Added
- add nested Style API to 6 components (skip mask) (#1404)

---

## 0.89.25 (2026-05-11)

### Refactored
- :art: window/window_panel 컴포넌트 nested Style API 추가 (#1398)

---

## 0.89.24 (2026-05-11)

### Refactored
- :art: footer/form_field/listing/phone_input/sortable/steps/switch_field/tracker 컴포넌트 nested Style API 추가 (#1397)

---

## 0.89.23 (2026-05-11)

### Refactored
- :art: basic/code_diff/code_snippet/collapsible/dock/empty_state/fieldset/file_input 컴포넌트 nested Style API 추가 (#1396)

---

## 0.89.22 (2026-05-11)

### Refactored
- :art: card_image/divider/frame/hero_section/input_otp/mockup_browser/responsive_container/stage_container/stat 컴포넌트 nested Style API 추가 (#1395)

---

## 0.89.21 (2026-05-11)

### Refactored
- :art: number_ticker/resizable/star_rating/status/mockup_window 컴포넌트 nested Style API 추가 (#1394)

---

## 0.89.20 (2026-05-11)

### Refactored
- 🎨 kbd/skeleton/label/stepper/table Theme chrome → Style 통합 (#1392)

---

## 0.89.19 (2026-05-11)

### Refactored
- rename _style.dart -> _resolver.dart for 25 components + ResolvedCo* unify (#1391)

---

## 0.89.18 (2026-05-11)

### Refactored
- rename _style.dart -> _resolver.dart for 16 layout components + ResolvedCo* unify (#1390)

---

## 0.89.17 (2026-05-11)

### Refactored
- rename _style.dart -> _resolver.dart for 16 layout components + ResolvedCo* unify (#1389)

---

## 0.89.16 (2026-05-11)

### Refactored
- rename _style.dart -> _resolver.dart for 10 components + ResolvedCo* unify (#1388)

---

## 0.89.15 (2026-05-11)

### Refactored
- 🧹 form picker/group _style → _resolver rename + ResolvedCo* 갈래 B' (#1387)

---

## 0.89.14 (2026-05-11)

### Refactored
- 🧹 toggle_style → toggle_resolver rename + ResolvedCoToggle 갈래 B' (#1386)

---

## 0.89.13 (2026-05-11)

### Refactored
- 🧹 slider_style → slider_resolver rename + ResolvedCoSlider 갈래 B' (#1385)

---

## 0.89.12 (2026-05-11)

### Refactored
- 🧹 button/text_field/text_area/checkbox resolver 갈래 B' — widget 이 resolved 만 참조 (#1384)

---

## 0.89.11 (2026-05-11)

### Refactored
- 🧹 ResolvedCoCheckbox 갈래 B 정공법 + checkbox_style → checkbox_resolver rename (#1383)

---

## 0.89.10 (2026-05-11)

### Refactored
- 🧹 ResolvedCoTextField 갈래 B 정공법 + resolver rename (#1382)

---

## 0.89.9 (2026-05-11)

### Refactored
- 🧹 button_style → button_resolver rename + ResolvedCoButton 갈래 B 정공법 (#1381)

---

## 0.89.8 (2026-05-11)

### Refactored
- 🧹 button Resolved 클래스 폐기 — Option B 패턴 PoC (#1380)

---

## 0.89.7 (2026-05-11)

### Refactored
- 🧹 tree/progress/button Theme legacy chrome → Style (#1378)

---

## 0.89.6 (2026-05-11)

### Refactored
- 🧹 timeline.dotSize + table.viewport* → Style + timeline gap/spacing → rowGap/columnGap rename (#1377)

---

## 0.89.5 (2026-05-11)

### Refactored
- 🧹 avatar.badgeGap + button.dashedBorder/dashedBorderColor → Style + Web dashedBorder 실제 렌더 구현 (#1376)

---

## 0.89.4 (2026-05-11)

### Refactored
- 🧹 chip_group sub-Style → CoreTextStyle + composite-layout 예외 폐기 + description_card typedef alias 제거 (#1375)

---

## 0.89.3 (2026-05-11)

### Refactored
- 🧹 description_card 정공법 일괄 정리 — emphasis/row sub-Style 제거 + FW generic 축소 + chrome 통합 (#1374)

---

## 0.89.2 (2026-05-11)

### Refactored
- 🧹 6 Theme legacy chrome 제거 (avatar/hover_gallery/progress/separator/skeleton/table) (#1373)

---

## 0.89.1 (2026-05-11)

### Refactored
- 🧹 6 Theme legacy chrome 제거 + diff/accordion/focus_outline 시각 chrome Style 통합 (#1372)

---

## 0.89.0 (2026-05-11)

### Added
- 🎨 Phase 7 atomic Style — join / kbd / label / mockup_code / mockup_phone (#1369)

---

## 0.88.0 (2026-05-11)

### Added
- 🎨 Phase 7 atomic Style — countdown / diff / dot_indicator / focus_outline / hover_gallery (#1368)

---

## 0.87.6 (2026-05-11)

### Refactored
- 🧹 avatar/accordion/stepper/timeline/table chrome param → Style (#1366)

---

## 0.87.5 (2026-05-11)

### Refactored
- 🧹 badge/chip/banner/alert chrome param → Style 통합 (#1365)

---

## 0.87.4 (2026-05-11)

### Refactored
- 🧹 separator/progress/loading/skeleton chrome param → Style 통합 (#1364)

---

## 0.87.3 (2026-05-11)

### Documentation
- 🧹 Migration 섹션 제거 + Style/Resolve 보강 + skill 7-6 추가 (#1356)

---

## 0.87.2 (2026-05-11)

### Refactored
- 🧹 Co atomic sweep — Stack/Positioned + DCM gate in skill (#1355)

---

## 0.87.1 (2026-05-09)

### Refactored
- 🎨 Carousel/Timeline/Tree/Table nested Style API widget migration (#1354)

---

## 0.87.0 (2026-05-09)

### Added
- 🎨 CoreCarouselStyle + CoreTimelineStyle + CoreTreeStyle + CoreTableStyle (#1353)

---

## 0.86.1 (2026-05-09)

### Refactored
- 🎨 Tabs/Stepper/Breadcrumb/Pagination nested Style API widget migration (#1352)

---

## 0.86.0 (2026-05-09)

### Added
- 🎨 CoreTabsStyle + CoreStepperStyle + CoreBreadcrumbStyle + CorePaginationStyle (#1351)

---

## 0.85.1 (2026-05-09)

### Refactored
- 🎨 Banner/Alert/Accordion nested Style API widget migration (#1350)

---

## 0.85.0 (2026-05-09)

### Added
- 🎨 CoreBannerStyle + CoreAlertStyle + CoreAccordionStyle (#1349)

---

## 0.84.1 (2026-05-09)

### Refactored
- 🎨 Badge/Chip/Avatar nested Style API widget migration (#1348)

---

## 0.84.0 (2026-05-09)

### Added
- 🎨 CoreBadgeStyle + CoreChipStyle + CoreAvatarStyle (#1347)

---

## 0.83.1 (2026-05-09)

### Refactored
- 🎨 DropdownMenu/Menu/Menubar/ContextMenu nested Style API (#1346)

---

## 0.83.0 (2026-05-09)

### Added
- 🎨 CoreDropdownMenuStyle + Theme + Contract (#1345)

---

## 0.82.1 (2026-05-09)

### Refactored
- 🎨 ColorPicker nested Style API migration (#1344)

---

## 0.82.0 (2026-05-08)

### Added
- ✨ CoreTimePickerStyle composite nested API (Phase 4) (#1343)

---

## 0.81.0 (2026-05-08)

### Added
- ✨ CoreDatePickerStyle composite nested API (Phase 4) (#1342)

---

## 0.80.0 (2026-05-08)

### Added
- ✨ CoreCalendarStyle nested API (Phase 4) (#1341)

---

## 0.79.0 (2026-05-08)

### Added
- ✨ CoreSelectStyle composite nested API (Phase 4) (#1340)

---

## 0.78.1 (2026-05-08)

### Documentation
- toast.md 스타일 시스템 섹션 보완 (#1339)

---

## 0.78.0 (2026-05-08)

### Added
- ✨ CoreTooltipStyle nested API + Story #1310 완결 (Phase 3) (#1338)

---

## 0.77.0 (2026-05-08)

### Added
- ✨ CoreToastStyle nested API + variant 위젯 파라미터 (Phase 3) (#1337)

---

## 0.76.0 (2026-05-08)

### Added
- ✨ CoreDrawerStyle nested API + open/close anim split (Phase 3) (#1336)

---

## 0.75.0 (2026-05-08)

### Added
- ✨ CoreDialogStyle nested API + popover anim split (Phase 3) (#1335)

---

## 0.74.0 (2026-05-08)

### Added
- ✨ CorePopoverStyle nested API + triggerStyle 슬롯 (Phase 3) (#1334)

---

## 0.73.0 (2026-05-08)

### Added
- ✨ CoreSliderStyle nested API + Story #1308 완결 (Phase 2) (#1333)

---

## 0.72.0 (2026-05-08)

### Added
- ✨ CoreToggleStyle nested API + variant 위젯 파라미터 (Phase 2) (#1332)

---

## 0.71.0 (2026-05-08)

### Added
- ✨ CoreRadioGroupStyle nested API + variant 위젯 파라미터 (Phase 2) (#1331)

---

## 0.70.0 (2026-05-08)

### Added
- ✨ CoreCheckboxStyle nested API + variant 위젯 파라미터 (Phase 2) (#1330)

---

## 0.69.0 (2026-05-08)

### Added
- ✨ CoreTextFieldStyle nested API + TextArea 공유 (Phase 2) (#1329)

---

## 0.68.0 (2026-05-08)

### Added
- ✨ CoreButtonStyle nested API + variant 위젯 파라미터 분리 (Phase 2) (#1328)

---

## 0.67.0 (2026-05-08)

### Added
- ✨ CoreOutlinedContainerStyle nested API + transparent-border collapse (#1327)

---

## 0.66.0 (2026-05-08)

### Added
- ✨ CoreCardStyle nested Style API + CoCard 마이그 (#1326)

---

## 0.65.0 (2026-05-08)

### Added
- ✨ CoreTextStyle 통합 (Flutter TextStyle 패턴) — typography spec + Layer 2 override (#1325)

---

## 0.64.0 (2026-05-08)

### Added
- ✨ CoreIconStyle / CoIcon nested Style API (Phase 1 Leaf) (#1324)

---

## 0.63.0 (2026-05-08)

### Added
- ✨ trigger style 분리 + theme/contract 1:1 + resolver core 통합 (#1301)

---

## 0.62.0 (2026-05-08)

### Added
- ✨ CoTimePicker 풀 통일 + CoPopover/CoButton/CoIcon + style 분리 + theme tristate (#1300)

---

## 0.61.0 (2026-05-07)

### Added
- ✨ CoCheckbox 통일 마무리 + scale/opacity 애니메이션 + theme tristate (#1299)

---

## 0.60.0 (2026-05-07)

### Added
- ✨ CoSelect 통일 마무리 + CoPopover 마이그레이션 + theme/style + verify 23 항목 통과 (#1297)

---

## 0.59.0 (2026-05-07)

### Added
- ✨ CoTextArea 통일 마무리 + selectAllOnFocus / interaction policy theme 화 + Web 2파일 구조 (#1295)

---

## 0.58.1 (2026-05-07)

### Fixed
- 🐛 web preview pane cross-axis 통일 + carousel intrinsic sizing (#1292)

---

## 0.58.0 (2026-05-07)

### Added
- ✨ CoFieldset 통일화 + CoTextField placeholder + CoUIWeb root w-full (#1291)

---

## 0.57.0 (2026-05-07)

### Added
- ✨ CoDatePicker mode/range 양쪽 통일 + CoPopover outside-click 정확 검사 + ColorPicker variant text 바인딩 (#1289)

---

## 0.56.1 (2026-05-06)

### Fixed
- 🐛 단일 TextField + SMS autofill 지원 (iOS 키보드 깜빡임 + 자동입력 fix) (#1288)

---

## 0.56.0 (2026-05-06)

### Added
- ✨ CoDrawer shadcn-style modal overlay (Flutter + Web 통일) (#1287)

---

## 0.55.0 (2026-05-06)

### Added
- Web overlay portal — Tooltip / HoverCard / Dialog (#1279, #1281, #1282) (#1285)

---

## 0.54.0 (2026-05-06)

### Added
- ✨ CoColorPicker 양 플랫폼 통일 — CoPopover 마이그레이션 + RecentColorsScope + 시각/동작 패리티 (#1284)

---

## 0.53.0 (2026-05-06)

### Added
- ✨ CoUIWeb overlay portal + Flutter parity (popover, animation tokens, CoUIApp 16-param) (#1276)

---

## 0.52.1 (2026-05-06)

### Fixed
- 🐛 CoButton radius 미적용 회귀 — radiusRole(String) → radius(double/String) type-safe (#1275)

---

## 0.52.0 (2026-05-05)

### Added
- ColorPicker + Popover 통일 — controller API / 시각 패리티 / verify 23개 통과 (#1274)

---

## 0.51.3 (2026-05-04)

### Refactored
- ♻️ CoreStrokeWidth.medium (1.5px) 완전 제거 (#1268) (#1273)

---

## 0.51.2 (2026-05-04)

### Refactored
- ♻️ CoreBorderWidth → CoreStrokeWidth (spec 클래스명 정합) (#1271) (#1272)

---

## 0.51.1 (2026-05-03)

### Refactored
- ♻️ deprecated 시맨틱 토큰 전수 제거 (#1269) (#1270)

---

## 0.51.0 (2026-05-03)

### Added
- ✨ CoreEasingFunction 9개 non-cubic-bezier easing 수학 구현 (#1266) (#1267)

---

## 0.50.0 (2026-05-03)

### Added
- ✨ CoreEasing CSS 변수 자동 생성 (#1262) (#1263)

---

## 0.49.1 (2026-04-30)

### Refactored
- ♻️ deprecated primitive 토큰 사용처 spec 네이밍 마이그레이션 (#1255) (#1261)

---

## 0.49.0 (2026-04-30)

### Added
- ✨ Easing primitive 토큰 + Curve 어댑터 (#1254) (#1260)

---

## 0.48.0 (2026-04-30)

### Added
- ✨ CoreShadow → BoxShadow 어댑터 (#1256) (#1259)

---

## 0.47.0 (2026-04-30)

### Added
- ✨ Content-Padding semantic 토큰 spec 반영 (#1257) (#1258)

---

## 0.46.0 (2026-04-30)

### Added
- ✨ primitive 디자인 토큰 spec 8개 카테고리 반영 (#1252) (#1253)

---

## 0.45.0 (2026-04-30)

### Added
- display atomic 컴포넌트 12종 Web/Flutter 디자인 패리티 (#1249)

---

## 0.44.2 (2026-04-29)

### Fixed
- 🐛 dart2js 환경 isDialogOverlay 회귀 — InheritedWidget marker 로 대체 (#1248)

---

## 0.44.1 (2026-04-29)

### Fixed
- 🐛 _DialogOverlayWrapper 가 Model<#coui_flutter_dialog_overlay> 를 inherit 하도록 수정 (#1247)

---

## 0.44.0 (2026-04-29)

### Added
- ✨ CoSelect search 지원 (옵션 필터링) (#1242) (#1246)

---

## 0.43.0 (2026-04-29)

### Added
- ✨ CoSelect generic 타입 지원 (#1241) (#1245)

---

## 0.42.0 (2026-04-29)

### Added
- ✨ CoSelect 옵션에 custom Widget rendering 지원 (#1243) (#1244)

---

## 0.41.0 (2026-04-29)

### Added
- 양쪽 플랫폼 Text chain 통일 + 후속 hotfix (#1225)

---

## 0.40.0 (2026-04-29)

### Added
- jaspr 플랫폼 지원 추가 및 컴포넌트 예제 확장 (#1224)

---

## 0.39.0 (2026-04-27)

### Added
- 인프라 컴포넌트 4종 통일 (FocusOutline / StackLayout / OutlinedContainer / InputOtp) (#1222)

---

## 0.38.1 (2026-04-27)

### Fixed
- preview_rendering_test 의 legacy Alert 참조 → CoAlert 교체 (#1221)

---

## 0.38.0 (2026-04-24)

### Added
- CardImage / Swap / Timeline / TreeView / Alert 통일화 (#1220)

---

## 0.37.0 (2026-04-24)

### Added
- Layout Phase 3 — ScrollableClient / StackLayout / StageContainer / WindowPanel / Window unify (#1205)

---

## 0.36.3 (2026-04-23)

### Refactored
- ♻️ [S3/4] info-level lint 경고 일괄 정리 (#1199)

---

## 0.36.2 (2026-04-23)

### Fixed
- 🐛 [S2/4] lightDefaultColor/darkDefaultColor M3 semantic tokens 추가 (#1197)

---

## 0.36.1 (2026-04-23)

### Refactored
- ♻️ [S1/4] generated_themes.dart legacy deprecated ignore (#1196)

---

## 0.36.0 (2026-04-23)

### Added
- Gap 패키지 완전 내재화 — CoGap 자체 구현 + CoMaxGap/CoSliverGap 신규 + crossAxisExtent/color 지원 (#1194) (#1195)

---

## 0.35.0 (2026-04-23)

### Added
- #1073 Layout Phase 2 — 12 컴포넌트 unify + Phase 6 sweep + CoCard child padding fix (#1193)

### Refactored
- 🔥 deprecated Gap wrapper 클래스 제거 + 내부 사용 CoGap 전환 (#1192)

---

## 0.34.7 (2026-04-23)

### Refactored
- 🔥 deprecated Gap wrapper 클래스 제거 + 내부 사용 CoGap 전환 (#1192)

---

## 0.34.6 (2026-04-23)

### Refactored
- ♻️ [S4] Foundation deprecated API 67건 마이그레이션 (#1185)

---

## 0.34.5 (2026-04-22)

### Refactored
- ♻️ [S6] Icon & 기타 inline px → rem 전환 (#1154) (#1161)

---

## 0.34.4 (2026-04-22)

### Refactored
- ♻️ [S5] Layout 컴포넌트 inline px → rem 전환 (#1153) (#1160)

---

## 0.34.3 (2026-04-22)

### Refactored
- ♻️ [S4] Overlay 컴포넌트 inline px → rem 전환 (#1152) (#1159)

---

## 0.34.2 (2026-04-22)

### Refactored
- ♻️ [S3] Display 컴포넌트 inline px → rem 전환 (#1151) (#1158)

---

## 0.34.1 (2026-04-22)

### Refactored
- ♻️ [S2] Form 컴포넌트 inline px → rem 전환 (#1150) (#1157)

---

## 0.34.0 (2026-04-22)

### Added
- ✨ [S1] CSS variable 인프라 — --coui-space/size/font-size/border-width (#1156)

---

## 0.33.0 (2026-04-21)

### Added
- CoSelect unify-component (파트 1) + FloatingController 통합 (#1113) (#1128)

---

## 0.32.1 (2026-04-21)

### Refactored
- Table 시리즈 통일화 + 파일 구조 표준화 (#1073) (#1127)

---

## 0.32.0 (2026-04-21)

### Added
- base/floating 엔진 — positioner·collision·portal·scroll·outside·registry (#1111) (#1126)

---

## 0.31.0 (2026-04-21)

### Added
- CoreFormFieldError + Severity/ValidationTrigger enums (#1119) (#1124)
- CorePopoverPlacement → Alignment/Offset extension (#1112) (#1125)

---

## 0.30.0 (2026-04-21)

### Added
- CorePopoverPlacement 12방향 확장 + Collision/Defaults (#1110) (#1123)

---

## 0.29.0 (2026-04-20)

### Added
- /unify-component Icon 스킬 전체 워크플로우 실행
- Web 통일화 — dialog/tooltip/icon 2파일 구조 + 레거시 삭제
- Web 통일화 — 7개 Co 컴포넌트 2파일 구조 + 레거시 완전 삭제
- Web 통일화 — 21개 Co 컴포넌트 2파일 구조 + 레거시 완전 삭제
- Web 통일화 — 8개 Co 컴포넌트 2파일 구조 + 레거시 완전 삭제
- CoGap 2파일 구조 + 레거시 삭제
- CoResizable 통일화 + Web 레거시 완전 삭제
- CoGap 통일 — contract + Flutter/Web 구현 + docs
- CoTree 통일 (#1073)
- CoStepper 통일 완료 (#1073)
- CoSteps 통일 (#1073)
- CoJoin 통일 (#1073)
- CoCollapsible 통일 (#1073)
- CoCard 통일 (#1073)
- CoAccordion 통일 (#1073)
- CoSeparator 통일 + coui_web core 전체 re-export (#1073)

### Fixed
- 시각 파리티 + screenshot 검증 tool 추가
- Flutter IconTheme fallback 제거 — 다크모드 전환 반영
- 스킬 규칙 위반 3건 수정 (토큰, 크기, 다크모드)
- 예제에서 수동 Container/div 대신 CoButton 사용
- Tree Flutter 코드 스니펫을 example(StatelessWidget)과 동기화
- Flutter Tree/Stepper clickable 요소에 MouseRegion 커서 추가
- CoTree 재검증 — 디자인 파리티 + callback 통일
- CoStepper 재검증 — Card 색상 패턴 + 디자인 파리티
- CoSteps 재검증 — horizontal 레이아웃 + 디자인 파리티
- CoJoin 재검증 — contract 제네릭, Web div 기반, 예제 분리
- CoCard 디자인 파리티 + contract 제네릭 통일
- CoCard 예제 Flutter/Web 통일 — StatelessWidget/StatelessComponent
- Collapsible 프리뷰 ViewConstraints + md 문서 업데이트
- Collapsible 예제 expanded:true로 초기 높이 측정 개선
- CoCollapsible 디자인 파리티 (Accordion과 동일 패턴 적용)
- CoAccordionTrigger 밑줄 색상 테마 연동
- CoAccordion 텍스트 색상 테마 연동
- CoAccordion 애니메이션 easing 통일
- Web CoAccordion content 텍스트 크기 + 애니메이션 자연스러움
- CoAccordion 디자인 파리티 — chevron 애니메이션, 아이콘 크기, content 타이포
- CoAccordionTrigger 디자인 파리티 — font weight + chevron 회전
- CoAccordion setState during build + Flutter 예제 StatelessWidget 통일
- CoCollapsible initState에서 Theme.of(context) 접근 제거
- CoAccordionItem initState에서 Theme.of(context) 접근 제거
- Separator 코드 스니펫을 전체 클래스 형식으로 통일
- Separator 예제 간소화 — default는 horizontal만, vertical은 variant
- 예제 코드 정리 — 불필요한 텍스트/SizedBox 제거
- 스킬 export.md Web import 규칙 수정
- coui_web core re-export를 show 방식으로 변경
- CoreComponentTheme stepper 필드 누락 수정

### Refactored
- IconResolver를 coui_core → coui_flutter로 이동

### Documentation
- unify-component에 스크린샷 검증 단계 추가 (7-3b)
- unify-component inline-only 케이스에도 2파일 구조 강제
- unify-component Web 2파일 구조 + 레거시 삭제 규칙 명시
- unify-component 정리 — 중복 제거, 번호 재정렬, CoreFontWeight 토큰 규칙 수정
- Material 금지 + Clickable vs GestureDetector 선택 기준
- verify.md에 Web SSR 자동 검증 단계 추가
- unify-component Steps 세션 회고 반영
- unify-component Card 세션 회고 반영
- 스킬 cautions.md에 이번 세션 발견 이슈 추가

### Other
- Merge pull request #1095 from coco-de/feat/1073-layout-unification
- Merge remote-tracking branch 'origin/main' into feat/1073-layout-unification
- wip: CoStepper core + Flutter (Web/docs 미완)

---

## 0.28.0 (2026-04-20)

### Added
- Form 기본 컴포넌트 통일 Phase (#1075) (#1092)

---

## 0.27.0 (2026-04-17)

### Added
- Overlay 컴포넌트 통일 Phase 2 (#1077) (#1094)

---

## 0.26.0 (2026-04-13)

### Added
- 통일 아이콘 시스템 — CoIcon + Iconify 기반 (#1091) (#1093)

---

## 0.25.1 (2026-04-13)

### Fixed
- CoCalendar/CoCarousel 통일화 + CoButton width/height/backgroundColor (#1090)

---

## 0.25.0 (2026-04-13)

### Added
- Display 컴포넌트 통일 Phase 2 (#1072) (#1089)

### Fixed
- 🐛 Spacing 상수 타입을 int에서 double로 수정
- 🐛 NavigationLabeled child에 Flexible 래핑 추가

---

## 0.24.0 (2026-04-07)

### Added
- 컴포넌트 통일 Phase 2 — Chip, Tooltip, Dialog, Slider, Avatar + docs_site 리팩토링 (#1088)

---

## 0.23.0 (2026-04-06)

### Added
- CoRadioGroup/CoRadio 통일 컴포넌트 구현 (#1035) (#1066)

---

## 0.22.3 (2026-04-06)

### Fixed
- CoSwitchField Flutter label fontSize/height 명시 (#1064) (#1065)

---

## 0.22.2 (2026-04-06)

### Fixed
- CoTextField Web focus 시 border 색상 변경 (#1062) (#1063)

---

## 0.22.1 (2026-04-06)

### Fixed
- docs_site Flutter preview 다크 모드 테마 동기화 (#1060) (#1061)

---

## 0.22.0 (2026-04-06)

### Added
- Checkbox/Toggle/SwitchField 통일화 — Co 컴포넌트 + 토큰 기반 렌더링 (#1059)

---

## 0.21.1 (2026-04-03)

### Fixed
- 🐛 pumpAndSettle() 호환 테스트 래퍼 buildCoUITestApp() 추가 (#1057)

---

## 0.21.0 (2026-04-03)

### Added
- TextField 컴포넌트 통일 — contract + 토큰 + variant style (#1053) (#1055)

---

## 0.20.0 (2026-04-01)

### Added
- Button 컴포넌트 통일 — contract + 토큰 + variant style (#1052)

---

## 0.19.12 (2026-03-31)

### Refactored
- 컴포넌트 카테고리를 doc_site 기준으로 통일 (#1050)

---

## 0.19.11 (2026-03-31)

### Refactored
- Flutter spacing 하드코딩 → CoreSpace 토큰 전환 (#1047) (#1048)

---

## 0.19.10 (2026-03-31)

### Fixed
- Android 상태바 아이콘 brightness를 테마에 맞게 설정 (#1045) (#1046)

---

## 0.19.9 (2026-03-31)

### Refactored
- Primitive 토큰 구조 통일 + 하드코딩 완전 제거 (#1043)

---

## 0.19.8 (2026-03-31)

### Refactored
- FontFamily 토큰 통일 (#1041)

---

## 0.19.7 (2026-03-30)

### Refactored
- Spacing/Radius 토큰 통일 + static const 패턴 (#1036)

---

## 0.19.6 (2026-03-30)

### Refactored
- Typography/Radius/Color 토큰 통일 (#1036)

---

## 0.19.5 (2026-03-27)

### Fixed
- CouiThemeConfig → ThemeConfig rename + theme_config.dart 복원 (#1029)

---

## 0.19.4 (2026-03-27)

### Refactored
- mockup 컴포넌트 DaisyUI 제거 → Tailwind + context.colorScheme (#1027)

---

## 0.19.3 (2026-03-27)

### Refactored
- preview 함수 BuildContext 추가 + 색상 하드코딩 제거 (#1025)

---

## 0.19.2 (2026-03-27)

### Refactored
- UiComponent buildBaseClass(context) + CoUIWeb 앱 래퍼 (#1022)

---

## 0.19.1 (2026-03-26)

### Refactored
- CoreSemanticMapping + Primitive 기반 전환 + docs_site CSS 주입 (#1010)

---

## 0.19.0 (2026-03-26)

### Added
- CoUI Color System — Primitive 생성기 + M3 Semantic 전환 (#1007)

---

## 0.18.3 (2026-03-25)

### Fixed
- Typography 토큰 값을 Tailwind CSS 기준으로 수정

### Other
- Merge pull request #992 from coco-de/fix/987-coui-core-typography-token-values

---

## 0.18.2 (2026-03-25)

### Fixed
- 🐛 InputOTP 백스페이스 삭제 불가 버그 수정 (#984) (#985)

---

## 0.18.1 (2026-03-24)

### Documentation
- Chip.button() / ChipGroup docs_site 문서 및 LivePreview 추가 (#982)

---

## 0.18.0 (2026-03-24)

### Added
- Card 컴포넌트 리디자인 — 범용 미디어/콘텐츠 컨테이너 (#977) (#981)

---

## 0.17.4 (2026-03-24)

### Fixed
- 🐛 InputOTP Delete 키 미동작 수정 (#975)

---

## 0.17.3 (2026-03-23)

### Fixed
- 🐛 _resolvedItemCount 무한 재귀 StackOverflow 수정

### Other
- Merge pull request #967 from coco-de/fix/carousel-resolved-item-count-recursion

---

## 0.17.2 (2026-03-20)

### Fixed
- 사이드바 스크롤 위치 유지 강화 및 검색바 sticky 고정 (#964) (#965)

---

## 0.17.1 (2026-03-20)

### Fixed
- 사이드바 스크롤 위치 유지 및 검색바 사이드바 이동 (#958) (#959)

---

## 0.17.0 (2026-03-20)

### Added
- 컴포넌트 검색바 추가 (#956) (#957)

---

## 0.16.0 (2026-03-20)

### Added
- TabList에 labels 단축 API 추가 — Flutter API 정렬 (#953) (#955)

---

## 0.15.0 (2026-03-20)

### Added
- TabList/TabPane에 터치 스와이프 탭 전환 지원 (#953) (#954)

---

## 0.14.0 (2026-03-20)

### Added
- Tab 컴포넌트 라벨 크기 확대 및 스와이프 제스처 지원 (#951) (#952)

---

## 0.13.0 (2026-03-20)

### Added
- Chip 컴포넌트 디자이너 산출물 통합 — Chip.button(), ChipGroup 추가 (#950)

---

## 0.12.6 (2026-03-19)

### Fixed
- Web↔Flutter Live Preview 색상 불일치 해결 (#942)
- Flutter 프리뷰 트리거 Web 형식 통일 (#938) (#939)
- InputOTP/Loading Web↔Flutter 크로스플랫폼 일관성 개선 (#941)

---

## 0.12.5 (2026-03-19)

### Fixed
- InputOTP/Loading Web↔Flutter 크로스플랫폼 일관성 개선 (#941)

---

# Changelog — coui_web

## 0.12.2 (2026-03-19)

### Fixed
- Input 포커스 링 `ring-ring` 스타일 Flutter와 일치 (#935) (#936)

---

## 0.12.1 (2026-03-19)

### Fixed
- 애니메이션 Duration을 CoreDuration 기반 `duration-*` 클래스로 통일 (#934)

---

## 0.12.0 (2026-03-19)

### Added
- Web↔Flutter 크로스플랫폼 시각적 일관성 개선 (#927) (#933)

---

## 0.11.0 (2026-03-18)

### Added
- Card에 `hoverable` 파라미터 및 hover shadow 애니메이션 추가 (#922) (#925)
- 컴포넌트에 명시적 `transition-*` duration 클래스 추가 (#921) (#924)

### Refactored
- Tailwind duration 클래스를 CoreDuration 기반으로 통일 (#923) (#926)

---

## 0.10.0 (2026-03-18)

### Added
- 8개 컴포넌트 `.simple()` API로 Flutter와 구조 통일 (#919)
- ColorInput `.simple()` API 추가 (#912) (#918)

---

## 0.9.0 (2026-03-18)

### Added
- Slider, DatePicker, TimePicker `.simple()` API 추가 (#917)

---

## 0.8.0 (2026-03-18)

### Added
- Tailwind `rounded-*` 클래스를 CoreRadiusScale 기반으로 동기화 (#915)

---

## 0.7.6 (2026-03-18)

### Refactored
- 프리뷰 스케일링을 CoreThemePresets 기반으로 동기화 (#908)

---

## 0.4.46 (2026-03-18)

### Refactored
- ThemeConfig(Tailwind config)를 CoreThemePresets single source of truth로 통일 (#892)

---

## 0.4.43 (2026-03-18)

### Fixed
- Menubar 수평 레이아웃 — `flex flex-row` 명시 추가 (#886)
- DropdownMenu Live Preview 텍스트/아이템 Flutter와 통일 (#884)
- ContextMenu 프리뷰 렌더링 Flutter와 통일 (#885)
- Swap 컴포넌트 체크박스 인라인 숨김 스타일 추가 (#887)

---

## 0.4.41 (2026-03-18)

### Fixed
- Gap 코드 스니펫 및 프리뷰 API Flutter와 통일 (#879)

---

## 0.4.39 (2026-03-18)

### Fixed
- Collapsible `details/summary` 네이티브 토글 동작 수정 (#870)
- Steps 프리뷰 콘텐츠를 Flutter와 통일 (#871)

---

## 0.4.36 (2026-03-18)

### Fixed
- Tooltip group 클래스 누락 수정 및 프리뷰 통일 (#862)
- Accordion 코드 스니펫 내용을 프리뷰와 일치 (#861)

---

## 0.4.34 (2026-03-18)

### Fixed
- Popover 트리거를 hover → click(focus) 기반으로 변경 (#853)
- Drawer 라이브 프리뷰 렌더링 Flutter와 통일 (#855)

---

## 0.4.31 (2026-03-18)

### Fixed
- Menu에 카드형 컨테이너 스타일 적용 (Flutter MenuPopup 일치) (#847)
- Breadcrumb ol/li 기본 스타일 리셋 (#844)

---

## 0.4.23 (2026-03-18)

### Fixed
- Link 코드 스니펫 `text()` → `Text()` 및 href 일치 (#825) (#826)

---

## 0.4.20 (2026-03-18)

### Fixed
- Loading 프리뷰 크기 및 코드 스니펫 Flutter와 통일 (#819) (#820)

---

## 0.4.18 (2026-03-18)

### Fixed
- Stat 코드 스니펫 label/value 프리뷰 일치 (#814) (#815)

---

## 0.4.15 (2026-03-18)

### Refactored
- CodeSnippet code examples를 WEB/FLUTTER 탭 공통으로 통일 (#810)

---

## 0.4.12 (2026-03-18)

### Fixed
- Calendar 코드 스니펫 API Flutter와 통일 (#800) (#801)

### Added
- String-based convenience factories for cross-platform API (#802)

---

## 0.4.9 (2026-03-18)

### Fixed
- Table 코드 스니펫 `text()` → `Text()` 수정 및 Role 칼럼/Badge 추가 (#795) (#798)

---

## 0.3.19 (2026-03-17)

### Fixed
- Badge 코드 스니펫 `text()` → `Text()` 대소문자 수정 (#780) (#782)

---

## 0.3.14 (2026-03-17)

### Fixed
- StarRating을 SVG 별 아이콘으로 교체하여 Flutter와 visual parity 달성 (#773)
- SwitchField 라이브 프리뷰 코드 스니펫 통일 (#770) (#772)

---

## 0.3.5 (2026-03-17)

### Refactored
- Select를 native `<select>`에서 button+dropdown 커스텀으로 교체 (#755)

---

## 0.3.1 (2026-03-17)

### Refactored
- Input API를 Flutter와 통일 (#753)

---

## 0.3.0 (2026-03-17)

### Added
- FAB 인라인 모드 추가 — Flutter와 API 통합 (#751)

---

## 0.2.12 (2026-03-17)

### Refactored
- CommandItem API를 Flutter와 통일 (#744) (#750)

---

## 0.2.8 (2026-03-17)

### Fixed
- RawText for inline scripts to prevent HTML entity escaping (#744)

---

## 0.2.7 (2026-03-16)

### Refactored
- Button 예제를 named constructor 형식으로 통일 (#743)

---

## 0.2.0

### Breaking Changes
- **`disabled` → `enabled`**: 모든 Form/Control 컴포넌트에서 positive boolean `enabled` (default `true`) 사용
- **`checked` → `value`**: Toggle, SwitchField, Swap에서 `value` 사용
- **`title` → `message`**: Toast 컴포넌트 primary text 파라미터 변경
- **Callback typedefs**: Component-specific typedef를 `CoreValueChanged<T>` / `CoreVoidCallback`으로 교체

### Deprecated (will be removed in v4.0)
- `disabled` getter (use `enabled` instead)
- `checked` getter on Toggle/SwitchField/Swap (use `value` instead)
- Component-specific callback typedefs

### Added
- Toast: `position` parameter (`CoreToastPosition`) and `durationMs` parameter
- Select: `items` getter returning `List<CoreSelectItem<String>>`
- SelectOption: `enabled` field and `toCoreItem()` method
- Checkbox: `isIndeterminate` getter

---

## 0.1.0

### Added
- 90+ CoUI components across 9 categories (control, display, form, layout, menu, navigation, overlay, text, icon)
- CoUIThemeController with 32 built-in CoUI themes
- ThemeTokens for CSS variable access and CustomThemeData for custom themes
- Spacing Scale (Tailwind CSS 4px base) with cross-platform parity
- UiComponent base class with styling, variant, and event systems
- Cross-platform API parity with coui_flutter (56 shared components)

---

## 0.0.4

### Added
- Checkbox, Radio, Toggle, Textarea, Select, Progress, Link

## 0.0.3

### Added
- Loading, Divider

## 0.0.2

### Added
- Input, Badge, Alert, Card

## 0.0.1

- Initial release — Button component PoC for Jaspr
