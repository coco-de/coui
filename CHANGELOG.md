## 0.127.15 (2026-06-16)

### Refactored
- #2585 — DaisyUI color 레이어 전면 제거 (color_style.dart 삭제 + chain naming M3화) (#2601)

---

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

## 0.12.4 (2026-03-19)

### Fixed
- Flutter StarRating 프리뷰 별 모양을 Web SVG와 일치 (#940)

---

## 0.12.3 (2026-03-19)

### Documentation
- 패키지별 CHANGELOG 분리 및 Live Docs 파이프라인 완료 (#937)

---

## 0.12.2 (2026-03-19)

### Fixed
- Web/Flutter Input 포커스 링 스타일 일치 (#935) (#936)

---

## 0.12.1 (2026-03-19)

### Fixed
- Web↔Flutter 애니메이션 Duration 크로스플랫폼 일관성 통일 (#934)

---

## 0.12.0 (2026-03-19)

### Added
- Web↔Flutter 크로스플랫폼 시각적 일관성 개선 (#927) (#933)

---

## 0.11.0 (2026-03-18)

### Added
- Card에 hoverable 파라미터 및 hover shadow 애니메이션 추가 (#922) (#925)
- 컴포넌트에 명시적 transition duration 추가 (#921) (#924)

### Refactored
- kDefaultDuration/kToggleDuration을 CoreDuration 기반으로 통일 (#923) (#926)

---

## 0.10.0 (2026-03-18)

### Added
- 8개 컴포넌트 .simple() API로 Web/Flutter 구조 통일 (#919)
- ColorInput에 .simple() API 추가 (#912) (#918)

---

## 0.9.0 (2026-03-18)

### Added
- Slider, DatePicker, TimePicker에 .simple() API 추가 (#917)

---

## 0.8.1 (2026-03-18)

### Fixed
- Flutter TextField 높이를 Web과 동일하게 40px로 통일 (#916)

---

## 0.8.0 (2026-03-18)

### Added
- Tailwind borderRadius를 CoreRadiusScale 기반으로 동기화 (#915)

---

## 0.7.6 (2026-03-18)

### Refactored
- 프리뷰 스케일링을 coui_core로 이동하여 동기화 (#908)

---

## 0.7.5 (2026-03-18)

### Fixed
- Flutter 프리뷰 컴포넌트 크기를 Web과 맞춤 (#907)

---

## 0.7.4 (2026-03-18)

### Fixed
- Flutter 프리뷰 텍스트 노란 밑줄 수정 (#906)

---

## 0.7.3 (2026-03-18)

### Fixed
- Flutter 프리뷰 높이 최적화 및 Web 컴포넌트 중앙 정렬 (#905)

---

## 0.7.2 (2026-03-18)

### Fixed
- Flutter 프리뷰 크기가 그리드 컬럼을 초과하는 문제 수정 (#903)

---

## 0.7.1 (2026-03-18)

### Fixed
- Flutter 프리뷰 렌더링 영역 오버플로우 수정 (#902)

---

## 0.7.0 (2026-03-18)

### Added
- Flutter Toggle.simple() API 추가 — Web과 동일 코드 구조 (#900)

---

## 0.6.0 (2026-03-18)

### Added
- Flutter Checkbox.simple() API 추가 — Web과 동일 코드 구조 (#898)

---

## 0.5.1 (2026-03-18)

### Fixed
- Flutter 프리뷰 Checkbox 파라미터를 Web과 동일하게 통일 (#896)

---

## 0.5.0 (2026-03-18)

### Added
- Flutter Input에 primary/error named 생성자 추가 (#894)

---

## 0.4.46 (2026-03-18)

### Refactored
- CoreThemePresets를 single source of truth로 통일

### Other
- Merge pull request #892 from coco-de/refactor/unified-theme-from-coui-core

---

## 0.4.45 (2026-03-18)

### Fixed
- Flutter Badge 프리뷰 텍스트 가시성 개선 (#891)

---

## 0.4.44 (2026-03-18)

### Fixed
- 6개 컴포넌트 라이브 프리뷰 렌더링 통일 (#889)

---

## 0.4.43 (2026-03-18)

### Fixed
- Web Menubar 수평 레이아웃 — flex flex-row 명시 추가 (#886)
- DropdownMenu Live Preview 텍스트/아이템 Web/Flutter 통일 (#884)
- Web/Flutter ContextMenu 프리뷰 렌더링 통일 (#885)
- Swap 컴포넌트 체크박스 인라인 숨김 스타일 추가 (#887)

---

## 0.4.42 (2026-03-18)

### Fixed
- Swap 컴포넌트 체크박스 인라인 숨김 스타일 추가 (#887)

---

## 0.4.41 (2026-03-18)

### Fixed
- Web/Flutter Gap 코드 스니펫 및 프리뷰 API 통일 (#879)
- Tree Flutter 프리뷰 builder에 TreeItemView 적용 (#878)
- Resizable Live Preview 전체 너비 채움 및 핸들 표시 (#877)

---

## 0.4.40 (2026-03-18)

### Fixed
- Timeline 라이브 프리뷰 Web/Flutter 시간 형식 일치 (#874)

---

## 0.4.39 (2026-03-18)

### Fixed
- Web details/summary 네이티브 토글 + Flutter 프리뷰 수정 (#870)
- Stepper Live Preview 방향 Web/Flutter 통일 (#869)
- Web Steps 프리뷰 콘텐츠를 Flutter와 통일 (#871)

---

## 0.4.38 (2026-03-18)

### Fixed
- Web Steps 프리뷰 콘텐츠를 Flutter와 통일 (#871)

---

## 0.4.37 (2026-03-18)

### Fixed
- Alert 라이브 프리뷰 Web/Flutter 렌더링 일치 개선 (#865)

---

## 0.4.36 (2026-03-18)

### Fixed
- Swiper Live Preview 텍스트 Web/Flutter 통일 (#858)
- Web Tooltip group 클래스 누락 수정 및 프리뷰 통일 (#862)
- RefreshTrigger Flutter 프리뷰를 Web과 동일한 스타일로 통일 (#863)
- Accordion 코드 스니펫 내용을 프리뷰와 일치 (#861)

---

## 0.4.35 (2026-03-18)

### Fixed
- Accordion 코드 스니펫 내용을 프리뷰와 일치 (#861)

---

## 0.4.34 (2026-03-18)

### Fixed
- Web Popover 트리거를 hover → click(focus) 기반으로 변경 (#853)
- Web/Flutter Drawer 라이브 프리뷰 렌더링 통일 (#855)
- Toast 라이브 프리뷰 Web/Flutter 렌더링 일치 개선 (#854)

---

## 0.4.33 (2026-03-18)

### Fixed
- Toast 라이브 프리뷰 Web/Flutter 렌더링 일치 개선 (#854)

---

## 0.4.32 (2026-03-18)

### Fixed
- HoverCard Live Preview 텍스트 Web/Flutter 통일 (#849)

---

## 0.4.31 (2026-03-18)

### Fixed
- Flutter/Web 시각적 파리티 — showLabel 기본값 + 활성 페이지 스타일 (#846)
- Web Menu에 카드형 컨테이너 스타일 적용 (Flutter MenuPopup 일치) (#847)
- Breadcrumb Live Preview ol/li 기본 스타일 리셋 (#844)
- Switcher 라이브 프리뷰 Web/Flutter 렌더링 일치 개선 (#845)

---

## 0.4.30 (2026-03-18)

### Fixed
- Breadcrumb Live Preview ol/li 기본 스타일 리셋 (#844)
- Switcher 라이브 프리뷰 Web/Flutter 렌더링 일치 개선 (#845)

---

## 0.4.29 (2026-03-18)

### Fixed
- Live Preview Web/Flutter 렌더링 일치 (#838)
- Tabs Flutter 프리뷰에 콘텐츠 패널 추가 — Web TabPane과 시각 파리티 (#839)

---

## 0.4.28 (2026-03-18)

### Fixed
- NavigationBar 라이브 프리뷰 Web/Flutter 렌더링 일치 개선 (#835)

---

## 0.4.27 (2026-03-18)

### Fixed
- Flutter/Web 컴포넌트 시각적 파리티 — 테마 기본값 조율 (#832)
- Web/Flutter 키캡 색상/크기/스타일 통일 (#831)
- Menu 라이브 프리뷰 Web/Flutter 렌더링 일치 개선 (#833)

---

## 0.4.26 (2026-03-18)

### Fixed
- Web/Flutter 키캡 색상/크기/스타일 통일 (#831)
- Menu 라이브 프리뷰 Web/Flutter 렌더링 일치 개선 (#833)

---

## 0.4.25 (2026-03-18)

### Fixed
- Menu 라이브 프리뷰 Web/Flutter 렌더링 일치 개선 (#833)

---

## 0.4.24 (2026-03-18)

### Fixed
- Flutter Tracker 프리뷰 크기를 Web과 매칭

### Other
- Merge pull request #828 from coco-de/fix/827-tracker-preview-size

---

## 0.4.23 (2026-03-18)

### Fixed
- Link Web 코드 스니펫 text()→Text() 및 href 일치 (#825) (#826)

---

## 0.4.22 (2026-03-18)

### Fixed
- Flutter NumberTicker 프리뷰 글씨 크기/정렬 개선

### Other
- Merge pull request #824 from coco-de/fix/823-numberticker-style

---

## 0.4.21 (2026-03-18)

### Fixed
- HoverGallery Flutter 프리뷰 단색 블록 → 실제 이미지 (#821) (#822)

---

## 0.4.20 (2026-03-18)

### Fixed
- Loading 프리뷰 크기 및 코드 스니펫 Web 통일 (#819) (#820)

---

## 0.4.19 (2026-03-18)

### Fixed
- Stat borderRadius를 Web rounded-lg(8px)와 일치 (#816) (#817)

---

## 0.4.18 (2026-03-18)

### Fixed
- Stat Web 코드 스니펫 label/value 프리뷰 일치 (#814) (#815)

---

## 0.4.17 (2026-03-18)

### Fixed
- NumberTicker.value() 편의 생성자 추가 및 코드 스니펫 통일

### Other
- Merge pull request #813 from coco-de/fix/811-numberticker-value

---

## 0.4.16 (2026-03-18)

### Fixed
- Flutter Skeleton preview에 shimmer 애니메이션 추가 (#812)

---

## 0.4.15 (2026-03-18)

### Refactored
- unify CodeSnippet code examples across WEB/FLUTTER tabs (#810)

---

## 0.4.14 (2026-03-18)

### Fixed
- Flutter 라이브 프리뷰 무한 로딩 수정 — Typography.x2Large → x2l (#808) (#809)

---

## 0.4.13 (2026-03-18)

### Fixed
- Flutter Chip 프리뷰를 Web과 동일한 outline 스타일로 변경

### Other
- Merge pull request #807 from coco-de/fix/806-chip-outline-style

---

## 0.4.12 (2026-03-18)

### Fixed
- Calendar Web/Flutter 코드 스니펫 API 통일 (#800) (#801)
- Flutter Chat preview를 Web과 동일한 전체 구조로 통일 (#804)
- Flutter Carousel 프리뷰 텍스트 미표시 수정

### Refactored
- add String-based convenience factories for cross-platform API (#802)

### Other
- Merge pull request #805 from coco-de/fix/803-carousel-preview-text

---

## 0.4.11 (2026-03-18)

### Fixed
- Flutter Chat preview를 Web과 동일한 전체 구조로 통일 (#804)
- Flutter Carousel 프리뷰 텍스트 미표시 수정

### Refactored
- add String-based convenience factories for cross-platform API (#802)

### Other
- Merge pull request #805 from coco-de/fix/803-carousel-preview-text

---

## 0.4.10 (2026-03-18)

### Fixed
- Flutter Chat preview를 Web과 동일한 전체 구조로 통일 (#804)
- Flutter Carousel 프리뷰 텍스트 미표시 수정

### Other
- Merge pull request #805 from coco-de/fix/803-carousel-preview-text

---

## 0.4.9 (2026-03-18)

### Fixed
- Table 코드 스니펫 text()→Text() 수정 및 Role 칼럼/Badge 추가 (#795) (#798)
- Flutter Text 프리뷰 텍스트 색상 및 typography 수정

### Refactored
- add Progress.value() for cross-platform API unification (#796)

### Other
- Merge pull request #799 from coco-de/fix/797-text-preview-color

---

## 0.4.8 (2026-03-18)

### Fixed
- Flutter Text 프리뷰 텍스트 색상 및 typography 수정

### Other
- Merge pull request #799 from coco-de/fix/797-text-preview-color

---

## 0.4.7 (2026-03-18)

### Fixed
- Table 코드 스니펫 text()→Text() 수정 및 Role 칼럼/Badge 추가 (#795) (#798)

---

## 0.4.6 (2026-03-18)

### Fixed
- use CrossAxisAlignment.stretch for Flutter preview layout (#791)
- Badge.primary/secondary/destructive/outline factory 추가
- Web/Flutter Icon preview를 Lucide 아이콘으로 통일 (#792)

### Other
- Merge pull request #794 from coco-de/fix/793-badge-factory

---

## 0.4.5 (2026-03-18)

### Fixed
- Badge.primary/secondary/destructive/outline factory 추가

### Other
- Merge pull request #794 from coco-de/fix/793-badge-factory

---

## 0.4.4 (2026-03-18)

### Fixed
- Web/Flutter Icon preview를 Lucide 아이콘으로 통일 (#792)

---

## 0.4.3 (2026-03-17)

### Fixed
- Flutter preview 버튼이 보이지 않는 높이 해결 문제 수정 (#790)

---

## 0.4.2 (2026-03-17)

### Fixed
- Form preview onSubmit 시그니처 수정 — Flutter 클라이언트 빌드 복구 (#789)

---

## 0.4.1 (2026-03-17)

### Fixed
- prevent Flutter preview clipping and improve skeleton sizing (#788)

---

## 0.4.0 (2026-03-17)

### Added
- Web/Flutter visual parity — 커스텀 드래그앤드롭 UI (#787)

---

## 0.3.20 (2026-03-17)

### Fixed
- Flutter Card 프리뷰 높이 제약 추가

### Other
- Merge pull request #786 from coco-de/fix/785-card-preview-height

---

## 0.3.19 (2026-03-17)

### Fixed
- Badge Web 코드 스니펫 text() → Text() 대소문자 수정 (#780) (#782)
- Flutter Form 프리뷰를 실제 Form 위젯으로 변경

### Refactored
- add Avatar.initials() named constructor for cross-platform API (#781)

### Other
- Merge pull request #783 from coco-de/fix/779-form-preview-parity

---

## 0.3.18 (2026-03-17)

### Fixed
- Flutter Form 프리뷰를 실제 Form 위젯으로 변경

### Refactored
- add Avatar.initials() named constructor for cross-platform API (#781)

### Other
- Merge pull request #783 from coco-de/fix/779-form-preview-parity

---

## 0.3.17 (2026-03-17)

### Fixed
- Flutter Form 프리뷰를 실제 Form 위젯으로 변경

### Other
- Merge pull request #783 from coco-de/fix/779-form-preview-parity

---

## 0.3.16 (2026-03-17)

### Fixed
- replace static preview with actual drag-and-drop Sortable (#778)

---

## 0.3.15 (2026-03-17)

### Fixed
- Web/Flutter Fieldset 프리뷰를 코드 스니펫과 일치

### Other
- Merge pull request #777 from coco-de/fix/776-fieldset-preview-parity

---

## 0.3.14 (2026-03-17)

### Fixed
- Web StarRating을 SVG 별 아이콘으로 교체하여 Flutter와 visual parity 달성 (#773)
- Flutter PhoneInput placeholder 지원 추가 및 프리뷰 통일
- SwitchField 라이브 프리뷰 Web/Flutter 코드 스니펫 통일 (#770) (#772)

### Refactored
- add cross-platform convenience constructor (#771)

### Other
- Merge pull request #775 from coco-de/fix/774-phoneinput-placeholder

---

## 0.3.13 (2026-03-17)

### Fixed
- SwitchField 라이브 프리뷰 Web/Flutter 코드 스니펫 통일 (#770) (#772)

### Refactored
- add cross-platform convenience constructor (#771)

---

## 0.3.12 (2026-03-17)

### Refactored
- add cross-platform convenience constructor (#771)

---

## 0.3.11 (2026-03-17)

### Fixed
- RadioGroup Flutter 코드 스니펫을 Web API와 통일 (#764) (#767)
- Flutter InputOtp 프리뷰를 Web과 동일한 간단 API로 통일

### Refactored
- add cross-platform convenience constructor (#766)

### Other
- Merge pull request #768 from coco-de/fix/765-inputotp-preview-parity

---

## 0.3.10 (2026-03-17)

### Fixed
- Flutter InputOtp 프리뷰를 Web과 동일한 간단 API로 통일

### Refactored
- add cross-platform convenience constructor (#766)

### Other
- Merge pull request #768 from coco-de/fix/765-inputotp-preview-parity

---

## 0.3.9 (2026-03-17)

### Refactored
- add cross-platform convenience constructor (#766)

---

## 0.3.8 (2026-03-17)

### Fixed
- ColorPicker 라이브 프리뷰 Web/Flutter 비주얼 패리티 (#761) (#763)
- Web/Flutter DatePicker API 통합 및 비주얼 패리티 수정

### Other
- Merge pull request #762 from coco-de/fix/760-datepicker-visual-parity

---

## 0.3.7 (2026-03-17)

### Fixed
- Web/Flutter DatePicker API 통합 및 비주얼 패리티 수정

### Other
- Merge pull request #762 from coco-de/fix/760-datepicker-visual-parity

---

## 0.3.6 (2026-03-17)

### Refactored
- add cross-platform convenience constructor (#759)

---

## 0.3.5 (2026-03-17)

### Fixed
- Toggle/TextArea 라이브 프리뷰 Web/Flutter 비주얼 패리티 및 API 통일 (#749, #752) (#754)
- Web/Flutter Slider API 통합 및 비주얼 패리티 수정

### Refactored
- add cross-platform convenience constructor (#757)
- Select를 native <select>에서 button+dropdown 커스텀으로 교체 (#755)

### Other
- Merge pull request #758 from coco-de/fix/756-slider-visual-parity

---

## 0.3.4 (2026-03-17)

### Fixed
- Web/Flutter Slider API 통합 및 비주얼 패리티 수정

### Other
- Merge pull request #758 from coco-de/fix/756-slider-visual-parity

---

## 0.3.3 (2026-03-17)

### Refactored
- add cross-platform convenience constructor (#757)

---

## 0.3.2 (2026-03-17)

### Refactored
- Select를 native <select>에서 button+dropdown 커스텀으로 교체 (#755)

---

## 0.3.1 (2026-03-17)

### Refactored
- unify Input API across Flutter and Web (#753)

---

## 0.3.0 (2026-03-17)

### Added
- Web/Flutter API 통합을 위한 인라인 모드 추가

### Other
- Merge pull request #751 from coco-de/feat/fab-inline-mode

---

## 0.2.12 (2026-03-17)

### Refactored
- unify CommandItem API across Flutter and Web (#744) (#750)

---

## 0.2.11 (2026-03-17)

### Fixed
- FAB 컴포넌트 Flutter 프리뷰 actions 미표시 수정 (#747) (#748)

---

## 0.2.10 (2026-03-17)

### Fixed
- Flutter preview가 variant gallery에서 보이지 않는 문제 수정 (#746)

---

## 0.2.9 (2026-03-17)

### Fixed
- Web/Flutter visual parity 개선 및 문서 API 정확성 수정 (#745)

---

## 0.2.8 (2026-03-17)

### Fixed
- use RawText for inline scripts to prevent HTML entity escaping (#744)

---

## 0.2.7 (2026-03-16)

### Refactored
- Button 예제를 named constructor 형식으로 통일 (#743)

---

## 0.2.6 (2026-03-16)

### Fixed
- use RawText for inline scripts to prevent HTML entity escaping (#742)

---

## 0.2.5 (2026-03-16)

### Documentation
- 실험 단계 안내 배너 및 버전 업데이트 (#741)

---

## 0.2.4 (2026-03-16)

### Fixed
- version workflow에 actions:write 권한 추가 (#740)

---

## 0.2.3 (2026-03-16)

### Fixed
- version workflow에서 publish workflow 직접 트리거 (#739)

---

## 0.2.2 (2026-03-16)

### Fixed
- annotated tag 사용하여 태그 push 수정 (#738)

---

## 0.2.1 (2026-03-16)

### Fixed
- CHANGELOG 자동 버저닝 워크플로우 설명 추가 (#737)

---

## 0.1.0

- feat: initial commit 🎉