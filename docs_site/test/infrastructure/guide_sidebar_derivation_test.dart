import 'dart:io';

import 'package:test/test.dart';

/// Keeps both sidebars derived from the shared site structure.
///
/// The structure test in docs_core proves the structure matches the pages on
/// disk. It cannot prove either sidebar reads it — a hand-written link
/// list satisfies that test perfectly while quietly going out of date,
/// which is exactly the state this repo was in.
///
/// Source text rather than the widget tree, matching the other tests in
/// this directory: both files are read as strings and neither package is
/// loaded, so this stays runnable wherever `dart test` runs.
void main() {
  const sidebars = {
    'docs_site': 'lib/components/site_drawer.dart',
    'docs_app': '../app/docs_app/lib/src/shell/docs_sidebar.dart',
  };

  group('the sidebar navigation has one source', () {
    for (final entry in sidebars.entries) {
      test('${entry.key} writes no page link of its own', () {
        final source = File(entry.value).readAsStringSync();

        // A path literal is the shape a hand-kept copy takes. Deriving
        // from the structure produces `page.path`, never `'/guides/…'`.
        for (final head in const ["'/guides/", "'/components/", "'/tokens/", "'/getting-started"]) {
          expect(source, isNot(contains(head)), reason: 'a literal page path is a second list starting over');
        }
      });

      test('${entry.key} reads the structure instead', () {
        final source = File(entry.value).readAsStringSync();

        expect(source, contains('kDocsNavTabs'));
        expect(source, contains('docs_navigation.dart'));
      });
    }

    test('the guides reach the structure through their catalog', () {
      // The structure does not restate the guides: it reads the guide
      // catalog, so a guide added there appears in both sidebars.
      final structure = File('../docs_core/lib/shared/docs_navigation.dart').readAsStringSync();

      expect(structure, contains('kDocsGuides'));
      expect(structure, contains('guide_catalog.dart'));
      expect(structure, isNot(contains("'/guides/")));
    });
  });
}
