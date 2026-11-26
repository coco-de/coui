# Tech spec — Neo-brutalism 커스텀 스타일

상위: `seed-spec-neobrutalism-custom-style.md` · 결정: `decision-log-neobrutalism-custom-style.md`
게이트: `docs/preset-acceptance-gate.md` 전체 상속

---

## 1. 변경의 형태 — 자물쇠 하나

```
지금:  resolveThemeGeometry(surfaceStyle: id) → CoreSurfaceRecipe.presets[id].geometry
바뀜:  resolveThemeGeometry(surfaceRecipe: recipe) → recipe.geometry
```

seat 이 **상수 테이블을 조회하는 대신 인자를 받는다**. 그 아래는 이미 파생 구조라 따라온다:

- Flutter 눌림 피드백 — `ResolvedButton.pressedTranslateOffset` 이 `theme.geometry.shadowOffsetAdd` 를 읽는다.
- Web CSS — `surfaceStyleGeometryBlock` 이 `geometry.radius(step)` · `geometry.stroke(step)` · `geometry.shadow(step.layers)` 의 **결과값**과 `--coui-control-shadow-offset-*` 를 굽는다.

새 transport 는 0 이다.

## 2. 새 타입 — `CoreSurfaceTuning`

`packages/coui_core/lib/src/surface/surface_tuning.dart`

```dart
@immutable
class CoreSurfaceTuning {
  const CoreSurfaceTuning({
    this.radiusFloor,
    this.radiusCap,
    this.shadowOffsetX,
    this.shadowOffsetY,
    this.strokeFloor,
    this.stageTintChroma = 0,
  });

  final double? radiusFloor;
  final double? radiusCap;
  final double? shadowOffsetX;
  final double? shadowOffsetY;
  final double? strokeFloor;
  final double stageTintChroma;

  static const CoreSurfaceTuning none = CoreSurfaceTuning();

  bool get isIdentity => /* 모든 필드가 기본값 */;

  CoreSurfaceRecipe applyTo(CoreSurfaceRecipe recipe);

  // copyWith · == · hashCode — 축 캐리어이므로 모든 필드가 비교 대상
}
```

**노출되지 않는 것** (§seed 3.1): `a11y` · `id` · `surface` 재질 · `typography.weightFloor` · `shadowMirror` · `highlightRim` · `shadowBlurScale` · `shadowOpacityOverride` · `controlShadow` · `outlineEmphasis` · `accentChromaScale` · `accentLightnessShift` · `surfaceMatchesStage`.

**`applyTo` 가 단일 출처다.** 튜닝을 레시피로 접는 자리가 둘이 되면 Flutter 와 Web 이 다른 답을 낸다. Flutter 의 `applySurfaceStyle` 과 Web 의 `ThemeConfig` 가 같은 함수를 부른다.

## 3. 범위 강제 — 두 층으로 갈린다 (정직하게)

D3 은 "컴파일 에러" 를 요구했지만, **상한 하나는 컴파일 타임에 표현할 수 없다**. `strokeFloor` 상한은 그 프리셋의 포커스 링 폭에서 파생되는데(D4), 링 폭은 프리셋마다 다르고(neo-brutalism 6 · 나머지 3) 튜닝 값은 어느 프리셋에 붙을지 모르는 채로 생성된다. 절대 상수로 못 박으면 가장 좁은 프리셋에 맞춰 3 이 되어 neo-brutalism 자신의 기본값 4 조차 못 적는다.

| 층 | 검사 | 언제 터지나 |
|---|---|---|
| `const` 생성자 assert | `radiusFloor ≤ radiusCap` · 둘 다 `≥ 0` · `shadowOffsetX/Y ≥ 0` · `strokeFloor ≥ CoreStrokeWidth.stroke2` | **컴파일 타임** (정상 호출부는 `const`) — 실측으로 증명됨 |
| `applyTo` assert | `strokeFloor < recipe.a11y.focusOutlineStyle.borderWidth` | **디버그 첫 fold** (앱 기동 시) |
| 테스트 | 출하되는 프리셋 × 경계 튜닝 조합이 위 관계를 지키는지 | CI |

**왜 clamp 가 아닌가**: 조용히 잘라내면 앱이 적은 값과 화면에 나오는 값이 달라지고 그 차이는 아무 신호도 남기지 않는다.

## 4. 배경 틴트 (W2)

`CoreSurfaceColorConstraint` 에 `stageTintChroma` 추가. `apply` 안에서:

```
surface' = oklch(L(surface), stageTintChroma, hue(primary), alpha(surface))
```

- **`surface` 하나만.** `surfaceContainerLow/Container/High` 는 손대지 않는다.
- **L 고정.** 감사할 자유 파라미터를 hue 하나로 유지한다.
- `isIdentity` 에 `stageTintChroma == 0` 추가 — 빠뜨리면 이 축을 켠 프리셋이 "아무것도 안 한다" 로 판정돼 Web 이 CSS 블록을 아예 안 굽는다(`surfaceStyleVariableBlocks` 가 `isIdentity` 로 스킵한다).
- `==` / `hashCode` / `copyWith` 에 추가 — 빠뜨리면 값이 같다고 판정돼 **rebuild 가 일어나지 않는다**.

고대비에서는 `applySurfaceStyle` 이 `colorConstraint` 를 통째로 건너뛰는 기존 동작이 그대로 적용된다(추가 코드 없음). 기하 튜닝은 그 분기 밖이라 유지된다.

## 5. hue sweep 감사 (W2)

`packages/coui_core/tool/check_contrast.dart`

```
for hue in 0..360 (step S):
  scheme = resolveThemeScheme(palette, brightness, surfaceRecipe: tuned(C_max, hue))
  assert every pair involving `surface` clears its threshold
```

- **`surface` 가 관여하는 쌍만.** 전체 매트릭스를 hue 마다 반복하지 않는다.
- 두 밝기 모두.
- 비용이 문제면 스텝 `S` 를 늘리지 말고 **최악 hue 근방만 촘촘히** 훑는다 — 스텝을 늘려 통과시키는 것은 감사를 무력화하는 방향이다.
- `C_max` 는 이 sweep 이 전 hue 에서 통과하는 최대 chroma. **결과가 0 이면 W2 미착수** 이고 그 사실이 산출물이다.

`_checkPresetCoverage` 는 그대로 두되, 자유 파라미터를 가진 프리셋이 스킴 등록 대신 sweep 으로 분류되는 세 번째 경로를 갖는다(O4 — 게이트 문안 갱신).

## 6. 파일별 변경

### W1 — 기하 튜닝

| 파일 | 변경 |
|---|---|
| `coui_core/.../surface/surface_tuning.dart` | **신규** — 타입 + `applyTo` + 범위 assert |
| `coui_core/.../surface/surface_recipe.dart` | 없음 (`presets` 는 CoUI 저작의 출발점으로 유지) |
| `coui_core/.../color/scheme_resolution.dart` | `resolveThemeGeometry` / `resolveThemeScheme` 가 `CoreSurfaceRecipe` 를 받는다. **id 를 받는 기존 시그니처는 기본값으로 유지** — 호출부 파괴 0 |
| `coui_core/lib/coui_core.dart` | export 추가 |
| `coui_flutter/.../theme/apply_surface_style.dart` | `surfaceTuning` 파라미터 추가, fold 전에 `applyTo` |
| `coui_flutter/.../coui_app.dart` | `CoUIApp` · `CoUIApp.router` · `CoUILayer` 셋 다 `surfaceTuning` 통과 |
| `coui_web/.../base/theme_config.dart` | `ThemeConfig(palette, {surfaceTunings})`, `surfaceStyleVariableBlocks` 가 튜닝된 레시피를 읽는다 |
| `docs_core/content/guides/theming.md` | **서페이스 스타일 축 자체가 문서에 없다** — 축 소개 + 튜닝 |

### W2 — 배경 틴트 (C_max > 0 일 때만)

| 파일 | 변경 |
|---|---|
| `coui_core/.../surface/surface_color_constraint.dart` | `stageTintChroma` + `apply` + `isIdentity` + `==`/`hashCode`/`copyWith` |
| `coui_core/.../surface/surface_tuning.dart` | `stageTintChroma` 를 constraint 로 접기 |
| `coui_core/tool/check_contrast.dart` | hue sweep |
| `docs/preset-acceptance-gate.md` | G4 에 세 번째 분류 경로 (O4) |

## 7. 호환 — 튜닝 없는 앱은 바이트 단위로 같다

- 모든 새 파라미터는 기본값이 identity.
- `CoreSurfaceTuning.none.applyTo(recipe)` 는 **`recipe` 자기 자신을 반환**한다(새 인스턴스가 아니라). 축 캐리어 동등성 비교가 identity 로 짧게 끝나고 불필요한 rebuild 가 안 생긴다.
- 패리티 베이스라인이 움직이면 안 된다 — 움직였다면 identity 경로가 새는 것이고, 그 자체가 회귀다.

## 8. 인수 조건 ↔ 테스트 매핑

| Seed spec 시나리오 | 어디서 검증되나 | 단위 |
|---|---|---|
| 각진 모서리 (violet) | `coui_flutter/test/theme/surface_tuning_e2e_test.dart` (칠해진 `BoxDecoration.borderRadius` 되읽기) + `coui_web/test/base/surface_tuning_css_test.dart` | W1 |
| 그림자 오프셋이 눌림까지 | `surface_tuning_e2e_test.dart` — 누른 상태의 `AnimatedContainer.transform` 되읽기(`* scaling` 반영) + Web `--coui-control-shadow-offset-*` | W1 |
| 범위 초과 = 컴파일 에러 | negative-test 로 확인됨 — `const` 호출부 3종이 `const_eval_throws_exception`, 유효 조합은 통과 | W1 |
| 앱이 계약에 닿지 못함 | `coui_core/test/surface_tuning_test.dart` — 접힌 레시피의 `a11y`/`id`/`surface` 불변 | W1 |
| 튜닝 없음 = 바이트 동일 | `applyTo` identity 반환 + Web 규칙 문자열 동일 + 패리티 베이스라인 무변동 | W1 |
| 배경만 틴트 (본문은 흰색) | `surface_colour_transport_test.dart` 확장 — `surface` 는 이동, `surfaceContainer*` 는 불변 | W2 |
| L 불변 | OKLch 되읽기 테스트 | W2 |
| 어떤 hue 에서도 대비가 선다 | `check_contrast.dart` sweep (CI) | W2 |
| 고대비 > 배경 틴트 | `apply_surface_style_test.dart` 확장 | W2 |

**가드는 실패시켜 본 뒤에만 가드다** (게이트 G7): 범위 assert 와 hue sweep 각각에 회귀를 주입 → 실패 확인 → 되돌림 → 통과 확인.

## 9. 위험

| # | 위험 | 완화 |
|---|---|---|
| R1 | `C_max` = 0 → W2 무산 | D8 분할로 W1 이 독립적으로 머지된다. 무산도 산출물 |
| R2 | `isIdentity` 에 새 필드를 빠뜨려 Web 이 CSS 를 안 굽는다 | §4 에 명시 + 되읽기 테스트 |
| R3 | `==`/`hashCode` 누락 → 계산은 맞는데 화면이 안 바뀐다 | 게이트 G6. 스크린샷에 원인이 안 드러나는 실패라 테스트로만 잡힌다 |
| R4 | 앱이 `strokeFloor` 를 링 폭 이상으로 → 릴리스에서 assert 없음 | §3 3층 구조. 출하 프리셋 조합은 CI 테스트가 고정 |
| R5 | 패리티 베이스라인 churn | §7. 움직이면 identity 경로 누수 |

## 10. 순서

1. **W1** — 타입 · seat · 양 플랫폼 통과 · 문서 · 테스트. 머지 가능한 단위.
2. **C_max 측정** — sweep 을 먼저 돌린다.
3. **W2** — 측정값이 0 보다 클 때만.

O3(docs 데모 방식)은 W1 문서 작업에서 결정된다 — 빌드타임 전용이므로 라이브 커스터마이저는 불가하고, 튜닝별로 구운 프리뷰나 정적 증거 중 하나를 고른다.
