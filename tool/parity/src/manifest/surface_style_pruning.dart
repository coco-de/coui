import 'package:coui_web/coui_web.dart'
    show CoreSurfaceRecipe, CoreSurfaceStyleId;

/// Non-default styles whose recipe states nothing — computed once, since
/// this only depends on the style itself, not on any component.
///
/// Pruning rule 1 (architecture doc, Component ① responsibilities):
/// "`CoreSurfaceRecipe.of(id)`가 identity인 축만 가진 프리셋 → 그 프리셋
/// 행 제외". Reuses `CoreSurfaceRecipe.statesNothing` — the same predicate
/// `surface_style_switching_test.dart` uses to decide whether the Web
/// stylesheet emits a rule for a style — so a style pruned here is
/// guaranteed to be exactly the styles that render byte-identical to
/// `defaultStyle` on every component, marker or not. `defaultStyle` is
/// deliberately excluded from this set even though its own recipe is always
/// silent by construction — it is not a *redundant* silent style, it is
/// *the* baseline every other style is compared against, and must always
/// remain in the matrix.
final Set<CoreSurfaceStyleId> kRedundantSurfaceStyles = {
  for (final id in CoreSurfaceStyleId.values)
    if (id != .defaultId && CoreSurfaceRecipe.of(id).statesNothing) id,
};

/// The surface styles [slug] should be captured under.
///
/// Pruning rule 2 (architecture doc) asks whether a preset can change a
/// pixel of this component at all. A preset has two ways to do that, and
/// the answer is different for each:
///
/// - **A token constraint** (`CoreSurfaceRecipe.statesTokenConstraint` —
///   palette, geometry, type) lands at the token seat and reaches every
///   component. Nothing about the component gates it, so nothing about
///   the component can prune it. Kept for every slug.
/// - **A material** (translucency, blur, refraction) lands only on an
///   element carrying the surface marker — the component's own root, or a
///   child it composes. Whether this slug has one anywhere in its rendered
///   example is [materialReach], measured by `material_reach.dart` from the
///   actual SSR output rather than declared. Kept only for reached slugs.
///
/// Both halves used to be treated as marker-scoped, with the component's
/// own marker call sites plus a two-entry composing list standing in for
/// reach. The nightly re-capture of every pruned combination said
/// otherwise on 1,406 of 2,528 pairs: the weight floor alone changed 464
/// of them (any text, marker or not), and 44 unmarked components turned
/// out to compose a `Button` or a `Card` in their example. The rule now
/// says what each half actually does.
///
/// What is left for the nightly to catch is narrower and real: a
/// component whose Flutter example composes a marked surface that its Web
/// example does not (or the reverse) — a cross-platform composition
/// asymmetry the render of one platform cannot see.
List<CoreSurfaceStyleId> surfaceStylesFor(
  String slug, {
  required Set<String> materialReach,
}) {
  final reached = materialReach.contains(slug);
  return [
    for (final id in CoreSurfaceStyleId.values)
      if (id == .defaultId ||
          (!kRedundantSurfaceStyles.contains(id) &&
              (CoreSurfaceRecipe.of(id).statesTokenConstraint || reached)))
        id,
  ];
}

/// The surface styles pruned away for [slug] — the complement of
/// [surfaceStylesFor] within [CoreSurfaceStyleId.values]. Empty when
/// pruning kept every style (a reached slug whose non-default styles are
/// all non-redundant).
///
/// This is the nightly re-verification target (#3620, Epic F): the
/// material half of rule 2 is a measurement of one platform's render, and
/// re-capturing exactly this set on both is what turns a composition
/// asymmetry into a caught regression instead of a silent gap (see
/// [surfaceStylesFor] and the `ParityManifest` doc comment).
List<CoreSurfaceStyleId> prunedSurfaceStylesFor(
  String slug, {
  required Set<String> materialReach,
}) {
  final kept = surfaceStylesFor(slug, materialReach: materialReach).toSet();
  return [
    for (final id in CoreSurfaceStyleId.values)
      if (!kept.contains(id)) id,
  ];
}
