# Seed spec — Neo-brutalism 커스텀 스타일

> **한 문장**: 앱이 서페이스 프리셋의 **기하와 배경 틴트를 자기 값으로** 정할 수 있게 하되, 그 값이 프리셋의 접근성 계약을 깨지 못하도록 **범위로 묶고 CI 가 자유 파라미터의 최악값을 훑는다**.

레퍼런스: <https://www.neobrutalism.dev/> · 근거 화면: blue / green / orange / violet 4종.

---

## 1. 왜 이게 필요한가

`CoreSurfaceRecipe.presets` 는 `static const Map` 이고 `CoreSurfaceRecipe.of(id)` 가 거기서만 읽는다. 그래서 neo-brutalism 의 모서리(`radiusCap: radius6`), 그림자 캐스트(`shadowOffsetAdd: (4,4)`), 테두리 두께(`strokeFloor: stroke4`)는 **CoUI 가 고른 값 하나뿐**이다. 앱은 그 프리셋을 켜거나 끌 수만 있다.

레퍼런스가 파는 것은 정확히 그 세 값을 앱이 정하는 능력이고, 스크린샷 4장의 차이도 대부분 거기서 나온다.

## 2. 이미 되는 것 — 다시 만들지 않는다

**강조 hue 는 오늘도 앱이 정한다.** `CoreSurfaceColorConstraint` 는 hue 를 의도적으로 건드리지 않으므로(브랜드 정체성 보존), blue/green/orange/violet 은 `PrimitiveColors` 교체만으로 나온다. 이 명세는 강조색 API 를 만들지 않는다.

**눌림 피드백은 이미 그림자에서 파생된다.** `pressedTranslateOffset` 이 `shadowOffsetAdd` 를 읽으므로, 오프셋을 키우면 눌림 이동량이 같이 커진다. 파라미터 하나가 두 값을 갈라놓을 위험은 없다.

**Web 은 변환 결과를 굽는다.** `surfaceStyleGeometryBlock` 이 `geometry.radius(step)` 의 **결과값**을 `--coui-radius-*` 로 emit 한다. 레시피가 바뀌면 CSS 가 따라오므로 새 transport 가 필요 없다.

## 3. 무엇을 만드는가

### 3.1 `CoreSurfaceTuning` — 앱이 만질 수 있는 것의 전부

```dart
CoUIApp(
  surfaceStyle: .neoBrutalism,
  surfaceTuning: CoreSurfaceTuning(
    radiusFloor: CoreRadius.radius0,
    radiusCap: CoreRadius.radius0,          // violet 스크린샷: 각진 모서리
    shadowOffsetX: 6,
    shadowOffsetY: 6,
    strokeFloor: CoreStrokeWidth.stroke3,
    stageTintChroma: 0.02,                  // 페이지가 강조 hue 를 옅게 받는다
  ),
)
```

**왜 레시피를 통째로 열지 않는가**: `CoreSurfaceRecipe.copyWith` 를 그대로 노출하면 앱이 `a11y` 와 `id` 에도 닿는다. `boundaryMechanism: .stroke` 는 강제 색상 모드에서 경계가 살아남는다는 **선언**이고, 앱이 그걸 바꿀 수 있으면 선언이 값이 아니라 거짓말이 된다. 접근성 계약은 앱이 협상할 대상이 아니다.

동시에 CoUI 자신의 프리셋 저작은 계속 자유로워야 한다(`shadowMirror` · `highlightRim` · 재질 · weight floor 는 neumorphism/claymorphism/glass 가 쓴다). 그래서 제약은 constraint 타입이 아니라 **앱이 지나는 좁은 타입 한 곳**에 산다.

### 3.2 범위 — 컴파일 타임에 막힌다

`const` 생성자의 `assert` 로 표현한다. 정상 호출부는 `const` 이므로 범위를 벗어난 값은 **컴파일 에러**다.

| 축 | 범위 | 왜 이 범위인가 |
|---|---|---|
| `radiusFloor` / `radiusCap` | `≥ 0`, floor ≤ cap | 사다리 멤버십은 요구하지 않는다 — 변환이 이미 두 경계를 사다리에 스냅한다(D12) |
| `shadowOffsetX` / `shadowOffsetY` | `v ≥ 0`, 상한 없음 | 상한을 정당화할 근거가 없다. 큰 캐스트는 이웃 컨트롤 위로 올라타고 눌림 이동이 점프로 읽히지만 그건 **앱이 소유한 미감의 결과**이지 계약 위반이 아니다. 음수만 막는다 — 이 스타일의 캐스트는 아래-오른쪽이라는 진술이고, 뒤집으면 그 진술이 아닌 다른 것이 된다. Web 은 이 값을 `ThemeConfig` 가 `--coui-control-shadow-offset-*` 로 직접 굽으므로 토큰 사다리 위에 있을 필요도 없다 |
| `strokeFloor` | `CoreStrokeWidth.stroke2` ≤ v < **프리셋 자신의 포커스 링 폭** | 하한: 1px 경계는 이 스타일의 하드 그림자 가장자리와 구분되지 않는다. 상한: 수용 게이트 G1 이 "링이 자기 경계와 구분될 것" 을 요구하므로, 테두리가 링과 같아지는 순간 링이 테두리의 일부로 읽힌다. **리터럴이 아니라 계약의 링 폭에서 파생** — 링이 바뀌면 상한도 따라간다 |
| `stageTintChroma` | `0 ≤ c ≤ C_max` (§4 가 정한다) | 자유 파라미터인 hue 의 최악값이 대비 임계를 넘는 지점 |

### 3.3 배경 틴트 — 페이지만

`CoreSurfaceColorConstraint` 에 `stageTintChroma` 를 더한다. 동작:

- 대상은 **`surface` 하나**. `surfaceContainerLow/Container/High` 는 손대지 않는다.
- `surface` 의 **OKLch L 은 그대로**, hue 를 강조색 hue 로, chroma 를 `stageTintChroma` 로 놓는다.

**왜 페이지만인가**: 스크린샷의 accordion 본문은 흰색이다. 컨테이너 톤까지 틴트하면 그 층이 사라지고 화면이 한 덩어리로 뭉갠다.

**왜 L 을 고정하는가**: 대비는 상대 휘도의 함수다. L 을 움직이면 그 배경 위의 모든 전경 쌍이 같이 움직이고, 감사해야 할 자유 파라미터가 hue 하나에서 hue×L 둘로 늘어난다. L 을 고정하면 남는 변동은 chroma 가 유발하는 휘도 편차뿐이고, 그건 §4 가 훑을 수 있는 크기다.

**고대비에서는 적용되지 않는다.** `applySurfaceStyle` 이 고대비에서 `colorConstraint` 를 통째로 건너뛰는 기존 동작을 그대로 물려받는다 — 새 규칙이 아니라 seat 에 이미 있는 우선순위다(*사용자가 요청한 결과가 앱이 고른 룩을 이긴다*). 반대로 **기하 튜닝은 고대비에서도 유지된다**: 모서리·그림자·두께는 대비 레버가 아니라서 버려도 접근성 이득이 없고 프리셋만 지워진다.

`surfaceMatchesStage`(neumorphism)와는 다른 축이다 — 그건 컨테이너를 페이지에 **맞추는** 진술이고, 이건 페이지에 **색조를 넣는** 진술이다. 둘이 동시에 켜지면 컨테이너도 따라 틴트되는데, 그건 각 프리셋의 저작 문제이지 이 축이 막을 일이 아니다.

### 3.4 seat — 한 곳으로 유지

레시피 조회가 id 기반이라 커스텀이 안 들어간다. **id 대신 해석된 레시피를 받는다**:

```
resolveThemeScheme(palette, brightness:, highContrast:, surfaceRecipe:)
resolveThemeGeometry(surfaceRecipe:)
applySurfaceStyle(base, surfaceRecipe:, highContrast:)
ThemeConfig(palette, surfaceTunings: {CoreSurfaceStyleId.neoBrutalism: tuning})
```

레시피 파생은 `CoreSurfaceRecipe.of(id).tunedBy(tuning)` 한 함수가 소유한다 — 튜닝을 레시피로 접는 자리가 둘이 되면 Flutter 와 Web 이 다른 답을 낸다.

seat 은 늘지 않는다. `scheme_resolution.dart` 가 여전히 색·기하 축이 합류하는 유일한 자리이고, 이 변경은 그 자리가 **읽는 대상**을 상수 테이블에서 인자로 바꿀 뿐이다.

## 4. 대비 — 자유 파라미터를 훑어서 증명한다

수용 게이트 G4 는 색을 굽히는 프리셋에 **감사된 스킴 등록**을 요구하고 CI 가 강제한다. 앱이 hue 를 고르면 등록할 스킴이 앱마다 달라져 그 방법이 성립하지 않는다.

**대신 크기를 묶고 자유 파라미터의 최악값을 훑는다.** `check_contrast.dart` 에 hue sweep 을 추가한다:

- hue 를 0°부터 360°까지 훑으며(스텝은 최악값을 놓치지 않을 만큼 촘촘하게), 각 hue 에서 `stageTintChroma = C_max` 로 틴트한 `surface` 를 만든다.
- 그 배경이 관여하는 **모든 쌍**을 임계에 건다 — 전경 텍스트, 그 위에 놓이는 컨테이너 톤, 경계.
- 전 hue 에서 통과하는 가장 큰 chroma 가 `C_max` 다.

**`C_max` 는 이 명세가 정하지 않는다.** 지금 숫자를 적으면 그건 측정이 아니라 추측이고, 이 레포는 그런 값이 어떻게 조용히 틀리는지 이미 겪었다(claymorphism 의 파스텔이 측정 후에 철회됐다). 구현이 sweep 을 먼저 돌리고, 나온 값이 명세로 돌아온다. **sweep 이 어떤 chroma 에서도 통과하지 못하면 이 축은 착수하지 않는다** — 그 결과 역시 유효한 산출물이다.

**왜 이 방법이 등록보다 강한가**: 등록은 "우리가 고른 조합 하나가 안전하다" 를 말한다. sweep 은 "앱이 무엇을 고르든 안전하다" 를 말한다. 앱이 hue 를 고르는 기능에서 필요한 것은 후자다.

## 5. 범위 밖 (명시적 비목표)

- **커스텀 스타일 id 등록** — 앱이 임의 이름의 새 서페이스 스타일을 정의하는 것. `CoreSurfaceStyleId` 는 닫힌 enum 으로 남는다.
- **최종 사용자 런타임 테마 피커** — 리빌드 없는 CSS 변수 덮어쓰기. 앱 빌드타임 1회 결정만 지원한다.
- **강조색 API** — 이미 팔레트가 한다(§2).
- **다른 프리셋의 튜닝 검증** — 메커니즘은 프리셋 무관하지만, 스크린샷 증거와 sweep 은 neo-brutalism 에서 먼저 끝난다.
- **`a11y` · `id` · 재질 · weight floor · rim · mirror 의 앱 노출** — §3.1.

## 6. 인수 조건

```gherkin
Feature: 앱이 서페이스 프리셋을 자기 값으로 튜닝한다

  Scenario: 각진 모서리 (violet 화면)
    Given 앱이 neo-brutalism 을 radiusCap 0 으로 튜닝했을 때
    When Flutter 와 Web 에서 같은 컴포넌트를 렌더하면
    Then 양쪽 모두 모서리가 0 이고
    And pill(9999) 도 함께 각져야 한다

  Scenario: 그림자 오프셋이 눌림까지 간다
    Given 앱이 shadowOffset 을 (6, 6) 으로 튜닝했을 때
    When 버튼을 누르면
    Then 캐스트가 6/6 으로 그려지고
    And 눌림 이동량이 그와 같은 6/6 이어야 한다

  Scenario: 배경만 틴트된다
    Given 앱이 stageTintChroma 를 상한값으로 두었을 때
    When 페이지와 accordion 본문을 함께 렌더하면
    Then 페이지는 강조 hue 를 받고
    And accordion 본문은 틴트되지 않아야 한다
    And 페이지의 OKLch L 은 튜닝 전과 같아야 한다

  Scenario: 범위를 벗어난 값은 빌드되지 않는다
    Given strokeFloor 를 프리셋 포커스 링 폭 이상으로 적은 const 호출부가 있을 때
    When 분석하면
    Then 컴파일 에러여야 한다

  Scenario: 앱은 접근성 계약에 닿지 못한다
    When CoreSurfaceTuning 의 공개 표면을 훑으면
    Then a11y · id · surface 재질을 지정하는 경로가 없어야 한다

  Scenario: 어떤 hue 를 골라도 대비가 선다
    Given stageTintChroma 가 상한값일 때
    When hue 를 0°에서 360°까지 훑으며 감사하면
    Then 모든 hue 에서 모든 쌍이 임계를 넘어야 한다

  Scenario: 튜닝하지 않은 앱은 아무것도 달라지지 않는다
    Given surfaceTuning 을 주지 않았을 때
    Then 렌더 결과가 튜닝 도입 전과 바이트 단위로 같아야 한다

  Scenario: 고대비는 배경 틴트를 이긴다
    Given 앱이 stageTintChroma 를 상한값으로 두었을 때
    When 사용자가 고대비를 켜면
    Then 페이지 배경이 틴트되지 않은 값으로 돌아가고
    And 모서리·그림자·두께 튜닝은 그대로여야 한다
```

## 7. 수용 게이트 상속

`docs/preset-acceptance-gate.md` 전체를 상속한다. 이 명세가 게이트에 더하는 것:

- **G1** — `strokeFloor` 상한이 링 폭에서 파생되므로, 어떤 튜닝에서도 링과 경계가 구분된다.
- **G2** — `boundaryMechanism` 은 튜닝 대상이 아니고 `strokeFloor` 하한이 stroke 를 보장한다.
- **G4** — 등록 대신 hue sweep(§4). 게이트 문서의 G4 문안이 "자유 파라미터를 가진 프리셋" 경로를 인정하도록 갱신돼야 한다.
- **G6** — seat 은 그대로 한 곳. 컴포넌트는 여전히 튜닝을 모른다.
- **G7** — sweep 과 범위 assert 각각을 negative-test 한다(회귀 주입 → 실패 → 되돌림 → 통과).
