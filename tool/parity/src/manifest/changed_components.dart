import 'package:docs_core/shared/component_catalog.dart';

/// What a set of changed (repo-root-relative) file paths implies for the
/// verification matrix — the answer `--changed-from` (#3610) exists to
/// compute, so a PR gate can restrict Tier1 to only what it actually
/// touched instead of running the whole tier on every PR (NFR-001).
sealed class ChangedComponentSelection {
  const ChangedComponentSelection();
}

/// Every changed path mapped to a known catalog component (or was outside
/// the pipeline's concern entirely) — safe to restrict the matrix to
/// exactly [slugs].
class ChangedComponentSet extends ChangedComponentSelection {
  const ChangedComponentSet(this.slugs);

  final Set<String> slugs;
}

/// No safe restriction exists — a path inside the pipeline's own library
/// trees (`packages/{coui_core,coui_flutter,coui_web}/lib/`) changed
/// outside any single component's own directory. This is what makes a path
/// "infra" without a maintained list of infra paths: `theme_config.dart`,
/// `surface_recipe.dart`, `semantic_mapping.dart`, `core_to_css.dart`,
/// `core_to_flutter.dart`, the surface fold functions, and anything else
/// the architecture doc names by example all live somewhere under one of
/// those three `lib/` trees but outside a component's own directory, so
/// they reach this case by construction rather than by being named here —
/// a second, hand-maintained list would only be a second place for that
/// set to drift from reality. A component-shaped path naming a directory
/// the catalog does not know also lands here, conservatively, rather than
/// being silently dropped.
///
/// "모르면 전체": the pipeline runs everything rather than guess at a
/// subset, because a wrong guess here means an infra regression ships with
/// nothing having checked it — silently selecting zero (or the wrong few)
/// is the failure mode this whole feature exists to prevent.
class ChangedComponentFallbackToAll extends ChangedComponentSelection {
  const ChangedComponentFallbackToAll(this.reason);

  /// Human-readable reason for logging — which path forced the fallback
  /// and why, so a CI log answers "why did this run everything" without
  /// someone having to re-derive it from the diff by hand.
  final String reason;
}

/// No changed path touched the pipeline's library trees at all — e.g. a
/// README, a CI workflow, or docs content — so the matrix is legitimately
/// empty, not a filter that failed to match anything. Distinct from
/// [ChangedComponentFallbackToAll]: this is a confident "nothing to check"
/// a PR gate can use to exit early, not "couldn't tell, so check
/// everything".
class ChangedComponentNone extends ChangedComponentSelection {
  const ChangedComponentNone();
}

/// `packages/coui_{flutter,web}/lib/src/components/<cat>/<comp>/**` — the
/// per-platform widget/resolver home of a component.
final RegExp _platformComponentPath = RegExp(
  '^packages/coui_(?:flutter|web)/lib/src/components/[^/]+/([^/]+)/',
);

/// `packages/coui_core/lib/src/component/contracts/<comp>/**` — the
/// platform-neutral contract/style/theme home of a component.
final RegExp _coreContractPath = RegExp(
  '^packages/coui_core/lib/src/component/contracts/([^/]+)/',
);

/// The three library roots the parity pipeline reads from. A changed path
/// under one of these that is *not* also under a component's own directory
/// ([_platformComponentPath] / [_coreContractPath]) is an infra change by
/// definition — it is library source the matrix generation or the capture
/// pipeline depends on, scoped to no single component. A changed path
/// outside all three is simply not this pipeline's concern (docs, CI,
/// other packages, …).
const List<String> _kPipelineLibraryRoots = [
  'packages/coui_core/lib/',
  'packages/coui_flutter/lib/',
  'packages/coui_web/lib/',
];

/// Maps [changedPaths] (repo-root-relative, forward-slash separated, as
/// `git diff --name-only` prints them) to the matrix selection they imply.
///
/// Three outcomes, checked per path in this order:
///
/// 1. Under a component's own Flutter/Web directory, or its Core contract
///    directory, with a slug the catalog recognizes → contributes to
///    [ChangedComponentSet].
/// 2. Under one of [_kPipelineLibraryRoots] but not (1) — an infra path, or
///    a component-shaped path the catalog does not recognize → the whole
///    result becomes [ChangedComponentFallbackToAll], overriding whatever
///    else was seen (a single infra path is enough to widen the run).
/// 3. Neither — outside the pipeline's library trees entirely (README,
///    docs, CI config, other packages) → contributes nothing.
///
/// If every path is (3), or [changedPaths] is empty, the result is
/// [ChangedComponentNone] — #3610's "컴포넌트 무관 PR(예: README)은
/// 매트릭스가 비어 조기 종료".
ChangedComponentSelection changedComponentsFor(Iterable<String> changedPaths) {
  final knownSlugs = kDocsComponentEntries.map((e) => e.slug).toSet();
  var matched = const <String>{};

  for (final rawPath in changedPaths) {
    final path = rawPath.trim();
    if (path.isEmpty) continue;

    final dirName =
        _platformComponentPath.firstMatch(path)?.group(1) ??
        _coreContractPath.firstMatch(path)?.group(1);

    if (dirName != null) {
      final slug = dirName.replaceAll('_', '-');
      if (knownSlugs.contains(slug)) {
        matched = {...matched, slug};
        continue;
      }
      return ChangedComponentFallbackToAll(
        '$path 가 카탈로그에 없는 슬러그($slug)로 해석됨 — '
        '경로 구조는 컴포넌트처럼 보이지만 알려진 컴포넌트가 아니다',
      );
    }

    final isPipelineLibraryPath = _kPipelineLibraryRoots.any(path.startsWith);
    if (isPipelineLibraryPath) {
      return ChangedComponentFallbackToAll(
        '$path 는 특정 컴포넌트 디렉터리 밖의 파이프라인 라이브러리 경로 — 인프라 변경으로 간주',
      );
    }
    // Outside every pipeline library root — not this pipeline's concern.
  }

  if (matched.isEmpty) return const ChangedComponentNone();
  return ChangedComponentSet(matched);
}
