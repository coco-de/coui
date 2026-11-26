# CoUI Web Theme System

`coui_web` 의 테마는 `coui_core` 의 플랫폼 무관 토큰(`CoreColorScheme` / `CoreTypography` / 원시토큰)을
Tailwind config + CSS 변수로 브리지한다 — Flutter 가 같은 토큰을 `Color`/`TextStyle` 로 굽는 것과
대칭이다. 값의 단일 출처는 항상 `coui_core` 이고, 이 문서는 그 값이 Web 에서 **어떤 형태로**
나타나는지(클래스 접두·CSS 변수 접두·단위)만 설명한다 — 정확한 값 목록은 여기 다시 적지 않는다.

## 구성 요소

| 클래스 | 역할 |
|---|---|
| `ThemeData` | 컴포넌트가 읽는 테마 값 묶음 — `colorScheme`(`CoreColorScheme`) · `typography`(`CoreTypography`) · `designSystem` · `textScaling` · `surfaceBlur` · `surfaceOpacity` |
| `ThemeConfig` | 색 소스(`CoreSchemeSource`) → Tailwind config(JS) + CSS 변수(`:root`) 생성기. CoUI 기본은 `ThemeConfig.defaults()`(고정 팔레트 `CouiColorPresets.source`), 브랜드는 `ThemeConfig(PrimitiveColors, mapping:)`. 앱/사이트당 1 인스턴스, `<head>` 에 1 회 주입 |
| `Theme` (`InheritedComponent`) | `ThemeData` 를 컴포넌트 트리에 전파 — Flutter `Theme.of(context)` 와 대칭 |
| `ColorScheme` | `CoreColorScheme` 의 typedef (레거시 이름 유지, 실체는 `coui_core` 타입) |

## 사용법

### 1. 앱 루트 — `CoUIWeb`

```dart
import 'package:coui_web/coui_web.dart';

CoUIWeb(
  theme: ThemeData.light,      // CoreThemePresets.light 에서 파생
  darkTheme: ThemeData.dark,   // CoreThemePresets.dark 에서 파생
  themeMode: CoreThemeMode.system,
  child: MyApp(),
)
```

### 2. `<head>` 에 Tailwind config + CSS 변수 주입 (사이트당 1 회)

`ThemeConfig` 는 개별 컴포넌트가 아니라 앱/사이트 부트스트랩이 소유한다.

```dart
import 'package:coui_web/coui_web.dart' show ThemeConfig;

final themeConfig = ThemeConfig.defaults(); // 또는 브랜드 팔레트: ThemeConfig(brandPalette)

// <head> 안:
// <script>{themeConfig.tailwindConfig}</script>
// <style>{themeConfig.cssVariables}</style>
```

### 3. 컴포넌트 안에서 읽기

```dart
Component build(BuildContext context) {
  final cs = context.colorScheme; // CoreColorScheme
  final ts = context.typography;  // CoreTypography

  return div([
    // Tailwind class 보간 (CoreColor.toString → 토큰 이름)
    Text('Hi').bodyMedium.onSurface,
  ], classes: 'bg-${cs.primary}');
}
```

색상은 두 경로로 쓸 수 있다 — Tailwind class 보간(`'bg-${cs.primary}'`) 또는 inline CSS
(`cs.onSurface?.toValue()` → `'var(--coui-on-surface)'`). 어느 경로든 값은 `--coui-*` CSS 변수를
가리켜 런타임 다크모드/대비 전환에 반응한다.

### 4. `coui_core` 프리셋에서 파생

```dart
final theme = ThemeData.fromCore(CoreThemePresets.light);
```

## CSS 변수 카테고리

`ThemeConfig.cssVariables` 가 `:root` 에 emit 하는 카테고리. 값 목록은 각 토큰 namespace
(`coui_core`)가 단일 출처이므로 여기 나열하지 않는다 — 정확한 값 표는 `.claude/rules/core/design-tokens.md`
참조, 생성 코드 자체는 `theme_config.dart` 참조.

| 카테고리 | 접두 | 단위 | 소스 |
|---|---|---|---|
| 색상 (Primitive + Semantic) | 프리미티브 `--coui-{family}-{step}` · 시맨틱 `--coui-{slot}` | RGB triplet (`rgb(var(--coui-x))`) | `CoreSchemeSource` — CoUI 는 `CouiPalette` + `CouiSemanticMapping`, 브랜드는 `PrimitiveColors` + 자기 매핑 |
| spacing | `--coui-space-*` | rem | `CoreSpace` |
| dimensional (width/height) | `--coui-size-*` | rem | `CoreSize` |
| font-size | `--coui-font-size-*` | rem | `CoreFontSize` |
| font-family | `--coui-font-family-*` | — | `CoreFontFamily` |
| line-height / letter-spacing | `--coui-line-height-*` / `--coui-letter-spacing-*` | unitless / em | `CoreLineHeight` / `CoreLetterSpacing` |
| typography (role 합성) | `--coui-text-{role}-{size,line-height,weight,tracking}` · 서체를 적은 역할만 `--coui-text-{role}-family` (기본 스케일은 `code-*` 만 — mono) | size rem · line-height 는 배수, 고정 줄 상자를 적은 역할(`code-*`)은 rem 길이 · tracking em | `CoreTypography` (`CssVariableGenerator.typographyVars`) |
| typography 단계 (display · headline) | `:root` 의 같은 `--coui-text-{role}-*` 중 단계가 바꾸는 것만 다시 진술 — 1024 · 768 미만 미디어 규칙과 인쇄 규칙(저작한 크기) — 셋 다 단계를 이름하지 않는 루트에, `data-coui-typography-tier` 고정 규칙(루트 · 부분 트리) | role 변수와 같음 | `CoreTypography.atTier` · `CoreHeadingSizes.couiByTier` (`ThemeConfig.typographyTierBlocks`) |
| border-width | `--coui-stroke-width-*` | px (고정, 텍스트 스케일 영향 X) | `CoreStrokeWidth` |
| focus ring | `--coui-ring-width` / `--coui-ring-offset` | px (고정, 단일 값 — 스케일 아님) | `CoreFocusRing` |
| radius | `--coui-radius-*` | px | `CoreRadius` |
| shadow | `--shadow-*` (`--coui-` 접두 없음) | box-shadow (2-layer) | `CoreShadow` |
| duration | `--coui-duration-*` | ms | `CoreDuration` |
| easing | `--easing-*` (`--coui-` 접두 없음) | cubic-bezier | `CoreEasing` |
| z-index | `--z-*` (`--coui-` 접두 없음 — `CoreZIndex.scale` 문서 계약) | int (1000 부터 시작) | `CoreZIndex` |

Tailwind `screens`(`sm`/`md`/`lg`/`xl`/`2xl`) 는 CSS 변수가 아니라 `tailwindConfig` 의 `screens` 키로
`CoreBreakpoint` 를 직접 참조한다 — media query 는 컴파일 타임에 고정돼야 하므로 CSS 변수로 표현할
수 없다. Flutter 의 뷰포트 판정과 같은 `CoreBreakpoint` 를 단일 출처로 공유한다.

## 다크모드 / 접근성

- **다크모드**: `[data-theme="dark"]` 선택자가 Semantic 색상 슬롯을 재정의한다
  (`PrimitiveCssGenerator.toCssBlockFrom`). `CoUIWeb.themeMode` 가 런타임 전환을 담당.
- **고대비** (`prefers-contrast: more`): 색 소스의 raise 가 쓰는 슬롯만 더 강한 값으로 재정의한다
  (`PrimitiveCssGenerator.semanticVarsRaised`) — 나머지는 `:root` 에서 cascade 로 상속하고, 컴포넌트는
  이 축의 존재를 모른다. 라이트 블록은 `data-theme="dark"` 페이지에 걸리지 않는다.
- **동작 줄이기** (`prefers-reduced-motion: reduce`): 전환 tier duration 만 `0ms` 로 재정의하고,
  표시 tier(스피너 등 "얼마나 오래 머무르나")는 보존한다. Skeleton 맥동은 표시 tier 이지만
  `--coui-skeleton-pulse` 를 쉼 끝을 붙드는 키프레임으로 바꿔 멈춘다
  (`CoreReducedMotion.runsPlaceholderPulse`).

## 같이 보기

- `.claude/rules/core/design-tokens.md` — 원시토큰 값 표, CSS 변수 카테고리·단위의 정본.
- `.claude/rules/web/web-specifics.md` — Web emit 규칙(default→class, override→inline), 색상 CSS 변수가
  bare RGB triplet 인 이유.
- `.claude/rules/core/theme-axis-composition.md` — 다크모드/고대비/동작 줄이기 축이 같은 토큰 해석
  지점에 앉는 이유.
- `packages/coui_web/lib/src/base/theme_config.dart` — 위 표를 실제로 생성하는 코드 (단일 출처).
