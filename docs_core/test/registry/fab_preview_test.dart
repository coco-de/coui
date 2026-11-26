import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('FAB preview registry', () {
    late String flutterDefaultExampleSource;
    late String webDefaultExampleSource;
    late String flutterPreviewSource;

    setUpAll(() {
      // `_fabPreview` in {flutter,web}_registry.dart is a thin
      // `switch (variant) { 'chain' => FabChainExample(), _ => FabDefaultExample() }`
      // dispatcher (process/docs-site.md "registry 연결 — preview function =
      // example widget, never inline") — the actual `Fab(...)` construction
      // this test cares about lives in the default-variant example file, not
      // the registry function body.
      flutterDefaultExampleSource = File(
        'lib/previews/examples/flutter/fab/fab_default_example.dart',
      ).readAsStringSync();
      webDefaultExampleSource = File(
        'lib/previews/examples/web/fab/fab_default_example.dart',
      ).readAsStringSync();
      flutterPreviewSource = File(
        'lib/shared/preview_constraints.dart',
      ).readAsStringSync();
    });

    test('Flutter default example uses the unified Fab', () {
      expect(
        flutterDefaultExampleSource,
        contains('Fab('),
        reason: 'FAB preview should use the unified Fab component',
      );
    });

    test('Web default example uses the unified Fab', () {
      expect(
        webDefaultExampleSource,
        contains('Fab('),
        reason: 'FAB preview should use the unified Fab component',
      );
    });

    test('Flutter default example passes speed-dial actions via FabAction', () {
      expect(
        flutterDefaultExampleSource,
        contains('actions:'),
        reason: 'FAB preview should pass actions to Fab',
      );
      expect(
        flutterDefaultExampleSource,
        contains('FabAction('),
        reason: 'FAB preview should use FabAction for speed-dial actions',
      );
    });

    test('Flutter default example renders 편집 and 공유 action labels', () {
      expect(
        flutterDefaultExampleSource,
        contains("'편집'"),
        reason: 'FAB preview should show 편집 action label',
      );
      expect(
        flutterDefaultExampleSource,
        contains("'공유'"),
        reason: 'FAB preview should show 공유 action label',
      );
    });

    test('FAB has medium constraints in the shared preview constraints', () {
      final hasFabConstraint = RegExp(
        r"'fab'\s*:\s*kDocsMediumConstraints",
      ).hasMatch(flutterPreviewSource);

      expect(
        hasFabConstraint,
        isTrue,
        reason: 'FAB should use kDocsMediumConstraints for preview rendering',
      );
    });
  });
}
