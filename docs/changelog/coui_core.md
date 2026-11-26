# coui_core changelog archive

## [0.152.0](https://github.com/coco-de/coui/compare/coui_core-v0.151.0...coui_core-v0.152.0) (2026-10-02)


### 기능

* **core,flutter,web:** Skeleton 의 enabled 를 폐기 예고한다 — 대체는 호출자의 조건부 렌더 ([#5242](https://github.com/coco-de/coui/issues/5242)) ([cfa7fba](https://github.com/coco-de/coui/commit/cfa7fba5cc3814b033428e09b2d39f92c6fd2207))


### 버그 수정

* **flutter:** Skeleton 맥동이 채움의 알파에 곱해진다 — .transparent 가 검정으로 맥동하던 것 ([#5243](https://github.com/coco-de/coui/issues/5243)) ([7ffe64f](https://github.com/coco-de/coui/commit/7ffe64f4a715821c5e4f389d84e05bbbd8c4fda1))

## [0.151.0](https://github.com/coco-de/coui/compare/coui_core-v0.150.0...coui_core-v0.151.0) (2026-10-02)


### 기능

* **core,flutter,web:** TextField · TextArea · Toggle 의 xs 를 예고한다 — assert 가 켜진 실행에서 한 번 로그 ([#5230](https://github.com/coco-de/coui/issues/5230)) ([eb4f70d](https://github.com/coco-de/coui/commit/eb4f70da3715691835bf1132ffb7b4cb2d9610ba))
* **core:** 없어질 크기 칸을 디버그 로그로 한 번만 알린다 ([#5228](https://github.com/coco-de/coui/issues/5228)) ([d205c2f](https://github.com/coco-de/coui/commit/d205c2ff1789b96d808a42abc3e59d55f5d9e4bb)), closes [#5220](https://github.com/coco-de/coui/issues/5220)


### 버그 수정

* **core,flutter,web,figma:** EmptyState 캔버스를 코드대로 — compact 제목 역할 · 아이콘 48/32 · 간격 · 폭 · 기본 변형 ([#5216](https://github.com/coco-de/coui/issues/5216)) ([beb78d8](https://github.com/coco-de/coui/commit/beb78d831d282e68d6578b6ceae17383092ec56f))


### 리팩터링

* **flutter,web:** TextField 가 크기 행을 resolveSizeRow 로 고른다 ([#5225](https://github.com/coco-de/coui/issues/5225)) ([f653639](https://github.com/coco-de/coui/commit/f6536396c39886d073d317b34446da5de2df410a)), closes [#5218](https://github.com/coco-de/coui/issues/5218)

## [0.150.0](https://github.com/coco-de/coui/compare/coui_core-v0.149.0...coui_core-v0.150.0) (2026-10-01)


### ⚠ BREAKING CHANGES

* **core:** ValidationBadge 의 대기(pending) 기본 테두리가 surfaceContainerHigh 에서 onSurfaceVariant 20% tint 로 바뀌어, 성공·실패 테두리와 같은 무게의 옅은 테두리로 렌더된다. 이전 색이 필요하면 `CoreValidationBadgeStyle(pendingBorderColor: CoreColor.token(CoreColors.surfaceContainerHigh))` 로 덮는다.
* **mockup:** MockupBrowser 의 chromeWidth · toolbarHeight · toolbarPadding(좌·상·우)은 이제 몸체 바깥 가장자리에서 재므로 기본 창이 2px 낮아지고 카드·툴바 내용이 1px 바깥으로 옮겨진다(테두리를 두껍게 해도 창 크기는 그대로). 또 양 플랫폼 MockupBrowser.copyWith 의 addressBar 가 String? 에서 ValueGetter<String?> 로 바뀌어 `copyWith(addressBar: 'x')` 는 `copyWith(addressBar: () => 'x')` 로 고쳐야 한다.
* **core,flutter,web:** Web `Button` 이 인라인 스타일에서 `--btn-icon-size` · `--btn-icon-color` · `--btn-icon-color-hover` · `--btn-icon-color-disabled` 를 더 이상 내지 않는다(읽는 곳이 없던 변수). 대신 크기가 지정되지 않은 `Icon` 이 Button 사이즈 사다리(xs 16 · sm/md 20 · lg/xl 24 · xl2 28)를 따르므로, xs·lg·xl·xl2 Button 안의 맨 `Icon` 과 Web FAB 글리프(20 → 24/24/28)의 렌더 크기가 Flutter 와 같게 바뀐다. FAB 의 `buttonStyle.height/width` 는 여전히 `diameter` 가 이긴다.
* **text_field,phone_input,web:** Flutter `TextField.onTapUpOutside` 의 타입이 `TapRegionCallback?` 에서 `TapRegionUpCallback?`(PointerUpEvent)으로 바뀌고 `CoreTextFieldContract` 에 `TapUpOutCb` 타입 파라미터가 추가된다 — 콜백 인자를 `PointerDownEvent` 로 명시한 호출부는 `PointerUpEvent` 로 고친다(이전에는 호출된 적이 없다). `TextField` / `TextArea` 의 확대경 기본값이 비활성에서 플랫폼 확대경으로 바뀌고(끄려면 `TextMagnifierConfiguration.disabled`), 읽기 전용 `TextArea` 도 탭으로 포커스·선택을 받는다.

### 기능

* **core,flutter,web:** DraggablePanel dockType outside 도킹 구현 ([#2945](https://github.com/coco-de/coui/issues/2945)) ([#5089](https://github.com/coco-de/coui/issues/5089)) ([6f48d56](https://github.com/coco-de/coui/commit/6f48d5677b03cdd78d987bcd5f9362c310000711))
* **core,flutter,web:** Sortable 을 키보드로 재정렬한다 — 핸들 포커스 · 한 칸 이동 · 위치 안내 ([#4113](https://github.com/coco-de/coui/issues/4113)) ([#5183](https://github.com/coco-de/coui/issues/5183)) ([82863b2](https://github.com/coco-de/coui/commit/82863b2241bc989dc23b24f6a3ae30fa9af714df))
* **figma:** 브랜드 색 램프의 publish 가시성을 exporter 가 유도하고 Import 가 쓴다 ([#4518](https://github.com/coco-de/coui/issues/4518)) ([#5160](https://github.com/coco-de/coui/issues/5160)) ([4378faf](https://github.com/coco-de/coui/commit/4378faf07bc9bdc9b6659a394e8755ba28500950))
* **tree:** [#5136](https://github.com/coco-de/coui/issues/5136) 포인터 드래그 프록시와 계층별 삽입 공간 ([bfc23b1](https://github.com/coco-de/coui/commit/bfc23b1c70be60ff8ff465d4d6c1d67bf9377b7d))
* **tree:** preview depth-aware placement and reorder intent ([#5136](https://github.com/coco-de/coui/issues/5136)) ([0f0572b](https://github.com/coco-de/coui/commit/0f0572b6944f12f956efd438a0e6399bc2144901))


### 버그 수정

* **a11y:** 검증 에러 통보 · 팝업 열림 · 선택 상태가 리더에 닿게 한다 ([#4155](https://github.com/coco-de/coui/issues/4155)) ([#5099](https://github.com/coco-de/coui/issues/5099)) ([93240b1](https://github.com/coco-de/coui/commit/93240b1f064a9b0b9fd95c13a3381a696091ef8c))
* **core,flutter,web:** FAB 아이콘 슬롯 clobber 해소 + Web Button 이 아이콘 스타일을 실제로 소비 ([#4136](https://github.com/coco-de/coui/issues/4136)) ([#5098](https://github.com/coco-de/coui/issues/5098)) ([4bc8771](https://github.com/coco-de/coui/commit/4bc87712ca96d2b61bac9097b8ee15751f93adea))
* **core,flutter:** badge 포커스 링 기본 슬롯에 offsetColor 를 채워 Flutter 가 offset 밴드를 그리게 한다 ([#5154](https://github.com/coco-de/coui/issues/5154)) ([5e7c0de](https://github.com/coco-de/coui/commit/5e7c0de5967cddcb77ef1ba822062f0df8a21288))
* **core:** ValidationBadge 대기 테두리를 대기 글자색 20% 로 칠한다 ([#3325](https://github.com/coco-de/coui/issues/3325)) ([#5189](https://github.com/coco-de/coui/issues/5189)) ([26595ff](https://github.com/coco-de/coui/commit/26595fffd6b2dbd207ac53dc0c1dad33942765e8))
* **figma:** 아이콘 Button 인스턴스 박스·라벨 고정과 DisclosureBadge·DefinitionList 빌더 ([#5119](https://github.com/coco-de/coui/issues/5119)) ([e83b30a](https://github.com/coco-de/coui/commit/e83b30a9ad0b2f2ae6136dce50487071a705dd52))
* **l10n:** 정오·자정 AM/PM 과 시각 0-패딩을 coui_core 한 곳에서 계산 ([#3383](https://github.com/coco-de/coui/issues/3383)) ([#5085](https://github.com/coco-de/coui/issues/5085)) ([7e4824a](https://github.com/coco-de/coui/commit/7e4824a24d1edd0e60493d242722edd3f1f7c7fc))
* **mockup:** MockupBrowser 창 거리를 바깥 가장자리에서 재고 copyWith 로 주소창을 지울 수 있게 ([#5170](https://github.com/coco-de/coui/issues/5170)) ([9f7f1c7](https://github.com/coco-de/coui/commit/9f7f1c74284abd913482ef6122963b36a7a23cd6))
* **text_field,phone_input,web:** 부채 4건 — obscureText seed 문서화 · PhoneInput placeholder · 선언만 된 파라미터 배선 · CDN 위생 ([#5092](https://github.com/coco-de/coui/issues/5092)) ([50e5bca](https://github.com/coco-de/coui/commit/50e5bca1ec1cb1536fabfe0a6e7e6adb893b1dcf))
* **theme:** 테마 크로스페이드 — 전 슬롯 보간 · 스냅 규칙 통일 · 채널 클램프 · 토큰 스킴 크래시 ([#5087](https://github.com/coco-de/coui/issues/5087)) ([8a4aff3](https://github.com/coco-de/coui/commit/8a4aff3ae8f1395b42eff105243343fdb1fdccdd))

## [0.149.0](https://github.com/coco-de/coui/compare/coui_core-v0.148.0...coui_core-v0.149.0) (2026-09-28)


### 기능

* **tree:** cross-platform node-to-folder drag/drop ([#5090](https://github.com/coco-de/coui/issues/5090)) ([#5103](https://github.com/coco-de/coui/issues/5103)) ([82ad175](https://github.com/coco-de/coui/commit/82ad17525cda9718535d665b1a4cc3c48609a3cf))
* **tree:** lazy loading, stable keys and virtual rows ([#5081](https://github.com/coco-de/coui/issues/5081)) ([#5097](https://github.com/coco-de/coui/issues/5097)) ([97e14e7](https://github.com/coco-de/coui/commit/97e14e747371d7fb3a8f888464a1ba48dd59d04e))
* **tree:** 파일과 노드를 탐색 트리 행 사이에 직접 드롭 ([#5104](https://github.com/coco-de/coui/issues/5104)) ([#5105](https://github.com/coco-de/coui/issues/5105)) ([2db7bcc](https://github.com/coco-de/coui/commit/2db7bcc4bcecff4dc85d390ad2ac310766438025))

## [0.148.0](https://github.com/coco-de/coui/compare/coui_core-v0.147.0...coui_core-v0.148.0) (2026-09-28)


### 기능

* Block Hero with Layout=center|split ([#5062](https://github.com/coco-de/coui/issues/5062)) ([5fc7fd0](https://github.com/coco-de/coui/commit/5fc7fd0f4968d665eb70d9b97cf74aed04171da9))
* **drawer:** openDrawer 에 useRootNavigator · fillSafeArea — 탭 셸 하단 시트 ([#5075](https://github.com/coco-de/coui/issues/5075)) ([ebeb823](https://github.com/coco-de/coui/commit/ebeb823a4a2e6bdfc2661f7a289e8c969e85253f))


### 버그 수정

* **figma:** Carousel radius16 and NavigationBar 10px section captions ([24000f4](https://github.com/coco-de/coui/commit/24000f4b4ef40adcb62589a33dfee4c12c57ce50))
* **text-field:** TextField 가 FormField 에 값을 보고한다 — FormValueSupplier 복원 ([#5072](https://github.com/coco-de/coui/issues/5072)) ([5a46aad](https://github.com/coco-de/coui/commit/5a46aad35907fb5592f0548f38c661f0863ae397))


### 문서

* move Footer from the component catalog to Blocks ([#5071](https://github.com/coco-de/coui/issues/5071)) ([2e50581](https://github.com/coco-de/coui/commit/2e505818a04e494d6a63faccff7ab7d618aab2f2))

## [0.147.0](https://github.com/coco-de/coui/compare/coui_core-v0.146.0...coui_core-v0.147.0) (2026-09-23)


### 기능

* **button:** Web 과 데스크톱 Flutter 에도 누름 축소를 — CoreButtonStyle.pressedScale 한 필드에서 ([#5047](https://github.com/coco-de/coui/issues/5047)) ([3a886c3](https://github.com/coco-de/coui/commit/3a886c31ddedf8592482f482f6f0b94c5ce15944)), closes [#4427](https://github.com/coco-de/coui/issues/4427)
* **core,flutter,web,docs:** HeroSection appear-on-scroll entrance ([#5033](https://github.com/coco-de/coui/issues/5033)) ([474b5f1](https://github.com/coco-de/coui/commit/474b5f14e7abf722110b459d3e0a9e4f55d49bfc))
* **core,flutter,web:** [#5036](https://github.com/coco-de/coui/issues/5036) — Button href 가 활성일 때 진짜 &lt;a&gt; 다 ([#5038](https://github.com/coco-de/coui/issues/5038)) ([c847b6d](https://github.com/coco-de/coui/commit/c847b6d402d9cd5eed896aec3336dd21c3a2092c))
* **core,flutter,web:** TabPane editorStrip — official IDE strip-only API ([#5032](https://github.com/coco-de/coui/issues/5032)) ([ff0fd28](https://github.com/coco-de/coui/commit/ff0fd28d12bae435feab680fd392a5c11d738bb9))
* **core,flutter,web:** 드래그가 스크린 리더에 말하고, 배선 실수를 보고한다 ([#4939](https://github.com/coco-de/coui/issues/4939)) ([#5012](https://github.com/coco-de/coui/issues/5012)) ([bf562af](https://github.com/coco-de/coui/commit/bf562af04531e931678cec415d33704712dc5a62))
* **core,flutter,web:** 라벨 보유 컨트롤에 labelMaxLines · labelOverflow 노출 ([#2880](https://github.com/coco-de/coui/issues/2880)) ([#5040](https://github.com/coco-de/coui/issues/5040)) ([1636f6d](https://github.com/coco-de/coui/commit/1636f6dbcdcb42cc40e12a881bbdf7658b3a3c2f))
* **core,flutter,web:** 타이핑한 dial code 로 국가를 고른다 — 모호하면 그대로 둔다 ([#5031](https://github.com/coco-de/coui/issues/5031)) ([c407b89](https://github.com/coco-de/coui/commit/c407b89ffeb22391d84583b63b53d3ecfc991f49)), closes [#4247](https://github.com/coco-de/coui/issues/4247)
* **core,web:** 브랜드 accent 역할과 마케팅 크롬 레시피 ([#5045](https://github.com/coco-de/coui/issues/5045)) ([e89068a](https://github.com/coco-de/coui/commit/e89068a0a9e85d1a860ce151f7842d716b70ad86))
* **lints:** copyWith 가 필드를 빠뜨리면 CI 가 막는다 — avoid_incomplete_copy_with ([#5017](https://github.com/coco-de/coui/issues/5017)) ([1e8bfe2](https://github.com/coco-de/coui/commit/1e8bfe2cb95a5ef74b9eda15137a964c65311406))
* **lints:** k 접두 · handle 어간 · child 마지막을 CI 가 막는다 ([#5021](https://github.com/coco-de/coui/issues/5021)) ([b786ce1](https://github.com/coco-de/coui/commit/b786ce1795ecc9061dabd4cd156f198af3b117d0))


### 버그 수정

* **web:** [#3708](https://github.com/coco-de/coui/issues/3708) — Sortable .horizontal/.grid 아이템 폭 = 콘텐츠 폭 ([#5024](https://github.com/coco-de/coui/issues/5024)) ([5dc42e0](https://github.com/coco-de/coui/commit/5dc42e0d0a3455b0683ccae5bc1bca8ad7f989c1))
* **web:** Frame row/column 자식을 Flutter 처럼 non-shrink 기본으로 ([#5051](https://github.com/coco-de/coui/issues/5051)) ([d0bb33d](https://github.com/coco-de/coui/commit/d0bb33d136a586276dbc0fe97b537c1a1f2a5305)), closes [#3127](https://github.com/coco-de/coui/issues/3127)


### 리팩터링

* **core,flutter,web:** Label.htmlFor 를 deprecate 하고 라벨↔컨트롤 연결을 FormField 로 안내한다 ([#5030](https://github.com/coco-de/coui/issues/5030)) ([965b364](https://github.com/coco-de/coui/commit/965b364ddc4c9d6a5e6a4e3a8d2b71eeddecca90))


### 문서

* **core:** 디자이너 확인 결정 3건 문서화 — 요일 헤더 타이포 · 트리거 바 최소 폭 · 헤더 경계선 관례 ([#5042](https://github.com/coco-de/coui/issues/5042)) ([5c0dac8](https://github.com/coco-de/coui/commit/5c0dac8b40ac27a75c858ef4ca682678267289e0)), closes [#4880](https://github.com/coco-de/coui/issues/4880) [#4173](https://github.com/coco-de/coui/issues/4173) [#4579](https://github.com/coco-de/coui/issues/4579)
* **core:** 배경 틴트는 다크 전용임을 현재 사실로 기록 ([#5048](https://github.com/coco-de/coui/issues/5048)) ([e30580a](https://github.com/coco-de/coui/commit/e30580a76b184c484631b24ecd94c593e1ed67f3)), closes [#4234](https://github.com/coco-de/coui/issues/4234)

## [0.146.0](https://github.com/coco-de/coui/compare/coui_core-v0.145.0...coui_core-v0.146.0) (2026-09-20)


### 기능

* **core,flutter,web,docs:** Command keywords + shadcn-parity 문서 예시 ([#4989](https://github.com/coco-de/coui/issues/4989)) ([#4990](https://github.com/coco-de/coui/issues/4990)) ([3ba75b8](https://github.com/coco-de/coui/commit/3ba75b82e3e3e3f9e4bfef2ba234689601862cab))


### 버그 수정

* **figma:** exporter 가 nested Style default 의 식별자를 해석한다 — 캔버스에 자식 default 가 새던 25자리 교정 + 대조 가드 ([#5000](https://github.com/coco-de/coui/issues/5000)) ([9afb1d1](https://github.com/coco-de/coui/commit/9afb1d1ce6ff9ac2cf8ad6dbdb37eda7fe16bdf3))
* **figma:** exporter 가 호출을 쓴 클래스의 스코프로 인자를 푼다 — 잠복 3건 ([#5001](https://github.com/coco-de/coui/issues/5001)) ([#5004](https://github.com/coco-de/coui/issues/5004)) ([ace5636](https://github.com/coco-de/coui/commit/ace5636430b5d0aede39fda6bd95df7e287a4a67))

## [0.145.0](https://github.com/coco-de/coui/compare/coui_core-v0.144.0...coui_core-v0.145.0) (2026-09-17)


### ⚠ BREAKING CHANGES

* **core:** `DesignSystemAdapter` 의 `resolveVariant` · `resolveMotion` · `resolveCornerStyle` · `resolveSurface` 가 인터페이스와 세 구현에서 제거됐다 — 어댑터는 이제 `resolveColorScheme` 만 가진다. variant 는 호출자가 진술하고, 모서리 기하는 표면 기하 제약이, 모션은 duration·easing tier 가, 표면 처리는 서페이스 스타일 레시피가 소유한다. `CornerStyle` enum 도 함께 제거됐다 — 마지막 소비자가 `resolveCornerStyle` 이었고 `CoreThemeData.cornerStyle` 은 이미 사라졌다.
* **core,flutter:** `CoreGlassMaterial` 과 그 층 모델이 사라진다 — `CoreSurfaceToken.glass` 는 `material:` 을 받지 않고, `CoreSurfaceToken.glass` 필드와 `toJson()` 의 `'glass'` 키가 없어진다. `CoreColorScheme` 의 `glassTint`/`glassHighlight`/`glassShadow`/`glassIllumination` 과 같은 이름의 `CoreColors` 토큰 4개, `ResolvedColorScheme` 의 같은 super-parameter 4개도 함께 사라진다 — 어떤 팔레트도 채우지 않고 CSS 생성기도 내보내지 않던 슬롯이라, 반투명 표면은 `liquidGlass` 서페이스 스타일이 `opacity`/`blurRadius` 로 진술한다. Flutter `Switcher.curve` 와 `resolveSwitcher(legacyCurve:)` 도 사라진다 — 전환 easing 은 `switcherStyle: CoreSwitcherStyle(curve: CoreEasing.*)` 로 들어가고, 그것만이 Web 트윈이 읽을 수 있는 형태다.
* **core,flutter,web:** `CoreThemeData.cornerStyle` 과 `.defaultMotion` 이 `copyWith` 파라미터·`toJson()` 키와 함께 제거됐다 — 직렬화된 테마가 더 이상 `cornerStyle`·`defaultMotion` 을 싣지 않는다. 모서리 기하는 표면 기하 제약으로, 모션은 duration·easing tier 로 진술한다. `Text` 체인의 `.primary`·`.secondary`·`.tertiary`·`.error`·`.success`·`.warning`·`.info` 가 제거됐다 — `.on{Role}Container` 를 쓴다(Web 은 애초에 그것만 있었다). `MockupPhone` typedef · `MockupDevice.mockupPhoneStyle` · `CoreComponentTheme.mockupPhone` · `CoreEasing.standard`·`.decelerate`·`.accelerate`·`.spring` · `ColorPalette` · `CoreContentPadding` · `saturationColorMatrix` · `AxisDirectional` · `resolveTimePicker(scopeId:)` 도 제거됐다.
* **core,flutter,web:** `CoreCheckboxState` enum(과 `toChecked`/`fromChecked`) · `CoreCheckboxVariant` enum · `CoreCheckboxVariantStyle` 클래스 · `CoreCheckboxStyle` 의 `defaultsByVariant` 와 `indeterminateSize` · `CoreCheckboxTheme.variantStyles` · Flutter `Checkbox.state` getter 가 제거됐다 — 체크 상태는 tristate `bool?` 이고 checkbox 에는 variant 축이 없다. `CoreScaffoldStyle` 의 `headerPadding` · `headerSpacing` · `headerActionSpacing` 과 그 `default*` 셋, 그리고 양 플랫폼 `AppBar.scaffoldStyle` 과 `resolveAppBar(legacyScaffoldPatch:)` 파라미터도 제거됐다 — AppBar 의 chrome 은 `appBarStyle` 로 직접 진술한다. 레포 안에 이 값들을 실제로 넘기는 호출자가 하나도 없어 렌더는 바뀌지 않는다.

### 기능

* **core,flutter,web:** checkbox·scaffold deprecation 14 심볼 제거 — 웨이브 2 완료 ([#4964](https://github.com/coco-de/coui/issues/4964)) ([d6d47dd](https://github.com/coco-de/coui/commit/d6d47ddef89c270aeb5c191176d2cb1265f65f7b))
* **core,flutter,web:** 인프라 deprecation 29 심볼 제거 — 웨이브 3b ([#4968](https://github.com/coco-de/coui/issues/4968)) ([ec557aa](https://github.com/coco-de/coui/commit/ec557aa465a4137e12417aa866763bcc815a4701))
* **core,flutter:** glass 층 모델과 Switcher.curve 제거 — 결정 (B) 적용 ([#4970](https://github.com/coco-de/coui/issues/4970)) ([584c943](https://github.com/coco-de/coui/commit/584c9437275261f58758431c0935b6e47b9c91f5))
* **core:** DesignSystemAdapter 를 한 멤버로 — deprecated 넷 제거 ([#4971](https://github.com/coco-de/coui/issues/4971)) ([6d05dbc](https://github.com/coco-de/coui/commit/6d05dbc8256e3bea08af7b788f25c07aca8cae78))

## [0.144.0](https://github.com/coco-de/coui/compare/coui_core-v0.143.0...coui_core-v0.144.0) (2026-09-17)


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

## [0.143.0](https://github.com/coco-de/coui/compare/coui_core-v0.142.0...coui_core-v0.143.0) (2026-09-17)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** `CoreTabVariantStyle` 이 required `disabledIndicatorColor` 를 받는다. 이 클래스를 직접 만들어 `CoreTabsTheme.variantStyles` 에 넣던 코드는 그 값을 더해야 한다 — 면을 칠하는 변형이면 `CoreColor.token(CoreColors.disabledContainer)`, 선을 그리는 변형이면 `CoreColor.token(CoreColors.disabledContent)`. 그리고 `pill` 의 "비활성 + 선택" 채움이 `surface`(Flutter) · `disabled-content`(Web) 에서 둘 다 `disabled-container` 로 바뀌므로 그 자세의 렌더가 달라진다.

### 기능

* **core,flutter,web,figma:** 비활성 선택 탭의 표시는 변형마다 다른 토큰 — 알약은 면, 밑줄은 선 ([#4924](https://github.com/coco-de/coui/issues/4924)) ([42806b3](https://github.com/coco-de/coui/commit/42806b3ac3bdb806577dcca51bf770b5f41716a3))
* **core,flutter,web:** FileInput 이 받은 파일을 저장한다 — 행 저장 버튼 + CoFileSaver ([#4934](https://github.com/coco-de/coui/issues/4934)) ([#4938](https://github.com/coco-de/coui/issues/4938)) ([02a997d](https://github.com/coco-de/coui/commit/02a997d5e0c5e85b340a11de38ea44e54a949981))
* **core,flutter,web:** FileInput 이 실제 파일 드롭을 받는다 — desktop_drop + Web 폴더 순회 ([#4932](https://github.com/coco-de/coui/issues/4932)) ([#4936](https://github.com/coco-de/coui/issues/4936)) ([b74dc4a](https://github.com/coco-de/coui/commit/b74dc4a6a71de75f75d6e9d88a006bbc85dda77d))
* **core,flutter,web:** FileInput 이 폴더를 고르고 그 안의 파일을 받는다 ([#4933](https://github.com/coco-de/coui/issues/4933)) ([#4937](https://github.com/coco-de/coui/issues/4937)) ([12c1681](https://github.com/coco-de/coui/commit/12c16817ea287fd805f769e0e14b7085186325f7))
* **core:** 드래그 collision 격차 반영 — compose + closestCenter · rectIntersection ([#4935](https://github.com/coco-de/coui/issues/4935)) ([#4940](https://github.com/coco-de/coui/issues/4940)) ([9a857bc](https://github.com/coco-de/coui/commit/9a857bc9ff34c576b3fc384a2b625af1fd7fddb4))

## [0.142.0](https://github.com/coco-de/coui/compare/coui_core-v0.141.0...coui_core-v0.142.0) (2026-09-15)


### ⚠ BREAKING CHANGES

* **core:** `CoreMockupDeviceContract` 가 `orientation` getter 를 요구하고 `resolveMockupDevice` / `CoreMockupDeviceLayout.compute` 가 required `orientation` 을 받는다. 가로를 `screenAspectWidth`/`screenAspectHeight` 로 저작하던 호출은 이제 세로로 그려진다 — 비율이 긴 변 먼저로 정규화되고 방향은 `orientation` 이 정하므로, `orientation: .landscape` 로 옮기고 비율 override 는 지운다. 폰 가로의 버튼도 좌우 변에서 위/아래 변으로 옮겨간다.
* **core,figma:** `CoreTabsStyle.defaultInactiveContentOpacity` 가 제거된다 — `pill` 의 비활성 라벨이 알파 대신 `on-surface-variant` 토큰을 직접 부르게 되면서 이 상수를 읽는 곳이 없어졌다. 그리고 두 변형의 `tabPadding` 기본값에서 세로 인셋이 빠진다(pill `vertical: space6` → 0, underline `vertical: space8` → 0) — 높이를 정하는 것은 `itemHeight` 이고, 세로 인셋을 되살리려면 `tabsStyle` 로 명시해야 한다.
* **core,flutter,web,figma:** `Tabs.size` 와 `CoreTabsContract.size` 가 `CoreComponentSize` 에서 `CoreTabsSize`(sm/md/lg)로 바뀐다 — `xs`/`xl`/`xl2` 는 사라지고, `CoreTabsStyle.defaultsBySize` 의 키도 같이 바뀐다. `CoreEmptyStateStyle` 은 `maxDescriptionWidth` 가 `maxTextWidth` 로 개명되고 `backgroundColor`·`borderColor`·`borderWidth`·`borderRadius`·`iconContainerSize`·`iconContainerColor`·`iconContainerShape`·`iconColorAlpha`·`borderAlpha`·`descriptionAlpha`·`iconSizeRatio` 열한 필드와 `CoreEmptyStateIconShape` enum 이 제거된다 — 리디자인이 그 필드들이 그리던 박스와 아이콘 컨테이너를 없앴으므로 후임이 없다.

### 기능

* **core,flutter,web,figma:** EmptyState 는 상자를 버리고, Tabs 는 사다리를 좁힌다 ([06da3df](https://github.com/coco-de/coui/commit/06da3dfbbe0473d907c46acd803a7c765f09f6ec))
* **core:** [#4914](https://github.com/coco-de/coui/issues/4914) — MockupDevice 의 Orientation 축, 돌린 몸체가 버튼을 데려간다 ([5d6024a](https://github.com/coco-de/coui/commit/5d6024a3a99600b92f3eaf384d33619161b4ddc0))
* **mockup-device:** 카메라·제스처 바 표시 옵션과 SafeArea ([#4918](https://github.com/coco-de/coui/issues/4918)) ([bb430b1](https://github.com/coco-de/coui/commit/bb430b1b39156f60c040142ef0a270ce774bf9bc)), closes [#4913](https://github.com/coco-de/coui/issues/4913)


### 버그 수정

* **core,figma:** Tabs 가 리디자인 프리뷰와 같은 값을 그린다 — 비활성 색 · 세로 인셋 · 캔버스 gap ([#4916](https://github.com/coco-de/coui/issues/4916)) ([97a2a29](https://github.com/coco-de/coui/commit/97a2a2982c587043f9aa96277f1b5c3fca6fcdca))


### 문서

* **core:** tabs · empty-state 의 STYLE_TABLE 을 생성기로 되돌린다 ([e8fd5a3](https://github.com/coco-de/coui/commit/e8fd5a356766af5ae746800f656e3b9134d10f1e))

## [0.141.0](https://github.com/coco-de/coui/compare/coui_core-v0.140.1...coui_core-v0.141.0) (2026-09-15)


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

## [0.140.1](https://github.com/coco-de/coui/compare/coui_core-v0.140.0...coui_core-v0.140.1) (2026-09-14)


### 버그 수정

* **core:** [#4856](https://github.com/coco-de/coui/issues/4856) A-1 — 트리거는 자기가 합성한 Button 의 라벨 역할로 값을 그린다 ([#4879](https://github.com/coco-de/coui/issues/4879)) ([03b32b1](https://github.com/coco-de/coui/commit/03b32b17d9c81e099b3d17aa4b5087b29097355b))
* **core:** [#4865](https://github.com/coco-de/coui/issues/4865) — 합성한 Button 이 비활성 트리거 값 색을 소유한다 ([#4878](https://github.com/coco-de/coui/issues/4878)) ([0b469e1](https://github.com/coco-de/coui/commit/0b469e166a00bb545e0117ff2b752361ad0f64ed))
* **parity:** [#4867](https://github.com/coco-de/coui/issues/4867) — 야간 스윕이 매일 red 였던 하네스 3건과 프루닝 규칙을 고친다 ([#4871](https://github.com/coco-de/coui/issues/4871)) ([a0a9d24](https://github.com/coco-de/coui/commit/a0a9d2437859b1edfddb53157c9476fd4cd1efaf))

## [0.140.0](https://github.com/coco-de/coui/compare/coui_core-v0.139.0...coui_core-v0.140.0) (2026-09-13)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** `ResolvedTextArea` 의 `labelTextStyle` 과 `requiredMarkColor` 가 `labelFormLabelStyle`(Flutter) 하나로, Web 의 `label` · `requiredMark` 가 `formLabelStyle` + `labelHost` 로 바뀐다. 위젯이 읽는 paint-ready artifact 라 공개 컴포넌트 API 는 그대로다. `CoreTextAreaStyle.defaultLabelStyle` 은 deprecated — 인스턴스별 역할은 계속 `labelStyle` 슬롯으로 간다.
* **core,flutter,web,figma:** 선택된 disabled Chip 이 채움색 1px 보더 대신 보더 없이 그려져 한 쪽당 1px 좁아지고, Chip `sm` 라벨 자간이 −0.12 에서 −0.06 으로 바뀐다. ChipInput 의 삭제 배지 라벨은 14px 로 유지된다(범위 밖). `CoreChipStyle.disabledSelectedBorderColor` 로 인스턴스별 재지정할 수 있다.
* **fieldset:** CoreFieldsetContract 에 size getter 가 추가됐다 — CoreFieldsetContract<W> 를 직접 구현하는 외부 클래스는 이 getter를 새로 구현해야 한다.
* **text-field:** ResolvedTextField.labelTextStyle(Flutter)이 labelFormLabelStyle로, Web ResolvedTextField.label이 formLabelStyle로 이름과 타입이 바뀌었다. CoreTextFieldStyle.defaultLabelStyle / defaultValueStyle / defaultPlaceholderStyle static const가 제거됐다.
* **form-label:** CoreFormLabelContract 에 size·enabled 두 필드가 추가돼 그 인터페이스를 implements 하는 코드는 두 게터를 구현해야 한다(양 플랫폼 FormLabel 자신은 이미 반영됨, 기본값 CoreComponentSize.md/true 라 기존 호출부는 변경 없이 그대로 동작).
* **menu:** CoreMenuStyle.defaultPopupStyle.borderRadius 가 8(이전 16)이 되어 Menu/DropdownMenu/ContextMenu/Menubar/Select 팝업 패널의 코너가 달라진다.

### 기능

* **fieldset:** Size 축 + disabled legend 색 + fieldSpacing 24 로 정정 ([c5bcaf3](https://github.com/coco-de/coui/commit/c5bcaf3fc86e64868a0ec031cc7fdafa109da33a))
* **form-label:** FormLabel 이 Size 축 + disabled 톤을 받는다 ([fcd75d8](https://github.com/coco-de/coui/commit/fcd75d80855b3d4221605a501299f794b82ea10d))
* **form:** actions row — primaryAction/secondaryAction slots, independent of onSubmit ([67d0bdb](https://github.com/coco-de/coui/commit/67d0bdb833f2b3d6a95f16686f9618de886e7a77))
* **form:** 액션 행을 캔버스에 맞춘다 — showSecondaryAction · 로케일 라벨 · Figma 프로퍼티 표기 ([#4792](https://github.com/coco-de/coui/issues/4792)) ([66c9fc1](https://github.com/coco-de/coui/commit/66c9fc10de7fb30e610f8e3542a0629c662b3f1f))
* **menu:** Menu 팝업 radius 를 패널 정본(8)에 맞춘다 ([b3d7c5a](https://github.com/coco-de/coui/commit/b3d7c5a320a4e93ca36b1b91798e875e49a647ee))
* **mockup:** Core·Figma·Web·Flutter 정합 ([#4766](https://github.com/coco-de/coui/issues/4766)) ([#4776](https://github.com/coco-de/coui/issues/4776)) ([a6377ac](https://github.com/coco-de/coui/commit/a6377ac7c7070601f7879e11a92bc0ca5f289b27))
* **surface:** 리퀴드 글래스를 iOS 26 기준으로 — 카드도 유리, 윤곽 림, 렌즈 돔, 독의 액체 알약 ([#4781](https://github.com/coco-de/coui/issues/4781)) ([9b5b081](https://github.com/coco-de/coui/commit/9b5b08185d9a79e9cf7eb29350f3f96d767000b2))
* **text-field:** value/placeholder 타이포 사다리 도입 + label을 FormLabel에 완전 위임 ([2210c26](https://github.com/coco-de/coui/commit/2210c266c2e752308867c1bec24d99374b8ed264))


### 버그 수정

* **core,flutter,web,figma:** [#4858](https://github.com/coco-de/coui/issues/4858) — TextArea 라벨의 역할은 FormLabel 이 정한다 ([#4861](https://github.com/coco-de/coui/issues/4861)) ([04549e4](https://github.com/coco-de/coui/commit/04549e4cce88ae4f504356c5608f90611202e444))
* **core,flutter,web,figma:** 선택된 disabled Chip 의 보이지 않는 보더를 없애고, 라벨 사다리를 역할로 진술한다 ([#4849](https://github.com/coco-de/coui/issues/4849)) ([bf1d61a](https://github.com/coco-de/coui/commit/bf1d61a6ab7ab54d324f1c1c3caeafbfcc2a992c))
* **core:** [#4553](https://github.com/coco-de/coui/issues/4553) — link·plain 비활성 배경을 투명하게 둔다 ([#4845](https://github.com/coco-de/coui/issues/4845)) ([116ce9c](https://github.com/coco-de/coui/commit/116ce9c8d5eda534d4dd5dcaaf47d0a29cc8c2eb))
* **core:** [#4577](https://github.com/coco-de/coui/issues/4577) — CoreTabContract 를 CoreTabsContract 로 개명 ([#4834](https://github.com/coco-de/coui/issues/4834)) ([38b05e7](https://github.com/coco-de/coui/commit/38b05e73e6679e743fed7c78be017c367cbbebbd))
* **figma:** FormLabel/Fieldset/Form 배치의 Figma 빌더 후속 작업 미완 정리 ([9dd1f2f](https://github.com/coco-de/coui/commit/9dd1f2f59f54fe00f2208fba16450c1bdf78f5da))
* **figma:** 라벨 자간을 fontSize 와 같은 2단으로 변수 바인딩 — 크기 키 letter-spacing/size-&lt;n&gt; ([4f3d0b8](https://github.com/coco-de/coui/commit/4f3d0b835ebf9b8ba8e69eb7db64b16ee6335549))
* **select:** 캔버스 대조 — 트리거 행간 120%, 셰브론 전 rung 20, focus 포즈의 caret 숨김, 문구 "Select an option" ([#4753](https://github.com/coco-de/coui/issues/4753)) ([35b69ac](https://github.com/coco-de/coui/commit/35b69ac42a37b1ceb2e578351504000f6bd65913))
* **text-area:** 사이즈 사다리 6단 확장 + hover 보더 + disabled 배경 + description 사다리 정합 ([e371a93](https://github.com/coco-de/coui/commit/e371a93ead170d54249d8c889d8d609e77d896a6))


### 문서

* **checkbox:** mark-thickness 는 대시 전용 — 체크마크는 아이콘 라이브러리 비례 램프를 따른다 ([96e57f3](https://github.com/coco-de/coui/commit/96e57f3dcd8a7b8edc01bdf57627b03fa8cdba21))

## [0.139.0](https://github.com/coco-de/coui/compare/coui_core-v0.138.0...coui_core-v0.139.0) (2026-09-09)


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

* **core,figma:** Chip 사다리 축소의 뒤처리 셋 — 토큰 exporter · custom disabled · 슬롯 baseline ([f6cb309](https://github.com/coco-de/coui/commit/f6cb309a5f9cadaf876fcdce9d161fea24d5c0c4))
* **guards:** [#4731](https://github.com/coco-de/coui/issues/4731) — ThemeController 의 Icon·Stacks 간선을 이름과 사유로 적는다 ([350dbac](https://github.com/coco-de/coui/commit/350dbaccb9b0dc6a71d889ef2db8ed4bf9a1c92f))

## [0.138.0](https://github.com/coco-de/coui/compare/coui_core-v0.137.0...coui_core-v0.138.0) (2026-09-08)


### ⚠ BREAKING CHANGES

* **core,flutter,web:** `CoreFabSize.mini` 의 지름이 40 에서 48 로 커진다. 이름은 그대로이므로 컴파일은 깨지지 않지만 mini FAB 을 쓰는 화면의 레이아웃이 8px 만큼 달라진다. 메뉴 행 높이도 40 에서 48 로 커진다.

### 기능

* **core,flutter,web:** FAB 이 디자이너가 그린 것을 그린다 — mini 는 48 이 되고, 라벨을 가진 Extended 가 생긴다 ([d0f26ca](https://github.com/coco-de/coui/commit/d0f26ca217b9733a303b678154ccfd4f2b36723a))
* **core:** `CoreLayout` — 패널·오버레이의 상한/하한을 담는 세 번째 치수 네임스페이스 ([#4721](https://github.com/coco-de/coui/issues/4721)) ([22b36d2](https://github.com/coco-de/coui/commit/22b36d24eea34265636c197190e0e58ebde8aea6))

## [0.137.0](https://github.com/coco-de/coui/compare/coui_core-v0.136.0...coui_core-v0.137.0) (2026-09-07)


### 기능

* **core,flutter,web,figma:** 탭이 라벨 앞뒤로 무언가를 걸 수 있다 — 에디터 스트립의 파일 글리프와 닫기 ([#4691](https://github.com/coco-de/coui/issues/4691)) ([#4706](https://github.com/coco-de/coui/issues/4706)) ([89ee36b](https://github.com/coco-de/coui/commit/89ee36b4dcd6ce72f0718e42372c301fb021ff33))

## [0.136.0](https://github.com/coco-de/coui/compare/coui_core-v0.135.0...coui_core-v0.136.0) (2026-09-07)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** 비활성 탭 라벨이 `onSurfaceVariant` 로 흐려진다 — 지금까지는 ambient 텍스트 색(보통 `onSurface`)을 상속해 활성 탭과 같은 색이었다. 이전 그림이 필요하면 `tabPaneStyle: CoreTabPaneStyle(inactiveContentColor: CoreColor.token(CoreColors.onSurface))` 로 되돌린다. API 는 그대로다.

### 기능

* **core,flutter,web,figma:** TabPane 스트립이 자기 배경을 갖는다 ([#4687](https://github.com/coco-de/coui/issues/4687)) ([#4703](https://github.com/coco-de/coui/issues/4703)) ([f1f3c1b](https://github.com/coco-de/coui/commit/f1f3c1bc909b870a49753591422c13dd9be2cffa))
* **core,flutter,web,figma:** TabPane 이 활성/비활성 탭 라벨을 색으로 구분한다 ([#4688](https://github.com/coco-de/coui/issues/4688)) ([#4704](https://github.com/coco-de/coui/issues/4704)) ([c4a8a46](https://github.com/coco-de/coui/commit/c4a8a46420e7595a57d19d7ba554cf6502f1b495))
* **core,flutter,web,figma:** TabPane 탭 사이에 구분선을 그릴 수 있다 ([#4690](https://github.com/coco-de/coui/issues/4690)) ([#4705](https://github.com/coco-de/coui/issues/4705)) ([20d087b](https://github.com/coco-de/coui/commit/20d087bb7fe712ada0f2b42606b704e281b3f5b6))


### 버그 수정

* **core,flutter,web,figma:** TabPane 의 탭 테두리와 패널 테두리를 두 필드로 나눈다 ([#4686](https://github.com/coco-de/coui/issues/4686)) ([#4693](https://github.com/coco-de/coui/issues/4693)) ([2b5740b](https://github.com/coco-de/coui/commit/2b5740beba648008cdffe503260fa422051a8cd1))
* **flutter:** AppBar 단일 행이 제목의 자기 inset 을 그린다 — Web 과 8px 어긋나던 것 ([#4698](https://github.com/coco-de/coui/issues/4698)) ([76b7f1f](https://github.com/coco-de/coui/commit/76b7f1fe80aa723f59e6d96441cf85932e6939e2)), closes [#4692](https://github.com/coco-de/coui/issues/4692)

## [0.135.0](https://github.com/coco-de/coui/compare/coui_core-v0.134.0...coui_core-v0.135.0) (2026-09-07)


### ⚠ BREAKING CHANGES

* **figma,core:** 캔버스 `TabPane` 의 안식 포즈가 세 탭에서 두 탭으로 바뀐다 — 흐려진 세 번째 탭은 이제 `Show disabled tab` (기본 false) 뒤에 있다. 배치된 인스턴스는 다음 Generate 에서 그 탭을 잃으므로, 그 포즈가 필요한 인스턴스는 체크박스를 켜면 된다. 코드 API 와 `CoreTabPaneStyle` 필드는 그대로다.
* **core,flutter,web:** `CoreNavigationBarStyle.sectionLabelRole` 과 `defaultSectionLabelTextStyle` 의 타이포 역할이 `labelSmall`(10px)에서 `labelLarge`(14px)로 바뀌어 rail·sidebar 의 섹션 머리말이 커진다. 이전 크기가 필요하면 `navigationBarStyle: CoreNavigationBarStyle(sectionLabelTextStyle: CoreTextStyle.token(CoreTextStyles.labelSmall))` 로 인스턴스에서 되돌린다.
* **core,flutter,web,figma:** `CoreFooterStyle.defaultBackgroundColor` 가 `surfaceContainer` 에서 `surface` 로 바뀌어 기본 Footer 의 배경 톤이 페이지 배경과 같아진다 — 이전 톤이 필요하면 `footerStyle: CoreFooterStyle(backgroundColor: CoreColor.token(CoreColors.surfaceContainer))` 를 명시한다. 생성자 파라미터는 전부 기본값이 있어 기존 호출은 그대로 컴파일된다.

### 기능

* **core,flutter,web,figma:** Footer 가 디자이너의 두 축을 갖고 legal 블록을 얻는다 ([#4671](https://github.com/coco-de/coui/issues/4671)) ([81031c9](https://github.com/coco-de/coui/commit/81031c93ab857a854b197a513314edf612a4d7c7))


### 버그 수정

* **core,flutter,web:** 내비게이션 섹션 머리말이 디자이너가 고른 역할을 쓴다 ([#4682](https://github.com/coco-de/coui/issues/4682)) ([23e137c](https://github.com/coco-de/coui/commit/23e137cc65e4ed74fb34acbe12e54ef67813e42c))
* **core:** Unibook primary 를 디자이너가 적어둔 남보라로 되돌린다 — 스와치만 파랑이었고 적힌 색 코드는 처음부터 남보라였다 ([#4683](https://github.com/coco-de/coui/issues/4683)) ([d313fa7](https://github.com/coco-de/coui/commit/d313fa7dcbce5c401f9a5b12e1accfca3041ea4a))
* **figma,core:** TabPane 캔버스가 docs 그림에서 쉬고 슬롯 콘텐츠를 프로퍼티로 준다 ([#4680](https://github.com/coco-de/coui/issues/4680)) ([#4681](https://github.com/coco-de/coui/issues/4681)) ([c2d798d](https://github.com/coco-de/coui/commit/c2d798d138587c1e30a778132690ed164355ccd1))

## [0.134.0](https://github.com/coco-de/coui/compare/coui_core-v0.133.0...coui_core-v0.134.0) (2026-09-03)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** `Carousel.indicatorPlacement` 가 사라지고 `variant` 가 그 자리를 받는다 — `indicatorPlacement: .below` 는 `variant: CoreCarouselVariant.banner` 로. `showNavigation` 이 `bool?` 이 되어 기본값이 variant 에서 파생되므로, `banner` 에서 좌우 버튼이 필요하면 `showNavigation: true` 를 명시한다. 배너 슬라이드를 `Card` 로 합성하던 코드는 `CarouselBanner` 로 바꾼다.
* **core,flutter,web,figma:** 세 가지 기본 렌더가 바뀐다. (1) `DotIndicator` 활성 점이 `primary` 대신 `onSurface` 이고 비활성 점 테두리가 사라진다(폭 0), (2) `Carousel` 좌우 버튼이 40 에서 32 로 줄고 `below` 배치의 점 간격이 0 이 된다, (3) `Banner` 의 `action:` 이 `Button` 이면 라벨이 변형 foreground 를 입는다. 이전 모습이 필요하면 각각 `dotIndicatorStyle: CoreDotIndicatorStyle(activeColor: CoreColor.token(CoreColors.primary), inactiveBorderWidth: CoreStrokeWidth.stroke2, inactiveColor: CoreColor.transparent)`, `carouselStyle: CoreCarouselStyle(navInset: …, indicatorBelowGapStyle: CoreGapStyle(size: CoreSpace.space8))`, `action: Button(buttonStyle: CoreButtonStyle(foregroundColor: …))`.
* **core,figma:** `CoreCarouselStyle.defaultBorderRadius` 가 16 에서 8 로 — `borderRadius` 를 주지 않던 모든 `Carousel` 의 뷰포트 모서리가 바뀐다. 이전 모습이 필요하면 `.radius16` 또는 `carouselStyle: CoreCarouselStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius16))`.
* **core,flutter,web,figma:** `DotIndicator` 의 비활성 점이 투명이 아니라 `outlineVariant` 로 채워진다 — `inactiveColor` 를 주지 않던 모든 사용처의 렌더가 바뀐다. 이전 모습이 필요하면 `dotIndicatorStyle: CoreDotIndicatorStyle(inactiveColor: CoreColor.transparent)`.
* **core,flutter,web,figma:** DotIndicator 의 기본 점 크기가 12 → 8 이 된다(기본 크기 md). `CoreDotIndicatorStyle.defaultDotSize` · `defaultSpacing` 정적 필드는 `defaultsBySize` 표로 대체됐다 — 직접 참조하던 코드는 `defaultsBySize[CoreDotIndicatorSize.defaultSize]` 를 읽는다. 점 12 를 원하면 `size: .lg`.

### 기능

* **core,figma:** Carousel 슬라이드 모서리 기본값이 8 이 되고, 배너 슬라이드는 디자이너의 썸네일 스트립을 그린다 ([#4651](https://github.com/coco-de/coui/issues/4651)) ([a255d0a](https://github.com/coco-de/coui/commit/a255d0afa73b54f28db3712613826d79ce4b44a6))
* **core,flutter,web,figma:** Carousel 이 디자이너의 두 축을 갖고, 배너 슬라이드가 CarouselBanner 로 독립한다 ([#4654](https://github.com/coco-de/coui/issues/4654)) ([964043b](https://github.com/coco-de/coui/commit/964043b73658dcfd1a44fa2659612e3b0e8012d8))
* **core,flutter,web,figma:** Carousel 이 인디케이터 위치 축을 갖는다 — 디자이너의 배너 세트를 합성으로 흡수한다 ([#4647](https://github.com/coco-de/coui/issues/4647)) ([be17989](https://github.com/coco-de/coui/commit/be1798996c11ae5848016e2999039430b8adf9c1))
* **core,flutter,web,figma:** DotIndicator 가 크기 축을 갖는다 — 디자이너의 sm·md·lg 세트를 코드가 뒷받침하고 빌더가 그대로 그린다 ([#4646](https://github.com/coco-de/coui/issues/4646)) ([c5ecf34](https://github.com/coco-de/coui/commit/c5ecf347292be5b74f63b23ed4fdbd020ce5fd38))
* **core,flutter,web,figma:** DotIndicator 비활성 점이 속을 채운다 — Carousel 좌우 버튼은 Button 의 circle 멤버를 합성한다 ([#4650](https://github.com/coco-de/coui/issues/4650)) ([4374e24](https://github.com/coco-de/coui/commit/4374e2457dc8dd9623b0acf67d4f0caffa11edc2))
* **core,flutter,web,figma:** 디자이너가 캔버스에서 되돌린 값들을 코드로 옮긴다 — 점 색·테두리, nav 32, 배너 액션 라벨, 인프라 자리표시 ([#4652](https://github.com/coco-de/coui/issues/4652)) ([40ea8c8](https://github.com/coco-de/coui/commit/40ea8c8b38f78602eef18e2a96c2ec25ef8d9b48))

## [0.133.0](https://github.com/coco-de/coui/compare/coui_core-v0.132.0...coui_core-v0.133.0) (2026-09-02)


### ⚠ BREAKING CHANGES

* **core,flutter,web,figma:** `CoreFilterItem<T>` 가 `CoreFilterItem<T, W>` 가 된다 — 명시 제네릭으로 쓰던 코드는 `<T, Widget>` / `<T, Component>` 로 바꾼다(추론으로 만드는 호출은 그대로). `CoreFilterStyle.defaultItemPadding` 이 h16/v8 에서 8 사방으로, 세그먼트 높이가 32 고정으로, reset 이 plain·md 에서 ghost·sm·square 로 바뀌어 Filter 의 렌더가 달라진다.

### 기능

* **core,figma:** 호스트 파생 필드를 부재와 구분한다 — FocusOutline 데모 링이 호스트 반경 8 을 따른다 ([#4625](https://github.com/coco-de/coui/issues/4625)) ([32c7d26](https://github.com/coco-de/coui/commit/32c7d26cc9f86b2829163d44dbe1ef4477b297cc))
* **core,flutter,web,figma:** Filter 세그먼트가 아이콘을 갖고 정사각으로 접힌다 — 디자이너의 세그먼트 프로퍼티를 흡수한다 ([#4628](https://github.com/coco-de/coui/issues/4628)) ([bc544e4](https://github.com/coco-de/coui/commit/bc544e431e99add953277472193e60cd90a5a3af))

## [0.132.0](https://github.com/coco-de/coui/compare/coui_core-v0.131.0...coui_core-v0.132.0) (2026-09-02)


### ⚠ BREAKING CHANGES

* **core:** `CoreButtonVariantStyle` 의 `hoverStateLayerOpacity` / `focusStateLayerOpacity` / `pressedStateLayerOpacity` 가 `stateLayer: CoreStateLayer?` 하나로 바뀌었다(#4505 에서 이미 반영). null 이면 hover 로 떨어지던 fall-through 는 사라진다 — 램프는 셋을 다 진술하거나 아예 없다.
* **core:** `CoreToastVariant.default_` 는 이제 deprecated alias 다(#4505 에서 이미 반영). 값으로 쓰는 코드는 그대로 컴파일되지만 exhaustive switch 는 `success` 로 바꿔야 한다. 그리고 variant 를 명시하지 않은 Toast 의 렌더가 바뀐다 — 초록 성공 체크가 사라지고 글리프 없는 토스트가 된다.
* **core:** `CoreToastVariant` 에 `neutral` 이 늘었다(#4505 에서 이미 반영) — 이 enum 을 exhaustive 하게 switch 하는 코드는 arm 을 추가해야 한다. `default_` 와 `destructive` 의 채움/전경 토큰도 바뀐다(양 모드 렌더 변경).
* **core:** `CoreFormattedInputStyle` 에 nullable 필드 둘(`disabledBackgroundColor` / `disabledBorderColor`)이 늘었다(#4505 에서 이미 반영). `==`/`hashCode` 대상이므로, 그 값을 쓰던 캐시나 스냅샷은 재계산된다.
* **core:** `CoreBannerVariant.default_` 가 `neutral` 로 이름이 바뀌고(@Deprecated alias 유지), `CoreAlertVariant.defaultVariant` 멤버도 `neutral` 로 바뀐다(#4505 에서 이미 반영). `Alert.title` 이 required, `description` 이 optional 로 뒤집힌다. Banner 에 `emphasis` 축(`weak`/`solid`)이 생겨 `defaultsByVariant` 가 중첩 Map 이 된다.
* **core:** `CoreTextAreaStyle.defaultsByVariant` 의 키가 `bool` 에서 `CoreTextAreaVariant` 로 바뀐다(#4606 에서 이미 반영). 이 표를 직접 첨자하는 코드는 `CoreTextAreaVariant.of(hasError: …)` 를 거쳐야 한다. 위젯 사용처는 영향이 없다 — `TextArea` 는 여전히 `errorText` 만 받는다.
* **core:** `CoreTextFieldStyle` · `CoreTextAreaStyle` · `CoreFormattedInputStyle` · `CorePhoneInputStyle` · `CoreChipInputStyle` 의 `defaultBorderRadius` 가 `radius4` 에서 `radius8` 로 바뀐다 — 기본 렌더의 모서리가 커지고, 이 필드를 합성하는 컴포넌트의 안쪽 필드도 같이 바뀐다. 이전 모서리를 원하면 `xxxStyle: CoreXxxStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius4))` 로 명시한다.
* `CoreBadgeContract.child` 가 `W` 에서 `W?` 로 바뀌고 `CoreBadgeContract.form` getter 가 새로 생긴다. 이 계약을 직접 `implements` 하는 코드는 두 멤버를 갱신해야 한다. Flutter/Web `Badge` 위젯 사용처는 영향이 없다 — `child` 는 더 관대해진 방향이고 `form` 은 `CoreBadgeForm.count` 기본값을 갖는다.
* **core:** 모든 lg Button 의 라벨이 14→16 으로 커진다 (시각 변경).
* **core,flutter,web,figma:** AppBar 의 withStyle patch 타입이 CoreScaffoldStyle 에서 CoreAppBarStyle 로 바뀌고, ResolvedScaffold 에서 headerPadding/headerSpacing/ headerActionSpacing 이 빠진다(소비 위젯 0). scaffoldStyle 파라미터는 deprecated 매핑으로 동작을 유지한다.
* **core:** `CoreNavigationBarStyle.defaultItemSpacing` 이 예고 없이 제거됐다 (0.131). 모드마다 값이 다르므로 스칼라 대체재는 없다 — `CoreNavigationBarStyle.defaultsByMode[mode].spacing` 을 읽어라 (`bar` 는 0, `rail` · `sidebar` 는 8). `itemSpacing` 필드 자체는 그대로이므로 인스턴스 오버라이드는 영향받지 않는다.
* **core:** `CoreTypography` 생성자에 `labelXl2` · `labelXl` required 파라미터 둘이 늘었다 (15 → 17) — 이 타입을 직접 생성하는 코드는 컴파일이 깨진다. 그리고 `labelLarge` · `labelMedium` · `labelSmall` 의 weight 가 regular(400) 에서 medium(500) 으로 올랐다. 라벨을 쓰는 모든 컨트롤의 렌더가 양 플랫폼에서 바뀐다.

### 기능

* Badge 가 점을 그릴 수 있게 된다 — 캔버스의 Style 축을 흡수 ([#4606](https://github.com/coco-de/coui/issues/4606)) ([e454861](https://github.com/coco-de/coui/commit/e4548610f49ef6f7b41cdb6c591fab5a9eb3e5d8))
* **core,figma:** @Deprecated · [@behaviour](https://github.com/behaviour)Only 변형은 캔버스에 오르지 않는다 — Button 의 text 와 fixed ([5025acc](https://github.com/coco-de/coui/commit/5025acc088e6868e1ad4830c5af5d828eeac9445))
* **core,flutter,web,figma:** AppBar 가 디자이너 세트를 스펙으로 얻는다 — 계약 신설 · 양 플랫폼 이동 · 빌더 등록 ([7c154ba](https://github.com/coco-de/coui/commit/7c154ba1f85c8b74747ad2c7398112c4d8dc0e44))
* **core:** Button lg 라벨 16 단계 + 어피스 radius 중첩 관례 + ChipInput compact pill 회귀 수정 ([bd36c12](https://github.com/coco-de/coui/commit/bd36c1228d6df844a57d2a38aa0fd2dfba091a4a)), closes [#4581](https://github.com/coco-de/coui/issues/4581) [#4582](https://github.com/coco-de/coui/issues/4582)
* **core:** CoreButtonVariantStyle.stateLayer 재고지 — [#4616](https://github.com/coco-de/coui/issues/4616) 도 squash 로 버렸다 ([5336ebb](https://github.com/coco-de/coui/commit/5336ebb0aaa8325e12bfe4a7c61d8791dc34d09a))
* **core:** CoreFormattedInputStyle disabled 색상 필드 재고지 — [#4616](https://github.com/coco-de/coui/issues/4616) 도 squash 로 버렸다 ([ce4100f](https://github.com/coco-de/coui/commit/ce4100fc647d72b1c7e88c93debe598dc813ea85))
* **core:** CoreToastVariant.default_ deprecated 재고지 — [#4616](https://github.com/coco-de/coui/issues/4616) 도 squash 로 버렸다 ([f567d1a](https://github.com/coco-de/coui/commit/f567d1a5ad7f23c2e4d1da8c8e4350f5ad11ebf9))
* **core:** CoreToastVariant.neutral 재고지 — [#4616](https://github.com/coco-de/coui/issues/4616) 도 squash 로 버렸다 ([eaa12ae](https://github.com/coco-de/coui/commit/eaa12ae9924998351c2732659fc05afcb37f22a5))
* **core:** display 역할이 regular(400) 로 — light 는 대형 제목에서 획이 사라진다 ([#4617](https://github.com/coco-de/coui/issues/4617)) ([d35041b](https://github.com/coco-de/coui/commit/d35041b0f65e55c086d425abb536ecd71bccb634))
* **core:** TextArea `defaultsByVariant` 키 변경 고지 — [#4606](https://github.com/coco-de/coui/issues/4606) 의 squash 가 버린 둘째 푸터 ([b53bd1d](https://github.com/coco-de/coui/commit/b53bd1d8f2a6bc8c06564abfd5bdcd3080752c4f))
* **core:** 입력 계열의 모서리가 selector tier(radius8)로 올라간다 — Button 과 같은 값 ([3a1d635](https://github.com/coco-de/coui/commit/3a1d6358c33679ef299bb97b52d857da41d20860))


### 버그 수정

* **core,docs:** 게이트 둘이 잡은 것 — FAB 마커 레지스트리 · 생성 표 stale ([579529c](https://github.com/coco-de/coui/commit/579529cbcd3c23be64ae2cde3eedd91739418efd))
* **core,flutter,web,figma:** Toast 액션이 슬랩 위에서 읽힌다 — 2.1:1 과 1.0:1 을 고친다 ([#4610](https://github.com/coco-de/coui/issues/4610)) ([73b93fe](https://github.com/coco-de/coui/commit/73b93fe582a6966c2a5b48a7be00dc7bea2c6fff))
* **core:** [#4505](https://github.com/coco-de/coui/issues/4505) 의 squash 가 버린 breaking-change 푸터 5개 복원 ([#4616](https://github.com/coco-de/coui/issues/4616)) ([ea3efc9](https://github.com/coco-de/coui/commit/ea3efc9852a052fe51ff288d35fc0193f54f25ae))
* **figma,core:** 라벨 행간 120% + Fab 를 메뉴로 + Toast/Chip/Toggle 캔버스 결함 정리 ([2aea28a](https://github.com/coco-de/coui/commit/2aea28a061eb5b7974eba8423731f789aead09dc))


### 문서

* **core:** CoreTypography 가 17 역할이라고 말하게 한다 ([97709ea](https://github.com/coco-de/coui/commit/97709ea724fb127ddfdf1fff895ac662c51012e0))
* **core:** deprecation 의 since 마커를 실제 출하 버전으로 정정 ([4fce8de](https://github.com/coco-de/coui/commit/4fce8de98acefc58561dd03a028ce456b0fc4927))
* **core:** Toast 문서가 개명 이후의 자기 자신을 설명하게 한다 ([b7e38ee](https://github.com/coco-de/coui/commit/b7e38eee11c5817cebccd9f2f88f6655d42bfffe))
* **core:** 사라진 NavigationBar 기본 간격의 행방을 소스에 남긴다 ([81bae74](https://github.com/coco-de/coui/commit/81bae74b9603c1ac2c93b1624b1fdbf7579b6ac6))

## [0.131.0](https://github.com/coco-de/coui/compare/coui_core-v0.130.0...coui_core-v0.131.0) (2026-08-31)


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
* **core:** CoUI 가 안 쓰는 유채색 램프를 바인딩하면 실패한다 ([#4485](https://github.com/coco-de/coui/issues/4485)) ([e2f0bdc](https://github.com/coco-de/coui/commit/e2f0bdca7ff14605281dab5cce3b327a3058396a))
* **core:** label role 이 body 보다 무거워지고, 계열이 사다리 끝까지 이어진다 ([#4556](https://github.com/coco-de/coui/issues/4556)) ([3629255](https://github.com/coco-de/coui/commit/3629255985a679086c3a100741a3002bb082ded1))
* **core:** opacity/3 신설 · hover 를 3% 로 · Figma opacity 를 0–100 으로 내보낸다 ([#4447](https://github.com/coco-de/coui/issues/4447)) ([7b661d7](https://github.com/coco-de/coui/commit/7b661d7138b4ac69525b62c8ddefd3bab36e26cc))
* **core:** 대비 가드가 선언된 짝이 아니라 렌더되는 짝을 본다 ([#4487](https://github.com/coco-de/coui/issues/4487)) ([1ee8d5f](https://github.com/coco-de/coui/commit/1ee8d5f3ced92c03b2629b66fab941bf15f1c275))
* **core:** 브랜드가 시맨틱 매핑을 소유한다 — Figma 토큰 편집 역동기화 ([#4434](https://github.com/coco-de/coui/issues/4434)) ([96ba6e9](https://github.com/coco-de/coui/commit/96ba6e976d19765d3d09966daabaa4422c09cabb))
* **core:** 플레이스홀더가 자기 색 슬롯을 갖는다 ([#4477](https://github.com/coco-de/coui/issues/4477)) ([a24b142](https://github.com/coco-de/coui/commit/a24b1423e276ab88a05ea010a908e1ed6a4b4b09))
* **guards:** 아무도 읽지 않는 default* 를 센다 — orphan 짝의 반대 방향 ([#4490](https://github.com/coco-de/coui/issues/4490)) ([be7c54e](https://github.com/coco-de/coui/commit/be7c54e01e362d98a9898d0161a1147d8f1e465e))


### 버그 수정

* **core,flutter,web:** [#4405](https://github.com/coco-de/coui/issues/4405) — 참조 reverse 캐스트 모션을 양 플랫폼에 구현 ([#4432](https://github.com/coco-de/coui/issues/4432)) ([6bf6cf0](https://github.com/coco-de/coui/commit/6bf6cf0684cd12bf7910dcce31dda7cd9f8d4883))
* **core,flutter:** 비활성 버튼이 비활성으로 보이게 한다 — 12 variant 전부 ([#4456](https://github.com/coco-de/coui/issues/4456)) ([c68273a](https://github.com/coco-de/coui/commit/c68273a5e44c54036a5954d550096f2dc9ebd93a))
* **core,parity:** destructive 버튼이 자기 채움 위에서 읽히게 하고, 못 읽히는 것을 셀 수 있게 한다 ([#4451](https://github.com/coco-de/coui/issues/4451)) ([b462920](https://github.com/coco-de/coui/commit/b4629205bd3e29645d0bab2e66141e02157e0095))
* **core:** [#4382](https://github.com/coco-de/coui/issues/4382) — crossing() 의 t 를 셀 안으로 묶고 그 불변식을 테스트로 고정 ([#4385](https://github.com/coco-de/coui/issues/4385)) ([71348bb](https://github.com/coco-de/coui/commit/71348bb1206ba57743738cd5c3ddb0eeec557387))
* **core:** [#4509](https://github.com/coco-de/coui/issues/4509) — 상태 램프가 두 벌이었고, 캔버스로 나가는 쪽이 틀린 값이었다 ([#4515](https://github.com/coco-de/coui/issues/4515)) ([b9b29d6](https://github.com/coco-de/coui/commit/b9b29d6eca6682384d1163e6e7d48edd0fde375c))
* **core:** card 버튼의 hover·selected 에서 글자가 보이게 한다 ([#4482](https://github.com/coco-de/coui/issues/4482)) ([262723f](https://github.com/coco-de/coui/commit/262723f5950494cd16a2745c25ad35bf849ad812))
* **core:** Chip 의 custom-seed 비활성 기본값이 자기 주석대로 되게 한다 ([#4484](https://github.com/coco-de/coui/issues/4484)) ([dc3b930](https://github.com/coco-de/coui/commit/dc3b9303536c81e70da2934d78f989dd5eb47580))
* **core:** destructive 버튼의 hover 가 실제로 읽히게 한다 — 알파 채움 유지, 대상은 이 variant 하나 ([#4498](https://github.com/coco-de/coui/issues/4498)) ([03c8816](https://github.com/coco-de/coui/commit/03c88167bfd398e103061cba4332953a1d11e8a1))
* **core:** 검증 힌트를 자기가 서 있는 자리에 맞춘다 — 아이콘 16 · 본문 bodySmall ([#4480](https://github.com/coco-de/coui/issues/4480)) ([de8c964](https://github.com/coco-de/coui/commit/de8c964b1e09e81c4d3a7965c85db7fd14d26898))
* **core:** 모프 비용 테스트가 자기가 주장하는 것을 재게 한다 ([#4483](https://github.com/coco-de/coui/issues/4483)) ([17757ea](https://github.com/coco-de/coui/commit/17757eaa9e398300dafa1950c445cd7183bbb221))
* **core:** 비활성 라벨을 읽을 수 있게 한다 — disabled-content 는 그래픽 전용 ([#4489](https://github.com/coco-de/coui/issues/4489)) ([b9f19db](https://github.com/coco-de/coui/commit/b9f19db12c5ab9bb8f43ba80c9060dfcdbfc67c0))
* **core:** 자기 틴트 위에 놓인 라벨이 읽히게 한다 — Alert · ValidationBadge ([#4486](https://github.com/coco-de/coui/issues/4486)) ([f426303](https://github.com/coco-de/coui/commit/f426303f1001b166372993f71a44b0f062c0380c))
* **flutter,core:** 버튼이 자기 크기 토큰만큼만 크다 — 밀도 축 포함, 그리고 그걸 놓친 가드 ([#4458](https://github.com/coco-de/coui/issues/4458)) ([84c286a](https://github.com/coco-de/coui/commit/84c286a4b463299aa14532cc00a91536d7a46b27))
* **web,flutter:** [#4407](https://github.com/coco-de/coui/issues/4407) — press 전환을 duration 변수 경유로, 상태는 유지 ([#4425](https://github.com/coco-de/coui/issues/4425)) ([af9fd27](https://github.com/coco-de/coui/commit/af9fd2735bba596b936dbb227f6c82b3d73856c2))


### 문서

* **core:** destructive hover — 라이트는 임시임을 소스에 남긴다 ([#4502](https://github.com/coco-de/coui/issues/4502)) ([5b61d65](https://github.com/coco-de/coui/commit/5b61d658ef9427ff2a44251c334add6b99506e57))


### 기타

* **deps:** [#4439](https://github.com/coco-de/coui/issues/4439) — Flutter 3.47.0 · jaspr 0.23.4 로 툴체인 상향 ([#4440](https://github.com/coco-de/coui/issues/4440)) ([a033bed](https://github.com/coco-de/coui/commit/a033beda885234867322886211f342e03e93ea41))

## [0.130.0](https://github.com/coco-de/coui/compare/coui_core-v0.129.0...coui_core-v0.130.0) (2026-08-18)


### ⚠ BREAKING CHANGES

* **surface:** #4217 — 유리 오버레이가 자기 트리거에서 자라난다 ([#4302](https://github.com/coco-de/coui/issues/4302))

### 기능

* **coui:** DefinitionList · DisclosureBadge 신설 ([#4260](https://github.com/coco-de/coui/issues/4260)) ([ae07784](https://github.com/coco-de/coui/commit/ae07784601d55b23b6de805b3744a0a080001719))
* **figma:** Generate 페이지 순서를 docs 사이트 큐레이션 순서로 바꾼다 ([#4333](https://github.com/coco-de/coui/issues/4333)) ([41b58fa](https://github.com/coco-de/coui/commit/41b58fac35527aad713773371677f611a174e97d))
* **figma:** 브랜드 축 — 브랜드별 Semantic/Color 컬렉션 + 리바인딩 플러그인 커맨드 ([#4290](https://github.com/coco-de/coui/issues/4290)) ([ff0d254](https://github.com/coco-de/coui/commit/ff0d2540cf92a8a06272367dfdec3e0577dc9a72))
* **figma:** 플러그인 UI 탭 리디자인 · Unibook 팔레트 교체 · 게시 에셋 ([#4303](https://github.com/coco-de/coui/issues/4303)) ([0f9c2be](https://github.com/coco-de/coui/commit/0f9c2bef9ff76b2600a95f0b0787fdf509302c49))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 모프 클립을 양 플랫폼에 세운다 ([#4300](https://github.com/coco-de/coui/issues/4300)) ([9c39a2b](https://github.com/coco-de/coui/commit/9c39a2b65b63b6e6d00b5283fe656366685c4d61))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 모프의 모션과, 그게 감당 가능하다는 측정 ([#4295](https://github.com/coco-de/coui/issues/4295)) ([ca02123](https://github.com/coco-de/coui/commit/ca021234401de5a518de2385001257146b447ad1))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 모프의 실루엣을 Core 산술로 (셰이더 없이) ([#4286](https://github.com/coco-de/coui/issues/4286)) ([bdd071c](https://github.com/coco-de/coui/commit/bdd071c10eb3bcfe0e31da9b6384078068fc69df))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 유리 오버레이가 자기 트리거에서 자라난다 ([#4302](https://github.com/coco-de/coui/issues/4302)) ([57e1e0f](https://github.com/coco-de/coui/commit/57e1e0f3c25194608fa541c597e329f0684674a4))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 유리 표면의 경계는 재질이 그린다 ([#4284](https://github.com/coco-de/coui/issues/4284)) ([9edf08e](https://github.com/coco-de/coui/commit/9edf08e93243224043b6a8153edfe8196d45e2b9))
* **surface:** [#4217](https://github.com/coco-de/coui/issues/4217) — 유리가 유리처럼 보일 만큼 재질을 올린다 ([#4306](https://github.com/coco-de/coui/issues/4306)) ([fa604e5](https://github.com/coco-de/coui/commit/fa604e567b29779c6f7bf9542c24fc774879c060))
* **surface:** [#4329](https://github.com/coco-de/coui/issues/4329) — 투명도 줄이기 폴백을 Flutter 에서도 켤 수 있게 한다 ([#4341](https://github.com/coco-de/coui/issues/4341)) ([5bff601](https://github.com/coco-de/coui/commit/5bff601e25cce6793ad51c724fc0e7681ecc1661))
* **surface:** [#4369](https://github.com/coco-de/coui/issues/4369) — 바닥값이 못 올리는 0 에, 스타일이 경계를 직접 기여한다 ([#4370](https://github.com/coco-de/coui/issues/4370)) ([ab9694b](https://github.com/coco-de/coui/commit/ab9694bd8512e646939b21435f4109a0752aed20))
* **web,core:** [#4217](https://github.com/coco-de/coui/issues/4217) — 투명도 줄이기 요청에 유리가 답한다 (G5) ([#4305](https://github.com/coco-de/coui/issues/4305)) ([1f40f64](https://github.com/coco-de/coui/commit/1f40f6400f9ce3429281a90d4932b08175d1b15d))


### 버그 수정

* **figma:** 플러그인 섹션을 docs 그룹과 1:1 정렬 — 4개 fold 를 10개 근-항등으로 ([#4277](https://github.com/coco-de/coui/issues/4277)) ([591d8ca](https://github.com/coco-de/coui/commit/591d8ca8ed63bdec302c81f437b5bb9a1d46b159))
* **web:** [#4314](https://github.com/coco-de/coui/issues/4314) — Sortable 이 자기 슬롯 위에서도 포인터를 따라오게 한다 ([#4315](https://github.com/coco-de/coui/issues/4315)) ([5cdde40](https://github.com/coco-de/coui/commit/5cdde40459b4e20762ff92bd38d88b5a21b630fa))

## [0.129.0](https://github.com/coco-de/coui/compare/coui_core-v0.128.1...coui_core-v0.129.0) (2026-08-12)


### ⚠ BREAKING CHANGES

* **layout:** Group 완전 삭제 — Stacks + Position 으로 완전 대체 ([#4273](https://github.com/coco-de/coui/issues/4273))
* **surface:** Text 체인의 accent fill getter 6종이 Web 에서 제거되고 Flutter 에서 deprecated 됐다. `.on{Role}Container` 로 교체한다.
* **core,flutter,web:** #4082 — #4001 후속 4건 (resizable 정규화 · focus-ring 슬롯/합성 3건) ([#4121](https://github.com/coco-de/coui/issues/4121))
* **flutter,web:** #3979 — a11y 감사 후속 5건 (Scrollbar 접근성 노드·값 축·플랫폼 대칭 + TimePicker 링) ([#3999](https://github.com/coco-de/coui/issues/3999))

### 기능

* **a11y:** [#3391](https://github.com/coco-de/coui/issues/3391) — nav 패밀리 role seat + Flutter expanded 배선 ([#3424](https://github.com/coco-de/coui/issues/3424)) ([c81ef74](https://github.com/coco-de/coui/commit/c81ef74cef84ab48cb75460a851d11f279e18de0))
* **a11y:** [#3426](https://github.com/coco-de/coui/issues/3426) — EmptyState 에 톤 축 (실패인 빈 상태 vs 그냥 빈 상태) ([#3431](https://github.com/coco-de/coui/issues/3431)) ([915fbb2](https://github.com/coco-de/coui/commit/915fbb2cc2a2145934a260496662e6019bbb14c7))
* **a11y:** 포인터 타겟 하한 — 그리는 크기가 아니라 닿는 범위를 넓힌다 ([#3410](https://github.com/coco-de/coui/issues/3410)) ([def5370](https://github.com/coco-de/coui/commit/def5370fd4753d95e5169a32ab47819cbb818c60))
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
* **core:** 대비 감사가 accent 를 전경으로 쓰는 경우를 보게 함 ([#3372](https://github.com/coco-de/coui/issues/3372)) ([5141532](https://github.com/coco-de/coui/commit/51415329bab424b3de1678779b4f1ea57c781802))
* **core:** 시맨틱 role seat — Core 가 들고 있던 raw ARIA 문자열 제거 ([#3403](https://github.com/coco-de/coui/issues/3403)) ([766360a](https://github.com/coco-de/coui/commit/766360a38dcc32b8163b8ec7cd3f57462d79777a))
* **cross-platform:** [#4186](https://github.com/coco-de/coui/issues/4186) — 잔여 3건 (divider childAlignment · 피드백 전역 opt-out · Web 버튼 chrome 전환) ([#4257](https://github.com/coco-de/coui/issues/4257)) ([ed2b409](https://github.com/coco-de/coui/commit/ed2b409f58b92cdcca3c941497bf78aa436942c7)), closes [#4200](https://github.com/coco-de/coui/issues/4200) [#4201](https://github.com/coco-de/coui/issues/4201) [#4202](https://github.com/coco-de/coui/issues/4202)
* **figma-token-sync:** [#4012](https://github.com/coco-de/coui/issues/4012) — schema v3 axes 판독기 (4축 + other 전수) ([#4051](https://github.com/coco-de/coui/issues/4051)) ([c506843](https://github.com/coco-de/coui/commit/c5068437fad62961b2e98c2ea94a445d0dda4495))
* **figma-token-sync:** [#4019](https://github.com/coco-de/coui/issues/4019) — schema v3 seal (meta 마커 · 순서 고정 테스트 · README) ([#4062](https://github.com/coco-de/coui/issues/4062)) ([c9c8331](https://github.com/coco-de/coui/commit/c9c8331139736db818bc7f020147097a6d756028))
* **figma-token-sync:** [#4099](https://github.com/coco-de/coui/issues/4099) — TEXT·BOOLEAN component property 도입 (§4-3 해제, D-25) ([#4108](https://github.com/coco-de/coui/issues/4108)) ([2702cd1](https://github.com/coco-de/coui/commit/2702cd1c8269b4bdb5fe0328bfd43f4c70e0ffc6))
* FormattedInput 단일 필드 마스크 재설계 — 백스페이스 연속성 · 커스텀 마스크 · 자동완성 ([#3866](https://github.com/coco-de/coui/issues/3866)) ([#3900](https://github.com/coco-de/coui/issues/3900)) ([68e8513](https://github.com/coco-de/coui/commit/68e8513867da78c58b3421791e32b759e651cb39))
* **i18n:** [#3429](https://github.com/coco-de/coui/issues/3429) — 논리 방향 inset (가로 비대칭 4건 전부) ([#3438](https://github.com/coco-de/coui/issues/3438)) ([ee951e4](https://github.com/coco-de/coui/commit/ee951e419b99d5356ebc3882c866155f8c7dd205))
* **icon:** 아이콘 크기 사다리 — 실제 결함은 네임스페이스 반전이었다 ([#3420](https://github.com/coco-de/coui/issues/3420)) ([625baa4](https://github.com/coco-de/coui/commit/625baa49cca467a0cfeec898285f8f4dd1a5cdee))
* **layout:** Group 완전 삭제 — Stacks + Position 으로 완전 대체 ([#4273](https://github.com/coco-de/coui/issues/4273)) ([a0e621b](https://github.com/coco-de/coui/commit/a0e621b61536da3cc0cfd5f11013530463c8d5e3))
* neo-brutalism 대각선 그림자·press-squash(Button/Fab) + card_image OutlinedContainer 합성 ([#4178](https://github.com/coco-de/coui/issues/4178)) ([78d74e6](https://github.com/coco-de/coui/commit/78d74e6e610babf82c78719b16b227db01dc8de9))
* **phone_input:** 전화번호 완전성 validator — Form 이 "완전한 번호" 를 말할 수단 ([#4243](https://github.com/coco-de/coui/issues/4243)) ([a36fe90](https://github.com/coco-de/coui/commit/a36fe90f6f8970b68f4edc92e6f1e1683c744fb9))
* Project [#3294](https://github.com/coco-de/coui/issues/3294) — 디자인 시스템 견고화 (접근성 축 10건 + 서피스 프리셋 축 4건) ([#3349](https://github.com/coco-de/coui/issues/3349)) ([5b6287d](https://github.com/coco-de/coui/commit/5b6287d1c48b73eb208b3838bd94effb9d9b1711))
* **surface:** [#4208](https://github.com/coco-de/coui/issues/4208) — 앱이 서페이스 프리셋을 자기 값으로 튜닝한다 ([#4240](https://github.com/coco-de/coui/issues/4240)) ([44093f7](https://github.com/coco-de/coui/commit/44093f75698976755992e85af17e642260ce4794))
* **surface:** [#4222](https://github.com/coco-de/coui/issues/4222) — 굴절은 축이 아니라 표면이 여는 역량이다 ([#4270](https://github.com/coco-de/coui/issues/4270)) ([f3bf226](https://github.com/coco-de/coui/commit/f3bf226879382ecb1e064dcffbc22cdd80488c48))
* **theme:** [#2865](https://github.com/coco-de/coui/issues/2865) — Neo-brutalism 프리셋 (첫 E2E) + docs 스타일 스위처 ([#3357](https://github.com/coco-de/coui/issues/3357)) ([40d6999](https://github.com/coco-de/coui/commit/40d69999eac9210c1050a71e9394c7f30d7e31b6))
* **theme:** [#3183](https://github.com/coco-de/coui/issues/3183) — 내비 표면이 재질을 받고, 떠 있을 수 있다 ([#3436](https://github.com/coco-de/coui/issues/3436)) ([7ae43c4](https://github.com/coco-de/coui/commit/7ae43c42ba4ebdc5e0dc66011627ef29fb5b4e1d))
* **theme:** 그림자 미러 축 — 배율로는 두 번째 방향을 만들 수 없다 ([#3414](https://github.com/coco-de/coui/issues/3414)) ([8691726](https://github.com/coco-de/coui/commit/86917267025647d0d210208a87046e195f4f0874))
* **theme:** 남은 프리셋 3종 (Glass · Neumorphism · Claymorphism) + orphan surface 필드 배선 ([#3362](https://github.com/coco-de/coui/issues/3362)) ([536bafc](https://github.com/coco-de/coui/commit/536bafceb1be2faf85fdda7e8aae755e559e3e98))
* **theme:** 표면 스타일이 반경 범위를 진술 — 사다리 위 재배치 ([#3407](https://github.com/coco-de/coui/issues/3407)) ([9c39d49](https://github.com/coco-de/coui/commit/9c39d490fb70f613d034ff39423e725cdddaace3))
* **web:** [#3763](https://github.com/coco-de/coui/issues/3763) — Core↔docs 정합 트랙 A(Web transport 결함) 완료 ([#3845](https://github.com/coco-de/coui/issues/3845)) ([5e558b9](https://github.com/coco-de/coui/commit/5e558b94bc79e8fcffae810e892b45876c9600f5))


### 버그 수정

* **autocomplete:** [#4188](https://github.com/coco-de/coui/issues/4188) — replaceWord 가 캐럿 위치의 단어를 완성한다 ([#4215](https://github.com/coco-de/coui/issues/4215)) ([cf69ea0](https://github.com/coco-de/coui/commit/cf69ea02ecf7ea66b0cc2d6de224b5c50303fe46))
* **core,flutter,web:** [#3495](https://github.com/coco-de/coui/issues/3495) — 드래그-스크롤 뷰포트를 보조 기술·키보드에 노출 ([#3958](https://github.com/coco-de/coui/issues/3958)) ([cd1a0f7](https://github.com/coco-de/coui/commit/cd1a0f7e0c513349fcce5aec7cb2a684b40f6923))
* **core,flutter,web:** [#3502](https://github.com/coco-de/coui/issues/3502) B — warning fill 을 텍스트 색에서 분리 (WCAG 1.4.3) ([#3973](https://github.com/coco-de/coui/issues/3973)) ([3c4e8d2](https://github.com/coco-de/coui/commit/3c4e8d2206a7e065a4f99129443bfad5cd69a70a))
* **core,flutter,web:** [#4082](https://github.com/coco-de/coui/issues/4082) — [#4001](https://github.com/coco-de/coui/issues/4001) 후속 4건 (resizable 정규화 · focus-ring 슬롯/합성 3건) ([#4121](https://github.com/coco-de/coui/issues/4121)) ([edf91db](https://github.com/coco-de/coui/commit/edf91db8f06b411496f091d65387e90fdf6a3957))
* **core,flutter,web:** [#4126](https://github.com/coco-de/coui/issues/4126) — [#4082](https://github.com/coco-de/coui/issues/4082) 후속 3건 (circle 링 죽은 필드 · badge offset 색 · 슬롯 clobber) ([#4139](https://github.com/coco-de/coui/issues/4139)) ([c9d60b7](https://github.com/coco-de/coui/commit/c9d60b78942e32bc8980e8c2e40e87e772988d67))
* **core,flutter:** [#3501](https://github.com/coco-de/coui/issues/3501) — outline 경계 3:1 + accent fill 4.5:1 (WCAG 1.4.11 · 1.4.3) ([#3962](https://github.com/coco-de/coui/issues/3962)) ([7e86d1d](https://github.com/coco-de/coui/commit/7e86d1d5dc4f4f0f086b23d49d5f7508bd0448cd))
* **core:** [#4237](https://github.com/coco-de/coui/issues/4237) — 두 엣지 run 이 양 모드에서 다 보인다 ([#4241](https://github.com/coco-de/coui/issues/4241)) ([9460b01](https://github.com/coco-de/coui/commit/9460b01ddfa1f1b3d4cc2c63178cf58aa7423a51))
* **core:** 그림자 색을 컴포넌트가 아니라 팔레트가 진술하게 함 ([#3396](https://github.com/coco-de/coui/issues/3396)) ([29b7f39](https://github.com/coco-de/coui/commit/29b7f39c5aba5655de0a6de1e3810756ceda2795))
* **docs:** 상태 토큰 예제가 읽을 수 없는 사용법을 시범하던 것 ([#3397](https://github.com/coco-de/coui/issues/3397)) ([d0e1ccf](https://github.com/coco-de/coui/commit/d0e1ccfe01ad1bf63fabfc2633722947f025fb93))
* **figma-token-sync:** [#4095](https://github.com/coco-de/coui/issues/4095) — 정보성 출력의 melos ERROR 라벨 제거 ([#4096](https://github.com/coco-de/coui/issues/4096)) ([a35ac08](https://github.com/coco-de/coui/commit/a35ac0892a42e5acb643b4454b52ef056a37f3ce))
* **flutter,web:** [#3771](https://github.com/coco-de/coui/issues/3771) — Form + Layout/Nav + Display + Overlay/Misc 25개 컴포넌트의 border/radius가 surface-style geometry 축을 안 탐 (Batch 1-5/5) ([#3828](https://github.com/coco-de/coui/issues/3828)) ([18f2df8](https://github.com/coco-de/coui/commit/18f2df82a359ff8fb9ebb9d52025b18a9119e1e2))
* **flutter,web:** [#3979](https://github.com/coco-de/coui/issues/3979) — a11y 감사 후속 5건 (Scrollbar 접근성 노드·값 축·플랫폼 대칭 + TimePicker 링) ([#3999](https://github.com/coco-de/coui/issues/3999)) ([5a017c9](https://github.com/coco-de/coui/commit/5a017c95449e6883eb287158ff8013023b285431))
* **flutter:** [#3718](https://github.com/coco-de/coui/issues/3718) — Command/Kbd border 가 surface-style geometry(strokeFloor)를 안 탐 ([#3719](https://github.com/coco-de/coui/issues/3719)) ([ad5e7fc](https://github.com/coco-de/coui/commit/ad5e7fc5c0d89f877081e37acad67602780e9919))
* **form:** 가려진 필드가 스펠체크·자동수정·IME 학습에 도달하지 않는다 ([#3409](https://github.com/coco-de/coui/issues/3409)) ([51b8a11](https://github.com/coco-de/coui/commit/51b8a115aa6ce97d833acb3a5dd1038ee118e945)), closes [#3385](https://github.com/coco-de/coui/issues/3385)
* **form:** 폼 입력 계약 4건 — 선언만 되고 아무도 안 읽던 필드 배선 ([#4224](https://github.com/coco-de/coui/issues/4224)) ([cb09aa9](https://github.com/coco-de/coui/commit/cb09aa95213ff6598781f63c36b0243bd6342458))
* **layout:** Epic D 4건 — join 포커스 링 · table intrinsic · stepper 앵커 · resizable optionalDivider ([#4255](https://github.com/coco-de/coui/issues/4255)) ([f1ccc24](https://github.com/coco-de/coui/commit/f1ccc249d1487f3545092db7ba01519d1c69647e))
* **navigation_menu:** [#4163](https://github.com/coco-de/coui/issues/4163) — 호버 애니메이션 Web/Flutter 파리티 (닫힘 디바운스 + 패널 전환 슬라이드) ([#4168](https://github.com/coco-de/coui/issues/4168)) ([22e257a](https://github.com/coco-de/coui/commit/22e257af8aaf1219646f8c4f58dba6884dcae1c8))
* **nav:** 선택 상태가 색으로만 구분되던 것에 비-색 신호 추가 ([#3394](https://github.com/coco-de/coui/issues/3394)) ([127b239](https://github.com/coco-de/coui/commit/127b239ccad07b02b802c122a37671e1807b49a7))
* **overlay:** [#3699](https://github.com/coco-de/coui/issues/3699) — Tooltip tooltipChild 기본 가시성 + panelMaxWidth 슬롯 ([#3700](https://github.com/coco-de/coui/issues/3700)) ([f898acb](https://github.com/coco-de/coui/commit/f898acb27cddc8f1151bc6fdd43294dc9e918c99))
* **parity:** 문서↔코드 · Flutter↔Web 드리프트 실측 수정 + 게이트 4종 ([#3440](https://github.com/coco-de/coui/issues/3440)) ([3953ef5](https://github.com/coco-de/coui/commit/3953ef58f8d3e60ae07a33db9fe2295077ab3992))
* **phone_input:** 입력값을 추측하지 않는다 — 타이핑된 다이얼 코드만 벗긴다 ([#4245](https://github.com/coco-de/coui/issues/4245)) ([8dde2aa](https://github.com/coco-de/coui/commit/8dde2aa7481d89ee009fb1c17ff6bfc47761f086))
* **surface:** 스타일 캐스트가 양 플랫폼에 같게 도달한다 ([#4242](https://github.com/coco-de/coui/issues/4242)) ([b01584f](https://github.com/coco-de/coui/commit/b01584fba7938b050e8bf275a4f90f8e93ffc1ec))
* **theme:** 표면 material 레이어를 알려진-죽음으로 — 가드 캐리어 확장 ([#3411](https://github.com/coco-de/coui/issues/3411)) ([b5a98df](https://github.com/coco-de/coui/commit/b5a98dfccdf24f5ceff723de891c3f92c92b01bb))
* **upstream:** shadcn_flutter 0.0.53 감사 확정 13건 이식 ([#4206](https://github.com/coco-de/coui/issues/4206)) ([b01519b](https://github.com/coco-de/coui/commit/b01519b2ba4fb18673d0cb359320f771bbb7934a))
* **web:** 그림자로만 경계를 그리는 프리셋에 forced-colors 경계를 실제로 그림 ([#3369](https://github.com/coco-de/coui/issues/3369)) ([3c5fc9d](https://github.com/coco-de/coui/commit/3c5fc9d91f8ceda619dd9f144e6b165e2301a824))


### 리팩터링

* **group:** deprecate Group — duplicates Stacks + Position ([#4094](https://github.com/coco-de/coui/issues/4094)) ([de4f177](https://github.com/coco-de/coui/commit/de4f177a2328688d291d28ac454d2ac28dccb53e))


### 문서

* **theme:** 밀도 축 결정 기록 — 필드는 만들지 않는다 ([#3418](https://github.com/coco-de/coui/issues/3418)) ([3643e0f](https://github.com/coco-de/coui/commit/3643e0f6cbb8ec1bfb76587bd1547ffa10347c6d))

## [0.128.1](https://github.com/coco-de/coui/compare/coui_core-v0.128.0...coui_core-v0.128.1) (2026-07-25)


### 버그 수정

* **button:** 🐛 outline variant 의 테두리가 surface alias 를 참조해 배경에 묻히던 문제 ([#3293](https://github.com/coco-de/coui/issues/3293)) ([#3324](https://github.com/coco-de/coui/issues/3324)) ([feb46b2](https://github.com/coco-de/coui/commit/feb46b2476f4e9b88abe9a5d8db317a7a628d06d))

## [0.128.0](https://github.com/coco-de/coui/compare/coui_core-v0.127.16...coui_core-v0.128.0) (2026-07-23)


### 기능

* **color:** ✨ ResolvedColorScheme — M3 슬롯 non-null 확정 (authored/resolved 분리) ([#3282](https://github.com/coco-de/coui/issues/3282)) ([0bde409](https://github.com/coco-de/coui/commit/0bde409fa7a5e6ec1a189c30fe268b28bae327ba))


### 리팩터링

* **web:** [#3285](https://github.com/coco-de/coui/issues/3285) — check_web_resolver 가드 green (Flutter 가드 미러 + 진짜 위반 실해소) ([#3287](https://github.com/coco-de/coui/issues/3287)) ([7884fc0](https://github.com/coco-de/coui/commit/7884fc0f616afd1607ad9a90f86b14a39e07206b))

## [0.127.16](https://github.com/coco-de/coui/compare/coui_core-v0.127.15...coui_core-v0.127.16) (2026-07-21)


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

# Changelog — coui_core

## 0.12.2 (2026-03-19)

### Fixed
- `CoreFocusRing.ringOpacity` 값을 1.0으로 변경 — Input 포커스 링 스타일 일치 (#935) (#936)

---

## 0.12.1 (2026-03-19)

### Fixed
- Web↔Flutter 애니메이션 Duration 토큰 크로스플랫폼 일관성 통일 (#934)

---

## 0.12.0 (2026-03-19)

### Added
- Web↔Flutter 크로스플랫폼 시각적 일관성 개선 — 공유 디자인 토큰 정렬 (#927) (#933)

---

## 0.11.0 (2026-03-18)

### Added
- `CoreDuration` 토큰 체계 도입 — xs(100ms), short(150ms), normal(200ms), medium(300ms)
- `CoreSpringConfig` 프리셋 — gentle, standard, bouncy, snappy, stiff

### Refactored
- kDefaultDuration/kToggleDuration을 CoreDuration 기반으로 통일 (#923) (#926)

---

## 0.10.0 (2026-03-18)

### Added
- 크로스플랫폼 `.simple()` API 지원을 위한 계약(contract) 정렬

---

## 0.9.0 (2026-03-18)

### Added
- Slider, DatePicker, TimePicker 크로스플랫폼 API 계약 정렬

---

## 0.8.0 (2026-03-18)

### Added
- `CoreRadiusScale` 기반 borderRadius 토큰 동기화 (#915)
  - field: extraSmall(4px), selector: small(8px), box: large(16px), badge: full(9999px)

---

## 0.7.6 (2026-03-18)

### Added
- `CoreThemePresets.previewLight` / `previewScaleFactor` — 프리뷰 스케일링 토큰 추가 (#908)

---

## 0.4.46 (2026-03-18)

### Refactored
- `CoreThemePresets`를 single source of truth로 통일 (#892)
  - Web(Tailwind config)과 Flutter(ThemeData) 모두 동일 소스 참조

---

## 0.3.0

### Added
- `CoreToastPosition` enum: bottomRight, bottomLeft, topRight, topLeft, bottomCenter, topCenter
- `CoreCheckboxContract`: `value` and `isIndeterminate` getters for state model alignment
- `CoreSelectItem.toCoreItem()`: Contract compatibility conversion method

### Improved
- Barrel export ordering normalized (alphabetical)
- CI verification script (`scripts/verify_contracts.sh`) for cross-package API consistency

---

## 0.2.0

### Breaking Changes
- **Contract naming normalization**: `isDisabled` → `enabled`, `isReadOnly` → `readOnly` across all contracts
- `CoreSelectItem.isDisabled` → `CoreSelectItem.enabled` (default `true`)
- `CoreTabItem.isDisabled` → `CoreTabItem.enabled` (default `true`)

### Added
- `CoreDrawerContract`: drawer/side panel component contract
- `CorePopoverContract`: popover/floating overlay contract
- `CoreMenuContract` + `CoreMenuItem`: menu component contract
- `CoreStepperContract` + `CoreStepItem`: stepper/wizard contract
- `CoreTreeContract` + `CoreTreeNode`: hierarchical tree contract
- `CoreDrawerPosition` enum: left, right, top, bottom
- `CorePopoverPlacement` enum: top, bottom, left, right

---

## 0.1.0

- Initial release with 20 component contracts
- Design tokens: color, typography, spacing, shape, motion, surface
- Callback types: `CoreVoidCallback`, `CoreValueChanged<T>`, `CoreValuePredicate<T>`, `CoreValueFormatter<T>`
- Design system adapters: DaisyUI, M3 Expressive, Liquid Glass
