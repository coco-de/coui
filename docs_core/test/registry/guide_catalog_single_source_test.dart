@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/shared/guide_catalog.dart';
import 'package:test/test.dart';

/// Holds the guide catalog to being the only list of guides there is.
///
/// Two hand-kept copies existed before it — one sidebar in the jaspr site,
/// one in the native app — and they had already drifted: eleven guides on
/// one side, nine on the other. Nothing failed, because nothing compared
/// them. On screen that reads as "the native app is missing those pages",
/// and the code says nothing about which side is right.
void main() {
  final contentDir = Directory('content/guides');
  final catalogSlugs = kDocsGuides.map((guide) => guide.slug).toSet();

  test('every guide in the catalog has a page', () {
    // An empty catalog satisfies "every guide has a page" the way an empty
    // room satisfies "everyone here is happy".
    expect(catalogSlugs, isNotEmpty);

    for (final slug in catalogSlugs) {
      expect(
        File('${contentDir.path}/$slug.md').existsSync(),
        isTrue,
        reason: '$slug is listed in the catalog and has no markdown behind it',
      );
    }
  });

  test('and every page is in the catalog', () {
    // The direction that catches the real failure. A page added without a
    // catalog entry builds, routes, and renders — it is simply unreachable
    // from either sidebar, which is indistinguishable from not existing.
    final onDisk = contentDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.md'))
        .map((file) => file.uri.pathSegments.last.replaceAll('.md', ''))
        .toSet();

    expect(onDisk.difference(catalogSlugs), isEmpty);
    expect(catalogSlugs.difference(onDisk), isEmpty);
  });

  test('slugs are unique and paths are built, not written', () {
    expect(catalogSlugs.length, kDocsGuides.length);
    for (final guide in kDocsGuides) {
      expect(guide.path, '/guides/${guide.slug}');
      expect(guide.label, isNotEmpty);
    }
  });
}
