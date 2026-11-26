import 'dart:io';

import 'package:docs_core/internal/preview/scenes.dart';
import 'package:docs_core/shared/docs_template.dart';
import 'package:path/path.dart' as p;

/// `<LivePreview component="..." variants="a,b,c" />` — the same markup
/// `docs_site`/`docs_app` render, and the only place a component's variant
/// list is declared (`process/docs-site.md` — variant galleries are
/// authored in content, not in a Dart registry). A file can carry more than
/// one `LivePreview` tag (e.g. a variant gallery plus an orientation
/// gallery); every `variants="..."` found is unioned into one flat list,
/// because `MatrixEntry` has no orientation axis to keep them apart on.
final RegExp _variantsAttr = RegExp('variants="([^"]*)"');

/// The variants declared for [slug] in `content/components/<slug>.md`,
/// deduplicated, order preserved, always including at least `default`.
///
/// Falls back to `['default']` when the doc page has no `variants=`
/// attribute (single-variant component) or no doc page at all (e.g. an
/// infra component `docs-site.md` says should skip registration, but whose
/// content file predates that rule and still exists). A `variants=""`
/// (declared-but-empty) is treated as a content authoring error and thrown,
/// not silently read as zero variants — #3604's completion definition
/// requires a missing axis to fail loudly.
List<String> variantsForSlug(String slug, {required String contentDir}) {
  final file = File(p.join(contentDir, '$slug.md'));
  if (!file.existsSync()) {
    return const ['default'];
  }

  final content = file.readAsStringSync();
  if (docsUsesTemplateV2(content)) {
    final scenes = visibleDocsScenes(content, sourcePath: file.path);
    if (scenes.isEmpty) {
      throw StateError(
        '${file.path}: v2 page declares no visible preview scene',
      );
    }
    return scenes.map((scene) => scene.reference).toList();
  }
  final matches = _variantsAttr.allMatches(content).toList();
  if (matches.isEmpty) {
    return const ['default'];
  }

  final ordered = <String>[];
  final seen = <String>{};
  for (final match in matches) {
    final raw = match.group(1)!;
    final parts = raw.split(',').map((s) => s.trim()).toList();
    if (parts.any((s) => s.isEmpty)) {
      throw StateError(
        '${file.path}: variants="$raw" 에 빈 항목이 있다 — '
        '축 누락을 조용히 넘기지 않는다(#3604 완료 정의).',
      );
    }
    for (final part in parts) {
      if (seen.add(part)) ordered.add(part);
    }
  }

  if (ordered.isEmpty) {
    throw StateError('${file.path}: variants 속성이 있으나 값이 없다.');
  }

  return ordered;
}
