import 'package:coui_web/coui_web.dart' show CoreSurfaceStyleId;
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/internal/preview/scenes.dart';
import 'package:docs_core/shared/component_catalog.dart';

import '../model/matrix_entry.dart';
import '../model/parity_theme.dart';
import '../model/parity_tier.dart';
import 'active_catalog.dart';
import 'capture_probes.dart';
import 'component_class_name.dart';
import 'component_filter_source.dart';
import 'surface_style_pruning.dart';
import 'tier1_policy.dart';
import 'variant_registry.dart';

/// Derives the verification matrix from the catalog and the surface-style
/// enum — the matrix is never hand-maintained (`core/theme-axis-composition.md`
/// — "match-status 를 정적 목록으로 단언하지 마라"; the exact failure mode
/// this file exists to avoid is a hand list rotting as the catalog grows
/// past it).
///
/// **Pruning is a belief, not a proof.** Rule 1 (`surface_style_pruning
/// .dart`) reads a recipe's identity fields; rule 2 keeps every preset that
/// bends a token and, for a preset that only states a material, reads
/// `materialReach` — a measurement of one platform's server render
/// (`material_reach.dart`), not a declaration. What neither checks is the
/// other platform: a Flutter example that composes a marked surface its
/// Web twin does not is invisible here. The architecture doc's design note
/// for this component prescribes the mitigation: a nightly sweep captures
/// pruned combinations anyway on both platforms and fails if one turns out
/// to differ, which would mean a pruning input is wrong rather than that
/// pruning itself is wrong. That sweep is out of this file's scope (#3604
/// is the derivation, not the sweep) — this comment exists so nobody reads
/// "pruned" as "verified identical".
class ParityManifest {
  const ParityManifest._();

  /// Path (repo-root relative) to the doc content directory the variant
  /// registry reads.
  static const String _defaultContentDir = 'docs_core/content/components';

  /// Derives the full (or filtered) matrix.
  ///
  /// [tier] restricts to one tier; omit for both. [components] restricts to
  /// specific catalog slugs; omit for the whole catalog. Every combination
  /// that survives filtering is expanded across the theme axis (2, fixed)
  /// and the pruned surface-style axis (always at least `defaultStyle`) —
  /// neither axis can come back empty, so there is nothing to guard there;
  /// the variant axis is the one that can, from a malformed content file,
  /// and [variantsForSlug] throws rather than let that through silently.
  ///
  /// [source] says where the filter came from, which is what decides whether
  /// an empty result is a typo to reject or an outcome to report — see
  /// [ComponentFilterSource]. The derivation itself cannot tell the two
  /// apart, and defaults to the strict reading.
  ///
  /// [materialReach] is the set of slugs whose rendered example carries the
  /// surface marker (`measureMaterialReachedSlugs`). Required, with no
  /// default: a default would have to be a declared list, and a declared
  /// list is the belief the measurement replaced. A caller that has not
  /// measured passes what it knows and says so.
  static List<MatrixEntry> resolve({
    required Set<String> materialReach,
    ParityTier? tier,
    List<String>? components,
    String contentDir = _defaultContentDir,
    ComponentFilterSource source = .handTyped,
  }) {
    final wantedSlugs = components?.toSet();
    if (wantedSlugs != null) {
      final known = kDocsComponentEntries.map((e) => e.slug).toSet();
      final unknown = wantedSlugs.difference(known);
      if (unknown.isNotEmpty) {
        throw ArgumentError(
          '알 수 없는 --components 슬러그: ${unknown.join(', ')}. '
          '카탈로그에 있는 슬러그만 지정할 수 있다.',
        );
      }
      _rejectDeprecatedSlugs(wantedSlugs);
    }

    final entries = _expand(
      wantedSlugs: wantedSlugs,
      tier: tier,
      contentDir: contentDir,
      surfaceStylesOf: (slug) =>
          surfaceStylesFor(slug, materialReach: materialReach),
    );

    if (entries.isEmpty && source == .handTyped) {
      throw StateError(
        '파생된 매트릭스가 비어있다 — --tier/--components 필터가 카탈로그와 '
        '전혀 겹치지 않는다. 조용히 빈 게이트를 통과시키지 않는다.',
      );
    }

    return entries;
  }

  /// The matrix cells pruning excluded from [resolve] — the nightly
  /// re-verification target (#3620, Epic F). Same filters as [resolve]
  /// ([tier]/[components]), but expanded across [prunedSurfaceStylesFor]
  /// instead of [surfaceStylesFor], so every row here is a combination
  /// [resolve] declared redundant without ever rendering it. An empty
  /// result is valid (a filter that selects only components/tiers pruning
  /// kept fully) and is not an error the way an empty [resolve] is — there
  /// is nothing here for the nightly sweep to re-check, which is a fact
  /// about the filter, not a broken pipeline.
  static List<MatrixEntry> resolvePruned({
    required Set<String> materialReach,
    ParityTier? tier,
    List<String>? components,
    String contentDir = _defaultContentDir,
  }) {
    final wantedSlugs = components?.toSet();
    if (wantedSlugs != null) {
      final known = kDocsComponentEntries.map((e) => e.slug).toSet();
      final unknown = wantedSlugs.difference(known);
      if (unknown.isNotEmpty) {
        throw ArgumentError(
          '알 수 없는 --components 슬러그: ${unknown.join(', ')}. '
          '카탈로그에 있는 슬러그만 지정할 수 있다.',
        );
      }
      _rejectDeprecatedSlugs(wantedSlugs);
    }

    return _expand(
      wantedSlugs: wantedSlugs,
      tier: tier,
      contentDir: contentDir,
      surfaceStylesOf: (slug) =>
          prunedSurfaceStylesFor(slug, materialReach: materialReach),
    );
  }

  /// Shared expansion loop behind [resolve] and [resolvePruned] — the two
  /// differ only in which surface-style set each catalog component expands
  /// across ([surfaceStylesFor] vs. [prunedSurfaceStylesFor]).
  /// 명시적으로 요청된 슬러그가 deprecated 면 조용히 누락시키는 대신
  /// 에러로 알린다 — `_expand` 의 deprecated 제외와 짝. 조용한 누락은
  /// "지정했는데 매트릭스에 없음" 을 호출자가 스스로 발견해야 하는
  /// 형태라, unknown 슬러그를 throw 하는 위 검증과 같은 이유로 막는다.
  static void _rejectDeprecatedSlugs(Set<String> wantedSlugs) {
    final deprecated = wantedSlugs
        .where(
          (slug) => kDocsComponentEntries
              .firstWhere((e) => e.slug == slug)
              .isDeprecated,
        )
        .toList();
    if (deprecated.isNotEmpty) {
      throw ArgumentError(
        'deprecated 컴포넌트는 파리티 매트릭스에서 제외됨: '
        '${deprecated.join(', ')} — deprecate 시 Web 프리뷰 레지스트리가 '
        '삭제되어 한쪽 캡처가 불가능하다.',
      );
    }
  }

  static List<MatrixEntry> _expand({
    required Set<String>? wantedSlugs,
    required ParityTier? tier,
    required String contentDir,
    required List<CoreSurfaceStyleId> Function(String slug) surfaceStylesOf,
  }) {
    final entries = <MatrixEntry>[];
    // 활성(비-deprecated) 컴포넌트만 — 제외 근거와 순회 단일 출처는
    // `active_catalog.dart`. 명시적 --components 로 deprecated 를 요청한
    // 경우는 여기 오기 전에 [_rejectDeprecatedSlugs] 가 조용한 누락 대신
    // 에러로 알린다.
    for (final (:group, :component) in activeCatalogComponents()) {
      if (wantedSlugs != null && !wantedSlugs.contains(component.slug)) {
        continue;
      }

      final entryTier = isTier1(component.slug, group.id)
          ? ParityTier.t1
          : ParityTier.t2;
      if (tier != null && entryTier != tier) continue;

      final variants = variantsForSlug(component.slug, contentDir: contentDir);
      final surfaceStyles = surfaceStylesOf(component.slug);
      final flutterClassName = pascalCaseComponentSlug(component.slug);

      for (final variant in variants) {
        final scene = variant.startsWith(docsScenePrefix)
            ? resolveDocsScene(
                component.slug,
                variant,
                contentDir: contentDir,
              )
            : null;
        for (final theme in ParityTheme.values) {
          for (final surfaceStyle in surfaceStyles) {
            final key =
                '${component.slug}-$variant-'
                '${theme.name}-${surfaceStyle.name}';
            entries.add(
              MatrixEntry(
                component: component.slug,
                variant: variant,
                theme: theme,
                surfaceStyle: surfaceStyle,
                tier: entryTier,
                probes: captureProbes(
                  key: key,
                  component: component.slug,
                  variant: variant,
                  flutterClassName: scene?.flutterOwnerType ?? flutterClassName,
                  docsScene: scene,
                ),
              ),
            );
          }
        }
      }
    }
    return entries;
  }
}
