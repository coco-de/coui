// #3620 — the nightly sweep's half of the mitigation `ParityManifest`'s
// own doc comment prescribes: "Pruning is a belief, not a proof." Both
// pruning rules in `surface_style_pruning.dart` only inspect
// *declarations* (a recipe's identity fields, a fixed marker-component
// set) — neither actually renders anything. This file derives every
// combination those rules exclude, paired with the `defaultStyle`
// baseline they claim it renders identically to, so a nightly job can
// capture both and let a real pixel diff decide whether the exclusion was
// correct.
import 'package:coui_web/coui_web.dart' show CoreSurfaceStyleId;
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/internal/preview/scenes.dart';

import '../model/matrix_entry.dart';
import '../model/parity_theme.dart';
import '../model/parity_tier.dart';
import 'active_catalog.dart';
import 'capture_probes.dart';
import 'component_class_name.dart';
import 'surface_style_pruning.dart';
import 'tier1_policy.dart';
import 'variant_registry.dart';

/// One pruned combination to re-verify, plus the `defaultStyle` entry
/// [surfaceStylesFor] claims it is pixel-identical to.
class PrunedPair {
  const PrunedPair({required this.pruned, required this.baseline});

  /// The (component, variant, theme, surfaceStyle) a normal
  /// `ParityManifest.resolve()` run would never capture.
  final MatrixEntry pruned;

  /// The same (component, variant, theme) at `defaultStyle` — captured
  /// this same sweep run, so the diff is same-run/same-renderer and can
  /// use a tight "should be identical" tolerance rather than the loose
  /// cross-platform parity threshold.
  final MatrixEntry baseline;
}

/// Default doc-content directory — mirrors `ParityManifest`'s own default
/// so a caller that doesn't override either derivation reads variants the
/// same way in both.
const String kDefaultPrunedPairsContentDir = 'docs_core/content/components';

/// Every pruned (component, variant, theme, surfaceStyle) combination the
/// catalog produces, each paired with its `defaultStyle` counterpart.
///
/// A component whose [surfaceStylesFor] result already covers every
/// [CoreSurfaceStyleId] contributes nothing here — there is nothing pruned
/// to re-verify for it.
///
/// [materialReach] — the slugs whose rendered Web example carries the
/// surface marker (`measureMaterialReachedSlugs`) — is the same input
/// `ParityManifest.resolve` prunes on. Passing it in rather than measuring
/// here keeps the two derivations reading one measurement: a pair whose
/// pruned side was decided against a different reach set than the matrix
/// would re-verify a combination the matrix never actually pruned.
List<PrunedPair> resolvePrunedPairs({
  required Set<String> materialReach,
  String contentDir = kDefaultPrunedPairsContentDir,
}) {
  final pairs = <PrunedPair>[];

  // 활성(비-deprecated) 컴포넌트만 — 순회 단일 출처는 `active_catalog.dart`.
  // 이 순회가 `parity_manifest.dart` 와 별도 사본이던 동안 deprecated 제외가
  // 한쪽에만 들어가, 프루닝 쌍이 deprecate 된 컴포넌트를 계속 확장해 야간
  // 재확인 캡처가 죽었다.
  for (final (:group, :component) in activeCatalogComponents()) {
    final prunedStyles = prunedSurfaceStylesFor(
      component.slug,
      materialReach: materialReach,
    );
    if (prunedStyles.isEmpty) continue;

    final entryTier = isTier1(component.slug, group.id)
        ? ParityTier.t1
        : ParityTier.t2;
    final variants = variantsForSlug(component.slug, contentDir: contentDir);
    final flutterClassName = pascalCaseComponentSlug(component.slug);

    MatrixEntry buildEntry(
      String variant,
      ParityTheme theme,
      CoreSurfaceStyleId style,
    ) {
      final key = '${component.slug}-$variant-${theme.name}-${style.name}';
      final scene = variant.startsWith(docsScenePrefix)
          ? resolveDocsScene(component.slug, variant, contentDir: contentDir)
          : null;
      return MatrixEntry(
        component: component.slug,
        variant: variant,
        theme: theme,
        surfaceStyle: style,
        tier: entryTier,
        probes: captureProbes(
          key: key,
          component: component.slug,
          variant: variant,
          flutterClassName: scene?.flutterOwnerType ?? flutterClassName,
          docsScene: scene,
        ),
      );
    }

    for (final variant in variants) {
      for (final theme in ParityTheme.values) {
        final baseline = buildEntry(
          variant,
          theme,
          CoreSurfaceStyleId.defaultId,
        );
        for (final prunedStyle in prunedStyles) {
          pairs.add(
            PrunedPair(
              pruned: buildEntry(variant, theme, prunedStyle),
              baseline: baseline,
            ),
          );
        }
      }
    }
  }

  return pairs;
}
