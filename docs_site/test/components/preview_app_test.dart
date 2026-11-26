import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String previewAppSource;

  setUpAll(() {
    previewAppSource = File('lib/widgets/preview_app.dart').readAsStringSync();
  });

  group('PreviewApp widget', () {
    test('imports coui_flutter', () {
      expect(
        previewAppSource,
        contains("package:coui_flutter/coui_flutter.dart"),
      );
    });

    test('imports flutter_registry', () {
      expect(previewAppSource, contains('flutter_registry.dart'));
    });

    test('uses CoreThemePresets.previewLight for theme', () {
      expect(previewAppSource, contains('CoreThemePresets.previewLight'));
    });

    test('uses ThemeData.fromCore for Flutter theme', () {
      expect(previewAppSource, contains('ThemeData.fromCore'));
    });

    test('disables debug banner', () {
      expect(previewAppSource, contains('debugShowCheckedModeBanner: false'));
    });

    test('pins the desktop typography tier', () {
      // The view is a preview pane, not the screen: left to follow its width
      // it would step the headings down beside a Web pane pinned to desktop.
      expect(
        previewAppSource,
        contains('typographyTier: CoreBreakpointTier.desktop'),
      );
    });

    test('uses kFlutterPreviewRegistry for component lookup', () {
      expect(previewAppSource, contains('kFlutterPreviewRegistry'));
    });

    test('renders through the CoUIApp shell (no opaque Material scaffold)', () {
      // Transparency is achieved by hosting the preview in `CoUIApp` with a
      // bare `home: Align(...)` — there is no Material `Scaffold` painting an
      // opaque background over the docs page, so the docs background shows
      // through. (Previously asserted a literal `Colors.transparent`.)
      expect(previewAppSource, contains('CoUIApp'));
      expect(previewAppSource, isNot(contains('Scaffold(')));
    });
  });
}
