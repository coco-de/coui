import 'package:coui_flutter/coui_flutter.dart';

/// 이미 고른 [base] 테마에 서페이스 프리셋을 접어 넣는다.
///
/// 프리셋 해석의 **단일 출처**다. `CoUIApp` 과 검증 하네스가 같은 함수를
/// 호출해야 하는 이유는, 하네스가 이 fold 를 복제하는 순간 프리셋 해석의 두
/// 번째 출처가 생기고 `CoUIApp` 이 순서를 바꾸면 조용히 갈리기 때문이다 —
/// **검증 도구가 검증 대상과 다른 답을 내는** 실패이고, 그 divergence 를
/// 잡으려고 만드는 것이 이 파이프라인이다.
///
/// ## 순서가 의미를 갖는다
///
/// geometry → colorConstraint → surface → typography(단계 → 굵기 하한) 순이며,
/// **마지막에 쓰는 축이 이긴다**. 이건 우연이 아니라 명시된 결정이므로 줄
/// 순서를 바꾸지 마라.
///
/// ## [highContrast] 가 두 축에 다르게 작용한다
///
/// - **colorConstraint 는 건너뛴다.** 이 자리는 팔레트가 아니라 이미 완성된
///   테마를 들고 있어, 프리셋이 방금 굽힌 것 위로 대비를 다시 올릴 수 없다.
///   장식을 버리는 쪽이 그 한계의 안전한 방향이다 — 고대비를 켠 사용자는
///   가독성을 요청한 것이지 앱이 고른 룩을 요청한 게 아니다. 더 세밀한
///   순서는 토큰 레벨 seat(`resolveThemeScheme`)이 유지한다.
/// - **typography 는 유지한다.** weight 는 대비 레버가 아니라서, 굵게 잡은
///   프리셋은 팔레트를 올려도 그대로 읽힌다 — 접근성 이득 없이 프리셋만
///   지우게 된다.
///
/// ## 전제 — colorConstraint 를 가진 프리셋은 **해결된** 스킴을 요구한다
///
/// `colorConstraint` 는 색을 OKLch 로 환산해 굽히므로 실제 ARGB 를 읽는다.
/// [base] 의 `colorScheme` 이 토큰 참조 상태(`ResolvedColorScheme.tokenized`,
/// 즉 `const ThemeData()` 의 기본값)면 그 자리에서 던진다. 실제 앱은 팔레트에서
/// 해결된 스킴을 들고 있어 이 경로를 지나지 않지만, 테스트에서 기본 생성자
/// 테마를 그대로 넘기면 만난다.
///
/// 기본 프리셋(`.defaultStyle`)은 네 축이 전부 identity 라, 밝은 [base] 는
/// 그대로 돌려받는다(어두운 [base] 는 아래 밝기 때문에 기하만 바뀐다). 그래서
/// 프리셋을 지정하지 않는 호출자는 이 전제와 무관하다.
///
/// ## [surfaceTuning] — 앱이 프리셋 값을 정한다
///
/// 프리셋이 저작한 모서리·캐스트·테두리를 앱 값으로 바꾼다. 접거나 접지 않는
/// 판단은 여기서 하지 않는다 — `resolveThemeRecipe` 한 곳이 소유하고, Web 의
/// `ThemeConfig` 도 같은 함수를 부른다. 튜닝하지 않은 앱은 프리셋 인스턴스
/// **자기 자신**을 되받으므로 이 경로가 생기기 전과 바이트 단위로 같다.
///
/// ## [density] — 기하에 같이 실린다
///
/// 밀도는 프리셋의 기하와 같은 값(`CoreSurfaceGeometryConstraint`)에 실려
/// `theme.geometry` 로 나간다. 간격·인셋·컨트롤 행·모서리를 Flutter 값으로
/// 바꾸는 변환이 그 값을 받으므로, 밀도가 컴포넌트에 닿는 자리도 그
/// 변환들이다 — 어떤 컴포넌트도 밀도를 직접 읽지 않는다. 밀도와 스타일이 한
/// 모서리를 같이 굽힐 때의 순서(밀도 먼저, 스타일 나중)는 그 값이 소유한다.
/// 기본값(`standard`)은 identity 라, 밀도를 말하지 않은 앱은 [base] 를 그대로
/// 되받는다.
///
/// ## 밝기 — 그림자 세기만 바뀐다
///
/// [base] 의 밝기(`coreBrightness`)도 같은 기하에 실린다. 기하가 밝기에 따라
/// 다르게 그리는 값은 그림자의 알파 하나다 — Dark 면 캐스트마다
/// `CoreShadow.darkStrength` 배(최대 1). 그림자의 모양은 Light 와 같다. 고대비
/// Dark 도 어두운 [base] 라 같은 배수를 받는다. 이 접기를 거치지 않은 맨
/// `ThemeData` 는 밀도·스타일이 없는 것처럼 Light 세기다.
///
/// ## [quality] — 같은 재질에서 덜어낼 수 있는 만큼만 덜어낸다
///
/// 품질 단계는 재질이 **그리는 것 중 비싼 것**을 사다리 위에서 한 칸씩
/// 내려놓는다(`CoreQualityLadder`): 굴절, 그리고 backdrop 패스와 그 위에 얹힌
/// 반투명 채움. 단계는 효과를 **더하지 않는다** — 레시피가 말하지 않은 굴절을
/// 만들어 주는 단계는 없고, 단계가 내려놓는 것은 고대비·투명도 줄이기가 이미
/// 내려놓은 것과 교집합일 뿐이다. 그래서 접근성 설정과 단계가 같은 줄에서
/// 만나도 순서를 따질 필요가 없다.
///
/// **투명도 줄이기가 단계보다 먼저다.** 설정이 켜져 있으면 받은 단계가 무엇이든
/// 사다리에서 굴절과 패스를 모두 내려놓는 첫 단계(`CoreQualityLadder.effective`)로
/// 접힌다. 그 단계의 재질은 `CoreSurfaceToken.withoutTransparency` 한 문장이고,
/// 이 설정이 예전부터 하던 일과 같다 — 같은 정책을 두 번 적지 않으려고 설정을
/// 단계의 한 값으로 접었다.
///
/// 접힌 결과는 `ThemeData.surfaceQuality` 로 **남는다.** 재질 필드는 이미
/// 덜어낸 값이라 리졸버는 그것만 읽지만, 로컬 재질 오버라이드
/// (`resolveSurfaceTheme`)는 자기 레시피에서 재질을 새로 만들어서 앱의
/// 표면이 덜어낸 것을 똑같이 덜어내야 하기 때문이다.
///
/// 기본값(`full`)은 아무것도 바꾸지 않는다 — 같은 인스턴스를 되돌려 주므로
/// 단계를 말하지 않는 앱은 이 인자가 생기기 전과 바이트 단위로 같은 테마를 받는다.
///
/// ## [typographyTier] — 제목 크기가 화면 폭을 따른다
///
/// 글자 단계는 typography 에 실린다. display · headline 여섯 역할만
/// 그 단계의 크기로 내려가고(`CoreTypography.atTier`), 그 밖의 역할은 그대로다.
/// 크기를 바꾸는 방법은 치환이 아니라 역할별 비율이다 — [base] 의 typography 에
/// 이미 곱해진 글자 배율(`ThemeData.fromCore` 의 textScaling)과 앱이 저작한
/// 제목 크기를 지우지 않고, 뒤에 오는 `AdaptiveScaling` 과도 순서를 바꿔도 같은
/// 답을 낸다. 굵기 하한보다 먼저 온다 — 하한은 크기를 모르고, 단계는 굵기를
/// 모른다. 고대비에서도 유지된다(굵기 하한과 같은 이유로, 크기는 대비 레버가
/// 아니다).
///
/// 기본값(`desktop`)은 저작한 스케일 그 자체라 identity 다. 그래서 단계를
/// 말하지 않는 호출자 — 이 함수를 직접 부르는 검증 하네스 — 는 이 자리가
/// 생기기 전과 같은 테마를 되받는다. 뷰포트 폭에서 단계를 고르는 것은
/// `CoUILayer` 이고, 컴포넌트는 단계를 읽지 않는다.
///
/// [devicePixelRatio] 는 화면의 배율이다. 받으면 가는 선 단계
/// (`CoreStrokeWidth.stroke0_5`)를 그 화면이 그리는 폭으로 기하에 싣는다 —
/// 2배 미만에서는 1px(반 픽셀 선은 제 색보다 옅게 번진다), 2배부터는 0.5
/// (`CoreStrokeWidth.hairlineAt`). Web 의 `--coui-stroke-width-0_5` 가 같은
/// 기준으로 화면을 읽는다. 받지 않는 호출자는 0.5 를 그대로 그린다.
ThemeData applySurfaceStyle(
  ThemeData base, {
  required CoreSurfaceStyleId surfaceStyle,
  required bool highContrast,
  CoreSurfaceTuning surfaceTuning = .none,
  bool? reduceTransparency,
  CoreQualityTier quality = .defaultTier,
  CoreDensity density = .defaultDensity,
  CoreBreakpointTier typographyTier = .desktop,
  double? devicePixelRatio,
}) {
  // 레시피를 한 번만 해석한다. 예전엔 `of(id)` 와 `resolveThemeGeometry` 를
  // 따로 불러 같은 답을 두 경로로 얻었는데, 앱이 프리셋을 튜닝할 수 있게 된
  // 지금 그 둘은 **갈릴 수 있는 두 출처**다 — 한쪽만 튜닝을 반영하면 색은
  // 튜닝된 프리셋이고 기하는 저작 원본인 화면이 나온다.
  final reducedTransparency = reduceTransparency ?? base.reduceTransparency;
  // The tier the surfaces are drawn at: the one asked for, unless a
  // reduce-transparency preference takes it to the lowest one first.
  const ladder = CoreQualityLadder.standard;
  final tier = ladder.effective(
    quality,
    reduceTransparency: reducedTransparency,
  );
  final recipe = resolveThemeRecipe(
    surfaceStyle: surfaceStyle,
    surfaceTuning: surfaceTuning,
  );

  // 프리셋의 기하 — 모서리 반경과 선 두께 — 에 테마 밀도와 밝기를 싣는다.
  // 화면 배율을 받으면 가는 선(stroke0_5)이 그 화면에서 그려질 폭도 싣는다 —
  // 2배 미만 화면에서는 1px. 받지 않으면 기하는 배율을 모르는 채로 남는다.
  final densityAndBrightness = recipe.geometry
      .atDensity(density)
      .atBrightness(base.coreBrightness);
  final geometry = devicePixelRatio == null
      ? densityAndBrightness
      : densityAndBrightness.atDevicePixelRatio(devicePixelRatio);
  final accessibleBase = reducedTransparency == base.reduceTransparency
      ? base
      : base.copyWith(reduceTransparency: () => reducedTransparency);
  final qualified = tier == accessibleBase.surfaceQuality
      ? accessibleBase
      : accessibleBase.copyWith(surfaceQuality: () => tier);
  var styled = geometry.isIdentity
      ? qualified
      : qualified.copyWith(geometry: () => geometry);

  // 프리셋의 색 진술. 고대비에서는 적용 후 일부만 덮는 대신 **통째로**
  // 건너뛴다 (위 doc 참조).
  final colorConstraint = recipe.colorConstraint;
  if (!colorConstraint.isIdentity && !highContrast) {
    styled = styled.copyWith(
      colorScheme: () => colorConstraint.apply(styled.colorScheme),
    );
  }

  // 프리셋의 표면 처리 — 반투명 · 블러 · 채도 · 휘도 · 엣지 시인.
  //
  // 이 값들이 한 fold 에 있는 이유는 **한 backdrop 패스**이기 때문이다. 채도만
  // 따로 접으면 블러가 없는 표면에 채도가 걸리는 조합이 생기고, 그건 재질이
  // 아니라 그냥 색이 진해진 표면이다.
  // 투명도 줄이기 — 정책은 `coui_core` 의 `withoutTransparency()` 하나이고
  // Web 의 `prefers-reduced-transparency` 규칙이 같은 문장을 CSS 로 적는다.
  //
  // Flutter 는 이 신호를 **읽지 못한다**. `AccessibilityFeatures` 에
  // 투명도 항목이 없어서(Apple 플랫폼엔 OS 설정이 있는데도) 읽을 것이
  // 없다. 그래서 읽는 대신 **받는다** — 자기 수단으로 신호를 얻은 앱이
  // `CoUIApp` 에 건네면 이 자리가 Web 과 같은 폴백을 적용한다. 이쪽에서
  // 할 수 있는 최대치이고, 폴백을 영영 못 켜는 것보다는 낫다.
  // The content role, and deliberately so.
  //
  // These flat fields are `_contentMaterial`'s authoritative source —
  // `ThemeData.surfaceFor(content)` reassembles the token from them, while
  // the functional role has its own stored slot below. Writing the
  // functional material here therefore does not "carry the style's
  // material"; it hands the *content* role the floating one.
  //
  // That was tried. A card then painted a 0.5 fill with its stroke
  // suppressed and mounted a `BackdropFilter`, while the same card nested
  // one level deep stayed opaque — because the nesting table had already
  // been corrected. The role split lands in `coui_core` and dies right
  // here if this line reaches for the other role.
  final surface = ladder.settle(tier, recipe.surface);
  if (surface != null) {
    styled = styled.copyWith(
      // No `?? 0`. A material that states no backdrop pass says so with
      // null, and coercing it to zero made the theme claim a pass the
      // recipe never stated — invisible while every material through this
      // line was glass. It stopped being invisible the moment one role
      // became a standard material: `_contentMaterial` rebuilt from a
      // zero here at depth 0, while depth >= 1 came straight off
      // `nestedSurfaces` as null, so Flutter disagreed with itself across
      // depth about the same role. `surfaceOpacity` on the next line keeps
      // the token alive, so null here does not read as "no material".
      surfaceBlur: () => surface.blurRadius,
      // Resolved at the same seat and for the same reason as the dimming
      // below: the flat field is the number for the mode this fold builds.
      surfaceOpacity: () => surface.opacity.resolve(base.coreBrightness),
      // The lift for the mode this fold builds, for the same reason as the
      // two terms around it: the flat field is the number a renderer takes.
      // A material that states one lift gives light's and dark's the same.
      surfaceSaturation: () => surface.saturationFor(base.coreBrightness),
      // The seat where the authored pair becomes a number. `base` is the
      // theme the app already chose — light, dark, or a high-contrast one
      // — so its brightness is the mode this fold is building for. The
      // pair exists because a multiply helps in opposite directions on
      // the two sides of the palette; see `CoreBackdropBrightness`.
      surfaceBackdropBrightness: () =>
          surface.backdropBrightness.resolve(base.coreBrightness),
      surfaceSheen: () => surface.sheen,
      // 중첩 정책도 같은 fold 에서 온다. Web 은 이걸 CSS 규칙으로 내고
      // Flutter 는 ambient 깊이로 읽는다 — 정책 문장은 하나다.
      nestedSurfaces: () => recipe.nestedSurfaces,
      // 고대비에서는 재질은 그대로 칠하되 **테두리를 돌려준다**. Web 은
      // 같은 판단을 `forced-colors` / `prefers-contrast` 규칙으로 내리고,
      // Flutter 엔 forced-colors 가 없으므로 이 게이트가 그 짝이다 —
      // 보장은 같고 표현만 각 플랫폼 idiom.
      surfaceDrawsOwnEdge: () => surface.drawsOwnEdge && !highContrast,
      // 투명도 줄이기는 두 재질 모두에 적용된다 — 한쪽만 불투명해지면
      // 떠 있는 패널만 폴백을 받고 카드는 안 받는 화면이 나온다.
      functionalSurface: () {
        final floating = recipe.surfaceFor(CoreSurfaceRole.functional);
        if (floating == null) return null;

        final settled = ladder.settle(tier, floating)!;

        // 고대비 게이트를 평면 필드와 **같은 값으로** 건다. 안 걸면 이
        // 토큰의 `drawsOwnEdge` 만 원본 그대로 남아, 같은 테마에서
        // `theme.surfaceDrawsOwnEdge` 는 false 인데
        // `theme.surfaceFor(.functional)!.drawsOwnEdge` 는 true 인
        // 상태가 된다 — 지금은 아무도 후자를 안 읽어서 증상이 없고,
        // 그게 정확히 이 레포가 반복해서 기록한 실패의 시작 모양이다.
        return settled.copyWith(
          drawsOwnEdge: settled.drawsOwnEdge && !highContrast,
        );
      },
    );
  }

  // The morph rides the same seat but not the same condition: it is not a
  // surface treatment, so a style can state one without stating a material,
  // and high contrast has no opinion about motion. Reduced motion is
  // answered by the clip itself, per-duration, where the signal lives.
  final morph = recipe.overlayMorph;
  if (morph != null) {
    styled = styled.copyWith(overlayMorph: () => morph);
  }

  // Bending rides the same seat as the rest of the material, and drops out
  // under high contrast for the same reason the translucency does: a mode
  // turned on to make edges decidable is not the moment to bend what is
  // behind them. And under reduce-transparency, because the fold above
  // just took the backdrop pass away — a surface with nothing showing
  // through it has nothing to bend. The renderer would already mount no
  // shader for a surface with no pass; stating it here is what keeps the
  // theme from carrying a bend it cannot draw, and what the Web twin's
  // `prefers-reduced-transparency` rule does when it zeroes the filter.
  //
  // The tier is the same statement from the other side: a tier that goes
  // without the bend leaves the request out, and it never adds one the recipe
  // did not state.
  final refraction = ladder.settleRefraction(tier, recipe.refraction);
  if (refraction != null && !highContrast) {
    styled = styled.copyWith(surfaceRefraction: () => refraction);
  }

  // The frost and the body shade ride the pass as well, and drop out for
  // the same two reasons — and for one more that is theirs: they are
  // decoration laid over content a person asked to see more plainly. Web's
  // `prefers-contrast` / `forced-colors` rule is the twin of the first gate
  // and `prefers-reduced-transparency` (which removes the whole filter list)
  // the twin of the second.
  //
  // A tier that goes without the backdrop pass takes them with it: both are
  // drawn by that pass, and the fold above has already made the fill opaque.
  // A tier that goes without only the bend keeps both — the shade reads no
  // coordinates, and the frost is a pass of its own. On the Web the tier's
  // stylesheet rule removes the whole filter list, as the
  // `prefers-reduced-transparency` rule does.
  //
  // Collapsed to the mode this fold builds, like the dimming and the chroma
  // lift above: the flat field is the number a renderer takes, and `base`
  // is the theme the app already chose.
  final keepsPass = !ladder.withholds(tier, CoreQualityEffect.backdropPass);
  if (!highContrast && !reducedTransparency && keepsPass) {
    final frost = recipe.frost;
    if (frost != null) {
      styled = styled.copyWith(
        surfaceFrost: () => frost.atBrightness(base.coreBrightness),
      );
    }
    // A shade of nothing in this mode is no shade: the theme then carries
    // none, and a surface does not mount the program to draw nothing.
    final shade = recipe.bodyShade?.atBrightness(base.coreBrightness);
    if (shade != null && shade.strength > 0) {
      styled = styled.copyWith(surfaceBodyShade: () => shade);
    }
  }

  // 타이포는 같은 seat 에서 합류하되 고대비에서도 살아남는다 (위 doc 참조).
  // 단계가 먼저, 굵기 하한이 나중이다 — 단계는 크기와 자간만, 하한은 굵기만
  // 쓴다.
  final tiered = styled.typography.atTier(typographyTier);
  if (!identical(tiered, styled.typography)) {
    styled = styled.copyWith(typography: () => tiered);
  }

  final typography = recipe.typography;
  if (!typography.isIdentity) {
    styled = styled.copyWith(
      typography: () => typography.apply(styled.typography),
    );
  }

  return styled;
}
