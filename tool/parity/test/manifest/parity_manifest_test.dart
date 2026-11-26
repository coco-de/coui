import 'dart:convert';

import 'package:coui_web/coui_web.dart'
    show CoreSurfaceRecipe, CoreSurfaceStyleId;
import 'package:docs_core/shared/component_catalog.dart';
import 'package:test/test.dart';

import '../../src/manifest/parity_manifest.dart';
import '../../src/manifest/surface_style_pruning.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/model/parity_tier.dart';

void main() {
  // A hand-chosen reach set, so these tests pin the derivation and not the
  // measurement (`material_reach_test.dart` pins that): `dialog` and `card`
  // reached, `divider` not.
  const reach = {'dialog', 'card'};

  group('ParityManifest.resolve', () {
    test('every non-deprecated catalog component appears exactly once with '
        'no filter', () {
      final entries = ParityManifest.resolve(materialReach: reach);
      final components = entries.map((e) => e.component).toSet();
      // 카탈로그에서 파생한 기대값 — 고정 숫자로 적으면 카탈로그가
      // 늘거나 deprecate 될 때마다 이 테스트를 고쳐야 한다(#3604 가
      // 막으려는 바로 그것). deprecated 는 제외 — deprecate 시 Web
      // 프리뷰 레지스트리가 삭제되어 한쪽 캡처가 불가능하다.
      final active = kDocsComponentEntries
          .where((e) => !e.isDeprecated)
          .map((e) => e.slug)
          .toSet();
      expect(components, active);
    });

    test('deprecated components never expand', () {
      final entries = ParityManifest.resolve(materialReach: reach);
      final deprecated = kDocsComponentEntries
          .where((e) => e.isDeprecated)
          .map((e) => e.slug)
          .toSet();
      for (final entry in entries) {
        expect(
          deprecated,
          isNot(contains(entry.component)),
          reason:
              '${entry.key}: deprecated 컴포넌트가 매트릭스에 확장됨 — '
              'Web 프리뷰 레지스트리가 없어 캡처가 죽는다.',
        );
      }
    });

    test('explicitly requesting a deprecated slug throws instead of '
        'silently dropping it', () {
      final deprecated = kDocsComponentEntries
          .where((e) => e.isDeprecated)
          .map((e) => e.slug)
          .toList();
      if (deprecated.isEmpty) {
        markTestSkipped('카탈로그에 deprecated 컴포넌트가 없음 — 검증 대상 없음.');
        return;
      }
      expect(
        () => ParityManifest.resolve(
          materialReach: reach,
          components: [deprecated.first],
        ),
        throwsArgumentError,
      );
    });

    test('every entry expands across both themes', () {
      final entries = ParityManifest.resolve(
        materialReach: reach,
        components: ['button'],
      );
      final themes = entries.map((e) => e.theme).toSet();
      expect(themes, {ParityTheme.light, ParityTheme.dark});
    });

    test('an unreached component gets defaultStyle plus every token-bending '
        'preset, and no material-only one', () {
      final entries = ParityManifest.resolve(
        materialReach: reach,
        components: ['divider'],
      );
      final styles = entries.map((e) => e.surfaceStyle).toSet();
      expect(styles, contains(CoreSurfaceStyleId.defaultId));
      for (final id in CoreSurfaceStyleId.values) {
        if (id == CoreSurfaceStyleId.defaultId) continue;
        final recipe = CoreSurfaceRecipe.of(id);
        expect(
          styles.contains(id),
          !kRedundantSurfaceStyles.contains(id) && recipe.statesTokenConstraint,
          reason: id.name,
        );
      }
    });

    test('a reached component gets every non-redundant surface style', () {
      final entries = ParityManifest.resolve(
        materialReach: reach,
        components: ['dialog'],
      );
      final styles = entries.map((e) => e.surfaceStyle).toSet();
      expect(
        styles,
        CoreSurfaceStyleId.values.toSet().difference(kRedundantSurfaceStyles),
      );
    });

    test('--tier filters to exactly that tier', () {
      final t1 = ParityManifest.resolve(
        materialReach: reach,
        tier: ParityTier.t1,
      );
      expect(t1.map((e) => e.tier).toSet(), {ParityTier.t1});
      final t2 = ParityManifest.resolve(
        materialReach: reach,
        tier: ParityTier.t2,
      );
      expect(t2.map((e) => e.tier).toSet(), {ParityTier.t2});
    });

    test('--components restricts to exactly the requested slugs', () {
      final entries = ParityManifest.resolve(
        materialReach: reach,
        components: ['card', 'button'],
      );
      expect(entries.map((e) => e.component).toSet(), {'card', 'button'});
    });

    test(
      'an unknown --components slug throws rather than silently returning nothing',
      () {
        expect(
          () => ParityManifest.resolve(
            materialReach: reach,
            components: ['not-a-real-component'],
          ),
          throwsArgumentError,
        );
      },
    );

    test('confirmed-defect components are present and tier1', () {
      final entries = ParityManifest.resolve(
        materialReach: reach,
        components: ['command', 'date-picker', 'dialog'],
      );
      expect(entries, isNotEmpty);
      for (final entry in entries) {
        expect(entry.tier, ParityTier.t1, reason: entry.key);
      }
    });

    test('every entry carries a root probe naming its own key', () {
      final entries = ParityManifest.resolve(
        materialReach: reach,
        components: ['button'],
      );
      for (final entry in entries) {
        expect(entry.probes, isNotEmpty);
        expect(entry.probes.first.webSelector, contains(entry.key));
      }
    });

    test('all keys are unique — no two cells collide', () {
      final entries = ParityManifest.resolve(materialReach: reach);
      final keys = entries.map((e) => e.key).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('material-only presets appear exactly for reached slugs', () {
      // The one thing the reach set decides. Every other style decision is
      // a fact about the recipes, pinned in surface_style_pruning_test.
      final entries = ParityManifest.resolve(
        materialReach: reach,
        components: ['divider', 'dialog', 'card'],
      );
      final materialOnly = CoreSurfaceStyleId.values.where(
        (id) =>
            id != CoreSurfaceStyleId.defaultId &&
            !kRedundantSurfaceStyles.contains(id) &&
            !CoreSurfaceRecipe.of(id).statesTokenConstraint,
      );
      final withMaterialOnly = entries
          .where((e) => materialOnly.contains(e.surfaceStyle))
          .map((e) => e.component)
          .toSet();
      expect(withMaterialOnly, materialOnly.isEmpty ? isEmpty : reach);
    });

    group('an empty matrix — a typo, or a fact about the diff', () {
      // `dot-indicator` is in the `display` group: not one of the whole-group
      // tier1 ids, not in the named form set, no surface marker, no confirmed
      // defect. So `--tier=t1` selects nothing out of it — the exact shape a
      // PR touching only display/layout/navigation produces.
      const tier2Only = ['dot-indicator'];

      test('a hand-typed filter selecting nothing throws', () {
        // Nobody types this on purpose; it means the slug or the tier is
        // wrong, and passing a vacuous gate would hide that.
        expect(
          () => ParityManifest.resolve(
            materialReach: reach,
            tier: .t1,
            components: tier2Only,
            source: .handTyped,
          ),
          throwsStateError,
        );
      });

      test('and stating no provenance reads as hand-typed', () {
        // The default has to be the strict side: a caller that forgets to
        // say where its filter came from should fail loudly, not silently
        // widen what the gate accepts. Only writing `.derivedFromDiff` —
        // a claim about the input, false if it is untrue — opens it.
        expect(
          () => ParityManifest.resolve(
            materialReach: reach,
            tier: .t1,
            components: tier2Only,
          ),
          throwsStateError,
        );
      });

      test('a diff-derived filter selecting nothing returns empty', () {
        // `--changed-from` picks the components; that they all sit outside
        // the requested tier is a fact about the diff, not a mistake. The
        // gate reports it and exits — the caller is what keeps it from being
        // silent.
        expect(
          ParityManifest.resolve(
            materialReach: reach,
            tier: .t1,
            components: tier2Only,
            source: .derivedFromDiff,
          ),
          isEmpty,
        );
      });

      test('a diff-derived filter does not weaken the unknown-slug check', () {
        // Being allowed to come back empty is not being allowed to name a
        // slug the catalog does not have — a diff cannot produce one, so
        // seeing one means the mapping, not the diff, is wrong.
        expect(
          () => ParityManifest.resolve(
            materialReach: reach,
            components: ['not-a-real-component'],
            source: .derivedFromDiff,
          ),
          throwsArgumentError,
        );
      });

      test('provenance changes nothing when the filter does select', () {
        // Compared by serialized form — `MatrixEntry` has no value equality,
        // so two separately-built lists of identical cells are not `==`.
        String shape(List<MatrixEntry> entries) =>
            jsonEncode(entries.map((e) => e.toJson()).toList());

        expect(
          shape(
            ParityManifest.resolve(
              materialReach: reach,
              components: tier2Only,
              source: .derivedFromDiff,
            ),
          ),
          equals(
            shape(
              ParityManifest.resolve(
                materialReach: reach,
                components: tier2Only,
              ),
            ),
          ),
        );
      });
    });
  });

  group('ParityManifest.resolvePruned', () {
    test('an unreached component is pruned across exactly the material-only '
        'and redundant styles', () {
      final entries = ParityManifest.resolvePruned(
        materialReach: reach,
        components: ['divider'],
      );
      final styles = entries.map((e) => e.surfaceStyle).toSet();
      expect(styles, isNot(contains(CoreSurfaceStyleId.defaultId)));
      expect(
        styles,
        CoreSurfaceStyleId.values
            .where(
              (id) =>
                  id != CoreSurfaceStyleId.defaultId &&
                  (kRedundantSurfaceStyles.contains(id) ||
                      !CoreSurfaceRecipe.of(id).statesTokenConstraint),
            )
            .toSet(),
      );
    });

    test('resolve and resolvePruned never share a (component, style) cell', () {
      final kept = ParityManifest.resolve(
        materialReach: reach,
        components: ['card'],
      );
      final pruned = ParityManifest.resolvePruned(
        materialReach: reach,
        components: ['card'],
      );
      final keptStyles = kept.map((e) => e.surfaceStyle).toSet();
      final prunedStyles = pruned.map((e) => e.surfaceStyle).toSet();
      expect(keptStyles.intersection(prunedStyles), isEmpty);
    });

    test('an empty pruned result is not an error, unlike resolve', () {
      // `dialog` is a marker component whose non-default styles are all
      // currently non-redundant, so nothing is pruned for it — this must
      // return an empty list, not throw the way an empty `resolve()` would.
      expect(
        () => ParityManifest.resolvePruned(
          materialReach: reach,
          components: ['dialog'],
        ),
        returnsNormally,
      );
    });

    test('an unknown --components slug throws, same as resolve', () {
      expect(
        () => ParityManifest.resolvePruned(
          materialReach: reach,
          components: ['not-a-real-component'],
        ),
        throwsArgumentError,
      );
    });
  });
}
