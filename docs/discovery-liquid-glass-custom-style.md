# Discovery — Liquid Glass 테마 커스텀 스타일

> 레퍼런스: [glasscn-components](https://github.com/kostyniuk/glasscn-components) / [데모](https://glasscn-components.vercel.app/#components)

## 1. 지금 CoUI 에 있는 것 (실측)

Liquid Glass 는 **이미 테마 축으로 존재하고, 양 플랫폼에 도달한다.**

| 자리 | 파일 | 상태 |
|---|---|---|
| 축 식별자 | `surface/surface_style_id.dart` — `CoreSurfaceStyleId.liquidGlass` | ✅ |
| 레시피 | `surface/surface_recipe.dart` — `CoreSurfaceRecipe.presets` | ✅ (const) |
| Flutter seat | `theme/apply_surface_style.dart` → `surfaceBlur` / `surfaceOpacity` | ✅ |
| Web seat | `base/theme_config.dart` → `surfaceStyleTreatmentBlock` → `[data-coui-style="liquidGlass"]` CSS | ✅ |
| 어댑터 | `adapter/liquid_glass_adapter.dart` — glassTint/Highlight/Shadow/Illumination 파생 | ⚠️ 색만 |

축 구조 자체는 `core/theme-axis-composition.md` 를 정확히 따르고 있다 — seat 하나, 컴포넌트는 축을 모름, 양 플랫폼 transport 동시 존재.

## 2. 비어 있는 두 자리

### 갭 A — 저작(authoring) 진입점이 없다

`CoreSurfaceRecipe.presets` 는 `static const Map` 이고 `CoreSurfaceRecipe.of(id)` 는 static 이다. 양 플랫폼 seat 이 **둘 다 이 static 을 직접 호출**한다:

```dart
// apply_surface_style.dart:42
final recipe = CoreSurfaceRecipe.of(surfaceStyle);
// theme_config.dart:1145
surfaceStyleTreatmentBlock(id, CoreSurfaceRecipe.of(id).surface)
```

`CoreThemeData` 에는 surface recipe 슬롯이 **아예 없다**(`designSystem` enum 뿐). 따라서 앱이 "우리 글래스는 blur 32 / opacity 0.55" 라고 말할 방법이 현재 0이다. 커스텀은 CoUI 를 포크하는 것 외엔 불가능하다.

### 갭 B — 글래스의 표현력이 opacity + blur 두 값뿐이다

`CoreGlassMaterial`(highlight / shadow / illumination / refraction)은 **`@Deprecated` 로 "아무도 안 읽음" 이 명시**되어 있다:

> Nothing renders any of them. … 그 네 값은 recipe 가 진술하고, equality/serialisation 을 통과하고, **어느 플랫폼의 렌더러도 읽지 않는다.**

즉 이건 이 레포 룰(`theme-axis-composition.md` 의 "선언만 된 필드는 축이 아니다")이 **자기 사례로 인용하고 있는 바로 그 상태**이며, `check_axis_field_consumed.sh` 가드가 재발을 막고 있다.

## 3. glasscn 이 하는 것 ↔ CoUI 갭 매핑

glasscn 의 두 변종:
- **`liquid`** — 순수 CSS. "heavy saturation + sheen + multi-layer bevel"
- **`liquid-refract`** — SVG displacement filter 로 실제 렌즈 굴절

| glasscn 요소 | CoUI 현재 | 판정 |
|---|---|---|
| backdrop blur | `blurRadius` ✅ | 있음 |
| 반투명 fill | `opacity` ✅ | 있음 |
| **saturation 부스트** | 필드 자체 없음 | **신규 필드 필요** |
| **sheen(specular)** | `highlightOpacity` — 선언만, 미렌더 | **렌더러 필요** |
| **multi-layer bevel** | `shadowOpacity` / `illuminationOpacity` — 선언만, 미렌더 | **렌더러 필요** |
| **refraction** | `refractionIndex` — 선언만 | **양 플랫폼 셰이더/필터 필요** |
| 컴포넌트별 `glassVariant` prop | 없음(축은 전역) | 룰상 도입 금지 — 축은 seat 하나 |

> glasscn 은 컴포넌트마다 `glassVariant` prop 을 노출한다. CoUI 에서 그 형태는 채택하지 않는다 — `theme-axis-composition.md` 가 "컴포넌트 코드는 축을 읽지 않는다" 를 명시하고, 컴포넌트별 prop 은 축을 140개 자리로 흩는다. CoUI 등가물은 **테마 레벨 저작 + 컴포넌트가 자기를 surface 로 표시**하는 기존 구조다.

## 4. 룰이 이 작업에 거는 제약 (사전 확인 완료)

`core/theme-axis-composition.md` 체크리스트에서 이 작업에 직접 걸리는 항목:

1. **새 필드는 읽는 쪽과 같이 들어온다.** 저작만 먼저 열고 렌더러를 나중에 붙이는 순서는 금지. 갭 A 와 갭 B 는 **같은 변경에** 묶여야 한다.
2. **`==` / `hashCode` 포함 의무.** 축이 쓰는 필드가 비교에서 빠지면 rebuild 자체가 안 일어난다.
3. **양 플랫폼 손잡이 동시.** 한쪽만 되는 축은 착수 보류.
4. **Web 재지정은 CSS 변수로만.** Dart 에서 값을 구워두면 런타임 스타일 전환에서 stale.
5. **표면 처리는 표면이 자기를 표면이라고 말할 때만 닿는다** + **채움을 publish 해야 한다.** (이미 `kWebSurfaceMarker` / `surface_fill_publication_test.dart` 로 구현·검증되어 있음 — 새 레이어도 같은 계약을 타야 함)
6. **가드를 실제로 실패시켜 봤는가.** 회귀 주입 → 실패 → 되돌림.

### 굴절(refraction)의 특수성

`refractionIndex` 는 나머지 셋과 성격이 다르다. 소스 주석이 이미 판정해 둔 상태:

> `refractionIndex` 는 다르다: 어느 플랫폼도 커스텀 셰이더 없이 표면 뒤의 빛을 굽힐 수 없다 — 배선이 안 된 값이 아니라 **애초에 도달 불가능했던** 값이다.

Web 은 SVG `feDisplacementMap` 으로 가능하고 Flutter 는 `FragmentShader` 가 필요하다. 규칙 4번(양 플랫폼 동시 손잡이)을 만족시키려면 **두 구현을 같이** 만들어야 하며, 이는 나머지 셋(순수 CSS/그라디언트로 표현 가능)과 난이도가 한 자릿수 다르다.

## 5. 결론

- "Liquid Glass 를 지원하자" 가 아니라 **"이미 있는 축을 저작 가능하게 + 실제로 글래스처럼 보이게"** 가 정확한 문제 정의다.
- 갭 A(저작)와 갭 B(렌더러)는 룰상 **분리 착수가 금지**되어 있고, 굴절은 **분리가 가능**하다(별도 축 필드 + 별도 transport).
- 따라서 범위 결정은 실질적으로 **"굴절을 포함하는가"** 한 축으로 수렴한다.
