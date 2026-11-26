# liquid_glass_widgets 대조 — CoUI 글래스에서 무엇을 가져오고 무엇을 두는가

측정일 2026-09-11 · 대상 `sdegenaar/liquid_glass_widgets` v1.4.3 (Flutter ≥ 3.41, MIT,
`whynotmake-it/liquid_glass_renderer` 의 포크) · CoUI `main` @ `01de6d12c` · 실기기 macOS 26.6 Impeller(Metal) DPR 2 · Chromium 152 headless

## 한 줄 결론

패키지의 **렌더링 모델**은 iOS 26 을 셰이더로 재현하는 것이고, CoUI 의 모델은 **Figma Glass 효과의 어휘**(Refraction · Depth · Dispersion · Light angle · Light intensity)를 Core 계약 위에 두고 양 플랫폼이 같은 값을 읽어 그리는 것이다. 둘은 같은 것을 다르게 그리는 것이 아니라 **다른 정본**을 그린다 — CoUI 의 룩은 디자이너가 캔버스에서 고른 값이고 a11y 창(링 ↔ 띠 대비, 7쌍)까지 그 값 위에서 측정돼 있다. 그래서 이 대조에서 바로 가져올 수 있는 것은 룩이 아니라 **엔지니어링**이고, 그것도 "Web 이 이미 그렇게 하고 있는데 Flutter 만 어긋난 자리" 로 한정했다. 룩에 관한 것은 전부 Core 필드 → Flutter seat → Web seat 형태의 제안으로 남긴다.

**대조하다 발견한 것이 가져온 것보다 크다.** 출하 중인 Flutter 굴절은 표면이 아니라 **화면을 휘게 하고 있었다** — 화면 가장자리에 붙지 않은 유리 패널은 Flutter 에서 전혀 휘지 않았고, Web 은 요소마다 맵을 구워 정상이었다. 양 플랫폼이 같은 Core 값을 읽는데 픽셀이 갈리는, 이 킷이 가장 경계하는 형태의 결함이다.

## 패키지가 하는 일 (요약)

| 축 | 패키지 | 파일 |
|---|---|---|
| 굴절 | SDF 법선 + `refract()` (프리미엄) / 가장자리 10px 존에서 `normal × edgeInfluence² × thickness × 0.5` (스탠다드) | `liquid_glass_final_render.frag` · `lightweight_glass.frag` |
| 색수차 | 변위 × (1 ± ca × 0.5) 로 R/B 채널 분리, 가장자리에 집중 | 같음 |
| 스펙큘러 | 라운드렉트 SDF 법선 · 광원 각도(0.75π) · 키+킥 이중 하이라이트 · pow 8/16/32 를 곱셈 체인으로 | `lightweight_glass.frag` STAGE 4 |
| 림 | 배경 휘도로 페이드(라이트 8% · 다크 100%) · 프레넬 `(1−nz)·0.10` · 메니스커스 흡수(기본 0) | 같음 STAGE 6–7 |
| 틴트 | 배경 휘도 보존 색조 이동(`regular`) vs 직접 알파 합성(`clear`) | `render.glsl::applyGlassColor` |
| 중첩 | 자식은 블러를 다시 걸지 않고 `densityFactor` 로 암부·알파·스펙큘러를 해석적 보정 | STAGE 3.5 |
| 기하 전달 | 표면 사각형을 `uGeometryOffset/Size` 로 넘기고 `GeometryTransformTrackingLayer` 가 씬마다 `getTransformTo(null)` 을 비교해 갱신 | `liquid_glass_render_object.dart` · `transform_tracking_repaint_boundary_mixin.dart` |
| 품질 | minimal(셰이더 0) · standard · premium(Impeller) + 프레임 P75 벤치로 자동 승강 | `glass_quality_adapter.dart` |
| 그 외 | 셰이더 프리웜 · 4-tap 수동 bilinear(#188365 우회) · 프로그레시브 블러 · 콘텐츠 인지 밝기 · 스프링 모프(smooth-min SDF) · 프레스 ambient lift | 각 파일 |

기본값: `thickness 20 · blur 5 · ca 0.01 · lightIntensity 0.5 · refractiveIndex 1.2 · saturation 1.5 · specular medium(n=16) · edgeAbsorption 0`.

## CoUI 가 하는 일 (요약)

`CoreSurfaceRecipe.presets[liquidGlass]` — 기능층(떠 있는 패널 · 도킹 바)만 유리, 콘텐츠층은 불투명:

| 겹 | 값 | 어디서 그리나 |
|---|---|---|
| 채움 | opacity 0.5 | 양 플랫폼 |
| backdrop | blur 4 · saturate 1.6 · brightness light 0.92 / dark 0.6 | Flutter `ImageFilter.compose(ColorFilter.matrix, blur)` · Web `backdrop-filter` |
| 띠 + 베벨 | 1px 4-run(가로 `surfaceContainerHighest@0.40` · 세로 `outline@0.25`, fade 0.18) + inset 베벨(thickness 2 · angle −45 · intensity 0.8 · glow 12) | `SurfaceSheenPainter` + `InsetShadow` · `::after` |
| 굴절 | `figma(refraction 80, depth 27, dispersion 50)` → bezel 0.27 · strength 0.8 · n 1.5 · dispersion 0.5 | `surface_refraction.frag`(Impeller) · SVG `feDisplacementMap`(Chromium) |
| 중첩 | 채움·띠 유지, 블러 패스 제거 | 깊이 테이블 |
| 모프 | `CoreMorphSpring(fast)` — 팝오버만 | `LiquidMorphClip` |
| a11y | reduce-transparency(`withoutTransparency`) · forced-colors · high-contrast(굴절·drawsOwnEdge 해제) | seat |

도달: Flutter 14 · Web 15 표면, 자격은 목록이 아니라 규칙(Q1 채움 · Q2 뒤로 지나감).

## 측정 — 전부 실기기, 전부 재실행 가능

`app/coui_widgetbook/integration_test/` (macOS Impeller) · `tool/parity/test/web/` (Chromium). `flutter_tester` 는 `isShaderFilterSupported == false` 라 값이 없다.

| 프로브 | 무엇을 재나 | 결과 |
|---|---|---|
| P1 | `ImageFilter.shader` 가 프로그램에 주는 `uSize` 의 단위 | 캡처 배율 1.0 → `201×104`, 2.0 → `402×201` (논리 200×100). **물리 픽셀** |
| **좌표계** | 240×140 캡처 안 (20,20) 의 200×100 패널에서 `uSize`·`FlutterFragCoord()` | 합성/베어 · 클립 유무 · `Opacity` 유무 전부 `uSize≈482`, 프래그먼트 = **캡처 픽셀**. 셰이더는 **표면이 아니라 backdrop 전체**의 좌표계를 받는다 |
| **G1** | 출하 표면을 600×400 backdrop 의 중앙 / 왼쪽 가장자리에 두고 띠 안 유색(분산) 픽셀 수 | **수정 전 중앙 0 · 가장자리 2720** → 수정 후 **중앙 2720 · 가장자리 2720** |
| 반경 | `uRadius` 0 · 20 · 40 · 80 · 160 을 그려 비교 | 0 ≡ 20 ≡ 40 (md5 동일), 80 부터 코너가 바뀜 — 작은 반경은 **캡처의** 코너에만 걸려 표면 안에서 안 보였다. 위 좌표계 결함의 다른 얼굴 |
| P2 | plain `ImageFilter.shader` 의 백드롭 샘플러 | 반텍셀 시프트: plain `0000ff`(nearest), 수동 4-tap `800080`(50% 혼합). **nearest** |
| P3 | 출하 표면의 띠 안 채널별 `distinct / 중간값 비율` — plain vs 4-tap vs nearest 강제 (좌표계 수정 **전**, 같은 읽기 경로) | plain: R 9/0.045 · G 9/0.023 · **B 4/0.000** — nearest 강제와 **동일** — 4-tap: R 12/0.114 · G 11/0.091 · **B 15/0.273** |
| P3 | 같은 지표, 좌표계 수정 **후** 경계를 루트 원점에 앉힌 기준선 (plain) | 띠 R 8/0.045 · G 9/0.045 · B 6/0.318 · 내부 전 채널 2/0.000 — 이후 회귀 비교의 기준 |
| W2 | Chromium `feDisplacementMap` in `backdrop-filter`, 같은 반픽셀 시프트 | 경계 열 `0000ff`, 중간 열 0. **Chromium 도 nearest** |
| C1 | 프레임 도중 마운트된 표면, 마운트 프레임 vs 정착 프레임 (HEAD: 표면마다 비동기 로드) | **0.0669** — 픽셀의 6.7% 가 한 프레임 뒤에 바뀐다 (첫 프레임 플래시) |
| C1 | 같음, 홀더 + 앱 루트 워밍업 | **0.0000** |
| C2 | 같음, `warmUp()` 을 먼저 기다린 뒤 | **0.0000** |
| 유니폼 슬롯 | vec2 + float×5 + sampler 선언에서 `setFloat(3..5)` 가 어디 도착하나 | 선언 순서대로 (3→uB, 4→uC, 5→uD). 결함은 매핑이 아니라 좌표계 |

P3 지표: 왼쪽 띠의 직선 구간(인셋 2–24 논리 px, 행 30–70)에서 채널별 `distinct levels / 두 지배값 ±6 밖 비율`. 세로 줄무늬 4px 배경, 블러 0.1 로 backdrop 패스만 살림 — 블러 0 은 패스 자체를 안 만들어 굴절도 사라진다(첫 판이 그 상태를 쟀다). A/B 는 4개 파일을 HEAD 로 체크아웃했다 되돌리는 스크립트로 했고, 첫 판은 zsh 가 파일 목록을 쪼개지 않아 체크아웃이 안 된 채 "동일" 을 냈다 — 두 번째 판이 그걸 잡았다.

## 적용한 것

1. **굴절이 표면을 휘게 한다 (결함 수정, Flutter 렌더러만)** — 셰이더에 `uOrigin`·`uExtent`(표면 사각형, 텍스처 px)를 더하고 띠·코너·인셋을 전부 그 사각형에 대해 재고, `SurfaceBackdrop` 렌더 오브젝트가 **씬 구성 시점**에 `getTransformTo(null)` × DPR 로 그 값을 매 프레임 쓴다(스크롤·라우트 이동에 repaint 없이 따라감 — 패키지의 `GeometryTransformTrackingLayer` 와 같은 자리). 반경도 같은 px 로 스케일. Core 계약과 Web 은 손대지 않았다 — Web 은 요소 사각형으로 맵을 굽고 있었고, 그게 정본이다. 가정: 필터가 읽는 backdrop 은 루트 뷰 × DPR (측정한 모든 구성에서 참, `Opacity` 아래 포함). 가드: `surface_refraction_parity_test`(유니폼 순서·인덱스) · `surface_backdrop_geometry_test`(사각형 변환) · 실기기 `refraction_geometry_probe_test`(G1, 중앙 ≥ 가장자리/2 단언).
2. **프로그램 홀더 + 앱 루트 워밍업** — `SurfaceRefractionProgram`(프로세스당 한 번 로드, 실패 기억), `SurfaceBlur` 가 도착한 프로그램을 `initState` 에서 동기로 읽고, `CoUIApp` 이 스타일이 굴절을 진술하면 마운트 시 워밍업. 첫 화면에 유리가 있으면 `runApp` 전 `await SurfaceRefractionProgram.warmUp()` — 가이드에 적음. Web 의 document-level `SurfaceRefractionHost` 와 같은 자리.
3. **가이드** — "굴절 미출하" 문장(거짓이 된 지 3주)을 런타임별 표로, 정적 8개 목록을 자격 규칙으로. 셰이더 유니폼 순서를 고정하는 테스트 이름도 실재하는 파일로.

### 룩 — iOS 26 참조 화면을 기준으로 (사용자 판정)

사용자가 iOS 26 Apple Music 의 탭 바 화면을 기준으로 내밀었다: 밝은 윤곽 림, 렌즈 굴절, 바와 합쳐진 선택 알약, 그리고 **유리 카드**. 그 기준으로 두 항목을 적용했고, 하나는 남겼다.

4. **콘텐츠 역할도 유리 (Core 프리셋 값 하나, 양 플랫폼이 따라옴)** — 프리셋이 콘텐츠 역할을 불투명 표준 재질로 두던 결정(Apple 의 "유리는 내비게이션 층")을 뒤집었다. 카드 라이브 프리뷰가 유리 독 옆에서 불투명 판으로 보였고, 그건 재질이 아니라 바 하나의 장식으로 읽혔다. 이제 `surface`·`functionalSurface` 가 같은 `_kGlassSurface` 이고 중첩 테이블도 두 역할이 같은 답. 따라온 것: **튜닝 seat** 이 "재질을 든 역할 하나"만 따라가던 것을 유리인 모든 역할로(카드만 옛 프로스트에 남는 divergence 방지), **Web 굴절 host** 가 functional 만 붙이던 것을 backdrop 패스가 있는 모든 표면으로(Flutter 는 이미 패스마다 셰이더를 붙이고 있었으므로 이것도 파리티 복원), 중첩 표면(패스 없음)에는 어느 쪽도 안 붙임. 콘텐츠 역할을 flat 으로 고정하던 테스트 12+2 건은 새 결정으로 고쳤다. 대가는 기록: 콘텐츠 패널의 대비가 정적으로 결정되지 않게 됐고, `usesTransparency`·투명도 줄이기 폴백이 그 답이다.
5. **윤곽 림 (제안 3 을 다른 형태로)** — `CoreSurfaceEdgeBevel` 에 `rimWidth`·`rimIntensity` 와 두 함수: `rimAlphaAt(법선각)`(같은 광원의 스펙큘러 로브, 지수 2, 반대편은 `counterShare`) 와 `rimSweep(w,h,r)`(윤곽을 **호를 따라** 샘플해 스윕 정지점으로 — 넓은 바의 작은 반경 호는 균등 스윕이 건너뛴다). Flutter 는 `SweepGradient` 스트로크, Web 은 스타일시트가 `::before` 링(마스크)을 그리고 클라이언트 런타임이 요소마다 `conic-gradient` 를 커스텀 프로퍼티로 쓴다. 제안했던 SVG `feSpecularLighting` 대신 이 형태를 고른 이유: 양 플랫폼이 **같은 Core 함수의 같은 정지점**을 그려 파리티가 구성으로 성립한다(SVG 라이팅 필터는 GLSL 과 근사 파리티뿐). 실기기 캡처 `glass-look-step2.png`(알약 독) 에서 좌상단 호가 빛나고 오른쪽 끝이 휜다. 값(1px · 0.9)은 디자이너 판정 항목.

6. **렌즈 돔 (표 10)** — `CoreSurfaceRefraction.lens`(중심에서의 거리 중 안쪽으로 당기는 비율, 축마다 같은 값 → 이음매 없는 균일 확대 `1/(1−lens)`). 첫 설계는 가장 가까운 변의 법선과 도달 거리로 잡았다가 버렸다 — 직사각형의 대각선에서 가장 가까운 변이 바뀌며 도달 거리가 점프해 이음매가 생긴다. 지금 형태는 `lensDisplacement(축 거리) = −lens × 거리` 한 줄이라 GLSL 미러도 한 줄(`lensTravel`)이고 파리티 테스트가 본문을 핀한다. **합성 순서**를 양쪽이 같게: 띠 굴절 먼저, 그 옮겨진 지점에서 렌즈 — Web 은 렌즈 맵을 첫 `feDisplacementMap` 패스로 돌리고 띠 패스들이 그 결과를 읽으며, Flutter `readAt` 이 같은 순서로 샘플한다. 렌즈는 분산하지 않는다(양쪽 한 장). 출하값 0.08.
7. **분산 단위 불일치 (측정 밖에서 발견, 수정)** — Web 필터는 채널 패스를 `1 ± 0.5·dispersion` 으로 벌리는데 셰이더는 `1 ± dispersion` 을 쓰고 있었다: 같은 진술값에 Flutter 프리즘 띠가 두 배. `CoreSurfaceRefraction.dispersionUnit` 하나로 모으고 셰이더 상수를 파리티 테스트가 핀한다.
8. **림 두께·세기 재조정 + 튜닝 손잡이** — 1px·0.9 는 알약 호에서는 읽히고 1× 카드의 직선 변에서는 사라졌다. 2px·1.0 으로 올리고, `CoreSurfaceTuning.rimWidth`·`rimIntensity` 로 앱이 옮길 수 있게 했다(유리인 모든 역할에 같이 닿음 — 카드만 고르는 손잡이는 재질 seat 원칙상 두지 않는다).

9. **선택 알약 (표 11)** — `Dock` 에 활성 항목 알약을 넣었다: `CoreDockStyle.indicatorColor/indicatorRadius/indicatorPadding/indicatorSpring`(기본 on-surface 10% · 완전 둥근 · 12×6 오버행 · `fast` 스프링). 정착 상태는 활성 항목 자신의 슬롯(항목 콘텐츠 뒤에 오버행하는 위치 요소라 레이아웃 불변). 활성 항목이 바뀌면 떠나는 알약과 도착하는 알약을 **두 몸체로 모프 엔진에** 넘기고, 스프링이 정착할 때까지 바 전체를 덮는 채움을 `LiquidMorphClip` 이 같은 Core 윤곽으로 깎는다 — 팝오버가 트리거에서 나올 때와 같은 클립, 같은 `morphShapeAt`. 비행 기하는 양쪽 다 **측정**(Flutter: 렌더 박스, Web: `getBoundingClientRect` 3회)이고, 축소 모션에서는 비행 없이 점프. 알약은 표면이 아니다(표면 위에 얹히는 것은 유리로 만들지 않는다는 가이드 규칙) — 채움 하나이고 림은 바의 것.

남긴 것 — 없음. 룩 값(림 2px·1.0, 렌즈 0.08, 알약 10%)은 디자이너 판정.

## 가져오려다 둔 것 — 4-tap 수동 bilinear

패키지의 근거(#188365, 엔진이 백드롭을 nearest 로 바인딩)는 P2·P3 에서 참으로 확인됐고, 4-tap 은 Flutter 의 띠를 실제로 매끄럽게 했다(B 채널 0→0.273). 그런데 Web 을 같은 방식으로 재니 **Chromium 도 정수 픽셀로 스냅**하고(W2), `feDisplacementMap` 에는 보간을 요청할 프리미티브가 없다. 즉 이 항목은 Flutter 만 매끄럽게 만들어 **두 플랫폼이 일치하던 자리를 갈라놓는** 변경이라 넣지 않았다. 셰이더 주석에 두 측정을 다 적어 다음 사람이 한쪽만 다시 넣지 않게 했다. 둘이 같이 움직일 수 있는 날(Web 에 보간 프리미티브가 생기거나, 둘 다 다른 방식으로 그리게 되거나) 다시 연다. 3.48 의 `ImageFilter.shader(filterQuality:)` 도 같은 이유로 그날까지 쓰지 않는다.

## 제안 — Core 필드 · Flutter seat · Web seat (착수 안 함)

`core/theme-axis-composition.md` 의 "양 플랫폼 transport 를 동시에 설계한다" 를 그대로 적용했다. **Web 손잡이가 없는 것은 미착수**로 표시한다. 순서는 가치 대비 위험.

| # | 무엇 | Core | Flutter seat | Web seat | 판정 |
|---|---|---|---|---|---|
| 1 | 고대비에서 유리를 불투명 폴백으로 — 지금은 굴절·drawsOwnEdge 만 해제하고 채움 0.5·블러가 남아 반투명 위 텍스트가 정적 대비 감사(G4) 밖에 있다 | 필드 0 — `withoutTransparency()` 재사용 | `applySurfaceStyle(highContrast:)` 에 접기 | `prefers-contrast: more` 블록에 reduced-transparency 와 같은 CSS | **양쪽 손잡이 있음.** a11y 정책이라 사용자 결정 |
| 2 | 중첩 보정 — 블러를 뺀 안쪽 표면에 알파·휘도 보정(패키지 `densityFactor` 의 CoUI 판) | 필드 0 — `nestedSurfaces` 토큰 값만 | 깊이 테이블 | `.coui-surface .coui-surface` 규칙 | **양쪽 손잡이 있음.** 값은 렌더된 카탈로그를 보고 정한 것이라 계산으로 덮지 않는다 — 나란히 그려 판정 |
| 3 | 법선 기반 스펙큘러 — 광원을 향한 모서리에 하이라이트가 모임 | `CoreSurfaceEdgeBevel.rimWidth`·`rimIntensity` + `rimAlphaAt`·`rimSweep` | `SweepGradient` 스트로크 (Flutter Web 포함) | `::before` 링 + 런타임이 쓰는 `conic-gradient` 커스텀 프로퍼티 | **적용됨 (위 5).** 링 색은 하이라이트 슬롯 — 띠의 7쌍 창은 건드리지 않았고, 링 ↔ 포커스 링 대비는 미측정 |
| 4 | 휘도 보존 틴트 — 포화 컨트롤(primary 유리)의 탁해짐 제거 | `CoreSurfaceToken` 에 합성 모드 1 | `ColorFilter`/셰이더 | `mix-blend-mode: luminosity` 가 backdrop 과 합성되는지 **미측정** | **미착수** — Web 손잡이 확인이 먼저 |
| 5 | 하단 볼류메트릭 암부 4% | `CoreSurfaceToken` 필드 1 | 그라디언트 | `::after` `linear-gradient` | 양쪽 있음. 순수 룩 |
| 6 | 프로그레시브 블러(스크롤 엣지) | `FadeScroll` 의 형제 역량 | `ImageFilter.shader` (Flutter Web 불가) | `mask-image` 로 층 쌓기 | **비대칭 기록 필요** — Flutter Web 이 빠짐 |
| 7 | 콘텐츠 인지 밝기 — 바 뒤 콘텐츠로 아이콘 극성 반전 | 새 seat | 다운스케일 리드백 | `IntersectionObserver` + 샘플 캔버스 | 별도 Epic 규모 |
| 8 | 모프 소비처 확장 — 엔진은 있고 팝오버만 쓴다 | 없음 | `LiquidMorphClip` | `liquid_morph_dom` | 양쪽 있음. 메뉴·드로어로 |
| 9 | Figma `depth` 의 단위 — CoUI 는 짧은 변의 비율(27%), 패키지는 논리 px | `CoreSurfaceRefraction.figma` | — | — | 캔버스와 나란히 놓고 디자이너가 판정. 40px 칩에서 11px, 300px 카드에서 81px |
| 10 | 렌즈 돔 — 띠 바깥의 면도 살짝 확대(참조 화면의 "렌즈" 느낌) | `CoreSurfaceRefraction.lens` + `lensDisplacement`·`lensPeak` | `uLens` 유니폼 + `lensTravel`·`readAt` (파리티 핀) | 렌즈 맵 첫 패스 → 띠 패스가 그 결과를 읽음 | **적용됨 (위 6).** 값 0.08 은 디자이너 판정 |
| 11 | 선택 알약 — 활성 항목 뒤 알약이 항목 사이를 액체처럼 이동 (smooth-union) | `CoreDockStyle.indicator*` 4 필드 | `LiquidMorphClip` 소비처 (렌더 박스 측정) | 같은 클립 + `dock_flight_dom` 측정 | **적용됨 (위 9).** 탭·내비게이션 바로의 확장은 별도 |

## 이 세션이 남긴 도구

- `app/coui_widgetbook/integration_test/refraction_geometry_probe_test.dart` — G1 (중앙 vs 가장자리, 단언 있음)
- `app/coui_widgetbook/integration_test/refraction_coordinate_space_probe_test.dart` — 좌표계 · 유니폼 슬롯
- `app/coui_widgetbook/integration_test/refraction_sampling_probe_test.dart` — P1 · P2 · P3
- `app/coui_widgetbook/integration_test/refraction_first_frame_probe_test.dart` — C1 (홀더를 이름으로 부르지 않아 HEAD 에도 빌드된다)
- `app/coui_widgetbook/integration_test/refraction_first_frame_warmed_probe_test.dart` — C2
- `app/coui_widgetbook/shaders/probe_{size,coords,uniforms5,half_texel,half_texel_bilinear}.frag`
- `tool/parity/test/web/backdrop_sampling_probe_test.dart` — W2 (Chromium, `test:tool` 에서 돌고 Chrome 이 없으면 skip)
- `packages/coui_flutter/test/theme/surface_refraction_warm_up_test.dart` — 홀더 상태 기계 + 앱 루트 워밍업
- `packages/coui_flutter/test/theme/surface_backdrop_geometry_test.dart` — 표면 사각형 변환 · 유니폼 인덱스

전부 `-d <device>` 가 전제다(Web 프로브는 로컬 Chrome).
