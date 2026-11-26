# Spec — Liquid Glass 커스텀 스타일

> 선행: [`discovery-liquid-glass-custom-style.md`](./discovery-liquid-glass-custom-style.md)
> 범위 결정: **저작 표면 + CSS 표현력 + 굴절** / 진행: 린(명세 → 구현)

## 0. 이 문서가 확정하는 것

1. 앱이 Liquid Glass 파라미터를 **저작**할 수 있는 단일 진입점
2. 글래스가 **실제로 글래스처럼 보이게** 하는 렌더 레이어(채도 · 림)
3. **굴절**이 축에 들어갈 수 없는 이유와, 대신 들어갈 자리

---

## 1. 레퍼런스 기법 해부 (glasscn 실측)

`components/ui/glasscn/liquid-glass.tsx` 를 읽어 확인한 실제 구성. 세 겹이다.

| 겹 | 기법 | 크기 의존 | 브라우저 |
|---|---|---|---|
| **채도** | `backdrop-filter: … saturate(1.28)` | ✗ | 전부 |
| **림(=multi-layer bevel)** | `::after` 두 개 linear-gradient + `mask-composite: exclude` | ✗ | 전부 |
| **굴절** | canvas SDF → PNG → `feImage` + `feDisplacementMap` | **✓** | **Chromium 전용** |

### 1-1. 림이 핵심이고, 크기 독립이다

glasscn 이 "multi-layer bevel" 이라 부르는 것의 정체는 **iOS 스타일 림 한 겹**이다:

```css
padding: var(--liquid-glass-rim-width, 0.5px);
background:
  linear-gradient(to right,  transparent, LIGHT 18%, LIGHT calc(100% - 18%), transparent),
  linear-gradient(to bottom, transparent, DARK  18%, DARK  calc(100% - 18%), transparent);
mask: linear-gradient(#000 0 0) content-box exclude, linear-gradient(#000 0 0);
```

가로 그라디언트는 **위/아래 변**을 밝게, 세로 그라디언트는 **좌/우 변**을 어둡게 훑고, 양 끝(코너)에서 0으로 사라진다. `mask ... exclude` 가 안쪽을 도려내 `rim-width` 두께의 테두리 밴드만 남긴다.

**전부 퍼센트 기반이라 요소 크기와 무관하다.** → CoUI 의 축 transport(스타일시트 한 벌 + CSS 변수)에 **그대로** 들어간다. 컴포넌트는 아무것도 몰라도 된다.

### 1-2. 굴절만 크기 의존이다

```js
createDisplacementMap({ width, height, radius, bezel })  // 요소 크기별 캔버스 SDF → PNG
// ResizeObserver 로 재측정, (w:h:r:bezel) 키로 캐시
```

`feImage` 가 참조하는 변위 맵을 **요소 크기마다** 다시 굽는다. 라운드 사각형의 signed distance 를 계산해 법선 방향을 R/G 채널에 넣고, `convexSquircle(t) = (1-(1-t)⁴)^0.25` 로 가장자리에 굴절을 몰고 안쪽은 광학적으로 평평하게 만든다.

---

## 2. Tier 1 — 축에 들어가는 것 (채도 + 림)

파리티 리스크 0. 양 플랫폼 모두 기존 transport 로 표현된다.

### 2-1. 신규 필드

`CoreSurfaceToken.glass` 에 두 개를 더한다. 둘 다 **이번 변경에서 읽는 쪽이 같이 들어온다**(`theme-axis-composition.md` 필수).

```dart
const CoreSurfaceToken.glass({
  required double opacity,
  required double blur,
  double saturation = 1.0,      // 신규 — backdrop 채도. 1.0 = identity
  CoreSurfaceRim? rim,          // 신규 — 림. null = 림 없음
  @Deprecated('…') CoreGlassMaterial? material,   // 0.130 까지 병존
});
```

```dart
/// 표면 가장자리를 훑는 빛. 위/아래 변은 밝게, 좌/우 변은 어둡게.
@immutable
class CoreSurfaceRim {
  const CoreSurfaceRim({
    required this.width,        // double — CoreStrokeWidth 참조
    required this.lightColor,   // CoreColor
    required this.darkColor,    // CoreColor
    this.fade = 0.18,           // 0..0.5 — 코너에서 풀 강도까지의 변 길이 비율
  });
}
```

> **`CoreGlassMaterial` 은 이번에 지우지 않는다.** `since 0.128` 예고, 현재 `0.128.1` → `process/deprecation.md` 의 "0.N+2 부터 제거" 규칙상 **0.130 이전 제거 불가**. 대체재(위 두 필드)가 동작하는 릴리스가 이번이므로, 제거는 0.130 브레이킹 릴리스의 별도 작업이다.

### 2-2. 프리셋 기본값

```dart
CoreSurfaceStyleId.liquidGlass: CoreSurfaceRecipe(
  id: .liquidGlass,
  a11y: .liquidGlass,          // 변경 없음 — usesTransparency: true, boundary: .stroke
  surface: CoreSurfaceToken.glass(
    opacity: CoreOpacity.opacity70,
    blur: CoreSize.size16,
    saturation: 1.3,
    rim: CoreSurfaceRim(
      width: CoreStrokeWidth.stroke1,
      lightColor: /* surface highlight 토큰 */,
      darkColor:  /* shadow 토큰 */,
    ),
  ),
),
```

색은 **팔레트에서 파생**한다 — 리터럴 흰색/검정을 박으면 `layer-mapping.md` 의 Core 단일출처 위반이고 다크모드에서 갈린다. `LiquidGlassAdapter._glassTintFrom` 이 이미 하는 파생을 재사용한다.

### 2-3. 양 플랫폼 transport

**Web** — `theme_config.surfaceStyleTreatmentBlock` 확장. 값은 전부 `--coui-*` 변수 경유(런타임 스타일 전환이 stale 되지 않게).

```css
[data-coui-style="liquidGlass"] .{marker} {
  background-color: rgb(var(--fill) / 70%);
  backdrop-filter: blur(16px) saturate(var(--coui-glass-saturation));
}
[data-coui-style="liquidGlass"] .{marker}::after {
  /* §1-1 의 2-gradient + mask-exclude, 값은 --coui-glass-rim-* */
}
```

**Flutter** — `applySurfaceStyle` 이 `surfaceSaturation` / `surfaceRim` 을 `ThemeData` 에 접고, 표면 primitive(`OutlinedContainer` — 이미 `BackdropFilter` 를 소유)가 읽는다.

- 채도: `ImageFilter.compose(outer: ColorFilter.matrix(saturationMatrix), inner: ImageFilter.blur(...))`
  - ⚠️ **착수 첫 커밋에서 스모크 테스트로 확인할 것.** 합성 필터가 `BackdropFilter` 에서 기대대로 동작하는지 실측 전에는 가정하지 않는다.
- 림: 라운드 사각형 테두리 path 에 두 그라디언트를 그리는 `CustomPainter`. Web 의 `mask-exclude` 에 해당하는 것이 path 자체다.

### 2-4. a11y — 새로 지는 빚 없음

`liquidGlass` a11y 계약은 이미 `boundaryMechanism: .stroke` 와 `usesTransparency: true` 를 선언한다.

- **림은 경계가 아니다.** 장식이며, forced-colors 에서 사라져도 stroke 경계가 남는다. → 기존 `surfaceStyleForcedColorsBlock` 이 이미 처리. **단 "림이 유일 경계가 아님" 을 테스트로 고정한다.**
- **reduce-transparency** 시 표면이 불투명으로 떨어지면 채도·림도 같이 사라진다(둘 다 backdrop 재질의 일부). 별도 분기 불필요.

### 2-5. 가드 · 테스트

| 항목 | 무엇 |
|---|---|
| `check_axis_field_consumed.sh` | 새 캐리어(`CoreSurfaceRim`)를 목록에 등록. `saturation`/`rim` 이 읽히지 않으면 fail |
| 렌더 값 테스트 (Web) | emit 된 CSS 에 `saturate(` 와 `::after` 림 규칙이 **실제로** 들어가는지 — 문자열 존재가 아니라 whole-rule 비교 |
| 렌더 값 테스트 (Flutter) | `BackdropFilter` 의 filter 가 compose 인지, 림 painter 가 호출되는지 |
| 파리티 | 두 플랫폼이 **같은 Core 필드**를 읽는지 (값 일치가 아니라 출처 일치) |
| 회귀 주입 | 가드를 실제로 실패시켜 본다 — 주입 → fail → 되돌림 → pass |

---

## 3. Tier 2 — 굴절 (축에 들어갈 수 없다)

### 3-1. Web: Chromium 전용이고, 기능 감지가 불가능하다

검증된 사실 두 가지:

1. `backdrop-filter: url(#svg-filter)` 로 `feDisplacementMap` 을 태우는 것은 **Chromium 에서만 렌더된다.** Safari/WebKit 미지원(WebKit bug 245510), Firefox 미지원. 2026년 중반 기준 여전히 열린 상호운용성 이슈다.
2. **`CSS.supports()` 가 거짓말을 한다.** Safari·Firefox 는 값을 *파싱*해서 `true` 를 돌려주지만 렌더하지 않는다. glasscn 도 소스 주석에 이걸 적고 UA 스니핑으로 갔다.

> ```js
> // CSS.supports("backdrop-filter", "url(#f)") returns true in Safari and
> // Firefox (they parse the value) but neither browser actually renders SVG
> // filters through backdrop-filter. UA sniffing is the only reliable approach.
> ```

CoUI Web 은 SSR 이다. glasscn 도 **SSR 과 첫 클라이언트 렌더는 무조건 폴백 분기**를 타게 해서 하이드레이션 불일치를 피한다 — CoUI 도 같은 제약을 그대로 받는다.

### 3-2. 굴절은 크기 의존이라 축 transport 를 탈 수 없다

축의 Web transport 는 **스타일시트 한 벌 + CSS 변수**다(`theme-axis-composition.md`). 굴절은 요소 크기마다 변위 맵을 다시 구워야 하므로 CSS 변수로 표현되지 않는다 — **축 배제의 근거는 이 크기 의존 하나다.** 억지로 축에 넣으면 컴포넌트가 축을 알아야 하고, 그건 "컴포넌트 코드는 축을 읽지 않는다" 위반이다.

요소별 런타임이 붙을 대상은 **8개**다 — `kSurfaceMarkerComponentSlugs`(outlined-container · popup · card · dock · scaffold · navigation-bar · dialog · tooltip). 정적 목록이 아니라 매 테스트 실행마다 `packages/coui_web/lib/src/components/` 를 재-grep 해 검증된다.

8 과 140 의 차이를 적는 이유는 굴절을 옹호하기 위해서가 아니다. 약한 논거가 섞여 있으면 강한 논거까지 같이 의심받고, 크기 의존은 혼자서 충분하다.

### 3-3. 그래서 어디에 두는가 — opt-in 표면 primitive

굴절은 **테마 축 필드가 아니라, 표면 primitive 의 opt-in 역량**으로 간다. 축이 "이 앱은 글래스다" 를 말하고, 굴절은 그 위에 호출자가 명시적으로 켜는 것이다.

`CoreSurfaceRefraction(bezel:, fallbackBlurAdd:)` 를 `OutlinedContainer.refraction` 으로 건다. 이 타입은 `CoreSurfaceToken` · `CoreSurfaceRecipe` · `CoreSurfaceTuning` · `CoreThemeData` 어디에도 슬롯을 갖지 않는다 — 테마에서 도달할 수 있으면 그것은 축이고, 축이면 모든 표면이 자기 크기를 재는 코드를 갖게 된다.

`fallbackBlurAdd` 의 기본은 **무보정**이다. 굴절은 가장자리에서 겉보기 흐림을 더하므로 폴백은 보정 없이는 덜 유리처럼 보이지만, 그 보정을 숨은 상수로 박으면 "굴절을 요청하지 않은 표면" 과 "요청했지만 못 받은 표면" 이 서로 다른 이유 없이 달라진다.

`theme-axis-composition.md` 의 예외 조항을 **의도적으로 사용**한다:

> 플랫폼 capability 자체가 없는 경우는 이 규칙의 예외다 — 그때는 없는 쪽을 만들 수 없으므로 **비대칭을 의도적으로 기록**하고 각 플랫폼의 활성 조건을 따로 적는다.

| 플랫폼 | 활성 조건 | 미충족 시 |
|---|---|---|
| Flutter (네이티브) | `ui.ImageFilter.isShaderFilterSupported` — **매 호출 시점의 런타임 질의** | Tier 1 글래스 |
| Flutter Web | **불가.** 웹 SDK 가 `isShaderFilterSupported` 를 리터럴 `false` 로, `ImageFilter.shader` 를 무조건 `UnsupportedError` 로 정의한다 | Tier 1 글래스 |
| Web (Chromium) | 하이드레이션 이후 인라인 스크립트 | Tier 1 글래스 |
| Web (Safari/Firefox) | **불가** (WebKit 245510). 사용자 에이전트가 가르고(`surfaceRefractionBrowserSupported`, Flutter Web 과 Jaspr 컴포넌트가 같은 답을 읽는다), 불가한 브라우저의 표면에는 참조를 붙이지 않는다 | Tier 1 글래스 |

**활성 조건을 플랫폼 행으로 적지 않는 이유**: `isShaderFilterSupported` 는 Impeller 활성 여부이고, Impeller 는 임베더가 끄고 켜는 런타임 플래그다. 같은 플랫폼에서도 앱 설정에 따라 뒤집히므로 "iOS 는 된다" 로 적으면 Impeller 를 끈 빌드에서 조용히 throw 한다. `FragmentProgram` 사용 가능 여부는 조건이 **아니다** — Flutter Web 에도 `FragmentProgram` 은 있지만 그건 `Paint.shader` 용이라 자기가 그리는 픽셀만 내고 뒤를 샘플링하지 못한다. 배경에 닿는 API 는 `BackdropFilter` → `ImageFilter.shader` 하나뿐이다.

측정값:

| 대상 | 값 |
|---|---|
| Android `R54Y500PE6P` (android-arm64, Android 16) | `isShaderFilterSupported = true`. 최소 변위 셰이더가 `BackdropFilter` 를 통과해 배경을 옮긴다 — 거울 셰이더가 좌·우 표본을 정확히 맞바꾼다 |
| Chromium (headless) | 필터 체인을 고정한 채 변위 맵만 바꿨을 때 패널 픽셀의 **10.4%** 가 이동한다 |

위 두 줄은 **타당성**이다 — "이게 되는가". 판정은 별개이고, 출하되는 런타임을 그대로 컴파일해 태운 프로브가 낸다:

| 판정 대상 (shipped 런타임) | 값 |
|---|---|
| bezel 만 바꿨을 때 (0.45 ↔ 0.05) | 패널 픽셀의 **25.6%** 가 이동 |
| 같은 bezel 을 받은 두 표면 | **0%** — 위 숫자가 캡처 잡음이 아님을 세우는 바닥 |
| 좁은 bezel 표면의 **내부** vs 굴절 없는 표면 | **0%** — 중립값이 128 이라 평평한 안쪽이 안 움직인다 |
| 부착 → 해제 | 필터 요소 `0→1→0`, 픽셀 복귀 **0%** |

타당성 프로브가 변위 맵을 페이지 JS 로 직접 만든다는 점이 판정을 따로 두는 이유다. 그 사본은 자기가 대변하는 런타임이 어긋난 뒤에도 계속 통과하고, 그러면서 커버리지처럼 보인다.

**폴백은 실패가 아니라 규정된 바닥이다.** glasscn 도 폴백에서 `blur + 2` 로 살짝 보정한다 — 같은 보정을 명시 필드로 둔다.

### 3-4. Flutter 굴절은 맨바닥부터다

출하 코드의 셰이더 인프라는 **0** 이다 — `packages/*/lib` 어디에도 `FragmentProgram` · `ImageFilter.shader` 호출이 없다. `.frag` 과 pubspec `shaders:` 등록은 `app/coui_widgetbook` 의 측정 프로브 한 벌뿐이고, 그건 어떤 컴포넌트도 렌더하지 않는다.

필요한 것: `.frag` 소스 + pubspec 등록 + `ImageFilter.shader` 경로. Tier 1 과 난이도가 한 자릿수 다르고, Tier 1 의 선행 요건이 **아니다**.

`.frag` 은 **vec2 uniform 과 sampler uniform 을 선언**해야 한다. SDK 검사는 프로그램이 *선언한* uniform 을 보므로 `setFloat` 호출 횟수로는 만족되지 않고, 둘 중 하나라도 빠지면 `StateError` 다.

---

## 4. 저작 진입점 (갭 A)

### 4-0. 결정 — 재질은 앱에 열되, 범위는 a11y 에서 파생한다

`CoreSurfaceTuning`(PR #4216, 리뷰 중)의 현재 doc 은 글래스 재질을 앱 튜닝에서 **의도적으로 제외**한다:

> CoUI's own presets still author freely — mirrored shadows, highlight rims, **glass materials**, weight floors

**이 입장을 바꾼다.** 재질이 안 열리면 "Liquid Glass 커스텀 스타일" 요구가 절반만 충족된다 — 앱은 스타일을 켜고 끌 수만 있고 자기 유리를 가질 수 없다.

**단 무제한으로 열지 않는다.** 글래스 `opacity` 는 장식이 아니라 접근성 진술이다 — `a11y.usesTransparency` 가 참인 근거이고, 게이트 G4 가 "반투명은 정적 대비 감사가 불가능하므로 불투명 fallback 쪽을 등록한다" 로 처리하는 대상이다. 앱이 이걸 임의로 움직이면 그 등록이 거짓이 된다.

**해법은 이미 #4216 안에 있다.** `strokeFloor` 의 상한이 절대 상수가 아니라 `recipe.a11y.focusOutlineStyle.borderWidth` 에서 **파생**되고, 그 검사가 `applyTo` 의 debug assert 에 앉아 있다(프리셋이 확정되는 유일한 자리). 글래스 범위도 같은 자리에서 같은 방식으로 파생시킨다:

| 튜닝 축 | 범위의 출처 | 검사 위치 |
|---|---|---|
| `strokeFloor`(기존) | `a11y.focusOutlineStyle.borderWidth` | `applyTo` assert |
| 글래스 `opacity` | `a11y.usesTransparency` + G4 불투명 fallback | `applyTo` assert |
| `blur` · `saturation` | 상·하한 상수 (접근성 결합 없음) | `const` assert |

**따라서 새 메커니즘이 0이다.** `applyTo` 가 지금 `geometry` 를 접는 옆에 `surface` 를 접는 분기가 하나 늘고, 단일 fold 성질은 유지된다. W2 가 평행 메커니즘을 만들면 seat 이 둘이 되어 Flutter/Web 이 갈린다.

> 이 결정과 근거는 [#4216 코멘트](https://github.com/coco-de/coui/pull/4216#issuecomment-5249125324)로 그 PR 에도 남겼다 — `isIdentity` 가 다음 필드에서 조용한 no-op 을 만드는 함정(그 다음 필드가 글래스 축이다)과 함께.

### 4-1. 슬롯 — `CoreSurfaceTuning`

앱은 레시피를 통째로 대체하지 않고 **값을 진술**한다. 부재는 프리셋 값 유지다.

```dart
// Flutter — 활성 style 이 한 번에 하나라 단수
CoUIApp(
  surfaceStyle: .liquidGlass,
  surfaceTuning: CoreSurfaceTuning(
    surfaceOpacity: 0.5,
    surfaceBlur: 32,
    surfaceSaturation: 1.6,
  ),
)

// Web — 시트가 모든 style 의 블록을 한 벌에 굽는다
ThemeConfig(
  palette,
  surfaceTunings: {
    CoreSurfaceStyleId.liquidGlass: CoreSurfaceTuning(surfaceOpacity: 0.5),
  },
)
```

단수/복수 비대칭은 divergence 가 아니라 두 transport 의 성질이다 — Flutter 는 활성 테마 하나를 만들고 Web 은 스타일시트 한 벌을 굽는다.

레시피 전체를 받지 않는 이유는 저작 표면이 넓어서가 아니라 **무엇이 앱의 것이 아닌지**가 있기 때문이다. 밴드 색은 토큰 정체성이 살아야 고대비와 CSS 변수가 닿고, `SurfaceType` 은 어느 transport 가 도는지를 정하며, `a11y` 는 컴포넌트가 fallback 을 그리는 근거다. 앱이 이들을 바꾸면 프리셋이 등록한 진술이 거짓이 된다.

### 4-2. 해석은 한 곳

양 플랫폼 seat 이 같은 fold 를 부른다 — `CoreSurfaceTuning.applyTo(CoreSurfaceRecipe.of(id))`. fold 가 둘이면 필드 순서나 누락이 갈릴 수 있고, 그 차이는 나란히 놓기 전엔 안 보인다.

범위는 **clamp 가 아니라 assert** 로 지킨다. 조용히 잘라내면 앱이 적은 값과 화면 값이 달라지고 아무 신호도 남지 않는다.

### 4-3. Web 배선이 실제 작업이다

```dart
const ThemeConfig(this._colors);   // 지금은 색만 받는다
```

`ThemeConfig` 가 `surfaceTunings` 를 받아 시트 생성 경로까지 흘린다. Core 필드 추가보다 이쪽이 부피가 크다.

### 4-4. `==` / `hashCode` 의무

`CoreSurfaceTuning` 의 비교에 저작 필드가 **전부** 들어간다. 빠진 필드는 앱이 값을 바꿔도 rebuild 를 일으키지 못한다 — 값은 맞는데 화면이 그대로인, 디버깅 비용이 가장 큰 실패다.

같은 이유로 `applyTo` 는 자기가 진술하지 않은 필드를 **보존**해야 한다. 토큰을 다시 만드는 분기가 언급되지 않은 필드를 떨어뜨리면 그 손실이 `==` 를 타고 나중 비교까지 간다.

---

## 5. 이슈 분해 (린 경로)

| # | 작업 | 의존 | 비고 |
|---|---|---|---|
| 1 | `CoreSurfaceEdgeSheen` + `saturation` 필드 · 프리셋 기본값 · `==`/`hashCode`/`copyWith` | — | 읽는 쪽(2,3)과 **같은 PR**. ✅ 완료 |
| 2 | Web transport — `saturate()` + `::after` 밴드, 전부 CSS 변수 | 1, 2a | |
| **2a** | **`glass-highlight` / `glass-shadow` 를 CSS 변수 emit 대상에 추가** | 1 | **아래 §6-1** |
| 3 | Flutter transport — compose 필터 + 림 painter | 1 | ⚠️ compose 스모크 먼저 |
| 4 | 가드 등록 + 회귀 주입 검증 + 렌더 값 테스트 | 2,3 | |
| 5 | 저작 축 — `CoreSurfaceTuning` 에 글래스 필드 + `applyTo` 분기 | 1 | 새 메커니즘 아님 |
| 6 | `ThemeConfig.surfaceTunings` 배선 | 5 | |
| 7 | docs — `card.md` 등 글래스 문서 + 저작 예제 | 2,3,5,6 | |
| 8 | **Tier 2** 굴절 — Web(Chromium) + Flutter(FragmentShader) | 1~7 | 비대칭 기록 필수 |

**1~3 은 반드시 한 PR.** 룰이 필드와 소비처의 분리 착수를 금지한다.

---

## 6. 구현 중 발견

### 6-1. `glass-*` 토큰은 CSS 변수로 나가지 않는다

`CoreColorScheme` 에 `glassTint` / `glassHighlight` / `glassShadow` / `glassIllumination` 이 있고 `LiquidGlassAdapter` 가 팔레트에서 파생까지 하는데, **`primitive_css_generator.dart` 의 emit 맵에 이 넷이 없다.** 같은 자리에 `surface-highlight` 는 있다.

→ Web 에서 `rgb(var(--coui-glass-highlight))` 를 참조하면 **정의되지 않은 변수라 아무것도 그려지지 않는다.** 밴드가 조용히 안 보이는 형태로 실패한다.

이건 `CoreGlassMaterial` 과 **같은 계열의 죽은 필드**다 — 색은 파생되는데 한쪽 플랫폼 transport 가 없다(룰이 인용하는 "한쪽 플랫폼에만 소비처가 있어 반대쪽 필드는 죽어 있던 색 변환"이 정확히 이것). 작업 2a 로 분리했다.

### 6-2. 스모크 하네스 함정 — `toImage()` 는 `runAsync` 가 필요하다

첫 프로브가 **10분 타임아웃**으로 실패했는데 원인은 `ImageFilter.compose` 가 아니라 하네스였다. `toImage()` / `toByteData()` 는 `testWidgets` 의 fake-async 존에서 완료되지 않아 `tester.runAsync()` 로 감싸야 한다.

**이 실패 모드는 기능 실패처럼 보인다** — 픽셀 비교 테스트를 쓰는 다음 사람이 같은 자리에서 같은 10분을 잃는다. 정식 테스트로 승격할 때 이 주석을 함께 옮긴다.

## 7. 남는 리스크

| 리스크 | 성격 | 대응 |
|---|---|---|
| 굴절 Web 비대칭 | **확정된 제약** | 의도적 기록 + 폴백 테스트 |
| 폴백 보정값이 죽은 필드가 됨 | 기본이 0 이라 안 읽어도 대부분 시나리오가 통과한다 | 0 이 아닌 값을 준 폴백의 블러를 되읽는 테스트 |
| Safari · Firefox 폴백 | Safari 27.0(macOS)은 실제 창의 픽셀로 쟀다 — 처음부터 `blur(10px) url(#f)` 인 칸은 `none` 과 같고 `blur(10px)` 는 전부 바뀐다. 스타일시트의 체인으로 이미 그려진 층에 참조를 덧붙이면 그 층은 그대로라 첫 그림은 맞지만, 층이 다시 만들어지면(`display: none` 으로 숨겼다 보이기, 노드를 뺐다 다시 끼우기) 대조 칸과 같아진다(16384 중 달라진 픽셀 0). Firefox 는 쟀지 않았다(설치돼 있지 않다) | UA 로 가르는 답을 Core 가 하나만 두고, 그 표를 Chrome 프로브가 사용자 에이전트마다 읽어 런타임과 호스트가 참조를 붙이지 않는지 본다. Firefox 는 하네스가 생기기 전까지 열어 둔다. 스텝을 줄여 통과시키지 않는다 |
| 림이 다크모드에서 갈림 | 리터럴 색 쓰면 발생 | 팔레트 파생 강제 + 대비 감사 |
