/// Per-component section derivation (schema v3 `section` — FR-002).
///
/// The section scheme is a *fold* of coui_flutter's category directories,
/// decided directory-by-directory and never per component — re-classifying
/// individual components would create a taxonomy the docs catalog and the
/// Figma plugin don't share. The fold map below is that decision's single
/// home; changing where a category lands is a one-line edit here.
///
/// The fold is a near-identity: each category maps to its own section, one
/// name per name, so the plugin's Figma section list matches
/// `docs_core/lib/shared/component_catalog.dart`'s `kDocsComponentGroups`
/// 1:1 (both walk from the same coui_flutter category directories — they
/// were never two different taxonomies, just two different fold degrees of
/// the same one). `infra` is included — the docs catalog registers an
/// `Infra` group (Clickable/FocusOutline/OutlinedContainer/…), so folding
/// it to `null` here would be the one category where the two surfaces
/// disagreed. Only `locale` folds to `null` — it holds localization data,
/// not visual components, and has no docs catalog group either. A
/// component whose slug matches no flutter directory at all gets
/// `{name: null, sourceCategory: null}` and is counted so the exporter can
/// surface the stragglers instead of silently shrugging.
library;

import 'dart:io';

/// Category directory → section name. `null` = folded out of the Figma
/// surface entirely.
const kSectionFold = <String, String?>{
  'control': 'Control',
  'navigation': 'Navigation',
  'menu': 'Menu',
  'display': 'Display',
  'overlay': 'Overlay',
  'text': 'Text',
  'icon': 'Icon',
  'form': 'Form',
  'layout': 'Layout',
  'infra': 'Infra',
  'locale': null,
};

/// One component's resolved section.
final class ComponentSection {
  const ComponentSection({required this.name, required this.sourceCategory});

  static const ComponentSection unmapped = ComponentSection(
    name: null,
    sourceCategory: null,
  );

  /// One of [kSectionFold]'s section names, or `null` when the source
  /// category folds out (`locale`) or the slug has no flutter home.
  final String? name;

  /// The coui_flutter category directory the fold was derived from —
  /// preserved so the original taxonomy stays auditable next to the folded
  /// result.
  final String? sourceCategory;
}

/// JSON shape for one component's `section` key — both keys always
/// present, `null` when unmapped (schema v2's "union 금지" rule).
Map<String, dynamic> sectionJson(ComponentSection section) => {
  'name': section.name,
  'sourceCategory': section.sourceCategory,
};

/// Walks `{componentsRoot}/{category}/{slug}/` and returns slug → section.
///
/// Secondary rule: a category directory whose *own name* is a component
/// slug (today only `icon`, whose widget lives directly in the `icon/`
/// category with no nested `icon/icon/` directory) maps to itself — checked
/// after the depth-2 scan so a real nested directory always wins.
///
/// Tertiary rule: a slug whose widget is a *file* rather than a directory
/// (`form/form_field.dart`, `avatar/avatar_badge.dart`, sub-components
/// generally) maps to the category whose tree contains `{slug}.dart` —
/// checked last, sorted category order, so both directory rules always
/// win over a stray same-named file.
Map<String, ComponentSection> readSections({required String componentsRoot}) {
  final root = Directory(componentsRoot);
  if (!root.existsSync()) {
    throw StateError('components root not found: $componentsRoot');
  }

  final categories =
      root.listSync().whereType<Directory>().map((d) => d.path).toList()
        ..sort();

  final bySlug = <String, ComponentSection>{};
  for (final categoryPath in categories) {
    final category = categoryPath.split(Platform.pathSeparator).last;
    final section = ComponentSection(
      name: kSectionFold[category],
      sourceCategory: category,
    );

    final slugs =
        Directory(categoryPath)
            .listSync()
            .whereType<Directory>()
            .map((d) => d.path.split(Platform.pathSeparator).last)
            .toList()
          ..sort();
    for (final slug in slugs) {
      bySlug[slug] = section;
    }

    // Secondary rule — the category directory itself as a slug.
    if (!bySlug.containsKey(category)) bySlug[category] = section;
  }

  // Tertiary rule — file-shaped sub-components.
  for (final categoryPath in categories) {
    final category = categoryPath.split(Platform.pathSeparator).last;
    final section = ComponentSection(
      name: kSectionFold[category],
      sourceCategory: category,
    );
    final fileSlugs =
        Directory(categoryPath)
            .listSync(recursive: true)
            .whereType<File>()
            .map((f) => f.path.split(Platform.pathSeparator).last)
            .where((name) => name.endsWith('.dart'))
            .map((name) => name.substring(0, name.length - '.dart'.length))
            .toList()
          ..sort();
    for (final slug in fileSlugs) {
      if (!bySlug.containsKey(slug)) bySlug[slug] = section;
    }
  }
  return bySlug;
}
