import 'package:coui_web/coui_web.dart'
    show CoreSurfaceRecipe, CoreSurfaceStyleId;
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/internal/preview/scenes.dart';
import 'package:docs_core/shared/component_catalog.dart';
import 'package:test/test.dart';

import '../../src/manifest/parity_manifest.dart';
import '../../src/manifest/pruned_pairs.dart';
import '../../src/manifest/surface_style_pruning.dart';
import '../../src/manifest/variant_registry.dart';
import '../../src/model/parity_theme.dart';

void main() {
  // A hand-chosen reach set: `divider` is left unreached so its pairs
  // exercise the material-only pruning, `dialog` is reached so nothing is
  // pruned for it. The rule under test is the pairing, not the measurement
  // (`material_reach_test.dart` pins that).
  const reach = {'dialog'};

  group('resolvePrunedPairs', () {
    test(
      'documentation probes use the same actual scene owner in both matrices',
      () {
        final regular = {
          for (final entry in ParityManifest.resolve(
            materialReach: reach,
            components: ['button'],
          ))
            entry.key: entry,
        };
        final pruned = {
          for (final entry in ParityManifest.resolvePruned(
            materialReach: reach,
            components: ['button'],
          ))
            entry.key: entry,
        };
        final pairs = resolvePrunedPairs(materialReach: reach)
            .where(
              (pair) =>
                  pair.baseline.component == 'button' &&
                  pair.baseline.variant.startsWith(docsScenePrefix),
            )
            .toList();
        expect(pairs, isNotEmpty);
        for (final pair in pairs) {
          final scene = resolveDocsScene('button', pair.baseline.variant);
          expect(pair.baseline.probes, regular[pair.baseline.key]!.probes);
          expect(pair.pruned.probes, pruned[pair.pruned.key]!.probes);
          for (final entry in [pair.baseline, pair.pruned]) {
            expect(
              entry.probes.single.flutterFinder,
              'byType:${scene.flutterOwnerType}',
            );
            expect(
              entry.probes.single.fields,
              pair.baseline.probes.single.fields,
            );
            expect(
              entry.probes.single.nativeBoxSource,
              pair.baseline.probes.single.nativeBoxSource,
            );
            expect(
              entry.probes.single.boxObservationSource,
              pair.baseline.probes.single.boxObservationSource,
            );
          }
        }
      },
    );
    test('deprecated components contribute no pruned pairs — pruned side '
        'nor baseline side', () {
      // deprecate 시 Web 프리뷰 레지스트리가 삭제되어 캡처가 불가능하다.
      // 매트릭스(`ParityManifest.resolve`)만 제외하고 프루닝 쌍이 계속
      // 확장하면 야간 재확인 캡처가 죽는다 — 두 파생이 같은
      // `activeCatalogComponents()` 를 순회하는지 여기서 고정한다.
      final deprecated = kDocsComponentEntries
          .where((e) => e.isDeprecated)
          .map((e) => e.slug)
          .toSet();
      for (final pair in resolvePrunedPairs(materialReach: reach)) {
        expect(
          deprecated,
          isNot(contains(pair.pruned.component)),
          reason: '${pair.pruned.key}: deprecated 컴포넌트가 프루닝 쌍에 확장됨',
        );
        expect(
          deprecated,
          isNot(contains(pair.baseline.component)),
          reason: '${pair.baseline.key}: deprecated 컴포넌트가 baseline 쌍에 확장됨',
        );
      }
    });
    test('an unreached component contributes one pair per pruned style '
        'per theme, always paired with its own defaultStyle', () {
      final pairs = resolvePrunedPairs(materialReach: reach).where(
        (p) => p.pruned.component == 'divider',
      );

      // divider is unreached, so only the material-only presets (and any
      // redundant ones) are pruned for it — the token-bending presets stay
      // in the matrix because they reach it through the token seat. One
      // pair per pruned style, for every (variant, theme) combination
      // divider's own doc page declares.
      final prunedStyleCount = CoreSurfaceStyleId.values
          .where(
            (id) =>
                id != CoreSurfaceStyleId.defaultId &&
                (kRedundantSurfaceStyles.contains(id) ||
                    !CoreSurfaceRecipe.of(id).statesTokenConstraint),
          )
          .length;
      final variantCount = variantsForSlug(
        'divider',
        contentDir: kDefaultPrunedPairsContentDir,
      ).length;
      expect(
        pairs.length,
        variantCount * ParityTheme.values.length * prunedStyleCount,
      );
      for (final pair in pairs) {
        expect(pair.pruned.surfaceStyle, isNot(CoreSurfaceStyleId.defaultId));
        expect(pair.baseline.surfaceStyle, CoreSurfaceStyleId.defaultId);
        expect(pair.pruned.component, pair.baseline.component);
        expect(pair.pruned.variant, pair.baseline.variant);
        expect(pair.pruned.theme, pair.baseline.theme);
      }
    });

    test('a reached component only contributes pairs for its redundant '
        '(identity) styles, if any', () {
      final pairs = resolvePrunedPairs(materialReach: reach).where(
        (p) => p.pruned.component == 'dialog',
      );

      // dialog is reached: surfaceStylesFor keeps every style that isn't
      // redundant. Whatever's left over (if anything) is exactly
      // kRedundantSurfaceStyles for this run of the surface recipe set —
      // assert the pruned set here is a subset of that, never a style
      // dialog's own surfaceStylesFor already kept.
      final kept = surfaceStylesFor('dialog', materialReach: reach).toSet();
      for (final pair in pairs) {
        expect(kept, isNot(contains(pair.pruned.surfaceStyle)));
      }
    });

    test('every pruned entry and its baseline share the same probes/tier', () {
      final pairs = resolvePrunedPairs(materialReach: reach).where(
        (p) => p.pruned.component == 'divider',
      );
      for (final pair in pairs) {
        expect(pair.pruned.tier, pair.baseline.tier);
        expect(
          pair.pruned.probes.map((p) => p.role),
          pair.baseline.probes.map((p) => p.role),
        );
      }
    });

    test('pruned and baseline keys always differ', () {
      for (final pair in resolvePrunedPairs(materialReach: reach)) {
        expect(pair.pruned.key, isNot(pair.baseline.key));
      }
    });
  });
}
